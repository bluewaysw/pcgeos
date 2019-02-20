/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Cache-module definitions.
 * FILE:	  cache.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Constant, type and function definitions for the Cache module.
 *	This module provides a fixed- or variable-size cache that may be
 *	flushed LRU. Entry keys are either strings or single-word values
 *	(q.v. the Hash module).
 *
* 	$Id: cache.h,v 4.3 92/07/07 19:08:40 adam Exp $
 *
 ***********************************************************************/
#ifndef _CACHE_H
#define _CACHE_H

#include    "hash.h"

/*
 * The cache is built on the Hash_Table data structure, so the entries we
 * return are just entries from the hash table.
 */
typedef void	  	*Cache;
typedef Hash_Entry	*Cache_Entry;
typedef Hash_Search 	Cache_Search;

#define NullCache 	((Cache)NULL)
#define NullEntry 	((Cache_Entry)NULL)

typedef void	    	Cache_DestroyProc(Cache cache, Cache_Entry entry);

/*
 * Constants for creation -- cache types and key types
 */
#define CACHE_LRU 	0x00000001  	/* LRU cache, else FIFO */

#define CACHE_ADDRESS	HASH_ONE_WORD_KEYS
#define CACHE_STRING	HASH_STRING_KEYS
#define CACHE_THIS(st)	sizeof(st)/sizeof(int)

/*
 * Accessor macros for cache entries
 */
#define Cache_GetValue(entry) Hash_GetValue(entry)
#define Cache_SetValue(entry, value) Hash_SetValue(entry, value)

/*
 * Function declarations
 */
extern Cache 	    Cache_Create (int flags, int maxSize, int keyType,
				  Cache_DestroyProc *destroyProc);
extern void 	    Cache_Destroy (Cache cache, Boolean destroy);
extern Cache_Entry  Cache_Lookup (Cache cache, Address key);
extern Cache_Entry  Cache_Enter (Cache cache, Address key, Boolean *newPtr);
extern void 	    Cache_InvalidateOne (Cache cache, Cache_Entry entry);
extern void 	    Cache_InvalidateAll (Cache cache, Boolean destroy);
extern Address 	    Cache_Key (Cache cache, Cache_Entry entry);
extern int  	    Cache_Size (Cache cache);
extern int  	    Cache_MaxSize (Cache cache);
extern void 	    Cache_SetMaxSize (Cache cache, int size);

extern Cache_Entry  Cache_EnumFirst(Cache cache, Cache_Search *searchPtr);
#define Cache_EnumNext(searchPtr) Hash_EnumNext(searchPtr)

#endif /* _CACHE_H */
