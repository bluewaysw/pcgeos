/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		rheapint.h

AUTHOR:		Ronald Braunstein, Jul 21, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 7/21/95	Initial version.

DESCRIPTION:

	This file allows the basrun library to call RunHeapLock et al
	as macros for speed.  During EC, it will default to using the
	external routines.  The basrun library calls RunHeapLock
	everywhere.  This is only file where it uses
	RunHeapLockExternal, internally in the library.  The .gp file
	maps the routine RunHeapLockExeternal to RunHeapLock.  The
	code for these routines can be found in runheap.c.
	


	$Revision: 1.1 $

	Liberty version control
	$Id: rheapint.h,v 1.1 98/10/05 12:35:17 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _RHEAPINT_H_
#define _RHEAPINT_H_

typedef void (*RunHeapCB)(byte* data, word size, void* extra_data);

#ifdef LIBERTY
#include <Legos/runheap.h>

extern void
LRunHeapEnum(RunHeapType rht, RunHeapCB callback, void* extra_data);

#define RunHeapEnum(a, b, c, d) LRunHeapEnum(b, c, d)

#else					/* GEOS STUFF */
#include <Legos/runheap.h>

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %		Macros for manipulating tokens
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* A token consists of a segment (high bits) and a block key or BKEY
 * (low bits).  The BKEY is an index into an LMem heap's array of
 * chunk handles.
 */

/* These two affect everything that follows */

/* #define TOKEN_SEG_BITS	defined in runheap.h */
/* #define TOKEN_SEG_MASK	defined in runheap.h */

#define TOKEN_BKEY_BITS ((sizeof(RunHeapToken)*8) - TOKEN_SEG_BITS)
#define TOKEN_BKEY_MASK (~(TOKEN_SEG_MASK))

#define CONSTRUCT_TOKEN(_seg, _bkey) ((_seg << TOKEN_BKEY_BITS) | _bkey)

#define TOKEN_SEG(x) (((unsigned)(TOKEN_SEG_MASK & (x))) >> TOKEN_BKEY_BITS)
#define TOKEN_BKEY(x) (TOKEN_BKEY_MASK & (x))

#define TOKEN_TO_CHUNK(x) \
((TOKEN_BKEY(x) << 1) + sizeof(LMemBlockHeader))

#define CHUNK_TO_BKEY(x) ((((word) x) - sizeof(LMemBlockHeader)) >> 1)
#define SAME_HEAP_BLOCK(x,y) (TOKEN_SEG(x) == TOKEN_SEG(y))


#define DESIRED_MAX_BLOCK_SIZE 4000


extern void
RunHeapLockExternal(RunHeapInfo*, RunHeapToken, void **data);

extern void
RunHeapUnlockExternal(RunHeapInfo*, RunHeapToken);

extern void*
RunHeapDerefExternal(RunHeapInfo*, RunHeapToken);

extern void
RunHeapDecRefAndUnlockExternal(RunHeapInfo*, RunHeapToken, void *data);

extern void
RunHeapEnum(RunHeapInfo* rhi, RunHeapType rht,
	    RunHeapCB callback, void* extra_data);

#define NO_INLINE ERROR_CHECK

#if NO_INLINE

#define RunHeapLock(rhi, token, dest)		\
	 RunHeapLockExternal(rhi, token, dest)

#define RunHeapUnlock(rhi, token) 		\
	 RunHeapUnlockExternal(rhi, token)

#define RunHeapDeref(rhi, token) 		\
	 RunHeapDerefExternal(rhi, token)

#define RunHeapDecRefAndUnlock(rhi, token, data) \
	RunHeapDecRefAndUnlockExternal(rhi, token, data)
#else

#define RunHeapLock(rhi, token, dest)					    \
do {									    \
     MemHandle han = (rhi)->RHI_blockTable				    \
	[TOKEN_SEG((RunHeapToken) (token))].HBE_handle;			    \
     MemLock(han);							    \
     *(dest) = ((void*) (((RunHeapEntry*)				    \
         LMemDerefHandles(han, TOKEN_TO_CHUNK((RunHeapToken) (token)))) + 1)); \
} while (0)
					     
#define RunHeapUnlock(rhi, token)			\
    MemUnlock((rhi)->RHI_blockTable			\
        [TOKEN_SEG((RunHeapToken) (token))].HBE_handle)	\

#define RunHeapDeref(rhi, token)					\
    ((void *)(								\
((RunHeapEntry*) LMemDerefHandles(					\
  (rhi)->RHI_blockTable[TOKEN_SEG((RunHeapToken)(token))].HBE_handle,	\
  TOKEN_TO_CHUNK((RunHeapToken)(token))					\
)) + 1))

#define RunHeapDecRefAndUnlock(rhi, token, data)	\
do {							\
    Boolean zero = FALSE;				\
    if ((RunHeapToken)(token)) RHE_DECREF(data);	\
    if (!RHE_REFCOUNT(data)) {				\
        zero = TRUE;					\
    }							\
    RunHeapUnlock(rhi, (RunHeapToken)(token));		\
    if (zero) {						\
         RunHeapFree(rhi, (RunHeapToken)(token));	\
    }							\
} while (0)

#endif /* NO_INLINE */
#endif /* GEOS STUFF */

#endif /* _RHEAPINT_H_ */

