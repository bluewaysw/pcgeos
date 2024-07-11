/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	LEGOS
MODULE:		basrun
FILE:		strmap.c

AUTHOR:		Roy Goldman, Jun  7, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 6/ 7/95   	Initial version.

DESCRIPTION:
	
        Runtime string constant access layer.
	This data structure allows us to map compile-time
	string constants into the heap-tokens which identify
	where these strings are at runtime.


	Liberty version control
	$Id: strmap.c,v 1.2 98/10/05 12:39:16 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/strmap.h>
#include <Legos/fixds.h>
#include <pos/ramalloc.h>   	/* For GetAllocatedSize() */
#else
#include "mystdapp.h"
#include <Ansi/string.h>
#include "strmap.h"
#include "fixds.h"
#include "rheapint.h"

#endif

/* Size of table when we create it. Keep it small.
   Unfortunately at creation time we don't really know
   how big the table will be (since we add two different
   string tables... If we could determine that easily, 
   maybe even store that in compiled code, then the map
   could be created directly with the final size...
*/

#define CREATION_SIZE 30


#ifdef LIBERTY
/*********************************************************************
 *			StrMapCreate
 *********************************************************************
 * SYNOPSIS:	Create a string map, used to map string constant numbers
 *              into global heap tokens at runtime....
 * CALLED BY:	GLOBAL (BascoInitRTaskFromCTask, RunAllocTask)
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	 7/17/95	Initial version
 *	mchen	11/ 6/95	Changed to use handles
 * 
 *********************************************************************/
MemHandle
StrMapCreate(word size) 
{
    MemHandle result = MemAlloc((sizeof(RunHeapToken) * size) + 
			       	sizeof(StrMapHeader), NULL, HAF_ZERO_INIT);
    if (result) {
	StrMapHeader *header = (StrMapHeader*)LockH(result);
	EC(theHeap.SetTypeAndOwner(header, "SMAP", (Geode*)0));
	header->size = size;    /* maximum number of entries in the table */
	UnlockH(result);
    }
    return result;
}
#else
/*********************************************************************
 *			StrMapCreate
 *********************************************************************
 * SYNOPSIS:	Create a string map, used to map string constant numbers
 *              into global heap tokens at runtime....
 * CALLED BY:   GLOBAL (BascoInitRTaskFromCTask, RunAllocTask)	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/15/95	Initial version
 * 
 *********************************************************************/
MemHandle StrMapCreate(void) {
    MemHandle mh;
    SET_DS_TO_DGROUP;
    StrMapHeader *smh;

    /* Start out with just a small number of strings to
       keep ram usage down if not needed.
    */

    mh = MemAlloc((sizeof(RunHeapToken) * CREATION_SIZE) +
		    sizeof(StrMapHeader),
		    HF_SWAPABLE | HF_SHARABLE, HAF_ZERO_INIT);

    if (mh == NullHandle) return mh;
    smh = (StrMapHeader*) MemLock(mh);

    /* These 2 are free from 0-init 
       smh->SMH_count = 0;
       smh->SMH_next = NullHandle;
       */

    smh->SMH_blockSpace = CREATION_SIZE;
    MemUnlock(mh);

    RESTORE_DS;
    return mh;
}
#endif

#ifdef LIBERTY
/*********************************************************************
 *			StrMapDestroy
 *********************************************************************
 * SYNOPSIS:	Decref every block on the strmap
 * CALLED BY:	RunDestroyTask
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	 5/07/96	Initial version
 * 
 *********************************************************************/
void StrMapDestroy(MemHandle strMap) 
{
    if (strMap) {
	ASSERT(theHeapDataMap.ValueIsHandle(strMap));
	StrMapHeader *header = (StrMapHeader*)LockH(strMap);
	RunHeapToken *tableEntry = (RunHeapToken *)(header + 1);
	word i;

	ASSERT(header->count <= header->size);

	for(i = 0; i < header->count; i++) {
	    if (tableEntry[i] != NULL_TOKEN) {
		LRunHeapDecRef(tableEntry[i]);
	    }
	}

	UnlockH(strMap);
	FreeH(strMap);
    }
}
#else	/* GEOS version below */

/*********************************************************************
 *			StrMapDestroy
 *********************************************************************
 * SYNOPSIS:	Recursive destruction of all blocks in the table...
 * CALLED BY:	RunDestroyTask, RunNullRTaskCode
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/15/95	Initial version
 * 
 *********************************************************************/
void StrMapDestroy(MemHandle strMap) {

    StrMapHeader *smh;
    MemHandle     next;

    smh = (StrMapHeader*) MemLock(strMap);

    next = smh->SMH_nextHandle;

    MemUnlock(strMap);

    if (next != NullHandle) {

	StrMapDestroy(next);
    }

    MemFree(strMap);
}
#endif

#ifdef LIBERTY
/*********************************************************************
 *			LStrMapAdd
 *********************************************************************
 * SYNOPSIS:	Add a string to the string map.
 *              Currently the heap can hold <= the number
 *              of entries in this table, so rely on table
 *              to fatal error first....
 * CALLED BY:	GLOBAL, BascoInitRtaskFromCtask, Page_ParseHeader
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:    This should only be called when loading a DLL application.
 *		We copy the strings for now.
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	 7/17/95	Initial version
 *	mchen	11/ 6/95	Changed to use handles
 * 
 *********************************************************************/
Boolean
LStrMapAdd(MemHandle strMap, TCHAR *str) 
{
    ASSERT(theHeapDataMap.ValueIsHandle(strMap));
    RunHeapToken *tableEntry;
    StrMapHeader *header = (StrMapHeader*)LockH(strMap);
    word i = header->count, len;

    ASSERT(i < header->size);

    tableEntry = (RunHeapToken *)(header+1);
    // if its an empty string use NULL_TOKEN as optimization
    len = strlen(str);
    if (len) {
      // its not an emptry string to allocate a RunHeapToken
      tableEntry[i] = LRunHeapAlloc(RHT_DLL_STRING_CONSTANT, 1, 
				    (len+1)*sizeof(TCHAR), str);
      // allocation failed, so return FALSE
      if(tableEntry[i] == NULL_TOKEN) {
	UnlockH(strMap);
	return FALSE;
      }
    } else {
      // use NULL_TOKEN for empty strings
      tableEntry[i] = NULL_TOKEN;
    }
    header->count++;
    UnlockH(strMap);
    return TRUE;
}
#else
/*********************************************************************
 *			StrMapAdd
 *********************************************************************
 * SYNOPSIS:	Add a string to the string map.
 *              Currently the heap can hold <= the number
 *              of entries in this table, so rely on table
 *              to fatal error first....
 * CALLED BY:	GLOBAL, BascoInitRtaskFromCtask, Page_ParseHeader
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/15/95	Initial version
 * 
 *********************************************************************/
Boolean StrMapAdd(MemHandle strMap, RunHeapInfo *rhi, TCHAR *str) {

    word i;
    StrMapHeader *smh;
    RunHeapToken *tokenPtr;
    MemHandle next;

    while(1) 
    {
	word quot;
	word blockSpace;

	smh = (StrMapHeader*) MemLock(strMap);
	i = smh->SMH_count;
	blockSpace = smh->SMH_blockSpace;

	EC_ERROR_IF( i > MAX_STRINGS_PER_BLOCK, RE_FAILED_ASSERTION);

	/* Check if we need to make the block grow... */
	if (i == blockSpace) {

	    MemUnlock(strMap);

	    /* Double the space, up to MAX block */

	    blockSpace *= 2;

	    if (blockSpace > MAX_STRINGS_PER_BLOCK)
		blockSpace = MAX_STRINGS_PER_BLOCK;

	    if (MemReAlloc(strMap, 
			   (sizeof(RunHeapToken) * blockSpace)
			   + sizeof(StrMapHeader),
			   0) == NullHandle)
	    {
		/* MemRealloc Failed */
		return FALSE;
	    }
	    smh = (StrMapHeader*) MemLock(strMap);
	    smh->SMH_blockSpace = blockSpace;
	}


	if (i < MAX_STRINGS_PER_BLOCK) 
	{
	    tokenPtr = (RunHeapToken*) &smh[1];
	    EC_BOUNDS(&tokenPtr[i]);
	    tokenPtr[i] = RunHeapAlloc(rhi, RHT_STRING, 1, 
				       (strlen(str) + 1) * sizeof(TCHAR),
				       str);
	    smh->SMH_count++;
	    MemUnlock(strMap);
	    break;
	}
	 
	next = smh->SMH_nextHandle;

	if (next == NullHandle) 
	{
	    next = smh->SMH_nextHandle = MemAlloc((sizeof(RunHeapToken) *
						   CREATION_SIZE) + 
						  sizeof(StrMapHeader),
						  HF_SWAPABLE | HF_SHARABLE,
						  HAF_ZERO_INIT | HAF_LOCK);
	    if (next == NullHandle) return FALSE;
	    smh = MemDeref(next);
	    smh->SMH_blockSpace = CREATION_SIZE;
	    MemUnlock(next);
	}
	    
	MemUnlock(strMap);
	strMap = next;
    }

    return TRUE;
}
#endif
	    

/*********************************************************************
 *			StrMapLookup
 *********************************************************************
 * SYNOPSIS:	Translate a string number into its position in the
 *              global heap.
 * CALLED BY:	Interpreter when dealing with compile-time string constants
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/15/95	Initial version
 * 
 *********************************************************************/
RunHeapToken StrMapLookup(MemHandle strMap, word mapKey) {
#ifdef LIBERTY
    if(theHeapDataMap.ValueIsHandle(strMap)) {
	StrMapHeader *smh = (StrMapHeader*)LockH(strMap);
	RunHeapToken *table = (RunHeapToken*)(smh+1);
	RunHeapToken result = table[mapKey];
	UnlockH(strMap);
	return result;
    }
    else {
	RunHeapToken *table = (RunHeapToken*)(strMap + sizeof(StrMapHeader));
	return table[mapKey];
    }
#else	/* GEOS version below */
    
    StrMapHeader *smh;
    RunHeapToken *tokenPtr;
    RunHeapToken token;
    MemHandle next;

    while (1) {

	smh = (StrMapHeader*) MemLock(strMap);

	EC_ERROR_IF(smh->SMH_count > MAX_STRINGS_PER_BLOCK,
		    RE_FAILED_ASSERTION);
	
	if (mapKey < MAX_STRINGS_PER_BLOCK)
	{
	    /* Found the right block. GET IT! */
	    EC_BOUNDS(smh);
	    tokenPtr = (RunHeapToken*) &smh[1];
	    EC_BOUNDS(tokenPtr+mapKey);
	    EC_BOUNDS(tokenPtr+smh->SMH_count);
    	    token = tokenPtr[mapKey];
	    MemUnlock(strMap);
	    return token;
	}
	    
	next = smh->SMH_nextHandle;
	EC_ERROR_IF(next == NullHandle, RE_FAILED_ASSERTION);
	MemUnlock(strMap);
	strMap = next;
	mapKey -= MAX_STRINGS_PER_BLOCK;
	
    }
#endif
}


/*********************************************************************
 *			StrMapGetCount
 *********************************************************************
 * SYNOPSIS:	Count the number of entries in the map.
 *              Only use I can think of right now is 
 *              for EC, to make sure that a runtask map is empty
 *              before conversion from a huge array (or loading from
 *              a compiled file) begins..
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
word StrMapGetCount(MemHandle strMap) {
#ifdef LIBERTY
    word count = ((StrMapHeader*)LockH(strMap))->count;
    UnlockH(strMap);
    return count;
#else	/* GEOS version below */

    word count = 0;
    StrMapHeader *smh;
    MemHandle next;

    SET_DS_TO_DGROUP;

    while (strMap != NullHandle) {
	smh = (StrMapHeader*) MemLock(strMap);
	count += smh->SMH_count;
	next = smh->SMH_nextHandle;
	MemUnlock(strMap);
	strMap = next;
    }

    RESTORE_DS;
    return count;
#endif
}

#ifdef LIBERTY
/*********************************************************************
 *			StrMapGetMemoryUsedBy
 *********************************************************************
 * SYNOPSIS:	Get the amount of memory used by this strmap
 * CALLED BY:	FunctionGetMemoryUsedBy()
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	 7/25/96	Initial version
 * 
 *********************************************************************/
dword 
StrMapGetMemoryUsedBy(MemHandle strMap) {
    if(theHeapDataMap.ValueIsHandle(strMap)) {
	StrMapHeader *header = (StrMapHeader*)LockH(strMap);
	dword totalSize = theHeap.GetAllocatedSize(header);
	RunHeapToken *table = (RunHeapToken*)(header+1);
	for(int i = 0; i < header->count; i++) {
	    void *runHeapBlock = (void*)LockH(table[i]);
	    totalSize += theHeap.GetAllocatedSize(runHeapBlock);
	    UnlockH(table[i]);
	}
	UnlockH(strMap);
	return totalSize;
    }
    return 0;
}	/* End of StrMapGetMemoryUsedBy() */
#endif
