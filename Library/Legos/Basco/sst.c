/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	L E G O S
MODULE:		Compiler
FILE:		sst.c

AUTHOR:		Roy Goldman, Jul  7, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95   	Initial version.

DESCRIPTION:
	
        sst code used only by compiler

	$Id: sst.c,v 1.1 98/10/13 21:43:31 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "sst.h"
#include "stable.h"


/*********************************************************************
 *			SSTFillFromHugeArray
 *********************************************************************
 * SYNOPSIS:	Fill in an SST with the strings from an old-style string
 *              table.
 *
 *              I guess this could go away and not use the old-style tables...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/28/95	Initial version
 * 
 *********************************************************************/
void SSTFillFromHugeArray(optr sst, optr haTable) {
    word numStrings, i;
    TCHAR *str;

    numStrings = StringTableGetCount(haTable);
    for (i = 0; i < numStrings; i++) {
	str = StringTableLock(haTable, i);
	SSTAdd(sst, str);
	StringTableUnlock(str);
    }
}
