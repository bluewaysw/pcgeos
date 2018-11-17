/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Hash library
FILE:		hash.h

AUTHOR:		Paul L. DuBois, Nov  4, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/21/94	Initial revision


DESCRIPTION:
	C Interface to hash table library
	The hash library API can be thought of as:


Data:	1-4 bytes | fptr to be followed
Opaque:	dword
Key:	16 random-ish bits


Add:	Data -> void

Lookup:	Opaque, Key -> Data | NULL
  Foreach X such that Add(X) and _hash(X) == Key
    if _compare(X, Opaque)
      return X
  return NULL

Remove:	Opaque, Key -> Data | NULL

  With the user providing:

_hash:	Data -> Key
_compare: Data, Opaque -> Bool
		
	$Id: hash.h,v 1.1 97/07/16 09:09:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _HASH_H_
#define _HASH_H_

#include <geos.h>


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %		Hash structures and callbacks
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * Typedefs for the callback functions needed by HashTableCreate
 *
 * Callback functions, general notes:
 *
 *	If HTF_POINTER_SEMANTICS is set, elementData is actually a pointer
 *	to the data section of a HashTableEntry structure.  Otherwise,
 *	elementData is a dword, the least significant bytes of which contain
 *	the data from the entry.
 *
 *	ds=dgroup will not be set up for the callback functions.  If you
 *	need dgroup, the following works:
 *		GeodeLoadDGroup(GeodeGetCodeProcessHandle());
 *	
 * Hash function:
 *
 * 	word _pascal hash(dword elementData, void *header);
 * 
 *	elementData is the dword (or less) that was stored in the hash
 *	table entry.  If fewer than 4 bytes were stored, they will be
 *	in the least significant bytes of the dword.  If HTF_POINTER_SEMANTICS
 *	is set, then it is a far pointer to the element data.
 *	
 *	The function should return 16 bits of hash.
 *   	Do NOT do anything that would cause hash table's LMem heap to
 *	be shuffled!
 * 
 *	header is a pointer to the HashTableHeader.
 *
 *	This function should return a word of hash.
 *
 *   	Notes:		Do NOT do anything that would cause hash table's
 *   			LMem heap to be shuffled!
 *
 * Comparison function:
 *
 * 	Boolean _pascal comp(dword callbackData,
 *			     dword elementData,
 *			     void _far *header);
 *
 *   	callbackData is the dword of data that was passed to HashTableLookup
 *	or HashTableDelete.
 *
 *	elementData is the dword (or less) that was stored in the hash
 *	table entry.  If fewer than 4 bytes were stored, they will be
 *	in the least significant bytes of the dword.  If HTF_POINTER_SEMANTICS
 *	is set, then it is a far pointer to the element data.
 *
 *	header is a pointer to the HashTableHeader.
 *
 *	This function should return TRUE if the elements are equal.
 *
 *   	Notes:		Do NOT do anything that would cause hash table's
 *   			LMem heap to be shuffled!
 */
typedef PCB(word, HashHashFunc, (dword eltData, void *header));
typedef PCB(Boolean, HashCompFunc, (dword cbData, dword eltData, void *header));

/*
 * HTF_POINTER_SEMANTICS -
 * 	pointers to data buffers are passed and returned instead
 * 	of the data itself.  Will be documented in routine headers
 * 	when implemented
 * 
 * HTF_C_API_CALLBACKS -
 * 	Must be set iff functions passed to HashTableCreate are written in C
 * 
 * HTF_NO_REPEAT_INSERT -
 * 	If set, HashTableAdd will assume that the element being added has not
 * 	been added before, and will not perform a search.  In EC, the search
 * 	is still made so we can fatal error if the assumption is violated.
 * 
 * HTF_ENTRY_SIZE -
 * 	Number of bytes to store with each hash table entry.  If this is
 * 	> 4, HTF_POINTER_SEMANTICS must be set.  If < 4, the least significant
 * 	bytes of the data dwords that are passed and returns will contain
 * 	the data.
 */
typedef WordFlags HashTableFlags;
/* 10 bits unused */
#define HTF_POINTER_SEMANTICS	(0x0020)
#define HTF_C_API_CALLBACKS	(0x0010)
#define HTF_NO_REPEAT_INSERT	(0x0008)
#define HTF_ENTRY_SIZE	(0x0004 | 0x0002 | 0x0001)
#define HTF_ENTRY_SIZE_OFFSET	0

/* size of this header should be kept even */
typedef struct {
    HashTableFlags	HTH_flags;
    word	HTH_tableSize;		/* # of list heads */
    HashHashFunc HTH_hashFunction;	/* hashing function */
    HashCompFunc HTH_compFunction;	/* comparison function */
    ChunkHandle	HTH_heap;		/* chunk containing entries */
    word	HTH_headerSize;
/*  even	-- no such thing as "even" directive in C */
} HashTableHeader;

typedef struct {
    word	HTE_link;		/* link to next entry in chain */
    byte	HTE_keyBits;		/* little bit of hash key */
/*  label byte	HTE_data */
} HashTableEntry;

/* Used mainly for an end-of-list marker */
#define MH_NULL_ELEMENT	(0xffff)


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %		Routines
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * HashTableCreate - Create a new hash table
 *
 * Pass:
 *	mh	handle to locked LMem block
 *	flags	HashTableFlags
 *	headerSize
 *		size of header.  This should be > sizeof(HashTableHeader).
 *		pass zero if you don't need any header space and want to
 *		use the default.
 *	numHeads
 *		initial # of list heads/hash buckets.  It's good if this
 *		is a prime number.
 *	hashFn	pointer to a hashing function; see docs by typedefs, above
 *	compFn	pointer to a comparison function; see docs by typedefs, above
 *	
 * Return:
 *	Returns a chunkhandle to the hash table, or zero if the allocation
 *	failed and LMF_RETURN_ERRORS set.
 * 
 *	WARNING: this routine MAY resize the LMem block and shuffle chunks.
 */
extern	ChunkHandle
    _pascal HashTableCreate
	(MemHandle mh,		/* locked handle to LMem block */
	 HashTableFlags flags,
	 word headerSize,	/* # bytes to reserve for header, 0=default */
	 word numHeads,
	 HashHashFunc hashFn,
	 HashCompFunc compFn);

/*
 * HashTableAdd - Add an entry to a table
 * Pass:
 *	ht	optr to hash table
 *	eltData	pointer to data to copy (if HTF_POINTER_SEMANTICS) or up to
 *		four bytes of data.  If HTF_ENTRY_SIZE < 4, the most
 *		significant bytes will be ignored.  Most likely, this will
 *		be something like an array element #, a chunk, or a handle.
 * Return:
 *	Returns true if the element was added.
 *
 *	Element will not be added iff eltData already exists in the hash
 *	table; if eltData is a HugeArray element #, then Add(ht, 1) and
 *	Add(ht, 2) will both succeed, even if elements 1 and 2 contain the
 *	same data.  If you think that an element with the same data may
 *	already exist, do a HashTableLookup first.
 *
 *	If the HTF_NO_REPEAT_INSERT flag is set, HashTableAdd
 *	will never return FALSE, but it will FatalError (in EC) if
 *	the "no duplicates" assumption is violated.  Most times, this is
 *	what you want, if passing the same eltData twice can only be a bug.
 *
 *	WARNING: this routine MAY resize the LMem block and shuffle chunks.
 */
extern	Boolean
    _pascal HashTableAdd(optr ht, dword eltData);

extern	Boolean _pascal HashTableLookup
    (optr ht, word hash, dword cbData, dword* eltData);

extern	Boolean _pascal HashTableRemove
    (optr ht, word hash, dword cbData, dword* eltData);

/* Returns FALSE on failure
 */
extern	Boolean _pascal HashTableResize
    (optr ht, word numBuckets);

/*
 * Description:	Look up (& maybe remove) an entry in the hash table
 * Pass:	ht	- Hash table
 *   		hash	- hash value of item you're looking up
 *   		cbData	- passed to callback routine
 *		eltData	- filled in if successful
 *
 * Return:	true if successful
 */

extern	word _pascal HashTableHash(char* string);
/*
 * Description:	Hash a string
 * Pass:	string	- ASCIIZ string
 * Return:	16 bit hash value
 */

/* XXX FIXME
extern	void _pascal ECCheckHashTable(optr ht);
*/
#endif /* _HASH_H_ */

/* Local variables: */
/* folded-file: t */
/* End: */
