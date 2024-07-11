/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           debug.c

AUTHOR:         Jimmy Lefkowitz, Jun 29, 1995

ROUTINES:
	Name                    Description
	----                    -----------

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	jimmy    6/29/95        Initial version.

DESCRIPTION:
	debug related stuff from RunMain

	$Revision: 1.2 $
	$Id: debug.c,v 1.2 98/10/05 12:39:44 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
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
#include <Legos/rpc.h>
#else
#include "mystdapp.h"
#include <sem.h>
#include "runint.h"
#include "funtab.h"
#include "prog.h"
#include "runint.h"
#include <Legos/rpc.h>
#endif

#include <Legos/bug.h>
#include "bugext.h"


/*********************************************************************
 *                      BugRestoreFromBreakpoint
 *********************************************************************
 * SYNOPSIS:    deal with coming back from a breakpoint
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy    6/29/95        Initial version
 * 
 *********************************************************************/
Opcode BugRestoreFromBreakpoint(RMLPtr rms)
{
    Opcode  op;
    BugInfoHeader *b;

    b = (BugInfoHeader*) MemLock(rms->rtask->RT_bugHandle);
    EC_BOUNDS(b);
    
    /* This is the check we use to decide whether the last
       time we were in runmainloop we hit a breakpoint,
       (or breaked for any other reason like single stepping,
       routine finishing, etc.)
       */
    if (b->BIH_displacedInsn != OP_ILLEGAL)
    {
	op = b->BIH_displacedInsn;
	    
	/* Not sure what the hell this would mean; can't be good */
	EC_ERROR_IF(op == OP_BREAK, RE_FAILED_ASSERTION);
	b->BIH_displacedInsn = OP_ILLEGAL;

	MemUnlock(rms->rtask->RT_bugHandle);

	/* [ example ]
	   With this, we reenter the main execution loop because
	   op has been set correctly.  Note that it is very important
	   to skip over the portion which decides whether
	   we need to stop. We never want to break again under
	   any circumstances without first executing some code.
	   
	   Good example to keep in mind:

	   for i = 1 to 1000
	   next i

	   Single stepping should just keep stopping at next i.
	   If we just look to see we change line numbers or
	   functions we won't catch it. Instead we make no
	   such requirements, but stipulate that after a breakpoint,
	   we MUST execute some code (virtual machine code)
	   before stopping again.  By going to SWITCH, we skip
	   the check which would force us to break again immediately
	   on re-entry, and it won't be caught again until
	   the next iteration.
	*/
	return op;
    }


    /* the start message is finishMessage - 1 */
    RunSendMessage(b->BIH_destObject, b->BIH_finishMessage-1);
    (b->BIH_runMainLoopCount)++;
    MemUnlock(rms->rtask->RT_bugHandle);

    /* just return some value to let up know we didn't come back from
     * a break - this does not mean we have hit an error...
     */
    return OP_ILLEGAL;
}



/*********************************************************************
 *                      BugCheckForBreakpoint
 *********************************************************************
 * SYNOPSIS:    RunMainLoop check for breakpoints
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * [ Ways this loop can give up control ]
	   
	   1. Normal completion of a top-level call. Exit handled
	      when we process the OP_END{FUNCTION,PROCEDURE} opcodes.

	   2. RunTimeError - We should return as soon as we hit one.

	   3. Asynchronous Halt - The builder may request a halt.
	      Every time through the loop we check to see if this is
	      the case and quit if so.

	      Performance wise, each time through we need to check
	      one flag in the bugHandle. Oh well...

	   4. Breakpoint - These are stored in code as OP_BREAK,
	      and are found by the main runtime loop. We save some
	      information about how we stopped and then P a semaphore.


	   4b. Note that single stepping, routine stepping, etc.
	       are done by setting one-time breakpoints which are
	       caught as described in step 3.  We're doing a bit
	       more work than we need to because we already know
	       that we're going to stop right as set the breakpoint,
	       but it helps us reduce the different ways conceptually
	       which we can use to break. And speed isn't a big
	       issue at that point...

 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy    6/29/95        Initial version
 * 
 *********************************************************************/
Boolean BugCheckForBreakpoint(RMLPtr rms)
{
    BugInfoHeader *b;
    BugBuilderRequest bbr;
    byte    start;  /* is current offset start of line? */
    sword   cf;     /* current frame */
    sword   func;   /* function number */
    word    offset; /* code offset */


    EC_ERROR_IF(rms->rtask->RT_bugHandle == NullHandle, -1);
    /* By entering into this block we assume the builder
       is up and controlling the viewer thread.
     */
    start = 0;
    bbr = rms->rtask->RT_builderRequest;


    b = (BugInfoHeader*) MemLock(rms->rtask->RT_bugHandle);
    EC_BOUNDS(b);

    /* if we are in a different call to RunMainLoop - bag it unless its a
     * halt or suspend which stops no matter where we are
     */
    if (bbr != BBR_HALT && bbr != BBR_SUSPEND &&
	b->BIH_breakRunMainLoopCount != b->BIH_runMainLoopCount)
    {
	MemUnlock(rms->rtask->RT_bugHandle);
	return TRUE;
    }

    /* BBR_HALT is the easiest request thanks to our
     * nonrecursive design. Just unlock everything, update
     * our pointers, and return!
     */
    if (bbr == BBR_HALT) 
    {
	MemHandle   ptaskHan;
	ProgTask    *pt;

	ptaskHan = rms->rtask->RT_progTask;
	MemUnlock(rms->rtask->RT_bugHandle);

	RunCleanMain(rms);

	/* reset context to top level and reset PT_err to NONE */
	pt = (ProgTask *)MemLock(ptaskHan);
	pt->PT_context.FC_codeHandle = 0xcccc;
	pt->PT_context.FC_module = 0xcccc;
	pt->PT_err = RTE_NONE;
	MemUnlock(ptaskHan);
	return FALSE;

	/* [ We assume that a MSG_META_QUIT is now
	 * on our message queue, waiting to get processed.
	 *
	 * Don't clear the builder request just yet, just
	 * in case there are some left over messages on
	 * the queue from event handlers...  We use this
	 * flag to know not to do anything when we see
	 * them...
	 */

    }
    else if (bbr == BBR_ROUTINE_STEP &&
	     b->BIH_breakVbpUnreloc < rms->bpType - rms->typeStack)
    {
	/* quick reject for routine steps, we only stop if we are
	 * in the same frame were we when we started the routine step
	 * or in a lower frame if we returned to the caller
	 */
	goto done;
    }
    else if (bbr == BBR_FINISH &&
	     b->BIH_breakVbpUnreloc <= rms->bpType - rms->typeStack)
    {
	/* quick reject for finish, we only finish when we are in a
	 * "lower" frame in the stack, or a lower vbp 
	 */
	goto done;
    }

    /* [ The rest of the builder requests involve breaking
     * (a temporary suspension), depending on certain
     * circumstances--immediate, single stepping, routine
     * stepping, routine finishing.
     *
     * Note that standard breakpoints are NOT processed as
     * builder requests--OP_BREAK opcodes are plopped
     * directly in the code to avoid runtime hunting for
     * breaks.
     *
     * Before we break here, however, we need to make sure
     * it's a safe time. For all cases:
     *
     * We must be in the "main" module of our program,
     * since currently that's the only one we maintain 
     * debugging information for.
     
     * We must not be executing a hidden routine, since the
     * builder wont display the routine, bad things would happen
     
     * We must be at the beginning of a source line.
     * Allowing otherwise just adds needless confusion.
     */
    
    func = BugGetFuncFromContext(&(rms->ptask->PT_context));
    
    if (func >= b->BIH_numHiddenFuncs && 
	rms->rtask->RT_handle == b->BIH_runTaskHan)
    {
	sword   ln = 0;

	/* Start is true if current offset is the start of a line.
	 */
	cf = BugGetCurrentFrameFromRML(rms);
	
	/* [ tricky cases ]
	   
	   Consider code: x = a() + b()
	   x = x + 1
	   
	   Current convention is that a() gets called before b.
	   If we are at the bottom of routine a and choose
	   routine step, we should stop next at x=x+1, not
	   at b(), even though b() is at the same frame level
	   as a. The key is to note when our frame has dropped
	   below the breakFrame, even when we don't execute
	   an entire line.  So, for the case above, the
	   next line will catch the interpreter when
	   it temporarily returns to continue evaluating the
	   expression by calling b().
	   */
	
	if (bbr == BBR_ROUTINE_STEP && cf < b->BIH_breakFrame) {
	    b->BIH_breakFrame = cf;
	}
	
	/* Similarly, when we are processing a BBR_FINISH,
	   the opposite is true. We DO want to stop in b(),
	   even though it's the same level as a.  To do this,
	   just change request to BBR_SUSPEND as soon
	   as we get below the given stack level.
	   */
#if 0
	if (bbr == BBR_FINISH && cf < b->BIH_breakFrame) 
	{
	    bbr = BBR_SUSPEND;
	    rms->rtask->RT_builderRequest = BBR_SUSPEND;
	}
#endif              
	
#if !USES_SEGMENTS
	offset = (rms->pc - rms->code);
#else
	offset = (rms->pc - rms->code) |
	          ((rms->ptask->PT_context.FC_codeHandle -
		    rms->ptask->PT_context.FC_startSeg) << 12);
#endif
	if (rms->rtask->RT_flags & RT_REMOTE_DEBUGGING) {
	    RpcOffset2LineNumArgs    args;
	    RpcOffset2LineNumReply   reply;

#ifdef LIBERTY
	    args.ro2lna_funcNumber = ByteSwap(func);
	    args.ro2lna_offset = ByteSwap(offset);
	    BasrunRpcCall(b->BIH_connection, RPC_DEFAULT_TIMEOUT,
			  RPC_OFFSET_TO_LINE_NUM,
			  sizeof(RpcOffset2LineNumArgs), &args,
			  sizeof(RpcOffset2LineNumReply), &reply);
	    ln = ByteSwap(reply.ro2lnr_lineNum);
#else
	    BasrunRpcCall(SERIAL_COM1, RPC_DEFAULT_TIMEOUT,
			  RPC_OFFSET_TO_LINE_NUM,
			  sizeof(RpcOffset2LineNumArgs), &args,
			  sizeof(RpcOffset2LineNumReply), &reply);
#endif
	    start = reply.ro2lnr_start;
#ifndef LIBERTY
	} else {
	    ln = BugOffsetToLineNum (rms->rtask->RT_bugHandle, func,
				     offset, &start);
#endif
        }
	
	if (start && 
	    (
	     
	     (bbr == BBR_SUSPEND)
	     
	     ||
	     
	     (bbr == BBR_FINISH && cf < b->BIH_breakFrame)
	     
	     ||
	     
	     (bbr == BBR_SINGLE_STEP)
	     
	     ||
	     
	     (bbr == BBR_ROUTINE_STEP && cf <= b->BIH_breakFrame)
	     
	     )
	    
	    )
	{
	    
	    /* NOTE: We set this breakpoint which WILL
	       be caught as soon as we enter the main execution
	       loop. All the work above ensured that 
	       our current offset marks the beginning
	       of the specified line!
	       
	       It does a little extra work, but
	       we don't care about blazing speed right here.
	       */
	    
	    
	    BugSetOneTimeBreakAtOffset(rms->rtask->RT_bugHandle,
				       func, ln, offset);
	}
	
    } 
done:
    MemUnlock(rms->rtask->RT_bugHandle);
    return TRUE;
} /* end if rms->rtask->RT_builderRequest != BBR_NONE */







/*********************************************************************
 *                      OpBreak
 *********************************************************************
 * SYNOPSIS:    deal with hitting a breakpoint
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy    6/29/95        Initial version
 * 
 *********************************************************************/
void OpBreak(RMLPtr rms)
{
    BugInfoHeader*      b;
    BugBreakPoint       tbp;
    word                funcNum;
    SemaphoreHandle     sem;
    optr                destObject;
    word                destMessage;
    Boolean             remote;

    Run_UpdatePTask(rms);

    /* Shouldn't be breaking if we have no bugging info,
       if we're not in the main task
       */

    EC_ERROR_IF(rms->rtask->RT_bugHandle == NullHandle, -1);

    /* We've hit a breakpoint. */
    
    funcNum = BugGetFuncFromContext(&rms->ptask->PT_context);

    /* Figure out what instruction was displaced,
       and store it in the task.
       */

    /* This call checks for either a normal or a one-time
       breakpoint at this offset... 
       
       Don't forget to subtract one from VPC because
       we've already incremented VPC past the OP_BREAK... 
     */

#if !USES_SEGMENTS
    tbp = BugDoesBreakAtOffset(rms->rtask->RT_bugHandle,
			      funcNum,
			      (rms->pc - 1 - rms->code),
			      BBF_NORMAL | BBF_ONE_TIME);
#else
    tbp = BugDoesBreakAtOffset(rms->rtask->RT_bugHandle,
			      funcNum,
			      (rms->pc - 1 - rms->code) |
			      ((rms->ptask->PT_context.FC_codeHandle -
				rms->ptask->PT_context.FC_startSeg) << 12),
			      BBF_NORMAL | BBF_ONE_TIME);
#endif
	    /* A breakpoint had better exist here.... */

    EC_ERROR_IF(tbp.BBP_insn == OP_ILLEGAL, RE_FAILED_ASSERTION);
    /* Clear if a one-time break */

    if (tbp.BBP_breakFlags & BBF_ONE_TIME) {
	BugClearBreakAtLine(rms->rtask->RT_bugHandle, 
			    funcNum,
			    tbp.BBP_lineNum);
    }
    
    /* Keep track of the current displaced instruction */
    /* Need a stack if we allow nested breakpoints */

    b = (BugInfoHeader*) MemLock(rms->rtask->RT_bugHandle);

    /* NOTE, BS_PAUSED needs to be set before GetCurrentFrameFromRML is called
     * or it will return -1 in an attempt to be robust, sigh
     */
    b->BIH_builderState   = BS_PAUSED;

    b->BIH_displacedInsn  = tbp.BBP_insn;
    b->BIH_breakLine      = tbp.BBP_lineNum;
    b->BIH_breakFrame     = BugGetCurrentFrameFromRML(rms);
    b->BIH_breakFunc      = funcNum;
    b->BIH_runTaskHan	  = rms->rtask->RT_handle;

    /* save these for quick checking of frame in CheckForBreakpoint */
    b->BIH_breakVbpUnreloc = rms->bpType - rms->typeStack;
    b->BIH_breakRunMainLoopCount = b->BIH_runMainLoopCount;

    destObject = b->BIH_destObject;
    destMessage= b->BIH_destMessage;

    MemUnlock(rms->rtask->RT_bugHandle);
		
    BugSetSuspendStatus(rms->rtask->RT_bugHandle,BSS_BREAK);

    remote = (Boolean) (rms->rtask->RT_flags & RT_REMOTE_DEBUGGING);
    
    /* Need a real call to RunCleanMain here. */
    RunCleanMain(rms);
		
    RunSendMessage(destObject, destMessage);

    if (remote) {
	/*
	 * Handle whatever RPC requests the builder sends us here, until
	 * our status is something other than paused...
	 */
	RunSendMessage(destObject, destMessage + 1);
    } else {
#ifndef LIBERTY
	BugSitAndSpin(destMessage);
#endif
    }
}
