/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Speedo/set_spcs.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: set_spcs.c,v 1.1 97/04/18 11:45:14 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("SetupCode")

/*                                                                            *
*  Copyright 1989, as an unpublished work by Bitstream Inc., Cambridge, MA   *
*                         U.S. Patent No 4,785,391                           *
*                           Other Patent Pending                             *
*                                                                            *
*         These programs are the sole property of Bitstream Inc. and         *
*           contain its proprietary and confidential information.            *
*                                                                            *
*****************************************************************************/
/********************* Revision Control Information **********************************
*                                                                                    *
*                                                                                    *
*       Revision 28.37  93/03/15  13:01:24  roberte
*       Release
*       
*       Revision 28.13  93/03/10  17:05:32  roberte
*       metric_resolution moved from union struct to common area. Oops!
*       
*       Revision 28.12  93/01/29  15:47:23  roberte
*       Changed references to specs_valid to reflect change to common area of SPEEDO_GLOBALS.
*       
*       Revision 28.11  93/01/08  14:03:54  roberte
*       hanged references to sp_globals. for pspecs, orus_per_em, curves_out, multrnd, pixfix and mpshift.
*       
*       Revision 28.10  93/01/07  12:03:56  roberte
*       Corrected references for function ptrs init_out - end_char items moved from union to common area of SPEEDO_GLOBALS. 
*       
*       Revision 28.9  93/01/04  16:25:20  roberte
*       
*       Changed all references to new union fields of SPEEDO_GLOBALS to sp_globals.processor.speedo prefix.
*       
*       Revision 28.8  92/12/30  17:50:26  roberte
*       Functions no longer renamed in spdo_prv.h now declared with "sp_"
*       Use PARAMS1&2 macros throughout.
*       
*       Revision 28.7  92/12/15  12:06:01  roberte
*       Added "static" to declaration of sp_setup_tcb(PARAMS1) function..
*       
*       Revision 28.6  92/11/24  10:57:55  laurar
*       include fino.h
*       
*       Revision 28.5  92/11/19  15:18:21  roberte
*       Release
*       
*       Revision 28.1  92/06/25  13:42:14  leeann
*       Release
*       
*       Revision 27.1  92/03/23  14:01:53  leeann
*       Release
*       
*       Revision 26.1  92/01/30  17:01:30  leeann
*       Release
*       
*       Revision 25.1  91/07/10  11:07:09  leeann
*       Release
*       
*       Revision 24.1  91/07/10  10:40:43  leeann
*       Release
*       
*       Revision 23.1  91/07/09  18:01:41  leeann
*       Release
*       
*       Revision 22.3  91/06/03  13:32:07  leeann
*       recalculate constants when pixshift changes
*       
*       Revision 22.2  91/04/08  17:35:11  joyce
*       Changes for new white writer code (M. Yudis)
*       
*       Revision 22.1  91/01/23  17:21:05  leeann
*       Release
*       
*       Revision 21.1  90/11/20  14:40:32  leeann
*       Release
*       
*       Revision 20.1  90/11/12  09:36:13  leeann
*       Release
*       
*       Revision 19.1  90/11/08  10:25:33  leeann
*       Release
*       
*       Revision 18.1  90/09/24  10:16:57  mark
*       Release
*       
*       Revision 17.1  90/09/13  16:01:54  mark
*       Release name rel0913
*       
*       Revision 16.1  90/09/11  13:22:33  mark
*       Release
*       
*       Revision 15.1  90/08/29  10:05:43  mark
*       Release name rel0829
*       
*       Revision 14.2  90/08/23  16:13:46  leeann
*       make setup_const take min and max as arguments
*       
*       Revision 14.1  90/07/13  10:42:31  mark
*       Release name rel071390
*       
*       Revision 13.2  90/07/13  09:32:24  mark
*       cast elements of calculation used to determine mirror
*       images to fix31 so we don't get integer overflow on
*       16 bit machines (such as IBM PC with Microsoft C).
*       
*       Revision 13.1  90/07/02  10:41:35  mark
*       Release name REL2070290
*       
*       Revision 12.5  90/07/02  09:19:41  mark
*       cast byte pointers to target type in read_word_u and read_long
*       
*       Revision 12.4  90/06/01  15:24:26  mark
*       set mirror in type_tcb based on dot (cross?) product
*       of basic transformations matrix.  i.e.
*       xx*yy - xy*yx < 0 is a mirror
*       
*       Revision 12.3  90/04/23  17:59:20  mark
*       rearrange priority of user output modules and
*       internals to allow JC to reuse screen output
*       
*       Revision 12.2  90/04/23  16:44:14  judy
*       fixed USEROUT syntax error.
*       
*       Revision 12.1  90/04/23  12:14:11  mark
*       Release name REL20
*       
*       Revision 11.1  90/04/23  10:14:26  mark
*       Release name REV2
*       
*       Revision 10.11  90/04/23  09:40:05  mark
*       fix argument passed to read_word_u to retrieve metric resolution
*       
*       Revision 10.10  90/04/21  10:46:35  mark
*       wrote functions sp_set_bitmap_device and sp_set_outline_device
*       for initializing structures used in multidevice support
*        
*       
*       Revision 10.9  90/04/18  09:56:35  mark
*       if INCL_USEROUT, call init_userout
*       
*       Revision 10.8  90/04/12  09:11:25  leeann
*       Check for CLIPPING flags set, but clipping code
*       not included.
*       
*       Revision 10.7  90/04/11  13:05:42  leeann
*       change squeeze compilation flag to be INCL_SQUEEZING
*       take CLIPPING dependancy off SQUEEZING
*       
*       Revision 10.6  90/04/10  14:19:46  leeann
*       turn on clipping whenever squeezing is on
*       
*       Revision 10.5  90/04/05  15:15:08  leeann
*       set no squeeze available error to "11"
*       
*       Revision 10.4  90/03/30  14:58:22  mark
*       remove out_wht and add out_scrn and out_util
*       
*       Revision 10.3  90/03/29  14:22:33  leeann
*       Put in error message call for setting of SQUEEZE mode flags
*       when SQUEEZE code is not compiled.
*       
*       
*       Revision 10.2  90/03/26  15:50:15  mark
*       change typo (|= changed to !=) when checking for set_specs with same font
*       set metric_resolution to specified value if font header size is large than
*       nominal, or to orus_per_em if not.
*       
*       Revision 10.1  89/07/28  18:12:51  mark
*       Release name PRODUCT
*       
*       Revision 9.1  89/07/27  10:26:17  mark
*       Release name PRODUCT
*       
*       Revision 8.1  89/07/13  18:22:11  mark
*       Release name Product
*       
*       Revision 7.1  89/07/11  09:04:49  mark
*       Release name PRODUCT
*       
*       Revision 6.3  89/07/09  15:00:12  mark
*       change stuff to handle GLOBALFAR option
*       
*       Revision 6.2  89/07/09  12:39:13  mark
*       copy specsarg into sp_globals.specs, and set pspecs to
*       point to copy in case user allocates it off the stack
*       
*       Revision 6.1  89/06/19  08:37:41  mark
*       Release name prod
*       
*       Revision 5.1  89/05/01  17:56:59  mark
*       Release name Beta
*       
*       Revision 4.2  89/05/01  17:15:38  mark
*       remove improper function declarations
*       
*       Revision 4.1  89/04/27  15:41:56  mark
*       Release name Beta
*       
*       Revision 3.1  89/04/25  08:32:59  mark
*       Release name beta
*       
*       Revision 2.5  89/04/18  18:23:13  john
*       sp_setup_consts(PARAMS1) rewritten to correct bounding box errors.
*       sp_setup_mult(PARAMS1), sp_setup_offset(PARAMS1) function definitions added.
*       
*       Revision 2.4  89/04/14  14:13:45  mark
*        Changed shift in setup_consts to work around MicroSoft C problem
*       
*       Revision 2.3  89/04/12  12:15:30  mark
*       added stuff for far stack and font
*       
*       Revision 2.2  89/04/10  17:05:24  mark
*       Modified pointer declarations that are used to refer
*       to font data to use FONTFAR symbol, which will be used
*       for Intel SS != DS memory models
*       
*       Revision 2.1  89/04/04  13:39:00  mark
*       Release name EVAL
*       
*       Revision 1.9  89/04/04  13:27:52  mark
*       Update copyright text
*       
*       Revision 1.8  89/03/31  17:36:17  john
*       Replaced NEXT_WORD_U() macro with sp_read_word_u(PARAMS1) function.
*       
*       Revision 1.7  89/03/31  14:51:20  mark
*       change speedo.h to spdo_prv.h
*       eliminate thresh
*       change fontware comments to speedo                  

*       
*       Revision 1.6  89/03/30  17:54:38  john
*       read_long_u() and read_long_ee() replaced by sp_read_long(PARAMS1).
*       value of normal now calculated in sp_type_tcb(PARAMS1).
*       
*       Revision 1.5  89/03/29  16:12:44  mark
*       changes for slot independence and dynamic/reentrant
*       data allocation
*       
*       Revision 1.4  89/03/24  16:46:06  john
*       Error 2 (Too many characters) eliminated.
*       setup_char_dir() eliminated.
*       
*       Revision 1.3  89/03/23  11:50:33  john
*       New entries added to font header
*       
*       Revision 1.2  89/03/21  13:32:52  mark
*       change name from oemfw.h to speedo.h
*       
*       Revision 1.1  89/03/15  12:35:55  mark
*       Initial revision
*                                                                                 *
*                                                                                    *
*************************************************************************************/

#ifdef RCSSTATUS
#endif



/*************************** S E T _ S P C S . C *****************************
 *                                                                           *
 * This module implements all sp_set_specs(PARAMS1) functionality.                  *
 *                                                                           *
 ********************** R E V I S I O N   H I S T O R Y **********************
 *                                                                           *
 *  1) 15 Dec 88  jsc  Created                                               *
 *                                                                           *
 *  2) 23 Jan 89  jsc  Font decryption mechanism implemented                 *
 *                                                                           *
 *  3)  2 Feb 89  jsc  Constraints off control added to specs flags          *
 *                                                                           *
 *  4) 10 Feb 89  jsc  Added CR NUL check in font header                     *
 *                                                                           *
 *  3)  1 Mar 89  jsc  Font decryption mechanism updated.                    *
 *                                                                           *
 ****************************************************************************/
#define SET_SPCS
#include "spdo_prv.h"               /* General definitions for Speedo    */
#include "fino.h"

#define   DEBUG      0

#if DEBUG
#include <stdio.h>
#define SHOW(X) printf("X = %d\n", X)
#else
#define SHOW(X)
#endif

/***** GLOBAL VARIABLES *****/

/***** GLOBAL FUNCTIONS *****/

/****** EXTERNAL VARIABLES *****/

/***** STATIC VARIABLES *****/


/****** STATIC FUNCTIONS *****/


FUNCTION boolean sp_set_specs(PARAMS2 specsarg)
GDECL
specs_t STACKFAR *specsarg;     /* Bundle of conversion specifications */
/* 
 * Called by host software to set character generation specifications
 */
{
ufix8 FONTFAR  *pointer;       /* Pointer to font data */
fix31   offcd;         /* Offset to start of character directory */
fix31   ofcns;         /* Offset to start of constraint data */ 
fix31   cd_size;       /* Size of character directory */
fix31   no_bytes_min;  /* Min number of bytes in font buffer */
ufix16  font_id;       /* Font ID */
ufix16  private_off;   /* offset to private header */
fix15   xmin;          /* Minimum X ORU value in font */
fix15   xmax;          /* Maximum X ORU value in font */
fix15   ymin;          /* Minimum Y ORU value in font */
fix15   ymax;          /* Maximum Y ORU value in font */

sp_globals.specs_valid = FALSE;           /* Flag specs not valid */

sp_globals.specs = *specsarg;   /* copy specs structure into sp_globals */
sp_globals.pspecs = &sp_globals.specs;
sp_globals.processor.speedo.font = *sp_globals.pspecs->pfont;
sp_globals.processor.speedo.pfont = &sp_globals.processor.speedo.font;
sp_globals.processor.speedo.font_org = sp_globals.processor.speedo.font.org;

if (sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_FMVER + 4) != 0x0d0a)
    {
    sp_report_error(PARAMS2 4);           /* Font format error */
    return FALSE;
    }
if (sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_FMVER + 6) != 0x0000)
    {
    sp_report_error(PARAMS2 4);           /* Font format error */
    return FALSE;
    }

sp_globals.processor.speedo.no_chars_avail = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_NCHRF);

/* Read sp_globals.processor.speedo.orus per em from font header */
sp_globals.orus_per_em = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_ORUPM);

/* compute address of private header */
private_off = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_HEDSZ);
sp_globals.processor.speedo.hdr2_org = sp_globals.processor.speedo.font_org + private_off;

/* set metric resolution if specified, default to outline res otherwise */
if (private_off > EXP_FH_METRES)
	{
	sp_globals.metric_resolution = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + EXP_FH_METRES);
	}
else
	{
	sp_globals.metric_resolution = sp_globals.orus_per_em;
	}

#if INCL_METRICS
sp_globals.processor.speedo.kern.tkorg = sp_globals.processor.speedo.font_org + sp_read_long(PARAMS2 sp_globals.processor.speedo.hdr2_org + FH_OFFTK);
sp_globals.processor.speedo.kern.pkorg = sp_globals.processor.speedo.font_org + sp_read_long(PARAMS2 sp_globals.processor.speedo.hdr2_org + FH_OFFPK); 
sp_globals.processor.speedo.kern.no_tracks = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_NKTKS);
sp_globals.processor.speedo.kern.no_pairs = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_NKPRS);
#endif

offcd = sp_read_long(PARAMS2 sp_globals.processor.speedo.hdr2_org + FH_OFFCD); /* Read offset to character directory */
ofcns = sp_read_long(PARAMS2 sp_globals.processor.speedo.hdr2_org + FH_OFCNS); /* Read offset to constraint data */
cd_size = ofcns - offcd;
if ((((sp_globals.processor.speedo.no_chars_avail << 1) + 3) != cd_size) &&
    (((sp_globals.processor.speedo.no_chars_avail * 3) + 4) != cd_size))
    {
    sp_report_error(PARAMS2 4);           /* Font format error */
    return FALSE;
    }

#if INCL_LCD                   /* Dynamic character data load suppoorted? */
#if INCL_METRICS
no_bytes_min = sp_read_long(PARAMS2 sp_globals.processor.speedo.hdr2_org + FH_OCHRD); /* Offset to character data */
#else                          /* Dynamic character data load not supported? */
no_bytes_min = sp_read_long(PARAMS2 sp_globals.processor.speedo.hdr2_org + FH_OFFTK); /* Offset to track kerning data */
#endif
#else                          /* Dynamic character data load not supported? */
no_bytes_min = sp_read_long(PARAMS2 sp_globals.processor.speedo.hdr2_org + FH_NBYTE); /* Offset to EOF + 1 */
#endif

sp_globals.processor.speedo.font_buff_size = sp_globals.processor.speedo.pfont->no_bytes;
if (sp_globals.processor.speedo.font_buff_size < no_bytes_min)  /* Minimum data not loaded? */
    {
    sp_report_error(PARAMS2 1);           /* Insufficient font data loaded */
    return FALSE;
    }

sp_globals.processor.speedo.pchar_dir = sp_globals.processor.speedo.font_org + offcd;
sp_globals.processor.speedo.first_char_idx = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_FCHRF);

/* Register font name with sp_globals.processor.speedo.constraint mechanism */
#if INCL_RULES
font_id = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_FNTID);
if (!(sp_globals.processor.speedo.constr.font_id_valid) || (sp_globals.processor.speedo.constr.font_id != font_id))
    {
    sp_globals.processor.speedo.constr.font_id = font_id;
    sp_globals.processor.speedo.constr.font_id_valid = TRUE;
    sp_globals.processor.speedo.constr.data_valid = FALSE;
    }
sp_globals.processor.speedo.constr.org = sp_globals.processor.speedo.font_org + ofcns;
sp_globals.processor.speedo.constr.active = ((sp_globals.pspecs->flags & CONSTR_OFF) == 0);
#endif

/* Set up sliding point constants */
/* Set pixel shift to accomodate largest transformed pixel value */
xmin = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_FXMIN);
xmax = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_FXMAX);
ymin = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_FYMIN);
ymax = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_FYMAX);

if (!sp_setup_consts(PARAMS2 xmin,xmax,ymin,ymax))
    {
    sp_report_error(PARAMS2 3);           /* Requested specs out of range */
    return FALSE;
    }
#if INCL_ISW
/* save the value of the max x oru that the fixed point constants are based on*/
sp_globals.processor.speedo.isw_xmax = xmax; 
#endif

/* Setup transformation control block */
sp_setup_tcb(PARAMS2 &sp_globals.tcb0);


/* Select output module */
sp_globals.output_mode = sp_globals.pspecs->flags & 0x0007;

#if INCL_USEROUT
if (!sp_init_userout(PARAMS2 sp_globals.pspecs))
#endif

switch (sp_globals.output_mode)
    {
#if INCL_BLACK
case MODE_BLACK:                        /* Output mode Black writer */
	sp_globals.init_out = sp_init_black;
    sp_globals.begin_char		= sp_begin_char_black;
    sp_globals.begin_sub_char	= sp_begin_sub_char_out;
   	sp_globals.begin_contour	= sp_begin_contour_black;
    sp_globals.curve			= sp_curve_out;
   	sp_globals.line			= sp_line_black;
    sp_globals.end_contour		= sp_end_contour_out;
   	sp_globals.end_sub_char	= sp_end_sub_char_out;
    sp_globals.end_char		= sp_end_char_black;
    break;
#endif

#if INCL_SCREEN
case MODE_SCREEN:                       /* Output mode Screen writer */
	sp_globals.init_out = sp_init_screen;
    sp_globals.begin_char		= sp_begin_char_screen;
    sp_globals.begin_sub_char	= sp_begin_sub_char_out;
   	sp_globals.begin_contour	= sp_begin_contour_screen;
    sp_globals.curve			= sp_curve_screen;
   	sp_globals.line			= sp_line_screen;
    sp_globals.end_contour		= sp_end_contour_screen;
   	sp_globals.end_sub_char	= sp_end_sub_char_out;
    sp_globals.end_char		= sp_end_char_screen;
	break;
#endif

#if INCL_OUTLINE
case MODE_OUTLINE:                      /* Output mode Vector */
	sp_globals.init_out = sp_init_outline;
    sp_globals.begin_char		= sp_begin_char_outline;
    sp_globals.begin_sub_char	= sp_begin_sub_char_outline;
   	sp_globals.begin_contour	= sp_begin_contour_outline;
    sp_globals.curve			= sp_curve_outline;
   	sp_globals.line			= sp_line_outline;
    sp_globals.end_contour		= sp_end_contour_outline;
   	sp_globals.end_sub_char	= sp_end_sub_char_outline;
    sp_globals.end_char		= sp_end_char_outline;
	break;
#endif

#if INCL_2D
case MODE_2D:                           /* Output mode 2d */
	sp_globals.init_out = sp_init_2d;
    sp_globals.begin_char		= sp_begin_char_2d;
    sp_globals.begin_sub_char	= sp_begin_sub_char_out;
   	sp_globals.begin_contour	= sp_begin_contour_2d;
    sp_globals.curve			= sp_curve_out;
   	sp_globals.line			= sp_line_2d;
    sp_globals.end_contour		= sp_end_contour_out;
   	sp_globals.end_sub_char	= sp_end_sub_char_out;
    sp_globals.end_char		= sp_end_char_2d;
    break;
#endif

#if INCL_WHITE
case MODE_WHITE:                        /* Output mode White writer */
    sp_globals.init_out       = sp_init_white;
    sp_globals.begin_char     = sp_begin_char_white;
    sp_globals.begin_sub_char = sp_begin_sub_char_out;
    sp_globals.begin_contour  = sp_begin_contour_white;
    sp_globals.curve          = sp_curve_out;
    sp_globals.line           = sp_line_white;
    sp_globals.end_contour    = sp_end_contour_white;
    sp_globals.end_sub_char   = sp_end_sub_char_out;
    sp_globals.end_char       = sp_end_char_white;
    break;
#endif

default:
    sp_report_error(PARAMS2 8);           /* Unsupported mode requested */
    return FALSE;
    }

	if (!fn_init_out(sp_globals.pspecs))
		{
		sp_report_error(PARAMS2 5);
		return FALSE;
		}
		

sp_globals.curves_out = sp_globals.pspecs->flags & CURVES_OUT;

if (sp_globals.pspecs->flags & BOGUS_MODE) /* Linear transformation requested? */
    {
    sp_globals.tcb0.xtype = sp_globals.tcb0.ytype = 4;
    }
else                           /* Intelligent transformation requested? */
    {
#if INCL_RULES
#else
    sp_report_error(PARAMS2 7);           /* Rules requested; not supported */
    return FALSE;
#endif
    }

if ((sp_globals.pspecs->flags & SQUEEZE_LEFT) ||
    (sp_globals.pspecs->flags & SQUEEZE_RIGHT) ||
    (sp_globals.pspecs->flags & SQUEEZE_TOP) ||
    (sp_globals.pspecs->flags & SQUEEZE_BOTTOM) )
    {
#if (INCL_SQUEEZING)
#else
     sp_report_error(PARAMS2 11);
     return FALSE;
#endif
    }

if ((sp_globals.pspecs->flags & CLIP_LEFT) ||
    (sp_globals.pspecs->flags & CLIP_RIGHT) ||
    (sp_globals.pspecs->flags & CLIP_TOP) ||
    (sp_globals.pspecs->flags & CLIP_BOTTOM) )
    {
#if (INCL_CLIPPING)
#else
     sp_report_error(PARAMS2 11);
     return FALSE;
#endif
    }

sp_globals.specs_valid = TRUE;
return TRUE;
}



#if INCL_MULTIDEV
#if INCL_BLACK || INCL_SCREEN || INCL_2D
FUNCTION boolean set_bitmap_device(bfuncs,size)
GDECL
bitmap_t *bfuncs;
ufix16 size;
{

if (size != sizeof(sp_globals.processor.speedo.bitmap_device))
	return FALSE;

sp_globals.processor.speedo.bitmap_device = *bfuncs;
sp_globals.processor.speedo.bitmap_device_set = TRUE;
}
#endif

#if INCL_OUTLINE
FUNCTION boolean set_outline_device(ofuncs,size)
GDECL
outline_t *ofuncs;
ufix16 size;
{

if (size != sizeof(sp_globals.processor.speedo.outline_device))
	return FALSE;

sp_globals.processor.speedo.outline_device = *ofuncs;
sp_globals.processor.speedo.outline_device_set = TRUE;
}
#endif
#endif


FUNCTION boolean sp_setup_consts(PARAMS2 xmin, xmax, ymin, ymax)
GDECL
fix15   xmin;          /* Minimum X ORU value in font */
fix15   xmax;          /* Maximum X ORU value in font */
fix15   ymin;          /* Minimum Y ORU value in font */
fix15   ymax;          /* Maximum Y ORU value in font */
/*
 * Sets the following constants used for fixed point arithmetic:
 *      sp_globals.multshift    multipliers and products; range is 14 to 8
 *      sp_globals.pixshift     pixels: range is 0 to 8
 *      sp_globals.mpshift      shift from product to sub-pixels (sp_globals.multshift - sp_globals.pixshift)
 *      sp_globals.multrnd      rounding for products
 *      sp_globals.pixrnd       rounding for pixels
 *      sp_globals.mprnd        rounding for sub-pixels
 *      sp_globals.onepix       1 pixel in shifted pixel units
 *      sp_globals.pixfix       mask to eliminate fractional bits of shifted pixels
 *      sp_globals.processor.speedo.depth_adj    curve splitting depth adjustment
 * Returns FALSE if specs are out of range
 */
{
fix31   mult;          /* Successive multiplier values */
ufix32  num;           /* Numerator of largest multiplier value */
ufix32  numcopy;       /* Copy of numerator */
ufix32  denom;         /* Denominator of largest multiplier value */
ufix32  denomcopy;     /* Copy of denominator */
ufix32  pix_max;       /* Maximum pixel rounding error */
fix31   xmult;         /* Coefficient of X oru value in transformation */
fix31   ymult;         /* Coefficient of Y oru value in transformation */
fix31   offset;        /* Constant in transformation */
fix15   i;             /* Loop counter */
fix15   x, y;          /* Successive corners of bounding box in ORUs */
fix31   pixval;        /* Successive pixel values multiplied by orus per em */
fix15   xx, yy;        /* Bounding box corner that produces max pixel value */
fix15   oldpixshift;   /* Save gs_globals.pixshift */

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

/* Set curve splitting depth adjustment to accomodate largest multiplier value */
sp_globals.processor.speedo.depth_adj = 0;   /* 0 = 0.5 pel, 1 = 0.13 pel, 2 = 0.04 pel accuracy */
denomcopy = denom;
/*  The following two occurances of a strange method of shifting twice by 1 
    are intentional and should not be changed to a single shift by 2.  
    It prevents MicroSoft C 5.1 from generating functions calls to do the shift.  
    Worse, using the REENTRANT_ALLOC option in conjunction with the /AC compiler 
    option, the function appears to be called incorrectly, causing depth_adj to always
	be set to -7, causing very angular characters. */

while ((num > denomcopy) && (sp_globals.processor.speedo.depth_adj < 5)) /* > 1, 4, 16, ...  pixels per oru? */
    {
    denomcopy <<= 1;
    denomcopy <<= 1;
    sp_globals.processor.speedo.depth_adj++; /* Add 1, 2, 3, ... to depth adjustment */
    }
numcopy = num << 2;
while ((numcopy <= denom) && (sp_globals.processor.speedo.depth_adj > -4))  /* <= 1/4, 1/16, 1/64 pix per oru? */
    {
    numcopy <<= 1;
    numcopy <<= 1;
    sp_globals.processor.speedo.depth_adj--; /* Subtract 1, 2, 3, ... from depth adjustment */
    }
SHOW(sp_globals.processor.speedo.depth_adj);

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


pix_max = (ufix32)((ufix16)sp_read_word_u(PARAMS2 sp_globals.processor.speedo.hdr2_org + FH_PIXMX));

num = 0;
xmult = ((sp_globals.pspecs->xxmult >> 16) + 1) >> 1;
ymult = ((sp_globals.pspecs->xymult >> 16) + 1) >> 1;
offset = ((sp_globals.pspecs->xoffset >> 16) + 1) >> 1;
xx = yy = 0;
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

oldpixshift = sp_globals.pixshift;

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

if (oldpixshift != sp_globals.pixshift)
    sp_globals.processor.speedo.constr.data_valid = FALSE; /* pixshift changed -
                                             recalculate sp_globals.processor.speedo.pix */
return TRUE;
}

FUNCTION static void sp_setup_tcb(PARAMS2 ptcb)
GDECL
tcb_t GLOBALFAR *ptcb;           /* Pointer to transformation control bloxk */
/* 
 * Convert transformation coeffs to internal form 
 */
{

ptcb->xxmult = sp_setup_mult(PARAMS2 sp_globals.pspecs->xxmult);
ptcb->xymult = sp_setup_mult(PARAMS2 sp_globals.pspecs->xymult);
ptcb->xoffset = sp_setup_offset(PARAMS2 sp_globals.pspecs->xoffset);
ptcb->yxmult = sp_setup_mult(PARAMS2 sp_globals.pspecs->yxmult);
ptcb->yymult = sp_setup_mult(PARAMS2 sp_globals.pspecs->yymult);
ptcb->yoffset = sp_setup_offset(PARAMS2 sp_globals.pspecs->yoffset);

SHOW(ptcb->xxmult);
SHOW(ptcb->xymult);
SHOW(ptcb->xoffset);
SHOW(ptcb->yxmult);
SHOW(ptcb->yymult);
SHOW(ptcb->yoffset);

sp_type_tcb(PARAMS2 ptcb); /* Classify transformation type */
}

FUNCTION static fix15 sp_setup_mult(PARAMS2 input_mult)
GDECL
fix31   input_mult;    /* Multiplier in input format */
/*
 * Called by sp_setup_tcb(PARAMS1) to convert multiplier in transformation
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

FUNCTION static fix31 sp_setup_offset(PARAMS2 input_offset)
GDECL
fix31   input_offset;   /* Multiplier in input format */
/*
 * Called by sp_setup_tcb(PARAMS1) to convert offset in transformation
 * matrix from external to internal form.
 */
{
fix15   imshift;       /* Right shift to internal format */
fix31   imrnd;         /* Rounding for right shift operation */

imshift = 15 - sp_globals.multshift;
imrnd = ((fix31)1 << imshift) >> 1;

return (((input_offset >> 1) + imrnd) >> imshift) + sp_globals.mprnd;
}

FUNCTION void sp_type_tcb(PARAMS2 ptcb)
GDECL
tcb_t GLOBALFAR *ptcb;           /* Pointer to transformation control bloxk */
{
fix15   x_trans_type;
fix15   y_trans_type;
fix15   xx_mult;
fix15   xy_mult;
fix15   yx_mult;
fix15   yy_mult;
fix15   h_pos;
fix15   v_pos;
fix15   x_ppo;
fix15   y_ppo;
fix15   x_pos;
fix15   y_pos;

/* check for mirror image transformations */
xx_mult = ptcb->xxmult;
xy_mult = ptcb->xymult;
yx_mult = ptcb->yxmult;
yy_mult = ptcb->yymult;

ptcb->mirror = ((((fix31)xx_mult*(fix31)yy_mult)-
                     ((fix31)xy_mult*(fix31)yx_mult)) < 0) ? -1 : 1;

if (sp_globals.pspecs->flags & BOGUS_MODE) /* Linear transformation requested? */
    {
    ptcb->xtype = 4;
    ptcb->ytype = 4;

    ptcb->xppo = 0;
    ptcb->yppo = 0;
    ptcb->xpos = 0;
    ptcb->ypos = 0;
    }
else                            /* Intelligent tranformation requested? */
    {
    h_pos = ((ptcb->xoffset >> sp_globals.mpshift) + sp_globals.pixrnd) & sp_globals.pixfix;
    v_pos = ((ptcb->yoffset >> sp_globals.mpshift) + sp_globals.pixrnd) & sp_globals.pixfix;

    x_trans_type = 4;
    x_ppo = 0;
    x_pos = 0;

    y_trans_type = 4;
    y_ppo = 0;
    y_pos = 0;

    if (xy_mult == 0)
        {
        if (xx_mult >= 0)
            {
            x_trans_type = 0;   /* X pix is function of X orus only */
            x_ppo = xx_mult;
            x_pos = h_pos;
            }
        else 
            {
            x_trans_type = 1;   /* X pix is function of -X orus only */
            x_ppo = -xx_mult;
            x_pos = -h_pos;
            }
        }

    else if (xx_mult == 0)
        {
        if (xy_mult >= 0)
            {
            x_trans_type = 2;   /* X pix is function of Y orus only */
            y_ppo = xy_mult;
            y_pos = h_pos;
            }
        else 
            {
            x_trans_type = 3;   /* X pix is function of -Y orus only */
            y_ppo = -xy_mult;
            y_pos = -h_pos;
            }
        }

    if (yx_mult == 0)
        {
        if (yy_mult >= 0)
            {
            y_trans_type = 0;   /* Y pix is function of Y orus only */
            y_ppo = yy_mult;
            y_pos = v_pos;
            }
        else 
            {
            y_trans_type = 1;   /* Y pix is function of -Y orus only */
            y_ppo = -yy_mult;
            y_pos = -v_pos;
            }
        }
    else if (yy_mult == 0)
        {
        if (yx_mult >= 0)
            {
            y_trans_type = 2;   /* Y pix is function of X orus only */
            x_ppo = yx_mult;
            x_pos = v_pos;
            }
        else 
            {
            y_trans_type = 3;   /* Y pix is function of -X orus only */
            x_ppo = -yx_mult;
            x_pos = -v_pos;
            }
        }

    ptcb->xtype = x_trans_type;
    ptcb->ytype = y_trans_type;

    ptcb->xppo = x_ppo;
    ptcb->yppo = y_ppo;
    ptcb->xpos = x_pos;
    ptcb->ypos = y_pos;
    }

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

#pragma Code ("BitstreamCode")


FUNCTION fix31 sp_read_long(PARAMS2 pointer)
GDECL
ufix8 FONTFAR *pointer;    /* Pointer to first byte of encrypted 3-byte integer */
/*
 * Reads a 3-byte encrypted integer from the byte string starting at 
 * the specified point.
 * Returns the decrypted value read as a signed integer.
 */
{
fix31 tmpfix31;

tmpfix31 = (fix31)((*pointer++) ^ sp_globals.processor.speedo.key4) << 8;            /* Read middle byte */
tmpfix31 += (fix31)(*pointer++) << 16;                              /* Read most significant byte */
tmpfix31 += (fix31)((*pointer) ^ sp_globals.processor.speedo.key6);                    /* Read least significant byte */
return tmpfix31;
}

FUNCTION fix15 sp_read_word_u(PARAMS2 pointer)
GDECL
ufix8 FONTFAR *pointer;    /* Pointer to first byte of unencrypted 2-byte integer */
/*
 * Reads a 2-byte unencrypted integer from the byte string starting at 
 * the specified point.
 * Returns the decrypted value read as a signed integer.
 */
{
fix15 tmpfix15;

tmpfix15 = (fix15)(*pointer++) << 8;                                /* Read most significant byte */
tmpfix15 += (fix15)(*pointer);                                        /* Add least significant byte */
return tmpfix15;
}

#pragma Code ()
