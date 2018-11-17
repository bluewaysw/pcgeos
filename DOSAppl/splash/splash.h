/***********************************************************************
 *
 *	Copyright (c) GlobalPC 1998.  All rights reserved.
 *	GLOBALPC CONFIDENTIAL
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  splash.h
 *
 * AUTHOR:  	  : Oct 02, 1998
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Todd    	10/02/98   	Initial version
 *
 * DESCRIPTION:
 *
 *	
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _SPLASH_H_
#define _SPLASH_H_

typedef struct {
	 unsigned char    zsoft_flag;
	 unsigned char    version_number;
	 unsigned char    encoding_flag;
	 unsigned char    bits_per_pixel;
	 unsigned char    xmin[2], ymin[2], xmax[2], ymax[2];
	 unsigned char    horiz_resolution[2], vert_resolution[2];
	 unsigned char    header_palette[48];
	 unsigned char    reserved;
	 unsigned char    planes;
	 unsigned char    bytes_per_scanline[2];
	 unsigned char    palette_interp[2];
	 unsigned char    video_screen_x[2], video_screen_y[2];
	 unsigned char    padding[54];
} PCXRawHeader;

typedef struct {
	 char             encoding_flag;
	 unsigned int	   bpp;
	 unsigned int	   xmin, ymin, xmax, ymax;
	 unsigned int     hrez, vrez;
	 unsigned int	   planes;
	 unsigned int	   bps;
	 unsigned int	   palette_type;
	 unsigned int	   screen_x, screen_y;
} PCXHeader;

typedef struct {
	unsigned char		red;
	unsigned char		green;
	unsigned char		blue;
} PaletteEntry;

typedef enum {
	 IDENTICAL_RUN,
	 VERBATIM_RUN
} LookaheadType;


#define PCX_RUN     	    0xc0    	/* Flag for PCX run length encoding. */

#endif /* _SPLASH_H_ */
