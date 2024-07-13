/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	L E G O S
MODULE:		
FILE:		bsst.h

AUTHOR:		Roy Goldman, Jul  7, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95	Initial version.

DESCRIPTION:
	
        Small string table stuff used by both compiler and runtime

	$Revision: 1.1 $

	Liberty version control
	$Id: bsst.h,v 1.1 98/03/11 04:37:51 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _BSST_H_
#define _BSST_H_

#ifndef LIBERTY
#include <geos.h>
#endif

#ifdef LIBERTY
ChunkHandle LSSTAlloc(uint16 numStrings, byte *byteStream, uint16 *pos);
TCHAR*		SSTDeref(optr table, word elt, word numFuncs);
dword		SSTGetMemoryUsedBy(optr table, word tableSize);

#else	/* GEOS version below */
ChunkHandle	SSTAlloc(MemHandle lmemBlock);
word		SSTAdd(optr table, TCHAR* string);
TCHAR*		SSTDeref(optr table, word elt);
#endif

void		SSTDestroy(optr table);

#endif /* _BSST_H_ */
