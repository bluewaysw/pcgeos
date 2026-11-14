/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 * PROJECT:	  PC GEOS
 * MODULE:	  
 * FILE:	  jerror.h
 *
 * AUTHOR:  	  Joon Song: Oct 29, 1995
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Joon	10/29/95   	Initial version
 *
 * DESCRIPTION:
 *	
 *
 *
 * 	$Id: jerror.h,v 1.1.11.7 97/11/13 17:25:44 joon Exp $
 *
 ***********************************************************************/

#ifndef _JERROR_H_
#define _JERROR_H_

/*
 * jerror.h
 *
 * Copyright (C) 1994-1995, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file defines the error and message codes for the JPEG library.
 * Edit this file to add new codes, or to translate the message strings to
 * some other language.
 * A set of error-reporting macros are defined too.  Some applications using
 * the JPEG library may wish to include this file to get the error codes
 * and/or the macros.
 */

typedef enum {
  JERR_BAD_ALIGN_TYPE,		/* ALIGN_TYPE is wrong, please fix */
  JERR_BAD_ALLOC_CHUNK,		/* MAX_ALLOC_CHUNK is wrong, please fix */
  JERR_BAD_BUFFER_MODE,		/* Bogus buffer control mode */
  JERR_BAD_COMPONENT_ID,	/* Invalid component ID %d in SOS */
  JERR_BAD_DCTSIZE,		/* IDCT output block size %d not supported */
  JERR_BAD_J_COLORSPACE,	/* Bogus JPEG colorspace */
  JERR_BAD_MCU_SIZE,		/* Sampling factors too large x-leaved scan */
  JERR_BAD_POOL_ID,		/* Invalid memory pool code %d */
  JERR_BAD_PRECISION,		/* Unsupported JPEG data precision %d */
  JERR_BAD_SAMPLING,		/* Bogus sampling factors */
  JERR_BAD_STATE,		/* Improper call to JPEG library in state %d */
  JERR_BAD_VIRTUAL_ACCESS,	/* Bogus virtual array access */
  JERR_COMPONENT_COUNT,		/* Too many color components: %d, max %d */
  JERR_CONVERSION_NOTIMPL,	/* Unsupported color conversion request */
  JERR_EOI_EXPECTED,		/* Didn't expect more than one scan */
  JERR_FRACT_SAMPLE_NOTIMPL,	/* Fractional sampling not implemented yet */
  JERR_IMAGE_TOO_BIG,		/* Exceeded maximum image dimension */
  JERR_MODE_CHANGE,		/* Invalid color quantization mode change */
  JERR_NOTIMPL,			/* Not implemented yet */
  JERR_NOT_COMPILED,		/* Feature was omitted at compile time */
  JERR_NO_HUFF_TABLE,		/* Huffman table 0x%02x was not defined */
  JERR_NO_QUANT_TABLE,		/* Quantization table 0x%02x was not defined */
  JERR_OUT_OF_MEMORY,		/* Insufficient memory (case %d) */
  JERR_QUANT_COMPONENTS,	/* Too many color components */
  JERR_QUANT_FEW_COLORS,	/* Cannot quantize to fewer than %d colors */
  JERR_QUANT_MANY_COLORS,	/* Cannot quantize to more than %d colors */
  JERR_SOF_NO_SOS,		/* Invalid JPEG file structure:missing SOS */
  JERR_TOO_LITTLE_DATA,		/* Application transferred too few scanlines */
  JERR_VIRTUAL_BUG,		/* Virtual array controller messed up */
  JERR_WIDTH_OVERFLOW,		/* Image too wide for this implementation */
} FatalErrors;

typedef enum {
  JWRN_ADOBE_XFORM,		/* Unknown Adobe color transform code %d */
  JWRN_APP0,			/* Unknown APP0 marker (not JFIF) */
  JWRN_APP14,			/* Unknown APP14 marker (not Adobe) */
  JWRN_BAD_LENGTH,		/* Bogus marker length */
  JWRN_DAC_INDEX,		/* Bogus DAC index %d */
  JWRN_DAC_VALUE,		/* Bogus DAC value 0x%x */
  JWRN_DHT_COUNTS,		/* Bogus DHT counts */
  JWRN_DHT_INDEX,		/* Bogus DHT index %d */
  JWRN_DQT_INDEX,		/* Bogus DQT index %d */
  JWRN_EMPTY_IMAGE,		/* Empty JPEG image (DNL not supported) */
  JWRN_EXTRANEOUS_DATA,		/* Corrupt JPEG data: extraneous bytes */
  JWRN_HIT_MARKER,		/* Corrupt JPEG data: premature end of data */
  JWRN_HUFF_BAD_CODE,		/* Corrupt JPEG data: bad Huffman code */
  JWRN_JFIF_BADTHUMBNAILSIZE,	/* Warning: thumbnail image size does match */
  JWRN_JFIF_THUMBNAIL,		/*     with %d x %d thumbnail image */
  JWRN_JFIF_MINOR,		/* Unknown JFIF minor revision number */
  JWRN_JFIF_MAJOR,		/* Warning: unknown JFIF revision number */
  JWRN_JPEG_EOF,		/* Premature end of JPEG file */
  JWRN_MUST_RESYNC,		/* Corrupt JPEG data: found wrong marker */
  JWRN_NO_SOI,			/* Not a JPEG file: starts with ?? ?? */
  JWRN_NOT_SEQUENTIAL,		/* Invalid SOS parameters for sequential JPEG*/
  JWRN_SOF_DUPLICATE,		/* Invalid JPEG file structure:2 SOF markers */
  JWRN_SOF_UNSUPPORTED,		/* Unsupported JPEG process: SOF type 0x%02x */
  JWRN_SOI_DUPLICATE,		/* Invalid JPEG file structure:2 SOI markers */
  JWRN_SOS_NO_SOF,		/* Invalid JPEG file structure:SOS b4 SOF */
  JWRN_TOO_MUCH_DATA,		/* Application transferred too many scanlines*/
  JWRN_UNKNOWN_IDS,		/* Unrecognized component IDs, assuming YCbCr*/
  JWRN_UNKNOWN_MARKER,		/* Unsupported marker type 0x%02x */
} Warnings;

extern FatalErrors ying;
extern Warnings yang;


/* Macros to simplify using the error and trace message stuff */
/* The first parameter is either type of cinfo pointer */

/* Fatal errors (print message and exit) */
#define ERREXIT(cinfo,code)  \
    EC_ERROR(code)
#define ERREXIT1(cinfo,code,p1)  \
    EC_ERROR(code)
#define ERREXIT2(cinfo,code,p1,p2)  \
    EC_ERROR(code)
#define ERREXIT3(cinfo,code,p1,p2,p3)  \
    EC_ERROR(code)
#define ERREXIT4(cinfo,code,p1,p2,p3,p4)  \
    EC_ERROR(code)
#define ERREXITS(cinfo,code,str)  \
    EC_ERROR(code)

#define MAKESTMT(stuff)		do { stuff } while (0)

#endif /* _JERROR_H_ */
