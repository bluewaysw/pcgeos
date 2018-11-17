/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Output/out_util.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: out_util.c,v 1.1 97/04/18 11:45:14 newdeal Exp $
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
*                                                                              *
*                                                                              *
 * Revision 28.37  93/03/15  12:47:31  roberte
 * Release
 * 
 * Revision 28.11  92/12/30  18:10:06  roberte
 * Changed all functions to "sp_" naming.
 * Use PARAMS1&2 macros throughout.
 * 
 * Revision 28.7  92/11/24  12:32:28  laurar
 * include fino.h
 * 
 * Revision 28.5  92/11/19  15:17:34  roberte
 * Release
 * 
 * Revision 28.1  92/06/25  13:41:17  leeann
 * Release
 * 
 * Revision 27.1  92/03/23  14:00:59  leeann
 * Release
 * 
 * Revision 26.1  92/01/30  17:00:12  leeann
 * Release
 * 
 * Revision 25.1  91/07/10  11:06:03  leeann
 * Release
 * 
 * Revision 24.1  91/07/10  10:39:37  leeann
 * Release
 * 
 * Revision 23.1  91/07/09  18:00:38  leeann
 * Release
 * 
 * Revision 22.3  91/06/19  14:27:38  leeann
 *  add function sp_set_clip_parameters for clipping
 * fix bug for clipping of left and right only
 * 
 * Revision 22.1  91/01/23  17:19:52  leeann
 * Release
 * 
 * Revision 21.1  90/11/20  14:39:07  leeann
 * Release
 * 
 * Revision 20.2  90/11/20  13:15:03  leeann
 * fixed clipping precision
 * 
 * Revision 20.1  90/11/12  09:31:55  leeann
 * Release
 * 
 * Revision 19.1  90/11/08  10:24:27  leeann
 * Release
 * 
 * Revision 18.2  90/11/07  15:38:41  leeann
 *  implement clipping for rotation of 90, 180, and 270 degrees
 * 
 * Revision 18.1  90/09/24  10:15:30  mark
 * Release
 * 
 * Revision 17.1  90/09/13  16:05:41  mark
 * Release name rel0913
 * 
 * Revision 16.1  90/09/11  13:20:33  mark
 * Release
 * 
 * Revision 15.1  90/08/29  10:09:04  mark
 * Release name rel0829
 * 
 * Revision 14.1  90/07/13  10:47:15  mark
 * Release name rel071390
 * 
 * Revision 13.1  90/07/02  10:46:01  mark
 * Release name REL2070290
 * 
 * Revision 12.2  90/06/26  09:01:59  leeann
 * use tcb0 to compute pixel values
 * 
 * Revision 12.1  90/04/23  12:17:07  mark
 * Release name REL20
 * 
 * Revision 11.1  90/04/23  10:17:26  mark
 * Release name REV2
 * 
 * Revision 1.8  90/04/23  09:44:08  mark
 * add GDECL statement
 * 
 * Revision 1.7  90/04/10  13:28:04  mark
 * fix collected bounding boxes
 * 
 * Revision 1.6  90/04/10  12:19:01  mark
 * correct ymin calculation to get rid of extra blank scan line at bottom
 * 
 * Revision 1.5  90/04/09  12:54:07  mark
 * another null checkin to test fix of put proble,
 * 
 * Revision 1.4  90/04/09  12:51:10  mark
 * null put to test bug in put procedure
 * 
 * Revision 1.3  90/04/06  12:15:01  mark
 * fix configuration problems so that necessary variables
 * are calculated regardless of which output modules are
 * included.
 * 
 * Revision 1.2  90/04/04  13:18:58  mark
 * added Y clipping by limiting y_band.band_min and band_max to
 * the size of the Em square
 * 
 * Revision 1.1  90/03/30  14:44:43  mark
 * Initial revision
 * 
*                                                                                    *
*************************************************************************************/

#ifdef RCSSTATUS
#endif


/*************************** O U T _ U T I L . C *****************************
 *                                                                           *
 * This is a utility module share by all bitmap output modules               *
 *                                                                           *
 *****************************************************************************/

#include "spdo_prv.h"               /* General definitions for Speedo   */
/* absolute value function */
#define   ABS(X)     ( (X < 0) ? -X : X)
#if INCL_BLACK || INCL_2D || INCL_SCREEN

FUNCTION  void sp_init_char_out(PARAMS2 Psw,Pmin,Pmax)
GDECL
point_t Psw, Pmin, Pmax;
{
sp_globals.set_width.x = (fix31)Psw.x << sp_globals.poshift;
sp_globals.set_width.y = (fix31)Psw.y << sp_globals.poshift;
sp_set_first_band_out(PARAMS2 Pmin, Pmax);
sp_init_intercepts_out(PARAMS1);
if (sp_globals.normal)
    {
    sp_globals.bmap_xmin = Pmin.x;
    sp_globals.bmap_xmax = Pmax.x;
    sp_globals.bmap_ymin = Pmin.y;
    sp_globals.bmap_ymax = Pmax.y;
    sp_globals.extents_running = FALSE;
    }
else
    {
    sp_globals.bmap_xmin = 32000;
    sp_globals.bmap_xmax = -32000;
    sp_globals.bmap_ymin = 32000;
    sp_globals.bmap_ymax = -32000;
    sp_globals.extents_running = TRUE;
    }
sp_globals.first_pass = TRUE;
}

FUNCTION void sp_begin_sub_char_out(PARAMS2 Psw, Pmin, Pmax)
GDECL
point_t Psw;                   
point_t Pmin;                   
point_t Pmax;                   
/* Called at the start of each sub-character in a composite character
 */
{
#if DEBUG
printf("BEGIN_SUB_CHAR_out(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f\n", 
                    (real)Psw.x / (real)sp_globals.onepix, (real)Psw.y / (real)sp_globals.onepix,
                    (real)Pmin.x / (real)sp_globals.onepix, (real)Pmin.y / (real)sp_globals.onepix,
                    (real)Pmax.x / (real)sp_globals.onepix, (real)Pmax.y / (real)sp_globals.onepix);
#endif
sp_restart_intercepts_out(PARAMS1);
if (!sp_globals.extents_running)
	{
    sp_globals.bmap_xmin = 32000;
    sp_globals.bmap_xmax = -32000;
    sp_globals.bmap_ymin = 32000;
    sp_globals.bmap_ymax = -32000;
    sp_globals.extents_running = TRUE;
	}
}

FUNCTION void sp_curve_out(PARAMS2 P1, P2, P3,depth)
GDECL
point_t P1, P2, P3;                   
fix15 depth;
/* Called for each curve in the transformed character if curves out enabled
 */
{
#if DEBUG
printf("CURVE_OUT(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f)\n", 
    (real)P1.x / (real)sp_globals.onepix, (real)P1.y / (real)sp_globals.onepix,
    (real)P2.x / (real)sp_globals.onepix, (real)P2.y / (real)sp_globals.onepix,
    (real)P3.x / (real)sp_globals.onepix, (real)P3.y / (real)sp_globals.onepix);
#endif
}



FUNCTION void sp_end_contour_out(PARAMS1)
GDECL
/* Called after the last vector in each contour
 */
{
#if DEBUG
printf("END_CONTOUR_OUT()\n");
#endif
}


FUNCTION void sp_end_sub_char_out(PARAMS1)
GDECL
/* Called after the last contour in each sub-character in a compound character
 */
{
#if DEBUG
printf("END_SUB_CHAR_OUT()\n");
#endif
}


FUNCTION void sp_init_intercepts_out(PARAMS1)
GDECL
/*  Called to initialize intercept storage data structure
 */

{
fix15 i;
fix15 no_lists;

#if DEBUG
printf("    Init intercepts (Y band from %d to %d)\n", sp_globals.y_band.band_min, sp_globals.y_band.band_max);
if (sp_globals.x_scan_active)
    printf("                    (X band from %d to %d)\n", sp_globals.x_band.band_min, sp_globals.x_band.band_max);
#endif 

sp_globals.intercept_oflo = FALSE;

sp_globals.no_y_lists = sp_globals.y_band.band_max - sp_globals.y_band.band_min + 1;
#if INCL_2D
if (sp_globals.output_mode == MODE_2D)
	{
	sp_globals.no_x_lists = sp_globals.x_scan_active ? 
		sp_globals.x_band.band_max - sp_globals.x_band.band_min + 1 : 0;
	no_lists = sp_globals.no_y_lists + sp_globals.no_x_lists;
	} 
else
#endif
	no_lists = sp_globals.no_y_lists;

#if INCL_2D
sp_globals.y_band.band_floor = 0;
sp_globals.y_band.band_ceiling = sp_globals.no_y_lists;
#endif
                                        
if (no_lists >= MAX_INTERCEPTS)  /* Not enough room for list table? */
    {
    no_lists = sp_globals.no_y_lists = MAX_INTERCEPTS;
    sp_globals.intercept_oflo = TRUE;
	sp_globals.y_band.band_min = sp_globals.y_band.band_max - sp_globals.no_y_lists + 1;
#if INCL_2D
    sp_globals.y_band.band_array_offset = sp_globals.y_band.band_min;
    sp_globals.y_band.band_ceiling = sp_globals.no_y_lists;
    sp_globals.no_x_lists = 0;
    sp_globals.x_scan_active = FALSE;
#endif
    }

for (i = 0; i < no_lists; i++)   /* For each active value... */
    {
#if INCL_SCREEN
	if (sp_globals.output_mode == MODE_SCREEN)
		sp_intercepts.inttype[i]=0;
#endif
    sp_intercepts.cdr[i] = 0;                    /* Mark each intercept list empty */
    }

sp_globals.first_offset = sp_globals.next_offset = no_lists;

#if INCL_2D
sp_globals.y_band.band_array_offset = sp_globals.y_band.band_min;
sp_globals.x_band.band_array_offset = sp_globals.x_band.band_min - sp_globals.no_y_lists;
sp_globals.x_band.band_floor = sp_globals.no_y_lists;
sp_globals.x_band.band_ceiling = no_lists;
#endif
#if INCL_SCREEN
sp_intercepts.inttype[sp_globals.no_y_lists-1] = END_INT;
#endif

}


FUNCTION void sp_restart_intercepts_out(PARAMS1)
GDECL

/*  Called by sp_make_char when a new sub character is started
 *  Freezes current sorted lists
 */

{

#if DEBUG
printf("    Restart intercepts:\n");
#endif
sp_globals.first_offset = sp_globals.next_offset;
}



FUNCTION void sp_set_first_band_out(PARAMS2 Pmin, Pmax)
GDECL
point_t Pmin;
point_t Pmax;
{

sp_globals.ymin = Pmin.y;
sp_globals.ymax = Pmax.y;

sp_globals.ymin = (sp_globals.ymin - sp_globals.onepix + 1) >> sp_globals.pixshift;
sp_globals.ymax = (sp_globals.ymax + sp_globals.onepix - 1) >> sp_globals.pixshift;

#if INCL_CLIPPING
    switch(sp_globals.tcb0.xtype)
       {
       case 1: /* 180 degree rotation */
	    if (sp_globals.specs.flags & CLIP_TOP)
               {
               sp_globals.clip_ymin = (fix31)((fix31)EM_TOP * sp_globals.tcb0.yppo + ((1<<sp_globals.multshift)/2));
               sp_globals.clip_ymin = sp_globals.clip_ymin >> sp_globals.multshift;
	       sp_globals.clip_ymin = -1* sp_globals.clip_ymin;
	       if (sp_globals.ymin < sp_globals.clip_ymin)
		    sp_globals.ymin = sp_globals.clip_ymin;
	       }
            if (sp_globals.specs.flags & CLIP_BOTTOM)
	       {
               sp_globals.clip_ymax = (fix31)((fix31)(-1 * EM_BOT) * sp_globals.tcb0.yppo + ((1<<sp_globals.multshift)/2));
               sp_globals.clip_ymax = sp_globals.clip_ymax >> sp_globals.multshift;
	       if (sp_globals.ymax > sp_globals.clip_ymax)
		    sp_globals.ymax = sp_globals.clip_ymax;
               }
               break;
       case 2: /* 90 degree rotation */
            sp_globals.clip_ymax = 0;
            if ((sp_globals.specs.flags & CLIP_TOP) &&
                (sp_globals.ymax > sp_globals.clip_ymax))
                 sp_globals.ymax = sp_globals.clip_ymax;
            sp_globals.clip_ymin = ((sp_globals.set_width.y+32768L) >> 16);
            if ((sp_globals.specs.flags & CLIP_BOTTOM) &&
                (sp_globals.ymin < sp_globals.clip_ymin))
                 sp_globals.ymin = sp_globals.clip_ymin;
            break;
       case 3: /* 270 degree rotation */
               sp_globals.clip_ymax = ((sp_globals.set_width.y+32768L) >> 16);
               if ((sp_globals.specs.flags & CLIP_TOP) &&
                   (sp_globals.ymax > sp_globals.clip_ymax))
                    sp_globals.ymax = sp_globals.clip_ymax;
               sp_globals.clip_ymin = 0;
               if ((sp_globals.specs.flags & CLIP_BOTTOM) &&
                   (sp_globals.ymin < sp_globals.clip_ymin))
                    sp_globals.ymin = sp_globals.clip_ymin;
               break;
       default: /* this is for zero degree rotation and arbitrary rotation */
	    if (sp_globals.specs.flags & CLIP_TOP)
               {
	       sp_globals.clip_ymax = (fix31)((fix31)EM_TOP * sp_globals.tcb0.yppo +  ((1<<sp_globals.multshift)/2));
               sp_globals.clip_ymax = sp_globals.clip_ymax >> sp_globals.multshift;
	       if (sp_globals.ymax > sp_globals.clip_ymax)
		    sp_globals.ymax = sp_globals.clip_ymax;
	       }
            if (sp_globals.specs.flags & CLIP_BOTTOM)
	       {
	       sp_globals.clip_ymin = (fix31)((fix31)(-1 * EM_BOT) * sp_globals.tcb0.yppo +  ((1<<sp_globals.multshift)/2));
               sp_globals.clip_ymin = sp_globals.clip_ymin >> sp_globals.multshift;
	       sp_globals.clip_ymin = - sp_globals.clip_ymin;
	       if (sp_globals.ymin < sp_globals.clip_ymin)
		    sp_globals.ymin = sp_globals.clip_ymin;
               }
               break;
       }
#endif
sp_globals.y_band.band_min = sp_globals.ymin;
sp_globals.y_band.band_max = sp_globals.ymax - 1; 

sp_globals.xmin = (Pmin.x + sp_globals.pixrnd) >> sp_globals.pixshift;
sp_globals.xmax = (Pmax.x + sp_globals.pixrnd) >> sp_globals.pixshift;


#if INCL_2D
sp_globals.x_band.band_min = sp_globals.xmin - 1; /* subtract one pixel of "safety margin" */
sp_globals.x_band.band_max = sp_globals.xmax /* - 1 + 1 */; /* Add one pixel of "safety margin" */
#endif
}




                                  


FUNCTION void sp_reduce_band_size_out(PARAMS1)
GDECL
{
sp_globals.y_band.band_min = sp_globals.y_band.band_max - ((sp_globals.y_band.band_max - sp_globals.y_band.band_min) >> 1);
#if INCL_2D
sp_globals.y_band.band_array_offset = sp_globals.y_band.band_min;
#endif
}


FUNCTION boolean sp_next_band_out(PARAMS1)
GDECL
{
fix15  tmpfix15;

if (sp_globals.y_band.band_min <= sp_globals.ymin)
    return FALSE;
tmpfix15 = sp_globals.y_band.band_max - sp_globals.y_band.band_min;
sp_globals.y_band.band_max = sp_globals.y_band.band_min - 1;
sp_globals.y_band.band_min = sp_globals.y_band.band_max - tmpfix15;
if (sp_globals.y_band.band_min < sp_globals.ymin)
    sp_globals.y_band.band_min = sp_globals.ymin;
#if INCL_2D
sp_globals.y_band.band_array_offset = sp_globals.y_band.band_min;
#endif
return TRUE;
}
#endif
#if INCL_CLIPPING
FUNCTION void set_clip_parameters()
GDECL
{
fix31 bmap_max, bmap_min;

    sp_globals.clip_xmax = sp_globals.xmax;
    sp_globals.clip_xmin = sp_globals.xmin;

    switch(sp_globals.tcb0.xtype)
       {
       case 1: /* 180 degree rotation */
            if (sp_globals.specs.flags & CLIP_TOP)
               {
               sp_globals.clip_ymin = (fix31)((fix31)EM_TOP * sp_globals.tcb0.yppo + ((1<<sp_globals.multshift)/2));
               sp_globals.clip_ymin = sp_globals.clip_ymin >> sp_globals.multshift;
               bmap_min = (sp_globals.bmap_ymin + sp_globals.pixrnd + 1) >> sp_globals.pixshift;
	       sp_globals.clip_ymin = -1 * sp_globals.clip_ymin;
	       if (bmap_min < sp_globals.clip_ymin)
		    sp_globals.ymin = sp_globals.clip_ymin;
               else
                    sp_globals.ymin = bmap_min;
               }
            if (sp_globals.specs.flags & CLIP_BOTTOM)
               {
               sp_globals.clip_ymax = (fix31)((fix31)(-1 * EM_BOT) * sp_globals.tcb0.yppo + ((1<<sp_globals.multshift)/2));
               sp_globals.clip_ymax = sp_globals.clip_ymax >> sp_globals.multshift;
               bmap_max = (sp_globals.bmap_ymax + sp_globals.pixrnd) >> sp_globals.pixshift;
	       if (bmap_max < sp_globals.clip_ymax)
                    sp_globals.ymax = bmap_max;
               else
		    sp_globals.ymax = sp_globals.clip_ymax;
               }
               sp_globals.clip_xmax =  -sp_globals.xmin;
               sp_globals.clip_xmin = ((sp_globals.set_width.x+32768L) >> 16) -
                                      sp_globals.xmin;
               break;
       case 2: /* 90 degree rotation */
            if ((sp_globals.specs.flags & CLIP_TOP) ||
                (sp_globals.specs.flags & CLIP_LEFT))
               {
               sp_globals.clip_xmin = (fix31)((fix31)(-1 * EM_BOT) * sp_globals.tcb0.yppo + ((1<<sp_globals.multshift)/2));
               sp_globals.clip_xmin = sp_globals.clip_xmin >> sp_globals.multshift;
               sp_globals.clip_xmin = -1 * sp_globals.clip_xmin;
               bmap_min = (sp_globals.bmap_xmin + sp_globals.pixrnd + 1) >> sp_globals.pixshift;
	       if (bmap_min > sp_globals.clip_xmin)
                    sp_globals.clip_xmin = bmap_min;

	       /* normalize to x origin */
               sp_globals.clip_xmin -= sp_globals.xmin;
               }
            if ((sp_globals.specs.flags & CLIP_BOTTOM) ||
                (sp_globals.specs.flags & CLIP_RIGHT))
               {
               sp_globals.clip_xmax = (fix31)((fix31)EM_TOP * sp_globals.tcb0.yppo + ((1<<sp_globals.multshift)/2));
               sp_globals.clip_xmax = sp_globals.clip_xmax >> sp_globals.multshift;
               bmap_max = (sp_globals.bmap_xmax + sp_globals.pixrnd) >> sp_globals.pixshift;
	       if (bmap_max < sp_globals.clip_xmax)
                        sp_globals.clip_xmax  = bmap_max;

	       sp_globals.clip_ymax = 0;
	       if ((sp_globals.specs.flags & CLIP_TOP) && 
                   (sp_globals.ymax > sp_globals.clip_ymax))
		    sp_globals.ymax = sp_globals.clip_ymax;
	       sp_globals.clip_ymin = ((sp_globals.set_width.y+32768L) >> 16);
               if ((sp_globals.specs.flags & CLIP_BOTTOM) && 
                   (sp_globals.ymin < sp_globals.clip_ymin))
                    sp_globals.ymin = sp_globals.clip_ymin;
	       /* normalize to x origin */
               sp_globals.clip_xmax -= sp_globals.xmin;
               }
               break;
       case 3: /* 270 degree rotation */
            if ((sp_globals.specs.flags & CLIP_TOP) ||
                (sp_globals.specs.flags & CLIP_LEFT))
               {
               sp_globals.clip_xmin = (fix31)((fix31)EM_TOP * sp_globals.tcb0.yppo + ((1<<sp_globals.multshift)/2));
               sp_globals.clip_xmin = sp_globals.clip_xmin >> sp_globals.multshift;
	       sp_globals.clip_xmin = -1 * sp_globals.clip_xmin;
               bmap_min = (sp_globals.bmap_xmin + sp_globals.pixrnd + 1) >> sp_globals.pixshift;

               /* let the minimum be the larger of these two values */
	       if (bmap_min > sp_globals.clip_xmin)
		    sp_globals.clip_xmin = bmap_min;

	       /* normalize the x value to new xorgin */
               sp_globals.clip_xmin -= sp_globals.xmin;
               }
            if ((sp_globals.specs.flags & CLIP_BOTTOM) ||
                (sp_globals.specs.flags & CLIP_RIGHT))

               {
               sp_globals.clip_xmax = (fix31)((fix31)(-1 * EM_BOT) * sp_globals.tcb0.yppo + ((1<<sp_globals.multshift)/2));
               sp_globals.clip_xmax = sp_globals.clip_xmax >> sp_globals.multshift;
               bmap_max = (sp_globals.bmap_xmax + sp_globals.pixrnd) >> sp_globals.pixshift;

	       /* let the max be the lesser of these two values */
	       if (bmap_max < sp_globals.clip_xmax)
		    {
		    sp_globals.clip_xmax = bmap_max;
		    }

	       /* normalize the x value to new x origin */
	       sp_globals.clip_xmax -= sp_globals.xmin;
               }
            if (sp_globals.specs.flags & CLIP_BOTTOM)
               {
               /* compute y clip values */
	       sp_globals.clip_ymax = ((sp_globals.set_width.y+32768L) >> 16);
	       if ((sp_globals.specs.flags & CLIP_TOP) && 
                   (sp_globals.ymax > sp_globals.clip_ymax))
		    sp_globals.ymax = sp_globals.clip_ymax;
	       sp_globals.clip_ymin = 0;
               if ((sp_globals.specs.flags & CLIP_BOTTOM) && 
                   (sp_globals.ymin < sp_globals.clip_ymin))
                    sp_globals.ymin = sp_globals.clip_ymin;
               }
               break;
       default: /* this is for zero degree rotation and arbitrary rotation */
            if (sp_globals.specs.flags & CLIP_TOP)
               {
	       sp_globals.clip_ymax = (fix31)((fix31)EM_TOP * sp_globals.tcb0.yppo + ((1<<sp_globals.multshift)/2));
               sp_globals.clip_ymax = sp_globals.clip_ymax >> sp_globals.multshift;
               bmap_max = (sp_globals.bmap_ymax + sp_globals.pixrnd) >> sp_globals.pixshift;
	       if (bmap_max > sp_globals.clip_ymax)
                    sp_globals.ymax = bmap_max;
               else
		    sp_globals.ymax = sp_globals.clip_ymax;
               }
            if (sp_globals.specs.flags & CLIP_BOTTOM)
               {
	       sp_globals.clip_ymin = (fix31)((fix31)(-1 * EM_BOT) * sp_globals.tcb0.yppo +  ((1<<sp_globals.multshift)/2));
               sp_globals.clip_ymin = sp_globals.clip_ymin >> sp_globals.multshift;
	       sp_globals.clip_ymin = - sp_globals.clip_ymin;
               bmap_min = (sp_globals.bmap_ymin + sp_globals.pixrnd + 1) >> sp_globals.pixshift;
	       if (bmap_min < sp_globals.clip_ymin)
		    sp_globals.ymin = sp_globals.clip_ymin;
               else
                    sp_globals.ymin = bmap_min;
               }
               sp_globals.clip_xmin = -sp_globals.xmin;
               sp_globals.clip_xmax = ((sp_globals.set_width.x+32768L) >> 16) -
                                      sp_globals.xmin;
               break;
       }
}
#endif

#pragma Code()
