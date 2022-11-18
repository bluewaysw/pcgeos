/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Icon creation
 * FILE:	  cvtpcx.c
 *
 * AUTHOR:  	  Adam de Boor: Jan  5, 1990
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	1/ 5/90	  ardeb	    Initial version
 *      1/6/92    josh      goc support
 *
 * DESCRIPTION:
 *	Hack to convert from a pcx icon to a .ui icon
 *
 * NOTES:
 *	This code no longer really supports negative Y offsets when not
 *	creating a moniker, but we don't do that around here, so to heck
 *	with it.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: cvtpcx.c,v 1.48 98/03/16 14:08:54 kho Exp $";
#endif lint

#include    <config.h>
#include    <stdio.h>
#include    <compat/file.h>
#include    <compat/string.h>
#include    <stdlib.h>		/* NOT compat/stdlib.h (no utils use here) */
#include    <ctype.h>
#include    <assert.h>
#include    <bswap.h>

typedef unsigned char byte;
typedef unsigned short word;

/******************************************************************************
 *
 *		     PCX FILE FORMAT DEFINITIONS
 *
 ******************************************************************************/

typedef enum {
    PCX_V2_5=0,
    PCX_V2_8PALETTE=2,
    PCX_V2_8NOPAL=3,
    PCX_V3=5,
} PCXVersions;

typedef enum {
    PCX_NOENCODING=0,
    PCX_RLE=1,
} PCXEncoding;

typedef enum {
    PCX_COLOR_BW=1,
    PCX_GREY_SCALE=2,
} PCXPaletteTypes;

#define PCX_MAX_RUN 63	    /* Maximum run-length */
#define PCX_RUN	    0xc0    /* Value to or into/strip from run-length to signal
			     * run */

typedef struct {
    byte    red, green, blue;
} RGBValue;

typedef struct {
    byte    	    PCXH_id;	    	/* Magic number: 0xa */

#if defined _MSC_VER /* msc doesn't calculate size correctly with bit fields */
    byte            PCXH_version;       /* Version number */
    byte            PCXH_encoding;      /* Encoding style */
#else
    PCXVersions     PCXH_version:8; 	/* Version number */
    PCXEncoding	    PCXH_encoding:8;	/* Encoding style */
#endif /* defined _MSC_VER */

    byte    	    PCXH_bitsPerPixel;	/* Number of bits per pixel per plane*/
    word    	    PCXH_upLeftX,
		    PCXH_upLeftY,
		    PCXH_lowRightX,
		    PCXH_lowRightY;
    word    	    PCXH_dispXRes,
		    PCXH_dispYRes;

#if 0
    RGBValue	    PCXH_palette[16]; /* doesn't work on sun3 */
#else
    byte    	    PCXH_palette[16*3];
#endif /* 0 */

    byte    	    PCXH_reserved;
    byte    	    PCXH_planes;        /* planes per pixel */
    word    	    PCXH_bytesPerPlane;	/* Number of bytes in a line */

#if defined _WIN32
    word            PCXH_paletteInfo;
#else
    PCXPaletteTypes PCXH_paletteInfo:16;
#endif /* defined _WIN32 */

    byte    	    PCXH_reserved2[58];
} PCXHeader;

/*
 * GEOS colors
 */

#define C_BLACK 0
#define C_BLUE 1
#define C_GREEN 2
#define C_CYAN 3
#define C_RED 4
#define C_VIOLET 5
#define C_BROWN 6
#define C_LIGHT_GRAY 7
#define C_DARK_GRAY 8
#define C_LIGHT_BLUE 9
#define C_LIGHT_GREEN 10
#define C_LIGHT_CYAN 11
#define C_LIGHT_RED 12
#define C_LIGHT_VIOLET 13
#define C_YELLOW 14
#define C_WHITE 15

#define RC_BLACK 	0 
#define RC_DARK_GRAY	2 
#define RC_LIGHT_GRAY	13
#define RC_WHITE 	15

static const byte GeosColorTable[] = { 
	0x00, 0x00, 0x00, 	/* C_BLACK	  */
	0x00, 0x00, 0xaa,	/* C_BLUE	  */
	0x00, 0xaa, 0x00,	/* C_GREEN	  */
	0x00, 0xaa, 0xaa,	/* C_CYAN	  */
	0xaa, 0x00, 0x00,	/* C_RED	  */
	0xaa, 0x00, 0xaa,	/* C_VIOLET	  */
	0xaa, 0x55, 0x00,	/* C_BROWN	  */
	0xaa, 0xaa, 0xaa,	/* C_LIGHT_GRAY	  */
	0x55, 0x55, 0x55,	/* C_DARK_GRAY	  */
	0x55, 0x55, 0xff,	/* C_LIGHT_BLUE	  */
	0x55, 0xff, 0x55,	/* C_LIGHT_GREEN  */
	0x55, 0xff, 0xff,	/* C_LIGHT_CYAN	  */
	0xff, 0x55, 0x55,	/* C_LIGHT_RED	  */
	0xff, 0x55, 0xff,	/* C_LIGHT_VIOLET */
	0xff, 0xff, 0x55,	/* C_YELLOW	  */
	0xff, 0xff, 0xff,	/* C_WHITE	  */

	/* 16 shades of grey */

	0x00, 0x00, 0x00,	/* index 10	 0.0% */
	0x11, 0x11, 0x11,	/*		 6.7% */
	0x22, 0x22, 0x22,	/*		13.3% */
	0x33, 0x33, 0x33,	/*		20.0% */
	0x44, 0x44, 0x44,	/* index 14	26.7% */
	0x55, 0x55, 0x55,	/*		33.3% */
	0x66, 0x66, 0x66,	/*		40.0% */
	0x77, 0x77, 0x77,	/*		46.7% */
	0x88, 0x88, 0x88,	/* index 18	53.3% */
	0x99, 0x99, 0x99,	/*		60.0% */
	0xaa, 0xaa, 0xaa,	/*		67.7% */
	0xbb, 0xbb, 0xbb,	/*		73.3% */
	0xcc, 0xcc, 0xcc,	/* index 1c	80.0% */
	0xdd, 0xdd, 0xdd,	/*		87.7% */
	0xee, 0xee, 0xee,	/*		93.3% */
	0xff, 0xff, 0xff,	/*	       100.0% */

	/* 8 extra slots */

	0x00, 0x00, 0x00,	/* index 20 */
	0x00, 0x00, 0x00,
	0x00, 0x00, 0x00,
	0x00, 0x00, 0x00,	
	0x00, 0x00, 0x00,
	0x00, 0x00, 0x00,
	0x00, 0x00, 0x00,
	0x00, 0x00, 0x00,	

	/* 216 entries, evenly spaced throughout the RGB space */

	0x00, 0x00, 0x00,
	0x00, 0x00, 0x33,
	0x00, 0x00, 0x66,
	0x00, 0x00, 0x99,
	0x00, 0x00, 0xcc,
	0x00, 0x00, 0xff,
	0x00, 0x33, 0x00,
	0x00, 0x33, 0x33,
	0x00, 0x33, 0x66,
	0x00, 0x33, 0x99,
	0x00, 0x33, 0xcc,
	0x00, 0x33, 0xff,
	0x00, 0x66, 0x00,
	0x00, 0x66, 0x33,
	0x00, 0x66, 0x66,
	0x00, 0x66, 0x99,
	0x00, 0x66, 0xcc,
	0x00, 0x66, 0xff,
	0x00, 0x99, 0x00,
	0x00, 0x99, 0x33,
	0x00, 0x99, 0x66,
	0x00, 0x99, 0x99,
	0x00, 0x99, 0xcc,
	0x00, 0x99, 0xff,
	0x00, 0xcc, 0x00,
	0x00, 0xcc, 0x33,
	0x00, 0xcc, 0x66,
	0x00, 0xcc, 0x99,
	0x00, 0xcc, 0xcc,
	0x00, 0xcc, 0xff,
	0x00, 0xff, 0x00,
	0x00, 0xff, 0x33,
	0x00, 0xff, 0x66,
	0x00, 0xff, 0x99,
	0x00, 0xff, 0xcc,
	0x00, 0xff, 0xff,
	0x33, 0x00, 0x00,
	0x33, 0x00, 0x33,
	0x33, 0x00, 0x66,
	0x33, 0x00, 0x99,
	0x33, 0x00, 0xcc,
	0x33, 0x00, 0xff,
	0x33, 0x33, 0x00,
	0x33, 0x33, 0x33,
	0x33, 0x33, 0x66,
	0x33, 0x33, 0x99,
	0x33, 0x33, 0xcc,
	0x33, 0x33, 0xff,
	0x33, 0x66, 0x00,
	0x33, 0x66, 0x33,
	0x33, 0x66, 0x66,
	0x33, 0x66, 0x99,
	0x33, 0x66, 0xcc,
	0x33, 0x66, 0xff,
	0x33, 0x99, 0x00,
	0x33, 0x99, 0x33,
	0x33, 0x99, 0x66,
	0x33, 0x99, 0x99,
	0x33, 0x99, 0xcc,
	0x33, 0x99, 0xff,
	0x33, 0xcc, 0x00,
	0x33, 0xcc, 0x33,
	0x33, 0xcc, 0x66,
	0x33, 0xcc, 0x99,
	0x33, 0xcc, 0xcc,
	0x33, 0xcc, 0xff,
	0x33, 0xff, 0x00,
	0x33, 0xff, 0x33,
	0x33, 0xff, 0x66,
	0x33, 0xff, 0x99,
	0x33, 0xff, 0xcc,
	0x33, 0xff, 0xff,
	0x66, 0x00, 0x00,
	0x66, 0x00, 0x33,
	0x66, 0x00, 0x66,
	0x66, 0x00, 0x99,
	0x66, 0x00, 0xcc,
	0x66, 0x00, 0xff,
	0x66, 0x33, 0x00,
	0x66, 0x33, 0x33,
	0x66, 0x33, 0x66,
	0x66, 0x33, 0x99,
	0x66, 0x33, 0xcc,
	0x66, 0x33, 0xff,
	0x66, 0x66, 0x00,
	0x66, 0x66, 0x33,
	0x66, 0x66, 0x66,
	0x66, 0x66, 0x99,
	0x66, 0x66, 0xcc,
	0x66, 0x66, 0xff,
	0x66, 0x99, 0x00,
	0x66, 0x99, 0x33,
	0x66, 0x99, 0x66,
	0x66, 0x99, 0x99,
	0x66, 0x99, 0xcc,
	0x66, 0x99, 0xff,
	0x66, 0xcc, 0x00,
	0x66, 0xcc, 0x33,
	0x66, 0xcc, 0x66,
	0x66, 0xcc, 0x99,
	0x66, 0xcc, 0xcc,
	0x66, 0xcc, 0xff,
	0x66, 0xff, 0x00,
	0x66, 0xff, 0x33,
	0x66, 0xff, 0x66,
	0x66, 0xff, 0x99,
	0x66, 0xff, 0xcc,
	0x66, 0xff, 0xff,
	0x99, 0x00, 0x00,
	0x99, 0x00, 0x33,
	0x99, 0x00, 0x66,
	0x99, 0x00, 0x99,
	0x99, 0x00, 0xcc,
	0x99, 0x00, 0xff,
	0x99, 0x33, 0x00,
	0x99, 0x33, 0x33,
	0x99, 0x33, 0x66,
	0x99, 0x33, 0x99,
	0x99, 0x33, 0xcc,
	0x99, 0x33, 0xff,
	0x99, 0x66, 0x00,
	0x99, 0x66, 0x33,
	0x99, 0x66, 0x66,
	0x99, 0x66, 0x99,
	0x99, 0x66, 0xcc,
	0x99, 0x66, 0xff,
	0x99, 0x99, 0x00,
	0x99, 0x99, 0x33,
	0x99, 0x99, 0x66,
	0x99, 0x99, 0x99,
	0x99, 0x99, 0xcc,
	0x99, 0x99, 0xff,
	0x99, 0xcc, 0x00,
	0x99, 0xcc, 0x33,
	0x99, 0xcc, 0x66,
	0x99, 0xcc, 0x99,
	0x99, 0xcc, 0xcc,
	0x99, 0xcc, 0xff,
	0x99, 0xff, 0x00,
	0x99, 0xff, 0x33,
	0x99, 0xff, 0x66,
	0x99, 0xff, 0x99,
	0x99, 0xff, 0xcc,
	0x99, 0xff, 0xff,
	0xcc, 0x00, 0x00,
	0xcc, 0x00, 0x33,
	0xcc, 0x00, 0x66,
	0xcc, 0x00, 0x99,
	0xcc, 0x00, 0xcc,
	0xcc, 0x00, 0xff,
	0xcc, 0x33, 0x00,
	0xcc, 0x33, 0x33,
	0xcc, 0x33, 0x66,
	0xcc, 0x33, 0x99,
	0xcc, 0x33, 0xcc,
	0xcc, 0x33, 0xff,
	0xcc, 0x66, 0x00,
	0xcc, 0x66, 0x33,
	0xcc, 0x66, 0x66,
	0xcc, 0x66, 0x99,
	0xcc, 0x66, 0xcc,
	0xcc, 0x66, 0xff,
	0xcc, 0x99, 0x00,
	0xcc, 0x99, 0x33,
	0xcc, 0x99, 0x66,
	0xcc, 0x99, 0x99,
	0xcc, 0x99, 0xcc,
	0xcc, 0x99, 0xff,
	0xcc, 0xcc, 0x00,
	0xcc, 0xcc, 0x33,
	0xcc, 0xcc, 0x66,
	0xcc, 0xcc, 0x99,
	0xcc, 0xcc, 0xcc,
	0xcc, 0xcc, 0xff,
	0xcc, 0xff, 0x00,
	0xcc, 0xff, 0x33,
	0xcc, 0xff, 0x66,
	0xcc, 0xff, 0x99,
	0xcc, 0xff, 0xcc,
	0xcc, 0xff, 0xff,
	0xff, 0x00, 0x00,
	0xff, 0x00, 0x33,
	0xff, 0x00, 0x66,
	0xff, 0x00, 0x99,
	0xff, 0x00, 0xcc,
	0xff, 0x00, 0xff,
	0xff, 0x33, 0x00,
	0xff, 0x33, 0x33,
	0xff, 0x33, 0x66,
	0xff, 0x33, 0x99,
	0xff, 0x33, 0xcc,
	0xff, 0x33, 0xff,
	0xff, 0x66, 0x00,
	0xff, 0x66, 0x33,
	0xff, 0x66, 0x66,
	0xff, 0x66, 0x99,
	0xff, 0x66, 0xcc,
	0xff, 0x66, 0xff,
	0xff, 0x99, 0x00,
	0xff, 0x99, 0x33,
	0xff, 0x99, 0x66,
	0xff, 0x99, 0x99,
	0xff, 0x99, 0xcc,
	0xff, 0x99, 0xff,
	0xff, 0xcc, 0x00,
	0xff, 0xcc, 0x33,
	0xff, 0xcc, 0x66,
	0xff, 0xcc, 0x99,
	0xff, 0xcc, 0xcc,
	0xff, 0xcc, 0xff,
	0xff, 0xff, 0x00,
	0xff, 0xff, 0x33,
	0xff, 0xff, 0x66,
	0xff, 0xff, 0x99,
	0xff, 0xff, 0xcc,
	0xff, 0xff, 0xff
};



/******************************************************************************
 *
 *	       MISCELLANEOUS TYPE/CONSTANT DEFINITIONS
 *
 ******************************************************************************/
#define TRUE	(-1)
#define FALSE	(0)
typedef int Boolean;

#define CVT_GOC_MODE	    	0x00000001  /* Output for GOC */
#define CVT_TOKEN_MODE	    	0x00000002  /* Output for token database,
					     * so use relative moves */
#define CVT_NO_GSTRING	    	0x00000004  /* Wants chunk, but no graphics
					     * string and no moniker */
#define CVT_NO_MONIKER	    	0x00000008  /* Wants chunk, but only the
					     * graphics string element,
					     * no moniker or start/end string*/
#define CVT_FORCE_MONO	    	0x00000010  /* Force creation of single-plane
					     * bitmap from color image.
					     * BLACK pixels become 1 and
					     * non-black become 0 */
#define CVT_FORCE_INVERSE_MONO	0x00000020  /* Similar, but WHITE becomes 0
					     * and non-white becomes 1 */
#define CVT_NO_RESOURCES    	0x00000040  /* Don't produce resource names,
					     * just moniker/gstring/bitmap */
#define CVT_NO_COMPACT	    	0x00000100  /* Don't compact, even if it'll
					     * save space */
#define CVT_USE_FILL_BITMAP 	0x00000200  /* Use GSFillBitmap, not
					     * GSDrawBitmap, in gstring */
#define CVT_TWO_POINT_OH    	0x00000400  /* Create thing for 2.0 */
#define CVT_ESP_MODE	    	0x00000800  /* Output for Esp */
#define CVT_UIC_MODE	    	0x00001000  /* Output for UIC */
#define CVT_NO_BEGIN_END_STRING	0x00002000  /* Don't output GSBegin/EndString*/

#define CVT_MODE_FLAGS	(CVT_UIC_MODE|CVT_ESP_MODE|CVT_GOC_MODE)

unsigned long	flags = CVT_UIC_MODE;

Boolean mapColorsForResponder = FALSE;

char	    	*inname;    	    /* Current input file */
PCXHeader	header;	    	    /* Header of the current input file */

byte            *colorTable = header.PCXH_palette; /* color table.  Init to
						    * 4bit color pallete.
						    * Switch to 8bit color
						    * pallete if necessary.
						    */

int             outputCustomPalette = 1;
byte            bitsPerPCXPixel = 0; /* number of bits per pixel in the cvx
				      * file */
byte    	maskout = 255;	    /* Pixel whose presence indicates a 0
				     * bit should be placed in the mask */

char    	*rname = "App";     /* Name to give resource */
char    	*mname = "";	    /* Name to give moniker */

#define BITMAP_SIZE (6)	    /* Size of a simple bitmap header */

/* 
 * allows us to print for ui or goc easily -- usually everything is the same 
 * but the string 
 */
#define UIC_OR_GOC_STRING(ui_string, goc_string)  \
        ((flags & CVT_GOC_MODE) ? goc_string : ui_string) 

#define UIC_FILE_SUFFIX "ui"
#define GOC_FILE_SUFFIX "goh"
#define FILE_SUFFIX UIC_OR_GOC_STRING(UIC_FILE_SUFFIX, GOC_FILE_SUFFIX)

/* Standard PC/GEOS artwork sizes. These aren't actually used in the
 * grids, as they'd become to unwieldy. */

#define	LARGE_ICON_WIDTH 64	/* Large (Welcome DOS/GCM Room) */
#define	LARGE_ICON_HEIGHT 40

#define	STANDARD_ICON_WIDTH 48	/* Standard (GeoManager file icons) */
#define	STANDARD_ICON_HEIGHT 30

#define TINY_ICON_WIDTH 32	/* Tiny (GeoManager file icons on small */
#define TINY_ICON_HEIGHT 20	/* screens) */

#define TOOL_ICON_WIDTH 15	/* Tool (Tools in toolbar, toolboxes).  */
#define TOOL_ICON_HEIGHT 15	/* These, unlike the others, are square. */
				/* The reasoning is twofold -- one, we're */
				/* trying to fit a lot across the screen, */
				/* & second,  this size would not be used */
				/* with a name below the image, as is */
				/* normally the case with the two above. */

/* CGA-specific versions of above, to accomodate low vertical resolution  */

#define LARGE_CGA_ICON_WIDTH 64		/* Large */
#define LARGE_CGA_ICON_HEIGHT 18

#define STANDARD_CGA_ICON_WIDTH 48	/* Standard */
#define STANDARD_CGA_ICON_HEIGHT 14

/* no CGA versions of TINY icons */

#define TOOL_CGA_ICON_WIDTH 15		/* Tool.  Not as proportionally */
#define TOOL_CGA_ICON_HEIGHT 10		/* smaller than other sizes, but */
					/* the artists can only do so much */
					/* with so few pixels... */

/******************************************************************************
 *
 *		       WELL-KNOWN ICON FORMATS
 *
 ******************************************************************************/
typedef struct {
    char    	*abbrev;    	    /* Abbreviation by which it's known.
				     * Used for grid creation and resource
				     * and moniker naming. */
    int	    	bpp;	    	    /* Bits per pixel */
    char    	*aspect;    	    /* Aspect ratio */
    char    	*size;	    	    /* Moniker size */
    char    	*style;	    	    /* Moniker style */
    int	    	width;	    	    /* Bitmap width */
    int	    	height;	    	    /* Bitmap height */
    Boolean 	ignore;	    	    /* If format appears in a grid, don't
				     * use it */
} IconFormat;

/*
 * set the bits per pixel for color icon formats to 0 so we can
 * just set them to be equal to the number of colors in the pcx file.
 */
static IconFormat	LargeColor = {
    "LC",   	0,  "normal", 	    "large", 	"icon",
    LARGE_ICON_WIDTH, LARGE_ICON_HEIGHT, FALSE
};

static IconFormat LargeMono = {
    "LM",   	1,  "normal", 	    "large", 	"icon",
    LARGE_ICON_WIDTH, LARGE_ICON_HEIGHT, FALSE
};

static IconFormat StandardColor = {
    "SC",   	0,  "normal", 	    "standard", "icon",
    STANDARD_ICON_WIDTH, STANDARD_ICON_HEIGHT, FALSE
};

static IconFormat StandardMono = {
    "SM",   	1,  "normal", 	    "standard", "icon",
    STANDARD_ICON_WIDTH, STANDARD_ICON_HEIGHT, FALSE
};

static IconFormat LargeCGA = {
    "LCGA", 	1,  "verySquished", "large", 	"icon",
    LARGE_CGA_ICON_WIDTH, LARGE_CGA_ICON_HEIGHT, FALSE
};

static IconFormat StandardCGA = {
    "SCGA", 	1,  "verySquished", "tiny",	"icon",
    STANDARD_CGA_ICON_WIDTH, STANDARD_CGA_ICON_HEIGHT, FALSE
};

static IconFormat TinyColor = {
    "YC",   	0,  "normal", 	    "tiny", 	"icon",
    TINY_ICON_WIDTH, TINY_ICON_HEIGHT, FALSE
};

static IconFormat TinyMono = {
    "YM",   	1,  "normal", 	    "tiny", 	"icon",
    TINY_ICON_WIDTH, TINY_ICON_HEIGHT, FALSE
};

static IconFormat ToolColor = {
    "TC",   	0,  "normal", 	    "tiny", 	"tool",
    TOOL_ICON_WIDTH, TOOL_ICON_HEIGHT, FALSE
};

static IconFormat ToolMono = {
    "TM",   	1,  "normal", 	    "tiny", 	"tool",
    TOOL_ICON_WIDTH, TOOL_ICON_HEIGHT, FALSE
};

static IconFormat ToolCGA = {
    "TCGA", 	1,  "verySquished", "tiny", 	"tool",
    TOOL_CGA_ICON_WIDTH, TOOL_CGA_ICON_HEIGHT, FALSE
};

static IconFormat   *allFormats[] = {
    &LargeColor, &LargeMono, &StandardColor, &StandardMono,
    &LargeCGA, &StandardCGA, &TinyColor, &TinyMono, &ToolColor,
    &ToolMono, &ToolCGA
};

/******************************************************************************
 *
 *			  PRE-DEFINED GRIDS
 *
 ******************************************************************************/
typedef struct {
    int	    	xOffset;    	    /* X coord of upperleft, from upperleft
				     * of the grid */
    int	    	yOffset;    	    /* Y coord of upperleft, from upperleft
				     * of the grid */
    IconFormat	*format;    	    /* Format stored there */
} GridElement;

/*
 * Standard 6-across grid from 1.x days.
 */
static GridElement  standardGrid[] = {
{ 1, 	    	    	    	    	    	    	1, &LargeColor },
{ 1+64+1,						1, &LargeMono },
{ 1+64+1+64+1,						1, &StandardColor },
{ 1+64+1+64+1+48+1,					1, &StandardMono },
{ 1+64+1+64+1+48+1+48+1,				1, &LargeCGA },
{ 1+64+1+64+1+48+1+48+1+64+1,				1, &StandardCGA }
};

/*
 * New 10-across grid that includes tiny icons for handheld devices and
 * tool icons for PM system menus.
 */
static GridElement  fullGrid[] = {
{ 1, 	    	    	    	    	    	    	1, &LargeColor },
{ 1+64+1,					    	1, &LargeMono },
{ 1+64+1+64+1,					    	1, &StandardColor },
{ 1+64+1+64+1+48+1,				    	1, &StandardMono },
{ 1+64+1+64+1+48+1+48+1,			    	1, &LargeCGA },
{ 1+64+1+64+1+48+1+48+1+64+1,			    	1, &StandardCGA },
{ 1+64+1+64+1+48+1+48+1+64+1+48+1,		    	1, &TinyColor },
{ 1+64+1+64+1+48+1+48+1+64+1+48+1+32+1,		    	1, &TinyMono },
{ 1+64+1+64+1+48+1+48+1+64+1+48+1+32+1+32+1,		1, &ToolMono },
{ 1+64+1+64+1+48+1+48+1+64+1+48+1+32+1+32+1+15+1,	1, &ToolCGA }
};

/*
 * Grid for tool icons.
 */
static GridElement  toolGrid[] = {
{ 1,			       	    	    	    	1, &ToolColor },
{ 1+15+1,						1, &ToolMono },
{ 1+15+1+15+1,						1, &ToolCGA }
};

/******************************************************************************
 *
 *		     BITMAP CREATION/MANIPULATION
 *
 ******************************************************************************/
typedef struct {
    byte    *data;  	    /* Start of data */
    byte    *next;  	    /* Next free byte in data */
    byte    *end;   	    /* First byte beyond "data", i.e. the end of
			     * the allocated array */
    byte    **scanlines;    /* Array of pointers to the start of each
			     * scanline (for a bitmap with a mask, the
			     * even entries are for the mask, while the odd
			     * entries are for the bitmap data) */
    int	    curscan;	    /* Current scanline */
    int	    width;
    int	    height;
} Bitmap;

typedef struct {
    Bitmap  compacted;	    /* Compacted form of the icon */
    Bitmap  uncompacted;    /* Uncompacted form of the icon */
    Boolean cvalid; 	    /* TRUE if compacted bitmap is valid, FALSE if it
			     * was too large to fit in the same space as
			     * the uncompacted */
} Icon;


/***********************************************************************
 *				IconCreate
 ***********************************************************************
 * SYNOPSIS:	    Allocate a structure to which bytes can be
 *	    	    added to form an icon.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    Icon *to pass to BitmapAddByte, BitmapEndScanline,
 *	    	    and BitmapSpew
 * SIDE EFFECTS:    something be created, of course.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/11/92	Initial Revision
 *
 ***********************************************************************/
static Icon *
IconCreate(int	    width,
	   int	    height,
	   int	    bitsPerPixel,
	   int	    hasMask)
{
    int	    size;
    Icon    *retval;

    /*
     * Figure the number of bytes needed for the bitmap itself. If the
     * thing has a mask, it's always 1 bit/pixel, so it requires
     * ceil(width/8) bytes to old per scanline. The image data fit in
     * ceil((width * bitsPerPixel)/8) bytes (assuming bpp is a power of 2...)
     * for each scanline.
     */
    size = ((hasMask ? (width+7)/8 : 0) + ((width * bitsPerPixel) + 7)/8) *
	height;
    

    /*
     * Allocate everything we need in one block, so caller can just free
     * the Icon * and have it all go away.
     */
    retval = (Icon *)malloc(sizeof(Icon) +
			    (((2 * size) + 3) & ~3) +	/* image data */
			    (2 *
			     ((height + 1 +	    /* scanline pointers */
			       (hasMask ? height : 0)) *
			      sizeof(byte *))));

    /*
     * Setup pointers for compacted bitmap (data follow the Icon structure)
     */
    retval->compacted.data = (byte *)(retval+1);
    retval->compacted.next = retval->compacted.data;
    retval->compacted.end = retval->compacted.data + size;

    /*
     * Setup pointers for the uncompacted bitmap (data follow the compacted
     * one)
     */
    retval->uncompacted.data = retval->compacted.end;
    retval->uncompacted.next = retval->uncompacted.data;
    retval->uncompacted.end = retval->uncompacted.data + size;

    /*
     * Setup the scanline pointers for both bitmaps.
     */
    retval->compacted.scanlines =
	(byte **)(retval->compacted.data + (((2 * size) + 3) & ~3));
    retval->uncompacted.scanlines =
	&retval->compacted.scanlines[height + (hasMask ? height : 0)];
    
    /*
     * Initialize scanline 0 for each to point to the start of their data.
     */
    retval->compacted.scanlines[0] = retval->compacted.next;
    retval->uncompacted.scanlines[0] = retval->uncompacted.next;

    /*
     * Setup the dimensions and counter for each bitmap.
     */
    retval->compacted.curscan = retval->uncompacted.curscan = 0;

    retval->compacted.width = retval->uncompacted.width = width;

    retval->compacted.height = retval->uncompacted.height =
	height + (hasMask ? height : 0);

    retval->cvalid = TRUE;	/* Assume it will fit */
			    

    return(retval);
}


/***********************************************************************
 *				BitmapAddByte
 ***********************************************************************
 * SYNOPSIS:	    Add another byte to the passed bitmap
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    TRUE if byte could be added
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/11/92	Initial Revision
 *
 ***********************************************************************/
#define BitmapAddByte(bm, b) \
	((bm)->next != (bm)->end ? *(bm)->next++ = (b), TRUE : FALSE)
								   
	   
#define BitmapEndScanline(bm) ((bm)->scanlines[++(bm)->curscan] = (bm)->next)


/***********************************************************************
 *				BitmapSpew
 ***********************************************************************
 * SYNOPSIS:	    Print out the bytes of the passed bitmap,
 *	    	    scanline by scanline.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    If we're in GOC mode, we can just spew things out
 *	    	    as 0x.. separated by commas, with no intro. For Esp,
 *	    	    we can use the same format, but need to start off with
 *	    	    a db.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/11/92	Initial Revision
 *
 ***********************************************************************/
static void
BitmapSpew(Bitmap   *bm,
	   FILE	    *outf)
{
    int	    scan;
    byte    *bp;
    int	    i;

    for (scan = 0, bp = bm->data; scan < bm->height; scan++) {
	if (!(flags & CVT_GOC_MODE)) {
	    fputs("\tdb\t", outf);
	} else {
	    fputs("\t\t", outf);
	}
	
	for (i = 0; bp < bm->scanlines[scan+1]; bp++) {
	    fprintf(outf, "0x%02x", *bp);
	    if (bp+1 == bm->scanlines[scan+1]) {
		if (flags & CVT_GOC_MODE) {
		    fputs(",\n", outf);
		} else {
		    fputs("\n", outf);
		}
	    } else {
		fputs(", ", outf);
		if (++i == 8) {
		    fputs("\n\t\t", outf);
		    i = 0;
		}
	    }
	}
    }
}
    
/******************************************************************************
 *
 *		      PCX -> PC/GEOS CONVERSION
 *
 ******************************************************************************/

/***********************************************************************
 *				ReadScanLine
 ***********************************************************************
 * SYNOPSIS:	    Read a single scanline from the input stream
 * CALLED BY:	    main
 * RETURN:	    number of bytes read into the buffer (0 on eof or
 *	    	    error)
 * SIDE EFFECTS:    buffer is filled
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 5/90		Initial Revision
 *
 ***********************************************************************/
int
ReadScanLine(byte   *buffer,	/* Buffer in which to store bytes */
	     int    bpl,    	/* Bytes per line */
	     FILE   *stream)	/* Stream from which to read */
{
    byte    b;
    int	    i;
    int	    n = bpl;

    b = getc(stream);
    while (bpl > 0 && !feof(stream)) {
	if ((b & PCX_RUN) == PCX_RUN) {
	    i = b & ~PCX_RUN;
	    b = getc(stream);
	    while (i > 0) {
		*buffer++ = b;
		bpl--, i--;
		if (bpl == 0 && i != 0) {
		    fprintf(stderr, "file invalid -- buffer overrun\n");
		    return(0);
		}
	    }
	} else {
	    *buffer++ = b;
	    bpl--;
	}
	b = getc(stream);
    }
    ungetc(b, stream);
    return(n);
}


/***********************************************************************
 *				CompactBytes
 ***********************************************************************
 * SYNOPSIS:	    Put a bunch of bytes into a bitmap, compacted
 * CALLED BY:	    readega
 * RETURN:	    TRUE if all bytes put to the bitmap. FALSE if they
 *	    	    wouldn't all fit.
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/11/92	Initial Revision
 *
 ***********************************************************************/
static Boolean
CompactBytes(byte	    *bytes,
	     int	    len,
	     Bitmap 	    *bm)
{
    byte    	*bp;
    int	    	j;  	    /* Counter of bytes in array */
    int	    	runflag=1;  /* If in a run */
    byte    	match;	    /* Byte to match */
    byte    	*nrp;	    /* Start of non-run */
    int	    	matchCount; /* Length of current run */
    byte    	nonrun[129];
    Boolean 	notfull = TRUE;

    bp = bytes;

    j = len;


    nrp = nonrun;
	
    while (j > 0) {
	j--;
	match = *bp++;
	matchCount = 1;
	    
	while (j > 0 && *bp == match) {
	    bp++;
	    matchCount++;
	    j--;
	    if (matchCount == 129) {
		break;
	    }
	}
	    
	if (matchCount > 2) {
	    /*
	     * Flush previous non-run, if any.
	     */
	    if (nrp != nonrun) {
		byte	*p;
		    
		for (p = nonrun; p != nrp; p++) {
		    notfull = notfull && BitmapAddByte(bm, *p);
		}
	    }
	    nrp = nonrun;

	    notfull = notfull && BitmapAddByte(bm,257-matchCount);
	    notfull = notfull && BitmapAddByte(bm,match);

	    runflag = 1;
	} else {
	    if (runflag) {
		/*
		 * Flush previous non-run, if any.
		 */
		if (nrp != nonrun) {
		    byte	*p;
			
		    for (p = nonrun; p != nrp; p++) {
			notfull = notfull && BitmapAddByte(bm, *p);
		    }
		}
		nrp = nonrun;
		*nrp++ = matchCount-1;
	    } else {
		/*
		 * Add these into the non-run packet
		 */
		nonrun[0] += matchCount;
	    }
		
	    /*
	     * Copy the data into the non-run packet.
	     */
	    while (matchCount--) {
		*nrp++ = match;
	    }
	    /*
	     * Merge unmatching data into this packet unless the size
	     * of the current packet is >= 126. This limit is imposed
	     * by needing to keep the packet size < 128. Since we can
	     * get two bytes of unmatching data per loop, we need to go
	     * to a new packet if the current one contains 126 or 127
	     * bytes
	     */
	    runflag = (nonrun[0] >= 126);
	}
    }
    if (nrp != nonrun) {
	byte    *p;
	    
	for (p = nonrun; p != nrp; p++) {
	    notfull = notfull && BitmapAddByte(bm, *p);
	}
    }

    return(notfull);
}


/***********************************************************************
 *			MapPixelToResponder
 ***********************************************************************
 * SYNOPSIS:	Maps a pixel value to the associated responder value
 * CALLED BY:	readega
 * RETURN:	mapped pixel
 * SIDE EFFECTS:none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	atw	7/10/95   	Initial Revision
 *
 ***********************************************************************/
static const byte responderMap[] = {
    RC_BLACK,     	/* C_BLACK */
    0xff,     	/* C_BLUE */
    RC_DARK_GRAY,     	/* C_GREEN */
    0xff,     	/* C_CYAN */
    0xff,     	/* C_RED */
    RC_DARK_GRAY,     	/* C_VIOLET */
    0xff,     	/* C_BROWN */
    RC_LIGHT_GRAY,     	/* C_LIGHT_GRAY */
    0xff,     	/* C_DARK_GRAY */
    0xff,     	/* C_LIGHT_BLUE */
    0xff,     	/* C_LIGHT_GREEN  */
    0xff,     	/* C_LIGHT_CYAN - should be masked out */
    0xff,     	/* C_LIGHT_RED  */
    RC_LIGHT_GRAY,     	/* C_LIGHT_VIOLET  */
    RC_LIGHT_GRAY,     	/* C_YELLOW  */
    RC_WHITE     	/* C_WHITE  */
};
    
byte
MapPixelToResponder(byte rawPixel)
{
    assert(rawPixel<16);
    if (rawPixel == maskout) {
	return(rawPixel);
    }
    if (responderMap[rawPixel] == 0xff) {
	fprintf(stderr, 
		"**** Error: Unmappable pixel value: %d ****\n", 
		(int) rawPixel);
	exit(1);
    }
    return(responderMap[rawPixel]);
}


/***********************************************************************
 *			MapPixelToGeosColorMap
 ***********************************************************************
 * SYNOPSIS:	Maps a pixel value to the associated geos color value
 * CALLED BY:	readega
 * RETURN:	mapped pixel
 * SIDE EFFECTS:none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	joon	9/27/98   	Initial Revision
 *
 ***********************************************************************/
byte
MapPixelToGeosColorMap(byte rawPixel)
{
    byte i, pixel;
    int delta, x;

    assert(rawPixel<16);
    pixel = rawPixel;
    delta = abs(colorTable[pixel*3+0] - GeosColorTable[pixel*3+0]) +
	    abs(colorTable[pixel*3+1] - GeosColorTable[pixel*3+1]) +
	    abs(colorTable[pixel*3+2] - GeosColorTable[pixel*3+2]);

    for (i = 0; i < 16; i++) {
	x = abs(colorTable[rawPixel*3+0] - GeosColorTable[i*3+0]) +
	    abs(colorTable[rawPixel*3+1] - GeosColorTable[i*3+1]) +
	    abs(colorTable[rawPixel*3+2] - GeosColorTable[i*3+2]);
	if (x < delta) {
	    pixel = i;
	    delta = x;
	}
    }

    return(pixel);
}

/***********************************************************************
 *			Read256ColorPalette
 ***********************************************************************
 * SYNOPSIS:	    Reads in the 256 color palette from a pcx file
 * CALLED BY:	    readvga
 * RETURN:	    byte * : pointer to palette
 * SIDE EFFECTS:    seeks to end of file, then back to starting point.
 *                  Also allocates memory to hold the palette
 *
 * STRATEGY:        Seek 769 bytes from end of file and see if decimal 12
 *                  is stored there.  If so there is a palette so read
 *                  it in.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	timb    1/12/99         Initial Revision
 *
 ***********************************************************************/
byte *
Read256ColorPalette(FILE *stream)
{
    int   checkByte;
    long  currentPos;
    byte *palette = NULL;

    /*
     * save current file position for restoration later
     */
    currentPos = ftell(stream);

    if (fseek(stream, -769, SEEK_END) != 0) {
	goto error;
    }

    /*
     * Make sure the magic number is there.  If not, there's something wrong.
     */
    checkByte = fgetc(stream);
    if (checkByte != 12) {
        if (checkByte == -1) {
            if (ferror(stream)) {
                perror("Get check byte");
            } else if (feof(stream)) {
                fprintf(stderr, "EOF while reading input.\n");
            }
        }
	goto error;
    }

    palette = (byte *) malloc(768 * sizeof(byte));

    if (fread(palette, 768, 1, stream) != 1) {
	free(palette);
	palette = NULL;
	goto error;
    }

error:
    fseek(stream, currentPos, SEEK_SET);
    return palette;
}

/***********************************************************************
 *			IsSameAsGeosPalette
 ***********************************************************************
 * SYNOPSIS:	    Compares the pcx file's palette with geos palette
 * CALLED BY:	    readvga
 * RETURN:	    0 if the palettes are different, 1 if they're the same
 *
 * STRATEGY:        Compare each entry in each table to see if they match
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	timb    3/04/99         Initial Revision
 *
 ***********************************************************************/
int
IsSameAsGeosPalette(byte *palette)
{
    int i;

    for (i = 0; i < 256 * 3; i++) {
	if (palette[i] != GeosColorTable[i]) {
	    return 0;
	}
    }

    return 1;
}
/***********************************************************************
 *				readvga
 ***********************************************************************
 * SYNOPSIS:	    Read and convert aa vga pcx file, producing two
 *		    bitmaps, one compacted and one uncompacted.
 * CALLED BY:	    ConvertFormat
 * RETURN:	    Icon *
 * SIDE EFFECTS:    a bunch
 *
 * STRATEGY:        do what readega does with changes necessary to support
 *                  256 colors.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	timb    1/8/99          Initial Revision
 *
 ***********************************************************************/
Icon *
readvga(FILE       *stream,
	IconFormat *format, 	    /* Format for resulting bitmap */
	int 	    xoffset,	    /* X offset at which to start converting */
	int 	    yoffset)	    /* Y offset at which to start converting */
{
    byte       *planes;
    byte       *pixels;
    int	    	pixellen;
    byte       *mask;
    int	    	masklen;
    int	    	i;
    int	    	bpl;
    int	    	bpp;
    int	    	maxx;
    int	    	y;
    int	    	maxy;
    Icon       *result;

    /*
     * read in the 256 color palette
     */
    colorTable = Read256ColorPalette(stream);
    if (colorTable == NULL) {
	return NULL;
    }

    outputCustomPalette = !IsSameAsGeosPalette(colorTable);

    /*
     * Fetch the number of bytes per scanline in the input file and allocate
     * a buffer sufficient to hold an entire scanline.
     *
     * We derive the size from the number of bytes in a single plane times the
     * number of planes in the scanline.
     */
    bpp    = swaps(header.PCXH_bytesPerPlane);
    bpl    = header.PCXH_planes * bpp;
    planes = (byte *) malloc(bpl);

    /*
     * Figure the largest X coordinate in the image, so we know when we have
     * to fill in things.
     */
    maxx = swaps(header.PCXH_lowRightX)-swaps(header.PCXH_upLeftX)+1;


    /*
     * Allocate a buffer to hold all the pixels that make up the icon, as we
     * need to construct and postprocess the things in somewhat nasty ways.
     */
    pixellen = (format->width + 1);
    pixels   = (byte *) calloc(pixellen, 1);

    /*
     * Ditto for the mask.
     */
    masklen = (format->width + 7) / 8;
    mask    = (byte *) calloc(masklen, 1);

    /*
     * Figure starting y coordinate and its maximum.
     */
    y    = swaps(header.PCXH_upLeftY);
    maxy = swaps(header.PCXH_lowRightY) + 1;

    /*
     * Create the icon we're going to return.
     */
    result = IconCreate(format->width,
			format->height,
			format->bpp,
			( (maskout != 255) && (format->bpp > 1) ));

    for (i = format->height + yoffset; i > 0; i--, y++) {
	int 	j,  	    /* The number of pixels left to fetch for this
			     * scanline */
		k;  	    /* The number of bits left in m */
	byte	*bp0;	    /* Pointer into bitplane 0 */
	byte	*pp;	    /* Pointer into the pixels array */
	byte	*mp;	    /* Pointer into the mask array */
	byte    b,  	    /* Current byte for the pixels array */
		m;  	    /* Current byte for the mask array */
	
	/*
	 * Fetch the next line of data.
	 */
	(void)ReadScanLine(planes, bpl, stream);

	/*
	 * If not yet in range of the area we're to convert, fetch the next
	 * line. (This code is sort of ass-backwards. When i reaches
	 * format->height, it means we've skipped over yoffset lines)
	 */
	if (i > format->height) {
	    continue;
	}

	/*
	 * Convert the bit-planes into packed pixels before we do anything
	 * about forcing them to monochrome or adding a mask, or what have you.
	 */
	bp0 = planes;
	pp  = pixels;
	mp  = mask;

	if (xoffset < 0) {
	    /*
	     * Deal with negative x offset by zeroing the mask and the pixel
	     * arrays until we get to the proper position. Easiest just to
	     * go in a loop. We end up with k and l set up for the following
	     * loop to properly shift in actual pixels and mask bits.
	     *
	     * We actually use the mask pixel to fill things in in the pixel
	     * array, just in case (for the case where we have no mask, this
	     * means we're putting in white...)
	     */
	    b = maskout & 0xff;
	    for (k = 8, j = -xoffset; j > 0; j--) {
		if (--k == 0) {
		    *mp++ = 0;
		    k = 8;
		}

		*pp++ = b;
	    }
	    j = maxx;
	    /*
	     * Make sure not to overflow the pixels and mask arrays
	     */
	    if (j > format->width + xoffset) {
		j = format->width + xoffset;
	    }

	} else {
	    if (xoffset > 0) {
		/*
		 * Deal with positive xoffset by incrementing bp0 by the x offset
		 */
		bp0 += xoffset;

		j  = maxx - xoffset;
	    } else {
		/*
		 * Convert all pixels...
		 */
		j = maxx;
	    }
	    if (j > format->width) {
		j = format->width;
	    }
	    b = 0;
	    k = 8;
	}

	/*
	 * Right. We now have things set up for the actual conversion of
	 * pixel data.
	 *  j	= # pixels to convert to fill up pixels/mask
	 *  pp	= place to store the next pixel pair
	 *  mp	= place to store the next mask octet
	 *  k	= # bits left in m
	 */
	m = 0;			/* Everything up to now is masked out */

	while (j > 0) {
	    /*
	     * Loop while we've got pixels to get
	     */
	    
	    /*
	     * fetch the next byte into b
	     */
	    b = *bp0;
		
	    /*
	     * If current pixel matches the one we're masking out,
	     * or if we've gone beyond the bounds of the picture, mask it
	     * out.
	     */
	    m <<= 1;
	    m |= ((b & 0xff) == maskout) ? 0 : ((y >= maxy) ? 0 : 1);
		
	    /*
	     * If that finishes off the mask byte, store it.
	     */
	    if (--k == 0) {
		*mp++ = m;
		k = 8;
	    }
		
	    /*
	     * store b
	     */
	    *pp++ = b;

	    j--;

	    /*
	     * Advance to the next byte in the bitplane data.
	     */
	    bp0++;
	}

	/*
	 * Store any lingering mask or pixel bytes, left-justifying them
	 * if necessary.
	 */
	if (k != 8) {
	    *mp++ = (m << k);
	}

	/*
	 * Now post-process the pixel and mask arrays based on the icon format
	 * and the state of the CVT_FORCE_INVERSE_MONO and CVT_FORCE_MONO
	 * bits in "flags".
	 */
	if (format->bpp == 1) {
	    if (!(flags & CVT_FORCE_INVERSE_MONO)) {
		/*
		 * Convert BLACK pixels to 1's and everything else to 0's
		 */
		m = 0;
		for (pp = pixels, j = format->width, k = 8; j > 0; j -= 2){
		    m <<= 1;
		    m |= (*pp & 0xff) ? 0 : 1;
		    pp++;
		    if ((k -= 2) == 0) {
			if (j == 1) {
			    /*
			     * If last pixel wasn't real (width is odd), make it
			     * the same as the last real pixel. This allows for
			     * better compression, especially on rows that are
			     * all 0 except the last fake pixel (which is
			     * initialized to BLACK, causing a 1 bit for it)
			     */
			    if (m & 2) {
				m |= 1;
			    } else {
				m &= ~1;
			    }
			}

			BitmapAddByte(&result->uncompacted, m);
			m = 0;
			k = 8;
		    }
		}
	    } else {
		/*
		 * If a pixel is white or the mask pixel, make the pixel 0.
		 * Else make the pixel 1.
		 */
		
		/*
		 * Figure mask pixel for low and high nibbles (if pixel is
		 * white or the mask, it gets a 0 in the bitmap). Since maskout
		 * is 255 if no mask was given, this gives the proper values of
		 * white for both highmask and lowmask.
		 * Added 10/19/90 for card decks... -- ardeb
		 */
		m = 0;
		for (pp = pixels, j = format->width, k = 8; j > 0; j -= 2) {
		    m <<= 1;
		    m |= (((*pp & 0xff) == 0xff) ||
			  ((*pp & 0xff) == maskout)) ? 0 : 1;
		    pp++;
		    if ((k -= 2) == 0) {
			if (j == 1) {
			    /*
			     * If last pixel wasn't real (width is odd), make it
			     * the same as the last real pixel. This allows for
			     * better compression, especially on rows that are
			     * all 0 except the last fake pixel (which is
			     * initialized to BLACK, causing a 1 bit for it)
			     */
			    if (m & 2) {
				m |= 1;
			    } else {
				m &= ~1;
			    }
			}
			BitmapAddByte(&result->uncompacted, m);
			m = 0;
			k = 8;
		    }
		}
	    }
	    /*
	     * If last pixel wasn't real (width is odd), make it the same as
	     * the last real pixel. This allows for better compression,
	     * especially on rows that are all 0 except the last fake pixel
	     * (which is initialized to BLACK, causing a 1 bit for it)
	     */
	    if ((format->width & 1) && (k != 8)) {
		if (m & 2) {
		    m |= 1;
		} else {
		    m &= ~1;
		}
	    }
	    if (k != 8) {
		BitmapAddByte(&result->uncompacted, m << k);
	    }
	    mp = result->uncompacted.scanlines[result->uncompacted.curscan];
	    result->cvalid = result->cvalid &&
		             CompactBytes(mp,
					  result->uncompacted.next - mp,
					  &result->compacted);
	} else {
	    if (maskout != 255) {
		/*
		 * Add the mask pixels to the compacted and uncompacted forms.
		 */
		for (bp0 = mask; bp0 < mp; bp0++) {
		    BitmapAddByte(&result->uncompacted, *bp0);
		}
		BitmapEndScanline(&result->uncompacted);
		
		result->cvalid = result->cvalid &&
		    CompactBytes(mask, mp-mask, &result->compacted);

		BitmapEndScanline(&result->compacted);
	    }

	    /*
	     * Now transfer all the image pixels in.
	     */
	    for (bp0 = pixels; bp0 < pp; bp0++) {
		BitmapAddByte(&result->uncompacted, *bp0);
	    }
	    result->cvalid = result->cvalid &&
		             CompactBytes(pixels,
					  pp-pixels,
					  &result->compacted);
	    
	}
	BitmapEndScanline(&result->uncompacted);
	BitmapEndScanline(&result->compacted);
	
    }
    free(planes);
    free(pixels);
    free(mask);

    return(result);

}

/***********************************************************************
 *				readega
 ***********************************************************************
 * SYNOPSIS:	    Read and convert an ega pcx file, producing two
 *		    bitmaps, one compacted and one uncompacted.
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    foo
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 5/90		Initial Revision
 *
 ***********************************************************************/
Icon	*
readega(FILE	    *stream,
	IconFormat  *format, 	    /* Format for resulting bitmap */
	int 	    xoffset,	    /* X offset at which to start converting */
	int 	    yoffset)	    /* Y offset at which to start converting */
{
    byte    	*planes;
    byte    	*pixels;
    int	    	pixellen;
    byte    	*mask;
    int	    	masklen;
    int	    	i;
    int	    	bpl;
    int	    	bpp;
    int	    	maxx;
    int	    	y;
    int	    	maxy;
    Icon    	*result;

    /*
     * Fetch the number of bytes per scanline in the input file and allocate
     * a buffer sufficient to hold an entire scanline.
     *
     * We derive the size from the number of bytes in a single plane times the
     * number of planes in the scanline.
     */
    bpp = swaps(header.PCXH_bytesPerPlane);
    bpl = header.PCXH_planes * bpp;
    planes = (byte *)malloc(bpl);

    /*
     * Figure the largest X coordinate in the image, so we know when we have
     * to fill in things.
     */
    maxx = swaps(header.PCXH_lowRightX)-swaps(header.PCXH_upLeftX)+1;

    /*
     * Allocate a buffer to hold all the pixels that make up the icon, as we
     * need to construct and postprocess the things in somewhat nasty ways.
     */
    pixellen = (format->width + 1)/2;
    pixels = (byte *)calloc(pixellen, 1);

    /*
     * Ditto for the mask.
     */
    masklen = (format->width + 7) / 8;
    mask = (byte *)calloc(masklen, 1);

    /*
     * Figure starting y coordinate and its maximum.
     */
    y = swaps(header.PCXH_upLeftY);
    maxy = swaps(header.PCXH_lowRightY)+1;

    /*
     * Create the icon we're going to return.
     */
    result = IconCreate(format->width, format->height, format->bpp,
			((maskout != 255) && (format->bpp > 1)));

    for (i = format->height+yoffset; i > 0; i--, y++) {
	int 	j,  	    /* The number of pixels left to fetch for this
			     * scanline */
		k;  	    /* The number of bits left in m */
	byte	*bp0,	    /* Pointer into bitplane 0 */
		*bp1,	    /* Pointer into bitplane 1 */
		*bp2,	    /* Pointer into bitplane 2 */
		*bp3;	    /* Pointer into bitplane 3 */
	byte	*pp;	    /* Pointer into the pixels array */
	byte	*mp;	    /* Pointer into the mask array */
	byte    b,  	    /* Current byte for the pixels array */
		m;  	    /* Current byte for the mask array */
	int    	l;  	    /* This is, effectively, a toggle. It is 0
			     * if b holds only the leftmost pixel, or
			     * 1 if b holds both pixels */
	int	bk; 	    /* The number of bits left at *bp[0-3] */
	
	/*
	 * Fetch the next line of data.
	 */
	(void)ReadScanLine(planes, bpl, stream);

	/*
	 * If not yet in range of the area we're to convert, fetch the next
	 * line. (This code is sort of ass-backwards. When i reaches
	 * format->height, it means we've skipped over yoffset lines)
	 */
	if (i > format->height) {
	    continue;
	}

	/*
	 * Convert the bit-planes into packed pixels before we do anything
	 * about forcing them to monochrome or adding a mask, or what have you.
	 */
	bp0 = planes;
	bp1 = bp0 + bpp;
	bp2 = bp1 + bpp;
	bp3 = bp2 + bpp;

	pp = pixels;
	mp = mask;
	
	if (xoffset < 0) {
	    /*
	     * Deal with negative x offset by zeroing the mask and the pixel
	     * arrays until we get to the proper position. Easiest just to
	     * go in a loop. We end up with k and l set up for the following
	     * loop to properly shift in actual pixels and mask bits.
	     *
	     * We actually use the mask pixel to fill things in in the pixel
	     * array, just in case (for the case where we have no mask, this
	     * means we're putting in white...)
	     */
	    b = (maskout&0xf) | ((maskout&0xf)<<4);
	    for (l = 0, k = 8, j = -xoffset; j > 0; j--) {
		if (--k == 0) {
		    *mp++ = 0;
		    k = 8;
		}
		if (++l == 2) {
		    *pp++ = b;
		    l = 0;
		}
	    }
	    j = maxx;
	    /*
	     * Make sure not to overflow the pixels and mask arrays
	     */
	    if (j > format->width+xoffset) {
		j = format->width+xoffset;
	    }
	    bk = 8;
	} else {
	    if (xoffset > 0) {
		/*
		 * Deal with positive xoffset by adjust bp[0-3] eight pixels at
		 * a time, then shifting *bp[0-3] to account for any remainder.
		 * l and k are left at 0 and 8, as we want to end up with mask
		 * and pixels starting with valid data.
		 */
		int	bytes = xoffset/8;
		int	bits = xoffset % 8;

		bp0 += bytes;
		bp1 += bytes;
		bp2 += bytes;
		bp3 += bytes;

		*bp0 <<= bits;
		*bp1 <<= bits;
		*bp2 <<= bits;
		*bp3 <<= bits;

		j  = maxx - xoffset;
		bk = 8 - bits;
	    } else {
		/*
		 * Convert all pixels...
		 */
		j = maxx;
		bk = 8;
	    }
	    if (j > format->width) {
		j = format->width;
	    }
	    b = l = 0, k = 8;
	}

	/*
	 * Right. We now have things set up for the actual conversion of
	 * pixel data.
	 *  bk	= # bits left at *bp[0-3]
	 *  j	= # pixels to convert to fill up pixels/mask
	 *  pp	= place to store the next pixel pair
	 *  mp	= place to store the next mask octet
	 *  l	= 0 if b contains nothing, 1 if it contains the leftmost
	 *	  pixel in its low nibble
	 *  k	= # bits left in m
	 */
	m = 0;			/* Everything up to now is masked out */

	while (j > 0) {
	    /*
	     * Loop while we've got bits left at *bp[0-3] and pixels to get
	     */
	    while (bk > 0 && j > 0) {
		/*
		 * Shift in the bit-planes (bp3 is the msb)
		 */
		b <<= 1;
		b |= (*bp3 & 0x80) ? 1 : 0;
		b <<= 1;
		b |= (*bp2 & 0x80) ? 1 : 0;
		b <<= 1;
		b |= (*bp1 & 0x80) ? 1 : 0;
		b <<= 1;
		b |= (*bp0 & 0x80) ? 1 : 0;
		
		/*
		 * If current pixel matches the one we're masking out,
		 * or if we've gone beyond the bounds of the picture, mask it
		 * out.
		 */
		m <<= 1;
		m |= ((b&0xf) == maskout) ? 0 : ((y >= maxy) ? 0 : 1);
		
		/*
		 * If that finishes off the mask byte, store it.
		 */
		if (--k == 0) {
		    *mp++ = m;
		    k = 8;
		}
		
		/*
		 * If b contains a full pixel, store it
		 */
		if (++l == 2) {
		    l = 0;
		    *pp++ = b;
		}
		/*
		 * Shift up the bytes in the four bit-planes.
		 */
		*bp3 <<= 1; *bp2 <<= 1; *bp1 <<= 1; *bp0 <<= 1;
		bk--; j--;
	    }
	    /*
	     * Advance to the next byte in the bitplane data.
	     */
	    bk = 8;
	    bp0++, bp1++, bp2++, bp3++;
	}
	/*
	 * Store any lingering mask or pixel bytes, left-justifying them
	 * if necessary.
	 */
	if (k != 8) {
	    *mp++ = (m << k);
	}
	if (l == 1) {
	    *pp++ = (b << 4);
	}

	/*
	 * Now post-process the pixel and mask arrays based on the icon format
	 * and the state of the CVT_FORCE_INVERSE_MONO and CVT_FORCE_MONO
	 * bits in "flags".
	 */
	if (format->bpp == 1) {
	    if (!(flags & CVT_FORCE_INVERSE_MONO)) {
		/*
		 * Convert BLACK pixels to 1's and everything else to 0's
		 */
		m = 0;
		for (pp = pixels, j = format->width, k = 8; j > 0; j -= 2){
		    m <<= 1;
		    m |= (*pp & 0xf0) ? 0 : 1;
		    m <<= 1;
		    m |= (*pp & 0x0f) ? 0 : 1;
		    pp++;
		    if ((k -= 2) == 0) {
			if (j == 1) {
			    /*
			     * If last pixel wasn't real (width is odd), make it
			     * the same as the last real pixel. This allows for
			     * better compression, especially on rows that are
			     * all 0 except the last fake pixel (which is
			     * initialized to BLACK, causing a 1 bit for it)
			     */
			    if (m & 2) {
				m |= 1;
			    } else {
				m &= ~1;
			    }
			}
			BitmapAddByte(&result->uncompacted, m);
			m = 0; k = 8;
		    }
		}
	    } else {
		/*
		 * If a pixel is white or the mask pixel, make the pixel 0.
		 * Else make the pixel 1.
		 */
		byte highmask, lowmask;
		
		/*
		 * Figure mask pixel for low and high nibbles (if pixel is
		 * white or the mask, it gets a 0 in the bitmap). Since maskout
		 * is 255 if no mask was given, this gives the proper values of
		 * white for both highmask and lowmask.
		 * Added 10/19/90 for card decks... -- ardeb
		 */
		highmask = maskout << 4; lowmask = maskout & 0xf;
		
		m = 0;
		for (pp = pixels, j = format->width, k = 8; j > 0; j -= 2) {
		    m <<= 1;
		    m |= (((*pp & 0xf0) == 0xf0) ||
			  ((*pp & 0xf0) == highmask)) ?
			      0 : 1;
		    m <<= 1;
		    m |= (((*pp & 0x0f) == 0x0f) ||
			  ((*pp & 0x0f) == lowmask)) ?
			      0 : 1;
		    pp++;
		    if ((k -= 2) == 0) {
			if (j == 1) {
			    /*
			     * If last pixel wasn't real (width is odd), make it
			     * the same as the last real pixel. This allows for
			     * better compression, especially on rows that are
			     * all 0 except the last fake pixel (which is
			     * initialized to BLACK, causing a 1 bit for it)
			     */
			    if (m & 2) {
				m |= 1;
			    } else {
				m &= ~1;
			    }
			}
			BitmapAddByte(&result->uncompacted, m);
			m = 0; k = 8;
		    }
		}
	    }
	    /*
	     * If last pixel wasn't real (width is odd), make it the same as
	     * the last real pixel. This allows for better compression,
	     * especially on rows that are all 0 except the last fake pixel
	     * (which is initialized to BLACK, causing a 1 bit for it)
	     */
	    if ((format->width & 1) && (k != 8)) {
		if (m & 2) {
		    m |= 1;
		} else {
		    m &= ~1;
		}
	    }
	    if (k != 8) {
		BitmapAddByte(&result->uncompacted, m << k);
	    }
	    mp = result->uncompacted.scanlines[result->uncompacted.curscan];
	    result->cvalid = result->cvalid &&
		CompactBytes(mp, result->uncompacted.next-mp,
			     &result->compacted);
	} else {
	    if (maskout != 255) {
		/*
		 * Add the mask pixels to the compacted and uncompacted forms.
		 */
		for (bp0 = mask; bp0 < mp; bp0++) {
		    BitmapAddByte(&result->uncompacted, *bp0);
		}
		BitmapEndScanline(&result->uncompacted);
		
		result->cvalid = result->cvalid &&
		    CompactBytes(mask, mp-mask, &result->compacted);

		BitmapEndScanline(&result->compacted);
	    }

	    /*
	     * Now transfer all the image pixels in.
	     */
	    if (mapColorsForResponder) {
		for (bp0 = pixels; bp0 < pp; bp0++) {
		    byte highPixel, lowPixel;
		    highPixel = MapPixelToResponder((*bp0&0xf0)>>4);
    		    lowPixel = MapPixelToResponder(*bp0&0x0f);
		    *bp0 = lowPixel | (highPixel<<4);
		}
	    } else {
		for (bp0 = pixels; bp0 < pp; bp0++) {
		    byte highPixel, lowPixel;
		    highPixel = MapPixelToGeosColorMap((*bp0&0xf0)>>4);
		    lowPixel = MapPixelToGeosColorMap(*bp0&0x0f);
		    *bp0 = lowPixel | (highPixel<<4);
		}
	    }

	    for (bp0 = pixels; bp0 < pp; bp0++) {
		BitmapAddByte(&result->uncompacted, *bp0);
	    }
	    result->cvalid = result->cvalid &&
		CompactBytes(pixels, pp-pixels, &result->compacted);
	    
	}
	BitmapEndScanline(&result->uncompacted);
	BitmapEndScanline(&result->compacted);
	
    }
    free(planes);
    free(pixels);
    free(mask);

    return(result);
}


/***********************************************************************
 *				UpCase
 ***********************************************************************
 * SYNOPSIS:	    Make a copy of a string, ensuring that all its lower
 *	    	    case letters are mapped to uppercase.
 * CALLED BY:	    (INTERNAL) EnterResource, ExitResource
 * RETURN:	    dynamically-allocated string with nary a lowercase
 *		    letter to be seen.
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/92	Initial Revision
 *
 ***********************************************************************/
static char *
UpCase(const char *str)
{
    char    *result, *cp;

    result = (char *)malloc(strlen(str)+1);

    for (cp = result; *str != '\0'; str++) {
	if (islower(*str)) {
	    *cp++ = toupper(*str);
	} else {
	    *cp++ = *str;
	}
    }
    *cp = '\0';
    return(result);
}


/***********************************************************************
 *				OutputCommentary
 ***********************************************************************
 * SYNOPSIS:	    Put out a little header saying how the thing was
 *	    	    converted and from where.
 * CALLED BY:	    (INTERNAL) ConvertFormat
 * RETURN:	    nothing
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/92	Initial Revision
 *
 ***********************************************************************/
static void
OutputCommentary(IconFormat *format, FILE *outf)
{
    if (!(flags & CVT_NO_MONIKER)) {
	if (flags & CVT_ESP_MODE) {
	    fprintf(outf, ";\n; Moniker generated from %s", inname);
	    if (maskout != 255) {
		fprintf(outf, " with pixel %d masked out\n;\n");
	    } else {
		fputs("\n;\n", outf);
	    }
	} else {
	    fprintf(outf, "/*\n * Moniker generated from %s", inname);
	    if (maskout != 255) {
		fprintf(outf, " with pixel %d masked out\n */\n", maskout);
	    } else {
		fputs("\n */\n", outf);
	    }
	}
    }
}


/***********************************************************************
 *				EnterResource
 ***********************************************************************
 * SYNOPSIS:	    Put out text to enter the resource appropriate to
 *		    this bitmap format.
 * CALLED BY:	    (INTERNAL) ConvertFormat
 * RETURN:	    nothing
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/92	Initial Revision
 *
 ***********************************************************************/
static void
EnterResource(IconFormat *format, FILE *outf)
{    
    if (!(flags & CVT_NO_RESOURCES)) {
	switch(flags & CVT_MODE_FLAGS) {
	case CVT_ESP_MODE:
	    fprintf(outf, "%s%sMonikerResource segment lmem LMEM_TYPE_GENERAL, mask LMF_NOT_DETACHABLE\n",
		    rname, format->abbrev);
	    break;
	case CVT_GOC_MODE:
	    /*
	     * Do things in uppercase so we don't have to track down all
	     * the uses of the uppercase form in our sample and real apps
	     * and switch them to mixed case. Unfortunately, HighC puts things
	     * out in upper-case, but does a case-sensitive comparison of
	     * names it is given, so it doesn't realize how badly it's
	     * going to bone Glue, which gets two SEGDEF records for the same
	     * segment in the same file and nicely overlays them both...
	     */
	    fprintf(outf, "@start %s%sMONIKERRESOURCE, %s;\n",
		    UpCase(rname), UpCase(format->abbrev),
		    (flags & CVT_TWO_POINT_OH) ? "data" : "notDetachable");
	    break;
	case CVT_UIC_MODE:
	    fprintf(outf, "start %s%sMonikerResource, %s;\n",
		    rname, format->abbrev,
		    (flags & CVT_TWO_POINT_OH) ? "data" : "notDetachable");
	    break;
	}
    }
}


/***********************************************************************
 *				OpenChunk
 ***********************************************************************
 * SYNOPSIS:	    Put out the entry into the chunk, as well as all the
 *		    stuff leading up to the bitmap header itself.
 * CALLED BY:	    (INTERNAL) ConvertFormat
 * RETURN:	    Actual height of the bitmap, as adjusted to cope
 *		    with the file not having actually had data for
 *		    some of the lines.
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/92	Initial Revision
 *
 ***********************************************************************/
static int
OpenChunk(IconFormat *format, int yoffset, int size, FILE *outf)
{
    int	    height = format->height;

    if (flags & CVT_NO_GSTRING) {
	/*
	 * Just the bitmap, please.
	 */
	switch(flags & CVT_MODE_FLAGS) {
	case CVT_ESP_MODE:
	    fprintf(outf, "%s%sMoniker chunk	Bitmap\n",
		    mname, format->abbrev);
	    break;
	case CVT_UIC_MODE:
	    fprintf(outf, "chunk %s%sMoniker = data {\n",
		    mname, format->abbrev);
	    break;
	case CVT_GOC_MODE:
	    fprintf(outf, "@chunk byte %s%sMoniker[] = {\n",
		    mname, format->abbrev);
	    break;
	}
    } else {
	char	*drawStr, *moveStr, *drawCpStr;
	int bitmapSize;

	if (format->bpp == 8) {
	    if (outputCustomPalette) {
		bitmapSize = 790;
	    } else {
		bitmapSize = 20;
	    }
	} else {
	    bitmapSize = BITMAP_SIZE;
	}

	/*
	 * Put out the visMoniker/@visMoniker directive, along with the
	 * various moniker parameters (style, aspect, etc.)
	 */
	if (!(flags & CVT_NO_MONIKER)) {
	    switch(flags & CVT_MODE_FLAGS) {
	    case CVT_ESP_MODE:
		/*XXX: DO SOMETHING HERE */
		break;
	    case CVT_GOC_MODE:
		putc('@', outf);
		/*FALLTHRU*/
	    case CVT_UIC_MODE:
		fprintf(outf, "visMoniker %s%sMoniker = {\n",
			mname, format->abbrev);
		fprintf(outf, "\tsize = %s;\n", format->size);
		if (flags & CVT_TWO_POINT_OH) {
		    fprintf(outf, "\tstyle = %s;\n", format->style);
		}
		fprintf(outf, "\taspectRatio = %s;\n", format->aspect);
		switch (format->bpp) {
		case 1:
		    fputs("\tcolor = gray1;\n", outf);
		    break;
		default:
		    fprintf(outf, "\tcolor = color%d;\n", format->bpp);
		    break;
		}
		fprintf(outf, "\tcachedSize = %d, %d;\n", format->width,
			format->height);
		fprintf(outf, "\tgstring {\n");
		break;
	    }
	}
	/*
	 * GOC version does no error-checking, so GSBeginString not used
	 */
	if (!(flags & CVT_NO_BEGIN_END_STRING) &&
	    (flags & (CVT_UIC_MODE|CVT_ESP_MODE))) {
	    fputs("\t\tGSBeginString\n", outf);
	}

	/*
	 * For monochrome monikers under 2.0, we need to use GrFillBitmap,
	 * not GrDrawBitmap. Set up the three formatting strings we need
	 * based on whether we're filling or drawing, and who will be reading
	 * the output.
	 */
	if ((flags & CVT_USE_FILL_BITMAP) && (format->bpp == 1)) {
	    if (flags & (CVT_ESP_MODE|CVT_UIC_MODE)) {
		drawStr = "\t\tGSFillBitmap 0, %d, %d\n";
		moveStr = "\t\tGSRelMoveTo 0, %d\n";
		drawCpStr = "\t\tGSFillBitmapAtCP %d\n";
	    } else {
		drawStr = "\t\tGSFillBitmap(0, %d, %d),\n";
		moveStr = "\t\tGSRelMoveTo(0, %d),\n";
		drawCpStr = "\t\tGSFillBitmapAtCP(%d),\n";
	    }
	} else {
	    if (flags & (CVT_ESP_MODE|CVT_UIC_MODE)) {
		drawStr = "\t\tGSDrawBitmap 0, %d, %d\n";
		moveStr = "\t\tGSRelMoveTo 0, %d\n";
		drawCpStr = "\t\tGSDrawBitmapAtCP %d\n";
	    } else {
		drawStr = "\t\tGSDrawBitmap(0, %d, %d),\n";
		moveStr = "\t\tGSRelMoveTo(0, %d),\n";
		drawCpStr = "\t\tGSDrawBitmapAtCP(%d),\n";
	    }
	}

	if ((yoffset < 0) && !(flags & CVT_TOKEN_MODE)) {
	    /*
	     * Missing the top part and not writing creating something
	     * for the token database, so we can use an absolute coordinate
	     * and GSFillBitmap.
	     */
	    height += yoffset;
	    fprintf(outf, drawStr, -yoffset, size + bitmapSize);
	} else {
	    /*
	     * Going into the token database, or we have all the bits
	     * we need (yoffset >= 0), so use GSFillBitmapAtCP instead
	     * (it's smaller).
	     */
	    if (yoffset < 0) {
		/*
		 * Don't have all the bits, but we can't use an absolute
		 * GSFillBitmap, so do a relative move.
		 */
		height += yoffset;
		fprintf(outf, moveStr, -yoffset);
	    }
	    fprintf(outf, drawCpStr, size + bitmapSize);
	}
    }

    return (height);
}


/***********************************************************************
 *				OutputHeader
 ***********************************************************************
 * SYNOPSIS:	    Print out the bitmap header.
 * CALLED BY:	    (INTERNAL) ConvertFormat
 * RETURN:	    nothing
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/92	Initial Revision
 *
 ***********************************************************************/
static void
OutputHeader(IconFormat *format,
	     int         height,
	     Bitmap     *bm,
	     Icon       *icon,
	     FILE       *outf)
{
    char *bitmapStr, *packbitsStr, *formatStr,
	 *paletteStr2, *paletteStr3, *paletteStr4;

    if (flags & (CVT_UIC_MODE | CVT_ESP_MODE)) {

	if (maskout != 255 && format->bpp == 4) {
	    bitmapStr = "\t\tBitmap <%d,%d,%s,%s or mask BMT_MASK>\n";
	} else if (format->bpp != 8) {
	    bitmapStr = "\t\tBitmap <%d,%d,%s,%s>\n";
	} else { /* 8 bit color */
            if (maskout != 255) {
		if (outputCustomPalette) {
		    bitmapStr = "\t\tCBitmap <<%d,%d,%s,%s or mask BMT_MASK or mask BMT_PALETTE or mask BMT_COMPLEX>, 0, %d, 0, %d, %d, 72, 72>\n";
		} else {
		    bitmapStr = "\t\tCBitmap <<%d,%d,%s,%s or mask BMT_MASK or mask BMT_COMPLEX>, 0, %d, 0, %d, %d, 72, 72>\n";
		}
            } else {
		if (outputCustomPalette) {
		    bitmapStr = "\t\tCBitmap <<%d,%d,%s,%s or mask BMT_PALETTE or mask BMT_COMPLEX>, 0, %d, 0, %d, %d, 72, 72>\n";
		} else {
		    bitmapStr = "\t\tCBitmap <<%d,%d,%s,%s or mask BMT_COMPLEX>, 0, %d, 0, %d, %d, 72, 72>\n";
		}
            }
	    paletteStr2 = "\t\tword\t256\n";
	    paletteStr3 = "\t\tRGBValue < 0x%02x, 0x%02x, 0x%02x >\n";
	    paletteStr4 = "\n";
	}

	if (bm == &icon->compacted) {
	    if (flags & CVT_TWO_POINT_OH) {
		packbitsStr = "BMC_PACKBITS";
	    } else {
		packbitsStr = "BM_PACKBITS";
	    }
	} else {
	    packbitsStr = "0";
	}

    } else {

	if (maskout != 255 && format->bpp == 4) {
	    bitmapStr = "\t\tBitmap (%d,%d,%s,(%s|BMT_MASK)),\n";
	} else if (format->bpp != 8) {
	    bitmapStr = "\t\tBitmap (%d,%d,%s,%s),\n";
	} else { /* 8 bit color */
            if (maskout != 255) {
		if (outputCustomPalette) {
		    bitmapStr = "\t\tBitmap (%d, %d, %s,(%s | BMT_MASK | BMT_PALETTE | BMT_COMPLEX)), 0,0, %d,%d, 0,0, %d,%d, %d,%d, 72,0, 72,0,\n";
		} else {
		    bitmapStr = "\t\tBitmap (%d, %d, %s,(%s | BMT_MASK | BMT_COMPLEX)), 0,0, %d,%d, 0,0, %d,%d, %d,%d, 72,0, 72,0,\n";
		}
            } else {
		if (outputCustomPalette) {
		    bitmapStr = "\t\tBitmap (%d, %d, %s,(%s | BMT_PALETTE | BMT_COMPLEX)), 0,0, %d,%d, 0,0, %d,%d, %d,%d, 72,0, 72,0,\n";
		} else {
		    bitmapStr = "\t\tBitmap (%d, %d, %s,(%s | BMT_COMPLEX)), 0,0, %d,%d, 0,0, %d,%d, %d,%d, 72,0, 72,0,\n";
		}
            }
	    paletteStr2 = "\t\t%d,%d, /* palette length */\n";
	    paletteStr3 = "\t\t0x%02x, 0x%02x, 0x%02x,\n";
	    paletteStr4 = "";
	}

	if (bm == &icon->compacted) {
	    packbitsStr = "BMC_PACKBITS";
	} else {
	    packbitsStr = "0";
	}

    }

    switch (format->bpp) {
    case 1:
	formatStr = "BMF_MONO";
	fprintf(outf, bitmapStr, format->width,	height,	packbitsStr, formatStr);
	break;

    case 4:
	formatStr = "BMF_4BIT";
	fprintf(outf, bitmapStr, format->width,	height,	packbitsStr, formatStr);
	break;

    case 8:
    {
	int i;
	int dataOffset;
	byte *colorEntry = colorTable;

	formatStr = "BMF_8BIT";

	if (outputCustomPalette) {
	    dataOffset = 790;
	} else {
	    dataOffset = 20;
	}

	if (flags & (CVT_UIC_MODE | CVT_ESP_MODE)) {
	    fprintf(outf,
		    bitmapStr,
		    format->width, height, packbitsStr, formatStr, height, dataOffset, 20);
	} else {
	    byte heightLow      = height & 0x000000ff;
	    byte heightHigh     = (height >> 8) & 0xff;
	    byte dataOffsetLow  = dataOffset & 0x000000ff;
	    byte dataOffsetHigh = (dataOffset >> 8) & 0xff;

	    fprintf(outf,
		    bitmapStr,
		    format->width, height, packbitsStr, formatStr,
		    heightLow, heightHigh,
		    dataOffsetLow, dataOffsetHigh,
		    20, 0);
	}

	if (outputCustomPalette) {
	    fprintf(outf, paletteStr2, 256 & 0xff, (256 >> 8) & 0xff);

	    for (i = 0; i < 256; i++) {
		fprintf(outf,
			paletteStr3,
			colorEntry[0], colorEntry[1], colorEntry[2]);
		colorEntry += 3;
	    }
	    fprintf(outf, paletteStr4);
	}
	break;
    }

    default:

	fprintf(stderr,
		"unknown format depth %d bits-per-pixel\n",
		format->bpp);
	formatStr = "UNKNOWN";
	break;
    }

}


/***********************************************************************
 *				CloseChunk
 ***********************************************************************
 * SYNOPSIS:	    Put out text to close off the graphics string and
 *	    	    chunk.
 * CALLED BY:	    (INTERNAL) ConvertFormat
 * RETURN:	    nothing
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/92	Initial Revision
 *
 ***********************************************************************/
static void
CloseChunk(IconFormat *format, FILE *outf)
{
    if (!(flags & CVT_NO_GSTRING)) {
	if (!(flags & CVT_NO_BEGIN_END_STRING)) {
	    if (flags & (CVT_ESP_MODE|CVT_UIC_MODE)) {
		fputs("\t\tGSEndString\n", outf);
	    } else {
		fputs("\t\tGSEndString()\n", outf);
	    }
	}
	if (flags & CVT_NO_MONIKER) {
	    /*
	     * Just putting out graphics string, so we're done.
	     */
	    return;
	}
	/* XXX: MIGHT BE DIFFERENT FOR Esp */
	fputs("\t}\n", outf);
    }

    switch(flags & CVT_MODE_FLAGS) {
	case CVT_ESP_MODE:
	  fprintf(outf, "%s%sMoniker endc\n", mname, format->abbrev);
	  break;
	case CVT_UIC_MODE:
	  fputs("}\n", outf);
	  break;
	case CVT_GOC_MODE:
	  fputs("};\n", outf);
	  break;
    }
}


/***********************************************************************
 *				ExitResource
 ***********************************************************************
 * SYNOPSIS:	    Put out text to exit the resource appropriate to
 *		    this bitmap format.
 * CALLED BY:	    (INTERNAL) ConvertFormat
 * RETURN:	    nothing
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/92	Initial Revision
 *
 ***********************************************************************/
static void
ExitResource(IconFormat *format, FILE *outf)
{    
    if (!(flags & CVT_NO_RESOURCES)) {
	switch(flags & CVT_MODE_FLAGS) {
	case CVT_ESP_MODE:
	    fprintf(outf, "%s%sMonikerResource ends\n",
		    rname, format->abbrev);
	    break;
	case CVT_GOC_MODE:
	    fprintf(outf, "@end %s%sMONIKERRESOURCE;\n",
		    UpCase(rname), UpCase(format->abbrev));
	    break;
	case CVT_UIC_MODE:
	    fprintf(outf, "end %s%sMonikerResource;\n",
		    rname, format->abbrev);
	    break;
	}
    }
}

/***********************************************************************
 *				ConvertFormat
 ***********************************************************************
 * SYNOPSIS:	    Convert an icon format from PCX to ours.
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    stuff is written to the output file.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/11/92	Initial Revision
 *
 ***********************************************************************/
static void
ConvertFormat(FILE  	 *stream,  /* Input stream, positioned at start of
				    * image data */
	      FILE  	 *outf,    /* Output stream */
	      int   	  xoffset, /* X offset of start of image data
				    * to convert */
	      int   	  yoffset, /* Y offset of start of image data
				    * to convert */
	      IconFormat *format)  /* Format of result */
{
    Icon    	*icon;
    int	    	size;
    Bitmap  	*bm;
    int	    	height;		/* Actual height, after adjusting for
				 * negative y offset and our ability to
				 * use GSRelMoveTo or what have you */

    /*
     * Convert the thing from the file, as we need the size in the
     * prologue...
     */
    if (bitsPerPCXPixel < 8) {
	icon = readega(stream, format, xoffset, yoffset);
    } else {
	icon = readvga(stream, format, xoffset, yoffset);
    }

    /*
     * If we're allowed to compact and the compacted bitmap is actually
     * valid (i.e. it didn't overflow the size allocated for the uncompacted
     * version), use it. Else use the uncompacted form.
     */
    if ((flags & CVT_NO_COMPACT) || !icon->cvalid ||
	(icon->compacted.next - icon->compacted.data >=
	 icon->uncompacted.next - icon->uncompacted.data))
    {
	bm = &icon->uncompacted;
    } else {
	bm = &icon->compacted;
    }

    /*
     * Figure how many bytes that is.
     */
    size = bm->next - bm->data;
    
    
    /*
     * Put out commentary saying where the thing came from.
     */
    OutputCommentary(format, outf);

    /*
     * If necessary, put out text to enter the proper resource.
     */
    EnterResource(format, outf);

    /*
     * Now open the chunk.
     */
    height = OpenChunk(format, yoffset, size, outf);

    /*
     * Now put out the bitmap header itself.
     */
    OutputHeader(format, height, bm, icon, outf);

    /*
     * Now spit out the bitmap bytes themselves.
     */
    BitmapSpew(bm, outf);

    /*
     * Close off the chunk appropriately.
     */
    CloseChunk(format, outf);

    /*
     * Exit the resource, if necessary.
     */
    ExitResource(format, outf);

    free(icon);
}

volatile void
usage(void)
{
    fprintf(stderr, "\
We accept as many arguments as desired, with the conversion parameters being\n\
specified before any file to be converted. \n\
\n\
cvtpcx can be used to convert a single icon, or a predefined grid of icons\n\
in predefined formats. 11 formats and 3 grids are currently defined. Each\n\
format is known by its abbreviation, which is used for the -d option (see\n\
below), forming the name of the moniker produced for a particular grid\n\
position, and forming the name of the resource in which the moniker is\n\
placed.\n\
\n\
The defined formats are:\n\
    Abbr  Color  Aspect        Size      Style  Width  Height\n\
    ----  -----	 ------------  --------	 -----	-----  ------\n\
    LC    4-bit  normal        large	 icon	 64      40\n\
    LM    Mono	 normal        large	 icon	 64      40\n\
    SC    4-bit	 normal	       standard	 icon	 48	 30\n\
    SM    Mono	 normal	       standard	 icon	 48	 30\n\
    LCGA  Mono	 verySquished  large	 icon	 64	 18\n\
    SCGA  Mono	 verySquished  tiny	 icon	 48	 14\n\
    YC	  4-bit	 normal	       tiny	 icon	 32	 20\n\
    YM	  Mono	 normal	       tiny	 icon	 32	 20\n\
    TC	  4-bit	 normal	       tiny	 tool	 15	 15\n\
    TM	  Mono	 normal	       tiny	 tool	 15	 15\n\
    TCGA  Mono   verySquished  tiny	 tool	 15	 10\n\
\n\
The grids are sequences of these formats laid out with a common top edge,\n\
from left to right, and a one pixel margin between each pair of icons, and\n\
around the grid as a whole. Three grids exist, currently. They are:\n\
    Flag    Formats\n\
    ----    --------------------------------------------------\n\
    -l	    LC, LM, SC, SM, LCGA, SCGA\n\
    -L	    LC, LM, SC, SM, LCGA, SCGA, YC, YM, TM, TCGA\n\
	    (the YC and YM icons are used for application icons on\n\
	    handheld devices, while the TM and TCGA icons are used\n\
	    for the Presentation Manager system menu)\n\
    -z	    TC, TM, TCGA\n\
\n\
The following parameters are useful for both grid and non-grid conversions:\n\
    -G                  Produce goc output instead of uic \n\
\n");
    fprintf(stderr, "\
    -g			Do not put resulting bitmaps in gstrings. The bitmap\n\
			is still in a chunk, but no gstring opcodes surround\n\
			it.\n\
\n\
    -j			Only output the gstring (don't create a moniker or\n\
			put the gstring in a chunk)\n\
\n\
    -2			Use 2.0 constants in the resulting gstring/bitmap.\n\
\n\
    -f			Uses GrFillBitmap instead of GrDrawBitmap for all\n\
			monochrome bitmaps.  Also implies the use of 2.0\n\
			constants, since this will not work prior to\n\
			version 2.0 as GrFillBitmap didn't exist.\n\
\n\
    -t      		Causes the bitmap to be drawn relative to the\n\
			current pen position if the program decides to\n\
			optimize the moniker by drawing the bitmap somewhere\n\
			other than 0,0. All monikers destined for the\n\
			token database should be created with this flag.\n\
\n\
    -u	    	    	Insist the resulting bitmaps remain uncompacted. By\n\
			default, cvtpcx will determine if it's worthwhile and\n\
			automatically compact each bitmap for you.\n\
\n\
    -o<filename>	Specify where the moniker(s) should be placed.\n\
\n\
The following parameters are useful when converting things by grid:\n\
    -m<pixel>   	Pixel to be masked out. Any pixel containing this\n\
			color (a decimal number) will be given a 0 bit in\n\
			the mask for the color bitmap. Defaults to none.\n\
\n\
    -x<xoffset> 	Specifies the left edge of the grid (the X coord-\n\
			inate of the 1-pixel margin to the left of the left-\n\
			most icon in the grid.)\n\
\n\
    -y<yoffset> 	Specifies the top edge of the grid (the X coord-\n\
			inate of the 1-pixel margin to the left of the left-\n\
			most icon in the grid.)\n\
\n\
    -n<moniker name>	Allows specifying the core name to give the moniker.\n\
			The name for each moniker in a grid is formed thus:\n\
			    <moniker name><format abbrev>Moniker\n\
			For instance -nHello would create \"HelloLCMoniker\"\n\
			for the leftmost icon in the \"-l\" grid.\n\
			\n\
			In addition, if no output file is specified (using\n\
			the \"-o\" option), the output file becomes\n\
			    mkr<moniker name>.<extension>\n\
\n");
    fprintf(stderr, "\
    -d<format(s)>	Argument is a comma-separated list of one or more\n\
			format abbreviations, indicating the grid doesn't\n\
			contain an icon in that format, so no moniker should\n\
			be produced for it.\n\
\n\
    -r<resource>    	Specifies the string (other than the default \"App\")\n\
			to begin the name of each resource. The resource\n\
			names are of the form\n\
			    <resource><format abbrev>MonikerResource\n\
			(this is all uppercase for GOC output).\n\
\n\
    -R	    	    	Don't put out resource start/end directives; just\n\
			produce the monikers, one after another.\n\
\n\
When converting a single icon, no start/end resource directives are\n\
produced. The -n option may still be used to name the moniker, but no\n\
format abbreviation will appear between the <moniker name> and \"Moniker\".\n\
The following parameters are useful only for converting single icons:\n\
    -w<width>   	width of resulting bitmap (input will be trimmed\n\
			or extended (but masked) as necessary to accomodate\n\
			this).Defaults to Standard size (48)\n\
\n\
    -h<height>  	height of resulting bitmap (input will be trimmed\n\
			or extended (masked) as necessary to accomodate\n\
			this)...Defaults to Standard size (30)\n\
\n\
    -S<style>		<style> is one of the defined moniker styles: text,\n\
			abbrevText, graphicText, icon, or tool. It defaults to\n\
			icon. (The \"-S\" option is only for 2.0 and above.)\n\
\n\
    -s<size>    	<size> is one of the defined moniker sizes: large,\n\
			standard, or tiny. It defaults to standard\n\
\n\
    -a<aspect>  	<aspect> is one of the defined aspectRatio values:\n\
			normal (vga), squished (ega) or verySquished (cga).\n\
			Defaults to squished.\n\
\n\
    -b      		Forces creation of a single bitplane (B&W) icon,\n\
			even if the source is 16 colors. Any pixel that isn't\n\
			black (pixel 0) is set to 0 in the resulting bitmap.\n\
			Black pixels are, of course, set to 1.\n\
\n\
    -B			Similar, but any pixel that isn't white (pixel 15)\n\
			or the mask (set by \"-m\") is set to 1.\n\
\n\
    -N	    	    	map the colors to the indices for the Nokia device\n\
\n\
\n");
    fprintf(stderr, 
	    "Once given, these parameters apply to all subsequent files, "
	    "unless they\nare given again.\n");
    exit(1);
}


/***********************************************************************
 *				main
 ***********************************************************************
 * SYNOPSIS:	    This is a program for converting PC-Paintbrush
 *	    	    cutouts that contain icons into uic moniker snippets
 *	    	    for use in PC/GEOS.
 *
 *	    	    We accept as many arguments as desired, with the
 *	    	    conversion parameters being specified before any
 *	    	    file to be converted. The available parameters and
 *	    	    their defaults are listed in the help text in
 *		    usage(), above.
 *
 *	    	    Each file <file>.pcx is written to <file>.ui when
 *	    	    the conversion is complete. The name may be overridden
 *	    	    by preceding it with a "-o<outfile>" argument. The moniker
 *	    	    is named <file>Moniker, unless the -o argument is given,
 *	    	    in which case the moniker is named <outfileRoot>Moniker,
 *	    	    where <outfileRoot> is all characters in <outfile> up to
 *	    	    the first period.
 *	    	    	
 * CALLED BY:	    User
 * RETURN:	    0, unless the user screwed up
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 6/90		Initial Revision
 *
 ***********************************************************************/
void
main(int argc, char **argv)
{
    int	    	ac;
    int	    	xoffset = 0;
    int	    	yoffset = 0;
    char    	*ofile = NULL;
    char	*outname;
    FILE	*outf;
    char    	*cp;
    static IconFormat	format = {
	"",
	0,
	"normal",
	"standard",
	"icon",
	STANDARD_ICON_WIDTH,
	STANDARD_ICON_HEIGHT,
	FALSE
    };
    GridElement	*grid = NULL;
    int	    	gridlen = 0;

    if (argc == 1) {
	usage();
    }

    for (ac = 1; ac < argc; ac++) {
	if (argv[ac][0] == '-') {
	    switch(argv[ac][1]) {
	    case 't':
		flags |= CVT_TOKEN_MODE;
		break;
	    case 'm':
		maskout = atoi(&argv[ac][2]);
		break;
	    case 'w':
		format.width = atoi(&argv[ac][2]);
		break;
	    case 'h':
		format.height = atoi(&argv[ac][2]);
		break;
	    case 'x':
		xoffset = atoi(&argv[ac][2]);
		break;
	    case 'y':
		yoffset = atoi(&argv[ac][2]);
		break;
	    case 'g':
		flags |= CVT_NO_GSTRING|CVT_NO_MONIKER;
		break;
	    case 'j':
		flags |= (CVT_NO_MONIKER|CVT_NO_BEGIN_END_STRING);
		break;
	    case 's':
		format.size = &argv[ac][2];
		break;
	    case 'S':
		format.style = &argv[ac][2];
		break;
	    case 'a':
		format.aspect = &argv[ac][2];
		break;
	    case 'o':
		ofile = &argv[ac][2];
		break;
	    case 'n':
		mname = &argv[ac][2];
		break;
	    case 'R':
		flags |= CVT_NO_RESOURCES;
		break;
	    case 'r':
		rname = &argv[ac][2];
		break;
	    case 'b':
		format.bpp = 1;
		flags |= CVT_FORCE_MONO;
		break;
	    case 'B':
		format.bpp = 1;
		flags |= CVT_FORCE_INVERSE_MONO;
		break;
	    case 'l':
		grid = standardGrid;
		gridlen = sizeof(standardGrid)/sizeof(standardGrid[0]);
		break;
	    case 'L':
		grid = fullGrid;
		gridlen = sizeof(fullGrid)/sizeof(fullGrid[0]);
		break;
	    case 'z':
		grid = toolGrid;
		gridlen = sizeof(toolGrid)/sizeof(toolGrid[0]);
		break;
	    case 'u':
		flags |= CVT_NO_COMPACT;
		break;
	    case 'f':
		flags |= CVT_USE_FILL_BITMAP|CVT_TWO_POINT_OH;
		break;
	    case 'd':
	    {
		int	    	i;
		char    	*abbrev;
		
		for (abbrev = &argv[ac][2]; *abbrev != '\0'; abbrev=cp) {
		    /*
		     * Find the next format abbreviation in the argument (up
		     * to a comma or null byte)
		     */
		    cp = index(abbrev, ',');
		    if (cp != NULL) {
			*cp++ = '\0';
		    } else {
			cp = abbrev + strlen(abbrev);
		    }
		    
		    /*
		     * Look for that format in the list of all known formats.
		     */
		    for (i = (sizeof(allFormats)/sizeof(allFormats[0]))-1;
			 i >= 0 ;
			 i--)
		    {
			if (!strcmp(abbrev, allFormats[i]->abbrev)) {
			    /*
			     * Found it. Should it appear in the grid we
			     * use, ignore it.
			     */
			    allFormats[i]->ignore = TRUE;
			    break;
			}
		    }
		    if (i < 0) {
			fprintf(stderr,
				"format %s unknown -- -d%s ignored\n",
				abbrev, abbrev);
		    }
		}
		break;
	    }
	    case '2':
		flags |= CVT_TWO_POINT_OH;
		break;
	    case 'G':
		flags |= CVT_GOC_MODE;
		flags &= ~(CVT_ESP_MODE|CVT_UIC_MODE);
		break;
	    case 'E':
		flags |= CVT_ESP_MODE;
		flags &= ~(CVT_GOC_MODE|CVT_UIC_MODE);
		break;
	    case 'N':
		mapColorsForResponder = TRUE;
		break;
	    default:
		fprintf(stderr, "option %s unknown\n", argv[ac]);
		usage();
	    }
	} else {
	    /*
	     * Must be a file for us to convert...
	     */
	    FILE    *stream = fopen(argv[ac], "rb");

	    if (stream == NULL) {
		perror(argv[ac]);
		continue;
	    }

	    inname = argv[ac];
	    
	    /*
	     * ERROR-CHECKING
	     */
	    if (grid == NULL) {
		if (-xoffset > format.width) {
		    fprintf(stderr,
			    "What is the point of producing a completely blank "
			    "moniker?\nxoffset is %d, but the moniker width is "
			    "%d.\nIf you're not going to play fair, I'm just "
			    "going to go home!\n",
			    xoffset,
			    format.width);
		    exit(1);
		}
	    
		if (-yoffset > format.height) {
		    fprintf(stderr,
			    "What is the point of producing a completely blank "
			    "moniker?\nyoffset is %d, but the moniker height "
			    "is %d.\nIf you're not going to play fair, I'm "
			    "just going to go home!\n",
			    yoffset,
			    format.width);
		    exit(1);
		}
		flags |= CVT_NO_RESOURCES;
	    }

	    
	    /*
	     * Read in the header and make sure it makes sense.
	     */
	    if (fread(&header, sizeof(header), 1, stream) != 1) {
		fprintf(stderr, "no header on %s\n", argv[ac]);
	    file_err:
		(void)fclose(stream);
		continue;
	    } else if (header.PCXH_id != 10) {
		fprintf(stderr, "header id wrong for %s\n", argv[ac]);
		goto file_err;
	    } else if (header.PCXH_planes != 4 &&
		       header.PCXH_planes * header.PCXH_bitsPerPixel != 8)
	    {
		fprintf(stderr,
			"Only able to convert 4-bit color or 8-bit color "
			"bitmaps at this time. Sorry.\n");
		goto file_err;
	    }
	    
	    cp = index(argv[ac], '.');

	    /*
	     * Figure output file and moniker name
	     */
	    if (ofile == NULL) {
		/* IF no output file was passed, but a moniker name WAS,
		 * then send output to a file with name:
		 * mkr<mname>.ui 				*/
		if (mname != NULL) {
		    outname = (char *)malloc(strlen(mname) + 10);
		    sprintf(outname, "mkr%s.%s", mname,FILE_SUFFIX);
		} else {
		    if (cp == NULL) {
			cp = argv[ac] + strlen(argv[ac]);
		    }
		    outname = (char *)malloc(cp-argv[ac] + 10);
		    sprintf(outname, "%.*s.%s", cp-argv[ac], argv[ac],
			    FILE_SUFFIX);
		    /*
		     * Define the moniker name while we're at it
		     */
		    mname = (char *)malloc(cp-argv[ac]);
		    sprintf(mname, "%.*s", cp-argv[ac], argv[ac]);
		}
	    } else {
		outname = ofile;
	    }
	    outf = fopen(outname, "wb");   /* for writing out */

	    if (outf == NULL) {
		perror(outname);
		goto file_err;
	    }
	    fprintf(stderr, "Input parameters for %s:\n", argv[ac]);
	    fprintf(stderr,
		    "\t%d bits per pixel, %d planes, %d bytes per plane\n",
		    header.PCXH_bitsPerPixel, header.PCXH_planes,
		    swaps(header.PCXH_bytesPerPlane));
	    fprintf(stderr,
		    "\t(%d, %d) to (%d, %d): width = %d, height = %d\n",
		    swaps(header.PCXH_upLeftX),
		    swaps(header.PCXH_upLeftY),
		    swaps(header.PCXH_lowRightX),
		    swaps(header.PCXH_lowRightY),
		    abs(swaps(header.PCXH_lowRightX) -
			swaps(header.PCXH_upLeftX)),
		    abs(swaps(header.PCXH_lowRightY) -
			swaps(header.PCXH_upLeftY))
		    );
	    fprintf(stderr, "\txRes = %d, yRes = %d\n",
		    swaps(header.PCXH_dispXRes),
		    swaps(header.PCXH_dispYRes));

	    bitsPerPCXPixel = header.PCXH_planes * header.PCXH_bitsPerPixel;

	    if (grid != NULL) {
		int 	i;

		for (i = 0; i < gridlen; i++) {
		    if (grid[i].format->bpp == 0) {
			grid[i].format->bpp = header.PCXH_planes *
			                     header.PCXH_bitsPerPixel;
		    }
		    if (!(grid[i].format->ignore)) {
			/*
			 * Format not being ignored, so convert it.
			 */
			ConvertFormat(stream, outf,
				      xoffset + grid[i].xOffset,
				      yoffset + grid[i].yOffset,
				      grid[i].format);
			/*
			 * Rewind the input file to the start of the image
			 * data again.
			 */
			fseek(stream, sizeof(PCXHeader), SEEK_SET);
		    }
		}
	    } else {
		/*
		 * Convert the format whose parameters we built in our
		 * local variable. The CVT_NO_RESOURCES flag is set, so
		 * we can just do this...
		 */
		if (format.bpp == 0) {
		    format.bpp = header.PCXH_planes * header.PCXH_bitsPerPixel;
		}
		ConvertFormat(stream, outf, xoffset, yoffset, &format);
	    }
	    
	    fclose(outf);
	    
	    if (!ofile) {
		free(outname);
	    } else {
		ofile = NULL;
		mname = NULL;
	    }
	    fclose(stream);
	}
    }

    exit(0);
}
