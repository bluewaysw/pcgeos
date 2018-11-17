/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	heap.h
 * AUTHOR:	Tony Requist: February 1, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines heap management structures and routines.
 *
 *	$Id: heap.h,v 1.1 97/04/04 15:58:25 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__HEAP_H
#define __HEAP_H

/*
 *	Constants for values to pass to heap routines
 */

typedef ByteFlags HeapFlags;
#define HF_FIXED	0x80
#define HF_SHARABLE	0x40
#define HF_DISCARDABLE	0x20
#define HF_SWAPABLE	0x10
#define HF_LMEM		0x08
#define HF_DISCARDED	0x02
#define HF_SWAPPED	0x01

#define HF_STATIC	(HF_DISCARDABLE | HF_SWAPABLE)
#define HF_DYNAMIC	(HF_SWAPABLE)

/* Flags for allocation type */

typedef ByteFlags HeapAllocFlags;
#define HAF_ZERO_INIT		0x80
#define HAF_LOCK		0x40
#define HAF_NO_ERR		0x20
#define HAF_UI			0x10
#define HAF_READ_ONLY		0x08
#define HAF_OBJECT_RESOURCE	0x04
#define HAF_CODE		0x02
#define HAF_CONFORMING		0x01

/*
 * a few shortcuts for allocation flags
 */

/* standard block allocation flags */

#define HAF_STANDARD		0
#define HAF_STANDARD_NO_ERR	(HAF_NO_ERR)

/* allocation flags to allocate locked block */

#define HAF_STANDARD_LOCK	(HAF_LOCK)
#define HAF_STANDARD_NO_ERR_LOCK (HAF_NO_ERR | HAF_LOCK)

/***/

extern MemHandle
    _pascal MemAlloc(word byteSize, HeapFlags hfFlags, HeapAllocFlags haFlags);

/***/

extern MemHandle	/*XXX*/
    _pascal MemAllocSetOwner(GeodeHandle owner, word byteSize,
		     HeapFlags hfFlags, HeapAllocFlags haFlags);

/***/

extern MemHandle	/*XXX*/
    _pascal MemReAlloc(MemHandle mh, word byteSize, HeapAllocFlags heapAllocFlags);

/***/

extern void
    _pascal MemFree(MemHandle mh);

/***/

extern void 	    	/*XXX*/
    _pascal MemDiscard(MemHandle mh);

/***/

#define MGI_LOCK_COUNT(val) ((byte) ((val) >> 8))
#define MGI_TYPE_FLAGS(val) ((byte) (val))

typedef enum /* word */ {
    MGIT_SIZE=0,	/* size in bytes */
    MGIT_FLAGS_AND_LOCK_COUNT=2,	/* use MGI_LOCK_COUNT and MGI_FLAGS */
    MGIT_OWNER_OR_VM_FILE_HANDLE=4,
    MGIT_ADDRESS=6,
    MGIT_OTHER_INFO=8,
    MGIT_EXEC_THREAD=10
} MemGetInfoType;

extern word	
    _pascal MemGetInfo(MemHandle mh, MemGetInfoType info);

/***/

extern void
    _pascal MemModifyFlags(MemHandle mh,
		   HeapFlags bitsToSet,
		   HeapFlags bitsToClear);

/***/

extern void	/*XXX*/
    _pascal HandleModifyOwner(Handle mh, GeodeHandle owner);

/***/

extern void	/*XXX*/
    _pascal MemModifyOtherInfo(MemHandle mh, word otherInfo);

/***/

extern void *
    _pascal MemLock(MemHandle mh);

/***/

extern void
    _pascal MemUnlock(MemHandle mh);

/***/

extern void
    _pascal HandleP(MemHandle mh);

/***/

extern void
    _pascal HandleV(MemHandle mh);

/***/

extern void *
    _pascal MemPLock(MemHandle mh);

/***/

extern void
    _pascal MemUnlockV(MemHandle mh);

/***/

extern void *
    _pascal MemThreadGrab(MemHandle mh);

/***/

#define BLOCK_GRABBED 1

extern void *
    _pascal MemThreadGrabNB(MemHandle mh);

/***/

extern void
    _pascal MemThreadRelease(MemHandle mh);

/***/

extern void *
    _pascal MemDeref(MemHandle mh);

/***/

extern GeodeHandle	/*XXX*/
    _pascal MemOwner(MemHandle mh);

/***/

extern MemHandle	/*XXX*/
    _pascal MemPtrToHandle(void *ptr);

/***/	    	    	/*XXX*/

extern void
    _pascal MemInitRefCount(MemHandle mh, word count);

/***/	    	    	/*XXX*/

extern void
    _pascal MemIncRefCount(MemHandle mh);

/***/	    	    	/*XXX*/

extern void
    _pascal MemDecRefCount(MemHandle mh);


/***/
extern void *	    	/*XXX*/
    _pascal MemLockFixedOrMovable(void *ptr);

/***/

extern void 	    	/*XXX*/
    _pascal MemUnlockFixedOrMovable(void *ptr);

/***/
extern void *	    	/*XXX*/
    _pascal MemLockShared(MemHandle mh);

/***/

extern void 	    	/*XXX*/
    _pascal MemUnlockShared(MemHandle mh);

/***/

extern void *	    	/*XXX*/
    _pascal MemLockExcl(MemHandle mh);

/***/

#define MemUnlockExcl(mh) MemUnlockShared(mh)

/***/

extern void 	    	/*XXX*/
    _pascal MemDowngradeExclLock(MemHandle mh);

/***/

extern void *	    	/*XXX*/
    _pascal MemUpgradeSharedLock(MemHandle mh);

/***/

extern MemHandle
    _pascal LZGAllocCompressStack(GeodeHandle stackOwner);

/***/

extern void
    _pascal LZGFreeCompressStack(MemHandle compressStack);

/***/

extern int
    _pascal LZGCompress(byte *compressBuffer, byte *data,
			int dataSize, MemHandle compressStack);

/***/

extern int
    _pascal LZGUncompress(byte *dataBuffer, byte *compressedData);

/***/

extern int
    _pascal LZGGetUncompressedSize(byte *compressedData);


/*
 *	Argument for MSG_PROCESS_MEM_FULL
 */

typedef enum /* word */ {
    HC_SCRUBBING,
    HC_CONGESTED,
    HC_DESPERATE
} HeapCongestion;

#ifdef __HIGHC__
pragma Alias(MemAlloc, "MEMALLOC");
pragma Alias(MemAllocSetOwner, "MEMALLOCSETOWNER");
pragma Alias(MemReAlloc, "MEMREALLOC");
pragma Alias(MemFree, "MEMFREE");
pragma Alias(MemGetInfo, "MEMGETINFO");
pragma Alias(MemModifyFlags, "MEMMODIFYFLAGS");
pragma Alias(HandleModifyOwner, "HANDLEMODIFYOWNER");
pragma Alias(MemModifyOtherInfo, "MEMMODIFYOTHERINFO");
pragma Alias(MemLock, "MEMLOCK");
pragma Alias(MemUnlock, "MEMUNLOCK");
pragma Alias(HandleP, "HANDLEP");
pragma Alias(HandleV, "HANDLEV");
pragma Alias(MemPLock, "MEMPLOCK");
pragma Alias(MemUnlockV, "MEMUNLOCKV");
pragma Alias(MemThreadGrab, "MEMTHREADGRAB");
pragma Alias(MemThreadGrabNB, "MEMTHREADGRABNB");
pragma Alias(MemThreadRelease, "MEMTHREADRELEASE");
pragma Alias(MemDeref, "MEMDEREF");
pragma Alias(MemOwner, "MEMOWNER");
pragma Alias(MemPtrToHandle, "MEMPTRTOHANDLE");
pragma Alias(MemInitRefCount, "MEMINITREFCOUNT");
pragma Alias(MemIncRefCount, "MEMINCREFCOUNT");
pragma Alias(MemDecRefCount, "MEMDECREFCOUNT");
pragma Alias(MemLockFixedOrMovable, "MEMLOCKFIXEDORMOVABLE");
pragma Alias(MemUnlockFixedOrMovable, "MEMUNLOCKFIXEDORMOVABLE");
pragma Alias(MemLockExcl, "MEMLOCKEXCL");
pragma Alias(MemLockShared, "MEMLOCKSHARED");
pragma Alias(MemUnlockShared, "MEMUNLOCKSHARED");
pragma Alias(MemUpgradeSharedLock, "MEMUPGRADESHAREDLOCK");
pragma Alias(MemDowngradeExclLock, "MEMDOWNGRADEEXCLLOCK");
pragma Alias(MemDiscard, "MEMDISCARD");
pragma Alias(LZGAllocCompressStack, "LZGALLOCCOMPRESSSTACK");
pragma Alias(LZGFreeCompressStack, "LZGFREECOMPRESSSTACK");
pragma Alias(LZGCompress, "LZGCOMPRESS");
pragma Alias(LZGUncompress, "LZGUNCOMPRESS");
pragma Alias(LZGGetUncompressedSize, "LZGGETUNCOMPRESSEDSIZE");
#endif

#endif
