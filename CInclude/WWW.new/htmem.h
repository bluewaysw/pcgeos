/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Geos WWW Library
MODULE:		htmem
FILE:		htmem.goh

AUTHOR:		Kok Kin Kee, Sep 16, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	9/16/96   	Initial version.

DESCRIPTION:

	HTMemory manager.

	$Id: htmem.h,v 1.6.7.6 97/11/11 19:54:35 kkee Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


#ifndef __HT_MEM_GOH__
#define __HT_MEM_GOH__

#include <library.h>

#define HTMemHandle optr

/*
 * ID for WID APIs. If you need a new ID, add it here. But please 
 * do not create too many IDs. IDs are allocated in ranges and these
 * ranges must not overlap.
 */
#define HTMID_BASE              0          /* Always the first. */
#define HTMID_HTML_START        1          /* Conv/HTML starts 1 */
#define HTMID_HTML_END          10000      /* Conv/HTML ends 100000 */
#define HTMID_HTANCHOR          10001      /* WWW/HTCore/HTAnchor */
#define HTMID_HTCOOKIE          10002      /* WWW/HTCore/HTAnchor */
#define HTMID_HTCACHE           10010      /* WWW/HTCache */
#define HTMID_END               10020      /* Always the last */


extern void _far _pascal 
        ECCheckHTMemHandle(HTMemHandle htmh);

extern HTMemHandle _far _pascal
	HTMemAlloc(word size);

extern HTMemHandle _far _pascal
	HTMemAllocWID(word id, word size);

extern HTMemHandle _far _pascal
        HTMemReAlloc(HTMemHandle, word size);

extern HTMemHandle _far _pascal
        HTMemReAllocWID(word id, HTMemHandle, word size);

extern void _far _pascal	
	HTMemFree(HTMemHandle htmh);

extern void _far _pascal	
	HTMemFreeAllWID(word id);

extern void * _far _pascal
	HTMemLock(HTMemHandle htmh);

extern void _far _pascal
	HTMemUnlock(HTMemHandle htmh);

extern void * _far _pascal
	HTMemDeref(HTMemHandle htmh);

extern void * _far _pascal
	HTMemAllocAndLock(HTMemHandle *htmh, word size);

extern void * _far _pascal
	HTMemAllocAndLockWID(word id, HTMemHandle *htmh, word size);

extern void _far _pascal
	HTMemUnlockAndFree(HTMemHandle htmh);

extern Boolean _far _pascal
        HTMemoryLimit(word size);

extern dword _far _pascal
        HTMemoryAllocated(void);

dword _far _pascal
    HTMemUsedSpaceWID (word id);

#ifdef __HIGHC__
pragma Alias(ECCheckHTMemHandle, "ECCHECKHTMEMHANDLE");
pragma Alias(HTMemAlloc, "HTMEMALLOC");
pragma Alias(HTMemAllocWID, "HTMEMALLOCWID");
pragma Alias(HTMemReAlloc, "HTMEMREALLOC");
pragma Alias(HTMemReAllocWID, "HTMEMREALLOCWID");
pragma Alias(HTMemFree, "HTMEMFREE");
pragma Alias(HTMemFreeAllWID, "HTMEMFREEALLWID");
pragma Alias(HTMemLock, "HTMEMLOCK");
pragma Alias(HTMemUnlock, "HTMEMUNLOCK");
pragma Alias(HTMemDeref, "HTMEMDEREF");
pragma Alias(HTMemAllocAndLock, "HTMEMALLOCANDLOCK");
pragma Alias(HTMemAllocAndLockWID, "HTMEMALLOCANDLOCKWID");
pragma Alias(HTMemUnlockAndFree, "HTMEMUNLOCKANDFREE");
pragma Alias(HTMemoryLimit, "HTMEMORYLIMIT");
pragma Alias(HTMemoryAllocated, "HTMEMORYALLOCATED");
pragma Alias(HTMemUsedSpaceWID, "HTMEMUSEDSPACEWID");
#endif


#endif



