/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/tt_specs.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: tt_specs.c,v 1.1 97/04/18 11:45:25 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TTSpecsCode")

/*************************** tt_specs.c   *********************************
 *                                                                           *
 *  set speedo_globals variables used by scan conversion
 *                                                                           */
/********************* Revision Control Information **********************************
*                                                                                    *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/tt_specs.c,v 1.1 97/04/18 11:45:25 newdeal Exp $                                                                       *
*                                                                                    *
*     $Log:	tt_specs.c,v $
 * Revision 1.1  97/04/18  11:45:25  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:59  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:16:59  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:24:31  roberte
 * Release
 * 
 * Revision 6.10  93/02/01  09:05:23  roberte
 * Un-#ifdef'ed SPEEDO_GLOBAL declaration.
 * Oops!
 * 
 * Revision 6.9  93/01/29  16:02:56  roberte
 * #ifdef'd out SPEEDO_GLOBALS declaration.
 * 
 * Revision 6.8  93/01/26  13:39:44  roberte
 * Added PARAMS1 and PARAMS2 macros to all reentrant function calls and definitions.
 * 
 * Revision 6.7  93/01/22  15:55:15  roberte
 * Commented out 2 unreferenced varibles.
 * 
 * Revision 6.6  93/01/05  14:21:58  roberte
 * Changed all report_error to sp_report_error calls.
 * 
 * Revision 6.5  92/12/29  12:48:14  roberte
 * Now includes "spdo_prv.h" first.
 * 
 * Revision 6.4  92/11/24  13:34:26  laurar
 * include fino.h
 * 
 * Revision 6.3  92/11/19  16:11:06  roberte
 * Release
 * 
 * Revision 6.1  91/08/14  16:49:32  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:30:37  mark
 * Release
 * 
 * Revision 4.2  91/08/07  12:02:10  mark
 * add rcs control strings
 * 
*************************************************************************************/

#ifdef RCSSTATUS
static char rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/tt_specs.c,v 1.1 97/04/18 11:45:25 newdeal Exp $";
#endif

#include "spdo_prv.h"
#include "fino.h"
#include "fscdefs.h"
#undef boolean
#include "fontscal.h"
#include "truetype.h"

#define  DEBUG       0
#define  FUNCTION
#define  PIXMAX      3          /* maximum pixel deviation from linear scaling */
                                /* 3 seems like a reasonable guess */

/*SPEEDO_GLOBALS  sp_globals;*/

#if DEBUG
#include <stdio.h>
#define SHOW(X) printf("X = %d\n", X)
#else
#define SHOW(X)
#endif

boolean tt_set_spglob PROTO((PROTO_DECL2 specs_t *specsarg,fix15 font_xmin,fix15 font_ymin,fix15 font_xmax,fix15 font_ymax,fix15 orupm));
boolean tt_setup_consts PROTO((PROTO_DECL2 fix15 xmin,fix15 xmax,fix15 ymin,fix15 ymax));
void tt_setup_tcb PROTO((PROTO_DECL2 tcb_t GLOBALFAR *ptcb));
static fix15 tt_setup_mult PROTO((PROTO_DECL2 fix31 input_mult));
static fix31 tt_setup_offset PROTO((PROTO_DECL2 fix31 input_offset));
void tt_type_tcb PROTO((PROTO_DECL2 tcb_t GLOBALFAR *ptcb));



FUNCTION boolean tt_set_spglob(PARAMS2 specsarg, font_xmin, font_ymin,
                                font_xmax, font_ymax, orupm)

  GDECL
  specs_t *specsarg;            /* Bundle of conversion specifications */
  fix15    font_xmin;           /* Minimum X ORU value in font */
  fix15    font_ymin;           /* Minimum Y ORU value in font */
  fix15    font_xmax;           /* Maximum X ORU value in font */
  fix15    font_ymax;           /* Maximum Y ORU value in font */
  fix15    orupm;               /* orus per em */
/* 
 * Called by host software to set character generation specifications
 */
{
/* ufix16  mask1, mask2; */

/* Flags: BOGUS_MODE and CONSTR_OFF must be set
 *        IMPORT_WIDTHS, SQUEEZE_xxxx, and CLIP_xxxx must all be 0. */
/* mask1 = (BOGUS_MODE | CONSTR_OFF);
/* mask2 = (IMPORT_WIDTHS | SQUEEZE_LEFT | SQUEEZE_RIGHT | SQUEEZE_TOP | SQUEEZE_BOTTOM |
/*          CLIP_LEFT | CLIP_RIGHT | CLIP_TOP | CLIP_BOTTOM);
/* if (((specsarg->flags & mask1) != mask1)  ||  (specsarg->flags & mask2))
/*     {
/*     sp_report_error(PARAMS2 999);               /* Unsupported mode requested */
/*     return FALSE;                       /* Illegal flags */
/*     }
*/
sp_globals.specs = *specsarg;           /* copy specs structure into sp_globals */
sp_globals.pspecs = &sp_globals.specs;
sp_globals.orus_per_em = orupm;
if (!tt_setup_consts(PARAMS2 font_xmin, font_xmax, font_ymin, font_ymax))
    {
    sp_report_error(PARAMS2 3);                 /* Requested specs out of range */
    return FALSE;
    }

/* Setup transformation control block */
tt_setup_tcb(PARAMS2 &sp_globals.tcb0);

/* TrueType curve direction is opposite to that of Speedo's */
sp_globals.tcb0.mirror = -sp_globals.tcb0.mirror;

sp_globals.tcb = sp_globals.tcb0;

/* Select output module */
sp_globals.output_mode = sp_globals.pspecs->flags & 0x0007;

#if INCL_USEROUT
if (!init_userout(sp_globals.pspecs))
#endif

sp_globals.curves_out = sp_globals.pspecs->flags & CURVES_OUT;
sp_globals.tcb0.xtype = sp_globals.tcb0.ytype = 4;

#if INCL_APPLESCAN
if (sp_globals.output_mode == MODE_APPLE)
	return TRUE;
#endif

switch (sp_globals.output_mode)
    {
#if INCL_BLACK
case MODE_BLACK:                        /* Output mode Black writer */
    sp_globals.init_out         = sp_init_black;
    sp_globals.begin_char       = sp_begin_char_black;
    sp_globals.begin_sub_char   = sp_begin_sub_char_out;
    sp_globals.begin_contour    = sp_begin_contour_black;
    sp_globals.curve            = sp_curve_out;
    sp_globals.line             = sp_line_black;
    sp_globals.end_contour      = sp_end_contour_out;
    sp_globals.end_sub_char     = sp_end_sub_char_out;
    sp_globals.end_char         = sp_end_char_black;
    break;
#endif

#if INCL_SCREEN
case MODE_SCREEN:                       /* Output mode Screen writer */
    sp_globals.init_out         = sp_init_screen;
    sp_globals.begin_char       = sp_begin_char_screen;
    sp_globals.begin_sub_char   = sp_begin_sub_char_out;
    sp_globals.begin_contour    = sp_begin_contour_screen;
    sp_globals.curve            = sp_curve_screen;
    sp_globals.line             = sp_line_screen;
    sp_globals.end_contour      = sp_end_contour_screen;
    sp_globals.end_sub_char     = sp_end_sub_char_out;
    sp_globals.end_char         = sp_end_char_screen;
    break;
#endif

#if INCL_OUTLINE
case MODE_OUTLINE:                      /* Output mode Vector */
    sp_globals.init_out         = sp_init_outline;
    sp_globals.begin_char       = sp_begin_char_outline;
    sp_globals.begin_sub_char   = sp_begin_sub_char_outline;
    sp_globals.begin_contour    = sp_begin_contour_outline;
    sp_globals.curve            = sp_curve_outline;
    sp_globals.line             = sp_line_outline;
    sp_globals.end_contour      = sp_end_contour_outline;
    sp_globals.end_sub_char     = sp_end_sub_char_outline;
    sp_globals.end_char         = sp_end_char_outline;
    break;
#endif

#if INCL_2D
case MODE_2D:                           /* Output mode 2d */
    sp_globals.init_out         = sp_init_2d;
    sp_globals.begin_char       = sp_begin_char_2d;
    sp_globals.begin_sub_char   = sp_begin_sub_char_out;
    sp_globals.begin_contour    = sp_begin_contour_2d;
    sp_globals.curve            = sp_curve_out;
    sp_globals.line             = sp_line_2d;
    sp_globals.end_contour      = sp_end_contour_out;
    sp_globals.end_sub_char     = sp_end_sub_char_out;
    sp_globals.end_char         = sp_end_char_2d;
    break;
#endif

#if INCL_WHITE
case MODE_WHITE:                        /* Output mode White writer */
    sp_globals.init_out         = sp_init_white;
    sp_globals.begin_char       = sp_begin_char_white;
    sp_globals.begin_sub_char   = sp_begin_sub_char_out;
    sp_globals.begin_contour    = sp_begin_contour_white;
    sp_globals.curve            = sp_curve_out;
    sp_globals.line             = sp_line_white;
    sp_globals.end_contour      = sp_end_contour_white;
    sp_globals.end_sub_char     = sp_end_sub_char_out;
    sp_globals.end_char         = sp_end_char_white;
    break;
#endif

default:
    sp_report_error(PARAMS2 8);                 /* Unsupported mode requested */
    return FALSE;
    }

if (!fn_init_out(sp_globals.pspecs))
    {
    sp_report_error(PARAMS2 5);
    return FALSE;
    }

return TRUE;
}


FUNCTION boolean tt_setup_consts(PARAMS2 xmin, xmax, ymin, ymax)
GDECL
fix15   xmin;          /* Minimum X ORU value in font */
fix15   xmax;          /* Maximum X ORU value in font */
fix15   ymin;          /* Minimum Y ORU value in font */
fix15   ymax;          /* Maximum Y ORU value in font */
/*
 * Sets the following constants used for fixed point arithmetic:
 ***    sp_globals.multshift    multipliers and products; range is 14 to 8
 ***    sp_globals.pixshift     pixels: range is 0 to 8
 *      sp_globals.mpshift      shift from product to sub-pixels (sp_globals.multshift - sp_globals.pixshift)
 *      sp_globals.multrnd      rounding for products
 ***    sp_globals.pixrnd       rounding for pixels
 ***    sp_globals.mprnd        rounding for sub-pixels
 ***    sp_globals.onepix       1 pixel in shifted pixel units
 *      sp_globals.pixfix       mask to eliminate fractional bits of shifted pixels
 *      sp_globals.depth_adj    curve splitting depth adjustment
 * Returns FALSE if specs are out of range
 */
{
fix31   mult;          /* Successive multiplier values */
ufix32  num;           /* Numerator of largest multiplier value */
ufix32  numcopy;       /* Copy of numerator */
ufix32  denom;         /* Denominator of largest multiplier value */
/*ufix32  denomcopy;     /* Copy of denominator */
ufix32  pix_max;       /* Maximum pixel rounding error */
fix31   xmult;         /* Coefficient of X oru value in transformation */
fix31   ymult;         /* Coefficient of Y oru value in transformation */
fix31   offset;        /* Constant in transformation */
fix15   i;             /* Loop counter */
fix15   x, y;          /* Successive corners of bounding box in ORUs */
fix31   pixval;        /* Successive pixel values multiplied by orus per em */
fix15   xx, yy;        /* Bounding box corner that produces max pixel value */

/* Determine numerator and denominator of largest multiplier value */
mult = sp_globals.pspecs->xxmult >> 16;
if (mult < 0)
    mult = -mult;
num = mult;

mult = sp_globals.pspecs->xymult >> 16;
if (mult < 0)
    mult = -mult;
if (mult > num)
    num = mult;

mult = sp_globals.pspecs->yxmult >> 16;
if (mult < 0)
    mult = -mult;
if (mult > num)
    num = mult;

mult = sp_globals.pspecs->yymult >> 16;
if (mult < 0)
    mult = -mult;
if (mult > num)
    num = mult;
num++;                 /* Max absolute pixels per em (rounded up) */
denom = (ufix32)sp_globals.orus_per_em;

/* Set multiplier shift to accomodate largest multiplier value */
sp_globals.multshift = 14;            
numcopy = num;
while (numcopy >= denom)     /* More than 1, 2, 4, ... pix per oru? */
    {
    numcopy >>= 1;
    sp_globals.multshift--; /* sp_globals.multshift is 13, 12, 11, ... */
    }

sp_globals.multrnd = ((fix31)1 << sp_globals.multshift) >> 1;
SHOW(sp_globals.multshift);

pix_max = PIXMAX;                       /* max pixel deviation from linear scaling */

num = 0;
xmult = ((sp_globals.pspecs->xxmult >> 16) + 1) >> 1;
ymult = ((sp_globals.pspecs->xymult >> 16) + 1) >> 1;
offset = ((sp_globals.pspecs->xoffset >> 16) + 1) >> 1;
for (i = 0; i < 8; i++)
    {
    if (i == 4)
        {
        xmult = ((sp_globals.pspecs->yxmult >> 16) + 1) >> 1;
        ymult = ((sp_globals.pspecs->yymult >> 16) + 1) >> 1;
        offset = ((sp_globals.pspecs->yoffset >> 16) + 1) >> 1;
        }
    x = (i & BIT1)? xmin: xmax;
    y = (i & BIT0)? ymin: ymax;
    pixval = (fix31)x * xmult + (fix31)y * ymult + offset * denom;
    if (pixval < 0)
        pixval = -pixval;
    if (pixval > num)
        {
        num = pixval;
        xx = x;
        yy = y;
        }
    }
if (xx < 0)
    xx = -xx;
if (yy < 0)
    yy = -yy;
num += xx + yy + ((pix_max + 2) * denom); 
                                  /* Allow (with 2:1 safety margin) for 1 pixel rounding errors in */
                                  /* xmult, ymult and offset values, pix_max pixel expansion */
                                  /* due to intelligent scaling, and */
                                  /* 1 pixel rounding of overall character position */
denom = denom << 14;              /* Note num is in units of half pixels times orus per em */

sp_globals.pixshift = -1;
while ((num <= denom) && (sp_globals.pixshift < 8))  /* Max pixels <= 32768, 16384, 8192, ... pixels? */
    {
    num <<= 1;
    sp_globals.pixshift++;        /* sp_globals.pixshift = 0, 1, 2, ... */
    }
if (sp_globals.pixshift < 0)
    return FALSE;

SHOW(sp_globals.pixshift);
sp_globals.poshift = 16 - sp_globals.pixshift;

sp_globals.onepix = (fix15)1 << sp_globals.pixshift;
sp_globals.pixrnd = sp_globals.onepix >> 1;
sp_globals.pixfix = 0xffff << sp_globals.pixshift;

sp_globals.mpshift = sp_globals.multshift - sp_globals.pixshift;
if (sp_globals.mpshift < 0)
    return FALSE;
sp_globals.mprnd = ((fix31)1 << sp_globals.mpshift) >> 1;

return TRUE;
}


FUNCTION void tt_setup_tcb(PARAMS2 ptcb)
GDECL
tcb_t GLOBALFAR *ptcb;           /* Pointer to transformation control bloxk */
/* 
 * Convert transformation coeffs to internal form 
 */
{

ptcb->xxmult = tt_setup_mult(PARAMS2 sp_globals.pspecs->xxmult);
ptcb->xymult = tt_setup_mult(PARAMS2 sp_globals.pspecs->xymult);
ptcb->xoffset = tt_setup_offset(PARAMS2 sp_globals.pspecs->xoffset);
ptcb->yxmult = tt_setup_mult(PARAMS2 sp_globals.pspecs->yxmult);
ptcb->yymult = tt_setup_mult(PARAMS2 sp_globals.pspecs->yymult);
ptcb->yoffset = tt_setup_offset(PARAMS2 sp_globals.pspecs->yoffset);

SHOW(ptcb->xxmult);
SHOW(ptcb->xymult);
SHOW(ptcb->xoffset);
SHOW(ptcb->yxmult);
SHOW(ptcb->yymult);
SHOW(ptcb->yoffset);

tt_type_tcb(PARAMS2 ptcb); /* Classify transformation type */
}


FUNCTION static fix15 tt_setup_mult(PARAMS2 input_mult)
GDECL
fix31   input_mult;    /* Multiplier in input format */
/*
 * Called by setup_tcb() to convert multiplier in transformation
 * matrix from external to internal form.
 */
{
fix15   imshift;       /* Right shift to internal format */
fix31   imdenom;       /* Divisor to internal format */
fix31   imrnd;         /* Rounding for division operation */

imshift = 15 - sp_globals.multshift;
imdenom = (fix31)sp_globals.orus_per_em << imshift;
imrnd = imdenom >> 1;

input_mult >>= 1;
if (input_mult >= 0)
    return (fix15)((input_mult + imrnd) / imdenom);
else
    return -(fix15)((-input_mult + imrnd) / imdenom);
}


FUNCTION static fix31 tt_setup_offset(PARAMS2 input_offset)
GDECL
fix31   input_offset;   /* Multiplier in input format */
/*
 * Called by setup_tcb() to convert offset in transformation
 * matrix from external to internal form.
 */
{
fix15   imshift;       /* Right shift to internal format */
fix31   imrnd;         /* Rounding for right shift operation */

imshift = 15 - sp_globals.multshift;
imrnd = ((fix31)1 << imshift) >> 1;

return (((input_offset >> 1) + imrnd) >> imshift) + sp_globals.mprnd;
}


FUNCTION void tt_type_tcb(PARAMS2 ptcb)
GDECL
tcb_t GLOBALFAR *ptcb;           /* Pointer to transformation control bloxk */
{
fix15   xx_mult;
fix15   xy_mult;
fix15   yx_mult;
fix15   yy_mult;

/* check for mirror image transformations */
xx_mult = ptcb->xxmult;
xy_mult = ptcb->xymult;
yx_mult = ptcb->yxmult;
yy_mult = ptcb->yymult;

ptcb->mirror = ((((fix31)xx_mult*(fix31)yy_mult)-
                     ((fix31)xy_mult*(fix31)yx_mult)) < 0) ? -1 : 1;

/* BOGUS MODE IS ASSUMED */
ptcb->xtype = 4;
ptcb->ytype = 4;

ptcb->xppo = 0;
ptcb->yppo = 0;
ptcb->xpos = 0;
ptcb->ypos = 0;

sp_globals.normal = (ptcb->xtype != 4) && (ptcb->ytype != 4);
#if INCL_WHITE
sp_globals.normal = FALSE;
#endif

ptcb->xmode = 4;
ptcb->ymode = 4;   

SHOW(ptcb->xtype);
SHOW(ptcb->ytype);
SHOW(ptcb->xppo);
SHOW(ptcb->yppo);
SHOW(ptcb->xpos);
SHOW(ptcb->ypos);
}

#pragma Code ()
