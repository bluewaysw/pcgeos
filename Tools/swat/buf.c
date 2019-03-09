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
 *      Buf_AddByte 	    Add a single byte to the end of a buffer
 *      Buf_AddByteMiddle   Add a single byte to the middle of a buffer
 *      Buf_AddBytes	    Add multiple bytes to the end of a buffer
 *      Buf_GetByte 	    Remove a byte from the front of a buffer
 *      Buf_GetBytes	    Remove bytes from the front of a buffer
 *      Buf_UngetByte	    Place a byte back at the front
 *      Buf_UngetBytes	    Place bytes back at the front
 *      Buf_GetAll  	    Fetch all the bytes in a buffer
 *      Buf_Discard 	    Throw away bytes from the front of a buffer
 *      Buf_Size    	    Return the number of bytes in a buffer
 *      Buf_DelBytes	    Nuke bytes from the end of a buffer
 *      Buf_DelBytesMiddle  Nuke bytes from the middle of a buffer
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
"$Id: buf.c,v 4.4 96/06/13 17:14:37 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "buf.h"

typedef struct {
    int	    size; 	/* Current size of the buffer */
    Byte    *buffer;	/* The buffer itself */
    Byte    *inPtr;	/* Place to write to */
    Byte    *outPtr;	/* Place to read from */
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
	    Byte  *newBuf = (Byte *) realloc_tagged((char *)(bp)->buffer, \
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
 * Buf_AddByte --
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
Buf_AddByte (Buffer buf,
	     Byte   b)
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
 * Buf_AddByteMiddle --
 *	Add a single byte to the middle of the buffer.
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
Buf_AddByteMiddle (Buffer buf,
		   Byte   b,
		   int start)
{
    register int     i;
    register BufPtr  bp = (BufPtr) buf;

    BufExpand (bp, 1);

    /*
     * Make room for the new byte by shifting everything back a byte
     */
    for (i=bp->size - 1; i >= start + 1; i--) {
	bp->buffer[i] = bp->buffer[i-1];
    }

    bp->buffer[start] = b;
    bp->inPtr += 1;

    /*
     * Null-terminate
     */
    *bp->inPtr = 0;
}

/*-
 *-----------------------------------------------------------------------
 * Buf_AddBytes --
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
Buf_AddBytes (Buffer	buf,
	      int	numBytes,
	      Byte	*bytesPtr)
{
    register BufPtr  bp = (BufPtr) buf;

    BufExpand (bp, numBytes);

    bcopy (bytesPtr, bp->inPtr, numBytes);
    bp->inPtr += numBytes;

    /*
     * Null-terminate
     */
    *bp->inPtr = 0;
}

/*-
 *-----------------------------------------------------------------------
 * Buf_AddBytesMiddle --
 *	Add a number of bytes to the middle of a buffer.
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
Buf_AddBytesMiddle (Buffer	buf,
		    int         numBytes,
		    Byte	*bytesPtr,
		    int         start)
{
    register int     i;
    register BufPtr  bp = (BufPtr) buf;

    BufExpand (bp, numBytes);

    /*
     * Make room for the new bytes by shifting everything back numBytes
     */
    for (i=bp->size - 1; i >= start + numBytes; i--) {
	bp->buffer[i] = bp->buffer[i-numBytes];
    }

    bcopy (bytesPtr, bp->buffer + start, numBytes);
    bp->inPtr += numBytes;

    /*
     * Null-terminate
     */
    *bp->inPtr = 0;
}
#if 0

/*-
 *-----------------------------------------------------------------------
 * Buf_UngetByte --
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
Buf_UngetByte (Buffer	buf,
	       Byte	b)
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
	int 	  numBytes = bp->inPtr - bp->outPtr;
	Byte	  *newBuf;

	newBuf = (Byte *) malloc_tagged (bp->size + BUF_UNGET_INC, TAG_BUFFER);
	bcopy ((Address)bp->outPtr,
			(Address)(newBuf+BUF_UNGET_INC), numBytes+1);
	bp->outPtr = newBuf + BUF_UNGET_INC;
	bp->inPtr = bp->outPtr + numBytes;
	free ((Address)bp->buffer);
	bp->buffer = newBuf;
	bp->size += BUF_UNGET_INC;
	bp->outPtr -= 1;
	*bp->outPtr = b;
    }
}

/*-
 *-----------------------------------------------------------------------
 * Buf_UngetBytes --
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
Buf_UngetBytes (Buffer	buf,
		int	numBytes,
		Byte	*bytesPtr)
{
    register BufPtr	bp = (BufPtr) buf;

    if (bp->outPtr - bp->buffer >= numBytes) {
	bp->outPtr -= numBytes;
	bcopy (bytesPtr, bp->outPtr, numBytes);
    } else if (bp->outPtr == bp->inPtr) {
	Buf_AddBytes (buf, numBytes, bytesPtr);
    } else {
	int 	  curNumBytes = bp->inPtr - bp->outPtr;
	Byte	  *newBuf;
	int 	  newBytes = max(numBytes,BUF_UNGET_INC);

	newBuf = (Byte *) malloc_tagged (bp->size + newBytes, TAG_BUFFER);
	bcopy((Address)bp->outPtr, (Address)(newBuf+newBytes), curNumBytes+1);
	bp->outPtr = newBuf + newBytes;
	bp->inPtr = bp->outPtr + curNumBytes;
	free ((Address)bp->buffer);
	bp->buffer = newBuf;
	bp->size += newBytes;
	bp->outPtr -= numBytes;
	bcopy ((Address)bytesPtr, (Address)bp->outPtr, numBytes);
    }
}
#endif /* 0 */

/*-
 *-----------------------------------------------------------------------
 * Buf_GetByte --
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
Buf_GetByte (Buffer buf)
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
 * Buf_GetBytes --
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
Buf_GetBytes (Buffer	buf,
	      int	numBytes,
	      Byte	*bytesPtr)
{
    BufPtr  bp = (BufPtr) buf;
    
    if (bp->inPtr - bp->outPtr < numBytes) {
	numBytes = bp->inPtr - bp->outPtr;
    }
    bcopy (bp->outPtr, bytesPtr, numBytes);
    bp->outPtr += numBytes;

    if (bp->outPtr == bp->inPtr) {
	bp->outPtr = bp->inPtr = bp->buffer;
	*bp->inPtr = 0;
    }
    return (numBytes);
}
#endif /* 0 */

/*-
 *-----------------------------------------------------------------------
 * Buf_DelBytes --
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
Buf_DelBytes(Buffer 	buf,
	     int    	numBytes)
{
    BufPtr  bp = (BufPtr)buf;

    bp->inPtr -= numBytes;
    if (bp->inPtr <= bp->outPtr) {
	bp->inPtr = bp->outPtr = bp->buffer;
    }
    *bp->inPtr = 0;
}

/*-
 *-----------------------------------------------------------------------
 * Buf_DelBytes --
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
Buf_DelBytesMiddle(Buffer 	buf,
		   int    	numBytes,
		   int          start)
{
    register int     i;
    register BufPtr  bp = (BufPtr)buf;

    bp->inPtr -= numBytes;
    if (bp->inPtr <= bp->outPtr) {
	bp->inPtr = bp->outPtr = bp->buffer;
	*bp->inPtr = 0;
    } else {
	/*
	 * Roll everything from start+numBytes back by numBytes
	 */
	for (i=start; i<=(bp->inPtr - bp->buffer); i++) {
	    bp->buffer[i] = bp->buffer[i +  numBytes];
	}
    }
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
Byte *
Buf_GetAll (Buffer  buf,
	    int	    *numBytesPtr)
{
    BufPtr  bp = (BufPtr)buf;

    if (numBytesPtr != (int *)NULL) {
	*numBytesPtr = bp->inPtr - bp->outPtr;
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
	     int    numBytes)
{
    register BufPtr	bp = (BufPtr) buf;

    if (bp->inPtr - bp->outPtr <= numBytes) {
	bp->inPtr = bp->outPtr = bp->buffer;
	*bp->inPtr = 0;
    } else {
	bp->outPtr += numBytes;
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

    bp = (Buf *) malloc_tagged(sizeof(Buf), TAG_BUFFER);

    if (size <= 0) {
	size = BUF_DEF_SIZE;
    }
    bp->size = size;
    bp->buffer = (Byte *) malloc_tagged (size, TAG_BUFFER);
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
	free ((malloc_t)bp->buffer);
    }
    free ((malloc_t)bp);
}
