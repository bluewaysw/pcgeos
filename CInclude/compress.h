/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	Compress Library
 * FILE:	compress.h
 *
 *
 * REVISION HISTORY:
 *	
 *	Name	Date		Description
 *	----	----		-----------
 *	atw	1/25/93		Initial revision
 *
 *
 * DESCRIPTION:
 *	Contains declarations for externally callable routines in the compress
 *	library.
 *		
 *	$Id: compress.h,v 1.1 97/04/04 15:57:38 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__COMPRESS_H
#define	__COMPRESS_H

#define	COMPRESS_PROTO_MAJOR	1
#define	COMPRESS_PROTO_MINOR	0

typedef WordFlags CompLibFlags;

#define	CLF_SOURCE_IS_BUFFER	0x8000
#define	CLF_DEST_IS_BUFFER	0x4000
#define	CLF_DECOMPRESS	    	0x2000
#define	CLF_MOSTLY_ASCII	0x1000

extern word
    _pascal CompressDecompress(CompLibFlags flags,
			       FileHandle sourceFileHandle,
			       void *sourceBuffer,
			       word sourceBufferSize,
			       FileHandle destFileHandle,
			       void *destBuffer);

#ifdef    __HIGHC__
pragma Alias(CompressDecompress, "COMPRESSDECOMPRESS");
#endif

#endif
