/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	L E G O S
MODULE:		Compiler
FILE:		strmap.c

AUTHOR:		Roy Goldman, Jul  7, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95   	Initial version.

DESCRIPTION:

        StrMap code used only by compiler

	$Id: strmap.c,v 1.1 98/10/13 21:43:40 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "stable.h"
#include "strmap.h"


/*********************************************************************
 *			StrMapFillFromHugeArray
 *********************************************************************
 * SYNOPSIS:	Given a compile task filled with string constants
 *              copy them over into the heap and set up the mapping...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/15/95	Initial version
 * 
 *********************************************************************/
void StrMapFillFromHugeArray(MemHandle strMap, RunHeapInfo *rhi,
			     TaskHan taskHan) {

    Task *task;
    dword numStrings;
    word i;
    optr stable;


#if ERROR_CHECK
    ECCheckMemHandle(strMap);
    EC_ERROR_IF(StrMapGetCount(strMap) != 0, BE_FAILED_ASSERTION);
#endif

    task = MemLock(taskHan);
    EC_BOUNDS(task);
    stable = task->stringConstTable;

    MemUnlock(taskHan);

    numStrings = StringTableGetCount(stable);

    /* Major problem here, we can only hold word sized amount...*/
    if (numStrings != (word) numStrings) {
	FatalError(BE_FAILED_ASSERTION);
    }

    for (i = 0; i < numStrings; i++) 
    {
	TCHAR *str;

	str = StringTableLock(stable, i);
	StrMapAdd(strMap, rhi, str);
	StringTableUnlock(str);
    }
}
	
