/*********************************************************************/
/*								     */
/*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     */
/*								     */
/* 	PROJECT:	PC GEOS					     */
/* 	MODULE:							     */	
/* 	FILE:		tiffopt.h				     */
/*								     */
/*	AUTHOR:		jimmy lefkowitz				     */
/*								     */
/*	REVISION HISTORY:					     */
/*								     */
/*	Name	Date		Description			     */
/*	----	----		-----------			     */
/*	jimmy	1/27/92		Initial version			     */
/*								     */
/*	DESCRIPTION:						     */
/*								     */
/*	$Id: tiffopt.h,v 1.1 97/04/07 11:27:49 newdeal Exp $
/*							   	     */
/*********************************************************************/



// TIFF filter internal options

#define     TIFF_NOCOMP        0
#define     TIFF_PACKBIT       1
#define     TIFF_LZW           2
#define     TIFF_CCITT         3

#define     TIFF_INTEL         0
#define     TIFF_MOTOR         1

#define     TIFF_INVERT        1
#define     TIFF_NOINVERT      0


// TIFF filter extern options. These options are set in the dwOption field
// within the 3rd parameter (LPCNVOPTION).  By setting the appropriate
// bit values, the filter will act promptly.

// According to TIFF 5.0 spec, LZW is the ONLY allowed compression
// method for Color and Grayscale image.  Monochrome image can be compressed
// with Packbit, CCITT only!

#define    TIF_NOCOMP      0x00    // bit 0-2      0:NO compression
#define    TIF_PACKBIT     0x01    //              1:packbit, 
#define    TIF_LZW         0x02    //              2:LZW,
#define    TIF_CCITT       0x03    //              3:CCITT G3
#define    TIF_AUTOCMPR    0x04    //              4:auto compression
                                   //                Filter will decide which
                                   //                compression scheme to use
                                   //                based upon the image type.
                                   //                For mono image, packbit is
                                   //                used. For color and gray
                                   //                image, LZW is used.

#define    TIF_INTEL       0x00    // bit 3,4  00:intel format
#define    TIF_MOTOR       0x08    //          01:motorola format

#define    TIF_INVERT      0x20    // bit 5, 1:invert, 
#define    TIF_NOINVERT    0x00    //        0:no invert

