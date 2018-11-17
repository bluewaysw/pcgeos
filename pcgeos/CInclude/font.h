/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	font.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines font structures and routines
 *
 *	$Id: font.h,v 1.1 97/04/04 15:56:46 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__FONT_H
#define __FONT_H

#include <fontID.h>

/* Font Constants */

#define DEFAULT_FONT_ID		FID_BERKELEY
#define DEFAULT_FONT_SIZE	10
#define FID_NAME_LEN		20

#define MIN_POINT_SIZE		4

#ifdef DO_DBCS
#define MAX_POINT_SIZE		432
#else
#define MAX_POINT_SIZE		792
#endif

/* Font Manufacturers */

typedef WordFlags FontIDRecord;
#define FIDR_maker	0xf000
#define FIDR_ID		0x0fff

#define FIDR_maker_OFFSET	12
#define FIDR_ID_OFFSET		0

/* Font Type */

typedef ByteFlags FontAttrs;
#define FA_USEFUL 	0x80
#define FA_FIXED_WIDTH	0x40
#define FA_ORIENT	0x20
#define FA_OUTLINE	0x10
#define FA_FAMILY	0x0f

#define FA_FAMILY_OFFSET	0

/* Font Weights */

typedef ByteEnum    FontWeight;
#define FW_MINIMUM  75
#define FW_NORMAL   100
#define FW_MAXIMUM  125


/* Font Widths */

typedef ByteEnum    FontWidth;
#define    FWI_MINIMUM 	    25
#define    FWI_NARROW 	    75
#define    FWI_CONDENSED    85
#define    FWI_MEDIUM 	    100
#define    FWI_WIDE 	    125
#define    FWI_EXPANDED     150
#define    FWI_MAXIMUM 	    20

/***/

#define MAX_FONTS	400
#define MAX_MENU_FONTS	10

/***/

typedef struct {
    FontID	FES_ID;
    TCHAR	FES_name[FID_NAME_LEN];
} FontEnumStruct;

typedef ByteFlags FontEnumFlags;
#define FEF_ALPHABETIZE	0x80
#define FEF_USEFUL	0x40
#define FEF_FIXED_WIDTH	0x20
#define FEF_FAMILY	0x10
#define FEF_STRING	0x08
#define FEF_DOWNCASE	0x04
#define FEF_BITMAPS	0x02
#define FEF_OUTLINES	0x01

extern word	/*XXX*/
    _pascal GrEnumFonts(FontEnumStruct *buffer, word size, FontEnumFlags flags,
		word family);

/***/

extern FontID	/*XXX*/
    _pascal GrCheckFontAvailID(FontEnumFlags flags, word family, FontID id);

extern FontID	/*XXX*/
    _pascal GrCheckFontAvailName(FontEnumFlags flags, word family, const char *name);

/***/

extern Boolean	/*XXX*/
    _pascal GrFindNearestPointsize(FontID id, dword sizeSHL16, word styles,
			   word *styleFound, dword *sizeFoundSHL16);

/***/

extern FontID	/*XXX*/
    _pascal GrGetDefFontID(dword *sizeSHL16);

/***/

typedef enum /* word */ {
    GCMI_MIN_X,
    GCMI_MIN_X_ROUNDED,
    GCMI_MIN_Y,
    GCMI_MIN_Y_ROUNDED,
    GCMI_MAX_X,
    GCMI_MAX_X_ROUNDED,
    GCMI_MAX_Y,
    GCMI_MAX_Y_ROUNDED,
} GCM_info;

extern dword		/* value << 16  or value */	/*XXX*/
    _pascal GrCharMetrics(GStateHandle gstate, GCM_info info, word ch);

/***/

typedef enum /* word */ {
    GFMI_HEIGHT=0, /* 0 */
    GFMI_HEIGHT_ROUNDED=1,
    GFMI_MEAN=2,
    GFMI_MEAN_ROUNDED=3,
    GFMI_DESCENT=4,
    GFMI_DESCENT_ROUNDED=5,
    GFMI_BASELINE=6,
    GFMI_BASELINE_ROUNDED=7,
    GFMI_LEADING=8,
    GFMI_LEADING_ROUNDED=9,
    GFMI_AVERAGE_WIDTH=10, /* 10 */
    GFMI_AVERAGE_WIDTH_ROUNDED=11,
    GFMI_ASCENT=12,
    GFMI_ASCENT_ROUNDED=13,
    GFMI_MAX_WIDTH=14,
    GFMI_MAX_WIDTH_ROUNDED=15,
    GFMI_MAX_ADJUSTED_HEIGHT=16,
    GFMI_MAX_ADJUSTED_HEIGHT_ROUNDED=17,
    GFMI_UNDER_POS=18,
    GFMI_UNDER_POS_ROUNDED=19,
    GFMI_UNDER_THICKNESS=20, /* 20 */
    GFMI_UNDER_THICKNESS_ROUNDED=21,
    GFMI_ABOVE_BOX=22,
    GFMI_ABOVE_BOX_ROUNDED=23,
    GFMI_ACCENT=24,
    GFMI_ACCENT_ROUNDED=25,
    GFMI_DRIVER=26, /* 26 */
    GFMI_KERN_COUNT=28, /* 28 */
    GFMI_FIRST_CHAR=30, /* 30 */
    GFMI_LAST_CHAR=32, /* 32 */
    GFMI_DEFAULT_CHAR=34, /* 34 */
    GFMI_STRIKE_POS=36, /* 36 */
    GFMI_STRIKE_POS_ROUNDED=37,
    GFMI_BELOW_BOX=38,
    GFMI_BELOW_BOX_ROUNDED=39,
} GFM_info;

extern dword		/* value << 16  or value */	/*XXX*/
    _pascal GrFontMetrics(GStateHandle gstate, GFM_info info);

/***/

extern word	/*XXX*/
    _pascal GrGetFontName(FontID id, char *name);

/***/

extern void 	/*XXX*/
    _pascal GrSetFontWeight(GStateHandle gstate, FontWeight weight);

extern void 	/*XXX*/
    _pascal GrSetFontWidth(GStateHandle gstate, FontWidth width);

typedef ByteEnum SuperscriptPosition; 
#define SPP_DISPLAY     50
#define SPP_FOOTNOTE    40
#define SPP_ALPHA       45
#define SPP_NUMERATOR   50
#define SPP_DEFAULT     50

typedef ByteEnum SuperscriptSize; 
#define SPS_DISPLAY     55
#define SPS_FOOTNOTE    65
#define SPS_ALPHA       75
#define SPS_NUMERATOR   60
#define SPS_DEFAULT     50

typedef struct {
    SuperscriptPosition position;
    SuperscriptSize     size;
} SuperscriptAttr;

extern void 	/*XXX*/
    _pascal GrSetSuperscriptAttr(GStateHandle gstate, SuperscriptAttr attrs);

typedef ByteEnum SubscriptPosition; 
#define SBP_CHEMICAL    30
#define SBP_DENOMINATOR  0
#define SBP_DEFAULT     50

typedef ByteEnum SubscriptSize; 
#define SBS_CHEMICAL    65
#define SBS_DENOMINATOR 60
#define SBS_DEFAULT     50

typedef struct {
    SubscriptPosition position;
    SubscriptSize     size;
} SubscriptAttr;

extern void 	/*XXX*/
    _pascal GrSetSubscriptAttr(GStateHandle gstate, SubscriptAttr attrs);

extern FontWeight   /*XXX*/
    _pascal GrGetFontWeight(GStateHandle gstate);

extern FontWidth    /*XXX*/
    _pascal GrGetFontWidth(GStateHandle gstate);

extern SuperscriptAttr	/*XXX*/
    _pascal GrGetSuperscriptAttr(GStateHandle gstate);

extern SubscriptAttr	/*XXX*/
    _pascal GrGetSubscriptAttr(GStateHandle gstate);

/***/

#ifdef __HIGHC__
pragma Alias(GrEnumFonts, "GRENUMFONTS");
pragma Alias(GrCheckFontAvailID, "GRCHECKFONTAVAILID");
pragma Alias(GrCheckFontAvailName, "GRCHECKFONTAVAILNAME");
pragma Alias(GrFindNearestPointsize, "GRFINDNEARESTPOINTSIZE");
pragma Alias(GrGetDefFontID, "GRGETDEFFONTID");
pragma Alias(GrCharMetrics, "GRCHARMETRICS");
pragma Alias(GrFontMetrics, "GRFONTMETRICS");
pragma Alias(GrGetFontName, "GRGETFONTNAME");
pragma Alias(GrSetFontWeight, "GRSETFONTWEIGHT");
pragma Alias(GrSetFontWidth, "GRSETFONTWIDTH");
pragma Alias(GrSetSuperscriptAttr, "GRSETSUPERSCRIPTATTR");
pragma Alias(GrSetSubscriptAttr, "GRSETSUBSCRIPTATTR");
pragma Alias(GrGetFontWeight, "GRGETFONTWEIGHT");
pragma Alias(GrGetFontWidth, "GRGETFONTWIDTH");
pragma Alias(GrGetSuperscriptAttr, "GRGETSUPERSCRIPTATTR");
pragma Alias(GrGetSubscriptAttr, "GRGETSUBSCRIPTATTR");
#endif

#endif
