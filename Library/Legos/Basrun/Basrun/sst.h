/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	LEGOS
MODULE:		basrun
FILE:		SST.h

AUTHOR:		Paul L. DuBois, May 15, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 5/15/95	Initial version.

DESCRIPTION:
	Exported stuff for small string table module;
	currently used for runtime string tables.
	
	$Revision: 1.1 $

	Liberty version control
	$Id: sst.h,v 1.1 98/10/05 12:35:24 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _SST_H_
#define _SST_H_

#ifdef LIBERTY
#include <Legos/bsst.h>

/* mchen: in Liberty, a SST is no longer a hash table but just simple
          sorted array of strings and the lookup uses a binary search
          rather than a hash table lookup */

#define SST_NULL 65535
word SSTLookup(optr table, TCHAR *string, word tableSize);

#else	/* GEOS version below */

#include <mystdapp.h>
#include <hash.h>
#include <Legos/Bridge/bsst.h>

typedef struct 
{
    HashTableHeader	SSTH_meta;
    MemHandle		SSTH_block;	/* Memhandle where SST resides */
    ChunkHandle		SSTH_strings;	/* chunkarray of strings */
} SSTHeader;

/* SSTAlloc, SSTDestroy, SSTDeref, and SSTAdd are in Legos/Bridge/bsst.h */

word		SSTLookup(optr table, TCHAR* string);

#define SST_NULL CA_NULL_ELEMENT
#define SST_NUM_BUCKETS 53

#endif

#endif /* _SST_H_ */
