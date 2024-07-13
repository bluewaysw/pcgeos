/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



	Copyright (c) Geoworks 1995 -- All Rights Reserved



PROJECT:	Legos

MODULE:		Basco Debugger

FILE:		bug.h



AUTHOR:		Roy Goldman, Jan 11, 1995



REVISION HISTORY:

	Name	Date		Description

	----	----		-----------

	roy	 1/11/95	Initial version.



DESCRIPTION:

	

        Header for calls "exported" by the debugger module

	to the runtime and editor. The debugger should in

	fact be the sole runtime interface between the two.



	$Id: bug.h,v 1.1 97/12/05 12:16:11 gene Exp $

	$Revision: 1.1 $



	Liberty version control

	$Id: bug.h,v 1.1 97/12/05 12:16:11 gene Exp $



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef _BUG_H_

#define _BUG_H_



#ifdef LIBERTY

#include <Legos/basrun.h>

#include <driver/serial.h>

#else

#include <geos.h>

#include <vm.h>

#include <Legos/basrun.h>

#include <internal/serialDr.h>

#endif



/* -- External API ------------------------------------------- */



/* Describes status of things when we stop execution. 

   Check slot of BugInfo.

*/



typedef enum

{

    BSS_NORMAL,

    BSS_ERROR,

    BSS_BREAK,

    BSS_HALT,

    BSS_WATCH

} BugSuspendStatus;



/* The builder can asynchronously make requests from the runtask by

   setting a specific data field in the bugInfo block.



   

*/



enum {

    BBR_NONE,

    BBR_SINGLE_STEP,      /* Execute until we're on a different

			     source line.

			  */



    BBR_ROUTINE_STEP,     /* Execute until we're on a different

			     line in the current or a previous frame

			  */

    BBR_FINISH,           /* Execute until we're on a line in

			     the previous frame.

			  */

/*  -------------------------------------------------------------------*/

/*  Requests below this line can happen asynchronously, that is, while

    the specific runtask is still actively running.                    */



    BBR_SUSPEND,          /* Ask interpreter to pause */

    BBR_HALT              /* Tell interpreter to finish itself off ASAP

			     without executing anymore code

			  */

};



typedef byte BugBuilderRequest;





typedef enum 

{

    BS_LOADING_FILE,

    BS_STOPPED,

    BS_PAUSED,

    BS_IDLE,

    BS_RUNNING,

    BS_PAUSED_IDLE

} BuilderState;





/* BugInfo structure is the data interface between the editor

   and the runtime engine. The RunTask will reserve a memory

   block for debugging purposes, and a chunkhandle to one

   instance of this structure...





   The bugtask isn't yet indepedent of the compile task.

   This could be done by creating yet another version

   of the function table which doesn't have the parse tree

   and other type information. All we really need are

   the names of the local variables.



   The debugger currently supports ONE module!

*/



typedef struct {

#ifndef LIBERTY

    LMemBlockHeader	BIH_meta;

    VMFileHandle	BIH_vmFile;	/* HugeArrays are in this vm file */

#endif



    /* The following two structures are used for mapping lines to code

       offsets.



       LineArray is an array mapping line numbers to code offsets.

       funcLabelTabel has an entry for each function, identifying

       the range of LineArray entries which apply to that routine.

    */

    MemHandle	        BIH_funcLabelTable;

    VMBlockHandle       BIH_funcTable;   /* Used by compiler only

					    to avoid having basrun

					    know all about compile-time

					    funtion tables... */

    VMBlockHandle	BIH_lineArray;	/* HugeArray of line # info */



    MemHandle		BIH_vtabHeap;	/* Variable table info */

    optr		BIH_stringIdentTable; /* Stores all strings */



#ifdef LIBERTY

    Array               *BIH_breakArray;

#else

    ChunkHandle		BIH_breakArray;	/* ChunkArray of breakpoints */

#endif

    Opcode		BIH_displacedInsn; /* Opcode of last displaced insn */



    /* Names of all module-level variables */

/*    optr BIH_stringModuleTable;*/



    /* Store the line number of for the breakpoint we stop at.

       Just a cache of infor we could determine otherwise

       by backmapping the offset into a linenumber. But

       we've got this line number anyway so just use it..



       Store other infor about our break...*/



    int     BIH_breakLine;

    int     BIH_breakFunc;

    int     BIH_breakFrame;



    /* The *only* memory which can asynchronously be modified

       by the builder.



       The runtime engine checks this periodically to see if

       it can process the request.

    */



    BugBuilderRequest BIH_builderRequest;



    

    /* When an app suspends execution, this flag will tell

       the system why. Normal finish? Breakpoint? Halt? WatchPoint?

       Runtime error? */



    BugSuspendStatus BIH_suspendStatus;



    /* Object to communicate with when we break or finish or

       find an error.

    */



    optr BIH_destObject;



    /* Messages we send when we hit a breakpoint or when

       we finish, respectively.

    */



    word BIH_destMessage;        

    word BIH_finishMessage;



    /* back reference to the runtask associated with this

       buginfo. Useful for getting the runtime function handle */



    MemHandle BIH_runTaskHan;



    optr    BIH_structIndex;



    BuilderState    BIH_builderState;   /* info about what's happening in the

					 * builder, for now this is used when

					 * setting breakpoints, so if the state

					 * is PAUSED then we can install

					 * the breakpoint at the same time it

					 * is added to the break list

					 */

    byte    BIH_numHiddenFuncs;  /* number of hidden routines, used so that

				  * bpts wont be set when single stepping

				  * over things that go into hidden routines

				  */



    /* this is used as an optimization for single-step/routine-step/finish

     */

    int	    BIH_breakVbpUnreloc;



    /* count the number of times runmainloop has been called so that single

     * stepping can work even when calls to runmainloop come in while single

     * stepping 

     */

    int	    BIH_runMainLoopCount;

    int	    BIH_breakRunMainLoopCount;



#ifdef LIBERTY

    Connection *BIH_connection;

#else

    /* SerialPortNum BIH_port; */

#endif

} BugInfoHeader;





/* This structure holds some debugging info which is CONSTANT

   within the builder. Every time a new runtask gets initialized,

   the builder needs to provides the following information to basco,

   which records it within that runtask's bugInfo block.



*/



typedef struct {

    optr BBI_destObject;

    word BBI_destMessage;

    word BBI_finishMessage;

} BugBuilderInfo;





typedef struct {



    /* Which routine does this correspond to. This number

       is an index into the runtime function table... */



    word BBP_funcNumber;

    

    /* This offset precisely identifies the virtual address

       of the instruction we want to break at.



       Its high 4 bits designate the "segment" within the

       function, low 12 are the offset within that segment.



    */

    

    word BBP_offset;

    

    /* The instruction we've displaced by setting a breakpoint */

    Opcode BBP_insn;



    /* The source line number for this breakpoint. */



    int BBP_lineNum;



    /* Any juicy info we want to store with this breakpoint.

       For now, the only flag is BBP_ONE_TIME to indicate

       that this breakpoint should disappear as soon as it's

       triggered.

    */



    byte BBP_breakFlags;



} BugBreakPoint;

    

BugSuspendStatus BugGetSuspendStatus(MemHandle bugHandle);



/* Request an action from the runtime engine. Called

   by the builder, potentially while runtime thread is still

   cranking along.

*/



void              BugSetBuilderRequest(PTaskHan, BugBuilderRequest bbr);

BugBuilderRequest BugGetBuilderRequest(PTaskHan);



word BugLineNumToOffset(MemHandle bugHandle, word funcNumber, word lineNum);

MemHandle         BugGetBugHandleFromRTask(MemHandle rtaskHan);

void              BugSetBugHandleNotRunning(MemHandle bugHandle);

/* not exported void              BugPSem(SemaphoreHandle sem);*/



/* --------------------------------------------- */

/* VARIABLES                                     */

/* --------------------------------------------- */



#define MODULE_LEVEL -1



/* This structure is the key definition of

   a typical variable at runtime (either local

   or module-level)

*/

typedef struct 

{

    word 	BV_type;

    dword   	BV_data;

} BugVar;



/*

 * BugVar ends up as 8 bytes in Liberty, 6 in GEOS, so I'm adding this

 * contant here so that code with deals with this screw is more legible.

 */

#ifdef LIBERTY

#define BUGVAR_SIZE_DIFF 2

#else

#define BUGVAR_SIZE_DIFF 0

#endif



#define GET_VAR FALSE

#define SET_VAR TRUE



BugVar BugGetSetVar(PTaskHan, sword frameNumber,

		      word varIndex, BugVar bv, Boolean set);



void BugGetString(PTaskHan, dword stringIndex,

		  TCHAR *dest, word maxLen);



BugVar BugCreateString(PTaskHan, TCHAR *src, BugVar oldString);



/*

 * I've moved the definitions of several basco-only routines

 * which used to reside here to bascobug.h - jon 6 may 96

 */



/* --------------------------------------------- */

/* CALL STACK                                    */

/* --------------------------------------------- */



/* Returns the 0-based index of the current frame 

   Number of active frames equals 1 + the value

   returned here.

*/



word BugGetCurrentFrame(PTaskHan ptaskHan);



Boolean BugGetFrameInfo(PTaskHan ptaskHan, word frame, word *funcNum);

word BugGetNumVars(PTaskHan ptaskHan, word frame);



/* Writes out the name of the routine for the given frame

   into dest. Assume dest has enough pre-allocated

   space to safely handle this...

*/



#define MAX_FRAME_NAME_CHARS 256

void BugGetFrameName(PTaskHan, word frame, TCHAR *dest);

word BugGetFrameLineNumber(PTaskHan, word frame);

/* --------------------------------------------- */

/* BREAKPOINTS                                   */

/* --------------------------------------------- */



/* We maintain one list of runtime breakpoints per module.

   For now there is no sorting since I doubt we'll ever

   have that many...



   There should only be one breakpoint set for any offset.  The client

   should keep track of this, but for now EC code will vomit Hong Fu

   Spicy Chicken if the client tries otherwise. 

*/

 

/* The following structure essentially defines a breakpoint. 



   While the user will only be able to set breakpoints at source line

   boundaries, the low-level mechanism supports breakpoints at any

   virtual machine instruction to aid our debugging of basco

   code.

*/



#define NULL_LINE -1

#define NULL_BREAK -1

#define NULL_OFFSET (word) -1



/* Breakpoint flags */



typedef byte BugBreakFlags; 

#define BBF_NORMAL   1

#define BBF_ONE_TIME 2

#define BBF_DELETED  4





/* Create a breakpoint at the given line of the given function.

   Returns TRUE if successful, returns FALSE otherwise.



   Would typically return FALSE if the user is trying

   to set a breakpoint on a source line which never mapped

   into any code, like a REM or a blank line.



   The client should probably take the FALSE return value

   and flash a dialog "Can't set a breakpoint at this line"



*/



Boolean BugSetBreakAtLine(MemHandle bugHandle, word funcNumber, word lineNum);



/* Set a breakpoint at a given virtual offset of a given routine.

   Assumes offset is valid!

*/



void BugSetBreakAtOffset(MemHandle bugHan, word funcNumber, word offset,

			 word lineNumber, BugBreakFlags breakFlags);

void BugClearBreakAtOffset(MemHandle bugHan, word funcNumber, word offset);



/* Clears a breakpoint regardless of its current setting */

void BugClearBreakAtLine(MemHandle bugHandle, word funcNumber, word lineNum);





/* Toggles a breakpoint */

Boolean BugToggleBreakAtLine(MemHandle bugHan, word funcNumber, word lineNum);



/* Set a one-time breakpoint, useful for single-stepping, finishing, etc.

  

   Overlap rules....

   Setting a one-time breakpoint where a normal breakpoint exists

   is an operation which does nothing...



   Setting a normal brekapoint where a one-time breakpoint exists

   changes the breakpoint into a normal one.



*/



Boolean BugSetOneTimeBreakAtLine(MemHandle bugHan,

				 word funcNumber, word lineNum);





void BugDeleteBreaksForFunction(MemHandle bugHandle, word funcNumber);



/*

 * Given an offset find the line number it corresponds to.

 * Return in the START byte TRUE if the offset corresponds

 * exactly to the beginning of a line.

 */

word BugOffsetToLineNum(MemHandle bugHandle, word funcNumber,

		       word offset, byte *start);



void BugUpdateBreaksForDeletedFunction(MemHandle bugHandle, word funcNumber);



/* Sets breaks for all functions, done after all code has been packed.. */



void BugSetAllBreaks(MemHandle bugHandle);



void BugDeleteAllBreaks(MemHandle bugHandle);



void 	    	BugSetBuilderState(MemHandle bugHandle, BuilderState state);

BuilderState 	BugGetBuilderState(MemHandle bugHandle);

void	    	BugSetNumHiddenFuncs(MemHandle bugHandle, word numHiddenFuncs);

#endif /* _BUG_H_ */

