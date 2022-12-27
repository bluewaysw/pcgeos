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
 *	Definition of driver function DR_INIT.
 ***********************************************************************/

#include "ttinit.h"
#include "ttadapter.h"
#include <fileEnum.h>
#include <geos.h>
#include <heap.h>
#include <lmem.h>
#include <ec.h>
#include <initfile.h>


/********************************************************************
 *                      Init_FreeType
 ********************************************************************
 * SYNOPSIS:	  Initialises the FreeType Engine with the kerning 
 *                extension. This is the adapter function for DR_INIT.
 * 
 * PARAMETERS:    void
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
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

        //commented out because it freezes swat
        //TT_Init_Kerning()

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
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
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
 * SYNOPSIS:	  Deinitialises the FreeType Engine. This is the 
 *                adapter function for DR_EXIT.
 * 
 * PARAMETERS:    void
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
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
void _pascal TrueType_InitFonts( MemHandle fontInfoBlock )
{
        FileEnumParams   ttfEnumParams;
        word             numOtherFiles;
        word             numFiles;
        word             file;
        FileLongName*    ptrFileName;
        MemHandle        fileEnumBlock    = NullHandle;
        FileExtAttrDesc  ttfExtAttrDesc[] =
                { { FEA_NAME, 0, sizeof( FileLongName ), NULL },
                  { FEA_END_OF_LIST, 0, 0, NULL } };


        FilePushDir();

        /* go to font/ttf directory */
        FileSetCurrentPath( SP_FONT, TTF_DIRECTORY );

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

        numFiles = FileEnum( &ttfEnumParams, &fileEnumBlock, &numOtherFiles );
        ECCheckMemHandle( fileEnumBlock );

        if( numFiles == 0 )
                goto Fin;

        /* iterate over all filenames and try to register a font.*/
        ptrFileName = MemLock( fileEnumBlock );
        for( file = 0; file < numFiles; file++ )
                TrueType_ProcessFont( ptrFileName[file], fontInfoBlock );

        MemFree( fileEnumBlock );

Fin:
        FilePopDir();
}


TT_Error TrueType_ProcessFont( const char* fileName, MemHandle fontInfoBlock )
{
        FileHandle      truetypeFile;
        TT_Face         face;
        TT_Error        error;
        char            familyName[FID_NAME_LEN];
        word            familyNameLength;
        FontID          fontID;


        ECCheckBounds( (void*)fileName );
        ECCheckMemHandle( fontInfoBlock );


        truetypeFile = FileOpen( fileName, FILE_ACCESS_R | FILE_DENY_W );
        
        ECCheckFileHandle( truetypeFile );

        error = TT_Open_Face( truetypeFile, &face );
        if( error )
                goto Fin;

        if ( getNameFromNameTable( familyName, face, FAMILY_NAME_INDEX ) == 0 )
                goto Fin;

        if ( !isMappedFont( familyName, &fontID ) )
                fontID = MAKE_FONTID( familyName );

        if ( !isRegistredFontID( fontID, fontInfoBlock ) )
        {
                //FontsAvailEntry erzeugen und füllen
                //FontInfo erzeugen und füllen
                //Referenz auf FontInfo in FontsAvailEntry füllen
                //Outline anhängen und füllen
        }
        else
        {
                //Gibt es schon noch keine Outline für den Style?
                        //Outline anhängen und füllen

        }

Fin:        
        FileClose( truetypeFile, FALSE );
        return error;
}


/********************************************************************
 *                      Fill_FontsAvialEntry
 ********************************************************************
 * SYNOPSIS:	  Fills the FontsAvialEntry structure with infomations 
 *                of the passed font file.
 * 
 * PARAMETERS:    fileName              Name of font file.
 *                face                  Face from font file.
 *                fontID                Calcualted FontID.
 *                fontsAvailEntry       Pointer to FontsAvialEntry
 *                                      structure to fill.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY: 
 * 
 * TODO:          Prepare it for dbcs.  
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/

TT_Error Fill_FontsAvailEntry( const char *      fileName,
                               TT_Face           face, 
                               FontID            fontID,
                               FontsAvailEntry*  fontsAvailEntry )
{
        TT_Error            error;
        TT_String*          familyName;
        word                familyNameLength;


        ECCheckBounds( (void*)fontsAvailEntry );


        error = TT_Get_Name_String( face, FAMILY_NAME_INDEX, &familyName, &familyNameLength );
        if ( error )
                return error;

        if ( familyNameLength >= FAMILY_NAME_LENGTH )
                return TT_Err_Invalid_Argument;

        fontsAvailEntry->FAE_fontID = fontID;

        /* We probably don't need this because we keep the file name in the */
        /* TrueTypeOutlineEntry for each style.                             */
        strcpy ( fontsAvailEntry->FAE_fileName, fileName );

        /* Will be filled later with the ChunkHandle to the FontInfo.       */
        fontsAvailEntry->FAE_infoHandle = NullChunk;

        return TT_Err_Ok;
}


/********************************************************************
 *                      Fill_FontInfo
 ********************************************************************
 * SYNOPSIS:	  Fills the FontsInfo structure with infomations 
 *                of the passed in FontsAvailEntry.
 * 
 * PARAMETERS:    face                  Face from font file.
 *                fontID                Calculated FontID.
 *                fontInfo              Pointer to FontInfo structure 
 *                                      to fill.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/

TT_Error _pascal Fill_FontInfo( TT_Face    face, 
                                FontID     fontID,
                                FontInfo*  fontInfo )
{
        TT_Error            error;
        TT_Face_Properties  faceProperties;
        

        ECCheckBounds( (void*)fontInfo );


        error = TT_Get_Face_Properties( face, &faceProperties );
        if ( error )
                return error;

        getNameFromNameTable( fontInfo->FI_faceName, face, FAMILY_NAME_INDEX );

        fontInfo->FI_family       = mapFamilyClass( faceProperties.os2->sFamilyClass );
        fontInfo->FI_fontID       = fontID;
        fontInfo->FI_maker        = FM_TRUETYPE;
        fontInfo->FI_pointSizeTab = 0;
        fontInfo->FI_pointSizeEnd = 0;
        fontInfo->FI_outlineTab   = 0;
        fontInfo->FI_outlineEnd   = 0;   
        
        return TT_Err_Ok;
}


/********************************************************************
 *                      Fill_OutlineData
 ********************************************************************
 * SYNOPSIS:	  Fills OutlineDataEntry and TrueTypeOutlineEntry
 *                structure with infomations of the passed file.
 * 
 * PARAMETERS:    fileName              Name of font file.
 *                face                  Face from font file.
 *                outlineDataEntry      Pointer to OutlineDataEntry 
 *                                      structure to fill.
 *                trueTypeOutlineEntry  Pointer to TrueTypeOutlineEntry
 *                                      structure to fill.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     The current directory must be the ttf font directory.
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/

TT_Error _pascal Fill_OutlineData( const char*            fileName, 
                                   TT_Face                face,
                                   OutlineDataEntry*      outlineDataEntry,
                                   TrueTypeOutlineEntry*  trueTypeOutlineEntry ) 
{
        TT_Face_Properties  faceProperties;
        TT_String*          styleName;
        word                styleNameLength;
        TT_Error            error;


        ECCheckBounds( (void*)fileName );
        ECCheckBounds( (void*)outlineDataEntry );
        ECCheckBounds( (void*)trueTypeOutlineEntry );


        //TODO: der Namestring kann ASCII oder auch UNICODE codiert sein
        //      die Implementierung muss damit umgehen können
        error = TT_Get_Name_String( face, STYLE_NAME_INDEX, &styleName, &styleNameLength );
        if ( error != TT_Err_Ok )
                return error;

        if ( styleNameLength >= STYLE_NAME_LENGTH )
                return TT_Err_Invalid_Argument;


        error = TT_Get_Face_Properties( face, &faceProperties );
        if ( error != TT_Err_Ok )
                return error;

        /* fill outlineDataEntry */
        outlineDataEntry->ODE_style  = mapTextStyle( styleName );
        outlineDataEntry->ODE_weight = mapFontWeight( faceProperties.os2->usWeightClass );

        /* fill trueTypeOutlineEntry */
        strcpy( trueTypeOutlineEntry->TTOE_fontFileName, fileName );

        return TT_Err_Ok;
}


/*******************************************************************/
/* Implemetation of helperfunctions                                */
/*******************************************************************/

static int toHash( const char* str )
{
        word    i;
        dword   hash = strlen( str );

        for ( i = 0; i < strlen( str ) ; i++ )
		hash = ( hash * 7 ) % ( 2^16 ) + str[i];

        return (int) hash;
}

static FontAttrs mapFamilyClass( TT_Short familyClass ) 
{
        byte        class    = familyClass >> 8;
        byte        subclass = (byte) familyClass & 0x00ff;
        FontFamily  family;

        switch ( class )
        {
        case 1:         //old style serifs
        case 2:         //transitional serifs
        case 3:         //modern serifs
                family = FF_SERIF;
                break;
        case 4:         //clarendon serifs
                family = subclass == 6 ? FF_MONO : FF_SERIF;
                break;
        case 5:         //slab serifs
                family = subclass == 1 ? FF_MONO : FF_SERIF;
                break;
                        //6 = reserved
        case 7:         //freeform serfis
                family = FF_SERIF;
                break;
        case 8:         //sans serif
                family = FF_SANS_SERIF;
                break;
        case 9:         //ornamentals
                family = FF_ORNAMENT;
                break;
        case 10:        //scripts
                family = FF_SCRIPT;
                break;
                        //11 = reserved
        case 12:        //symbolic
                family = FF_SYMBOL;
                break;
        default:
                family = FF_NON_PORTABLE;
        } 

        return  FA_USEFUL | FA_OUTLINE | family;   
}

static AdjustedWeight mapFontWeight( TT_Short weightClass ) 
{
        switch (weightClass)
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

static TextStyle mapTextStyle( const char* subfamily )
{
        if ( strcmp( subfamily, "Regular" ) == 0 )
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

static Boolean isMappedFont( const char* familiyName, FontID* fontID ) 
{
        Boolean result;

        result = !InitFileReadInteger( FONTMAPPING_CATEGORY, 
		                       familiyName, 
                                       fontID );

        //ensure FM_TRUETYPE is set
        *fontID = FM_TRUETYPE || (*fontID && 0x0fff);
        return result;
}

static Boolean isRegistredFontID( FontID fontID, MemHandle fontInfoBlock )
{
        FontsAvailEntry*  fontsAvailEntrys;
        word   elements;
        word   element;

        /* set fontsAvailEntrys to first Element after LMemBlockHeader */
        fontsAvailEntrys = ( (byte*)MemDeref( fontInfoBlock ) + sizeof( LMemBlockHeader ) );
        elements = LMemGetChunkSizePtr( fontsAvailEntrys ) / sizeof( FontsAvailEntry );

        for( element = 0; element < elements; element++ )
                if( fontsAvailEntrys[element].FAE_fontID == fontID )
                        return TRUE;

        return FALSE;
}

static word getNameFromNameTable( char* name, TT_Face face, TT_UShort nameID )
{
        TT_Face_Properties  faceProperties;
        TT_UShort           platformID;
        TT_UShort           encodingID;
        TT_UShort           languageID;
        word                nameLength;
        word                id;
        word                i, n;
        char*               str;
        
        
        TT_Get_Face_Properties( face, &faceProperties );

        for( n = 0; n < faceProperties.num_Names; n++ )
        {
                TT_Get_Name_ID( face, n, &platformID, &encodingID, &languageID, &id );
                if( id != nameID )
                        continue;

                if( platformID == PLATFORM_ID_MS && 
                    encodingID == ENCODING_ID_MS_UNICODE_BMP && 
                    languageID == LANGUAGE_ID_WIN_EN_US )
                {
                        TT_Get_Name_String( face, n, &str, &nameLength );

                        for (i = 1; str != 0 && i < nameLength; i += 2)
                                *name++ = str[i];
                        *name = 0;
                        return nameLength >> 1;
                }
                else if( platformID == PLATFORM_ID_MAC && 
                         encodingID == ENCODING_ID_MAC_ROMAN &&
                         languageID == LANGUAGE_ID_MAC_EN )
                {
                        TT_Get_Name_String( face, n, &str, &nameLength );

                        for (i = 1; str != 0 && i < nameLength; i ++)
                                *name++ = str[i];
                        *name = 0;
                        return nameLength;
                }
        }

        return 0;
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
                s1++;
                s2++;
        }
        return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}
