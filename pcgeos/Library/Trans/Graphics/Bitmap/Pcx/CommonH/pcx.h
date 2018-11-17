/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pcx.h

AUTHOR:		Maryann Simmons, Apr 20, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	4/20/92   	Initial version.

DESCRIPTION:
	

	$Id: pcx.h,v 1.1 97/04/07 11:28:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* PCX file header format        */

#define SIZEOFPCXHEADER 128 

struct pcx_header {
        char manf,       /* 10 : PC Paintbrush PCX */
             version,    /* 0: v2.5, 2:V2.8, 3: V2.8 W/O pallete         */
                         /* 5: V3.0 w/palette */
             encoding,   /* 1: PCX Run-length encoding */
                         /* 0: no compression.                       */
             bpp;        /* bits per pixel */
        SHORT  Xmin, Ymin, Xmax,
                Ymax,    /* (Xmin,Ymin) (Xmax,Ymax) */
                H_res,   /* Horizontal Resolution */
                V_res;   /* Vertical Resolution */
        char colormap[16][3],  /* Color Pallete Setting */
                              /* Each RGB is from 0..255 */
                 reserve,
                 nplanes; /* # of color planes */
         SHORT         bpl; /* bytes per scan line */
         char tag[ 60 ];                    /*  Comment line  */
};
 
 
 
 
/* BITMAP file format data type */
typedef struct
        {
        WORD    dummy1;
        SHORT        bmType; 
        SHORT         bmWidth;
        SHORT         bmHeight;
        SHORT         bmWidthBytes;
        BYTE         bmPlanes;
        BYTE        bmBitsPixel;
        WORD        scnWidth, scnHeight;
/* extension for storing other valuable info */
        char        bmExtension[ 4 ];
        char         bmDescription[ 80 ];
        char        bmFormatID[ 20 ];
        BYTE        bmPallette[256][3];  /* pallette table, default to system color */
    BYTE    bmColors;            /* number of colors for the image */
    BYTE    bmImageType;         /* 0: mono, 1: gray, 2:RGB color */
                                 /* 3: pallette color */
}
BMFILEHDR;
 
