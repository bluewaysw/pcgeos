/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Expandable Buffers
 * FILE:	  buf.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *      Buf_Init    	    Initialize an expandable buffer
 *      Buf_Destroy 	    Nuke an expandable buffer
 *      Buf_AddB 	    Add a single byte to a buffer
 *      Buf_AddBs	    Add multiple bytes to a buffer
 *      Buf_GetB 	    Remove a byte from the front of a buffer
 *      Buf_GetBs	    Remove bytes from the front of a buffer
 *      Buf_UngetB	    Place a byte back at the front
 *      Buf_UngetBs	    Place bytes back at the front
 *      Buf_GetAll  	    Fetch all the bytes in a buffer
 *      Buf_Discard 	    Throw away bytes from the front of a buffer
 *      Buf_Size    	    Return the number of bytes in a buffer
 *      Buf_DelBs	    Nuke bytes from the end of a buffer
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to handle automatically-expanded buffers.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: buf.c,v 4.2 92/07/26 16:42:12 adam Exp $";
#endif lint


#include <config.h>
#include <compat/stdlib.h>
#include <compat/string.h>

#include "goc.h"
#include "buf.h"
#include "malloc.h"

typedef struct {
    int	    size; 	/* Current size of the buffer */
    B    *buffer;	/* The buffer itself */
    B    *inPtr;	/* Place to write to */
    B    *outPtr;	/* Place to read from */
} Buf, *BufPtr;

#ifndef max
#define max(a,b)  ((a) > (b) ? (a) : (b))
#endif

/*
 * BufExpand --
 * 	Expand the given buffer to hold the given number of additional
 *	bytes.
 *	Makes sure there's room for an extra NULL byte at the end of the
 *	buffer in case it holds a string.
 */
#define BufExpand(bp,nb) \
 	if (((bp)->size - ((bp)->inPtr - (bp)->buffer)) < (nb)+1) {\
	    int newSize = (bp)->size + max((nb)+1,BUF_ADD_INC); \
	    B  *newBuf = (B *) realloc((char *)(bp)->buffer, \
						    newSize); \
	    \
	    (bp)->inPtr = newBuf + ((bp)->inPtr - (bp)->buffer); \
	    (bp)->outPtr = newBuf + ((bp)->outPtr - (bp)->buffer);\
	    (bp)->buffer = newBuf;\
	    (bp)->size = newSize;\
	}

#define BUF_DEF_SIZE	256 	/* Default buffer size */
#define BUF_ADD_INC	256 	/* Expansion increment when Adding */
#define BUF_UNGET_INC	16  	/* Expansion increment when Ungetting */

/*-
 *-----------------------------------------------------------------------
 * Buf_AddB --
 *	Add a single byte to the buffer.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The buffer may be expanded.
 *
 *-----------------------------------------------------------------------
 */
void
Buf_AddB (Buffer buf,
	     B   b)
{
    register BufPtr  bp = (BufPtr) buf;

    BufExpand (bp, 1);

    *bp->inPtr = b;
    bp->inPtr += 1;

    /*
     * Null-terminate
     */
    *bp->inPtr = 0;
}

/*-
 *-----------------------------------------------------------------------
 * Buf_AddBs --
 *	Add a number of bytes to the buffer.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Guess what?
 *
 *-----------------------------------------------------------------------
 */
void
Buf_AddBs (Buffer	buf,
	   int	        numBs,
	   B	       *bytesPtr)
{
    register BufPtr  bp = (BufPtr) buf;

    BufExpand (bp, numBs);

    bcopy (bytesPtr, bp->inPtr, numBs);
    bp->inPtr += numBs;

    /*
     * Null-terminate
     */
    *bp->inPtr = 0;
}
#if 0

/*-
 *-----------------------------------------------------------------------
 * Buf_UngetB --
 *	Place the byte back at the beginning of the buffer.
 *
 * Results:
 *	SUCCESS if the byte was added ok. FAILURE if not.
 *
 * Side Effects:
 *	The byte is stuffed in the buffer and outPtr is decremented.
 *
 *-----------------------------------------------------------------------
 */
void
Buf_UngetB (Buffer	buf,
	       B	b)
{
    register BufPtr	bp = (BufPtr) buf;

    if (bp->outPtr != bp->buffer) {
	bp->outPtr -= 1;
	*bp->outPtr = b;
    } else if (bp->outPtr == bp->inPtr) {
	*bp->inPtr = b;
	bp->inPtr += 1;
	*bp->inPtr = 0;
    } else {
	/*
	 * Yech. have to expand the buffer to stuff this thing in.
	 * We use a different expansion constant because people don't
	 * usually push back many bytes when they're doing it a byte at
	 * a time...
	 */
	int 	  numBs = bp->inPtr - bp->outPtr;
	B	  *newBuf;

	newBuf = (B *) malloc (bp->size + BUF_UNGET_INC);
	bcopy ((Address)bp->outPtr,
			(Address)(newBuf+BUF_UNGET_INC), numBs+1);
	bp->outPtr = newBuf + BUF_UNGET_INC;
	bp->inPtr = bp->outPtr + numBs;
	free ((Address)bp->buffer);
	bp->buffer = newBuf;
	bp->size += BUF_UNGET_INC;
	bp->outPtr -= 1;
	*bp->outPtr = b;
    }
}

/*-
 *-----------------------------------------------------------------------
 * Buf_UngetBs --
 *	Push back a series of bytes at the beginning of the buffer.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	outPtr is decremented and the bytes copied into the buffer.
 *
 *-----------------------------------------------------------------------
 */
void
Buf_UngetBs (Buffer	buf,
		int	numBs,
		B	*bytesPtr)
{
    register BufPtr	bp = (BufPtr) buf;

    if (bp->outPtr - bp->buffer >= numBs) {
	bp->outPtr -= numBs;
	bcopy (bytesPtr, bp->outPtr, numBs);
    } else if (bp->outPtr == bp->inPtr) {
	Buf_AddBs (buf, numBs, bytesPtr);
    } else {
	int 	  curNumBs = bp->inPtr - bp->outPtr;
	B	  *newBuf;
	int 	  newBs = max(numBs,BUF_UNGET_INC);

	newBuf = (B *) malloc (bp->size + newBs);
	bcopy((Address)bp->outPtr, (Address)(newBuf+newBs), curNumBs+1);
	bp->outPtr = newBuf + newBs;
	bp->inPtr = bp->outPtr + curNumBs;
	free ((Address)bp->buffer);
	bp->buffer = newBuf;
	bp->size += newBs;
	bp->outPtr -= numBs;
	bcopy ((Address)bytesPtr, (Address)bp->outPtr, numBs);
    }
}
#endif /* 0 */

/*-
 *-----------------------------------------------------------------------
 * Buf_GetB --
 *	Return the next byte from the buffer. Actually returns an integer.
 *
 * Results:
 *	Returns BUF_ERROR if there's no byte in the buffer, or the byte
 *	itself if there is one.
 *
 * Side Effects:
 *	outPtr is incremented and both outPtr and inPtr will be reset if
 *	the buffer is emptied.
 *
 *-----------------------------------------------------------------------
 */
int
Buf_GetB (Buffer buf)
{
    BufPtr  bp = (BufPtr) buf;
    int	    res;

    if (bp->inPtr == bp->outPtr) {
	return (BUF_ERROR);
    } else {
	res = (int) *bp->outPtr;
	bp->outPtr += 1;
	if (bp->outPtr == bp->inPtr) {
	    bp->outPtr = bp->inPtr = bp->buffer;
	    *bp->inPtr = 0;
	}
	return (res);
    }
}
#if 0

/*-
 *-----------------------------------------------------------------------
 * Buf_GetBs --
 *	Extract a number of bytes from the buffer.
 *
 * Results:
 *	The number of bytes gotten.
 *
 * Side Effects:
 *	The passed array is overwritten.
 *
 *-----------------------------------------------------------------------
 */
int
Buf_GetBs (Buffer	buf,
	      int	numBs,
	      B	*bytesPtr)
{
    BufPtr  bp = (BufPtr) buf;
    
    if (bp->inPtr - bp->outPtr < numBs) {
	numBs = bp->inPtr - bp->outPtr;
    }
    bcopy (bp->outPtr, bytesPtr, numBs);
    bp->outPtr += numBs;

    if (bp->outPtr == bp->inPtr) {
	bp->outPtr = bp->inPtr = bp->buffer;
	*bp->inPtr = 0;
    }
    return (numBs);
}
#endif /* 0 */

/*-
 *-----------------------------------------------------------------------
 * Buf_DelBs --
 *	Nukes bytes from the end of the buffer.
 *
 * Results:
 *	Nothing
 *
 * Side Effects:
 *	inPtr is backed up.
 *
 *-----------------------------------------------------------------------
 */
void
Buf_DelBs(Buffer 	buf,
	     int    	numBs)
{
    BufPtr  bp = (BufPtr)buf;

    bp->inPtr -= numBs;
    if (bp->inPtr <= bp->outPtr) {
	bp->inPtr = bp->outPtr = bp->buffer;
    }
    *bp->inPtr = 0;
}

/*-
 *-----------------------------------------------------------------------
 * Buf_GetAll --
 *	Get all the available data at once.
 *
 * Results:
 *	A pointer to the data and the number of bytes available.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
B *
Buf_GetAll (Buffer  buf,
	    int	    *numBsPtr)
{
    BufPtr  bp = (BufPtr)buf;

    if (numBsPtr != (int *)NULL) {
	*numBsPtr = bp->inPtr - bp->outPtr;
    }
    
    return (bp->outPtr);
}

/*-
 *-----------------------------------------------------------------------
 * Buf_Discard --
 *	Throw away bytes in a buffer.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The bytes are discarded. 
 *
 *-----------------------------------------------------------------------
 */
void
Buf_Discard (Buffer buf,
	     int    numBs)
{
    register BufPtr	bp = (BufPtr) buf;

    if (bp->inPtr - bp->outPtr <= numBs) {
	bp->inPtr = bp->outPtr = bp->buffer;
	*bp->inPtr = 0;
    } else {
	bp->outPtr += numBs;
    }
}

/*-
 *-----------------------------------------------------------------------
 * Buf_Size --
 *	Returns the number of bytes in the given buffer. Doesn't include
 *	the null-terminating byte.
 *
 * Results:
 *	The number of bytes.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Buf_Size (Buffer    buf)
{
    return (((BufPtr)buf)->inPtr - ((BufPtr)buf)->outPtr);
}

/*-
 *-----------------------------------------------------------------------
 * Buf_Init --
 *	Initialize a buffer. If no initial size is given, a reasonable
 *	default is used.
 *
 * Results:
 *	A buffer to be given to other functions in this library.
 *
 * Side Effects:
 *	The buffer is created, the space allocated and pointers
 *	initialized.
 *
 *-----------------------------------------------------------------------
 */
Buffer
Buf_Init (int	size)	/* Initial size for the buffer */
{
    BufPtr  bp;	  	/* New Buffer */

    bp = (Buf *) malloc(sizeof(Buf));

    if (size <= 0) {
	size = BUF_DEF_SIZE;
    }
    bp->size = size;
    bp->buffer = (B *) malloc (size);
    bp->inPtr = bp->outPtr = bp->buffer;
    *bp->inPtr = 0;

    return ((Buffer) bp);
}

/*-
 *-----------------------------------------------------------------------
 * Buf_Destroy --
 *	Nuke a buffer and all its resources.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The buffer is freed.
 *
 *-----------------------------------------------------------------------
 */
void
Buf_Destroy (Buffer	buf,	    /* Buffer to destroy */
	     Boolean	freeData)   /* TRUE if the data should be destroyed as
				     * well */
{
    BufPtr  bp = (BufPtr) buf;
    
    if (freeData) {
	free ((Address)bp->buffer);
    }
    free ((Address)bp);
}
