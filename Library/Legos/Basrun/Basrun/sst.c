/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Tiny string tables
FILE:		sst.c

AUTHOR:		Paul L. DuBois, May 15, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 5/15/95   	Initial version.
	mchen	 7/17/95    	

DESCRIPTION:
	These string tables fit in one lmem heap.
	These tables are designed to convert a string into a word.
	Internally, the lookup is sped up by using a hash table.


	Liberty version control
	$Id: sst.c,v 1.2 98/10/05 12:38:51 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifdef LIBERTY
#include <Ansi/string.h>
#include <Legos/interp.h>
#include <Legos/fixds.h>
#include <Legos/sst.h>
#include <pos/ramalloc.h>   	    /* for GetAllocatedSize() */

typedef int (ComparisonFunc)(void *arg1, void *arg2);

int32 BinarySearch(void **array, void *target, 
		   ComparisonFunc *compare, uint32 arraySize);

extern "C" {
/*
 * I'm not sure if it is CFront or just this GHS version of CFront
 * that defines rand as long (instead of int), but as we have an
 * easy check for toolset I'm going to go with a "TOOSET_ghs"
 * conditional, instead of the some other generic "cfront" check.
 */
#ifdef TOOSET_ghs
    long rand();
#else
    int rand();
#endif
}

#else	/* GEOS version below */

#include "mystdapp.h"
#include <lmem.h>
#include <chunkarr.h>
#include <Ansi/string.h>
#include "fixds.h"
#include "sst.h"

static word _pascal SSTHash(dword, SSTHeader*);
static Boolean _pascal SSTCompare(dword, dword, SSTHeader*);

#endif


#ifdef LIBERTY
/***********************************************************************
 *			Swap
 ***********************************************************************
 * SYNOPSIS:	    
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	mchen	2/13/96	Initial Revision
 *
 ***********************************************************************/
void
Swap (uint16 *array, int32 index1, int32 index2) 
{
    uint16 tmp = array[index1];
    array[index1] = array[index2];
    array[index2] = tmp;
}	/* End of Swap.	*/

/***********************************************************************
 *			QuickSort
 ***********************************************************************
 * SYNOPSIS:	    
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	mchen	2/13/96	Initial Revision
 *
 ***********************************************************************/
void
QuickSort (uint16 *array, int32 lower, int32 upper)
{
    if (lower < upper) {
        // compute a random index between lower and upper
        uint32 randIndex = lower + (rand() % (upper - lower + 1));

        // swap array[lower] with a array[randIndex]
        Swap(array, lower, randIndex);

        int32 tmpIndex = lower;
        int32 middle = lower;

        for(int32 i = lower + 1; i <= upper; i++) {
	    TCHAR *target1 = (TCHAR*)(((byte*)array) + array[i]);
	    TCHAR *target2 = (TCHAR*)(((byte*)array) + array[tmpIndex]);
            if(strcmp(target1, target2) < 0) {
                middle++;
                Swap(array, middle, i);
            }
        }
        Swap(array, lower, middle);
        QuickSort(array, lower, middle - 1);
        QuickSort(array, middle + 1, upper);
    }
}	/* End of QuickSort.	*/


/*********************************************************************
 *			SSTAlloc
 *********************************************************************
 * SYNOPSIS:	Create a small string table given the number of strings,
 *		a pointer to the beginning of the page, and a pointer to
 *		the starting offset in the page (the byteStream).
 * CALLED BY:	RunAllocTask()
 * RETURN:	handle to a small string table
 * SIDE EFFECTS:  Allocates memory for a small string table
 * STRATEGY:	The SST will consist of one blocks of movable memory.
 *              The beginning of the block is a table that is a sorted array
 *		of offsets into the block (like a variable darray).  After
 *	    	the table are the strings themselves, packed together.  
 *	    	Doing it this way saves memory since otherwise every string
 *	    	would have malloc overhead (or movable block overhead).
 *		The given string block is copied so that the header page
 *		can be deleted.
 *		
 *	    	Still assumes that byteStream[pos] is 2-byte aligned so
 *		that we can do comparisons faster.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	 7/17/95	Initial version
 *	mchen	 8/15/95	Moved the dword count to the end and
 *				add numBuckets after the count
 *	mchen	11/ 7/95    	Changed to use handles
 *	mchen	01/29/96	Complete re-write to use a binary search
 *				on a sorted array of strings instead of
 *				a hash table
 *	mchen	04/02/96	Changed to copy from the header page.
 *      jon     3 may 96        Added the unsorted offset array after
 *                              the sorted one to make SSTDeref easier.
 *      matta   10/15/96	Alloc error sets *startPos <- 0xffff
 *	dubois	11/26/96	Remove jon's modification, since bcl2c
 *				generates tables the old way
 *********************************************************************/
ChunkHandle
LSSTAlloc(uint16 numStrings, byte *byteStream, uint16 *startPos)
{
    if(numStrings == 0) {
	return NULL;
    }
    int i, pos = 0;
    TCHAR *stringStart = (TCHAR*)&byteStream[*startPos];
    ASSERTS(((uint32)stringStart & 0x1) == 0, "DBCS string not 2-byte aligned");

    // Determine how many byte needed for string storage
    for(i = 0; i < numStrings; i++) {
	// find the index for the string at the end of it, doing a
	// endian reversal if needed 
#if ARCH_BIG_ENDIAN
        /* since the code is default as little endian, we need to convert
           the string to the right format, we will do this in place. */
        while(stringStart[pos] != '\0') {
            byte *tmpPtr = (byte*)&stringStart[pos];
            byte tmp = *tmpPtr;
            *tmpPtr = *(tmpPtr+1);
            *(tmpPtr+1) = tmp;
	    pos++;
        }
	/* also reverse the endianness of the index number */
	pos++;
	byte *tmpPtr = (byte*)&stringStart[pos++];
	byte tmp = *tmpPtr;
	*tmpPtr = *(tmpPtr+1);
	*(tmpPtr+1) = tmp;
#else
	pos += strlen(&stringStart[pos]) + 2;
#endif
    }

    // malloc the block of memory, first the table is 
    // numStrings * sizeof(TCHAR**), then the additional memory needed for
    // storing the strings themselves
    uint32 blockSizeNeeded = (numStrings * sizeof(uint16)) + 
	    	    	     (pos * sizeof(TCHAR));
    // since we are using uint16 offsets, we need to check that this table
    // is not too large
    ASSERTS(blockSizeNeeded < 65535, "Small String Table (SST) too large!");
    MemHandle result = MallocH(blockSizeNeeded);
    if(result == NULL) {
	*startPos = 0xffff;	/* signal error */
	return NULL;
    }
    uint16 *stringOffsetArray = (uint16*)LockH(result);
    EC(theHeap.SetTypeAndOwner(stringOffsetArray, "SST", (Geode*)0);)
    TCHAR *stringStorage = (TCHAR*)(stringOffsetArray +  numStrings);

    // now copy the strings into the block
    memcpy(stringStorage, stringStart, pos * sizeof(TCHAR));

    // now fill in the table
    for(i = 0; i < numStrings; i++) {
	stringOffsetArray[i] =
	    ((uint32)stringStorage - (uint32)stringOffsetArray);

	// increment by length plus 1 for '\0' and 1 for index word
	stringStorage += strlen(stringStorage) + 2;	
    }

    // now sort the table
    QuickSort(stringOffsetArray, 0, numStrings - 1);
    UnlockH(result);
    *startPos += (pos * sizeof(TCHAR));
    return result;
}
#else
/*********************************************************************
 *			SSTAlloc
 *********************************************************************
 * SYNOPSIS:	Create a tiny string table
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/15/95	Initial version
 * 
 *********************************************************************/
ChunkHandle
SSTAlloc(MemHandle lmemBlock)
{
    ChunkHandle	stringArray;
    ChunkHandle	hash;
    SSTHeader*	t;

    MemLock(lmemBlock);

    hash = HashTableCreate(lmemBlock,
			   (HTF_C_API_CALLBACKS | HTF_NO_REPEAT_INSERT | 2),
			   sizeof (SSTHeader),
			   SST_NUM_BUCKETS,
			   (HashHashFunc) SSTHash,
			   (HashCompFunc) SSTCompare);

    if (hash == NullHandle) return NullHandle;
    stringArray = ChunkArrayCreate(lmemBlock, 0, 0, 0);
    if (stringArray == NullHandle) 
    {
	LMemFreeHandles(lmemBlock, hash);
	return NullHandle;
    }
    t = LMemDerefHandles(lmemBlock, hash);
    t->SSTH_block = lmemBlock;
    t->SSTH_strings = stringArray;
    MemUnlock(lmemBlock);

    return hash;
}
#endif

#ifdef LIBERTY
/*********************************************************************
 *			SSTDestroy
 *********************************************************************
 * SYNOPSIS:	Delete the sst
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	Should never be called on a XIP sst.
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	 7/17/95	Initial version
 *	mchen	 1/29/96	Changes to non-hash table
 * 
 *********************************************************************/
void
SSTDestroy(optr table)
{
    if(table != NULL) {
	FreeH(table);
    }
}
#else
/*********************************************************************
 *			SSTDestroy
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/15/95	Initial version
 * 
 *********************************************************************/
void
SSTDestroy(optr table)
{
    SSTHeader*	t;
    MemHandle	heap;

    heap = OptrToHandle(table);
    MemLock(heap);

    t = LMemDeref(table);
    LMemFreeHandles(heap, t->SSTH_strings);

    /* Until HashTableDelete comes along, do this instead
     */
    LMemFreeHandles(heap, ((HashTableHeader*)t)->HTH_heap);
    LMemFree(table);

    MemUnlock(heap);
}


/*********************************************************************
 *			SSTAdd
 *********************************************************************
 * SYNOPSIS:	Add string to SST
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	word returned is actually element # in chunk array
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/15/95	Initial version
 * 
 *********************************************************************/
word
SSTAdd(optr table, TCHAR* string)
{
    SSTHeader*	t;
    word	element;

    element = SSTLookup(table, string);
    if (element == SST_NULL)
    {
	optr	stringArray;
	TCHAR*	newStr;

	MemLock(OptrToHandle(table));
	t = LMemDeref(table);

	stringArray = ConstructOptr(OptrToHandle(table), t->SSTH_strings);
	element = ChunkArrayGetCount(stringArray);
	newStr = ChunkArrayAppend(stringArray, 
				  (strlen(string)+1)*sizeof(TCHAR));
	strcpy(newStr, string);

	HashTableAdd(table, element);
	MemUnlock(OptrToHandle(table));
    }

    return element;
}
#endif

#ifdef LIBERTY
/*********************************************************************
 *			BinarySearch
 *********************************************************************
 * SYNOPSIS:	Given a comparison function, an array, and the count
 *		of the size of the array, and a target, do a binary
 *		search for the target in the array.
 * CALLED BY:	SSTLookup
 * RETURN:	The index of the target in the array if the target was
 *		found, else the negative of the index + 1 (so that 0
 *	    	becomes -1) where the target should have been if it
 *	    	was in the array.
 * SIDE EFFECTS:
 * STRATEGY:    This array is an array of offsets from the start position
 *	    	of the array itself rather than being an array of
 *	    	pointers.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	 1/30/96	Initial version
 * 
 *********************************************************************/
int32
BinarySearch(uint16 *array, void *target, 
             ComparisonFunc *compare, uint32 arraySize)
{
    int top, bottom;

    top = arraySize - 1;
    bottom = 0;

    while(top >= bottom) {
	int middle = (top + bottom) / 2;
	void *test = (void*)(((byte*)array) + array[middle]);
	int result = (*compare)(test, target);
	if (result == 0) {
	    // target found, return result;
	    return middle;
	}
	else if (result < 0) {
	    // reduce search to top half of the array
	    bottom = middle + 1;
	}
	else {
	    // reduce search to bottom half of the array
	    top = middle - 1;
	}
    }
    // target not in array, return the negative of where it should have been
    return -(bottom + 1);
}

/*********************************************************************
 *			SSTLookup
 *********************************************************************
 * SYNOPSIS:	Lookup a given string in the table.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:    This can be called on an XIP generated hash table.
 *		Uses a binary search to find the element we are looking
 *		for.
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	 5/15/95	Initial version
 *	mchen	 1/29/96	Changed to binary search
 * 
 *********************************************************************/
word
SSTLookup(optr table, TCHAR* string, word tableSize)
{
    if(tableSize == 0) {
	return SST_NULL;
    }

    ASSERTS(table != NULL, "can't lookup in a null SST table");
    int (*TCHARstringCompareFunction)(const TCHAR *, const TCHAR*) = strcmp;
    word result = SST_NULL;

    uint16 *sstTable = (uint16*)CheckLock(table);

    int index = BinarySearch(sstTable, (void*)string, 
			     (ComparisonFunc*)TCHARstringCompareFunction,
			     tableSize);

    if(index >= 0) {
	// entry was in the list, find the function number at the end of
	// the string
	ASSERT(sizeof(TCHAR) == 2); // for now, only works with DBCS
	TCHAR* string = (TCHAR*)(((byte*)sstTable) + sstTable[index]);
	result = *(word*)(string + strlen(string) + 1);
    }
    CheckUnlock(table);

    return result;
}

/*********************************************************************
 *			SSTGetMemoryUsedBy
 *********************************************************************
 * SYNOPSIS:	Get the memory used by this object
 * CALLED BY:	
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
SSTGetMemoryUsedBy(optr table, word tableSize)
{
    if(tableSize == 0) {
	return 0;
    }
    if(theHeapDataMap.ValueIsHandle(table)) {
	void *sstTable = (void*)LockH(table);
	dword totalSize = theHeap.GetAllocatedSize(sstTable);
	UnlockH(table);
	return totalSize;
    }
    return 0;
}	/* End of SSTGetMemoryUsedBy() */
#else
/*********************************************************************
 *			SSTLookup
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/15/95	Initial version
 * 
 *********************************************************************/
word
SSTLookup(optr table, TCHAR* string)
{
    Boolean	retval;
    dword	element;

    MemLock(OptrToHandle(table));
    retval = HashTableLookup(table, HashTableHash(string), (dword)string,
			     &element);
    MemUnlock(OptrToHandle(table));

    return retval ? (word)element : SST_NULL;
}
#endif

/*********************************************************************
 *			SSTDeref
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/15/95	Initial version
 * 
 *********************************************************************/
#ifdef LIBERTY
TCHAR*
SSTDeref(optr table, word elt, word numFuncs)
{
    uint16      *sstTable;
    TCHAR       *str;

    sstTable = (uint16*)CheckLock(table);
    // still have to do things the hard way; bcl2c doesn't generate
    // SSTs with two offset tables
    // str = (TCHAR*)(((byte*)sstTable) + sstTable[elt + numFuncs]);
    str = (TCHAR*)(sstTable + numFuncs);
    while (elt) {
	while (*str++ != 0);
	str++;
	elt--;
    }

    CheckUnlock(table);
    return str;
}
#else
TCHAR*
SSTDeref(optr table, word elt)
{
    SSTHeader*	t;
    optr	stringArray;
    TCHAR*	str = NULL;

    MemLock(OptrToHandle(table));
    t = LMemDeref(table);

    stringArray = ConstructOptr(OptrToHandle(table), t->SSTH_strings);
    if (elt < ChunkArrayGetCount(stringArray))
    {
	word	dummy;
	str = ChunkArrayElementToPtr(stringArray, elt, &dummy);
    }

    MemUnlock(OptrToHandle(table));

    return str;
}

word _pascal
SSTHash(dword data, SSTHeader* t)
{
    TCHAR*	s2;
    word	hash;
    word    	dummy;

    s2 = ChunkArrayElementToPtrHandles
	(t->SSTH_block, t->SSTH_strings, (word) data, &dummy);

    hash = HashTableHash(s2);
    return hash;
}

Boolean _pascal
SSTCompare(dword cbData, dword eltData, SSTHeader* t)
{
    TCHAR*	s2;
    word	dummy;
    Boolean	val;

    s2 = ChunkArrayElementToPtrHandles
	(t->SSTH_block, t->SSTH_strings, (word) eltData, &dummy);
    val = strcmp((TCHAR*)cbData, s2);
    return (val == 0);
}
#endif
