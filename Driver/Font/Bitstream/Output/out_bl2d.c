/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Output/out_bl2d.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: out_bl2d.c,v 1.1 97/04/18 11:45:13 newdeal Exp $
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
/*************************** O U T _ B L 2 D . C *********************************
 *                                                                           *
 * This is an output module for screen writer using two dimensional scanning *
 *                                                                           */
/********************* Revision Control Information **********************************
*                                                                                    *
*                                                                                    *
*       Revision 28.37  93/03/15  12:46:37  roberte
*       Release
*       
*       Revision 28.9  93/01/12  12:00:49  roberte
*       #undef'ed CLOCKWISE if was already defined.
*       
*       Revision 28.8  92/12/30  17:44:41  roberte
*       Functions no longer renamed in spdo_prv.h now declared with "sp_"
*       Use PARAMS1&2 macros throughout.
*       
*       Revision 28.7  92/12/14  15:13:59  weili
*       Modified sp_proc_intercepts_2d(PARAMS1) to fix the -x
*       problems caused by characters below 6 lines 
*       
*       Revision 28.6  92/11/24  10:59:31  laurar
*       include fino.h
*       
*       Revision 28.5  92/11/19  15:16:43  roberte
*       Release
*       
*       Revision 28.1  92/06/25  13:40:21  leeann
*       Release
*       
*       Revision 27.1  92/03/23  14:00:01  leeann
*       Release
*       
*       Revision 26.1  92/01/30  16:58:46  leeann
*       Release
*       
*       Revision 25.1  91/07/10  11:05:01  leeann
*       Release
*       
*       Revision 24.1  91/07/10  10:38:35  leeann
*       Release
*       
*       Revision 23.1  91/07/09  17:59:28  leeann
*       Release
*       
*       Revision 22.3  91/06/19  14:34:45  leeann
*       move code into set_clip_parameters() in out_util
*       
*       Revision 22.2  91/05/23  16:12:47  mark
*       get formfeed off of conditional line.
*       
*       Revision 22.1  91/01/23  17:18:45  leeann
*       Release
*       
*       Revision 21.2  90/11/28  11:31:14  joyce
*       fixed problem in draw_vector_to_2d
*       
*       Revision 21.1  90/11/20  14:38:07  leeann
*       Release
*       
*       Revision 20.2  90/11/20  13:16:09  leeann
*       fixed clipping precision
*       
*       Revision 20.1  90/11/12  09:30:44  leeann
*       Release
*       
*       Revision 19.1  90/11/08  10:20:23  leeann
*       Release
*       
*       Revision 18.2  90/11/07  15:39:45  leeann
*        implement clipping for rotation of 90, 180, and 270 degrees
*       
*       Revision 18.1  90/09/24  10:10:13  mark
*       Release
*       
*       Revision 17.1  90/09/13  16:02:55  mark
*       Release name rel0913
*       
*       Revision 16.1  90/09/11  13:19:11  mark
*       Release
*       
*       Revision 15.1  90/08/29  10:06:41  mark
*       Release name rel0829
*       
*       Revision 14.4  90/08/29  09:55:53  judy
*       fix syntax error in interchar spacing
*       
*       Revision 14.3  90/08/28  17:24:17  judy
*       fix interchar spacing fix - xmode = 4 has no rounding error
*       
*       Revision 14.2  90/08/28  16:35:32  judy
*       fix inter-character spacing bug in end_char: add the round
*       error based on the xmode and ymode type to either xorg or
*       yorg.
*       
*       Revision 14.1  90/07/13  10:44:01  mark
*       Release name rel071390
*       
*       Revision 13.1  90/07/02  10:42:51  mark
*       Release name REL2070290
*       
*       Revision 12.3  90/06/26  08:57:10  leeann
*       When CLIPPED characters go into banding, save the
*       correct ymin and ymax
*       
*       Revision 12.2  90/06/06  16:41:26  judy
*       fix inter-character spacing
*       
*       Revision 12.1  90/04/23  12:15:02  mark
*       Release name REL20
*       
*       Revision 11.1  90/04/23  10:15:18  mark
*       Release name REV2
*       
*       Revision 10.6  90/04/20  12:52:31  judy
*       fix revision comment.
*       
*       Revision 10.5  90/04/20  11:54:43  judy
*       enter rccs information.
*       
*************************************************************************************/

#ifdef RCSSTATUS
#endif

/********************** R E V I S I O N   H I S T O R Y **********************
 *                                                                           *
 *  1)  29 Mar 89 cdf   First Version                                        *
 *                                                                           *
 ****************************************************************************/

#include "spdo_prv.h"              /* General definitions for speedo */
#include "fino.h"

#ifdef CLOCKWISE
#undef CLOCKWISE
#endif
#define   CLOCKWISE  1
#define   DEBUG      0
#define   ABS(X)     ( (X < 0) ? -X : X)

#if DEBUG
#include <stdio.h>
#define SHOW(X) printf("X = %d\n", X)
#else
#define SHOW(X)
#endif

/***** GLOBAL VARIABLES *****/

/***** GLOBAL FUNCTIONS *****/

/***** EXTERNAL VARIABLES *****/

/***** EXTERNAL FUNCTIONS *****/

/***** STATIC VARIABLES *****/

/***** STATIC FUNCTIONS *****/



#if INCL_2D
FUNCTION boolean sp_init_2d(PARAMS2 specsarg)
GDECL
specs_t GLOBALFAR *specsarg;
/*
 * init_out_2d() is called by sp_set_specs(PARAMS1) to initialize the output module.
 * Returns TRUE if output module can accept requested specifications.
 * Returns FALSE otherwise.
 */
{

if (specsarg->flags & CURVES_OUT)
    return FALSE;           /* Curves out, clipping not supported */

#if DEBUG
printf("INIT_OUT__2d()\n");
#endif
return TRUE;
}
#endif

#if INCL_2D
FUNCTION boolean sp_begin_char_2d(PARAMS2 Psw, Pmin, Pmax)
GDECL
point_t Psw;                   
point_t Pmin;                   
point_t Pmax;                   
/* Called once at the start of the character generation process
 * Initializes intercept table, either calculates pixel maxima or
 * decides that they need to be collected
 */
{
#if DEBUG
printf("BEGIN_CHAR__2d(%3.1f, %3.1f, %3.1f, %3.1f, %3.1f, %3.1f\n", 
                    (real)Psw.x / (real)sp_globals.one_pix, (real)Psw.y / (real)sp_globals.onepix,
                    (real)Pmin.x / (real)sp_globals.onepix, (real)Pmin.y / (real)sp_globals.onepix,
                    (real)Pmax.x / (real)sp_globals.onepix, (real)Pmax.y / (real)sp_globals.onepix);
#endif
/* Convert PIX.FRAC to 16.16 form */
sp_globals.x_scan_active = TRUE;  /* Assume x-scanning from the start */

sp_init_char_out(PARAMS2 Psw,Pmin,Pmax);
return TRUE;
}
#endif


#if INCL_2D
FUNCTION void sp_begin_contour_2d(PARAMS2 P1, outside)
GDECL
point_t P1;                   
boolean outside;
/* Called at the start of each contour
 */
{

#if DEBUG
printf("BEGIN_CONTOUR__2d(%3.4f, %3.4f, %s)\n", 
    (real)P1.x / (real)sp_globals.onepix, 
    (real)P1.y / (real)sp_globals.onepix, 
    outside? "outside": "inside");
#endif
sp_globals.x0_spxl = P1.x;
sp_globals.y0_spxl = P1.y;
}
#endif

#if INCL_2D
FUNCTION void sp_line_2d(PARAMS2 P1)
GDECL
point_t P1;
/*
 * Called for each vector in the transformed character
 *     "draws" vector into intercept table
 */
{

#if DEBUG
printf("LINE_0(%3.4f, %3.4f)\n", 
       (real)P1.x / (real)sp_globals.onepix, 
       (real)P1.y / (real)sp_globals.onepix);
#endif

if (sp_globals.extents_running)
    {
    if (sp_globals.x0_spxl > sp_globals.bmap_xmax)         
        sp_globals.bmap_xmax = sp_globals.x0_spxl;
    if (sp_globals.x0_spxl < sp_globals.bmap_xmin)
        sp_globals.bmap_xmin = sp_globals.x0_spxl;
    if (sp_globals.y0_spxl > sp_globals.bmap_ymax)
        sp_globals.bmap_ymax = sp_globals.y0_spxl;
    if (sp_globals.y0_spxl < sp_globals.bmap_ymin)
        sp_globals.bmap_ymin = sp_globals.y0_spxl;
    }

if (!sp_globals.intercept_oflo)
    {
    sp_draw_vector_to_2d(PARAMS2 sp_globals.x0_spxl,
                  sp_globals.y0_spxl,
                  P1.x,
                  P1.y,
                  &sp_globals.y_band); /* y-scan */

    if (sp_globals.x_scan_active)
        sp_draw_vector_to_2d(PARAMS2 sp_globals.y0_spxl,
                      sp_globals.x0_spxl,
                      P1.y,
                      P1.x,
                      &sp_globals.x_band); /* x-scan if selected */
    }

sp_globals.x0_spxl = P1.x; 
sp_globals.y0_spxl = P1.y; /* update endpoint */
}

FUNCTION static void sp_draw_vector_to_2d(PARAMS2 x0, y0, x1, y1, band)
GDECL
fix15 x0;                /* X coordinate */
fix15 y0;                /* Y coordinate */
fix15 x1;
fix15 y1;
band_t GLOBALFAR *band;
{
register fix15     how_many_y;       /* # of intercepts at y = n + 1/2  */
register fix15     yc;               /* Current scan-line */
         fix15     temp1;            /* various uses */
         fix15     temp2;            /* various uses */
register fix31     dx_dy;            /* slope of line in 16.16 form */
register fix31     xc;               /* high-precision (16.16) x coordinate */
         fix15     y_pxl;

yc = (y0 + sp_globals.pixrnd) >> sp_globals.pixshift;      /* current scan line = end of last line */
y_pxl = (y1 + sp_globals.pixrnd) >> sp_globals.pixshift;   /* calculate new end-scan line */

if ((how_many_y = y_pxl - yc) == 0) return; /* Don't draw a null line */

if (how_many_y < 0) yc--; /* Predecrment downward lines */

if (yc > band->band_max) /* Is start point above band? */
    {
    if (y_pxl > band->band_max) return; /* line has to go down! */
    how_many_y = y_pxl - (yc = band->band_max) - 1; /* Yes, limit it */
    }

if (yc < band->band_min)   /* Is start point below band? */
    {
    if (y_pxl < band->band_min) return; /* line has to go up! */
    how_many_y = y_pxl - (yc = band->band_min);   /* Yes, limit it */
    }

xc = (fix31)(x0 + sp_globals.pixrnd) << 16; /* Original x coordinate with built in  */
                                 /* rounding. int.16 + pixshift form */

if ( (temp1 = (x1 - x0)) == 0)  /* check for vertical line */
    {
    dx_dy = 0L; /* Zero slope, leave xc alone */
    goto skip_calc;
    }
          
/* calculate dx_dy at 16.16 fixed point */

dx_dy = ( (fix31)temp1 << 16 )/(fix31)(y1 - y0);

/* We have to check for a @#$%@# possible multiply overflow  */
/* by doing another @#$*& multiply.  In assembly language,   */
/* the program could just check the OVerflow flag or whatever*/
/* works on the particular processor.  This C code is meant  */
/* to be processor independent.                              */

temp1 = (yc << sp_globals.pixshift) - y0 + sp_globals.pixrnd;
/* This sees if the sign bits start at bit 15 */
/* if they do, no overflow has occurred       */

temp2 = (fix15)(MULT16(temp1,(fix15)(dx_dy >> 16)) >> 15);

if (  (temp2 != (fix15)0xFFFF) &&
      (temp2 != 0x0000)   )
    {  /* Overflow. Pick point closest to yc + .5 */
    if (ABS(temp1) < ABS((yc << sp_globals.pixshift) - y1 + sp_globals.pixrnd))
        { /* use x1 instead of x0 */
        xc = (fix31)(x1 + sp_globals.pixrnd) << (16 - sp_globals.pixshift);
        }
    goto skip_calc;
    }
/* calculate new xc at the center of the *current* scan line */
/* due to banding, yc may be several lines away from y0      */
/*  xc += (yc + .5 - y0) * dx_dy */
/* This multiply generates a subpixel delta. */
/* So we leave it as an int.pixshift + 16 delta */

xc += (fix31)temp1 * dx_dy;
dx_dy <<= sp_globals.pixshift;
skip_calc:

yc -= band->band_array_offset; /* yc is now an offset relative to the band */

if (how_many_y < 0)
    {   /* Vector down */
    if ((how_many_y += yc + 1) < band->band_floor) 
        how_many_y = band->band_floor; /* can't go below floor */
    while(yc >= how_many_y)
        {
        temp1 = (fix15)(xc >> 16); 
        sp_add_intercept_2d(PARAMS2 yc--,temp1); 
        xc -= dx_dy;
        }
    }
    else
    {   /* Vector up */
     /* check to see that line doesn't extend beyond top of band */
    if ((how_many_y += yc) > band->band_ceiling) 
        how_many_y = band->band_ceiling;
    while(yc < how_many_y)
        {
        temp1 = (fix15)(xc >> 16);
        sp_add_intercept_2d(PARAMS2 yc++,temp1); 
        xc += dx_dy;
        }
    }
}

#endif

#if INCL_2D
FUNCTION boolean sp_end_char_2d(PARAMS1)
GDECL
/* Called when all character data has been output
 * Return TRUE if output process is complete
 * Return FALSE to repeat output of the transformed data beginning
 * with the first contour
 */
{

fix31 xorg;
fix31 yorg;

#if DEBUG
printf("END_CHAR__2d()\n");
#endif

if (sp_globals.first_pass)
    {
    if (sp_globals.bmap_xmax >= sp_globals.bmap_xmin)
        {
        sp_globals.xmin = (sp_globals.bmap_xmin + sp_globals.pixrnd + 1) >> sp_globals.pixshift;
        sp_globals.xmax = (sp_globals.bmap_xmax + sp_globals.pixrnd) >> sp_globals.pixshift;
        }
    else
        {
        sp_globals.xmin = sp_globals.xmax = 0;
        }
/****************************************************************************/
    if (sp_globals.bmap_ymax >= sp_globals.bmap_ymin)
        {

#if INCL_CLIPPING
set_clip_parameters();
if ( !(sp_globals.specs.flags & CLIP_TOP))
#endif
            sp_globals.ymax = (sp_globals.bmap_ymax + sp_globals.pixrnd) >> sp_globals.pixshift;

#if INCL_CLIPPING
if ( !(sp_globals.specs.flags & CLIP_BOTTOM))
#endif
        sp_globals.ymin = (sp_globals.bmap_ymin + sp_globals.pixrnd + 1) >> sp_globals.pixshift;
        }
    else
        {
        sp_globals.ymin = 0;
	sp_globals.ymax = 0;
        }
/****************************************************************************
if (sp_globals.bmap_ymax >= sp_globals.bmap_ymin) {
	sp_globals.ymax = (sp_globals.bmap_ymax + sp_globals.pixrnd) >> sp_globals.pixshift;
	sp_globals.ymin = (sp_globals.bmap_ymin + sp_globals.pixrnd + 1) >> sp_globals.pixshift;
} else {
	sp_globals.ymin = sp_globals.ymax = 0;
}
****************************************************************************/

    /* add in the rounded out part (from xform.) of the left edge */
    if (sp_globals.tcb.xmode == 0)    /* for X pix is function of X orus only add the round */
    	xorg = (((fix31)sp_globals.xmin << 16) + (sp_globals.rnd_xmin << sp_globals.poshift));
    else
        if (sp_globals.tcb.xmode == 1) /* for X pix is function of -X orus only, subtr. round */
        	xorg = (((fix31)sp_globals.xmin << 16) - (sp_globals.rnd_xmin << sp_globals.poshift)) ;
        else
        	xorg = (fix31)sp_globals.xmin << 16;   /* for other cases don't use round on x */
           
    if (sp_globals.tcb.ymode == 2)   /* for Y pix is function of X orus only, add round error */ 
    	yorg = (((fix31)sp_globals.ymin << 16) + (sp_globals.rnd_xmin << sp_globals.poshift));
    else
        if (sp_globals.tcb.ymode == 3) /* for Y pix is function of -X orus only, sub round */
        	yorg = (((fix31)sp_globals.ymin << 16) - (sp_globals.rnd_xmin << sp_globals.poshift));
        else                          /* all other cases have no round error on yorg */
         	yorg = (fix31)sp_globals.ymin << 16;

    open_bitmap(sp_globals.set_width.x, sp_globals.set_width.y, xorg, yorg,
				 sp_globals.xmax - sp_globals.xmin, sp_globals.ymax -  sp_globals.ymin);
    if (sp_globals.intercept_oflo)
        {
        sp_globals.y_band.band_min = sp_globals.ymin;
        sp_globals.y_band.band_max = sp_globals.ymax;
        sp_globals.x_scan_active = FALSE;
        sp_globals.no_x_lists = 0;
        sp_init_intercepts_out(PARAMS1);
        sp_globals.first_pass = FALSE;
        sp_globals.extents_running = FALSE;
        return FALSE;
        }
    else
        {
        sp_proc_intercepts_2d(PARAMS1);
        close_bitmap();
        return TRUE;
        }
    }
else
    {
    if (sp_globals.intercept_oflo)
        {
        sp_reduce_band_size_out(PARAMS1);
        sp_init_intercepts_out(PARAMS1);
        return FALSE;
        }
    else
        {
        sp_proc_intercepts_2d(PARAMS1);
        if (sp_next_band_out(PARAMS1))
            {
            sp_init_intercepts_out(PARAMS1);
            return FALSE;
            }
        close_bitmap();
        return TRUE;
        }
    }
}
#endif

#if INCL_2D
FUNCTION static  void sp_add_intercept_2d(PARAMS2 y, x)
GDECL
fix15 y;                 /* Y coordinate in relative pixel units */
                         /* (0 is lowest sample in band) */
fix15 x;                 /* X coordinate of intercept in subpixel units */

/*  Called by line() to add an intercept to the intercept list structure
 */

{
register fix15 from;   /* Insertion pointers for the linked list sort */
register fix15 to;

#if DEBUG
/* Bounds checking IS done in debug mode */
if ((y >= MAX_INTERCEPTS) || (y < 0))
    {
    printf("Intercept out of table!!!!! (%d)\n",y);
    return;
    }

if (y >= sp_globals.no_y_lists)
    {
    printf("    Add x intercept(%2d, %f)\n", 
        y + sp_globals.x_band.band_min - sp_globals.no_y_lists,
        (real)x/(real)sp_globals.onepix);
    if (y > (sp_globals.no_x_lists + sp_globals.no_y_lists))
        {
        printf(" Intercept too big for band!!!!!\007\n");
        return;
        }
    }
    else
    {
    printf("    Add y intercept(%2d, %f)\n", y + sp_globals.y_band.band_min,(real)x/(real)sp_globals.onepix);
    }

if (y < 0)       /* Y value below bottom of current band? */
    {
    printf(" Intecerpt less than 0!!!\007\n");
    return;
    }
#endif

/* Store new values */

sp_intercepts.car[sp_globals.next_offset] = x;

/* Find slot to insert new element (between from and to) */

from = y; /* Start at list head */

while( (to = sp_intercepts.cdr[from]) >= sp_globals.first_offset) /* Until to == end of list */
    {
    if (x <= sp_intercepts.car[to]) /* If next item is larger than or same as this one... */
        goto insert_element; /* ... drop out and insert here */
    from = to; /* move forward in list */
    }

insert_element: /* insert element "next_offset" between elements "from" */
                /* and "to" */

sp_intercepts.cdr[from] = sp_globals.next_offset;
sp_intercepts.cdr[sp_globals.next_offset] = to;

if (++sp_globals.next_offset >= MAX_INTERCEPTS) /* Intercept buffer full? */
    {
    sp_globals.intercept_oflo = TRUE;
/* There may be a few more calls to "add_intercept" from the current line */
/* To avoid problems, we set next_offset to a safe value. We don't care   */
/* if the intercept table gets trashed at this point                      */
    sp_globals.next_offset = sp_globals.first_offset;
    }
}

#endif

#if INCL_2D
FUNCTION static  void sp_proc_intercepts_2d(PARAMS1)
GDECL
/*  Called by sp_make_char to output accumulated intercept lists
 *  Clips output to xmin, xmax, sp_globals.ymin, ymax boundaries
 */
{
register fix15 i;
register fix15 from, to;          /* Start and end of run in pixel units   
                            relative to left extent of character  */
register fix15 y;
register fix15 scan_line;
         fix15 local_bmap_xmin;
         fix15 local_bmap_xmax;
         fix15 first_y, last_y;
         fix15 j,k;
         fix15 xmin, xmax;
         boolean clipleft, clipright;

/* fixed the -x bits problems cause by characters below 6 lines */
if ( sp_globals.xmax <= sp_globals.xmin )
    return;


#if INCL_CLIPPING
if ((sp_globals.specs.flags & CLIP_LEFT) != 0)
    clipleft = TRUE;
else
    clipleft = FALSE;
if ((sp_globals.specs.flags & CLIP_RIGHT) != 0)
    clipright = TRUE;
else
    clipright = FALSE;
if (clipleft || clipright)
        {
        xmax = sp_globals.clip_xmax << sp_globals.pixshift;
        xmin = sp_globals.clip_xmin << sp_globals.pixshift;
        }
if (!clipright)
        xmax = ((sp_globals.set_width.x+32768L) >> 16);
#endif

if (sp_globals.x_scan_active)      /* If xscanning, we need to make sure we don't miss any important pixels */
    {
    first_y = sp_globals.x_band.band_floor;        /* start of x lists */
    last_y = sp_globals.x_band.band_ceiling;                          /* end of x lists   */
    for (y = first_y; y != last_y; y++)             /* scan all xlists  */
        {
        i = sp_intercepts.cdr[y];                            /* Index head of intercept list */
        while (i != 0)         /* Link to next intercept if present */
            {
            from = sp_intercepts.car[i];
            j = i;
            i = sp_intercepts.cdr[i];                   /* Link to next intercept */
            if (i == 0)                   /* End of list? */
                {
#if DEBUG
                printf("****** proc_intercepts: odd number of intercepts in x list\n");
#endif
                break;
                }
            to = sp_intercepts.car[i];
            k = sp_intercepts.cdr[i];
            if (((to >> sp_globals.pixshift) >=  (from >> sp_globals.pixshift)) &&
                 ((to - from) < (sp_globals.onepix + 1)))
                {
                from = ((fix31)to + (fix31)from - (fix31)sp_globals.onepix) >> (sp_globals.pixshift + 1);
                if (from > sp_globals.y_band.band_max) 
					from = sp_globals.y_band.band_max;
                if ((from -= sp_globals.y_band.band_min) < 0) 
					from = 0;
                to = ((y - sp_globals.x_band.band_floor + sp_globals.x_band.band_min) 
                           << sp_globals.pixshift) 
                           + sp_globals.pixrnd;
                sp_intercepts.car[j] = to;
                sp_intercepts.car[i] = to + sp_globals.onepix;
                sp_intercepts.cdr[i] = sp_intercepts.cdr[from];
                sp_intercepts.cdr[from] = j;
                }
skip_xint:  i = k;
            }
        }
    }
#if DEBUG
printf("\nIntercept lists:\n");
#endif

if ((first_y = sp_globals.y_band.band_max) >= sp_globals.ymax)    
    first_y = sp_globals.ymax - 1;               /* Clip to ymax boundary */

if ((last_y = sp_globals.y_band.band_min) < sp_globals.ymin)      
    last_y = sp_globals.ymin;                    /* Clip to sp_globals.ymin boundary */

last_y  -= sp_globals.y_band.band_array_offset;

local_bmap_xmin = sp_globals.xmin << sp_globals.pixshift;
local_bmap_xmax = (sp_globals.xmax << sp_globals.pixshift) + sp_globals.pixrnd;

#if DEBUG
/* Print out all of the intercept info */
scan_line = sp_globals.ymax - first_y - 1;

for (y = first_y - sp_globals.y_band.band_min; y >= last_y; y--, scan_line++)
    {
    i = y;                            /* Index head of intercept list */
    while ((i = sp_intercepts.cdr[i]) != 0)         /* Link to next intercept if present */
        {
        if ((from = sp_intercepts.car[i] - local_bmap_xmin) < 0)
            from = 0;                 /* Clip to xmin boundary */
        i = sp_intercepts.cdr[i];                   /* Link to next intercept */
        if (i == 0)                   /* End of list? */
            {
            printf("****** proc_intercepts: odd number of intercepts\n");
            break;
            }
        if ((to = sp_intercepts.car[i]) > sp_globals.bmap_xmax)
            to = sp_globals.bmap_xmax - local_bmap_xmin;         /* Clip to xmax boundary */
        else
            to -= local_bmap_xmin;
        printf("    Y = %2d (scanline %2d): %3.4f %3.4f:\n", 
            y + sp_globals.y_band.band_min, 
            scan_line, 
            (real)from / (real)sp_globals.onepix, 
            (real)to / (real)sp_globals.onepix);
        }
    }
#endif

/* Draw the image */
scan_line = sp_globals.ymax - first_y - 1;

for (y = first_y - sp_globals.y_band.band_min; y >= last_y; y--, scan_line++)
    {
    i = y;                            /* Index head of intercept list */
    while ((i = sp_intercepts.cdr[i]) != 0)         /* Link to next intercept if present */
        {
        if ((from = sp_intercepts.car[i] - local_bmap_xmin) < 0)
            from = 0;                 /* Clip to xmin boundary */
        i = sp_intercepts.cdr[i];                   /* Link to next intercept */

        if ((to = sp_intercepts.car[i]) > local_bmap_xmax)
            to = sp_globals.bmap_xmax - local_bmap_xmin;         /* Clip to xmax boundary */
        else
            to -= local_bmap_xmin;
#if INCL_CLIPPING
                if (clipleft)
                        {
                        if (to <= xmin)
                                continue;
                        if (from < xmin)
                                from = xmin;
                        }
        if (clipright)
                        {
                        if (from >= xmax)
                                continue;
                        if (to > xmax)
                                to = xmax;
                        }
#endif
        if ( (to - from) <= sp_globals.onepix)
            {
            from = (to + from - sp_globals.onepix) >> (sp_globals.pixshift + 1);
            set_bitmap_bits(scan_line, from, from + 1);
            }
            else
            {
            set_bitmap_bits(scan_line, from >> sp_globals.pixshift, to >> sp_globals.pixshift);
            }
        }
    }
}

#endif

#pragma Code()
