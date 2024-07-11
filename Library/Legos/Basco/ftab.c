/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		ftab.c

AUTHOR:		Paul L. Du Bois, May 13, 1996

ROUTINES:
	Name			Description
	----			-----------
    INT FTabIncrementNumLines	Adds an entry to the FUNCTION-SUB lookup
				table.

    EXT FTabAddEntry		Adds an entry to the FUNCTION-SUB lookup
				table.

    EXT FTabCreate		create a functable

    EXT FTabDestroy		Free up the function table

    INT FTabClean		Free up the function table

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/13/96  	Initial version.

DESCRIPTION:
	Routines that have to do with the compiler's function table.
	No relation to funtab, which some might say shouldn't exist.

	$Id: ftab.c,v 1.1 98/10/13 21:42:55 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include "mystdapp.h"
#include <thread.h>
#include <tree.h>

#include "bascoint.h"
#include "ftab.h"
#include "vtab.h"
#include "scope.h"
#include "stable.h"

FTabEntry*
FTabLock(MemHandle table, int funcNumber)
{
    FTabEntry*	ftab;
    word	dummy;

    MemLock(table);
    ftab = ChunkArrayElementToPtrHandles(table, FTAB_TableToChunk(table), 
					 funcNumber,&dummy);
    EC_BOUNDS(ftab);
    return ftab;
}

FTabEntry*
FTabDeref(MemHandle table, int funcNumber)
{
    FTabEntry*	ftab;

    ftab = ChunkArrayElementToPtrHandles(table, FTAB_TableToChunk(table), 
					 funcNumber,NULL);
    EC_BOUNDS(ftab);
    return ftab;
}

word FTabGetCount(MemHandle table)
{
    word    count;
    MemLock(table);
    count = ChunkArrayGetCountHandles(table, FTAB_TableToChunk(table));
    MemUnlock(table);
    return count;
}

/*********************************************************************
 *			FTabIncrementNumLines
 *********************************************************************
 * SYNOPSIS: 	Adds an entry to the FUNCTION-SUB lookup table.
 * CALLED BY:	INTERNAL, LineAdd
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/18/95	Initial version			     
 * 
 *********************************************************************/
void
FTabIncrementNumLines(TaskPtr	    task, int funcNumber)
{
    FTabEntry	*ftab;

    ftab = FTabLock(task->funcTable, funcNumber);
    ftab->numLines++;
    MemUnlock(task->funcTable);
}

/*********************************************************************
 *			FTabAddEntry
 *********************************************************************
 * SYNOPSIS: 	Adds an entry to the FUNCTION-SUB lookup table.
 * CALLED BY:	EXTERNAL, LineAdd
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/18/95	Initial version			     
 * 
 *********************************************************************/
int
FTabAddEntry(TaskPtr task, TCHAR* name, BascoFuncType type, word self)
{
   FTabEntry*	ftab;
   int	    	    funcNumber;

   /* get the element for name */
   MemLock(task->funcTable);

   ftab = ChunkArrayAppendHandles(task->funcTable, FTAB_CHUNK, 0);

   ftab->tree = NullHandle;
   ftab->funcType = type;
   ftab->vtab = NULL_VTAB;
   ftab->global = 0;
   ftab->compStatus = CS_NAKED;
   ftab->deleted = FALSE;
   ftab->numLines = 0;
   ftab->index = funcNumber = FTabGetCount(task->funcTable) - 1;
   ftab->lineElement = SELF_CONSTRUCT(funcNumber, self);
   ftab->labelNameTable = NullOptr;

   MemUnlock(task->funcTable);
   StringTableAdd(task->stringFuncTable, name);

   return funcNumber;
}

/*********************************************************************
 *			FTabCreate
 *********************************************************************
 * SYNOPSIS:	create a functable
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/16/96  	Initial version
 * 
 *********************************************************************/
MemHandle
FTabCreate()
{
    MemHandle	funcTable;
    ChunkHandle	ch;

    funcTable = MemAllocLMem(LMEM_TYPE_GENERAL, 0);
    MemModifyOtherInfo(funcTable, ThreadGetInfo(0,TGIT_THREAD_HANDLE )); 
    MemModifyFlags(funcTable, HF_SHARABLE, 0);
    MemLock(funcTable);
    ch = ChunkArrayCreate(funcTable, sizeof(FTabEntry), 0, 0);
#ifdef DOS
    return ch;
#else
    if (ch != FTAB_CHUNK)
    {
	EC_ERROR(-1);
	return NullHandle;
    }
    MemUnlock(funcTable);
    return funcTable;
#endif
}

/*********************************************************************
 *			FTabDestroy
 *********************************************************************
 * SYNOPSIS:	Free up the function table
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/22/94	Initial version			     
 * 
 *********************************************************************/
void
FTabDestroy(MemHandle taskHan)
{
    TaskPtr task;
    
    task = MemLock(taskHan);
    FTabClean(taskHan);
    MemFree(task->funcTable);
    task->funcTable = NullHandle;

    MemUnlock(taskHan);
}

/*********************************************************************
 *			FTabClean
 *********************************************************************
 * SYNOPSIS:	Clean up function table internal state
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/22/94	Initial version			     
 * 
 *********************************************************************/
void
FTabClean(MemHandle taskHan)
{

    dword count;
    dword i;
    FTabEntry*	ftab;
    TaskPtr task;

    task = MemLock(taskHan);

    if (task->funcTable == NullHandle) {
	return;
    }
    count = FTabGetCount(task->funcTable);

    for (i = 0; i < count; i++) 
    {
	ftab = FTabLock(task->funcTable, i);

	if (ftab->tree) 
	{
	    ECCheckHugeArray(task->vmHandle, ftab->tree);
	    HugeTreeDestroy(task->vmHandle, ftab->tree);
	    ftab->tree = NullHandle;
	}
	if (ftab->vtab != NULL_VTAB)
	{
	    VTDestroy(task->vtabHeap, ftab->vtab);
	    ftab->vtab = NULL_VTAB;
	}
	if (ftab->labelNameTable != NullOptr)
	{
	    LMemFree(ftab->labelNameTable);
	    ftab->labelNameTable = NullOptr;
	}
	ftab->compStatus = CS_NAKED;
	FTabUnlock(ftab);
    }
    MemUnlock(taskHan);
}

/*********************************************************************
 *			FTabAddLabel
 *********************************************************************
 * SYNOPSIS:	Add a label to current function
 * CALLED BY:	
 * RETURN:	error set if unsuccessful
 * SIDE EFFECTS:
 * STRATEGY:
 *	Can fail if labelNameKey was already associated with a Node
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	5/14/96  	Initial version
 * 
 *********************************************************************/
void
FTabAddLabel(TaskPtr task, word labelNameKey, Node labelNode)
{
    FTabEntry*	ftab;
    NamedLabel*	entry;
    word	i, count;
    Boolean	found = FALSE;

    ftab = FTabLock(task->funcTable, task->funcNumber);
    if (ftab->labelNameTable == NullOptr)
    {
	optr	newArray;
	newArray =		/* shuffle */
	    ConstructOptr
		(task->funcTable,
		 ChunkArrayCreate(task->funcTable, sizeof(NamedLabel), 0, 0));
	ftab = FTabDeref(task->funcTable, task->funcNumber);
	ftab->labelNameTable = newArray;
    }

    count = ChunkArrayGetCount(ftab->labelNameTable);
    entry = ChunkArrayElementToPtr(ftab->labelNameTable, 0, NULL);
    for (i=0; i<count; i++, entry++)
    {
	if (entry->identKey == labelNameKey) {
	    found = TRUE;
	    break;
	}
    }
    
    if (found) {
	if (entry->node == NullNode) {
	    entry->node = labelNode;
	} else {
	    SetError(task, E_DUPLICATE_LABEL);
	}
    } else {
	entry = ChunkArrayAppend(ftab->labelNameTable, 0); /* shuffle */
	ftab = FTabDeref(task->funcTable, task->funcNumber);
	entry->identKey = labelNameKey;
	entry->node = labelNode;
	entry->label = NULL_LABEL;
    }
    FTabUnlock(ftab);
}

/*********************************************************************
 *			FTabGetLabelEntry
 *********************************************************************
 * SYNOPSIS:	Find label node for current func given a string
 * CALLED BY:	EXTERNAL
 * RETURN:	Corresponding NamedLabel, or null
 * SIDE EFFECTS:
 * STRATEGY:
 *	NamedLabel is within ftab block; it must be locked
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	5/14/96  	Initial version
 * 
 *********************************************************************/
NamedLabel*
FTabGetLabelEntry(TaskPtr task, word labelNameKey)
{
    FTabEntry*	ftab;
    word	i, count;
    NamedLabel	*entry, *retval = NULL;

    ftab = FTabDeref(task->funcTable, task->funcNumber);
    if (ftab->labelNameTable != NullOptr) {
	count = ChunkArrayGetCount(ftab->labelNameTable);
	entry = ChunkArrayElementToPtr(ftab->labelNameTable, 0, NULL);
	for (i=0; i<count; i++, entry++) {
	    if (entry->identKey == labelNameKey) {
		retval = entry;
		break;
	    }
	}
    }
    return retval;
}

/*********************************************************************
 *			FTabResetLabelEntries
 *********************************************************************
 * SYNOPSIS:	Reset code labels in LabelEntries before codegen begins
 * CALLED BY:	EXTERNAL, CodeGen phase
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	5/14/96  	Initial version
 * 
 *********************************************************************/
void
FTabResetLabelEntries(TaskPtr task)
{
    FTabEntry*	ftab;
    word	i, count;
    NamedLabel*	entry;

    ftab = FTabLock(task->funcTable, task->funcNumber);
    if (ftab->labelNameTable != NullOptr) {
	count = ChunkArrayGetCount(ftab->labelNameTable);
	entry = ChunkArrayElementToPtr(ftab->labelNameTable, 0, NULL);
	for (i=0; i<count; i++, entry++) {
	    entry->label = NULL_LABEL;
	}
    }
    FTabUnlock(ftab);
}
