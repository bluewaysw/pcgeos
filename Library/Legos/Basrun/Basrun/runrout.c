/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Runtime
FILE:		runrout.c

AUTHOR:		Paul L. DuBois, Mar  3, 1995

ROUTINES:
	Name			Description
	----			-----------
    GLB RunTopLevel		Execute first function in a RunTask

    EXT RunSetupRML		set up the RML state for RunMainLoop

    GLB RunPushArguments	Push some arguments on the runtime stack

    GLB RunFindFunction		see if a routine of a certain name exists

    GLB RunCallFunction		Run a function given its string name

    GLB RunCallFunctionWithKey	run a function given its function key

    INT Run_SetArrayRef		Set an array ref

   ?INT Run_SetModuleVarLVal	pop or assign to a module ref lval

    INT Run_LockOrLoadFTabEntry	Return an RFTE for a funcNum, loading page
				if necessary

   ?INT Run_GetArrayRef		dereference an array ref

   ?INT RunModuleCallProcOrFunc	helper routine to RunMainLoop

    EXT RunGetAggProperty	Get a property from an aggregate

    EXT RunSetAggProperty	Set the property of an aggregate

    EXT RunDoAggAction		Get an aggregate to perform an action

    GLB RunAllocComplex		Allocate a complex on the runtime heap

    GLB RunCreateComplex	Create and initialize a LegosComplex

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 3/ 3/95   	Initial version.

DESCRIPTION:
	Support routines for runmain.c, which is TOO BIG

	$Id: runrout.c,v 1.2 98/10/05 12:33:33 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/runheap.h>
#include <Legos/runint.h>
#include <Legos/stack.h>
#include <Legos/sst.h>
#include <Legos/prog.h>
#include <pos/ramalloc.h>

/*
 * for some reason in linux Ansi/string.h redefines our NULL (defined
 * in liberty.h) as (void *)0 and we get conversion errors, so put
 * it back they way we had it to begin with.  Remove this fix
 * and Ansi/string.h itself when we stop relying on compiler headers.
 */
#include <Ansi/string.h>
#if defined(TOOLSET_gnu) && defined(ARCH_i386)
#undef NULL
#define NULL 0
#endif

#include <Legos/funtab.h>
#include <Legos/strmap.h>
#include <Legos/fixds.h>
#include <driver/keyboard/tchar.h>
#include "legoslog.h"
#include "legosdb.h"

#else	/* GEOS version below */

#include "mystdapp.h"
#include <Ansi/string.h>
#include <sem.h>
#include <chunkarr.h>
#include <hugearr.h>
#include "prog.h"
#include "runint.h"
#include "stack.h"
#include "sst.h"
#include "bugext.h"
#include "funtab.h"
#include "strmap.h"
#include "profile.h"
#include "fixds.h"
#include "rheapint.h"
#endif
#define RMS (*rms)




/* These next two global variables used to be fields in RMLState.
 * However, since RunMainLoop can be called recursively, it's possible
 * that a newer invocation of RunMainLoop might wipe out the cached
 * array referred to by an older invocation.  We use global variables
 * to avoid this bug.  (see 63139)
 */
MemHandle
cachedArray = NullHandle;     /* last array used, already locked */
#ifdef LIBERTY
ArrayHeader
*cachedArrayPtr = NULL;       /* last array used, already deref'd */
#endif




RunFastFTabEntry *Run_LockOrLoadFTabEntry(RunTask* rtask, word funcNum);
extern Boolean ProgHasRunTask(PTaskPtr ptask, RTaskHan rtaskHan);


#if (defined(DEBUG_AID) && defined(EC_LOG)) || defined(LEGOS_NONEC_LOG)
/* For system time */
#include <kernel/system.h>

#if defined(LEGOS_NONEC_LOG)
/* These are normally defined in the kernel, but they are EC-only */
int theComponentTraceLogDepth = 0;
uint16 theLegosFunctionTraceFlag = 0;
uint32 theLegosOpcodeCount = 0;
Boolean theLegosLoadModuleTraceFlag = FALSE;

#if defined(TOOLSET_ghs)
/* Going to multi stdout is incredibly slow */
Boolean theLegosFunctionTraceMemoryFlag = TRUE;
#else
Boolean theLegosFunctionTraceMemoryFlag = FALSE;
#endif

#endif /* LEGOS_NONEC_LOG */

Log *theLegosFunctionTraceLog = NULL;
uint32	theLegosFunctionTraceLogSize = 60000;

/* TRUE if RunSetUpFrame was called from RunSwitchFunctions
 * as opposed to from RunMainLoop via RunCallFunctionWithKey.
 * Logging code is different.
 */
static Boolean theLFT_calledFromRunSwitchFunctions = FALSE;
static RTaskHan theLFT_newModule;
static word theLFT_funcNum;

#endif /* DEBUG_AID && EC_LOG */

#define FUNC_MAX_LEN 80


/*********************************************************************
 *			RunTopLevel -d-
 *********************************************************************
 * SYNOPSIS:	Try to execute designated "top-level" functions
 * CALLED BY:	GLOBAL 
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Try duplo_ui first -- if that doesn't exist, try duplo_start.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/28/94	Initial version			     
 * 
 *********************************************************************/
void
RunTopLevel(RTaskHan rtaskHan)
{
    byte uiFound;

    SET_DS_TO_DGROUP;

    uiFound = RunCallFunction(rtaskHan, _TEXT("duplo_ui_ui_ui"),
			      NULL, NULL, NULL);
    if (!uiFound) {
	RunCallFunction(rtaskHan, _TEXT("duplo_start"), NULL, NULL, NULL);
    }
    RESTORE_DS;
}

/*********************************************************************
 *			RunSetupRML -d-
 *********************************************************************
 * SYNOPSIS:	set up the RML state for RunMainLoop
 * CALLED BY:	EXTERNAL, RunMainLoop
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 6/29/95	Initial version
 * 
 *********************************************************************/
void RunSetupRML(PTaskHan ptaskHan, RMLPtr rms)
{

    /* Set up RMLState from ptask and passed parameters.
     */
    rms->ptask = (PTaskPtr) MemLock(ptaskHan);
#if ERROR_CHECK
    rms->ptask->PT_busy = TRUE;          /* FIXME: race condition */
#endif

    rms->typeStack = (byte*)MemLock(rms->ptask->PT_stack);
    rms->dataStack = (dword*)(rms->typeStack + rms->ptask->PT_stackLength);
    ASSERT_ALIGNED(rms->dataStack);
/*    rms->stack = (byte*)MemLock(rms->ptask->PT_stack);*/

    rms->bpType = rms->typeStack + rms->ptask->PT_context.FC_vbpType;
    rms->spType = rms->typeStack + rms->ptask->PT_vspType;

    rms->bpData = rms->dataStack + rms->ptask->PT_context.FC_vbpData;
    rms->spData = rms->dataStack + rms->ptask->PT_vspData;

    rms->rtask = RunTaskLock(rms->ptask->PT_context.FC_module);

#ifdef LIBERTY
    rms->code = (byte*)CheckLock(rms->ptask->PT_context.FC_codeHandle);
#else
    ;{
	word    dummy;
	HugeArrayLock(rms->rtask->RT_vmFile,
		      rms->rtask->RT_funTabInfo.FTI_code,
		      rms->ptask->PT_context.FC_codeHandle,
		      (void**)&rms->code, 
		      &dummy);
    }
    rms->rhi = &(rms->ptask->PT_runHeapInfo);
#endif
    rms->pc = rms->code + rms->ptask->PT_context.FC_vpc;
    BEGIN_USING_CACHED_ARRAY;
    if (cachedArray != NullHandle) {
	/* Don't let the lock count run up! */
	MemUnlock(cachedArray);
    }
    cachedArray = NullHandle;
    LONLY(cachedArrayPtr = NULL);
    END_USING_CACHED_ARRAY;

    /* keep the global variable locked down */
    if (rms->rtask->RT_moduleVars) {
	LOCK_GLOBALS(rms->rtask->RT_moduleVars, rms->dsType, rms->dsData);
    }

    rms->ehs = NULL;
}

/*********************************************************************
 *			RunPushArguments -d-
 *********************************************************************
 * SYNOPSIS:	Push some arguments on the runtime stack
 * CALLED BY:	GLOBAL
 * RETURN:	# args pushed
 * SIDE EFFECTS:
 * STRATEGY:
 *	params may be a null pointer.
 *
 *	Translate *params into values pushed on the runtime stack.
 *	params should look like:
 *		[byte - # params] ([type byte] [data])*
 *	where [data] is 4 bytes of data or a null-terminated string,
 *	depending on the type byte.
 *
 *      isFunc tells us whether or not we should allocate additional
 *      stack storage space for a return variable.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 4/11/95	Initial version			     
 * 
 *********************************************************************/
byte
RunPushArguments(PTaskHan ptaskHan, RTaskHan rtaskHan, byte* params,
		 byte isFunc)
{
    PTaskPtr	ptask;
    word	numPushed = 0;
    word 	numParams;
    byte*	typeStack;
    byte*	spType;
    dword*	spData;

    /* Not used... */
    rtaskHan = rtaskHan;

    ptask = (PTaskPtr) MemLock(ptaskHan);
    typeStack = (byte*)MemLock(ptask->PT_stack);

    spType = typeStack + ptask->PT_vspType;
    spData = ((dword*)(typeStack + ptask->PT_stackLength)) + ptask->PT_vspData;

    if (params == NULL) {
	numPushed = numParams = 0;
    } else {
	numPushed = numParams = *params;
	params++;
    }

    if (isFunc) 
    {
	*spType++ = TYPE_NONE;
	*spData++ = 0;
	numPushed++;
    }

    while(numParams)
    {
	dword       data;
	LegosType   type;

	type = (LegosType)*params;
	if (type == TYPE_ILLEGAL) 
	{
	    RunSetError(ptask, RTE_BAD_PARAM_TYPE);
	    break;
	}

	params++;
	NextDword(params, data);
	params += sizeof(dword);
	    
	/* push the actual data */
	if (RUN_HEAP_TYPE(type, data))
	{
	    if (type == TYPE_COMPONENT) {
	        RunHeapIncRef(&ptask->PT_runHeapInfo, AGG_TO_STRUCT(data));
	    } else {
	        RunHeapIncRef(&ptask->PT_runHeapInfo, data);
	    }
	}
	*spType++ = type;
	*spData++ = data;

	numParams--;
    }

    /* update virtual stack pointers */
    ptask->PT_vspType += numPushed;
    ptask->PT_vspData += numPushed;
    ASSERT(ptask->PT_vspType == spType - typeStack);

    MemUnlock(ptask->PT_stack);
    MemUnlock(ptaskHan);
    return numPushed;
}

/*********************************************************************
 *			RunFindFunction -d-
 *********************************************************************
 * SYNOPSIS:	see if a routine of a certain name exists
 * CALLED BY:	GLOBAL
 * PASS:    	run task and string of routine name
 * RETURN:  	if function found:
 *			dword function key (pass to RunCallFunctionWithKey)
 *		If not found:
 *			SST_NULL 
 *
 *               Key is actually a word as of 6/29/95. Ent still
 *               expects dword so I haven't changed the api yet...
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/19/95	Initial version			     
 * 
 *********************************************************************/
dword
RunFindFunction(RTaskHan rtaskHan, TCHAR *name)
{
    word   key;
    RunTask *rtask;

    rtask = (RunTask*)MemLock(rtaskHan);
#ifdef LIBERTY
    key = SSTLookup(rtask->RT_stringFuncTable, name, 
		    rtask->RT_stringFuncCount);
#else
    key = SSTLookup(rtask->RT_stringFuncTable, name);
#endif
    MemUnlock(rtaskHan);

    return (long) key;
}

/*********************************************************************
 *			RunCallFunction -d-
 *********************************************************************
 * SYNOPSIS:	Run a function given its string name
 * CALLED BY:	GLOBAL
 * RETURN:	Boolean - FALSE if call failed
 *		If returnType and/or returnVal non-NULL, fill them
 *		in with the return value of the function.  If no value
 *		was returned (for whatever reason), returnType will be
 *		set to TYPE_ILLEGAL
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dloft	5/19/95		Initial version
 * 
 *********************************************************************/
Boolean
RunCallFunction(MemHandle rtaskHan, TCHAR *name, byte *params,
		LegosType *returnType, dword *returnVal)
{
    word	key;
    RunTask	*rtask;
    
    rtask = (RunTask*)MemLock(rtaskHan);

#ifdef LIBERTY
    key = SSTLookup(rtask->RT_stringFuncTable, name, 
		    rtask->RT_stringFuncCount);
#else
    key = SSTLookup(rtask->RT_stringFuncTable, name);
#endif

    MemUnlock(rtaskHan);

    return (key != SST_NULL) ? RunCallFunctionWithKey(rtaskHan, (dword) key,
							 params, returnType,
							 returnVal) : FALSE;
}

/*********************************************************************
 *			RunCallFunctionWithKey -d-
 *********************************************************************
 * SYNOPSIS:	run a function given its function key
 * CALLED BY:	GLOBAL
 * PASS:    	parameters for function in a buffer
 * RETURN:  	FALSE if call failed
 *		If returnType and/or returnVal non-NULL, fill them
 *		in with the return value of the function.  If no value
 *		was returned (for whatever reason), returnType will be
 *		set to TYPE_ILLEGAL.
 *
 *		If an error was raised, returnType will be TYPE_ERROR;
 *		the data will the the specific error number
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/19/95	Initial version			     
 * 
 *********************************************************************/
Boolean
RunCallFunctionWithKey(MemHandle rtaskHan, dword funcNumber, byte *params,
		       LegosType *returnType, dword *returnVal)
{
    RunTask	*rtask;
    PTaskPtr	ptask;
    SET_DS_TO_DGROUP;

#if (defined(DEBUG_AID) && defined(EC_LOG)) || defined(LEGOS_NONEC_LOG)
    if (theLegosFunctionTraceFlag) {
	theLFT_newModule = rtaskHan;
	theLFT_funcNum = funcNumber;
	theLFT_calledFromRunSwitchFunctions = FALSE;
    }
#endif

    /* Not sure where to put these, but this is as good a place as any
     * All these structures are placed on the data stack, which is
     * dword aligned.
     */
#pragma warn -rch
#pragma warn -ccc
    ASSERT(sizeof(LoopContext)%4 == 0);
    ASSERT(sizeof(FrameContext)%4 == 0);
    ASSERT(sizeof(EHState)%4 == 0);
#pragma warn .rch
#pragma warn .ccc

    rtask = (RunTask*)MemLock(rtaskHan);

    /* various reasons we should not run this function */
    if (rtask->RT_flags & RT_EVENTS_DISABLED)
    {
	EC_WARNING(RW_FUNC_CALL_WHEN_DISABLED);
	MemUnlock(rtaskHan);
	RESTORE_DS;
	return TRUE;
    }

    ptask = (PTaskPtr) MemLock(rtask->RT_progTask);

#ifndef LIBERTY
    /* a halt was requested in some run task owned by our progtask, so
     * just stop running all code
     */
    if (ptask->PT_flags & PT_HALT)
    {
	MemUnlock(rtask->RT_progTask);
	MemUnlock(rtaskHan);
	RESTORE_DS;
	return TRUE;
    }
#endif


    /* No events allowed when the interpreter is "busy" (not expecting
     * them), or when interpreter is stopped by the debugger.
     */
#if ERROR_CHECK
    if (ptask->PT_busy) {
	EC_WARNING(RW_FUNC_CALL_WHEN_BUSY);
	goto unlockFail;
    }
#endif

    if (ptask->PT_err != RTE_NONE
#ifndef LIBERTY
	|| rtask->RT_builderRequest == BBR_HALT
#endif
	)
    {
#if 0
	/* we should not have a HALT request without a bugHandle, the
	 * bugHandle gets zeroed out during halt process, so this might
	 * actually happen without being a problem, so just fail
	 */
	ECG_ERROR_IF(rtask->RT_bugHandle == NullHandle && 
		     rtask->RT_builderRequest == BBR_HALT, 
		     RE_FAILED_ASSERTION);
#endif
	goto unlockFail;
    }

    /* Do it!  Execute the function, then restore old context.
     */
    ;{
	RunFastFTabEntry* rfte;
	FrameContext	  oldContext; /* I think this can be made ec-only */
	byte	argsPushed;
	word	vspType_old, vspData_old;
	Boolean	doesReturn;		/* value left on runtime stack? */
	byte*	code;
	byte	calledRoutineIsFunc;

	oldContext = ptask->PT_context;
	ECG(ECCheckFrameContext(&oldContext));

	vspType_old = ptask->PT_vspType;
	vspData_old = ptask->PT_vspData;

	rfte = Run_LockOrLoadFTabEntry(rtask, (word) funcNumber);
	if (rfte == NULL)
	{
	    goto unlockFail;
	}

	/* ptask->PT_context.FC_vbpXXX = ??;	set by SetUpFrame */
	ptask->PT_context.FC_codeHandle = rfte->RFFTE_codeHandle;
	ptask->PT_context.FC_vpc = 0;

#if USES_SEGMENTS
	ptask->PT_context.FC_startSeg = rfte->RFFTE_codeHandle;
#endif

	ptask->PT_context.FC_module = rtaskHan;
	ECG(ECCheckFrameContext(&(ptask->PT_context)));
	
	/* Find out if we return a value
	 */
#ifdef LIBERTY
	/* no offsets in Liberty */
        code = (byte*)CheckLock(rfte->RFFTE_codeHandle);
#else
	;{
	    word dummy;
	    HugeArrayLock(rtask->RT_vmFile, rtask->RT_funTabInfo.FTI_code,
			  rfte->RFFTE_codeHandle, (void**)&code, &dummy);
	}
#endif
	calledRoutineIsFunc = (*code == OP_START_FUNCTION);
#ifdef LIBERTY
	// this must be BEFORE the funtab unlock below!
	CheckUnlock(rfte->RFFTE_codeHandle);
#else
	HugeArrayUnlock(code);
#endif
	FUNTAB_UNLOCK_TABLE_ENTRY(rtask->RT_funTabInfo, rfte);

	argsPushed = RunPushArguments(ptask->PT_handle, rtaskHan, params,
				      calledRoutineIsFunc);

#ifdef LIBERTY
	RTaskHan oldNonAggregateRunTask = NullHandle;
	
	/* change the PT_lastNonAggregateRunTask if needed */
	if(FidoIsAggregateModule(rtask->RT_fidoModule) == FALSE) {
	    oldNonAggregateRunTask = ptask->PT_lastNonAggregateRunTask;
	    ptask->PT_lastNonAggregateRunTask = rtaskHan;
	}
#endif

	MemUnlock(rtaskHan);	/* don't keep it locked during RunMainLoop */
	EC(	rtask = 0;						);

	doesReturn = RunMainLoop(ptask->PT_handle, &oldContext, argsPushed);

	EC_ERROR_IF((ptask->PT_err == 0) && 
		    ((doesReturn && !calledRoutineIsFunc) ||
		    (!doesReturn && calledRoutineIsFunc)), 
		     RE_FAILED_ASSERTION);

#ifdef LIBERTY
	/* change the PT_lastNonAggregateRunTask back if needed */
	if(oldNonAggregateRunTask != NullHandle) {
	    ptask->PT_lastNonAggregateRunTask = oldNonAggregateRunTask;
	}
#endif

	ECG(ECCheckFrameContext(&(ptask->PT_context)));
	if (ptask->PT_err)
	{
	    if (returnType != NULL) *returnType = TYPE_ERROR;
	    if (returnVal != NULL) *returnVal = ptask->PT_err;
	    /* if there are still RunMainLoops running, then set the progtask
	     * to exit from them quietly
	     */
	    if (ptask->PT_vspType == 0) {
		ptask->PT_err = RTE_NONE;
	    } else {
		ptask->PT_err = RTE_QUIET_EXIT;
	    }
	}
	else if (doesReturn)
	{
	    byte*	typeStack;
	    dword*	dataStack;

	    /* Extract return value off top of stack */
	    typeStack = (byte*)MemLock(ptask->PT_stack);
	    dataStack = (dword*)(typeStack+ptask->PT_stackLength);

	    if (returnType != NULL)
	    {
		EC_BOUNDS(returnType);
		*returnType = typeStack[--ptask->PT_vspType];
	    }
	    if (returnVal != NULL)
	    {
		EC_BOUNDS(returnVal);
		*returnVal = dataStack[--ptask->PT_vspData];
	    }
	    MemUnlock(ptask->PT_stack);
	}
	else if (returnType != NULL)
	{
	    *returnType = TYPE_ILLEGAL;
	}

	if (ptask->PT_vspType != vspType_old)
	{
	    /* uh oh... stack wasn't cleaned up, so context probably
	     * wasn't restored either.  This shouldn't happen, but.
	     * Should this be just EC code?
	     */
	    EC_WARNING(RW_STACK_UNBALANCED);
	    ptask->PT_vspType = vspType_old;
	    ptask->PT_vspData = vspData_old;
	    oldContext.FC_vpc =
		(MemHandle)((int)oldContext.FC_vpc & (~VPC_RETURN));

	    ptask->PT_context = oldContext;
	    EC_CHECK_CONTEXT(&oldContext);
#if ERROR_CHECK
	} else {
	    ASSERTS(!memcmp(&ptask->PT_context,&oldContext, sizeof oldContext),
		    "RunCallFunction trashed PT_context");
#endif
	}

	/* If there are zombies and there are no pending calls on the
	 * stack, destroy them now
	 */
	if ((ptask->PT_flags & PT_HAS_ZOMBIES) && (ptask->PT_vspType == 0))
	{
	    ProgDestroyZombieRTasks(ptask);
	}
    }

    MemUnlock(ptask->PT_handle);
    RESTORE_DS;
    return TRUE;
 unlockFail:
    EC_WARNING(RW_FUNC_CALL_FAILED);
    MemUnlock(ptask->PT_handle);
    MemUnlock(rtaskHan);
    RESTORE_DS;
    return FALSE;
}

/*********************************************************************
 *			Run_SetModuleVarLVal -d-
 *********************************************************************
 * SYNOPSIS:	pop or assign to a module ref lval
 * CALLED BY:	EXTERNAL
 * RETURN:	FALSE if failed
 * SIDE EFFECTS:
 * STRATEGY:	a module ref lval is the MemHandle for the module
 *	    	variables of the module and the index into the module
 *	    	variables.
 *
 *	Does not alter refcount of rv.
 *	If FALSE, assignment not made, error is set.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	5/15/95		Initial version
 * 
 *********************************************************************/
Boolean
Run_SetModuleVarLVal(RMLPtr rms, RVal *rv)
{
    MemHandle	moduleVars;
    word	index;
    byte*	varsType;
    dword*	varsData;
    LegosType	lvalType, resultType;

    index = PopData();
    moduleVars = PopData();

    LOCK_GLOBALS(moduleVars, varsType, varsData);
    EC_BOUNDS(varsData + index);

    lvalType = varsType[index];
    if (lvalType != rv->type)
    {
	resultType = AssignTypeCompatible(lvalType, rv->type, &rv->value);
	if (resultType == TYPE_ILLEGAL) {
	    RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, lvalType);
	}
	if (rms->ptask->PT_err) 
	{
	    MemUnlock(moduleVars);
	    return FALSE;
	}
    } else {
	resultType = lvalType;
    }

    if (RUN_HEAP_TYPE(resultType, varsData[index]))
    {
	if (resultType == TYPE_COMPONENT) {
	    RunHeapDecRef(rms->rhi, AGG_TO_STRUCT(varsData[index]));
	} else {
	    RunHeapDecRef(rms->rhi, (RunHeapToken)varsData[index]);
	}
    }

    varsType[index] = resultType;
    varsData[index] = rv->value;

    MemUnlock(moduleVars);
    return TRUE;
}

/*********************************************************************
 *                      RunSwitchFunctions -d-
 *********************************************************************
 * SYNOPSIS:    Switch contexts to a different function, and performs
 *              all of the code that START_{FUNCTION,PROCEDURE} do
 *              so we can skip over it and procede directly...
 *
 * CALLED BY:   OP_MODULE_CALL, OP_CALL, RaiseEvent
 * PASS:        RTaskHan may be NullHandle if switching to same module
 * RETURN:      Nothing
 * SIDE EFFECTS:
 *      May change rtasks, sets code pointer.  May read in code.
 *
 * STRATEGY:
 *      Use this to switch to another function.  Sets up prevContext
 *      for later use by SetUpFrame, switches rtasks if necessary,
 *      asserts that first opcode is a valid start function opcode.
 * 
 *      Causes checking of 1) number of calling arguments and 2)
 *      type-checking of arguments iff checkingRequired is true.
 *
 *	NOTE: Hitting a runtime error here is tricky -- we are in an
 *	inconsistent state, with the current function being the called
 *	function, but the current frame pointer being the callee's.
 *	The choices are to go forward or roll back; this code does the
 *	former. After raising an error, we must fix things up as well
 *	as possible instead of just returning, so that when we return
 *	we will be in a consistent state.
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      dubois   5/ 2/95        Pulled out common code
 * 
 *********************************************************************/
void
RunSwitchFunctions(register RMLPtr rms, RTaskHan newModule, 
		   word funcNum, RunSwitchCheck checkingRequired)
{
    RunFastFTabEntry*	rfte;
    FrameContext	prevContext;
    MemHandle		oldHan, newHan;

#if (defined (DEBUG_AID) && defined(EC_LOG)) || defined(LEGOS_NONEC_LOG)
    if (theLegosFunctionTraceFlag) {
	theLFT_newModule = newModule;
	theLFT_funcNum = funcNum;
	theLFT_calledFromRunSwitchFunctions = TRUE;
    }
#endif

    /* Why are people passing NullHandle in? */
    if (newModule == NullHandle) {
	EC_WARNING(RW_NULLHANDLE_TO_RUN_SWITCH_FUNCTIONS);
	newModule = rms->rtask->RT_handle;
    }

    /* -Set up prevContext
     */
    /* prevContext.FC_vbpUnreloc = (MemHandle)(rms->vbp - rms->stack); */
    prevContext.FC_vbpData = rms->bpData - rms->dataStack;
    prevContext.FC_vbpType = rms->bpType - rms->typeStack;

    prevContext.FC_vpc = rms->pc - rms->code;
#if USES_SEGMENTS
    prevContext.FC_startSeg = rms->ptask->PT_context.FC_startSeg;
#endif
    EC_CHECK_CONTEXT(&rms->ptask->PT_context);
    prevContext.FC_codeHandle = oldHan = rms->ptask->PT_context.FC_codeHandle;

    /* - Switch rtasks if necessary
     */
    prevContext.FC_module = rms->rtask->RT_handle;
    if (newModule != rms->rtask->RT_handle)
    {
	rms->ptask->PT_context.FC_module = newModule;
	if (rms->rtask->RT_moduleVars) {
	    MemUnlock(rms->rtask->RT_moduleVars);
	}
	MemUnlock(rms->rtask->RT_handle);
	rms->rtask = RunTaskLock(newModule);
	if (rms->rtask->RT_moduleVars) {
	    LOCK_GLOBALS(rms->rtask->RT_moduleVars,
			 rms->dsType, rms->dsData);
	}
    } 
    EC_CHECK_CONTEXT(&prevContext);

    /* - set vpc, update context.
     */

    /* This call can shuffle code blocks.
     * EC code destroys what might be invalidated.
     */
#ifndef LIBERTY
    HugeArrayUnlock(rms->code);
#endif
    rfte = Run_LockOrLoadFTabEntry(rms->rtask, funcNum);
    if (rfte == NULL)
    {
	/* go back to old state */
	if (newModule != prevContext.FC_module)
	{
	    if (rms->rtask->RT_moduleVars) {
		MemUnlock(rms->rtask->RT_moduleVars);
	    }
	    MemUnlock(rms->rtask->RT_handle);
	    rms->rtask = RunTaskLock(prevContext.FC_module);
	    if (rms->rtask->RT_moduleVars) {
		LOCK_GLOBALS(rms->rtask->RT_moduleVars,
			     rms->dsType, rms->dsData);
	    }
	    rms->ptask->PT_context.FC_module = prevContext.FC_module;
	}
#ifndef LIBERTY
    {
	/* restore code segment to previous state */
	word	dummy;
	HugeArrayLock(rms->rtask->RT_vmFile, 
		      rms->rtask->RT_funTabInfo.FTI_code,
		      newHan, (void**)&rms->code, &dummy);
    }
#endif
	LONLY(EC_WARN("Can't get FTab entry, RTE_OUT_OF_MEMORY"));
	RunSetError(rms->ptask, RTE_OUT_OF_MEMORY);
	return;
    }
    newHan = rfte->RFFTE_codeHandle;

#ifdef LIBERTY
    CheckUnlock(oldHan);
    rms->code = (byte*) CheckLock(newHan);
#else
{
    word    dummy;
    USE_IT(oldHan);
    HugeArrayLock(rms->rtask->RT_vmFile, 
		  rms->rtask->RT_funTabInfo.FTI_code,
		  newHan, (void**)&rms->code, &dummy);
}
    rms->ptask->PT_context.FC_startSeg = newHan;
#endif
    rms->ptask->PT_context.FC_codeHandle = newHan;

    ECG(ECCheckFrameContext(&(rms->ptask->PT_context)));

    FUNTAB_UNLOCK_TABLE_ENTRY(rms->rtask->RT_funTabInfo, rfte);

    /* -Optional runtime checks:
     * Verify calling a function or a procedure
     * Other checks may be made in RunSetUpFrame
     */
    if (checkingRequired)
    {
	if (checkingRequired & RSC_NUM_ARGS)
	{
	    /* Mostly important for inter-module calls, calls from
	     * outside the interpreter.
	     * Assume that the # args has been pushed on the stack
	     */
	    ASSERT(TopType() == TYPE_INTEGER);
	    PopTypeV();
	    rms->numCallArgs = PopData();
	}

	/* Fix up numCallArgs in case RSC_NUM_ARGS was passed, so
	 * RunSetUpFrame doesn't try to perform its own fixup
	 * (why is that bad?)
	 */
	if ((checkingRequired & RSC_PROC) &&
	    (*rms->code != OP_START_PROCEDURE))
	{
	    RunSetError(rms->ptask, RTE_EXPECT_PROC);
	    PushTypeData(TYPE_NONE, 0);
	    rms->numCallArgs += 1;
	    /* return; NO.  See header comment */
	}
	else if ((checkingRequired & RSC_FUNC) &&
		 (*rms->code != OP_START_FUNCTION))
	{
	    RunSetError(rms->ptask, RTE_EXPECT_FUNC);
	    /* return; NO.  See header comment */
	}
    }

    /* -Inline START_FUNCTION/PROCEDURE opcode here
     */
    EC_ERROR_IF(*rms->code != OP_START_FUNCTION &&
		*rms->code != OP_START_PROCEDURE,
		RE_FAILED_ASSERTION);
    rms->pc = rms->code + 1;
    RunSetUpFrame(rms, checkingRequired, &prevContext);
    return;
}

/*********************************************************************
 *			Run_LockOrLoadFTabEntry
 *********************************************************************
 * SYNOPSIS:	Return an RFTE for a funcNum, loading page if necessary
 * CALLED BY:	INTERNAL, RunSwitchFunctions RunCallFunctionWithKey
 * RETURN:	RFFTE* and function loaded, or fatal error
 *
 * SIDE EFFECTS:*** can move blocks storing code ***
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/20/95	Initial version
 * 
 *********************************************************************/
RunFastFTabEntry*
Run_LockOrLoadFTabEntry(RunTask* rtask, word funcNum)
{
    RunFastFTabEntry*	rfte;

    FUNTAB_LOCK_TABLE_ENTRY(rtask->RT_funTabInfo, rfte, funcNum);
    EC_BOUNDS(rfte);

    /* See if this function hasn't been loaded yet.
     */
    if (rfte->RFFTE_codeHandle == NullHandle)
    {
	word page;

	page = rfte->RFFTE_page;
	FUNTAB_UNLOCK_TABLE_ENTRY(rtask->RT_funTabInfo, rfte);
	/* This will fill in entry */
	if (RunReadPage(rtask, page) == FALSE)
	{
	    return NULL;
	}
	FUNTAB_LOCK_TABLE_ENTRY(rtask->RT_funTabInfo, rfte, funcNum);
	EC_BOUNDS(rfte);
    }

    ECG_ERROR_IF(rfte->RFFTE_codeHandle >= HugeArrayGetCount(rtask->RT_vmFile, rtask->RT_funTabInfo.FTI_code), RE_FAILED_ASSERTION);
    return rfte;
}

/*********************************************************************
 *                      RunSetUpFrame -d-
 *********************************************************************
 * SYNOPSIS:    Set up stack frame for function
 * CALLED BY:	EXTERNAL OP_START_ROUTINE & RunSwitchFunctions
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	Assume all params are already on the stack.
 *		Assume rms.pc is just after the OP_START_XXX opcode
 *
 *	Arguments to opcode:
 *	byte: # params expected on stack
 *	byte: Total # local variables in frame
 *	1 type byte for each local variable
 *
 *	1. Grow stack if necessary
 *	2. Set up frame pointer
 *	3. Type check parameter if necessary
 *	4. Stack space for locals
 *	5. Push return context
 *
 *	NOTE: Hitting a runtime error here is tricky -- we are in an
 *	inconsistent state, with the current function being the called
 *	function, but the current frame pointer being the callee's.
 *	The choices are to go forward or roll back; this code does the
 *	former. After raising an error, we must fix things up as well
 *	as possible instead of just returning, so that when we return
 *	we will be in a consistent state.
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      5/ 9/95        Initial version
 * 
 *********************************************************************/
void
RunSetUpFrame(register RMLPtr rms, RunSwitchCheck checkingRequired,
	      FrameContext *prevContext)
{
    LONLY(TRACE_LOG_DEPTH(++);)	/* Delete this and Matt deletes you. */
    byte	i;
    byte	numParams;	/* parameters passed on stack */
    byte	numLocals;	/* all local variables */
    byte	numDynamic;	/* locals, not including params */

#if (defined (DEBUG_AID) && defined(EC_LOG)) || defined(LEGOS_NONEC_LOG)
    if (theLegosFunctionTraceFlag)
    {
	TCHAR*	funcName;
	RunTask* rtask;

	if (theLegosFunctionTraceLog == NULL) {
	  if (theLegosFunctionTraceMemoryFlag) {
	    theLegosFunctionTraceLog =  new Log("functionTraceLog", theLegosFunctionTraceLogSize, TRUNCATE_AT_END, (char *)malloc(theLegosFunctionTraceLogSize));
	  } else {
	    theLegosFunctionTraceLog =  &theLog;
	  }
	}
	rtask = (RunTask*) MemLock(theLFT_newModule);
	CheckLock(rtask->RT_stringFuncTable);

	funcName = SSTDeref(rtask->RT_stringFuncTable,
			    theLFT_funcNum,
			    rtask->RT_stringFuncCount);

	if (theLFT_calledFromRunSwitchFunctions) {
	    *theLegosFunctionTraceLog << " -";
	} else {
	    *theLegosFunctionTraceLog << ">>";
	}

	LOG_INDENT(*theLegosFunctionTraceLog);

	*theLegosFunctionTraceLog << '<';
	LogML(*theLegosFunctionTraceLog, theLFT_newModule);
	*theLegosFunctionTraceLog << ">::" << funcName << "\t\t" << theLegosOpcodeCount;
	*theLegosFunctionTraceLog << " time: " << theSystem.GetSystemTime() << '\n';
	if (!theLegosFunctionTraceMemoryFlag) {
	    (*theLegosFunctionTraceLog).Flush();
	}
	CheckUnlock(rtask->RT_stringFuncTable);
	MemUnlock(theLFT_newModule);
    }
#endif

    numParams = *rms->pc++;
    numLocals = *rms->pc++;
    /* pc points to a series of type bytes now */

    /*- 1. Grow stack */
    /* if this fails, up THRESHHOLD or check stack more often */
    ASSERT(rms->spData - rms->dataStack < rms->ptask->PT_stackLength);
    if (((rms->spData - rms->dataStack) + (numLocals-numParams) +
	 STACK_REALLOC_THRESHOLD) >
	(rms->ptask->PT_stackLength))
    {
	word    vbpType, vbpData;
	word    vspType, vspData;
	word	oldLength, oldEhs;

	/* The type and data stack actually share the same memory block
	 * with the type stack coming first.  Each has room for PT_stackLength
	 * elements, with types being 1 byte, data being 4
	 */
	vbpType = rms->bpType - rms->typeStack;
	vbpData = rms->bpData - rms->dataStack;

	vspType = rms->spType - rms->typeStack;
	vspData = rms->spData - rms->dataStack;

	oldLength = rms->ptask->PT_stackLength;
	oldEhs = 0xffff;
	if (rms->ehs != NULL) {
	    oldEhs = (byte *)rms->ehs - (byte *)rms->dataStack;
	}
#ifdef LIBERTY
    {
	Result	result;

	MemUnlock(rms->ptask->PT_stack);
	result = ReallocH
	    (rms->ptask->PT_stack,
	     (rms->ptask->PT_stackLength + STACK_LENGTH_INCREMENT) * 5);
	if (result != SUCCESS)
	{
	    RunSetError(rms->ptask, RTE_STACK_OVERFLOW);
	    /* since we have a threshhold - we should be able to finish
	     * off this frame and get out ok
	     */
	} else {
	    rms->ptask->PT_stackLength += STACK_LENGTH_INCREMENT;
	}
	rms->typeStack = (byte*)LockH(rms->ptask->PT_stack);
	EC(theHeap.SetTypeAndOwner(rms->typeStack, "LSTK", (Geode*)0);)
    }
#else
	/* if we are too big for GEOS, bail instead of expanding. */
	if ((rms->ptask->PT_stackLength > MAX_STACK_LENGTH) ||
	    MemReAlloc(rms->ptask->PT_stack,
		       (rms->ptask->PT_stackLength + STACK_LENGTH_INCREMENT)*5,
		       HAF_ZERO_INIT) == NullHandle)
	{
	    RunSetError(rms->ptask, RTE_STACK_OVERFLOW);
	    /* Keep going, we have to have that FrameContext on the stack!
	     * just hope there's room for it... */
	} else {
	    rms->ptask->PT_stackLength += STACK_LENGTH_INCREMENT;
	}
	rms->typeStack = MemDeref(rms->ptask->PT_stack);
#endif
	rms->dataStack = (dword*)(rms->typeStack + rms->ptask->PT_stackLength);
	ASSERT_ALIGNED(rms->dataStack);

	/* Move data stack to make new space for type stack */
	memmove(rms->typeStack + rms->ptask->PT_stackLength,
		rms->typeStack + oldLength,
		oldLength << 2);

	rms->bpType = rms->typeStack + vbpType;	/* xxx not necessary? */
	rms->spType  = rms->typeStack + vspType;

	rms->bpData = rms->dataStack + vbpData;	/* xxx not necessary? */
	rms->spData  = rms->dataStack + vspData;

	if (oldEhs != 0xffff) {
	    /* i only did this so we could compile. someone should check
	     * to see if i messed it up. -kw 
	     * old version: rms->ehs = (byte *)rms->dataStack + oldEhs;*/
	    rms->ehs = (EHState *)((byte *)rms->dataStack + oldEhs);
	}
    }

    if ((checkingRequired & RSC_NUM_ARGS) && (rms->numCallArgs != numParams))
    {
	word	delta;
	RunSetError(rms->ptask, RTE_BAD_NUM_ARGS);

	/* Try and keep things going -- pretend we really did want
	 * the number of arguments we got */
	delta = (rms->numCallArgs - numParams);
	numLocals += delta;
	numParams += delta;
	checkingRequired &= ~RSC_TYPE_ARGS;
    }

    /*- 2. Frame pointer */
    rms->bpType = rms->spType - numParams;
    rms->bpData = rms->spData - numParams;

    /*- 3. Type checks if necessary */
    if (checkingRequired & RSC_TYPE_ARGS)
    {
	for (i = 0; i < numParams; i++) 
	{
	    LegosType formalType, callType, newType;
	    dword callVal;
		
	    formalType = (LegosType) rms->pc[i];
	    callType = rms->bpType[i];
		
	    if (callType == TYPE_NONE)
	    {
		ASSERT(i == 0); /* only func return val should be NONE */
		rms->bpType[i] = formalType;
		continue;
	    }

	    /* Coerce arguments... sigh.  Necessary if we've been called
	     * from another module; types might be wrong.  Should we just
	     * raise an error instead? FIXME spec it
	     */
	    if (formalType != callType) {
		callVal = rms->bpData[i];
		newType = AssignTypeCompatible(formalType, callType,
					       &callVal);
		if (newType == TYPE_ILLEGAL)
		{
		    RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH,
					formalType);
		    /* return;*/
		    break;
		}
		rms->bpData[i] = callVal;
		rms->bpType[i] = newType;
	    }
	}
    }
#if ERROR_CHECK
    /* All the types should be correct by now
     * this ec code assumes rms.pc is pointing at the type arguments
     */
    ASSERT(rms->code+3 == rms->pc);
    if (rms->ptask->PT_err == RTE_NONE)
    {
	for (i = 0; i < numParams; i++)
	{ 
	    ASSERT((rms->pc[i] == TYPE_NONE) ||
		   (rms->pc[i] == rms->bpType[i]));
	}
    }
#endif

    /*- 4. Stack space for locals not passed in */
    numDynamic = numLocals-numParams;
    memcpy(&rms->bpType[numParams], &rms->pc[numParams], numDynamic);
    memset(&rms->bpData[numParams], '\0', numDynamic<<2);
    rms->spType += numDynamic;
    rms->spData += numDynamic;
    rms->pc += numLocals;

    /*- 5. Push return context */
    PushType(TYPE_FRAME_CONTEXT);
    PushBigData(prevContext, FrameContext);
    EC_CHECK_CONTEXT(prevContext);
}

/*********************************************************************
 *                      Run_IndicesToArrayRef -d-
 *********************************************************************
 * SYNOPSIS:    Pop indices off stack and return an array ref
 * CALLED BY:   OP_?_ARRAY_REF_?V
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:        pop off the number of dimensions, and then pop
 *                  off the value for each dimension as well.
 *              Handles case of un-DIMed array (array is NullHandle)
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy    1/27/95        Initial version                      
 * 
 *********************************************************************/
word
Run_IndicesToArrayRef(register RMLPtr rms, MemHandle array, byte numDims)
{
    word        indices[MAX_DIMS], element;
    sword       i;
    ArrayHeader *arrh;
    MemHandle	ca;

    PROFILE_START_SECTION(PS_RUN_DO_ARRAY_REF); 
    if (array == NullHandle) {
	RunSetError(rms->ptask, RTE_ARRAY_REF_SANS_DIM);
	return 0;
    }

    BEGIN_USING_CACHED_ARRAY;
    if ((ca = cachedArray) == array) /* same array as last time? */
    {
	GONLY(arrh = (ArrayHeader *)MemDeref(array));
	LONLY(arrh = cachedArrayPtr);
    }
    else
    {
	/* Unlock old one, lock new one and save it in rms */
	arrh = (ArrayHeader *)MemLock(array);
	if (ca) {
	    MemUnlock(ca);
	}
	cachedArray = array; /* save locked array */
	LONLY(cachedArrayPtr = arrh); /* save deref'd pointer */
    }
    EC_BOUNDS(arrh);
    END_USING_CACHED_ARRAY;

    /* pop off all the indices, checking them against the array's
     * actual size as we go
     */
    if (numDims != arrh->AH_numDims)
    {
	RunSetError(rms->ptask, RTE_BAD_ARRAY_REF);
	return 0;
    }

    for (i = numDims-1; i >= 0; i--)
    {
	RVal    rvDim;

	PopVal(rvDim);
	if (rvDim.type != TYPE_INTEGER) {
	    rvDim.type =
		AssignTypeCompatible(TYPE_INTEGER, rvDim.type, &rvDim.value);
	}
	if (rms->ptask->PT_err || rvDim.type != TYPE_INTEGER ||
	    (word)rvDim.value >= arrh->AH_dims[i])
	{
	    RunSetError(rms->ptask, RTE_BAD_ARRAY_REF);
	    return 0;
	}
	indices[i] = rvDim.value;
    }

    /* compute a linear offset into the array
     */
    /* compute a linear offset into the array
     */
    switch (numDims) {
	/* Singly dimensioned arrays are handled by special opcodes,
	   so no case for them is provided here. */
     case 2:
	element = (indices[0] + 
		   indices[1] * arrh->AH_dims[0]);
	break;
     case 3:
	element = (indices[0] + 
		   indices[1] * arrh->AH_dims[0] +
		   indices[2] * arrh->AH_dims[0] * arrh->AH_dims[1]);
	break;
     default:
	element = RunDimsToOffset(indices, numDims, arrh->AH_dims);
	break;
    }

    PROFILE_END_SECTION(PS_RUN_DO_ARRAY_REF);
    return element;
}

/*********************************************************************
 *			Run_GetArrayRef -d-
 *********************************************************************
 * SYNOPSIS:	dereference an array ref
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:	Doesn't play with reference counts
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 5/26/95	Initial version
 * 
 *********************************************************************/
void
Run_GetArrayRef(RMLPtr rms, MemHandle array, word elt, RVal* rv)
{
    ArrayHeader *arrh;
    MemHandle  	ca;

    SET_DS_TO_DGROUP;                    /* For cachedArray use. */

    if (array == NullHandle) {
	RunSetError(rms->ptask, RTE_ARRAY_REF_SANS_DIM);
	RESTORE_DS;
	return;
    }

    if ((ca = cachedArray) == array) /* same array as last time? */
    {
	GONLY(arrh = (ArrayHeader *)MemDeref(array));
	LONLY(arrh = cachedArrayPtr);
    }
    else
    {
	/* Unlock old one, lock new one and save it in rms */
	arrh = (ArrayHeader *)MemLock(array);
	if (ca) {
	    MemUnlock(ca);
	}
	cachedArray = array; /* save locked array */
	LONLY(cachedArrayPtr = arrh); /* save deref'd pointer */
    }
    EC_BOUNDS(arrh);
    rv->type = (LegosType)arrh->AH_type;
    if (elt >= arrh->AH_maxElt)
    {
	RunSetError(rms->ptask, RTE_BAD_ARRAY_REF);
	MemUnlock(cachedArray);
	cachedArray = NullHandle;
	LONLY(cachedArrayPtr = NULL);
	RESTORE_DS;
	return;
    }
    arrh++;
    RESTORE_DS;
    
    switch (rv->type)
    {
    case TYPE_RUN_HEAP_CASE:
	rv->value = ((RunHeapToken*)arrh)[elt];
	break;

    case TYPE_INTEGER:
#ifndef LIBERTY
    case TYPE_MODULE:
#endif
	rv->value = ((word*)arrh)[elt];
	break;

    case TYPE_LONG:
    case TYPE_FLOAT:
    case TYPE_COMPONENT:
#ifdef LIBERTY
    case TYPE_MODULE:
#endif
	rv->value = ((dword*)arrh)[elt];
	break;

    default:
#if ERROR_CHECK
	EC_ERROR(RE_INVALID_TYPE);
#endif
	break;
    }

    PROFILE_END_SECTION(PS_POP_DEREF_ARRAY_REF);
    return;
}

/*********************************************************************
 *                      Run_SetArrayEltLVal -d-
 *********************************************************************
 * SYNOPSIS:    derefernce an array reference off the stack
 *
 * CALLED BY:   OP_DIR_ASSIGN_ARRAY_REF_?, OP_ASSIGN
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *      a MemHandle and element number will be on the
 *      stack, so that's all we need
 *
 *      Takes invalue of type rtype and assigns
 *      it to the specified array slot if compatible.
 *
 *	Does not alter ref count of rv
 *	Return TRUE if error set, in which case assignment is not made
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy    1/ 5/95        Initial version                      
 * 
 *********************************************************************/
Boolean
Run_SetArrayEltLVal(RMLPtr rms, RVal* rv)
{
    ArrayHeader*	arrh;
    LegosType		arrType, result;
    MemHandle		ca;
    MemHandle		array;
    word		elt;

    PROFILE_START_SECTION(PS_POP_SET_ARRAY_REF);

    elt = PopData();
    array = PopData();

    if (array == NullHandle) {
	RunSetError(rms->ptask, RTE_ARRAY_REF_SANS_DIM);
	return TRUE;
    }

    BEGIN_USING_CACHED_ARRAY;
    if ((ca = cachedArray) == array) /* same array as last time? */
    {
	GONLY(arrh = (ArrayHeader *)MemDeref(array));
	LONLY(arrh = cachedArrayPtr);
    }
    else
    {
	/* Unlock old one, lock new one and save it in rms */
	arrh = (ArrayHeader *)MemLock(array);
	if (ca) {
	    MemUnlock(ca);
	}
	cachedArray = array; /* save locked array */
	LONLY(cachedArrayPtr = arrh); /* save deref'd pointer */
    }
    EC_BOUNDS(arrh);
    END_USING_CACHED_ARRAY;

    /* the optimized array ref opcodes don't do any checking on index bounds
     * so this takes care of that
     */
    if (elt >= arrh->AH_maxElt)
    {
	RunSetError(rms->ptask, RTE_BAD_ARRAY_REF);
	return TRUE;
    }

    arrType = arrh->AH_type;
    arrh++;
    ASSERT_ALIGNED(arrh);

    if (rv->type != arrType) {
	result = AssignTypeCompatible(arrType, rv->type, &rv->value);
	if (result == TYPE_ILLEGAL) {
	    /* FIXME: TYPE_INCOMPATIBLE instead? */
	    RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, arrType);
	    return TRUE;
	}
	/* No variant support for arrays right now. We must
	   know the types of all the elements.. That means
	   result will always be the same as ltype */

	EC_ERROR_IF(result != arrType, RE_FAILED_ASSERTION);
    }

    switch (arrType)
    {
    case TYPE_COMPONENT:
    {
	dword	oldVal;

	/* NextDword(((dword*)arrh)+elt, oldVal); */
	oldVal = ((dword*)arrh)[elt];

	if (COMP_IS_AGG(oldVal)) {
	    RunHeapDecRef(rms->rhi, AGG_TO_STRUCT(oldVal));
	}

        /* CopyDword((((dword *)arrh)+elt), &rv->value); */
	((dword*)arrh)[elt] = rv->value;
	break;
    }

    case TYPE_RUN_HEAP_CASE:
    {
	RunHeapToken	oldToken;

	/* NextRunHeapToken((((RunHeapToken*)arrh)+elt), oldToken); */
	oldToken = ((RunHeapToken*)arrh)[elt];

	if (oldToken) {
	    RunHeapDecRef(rms->rhi, oldToken);
	}

	/* CopyRunHeapToken((((RunHeapToken *)arrh)+elt), &rv->value); */
	((RunHeapToken*)arrh)[elt] = rv->value;
	break;
    }

    case TYPE_INTEGER:
#ifndef LIBERTY
    case TYPE_MODULE:
#endif
	/* CopyWordFromDword((((word *)arrh)+elt), &rv->value); */
	((word*)arrh)[elt] = rv->value;
	break;

    case TYPE_LONG:
    case TYPE_FLOAT:
#ifdef LIBERTY
    case TYPE_MODULE:
#endif
	/* CopyDword((((dword *)arrh)+elt), &rv->value); */
	((dword*)arrh)[elt] = rv->value;
	break;

    default:
	EC_ERROR(RE_FAILED_ASSERTION);
        break;
    }

    PROFILE_END_SECTION(PS_POP_SET_ARRAY_REF);
    return FALSE;
}

/*********************************************************************
 *                      AssignTypeCompatible
 *********************************************************************
 * SYNOPSIS: Can a value of rtype be assigned to an ltype?
 *           If not, return OP_ILLEGAL. If so, return
 *           the result type and also cast the value correctly.
 *
 * CALLED BY:   ASSIGN, SetUpFrame
 *
 * RETURN: New type of ltype, usually ltype except when ltype
 *         is first a VARIANT. Returns OP_ILLEGAL if incompatible.
 *         Fills rdw with correctly casted version of itself.
 *      Note that the way assignment to arrays works, we expect
 *      the return value to be ltype or variant (ie don't coerce
 *      type of LHS!)
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/ 6/95        Initial version                      
 * 
 *********************************************************************/
LegosType
AssignTypeCompatible(LegosType ltype, LegosType rtype, dword *rdw)
{
    EC_BOUNDS(rdw);

    if (rtype == ltype) {
	return ltype;
    }

    PROFILE_START_SECTION(PS_ASSIGN_TYPE_COMPATIBLE);
    switch (ltype) {
    case TYPE_NONE:
    {
	PROFILE_END_SECTION(PS_ASSIGN_TYPE_COMPATIBLE);
	return rtype;
    }
    case TYPE_INTEGER:
    {
	/* Go ahead and cast it like a long
	   so we can later use it as an int or a long... 

	   Essentially, this keeps the sign bit of our
	   result so casting from int to long is trivial
	*/

	if (rtype == TYPE_FLOAT) {
	    *(sdword*)rdw = (sword) *(float*)rdw;       
	    PROFILE_END_SECTION(PS_ASSIGN_TYPE_COMPATIBLE);
	    return ltype;
	}

	/* This actually does something... It cleans
	   out the high bits, leaving only a sign bit... */

	if (rtype == TYPE_LONG) {
	    *(sdword*)rdw = (sword) *(sdword*)rdw;
	    PROFILE_END_SECTION(PS_ASSIGN_TYPE_COMPATIBLE);
	    return ltype;
	}
	
	PROFILE_END_SECTION(PS_ASSIGN_TYPE_COMPATIBLE);
	return TYPE_ILLEGAL;
    }
    case TYPE_LONG:
    {
	if (rtype == TYPE_INTEGER) {
	    *(sdword*)rdw = (sdword)((sword)(*rdw));
	    PROFILE_END_SECTION(PS_ASSIGN_TYPE_COMPATIBLE);
	    return TYPE_LONG;
	}
	if (rtype == TYPE_FLOAT) {
	    *(sdword*)rdw = (sdword)(*(float*)rdw);
	    PROFILE_END_SECTION(PS_ASSIGN_TYPE_COMPATIBLE);
	    return TYPE_LONG;
	}

	PROFILE_END_SECTION(PS_ASSIGN_TYPE_COMPATIBLE);
	return TYPE_ILLEGAL;
    }
    case TYPE_FLOAT:
    {
	/* Assume the high bytes of an int's representation are 0 */
	if (rtype == TYPE_INTEGER || rtype == TYPE_LONG) {
	    *(float*)rdw = (float)(*(sdword*)rdw);
	    PROFILE_END_SECTION(PS_ASSIGN_TYPE_COMPATIBLE);
	    return TYPE_FLOAT;
	}
    }

    default:
	/* if its not a number then the two types must be the same */
	PROFILE_END_SECTION(PS_ASSIGN_TYPE_COMPATIBLE);
    }
    return TYPE_ILLEGAL;
}
#pragma warn .rvl

/*********************************************************************
 *			RunModuleCallProcOrFunc -d-
 *********************************************************************
 * SYNOPSIS:	helper routine to RunMainLoop
 * CALLED BY:	EXTERNAL RunMainLoop
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 6/13/95	Initial version
 * 
 *********************************************************************/
void
RunModuleCallProcOrFunc(RMLPtr	rms, Opcode op)
{
    RunTask*	rt;
    TCHAR*	name;
    RVal	rvModule;
    word	funcKey;
    RunHeapToken funcKeyToken;
    word	funcNum;
    RunSwitchCheck runcheck;
    
#if defined (DEBUG_AID) && defined(EC_LOG)
    theLegosModuleRefProcCount++;
    if (theLegosModuleRefTraceFlag) {
	theLog << "module call #" << theLegosModuleRefProcCount << '\n';
    }
#endif

    GetWordBcl(rms->pc, funcKey);

    funcKeyToken = StrMapLookup(rms->rtask->RT_strConstMap, funcKey);

    /* 1. Pop relevant info off stack
     */
    PopVal(rvModule);
    if (rvModule.type != TYPE_MODULE || 
	(MemHandle)rvModule.value == NullHandle)
    {
	RunSetError(rms->ptask,
		    ((MemHandle)rvModule.value == NullHandle) ?
		    RTE_VALUE_IS_NULL :
		    RTE_BAD_MODULE);
	return;
    }

    /* 2. Try and find the function in the other module
     */
    rt = RunTaskLock(rvModule.value);

    RunHeapLock(rms->rhi, funcKeyToken, (void**)(&name));

#ifdef LIBERTY
    funcNum = SSTLookup(rt->RT_stringFuncTable, name, rt->RT_stringFuncCount);
#else
    funcNum = SSTLookup(rt->RT_stringFuncTable, name);
#endif
    RunHeapUnlock(rms->rhi, funcKeyToken);

    MemUnlock(rvModule.value);

    if (funcNum == SST_NULL)
    {
	RunSetError(rms->ptask, RTE_INVALID_MODULE_CALL);
	return;
    }

    runcheck = RSC_TYPE_ARGS | RSC_NUM_ARGS;
	    
    if (op == OP_MODULE_CALL_PROC) {
	runcheck = runcheck | RSC_PROC;
    }
    else {
	runcheck = runcheck |  RSC_FUNC;
    }
		
    RunSwitchFunctions(rms, (MemHandle)rvModule.value, funcNum, runcheck);
}

/*********************************************************************
 *			RunGetAggPropertyExt
 *********************************************************************
 * SYNOPSIS:	Get property on an agg
 * CALLED BY:	GLOBAL
 * RETURN:	TRUE if getprop went to the aggregate.
 *		TYPE_ERROR will be returned if an error was raised;
 *		in data will be set to the specific error.
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	11/13/95	Initial version
 * 
 *********************************************************************/
Boolean
RunGetAggPropertyExt(PTaskHan ptaskHan, RunHeapToken aggComp,
		     TCHAR* propName, LegosType* lType, dword* lData)
{
    PTaskPtr	ptask;
#ifndef LIBERTY
    RunHeapInfo* rhi;
#endif
    MemHandle	libModule;
    RunHeapToken className;
    word	funcNum = SST_NULL;
    TCHAR	func[FUNC_MAX_LEN];
    TCHAR   	*cp;
    TCHAR   	*nullp;
    byte	args[1+5*3];
    /* DS isn't set up so the initializer doesn't work.
	1,			 Normally 1 arg
	TYPE_STRUCT, 0,0,0,0,	 Agg comp
	TYPE_STRING, 0,0,0,0};	 name of prop, if needed */
    Boolean	success = FALSE;

    SET_DS_TO_DGROUP;
    args[0] = 1; args[1] = TYPE_STRUCT; args[6] = TYPE_STRING;

    ptask = (PTaskPtr)MemLock(ptaskHan);
#ifndef LIBERTY
    rhi = &ptask->PT_runHeapInfo;
#endif

    ;{	/* grab libModule and className from struct */
	byte*	strucP;

	RunHeapLock(rhi, aggComp, (void**)(&strucP));
	FieldNMemHandle(strucP, AF_LIB_MODULE, libModule);
	FieldNRunHeapToken(strucP, AF_CLASS, className);
	RunHeapUnlock(rhi, aggComp);
    }

    if (libModule == NullHandle) goto done;

    /* Create "<className>_" string
     */
    RunHeapLock(rhi, className, (void**)(&cp));
    strcpy(func, cp);
    RunHeapUnlock(rhi, className);
    nullp = strchr(func, C_NULL);
    *nullp++ = C_UNDERSCORE;
    *nullp = C_NULL;
    
    /* Argument 1: component */
    CopyDword(&args[2], &aggComp);

    ;{		/* look up handler in library module */
	RunTask*	rt;

	rt = (RunTask*)MemLock(libModule);

	/* Try "<className>_<prop>Get" first
	 */
	strcat(nullp, propName);
	strcat(nullp, _TEXT("Get"));
#ifdef LIBERTY
	funcNum = SSTLookup(rt->RT_stringFuncTable, func, 
			    rt->RT_stringFuncCount);
#else
	funcNum = SSTLookup(rt->RT_stringFuncTable, func);
#endif

	if (funcNum == SST_NULL)
	{
	    RunHeapToken	propNameToken;
	    /* Need Argument 2: propName
	     */
	    EC_ERROR_IF(strlen(func) > FUNC_MAX_LEN, RE_FAILED_ASSERTION);
	    strcpy(nullp, _TEXT("GetProperty"));
#ifdef LIBERTY
	    funcNum = SSTLookup(rt->RT_stringFuncTable, func,
				rt->RT_stringFuncCount);
#else
	    funcNum = SSTLookup(rt->RT_stringFuncTable, func);
#endif
	    args[0] = 2;
	    propNameToken = RunHeapAlloc(rhi, RHT_STRING, 0, 
					 (strlen(propName)+1)*sizeof(TCHAR), 
					 propName);
	    CopyDword(&args[7], &propNameToken);
	}
	MemUnlock(libModule);
    }

    if (funcNum != SST_NULL) {
	ptask->PT_suspendedErrorCount++;
	EC_ERROR_IF(ptask->PT_suspendedErrorCount == 0, RE_FAILED_ASSERTION);
	success = RunCallFunctionWithKey
	    (libModule, funcNum, args, lType, lData);
	ptask->PT_err = RTE_NONE;
	ptask->PT_suspendedErrorCount--;
    }

 done:
    MemUnlock(ptaskHan);
    RESTORE_DS;
    return success;
}

/*********************************************************************
 *			RunSetAggPropertyExt
 *********************************************************************
 * SYNOPSIS:	Set property on an agg
 * CALLED BY:	GLOBAL
 * RETURN:	TRUE if prop Set succeeded
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	11/13/95	Initial version
 * 
 *********************************************************************/
Boolean
RunSetAggPropertyExt(PTaskHan ptaskHan, RunHeapToken aggComp,
		     TCHAR* propName, LegosType lType, dword lData)
{
    PTaskPtr	ptask;
#ifndef LIBERTY
    RunHeapInfo* rhi;
#endif
    MemHandle	libModule;
    RunHeapToken className;
    word	funcNum = SST_NULL;
    TCHAR	func[FUNC_MAX_LEN];
    TCHAR   	*cp;
    TCHAR   	*nullp;
    byte	args[1+5*3];
/* Initializer doesn't work, so...
 = {
	2,			 Normally 2 args 
	TYPE_STRUCT, 0,0,0,0,	 Agg comp 
	TYPE_NONE, 0,0,0,0,	 value, if 2 args; prop name if 3 
	TYPE_NONE, 0,0,0,0};	 value */
    Boolean	success = FALSE;

    SET_DS_TO_DGROUP;
    args[0]=2; args[1]=TYPE_STRUCT;
    ptask = (PTaskPtr)MemLock(ptaskHan);
#ifndef LIBERTY
    rhi = &ptask->PT_runHeapInfo;
#endif

    ;{	/* grab libModule and className from struct */
	byte*	strucP;

	RunHeapLock(rhi, aggComp, (void**)(&strucP));
	FieldNMemHandle(strucP, AF_LIB_MODULE, libModule);
	FieldNRunHeapToken(strucP, AF_CLASS, className);
	RunHeapUnlock(rhi, aggComp);
    }

    if (libModule == NullHandle) goto done;

    /* Create "<className>_" string
     */
    RunHeapLock(rhi, className, (void**)(&cp));
    strcpy(func, cp);
    RunHeapUnlock(rhi, className);
    nullp = strchr(func, C_NULL);
    *nullp++ = C_UNDERSCORE;
    *nullp = C_NULL;
    
    /* Argument 1: component */
    CopyDword(&args[2], &aggComp);

    ;{		/* look up handler in library module */
	RunTask*	rt;
	RunHeapToken	propNameToken;

	rt = (RunTask*)MemLock(libModule);

	/* Try "<className>_<prop>Set" first
	 */
	strcat(nullp, propName);
	strcat(nullp, _TEXT("Set"));
#ifdef LIBERTY
	funcNum = SSTLookup(rt->RT_stringFuncTable, func,
			    rt->RT_stringFuncCount);
#else
	funcNum = SSTLookup(rt->RT_stringFuncTable, func);
#endif

	if (funcNum == SST_NULL)
	{
	    /* Need Argument 2: propName, Argument 3: value
	     */
	    EC_ERROR_IF(strlen(func) > FUNC_MAX_LEN, RE_FAILED_ASSERTION);
	    strcpy(nullp, _TEXT("SetProperty"));
#ifdef LIBERTY
	    funcNum = SSTLookup(rt->RT_stringFuncTable, func,
				rt->RT_stringFuncCount);
#else
	    funcNum = SSTLookup(rt->RT_stringFuncTable, func);
#endif
	    args[0] = 3;

	    /* Allocate string on heap */
	    propNameToken = RunHeapAlloc(rhi, RHT_STRING, 0, 
					 (strlen(propName)+1)*sizeof(TCHAR), 
					 propName);
				     
	    args[6] = TYPE_STRING;
	    CopyDword(&args[7], &propNameToken);

	    args[11] = lType;
	    CopyDword(&args[12], &lData);
	} else {
	    /* Argument 2: value
	     */
	    args[6] = lType;
	    CopyDword(&args[7], &lData);
	}
	MemUnlock(libModule);
    }

    if (funcNum != SST_NULL) {
	ptask->PT_suspendedErrorCount++;
	EC_ERROR_IF(ptask->PT_suspendedErrorCount == 0, RE_FAILED_ASSERTION);
	success = RunCallFunctionWithKey
	    (libModule, funcNum, args, NULL, NULL);
	ptask->PT_err = RTE_NONE;
	ptask->PT_suspendedErrorCount--;
    }

 done:
    MemUnlock(ptaskHan);
    RESTORE_DS;
    return success;
}

/*********************************************************************
 *			RunGetAggProperty -d-
 *********************************************************************
 * SYNOPSIS:	Get a property from an aggregate
 * CALLED BY:	EXTERNAL RunMainLoop
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	call function in component's libModule called:
 *		<class>_GetProperty
 *	The property will be left on the stack.
 *
 * BUGS:
 *	Uses unsafe static buffers.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/16/95	Initial version
 * 
 *********************************************************************/
void
RunGetAggProperty(RMLPtr rms, RunHeapToken propNameToken)
{
    MemHandle	libModule;
    RunHeapToken aggStruct;
    RunHeapToken className;
    word	funcNum = SST_NULL;
    TCHAR	func[FUNC_MAX_LEN];
    TCHAR   	*cp;
    TCHAR   	*nullp;
    byte	numArgs;

    ASSERT(NthType(1) == TYPE_COMPONENT && COMP_IS_AGG(NthData(1)));
    aggStruct = AGG_TO_STRUCT(NthData(1));

    ;{	/* grab libModule and className from struct */
	byte*	strucP;
	RunHeapLock(rms->rhi, aggStruct, (void**)(&strucP));
	FieldNMemHandle(strucP, AF_LIB_MODULE, libModule);
	FieldNRunHeapToken(strucP, AF_CLASS, className);
	RunHeapUnlock(rms->rhi, aggStruct);
    }

    if (libModule == NullHandle) {
	RunSetError(rms->ptask, RTE_VALUE_IS_NULL);
	return;
    } else {
	PopValVoid();
    }

    /* Create "<className>_" string
     */
    RunHeapLock(rms->rhi, className, (void**)(&cp));
    strcpy(func, cp);
    RunHeapUnlock(rms->rhi, className);
    nullp = strchr(func, C_NULL);
    *nullp++ = C_UNDERSCORE;
    *nullp = C_NULL;
    

    ;{		/* look up handler in library module */
	RunTask*	rt;
	SET_DS_TO_DGROUP;

	rt = (RunTask*)MemLock(libModule);

#if 0
	/* Try "<className>_<prop>Get" first
	 */
	RMS_StringLock(propNameToken, (void**)(&cp));
	strcat(nullp, prop);
	RMS_StringUnlock(propNameToken, cp);
	strcat(nullp, _TEXT("Get"));
	/* FIXME Lookup into funcNum */
#endif

	/* "Argument" 1: return value
	 */
	PushTypeData(TYPE_NONE, 0);

	/* Argument 2: aggregate component
	 * Within the agg library, it should be a structure 
	 * Don't inc because we didn't dec above
	 */
	PushTypeData(TYPE_STRUCT, aggStruct);

	numArgs = 2;

	if (funcNum == SST_NULL)
	{
	    /* Need Argument 3: propName
	     */
	    EC_ERROR_IF(strlen(func) > FUNC_MAX_LEN, RE_FAILED_ASSERTION);
	    strcpy(nullp, _TEXT("GetProperty"));
#ifdef LIBERTY
	    funcNum = SSTLookup(rt->RT_stringFuncTable, func,
				rt->RT_stringFuncCount);
#else
	    funcNum = SSTLookup(rt->RT_stringFuncTable, func);
#endif
	    RunHeapIncRef(rms->rhi, propNameToken);
	    PushTypeData(TYPE_STRING, propNameToken);
	    numArgs++;
	}
	RESTORE_DS;
	MemUnlock(libModule);
    }


    if (funcNum == SST_NULL)
    {
	RunSetError(rms->ptask, RTE_INVALID_MODULE_CALL);
	return;
    }

    PushTypeData(TYPE_INTEGER, numArgs);
    RunSwitchFunctions(rms, libModule, funcNum,
		       RSC_FUNC | RSC_TYPE_ARGS | RSC_NUM_ARGS);
    return;
}

/*********************************************************************
 *			RunSetAggProperty -d-
 *********************************************************************
 * SYNOPSIS:	Set the property of an aggregate
 * CALLED BY:	EXTERNAL RunMainLoop
 * PASS:	stack: <component> <string> TOS
 * RETURN:
 * SIDE EFFECTS:
 *
 *	rvR is popped off in OP_ASSIGN, but not dec'd because it will
 *	just be assigned to something later (in this case, pushed back
 *	on the stack).  This is why it's pushed without an inc.
 *	
 *	Call <class>_SetProperty with stack
 *		<agg struct> <string> <value> INTEGER(3)	OR
 *
 *	Call <class>Set_<prop> with stack
 *		<agg struct> <value> INTEGER(2)
 *
 * STRATEGY:
 *	Start with agg and prop on stack
 *
 *	remove prop, push value, call <class>_<property>Set	OR
 *	push value and call <class>_SetProperty
 *
 *	The property will be left on the stack.
 *
 * BUGS:
 *	Uses unsafe static buffers.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/16/95	Initial version
 * 
 *********************************************************************/
#define FUNC_MAX_LEN 80
void
RunSetAggProperty(RMLPtr rms, RVal* rvR)
{
    MemHandle	libModule;
    RunHeapToken aggStruct;
    RunHeapToken className;
    word	funcNum = SST_NULL;
    TCHAR	func[FUNC_MAX_LEN];
    TCHAR   	*cp;
    TCHAR   	*nullp;
    byte	numArgs;

    ASSERT(NthType(2) == TYPE_COMPONENT && COMP_IS_AGG(NthData(2)));
    aggStruct = NthData(2) = AGG_TO_STRUCT(NthData(2));
    NthType(2) = TYPE_STRUCT;

    ;{	/* grab libModule and className from struct */
	byte*	strucP;

	RunHeapLock(rms->rhi, aggStruct, (void**)(&strucP));
	FieldNMemHandle(strucP, AF_LIB_MODULE, libModule);
	FieldNRunHeapToken(strucP, AF_CLASS, className);
	RunHeapUnlock(rms->rhi, aggStruct);
    }

    if (libModule == NullHandle) {
	RunSetError(rms->ptask, RTE_VALUE_IS_NULL);
	return;
    }

    /* Create "<className>_" string
     */
    RunHeapLock(rms->rhi, className, (void**)(&cp));
    strcpy(func, cp);
    RunHeapUnlock(rms->rhi, className);
    nullp = strchr(func, C_NULL);
    *nullp++ = C_UNDERSCORE;
    *nullp = C_NULL;

    ;{		/* look up handler in library module */
	RunTask*	rt;

	SET_DS_TO_DGROUP;
	rt = (RunTask*)MemLock(libModule);
#if 0
	/* Try "<className>_<prop>Set" first
	 */
	propName = NthData(1);
	RunHeapLock(rms->rhi, propName, (void**)&cp);
	strcat(nullp, cp);
	RunHeapDecRefAndUnlock(rms->rhi, propName, cp);
	strcat(nullp, _TEXT("Set"));
	/* FIXME: Look up, pop off propName if successful */
#endif

	/* Argument 1: aggregate component, already on stack */
	numArgs = 2;

	if (funcNum == SST_NULL)
	{
	    /* Argument 2: propName, still on stack */
	    EC_ERROR_IF(strlen(func) > FUNC_MAX_LEN, RE_FAILED_ASSERTION);
	    strcpy(nullp, _TEXT("SetProperty"));
#ifdef LIBERTY
	    funcNum = SSTLookup(rt->RT_stringFuncTable, func,
                                rt->RT_stringFuncCount);
#else
	    funcNum = SSTLookup(rt->RT_stringFuncTable, func);
#endif
	    numArgs++;
	}
	RESTORE_DS;
	MemUnlock(libModule);
    }

    /* Last 2 arguments -- value and #args
     */
    PushTypeData(rvR->type, rvR->value);
    PushTypeData(TYPE_INTEGER, numArgs);

    /* Check after things are on stack, so they can be cleaned up */
    if (funcNum == SST_NULL)
    {
	RunSetError(rms->ptask, RTE_INVALID_MODULE_CALL);
	return;
    }

    RunSwitchFunctions(rms, libModule, funcNum,
		       (RSC_PROC | RSC_TYPE_ARGS | RSC_NUM_ARGS));
    return;
}

/*********************************************************************
 *			RunDoAggAction -d-
 *********************************************************************
 * SYNOPSIS:	Get an aggregate to perform an action
 * CALLED BY:	EXTERNAL, RunMainLoop
 * PASS:	vpc:	name of action
 *		stack:	[zero] {params...} #params component TOS
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/27/95	Initial version
 * 
 *********************************************************************/
void
RunDoAggAction(RMLPtr rms, Opcode op, RunHeapToken actionToken)
{
    MemHandle		libModule;
    RunHeapToken	aggStruct;
    dword    		numArgs;
    RunHeapToken	className;
    word		funcNum;
    TCHAR		func[FUNC_MAX_LEN];
    TCHAR*		cp;
    RunSwitchCheck	runSwitchChecks;
    
    ASSERT(TopType() == TYPE_COMPONENT && COMP_IS_AGG(TopData()));
    aggStruct = PopData();
    aggStruct = AGG_TO_STRUCT(aggStruct);
    PopTypeV();

    ASSERT(TopType() == TYPE_INTEGER);
    numArgs = PopData(); PopTypeV();

    ;{	/* grab libModule and className from struct */
	byte*	strucP;

	RunHeapLock(rms->rhi, aggStruct, (void**)(&strucP));
	FieldNMemHandle(strucP, AF_LIB_MODULE, libModule);
	FieldNRunHeapToken(strucP, AF_CLASS, className);
	RunHeapUnlock(rms->rhi, aggStruct);
    }

    if (libModule == NullHandle) {
	RunSetError(rms->ptask, RTE_VALUE_IS_NULL);
	return;
    }

    /* Create "<className>_<action>" string
     */
    RunHeapLock(rms->rhi, className, (void**)(&cp));
    strcpy(func, cp);
    RunHeapUnlock(rms->rhi, className);

    ;{
	SET_DS_TO_DGROUP;
	strcat(func, _TEXT("_"));
	RESTORE_DS;
    }

    RunHeapLock(rms->rhi, actionToken, (void**)(&cp));
    strcat(func, cp);
    RunHeapUnlock(rms->rhi, actionToken);

    ;{
	RunTask*	rt;
	rt = (RunTask*)MemLock(libModule);
#ifdef LIBERTY
	funcNum = SSTLookup(rt->RT_stringFuncTable, func,
                            rt->RT_stringFuncCount);
#else
	funcNum = SSTLookup(rt->RT_stringFuncTable, func);
#endif
	MemUnlock(libModule);
    }

    if (funcNum == SST_NULL)
    {
	RunSetError(rms->ptask, RTE_INVALID_ACTION);
	RunHeapDecRef(rms->rhi, aggStruct);
	return;
    }

    /* Last 2 arguments -- <agg>, <#args> */
    if (op == OP_ACTION_FUNC) {
	runSwitchChecks = RSC_FUNC | RSC_TYPE_ARGS | RSC_NUM_ARGS;
	numArgs ++;		/* for the return value */
    } else {
	runSwitchChecks = RSC_PROC | RSC_TYPE_ARGS | RSC_NUM_ARGS;
    }

    PushTypeData(TYPE_STRUCT, aggStruct);
    PushTypeData(TYPE_INTEGER, numArgs+1); /* +1 for the aggStruct */

    RunSwitchFunctions(rms, libModule, funcNum, runSwitchChecks);
    return;
}

/*********************************************************************
 *	    	    RunDimsToOffset
 *********************************************************************
 * SYNOPSIS:	convert a bunch of dims to an offset to index
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	10/ 5/94		Initial version			     
 * 
 *********************************************************************/
#define ARRAY_BACKWARDS
word
RunDimsToOffset(word *dims, byte num_dims, word *max_dims)
{
    word	element;

#if defined(ARRAY_GENERAL_BACKWARDS)
    byte	j,k;
    word	tmp;

    element = 0;
    for(j=0; j<num_dims; j++)
    {
	tmp = 1;
	for(k=0; k<j; k++)
	{
	    tmp *= max_dims[k];
	}
	tmp *= dims[j];

	element += tmp;
    }
#elif defined(ARRAY_BACKWARDS)
    switch (num_dims)
    {
    case 0:
	element = 0;
	break;
    case 1:
	element = dims[0];
	break;
    case 2:
	element = (dims[0] + 
		   dims[1] * max_dims[0]);
	break;
    case 3:
	element = (dims[0] + 
		   dims[1] * max_dims[0] +
		   dims[2] * max_dims[0] * max_dims[1]);
	break;
     default:
	{
	    byte	j,k;
	    word	tmp;

	    // General code
	    element = 0;
	    for(j=0; j<num_dims; j++)
	    {
		tmp = 1;
		for(k=0; k<j; k++)
		{
		    tmp *= max_dims[k];
		}
		tmp *= dims[j];
		
		element += tmp;
	    }
	}
    }
#else
    /* General pattern is:
     * dim[i] * Product(max_dims[greater than i])
     * If the max # of dims were > 3 then higher orders
     * can be optimized by saving products
     */
    switch (num_dims)
    {
    case 0:
	element = 0;
	break;
    case 1:
	element = dims[0];
	break;
    case 2:
	element = dims[0] * max_dims[1] +
	          dims[1];
	break;
    case 3:
	element = dims[0] * max_dims[1] * max_dims[2] +
	          dims[1] * max_dims[2] +
		  dims[2];
	break;
    }
#endif
    return element;
}

/*********************************************************************
 *			RunAllocComplex
 *********************************************************************
 * SYNOPSIS:	Allocate a complex on the runtime heap
 * CALLED BY:	GLOBAL
 * RETURN:	RunHeapToken of an uninit'd complex
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	9/25/95	Initial version
 * 
 *********************************************************************/
RunHeapToken
RunAllocComplex(PTaskHan ptaskHan)
{
    PTaskPtr	ptask;
    RunHeapToken complex;

    ptask = (PTaskPtr)MemLock(ptaskHan);
    complex = RunHeapAlloc(&ptask->PT_runHeapInfo, RHT_COMPLEX, 1,
			   sizeof(LegosComplex), NULL);
    MemUnlock(ptaskHan);
    return complex;
}

/*********************************************************************
 *			RunCreateComplex
 *********************************************************************
 * SYNOPSIS:	Create/init a LegosComplex with a copy of passed VMChain
 * CALLED BY:	GLOBAL
 * RETURN:	RunHeapToken of the complex
 * SIDE EFFECTS:
 * STRATEGY:
 *	Copy VMChain into newly-allocated complex
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	9/27/95	Initial version
 * 
 *********************************************************************/
#ifdef LIBERTY
RunHeapToken
RunCreateComplex(PTaskHan /*ptaskHan*/, ClipboardItemFormatID /*format*/,
		 VMFileHandle /*vmfh*/, VMChain /*oldChain*/)
{
    ASSERTS_WARN(FALSE, "RunCreateComplex() not implemented in Liberty.");
    return NULL;
}
#else
RunHeapToken
RunCreateComplex(PTaskHan ptaskHan, ClipboardItemFormatID format,
		 VMFileHandle vmfh, VMChain oldChain)
{
    PTaskPtr		ptask;
    RunHeapToken	lcTok;
    LegosComplex*	lcPtr;
    VMChain		newChain;

    ptask = (PTaskPtr)MemLock(ptaskHan);
    lcTok = RunHeapAlloc(&ptask->PT_runHeapInfo, RHT_COMPLEX, 1,
			   sizeof(LegosComplex), NULL);

    newChain = VMCopyVMChain_FIX(vmfh, oldChain, ptask->PT_vmFile);

    RunHeapLock(&ptask->PT_runHeapInfo, lcTok, (void**)(&lcPtr));
    lcPtr->LC_vmfh = ptask->PT_vmFile;
    lcPtr->LC_chain= newChain;
    lcPtr->LC_format = format;
    RunHeapUnlock(&ptask->PT_runHeapInfo, lcTok);

    MemUnlock(ptaskHan);
    return lcTok;
}
#endif





/*********************************************************************
 *			OpJmpSeg -d-
 *********************************************************************
 * SYNOPSIS:	jump to a different segment
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	1/ 4/96	Initial version
 * 
 *********************************************************************/
void
OpJmpSeg(register RMLPtr rms, word target)
{
    word    offset;
#ifndef LIBERTY
    word	tmpWord;
    offset = target & 0x0fff;
    target = (target >> 12) + rms->ptask->PT_context.FC_startSeg;
    if (target != rms->ptask->PT_context.FC_codeHandle)
    {
	HugeArrayUnlock(rms->code);
	HugeArrayLock(rms->rtask->RT_vmFile, 
		      rms->rtask->RT_funTabInfo.FTI_code, target,
		      (void **)&rms->code, &tmpWord);
	/* update current code handle pointer */
	rms->ptask->PT_context.FC_codeHandle = target;
    }
#else
    offset = target;
#endif
    rms->pc = rms->code + offset;
}
