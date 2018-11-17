/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	spdo_prv.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: spdo_prv.h,v 1.1 97/04/18 11:45:12 newdeal Exp $
 *
 ***********************************************************************/



/*****************************************************************************
*                                                                            *
*  Copyright 1989, as an unpublished work by Bitstream Inc., Cambridge, MA   *
*                         U.S. Patent No 4,785,391                           *
*                           Other Patent Pending                             *
*                                                                            *
*         These programs are the sole property of Bitstream Inc. and         *
*           contain its proprietary and confidential information.            *
*                                                                            *
*****************************************************************************/
/********************* Revision Control Information **********************************
*                                                                         
*                                                                                    
*       Revision 28.37  93/03/15  13:01:50  roberte
*       Release
*       
*       Revision 28.12  93/01/29  09:10:57  roberte
*       Correct NEXT_WORD macro to properly reference sp_globals.processor.speedo union struct.
*       
*       Revision 28.11  93/01/07  12:07:22  roberte
*       Changed definitions of fn_ functions reflecting move of init_out - end_char
*       function ptrs from union area of SPEEDO_GLOBALS to common area.
*       
*       Revision 28.10  93/01/04  16:16:48  roberte
*       fn_* functions now reference sp_globals.function ptrs.
*       Field of union structure.
*       
*       Revision 28.9  92/12/30  17:36:40  roberte
*       Removed almost all renames of "sp_" functions by employing
*       the new macros PARAMS1 and PARAMS2.  Functions must be declared
*       now with the "sp_" prefix, and using the same PARAMS1 and PARAMS2
*       macros.
*       
*       Revision 28.8  92/12/02  18:19:51  laurar
*       fix typo with callback_ptrs reference.
*       
*       Revision 28.7  92/12/02  11:41:51  laurar
*       only include read_long redefine if file is NOT included in type1 processor.
*       
*       Revision 28.6  92/12/01  17:35:56  laurar
*       redefine calls to report_error, open_bitmap, etc for WINDOWS_4IN1.
*       
*       Revision 28.5  92/11/19  15:18:45  roberte
*       Release
*       
*       Revision 28.1  92/06/25  13:42:41  leeann
*       Release
*       
*       Revision 27.1  92/03/23  14:02:27  leeann
*       Release
*       
*       Revision 26.1  92/01/30  17:02:09  leeann
*       Release
*       
*       Revision 25.1  91/07/10  11:07:44  leeann
*       Release
*       
*       Revision 24.1  91/07/10  10:41:16  leeann
*       Release
*       
*       Revision 23.1  91/07/09  18:02:13  leeann
*       Release
*       
*       Revision 22.3  91/06/19  14:25:24  leeann
*        add function sp_set_clip_parameters for clipping
*       
*       Revision 22.2  91/04/08  17:30:29  joyce
*       Added white writer output function defines (M. Yudis)
*       
*       Revision 22.1  91/01/23  17:21:45  leeann
*       Release
*       
*       Revision 21.1  90/11/20  14:41:09  leeann
*       Release
*       
*       Revision 20.1  90/11/12  09:36:47  leeann
*       Release
*       
*       Revision 19.1  90/11/08  10:26:19  leeann
*       Release
*       
*       Revision 18.2  90/11/06  19:01:17  leeann
*       add new function compute_isw_scale
*       
*       Revision 18.1  90/09/24  10:17:35  mark
*       Release
*       
*       Revision 17.2  90/09/19  18:08:01  leeann
*       make preview_bounding_box visible when squeezing
*       
*       Revision 17.1  90/09/13  16:04:03  mark
*       Release name rel0913
*       
*       Revision 16.1  90/09/11  13:23:18  mark
*       Release
*       
*       Revision 15.2  90/09/05  11:20:23  leeann
*       added two new functions: sp_reset_xmax and sp_preview_bounding_box
*       
*       Revision 15.1  90/08/29  10:07:37  mark
*       Release name rel0829
*       
*       Revision 14.2  90/08/23  16:13:14  leeann
*       make setup_const take min and max as arguments
*       
*       Revision 14.1  90/07/13  10:45:12  mark
*       Release name rel071390
*       
*       Revision 13.1  90/07/02  10:44:10  mark
*       Release name REL2070290
*       
*       Revision 12.4  90/06/26  08:54:34  leeann
*       Add macro for SQUEEZE_MULT
*       
*       Revision 12.3  90/06/20  15:57:41  leeann
*       Add parameter of number of y control zones to function
*       sp_calculate_y_zone
*       
*       Revision 12.2  90/06/01  15:23:10  mark
*       straighten out reentrant declarations of multi device
*       support function declarations
*       
*       Revision 12.1  90/04/23  12:15:56  mark
*       Release name REL20
*       
*       Revision 11.1  90/04/23  10:16:14  mark
*       Release name REV2
*       
*       Revision 10.12  90/04/23  09:42:56  mark
*       add proper redefinitions of do_make_char
*       
*       Revision 10.11  90/04/21  10:45:59  mark
*       add declaration of functions for multiple output device handling
*       sp_set_bitmap_device() and sp_set_outline_device()
*       
*       Revision 10.10  90/04/18  09:56:05  mark
*       define init_userout
*       
*       
*       Revision 10.9  90/04/12  13:00:09  mark
*       add argument of type buff_t to get_cust_no, since
*       valid specs cannot be provided via set_specs until
*        the encryption is set, which requires customer number
*       
*       Revision 10.8  90/04/12  12:25:51  mark
*       added macros for sp_get_char_bbox and sp_get_cust_no
*       
*       Revision 10.7  90/04/11  13:02:44  leeann
*       add make_char_isw; make char for imported setwidth
*       
*       Revision 10.6  90/04/06  12:32:18  mark
*       declare curve handling functions in out_scrn
*       
*       Revision 10.5  90/03/30  14:58:08  mark
*       remove out_wht and add out_scrn and out_util
*       
*       Revision 10.4  90/03/29  16:41:37  leeann
*       Added set_flags argument to read_bbox
*       
*       Revision 10.3  90/03/28  13:50:34  leeann
*       new global variables added for squeezing
*       new function skip_orus added
*       
*       Revision 10.2  90/03/27  14:51:18  leeann
*       Include new functions skip_control_zone, skip_interpolation_zone
*       
*       Revision 10.1  89/07/28  18:15:59  mark
*       Release name PRODUCT
*       
*       Revision 9.1  89/07/27  10:29:51  mark
*       Release name PRODUCT
*       
*       Revision 8.1  89/07/13  18:24:48  mark
*       Release name Product
*       
*       Revision 7.1  89/07/11  09:08:15  mark
*       Release name PRODUCT
*       
*       Revision 6.1  89/06/19  08:40:19  mark
*       Release name prod
*       
*       Revision 5.3  89/06/06  17:48:49  mark
*       add curve depth to output module curve functions
*       
*       Revision 5.2  89/05/25  17:33:39  john
*       All 3-byte fields in list of private font header
*       offset constants now commented as Encrypted.
*       
*       Revision 5.1  89/05/01  18:01:32  mark
*       Release name Beta
*       
*       Revision 4.1  89/04/27  12:24:09  mark
*       Release name Beta
*       
*       Revision 3.2  89/04/26  16:59:57  mark
*       remove redundant declarations of get_char_org and plaid_tcb
*       
*       Revision 3.1  89/04/25  08:37:26  mark
*       Release name beta
*       
*       Revision 2.2  89/04/18  18:21:33  john
*       setup_mult(), setup_offset() function definitions added
*       
*       Revision 2.1  89/04/04  13:42:34  mark
*       Release name EVAL
*       
*       Revision 1.3  89/04/04  13:30:12  mark
*       Update copyright text
*       
*       Revision 1.2  89/03/31  17:35:18  john
*       Added read_word_u() function def.
*       
*       Revision 1.1  89/03/31  15:08:11  mark
*       Initial revision
*       
*                                                                                    
*************************************************************************************/

/***************************** S P D O _ P R V . H *******************************/
 
#include "speedo.h"  /* include public definitions */

/* GEOS hack for ProcCallFixedOrMovable_cdecl */
#include <resource.h>

/*****  CONFIGURATION DEFINITIONS *****/


#ifndef INCL_PLAID_OUT
#define  INCL_PLAID_OUT 0          /* 1 to include plaid data monitoring */
#endif                             /* 0 to omit plaid data monitoring */


/***** PRIVATE FONT HEADER OFFSET CONSTANTS  *****/
#define  FH_ORUMX    0      /* U   Max ORU value  2 bytes                   */
#define  FH_PIXMX    2      /* U   Max Pixel value  2 bytes                 */
#define  FH_CUSNR    4      /* U   Customer Number  2 bytes                 */
#define  FH_OFFCD    6      /* E   Offset to Char Directory  3 bytes        */
#define  FH_OFCNS    9      /* E   Offset to Constraint Data  3 bytes       */
#define  FH_OFFTK   12      /* E   Offset to Track Kerning  3 bytes         */
#define  FH_OFFPK   15      /* E   Offset to Pair Kerning  3 bytes          */
#define  FH_OCHRD   18      /* E   Offset to Character Data  3 bytes        */
#define  FH_NBYTE   21      /* E   Number of Bytes in File  3 bytes         */


/***** MODE FLAGS CONSTANTS *****/
#define CURVES_OUT     0X0008  /* Output module accepts curves              */
#define BOGUS_MODE     0X0010  /* Linear scaling mode                       */
#define CONSTR_OFF     0X0020  /* Inhibit constraint table                  */
#define IMPORT_WIDTHS  0X0040  /* Imported width mode                       */
#define SQUEEZE_LEFT   0X0100  /* Squeeze left mode                         */
#define SQUEEZE_RIGHT  0X0200  /* Squeeze right mode                        */
#define SQUEEZE_TOP    0X0400  /* Squeeze top mode                          */
#define SQUEEZE_BOTTOM 0X0800  /* Squeeze bottom mode                       */
#define CLIP_LEFT      0X1000  /* Clip left mode                            */
#define CLIP_RIGHT     0X2000  /* Clip right mode                           */
#define CLIP_TOP       0X4000  /* Clip top mode                             */
#define CLIP_BOTTOM    0X8000  /* Clip bottom mode                          */


/***** MACRO DEFINITIONS *****/

#define SQUEEZE_MULT(A,B) (((fix31)A * (fix31)B) >> 16)

#define NEXT_BYTE(A) (*(A)++)

#define NEXT_WORD(A) \
    ((fix15)(sp_globals.processor.speedo.key32 ^ ((A) += 2, ((fix15)((A)[-1]) << 8) | (fix15)((A)[-2]))))

#if INCL_EXT                       /* Extended fonts supported? */

#define NEXT_BYTES(A, B) \
    (((B = (ufix16)(*(A)++) ^ sp_globals.processor.speedo.key7) >= 248)? \
     ((ufix16)(B & 0x07) << 8) + ((*(A)++) ^ sp_globals.processor.speedo.key8) + 248: \
     B)

#else                              /* Compact fonts only supported? */

#define NEXT_BYTES(A, B) ((*(A)++) ^ sp_globals.processor.speedo.key7)

#endif

#define NEXT_BYTE_U(A) (*(A)++) 

#define NEXT_WORD_U(A, B) \
    (fix15)(B = (*(A)++) << 8, (fix15)(*(A)++) + B)

#define NEXT_CHNDX(A, B) \
    ((B)? (ufix16)NEXT_WORD(A): (ufix16)NEXT_BYTE(A))

/* Multiply (fix15)X by (fix15)Y to produce (fix31)product */
#define MULT16(X, Y) \
    ((fix31)X * (fix31)Y)

/* Multiply (fix15)X by (fix15)MULT, add (fix31)OFFSET, 
 * shift right SHIFT bits to produce (fix15)result */
#define TRANS(X, MULT, OFFSET, SHIFT) \
    ((fix15)((((fix31)X * (fix31)MULT) + OFFSET) >> SHIFT))

/******************************************************************************
 *
 *      the following block of definitions redefines every function
 *      reference to be prefixed with an "sp_".  In addition, if this 
 *      is a reentrant version, the parameter sp_globals will be added
 *      as the first parameter.
 *
 *****************************************************************************/

#if STATIC_ALLOC || DYNAMIC_ALLOC
#define GDECL
#else /* REENTRANT_ALLOC */
#define GDECL SPEEDO_GLOBALS* sp_global_ptr;
#endif

#ifdef __GEOS__		/* GEOS hacks */
#define fn_init_out(specsarg) (boolean)ProcCallFixedOrMovable_pascal(PARAMS2 specsarg, (*sp_globals.init_out))  
#define fn_begin_char(Psw,Pmin,Pmax) (boolean)ProcCallFixedOrMovable_pascal(PARAMS2 Psw,Pmin,Pmax, (*sp_globals.begin_char))
#define fn_begin_sub_char(Psw,Pmin,Pmax) (void)ProcCallFixedOrMovable_pascal(PARAMS2 Psw,Pmin,Pmax, (*sp_globals.begin_sub_char))
#define fn_end_sub_char() (void)ProcCallFixedOrMovable_pascal(PARAMS2 (*sp_globals.end_sub_char))
#define fn_end_char() (boolean)ProcCallFixedOrMovable_pascal(PARAMS2 (*sp_globals.end_char))
#define fn_line(P1) (void)ProcCallFixedOrMovable_pascal(PARAMS2 P1, (*sp_globals.line))
#define fn_end_contour() (void)ProcCallFixedOrMovable_pascal(PARAMS2 (*sp_globals.end_contour))
#define fn_begin_contour(P0,fmt) (void)ProcCallFixedOrMovable_pascal(PARAMS2 P0,fmt, (*sp_globals.begin_contour))
#define fn_curve(P1,P2,P3,depth) (void)ProcCallFixedOrMovable_pascal(PARAMS2 P1,P2,P3,depth, (*sp_globals.curve))
#else			/* end of GEOS hacks */
#define fn_init_out(specsarg) (*sp_globals.init_out)(PARAMS2 specsarg)  
#define fn_begin_char(Psw,Pmin,Pmax) (*sp_globals.begin_char)(PARAMS2 Psw,Pmin,Pmax)
#define fn_begin_sub_char(Psw,Pmin,Pmax) (*sp_globals.begin_sub_char)(PARAMS2 Psw,Pmin,Pmax)
#define fn_end_sub_char() (*sp_globals.end_sub_char)(PARAMS1)
#define fn_end_char() (*sp_globals.end_char)(PARAMS1)
#define fn_line(P1) (*sp_globals.line)(PARAMS2 P1)
#define fn_end_contour() (*sp_globals.end_contour)(PARAMS1)
#define fn_begin_contour(P0,fmt) (*sp_globals.begin_contour)(PARAMS2 P0,fmt)
#define fn_curve(P1,P2,P3,depth) (*sp_globals.curve)(PARAMS2 P1,P2,P3,depth)
#endif			/* GEOS hacks */

#if INCL_MULTIDEV
#define set_bitmap_device(bfuncs,size) sp_set_bitmap_device(PARAMS2 bfuncs,size)
#define set_outline_device(ofuncs,size) sp_set_outline_device(PARAMS2 ofuncs,size)
#define open_bitmap(x_set_width, y_set_width, xmin, xmax, ymin, ymax)(*sp_globals.bitmap_device.p_open_bitmap)(PARAMS2 x_set_width, y_set_width, xmin, xmax, ymin, ymax)
#define set_bitmap_bits(y, xbit1, xbit2)(*sp_globals.bitmap_device.p_set_bits)(PARAMS2 y, xbit1, xbit2)
#define close_bitmap()(*sp_globals.bitmap_device.p_close_bitmap)(PARAMS1)
#define open_outline(x_set_width, y_set_width, xmin, xmax, ymin, ymax)(*sp_globals.outline_device.p_open_outline)(PARAMS2 x_set_width, y_set_width, xmin, xmax, ymin, ymax)
#define start_new_char()(*sp_globals.outline_device.p_start_char)(PARAMS1)
#define start_contour(x,y,outside)(*sp_globals.outline_device.p_start_contour)(PARAMS2 x,y,outside)
#define curve_to(x1,y1,x2,y2,x3,y3)(*sp_globals.outline_device.p_curve)(PARAMS2 x1,y1,x2,y2,x3,y3)
#define line_to(x,y)(*sp_globals.outline_device.p_line)(PARAMS2 x,y)
#define close_contour()(*sp_globals.outline_device.p_close_contour)(PARAMS1)
#define close_outline()(*sp_globals.outline_device.p_close_outline)(PARAMS1)
#else /* NOT INCL_MULTIDEV */
#define open_bitmap(x_set_width, y_set_width, xmin, xmax, ymin, ymax) sp_open_bitmap(PARAMS2  x_set_width, y_set_width, xmin, xmax, ymin, ymax)
#define set_bitmap_bits(y, xbit1, xbit2) sp_set_bitmap_bits(PARAMS2  y, xbit1, xbit2)
#define close_bitmap() sp_close_bitmap(PARAMS1)
#define open_outline(x_set_width, y_set_width, xmin, xmax, ymin, ymax) sp_open_outline(PARAMS2  x_set_width, y_set_width, xmin, xmax, ymin, ymax)
#define start_new_char() sp_start_new_char(PARAMS1 )
#define start_contour(x,y,outside) sp_start_contour(PARAMS2  x,y,outside)
#define curve_to(x1,y1,x2,y2,x3,y3) sp_curve_to(PARAMS2  x1,y1,x2,y2,x3,y3)
#define line_to(x,y) sp_line_to(PARAMS2  x,y)
#define close_contour() sp_close_contour(PARAMS1)
#define close_outline() sp_close_outline(PARAMS1)
#endif /* else NOT MULTIDEV */

