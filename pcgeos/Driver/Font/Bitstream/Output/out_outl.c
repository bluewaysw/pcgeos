/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Output/out_outl.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: out_outl.c,v 1.1 97/04/18 11:45:13 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("OutputCode")


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
*                                                                                    *
*                                                                                    *
*       Revision 28.37  93/03/15  12:47:09  roberte
*       Release
*       
*       Revision 28.7  92/12/30  17:45:51  roberte
*       Functions no longer renamed in spdo_prv.h now declared with "sp_"
*       Use PARAMS1&2 macros throughout.
*       
*       Revision 28.6  92/11/24  11:00:59  laurar
*       include fino.h
*       
*       Revision 28.5  92/11/19  15:17:11  roberte
*       Release
*       
*       Revision 28.1  92/06/25  13:40:54  leeann
*       Release
*       
*       Revision 27.1  92/03/23  14:00:33  leeann
*       Release
*       
*       Revision 26.1  92/01/30  16:59:36  leeann
*       Release
*       
*       Revision 25.1  91/07/10  11:05:38  leeann
*       Release
*       
*       Revision 24.1  91/07/10  10:39:13  leeann
*       Release
*       
*       Revision 23.1  91/07/09  18:00:14  leeann
*       Release
*       
*       Revision 22.1  91/01/23  17:19:18  leeann
*       Release
*       
*       Revision 21.1  90/11/20  14:38:35  leeann
*       Release
*       
*       Revision 20.1  90/11/12  09:31:11  leeann
*       Release
*       
*       Revision 19.1  90/11/08  10:20:52  leeann
*       Release
*       
*       Revision 18.1  90/09/24  10:10:46  mark
*       Release
*       
*       Revision 17.1  90/09/13  16:00:34  mark
*       Release name rel0913
*       
*       Revision 16.1  90/09/11  13:19:51  mark
*       Release
*       
*       Revision 15.1  90/08/29  10:04:45  mark
*       Release name rel0829
*       
*       Revision 14.1  90/07/13  10:41:14  mark
*       Release name rel071390
*       
*       Revision 13.1  90/07/02  10:40:16  mark
*       Release name REL2070290
*       
*       Revision 12.1  90/04/23  12:13:18  mark
*       Release name REL20
*       
*       Revision 11.1  90/04/23  10:13:33  mark
*       Release name REV2
*       
*       Revision 10.1  89/07/28  18:11:24  mark
*       Release name PRODUCT
*       
*       Revision 9.1  89/07/27  10:24:47  mark
*       Release name PRODUCT
*       
*       Revision 8.1  89/07/13  18:20:53  mark
*       Release name Product
*       
*       Revision 7.1  89/07/11  09:03:03  mark
*       Release name PRODUCT
*       
*       Revision 6.2  89/07/09  14:47:48  mark
*       make specsarg argument to init_outline GLOBALFAR
*       
*       Revision 6.1  89/06/19  08:36:22  mark
*       Release name prod
*       
*       Revision 5.4  89/06/06  17:24:13  mark
*       add curve depth to output module curve functions
*       
*       Revision 5.3  89/06/02  08:24:06  mark
*       added logic to limit coordinates of points on the
*       outline to the bounding box provided to sp_begin_char
*       in case extrapolation causes some problem.
*       
*       Revision 5.2  89/06/01  16:55:35  mark
*       changed declaration of begin_char_outline to boolean,
*       return TRUE
*       
*       Revision 5.1  89/05/01  17:55:26  mark
*       Release name Beta
*       
*       Revision 4.1  89/04/27  12:17:36  mark
*       Release name Beta
*       
*       Revision 3.1  89/04/25  08:30:40  mark
*       Release name beta
*       
*       Revision 2.2  89/04/12  12:13:02  mark
*       added stuff for far stack and font
*       
*       Revision 2.1  89/04/04  13:36:52  mark
*       Release name EVAL
*       
*       Revision 1.6  89/04/04  13:25:11  mark
*       Update copyright text
*       
*       Revision 1.5  89/03/31  14:50:08  mark
*       change arguments to open_outline
*        change speedo.h to spdo_prv.h
*       eliminate thresh
*       change fontware to comments to speedo
*       
*       Revision 1.4  89/03/30  17:51:54  john
*       Open outline now gives valid bounding box information
*       even in the presence of arbitrary transformations.
*       
*       Revision 1.3  89/03/29  16:10:58  mark
*       changes for slot independence and dynamic/reentrant
*       data allocation
*       
*       Revision 1.2  89/03/21  13:30:39  mark
*       change name from oemfw.h to speedo.h
*       
*       Revision 1.1  89/03/15  12:34:33  mark
*       Initial revision
*                                                                                 *
*                                                                                    *
*************************************************************************************/

#ifdef RCSSTATUS
#endif



/**************************** O U T _ 2 _ 1 . C ******************************
 *                                                                           *
 * This is the standard output module for vector output mode.                *
 *                                                                           *
 ********************** R E V I S I O N   H I S T O R Y **********************
 *                                                                           *
 *  1) 16 Dec 88  jsc  Created                                               *
 *                                                                           *
 *  2) 31 Jan 89  jsc  xmin, xmax, ymin, ymax arguments added to             *
 *                     open_outline() function.                              *
 *                                                                           *
 *  3)  2 Feb 89  jsc  Call to external curve_to() added for curve output    *
 *                     when enabled.                                         *
 *                                                                           *
 *  4)  7 Feb 89  jsc  Additional commenting.                                *
 *                                                                           *
 *  5) 16 Feb 89  jsc  init_out2() function added.                           *
 *                                                                           *
 ****************************************************************************/

#include "spdo_prv.h"               /* General definitions for Speedo     */
#include "fino.h"


#define   DEBUG      0

#if DEBUG
#include <stdio.h>
#define SHOW(X) printf("X = %d\n", X)
#else
#define SHOW(X)
#endif

/* the following macro is used to limit points on the outline to the bounding box */

#define RANGECHECK(value,min,max) (((value) >= (min) ? (value) : (min)) < (max) ? (value) : (max))
/***** GLOBAL VARIABLES *****/

/***** GLOBAL FUNCTIONS *****/

/***** EXTERNAL VARIABLES *****/

/***** EXTERNAL FUNCTIONS *****/

/***** STATIC VARIABLES *****/

/***** STATIC FUNCTIONS *****/


#if INCL_OUTLINE
FUNCTION boolean sp_init_outline(PARAMS2 specsarg)
GDECL
specs_t GLOBALFAR *specsarg;
/*
 * init_out2() is called by sp_set_specs(PARAMS1) to initialize the output module.
 * Returns TRUE if output module can accept requested specifications.
 * Returns FALSE otherwise.
 */
{
#if DEBUG
printf("INIT_OUT_2()\n");
#endif
if (specsarg->flags & (CLIP_LEFT + CLIP_RIGHT + CLIP_TOP + CLIP_BOTTOM))
    return FALSE;           /* Clipping not supported */
return (TRUE); 
}
#endif

#if INCL_OUTLINE
FUNCTION boolean sp_begin_char_outline(PARAMS2 Psw, Pmin, Pmax)
GDECL
point_t Psw;       /* End of escapement vector (sub-pixels) */            
point_t Pmin;      /* Bottom left corner of bounding box */             
point_t Pmax;      /* Top right corner of bounding box */
/*
 * If two or more output modules are included in the configuration, begin_char2()
 * is called by begin_char() to signal the start of character output data.
 * If only one output module is included in the configuration, begin_char() is 
 * called by sp_make_simp_char(PARAMS1) and sp_make_comp_char(PARAMS1).
 */
{
fix31 set_width_x;
fix31 set_width_y;
fix31  xmin;
fix31  xmax;
fix31  ymin;
fix31  ymax;

#if DEBUG
printf("BEGIN_CHAR_2(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f\n", 
                    (real)Psw.x / (real)onepix, (real)Psw.y / (real)onepix,
                    (real)Pmin.x / (real)onepix, (real)Pmin.y / (real)onepix,
                    (real)Pmax.x / (real)onepix, (real)Pmax.y / (real)onepix);
#endif
sp_globals.poshift = 16 - sp_globals.pixshift;
set_width_x = (fix31)Psw.x << sp_globals.poshift;
set_width_y = (fix31)Psw.y << sp_globals.poshift;
xmin = (fix31)Pmin.x << sp_globals.poshift;
xmax = (fix31)Pmax.x << sp_globals.poshift;
ymin = (fix31)Pmin.y << sp_globals.poshift;
ymax = (fix31)Pmax.y << sp_globals.poshift;
sp_globals.xmin = Pmin.x;
sp_globals.xmax = Pmax.x;
sp_globals.ymin = Pmin.y;
sp_globals.ymax = Pmax.y;
open_outline(set_width_x, set_width_y, xmin, xmax, ymin, ymax);
return TRUE;
}
#endif

#if INCL_OUTLINE
FUNCTION void sp_begin_sub_char_outline(PARAMS2 Psw, Pmin, Pmax)
GDECL
point_t Psw;       /* End of sub-char escapement vector */            
point_t Pmin;      /* Bottom left corner of sub-char bounding box */             
point_t Pmax;      /* Top right corner of sub-char bounding box */
/*
 * If two or more output modules are included in the configuration, begin_sub_char2()
 * is called by begin_sub_char() to signal the start of sub-character output data.
 * If only one output module is included in the configuration, begin_sub_char() is 
 * called by sp_make_comp_char(PARAMS1).
 */
{
#if DEBUG
printf("BEGIN_SUB_CHAR_2(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f\n", 
                    (real)Psw.x / (real)onepix, (real)Psw.y / (real)onepix,
                    (real)Pmin.x / (real)onepix, (real)Pmin.y / (real)onepix,
                    (real)Pmax.x / (real)onepix, (real)Pmax.y / (real)onepix);
#endif
start_new_char();
}
#endif


#if INCL_OUTLINE
FUNCTION void sp_begin_contour_outline(PARAMS2 P1, outside)
GDECL
point_t P1;       /* Start point of contour */            
boolean outside;  /* TRUE if outside (counter-clockwise) contour */
/*
 * If two or more output modules are included in the configuration, begin_contour2()
 * is called by begin_contour() to define the start point of a new contour
 * and to indicate whether it is an outside (counter-clockwise) contour
 * or an inside (clockwise) contour.
 * If only one output module is included in the configuration, begin_sub_char() is 
 * called by sp_proc_outl_data(PARAMS1).
 */
{
fix15 x,y;
#if DEBUG
printf("BEGIN_CONTOUR_2(%3.1f, %3.1f, %s)\n", 
    (real)P1.x / (real)onepix, (real)P1.y / (real)onepix, outside? "outside": "inside");
#endif
x = RANGECHECK(P1.x,sp_globals.xmin,sp_globals.xmax);
y = RANGECHECK(P1.y,sp_globals.ymin,sp_globals.ymax);

start_contour((fix31)x << sp_globals.poshift, (fix31)y << sp_globals.poshift, outside);
}
#endif

#if INCL_OUTLINE
FUNCTION void sp_curve_outline(PARAMS2 P1, P2, P3,depth)
GDECL
point_t P1;      /* First control point of Bezier curve */
point_t P2;      /* Second control point of Bezier curve */
point_t P3;      /* End point of Bezier curve */
fix15 depth;
/*
 * If two or more output modules are included in the configuration, curve2()
 * is called by curve() to output one curve segment.
 * If only one output module is included in the configuration, curve() is 
 * called by sp_proc_outl_data(PARAMS1).
 * This function is only called when curve output is enabled.
 */
{
fix15 x1,y1,x2,y2,x3,y3;
#if DEBUG
printf("CURVE_2(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n", 
    (real)P1.x / (real)onepix, (real)P1.y / (real)onepix,
    (real)P2.x / (real)onepix, (real)P2.y / (real)onepix,
    (real)P3.x / (real)onepix, (real)P3.y / (real)onepix);
#endif
x1= RANGECHECK(P1.x,sp_globals.xmin,sp_globals.xmax);
y1= RANGECHECK(P1.y,sp_globals.ymin,sp_globals.ymax);

x2= RANGECHECK(P2.x,sp_globals.xmin,sp_globals.xmax);
y2= RANGECHECK(P2.y,sp_globals.ymin,sp_globals.ymax);

x3= RANGECHECK(P3.x,sp_globals.xmin,sp_globals.xmax);
y3= RANGECHECK(P3.y,sp_globals.ymin,sp_globals.ymax);

curve_to((fix31)x1 << sp_globals.poshift, (fix31)y1 << sp_globals.poshift,
         (fix31)x2<< sp_globals.poshift, (fix31)y2 << sp_globals.poshift,
         (fix31)x3 << sp_globals.poshift, (fix31)y3 << sp_globals.poshift);
}
#endif

#if INCL_OUTLINE
FUNCTION void sp_line_outline(PARAMS2 P1)
GDECL
point_t P1;      /* End point of vector */             
/*
 * If two or more output modules are included in the configuration, line2()
 * is called by line() to output one vector.
 * If only one output module is included in the configuration, line() is 
 * called by sp_proc_outl_data(PARAMS1). If curve output is enabled, line() is also
 * called by sp_split_curve(PARAMS1).
 */
{
fix15 x1,y1;
#if DEBUG
printf("LINE_2(%3.1f, %3.1f)\n", (real)P1.x / (real)onepix, (real)P1.y / (real)onepix);
#endif
x1= RANGECHECK(P1.x,sp_globals.xmin,sp_globals.xmax);
y1= RANGECHECK(P1.y,sp_globals.ymin,sp_globals.ymax);

line_to((fix31)x1 << sp_globals.poshift, (fix31)y1 << sp_globals.poshift);
}
#endif

#if INCL_OUTLINE
FUNCTION void sp_end_contour_outline(PARAMS1)
GDECL
/*
 * If two or more output modules are included in the configuration, end_contour2()
 * is called by end_contour() to signal the end of a contour.
 * If only one output module is included in the configuration, end_contour() is 
 * called by sp_proc_outl_data(PARAMS1).
 */
{
#if DEBUG
printf("END_CONTOUR_2()\n");
#endif
close_contour();
}
#endif


#if INCL_OUTLINE
FUNCTION void sp_end_sub_char_outline(PARAMS1)
GDECL
/*
 * If two or more output modules are included in the configuration, end_sub_char2()
 * is called by end_sub_char() to signal the end of sub-character data.
 * If only one output module is included in the configuration, end_sub_char() is 
 * called by sp_make_comp_char(PARAMS1).
 */
{
#if DEBUG
printf("END_SUB_CHAR_2()\n");
#endif
}
#endif


#if INCL_OUTLINE
FUNCTION boolean sp_end_char_outline(PARAMS1)
GDECL
/*
 * If two or more output modules are included in the configuration, end_char2()
 * is called by end_char() to signal the end of the character data.
 * If only one output module is included in the configuration, end_char() is 
 * called by sp_make_simp_char(PARAMS1) and sp_make_comp_char(PARAMS1).
 * Returns TRUE if output process is complete
 * Returns FALSE to repeat output of the transformed data beginning
 * with the first contour (of the first sub-char if compound).
 */
{
#if DEBUG
printf("END_CHAR_2()\n");
#endif
close_outline();
return TRUE;
}
#endif

#pragma Code()
