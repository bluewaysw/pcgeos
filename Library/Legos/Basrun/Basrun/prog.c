/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		prog.c

AUTHOR:		Jimmy Lefkowitz, Jan 26, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 1/26/95   	Initial version.

DESCRIPTION:
	program stuff

	$Revision: 1.2 $

	Liberty version control
	$Id: prog.c,v 1.2 98/10/05 12:41:00 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/runint.h>
#include <Legos/stack.h>
#include <Legos/fido.h>
#include <Legos/progtask.h>
#include <Legos/run.h>
#include <Legos/fixds.h>
#include <pos/ramalloc.h>

#else	/* GEOS version below */

#include <Ansi/string.h>
#include <Legos/fido.h>
#include <file.h>

#include "mystdapp.h"
#include "prog.h"
#include "run.h"
#include "fixds.h"
#include "rheapint.h"
#include "runint.h"
#include "stack.h"
#include "fidoint.h"

/* From clipbrd.goh. DOn't want to make this a .goc file, so
   just yank it! */

extern VMFileHandle	/* XXX */
    _pascal ClipboardGetClipboardFile(void);
#endif

#define MAX_NUM_LOADED_MODULES 128

/*********************************************************************
 *			ProgAllocTask -d-
 *********************************************************************
 * SYNOPSIS:	Create a ProgTask
 * CALLED BY:	GLOBAL 
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 2/ 3/95	Created func header
 * 
 *********************************************************************/
PTaskHan
ProgAllocTask(optr interpreter, VMFileHandle vmfile)
{
    MemHandle	ptaskHan;
    ProgTask 	*ptask;
    GONLY( RTaskHan   rtaskHan);
    SET_DS_TO_DGROUP;

    USE_IT(interpreter);
    USE_IT(vmfile);

    ptaskHan = (MemHandle)MemAlloc(sizeof(ProgTask), HF_SWAPABLE | HF_SHARABLE,
				   HAF_ZERO_INIT);
    if (ptaskHan == NullHandle) {
	RESTORE_DS;
	return NullHandle;
    }
    ptask = (ProgTask*)MemLock(ptaskHan);
    ECL(theHeap.SetTypeAndOwner(ptask, "PTSK", (Geode*)0);)

    // COMMON
#ifndef LIBERTY
    if (vmfile == NullHandle) 
    {
	vmfile = ClipboardGetClipboardFile();
	ptask->PT_aintMyVmFile = TRUE;
    }
    else {
	ptask->PT_aintMyVmFile = TRUE;
    }
#endif

    /* The rest of the fields, initialized in order.  Zero-init lines
     * are commented out.
     */
    ptask->PT_handle		= ptaskHan;
    ptask->PT_cookie		= PTASK_COOKIE;
    GONLY( ptask->PT_vmFile	= vmfile; )
/*  ptask->PT_filename set above				*/
/*  ptask->PT_aintMyVmFile set above				*/
/*  ptask->PT_mainTask		= NullHandle;			*/
    ptask->PT_lastNonAggregateRunTask = NullHandle;
    ptask->PT_tasks = (MemHandle)MemAlloc(MAX_NUM_LOADED_MODULES * sizeof(MemHandle), 
					  HF_SWAPABLE | HF_SHARABLE, 
					  HAF_ZERO_INIT);
#ifdef LIBERTY
#ifdef ERROR_CHECK
    if(ptask->PT_tasks != NullHandle) {
	void *block = LockH(ptask->PT_tasks);
	theHeap.SetTypeAndOwner(block, "PTKS", (Geode*)0);
	UnlockH(ptask->PT_tasks);
    }
#endif 
#endif
    ptask->PT_numTasks		= 0;

#ifndef LIBERTY
    ptask->PT_fidoTask		= FidoAllocTask();
#endif

    GONLY( ptask->PT_interpreter = interpreter; )
    GONLY( ptask->PT_runHeapInfo = RunHeapCreate(); )

/*  ptask->PT_busy		= FALSE;			*/
/*  ptask->PT_err		= RTE_NONE;			*/
    ptask->PT_stack = (MemHandle)MemAlloc(INITIAL_STACK_LENGTH * 5, 
					  HF_SWAPABLE | HF_SHARABLE,
					  HAF_ZERO_INIT);
#ifdef LIBERTY
#ifdef ERROR_CHECK
    if(ptask->PT_stack != NullHandle) {
	void *block = LockH(ptask->PT_stack);
	theHeap.SetTypeAndOwner(block, "LSTK", (Geode*)0);
	UnlockH(ptask->PT_stack);
    }
#endif 
#endif
    ptask->PT_stackLength = INITIAL_STACK_LENGTH;

    /* All xxxUnreloc values are used to save the state during
       recursive calls, they store difference between the used values
       and the start of the actual memory block, which are movable */

/*  ptask->PT_vspData = ptask->vspType = 0			*/

/*  ptask->PT_context.FC_vbpData = 0;				*/
/*  ptask->PT_context.FC_vbpType = 0;				*/
/*  ptask->PT_context.FC_vpc = 0;				*/

    ptask->PT_context.FC_codeHandle = ECNullHandle;
    ptask->PT_context.FC_module	= ECNullHandle;
#if USES_SEGMENTS
    ptask->PT_context.FC_startSeg = 0xcccc;
#endif

/*  ptask->PT_suspendedErrorCount= 0;				*/

    MemUnlock(ptaskHan);

#if 0
    /* Builder no longer uses this */
#ifndef LIBERTY
    /* Liberty doesn't have a builder */
    rtaskHan = RunAllocTask(ptaskHan, NullOptr);
    ProgAddRunTask(ptaskHan, rtaskHan);
    ProgSetMainTask(ptaskHan, rtaskHan);
#endif
#endif

    RESTORE_DS;
    return ptaskHan;
}

#ifndef LIBERTY

/*********************************************************************
 *			ProgTurboChargeFido
 *********************************************************************
 * SYNOPSIS:	For apps which statically depend on component libraries
 *              time required to create the first component can be
 *              dramatically reduced by telling Fido explicitly
 *              that they have already been loaded.
 *
 * CALLED BY:	Different "viewer" or "launcher" apps.
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/26/95	Initial version
 * 
 *********************************************************************/
void
ProgTurboChargeFido(PTaskHan ptaskHan)
{
    ProgTask    *ptask;

    ptask = (ProgTask*)MemLock(ptaskHan);
    FidoRegLoadedCompLibs(ptask->PT_fidoTask);
    MemUnlock(ptaskHan);
}
#endif

/*********************************************************************
 *			ProgHasRunTask
 *********************************************************************
 * SYNOPSIS:	check the list to see if we have this one
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/30/95	Initial version
 * 
 *********************************************************************/
Boolean ProgHasRunTask(PTaskPtr	ptask, RTaskHan rtaskHan)
{
    RTaskHan	*moduleArray;
    word	numTasks;
    Boolean	retval = FALSE;

    moduleArray = (RTaskHan*)MemLock(ptask->PT_tasks);
    numTasks = ptask->PT_numTasks;

    while(numTasks)
    {
	if (*moduleArray == rtaskHan) 
	{
	    retval = TRUE;
	}
	moduleArray++;
	numTasks--;
    }

    MemUnlock(ptask->PT_tasks);
    /* this is really a workaround a tricky problem of runtasks getting
     * freed while an error dialog is up - we'll see what happens
     */
    EC_WARNING_IF(retval == FALSE, -1);
    return retval;
}


/*********************************************************************
 *			ProgDestroyRunTask
 *********************************************************************
 * SYNOPSIS:	destroy a given runtask and nuke it from list
 *	    	but only if its in the correct state
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	because of problems with lview putting up dialogs just
 *	    	as STOP is hit, I have a delayed system for deleting
 *	    	RunTasks, the first time we try to delete them, we mark
 *	    	them as ready to be deleted, so the next time around they
 *	    	actually get deleted, this fixes the nasty problem due
 *	    	to the fact that UserDoDialog send MSG_META_FLUSH_INPUT_QUEUE
 *	    	messages on through, not allowing lview to use that mechanism
 *	    	to wait until the last RunMainLoop has exited - whatever
 *
 *	    	this has the unfortunate side effect of chewing up some extra
 *	    	handles, but that's better than crashing, and they do get
 *	    	freed on the next RUN, so the number of handles doesn't
 *	    	keep growing
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 1/95	Initial version
 * 
 *********************************************************************/

#define MARKED_FOR_DELETION ((byte)-1)

Boolean
ProgDestroyRunTask(MemHandle ptaskHan, RTaskHan rtaskHan)
{
    ProgTask	*ptask;
    MemHandle	*moduleArray;
    word	numTasks;
    Boolean    	retval = FALSE;

    ptask = (ProgTask*)MemLock(ptaskHan);

    numTasks = ptask->PT_numTasks;
    moduleArray = (MemHandle*)MemLock(ptask->PT_tasks);

    while(numTasks)
    {
	if (rtaskHan == *moduleArray)
	{
	    RunDestroyTask(*moduleArray);
	    retval = TRUE;
	    --ptask->PT_numTasks;
	    /* shift last one into emptied slot */
	    *moduleArray = *(moduleArray+numTasks-1);
	    break;
	}
    	moduleArray++;
	numTasks--;
    }
    MemUnlock(ptask->PT_tasks);
    MemUnlock(ptaskHan);
    return retval;
}


/*********************************************************************
 *			ProgDestroyTask -d-
 *********************************************************************
 * SYNOPSIS:	Destroy a ProgTask
 * CALLED BY:	GLOBAL
 * RETURN:	nothing
 * SIDE EFFECTS:Nukes things
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 2/ 3/95	Broken out from BascoEndProgram
 * 
 *********************************************************************/
void
ProgDestroyTask(PTaskHan ptaskHan)
{
    ProgTask	*ptask;
    RTaskHan	*moduleArray;
    word	numTasks;

    ptask = (ProgTask*)MemLock(ptaskHan);
    
    moduleArray = (RTaskHan*)MemLock(ptask->PT_tasks);

    /* NOTE: here we are Destroying runtasks regardless of their busy
     * state, as the assumption is that since we are actually destroying
     * the prog task, we really are done with these runtasks
     */
    numTasks = ptask->PT_numTasks;
    while (numTasks)
    {
	RunDestroyTask(*moduleArray);
	*moduleArray = NullHandle;
	moduleArray++;
	--numTasks;
    }

    /* Only destroy the vmfile if the task is the one that
     * created it..
     */
#ifndef LIBERTY
    if (!ptask->PT_aintMyVmFile) {
	VMClose( ptask->PT_vmFile, 0 );
    }
#endif
    ECL(MemUnlock(ptask->PT_tasks));
    /*    ECL(MemUnlock(ptask->PT_stack);)  this doesn't seem to be locked */
    MemFree(ptask->PT_tasks);
    MemFree(ptask->PT_stack);

#ifndef LIBERTY
    FidoDestroyTask(ptask->PT_fidoTask);
    RunHeapDestroy(&(ptask->PT_runHeapInfo));
#endif
    ECL(MemUnlock(ptaskHan);)
    MemFree(ptaskHan);
    return;
}

/*********************************************************************
 *			ProgAddRunTask
 *********************************************************************
 * SYNOPSIS:	Add a RunTask to ProgTask
 * CALLED BY:	GLOBAL
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:	
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	2/ 3/95		Initial version			     
 *	mchen	7/13/95	    	Made changes for Liberty
 * 
 *********************************************************************/
void
ProgAddRunTask(PTaskHan ptaskHan, RTaskHan rtaskHan)
{
    ProgTask	*ptask;
    RTaskHan	*moduleArray;

    /* FIXME: doesn't resize moduleArray if necessary, maybe just
     * make it a chunkarray...
     */
    ptask = (ProgTask*)MemLock(ptaskHan);
    moduleArray = (RTaskHan*)MemLock(ptask->PT_tasks);

    moduleArray[ptask->PT_numTasks] = rtaskHan;
#ifdef LIBERTY
    ASSERTS_WARN(ptask->PT_numTasks < (MAX_NUM_LOADED_MODULES - 5),
		 "approaching the limit for number of loaded modules");
    ASSERTS(ptask->PT_numTasks < MAX_NUM_LOADED_MODULES,
	    "too many loaded modules at once");
#endif
    ptask->PT_numTasks++;

    MemUnlock(ptask->PT_tasks);
    MemUnlock(ptaskHan);
}

void
ProgAddDebuggedRunTask(PTaskHan ptaskHan, RTaskHan rtaskHan)
{
    RunTask*	rtask;
    PTaskPtr	ptask;

    rtask = (RunTask*)MemLock(rtaskHan);
    ptask = (PTaskPtr)MemLock(ptaskHan);

    ProgAddRunTask(ptaskHan, rtaskHan);

    /* The builder uses COMPILE_INTERP_RUN_MODULE for non-debugged modules
     */
    if (rtask->RT_bugHandle != NullHandle) {
	/* Can only have one debugged module (currently) */
	ptask->PT_bugHandle = rtask->RT_bugHandle;
	ptask->PT_bugModule = rtask->RT_handle;
    } else {
	ptask->PT_bugHandle = NullHandle;
	ptask->PT_bugModule = NullHandle;
    }

    MemUnlock(ptaskHan);
    MemUnlock(rtaskHan);
}

/*********************************************************************
 *			ProgDestroyZombieRTasks
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/10/96  	Initial version
 * 
 *********************************************************************/
void
ProgDestroyZombieRTasks(PTaskPtr ptask)
{
    word	i;
    RTaskHan*	rtaskArray;
    RunTask*	rtask;
    
    rtaskArray = (RTaskHan*)MemLock(ptask->PT_tasks);

    i = 0;
    while (i < ptask->PT_numTasks)
    {
	Boolean	isZombie;
	rtask = (RunTask*)MemLock(rtaskArray[i]);
	isZombie = (Boolean)(rtask->RT_flags & RT_ZOMBIE);
	MemUnlock(rtaskArray[i]);
	if (isZombie)
	{
	    /* Destroy and replace with last module in array
	     */
	    RunDestroyTask(rtaskArray[i]);
	    ptask->PT_numTasks--;
	    rtaskArray[i] = rtaskArray[ptask->PT_numTasks];
ECG(	    rtaskArray[ptask->PT_numTasks] = 0xdead		);
	}
	else
	{
	    i += 1;
	}

    }
    ptask->PT_flags &= ~PT_HAS_ZOMBIES;
    MemUnlock(ptask->PT_tasks);
    return;
}

#ifndef LIBERTY
/*********************************************************************
 *			ProgGetVMFile
 *********************************************************************
 * SYNOPSIS:	Get VM file from prog
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 2/ 4/95	Initial version			     
 * 
 *********************************************************************/
VMFileHandle
ProgGetVMFile(PTaskHan prog)
{
    ProgTask	*pt;
    VMFileHandle vmfh;

    pt = (ProgTask*)MemLock(prog);
    vmfh = pt->PT_vmFile;
    MemUnlock(prog);
    return vmfh;
}

/*********************************************************************
 *			ProgResetTask
 *********************************************************************
 * SYNOPSIS:	Hack -- clean heap, fido task, etc
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 *	Alloc new heap; clean fido task
 *
 * STRATEGY:
 *	Clean up task so it can be treated like a freshly-allocated
 *	ProgTask.  Used by the builder for lview's interpereter.
 *
 * BUGS:
 *	Nuking the heap shouldn't be necessary once we can make
 *	modules exit cleanly.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	9/ 1/95		Initial version
 * 
 *********************************************************************/
void
ProgResetTask(PTaskHan ptaskHan)
{
    ProgTask*	ptask;
    
    ptask = (ProgTask*)MemLock(ptaskHan);

    /* turn off the HALT bit so things can run again */
    ptask->PT_flags &= ~PT_HALT;
    RunHeapDestroy(&(ptask->PT_runHeapInfo));
    ptask->PT_runHeapInfo = RunHeapCreate();
    FidoCleanTask(ptask->PT_fidoTask);
    
    MemUnlock(ptaskHan);
    return;
}
#endif
