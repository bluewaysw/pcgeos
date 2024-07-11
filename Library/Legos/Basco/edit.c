/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		edit.c

AUTHOR:		Roy Goldman, 1/26/95

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	1/26/95   	Initial version.

DESCRIPTION:
        Editor functionality.

	Its place here is for the short term only, and really has no
	place in the compiler.  But currently the compiler maintains
	our source code, so this batch of functions lets us
	deal with the code. (The builder's "editor" is nothing
	more than a shallow view of the data here.)

	The builder is the logical module which should be storing
	the BASIC code we work on.

	$Id: edit.c,v 1.1 98/10/13 21:42:45 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


#include <Ansi/stdio.h>
#include <Ansi/ctype.h>
#include <Legos/edit.h>
#include <char.h>
#include "scope.h"
#include "stable.h"
#include "chunkarr.h"
#include "parse.h"
#include "ftab.h"

extern FTabEntry *FunctionFind( TaskPtr task, TCHAR *buffer);
extern word setDSToDgroup(void);
extern void restoreDS(word oldDS);


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*              EDITOR                                         */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/*********************************************************************
 *			EditGetNumRoutines
 *********************************************************************
 * SYNOPSIS:	Grab the number of active routines
 * CALLED BY:	
 * RETURN:    
 * SIDE EFFECTS:
 * STRATEGY:       
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	10/ 6/94		Initial version			     
 * 
 *********************************************************************/
int EditGetNumRoutines(MemHandle taskHan) 
{
    int     	val;
    TaskPtr 	task;

    task = MemLock(taskHan);
    val = FTabGetCount(task->funcTable);
    MemUnlock(taskHan);
    return val;
}

/*********************************************************************
 *			EditGetRoutineName
 *********************************************************************
 * SYNOPSIS:	Given an index into the function table,
 *              write name of function into dest.
 *              Assume dest has been preallocated and big enough
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:     Assume index is valid
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	10/ 6/94		Initial version			     
 * 
 *********************************************************************/
void EditGetRoutineName(MemHandle taskHandle, int index, TCHAR *dest) 
{
    TCHAR *name;
    TaskPtr task;

    task = MemLock(taskHandle);
    name = StringTableLock(task->stringFuncTable, index);

    if (name != NULL) 
    {
	strcpy(dest, name);
	HugeArrayUnlock(name);
    }
    else
    {
	dest[0] = C_NULL;
    }
    MemUnlock(taskHandle);
}

/*********************************************************************
 *			EditGetRoutineIndex
 *********************************************************************
 * SYNOPSIS:	Given a string, find the index number in our
 *              code storage for that routine. 
 * CALLED BY:	GLOBAL
 * RETURN:      >= 0 if routine exists, 
 *              else -1.
 *
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/ 9/95	Initial version			     
 * 
 *********************************************************************/
int EditGetRoutineIndex(MemHandle taskHan, TCHAR *name) 
{
    int     	offset;
    TaskPtr 	task;
    
    task = MemLock(taskHan);
    offset = StringTableLookupString(task->stringFuncTable, name);
    MemUnlock(taskHan);

    return offset;
}


/*********************************************************************
 *			EditDeleteAllCode
 *********************************************************************
 * SYNOPSIS:	Wipe out all routines stored in a given task
 * CALLED BY:	
 * PASS:        
 * RETURN:      
 * SIDE EFFECTS:
 * STRATEGY:       
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	10/ 6/94		Initial version			     
 * 
 *********************************************************************/
void EditDeleteAllCode(MemHandle taskHandle) 
{
    TaskPtr 	task = MemLock(taskHandle);

    if (task->funcTable != NullHandle)
    {
	int 	count;
	word	dummy;

	MemLock(task->funcTable);
	count = ChunkArrayGetCountHandles(task->funcTable, FTAB_CHUNK);
	while (count)
	{
	    FTabEntry	*ftab;

	    count--;
	    ftab = ChunkArrayElementToPtrHandles(task->funcTable, FTAB_CHUNK, 
						 count, &dummy);
	    Scope_NukeScope(task, task->code_han,SELF_FUNC(ftab->lineElement));
	}
	MemUnlock(task->funcTable);
	FTabDestroy(taskHandle);
	task->funcTable= FTabCreate();
	Scope_InitCode(task);
    }
    if (task->stringFuncTable != NullOptr)
    {
	/* for string tables, its easiest to just create a new table */
	StringTableDestroy(task->stringFuncTable);
	task->stringFuncTable = StringTableCreate(task->vmHandle);
    }
    
    MemUnlock(taskHandle);
}

/*********************************************************************
 *			EditGetRoutineNumLines
 *********************************************************************
 * SYNOPSIS:	Get the number of lines in function at given index
 *              Fill in offset with data which will optimize code
 *              look up actual lines assosciated with this routine..
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	10/ 6/94		Initial version			     
 * 
 *********************************************************************/
int EditGetRoutineNumLines(MemHandle taskHandle, int index,
			   dword *codeOffset) 
{
    TaskPtr 	task;
    FTabEntry 	*f;
    int     	val;

    task = MemLock(taskHandle);

    /* deal gracefully with this in non-ec */
    if (FTabGetCount(task->funcTable) <= index)
    {
	EC_ERROR(-1);
	val = 0;
	*codeOffset = 0;
    }
    else
    {
	f = FTabLock(task->funcTable, index);
	val = f->numLines;
	*codeOffset = (word)f->lineElement;
	FTabUnlock(f);
    }

    MemUnlock(taskHandle);
    return val;
}

/*********************************************************************
 *			EditGetLineDebugStatus
 *********************************************************************
 * SYNOPSIS:	Given a line number and an offset code used
 *              to identify a routine (generated by EditGetRoutineNumLines),
 *              returns the break flag for that line.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	10/19/94		Initial version			     
 * 
 *********************************************************************/
Boolean EditGetLineDebugStatus(MemHandle taskHandle, dword codeOffset,
			      int index) 
{
    TaskPtr task;
	  
    DebugStatus flag;
    word    	dummy;
    byte    	*cp;

    task = MemLock(taskHandle);

    HugeArrayLock(task->vmHandle, task->code_han, codeOffset + index,
		  (void**)&cp, &dummy);
    
    if (*cp == DBG_BREAK || *cp == DBG_BREAK_AND_PC) {
	flag = TRUE;
    } else {
	flag= FALSE;
    }
    
    HugeArrayUnlock(cp);
    MemUnlock(taskHandle);

    return flag;
}

/*********************************************************************
 *			EditSetLineDebugStatus
 *********************************************************************
 * SYNOPSIS:	Given a line number and an offset code used
 *              to identify a routine (generated by EditGetRoutineNumLines),
 *              sets the break flag for that line
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	10/19/94		Initial version			     
 * 
 *********************************************************************/
void EditSetLineDebugStatus(MemHandle taskHandle, dword codeOffset,
			      int index, DebugStatus value) 
{
    TaskPtr task;
    byte    *cp;
    word dummy;

    task = MemLock(taskHandle);

    HugeArrayLock(task->vmHandle, task->code_han, codeOffset + index,
		  (void**)&cp, &dummy);

    *cp = value;
    HugeArrayDirty(cp);
    HugeArrayUnlock(cp);

    MemUnlock(taskHandle);
}

/*********************************************************************
 *			EditGetLineTextWithLock
 *********************************************************************
 * SYNOPSIS:	Given a line number and an offset code used
 *              to identify a routine (generated by EditGetRoutineNumLines)
 *              Client must unlock.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	10/ 6/94		Initial version			     
 * 
 *********************************************************************/
TCHAR *EditGetLineTextWithLock(MemHandle taskHandle, dword codeOffset, 
			      int index) 
{
    TaskPtr task;

    TCHAR *text;
    word dummy;

    task = MemLock(taskHandle);

    HugeArrayLock(task->vmHandle, task->code_han, codeOffset + index,
		  (void**)&text, &dummy);


    MemUnlock(taskHandle);
    /* return just the text, skipping the DebugStatus TCHAR */
    return text+1;
}
    




