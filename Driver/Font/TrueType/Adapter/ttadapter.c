/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttadapter.c
 *
 * AUTHOR:	  Jirka Kunze: July 5 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/5/22	  JK	    Initial version
 *
 * DESCRIPTION:
 *	Functions to adapt the FreeGEOS font driver interface to the 
 *      FreeType library interface.
 *
 ***********************************************************************/

#include "ttadapter.h"


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
 *                      Fill_FontsAvialEntry
 ********************************************************************
 * SYNOPSIS:	  Fills the FontsAvialEntry structure with infomations 
 *                of the passed font file.
 * 
 * PARAMETERS:    fileName              Name of font file
 *                fontsAvailEntry       Pointer to FontsAvialEntry
 *                                      structure to fill.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
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

TT_Error _pascal Fill_FontsAvailEntry( const char*       fileName, 
                                       FontsAvailEntry*  fontsAvailEntry )
{
        FileHandle          fileHandle;
        TT_Error            error;
        TT_Face             face;
        char                familyName[FAMILY_NAME_LENGTH];
        word                familyNameLength;

        ECCheckBounds( fileName );
        ECCheckBounds( fontsAvailEntry );

        if ( strlen( fileName ) >= FONT_FILE_LENGTH )
                return TT_Err_Invalid_Argument;

        fileHandle = FileOpen( fileName, FILE_ACCESS_R | FILE_DENY_W );
        ECCheckFileHandle( fileHandle );

        error = TT_Open_Face( fileHandle, &face );
        if ( error != TT_Err_Ok )
                goto Fail;

        error = TT_Get_Name_String( face, NAME_INDEX_FAMILY, familyName, &familyNameLength );
        if ( error != TT_Err_Ok )
                goto Fin;

        if ( familyNameLength >= FAMILY_NAME_LENGTH )
        {
                error = TT_Err_Invalid_Argument;
                goto Fin;
        }

        if ( isMappedFont( familyName ) )
                fontsAvailEntry->FAE_fontID = getMappedFontID( familyName );
        else
                fontsAvailEntry->FAE_fontID = MAKE_FONTID( familyName );

        strcpy ( fontsAvailEntry->FAE_fileName, fileName );
        error = TT_Err_Ok;

Fin:
        TT_Close_Face( face );
Fail:
        FileClose( fileHandle, FALSE );
        return error;
}


/********************************************************************
 *                      Fill_FontInfo
 ********************************************************************
 * SYNOPSIS:	  Fills the FontsInfo structure with infomations 
 *                of the passed in FontsAvailEntry.
 * 
 * PARAMETERS:    fileName              Name of font file
 *                fontInfo              Pointer to FontInfo structure 
 *                                      to fill.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/

TT_Error _pascal Fill_FontInfo( const char* fileName, FontInfo* fontInfo )
{
        FileHandle          fileHandle;
        TT_Error            error;
        TT_Face             face;
        TT_Face_Properties  faceProperties;
        char                familyName[FAMILY_NAME_LENGTH];
        word                familyNameLength;
        
        ECCheckBounds( fileName );
        ECCheckBounds( fontInfo );

        fileHandle = FileOpen( fileName, FILE_ACCESS_R | FILE_DENY_W );
        ECCheckFileHandle( fileHandle );

        error = TT_Open_Face( fileHandle, &face );
        if ( error != TT_Err_Ok )
                goto Fail;

        error = TT_Get_Name_String( face, NAME_INDEX_FAMILY, familyName, &familyNameLength );
        if ( error != TT_Err_Ok )
                goto Fin;

        if ( familyNameLength >= FAMILY_NAME_LENGTH )
        {
                error = TT_Err_Invalid_Argument;
                goto Fin;
        }

        error = TT_Get_Face_Properties( face, &faceProperties );
        if ( error != TT_Err_Ok )
                goto Fin;

        fontInfo->FI_family = mapFamilyClass( faceProperties.os2->sFamilyClass );

        if ( isMappedFont( familyName ) )
                fontInfo->FI_fontID = getMappedFontID( familyName );
        else
                fontInfo->FI_fontID = MAKE_FONTID( familyName );

        fontInfo->FI_maker        = FM_TRUETYPE;
        fontInfo->FI_pointSizeTab = 0;
        fontInfo->FI_pointSizeEnd = 0;
        fontInfo->FI_outlineTab   = 0;
        fontInfo->FI_outlineEnd   = 0; 

        error = TT_Err_Ok;
        
Fin:
        TT_Close_Face( face );
Fail:
        FileClose( fileHandle, FALSE );
        return error;
}


/********************************************************************
 *                      Fill_OutlineDataEntry
 ********************************************************************
 * SYNOPSIS:	  Fills the OutlineDataEntry structure with infomations 
 *                of the passed in FontInfo.
 * 
 * PARAMETERS:    fontInfo              Name of font file.
 *                OutlineDataEntry      Pointer to OutlineDataEntry 
 *                                      structure to fill.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/

TT_Error _pascal Fill_OutlineDataEntry( const FontInfo* fontInfo, OutlineDataEntry* outlineDataEntry) 
{
        FileHandle          fileHandle;
        TT_Face             face;
        TT_Error            error;



        error = TT_Err_Ok;

Fin:
        TT_Close_Face( face );
Fail:
        FileClose( fileHandle, FALSE );
        return error;
}


/********************************************************************
 *                      Fill_FontBuf
 ********************************************************************
 * SYNOPSIS:	  Fills the FontBuf structure with infomations 
 *                of the passed in FontInfo.
 * 
 * PARAMETERS:    fontName              Name of font file.
 *                fontBuf               Pointer to FontBuf structure 
 *                                      to fill.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/
TT_Error _pascal Fill_FontBuf( const char* fileName, FontBuf* fontBuf ) 
{
        FileHandle          fileHandle;
        TT_Error            error;
        TT_Face             face;
        TT_Face_Properties  faceProperties;
        
        ECCheckBounds( fileName );
        ECCheckBounds( fontBuf );

        fileHandle = FileOpen( fileName, FILE_ACCESS_R | FILE_DENY_W );
        ECCheckFileHandle( fileHandle );

        error = TT_Open_Face( fileHandle, &face );
        if ( error != TT_Err_Ok )
                goto Fail;

        error = TT_Err_Ok;

Fin:
        TT_Close_Face( face );
Fail:
        FileClose( fileHandle, FALSE );
        return error;
}

/********************************************************************
 *                      Fill_CharTableEntry
 ********************************************************************
 * SYNOPSIS:	  Fills the FontBuf structure with infomations 
 *                of the passed in FontInfo.
 * 
 * PARAMETERS:    fontInfo              Pointer to FontInfo structure.
 *                gstate                Handle to current gstate.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      Pointsize, scale and rotation will read from gstate.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/
TT_Error _pascal Fill_CharTableEntry( const FontInfo* fontInfo, GStateHandle gstate, word character )
{

        return TT_Err_Ok;
}

/* offen: Kerning */

/********************************************************************
 *                      Fill_CharTableEntry
 ********************************************************************
 * SYNOPSIS:	  Fills the FontBuf structure with infomations 
 *                of the passed in FontInfo.
 * 
 * PARAMETERS:    fontInfo              Pointer to FontInfo structure.
 *                gstate                Handle to current gstate.
 *                result                Pointer in wicht the result will 
 *                                      stored.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      Pointsize, scale and rotation will read from gstate.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/
TT_Error Get_Char_Metrics( const FontInfo* fontInfo, word character,  GCM_info	info, dword* result ) 
{
        /* Api-Funktion für DR_FONT_GET_METRICS                                              */
        /* Transformationen werden nicht beachtet!!!                                         */
        /* The information is in document coordinates, which is to say it is not affected by */
        /* scaling, rotation, etc. that modifies the way the document is viewed, but simply  */
        /* by the pointsize and font attributes requested.                                   */
        /* siehe GrCharMetrics()                                                             */
        return TT_Err_Ok;
}

/********************************************************************
 *                      Gen_Char
 ********************************************************************
 * SYNOPSIS:	  Renders the given character as bitmap or region to 
 *                bitmap block.
 * 
 * PARAMETERS:    fontInfo              Pointer to FontInfo structure.
 *                gstate                Handle to current gstate.
 *                word                  Character to render.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      Pointsize, scale and rotation will read from gstate.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/
TT_Error _pascal Gen_Char( const FontInfo* fontInfo, GStateHandle gstate, word character )
{
        /* Das Zeichen wird als Bitmap/Region gerendert. Die Transformationsmatix und       */
        /* PointSize wird aus den GState geholt. Die gerenderte Bitmap wird in den          */
        /* bitmapBlock und die belegte Größe in bitmapSize abgelegt. Das Format entspricht  */
        /* CharData bzw. RegionCharData.                                                    */

        /* offen: Was machen wir mit dem CharTableEntry?                                    */
        /* Da das Flag welches anzeigt ob ein Glyph als Bitmap oder Region abgelegt wird    */
        /* in FontInfo liegt, gilt: alle Zeichen als Bitmap oder als Region, Auf welcher    */
        /* Basis wollen wir entscheiden ob wir ein Glyph als Bitmap oder als Region rendern?*/
        // --> im NibusTreiber prüfen

        return TT_Err_Ok;
}

/********************************************************************
 *                      Gen_InRegion
 ********************************************************************
 * SYNOPSIS:	  Renders the given character into the RegionPath.
 * 
 * PARAMETERS:    fontInfo              Pointer to FontInfo structure.
 *                gstate                Handle to current gstate.
 *                regionPath            Handle in wich the character 
 *                                      will rendered.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      Pointsize, scale and rotation will read from gstate.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/
TT_Error _pascal Gen_In_Region( const FontInfo* fontInfo, GStateHandle gstate, Handle regionPath, word character )
{
        /* Das Zeichen wird als RegionPath gerendert. Die Transformationsmatix und          */
        /* PointSize wird aus den GState geholt. Das gerenderte Glyph wird in den           */
        /* übergebenen RegionPath gelegt.                                                   */

        return TT_Err_Ok;
}

/********************************************************************
 *                      Gen_Path
 ********************************************************************
 * SYNOPSIS:	  Renders the given character into the GStateHandle.
 * 
 * PARAMETERS:    fontInfo              Pointer to FontInfo structure.
 *                gstate                Handle to current gstate.
 *                flags                 Transformation flags.
 *                word                  Character to render.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      Pointsize, scale and rotation will read from gstate.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/
TT_Error _pascal Gen_Path( const FontInfo* fontInfo, GStateHandle gstate, FontGenPathFlags flags, word character )
{
        /* Das Zeichen wird als Path gerendert. Die Transformationsmatix und PointSize wird  */
        /* aus den GState geholt. Das gerenderte Glyph wird in den übergebenen GState gelegt.*/

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

static Boolean isMappedFont( const char* familiyName ) 
{
        //TODO: implement it
        return FALSE;
}

static FontID getMappedFontID( const char* familyName )
{ 
        //TODO: implement it
        //TODO: FontMaker austauschen
        return (FontID) FID_DTC_URW_SANS;
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


//füllen der fontsAvailEntry Struktur:
//      FAE_fontID      (FontID)        := wird berechnet aus Fontfamily
//                                         Fontfamily := NameTable ID 1 (Font Family)
//                                         Wie ist der Bildungsalgorithmus?
//      FAE_fileName    (char/wchar)    := Dateiname des Fonts (Prüfung auf max. 36 Zeichen; sbcs/dbcs beachten)
//      FAE_infoHandle  (ChunkHandle)   := Handle auf u.g. fontInfo


//füllen der fontInfo Struktur
//      FI_fileHandle (word)	        := FileOpen( fileName ... )
//      FI_RESIDENT label(word)         := ???
//      FI_fontID (FontID)              := siehe oben FAE_fontID
//      FI_maker  (FontMaker)           := FontMaker.FM_TRUETYPE
//      FI_family (FontAttrs)           :=
//              FA_USEFUL 	(FontUseful:1)		:= FU_USEFUL/FU_NOT_USEFUL?
//              FA_FIXED_WIDTH	(FontPitch:1)	        := FP_PROPORTIONAL
//              FA_ORIENT	(FontOrientation:1)	:= FO_NORMAL
//              FA_OUTLINE	(FontSource:1)		:= FS_OUTLINE
//              FA_FAMILY	(FontFamily:4)		:= gemappt aus FaceProperties -> OS2 -> sWeightClass
//                                                         (high byte = class; low byte = subclass)
//                      class  0 (no classification)    -> FF_NON_PORTABLE?
//                      class  1 (old style serifs)     -> FF_SERIF
//                      class  2 (transitional serifs)  -> FF_SERIF
//                      class  3 (modern serifs)        -> FF_SERIF
//                      class  4 (clarendon serifs)      
//                              subclass 6 (monotone)   -> FF_MONO sonst FF_SERIF
//                      class  5 (slab serifs)          -> FF_SERIF
//                              subclass 1 (monotone)   -> FF_MONO sonst FF_SERIF
//                      class  6 (reserved)
//                      class  7 (freeform serifs)      -> FF_SERIF
//                      class  8 (sans serif)           -> FF_SANS_SERIF
//                      class  9 (ornamentals)          -> FF_ORNAMENT
//                      class 10 (scrips)               -> FF_SCRIPT
//                      class 11 (reserved)
//                      class 12 (symbolic)             -> FF_SYMBOL
//                      Achtung: für FF_SPECIAL gibt es keine Zuordnung 
//      FI_faceName (char/wchar)        := NameTable ID 1 (Font Family) (Prüfung auf max. 20 Zeichen)
//      FI_pointSizeTab  (word?)        := 0 (keine Unterstützung für Bitmaps)
//      FI_pointSizeEnd  (word?)        := 0 ( -"- )
//      FI_outlineTab    (word?)	:= wird nicht verändert; muss in der asm-Schicht gefüllt werden
//      FI_outlineEnd    (word?)        := ( -"- )

//füllen des OutlineDataEntry (im TTF Treiber gibt es nur einen Entry je Fontfile)
//      ODE_style  (TextStyle)          := gemappt aus NameTable ID 2 (Subfamily)
//              "Regular"               := 0
//              "Bold"                  := TS_BOLD
//              "Italic"                := TS_ITALIC
//              "Bold Italic"           := TS_BOLD | TS_ITALIC
//              "Oblique"               := TS_ITALIC
//              "Bold Oblique"          := TS_BOLD | TS_ITALIC
//      ODE_weight  (FontWeight)        := gemappt aus gemappt aus FaceProperties -> OS2 -> usWeightClass
//              1 (Ultra-light)         := FWE_ULTRA_LIGHT
//              2 (Extra-light)         := FWE_EXTRA_LIGHT
//              3 (Light)               := FWE_LIGHT
//              4 (Semi-light)          := FWE_BOOK
//              5 (Medium (normal))     := FWE_NORMAL
//              6 (Semi-bold)           := FWE_DEMI
//              7 (Bold)                := FWE_BOLD
//              8 (Extra-Bold)          := FWE_EXTRA_BOLD
//              9 (Ultra-bold)          := FWE_ULTRA_BOLD
//      ODE_header	(OutlineEntry)      := 0?
//      ODE_first	(OutlineEntry)      := 0?
//      ODE_second	(OutlineEntry)      := 0?

//füllen der FontBuf Struktur
//      FB_dataSize     (word)          := berechnet
//      FB_maker        (FontMaker)     := FontMaker.FM_TRUETYPE
//      FB_avgwidth     (WBFixed)       := FaceProperties -> OS2 -> xAvgCharWidth
//      FB_maxwidth	(WBFixed)	:= muss berechnet werden; wird im BS Teiber nicht gefüllt
//      FB_heightAdjust	(WBFixed)	:= BS-Treiber: pointsize
//      FB_height	(WBFixed) 	:=    ; height of characters
//      FB_accent       (WBFixed) 	    ; height of accent portion.
//      FB_mean         (WBFixed) 	    ; top of lower case character boxes.
//      FB_baseAdjust   (WBFixed)		; offset to top of ascent
//      FB_baselinePos  (WBFixed)   	; position of baseline from top of font
//      FB_descent      (WBFixed)   	; maximum descent (from baseline)
//      FB_extLeading	(WBFixed)    	; recommended external leading
//      FB_kernCount	(word)          := TT_Get_Kerning_Directory()
//                                         directory->nTables
//      FB_kernPairPtr	nptr.KernPair	:= Ptr zur KernpairTabelle
//      FB_kernValuePtr	nptr.BBFixed	:= Ptr zur KernvalueTabelle
//      FB_firstChar	(byte/Chars)		; first char in section
//      FB_lastChar	(byte/Chars)		; last char in section
//      FB_defaultChar	(byte/Chars)		; default character
//      FB_underPos	(WBFixed)		    ; underline position (from baseline)
//      FB_underThickness   (WBFixed)		; underline thickness
//      FB_strikePos	(WBFixed)	    ; position of the strike-thru
//      FB_aboveBox	(WBFixed)		    ; maximum above font box
//      FB_belowBox	(WBFixed)		    ; maximum below font box
//      FB_minLSB	(sword)		    ; minimum left side bearing
//      FB_minTSB	(sword)		    ; minimum top side bound
//      FB_maxBSB*		sword		    ; maximum bottom side bound
//      FB_maxRSB*		sword		    ; maximum right side bound
//      FB_pixHeight	word		    ; height of font (invalid for rotation)
//      FB_flags		FontBufFlags	; special flags
//      FB_heapCount	word		    ; usage counter for this font
//      FB_charTable	CharTableEntry <>
//      *nicht DBCS

//füllen eines CharTableEntries
//      CTE_dataOffset	nptr.CharData	;Offset to data
//      CTE_width		WBFixed		    ;character width
//      CTE_flags		CharTableFlags	;flags
//      CTE_usage*		word		    ;LRU count
//      *nicht DBCS
