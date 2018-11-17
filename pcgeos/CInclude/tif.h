/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tif.h

AUTHOR:		Maryann Simmons, customized by Daniel Medeiros

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 5/92   	Initial version.

DESCRIPTION:
	

	$Id: tif.h,v 1.1 97/04/07 11:27:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*************************************************************

    TIFF file data structure and constant definition

**************************************************************/

#ifndef _TIF_H
#define _TIF_H

typedef struct tifhdr 
    {
    word      byteOrder;    /* 0x4949 for l..m, 0x4d4d for m..lsb */
    word      tiffVersion;
    dword     ifdOffset;
    } TifHeader;

#define SIZEOFTIFHEADER    8

/*
 * Image File Directory Entry
 */
typedef struct
    {
    word tag;
    word type;            /* see defines below             */

#define IFD_BYTE    1
#define IFD_ASCII    2
#define IFD_SHORT    3
#define IFD_LONG    4
#define IFD_RATIONAL    5

    dword count;
    dword offset;            /* file offset of the actual bits */   
} IFDEntry;

#define  SIZEOFIFD 12

/*
 * Internal representation of the info about an IFD.
 */
typedef struct {
    dword bogus;             /* 1 if we can't deal with this image*/ 
    dword height, width;     /* dimensions */
    byte resolution;         // 1=full, 2=reduced, 3=single page of many 
    byte photoMetric;        // 0 -> 0 is white, 1 -> 0 is black 
    byte thresholding;       // 1 = bw scan, else gray-scale 
    byte fillOrder;          // 1 -> ms bits filled first, 2 -> ls 
    byte orientation;        // see doc 
    byte planeConfig;        // 1 = one plane, 2 = mult planes 
    byte resUnit;            // 1 no size unit, 2 inches, 3 centimeters 
    byte samplesPerPixel;
    byte bitsPerSample;
    word compression;        // 1 if not compressed 
    dword rowsPerStrip;      // number of rows per strip 
    dword stripOffset;       // offset to start of strips 
    dword stripByteCounts;
    dword minValue;
    dword maxValue;
    dword xResolution;
    dword yResolution;
    dword pageNumInfo;       // page number and number of pages in the document.
    dword Group3Options;     // specifies whether data is 1 or 2D compressed and if the image is using byte-aligned EOLs.
} Image;

/* list of stip offsets and byte counts */
typedef struct  Strip {
   dword  stripOffset;
   dword  stripByteCount;
} STRIP;

/* TIFF TAG mnenomics */
#define TAG_SubfileType            0xff /* obsolete */
#define TAG_NewSubfileType         0xfe
#define TAG_ImageWidth             0x100
#define TAG_ImageLength            0x101
#define TAG_BitsPerSample          0x102
#define TAG_Compression            0x103
#define TAG_PhotometricInterpretation    0x106
#define TAG_Thresholding           0x107 /* obsolete */
#define TAG_CellWidth              0x108 /* obsolete */
#define TAG_CellLength             0x109 /* obsolete */
#define TAG_FillOrder              0x10a /* obsolete */
#define TAG_DocumentName           0x10d /* name of the document where image is
                                       * scanned */
#define TAG_ImageDescription       0x10e /* image description(slug) */
#define TAG_Make                   0x10f /* manufacture of scanner, digitizer */
#define TAG_Model                  0x110 /* scanner, digitizer model */
#define TAG_StripOffsets           0x111
#define TAG_Orientation            0x112 /* obsolete */
#define TAG_SamplesPerPixel        0x115
#define TAG_RowsPerStrip           0x116
#define TAG_StripByteCounts        0x117
#define TAG_MinSampleValue         0x118 /* obsolete */
#define TAG_MaxSampleValue         0x119 /* obsolete */
#define TAG_XResolution            0x11a
#define TAG_YResolution            0x11b
#define TAG_PlanarConfiguration    0x11c
#define TAG_PageName               0x11d // page name of the document where image is
                                       // scanned */
#define TAG_XPosition            0x11e /* x offset of the left of the image */
#define TAG_YPOsition            0x11f /* y offset of the top of the image */
#define TAG_FreeOffsets          0x120 /* obsolete */
#define TAG_FreeByteCounts       0x121 /* obsolete */
#define TAG_GrayResponseUnit     0x122
#define TAG_GrayResponseCurve    0x123
#define TAG_Group3Options        0x124
#define TAG_Group4Options        0x125
#define TAG_ResolutionUnit       0x128
#define TAG_PageNumber           0x129 /* page # of the document where image is
                                       * scanned */
#define TAG_ColorResponseUnit    0x12c
#define TAG_ColorResponseCurves  0x12d
#define TAG_ColorMap             0x140

#define TAG_Software            0x131  /* name of the software used */
#define TAG_DateTime            0x132  /* date & time of creation */
#define TAG_Artish              0x13B  /* Artist/Creator of the image */
#define TAG_HostComputer        0x13C  /* host computer system */
#define TAG_Predictor           0x13D  /* new TAG, not supported */

#endif /* _TIF_H */
