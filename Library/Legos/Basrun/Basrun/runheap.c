/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos!
MODULE:		
FILE:		runheap.c

AUTHOR:		Roy Goldman, Jun  6, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 6/ 6/95   	Initial version.

DESCRIPTION:
	Code for the global reference heap.


	Liberty version control
	$Id: runheap.c,v 1.2 98/10/05 12:41:51 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/runint.h>
#include <Legos/basrun.h>
#include <data/data.h>
#include <Legos/rheapint.h>

#if ERROR_CHECK
# include <pos/ramalloc.h>
#endif

#include <data/array.h>

/****************************************************************/
/* list handles of RHT_STRUCTs on the RunHeap, implemented as 	*/
/* just a simple movable array (elements are handles).  The	*/
/* array grows and shrinks in chunks of STRUCT_LIST_GROW_INCREMENT   */
/****************************************************************/
#define STRUCT_LIST_GROW_INCREMENT 32
static MemHandle theStructListHandle = DM_BAD_DATA_HANDLE;
static int32 theStructListElementCount = 0;	/* num elements in array */
static int32 theStructListSize = 0;	/* size of array */

#include <Ansi/string.h> /* for memcpy() */

/***********************************************************************
 *			StructListAdd()
 ***********************************************************************
 * SYNOPSIS:	    Adds a run heap token to the struct list
 * CALLED BY:	    LRunHeapAlloc()
 * RETURN:	    SUCCESS on success, FAILURE on failure
 * SIDE EFFECTS:    Modifies the theStructList* variables
 *
 * STRATEGY:	    Grow the struct list array in chunks to reduce
 *		    allocation time.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	matta	9/18/96  	Initial Revision
 *
 ***********************************************************************/
static Result
StructListAdd(RunHeapToken token)
{
    /* add the token to theStructList */
    if (theStructListHandle == DM_BAD_DATA_HANDLE) {
	ASSERT(theStructListElementCount == 0);
	ASSERT(theStructListSize == 0);
	/* first time */
	theStructListHandle = MallocH(STRUCT_LIST_GROW_INCREMENT *
				      sizeof(MemHandle));
	if (theStructListHandle == DM_BAD_DATA_HANDLE) {
	    /* allocation failed!  */
	    return FAILURE;
	} else {
	    theStructListSize = STRUCT_LIST_GROW_INCREMENT;
	    theStructListElementCount = 1;
	    MemHandle *handleArray = (MemHandle*)LockH(theStructListHandle);
	    EC(theHeap.SetTypeAndOwner(handleArray, "SLST", (Geode*)0);)
	    handleArray[0] = token;
	    UnlockH(theStructListHandle);
	}

    } else {
	/* grow array if necessary (by chunks of
           STRUCT_LIST_GROW_INCREMENT) */
	if (theStructListSize == theStructListElementCount) {
	    if (ReallocH(theStructListHandle,
			 (theStructListSize + 
			  STRUCT_LIST_GROW_INCREMENT) * 
			 sizeof(MemHandle)) == FAILURE) {
		/* ran out of memory trying to extend array */
		return FAILURE;
	    }
	    theStructListSize += STRUCT_LIST_GROW_INCREMENT;
	}
	/* append to the list */
	MemHandle *handleArray = (MemHandle*)LockH(theStructListHandle);
	EC(theHeap.SetTypeAndOwner(handleArray, "SLST", (Geode*)0);)
	handleArray[theStructListElementCount] = token;
	theStructListElementCount++;
	UnlockH(theStructListHandle);
    }
    return SUCCESS;

}	/* End of StructListAdd() */


/***********************************************************************
 *			StructListRemove()
 ***********************************************************************
 * SYNOPSIS:	    Removes a token from the struct list
 * CALLED BY:	    LRunHeapFree()
 * RETURN:	    void
 * SIDE EFFECTS:    modifies theStructList* variables
 *
 * STRATEGY:	    Shrinks the array in chunks to avoid
 * 		    allocator overhead (execution speed)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	matta	9/18/96  	Initial Revision
 *
 ***********************************************************************/
static void
StructListRemove(RunHeapToken token)
{
    ASSERT(theStructListHandle != DM_BAD_DATA_HANDLE);

    if (theStructListHandle == DM_BAD_DATA_HANDLE) {
	return;			/* exceptional case */
    }

    /* remove the entry from theStructList array */
    MemHandle *handleArray = (MemHandle*)LockH(theStructListHandle);
    /* do a simple linear search of the unsorted array */
    int32 index;
    for (index = theStructListElementCount - 1; index >= 0; index--) {
	if (handleArray[index] == token) {
	    /* found the entry, move any entries below this one up */
	    memmove(&handleArray[index], &handleArray[index + 1],
		    ((theStructListElementCount - index - 1) * 
		     sizeof(MemHandle)));
		    
	    /* decrement count of elements in array and unlock
	       the array */
	    theStructListElementCount--;
	    UnlockH(theStructListHandle);
	    handleArray = NULL;

	    /* if too much free space, shrink the array.  Note
	       that this leaves the block around even when
	       element count is zero -- this is intentional */
	    if (theStructListElementCount < (theStructListSize -
					     STRUCT_LIST_GROW_INCREMENT)) {
		theStructListSize -= STRUCT_LIST_GROW_INCREMENT;
		ASSERT(theStructListSize >= theStructListElementCount);
		ASSERT(theStructListSize > 0);
		/* no check, shrinking doesn't fail */
		ReallocH(theStructListHandle, 
			 theStructListSize * sizeof(MemHandle));
	    }

	    /* break out of loop */
	    break;
	}
    }
    ASSERTS(index >= 0, "token for struct not found in RunHeap list");

}	/* End of StructListRemove() */



/***********************************************************************
 *			LRunHeapAlloc()
 ***********************************************************************
 * SYNOPSIS:    Create a buffer on the Legos run heap and optionally
 *              fill it with some initial data.
 * CALLED BY:   Interpreter, Components
 * RETURN:      a RunHeapToken, which may be NULL on error.
 * SIDE EFFECTS:
 *
 * STRATEGY:    The initial reference count of the run heap buffer
 *              is "initRefCount".  The interpreter and components
 *              increment reference count when a RunHeapToken is stored,
 *              so if you are allocating a buffer and passing it off
 *              to someone, you should set its reference count to zero.
 *	    	For STRUCTS, Liberty implemention differs from GEOS
 *	    	due to fact that there is no way to determine the size
 *	    	of the block once it has been allocated, so we have to
 *	    	store the size of the block with it ourselves.  This
 *	    	extra two bytes is hidden from the user.
 *
 *		For Complex data, we pad the header to 4-byte align the
 *		Data object.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	mchen	10/ 3/95   	Initial Revision
 *
 ***********************************************************************/
RunHeapToken
LRunHeapAlloc(RunHeapType type, byte initRefCount, 
	      word size, const void *data) 
{
    RunHeapToken rToken;
    if((type == RHT_STRUCT) || (type == RHT_COMPLEX)) {
	/* structs need the extra 2 bytes for the size of the structure,
	   complex needs 2 bytes to 4-byte align the Data object */
    	rToken = MallocH(size + sizeof(RunHeapEntry) + sizeof(word));
    } else {
    	rToken = MallocH(size + sizeof(RunHeapEntry));
    }
    ASSERTS_WARN(rToken != DM_BAD_DATA_HANDLE, 
		"LRunHeapAlloc() returning NULL_HANDLE!");
    if(rToken == DM_BAD_DATA_HANDLE) {
	return rToken;
    }
    RunHeapEntry *result = (RunHeapEntry*)LockH(rToken);
#ifdef ERROR_CHECK
    switch (type) {
     case RHT_STRING:
	HeapSetTypeAndOwner(result,"RHS");
	break;
     case RHT_STRUCT:
	HeapSetTypeAndOwner(result,"RHST");
	break;
     case RHT_COMPLEX:
	HeapSetTypeAndOwner(result,"RHCX");
	break;
     default:
	HeapSetTypeAndOwner(result,"RHEP");
	break;
    }
#endif
    result->RHE_type = type;
    result->RHE_refCount = initRefCount;

    if(type == RHT_STRUCT) {
	result++;
	*(word*)(result) = size;    	/* save the size inside a STRUCT */

	if (StructListAdd(rToken) == FAILURE) {
		/* allocation failed! */
		UnlockH(rToken);
		FreeH(rToken);
		return DM_BAD_DATA_HANDLE;
	}
    }

    if (data != NULL) {	    	    	/* copy any initial data value */
	ASSERT(type != RHT_COMPLEX);	/* shouldn't be copying COMPLEX */
	memcpy(result+1, data, size);
    } else if (type == RHT_COMPLEX) {
        /* initialize the rest of the memory to 0, which we will use
           to check when we delete the memory later so we don't delete
           an unitialized complex object */
        memset(result+1, 0, size);
    }
    UnlockH(rToken);
    return rToken;
}	/* End of LRunHeapAlloc. */

extern TCHAR const theNullString[1] = {'\0'};
   

/***********************************************************************
 *			LRunHeapLock
 ***********************************************************************
 * SYNOPSIS:    Dereferences a RunHeapToken previously returned by
 *              LRunHeapAlloc(), returns a pointer to the data.
 * CALLED BY:	Interpreter, Components
 * RETURN:	void* or NULL when the token is NULL.
 * SIDE EFFECTS:
 *
 * STRATEGY:	For XIP strings (strings that are in ROM), the RunHeapToken
 *		passed around is actually a pointer and not a DataHandle.
 *		We check if the RunHeapToken is a DataHandle and either
 *		lock it if it is or simply return the offset if it is not.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	mchen	10/ 3/95   	Initial Revision
 *
 ***********************************************************************/
void *
LRunHeapLock(RunHeapToken token) 
{
    if(token == NULL_TOKEN) {
	return((void*)theNullString);
    }
    PARAM_ASSERT(token != 0);
    RunHeapEntry *entry;
    if(theHeapDataMap.ValueIsHandle(token)) {
	// the token was a handle, do normal locking
	entry = (RunHeapEntry*)LockH(token);
	ASSERT(entry);
	ASSERT(entry->RHE_type != RHT_XIP_STRING_CONSTANT);
	if((entry->RHE_type == RHT_STRUCT) || 
	   (entry->RHE_type == RHT_COMPLEX)) {
	    /* for a struct, skip both the header (2 bytes) and the
	       size of the struct (2 bytes) */
	    /* for a complex object, skip both the header (2 bytes) and
	       the 2 byte padding so that the object is 4 byte aligned */
	    return(entry+2);
	}
    }
    else {
	/* the token was not a handle, we assume that it is a pointer to
	   an XIP STRING CONSTANT */
	entry = (RunHeapEntry*)token;
	ASSERT(entry->RHE_type == RHT_XIP_STRING_CONSTANT);
    }
    return(entry+1);
}	/* End of LRunHeapLock. */

/***********************************************************************
 *			LRunHeapUnlock
 ***********************************************************************
 * SYNOPSIS:    Unlock a locked RunHeapToken.
 * CALLED BY:	Interpreter, Components
 * RETURN:	void
 * SIDE EFFECTS:
 * STRATEGY:	For XIP strings (strings that are in ROM), the RunHeapToken
 *		passed around is actually a pointer and not a DataHandle.
 *		We check if the RunHeapToken is a DataHandle and either
 *		unlock it if it is or do nothing if it is not.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	mchen	6/ 7/95   	Moved here from runheap.h, used to be inline
 *
 ***********************************************************************/
void
LRunHeapUnlock(RunHeapToken token) 
{
    if(theHeapDataMap.ValueIsHandle(token)) {
        /* the token was a handle, do normal unlocking */
        UnlockH(token);
    }
}	/* End of LRunHeapUnlock. */

/*********************************************************************
 *			LRunHeapFree
 *********************************************************************
 * SYNOPSIS:	Free up space for an allocated block
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	11/ 6/95	Initial version
 * 
 *********************************************************************/
void
LRunHeapFree(RunHeapToken token)
{
    byte*	cursor = 0;
    word	structSize = 0;
    Data*	lc = NULL;
    RunHeapToken entry = (RunHeapToken) 0;
    RunHeapToken *stringType = NULL;
    RunHeapEntry *rhe = (RunHeapEntry*)LockH(token);

    switch (rhe->RHE_type) {
     case RHT_COMPLEX:
        /* the Data object is 4-byte aligned, after 2-bytes of  padding 
	   and 4-bytes of RunHeapToken string type */
	stringType = (RunHeapToken*)(rhe+2);
	// check for null token
	if (*stringType == NULL_TOKEN) {
	    break;
        }

	LRunHeapDecRef(*stringType);
	lc = (Data*)(stringType+1);
	if(lc != NULL) {
	    delete lc; 	    /* call virtual destructor for object */
	}
	break;
     case RHT_STRUCT:
	{
	    cursor = (byte*)(rhe+2);
	    structSize = *(word*)(rhe+1);

	    ASSERTS(structSize % 5 == 0, 
		    "error in LRunHeapFree, strucsize%5 != 0");

	    while (structSize > 0) {
		switch (cursor[4]) {
		 case TYPE_RUN_HEAP_CASE:
		    NextDword(cursor, entry);
		    LRunHeapDecRef(entry);
		    break;
		 case TYPE_COMPONENT:
		    NextDword(cursor, entry);
		    if (COMP_IS_AGG(entry)) {
			LRunHeapDecRef(entry);
		    }
		    break;
		} /* switch cursor[4] */
		structSize -= 5; 
		cursor += 5;
	    }

	    /* Remove it from the struct list */
	    StructListRemove(token);

	    break;

	} /* switch */ 
    }

    UnlockH(token);
    FreeH(token);	/* free object itself */
}

/*********************************************************************
 *			LRunHeapIncRef
 *********************************************************************
 * SYNOPSIS:	Increment the reference count of the RunHeap value	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	11/ 6/95	Initial version
 * 
 *********************************************************************/
void 
LRunHeapIncRef(RunHeapToken token) 
{
    /* don't do anything if the token is not a handle
       (XIP string const case) */
    if(theHeapDataMap.ValueIsHandle(token)) {
	RunHeapEntry *entry = (RunHeapEntry*)LockH(token);
	ASSERT(entry);
	ASSERT(entry->RHE_type != RHT_XIP_STRING_CONSTANT);
	entry->RHE_refCount++;
	ASSERTS_WARN(entry->RHE_refCount < 50, 
		     "run heap increment count getting large (>= 50)");
	ASSERT(entry->RHE_refCount != 0);		// check overflow
	UnlockH(token);
    }
}


/*********************************************************************
 *			LRunHeapDecRef
 *********************************************************************
 * SYNOPSIS:  Decrement the ref count. If it hits zero, it will
 *            get freed.
 *              
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	11/ 6/95	Initial version
 * 
 *********************************************************************/
void 
LRunHeapDecRef(RunHeapToken token) {
    /* don't do anything if the token is not a handle
       (XIP string const case) */
    if(theHeapDataMap.ValueIsHandle(token)) {
	RunHeapEntry *entry = (RunHeapEntry*)LockH(token);
	ASSERT(entry);
	ASSERT(entry->RHE_type != RHT_XIP_STRING_CONSTANT);
	ASSERT(entry->RHE_refCount != 0);		// check underflow
	Boolean freeData = FALSE;
	if((--entry->RHE_refCount) == 0) {
	    freeData = TRUE;
	}
	UnlockH(token);	
	if(freeData) {
	    LRunHeapFree(token);		/* free the allocation */
	}
    }
}

/*********************************************************************
 *			LRunHeapDecRefAndUnlock
 *********************************************************************
 * SYNOPSIS:	When a heap block is already locked down and it
 *              needs to have its ref count decreased before it's unlocked,
 *              do everything right here for speed.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	11/ 6/95	Initial version
 * 
 *********************************************************************/
void
LRunHeapDecRefAndUnlock(RunHeapToken token)
{
    /* don't do anything if the token is not a handle
       (XIP string const case) */
    if(theHeapDataMap.ValueIsHandle(token)) {
	RunHeapEntry *entry = (RunHeapEntry*)DerefH(token);
	ASSERT(entry->RHE_type != RHT_XIP_STRING_CONSTANT);
	ASSERT(entry->RHE_refCount != 0);		// check underflow
	Boolean freeData = FALSE;
	if((--entry->RHE_refCount) == 0) {
	    freeData = TRUE;
	}
	UnlockH(token);	
	if(freeData) {
	    LRunHeapFree(token);		/* free the allocation */
	}
    }
}

/***********************************************************************
 *			LRunHeapGetType()
 ***********************************************************************
 * SYNOPSIS:	    Retrieves the type
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	matta	3/11/96	Initial Revision
 *
 ***********************************************************************/
RunHeapType
LRunHeapGetType(RunHeapToken token)
{
    ASSERT(token != NULL_TOKEN);

    if (token == NULL_TOKEN) {
	return (RunHeapType)0x7f;    /* something invalid */
    }

    RunHeapType type;
    RunHeapEntry *entry;
    if (theHeapDataMap.ValueIsHandle(token)) {
	// the token was a handle, do normal locking
	entry = (RunHeapEntry*)LockH(token);
	ASSERT(entry);
	ASSERT(entry->RHE_type != RHT_XIP_STRING_CONSTANT);
        type = entry->RHE_type;
        UnlockH(token);
    } else {
	/* the token was not a handle, we assume that it is a pointer to;
           an XIP run heap value. */
        
        entry = (RunHeapEntry*)token;
        type = entry->RHE_type;

        /* For now, strings are the only thing in XIP */
	ASSERT(entry->RHE_type == RHT_XIP_STRING_CONSTANT);
    }

    return type;

}	/* End of LRunHeapGetType() */

/*********************************************************************
 *			RunHeapGetRefCount
 *********************************************************************
 * SYNOPSIS:	Get the reference count of the runheap entry.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	 4/11/95	Initial version
 * 
 *********************************************************************/
byte
LRunHeapGetRefCount(RunHeapToken token) {
    byte result = 0;
    if(token == NULL_TOKEN) {
	return 0;
    }
    PARAM_ASSERT(token != 0);
    RunHeapEntry *entry;
    if(theHeapDataMap.ValueIsHandle(token)) {
	// the token was a handle, do normal locking
	entry = (RunHeapEntry*)LockH(token);
	result = entry->RHE_refCount;
	UnlockH(token);
    }
    return result;
}

/***********************************************************************
 *			RunHeapEnum()
 ***********************************************************************
 * SYNOPSIS:	 Enumerate through given entries in the runheap
 * CALLED BY:	 EXTERNAL
 * RETURN:	 Nothing
 * SIDE EFFECTS: 
 *
 * STRATEGY:	 Liberty version only enumerates RHT_STRUCT type
 *		 and does this by collection an array of handles
 *		 in LRunHeapAlloc().
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	mchen	5/ 9/96		Initial Revision
 *
 ***********************************************************************/
void
LRunHeapEnum(RunHeapType EC(rht), RunHeapCB callback, void *extra_data)
{
    ASSERTS(rht == RHT_STRUCT, 
	    "Liberty only supports RunHeapEnum for RHT_STRUCT type");
    
    if (theStructListElementCount > 0) {
	ASSERT(theStructListSize > 0);
	ASSERT(theStructListElementCount > 0);
	MemHandle *handleArray = (MemHandle*)LockH(theStructListHandle);
	for (int32 i = 0; i < theStructListElementCount; i++) {
	    if (handleArray[i] != NULL_TOKEN) {
		byte *buffer = (byte*)LRunHeapLock(handleArray[i]);
		word numStructFields = *(word*)(buffer - 2) / 5;
		(*callback)(buffer, numStructFields, extra_data);
		LRunHeapUnlock(handleArray[i]);
	    }
	}
	UnlockH(theStructListHandle);
    }
}	/* End of RunHeapEnum() */

#else   /* GEOS version below */

/* Borland thing */
#ifdef __BORLANDC__
#define MK_FP( seg,ofs )( (void _seg * )( seg ) +( void near * )( ofs ))
#else /*__HIGHC__*/
#define MK_FP( seg,ofs )( (void *)ConstructOptr((void*)seg,(void*)ofs) )
#endif

#include "mystdapp.h"
#include <Legos/basrun.h>
#include <Legos/runheap.h>
#include <vm.h>
#include <Ansi/string.h>
#include <resource.h>
#include "fixds.h"
#include "rheapint.h"
#include "run.h"


/*********************************************************************
 *			RunHeapCreate
 *********************************************************************
 * SYNOPSIS:	Create an empty runtime storage heap
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/ 6/95	Initial version
 * 
 *********************************************************************/
RunHeapInfo RunHeapCreate( void ) 
{
    RunHeapInfo rhi;
    byte i;
    MemHandle	han;

    for (i = 0; i < MAX_HEAP_BLOCKS; i++) 
    {
	rhi.RHI_blockTable[i].HBE_handle   = NullHandle;
	rhi.RHI_blockTable[i].HBE_usedSize = 0;
    }

    /* Now let's create the first one... */

    han = rhi.RHI_blockTable[0].HBE_handle = MemAllocLMem(LMEM_TYPE_GENERAL,0);

    BasrunHandleSetOwner(han);
    MemModifyFlags(han, HF_SHARABLE, 0);

#if ERROR_CHECK
    rhi.RHI_numLocks = 0;
    rhi.RHI_heapLocks = 0;
#endif

    rhi.RHI_lastBlock = 0;

    return rhi;
}

/*********************************************************************
 *			RunHeapDestroy
 *********************************************************************
 * SYNOPSIS:	Kill off our heap. Because this can occur
 *              after a runtime error, we do no work to ensure
 *              that it's not free of garbage...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/ 6/95	Initial version
 * 
 *********************************************************************/
void RunHeapDestroy( RunHeapInfo *rhi) 
{
    word i;

    EC_ERROR_IF(rhi->RHI_numLocks, RE_FAILED_ASSERTION);

    for (i = 0; i < MAX_HEAP_BLOCKS; i++) 
    {
	if (rhi->RHI_blockTable[i].HBE_handle != NullHandle) {
	    MemFree(rhi->RHI_blockTable[i].HBE_handle);
	}

    }
}


/*********************************************************************
 *			RunHeapAlloc
 *********************************************************************
 * SYNOPSIS:	Allocate some space in the heap and optionally
 *              fill it in with some of the hard stuff.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/ 6/95	Initial version
 * 
 *********************************************************************/
RunHeapToken
RunHeapAlloc(RunHeapInfo *rhi, RunHeapType type,
	     byte initRefCount, word size, void *data)
{
    RunHeapEntry entry;
    RunHeapEntry *newdata;
    ChunkHandle  newChunk;
    word         newSize;
    HeapBlockEntry *hbe;
    MemHandle    han;
    word         token;
    Boolean      foundEmptyBlock;
    word         emptyBlock;
    word         fullBlockCount;
    word         currentDesiredMaxBlockSize;
    byte         cacheBlock;

    byte         i, curBlock;

    /* At this point, initRefCount should never be > 1 */
    EC_ERROR_IF(initRefCount > 1, RE_FAILED_ASSERTION);
    EC_BOUNDS(rhi);

    entry.RHE_type     = type;
    entry.RHE_refCount = initRefCount;

#if ERROR_CHECK
    entry.RHE_numLocks = 0;
    entry.RHE_cookie   = RHE_COOKIE_VALUE;

    /* Allocation might shuffle heap blocks, a no-no if the heap is locked
     */
    if (rhi->RHI_heapLocks != 0)
    {
	CFatalError(RE_HEAP_LOCKED_BUT_COULD_MOVE);
    }
#endif

    newSize = size + sizeof(RunHeapEntry);


    /* Allocation algorithm:

       No assumptions are made about where used and unused
       blocks are, leaving open the option in the future of
       coalescing small blocks to free up handles...

       We also assume the max number of heap blocks is small
       enough that a linear traversal isn't too bad a hit.

       Steps to find

       0. Initialize the current desired max block size.

       1. Check each used block, looking for one with enough room
       for the new data. ("Enough room" is based on the current
       desired max block size.)

       2. If we didn't find one, but did find an empty
       unused block, use that one.

       3. Otherwise, we find that each available block is already
       full based on the current maximum size.  This is getting
       dangerous, and in our current scheme means that runtime storage
       is about at least MAX_HEAP_BLOCKS * 4K. 
       (initial threshold is 4K). Anyway, so we don't crash, we
       simply up the threshold and repeat steps 1 & 3 until
       the allocation succeeds.

    */

    hbe = rhi->RHI_blockTable;

    foundEmptyBlock = FALSE;
    currentDesiredMaxBlockSize = DESIRED_MAX_BLOCK_SIZE;

    /* Let's start with the block we used for our last allocation. */

    cacheBlock = rhi->RHI_lastBlock;

    EC_ERROR_IF(cacheBlock >= MAX_HEAP_BLOCKS, RE_FAILED_ASSERTION);

    while (1) {

	fullBlockCount = 0;

	for (i = 0; i < MAX_HEAP_BLOCKS; i++) {

	    /* Essentially cycle through all blocks, starting
	       at our cache block. */

	    curBlock = ( i + cacheBlock) % MAX_HEAP_BLOCKS;
	    
	    if (hbe[curBlock].HBE_handle == NullHandle) 
	    {
		/* While we're looking for an existing block,
		   it can't hurt to keep track of the first
		   empty block available..

		   */

		/*   Note we should only enter here on the
		   first pass through the loop; logic should
		   decide to use up an empty block if the first pass
		   can't find any room. We shouldn't up the
		   acceptable block size until we've used all of
		   our possible blocks.

		*/

		EC_ERROR_IF(currentDesiredMaxBlockSize > 
			    DESIRED_MAX_BLOCK_SIZE, RE_FAILED_ASSERTION);

		if (!foundEmptyBlock) {
		    foundEmptyBlock  = TRUE;
		    emptyBlock = curBlock;
		}
	    }
	    else if( hbe[curBlock].HBE_usedSize + newSize 
		                   < currentDesiredMaxBlockSize) 
	    {
		/* Got it! */
		
		han = hbe[curBlock].HBE_handle;
		
		MemLock(han);
		newChunk = LMemAlloc(han, newSize);

		/* Now see if there is room to encode this chunk;
		   perform the inverse of the key->chunkhandle mapping
		   and see if it overlaps with the segment mask. 
		   If yes, then there's no more room in this segment
		   for any more entries */

		if ((CHUNK_TO_BKEY(newChunk) & TOKEN_SEG_MASK) != 0) 
		{
		    /* Too many chunks in this block! Free it
		       and act as if this block is full...
		       */
		    LMemFreeHandles(han, newChunk);
		    MemUnlock(han);
		    
		    /* Keep track of number of full blocks.
		       If they're all full we are completely hosed
		       and must give up! 
		    */

		    fullBlockCount++;
		    continue;
		}

		goto FILLERUP;

	    }
	}

	/* The first time through, we may have (and hopefully did)
	   find an empty block somewhere if all of the used blocks
	   are already too big.  So use it! */

	if (foundEmptyBlock) {

	    /* This can only happen during our first pass.. */

	    EC_ERROR_IF(currentDesiredMaxBlockSize > DESIRED_MAX_BLOCK_SIZE,
			RE_FAILED_ASSERTION);
	    EC_ERROR_IF(hbe[emptyBlock].HBE_handle != NullHandle ||
			hbe[emptyBlock].HBE_usedSize != 0,
			RE_FAILED_ASSERTION);

	    han  = MemAllocLMem(LMEM_TYPE_GENERAL,0);
	    if (han == NullHandle)
	    {
		newChunk = NullHandle;
		goto FILLERUP;
	    }

	    EC_ERROR_IF(han == NullHandle, RE_FAILED_ASSERTION);
	    BasrunHandleSetOwner(han);
	    MemModifyFlags(han, HF_SHARABLE, 0);

	    hbe[emptyBlock].HBE_handle = han;

	    /* han, newChunk, and curBlock are the three "args" to FILLERUP */

	    MemLock(han);
	    newChunk = LMemAlloc(han, newSize);
	    curBlock = emptyBlock;

	    goto FILLERUP;
	    
	}

	if (fullBlockCount == MAX_HEAP_BLOCKS) 
	{
	    /* This is a massive fatal error. It means
	       that we ran out of handles that we can use;
	       no more chunk handles in _each_ of our blocks.
	       Pretty unlikely, but catch it none-the-less....
	    */
	    newChunk = NullHandle;
	    goto FILLERUP;
	}

	currentDesiredMaxBlockSize += DESIRED_MAX_BLOCK_SIZE;
    }


 FILLERUP:

    /* Actually fill in the entry.

       "Takes" chunkhandle in newChunk,
               dest lmem heap in han (assumed locked),
	       block number in curBlock
    */

    /* if we couldn't allocate a newChunk for some reason, just return
     * a Null Token
     */
    if (newChunk == NullHandle)
    {
	if (han != NullHandle) {
	    MemUnlock(han);
	}
	return NULL_TOKEN;
    }

    newdata = LMemDerefHandles(han, newChunk);
    
    *newdata = entry;

    if (data != NULL) 
    {
	EC_BOUNDS(data);
	memcpy(newdata+1, data, size);
    }
    
    MemUnlock(han);

    rhi->RHI_lastBlock = curBlock;

    hbe[curBlock].HBE_usedSize += newSize;
    
    token = CONSTRUCT_TOKEN(curBlock, CHUNK_TO_BKEY(newChunk));
    
    return token;
}

/*********************************************************************
 *			RunHeapFree
 *********************************************************************
 * SYNOPSIS:	Free up space for a block
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * 	Currently, once an lmem block has been created in the global
 * 	heap, it doesn't disappear until the entire heap disappears.
 *
 * 	I don't think this is too big a problem; we rely on the lmem
 * 	compaction to make the heap have negligible size, and then
 * 	the only loss becomes a handle. Oh well...
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/ 6/95	Initial version
 * 
 *********************************************************************/
void
RunHeapFree(RunHeapInfo *rhi, RunHeapToken token)
{
    byte	seg;
    MemHandle	memHan;
    ChunkHandle	chunkHan;
    word	size;
    RunHeapEntry* rhe;
    HeapBlockEntry* hbe;

    EC_BOUNDS(rhi);
    hbe = rhi->RHI_blockTable;

    seg      = TOKEN_SEG(token);
    memHan   = hbe[seg].HBE_handle;
    chunkHan = TOKEN_TO_CHUNK(token);

    MemLock(memHan);

    size = LMemGetChunkSizeHandles(memHan, chunkHan);
    hbe[seg].HBE_usedSize -= size;

    rhe = LMemDerefHandles(memHan, chunkHan);
    switch (rhe->RHE_type) {
    case RHT_COMPLEX:
    {
	LegosComplex*	lc = (LegosComplex*)(rhe+1);
	VMFreeVMChain(lc->LC_vmfh, lc->LC_chain);
	break;
    }
    case RHT_STRUCT:
    {
	byte*	cursor = (byte*)(rhe+1);
	word	structSize;


	for (structSize = size-sizeof(RunHeapEntry);
	     structSize > 0;
	     structSize -= 5, cursor += 5)
	{
	    EC_ERROR_IF(structSize%5 != 0, RE_FAILED_ASSERTION);
	    switch (cursor[4]) {
	    case TYPE_RUN_HEAP_CASE:
	    {
		RunHeapDecRef(rhi, *(word*)cursor);
		break;
	    }
	    case TYPE_COMPONENT:
	    {
		dword	dw;
		dw = *(dword*)cursor;
		if (COMP_IS_AGG(dw)) RunHeapDecRef(rhi, dw);
		break;
	    }
	    } /* switch cursor[4] */
	}
	break;
    }

    } /* switch */

    LMemFreeHandles(memHan, chunkHan);
    MemUnlock(memHan);
}


/*********************************************************************
 *			RunHeapIncRef
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/ 6/95	Initial version
 * 
 *********************************************************************/
void RunHeapIncRef(RunHeapInfo *rhi, RunHeapToken token) 
{
    void *data;

    if (!token) return;

    EC_BOUNDS(rhi);
    RunHeapLock(rhi, token, &data);

    EC_ERROR_IF(RHE_COOKIE(data) != RHE_COOKIE_VALUE, RE_FAILED_ASSERTION);

    RHE_INCREF(data);

    RunHeapUnlock(rhi, token);
}


/*********************************************************************
 *			RunHeapDecRef
 *********************************************************************
 * SYNOPSIS:  Decrement the ref count. If it hits zero, it will
 *            get freed.
 *              
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/ 6/95	Initial version
 * 
 *********************************************************************/
void RunHeapDecRef(RunHeapInfo *rhi, RunHeapToken token) 
{
    void *data;
    Boolean freeData = FALSE;

    if (!token)
	return;

    EC_BOUNDS(rhi);
    RunHeapLock(rhi, token, &data);
    EC_ERROR_IF(RHE_COOKIE(data) != RHE_COOKIE_VALUE, RE_FAILED_ASSERTION);

    /* Reference counts are useless for the zero element, since
       it's a null string and gains uncntrolled numbers of references...
    */

    EC_ERROR_IF((RHE_REFCOUNT(data) == 0), RE_FAILED_ASSERTION);
    RHE_DECREF(data);

    if (!RHE_REFCOUNT(data)) {
	freeData = TRUE;
    }

    RunHeapUnlock(rhi, token);

    if (freeData) {
	RunHeapFree(rhi, token);
    }
}

/***********************************************************************
 *			RunHeapDataSize()
 ***********************************************************************
 * SYNOPSIS:	    get size of data in RunHeapToken
 * CALLED BY:	    GLOBAL
 * RETURN:	    size in bytes of data
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JL	7/10/96  	Initial Revision
 *
 ***********************************************************************/
word
RunHeapDataSize(RunHeapInfo *rhi, RunHeapToken token)
{
    byte	    seg;
    MemHandle	    memHan;
    HeapBlockEntry *hbe;
    ChunkHandle	    chunkHan;
    word	    size;

    EC_BOUNDS(rhi);
    hbe = rhi->RHI_blockTable;

    seg      = TOKEN_SEG(token);
    memHan   = hbe[seg].HBE_handle;
    chunkHan = TOKEN_TO_CHUNK(token);

    MemLock(memHan);
    size = LMemGetChunkSizeHandles(memHan, chunkHan) - sizeof(RunHeapEntry);
    MemUnlock(memHan);
    return size;
}	/* End of RunHeapDataSize() */


/*********************************************************************
 *			RunHeapLockExternal
 *********************************************************************
 * SYNOPSIS:	Lock down data within the runtime heap.
 *              Fill in data pointer with pointer to heap data.
 *              
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/ 6/95	Initial version
 * 
 *********************************************************************/
void
RunHeapLockExternal(RunHeapInfo *rhi, RunHeapToken token, void **data)
{
    byte seg;
    MemHandle memHan;
    HeapBlockEntry *hbe;
    ChunkHandle chunkHan;
    word oldDS;

    oldDS = setDSToDgroup();


    EC_BOUNDS(rhi);
    hbe = rhi->RHI_blockTable;

    seg      = TOKEN_SEG(token);
    memHan   = hbe[seg].HBE_handle;
    chunkHan = TOKEN_TO_CHUNK(token);

    MemLock(memHan);

    EC(ECCheckLMemODHandles(memHan, chunkHan);)
    *data = ( (RunHeapEntry*) LMemDerefHandles(memHan, chunkHan)) + 1;

    EC_BOUNDS(data);
    
    EC_ERROR_IF(RHE_COOKIE(*data) != RHE_COOKIE_VALUE, RE_FAILED_ASSERTION);

    EC_ERROR_IF(RHE_NUMLOCKS(*data) == 255, RE_FAILED_ASSERTION);
    EC_ERROR_IF(rhi->RHI_numLocks == 255, RE_FAILED_ASSERTION);

#if ERROR_CHECK
    RHE_NUMLOCKS(*data)++;
    rhi->RHI_numLocks++;
#endif
    restoreDS(oldDS);
}

/*********************************************************************
 *			RunHeapDerefExternal
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/11/95	Initial version
 * 
 *********************************************************************/
void*
RunHeapDerefExternal(RunHeapInfo *rhi, RunHeapToken token)
{
    void *data;
    byte seg;
    MemHandle memHan;
    HeapBlockEntry *hbe;
    ChunkHandle chunkHan;
    word oldDS;

    oldDS = setDSToDgroup();


    EC_BOUNDS(rhi);
    hbe      = rhi->RHI_blockTable;

    seg      = TOKEN_SEG(token);
    memHan   = hbe[seg].HBE_handle;
    chunkHan = TOKEN_TO_CHUNK(token);
    EC(ECCheckLMemODHandles(memHan, chunkHan);)

    MemLock(memHan);             // EC code says block must be locked
    data = ( (RunHeapEntry*) LMemDerefHandles(memHan, chunkHan)) + 1;
    MemUnlock(memHan);

    EC_ERROR_IF(RHE_COOKIE(data) != RHE_COOKIE_VALUE, RE_FAILED_ASSERTION);

    restoreDS(oldDS);
    return data;
}

/*********************************************************************
 *			RunHeapUnlockExternal
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/ 6/95	Initial version
 * 
 *********************************************************************/
void
RunHeapUnlockExternal(RunHeapInfo *rhi, RunHeapToken token)
{

    byte seg;
    MemHandle memHan;
    HeapBlockEntry *hbe;
    word oldDS;

    oldDS = setDSToDgroup();


    EC_BOUNDS(rhi);
    hbe = rhi->RHI_blockTable;

    seg      = TOKEN_SEG(token);
    memHan   = hbe[seg].HBE_handle;

#if ERROR_CHECK
    ;{
	ChunkHandle chunkHan;
	void *data;

	chunkHan = TOKEN_TO_CHUNK(token);
	EC(ECCheckLMemODHandles(memHan, chunkHan);)

	data = ( (RunHeapEntry*) LMemDerefHandles(memHan, chunkHan)) + 1;

	EC_ERROR_IF(RHE_COOKIE(data) != RHE_COOKIE_VALUE, RE_FAILED_ASSERTION);

	EC_ERROR_IF(RHE_NUMLOCKS(data) == 0, RE_FAILED_ASSERTION);
	EC_ERROR_IF(rhi->RHI_numLocks == 0, RE_FAILED_ASSERTION);
    
	RHE_NUMLOCKS(data)--;
	rhi->RHI_numLocks--;
    }
#endif

    MemUnlock(memHan);
    restoreDS(oldDS);
}

/*********************************************************************
 *			RunHeapDecRefAndUnlockExternal
 *********************************************************************
 * SYNOPSIS:	When a heap block is already locked down and it
 *              needs to have its ref count decreased before it's unlocked,
 *              do everything right here for speed.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/15/95	Initial version
 * 
 *********************************************************************/
void
RunHeapDecRefAndUnlockExternal(RunHeapInfo *rhi, RunHeapToken token,
			       void *data)
{
    Boolean zero = FALSE;
    word oldDS;

    oldDS = setDSToDgroup();


    EC_ERROR_IF(RHE_COOKIE(data) != RHE_COOKIE_VALUE, RE_FAILED_ASSERTION);

    if (token) {
	RHE_DECREF(data);
    }

    if (!RHE_REFCOUNT(data)) {
	zero = TRUE;
    }

    RunHeapUnlock(rhi, token);

    if (zero) {

	RunHeapFree(rhi, token);
    }

    restoreDS(oldDS);
}

/*********************************************************************
 *			ECRunHeapLockHeap
 *********************************************************************
 * SYNOPSIS:	"Lock" the heap.  This asserts that no locked heap
 *		entries are allowed to move; heap code will fatal error
 *		if a heap block might be moved (such as on an allocation)
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 8/ 4/95	Initial version
 * 
 *********************************************************************/
#pragma argsused
void
ECRunHeapLockHeap(RunHeapInfo* rhi)
{
#if ERROR_CHECK
    if (++rhi->RHI_heapLocks == 0)
    {
	CFatalError(-1);	/* Too many heap locks; better change
				 * RHI_heapLocks to a word
				 */
    }
#endif
}

/*********************************************************************
 *			ECRunHeapUnlockHeap
 *********************************************************************
 * SYNOPSIS:	"Unlock" the heap.  See comments in ECRunHeapLockHeap.
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 8/ 4/95	Initial version
 * 
 *********************************************************************/
void
ECRunHeapUnlockHeap(RunHeapInfo* rhi)
{
#if ERROR_CHECK
    if (rhi->RHI_heapLocks-- == 0)
    {
	CFatalError(-1);	/* Underflow */
    }
#endif
}

/*********************************************************************
 *			RunHeapEnum
 *********************************************************************
 * SYNOPSIS:	Enumerate through given entries in the runheap
 * CALLED BY:	EXTERNAL
 * RETURN:	Nothing
 * SIDE EFFECTS:
 * STRATEGY:
 *	NOTE! This is not really a full-featured enum
 *	in particular, the size parameter really measures the
 *	number of struct fields.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	5/ 6/96  	Initial version
 * 
 *********************************************************************/
void
RunHeapEnum(RunHeapInfo* rhi, RunHeapType rht,
	    RunHeapCB callback, void* extra_data)
{
    MemHandle	heap_block;
    word	i, j;

#ifdef __BORLANDC__
    LMemBlockHeader _seg* lmbh;
#else /*__HIGHC__*/
    LMemBlockHeader * lmbh;
#endif
    ChunkHandle*	chunks;
    RunHeapEntry*	rhe;
    byte*		data;

    for (i=0; i<MAX_HEAP_BLOCKS; i++)
    {
	heap_block = rhi->RHI_blockTable[i].HBE_handle;
	if (heap_block == NullHandle) continue;

#ifdef __BORLANDC__
	lmbh = (LMemBlockHeader _seg*)MemLock(heap_block);
#else  /*__HIGHC__*/
	lmbh = (LMemBlockHeader *)MemLock(heap_block);
#endif
	chunks = (ChunkHandle*)MK_FP(lmbh, lmbh->LMBH_offset);

	for (j=0; j<lmbh->LMBH_nHandles; j++, chunks++)
	{
	    word	chunkOffset;

	    /* 0 means unused, -1 means no data */
	    chunkOffset = *chunks;
	    if (chunkOffset == 0 || chunkOffset == -1) continue;
	    
	    rhe = MK_FP(lmbh, chunkOffset);
	    EC_ERROR_IF(rhe->RHE_cookie != RHE_COOKIE_VALUE,
			RE_FAILED_ASSERTION);

	    if (rhe->RHE_type == rht)
	    {
		sword	size;

		size = LMemGetChunkSizePtr(rhe) - sizeof(RunHeapEntry);
		EC_ERROR_IF(size % 5 != 0, RE_FAILED_ASSERTION);
		data = (byte*)(rhe+1);
		ProcCallFixedOrMovable_cdecl(callback, data, size/5,
					     extra_data);
	    }
	}
	MemUnlock(heap_block);
    }
}

#endif /* GEOS STUFF */
