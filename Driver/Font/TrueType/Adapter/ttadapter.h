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
#include <graphics.h>
#include "../FreeType/freetype.h"
#include "../FreeType/ttengine.h"
#include "../FreeType/ttcalc.h"


/***********************************************************************
 *      global dgoup objects
 ***********************************************************************/

extern TEngine_Instance engineInstance;


#define TTF_DIRECTORY                       "TTF"
#define FONT_MAN_ID                         0x20

#define CHAR_NOT_EXIST                      0
#define CHAR_NOT_LOADED                     1
#define CHAR_NOT_BUILT                      2
#define CHAR_MISSING                        3	

#define WWFIXED_0_POINT_5                   0x00008000
#define WWFIXED_1_POINR_1                   0x00012000

#define ITALIC_FACTOR                       0x0000366A
#define BOLD_FACTOR                         0x00012000 
#define SCRIPT_FACTOR                       0x00008000
#define SCRIPT_SHIFT_FACTOR                 0x00015000

#define SUPERSCRIPT_OFFSET                  0x00006000
#define SUBSCRIPT_OFFSET                    0x00001a00


#define MAX_BITMAP_SIZE		                125
#define MAX_FONTBUF_SIZE                    10 * 1024
#define INITIAL_BITMAP_BLOCKSIZE            2 * 1024
#define REGION_SAFETY                       400

#define FAMILY_NAME_LENGTH                  20
#define STYLE_NAME_LENGTH                   16

#define MAX_KERN_TABLE_LENGTH               6000

#define STANDARD_GRIDSIZE                   1000


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
    wchar                       FAE_fileName[FILE_LONGNAME_BUFFER_SIZE];
#else
    char                        FAE_fileName[FILE_LONGNAME_BUFFER_SIZE];
#endif
    ChunkHandle                 FAE_infoHandle;
} FontsAvailEntry;


/*
 * drivers FontInfo structure (see fontDr.def)
 */
typedef struct
{
    FileHandle                  FI_fileHandle;
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
    wchar                       TTOE_fontFileName[FILE_LONGNAME_BUFFER_SIZE]
#else
    char                        TTOE_fontFileName[FILE_LONGNAME_BUFFER_SIZE];
#endif
} TrueTypeOutlineEntry;


/*
 * flags for describing rendered char (see fontDr.def)
 */
typedef ByteFlags CharTableFlags;
#define CTF_NEGATIVE_LSB    0x40    //set is negativ left side bearing
#define	CTF_ABOVE_ASCENT    0x20
#define CTF_BELOW_DESCENT   0x10
#define CTF_NO_DATA         0x08    //set if char is missing in chracter set
#define CTF_IS_FIRST_KERN   0x04
#define	CTF_IS_SECOND_KERN  0x02
#define	CTF_NOT_VISIBLE     0x01    //set if char is normally invisible


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
    word                        FB_kernPairs;     //offset to kerning pair table
    word                        FB_kernValues;    //offset to kerning value table
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
#define AW_BLACK                125


typedef struct 
{
    dword                       OE_offset;      /* offset in file */
    word                        OE_size;        /* size in bytes) */
    ChunkHandle                 OE_handle;      /* handle (if loaded) */
} OutlineEntry;

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
    OutlineEntry                ODE_header;
    OutlineEntry                ODE_first;
    OutlineEntry                ODE_second;
#endif
} OutlineDataEntry;

/*
 * drivers KernPair stucture (see fontDr.def)
 */
typedef struct
{
    char                        KP_charRight;
    char                        KP_charLeft;
} KernPair;

/*
 * drivers TransformMatrix structure
 */
typedef struct
{
    TT_Matrix                   TM_matrix;
    sword                       TM_scriptX;
    sword                       TM_heightX;
    sword                       TM_scriptY;
    sword                       TM_heightY;
} TransformMatrix;

typedef ByteFlags TransFlags;
#define TF_INV_VALID    0x08
#define TF_ROTATED      0x04
#define TF_SCALED       0x02 
#define TF_TRANSLATED   0x01

#define TF_COMPLEX      ( TF_ROTATED | TF_SCALED )

typedef struct
{
    WWFixedAsDWord              FM_11;
    WWFixedAsDWord              FM_12;
    WWFixedAsDWord              FM_21;
    WWFixedAsDWord              FM_22;
    DWFixed                     FM_31;
    DWFixed                     FM_32;
    DDFixed                     FM_xInv;    /* inverse translation factor (x coords) */
    DDFixed                     FM_yInv;    /* inverse translation factor (y coords) */
    TransFlags                  FM_flags;
} FontMatrix;


/*
 * drivers CharData structure (see fontDr.def)
 */
typedef struct 
{
    byte                        CD_pictureWidth;
    byte                        CD_numRows;
    sbyte                       CD_yoff;
    sbyte                       CD_xoff;
    byte                        CD_data;
} CharData;

#define SIZE_CHAR_HEADER        ( sizeof( CharData ) - 1 )


/*
 * drivers RegionCharData structure (see fontDr.def)
 */
typedef struct
{
    sword                       RCD_yoff;       /* (signed) offset to first row */
    sword                       RCD_xoff;       /* (signed) offset to first column */
    word                        RCD_size;       /* size of region (in bytes) */
#if DBCS_PCGEOS
    word                        RCD_usage;      /* LRU count */
#endif
    Rectangle                   RCD_bounds;     /* bounding box of region */
    word                        RCD_data;       /* data for region */
} RegionCharData;

#define SIZE_REGION_HEADER	    ( sizeof( RegionCharData) - 2 )


typedef struct
{
    word                        FH_h_height;        //top of 'H'
    word                        FH_x_height;        //top of 'x'
    word                        FH_ascender;        //top of 'd'
    word                        FH_descender;       //bottom of 'p'
    word                        FH_avgwidth;        //average character width
    word                        FH_maxwidth;        //widest character width
    word                        FH_height;          //height of font box
    word                        FH_accent;          //height of accents
    word                        FH_ascent;          //height of caps
    word                        FH_descent;         //descent (from baseline)
    word                        FH_baseAdjust;      //adjustment for baseline
    char                        FH_firstChar;       //first char defined
    char                        FH_lastChar;        //last char defined
    char                        FH_defaultChar;     //default character
    word                        FH_underPos;        //position of underline   		
    word                        FH_underThick;      //thickness of underline
    word                        FH_strikePos;       //position of strikethrough
    word                        FH_numChars;        //number of characters
    sword                       FH_minLSB;          //minimum left side bearing
    sword                       FH_minTSB;          //minimum top side bound
    sword                       FH_maxBSB;          //maximum bottom side bound
    sword                       FH_maxRSB;          //maximum right side bound
    word                        FH_kernCount;       //num of kerning pairs
} FontHeader;


typedef struct
{
    /* init fonts */
    char                        familyName[FID_NAME_LEN];
    char                        styleName[STYLE_NAME_LENGTH];

    /* scaling */
    WWFixedAsDWord              scaleHeight;
    WWFixedAsDWord              scaleWidth;

    /* render glyphs */
    TT_Raster_Map               rasterMap;

    /* general purpose */
    TT_Face                     face;
    TT_Face_Properties          faceProperties; 
    TT_Instance                 instance;
    TT_Instance_Metrics         instanceMetrics;
    TT_Glyph                    glyph;
    TT_Glyph_Metrics            glyphMetrics;
    TT_CharMap                  charMap;
    TT_Outline                  outline;
    TT_BBox                     bbox;

    /* currently open face */
    FileHandle                  ttfile;
    TrueTypeOutlineEntry        entry;
} TrueTypeVars;


#define TRUETYPE_VARS           TrueTypeVars* trueTypeVars

#define FAMILY_NAME             trueTypeVars->familyName
#define STYLE_NAME              trueTypeVars->styleName
#define FACE                    trueTypeVars->face
#define FACE_PROPERTIES         trueTypeVars->faceProperties
#define INSTANCE                trueTypeVars->instance
#define INSTANCE_METRICS        trueTypeVars->instanceMetrics
#define GLYPH                   trueTypeVars->glyph
#define CHAR_MAP                trueTypeVars->charMap
#define OUTLINE                 trueTypeVars->outline
#define GLYPH_METRICS           trueTypeVars->glyphMetrics
#define GLYPH_BBOX              trueTypeVars->glyphMetrics.bbox
#define RASTER_MAP              trueTypeVars->rasterMap
#define SCALE_HEIGHT            trueTypeVars->scaleHeight
#define SCALE_WIDTH             trueTypeVars->scaleWidth
#define TTFILE                  trueTypeVars->ttfile

#define UNITS_PER_EM            FACE_PROPERTIES.header->Units_Per_EM


/***********************************************************************
 *      macros
 ***********************************************************************/

/*
 * convert value (word) to WWFixedAsDWord
 */
#define WORD_TO_WWFIXEDASDWORD( value )          \
        ( (WWFixedAsDWord) MakeWWFixed( value ) )

/*
 * convert value (TT_F26DOT6) to WWFixedAsDWord
 */
#define FIXED26DOT6_TO_WWFIXEDASDWORD( value )   \
        ( (WWFixedAsDWord)value << 10 )

#define WWFIXEDASDWORD_TO_FIXED26DOT6( value )   \
        ( (TT_F26Dot6)value >> 10 )

/*
 * scale value (word) by factor (WWFixedAsDWord)
 */
#define SCALE_WORD( value, factor )              \
        ( GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( value ), factor ) )

/*
 * round value (WWFixedAsDWord) to nearest word
 */
#define ROUND_WWFIXEDASDWORD( value )            \
        ( value & 0x8000 ?                       \
            ( value & 0x0080 ? ( ( (sword)(value >> 16) ) - 1 ) : ( (sword)(value >> 16) ) ) : \
            ( value & 0x0080 ? ( ( (sword)(value >> 16) ) + 1 ) : ( (sword)(value >> 16) ) ) )

/*
 * round value (WWFixedAsDWord) to negativ infinity (word) 
 */
#define CEIL_WWFIXEDASDWORD( value )             \
        ( value & 0x8000 ?                       \
            ( value & 0x00ff ? ( ( value >> 16 ) - 1 ) : ( ( value >> 16 ) ) ) : \
            ( value >> 16 ) )

#define CEIL( value )       ( value & 0x000000ff ? ( value >> 16 ) + 1 : ( value ) ) 

/*
 * get integral part of value (WWFixedAsDWord)
 */
#define INTEGER_OF_WWFIXEDASDWORD( value )       \
        ( (sword) ( (WWFixedAsDWord)value >> 16 ) )

/*
 * get fractional part (reduced to 8 bit) of value (WWFixedAsDWord)
 */
#define FRACTION_OF_WWFIXEDASDWORD( value )      \
        ( (byte) ( (WWFixedAsDWord)value >> 8 ) )

/*
 * convert value (WBFixed) to WWFixedAsDWord 
 */
#define WBFIXED_TO_WWFIXEDASDWORD( value )       \
        ( (long) ( ( (long)(value.WBF_int) ) * 0x00010000 ) | ( ( (long)value.WBF_frac) << 8 ) )


/***********************************************************************
 *      functions
 ***********************************************************************/

Boolean TrueType_Lock_Face(TRUETYPE_VARS, TrueTypeOutlineEntry* entry);
void TrueType_Unlock_Face(TRUETYPE_VARS);
void TrueType_Free_Face(TRUETYPE_VARS);

#endif /* _TTADAPTER_H_ */
