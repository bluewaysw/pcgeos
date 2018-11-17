/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	hugearr.h
 * AUTHOR:	Jim DeFrisco: October 20, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines HugeArray structures and routines.
 *
 *	$Id: hugearr.h,v 1.1 97/04/04 15:56:52 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__HUGEARR_H
#define __HUGEARR_H

/*
 *	Constants and Structures
 */

typedef struct {
    LMemBlockHeader	HAD_header;
    VMBlockHandle	HAD_data;
    ChunkHandle		HAD_dir;
    VMBlockHandle	HAD_xdir;
    VMBlockHandle	HAD_self;
    word		HAD_size;
} HugeArrayDirectory;

/***/

extern VMBlockHandle	/*XXX*/
    _pascal HugeArrayCreate(VMFileHandle vmFile, word elemSize, word headerSpace);

/***/

extern void 		/*XXX*/
    _pascal HugeArrayDestroy(VMFileHandle vmFile, VMBlockHandle vmBlock);

/***/

#define	HAL_COUNT(val) 	((word) (val))
#define	HAL_PREV(val) 	((word) ((val)>>16))

extern dword		/*XXX*/
    _pascal HugeArrayLock(VMFileHandle vmFile, VMBlockHandle vmBlock,
	          dword elemNum, void **elemPtr, word *elemSize);


/***/

extern void		/*XXX*/
    _pascal HugeArrayUnlock(void *elemPtr);

/***/

extern void		/*XXX*/
    _pascal HugeArrayLockDir(VMFileHandle vmFile, VMBlockHandle vmBlock,
		     void **elemPtr);

/***/

extern void		/*XXX*/
    _pascal HugeArrayUnlockDir(void *elemPtr);

/***/

extern dword		/*XXX*/
    _pascal HugeArrayAppend(VMFileHandle vmFile, VMBlockHandle vmBlock,
		    word numElem, const void *initData);

/***/

extern void 		/*XXX*/
    _pascal HugeArrayInsert(VMFileHandle vmFile, VMBlockHandle vmBlock,
		    word numElem, dword elemNum, const void *initData);

/***/

extern void		/*XXX*/
    _pascal HugeArrayDelete(VMFileHandle vmFile, VMBlockHandle vmBlock,
		    word numElem, dword elemNum);

/***/

extern dword		/*XXX*/
    _pascal HugeArrayGetCount(VMFileHandle vmFile, VMBlockHandle vmBlock);
				   

/***/

extern void		/*XXX*/
    _pascal HugeArrayReplace(VMFileHandle vmFile, VMBlockHandle vmBlock,
		     word numElem, dword elemNum, const void *initData);

/***/

extern word		/*XXX*/
    _pascal HugeArrayNext(void **elemPtr, word *size);

/***/

extern word		/*XXX*/
    _pascal HugeArrayPrev(void **elemPtr1, void **elemPtr2, word *size);

/***/

extern word		/*XXX*/
    _pascal HugeArrayExpand(void **elemPtr, word numElem, 
			    const void *initData);

/***/

extern word		/*XXX*/
    _pascal HugeArrayContract(void **elemPtr, word numElem);

/***/

extern void		/*XXX*/
    _pascal HugeArrayDirty(const void *elemPtr);

/***/

extern void		/*XXX*/
    _pascal HugeArrayResize(VMFileHandle vmFile, VMBlockHandle vmBlock,
		    	    dword elemNum, word newSize);

/***/

extern Boolean		/*XXX*/
    _pascal HugeArrayEnum(VMFileHandle vmFile, VMBlockHandle vmBlock,
			PCB(Boolean, callback,	/* TRUE to stop */
				(void *element, void *enumData)),
		    	dword startElement, dword count,
			void *enumData
		  );

/***/

extern void		/*XXX*/
    _pascal ECCheckHugeArray(VMFileHandle vmFile, VMBlockHandle vmBlock);

/***/

extern void		/*XXX*/
    _pascal HugeArrayCompressBlocks(VMFileHandle vmFile,VMBlockHandle vmBlock);

/***/

#ifdef __HIGHC__
pragma Alias(HugeArrayCreate, "HUGEARRAYCREATE");
pragma Alias(HugeArrayDestroy, "HUGEARRAYDESTROY");
pragma Alias(HugeArrayLock, "HUGEARRAYLOCK");
pragma Alias(HugeArrayUnlock, "HUGEARRAYUNLOCK");
pragma Alias(HugeArrayLockDir, "HUGEARRAYLOCKDIR");
pragma Alias(HugeArrayUnlockDir, "HUGEARRAYUNLOCKDIR");
pragma Alias(HugeArrayAppend, "HUGEARRAYAPPEND");
pragma Alias(HugeArrayInsert, "HUGEARRAYINSERT");
pragma Alias(HugeArrayDelete, "HUGEARRAYDELETE");
pragma Alias(HugeArrayGetCount, "HUGEARRAYGETCOUNT");
pragma Alias(HugeArrayReplace, "HUGEARRAYREPLACE");
pragma Alias(HugeArrayNext, "HUGEARRAYNEXT");
pragma Alias(HugeArrayPrev, "HUGEARRAYPREV");
pragma Alias(HugeArrayExpand, "HUGEARRAYEXPAND");
pragma Alias(HugeArrayContract, "HUGEARRAYCONTRACT");
pragma Alias(HugeArrayDirty, "HUGEARRAYDIRTY");
pragma Alias(HugeArrayResize, "HUGEARRAYRESIZE");
pragma Alias(HugeArrayEnum, "HUGEARRAYENUM");
pragma Alias(ECCheckHugeArray, "ECCHECKHUGEARRAY");
pragma Alias(HugeArrayCompressBlocks, "HUGEARRAYCOMPRESSBLOCKS");
#endif

#endif
