/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		RunTask manipulation, Fido interface
FILE:		runtask.c

AUTHOR:		Paul L. DuBois, Jan  3, 1995

ROUTINES:
	Name			Description
	----			-----------
    EXT RunAllocTask		Create a RunTask using passed VM file
				handle

    EXT RunAllocTaskXIP		Create a RunTask with module code that is
				XIP

    INT RunDestroyModuleVariables
				a routine to clean up a module scope

    EXT RunDestroyTask		Kill off a runtime task

    GLB RunSetURL		Set URL for a RunTask, if RunLoadModule
				wasn't used to create

    EXT RunInitRTaskFromModule	Given a runtask and a url, fill in the
				runtask with compiled module code from the
				URL.

    GLB RunLoadModule		Load, RunTopLevel a URL.  Add new RunTask
				to ProgTask

    EXT RunLoadModuleLow	Load, RunTopLevel a URL.  Add new RunTask
				to ProgTask

    EXT RunReadPage		Load page from current module

    INT Page_ParseHeader	Initialize RunTask from a header block

    INT Page_ParseStructInfo	Extract struct info from header

    INT Page_ParsePage		Top-level page parsing routine

    INT Page_ParseSTable	Read in a string table

    INT Page_ParseFunc		Extract a function from a page

    EXT RunTaskGetVMFile	Returns the vm file from the runtask.

    GLB RunGetFidoTask		Extract fidotask from rtask

    GLB RunSetBuildTime		set a run task to use buildtime components

    GLB RunGetProgHandleFromRunTask
				fetch the program handle from a runtask

    EXT RunSetTop		set the top ui object to a new object

    GLB RunNullRTaskCode	Remove references to items in a compile
				task

    GLB RunTaskSetFlags		set the flags of a run task

    GLB RunTaskGetFlags		get flags

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	dubois	 1/ 3/95	Initial version.

DESCRIPTION:
	Contains routines to create, initialize, modify, destroy
	runtime tasks; these are replacements for RunNewTask.


	Liberty version control
	$Id: runtask.c,v 1.2 98/10/05 12:48:27 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/runint.h>
#include <Legos/fido.h>
#include <Legos/sst.h>
#include <Legos/funtab.h>
#include <Legos/strmap.h>
#include <Legos/fixds.h>
#include <Legos/fformat.h>
#include <pos/ramalloc.h>	/* For GetMemoryUsedBy() */

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

#include <driver/keyboard/tchar.h>
#include <data/array.h>

#else	/* GEOS version below */

#include <Ansi/string.h>
#include "mystdapp.h"
#include "runint.h"
#include <uDialog.h>
#include <geoMisc.h> /* conflicts with Ansi/string.h */ 
#include <chunkarr.h>
#include <hugearr.h>
#include <Legos/fido.h>
#include <Legos/Internal/fformat.h>
#include <ec.h>
#include "sst.h"
#include "funtab.h"
#include "bugext.h"
#include "strmap.h"
#include "fixds.h"

#if ERROR_CHECK
typedef struct
{
    ChunkArrayHeader	ECAH_meta;
    char		ECAH_tag[4];
} ECChunkArrayHeader;

#define ECChunkArrayInitTag(_carray,_str)		\
do {							\
  ECChunkArrayHeader* ecah = LMemDeref(_carray);	\
  memcpy(ecah->ECAH_tag, _str, 4);			\
} while (0)
#else
#define ECChunkArrayHeader ChunkArrayHeader
#define ECChunkArrayInitTag(_carray,_str)
#endif

#endif

static void	RunDestroyModuleVariables(RTaskHan rtask, Boolean decRef);

word Page_ParseHeader(RunTask* rtask, MemHandle headerHandle);
#ifdef LIBERTY
Boolean Page_ParsePage(RunTask* rtask, MemHandle pageHan, word& pos);
#else
Boolean Page_ParsePage(RunTask* rtask, MemHandle pageHan, word pos);
#endif
word Page_ParseFunc(RunTask* rtask, byte* page, word pos);
word Page_ParseSTable(RunTask* rtask, byte* page, word pos);
word Page_ParseStructInfo(RunTask* rtask, byte* page, word pos);

extern void RunSendObjFreeMessage(RTaskHan rtaskHan, MemHandle objBlock);

/*
 * This is an assert-type macro; they should never fail
 * (and serve more for documentation than anything else)
 */
#define PAGE_ASSERT(expr) EC_ERROR_IF( !(expr), PAGE_INTERNAL_ERROR )

/* The amount of platform-specific code is just DISGUSTING --dubois */
#ifdef LIBERTY
#define FidoOpenModule_Compat(_unused, arg1, arg2) FidoOpenModule(arg1, arg2)
#define FidoCloseModule_Compat(_unused, arg1) FidoCloseModule(arg1)
#define FidoGetHeader_Compat(_unused, arg1) FidoGetHeader(arg1)
#else /* GEOS */
#define FidoOpenModule_Compat FidoOpenModule
#define FidoCloseModule_Compat FidoCloseModule
#define FidoGetHeader_Compat FidoGetHeader
#endif


/*********************************************************************
 *			RunAllocTask
 *********************************************************************
 * SYNOPSIS:	Create a RunTask using passed VM file handle
 * CALLED BY:	EXTERNAL, ProgAllocTask
 * RETURN:	Handle to an empty RunTask object
 * SIDE EFFECTS:
 * STRATEGY:
 *	Initialize redundant fields from ProgTask
 *	(vmfile, interpreter, fidotask, progtask)
 *
 *	appObject and uiParent are set.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/12/95	Initial version
 * 
 *********************************************************************/
RTaskHan
RunAllocTask(PTaskHan ptaskHan, optr uiParent)
{
    ProgTask*	ptask;
    RTaskHan	rtaskHan;
    RunTask*	rtask;

#ifdef LIBERTY
    ASSERTS_WARN(uiParent, "RunAllocTask() called with no uiParent!");
#endif
    ECDLM(uint32 beforeCall = theHeap.GetFreeMemoryBytes();)
    rtaskHan = (RTaskHan)MemAlloc(sizeof(RunTask), HF_SWAPABLE | HF_SHARABLE,
			    	  HAF_ZERO_INIT);
    ECDLM(uint32 afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("    After allocating *%d* bytes for Runtask,\n", beforeCall - afterCall);)
    ECDLM(beforeCall = afterCall;)

    if (rtaskHan == NullHandle) return NullHandle;

    rtask = (RunTask*)MemLock(rtaskHan);
    ECL(theHeap.SetTypeAndOwner(rtask, "RTSK", (Geode*)0);)
    EC_BOUNDS(rtask);

    /* Copy oft-used stuff from ptask
     */
    ptask = (ProgTask*)MemLock(ptaskHan);
    EC_BOUNDS(ptask);

#ifndef LIBERTY
    /* GEOS-only fields */
    rtask->RT_interpreter =	ptask->PT_interpreter;
    rtask->RT_vmFile =		ptask->PT_vmFile;
    rtask->RT_fidoTask =	ptask->PT_fidoTask;
#endif
    MemUnlock(ptaskHan);

    /* Init fields of runtask.  Fields are in order of definition in
     * RunTask; fields which don't need initialization are skipped.
     * Zero-initializes are commented out, since the block is
     * alloc'd with HAF_ZERO_INIT
     */
    rtask->RT_handle =		rtaskHan;
    rtask->RT_fidoModule =	NULL_MODULE;
#if ERROR_CHECK
    rtask->RT_cookie =		RTASK_COOKIE;
    rtask->RT_shared =		FALSE;
#endif
    rtask->RT_useCount =	1;
    rtask->RT_progTask =	ptaskHan;
    rtask->RT_compTime =	FRESH;
    rtask->RT_builderRequest = 	BBR_NONE;

#ifndef LIBERTY

    rtask->RT_sstBlock		= MemAllocLMem(LMEM_TYPE_GENERAL,0);
    if (rtask->RT_sstBlock == NullHandle) goto error;
    MemModifyFlags(rtask->RT_sstBlock, HF_SHARABLE, 0);

/*  rtask->RT_bugHandle		= Initialized separately if needed	*/

    (void)MemLock(rtask->RT_sstBlock);
    rtask->RT_uiBlocks = ConstructOptr
	(rtask->RT_sstBlock,
	 ChunkArrayCreate (rtask->RT_sstBlock, sizeof(MemHandle),
			   sizeof(ECChunkArrayHeader), 0));
    ECChunkArrayInitTag(rtask->RT_uiBlocks, "UIbk");

    rtask->RT_childModules = ConstructOptr
	(rtask->RT_sstBlock,
	 ChunkArrayCreate (rtask->RT_sstBlock, sizeof(RTaskHan),
			   sizeof(ECChunkArrayHeader), 0));
    ECChunkArrayInitTag(rtask->RT_childModules, "cMod");

    MemUnlock(rtask->RT_sstBlock);

#endif

#ifdef LIBERTY
    rtask->RT_childModules = new Array(sizeof(RTaskHan), FALSE);
    EC(HeapSetTypeAndOwner(rtask->RT_childModules, "RTCA"));
    if(rtask->RT_childModules == NULL) goto error;
    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("    After allocating *%d* bytes for RT_childModules,\n", beforeCall - afterCall);)
    ECDLM(beforeCall = afterCall;)

    rtask->RT_funTabInfo      = FunTabCreate();
    if (rtask->RT_funTabInfo.FTI_ftabTable == NullHandle) goto error;
    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("    After allocating *%d* bytes for FunTab,\n", beforeCall - afterCall);)

    rtask->RT_strConstMap     = NullHandle;
    rtask->RT_stringFuncTable = NullHandle;
    rtask->RT_exportTable = NullHandle;

#else
    rtask->RT_funTabInfo      = FunTabCreate(rtask->RT_vmFile, NullHandle);
    if (rtask->RT_funTabInfo.FTI_code == NullHandle) goto error;
    rtask->RT_strConstMap     = StrMapCreate();
    if (rtask->RT_strConstMap == NullHandle) goto error;

    rtask->RT_stringFuncTable =	ConstructOptr(rtask->RT_sstBlock,
					      SSTAlloc(rtask->RT_sstBlock));
    if (OptrToChunk(rtask->RT_stringFuncTable) == NullHandle) goto error;
    rtask->RT_exportTable     =	ConstructOptr(rtask->RT_sstBlock,
					      SSTAlloc(rtask->RT_sstBlock));
    if (OptrToChunk(rtask->RT_exportTable) == NullHandle) goto error;
#endif

    rtask->RT_structInfo	= NullHandle;
    rtask->RT_uiParent =	uiParent;
    GONLY(rtask->RT_appObject =	GeodeGetAppObject(0));
    LONLY(rtask->RT_appObject =	NULL);
    rtask->RT_moduleVars	= NullHandle;
    rtask->RT_buildTimeComponents = FALSE;
    rtask->RT_flags		= 0;

    MemUnlock(rtaskHan);
    return rtaskHan;

#ifdef LIBERTY
 error:
    if (rtask->RT_funTabInfo.FTI_ftabTable != NullHandle) {
	FunTabDestroy(&rtask->RT_funTabInfo);
    }
    if (rtask->RT_childModules != NULL) {
	delete rtask->RT_childModules;
    }
    MemFree(rtaskHan);
    return NullHandle;

#else
 error:
    if (rtask->RT_funTabInfo.FTI_code != NullHandle) {
	FunTabDestroy(&rtask->RT_funTabInfo);
    }
    if (rtask->RT_strConstMap != NullHandle) { 
	StrMapDestroy(rtask->RT_strConstMap);
    }
    if (rtask->RT_sstBlock != NullHandle) {
	MemFree(rtask->RT_sstBlock);
    }
    MemFree(rtaskHan);
    return NullHandle;
#endif
}


#ifdef LIBERTY

#include "Legos/legosxip.h"

/*********************************************************************
 *			RunAllocTaskXIP -d-
 *********************************************************************
 * SYNOPSIS:	Create a RunTask with module code that is XIP
 * CALLED BY:	EXTERNAL, ProgAllocTask
 * RETURN:	Handle to an empty RunTask object
 * SIDE EFFECTS:
 * STRATEGY:
 *	Initialize redundant fields from ProgTask
 *	(vmfile, interpreter, fidotask, progtask)
 *
 *	appObject and uiParent are set.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/12/95	Initial version
 * 
 *********************************************************************/
RTaskHan
RunAllocTaskXIP(PTaskHan ptaskHan, optr uiParent, MemHandle header, 
		ModuleToken mod)
{
    ProgTask*	ptask;
    RTaskHan	rtaskHan;
    RunTask*	rtask;

    ECDLM(uint32 beforeCall = theHeap.GetFreeMemoryBytes();)
    rtaskHan = (RTaskHan)MemAlloc(sizeof(RunTask), HF_SWAPABLE | HF_SHARABLE,
			    	  HAF_ZERO_INIT);
    ECDLM(uint32 afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("    After allocating *%d* bytes for RunTask,\n", beforeCall - afterCall);)
    ECDLM(beforeCall = afterCall;)
    if (rtaskHan == NullHandle) return NullHandle;

    rtask = (RunTask*)MemLock(rtaskHan);
    ECL(theHeap.SetTypeAndOwner(rtask, "RTSK", (Geode*)0);)
    EC_BOUNDS(rtask);

    /* Copy oft-used stuff from ptask
     */
    ptask = (ProgTask*)MemLock(ptaskHan);
    EC_BOUNDS(ptask);

    MemUnlock(ptaskHan);

    /* Init fields of runtask.  Fields are in order of definition in
     * RunTask; fields which don't need initialization are skipped.
     * Zero-initializes are commented out, since the block is
     * alloc'd with HAF_ZERO_INIT
     */
    rtask->RT_handle =		rtaskHan;
#if ERROR_CHECK
    rtask->RT_cookie =		RTASK_COOKIE;
    rtask->RT_shared =	    	FALSE;
#endif
    rtask->RT_useCount =    	1;
    rtask->RT_progTask =	ptaskHan;
    rtask->RT_compTime =	FRESH;
    rtask->RT_builderRequest =	BBR_NONE;
    rtask->RT_childModules = new Array(sizeof(RTaskHan), FALSE);
    EC(HeapSetTypeAndOwner(rtask->RT_childModules, "RTCA"));
    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("    After allocating *%d* bytes for RT_childModules,\n", beforeCall - afterCall);)
    ECDLM(beforeCall = afterCall;)

    if(rtask->RT_childModules == NULL) {
	MemFree(rtaskHan);
	return NullHandle;
    }

    rtask->RT_fidoModule =  	mod;

    rtask->RT_uiParent = uiParent;

    /* create the module variable storage table */
    int i;
    XIP_Module *module = (XIP_Module*)header;
    register int moduleBlockSize = (int)module->moduleBlockSize; /* obsolete */
    register int numModuleVars = module->numModuleVars;

    /* module var block is laid out like so:
     * <word: num vars> <N type bytes> <0-3 pad bytes> <N data dwords>
     */
    moduleBlockSize = (int)
	((numModuleVars << 2) +				/* data */
	 CEILING_DWORD(sizeof(word) + numModuleVars));	/* types */

    /* get function table info */
    rtask->RT_funTabInfo = module->funTabInfo;

    /* allocate RAM for module variables, initialize and assign types */
    rtask->RT_moduleVars = NullHandle;
    if(moduleBlockSize > 0) {
	ECDLM(beforeCall = theHeap.GetFreeMemoryBytes();)
	rtask->RT_moduleVars = (MemHandle)MemAlloc(moduleBlockSize,
						   HP_SWAPABLE,
						   HAF_LOCK |
						   HAF_ZERO_INIT);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("    After allocating *%d* bytes for FunTab,\n", beforeCall - afterCall);)

	if (rtask->RT_moduleVars == NullHandle) 
	{
	    LONLY(EC_WARN("RunAllocTaskXIP() failed to allocate module vars"));
	    delete rtask->RT_childModules;
	    MemFree(rtaskHan);
	    return NullHandle;
	}
	byte *moduleVars = (byte*)MemDeref(rtask->RT_moduleVars);
	EC(theHeap.SetTypeAndOwner(moduleVars, "MODV", (Geode*)0);)
	byte *cursor = (byte*)module->moduleVarInfo;

	/* first word -- num vars */
	*(word*)moduleVars = numModuleVars;
	moduleVars += sizeof(word);

	for(i = 0; i < numModuleVars; i++) {
	    byte type;
	    word offset;
	    GetType(cursor, type);
	    /* FIXME when HVTE_offset is removed */
	    GetWordBcl(cursor, offset);
	    moduleVars[offset/5] = type;
	}
	/* Unlock added by matta */
	MemUnlock(rtask->RT_moduleVars);
    }
    /* complex data */
    rtask->RT_complexDataCount = module->numComplexDataElements;
    rtask->RT_complexTable = module->complexDataTable;

    /* parse struct info */
    /* don't bother copying, ROM image is already correct */
    rtask->RT_structInfo = module->structInfo;

    /* parse string constant table */
    rtask->RT_strConstMap = module->strConstMap;

    /* parse export string table */
    rtask->RT_exportTable = module->exportTable;
    rtask->RT_exportTableCount = module->numExportStrings;

    /* parse string function table */
    rtask->RT_stringFuncTable = module->stringFuncTable;
    rtask->RT_stringFuncCount = module->numStringFuncs;

    rtask->RT_buildTimeComponents = FALSE;

    MemUnlock(rtaskHan);
    return rtaskHan;
}

#endif
/*********************************************************************
 *			RunDestroyModuleVariables
 *********************************************************************
 * SYNOPSIS:	a routine to clean up a module scope
 * CALLED BY:	INTERNAL RunDestroyTask, RunNullRTaskCode
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	decRef is a temporary flag, until we get rid of all this
 *	NullRTaskCode business.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 2/17/95	Initial version			     
 * 
 *********************************************************************/
static void
RunDestroyModuleVariables(RTaskHan rtaskHan, Boolean decRef)
{
    RunTask*	rtask;
    PTaskPtr	ptask;
    GONLY(RunHeapInfo* rhi;)
	
    byte*	globalTypes;
    dword*	globalData;

    word	i, numGlobs;
    MemHandle	moduleVars;

    rtask = (RunTask*)MemLock(rtaskHan);
    ptask = (ProgTask*)MemLock(rtask->RT_progTask);
    GONLY(rhi = &ptask->PT_runHeapInfo;)

    moduleVars = rtask->RT_moduleVars;
    if (moduleVars == NullHandle) {
	goto	done;
    }

    LOCK_GLOBALS(moduleVars, globalTypes, globalData);
    numGlobs = NUM_GLOBALS_FAST(globalTypes);

    for(i = 0; i < numGlobs; i++)
    {
	switch (globalTypes[i])
	{
	case TYPE_ARRAY:
	{
	    MemHandle	tmpHandle;

	    tmpHandle = (MemHandle) globalData[i];

	    if (tmpHandle != NullHandle) {
		BEGIN_USING_CACHED_ARRAY;
		if (cachedArray == tmpHandle) {
		    /* Prevent accessing cachedArray later. */
		    /* No need to unlock, since freed below. */
		    cachedArray = NullHandle;
		    LONLY(cachedArrayPtr = NULL);
		}
		END_USING_CACHED_ARRAY;
		if (decRef) {
		    ArrayDecRefElements(rhi, tmpHandle, 0, ARRAY_DEC_REF_ALL);
		}
		MemFree(tmpHandle);
	    }
	    break;
	}

	case TYPE_RUN_HEAP_CASE:
	{
	    RunHeapToken	token;

	    token = (RunHeapToken) globalData[i];
	    if (decRef) {
		RunHeapDecRef(rhi, token);
	    }
	    break;
	}

	case TYPE_COMPONENT:
	{
	    optr	comp;
	    
	    comp = (optr) globalData[i];
	    if (decRef) {
		if (COMP_IS_AGG(comp)) {
		    RunHeapDecRef(rhi, AGG_TO_STRUCT(comp));
		}
	    }
	    break;
	}

	default:
	    break;

	}
    }

    /* ECL(MemUnlock(moduleVars);) Mike added this, but it isn't right... */
    ECL(MemUnlock(moduleVars);)
    MemFree(moduleVars);
    rtask->RT_moduleVars = NullHandle;
 done:
    MemUnlock(ptask->PT_handle);
    MemUnlock(rtaskHan);
}

/*********************************************************************
 *			RunDestroyTask
 *********************************************************************
 * SYNOPSIS:	Kill off a runtime task
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	If the RTask was created from a CTask, complain if references
 *	haven't been nulled out yet.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/28/94	Initial version			     
 * 
 *********************************************************************/
void
RunDestroyTask(RTaskHan rtaskHan)
{
    RunTask	*rtask;

    rtask = (RunTask*)MemLock(rtaskHan);
    EC_ERROR_IF( rtask->RT_cookie != RTASK_COOKIE, RE_BAD_RTASK);
    ECDLM(uint32 beforeCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("Start of RunDestroyTask(), there is %d bytes free\n", beforeCall);)
    ECDLM(uint32 afterCall;)

    if ( rtask->RT_fidoModule != NULL_MODULE )
    {
#ifdef LIBERTY
	FidoCloseModule(rtask->RT_fidoModule);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("After FidoCloseModule(), freed %d bytes\n", afterCall - beforeCall);)
	ECDLM(beforeCall = afterCall;)
#else
	FidoCloseModule(rtask->RT_fidoTask, rtask->RT_fidoModule);
#endif
    }

#ifndef LIBERTY
    if (rtask->RT_uiBlocks != NullOptr) 
    {
	word		i, count;
	MemHandle	mh;

	MemLock(OptrToHandle(rtask->RT_uiBlocks));
	count = ((ChunkArrayHeader*)LMemDeref(rtask->RT_uiBlocks))->CAH_count;

	for (i=0; i<count; i++)
	{
	    mh = *(MemHandle*)ChunkArrayElementToPtr
		(rtask->RT_uiBlocks, i, NULL);
	    if (mh != NullHandle) {
		RunSendObjFreeMessage(rtask->RT_handle, mh);
/*		ObjFreeObjBlock(mh); */
	    }
	}
	LMemFree(rtask->RT_uiBlocks);
	MemUnlock(OptrToHandle(rtask->RT_uiBlocks));
	rtask->RT_uiBlocks = NullOptr;
    }
#endif

    if (rtask->RT_compTime == NOT_OWNER)
    {
	/* Hey!  Call RunNullRTaskCode before destroying! */
	EC_WARNING_IF(rtask->RT_strConstMap ||
		      rtask->RT_exportTable ||
		      rtask->RT_stringFuncTable ||
		      rtask->RT_funTabInfo.FTI_code != NullHandle ||
		      rtask->RT_bugHandle,
		      RW_DESTROYING_RTASK_WITH_REFERENCES);
    }
    else if (!LIBERTY_XIP_MODULE(rtask))
    {
	FunTabDestroy(&rtask->RT_funTabInfo);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("After FunTabDestroy(), freed %d bytes\n", afterCall - beforeCall);)
	ECDLM(beforeCall = afterCall;)

	StrMapDestroy(rtask->RT_strConstMap);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("After StrMapDestroy(), freed %d bytes\n", afterCall - beforeCall);)
	ECDLM(beforeCall = afterCall;)

	SSTDestroy(rtask->RT_stringFuncTable);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("After SSTDestroy() of stringFuncTable, freed %d bytes\n", afterCall - beforeCall);)
	ECDLM(beforeCall = afterCall;)

	SSTDestroy(rtask->RT_exportTable);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("After SSTDestroy() of exportTable, freed %d bytes\n", afterCall - beforeCall);)
	ECDLM(beforeCall = afterCall;)

#ifndef LIBERTY
	MemFree(rtask->RT_sstBlock);
#endif
	if (rtask->RT_structInfo != NullOptr)
	{
	    MemFree(OptrToHandle(rtask->RT_structInfo));
	    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	    ECDLM(printf("After freeing structInfo block, freed %d bytes\n", afterCall - beforeCall);)
	    ECDLM(beforeCall = afterCall;)
	}
    }

#ifdef LIBERTY
    delete rtask->RT_childModules;
    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("After deleting RT_childModules, freed %d bytes\n", afterCall - beforeCall);)
    ECDLM(beforeCall = afterCall;)

    if (rtask->RT_topLevelComponents != NullHandle) {
	ASSERT(LockCountH(rtask->RT_topLevelComponents) == 0);
	MemFree(rtask->RT_topLevelComponents);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("After deleting RT_topLevelComponents, freed %d bytes\n", afterCall - beforeCall);)
	ECDLM(beforeCall = afterCall;)
    }
#endif

    RunDestroyModuleVariables(rtaskHan, TRUE);
    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("After RunDestroyModuleVariables(), freed %d bytes\n", afterCall - beforeCall);)
    ECDLM(beforeCall = afterCall;)

    ECL(MemUnlock(rtaskHan);)
    MemFree(rtaskHan);
    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("After deleting rtask, freed %d bytes\n", afterCall - beforeCall);)
    ECDLM(printf("Memory free = %d\n\n", afterCall);)

    return;
}

#ifdef LIBERTY

static RunTask* 
RunTaskEnumAndReverse(RunTask* head,
		      void (*func)(RunTask*, void*),
		      void* funcArg);

/***********************************************************************
 *			RunTaskGetNext()
 ***********************************************************************
 *
 * SYNOPSIS:	    Get the next run task from this one
 * CALLED BY:	    Module unloading code
 * RETURN:	    The value of RT_next
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	matta	1/ 2/97  	Initial Revision
 *
 ***********************************************************************/
RunTask*
RunTaskGetNext(RunTask* task)
{
    PARAM_ASSERT(task != NULL);
    PARAM_ASSERT(LockCountH(task->RT_handle) > 0);
    ASSERT(task->RT_next == NULL || 
	   LockCountH(task->RT_next->RT_handle) > 0);

    return task->RT_next;
}	/* End of RunTaskGetNext() */

/***********************************************************************
 *			RunTaskSetNext()
 ***********************************************************************
 *
 * SYNOPSIS:	    Set the next run task in the unload chain
 * CALLED BY:	    Module unloading code
 * RETURN:	    nothing
 * SIDE EFFECTS:    Sets RT_next
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	matta	1/ 2/97  	Initial Revision
 *
 ***********************************************************************/
void
RunTaskSetNext(RunTask* task,
	       RunTask* next)
{
    PARAM_ASSERT(task != NULL);
    PARAM_ASSERT(LockCountH(task->RT_handle) > 0);
    PARAM_ASSERT(next == NULL || LockCountH(next->RT_handle) > 0);

    task->RT_next = next;
}	/* End of RunTaskSetNext() */

/***********************************************************************
 *			RunTaskEnumBackwards()
 ***********************************************************************
 *
 * SYNOPSIS:	    Enum the run task list backwards
 * CALLED BY:	    UM_CallModuleExits
 * RETURN:	    The new head.  When NULL is passed as the enum
 *                  function, the list is reversed.
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	matta	1/ 2/97  	Initial Revision
 *
 ***********************************************************************/
void RunTaskEnumBackwards(RunTask* head,
			   void (*func)(RunTask*, void*),
			   void* funcArg)
{
    PARAM_ASSERT(func != NULL);

    /* Reverse the list */
    head = RunTaskEnumAndReverse(head, NULL, NULL);
    /* Enum with function while reversing list back to original order
       */
    (void) RunTaskEnumAndReverse(head, func, funcArg);
}	/* End of RunTaskEnumBackwards() */


/***********************************************************************
 *			RunTaskEnumAndReverse()
 ***********************************************************************
 *
 * SYNOPSIS:	    Enum a linked list of run tasks, reversing
 *                  the list as it is done.
 * CALLED BY:	    RunTaskEnumBackwards()
 * RETURN:	    The new head of the list (which was the old tail)
 * SIDE EFFECTS:    Reverses the links in the list
 *
 * STRATEGY:	    Reverse the list in place, for O(1) space and
 *                  O(n) time.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	matta	1/ 2/97  	Initial Revision
 *
 ***********************************************************************/
static RunTask* 
RunTaskEnumAndReverse(RunTask* head,
		      void (*func)(RunTask*, void*),
		      void* funcArg)
{
    PARAM_ASSERT(head != NULL);

    /* Call the enum function, reversing the list along the way.
       given one */
    RunTask* curr = head->RT_next;
    RunTask* prev = head;

    prev->RT_next = NULL;
    if (func) {
	/* Call the enum function */
	func(prev, funcArg);
    }
    while (curr) {
	if (func) {
	    /* Call the enum function */
	    func(curr, funcArg);
	}
	RunTask* temp = curr->RT_next; /* Save for later */
	curr->RT_next = prev;	/* Reverse this link */
	prev = curr;		/* Advance */
	curr = temp;
    }

    return prev;		/* return the new head */

}	/* End of RunTaskEnumAndReverse() */

/***********************************************************************
 *			RunTaskInList()
 ***********************************************************************
 *
 * SYNOPSIS:	    Checks if a given handle is in the list
 * CALLED BY:	    Module unloading code
 * RETURN:	    TRUE if item is in list, FALSE otherwise.
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	matta	1/ 2/97  	Initial Revision
 *
 ***********************************************************************/
Boolean
RunTaskInList(RunTask* head, RTaskHan handle)
{
    RunTask* curr = head;
    while (curr) {
	if (curr->RT_handle == handle) {
	    return TRUE;
	}
	curr = curr->RT_next;
    }
    return FALSE;
}	/* End of RunTaskInList() */

#endif /* LIBERTY */

#ifndef LIBERTY
/*********************************************************************
 *			RunSetURL
 *********************************************************************
 * SYNOPSIS:	Set URL for a RunTask, if RunLoadModule wasn't used to create
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	11/ 9/95	Initial version
 * 
 *********************************************************************/
void
RunSetURL(RTaskHan rtaskHan, TCHAR* url)
{
    RunTask*	rtask;

    rtask = (RunTask*)MemLock(rtaskHan);
    if (rtask->RT_fidoModule != NULL_MODULE) {
	FidoCloseModule(rtask->RT_fidoTask, rtask->RT_fidoModule);
    }

    /* temp: Strip off the .XXX
     */
    ;{
	TCHAR*		endP;

	/* get a pointer to the last occurrance of a period */
	endP = strrchr(url, C_PERIOD);
	if (endP) {
	    /* there was a period in the url, drop the .XXX by
	       replacing it with a C_NULL */
	    *endP = C_NULL;
	}
	
	rtask->RT_fidoModule =
	    FidoOpenModule(rtask->RT_fidoTask, url, NULL_MODULE);

	if (endP) {
	    /* restore the period back into the string */
	    *endP = C_PERIOD;
	}
    }

    MemUnlock(rtaskHan);
}
#endif

/*********************************************************************
 *			RunLoadModule
 *********************************************************************
 * SYNOPSIS:	Load, RunTopLevel a URL.  Add new RunTask to ProgTask
 *
 * CALLED BY:	GLOBAL
 *
 * RETURN:	RTaskHan - new run task handle for module, or
 *			   null if module not loaded
 *
 * SIDE EFFECTS: this routine doesn't actually need to set up DS, but
 *	    	 RunLoadModuleLow destroys DS and this is an easy way
 *	    	 to restore DS in C
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/27/94	Initial version			     
 * 
 *********************************************************************/
RTaskHan
RunLoadModule(PTaskHan ptaskHan, TCHAR *url, optr uiParent)
{
    SET_DS_TO_DGROUP;
    RTaskHan rtaskHan = RunLoadModuleLow(ptaskHan, url, uiParent, NULL_MODULE);
    if(rtaskHan != NullHandle) {
    	RunTopLevel(rtaskHan);
    }
    RESTORE_DS;
    return rtaskHan;
}


/*********************************************************************
 *			RunLoadModuleLow
 *********************************************************************
 * SYNOPSIS:	Load, RunTopLevel a URL.  Add new RunTask to ProgTask
 *
 * CALLED BY:	EXTERNAL, RunLoadModule, FunctionLoadModule
 *
 * RETURN:	RTaskHan - new run task handle for module, or
 *			   null if module not loaded
 *
 * SIDE EFFECTS:
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/27/94	Initial version			     
 * 
 *********************************************************************/
RTaskHan
RunLoadModuleLow(PTaskHan ptaskHan, TCHAR *url, optr uiParent, ModuleToken currentModule)
{
    RTaskHan	rtaskHan;
    RunTask*	rtask;
    MemHandle	header;
    ModuleToken	mod;
    word	pos;
#ifndef LIBERTY
    ProgTask* 	ptask;
    MemHandle	fidoTask;

    ptask = (ProgTask*)MemLock(ptaskHan);
    EC_BOUNDS(ptask);
    fidoTask = ptask->PT_fidoTask;
    MemUnlock(ptaskHan);
#endif

    ECDLM(uint32 beforeCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(uint32 beforeLoad = beforeCall;)
    ECDLM(uint32 afterCall;)
    ECDLM(printf("\nBefore module load there was %d bytes free.\n", beforeCall);)
    ASSERTS_WARN(uiParent, "RunLoadModuleLow() called with no uiParent!");

    mod = FidoOpenModule_Compat(fidoTask, url, currentModule);

    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("After FidoOpenModule(), used *%d* bytes for Fido module entry.\n", beforeCall-afterCall);)
    ECDLM(beforeCall = afterCall;)

    if (mod == NULL_MODULE) {
	return NullHandle;
    }

    header = FidoGetHeader_Compat(fidoTask, mod);
    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("After FidoGetHeader(), temporarily uses %d bytes.\n", beforeCall-afterCall);)
    ECDLM(beforeCall = afterCall;)

    if (header == NullHandle)
    {
	FidoCloseModule_Compat(fidoTask, mod);
	return NullHandle;
    }

    /* All's well so far... create and fill in the new runtask,
     * add it to ProgTask
     */
#ifdef LIBERTY
    if(mod >= 32767) {
	/* 32767 is used by Liberty version to identify XIP modules */
	ECDLM(printf("Starting RunAllocTaskXIP() for new module\n");)
	rtaskHan = RunAllocTaskXIP(ptaskHan, uiParent, header, mod);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("After RunAllocTaskXIP(), used **%d** bytes.\n", beforeCall-afterCall);)
	ECDLM(beforeCall = afterCall;)
    }
    else {
#endif
	ECDLM(printf("Starting RunAllocTask() allocations for new module\n");)

	rtaskHan = RunAllocTask(ptaskHan, uiParent);

	ECDLM(afterCall = theHeap.GetFreeMemoryBytes());
	ECDLM(printf("After RunAllocTask(), used **%d** bytes.\n", beforeCall-afterCall));
	ECDLM(beforeCall = afterCall);

	if (rtaskHan == NullHandle) {
	    return NullHandle;
	}

	rtask = (RunTask*)MemLock(rtaskHan);
	EC_BOUNDS(rtask);
	EC_ERROR_IF(rtask->RT_compTime != FRESH, RE_FAILED_ASSERTION);
    	rtask->RT_compTime = OWNER;

	rtask->RT_fidoModule = mod;
#ifdef LIBERTY
        ECDLM(printf("Starting Page_ParseHeader()\n");)
	pos = Page_ParseHeader(rtask, header);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
        ECDLM(printf("After Page_ParseHeader(), used **%d** bytes.\n", beforeCall-afterCall);)
        ECDLM(beforeCall = afterCall;)

	MemFree(header);
        ECDLM(printf("Freeing header page\n");)
	ECDLM(beforeCall = theHeap.GetFreeMemoryBytes();)

	if (pos == 0xffff) {
	    /* error in Page_ParseHeader */
	    MemUnlock(rtaskHan);
	    RunDestroyTask(rtaskHan);
	    return NullHandle;
	}

	MemHandle page = FidoGetPage(mod, 0);
        ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
        ECDLM(printf("After FidoGetPage(), temporarily uses %d bytes.\n", beforeCall-afterCall);)
	pos = 0;
	if (Page_ParsePage(rtask, page, pos) == FALSE)
	{
	    MemFree(page);
	    ECDLM(printf("Freeing page obtained in FidoGetPage() - ERROR occurred\n");)
	    MemUnlock(rtaskHan);
	    RunDestroyTask(rtaskHan);
	    return NullHandle;
	}
	MemFree(page);
	ECDLM(printf("Freeing page obtained in FidoGetPage()\n");)
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("After Page_ParsePage() creates blocks of function code, used **%d** bytes.\n", beforeCall-afterCall);)
        ECDLM(beforeCall = afterCall;)

	MemUnlock(rtaskHan);
    }
#else
    pos = Page_ParseHeader(rtask, header);

    if (pos == 0xffff)
    {
	MemFree(header);
	MemUnlock(rtaskHan);
	return NullHandle;
    }
    if (Page_ParsePage(rtask, header, pos) == FALSE)
    {
	MemFree(header);
	MemUnlock(rtaskHan);
	return NullHandle;
    }
    MemFree(header);
    
    /* XXX: check for errors */
    if (rtask->RT_bugHandle != NullHandle) {
	BugSetAllBreaks(rtask->RT_bugHandle);
    }
    MemUnlock(rtaskHan);
#endif
    
    if (rtaskHan != NullHandle) {
	ProgAddRunTask(ptaskHan, rtaskHan);
    }

    ECDLM(printf("** This module used a total of ****%d*** bytes, now %d bytes free.**\n\n",
	  beforeLoad - afterCall, afterCall); )
    return rtaskHan;
}


/*********************************************************************
 *			RunReadPage
 *********************************************************************
 * SYNOPSIS:	Load page from current module
 * CALLED BY:	EXTERNAL, RunMainLoop
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Only functions are on pages right now, so this function is
 *	mostly a wrapper...
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/24/95	Initial version			     
 * 
 *********************************************************************/
Boolean
RunReadPage(RunTask* rtask, word pageNum)
{
    MemHandle	page;
    Boolean	retval = FALSE;

    EC_ERROR_IF(rtask->RT_fidoModule == NULL_MODULE, RE_NO_FIDO);
#ifdef LIBERTY
    page = FidoGetPage(rtask->RT_fidoModule, pageNum);
#else
    page = FidoGetPage(rtask->RT_fidoTask, rtask->RT_fidoModule,
		       pageNum);
#endif
    if (page != NullHandle)
    {
	word x = 0;
	retval = Page_ParsePage(rtask, page, x);
	MemFree(page);
    }
    return retval;
}

/*********************************************************************
 *			Page_ParseHeader
 *********************************************************************
 * SYNOPSIS:	Initialize RunTask from a header block
 * CALLED BY:	INTERNAL, RunLoadModule
 * RETURN:	Position of end of header, 0xffff on error
 * SIDE EFFECTS:
 *	Creates a new vm file, allocates memory.
 *
 * STRATEGY:
 *	Top of file:
 *	2 bytes		protocol
 *	word		var table size
 *	word		num entries
 *
 *	Fill in the runtask from data stored in the header.
 *	Doesn't fill in the various string tables yet.
 *
 *	Fills in Code and function table hugearrays, and creates
 *	mem block for module variable storage
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/ 4/95	Initial version			     
 * 
 *********************************************************************/
word
Page_ParseHeader(RunTask* rtask, MemHandle headerHandle)
{
    byte	*header, *moduleVars;
    word	moduleBlockSize;
    word	hc, i;
    word	numModuleVars, nFuncEntries;
    RunFastFTabEntry rfte;
    Boolean	done = FALSE;

    EC_BOUNDS(rtask);
    header = (byte*)MemLock(headerHandle);
    EC_BOUNDS(header);

    if (header[0] != BC_MAJOR_REV || header[1] > BC_MINOR_REV)
    {
#ifdef LIBERTY
#ifdef EC_LOG
	theLog << "DLL with protocol version " << (int)header[0]
	       << '.' << (int)header[1]
	       << ", can only handle up to " << (int)BC_MAJOR_REV << '.'
	       << (int)BC_MINOR_REV << '\n';
#endif
#else
	/* I'd make this EC but it is good to have in NC as well
	 * at least during development.
	 */
	SET_DS_TO_DGROUP;
	TCHAR*	cp;
	TCHAR	wantStr[10];
	TCHAR	gotStr[10];

	cp = wantStr;
	itoa(BC_MAJOR_REV, cp);	cp=strchr(cp, C_NULL); *cp++ = C_PERIOD;
	itoa(BC_MINOR_REV, cp);
	
	cp = gotStr;
	itoa(header[0], cp); cp=strchr(cp, C_NULL); *cp++ = C_PERIOD;
	itoa(header[1], cp);

	UserStandardDialog(NULL,NULL, gotStr, wantStr,
			   _TEXT("Wanted protocol \001 but got protocol \002"),
			   CDBF_SYSTEM_MODAL | 
			   (CDT_ERROR << CDBF_DIALOG_TYPE_OFFSET) |
			   (GIT_NOTIFICATION << CDBF_INTERACTION_TYPE_OFFSET));
	RESTORE_DS;
#endif
	MemUnlock(headerHandle);
	return 0xffff;
    }

    /* create the module variable storage table.
     * module var block is laid out like so:
     * <word: num vars> <N type bytes> <0-3 pad bytes> <N data dwords>
     */
    ECDLM(uint32 beforeCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(uint32 afterCall;)
    NextWordBcl(&header[2], moduleBlockSize); /* mostly obsolete */
    hc = 6;

    if (moduleBlockSize > 0)
    {
	NextWordBcl(&header[4], numModuleVars);

	moduleBlockSize = (word)
	    ((numModuleVars << 2) +				/* data */
	     CEILING_DWORD(sizeof(word) + numModuleVars));	/* types */

	rtask->RT_moduleVars = (MemHandle)MemAlloc(moduleBlockSize,
						   HF_SWAPABLE,
						   HAF_LOCK | 
						   HAF_ZERO_INIT);
        ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("    After MemAlloc() for module vars, used *%d* bytes.\n", beforeCall-afterCall);)
	ECDLM(beforeCall = afterCall;)

	if (rtask->RT_moduleVars == NullHandle) {
	    return 0xffff;
	}
	moduleVars = (byte*) MemDeref(rtask->RT_moduleVars);
	ECL(theHeap.SetTypeAndOwner(moduleVars, "MODV", (Geode*)0);)
	/* first word -- num vars */
	*(word*)moduleVars = numModuleVars;
	moduleVars += sizeof(word);

	for (i = 0; i < numModuleVars; i++)
	{
	    byte	type;
	    word	offset;

	    type = header[hc];
	    hc++;
	    NextWordBcl(header+hc, offset);
	    hc += 2;
	    moduleVars[offset/5] = type;
	    /* FIXME when HVTE_offset is removed */
	}
	MemUnlock(rtask->RT_moduleVars);
    } else {
#if ERROR_CHECK
	NextWordBcl(&header[4], numModuleVars);
	PAGE_ASSERT( numModuleVars == 0 );
#endif
	/* MemAlloc blows up if we allocate zero bytes, so don't */
	rtask->RT_moduleVars = NullHandle;
    }
    
    /* Fill in the function table
     */
    NextWordBcl(&header[hc], nFuncEntries);	hc += 2;
    for (i=0; i < nFuncEntries; i++)
    {
	rfte.RFFTE_codeHandle = NullHandle;
	NextWordBcl(&header[hc], rfte.RFFTE_page);	hc += 2;
	if (FunTabAppendTableEntry(&rtask->RT_funTabInfo, &rfte) == FALSE) {
	    done = TRUE;	/* avoid while loop below */
	    hc = 0xffff;	/* indicate error */
	    break;
	}
    }
    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("    After FunTabAppendTableEntry() of %d entries, used *%d* bytes.\n", nFuncEntries, beforeCall-afterCall);)
    ECDLM(beforeCall = afterCall;)

    rtask->RT_structInfo = NullHandle;

    while (!done)
    {
	PageMarker	pm;
	NextWordBcl(&header[hc], pm);
	switch(pm)
	{
	case PM_STRUCT_INFO:
	    hc = Page_ParseStructInfo(rtask, header, hc);
	    if (hc == 0xffff) {	/* check for error */
		done = TRUE;
	    }
 	    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	    ECDLM(printf("    After Page_ParseStructInfo(), used *%d* bytes.\n", beforeCall-afterCall);)
	    ECDLM(beforeCall = afterCall;)
	    break;

	case PM_PAD_BYTE:
	    EC_ERROR_IF(header[hc+2] != 0xcc, RE_FAILED_ASSERTION);
	    hc += 3;
	    break;

	case PM_STRING_FUNC:
	case PM_STRING_CONST:
	case PM_EXPORT:
	    /* Should be word-aligned */
	    EC_ERROR_IF(hc&1, RE_FAILED_ASSERTION);
	    hc = Page_ParseSTable(rtask, header, hc);
	    if (hc == 0xffff)
	    {
	    	done = TRUE;
	    }
	    break;

	case PM_HEADER_END:
	    hc += 2;
	    done = TRUE;
	    break;

	default:
	    EC_ERROR(PAGE_INVALID_MARKER);
	    done = TRUE;
	    hc = 0xffff;
	    break;
	}
    }

    MemUnlock(headerHandle);
    return hc;
}

/*********************************************************************
 *			Page_ParseStructInfo
 *********************************************************************
 * SYNOPSIS:	Extract struct info from header
 * CALLED BY:	INTERNAL
 * RETURN:	ending position, or 0xffff on error
 * SIDE EFFECTS:fills in rtask->RT_structInfo with info parsed
 * STRATEGY:
 *	each struct is:
 *	word	size
 *	word	numFields
 *
 *	followed by <numFields> of these
 *	byte	type
 *	word	offset
 *	byte	structType	(only if minor proto is >= 2)
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/20/95	Initial version
 * 
 *********************************************************************/
word
Page_ParseStructInfo(RunTask* rtask, byte* page, word pos)
{
#ifndef LIBERTY
    MemHandle	mh;
    ChunkHandle	ch;
    optr	carr;
#endif
    byte*	cursor;
    word	i, numStructs;

#if ERROR_CHECK
    cursor = page+pos;
    GetWordBcl(cursor, numStructs);
    EC_ERROR_IF(numStructs != PM_STRUCT_INFO, RE_FAILED_ASSERTION);
#else
    cursor = page+pos+2;
#endif

#ifdef LIBERTY
    /* we're going to free the header page so copy the struct info part out 
       into a simple movable block of memory */
    GetWordBcl(cursor, numStructs);
    byte *startBlock = cursor;

    /* find end of the struct info section */
    for(i = 0; i < numStructs; i++) {
	word numFields;
	GetWordBcl(cursor, numFields);
	cursor += 2 + numFields * sizeof(BCLVTabEntry);
    }

    if (numStructs > 0) {
	uint32 size = cursor - startBlock;
	rtask->RT_structInfo = MallocH(size);
	if (rtask->RT_structInfo != 0) {
	    char *block = (char*)LockH(rtask->RT_structInfo);
	    EC(theHeap.SetTypeAndOwner(block, "SIFO", (Geode*)0));
	    memcpy(block, startBlock, size);
	    UnlockH(rtask->RT_structInfo);
	} else {
	    return 0xffff;
	}
    }
    return (cursor-page);

#else	/* GEOS version below */

    mh = MemAllocLMem(LMEM_TYPE_GENERAL, 0);
    EC_ERROR_IF(mh == NullHandle, RE_FAILED_ASSERTION);
    MemModifyFlags(mh, HF_SHARABLE, 0);

    (void) MemLock(mh);

    ch = ChunkArrayCreate(mh, 0,0,0);				/* shuffle */
    carr = ConstructOptr(mh, ch);

    GetWordBcl(cursor, numStructs);
    for (i=0; i<numStructs; i++)
    {
	word	j;

	BCLVTab*	bvtab;
	RunVTab*	rvtab;
	BCLVTabEntry*	bvte;
	RunVTabEntry*	rvte;
	
	bvtab = (BCLVTab*)cursor;
	cursor += sizeof(BCLVTab);

	rvtab =		/* shuffle */
	    ChunkArrayAppend(carr,
	     (sizeof(RunVTab) +	bvtab->numFields*sizeof(RunVTabEntry)));

	rvtab->RVT_size = bvtab->size;
	rvtab->RVT_numFields = bvtab->numFields;

	rvte = (RunVTabEntry*)(rvtab+1);
	for (j=0; j<rvtab->RVT_numFields; j++)
	{
	    bvte = (BCLVTabEntry*)cursor;

	    rvte->RVTE_type = bvte->type;
	    rvte->RVTE_structType = bvte->structType;

	    rvte += 1;
	    cursor += sizeof *bvte;
	}
    }
    MemUnlock(mh);
    rtask->RT_structInfo = carr;
    return (cursor-page);
#endif
}

/*********************************************************************
 *			Page_ParsePage
 *********************************************************************
 * SYNOPSIS:	Top-level page parsing routine
 * CALLED BY:	INTERNAL, RunReadPage RunLoadModule
 * RETURN:	void
 * SIDE EFFECTS:
 * STRATEGY:	There doesn't seem to be a way for this to return FALSE
 *	    	so what's the point of having a return value?  mchen
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 2/ 1/95	Initial version			     
 * 
 *********************************************************************/
Boolean
#ifdef LIBERTY
Page_ParsePage(RunTask* rtask, MemHandle pageHan, word& pos)
#else
Page_ParsePage(RunTask* rtask, MemHandle pageHan, word pos)
#endif
{
    byte*	page;
    Boolean	done = FALSE;
    Boolean	retval = TRUE;

    if (!pageHan) {
	return FALSE;
    }

#ifdef LIBERTY
    page = (byte*)CheckLock(pageHan);
#else
    page = (byte*)MemLock(pageHan);
#endif

    while (!done)
    {
	PageMarker pageType;
	NextWordBcl(&page[pos], pageType);
	switch(pageType)
	{
	case PM_FUNC:
	    pos = Page_ParseFunc(rtask, page, pos);
	    if (pos == 0xffff) { /* check for error */
		retval = FALSE;
		done = TRUE;
	    }
	    break;
	case PM_END:
	    done = TRUE;
	    break;
	default:
	    EC_ERROR(PAGE_INVALID_MARKER);
	    done = TRUE;
	    retval = FALSE;
	    break;
	}
    }

    MemUnlock(pageHan);
    return retval;
}

/*********************************************************************
 *			Page_ParseSTable
 *********************************************************************
 * SYNOPSIS:	Read in a string table
 * CALLED BY:	INTERNAL
 * RETURN:	position of end of STable
 * SIDE EFFECTS:
 * STRATEGY:
 *	Rely on the fact that rtask fields are initialized to 0.
 *	Will create string table if it doesn't already exist;
 *	otherwise, it will be appended to.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 2/ 1/95	Initial version			     
 * 
 *********************************************************************/
word
Page_ParseSTable(RunTask* rtask, byte* page, word pos)
{
    optr  	*stableP = NULL;
    word	i, numStrings, SH_marker;
    Boolean     constMap = FALSE;
    PTaskPtr    ptask = NULL;

    EC_BOUNDS(rtask);
    EC_BOUNDS(page);

    /* Hey, it works.
     */
    NextWordBcl(&(page[pos]), SH_marker);
    NextWordBcl(&(page[pos+2]), numStrings);
    pos += sizeof(StringHeader);

    ECDLM(uint32 beforeCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(uint32 afterCall;)

    switch ( SH_marker )
    {
    case PM_STRING_CONST:
#ifdef LIBERTY
       ASSERT(!constMap);
       rtask->RT_strConstMap     = StrMapCreate(numStrings);	
       ECDLM(afterCall = theHeap.GetFreeMemoryBytes());
       ECDLM(printf("    After StrMapCreate(), used *%d* bytes.\n", beforeCall-afterCall));
       ECDLM(beforeCall = afterCall);
       if (!rtask->RT_strConstMap) {
	   return 0xffff;	/* error */
       }
#else
       EC_ERROR_IF(StrMapGetCount(rtask->RT_strConstMap) != 0, 
		   RE_FAILED_ASSERTION);
#endif
       ptask = (ProgTask*)MemLock(rtask->RT_progTask);
       constMap = TRUE;
       break;
    case PM_STRING_FUNC:
	stableP = &rtask->RT_stringFuncTable;
#ifdef LIBERTY
	ASSERTS(((uint32)&page[pos] & 0x1) == 0, "DBCS string not 2-byte aligned");
	rtask->RT_stringFuncTable = LSSTAlloc(numStrings, page, &pos);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes());
	ECDLM(printf("    After LSSTAlloc() for STRING_FUNC, used *%d* bytes.\n", beforeCall-afterCall));
	ECDLM(beforeCall = afterCall);
	if (pos == 0xffff) {	/* check for error */
	    if (constMap) {
		MemUnlock(rtask->RT_progTask);
	    }
	    return 0xffff;	/* error */
	}
	rtask->RT_stringFuncCount = numStrings;
	return pos;
#else
	break;
#endif
    case PM_EXPORT:
	stableP = &rtask->RT_exportTable;
#ifdef LIBERTY
	ASSERTS(((uint32)&page[pos] & 0x1) == 0, "DBCS string not 2-byte aligned");
	rtask->RT_exportTable = LSSTAlloc(numStrings, page, &pos);
	ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
	ECDLM(printf("    After LSSTAlloc() for EXPORT, used *%d* bytes.\n", beforeCall-afterCall);)
	ECDLM(beforeCall = afterCall);
	if (pos == 0xffff) {	/* check for error */
	    if (constMap) {
		MemUnlock(rtask->RT_progTask);
	    }
	    return 0xffff;	/* error */
	}
	rtask->RT_exportTableCount = numStrings;
	return pos;
#else
	break;
#endif
    default:
#ifdef LIBERTY
	ASSERT(FALSE);
#else
#if ERROR_CHECK
	CFatalError(RE_FAILED_ASSERTION);
#endif
#endif
	break;
    }

    for (i = 0; i < numStrings; i++)
    {
#if ARCH_BIG_ENDIAN
	/* since the code is default as little endian, we need to convert
	   the string to the right format, we will do this in place. */
	TCHAR *string = (TCHAR*)&page[pos];
	while(*string != '\0') 
	{
	    byte *tmpPtr = (byte*)string;
	    byte tmp = *tmpPtr;
	    *tmpPtr = *(tmpPtr+1);
	    *(tmpPtr+1) = tmp;
	    string++;
	}
#endif
	if (constMap) 
	{
	    if (StrMapAdd(rtask->RT_strConstMap, &(ptask->PT_runHeapInfo),
			  (TCHAR*)&page[pos]) == FALSE)
	    {
		MemUnlock(rtask->RT_progTask);
		return 0xffff;
	    }
	}
	else 
	{
#ifdef LIBERTY
	    // we should never get here in Liberty
	    ASSERT(FALSE);
#else
	    SSTAdd(*stableP, (TCHAR*)&page[pos]);
#endif
	}

	pos += (strlen((TCHAR*)&page[pos]) + 1) * sizeof(TCHAR);
    }

    ECDLM(afterCall = theHeap.GetFreeMemoryBytes();)
    ECDLM(printf("    After adding all string constants to StrMap, used *%d* bytes.\n", beforeCall-afterCall);)
    ECDLM(beforeCall = afterCall;)

    if (constMap) {
	MemUnlock(rtask->RT_progTask);
    }

    return pos;
}

/*********************************************************************
 *			Page_ParseFunc
 *********************************************************************
 * SYNOPSIS:	Extract a function from a page
 * CALLED BY:	INTERNAL, Page_ParsePage
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY: page looks like:
 *	PM_FUNC		word
 *	funcNum		word
 *	numSegs		byte
 *	numLocals   	word
 *	 segSize	word
 *	 data		<variable>
 *	 [ numSegs of these pairs ]
 *	[more functions]
 *	PM_END
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/10/95	Initial version			     
 * 
 *********************************************************************/
word
Page_ParseFunc(RunTask* rtask, byte* page, word pos)
{
    RunFastFTabEntry	*rfte, ftab;
    word	funcNum, i;
    byte	funcSize;
    word    	numLocals;

    PageMarker  marker;
    NextWordBcl(&page[pos], marker);
    EC_ERROR_IF( marker != PM_FUNC, -1);

    pos += 2;			/* inc beyond the page marker */


    NextWordBcl(&page[pos], funcNum);  pos += 2;
    NextByte(&page[pos], funcSize); pos ++;
    NextWordBcl(&page[pos], numLocals);	pos +=2;

    EC_ERROR_IF(funcNum >= rtask->RT_funTabInfo.FTI_funCount,
		PAGE_INVALID_FUNCTION_NUMBER);

    /* For now, it can't be bigger than 1 segment.. */
#ifdef LIBERTY
    ASSERT(funcSize == 1);
#endif

    /* Ultimately it could be as big as 16...  */
    EC_ERROR_IF(funcSize > 16, PAGE_FUNCTION_TOO_LARGE);

    ftab.RFFTE_numLocals = numLocals;

    /* Copy the code segments into the code table. Again
     * remember that there's only 1 segment. I leave the loop
     * structure so we can remember how things are stored
     * when we support multi-segment routines...
     */

    ECG_ERROR_IF(rtask->RT_funTabInfo.FTI_code == NullHandle, RE_FAILED_ASSERTION);

    for (i=0; i < funcSize; i++)
    {
	word	segSize;
	GONLY(word codeHandle;)

	NextWordBcl(&page[pos], segSize);	pos+=2;
	
#ifdef LIBERTY
	/* Liberty supports only single page functions */
	ASSERT(funcSize == 1);

	/* make a copy from the page because we dump the page later */
	ftab.RFFTE_codeHandle = MallocH(segSize);

	/* can we give a run time error instead of this assert ?????? */
	if (ftab.RFFTE_codeHandle != 0) {
	    byte *block = (byte*)LockH(ftab.RFFTE_codeHandle);
	    EC(theHeap.SetTypeAndOwner(block, "LCOD", (Geode*)0));
	    memcpy(block, &page[pos], segSize);
	    UnlockH(ftab.RFFTE_codeHandle);
	} else {
	    return 0xffff;
	}
#else
	EC_ERROR_IF(segSize > 0x0fff, PAGE_SEGMENT_TOO_LARGE);
	FunTabAppendRoutineCode(rtask->RT_vmFile, &rtask->RT_funTabInfo,
				(byte*)(&page[pos]),
				segSize, &codeHandle);
	if (!i)
	{
	    /* update the start segment for the routine */
	    ftab.RFFTE_codeHandle = codeHandle;
	}
#endif

	pos += segSize;

    }

    FUNTAB_LOCK_TABLE_ENTRY(rtask->RT_funTabInfo, rfte, funcNum);
#ifndef LIBERTY
    EC_ERROR_IF(rfte->RFFTE_codeHandle != NullHandle, -1);
#endif
    *rfte = ftab;
    FUNTAB_UNLOCK_TABLE_ENTRY(rtask->RT_funTabInfo, rfte);
    return pos;
}

#ifndef LIBERTY

/*********************************************************************
 *			RunTaskGetVMFile
 *********************************************************************
 * SYNOPSIS:	Returns the vm file from the runtask.
 * CALLED BY:	EXTERNAL
 * RETURN:	vmFileHandle
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	RON	 2/08/95	Initial version			     
 * 
 *********************************************************************/
VMFileHandle RunTaskGetVMFile(MemHandle rtaskHan)
{
    VMFileHandle	file;
    
    RunTask *rtask;

    rtask = (RunTask*)MemLock(rtaskHan);
    file = rtask->RT_vmFile;
    MemUnlock(rtaskHan);

    return file;
}

/*********************************************************************
 *			RunGetFidoTask
 *********************************************************************
 * SYNOPSIS:	Weirdness. This is really a runtime-style routine.
 *              But it's only called by the compiler. So... where should
 *              it go? Change it if you want, but I'm leaving it in runtime.
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 5/23/95	Initial version
 * 
 *********************************************************************/
MemHandle
RunGetFidoTask(MemHandle rtaskHan)
{
    RunTask 	*rtask;
    MemHandle	fidoTask;

    rtask = (RunTask*)MemLock(rtaskHan);
    EC_ERROR_IF(rtask->RT_cookie != RTASK_COOKIE, -1);
    fidoTask = rtask->RT_fidoTask;
    MemUnlock(rtaskHan);

    return fidoTask;
}

/*********************************************************************
 *			RunSetBuildTime
 *********************************************************************
 * SYNOPSIS: 	set a run task to use buildtime components
 * CALLED BY:	GLOBAL
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/27/95	Initial version			     
 * 
 *********************************************************************/
void
RunSetBuildTime(MemHandle rtaskhan, Boolean flag)
{
    RunTask *rtask;

    rtask = (RunTask*)MemLock(rtaskhan);
    EC_ERROR_IF(rtask->RT_cookie != RTASK_COOKIE, -1);
    rtask->RT_buildTimeComponents = flag;
    MemUnlock(rtaskhan);

}
#endif

/*********************************************************************
 *			RunGetProgHandleFromRunTask
 *********************************************************************
 * SYNOPSIS: 	fetch the program handle from a runtask
 * CALLED BY:	GLOBAL
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/30/95	Initial version			     
 * 
 *********************************************************************/
MemHandle RunGetProgHandleFromRunTask(MemHandle   rtask)
{
    RunTask	*rt;
    MemHandle	prog;

    rt = (RunTask*)MemLock(rtask);
    EC_ERROR_IF(rt->RT_cookie != RTASK_COOKIE, -1);
    prog = rt->RT_progTask;
    MemUnlock(rtask);

    return prog;
}

#ifndef LIBERTY
/*********************************************************************
 *			RunSetTop
 *********************************************************************
 * SYNOPSIS: 	set the top ui object to a new object
 * CALLED BY:	EXTERNAL
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/27/95	Initial version			     
 * 
 *********************************************************************/
void
RunSetTop(MemHandle	rtaskhan, optr	newtop)
{
    RunTask *rtask;

    rtask = (RunTask*)MemLock(rtaskhan);
    EC_ERROR_IF(rtask->RT_cookie != RTASK_COOKIE, -1);
    rtask->RT_uiParent = newtop;
    MemUnlock(rtaskhan);

}
#endif


#if 0
/*********************************************************************
 *			RunNullRTaskCode
 *********************************************************************
 * SYNOPSIS: 	Remove references to items in a compile task
 * CALLED BY:	GLOBAL
 * PASS:    	RunTask (RT_compTime is FRESH or NOT_OWNER)
 * RETURN:  	nothing
 * SIDE EFFECTS:   
 * STRATEGY:
 *	Use on a freshly created RTask, or one one init'ed with
 *	BascoInitRTaskFromCTask (BIRFC); properly empties out RTask
 *	for a BIRFC or deletion. Use before BIRFC, between calls to
 *	BIRFC, and (finally) before RunDestroyTask.
 *
 *	Details:
 *	
 *	If RTask is FRESH, deletes hugearrays created by RunAllocTask,
 *	marks rtask as NOT_OWNER.
 *	
 *	Otherwise, nulls out references that were copied with BIRFC
 *	and destroys those that were created.  See BIRFC header for a
 *	list of these fields.
 *
 *	FIXME: FRESH and NOT_OWNER distinction is not very useful any
 *	more, as only the bughandle is referenced by both compiler and
 *	rtask; and bughandle is never destroyed as it is only around
 *	at runtime.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 3/27/95	Initial version			     
 * 
 *********************************************************************/
void
RunNullRTaskCode(MemHandle rtaskHan)
{
    RunTask *rtask;

    rtask = (RunTask*)MemLock(rtaskHan);
    rtask->RT_uiParent = NullOptr;

    EC_ERROR_IF( rtask->RT_cookie != RTASK_COOKIE, RE_BAD_RTASK );
    EC_ERROR_IF( rtask->RT_compTime == OWNER, RE_FAILED_ASSERTION );

    rtask->RT_compTime = NOT_OWNER;

    ECG_ERROR_IF(rtask->RT_funTabInfo.FTI_code == NullHandle,
		 RE_FAILED_ASSERTION);
    FunTabDestroy(&rtask->RT_funTabInfo);
    StrMapDestroy(rtask->RT_strConstMap);
    rtask->RT_strConstMap = NullHandle;

    SSTDestroy(rtask->RT_exportTable);
    SSTDestroy(rtask->RT_stringFuncTable);
    rtask->RT_exportTable = rtask->RT_stringFuncTable = NullOptr;
    /* Don't decref, as the runtime heap has already been flushed
     * we don't want handle leaks from unfreed arrays,
     * so still need to do this
     */
    RunDestroyModuleVariables(rtaskHan, FALSE);
    rtask->RT_bugHandle = NullHandle;

#ifndef LIBERTY

    ;{
#if 0
	/* Can't do this -- Gandalf thread can't destroy obj blocks
	 * owned by lview thread.  Yes, it's a handle leak, and it's
	 * been around for a while.  But, we will at some point just
	 * destroy everything when the interpreter stops, instead of
	 * cleaning out the runtask and reusing it.
	 * FIXME
	 */
	word	i, count;
	MemHandle	mh;

	/* FIXME: this seems unsafe somehow -- might there be
	 * objects left in the blocks?
	 */
	MemLock(OptrToHandle(rtask->RT_uiBlocks));
	count = ChunkArrayGetCount(rtask->RT_uiBlocks);
	for (i=0; i<count; i++)
	{
	    mh = *(MemHandle*)ChunkArrayElementToPtr
		(rtask->RT_uiBlocks, i, NULL);
	    ObjFreeObjBlock(mh);
	}

	ChunkArrayZero(rtask->RT_uiBlocks);
	MemUnlock(OptrToHandle(rtask->RT_uiBlocks));
#endif
	rtask->RT_uiBlocks = NullOptr;
    }

    /* Null out block and every optr that points into block
     */
    MemFree(rtask->RT_sstBlock);
    rtask->RT_sstBlock = NullHandle;
    rtask->RT_uiBlocks = NullOptr;
    rtask->RT_childModules = NullOptr;

    if (rtask->RT_structInfo != NullOptr)
    {
	MemFree(OptrToHandle(rtask->RT_structInfo));
    }
    rtask->RT_structInfo = NullOptr;
#else
    delete rtask->RT_childModules;
    rtask->RT_childModules = NULL;

    if (rtask->RT_structInfo != NullHandle)
    {
	FreeH(rtask->RT_structInfo);
    }
    rtask->RT_structInfo = NullHandle;
#endif

    MemUnlock(rtaskHan);
}
#endif


/*********************************************************************
 *			RunTaskSetFlags
 *********************************************************************
 * SYNOPSIS:	set the flags of a run task
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/21/96  	Initial version
 * 
 *********************************************************************/
void
RunTaskSetFlags(RTaskHan rtaskHan, byte flagsToSet, byte flagsToClear)
{
    RunTask 	*rt;

    rt = (RunTask*)MemLock(rtaskHan);
    EC_ERROR_IF(rt->RT_cookie != RTASK_COOKIE, -1);
    rt->RT_flags &= ~flagsToClear;
    rt->RT_flags |= flagsToSet;
    MemUnlock(rtaskHan);
}


/*********************************************************************
 *			RunTaskGetFlags
 *********************************************************************
 * SYNOPSIS:	get flags
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/21/96  	Initial version
 * 
 *********************************************************************/
byte RunTaskGetFlags(RTaskHan rtaskHan)
{
    RunTask 	*rt;
    byte    	flags;

    rt = (RunTask*)MemLock(rtaskHan);
    EC_ERROR_IF(rt->RT_cookie != RTASK_COOKIE, -1);
    flags = rt->RT_flags;
    MemUnlock(rtaskHan);
    return flags;
}

/*********************************************************************
 *			RunTaskSetBugHandle
 *********************************************************************
 * SYNOPSIS:	allow setting of bug handle externally
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/14/96  	Initial version
 * 
 *********************************************************************/
void
RunTaskSetBugHandle(MemHandle rtaskHan, MemHandle bugHandle)
{
    RunTask 	*rt;

    rt = (RunTask*)MemLock(rtaskHan);
    EC_ERROR_IF(rt->RT_cookie != RTASK_COOKIE, -1);
    rt->RT_bugHandle = bugHandle;
    MemUnlock(rtaskHan);
}

