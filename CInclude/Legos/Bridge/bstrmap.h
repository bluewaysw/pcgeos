/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		bstrmap.h

AUTHOR:		Roy Goldman, Jul  7, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95	Initial version.

DESCRIPTION:
	
        StrMap info used by both compiler and interpreter.

	$Revision: 1.1 $

	Liberty version control
	$Id: bstrmap.h,v 1.1 98/03/11 04:37:57 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _BSTRMAP_H_
#define _BSTRMAP_H_

#ifndef LIBERTY
#include <geos.h>
#include <legos/runheap.h>
#endif

#ifdef LIBERTY

MemHandle StrMapCreate(word size);
Boolean LStrMapAdd(MemHandle strMap, TCHAR *str);
void StrMapDestroy(MemHandle strMap);

#define StrMapAdd(strMap, rhi, str) LStrMapAdd(strMap, str)

EC(word StrMapGetCount(MemHandle strMap);)
dword StrMapGetMemoryUsedBy(MemHandle strMap);

#else	/* GEOS version below */

MemHandle StrMapCreate(void);
Boolean StrMapAdd(MemHandle strMap, RunHeapInfo *rhi, TCHAR *str);
void StrMapDestroy(MemHandle strMap);
word StrMapGetCount(MemHandle strMap);

#endif

#endif /* _BSTRMAP_H_ */
