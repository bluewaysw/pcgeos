/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:        
MODULE:         Runtime
FILE:           bugmain.c

AUTHOR:         Roy Goldman, Jan 17, 1995

ROUTINES:
	Name                    Description
	----                    -----------

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy      1/17/95        Initial version.

DESCRIPTION:
	Debugging code.....
	Not much effort has been made here to make things
	incredibly fast.  None of the work here is too complicated
	and it will all be running off the 486. Hence I've
	concentrated on making things simple and easy to follow.
	

	$Revision: 1.2 $
	$Id: bugmain.c,v 1.2 98/10/05 12:36:29 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#if defined __BORLANDC__
#define _near near
#elif defined LIBERTY
#define _near
#endif

#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/runint.h>
#include <Legos/funtab.h>
#include <Legos/progtask.h>
#include <Legos/builtin.h>
#include <Legos/sst.h>
#include <Legos/runmath.h>
#include <Legos/strmap.h>
#include <Legos/rheapint.h>
#include <Ansi/string.h>
#include <Legos/ehan.h>
#include <Legos/fixds.h>
#include <Legos/compat.h>
#include <Legos/fido.h>
#include "bugint.h"

#include <data/array.h>

/* for checking theHeap */
//#include <pos/hpalloc.h>

#else	/* GEOS version below */

#include <geos.h>
#include <math.h>
#include <chunkarr.h>
#include <hugearr.h>
#include <Legos/edit.h>
#include <Legos/Internal/runtask.h>
#include <Legos/Internal/progtask.h>
#include <Legos/opcode.h>
#include <Legos/legtype.h>
#include <Legos/bugdata.h>
#include <Legos/fido.h>
#include <Ansi/string.h>
#include <sem.h>

#include "mystdapp.h"
#include "bugint.h"
#include "sst.h"
#include "funtab.h"
#include "rheapint.h"
#include "fixds.h"
#include "compat.h"

extern word setDSToDgroup(void);
extern void restoreDS(word);
#endif

    

/*********************************************************************
 *			ECCheckFrameContext
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 6/13/95	Initial version
 * 
 *********************************************************************/
#if ERROR_CHECK
void ECCheckFrameContext(FrameContext  *fc)
{
#ifdef LIBERTY
    if ((fc->FC_module != NullHandle) && (fc->FC_module != (MemHandle)0xcccccccc))
#else
    if ((fc->FC_module != NullHandle) && (fc->FC_module != 0xcccc))
#endif
    {
	ECCheckMemHandle(fc->FC_module);
    }
}
#endif

/*********************************************************************
 *			BugDestroy
 *********************************************************************
 * SYNOPSIS:	kill off a BugInfoBlock
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	right now the only alloced in the bugInfo block header
 *	    	is a chunk array, which will get freed as part of the
 *	    	MemFree
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 4/ 4/95	Initial version			     
 * 
 *********************************************************************/
void
BugDestroy(MemHandle bugHandle)
{
    MemFree(bugHandle);
}

/*********************************************************************
 *                      BugGetBugHandleFromRTask
 *********************************************************************
 * SYNOPSIS:    Return the bug handle of an rtask
 * CALLED BY:   GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      2/12/95        Initial version                      
 * 
 *********************************************************************/
MemHandle BugGetBugHandleFromRTask(MemHandle rtaskHan) 
{
    RunTask *rtask;
    MemHandle ret;

    rtask = (RunTask *)MemLock(rtaskHan);

    EC_ERROR_IF(rtask->RT_cookie != RTASK_COOKIE, -1);

    ret = rtask->RT_bugHandle;

    MemUnlock(rtaskHan);
    return ret;
}


/*********************************************************************
 *			BugSetBugHandleNotRunning
 *********************************************************************
 * SYNOPSIS:	Set the rtask handle in the bug handle to NULL
 *              telling the world that the buginfo block isn't
 *              currently tied to running code.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 5/23/95	Initial version
 * 
 *********************************************************************/
void BugSetBugHandleNotRunning(MemHandle bugHandle) 
{
    BugInfoHeader *b;

    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);
    b->BIH_runTaskHan = NullHandle;
    MemUnlock(bugHandle);
}

	
/*********************************************************************
 *                      BugGetFuncFromContext
 *********************************************************************
 * SYNOPSIS:	Get func # given a FrameContext
 * CALLED BY:   EXTERNAL
 * RETURN:      Function number
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/18/95        Initial version                      
 * 
 *********************************************************************/
word
BugGetFuncFromContext(FrameContext *fc)
{
    word	i, numFuncs;
    RunTask*	rtask;
    FunTabInfo*	fti;
    RunFastFTabEntry *table;

    EC(ECCheckFrameContext(fc));
    rtask = (RunTask*)MemLock(fc->FC_module);
    fti = &rtask->RT_funTabInfo;

    numFuncs = fti->FTI_funCount;
    FUNTAB_LOCK_TABLE_ENTRY(*fti, table, 0);
    for (i = 0;
	 i < numFuncs;
	 i++,table++) 
    {
	EC_BOUNDS(table);
#if USES_SEGMENTS
	if (table->RFFTE_codeHandle == fc->FC_startSeg)
#else
	if (table->RFFTE_codeHandle == fc->FC_codeHandle)
#endif
	{
	    goto done;
	}
    }
    EC_ERROR(BUG_INVALID_FUNC_SEG);

 done:
    FUNTAB_UNLOCK_TABLE_ENTRY(*fti, table);
    MemUnlock(fc->FC_module);
    return i;
}

/*********************************************************************
 *			Bug_GetPreviousContext
 *********************************************************************
 * SYNOPSIS:	Find context of caller of passed context
 *
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	bfc->context need not be pointing into the stack
 *	It will point into the stack on return, though.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 5/ 9/95	Initial version
 * 
 *********************************************************************/
void
Bug_GetPreviousContext(BugFrameContext* bfc)
{
    dword*	dataCursor;
    byte*	typeCursor;

    EC(ECCheckFrameContext(bfc->context));
    typeCursor	= bfc->typeStack + bfc->context->FC_vbpType;
    dataCursor	= bfc->dataStack + bfc->context->FC_vbpData;

    /* bp points to local vars -- skip forward over them to find context
     * Rely on the fact that all of them are 4 bytes
     */
    while (*typeCursor != TYPE_FRAME_CONTEXT)
    {
	ASSERT(*typeCursor < TYPE_NUM_TYPES);
	typeCursor++;
	dataCursor++;
    }
    bfc->context = (FrameContext*)dataCursor;
}

/*********************************************************************
 *                      BugSetSuspendStatus
 *********************************************************************
 * SYNOPSIS:    Set the run task's suspend status
 * CALLED BY:   RunMainLoop, right before returning control...
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/19/95        Initial version                      
 * 
 *********************************************************************/
void BugSetSuspendStatus(MemHandle bugHandle, BugSuspendStatus bss) 
{
    BugInfoHeader *b;

    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);
    b->BIH_suspendStatus = bss;
    MemUnlock(bugHandle);
}


/*********************************************************************
 *                      BugGetSuspendStatus
 *********************************************************************
 * SYNOPSIS:    Returns suspend status of a run task
 * CALLED BY:   Editor/Builder to figure out why execution was
 *              suspended...
 * RETURN:      BugSuspendStatus value
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/19/95        Initial version                      
 * 
 *********************************************************************/
BugSuspendStatus BugGetSuspendStatus(MemHandle bugHandle) 
{
    BugInfoHeader *b;
    BugSuspendStatus bss;

    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);
    bss = b->BIH_suspendStatus;
    MemUnlock(bugHandle);    
    return bss;
}

/*********************************************************************
 *                      BugSetBuilderRequest
 *********************************************************************
 * SYNOPSIS:    Allow the builder to request
 *              runtime action from the runtime engine. 
 * CALLED BY:   BUILDER BUILDER BUILDER!
 * RETURN:
 * SIDE EFFECTS:
 *
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      2/11/95        Initial version                      
 * 
 *********************************************************************/
void
BugSetBuilderRequest(PTaskHan ptaskHan, BugBuilderRequest bbr) 
{
    PTaskPtr	ptask;
    RunTask*	rtask;

    ptask = (PTaskPtr)MemLock(ptaskHan);
    EC_ERROR_IF(ptask->PT_cookie != PTASK_COOKIE, -1);
    rtask = (RunTask*)MemLock(ptask->PT_bugModule);
    EC_ERROR_IF(rtask->RT_cookie != RTASK_COOKIE, -1);

    rtask->RT_builderRequest = bbr;

    /* if its a HALT, set the HALT bit in the progtask as well so all
     * code stops executing
     */
    if (bbr == BBR_HALT)
    {
	ptask->PT_flags |= PT_HALT;
    }
    MemUnlock(ptask->PT_bugModule);
    MemUnlock(ptaskHan);
}


/*********************************************************************
 *                      BugGetBuilderRequest
 *********************************************************************
 * SYNOPSIS:    Get builder request
 * CALLED BY:   EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      2/11/95        Initial version                      
 * 
 *********************************************************************/
BugBuilderRequest
BugGetBuilderRequest(PTaskHan ptaskHan)
{
    PTaskPtr	ptask;
    RunTask*	rtask;
    BugBuilderRequest bbr;

    ptask = (PTaskPtr)MemLock(ptaskHan);
    ASSERT(ptask->PT_cookie == PTASK_COOKIE);

    rtask = (RunTask*)MemLock(ptask->PT_bugModule);
    ASSERT(rtask->RT_cookie == RTASK_COOKIE);

    bbr = rtask->RT_builderRequest;

    MemUnlock(ptask->PT_bugModule);
    MemUnlock(ptaskHan);

    return bbr;
}


/* ----------------------------------------------------- */
/* INTERNAL ROUTINES                                     */
/* ----------------------------------------------------- */

/*********************************************************************
 *                      BugLineNumToOffset
 *********************************************************************
 * SYNOPSIS:    Translate a line number into a virtual offset
 *              through the line label information generated
 *              during code gen phase. Used for setting breakpoints
 *              on source lines...
 *
 * CALLED BY:   Any debugging client, really
 * RETURN:      The virtual offset corresponding to a given
 *              line or NULL_OFFSET otherwise...
 * SIDE EFFECTS:
 * STRATEGY:    This routine assumes never more than 65534 lines
 *              in a function. Don't think that's a problem,
 *              as the way line number labels are stored in the
 *              chunk array basically limits us to less than that
 *              anyway.
 *
 *              Main idea is to grab the line label information
 *              from code generation time.  We assume its sorted,
 *              and for now will just use an easy linear search.
 *              Just break when we've passed the offset we're looking for.
 *             
 *              We may find redundancies, but that's not a problem.
 *              The first one we find is what we want.
 * 
 * 
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/17/95        Initial version                      
 * 
 *********************************************************************/
#ifndef LIBERTY
#define FTAB_CHUNK 0x10
word
BugLineNumToOffset(MemHandle bugHandle, word funcNumber, word lineNum) 
{
    FuncLabelInfo *fli;
    VMFileHandle vmfile;
    VMBlockHandle lineArray;
    dword	labelOffset;
    word		labelSize, i;
    word	tempLine, tempOffset, dummy;
    word	offset = NULL_OFFSET;
    BugInfoHeader *b;
    LineData	*ld;

    /* Lock rtfe entry for the given function number ... */
    /* and grab the huge array offset and the number of entries. */

    /* Find our line labels... */

    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);

    MemLock(b->BIH_funcTable);
    if (b->BIH_funcLabelTable == NullHandle ||
	(ChunkArrayGetCountHandles(b->BIH_funcTable, FTAB_CHUNK) 
	 <= funcNumber))
    {
	MemUnlock(b->BIH_funcTable);
	MemUnlock(bugHandle);
	return NULL_OFFSET;
    }

    MemUnlock(b->BIH_funcTable);

    fli = MemLock(b->BIH_funcLabelTable);
    fli += funcNumber;

    labelOffset = fli->FLI_labelOffset;
    labelSize   = fli->FLI_labelSize;

    MemUnlock(b->BIH_funcLabelTable);

    vmfile = b->BIH_vmFile;
    lineArray = b->BIH_lineArray;

    MemUnlock(bugHandle);
    
    /* Scan through the line label huge array, looking
       for the first matching entry. 

       Note that line labels are in order of code generation,
       which isn't necessarily order of source code.

       So we actually have to look through all of them before
       we decide that the line is irrelevant...
    */

    for (i = labelOffset; i < labelOffset + labelSize; i++) 
    {
	HugeArrayLock(vmfile, lineArray, i,
		      (void**)&ld, &dummy);
	tempLine   = ld->LD_line;
	tempOffset = ld->LD_offset;

	HugeArrayUnlock(ld);

	if (tempLine == lineNum) 
	{
	    offset = tempOffset;
	    break;
	}

    }
    return offset;
}


/*********************************************************************
 *                      BugOffsetToLineNum
 *********************************************************************
 * SYNOPSIS:    Translates a virtual offset into a routine 
 *              into a line number which corresponds to it.
 * CALLED BY:   
 * RETURN:      Line number specified offset corresponds to.
 *              Sets START true if the offset happens to be
 *              at the beginning of a line..
 *
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      2/13/95        Initial version                      
 * 
 *********************************************************************/
word
BugOffsetToLineNum(MemHandle bugHandle, word funcNumber,
		   word offset, byte *start) 
{
    FuncLabelInfo *fli;
    BugInfoHeader *b;
    word useless;
    dword labelOffset;
    word i,labelSize;
    VMBlockHandle lineArray;
    VMFileHandle vmfile;
    LineData *ld;
    word tempLine, lastLine;
    dword tempOffset;
    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);
    MemLock(b->BIH_funcTable);
    if (b->BIH_funcLabelTable == NullHandle ||
	(ChunkArrayGetCountHandles(b->BIH_funcTable, FTAB_CHUNK) 
	 <= funcNumber))
    {
	MemUnlock(b->BIH_funcTable);
	*start = FALSE;
	lastLine = -1;
	MemUnlock(bugHandle);
	goto done;
    }
    MemUnlock(b->BIH_funcTable);
    fli = MemLock(b->BIH_funcLabelTable);
    fli += funcNumber;

    labelOffset = fli->FLI_labelOffset;
    labelSize   = fli->FLI_labelSize;

    MemUnlock(b->BIH_funcLabelTable);

    vmfile     = b->BIH_vmFile;
    lineArray  = b->BIH_lineArray;

    MemUnlock(bugHandle);

    lastLine = 0;

    for (i = labelOffset; i < labelOffset + labelSize; i++) 
    {
	HugeArrayLock(vmfile, lineArray, i,
		      (void**)&ld, &useless);

	tempLine   = ld->LD_line;
	tempOffset = ld->LD_offset;

	HugeArrayUnlock(ld);

	if (tempOffset == offset) {
	    lastLine = tempLine;
	    *start = TRUE;
	    break;
	}

	if (tempOffset > offset) {
	    *start = FALSE;
	    break;
	}
	
	lastLine = tempLine;
    }
done:
    return lastLine;
}
#endif

/*********************************************************************
 *                      BugSetBreakAtOffset
 *********************************************************************
 * SYNOPSIS:    Sets a breakpoint at the given virtual offset of
 *              the specified routine.  
 *
 *              Supply break flags too...
 * CALLED BY:   INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/18/95        Initial version                      
 * 
 *********************************************************************/
void
BugSetBreakAtOffset(MemHandle bugHandle, word funcNumber, word offset,
		    word lineNumber, BugBreakFlags breakFlags) 
{
    BugBreakPoint tbp, *bpPtr;
    RunFastFTabEntry *rfte;
    byte *code;
#ifndef LIBERTY
    optr breakArray;
    word dummy;
#endif
    BugInfoHeader *b;
    int numBreaks, i;
    Boolean found = FALSE;

    tbp.BBP_breakFlags = breakFlags;
    tbp.BBP_funcNumber = funcNumber;
    tbp.BBP_lineNum    = lineNumber;
    tbp.BBP_insn       = OP_BREAK;

    /* Find the instruction we're swapping out... */

    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);

    /* if we are setting a breakpoint while paused, then we are able
     * to map the offset and actually set the breakpoint since the compiled
     * code must be up to date as we are actually running - this allows
     * breakpoints that are set while paused to actually get installed
     * right away
     */
#ifndef LIBERTY
    if ((b->BIH_builderState == BS_PAUSED || 
	 b->BIH_builderState == BS_PAUSED_IDLE) 
	&& offset == NULL_OFFSET) 
    {
	offset = BugLineNumToOffset(bugHandle, funcNumber, lineNumber);
    }
#endif

    tbp.BBP_offset     = offset;
	
    /* Only actually set the breakpoint if we're running. Otherwise
       rely on SetAllBreakpoints to do this when things are kosher...
    */
    if (offset != NULL_OFFSET && b->BIH_runTaskHan != NullHandle) 
    {
	RunTask *rtask = (RunTask *)MemLock(b->BIH_runTaskHan);

	EC_BOUNDS(rtask);

	FUNTAB_LOCK_TABLE_ENTRY(rtask->RT_funTabInfo, rfte, funcNumber);

#ifdef LIBERTY
	code = (byte*)CheckLock(rfte->RFFTE_codeHandle + ((offset&0xf000)>>12));
#else
	HugeArrayLock(rtask->RT_vmFile, rtask->RT_funTabInfo.FTI_code,
		      rfte->RFFTE_codeHandle + ((offset&0xf000)>>12),
		      (void**)&code, &dummy);
#endif

	/* make sure its not already installed */
	EC_BOUNDS(&code[offset&0x0fff]);
	/* Swap it with the OP_BREAK interrupt */
	tbp.BBP_insn       = (Opcode)code[offset & 0x0fff];
	if (code[offset & 0x0fff] != OP_BREAK)
	{
	    code[offset & 0x0fff] = OP_BREAK;
#ifndef LIBERTY
	    HugeArrayDirty(code);
#endif
	}

#ifdef LIBERTY
	CheckUnlock(rfte->RFFTE_codeHandle + ((offset&0xf000)>>12));
#else
	HugeArrayUnlock(code);
#endif
	FUNTAB_UNLOCK_TABLE_ENTRY(rtask->RT_funTabInfo, rfte);

	MemUnlock(b->BIH_runTaskHan);

	/* Now add this breakpoint to the break list... */
	/* First step is to see if one already exists... */
    }


#ifdef LIBERTY
    numBreaks = b->BIH_breakArray->GetCount();
#else
    breakArray = ConstructOptr(bugHandle, b->BIH_breakArray);

    numBreaks = ChunkArrayGetCount(breakArray);
#endif

    for (i = 0; (i < numBreaks) && (found != TRUE); i++) 
    {
#ifdef LIBERTY
	bpPtr = (BugBreakPoint *)b->BIH_breakArray->LockElement(i);
#else
	bpPtr = ChunkArrayElementToPtr(breakArray, i, &dummy);
#endif

	/* if the offsets are different but neither one is NULL_OFFSET
	 * they are not really the same breakpoint.
	 * This happens normally when one line of code has adjacent
	 * line number labels but with different offsets (like DO WHILE)
	 * and the user single-steps
	 *
	 * I'm taking this case out of the next if, where it used to die
	 * for no good reason -- paul 9/30/96
	 */
	if ((offset != bpPtr->BBP_offset) &&
	    (offset != NULL_OFFSET) &&
	    (bpPtr->BBP_offset != NULL_OFFSET))
	{
	    found = FALSE;	/* it is already, but just to be explicit */
	}
	else if (bpPtr->BBP_lineNum == tbp.BBP_lineNum &&
		 bpPtr->BBP_funcNumber == tbp.BBP_funcNumber)
	{

	    /* Can't find more than one! */
#if ERROR_CHECK

	    EC_ERROR_IF(found,-1);
#endif

	    /* A breakpoint already exists at this line..
	       Well, we never want more than one breakpoint
	       at the same spot, so we'll keep one.

	       What do we do about flags?

	       Right now, (1/18/95) a breakpoint is either
	       normal or onetime.  Current policy is that
	       normal always takes precedence.  This should
	       get more sophisticated as more flags are added...
	     */

	    if (bpPtr->BBP_breakFlags != BBF_NORMAL) {
		bpPtr->BBP_breakFlags = breakFlags;
	    }

	    /* this maybe the first time the breakpoint actually got put
	     * into the code, so grab the value of the code that was there
	     * and stuff in the offset
	     */
	    if (tbp.BBP_insn != OP_BREAK) {
		bpPtr->BBP_insn = tbp.BBP_insn;
	    }

	    /* if the offsets are different but neither one is NULL_OFFSET
	     * something is wrong
	     */
	    EC_ERROR_IF((offset != bpPtr->BBP_offset) &&
			(offset != NULL_OFFSET) &&
			(bpPtr->BBP_offset != NULL_OFFSET), -1);

	    if (offset != NULL_OFFSET) {
		bpPtr->BBP_offset = offset;
	    }
	    found = TRUE;
	}
#ifdef LIBERTY
	b->BIH_breakArray->UnlockElement(i);
#endif
    }

    if (!found) 
    {
#ifdef LIBERTY
	bpPtr =  (BugBreakPoint *)b->BIH_breakArray->Append();
#else
	bpPtr  = ChunkArrayAppend(breakArray,NULL);
#endif
	*bpPtr = tbp;
#ifdef LIBERTY
	b->BIH_breakArray->UnlockElement(ARRAY_END);
#endif
    }

    MemUnlock(bugHandle);
}

/*********************************************************************
 *                      BugClearBreakAtOffset
 *********************************************************************
 * SYNOPSIS:    If a breakpoint exists with this offset,
 *              remove it from the break list and restore
 *              the code...
 * CALLED BY:   INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/18/95        Initial version                      
 * 
 *********************************************************************/
void BugClearBreakAtOffset(MemHandle bugHandle, word funcNumber, word offset) 
{
#ifndef LIBERTY
    optr breakArray;
    word dummy;
#endif
    BugInfoHeader *b;
    int numBreaks, i;
    BugBreakPoint tbp, *tbpp;
    byte *code;
    RunFastFTabEntry *rfte;

#ifndef LIBERTY
    word   oldDS = setDSToDgroup();
#endif

    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);

#ifdef LIBERTY
    numBreaks = b->BIH_breakArray->GetCount();
#else
    breakArray = ConstructOptr(bugHandle, b->BIH_breakArray);

    numBreaks = ChunkArrayGetCount(breakArray);
#endif

    for (i = numBreaks - 1; i >= 0; i--)
    {
#ifdef LIBERTY
	tbpp = (BugBreakPoint *)b->BIH_breakArray->LockElement(i);
	tbp = *tbpp;
        b->BIH_breakArray->UnlockElement(i);
#else
	ChunkArrayGetElement(breakArray, i, &tbp);
#endif

	if (tbp.BBP_offset == offset &&
	    tbp.BBP_funcNumber == funcNumber)
	{

	    if (b->BIH_runTaskHan != NullHandle) 
	    {
	    /* Put its code back...
	     * Find the correct spot in the code..
	     * Only do this if possible at run time.*/
		RunTask *rtask = (RunTask *)MemLock(b->BIH_runTaskHan);
		EC_BOUNDS(rtask);

		
		FUNTAB_LOCK_TABLE_ENTRY(rtask->RT_funTabInfo,rfte,funcNumber);
#ifdef LIBERTY
	        code = (byte*)CheckLock(rfte->RFFTE_codeHandle + ((offset&0xf000)>>12));
#else
		HugeArrayLock(rtask->RT_vmFile, rtask->RT_funTabInfo.FTI_code,
			      rfte->RFFTE_codeHandle + ((offset&0xf000)>>12),
			      (void**)&code, &dummy);
#endif

		EC_BOUNDS(&code[offset&0x0fff]);
		code[offset & 0x0fff] = tbp.BBP_insn;
#ifndef LIBERTY
		HugeArrayDirty(code);

		HugeArrayUnlock(code);
#endif
		
		FUNTAB_UNLOCK_TABLE_ENTRY(rtask->RT_funTabInfo, rfte);
		
		MemUnlock(b->BIH_runTaskHan);
#ifdef LIBERTY
		b->BIH_breakArray->Delete(i);
#else
		ChunkArrayDeleteRange(breakArray,i, 1);
#endif
	    }
	    else
	    {
		BugBreakPoint	*tbpPtr;

#ifdef LIBERTY
		tbpPtr = (BugBreakPoint *)b->BIH_breakArray->LockElement(i);
#else
		tbpPtr = ChunkArrayElementToPtr(breakArray, (word)i, &dummy);
#endif
		tbpPtr->BBP_breakFlags = BBF_DELETED;
	    }
	    break;
	}
    }

    MemUnlock(bugHandle);
#ifndef LIBERTY
    restoreDS(oldDS);
#endif
}
	    
/* ---------------------------------------------- */
/* BREAKPOINTS                                    */
/* ---------------------------------------------- */


/*********************************************************************
 *			BugSetAllBreaks
 *********************************************************************
 * SYNOPSIS:	Sets all the breakpoints for a given module
 * CALLED BY:	external, after compiled code has been packed
 *              into runtime format
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *             This takes the place of BugSetBreaksForFunction;
 *             since all code is repacked for any recompilation,
 *             we just activate all breakpoints..
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 5/23/95	Initial version
 * 
 *********************************************************************/
#ifndef LIBERTY
void BugSetAllBreaks(MemHandle bugHandle) 
{
    BugInfoHeader   *b;
    int             numBreaks, i;
    BugBreakPoint   tbp;
    optr    	    breakArray;
#ifdef LIBERTY
    BugBreakPoint   *tbpp;
#endif

    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);

#ifdef LIBERTY
    numBreaks = b->BIH_breakArray->GetCount();
#else
    breakArray = ConstructOptr(bugHandle, b->BIH_breakArray);
    numBreaks = ChunkArrayGetCount(breakArray);
#endif
    
    for (i = numBreaks-1; i >= 0; i--)
    {
#ifdef LIBERTY
	tbpp = (BugBreakPoint *)b->BIH_breakArray->LockElement(i);
	tbp = *tbpp;
        b->BIH_breakArray->UnlockElement(i);
#else
	ChunkArrayGetElement(breakArray, i, &tbp);
#endif
	if (tbp.BBP_breakFlags == BBF_DELETED)
	{
	    BugClearBreakAtOffset(bugHandle, tbp.BBP_funcNumber,
				  tbp.BBP_offset);
	}
    }

#ifdef LIBERTY
    numBreaks = b->BIH_breakArray->GetCount();
#else
    numBreaks = ChunkArrayGetCount(breakArray);
#endif
    for (i = 0; i < numBreaks; i++)
    {
#ifdef LIBERTY
	tbpp = (BugBreakPoint *)b->BIH_breakArray->LockElement(i);
	tbp = *tbpp;
        b->BIH_breakArray->UnlockElement(i);
#else
	ChunkArrayGetElement(breakArray, i, &tbp);
	tbp.BBP_offset = BugLineNumToOffset(bugHandle, tbp.BBP_funcNumber,
					    tbp.BBP_lineNum);
#endif
	BugSetBreakAtOffset(bugHandle, tbp.BBP_funcNumber, tbp.BBP_offset,
			    tbp.BBP_lineNum, tbp.BBP_breakFlags);
    }

    MemUnlock(bugHandle);
}
#endif
/*********************************************************************
 *			BugDeleteBreaksForFunction
 *********************************************************************
 * SYNOPSIS:	delete all breakpoints for a given function
 * CALLED BY:	GLOBAL
 * RETURN:  	nothing
 * SIDE EFFECTS:    breakpoints set
 * STRATEGY:	run through the list looking for relavent breakpoints
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 4/ 5/95	Initial version			     
 * 
 *********************************************************************/
#ifndef LIBERTY
void BugDeleteBreaksForFunction(MemHandle bugHandle, word funcNumber)
{
    BugInfoHeader   *b;
    int    	    numBreaks, i;
    BugBreakPoint   tbp;
    optr    	    breakArray;
    word oldDS;

    oldDS = setDSToDgroup();


    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);

    breakArray = ConstructOptr(bugHandle, b->BIH_breakArray);
    numBreaks = ChunkArrayGetCount(breakArray);

    /* loop backwards since we will be removing elements from the list */
    for (i = numBreaks-1; i >= 0; i--)
    {
	ChunkArrayGetElement(breakArray, i, &tbp);
	if (tbp.BBP_funcNumber == funcNumber) 
	{
	    BugClearBreakAtLine(bugHandle, funcNumber, tbp.BBP_lineNum);
	}
    }
    MemUnlock(bugHandle);
    restoreDS(oldDS);
}
#endif


/*********************************************************************
 *			BugUpdateBreaksForDeletedFunction
 *********************************************************************
 * SYNOPSIS:	update function numbers for breaks
 * CALLED BY:	GLOBAL
 * RETURN:  	nothing
 * SIDE EFFECTS:    offsets of breakpoints updated
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 4/ 5/95	Initial version			     
 * 
 *********************************************************************/
#ifndef LIBERTY
void BugUpdateBreaksForDeletedFunction(MemHandle bugHandle, word funcNumber)
{
    BugInfoHeader *b;
    BugBreakPoint *tbp;
    word	dummy;
    int		numBreaks, i;
    optr	breakArray;
    word oldDS;

    oldDS = setDSToDgroup();


    b = (BugInfoHeader*) MemLock(bugHandle);
    breakArray = ConstructOptr(bugHandle, b->BIH_breakArray);
    numBreaks = ChunkArrayGetCount(breakArray);

    /* loop backwards since we will be removing elements from the list */
    for (i = numBreaks-1; i >= 0; i--)
    {
	tbp = ChunkArrayElementToPtr(breakArray, (word)i, &dummy);
	if (tbp->BBP_funcNumber == funcNumber) 
	{
	    tbp->BBP_funcNumber = -1;
	}
	else if (tbp->BBP_funcNumber > funcNumber) 
	{
	    tbp->BBP_funcNumber--;
	}
    }
    MemUnlock(bugHandle);
    restoreDS(oldDS);
}
#endif




/*********************************************************************
 *                      BugSetBreakAtLine
 *********************************************************************
 * SYNOPSIS:    Set a breakpoint at the specified function, line number.
 * CALLED BY:   Editor?
 * RETURN:      True if successful, else False, which should occur
 *              when the specified line doesn't correspond to any
 *              breakable code, like a REM or whitespace.
 *
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/17/95        Initial version                      
 * 
 *********************************************************************/
#ifndef LIBERTY
Boolean
BugSetBreakAtLine(MemHandle bugHandle, word funcNumber, word lineNum) 
{
    word offset;
    word   oldDS;

    oldDS = setDSToDgroup();

    BugSetBreakAtOffset(bugHandle, funcNumber, NULL_OFFSET, 
			lineNum, BBF_NORMAL);

    restoreDS(oldDS);
    return TRUE;
}
#endif

/*********************************************************************
 *                      BugSetOneTimeBreakAtLine
 *********************************************************************
 * SYNOPSIS:    Sets a breakpoint which gets cleared as soon as it's
 *              hit. Should be useful for single stepping, finishing,
 *              etc.
 * CALLED BY:   GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/19/95        Initial version                      
 * 
 *********************************************************************/
#ifndef LIBERTY
Boolean BugSetOneTimeBreakAtLine(MemHandle bugHandle, word funcNumber,
				 word lineNum) 
{
    word    	    offset;
    word    	    oldDS;
    BugBreakPoint   tbp;

    oldDS = setDSToDgroup();


    offset = BugLineNumToOffset(bugHandle, funcNumber, lineNum);

    /* since its a one time breakpoint, if there is already a breakpoint
     * there, don't bother setting another one
     */
    tbp = BugDoesBreakAtOffset(bugHandle, funcNumber, offset,
			       BBF_NORMAL | BBF_ONE_TIME);

    if (tbp.BBP_insn == OP_ILLEGAL) 
    {
	BugSetBreakAtOffset(bugHandle, funcNumber, offset, lineNum, 
			    BBF_ONE_TIME);
    }

    restoreDS(oldDS);
    return TRUE;
}
#endif

/*********************************************************************
 *                      BugSetOneTimeBreakAtOffset
 *********************************************************************
 * SYNOPSIS:    Sets a breakpoint which gets cleared as soon as it's
 *              hit. Should be useful for single stepping, finishing,
 *              etc.
 * CALLED BY:   GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/19/95        Initial version                      
 * 
 *********************************************************************/
Boolean BugSetOneTimeBreakAtOffset(MemHandle bugHandle, word funcNumber,
				   word lineNum, word offset) 
{
    BugBreakPoint   tbp;

#ifndef LIBERTY
    word    	    oldDS = setDSToDgroup();
#endif


    /* since its a one time breakpoint, if there is already a breakpoint
     * there, don't bother setting another one
     */
    tbp = BugDoesBreakAtOffset(bugHandle, funcNumber, offset,
			       BBF_NORMAL | BBF_ONE_TIME);

    if (tbp.BBP_insn == OP_ILLEGAL) 
    {
	BugSetBreakAtOffset(bugHandle, funcNumber, offset, lineNum, 
			    BBF_ONE_TIME);
    }

#ifndef LIBERTY
    restoreDS(oldDS);
#endif
    return TRUE;
}

/*********************************************************************
 *                      BugClearBreakAtLine
 *********************************************************************
 * SYNOPSIS:    Erases a breakpoint at a line of code. Does nothing
 *              if there isn't a breakpoint at that line..
 * CALLED BY:   
 * RETURN:      
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/17/95        Initial version                      
 * 
 *********************************************************************/
void
BugClearBreakAtLine(MemHandle bugHandle, word funcNumber, word lineNum) 
{
    int   	numBreaks, i;
    BugInfoHeader* b;
    BugBreakPoint tbp, *tbpp;

#ifndef LIBERTY
    optr	breakArray;
    word        oldDS = setDSToDgroup();
#endif

    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);

#ifdef LIBERTY
    numBreaks = b->BIH_breakArray->GetCount();
#else
    breakArray = ConstructOptr(bugHandle, b->BIH_breakArray);

    numBreaks = ChunkArrayGetCount(breakArray);
#endif

    for (i = numBreaks-1; i >= 0; i--) 
    {
#ifdef LIBERTY
	tbpp = (BugBreakPoint *)b->BIH_breakArray->LockElement(i);
	tbp = *tbpp;
        b->BIH_breakArray->UnlockElement(i);
#else
	ChunkArrayGetElement(breakArray, i, &tbp);
#endif

	if (tbp.BBP_lineNum == lineNum &&
	    tbp.BBP_funcNumber == funcNumber) 
	{

	    /* if the offset is NULL_OFFSET, it never actually got stuck
	     * in the code, so just nuke it from the break list, else
	     * use the offset to restore the code and nuke it
	     */
	    if (tbp.BBP_offset == NULL_OFFSET) {
#ifdef LIBERTY
		b->BIH_breakArray->Delete(i);
#else
		ChunkArrayDeleteRange(breakArray,i, 1);
#endif
	    } else {
		BugClearBreakAtOffset(bugHandle, funcNumber, tbp.BBP_offset);
	    }
	    break;
	}
    }

    MemUnlock(bugHandle);

#ifndef LIBERTY
    restoreDS(oldDS);
#endif
    return;
}


/*********************************************************************
 *                      BugToggleBreakAtLine
 *********************************************************************
 * SYNOPSIS:    Toggles a breakpoint
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/17/95        Initial version                      
 * 
 *********************************************************************/
#ifndef LIBERTY
Boolean BugToggleBreakAtLine(MemHandle bugHandle,
			     word funcNumber, 
			     word lineNum) 
{
    word offset;
    BugBreakPoint tbp;
    word   oldDS;

    oldDS = setDSToDgroup();


    /* No go if this doesn't match to a breakable offset */

    if ((offset = BugLineNumToOffset(bugHandle, funcNumber, 
				     lineNum)) == NULL_OFFSET) 
    {
	return FALSE;
    }

    /* Now check if there's a breakpoint here... */

    tbp = BugDoesBreakAtOffset(bugHandle, funcNumber, offset, BBF_NORMAL);

    if (tbp.BBP_insn != OP_ILLEGAL) 
    {
	/* Not the most efficient approach, since
	   we have to traverse the break list when we know
	   its index is breakIndex, but who cares
	   about speed right here.. And anyway, 
	   there will never be that many breakpoints...
	*/
	BugClearBreakAtOffset(bugHandle, funcNumber, offset);
    }
    else 
    {
	/* No break here, add a new one. */

	BugSetBreakAtOffset(bugHandle, funcNumber, offset, lineNum, BBF_NORMAL);

    }

    restoreDS(oldDS);
    return TRUE;
}
#endif


/*********************************************************************
 *                      BugGetBreakAtOffset
 *********************************************************************
 * SYNOPSIS:    Check to see if a breakpoint with at least one of
 *              the compareFlags as
 *              its flags exists at the given routine/offset pair.
 * 
 *              Typical use of the flags is to be able to ignore
 *              one-time breakpoints--in some cases the user
 *              might not want to know about them..
 *
 *              As we add more flags, I'll add more sophisticated filters
 *              if necessary...
 *
 * CALLED BY:   EXTERNAL
 * RETURN:      Returns the actual breakpoint that
 *              has been displaced if it does exist...
 *              Otherwise it a breakpoint whose instruction is OP_ILLEGAL.
 *
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/18/95        Initial version                      
 * 
 *********************************************************************/

BugBreakPoint BugDoesBreakAtOffset(MemHandle bugHandle, 
				   word funcNumber, 
				   word offset,
				   BugBreakFlags compareFlags) 
{
#ifndef LIBERTY
    optr breakArray;
#endif
    BugInfoHeader *b;
    int numBreaks, i;
    BugBreakPoint tbp, *tbpp, bpToReturn;
#if ERROR_CHECK
    Boolean found = FALSE;
#endif

#ifndef LIBERTY
    word   oldDS = setDSToDgroup();
#endif


    bpToReturn.BBP_insn = OP_ILLEGAL;
    b = (BugInfoHeader*) MemLock(bugHandle);
    EC_BOUNDS(b);

#ifndef LIBERTY
    breakArray = ConstructOptr(bugHandle, b->BIH_breakArray);
#endif


#ifdef LIBERTY
    numBreaks = b->BIH_breakArray->GetCount();
#else
    numBreaks = ChunkArrayGetCount(breakArray);
#endif


    for (i = 0; i < numBreaks; i++) 
    {
#ifdef LIBERTY
	tbpp = (BugBreakPoint *)b->BIH_breakArray->LockElement(i);
	tbp = *tbpp;
        b->BIH_breakArray->UnlockElement(i);
#else
	ChunkArrayGetElement(breakArray, i, &tbp);
#endif

	if (tbp.BBP_offset == offset &&
	    tbp.BBP_funcNumber == funcNumber &&
	    (tbp.BBP_breakFlags | compareFlags)) 
	{

	    /* Got it! */
#if ERROR_CHECK

	    /* Choke if we''re already found it.. */
	    EC_ERROR_IF(found,-1);
	    found = TRUE;
#endif
	    bpToReturn = tbp;


	}
    }

    MemUnlock(bugHandle);

#ifndef LIBERTY
    restoreDS(oldDS);
#endif

    return bpToReturn;
}


	
/* --------------------------------------------- */
/* CALL STACK                                    */
/* --------------------------------------------- */

/*********************************************************************
 *                      BugGetCurrentFrame
 *********************************************************************
 * SYNOPSIS:    Returns the 0-based index of the current frame.
 *              Returns -1 if there are no active frames...
 *              Number of active frames equals result from here + 1.
 * CALLED BY:   GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Go backwards through the context blocks on the stack.
 *      This FIRST one is taken from the program task, hence it
 *      MUST be synchronized correctly before being called...
 * BUGS:
 *	Should take PTaskHan instead of RTaskHan
 *	What do we do here for nested breakpoints??
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/19/95        Initial version                      
 * 
 *********************************************************************/
word
BugGetCurrentFrame(PTaskHan ptaskHan)
{
    PTaskPtr	ptask;

    int		count;
    BugFrameContext bfc;
    
    ptask = (PTaskPtr)MemLock(ptaskHan);
    ASSERT(ptask->PT_cookie == PTASK_COOKIE);

    /* this should be more reliable than checking the stack pointer
     * to determine whether we are actually running or not as
     * the only state that indicates an active stack that would be
     * safe to look at is BS_PAUSED, although if a request is pending
     * then we need to let this through, unless its a HALT request since
     * a HALT means we are stopping, not pausing
     * 
     */
    ;{
	RunTask*	rtask;
	BugInfoHeader*	bih;
	
	if (ptask->PT_bugHandle == NullHandle) {
	    MemUnlock(ptaskHan);
	    return (word)-1;
	}
	bih = (BugInfoHeader*)MemLock(ptask->PT_bugHandle);
	rtask = (RunTask*)MemLock(ptask->PT_bugModule);
	if (bih->BIH_builderState != BS_PAUSED &&
	    (rtask->RT_builderRequest == BBR_NONE ||
	     rtask->RT_builderRequest == BBR_HALT))
	{
	    MemUnlock(ptask->PT_bugHandle);
	    MemUnlock(rtask->RT_handle);
	    MemUnlock(ptaskHan);
	    return (word)-1;
	}
	MemUnlock(rtask->RT_handle);
	MemUnlock(ptask->PT_bugHandle);
    }

    /* Now that we know we're actually running (sigh), do the real
     * work of looking through the stack
     */
    bfc.typeStack = (byte*)MemLock(ptask->PT_stack);
    bfc.dataStack = (dword*)(bfc.typeStack + ptask->PT_stackLength);
    ASSERT_ALIGNED(bfc.dataStack);
    
    /* if we have a 0xcccc module in the ptask FrameContext then we are
     * not actually running code, thus there is no current frame
     */
    count = 0;
    bfc.context = &ptask->PT_context;
/*    if ((bfc.context->FC_module & 0xffff) != 0xcccc) {*/
/*	for (; !(bfc.context->FC_vpc & VPC_RETURN); count++)*/
	for (; (bfc.context->FC_module & 0xffff) != 0xcccc; count++)
	{
	    Bug_GetPreviousContext(&bfc);
	    /* check for infinite loop */
	    if (count > 1000) {
		count = -1;
		break;
	    }
	}
/*    }*/
    /* The context with VPC_RETURN doesn't count -- it contains the state
     * the interp was in before the current invocation */
    count--;

    MemUnlock(ptask->PT_stack);
    MemUnlock(ptask->PT_handle);
    return count;
}


/*********************************************************************
 *			BugGetCurrentFrameFromRML
 *********************************************************************
 * SYNOPSIS:	Specialized version of BugGetCurrentFrame to
 *              be called from within RunMainLoop--it makes sure
 *              that the context block is correct (i.e. vbp is right!)
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:     Assume that ptask, rtask etc, are all locked down.
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 5/17/95	Initial version
 * 
 *********************************************************************/
word BugGetCurrentFrameFromRML(RMLPtr rms) 
{
    EC_BOUNDS(rms->ptask);
    EC_BOUNDS(rms->rtask);
    rms->ptask->PT_context.FC_vbpType = rms->bpType - rms->typeStack;
    rms->ptask->PT_context.FC_vbpData = rms->bpData - rms->dataStack;
    return BugGetCurrentFrame(rms->ptask->PT_handle);
}


/*********************************************************************
 *                      BugGetFrameInfo
 *********************************************************************
 * SYNOPSIS:	Check if a frame has debugging info, and return the func #
 * CALLED BY:   GLOBAL
 * RETURN:	TRUE if frame's module has debugging info
 * SIDE EFFECTS:
 * STRATEGY:
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/24/95        Initial version                      
 * 
 *********************************************************************/
Boolean
BugGetFrameInfo(PTaskHan ptaskHan, word frame, word *funcNum)
{
    FrameContext context;
    PTaskPtr	ptask;
    Boolean	retval;
 
    context = Bug_GetNthContext(ptaskHan, frame);
    *funcNum =  BugGetFuncFromContext(&context);

    ptask = (PTaskPtr)MemLock(ptaskHan);
    retval = (Boolean)(context.FC_module == ptask->PT_bugModule);
    MemUnlock(ptaskHan);

    return retval;
}

/*********************************************************************
 *			Bug_GetNthContext
 *********************************************************************
 * SYNOPSIS:	Return the <frame>th FrameContext, the base frame being 0
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	frame can be anywhere within [0, current_frame]
 *	The top is current_frame
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/11/95	Initial version
 * 
 *********************************************************************/
FrameContext
Bug_GetNthContext(PTaskHan ptaskHan, word destFrame)
{
    FrameContext context;
    PTaskPtr	ptask;
    word	curFrame;
    BugFrameContext	bfc;

    ptask = (PTaskPtr)MemLock(ptaskHan);
    ASSERT(ptask->PT_cookie == PTASK_COOKIE);

    curFrame = BugGetCurrentFrame(ptask->PT_handle);
    ASSERT(destFrame <= curFrame);

    bfc.typeStack = (byte*)MemLock(ptask->PT_stack);
    bfc.dataStack = (dword*)(bfc.typeStack + ptask->PT_stackLength);
    ASSERT_ALIGNED(bfc.dataStack);
    bfc.context = &ptask->PT_context;

    while (destFrame < curFrame) {
	Bug_GetPreviousContext(&bfc);
	curFrame--;
    }
    context = *bfc.context;
    EC(ECCheckFrameContext(&context));
    
    MemUnlock(ptask->PT_stack);
    MemUnlock(ptask->PT_handle);

    return context;
}

/*********************************************************************
 *                      BugGetFrameName
 *********************************************************************
 * SYNOPSIS:    Write the name of the routine for the given frame
 *              into dest.  Assume dest has enough pre-allocated
 *              space to safely handle this...
 * CALLED BY:   GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/26/95        Initial version                      
 * 
 *********************************************************************/
extern TCHAR* Fido_GetML(FTaskHan, ModuleToken);
void
BugGetFrameName(MemHandle ptaskHan, word frame, TCHAR *dest)
{
    RunTask	*rtask;
    TCHAR	*name;
    FrameContext context;
    word	funcNum;

    context = Bug_GetNthContext(ptaskHan, frame);
#ifndef LIBERTY
    if (context.FC_module == 0) {
	/* this happens when you call a void aggregate action as a
	 * function 
	 */
	dest[0] = 0;
	return;
    }
#endif
    funcNum = BugGetFuncFromContext(&context);

    rtask = (RunTask *)MemLock(context.FC_module);
    ASSERT(rtask->RT_cookie == RTASK_COOKIE);

#ifdef LIBERTY
    CheckLock(rtask->RT_stringFuncTable);
    name = SSTDeref(rtask->RT_stringFuncTable, funcNum, rtask->RT_stringFuncCount);
#else
    MemLock(rtask->RT_sstBlock);
    name = SSTDeref(rtask->RT_stringFuncTable, funcNum);
#endif

    strcpy(dest, name);

    /* If not the current debugged module, indicate what module it is */
    if (rtask->RT_bugHandle == NullHandle)
    {
	TCHAR*	module_locator;
	PTaskPtr	ptask;
	SET_DS_TO_DGROUP;

	ptask = (PTaskPtr)MemLock(ptaskHan);
	USE_IT(ptask);
	GONLY((void)MemLock(ptask->PT_fidoTask));

	strcat(dest, _TEXT(" in "));
	module_locator = Fido_GetML(ptask->PT_fidoTask, rtask->RT_fidoModule);
	strcat(dest, module_locator);
	LONLY(free(module_locator));

	GONLY(MemUnlock(ptask->PT_fidoTask));
	MemUnlock(ptaskHan);
	RESTORE_DS;
    }
 
#ifdef LIBERTY
    CheckUnlock(rtask->RT_stringFuncTable);
#else
    MemUnlock(rtask->RT_sstBlock);
#endif
    MemUnlock(context.FC_module);
}

/*********************************************************************
 *                      BugGetFrameLineNumber
 *********************************************************************
 * SYNOPSIS:    Get line number for frame
 * CALLED BY:   GLOBAL
 * RETURN:	line number, 0 if frame has no debug info
 * SIDE EFFECTS:
 * STRATEGY:    If it's the current frame, we check the cache
 *              in the bug info, and it will return one of two
 *              things.  If called after a breakpoint halt,
 *              it gives the line number of the line we are about
 *              to execute. Otherwise, it will be after a halt due to
 *              an error, 
 *              so we give the line we were executing when the halt
 *              occurred.
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/26/95        Initial version                      
 * 
 *********************************************************************/
word
BugGetFrameLineNumber(PTaskHan ptaskHan, word frame)
{
    word	funcNum;
    Boolean	isDebugged;
    FrameContext fc;

    RTaskHan	rtaskHan;
    RunTask	*rtask;
    sword	line;
    
    /* Just punt if we know there's no line # info */
    isDebugged = BugGetFrameInfo(ptaskHan, frame, &funcNum);
    if (!isDebugged) return 0;

    fc = Bug_GetNthContext(ptaskHan, frame);
    rtaskHan = fc.FC_module;
    rtask = (RunTask *)MemLock(rtaskHan);
    ASSERT(rtask->RT_cookie == RTASK_COOKIE);

    if (frame == BugGetCurrentFrame(ptaskHan)) 
    {
	BugInfoHeader *b;
	b = (BugInfoHeader*) MemLock(rtask->RT_bugHandle);
	EC_BOUNDS(b);
	line = b->BIH_breakLine;
	MemUnlock(rtask->RT_bugHandle);
    } else {
	word	vpc;
#ifndef LIBERTY
	byte	start;
#endif

	vpc = fc.FC_vpc & ~VPC_RETURN; /* might have the return bit set */
#ifndef LIBERTY
	line = BugOffsetToLineNum(rtask->RT_bugHandle, funcNum,
				  vpc-1, &start);
	ASSERT(line >= 0);
#else
	/* Slight hack; a negative number is interpreted by the debugger
	 * as an offset instead of a line number; processing the offset
	 * into a line number can go on at the other end */
	ASSERT(vpc-1 >= 0);
	line = -(vpc-1);
#endif
    }
    MemUnlock(rtaskHan);
    return line;
}

/*********************************************************************
 *			BugDeleteAllBreaks
 *********************************************************************
 * SYNOPSIS:	get rid of all breakpoints from the breakArray
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 6/ 5/95	Initial version
 * 
 *********************************************************************/
#ifndef LIBERTY
void BugDeleteAllBreaks(MemHandle	bugHandle)
{
    BugInfoHeader   *b;
    ChunkHandle	    ca;

    b = (BugInfoHeader *)MemLock(bugHandle);
    LMemFree(ConstructOptr(bugHandle, b->BIH_breakArray));
    ca = ChunkArrayCreate(bugHandle, sizeof(BugBreakPoint), 0,0);
    b = (BugInfoHeader *)MemDeref(bugHandle);
    b->BIH_breakArray = ca;
    MemUnlock(bugHandle);
}
#endif



/*********************************************************************
 *			BugSetBuilderState
 *********************************************************************
 * SYNOPSIS:	set the builder state field in the bug handle
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	10/17/95	Initial version
 * 
 *********************************************************************/
void
BugSetBuilderState(MemHandle bugHandle, BuilderState state)
{
    BugInfoHeader   *b;

    b = (BugInfoHeader *)MemLock(bugHandle);
    b->BIH_builderState = state;
    MemUnlock(bugHandle);
}



/*********************************************************************
 *			BugGetBuilderState
 *********************************************************************
 * SYNOPSIS:	get the builder state field in the bug handle
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	10/17/95	Initial version
 * 
 *********************************************************************/
BuilderState BugGetBuilderState(MemHandle bugHandle)
{
    BugInfoHeader   *b;
    BuilderState    state;

    b = (BugInfoHeader *)MemLock(bugHandle);
    state = b->BIH_builderState;
    MemUnlock(bugHandle);
    return state;
}


/*********************************************************************
 *			BugSetNumHiddenFuncs
 *********************************************************************
 * SYNOPSIS:	set number of hidden functions in bug handle
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/29/95	Initial version
 * 
 *********************************************************************/
void BugSetNumHiddenFuncs(MemHandle	bugHandle, word numHiddenFuncs)
{
    BugInfoHeader   *b;

    b = (BugInfoHeader *)MemLock(bugHandle);
    b->BIH_numHiddenFuncs = numHiddenFuncs;
    MemUnlock(bugHandle);
}


/*********************************************************************
 *			BugGetNumVars
 *********************************************************************
 * SYNOPSIS:	Find the size of a stack or global scope
 * CALLED BY:	GLOBAL
 * RETURN:	# elements in that scope
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	8/23/96  	Initial version
 * 
 *********************************************************************/
word
BugGetNumVars(PTaskHan ptaskHan, word frame)
{
    word	size;
    byte*	byteDummy;
    dword*	dwordDummy;
    MemHandle	toUnlock;

    Bug_FindScope(ptaskHan, frame, &toUnlock, &size, &byteDummy, &dwordDummy);
    if (toUnlock) MemUnlock(toUnlock);
    return size;
}

/*********************************************************************
 *                      BugGetSetVar
 *********************************************************************
 * SYNOPSIS:    Returns the data for the variable of index varIndex
 *              in the frameNumber frame on the call stack OR
 *              from the module level variables if MODULE_LEVEL
 *              is supplied as the frame number.
 * CALLED BY:   GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/24/95        Initial version
 *	dubois	6/15/96  	Rewritten for new storage implementation
 * 
 *********************************************************************/
BugVar
BugGetSetVar(PTaskHan ptaskHan,
	       sword frame, word varIndex,
	       BugVar sVar, Boolean set) 
{
    BugVar	bv;
    PTaskPtr	ptask;

    byte*	typeScope;
    dword*	dataScope;
    MemHandle	scopeHan;
    word	scopeSize;

    ptask = (PTaskPtr)MemLock(ptaskHan);
    ASSERT(ptask->PT_cookie == PTASK_COOKIE);

    Bug_FindScope(ptaskHan, frame,
		  &scopeHan, &scopeSize, &typeScope, &dataScope);

    /* Perform the get or set */
    if (varIndex >= scopeSize)
    {
	bv.BV_type = TYPE_ERROR;
	bv.BV_data = 0xcccccccc;
    }
    else if (set)
    {
	if (typeScope[varIndex] == sVar.BV_type)
	{
	    dataScope[varIndex] = sVar.BV_data;
	}
	else if (typeScope[varIndex] == TYPE_LONG &&
		 sVar.BV_type == TYPE_INTEGER) 
	{
	    dataScope[varIndex] = (sdword)(sword)sVar.BV_data;
	}
    } else {
	bv.BV_type = typeScope[varIndex];
	bv.BV_data = dataScope[varIndex];
    }

    /* Unlock and return */
    if (scopeHan) MemUnlock(scopeHan);
    MemUnlock(ptaskHan);
    return bv;
}

/*********************************************************************
 *			Bug_FindScope
 *********************************************************************
 * SYNOPSIS:	Common code -- find a stack frame or globals
 * CALLED BY:	INTERNAL
 * RETURN:	All return values zeroed out if scope not found
 *		This can happen of the global scope is empty
 *
 *		*toUnlock	MemUnlock this when done
 *		*sizeP		size of found scope
 *		*typePP		Points at type of found var
 *		*dataPP		Points at data of found var
 *
 * SIDE EFFECTS:
 * STRATEGY:
 *	Pass MODULE_LEVEL to look for a var in the global scope
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	8/23/96  	Initial version
 * 
 *********************************************************************/
void
Bug_FindScope(PTaskHan ptaskHan, sword frame,
	      MemHandle* toUnlock,
	      word*	sizeP,
	      byte**	typePP,
	      dword**	dataPP)
{
    PTaskPtr	ptask;

    ptask = (PTaskPtr)MemLock(ptaskHan);
    ASSERT(ptask->PT_cookie == PTASK_COOKIE);

    /* Lock down either the stack or the global segment
     * set up pointers to type and data areas
     */
    if (frame == MODULE_LEVEL) {
	RunTask*	rtask;

	rtask = (RunTask*)MemLock(ptask->PT_bugModule);
	*toUnlock = rtask->RT_moduleVars;
	MemUnlock(ptask->PT_bugModule);

	if (*toUnlock == NullHandle) {
	    *sizeP = 0;
	    *typePP = NULL;
	    *dataPP = NULL;
	} else {
	    LOCK_GLOBALS(*toUnlock, *typePP, *dataPP);
	    *sizeP = NUM_GLOBALS_FAST(*typePP);
	}
    } else {
	FrameContext	context;
	byte*	tmpTypes;

	*toUnlock = ptask->PT_stack;
	*typePP = (byte*)  MemLock(*toUnlock);
	*dataPP = (dword*) (*typePP + ptask->PT_stackLength);
	ASSERT_ALIGNED(*dataPP);

	context = Bug_GetNthContext(ptaskHan, frame);
	*typePP += context.FC_vbpType;
	*dataPP += context.FC_vbpData;

	/* Locals lie betwen bp and the frame context */
	tmpTypes = *typePP; *sizeP = 0;
	while (*tmpTypes != TYPE_FRAME_CONTEXT) {
	    (*sizeP)++;
	    tmpTypes++;
	}
    }

    MemUnlock(ptaskHan);
    return;
}

#if 0
/*********************************************************************
 *			BugGetArrayElement
 *********************************************************************
 * SYNOPSIS:	get an array element
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 7/ 5/95	Initial version
 * 
 *********************************************************************/
BugVar
BugGetSetArrayElement(MemHandle rtaskHan, word frameNumber, word varNum,
                      word element, BugVar sVar, Boolean set)
{
    ArrayHeader	*ah;
    RunTask 	*rtask;
    BugVar  	bv, ev;
    

    rtask = (RunTask *)MemLock(rtaskHan);
    EC_ERROR_IF(rtask->RT_cookie != RTASK_COOKIE, RE_BAD_RTASK);

    bv = BugGetSetVar(rtaskHan, frameNumber, varNum, bv, GET_VAR);
    EC_ERROR_IF(bv.BV_type != TYPE_ARRAY, -1);
    ah = MemLock(bv.BV_data);
    EC_BOUNDS(ah);
    EC_ERROR_IF(element >= ah->maxElt, BE_FAILED_ASSERTION);

    ev.BV_type = ah->type;

    ah++;


    switch (ev.BV_type) {
    case TYPE_STRING:
    case TYPE_COMPLEX:
    case TYPE_STRUCT:

    case TYPE_INTEGER:
    case TYPE_MODULE:
	if (set) {
	    if (ev.BV_type == sVar.BV_type) {
		*(word *)(((word *)ah)+element) = sVar.BV_data;
	    }
	} else {
	    ev.BV_data = *(word *)(((word *)ah)+element);
	}
	break;
    case TYPE_LONG:
    case TYPE_FLOAT:
    case TYPE_COMPONENT:
	if (set) {
	    if (ev.BV_type == sVar.BV_type) {
#ifdef LIBERTY
		memcpy((((dword *)ah)+element), &(sVar.BV_data), sizeof(dword));
#else
		*(dword *)(((dword *)ah)+element) = sVar.BV_data;
#endif
	    } else 
	    if (ev.BV_type == TYPE_LONG &&
		sVar.BV_type == TYPE_INTEGER)
	    {
#ifdef LIBERTY
		 sdword tmp;
	         tmp = (sword)sVar.BV_data;
		 memcpy((((sdword *)ah)+element), &tmp, sizeof(sdword));
#else
		*((sdword*)(((sdword *)ah)+element)) = (sword)sVar.BV_data;
#endif
	    }
	} else {
#ifdef LIBERTY
	    memcpy(&(ev.BV_data), (((dword *)ah)+element), sizeof(dword));
#else
	    ev.BV_data = *(dword *)(((dword *)ah)+element);
#endif
	}

	break;
#if ERROR_CHECK
    default:
	EC_ERROR(BE_FAILED_ASSERTION);
#endif
    }
    
    MemUnlock(bv.BV_data);
    MemUnlock(rtaskHan);
    return ev;
}
#endif

#if 0
/*********************************************************************
 *			BugGetArrayDims
 *********************************************************************
 * SYNOPSIS:	get the number of elements in an array
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 7/ 5/95	Initial version
 * 
 *********************************************************************/
word BugGetArrayDims(MemHandle rtaskHan, word frameNumber, word varNum, 
		    word dims[])
{
    ArrayHeader	*ah;
    RunTask 	*rtask;
    word	    	numDims, i;
    BugVar  	bv;

    rtask = (RunTask *)MemLock(rtaskHan);
    EC_ERROR_IF(rtask->RT_cookie != RTASK_COOKIE, RE_BAD_RTASK);

    bv = BugGetSetVar(rtaskHan, frameNumber, varNum, bv, GET_VAR);
    EC_ERROR_IF(bv.BV_type != TYPE_ARRAY, -1);
    ah = MemLock(bv.BV_data);
    EC_BOUNDS(ah);
    numDims = ah->numDims;
    for (i = 0; i < numDims; i++)
    {
	EC_BOUNDS(&(dims[i]));
	dims[i] = ah->dims[i];
    }
    MemUnlock(bv.BV_data);
    MemUnlock(rtaskHan);
    return numDims;
}
#endif

/*********************************************************************
 *		      BugGetString
 *********************************************************************
 * SYNOPSIS:	Fill in a character buffer with a string constant
 *              if maxLen is 0, copy entire string.
 *              Otherwise, copy over maxLen bytes followed by a null
 *              terminator.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/16/95	Initial version			     
 * 
 *********************************************************************/
void 
BugGetString(PTaskHan ptaskHan,
	     dword stringIndex,
	     TCHAR *dest,
	     word maxLen) 
{
    PTaskPtr	ptask;
    TCHAR    	*cp;

    ptask = (PTaskPtr)MemLock(ptaskHan);
    ASSERT(ptask->PT_cookie == PTASK_COOKIE);

    RunHeapLock(&(ptask->PT_runHeapInfo), stringIndex, (void **)(&cp));
    if (maxLen) {
	strncpy(dest, cp, maxLen);
    }
    else {
	strcpy(dest, cp);
    }
    RunHeapUnlock(&(ptask->PT_runHeapInfo), stringIndex);
    MemUnlock(ptaskHan);
}

/*********************************************************************
 *			BugCreateString
 *********************************************************************
 * SYNOPSIS:	Create a string on the runtime heap
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:DecRefs oldVar if necessary (what?!)
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/16/95	Initial version			     
 * 
 *********************************************************************/
BugVar
BugCreateString(PTaskHan ptaskHan, TCHAR *src, BugVar oldVar)
{
    PTaskPtr	    ptask;
    RunHeapToken    token;
    BugVar  	    bvar;

    ptask = (PTaskPtr) MemLock(ptaskHan);
    ASSERT(ptask->PT_cookie == PTASK_COOKIE);

    /* If we were passed in an oldVar, decrement the thing's reference
     * count 'cause we won't be needing it anymore.
     */
    if (oldVar.BV_type == TYPE_STRING) {
	RunHeapDecRef(&(ptask->PT_runHeapInfo), oldVar.BV_data);
    }

    token = RunHeapAlloc(&(ptask->PT_runHeapInfo), RHT_STRING, 1,
			 (strlen(src)+1)*sizeof(TCHAR), src);

    MemUnlock(ptaskHan);

    bvar.BV_type = TYPE_STRING;
    bvar.BV_data = token;
    return bvar;
}


