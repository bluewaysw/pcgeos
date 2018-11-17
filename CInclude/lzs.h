/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  data compression
 * MODULE:	  Stac LZS Library
 * FILE:	  lzs.h
 *
 * AUTHOR:  	  Jennifer Wu: Aug 27, 1996
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/27/96	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	API and definitions for Stac LZS data compression library.  
 *	LZS221-C Version 4 Release 2
 *
 *	Note: This library cannot be used without a license from
 *	      Stac Electronics.
 *
 * 	$Id: lzs.h,v 1.1 97/04/04 15:59:50 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _LZS_H_
#define _LZS_H_

/*----------------------------------------------------------------------

   Data Compression Software - a STAC(R) LZS(TM) algorithm		

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!	
  !!                                                              !!	
  !!  NOTE:                                                       !!
  !!  The contents of this document constitute                    !!
  !!           CONFIDENTIAL INFORMATION                           !!
  !!  		(C) Stac Electronics 1995.		    	  !!	
  !!						  		  !!
  !!      Including one or more U.S. Patents:			  !!	
  !!		No. 4701745, 5016009, 5126739 and 5146221 and	  !!
  !!                  other pending patents.              	  !!  
  !!                                                              !!	
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

					
   Copyright 1988-95 Stac Electronics, Carlsbad, California.		
   All rights reserved.  This code is Stac confidential property, and	
   the algorithms and methods used herein may not be disclosed to any	
   party without express written consent from Stac Electronics.		
 									
   All Stac product names are trademarks or registered trademarks	
   of Stac Electronics.						

-----------------------------------------------------------------------*/

#include <geos.h>

/*----------------------------------------------------------------------
 	    	     Symbolic Constants 
----------------------------------------------------------------------*/

/*
 * If defined, when there are bytes left over in either the source 
 * or destination buffer, the buffer pointers and sizes will be 
 * returned updated.  By default, these values are returned unchanged
 * and the compression engine stores the information in the history.
 */
/* #define _SAVE_COMPRESS_POINTERS */

/*
 * A flush operation will force any intermediate data out to 
 * the destination buffer, appending an end marker to the 
 * destination buffer.
 *
 * If both these flags are set, then when either source or 
 * destinatino buffers exhaust, a flush operation will occur.
 *
 * The value of the flush bits cannot be changed between successive
 * LZS_Compress function calls until the corresponding buffer is 
 * exhausted.
 */
#define LZS_SOURCE_FLUSH 	1  /* flush after reading all the source */
#define LZS_DEST_FLUSH 		2  /* flush when destination buffer fills */

/*
 * Save compression history at the end of a flush operation.
 * This will allow for a higher compression ratio for the next block 
 * to be compressed.
 *
 * Blocks must be decompressed in the same order they were compressed
 * if history is preserved between blocks.
 */
#define LZS_SAVE_HISTORY 	4  

/*
 * Performance modes. Smaller values force faster execution.
 */
#define LZS_PERFORMANCE_MODE_0 	0
#define LZS_PERFORMANCE_MODE_1 	8
#define LZS_PERFORMANCE_MODE_2 	16


/*
 * Parameter for LZS_Decompress.  If set, the source data is treated
 * as if it were uncompressed data.  The decompression history will 
 * be updated to reflect this data.  The data in the source buffer
 * will be moved into the destination buffer. 
 */
#define LZS_UNCOMPRESSED    	2

/*
 * Result codes.
 */
#define LZS_INVALID 		0
#define LZS_SOURCE_EXHAUSTED	1   	/* all data read from source buffer */
#define LZS_DEST_EXHAUSTED	2   	/* destination buffer filled */
#define LZS_FLUSHED 		4   	

#define LZS_END_MARKER 		4   	/* end marker detected */

/*
 * Minimum size for destination buffer.
 */
#define LZS_DEST_MIN 		16U

/*
 * Maximum amount of extra space needed at the end of source buffers
 * when LZS_FAST is defined. 
 */
#define LZS_MAX_OVERRUN 	16U


/*
 * Endian
 */
#define LZS_LITTLE_END			1
#define LZS_BIG_END			2

/*----------------------------------------------------------------------
  	    	     Compile time options
 
  LZS_FAR
 	This constant must always be defined.  It defaults to a blank.
 	Add your definition to the end of the line, if required.
 
 	Ex: #define LZS_FAR __far

----------------------------------------------------------------------*/
#if !defined (LZS_FAR)
#define LZS_FAR
#endif

#ifdef __BORLANDC__
#define CALLCONV _pascal
#endif
#ifdef __HIGHC__
#define CALLCONV
#endif

/*---------------------------------------------------------------------
  LZS_SMALL_BUFFERS
 	If desired, add the definitions after the #if statement.

	Defining this constant produces a version that requires
	that the source and destination buffer sizes be less than
	or equal to 64K bytes.  If used, this will produce slightly
	faster code.

	The sourceCnt and destCnt parameters will remain defined as
	"long", but only the lower 16-bits will be used.  
----------------------------------------------------------------------*/
#if !defined (LZS_SMALL_BUFFERS)
#define LZS_SMALL_BUFFERS
#endif


/*----------------------------------------------------------------------
  LZS_FAST
 	If desired, add the definition after the #if statement.
	
	Defining this constant will produce a version of the library
	that operates more quickly than normal at the expense of the
	compression ratio.  Less memory is also required for each 
	compression and decompression history.  

	There are several restrictions that must be followed if this 
	mode is enabled.  In summary, the restrictions include:
	    * sourceCnt parameter must be less than or equal to 56K
	    * destination buffer must be large enough to hold all
	      the data produced
	    * cannot keep history
	    * cannot perform destination flush
	    * must always perform source flush

	The default is that LZS_FAST is not defined.

----------------------------------------------------------------------*/
#if !defined (LZS_FAST)
#endif


/*----------------------------------------------------------------------
  LZS_BYTE_ORDER
  	This constant must always be defined.  It defaults to 
 	LZS_LITTLE_ENDIAN.  Change this to LZS_BIG_ENDIAN if required.
----------------------------------------------------------------------*/
#if !defined (LZS_BYTE_ORDER)
#define LZS_BYTE_ORDER LZS_LITTLE_END
#endif


/*----------------------------------------------------------------------
 LZS_ALIGNED			
	If desired, add the definition after the #if statement.	   

	Defining this constant will produce a version of the library
	that defines type aligned memory access.  Performance may
	slow slightly.

	The default is that LZS_ALIGNED is not defined.
----------------------------------------------------------------------*/
#if !defined (LZS_ALIGNED)
#endif

/*----------------------------------------------------------------------
  	    	    	    User API 
----------------------------------------------------------------------*/

/*
 * LZS_SizeOfCompressionHistory
 *
 * This function must be called to determine the number of bytes
 * required for one compression history.  
 */
extern unsigned short CALLCONV LZS_FAR LZS_SizeOfCompressionHistory(void);

/*
 * LZS_InitCompressionHistory
 *
 * This function must be called to initialize a comprssion history
 * before it can be used with the LZS_Compress function.  Each 
 * compression history must be initialized  separately.  Each 
 * history is typically only initialized once, although a compression
 * history may be initialized at any time if desired.
 *
 * The *history parameter is a pointer to the memory allocated for a 
 * compression history. 
 * 
 * The return value is undefined and will always be non-zero.
 */
extern unsigned short CALLCONV LZS_FAR LZS_InitCompressionHistory(void LZS_FAR * history);

/*
 * LZS_Compress
 *
 * This function will compress data from the source buffer into the 
 * dest buffer.  The function will stop when sourceCnt bytes have been
 * read from the source buffer or when destCnt buytes (or slightly less)
 * have been written to the dest buffer.  
 *
 * sourceCnt will decrement and *source will increment for each byte read.
 * destCnt will decrement and *dest will increment for each byte written.
 * 
 * If the source buffer does not exhaust, the *source pointer and sourceCnt
 * counter values will be returned unchanged.  The source buffer is still
 * in use by the compression engine, and the original allocated source buffer
 * should be used in the next LZS_Compress call.  The actual pointer and
 * counter values are stored in the compression history area, and the value
 * of the *source and sourceCnt calling parameters for the next function call
 * are a "don't care".  The same thing applies to *dest and destCnt when the 
 * destination buffer does not exhaust.
 * 
 * LZS_Compress may be used to reset the compression history faster than
 * LZS_InitCompressionHistory.  Pass sourceCnt of 0, LZS_SOURCE_FLUSH with
 * the LZS_SAVE_HISTORY bit clear.  Use LZS_InitCompressionHistory if the
 * previous LZS_Compress call did not exhaust the source buffer and you
 * want to terminate the compression prematurely.
 *
 * flags:
 *	    LZS_SOURCE_FLUSH
 *	    LZS_DEST_FLUSH
 *	    	(destCnt may not reach zero when LZS_Compress returns
 *    	    	due to the unknown amount of extra bytes that the 
 *	    	compression engine needs to output during the flush 
 *    	    	operation)
 * 	    LZS_SAVE_HISTORY 
 *	    LZS_PERFORMANCE_MODE_0/1/2  (only one at a time)
 *
 * performance: 0 - 255
 *	    	Smaller values for the performance parameter
 * 	    	will force faster execution.  Faster speeds result in lower 
 * 	    	compression ratios.    
 *
 * Returns a record with following bits possibly set:
 *	    LZS_INVALID if destCnt is less than LZS_DEST_MIN
 *	    	    	or if sourceCnt or destCnt exceeds 65535 when
 *	    	    	LZS_SMALL_BUFFERS is defined
 *	    LZS_SOURCE_EXHAUSTED 
 *	    LZS_DEST_EXHAUSTED 
 *	    LZS_FLUSHED
 */
extern unsigned short CALLCONV LZS_FAR LZS_Compress(
	unsigned char LZS_FAR * LZS_FAR *source,    /* ptr to source buffer */
	unsigned char LZS_FAR * LZS_FAR *dest,	    /* ptr to dest buffer */
	unsigned long LZS_FAR           *sourceCnt, /* ptr to source size */
	unsigned long LZS_FAR           *destCnt,   /* ptr to dest buffer size */
	void 	      LZS_FAR           *history,   /* ptr to comp. history */
	unsigned short                   flags,	    
	unsigned short                   performance 
);


/*
 * LZS_SizeOfDecompressionHistory
 * 
 * This function must be called to determine the number of bytes
 * required for one decompression history.
 */
extern unsigned short CALLCONV LZS_FAR LZS_SizeOfDecompressionHistory(void);

/*
 * LZS_InitDecompressionHistory
 * 
 * This function must be called to initialize a decompression history
 * before it can be used with the LZS_Decompress function.  Each 
 * decompression history must be initialized separately.  Each 
 * history is typically only initialized once, although a
 * decompression history may be initialized at any time if desired.
 *
 * The *history parameter is a pointer to the memory allocated for a 
 * compression history.
 * 
 * The return value is undefined and will always be non-zero.
 */
extern unsigned short CALLCONV LZS_FAR LZS_InitDecompressionHistory(void LZS_FAR * history);

/*
 * LZS_Decompress
 *
 * This function decompresses data from the source buffer into the
 * dest buffer.  The function will stop when sourceCnt bytes have been
 * read from the source buffer or when destCnt bytes (or slightly
 * less) have been written to the dest buffer.
 * 
 * sourceCnt will decrement and *source will increment for each byte read.
 * destCnt will decrement and *dest will increment for each byte written.
 * 
 * If LZS_END_MARKER is returned, all counters and pointers will be updated.
 * *source and *dest pointers will point to the next bytes to be processed,
 * sourceCnt will indicate the number of bytes remaining in the source 
 * buffer to be processed, destCnt will indicate the number of unused bytes
 * in the destination buffer.
 * 
 * If the source buffer exhausts, *dest and destCnt values will be returned
 * unchanged. The destination buffer is still in use by the decompression
 * engine, and the original allocated destination buffer should be used
 * in the next LZS_Decompress call.  The *dest and destCnt parameters 
 * for the next call will be "don't care".  The same thing applies to 
 * *source and sourceCnt when the destination buffer exhausts.
 * 
 * If it is desired to terminate process a block of data prior to the 
 * end of the data block, simply call LZS_InitDecompressionHistory.
 *
 * flags:
 *	    LZS_SAVE_HISTORY
 * 	    LZS_UNCOMPRESSED
 *
 * Returns a record with following bits possibly set:
 *	    LZS_INVALID
 *	    LZS_SOURCE_EXHAUSTED 
 *	    LZS_DEST_EXHAUSTED 
 *	    LZS_END_MARKER
 */
extern unsigned short CALLCONV LZS_FAR LZS_Decompress(
	unsigned char LZS_FAR * LZS_FAR *source,
	unsigned char LZS_FAR * LZS_FAR *dest,
	unsigned long LZS_FAR           *sourceCnt,
	unsigned long LZS_FAR           *destCnt,
	void 	      LZS_FAR           *history,
	unsigned short                   flags
);

#endif /* _LZS_H_ */
