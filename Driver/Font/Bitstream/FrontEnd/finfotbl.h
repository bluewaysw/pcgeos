/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	FrontEnd/finfotbl.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: finfotbl.h,v 1.1 97/04/18 11:45:07 newdeal Exp $
 *
 ***********************************************************************/

/***********************************************************************************************
	FILE:		FINFOTBL.H
***********************************************************************************************/
#ifdef HAVE_STICK_FONT
#define N_LOGICAL_FONTS	126
#else
#define N_LOGICAL_FONTS	126
#endif
#define NULLCHARPTR	(char *)0
#define NEXT_NONE	0x0100
#define NEXT_ABSTARG	0x0200
#define	NEXT_RELTARG	0x0400

#define BUCKET			(NEXT_ABSTARG|0x0000)
#define SERIF			(NEXT_ABSTARG|0X0001)
#define SERIF_BOLD		(NEXT_ABSTARG|0x0002)
#define SANS			(NEXT_ABSTARG|0x0003)
#define SANS_BOLD		(NEXT_ABSTARG|0x0004)
#define STICK			(NEXT_ABSTARG|0x0005)


#define UP_ONE			(NEXT_RELTARG|0x00ff)
#define UP_TWO			(NEXT_RELTARG|0x00fe)
#define UP_THREE		(NEXT_RELTARG|0x00fd)
#define UP_FOUR			(NEXT_RELTARG|0x00fc)
#define UP_FIVE			(NEXT_RELTARG|0x00fb)
#define DOWN_ONE		(NEXT_RELTARG|0x0001)
#define DOWN_TWO		(NEXT_RELTARG|0x0002)
#define DOWN_THREE		(NEXT_RELTARG|0x0003)
#define DOWN_FOUR		(NEXT_RELTARG|0x0004)
#define DOWN_FIVE		(NEXT_RELTARG|0x0005)

#define NEXT_UNKNOWN	NEXT_NONE


enum {pdlPCL=128, pdlPostScript, pdlGDI, pdlSupport};

typedef struct VFNT_HEAD  /* Logical font header */
{
ufix16  size;             /* always 88 */
ufix8   format,           /* always 12 */
        font_type;        /* 0=7-bit,1=8-bit,2=PC-8,10=unbound scalable */
ufix16  style_msb,        /* high byte of style word */
        baseline,         /* top of em to baseline, PCPU */
        cell_width,       /* PCPU */
        cell_height;      /* PCPU */
ufix8   orient;           /* always 0 */
boolean spacing;          /* 0 = fixed, 1 = proportional */
ufix16  symbol_set,       /* HP symbol set (always 0)*/
        pitch,            /* default HMI for monospace, PCPU. 
                             0 if proportional font */
        height,           /* always 192 */
        x_height;         /* height of lowercase x from baseline, PCPU */
fix7    width_type;       /* -2 condensed to +2 expanded */
ufix8   style_lsb;        /* 0 upright, 1 italic */
fix7    stroke_weight;    /* -7 to 7, 0 being normal */
ufix8   typeface_lsb,     /* bitsid from tdf */
        typeface_msb,     /* always 0 */
        serif_style;      /* same as cvthpf uses */
ufix8   quality;          /* font quality */
fix7    placement;        /* placement of chars relative to baseline */
fix7    uline_dist;       /* baseline to center of underline, PCPU/4 ?? */
ufix8   old_uline_height; /* thickness of underline, PCPU */
ufix16  reserved1,        /* reserved */
        reserved2,        /* reserved */
        reserved3,        /* reserved */
        num_outlines;     /* number of outlines to download (unused) */
ufix8   pitch_ext,        /* extended 8 bits for pitch field */
        height_ext;       /* extended 8 bits for height field */
ufix16  cap_height;       /* distance from capline to the baseline */
ufix32  font_number;      /* vendor-assigned font number */
char    font_name[16];    /* font name string */
ufix16  scale_factor,     /* scale factor in design window units */
        master_x_res,     /* horizontal pixel resolution */
        master_y_res;     /* vertical pixel resolution */
fix15   uline_pos;        /* position of underline */
ufix16  uline_height,     /* thickness of underline */
        lre_thresh,       /* low resolution enhancement threshold */
        italic_angle;     /* tangent of italic angle times 2**15 */
ufix32  char_complement_msw, /* character complement MSW */
        char_complement_lsw; /* character complement LSW */	
ufix16  data_size;        /* not used */
} pclHdrType;


typedef struct
{
char	    stringName[48];        /* font alias name */
pclHdrType  pclHdrInfo;        /* attribute/metric info about font in PCL Intellifont format */
ufix8       pdlType;           /* font emulation type (pdlPCL ... pdlSupport) */
char        *addr;             /* to be filled in after font is loaded or ROM burned */
ufix16      nextSearchEncode;   /* hi,lo byte encoded indicator of next index */
}FontInfoType;
