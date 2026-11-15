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

	$Id: htmem.h,v 1.1 97/04/04 15:55:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


#ifndef __HT_MEM_GOH__
#define __HT_MEM_GOH__

#include <library.h>

#define HTMemHandle optr

extern void _far _pascal 
        ECCheckHTMemHandle(HTMemHandle htmh);

extern HTMemHandle _far _pascal
	HTMemAlloc(word size);

extern HTMemHandle _far _pascal
        HTMemReAlloc(HTMemHandle, word size);

extern void _far _pascal	
	HTMemFree(HTMemHandle htmh);

extern void * _far _pascal
	HTMemLock(HTMemHandle htmh);

extern void _far _pascal
	HTMemUnlock(HTMemHandle htmh);

extern void * _far _pascal
	HTMemAllocAndLock(HTMemHandle *htmh, word size);

extern void _far _pascal
	HTMemUnlockAndFree(HTMemHandle htmh);

extern Boolean _far _pascal
        HTMemoryLimit(word size);

#ifdef __HIGHC__
pragma Alias(ECCheckHTMemHandle, "ECCHECKHTMEMHANDLE");
pragma Alias(HTMemAlloc, "HTMEMALLOC");
pragma Alias(HTMemReAlloc, "HTMEMREALLOC");
pragma Alias(HTMemFree, "HTMEMFREE");
pragma Alias(HTMemLock, "HTMEMLOCK");
pragma Alias(HTMemUnlock, "HTMEMUNLOCK");
pragma Alias(HTMemAllocAndLock, "HTMEMALLOCANDLOCK");
pragma Alias(HTMemUnlockAndFree, "HTMEMUNLOCKANDFREE");
pragma Alias(HTMemoryLimit, "HTMEMORYLIMIT");
#endif


#endif



