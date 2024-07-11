/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		funtab.c

AUTHOR:		Roy Goldman, Jul  7, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95   	Initial version.

DESCRIPTION:
	Function table code used by the compiler only.

	$Id: funtab.c,v 1.1 98/10/13 21:42:59 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "funtab.h"
#include "hugearr.h"
#include "bascoint.h"
#include "vtab.h"
#include "ftab.h"


/*********************************************************************
 *                      FunTabConvertFromHugeArray
 *********************************************************************
 * SYNOPSIS:    Takes a huge array function table and code store
 *              and convert it into a fast packed version.
 *              This is the main routine used by Legos to transform
 *              complete huge-array-stored code into well-packed code.
 *
 *              It's reasonable for the compiler to use HugeArrays
 *              because speed isn't as important and HugeArrays are a 
 *              powerful abstraction (supporting arbitrary deletion, 
 *              insertion, etc)
 * CALLED BY:   BascoInitRTaskFromCTask
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:    
 *              
 *              
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      5/ 9/95        Initial version
 * 
 *********************************************************************/
void FunTabConvertFromHugeArray(FunTabInfo *fti,
				TaskHan taskHan) 
{
    word numFuncs, i;
    FTabEntry *fte;

    Task *task;

    task = MemLock(taskHan);
    EC_BOUNDS(task);

    numFuncs = FTabGetCount(task->funcTable);
    for (i = 0; i < numFuncs; i++) {
	
	fte = FTabLock(task->funcTable, i);
  
	EC_BOUNDS(fte);

	FunTabAppendRoutine(fti, fte->startSeg,
			    VTGetCount(task->vtabHeap, fte->vtab), 
			    0);    /* page */
	FTabUnlock(fte);
    }


    MemUnlock(taskHan);

}


