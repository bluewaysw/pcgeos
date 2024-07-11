/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	L E G O S
MODULE:		Compiler
FILE:		funtab.h

AUTHOR:		Roy Goldman, Jul  7, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95	Initial version.

DESCRIPTION:
	
        Function table routines used only by the compiler.

	$Id: funtab.h,v 1.1 98/10/13 21:43:01 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _FUNTAB_H_
#define _FUNTAB_H_

#include <Legos/Bridge/bfuntab.h>
#include <bascoint.h>

/* Convert compiled code stored in a compile task into
   the funtabinfo structure */

void FunTabConvertFromHugeArray(FunTabInfo *fti,
				TaskHan task);


#endif /* _FUNTAB_H_ */
