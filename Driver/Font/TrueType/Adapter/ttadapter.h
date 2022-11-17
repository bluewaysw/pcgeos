/***********************************************************************
 *
 *	Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttadapter.h
 *
 * AUTHOR:	  Jirka Kunze: July 5 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	05.07.22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Declaration of global objects which are defined in assembler 
 *      and are also needed in c functions.
 ***********************************************************************/
#ifndef _TTADAPTER_H_
#define _TTADAPTER_H_

#include <geos.h>
#include <ec.h>
#include <fontID.h>
#include <file.h>
#include "../FreeType/freetype.h"
#include "../FreeType/ttengine.h"

/***********************************************************************
 *      global dgoup objects
 ***********************************************************************/
extern TEngine_Instance engineInstance;


/***********************************************************************
 *      parameters for search in name table
 ***********************************************************************/
#define NAME_INDEX_FAMILY          1       // font family name
#define NAME_INDEX_STYLE           2       // font style

#define FONT_FILE_LENGTH           FILE_LONGNAME_BUFFER_SIZE

#define FAMILY_NAME_LENGTH         20


#define MAKE_FONTID( family )      ( FM_TRUETYPE | ( 0x0fff & toHash ( family )))

/***********************************************************************
 *      structures
 ***********************************************************************/

typedef struct
{
    FontID                      FAE_fontID;
#ifdef DBCS_PCGEOS
    wchar                       FAE_fileName[FONT_FILE_LENGTH];
#else
    char                        FAE_fileName[FONT_FILE_LENGTH];
#endif
    ChunkHandle                 FAE_infoHandle;
} FontsAvailEntry;


typedef struct
{
    word                        FI_fileHandle;
    word                        FI_RESIDENT;
    word                        FI_fontID;
    FontMaker                   FI_maker;
    FontAttrs                   FI_family;
#ifdef DBCS_PCGEOS
    wchar                       FI_faceName[FID_NAME_LEN];
#else
    char                        FI_faceName[FID_NAME_LEN];
#endif
    word                        FI_pointSizeTab;   //nptr to PointSizeEntry
    word                        FI_pointSizeEnd;   //nptr to PointSizeEntry
    word                        FI_outlineTab;     //nptr to OutlineEntry
    word                        FI_outlineEnd;     //nptr to outlineEntry
#ifdef DBCS_PCGEOS
    wchar                       FI_firstChar;
    wchar                       FI_lastChar;
#endif
} FontInfo;

typedef struct
{
    char x;  //TBD
} TrueTypeOutlineEntry;

typedef struct 
{
    char x; //TBD
} CharTableEntry;


typedef enum
{
    //TBD
    FGPF_SAVE_STATE = 0x00,
    FGPF_POSTSCRIPT = 0x00,
} FontGenPathFlags;



typedef	struct
{
    word                        FB_dataSize;
    FontMaker                   FB_maker;
    WBFixed                     FB_avgwidth;
    WBFixed                     FB_maxwidth;
    WBFixed                     FB_heightAdjust;
    WBFixed                     FB_height;
    WBFixed                     FB_accent;
    WBFixed                     FB_mean;
/*    FB_baseAdjust	WBFixed		; offset to top of ascent
    FB_baselinePos	WBFixed 	; position of baseline from top of font
    FB_descent		WBFixed 	; maximum descent (from baseline)
    FB_extLeading	WBFixed 	; recommended external leading
    FB_kernCount	word		; number of kerning pairs
    FB_kernPairPtr	nptr.KernPair	; offset to kerning pair table
    FB_kernValuePtr	nptr.BBFixed	; offset to kerning value table
if DBCS_PCGEOS
    FB_firstChar	Chars		; first char in section
    FB_lastChar		Chars		; last char in section
    FB_defaultChar	Chars		; default character
else
    FB_firstChar	byte		; first char defined
    FB_lastChar		byte		; last char defined
    FB_defaultChar	byte		; default character
endif
    FB_underPos		WBFixed		; underline position (from baseline)
    FB_underThickness	WBFixed		; underline thickness
    FB_strikePos	WBFixed		; position of the strike-thru
    FB_aboveBox		WBFixed		; maximum above font box
    FB_belowBox		WBFixed		; maximum below font box
	; Bounds are signed integers, in device coords, and are
	; measured from the upper left of the font box where
	; character drawing starts from.
    FB_minLSB		sword		; minimum left side bearing
    FB_minTSB		sword		; minimum top side bound
if not DBCS_PCGEOS
    FB_maxBSB		sword		; maximum bottom side bound
    FB_maxRSB		sword		; maximum right side bound
endif
    FB_pixHeight	word		; height of font (invalid for rotation)
    FB_flags		FontBufFlags	; special flags
    FB_heapCount	word		; usage counter for this font
    FB_charTable	CharTableEntry <>
    */
} FontBuf;


typedef struct
{
    TextStyle                   ODE_style;
    FontWeight                  ODE_weight;
#ifdef DBCS_PCGEOS
    word                        ODE_extraData;
#else
    TrueTypeOutlineEntry       ODE_header;
    TrueTypeOutlineEntry       ODE_first;
    TrueTypeOutlineEntry       ODE_second;
#endif
} OutlineDataEntry;

/***********************************************************************
 *      helperfunctions
 ***********************************************************************/

static Boolean  isMappedFont( const char* familiyName );

static FontID   getMappedFontID( const char* familyName );

static int      toHash( const char* str );

static FontAttrs mapFamilyClass( TT_Short familyClass );



static int       strlen( const char* str );

static void      strcpy( char* dest, const char* source );

#endif /* _TTADAPTER_H_ */

