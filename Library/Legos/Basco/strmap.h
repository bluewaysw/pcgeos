/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	L E G O S 
MODULE:		Compiler
FILE:		strmap.h

AUTHOR:		Roy Goldman, Jul  7, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95	Initial version.

DESCRIPTION:

        StrMap routines needed by the compiler.

	$Id: strmap.h,v 1.1 98/10/13 21:43:42 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _STRMAP_H_
#define _STRMAP_H_

#include <hugearr.h>
#include <bascoint.h>
#include <Legos/Bridge/bstrmap.h>
#include <Legos/runheap.h>

/* Fill in a heap with strings that are currently in a huge array 
   structure... */

void StrMapFillFromHugeArray(MemHandle strMap, 
			     RunHeapInfo *rhi, 
			     TaskHan task);

#endif /* _STRMAP_H_ */
