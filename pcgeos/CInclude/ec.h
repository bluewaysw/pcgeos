/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	ec.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines error checking structures and routines.
 *
 *	$Id: ec.h,v 1.1 97/04/04 15:58:16 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__EC_H
#define __EC_H

/*
 * Definitions for fatal errors
 */

#define SYSTEM_ERROR_CODES CAN_NOT_USE_CHUNKSIZEPTR_MACRO_ON_EMPTY_CHUNKS, \
    CHUNK_ARRAY_BAD_ELEMENT, MACRO_REQUIRES_FIXED_SIZE_ELEMENTS, CANNOT_USE_DBCS_IN_THIS_VERSION

/***/

extern void	/*XXX*/
    _pascal CFatalError(word code);

#define FatalError(code) CFatalError(code)

extern void
    _pascal CWarningNotice(word code);

#define Warning(code)	CWarningNotice(code)

/***/

extern void    /*XXX*/
    _pascal ECCheckFileHandle(FileHandle fh);

/***/

extern void	/*XXX*/
    _pascal ECCheckMemHandle(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ECCheckMemHandleNS(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ECCheckThreadHandle(ThreadHandle th);

/***/

extern void	/*XXX*/
    _pascal ECCheckProcessHandle(GeodeHandle gh);

/***/

extern void	/*XXX*/
    _pascal ECCheckResourceHandle(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ECCheckGeodeHandle(GeodeHandle gh);

/***/

extern void	/*XXX*/
    _pascal ECCheckDriverHandle(GeodeHandle gh);

/***/

extern void	/*XXX*/
    _pascal ECCheckLibraryHandle(GeodeHandle gh);

/***/

extern void	/*XXX*/
    _pascal ECCheckGStateHandle(GStateHandle gsh);

/***/

extern void	/*XXX*/
    _pascal ECCheckWindowHandle(WindowHandle wh);

/***/

extern void	/*XXX*/
    _pascal ECCheckQueueHandle(QueueHandle qh);

/***/

extern void	/*XXX*/
    _pascal ECCheckEventHandle(EventHandle eh);

/***/

extern void	/*XXX*/
    _pascal ECCheckLMemHandle(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ECCheckLMemHandleNS(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ECLMemValidateHeap(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ECLMemValidateHandle(optr o);

#define ECLMemValidateHandleHandles(mh, ch) \
		ECLMemValidateHandle(ConstructOptr(mh, ch))

/***/

extern void	/*XXX*/
    _pascal ECCheckLMemChunk(void *chunkPtr);

/***/

extern void	/*XXX*/
    _pascal ECMemVerifyHeap(void);

/***/

extern void	/*XXX*/
    _pascal ECLMemExists(optr o);

#define ECLMemExistsHandles(mh, ch) ECLMemExists(ConstructOptr(mh, ch))

/***/

extern void	/*XXX*/
    _pascal ECCheckChunkArray(optr o);

#define ECCheckChunkArrayHandles(mh, ch) \
		ECCheckChunkArray(ConstructOptr(mh, ch))

/***/

extern void	/*XXX*/
    _pascal ECCheckClass(ClassStruct *class);

/***/

extern void	/*XXX*/
    _pascal ECCheckObject(optr obj);

#define ECCheckObjectHandles(mh, ch) ECCheckObject(ConstructOptr(mh, ch))

/***/

extern void	/*XXX*/
    _pascal ECCheckLMemObject(optr obj);

#define ECCheckLMemObjectHandles(mh, ch) \
		ECCheckLMemObject(ConstructOptr(mh, ch))

/***/

extern void	/*XXX*/
    _pascal ECCheckOD(optr obj);

#define ECCheckODHandles(mh, ch) ECCheckOD(ConstructOptr(mh, ch))

/***/

extern void	/*XXX*/
    _pascal ECCheckLMemOD(optr o);

#define ECCheckLMemODHandles(mh, ch) ECCheckLMemOD(ConstructOptr(mh, ch))

/***/

extern void	/*XXX*/
    _pascal ECCheckStack(void);

/***/

extern void	/*XXX*/
    _pascal ECVMCheckVMFile(VMFileHandle file);

extern void	/*XXX*/
    _pascal ECVMCheckVMBlockHandle(VMFileHandle file, VMBlockHandle block);

extern void	/*XXX*/
    _pascal ECVMCheckMemHandle(MemHandle han);

/***/

extern void	/*XXX*/
    _pascal ECCheckBounds(void *address);

/***/

#if 0
typedef WordFlags ErrorCheckingFlags;
#define ECF_REGION		0x8000
#define ECF_HEAP_FREE_BLOCKS	0x4000
#define ECF_LMEM_INTERNAL	0x2000
#define ECF_LMEM_FREE_AREAS	0x1000
#define ECF_LMEM_OBJECT		0x0800
#define ECF_BLOCK_CHECKSUM	0x0400
#define ECF_GRAPHICS		0x0200
#define ECF_SEGMENT		0x0100
#define ECF_NORMAL		0x0080
#define ECF_VMEM		0x0040
#define ECF_APP			0x0020
#define ECF_LMEM_MOVE		0x0010
#define ECF_UNLOCK_MOVE		0x0008
#define ECF_VMEM_DISCARD	0x0004

#else

typedef WordFlags ErrorCheckingFlags;
#define ECF_ANAL_VMEM		0x2000
#define	ECF_FREE		0x1000
#define	ECF_HIGH		0x0800
#define	ECF_LMEM		0x0400
#define ECF_BLOCK_CHECKSUM	0x0200
#define ECF_GRAPHICS		0x0100
#define ECF_SEGMENT		0x0080
#define ECF_NORMAL		0x0040
#define ECF_VMEM		0x0020
#define ECF_APP			0x0010
#define ECF_LMEM_MOVE		0x0008
#define ECF_UNLOCK_MOVE		0x0004
#define ECF_VMEM_DISCARD	0x0002
#define	ECF_TEXT		0x0001

#endif

extern ErrorCheckingFlags
    _pascal SysGetECLevel(MemHandle *checksumBlock);

/***/

extern void
    _pascal SysSetECLevel(ErrorCheckingFlags flags, MemHandle checksumBlock);

/***/

/*
 * Macros for conditional compilation based on EC flag
 */


#if	ERROR_CHECK

#define EC(line) 		line
#define EC_ERROR(code) 		FatalError(code)
#define EC_ERROR_IF(test, code) if (test) FatalError(code)
#define NEC(line)
#define EC_BOUNDS(addr) 	ECCheckBounds(addr)
#define EC_WARNING_IF(test, code) if (test) CWarningNotice(code)
#define EC_WARNING(code)    	CWarningNotice(code)

#else

#define EC(line)
#define EC_ERROR(code)
#define EC_ERROR_IF(test, code)
#define NEC(line) 		line
#define EC_BOUNDS(addr)
#define EC_WARNING_IF(test, code)
#define EC_WARNING(code)

#endif


#ifdef __HIGHC__
pragma Alias(CFatalError, "CFATALERROR");
pragma Alias(CWarningNotice, "CWARNINGNOTICE");
pragma Alias(ECCheckFileHandle, "ECCHECKFILEHANDLE");
pragma Alias(ECCheckMemHandle, "ECCHECKMEMHANDLE");
pragma Alias(ECCheckMemHandleNS, "ECCHECKMEMHANDLENS");
pragma Alias(ECCheckThreadHandle, "ECCHECKTHREADHANDLE");
pragma Alias(ECCheckProcessHandle, "ECCHECKPROCESSHANDLE");
pragma Alias(ECCheckResourceHandle, "ECCHECKRESOURCEHANDLE");
pragma Alias(ECCheckGeodeHandle, "ECCHECKGEODEHANDLE");
pragma Alias(ECCheckDriverHandle, "ECCHECKDRIVERHANDLE");
pragma Alias(ECCheckLibraryHandle, "ECCHECKLIBRARYHANDLE");
pragma Alias(ECCheckGStateHandle, "ECCHECKGSTATEHANDLE");
pragma Alias(ECCheckWindowHandle, "ECCHECKWINDOWHANDLE");
pragma Alias(ECCheckQueueHandle, "ECCHECKQUEUEHANDLE");
pragma Alias(ECCheckEventHandle, "ECCHECKEVENTHANDLE");
pragma Alias(ECCheckLMemHandle, "ECCHECKLMEMHANDLE");
pragma Alias(ECCheckLMemHandleNS, "ECCHECKLMEMHANDLENS");
pragma Alias(ECLMemValidateHeap, "ECLMEMVALIDATEHEAP");
pragma Alias(ECLMemValidateHandle, "ECLMEMVALIDATEHANDLE");
pragma Alias(ECCheckLMemChunk, "ECCHECKLMEMCHUNK");
pragma Alias(ECMemVerifyHeap, "ECMEMVERIFYHEAP");
pragma Alias(ECLMemExists, "ECLMEMEXISTS");
pragma Alias(ECCheckChunkArray, "ECCHECKCHUNKARRAY");
pragma Alias(ECCheckClass, "ECCHECKCLASS");
pragma Alias(ECCheckObject, "ECCHECKOBJECT");
pragma Alias(ECCheckLMemObject, "ECCHECKLMEMOBJECT");
pragma Alias(ECCheckOD, "ECCHECKOD");
pragma Alias(ECCheckLMemOD, "ECCHECKLMEMOD");
pragma Alias(ECCheckStack, "ECCHECKSTACK");
pragma Alias(ECVMCheckVMFile, "ECVMCHECKVMFILE");
pragma Alias(ECVMCheckVMBlockHandle, "ECVMCHECKVMBLOCKHANDLE");
pragma Alias(ECVMCheckMemHandle, "ECVMCHECKMEMHANDLE");
pragma Alias(ECCheckBounds, "ECCHECKBOUNDS");
pragma Alias(SysGetECLevel, "SYSGETECLEVEL");
pragma Alias(SysSetECLevel, "SYSSETECLEVEL");
#endif

#endif
