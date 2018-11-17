/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Type1/tr_trans.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: tr_trans.c,v 1.1 97/04/18 11:45:16 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TrTransCode")


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



/*************************** T R A N S _ A . C *******************************
 *                                                                           *
 * This is the transformation module for the Type A font interpreter.        *
 *                                                                           *
 ********************** R E V I S I O N   H I S T O R Y **********************
 * $Header: /staff/pcgeos/Driver/Font/Bitstream/Type1/tr_trans.c,v 1.1 97/04/18 11:45:16 newdeal Exp $
 *
 * $Log:	tr_trans.c,v $
 * Revision 1.1  97/04/18  11:45:16  newdeal
 * Initial revision
 * 
 * Revision 1.1.10.1  97/03/29  07:05:37  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:18:12  brianc
 * support Type1
 * 
 * Revision 28.24  93/03/15  13:11:59  roberte
 * Release
 * 
 * Revision 28.15  93/01/21  13:26:44  roberte
 * 
 * Reentrant code work.  Added macros to support sp_global_ptr parameter pass in all essential call threads. 
 * Prototyped all static functions.
 * 
 * Revision 28.14  93/01/18  12:53:10  ruey
 * change top_zone[].pix from bottom_orus to top_orus
 * 
 * Revision 28.13  93/01/14  10:19:42  roberte
 * Changed all data references to sp_globals.processor.type1.<varname> since these are all part of union structure there.
 * Moved structure definitions to type1.h.
 * 
 * Revision 28.12  93/01/04  17:26:34  roberte
 * Changed all the report_error calls back to sp_report_error to be in line with the spdo_prv.h changes.
 * 
 * Revision 28.11  92/12/28  16:17:45  roberte
 * Changed #include "speedo.h" to #include "spdo_prv.h"
 * 
 * Revision 28.10  92/12/28  12:16:59  roberte
 * Changed style of function declaration init_trans_a()
 * to older K&R style.
 * 
 * Revision 28.9  92/12/02  17:48:31  laurar
 * include speedo.h.
 * 
 * Revision 28.8  92/11/24  13:14:22  laurar
 * include fino.h
 * 
 * Revision 28.7  92/11/19  15:36:03  weili
 * Release
 * 
 * Revision 26.7  92/11/16  18:24:57  laurar
 * Add STACKFAR for Windows.
 * 
 * Revision 26.6  92/10/21  09:58:58  davidw
 * Turned off debug
 * 
 * Revision 26.5  92/10/19  07:43:10  davidw
 * transformed function parameter list declaration to conform with ANSI "C"
 * 
 * Revision 26.4  92/10/16  16:46:36  davidw
 *    beautified with indent
 * 
 * Revision 26.3  92/09/28  16:47:07  roberte
 * Changed "fnt.h" to fnt_a.h".  Same include file needs different name for 4in1.
 * 
 * Revision 26.2  92/09/22  16:01:02  ruey
 * sp_globals.processor.type1.Xorus and sp_globals.processor.type1.Yorus are ufix31 now
 * 
 * Revision 26.1  92/06/26  10:26:36  leeann
 * Release
 * 
 * Revision 25.1  92/04/06  11:42:57  leeann
 * Release
 * 
 * Revision 24.2  92/04/06  11:29:37  leeann
 * save the default blue_shift value
 * 
 * Revision 24.1  92/03/23  14:11:15  leeann
 * Release
 * 
 * Revision 23.2  92/03/23  11:54:17  leeann
 * improve baseline placement - use compilation option BASELINE_IMPROVE
 * until this improvement has been fully tested
 * 
 * Revision 23.1  92/01/29  17:02:23  leeann
 * Release
 * 
 * Revision 22.4  92/01/29  14:11:45  leeann
 * make baseline a special case in align_hstem
 * 
 * Revision 22.3  92/01/28  14:27:24  leeann
 * remove unnecessary code in align_hstem
 * 
 * Revision 22.2  92/01/21  15:23:57  leeann
 * if horizontal zone is a bottom zone, align the bottom edge and
 * subract weight for top edge, otherwise default action is align
 * top edge, and subtract weight for bottom edge.
 * 
 * Revision 22.1  92/01/20  13:33:47  leeann
 * Release
 * 
 * Revision 21.2  92/01/20  13:20:19  leeann
 * make sp_globals.processor.type1.Xmult and sp_globals.processor.type1.Ymult 32 bits to prevent overflow,
 * when setting horizontal edges, always set bottom edge first.
 * 
 * Revision 21.1  91/10/28  16:46:12  leeann
 * Release
 * 
 * Revision 20.2  91/10/28  16:36:18  leeann
 * get proper stem weight in do_hstem3
 * 
 * Revision 20.1  91/10/28  15:29:54  leeann
 * Release
 * 
 * Revision 18.4  91/10/23  16:14:04  leeann
 * force hstem3 hint stems to be symetric
 * 
 * Revision 18.3  91/10/23  14:01:28  leeann
 * explicitly cast to ufix32 when using ufix16 as 32 bit number
 * 
 * Revision 18.2  91/10/22  15:58:03  leeann
 * force vstem3 hint stems to be symetric
 * 
 * Revision 18.1  91/10/17  11:41:26  leeann
 * Release
 * 
 * Revision 17.3  91/10/03  11:21:42  leeann
 * fix vstem3 and hstem3 hints -
 * the edge given can be either the left or right, compensate for
 * that by alway making it the left (in the case of hstem3 hints)
 * or bottom (in the case of vstem3 hints). Also - don't make the
 * widths be the same weight.
 * 
 * Revision 17.2  91/09/24  16:44:51  leeann
 * use transformed bounding box to set fixed point constants
 * 
 * Revision 17.1  91/06/13  10:46:06  leeann
 * Release
 * 
 * Revision 16.1  91/06/04  15:36:42  leeann
 * Release
 * 
 * Revision 15.1  91/05/08  18:08:49  leeann
 * Release
 * 
 * Revision 14.1  91/05/07  16:30:38  leeann
 * Release
 * 
 * Revision 13.1  91/04/30  17:05:20  leeann
 * Release
 * 
 * Revision 12.3  91/04/30  16:57:59  leeann
 * still trying to get blueshift right...
 * 
 * Revision 12.2  91/04/30  11:11:00  leeann
 * fix top_oru calculation for blueshift
 * 
 * Revision 12.1  91/04/29  14:55:42  leeann
 * Release
 * 
 * Revision 11.10  91/04/29  13:57:55  leeann
 * make edge align the default
 * 
 * Revision 11.9  91/04/26  11:19:15  leeann
 * make blueshift enforce overshoot
 * 
 * Revision 11.8  91/04/24  18:12:50  leeann
 * change snap value for hstems and vstems to be 1/2 pixel
 * 
 * Revision 11.7  91/04/24  17:50:52  leeann
 * read useropt.h file
 * 
 * Revision 11.6  91/04/24  10:34:57  leeann
 * Change undefined values for bluescale, blueshift, and bluefuzz
 * 
 * Revision 11.5  91/04/23  10:42:01  leeann
 * fix vstem3 hint
 * for edge aligned implementation
 * 
 * Revision 11.4  91/04/16  17:57:35  leeann
 * fix do_vstem3 for EDGE_ALIGN model
 * 
 * Revision 11.3  91/04/10  13:21:54  leeann
 * take out strkwt0_pix - don't need it
 * 
 * Revision 11.2  91/04/04  15:03:57  leeann
 * put in fix for update_x_trans when zones overlap
 * 
 * Revision 11.1  91/04/04  10:59:30  leeann
 * Release
 * 
 * Revision 10.3  91/04/04  10:47:50  leeann
 * Support edge alignment (vs pixel center alignment) as
 * a compilation option (ALIGN_EDGE) Default is center align
 * 
 * Revision 10.2  91/03/25  17:36:53  leeann
 * take out check for UniqueID, fixup call to align_hstem
 * 
 * Revision 10.1  91/03/14  14:32:01  leeann
 * Release
 * 
 * Revision 9.1  91/03/14  10:07:03  leeann
 * Release
 * 
 * Revision 8.3  91/03/13  16:16:50  leeann
 * Support RESTRICTED_ENVIRON
 * 
 * Revision 8.2  91/02/26  11:17:22  leeann
 * make sp_globals.processor.type1.Xmult and sp_globals.processor.type1.Ymult arrays ufix16
 * 
 * Revision 8.1  91/01/30  19:03:56  leeann
 * Release
 * 
 * Revision 7.1  91/01/22  14:28:22  leeann
 * Release
 * 
 * Revision 6.1  91/01/16  10:54:07  leeann
 * Release
 * 
 * Revision 5.1  90/12/12  17:20:42  leeann
 * Release
 * 
 * Revision 4.1  90/12/12  14:46:30  leeann
 * Release
 * 
 * Revision 3.1  90/12/06  10:28:53  leeann
 * Release
 * 
 * Revision 2.1  90/12/03  12:57:37  mark
 * Release
 * 
 * Revision 1.2  90/12/03  12:22:35  joyce
 * Changed include line to reference new include file names:
 * fnt_a.h -> fnt.h; ps_qem.h -> type1.h
 * 
 * Revision 1.1  90/11/30  11:28:13  joyce
 * Initial revision
 * 
 * Revision 1.6  90/11/29  17:01:07  leeann
 * change function names to conform to spec.
 * 
 * Revision 1.5  90/09/17  15:48:49  roger
 * converted azone_t to split integer
 * 
 * Revision 1.4  90/09/17  13:23:19  roger
 * put in rcsid[] to help RCS
 * 
 * Revision 1.3  90/09/11  10:55:52  roger
 * major revision to convert most real calculations 
 * (and variables) to split integer format
 * 
 * Revision 1.2  90/08/14  12:38:52  roger
 * New version of trans_a.c from jsc
 * 
 * Revision 1.1  90/08/13  15:30:39  arg
 * Initial revision
 * 
 *                                                                           *
 *  1) 24 May 90  jsc  Created                                               *
 *                                                                           *
 ****************************************************************************/

static char     rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/Type1/tr_trans.c,v 1.1 97/04/18 11:45:16 newdeal Exp $";

#include "spdo_prv.h"
#include "fino.h"
#include "stdef.h"
#include "type1.h"
#include <math.h>
#ifdef __GEOS__
extern double _pascal fabs(double __x);
extern double _pascal floor(double __x);
#endif
#include "fnt_a.h"

#define   DEBUG     0
#ifndef EDGE_ALIGN
#define EDGE_ALIGN 1		/* default is edge align */
#endif

#if DEBUG
#ifdef __GEOS__
#define SHOWD(X)
#define SHOWI(X)
#define SHOWR(X)
#define SHOWB(X)
#else
#include <stdio.h>
#define SHOWD(X) printf("    X = %d\n", X)
#define SHOWI(X) printf("    X = %ld\n", X)
#define SHOWR(X) printf("    X = %f\n", X)
#define SHOWB(X) printf("    X = %s\n", X? "TRUE": "FALSE")
#endif
#else
#define SHOWD(X)
#define SHOWI(X)
#define SHOWR(X)
#define SHOWB(X)
#endif




#ifdef OLDWAY
/*** STATIC VARIABLES ***/
static real     local_matrix[6];/* Current transformation matrix */
static fix31    local_matrix_i[6];	/* Current transformation matrix */
static real     x_pix_per_oru;	/* Pixels per oru in x direction */
static real     y_pix_per_oru;	/* Pixels per oru in y direction */
static real     x_pix_per_oru_r;/* Pixels per oru in x direction */
static real     y_pix_per_oru_r;/* Pixels per oru in y direction */
static fix31    x_pix_per_oru_i;/* Pixels per oru in x direction */
static fix31    y_pix_per_oru_i;/* Pixels per oru in y direction */
static boolean  vstem3_active;	/* True if vstem3 hint set */
static boolean  hstem3_active;	/* True if hstem3 hint set */

/* Transformation control tables */
static fix31      x_trans_mode;	/* Mode for calculating transformed X */
static fix31      y_trans_mode;	/* Mode for calculating transformed Y */
/* 0: Linear                        */
/* 1: function of X only            */
/* 2: function of -X only           */
/* 3: function of Y only            */
/* 4: function of -Y only           */
static boolean  x_trans_ready;	/* True if X transformation data updated from
				 * hints */
static boolean  y_trans_ready;	/* True if Y transformation data updated from
				 * hints */
static boolean  non_linear_X;	/* True if X values require non-linear
				 * transformation */
static boolean  non_linear_Y;	/* True if Y values require non-linear
				 * transformation */
static fix31      no_x_breaks;	/* Number of X transformation breakpoints */
static fix31      no_y_breaks;	/* Number of Y transformation breakpoints */
static fix31    Xorus[MAXSTEMZONES];	/* List of X non-linear breakpoints */
static fix31    Yorus[MAXSTEMZONES];	/* List of Y non-linear breakpoints */
static fix31    Xpix[MAXSTEMZONES];	/* List of X pixel values at
					 * breakpoints */
static fix31    Ypix[MAXSTEMZONES];	/* List of Y pixel values at
					 * breakpoints */
static ufix32   Xmult[MAXSTEMZONES + 1];	/* List of X interpolation
						 * coefficients */
static ufix32   Ymult[MAXSTEMZONES + 1];	/* List of Y interpolation
						 * coefficients */
static fix31    Xoffset[MAXSTEMZONES + 1];	/* List of X interpolation
						 * constants */
static fix31    Yoffset[MAXSTEMZONES + 1];	/* List of Y interpolation
						 * constants */

/* Vertical alignment control tables */
static azone_t  top_zones[6];	/* Top alignment zones */
static fix31      no_top_zones;	/* Number of top alignment zones */
static azone_t  bottom_zones[6];/* Bottom alignment zones */
static fix31      no_bottom_zones;/* Number of bottom alignement zones */

/* Stem weight control tables */
static real     minhstemweight;	/* Minimum horizontal stem weight */
static real     minvstemweight;	/* Minimum vertical stem weight */
static fix31    i_minhstemweight;	/* Minimum horizontal stem weight */
static fix31    i_minvstemweight;	/* Minimum vertical stem weight */
static stem_snap_t hstem_std;	/* Standard horizontal stem weight */
static i_stem_snap_t i_hstem_std;	/* Standard horizontal stem weight */
static stem_snap_t vstem_std;	/* Standard vertical stem weight */
static i_stem_snap_t i_vstem_std;	/* Standard vertical stem weight */
static stem_snap_t hstem_snaps[MAXSTEMSNAPH];
/* Horizontal stem control table */
static i_stem_snap_t i_hstem_snaps[MAXSTEMSNAPH];
/* Horizontal stem control table */
static fix31 no_hstem_snaps;	/* Number of controlled hstems */
static stem_snap_t vstem_snaps[MAXSTEMSNAPV];
/* Vertical stem control table */
static i_stem_snap_t i_vstem_snaps[MAXSTEMSNAPV];
/* Vertical stem control table */
static fix31 no_vstem_snaps;	/* Number of controlled vstems */

static fix15    tr_shift;	/* Fixed point shift for multipliers */
static fix15    tr_poshift;	/* Left shift from pixel to output format */
static fix15    mk_shift;	/* Fixed point shift for mult to sub-pixels */
static fix31    mk_rnd;		/* 0.5 in multiplier units */
static fix31    tr_rnd;		/* 0.5 in sub-pixel units */
static fix15    tr_fix;		/* Mask to remove fractional pixels */
static fix31    tr_onepix;	/* 1.0 pixels in sub-pixel units */
static fix31    mk_onepix;	/* 1.0 pixels in sub-pixel units */
static fix31    mk_fix;		/* strip fractional bits */
static fix31    fudge_x;
static fix31    fudge_y;
static fix31    fudge_x1;
static fix31    fudge_y1;
static fix31    pt_1;
static fix31    pt_2;
static fix31    pt_36;
static fix31    pt_725;
static fix31    pt_6;
static fix31    pt_875;
#endif /* OLDWAY */

/* static function prototypes: */
static void real_trans_a PROTO((real STACKFAR*matrix,real STACKFAR*x,real STACKFAR*y));
static void set_fixed_point PROTO((PROTO_DECL2 real STACKFAR*matrix,fbbox_t STACKFAR*font_bbox));
static void set_blue_values PROTO((PROTO_DECL2 font_hints_t STACKFAR*pfont_hints));
static void set_stem_tables PROTO((PROTO_DECL2 font_hints_t STACKFAR*pfont_hints));
#if EDGE_ALIGN
static void align_hstem PROTO((PROTO_DECL2 fix31 y1,fix31 y2,fix31 STACKFAR*pcy_pix_bottom,
			fix31 STACKFAR*pcy_pix_top));
#else
static void align_hstem PROTO((PROTO_DECL2 fix31 y1,fix31 y2,fix31 STACKFAR*pcy_pix));
#endif
static void align_vstem PROTO((PROTO_DECL2 fix31 x1,fix31 x));
static	fix31 vstemweight PROTO((PROTO_DECL2 fix31 dx));
static	void add_x_constraint PROTO((PROTO_DECL2 fix31 orus,fix31 pix));
static	fix31 hstemweight PROTO((PROTO_DECL2 fix31 dy));
static	void add_y_constraint PROTO((PROTO_DECL2 fix31 orus,fix31 pix));
static	void update_x_trans PROTO((PROTO_DECL1));
static	void update_y_trans PROTO((PROTO_DECL1));


FUNCTION void 
init_trans_a(PARAMS2 matrix, font_bbox)
GDECL
real STACKFAR*matrix;
fbbox_t STACKFAR*font_bbox;
/*
 * Called to initialize the transformation mechanism for a new font or
 * transformation matrix 
 */
{
	int             i;
	font_hints_t   STACKFAR*pfont_hints;	/* Font hints structure */

	void            set_mode_flags();
	void            set_fixed_point();
	font_hints_t   STACKFAR*tr_get_font_hints();
	void            set_blue_values();
	void            set_stem_tables();

#if DEBUG
	printf("LocalMatrix = [%7.5f, %7.5f, %7.5f, %7.5f, %7.5f, %7.5f]\n",
	       (double) matrix[0],
	       (double) matrix[1],
	       (double) matrix[2],
	       (double) matrix[3],
	       (double) matrix[4],
	       (double) matrix[5]);

	printf("FontBBox = { %3.1f %3.1f %3.1f %3.1f}\n",
	font_bbox->xmin, font_bbox->ymin, font_bbox->xmax, font_bbox->ymax);

	pfont_hints = tr_get_font_hints(PARAMS1);

	printf("BlueValues = [");
	for (i = 0; i < pfont_hints->no_blue_values; i++)
		printf(" %d", pfont_hints->pblue_values[i]);
	printf("]\n");

	printf("OtherBlues = [");
	for (i = 0; i < pfont_hints->no_other_blues; i++)
		printf(" %d", pfont_hints->pother_blues[i]);
	printf("]\n");

	printf("FamilyBlues = [");
	for (i = 0; i < pfont_hints->no_fam_blues; i++)
		printf(" %d", pfont_hints->pfam_blues[i]);
	printf("]\n");

	printf("FamilyOtherBlues = [");
	for (i = 0; i < pfont_hints->no_fam_other_blues; i++)
		printf(" %d", pfont_hints->pfam_other_blues[i]);
	printf("]\n");

	printf("BlueScale = %8.6f\n", pfont_hints->blue_scale);

	printf("BlueShift = %d\n", pfont_hints->blue_shift);

	printf("BlueFuzz = %d\n", pfont_hints->blue_fuzz);

	printf("StdHW = %3.1f\n", pfont_hints->stdhw);

	printf("StdVW = %3.1f\n", pfont_hints->stdvw);

	printf("StemSnapH = [");
	for (i = 0; i < pfont_hints->no_stem_snap_h; i++) {
		printf(" %3.1f", pfont_hints->pstem_snap_h[i]);
		if ((i != 0) && (pfont_hints->pstem_snap_h[i] < pfont_hints->pstem_snap_h[i - 1]))
			printf("(***out or order***)");
	}
	printf("]\n");

	printf("StemSnapV = [");
	for (i = 0; i < pfont_hints->no_stem_snap_v; i++) {
		printf(" %3.1f", pfont_hints->pstem_snap_v[i]);
		if ((i != 0) && (pfont_hints->pstem_snap_h[i] < pfont_hints->pstem_snap_h[i - 1]))
			printf("(***out or order***)");
	}
	printf("]\n");

	printf("ForceBold = %s\n", pfont_hints->force_bold ? "true" : "false");

#endif

	/* Copy linear transformation matrix into static storage */
	for (i = 0; i < 6; i++) {
		sp_globals.processor.type1.local_matrix[i] = matrix[i];
	}

	set_mode_flags(PARAMS2 font_bbox);
	set_fixed_point(PARAMS2 matrix, font_bbox);

	for (i = 0; i < 6; i++) {
		sp_globals.processor.type1.local_matrix_i[i] = (fix31) ROUND(matrix[i] * (real) sp_globals.processor.type1.mk_onepix);
	}

	pfont_hints = tr_get_font_hints(PARAMS1);
	set_blue_values(PARAMS2 (font_hints_t STACKFAR *)pfont_hints);
	set_stem_tables(PARAMS2 (font_hints_t STACKFAR *)pfont_hints);

#if DEBUG
	printf("Transformation mode flags:\n");
	SHOWB(sp_globals.processor.type1.non_linear_X);
	SHOWD(sp_globals.processor.type1.x_trans_mode);
	SHOWR(sp_globals.processor.type1.x_pix_per_oru);
	SHOWB(sp_globals.processor.type1.non_linear_Y);
	SHOWD(sp_globals.processor.type1.y_trans_mode);
	SHOWR(sp_globals.processor.type1.y_pix_per_oru);

	printf("\nProcessed blue value data (Top zones)\n");
	for (i = 0; i < sp_globals.processor.type1.no_top_zones; i++) {
		printf("%6.1f %6.1f %8.3f\n",
		       (real) sp_globals.processor.type1.top_zones[i].bottom_orus / 16.0, (real) sp_globals.processor.type1.top_zones[i].top_orus / 16.0, (real) sp_globals.processor.type1.top_zones[i].pix / (real) sp_globals.processor.type1.mk_onepix);
	}

	printf("\nProcessed blue value data (Bottom zones)\n");
	for (i = 0; i < sp_globals.processor.type1.no_bottom_zones; i++) {
		printf("%6.1f %6.1f %8.3f\n",
		       (real) sp_globals.processor.type1.bottom_zones[i].bottom_orus / 16.0, (real) sp_globals.processor.type1.bottom_zones[i].top_orus / 16.0, (real) sp_globals.processor.type1.bottom_zones[i].pix / (real) sp_globals.processor.type1.mk_onepix);
	}

	printf("\nStandard vertical stem control\n");
	printf("%6.1f %6.1f %8.3f\n",
	       sp_globals.processor.type1.vstem_std.min_orus, sp_globals.processor.type1.vstem_std.max_orus, sp_globals.processor.type1.vstem_std.pix);

	printf("\nStandard horizontal stem control\n");
	printf("%6.1f %6.1f %8.3f\n",
	       sp_globals.processor.type1.hstem_std.min_orus, sp_globals.processor.type1.hstem_std.max_orus, sp_globals.processor.type1.hstem_std.pix);

	if (sp_globals.processor.type1.no_vstem_snaps != 0) {
		printf("\nVertical stem snap table\n");
		for (i = 0; i < sp_globals.processor.type1.no_vstem_snaps; i++) {
			printf("%6.1f %6.1f %8.3f\n",
			       sp_globals.processor.type1.vstem_snaps[i].min_orus, sp_globals.processor.type1.vstem_snaps[i].max_orus, sp_globals.processor.type1.vstem_snaps[i].pix);
		}
	}
	if (sp_globals.processor.type1.no_hstem_snaps != 0) {
		printf("\nHorizontal stem snap table\n");
		for (i = 0; i < sp_globals.processor.type1.no_hstem_snaps; i++) {
			printf("%6.1f %6.1f %8.3f\n",
			       sp_globals.processor.type1.hstem_snaps[i].min_orus, sp_globals.processor.type1.hstem_snaps[i].max_orus, sp_globals.processor.type1.hstem_snaps[i].pix);
		}
	}
#endif
}



FUNCTION void 
set_mode_flags(PARAMS2 font_bbox)
	GDECL
	fbbox_t        STACKFAR*font_bbox;
/*
 * Sets up the transformation mode flags 
 */
{
	real            xrange;	/* Fontwide range of X oru values */
	real            yrange;	/* Fontwide range of Y oru values */
	real            dxdx;	/* Variation of transformed X over X range */
	real            dydx;	/* Variation of transformed Y over X range */
	real            dxdy;	/* Variation of transformed X over Y range */
	real            dydy;	/* Variation of transformed Y over Y range */
	real            thresh = 0.5;	/* Half pixel threshold over range */

	/* Set defaults for linear transformation */
	sp_globals.processor.type1.non_linear_X = FALSE;
	sp_globals.processor.type1.non_linear_Y = FALSE;
	sp_globals.processor.type1.x_trans_mode = 0;
	sp_globals.processor.type1.y_trans_mode = 0;
	sp_globals.processor.type1.no_x_breaks = 0;
	sp_globals.processor.type1.no_y_breaks = 0;
	sp_globals.processor.type1.x_trans_ready = FALSE;
	sp_globals.processor.type1.y_trans_ready = FALSE;
	sp_globals.processor.type1.vstem3_active = FALSE;
	sp_globals.processor.type1.hstem3_active = FALSE;

	/* Calculate partial differentials */
	xrange = font_bbox->xmax - font_bbox->xmin;
	yrange = font_bbox->ymax - font_bbox->ymin;
	dxdx = sp_globals.processor.type1.local_matrix[0] * xrange;
	dydx = sp_globals.processor.type1.local_matrix[1] * xrange;
	dxdy = sp_globals.processor.type1.local_matrix[2] * yrange;
	dydy = sp_globals.processor.type1.local_matrix[3] * yrange;

	if (dxdx > thresh) {	/* Transformed X increases over X range? */
		if (dxdy > thresh)	/* Transformed X increases over Y
					 * range? */
			goto next;
		if (dxdy < -thresh)	/* Transformed X decreases over Y
					 * range? */
			goto next;
		sp_globals.processor.type1.non_linear_X = TRUE;	/* X is a function of +X only */
		sp_globals.processor.type1.x_pix_per_oru = sp_globals.processor.type1.local_matrix[0];
		sp_globals.processor.type1.x_trans_mode = 1;
		goto next;
	}
	if (dxdx < -thresh) {	/* Transformed X decreases over X range? */
		if (dxdy > thresh)	/* Transformed X increases over Y
					 * range? */
			goto next;
		if (dxdy < -thresh)	/* Transformed X decreases over Y
					 * range? */
			goto next;
		sp_globals.processor.type1.non_linear_X = TRUE;	/* X is a function of -X only */
		sp_globals.processor.type1.x_pix_per_oru = -sp_globals.processor.type1.local_matrix[0];
		sp_globals.processor.type1.x_trans_mode = 2;
		goto next;
	}
	if (dxdy > thresh) {	/* Transformed X increases over Y range? */
		sp_globals.processor.type1.non_linear_Y = TRUE;	/* X is a function of +Y only */
		sp_globals.processor.type1.y_pix_per_oru = sp_globals.processor.type1.local_matrix[2];
		sp_globals.processor.type1.x_trans_mode = 3;
		goto next;
	}
	if (dxdy < -thresh) {	/* Transformed X decreases over Y range? */
		sp_globals.processor.type1.non_linear_Y = TRUE;	/* X is a function of -Y only */
		sp_globals.processor.type1.y_pix_per_oru = -sp_globals.processor.type1.local_matrix[2];
		sp_globals.processor.type1.x_trans_mode = 4;
		goto next;
	}
next:
	if (dydx > thresh) {	/* Transformed Y increases over X range? */
		if (dydy > thresh)	/* Transformed Y increases over Y
					 * range? */
			return;
		if (dydy < -thresh)	/* Transformed Y decreases over Y
					 * range? */
			return;
		sp_globals.processor.type1.non_linear_X = TRUE;	/* Y is a function of +X only */
		sp_globals.processor.type1.x_pix_per_oru = sp_globals.processor.type1.local_matrix[1];
		sp_globals.processor.type1.y_trans_mode = 1;
		return;
	}
	if (dydx < -thresh) {	/* Transformed Y decreases over X range? */
		if (dydy > thresh)	/* Transformed Y increases over Y
					 * range? */
			return;
		if (dydy < -thresh)	/* Transformed Y decreases over Y
					 * range? */
			return;
		sp_globals.processor.type1.non_linear_X = TRUE;	/* Y is a function of -X only */
		sp_globals.processor.type1.x_pix_per_oru = -sp_globals.processor.type1.local_matrix[1];
		sp_globals.processor.type1.y_trans_mode = 2;
		return;
	}
	if (dydy > thresh) {	/* Transformed Y increases over Y range? */
		sp_globals.processor.type1.non_linear_Y = TRUE;	/* Y is a function of +Y only */
		sp_globals.processor.type1.y_pix_per_oru = sp_globals.processor.type1.local_matrix[3];
		sp_globals.processor.type1.y_trans_mode = 3;
		return;
	}
	if (dydy < -thresh) {	/* Transformed Y decreases over Y range */
		sp_globals.processor.type1.non_linear_Y = TRUE;	/* Y is a function of -Y only */
		sp_globals.processor.type1.y_pix_per_oru = -sp_globals.processor.type1.local_matrix[3];
		sp_globals.processor.type1.y_trans_mode = 4;
		return;
	}
}


FUNCTION void 
real_trans_a(matrix, x, y)
real            STACKFAR*matrix;
real           STACKFAR*x, STACKFAR*y;

{
	real            X, Y;

	X = *x;
	Y = *y;

	*x = (X * *(real STACKFAR*)matrix) + (Y * *(real STACKFAR*)matrix+2) + *(real STACKFAR*)matrix+4;
	*y = (X * *(real STACKFAR*)matrix+1) + (Y * *(real STACKFAR*)matrix+3) + *(real STACKFAR*)matrix+5;
}


FUNCTION void 
set_fixed_point(PARAMS2 matrix, font_bbox)
GDECL
real            STACKFAR*matrix;
fbbox_t        STACKFAR*font_bbox;
/*
 * Sets up fixed point constants 
 */
{
	real            x, y, maxabs;
	real            temp1, temp2;
	real            xmax, xmin, ymax, ymin;

	/* recompute max and min using transformation matrix */
	x = font_bbox->xmin;
	y = font_bbox->ymin;
	real_trans_a(matrix, (real STACKFAR*)&x, (real STACKFAR*)&y);
	xmin = xmax = x;
	ymin = ymax = y;

	x = font_bbox->xmax;
	y = font_bbox->ymin;
	real_trans_a(matrix, (real STACKFAR*)&x, (real STACKFAR*)&y);
	if (x > xmax)
		xmax = x;
	if (x < xmin)
		xmin = x;
	if (y > ymax)
		ymax = y;
	if (y < ymin)
		ymin = y;

	x = font_bbox->xmax;
	y = font_bbox->ymax;
	real_trans_a(matrix, (real STACKFAR*)&x, (real STACKFAR*)&y);
	if (x > xmax)
		xmax = x;
	if (x < xmin)
		xmin = x;
	if (y > ymax)
		ymax = y;
	if (y < ymin)
		ymin = y;

	x = font_bbox->xmin;
	y = font_bbox->ymax;
	real_trans_a(matrix, (real STACKFAR*)&x, (real STACKFAR*)&y);
	if (x > xmax)
		xmax = x;
	if (x < xmin)
		xmin = x;
	if (y > ymax)
		ymax = y;
	if (y < ymin)
		ymin = y;

	temp1 = MAX(fabs(xmax), fabs(xmin));
	temp2 = MAX(fabs(ymax), fabs(ymin));
	maxabs = MAX(temp1, temp2);

	temp1 = MAX(fabs(font_bbox->xmax), fabs(font_bbox->xmin));
	temp2 = MAX(fabs(font_bbox->ymax), fabs(font_bbox->ymin));

	sp_globals.processor.type1.tr_shift = 16;

	x = 1000.0;

	while (sp_globals.processor.type1.tr_shift >= 0) {
		if (maxabs < x)
			break;
		sp_globals.processor.type1.tr_shift--;
		x *= 2.0;
	}

#if 0
	if (sp_globals.processor.type1.tr_shift < 0) {
		sp_report_error(PARAMS2 3);/* Transformation matrix out of range */
	}
#endif


	sp_globals.processor.type1.tr_poshift = 16 - sp_globals.processor.type1.tr_shift;
	sp_globals.processor.type1.tr_onepix = (fix31) 1 << sp_globals.processor.type1.tr_shift;
	sp_globals.processor.type1.tr_rnd = sp_globals.processor.type1.tr_onepix >> 1;
	sp_globals.processor.type1.tr_fix = 0xffff << sp_globals.processor.type1.tr_shift;
	sp_globals.processor.type1.mk_shift = sp_globals.processor.type1.tr_shift + 4;
	sp_globals.processor.type1.mk_fix = 0xffffffffL << sp_globals.processor.type1.mk_shift;
	sp_globals.processor.type1.mk_onepix = (fix31) 1 << sp_globals.processor.type1.mk_shift;
	sp_globals.processor.type1.mk_rnd = (fix31) sp_globals.processor.type1.tr_rnd << 4;

	sp_globals.processor.type1.x_pix_per_oru_i = (fix31) (sp_globals.processor.type1.x_pix_per_oru * (real) sp_globals.processor.type1.tr_onepix);
	sp_globals.processor.type1.y_pix_per_oru_i = (fix31) (sp_globals.processor.type1.y_pix_per_oru * (real) sp_globals.processor.type1.tr_onepix);
	sp_globals.processor.type1.x_pix_per_oru_r = sp_globals.processor.type1.x_pix_per_oru * (real) sp_globals.processor.type1.tr_onepix;
	sp_globals.processor.type1.y_pix_per_oru_r = sp_globals.processor.type1.y_pix_per_oru * (real) sp_globals.processor.type1.tr_onepix;
	sp_globals.processor.type1.fudge_x = (fix31) (sp_globals.processor.type1.x_pix_per_oru * (real) sp_globals.processor.type1.mk_onepix) - (sp_globals.processor.type1.x_pix_per_oru_i << 4);
	sp_globals.processor.type1.fudge_y = (fix31) (sp_globals.processor.type1.y_pix_per_oru * (real) sp_globals.processor.type1.mk_onepix) - (sp_globals.processor.type1.y_pix_per_oru_i << 4);
	sp_globals.processor.type1.fudge_x1 = sp_globals.processor.type1.fudge_x + 1;
	sp_globals.processor.type1.fudge_y1 = sp_globals.processor.type1.fudge_y + 1;
	sp_globals.processor.type1.pt_1 = (fix31) (0.1 * (real) sp_globals.processor.type1.mk_onepix);
	sp_globals.processor.type1.pt_2 = (fix31) (0.2 * (real) sp_globals.processor.type1.mk_onepix);
	sp_globals.processor.type1.pt_36 = (fix31) (0.36 * (real) sp_globals.processor.type1.mk_onepix);
	sp_globals.processor.type1.pt_725 = (fix31) (0.725 * (real) sp_globals.processor.type1.mk_onepix);
	sp_globals.processor.type1.pt_6 = (fix31) (0.6 * (real) sp_globals.processor.type1.mk_onepix);
	sp_globals.processor.type1.pt_875 = (fix31) (0.875 * (real) sp_globals.processor.type1.mk_onepix);
#if DEBUG
	SHOWI(sp_globals.processor.type1.x_pix_per_oru_i);
	SHOWI(sp_globals.processor.type1.y_pix_per_oru_i);
	SHOWI(sp_globals.processor.type1.pt_36);
	SHOWI(sp_globals.processor.type1.pt_725);
	SHOWI(sp_globals.processor.type1.pt_6);
	SHOWI(sp_globals.processor.type1.pt_875);
	SHOWD(sp_globals.processor.type1.tr_shift);
	SHOWI(sp_globals.processor.type1.tr_onepix);
	SHOWD(sp_globals.processor.type1.mk_shift);
	SHOWI(sp_globals.processor.type1.mk_onepix);
	SHOWI(sp_globals.processor.type1.mk_fix);
	SHOWI(sp_globals.processor.type1.fudge_x);
	SHOWI(sp_globals.processor.type1.fudge_y);
#endif
}


FUNCTION void 
set_blue_values(PARAMS2 pfont_hints)
GDECL
font_hints_t   STACKFAR*pfont_hints;
/*
 * Sets up data in sp_globals.processor.type1.top_zones[] and sp_globals.processor.type1.bottom_zones[] to control vertical
 * alignment 
 */
{
	int             i, j;
	boolean         suppr_oversht;	/* True if overshoot supression
					 * active */
	fix15           orus_per_half_pix;
	fix15           thresh;
	fix15           blue_shift;
	int             blue_fuzz;

	if (!sp_globals.processor.type1.non_linear_Y)	/* Hints not active in character Y dimension? */
		return;

	i = 0;
	for (j = 2; j < pfont_hints->no_blue_values;) {
		sp_globals.processor.type1.top_zones[i].bottom_orus = (fix15) ROUND(pfont_hints->pblue_values[j++] * 16.0);
		sp_globals.processor.type1.top_zones[i].top_orus = (fix15) ROUND(pfont_hints->pblue_values[j++] * 16.0);
		i++;
	}
	sp_globals.processor.type1.no_top_zones = i;

	i = 0;
	if (pfont_hints->no_blue_values >= 2) {
		sp_globals.processor.type1.bottom_zones[i].bottom_orus = (fix15) ROUND(pfont_hints->pblue_values[0] * 16.0);
		sp_globals.processor.type1.bottom_zones[i].top_orus = (fix15) ROUND(pfont_hints->pblue_values[1] * 16.0);
		i++;
	}
	for (j = 0; j < pfont_hints->no_other_blues;) {
		sp_globals.processor.type1.bottom_zones[i].bottom_orus = (fix15) ROUND(pfont_hints->pother_blues[j++] * 16.0);
		sp_globals.processor.type1.bottom_zones[i].top_orus = (fix15) ROUND(pfont_hints->pother_blues[j++] * 16.0);
		i++;
	}
	sp_globals.processor.type1.no_bottom_zones = i;

	if (pfont_hints->blue_scale > -1.0) {	/* BlueScale specified in
						 * font? */
		suppr_oversht = (sp_globals.processor.type1.y_pix_per_oru < pfont_hints->blue_scale);
	} else {
		/*
		 * suppr_oversht = (sp_globals.processor.type1.y_pix_per_oru < 0.039625); /* Default is
		 * 10 pt @ 300 dpi 
		 */
		suppr_oversht = (sp_globals.processor.type1.y_pix_per_oru < 0.041666666);	/* Default is 10 pt @
								 * 300 dpi */
	}

	orus_per_half_pix = ((fix15) (0.5 / sp_globals.processor.type1.y_pix_per_oru)) << 4;
	if (pfont_hints->blue_shift > -1) {	/* BlueShift specified in
						 * font? */
		blue_shift = pfont_hints->blue_shift << 4;
		thresh = (orus_per_half_pix > (pfont_hints->blue_shift << 4)) ?
			pfont_hints->blue_shift << 4 :
			orus_per_half_pix;
	} else {		/* No BlueShift keyword in font? */
		pfont_hints->blue_shift = 7;
		blue_shift = 7 << 4;
		thresh = (orus_per_half_pix > (7 << 4)) ?	/* Use default value of
								 * 7 */
			(7 << 4) :
			orus_per_half_pix;
	}

	if (pfont_hints->blue_fuzz > -1) {	/* BlueFuzz specified in
						 * font? */
		blue_fuzz = pfont_hints->blue_fuzz << 4;	/* Use value from font */
	} else {		/* No BlueFuzz keyword in font? */
		blue_fuzz = 1 << 4;	/* Use default value of 1 */
	}

	for (i = 0; i < sp_globals.processor.type1.no_top_zones; i++) {
		sp_globals.processor.type1.top_zones[i].pix = (sp_globals.processor.type1.top_zones[i].top_orus * sp_globals.processor.type1.y_pix_per_oru_i
			      + ((sp_globals.processor.type1.top_zones[i].bottom_orus >> 4) * sp_globals.processor.type1.fudge_y1)
				    + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
		if (suppr_oversht) {
			sp_globals.processor.type1.top_zones[i].bottom_orus -= blue_fuzz;
			sp_globals.processor.type1.top_zones[i].top_orus += blue_fuzz;
		} else {
			sp_globals.processor.type1.top_zones[i].top_orus = ((fix31) ((real) (sp_globals.processor.type1.top_zones[i].pix >> sp_globals.processor.type1.mk_shift) * 1.0 / sp_globals.processor.type1.y_pix_per_oru) << 4) + orus_per_half_pix;
			sp_globals.processor.type1.top_zones[i].bottom_orus = sp_globals.processor.type1.top_zones[i].bottom_orus + blue_shift;
			sp_globals.processor.type1.top_zones[i].pix += sp_globals.processor.type1.mk_onepix;
			sp_globals.processor.type1.top_zones[i].bottom_orus -= blue_fuzz;
			sp_globals.processor.type1.top_zones[i].top_orus += blue_fuzz;
		}
	}

	for (i = 0; i < sp_globals.processor.type1.no_bottom_zones; i++) {
		sp_globals.processor.type1.bottom_zones[i].pix = (sp_globals.processor.type1.bottom_zones[i].top_orus * sp_globals.processor.type1.y_pix_per_oru_i
			      + ((sp_globals.processor.type1.bottom_zones[i].top_orus >> 4) * sp_globals.processor.type1.fudge_y1)
				       + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
		sp_globals.processor.type1.bottom_zones[i].top_orus += blue_fuzz;
		if (suppr_oversht) {
			sp_globals.processor.type1.bottom_zones[i].bottom_orus -= blue_fuzz;
		} else {
			sp_globals.processor.type1.bottom_zones[i].bottom_orus = sp_globals.processor.type1.bottom_zones[i].top_orus - thresh - blue_fuzz;
		}
	}

}


FUNCTION void 
set_stem_tables(PARAMS2 pfont_hints)
GDECL
font_hints_t   STACKFAR*pfont_hints;
/*
 * Sets up data tables to control stem weight calculation 
 */
{
	real            thresh;
	real            thresh1;
	real            thresh2;
	real            stdvw_pix;
	real            stdhw_pix;
	int             i;

	char           STACKFAR*tr_get_fnt_name();

	/* Set minimum stem weights */
	if (pfont_hints->force_bold) {
		sp_globals.processor.type1.minvstemweight = 2;
		sp_globals.processor.type1.minhstemweight = 2;
	} else {
		sp_globals.processor.type1.minvstemweight = 1;
		sp_globals.processor.type1.minhstemweight = 1;
	}

	/* Use stdVW for stdHW if latter is not specified */
	if (pfont_hints->stdhw == 0.0) {
		pfont_hints->stdhw = pfont_hints->stdvw;
	}
	/* Set up standard vertical stem weight control data */
	if (sp_globals.processor.type1.non_linear_X) {	/* Hints active in character X dimension? */
		stdvw_pix = pfont_hints->stdvw * sp_globals.processor.type1.x_pix_per_oru;	/* Standard vstem in
								 * pixels (unrounded) */
		sp_globals.processor.type1.vstem_std.pix = floor(stdvw_pix + 0.5);	/* Standard vstem in
							 * pixels (rounded) */
		if (sp_globals.processor.type1.vstem_std.pix < sp_globals.processor.type1.minvstemweight)
			sp_globals.processor.type1.vstem_std.pix = sp_globals.processor.type1.minvstemweight;
		thresh1 = stdvw_pix - 0.36;
		thresh2 = sp_globals.processor.type1.vstem_std.pix -.725;
		sp_globals.processor.type1.vstem_std.min_orus = ((thresh1 > thresh2) ? thresh1 : thresh2) / sp_globals.processor.type1.x_pix_per_oru;
		thresh1 = stdvw_pix + 0.6;
		thresh2 = sp_globals.processor.type1.vstem_std.pix +.875;
		sp_globals.processor.type1.vstem_std.max_orus = ((thresh1 < thresh2) ? thresh1 : thresh2) / sp_globals.processor.type1.x_pix_per_oru;
	}
	/* Set up standard horizontal stem weight control data */
	if (sp_globals.processor.type1.non_linear_Y) {	/* Hints active in character Y dimension? */
		stdhw_pix = pfont_hints->stdhw * sp_globals.processor.type1.y_pix_per_oru;	/* Standard hstem in
								 * pixels (unrounded) */
		sp_globals.processor.type1.hstem_std.pix = floor(stdhw_pix + 0.5);	/* Standard hstem in
							 * pixels (rounded) */
		if (sp_globals.processor.type1.hstem_std.pix < sp_globals.processor.type1.minhstemweight)
			sp_globals.processor.type1.hstem_std.pix = sp_globals.processor.type1.minhstemweight;
		thresh1 = stdhw_pix - 0.36;
		thresh2 = sp_globals.processor.type1.hstem_std.pix -.725;
		sp_globals.processor.type1.hstem_std.min_orus = ((thresh1 > thresh2) ? thresh1 : thresh2) / sp_globals.processor.type1.y_pix_per_oru;
		thresh1 = stdhw_pix + 0.6;
		thresh2 = sp_globals.processor.type1.hstem_std.pix +.875;
		sp_globals.processor.type1.hstem_std.max_orus = ((thresh1 < thresh2) ? thresh1 : thresh2) / sp_globals.processor.type1.y_pix_per_oru;
	}
	/* Set up vertical stem snap table */
	if (sp_globals.processor.type1.non_linear_X) {	/* Hints active in character X dimension? */
		thresh = 0.5 / sp_globals.processor.type1.y_pix_per_oru;	/* one half pixel */
		sp_globals.processor.type1.no_vstem_snaps = pfont_hints->no_stem_snap_v;
		for (i = 0; i < sp_globals.processor.type1.no_vstem_snaps; i++) {
			sp_globals.processor.type1.vstem_snaps[i].min_orus = pfont_hints->pstem_snap_v[i] - thresh;
			sp_globals.processor.type1.vstem_snaps[i].max_orus = pfont_hints->pstem_snap_v[i] + thresh;
			sp_globals.processor.type1.vstem_snaps[i].pix = floor(pfont_hints->pstem_snap_v[i] * sp_globals.processor.type1.x_pix_per_oru + 0.5);
			if (sp_globals.processor.type1.vstem_snaps[i].pix < sp_globals.processor.type1.minvstemweight)
				sp_globals.processor.type1.vstem_snaps[i].pix = sp_globals.processor.type1.minvstemweight;
		}
	}
	/* Set up horizontal stem snap table */
	if (sp_globals.processor.type1.non_linear_Y) {	/* Hints active in character Y dimension? */
		thresh = 0.5 / sp_globals.processor.type1.y_pix_per_oru;	/* one half pixel */
		sp_globals.processor.type1.no_hstem_snaps = pfont_hints->no_stem_snap_h;
		for (i = 0; i < sp_globals.processor.type1.no_hstem_snaps; i++) {
			sp_globals.processor.type1.hstem_snaps[i].min_orus = pfont_hints->pstem_snap_h[i] - thresh;
			sp_globals.processor.type1.hstem_snaps[i].max_orus = pfont_hints->pstem_snap_h[i] + thresh;
			sp_globals.processor.type1.hstem_snaps[i].pix = floor(pfont_hints->pstem_snap_h[i] * sp_globals.processor.type1.y_pix_per_oru + 0.5);
			if (sp_globals.processor.type1.hstem_snaps[i].pix < sp_globals.processor.type1.minhstemweight)
				sp_globals.processor.type1.hstem_snaps[i].pix = sp_globals.processor.type1.minhstemweight;
		}
	}
	sp_globals.processor.type1.i_minvstemweight = (fix31) ROUND(sp_globals.processor.type1.minvstemweight * (real) sp_globals.processor.type1.mk_onepix);
	sp_globals.processor.type1.i_minhstemweight = (fix31) ROUND(sp_globals.processor.type1.minhstemweight * (real) sp_globals.processor.type1.mk_onepix);

	sp_globals.processor.type1.i_vstem_std.min_orus = (fix15) ROUND(sp_globals.processor.type1.vstem_std.min_orus * 16.0);
	sp_globals.processor.type1.i_vstem_std.max_orus = (fix15) ROUND(sp_globals.processor.type1.vstem_std.max_orus * 16.0);
	sp_globals.processor.type1.i_vstem_std.pix = (fix31) ROUND(sp_globals.processor.type1.vstem_std.pix * (real) sp_globals.processor.type1.mk_onepix);

	sp_globals.processor.type1.i_hstem_std.min_orus = (fix15) ROUND(sp_globals.processor.type1.hstem_std.min_orus * 16.0);
	sp_globals.processor.type1.i_hstem_std.max_orus = (fix15) ROUND(sp_globals.processor.type1.hstem_std.max_orus * 16.0);
	sp_globals.processor.type1.i_hstem_std.pix = (fix31) ROUND(sp_globals.processor.type1.hstem_std.pix * (real) sp_globals.processor.type1.mk_onepix);

	if (sp_globals.processor.type1.no_vstem_snaps != 0) {
		for (i = 0; i < sp_globals.processor.type1.no_vstem_snaps; i++) {
			sp_globals.processor.type1.i_vstem_snaps[i].min_orus = (fix15) ROUND(sp_globals.processor.type1.vstem_snaps[i].min_orus * 16.0);
			sp_globals.processor.type1.i_vstem_snaps[i].max_orus = (fix15) ROUND(sp_globals.processor.type1.vstem_snaps[i].max_orus * 16.0);
			sp_globals.processor.type1.i_vstem_snaps[i].pix = (fix31) ROUND(sp_globals.processor.type1.vstem_snaps[i].pix * (real) sp_globals.processor.type1.mk_onepix);
		}
	}
	if (sp_globals.processor.type1.no_hstem_snaps != 0) {
		for (i = 0; i < sp_globals.processor.type1.no_hstem_snaps; i++) {
			sp_globals.processor.type1.i_hstem_snaps[i].min_orus = (fix15) ROUND(sp_globals.processor.type1.hstem_snaps[i].min_orus * 16.0);
			sp_globals.processor.type1.i_hstem_snaps[i].max_orus = (fix15) ROUND(sp_globals.processor.type1.hstem_snaps[i].max_orus * 16.0);
			sp_globals.processor.type1.i_hstem_snaps[i].pix = (fix31) ROUND(sp_globals.processor.type1.hstem_snaps[i].pix * (real) sp_globals.processor.type1.mk_onepix);
		}
	}
}




FUNCTION void 
clear_constraints(PARAMS1)
GDECL
/*
 * Called at the start of each character or hint replacement operation
 * Discards the current set of constraints in both X and Y dimensions 
 */
{
#if DEBUG
	printf("clear_constraints()\n");
#endif

	sp_globals.processor.type1.no_x_breaks = 0;
	sp_globals.processor.type1.x_trans_ready = FALSE;
	sp_globals.processor.type1.no_y_breaks = 0;
	sp_globals.processor.type1.y_trans_ready = FALSE;
	sp_globals.processor.type1.vstem3_active = FALSE;
	sp_globals.processor.type1.hstem3_active = FALSE;
}


FUNCTION void 
do_hstem(PARAMS2 sby, y, dy)
	GDECL
	fix31           sby;	/* Sidebearing Y coordinate */
	fix31           y;	/* Y coordinate of first edge of stem */
	fix31           dy;	/* Stem thickness */
/*
 * Adds a horizontal stem constraint to the piecewise linear transformation 
 */
{
	fix31           y1;
	fix31           y2;
#if EDGE_ALIGN
	fix31           y1_pix_top, y1_pix_bottom;
#else
	fix31           y1_pix;
#endif

	void            align_hstem();

#if DEBUG
	printf("do_hstem(%3.1f, %3.1f, %3.1f)\n", (real) sby / 16.0, (real) y / 16.0, (real) dy / 16.0);
#endif

	if ((!sp_globals.processor.type1.non_linear_Y) ||	/* Hints not active in character Y dimension? */
	    (sp_globals.processor.type1.hstem3_active))
		return;

	if (dy >= 0) {
		y1 = sby + y;
		y2 = y1 + dy;
	} else {
		y2 = sby + y;
		y1 = y2 + dy;
	}
#if EDGE_ALIGN
	align_hstem(PARAMS2 y1, y2, (fix31 STACKFAR*)&y1_pix_bottom, (fix31 STACKFAR*)&y1_pix_top);
#else
	align_hstem(PARAMS2 y1, y2, (fix31 STACKFAR*)&y1_pix);
#endif
}



#if EDGE_ALIGN
FUNCTION void 
do_hstem3(PARAMS2 sby, y0, dy0, y1, dy1, y2, dy2)
	GDECL
	fix31           sby;	/* Sidebearing Y coordinate */
	fix31           y0;
	fix31           dy0;
	fix31           y1;
	fix31           dy1;
	fix31           y2;
	fix31           dy2;
{
	fix31           bottom;
	fix31           temp_bottom;
	fix31           pix_bottom, tpix_bottom, bpix_bottom;
	fix31           pix_top, tpix_top, bpix_top;
	fix31           t, t1, t2;

	fix31           strkwt_pix;	/* Thickness of center stroke in
					 * device units */

	void            hint_sort3();
	void            align_hstem();
	fix31           hstemweight();
	void            add_y_constraint();

#if DEBUG
	printf("do_hstem3(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n",
	       (real) sby / 16.0, (real) y0 / 16.0, (real) dy0 / 16.0, (real) y1 / 16.0, (real) dy1 / 16.0, (real) y2 / 16.0, (real) dy2 / 16.0);
#endif

	if (!sp_globals.processor.type1.non_linear_Y)	/* Hints not active in character Y dimension? */
		return;

	/* check for negative widths */
	if (dy0 < 0) {
		y0 += dy0;	/* make y0 be the bottom edge of the bar */
		dy0 = dy0 * -1;	/* make the width positive */
	}
	if (dy1 < 0) {
		y1 += dy1;	/* make y1 be the bottom edge of the bar */
		dy1 = dy1 * -1;	/* make the width positive */
	}
	if (dy2 < 0) {
		y2 += dy2;	/* make y2 be the bottom edge of the bar */
		dy2 = dy2 * -1;	/* make the width positive */
	}
	hint_sort3((fix31 STACKFAR*)&y0, (fix31 STACKFAR*)&dy0, (fix31 STACKFAR*)&y1, (fix31 STACKFAR*)&dy1, (fix31 STACKFAR*)&y2, (fix31 STACKFAR*)&dy2);	/* Sort strokes into
							 * ascending order */

	/* Position center stroke */
	strkwt_pix = hstemweight(PARAMS2 dy1);	/* Compute weight of center stroke */
	bottom = sby + y1;	/* bottom edge of center stroke */
	temp_bottom = (bottom * sp_globals.processor.type1.y_pix_per_oru_i) + ((bottom >> 4) * sp_globals.processor.type1.fudge_x);
	pix_bottom = (temp_bottom + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to pixel
							 * boundary */
	pix_top = pix_bottom + strkwt_pix;
	add_y_constraint(PARAMS2 bottom, pix_bottom);	/* Constrain edges */
	add_y_constraint(PARAMS2 bottom + dy1, pix_top);

	/* Position bottom stroke */
	strkwt_pix = hstemweight(PARAMS2 dy0);	/* Compute weight of bottom stroke */
	bottom = sby + y0;	/* bottom edge of bottom stroke */
	temp_bottom = (bottom * sp_globals.processor.type1.y_pix_per_oru_i) + ((bottom >> 4) * sp_globals.processor.type1.fudge_x);
	bpix_bottom = (temp_bottom + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to pixel
							 * boundary */
	bpix_top = bpix_bottom + strkwt_pix;

	/* Position top stroke */
	strkwt_pix = hstemweight(PARAMS2 dy2);	/* Compute weight of top stroke */
	bottom = sby + y2;	/* bottom edge of top stroke */
	temp_bottom = (bottom * sp_globals.processor.type1.y_pix_per_oru_i) + ((bottom >> 4) * sp_globals.processor.type1.fudge_x);
	tpix_bottom = (temp_bottom + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to pixel
							 * boundary */
	tpix_top = tpix_bottom + strkwt_pix;

	/* ensure even spacing after rounding */
	t = (pix_bottom + pix_top) >> 1;
	t1 = t - ((bpix_bottom + bpix_top) >> 1);
	t2 = ((tpix_bottom + tpix_top) >> 1) - t;

	if (t1 > t2) {		/* adjust narrower if necessary - bottom
				 * stroke */
		t = t1 - t2;
		bpix_bottom = (bpix_bottom + t + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
		bpix_top = (bpix_top + t + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
	} else if (t2 > t1) {	/* adjust narrower if necessary - top stroke */
		t = t2 - t1;
		tpix_bottom = (tpix_bottom - t + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
		tpix_top = (tpix_top - t + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
	}
	add_y_constraint(PARAMS2 sby + y0, bpix_bottom);	/* Constrain edges */
	add_y_constraint(PARAMS2 sby + y0 + dy0, bpix_top);
	add_y_constraint(PARAMS2 sby + y2, tpix_bottom);	/* Constrain edges */
	add_y_constraint(PARAMS2 sby + y2 + dy2, tpix_top);


	sp_globals.processor.type1.hstem3_active = TRUE;

}
#else
FUNCTION void 
do_hstem3(PARAMS2 sby, y0, dy0, y1, dy1, y2, dy2)
	GDECL
	fix31           sby;	/* Sidebearing Y coordinate */
	fix31           y0;
	fix31           dy0;
	fix31           y1;
	fix31           dy1;
	fix31           y2;
	fix31           dy2;
{
	fix31           cy1;	/* Centerline of middle stroke in outline
				 * units */
	fix31           cy0_pix;/* Centerline of lower stroke in device units */
	fix31           cy1_pix;/* Centerline of middle stroke in device
				 * units */
	fix31           cy2_pix;/* Centerline of upper stroke in device units */
	fix31           strkwt_pix;	/* Thickness of center stroke in
					 * device units */

	void            hint_sort3();
	void            align_hstem();
	fix31           hstemweight();
	void            add_y_constraint();

#if DEBUG
	printf("do_hstem3(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n",
	       (real) sby / 16.0, (real) y0 / 16.0, (real) dy0 / 16.0, (real) y1 / 16.0, (real) dy1 / 16.0, (real) y2 / 16.0, (real) dy2 / 16.0);
#endif

	if (!sp_globals.processor.type1.non_linear_Y)	/* Hints not active in character Y dimension? */
		return;

	/* check for negative widths */
	if (dy0 < 0) {
		y0 += dy0;	/* make y0 be the bottom edge of the bar */
		dy0 = dy0 * -1;	/* make the width positive */
	}
	if (dy1 < 0) {
		y1 += dy1;	/* make y1 be the bottom edge of the bar */
		dy1 = dy1 * -1;	/* make the width positive */
	}
	if (dy2 < 0) {
		y2 += dy2;	/* make y2 be the bottom edge of the bar */
		dy2 = dy2 * -1;	/* make the width positive */
	}
	hint_sort3((fix31 STACKFAR*)&y0, (fix31 STACKFAR*)&dy0, (fix31 STACKFAR*)&y1, (fix31 STACKFAR*)&dy1, (fix31 STACKFAR*)&y2, (fix31 STACKFAR*)&dy2);	/* Sort strokes into
							 * ascending order */

	align_hstem(PARAMS2 sby + y0, sby + y0 + dy0, (fix31 STACKFAR*)&cy0_pix);	/* Align lower stroke */

	align_hstem(PARAMS2 sby + y2, sby + y2 + dy2, (fix31 STACKFAR*)&cy2_pix);	/* Align upper stroke */

	strkwt_pix = hstemweight(PARAMS2 dy1);	/* Compute stroke weight of center
					 * stroke */

	cy1 = sby + y1 + (dy1 >> 1);
	cy1_pix = (cy0_pix + cy2_pix + sp_globals.processor.type1.pt_1) >> 1;
	if (strkwt_pix & sp_globals.processor.type1.mk_onepix) {	/* Odd number of pixels? */
		cy1_pix = (cy1_pix & sp_globals.processor.type1.mk_fix) + sp_globals.processor.type1.mk_rnd;	/* Round to nearest
							 * pixel center */
	} else {
		cy1_pix = ((cy1_pix + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix);	/* Round to nearest
								 * pixel boundary */
	}

	add_y_constraint(PARAMS2 cy1, cy1_pix);
	sp_globals.processor.type1.hstem3_active = TRUE;
}
#endif


FUNCTION void 
do_vstem(PARAMS2 sbx, x, dx)
	GDECL
	fix31           sbx;	/* Sidebearing X coordinate */
	fix31           x;	/* X coordinate of first edge of stem */
	fix31           dx;	/* Stem thickness */
/*
 * Adds a vertical stem constraint to the piecewise linear transformation 
 */
{
	fix31           x1;
	fix31           x2;

	void            align_vstem();

#if DEBUG
	printf("do_vstem(%3.1f, %3.1f, %3.1f)\n", (real) sbx / 16.0, (real) x / 16.0, (real) dx / 16.0);
#endif

	if ((!sp_globals.processor.type1.non_linear_X) ||	/* Hints not active in character X dimension? */
	    (sp_globals.processor.type1.vstem3_active))
		return;

	if (dx >= 0) {
		x1 = sbx + x;
		x2 = x1 + dx;
	} else {
		x2 = sbx + x;
		x1 = x2 + dx;
	}


	align_vstem(PARAMS2 x1, x2);
}


#if EDGE_ALIGN
FUNCTION void 
do_vstem3(PARAMS2 sbx, x0, dx0, x1, dx1, x2, dx2)
	GDECL
	fix31           sbx;	/* Sidebearing X coordinate */
	fix31           x0;	/* First edge of a stroke */
	fix31           dx0;	/* Stroke thickness */
	fix31           x1;	/* First edge of another stroke */
	fix31           dx1;	/* Stroke thickness */
	fix31           x2;	/* First edge of a third stroke */
	fix31           dx2;	/* Stroke thickness */
{
	fix31           left;	/* left edge of mddle stroke in outline units */
	fix31           temp_left;
	fix31           strkwt_pix;	/* Thickness of center stroke in
					 * device units */
	fix31           pix_left, lpix_left, rpix_left;
	fix31           pix_right, lpix_right, rpix_right;
	fix31           t, t1, t2;

	void            hint_sort3();
	fix31           vstemweight();
	void            add_x_constraint();

#if DEBUG
	printf("do_vstem3(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n",
	       (real) sbx / 16.0, (real) x0 / 16.0, (real) dx0 / 16.0, (real) x1 / 16.0, (real) dx1 / 16.0, (real) x2 / 16.0, (real) dx2 / 16.0);
#endif

	if (!sp_globals.processor.type1.non_linear_X)	/* Hints not active in character X dimension? */
		return;

	/* check for negative widths */
	if (dx0 < 0) {
		x0 += dx0;	/* make x0 be the left edge of the bar */
		dx0 = dx0 * -1;	/* make the width positive */
	}
	if (dx1 < 0) {
		x1 += dx1;	/* make x1 be the left edge of the bar */
		dx1 = dx1 * -1;	/* make the width positive */
	}
	if (dx2 < 0) {
		x2 += dx2;	/* make x2 be the left edge of the bar */
		dx2 = dx2 * -1;	/* make the width positive */
	}
	hint_sort3((fix31 STACKFAR*)&x0, (fix31 STACKFAR*)&dx0, (fix31 STACKFAR*)&x1, (fix31 STACKFAR*)&dx1, (fix31 STACKFAR*)&x2, (fix31 STACKFAR*)&dx2);

	/* Position center stroke */
	strkwt_pix = vstemweight(PARAMS2 dx1);	/* Compute weight of center stroke */
	left = sbx + x1;	/* left edge of center stroke */
	temp_left = (left * sp_globals.processor.type1.x_pix_per_oru_i) + ((left >> 4) * sp_globals.processor.type1.fudge_x);
	pix_left = (temp_left + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to pixel
							 * boundary */
	pix_right = pix_left + strkwt_pix;
	add_x_constraint(PARAMS2 left, pix_left);	/* Constrain edges */
	add_x_constraint(PARAMS2 left + dx1, pix_right);

	/* Position left stroke */
	strkwt_pix = vstemweight(PARAMS2 dx0);	/* Compute weight of left stroke */
	left = sbx + x0;	/* left edge of left stroke */
	temp_left = (left * sp_globals.processor.type1.x_pix_per_oru_i) + ((left >> 4) * sp_globals.processor.type1.fudge_x);
	lpix_left = (temp_left + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to pixel
							 * boundary */
	lpix_right = lpix_left + strkwt_pix;

	/* Position right stroke */
	strkwt_pix = vstemweight(PARAMS2 dx2);	/* Compute weight of right stroke */
	left = sbx + x2;	/* left edge of right stroke */
	temp_left = (left * sp_globals.processor.type1.x_pix_per_oru_i) + ((left >> 4) * sp_globals.processor.type1.fudge_x);
	rpix_left = (temp_left + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to pixel
							 * boundary */
	rpix_right = rpix_left + strkwt_pix;

	/* ensure even spacing after rounding */
	t = (pix_left + pix_right) >> 1;
	t1 = t - ((lpix_left + lpix_right) >> 1);
	t2 = ((rpix_left + rpix_right) >> 1) - t;

	if (t1 > t2) {		/* adjust narrower if necessary - left stroke */
		t = t1 - t2;
		lpix_left = (lpix_left + t + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
		lpix_right = (lpix_right + t + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
	} else if (t2 > t1) {	/* adjust narrower if necessary - right
				 * stroke */
		t = t2 - t1;
		rpix_left = (rpix_left - t + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
		rpix_right = (rpix_right - t + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
	}
	add_x_constraint(PARAMS2 sbx + x0, lpix_left);	/* Constrain edges */
	add_x_constraint(PARAMS2 sbx + x0 + dx0, lpix_right);
	add_x_constraint(PARAMS2 sbx + x2, rpix_left);	/* Constrain edges */
	add_x_constraint(PARAMS2 sbx + x2 + dx2, rpix_right);


	sp_globals.processor.type1.vstem3_active = TRUE;
}
#else
FUNCTION void 
do_vstem3(PARAMS2 sbx, x0, dx0, x1, dx1, x2, dx2)
	GDECL
	fix31           sbx;	/* Sidebearing X coordinate */
	fix31           x0;	/* First edge of a stroke */
	fix31           dx0;	/* Stroke thickness */
	fix31           x1;	/* First edge of another stroke */
	fix31           dx1;	/* Stroke thickness */
	fix31           x2;	/* First edge of a third stroke */
	fix31           dx2;	/* Stroke thickness */
{
	fix31           cx1;	/* Centerline of middle stroke in outline
				 * units */
	fix31           cx1_pix;/* Centerline of middle stroke in device
				 * units */
	fix31           strkwt0_pix;	/* Thickness of left and right
					 * strokes in device units */
	fix31           strkwt1_pix;	/* Thickness of center stroke in
					 * device units */
	fix31           xleft_pix;
	fix31           xright_pix;
	fix31           halfspan;	/* Center left stem to center middle
					 * stem in outline units */
	fix31           halfspan_pix;	/* Center left stem to center middle
					 * stem in device units */
	fix31           cx1_temp;
	fix31           halfspan_temp;

	void            hint_sort3();
	fix31           vstemweight();
	void            add_x_constraint();

#if DEBUG
	printf("do_vstem3(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n",
	       (real) sbx / 16.0, (real) x0 / 16.0, (real) dx0 / 16.0, (real) x1 / 16.0, (real) dx1 / 16.0, (real) x2 / 16.0, (real) dx2 / 16.0);
#endif

	if (!sp_globals.processor.type1.non_linear_X)	/* Hints not active in character X dimension? */
		return;

	/* check for negative widths */
	if (dx0 < 0) {
		x0 += dx0;	/* make x0 be the left edge of the bar */
		dx0 = dx0 * -1;	/* make the width positive */
	}
	if (dx1 < 0) {
		x1 += dx1;	/* make x1 be the left edge of the bar */
		dx1 = dx1 * -1;	/* make the width positive */
	}
	if (dx2 < 0) {
		x2 += dx2;	/* make x2 be the left edge of the bar */
		dx2 = dx2 * -1;	/* make the width positive */
	}
	hint_sort3((fix31 STACKFAR*)&x0, (fix31 STACKFAR*)&dx0, (fix31 STACKFAR*)&x1, (fix31 STACKFAR*)&dx1, (fix31 STACKFAR*)&x2, (fix31 STACKFAR*)&dx2);

	strkwt1_pix = vstemweight(PARAMS2 dx1);	/* Compute stroke weight of center
					 * stroke */

	/* Position center stroke */
	cx1 = sbx + x1 + (dx1 >> 1);	/* Centerline of center stroke */
	cx1_temp = (cx1 * sp_globals.processor.type1.x_pix_per_oru_i) + ((cx1 >> 4) * sp_globals.processor.type1.fudge_x);
	if (strkwt1_pix & sp_globals.processor.type1.mk_onepix) {	/* Center stroke has odd number of
					 * pixels? */
		cx1_pix = (cx1_temp & sp_globals.processor.type1.mk_fix) + sp_globals.processor.type1.mk_rnd;	/* Round centerline to
							 * pixel center */
	} else {
		cx1_pix = (cx1_temp + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round centerline to
							 * pixel boundary */
	}

	/* Constrain center stroke */
	add_x_constraint(PARAMS2 cx1, cx1_pix);

	strkwt0_pix = vstemweight(PARAMS2 dx0);	/* Compute stroke weight of left and
					 * right strokes */

	/* Position left and right strokes */
	halfspan = (x2 - x0) >> 1;
	halfspan_temp = (halfspan * sp_globals.processor.type1.x_pix_per_oru_i) + ((halfspan >> 4) * sp_globals.processor.type1.fudge_x);
	if ((strkwt0_pix + strkwt1_pix) & sp_globals.processor.type1.mk_onepix) {	/* Left + center stroke
							 * has odd number of
							 * pixels? */
		halfspan_pix = (halfspan_temp & sp_globals.processor.type1.mk_fix) + sp_globals.processor.type1.mk_rnd;	/* Round halfspan to
									 * nearest half pixel */
	} else {
		halfspan_pix = (halfspan_temp + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round halfspan to
									 * nearest pixel */
	}

	/* Constrain left stroke */
	add_x_constraint(PARAMS2 sbx + x0 + (dx0 >> 1), cx1_pix - halfspan_pix);

	/* Constrain right stroke */
	add_x_constraint(PARAMS2 sbx + x2 + (dx2 >> 1), cx1_pix + halfspan_pix);

	sp_globals.processor.type1.vstem3_active = TRUE;
}
#endif


FUNCTION void 
hint_sort3(px0, pdx0, px1, pdx1, px2, pdx2)
	fix31          STACKFAR*px0;
	fix31          STACKFAR*pdx0;
	fix31          STACKFAR*px1;
	fix31          STACKFAR*pdx1;
	fix31          STACKFAR*px2;
	fix31          STACKFAR*pdx2;
/*
 * Sorts a group of 3 stroke specs into ascending order 
 */
{
	void            hint_sort2();

	hint_sort2(px0, pdx0, px1, pdx1);
	hint_sort2(px1, pdx1, px2, pdx2);
	hint_sort2(px0, pdx0, px1, pdx1);
}


FUNCTION void 
hint_sort2(px0, pdx0, px1, pdx1)
	fix31          STACKFAR*px0;
	fix31          STACKFAR*pdx0;
	fix31          STACKFAR*px1;
	fix31          STACKFAR*pdx1;
/*
 * Sorts a pair of stroke specs into ascending order 
 */
{
	fix31           tmpfix31;

	if (*px0 > *px1) {
		tmpfix31 = *px0;
		*px0 = *px1;
		*px1 = tmpfix31;
		tmpfix31 = *pdx0;
		*pdx0 = *pdx1;
		*pdx1 = tmpfix31;
	}
}


#if EDGE_ALIGN
FUNCTION void 
align_vstem(PARAMS2 x1, x2)
	GDECL
	fix31           x1;	/* Left edge of stroke in outline units */
	fix31           x2;	/* Right edge of stroke in outline units */
/*
 * Aligns a vertical stem to whole pixel boundaries Returns pixel coordinates
 * of centerline of aligned stem 
 */
{
	fix31           strkwt_pix;	/* Thickness of stroke in device
					 * units */
	fix31           cx_pix_left;	/* left edge of stroke in device
					 * units */
	fix31           cx_temp_left;	/* right edge of stroke in device
					 * units */

	fix31           vstemweight();
	void            add_x_constraint();

	strkwt_pix = vstemweight(PARAMS2 x2 - x1);	/* Compute stroke weight */

	/*
	 * Position non-aligned zone for optimal stroke center position
	 * accuracy 
	 */
	cx_temp_left = (x1 * sp_globals.processor.type1.x_pix_per_oru_i) + ((x1 >> 4) * sp_globals.processor.type1.fudge_x);
	cx_pix_left = (cx_temp_left + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to nearest
							 * pixel boundary */

	add_x_constraint(PARAMS2 x1, cx_pix_left);
	add_x_constraint(PARAMS2 x2, cx_pix_left + strkwt_pix);

}
#else
FUNCTION void 
align_vstem(PARAMS2 x1, x2)
	GDECL
	fix31           x1;	/* Left edge of stroke in outline units */
	fix31           x2;	/* Right edge of stroke in outline units */
/*
 * Aligns a vertical stem to whole pixel boundaries Returns pixel coordinates
 * of centerline of aligned stem 
 */
{
	fix31           cx;	/* Position of centerline of stroke in
				 * outline units */
	fix31           strkwt_pix;	/* Thickness of stroke in device
					 * units */
	fix31           cx_pix;	/* Position of centerline of stroke in device
				 * units */
	fix31           cx_temp;/* Position of centerline of stroke in device
				 * units */

	fix31           vstemweight();
	void            add_x_constraint();

	strkwt_pix = vstemweight(PARAMS2 x2 - x1);	/* Compute stroke weight */

	/*
	 * Position non-aligned zone for optimal stroke center position
	 * accuracy 
	 */
	cx = (x1 + x2) >> 1;
	cx_temp = (cx * sp_globals.processor.type1.x_pix_per_oru_i) + ((cx >> 4) * sp_globals.processor.type1.fudge_x);
	if (strkwt_pix & sp_globals.processor.type1.mk_onepix) {	/* Odd number of pixels? */
		cx_pix = (cx_temp & sp_globals.processor.type1.mk_fix) + sp_globals.processor.type1.mk_rnd;	/* Round to nearest
							 * pixel center */
	} else {
		cx_pix = (cx_temp + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to nearest
							 * pixel boundary */
	}

	add_x_constraint(PARAMS2 cx, cx_pix);

}
#endif


FUNCTION fix31 
vstemweight(PARAMS2 dx)
	GDECL
	fix31           dx;
{
	int             i;
	fix31           dx_pix;

	/* Check if within standard vstem range */
	if ((dx >= (fix31) sp_globals.processor.type1.i_vstem_std.min_orus) &&
	    (dx <= (fix31) sp_globals.processor.type1.i_vstem_std.max_orus)) {
		return sp_globals.processor.type1.i_vstem_std.pix;
	}
	/* Check for match with vstem snap ranges */
	for (i = 0; i < sp_globals.processor.type1.no_vstem_snaps; i++) {
		if ((dx >= (fix31) sp_globals.processor.type1.i_vstem_snaps[i].min_orus) &&
		    (dx <= (fix31) sp_globals.processor.type1.i_vstem_snaps[i].max_orus)) {
			return sp_globals.processor.type1.i_vstem_snaps[i].pix;
		}
	}

	/* Round to nearest whole number of pixels */
	dx_pix = ((dx * sp_globals.processor.type1.x_pix_per_oru_i) + ((dx >> 4) * sp_globals.processor.type1.fudge_x1) + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;

	/* Check against minimum vstem weight */
	if (dx_pix < sp_globals.processor.type1.i_minvstemweight)
		dx_pix = sp_globals.processor.type1.i_minvstemweight;

	return dx_pix;
}


FUNCTION void 
add_x_constraint(PARAMS2 orus, pix)
	GDECL
	fix31           orus;	/* X coordinate in outline resolution units */
	fix31           pix;	/* Required transformation into pixels */
/*
 * Adds constraint points to piecewise-linear transformation for x Replaces
 * existing entry if new breakpoint matches existing breakpoint 
 */
{
	int             i, j;
	fix31           orus1 = (orus << sp_globals.processor.type1.tr_shift) - sp_globals.processor.type1.pt_1;

	if (sp_globals.processor.type1.no_x_breaks >= MAXSTEMZONES) {	/* Breakpoint table full? */
#if DEBUG
		printf("add_x_constraint: Too many X breaks\n");
#endif
		return;		/* Ignore if breakpoint table full */
	}
	/* Find the first i for which orus < sp_globals.processor.type1.Xorus[i] */
	for (i = 0; i < sp_globals.processor.type1.no_x_breaks; i++) {
		if (orus1 < (sp_globals.processor.type1.Xorus[i] << sp_globals.processor.type1.tr_shift)) {
			if (((sp_globals.processor.type1.Xorus[i] << sp_globals.processor.type1.tr_shift) - orus1) < sp_globals.processor.type1.pt_2) {	/* oru values are
									 * essentially equal? */
				goto L1;
			}
			break;
		}
	}

	/*
	 * Shuffle entries in sp_globals.processor.type1.Xorus and sp_globals.processor.type1.Xpix up one position starting at
	 * entry point 
	 */
	for (j = sp_globals.processor.type1.no_x_breaks; j > i; j--) {
		sp_globals.processor.type1.Xorus[j] = sp_globals.processor.type1.Xorus[j - 1];
		sp_globals.processor.type1.Xpix[j] = sp_globals.processor.type1.Xpix[j - 1];
	}
	sp_globals.processor.type1.no_x_breaks++;		/* Increment number of breakpoints */

	/* Add new entry or replace existing entry */
L1:
	sp_globals.processor.type1.Xorus[i] = orus;
	sp_globals.processor.type1.Xpix[i] = pix;

	sp_globals.processor.type1.x_trans_ready = FALSE;	/* Flag need to recalculate X interpolation
				 * coefficients */
}


#if EDGE_ALIGN
FUNCTION void 
align_hstem(PARAMS2 y1, y2, pcy_pix_bottom, pcy_pix_top)
	GDECL
	fix31           y1;	/* Lower edge of stroke in outline units */
	fix31           y2;	/* Upper edge of stroke in outline units */
	fix31          STACKFAR*pcy_pix_bottom;	/* bottom of stroke in device units */
	fix31          STACKFAR*pcy_pix_top;	/* top of stroke in device units */
/*
 * Aligns a horizontal stem to whole pixel boundaries Returns pixel
 * coordinate of centerline of aligned stem Uses sp_globals.processor.type1.top_zones[] and
 * sp_globals.processor.type1.bottom_zones[] arrays for blue value alignment 
 */
{
	fix31           cy_bottom;	/* bottom Position of stroke in
					 * outline units */
	fix31           cy_top;	/* top Position of stroke in outline units */
	fix31           strkwt_pix;	/* Thickness of stroke in device
					 * units */
	fix31           cy_pix_bottom;	/* bottom Position of  stroke in
					 * device units */
	fix31           cy_pix_top;	/* top Position  of stroke in device
					 * units */
	fix31           cy_temp_bottom;	/* Position of bottom of stroke in
					 * device units */
	fix31           cy_temp_top;	/* Position of top of stroke in
					 * device units */
	int             i;
	fix31           temp_bottom;	/* temp variable for calculation of
					 * bottom edge */

	fix31           hstemweight();
	void            add_y_constraint();

	cy_bottom = y1;
	cy_top = y2;

	strkwt_pix = hstemweight(PARAMS2 y2 - y1);	/* Stroke weight in pixels */

	/* Check upper edge for blue value alignment */

	for (i = 0; i < sp_globals.processor.type1.no_top_zones; i++) {
		if (y2 >= sp_globals.processor.type1.top_zones[i].bottom_orus) {
			if (y2 <= sp_globals.processor.type1.top_zones[i].top_orus) {
				cy_pix_top = sp_globals.processor.type1.top_zones[i].pix;
				cy_pix_bottom = sp_globals.processor.type1.top_zones[i].pix - strkwt_pix;
				goto done;
			}
		}
	}
	/* Check lower edge for blue value alignment */
	for (i = 0; i < sp_globals.processor.type1.no_bottom_zones; i++) {
		if (y1 <= sp_globals.processor.type1.bottom_zones[i].top_orus) {
			if (y1 >= sp_globals.processor.type1.bottom_zones[i].bottom_orus) {
				cy_pix_top = sp_globals.processor.type1.bottom_zones[i].pix + strkwt_pix;
				cy_pix_bottom = sp_globals.processor.type1.bottom_zones[i].pix;
				goto done;
			}
		}
	}
#if BASELINE_IMPROVE

	/* default action */
	if (cy_bottom <= 0) {	/* bottom edge below or at baseline */
		/* set the bottom edge, and add stoke weight to get top edge */
		cy_temp_bottom = (cy_bottom * sp_globals.processor.type1.y_pix_per_oru_i) + ((cy_bottom >> 4) * sp_globals.processor.type1.fudge_y);
		cy_pix_bottom = (cy_temp_bottom + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
		cy_pix_top = cy_pix_bottom + strkwt_pix;
	} else {		/* bottom edge is above baseline */
		/*
		 * set top edge, and subtract stroke weight to get bottom
		 * edge 
		 */
		cy_temp_top = (cy_top * sp_globals.processor.type1.y_pix_per_oru_i) + ((cy_top >> 4) * sp_globals.processor.type1.fudge_y);
		cy_pix_top = (cy_temp_top + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to nearest
								 * pixel boundary */
		cy_pix_bottom = cy_pix_top - strkwt_pix;

#else

	/*
	 * default action - set the top edge and subtract pix width for
	 * bottom 
	 */
	cy_temp_top = (cy_top * sp_globals.processor.type1.y_pix_per_oru_i) + ((cy_top >> 4) * sp_globals.processor.type1.fudge_y);
	cy_temp_bottom = cy_temp_top - strkwt_pix;


	cy_pix_bottom = (cy_temp_bottom + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to nearest
								 * pixel boundary */
	cy_pix_top = (cy_temp_top + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to nearest
							 * pixel boundary */

	/*
	 * special case for baseline - when both edges resolve to 0 pixel
	 * value, set the bottom edge, and move pix width up for top edge 
	 */
	if (cy_pix_top == 0) {
		temp_bottom = (cy_bottom * sp_globals.processor.type1.y_pix_per_oru_i) + ((cy_bottom >> 4) * sp_globals.processor.type1.fudge_y);
		temp_bottom = (temp_bottom + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
		if (temp_bottom == 0) {
			cy_pix_bottom = 0;
			cy_temp_top = strkwt_pix;
			cy_pix_top = (cy_temp_top + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;
		}
#endif
	}
done:
	add_y_constraint(PARAMS2 cy_bottom, cy_pix_bottom);
	add_y_constraint(PARAMS2 cy_top, cy_pix_top);

	*pcy_pix_bottom = cy_pix_bottom;
	*pcy_pix_top = cy_pix_top;
}
#else
FUNCTION void 
align_hstem(PARAMS2 y1, y2, pcy_pix)
	GDECL
	fix31           y1;	/* Lower edge of stroke in outline units */
	fix31           y2;	/* Upper edge of stroke in outline units */
	fix31          STACKFAR*pcy_pix;/* Centerline of stroke in device units */
/*
 * Aligns a horizontal stem to whole pixel boundaries Returns pixel
 * coordinate of centerline of aligned stem Uses sp_globals.processor.type1.top_zones[] and
 * sp_globals.processor.type1.bottom_zones[] arrays for blue value alignment 
 */
{
	fix31           cy;	/* Position of centerline of stroke in
				 * outline units */
	fix31           strkwt_pix;	/* Thickness of stroke in device
					 * units */
	fix31           hstrkwt_pix;	/* Half thickness of stroke in device
					 * units */
	fix31           cy_pix;	/* Position of centerline of stroke in device
				 * units */
	fix31           cy_temp;/* Position of centerline of stroke in device
				 * units */
	int             i;

	fix31           hstemweight();
	void            add_y_constraint();

	cy = (y1 + y2) >> 1;	/* Stroke centerline in orus */

	strkwt_pix = hstemweight(PARAMS2 y2 - y1);	/* Stroke weight in pixels */
	hstrkwt_pix = strkwt_pix >> 1;	/* Half stroke weight in pixels */

	/* Check upper edge for blue value alignment */
	for (i = 0; i < sp_globals.processor.type1.no_top_zones; i++) {
		if (y2 >= sp_globals.processor.type1.top_zones[i].bottom_orus) {
			if (y2 <= sp_globals.processor.type1.top_zones[i].top_orus) {
				cy_pix = sp_globals.processor.type1.top_zones[i].pix - hstrkwt_pix;
				goto done;
			}
		}
	}

	/* Check lower edge for blue value alignment */
	for (i = 0; i < sp_globals.processor.type1.no_bottom_zones; i++) {
		if (y1 <= sp_globals.processor.type1.bottom_zones[i].top_orus) {
			if (y1 >= sp_globals.processor.type1.bottom_zones[i].bottom_orus) {
				cy_pix = sp_globals.processor.type1.bottom_zones[i].pix + hstrkwt_pix;
				goto done;
			}
		}
	}

	/*
	 * Position non-aligned zone for optimal stroke center position
	 * accuracy 
	 */
	cy_temp = (cy * sp_globals.processor.type1.y_pix_per_oru_i) + ((cy >> 4) * sp_globals.processor.type1.fudge_y);
	if (strkwt_pix & sp_globals.processor.type1.mk_onepix) {	/* Odd number of pixels? */
		cy_pix = (cy_temp & sp_globals.processor.type1.mk_fix) + sp_globals.processor.type1.mk_rnd;	/* Round to nearest
							 * pixel center */
	} else {
		cy_pix = (cy_temp + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;	/* Round to nearest
							 * pixel boundary */
	}

done:
	add_y_constraint(PARAMS2 cy, cy_pix);

	*pcy_pix = cy_pix;
}
#endif


FUNCTION fix31 
hstemweight(PARAMS2 dy)
	GDECL
	fix31           dy;
{
	int             i;
	fix31           dy_pix;

	/* Check if within standard hstem range */
	if ((dy >= (fix31) sp_globals.processor.type1.i_hstem_std.min_orus) &&
	    (dy <= (fix31) sp_globals.processor.type1.i_hstem_std.max_orus)) {
		return sp_globals.processor.type1.i_hstem_std.pix;
	}
	/* Check for match with hstem snap ranges */
	for (i = 0; i < sp_globals.processor.type1.no_hstem_snaps; i++) {
		if ((dy >= (fix31) sp_globals.processor.type1.i_hstem_snaps[i].min_orus) &&
		    (dy <= (fix31) sp_globals.processor.type1.i_hstem_snaps[i].max_orus)) {
			return sp_globals.processor.type1.i_hstem_snaps[i].pix;
		}
	}

	/* Round to nearest whole number of pixels */
	dy_pix = ((dy * sp_globals.processor.type1.y_pix_per_oru_i) + ((dy >> 4) * sp_globals.processor.type1.fudge_y1) + sp_globals.processor.type1.mk_rnd) & sp_globals.processor.type1.mk_fix;

	/* Check against minimum hstem weight */
	if (dy_pix < sp_globals.processor.type1.i_minhstemweight)
		dy_pix = sp_globals.processor.type1.i_minhstemweight;

	return dy_pix;
}


FUNCTION void 
add_y_constraint(PARAMS2 orus, pix)
	GDECL
	fix31           orus;	/* Y coordinate in outline resolution units */
	fix31           pix;	/* Required transformation into pixels */
/*
 * Adds constraint points to piecewise-linear transformation for y Replaces
 * existing entry if new breakpoint matches existing breakpoint 
 */
{
	int             i, j;
	fix31           orus1 = (orus << sp_globals.processor.type1.tr_shift) - sp_globals.processor.type1.pt_1;

	if (sp_globals.processor.type1.no_y_breaks >= MAXSTEMZONES) {	/* Breakpoint table full? */
#if DEBUG
		printf("add_x_constraint: Too many Y breaks\n");
#endif
		return;		/* Ignore if breakpoint table full */
	}
	/* Find the first i for which orus < sp_globals.processor.type1.Yorus[i] */
	for (i = 0; i < sp_globals.processor.type1.no_y_breaks; i++) {
		if (orus1 < (sp_globals.processor.type1.Yorus[i] << sp_globals.processor.type1.tr_shift)) {
			if (((sp_globals.processor.type1.Yorus[i] << sp_globals.processor.type1.tr_shift) - orus1) < sp_globals.processor.type1.pt_2) {	/* oru values are
									 * essentially equal? */
				goto L1;
			}
			break;
		}
	}

	/*
	 * Shuffle entries in sp_globals.processor.type1.Yorus and sp_globals.processor.type1.Ypix up one position starting at this
	 * point 
	 */
	for (j = sp_globals.processor.type1.no_y_breaks; j > i; j--) {
		sp_globals.processor.type1.Yorus[j] = sp_globals.processor.type1.Yorus[j - 1];
		sp_globals.processor.type1.Ypix[j] = sp_globals.processor.type1.Ypix[j - 1];
	}
	sp_globals.processor.type1.no_y_breaks++;		/* Increment number of breakpoints */

	/* Add new entry or replace existing entry */
L1:
	sp_globals.processor.type1.Yorus[i] = orus;
	sp_globals.processor.type1.Ypix[i] = pix;

	sp_globals.processor.type1.y_trans_ready = FALSE;	/* Flag need to recalculate Y interpolation
				 * coefficients */
}



FUNCTION void 
do_trans_a(PARAMS2 pX, pY)
	GDECL
	fix31          STACKFAR*pX;
	fix31          STACKFAR*pY;
/*
 * Applies the current transformation to the point (*pX, *pY) 
 */
{
	fix31           X = *pX;/* Original X coordinate */
	fix31           Y = *pY;/* Original Y coordinate */
	int             i;
	fix31           xtrans;	/* Non-linear transformation of X coordinate */
	fix31           ytrans;	/* Non-linear transformation of Y coordinate */
#if DEBUG
	boolean         x_print_flag = FALSE;
	boolean         y_print_flag = FALSE;
#endif

	void            update_x_trans();
	void            update_y_trans();
	void            print_x_trans();
	void            print_y_trans();


	if (sp_globals.processor.type1.non_linear_X) {	/* Non-linear transformation of X
				 * coordinates? */
		if (!sp_globals.processor.type1.x_trans_ready) {
			update_x_trans(PARAMS1);
#if DEBUG
			x_print_flag = TRUE;
#endif
		}
		for (i = 0; i < sp_globals.processor.type1.no_x_breaks; i++) {
			if (X < sp_globals.processor.type1.Xorus[i]) {
				xtrans = X * (ufix32) sp_globals.processor.type1.Xmult[i] + sp_globals.processor.type1.Xoffset[i];
				goto L1;
			}
		}
		xtrans = X * (ufix32) sp_globals.processor.type1.Xmult[sp_globals.processor.type1.no_x_breaks] + sp_globals.processor.type1.Xoffset[sp_globals.processor.type1.no_x_breaks];
L1:
		;
	}
	if (sp_globals.processor.type1.non_linear_Y) {	/* Non-linear transformation of Y
				 * coordinates? */
		if (!sp_globals.processor.type1.y_trans_ready) {
			update_y_trans(PARAMS1);
#if DEBUG
			y_print_flag = TRUE;
#endif
		}
		for (i = 0; i < sp_globals.processor.type1.no_y_breaks; i++) {
			if (Y < sp_globals.processor.type1.Yorus[i]) {
				ytrans = Y * (ufix32) sp_globals.processor.type1.Ymult[i] + sp_globals.processor.type1.Yoffset[i];
				goto L2;
			}
		}
		ytrans = Y * (ufix32) sp_globals.processor.type1.Ymult[sp_globals.processor.type1.no_y_breaks] + sp_globals.processor.type1.Yoffset[sp_globals.processor.type1.no_y_breaks];
L2:
		;
	}
#if DEBUG
	if (x_print_flag)
		print_x_trans();
	if (y_print_flag)
		print_y_trans();
#endif

	switch (sp_globals.processor.type1.x_trans_mode) {	/* Switch on method of calculating
				 * transformed X value */
	case 1:		/* X is a function of x only */
		*pX = xtrans;
		break;

	case 2:		/* X is a function of x only */
		*pX = -xtrans;
		break;

	case 3:		/* X is a function of y only */
		*pX = ytrans;
		break;

	case 4:		/* X is a function of -y only */
		*pX = -ytrans;
		break;

	default:		/* X is a linear of x and y */
		*pX = X * (sp_globals.processor.type1.local_matrix_i[0] >> 4) + Y * (sp_globals.processor.type1.local_matrix_i[2] >> 4) + sp_globals.processor.type1.local_matrix_i[4];
		break;
	}

	switch (sp_globals.processor.type1.y_trans_mode) {	/* Switch on method of calculating
				 * transformed X value */
	case 1:		/* Y is a function of x only */
		*pY = xtrans;
		break;

	case 2:		/* Y is a function of -x only */
		*pY = -xtrans;
		break;

	case 3:		/* Y is a function of y only */
		*pY = ytrans;
		break;

	case 4:		/* Y is a function of -y only */
		*pY = -ytrans;
		break;

	default:		/* Y is a linear of x and y */
		*pY = X * (sp_globals.processor.type1.local_matrix_i[1] >> 4) + Y * (sp_globals.processor.type1.local_matrix_i[3] >> 4) + sp_globals.processor.type1.local_matrix_i[5];
		break;
	}
}


FUNCTION void 
update_x_trans(PARAMS1)
GDECL
/*
 * Updates the interpolation tables used for piecewise linear transformation
 * of X coordinates in character 
 */
{
	int             i, j;

	if (sp_globals.processor.type1.no_x_breaks == 0) {
		sp_globals.processor.type1.Xmult[0] = sp_globals.processor.type1.x_pix_per_oru_i;
		sp_globals.processor.type1.Xoffset[0] = sp_globals.processor.type1.local_matrix_i[4];
	} else {
#if EDGE_ALIGN
		for (i = 1; i < sp_globals.processor.type1.no_x_breaks; i++)
			if (sp_globals.processor.type1.Xpix[i - 1] > sp_globals.processor.type1.Xpix[i]) {	/* get rid of sp_globals.processor.type1.Ypix [i-1] */
				for (j = i; j < sp_globals.processor.type1.no_x_breaks; j++) {
					sp_globals.processor.type1.Xpix[j] = sp_globals.processor.type1.Xpix[j + 1];
					sp_globals.processor.type1.Xorus[j] = sp_globals.processor.type1.Xorus[j + 1];
				}
				sp_globals.processor.type1.no_x_breaks--;
				i--;
			}
#endif
		sp_globals.processor.type1.Xmult[0] = sp_globals.processor.type1.x_pix_per_oru_i;
		sp_globals.processor.type1.Xoffset[0] = sp_globals.processor.type1.Xpix[0] - (sp_globals.processor.type1.Xorus[0] * sp_globals.processor.type1.x_pix_per_oru_i + ((sp_globals.processor.type1.Xorus[0] >> 4) * sp_globals.processor.type1.fudge_x));

		for (i = 1; i < sp_globals.processor.type1.no_x_breaks; i++) {
			sp_globals.processor.type1.Xmult[i] = ((sp_globals.processor.type1.Xpix[i] - sp_globals.processor.type1.Xpix[i - 1]) / (sp_globals.processor.type1.Xorus[i] - sp_globals.processor.type1.Xorus[i - 1]));
			sp_globals.processor.type1.Xoffset[i] = sp_globals.processor.type1.Xpix[i] - (sp_globals.processor.type1.Xorus[i] * (ufix32) sp_globals.processor.type1.Xmult[i] + ((sp_globals.processor.type1.Xorus[i] >> 4) * sp_globals.processor.type1.fudge_x));
		}

		sp_globals.processor.type1.Xmult[i] = sp_globals.processor.type1.x_pix_per_oru_i;
		sp_globals.processor.type1.Xoffset[i] = sp_globals.processor.type1.Xpix[sp_globals.processor.type1.no_x_breaks - 1] - (sp_globals.processor.type1.Xorus[sp_globals.processor.type1.no_x_breaks - 1] * sp_globals.processor.type1.x_pix_per_oru_i + ((sp_globals.processor.type1.Xorus[sp_globals.processor.type1.no_x_breaks - 1] >> 4) * sp_globals.processor.type1.fudge_x));
	}

	sp_globals.processor.type1.x_trans_ready = TRUE;

}



FUNCTION void 
update_y_trans(PARAMS1)
GDECL
/*
 * Updates the interpolation tables used for piecewise linear transformation
 * of Y coordinates in character 
 */
{
	int             i, j;

	if (sp_globals.processor.type1.no_y_breaks == 0) {
		sp_globals.processor.type1.Ymult[0] = sp_globals.processor.type1.y_pix_per_oru_i;
		sp_globals.processor.type1.Yoffset[0] = sp_globals.processor.type1.local_matrix_i[5];
	} else {
		/* go through the list and get rid of bad edges */
		/*
		 * in the case where (oru[i] > oru[j] && pix[i] < pix[j]) get
		 * rid of edge j 
		 */
#if EDGE_ALIGN
		for (i = 1; i < sp_globals.processor.type1.no_y_breaks; i++)
			if (sp_globals.processor.type1.Ypix[i - 1] > sp_globals.processor.type1.Ypix[i]) {	/* get rid of sp_globals.processor.type1.Ypix [i-1] */
				for (j = i; j < sp_globals.processor.type1.no_y_breaks; j++) {
					sp_globals.processor.type1.Ypix[j] = sp_globals.processor.type1.Ypix[j + 1];
					sp_globals.processor.type1.Yorus[j] = sp_globals.processor.type1.Yorus[j + 1];
				}
				sp_globals.processor.type1.no_y_breaks--;
				i--;
			}
#endif

		sp_globals.processor.type1.Ymult[0] = sp_globals.processor.type1.y_pix_per_oru_i;
		sp_globals.processor.type1.Yoffset[0] = sp_globals.processor.type1.Ypix[0] - (sp_globals.processor.type1.Yorus[0] * sp_globals.processor.type1.y_pix_per_oru_i + ((sp_globals.processor.type1.Yorus[0] >> 4) * sp_globals.processor.type1.fudge_y));

		for (i = 1; i < sp_globals.processor.type1.no_y_breaks; i++) {
			sp_globals.processor.type1.Ymult[i] = ((sp_globals.processor.type1.Ypix[i] - sp_globals.processor.type1.Ypix[i - 1]) / (sp_globals.processor.type1.Yorus[i] - sp_globals.processor.type1.Yorus[i - 1]));
			sp_globals.processor.type1.Yoffset[i] = sp_globals.processor.type1.Ypix[i] - (sp_globals.processor.type1.Yorus[i] * (ufix32) sp_globals.processor.type1.Ymult[i] + ((sp_globals.processor.type1.Yorus[i] >> 4) * sp_globals.processor.type1.fudge_y));
		}

		sp_globals.processor.type1.Ymult[i] = sp_globals.processor.type1.y_pix_per_oru_i;
		sp_globals.processor.type1.Yoffset[i] = sp_globals.processor.type1.Ypix[sp_globals.processor.type1.no_y_breaks - 1] - (sp_globals.processor.type1.Yorus[sp_globals.processor.type1.no_y_breaks - 1] * sp_globals.processor.type1.y_pix_per_oru_i + ((sp_globals.processor.type1.Yorus[sp_globals.processor.type1.no_y_breaks - 1] >> 4) * sp_globals.processor.type1.fudge_y));
	}

	sp_globals.processor.type1.y_trans_ready = TRUE;

}



#if DEBUG
FUNCTION void 
print_x_trans()
/*
 * Called by update_x_trans() to print the transformation coefficients for X
 * coordinates in the character outline. For debugging purposes only 
 */
{
	fix15           i;
	fix31           q1, q2;
	void            do_trans_a();

	printf("\nTransformation table for X coordinates:\n");
	printf("Zone edges       sp_globals.processor.type1.Xpix       sp_globals.processor.type1.Xmult      sp_globals.processor.type1.Xoffset         trans\n");
	printf("----------     --------   ---------- ------------      -------\n");
	for (i = 0; i < sp_globals.processor.type1.no_x_breaks; i++) {
		q1 = sp_globals.processor.type1.Xorus[i];
		q2 = 0;
		do_trans_a(PARAMS2 (fix31 STACKFAR*)&q1, (fix31 STACKFAR*)&q2);
		printf("%10.1f %12.1f %12.5f %12.5f %12.5f\n",
		       (real) sp_globals.processor.type1.Xorus[i] * 0.0625, (real) sp_globals.processor.type1.Xpix[i] / (real) sp_globals.processor.type1.mk_onepix, (real) sp_globals.processor.type1.Xmult[i] / (real) sp_globals.processor.type1.tr_onepix, (real) sp_globals.processor.type1.Xoffset[i] / (real) sp_globals.processor.type1.mk_onepix, (real) q1 / (real) sp_globals.processor.type1.mk_onepix);
	}
	printf("                        %12.5f %12.5f\n",
	       (real) sp_globals.processor.type1.Xmult[sp_globals.processor.type1.no_x_breaks] / (real) sp_globals.processor.type1.tr_onepix, (real) sp_globals.processor.type1.Xoffset[sp_globals.processor.type1.no_x_breaks] / (real) sp_globals.processor.type1.mk_onepix);
	return;
}
#endif


#if DEBUG
FUNCTION void 
print_y_trans()
/*
 * Called by update_y_trans() to print the transformation coefficients for Y
 * coordinates in the character outline. For debugging purposes only 
 */
{
	fix15           i;
	fix31           q1, q2;
	void            do_trans_a();

	printf("\nTransformation table for Y coordinates:\n");
	printf("Zone edges       sp_globals.processor.type1.Ypix       sp_globals.processor.type1.Ymult      sp_globals.processor.type1.Yoffset         trans\n");
	printf("----------     --------   ---------- ------------      -------\n");
	for (i = 0; i < sp_globals.processor.type1.no_y_breaks; i++) {
		q1 = 0;
		q2 = sp_globals.processor.type1.Yorus[i];
		do_trans_a(PARAMS2 (fix31 STACKFAR*)&q1, (fix31 STACKFAR*)&q2);
		printf("%10.1f %12.1f %12.5f %12.5f %12.5f\n",
		       (real) sp_globals.processor.type1.Yorus[i] * 0.0625, (real) sp_globals.processor.type1.Ypix[i] / (real) sp_globals.processor.type1.mk_onepix, (real) sp_globals.processor.type1.Ymult[i] / (real) sp_globals.processor.type1.tr_onepix, (real) sp_globals.processor.type1.Yoffset[i] / (real) sp_globals.processor.type1.mk_onepix, (real) q2 / (real) sp_globals.processor.type1.mk_onepix);
	}
	printf("                        %12.5f %12.5f\n",
	       (real) sp_globals.processor.type1.Ymult[sp_globals.processor.type1.no_y_breaks] / (real) sp_globals.processor.type1.tr_onepix, (real) sp_globals.processor.type1.Yoffset[sp_globals.processor.type1.no_y_breaks] / (real) sp_globals.processor.type1.mk_onepix);
	return;
}
#endif



FUNCTION fix15 set_shift_const(PARAMS1)
GDECL
{
	return sp_globals.processor.type1.tr_shift;
}

#pragma Code()
