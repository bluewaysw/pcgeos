/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	LEGOS 
MODULE:		basrun
FILE:		strmap.h

AUTHOR:		Roy Goldman, Jun  7, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 6/ 7/95	Initial version.

DESCRIPTION:

        Runtime translation table from a compile time string
	identifier into its global heap token.

	This is an easy process because compile time tokens
	are simply counting numbers; first string is 0, second is 1,
	etc.  Hence we just dereference the nth entry in the table
	to find the heap token for a given string constant...

	It's a linked list of memory blocks, with each memory
	block holding up to 3000 strings.  Hence for most
	cases, a single memlock will do the trick....  For
	modules with massive number of strings, access will be longer.
	So what?

	This header file is for basrun-only use.

	$Revision: 1.1 $

	Liberty version control
	$Id: strmap.h,v 1.1 98/10/05 12:35:29 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _STRMAP_H_
#define _STRMAP_H_

#ifdef LIBERTY

#include <Legos/runheap.h>
#include <Legos/bstrmap.h>

typedef struct 
{
    word	size;		/* max # of entries in the table */
    word	count; 		/* # of entries added to the table */
} StrMapHeader;

#else	/* GEOS version below */

#include <Legos/runheap.h>
#include <Legos/Bridge/bstrmap.h>

typedef struct 
{
    MemHandle SMH_nextHandle;         /* Link to next block or NullHandle
					 if last */

    word      SMH_count;              /* Entries in this block */

    word      SMH_blockSpace;    /* there is currently room for
				    this many entries in the block. */
} StrMapHeader;

#endif

/* The main use at runtime of the string map, used
   to map a compile-time string key into a heap token */
RunHeapToken StrMapLookup(MemHandle strMap, word mapKey);

#if ERROR_CHECK

#define MAX_STRINGS_PER_BLOCK 10

#else

#define MAX_STRINGS_PER_BLOCK 3000

#endif


#endif /* _STRMAP_H_ */
