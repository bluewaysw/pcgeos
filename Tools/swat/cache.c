/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  cache.c
 * FILE:	  cache.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Cache_Create	    Create a new cache
 *	Cache_Destroy	    Nuke a cache and its elements
 *	Cache_Lookup	    Look up an element in a cache
 *	Cache_Enter 	    Enter an element into a cache
 *	Cache_InvalidateOne Throw out a single element of a cache
 *	Cache_InvalidateAll Throw out all elements of a cache
 *	Cache_Key   	    Return the key belonging to an entry
 *	Cache_Size  	    Return the number of elements in a cache
 *	Cache_MaxSize	    Return the maximum number of things that may
 *	    	    	    be cached.
 *	Cache_SetMaxSize    Set the number of elements that may be cached.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to implement a simple caching scheme. Caches are keyed
 *	either by a single address (word) or by a string and may be
 *	either FIFO or LRU, fixed-size or variable (with or without bound).
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: cache.c,v 4.12 97/04/18 14:51:31 dbaumann Exp $";
#endif lint

#include <config.h>
#include <compat/stdlib.h>
#include "swat.h"
#include "cache.h"
#include "cmd.h"

/*
 * The basic cache structure consists of a hash table and a linked list, the
 * former for quick lookup and the latter to maintain order. If the cache is
 * an LRU cache, each time an entry is looked up, it is placed at the front of
 * the queue. If it is FIFO, no such movement occurs. The list elements are
 * simply the Hash_Entry *'s for the various entries in the cache.
 */
typedef struct _Cache {
    Hash_Table	  	table;	    /* Table for lookups */
    Lst	    	  	list;	    /* List for ordering */
    int			max;	    /* Max allowed */
    int			num;	    /* Current size */
    int			flags;	    /* Initial flags */
    int			keyType;    /* For re-initializing the cache */
    Cache_DestroyProc  	*destroyProc;
} CacheRec, *CachePtr;

/*-
 *-----------------------------------------------------------------------
 * CacheDestroyEntry --
 *	Callback function for Cache_SetMaxSize via Lst_ForEachFrom.
 *	Destroys each element in turn and removes it from the hash
 *	table.
 *
 * Results:
 *	=== 0.
 *
 * Side Effects:
 *	The entry is destroyed and removed.
 *
 *-----------------------------------------------------------------------
 */
static int
CacheDestroyEntry(Cache_Entry    entry,
		  CachePtr	    c)
{
/*    assert(VALIDTPTR(entry,TAG_HASH));*/
    assert(VALIDTPTR(c,TAG_CACHE));
    if (c->destroyProc != (Cache_DestroyProc *)NoDestroy) {
	(*(c->destroyProc))((Cache)c, entry);
    }
    Hash_DeleteEntry(&c->table, entry);
    return(0);
}
/*-
 *-----------------------------------------------------------------------
 * Cache_Create --
 *	Create a cache for the caller.
 *
 * Results:
 *	The new cache.
 *
 * Side Effects:
 *	Memory be allocated.
 *
 *-----------------------------------------------------------------------
 */
Cache
Cache_Create(int    flags,
	     int    maxSize,
	     int    keyType,
	     Cache_DestroyProc *destroyProc)
{
    CachePtr	  	c;

    c = (CachePtr)malloc_tagged(sizeof(CacheRec), TAG_CACHE);
    Hash_InitTable(&c->table, 0, keyType, 0);
    c->list = Lst_Init(FALSE);
    c->num = 0;
    c->max = maxSize;
    c->flags = flags;
    c->keyType = keyType;
    c->destroyProc = destroyProc;

    return((Cache)c);
}

/*-
 *-----------------------------------------------------------------------
 * Cache_Destroy --
 *	Destroy a cache and all the elements of it. destroyProc should
 *	be NULL if the entries needn't be freed.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	All memory for the cache is freed up.
 *
 *-----------------------------------------------------------------------
 */
void
Cache_Destroy(Cache	cache,
	      Boolean	destroy)
{
    register CachePtr	c = (CachePtr)cache;

    assert(VALIDTPTR(cache,TAG_CACHE));

    if (destroy) {
	Lst_ForEach(c->list, CacheDestroyEntry, (LstClientData)cache);
    }
    Lst_Destroy(c->list, NOFREE);
    Hash_DeleteTable(&c->table);
    free((char *)c);
}

/*-
 *-----------------------------------------------------------------------
 * Cache_Lookup --
 *	Search for an entry in a cache. If it is not found, returns NULL.
 *
 * Results:
 *	The Cache_Entry for the key or NullEntry if none found.
 *
 * Side Effects:
 *	If the cache is LRU, the entry is moved to the front of the list.
 *
 *-----------------------------------------------------------------------
 */
Cache_Entry
Cache_Lookup(Cache	cache,
	     Address	key)
{
    register CachePtr	c = (CachePtr)cache;
    Cache_Entry	  	entry;

    entry = Hash_FindEntry(&c->table, key);
    if ((entry != NullEntry) && (c->flags & CACHE_LRU)) {
	LstNode	  	ln;

	ln = Lst_Member(c->list, (LstClientData)entry);
	if (ln != NILLNODE) {
	    if (ln != Lst_First(c->list)) {
		Lst_Move(c->list, ln, c->list, Lst_First(c->list), TRUE);
	    }
	} else {
	    Punt("Entry in cache (%xh) but not on list", cache);
	    /*NOTREACHED*/
	}
    }

    return(entry);
}

/*-
 *-----------------------------------------------------------------------
 * Cache_Enter --
 *	Find or create an entry for the given key in the cache. If the
 *	entry was created and newPtr is non-null, *newPtr is set TRUE.
 *
 * Results:
 *	The new (or old) entry.
 *
 * Side Effects:
 *	An entry may be made in the table, or the old entry moved to
 *	the front of the list.
 *
 *-----------------------------------------------------------------------
 */
Cache_Entry
Cache_Enter(Cache   cache,
	    Address key,
	    Boolean *newPtr)
{
    register CachePtr	c = (CachePtr)cache;
    Cache_Entry		entry;
    Boolean 	  	new;

    assert(VALIDTPTR(cache,TAG_CACHE));
    /*
     * First create the entry, if necessary, or at the very least find
     * the old one.
     */
    entry = Hash_CreateEntry(&c->table, key, &new);

    if (entry == NullEntry) {
	Punt("Cache_Enter: Hash_CreateEntry returned NULL");
	/*NOTREACHED*/
    }
    
    /*
     * If this isn't a new entry, shift it to the front of the list.
     */
    if (!new) {
	LstNode	  	ln;
	
	ln = Lst_Member(c->list, (LstClientData)entry);
	if (ln != NILLNODE) {
	    Lst_Remove(c->list, ln);
	}
	c->num -= 1;
    }

    (void)Lst_AtFront(c->list, (LstClientData)entry);

    c->num += 1;
    
    if ((c->num > c->max) && (c->max > 0)) {
	/*
	 * If the cache is too large, destroy the last member on the list.
	 */
	Cache_Entry	flushed;
	LstNode	  	ln;

	ln = Lst_Last(c->list);
	flushed = (Cache_Entry)Lst_Datum(ln);
	Lst_Remove(c->list, ln);

	CacheDestroyEntry(flushed, c);
	c->num -= 1;
    }

    /*
     * If the caller also wanted to know if the entry is new, tell it.
     */
    if (newPtr != (Boolean *)NULL) {
	*newPtr = new;
    }
    
    return(entry);
}

/*-
 *-----------------------------------------------------------------------
 * Cache_InvalidateOne --
 *	Invalidate a single entry in the cache.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The entry is deleted and the destroyProc called, if defined.
 *
 *-----------------------------------------------------------------------
 */
void
Cache_InvalidateOne(Cache	cache,
		    Cache_Entry	entry)
{
    register CachePtr	c = (CachePtr)cache;
    LstNode 	  	ln;

    assert(VALIDTPTR(cache,TAG_CACHE));
/*    assert(VALIDTPTR(entry,TAG_HASH));*/

    ln = Lst_Member(c->list, (LstClientData)entry);
    if (ln == NILLNODE) {
	Punt("Invalidating entry that's not in a cache?");
	/*NOTREACHED*/
    }
    Lst_Remove(c->list, ln);
    c->num -= 1;

    CacheDestroyEntry(entry, c);
}

/*-
 *-----------------------------------------------------------------------
 * Cache_InvalidateAll --
 *	Invalidate all the entries in the given cache.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The destroyProc is called for each element in the cache, if a
 *	destroyProc was given.
 *
 *-----------------------------------------------------------------------
 */
void
Cache_InvalidateAll(Cache   cache,	/* Cache to invalidate */
		    Boolean destroy)	/* TRUE if should destroy entries, too */
{
    register CachePtr	c = (CachePtr)cache;

    assert(VALIDTPTR(cache,TAG_CACHE));
    if (destroy) {
	Lst_ForEach(c->list, CacheDestroyEntry, (LstClientData)cache);
    }
    Lst_Destroy(c->list, NOFREE);
    Hash_DeleteTable(&c->table);

    Hash_InitTable(&c->table, 0, c->keyType, 0);
    c->list = Lst_Init(FALSE);
    c->num = 0;
}

/*-
 *-----------------------------------------------------------------------
 * Cache_Key --
 *	Return the key for a given element in the cache.
 *
 * Results:
 *	The key for the element.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Address
Cache_Key(Cache		cache,
	  Cache_Entry	entry)
{
    register CachePtr	c = (CachePtr)cache;

    assert(VALIDTPTR(cache,TAG_CACHE));
/*    assert(VALIDTPTR(entry,TAG_HASH));*/
    if (c->keyType == CACHE_STRING) {
	return ((Address)entry->key.name);
    } else {
	return (entry->key.ptr);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Cache_Size --
 *	Find the number of entries in the cache.
 *
 * Results:
 *	The number of entries in the cache.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Cache_Size(Cache    cache)
{
    assert(VALIDTPTR(cache,TAG_CACHE));
    return (((CachePtr)cache)->num);
}
/*-
 *-----------------------------------------------------------------------
 * Cache_MaxSize --
 *	Find the maximum number of entries in the cache.
 *
 * Results:
 *	The maximum number of entries in the cache.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Cache_MaxSize(Cache    cache)
{
    assert(VALIDTPTR(cache,TAG_CACHE));
    return (((CachePtr)cache)->max);
}

/*-
 *-----------------------------------------------------------------------
 * CacheFindByNum --
 *	A "find" callback function for Cache_SetMaxSize to find the
 *	nth element of the list. The clientdata is a pointer to the
 *	number of the element desired, and this simply decrements it and
 *	returns 0 when the number is 0.
 *
 * Results:
 *	0 if the counter is 0 and non-zero if not.
 *
 * Side Effects:
 *	The counter is decremented.
 *
 *-----------------------------------------------------------------------
 */
static int
CacheFindByNum(Cache_Entry  entry,
	       int	    *counterPtr)
{
/*    assert(VALIDTPTR(entry,TAG_HASH));*/
    return (--(*counterPtr));
}


/*-
 *-----------------------------------------------------------------------
 * Cache_SetMaxSize --
 *	Change the maximum number of entries allowed in the cache.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Any entries over this limit are destroyed.
 *
 *-----------------------------------------------------------------------
 */
void
Cache_SetMaxSize(Cache	cache,
		 int	size)
{
    register CachePtr	c = (CachePtr)cache;
    int	    	  	num;
    register Lst  	l;
    register LstNode	last;
    register LstNode  	ln;
    
    assert(VALIDTPTR(cache,TAG_CACHE));

    c->max = size;

    if ((c->num > c->max) && (c->max > 0)) {
	num = c->max;
	l = c->list;

	/*
	 * Find the num'th entry in the list.
	 */
	ln = Lst_Find(l, (LstClientData)&num, CacheFindByNum);

	/*
	 * Destroy all entries beyond that one (we know there are entries
	 * beyond it...).
	 */
	Lst_ForEachFrom(l, Lst_Succ(ln), CacheDestroyEntry, (LstClientData)c);

	/*
	 * Remove the nodes themselves from the list.
	 */
	while ((last = Lst_Last(l)) != ln) {
	    Lst_Remove(l, last);
	}
	
	c->num = c->max;
    }
}

/******************************************************************************
 *
 *		       TCL CACHE IMPLEMENTATION
 *
 ******************************************************************************/
typedef struct {
    CacheRec	common;
    char    	*flushProc; 	/* Name of the flush procedure */
    Boolean 	destroy;	/* Flag to tell whether to call flushProc */
} TclCacheRec, *TclCachePtr;


/***********************************************************************
 *				CacheTclFlush
 ***********************************************************************
 * SYNOPSIS:	    Handle the flushing of an entry from a TCL-created
 *	    	    cache.
 * CALLED BY:	    Cache stuff
 * RETURN:	    nothing
 * SIDE EFFECTS:    the value string for the entry is freed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/25/91		Initial Revision
 *
 ***********************************************************************/
static void
CacheTclFlush(Cache 	    cache,
	      Cache_Entry   entry)
	      
{
    TclCachePtr	tcp = (TclCachePtr)cache;
    
    if ((tcp->flushProc != 0) && tcp->destroy) {
	char	*argv[3];
	char	cacheToken[16];
	char	entryToken[16];
	char	*cmd;

	sprintf(cacheToken, "%u", (unsigned int)tcp);
	sprintf(entryToken, "%u", (unsigned int)entry);

	argv[0] = tcp->flushProc;
	argv[1] = cacheToken;
	argv[2] = entryToken;

	cmd = Tcl_Merge(3, argv);
	(void)Tcl_Eval(interp, cmd, 0, (const char **)0);
	free(cmd);
    }

    free((char *)Cache_GetValue(entry));
    Cache_SetValue(entry, 0);
}

/***********************************************************************
 *				Cache_EnumFirst
 ***********************************************************************
 * SYNOPSIS:	    Begin enumerating the entries currently in the cache.
 *	    	    Entries are enumerated in no particular order.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The first entry in the cache, or NullEntry if cache
 *	    	    is empty.
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 8/92		Initial Revision
 *
 ***********************************************************************/
Cache_Entry
Cache_EnumFirst(Cache	    	cache,
		Cache_Search	*searchPtr)
{
    return (Hash_EnumFirst(&((CachePtr)cache)->table, searchPtr));
}


/***********************************************************************
 *				CacheCmd
 ***********************************************************************
 * SYNOPSIS:	    TCL interface for the creation and maintenance of
 *	    	    caches.
 * CALLED BY:	    TCL
 * RETURN:	    TCL result code
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/25/91		Initial Revision
 *
 ***********************************************************************/
#define CACHE_CREATE	    (ClientData)0
#define CACHE_DESTROY	    (ClientData)1
#define CACHE_LOOKUP	    (ClientData)2
#define CACHE_ENTER 	    (ClientData)3
#define CACHE_INVAL_ONE	    (ClientData)4
#define CACHE_INVAL_ALL	    (ClientData)5
#define CACHE_KEY   	    (ClientData)6
#define CACHE_SIZE  	    (ClientData)7
#define CACHE_MAXSIZE	    (ClientData)8
#define CACHE_SET_MAXSIZE   (ClientData)9
#define CACHE_GETVALUE 	    (ClientData)10
#define CACHE_SETVALUE	    (ClientData)11
static const Tcl_SubCommandRec cacheCmds[] = {
    {"create",	CACHE_CREATE,	2, 3, "(lru|fifo) <maxSize> [<flushProc>]"},
    {"destroy",	CACHE_DESTROY,	1, 2, "<cache> [flush|noflush]"},
    {"lookup",	CACHE_LOOKUP,	2, 2, "<cache> <key>"},
    {"enter",	CACHE_ENTER,	2, 2, "<cache> <key>"},
    {"invalone", CACHE_INVAL_ONE,2, 2, "<cache> <entry>"},
    {"invalall",	CACHE_INVAL_ALL,1, 2, "<cache> [flush|noflush]"},
    {"key",  	CACHE_KEY,  	2, 2, "<cache> <entry>"},
    {"size", 	CACHE_SIZE, 	1, 1, "<cache>"},
    {"maxsize",	CACHE_MAXSIZE,	1, 1, "<cache>"},
    {"setmaxsize",CACHE_SET_MAXSIZE, 2, 2, "<cache> <maxSize>"},
    {"getval",	CACHE_GETVALUE,	2, 2, "<cache> <entry>"},
    {"setval",	CACHE_SETVALUE, 3, 3, "<cache> <entry> <value>"},
    {TCL_CMD_END}
};

DEFCMD(cache,Cache,TCL_EXACT,cacheCmds,swat_prog,
"Usage:\n\
    cache create (lru|fifo) <maxSize> [<flushProc>]\n\
    cache destroy <cache> [flush|noflush]\n\
    cache lookup <cache> <key>\n\
    cache enter <cache> <key>\n\
    cache invalone <cache> <entry>\n\
    cache invalall <cache> [flush|noflush]\n\
    cache key <cache> <entry>\n\
    cache size <cache>\n\
    cache maxsize <cache>\n\
    cache setmaxsize <cache> <maxSize>\n\
    cache getval <cache> <entry>\n\
    cache setval <cache> <entry> <value>\n\
\n\
Examples:\n\
    \"var cache [cache create lru 10]\"	    Creates a cache of 10 items that are\n\
					    flushed on a least-recently-used\n\
					    basis. The returned token is saved\n\
					    for later use.\n\
    \"var entry [cache lookup $cache mom]\"   Sees if an entry with the key \"mom\"\n\
					    is in the cache and saves its entry\n\
					    token if so.\n\
    \"echo mom=[cache getval $cache $entry]\" Retrieves the value stored in the\n\
					    entry for \"mom\" and echoes it.\n\
    \"cache invalone $cache $entry\"  	    Flushes the entry just found from\n\
					    the cache.\n\
    \"cache destroy $cache\"  	    	    Destroys the cache.\n\
\n\
Synopsis:\n\
    The cache command, as the name implies, maintains a cache of data that\n\
    is keyed by strings. When a new entry is added to an already-full cache,\n\
    an existing entry is automatically flushed based on the usage method\n\
    with which the cache was created: lru or fifo. If lru, the least-recently-\n\
    used entry is flushed; if fifo, the oldest entry is flushed.\n\
\n\
Notes:\n\
    * Unlike the \"table\" command, the \"cache\" command returns tokens for\n\
      entries, not their values, to allow entries to be individually flushed\n\
      or their values altered.\n\
\n\
    * If a <flushProc> is specified when the cache is created, the procedure\n\
      will be called each time an entry is flushed from the cache. It\n\
      will be called \"<flushProc> <cache> <entry>\" where <cache> is the token\n\
      for the cache, and <entry> is the token for the entry being flushed.\n\
\n\
    * If the maximum size of a full cache is reduced, entries will be flushed\n\
      from the cache to bring it down to the new maximum size. The <flushProc>\n\
      will be called for each of them.\n\
\n\
    * If the values stored in the cache entries should not be freed when the\n\
      cache is destroyed, pass \"noflush\" to \"cache destroy\". The default\n\
      is to flush (and hence call the <flushProc>) all entries from the cache\n\
      before it is destroyed.\n\
\n\
    * If the values stored in the cache entries should not be freed when the\n\
      cache is flushed, pass \"noflush\" to \"cache invalall\". The default\n\
      is to call the <flushProc> for each entry in the cache before it is\n\
      actually flushed.\n\
\n\
    * If an entry is not found in the cache, \"cache lookup\" will return an\n\
      empty string.\n\
\n\
    * When an entry is created, \"cache enter\" returns a 2-list containing\n\
      the entry token as its first element, and an integer, as its second\n\
      element, that is either non-zero or 0, to tell if the entry is new or\n\
      was already present, respectively.\n\
")
{
    TclCachePtr	    tcp = 0;

    if (clientData != CACHE_CREATE) {
	tcp = (TclCachePtr)atoi(argv[2]);

	if (malloc_tag((char *)tcp) != TAG_CACHE) {
	    Tcl_RetPrintf(interp, "%s %s: %s not a valid cache", argv[0],
			  argv[1], argv[2]);
	    return(TCL_ERROR);
	}
    }

    switch((int)clientData) {
	case CACHE_CREATE:
	{
	    int	    flags;
	    int	    maxSize;

	    if (strcmp(argv[2], "lru") == 0) {
		flags = CACHE_LRU;
	    } else if (strcmp(argv[2], "fifo") == 0) {
		flags = 0;
	    } else {
		return (TCL_SUBUSAGE);
	    }

	    maxSize = cvtnum(argv[3], (char **)NULL);

	    tcp = (TclCachePtr)Cache_Create(flags, maxSize, CACHE_STRING,
					    CacheTclFlush);
	    tcp = (TclCachePtr)realloc_tagged((char *)tcp, sizeof(TclCacheRec));

	    if (argc == 5) {
		tcp->flushProc = (char *)malloc(strlen(argv[4])+1);
		strcpy(tcp->flushProc, argv[4]);
	    } else {
		tcp->flushProc = 0;
	    }

	    Tcl_RetPrintf(interp, "%d", tcp);
	    break;
	}
	case CACHE_DESTROY:
	{
	    char    *flushProc;

	    tcp->destroy = TRUE;

	    if (argc != 3) {
		int length;

		length = strlen(argv[3]);
		if (strncmp(argv[3], "flush", length) == 0) {
		    tcp->destroy = TRUE;
		} else if (strncmp(argv[3], "noflush", length) == 0) {
		    tcp->destroy = FALSE;
		} else {
		    return (TCL_SUBUSAGE);
		}
	    }
	    
	    flushProc = tcp->flushProc;
	    Cache_Destroy((Cache)tcp, TRUE);

	    if (flushProc != 0) {
		free(flushProc);
	    }
	    break;
	}
	case CACHE_LOOKUP:
	{
	    Cache_Entry	entry;

	    entry = Cache_Lookup((Cache)tcp, (Address)argv[3]);

	    if (entry != NullEntry) {
		Tcl_RetPrintf(interp, "%d", entry);
	    } else {
		Tcl_Return(interp, "", TCL_STATIC);
	    }
	    break;
	}
	case CACHE_ENTER:
	{
	    Cache_Entry entry;
	    Boolean new;

	    entry = Cache_Enter((Cache)tcp, (Address)argv[3], &new);
	    malloc_settag((malloc_t)entry, TAG_HASH);

	    /*
	     * Give it a 0 value so we know it's not been set yet.
	     */
	    Cache_SetValue(entry, 0);

	    Tcl_RetPrintf(interp, "%d %d", entry, new);
	    break;
	}
	case CACHE_INVAL_ONE:
	{
	    Cache_Entry entry;

	    entry = (Cache_Entry)atoi(argv[3]);
	    if (malloc_tag((char *)entry) != TAG_HASH) {
		Tcl_RetPrintf(interp, "%s %s: %s is not a valid cache entry",
			      argv[0], argv[1], argv[3]);
		return (TCL_ERROR);
	    }
	    Cache_InvalidateOne((Cache)tcp, entry);
	    break;
	}
	case CACHE_INVAL_ALL:
	{
	    tcp->destroy = TRUE;

	    if (argc != 3) {
		int length;

		length = strlen(argv[3]);
		if (strncmp(argv[3], "flush", length) == 0) {
		    tcp->destroy = TRUE;
		} else if (strncmp(argv[3], "noflush", length) == 0) {
		    tcp->destroy = FALSE;
		} else {
		    return (TCL_SUBUSAGE);
		}
	    }
	    
	    Cache_InvalidateAll((Cache)tcp, TRUE);
	    break;
	}
	case CACHE_KEY:
	{
	    Cache_Entry	    entry;

	    entry = (Cache_Entry)atoi(argv[3]);
	    if (malloc_tag((char *)entry) != TAG_HASH) {
		Tcl_RetPrintf(interp, "%s %s: %s is not a valid cache entry",
			      argv[0], argv[1], argv[3]);
		return (TCL_ERROR);
	    }
	    Tcl_Return(interp, (const char *)Cache_Key((Cache)tcp, entry),
		       TCL_VOLATILE);
	    break;
	}
	case CACHE_SIZE:
	    Tcl_RetPrintf(interp, "%d", Cache_Size((Cache)tcp));
	    break;
	case CACHE_MAXSIZE:
	    Tcl_RetPrintf(interp, "%d", Cache_MaxSize((Cache)tcp));
	    break;
	case CACHE_SET_MAXSIZE:
	{
	    int	    maxSize;

	    maxSize = atoi(argv[3]);
	    Cache_SetMaxSize((Cache)tcp, maxSize);
	    break;
	}
	case CACHE_GETVALUE:
	{
	    Cache_Entry	    entry;
	    char    	    *value;

	    entry = (Cache_Entry)atoi(argv[3]);
	    if (malloc_tag((char *)entry) != TAG_HASH) {
		Tcl_RetPrintf(interp, "%s %s: %s is not a valid cache entry",
			      argv[0], argv[1], argv[3]);
		return (TCL_ERROR);
	    }
	    value = Cache_GetValue(entry);

	    if (value != 0) {
		Tcl_Return(interp, value, TCL_VOLATILE);
	    } else {
		Tcl_Return(interp, NULL, TCL_STATIC);
	    }
	    break;
	}
	case CACHE_SETVALUE:
	{
	    Cache_Entry	    entry;
	    char    	    *value;

	    entry = (Cache_Entry)atoi(argv[3]);
	    if (malloc_tag((char *)entry) != TAG_HASH) {
		Tcl_RetPrintf(interp, "%s %s: %s is not a valid cache entry",
			      argv[0], argv[1], argv[3]);
		return (TCL_ERROR);
	    }
	    value = Cache_GetValue(entry);

	    if (value != 0) {
		free(value);
	    }

	    value = (char *)malloc(strlen(argv[4])+1);
	    strcpy(value, argv[4]);
	    Cache_SetValue(entry, value);
	    break;
	}
    }
    return(TCL_OK);
}
