/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991-2000 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	MapHeap.h
 * AUTHOR:	ayuen: September 01, 2000
 *
 * DESCRIPTION:
 *	This file defines structures and routines for managing the mapped
 *	heap window system.
 *
 *	$Id$
 *
 ***********************************************************************/

#ifndef	__MAPHEAP_H
#define __MAPHEAP_H

#include <geode.h>

/*
 * Functions for Map Heap management
 */

extern void _cdecl
    MapHeapEnter(MemHandle phyMemInfoBlk);

/***/

extern void _cdecl
    MapHeapLeave(void);

/***/

extern Boolean _cdecl
    MapHeapCreate(char permName[GEODE_NAME_SIZE], MemHandle *phyMemInfoBlk);

/***/

extern void _cdecl
    MapHeapDestroy(MemHandle phyMemInfoBlk);

/***/

extern Boolean _cdecl
    MapHeapMaybeInHeap(void *blockPtr);

/***/

extern void *_cdecl
    MapHeapMalloc(word blockSize);

/***/

extern void _cdecl
    MapHeapFree(void *blockPtr);

/***/

extern void *_cdecl
    MapHeapRealloc(void *blockPtr, word newSize);

/***/

extern ChunkHandle _cdecl
    LMemLockAllocAndReturnError(MemHandle block, word chunkSize);

/***/

extern ChunkHandle _cdecl
    LMemLockReAllocAndReturnError(optr chunkOptr, word chunkSize);

#ifdef __HIGHC__
pragma Alias(MapHeapEnter, "MAPHEAPENTER");
pragma Alias(MapHeapLeave, "MAPHEAPLEAVE");
pragma Alias(MapHeapCreate, "MAPHEAPCREATE");
pragma Alias(MapHeapDestroy, "MAPHEAPDESTROY");
pragma Alias(MapHeapMaybeInHeap, "MAPHEAPMAYBEINHEAP");
pragma Alias(MapHeapMalloc, "MAPHEAPMALLOC");
pragma Alias(MapHeapFree, "MAPHEAPFREE");
pragma Alias(MapHeapRealloc, "MAPHEAPREALLOC");
pragma Alias(LMemLockAllocAndReturnError, "LMEMLOCKALLOCANDRETURNERROR");
pragma Alias(LMemLockReAllocAndReturnError, "LMEMLOCKREALLOCANDRETURNERROR");
#endif

#endif /* __MAPHEAP_H */

