/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Runtime
FILE:		unload.c

AUTHOR:		Paul Du Bois, Mar 13, 1996

ROUTINES:
	Name			Description
	----			-----------
    EXT FunctionUnloadModuleCommon
				Start the module-unloading process for a
				module

    INT UM_CallModuleExits	Call module_exit functions

    INT UM_FindDeadModules	Find all "dead" modules

    INT UM_RemoveChildRefs	Remove modules from children array

    INT UM_NullReferences	Null out component and module references

    INT UM_DestroyComps		Get rid of some components

    INT UM_DestroyModules	Destroy those modules that we can

    EXT ComputeSpaceUsedByRTask	Determines the space used by objects in a
				rtask by summing the sizes of all the
				object blocks owned by the rtask.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	3/13/96  	Initial version.

DESCRIPTION:
	Implements UnloadModule functionality.

	Liberty version control
	$Id: unload.c,v 1.2 98/10/05 12:34:51 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/runheap.h>
#include <Legos/fido.h>
#include <Legos/legtype.h>

#include <Legos/prog.h>
#include <Legos/runtask.h>

#include <Legos/runint.h>
#include <Legos/stack.h>
#include <Legos/ehan.h>
#include <Legos/fixds.h>
#include <Legos/builtin.h>
#include <Legos/computil.h>
#include <data/array.h>

#include <Legos/rheapint.h>
#define IN_UNLOAD_C
#include <Legos/unload.h>

#include <Legos/bstrmap.h>
#include <Legos/bsst.h>
#include <pos/ramalloc.h>   	/* for GetMemoryUsedBy() */
#include <driver/fatalerr.h>   	/* for FatalError() */

#include "legosdb.h"
#include "legoslog.h"

/* just tie ECGMUB to EC_DYNAMIC_LOADED_MODULES for now */
#ifdef EC_DYNAMIC_LOADED_MODULES
#define ECGMUB(a) a
#else
#define ECGMUB(a)
#endif

#else	/* GEOS version below */

#include "mystdapp.h"
#include <lmem.h>
#include <ctype.h>
#include <chunkarr.h>

#include <Legos/basrun.h>
#include <Legos/runheap.h>
#include <Legos/fido.h>
#include <Legos/legtype.h>

#include <Legos/Internal/progtask.h>
#include <Legos/Internal/runtask.h>

#include "runint.h"
#include "stack.h"
#include "ehan.h"
#include "fixds.h"
#include "builtin.h"
#include "computil.h"
#include "prog.h"

/* For enum */
#include "rheapint.h"
#define IN_UNLOAD_C
#include "unload.h"

#endif
#define RMS (*rms)


#ifdef LIBERTY
/***********************************************************************
 *			ChunkArrayAppendNoFail()
 ***********************************************************************
 *
 * SYNOPSIS:	    Does a ChunkArrayAppend and raises a fatal error
 *                  if it fails.
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	matta	11/20/96  	Initial Revision
 *
 ***********************************************************************/
void *
ChunkArrayAppendNoFail(Array* array, int /* unused */)
{
    PARAM_ASSERT(array);
    void *newElement = array->Append();
    if (!newElement) {
	EC_FAIL("ChunkArrayAppendNoFail() fails.");
	FatalErrorDriver::FatalError(OUT_OF_MEMORY_FATAL_ERROR);
    }
    return newElement;
}	/* End of ChunkArrayAppendNoFail() */
#endif /* LIBERTY */


/*********************************************************************
 *			FunctionUnloadModuleCommon
 *********************************************************************
 * SYNOPSIS:	Start the module-unloading process for a module
 * CALLED BY:	EXTERNAL, OP_CALL_PRIMITIVE in runmain.c
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 *	takes one argument, the module to unload.
 *	Modules being unloaded produce errors when unloaded again.
 *
 *	Implements both UnloadModule and DestroyModule.
 *	Destroy will unload a module even if its use count is > 1
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	3/13/96  	Initial version
 * 
 *********************************************************************/
void
FunctionUnloadModuleCommon(register RMLPtr rms, BuiltInFuncEnum id)
{
    RTaskHan	removeMod;


    removeMod = PopData();
    PopTypeV();

    if (removeMod == NullHandle)
    {
	RunSetError(rms->ptask, RTE_BAD_MODULE);
	return;
    }

#if 0
    // theLog << "S";
    return;
#else
    RunUnloadModule(rms, removeMod,
		    (Boolean)(id == FUNCTION_DESTROY_MODULE), 0);
#endif
}

/*********************************************************************
 *			UnloadModule
 *********************************************************************
 * SYNOPSIS:	down and dirty parts of unloading a module
 * CALLED BY:	FunctionUnloadModuleCommon, GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	if rms is NULL, then grab info from the ptask, this
 *		allows this routine to be called without an RMLState
 *
 *	If a non-zero message is passed, send that to interpreter when
 *	unload is finished.

 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/13/96  	Initial version
 * 
 *********************************************************************/
void
RunUnloadModule(void		*rmsPtr,	
		RTaskHan	removeMod,
		Boolean		destroy,
		word		notifyMessage)
{
    RunTask*	tempRTask;
    GONLY(MemHandle	tempLMem);
    GONLY(ChunkArray	moduleOptr);
    GONLY(RTaskHan*	moduleP);
    MemHandle	progTask;
    ArrayOfComponentsHeader comps;
    RMLPtr	rms;
    DS_DECL;

    rms = (RMLPtr)rmsPtr;
    tempRTask = (RunTask*)MemLock(removeMod);

#if (defined(DEBUG_AID) && defined(EC_LOG)) || defined(LEGOS_NONEC_LOG)
    if (theLegosFunctionTraceFlag && theLegosFunctionTraceLog) {
	volatile word usecount, shared;
	usecount = tempRTask->RT_useCount;
	shared = tempRTask->RT_shared;
	ModuleToken mod = tempRTask->RT_fidoModule;
	TCHAR mlbuf[30];
	FidoGetML_withBuffer(mod, mlbuf);
	*theLegosFunctionTraceLog
	    << "UNLOADING " << mlbuf << " refs: " << usecount;
	if (!theLegosFunctionTraceMemoryFlag) { theLog.Flush(); }
    }
#endif

    /* Don't allow unloading of modules being debugged.
     * They should never be "child" modules, so they can only be
     * unloaded by an explicit UnloadModule()
     */
    if (tempRTask->RT_bugHandle != NullHandle)
    {
	EC_WARNING(RW_CANT_UNLOAD_DEBUGGED_MODULE);
	MemUnlock(removeMod);
	return;
    }

    if (tempRTask->RT_flags & RT_UNLOADING)
    {
	MemUnlock(removeMod);
	if (rms != NULL) {
	    RunSetError(rms->ptask, RTE_BEING_UNLOADED);
	}
	return;
    }

    if ((tempRTask->RT_useCount > 1) && destroy)
    {
	/* Guarantee that this module will be unloaded with this call */
	tempRTask->RT_useCount = 1;
    }

#if defined(DEBUG_AID) && defined(EC_LOG) && defined(LIBERTY)
    if (theLegosLoadModuleTraceFlag) {
	ModuleToken mod = tempRTask->RT_fidoModule;
	TCHAR *thisML = FidoGetML(mod);
	theLog << "UNLOADING " << thisML  << '(' << mod << ")\n";
	theLog.Flush(); 
	free(thisML);
    }
#endif

    progTask = tempRTask->RT_progTask;
    MemUnlock(removeMod);

    /* Module should be removed from the caller's child list (if there
     * is a calling rtask), even if the removed module is not unloaded
     * because it has a use count > 1.  This is so because the calling
     * module's reference to the module is going away.  matta 5/25/96
     */
    if (rms != NULL) {
	LONLY(UM_RemoveChildRefs(rms->rtask->RT_handle, tempRTask));
	GONLY(UM_RemoveChildRefs(rms->rtask->RT_handle, &removeMod, 1));
    }

#ifdef LIBERTY
    /* Create a linked list of all modules that will be destroyed.
       List is a pre-order tree traversal. */
    RunTask* tail = NULL;	/* unused */
    RunTask* head = UM_FindDeadModules(removeMod, &tail);

    /* Count will be 0 if removeMod isn't being destroyed */
#if (defined(DEBUG_AID) && defined(EC_LOG)) || defined(LEGOS_NONEC_LOG)
    if (theLegosFunctionTraceFlag && theLegosFunctionTraceLog) {
	if (head == 0) {
	    *theLegosFunctionTraceLog << " no unload\n";
	} else {
	    *theLegosFunctionTraceLog << " unloading\n";
	}
    }
#endif

    if (!head) {
	goto done;
    }

#else /* Geos */

    /* Create an ordered array of all modules that will be destroyed
     * Array is a null-terminated preorder tree traversal
     * count is off by one because of the null termination.
     */
    tempLMem = MemAllocLMem(LMEM_TYPE_GENERAL, 0);
    (void)MemLock(tempLMem);
    moduleOptr = ConstructOptr
	(tempLMem, ChunkArrayCreate(tempLMem, sizeof(RTaskHan),0,0));
    UM_FindDeadModules(removeMod, moduleOptr);
    if (ChunkArrayGetCount(moduleOptr) == 0) goto done;
#endif

    /* Flush cached pointers, in case any of them reference objects
     * in modules that are going away
     */
    BEGIN_USING_CACHED_ARRAY;
    if (cachedArray != NullHandle) {
	MemUnlock(cachedArray);
	cachedArray = NullHandle;
	LONLY(cachedArrayPtr = NULL);
    }
    END_USING_CACHED_ARRAY;

#ifndef LIBERTY
    *(RTaskHan*)ChunkArrayAppendNoFail(moduleOptr, 0) = NullHandle;
    MemUnlock(tempLMem);
#endif


    LONLY(UM_CallModuleExits(rms, head));
    GONLY(UM_CallModuleExits(rms, moduleOptr));

#ifdef LIBERTY
    comps.head = NULL; 
    comps.last = NULL;
    comps.lastTopLevel = NULL;
    Run_GetComponentsToDestroy(NullOptr, head, &comps);

    DS_DGROUP;
    UM_NullReferences(rms, head, &comps, progTask);
    UM_DestroyComps(rms, head, &comps, progTask, notifyMessage);
    UM_DestroyModules(rms, head, progTask);
    DS_RESTORE;
#else
    moduleP = (RTaskHan*)ChunkArrayLock(moduleOptr);
    comps.arrayBlock = NullHandle;
    Run_GetComponentsToDestroy(NullOptr, moduleP, &comps);
    ChunkArrayUnlock(moduleOptr);

    DS_DGROUP;
    UM_NullReferences(rms, moduleOptr, &comps, progTask);
    UM_DestroyComps(rms, moduleOptr, &comps, progTask, notifyMessage);
    UM_DestroyModules(rms, moduleOptr, progTask);
    DS_RESTORE;
#endif

 done:
    /* block in comps will be freed when the components are destroyed */
    GONLY(MemFree(tempLMem));

    return;
}

/*********************************************************************
 *			UM_CallModuleExits
 *********************************************************************
 * SYNOPSIS:	Call module_exit functions
 * CALLED BY:	INTERNAL, FunctionUnloadModuleCommon
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 *	We want to call module_exit on child modules first, then
 *	parent modules.  Since array is a preorder traversal, enum
 *	backwards through it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/ 5/96  	Initial version
 * 
 *********************************************************************/
#ifdef LIBERTY

static void
UM_CallModuleExitsEnumFunction(RunTask* rtask, void*)
{
#if defined(DEBUG_AID) && defined(EC_LOG) && defined(LIBERTY)
    /* Print out that we did it */
    if (theLegosLoadModuleTraceFlag) {
	TCHAR *thisML = FidoGetML(rtask->RT_fidoModule);
	theLog << "Call module_exit on " << thisML  
	       << '(' << rtask->RT_fidoModule << ")\n";
	theLog.Flush(); 
	free(thisML);
    }
#endif

    /* Call module_exit */
    RunCallFunction(rtask->RT_handle, _TEXT("module_exit"), BORK, BORK, BORK);
	
    /* Don't allow any more function calls */
    rtask->RT_flags |= RT_EVENTS_DISABLED;
}

static void
UM_CallModuleExits(RMLPtr rms, RunTask* head)
{
    if (rms != NULL) {
	INT_ON(rms);
    }

    /* Enumerate the tasks in the linked list backwards, calling
       module_exit along the way */
    RunTaskEnumBackwards(head, UM_CallModuleExitsEnumFunction, NULL);

    if (rms != NULL) {
	INT_OFF(rms);
    }
}

#else  /* begin Geos only section, end Liberty only section */

static void
UM_CallModuleExits(RMLPtr rms, ChunkArray moduleArray)
{
    sword	count, i;
    RTaskHan	rtaskHan;
    DS_DECL;

    if (rms != NULL) {
	INT_ON(rms);
    }

    DS_DGROUP;
    (void)MemLock(OptrToHandle(moduleArray));

    count = ChunkArrayGetCount(moduleArray);
    /* Start at -2 because the array is null terminated */
    for (i=count-2; i>=0; i--)
    {
	RunTask*	rtask;
	rtaskHan = ChunkArrayGetElt(moduleArray, RTaskHan, i);
	(void)MemUnlock(OptrToHandle(moduleArray));
	RunCallFunction(rtaskHan, _TEXT("module_exit"), BORK, BORK, BORK);
	
	/* Don't allow any more function calls */
	rtask = (RunTask*)MemLock(rtaskHan);
	rtask->RT_flags |= RT_EVENTS_DISABLED;
	MemUnlock(rtaskHan);

	MemLock(OptrToHandle(moduleArray));
    }

    MemUnlock(OptrToHandle(moduleArray));
    DS_RESTORE;
    if (rms != NULL) {
	INT_OFF(rms);
    }
    return;
}

#endif /* end Geos only section */

/*********************************************************************
 *			UM_FindDeadModules
 *********************************************************************
 * SYNOPSIS:	Find all "dead" modules
 * CALLED BY:	INTERNAL, FunctionUnloadModuleCommon
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Decrement ref count of passed module.
 *	If it goes to zero, append module to moduleArray, recurse on
 *	"child" modules.
 *
 *	Final result is a preorder traversal of tree of modules
 *	that will be going away.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/ 4/96  	Initial version
 * 
 *********************************************************************/
#ifdef LIBERTY
static RunTask*
UM_FindDeadModules(RTaskHan rtaskHan, RunTask** tail)
#else
static void
UM_FindDeadModules(RTaskHan rtaskHan, ChunkArray moduleArray)
#endif
{
    RunTask* rtask = (RunTask*)MemLock(rtaskHan);

    /* Might get this if:
     * A loads B,C.  B,C Require D.  D is unloaded by someone else
     * (D now has use count 1).  Recursion gets to B, D's count -> 0.
     * Recursion gets to D -- D is marked as RT_UNLOADING.  In case
     * you were wondering.
     */
    if (rtask->RT_flags & RT_UNLOADING) goto unlockDone;

    /* Use count should always be > 0.
     * If module is not shared, use count should always be 1
     */
    ASSERT(rtask->RT_bugHandle == NullHandle);
    ASSERT(rtask->RT_useCount != 0);
    ASSERT(! ((rtask->RT_useCount > 1) && (!rtask->RT_shared)));

    /* Be nice; unlock RTask before recursing
     */
#ifdef LIBERTY

    {
	RunTask *head = NULL;
	if (--rtask->RT_useCount == 0) {
	    ChunkArray childArray;
	    word	i, childCount;
	    
	    rtask->RT_flags |= RT_UNLOADING;
	    
	    ASSERT(tail);
	    if (*tail) {
		RunTaskSetNext(*tail, rtask);
	    }
	    head = *tail = rtask;
	    
	    childArray = rtask->RT_childModules;
	    childCount = childArray->GetCount();
	    if (childCount > 0) {
		RTaskHan *childModulesArray = 
		    (RTaskHan*)childArray->LockElement(0);
		for (i=0; i<childCount; i++) {
		    (void) UM_FindDeadModules(childModulesArray[i], tail);
		}
		childArray->UnlockElement(0);
	    }
	    
	} else {
	    MemUnlock(rtaskHan);
	}
	return head;
    }

 unlockDone:
    MemUnlock(rtaskHan);
    return NULL;

#else  /* Geos only below, Liberty only above */

    if (--rtask->RT_useCount == 0)
    {
	ChunkArray childArray;
	word	i, childCount;

	rtask->RT_flags |= RT_UNLOADING;
	*(RTaskHan*)ChunkArrayAppendNoFail(moduleArray, 0) = rtaskHan;

	childArray = rtask->RT_childModules;
	MemUnlock(rtaskHan);

	(void) ChunkArrayLock(childArray);
	childCount = ChunkArrayGetCount(childArray);
	for (i=0; i<childCount; i++)
	{
	    RTaskHan	childMod;
	    childMod = ChunkArrayGetElt(childArray, RTaskHan, i);
	    UM_FindDeadModules(childMod, moduleArray);
	}
	ChunkArrayUnlock(childArray);
    }
    else
    {
	MemUnlock(rtaskHan);
    }
    return;

 unlockDone:
    MemUnlock(rtaskHan);
    return;

#endif /* END Geos only */
}

#ifdef LIBERTY
/*********************************************************************
 *			UM_FindDefinitelyUnloadableModules
 *********************************************************************
 * SYNOPSIS:	Find all the modules that would definitely be unloaded
 *	    	(recursively) ignoring any modules with a reference
 *	    	count > 1 since those might not be unloaded.
 * CALLED BY:	INTERNAL, FunctionGetMemoryUsedBy
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Similar to UM_FindDeadModules except we don't actually touch
 *	the ref counts.
 *
 *	Check ref count of passed module.
 *	If it is 1, append module to moduleArray, recurse on
 *	"child" modules.
 *
 *	Final result is a preorder traversal of tree of modules
 *	that are definitely unloadable and would go away if unloaded.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	7/25/96  	Initial version
 * 
 *********************************************************************/
static void
UM_FindDefinitelyUnloadableModules(RTaskHan rtaskHan, ChunkArray moduleArray)
{
    RunTask* rtask = (RunTask*)MemLock(rtaskHan);

    /* Use count should always be > 0.
     * If module is not shared, use count should always be 1
     */
    ASSERT(rtask->RT_bugHandle == NullHandle);
    ASSERT(rtask->RT_useCount != 0);
    ASSERT(! ((rtask->RT_useCount > 1) && (!rtask->RT_shared)));

    /* Be nice; unlock RTask before recursing
     */
    if (rtask->RT_useCount == 1)
    {
	ChunkArray childArray;
	word	i, childCount;

	*(RTaskHan*)ChunkArrayAppendNoFail(moduleArray, 0) = rtaskHan;
	LONLY(moduleArray->UnlockElement(0));

	childArray = rtask->RT_childModules;
	MemUnlock(rtaskHan);

	childCount = childArray->GetCount();
	if(childCount > 0) {
	    RTaskHan *childModulesArray = 
		(RTaskHan*)childArray->LockElement(0);
	    for (i=0; i<childCount; i++) {
		UM_FindDefinitelyUnloadableModules(childModulesArray[i], 
						   moduleArray);
	    }
	    childArray->UnlockElement(0);
	}
    } else {
	MemUnlock(rtaskHan);
    }

    return;
}
#endif

/*********************************************************************
 *			UM_RemoveChildRefs
 *********************************************************************
 * SYNOPSIS:	Remove modules from children array
 * CALLED BY:	INTERNAL, FunctionUnloadModuleCommon
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Not an error if module isn't in list of loaded modules.
 *	The UnloadModule might have been called somewhere else, so
 *	we just have to handle it gracefully.
 *
 *	This has to be much different in Liberty version because 
 *	Array::Delete() requires the array to be unlocked.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/ 4/96  	Initial version
 * 
 *********************************************************************/
#ifdef LIBERTY
static void
UM_RemoveChildRefs(RTaskHan srcMod, RunTask* taskList)
#else
static void
UM_RemoveChildRefs(RTaskHan srcMod, RTaskHan* removeMods, word numModules)
#endif
{
    RunTask*	rtask;
    ChunkArray	childModules;
    GONLY(RTaskHan*	childArray;)
    GONLY(word	i);
    word  j, childCount;

    rtask = (RunTask*)MemLock(srcMod);
    childModules = rtask->RT_childModules;
    MemUnlock(srcMod);

#ifdef LIBERTY
    /* remove any childModules entries that are in the given
       removeMods array */
    childCount = childModules->GetCount();
    for (j = 0; j < childCount; j++) {
	RTaskHan child = *(RTaskHan*)childModules->LockElement(j);
	childModules->UnlockElement(j);
	if (RunTaskInList(taskList, child)) {
	    childModules->Delete(j);
	    break;
	}
    }
#else
    (void)ChunkArrayLock(childModules);
    childArray = ChunkArrayElementToPtr(childModules, 0, NULL);

    for (i=0; i<numModules; i++)
    {
	childCount = ChunkArrayGetCount(childModules);
	for (j=0; j<childCount; j++)
	{
	    if (childArray[j] == removeMods[i])
	    {
		/* We're guaranteed that it only occurs once
		 * in the child array -- see RequireModule
		 */
		ChunkArrayDelete(childModules, &childArray[j]);
		break;
	    }
	}
    }

    ChunkArrayUnlock(childModules);
#endif
    return;
}

/*********************************************************************
 *			UM_NullReferences
 *********************************************************************
 * SYNOPSIS:	Null out component and module references
 * CALLED BY:	INTERNAL
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 *	REQUIRES DS = DGROUP
 *
 *	1. Initial set up
 *	2. Null out destroyed modules/components in global scopes
 *	3. Null out in local scopes/stack
 *	4. Null out in RT_childModule arrays
 *	5. Null out in runtime heap
 *	6. Null out in component properties	XXX
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/ 8/96  	Initial version
 * 
 *********************************************************************/
#ifdef LIBERTY
static void
UM_NullReferences(RMLPtr rms, RunTask* headRunTask, 
		  ArrayOfComponentsHeader* comps, MemHandle progTask)
#else /* Geos */
static void
UM_NullReferences(RMLPtr rms, ChunkArray moduleOptr, 
		  ArrayOfComponentsHeader* comps, MemHandle progTask)
#endif
{
    RTaskHan*	taskArray;
    UnloadData	ud;
    word	i, numTasks;
    ProgTask	*ptask;
    byte*	typeCursor;
    dword*	dataCursor;

    /* 1. Lock arrays
     */
    if (rms == NULL) {
	ptask = (ProgTask*)MemLock(progTask);
    } else {
	ptask = rms->ptask;
    }
    taskArray = (RTaskHan*)MemLock(ptask->PT_tasks);
    numTasks = ptask->PT_numTasks;

#ifdef LIBERTY
    ud.headComponent = comps->head;
    ud.headRunTask = headRunTask;
#else
    ud.compArray = (optr*)MemLock(comps->arrayBlock);
    ud.numComps = comps->numElements;
    ud.moduleArray = (RTaskHan*)ChunkArrayLock(moduleOptr);
    ud.numModules = ChunkArrayGetCount(moduleOptr)-1; /* null terminated */
#endif

    /* 2. Do module variables
     */
    for (i=0; i<numTasks; i++)
    {
	RunTask* rtask;
	byte*	varTypes;
	dword*	varData;
	word	num_vars;

	rtask = (RunTask*)MemLock(taskArray[i]);
	if (rtask->RT_moduleVars == NullHandle) {
	    MemUnlock(rtask->RT_handle);
	    continue;
	}

	LOCK_GLOBALS(rtask->RT_moduleVars, varTypes, varData);
	num_vars = NUM_GLOBALS_FAST(varTypes);
	
	CheckScope(varTypes, varData, num_vars, &ud);
	MemUnlock(rtask->RT_moduleVars);
	MemUnlock(rtask->RT_handle);
    }

    /* 2.5. Do internal cached data in ptask
     */
    CheckModule(&ptask->PT_bugModule, &ud);
    if (ptask->PT_bugModule == NullHandle) {
	ptask->PT_bugHandle = NullHandle;
    }

    /* 3. Do stack
     */
    dataCursor = rms->spData;
    if (rms == NULL) {
	/* don't think this is right
	 * stack is never checked if unload called from c code?
	 * This is right because when its called from C, there is no
	 * stack
	 */
	typeCursor = rms->typeStack;
    } else {
	typeCursor = rms->spType;
    }

    while (typeCursor > rms->typeStack)
    {
	switch (typeCursor[-1])
	{
	case TYPE_COMPONENT:
	    typeCursor--;
	    dataCursor--;
	    UM_CheckComponent((optr*)dataCursor, &ud);
	    break;

	case TYPE_MODULE:
	    typeCursor--;
	    dataCursor--;
	    CheckModule((RTaskHan*)dataCursor, &ud);
	    break;

	case TYPE_ARRAY:
	    typeCursor--;
	    dataCursor--;
	    CheckArray((MemHandle)*dataCursor, &ud);
	    break;

	default:
	    typeCursor--;
	    dataCursor -= EH_DataSizes[*typeCursor];
	    break;
	}
    }

    /* 4. Do child arrays
     */
    for (i=0; i<numTasks; i++)
    {
	LONLY(UM_RemoveChildRefs(taskArray[i], ud.headRunTask));
	GONLY(UM_RemoveChildRefs(taskArray[i], ud.moduleArray, ud.numModules));
    }

    /* 5. Do runheap
     */
    RunHeapEnum(&(ptask->PT_runHeapInfo), RHT_STRUCT,
		(RunHeapCB)CheckStruct, &ud);

    /* 6. Do component properties and such
     */
#ifdef LIBERTY
    Run_CallRemoveReferences(ud.headComponent, ud.headRunTask);
#else
    Run_CallRemoveReferences(ud.compArray, ud.moduleArray);
#endif

    /* N. Unlock stuff
     */
    GONLY(ChunkArrayUnlock(moduleOptr));
    GONLY(MemUnlock(comps->arrayBlock));
    MemUnlock(ptask->PT_tasks);
    if (rms == NULL) {
	MemUnlock(progTask);
    }
}

/* Use this when type and data areas are separate */
static void CheckScope(byte* varTypes, dword* varData,
		       word num_vars, UnloadData* ud)
{
    word i;

    for (i=0; i<num_vars; i++)
    {
	switch (varTypes[i])
	{
	case TYPE_COMPONENT:
	    UM_CheckComponent((optr*)&varData[i], ud);
	    break;

	case TYPE_MODULE:
	    CheckModule((RTaskHan*)&varData[i], ud);
	    break;

	case TYPE_ARRAY:
	    CheckArray((MemHandle)varData[i], ud);
	    break;

	default:
	    break;
	}
    }
}

static void CheckStruct(byte* vars, word num_vars, UnloadData* ud)
{
    word i;
    optr	tmpOptr;
    RTaskHan	tmpModule;
    MemHandle	tmpArray;

    /* Kludgy, yes; hopefully temporary */
    for (i=0; i<num_vars; i++)
    {
	switch (vars[4])
	{
	case TYPE_COMPONENT:
	    CopyDword(&tmpOptr, vars);
	    UM_CheckComponent(&tmpOptr, ud);
	    CopyDword(vars, &tmpOptr);
	    break;

	case TYPE_MODULE:
	    CopyDword(&tmpModule, vars);
	    CheckModule(&tmpModule, ud);
	    CopyDword(vars, &tmpModule);
	    break;

	case TYPE_ARRAY:
	    CopyDword(&tmpArray, vars);
	    CheckArray(tmpArray, ud);
	    break;

	default:
	    break;
	}
	vars += 5;		/* VAR_SIZE */
    }
}

#ifndef LIBERTY
/* Liberty version lives in computil.cpp */
void UM_CheckComponent(optr* tempOptr, UnloadData* ud)
{
    word	i;
    if (*tempOptr != NullOptr) {
	for (i=0; i<ud->numComps; i++) {
	    if (*tempOptr == ud->compArray[i]) {
		*tempOptr = NullOptr;
		break;
	    }
	}
    }
    return;
}
#endif

static void CheckModule(RTaskHan* tempModule, UnloadData* ud)
{

    if (*tempModule != NullHandle) {
#ifdef LIBERTY
	RunTask* curr = ud->headRunTask;
	while (curr) {
	    if (*tempModule == curr->RT_handle) {
		*tempModule = NullHandle;
		break;
	    }
	    curr = curr->RT_next;
	}
#else /* Geos only below, Liberty only above */
	word	i;
	for (i=0; i<ud->numModules; i++) {
	    if (*tempModule == ud->moduleArray[i]) {
		*tempModule = NullHandle;
		break;
	    }
	}
#endif /* Geos only above */
    }
    return;
}

static void CheckArray(MemHandle tempHan, UnloadData* ud)
{
    ArrayHeader* lah;
    word	i;

    if (tempHan == NullHandle) {
	return;
    }

    lah = (ArrayHeader*)MemLock(tempHan);

    ASSERT(lah->AH_type != TYPE_ARRAY);
    switch (lah->AH_type)
    {
    case TYPE_MODULE:
    {
	RTaskHan*	cursor;

	for (i=0, cursor=(RTaskHan*)(lah+1); i<lah->AH_maxElt; i++, cursor++)
	{
	    CheckModule(cursor, ud);
	}
	break;
    }

    case TYPE_COMPONENT:
    {
	optr*	cursor;

	for (i=0, cursor=(optr*)(lah+1); i<lah->AH_maxElt; i++, cursor++)
	{
	    UM_CheckComponent(cursor, ud);
	}
	break;
    }

    default:
	break;
    }
    
    MemUnlock(tempHan);
    return;
}

/*********************************************************************
 *			UM_DestroyComps
 *********************************************************************
 * SYNOPSIS:	Get rid of some components
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	This is no longer synchronous; it puts a message on the queue
 *	so components will be destroyed later.
 *
 *	Create new block, with two chunkarrays
 *	- optrs of top level objects
 *	- ObjBlocks of all modules that are being destroyed
 *
 *	Null out array of object blocks in the modules, so that they
 *	don't get destroyed with the modules.
 *
 *	Null out FidoTask in the modules so any DLLs loaded don't get
 *	freed before components have a chance to destroy themselves.
 *
 *	If a non-zero message is passed, send that to interpreter when
 *	unload is finished.
 *
 * BUGS/IDEAS:
 *	Only null out fido task if module has loaded a new DLL component
 *	library; that's the only case where it needs to be destroyed after
 *	destroying the components.  In all other cases it's probably better
 *	to free as much as possible before we return from UnloadModule.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/ 8/96  	Initial version
 * 
 *********************************************************************/
#ifdef LIBERTY
static void
UM_DestroyComps(RMLPtr rms, 
		RunTask* taskList,
		ArrayOfComponentsHeader* comps, 
		MemHandle progTask,
		word notifyMessage)
{
    USE_IT(rms);
    USE_IT(progTask);
    USE_IT(notifyMessage);

    /* Generate a list of dynamically loaded modules.  They may depend
       on DLLs, which must be deleted in a delayed way (just like
       components) becaues they may have functions on the stack. */

    ModuleToken firstFidoModule = NULL_MODULE;
    ModuleToken lastFidoModule = NULL_MODULE;
    RunTask *curr = taskList;
    while (curr) {
	/* only add non-XIP modules, XIP modules should be able to be
	   closed immediately since they do not depend on dll libraries */
	if ( ! LIBERTY_XIP_MODULE(curr)) {
	    ASSERT(curr->RT_fidoModule != NULL_MODULE);
	    ASSERT(FidoModuleGetNextToken(curr->RT_fidoModule) == 
		   NULL_MODULE);
	    if (firstFidoModule == NULL_MODULE) {
		firstFidoModule = lastFidoModule = curr->RT_fidoModule;
	    } else {
		FidoModuleSetNextToken(lastFidoModule, curr->RT_fidoModule);
		lastFidoModule = curr->RT_fidoModule;
	    }
	    curr->RT_fidoModule = NULL_MODULE;
	}
	curr = curr->RT_next;
    }
    
    Run_SendDestroyComponents(firstFidoModule, comps->head);
    comps->head = NULL;
}
#else /* GEOS */
static void
UM_DestroyComps(RMLPtr rms, 
		ChunkArray moduleArray,
		ArrayOfComponentsHeader* comps, 
		MemHandle progTask,
		word notifyMessage)
{
    MemHandle	destroyBlock;
    ChunkArray	compArray, allBlockArray, fidoModuleArray;
    ProgTask	*ptask;

    destroyBlock = MemAllocLMem(LMEM_TYPE_GENERAL, 0);
    (void)MemLock(destroyBlock);

    ;{				/* create and populate array of comps */
	optr*	compP;
	word	i;
	compArray = ConstructOptr
	    (destroyBlock, ChunkArrayCreate(destroyBlock, sizeof(optr),0,0));
	compP = MemLock(comps->arrayBlock);
	for (i=0; i<comps->numTopLevelComps; i++) {
	    *(optr*)ChunkArrayAppend(compArray,0) = compP[i];
	}
	/* we are done with this now */
	MemFree(comps->arrayBlock);
    }

    ;{				/* create and populate array of obj blocks
				 * and fido tasks */
	MemHandle*	moduleP;
	word		i,moduleCount;

	allBlockArray = ConstructOptr
	    (destroyBlock, ChunkArrayCreate(destroyBlock,
					    sizeof(MemHandle),0,0));
	fidoModuleArray = ConstructOptr
	    (destroyBlock, ChunkArrayCreate(destroyBlock,
					    sizeof(ModuleToken),0,0));

	/* Array includes a trailing NULL */
	moduleP = ChunkArrayLock(moduleArray);
	moduleCount = ChunkArrayGetCount(moduleArray)-1;
	for (i=0; i<moduleCount; i++) {
	    RunTask*	rtask;
	    ChunkArray	blockArray;
	    MemHandle*	blockP;
	    word	j, blockCount;

	    rtask = MemLock(moduleP[i]);
	    blockArray = rtask->RT_uiBlocks;
	    rtask->RT_uiBlocks = NullOptr;
	    *(ModuleToken*)
		ChunkArrayAppend(fidoModuleArray,0) = rtask->RT_fidoModule;
	    rtask->RT_fidoModule = NULL_MODULE;
	    MemUnlock(rtask->RT_handle);
	    
	    blockP = ChunkArrayLock(blockArray);
	    blockCount = ChunkArrayGetCount(blockArray);
	    for (j=0; j<blockCount; j++) {
		*(MemHandle*)ChunkArrayAppend(allBlockArray,0) = blockP[j];
	    }
	    LMemFree(blockArray);
	    MemUnlock(OptrToHandle(blockArray));
	}
	ChunkArrayUnlock(moduleArray);
    }
    MemUnlock(destroyBlock);

    if (rms == NULL) {
	ptask = MemLock(progTask);
    } else {
	ptask = rms->ptask;
    }
    Run_SendDestroyComponents
	(ptask->PT_interpreter, compArray, allBlockArray,
	 fidoModuleArray, notifyMessage);
    if (rms == NULL) {
	MemUnlock(progTask);
    }
}
#endif /* end GEOS */

/*********************************************************************
 *			UM_DestroyModules
 *********************************************************************
 * SYNOPSIS:	Destroy those modules that we can
 * CALLED BY:	INTERNAL FunctionUnloadModuleCommon
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	REQUIRES DS = DGROUP (EH_TypeSizes)
 *
 *	Any modules that cannot be destroyed (still executing code)
 *	are marked for future destruction, by setting their RT_ZOMBIE
 *	bit.  If we find any zombies, set a flag in the ptask so we
 *	know to destroy them the next time the interpreter goes idle.
 *
 *	Logic is complicated slightly because we can be called from
 *	both within and without the interpreter.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/ 8/96  	Initial version
 * 
 *********************************************************************/
#ifdef LIBERTY

typedef RunTask* RunTaskPtr;

static Boolean
MoveItemIfInList(RunTaskPtr& fromHead,	/* Head of the from list */
		 RunTaskPtr& toHead,	/* Destination list */
		 RTaskHan matchTask)	/* Item to match in from list */
{
    if (!fromHead) {
	return FALSE;
    }

    RunTask* curr = fromHead;
    RunTask* prev = NULL;

    while (curr) {
	if (curr->RT_handle == matchTask) {
	    /* Save next of fromMove */
	    RunTask* currNext = RunTaskGetNext(curr);

	    /* Add fromMove to the list described by toHead */
	    RunTaskSetNext(curr, toHead);
	    toHead = curr;

	    /* Remove fromMove from the list described by fromHead and
	       fromPrev */
	    if (curr == fromHead) {
		ASSERT(prev == NULL);
		fromHead = currNext;
	    } else {
		ASSERT(prev != NULL);
		RunTaskSetNext(prev, currNext);
	    }
	    return TRUE;
	}
	prev = curr;
	curr = curr->RT_next;
    }
    return FALSE;
}

static void
UM_DestroyModules(RMLPtr rms, 
		  RunTask* taskList, 
		  MemHandle progTask)
{
    byte	*typeCursor, *typeStack;
    dword*	dataCursor;
    ProgTask	*ptask;

    RTaskHan	currentModule;

    /* Mark all modules that have code currently executing. Check the
     * currently-running module, and all the return addresses on the
     * stack. */

    /* Set up typeCursor, dataCursor, typeStack, currentModule.  The
     * rest of the function shouldn't need to rely on rms.
     */
    if (rms != NULL)
    {
	typeCursor = rms->spType;
	dataCursor = rms->spData;

	typeStack = rms->typeStack;
	ptask = rms->ptask;
	currentModule = rms->rtask->RT_handle;
    }
    else
    {
	dword*	dataStack;

	ptask = (ProgTask*)MemLock(progTask);
	typeStack = (byte*)MemLock(ptask->PT_stack);
	dataStack = (dword*)(typeStack + ptask->PT_stackLength);
	ASSERT_ALIGNED(dataStack);

	typeCursor = typeStack + ptask->PT_vspType;
	dataCursor = dataStack + ptask->PT_vspData;
	currentModule = ptask->PT_context.FC_module;
    }

    RunTask* zombieList = NULL;

    /* Check module of current function */
    MoveItemIfInList(taskList, zombieList, currentModule);

    /* Check module of all return contexts on stack */
    while (typeCursor > typeStack)
    {
	RTaskHan	rtaskHan;
	
	if (typeCursor[-1] == TYPE_FRAME_CONTEXT)
	{
	    rtaskHan = ((FrameContext*)dataCursor)[-1].FC_module;
	    MoveItemIfInList(taskList, zombieList, rtaskHan);
	}

	typeCursor--;
	ASSERT(*typeCursor < TYPE_NUM_TYPES);
	ASSERT(EH_DataSizes[*typeCursor] != 0xff);
	dataCursor -= EH_DataSizes[*typeCursor];
    }

    /* Destroy all the dead tasks */
    RunTask* dead = taskList;
    while (dead) {
	RunTask *next = RunTaskGetNext(dead);
	RTaskHan rTaskHan = dead->RT_handle;
	MemUnlock(rTaskHan);
	ProgDestroyRunTask(ptask->PT_handle, rTaskHan);
	dead = next;
    }

    /* Mark all the zombie tasks */
    RunTask* zombie = zombieList;
    while (zombie) {	
	zombie->RT_shared = FALSE;
	zombie->RT_flags |= RT_ZOMBIE;
	ptask->PT_flags |= PT_HAS_ZOMBIES;
	RunTask* next = RunTaskGetNext(zombie);
	MemUnlock(zombie->RT_handle);
	zombie = next;
    }

    if (rms == NULL) {
	MemUnlock(ptask->PT_stack);
	MemUnlock(progTask);
    }
}

#else /* GEOS */

/* Geos handles always have the low 3 bits clear */
#define MARK_BITS 7
#define IS_MARKED(handle) (((handle) & MARK_BITS) == 7)

static void
UM_DestroyModules(RMLPtr rms, 
		  ChunkArray moduleOptr, 
		  MemHandle progTask)
{
    word	i, numModules;
    RTaskHan*	moduleArray;
    byte	*typeCursor, *typeStack;
    dword*	dataCursor;
    ProgTask	*ptask;

    RTaskHan	currentModule;

    moduleArray = (RTaskHan*)ChunkArrayLock(moduleOptr);
    numModules = ChunkArrayGetCount(moduleOptr)-1; /* Null-terminated */

    /* Mark all modules that have code currently executing
     * Check the currently-running module, and all the return
     * addresses on the stack.
     */

    /* Set up typeCursor, dataCursor, typeStack, currentModule.
     * The rest of the function shouldn't need to rely on rms.
     */
    if (rms != NULL)
    {
	typeCursor = rms->spType;
	dataCursor = rms->spData;

	typeStack = rms->typeStack;
	ptask = rms->ptask;
	currentModule = rms->rtask->RT_handle;
    }
    else
    {
	dword*	dataStack;

	ptask = (ProgTask*)MemLock(progTask);
	typeStack = (byte*)MemLock(ptask->PT_stack);
	dataStack = (dword*)(typeStack + ptask->PT_stackLength);
	ASSERT_ALIGNED(dataStack);

	typeCursor = typeStack + ptask->PT_vspType;
	dataCursor = dataStack + ptask->PT_vspData;
	currentModule = ptask->PT_context.FC_module;
    }


    /* Check module of current function */
    for (i=0; i<numModules; i++)
    {
	if (currentModule == moduleArray[i]) {
	    /* Mark by setting low bits -- should work in liberty */
	    ASSERT(!IS_MARKED(moduleArray[i]));
	    moduleArray[i] ^= MARK_BITS;
	}
    }

    /* Check module of all return contexts on stack */
    while (typeCursor > typeStack)
    {
	RTaskHan	rtaskHan;
	
	if (typeCursor[-1] == TYPE_FRAME_CONTEXT)
	{
	    rtaskHan = ((FrameContext*)dataCursor)[-1].FC_module;
	    for (i=0; i<numModules; i++)
	    {
		if (rtaskHan == moduleArray[i]) {
		    /* Mark by setting low bits -- should work in liberty */
		    ASSERT(!IS_MARKED(moduleArray[i]));
		    moduleArray[i] ^= MARK_BITS;
		}
	    }
	}

	typeCursor--;
	ASSERT(*typeCursor < TYPE_NUM_TYPES);
	ASSERT(EH_DataSizes[*typeCursor] != 0xff);
	dataCursor -= EH_DataSizes[*typeCursor];
    }

    for (i=0; i<numModules; i++)
    {	
	if (IS_MARKED(moduleArray[i]))
	{
	    RunTask*	rtask;
	    moduleArray[i] ^= MARK_BITS;
	    rtask = (RunTask*)MemLock(moduleArray[i]);
	    rtask->RT_shared = FALSE;
	    rtask->RT_flags |= RT_ZOMBIE;
	    ptask->PT_flags |= PT_HAS_ZOMBIES;
	    MemUnlock(moduleArray[i]);
	} else {
	    ProgDestroyRunTask(ptask->PT_handle, moduleArray[i]);
	}
    }

    if (rms == NULL) {
	MemUnlock(ptask->PT_stack);
	MemUnlock(progTask);
    }
    ChunkArrayUnlock(moduleOptr);
    return;
}

#endif /* ifdef LIBERTY */


/*********************************************************************
 *			FunctionGetMemoryUsedBy
 *********************************************************************
 * SYNOPSIS:	Determines the space used by objects in a rtask by
 *		summing the sizes of all the object blocks owned by
 *		the rtask.
 * CALLED BY:	EXTERNAL
 * PASS:	TYPE_MODULE		Task to check
 * RETURN:	TYPE_LONG		Number of bytes used
 * SIDE EFFECTS:
 * STRATEGY:
 *      1. Possibly inaccurate but quick tally of object size
 *      2. Size of module variables (treat arrays specially)
 *      3. Other random blocks in the task
 *      4. Size of task itself
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	ron	4/3/96   	Initial version
 *	mchen	7/25/96	    	Added Liberty implementation
 * 
 *********************************************************************/
void
FunctionGetMemoryUsedBy(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvMod;

    RunTask*	rtask;
    GONLY(optr	block_array;)
    sdword	totalSize = 0;
    int		count;
    GONLY(MemHandle*	blockP;)

    USE_IT(id);

    if (TopType() != TYPE_MODULE) {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_MODULE);
	return;
    }

    PopVal(rvMod);
    if ((MemHandle)rvMod.value == NullHandle) {
	RunSetError(rms->ptask, RTE_VALUE_IS_NULL);
	return;
    }
#ifdef LIBERTY
    ECGMUB(int lastSize = 0;)

    /* 0. Get list of modules that would definitely be unloaded if this
     *    module is unloaded.  This list is a list of RTaskHan, and includes
     *    the target module 
     */

    Array *moduleArray = new Array(sizeof(RTaskHan), FALSE);
    EC(HeapSetTypeAndOwner(moduleArray, "FDUM"));
    UM_FindDefinitelyUnloadableModules(rvMod.value, moduleArray);

    /* add a NullHandle at end as marker */
    *(RTaskHan*)ChunkArrayAppendNoFail(moduleArray, 0) = NullHandle;
    moduleArray->UnlockElement(0);

    RTaskHan *moduleP = (RTaskHan*)moduleArray->LockElement(0);

    /* 1. Object sizes - this gets the size of all components of this
     *    module and all modules that would definitely be unloaded if this
     *    module is unloaded (non-definite modules would be descendent
     *    modules which were shared and have a ref count > 1)
     */

    totalSize += Run_GetSizeOfComponents(moduleP);

    ECGMUB(printf("Run_GetSizeOfComponents() returned %d\n", totalSize);)
    ECGMUB(lastSize = totalSize;)

    /* 2. For each of the modules which are definitely unloadable, find
     *	  (a) the size of the module variables, not including RunHeap
     *        values but do count arrays
     *    (b) the size of the string const table
     *    (c) the size of the function info table 
     *    (d) the size of the function string name table
     *    (e) the size of the export table
     *    (f) the size of the struct info block
     *    (g) the size of the child module table
     *    (h) the size of the topLevelComponents array
     *    (i) the size of the RunTask itself
     */

    for (count = 0; (uint32)count < moduleArray->GetCount()-1; count++) {
	rtask = (RunTask*)MemLock(moduleP[count]);

	/* 2a. Size of module variables */
	if (rtask->RT_moduleVars != NullHandle)
	{
	    byte*	varTypes;
	    dword*	varData;
	    dword	size_vars;
	    word	num_vars, i;

	    LOCK_GLOBALS(rtask->RT_moduleVars, varTypes, varData);
	    num_vars = NUM_GLOBALS_FAST(varTypes);
	    size_vars = (dword)(CEILING_DWORD(sizeof(word) + num_vars)+(num_vars << 2));
	    totalSize += size_vars;

	    for(i=0; i<num_vars; i++) {
		if (varTypes[i] == TYPE_ARRAY) {
		    if (varData[i] != NullHandle) {
			void *arrayBlock = (void*)LockH(varData[i]);
			totalSize += theHeap.GetAllocatedSize(arrayBlock);
		    	UnlockH(varData[i]);
		    }
		}
	    }
	    MemUnlock(rtask->RT_moduleVars);
	    ECGMUB(printf("moduleVars for rTaskHan %d was %d bytes\n",moduleP[count],totalSize-lastSize);)
	    ECGMUB(lastSize = totalSize;)

	}
    
    	/* 2b. the size of the string const table */
	totalSize += StrMapGetMemoryUsedBy(rtask->RT_strConstMap);
	ECGMUB(printf("string const table for rTaskHan %d was %d bytes\n",moduleP[count],totalSize-lastSize);)
	ECGMUB(lastSize = totalSize;)

    	/* 2c. the size of the function info table and the loaded function
	 *     pages
	 */
	totalSize += FunTabGetMemoryUsedBy(&rtask->RT_funTabInfo);
	ECGMUB(printf("funTab for rTaskHan %d was %d bytes\n",moduleP[count],totalSize-lastSize);)
	ECGMUB(lastSize = totalSize;)

    	/* 2d. the size of the function string name table */
	totalSize += SSTGetMemoryUsedBy(rtask->RT_stringFuncTable,
					rtask->RT_stringFuncCount);
	ECGMUB(printf("strFuncTable for rTaskHan %d was %d bytes\n",moduleP[count],totalSize-lastSize);)
	ECGMUB(lastSize = totalSize;)

    	/* 2e. the size of the export table */
	totalSize += SSTGetMemoryUsedBy(rtask->RT_exportTable,
					rtask->RT_exportTableCount);
	ECGMUB(printf("exportTable for rTaskHan %d was %d bytes\n",moduleP[count],totalSize-lastSize);)
	ECGMUB(lastSize = totalSize;)

    	/* 2f. the size of the struct info block */
    	if(theHeapDataMap.ValueIsHandle(rtask->RT_structInfo)) {
	    void *exportBlock = (void*)LockH(rtask->RT_structInfo);
	    totalSize += theHeap.GetAllocatedSize(exportBlock);
	    UnlockH(rtask->RT_structInfo);

	    ECGMUB(printf("structInfo for rTaskHan %d was %d bytes\n",moduleP[count],totalSize-lastSize);)
	    ECGMUB(lastSize = totalSize;)
	}

    	/* 2g. the size of the child module table */
    	totalSize += rtask->RT_childModules->GetCount() * sizeof(RTaskHan);
    	totalSize += sizeof(Array);	    	/* we ignore malloc overhead */
	ECGMUB(printf("childModules for rTaskHan %d was %d bytes\n",moduleP[count],totalSize-lastSize);)
	ECGMUB(lastSize = totalSize;)

	/* 2h. the size of the array of TopLevelComponents, which is
	 *     RT_topLevelCount * sizeof(Component*), since we don't
         *     want to include class Component, we just use 4 as the
         *     pointer size
         */
	totalSize += rtask->RT_topLevelCount * 4;
	ECGMUB(printf("topLevelComp for rTaskHan %d was %d bytes\n",moduleP[count],totalSize-lastSize);)
	ECGMUB(lastSize = totalSize;)

    	/* 2i. the size of the RunTask itself */
    	totalSize += sizeof(RunTask);
	ECGMUB(printf("runTask for rTaskHan %d was %d bytes\n",moduleP[count],totalSize-lastSize);)
	ECGMUB(lastSize = totalSize;)

    	/* NOTE: we don't count the Fido overhead for tracking the an open
	   module */

	MemUnlock(moduleP[count]);
    }

    moduleArray->UnlockElement(0);
    delete moduleArray;

#else	/* GEOS version below */

    rtask = (RunTask*)MemLock(rvMod.value);

    GONLY(block_array = rtask->RT_uiBlocks;)
    GONLY(MemLock(OptrToHandle(block_array));)

    /* 1. Object sizes
     */
    count = ChunkArrayGetCount(block_array);
    blockP = ChunkArrayElementToPtr(block_array, 0, NULL);
    for (; count; count--, blockP++)
    {
EC(	ECCheckLMemHandle(*blockP)	);
	totalSize += MemGetInfo(*blockP, MGIT_SIZE);
    }
    MemUnlock(OptrToHandle(block_array));


    /* 2. Size of module variables
     */
    if (rtask->RT_moduleVars != NullHandle)
    {
	byte*	varTypes;
	dword*	varData;
	word	num_vars, size_vars, i;
	MemHandle tmp_array;

	LOCK_GLOBALS(rtask->RT_moduleVars, varTypes, varData);
	num_vars = NUM_GLOBALS_FAST(varTypes);
	size_vars = CEILING_DWORD(sizeof(word) + num_vars) + (num_vars << 2);
	totalSize += size_vars;

	for(i=0; i<num_vars; i++) {
	    if (varTypes[i] == TYPE_ARRAY) {
		if (varData[i] != NullHandle) {
		    totalSize += MemGetInfo(varData[i], MGIT_SIZE);
		}
	    }
	}
	MemUnlock(rtask->RT_moduleVars);
    }

    /* 3. Other random blocks
     */
    totalSize += MemGetInfo(rtask->RT_sstBlock, MGIT_SIZE);
    totalSize += MemGetInfo(rtask->RT_strConstMap, MGIT_SIZE);

    /* 4. Task itself
     */
    totalSize += sizeof(RunTask);

    MemUnlock(rtask->RT_handle);
#endif

    PushTypeData(TYPE_LONG, totalSize);
}




