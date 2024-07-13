/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basrun
FILE:		runheap.h

AUTHOR:		Roy Goldman, Jun  6, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 6/ 6/95	Initial version.

DESCRIPTION:
	Reference-counted heap.

	$Revision: 1.1 $

	Liberty version control
	$Id: runheap.h,v 1.1 98/03/11 04:38:02 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _RUNHEAP_H_
#define _RUNHEAP_H_

/* The handle to any entry in the heap is identified by a RunHeapToken */

#ifdef LIBERTY

typedef byte RunHeapType;
#define RHT_STRING		0x00
#define RHT_STRUCT		0x01
#define RHT_COMPLEX		0x02
#define RHT_XIP_STRING_CONSTANT 0xfe
#define RHT_DLL_STRING_CONSTANT 0xfd

/* Because more than one value is legal for a "string" type in Liberty,
   we provide this macro that can be used to test for string types */
#define RHT_IS_STRING(runHeapType) 		\
   (runHeapType == RHT_STRING ||		\
    runHeapType == RHT_XIP_STRING_CONSTANT ||	\
    runHeapType == RHT_DLL_STRING_CONSTANT)

/* Every entry in the heap is preceded with the following header */
typedef struct {
    RunHeapType RHE_type;
    byte        RHE_refCount;
} RunHeapEntry;                     

typedef MemHandle RunHeapToken;

/* ------------------------------------------------------ */
/* Routine headers and macros                             */
/* ------------------------------------------------------ */

extern RunHeapToken 
LRunHeapAlloc(RunHeapType type, byte initRefCount, 
	      word size, const void *data);

extern void
LRunHeapFree(RunHeapToken token);
 
extern void 
*LRunHeapLock(RunHeapToken token);

extern void
LRunHeapUnlock(RunHeapToken token);

/* Return the type of a run heap block.  "token" must be a valid token. */
extern RunHeapType LRunHeapGetType(RunHeapToken token);

/* Return the refCount of a run heap block. */
extern byte LRunHeapGetRefCount(RunHeapToken token);

extern void
LRunHeapIncRef(RunHeapToken token);

extern void
LRunHeapDecRef(RunHeapToken token);

extern void
LRunHeapDecRefAndUnlock(RunHeapToken token);

#define RunHeapAlloc(rhi, type, initRefCount, size, data) \
    LRunHeapAlloc(type, initRefCount, size, data)

#define RunHeapLock(rhi, token, dest) \
    *(dest) = LRunHeapLock((RunHeapToken)token)

#define RunHeapUnlock(rhi, token) LRunHeapUnlock(token)

#define RunHeapIncRef(rhi, token) LRunHeapIncRef((RunHeapToken)token)

#define RunHeapDecRef(rhi, token) LRunHeapDecRef((RunHeapToken)token)

#define RunHeapDecRefAndUnlock(rhi, token, data) \
    LRunHeapDecRefAndUnlock(token)

#if ERROR_CHECK
#define RHE_COOKIE_VALUE (0xdead)
#define RHE_COOKIE(dataPtr)   ((((RunHeapEntry*)(dataPtr))-1)->RHE_cookie)
#endif

extern char NULL_STRING;
#define EMPTY_STRING_KEY (RunHeapToken)(0x0)
#define NULL_TOKEN EMPTY_STRING_KEY
#define SAME_HEAP_BLOCK(a,b) TRUE


#else	/* GEOS DEFINITIONS */

#include <geos.h>

#define TOKEN_SEG_BITS 7
#define TOKEN_SEG_MASK (0xfe00)
#define MAX_HEAP_BLOCKS (1 << TOKEN_SEG_BITS)

typedef word	RunHeapToken;        

/* Every entry in the heap will be one of the following types */

typedef enum {
    RHT_STRING,
    RHT_STRUCT,
    RHT_COMPLEX
} RunHeapType;

/* Because more than one value is legal for a "string" type in Liberty,
   we provide this macro that can be used to test for string types */
#define RHT_IS_STRING(runHeapType) (runHeapType == RHT_STRING)

/* Every entry in the heap is preceded with the following header */

typedef struct
{
#if ERROR_CHECK
#define RHE_COOKIE_VALUE (0xdead)
    word	RHE_cookie;
    byte	RHE_numLocks;
#endif
    RunHeapType	RHE_type;
    byte	RHE_refCount;
} RunHeapEntry;


/* Things become very convenient when the EMPTY_STRING_KEY is 0,
   since new arrays, local variables, and return variables are all
   automatically initialized to the null string.

   Be very careful if you change this, or can no longer guarantee
   that key 0 in the global heap is the empty string.  You will
   have to modify all creations of strings arrays or variables. One
   particularly narley little thing is the OP_ZERO opcode, used
   to create space for a routine's returne variable; it will have
   to be tweaked to spit out the new EMPTY_STRING_KEY....

   Also, there is no reference count work ever done for the zero key...
   (If your code ever calls INCREF or DECREF directly, make sure
   you don't do it for the 0 string...
*/

/* RunHeapAlloc will never return this value
 */
#define EMPTY_STRING_KEY (0x0)
#define NULL_TOKEN EMPTY_STRING_KEY

typedef struct {
    MemHandle	HBE_handle;
    word	HBE_usedSize;
} HeapBlockEntry;

typedef struct
{
#if ERROR_CHECK
    byte	RHI_numLocks;	/* Total # locks of heap entries */
    byte	RHI_heapLocks;	/* EC-only heap-wide lock count
				 * See ECRunHeapLockHeap */
#endif
    HeapBlockEntry RHI_blockTable[MAX_HEAP_BLOCKS];
    byte	RHI_lastBlock;	/* Last block used for allocation */
} RunHeapInfo;

/* When given the option of creating an additional block
   or forcing the usedSize above this value, we will
   always create a new block unless there are no more small
   enough blocks...
*/

/* ------------------------------------------------------ */
/* Routine headers and macros				  */
/* ------------------------------------------------------ */

RunHeapInfo	RunHeapCreate(void);
void		RunHeapDestroy(RunHeapInfo *rfi);

RunHeapToken	RunHeapAlloc(RunHeapInfo *rhi, RunHeapType type,
			     byte initRefCount, word size, void *data);
void		RunHeapFree(RunHeapInfo *rhi, RunHeapToken token);
void		RunHeapIncRef(RunHeapInfo *rhi, RunHeapToken token);
void		RunHeapDecRef(RunHeapInfo *rhi, RunHeapToken token);

void		RunHeapLock(RunHeapInfo *rhi, RunHeapToken token, void **data);
word		RunHeapDataSize(RunHeapInfo *rhi, RunHeapToken token);
void		RunHeapUnlock(RunHeapInfo *rhi, RunHeapToken token);
void*		RunHeapDeref(RunHeapInfo *rhi, RunHeapToken token);
void		RunHeapDecRefAndUnlock(RunHeapInfo *rhi, RunHeapToken token, 
				       void *data);

/* RunComponent...Heap are defined in basrun.goh
 */
#define RunOptrLockHeap(_optr) \
  RunComponentLockHeap(MemDeref(OptrToHandle(_optr)))

#define RunOptrUnlockHeap(_optr) \
  RunComponentUnlockHeap(MemDeref(OptrToHandle(_optr)))

extern void	ECRunHeapLockHeap(RunHeapInfo*);
extern void	ECRunHeapUnlockHeap(RunHeapInfo*);

/* -------------------------- */
/* Since the lock returns a pointer to the actual data of the block,
   (which comes directly after the header), subtract one to access
   header data...
   */

#if ERROR_CHECK

#define RHE_NUMLOCKS(dataPtr) ((((RunHeapEntry*)(dataPtr))-1)->RHE_numLocks)
#define RHE_COOKIE(dataPtr)   ((((RunHeapEntry*)(dataPtr))-1)->RHE_cookie)

#endif

#define RHE_REFCOUNT(dataPtr) ((((RunHeapEntry*)(dataPtr))-1)->RHE_refCount)
#define RHE_TYPE(dataPtr)     ((((RunHeapEntry*)(dataPtr))-1)->RHE_type)
/* #define RHE_SIZE(dataPtr)	((((RunHeapEntry*)(dataPtr))-1)->RHE_size) */


#if ERROR_CHECK

#define RHE_INCREF(dataPtr) \
EC_ERROR_IF((++RHE_REFCOUNT(dataPtr)) == 0, RE_FAILED_ASSERTION)

#define RHE_DECREF(dataPtr) \
EC_ERROR_IF((RHE_REFCOUNT(dataPtr)--) == 0, RE_FAILED_ASSERTION)


#else

#define RHE_INCREF(dataPtr)   (++RHE_REFCOUNT(dataPtr))

#define RHE_DECREF(dataPtr)   (--RHE_REFCOUNT(dataPtr))


#endif

#endif	/* GEOS DEFINITIONS */
#endif	/* _RUNHEAP_H_ */
