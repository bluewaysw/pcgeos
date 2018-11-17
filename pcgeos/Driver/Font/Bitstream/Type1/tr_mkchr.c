/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Type1/tr_mkchr.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: tr_mkchr.c,v 1.1 97/04/18 11:45:17 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TrMkChrCode")


/*****************************************************************************
*                                                                            *
*  Copyright 1990, as an unpublished work by Bitstream Inc., Cambridge, MA   *
*                         U.S. Patent No 4,785,391                           *
*                           Other Patent Pending                             *
*                                                                            *
*         These programs are the sole property of Bitstream Inc. and         *
*           contain its proprietary and confidential information.            *
*                                                                            *
*****************************************************************************/



/*************************** M K _ C H R _ A . C *****************************
 *                                                                           *
 * This is the Type A font interpreter.                                      *
 *                                                                           *
 ********************** R E V I S I O N   H I S T O R Y **********************
* static char rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/Type1/tr_mkchr.c,v 1.1 97/04/18 11:45:17 newdeal Exp $";
 *
 * $Log:	tr_mkchr.c,v $
 * Revision 1.1  97/04/18  11:45:17  newdeal
 * Initial revision
 * 
 * Revision 1.1.10.1  97/03/29  07:05:53  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:17:58  brianc
 * support Type1
 * 
 * Revision 28.24  93/03/15  13:11:14  roberte
 * Release
 * 
 * Revision 28.23  93/03/09  18:38:20  ruey
 * fix an error on do_pop{}
 * 
 * Revision 28.22  93/03/09  15:08:48  ruey
 * made a correction to do_pop() and tr_pop()
 * 
 * Revision 28.21  93/03/08  17:17:03  roberte
 * setup_constants() set sp_globals.tcb0.mirror as well. A must for white writer!
 * 
 * Revision 28.20  93/03/04  11:28:19  ruey
 * add tr_pop() and do_pop()
 * 
 * Revision 28.19  93/02/10  15:09:24  roberte
 * Moved stack allocation of intercepts to tr_make_char from do_char.
 * Also removed un-needed stack allocation of plaid.
 * 
 * Revision 28.18  93/02/05  13:36:14  roberte
 * Replaced all of Type1's use of its private function pointers for output functions.
 * Now initializes SPEEDO_GLOBALS function pointers and calls fn_*() functions
 * like the other processors.
 * 
 * Revision 28.17  93/01/29  11:01:28  roberte
 * Changed reference to sp_globals.plaid to reflect its' move from union struct to common area.  
 * 
 * Revision 28.16  93/01/21  13:25:21  roberte
 * Reentrant code work.  Added macros to support sp_global_ptr parameter pass in all essential call threads.
 * Prototyped all static functions.
 * 
 * Revision 28.15  93/01/18  11:05:47  ruey
 * move tr_get_leniv out of while loop
 * 
 * Revision 28.14  93/01/18  10:59:42  ruey
 * add error_handling for sub_charstring
 * 
 * Revision 28.13  93/01/18  10:44:39  ruey
 * seac uses charname_tbl instead of the tr_encode[]
 * 
 * Revision 28.12  93/01/14  10:16:42  roberte
 * Changed all data references to sp_globals.processor.type1.<varname> since these are all part of union structure there.
 * 
 * Revision 28.11  93/01/04  17:25:55  roberte
 *   Changed all the report_error calls back to sp_report_error to be in line with the spdo_prv.h changes.
 * 
 * Revision 28.10  92/12/28  11:23:56  roberte
 * In tr_set_specs(), setup_constants() and tr_get_char_width(), revert to
 * old K&R style of parameter declaration.
 * 
 * Revision 28.9  92/12/02  17:48:04  laurar
 * add STACKFAR to a pointer.
 * 
 * Revision 28.8  92/11/24  13:13:48  laurar
 * include fino.h
 * 
 * Revision 28.7  92/11/19  15:35:37  weili
 * Release
 * 
 * Revision 26.6  92/11/16  18:31:06  laurar
 * Add STACKFAR for Windows.
 * 
 * Revision 26.5  92/10/21  09:58:41  davidw
 * Turned off debug
 * 
 * Revision 26.4  92/10/16  16:42:29  davidw
 * beautified with indent
 * 
 * Revision 26.3  92/10/01  12:11:24  laurar
 * change specs_flags from ufix16 to ufix32;
 * changed appropriate casts as a result of this.
 * 
 * Revision 26.2  92/09/28  16:46:21  roberte
 * Changed "fnt.h" to "fnt_a.h". Same include file needs different name for 4in1.
 * 
 * Revision 26.1  92/06/26  10:26:10  leeann
 * Release
 * 
 * Revision 25.1  92/04/06  11:42:32  leeann
 * Release
 * 
 * Revision 24.2  92/04/06  11:30:30  leeann
 * When a font has a flex feature height > blueshift use two bezier curves
 * 
 * Revision 24.1  92/03/23  14:10:48  leeann
 * Release
 * 
 * Revision 23.1  92/01/29  17:01:53  leeann
 * Release
 * 
 * Revision 22.1  92/01/20  13:33:14  leeann
 * Release
 * 
 * Revision 21.2  92/01/20  12:47:39  leeann
 * Get the charstring definition again for compound characters when
 * working in the RESTRICTED_ENVIRON implementations
 * 
 * Revision 21.1  91/10/28  16:45:42  leeann
 * Release
 * 
 * Revision 20.1  91/10/28  15:29:24  leeann
 * Release
 * 
 * Revision 18.2  91/10/23  14:02:55  leeann
 * fix reference to leniv in tr_get_char_width function
 * 
 * Revision 18.1  91/10/17  11:40:56  leeann
 * Release
 * 
 * Revision 17.5  91/10/08  15:59:25  leeann
 * fix matrix multiplication bug
 * 
 * Revision 17.4  91/09/24  16:41:19  leeann
 * fix poshift assignment
 * 
 * Revision 17.3  91/09/18  14:19:26  leeann
 * pre-multiply current transformation matrix by the font matrix
 * 
 * Revision 17.2  91/07/12  11:43:34  mark
 * check return of tr_get_chardef in tr_get_char_width so we don't try to
 * get the width of nonexistent characters.
 * 
 * Revision 17.1  91/06/13  10:45:34  leeann
 * Release
 * 
 * Revision 16.1  91/06/04  15:36:13  leeann
 * Release
 * 
 * Revision 15.1  91/05/08  18:08:20  leeann
 * Release
 * 
 * Revision 14.2  91/05/08  14:59:06  leeann
 * keep accurate record of current pixel position independent
 * of output module.
 * 
 * Revision 14.1  91/05/07  16:30:08  leeann
 * Release
 * 
 * Revision 13.1  91/04/30  17:04:51  leeann
 * Release
 * 
 * Revision 12.1  91/04/29  14:55:13  leeann
 * Release
 * 
 * Revision 11.4  91/04/26  11:17:57  leeann
 * improve curve splitting
 * 
 * Revision 11.3  91/04/24  17:49:07  leeann
 * support OSUBR_CALLOUT, make flex curves look better at low resolution
 * 
 * Revision 11.2  91/04/10  13:20:37  leeann
 *  support character names as structures
 * 
 * Revision 11.1  91/04/04  10:59:01  leeann
 * Release
 * 
 * Revision 10.1  91/03/14  14:31:22  leeann
 * Release
 * 
 * Revision 9.1  91/03/14  10:06:38  leeann
 * Release
 * 
 * Revision 8.7  91/03/13  16:17:33  leeann
 * Support RESTRICTED_ENVIRON
 * 
 * Revision 8.6  91/02/20  11:13:10  leeann
 * pass flag to tr_set_specs
 * 
 * Revision 8.5  91/02/19  16:23:45  leeann
 * set curves_out to FALSE for output modules other than OUTLINE
 * 
 * Revision 8.4  91/02/19  16:21:33  leeann
 * put in curve logic
 * 
 * Revision 8.3  91/02/14  16:09:49  leeann
 * set curves_out to TRUE
 * 
 * Revision 8.2  91/02/12  12:56:24  leeann
 * change tr_make_char and tr_set_specs to boolean
 * change tr_get_char_width to return a real
 * 
 * Revision 8.1  91/01/30  19:03:30  leeann
 * Release
 * 
 * Revision 7.2  91/01/30  18:55:09  leeann
 * clarify integer sizes
 * 
 * Revision 7.1  91/01/22  14:27:53  leeann
 * Release
 * 
 * Revision 6.1  91/01/16  10:53:43  leeann
 * Release
 * 
 * Revision 5.2  91/01/07  19:56:07  leeann
 * change function type of "tr_get_paint_type" to fix15
 * 
 * Revision 5.1  90/12/12  17:20:19  leeann
 * Release
 * 
 * Revision 4.1  90/12/12  14:46:05  leeann
 * Release
 * 
 * Revision 3.3  90/12/11  17:39:24  leeann
 * fix setwidth units
 * 
 * Revision 3.2  90/12/11  17:22:00  leeann
 * return set width in fractions of an em
 * 
 * Revision 3.1  90/12/06  10:28:29  leeann
 * Release
 * 
 * Revision 2.2  90/12/05  11:36:03  joyce
 * Set specs flags for output modules
 * 
 * Revision 2.1  90/12/03  12:57:12  mark
 * Release
 * 
 * Revision 1.2  90/12/03  12:20:50  joyce
 * Changed include line to reference new include file names:
 * fnt_a.h -> fnt.h, ps_qem.h -> type1.h
 * 
 * Revision 1.1  90/11/30  11:28:00  joyce
 * Initial revision
 * 
 * Revision 1.12  90/11/29  17:23:13  joyce
 * Added call to end_contour in do_closepath
 * 
 * Revision 1.11  90/11/29  15:38:37  leeann
 * fix tr_get_set_width
 * 
 * Revision 1.10  90/11/29  15:15:46  leeann
 * add tr_get_char_width, change function names,
 * allow multiple fonts
 * 
 * Revision 1.9  90/11/28  11:15:50  joyce
 * replaced output modules with speedo output modules
 * 
 * Revision 1.8  90/11/19  15:53:52  joyce
 * replacing output modules with speedo modules (incomplete)
 * 
 * Revision 1.7  90/09/17  13:01:22  roger
 * test in othersubr put into DEBUG, some changes to help
 * pc compatiblity
 * 
 * Revision 1.6  90/09/13  12:51:12  roger
 * preprocessor options put in so useropt.h does control what 
 * is being compiled
 * 
 * Revision 1.5  90/09/11  16:57:38  roger
 * converted callothersubr to split integer
 * 
 * Revision 1.4  90/09/11  14:53:58  roger
 * moved several more calculations to split integer
 * 
 * Revision 1.3  90/09/11  10:45:37  roger
 * major revision to convert most real calculations to integer
 * each stack item has a real member and a split integer member
 * which has four fractional bits
 * 
 * Revision 1.2  90/09/07  09:26:49  roger
 * fixed cast so that pc version works
 * 
 * Revision 1.1  90/08/13  15:27:33  arg
 * Initial revision
 * 
 *                                                                           *
 *  1) 14 Mar 90  jsc  Created                                               *
 *                                                                           *
 *  2)  7 May 90  jsc  Flex feature added                                    *
 *                                                                           *
 *  3) 23 Jul 90  jsc  Modified do_char() to execute character string        *
 *                     decryption at run time.                               *
 *                                                                           *
 ****************************************************************************/

static char     rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/Type1/tr_mkchr.c,v 1.1 97/04/18 11:45:17 newdeal Exp $";

#include "spdo_prv.h"		/* General definitions for Speedo */
#include "fino.h"
#include "type1.h"
/*
 * #include "spdo_add.h"           /* Additional definitions for output
 * modules  
 */
#include <math.h>
#include "fnt_a.h"
#include "tr_fdata.h"

#define   DEBUG      0
#define   DBGOPND    0		/* Print trace of operands */

#if DEBUG
#ifdef __GEOS__
#define SHOW(X)
#define SHOWR(X)
#else
#include <stdio.h>
#define SHOW(X) printf("X = %d\n", X)
#define SHOWR(X) printf("X = %f\n", X)
#endif
#else
#define SHOW(X)
#define SHOWR(X)
#endif
#define   ABS(a)    (((a) >  0) ? (a) : -(a))
#define   MAX(a, b) ((a) > (b) ? (a) : (b))
#define NOSETWIDTH 0X01		/* Inhibit set width output during do_char
				 * operation */
#define SUBCHARMODE 0X02	/* Sub-character mode for do_char operation */


/* Character program string decryption constants */
static unsigned short int makechr_decrypt_c1 = 52845;
static unsigned short int makechr_decrypt_c2 = 22719;

#define CLEAR_STACK sp_globals.processor.type1.stack_top = sp_globals.processor.type1.stack_bottom	/* Clear BuildChar stack */
#define FIRST_ARG sp_globals.processor.type1.stack_next = sp_globals.processor.type1.stack_bottom;	/* Start reading arguments
						 * from stack bottom */
#define GET_ARG (sp_globals.processor.type1.stack_next++)->i_value	/* Read argument from BuildChar stack
					 * bottom upwards */
#if 0
#define PUSH  *(sp_globals.processor.type1.stack_top++) =	/* Push value onto stack */
#endif
#define POP   *(--sp_globals.processor.type1.stack_top)	/* Pop value from stack */
#define POPR  (--sp_globals.processor.type1.stack_top)->r_value	/* Pop value from stack */
#define POPI  (--sp_globals.processor.type1.stack_top)->i_value	/* Pop value from stack */

#if PROTOTYPE
#if NAME_STRUCT
extern CHARACTERNAME  *charname_tbl[];
extern CHARACTERNAME   charname_structs[];
#else
extern CHARACTERNAME  *charname_tbl[];
#endif
#else
extern CHARACTERNAME  *charname_tbl[];
#endif


#ifdef OLDWAY
static fix31    X_orus, Y_orus;	/* Current point in outline units */
static fix31    X, Y;		/* Current point in character coordinates */
static point_t  P0;		/* Point at start of current contour */
static point_t  Pmin, Pmax;	/* Transformed bounding box */
static fix15    flex_count;	/* Count of flex points accumulated */
static boolean  flex_active;	/* Flex mechanism active */
static fix31    flex_X[7];	/* Flex X coordinates */
static fix31    flex_Y[7];	/* Flex Y coordinates */
static fix15    shift_down;
static fix31    shift_rnd;
static fix15    mk_shift;	/* Fixed point shift for mult to sub-pixels */
static fix31    mk_rnd;		/* 0.5 in multiplier units */
static fix31    mk_onepix;
static fix31    tr_flex;

/* Pointers to selected output module */
static
boolean(*init_out) ();
static
boolean(*begin_char) ();
static void     (*begin_sub_char) ();
static void     (*begin_contour) ();
static void     (*curve) ();
static void     (*line) ();
static void     (*closepath) ();
static void     (*end_sub_char) ();
static
boolean(*end_char) ();

/* Stack mechanism for BuildChar command interpretation */

static stack_item stack[20];	/* BuildChar stack */
static stack_item *stack_top;	/* Top of BuildChar stack */
static stack_item *stack_next;	/* Current argument access to BuildChar stack */
static stack_item *stack_bottom = stack;	/* Bottom of BuildChar stack */
fix31           other_args[MAXOTHERARGS];	/* Argument stack for
						 * callothersubr and pop
						 * operation */
fix15           no_other_args;	/* Number of arguments on other args stack */
ufix8          STACKFAR*current_font;	/* global current font pointer */
/* current point in sub-pixels */
static fix15    cur_spxl_x, cur_spxl_y;
#endif /* OLDWAY */

/* static function prototypes: */
static	unsigned char do_char PROTO((PROTO_DECL2 ufix8 STACKFAR*charstring,ufix8 flags));
static	void call_other_subr PROTO((PROTO_DECL2 fix15 i));
static	unsigned char do_begin_char PROTO((PROTO_DECL2 fix31 wx,fix31 wy,ufix8 flags));
static	void do_move PROTO((PROTO_DECL2 fix31 x,fix31 y));
static	void do_line PROTO((PROTO_DECL2 fix31 x,fix31 y));
static	void do_curve PROTO((PROTO_DECL2 fix31 x1,fix31 y1,fix31 x2,fix31 y2,fix31 x3,fix31 y3));
static	void do_closepath PROTO((PROTO_DECL1));
static void setup_constants PROTO((PROTO_DECL2 fbbox_t STACKFAR* font_bbox, real STACKFAR*matrix));


FUNCTION void
tr_init(PARAMS1)
GDECL
{
	int             i;

#if PROTOTYPE
	sp_globals.processor.type1.current_font = NULL;
#if NAME_STRUCT
	for (i = 0; i < 256; i++)
		charname_tbl[i] = (CHARACTERNAME STACKFAR*)&charname_structs[i];
#endif
#endif
	sp_globals.processor.type1.stack_bottom = sp_globals.processor.type1.stack;	/* Bottom of BuildChar stack */
}


FUNCTION boolean
tr_set_specs(PARAMS2 specs_flags, matrix, font_ptr)
GDECL
ufix32 specs_flags;
real STACKFAR*matrix;
ufix8 STACKFAR*font_ptr;
{
	fbbox_t        STACKFAR*font_bbox;	/* Fontwide bounding box for current
					 * font */
	fix15           i;
	specs_t         specs;
	out_strk_info_t out_strk_info;

	/* Stroke output module information structure */
	point_t         Psw;	/* Transformed escapement vector */

	fbbox_t        STACKFAR*tr_get_font_bbox();
	void            init_trans_a();
	void            setup_constants();
	char           STACKFAR*tr_get_font_name();
	fix15           tr_get_paint_type();
	CHARACTERNAME  STACKFAR*tr_encode();
	real            font_matrix[6];
	real            new_matrix[6];
	ufix16          mode;

	mode = (ufix16) specs_flags & 0x0007;
	sp_globals.curves_out = specs_flags & CURVES_OUT;

	sp_globals.processor.type1.current_font = (font_data *)font_ptr;

	specs.flags = specs_flags;

	tr_get_font_matrix(PARAMS2 (real STACKFAR*)font_matrix);

	/* multiply the input matrix by the font matrix */
	/*
	 * --     --    --     --      --              -- |a   b   0| |g   h  
	 * 0| |ag+bi    ah+bj   0| |c   d   0|  |i   j   0| =  |cg+di   ch+dj  
	 * 0| |e   f   1|  |k   l   1|    |eg+fi+k  eh+fj+l 1| --    --    --    
	 * --      --              -- 
	 */

	new_matrix[0] = (font_matrix[0] * matrix[0]) + (font_matrix[1] * matrix[2]);
	new_matrix[1] = (font_matrix[0] * matrix[1]) + (font_matrix[1] * matrix[3]);
	new_matrix[2] = (font_matrix[2] * matrix[0]) + (font_matrix[3] * matrix[2]);
	new_matrix[3] = (font_matrix[2] * matrix[1]) + (font_matrix[3] * matrix[3]);
	new_matrix[4] = (font_matrix[4] * matrix[0]) + (font_matrix[5] * matrix[2]) + matrix[4];
	new_matrix[5] = (font_matrix[4] * matrix[1]) + (font_matrix[5] * matrix[3]) + matrix[5];


	font_bbox = tr_get_font_bbox(PARAMS1);	/* Get fontwide bounding box from
					 * font */
	init_trans_a(PARAMS2 (real STACKFAR*)new_matrix, (fbbox_t STACKFAR*)font_bbox);	/* Initialize transformation
						 * mechanism */

	/* Set up fixed point arithmetic constants */
	setup_constants(PARAMS2 font_bbox, (real STACKFAR*)new_matrix);

#if DEBUG
	printf("FontName = %s\n", tr_get_font_name(PARAMS1));
	printf("FontBBox = { %3.1f %3.1f %3.1f %3.1f}\n",
	font_bbox->xmin, font_bbox->ymin, font_bbox->xmax, font_bbox->ymax);
	/* printf("PaintType = %d\n", tr_get_paint_type(PARAMS1)); */
	printf("\nEncoding vector\n");
	for (i = 0; i < 256; i++) {
		printf("%3d: %s\n", i, tr_encode(PARAMS2 i));
	}
#endif

	sp_globals.output_mode = (fix15) mode;

	switch (mode) {
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
		sp_report_error(PARAMS2 8);/* Unsupported mode requested */
		return (FALSE);
	}

	if (!fn_init_out( (specs_t GLOBALFAR *)&specs)) {	/* Initialize selected output module */
		sp_report_error(PARAMS2 5);/* Specs rejected by output module */
		return (FALSE);
	}
	return (TRUE);
}


#if RESTRICTED_ENVIRON
FUNCTION boolean 
tr_make_char(PARAMS2 font_ptr, charname)
	GDECL
	ufix8          STACKFAR*font_ptr;
	CHARACTERNAME  STACKFAR*charname;
#else
FUNCTION boolean 
tr_make_char(PARAMS2 charname)
	GDECL
	CHARACTERNAME  *charname;
#endif
{
	unsigned char  STACKFAR*charstring;
	ufix8           do_char_flags;	/* Flags controlling operation of
					 * do_char() */

	unsigned char  STACKFAR*tr_get_chardef();
	boolean         do_char();
#if REENTRANT_ALLOC
#if INCL_BLACK || INCL_SCREEN || INCL_2D
intercepts_t intercepts;
sp_globals.intercepts = &intercepts;
#endif
#endif

#if RESTRICTED_ENVIRON
	sp_globals.processor.type1.current_font = font_ptr;
#endif

#if DEBUG
	printf("\nmake_char(%s)\n", charname);
#endif
	/* Get character program string for specified char */
	if ((charstring = tr_get_chardef(PARAMS2 charname)) == NULL)
		return (FALSE);
	sp_globals.processor.type1.X = 0;
	sp_globals.processor.type1.Y = 0;
	do_char_flags = 0;	/* Enable set width, sp_globals.processor.type1.begin_char; signal root
				 * char */
	if (!do_char(PARAMS2 charstring, do_char_flags))	/* Execute character
							 * program string */
		return (FALSE);
	while (!fn_end_char()) {
#if DEBUG
		printf("Repeat scan requested\n");
#endif
#if RESTRICTED_ENVIRON
		/* get character program string for specified character */
		if ((charstring = tr_get_chardef(PARAMS2 charname)) == NULL)
			return (FALSE);
#endif
		sp_globals.processor.type1.X = 0;
		sp_globals.processor.type1.Y = 0;
		do_char_flags = NOSETWIDTH;	/* Inhibit set width,
						 * sp_globals.processor.type1.begin_char during repeat
						 * scans */
		if (!do_char(PARAMS2 charstring, do_char_flags))	/* Repeat char prog
								 * string execution */
			return (FALSE);
	}
	return (TRUE);
}

FUNCTION void 
do_pop(PARAMS2 value)
GDECL
real value;
{
	sp_globals.processor.type1.stack_top->i_value = value ;
	sp_globals.processor.type1.stack_top->r_value = (real) sp_globals.processor.type1.stack_top->i_value;
	sp_globals.processor.type1.stack_top++;
	return ;
}

FUNCTION boolean
do_char(PARAMS2 charstring, flags)
	GDECL
	ufix8          STACKFAR*charstring;
	ufix8           flags;	/* Control flags:                           */
/* Bit 0: Disable set width output       */
/* Bit 1: Sub-character mode             */
{
	fix15           i, n;
	ufix16          decrypt_r;	/* Current decryption key */
	fix15           no_bytes;	/* Number of bytes processed in char
					 * prog string */
	fix15           state;	/* Multi-byte operator and operand decoding
				 * state */
	ufix8           byte;	/* Byte read from character program string */
	fix31           operand;/* Accumulator for multi-byte operand values */
	fix31           wx, wy;	/* Escapement vector in character units */
	ufix8          STACKFAR*sub_charstring;	/* Pointer to charstring for compound
					 * char element */
	CHARACTERNAME  STACKFAR*charname;	/* Character name string for compoune
					 * char element */
	fix15           subr_depth = 0;	/* Current subr depth */
	ufix8          STACKFAR*ra_stack[MAXSUBRDEPTH];	/* Return address stack for
						 * subrs */
	ufix16          decrypt_r_stack[MAXSUBRDEPTH];	/* Decryption key stack
							 * for subrs */
	fix15           no_bytes_stack[MAXSUBRDEPTH];	/* Byte count stack for
							 * subrs */
	real            r_arg1, r_arg2;
	fix31           arg1, arg2, arg3, arg4, arg5, arg6;
	/* Arguments read from BuildChar stack */
	ufix8           sub_flags;	/* Control flags for sub_character
					 * execution */
	fix31           sbx, sby;	/* X and Y components of left
					 * sidebearing */

	CHARACTERNAME  STACKFAR*tr_encode();	/* Get character name for specified
					 * char code */
	unsigned char  STACKFAR*tr_get_chardef();	/* get character program
						 * string */
	unsigned char  STACKFAR*tr_get_subr();	/* Get subr string */
	void            clear_constraints();	/* Reset hint constraint list */
	void            call_other_subr();	/* Call othersubr */
	void            do_hstem(PARAMS2);	/* Execute hstem hint */
	void            do_hstem3();	/* Execute hstem3 hint */
	void            do_vstem();	/* Execute vstem hint */
	void            do_vstem3();	/* Execute vstem3 hint */
	boolean         do_begin_char();	/* Signal start of character
						 * data */
	void            do_move();	/* Execute moveto operation */
	void            do_line();	/* Execute lineto operation */
	void            do_curve();	/* Execute curveto operation */
	void            do_closepath();	/* Execute closepath operation */
	fix15           tr_get_leniv();
	fix15           leniv;

	state = 0;
	CLEAR_STACK;		/* Start with empty BuildChar stack */
	sp_globals.processor.type1.flex_active = FALSE;
	clear_constraints(PARAMS1);	/* Reset hint constraint list */
	decrypt_r = 4330;	/* Initialize decryption */
	no_bytes = 0;		/* Initialize byte count */
	leniv = tr_get_leniv(PARAMS1);

	while (TRUE) {		/* Loop for character program string */
		byte = *charstring ^ (decrypt_r >> 8);	/* Decrypt byte from
							 * char prog string */
		decrypt_r = (*charstring + decrypt_r) * makechr_decrypt_c1 + makechr_decrypt_c2;
		/* Update decryption key */
		charstring++;	/* Update byte pointer */

		if (no_bytes++ < leniv)	/* Discard first "leniv" bytes of
					 * char prog string */
			continue;

		switch (state) {
		case 0:	/* Initial state */
			if (byte < 32) {	/* Command? */
				switch (byte) {
				case 1:	/* hstem */
					FIRST_ARG;
					arg1 = GET_ARG;	/* y: Lower edge of
							 * horizontal stroke */
					arg2 = GET_ARG;	/* dy: Thickness of
							 * stroke */
					CLEAR_STACK;
#if DEBUG
					printf("hstem(%3.1f, %3.1f)\n", (real) (sby + arg1) / 16.0, (real) (sby + arg1 + arg2) / 16.0);
#endif
					do_hstem(PARAMS2 sby, arg1, arg2);
					break;

				case 3:	/* vstem */
					FIRST_ARG;
					arg1 = GET_ARG;	/* x: Left edge of
							 * vertical stroke */
					arg2 = GET_ARG;	/* dx: Thickness of
							 * stroke */
					CLEAR_STACK;
#if DEBUG
					printf("vstem(%3.1f, %3.1f)\n", (real) (sbx + arg1) / 16.0, (real) (sbx + arg1 + arg2) / 16.0);
#endif
					do_vstem(PARAMS2 sbx, arg1, arg2);
					break;

				case 4:	/* vmoveto */
					FIRST_ARG;
					sp_globals.processor.type1.Y += GET_ARG;	/* dy */
					CLEAR_STACK;
#if DEBUG
					printf("vmoveto(%3.1f, %3.1f)\n", (real) sp_globals.processor.type1.X / 16.0, (real) sp_globals.processor.type1.Y / 16.0);
#endif
					do_move(PARAMS2 sp_globals.processor.type1.X, sp_globals.processor.type1.Y);
					break;

				case 5:	/* rlineto */
					FIRST_ARG;
					sp_globals.processor.type1.X += GET_ARG;	/* dx */
					sp_globals.processor.type1.Y += GET_ARG;	/* dy */
					CLEAR_STACK;
#if DEBUG
					printf("rlineto(%3.1f, %3.1f)\n", (real) sp_globals.processor.type1.X / 16.0, (real) sp_globals.processor.type1.Y / 16.0);
#endif
					do_line(PARAMS2 sp_globals.processor.type1.X, sp_globals.processor.type1.Y);
					break;

				case 6:	/* hlineto */
					FIRST_ARG;
					sp_globals.processor.type1.X += GET_ARG;	/* dx */
					CLEAR_STACK;
#if DEBUG
					printf("hlineto(%3.1f, %3.1f)\n", (real) sp_globals.processor.type1.X / 16.0, (real) sp_globals.processor.type1.Y / 16.0);
#endif
					do_line(PARAMS2 sp_globals.processor.type1.X, sp_globals.processor.type1.Y);
					break;

				case 7:	/* vlineto */
					FIRST_ARG;
					sp_globals.processor.type1.Y += GET_ARG;	/* dy */
					CLEAR_STACK;
#if DEBUG
					printf("vlineto(%3.1f, %3.1f)\n", (real) sp_globals.processor.type1.X / 16.0, (real) sp_globals.processor.type1.Y / 16.0);
#endif
					do_line(PARAMS2 sp_globals.processor.type1.X, sp_globals.processor.type1.Y);
					break;

				case 8:	/* rrcurveto */
					FIRST_ARG;
					arg1 = sp_globals.processor.type1.X + GET_ARG;	/* dx1 */
					arg2 = sp_globals.processor.type1.Y + GET_ARG;	/* dy1 */
					arg3 = arg1 + GET_ARG;	/* dx2 */
					arg4 = arg2 + GET_ARG;	/* dy2 */
					sp_globals.processor.type1.X = arg3 + GET_ARG;	/* dx3 */
					sp_globals.processor.type1.Y = arg4 + GET_ARG;	/* dy3 */
					CLEAR_STACK;
#if DEBUG
					printf("rrcurveto(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n",
					       (real) arg1 / 16.0, (real) arg2 / 16.0, (real) arg3 / 16.0, (real) arg4 /
						   16.0, (real) sp_globals.processor.type1.X / 16.0, (real) sp_globals.processor.type1.Y / 16.0);
#endif
					do_curve(PARAMS2 arg1, arg2, arg3, arg4, sp_globals.processor.type1.X, sp_globals.processor.type1.Y);
					break;

				case 9:	/* closepath */
#if DEBUG
					printf("closepath\n");
#endif
					CLEAR_STACK;
					do_closepath(PARAMS1);
					break;

				case 10:	/* callsubr */
					arg1 = POPI;
#if DEBUG
					printf("callsubr(%d)\n", arg1 >> 4);
					if (subr_depth >= MAXSUBRDEPTH) {
						printf("*** Subr depth overflow\n");
						return (FALSE);
					}
#endif
					ra_stack[subr_depth] = charstring;	/* Save pointer to next
										 * byte */
					decrypt_r_stack[subr_depth] = decrypt_r;	/* Save decryption key */
					no_bytes_stack[subr_depth] = no_bytes;	/* Save byte count */
					subr_depth++;	/* Increment subr depth
							 * count */
					charstring = tr_get_subr(PARAMS2 arg1 >> 4);	/* Point to start of
										 * subr */
					decrypt_r = 4330;	/* Initialize decryption
								 * key for subr */
					no_bytes = 0;	/* Initialize byte count
							 * for subr */
					break;

				case 11:	/* return */
#if DEBUG
					printf("return\n");
#endif
					subr_depth--;	/* Decrement subr depth
							 * count */
					charstring = ra_stack[subr_depth];	/* Restore pointer to
										 * next byte */
					decrypt_r = decrypt_r_stack[subr_depth];	/* Restore decryption
											 * key */
					no_bytes = no_bytes_stack[subr_depth];	/* Restore byte count */
					break;

				case 12:	/* First byte of 2-byte
						 * command */
					state = 1;
					break;

				case 13:	/* hsbw */
					FIRST_ARG;
					arg1 = GET_ARG;	/* sbx: X coordinate of
							 * left sidebearing */
					arg2 = GET_ARG;	/* wx: X coordinate of
							 * character width
							 * vector */
					CLEAR_STACK;
#if DEBUG
					printf("hsbw(%3.1f, %3.1f)\n", (real) arg1 / 16.0, (real) arg2 / 16.0);
#endif
					sp_globals.processor.type1.X += arg1;
					sbx = sp_globals.processor.type1.X;
					sby = sp_globals.processor.type1.Y;

					if (!do_begin_char(PARAMS2 arg2, (fix31) 0, flags)) {	/* Signal start of char
											 * or sub-char */
#if DEBUG
						printf("Scan aborted by sp_globals.processor.type1.begin_char()\n");
#endif
						return (FALSE);
					}
					break;

				case 14:	/* endchar */
					CLEAR_STACK;
#if DEBUG
					printf("endchar\n");
#endif
					return (TRUE);

				case 21:	/* rmoveto */
					FIRST_ARG;
					sp_globals.processor.type1.X += GET_ARG;	/* dx */
					sp_globals.processor.type1.Y += GET_ARG;	/* dy */
					CLEAR_STACK;
#if DEBUG
					printf("rmoveto(%3.1f, %3.1f)\n", (real) sp_globals.processor.type1.X / 16.0, (real) sp_globals.processor.type1.Y / 16.0);
#endif
					do_move(PARAMS2 sp_globals.processor.type1.X, sp_globals.processor.type1.Y);
					break;

				case 22:	/* hmoveto */
					FIRST_ARG;
					sp_globals.processor.type1.X += GET_ARG;	/* dx */
					CLEAR_STACK;
#if DEBUG
					printf("hmoveto(%3.1f, %3.1f)\n", (real) sp_globals.processor.type1.X / 16.0, (real) sp_globals.processor.type1.Y / 16.0);
#endif
					do_move(PARAMS2 sp_globals.processor.type1.X, sp_globals.processor.type1.Y);
					break;

				case 30:	/* vhcurveto */
					FIRST_ARG;
					arg1 = sp_globals.processor.type1.X;
					arg2 = sp_globals.processor.type1.Y + GET_ARG;	/* dy1 */
					arg3 = arg1 + GET_ARG;	/* dx2 */
					arg4 = arg2 + GET_ARG;	/* dy2 */
					sp_globals.processor.type1.X = arg3 + GET_ARG;	/* dx3 */
					sp_globals.processor.type1.Y = arg4;
					CLEAR_STACK;
#if DEBUG
					printf("vhcurveto(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n",
					       (real) arg1 / 16.0, (real) arg2 / 16.0, (real) arg3 / 16.0, (real) arg4 /
						   16.0, (real) sp_globals.processor.type1.X / 16.0, (real) sp_globals.processor.type1.Y / 16.0);
#endif
					do_curve(PARAMS2 arg1, arg2, arg3, arg4, sp_globals.processor.type1.X, sp_globals.processor.type1.Y);
					break;

				case 31:	/* hvcurveto */
					FIRST_ARG;
					arg1 = sp_globals.processor.type1.X + GET_ARG;	/* dx1 */
					arg2 = sp_globals.processor.type1.Y;
					arg3 = arg1 + GET_ARG;	/* dx2 */
					arg4 = arg2 + GET_ARG;	/* dy2 */
					sp_globals.processor.type1.X = arg3;
					sp_globals.processor.type1.Y = arg4 + GET_ARG;	/* dy3 */
					CLEAR_STACK;
#if DEBUG
					printf("hvcurveto(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n",
					       (real) arg1 / 16.0, (real) arg2 / 16.0, (real) arg3 / 16.0, (real) arg4 /
						   16.0, (real) sp_globals.processor.type1.X / 16.0, (real) sp_globals.processor.type1.Y / 16.0);
#endif
					do_curve(PARAMS2 arg1, arg2, arg3, arg4, sp_globals.processor.type1.X, sp_globals.processor.type1.Y);
					break;

				default:
					CLEAR_STACK;
#if DEBUG
					printf("*** Unknown command %d\n", byte);
#endif
					break;
				}
			} else if (byte < 247) {	/* 1-byte integer? */
				operand = ((fix31) byte - 139L);
#if DBGOPND
				printf("%d, ", operand);
#endif
				sp_globals.processor.type1.stack_top->i_value = operand << 4;
				sp_globals.processor.type1.stack_top->r_value = (real) sp_globals.processor.type1.stack_top->i_value;
				sp_globals.processor.type1.stack_top++;
			} else if (byte < 251) {	/* 2-byte positive
							 * integer? */
				operand = ((fix31) byte - 247L) << 8;
				state = 2;
			} else if (byte < 255) {	/* 2-byte negative
							 * integer? */
				operand = -(((fix31) byte - 251L) << 8);
				state = 3;
			} else {/* 5-byte integer? */
				operand = 0;
				state = 7;
			}
			break;

		case 1:	/* Second byte of 2-byte command */
			switch (byte) {
			case 0:/* dotsection */
				CLEAR_STACK;
#if DEBUG
				printf("dotsection\n");
#endif
				break;

			case 1:/* vstem3 */
				FIRST_ARG;
				arg1 = GET_ARG;	/* x1 */
				arg2 = GET_ARG;	/* dx1 */
				arg3 = GET_ARG;	/* x2 */
				arg4 = GET_ARG;	/* dx2 */
				arg5 = GET_ARG;	/* x3 */
				arg6 = GET_ARG;	/* dx3 */
				CLEAR_STACK;
#if DEBUG
				printf("vstem3(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n",
				       (real) (sbx + arg1) / 16.0, (real) (sbx + arg1 + arg2) / 16.0,
				       (real) (sbx + arg3) / 16.0, (real) (sbx + arg3 + arg4) / 16.0,
				       (real) (sbx + arg5) / 16.0, (real) (sbx + arg5 + arg6) / 16.0);
#endif
				do_vstem3(PARAMS2 sbx, arg1, arg2, arg3, arg4, arg5, arg6);
				break;

			case 2:/* hstem3 */
				FIRST_ARG;
				arg1 = GET_ARG;	/* y1 */
				arg2 = GET_ARG;	/* dy1 */
				arg3 = GET_ARG;	/* y2 */
				arg4 = GET_ARG;	/* dy2 */
				arg5 = GET_ARG;	/* y3 */
				arg6 = GET_ARG;	/* dy3 */
				CLEAR_STACK;
#if DEBUG
				printf("hstem3(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n",
				       (real) (sby + arg1) / 16.0, (real) (sby + arg1 + arg2) / 16.0,
				       (real) (sby + arg3) / 16.0, (real) (sby + arg3 + arg4) / 16.0,
				       (real) (sby + arg5) / 16.0, (real) (sby + arg5 + arg6) / 16.0);
#endif
				do_hstem3(PARAMS2 sby, arg1, arg2, arg3, arg4, arg5, arg6);
				break;

			case 6:/* seac */
				FIRST_ARG;
				arg1 = GET_ARG;	/* asb: X component of left
						 * sidebearing of accent */
				arg2 = GET_ARG;	/* adx: X shift for accent
						 * placement */
				arg3 = GET_ARG;	/* ady: Y shift for accent
						 * placement */
				arg4 = GET_ARG;	/* bchar: Base character code */
				arg5 = GET_ARG;	/* achar: Accent character
						 * code */
				CLEAR_STACK;
#if DEBUG
				printf("seac(%3.1f, %3.1f, %3.1f, %d, %d)\n", (real) arg1 / 16.0, (real) arg2 / 16.0, (real) arg3 / 16.0, (real) arg4 / 16.0, (real) arg5 / 16.0);
#endif
				charname = charname_tbl[arg4 >> 4];	/* Look up name of base
									 * character */
				if (( sub_charstring = tr_get_chardef(PARAMS2 charname))==NULL )	/* Get charstring for
										 * base character */
                                    return (FALSE) ;
				sp_globals.processor.type1.X = 0;
				sp_globals.processor.type1.Y = 0;
				sub_flags = SUBCHARMODE | NOSETWIDTH;
				if (!do_char(PARAMS2 sub_charstring, sub_flags))	/* Execute base
										 * character */
					return (FALSE);
				fn_end_sub_char();

				charname = charname_tbl[arg5 >> 4];
				if (( sub_charstring = tr_get_chardef(PARAMS2 charname))==NULL )
                                    return (FALSE) ;
				sp_globals.processor.type1.X = sbx - arg1 + arg2;
				sp_globals.processor.type1.Y = arg3;
				sub_flags = SUBCHARMODE | NOSETWIDTH;
				if (!do_char(PARAMS2 sub_charstring, sub_flags))	/* Execute accent
										 * character */
					return (FALSE);
				fn_end_sub_char();

				return (TRUE);

			case 7:/* sbw */
				FIRST_ARG;
				arg1 = GET_ARG;	/* sbx: X coordinate of left
						 * sidebearing */
				arg2 = GET_ARG;	/* sby: Y coordinate of left
						 * sidebearing */
				arg3 = GET_ARG;	/* wx: X coordinate of
						 * character width vector */
				arg4 = GET_ARG;	/* wy: Y coordinate of
						 * character width vector */
				CLEAR_STACK;
#if DEBUG
				printf("sbw(%3.1f, %3.1f, %3.1f, %3.1f)\n", (real) arg1 / 16.0, (real) arg2 / 16.0, (real) arg3 / 16.0, (real) arg4 / 16.0);
#endif
				sp_globals.processor.type1.X += arg1;
				sp_globals.processor.type1.Y += arg2;
				sbx = sp_globals.processor.type1.X;
				sby = sp_globals.processor.type1.Y;

				if (!do_begin_char(PARAMS2 arg3, arg4, flags)) {	/* Signal start of char
										 * or sub-char */
#if DEBUG
					printf("Scan aborted by sp_globals.processor.type1.begin_char()\n");
#endif
					return (FALSE);
				}
				break;

			case 12:	/* div */
				r_arg2 = POPR;
				r_arg1 = POPR;
#if DEBUG
				printf("div(%3.1f, %3.1f)\n", r_arg1 / 16.0, r_arg2 / 16.0);
#endif
				sp_globals.processor.type1.stack_top->r_value = (r_arg1 * 16.0) / r_arg2;
				sp_globals.processor.type1.stack_top->i_value = (fix31) sp_globals.processor.type1.stack_top->r_value;
				sp_globals.processor.type1.stack_top++;
				break;

			case 16:	/* callothersubr */
				arg1 = POPI;	/* othersubr # */
				arg2 = POPI;	/* number of args */
				sp_globals.processor.type1.no_other_args = arg2 >> 4;
				for (i = 0; i < sp_globals.processor.type1.no_other_args; i++) {
					arg3 = POPI;	/* number of args */
					sp_globals.processor.type1.other_args[i] = arg3;	/* arguments */
				}
#if DEBUG
				printf("callothersubr(%d, %d", arg1 >> 4, sp_globals.processor.type1.no_other_args);
				for (i = sp_globals.processor.type1.no_other_args - 1; i >= 0; i--) {
					printf(", %3.1f", (real) sp_globals.processor.type1.other_args[i] / 16.0);
				}
				printf(")\n");
#endif
				call_other_subr(PARAMS2 (fix15) arg1 >> 4);
				break;

			case 17:	/* pop */
			{
				real value ;
#if DEBUG
				printf("pop\n");
#endif
                                value = sp_globals.processor.type1.other_args[--sp_globals.processor.type1.no_other_args];
				do_pop(value);
			}
				break;

			case 33:	/* setcurrentpoint */
				FIRST_ARG;
				sp_globals.processor.type1.X = GET_ARG;	/* x */
				sp_globals.processor.type1.Y = GET_ARG;	/* y */
				CLEAR_STACK;
#if DEBUG
				printf("setcurrentpoint(%3.1f, %3.1f)\n", (real) sp_globals.processor.type1.X / 16.0, (real) sp_globals.processor.type1.Y / 16.0);
#endif
				break;

			default:
				CLEAR_STACK;
#if DEBUG
				printf("*** Unknown command 12 %d\n", byte);
#endif
				break;
			}
			state = 0;
			break;

		case 2:	/* Second byte of 2-byte positive integer */
			operand += (fix31) byte + 108L;
#if DBGOPND
			printf("%d, ", operand);
#endif
			sp_globals.processor.type1.stack_top->i_value = operand << 4;
			sp_globals.processor.type1.stack_top->r_value = (real) sp_globals.processor.type1.stack_top->i_value;
			sp_globals.processor.type1.stack_top++;
			state = 0;
			break;

		case 3:	/* Second byte of 2-byte negative integer */
			operand -= (fix31) byte + 108L;
#if DBGOPND
			printf("%d, ", operand);
#endif
			sp_globals.processor.type1.stack_top->i_value = operand << 4;
			sp_globals.processor.type1.stack_top->r_value = (real) sp_globals.processor.type1.stack_top->i_value;
			sp_globals.processor.type1.stack_top++;
			state = 0;
			break;
		case 4:	/* Last byte of 5-byte integer */
			operand = (operand << 8) + (fix31) byte;
#if DBGOPND
			printf("%d, ", operand);
#endif
			sp_globals.processor.type1.stack_top->r_value = (real) operand *16.0;
			sp_globals.processor.type1.stack_top->i_value = operand << 4;
			sp_globals.processor.type1.stack_top++;
			state = 0;
			break;

		default:	/* Other bytes of 5-byte integer */
			operand = (operand << 8) + (fix31) byte;
			state--;
			break;
		}
	}
}


FUNCTION void
call_other_subr(PARAMS2 i)
	GDECL
	fix15           i;
/*
 * Called by do_char() Uses PostScript argument stack sp_globals.processor.type1.other_args[]
 * sp_globals.processor.type1.no_other_args is number of args on stack Top of stack (arg1) is
 * sp_globals.processor.type1.other_args[sp_globals.processor.type1.no_other_args - 1] Bottom of stack is other_args[0] 
 */
{
	fix31           other_arg1;
	fix31           other_arg2;
	fix31           other_arg3;
	fix31           x1, y1;
	fix31           x2, y2;
	fix31           delta;
	fix31           flex_ctrl;
	fix31           temp;

	void            do_trans_a();
	void            do_line();
	void            do_curve();
	void            clear_constraints();	/* Reset hint constraint list */
	void            tr_othersubr();
	font_hints_t   STACKFAR*tr_get_font_hints(), STACKFAR*pfont_hints;
	boolean         well_behaved;
	fix31           flex_feature_height;
#if OSUBR_CALLOUT
#define MAX_OSUBR_ARGS 5
	real            osubr_args[MAX_OSUBR_ARGS];
#endif

	switch (i) {
	case 0:		/* flex_ctrl x y 3 0 callothersubr */
#if OSUBR_CALLOUT
		osubr_args[0] = (real) sp_globals.processor.type1.other_args[--sp_globals.processor.type1.no_other_args];	/* Pop arg1 from other
									 * args stack */
		osubr_args[1] = (real) sp_globals.processor.type1.other_args[sp_globals.processor.type1.no_other_args - 1];
		osubr_args[2] = (real) sp_globals.processor.type1.other_args[sp_globals.processor.type1.no_other_args - 2];
		tr_othersubr(0, 3, osubr_args);
#else
		other_arg1 = sp_globals.processor.type1.other_args[--sp_globals.processor.type1.no_other_args];	/* Pop arg1 from other
								 * args stack */
		other_arg2 = sp_globals.processor.type1.other_args[sp_globals.processor.type1.no_other_args - 1];	/* Leave x at top of
								 * stack */
		other_arg3 = sp_globals.processor.type1.other_args[sp_globals.processor.type1.no_other_args - 2];	/* Leave y in second
								 * place */

#if DEBUG
		if ((ABS(other_arg2 - sp_globals.processor.type1.flex_X[6]) > 1) ||
		    (ABS(other_arg3 - sp_globals.processor.type1.flex_Y[6]) > 1)) {
			printf("*** Flex end point inconsistency\n");
		}
#endif
		if (sp_globals.processor.type1.X_orus == sp_globals.processor.type1.flex_X[6])	/* vertical curve */
			flex_feature_height = ABS(sp_globals.processor.type1.flex_X[3] - sp_globals.processor.type1.flex_X[6]) >> 4;
		else		/* horizontal curve */
			flex_feature_height = ABS(sp_globals.processor.type1.flex_Y[3] - sp_globals.processor.type1.flex_Y[6]) >> 4;
		pfont_hints = tr_get_font_hints(PARAMS1);

		/*
		 * I should never encounter a font with a flex_feature_height
		 * > blue_shift. 
		 */
		/* If I DO encounter such a font - always use curves */
		if ((flex_feature_height) > pfont_hints->blue_shift)
			well_behaved = FALSE;
		else
			well_behaved = TRUE;

		x1 = sp_globals.processor.type1.flex_X[0];
		y1 = sp_globals.processor.type1.flex_Y[0];
		do_trans_a(PARAMS2 (fix31 STACKFAR*)&x1, (fix31 STACKFAR*)&y1);	/* Transform reference point */
		x2 = sp_globals.processor.type1.flex_X[3];
		y2 = sp_globals.processor.type1.flex_Y[3];
		do_trans_a(PARAMS2 (fix31 STACKFAR*)&x2, (fix31 STACKFAR*)&y2);	/* Transform reference point */

		flex_ctrl = other_arg1 * sp_globals.processor.type1.tr_flex;	/* Convert flex control
							 * to device coords */
		delta = ABS(x1 - x2) + ABS(y1 - y2);	/* Difference in device
							 * coords */

		if ((delta >= flex_ctrl) ||	/* Flex feature >= flex
						 * control parameter? */
		    (!well_behaved)) {
			/*
			 * if pixel depth of the curve is only one pixel,
			 * flatten 
			 */
			/* the curve */
#if LOW_RES
			if ((delta < (sp_globals.processor.type1.mk_onepix + (sp_globals.processor.type1.mk_onepix >> 1))) && (well_behaved)) {
				if (sp_globals.processor.type1.flex_Y[0] == sp_globals.processor.type1.flex_Y[6]) {	/* horizontal flex */
					sp_globals.processor.type1.flex_X[1] = sp_globals.processor.type1.flex_X[0];
					sp_globals.processor.type1.flex_X[5] = sp_globals.processor.type1.flex_X[6];
					sp_globals.processor.type1.flex_Y[1] = sp_globals.processor.type1.flex_Y[2] = sp_globals.processor.type1.flex_Y[4] = sp_globals.processor.type1.flex_Y[5] = sp_globals.processor.type1.flex_Y[3];
				} else {	/* vertical flex */
					sp_globals.processor.type1.flex_Y[1] = sp_globals.processor.type1.flex_Y[0];
					sp_globals.processor.type1.flex_Y[5] = sp_globals.processor.type1.flex_Y[6];
					sp_globals.processor.type1.flex_X[1] = sp_globals.processor.type1.flex_X[2] = sp_globals.processor.type1.flex_X[4] = sp_globals.processor.type1.flex_X[5] = sp_globals.processor.type1.flex_X[3];
				}
			}
#endif
			do_curve(PARAMS2 sp_globals.processor.type1.flex_X[1], sp_globals.processor.type1.flex_Y[1],
				 sp_globals.processor.type1.flex_X[2], sp_globals.processor.type1.flex_Y[2],
				 sp_globals.processor.type1.flex_X[3], sp_globals.processor.type1.flex_Y[3]);	/* Output first curve */

			do_curve(PARAMS2 sp_globals.processor.type1.flex_X[4], sp_globals.processor.type1.flex_Y[4],
				 sp_globals.processor.type1.flex_X[5], sp_globals.processor.type1.flex_Y[5],
				 sp_globals.processor.type1.flex_X[6], sp_globals.processor.type1.flex_Y[6]);	/* Output second curve */
		} else {
			do_line(PARAMS2 sp_globals.processor.type1.flex_X[6], sp_globals.processor.type1.flex_Y[6]);	/* Replace curves with
							 * vector */
		}
		sp_globals.processor.type1.flex_active = FALSE;
#endif
		return;

	case 1:
#if OSUBR_CALLOUT
		tr_othersubr(1, 0, NULL);
#else
		sp_globals.processor.type1.flex_count = 0;
		sp_globals.processor.type1.flex_active = TRUE;
#endif
		return;

	case 2:
#if OSUBR_CALLOUT
		osubr_args[0] = (real) sp_globals.processor.type1.X;
		osubr_args[1] = (real) sp_globals.processor.type1.Y;
		tr_othersubr(2, 2, osubr_args);
#else
		sp_globals.processor.type1.flex_X[sp_globals.processor.type1.flex_count] = sp_globals.processor.type1.X;	/* Save 7 flex points */
		sp_globals.processor.type1.flex_Y[sp_globals.processor.type1.flex_count] = sp_globals.processor.type1.Y;
		sp_globals.processor.type1.flex_count++;
#endif
		return;

	case 3:
#if OSUBR_CALLOUT
		tr_othersubr(3, 0, NULL);
#endif
		clear_constraints(PARAMS1);	/* Reset hint constraint list */
		return;

	default:
		return;
	}
}


FUNCTION boolean
do_begin_char(PARAMS2 wx, wy, flags)
	GDECL
	fix31           wx;	/* X component of escapement vector in
				 * character coordinates */
	fix31           wy;	/* Y component of escapement vector in
				 * character coordinates */
	ufix8           flags;	/* Control flags:                           */
/* Bit 0: Disable set width output       */
/* Bit 1: Sub-character mode */
/*
 * Called at the start of each character or sub-character Returns FALSE if
 * scan is to be aborted 
 */
{
	fix31           x = 0;
	fix31           y = 0;
	point_t         P;
	point_t         Psw;	/* Transformed escapement vector */

	void            do_trans_a();

	do_trans_a(PARAMS2 (fix31 STACKFAR*)&x, (fix31 STACKFAR*)&y);	/* Transform character origin */
	do_trans_a(PARAMS2 (fix31 STACKFAR*)&wx, (fix31 STACKFAR*)&wy);	/* Transform end-point of escapement vector */
	Psw.x = (fix15) (((wx - x) + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
	Psw.y = (fix15) (((wy - y) + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);

	if (flags & SUBCHARMODE) {	/* Sub-character mode? */
		fn_begin_sub_char(Psw, sp_globals.processor.type1.Pmin, sp_globals.processor.type1.Pmax);
		return TRUE;
	}
	if (flags & NOSETWIDTH) {	/* Repeat pass of simple character
					 * mode? */
		return TRUE;
	} else {		/* First pass of simple character mode? */
		return fn_begin_char(Psw, sp_globals.processor.type1.Pmin, sp_globals.processor.type1.Pmax);
	}
}



FUNCTION void
do_move(PARAMS2 x, y)
	GDECL
	fix31           x, y;
{
	point_t         P;

	void            do_trans_a();

	if (!sp_globals.processor.type1.flex_active) {
		sp_globals.processor.type1.X_orus = x;	/* save current oru position */
		sp_globals.processor.type1.Y_orus = y;
		do_trans_a(PARAMS2 (fix31 STACKFAR*)&x, (fix31 STACKFAR*)&y);
		sp_globals.processor.type1.P0.x = P.x = (fix15) ((x + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
		sp_globals.processor.type1.P0.y = P.y = (fix15) ((y + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
		sp_globals.processor.type1.cur_spxl_x = sp_globals.processor.type1.P0.x;
		sp_globals.processor.type1.cur_spxl_y = sp_globals.processor.type1.P0.y;

		fn_begin_contour(P, (boolean) (FALSE));	/* Note: inside/outside
								 * is not known */
	}
}


FUNCTION void
do_line(PARAMS2 x, y)
	GDECL
	fix31           x, y;
{
	point_t         P;

	void            do_trans_a();

	sp_globals.processor.type1.X_orus = x;		/* save current oru position */
	sp_globals.processor.type1.Y_orus = y;
	do_trans_a(PARAMS2 (fix31 STACKFAR*)&x, (fix31 STACKFAR*)&y);
	P.x = (fix15) ((x + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
	P.y = (fix15) ((y + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
	fn_line(P);
	sp_globals.processor.type1.cur_spxl_x = P.x;
	sp_globals.processor.type1.cur_spxl_y = P.y;
}



FUNCTION void
do_curve(PARAMS2 x1, y1, x2, y2, x3, y3)
	GDECL
	fix31           x1, y1, x2, y2, x3, y3;
{
	point_t         P1, P2, P3;
	fix15           depth = -1;

	void            do_trans_a();

	sp_globals.processor.type1.X_orus = x3;		/* save current oru position */
	sp_globals.processor.type1.Y_orus = y3;
	do_trans_a(PARAMS2 (fix31 STACKFAR*)&x1, (fix31 STACKFAR*)&y1);
	P1.x = (fix15) ((x1 + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
	P1.y = (fix15) ((y1 + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);

	do_trans_a(PARAMS2 (fix31 STACKFAR*)&x2, (fix31 STACKFAR*)&y2);
	P2.x = (fix15) ((x2 + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
	P2.y = (fix15) ((y2 + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);

	do_trans_a(PARAMS2 (fix31 STACKFAR*)&x3, (fix31 STACKFAR*)&y3);
	P3.x = (fix15) ((x3 + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
	P3.y = (fix15) ((y3 + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);

	if (sp_globals.curves_out)
		fn_curve(P1, P2, P3, depth);
	else
		curve_fill(PARAMS2 P1, P2, P3, depth);
}


/***********************************************************************
 * curve_fill(PARAMS2 P1, P2, P3, depth)
 *
 ***********************************************************************/
FUNCTION void
curve_fill(PARAMS2 P1, P2, P3, depth)
	GDECL
	point_t         P1, P2, P3;
	fix15           depth;
{
	fix31           X0;
	fix31           Y0;
	fix31           X1;
	fix31           Y1;
	fix31           X2;
	fix31           Y2;
	fix31           X3;
	fix31           Y3;

	/* Accumulate actual character extents if required */
#if INCL_BLACK || INCL_SCREEN || INCL_2D || INCL_WHITE
	if (sp_globals.extents_running) {
		if (P3.x > sp_globals.bmap_xmax)
			sp_globals.bmap_xmax = P3.x;
		if (P3.x < sp_globals.bmap_xmin)
			sp_globals.bmap_xmin = P3.x;
		if (P3.y > sp_globals.bmap_ymax)
			sp_globals.bmap_ymax = P3.y;
		if (P3.y < sp_globals.bmap_ymin)
			sp_globals.bmap_ymin = P3.y;
	}
#endif
	X0 = (fix31) sp_globals.processor.type1.cur_spxl_x << sp_globals.poshift;
	Y0 = (fix31) sp_globals.processor.type1.cur_spxl_y << sp_globals.poshift;
	X1 = (fix31) P1.x << sp_globals.poshift;
	Y1 = (fix31) P1.y << sp_globals.poshift;
	X2 = (fix31) P2.x << sp_globals.poshift;
	Y2 = (fix31) P2.y << sp_globals.poshift;
	X3 = (fix31) P3.x << sp_globals.poshift;
	Y3 = (fix31) P3.y << sp_globals.poshift;

	scan_curve_fill(PARAMS2 X0, Y0, X1, Y1, X2, Y2, X3, Y3);
}

/***********************************************************************
 * scan_curve_fill(PARAMS2 X0,Y0,X1,Y1,X2,Y2,X3,Y3)
 *
 * Called for each curve in the transformed character if curves out
 * enabled
 *
 ***********************************************************************/
FUNCTION void
scan_curve_fill(PARAMS2 X0, Y0, X1, Y1, X2, Y2, X3, Y3)
	GDECL
	fix31           X0, Y0, X1, Y1, X2, Y2, X3, Y3;
{
	fix31           Pmidx;
	fix31           Pmidy;
	fix31           Pctrl1x;
	fix31           Pctrl1y;
	fix31           Pctrl2x;
	fix31           Pctrl2y;
	fix31           tx, ty, px, py, del_x, del_y, dist;
	point_t         P_t;
	fix31           bx1, by1, bx2, by2, d1, d2;

	bx1 = (((X3 + X0) >> 1) + X0) >> 1;
	by1 = (((Y3 + Y0) >> 1) + Y0) >> 1;
	bx2 = (((X3 + X0) >> 1) + X3) >> 1;
	by2 = (((Y3 + Y0) >> 1) + Y3) >> 1;


	del_x = ABS(bx1 - X1);
	del_y = ABS(by1 - Y1);
	d1 = (del_x > del_y) ? del_x + (del_y >> 1) : del_y + (del_x >> 1);
	del_x = ABS(bx2 - X2);
	del_y = ABS(by2 - Y2);
	d2 = (del_x > del_y) ? del_x + (del_y >> 1) : del_y + (del_x >> 1);

	dist = d1 > d2 ? d1 : d2;

	Pmidx = (X0 + (X1 + X2) * 3 + X3 + 4) >> 3;
	Pmidy = (Y0 + (Y1 + Y2) * 3 + Y3 + 4) >> 3;

	if ((dist >> 16) == 0) {
		P_t.x = (fix15) (Pmidx >> sp_globals.poshift);
		P_t.y = (fix15) (Pmidy >> sp_globals.poshift);
		fn_line(P_t);
		P_t.x = (fix15) (X3 >> sp_globals.poshift);
		P_t.y = (fix15) (Y3 >> sp_globals.poshift);
		fn_line(P_t);
		sp_globals.processor.type1.cur_spxl_x = P_t.x;
		sp_globals.processor.type1.cur_spxl_y = P_t.y;
		return;
	}
	Pctrl1x = (X0 + X1 + 1) >> 1;
	Pctrl1y = (Y0 + Y1 + 1) >> 1;
	Pctrl2x = (X0 + (X1 << 1) + X2 + 2) >> 2;
	Pctrl2y = (Y0 + (Y1 << 1) + Y2 + 2) >> 2;
	scan_curve_fill(PARAMS2 X0, Y0, Pctrl1x, Pctrl1y, Pctrl2x, Pctrl2y, Pmidx, Pmidy);

	Pctrl1x = (X1 + (X2 << 1) + X3 + 2) >> 2;
	Pctrl1y = (Y1 + (Y2 << 1) + Y3 + 2) >> 2;
	Pctrl2x = (X2 + X3 + 1) >> 1;
	Pctrl2y = (Y2 + Y3 + 1) >> 1;
	scan_curve_fill(PARAMS2 Pmidx, Pmidy, Pctrl1x, Pctrl1y, Pctrl2x, Pctrl2y, X3, Y3);
}




FUNCTION void
do_closepath(PARAMS1)
GDECL
{
	fn_line(sp_globals.processor.type1.P0);		/* Vector to start point of current contour */
	fn_end_contour();
}


FUNCTION void
setup_constants(PARAMS2 font_bbox, matrix)
GDECL
fbbox_t STACKFAR* font_bbox;
real STACKFAR*matrix;
/*
 * Sets up fixed point arithmetic constants Sets up transformed bounding box
 * sp_globals.processor.type1.Pmin and sp_globals.processor.type1.Pmax Sets tcb.mirror (-1 if mirror transformation, +1 otherwise)
 * Uses fontwide bounding box and local matrix 
 */
{
	fix31           x, y;
	fix31           xmin, xmax, ymin, ymax;
	fix31           maxabs;
	fix15           shift_oru;
	real            x_test, max_test;

	void            do_trans_a();
	fix15           set_shift_const();

	x = (fix31) (font_bbox->xmin * 16.0);
	y = (fix31) (font_bbox->ymin * 16.0);
	do_trans_a(PARAMS2 (fix31 STACKFAR*)&x, (fix31 STACKFAR*)&y);
	xmin = xmax = x;
	ymin = ymax = y;

	x = (fix31) (font_bbox->xmax * 16.0);
	y = (fix31) (font_bbox->ymin * 16.0);
	do_trans_a(PARAMS2 (fix31 STACKFAR*)&x, (fix31 STACKFAR*)&y);
	if (x > xmax)
		xmax = x;
	if (x < xmin)
		xmin = x;
	if (y > ymax)
		ymax = y;
	if (y < ymin)
		ymin = y;

	x = (fix31) (font_bbox->xmax * 16.0);
	y = (fix31) (font_bbox->ymax * 16.0);
	do_trans_a(PARAMS2 (fix31 STACKFAR*)&x, (fix31 STACKFAR*)&y);
	if (x > xmax)
		xmax = x;
	if (x < xmin)
		xmin = x;
	if (y > ymax)
		ymax = y;
	if (y < ymin)
		ymin = y;

	x = (fix31) (font_bbox->xmin * 16.0);
	y = (fix31) (font_bbox->ymax * 16.0);
	do_trans_a(PARAMS2 (fix31 STACKFAR*)&x, (fix31 STACKFAR*)&y);
	if (x > xmax)
		xmax = x;
	if (x < xmin)
		xmin = x;
	if (y > ymax)
		ymax = y;
	if (y < ymin)
		ymin = y;

	maxabs = ABS(xmin);
	if ((x = ABS(xmax)) > maxabs)
		maxabs = x;
	if ((x = ABS(ymin)) > maxabs)
		maxabs = x;
	if ((x = ABS(ymax)) > maxabs)
		maxabs = x;
	sp_globals.pixshift = 8;

	shift_oru = set_shift_const(PARAMS1);
	sp_globals.processor.type1.mk_shift = shift_oru + 4;
	sp_globals.processor.type1.mk_onepix = (fix31) 1 << sp_globals.processor.type1.mk_shift;
	sp_globals.processor.type1.tr_flex = (fix31) ((real) ((fix31) 1 << shift_oru) *.01);
	sp_globals.processor.type1.mk_rnd = sp_globals.processor.type1.mk_onepix >> 1;

	x_test = 100.0;
	max_test = (real) maxabs / (real) sp_globals.processor.type1.mk_onepix;

	while (sp_globals.pixshift >= 0) {
		if (max_test < x_test)
			break;
		sp_globals.pixshift--;
		x_test *= 2.0;
	}
	if (sp_globals.pixshift < 0) {
		sp_report_error(PARAMS2 3);/* Transformation matrix out of range */
	}
	sp_globals.poshift = 16 - sp_globals.pixshift;
	sp_globals.onepix = (fix15) 1 << sp_globals.pixshift;
	sp_globals.pixrnd = sp_globals.onepix >> 1;
	sp_globals.pixfix = 0xffff << sp_globals.pixshift;
	sp_globals.normal = FALSE;

	sp_globals.processor.type1.shift_down = (shift_oru + 4) - sp_globals.pixshift;
	sp_globals.processor.type1.shift_rnd = (fix31) 1 << (sp_globals.processor.type1.shift_down - 1);

	sp_globals.processor.type1.Pmin.x = (fix15) ((xmin + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
	sp_globals.processor.type1.Pmax.x = (fix15) ((xmax + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
	sp_globals.processor.type1.Pmin.y = (fix15) ((ymin + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);
	sp_globals.processor.type1.Pmax.y = (fix15) ((ymax + sp_globals.processor.type1.shift_rnd) >> sp_globals.processor.type1.shift_down);

	/* Check for mirror image transformations */
	sp_globals.tcb0.mirror  = sp_globals.tcb.mirror =
			((matrix[0] * matrix[3]) < (matrix[1] * matrix[2])) ? -1 : 1;
}
#if RESTRICTED_ENVIRON
FUNCTION        real
tr_get_char_width(PARAMS2 font_ptr, charname)
GDECL
ufix8 STACKFAR*font_ptr;
CHARACTERNAME STACKFAR*charname;
#else
FUNCTION        real
tr_get_char_width(PARAMS2 charname)
GDECL
CHARACTERNAME *charname;
#endif
{
	fix15           i, n;
	ufix16          decrypt_r;	/* Current decryption key */
	fix15           no_bytes;	/* Number of bytes processed in char * prog string */
	fix15           state;	/* Multi-byte operator and operand decoding state */
	ufix8           byte;	/* Byte read from character program string */
	fix31           operand;/* Accumulator for multi-byte operand values */
	real            r_arg1, r_arg2;
	fix31           arg1, arg2, arg3, arg4, arg5, arg6;
	/* Arguments read from BuildChar stack */

	unsigned char  STACKFAR*tr_get_chardef();	/* get character program string */
	ufix8          STACKFAR*charstring;
	real            set_width;
	fix15           tr_get_leniv();
	fix15           leniv;

#if RESTRICTED_ENVIRON
	sp_globals.processor.type1.current_font = font_ptr;
#endif
	state = 0;
	CLEAR_STACK;		/* Start with empty BuildChar stack */
	sp_globals.processor.type1.flex_active = FALSE;
	decrypt_r = 4330;	/* Initialize decryption */
	no_bytes = 0;		/* Initialize byte count */
	charstring = tr_get_chardef(PARAMS2 charname);	/* Get character program string for specified char */

	if (charstring == NULL)	/* make sure character exists */
		return (0.0);

	leniv = tr_get_leniv(PARAMS1);
	while (TRUE) {		/* Loop for character program string */
		byte = *charstring ^ (decrypt_r >> 8);	/* Decrypt byte from
							 * char prog string */
		decrypt_r = (*charstring + decrypt_r) * makechr_decrypt_c1 + makechr_decrypt_c2;
		/* Update decryption key */
		charstring++;	/* Update byte pointer */
		if (no_bytes++ < leniv)	/* Discard first "leniv" bytes of
					 * char progstring */
			continue;



		switch (state) {
		case 0:	/* Initial state */
			if (byte < 32) {	/* Command? */
				switch (byte) {
				case 13:	/* hsbw */
					FIRST_ARG;
					arg1 = GET_ARG;	/* sbx: X coordinate of
							 * left sidebearing */
					arg2 = GET_ARG;	/* wx: X coordinate of
							 * character width
							 * vector */

					CLEAR_STACK;
#if DEBUG
					printf("hsbw(%3.1f, %3.1f)\n", (real) arg1 / 16.0, (real) arg2 / 16.0);
#endif
					/* return value in 16.16 notation */
					set_width = (real) arg2 / 16.0;	/* setwidth in orus */
					set_width = set_width / 1000.0;	/* orus * (em/orus) */
					return (set_width);
				case 7:	/* sbw */
					FIRST_ARG;
					arg1 = GET_ARG;	/* sbx: X coordinate of
							 * left sidebearing */
					arg2 = GET_ARG;	/* sby: Y coordinate of
							 * left sidebearing */
					arg3 = GET_ARG;	/* wx: X coordinate of
							 * character width
							 * vector */
					arg4 = GET_ARG;	/* wy: Y coordinate of
							 * character width
							 * vector */
					CLEAR_STACK;
#if DEBUG
					printf("sbw(%3.1f, %3.1f, %3.1f, %3.1f)\n", (real) arg1 / 16.0, (real) arg2 / 16.0, (real) arg3 / 16.0, (real) arg4 / 16.0);
#endif
					/* return value in 16.16 notation */
					set_width = (real) arg2 / 16.0;	/* setwidth in orus */
					set_width = set_width / 1000.0;	/* orus * (em/orus) */
					return (set_width);

				default:
					sp_report_error(PARAMS2 4001);
					return (0);


				}
			} else if (byte < 247) {	/* 1-byte integer? */
				operand = ((fix31) byte - 139L);
#if DBGOPND
				printf("%d, ", operand);
#endif
				sp_globals.processor.type1.stack_top->i_value = operand << 4;
				sp_globals.processor.type1.stack_top->r_value = (real) sp_globals.processor.type1.stack_top->i_value;
				sp_globals.processor.type1.stack_top++;
			} else if (byte < 251) {	/* 2-byte positive
							 * integer? */
				operand = ((fix31) byte - 247L) << 8;
				state = 2;
			} else if (byte < 255) {	/* 2-byte negative
							 * integer? */
				operand = -(((fix31) byte - 251L) << 8);
				state = 3;
			} else {/* 5-byte integer? */
				operand = 0;
				state = 7;
			}
			break;

		case 1:	/* Second byte of 2-byte command */
			sp_report_error(PARAMS2 4001);
			break;

		case 2:	/* Second byte of 2-byte positive integer */
			operand += (fix31) byte + 108L;
#if DBGOPND
			printf("%d, ", operand);
#endif
			sp_globals.processor.type1.stack_top->i_value = operand << 4;
			sp_globals.processor.type1.stack_top->r_value = (real) sp_globals.processor.type1.stack_top->i_value;
			sp_globals.processor.type1.stack_top++;
			state = 0;
			break;

		case 3:	/* Second byte of 2-byte negative integer */
			operand -= (fix31) byte + 108L;
#if DBGOPND
			printf("%d, ", operand);
#endif
			sp_globals.processor.type1.stack_top->i_value = operand << 4;
			sp_globals.processor.type1.stack_top->r_value = (real) sp_globals.processor.type1.stack_top->i_value;
			sp_globals.processor.type1.stack_top++;
			state = 0;
			break;
		case 4:	/* Last byte of 5-byte integer */
			operand = (operand << 8) + (fix31) byte;
#if DBGOPND
			printf("%d, ", operand);
#endif
			sp_globals.processor.type1.stack_top->r_value = (real) operand *16.0;
			sp_globals.processor.type1.stack_top->i_value = operand << 4;
			sp_globals.processor.type1.stack_top++;
			state = 0;
			break;

		default:	/* Other bytes of 5-byte integer */
			operand = (operand << 8) + (fix31) byte;
			state--;
			break;
		}
	}
}
#if OSUBR_CALLOUT
void
tr_do_move(PARAMS2 X, Y)
	GDECL
	real            X, Y;
{
	do_move(PARAMS2 (fix31) X, (fix31) Y);
}
void
tr_do_line(PARAMS2 X, Y)
	GDECL
	real            X, Y;
{
	do_line(PARAMS2 (fix31) X, (fix31) Y);
}
void
tr_do_curve(PARAMS2 X1, Y1, X2, Y2, X3, Y3)
	GDECL
	real            X1, Y1, X2, Y2, X3, Y3;
{
	do_curve(PARAMS2 (fix31) X1, (fix31) Y1, (fix31) X2, (fix31) Y2, (fix31) X3, (fix31) Y3);
}
void
tr_closepath(PARAMS1)
GDECL
{
	do_closepath(PARAMS1);
}
void 
tr_pop(PARAMS2 value)
GDECL
real value;
{
	do_pop(PARAMS2 value);
}
#endif

#pragma Code()
