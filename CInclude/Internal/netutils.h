/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	socket
MODULE:		Network utilities library
FILE:		netutils.h

AUTHOR:		Eric Weber, Jul 24, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/24/95   	Initial version.

DESCRIPTION:
        NOTE: Do not add goc keywords to this file as it is included
	by regular .h files.  
	

	$Id: netutils.h,v 1.1 97/04/04 15:53:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


/*
 *  default max block number for a hugelmem
 */
#define DEFAULT_MAX_BLOCK_NUMBER	(100)

/*
 *  RESERVED TIMEOUT VALUES
 *  : used in HugeLMemAllocLock, QueueEnqueueStart, QueueDequeueStart
 */
#define FOREVER_WAIT	(0xffff)              /*  */
#define NO_WAIT	        (0x0000)              /*  */
#define RESIZE_QUEUE	(0x0001)              /*  HACK! this MUST be 1. */


/*
 *  HugeLMem errors
 */
/* enum HugeLMemErrors */
typedef enum {		
/*  an optr not belonging to this hugelmem is passed */
    HLME_BLOCK_NOT_FOUND = 0x0,

/*
 *  resizing the given chunk will make current data block in
 *  hugelmem too big( this will never happen in net lib )
 *  But, I will change this so that the hugelmem chunk can be 
 *  relocated within the hugelmem later.
 */
    HLME_BLOCK_BECAME_TOO_BIG = 0x2,


} HugeLMemErrors;

/* 
 *  Queue errors
 */
/* enum QueueErrors */
typedef enum {	       
/*
 *  a queue operation could not be completed within the given
 *  time
 */

    QE_TIMEOUT = 0x0,


/*
 *  tried to perform a queue operation on a dead queue.
 *  You can't do anything to a dead queue. But this comes in
 *  handy in shutdown sequence of an application where multiple
 *  threads are accessing a common queue.
 */
    QE_DEAD = 0x2,

    QE_TOO_BIG = 0x4,

} QueueErrors;

/*
 *  tried resize the queue beyond the max capacity of the queue.
 */

typedef Handle HugeLMemHandle;

HugeLMemHandle
_pascal HugeLMemCreate(word maxBlocks, word minSize, word maxSize);
/* --------------------------------------------------------------------
SYNOPSIS:	Creates and initializes a HugeLMem.
PASS:		ax = maximum # of mem blocks to be used
		     0 for default(maximum) value
		bx = minimum size for an optimal block
		cx = maximum size for an optimal block
RETURN:		bx = HugeLMem handle
		carry set on error( most likely to be "insufficient memory" )
		MemHandle null if error
DESTROYED:	ax, cx
------------------------------------------------------------------------*/

void 
_pascal HugeLMemForceDestory(HugeLMemHandle handle);
/* --------------------------------------------------------------------
SYNOPSIS:	Destroys a HugeLMem without checking if there are still
		chunks allocated in it.
PASS:		bx = HugeLMem handle
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	none
-----------------------------------------------------------------------*/

Boolean
_pascal HugeLMemDestroy(HugeLMemHandle handle);
/* --------------------------------------------------------------------
SYNOPSIS:	Destroys a HugeLMem.  If there are still chunks around, return
		with error
PASS:		bx = HugeLMem handle
RETURN:		carry set if there are still chunks around on the heap.
DESTROYED:	bx
SIDE EFFECTS:	none
-----------------------------------------------------------------------*/

Boolean
_pascal HugeLMemAllocLock(HugeLMemHandle handle, word chunkSize, word timeout,
			  optr *newBufferOptr);

/* -------------------------------------------------------------------
SYNOPSIS:	Allocates a chunk in HugeLMem, and returns optr & fptr to it.
		When this function returns, the block containing the newly
		allocated chunk is locked.  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PASS:		ax = size of chunk
		bx = HugeMemHandle
		cx = timeout value( ticks )
		     0 means no wait
		     FOREVER_WAIT means wait forever
		When there is not enough memory, wait for cx number of ticks
		to see if anything frees up.
RETURN:		^lax:cx = new buffer( optr )
		ds:di	= new buffer( fptr )
		If there is not enough memory, carry set.
IMPORTANT:	Memory block in which the chunk is allocated in is locked.
		One must unlock it after writing things into it.
DESTROYED:	nothing
SIDE EFFECTS:	none
----------------------------------------------------------------------*/

Boolean
_pascal HugeLMemFree(optr hugeLMemOptr);

/* -------------------------------------------------------------------
TESTED
SYNOPSIS:	frees a HugeMem chunk
PASS:		^lax:cx = huge mem chunk optr
RETURN:		none

		In EC version, invalid chunk optr is detected in
		ECValidateHugeLMemChunk.

		In non-EC version:
		if datablock(ax) belongs to this hugeLMem,
		   if cx = illegal handle, then [fatal error from LMemFree]
		   else [everything is fine]
		else
		   carry = set.

DESTROYED:	ax, cx
SIDE EFFECTS:	none
----------------------------------------------------------------------*/

void *
_pascal HugeLMemLock(MemHandle hugeLMemOptr);

/* -------------------------------------------------------------------
TESTED
SYNOPSIS:	locks the block containing a hugelmem chunk
PASS:		bx = hptr part of hugelmem chunk
RETURN:		ax = segment address of the block
DESTROYED:	nothing
SIDE EFFECTS:	none
----------------------------------------------------------------------*/

void
_pascal HugeLMemUnlock(MemHandle handle);
/* -------------------------------------------------------------------
TESTED
SYNOPSIS:	Unlocks a memblock containing hugelmem chunk
PASS:		bx = hptr part of hugelmem chunk
RETURN:		none
DESTROYED:	nothing
SIDE EFFECTS:	none
----------------------------------------------------------------------*/

Boolean
_pascal HugeLMemRealloc(optr hugeLMemOptr, word size);
/* -------------------------------------------------------------------
SYNOPSIS:	Change the size of a chunk in a hugelmem
PASS:		*ds:ax = handle of the hugelmem chunk
		cx = size to resize chunk to
RETURN:		ds = segment address of same lmem heap (may have moved).
		es = unchanged, unless es and ds were the same on entry to the
		     routine, in which case es and ds are the same on return.
		carry = set if error( couldn't realloc the chunk because of
		        memory or max size limitation in which case the user
			is advised to create a new larger chunk rather than
			resizing this one. )

DESTROYED:	nothing
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

IMPORTANT
NOTE:		Currently only downsizing a chunk is allowed.

SIDE EFFECTS:	none
----------------------------------------------------------------------*/

/* generate a 32 bit random number */
extern long _pascal NetGenerateRandom32();

/* generate an 8 bit random number between 0 and limit */
extern int _pascal NetGenerateRandom8(int limit);

#ifdef __HIGHC__

pragma Alias(HugeLMemCreate, "HUGELMEMCREATE");
pragma Alias(HugeLMemForceDestory, "HUGELMEMFORCEDESTORY");
pragma Alias(HugeLMemDestroy, "HUGELMEMDESTROY");
pragma Alias(HugeLMemAllocLock, "HUGELMEMALLOCLOCK");
pragma Alias(HugeLMemFree, "HUGELMEMFREE");
pragma Alias(HugeLMemLock, "HUGELMEMLOCK");
pragma Alias(HugeLMemUnlock, "HUGELMEMUNLOCK");
pragma Alias(HugeLMemRealloc, "HUGELMEMREALLOC");
pragma Alias(NetGenerateRandom32, "NETGENERATERANDOM32");
pragma Alias(NetGenerateRandom8, "NETGENERATERANDOM8");
#endif











