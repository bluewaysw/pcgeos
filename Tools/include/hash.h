/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Hash Table Declarations
 * FILE:	  hash.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Hash table declarations
 *
 *
 * 	$Id: hash.h,v 1.3 93/09/02 19:56:07 jimmy Exp $
 *
 ***********************************************************************/
#ifndef _HASH_H_
#define _HASH_H_

/*
 *	If not making SWAT, define the few constants needed to allow this
 * module to be used elsewhere (uic to be specific)
*/
#ifndef ISSWAT

#ifndef FALSE
#define FALSE	  (0)
#endif
#ifndef TRUE
#define TRUE	  (!FALSE)
#endif
#include <stdio.h>
#define malloc_tagged(a,b) malloc(a)
#if defined(__HIGHC__)
typedef unsigned long Opaque;
#else
typedef void *Opaque;
#endif
typedef char *Address;
typedef int Boolean;

#endif /* !ISSWAT */

/*
 * Structure for the insque and remque calls
 */
typedef struct {
    struct Hash_Entry	*next;
    struct Hash_Entry   *prev;
}	HashLink;

/*
 * The following defines one entry in the hash table.
 */

typedef struct Hash_Entry {
    HashLink	links;	    	/* Used to link together all the
				 * entries associated with the same
				 * bucket. */
    Opaque	data;	    	/* Arbitrary piece of data associated
				 * with key. */
    union {
	Address	    ptr;	    /* One-word key value to identify entry. */
	int 	    words[1];	    /* N-word key value.  Note: the actual
				     * size may be longer if necessary to
				     * hold the entire key. */
	char 	    name[4];	    /* Text name of this entry.  Note: the
				     * actual size may be longer if
				     * necessary to hold the whole string.
				     * This MUST be the last entry in the
				     * structure!!! */
    } 	    	key;	    	/* Union of possible keys--all the same size */
} Hash_Entry;

#define NullHash_Entry (Hash_Entry *) NULL

/*
 * A hash table consists of an array of pointers to hash
 * lists.  Tables can be organized in either of three ways, depending
 * on the type of comparison keys:
 *
 *	Strings:	  these are NULL-terminated; their address
 *			  is passed to HashFind as a (char *).
 *	Single-word keys: these may be anything, but must be passed
 *			  to Hash_Find as an Address.
 *	Multi-word keys:  these may also be anything; their address
 *			  is passed to HashFind as an Address.
 *
 *	Single-word keys are fastest, but most restrictive.
 */

#define HASH_STRING_KEYS	0
#define HASH_ONE_WORD_KEYS	1

typedef struct Hash_Table {
    HashLink 	*bucketPtr;	/* Pointer to array of HashLink, one
    				 * for each bucket in the table. */
    int 	size;		/* Actual size of array. */
    int		limit;	    	/* Average chain-length at which the table
				 * is expanded */
    int 	numEntries;	/* Number of entries in the table. */
    int 	downShift;	/* Shift count, used in hashing function. */
    int 	mask;		/* Used to select bits for hashing. */
    int 	keyType;	/* Type of keys used in table:
    				 * HASH_STRING_KEYS, HASH_ONE_WORD_KEYS,
				 * or >1 means keyType gives number of words
				 * in keys.
				 */
} Hash_Table;

/*
 * The following structure is used by the searching routines
 * to record where we are in the search.
 */

typedef struct Hash_Search {
    Hash_Table  *tablePtr;	/* Table being searched. */
    int 	nextIndex;	/* Next bucket to check (after current). */
    Hash_Entry 	*hashEntryPtr;	/* Next entry to check in current bucket. */
    HashLink	*hashList;	/* Hash chain currently being checked. */
} Hash_Search;

/*
 * Macros.
 */

/*
 * Opaque Hash_GetValue(Hash_Entry *h);
 */

#define Hash_GetValue(h) ((h)->data)

/*
 * Hash_SetValue(HashEntry *h, Opaque val);
 */

#define Hash_SetValue(h, val) ((h)->data = (Opaque) (val))

/*
 * Hash_Size(n) returns the number of words in an object of n bytes
 */

#define	Hash_Size(n)	(((n) + sizeof (int) - 1) / sizeof (int))

/*
 * The following procedure declarations and macros
 * are the only things that should be needed outside
 * the implementation code.
 */

extern Hash_Entry *	Hash_CreateEntry(Hash_Table *tablePtr,
					 Address key,
					 Boolean *newPtr);
extern void		Hash_DeleteTable(Hash_Table *tablePtr);
extern void		Hash_DeleteEntry(Hash_Table *tablePtr,
					 Hash_Entry *hashEntryPtr);
extern Hash_Entry *	Hash_EnumFirst(Hash_Table *tablePtr,
				       Hash_Search *searchPtr);
extern Hash_Entry *	Hash_EnumNext(Hash_Search *searchPtr);
extern Hash_Entry *	Hash_FindEntry(Hash_Table *tablePtr,
				       Address key);
extern void		Hash_InitTable(Hash_Table *tablePtr,
				       int numBuckets,
				       int keyType,
				       int limit);
extern void		Hash_PrintStats(Hash_Table *tablePtr,
					void (*proc)(Opaque data,
						     char *msg),
					Opaque data);

#endif /* _HASH_H_ */
