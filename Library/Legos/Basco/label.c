/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basco
FILE:		label.c

AUTHOR:		Paul L. DuBois, Dec 14, 1994

ROUTINES:
	Name			Description
	----			-----------
EXT	LabelInitHeap
EXT	LabelCreateTarget
EXT	LabelCreateLine
EXT	LabelCreateFixup
EXT	LabelGetOffset
EXT	LabelSetOffset
INT	EC_CheckLabelHeap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	12/14/94	Initial version.

DESCRIPTION:
	Handle label generation and lookup

	$Id: label.c,v 1.1 98/10/13 21:43:03 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include "mystdapp.h"
#include "bascoint.h"
#include "label.h"
#include "labelint.h"

/* for codeseglock */
#include "codeint.h"

#include <lmem.h>
#include <chunkarr.h>


/*********************************************************************
 *			LabelDeleteGlobalRefsForFunction
 *********************************************************************
 * SYNOPSIS:	delete all global refs belonging to a specific function
 * CALLED BY:	LabelInitHeap, LabelDoGlobalRefFixups
 * RETURN:  	nothing
 * SIDE EFFECTS: elements deleted from globalRefs array
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/22/95	Initial version
 * 
 *********************************************************************/
void
LabelDeleteGlobalRefsForFunction(TaskPtr    task, int funcNumber,
				 Boolean    deleteFunc)
{
    int	i;

    i = HugeArrayGetCount(task->vmHandle, task->globalRefs);
    while (i)
    {
	GlobalRefData	*grd;
	word	    	dummy;

	--i;
	HugeArrayLock(task->vmHandle, task->globalRefs, i, (void**)&grd,
		      &dummy);
	if (grd->GRD_funcNumber == funcNumber) 
	{
	    HugeArrayUnlock(grd);
	    HugeArrayDelete(task->vmHandle, task->globalRefs, 1, i);
	} 
	else
	{
	    if (deleteFunc && grd->GRD_funcNumber > funcNumber) 
	    {
		grd->GRD_funcNumber--;
		HugeArrayDirty(grd); 
	    }
	    HugeArrayUnlock(grd);
	}
    }
}


/*********************************************************************
 *			LabelInitHeap
 *********************************************************************
 * SYNOPSIS:	Create and init a new heap for label generation use.
 * CALLED BY:	EXTERNAL
 * RETURN:	TRUE if successful.
 *
 * SIDE EFFECTS: Allocates memory
 * STRATEGY:
 *	Assumes task->curSeg is element # of first code element;
 *	caches this so later code can figure out what segment #
 *	an offset is in -- this assumes that all code segments
 *	are in adjacent huge array entries.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/14/94	Initial version			     
 * 
 *********************************************************************/
Boolean
LabelInitHeap(TaskPtr task)
{
    MemHandle	mh;
    ChunkHandle	lineArray, targetArray, jumpArray;
    LabelHeader* lh;

    /*
     * Allocate memory and deal with errors
     */
    mh = MemAllocLMem(LMEM_TYPE_GENERAL, sizeof(LabelHeader));
    if (mh == NullHandle) return FALSE;

    lh = (LabelHeader*) MemLock(mh);

    lineArray = ChunkArrayCreate(mh, sizeof(LineData), 0, 0);
    targetArray = ChunkArrayCreate(mh, sizeof(TargetData), 0, 0);
    jumpArray = ChunkArrayCreate(mh, sizeof(JumpData), 0, 0);

    if ((lineArray == 0) || (targetArray == 0) || (jumpArray == 0)) {
	MemFree(mh);
	return FALSE;
    }
    lh = MemDeref(mh);

    lh->LH_lineArray = lineArray;
    lh->LH_targetArray = targetArray;
    lh->LH_jumpArray = jumpArray;
    lh->LH_startSeg = task->curSeg;
#if ERROR_CHECK
    lh->LH_tag = EC_LABEL_HEAP_TAG;
#endif

    MemUnlock(mh);


    /* one other thing to do here, is delete all the global ref entries
     * for this function, since they will be invalid
     */
    LabelDeleteGlobalRefsForFunction(task, task->funcNumber, FALSE);
    task->labels = mh;
    return TRUE;
}

/*********************************************************************
 *			LabelCreateTarget
 *********************************************************************
 * SYNOPSIS:	Create a target label.
 * CALLED BY:	EXTERNAL
 * RETURN:	Newly-created label, or NULL_LABEL on error
 * SIDE EFFECTS:may expand label heap
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/16/94	Initial version			     
 * 
 *********************************************************************/
Label
LabelCreateTarget(TaskPtr task)
{
    MemHandle		heap;
    Label		retval;
    LabelHeader*	blockHeader;
    ChunkHandle		ch;
    ChunkArrayHeader*	chunkHeader;
    TargetData*		data;

    heap = task->labels;
    blockHeader = (LabelHeader*) MemLock(heap);
EC (	EC_CheckLabelHeap(heap);					)

    ch = blockHeader->LH_targetArray;
    chunkHeader = LMemDerefHandles(heap, ch);
    retval = chunkHeader->CAH_count;

    data = (TargetData*) ChunkArrayAppendHandles(heap, ch, 0);
    LABEL_ASSERT( ChunkArrayPtrToElementHandle(ch, data) == retval );

    data->TD_offset = UNSET_OFFSET;

    MemUnlock(heap);
    return retval;
}

/*********************************************************************
 *			LabelCreateLine
 *********************************************************************
 * SYNOPSIS:	Create a line label.
 * CALLED BY:	EXTERNAL
 * RETURN:	nothing
 * SIDE EFFECTS:may expand label heap.
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/16/94		Initial version			     
 * 
 *********************************************************************/
void
LabelCreateLine(TaskPtr task, word line)
{
    MemHandle		heap;
    LabelHeader*	lh;
    LineData*		data;

    heap = task->labels;
    lh = (LabelHeader*) MemLock(heap);
EC (	EC_CheckLabelHeap(heap);					)

    data = (LineData*) ChunkArrayAppendHandles(heap,
					       lh->LH_lineArray,
					       0);

    /* Added by rg 12/28/94.  The above could invalidate pointers. */

    lh = (LabelHeader*) MemDeref(heap);

    /* Make sure there will be no overlap when we construct LD_offset */
    EC_ERROR_IF((task->curSeg - lh->LH_startSeg) & 0xfff0,
		LABEL_BAD_SEG_OR_OFFSET);
    EC_ERROR_IF(task->segIp & 0xf000, LABEL_BAD_SEG_OR_OFFSET);

    data->LD_offset = ((task->curSeg - lh->LH_startSeg) << 12) | task->segIp;
    data->LD_line = line;

    MemUnlock(heap);
    return;
}


/*********************************************************************
 *			LabelCreateFixup
 *********************************************************************
 * SYNOPSIS:	Create a Fixup
 * CALLED BY:	EXTERNAL
 * RETURN:	nothing
 * SIDE EFFECTS:may expand label heap.
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/16/94		Initial version			     
 * 
 *********************************************************************/
/* P FIXME proto */
void
LabelCreateFixup(TaskPtr task, FixupType type, word index)
{
    MemHandle		heap;
    LabelHeader*	lh;
    FixupData*		data;

    heap = task->labels;
    lh = (LabelHeader*) MemLock(heap);
EC (	EC_CheckLabelHeap(heap);					)

    data = (FixupData*) ChunkArrayAppendHandles(heap,
						lh->LH_jumpArray,
						0);
    /* Added by rg 12/28/94.  The above could invalidate pointers. */

    lh = (LabelHeader*) MemDeref(heap);

    /* Make sure there will be no overlap when we construct LD_offset */
    EC_ERROR_IF((task->curSeg - lh->LH_startSeg) & 0xfff0,
		LABEL_BAD_SEG_OR_OFFSET);
    EC_ERROR_IF(task->segIp & 0xf000, LABEL_BAD_SEG_OR_OFFSET);

    data->FD_offset =
	((task->curSeg - lh->LH_startSeg) << 12) | task->segIp;
    data->FD_type = type;
    data->FD_index = index;
    data->FD_extraData = 0;

    MemUnlock(heap);
    return;
}

/*********************************************************************
 *			LabelCreateGlobalFixup
 *********************************************************************
 * SYNOPSIS:	Create a fixup for a global-type thing
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:    
 * STRATEGY:	I have plans for using this to create fixups for global
 *	    	variable, procedure calls and constants, so that if a global
 *	    	variable changes, we don't need to recompile everything, we
 *	    	can just go through and fix things up.
 *
 *	Maybe this should just be merged with LabelCreateJump...
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 6/95	Initial version
 * 
 *********************************************************************/
void
LabelCreateGlobalFixup(TaskPtr task, word index, GlobalRefType grt)
{
    MemHandle		heap;
    LabelHeader*	lh;
    FixupData*		data;

#ifndef FIXUP_CONSTANTS
    /* Fixing up constants cant work?  Should this be nuked or fixed?
     * --dubois 12/28/95
     */
    if (grt == GRT_CONSTANT) {
	return;
    }
#endif

    heap = task->labels;
    lh = MemLock(heap);
EC (	EC_CheckLabelHeap(heap);					)
    data = ChunkArrayAppendHandles(heap, lh->LH_jumpArray, 0);
    lh = MemDeref(heap);

    /* Make sure there will be no overlap when we construct LD_offset */
    EC_ERROR_IF((task->curSeg - lh->LH_startSeg) & 0xfff0,
		LABEL_BAD_SEG_OR_OFFSET);
    EC_ERROR_IF(task->segIp & 0xf000, LABEL_BAD_SEG_OR_OFFSET);

    data->FD_offset =
	((task->curSeg - lh->LH_startSeg) << 12) | task->segIp;

    data->FD_type = FT_GLOBAL;
    data->FD_index = index;
    data->FD_extraData = grt;
    MemUnlock(heap);
    return;
}

/*********************************************************************
 *			LabelSetOffset
 *********************************************************************
 * SYNOPSIS:	Set a target's offset
 * CALLED BY:	EXTERNAL
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 *	EC: Assert that offset hasn't been set yet
 *	EC: Offset shouldn't be UNSET_OFFSET.  However, UNSET_OFFSET
 *	    is chosen so that this shouldn't occur in real life.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/15/94	Initial version			     
 * 
 *********************************************************************/
void
LabelSetOffset(TaskPtr task, Label l)
{
    MemHandle		heap;
    LabelHeader*	lh;
    ChunkHandle		ch;
    TargetData*		data;
    word		offset;

    heap = task->labels;
    lh = MemLock(heap);
EC( EC_CheckLabelHeap(heap);					)
    ch = lh->LH_targetArray;

#if ERROR_CHECK
    {
	ChunkArrayHeader*	chunkHeader;

	chunkHeader = (ChunkArrayHeader*) LMemDerefHandles(heap, ch);
	EC_ERROR_IF(l >= chunkHeader->CAH_count, LABEL_BAD_LABEL_NUMBER);
	EC_ERROR_IF(l == NULL_LABEL, LABEL_BAD_LABEL_NUMBER);
    }
#endif

    data = (TargetData*) ChunkArrayElementToPtrHandles(heap, ch, l, (void*)0);


    /* Make sure there will be no overlap when we construct LD_offset */
    EC_ERROR_IF((task->curSeg - lh->LH_startSeg) & 0xfff0,
		LABEL_BAD_SEG_OR_OFFSET);
    EC_ERROR_IF(task->segIp & 0xf000, LABEL_BAD_SEG_OR_OFFSET);

    offset = ((task->curSeg - lh->LH_startSeg) << 12) | task->segIp;

    LABEL_ASSERT( offset != UNSET_OFFSET );
    EC_ERROR_IF(data->TD_offset != UNSET_OFFSET, LABEL_OFFSET_ALREADY_SET);

    data->TD_offset = offset;

    MemUnlock(heap);
    return;
}

void LabelDestroyHeap(TaskPtr task)
{
    MemFree(task->labels);
#if ERROR_CHECK
    task->labels = 0xcccc;
#endif
    return;
}

/*********************************************************************
 *			EC_CheckLabelHeap
 *********************************************************************
 * SYNOPSIS:	Do some sanity checking
 * CALLED BY:	INTERNAL
 * RETURN:	nothing
 * SIDE EFFECTS:may fatal error
 * STRATEGY:
 *	- check LH_tag in header
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/16/94		Initial version			     
 * 
 *********************************************************************/
#if ERROR_CHECK
void
EC_CheckLabelHeap(MemHandle heap)
{
    LabelHeader*	lh;
    lh = MemLock(heap);
    EC_ERROR_IF(lh->LH_tag != EC_LABEL_HEAP_TAG, LABEL_BAD_LABEL_HEAP);
    MemUnlock(heap);
}
#endif

/*********************************************************************
 *			EC_FinalCheckLabelHeap
 *********************************************************************
 * SYNOPSIS:	Do sanity checking after all codegen is done
 * CALLED BY:	INTERNAL
 * RETURN:	nothing
 * SIDE EFFECTS:may fatal error
 *
 * STRATEGY:
 *	- perform checks in EC_CheckLabelHeap (just calls it)
 *	- asserts that no targets/jumps/lines have offset UNSET_OFFSET
 *	- assert that line and jump arrays are in order
 *	  (by offset)
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/20/94	Initial version			     
 * 
 *********************************************************************/
#if ERROR_CHECK
void
EC_FinalCheckLabelHeap(MemHandle heap)
{
    LabelHeader*	lh;
    ChunkArrayHeader*	cah;
    word i;

    lh = MemLock(heap);
    EC_CheckLabelHeap(heap);

    {
	LineData*	ld;
	word		oldOffset;
	
	cah = LMemDerefHandles(heap, lh->LH_lineArray);
	ld = (LineData*) (&cah[1]);
	for (i=0, oldOffset = 0;
	     i<cah->CAH_count;
	     i++,ld++)
	{
	    EC_ERROR_IF(ld->LD_offset == UNSET_OFFSET,
			LABEL_NULL_OFFSET_AFTER_CODEGEN);
	    LABEL_ASSERT( ld->LD_offset >= oldOffset );
	    oldOffset = ld->LD_offset;
	}
    }
	
    {
	FixupData*	fixup;
	word		oldOffset;
	
	cah = LMemDerefHandles(heap, lh->LH_jumpArray);
	fixup = (FixupData*) (&cah[1]);
	for (i=0, oldOffset=0;
	     i<cah->CAH_count;
	     i++,fixup++)
	{
	    EC_ERROR_IF(fixup->FD_offset == UNSET_OFFSET,
			LABEL_NULL_OFFSET_AFTER_CODEGEN);
	    LABEL_ASSERT( fixup->FD_offset >= oldOffset );
	    oldOffset = fixup->FD_offset;
	}
    }


#if 0	
    /* this is a bogus check, as things like FOR loops with no exits
     * will create targets and never jump to them
     */
    {
	TargetData*	td;
	
	cah = LMemDerefHandles(heap, lh->LH_targetArray);
	td = (TargetData*) (&cah[1]);
	for (i=0 ; i<cah->CAH_count; i++,td++) {
	    EC_ERROR_IF(td->TD_offset == UNSET_OFFSET,
			LABEL_NULL_OFFSET_AFTER_CODEGEN);
	}
    }
#endif	
    MemUnlock(heap);
}
#endif

#if 0
/*********************************************************************
 *			LabelGetOffset
 *********************************************************************
 * SYNOPSIS:	Return label's offset
 * CALLED BY:	EXTERNAL
 * RETURN:	word-sized offset
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/15/94	Initial version			     
 * 
 *********************************************************************/
word
LabelGetOffset(MemHandle heap, Label l)
{
    LabelHeader*	blockHeader;
    ChunkHandle		ch;
    TargetData*		data;
    word		retval;

    blockHeader = MemLock(heap);
    EC( EC_CheckLabelHeap(heap);					)
    ch = blockHeader->LH_targetArray;

#if ERROR_CHECK
    {
	ChunkArrayHeader*	chunkHeader;

	chunkHeader = (ChunkArrayHeader*) LMemDerefHandles(heap, ch);
	EC_ERROR_IF(l >= chunkHeader->CAH_count, LABEL_BAD_LABEL_NUMBER);
	EC_ERROR_IF(l == NULL_LABEL, LABEL_BAD_LABEL_NUMBER);
    }
#endif

    data = (TargetData*) ChunkArrayElementToPtrHandles(heap, ch, l, (void*)0);
    retval = data->TD_offset;

    MemUnlock(heap);
    return retval;
}
#endif

#if 0
/* These aren't needed at compile time any more --dubois
 */
/*********************************************************************
 *			LabelGetCounts
 *********************************************************************
 * SYNOPSIS:	get size of current label tables
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 4/ 4/95	Initial version			     
 * 
 *********************************************************************/
void LabelGetCounts(MemHandle heap,
		    word *numTargets, word *numJumps, word *numLines)
{
    LabelHeader	*lh;

    EC( ECCheckMemHandle(heap);	    )
    lh = MemLock(heap);
    EC( EC_CheckLabelHeap(heap);    )
    
    *numTargets = ChunkArrayGetCountHandles(heap, lh->LH_targetArray);
    *numJumps = ChunkArrayGetCountHandles(heap, lh->LH_jumpArray);
    *numLines = ChunkArrayGetCountHandles(heap, lh->LH_lineArray);
    MemUnlock(heap);
}
	

/*********************************************************************
 *			LabelDeleteEntries
 *********************************************************************
 * SYNOPSIS:	delete a bunch of label entries in various tables
 * CALLED BY:	GLOBAL
 * RETURN:	void
 * SIDE EFFECTS:    deletes entries from the label tables
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 4/ 5/95	Initial version			     
 * 
 *********************************************************************/
void LabelDeleteEntries(MemHandle heap, 
		   word jumpStart, word jumpCount,
		   word targetStart, word targetCount,
		   word lineStart, word lineCount)
{
    LabelHeader	*lh;

    EC( ECCheckMemHandle(heap);	    )
    lh = MemLock(heap);
    EC( EC_CheckLabelHeap(heap);    )
	
    if (jumpCount) {
	ChunkArrayDeleteRange(ConstructOptr(heap, lh->LH_jumpArray),
			      jumpStart, jumpCount);
    }
    if (targetCount) {
	ChunkArrayDeleteRange(ConstructOptr(heap, lh->LH_targetArray),
			      targetStart, targetCount);
    }
    if (lineCount) {
	ChunkArrayDeleteRange(ConstructOptr(heap, lh->LH_lineArray),
			      lineStart, lineCount);
    }
    MemUnlock(heap);
}
#endif
