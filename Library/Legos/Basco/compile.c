/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		compile.c

AUTHOR:		Jimmy Lefkowitz, Apr 13, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT BascoAllocTask		This function creates and initializes basco
				compile

    INT BascoReportError	Assuming an error has occured in a compile
				task

    INT BascoDestroyTask	Free up memory taken by a compile task.

    EXT BascoLoadFile		Load a BASIC file into a CTask

    GLB BascoCompileModule	Compile a module

    INT BascoCompileCodeFromTask Compiles the code existing within a
    				compile-time task

    INT InitCompileTask		init an alloced compile task

    GLB BascoCompileFunction	compile a single function within a module

    INT isIgnorable		Decides whether a line is ignorable,

    INT stripcr			Strip a CR or LF from the end of a string

    INT LoadFile		Loads a BASIC program file into memory

    INT BascoTerminateRoutine	Tell the compiler task to force finish
				a routine...

    GLB BascoLineAdd		Exported routine for adding just a string

    INT LineAdd			Adds a new line to the program in memory

    INT strncmp_nocase		do a case insensitive string compare

    INT FunctionAdd		Adds an entry to the FUNCTION-SUB lookup table.

    INT FunctionFind		Find a FTabEntry given a name

    INT scan_element		Return and advance past a line element

    GLB BascoGetCompileErrorForFunction
				get compile status of a function in the
				function table

    GLB BascoGetNumFunctions	get number of functions in a compile task

    GLB BascoSetTaskErrorToFunction
				set the task error to the error for a specific
				function

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 4/13/95   	Initial version.

DESCRIPTION:
	compile related stuff

	$Id: compile.c,v 1.1 98/10/13 21:42:37 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "mystdapp.h"
#include <math.h>
#include <thread.h>

#include <geos.h>
#include <resource.h>
#include <heap.h>
#include <chunkarr.h>
#include <char.h>

#include <Ansi/string.h>
#include <Ansi/stdio.h>
#include <Ansi/ctype.h>

#include <Legos/edit.h>
#include <Legos/bug.h>
#include <Legos/fido.h>
#include <Legos/basco.h>
#include <Legos/bascobug.h>
#include <Legos/bug.h>
#include <Legos/bugdata.h>
#include <tree.h>
#include <file.h>

#include <Legos/Bridge/bfuntab.h>

#include "codegen.h"
#include "btoken.h"
#include "ftab.h"
#include "scope.h"
#include "parseint.h"
#include "stable.h"
#include "write.h"
#include "vtab.h"
#include "vars.h"
#include "table.h"
#include "labelint.h"
#include "types.h"

/*- Internal fns */
byte isIgnorable(TCHAR *rl);
void scan_element( TCHAR *buffer, int *pos);
void InitCompileTask(TaskPtr task);
int LoadFile(TaskPtr task, FILE *file );
int LineAdd(TaskPtr task, TCHAR *buffer, BascoFuncType ft);
void BugGetDataFromCTask(MemHandle ctaskHan);


/*********************************************************************
 *			BugGetDataFromCTask
 *********************************************************************
 * SYNOPSIS:	get useful data from the CTask
 * CALLED BY:	BascoCompileCodeFromTask
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 4/ 6/95	Initial version			     
 * 
 *********************************************************************/
void
BugGetDataFromCTask(MemHandle ctaskHan)
{
    TaskPtr 	    	task;
    BugInfoHeader	*b;

    task = MemLock(ctaskHan);
    if (task->bugHandle != NullHandle) 
    {
	word numFuncs, i;
	FuncLabelInfo *fli;
	FTabEntry *ftab;

	b = MemLock(task->bugHandle);
	b->BIH_vmFile = task->vmHandle;
	b->BIH_funcTable  = task->funcTable;
	b->BIH_lineArray  = task->hugeLineArray;
	b->BIH_vtabHeap   = task->vtabHeap;
	b->BIH_stringIdentTable = task->stringIdentTable;
	b->BIH_structIndex = task->structIndex;
	
	numFuncs = FTabGetCount(task->funcTable);

#if ERROR_CHECK
	if (b->BIH_funcLabelTable == 0xcccc) {
	    b->BIH_funcLabelTable = 0;
	}
#endif
	if (b->BIH_funcLabelTable != NullHandle) {
	    MemFree(b->BIH_funcLabelTable);
	}
	/* FIXME - arbitrary limit on number of functions at 255 */
	b->BIH_funcLabelTable = MemAlloc(sizeof(FuncLabelInfo) * 
					 255,
					 HF_SWAPABLE | HF_SHARABLE, 0);
	fli = MemLock(b->BIH_funcLabelTable);

	for (i = 0; i < numFuncs; i++) 
	{
	    ftab = FTabLock(task->funcTable, i);
	    fli->FLI_labelOffset = ftab->labelOffset;
	    fli->FLI_labelSize   = ftab->labelSize;
	    FTabUnlock(ftab);
	    fli++;
	}

	MemUnlock(b->BIH_funcLabelTable);
	MemUnlock(task->bugHandle);
    }
    MemUnlock(ctaskHan);
}

/*********************************************************************
 *			BascoAllocTask
 *********************************************************************
 * SYNOPSIS: 	This function creates and initializes basco compile
 *              time task.
 *
 * CALLED BY:	EXTERNAL BascoLoadModule
 *		(previously global as BascoInitCompiler, LegosCreateInterp)
 * PASS:
 * RETURN:	Compile task handle
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/18/95	Initial version			     
 * 
 *********************************************************************/
MemHandle
BascoAllocTask(VMFileHandle vmfh, BugBuilderInfo *bbi)
{
    MemHandle	    newtask;
    TaskPtr	    task;
    BascoBuiltInEntry   *ce;
    int	    	    i;

    /* get memory for task structure */

    newtask = MemAlloc(sizeof(Task), HF_SWAPABLE | HF_SHARABLE, 
		       HAF_LOCK | HAF_ZERO_INIT);

    if (newtask == NullHandle) {
	return NullHandle;
    }

    task = (TaskPtr)MemDeref(newtask);

    task->task_han = newtask;
    task->vmHandle = vmfh;

    task->clean = TRUE;

    task->err_code = NONE;

    /* New stuff */

    task->ln = (word) -1;
    task->funcNumber = (word) -1;

    task->stringIdentTable = NullOptr; 
    task->stringConstTable = NullOptr;
    task->symbolicConstantTable = NullOptr;

    task->flags = COMPILE_CODE_GEN_ON;
    task->codeBlock = NullHandle;

    task->current_func = -1;
    task->compileID = 0;

    if (bbi != NULL) {
	BascoBugInit(newtask, bbi);
    }

    /* The first code scope is in fact a stack which keeps track
       of interactive calls. This allows a component event handler,
       which gets activated with a direct call into the interpreter,
       to trigger another event, and so on... */


    Scope_InitCode(task);
    task->stringFuncTable  = StringTableCreate(task->vmHandle);
    task->funcTable  = FTabCreate();

    /* fido task and name table used for compile time component typing */
    task->fidoTask = FidoAllocTask();
    /* Try out roy's optimization */
    FidoRegLoadedCompLibs(task->fidoTask);
    
    task->compTypeNameTable = StringTableCreate(task->vmHandle);
    task->compTypeObjBlock = MemAllocLMem(LMEM_TYPE_OBJ_BLOCK, 0);
    MemModifyOtherInfo(task->compTypeObjBlock, 
		       ThreadGetInfo(0,TGIT_THREAD_HANDLE ));   

    /* allocate a memory block to hold code being scanned in */
    task->lineBuffer = MemAlloc(4096, HF_SWAPABLE|HF_SHARABLE, 0);

    task->liberty = FALSE;

    /* add all the strings for the built in functions */
    task->stringBuiltInFuncTable  = StringTableCreate(task->vmHandle);
    ce = MemLockFixedOrMovable(BuiltInFuncs);
    for (i = 0; i < NUM_BUILT_IN_FUNCTIONS; i++)
    {
	StringTableAdd(BUILT_IN_FUNC_TABLE, ce->name);
	ce++;
    }
    MemUnlockFixedOrMovable(BuiltInFuncs);

    MemUnlock(newtask);

    return newtask;
}

/*********************************************************************
 *			BascoReportError
 *********************************************************************
 * SYNOPSIS: 	Assuming an error has occured in a compile task
 *              fill in the function index where the error occured
 *              and the line number too..
 * CALLED BY:	
 * PASS:
 * RETURN:      Appropriate indeces, or sets both to -1 if 
 *              the error flag is clear.
 * SIDE EFFECTS:If error is set, clears the task's error flag.
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/10/95	Initial version			     
 * 
 *********************************************************************/
void BascoReportError(MemHandle taskHan, int *func, int *line) 
{
    TaskPtr task;

    task = MemLock(taskHan);

    if (ERROR_SET) {
	*func = task->funcNumber;
	*line = task->ln;
	SignalError(task);
	/* Clear error*/
	task->err_code = 0;
    }
    else {
	*func = *line = -1;
    }

    MemUnlock(taskHan);
}	

/*********************************************************************
 *			CleanCompileTask
 *********************************************************************
 * SYNOPSIS:	common code for destroy stuff in a compile task 
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Cleans out fields which need to be destroyed before
 *	compiling a module from scratch.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 4/28/95	Initial version			     
 * 
 *********************************************************************/

/* these three macros are used by the following two routines */
#define CHECK_HARR(name)                    \
    if (task->name != NullHandle)          \
	ECCheckHugeArray(task->vmHandle, task->name);

#define CHECK_HARR_NO_NULL(name)                    \
    if (task->name != NullHandle)          \
	ECCheckHugeArray(task->vmHandle, task->name); \
    else						\
        EC_ERROR(BE_TASK_FIELD_IS_EMPTY)

#define DESTROY_HARR(name)			\
    if ( task->name != NullHandle )		\
	HugeArrayDestroy( task->vmHandle, task->name ),task->name=NullHandle;

#define DESTROY_STABLE(name)			\
    if ( task->name != NullOptr )		\
	StringTableDestroy( task->name );	\
    else					\
        EC_ERROR(BE_TASK_FIELD_IS_EMPTY)

#define DESTROY_STABLE_MAYBE_NULL(name)		\
    if ( task->name != NullOptr )		\
	StringTableDestroy( task->name )	\

void
CleanCompileTask(MemHandle taskHan)
{
    TaskPtr	task;

    task = MemLock(taskHan);

    FTabClean(task->task_han);
    if (!task->clean)
    {
#if ERROR_CHECK
	CHECK_HARR(codeBlock);
	CHECK_HARR_NO_NULL(hugeLineArray);
#endif

	DESTROY_HARR( codeBlock );
	DESTROY_HARR(hugeLineArray);

	/* Free up the parse tree, local string names, and local
	   variable storage for each routine... */

	DESTROY_STABLE(stringIdentTable);
	DESTROY_STABLE(structIndex);

	/* These might have been moved to an rtask
	 */
	DESTROY_STABLE_MAYBE_NULL(exportTable);
	DESTROY_STABLE_MAYBE_NULL(stringConstTable);
	DESTROY_STABLE_MAYBE_NULL(symbolicConstantTable);

	VTabExit(task->vtabHeap);
	task->vtabHeap = NullHandle;

	task->clean = TRUE;
    }

    DESTROY_HARR( globalRefs );
    MemUnlock(taskHan);
}

/*********************************************************************
 *			BascoDestroyTask
 *********************************************************************
 * SYNOPSIS: 	Free up memory taken by a compile task.
 *              Leaves the vmfile open though...
 * 
 * CALLED BY:	
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/ 9/95	Initial version			     
 * 
 *********************************************************************/
void BascoDestroyTask(MemHandle taskHan) 
{
    TaskPtr task;
    BugInfoHeader *b;


    task = MemLock(taskHan);

    /* Do this before cleaning the compile task so
       vtabHeap still exists.... */

    if (task->funcTable != NullHandle) {
	FTabDestroy(taskHan);
    }

    /* this routine destroys most of the data.
     */
    CleanCompileTask(taskHan);

#if ERROR_CHECK
    /* NOTE: macro depends on local variable task */
    CHECK_HARR_NO_NULL(code_han);
#endif
    /* NOTE: macro depends on local variable task */
    DESTROY_HARR( code_han  );

    /* NOTE: macro depends on local variable task */
    DESTROY_STABLE(stringBuiltInFuncTable);
    DESTROY_STABLE(compTypeNameTable);

    /* This one might have been moved to an rtask
     */
    DESTROY_STABLE_MAYBE_NULL(stringFuncTable);

#define DESTROY_MEM(name)			\
    if ( task->name != NullHandle )		\
	MemFree( task->name )

    DESTROY_MEM( compTypeObjBlock );
    DESTROY_MEM( lineBuffer );

#undef DESTROY_MEM

    if (task->bugHandle != NullHandle) {
	b = MemLock(task->bugHandle);
	if (b->BIH_funcLabelTable != NullHandle) {
	    MemFree(b->BIH_funcLabelTable);
	}
	MemUnlock(task->bugHandle);
	MemFree(task->bugHandle);
    }

    if (task->fidoTask != NullHandle) {
	FidoDestroyTask(task->fidoTask);
    }
    MemUnlock(taskHan);
    MemFree(taskHan);

}

#undef CHECK_HARR
#undef CHECK_HARR_NO_NULL
#undef DESTROY_HARR
#undef DESTROY_STABLE


/*********************************************************************
 *			BascoLoadFile
 *********************************************************************
 * SYNOPSIS:	Load a BASIC file into a CTask
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/20/94		Initial version			     
 * 
 *********************************************************************/
#pragma argsused
int	BascoLoadFile(MemHandle taskHan, TCHAR *file)
{
    FILE    *input;
    word    oldDS;
    TaskPtr task;

    /* needed for the "r" in fopen */
    oldDS = setDSToDgroup();
    task = (TaskPtr)MemLock(taskHan);

    task->err_code = NONE;
    if ( ( input = fopen( file, "r")) == NULL )
    {
	SetError( task, E_NOPROGFILE );
	SignalError(task);
		
	MemUnlock(taskHan);
	restoreDS(oldDS);
	return FALSE;
    }


    if ( input != NULL )
    {
	LoadFile( task, input );    /* read in the file to memory */
	fclose( input );
	 
	if (ERROR_SET) {
	    SignalError(task);
	    MemUnlock(taskHan);
	    restoreDS(oldDS);
	    return FALSE;
	}
    }

    MemUnlock(taskHan);
    restoreDS(oldDS);
    return TRUE;
}


/*********************************************************************
 *			BascoCompileModule
 *********************************************************************
 * SYNOPSIS: 	Compile a module
 * CALLED BY:	GLOBAL, BascoLoadModule
 * PASS:
 * RETURN:	Compile task
 * SIDE EFFECTS:
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 2/ 4/95	Broke out from BascoLoadModule
 * 
 *********************************************************************/
MemHandle
BascoCompileModule(VMFileHandle vmfh, TCHAR *file)
{
    MemHandle	taskHan;
    TaskPtr 	task;
    Boolean	err = FALSE;

    taskHan = BascoAllocTask(vmfh, NULL);

    if (BascoLoadFile(taskHan, file)) /* signals its own errors :P */
    {
	if (!BascoCompileCodeFromTask(taskHan,FALSE))
	{
	    task = MemLock(taskHan);
	    if (task->err_code) {
		SignalError(task);
	    }
	    MemUnlock(taskHan);
	    err = TRUE;
	}
    } else {
	err = TRUE;
    }

    return (err ? NullHandle : taskHan);
}



/*********************************************************************
 *			BascoCompileCodeFromTask
 *********************************************************************
 * SYNOPSIS: 	Compiles the code existing within a compile-time task
 *              through code generation phase.  
 * 
 *              If updateMode is TRUE, it will do the minimal work
 *              needed to get the system back to a fully-compiled state,
 *              such redoing var_analysis through code generation
 *              for functions after the return type of a function has
 *              changed. Note that for updateMode to work, every
 *              function which changes must first get BascoCompileFunction
 *              called on it....              
 *
 *              Also clears out the compile task to get rid of
 *              any crud which may have been accumulated. An example
 *              of such crud is a long string constant which a user
 *              includes in a function but then takes out of a later
 *              compilation. That constant will still be in the string
 *              constant table and we don't want it there if we need
 *              to write the compiled code to disk...
 *
 * CALLED BY:	
 * PASS:        
 * RETURN:      the memhandle of the task or NullHandle if there's
 *              an error.
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/ 6/95	Initial version	
 *      roy      5/17/95        Jimmy changed this to make use
 *                              of BascoCompileFunction, so each
 *                              function is compiled completely
 *                              one at a time. This won't work now,
 *                              though, since I've added static type-checking
 *                              of function calls; that is, we must have
 *                              parsed ALL functions in a module before
 *                              we can start type-checking any function!
 * 
 *********************************************************************/
MemHandle
BascoCompileCodeFromTask(MemHandle taskHan, Boolean updateMode)
{
    TaskPtr task;
    word    	numRoutines;
    int	    	i, err;
    FTabEntry   *ftab;
    word	oldDS;

    oldDS = setDSToDgroup();
    task = (TaskPtr)MemLock(taskHan);

    task->compileID++;
RESTART:
    if (!updateMode || task->flags & COMPILE_NEEDS_FULL_RECOMPILE)
    {
	/* Something strange is going on... to help track it down
	 * FIXME: remove later
	 */
	TaskPtr	oldTask;
	oldTask = task;

	/* If this isn't an update, clean out any cruft from previous
	   compiles.... 
        */
	CleanCompileTask(taskHan);
	if (task != oldTask) {
	    CFatalError(BE_FAILED_ASSERTION);
	}
	InitCompileTask(task);
    }


    /* COMPILE ALL CODE */

    err = FALSE;

    /* When compiling code for the entire module we need to parse and
       var analyze all functions first because we need to know about
       all the arguments ahead of time for type-checking... */

    task->err_code = NONE;

    numRoutines = FTabGetCount(task->funcTable);

    for (i = 0; i < numRoutines; i++) 
    {
	task->funcNumber = i;

	ftab = FTabLock(task->funcTable, i);
	
	if (!updateMode || ftab->compStatus < CS_PARSED)
	{
	    ftab->lastCompileError = NONE;
#ifdef DOS_VERBOSE
	    printf("parsing function %d\n", i);
#endif
	    if (Parse_Function(task, i) == NullHandle) 
	    {
		err = TRUE;
		ftab = FTabDeref(task->funcTable, i);
		goto DONE;
	    }
	    ftab = FTabDeref(task->funcTable, i);
	}
	FTabUnlock(ftab);

	/* if we came across a reason for a full recompile (and right now
	 * this only happens at the parse stage and var analyze stage) 
	 * just restart everything
	 */
	if (task->flags & COMPILE_NEEDS_FULL_RECOMPILE)
	{
	    goto RESTART;
	}
    }

    /* Do var analysis after all parsing to make sure all exports
       have been identified before creating the global var table */

    for (i = 0; i < numRoutines; i++) 
    {
	task->funcNumber = i;

	ftab = FTabLock(task->funcTable, i);

	if (!updateMode || ftab->compStatus < CS_VAR_ANALYZED) 
	{
#ifdef DOS_VERBOSE
	    printf("var analysing function %d\n", i);
#endif
	    if (!VarAnalyzeFunction(task, i)) 
	    {
		if (task->flags & COMPILE_NEEDS_FULL_RECOMPILE)
		{
		    FTabUnlock(ftab);
		    goto RESTART;
		}
		err = TRUE;
		goto DONE;
	    }
	}
	FTabUnlock(ftab);
    }


/* this needs to be called before BugUpdateBreaksForFunction */
    BugGetDataFromCTask(taskHan);

    for (i = 0; i < numRoutines; i++) 
    {
	ftab = FTabLock(task->funcTable, i);
	if (!updateMode || ftab->compStatus < CS_TYPE_CHECKED) 
	{
#ifdef DOS_VERBOSE
	    printf("type checking function %d\n", i);
#endif
	    if (!TypeCheckFunction(task, i)) 
	    {
		err = TRUE;
		goto DONE;
	    }
	}

	if (!updateMode || ftab->compStatus < CS_CODE_GENERATED) 
	{
#ifdef DOS_VERBOSE
	    printf("code generating function %d\n", i);
#endif
	    if (!CodeGenAddFunction(task, i)) 
	    {
		ftab = FTabDeref(task->funcTable, i);
		err = TRUE;
		goto DONE;
	    }
	    ftab = FTabDeref(task->funcTable, i);
	}
	FTabUnlock(ftab);
    }

    /* fixup globals */
#ifdef DOS_VERBOSE
	    printf("linking function %d\n", i);
#endif
    if (LabelDoGlobalRefFixups(task, GRT_MOD_VAR|GRT_CONSTANT, 0) 
	== FALSE)
    {
	ftab = FTabLock(task->funcTable, task->funcNumber);
	err = TRUE;
    }
DONE:
    restoreDS(oldDS);
    if (err == TRUE) {
#ifdef DOS
	char	fname[128];
	EditGetRoutineName(task->task_han, task->funcNumber, fname);
	printf("Compile Error (%s : %d): %s\n", fname, task->ln, ConvertCompileErrorCodeToString(task->err_code));
#endif
	ftab->compStatus = CS_NAKED;
	ftab->lastCompileLine = task->ln;
	ftab->lastCompileError = 
	    (task->err_code == NONE) ? E_SYNTAX : task->err_code;
	FTabUnlock(ftab);
    }

    VMUpdate(task->vmHandle);
    MemUnlock(taskHan);
    if (err) {
	return NullHandle;
    } else {
	return taskHan;
    }
}

/*********************************************************************
 *			InitCompileTask
 *********************************************************************
 * SYNOPSIS:	Do the reverse of CleanCompileTask
 * CALLED BY:	INTERNAL, BascoCompileCodeFromTask, BascoCompileFunction
 * SIDE EFFECTS:
 *	Create fields which are necessary only for compiling modules.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 3/30/95	Initial version			     
 * 
 *********************************************************************/
void
InitCompileTask(TaskPtr task)
{
    word    dummy;
    word    oldDS;

    /* Hm... are we overwriting fields?
     */
    EC_ERROR_IF(!task->clean, BE_FAILED_ASSERTION);

    task->clean = 0;
    task->stringIdentTable = StringTableCreate(task->vmHandle);
    task->stringConstTable = StringTableCreate(task->vmHandle);
    task->symbolicConstantTable = StringTableCreate(task->vmHandle);
    task->exportTable	   = StringTableCreate(task->vmHandle);
    oldDS = setDSToDgroup();
    StringTableAdd(task->stringConstTable, _TEXT(""));
    restoreDS(oldDS);

    task->structIndex = StringTableCreate(task->vmHandle);

    task->codeBlock = HugeArrayCreate(task->vmHandle, 0, 0);
    /* hack to avoid having element 0 ever used */
    HugeArrayAppend(task->vmHandle, task->codeBlock, 1, &dummy);

    if (task->hugeLineArray != NullHandle) {
	HugeArrayDestroy(task->vmHandle, task->hugeLineArray);
    }
    task->hugeLineArray = HugeArrayCreate(task->vmHandle, sizeof(LineData), 0);

    task->vtabHeap = VTabInit();

    task->globalRefs = HugeArrayCreate(task->vmHandle, sizeof(GlobalRefData), 
				       0);
    if (task->globalRefs == NullHandle)
    {
	EC_ERROR(BE_FAILED_ASSERTION);
	return;
    }

#if 0
#ifdef DOS
    task->globalRefs = ChunkArrayCreate(0, sizeof(GlobalRefData), 0, 0);
#else
    task->globalRefs = MemAllocLMem(LMEM_TYPE_GENERAL, 0);
    if (task->globalRefs == NullHandle)
    {
	EC_ERROR(BE_FAILED_ASSERTION);
	return;
    }
    MemLock(task->globalRefs);
    if (ChunkArrayCreate(task->globalRefs, sizeof(GlobalRefData), 0, 0) !=
	GLOBAL_REFS_CHUNK)
    {
	EC_ERROR(BE_FAILED_ASSERTION);
	return;
    }
    MemUnlock(task->globalRefs);
#endif
#endif

{
#if ERROR_CHECK
    word	newHeap;
    newHeap = 
#endif
         VTAlloc(task->vtabHeap);	/* Alloc global vtab */
    EC_ERROR_IF(newHeap != GLOBAL_VTAB, BE_FAILED_ASSERTION);
}
    task->flags |= COMPILE_FORCE_DECLS;
    task->flags &= ~COMPILE_NEEDS_FULL_RECOMPILE;
    return;
}

/*********************************************************************
 *			BCF_UncompileCallers
 *********************************************************************
 * SYNOPSIS:	Restore callers of <funcNum> to CS_NAKED
 * CALLED BY:	INTERNAL, BascoCompileFunction
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/14/95	Initial version
 * 
 *********************************************************************/
void
BCF_UncompileCallers(TaskPtr task, int funcNumber)
{
    sword	numRoutines, i;
    FTabEntry*	ftab;
    
    if (task->globalRefs == NullHandle) {
	numRoutines = FTabGetCount(task->funcTable);
	for (i=0; i<numRoutines; i++)
	{
	    ftab = FTabLock(task->funcTable, i);
	    ftab->compStatus = CS_NAKED;
	    FTabDirty(ftab);
	    FTabUnlock(ftab);
	}
    } else {
	/* Quick version */
	word	c, i, skipFunc;
	GlobalRefData*	grd;

	/* All grd for a given function will be adjacent
	 */
	c = HugeArrayGetCount(task->vmHandle, task->globalRefs);
	for (i=0, skipFunc=0xffff; i<c; i++, grd++)
	{
	    word    dummy;
	    HugeArrayLock(task->vmHandle, task->globalRefs, i, (void**)&grd,
			  &dummy);
	    if (grd->GRD_funcNumber == skipFunc) 
	    {
		HugeArrayUnlock(grd);
		continue;
	    }

	    if (grd->GRD_type & GRT_ROUTINE_CALL &&
		grd->GRD_index == funcNumber)
	    {
		ftab = FTabLock(task->funcTable, grd->GRD_funcNumber);
		ftab->compStatus = CS_NAKED;
		FTabDirty(ftab);
		FTabUnlock(ftab);
		skipFunc = grd->GRD_funcNumber; /* skip the rest */
	    }
	    HugeArrayUnlock(grd);
	}
    }
}

/*********************************************************************
 *			BascoCompileFunction
 *********************************************************************
 * SYNOPSIS: 	compile a single function within a module
 *              Should be used to process every function as it's added
 *              (or modified).
 *
 * CALLED BY:	GLOBAL
 * PASS:    	ctask:	    Compile Task handle
 *	    	funcNumber: index into ftab table
 *
 * RETURN:
 * SIDE EFFECTS:    if its a new function, allocate a new ftab entry
 *	    	    otherwise, clean out the old one and reuse it
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 3/22/95	Initial version			     
 * 
 *********************************************************************/
Boolean
BascoCompileFunction(MemHandle ctask, int funcNumber)
{
    Boolean 	ok = TRUE;
    Boolean	tweakNeeded;
    TaskPtr 	task;
    FTabEntry	oldFtab;
    FTabEntry	*ftab;
    int	    	i, numRoutines;
    word	oldDS;

    oldDS = setDSToDgroup();
    task = MemLock(ctask);

    /* clear out the error code */
    task->err_code = NONE;
    task->compileID++;

    if (task->stringConstTable == NullOptr) 
    {
	InitCompileTask(task);
    }

    ftab = FTabLock(task->funcTable, funcNumber);
    /* Loop below assumes that function is naked and will have its
     * vtab recreated
     */
    ftab->compStatus = CS_NAKED;
    oldFtab.funcType = ftab->funcType;
    oldFtab.numParams = ftab->numParams;
    oldFtab.vtab = ftab->vtab;
    ftab->vtab = NULL_VTAB;
    FTabUnlock(ftab);

    /* Bring all routines to CS_VAR_ANALYZED state so their call types
     * are up to date
     */
    numRoutines = FTabGetCount(task->funcTable);
RESTART:
    for (i = 0; i < numRoutines; i++) 
    {
	CompStatus	status;
	task->funcNumber = i;

	ftab = FTabLock(task->funcTable, i);
	status = ftab->compStatus;
	if (ftab->compStatus < CS_PARSED) {
	    ftab->lastCompileError = NONE;
	}
	FTabUnlock(ftab);

	if (status < CS_PARSED) 
	{
	    if (Parse_Function(task, i) == NullHandle) 
	    {
		ok = FALSE;
		goto done;
	    }

	    /* if we came across a reason for a full recompile (and right now
	     * this only happens at the parse stage) just recompile everything
	     */
	    if (task->flags & COMPILE_NEEDS_FULL_RECOMPILE)
	    {
		ok = BascoCompileCodeFromTask(ctask, 0);
		goto done;
	    }
	}
	
	if (status < CS_VAR_ANALYZED) 
	{
	    if (!VarAnalyzeFunction(task, i)) 
	    {
		if (task->flags & COMPILE_NEEDS_FULL_RECOMPILE)
		{
		    ok = BascoCompileCodeFromTask(ctask, 0);
		    goto done;
		}
		ok = FALSE;
		goto done;
	    }
	}
    }


    /* If the call type of the function has changed, recompile any
     * functions which called it.  Call type = func vs sub, # params,
     * type of params.
     *
     * If we can't check (because old ftab entry didn't have a vtab;
     * probably hit an error last time it was compiled) just assume
     * that callers need recompilation.
     */
    tweakNeeded = FALSE;
    ftab = FTabLock(task->funcTable, funcNumber);
    if (ftab->funcType  != oldFtab.funcType  ||
	ftab->numParams != oldFtab.numParams ||
	oldFtab.vtab == NULL_VTAB)
    {
	tweakNeeded = TRUE;
    } else {
	VTabEntry	newVte, oldVte;
	byte		i, numVarsToCheck;

	/* Assumes that tables are in order of increasing offset
	 * in scope (maybe not true for global scope, but should
	 * be true for all local scopes)
	 */
	numVarsToCheck = ftab->numParams;
	if (ftab->funcType == FT_FUNCTION) numVarsToCheck++;
		
	for (i = 0; i < numVarsToCheck; i++)
	{
	    VTLookupIndex(task->vtabHeap, ftab->vtab, i, &newVte);
	    VTLookupIndex(task->vtabHeap, oldFtab.vtab, i, &oldVte);
	    EC_ERROR_IF(newVte.VTE_offset != oldVte.VTE_offset,
			BE_FAILED_ASSERTION);
	    EC_ERROR_IF(newVte.VTE_offset != 5*i, BE_FAILED_ASSERTION);
	    if (newVte.VTE_type != oldVte.VTE_type) {
		tweakNeeded = TRUE;
		break;
	    }
	}
    }
    FTabUnlock(ftab);

    if (tweakNeeded) {
	BCF_UncompileCallers(task, funcNumber);
    }
			 
    if (oldFtab.vtab != NULL_VTAB) {
	VTDestroy(task->vtabHeap, oldFtab.vtab);
    }

    /* ---------------------------------------------------------*/
    /* This is it.  Parse, Analyze variables, Typecheck, Codegen.
     * Only perform the next step if the previous ones succeeded.
     */

    ok = ok && TypeCheckFunction(task, funcNumber);
    ok = ok && CodeGenAddFunction(task, funcNumber);

 done:
    restoreDS(oldDS);
    if (!ok)
    {
	ftab = FTabLock(task->funcTable, funcNumber);
	ftab->compStatus = CS_NAKED;
	ftab->lastCompileLine = task->ln;
	ftab->lastCompileError =
	    (task->err_code == NONE) ? E_INTERNAL : task->err_code;
	FTabUnlock(ftab);
    }

    VMUpdate(task->vmHandle);
    MemUnlock(ctask);
    return ok;
}

/*********************************************************************
 *			isIgnorable
 *********************************************************************
 * SYNOPSIS:	Decides whether a line is ignorable,
 *		i.e. is NULL, is all whitespace, is a REM, etc.
 * CALLED BY:	
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	10/21/94		Initial version			     
 * 
 *********************************************************************/

byte isIgnorable(TCHAR *rl) 
{
    int position=0;
    if (*rl != C_NULL)
	adv_ws(rl,&position);
    rl+=position;

    /* ignore blank lines and REMS */
    if (*rl == C_NULL
	|| *rl == C_FF
	|| *rl == C_LINEFEED
	|| *rl == 0x1a
	|| *rl == C_ENTER) {
	return 1;
    }

    return 0;
}


/*********************************************************************
 *			stripcr
 *********************************************************************
 * SYNOPSIS: 	Strip a CR or LF from the end of a string
 * CALLED BY:	INTERNAL, LoadFile
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
stripcr( TCHAR *s )
{

    while ( *s != 0 )
    {
	switch( *s )
	{
	    case C_ENTER:
	    case C_LINEFEED:
		*s = C_NULL;
		return TRUE;
	}
	++s;
    }
    *s = C_NULL;
    return TRUE;
}

/*********************************************************************
 *			LoadFile
 *********************************************************************
 * SYNOPSIS: 	Loads a BASIC program file into memory
 * CALLED BY:	INTERNAL, BascoLoadFile
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

#define MAXREADLINESIZE 4096
#ifdef DO_DBCS
/* this is a routine defined in manager.asm */
#define fgets fgets_dbcs
extern void fgets_dbcs(TCHAR *dst, word maxSize, FILE *file);
#endif

int
LoadFile( TaskPtr task, FILE *file )
{
    int		position;
    TCHAR*	read_line;
    MemHandle	rl_han;

    TCHAR    *cp;

    rl_han = MemAlloc(MAXREADLINESIZE, HF_SWAPABLE | HF_SHARABLE,
		      HAF_LOCK);
    cp = MemDeref(rl_han);
    cp[0] = DBG_NORMAL;
    read_line = cp + 1;
    while ( feof( file ) == FALSE )
    {
	int len;

	read_line[ 0 ] = C_NULL;

	fgets( read_line, MAXREADLINESIZE, file );

	len = strlen(read_line);
	stripcr( read_line );

       /* be sure that this is not EOF with a NULL line */
	if (( feof( file ) == FALSE ) || (len > 0 ))
	{
 	    position = 0;
	    adv_ws(read_line, &position);
	    BascoLineAdd(task->task_han, cp);
       	}
    }
    /* close file stream */

    task->current_func = -1;

    MemFree(rl_han);
    return TRUE;
}

/*********************************************************************
 *			BascoTerminateRoutine
 *********************************************************************
 * SYNOPSIS: 	Tell the compiler task to force finish a routine...
 *              Really just a hack to check for errors when downloading
 *              incorrectly formed code from the editor...
 * CALLED BY:	
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/ 7/95	Initial version			     
 * 
 *********************************************************************/
void BascoTerminateRoutine(MemHandle taskHan) 
{
    TaskPtr task;

    task = MemLock(taskHan);
    task->current_func = -1;
    MemUnlock(taskHan);
}


/*********************************************************************
 *			BascoBlockAdd
 *********************************************************************
 * SYNOPSIS: 	Exported routine for adding a block of text
 *              to the interpreter's code store...
 * CALLED BY:	GLOBAL
 * PASS:	TCHAR *block
 * RETURN:	nothing
 * SIDE EFFECTS:none
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/ 6/95	Initial version			     
 * 
 *********************************************************************/
void BascoBlockAdd(MemHandle taskHan, TCHAR *input)
{
    TCHAR save;
    TCHAR *current = input;

    while (*input != C_NULL) {
	if ((*input == C_ENTER) || (*input == C_LINEFEED)) {
	    save = *input;
	    *input = C_NULL;
	    BascoLineAdd(taskHan, current);
	    *input = save;
	    while ((*input == C_LINEFEED) || (*input == C_ENTER))
		input++;	/* skip extra newlines */
	    current = input;
	} else {
	    input++;
	}
    }

    if (*current != C_NULL) BascoLineAdd(taskHan, current);
}    


/*********************************************************************
 *			BascoLineAdd
 *********************************************************************
 * SYNOPSIS: 	Exported routine for adding just a string
 *              to the interpreter's code store...
 * CALLED BY:	GLOBAL
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/ 6/95	Initial version			     
 * 
 *********************************************************************/
BascoFuncType
BascoLineAdd(MemHandle taskHan, TCHAR *input) 
{
    word	oldDS;
    BascoFuncType notfunc = FT_NONE;
    byte	lineOffset = 0;
    TaskPtr	task;
    int		pos;
    
    oldDS = setDSToDgroup();
    task = MemLock(taskHan);

    /* Since we're adding it from the interpreter, skip over
       the first byte which indicates debug info...
    */
    if (IS_LINE_DESCRIPTOR(*input))
    {
	lineOffset = 1;
    }

    if (!strncmp_nocase(input+lineOffset, _TEXT("FUNCTION "), FUNCTION_LENGTH_PLUS_ONE))
    {
	notfunc = FT_FUNCTION;
    }
    else if (!strncmp_nocase(input+lineOffset, _TEXT("SUB "), SUB_LENGTH_PLUS_ONE))
    {
	notfunc = FT_SUBROUTINE;
    }
    
    if ( (notfunc != FT_NONE) )
    {
	if (task->current_func != -1)
	{
	    /* not allowed to define functions inside functions */
	    SetError(task, E_FUNCTION_INSIDE_FUNCTION);
	    MemUnlock(taskHan);
	    restoreDS(oldDS);
	    return notfunc;
	}

    }
    
    if (LineAdd( task, input, notfunc ) == TRUE)
    {
	pos = 0;
	adv_ws(input+lineOffset, &pos);
	if (!strncmp_nocase(input+lineOffset+pos, _TEXT("END"), END_LENGTH))
	{
	    pos += END_LENGTH;
	
	    adv_ws(input+lineOffset, &pos);
	    if (!strncmp_nocase(input+lineOffset+pos,
				_TEXT("FUNCTION"), 
				FUNCTION_LENGTH))
	    {
		task->current_func = -1;
		notfunc = FT_END_FUNCTION;
	    }
	    else if (!strncmp_nocase(input+lineOffset+pos,
				     _TEXT("SUB"), 
				     SUB_LENGTH))
	    {
		task->current_func = -1;
		notfunc = FT_END_SUB;
	    }
	}
    }
    else
    {
	notfunc = FT_ERROR;
    }

    MemUnlock(taskHan);
    restoreDS(oldDS);
    return notfunc;
}

/*********************************************************************
 *			LineAdd
 *********************************************************************
 * SYNOPSIS: 	Adds a new line to the program in memory
 * CALLED BY:	INTERNAL, LoadFile
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
LineAdd( TaskPtr task, TCHAR *buffer, BascoFuncType ft )
{
    dword	     start, end;
    int		     pos;
    FTabEntry	     *f;
    TCHAR   	     *cp;

    cp = buffer;
  
    if(IS_LINE_DESCRIPTOR(*buffer))
    {
	buffer++;
    }

#if ERROR_CHECK
    ECCheckHugeArray( task->vmHandle, task->code_han );
#endif

    if (ft != FT_NONE)
    {
	end = HugeArrayGetCount(task->vmHandle, task->code_han);
    }
    else
    {
 	if (task->current_func == -1) 
 	{
	    /* ignore blank lines between functions */
	    if (!isIgnorable(buffer))
	    {
		SetError(task, E_CODE_OUTSIDE_FUNCTION);
		return FALSE;
	    }
	    return TRUE;
 	}

	Scope_FindRange(task, task->current_func, &start, &end);
	Scope_UpdateAll(task, start, -1);
	end++;
    }
    if (cp != buffer) 
    {
	HugeArrayInsert(task->vmHandle, task->code_han, 
			sizeof(TCHAR) * (strlen(buffer)+2),
			end, cp);
    }
    else
    {
	TCHAR	*ptr;
	word	size;

	HugeArrayInsert(task->vmHandle, task->code_han, 
			sizeof(TCHAR) * (strlen(buffer)+2),
			end, NULL);
	HugeArrayLock(task->vmHandle, task->code_han, end, 
		      (void**)&ptr, &size);
	*ptr = DBG_NORMAL;
	strcpy(ptr+1, buffer);
	HugeArrayDirty(ptr);
	HugeArrayUnlock(ptr);
    }
    

    if (ft != FT_NONE)
    {
       /* NOTE: this code must come after the updatescopes call, since it
	* will be adding entries to the same huge array
	*/

       if (ft == FT_FUNCTION) {
	   pos = FUNCTION_LENGTH;
       } else {
	   pos = SUB_LENGTH;
       }
       adv_ws(buffer, &pos);
       f = FunctionFind(task, buffer+pos);
       if (f == NULL) 
       {
	   int		name_end;
	   TCHAR	oldc, *name;

	   adv_ws(buffer, &pos);
	   name = buffer + pos;
	   name_end = pos;
	   scan_element(buffer, &name_end);
	   oldc = buffer[name_end];
	   buffer[name_end] = C_NULL;
	   task->current_func = FTabAddEntry(task, name, ft, end);
	   buffer[name_end] = oldc;
       }
       else
       {
	   /* nuke the scope for the old code */
	   Scope_NukeScope(task, task->code_han, f->index);
	   task->current_func = f->index;
	   f->lineElement = SELF_CONSTRUCT(f->index,
					   HugeArrayGetCount(task->vmHandle,
							    task->code_han))-1;
	   f->funcType = ft;
	   f->compStatus = CS_NAKED;	/* reset compiled status */
	   FTabDirty(f);
	   FTabUnlock(f);
       }
    }

    
    EC_ERROR_IF(task->current_func == -1, BE_FAILED_ASSERTION);
    FTabIncrementNumLines(task, task->current_func);
    return TRUE;
}



/*********************************************************************
 *			SetIdentError
 *********************************************************************
 * SYNOPSIS:	routine to specify what type of ident error we get
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
int
SetIdentError(TaskPtr task, TokenCode tc)
{
    if (TokenIsKeyword(tc)) {
	return SetError(task, E_BAD_KEYWORD_USE);
    } else {
	return SetError(task, E_EXPECT_IDENT);
    }
}

/***************************************************************

	FUNCTION:	SetError()

	DESCRIPTION:	This function is called to handle errors
			in Bywater BASIC.  It displays the error
			message, then calls the break_handler()
			routine.

***************************************************************/
int
SetError( TaskPtr task, ErrorCode ec )
{
    if (task->err_code == NONE) 
    {
	task->err_code = ec;
    }
    return TRUE;    
}
	


/*********************************************************************
 *			strncmp_nocase
 *********************************************************************
 * SYNOPSIS:	do a case insensitive string compare
 * CALLED BY:	
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 7/94		Initial version			     
 * 
 *********************************************************************/
int
strncmp_nocase( TCHAR *a, TCHAR *b, int n )
{
    int	i;

#if ERROR_CHECK
   if (a == NULL || b == NULL) {
       EC_ERROR(-1);
   }
#endif

    for(i=0; i<n && *a && *b; i++)
    {	
	if (toupper(*a++) != toupper(*b++))
	{
	    return 1;
	}
    }

    return ( (i<n) ? 1 : 0 );
}



/*********************************************************************
 *			BascoDeleteRoutine
 *********************************************************************
 * SYNOPSIS:	delete a function
 * CALLED BY:	
 * RETURN:  	TRUE if everything hunky dory, FALSE otherwise
 * SIDE EFFECTS:
 * STRATEGY:
 *	    	we need to not only delete the entry in the funcTable
 *	    	but we need to delete the entry in the stringFuncTable
 *	    	and since there is no way to delete the entry in the
 *	    	stringFuncTable, we will create a new string func table
 *	    	and add all the entries except the one we are deleting
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 9/11/95	Initial version
 * 
 *********************************************************************/
Boolean
BascoDeleteRoutine(MemHandle ctask, int funcNumber)
{
    TaskPtr task;
    Boolean retval;
    FTabEntry	*ftab;

    task = MemLock(ctask);
    EC_BOUNDS(task);

    /* first make sure its a valid funcNumber */
    if (task->vmHandle == NullHandle || task->funcTable == NullHandle ||
	(FTabGetCount(task->funcTable) <= funcNumber))
    {
	MemUnlock(ctask);
	return FALSE;
    }

    ftab = FTabLock(task->funcTable, funcNumber);
    ftab->deleted = TRUE;
    FTabUnlock(ftab);

    retval = LabelDoGlobalRefFixups(task, GRT_ROUTINE_CALL, funcNumber);

    /* adjust breakpoint function numbers appropriately */
    if (task->bugHandle != NullHandle)
    {
	BugUpdateBreaksForDeletedFunction(task->bugHandle, funcNumber);
    }
    MemUnlock(ctask);

    return retval;
}

/*********************************************************************
 *			FunctionFind
 *********************************************************************
 * SYNOPSIS: 	Find a FTabEntry given a name
 * CALLED BY:	INTERNAL, LineAdd
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	This C function finds an FTabEntry structure
 *	corresponding to a name in the FUNCTION- SUB lookup table.
 *	Send NULL as offset if not interested in offset.  Otherwise
 *	you will get the offset of the entry within the function
 *	block.
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/18/95	Initial version			     
 * 
 *********************************************************************/
FTabEntry *
FunctionFind( TaskPtr task, TCHAR *buffer)
{
    FTabEntry	*f = NULL;
    dword   	index;
    TCHAR    	*cp;
    word	oldDS;

    /* remove open-paren from string */

    if (task->stringFuncTable == NullOptr)
    {
	return NULL;
    }

    /* we are often passed "funcname [<whitespace>] (" 
     * so check for the open paran, and whitespace
     */
    cp = strchr(buffer, C_LEFT_PAREN);
    if (cp != NULL)
    {
	cp--;
	while (isspace(*cp))
	{
	    cp--;
	}
	cp++;
	*cp = C_NULL;
    }

    oldDS = setDSToDgroup();
    if (!strcmp(buffer, _TEXT("module_init"))) {
	buffer = _TEXT("duplo_start");
    }
    index = StringTableLookupString(task->stringFuncTable, buffer);
    restoreDS(oldDS);
    if (index == NullElement) 
    {
	return NULL;
    }

    f = FTabLock(task->funcTable, index);
    return f;
}

/*********************************************************************
 *			scan_element
 *********************************************************************
 * SYNOPSIS: 	Return and advance past a line element
 * CALLED BY:	INTERNAL, FunctionAdd
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	This function reads characters in <buffer> beginning at <pos> and
 *	advances past a line element, incrementing <pos> appropri- ately and
 *	returning the line element in <element>.
 *
 *	This function is almost identical to adv_element(), but it will not
 *	stop at a full colon.  This is necessary to detect a label in
 *	the first element position.  If MULTISEG_LINES is defined as
 *	TRUE, adv_element() will stop at the colon, interpreting it as
 *	the end-of-segment marker.
 *
 *	this routine returns TRUE if its a label, FALSE otherwise
 *	
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/18/95	Initial version			     
 * 
 *********************************************************************/
extern void
scan_element( TCHAR *buffer, int *pos)
{
   int 	    	loop;	        /* control loop */
   int 	    	str_const;	/* boolean: building a string constant */
   TCHAR	*cp, c;


   /* advance beyond any initial whitespace */

   adv_ws( buffer, pos );

   cp = buffer + *pos;
   /* now loop while building an element and looking for an
      element terminator */

   loop = TRUE;
   str_const = FALSE;

   c = *cp;

   while ( loop == TRUE )
   {
      switch( *cp )
      {
	 case C_COMMA:			/* element terminators */
	 case C_SEMICOLON:
	 case C_EQUAL:
	 case C_SPACE:
	 case C_TAB:
	 case C_NULL:
	 case C_LINEFEED:
	 case C_ENTER:
	 case C_LEFT_PAREN:
	    if ( str_const == TRUE )
	    {
		cp++;
	    }
	    else
	    {
		*pos = cp - buffer;
		if (c == C_COLON) {
		    return;
		} else {
		    return;
		}
	    }
	    break;

	 case C_QUOTE:		       /* string constant */
	    cp++;
	    if ( str_const == TRUE )	/* termination of string constant */
	    {
		*pos = cp - buffer;
		return;
	    }
	    else			/* beginning of string constant */
	    {
		str_const = TRUE;
	    }
	    break;

	 default:
	    c = *cp++;
	    break;
	}
  }
   EC_ERROR(-1);
}



/*********************************************************************
 *			BascoGetCompileErrorForFunction
 *********************************************************************
 * SYNOPSIS:	get compile status of a function in the function table
 * CALLED BY:	GLOBAL
 * RETURN:  	error code as a word (NONE = 0 for no error)
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 4/13/95	Initial version			     
 * 
 *********************************************************************/
word BascoGetCompileErrorForFunction(MemHandle taskHan, int funcNumber)
{
    TaskPtr 	task;
    FTabEntry	*ftab;
    word    	lce;

    task = MemLock(taskHan);
    EC_BOUNDS(task);
    ftab = FTabLock(task->funcTable, funcNumber);
    lce = ftab->lastCompileError;
    FTabUnlock(ftab);
    MemUnlock(taskHan);
    return lce;
}



/*********************************************************************
 *			BascoSetTaskErrorToFunction
 *********************************************************************
 * SYNOPSIS:	set the task error to the error for a specific function
 * CALLED BY:	GLOBAL
 * RETURN:  	nothing
 * SIDE EFFECTS:    fields in task updated 
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 4/13/95	Initial version			     
 * 
 *********************************************************************/
void BascoSetTaskErrorToFunction(MemHandle taskHan, int funcNumber)
{
    TaskPtr 	task;
    FTabEntry	*ftab;

    task = MemLock(taskHan);
    EC_BOUNDS(task);
    ftab = FTabLock(task->funcTable, funcNumber);
    task->ln = ftab->lastCompileLine;
    task->err_code = ftab->lastCompileError;
    task->funcNumber = funcNumber;
    FTabUnlock(ftab);
    MemUnlock(taskHan);
}


/*********************************************************************
 *			BascoSetCompileTaskBuildTime
 *********************************************************************
 * SYNOPSIS:	set the compile task buildTime flag
 * CALLED BY:	GLOBAL
 * RETURN:  	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 5/23/95	Initial version
 * 
 *********************************************************************/
void
BascoSetCompileTaskBuildTime(MemHandle ctaskHan, byte buildTime)
{
    TaskPtr ctask;

    ctask = MemLock(ctaskHan);
    if (buildTime) {
	ctask->flags |= COMPILE_BUILD_TIME;
    } else {
	ctask->flags &= ~COMPILE_BUILD_TIME;
    }
    MemUnlock(ctaskHan);
}


/*********************************************************************
 *			BascoSetCompileTaskOptimize
 *********************************************************************
 * SYNOPSIS:	set or unset OPTIMIZE bit
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/11/95	Initial version
 * 
 *********************************************************************/
void
BascoSetCompileTaskOptimize(MemHandle ctaskHan, byte optimize)
{
    TaskPtr ctask;

    ctask = MemLock(ctaskHan);
    if (optimize) {
	ctask->flags |= COMPILE_OPTIMIZE;
    } else {
	ctask->flags &= ~COMPILE_OPTIMIZE;
    }
    MemUnlock(ctaskHan);
}


/*********************************************************************
 *			BascoCompileTaskSetFidoTask
 *********************************************************************
 * SYNOPSIS:	null out FidoTask in a comile task
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	zero out the fidoTask field so BascoDestroyTask doesn't free it
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 5/23/95	Initial version
 * 
 *********************************************************************/
MemHandle
BascoCompileTaskSetFidoTask(MemHandle ctaskHan, MemHandle fidoTask)
{
    TaskPtr 	ctask;
    MemHandle	oldFidoTask;

    ctask = MemLock(ctaskHan);
    oldFidoTask = ctask->fidoTask;
    ctask->fidoTask = fidoTask;
    MemUnlock(ctaskHan);
    return oldFidoTask;
}

/*********************************************************************
 *			BascoSetLiberty
 *********************************************************************
 * SYNOPSIS:	set the liberty flag in the compile task
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	9/19/95  	Initial version
 * 
 *********************************************************************/
void BascoSetLiberty(MemHandle taskHan, Boolean value)
{
    TaskPtr	task;

    task = MemLock(taskHan);

    if (value) {
	task->flags |= COMPILE_NO_SEGMENTS;
    } else {
	task->flags &= ~COMPILE_NO_SEGMENTS;
    }

    /* Only do this if the value is actually changing
     */
    if (task->liberty != value)
    {
	word	i, count;
	FTabEntry* ftab;

	task->liberty = value;

	count = FTabGetCount(task->funcTable);
	for (i=0; i<count; i++)
	{
	    /* Force functions to be codegen'd again, because
	     * we just changed COMPILE_NO_SEGMENTS.
	     */
	    ftab = FTabLock(task->funcTable, i);
	    /* Might or might not have tree-nuking optimization */
	    if (ftab->compStatus >= CS_CODE_GENERATED) {
		if (ftab->tree) {
		    /* tree still around; safe to go back a bit */
		    ftab->compStatus = CS_TYPE_CHECKED;
		} else {
		    ftab->compStatus = CS_NAKED;
		}
	    }
	    FTabUnlock(ftab);
	}
    }

    MemUnlock(taskHan);
}

/*********************************************************************
 *			swapWord
 *********************************************************************
 * SYNOPSIS:	Used for retargeting little-endian word values
 *              to big-endian
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 7/19/95	Initial version
 * 
 *********************************************************************/
void swapWord(word *val) {

    byte *bytePtr;
    byte t;
    EC_ERROR(-1); /* this function is currently unused */

    bytePtr = (byte*) val;
    t = bytePtr[0];
    bytePtr[0] = bytePtr[1];
    bytePtr[1] = t;
}


/*********************************************************************
 *			swapDword
 *********************************************************************
 * SYNOPSIS:	Convert little-endian dword into big-endian dword
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 7/19/95	Initial version
 * 
 *********************************************************************/
void swapDword(dword *val) {

    word *wordPtr;
    word t;
    EC_ERROR(-1);  /* this function is currently unused */

    wordPtr = (word*) val;

    swapWord(&wordPtr[0]);
    swapWord(&wordPtr[1]);

    t = wordPtr[0];
    wordPtr[0] = wordPtr[1];
    wordPtr[1] = t;
}

    

