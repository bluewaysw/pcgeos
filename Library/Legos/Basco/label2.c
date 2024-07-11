/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basco
FILE:		label2.c

AUTHOR:		Paul L. DuBois, Dec 16, 1994

ROUTINES:
	Name			Description
	----			-----------
EXT	LabelDoFixups
INT	Label_FixupJumpCB
INT	Label_FixupSizes
INT	Label_CommitJumpChanges

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	12/16/94   	Initial version.

DESCRIPTION:
	Contains all the fixup-related code for the label module

	$Id: label2.c,v 1.1 98/10/13 21:43:06 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include "mystdapp.h"
#include <lmem.h>
#include <chunkarr.h>
#include <hugearr.h>

#include "bascoint.h"
#include "label.h"
#include "labelint.h"
#include "codeint.h"
#include "vtab.h"
#include "vars.h"
#include "stable.h"
#include "parseint.h"
#include <Legos/bug.h>



/*********************************************************************
 *			StableTableRestConstantsForFunction
 *********************************************************************
 * SYNOPSIS:	reset tasks for the deleted routine
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/26/96  	Initial version
 * 
 *********************************************************************/
void
StringTableResetConstantsForFunction(TaskPtr task, int funcNumber)
{
    int	    	    count, i;
    ConstantInfo    ci;

    count = StringTableGetCount(SYMBOLIC_CONST_TABLE);
    for (i = 0; i < count; i++)
    {
	StringTableGetDataPtr(SYMBOLIC_CONST_TABLE, i, sizeof(ci), &ci);
	if (ci.funcNumber == funcNumber)
	{
	    ci.funcNumber = -1;
	    StringTableSetDataPtr(SYMBOLIC_CONST_TABLE, i, sizeof(ci), &ci);
	} 
	else if (ci.funcNumber > funcNumber)
	{
	    ci.funcNumber--;
	    StringTableSetDataPtr(SYMBOLIC_CONST_TABLE, i, sizeof(ci), &ci);
	}
    }
}



/*********************************************************************
 *			LabelCompactFunctions
 *********************************************************************
 * SYNOPSIS:	update index fields
 * CALLED BY:	LabelDoGlobalRefFixups
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/29/95	Initial version
 * 
 *********************************************************************/
#define LabelCompactFunctions(task) LabelCompactUncompactFunctions(task,FALSE)
#define LabelUncompactFunctions(task) LabelCompactUncompactFunctions(task,TRUE)
void
LabelCompactUncompactFunctions(TaskPtr task, Boolean uncompact)
{
    int	    	c, i, delta=0;
    FTabEntry	*ftab;

    c = FTabGetCount(task->funcTable);
    for (i = 0; i < c; i++)
    {
	ftab = FTabLock(task->funcTable, i);

	if (uncompact) {
	    ftab->index = i;
	    ftab->deleted = FALSE;
	    FTabDirty(ftab);
	} else if (ftab->deleted) {
	    delta++;
	} else {
	    ftab->index = i - delta;
	    FTabDirty(ftab);
	}
	FTabUnlock(ftab);
    }
}



/*********************************************************************
 *			LabelDoGlobalRefFixups
 *********************************************************************
 * SYNOPSIS:	fixup global references that might have moved
 * CALLED BY:	BascoCompileCodeFromTask, BascoCompileFunction
 * RETURN:  	TRUE if everything hunky dory, FALSE otherwise
 * SIDE EFFECTS: code fixed up
 * STRATEGY:
 *	    	we have an array of global references giving us all
 *	    	the information we need to be able to fixup pointers
 *	    	to things that might have moved
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 9/95	Initial version
 * 
 *********************************************************************/
#define PASS1 0
#define PASS2 1

Boolean LabelDoGlobalRefFixups(TaskPtr	task, GlobalRefType type, word data)
{
    int	    	    c, i, j;
    GlobalRefData   *grd;
    FTabEntry	    *ftab;
    word    	    curFunc = -1;
    word    	    curSeg = -1;
    word    	    startSeg;
    byte    	    *code = NULL;
    word    	    dummy;
    VTabEntry	    vte;
    optr	globalsIndex = NullOptr;
    Boolean	retval;

    /* if its a proc_call fixup, we just deleted routine <data>, so
     * delete all the fixups for that routine
     */
    if (type & GRT_ROUTINE_CALL)
    {
	LabelCompactFunctions(task);
    }
    if (type & GRT_MODULE_VAR)
    {
	/* update offsets to correct for globals that are going away
	 * but only if we are doing module vars
	 */
	globalsIndex = VTCreateIndex(task->vtabHeap, GLOBAL_VTAB);
	VTCompactGlobals(task->vtabHeap, globalsIndex);
    }

    if (!type) 
    {
	retval = TRUE;
	goto done;
    }

    EC_ERROR_IF(task->globalRefs == NullHandle, BE_FAILED_ASSERTION);

    c = HugeArrayGetCount(task->vmHandle, task->globalRefs);
    /* two passes, once to check for errors, once to make changes
     */
    for (j = 0; j < 2; j++)
    {
    for (i = 0; i < c; i++)
    {
	HugeArrayLock(task->vmHandle, task->globalRefs, i, (void**)&grd,
		      &dummy);
	/* make sure we are doing this type of fixup on pass2
	 * check for any errors in pass1
	 */
	if (grd->GRD_type & type || j == PASS1)
	{
	    /* we are banking on the fact these will pretty much be
	     * grouped by function (in terms of speed)
	     */
	    if (j == PASS2)
	    {
		if (!(type & GRT_ROUTINE_CALL && grd->GRD_funcNumber == data)
		    && ((curFunc != grd->GRD_funcNumber) ||
		       (curSeg != (grd->GRD_offset >> 12))))
		{
		    if (code != NULL) 
		    {
			CodeSegDirty(code);
			CodeSegUnlock(code);
		    }

		    if (curFunc != grd->GRD_funcNumber)
		    {
			curFunc = grd->GRD_funcNumber;
			ftab = FTabLock(task->funcTable, curFunc);
			startSeg = ftab->startSeg;
			FTabUnlock(ftab);
		    }
		    curSeg = grd->GRD_offset >> 12;
		    code = CodeSegLock(task->vmHandle, task->codeBlock,
				       startSeg + curSeg, &dummy);
		}
	    }
	    switch (grd->GRD_type) 
	    {
	    case GRT_MODULE_VAR:
	    case GRT_MODULE_VAR_INDEX:
		/* if its a variable fixup in a routine that is being
		 * deleted anyways, don't bother
		 */
		if (!((type & GRT_ROUTINE_CALL) &&
		    grd->GRD_funcNumber == data))
		{
		    VarGetVTabEntry(task, grd->GRD_funcNumber, 
				    MAKE_VAR_KEY(VAR_MODULE, grd->GRD_index),
				    &vte);

		    if (vte.VTE_funcNumber == (word)-1) 
		    {
			SetError(task, E_UNDECLARED);
			goto    error_done;
		    }
		    if (j == PASS2)
		    {
			/* update our index, incase its going to move */
			grd->GRD_index = vte.VTE_index;
			HugeArrayDirty(grd);
			if (grd->GRD_type == GRT_MODULE_VAR) {
			    CAST_ARR(word, code[grd->GRD_offset&0x0fff]) = 
				vte.VTE_offset/VAR_SIZE;
			} else if (grd->GRD_type == GRT_MODULE_VAR_INDEX) {
			    CAST_ARR(byte, code[grd->GRD_offset&0x0fff]) = 
				vte.VTE_offset/VAR_SIZE;
			}
		    }
		}
		break;
	    case GRT_PROC_CALL: 
	    case GRT_FUNC_CALL:
	    {
		FTabEntry   *ftab;
		word	    delete, index;
		BascoFuncType	ft;

		/* the only time this happens is when a routine is deleted
		 * so, just look for references to the delete routine and
		 * any routines of index higher than the delete routine, 
		 * get decremented
		 */
		ftab = FTabLock(task->funcTable, grd->GRD_index);
		delete = ftab->deleted;
		index = ftab->index;
		ft = ftab->funcType;
		FTabUnlock(ftab);
		/* ignore entries for the function being deleted */
		if (grd->GRD_funcNumber != data)
		{
		    if (delete)
		    {
			/* there is a reference to the delete routine, so
			 * report the error
			 */
			SetError(task, E_UNABLE_TO_DELETE_FUNCTION);
			goto error_done;
		    } 
		    if (ft==FT_FUNCTION && grd->GRD_type==GRT_PROC_CALL)
		    {
			SetError(task, E_EXPECT_FUNC);
			goto	error_done;
		    }
		    if (ft==FT_SUBROUTINE && grd->GRD_type==GRT_FUNC_CALL)
		    {
			SetError(task, E_SUB_NOT_RVAL);
			goto	error_done;
		    }
		    if (j == PASS2)
		    {
			grd->GRD_index = index;
			HugeArrayDirty(grd);
			CAST_ARR(word, code[grd->GRD_offset&0x0fff]) = index;
		    }
		}
	    }
		break;
#if 0
	    case GRT_CONSTANT:
		if (j == PASS2)
		{
		    Token   t;

		    StringTableGetDataPtr(task->symbolicConstantTable, 
					  grd->GRD_index, sizeof(t), &t);
		    if (t.code == CONST_INT || t.code == CONST_STRING) {
			CAST_ARR(word,code[grd->GRD_offset&0x0fff]) =
			    	    	    	    	    t.data.integer;
		    } else {
			CAST_ARR(dword, code[grd->GRD_offset&0x0fff]) = 
			    	    	    	    	    t.data.key;
		    }
		}
		break;
#endif
	    }
	}
	HugeArrayUnlock(grd);
    }
    }
    if (code != NULL) 
    {
	CodeSegDirty(code);
	CodeSegUnlock(code);
    }

    if (type & GRT_MODULE_VAR) {
	/* at this point we can nuke unused globals */
	VTDeleteUnusedGlobals(task->vtabHeap);
    } 
    if (type & GRT_ROUTINE_CALL) 
    {
	FTabEntry   *ftab;
	/* we can now actually delete the entries in the func and stringFunc
	 * tables since we had a successful link
	 */
	ftab = FTabLock(task->funcTable, data);
	ChunkArrayDelete(ConstructOptr(task->funcTable, FTAB_CHUNK), ftab);
	FTabUnlock(ftab);
	task->stringFuncTable = StableCopyTableDeleteElement(
						       task->stringFuncTable,
						       data);
	/* get rid of entries for deleted routine and update entries for
	 * routines whose funcNumber decremented by one after deletion
	 */
	LabelDeleteGlobalRefsForFunction(task, data, TRUE);

	/* mark all the globals from the deleted function as being gone
	 * so when we do a module_var link, we detect bad refs and compact
	 * the remaining globals
	 */
	VTResetGlobalsForFunction(task->vtabHeap, data, TRUE);

	/* need to do the same for symbolic constants */
	StringTableResetConstantsForFunction(task, data);
    }
    retval = TRUE;

 done:
    if (globalsIndex) {
	MemLock(OptrToHandle(globalsIndex));
	LMemFree(globalsIndex);
	MemUnlock(OptrToHandle(globalsIndex));
    }
    return retval;

error_done:
    /* fetch relevant info on error */
    task->funcNumber = grd->GRD_funcNumber;
    task->ln = BugOffsetToLineNum(task->bugHandle, task->funcNumber,
				  grd->GRD_offset, (byte *)&dummy);
    HugeArrayUnlock(grd);
    /* restore globals to prelink state so when we try linking again
     * thinks will work
     */
    if (type & GRT_ROUTINE_CALL) {
	LabelUncompactFunctions(task);
    } 
    if (type & GRT_MODULE_VAR) {
	VTUncompactGlobals(task->vtabHeap, globalsIndex);
    }
    retval = FALSE;
    goto done;
}


/*********************************************************************
 *			LabelDoLocalFixups
 *********************************************************************
 * SYNOPSIS:	Perform local fixups (jumps, code labels)
 * CALLED BY:	Nobody
 * RETURN:	nothing
 * SIDE EFFECTS:jump fixups change code size
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/16/94	Initial version			     
 * 
 *********************************************************************/
Boolean
LabelDoLocalFixups(TaskPtr task)
{
    LabelHeader*	lh;
    CAEProcPtr		funcPtr;

    /* I have heard that this should be done to avoid possible optimizations
       (ie, push cs) when passing function pointers that don't work in XIP
       because there is no segment for glue to relocate */
    funcPtr = &Label_FixupJumpCB;
    lh = MemLock(task->labels);

#if ERROR_CHECK
    EC_FinalCheckLabelHeap(task->labels);
#endif

    /* Keep around the original offsets; they'll be needed when we
     * commit the jump changes
     */
    ;{
	ChunkArrayHeader* cah;
	FixupData*	fixup;
	word		i;

	cah = LMemDerefHandles(task->labels, lh->LH_jumpArray);
	fixup = (FixupData*) FIXED_CA_FIRST_ELEMENT(cah);
	for (i=0;
	     i<cah->CAH_count;
	     i++,fixup++)
	{
	    fixup->FD_origOffset = fixup->FD_offset;
	}
    }

    /* Callback routine will set lh->LH_codeSizeChanged */
    do {
	lh->LH_codeSizeChanged = FALSE;
	ChunkArrayEnumHandles(task->labels, lh->LH_jumpArray,
			      (void*) task,
			      funcPtr);
    } while (lh->LH_codeSizeChanged != FALSE);

    MemUnlock(task->labels);
    if (Label_CommitJumpChanges(task) == FALSE) {
	return FALSE;
    }

    /* Code segments are now their final size.  Go through
     * and fix up cross-segment jumps to be normal long jumps
     * if we are compiling for a flat model
     */
    if (task->flags & COMPILE_NO_SEGMENTS) {
	Label_FlattenJumps(task);
    }

    ;{
	ChunkArrayHeader* cah;
	int size;

	/* Finally, for debuggable apps, spit out all the line
	   number label information into the task's line label
	   Huge Array.

	   Eventually we will probably need to pass some flag
	   to this routine telling whether or not we want it,
	   OR just push this into some other routine... */

	MemLock(task->labels);
	lh = MemDeref(task->labels);

	cah = LMemDerefHandles(task->labels, lh->LH_lineArray);
	size = cah->CAH_count;

	/* I'm hoping this is the correct way to copy
	   chunk array good stuff into a huge array. */

	HugeArrayAppend(task->vmHandle, task->hugeLineArray,
			size, (LineData*) (FIXED_CA_FIRST_ELEMENT(cah)));

	MemUnlock(task->labels);


    }
    return TRUE;
}

/*********************************************************************
 *			Label_FixupJumpCB
 *********************************************************************
 * SYNOPSIS:	Modify this jump, if necessary.
 * CALLED BY:	INTERNAL, LabelDoFixups (through ChunkArrayEnum)
 * RETURN:	FALSE	(since we want to enum through all elements)
 * SIDE EFFECTS:might modify flags for this element.
 * STRATEGY:
 *	Assume that label block is locked.
 *	
 *	Jumps start out long and intra-segment by default.
 *	
 *	All inter-segment jumps are handled the first time through
 *	the loop, and marked so we'll ignore them on later passes.
 *	
 *	Jumps that are definitely long ( < -256, > 254 )
 *	are handled and marked.
 *	
 *	Jumps that are definitely short are handled and marked;
 *	In addition, we fix up labels to account for the loss of a
 *	byte.  This fixup sets a variable in the labelheader
 *	(LH_codeSizeChanged) so we know to loop again and see if maybe
 *	some other jumps can be compressed.
 *	
 *	All other jumps are left alone (they will be the long,
 *	intra-segment jumps).
 *	
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/16/94	Initial version			     
 * 
 *********************************************************************/
Boolean _pascal
Label_FixupJumpCB(void* element, void* enumData)
{
    TaskPtr	task;
    FixupData*	fixup;
    TargetData*	td;
    LabelHeader* lh;
    sword	dist;

    fixup = (FixupData*) element;

    /* Not a jump, or needs no more processing -- bail out quick */
    if (fixup->FD_type != FT_JUMP ||
	fixup->FD_extraData & JF_STABLE) {
	return FALSE;
    }

    /* Dereference things and find out the current jump distance */
    task = (TaskPtr) enumData;
    lh = (LabelHeader*) MemDeref(task->labels);

    td = ChunkArrayElementToPtrHandles
	(lh->LH_meta.LMBH_handle, lh->LH_targetArray,
	 fixup->FD_index, (void*)0);

    /* if the offset is unset, then we created the target but never created
     * a jump to it, so just forget the whole thing
     */
    if (td->TD_offset == UNSET_OFFSET) {    
/* Wait... why is this not an error?  Is this ever hit legitimately?
 * Let's try this and see what happens */
	EC_ERROR(-1);
	return FALSE;
    }

    dist = td->TD_offset - fixup->FD_offset;

    /* Decide what to do based on that distance... */


    /* Check for cross-segment jump (which is always absolute) */
    if ((td->TD_offset & 0xf000) != (fixup->FD_offset & 0xf000))
    {
	fixup->FD_extraData |= (JF_STABLE | JF_CROSS_SEGMENT);
    }

    /* Check for definitely short -- shuffle labels & fixups down a byte */
    else if (dist >= -128 && dist <= 127)
    {
	fixup->FD_extraData |= (JF_STABLE | JF_RELATIVE);
	Label_FixupSizes(task, fixup->FD_offset+1, -1);
    }

    /* Check for definitely long */
    else if (dist < -256 || dist > 254)
    {
	fixup->FD_extraData |= JF_STABLE;
    }
#if ERROR_CHECK
    else
    {
	LABEL_ASSERT(fixup->FD_extraData == 0);
    }
#endif	

    return FALSE;
}

/*********************************************************************
 *			Label_FixupSizes
 *********************************************************************
 * SYNOPSIS:	Shuffle all labels in heap up or down.
 * CALLED BY:	INTERNAL, Label_FixupJumpCB
 * RETURN:	nothing
 * SIDE EFFECTS:
 *	messes with label offsets
 *	if any label offsets are changed, LH_codeSizeChanged is set
 *
 * STRATEGY:
 *	Assumes label block is locked
 *
 *	This is the real workhorse routine, and the one that should
 *	be fast.  For now, simple version just loops through the
 *	various chunkarrays, incrementing or decrementing the _offset
 *	fields of the elements.
 *
 *	We don't mess with offsets in segments other than our own.
 *	
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/16/94	Initial version			     
 * 
 *********************************************************************/
void
Label_FixupSizes(TaskPtr task, word offset, sbyte delta)
{
    LabelHeader*	lh;
    ChunkArrayHeader*	cah;

    word	size, i, curSeg;
    LineData*	ld;		/* used as arrays, to avoid having to */
    TargetData*	td;		/* use ChunkArrayEnum all the time */
    FixupData*	fixup;

    /* if code can expand as well as contract, fixup algorithm
       doesn't work... plus, I haven't defined whether bytes are
       inserted before or after labels, or checked if a label was
       deleted */
    LABEL_ASSERT( delta == -1);
    lh = MemDeref(task->labels);
    
    curSeg = offset & 0xf000;	/* to quickly tell what's in our segment */

    /* Fix up the line array, which shouldn't need to be sorted; there
     * is no way to add lines out of order, unless the caller is
     * messing with task->segIp.  Assert that the chunkarray doesn't
     * have variable-sized elements, as in that case we'll have to use
     * ChunkArrayEnum...
     */

    cah = (ChunkArrayHeader*)
	LMemDerefHandles(task->labels, lh->LH_lineArray);
    LABEL_ASSERT( cah->CAH_elementSize != 0 );
    size = cah->CAH_count;

    ld = (LineData*) (FIXED_CA_FIRST_ELEMENT(cah));
    for (i=0; i<size; i++,ld++) {
	if ((ld->LD_offset & 0xf000) != curSeg) {
	    continue;
	}
	if (ld->LD_offset > offset)
	{
	    lh->LH_codeSizeChanged = TRUE;
	    ld->LD_offset += delta;
	}
    }
    
    /* Fix up the target array, currently not sorted */

    cah = (ChunkArrayHeader*)
	LMemDerefHandles(task->labels, lh->LH_targetArray);
    LABEL_ASSERT( cah->CAH_elementSize != 0 );
    size = cah->CAH_count;

    td = (TargetData*) (FIXED_CA_FIRST_ELEMENT(cah));
    for (i=0; i<size; i++,td++) {
	if ((td->TD_offset == UNSET_OFFSET) ||
	    (td->TD_offset & 0xf000) != curSeg)
	{
	    continue;
	}
	if (td->TD_offset > offset)
	{
	    td->TD_offset += delta;
	}
    }
    
    /* Fix up the jump array, currently not sorted */

    cah = (ChunkArrayHeader*)
	LMemDerefHandles(task->labels, lh->LH_jumpArray);
    LABEL_ASSERT( cah->CAH_elementSize != 0 );
    size = cah->CAH_count;

    fixup = (FixupData*) (FIXED_CA_FIRST_ELEMENT(cah));
    for (i=0; i<size; i++,fixup++) {
	if ((fixup->FD_offset & 0xf000) != curSeg) {
	    continue;
	}
	if (fixup->FD_offset > offset)
	{
	    fixup->FD_offset += delta;
	}
    }

    return;
}

/*********************************************************************
 *			Label_CommitJumpChanges
 *********************************************************************
 * SYNOPSIS:	Re-write code segments with real jump offsets
 * CALLED BY:	INTERNAL, LabelDoFixups
 * RETURN:	nothing
 * SIDE EFFECTS: code segments might shrink
 * STRATEGY:
 *	Rely on fact that jump array is already sorted by offset.
 *	Code is modified in-place.
 *	
 *	Foreach S in (code segments)
 *	  [a] While (there are fixups left &&
 *	             current fixup is in segment S)
 *	    (1) Copy code up to fixup
 *	    (2) Emit proper jump opcode (if type == FT_JUMP)
 *	    (3) Emit relative offset, or word-sized virtual offset
 *	    (4) Go to next jump
 *
 *	  [b] copy rest of code in segment
 *
 *	  [c] update huge array element size and dirty it.
 *
 *	Also overloaded to add elements to the global reference array.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/16/94	Initial version			     
 * 
 *********************************************************************/
Boolean
Label_CommitJumpChanges(TaskPtr task)
{
    LabelHeader* lh;
    word	i;

    optr	fixupArr;
    word	fixupCount;
    word	j;		/* index of current fixup */
    FixupData*	fixup;		/* pointer to current fixup */

    optr	targetArr;
    Label	l;		/* index of target of current jump */
    TargetData*	td;

    lh = MemLock(task->labels);

    fixupArr = ConstructOptr(task->labels, lh->LH_jumpArray);
    fixupCount = ChunkArrayGetCount(fixupArr);
    j = 0;

    targetArr = ConstructOptr(task->labels, lh->LH_targetArray);

    /* Loop through code segments (from lh->LH_startSeg to
     * task->curSeg inclusive), updating them in place.
     */
    for (i=0; i+lh->LH_startSeg <= task->curSeg; i++)
    {
	byte*	code;
	word	segSize;	/* size of *code */

	word	wOff;		/* index of next byte to be written */
	word	rOff;		/* index of next byte to be read */
	word	jOff;		/* index of the fixup */

	code = CodeSegLock(task->vmHandle,
			   task->codeBlock,
			   i+lh->LH_startSeg,
			   &segSize);
	wOff = rOff = 0;

	/* [a] */
	while (j < fixupCount)
	{
	    fixup = (JumpData*)ChunkArrayElementToPtr(fixupArr, j, 0);

	    if ( (fixup->FD_origOffset & 0xf000) != i<<12 )
		break;

	    if (fixup->FD_type == FT_GLOBAL)
	    {
		GlobalRefData	grd;

		grd.GRD_offset = fixup->FD_offset;
		grd.GRD_index = fixup->FD_index;
		grd.GRD_type = fixup->FD_extraData;
		grd.GRD_funcNumber = task->funcNumber;
		HugeArrayAppend(task->vmHandle, task->globalRefs, 1, 
				(void *)&grd);
			      
		j += 1;
		continue;
	    }
	    LABEL_ASSERT(fixup->FD_type == FT_JUMP ||
			 fixup->FD_type == FT_LABEL);

	    jOff = fixup->FD_origOffset & 0x0fff;
	    LABEL_ASSERT( rOff < segSize );
	    LABEL_ASSERT( rOff <= jOff );
	    EC_ERROR_IF( jOff >= segSize, LABEL_OFFSET_TOO_LARGE );

	    /* (1) Shuffle bytes downward, if necessary */
	    if (rOff != wOff)
	    {
		memmove( &code[wOff], &code[rOff], jOff-rOff );
		wOff += jOff-rOff;
		rOff = jOff;	/* rOff += jOff - rOff */
	    } else {
		/* don't do the move -- it's just an expensive nop */
		wOff = rOff = jOff;
	    }

	    /* (2) write the correct jump opcode if it's a jump fixup */
	    if (fixup->FD_type == FT_JUMP) {
		code[wOff++] = (byte)Label_ConvertJump
		    (code[rOff++], fixup->FD_extraData);
	    }

	    /* (3) write correct target addr and go to next fixup */
	    l = CAST_ARR(Label, code[rOff]);
	    /* I think putting the label in code is redundant... */
	    LABEL_ASSERT(l == fixup->FD_index);
	    td = (TargetData*) ChunkArrayElementToPtr(targetArr, l, 0);

	    if (td->TD_offset == UNSET_OFFSET) 
	    {
		/* a jump to an non-existent label */
		CodeSegUnlock(code);
		MemUnlock(task->labels);
		SetError(task, E_UNDEFINED_LABEL);
		return FALSE;
	    }

	    /* addr can be relative for jump fixups only */
	    if (fixup->FD_type == FT_JUMP &&
		fixup->FD_extraData & JF_RELATIVE)
	    {
		CAST_ARR(sbyte, code[wOff]) =
		    (sbyte) (td->TD_offset - fixup->FD_offset);
		wOff += 1;
	    }
	    else
	    {
		CAST_ARR(word, code[wOff]) = td->TD_offset;
		if (BIG_ENDIAN) {
		    swapWord((word*)&(code[wOff]));
		}
		wOff += 2;
	    }
	    rOff += 2;

	    /* (4) Pretty self-explanatory... */
	    j += 1;
	}

	/* [b] Copy to end of segment -- at the end, wOff will be the
	 * new size of the segment.  Don't bother updating rOff, we
	 * don't care about it any more.
	 */
	if (rOff != wOff)
	{
	    memmove( &code[wOff], &code[rOff], segSize - rOff );
	    wOff += segSize - rOff;
	} else {
	    wOff = segSize;
	}

	/* [c] */
	CodeSegDirty(code);
	CodeSegUnlock(code);

	CodeSegContract(task->vmHandle,
			task->codeBlock,
			i+lh->LH_startSeg,
			wOff);
    }

    MemUnlock(task->labels);
    return TRUE;
}

/*********************************************************************
 *			Label_ConvertJump
 *********************************************************************
 * SYNOPSIS:	Convert a jump opcode to the correct form
 * CALLED BY:	INTERNAL, Label_CommitJumpChanges
 * RETURN:	correct Opcode
 * SIDE EFFECTS:
 *	Fatal errors if not passed a jump (in EC).
 *
 * STRATEGY:
 *	Takes a byte because TokenCode is a word.  This should be
 *	fixed up when opcodes get their own (byte-sized?) enum.
 *
 *	Otherwise, really simplistic.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/24/94	Initial version			     
 * 
 *********************************************************************/
Opcode
Label_ConvertJump(byte opcode, JumpFlags flags)
{
    Opcode	retval;

    LABEL_ASSERT( ! ((flags & JF_CROSS_SEGMENT) &&
		     (flags & JF_RELATIVE)) );

    /* Assume it doesn't change */
    retval = (Opcode) opcode;

    switch ((Opcode) opcode)
    {
	case OP_JMP:
	if (flags & JF_CROSS_SEGMENT)
	    retval = OP_JMP_SEG;
	else if (flags & JF_RELATIVE)
	    retval = OP_JMP_REL;
	break;

	case OP_BNE:
	if (flags & JF_CROSS_SEGMENT)
	    retval = OP_BNE_SEG;
	else if (flags & JF_RELATIVE)
	    retval = OP_BNE_REL;
	break;

	case OP_BEQ:
	if (flags & JF_CROSS_SEGMENT)
	    retval = OP_BEQ_SEG;
	else if (flags & JF_RELATIVE)
	    retval = OP_BEQ_REL;
	break;

	default:
	EC_ERROR(LABEL_INTERNAL_ERROR);
	break;
    }

    return retval;
}

/*********************************************************************
 *			Label_FlattenJumps
 *********************************************************************
 * SYNOPSIS:	Convert XSEG jumps to normal long jumps
 * CALLED BY:	INTERNAL LabelDoLocalFixups
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 *	segOffsets is an array of the offset at which a code segment
 *	would start if they were all spliced together back-to-back.
 *
 *	Compute it by getting the sizes of each segment (except for the
 *	last one, which doesn't matter); then add to each element in the
 *	array the value of all the previous elements.
 *
 *	Thus if we had 4 segs of sizes [10,12,15,13] we would end up with
 *	[0, 10+0, 12+(10+0), 15+(12+(10+0))]	or
 *	[0, 10, 22, 37]
 *
 *	Dynamic programming allows us to do this in one pass.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	3/ 1/96  	Initial version
 * 
 *********************************************************************/
void
Label_FlattenJumps(TaskPtr task)
{
    LabelHeader* lh;
    word	firstSeg, numSegs;
    word	segOffsets[16];

    optr	fixupArr;
    word	fixupCount, fixupIndex, i;

    lh = MemLock(task->labels);

    firstSeg = lh->LH_startSeg;
    numSegs = task->curSeg - firstSeg + 1;
    EC_ERROR_IF(numSegs>0xf, BE_FAILED_ASSERTION);

    /* Init segOffsets array */
    segOffsets[0] = 0;
    for (i=1; i<numSegs; i++)
    {
	byte*	code;
	word	prevSegSize;

	/* Current offset = prev seg's offset + size of previous seg */
	code = CodeSegLock(task->vmHandle, task->codeBlock,
			   firstSeg+(i-1), &prevSegSize);
	segOffsets[i] = segOffsets[i-1] + prevSegSize;
	CodeSegUnlock(code);
    }

    /* Loop through segments, flattening jumps */
    fixupArr = ConstructOptr(task->labels, lh->LH_jumpArray);
    fixupCount = ChunkArrayGetCount(fixupArr);
    fixupIndex = 0;
    for (i=0; i<numSegs; i++)
    {
	FixupData* fixup;
	byte*	code;
	word	dummy;
	word	offset, target;

	code = CodeSegLock(task->vmHandle, task->codeBlock,
			   i+firstSeg, &dummy);

	for (; fixupIndex < fixupCount; fixupIndex++)
	{
	    fixup = ChunkArrayElementToPtr(fixupArr, fixupIndex, NULL);

	    /* Fixup might be in next segment */
	    if ((fixup->FD_offset & 0xf000) != i<<12 ) break;

	    if (fixup->FD_type == FT_JUMP)
	    {
		Opcode	op;

		if (!(fixup->FD_extraData & JF_CROSS_SEGMENT)) continue;
		offset = fixup->FD_offset&0xfff;

		op = code[offset];

		switch (op) {
		case OP_JMP_SEG: op = OP_JMP; break;
		case OP_BNE_SEG: op = OP_BNE; break;
		case OP_BEQ_SEG: op = OP_BEQ; break;
		default:	EC_ERROR(-1); break;
		}

		code[offset] = op;
		offset ++;
		goto UPDATE_TARGET;
	    }
	    else if (fixup->FD_type == FT_LABEL)
	    {
		offset = fixup->FD_offset&0xfff;
UPDATE_TARGET:
		target = CAST_ARR(word, code[offset]);
		if (BIG_ENDIAN) { swapWord(&target); }

		/* Convert from 4 bits seg/12 bits offset to 16 bits offset
		 */
		target = segOffsets[target>>12] + (target & 0xfff);

		if (BIG_ENDIAN) { swapWord(&target); }
		CAST_ARR(word, code[offset]) = target;
	    }
	}

	CodeSegDirty(code);
	CodeSegUnlock(code);
    }
    MemUnlock(task->labels);
}
