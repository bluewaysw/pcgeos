/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  hash.c
 * FILE:	  hash.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Contains functions to manipulate an arbitrary-key hash table.
 *	The tables grow automatically as the amount of information
 *	stored in them increases. The maximum average chain length
 *	is table-specific, but is usually 3. When this limit is reached,
 *	the number of chains is quadrupled and everything is rehashed.
 *
 *	Derived from hash table library distributed with Sprite:
 *
 *      Copyright (c) 1988 by the Regents of the University of California
 *     
 *      Permission to use, copy, modify, and distribute this
 *      software and its documentation for any purpose and without
 *      fee is hereby granted, provided that the above copyright
 *      notice appear in all copies.  The University of California
 *      makes no representations about the suitability of this
 *      software for any purpose.  It is provided "as is" without
 *      express or implied warranty.
 *
 *
 ***********************************************************************/

#include <config.h>
#include <search.h>
#include <compat/queue.h>
#include <compat/string.h>

#include "malloc.h"

#ifdef ISSWAT
#include    "swat.h"
#endif /* ISSWAT */

#include    "hash.h"

/*
 * Forward references to local procedures that are used before they're
 * defined:
 */

static Hash_Entry *	ChainSearch(Hash_Table *tablePtr, 
				    register Address key, 
				    register HashLink *hashList);
static int		Hash(register Hash_Table *tablePtr, register char *key);
static void		RebuildTable(Hash_Table	*tablePtr);

/*
 * DEFAULT_LIMIT is the default maximum length to which a chain may grow
 * before the table is expanded.
 */
#define DEFAULT_LIMIT	3


/*
 *---------------------------------------------------------
 * 
 * Hash_InitTable --
 *
 *	This routine just sets up the hash table.
 *
 * Results:	
 *	None.
 *
 * Side Effects:
 *	Memory is allocated for the initial bucket area.
 *
 *---------------------------------------------------------
 */

void
Hash_InitTable(register Hash_Table  *tablePtr,	/* Structure to use to hold
						 * table. */
	       int		    numBuckets,	/* How many buckets to create
						 * for starters. This number is
						 * rounded up to a power of
						 * two.   If <= 0, a reasonable
						 * default is chosen. The table
						 * will grow in size later as
						 * needed. */
	       int		    keyType,	/* HASH_STRING_KEYS means that
						 * key values passed to
						 * HashFind will be strings,
						 * passed via a (char *)
						 * pointer.  HASH_ONE_WORD_KEYS
						 * means that key values will
						 * be any one-word value passed
						 * as Address. > 1 means that
						 * key values will be  multi-
						 * word values whose address is
						 * passed as Address.  In this
						 * last case, keyType is the
						 * number of words in the key,
						 * not the number of bytes. */
	       int		    limit)	/* The average chain-length at
						 * which the table is to be
						 * expanded */
{
    register	int 		i;
    register	HashLink 	*bucketPtr;

    /*
     * Use defaults for numBuckets and limit if value not specified
     */
    if (numBuckets <= 0) {
	numBuckets = 16;
    }
    if (limit <= 0) {
	limit = 3;
    }
    tablePtr->numEntries = 0;
    tablePtr->keyType = keyType;
    tablePtr->limit = limit;
    tablePtr->size = 2;
    tablePtr->mask = 1;
    tablePtr->downShift = 29;
    /* 
     * Round up the size to a power of two and set the mask and downshift
     * appropriately at the same time.
     */

    while (tablePtr->size < numBuckets) {
	tablePtr->size <<= 1;
	tablePtr->mask = (tablePtr->mask << 1) + 1;
	tablePtr->downShift--;
    }

    tablePtr->bucketPtr = (HashLink *) malloc_tagged(tablePtr->size *
						     sizeof(HashLink),
						     TAG_HASHT);
    for (i=0, bucketPtr = tablePtr->bucketPtr; i < tablePtr->size;
	    i++, bucketPtr++)
    {
	/*
	 * Initialize by pointing to itself
	 */
	bucketPtr->prev = bucketPtr->next = (Hash_Entry *)bucketPtr;
    }
}

/*
 *---------------------------------------------------------
 *
 * Hash_DeleteTable --
 *
 *	This routine removes everything from a hash table
 *	and frees up the memory space it occupied (except for
 *	the space in the Hash_Table structure).
 *
 * Results:	
 *	None.
 *
 * Side Effects:
 *	Lots of memory is freed up.
 *
 *---------------------------------------------------------
 */

void
Hash_DeleteTable(Hash_Table *tablePtr)	/* Hash table whose entries are all to
					 * be freed.  */
{
    register HashLink *hashTableEnd;
    register Hash_Entry *hashEntryPtr;
    register HashLink *bucketPtr;

    bucketPtr = tablePtr->bucketPtr;
    hashTableEnd = &(bucketPtr[tablePtr->size]);
    for (; bucketPtr < hashTableEnd; bucketPtr++) {
	while (bucketPtr->next != (Hash_Entry *)bucketPtr) {
	    hashEntryPtr = bucketPtr->next;
	    remque((struct qelem*) &hashEntryPtr->links);
	    free((Address) hashEntryPtr);
	}
    }
    free((Address) tablePtr->bucketPtr);

    /*
     * Set up the hash table to cause memory faults on any future
     * access attempts until re-initialization.
     */

    tablePtr->bucketPtr = (HashLink *) NULL;
}

/*
 *---------------------------------------------------------
 *
 * Hash_FindEntry --
 *
 * 	Searches a hash table for an entry corresponding to key.
 *
 * Results:
 *	The return value is a pointer to the entry for key,
 *	if key was present in the table.  If key was not
 *	present, NULL is returned.
 *
 * Side Effects:
 *	None.
 *
 *---------------------------------------------------------
 */

Hash_Entry *
Hash_FindEntry(Hash_Table   *tablePtr,	/* Hash table to search. */
	       Address	    key)	/* A hash key. */
{
    return(ChainSearch(tablePtr, key,
	    &(tablePtr->bucketPtr[Hash(tablePtr, key)])));
}

/*
 *---------------------------------------------------------
 *
 * Hash_CreateEntry --
 *
 *	Searches a hash table for an entry corresponding to
 *	key.  If no entry is found, then one is created.
 *
 * Results:
 *	The return value is a pointer to the entry.  If *newPtr
 *	isn't NULL, then *newPtr is filled in with TRUE if a
 *	new entry was created, and FALSE if an entry already existed
 *	with the given key.
 *
 * Side Effects:
 *	Memory may be allocated, and the hash buckets may be modified.
 *---------------------------------------------------------
 */

Hash_Entry *
Hash_CreateEntry(register Hash_Table	*tablePtr,  /* Hash table to search. */
		 Address		key,	    /* A hash key. */
		 Boolean		*newPtr)    /* Filled in with TRUE if
						     * new entry created, FALSE
						     * otherwise. */
{
    register Hash_Entry *hashEntryPtr;
    register int 	*hashKeyPtr;
    register int 	*keyPtr;
    HashLink 		*hashList;

    keyPtr = (int *) key;

    hashList = &(tablePtr->bucketPtr[Hash(tablePtr, (Address) keyPtr)]);
    hashEntryPtr = ChainSearch(tablePtr, (Address) keyPtr, hashList);

    if (hashEntryPtr != (Hash_Entry *) NULL) {
	if (newPtr != NULL) {
	    *newPtr = FALSE;
	}
    	return hashEntryPtr;
    }

    /* 
     * The desired entry isn't there.  Before allocating a new entry,
     * see if we're overloading the buckets.  If so, then make a
     * bigger table.
     */

    if (tablePtr->numEntries >= tablePtr->limit * tablePtr->size) {
	RebuildTable(tablePtr);
	hashList = &(tablePtr->bucketPtr[Hash(tablePtr, (Address) keyPtr)]);
    }
    tablePtr->numEntries += 1;

    /*
     * Not there, we have to allocate.  If the string is longer
     * than 3 bytes, then we have to allocate extra space in the
     * entry.
     */

    switch (tablePtr->keyType) {
	case HASH_STRING_KEYS: {
	    /*
	     * Allocate room for the entire string after the Hash_Entry
	     */
	    int	  len;

	    len = strlen((char *)keyPtr) + 1;

	    if (len > 4) {
		/*
		 * String won't fit in the four-byte array allocated for it.
		 * Allocate room for the string after the Hash_Entry. The
		 * first four characters still go in the name field, though.
		 */
		hashEntryPtr = (Hash_Entry *)malloc_tagged(sizeof(Hash_Entry) +
							   len - 4,
							   TAG_HASH);
		strcpy(hashEntryPtr->key.name, (char *) keyPtr);
	    } else {
		/*
		 * Only allocate the Hash_Entry. Use strncpy(4) to zero-pad
		 * the name field.
		 */
		hashEntryPtr = (Hash_Entry *)malloc_tagged(sizeof(Hash_Entry),
							   TAG_HASH);
		strncpy(hashEntryPtr->key.name, (char *)keyPtr, 4);
	    }
	    break;
	}
	case HASH_ONE_WORD_KEYS:
	    hashEntryPtr = (Hash_Entry *) malloc_tagged(sizeof(Hash_Entry),
							TAG_HASH);
	    hashEntryPtr->key.ptr = (Address) keyPtr;
	    break;
	case 2:
	    hashEntryPtr = 
		(Hash_Entry *) malloc_tagged(sizeof(Hash_Entry) + sizeof(int),
					     TAG_HASH);
	    hashKeyPtr = hashEntryPtr->key.words;
	    *hashKeyPtr++ = *keyPtr++;
	    *hashKeyPtr = *keyPtr;
	    break;
	default: {
	    register int	n;

	    n = tablePtr->keyType;
	    hashEntryPtr = (Hash_Entry *) malloc_tagged(sizeof(Hash_Entry) +
							(n - 1) * sizeof(int),
							TAG_HASH);
	    hashKeyPtr = hashEntryPtr->key.words;
	    do { 
		*hashKeyPtr++ = *keyPtr++; 
	    } while (--n);
	    break;
	}
    }

    hashEntryPtr->data = (Opaque) NULL;
    insque((struct qelem*) &hashEntryPtr->links, (struct qelem*) hashList);

    if (newPtr != NULL) {
	*newPtr = TRUE;
    }
    return hashEntryPtr;
}

/*
 *---------------------------------------------------------
 *
 * Hash_DeleteEntry --
 *
 * 	Delete the given hash table entry and free memory associated with
 *	it.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Hash chain that entry lives in is modified and memory is freed.
 *
 *---------------------------------------------------------
 */

void
Hash_DeleteEntry(Hash_Table		*tablePtr,
		 register	Hash_Entry*hashEntryPtr)
{
    if (hashEntryPtr != (Hash_Entry *) NULL) {
	remque((struct qelem*) &hashEntryPtr->links);
	free((Address) hashEntryPtr);
	tablePtr->numEntries--;
    }
}

/*
 *---------------------------------------------------------
 *
 * Hash_EnumFirst --
 *	This procedure sets things up for a complete search
 *	of all entries recorded in the hash table.
 *
 * Results:	
 *	The return value is the address of the first entry in
 *	the hash table, or NULL if the table is empty.
 *
 * Side Effects:
 *	The information in hashSearchPtr is initialized so that successive
 *	calls to Hash_Next will return successive HashEntry's
 *	from the table.
 *
 *---------------------------------------------------------
 */

Hash_Entry *
Hash_EnumFirst(Hash_Table	    *tablePtr,	    /* Table to be searched. */
	       register Hash_Search *hashSearchPtr) /* Area in which to keep
						     * state  about search.*/
{
    hashSearchPtr->tablePtr = tablePtr;
    hashSearchPtr->nextIndex = 0;
    hashSearchPtr->hashEntryPtr = (Hash_Entry *) NULL;
    return Hash_EnumNext(hashSearchPtr);
}

/*
 *---------------------------------------------------------
 *
 * Hash_EnumNext --
 *    This procedure returns successive entries in the hash table.
 *
 * Results:
 *    The return value is a pointer to the next HashEntry
 *    in the table, or NULL when the end of the table is
 *    reached.
 *
 * Side Effects:
 *    The information in hashSearchPtr is modified to advance to the
 *    next entry.
 *
 *---------------------------------------------------------
 */

Hash_Entry *
Hash_EnumNext(register Hash_Search  *hashSearchPtr) /* Area used to keep state
						     * about search. */
{
    register Hash_Entry *hashEntryPtr;

    hashEntryPtr = hashSearchPtr->hashEntryPtr;

    while ((hashEntryPtr == (Hash_Entry *) NULL) ||
	   (hashEntryPtr == (Hash_Entry *)hashSearchPtr->hashList))
    {
	if (hashSearchPtr->nextIndex >= hashSearchPtr->tablePtr->size) {
	    return((Hash_Entry *) NULL);
	}
	/*
	 * Advance to next chain in table. ->hashList gets the address of
	 * the head pointer, while hashEntryPtr gets the address of the first
	 * element in the chain. Note that if the chain is empty, this
	 * will just be the address of the head pointer and we will loop
	 * again.
	 */
	hashSearchPtr->hashList =
	    &(hashSearchPtr->tablePtr->bucketPtr[hashSearchPtr->nextIndex++]);
	hashEntryPtr = hashSearchPtr->hashList->next;
    }

    /*
     * Set up the ->hashEntryPtr for the next item in the chain to be used on
     * the next call
     */
    hashSearchPtr->hashEntryPtr = hashEntryPtr->links.next;

    return(hashEntryPtr);
}

/*
 *---------------------------------------------------------
 *
 * Hash_PrintStats --
 *
 *	This routine calls a caller-supplied procedure to print
 *	statistics about the current bucket situation.
 *
 * Results:	
 *	None.
 *
 * Side Effects:	
 *	Proc gets called (potentially many times) to output information
 *	about the hash table. It must have the following calling sequence:
 *
 *	void
 *	proc(data, string)
 *	    Opaque data;
 *	    char *string;
 *	{
 *	}
 *
 *	In each call, data is the same as the data argument
 *	to this procedure, and string is a null-terminated string of
 *	characters to output.
 *
 *---------------------------------------------------------
 */

void
Hash_PrintStats(Hash_Table  *tablePtr,	/* Table for which to print info. */
		void	    (*proc)(),	/* Procedure to call to do actual I/O. */
		Opaque      data)	/* Datum to pass it */
{
    int count[10], overflow, i, j;
    char msg[100];
    Hash_Entry 	*hashEntryPtr;
    HashLink	*hashList;

    for (i=0; i<10; i++) {
	count[i] = 0;
    }
    overflow = 0;
    for (i = 0; i < tablePtr->size; i++) {
	j = 0;
	hashList = &(tablePtr->bucketPtr[i]);

	for (hashEntryPtr = hashList->next;
	     hashEntryPtr != (Hash_Entry *)hashList;
	     hashEntryPtr = hashEntryPtr->links.next)
	{
	    j++;
	}

	if (j < 10) {
	    count[j]++;
	} else {
	    overflow++;
	}
    }

    sprintf(msg, "Entries in table %d number of buckets %d\n", 
		tablePtr->numEntries, tablePtr->size);
    (*proc)(data, msg);
    for (i = 0;  i < 10; i++) {
	sprintf(msg, "Number of buckets with %d entries: %d.\n",
		i, count[i]);
	(*proc)(data, msg);
    }
    sprintf(msg, "Number of buckets with > 9 entries: %d.\n",
	    overflow);
    (*proc)(data, msg);
}

/*
 *---------------------------------------------------------
 *
 * Hash --
 *	This is a local procedure to compute a hash table
 *	bucket address based on a string value.
 *
 * Results:
 *	The return value is an integer between 0 and size - 1.
 *
 * Side Effects:	
 *	None.
 *
 * Design:
 *	It is expected that most keys are decimal numbers,
 *	so the algorithm behaves accordingly.  The randomizing
 *	code is stolen straight from the rand library routine.
 *
 *---------------------------------------------------------
 */

static int
Hash(register Hash_Table    *tablePtr,
     register char	    *key)
{
    register int 	i = 0;
    register int 	j;
    register int 	*intPtr;

    switch (tablePtr->keyType) {
	case HASH_STRING_KEYS:
	    while (*key != '\0') {
		i = (i * 10) + (*key++ - '0');
	    }
	    break;
	case HASH_ONE_WORD_KEYS:
	    i = (int)(intptr_t) key;
	    break;
	case 2:
	    i = ((int *) key)[0] + ((int *) key)[1];
	    break;
	default:
	    j = tablePtr->keyType;
	    intPtr = (int *) key;
	    do { 
		i += *intPtr++; 
		j--;
	    } while (j > 0);
	    break;
    }


    return(((i*1103515245 + 12345) >> tablePtr->downShift) & tablePtr->mask);
}

/*
 *---------------------------------------------------------
 *
 * ChainSearch --
 *
 * 	Search the hash table for the entry in the hash chain.
 *
 * Results:
 *	Pointer to entry in hash chain, NULL if none found.
 *
 * Side Effects:
 *	None.
 *
 *---------------------------------------------------------
 */

static Hash_Entry *
ChainSearch(Hash_Table		*tablePtr,  /* Hash table to search. */
	    register Address	key,	    /* A hash key. */
	    register HashLink	*hashList)
{
    register Hash_Entry *hashEntryPtr;

    /*
     * Perform the switch on the keyType once -- at the beginning.
     */
    switch(tablePtr->keyType) {
    case HASH_STRING_KEYS: {
	/*
	 * String key -- compare the first char before calling strcmp
	 */
	register char firstChar = *(char *)key;
	
	for (hashEntryPtr = hashList->next;
	     hashEntryPtr != (Hash_Entry *)hashList;
	     hashEntryPtr = hashEntryPtr->links.next)
	{
	    if ((*hashEntryPtr->key.name == firstChar) &&
		(strcmp(hashEntryPtr->key.name, key) == 0))
	    {
		return(hashEntryPtr);
	    }
	}
	break;
    }
    case HASH_ONE_WORD_KEYS:
	for (hashEntryPtr = hashList->next;
	     hashEntryPtr != (Hash_Entry *)hashList;
	     hashEntryPtr = hashEntryPtr->links.next)
	{
	    if (hashEntryPtr->key.ptr == key) {
		return(hashEntryPtr);
	    }
	}
	break;
    case 2: {
	/*
	 * Two-word key -- do it w/o a function call
	 */
	register int 	*hashKeyPtr, *keyPtr;

	for (hashEntryPtr = hashList->next;
	     hashEntryPtr != (Hash_Entry *)hashList;
	     hashEntryPtr = hashEntryPtr->links.next)
	{
	    keyPtr = (int *)key;
	    hashKeyPtr = hashEntryPtr->key.words;
	    
	    if ((*hashKeyPtr++ == *keyPtr++) &&
		(*hashKeyPtr == *keyPtr))
	    {
		return(hashEntryPtr);
	    }
	}
	break;
    }
    default: {
	register int	numBytes;

	numBytes = tablePtr->keyType * sizeof(int);

	for (hashEntryPtr = hashList->next;
	     hashEntryPtr != (Hash_Entry *)hashList;
	     hashEntryPtr = hashEntryPtr->links.next)
	{
	    if (bcmp((Address)hashEntryPtr->key.words,
		     (Address)key,
		     numBytes) == 0)
	    {
		return(hashEntryPtr);
	    }
	}
	break;
    }
    }

    /* 
     * The desired entry isn't there 
     */

    return ((Hash_Entry *) NULL);
}

/*
 *---------------------------------------------------------
 *
 * RebuildTable --
 *	This local routine makes a new hash table that
 *	is larger than the old one.
 *
 * Results:	
 * 	None.
 *
 * Side Effects:
 *	The entire hash table is moved, so any bucket numbers
 *	from the old table are invalid.
 *
 *---------------------------------------------------------
 */

static void
RebuildTable(Hash_Table	*tablePtr)  /* Table to be enlarged. */
{
    int 		 oldSize;
    int 		 bucket;
    HashLink		 *oldBucketPtr;
    register Hash_Entry  *hashEntryPtr;
    register HashLink	 *oldHashList;

    oldBucketPtr = tablePtr->bucketPtr;
    oldSize = tablePtr->size;

    /* 
     * Build a new table 4 times as large as the old one. 
     */

    Hash_InitTable(tablePtr, tablePtr->size * 4, tablePtr->keyType,
		   tablePtr->limit);

    for (oldHashList = oldBucketPtr; oldSize > 0; oldSize--, oldHashList++) {
	while (oldHashList->next != (Hash_Entry *)oldHashList) {
	    hashEntryPtr = oldHashList->next;
	    remque((struct qelem*) &hashEntryPtr->links);

	    switch (tablePtr->keyType) {
		case HASH_STRING_KEYS:
		    bucket = Hash(tablePtr, (Address) hashEntryPtr->key.name);
		    break;
		case HASH_ONE_WORD_KEYS:
		    bucket = Hash(tablePtr, (Address) hashEntryPtr->key.ptr);
		    break;
		default:
		    bucket = Hash(tablePtr, (Address) hashEntryPtr->key.words);
		    break;
	    }
	    insque((struct qelem*) &hashEntryPtr->links, (struct qelem*) &tablePtr->bucketPtr[bucket]);
	    tablePtr->numEntries++;
	}
    }

    free((Address) oldBucketPtr);
}
