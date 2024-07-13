/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



	Copyright (c) Geoworks 1994 -- All Rights Reserved



PROJECT:	Legos

MODULE:		Runtime pcode interpreter

FILE:		runtask.h



AUTHOR:		Roy Goldman, Dec 27, 1994



REVISION HISTORY:

	Name	Date		Description

	----	----		-----------

	roy	12/27/94	Initial version.



DESCRIPTION:

	Runtask structure... Namely so the debugger can

	do something useful.



	$Id: runTask.h,v 1.1 97/12/05 12:15:59 gene Exp $



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef _RUNTASK_H_

#define _RUNTASK_H_



#if !defined(COMPILING_BCL2C)

#include <Legos/bug.h>

#else

typedef byte BugBuilderRequest;

#endif

#include <Legos/fido.h>



#ifdef LIBERTY

#include <Legos/bfuntab.h>

#else

#include <Legos/bridge/bfuntab.h>

#endif



#ifdef LIBERTY

typedef byte RTaskState;

#define FRESH 		0

#define NOT_OWNER 	1

#define OWNER		2

#else

typedef enum {

    FRESH,		/* Newly created */

    NOT_OWNER,		/* arrays are owned by a ctask */

    OWNER,		/* arrays are owned by the rtask */

} RTaskState;

#endif



/* run task flags */



/* Unused */

#define RT_UNUSED_1		0x01

/* used to implement EventsDisabled() */

#define RT_EVENTS_DISABLED   	0x02

/* used by the builder to prevent certain tasks from being destroyed */

#define RT_OWNED_BY_BUILDER 	0x04

/* Set while UnloadModule is doing its work */

#define RT_UNLOADING		0x08

/* Set after UnloadModule is done, and module is ready for destruction */

#define RT_ZOMBIE		0x10

/* Set to indicate that this module is being debugged remotely, and so should

 * do things like answer RPC requests instead of BugSitAndSpin, etc. */

#define RT_REMOTE_DEBUGGING	0x20





#ifdef LIBERTY

class Array;

#define ChunkArray Array*

#else

#define ChunkArray optr

#endif





/* A number of these fields are copied from a ProgTask upon

 * creation (in RunAllocRunTask)

 */

typedef struct _runTask {

    MemHandle		RT_handle;	/* handle to itself */

    ModuleToken		RT_fidoModule;	/* Fido information */



#if ERROR_CHECK

#define RTASK_COOKIE	0xfeed

    word		RT_cookie;

#endif

    Boolean		RT_shared;	/* Should use count ever exceed 1? */



    word		RT_useCount;	/* # of Require/LoadModules on us */

    MemHandle	    	RT_progTask;	/* program task handle */

    MemHandle		RT_fidoTask;	/* copied from ptask */

    RTaskState		RT_compTime;	/* some fields owned by a CTask? */



#ifndef LIBERTY

    VMFileHandle	RT_vmFile;	/* copied from ptask */

    optr    		RT_interpreter;	/* copied from ptask */



    MemHandle   RT_sstBlock;		/* for SSTs and random chunks */

    optr	RT_uiBlocks;

#endif

    MemHandle	RT_bugHandle;		/* Debugging information */

    BugBuilderRequest	RT_builderRequest;

    optr	RT_stringFuncTable;	/* Small String table (SST) */

    optr    	RT_exportTable;		/* Small String table (SST) */

#ifdef LIBERTY

    word	RT_stringFuncCount;	/* num entries in string func table */

    word	RT_exportTableCount;	/* num entries in export table */

    MemHandle	RT_topLevelComponents;	/* array of top level

					   components "owned" by this

					   RunTask.  These componnts

					   and all their descendants

					   will be destroyed when the

					   module associated with this

					   rtask is unloaded. */

    word	RT_topLevelCount;	/* count components in the

					   block above */

    word    	RT_complexDataCount;	/* number of complex data elements */

    MemHandle	RT_complexTable;    	/* table of complex data elements */

    struct _runTask* RT_next;           /* the next run task -- used only

                                           when chaining run tasks at

                                           unload time */

#endif



    FunTabInfo  RT_funTabInfo;		/* Much faster function table */

    MemHandle   RT_strConstMap;		/* Mapping of str constant numbers

					   into global heap tokens */

    optr	RT_structInfo;



    optr    	RT_uiParent;

    optr    	RT_appObject;



    MemHandle	RT_moduleVars;		/* NullHandle if there are none */



    byte    	RT_buildTimeComponents;



    byte 	RT_flags;

    ChunkArray  RT_childModules;	/* Modules we have loaded, it is a

					   ChunkArray in GEOS, a pointer

					   to a Array in Liberty */

} RunTask;





extern byte RunTaskGetFlags(RTaskHan rtaskHan);

extern void RunTaskSetFlags(RTaskHan rtaskHan, byte flagsToSet, 

			    byte flagsToClear);



#ifdef LIBERTY

RunTask* RunTaskGetNext(RunTask* task);

void RunTaskSetNext(RunTask* task, RunTask* next);

void RunTaskEnumBackwards(RunTask* head, 

			  void (*func)(RunTask*, void*),

			  void*);

Boolean RunTaskInList(RunTask* head, RTaskHan handle);

#endif



#endif /* _RUNTASK_H_ */

