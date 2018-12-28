/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		lzw.c

AUTHOR:		Maryann Simmons, Jun 10, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/10/92   	Initial version.

DESCRIPTION:
	

	$Id: lzw.c,v 1.1 97/04/07 11:27:42 newdeal Exp $
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*

   LZW DEcompression routines

*/
#ifndef __WATCOMC__
#pragma Comment("@" __FILE__);
#endif

#include "hsimem.h"
#include "hsierror.h"

#include <Ansi/stdio.h>
#include <Ansi/stdlib.h>


#include "lzw.h"


WORD
CalcMask (WORD BitDepth)
   {
   register WORD    Mask;

   Mask = ~0;
   Mask <<= BitDepth;    /* shift in low-order zeros */
   Mask = ~Mask;

   return Mask;
   }

/*
   LzwExpandCodes

Desription

  Expand the codes in the chunk to 16 bits per code,
  low-order-justified,
  so that I don't have to make a function call every
  time I want to get the next code.

  there must be an EOI code at the end of the chunk, or this routine
  will get stuck in an infinite loop.

  assumes that data has been stored "as bytes", but we will
  access a word at a time, so the caller
  must be careful to pass even addresses to this routine.
  this routine swaps bytes if executing
  on an Intel-type machine.

*/

int
LzwExpandCodes (
   LPSTR    lpCmChunk,          // the input non-expanded codes
   DWORD    dwChunkByteCount,   // number of bytes in hCmChunk
   WORD     *pNumCodes,         // OUT: number of codes, including the EOI
   LPSTR    lpExpCodes )        // where to put the expanded codes
   {
   HSI_ERROR_CODE        err = SUCCESS;
   WORD    ChunkByteCount = (WORD)dwChunkByteCount;
   WORD    bcnt=0;
   WORD    BitsLeft = 16;
   register WORD    diff;
   register WORD    Code;
   register WORD    Mask;
   WORD    ComprSize;
   WORD    NextOne;
   WORD    NextBoundary;
   LPWORD    lpCmChunkPtr;
   LPWORD    lpExpCodesPtr;

   extern void _lswab (LPSTR,LPSTR,WORD);

   lpCmChunkPtr = (LPWORD)lpCmChunk;
   lpExpCodesPtr= (LPWORD)lpExpCodes;

   if (ODD(ChunkByteCount))
        ChunkByteCount++;

#ifdef INTEL
   /*
   ** Swap the byte within each WORD now, so that when we get the
   ** word from the content of a word pointer will work properly.
   */
   _lswab ((LPSTR)lpCmChunk, (LPSTR)lpCmChunk, (WORD)ChunkByteCount);
#endif

   // so that we know when we are about to cross over a bit boundary.
   // used similarly to "Empty" in compression routines

   NextOne = EOICODE + 1;

   ComprSize = CHARBITS + 1;
   NextBoundary = 1 << ComprSize;
   Mask = CalcMask(ComprSize);

   do {
        // There should be a better apprach to get the next code!!!

        if ( BitsLeft > ComprSize )
            {
            BitsLeft -= ComprSize;   // set and stay in same word
            Code = (*lpCmChunkPtr >> BitsLeft) & Mask;
            }
        else
        if (BitsLeft < ComprSize)
            {
            /* Code is across a word boundary */
            diff = ComprSize - BitsLeft;
            Code = (*lpCmChunkPtr++ << diff) & Mask;
            bcnt+=2;

            if (bcnt == ChunkByteCount)
               break;

            if (bcnt > ChunkByteCount)
               { err=HSI_EC_INVALIDLZW; goto cu0; }

            BitsLeft = 16 - diff;
            Code |= (*lpCmChunkPtr >> BitsLeft);
            }
        else
            {    /* equal */
            /* set and move on to the next word */
            Code = *lpCmChunkPtr++ & Mask;
            bcnt+=2;

            if (bcnt == ChunkByteCount)    /* do not treat this as error */
               break;                      /* just exit current loop     */

            if (bcnt > ChunkByteCount)
               { err=HSI_EC_INVALIDLZW; goto cu0; }

            BitsLeft = 16;
            }

        *lpExpCodesPtr++ = Code;   // store the result

        if (Code == CLEARCODE)        // check for CLEAR code
            {
            NextOne = EOICODE + 1;
            ComprSize = CHARBITS + 1;
            NextBoundary = 1 << ComprSize;
            Mask = CalcMask(ComprSize);
            }
        else // if at bit boundary, adjust compression size
        if (++NextOne == NextBoundary)
            {
            ComprSize++;

            if (ComprSize > MAXCODEWIDTH)
                {
                err = HSI_EC_INVALIDFILE;
                goto cu0;
                }

            NextBoundary <<= 1;
            Mask = CalcMask(ComprSize);
            }
        }
   while (Code != EOICODE && bcnt < ChunkByteCount );

   // store output information (caution: word arithmetic)

   *pNumCodes = (WORD)((LPSTR)lpExpCodesPtr - (LPSTR)lpExpCodes);

   cu0:

   return err;
   }




/*
   Decompress an entire chunk

   assumptions:

     1. the input codes have already been expanded to 16-bit codes.
     2. the first code in a chunk is CLEAR.
*/

int
LzwDecodeChunk(
   LPWORD     lpExpCodes,     /* input expanded codes */
   DCLPTREENODE lpTab,          /* the LZW table */
/*   WORD       NumCodes,        number of codes */
   LPSTR      lpUnChunk,      /* output uncompressed bytes */
   DWORD      dwOutExpected)  /* number of bytes expected in output */
   {
   HSI_ERROR_CODE                    err = SUCCESS;
   LPBYTE     lpOutPtr=NULL;
   register WORD        Code;
   register WORD        Old;
   register WORD        StringToWrite;
   register WORD        Empty;
   register BYTE        FirstChar;
   register BYTE        OutStringLength;
   DWORD                dwOutSoFar = 0L;

   /* if the first code is not a clear code, give up */

   if (*lpExpCodes != CLEARCODE)
        {
        err = HSI_EC_INVALIDFILE;
        goto cu0;
        }

   // get the next code, while there are codes to be gotten...

   while ((Code = *lpExpCodes++) != EOICODE)
        {

        // if 'Clear'...

        if (Code == CLEARCODE)
            {
            // do the clear

            Empty = EOICODE + 1;

            /* get the next code, to prime the pump.
            * output the code to the charstream,
            * i.e., the (expanded-pixel) output buffer.
            * (we assume code = char for roots, which is true for our data).
            * initialize "old-code": <old> = <code>
            *
            * make sure we don't get mixed up by a multiple-
            * ClearCode situation, which shouldn't ever happen,
            * but why take the chance...
            */

            while ((Code = *lpExpCodes++) == CLEARCODE)
                {
                ;
                }

            if (Code == EOICODE)      // Code = *lpExpCodes++;
                break;

            *lpUnChunk++ = (BYTE)Code;
            dwOutSoFar++;

            Old = Code;
            FirstChar = (BYTE)Code;

            // continue to the very bottom of the loop

            continue;

        } /* end of clear-handler */

   else    // otherwise, we have a normal code, so...
        {

        /* TODO MAYBE: add a special case for roots? */

        /* if <code> exists in the string table...
        *
        * described this way in the LZW paper:
        *
        * "output the string for <code> to the charstream"
        * "add the correct entry to our table"
        *        "get string [...] corresponding to <old>"
        *        "get first character K of string corresponding to <code>"
        *        "add [...]K to the string table"
        * "<old> = <code>"
        *
        * we do it a little differently...
        */

        if (Code < Empty)
            {
            StringToWrite = Code;

           // Old to Code, 5-5, 3pm
            OutStringLength = ((DCTREENODE *)(lpTab + Code))->StringLength;

           dwOutSoFar += (DWORD)OutStringLength;

            if (dwOutSoFar > dwOutExpected)     // we have to check here, since
                {                               // the lpUnChunk might overflow
//               err = HSI_EC_INVALIDFILE;
                goto cu0;
                }

            lpUnChunk += OutStringLength;
            lpOutPtr = (LPBYTE)lpUnChunk;

            }

        /* else if <code> does not exist in the string table...
        *
        * described this way in the paper:
        *
        * "get string [...] corresponding to <old>"
        * "get K, the first character of [...]"
        * "output [...]K to the charstream"
        * "add it to the string table"
        * "<old> = <code>"
        *
        * we do it a little differently, but with the same effect:
        */
        else
        if (Code == Empty)
            {
            StringToWrite = Old;
            OutStringLength = ((DCTREENODE *)(lpTab + Old))->StringLength + 1;

           dwOutSoFar += (DWORD)OutStringLength;

            if (dwOutSoFar > dwOutExpected)     // we have to check here, since
                {                               // the lpUnChunk might overflow
//               err = HSI_EC_INVALIDFILE;
                goto cu0;
                }

            lpUnChunk += OutStringLength;
            lpOutPtr = (LPBYTE)lpUnChunk;

            *--lpOutPtr = FirstChar;
            }
        else
            {
//            err = HSI_EC_INVALIDFILE;
            goto cu0;
            }

        /* write out the rest of the string, by walking up the tree     */
        {
        register DCLPTREENODE    lpNode;
        register WORD        TabIndex = StringToWrite;
        register LPBYTE        lpOutPtr2;

        lpOutPtr2 = lpOutPtr;

        do {
            lpNode = lpTab + TabIndex;
            *--lpOutPtr = ((DCTREENODE *)lpNode)->Suffix;
            TabIndex = ((DCTREENODE *)lpNode)->Parent;
            } while (TabIndex != MAXWORD);

        lpOutPtr = lpOutPtr2;

        // keep the first char around, so that when we need
        // the first char of <old>, it will be available

        FirstChar = ((DCTREENODE *)lpNode)->Suffix;
        }

        /* add the correct entry to our table */
        {
        register DCLPTREENODE    lpNode;

        lpNode = lpTab + Empty++;        /* our new table entry */
        ((DCTREENODE *)lpNode)->Suffix = FirstChar;
        ((DCTREENODE *)lpNode)->StringLength =( ((DCTREENODE *)(lpTab + Old))->StringLength + 1);
        ((DCTREENODE *)lpNode)->Parent = Old;  /* parent is always Old */

        } /* end of entry-adding */

        /* <old> = <code> */
        Old = Code;

        /* check for overflow */

        if (dwOutSoFar > dwOutExpected)     // overflow of this chunk, the
            {                               // file is incorrect.
//            err = HSI_EC_INVALIDFILE;       // should be warning only??
            goto cu0;
            }

        if (Empty >= MAXTABENTRIES)
            {
//            err = HSI_EC_INVALIDFILE;
            goto cu0;
            }

        } /* end of normal-code section */

   } /* end of main code loop */

   /* store local things back     */

   cu0:

   return err;
   }


/*
   Lzw Decompression "OPEN" routine: allocate buffers, do some
   preliminary calculations, and so on, so that we don't have to
   do it for every chunk
 */
int

LzwDeOpen(DWORD dwMaxOutBytes, DCLPTREENODE FAR *lpTreeNode, 
	  LPSTR FAR *lpCodesBuf)
   // maximum output (i.e. uncompressed )
   // bytes per chunk
   // OUT: table allocated by this routine
   // OUT: place to put the expanded codes
   {
   short      err=0;
   DWORD      tbytes = sizeof(DCTREENODE) * MAXTABENTRIES;
   DCLPTREENODE lpNode;
   register WORD    nRoots = 1<<CHARBITS;
   register WORD    ii;

   // allocate and initialize the string table

   *lpTreeNode = (DCLPTREENODE)_fmalloc(tbytes);

   if (!*lpTreeNode)
        {
        err = HSI_EC_NOMEMORY;
        goto cu0;
        }

   lpNode = *lpTreeNode;

   /* useful to avoid special case for <old> */

   ((DCTREENODE *)(lpNode + CLEARCODE))->StringLength = 1;

   for (ii = 0;  ii < nRoots; ii++, lpNode++)
        {
        ((DCTREENODE *)lpNode)->Suffix = (BYTE)ii;
        ((DCTREENODE *)lpNode)->StringLength = 1;
        ((DCTREENODE *)lpNode)->Parent = MAXWORD;    
	/* signals the top of the tree */
        }

   /*
    Calculate the maximum string length.  the worst case, of course,
    is when the input string is made up of all the same character.
    if the input buffer is made up of 1 character, the max output string is
    1 character.  if input is 3 characters, the max output string is
    2 characters.  if input is 6 characters, the max output string is 3
    characters.  if input is 10 characters, the max output string is 4
    characters.  so, we can use the old sum of an arithmetic sequence
    formula:  Sum = n*(n+1)/2.  We want n, given s, so using the
    quadratic formula we have n = (-1 + sqrt(1 + 8*Sum)) / 2.
    our "Sum" is the length of the input data, which is the number
    of pixels in a chunk.

    allocate a MaxStringLen-byte buffer to hold a reversed string, which
    is the way we first get it.

    FLASH: don't need it, because I'm not reversing any more.
   */

   /*
     Allocate the expanded-codes buffer.  I need to know how many codes
    I have, and then I need a word for each code.  Now, how do I know
    how many codes I have?  I guess I don't.  I could make people store it
    in the TIFF file, but that's kind of a pain...So what is the worst case?
    The worst case is probably one code per input character.
    (UPDATE: out input characters are always 8-bit bytes, now.)
    Actually, the worst case is infinite, since you could string an infinite
    number of ClearCodes together, but I guess we can safely assume that
    that won't happen.
   */

   *lpCodesBuf = _fmalloc(dwMaxOutBytes * 2);

   if (!*lpCodesBuf)
        {
        err = HSI_EC_NOMEMORY;
        goto cu0;
        }

   cu0:

   if (err)
       {
       if (*lpTreeNode)
           {
            free((LPSTR)*lpTreeNode);
           *lpTreeNode=NULL;
           }
       }

   return err;
   }


/* decompress an entire chunk */

int
LzwDeChunk (
LPSTR    lpGMem,             /* the compressed chunk */
DWORD    dwChunkByteCount,   /* number of bytes in the compressed chunk */
LPSTR    lpCodesBuf,         /* work buffer for the expanded codes */
DCLPTREENODE lpTreeNode,       /* buffer to hold the decompression table */
DWORD    dwOutExpected,      /* number of output (uncompressed) characters (bytes) expected */
LPSTR    lpstr )             /* where to put the uncompressed chunk data */
   {
   short err=0;
   static WORD    nCodes;    /* number of codes, including the EOI */

   /* expand the codes in the chunk to 16 bits per code */

   err = LzwExpandCodes (
                           lpGMem,
                           dwChunkByteCount,
                           &nCodes,
                           lpCodesBuf);
   if( err)
        goto cu0;

   /* Decode the entire chunk */

   err = LzwDecodeChunk ((LPWORD)lpCodesBuf,
                              lpTreeNode,
                        /*      nCodes,*/
                              lpstr,
                              dwOutExpected); 
   if (err )
        goto cu0;

   cu0:

   return err;
   }


/*
   CLOSE:  free up buffers, and so on.
*/

void
LzwDeClose (DCLPTREENODE lpTreeNode, LPSTR lpCodesBuf)
   {

   if (lpTreeNode)
       free((LPSTR)lpTreeNode);

   if (lpCodesBuf)
       free(lpCodesBuf);
   }

