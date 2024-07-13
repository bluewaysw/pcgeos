/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	LEGOS
MODULE:		
FILE:		progtask.h

AUTHOR:		Roy Goldman, Jul  7, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95	Initial version.

DESCRIPTION:
	Program task structure (exported for debugger)

	$Id: progTask.h,v 1.1 97/12/05 12:15:57 gene Exp $
	$Revision: 1.1 $

	Liberty version control

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _PROGTASK_H_
#define _PROGTASK_H_

#ifdef LIBERTY
#include <legos/basrun.h>
#include <legos/runheap.h>
#include <legos/runerr.h>
#else	/* GEOS version below */
#include <legos/basrun.h>
#include <legos/runheap.h>
#include <legos/internal/runerr.h>
#endif

#define VPC_RETURN	0x8000

typedef struct
{
#ifdef LIBERTY
    word	FC_padding;
#else
    word	FC_startSeg;
#endif
    word	FC_vbpType;	/* unrelocated: index into type stack */
    word	FC_vbpData;	/* unrelocated: index into data stack */
    word	FC_vpc;
    MemHandle	FC_codeHandle;	/* Return from RML if top nibble != 0h */
    RTaskHan	FC_module;	/* Return to same module if NullHandle */
} FrameContext;

typedef struct
{
    sdword      LC_end;
    sdword      LC_inc;
    word        LC_var;
    word        LC_code;	/* LIBERTY warning, this stores a difference
				   between two code pointers so might have
				   to be 4 bytes */
    word        LC_cont;	/* offset from code */
#ifdef LIBERTY
    byte	LC_scope;	/* the Opcode enum is 4 bytes otherwise */
#else
    Opcode      LC_scope;
#endif
} LoopContext;

/* PTask flags */

/* Set if any modules have RT_ZOMBIE set */
#define PT_HAS_ZOMBIES		0x1
/* set if ANY run task owned by the prog task has been told to HALT */
#define PT_HALT			0x2

/* lofty */
#define PTASK_COOKIE	0x1f7e

typedef struct 
{
    MemHandle		PT_handle;	/* handle to itself */
    word		PT_cookie;
#ifndef LIBERTY
    VMFileHandle	PT_vmFile;
    TCHAR	    	PT_filename[15];/* Name of scratch vm file */
    byte                PT_aintMyVmFile;/* Set if ptask doesn't own vm file */
#endif
    /* the rtask of the last running module that isn't an aggregate module */
    MemHandle	    	PT_lastNonAggregateRunTask;

    MemHandle	    	PT_tasks;
    word		PT_numTasks;
    MemHandle		PT_fidoTask;

#ifndef LIBERTY
    RunHeapInfo         PT_runHeapInfo;
    optr    	    	PT_interpreter;
#endif

#if ERROR_CHECK
    byte		PT_busy; /* Not expecting a recursive RML call? */
#endif
    RuntimeErrorCode	PT_err;
    dword		PT_errData;

    MemHandle		PT_stack;
    word                PT_stackLength;

    word		PT_vspType; /* unrelocated: index into type stack */
    word		PT_vspData; /* unrelocated: index into data stack */
    FrameContext	PT_context;
    
    /* Non-zero means don't pop up a dialog on a runtime error */
    byte		PT_suspendedErrorCount;
    byte		PT_flags;

    MemHandle		PT_bugHandle;
    RTaskHan		PT_bugModule;
} ProgTask;

#if ERROR_CHECK
typedef ProgTask* PTaskPtr;
#else
#ifdef LIBERTY
typedef ProgTask* PTaskPtr;
#else
/* It's always paragraph-aligned */
typedef ProgTask _seg* PTaskPtr;
#endif
#endif

#endif /* _PROGTASK_H_ */
