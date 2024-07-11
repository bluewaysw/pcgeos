/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	L E G O S
MODULE:		Compiler
FILE:		sst.h

AUTHOR:		Roy Goldman, Jul  7, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95	Initial version.

DESCRIPTION:
       
        sst stuff used only by compiler. It would be nice
	if soon the compiler and runtime both used sst's
	where necessary and there was no need to map stables
	into sst's...

	$Id: sst.h,v 1.1 98/10/13 21:43:33 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _SST_H_
#define _SST_H_

#include <Legos/Bridge/bsst.h>

void            SSTFillFromHugeArray(optr ssTable, optr haTable);

#endif /* _SST_H_ */
