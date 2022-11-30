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
 *  and are also needed in c functions.
 ***********************************************************************/
#ifndef _TTADAPTER_H_
#define _TTADAPTER_H_

#include <geos.h>
#include <ec.h>
#include <fontID.h>
#include <file.h>
#include "../FreeType/freetype.h"
#include "../FreeType/ttengine.h"
#include "../FreeType/ttcalc.h"

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
#define STYLE_NAME_LENGTH          16


#define MAKE_FONTID( family )      ( FM_TRUETYPE | ( 0x0fff & toHash ( family )))

/***********************************************************************
 *      structures
 ***********************************************************************/

/*
 * drivers FontsAvialEntry structure (see fontDr.def)
 */
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


/*
 * drivers FontInfo structure (see fontDr.def)
 */
typedef struct
{
    FileHandle                  FI_fileHandle;
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


/*
 * drivers TrueTypeOutlineEntry structure (see truetypeVariable.def)
 */
typedef struct
{
#if DBCS_PCGEOS
    wchar                       TTOE_fontFileName[FONT_FILE_LENGTH]
#else
    char                        TTOE_fontFileName[FONT_FILE_LENGTH];
#endif
} TrueTypeOutlineEntry;


/*
 * flags for describing rendered char (see fontDr.def)
 */
typedef ByteFlags CharTableFlags;
#define CTF_NEGATIVE_LSB    0x40
#define	CTF_ABOVE_ASCENT    0x20
#define CTF_BELOW_DESCENT   0x10
#define CTF_NO_DATA         0x08
#define CTF_IS_FIRST_KERN   0x04
#define	CTF_IS_SECOND_KERN  0x02
#define	CTF_NOT_VISIBLE     0x01


/*
 * driver CharTableEntry structure (see fontDr.def)
 */
typedef struct 
{
    word                        CTE_dataOffset;   //nptr to data
    WBFixed                     CTE_width;
    CharTableFlags              CTE_flags;
#ifndef  DBCS_PCGEOS
    word                        CTE_usage;
#endif
} CharTableEntry;


/*
 * flags for font transforming (see fontDr.def)
 */
typedef ByteFlags FontGenPathFlags;
#define FGPF_SAVE_STATE     0x02
#define FGPF_POSTSCRIPT     0x01


/*
 * flags for font information (see fontDr.def)
 */
typedef ByteFlags FontBufFlags;
#define FBF_DEFAULT_FONT    0x80
#define FBF_MAPPED_FONT     0x40
#define FBF_IS_OUTLINE      0x10
#define FBF_IS_REGION       0x08
#define FBF_IS_COMPLEX      0x04
#define	FBF_IS_INVALID      0x02


/*
 * drivers FontBuf structure (see frontDr.def)
 */
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
    WBFixed                     FB_baseAdjust;
    WBFixed                     FB_baselinePos;
    WBFixed                     FB_descent;
    WBFixed                     FB_extLeading;
    word                        FB_kernCount;
    word                        FB_kernPairPtr;     //offset to kerning pair table
    word                        FB_kernValuePtr;    //offset to kerning value table
#ifdef DBCS_PCGEOS
    wchar                       FB_firstChar;
    wchar                       FB_lastChar;
    wchar                       FB_defaultChar;
#else
    char                        FB_firstChar;
    char                        FB_lastChar;
    char                        FB_defaultChar;
#endif
    WBFixed                     FB_underPos;
    WBFixed                     FB_underThickness;
    WBFixed                     FB_strikePos;
    WBFixed                     FB_aboveBox;
    WBFixed                     FB_belowBox;
    sword                       FB_minLSB;
    sword                       FB_minTSB;
#ifndef DBCS_PCGEOS
    sword                       FB_maxBSB;
    sword                       FB_maxRSB;
#endif
    word                        FB_pixHeight;
    FontBufFlags                FB_flags;
    word                        FB_heapCount;
} FontBuf;


/*
 * drivers AdjustedWeight structure
 */
typedef ByteEnum AdjustedWeight;
#define AW_ULTRA_LIGHT          80
#define AW_EXTRA_LIGHT		    85
#define AW_LIGHT		        90
#define AW_SEMI_LIGHT	        95
#define AW_MEDIUM		        100
#define AW_SEMI_BOLD	        105
#define AW_BOLD		            110
#define AW_EXTRA_BOLD	        115
#define AW_ULTRA_BOLD	        120


/*
 * drivers OutlineDataEntry structure (see fontDr.def)
 */
typedef struct
{
    TextStyle                   ODE_style;
    AdjustedWeight              ODE_weight;
#ifdef DBCS_PCGEOS
    word                        ODE_extraData;
#else
    TrueTypeOutlineEntry        ODE_header;
    TrueTypeOutlineEntry        ODE_first;
    TrueTypeOutlineEntry        ODE_second;
#endif
} OutlineDataEntry;


/***********************************************************************
 *      macros
 ***********************************************************************/

/*
 * convert value (word) to WWFixedAsDWord
 */
#define WORD_TO_WWFIXEDASDWORD( value )          \
        ( (WWFixedAsDWord)value << 16 )

/*
 * convert value (TT_F26DOT6) to WWFixedAsDWord
 */
#define FIXED26DOT6_TO_WWFIXEDASDWORD( value )   \
        ( (WWFixedAsDWord)value << 10 )

/*
 * copy from (WWFixedAsDWord) into to (WBFixed)
 */
#define FILL_WBFIXED( to, from )                 \
        ( to.WBF_int  = (sword)(from >> 16);     \
          to.WBF_frac = (byte)(from >> 8); )

/*
 * scale value (word) by factor (WWFixedAsDWord)
 */
#define SCALE( value, factor )                   \
        (   GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( value ), factor ) )

/*
 * convert value (WBFixed) to TT_F26DOT6 
 */
#define WBFIXED_TO_FIXED26DOT6( value )          \
        ( ( ( (long)value.WBF_int ) * 1024 ) | value.WBF_frac >> 2 )

/***********************************************************************
 *      helperfunctions
 ***********************************************************************/

static Boolean      isMappedFont( const char* familiyName );

static FontID       getMappedFontID( const char* familyName );

static int          toHash( const char* str );

static FontAttrs    mapFamilyClass( TT_Short familyClass );

static FontWeight   mapFontWeight( TT_Short weightClass );

static TextStyle    mapTextStyle( const char* subfamily );


static int          strlen( const char* str );

static void         strcpy( char* dest, const char* source );


#endif /* _TTADAPTER_H_ */

