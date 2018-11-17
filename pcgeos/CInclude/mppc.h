/***********************************************************************
 *
 *	Copyright (c) Geoworks 1997 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  data compression
 * MODULE:	  Microsoft Point-to-Point Compression (MPPC) Library
 * FILE:	  mppc.h
 *
 * AUTHOR:  	  Jennifer Wu: Sep 24, 1997
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/24/97	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	API and definitions for Microsoft Point-to-Point Compression
 *	library.
 *	MPPC221-C Version 4.00
 *
 *	Note: This library cannot be used without a license from
 *	      Stac Electronics.
 *
 * 	$Id: mppc.h,v 1.1 97/11/20 18:21:52 jwu Exp $
 *
 ***********************************************************************/
#ifndef _MPPC_H_
#define _MPPC_H_

#ifdef __HIGHC__
/*
 * for HighC, geos.h sets CALLEE_POPS_STACK, but uses C naming conventions
 */
#define CALLCONV
#endif
#ifdef __BORLANDC__
/*
 * for BorlandC, we don't have CALLEE_POPS_STACK, so we use full C
 * calling convention, so we need this to have calling C code (which may
 * be existing assembly code, or existing CALLEE_POPS_STACK C code) handle
 * parameters correctly
 */
#define CALLCONV _cdecl
#endif

/*----------------------------------------------------------------------*/
/* MPPC.H                                                               */
/*    Header file to include with user's software                       */
/*----------------------------------------------------------------------*/
/* Stac (R), LZS (R)                                                    */
/* (c) 1996, Stac, Inc.                                                 */
/* (c) 1994-1996 Microsoft Corporation                                  */
/* Includes one or more U.S. Patents:                                   */
/*    No. 4701745, 5016009, 5126739, 5146221, and 5414425.              */
/*    Other patents pending                                             */
/*----------------------------------------------------------------------*/
/* Engineering Sequence Number                                          */
/*    4003                                                              */
/*----------------------------------------------------------------------*/


#include <geos.h>



/*----------------------------------------------------------------------*/
/* Symbolic Constants - see data sheet PRS-0045 for details		*/
/*----------------------------------------------------------------------*/
#define MPPC_SOURCE_MAX					8192

/* MPPC_Compress / MPPC_Decompress return values */

#define MPPC_INVALID		0x00
#define MPPC_SOURCE_EXHAUSTED	0x01
#define MPPC_DEST_EXHAUSTED	0x02
#define MPPC_FLUSHED		0x04
#define MPPC_RESTART_HISTORY	0x08	/* Also a decompress flag bit */
#define MPPC_EXPANDED		0x10

/* MPPC_Compress / MPPC_Decompress flag bits */

#define MPPC_SAVE_HISTORY	        0x04	/* Compress only */
#define	MPPC_MANDATORY_COMPRESS_FLAGS	0x01	
            /* Must be set for all compress calls */

#define MPPC_INTERNAL_DECOMPRESS	0x10	/* Decompress only */
            /* Internal decompress is faster because it decompressed
	       the data directly in the decompression history.  If 
	       you are not using the data immediately before anohter
	       MPPC_Decompress call, DO NOT set this flag. */
#define	MPPC_MANDATORY_DECOMPRESS_FLAGS	0x04	
            /* Must be set for all decompress calls*/

/* Constants defined for backwards compatibility with LZS221-C */
#define MPPC_SOURCE_FLUSH		0x01
#define MPPC_DEST_FLUSH			0x02
#define MPPC_UNCOMPRESSED		0x02

#define MPPC_END_MARKER			MPPC_FLUSHED

#define MPPC_DEST_MIN			16U
#define MPPC_MAX_OVERRUN		0

#define MPPC_PERFORMANCE_MODE_0		0x00
#define MPPC_PERFORMANCE_MODE_1		0x00
#define MPPC_PERFORMANCE_MODE_2		0x00

/*----------------------------------------------------------------------*/
/* Function Prototypes							*/
/*----------------------------------------------------------------------*/

/*
 * MPPC_SizeOfCompressionHistory 
 *
 * This function must be called to determine the number of bytes
 * required for one compression history.
 */
extern unsigned short CALLCONV MPPC_SizeOfCompressionHistory(void);


/* 
 * MPPC_InitCompressionHistory
 *
 * This function must be called to initialize a compression history
 * before it can be used with the MPPC_Compress function.  Each 
 * compression history must be initialized separately.  
 * 
 * This function can also be called to reset the compression history.
 * Unlike LZS, it is faster than calling MPPC_Compress with sourceCnt
 * set to 0 and no MPPC_SAVE_HISTORY.
 *
 * The *history parameter is a pointer to the memory allocated for
 * a compression history.
 *
 * The return value is undefined and will always be non-zero.
 */
extern unsigned short CALLCONV MPPC_InitCompressionHistory(void * history);

/*
 * MPPC_Compress
 * 
 * Compress data from the source buffer into the dest buffer.
 * The function will stop when sourceCnt bytes have been read
 * from the source buffer or when destCnt bytes (or slightly less)
 * have been written to the dest buffer.
 * 
 * sourceCnt will decrement and *source will increment for each byte read.
 * destCnt will decrement and *dest will increment for each byte written.
 * 
 * flags: MPPC_SAVE_HISTORY	    
 *
 *	    Also, MPPC_MANDATORY_COMPRESS_FLAGS must be set.
 * 
 * Returns combination of the following flags:
 *	MPPC_SOURCE_EXHAUSTED	    
 *	MPPC_FLUSHED
 *	MPPC_RESTART_HISTORY
 *	MPPC_EXPANDED
 *	MPPC_INVALID
 */
extern unsigned short CALLCONV MPPC_Compress(unsigned char	**source,
				    unsigned char	**dest,
				    unsigned long	*sourceCnt,
				    unsigned long	*destCnt,
				    void		*history,
				    unsigned short	flags,
				    unsigned short	performance);

/*
 * MPPC_SizeOfDecompressionHistory
 *
 * This function must be called to determine the number of bytes
 * required for one decompression history.
 */
extern unsigned short CALLCONV MPPC_SizeOfDecompressionHistory(void);

/*
 * MPPC_InitDecompressionHistory
 *
 * This function must be called to initialize a decompression history
 * before it can be used with the MPPC_Decompress function.  Each
 * decompression history must be initialized separately.  
 *
 * This function can also be called to reset the decompression history.
 *
 * The *history parameter is a pointer to the memory allocated for
 * a decompression history.
 *
 * The return value is undefined and will always be non-zero.
 */
extern unsigned short CALLCONV MPPC_InitDecompressionHistory(void * history);

/*
 * MPPC_Decompress
 *
 * Decompress data from the source buffer into the dest buffer.
 * The function will stop when sourceCnt bytes have been read
 * from the source buffer or when destCnt bytes (or slightly less) 
 * have been written to the dest buffer.
 *
 * sourceCnt will decrement and *source will increment for each byte read.
 * destCnt will decrement and *dest will increment for each byte written.
 * 
 * flags:
 *	    MPPC_RESTART_HISTORY
 *	    MPPC_INTERNAL_DECOMPRESS
 * 
 *	    Also, MPPC_MANDATORY_DECOMPRESS_FLAGS must be set.
 *
 * Returns combination of the following flags:
 *
 *	    MPPC_SOURCE_EXHAUSTED
 *	    MPPC_DEST_EXHAUSTED
 *	    MPPC_FLUSHED
 *		(Note: In this version, all 3 of the above flags are
 *		synonymous.  Separate flags are retained for compatibility
 *	        with other libraries.)
 *	    MPPC_INVALID
 */
extern unsigned short CALLCONV MPPC_Decompress(unsigned char	**source,
				      unsigned char	**dest,
				      unsigned long	*sourceCnt,
				      unsigned long	*destCnt,
				      void		*history,
				      unsigned short	flags);

#endif /* _MPPC_H_ */

