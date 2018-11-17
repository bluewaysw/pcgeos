/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	Text/tCommon.h
 * AUTHOR:	Tony Requist: February 12, 1991
 *
 * DECLARER:	UI / Text library
 *
 * DESCRIPTION:
 *	This file defines VisTextClass
 *
 *	$Id: tCommon.h,v 1.1 97/04/04 15:50:32 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__TCOMMON_H
#define __TCOMMON_H

#include <stylesh.h>
#include <sllang.h>

/*---------------------------------------------------------------------------
 * 	Text Ranges
 *--------------------------------------------------------------------------*/

/*
 * The VisTextRange structure is passed to many routines to indicate the
 * range of text to act on.
 */
typedef struct {
    dword   VTR_start;
    dword   VTR_end;
} VisTextRange;

/*
 * This constant can be placed in either VTR_start or VTR_end
 */
#define TEXT_ADDRESS_PAST_END		0x00ffffffL
#define TEXT_ADDRESS_PAST_END_HIGH	0x00ff
#define TEXT_ADDRESS_PAST_END_LOW	0xffff
	/* Special value for VTR_start.high */

#define	VIS_TEXT_RANGE_SELECTION_HIGH	0xffff
#define	VIS_TEXT_RANGE_SELECTION_LOW	0x0000
#define	VIS_TEXT_RANGE_SELECTION	0xffff0000L
/* Description:
 *	Indicates that the current selected area will be used.  Note that
 *	for some operations (like paraAttr changes), the affected text will
 *	actually be larger than the selection.
 */

#define VIS_TEXT_RANGE_PARAGRAPH_SELECTION	0xfffe0000L
#define VIS_TEXT_RANGE_PARAGRAPH_SELECTION_HIGH	0xfffe
#define VIS_TEXT_RANGE_PARAGRAPH_SELECTION_LOW  0x0000
/* Description:
 *	Indicates that the current selected area will be used after being
 *	adjusted to a paragraph boundry.
 */


/*---------------------------------------------------------------------------
 * 	Tabs, Fields and Lines
 *--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------
 *  An array of line structures is kept (one for every line of text).
 *  For updates we need to know if a line has changed (so we can redraw it).
 *  For calculations we need to know if a line is the start of a paragraph (so
 *  we can apply the paragraph margin).
 *--------------------------------------------------------------------------*/

typedef WordFlags LineFlags;

/*  Set if line starts a paragraph */
#define LF_STARTS_PARAGRAPH	(0x8000)

/*  Set if line ends a paragraph */
#define LF_ENDS_PARAGRAPH	(0x4000)
    
/*  Set if field ends in CR. */
#define LF_ENDS_IN_CR	(0x2000)

/*  Set if line ends in a column break */
#define LF_ENDS_IN_COLUMN_BREAK	(0x1000)

/*  Set if line ends in a section break */
#define LF_ENDS_IN_SECTION_BREAK	(0x0800)

/*  Set if line ends in NULL, last one in document */
#define LF_ENDS_IN_NULL	(0x0400)
    
/*  Set if line needs redrawing */
#define LF_NEEDS_DRAW	(0x0200)

/*  Set if line needs calculating */
#define LF_NEEDS_CALC	(0x0100)
    
/*  Set if line ends in a generated hyphen */
#define LF_ENDS_IN_AUTO_HYPHEN	(0x0080)

/*  Set if line ends in an optional hyphen */
#define LF_ENDS_IN_OPTIONAL_HYPHEN	(0x0040)
    
/*
 *  Sometimes characters in a line will extend outside the top and bottom
 *  bounds of the line. We mark these lines with these bits. 
 */
/*  Set if line interacts with line above it */
#define LF_INTERACTS_ABOVE	(0x0020)

/*  Set if line interacts with line below it */
#define LF_INTERACTS_BELOW	(0x0010)

/*
 *  When doing an optimized redraw of a line we draw the last field in the
 *  line if the field got longer. If the field got shorter we just clear
 *  from beyond the right edge of the field. There are a few situations
 *  where we can't really do this:
 * 	- Current last character on line extended to the right of its font
 * 	  box. (Italic characters are a good example of this).
 * 	- The last character on the line was negatively kerned before we
 * 	  made the modification and is that is no longer the case (this
 * 	  character was removed).
 *  We flag these two cases separately.
 */

/*
 *  Set if the last character on the line extends
 *   to the right of its font box.
 */
#define LF_LAST_CHAR_EXTENDS_RIGHT	(0x0008)
    
/*
 *  Set if the last character on the line is 
 *  kerned. The only time we use this is to copy
 *  it into the next field...
 */
#define LF_LAST_CHAR_KERNED	(0x0004)
    
/*
 *  Set if the line contains styles which are not supported by the kernel.
 *  This allows applications to optimize line redraw by skipping over code
 *  which may attempt to draw attributes which don't exist for the line.
 */
#define LF_CONTAINS_EXTENDED_STYLE	(0x0002)
    
/*
 * 	Structure of a tab
 */
typedef ByteEnum TabLeader;
#define TL_NONE	    0x0
#define TL_DOT	    0x1
#define TL_LINE	    0x2
#define TL_BULLET   0x3

typedef ByteEnum TabType;	
#define TT_LEFT	    	0x0
#define TT_CENTER	0x1
#define TT_RIGHT	0x2
#define TT_ANCHORED	0x3

typedef ByteFlags TabAttributes;	
/* 3 bits unused */
#define TabLeader	(0x10 | 0x08 | 0x04)
#define TabLeader_OFFSET	2
#define TabType	    	(0x02 | 0x01)
#define TabType_OFFSET	    	0

typedef ByteEnum TabReferenceType;	
#define TRT_RULER	0x0 	    /*  Reference is into the ruler. */
#define TRT_OTHER	0x1

typedef ByteFlags TabReference;
#define TabReferenceType    0x80    /*  Type of reference. */

/*  Reference number */
#define TR_REF_NUMBER	(0x40 | 0x20 | 0x10 | 0x08 | 0x04 | 0x02 | 0x01)
#define TR_REF_NUMBER_OFFSET	0

/*
 *  Reference number that means no tab, use left edge of line.
 *  MUST BE 0x7f (-1 in 7 binary digits).
 */
#define	RULER_TAB_TO_LINE_LEFT	    	0x7f

/*
 *  Reference number that means use the left margin value.
 */
#define RULER_TAB_TO_LEFT_MARGIN	0x7e

/*
 *  Reference number that means use the para margin value.
 */
#define RULER_TAB_TO_PARA_MARGIN	0x7d

/*
 *  Reference number that means tab has an intrinsic width and 
 *  is not associated with any tabstop.
 */
#define OTHER_INTRINSIC_TAB		0x7f

/*
 *  Reference number that means that the tab is zero width. This is a special
 *  case that is reserved for really horrible situations.
 */
#define OTHER_ZERO_WIDTH_TAB		0x7e

typedef struct {
    word	    T_position;     	/*  Position of tab (pixels * 8) */
    TabAttributes   T_attr;	        /*  Tab attributes. */
    SysDrawMask	    T_grayScreen; 	/*  Gray screen for tab lines */
    byte	    T_lineWidth;    	/*  Width of line before (after) tab
					 *  0 = none, units are pixels * 8  */
    byte	    T_lineSpacing;  	/*  Space between tab and line
					 *  0 = none, units are pixels * 8  */
    word	    T_anchor; 	    	/*  Anchor character. */
} Tab;

#define TAB_POS_TYPE_LEADER_ANCHOR_GRAY_WIDTH_SPACING(pos, type, leander, anchor, gray, width, spacing) { \
    {(pos)*PIXELS_PER_INCH, {leader, type}, gray, width, spacing, anchor}

#define TAB_POS_TYPE(pos, type)  \
    TAB_POS_TYPE_LEADER_ANCHOR_GRAY_WIDTH_SPACING(pos, type, TL_NONE, '.', SDM_100, 0, 0)


/*
 *  A line is made up of a list of fields...
 */
typedef struct {	
    word	FI_nChars;  	/*  Number of characters in the field */
    word	FI_position; 	/*  X position of field on line */
    word	FI_width;   	/*  Width of the field */
    TabReference FI_tab;    	/*  Reference to a tab in the ruler */
} FieldInfo;

/*
 *  A line...
 */
typedef	struct {
    LineFlags 	LI_flags;
    WBFixed 	LI_hgt;			/* Height of line */
    WBFixed 	LI_blo;			/* Baseline offset */
    word    	LI_adjustment;	   	/* Adjustment for justification */
    WordAndAHalf LI_count;	    	/* Number of characters in the line.
					 * This is the total of the field
					 * counts.
					 */
    WBFixed 	LI_spacePad;		/* Amount to pad last field to 
					 * get full justification 
					 */
    word    	LI_lineEnd; 	    	/* The rounded end-of-line position
					 * which indicates the end of the
					 * last non-white-space character.
					 */
    FieldInfo	LI_firstField;	        /* Contains the always present 
					 * first field .
					 */

} LineInfo;


/*--------------------------------------------------------------------------
 *		CharAttrs
 *-------------------------------------------------------------------------*/

typedef WordFlags VisTextExtendedStyles;
#define VTES_BOXED  		0x8000
#define VTES_BUTTON  		0x4000
#define VTES_INDEX  		0x2000
#define VTES_ALL_CAP  		0x1000
#define VTES_SMALL_CAP 		0x0800
#define VTES_HIDDEN 		0x0400
#define VTES_CHANGE_BAR		0x0200
#define VTES_BACKGROUND_COLOR	0x0100
#define VTES_NOWRAP             0x0080  /* Can't break by word or char */

/*
 * 	Definition of a text CharAttr element
 */
typedef struct {
    StyleSheetElementHeader VTCA_meta;
    FontID	    	    VTCA_fontID;
    WBFixed	    	    VTCA_pointSize;
    TextStyle 	    	    VTCA_textStyles;
    ColorQuad     	    VTCA_color;
    sword	     	    VTCA_trackKerning;
    byte	    	    VTCA_fontWeight;
    byte	    	    VTCA_fontWidth;
    VisTextExtendedStyles   VTCA_extendedStyles;
    SystemDrawMask	    VTCA_grayScreen;
    GraphicPattern    	    VTCA_pattern;
    ColorQuad	    	    VTCA_bgColor;
    SystemDrawMask	    VTCA_bgGrayScreen;
    GraphicPattern    	    VTCA_bgPattern;
    byte	    	    VTCA_reserved[7];
} VisTextCharAttr;

typedef ByteEnum VisTextDefaultSize;
#define     VTDS_8  0
#define     VTDS_9  1
#define     VTDS_10 2
#define     VTDS_12 3
#if DBCS_GEOS
#define     VTDS_16 4
#else
#define     VTDS_14 4
#endif
#define     VTDS_18 5
#define     VTDS_24 6
#define     VTDS_36 7

/*
 *	Default CharAttr record (incorporates the default sizes 
 *	and color map modes).
 */

/*
 *	There are are maximum of 32 default fonts (since the bitfield is
 *	five bits wide).  Do not add fonts without consulting font people!
 */
typedef ByteEnum VisTextDefaultFont;
#define     VTDF_BERKELEY   	    0
#define     VTDF_CHICAGO    	    1
#define     VTDF_BISON 	    	    2
#define     VTDF_WINDOWS    	    3
#define     VTDF_LED 	    	    4
#define     VTDF_ROMA 	    	    5
#define     VTDF_UNIVERSITY 	    6
#define     VTDF_URW_ROMAN  	    7
#define     VTDF_URW_SANS   	    8
#define     VTDF_URW_MONO   	    9
#define     VTDF_URW_SYMBOLS 	    10
#define     VTDF_CENTURY_SCHOOLBOOK 11
#define     VTDF_JSYS               12
#define     VTDF_ESQUIRE            13

typedef WordFlags VisTextDefaultCharAttr;
#define VTDCA_UNDERLINE	0x8000
#define VTDCA_BOLD	0x4000
#define VTDCA_ITALIC	0x2000
#define VTDCA_COLOR	0x0f00	/* ColorQuad */
#define VTDCA_SIZE	0x00e0	/* VisTextDefaultSize */
#define VTDCA_FONT	0x001f	/* VisTextDefaultFont */

#define VTDCA_COLOR_OFFSET	8
#define VTDCA_SIZE_OFFSET	5
#define VTDCA_FONT_OFFSET	0

/*
 *	The initial CharAttr for a text object 
 */
#define VIS_TEXT_INITIAL_CHAR_ATTR \
 	    	((VTDS_12 << VTDCA_SIZE_OFFSET) | VTDF_BERKELEY)

#define VIS_TEXT_DEFAULT_POINT_SIZE 12


/*--------------------------------------------------------------------------- 
 *	Macros for defining VisTextCharAttr structures 
 */

#define CHAR_ATTR_STYLE_FONT_SIZE_STYLE_COLOR(ref, style, font, psize, tstyle, color) { \
    {{{ref, 0}}, style}, font, {0, psize}, tstyle, \
	{color, CF_INDEX, 0, 0}, 0, FWI_MEDIUM, FW_NORMAL, 0, SDM_100, {0}, \
	{C_WHITE, CF_INDEX, 0, 0}, SDM_0, {0}, {0,0,0,0,0,0,0}}
#if 0
     {{{ref, 0}}, style}, \      	/* StyleSheetElementHeader  	  */
 	font, \	    	    	    	/* FontID   	    	    	  */
	{0, psize}, \	    	    	/* point size - WBFixed     	  */
	tstyle, \   	    	    	/* TextStyle 	    	    	  */
	{color, CF_INDEX, 0, 0},    	/* text ColorQuad   	    	  */
	0, \	    	    	    	/* Track kerning    	    	  */
	FWI_MEDIUM, FW_NORMAL, \    	/* Font weight, font width  	  */
	0, \	    	    	    	/* VisTextExtendedStyles    	  */
	SDM_100, {0}, \  	    	/* SystemDrawMask, GraphicPattern */
	{C_WHITE, CF_INDEX, 0, 0}, \  	/* background ColorQuad     	  */
	SDM_0, \ 	    	    	/* background SystemDrawMask 	  */
	{0}, \	    	    	    	/* background GraphicPattern 	  */
	{0,0,0,0,0,0,0}}    	    	/* reserved 	    	    	  */
#endif

#define CHAR_ATTR_FONT_SIZE_STYLE(font, psize, tstyle) \
	    CHAR_ATTR_STYLE_FONT_SIZE_STYLE_COLOR(2, CA_NULL_ELEMENT, font, \
						psize, tstyle, C_BLACK)

#define CHAR_ATTR_FONT_SIZE(font, psize) \
	    CHAR_ATTR_STYLE_FONT_SIZE_STYLE_COLOR(2, CA_NULL_ELEMENT, font, \
						psize, 0, C_BLACK)

/* 
 *	Macros for typical default attribute structures 
 */

#define DEF_CHAR_ATTR_FONT_SIZE(font, psize) (((psize) << VTDCA_SIZE_OFFSET) | \
					      ((font) << VTDCA_FONT_OFFSET))

/*--------------------------------------------------------------------------
 *		ParaAttrs
 *-------------------------------------------------------------------------*/

/*
 *	Limits for various ParaAttr components
 */
#ifdef DO_PIZZA
#define VIS_TEXT_MAX_PARA_WIDTH	    	    	3926	/* 138.5 cm */
#else
#define VIS_TEXT_MAX_PARA_WIDTH			4000
#endif

#define VIS_TEXT_MIN_NON_ZERO_LINE_SPACING 	((0 << 8) + 128)	
	/* BBFixed constant */

#define VIS_TEXT_MIN_NON_ZERO_LINE_SPACING_INT 	0
#define VIS_TEXT_MIN_NON_ZERO_LINE_SPACING_FRAC 32768
	/* WWFixed constants */

#define VIS_TEXT_MAX_LINE_SPACING	(12 << 8)
	/* BBFixed constant */

#define VIS_TEXT_MAX_LINE_SPACING_INT	12
#define VIS_TEXT_MAX_LINE_SPACING_FRAC	0
	/* WWFixed constants */

#define VIS_TEXT_MIN_TEXT_FIELD_WIDTH	47
#define VIS_TEXT_MIN_NON_ZERO_LEADING	1
#define VIS_TEXT_MAX_LEADING		MAX_POINT_SIZE
#define VIS_TEXT_MAX_TABS		25

#define TEXT_ONE_LINE_RIGHT_MARGIN 	VIS_TEXT_MAX_PARA_WIDTH
	/* Right margin used by right justified single line objects */


/*
 *	Structure of a paraAttr				
 *
 * The size of a paraAttr can be computed by:
 *
 *	size = (size VisTextParaAttr) + (VTPA_numberOfTabs * (size Tab))
 */

/* 
 *	Different types of borders on a paragraph
 */
typedef ByteEnum ShadowAnchor;
#define     SA_TOP_LEFT 	0
#define     SA_TOP_RIGHT 	1
#define     SA_BOTTOM_LEFT 	2
#define     SA_BOTTOM_RIGHT 	3

typedef WordFlags VisTextParaBorderFlags;
#define VTPBF_LEFT		0x8000	/* set if border on the left */
#define VTPBF_TOP		0x4000	/* set if border on the top */
#define VTPBF_RIGHT		0x2000	/* set if border on the right */
#define VTPBF_BOTTOM		0x1000	/* set if border on the bottom */
#define VTPBF_DOUBLE		0x0800	/* draw two line border */
#define VTPBF_DRAW_INNER_LINES	0x0400	/* draw lines between bordered para. */
#define VTPBF_SHADOW 	    	0x0200	/* set to use shadow */
#define VTPBF_ANCHOR		0x0003	/* ShadowAnchor */

#define VTPBF_ANCHOR_OFFSET	0

typedef ByteEnum VisTextNumberType;
#define     VTNT_NUMBER    	    	0
#define     VTNT_LETTER_UPPER_A    	1
#define     VTNT_LETTER_LOWER_A    	2
#define     VTNT_ROMAN_NUMERAL_UPPER 	3
#define     VTNT_ROMAN_NUMERAL_LOWER 	4

typedef WordFlags VisTextParaAttrAttributes;
#define VTPAA_JUSTIFICATION 	    	0xc000
#define VTPAA_KEEP_PARA_WITH_NEXT	0x2000
#define VTPAA_KEEP_PARA_TOGETHER	0x1000	/* don't break up paragraph */
#define VTPAA_ALLOW_AUTO_HYPHENATION	0x0800  /* use VisTextHyphenationInfo*/
#define VTPAA_DISABLE_WORD_WRAP	    	0x0400
#define VTPAA_COLUMN_BREAK_BEFORE    	0x0200
#define VTPAA_PARA_NUMBER_TYPE	    	0x01c0
#define VTPAA_DROP_CAP	    	    	0x0020  /* use VisTextDropCapInfo */
#define VTPAA_KEEP_LINES    	    	0x0010  /* use VisTextKeepInfo */

#define VTPAA_JUSTIFICATION_OFFSET 	14
#define VTPAA_PARA_NUMBER_TYPE_OFFSET  	5

typedef WordFlags VisTextHyphenationInfo;
#define VTHI_HYPHEN_MAX_LINES	    	0xf000
#define VTHI_HYPHEN_SHORTEST_WORD   	0x0f00
#define VTHI_HYPHEN_SHORTEST_PREFIX 	0x00f0
#define VTHI_HYPHEN_SHORTEST_SUFFIX 	0x000f

#define VTHI_HYPHEN_MAX_LINES_OFFSET	    	12
#define VTHI_HYPHEN_SHORTEST_WORD_OFFSET   	8
#define VTHI_HYPHEN_SHORTEST_PREFIX_OFFSET 	4
#define VTHI_HYPHEN_SHORTEST_SUFFIX_OFFSET 	0

#define VIS_TEXT_DEFAULT_HYPHENATION (2 << VTHI_HYPHEN_MAX_LINES_OFFSET)|\
				     (4 << VTHI_HYPHEN_SHORTEST_WORD_OFFSET)|\
				     (2 << VTHI_HYPHEN_SHORTEST_PREFIX_OFFSET)|\
				     (2 << VTHI_HYPHEN_SHORTEST_SUFFIX_OFFSET)

typedef ByteFlags VisTextKeepInfo;
#define VTKI_TOP_LINES	    0xf0  /* # lines at start of PP to keep together */
#define VTKI_BOTTOM_LINES   0x0f  /* # lines at end of PP to keep together */

#define VTKI_TOP_LINES_OFFSET	    4
#define VTKI_BOTTOM_LINES_OFFSET    0

typedef WordFlags VisTextDropCapInfo;
#define VTDCI_CHAR_COUNT    0xf000	/* # chars for drop cap CharAttr */
#define VTDCI_LINE_COUNT    0x0f00	/* # lines for drop cap */
#define VTDCI_POSITION	    0x00f0	/* 0 is full drop cap
				  	 * lineCount - 1 is full tall cap */

#define VTDCI_CHAR_COUNT_OFFSET	    12
#define VTDCI_LINE_COUNT_OFFSET	    8
#define	VTDCI_POSITION_OFFSET	    4

#define VIS_TEXT_DEFAULT_DROP_CAP (0 << VTDCI_CHAR_COUNT_OFFSET)|\
				  (2 << VTDCI_LINE_COUNT_OFFSET)|\
				  (0 << VTDCI_POSITION_OFFSET)


#define VIS_TEXT_MIN_STARTING_NUMBER		-1000
#define VIS_TEXT_MAX_STARTING_NUMBER		60000
#define VIS_TEXT_DEFAULT_STARTING_NUMBER	62000

/*
 *	Default ParaAttrs
 */

#define PIXELS_PER_INCH		72

/*
 * Intrinsic width for a tab character if there are no tabstops which apply
 * to it.
 */
#define TAB_INTRINSIC_WIDTH 	18		/* 1/4 inch */

typedef ByteEnum VisTextDefaultDefaultTab;
#define     VTDDT_NONE 		0
#define     VTDDT_HALF_INCH 	1
#define     VTDDT_INCH 		2
#define     VTDDT_CENTIMETER 	3

typedef WordFlags VisTextDefaultParaAttr;
#define VTDPA_JUSTIFICATION	0xc000	/* Justification */
#define VTDPA_DEFAULT_TABS	0x3000	/* VisTextDefaultDefaultTab */
#define VTDPA_LEFT_MARGIN	0x0f00	/* in units of half inches */
#define VTDPA_PARA_MARGIN	0x00f0	/* in units of half inches */
#define VTDPA_RIGHT_MARGIN	0x000f	/* in units of half inches -- 0 means
					 * VIS_TEXT_MAX_PARA_ATTR_SIZE */

#define VTDPA_JUSTIFICATION_OFFSET	14
#define VTDPA_DEFAULT_TABS_OFFSET	12
#define VTDPA_LEFT_MARGIN_OFFSET	8
#define VTDPA_PARA_MARGIN_OFFSET	4
#define VTDPA_RIGHT_MARGIN_OFFSET	0


/* 
 *	Structure of a ParaAttr
 */
typedef struct {
    StyleSheetElementHeader VTPA_meta;
    VisTextParaBorderFlags  VTPA_borderFlags;	/* border type */
    ColorQuad    	    VTPA_borderColor;	/* color for border */
    VisTextParaAttrAttributes VTPA_attributes;
    word	    	    VTPA_leftMargin;	/* margins - unsigned */
    word	    	    VTPA_rightMargin;	/* right margin is an offset
						 * from the RIGHT edge of the
						 * object */
    word	    	    VTPA_paraMargin;
						/* ** See note on line height
						 * ** calculation below */
    BBFixedAsWord    	    VTPA_lineSpacing;	/* line spacing - unsigned 
						 * 1.0 is normal  */

	/* extra space above/below paragraph, in points (13.3) */

    word	    	    VTPA_leading;	/* unsigned, 13.3	*/
    BBFixedAsWord    	    VTPA_spaceOnTop;	/* unsigned, 0.0 is normal */
    BBFixedAsWord	    VTPA_spaceOnBottom; /* spacing */

    ColorQuad	    	    VTPA_bgColor;
    byte	    	    VTPA_numberOfTabs;	/* # of tabs in ParaAttr */

    byte	    	    VTPA_borderWidth;	/* (pixels * 8)	*/
    byte	    	    VTPA_borderSpacing;	/* (pixels * 8)	*/
    byte	    	    VTPA_borderShadow;	/* (pixels * 8)	*/
    SystemDrawMask	    VTPA_borderGrayScreen;
    SystemDrawMask	    VTPA_bgGrayScreen;
    GraphicPattern    	    VTPA_borderPattern;
    GraphicPattern    	    VTPA_bgPattern;
    word	    	    VTPA_defaultTabs;	/* spacing for default tabs */
    word	    	    VTPA_startingParaNumber;
    char	    	    VTPA_prependChars[4];	/* chars to prepend at
						* start of each paragraph */
    VisTextHyphenationInfo  VTPA_hyphenationInfo;
    VisTextKeepInfo   	    VTPA_keepInfo;
    VisTextDropCapInfo 	    VTPA_dropCapInfo;
    word		    VTPA_nextStyle;
    StandardLanguage	    VTPA_language;
#if DBCS_PCGEOS
    TextMiscModeFlags	    VTPA_miscMode;
    byte	    	    VTPA_reserved[14];
#else
    byte	    	    VTPA_reserved[15];
#endif
} VisTextParaAttr;

typedef struct {
    VisTextParaAttr	VTMPA_paraAttr;
    Tab	    	    	VTMPA_tabs[VIS_TEXT_MAX_TABS];
} VisTextMaxParaAttr;


/*
 *	The initial ParaAttr for a text object 
 */
#define VIS_TEXT_INITIAL_PARA_ATTR (VisTextDefaultParaAttr) ( (0*2) << VTDPA_LEFT_MARGIN_OFFSET ) | \
				( (0*2) << VTDPA_PARA_MARGIN_OFFSET ) | \
				( (0*2) << VTDPA_RIGHT_MARGIN_OFFSET ) | \
				( VTDDT_HALF_INCH << VTDPA_DEFAULT_TABS_OFFSET ) | \
				( J_LEFT << VTDPA_JUSTIFICATION_OFFSET )

/*---------------------------------------------------------------------------
 *	Macros for defining default ParaAttrs
 */
#define DEF_PARA_ATTR_JUST_TABS(just, tabs) \
				(( (0*2) << VTDPA_LEFT_MARGIN_OFFSET ) | \
				( (0*2) << VTDPA_PARA_MARGIN_OFFSET ) | \
				( (0*2) << VTDPA_RIGHT_MARGIN_OFFSET ) | \
				( (tabs) << VTDPA_DEFAULT_TABS_OFFSET ) | \
				( (just) << VTDPA_JUSTIFICATION_OFFSET ))

#define DEF_PARA_ATTR_CENTER \
    DEF_PARA_ATTR_JUST_TABS(J_CENTER, VTDDT_INCH)

#define DEF_PARA_ATTR_RIGHT \
    DEF_PARA_ATTR_JUST_TABS(J_RIGHT, VTDDT_INCH)


#define PARA_ATTR_STYLE_JUST_LEFT_RIGHT_PARA(ref, style, just, left, right, para) { \
        {{{ref, 0}}, style}, 0, {C_BLACK, CF_INDEX, 0, 0}, \
	just << VTPAA_JUSTIFICATION_OFFSET, (left)*PIXELS_PER_INCH, \
	 (right)*PIXELS_PER_INCH,  (para)*PIXELS_PER_INCH, \
	1<<8, 0, 0, 0, {C_WHITE, CF_INDEX, 0, 0}, \
	0, 1*8, 2*8, 1*8, SDM_100, SDM_0, {0}, {0}, \
	PIXELS_PER_INCH/2*8, VIS_TEXT_DEFAULT_STARTING_NUMBER, "", \
	0, 0, 0, CA_NULL_ELEMENT, SL_ENGLISH, {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}}

/*---------------------------------------------------------------------------
 *		 Attributes
 *--------------------------------------------------------------------------*/

/*
 * VisTextStorageFlags reflect the type of data structures used to store
 * the text object's data
 */
typedef ByteFlags VisTextStorageFlags;
#define VTSF_LARGE	    	    	0x80	
    /* If set: this object uses the large storage format and the bits below
     * 	       are unused.
     * If clear: this object uses the model storage format and the bits below
     *	    	  are unused.
     */

#define VTSF_MULTIPLE_CHAR_ATTRS	0x40
    /* If set: VTI_charAttrRuns = chunk handle of charAttr runs
     * If clear:  if (VTTF_defaultCharAttr)
     *	    	    	VTI_charAttrRuns is a VisTextDefaultCharAttr
     *	    	  else
     *	    	    	VTI_charAttrRuns = chunk handle of charAttr
     */

#define VTSF_MULTIPLE_PARA_ATTRS	0x20
    /* If set: VTI_paraAttrRuns = chunk handle of paraAttr runs
     * If clear:  if (VTI_paraAttrRuns != 0)
     *	    	    	VTI_paraAttrRuns = chunk handle of charAttr
     *	    	  else
     *	    	    	use default paraAttr
     */

#define VTSF_TYPES	    	    	0x10
#define VTSF_GRAPHICS	    	    	0x08
#define VTSF_DEFAULT_CHAR_ATTR	    	0x04
#define VTSF_DEFAULT_PARA_ATTR	    	0x02
#define VTSF_STYLES 		    	0x01

/*
 * We need an additional flag for passing to MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY.
 * Since VTSF_DEFAULT_CHAR_ATTR can't be passed to this routine, we use it
 * to represent VTSF_NAMES.
 */
#define	VTSF_NAMES  VTSF_DEFAULT_CHAR_ATTR

#endif

