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
#include "ttcharmapper.h"
#include "ftxkern.h"
#include <fileEnum.h>
#include <geos.h>
#include <heap.h>
#include <lmem.h>
#include <ec.h>
#include <initfile.h>
#include <unicode.h>


static word DetectFontFiles(    MemHandle*  fileEnumBlock );

static void ProcessFont(        TRUETYPE_VARS,
                                const char*  file, 
                                MemHandle    fontInfoBlock );

static sword getFontIDAvailIndex( 
                                FontID     fontID, 
                                MemHandle  fontInfoBlock );

static Boolean getFontID(       const char* familiyName, 
                                FontID*     fontID );

static FontWeight mapFontWeight( TT_Short weightClass );

static TextStyle mapTextStyle( const char* subfamily );

static word getNameFromNameTable( 
                                TRUETYPE_VARS,
                                char*      name, 
                                TT_UShort  nameIndex );

static void ConvertHeader(      TRUETYPE_VARS, FontHeader* fontHeader );

static char GetDefaultChar(     TRUETYPE_VARS, char firstChar );

static word GetKernCount(       TRUETYPE_VARS );

static word toHash( const char* str );

static int  strlen( const char* str );

static void strcpy( char* dest, const char* source );

static int strcmp( const char* s1, const char* s2 );


/********************************************************************
 *                      Init_FreeType
 ********************************************************************
 * SYNOPSIS:	  Initialises the FreeType Engine with the kerning 
 *                extension. This is the adapter function for DR_INIT.
 * 
 * PARAMETERS:    void
 * 
 * RETURNS:       TT_Error        FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      Initialises the FreeType engine by delegating to 
 *                TT_Init_FreeType() and TT_Init_Kerning().
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      7/15/22   JK        Initial Revision
 *******************************************************************/

TT_Error _pascal Init_FreeType()
{
        TT_Error        error;
 
 
        error = TT_Init_FreeType();
        if ( error != TT_Err_Ok )
                return error;

        TT_Init_Kerning_Extension();

        return TT_Err_Ok;
}


/********************************************************************
 *                      Exit_FreeType
 ********************************************************************
 * SYNOPSIS:	  Deinitialises the FreeType Engine. This is the 
 *                adapter function for DR_EXIT.
 * 
 * PARAMETERS:    void
 * 
 * RETURNS:       TT_Error        FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      Deinitialises the FreeType engine by delegating to 
 *                TT_Done_FreeType().
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      7/15/22   JK        Initial Revision
 *******************************************************************/

TT_Error _pascal Exit_FreeType() 
{
        return TT_Done_FreeType();
}


/********************************************************************
 *                      TrueType_InitFonts
 ********************************************************************
 * SYNOPSIS:	  Search for TTF fonts and register them. This is the 
 *                adapter function for DR_FONT_INIT_FONTS.
 * 
 * PARAMETERS:    fontInfoBlock   MemHandle to fontInfo.
 *                varBlock        MemHandle to truetypeVarBlock.
 * 
 * RETURNS:       void
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      7/15/22   JK        Initial Revision
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
 * SYNOPSIS:	  Lists all file names in the current directory.
 * 
 * PARAMETERS:    fileEnumBlock   Handle to the memory block in 
 *                                which the file names are stored.
 * 
 * RETURNS:       word
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14/4/23   JK        Initial Revision
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


/********************************************************************
 *                      ProcessFont
 ********************************************************************
 * SYNOPSIS:	  Registers a font with its styles as an available font.
 * 
 * PARAMETERS:    TRUETYPE_VARS   Pointer to truetypevar block.
 *                fileName        Name of font file.
 *                fontInfoBlock   Handle to memory block with all
 *                                infos about aviable fonts.
 * 
 * RETURNS:       void
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/01/23  JK        Initial Revision
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

        if ( getCharMap( trueTypeVars, &CHAR_MAP ) )
                goto Fail;

        if ( getNameFromNameTable( trueTypeVars, FAMILY_NAME, FAMILY_NAME_ID ) == 0 )
                goto Fail;

        if ( getNameFromNameTable( trueTypeVars, STYLE_NAME, STYLE_NAME_ID ) == 0 )
                goto Fail;

        mappedFont = getFontID( FAMILY_NAME, &fontID );
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
                
                /* fill OutlineDataEntry */
                outlineDataEntry = (OutlineDataEntry*) (fontInfo + 1);
                outlineDataEntry->ODE_style  = mapTextStyle( STYLE_NAME );
                outlineDataEntry->ODE_weight = mapFontWeight( FACE_PROPERTIES.os2->usWeightClass );
                outlineDataEntry->ODE_header.OE_handle = trueTypeOutlineChunk;
                outlineDataEntry->ODE_first.OE_handle = fontHeaderChunk;
	
                /* fill FontHeader */
                fontHeader = LMemDerefHandles( fontInfoBlock, fontHeaderChunk );
                ConvertHeader( trueTypeVars, fontHeader );

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
                
                /* fill OutlineDataEntry */
                fontInfo = LMemDeref( ConstructOptr(fontInfoBlock, fontInfoChunk) );
                outlineData = (OutlineDataEntry*) (fontInfo + 1);
                outlineData->ODE_style  = mapTextStyle( STYLE_NAME );
                outlineData->ODE_weight = mapFontWeight( FACE_PROPERTIES.os2->usWeightClass );
                outlineData->ODE_header.OE_handle = trueTypeOutlineChunk;
                outlineData->ODE_first.OE_handle = fontHeaderChunk;

                /* fill FontHeader */
                fontHeader = LMemDerefHandles( fontInfoBlock, fontHeaderChunk );
                ConvertHeader( trueTypeVars, fontHeader );
   
		fontInfo = LMemDeref( ConstructOptr(fontInfoBlock, fontInfoChunk) );
        	fontInfo->FI_outlineEnd += sizeof( OutlineDataEntry );
	}
Fail:
        TT_Close_Face( FACE );
Fin:        
        FileClose( truetypeFile, FALSE );
}


/********************************************************************
 *                      toHash
 ********************************************************************
 * SYNOPSIS:	  Calculates the hash value of the passed string.
 * 
 * PARAMETERS:    str             Pointer to the string.
 * 
 * RETURNS:       word            Hash value for passed string.
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21/01/23  JK        Initial Revision
 *******************************************************************/

static word toHash( const char* str )
{
        word    i;
        dword   hash = strlen( str );

        for ( i = 0; i < strlen( str ); ++i )
		hash = ( ( hash * 7 ) % 65535 ) + str[i];

        return (word) hash;
}


/********************************************************************
 *                      mapFontWeight
 ********************************************************************
 * SYNOPSIS:	  Maps the TrueType font weight class to FreeGEOS 
 *                AdjustedWeight.
 * 
 * PARAMETERS:    weightClass     TrueType weight class.
 * 
 * RETURNS:       AdjustedWeight  FreeGEOS AdjustedWeight.
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21/01/23  JK        Initial Revision
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
 * SYNOPSIS:	  Maps the TrueType subfamily to FreeGEOS TextStyle.
 * 
 * PARAMETERS:    subfamily*      String with subfamiliy name. 
 * 
 * RETURNS:       TextStyle       FreeGEOS TextStyle.
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21/01/23  JK        Initial Revision
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
 *                      getFontID
 ********************************************************************
 * SYNOPSIS:	  If the passed font family is a mapped font, the 
 *                FontID form geos.ini is returned, otherwise we 
 *                calculate new FontID and return it.
 * 
 * PARAMETERS:    familyName*     Font family name.
 *
 * RETURNS:       FontID          FontID found geos.ini or calculated.
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21/01/23  JK        Initial Revision
 *******************************************************************/

static Boolean getFontID( const char* familyName, FontID* fontID ) 
{
        if( !InitFileReadInteger( FONTMAPPING_CATEGORY, familyName, fontID ) )
        {
                *fontID = ( FM_TRUETYPE | (*fontID & 0x0fff) );
                return TRUE;
        }

        *fontID = MAKE_FONTID( familyName );
        return FALSE;
}


/********************************************************************
 *                      getFontIDAvailIndex
 ********************************************************************
 * SYNOPSIS:	  Searches all FontsAvailEntries for the passed 
 *                FontID and returns its index. If no FontsAvailEntry 
 *                is found for the FontID, -1 is returned.
 * 
 * PARAMETERS:    fontID          Searched FontID.
 *                fontInfoBlock   Memory block with font information.
 * 
 * RETURNS:       sword           Index in FontBlock, if FontID 
 *                                was not found -1 will return.
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21/01/23  JK        Initial Revision
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

        for( element = 0; element < elements; element++ )
                if( fontsAvailEntrys[element].FAE_fontID == fontID )
                        return element;

        return -1;
}


/********************************************************************
 *                      getNameFromNameTable
 ********************************************************************
 * SYNOPSIS:	  Searches the font's name tables for the given NameID 
 *                and returns its content.
 * 
 * PARAMETERS:    TRUETYPE_VARS   Pointer to truetypevar block.
 *                name*           Pointer to result string.
 *                nameID          ID to be searched.
 * 
 * RETURNS:       word            Length of the table entry found.
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21/01/23  JK        Initial Revision
 *******************************************************************/

static word getNameFromNameTable( TRUETYPE_VARS, char* name, TT_UShort nameID )
{
        TT_UShort           platformID;
        TT_UShort           encodingID;
        TT_UShort           languageID;
        word                nameLength;
        word                id;
        word                i, n;
        char*               str;
        
        
        for( n = 0; n < FACE_PROPERTIES.num_Names; n++ )
        {
                TT_Get_Name_ID( FACE, n, &platformID, &encodingID, &languageID, &id );
                if( id != nameID )
                        continue;

                if( platformID == PLATFORM_ID_MS && 
                    encodingID == ENCODING_ID_MS_UNICODE_BMP && 
                    languageID == LANGUAGE_ID_WIN_EN_US )
                {
                        TT_Get_Name_String( FACE, n, &str, &nameLength );

                        for (i = 1; str != 0 && i < nameLength; i += 2)
                                *name++ = str[i];
                        *name = 0;
                        return nameLength >> 1;
                }
                else if( platformID == PLATFORM_ID_MAC && 
                         encodingID == ENCODING_ID_MAC_ROMAN &&
                         languageID == LANGUAGE_ID_MAC_EN )
                {
                        TT_Get_Name_String( FACE, n, &str, &nameLength );

                        for (i = 0; str != 0 && i < nameLength; i++)
                                *name++ = str[i];
                        *name = 0;
                        return nameLength;
                }
		else if( encodingID == ENCODING_ID_UNICODE )
		{
			TT_Get_Name_String( FACE, n, &str, &nameLength );
	
			for (i = 1; str != 0 && i < nameLength; i += 2)
				*name++ = str[i];
			*name = 0;
			return nameLength >> 1;
		}
        }

        return 0;
}


/********************************************************************
 *                      ConvertHeader
 ********************************************************************
 * SYNOPSIS:	  Converts information from a TrueType font into a 
 *                FreeGEOS FontHeader.
 * 
 * PARAMETERS:    TRUETYPE_VARS   Pointer to truetypevar block. 
 *                fontHeader*     Pointer to FontInfo in which the
 *                                converted information is to be stored.
 * 
 * RETURNS:       void
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      21/01/23  JK        Initial Revision
 *******************************************************************/

static void ConvertHeader( TRUETYPE_VARS, FontHeader* fontHeader )
{
        TT_UShort           charIndex;
        word                geosChar;


EC(     ECCheckBounds( (void*)fontHeader ) );
        
        /* initialize min, max and avg values in fontHeader */
        fontHeader->FH_minLSB   =  9999;
        fontHeader->FH_maxBSB   = -9999;
        fontHeader->FH_minTSB   = -9999;
        fontHeader->FH_maxRSB   = -9999;
        fontHeader->FH_descent  = 9999;
        fontHeader->FH_accent   = 0;
        fontHeader->FH_ascent   = 0;

        fontHeader->FH_numChars = InitGeosCharsInCharMap( CHAR_MAP, 
                                                           &fontHeader->FH_firstChar, 
                                                           &fontHeader->FH_lastChar ); 
        fontHeader->FH_defaultChar = GetDefaultChar( trueTypeVars, fontHeader->FH_firstChar );
        fontHeader->FH_kernCount   = GetKernCount( trueTypeVars );

        TT_New_Instance( FACE, &INSTANCE );
        TT_New_Glyph( FACE, &GLYPH );

        for ( geosChar = fontHeader->FH_firstChar; geosChar < fontHeader->FH_lastChar; ++geosChar )
        {
                word unicode = GeosCharToUnicode( geosChar );


                if( !GeosCharMapFlag( geosChar ) )
                        continue;

                charIndex = TT_Char_Index( CHAR_MAP, unicode );
                if ( charIndex == 0 )
                        continue;

                /* load glyph without scaling or hinting */
                TT_Load_Glyph( INSTANCE, GLYPH, charIndex, 0 );
                TT_Get_Glyph_Metrics( GLYPH, &GLYPH_METRICS );

                //h_height -> check
                if( unicode == C_LATIN_CAPITAL_LETTER_H )
                        fontHeader->FH_h_height = GLYPH_BBOX.yMax;

                //x_height -> check
                if ( unicode == C_LATIN_SMALL_LETTER_X )
                        fontHeader->FH_x_height = GLYPH_BBOX.yMax;
        
                //ascender -> check
                if ( unicode == C_LATIN_SMALL_LETTER_D )
                        fontHeader->FH_ascender = GLYPH_BBOX.yMax;

                //descender -> check
                if ( unicode == C_LATIN_SMALL_LETTER_P )
                        fontHeader->FH_descender = GLYPH_BBOX.yMin;
                
                /* scan xMin -> check */
                if( fontHeader->FH_minLSB > GLYPH_BBOX.xMin )
                        fontHeader->FH_minLSB = GLYPH_BBOX.xMin;

                /* scan xMax -> check */
                if ( fontHeader->FH_maxRSB < GLYPH_BBOX.xMax )
                        fontHeader->FH_maxRSB = GLYPH_BBOX.xMax;

                /* scan yMin -> check */
                if ( fontHeader->FH_maxBSB < -GLYPH_BBOX.yMin )
                        fontHeader->FH_maxBSB = -GLYPH_BBOX.yMin;
                        
                /* check */
                if ( GeosCharMapFlag( geosChar) & CMF_DESCENT &&
                        fontHeader->FH_descent > -GLYPH_BBOX.yMin )
                        fontHeader->FH_descent = -GLYPH_BBOX.yMin;

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

        TT_Done_Glyph( GLYPH );
        TT_Done_Instance( INSTANCE );

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
}


/********************************************************************
 *                      GetDefaultChar
 ********************************************************************
 * SYNOPSIS:	  Returns the default character, if this is not present 
 *                in the face, the first GEOS character in the font is 
 *                the default character.
 * 
 * PARAMETERS:    TRUETYPE_VARS   Pointer to truetypevar block.
 *                firstChar       First GEOS char in face.
 * 
 * RETURNS:       char
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      23/04/23  JK        Initial Revision
 *******************************************************************/

static char GetDefaultChar( TRUETYPE_VARS, char firstChar )
{
        if ( !TT_Char_Index( CHAR_MAP, GeosCharToUnicode( DEFAULT_DEFAULT_CHAR ) ) )
                return firstChar;  

        return DEFAULT_DEFAULT_CHAR; 
}


/********************************************************************
 *                      GetKernCount
 ********************************************************************
 * SYNOPSIS:	  Returns the number of kernpairs with chars from 
 *                FreeGEOS char set.
 * 
 * PARAMETERS:    TRUETYPE_VARS   Pointer to truetypevar block.
 * 
 * RETURNS:       word
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/08/23  JK        Initial Revision
 *******************************************************************/

static word GetKernCount( TRUETYPE_VARS )
{
        TT_Kerning        kerningDir;
        word              table;
        word              numGeosKernPairs = 0;

        if( TT_Get_Kerning_Directory( FACE, &kerningDir ) )
                goto Fail;

        /* search for format 0 subtable */
        for( table = 0; table < kerningDir.nTables; ++table )
        {
                word i;

                if( TT_Load_Kerning_Table( FACE, table ) )
                        goto Fail;

                if( kerningDir.tables->format != 0 )
                        continue;

                /* We only support decreasing the character spacing.*/
                if( kerningDir.tables->t.kern0.pairs[i].value > 0 )
                        continue;

                for( i = 0; i < kerningDir.tables->t.kern0.nPairs; ++i )
                {
                        if( isGeosCharPair( kerningDir.tables->t.kern0.pairs[i].left,
                                        kerningDir.tables->t.kern0.pairs[i].right ) )
                                ++numGeosKernPairs;
                }
        }

Fail:
        return numGeosKernPairs;
}


/*******************************************************************/
/* We cannot use functions from the Ansic library, which causes a  */
/* cycle. Therefore, the required functions are reimplemented here.*/
/*******************************************************************/

static int strlen( const char* str )
{
        const char  *s;

        for ( s = str; *s; ++s )
                ;
        return( s - str );
}


static void strcpy( char* dest, const char* source )
{
        while ((*dest++ = *source++) != '\0');
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
