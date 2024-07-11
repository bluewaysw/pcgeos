/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basco
FILE:		strtab.c

AUTHOR:		Roy Goldman, Dec  7, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/ 7/94   	Initial version.

DESCRIPTION:
	

	$Id: stable.c,v 1.1 98/10/13 21:43:36 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "stable.h"
#include "stabint.h"
#include "faterr.h"
#include <hash.h>
#include <Ansi/string.h>
#include <lmem.h>
#include <mystdapp.h>

/*********************************************************************
 *			StringTableCreate
 *********************************************************************
 * SYNOPSIS:	Given a handle to a vmFile, create a string
 *              table out of it...
 * CALLED BY:	GLOBAL
 * RETURN:      optr which identifies the table
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 7/94	Initial version			     
 * 
 *********************************************************************/

optr StringTableCreate(VMFileHandle vmFile) {

    VMBlockHandle vmBlock;
    MemHandle heap;
    ChunkHandle hash;

    optr table;
    TableHeader *t;
    
    vmBlock = HugeArrayCreate(vmFile, 0, 0);

    heap = MemAllocLMem(LMEM_TYPE_GENERAL,0);
    MemModifyFlags(heap, HF_SHARABLE, 0);
    MemLock(heap);

    hash = HashTableCreate(heap,
			   (HTF_C_API_CALLBACKS | HTF_NO_REPEAT_INSERT | 4),
			   sizeof (TableHeader),
			   239,
			   STHash,
			   STCompare);

    
    table = ConstructOptr(heap, hash);

    t = LMemDeref(table);

    t->TH_vmFile = vmFile;
    t->TH_vmBlock = vmBlock;

    MemUnlock(heap);
    return table;
}

/*********************************************************************
 *			StringTableDestroy
 *********************************************************************
 * SYNOPSIS:	Kill off a string table
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 8/94	Initial version			     
 * 
 *********************************************************************/
void StringTableDestroy(optr table) {
    
    TableHeader *t;

    MemLock(STableOptrToHandle(table));

    t = LMemDeref(table);

    HugeArrayDestroy(t->TH_vmFile, t->TH_vmBlock);

    MemFree(STableOptrToHandle(table));
}

/*********************************************************************
 *			StringTableAddWithData
 *********************************************************************
 * SYNOPSIS:	Add string to table, with word of data
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:If string exists, its data will be updated.
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/27/95	Initial version			     
 * 
 *********************************************************************/
dword StringTableAddWithData(optr table, TCHAR *string, word size, void *data)
{
    TableHeader	*t;
    dword	element;
    byte	*eltP;
    word	eltSize;
    Boolean	found = FALSE;

    MemLock(STableOptrToHandle(table));
    t = LMemDeref(table);

    element = StringTableLookupString(table, string);

    if (element != NullElement) 
    {
	found = TRUE;
    } else {
	element = HugeArrayAppend(t->TH_vmFile,
				  t->TH_vmBlock,
				  (strlen(string)+1)*sizeof(TCHAR) + size,
				  NULL);
    }

    /* Copy the string and data in by hand
     */
    (void) HugeArrayLock(t->TH_vmFile, t->TH_vmBlock,
			 element, (void**)&eltP, &eltSize);

    EC_ERROR_IF(eltSize < (strlen(string)+1)*sizeof(TCHAR) + size, -1);
    if (!found) {
	strcpy((char *)eltP, (char *)string);
    }

    memcpy(&(eltP[eltSize - size]), data, size);
    HugeArrayDirty(eltP);
    HugeArrayUnlock(eltP);

    if (!found) {
	HashTableAdd(table, element);
    }
    MemUnlock(STableOptrToHandle(table));

    return element;
}

/*********************************************************************
 *			StringTableAdd
 *********************************************************************
 * SYNOPSIS:	Add the given string to the given string table
 *              Returns the key for that string.  Note that
 *              strings are only stored once within the table.
 *              If you try to add the same string twice it will return
 *              the key from the previous insertion.
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 8/94	Initial version			     
 * 
 *********************************************************************/
dword
StringTableAdd(optr table, TCHAR *string) 
{
    TableHeader *t;
    dword element;


    element = StringTableLookupString(table, string);

    if (element != NullElement) 
    {
	return element;
    }
    else 
    {
	MemLock(STableOptrToHandle(table));
	t = LMemDeref(table);

	element = HugeArrayGetCount(t->TH_vmFile, t->TH_vmBlock);

	HugeArrayAppend(t->TH_vmFile,
			t->TH_vmBlock,
			(strlen(string)+1)*sizeof(TCHAR),
			string);
	HashTableAdd(table,element);
	MemUnlock(STableOptrToHandle(table));

	return element;
    }
	
}

/*********************************************************************
 *			StringTableLookupWithData
 *********************************************************************
 * SYNOPSIS:	Map string to a token; also return data
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/27/95	Initial version			     
 * 
 *********************************************************************/
dword
StringTableLookupWithData(optr table, TCHAR* string, word size, void *data)
{
    TableHeader	*t;
    Boolean	retval;
    dword	element;
    byte*	eltP;
    word	eltSize;
    byte    	*dummy;

    dummy = MemLock(STableOptrToHandle(table));
    if (dummy == NULL) {
	return NullElement;
    }
    
    retval = HashTableLookup(table,
			     HashTableHash(string),
			     (dword)string,
			     &element);

    MemUnlock(STableOptrToHandle(table));

    if (!retval)
    {
	return NullElement;
    }

    /* Extract the word of data
     */
    MemLock(STableOptrToHandle(table));
    t = LMemDeref(table);
    (void) HugeArrayLock(t->TH_vmFile, t->TH_vmBlock,
			 element, (void**)&eltP, &eltSize);
    MemUnlock(STableOptrToHandle(table));

    /* Check to see if the null is in the right place.  If it isn't
     * this string probably doesn't have any data associated with it...
     */
    EC_ERROR_IF(eltP[ eltSize-size-1 ] != '\0', -1);
    memcpy(data, &(eltP[eltSize-size]), size);
    HugeArrayUnlock(eltP);

    return element;
}


/*********************************************************************
 *			StringTableGetData
 *********************************************************************
 * SYNOPSIS:	Map string to a token; also return data
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/27/95	Initial version			     
 * 
 *********************************************************************/
word
StringTableGetData(optr table, dword key)
{
    TableHeader* t;
    byte*	eltP;
    word	eltData;	/* also used for elt size */

    MemLock(STableOptrToHandle(table));
    t = LMemDeref(table);
    (void) HugeArrayLock(t->TH_vmFile, t->TH_vmBlock,
			 key, (void**)&eltP, &eltData);
    MemUnlock(STableOptrToHandle(table));

    /* Check to see if the null is in the right place.  If it isn't
     * this string probably doesn't have any data associated with it...
     */
    EC_ERROR_IF(eltP[ eltData-sizeof(word)-1 ] != '\0', BE_FAILED_ASSERTION);
    eltData = CAST_ARR(word, eltP[ eltData-sizeof(word) ]);
    HugeArrayUnlock(eltP);

    return eltData;
}

/*********************************************************************
 *			StringTableGetDataPtr
 *********************************************************************
 * SYNOPSIS:	Map string to a token; also return data
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/27/95	Initial version			     
 * 
 *********************************************************************/
void
StringTableGetDataPtr(optr table, dword key, word size, void *dataPtr)
{
    TableHeader* t;
    byte*	eltP;
    word    	elSize;

    MemLock(STableOptrToHandle(table));
    t = LMemDeref(table);
    (void) HugeArrayLock(t->TH_vmFile, t->TH_vmBlock,
			 key, (void**)&eltP, &elSize);
    MemUnlock(STableOptrToHandle(table));

    /* Check to see if the null is in the right place.  If it isn't
     * this string probably doesn't have any data associated with it...
     */
    EC_ERROR_IF(eltP[ elSize-size-1 ] != '\0', BE_FAILED_ASSERTION);
    memcpy(dataPtr, &(eltP[elSize-size]), size);
    HugeArrayUnlock(eltP);
}

/*********************************************************************
 *			StringTableSetDataPtr
 *********************************************************************
 * SYNOPSIS:	Change the data associated with a string
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/27/95	Initial version			     
 * 
 *********************************************************************/
void
StringTableSetDataPtr(optr table, dword key, word size, void *dataPtr)
{
    TableHeader* t;
    byte*	eltP;
    word    	elSize;

    MemLock(STableOptrToHandle(table));
    t = LMemDeref(table);
    (void) HugeArrayLock(t->TH_vmFile, t->TH_vmBlock,
			 key, (void**)&eltP, &elSize);
    MemUnlock(STableOptrToHandle(table));

    /* Check to see if the null is in the right place.  If it isn't
     * this string probably doesn't have any data associated with it...
     */
    EC_ERROR_IF(eltP[ elSize-size-1 ] != '\0', BE_FAILED_ASSERTION);
    memcpy(&(eltP[elSize-size]), dataPtr, size);
    HugeArrayDirty(eltP);
    HugeArrayUnlock(eltP);
}


/*********************************************************************
 *			StringTableLookupString
 *********************************************************************
 * SYNOPSIS:	Checks to see if a certain string
 *              in the table. If so, returns its element number
 *              otherwise returns -1.
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 8/94	Initial version			     
 * 
 *********************************************************************/
dword StringTableLookupString(optr table, TCHAR *string)
{
    Boolean retval;
    dword element;
    byte    *dummy;

    dummy = MemLock(STableOptrToHandle(table));
    if (dummy == NULL) {
	return NullElement;
    }
    
    retval = HashTableLookup(table,
			     HashTableHash(string),
			     (dword)string,
			     &element);
    MemUnlock(STableOptrToHandle(table));

    /* Already in the table, return the index */
    
    if (retval) {
	return element;
    } else {
        return NullElement;
    }
}

    
/*********************************************************************
 *			StringTableLockNew
 *********************************************************************
 * SYNOPSIS:	Back maps a key into the actual element
 *              and locks it down, returning a pointer..
 * CALLED BY:	GLOBAL
 * RETURN:	TRUE if successful; elt, size filled in
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 8/94	Initial version			     
 * 
 *********************************************************************/
Boolean
StringTableLockNew(optr table, dword index, TCHAR** elt, word* size)
{
    TableHeader *t;
    
    MemLock(STableOptrToHandle(table));
    t = LMemDeref(table);

    if ((HugeArrayGetCount(t->TH_vmFile, t->TH_vmBlock) <= index) ||
	index == NullElement) 
    {
	MemUnlock(STableOptrToHandle(table));
	return FALSE;
    }

    HugeArrayLock(t->TH_vmFile, t->TH_vmBlock, index, (void**)elt, size);
    MemUnlock(STableOptrToHandle(table));
    return TRUE;
}

    
/*********************************************************************
 *			StringTableLock
 *********************************************************************
 * SYNOPSIS:	Back maps a key into the actual element
 *              and locks it down, returning a pointer..
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 8/94	Initial version			     
 * 
 *********************************************************************/
TCHAR *StringTableLock(optr table, dword index)
{
    TCHAR	*cp;
    word	w;		/* dummy */
    TableHeader *t;
    byte    	*dummy;

    dummy = MemLock(STableOptrToHandle(table));
    if (dummy == NULL) {
	return NULL;
    }
    t = LMemDeref(table);

    if (HugeArrayGetCount(t->TH_vmFile, t->TH_vmBlock) <= index ||
	index == NullElement) 
    {
	MemUnlock(STableOptrToHandle(table));
	return NULL;
    }

    HugeArrayLock(t->TH_vmFile, t->TH_vmBlock, index, (void**)&cp, &w);

    MemUnlock(STableOptrToHandle(table));

    return cp;
}

/*********************************************************************
 *			StringTableGetCount
 *********************************************************************
 * SYNOPSIS:	Returns the number of strings in the table
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 1/24/95	Initial version			     
 * 
 *********************************************************************/
dword StringTableGetCount(optr table)
{
    TableHeader *t;
    dword count;
    word    *dummy;

    dummy = MemLock(STableOptrToHandle(table));
    if (dummy == NULL) {
	return 0;
    }
    t = LMemDeref(table);
    
    count = HugeArrayGetCount(t->TH_vmFile, t->TH_vmBlock);

    MemUnlock(STableOptrToHandle(table));

    return count;
}

/*********************************************************************
 *			STHash
 *********************************************************************
 * SYNOPSIS:	To add an item to the table, we insert it into
 *              the hugeArray and keep its dword offset within the array.
 *              We then send this offset to the HashTableAdd, which
 *              proceeds to send that offset to this function.
 *              This function must dereference the string at that
 *              element, hash it, and return the hash value.
 *              
 * CALLED BY:	INTERNAL (hash table routines)
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 8/94	Initial version			     
 * 
 *********************************************************************/

word _pascal STHash(dword data, void *h)
{
    TCHAR	*string;
    word	hash, dummy;
    TableHeader *t = (TableHeader*) h;

    HugeArrayLock(t->TH_vmFile,
		  t->TH_vmBlock,
		  data,
		  (void**)&string,
		  &dummy);

    hash = HashTableHash(string);

    HugeArrayUnlock(string);

    return hash;
}

/*********************************************************************
 *			STCompare
 *********************************************************************
 * SYNOPSIS:	Compare call back.
 * CALLED BY:	INTERNAL (hash table routines)
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 8/94	Initial version			     
 * 
 *********************************************************************/

Boolean _pascal STCompare(dword cbData, dword eltData, void *h) {
    
    TCHAR	*s1, *s2;
    word	dummy;
    Boolean	val;
    TableHeader	*t = (TableHeader*) h;

    s1 = (TCHAR*) cbData;

    HugeArrayLock(t->TH_vmFile,
		  t->TH_vmBlock,
		  eltData,
		  (void**)&s2,
		  &dummy);

    val = strcmp(s1,s2);

    HugeArrayUnlock(s2);

    return (val == 0);
}






/*********************************************************************
 *			StableCopyTableDeleteElement
 *********************************************************************
 * SYNOPSIS:	create a new table with one element deleted
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/11/95	Initial version
 * 
 *********************************************************************/
optr StableCopyTableDeleteElement(optr	table, word index)
{
    word    	count;
    int	    	i;
    TableHeader *t;
    optr    	newTable;

    if (table == NullOptr) {
	return NullOptr;
    }


    MemLock(STableOptrToHandle(table));
    t = LMemDeref(table);
    newTable = StringTableCreate(t->TH_vmFile);
    MemUnlock(STableOptrToHandle(table));
    
    count = StringTableGetCount(table);
    for (i = 0; i < count; i++)
    {
	if (i != index)
	{
	    TCHAR	*str;

	    str = StringTableLock(table, i);
	    StringTableAdd(newTable, str);
	    StringTableUnlock(str);
	}
    }

    StringTableDestroy(table);
    return newTable;
}
