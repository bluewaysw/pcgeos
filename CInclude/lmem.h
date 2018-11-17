/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	lmem.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines local memory structures and routines.
 *
 *	$Id: lmem.h,v 1.1 97/04/04 15:59:04 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__LMEM_H
#define __LMEM_H

/*
 *	Definitions for local memory block structures
 */

/* Types of local memory blocks */

typedef enum /* word */ {
    LMEM_TYPE_GENERAL,
    LMEM_TYPE_WINDOW,
    LMEM_TYPE_OBJ_BLOCK,
    LMEM_TYPE_GSTATE,
    LMEM_TYPE_FONT_BLK,
    LMEM_TYPE_GSTRING,
    LMEM_TYPE_DB_ITEMS
} LMemType;

/* Flags for a local memory block */

typedef WordFlags LocalMemoryFlags;
#define LMF_HAS_FLAGS		0x8000
#define LMF_IN_RESOURCE		0x4000
#define LMF_DETACHABLE		0x2000
#define LMF_DUPLICATED		0x1000
#define LMF_RELOCATED		0x0800
#define LMF_AUTO_FREE		0x0400
#define LMF_IN_LMEM_ALLOC	0x0200
#define LMF_IS_VM		0x0100
#define LMF_NO_HANDLES		0x0080
#define LMF_NO_ENLARGE		0x0040
#define LMF_RETURN_ERRORS	0x0020
#define LMF_DEATH_COUNT		0x0007

/* Structure at the beginning of every local-memory block. */

typedef struct {
    MemHandle		LMBH_handle;
    word		LMBH_offset;
    LocalMemoryFlags	LMBH_flags;
    LMemType		LMBH_lmemType;
    word		LMBH_blockSize;
    word		LMBH_nHandles;
    word		LMBH_freeList;
    word		LMBH_totalFree;
} LMemBlockHeader;

/*
 * Constants and structures passed to local memory routines
 */

/* Standard values to pass to LMemInitHeap */

#define STD_INIT_HEAP		256
#define STD_INIT_HANDLES	16
#define STD_LMEM_OBJECT_FLAGS   (LMF_HAS_FLAGS | LMF_RELOCATED)

/***/

extern ChunkHandle	/*XXX*/
    _pascal LMemAlloc(MemHandle mh, word chunkSize);

/***/

extern MemHandle
    _pascal MemAllocLMem(LMemType type, word headerSize);

/***/

extern void
    _pascal LMemInitHeap(MemHandle mh,
		 LMemType type,
		 LocalMemoryFlags flags,
		 word lmemOffset,
		 word numHandles,
		 word freeSpace);

/***/

extern void *
    _pascal LMemDeref(optr o);

#define LMemDerefHandles(mh, ch) \
    LMemDeref(ConstructOptr(mh, ch))

/***/

extern void	/*XXX*/
    _pascal LMemFree(optr o);

#define LMemFreeHandles(mh, ch) \
    LMemFree(ConstructOptr(mh, ch))

/***/

extern Boolean	/*XXX*/
    _pascal LMemReAlloc(optr o, word chunkSize);

#define LMemReAllocHandles(mh, ch, sz) \
    LMemReAlloc(ConstructOptr(mh, ch), sz)

/***/

extern Boolean	/*XXX*/
    _pascal LMemInsertAt(optr o, word insertOffset, word insertCount);

#define LMemInsertAtHandles(mh, ch, io, ic) \
    LMemInsertAt(ConstructOptr(mh, ch), io, ic)

/***/

extern void	/*XXX*/
    _pascal LMemDeleteAt(optr o, word deleteOffset, word deleteCount);

#define LMemDeleteAtHandles(mh, ch, do, dc) \
    LMemDeleteAt(ConstructOptr(mh, ch), do, dc)

/***/

extern void	/*XXX*/
    _pascal LMemContract(MemHandle mh);

/***/

extern word	/*XXX*/
    _pascal LMemGetChunkSize(optr o);

#define LMemGetChunkSizeHandles(mh, ch) \
    LMemGetChunkSize(ConstructOptr(mh, ch))

/*
 *	Macros for local memory chunks
 */

/* Offset from a pointer to a chunk to the size of that chunk. */
/* THIS SHOULD ONLY BE USED IN EXCEPTIONAL CIRCUMSTANCES. */

#define LMC_size	(-2)

#define LMemGetChunkSizePtr(ptr) ((word) (*(((word *)ptr)-1)-2))

#ifdef __HIGHC__
pragma Alias(MemAllocLMem, "MEMALLOCLMEM");
pragma Alias(LMemInitHeap, "LMEMINITHEAP");
pragma Alias(LMemAlloc, "LMEMALLOC");
pragma Alias(LMemDeref, "LMEMDEREF");
pragma Alias(LMemFree, "LMEMFREE");
pragma Alias(LMemReAlloc, "LMEMREALLOC");
pragma Alias(LMemInsertAt, "LMEMINSERTAT");
pragma Alias(LMemDeleteAt, "LMEMDELETEAT");
pragma Alias(LMemContract, "LMEMCONTRACT");
pragma Alias(LMemGetChunkSize, "LMEMGETCHUNKSIZE");
#endif

#endif
