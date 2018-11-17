/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * PROJECT:	  PC SDK
 * MODULE:	  Sample Library -- Mandelbrot Set Library
 * FILE:	  msConst.h
 *
 * AUTHOR:  	  Paul DuBois: Aug  9, 1993
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dubois	8/ 9/93   	Initial version
 *
 * DESCRIPTION:
 *	Constants for the MSet object's internal use.
 *
 * 	$Id: msConst.h,v 1.1 97/04/07 10:43:37 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _MSCONST_H_
#define _MSCONST_H_

/*
 * These constants are used to initialize the MSetParameters block of a
 * newly-created MSet.
 * 
 * MSET_DEF_WIDTH and MSET_DEF_HEIGHT are the width and height (in pixels)
 * of the MSet.
 * 
 * MSET_DEF_LEFT and MSET_DEF_TOP are put into the high word of
 * the fixnums MSP_left and MSP_top.  These parameters define the
 * coordinates of the top-left corner of the generated MSet.  They are
 * FixNums, which means that they have only 4 bits of integer.
 * 
 * MSET_DEF_RESOLUTION is put into the high word of MSP_hRes and MSP_vRes;
 * they control the distance between calculated pixels of the MSet.
 * The smaller the number, the more zoomed-in the image.
 * 
 * A good rule of thumb is that for the high word of a FixNum, 1<<12 is 1
 * unit.  These constants were chosen so that the image from (-2,2) to
 * (2,-2) is displayed.
 */

#define MSET_DEF_COLOR_SCHEME	MSC_BRIGHT
#define MSET_DEF_PRECISION	MSP_16BIT
#define MSET_DEF_MAX_DWELL	200

#define	MSET_DEF_WIDTH		128
#define	MSET_DEF_HEIGHT		128

#define MSET_DEF_LEFT		(-2<<12)
#define MSET_DEF_TOP		(2<<12)

/* 1/32 of a unit */
#define MSET_DEF_RESOLUTION	(1<<7)


#endif /* _MSCONST_H_ */
