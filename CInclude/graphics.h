/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	graphics.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines graphics structures and routines.
 *
 *	$Id: graphics.h,v 1.1 97/04/04 15:56:44 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__GRAPHICS_H
#define __GRAPHICS_H

#include <fontID.h>
#include <font.h>
#include <color.h>

/* return info for GrGetCharInfo */
typedef ByteFlags CharInfo;
#define CI_NEGATIVE_LSB 0x40	/* TRUE if negative left-side bearing */
#define	CI_ABOVE_ASCENT 0x20	/* TRUE if very tall */
#define	CI_BELOW_DESCENT 0x10	/* TRUE if very low */
#define	CI_NO_DATA 0x08		/* TRUE if no data */
#define	CI_IS_FIRST_KERN 0x04	/* TRUE if first of a kern pair */
#define	CI_IS_SECOND_KERN 0x02	/* TRUE if second of a kern pair */

/* Maximum allowed values */

#define MIN_TRACK_KERNING	(-150)
#define MAX_TRACK_KERNING	500

#define MAX_KERN_VALUE		0x7ff0
#define MIN_KERN_VALUE		0x8001

/***/

typedef ByteEnum Justification;
#define J_LEFT 0
#define J_RIGHT 1
#define J_CENTER 2
#define J_FULL 3

/***/

/* structure for a draw mask -- the default mask has all bits set */

typedef byte DrawMask[8];

/* constants for system patterns and draw masks */

typedef ByteEnum SystemDrawMask;
#define SDM_TILE 0
#define SDM_SHADED_BAR 1
#define SDM_HORIZONTAL 2
#define SDM_VERTICAL 3
#define SDM_DIAG_NE 4
#define SDM_DIAG_NW 5
#define SDM_GRID 6
#define SDM_BIG_GRID 7
#define SDM_BRICK 8
#define SDM_SLANT_BRICK 9
#define SDM_0    89
#define SDM_12_5    81
#define SDM_25    73
#define SDM_37_5    65
#define SDM_50    57
#define SDM_62_5    49
#define SDM_75    41
#define SDM_87_5    33
#define SDM_100    25
#define SDM_CUSTOM 0x7f

#define SET_CUSTOM_PATTERN	SDM_CUSTOM

/* record to pass to GrSetXXXXMask */

typedef ByteFlags SysDrawMask;
#define SDM_INVERSE	0x80
#define SDM_MASK	0x7f

/* Bitmap / Raster Constants and Structures */

/* Record for ImageFlags */

typedef ByteFlags ImageFlags;
#define	IF_BORDER   0x08
#define IF_BITSIZE  0x07

/* Enum for GrDrawImage pixel sizes */
typedef ByteEnum ImageBitSize;
#define	IBS_1	0
#define	IBS_2	1
#define	IBS_4	2
#define	IBS_8	3
#define	IBS_16	4

/* Enum for B_compact */

typedef ByteEnum BMCompact;
#define BMC_UNCOMPACTED 0
#define BMC_PACKBITS 1
#define BMC_LZG 2
#define BMC_USER_DEFINED 0x80

/* Enum for BMT_FORMAT */

typedef ByteEnum BMFormat;
#define BMF_MONO  0
#define BMF_4BIT  1
#define BMF_8BIT  2
#define BMF_24BIT 3
#define BMF_4CMYK 4
#define BMF_3CMY  5

/* Record for B_type */

typedef ByteFlags BMType;
#define BMT_PALETTE	0x40
#define BMT_HUGE	0x20
#define BMT_MASK	0x10
#define BMT_COMPLEX	0x08
#define BMT_FORMAT	0x07

/* Simple Bitmap Structure */

typedef struct {
    word	B_width;
    word	B_height;
    byte	B_compact;
    byte	B_type;
} Bitmap;

/* Complex Bitmap Structure */

typedef struct {
    Bitmap	CB_simple;
    word	CB_startScan;
    word	CB_numScans;
    word	CB_devInfo;
    word	CB_data;
    word	CB_palette;
    word	CB_xres;
    word	CB_yres;
} CBitmap;

/***/

#define PATTERN_SIZE	8

/* different values for GS_mixMode */

typedef ByteEnum MixMode;
#define MM_CLEAR 0
#define MM_COPY 1
#define MM_NOP 2
#define MM_AND 3
#define MM_INVERT 4
#define MM_XOR 5
#define MM_SET 6
#define MM_OR 7

#define LAST_MIX_MODE	MM_OR

/* different values for color mapping modes */

typedef ByteEnum MapColorToMono;
#define CMT_CLOSEST 0
#define CMT_DITHER 1

typedef ByteFlags ColorMapMode;
#define CMM_ON_BLACK	0x04
#define CMM_MAP_TYPE	0x01

#define LAST_MAP_MODE	mask CMM_MAP_TYPE or mask CMM_ON_BLACK

/* options for line style */

typedef ByteEnum LineStyle;
#define LS_SOLID 0
#define LS_DASHED 1
#define LS_DOTTED 2
#define LS_DASHDOT 3
#define LS_DASHDDOT 4
#define LS_CUSTOM 5

#define MAX_DASH_ARRAY_PAIRS	5

/* structure for a dash pair array */

typedef word	DashPairArray[MAX_DASH_ARRAY_PAIRS*2];

/* constants for line join */

typedef ByteEnum LineJoin;
#define LJ_MITERED 0
#define LJ_ROUND 1
#define LJ_BEVELED 2

#define LAST_LINE_JOIN_TYPE	LJ_BEVELED

/* constants for line end */

typedef ByteEnum LineEnd;
#define LE_BUTTCAP 0
#define LE_ROUNDCAP 1
#define LE_SQUARECAP 2

#define LAST_LINE_END_TYPE	LE_SQUARECAP

/* text styles */

typedef ByteFlags TextStyle;
#define TS_OUTLINE	0x40
#define TS_BOLD		0x20
#define TS_ITALIC	0x10
#define TS_SUPERSCRIPT	0x08
#define TS_SUBSCRIPT	0x04
#define TS_STRIKE_THRU	0x02
#define TS_UNDERLINE	0x01

/* text modes */

typedef ByteFlags TextMode;
#define TM_DRAW_CONTROL_CHARS           0x80
	/* Does the following mapping when drawing text:
		   C_SPACE	   -> C_CNTR_DOT
		   C_NONBRKSPACE   -> C_CNTR_DOT
		   C_CR	           -> C_PARAGRAPH
		   C_TAB	   -> C_LOGICAL_NOT */
#define TM_TRACK_KERN			0x40
#define TM_PAIR_KERN			0x20
#define TM_PAD_SPACES			0x10
#define TM_DRAW_BASE			0x08
#define TM_DRAW_BOTTOM			0x04
#define TM_DRAW_ACCENT			0x02
#define TM_DRAW_OPTIONAL_HYPHENS	0x01

/* For Directional text support -- lshields 02/12/2002 */
typedef ByteEnum TextDirection ;
#define TD_LEFT_TO_RIGHT 0
#define TD_RIGHT_TO_LEFT 1

/* text misc modes */
typedef ByteFlags TextMiscMode;
#define TMMF_CHARACTER_JUSTIFICATION	0x80

/* Region Constants */

typedef word Region;

#define EOREGREC	0x8000
#define EOREG_HIGH	0x80

/* structure of a rectangular region */

typedef struct {
    word	RR_y1M1;
    word	RR_eo1;		/* EOREGREC */
    word	RR_y2;
    word	RR_x1;
    word	RR_x2;
    word	RR_eo2;		/* EOREGREC */
    word	RR_eo3;		/* EOREGREC */
} RectRegion;

/* macro for creating rectangular regions */

#define MakeRectRegion(left, top, right, bottom) \
		{(left), (top), (right), (bottom), (top) - 1, (EOREGREC), \
		     (bottom), (left), (right), (EOREGREC), (EOREGREC)}

/*
 * (x,y) values are often returned from functions.  To allow their easy return,
 * the type XYValueAsDWord is returned.  The DWORD_X() and DWORD_Y() macros
 * can be used to access the x and y components.
 * For functions returning 16-bit values, there is the possibility (with some
 * functions) that the return value for either X or Y cannot be expressed in
 * 16-bits.  This will happen most often if there is an extended (32-bit)
 * translation applied to the GState Transformation Matrix.  In those cases,
 * the value ERROR_COORD will be returned.
 */
typedef dword XYValueAsDWord;

#define DWORD_X(val) ((sword)( (val) & 0xffff ))
#define DWORD_Y(val) ((sword)( ((val) >> 16) & 0xffff ))
#define ERROR_COORD 	0x8000


/* standard structure for an X,Y pair */

typedef struct {
    sword	P_x;
    sword	P_y;
} Point;

typedef struct {
    WWFixed	PF_x;
    WWFixed	PF_y;
} PointWWFixed;

typedef struct {
    WBFixed	PWBF_x;
    WBFixed	PWBF_y;
} PointWBFixed;

typedef struct {
    DWFixed	PDF_x;
    DWFixed	PDF_y;
} PointDWFixed;

typedef struct {
    sdword	PD_x;
    sdword	PD_y;
} PointDWord;

typedef struct {
    sword	XYO_x;
    sword	XYO_y;
} XYOffset;

typedef struct {
    word	XYS_width;
    word	XYS_height;
} XYSize;

/* standard structure for a rectangle */

typedef struct {
    sword	R_left;
    sword	R_top;
    sword	R_right;
    sword	R_bottom;
} Rectangle;

typedef struct {
    sdword	RD_left;
    sdword	RD_top;
    sdword	RD_right;
    sdword	RD_bottom;
} RectDWord;

/***/
/* constants for region fill rule */

typedef ByteEnum RegionFillRule;
#define ODD_EVEN 0
#define WINDING 1

/* constants for GrNewPage */

typedef ByteEnum PageEndCommand;
#define PEC_FORM_FEED 0
#define PEC_NO_FORM_FEED 1

/* constants for filled arcs */

typedef enum /* word */ {
    ACT_OPEN,              /* Illegal for filled arcs */
    ACT_CHORD,             /* draw/fill as a chord */
    ACT_PIE                /* draw/fill as a pie */
} ArcCloseType;
/*
 * For backwards compatibility:
 */
#define OPEN  ACT_OPEN
#define CHORD ACT_CHORD
#define PIE   ACT_PIE

typedef struct {
    ArcCloseType    TPAP_close;
    PointWWFixed    TPAP_point1;
    PointWWFixed    TPAP_point2;
    PointWWFixed    TPAP_point3;
} ThreePointArcParams;

typedef struct {
    ArcCloseType    TPATP_close;
    PointWWFixed    TPATP_point2;
    PointWWFixed    TPATP_point3;
} ThreePointArcToParams;

typedef struct {
    ArcCloseType    TPRATP_close;
    PointWWFixed    TPRATP_delta2;
    PointWWFixed    TPRATP_delta3;
} ThreePointRelArcToParams;

/* Structures & Constants for Patterns */

typedef ByteEnum PatternType;
#define PT_SOLID 0
#define PT_SYSTEM_HATCH 1
#define PT_SYSTEM_BITMAP 2
#define PT_USER_HATCH 3
#define PT_USER_BITMAP 4
#define PT_CUSTOM_HATCH 5
#define PT_CUSTOM_BITMAP 6

typedef ByteEnum SystemHatch;
#define SH_VERTICAL 0
#define SH_HORIZONTAL 1
#define SH_45_DEGREE 2
#define SH_135_DEGREE 3
#define SH_BRICK 4
#define SH_SLANTED_BRICK 5
      
typedef struct {
    PatternType	HP_type;
    byte	HP_data;
} GraphicPattern;


/* Structures & Constants for Hatch Patterns */

typedef struct {
    WWFixed 	HD_on;
    WWFixed 	HD_off;
} HatchDash;

typedef	struct {
    PointWWFixed HL_origin;
    WWFixed 	HL_deltaX;
    WWFixed 	HL_deltaY;
    WWFixed 	HL_angle;
    ColorQuad	HL_color;
    word    	HL_numDashes;
    /* array of HatchDash structures follows here */
} HatchLine;

typedef	struct {
    word    	HP_numLines;
    /* array of HatchLine structures follows here */
} HatchPattern;

#define	MAX_CUSTOM_PATTERN_SIZE	16384


/* Constants for DrawRegion and DrawString */

#define PARAM_0		0x5000
#define PARAM_1		0x7000
#define PARAM_2		0x9000
#define PARAM_3		0xb000

/* Structure passed to transformation matrix routines */

/*
 * This structure defines a 3x3 transformation matrix.  Since only six of the
 * nine elements are actually used, the structure only has six elements.
 *
 *		e11	e12	0
 *		e21	e22	0
 *		e31	e32	1
 */

typedef struct {
    WWFixed	TM_e11;
    WWFixed	TM_e12;
    WWFixed	TM_e21;
    WWFixed	TM_e22;
    DWFixed	TM_e31;
    DWFixed	TM_e32;
} TransMatrix;


#define LARGEST_POSITIVE_COORDINATE	0x4000
#define LARGEST_NEGATIVE_COORDINATE	0xffffc000

#define MAX_COORD	LARGEST_POSITIVE_COORDINATE
#define MIN_COORD	LARGEST_NEGATIVE_COORDINATE

/*
 *	Pointer Picture Definition Structure
 */

#define STANDARD_CURSOR_IMAGE_SIZE	32
#define CURSOR_IMAGE_SIZE_32	       128
#define CURSOR_IMAGE_SIZE_64	       512

typedef struct {
    byte        PD_width;
    byte    	PD_height;
    sbyte	PD_hotX;
    sbyte	PD_hotY;
    byte	PD_mask[STANDARD_CURSOR_IMAGE_SIZE];
    byte	PD_image[STANDARD_CURSOR_IMAGE_SIZE];
} PointerDef16;

typedef struct {
    byte        PD_width;
    byte    	PD_height;
    sbyte	PD_hotX;
    sbyte	PD_hotY;
    byte	PD_mask[CURSOR_IMAGE_SIZE_32];
    byte	PD_image[CURSOR_IMAGE_SIZE_32];
} PointerDef32;

typedef struct {
    byte        PD_width;
    byte    	PD_height;
    sbyte	PD_hotX;
    sbyte	PD_hotY;
    byte	PD_mask[CURSOR_IMAGE_SIZE_64];
    byte	PD_image[CURSOR_IMAGE_SIZE_64];
} PointerDef64;

/***/

typedef ByteEnum GStringElement;
#define GR_END_GSTRING 0
#define GR_COMMENT 1
#define GR_NULL_OP 2
#define GR_SET_GSTRING_BOUNDS 3
#define GR_MISC_4 4
#define GR_MISC_5 5
#define GR_MISC_6 6
#define GR_MISC_7 7
#define GR_MISC_8 8
#define GR_MISC_9 9
#define GR_MISC_A 10
#define GR_MISC_B 11
#define GR_MISC_C 12
#define GR_LABEL 13 
#define GR_ESCAPE 14
#define GR_NEW_PAGE 15
#define GR_APPLY_ROTATION 16
#define GR_APPLY_SCALE 17
#define GR_APPLY_TRANSLATION 18
#define GR_APPLY_TRANSFORM 19
#define GR_APPLY_TRANSLATION_DWORD 20
#define GR_SET_TRANSFORM 21
#define GR_SET_NULL_TRANSFORM 22
#define GR_SET_DEFAULT_TRANSFORM 23
#define GR_INIT_DEFAULT_TRANSFORM 24
#define GR_SAVE_TRANSFORM 25
#define GR_RESTORE_TRANSFORM 26
#define GR_XFORM_1B 27
#define GR_XFORM_1C 28
#define GR_XFORM_1D 29
#define GR_XFORM_1E 30
#define GR_XFORM_1F 31
#define GR_DRAW_LINE 32
#define GR_DRAW_LINE_TO 33
#define GR_DRAW_REL_LINE_TO 34
#define GR_DRAW_HLINE 35
#define GR_DRAW_HLINE_TO 36
#define GR_DRAW_VLINE 37   
#define GR_DRAW_VLINE_TO 38
#define GR_DRAW_POLYLINE 39
#define GR_DRAW_ARC 40     
#define GR_DRAW_ARC_3POINT 41
#define GR_DRAW_ARC_3POINT_TO 42
#define GR_DRAW_REL_ARC_3POINT_TO 43
#define GR_DRAW_RECT 44
#define GR_DRAW_RECT_TO 45
#define GR_DRAW_ROUND_RECT 46
#define GR_DRAW_ROUND_RECT_TO 47
#define GR_DRAW_SPLINE 48
#define GR_DRAW_SPLINE_TO 49
#define GR_DRAW_CURVE 50
#define GR_DRAW_CURVE_TO 51
#define GR_DRAW_REL_CURVE_TO 52
#define GR_DRAW_ELLIPSE 53
#define GR_DRAW_POLYGON 54
#define GR_DRAW_POINT 55  
#define GR_DRAW_POINT_CP 56
#define GR_BRUSH_POLYLINE 57
#define GR_DRAW_CHAR 58
#define GR_DRAW_CHAR_CP 59
#define GR_DRAW_TEXT 60   
#define GR_DRAW_TEXT_CP 61
#define GR_DRAW_TEXT_FIELD 62
#define GR_DRAW_TEXT_PTR 63
#define GR_DRAW_TEXT_OPTR 64
#define GR_DRAW_PATH 65
#define GR_FILL_RECT 66
#define GR_FILL_RECT_TO 67
#define GR_FILL_ROUND_RECT 68
#define GR_FILL_ROUND_RECT_TO 69
#define GR_FILL_ARC 70
#define GR_FILL_POLYGON 71
#define GR_FILL_ELLIPSE 72
#define GR_FILL_PATH 73   
#define GR_FILL_ARC_3POINT 74
#define GR_FILL_ARC_3POINT_TO 75
#define GR_FILL_BITMAP 76
#define GR_FILL_BITMAP_CP 77
#define GR_FILL_BITMAP_OPTR 78
#define GR_FILL_BITMAP_PTR 79
#define GR_DRAW_BITMAP 80
#define GR_DRAW_BITMAP_CP 81
#define GR_DRAW_BITMAP_OPTR 82
#define GR_DRAW_BITMAP_PTR 83
#define GSE_BITMAP_SLICE 84
#define GR_OUTPUT_55 85    
#define GR_OUTPUT_56 86
#define GR_OUTPUT_57 87
#define GR_OUTPUT_58 88
#define GR_OUTPUT_59 89
#define GR_OUTPUT_5A 90
#define GR_OUTPUT_5B 91
#define GR_OUTPUT_5C 92
#define GR_OUTPUT_5D 93
#define GR_OUTPUT_5E 94
#define GR_OUTPUT_5F 95
#define GR_SAVE_STATE 96
#define GR_RESTORE_STATE 97
#define GR_SET_MIX_MODE 98 
#define GR_MOVE_TO 99     
#define GR_REL_MOVE_TO 100
#define GR_CREATE_PALETTE 101
#define GR_DESTROY_PALETTE 102
#define GR_SET_PALETTE_ENTRY 103
#define GR_SET_PALETTE 104
#define GR_SET_LINE_COLOR 105
#define GR_SET_LINE_MASK 106
#define GR_SET_LINE_COLOR_MAP 107
#define GR_SET_LINE_WIDTH 108    
#define GR_SET_LINE_JOIN 109
#define GR_SET_LINE_END 110
#define GR_SET_LINE_ATTR 111
#define GR_SET_MITER_LIMIT 112
#define GR_SET_LINE_STYLE 113
#define GR_SET_LINE_COLOR_INDEX 114
#define GR_SET_CUSTOM_LINE_MASK 115
#define GR_SET_CUSTOM_LINE_STYLE 116
#define GR_SET_AREA_COLOR 117
#define GR_SET_AREA_MASK 118
#define GR_SET_AREA_COLOR_MAP 119
#define GR_SET_AREA_ATTR 120     
#define GR_SET_AREA_COLOR_INDEX 121
#define GR_SET_CUSTOM_AREA_MASK 122
#define GR_SET_AREA_PATTERN 123
#define GR_SET_CUSTOM_AREA_PATTERN 124
#define GR_SET_TEXT_COLOR 125
#define GR_SET_TEXT_MASK 126
#define GR_SET_TEXT_COLOR_MAP 127
#define GR_SET_TEXT_STYLE 128    
#define GR_SET_TEXT_MODE 129
#define GR_SET_TEXT_SPACE_PAD 130
#define GR_SET_TEXT_ATTR 131     
#define GR_SET_FONT 132
#define GR_SET_TEXT_COLOR_INDEX 133
#define GR_SET_CUSTOM_TEXT_MASK 134
#define GR_SET_TRACK_KERN 135
#define GR_SET_FONT_WEIGHT 136
#define GR_SET_FONT_WIDTH 137
#define GR_SET_SUPERSCRIPT_ATTR 138
#define GR_SET_SUBSCRIPT_ATTR 139
#define GR_SET_TEXT_PATTERN 140  
#define GR_SET_CUSTOM_TEXT_PATTERN 141
#define GR_MOVE_TO_WWFIXED 142
#define GR_ATTR_8F 143
#define GR_ATTR_90 144
#define GR_ATTR_91 145
#define GR_ATTR_92 146
#define GR_ATTR_93 147
#define GR_ATTR_94 148
#define GR_ATTR_95 149
#define GR_ATTR_96 150
#define GR_ATTR_97 151
#define GR_ATTR_98 152
#define GR_ATTR_99 153
#define GR_ATTR_9A 154
#define GR_ATTR_9B 155
#define GR_ATTR_9C 156
#define GR_ATTR_9D 157
#define GR_ATTR_9E 158
#define GR_ATTR_9F 159
#define GR_BEGIN_PATH 160
#define GR_END_PATH 161  
#define GR_SET_CLIP_RECT 162
#define GR_SET_WIN_CLIP_RECT 163
#define GR_CLOSE_SUB_PATH 164
#define GR_SET_CLIP_PATH 165
#define GR_SET_WIN_CLIP_PATH 166
#define GR_SET_STROKE_PATH 167
#define GR_PATH_A8 168
#define GR_PATH_A9 169
#define GR_PATH_AA 170
#define GR_PATH_AB 171
#define GR_PATH_AC 172
#define GR_PATH_AD 173
#define GR_PATH_AE 174
#define GR_PATH_AF 175
#define NUM_GSTRING_CMDS 176

/***/

extern dword		/* width << 16 */
    _pascal GrCharWidth(GStateHandle gstate, word ch);

/***/

extern word	/*XXX*/
    _pascal GrTextWidth(GStateHandle gstate, const char *str, word size);

/***/

extern CharInfo	/*XXX*/
    _pascal GrGetCharInfo(GStateHandle gstate, word ch);

/***/

extern dword		/* width << 16 */	/*XXX*/
    _pascal GrTextWidthWWFixed(GStateHandle gstate, const char *str, word size);

/***/

extern MemHandle	/*XXX*/
    _pascal GrGetBitmap(GStateHandle gstate, sword x, sword y, word width,
				word height, XYSize *sizeCopied);

/***/

extern RGBColorAsDWord	/*XXX*/
    _pascal GrGetPoint(GStateHandle gstate, sword x, sword y);

/***/

extern VMBlockHandle	/*XXX*/
    _pascal GrCreateBitmap(BMFormat initFormat, word initWidth, word initHeight, 
		VMFileHandle vmFile, optr exposureOD, GStateHandle *bmgs);

/***/

extern VMBlockHandle	/*XXX*/
    _pascal GrCreateBitmapRaw(BMFormat initFormat, word initWidth, word initHeight, 
		VMFileHandle vmFile);

/***/

extern GStateHandle	/*XXX*/
    _pascal GrEditBitmap(VMFileHandle vmFile, VMBlockHandle vmBlock, optr exposureOD);

/***/

extern VMBlockHandle	/*XXX*/
    _pascal GrCompactBitmap(VMFileHandle srcFile, VMBlockHandle srcBlock, VMFileHandle destFile);

/***/

extern VMBlockHandle	/*XXX*/
    _pascal GrUncompactBitmap(VMFileHandle srcFile, VMBlockHandle srcBlock, VMFileHandle destFile);

/***/

typedef ByteEnum BMDestroy;
#define BMD_KILL_DATA 0
#define BMD_LEAVE_DATA 1

extern void	/*XXX*/
    _pascal GrDestroyBitmap(GStateHandle gstate, BMDestroy flags);

/***/

typedef WordFlags BitmapMode;
#define	BM_EDIT_MASK	    0x0002
#define BM_CLUSTERED_DITHER 0x0001

extern void 	/*XXX*/
    _pascal GrSetBitmapMode(GStateHandle gstate, word flags, MemHandle colorCorr);

/***/

extern word  	/*XXX*/
    _pascal GrGetBitmapMode(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrSetBitmapRes(GStateHandle gstate, word xRes, word yRes);

/***/

extern XYValueAsDWord	/*XXX*/
    _pascal GrGetBitmapRes(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrClearBitmap(GStateHandle gstate);

/***/

extern XYValueAsDWord	/*XXX*/
    _pascal GrGetBitmapSize(const Bitmap *bm);

/***/

extern XYValueAsDWord
    _pascal GrGetHugeBitmapSize(VMFileHandle vmFile, VMBlockHandle vmBlk);

/***/

extern void	/*XXX*/
    _pascal GrDrawRegion(GStateHandle gstate, sword xPos, sword yPos,
			const Region *reg, word cxParam, word dxParam);

/***/

extern void	/*XXX*/
    _pascal GrDrawRegionAtCP(GStateHandle gstate, const Region *reg,
		     word axParam, word bxParam, word cxParam, word dxParam);

/***/

extern void	/*XXX*/
    _pascal GrMoveReg(Region *reg, sword xOffset, sword yOffset);

/***/

extern word		/* returns region size */	/*XXX*/
    _pascal GrGetPtrRegBounds(const Region *reg, Rectangle *bounds);

/***/

extern Boolean	/*XXX*/
    _pascal GrTestPointInReg(const Region *reg, word xPos, word yPos,
		     Rectangle *boundingRect);

/***/

typedef ByteEnum TestRectReturnType;
#define TRRT_OUT 0
#define TRRT_PARTIAL 1
#define TRRT_IN 2

extern TestRectReturnType	/*XXX*/
    _pascal GrTestRectInReg(const Region *reg, sword left, sword top,
		    sword right, sword bottom);

/***/

extern TestRectReturnType	/*XXX*/
    _pascal GrTestRectInMask(GStateHandle gstate, sword left, sword top,
		    sword right, sword bottom);

/***/

#define WWFIXED_OVERFLOW 0x80000000

extern WWFixedAsDWord
    _pascal GrMulWWFixed(WWFixedAsDWord i, WWFixedAsDWord j);

/***/

extern void	/*XXX*/
    _pascal GrMulDWFixed(const DWFixed *i, const DWFixed *j, DWFixed *result);

/***/

extern WWFixedAsDWord	/*XXX*/
    _pascal GrSDivWWFixed(WWFixedAsDWord dividend, WWFixedAsDWord divisor);

/***/

extern WWFixedAsDWord	
    _pascal GrUDivWWFixed(WWFixedAsDWord dividend, WWFixedAsDWord divisor);

/***/

extern WWFixedAsDWord	/*XXX*/
    _pascal GrSqrRootWWFixed(WWFixedAsDWord i);

/***/

extern void	/*XXX*/
    _pascal GrSDivDWFbyWWF(const DWFixed *dividend,
		   const WWFixed *divisor,
		   DWFixed *quotient);

/***/
extern WWFixedAsDWord	/*XXX*/
    _pascal GrQuickSine(WWFixedAsDWord angle);

/***/

extern WWFixedAsDWord	/*XXX*/
    _pascal GrQuickCosine(WWFixedAsDWord angle);

/***/

extern WWFixedAsDWord	/*XXX*/
    _pascal GrQuickTangent(WWFixedAsDWord angle);

/***/

extern WWFixedAsDWord	/*XXX*/
    _pascal GrQuickArcSine(WWFixedAsDWord deltaYDivDistance, word origDeltaX);

/***/

extern GStateHandle
    _pascal GrCreateState(WindowHandle win);

/***/

extern void
    _pascal GrDestroyState(GStateHandle gstate);

/***/

extern void /*XXX*/
    _pascal GrSetVMFile(GStateHandle gstate, VMFileHandle vmFile);
						  
/***/

extern GStateHandle /*XXX*/
    _pascal GrGetExclusive(GeodeHandle videoDriver);
						  
/***/
						  
extern void /*XXX*/
    _pascal GrGrabExclusive(GeodeHandle videoDriver, GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrReleaseExclusive(GeodeHandle videoDriver, GStateHandle gstate,
		        Rectangle *bounds);

/***/

extern void	/*XXX*/
    _pascal GrTransformWWFixed(GStateHandle gstate, WWFixedAsDWord xPos,
			WWFixedAsDWord yPos, PointWWFixed *deviceCoordinates);

/***/

extern void	/*XXX*/
    _pascal GrTransformDWFixed(GStateHandle gstate, PointDWFixed *coord);

/***/

extern void	/*XXX*/
    _pascal GrUntransformWWFixed(GStateHandle gstate,
			 WWFixedAsDWord xPos,
			 WWFixedAsDWord yPos,
			 PointWWFixed *documentCoordinates);

/***/

extern void	/*XXX*/
    _pascal GrUntransformDWFixed(GStateHandle gstate, PointDWFixed *coord);

/***/

typedef enum /* word */ {
    BLTM_COPY,
    BLTM_MOVE,
    BLTM_CLEAR
} BLTMode;

extern void	/*XXX*/
    _pascal GrBitBlt(GStateHandle gstate, sword sourceX, sword sourceY, sword destX,
	     sword destY, word width, word height, BLTMode mode);

/***/

extern XYValueAsDWord	/*XXX*/
    _pascal GrTransform(GStateHandle gstate, sword xCoord, sword yCoord);

/***/

extern void	/*XXX*/
    _pascal GrTransformDWord(GStateHandle gstate, sdword xCoord,
			sdword yCoord, PointDWord *deviceCoordinates);

/***/

extern XYValueAsDWord	/*XXX*/
    _pascal GrUntransform(GStateHandle gstate, sword xCoord, sword yCoord);

/***/

extern void	/*XXX*/
    _pascal GrUntransformDWord(GStateHandle gstate, sdword xCoord,
			  sdword yCoord, PointDWord *documentCoordinates);

/***/

extern RGBColorAsDWord	/*XXX*/
    _pascal GrMapColorIndex(GStateHandle gstate, Color c);

/***/

extern RGBColorAsDWord	/*XXX*/
    _pascal GrMapColorRGB(GStateHandle gstate, word red, word green, word blue,
			  Color _far *index);

/***/

typedef ByteEnum GetPalType;
#define GPT_ACTIVE 0
#define GPT_DEFAULT 1

extern MemHandle	/*XXX*/
    _pascal GrGetPalette(GStateHandle gstate, GetPalType flag);

/***/

extern void	/*XXX*/
    _pascal GrSetPrivateData(GStateHandle gstate, word dataAX, word dataBX,
		     word dataCX, word dataDX);

/***/

extern MixMode	/*XXX*/
    _pascal GrGetMixMode(GStateHandle gstate);

/***/

extern RGBColorAsDWord	/*XXX*/
    _pascal GrGetLineColor(GStateHandle gstate);

/***/

extern RGBColorAsDWord	/*XXX*/
    _pascal GrGetAreaColor(GStateHandle gstate);

/***/

extern RGBColorAsDWord	/*XXX*/
    _pascal GrGetTextColor(GStateHandle gstate);

/***/

typedef ByteEnum GetMaskType;
#define GMT_ENUM 0
#define GMT_BUFFER 1

extern word	/* SysDrawMask */	/*XXX*/
    _pascal GrGetLineMask(GStateHandle gstate, DrawMask *dm);

/***/

extern word	/* SysDrawMask */	/*XXX*/
    _pascal GrGetAreaMask(GStateHandle gstate, DrawMask *dm);

/***/

extern word	/* SysDrawMask */	/*XXX*/
    _pascal GrGetTextMask(GStateHandle gstate, DrawMask *dm);

/***/

extern word	/* ColorMapMode */	/*XXX*/
    _pascal GrGetLineColorMap(GStateHandle gstate);

/***/

extern word	/* ColorMapMode */	/*XXX*/
    _pascal GrGetAreaColorMap(GStateHandle gstate);

/***/

extern word	/* ColorMapMode */	/*XXX*/
    _pascal GrGetTextColorMap(GStateHandle gstate);

/***/

extern WWFixedAsDWord	/*XXX*/
    _pascal GrGetTextSpacePad(GStateHandle gstate);

/***/

extern word	/* TextStyle */	/*XXX*/
    _pascal GrGetTextStyle(GStateHandle gstate);

/***/

extern word	/* TextDrawOffset */	/*XXX*/
    _pascal GrGetTextDrawOffset(GStateHandle gstate);

/***/

extern word	/* TextMode */	/*XXX*/
    _pascal GrGetTextMode(GStateHandle gstate);

/***/

extern WWFixedAsDWord	/*XXX*/
    _pascal GrGetLineWidth(GStateHandle gstate);

/***/

extern LineEnd	/*XXX*/
    _pascal GrGetLineEnd(GStateHandle gstate);

/***/

extern LineJoin	/*XXX*/
    _pascal GrGetLineJoin(GStateHandle gstate);

/***/

extern LineStyle	/*XXX*/
    _pascal GrGetLineStyle(GStateHandle gstate);

/***/

extern WWFixedAsDWord	/*XXX*/
    _pascal GrGetMiterLimit(GStateHandle gstate);

/***/

extern XYValueAsDWord
    _pascal GrGetCurPos(GStateHandle gstate);

/***/

extern void
    _pascal GrGetCurPosWWFixed(GStateHandle gstate,
			       PointWWFixed _far *cp);

/***/

typedef enum /* word */ {
    GIT_PRIVATE_DATA=0,
    GIT_WINDOW=2,
    GIT_PEN_POS=4
} GrInfoType;

extern void	/*XXX*/
    _pascal GrGetInfo(GStateHandle gstate, GrInfoType type, void *data);

/***/

extern void	/*XXX*/
    _pascal GrGetTransform(GStateHandle gstate, TransMatrix *tm);

/***/

extern FontID	/*XXX*/
    _pascal GrGetFont(GStateHandle gstate, WWFixedAsDWord *pointSize);

/***/

extern word	/*XXX*/
    _pascal GrGetTrackKern(GStateHandle gstate);

/***/

extern Boolean	/*XXX*/
    _pascal GrTestPointInPolygon(GStateHandle gstate, RegionFillRule rule, Point *list,
		       word numPoints, sword xCoord, sword yCoord);

/***/

typedef enum /* word */ {
    GSET_NO_ERROR,
    GSET_DISK_FULL
} GStringErrorType;

extern GStringErrorType	/*XXX*/
    _pascal GrEndGString(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrComment(GStateHandle gstate, const void *data, word size);

/***/

extern void	/*XXX*/
    _pascal GrNullOp(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrEscape(GStateHandle gstate, word code, const void *data, word size);

/***/

extern void	/*XXX*/
    _pascal GrSaveState(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrRestoreState(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrNewPage(GStateHandle gstate, PageEndCommand pageEndCommand);

/***/

extern void
    _pascal GrApplyRotation(GStateHandle gstate, WWFixedAsDWord angle);

/***/

extern void	/*XXX*/
    _pascal GrApplyScale(GStateHandle gstate, WWFixedAsDWord xScale,
		 WWFixedAsDWord yScale);

/***/

extern void	/*XXX*/
    _pascal GrApplyTranslation(GStateHandle gstate, WWFixedAsDWord xTrans,
		       WWFixedAsDWord yTrans);

/***/

extern void	/*XXX*/
    _pascal GrApplyTranslationDWord(GStateHandle gstate, sdword xTrans, sdword yTrans);

/***/

extern void	/*XXX*/
    _pascal GrSetTransform(GStateHandle gstate, const TransMatrix *tm);

/***/

extern void	/*XXX*/
    _pascal GrApplyTransform(GStateHandle gstate, const TransMatrix *tm);

/***/

extern void	/*XXX*/
    _pascal GrSaveTransform(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrRestoreTransform(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrSetNullTransform(GStateHandle gstate);

/***/

extern void	
    _pascal GrDrawLine(GStateHandle gstate, sword x1, sword y1, sword x2, sword y2);

/***/

extern void	/*XXX*/
    _pascal GrDrawLineTo(GStateHandle gstate, sword x, sword y);

/***/

extern void
    _pascal GrDrawRect(GStateHandle gstate, sword left, sword top, sword right,
	       sword bottom);

/***/

extern void	/*XXX*/
    _pascal GrDrawRectTo(GStateHandle gstate, sword x, sword y);

/***/

extern void	/*XXX*/
    _pascal GrDrawHLine(GStateHandle gstate, sword x1, sword y, sword x2);

/***/

extern void	/*XXX*/
    _pascal GrDrawHLineTo(GStateHandle gstate, sword x);

/***/

extern void	/*XXX*/
    _pascal GrDrawVLine(GStateHandle gstate, sword x, sword y1, sword y2);

/***/

extern void	/*XXX*/
    _pascal GrDrawVLineTo(GStateHandle gstate, sword y);

/***/

extern void	/*XXX*/
    _pascal GrDrawRoundRect(GStateHandle gstate, sword left, sword top, sword right,
		    sword bottom, word radius);

/***/

extern void	/*XXX*/
    _pascal GrDrawRoundRectTo(GStateHandle gstate, sword bottom, sword right,
		      word radius);

/***/

extern void	/*XXX*/
    _pascal GrDrawPoint(GStateHandle gstate, sword x, sword y);

/***/

extern void	/*XXX*/
    _pascal GrDrawPointAtCP(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrDrawBitmap(GStateHandle gstate, sword x, sword y, const Bitmap *bm,
		 PCB(Bitmap *, callback, (Bitmap *bm)));

/***/

extern void	/*XXX*/
    _pascal GrDrawBitmapAtCP(GStateHandle gstate, const Bitmap *bm,
		     PCB(Bitmap *, callback, (Bitmap *bm)));

/***/

extern void	/*XXX*/
    _pascal GrFillBitmap(GStateHandle gstate, sword x, sword y, const Bitmap *bm,
		 PCB(Bitmap *, callback, (Bitmap *bm)));

/***/

extern void	/*XXX*/
    _pascal GrFillBitmapAtCP(GStateHandle gstate, const Bitmap *bm,
		     PCB(Bitmap *, callback, (Bitmap *bm)));


/***/

extern void	/*XXX*/
    _pascal GrDrawHugeBitmap(GStateHandle gstate, sword x, sword y,
		     VMFileHandle vmFile, VMBlockHandle vmBlk);

/***/

extern void	/*XXX*/
    _pascal GrDrawHugeBitmapAtCP(GStateHandle gstate, 
			 VMFileHandle vmFile, VMBlockHandle vmBlk);

/***/

extern void	/*XXX*/
    _pascal GrFillHugeBitmap(GStateHandle gstate, sword x, sword y,
		     VMFileHandle vmFile, VMBlockHandle vmBlk);

/***/

extern void	/*XXX*/
    _pascal GrFillHugeBitmapAtCP(GStateHandle gstate, 
			 VMFileHandle vmFile, VMBlockHandle vmBlk);

/***/

extern void	/*XXX*/
    _pascal GrDrawImage(GStateHandle gstate, sword x, sword y, ImageFlags flags,
		 const Bitmap *bm);

/***/

extern void	/*XXX*/
    _pascal GrDrawHugeImage(GStateHandle gstate, sword x, sword y, ImageFlags flags,
		    	 VMFileHandle vmFile, VMBlockHandle vmBlk);

/***/

extern void	/*XXX*/
    _pascal GrDrawChar(GStateHandle gstate, sword x, sword y, word ch);

/***/

extern void	/*XXX*/
    _pascal GrDrawCharAtCP(GStateHandle gstate, word ch);

/***/

extern void
    _pascal GrDrawText(GStateHandle gstate, sword x, sword y, const char *str,
	       word size);

/***/

extern void
    _pascal GrDrawTextAtCP(GStateHandle gstate, const char *str, word size);

/***/

extern void	/*XXX*/
    _pascal GrDrawPolyline(GStateHandle gstate, const Point *points, word numPoints);
/***/

extern void	/*XXX*/
    _pascal GrBrushPolyline(GStateHandle gstate, const Point *points, word numPoints,
		    word brushH, word brushW);

/***/

extern void	/*XXX*/
    _pascal GrDrawEllipse(GStateHandle gstate, sword left, sword top,
		  sword right, sword bottom);

/***/

extern void	/*XXX*/
    _pascal GrDrawArc(GStateHandle gstate, sword left,
		                sword top, sword right, sword bottom,
				word startAngle, word endAngle,
				ArcCloseType closeType);

/***/

extern void	/*XXX*/
    _pascal GrDrawArc3Point (GStateHandle gstate, 
			     	const ThreePointArcParams *params);

/***/

extern void	/*XXX*/
    _pascal GrDrawArc3PointTo (GStateHandle gstate, 
			     	const ThreePointArcToParams *params);

/***/

extern void	/*XXX*/
    _pascal GrDrawRelArc3PointTo (GStateHandle gstate,
			     	const ThreePointRelArcToParams *params);

/***/

extern void	/*XXX*/
    _pascal GrDrawPolygon(GStateHandle gstate, const Point *points, word numPoints);
/***/

extern void 	/*XXX*/
    _pascal GrDrawSpline(GStateHandle gstate, const Point *points, word numPoints);

/***/
extern void 	/*XXX*/
    _pascal GrDrawSplineTo(GStateHandle gstate, const Point *points, word numPoints);

/***/

extern void 	/*XXX*/
    _pascal GrDrawCurve(GStateHandle gstate, const Point *points);

/***/

extern void 	/*XXX*/
    _pascal GrDrawCurveTo(GStateHandle gstate, const Point *points);


/***/

extern void
    _pascal GrFillRect(GStateHandle gstate, sword left, sword top, sword right,
	       sword bottom);

/***/

extern void	/*XXX*/
    _pascal GrFillRectTo(GStateHandle gstate, sword x, sword y);

/***/

extern void	/*XXX*/
    _pascal GrFillRoundRect(GStateHandle gstate, sword left, sword top, sword right,
		    sword bottom, word radius);

/***/

extern void	/*XXX*/
    _pascal GrFillRoundRectTo(GStateHandle gstate, sword right, sword bottom,
		      word radius);

/***/

extern void	/*XXX*/
    _pascal GrFillArc(GStateHandle gstate, sword left,
		                sword top, sword right, sword bottom,
				word startAngle, word endAngle,
				ArcCloseType closeType);

/***/

extern void	/*XXX*/
    _pascal GrFillArc3Point (GStateHandle gstate, 
			     	const ThreePointArcParams *params);

/***/

extern void	/*XXX*/
    _pascal GrFillArc3PointTo (GStateHandle gstate, 
			       	const ThreePointArcToParams *params);

/***/

extern void	
    _pascal GrFillPolygon(GStateHandle gstate, RegionFillRule windingRule,
		  const Point *points, word numPoints);

/***/

extern void
    _pascal GrFillEllipse(GStateHandle gstate, sword left, sword top, sword right,
		  sword bottom);

/***/

extern void	/*XXX*/
    _pascal GrSetMixMode(GStateHandle gstate, MixMode mode);

/***/

extern void	/*XXX*/
    _pascal GrRelMoveTo(GStateHandle gstate, WWFixedAsDWord x, WWFixedAsDWord y);

/***/

extern void	/*XXX*/
    _pascal GrMoveToWWFixed(GStateHandle gstate, WWFixedAsDWord x, WWFixedAsDWord y);

/***/

extern void	/*XXX*/
    _pascal GrDrawRelLineTo(GStateHandle gstate, WWFixedAsDWord x, WWFixedAsDWord y);

/***/

extern void
    _pascal GrMoveTo(GStateHandle gstate, sword x, sword y);

/***/

extern void	
    _pascal GrSetLineColor(GStateHandle gstate, ColorFlag flag, word redOrIndex,
		   word green, word blue);

/***/

extern void	/*XXX*/
    _pascal GrSetLineMaskSys(GStateHandle gstate, word sysDM);

extern void	/*XXX*/
    _pascal GrSetLineMaskCustom(GStateHandle gstate, const DrawMask *dm);

/***/

extern void	/*XXX*/
    _pascal GrSetLineColorMap(GStateHandle gstate, word colorMap);

/***/

extern void	
    _pascal GrSetLineWidth(GStateHandle gstate, WWFixedAsDWord width);

/***/

extern void	/*XXX*/
    _pascal GrSetLineJoin(GStateHandle gstate, LineJoin join);

/***/

extern void	/*XXX*/
    _pascal GrSetLineEnd(GStateHandle gstate, LineEnd end);

/***/


typedef struct {
    byte    	    	LA_colorFlag;
    RGBValue	    	LA_color;
    SystemDrawMask  	LA_mask;
    ColorMapMode    	LA_mapMode;
    LineEnd 	    	LA_end;
    LineJoin	    	LA_join;
    LineStyle	    	LA_style;
    WWFixed 	    	LA_width;
} LineAttr;

extern void	/*XXX*/
    _pascal GrSetLineAttr(GStateHandle gstate, const LineAttr *la);

/***/

extern void	/*XXX*/
    _pascal GrSetMiterLimit(GStateHandle gstate, WWFixedAsDWord limit);

/***/

extern void	/*XXX*/
    _pascal GrSetLineStyle(GStateHandle gstate, LineStyle style, word skipDistance,
		   const DashPairArray *dpa, word numPairs);

/***/

extern void
    _pascal GrSetAreaColor(GStateHandle gstate, ColorFlag flag, word redOrIndex,
		   word green, word blue);

/***/

extern void	/*XXX*/
    _pascal GrSetAreaMaskSys(GStateHandle gstate, word sysDM);

extern void	/*XXX*/
    _pascal GrSetAreaMaskCustom(GStateHandle gstate, const DrawMask *dm);

/***/

extern void	/*XXX*/
    _pascal GrSetAreaColorMap(GStateHandle gstate, word colorMap);

/***/

typedef struct {
    byte    	    AA_colorFlag;
    RGBValue	    AA_color;
    SystemDrawMask  AA_mask;
    ColorMapMode    AA_mapMode;
} AreaAttr;

extern void	/*XXX*/
    _pascal GrSetAreaAttr(GStateHandle gstate, const AreaAttr *aa);

/***/

extern void
    _pascal GrSetTextColor(GStateHandle gstate, ColorFlag flag, word redOrIndex,
		   word green, word blue);

/***/

extern void	/*XXX*/
    _pascal GrSetTextMaskSys(GStateHandle gstate, SysDrawMask sysDM);

extern void	/*XXX*/
    _pascal GrSetTextMaskCustom(GStateHandle gstate, const DrawMask *dm);

/***/

extern void	/*XXX*/
    _pascal GrSetTextColorMap(GStateHandle gstate, word colorMap);

/***/

extern void	/*XXX*/
    _pascal GrSetTextStyle(GStateHandle gstate, TextStyle bitsToSet,
		   TextStyle bitsToClear);

/***/

extern void	/*XXX*/
    _pascal GrSetTextMode(GStateHandle gstate, TextMode bitsToSet,
		  TextMode bitsToClear);

/***/

extern void	/*XXX*/
    _pascal GrSetTextDrawOffset(GStateHandle gstate, word numToDraw);

/***/

extern void	/*XXX*/
    _pascal GrSetTextSpacePad(GStateHandle gstate, WWFixedAsDWord padding);

/***/

typedef struct {
    ColorQuad		TA_color;
    SystemDrawMask	TA_mask;
    GraphicPattern	TA_pattern;
    TextStyle		TA_styleSet;
    TextStyle		TA_styleClear;
    TextMode		TA_modeSet;
    TextMode		TA_modeClear;
    WBFixed		TA_spacePad;
    FontID		TA_font;
    WBFixed		TA_size;
    sword		TA_trackKern;
    FontWeight	    	TA_fontWeight;
    FontWidth	    	TA_fontWidth;
} TextAttr;

extern void	/*XXX*/
    _pascal GrSetTextAttr(GStateHandle gstate, const TextAttr *ta);

/***/

extern void
    _pascal GrSetFont(GStateHandle gstate, FontID id, WWFixedAsDWord pointSize);

/***/

extern void	/*XXX*/
    _pascal GrSetGStringBounds(GStateHandle gstate, sword left, sword top,
		      sword right, sword bottom);

/***/

extern word	/*XXX*/
    _pascal GrCreatePalette(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrDestroyPalette(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrSetPaletteEntry(GStateHandle gstate, word index, word red, word green,
		      word blue);

/***/

extern void	/*XXX*/
    _pascal GrSetPalette(GStateHandle gstate, const RGBValue *buffer,
		 word index, word numEntries);

/***/

extern void	/*XXX*/
    _pascal GrSetTrackKern(GStateHandle gstate, word tk);

/***/

extern void	/*XXX*/
    _pascal GrInitDefaultTransform(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal GrSetDefaultTransform(GStateHandle gstate);

/***/

/*
 * Should not be needed anymore
#define SACRF_REPLACE	0x8000
#define SACRF_NULL	0x2000
#define SACRF_RECT	0x1000
*/

typedef enum /* word */ {
    PCT_NULL,
    PCT_REPLACE,
    PCT_UNION,
    PCT_INTERSECTION
} PathCombineType;

extern void	/*XXX*/
    _pascal GrSetClipRect(GStateHandle gstate, PathCombineType flags, 
			  sword left, sword top,  sword right, sword bottom);

/***/

extern void	/*XXX*/
    _pascal GrSetWinClipRect(GStateHandle gstate, PathCombineType flags,
			     sword left, sword top, sword right, sword bottom);

/***/


extern void 	/*XXX*/
    _pascal GrBeginPath(GStateHandle gstate, PathCombineType params);

extern void 	/*XXX*/
    _pascal GrEndPath(GStateHandle gstate);

extern void 	/*XXX*/
    _pascal GrCloseSubPath(GStateHandle gstate);

extern void 	/*XXX*/
    _pascal GrSetClipPath(GStateHandle gstate, PathCombineType params,
		  RegionFillRule rule);

extern void 	/*XXX*/
    _pascal GrSetWinClipPath(GStateHandle gstate,PathCombineType params,
		     RegionFillRule rule);

extern void 	/*XXX*/
    _pascal GrFillPath(GStateHandle gstate, RegionFillRule rule);

extern void 	/*XXX*/
    _pascal GrDrawPath(GStateHandle gstate);

extern void 	/*XXX*/
    _pascal GrSetStrokePath(GStateHandle gstate);

typedef enum /* word */ {
    GPT_CURRENT,
    GPT_CLIP,
    GPT_WIN_CLIP
} GetPathType;

extern Boolean 	/*XXX*/
    _pascal GrGetPathBounds(GStateHandle gstate,GetPathType ptype,Rectangle *bounds);

extern Boolean 	/*XXX*/
    _pascal GrGetPathBoundsDWord(GStateHandle gstate,GetPathType ptype,RectDWord *bounds);

extern Boolean 	/*XXX*/
    _pascal GrTestPath(GStateHandle gstate,GetPathType ptype);

extern void 	/*XXX*/
    _pascal GrInvalRect(GStateHandle gstate, sword left, sword top, sword right,
		sword bottom);

extern void 	/*XXX*/
    _pascal GrInvalRectDWord(GStateHandle gstate, const RectDWord *bounds);

extern void 	/*XXX*/
    _pascal GrGetWinBoundsDWord(GStateHandle gstate, RectDWord *bounds);

extern Boolean  /*XXX*/
    _pascal GrGetMaskBoundsDWord(GStateHandle gstate, RectDWord *bounds);

extern Boolean 	/*XXX*/
    _pascal GrGetWinBounds(GStateHandle gstate, Rectangle *bounds);

extern Boolean 	/*XXX*/
    _pascal GrGetMaskBounds(GStateHandle gstate, Rectangle *bounds);

extern WindowHandle 	/*XXX*/
    _pascal GrGetWinHandle(GStateHandle gstate);

extern Handle 	/*XXX*/
    _pascal GrGetGStringHandle(GStateHandle gstate);

extern void 	/*XXX*/
    _pascal GrSetVMFile(GStateHandle gstate, VMFileHandle vmFile);

extern Boolean 	    	/*XXX*/
    _pascal GrTestPointInPath(GStateHandle gstate, word xPos, word yPos,
		      RegionFillRule rule);

extern MemHandle 	/*XXX*/
    _pascal GrGetPath(GStateHandle gstate, GetPathType ptype);

extern Boolean 	    	/*XXX*/
    _pascal GrTestPath(GStateHandle gstate, GetPathType ptype);

extern MemHandle 	/*XXX*/
    _pascal GrGetPathPoints(GStateHandle gstate, word resolution);

extern MemHandle 	/*XXX*/
    _pascal GrGetPathRegion(GStateHandle gstate, RegionFillRule rule);

extern MemHandle 	/*XXX*/
    _pascal GrGetClipRegion(GStateHandle gstate, RegionFillRule rule);

extern void 	    	/*XXX*/
    _pascal GrSetAreaPattern (GStateHandle gstate, GraphicPattern pattern);

extern void 	    	/*XXX*/
    _pascal GrSetCustomAreaPattern (GStateHandle gstate, GraphicPattern pattern,
			    const void *patternData, word patternSize);

extern void 	    	/*XXX*/
    _pascal GrSetTextPattern (GStateHandle gstate, GraphicPattern pattern);

extern void 	    	/*XXX*/
    _pascal GrSetCustomTextPattern (GStateHandle gstate, GraphicPattern pattern,
			    const void *patternData);

extern GraphicPattern	/*XXX*/
    _pascal GrGetAreaPattern (GStateHandle gstate,
		      const MemHandle *customPattern, word *customSize);

extern GraphicPattern	/*XXX*/
    _pascal GrGetTextPattern (GStateHandle gstate,
		      const MemHandle *customPattern, word *customSize);

extern Boolean
    _pascal GrGetTextBounds(GStateHandle gstate, const char _far *str, 
			    word xpos, word ypos, 
			    word count, Rectangle *bounds);

extern void
    _pascal GrSetTextDirection(GStateHandle gstate, TextDirection dir) ;

#ifdef __HIGHC__
pragma Alias(GrCharWidth, "GRCHARWIDTH");
pragma Alias(GrTextWidth, "GRTEXTWIDTH");
pragma Alias(GrGetCharInfo, "GRGETCHARINFO");
pragma Alias(GrTextWidthWWFixed, "GRTEXTWIDTHWWFIXED");
pragma Alias(GrGetBitmap, "GRGETBITMAP");
pragma Alias(GrGetPoint, "GRGETPOINT");
pragma Alias(GrCreateBitmap, "GRCREATEBITMAP");
pragma Alias(GrEditBitmap, "GREDITBITMAP");
pragma Alias(GrCompactBitmap, "GRCOMPACTBITMAP");
pragma Alias(GrUncompactBitmap, "GRUNCOMPACTBITMAP");
pragma Alias(GrDestroyBitmap, "GRDESTROYBITMAP");
pragma Alias(GrSetBitmapMode, "GRSETBITMAPMODE");
pragma Alias(GrGetBitmapMode, "GRGETBITMAPMODE");
pragma Alias(GrSetBitmapRes, "GRSETBITMAPRES");
pragma Alias(GrGetBitmapRes, "GRGETBITMAPRES");
pragma Alias(GrClearBitmap, "GRCLEARBITMAP");
pragma Alias(GrGetBitmapSize, "GRGETBITMAPSIZE");
pragma Alias(GrGetHugeBitmapSize, "GRGETHUGEBITMAPSIZE");
pragma Alias(GrDrawRegion, "GRDRAWREGION");
pragma Alias(GrDrawRegionAtCP, "GRDRAWREGIONATCP");
pragma Alias(GrMoveReg, "GRMOVEREG");
pragma Alias(GrGetPtrRegBounds, "GRGETPTRREGBOUNDS");
pragma Alias(GrTestPointInReg, "GRTESTPOINTINREG");
pragma Alias(GrTestRectInReg, "GRTESTRECTINREG");
pragma Alias(GrTestRectInMask, "GRTESTRECTINMASK");
pragma Alias(GrMulWWFixed, "GRMULWWFIXED");
pragma Alias(GrMulDWFixed, "GRMULDWFIXED");
pragma Alias(GrSDivWWFixed, "GRSDIVWWFIXED");
pragma Alias(GrUDivWWFixed, "GRUDIVWWFIXED");
pragma Alias(GrSqrRootWWFixed, "GRSQRROOTWWFIXED");
pragma Alias(GrSDivDWFbyWWF, "GRSDIVDWFBYWWF");
pragma Alias(GrQuickSine, "GRQUICKSINE");
pragma Alias(GrQuickCosine, "GRQUICKCOSINE");
pragma Alias(GrQuickTangent, "GRQUICKTANGENT");
pragma Alias(GrQuickArcSine, "GRQUICKARCSINE");
pragma Alias(GrCreateState, "GRCREATESTATE");
pragma Alias(GrDestroyState, "GRDESTROYSTATE");
pragma Alias(GrSetVMFile, "GRSETVMFILE");
pragma Alias(GrGetExclusive, "GRGETEXCLUSIVE");
pragma Alias(GrGrabExclusive, "GRGRABEXCLUSIVE");
pragma Alias(GrReleaseExclusive, "GRRELEASEEXCLUSIVE");
pragma Alias(GrTransformWWFixed, "GRTRANSFORMWWFIXED");
pragma Alias(GrTransformDWFixed, "GRTRANSFORMDWFIXED");
pragma Alias(GrUntransformWWFixed, "GRUNTRANSFORMWWFIXED");
pragma Alias(GrUntransformDWFixed, "GRUNTRANSFORMDWFIXED");
pragma Alias(GrBitBlt, "GRBITBLT");
pragma Alias(GrTransform, "GRTRANSFORM");
pragma Alias(GrTransformDWord, "GRTRANSFORMDWORD");
pragma Alias(GrUntransform, "GRUNTRANSFORM");
pragma Alias(GrUntransformDWord, "GRUNTRANSFORMDWORD");
pragma Alias(GrMapColorIndex, "GRMAPCOLORINDEX");
pragma Alias(GrMapColorRGB, "GRMAPCOLORRGB");
pragma Alias(GrGetPalette, "GRGETPALETTE");
pragma Alias(GrSetPrivateData, "GRSETPRIVATEDATA");
pragma Alias(GrGetMixMode, "GRGETMIXMODE");
pragma Alias(GrGetLineColor, "GRGETLINECOLOR");
pragma Alias(GrGetAreaColor, "GRGETAREACOLOR");
pragma Alias(GrGetTextColor, "GRGETTEXTCOLOR");
pragma Alias(GrGetLineMask, "GRGETLINEMASK");
pragma Alias(GrGetAreaMask, "GRGETAREAMASK");
pragma Alias(GrGetTextMask, "GRGETTEXTMASK");
pragma Alias(GrGetLineColorMap, "GRGETLINECOLORMAP");
pragma Alias(GrGetAreaColorMap, "GRGETAREACOLORMAP");
pragma Alias(GrGetTextColorMap, "GRGETTEXTCOLORMAP");
pragma Alias(GrGetTextSpacePad, "GRGETTEXTSPACEPAD");
pragma Alias(GrGetTextStyle, "GRGETTEXTSTYLE");
pragma Alias(GrGetTextDrawOffset, "GRGETTEXTDRAWOFFSET");
pragma Alias(GrGetTextMode, "GRGETTEXTMODE");
pragma Alias(GrGetLineWidth, "GRGETLINEWIDTH");
pragma Alias(GrGetLineEnd, "GRGETLINEEND");
pragma Alias(GrGetLineJoin, "GRGETLINEJOIN");
pragma Alias(GrGetLineStyle, "GRGETLINESTYLE");
pragma Alias(GrGetMiterLimit, "GRGETMITERLIMIT");
pragma Alias(GrGetCurPos, "GRGETCURPOS");
pragma Alias(GrGetCurPosWWFixed, "GRGETCURPOSWWFIXED");
pragma Alias(GrGetInfo, "GRGETINFO");
pragma Alias(GrGetTransform, "GRGETTRANSFORM");
pragma Alias(GrGetFont, "GRGETFONT");
pragma Alias(GrTestPointInPolygon, "GRTESTPOINTINPOLYGON");
pragma Alias(GrEndGString, "GRENDGSTRING");
pragma Alias(GrComment, "GRCOMMENT");
pragma Alias(GrNullOp, "GRNULLOP");
pragma Alias(GrEscape, "GRESCAPE");
pragma Alias(GrSaveState, "GRSAVESTATE");
pragma Alias(GrRestoreState, "GRRESTORESTATE");
pragma Alias(GrNewPage, "GRNEWPAGE");
pragma Alias(GrApplyRotation, "GRAPPLYROTATION");
pragma Alias(GrApplyScale, "GRAPPLYSCALE");
pragma Alias(GrApplyTranslation, "GRAPPLYTRANSLATION");
pragma Alias(GrApplyTranslationDWord, "GRAPPLYTRANSLATIONDWORD");
pragma Alias(GrSetTransform, "GRSETTRANSFORM");
pragma Alias(GrApplyTransform, "GRAPPLYTRANSFORM");
pragma Alias(GrSaveTransform, "GRSAVETRANSFORM");
pragma Alias(GrRestoreTransform, "GRRESTORETRANSFORM");
pragma Alias(GrSetNullTransform, "GRSETNULLTRANSFORM");
pragma Alias(GrDrawLine, "GRDRAWLINE");
pragma Alias(GrDrawLineTo, "GRDRAWLINETO");
pragma Alias(GrDrawRelLineTo, "GRDRAWRELLINETO");
pragma Alias(GrDrawRect, "GRDRAWRECT");
pragma Alias(GrDrawRectTo, "GRDRAWRECTTO");
pragma Alias(GrDrawHLine, "GRDRAWHLINE");
pragma Alias(GrDrawHLineTo, "GRDRAWHLINETO");
pragma Alias(GrDrawVLine, "GRDRAWVLINE");
pragma Alias(GrDrawVLineTo, "GRDRAWVLINETO");
pragma Alias(GrDrawRoundRect, "GRDRAWROUNDRECT");
pragma Alias(GrDrawRoundRectTo, "GRDRAWROUNDRECTTO");
pragma Alias(GrDrawPoint, "GRDRAWPOINT");
pragma Alias(GrDrawPointAtCP, "GRDRAWPOINTATCP");
pragma Alias(GrDrawBitmap, "GRDRAWBITMAP");
pragma Alias(GrDrawBitmapAtCP, "GRDRAWBITMAPATCP");
pragma Alias(GrDrawChar, "GRDRAWCHAR");
pragma Alias(GrDrawCharAtCP, "GRDRAWCHARATCP");
pragma Alias(GrDrawText, "GRDRAWTEXT");
pragma Alias(GrDrawTextAtCP, "GRDRAWTEXTATCP");
pragma Alias(GrDrawPolyline, "GRDRAWPOLYLINE");
pragma Alias(GrDrawEllipse, "GRDRAWELLIPSE");
pragma Alias(GrDrawArc, "GRDRAWARC");
pragma Alias(GrDrawArc3Point, "GRDRAWARC3POINT");
pragma Alias(GrDrawArc3PointTo, "GRDRAWARC3POINTTO");
pragma Alias(GrDrawRelArc3PointTo, "GRDRAWRELARC3POINTTO");
pragma Alias(GrDrawSpline, "GRDRAWSPLINE");
pragma Alias(GrDrawSplineTo, "GRDRAWSPLINETO");
pragma Alias(GrDrawCurve, "GRDRAWCURVE");
pragma Alias(GrDrawCurveTo, "GRDRAWCURVETO");
pragma Alias(GrDrawPolygon, "GRDRAWPOLYGON");
pragma Alias(GrFillRect, "GRFILLRECT");
pragma Alias(GrFillRectTo, "GRFILLRECTTO");
pragma Alias(GrFillRoundRect, "GRFILLROUNDRECT");
pragma Alias(GrFillRoundRectTo, "GRFILLROUNDRECTTO");
pragma Alias(GrFillArc, "GRFILLARC");
pragma Alias(GrFillArc3Point, "GRFILLARC3POINT");
pragma Alias(GrFillArc3PointTo, "GRFILLARC3POINTTO");
pragma Alias(GrFillPolygon, "GRFILLPOLYGON");
pragma Alias(GrFillEllipse, "GRFILLELLIPSE");
pragma Alias(GrSetMixMode, "GRSETMIXMODE");
pragma Alias(GrRelMoveTo, "GRRELMOVETO");
pragma Alias(GrMoveTo, "GRMOVETO");
pragma Alias(GrSetLineColor, "GRSETLINECOLOR");
pragma Alias(GrSetLineMaskSys, "GRSETLINEMASKSYS");
pragma Alias(GrSetLineMaskCustom, "GRSETLINEMASKCUSTOM");
pragma Alias(GrSetLineColorMap, "GRSETLINECOLORMAP");
pragma Alias(GrSetLineWidth, "GRSETLINEWIDTH");
pragma Alias(GrSetLineJoin, "GRSETLINEJOIN");
pragma Alias(GrSetLineEnd, "GRSETLINEEND");
pragma Alias(GrSetLineAttr, "GRSETLINEATTR");
pragma Alias(GrSetMiterLimit, "GRSETMITERLIMIT");
pragma Alias(GrSetLineStyle, "GRSETLINESTYLE");
pragma Alias(GrSetAreaColor, "GRSETAREACOLOR");
pragma Alias(GrSetAreaMaskSys, "GRSETAREAMASKSYS");
pragma Alias(GrSetAreaMaskCustom, "GRSETAREAMASKCUSTOM");
pragma Alias(GrSetAreaColorMap, "GRSETAREACOLORMAP");
pragma Alias(GrSetAreaAttr, "GRSETAREAATTR");
pragma Alias(GrSetTextColor, "GRSETTEXTCOLOR");
pragma Alias(GrSetTextMaskSys, "GRSETTEXTMASKSYS");
pragma Alias(GrSetTextMaskCustom, "GRSETTEXTMASKCUSTOM");
pragma Alias(GrSetTextColorMap, "GRSETTEXTCOLORMAP");
pragma Alias(GrSetTextStyle, "GRSETTEXTSTYLE");
pragma Alias(GrSetTextMode, "GRSETTEXTMODE");
pragma Alias(GrSetTextDrawOffset, "GRSETTEXTDRAWOFFSET");
pragma Alias(GrSetTextSpacePad, "GRSETTEXTSPACEPAD");
pragma Alias(GrSetTextAttr, "GRSETTEXTATTR");
pragma Alias(GrSetFont, "GRSETFONT");
pragma Alias(GrSetGStringBounds, "GRSETGSTRINGBOUNDS");
pragma Alias(GrCreatePalette, "GRCREATEPALETTE");
pragma Alias(GrDestroyPalette, "GRDESTROYPALETTE");
pragma Alias(GrSetPaletteEntry, "GRSETPALETTEENTRY");
pragma Alias(GrSetPalette, "GRSETPALETTE");
pragma Alias(GrSetTrackKern, "GRSETTRACKKERN");
pragma Alias(GrInitDefaultTransform, "GRINITDEFAULTTRANSFORM");
pragma Alias(GrSetDefaultTransform, "GRSETDEFAULTTRANSFORM");
pragma Alias(GrSetClipRect, "GRSETCLIPRECT");
pragma Alias(GrSetWinClipRect, "GRSETWINCLIPRECT");
pragma Alias(GrBeginPath, "GRBEGINPATH");
pragma Alias(GrEndPath, "GRENDPATH");
pragma Alias(GrCloseSubPath, "GRCLOSESUBPATH");
pragma Alias(GrSetClipPath, "GRSETCLIPPATH");
pragma Alias(GrSetWinClipPath, "GRSETWINCLIPPATH");
pragma Alias(GrFillPath, "GRFILLPATH");
pragma Alias(GrDrawPath, "GRDRAWPATH");
pragma Alias(GrSetStrokePath, "GRSETSTROKEPATH");
pragma Alias(GrTestPointInPath, "GRTESTPOINTINPATH");
pragma Alias(GrGetPath, "GRGETPATH");
pragma Alias(GrTestPath, "GRTESTPATH");
pragma Alias(GrGetPathBounds, "GRGETPATHBOUNDS");
pragma Alias(GrGetPathBoundsDWord, "GRGETPATHBOUNDSDWORD");
pragma Alias(GrGetPathPoints, "GRGETPATHPOINTS");
pragma Alias(GrGetPathRegion, "GRGETPATHREGION");
pragma Alias(GrGetClipRegion, "GRGETCLIPREGION");
pragma Alias(GrInvalRect, "GRINVALRECT");
pragma Alias(GrInvalRectDWord, "GRINVALRECTDWORD");
pragma Alias(GrGetWinBoundsDWord, "GRGETWINBOUNDSDWORD");
pragma Alias(GrGetMaskBoundsDWord, "GRGETMASKBOUNDSDWORD");
pragma Alias(GrGetWinBounds, "GRGETWINBOUNDS");
pragma Alias(GrGetMaskBounds, "GRGETMASKBOUNDS");
pragma Alias(GrGetWinHandle, "GRGETWINHANDLE");
pragma Alias(GrBrushPolyline, "GRBRUSHPOLYLINE");
pragma Alias(GrFillBitmap, "GRFILLBITMAP");
pragma Alias(GrFillBitmapAtCP, "GRFILLBITMAPATCP");
pragma Alias(GrGetTrackKern, "GRGETTRACKKERN");
pragma Alias(GrSetAreaPattern, "GRSETAREAPATTERN");
pragma Alias(GrSetCustomAreaPattern, "GRSETCUSTOMAREAPATTERN");
pragma Alias(GrSetTextPattern, "GRSETTEXTPATTERN");
pragma Alias(GrSetCustomTextPattern, "GRSETCUSTOMTEXTPATTERN");
pragma Alias(GrGetAreaPattern, "GRGETAREAPATTERN");
pragma Alias(GrGetTextPattern, "GRGETTEXTPATTERN");
pragma Alias(GrGetTextBounds, "GRGETTEXTBOUNDS");
pragma Alias(GrDrawHugeBitmap, "GRDRAWHUGEBITMAP");
pragma Alias(GrDrawHugeBitmapAtCP, "GRDRAWHUGEBITMAPATCP");
pragma Alias(GrFillHugeBitmap, "GRFILLHUGEBITMAP");
pragma Alias(GrFillHugeBitmapAtCP, "GRFILLHUGEBITMAPATCP");
pragma Alias(GrDrawImage, "GRDRAWIMAGE");
pragma Alias(GrDrawHugeImage, "GRDRAWHUGEIMAGE");
pragma Alias(GrMoveToWWFixed, "GRMOVETOWWFIXED");
pragma Alias(GrGetGStringHandle, "GRGETGSTRINGHANDLE");

#endif

#endif
