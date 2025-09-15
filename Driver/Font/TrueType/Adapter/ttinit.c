/***********************************************************************
 *
 *	Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttinit.c
 *
 * AUTHOR:	  Jirka Kunze: December 20 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	20/12/22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Implementations for functions DR_INIT and DR_FONT_INIT_FONTS.
 ***********************************************************************/

#include "ttinit.h"
#include "ttadapter.h"
#include "ttacache.h"
#include "ttcharmapper.h"
#include "ttmemory.h"
#include "ftxkern.h"
#include <fileEnum.h>
#include <geos.h>
#include <heap.h>
#include <lmem.h>
#include <ec.h>
#include <initfile.h>
#include <unicode.h>
#include <fontID.h>


static word DetectFontFiles(    MemHandle*  fileEnumBlock );

static void ProcessFont(        TRUETYPE_VARS,
                                const char*  file, 
                                MemHandle    fontInfoBlock );

static Boolean isFontResourceIntensive( TRUETYPE_VARS );

static sword getFontIDAvailIndex( 
                                FontID     fontID, 
                                MemHandle  fontInfoBlock );

static Boolean getFontID( TRUETYPE_VARS, FontID* fontID );

static FontWeight mapFontWeight( TT_Short weightClass );

static TextStyle mapTextStyle(  const char* subfamily );

static FontGroup mapFontGroup( TRUETYPE_VARS );

static word getNameFromNameTable( 
                                TRUETYPE_VARS,
                                char*            name, 
                                const TT_UShort  nameIndex );

void InitConvertHeader(         TRUETYPE_VARS, FontHeader* fontHeader );

static char GetDefaultChar(     TRUETYPE_VARS, char firstChar );

word GetKernCount(       TRUETYPE_VARS );

static word toHash( const char* str );

static word strlen( const char* str );

static char* strcpy( char* dest, const char* source );

static void strcpyname( char* dest, const char* source );

static int strcmp( const char* s1, const char* s2 );

static Boolean activateBytecodeInterpreter();


/********************************************************************
 *                      Init_FreeType
 ********************************************************************
 * SYNOPSIS:       Initializes the FreeType library and sets up
 *                 kerning extensions for subsequent operations.
 * 
 * PARAMETERS:     None
 * 
 * RETURNS:        TT_Error
 *                    Returns `TT_Err_Ok` on success, or an error code
 *                    if initialization fails.
 * 
 * STRATEGY:       - Call `TT_Init_FreeType()` to initialize the core
 *                   FreeType library.
 *                 - Return the appropriate error code if the core
 *                   initialization fails.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      15.07.22  JK        Initial Revision
 *******************************************************************/

TT_Error _pascal Init_FreeType()
{
        TT_Error        error;
 
        error = TT_Init_FreeType();
        if ( error != TT_Err_Ok )
                return error;

        engineInstance.interpreterActive = activateBytecodeInterpreter();

        return TT_Err_Ok;
}


/********************************************************************
 *                      Exit_FreeType
 ********************************************************************
 * SYNOPSIS:       Cleans up and deinitializes the FreeType library,
 *                 releasing all allocated resources.
 * 
 * PARAMETERS:     MemHandle varBlock
 *                    Memory handle to the block containing TrueType variables.None
 * 
 * RETURNS:        void
 * 
 * STRATEGY:       - Call `TT_Done_FreeType()` to clean up resources
 *                   used by the FreeType library.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      15.07.22  JK        Initial Revision
 *******************************************************************/

void _pascal Exit_FreeType(MemHandle varBlock) 
{
        if ( varBlock != NullHandle ) {

            TrueTypeVars*          trueTypeVars;
    
            trueTypeVars = MemLock( varBlock );
EC(         ECCheckBounds( (void*)trueTypeVars ) );
    
            if( trueTypeVars->cacheFile != NullHandle ) {
                TrueType_Cache_Exit( trueTypeVars->cacheFile );
            }
            MemUnlock( varBlock );
        }

        TT_Done_FreeType();
}

/********************************************************************
 *                      TrueType_InitFonts
 ********************************************************************
 * SYNOPSIS:       Initializes TrueType fonts by scanning the font 
 *                 directory and processing detected font files. Updates 
 *                 the font info and variable blocks with the detected 
 *                 font information.
 * 
 * PARAMETERS:     MemHandle fontInfoBlock
 *                    Memory handle to the block containing font information.
 * 
 *                 MemHandle varBlock
 *                    Memory handle to the block containing TrueType variables.
 * 
 * RETURNS:        void
 * 
 * STRATEGY:       - Verify the validity of `fontInfoBlock` and `varBlock`.
 *                 - Lock `varBlock` to retrieve or allocate TrueTypeVars.
 *                 - Set the current directory to the font TrueType directory.
 *                 - Detect available font files and enumerate them.
 *                 - If no files are found, clean up and exit.
 *                 - Iterate over each detected font file and attempt to
 *                   register the font using `ProcessFont()`.
 *                 - Clean up memory, unlock variable block, and restore
 *                   the original directory.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      15.07.22  JK        Initial Revision
 *******************************************************************/

void _pascal TrueType_InitFonts( MemHandle fontInfoBlock, MemHandle varBlock )
{
        word            numFiles;
        FileLongName*   ptrFileName;
        MemHandle       fileEnumBlock;
        TrueTypeVars*   trueTypeVars;


EC(     ECCheckMemHandle( fontInfoBlock ) );
EC(     ECCheckMemHandle( varBlock ) );


        /* get trueTypeVar block */
        trueTypeVars = MemLock( varBlock );
        if( trueTypeVars == NULL )
        {
                MemReAlloc( varBlock, sizeof( TrueTypeVars ), HAF_NO_ERR | HAF_ZERO_INIT );
                trueTypeVars = MemLock( varBlock );
        }

        /* go to font/ttf directory */
        FilePushDir();
        FileSetCurrentPath( SP_FONT, TTF_DIRECTORY );

        /* detect all filenames in current directory */
        numFiles = DetectFontFiles( &fileEnumBlock );

        if( numFiles == 0 )
                goto Fin;
EC(     ECCheckMemHandle( fileEnumBlock ) );

        /* iterate over all filenames and try to register a font */
        ptrFileName = MemLock( fileEnumBlock );
        while( numFiles-- )
                ProcessFont( trueTypeVars, ptrFileName++, fontInfoBlock );

        MemFree( fileEnumBlock );

Fin:
        MemUnlock( varBlock );
        FilePopDir();
}


/********************************************************************
 *                      DetectFontFiles
 ********************************************************************
 * SYNOPSIS:       Detects and enumerates all TrueType font files in the
 *                 current directory, storing their information in a memory
 *                 block.
 * 
 * PARAMETERS:     MemHandle* fileEnumBlock
 *                    Pointer to a memory handle that will store information
 *                    about the detected font files.
 * 
 * RETURNS:        word
 *                    The number of detected font files.
 * 
 * STRATEGY:       - Set up the `FileEnumParams` structure to specify
 *                   attributes for enumeration, such as file names.
 *                 - Configure enumeration to only search for non-GEOS files.
 *                 - Pass the configured parameters to `FileEnum()` to detect
 *                   and list the font files.
 *                 - Store the results in the memory block provided by `fileEnumBlock`.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14.04.23  JK        Initial Revision
 *******************************************************************/

static word DetectFontFiles( MemHandle* fileEnumBlock )
{
        FileEnumParams   ttfEnumParams;
        word             numOtherFiles;
        FileExtAttrDesc  ttfExtAttrDesc[] = { { FEA_NAME, 0, sizeof( FileLongName ), NULL },
                                              { FEA_END_OF_LIST, 0, 0, NULL } };

        /* get all filenames contained in current directory */
        ttfEnumParams.FEP_searchFlags   = FESF_NON_GEOS;
        ttfEnumParams.FEP_returnAttrs   = ttfExtAttrDesc;
        ttfEnumParams.FEP_returnSize    = sizeof( FileLongName );
        ttfEnumParams.FEP_matchAttrs    = NullHandle;
        ttfEnumParams.FEP_bufSize       = FE_BUFSIZE_UNLIMITED;
        ttfEnumParams.FEP_skipCount     = 0;
        ttfEnumParams.FEP_callback      = NullHandle;
        ttfEnumParams.FEP_callbackAttrs = NullHandle;
        ttfEnumParams.FEP_headerSize    = 0;

        return FileEnum( &ttfEnumParams, fileEnumBlock, &numOtherFiles );
}


static word CalcMagicNumber(FileHandle fontFile, dword fontFileSize) 
{
	/* zero magic for now
	word magicNumber = 0;
	MemHandle mem;
	mem = MemAlloc();
	buf = MemDeref(mem);

	FilePos();
	FileRead();

	

	MemFree(mem);
	return magicNumber;
	*/
	return 0;
}

/********************************************************************
 *                      ProcessFont
 ********************************************************************
 * SYNOPSIS:       Processes a TrueType font file and adds its data to 
 *                 the font information block if the font is new.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the driver.
 *                 const char* fileName
 *                    Pointer to the name of the TrueType font file to process.
 *                 MemHandle fontInfoBlock
 *                    Handle to the memory block where font information is stored.
 * 
 * RETURNS:        void
 * 
 * STRATEGY:       - Open the TrueType font file and validate its face properties.
 *                 - Retrieve or create entries for the font header, outline,
 *                   and other font-related data structures.
 *                 - Allocate necessary memory chunks for font data, ensuring
 *                   the availability of the font entry.
 *                 - Populate font metadata, including outline entries, styles,
 *                   and header information.
 *                 - Append the newly created font entry or update existing
 *                   entries in the font information block.
 *                 - Ensure proper memory allocation and free resources on errors.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20.01.23  JK        Initial Revision
 *******************************************************************/

static void ProcessFont( TRUETYPE_VARS, const char* fileName, MemHandle fontInfoBlock )
{
        FileHandle              truetypeFile;
        ChunkHandle             trueTypeOutlineChunk;
        ChunkHandle             fontHeaderChunk;
        ChunkHandle             fontInfoChunk;
        FontHeader*             fontHeader;
        FontInfo*               fontInfo;
        TrueTypeOutlineEntry*   trueTypeOutlineEntry;
        FontID                  fontID;
        Boolean                 mappedFont;
        sword                   availIndex;


EC(     ECCheckBounds( (void*)fileName ) );
EC(     ECCheckBounds( (void*)trueTypeVars ) );
        
        truetypeFile = FileOpen( fileName, FILE_ACCESS_R | FILE_DENY_W );
        
EC(     ECCheckFileHandle( truetypeFile ) );

        if ( TT_Open_Face( truetypeFile, &FACE ) )
                goto Fin;

        if ( TT_Get_Face_Properties( FACE, &FACE_PROPERTIES ) )
                goto Fail;

        if ( isFontResourceIntensive( trueTypeVars ) )
                goto Fail;

        if ( getCharMap( FACE, &FACE_PROPERTIES, &CHAR_MAP ) )
                goto Fail;

        if ( getNameFromNameTable( trueTypeVars, FAMILY_NAME, FAMILY_NAME_ID ) == 0 )
                goto Fail;

        if ( getNameFromNameTable( trueTypeVars, STYLE_NAME, STYLE_NAME_ID ) == 0 )
                goto Fail;

        mappedFont = getFontID( trueTypeVars, &fontID );
	availIndex = getFontIDAvailIndex( fontID, fontInfoBlock );

        /* if we have an new font FontAvailEntry, FontInfo and Outline must be created */
        if ( availIndex < 0 )
        {
		FontsAvailEntry*       newEntry; 
                OutlineDataEntry*      outlineDataEntry;

		
		/* allocate chunk for FontsAvailEntry and fill it */
		if( LMemInsertAtHandles( fontInfoBlock, sizeof(LMemBlockHeader), 0, sizeof(FontsAvailEntry) ) ) 
			goto Fail;

		newEntry = LMemDeref( ConstructOptr( fontInfoBlock, sizeof( LMemBlockHeader ) ) );
                newEntry->FAE_fontID = fontID;
                newEntry->FAE_infoHandle = NullChunk;
                *newEntry->FAE_fileName = 0;

		/* allocate chunk for FontInfo and OutlineDataEntry */
		fontInfoChunk = LMemAlloc( fontInfoBlock, sizeof(OutlineDataEntry) + sizeof(FontInfo) );
		if( fontInfoChunk == NullChunk )
		{
			/* revert previous allocation of FontsAvailEntry */
			LMemDeleteAtHandles( fontInfoBlock, sizeof(LMemBlockHeader), 0, sizeof(FontsAvailEntry) );
			goto Fail;
		}

                /* get pointer to FontInfo and fill it */
		fontInfo = LMemDerefHandles( fontInfoBlock, fontInfoChunk );
                strcpy( fontInfo->FI_faceName, FAMILY_NAME );
                fontInfo->FI_fileHandle   = NullHandle;
                fontInfo->FI_fontID       = fontID;
                fontInfo->FI_family       = FA_USEFUL | FA_OUTLINE | ( mappedFont ? FA_FAMILY : 0 );
                fontInfo->FI_maker        = FM_TRUETYPE;
                fontInfo->FI_pointSizeTab = 0;
                fontInfo->FI_pointSizeEnd = 0;
                fontInfo->FI_outlineTab   = 0;
                fontInfo->FI_outlineEnd   = 0;

		/* add Chunk for TrueTypeOutlineEntry */
		trueTypeOutlineChunk = LMemAlloc( fontInfoBlock, sizeof(TrueTypeOutlineEntry) );
		if( trueTypeOutlineChunk == NullChunk)
		{
			LMemFreeHandles( fontInfoBlock, fontInfoChunk );
			LMemDeleteAtHandles( fontInfoBlock, sizeof(LMemBlockHeader), 0, sizeof(FontsAvailEntry) );
			goto Fail;
		}

                /* add chunk for FontHeader */
                fontHeaderChunk = LMemAlloc( fontInfoBlock, sizeof(FontHeader) );
                if( fontHeaderChunk == NullChunk )
                {
                        LMemFreeHandles( fontInfoBlock, trueTypeOutlineChunk );
                        LMemFreeHandles( fontInfoBlock, fontInfoChunk );
                        LMemDeleteAtHandles( fontInfoBlock, sizeof(LMemBlockHeader), 0, sizeof(FontsAvailEntry) );
                        goto Fail;
                }

		fontInfo = LMemDerefHandles( fontInfoBlock, fontInfoChunk );
		trueTypeOutlineEntry = LMemDerefHandles( fontInfoBlock, trueTypeOutlineChunk );

                /* fill TrueTypeOutlineEntry */
                strcpy( trueTypeOutlineEntry->TTOE_fontFileName, fileName );
            	trueTypeOutlineEntry->TTOE_fontFileSize = FileSize(truetypeFile);
		trueTypeOutlineEntry->TTOE_magicWord = CalcMagicNumber(truetypeFile, 
							trueTypeOutlineEntry->TTOE_fontFileSize);
    
                /* fill OutlineDataEntry */
                outlineDataEntry = (OutlineDataEntry*) (fontInfo + 1);
                outlineDataEntry->ODE_style  = mapTextStyle( STYLE_NAME );
                outlineDataEntry->ODE_weight = mapFontWeight( FACE_PROPERTIES.os2->usWeightClass );
                outlineDataEntry->ODE_header.OE_handle = trueTypeOutlineChunk;
                outlineDataEntry->ODE_first.OE_handle = fontHeaderChunk;
	
                /* fill FontHeader */
                fontHeader = LMemDerefHandles( fontInfoBlock, fontHeaderChunk );
                memset(fontHeader, 0, sizeof(FontHeader));

		fontInfo->FI_outlineTab = sizeof( FontInfo );
		fontInfo->FI_outlineEnd = sizeof( FontInfo ) + sizeof( OutlineDataEntry );

                /* set Chunk to FontInfo into FontsAvailEntry */
                newEntry = LMemDeref( ConstructOptr( fontInfoBlock, sizeof( LMemBlockHeader ) ) );
                newEntry->FAE_infoHandle = fontInfoChunk;
	}
        else
        {
                FontsAvailEntry*      availEntries = LMemDeref( ConstructOptr(fontInfoBlock, sizeof(LMemBlockHeader)) );
		OutlineDataEntry*     outlineData = (OutlineDataEntry*) (((byte*)fontInfo) + fontInfo->FI_outlineTab);
                OutlineDataEntry*     outlineDataEnd = (OutlineDataEntry*) (((byte*)fontInfo) + fontInfo->FI_outlineEnd);

                fontInfoChunk = availEntries[availIndex].FAE_infoHandle;
		while( outlineData < outlineDataEnd)
		{
                        if( ( mapTextStyle( STYLE_NAME ) == outlineData->ODE_style ) &&
	                    ( mapFontWeight( FACE_PROPERTIES.os2->usWeightClass ) == outlineData->ODE_weight ) )
			{
				goto Fail;
			}
			++outlineData;
		}

		/* not found append new outline entry */
		trueTypeOutlineChunk = LMemAlloc( fontInfoBlock, sizeof(TrueTypeOutlineEntry) );
		if( trueTypeOutlineChunk == NullChunk )
			goto Fail;			

                /* insert OutlineDataEntry behinde fontinfo */
                fontInfo = LMemDeref( ConstructOptr(fontInfoBlock, fontInfoChunk) );
                if( LMemInsertAtHandles( fontInfoBlock, fontInfoChunk, fontInfo->FI_outlineTab, sizeof( OutlineDataEntry ) ) )
		{
			LMemFreeHandles( fontInfoBlock, trueTypeOutlineChunk );
			goto Fail;
		}

                /* add chunk for FontHeader */
                fontHeaderChunk = LMemAlloc( fontInfoBlock, sizeof(FontHeader) );
                if( fontHeaderChunk == NullChunk )
                {
                        LMemFreeHandles( fontInfoBlock, trueTypeOutlineChunk );
                        goto Fail;
                }
	
                /* fill TrueTypeOutlineEntry */
                trueTypeOutlineEntry = LMemDerefHandles( fontInfoBlock, trueTypeOutlineChunk );
                strcpy( trueTypeOutlineEntry->TTOE_fontFileName, fileName );
		trueTypeOutlineEntry->TTOE_fontFileSize = FileSize(truetypeFile);
		trueTypeOutlineEntry->TTOE_magicWord = CalcMagicNumber(truetypeFile, 
							trueTypeOutlineEntry->TTOE_fontFileSize);
                
                /* fill OutlineDataEntry */
                fontInfo = LMemDeref( ConstructOptr(fontInfoBlock, fontInfoChunk) );
                outlineData = (OutlineDataEntry*) (fontInfo + 1);
                outlineData->ODE_style  = mapTextStyle( STYLE_NAME );
                outlineData->ODE_weight = mapFontWeight( FACE_PROPERTIES.os2->usWeightClass );
                outlineData->ODE_header.OE_handle = trueTypeOutlineChunk;
                outlineData->ODE_first.OE_handle = fontHeaderChunk;

                /* fill FontHeader */
                fontHeader = LMemDerefHandles( fontInfoBlock, fontHeaderChunk );
                memset(fontHeader, 0, sizeof(FontHeader));
   
		fontInfo = LMemDeref( ConstructOptr(fontInfoBlock, fontInfoChunk) );
        	fontInfo->FI_outlineEnd += sizeof( OutlineDataEntry );
	}
Fail:
        TT_Close_Face( FACE );
Fin:        
        FileClose( truetypeFile, FALSE );
}


/********************************************************************
 *                      isFontResourceIntensive
 ********************************************************************
 * SYNOPSIS:       Determines whether the given font is considered
 *                 resource-intensive based on certain criteria.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the driver.
 * 
 * RETURNS:        Boolean
 *                    TRUE if the font is considered resource-intensive.
 *                    FALSE otherwise.
 * 
 * STRATEGY:       - Currently, this function evaluates the resource 
 *                   intensity of a font based solely on the number 
 *                   of glyphs it contains.
 *                 - If the number of glyphs exceeds a defined threshold 
 *                   (MAX_NUM_GLYPHS), it returns TRUE.
 *                 - The function is designed to be extensible, allowing 
 *                   additional criteria to be added in the future.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      19.12.23  JK        Initial Revision
 *******************************************************************/
static Boolean isFontResourceIntensive( TRUETYPE_VARS )
{
        /* Further checks can be implemented here. */

        if( FACE_PROPERTIES.num_Glyphs > MAX_NUM_GLYPHS )
                return FALSE;

        return FACE_PROPERTIES.os2->version < MIN_OS2_TABLE_VERSION;
}


/********************************************************************
 *                      toHash
 ********************************************************************
 * SYNOPSIS:       Generates a hash value for a given string, which 
 *                 is used to help uniquely identify a font.
 * 
 * PARAMETERS:     const char* str
 *                    Pointer to the string for which the hash value 
 *                    is to be generated.
 * 
 * RETURNS:        word
 *                    The computed hash value, mapped within a predefined range.
 * 
 * STRATEGY:       - Calculate the initial hash value using the length 
 *                   of the string.
 *                 - Iterate over each character of the string and modify 
 *                   the hash using a multiplier of 7.
 *                 - Limit the final hash value to a range of 9 bits (0x01f0), 
 *                   adding 15 to ensure it fits within the designated range 
 *                   for unique font IDs.
 *                 - Reserve specific hash values for mapping original Nimbus fonts.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21.01.23  JK        Initial Revision
 *******************************************************************/

static word toHash( const char* str )
{
        word   i;
        word   hash = strlen( str );

        for ( i = 0; i < strlen( str ); ++i )
		hash = hash * 7 + str[i];

        /* The generated FontID has the following structure:      */
        /* 0bMMMMGGGHHHHHHHHH        MMMM      Fontmaker (4 bit)  */
        /*                           GGG       FontGroup (3 bit)  */
        /*                           HHHHHHHHH hash      (9 bit)  */
        /*                                                        */
        /* From hash the range from 0b000000000 to 0b000001111 is */
        /* reserved for mapping original Nimbus Fonts to TrueType */
        /* fonts via geos.ini.                                    */
        return hash % 0x01f0 + 15;
}


/********************************************************************
 *                      mapFontWeight
 ********************************************************************
 * SYNOPSIS:       Maps a TrueType weight class value to an internal 
 *                 adjusted weight classification.
 * 
 * PARAMETERS:     TT_Short weightClass
 *                    The weight class from the TrueType font, typically 
 *                    ranging from 100 (thin) to 900 (black).
 * 
 * RETURNS:        AdjustedWeight
 *                    The corresponding internal weight classification.
 * 
 * STRATEGY:       - Divide the weight class value by 100 to simplify the mapping.
 *                 - Use a switch statement to translate the weight class into
 *                   one of several predefined adjusted weight levels.
 *                 - Provide default handling to classify any unexpected 
 *                   values as `AW_ULTRA_BOLD`.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21.01.23  JK        Initial Revision
 *******************************************************************/

static AdjustedWeight mapFontWeight( TT_Short weightClass ) 
{
        switch (weightClass / 100)
        {
        case 1:
                return AW_ULTRA_LIGHT;
        case 2:
                return AW_EXTRA_LIGHT;
        case 3:
                return AW_LIGHT;
        case 4:
                return AW_SEMI_LIGHT;
        case 5:
                return AW_MEDIUM;
        case 6:
                return AW_SEMI_BOLD;
        case 7:
                return AW_BOLD;
        case 8:
                return AW_EXTRA_BOLD;
        default:
                return AW_ULTRA_BOLD;
        }
}


/********************************************************************
 *                      mapTextStyle
 ********************************************************************
 * SYNOPSIS:       Maps a font subfamily name to an internal text 
 *                 style representation.
 * 
 * PARAMETERS:     const char* subfamily
 *                    The subfamily name of the font, such as "Bold", 
 *                    "Italic", etc.
 * 
 * RETURNS:        TextStyle
 *                    The corresponding internal text style flag.
 * 
 * STRATEGY:       - Use a series of `strcmp` comparisons to determine the 
 *                   corresponding text style based on the subfamily name.
 *                 - Map common styles like "Regular", "Bold", "Italic", 
 *                   and combinations like "Bold Italic" and "Oblique" 
 *                   to their respective internal representations.
 *                 - Default to `TS_BOLD | TS_ITALIC` for unrecognized 
 *                   combinations like "Bold Oblique".
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21.01.23  JK        Initial Revision
 *******************************************************************/

static TextStyle mapTextStyle( const char* subfamily )
{
        if ( strcmp( subfamily, "Regular" ) == 0 || strcmp( subfamily, "Medium" ) == 0 )
                return 0x00;
        if ( strcmp( subfamily, "Bold" ) == 0 )
                return TS_BOLD;
        if ( strcmp( subfamily, "Italic" ) == 0 )
                return TS_ITALIC;
        if ( strcmp( subfamily, "Bold Italic" ) == 0 )
                return TS_BOLD | TS_ITALIC;
        if ( strcmp( subfamily, "Oblique" ) == 0 )
                return TS_ITALIC;
        
        /* only Bold Oblique remains */
        return TS_BOLD | TS_ITALIC;
}


/********************************************************************
 *                      mapFontGroup
 ********************************************************************
 * SYNOPSIS:       Maps TrueType font properties to an internal 
 *                 FontGroup representation.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the driver.
 * 
 * RETURNS:        FontGroup
 *                    The determined internal font group classification.
 * 
 * STRATEGY:       - The function attempts to approximate the font group 
 *                   for a TrueType font based on the `os2` properties 
 *                   of the font, specifically the `panose` array and 
 *                   `sFamilyClass` fields.
 *                 - Monospaced fonts are identified if the `panose` 
 *                   field for proportion equals 9.
 *                 - Serif, Sans-Serif, Ornament, and Symbol fonts are 
 *                   identified from `sFamilyClass`.
 *                 - Script fonts are recognized from the `panose` 
 *                   family type field.
 *                 - If no specific group is identified, the font is 
 *                   classified as `FG_NON_PORTABLE`.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      28.11.23  JK        Initial Revision
 *******************************************************************/

#define B_FAMILY_TYPE           0
#define B_PROPORTION            3
static FontGroup mapFontGroup( TRUETYPE_VARS )
{
        /* The font group of a TrueType font cannot be determined exactly.  */
        /* This implementation is therefore more of an approximation than   */
        /* an exact determination.                                          */

        /* recognize FF_MONO from panose fields */
        if( FACE_PROPERTIES.os2->panose[B_PROPORTION] == 9 )    //Monospaced
                return FG_MONO;

        /* recognize FF_SANS_SERIF, FF_SERIF, FF_SYMBOL and FF_ORNAMENT from sFamilyClass */
        switch( FACE_PROPERTIES.os2->sFamilyClass >> 8 )
        {
                case 1:
                case 2:
                case 3:
                case 4:
                case 5:
                case 7:
                        return FG_SERIF;
                case 8:
                        return FG_SANS_SERIF;
                case 9:
                        return FG_ORNAMENT;
                case 12:
                        return FG_SYMBOL;
        }

        /* recognize FF_SCRIPT from panose fields */
        if( FACE_PROPERTIES.os2->panose[B_FAMILY_TYPE] == 2 )   //Script
                return FG_SCRIPT;

        return FG_NON_PORTABLE;
}


/********************************************************************
 *                      getFontID
 ********************************************************************
 * SYNOPSIS:       Determines or generates a FontID for the given 
 *                 TrueType font family.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the driver.
 *                 FontID* fontID
 *                    Pointer to store determined or generated FontID.
 * 
 * RETURNS:        Boolean
 *                    TRUE if the FontID was found in `geos.ini`,
 *                    FALSE if a new FontID was generated.
 * 
 * STRATEGY:       - First, attempts to read `FontID` for the given font
 *                   family name from the `geos.ini` configuration file.
 *                 - If the `FontID` is found, it is modified by combining 
 *                   it with the TrueType marker (`FM_TRUETYPE`) to indicate 
 *                   the font type.
 *                 - If the `FontID` is not found, a new one is generated 
 *                   using the font group (determined via `mapFontGroup`) 
 *                   and the family name.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21.01.23  JK        Initial Revision
 *******************************************************************/

static Boolean getFontID( TRUETYPE_VARS, FontID* fontID ) 
{
        char  familyName[FID_NAME_LEN];


        /* clean up family name */
        strcpyname( familyName, trueTypeVars->familyName );

        /* get FontID from geos.ini */
        if( !InitFileReadInteger( FONTMAPPING_CATEGORY, familyName, fontID ) )
        {
                *fontID = ( FM_TRUETYPE | (*fontID & 0x0fff) );
                return TRUE;
        }

        /* generate FontID */
        *fontID = MAKE_FONTID( mapFontGroup( trueTypeVars ), trueTypeVars->familyName );
        return FALSE;
}


/********************************************************************
 *                      getFontIDAvailIndex
 ********************************************************************
 * SYNOPSIS:       Searches for a given FontID within a list of available
 *                 fonts and returns its index if found.
 * 
 * PARAMETERS:     FontID fontID
 *                    The FontID to be searched within the available fonts list.
 *                 MemHandle fontInfoBlock
 *                    The memory handle that contains the block of font information.
 * 
 * RETURNS:        sword
 *                    The index of the FontID if it is found in the fonts available list.
 *                    Returns -1 if the FontID is not found.
 * 
 * STRATEGY:       - Obtain the list of available fonts from the memory block.
 *                 - Calculate the number of FontsAvailEntry elements.
 *                 - Iterate through the list to find the matching FontID.
 *                 - If found, return the current index.
 *                 - If not found after the iteration, return -1.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21.01.23  JK        Initial Revision
 *******************************************************************/

static sword getFontIDAvailIndex( FontID fontID, MemHandle fontInfoBlock )
{
        FontsAvailEntry*  fontsAvailEntrys;
        word   elements;
        sword   element;

        /* set fontsAvailEntrys to first Element after LMemBlockHeader */
        fontsAvailEntrys = ( (FontsAvailEntry*)LMemDeref( 
			ConstructOptr( fontInfoBlock, sizeof(LMemBlockHeader))) );
        elements = LMemGetChunkSizePtr( fontsAvailEntrys ) / sizeof( FontsAvailEntry );

        for( element = 0; element < elements; ++element )
                if( fontsAvailEntrys[element].FAE_fontID == fontID )
                        return element;

        return -1;
}


/********************************************************************
 *                      getNameFromNameTable
 ********************************************************************
 * SYNOPSIS:       Extracts a specific name string from the TrueType 
 *                 font's naming table based on a provided name ID.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the driver.
 *                 char* name
 *                    Pointer to buffer where the name will be stored.
 *                 TT_UShort nameID
 *                    The identifier for the specific name entry being 
 *                    requested (e.g., family name, style name).
 * 
 * RETURNS:        word
 *                    The length of the extracted name. Returns 0 if the 
 *                    name is not found.
 * 
 * STRATEGY:       - Iterate over all name entries in the font's name 
 *                   table to find entries matching the given nameID.
 *                 - Prioritize Microsoft Unicode BMP and Macintosh 
 *                   Roman encodings for English, handling both 16-bit 
 *                   and 8-bit encoding differences.
 *                 - Extract the name string, converting UTF-16 to 
 *                   ASCII where necessary.
 *                 - If a valid name is found, store it in the buffer 
 *                   and return its length.
 *                 - If no match is found, return 0.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21.01.23  JK        Initial Revision
 *******************************************************************/

static word getNameFromNameTable( TRUETYPE_VARS, char* name, const TT_UShort nameID )
{
        TT_UShort           platformID;
        TT_UShort           encodingID;
        TT_UShort           languageID;
        word                nameLength;
        word                id;
        word                i, n;
        char*               str;
        
        
        for( n = 0; n < FACE_PROPERTIES.num_Names; ++n )
        {
                TT_Get_Name_ID( FACE, n, &platformID, &encodingID, &languageID, &id );
                if( id != nameID )
                        continue;

                if( platformID == PLATFORM_ID_MS && 
                    encodingID == ENCODING_ID_MS_UNICODE_BMP && 
                    languageID == LANGUAGE_ID_WIN_EN_US )
                {
                        TT_Get_Name_String( FACE, n, &str, &nameLength );

                        for( i = 1; str != 0 && i < nameLength; i += 2 )
                                *name++ = str[i];
                        *name = 0;
                        return nameLength >> 1;
                }
                else if( platformID == PLATFORM_ID_MAC && 
                         encodingID == ENCODING_ID_MAC_ROMAN &&
                         languageID == LANGUAGE_ID_MAC_EN )
                {
                        TT_Get_Name_String( FACE, n, &str, &nameLength );

                        for( i = 0; str != 0 && i < nameLength; ++i )
                                *name++ = str[i];
                        *name = 0;
                        return nameLength;
                }
		else if( encodingID == ENCODING_ID_UNICODE )
		{
			TT_Get_Name_String( FACE, n, &str, &nameLength );
	
			for( i = 1; str != 0 && i < nameLength; i += 2 )
				*name++ = str[i];
			*name = 0;
			return nameLength >> 1;
		}
        }

        return 0;
}


/********************************************************************
 *                      InitConvertHeader
 ********************************************************************
 * SYNOPSIS:       Initializes the `FontHeader` structure with key 
 *                 metrics from the given TrueType font. This includes
 *                 character bounds, kerning information, ascent/descent,
 *                 and other font properties.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the driver.
 *                 FontHeader* fontHeader
 *                    Pointer to the font header structure to be initialized.
 * 
 * RETURNS:        void
 *                    No return value, modifies the provided FontHeader.
 * 
 * STRATEGY:       - Check if the font header has already been initialized.
 *                 - Set default extreme values for character metrics.
 *                 - Calculate the first and last valid characters in the font.
 *                 - Retrieve the default character and kerning pair count.
 *                 - Iterate over all valid characters, updating various 
 *                   metrics including ascent, descent, min/max bounds, etc.
 *                 - Compute additional metrics such as x-height, h-height, 
 *                   and specific character positions.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21.01.23  JK        Initial Revision
 *******************************************************************/
#pragma code_seg(ttcharmapper_TEXT)
void InitConvertHeader( TRUETYPE_VARS, FontHeader* fontHeader )
{
        TT_UShort  charIndex;
        word       geosChar;


EC(     ECCheckBounds( (void*)fontHeader ) );

        if(fontHeader->FH_initialized) return;

        /* not initialized try loading cache */
        if(trueTypeVars->cacheFile == NullHandle) {
                trueTypeVars->cacheFile = TrueType_Cache_Init();
        }

        if(trueTypeVars->cacheFile != NullHandle) {
            /* try loading header from cache */
            if(TrueType_Cache_ReadHeader( 
                                        trueTypeVars->cacheFile, 
                                        trueTypeVars->entry.TTOE_fontFileName, 
					trueTypeVars->entry.TTOE_fontFileSize,
					trueTypeVars->entry.TTOE_magicWord,
                                        fontHeader)) 
                return;	    
        }

        /* initialize min, max and avg values in fontHeader */
        fontHeader->FH_minLSB   =  9999;
        fontHeader->FH_maxBSB   = -9999;
        fontHeader->FH_minTSB   = -9999;
        fontHeader->FH_maxRSB   = -9999;
        fontHeader->FH_descent  = 9999;
        fontHeader->FH_accent   = 0;
        fontHeader->FH_ascent   = 0;

        fontHeader->FH_numChars = CountValidGeosChars( CHAR_MAP, 
                                                       &fontHeader->FH_firstChar, 
                                                       &fontHeader->FH_lastChar ); 
        fontHeader->FH_defaultChar = GetDefaultChar( trueTypeVars, fontHeader->FH_firstChar );
        fontHeader->FH_kernCount   = GetKernCount( trueTypeVars );

        for ( geosChar = fontHeader->FH_firstChar; geosChar < fontHeader->FH_lastChar; ++geosChar )
        {
                const word  unicode = GeosCharToUnicode( geosChar );


                if( !GeosCharMapFlag( geosChar ) )
                        continue;

                charIndex = TT_Char_Index( CHAR_MAP, unicode );
                if ( charIndex == 0 )
                        continue;

                /* load glyph metrics without scaling or hinting */
                TT_Get_Index_Metrics( FACE, charIndex, &GLYPH_METRICS );

                //h_height -> check
                if( unicode == C_LATIN_CAPITAL_LETTER_H )
                        fontHeader->FH_h_height = GLYPH_BBOX.yMax;

                //x_height -> check
                if ( unicode == C_LATIN_SMALL_LETTER_X )
                        fontHeader->FH_x_height = GLYPH_BBOX.yMax;
        
                //ascender -> check
                if ( unicode == C_LATIN_SMALL_LETTER_D )
                        fontHeader->FH_ascender = GLYPH_BBOX.yMax;

                /* scan xMin -> check */
                if( fontHeader->FH_minLSB > GLYPH_BBOX.xMin )
                        fontHeader->FH_minLSB = GLYPH_BBOX.xMin;

                /* scan xMax -> check */
                if ( fontHeader->FH_maxRSB < GLYPH_BBOX.xMax )
                        fontHeader->FH_maxRSB = GLYPH_BBOX.xMax;

                /* scan yMin -> check */
                if ( fontHeader->FH_maxBSB < -GLYPH_BBOX.yMin )
                        fontHeader->FH_maxBSB = -GLYPH_BBOX.yMin;

                /* scan yMax -> check */
                if ( fontHeader->FH_minTSB < GLYPH_BBOX.yMax )
                        fontHeader->FH_minTSB = GLYPH_BBOX.yMax;

                /* check */
                if ( GeosCharMapFlag( geosChar ) & ( CMF_ASCENT | CMF_CAP ) )
                        if ( fontHeader->FH_ascent < GLYPH_BBOX.yMax )
                                fontHeader->FH_ascent = GLYPH_BBOX.yMax;

                /* check */
                if ( GeosCharMapFlag( geosChar ) == CMF_ACCENT )
                        if ( fontHeader->FH_accent < GLYPH_BBOX.yMax )
                                fontHeader->FH_accent = GLYPH_BBOX.yMax;
        }

        fontHeader->FH_descender  = FACE_PROPERTIES.os2->sTypoDescender;
        fontHeader->FH_descent    = -FACE_PROPERTIES.os2->sTypoDescender;
        fontHeader->FH_avgwidth   = FACE_PROPERTIES.os2->xAvgCharWidth;
        fontHeader->FH_maxwidth   = FACE_PROPERTIES.horizontal->advance_Width_Max;
        fontHeader->FH_accent     = fontHeader->FH_accent - fontHeader->FH_ascent;    
        fontHeader->FH_baseAdjust = BASELINE( UNITS_PER_EM ) - fontHeader->FH_ascent - fontHeader->FH_accent;
        fontHeader->FH_height     = fontHeader->FH_maxBSB + fontHeader->FH_ascent + DESCENT( UNITS_PER_EM ) - SAFETY( UNITS_PER_EM );
        fontHeader->FH_minTSB     = fontHeader->FH_minTSB - BASELINE( UNITS_PER_EM );
        fontHeader->FH_maxBSB     = fontHeader->FH_maxBSB - ( DESCENT( UNITS_PER_EM ) - SAFETY( UNITS_PER_EM ) );
        fontHeader->FH_underPos   = DEFAULT_UNDER_POSITION( UNITS_PER_EM ) + fontHeader->FH_accent + fontHeader->FH_ascent;
        fontHeader->FH_underThick = DEFAULT_UNDER_THICK( UNITS_PER_EM );
        
        if( fontHeader->FH_x_height > 0 )
                fontHeader->FH_strikePos = 3 * fontHeader->FH_x_height / 5;
        else
                fontHeader->FH_strikePos = 3 * fontHeader->FH_ascent / 5;

        fontHeader->FH_initialized = TRUE;

        TrueType_Cache_WriteHeader(
                                trueTypeVars->cacheFile, 
                                trueTypeVars->entry.TTOE_fontFileName, 
				trueTypeVars->entry.TTOE_fontFileSize,
				trueTypeVars->entry.TTOE_magicWord,
                                fontHeader);
}
#pragma code_seg()

/********************************************************************
 *                      GetDefaultChar
 ********************************************************************
 * SYNOPSIS:       Determines the default character for a given TrueType 
 *                 font, verifying if the standard default character is 
 *                 available in the font's character map.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the driver.
 *                 char firstChar
 *                    The fallback character to use if the standard default 
 *                    character is not present in the font.
 * 
 * RETURNS:        char
 *                    The character to be used as the default. Returns 
 *                    DEFAULT_DEFAULT_CHAR if it exists in the font, 
 *                    otherwise returns firstChar.
 * 
 * STRATEGY:       - Check if the default character (DEFAULT_DEFAULT_CHAR) 
 *                   is present in the font's character map.
 *                 - If it exists, return DEFAULT_DEFAULT_CHAR.
 *                 - Otherwise, return the provided firstChar as the fallback.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      23.04.23  JK        Initial Revision
 *******************************************************************/

static char GetDefaultChar( TRUETYPE_VARS, char firstChar )
{
        if ( !TT_Char_Index( CHAR_MAP, GeosCharToUnicode( DEFAULT_DEFAULT_CHAR ) ) )
                return firstChar;  

        return DEFAULT_DEFAULT_CHAR; 
}


/********************************************************************
 *                      activateBytecodeInterpreter
 ********************************************************************
 * SYNOPSIS:       Activates or determines if the bytecode interpreter 
 *                 should be active for the TrueType font driver. Reads 
 *                 the configuration setting from geos.ini.
 * 
 * PARAMETERS:     None
 * 
 * RETURNS:        Boolean
 *                    TRUE if the bytecode interpreter should be active 
 *                    (default behavior) or the value retrieved from the 
 *                    initialization file if it is successfully read.
 * 
 * STRATEGY:       - Attempt to read the BYTECODEINTERPRETER_KEY from the 
 *                   initialization file under the TTFDRIVER_CATEGORY.
 *                 - If the key is successfully read, return the retrieved value.
 *                 - If reading fails, return TRUE as the default behavior.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      17.11.24  jk        Initial Revision
 *******************************************************************/

static Boolean activateBytecodeInterpreter()
{
        Boolean  bytecodeInterpreterActive;


        if( !InitFileReadBoolean( TTFDRIVER_CATEGORY, BYTECODEINTERPRETER_KEY, &bytecodeInterpreterActive ) )
                return bytecodeInterpreterActive;

        return TRUE;
}


/********************************************************************
 *                      GetKernCount
 ********************************************************************
 * SYNOPSIS:       Retrieves the number of valid kerning pairs for the 
 *                 current TrueType font, specifically focusing on pairs 
 *                 where both characters are present in the GEOS character set.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the driver.
 * 
 * RETURNS:        word
 *                    The count of kerning pairs involving GEOS characters.
 *                    Returns 0 if no valid kerning pairs are found or if 
 *                    the kerning directory cannot be loaded.
 * 
 * STRATEGY:       - Obtain the kerning directory from the TrueType face.
 *                 - Lock the lookup table containing character mappings.
 *                 - Iterate through the kerning tables to find a subtable 
 *                   in format 0.
 *                 - Check for kerning pairs that meet a minimum threshold 
 *                   for value, ensuring both characters are present in 
 *                   the GEOS character set.
 *                 - Unlock resources when finished and return the count 
 *                   of valid kerning pairs.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/08/23  JK        Initial Revision
 *******************************************************************/
#pragma code_seg(ttcharmapper_TEXT)
word GetKernCount( TRUETYPE_VARS )
{
        TT_Kerning        kerningDir;
        word              table;
        TT_Kern_0_Pair*   pairs;
        word              numGeosKernPairs = 0;
        LookupEntry*      indices;

        if( TT_Load_Kerning_Directory( FACE, &kerningDir ) )
                return 0;

        if( kerningDir.nTables == 0 )
                return 0;        

        /* get pointer to lookup table */
        indices = GEO_LOCK( LOOKUP_TABLE );
EC(     ECCheckBounds( indices ) );

        /* search for format 0 subtable */
        for( table = 0; table < kerningDir.nTables; ++table )
        {
                word i;
                word minKernValue = UNITS_PER_EM / KERN_VALUE_DIVIDENT;

                if( TT_Load_Kerning_Table( FACE, &kerningDir, table ) )
                        continue;

                if( kerningDir.tables->format != 0 )
                        continue;

                pairs = GEO_LOCK( kerningDir.tables->t.kern0.pairsBlock );

                for( i = 0; i < kerningDir.tables->t.kern0.nPairs; ++i )
                {
                        if( ABS( pairs[i].value ) <= minKernValue )
                                continue;

                        if ( GetGEOSCharForIndex( indices, pairs[i].left ) && 
                             GetGEOSCharForIndex( indices, pairs[i].right ) )
                                ++numGeosKernPairs;
                }

                GEO_UNLOCK( kerningDir.tables->t.kern0.pairsBlock );
        }
        GEO_UNLOCK( LOOKUP_TABLE );
        TT_Kerning_Directory_Done( &kerningDir );

        return numGeosKernPairs;
}
#pragma code_seg()

/*******************************************************************/
/* We cannot use functions from the Ansic library, which causes a  */
/* cycle. Therefore, the required functions are reimplemented here.*/
/*******************************************************************/

static word strlen( const char* str )
{
        const char  *s;

        for ( s = str; *s; ++s )
                ;
        return( s - str );  
}


static char* strcpy( char* dest, const char* source )
{
        while( (*dest++ = *source++) != '\0' );
        return dest;
}


static void strcpyname( char* dest, const char* source )
{
        while( *source != '\0' ) 
        {
                if( *source != ' ' ) 
                {
                        *dest = *source;
                        ++dest;
                }
                ++source;
        }
        *dest = '\0';  // stringending
}


static int strcmp( const char* s1, const char* s2 )
{
        while ( *s1 && ( *s1 == *s2 ) )
        {
                ++s1;
                ++s2;
        }
        return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}
