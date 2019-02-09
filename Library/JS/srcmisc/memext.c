/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) MyTurn.com 2000.  All rights reserved.
	CONFIDENTIAL

PROJECT:	JavaScript
MODULE:		JS Library
FILE:		memext.c

AUTHOR:		David Hunter, Sep 19, 2000

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	9/19/00   	Initial version

DESCRIPTION:
	Extended memory routines for movable memory operation

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "srccore.h"

/* Undefine for "dummy" fixed-based allocator with all the handle overhead */
#define MOVABLE_ALLOCATOR

#include <heap.h>
#include <lmem.h>

/* Flag that script engine should callQuit as soon as possible due to 
   an out of memory condition. */
jsebool jseOutOfMemory = FALSE;

#if (JSE_MEMEXT_SECODES!=0) \
 || (JSE_MEMEXT_STRINGS!=0) \
 || (JSE_MEMEXT_OBJECTS!=0) \
 || (JSE_MEMEXT_MEMBERS!=0)

#if defined(MOVABLE_ALLOCATOR)

#include <MapHeap.h>

#pragma codeseg JSEMEM_TEXT

#  ifdef MEM_TRACKING
     dword handleMemSize;
     dword maxHandleMemSize;
#    define MAXHANDLEMEMSIZE() if (handleMemSize > maxHandleMemSize) maxHandleMemSize = handleMemSize;
     word lockCount;
     word maxLockCount;
#    define MAXLOCKCOUNT() if (lockCount > maxLockCount) maxLockCount = lockCount;
#  endif

/*
 * This is a very simple allocator.  A heap consists of one or more LMem blocks
 * of fixed size.  The handles and the last failed allocation size for each of
 * those blocks are stored in a separate movable block whose basic structure
 * is an array of BlockListEntry's.
 *
 * When an Alloc occurs:
 * An LMemAlloc is done on each block whose last failed allocation size is
 * zero or greater than or equal to the requested allocation size.  If the
 * LMemAlloc fails, the last failed allocation size for that block is updated
 * (with the requested allocation size, of course).  If the LMemAlloc succeeds,
 * the last failed allocation size is cleared.
 *
 * When a Free occurs, LMemFree is called, and the last failed allocation size
 * for that block is cleared.
 *
 * When a ReAlloc occurs, LMemReAlloc is called.  If that fails, an Alloc
 * happens, and the old data is copied and Free'd.
 *
 */

/* Structure of a single entry in the block list: */
typedef struct {
    MemHandle BLE_block;	/* MemHandle of the LMem block */
    word BLE_failSize;		/* last failed allocation size */
} BlockListEntry;

/* Structure of a block list: */
typedef struct {
    word BL_count;		/* number of slots in the list */
    BlockListEntry BL_list[1];	/* start of the entry list */
} BlockList;

#define BLOCK_LIST_BASE_SIZE (sizeof(BlockList) - sizeof(BlockListEntry))

/* Handles of the block lists for each heap.  The order MUST follow exactly
   the definition of jseMemExtType. */
MemHandle memextHeaps[] = {
#if (JSE_MEMEXT_SECODES!=0)
    NullHandle,		/* jseMemExtSecodeType */
#endif
#if (JSE_MEMEXT_STRINGS!=0)
    NullHandle,		/* jseMemExtStringType */
#endif
#if (JSE_MEMEXT_OBJECTS!=0)
    NullHandle,		/* jseMemExtObjectType */
#endif
#if (JSE_MEMEXT_MEMBERS!=0)
    NullHandle		/* jseMemExtMemberType */
#endif
};

/* Arbitrarily chosen fixed size for blocks in each heap. */
const word memextHeapSize[] = {
#if (JSE_MEMEXT_SECODES!=0)
    4 * 1024,		/* jseMemExtSecodeType */
#endif
#if (JSE_MEMEXT_STRINGS!=0)
    8 * 1024,		/* jseMemExtStringType */
#endif
#if (JSE_MEMEXT_OBJECTS!=0)
    8 * 1024,		/* jseMemExtObjectType */
#endif
#if (JSE_MEMEXT_MEMBERS!=0)
    8 * 1024		/* jseMemExtMemberType */
#endif
};    

#define JSE_MEMEXT_NUM_TYPES (sizeof(memextHeaps) / sizeof(MemHandle))

/* How to derefence an optr to an LMem block with no handles and the chunk
   handle is really the offset: */
#define LMemDerefNH(o) (void *)(((byte *)MemDeref(OptrToHandle(o))) + (word)OptrToChunk(o))

GeodeHandle jsememextOwner = NullHandle;

#define SLOT_INCREMENT 8

/* Arbitrarily chosen size limit for individual allocations, above which
   we'll allocate room in the mapped heap. */
#define JSE_MEMEXT_SIZE_LIMIT 10240

/* Arbitrarily chosen size limit at which we'll flag an out of memory
   condition, but still try to satisfy the request. */
#define JSE_MEMEXT_SIZE_OUT_OF_MEMORY 32767

extern jsememextHandle MappedPtrToJsememextHandle(void *p);

extern Boolean mapCreated;

void initializeMemExt(void)
{
    BlockList *bl;
    int i;
    MemHandle block;

    /* Get our handle once so we don't have to do it again. */
    jsememextOwner = GeodeGetCodeProcessHandle();

    /* Create the block lists for each heap. */
    for (i = 0; i < JSE_MEMEXT_NUM_TYPES; i++)
    {
	memextHeaps[i] = MemAllocSetOwner(jsememextOwner, BLOCK_LIST_BASE_SIZE + 
				     sizeof(BlockListEntry) * SLOT_INCREMENT,
				     HF_DYNAMIC|HF_SHARABLE,
				     HAF_ZERO_INIT | HAF_STANDARD_NO_ERR_LOCK);

	/* Allocate an initial block for the heap. */
	bl = (BlockList *) MemDeref(memextHeaps[i]);
	block = bl->BL_list[0].BLE_block = MemAllocSetOwner(jsememextOwner, 
						    memextHeapSize[i],
						    HF_DYNAMIC|HF_SHARABLE,
						    HAF_STANDARD_NO_ERR_LOCK);
	LMemInitHeap(block, LMEM_TYPE_GENERAL, 
                     LMF_NO_HANDLES | LMF_NO_ENLARGE | LMF_RETURN_ERRORS, 
                     sizeof(LMemBlockHeader), 0, 
		     memextHeapSize[i] - sizeof(LMemBlockHeader));
	MemUnlock(block);
	bl->BL_count = SLOT_INCREMENT;
	MemUnlock(memextHeaps[i]);
    }

#ifdef MEM_TRACKING
    handleMemSize = maxHandleMemSize = 0;
    lockCount = maxLockCount = 0;
#endif
}

void terminateMemExt(void)
{
    BlockList *bl;
    BlockListEntry *ble;
    word count;
    int i;

    for (i = 0; i < JSE_MEMEXT_NUM_TYPES; i++)
    {
	bl = (BlockList *) MemLock(memextHeaps[i]);
	count = bl->BL_count;
	EC_ERROR_IF(count == 0, -1);	/* this shouldn't happen. */
	ble = &(bl->BL_list[0]);

	for (; count; count--, ble++)
	    if (ble->BLE_block != NullHandle)
		MemFree(ble->BLE_block);

	MemFree(memextHeaps[i]);
    }
}

jsememextHandle jsememextAlloc(JSE_POINTER_UINDEX size,enum jseMemExtType type)
{
    BlockList *bl;
    BlockListEntry *ble;
    word count;
    jsememextHandle han = jsememextNullHandle;
    MemHandle block;
    ChunkHandle chunk;
    word freeSlot = 0;
    word newSize, needSize;

    if (size > JSE_MEMEXT_SIZE_OUT_OF_MEMORY)
	jseOutOfMemory = TRUE;

    if (mapCreated && size > JSE_MEMEXT_SIZE_LIMIT)
    {
	void *data = MapHeapMalloc(size);
	if (data != NULL)
	    return MappedPtrToJsememextHandle(data);
	/* else allocate on the movable heap... */
    }

    /* Lock down the block list appropriate for the type. */
    EC_ERROR_IF((unsigned int)type > JSE_MEMEXT_NUM_TYPES, -1);
    EC_WARNING_IF(size > memextHeapSize[(int)type] - sizeof(LMemBlockHeader), -1);
    bl = (BlockList *) MemLock(memextHeaps[(int)type]);
    count = bl->BL_count;
    EC_ERROR_IF(count == 0, -1);	/* this shouldn't happen. */
    ble = &(bl->BL_list[0]);
    
    /* Scan thru the list looking for a block whose last failed allocation
       size is zero or greater than or equal to 'size'. */
    for (; count; count--, ble++)
    {
	block = ble->BLE_block;
	if (block == NullHandle)
	{
	    if (freeSlot == 0)
		freeSlot = count;
	}
	else if (ble->BLE_failSize == 0 || ble->BLE_failSize >= size)
	{
	    /* Try allocation in this block. */
	    if ((chunk = LMemLockAllocAndReturnError(block, size)) != 0)
	    {
		han = ConstructOptr(block, chunk);
		ble->BLE_failSize = 0;
		break;
	    }
	    ble->BLE_failSize = size;
	    MemUnlock(block);
	}
    }

    /* If no blocks could hold it, then it's time to add another block. */
    if (count == 0)
    {
	/* If no free slots, extend the block list. */
	if (freeSlot == 0)
	{
	    bl->BL_count += SLOT_INCREMENT;
	    bl = (BlockList *) MemDeref(MemReAlloc(memextHeaps[(int)type],
		BLOCK_LIST_BASE_SIZE + sizeof(BlockListEntry) * bl->BL_count,
		HAF_ZERO_INIT | HAF_STANDARD_NO_ERR));
	    freeSlot = bl->BL_count - SLOT_INCREMENT;
	}
	else
	    freeSlot = bl->BL_count - freeSlot;

	newSize = memextHeapSize[(int)type];
	needSize = ((size+3) & 0xfffc) + sizeof(word) + sizeof(LMemBlockHeader);
	/* ensure big enough for requested allocation */
	if (newSize < needSize)
	    newSize = needSize;
#if JSE_MEMEXT_MEMBERS!=0
	/* for member array, we'll likely want more, so give us some extra */
	if (type == jseMemExtMemberType)
	    newSize += newSize/4;  /* arbitrarily 25% more */
#endif
	block = bl->BL_list[freeSlot].BLE_block = 
	    MemAllocSetOwner(jsememextOwner, newSize,
			     HF_DYNAMIC|HF_SHARABLE, HAF_STANDARD_NO_ERR_LOCK);
	LMemInitHeap(block, LMEM_TYPE_GENERAL, 
                     LMF_NO_HANDLES | LMF_NO_ENLARGE | LMF_RETURN_ERRORS, 
                     sizeof(LMemBlockHeader), 0, 
		     newSize - sizeof(LMemBlockHeader));
	han = ConstructOptr(block, LMemAlloc(block, size));
    }
#ifdef MEM_TRACKING
    handleMemSize += jseChunkSize(LMemDerefNH(han));
    MAXHANDLEMEMSIZE();
#endif
    MemUnlock(block);
    MemUnlock(memextHeaps[(int)type]);
    return han;
}

jsememextHandle jsememextRealloc(jsememextHandle memHandle,
				 JSE_POINTER_UINDEX size,enum jseMemExtType type)
{
    ChunkHandle chunk;
#ifdef MEM_TRACKING
    word oldsize;
#endif

    if (size > JSE_MEMEXT_SIZE_OUT_OF_MEMORY)
	jseOutOfMemory = TRUE;

    if (mapCreated && OptrToHandle(memHandle) < UTIL_WINDOW_MAX_NUM_WINDOWS)
    {
	void *data = MapHeapRealloc(jsememextLockRead(memHandle, type), size);
	if (data != NULL)
	    return MappedPtrToJsememextHandle(data);
	else
	{
	    /* If the reallocation failed, then allocate in movable heap. */
	    jsememextHandle newhan = jsememextAlloc(size, type);
	    void *old;

	    MemLock(OptrToHandle(newhan));
	    old = jsememextLockRead(memHandle, type);
	    memcpy(LMemDerefNH(newhan), old, size);
	    jsememextUnlockRead(memHandle, old, type);	/* unlock old chunk */
	    jsememextFree(memHandle, type);		/* free old chunk */
	    memHandle = newhan;
	    MemUnlock(OptrToHandle(memHandle));		/* unlock new chunk */
	    return memHandle;
	}
    }

    EC_ERROR_IF(memHandle == jsememextNullHandle, -1);
    EC_WARNING_IF(size > memextHeapSize[(int)type] - sizeof(LMemBlockHeader), -1);
#ifdef MEM_TRACKING
    /* If resizing succeeds, the old size will be lost afterwards */
    MemLock(OptrToHandle(memHandle));
    oldsize = jseChunkSize(LMemDerefNH(memHandle));
    MemUnlock(OptrToHandle(memHandle));
#endif
    if ((chunk = LMemLockReAllocAndReturnError(memHandle, size)) == 0)
    {
	/* If the reallocation failed, then allocate in another block,
	   copy and free and the old handle. */
	jsememextHandle newhan = jsememextAlloc(size, type);
	void *new = jsememextLockRead(newhan, type);
	
	memcpy(new, LMemDerefNH(memHandle), size);
	MemUnlock(OptrToHandle(memHandle));	/* unlock old chunk */
	jsememextFree(memHandle, type);		/* free old chunk */
	memHandle = newhan;
	jsememextUnlockRead(memHandle, new, type); /* unlock new chunk */
    }
    else
    {
	memHandle = ConstructOptr(OptrToHandle(memHandle), chunk);
#ifdef MEM_TRACKING
        handleMemSize += jseChunkSize(LMemDerefNH(memHandle)) - oldsize;
        MAXHANDLEMEMSIZE();
#endif
	MemUnlock(OptrToHandle(memHandle));	/* unlock new chunk */
    }

    return memHandle;
}

jsememextHandle jsememextStore(const void *data,JSE_POINTER_UINDEX size,
			       enum jseMemExtType type)
{
    /* This is just an allocation and a copy. */
    jsememextHandle han = jsememextAlloc(size, type);
    void *ptr = jsememextLockWrite(han, type);

    memcpy(ptr, data, size);
    jsememextUnlockWrite(han, ptr, type);
    return han;
}

void jsememextFree(jsememextHandle memHandle,enum jseMemExtType type)
{
    BlockList *bl;
    BlockListEntry *ble;
    word count;

    EC_ERROR_IF(memHandle == jsememextNullHandle, -1);

    if (mapCreated && OptrToHandle(memHandle) < UTIL_WINDOW_MAX_NUM_WINDOWS)
    {
	MapHeapFree(jsememextLockReadReally(memHandle, type));
	return;
    }

    /* Lock down the block list appropriate for the type. */
    EC_ERROR_IF((unsigned int)type > JSE_MEMEXT_NUM_TYPES, -1);
    bl = (BlockList *) MemLock(memextHeaps[(int)type]);
    count = bl->BL_count;
    EC_ERROR_IF(count == 0, -1);	/* this shouldn't happen. */
    ble = &(bl->BL_list[0]);

    /* Find the block list entry for the passed handle. */
    for (; count; count--, ble++)
	if (ble->BLE_block == OptrToHandle(memHandle))
	    break;
    EC_ERROR_IF(count == 0, -1);	/* where's the block? */

    /* Free the chunk and clear the last failed allocation size. */
    MemLock(OptrToHandle(memHandle));
#ifdef MEM_TRACKING
    handleMemSize -= jseChunkSize(LMemDerefNH(memHandle));
#endif
    LMemFree(memHandle);
    MemUnlock(OptrToHandle(memHandle));
    ble->BLE_failSize = 0;
    MemUnlock(memextHeaps[(int)type]);
}

#ifdef MEM_TRACKING

JSE_MEMEXT_R void * jsememextLockRead(jsememextHandle memHandle,
				      enum jseMemExtType type)
{
    lockCount++;
    MAXLOCKCOUNT();
    return jsememextLockReadReally(memHandle, type);
}

void jsememextUnlockRead(jsememextHandle memHandle,JSE_MEMEXT_R void * data,
			 enum jseMemExtType type)
{
    jsememextUnlockReadReally(memHandle, data, type);
    lockCount--;
}

#endif

#else  /* defined(MOVABLE_ALLOCATOR) */

/*
 * An even simpler allocator that only creates fixed memory blocks and
 * has no need to lock anything. It is only intended as a test for the
 * basic overhead of the memory extension mechanism.
 */

void initializeMemExt(void) {}
void terminateMemExt(void) {}

#pragma argsused
jsememextHandle jsememextAlloc(JSE_POINTER_UINDEX size,enum jseMemExtType type)
{
    return (jsememextHandle)jseMappedMalloc(size);
}

#pragma argsused
jsememextHandle jsememextRealloc(jsememextHandle memHandle,
				 JSE_POINTER_UINDEX size,enum jseMemExtType type)
{
    return (jsememextHandle)jseMappedRealloc((void *)memHandle, size);
}

#pragma argsused
jsememextHandle jsememextStore(const void *data,JSE_POINTER_UINDEX size,
			       enum jseMemExtType type)
{
    void *mem = jseMappedMalloc(size);
    memcpy(mem,data,size);
    return (jsememextHandle)mem;
}

#pragma argsused
void jsememextFree(jsememextHandle memHandle,enum jseMemExtType type)
{
    jseMappedFree((void *)memHandle);
}

#pragma argsused
JSE_MEMEXT_R void * jsememextLockRead(jsememextHandle memHandle,
				      enum jseMemExtType type)
{
    return (void *)memHandle;
}

#pragma argsused
void jsememextUnlockRead(jsememextHandle memHandle,JSE_MEMEXT_R void * data,
			 enum jseMemExtType type)
{
}

#endif /* defined(MOVABLE_ALLOCATOR) */

#endif
