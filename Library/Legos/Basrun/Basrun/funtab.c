/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:        L E G O S and Legos was his name-o
MODULE:         
FILE:           funtab.c

AUTHOR:         Roy Goldman, May  9, 1995

ROUTINES:
	Name                    Description
	----                    -----------

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy      5/ 9/95        Initial version.
	jimmy	 1/96	    	rewrote most of it

DESCRIPTION:
	Function table and code storage code.

	Handles packing of code into memory blocks and updates
	the function table accordingly.

	Currently handles only one-segment functions...

	This data structure is NOT meant to be dynamic. Appends
	are the only operation allowed. Functions can't be deleted,
	and new functions can't be inserted arbitrarily into the code.

	In essence, this packing is a "linking" phase which will
	be required after every code modification.

	$Revision: 1.2 $

	Liberty version control
	$Id: funtab.c,v 1.2 98/10/05 12:40:33 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/funtab.h>
#include <Legos/fixds.h>
#include <pos/ramalloc.h>   	/* For GetAllocatedSize() */
#else
#include "mystdapp.h"
#include "funtab.h"
#include <Ansi/string.h>
#include "fixds.h"
#include <hugearr.h>
#endif


#ifdef LIBERTY
/*********************************************************************
 *                      FunTabCreate
 *********************************************************************
 * SYNOPSIS:    Create a fast function table
 * CALLED BY:   GLOBAL, RunAllocTask
 * RETURN:      FunTabInfo struct
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy      5/ 9/95        Initial version
 * 
 *********************************************************************/
FunTabInfo FunTabCreate(void) 
{
    FunTabInfo fti;

    fti.FTI_funCount = 0;
    fti.FTI_ftabTable = (MemHandle)MemAlloc(sizeof(RunFastFTabEntry) * 
					    INC_ROUTINES,
					    HF_SWAPABLE | HF_SHARABLE, 0);
#ifdef ERROR_CHECK
    if(fti.FTI_ftabTable != NullHandle) {
	void *block = LockH(fti.FTI_ftabTable);
	theHeap.SetTypeAndOwner(block, "FTAB", (Geode*)0);
	UnlockH(fti.FTI_ftabTable);
    }
#endif

    return fti;
}
#else	/* GEOS version below */
/*********************************************************************
 *                      FunTabCreate
 *********************************************************************
 * SYNOPSIS:    Create a fast function table
 * CALLED BY:   GLOBAL, BascoInitRTaskFromCtask, RunAllocTask
 * RETURN:      FunTabInfo struct
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy      5/ 9/95        Initial version
 * 
 *********************************************************************/
FunTabInfo FunTabCreate(MemHandle vmFile, MemHandle code)
{
    FunTabInfo fti;
    word       dummy;

    fti.FTI_funCount = 0;
    fti.FTI_ownArray   = FALSE;
    fti.FTI_vmFile = vmFile;
    if (code == NullHandle)
    {
	fti.FTI_code = HugeArrayCreate(vmFile, 0, 0);
	/* the first element is the actual table of RunFastFTabEntrys */
	HugeArrayAppend(vmFile, fti.FTI_code, 1, &dummy);

	fti.FTI_ownArray = TRUE;
    }
    else
    {
	fti.FTI_code = code;
    }

    fti.FTI_ftabTable = (MemHandle)MemAlloc(sizeof(RunFastFTabEntry) * 
					    INC_ROUTINES,
					    HF_SWAPABLE | HF_SHARABLE, 0);
    return fti;
}
#endif


#ifndef LIBERTY
/*********************************************************************
 *                      FunTabAppendRoutine
 *********************************************************************
 * SYNOPSIS:    Adds a new routine to the function table and stores
 *              the code for it somewhere.
 * 
 *
 * CALLED BY:   GLOBAL; BIRFC
 * RETURN:      nothing
 * SIDE EFFECTS:
 * STRATEGY:    Appending a routine is linear in the number of blocks
 *              currently used. Find the first block with room
 *              for this function, otherwise add a new one...
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy      5/ 9/95        Initial version
 * 
 *********************************************************************/
void FunTabAppendRoutine(FunTabInfo *fti, word startSeg, 
			 word numLocals, byte page) 
{

    RunFastFTabEntry fte;
    SET_DS_TO_DGROUP;

    fte.RFFTE_codeHandle = startSeg;
    fte.RFFTE_numLocals  = numLocals;
    fte.RFFTE_page       = page;

    FunTabAppendTableEntry(fti, &fte);
    RESTORE_DS;
}
#endif

/*********************************************************************
 *                      FunTabAppendTableEntry
 *********************************************************************
 * SYNOPSIS:    Append a funtab entry to the function table
 * CALLED BY:   Page_ParseHeader
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy      5/12/95        Initial version
 * 
 *********************************************************************/
Boolean
FunTabAppendTableEntry(FunTabInfo *fti, RunFastFTabEntry *fte) 
{
    RunFastFTabEntry *funTabEntry;
    /* Now update the function table */
    if (fti->FTI_funCount && fti->FTI_funCount % INC_ROUTINES == 0) {
	MemHandle newHandle = (MemHandle)MemReAlloc(fti->FTI_ftabTable,
						    (fti->FTI_funCount + 
						     INC_ROUTINES) *
						    sizeof(RunFastFTabEntry),
						    0);
	if (!newHandle) {
	    return FALSE;
	}
	
	fti->FTI_ftabTable = newHandle;

#if defined(LIBERTY) && defined(ERROR_CHECK)
	void *block = LockH(fti->FTI_ftabTable);
	theHeap.SetTypeAndOwner(block, "FTAB", (Geode*)0);
	UnlockH(fti->FTI_ftabTable);
#endif

    }

    funTabEntry = &((RunFastFTabEntry*) 
		    MemLock(fti->FTI_ftabTable))[fti->FTI_funCount];
    
    *funTabEntry = *fte;

    fti->FTI_funCount++;

    MemUnlock(fti->FTI_ftabTable);
    return TRUE;
}


#ifndef LIBERTY
/*********************************************************************
 *                      FunTabAppendRoutineCode
 *********************************************************************
 * SYNOPSIS:    Add the specified code to our code store
 * CALLED BY:   Page_ParseFunc
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:      We need this because of paging..
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------
 *      jimmy	5/15/95	    	Initial version
 * 
 *********************************************************************/
void FunTabAppendRoutineCode(VMFileHandle vmFile, FunTabInfo *fti, byte *code,
			     word codeLen, word *startSeg)
{
    *startSeg = HugeArrayAppend(vmFile, fti->FTI_code, codeLen, code);
}
#endif

/*********************************************************************
 *                      FunTabDestroy
 *********************************************************************
 * SYNOPSIS:    Destroy all code owned by a function table and
 *              destroy the function table too.
 * CALLED BY:   GLOBAL; RunDestroyTask, RunNullRTask
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy      5/ 9/95        Initial version
 * 
 *********************************************************************/
void FunTabDestroy(FunTabInfo *fti) 
{
#ifdef LIBERTY
    int i;
    if (fti->FTI_ftabTable != NullHandle) {
	RunFastFTabEntry* table = 
	    (RunFastFTabEntry*)MemLock(fti->FTI_ftabTable);
	for(i = 0; i < fti->FTI_funCount; i++) {
	    if(table[i].RFFTE_codeHandle != NullHandle) {
		MemFree(table[i].RFFTE_codeHandle);
	    }
	}
	MemUnlock(fti->FTI_ftabTable);
    }
#endif
    MemFree(fti->FTI_ftabTable);
    fti->FTI_ftabTable = NullHandle;
#ifndef LIBERTY
    if (fti->FTI_ownArray)
    {
	HugeArrayDestroy(fti->FTI_vmFile, fti->FTI_code);
    }
    fti->FTI_code = NullHandle;
#endif
}


/*********************************************************************
 *                      FunTabGetNumLocals
 *********************************************************************
 * SYNOPSIS:    Return the number of local variables for a given 
 *              routine.
 * CALLED BY:   debugger?
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy      5/ 9/95        Initial version
 * 
 *********************************************************************/
word FunTabGetNumLocals(FunTabInfo *fti, word funcNum) 
{
    RunFastFTabEntry *rfte;
    word retVal;

    FUNTAB_LOCK_TABLE_ENTRY(*fti, rfte, funcNum);
    retVal = rfte->RFFTE_numLocals;
    FUNTAB_UNLOCK_TABLE_ENTRY(*fti, rfte);

    return retVal;
}


#ifdef LIBERTY
/*********************************************************************
 *                      FunTabGetMemoryUsedBy
 *********************************************************************
 * SYNOPSIS:    Return the amount of memory used by the function table
 *		and all its entries.
 * CALLED BY:   FunctionGetMemoryUsedBy()
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      mchen   7/25/96         Initial version
 * 
 *********************************************************************/
dword 
FunTabGetMemoryUsedBy(FunTabInfo *fti)
{
    if(theHeapDataMap.ValueIsHandle(fti->FTI_ftabTable)) {
	RunFastFTabEntry *funTabBlock = (RunFastFTabEntry*)LockH(fti->FTI_ftabTable);
	dword totalSize = theHeap.GetAllocatedSize(funTabBlock);

	for(int i = 0; i < fti->FTI_funCount; i++) {
	    void *codeBlock = (void*)LockH(funTabBlock[i].RFFTE_codeHandle);
	    totalSize += theHeap.GetAllocatedSize(codeBlock);
	    UnlockH(funTabBlock[i].RFFTE_codeHandle);
	}
	UnlockH(fti->FTI_ftabTable);
	return totalSize;
    }
    return 0;
}	/* End of FunTabGetMemoryUsedBy() */
#endif
