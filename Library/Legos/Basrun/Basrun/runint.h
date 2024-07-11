/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		
FILE:		runint.h

AUTHOR:		Roy Goldman, Dec 21, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/21/94	Initial version.

DESCRIPTION:
	Header file with all the internal juicy goodies
	for the Legos runtime engine

	Some macros need the macro RMS defined.  If the variable
	rms is a pointer

#define RMS (*rms)

	Liberty version control
	$Id: runint.h,v 1.1 98/10/05 12:26:00 martin Exp $

	otherwise

#define RMS rms
	
	$Revision: 1.1 $

        Liberty version control
        $Id: runint.h,v 1.1 98/10/05 12:26:00 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _RUNINT_H_
#define _RUNINT_H_

#ifdef LIBERTY

#include <Legos/compat.h>
#include <Legos/run.h>
#include <Legos/funtab.h>
#include <Legos/runerr.h>
#include <Legos/progtask.h>

#else	/* GEOS version below */

#include "compat.h"
#include <hugearr.h>
#include "run.h"
#include "funtab.h"
#include <Legos/Internal/runerr.h>
#include <Legos/Internal/progtask.h>
#include "fixds.h"

#endif

#ifdef LIBERTY
#define ASSERT_ALIGNED(_ptr) \
  ASSERTS((((dword)_ptr)&3)==0, "Misaligned pointer")
#else
#define ASSERT_ALIGNED(_ptr)	\
 EC_BOUNDS(_ptr);		\
 EC_ERROR_IF((((dword)_ptr)&3), RE_POINTER_NOT_ALIGNED)
#endif

#ifdef LIBERTY

/* Unlock and lock stack because there is no "deref" function */

#define INT_ON_LOW(_r)							\
 (*_r).ehs = NULL;							\
 (*_r).ptask->PT_vspType = ((*_r).spType - (*_r).typeStack);		\
 (*_r).ptask->PT_vspData = ((*_r).spData - (*_r).dataStack);		\
 (*_r).ptask->PT_context.FC_vpc = (*_r).pc - (*_r).code;		\
 (*_r).ptask->PT_context.FC_vbpType = (*_r).bpType - (*_r).typeStack;	\
 (*_r).ptask->PT_context.FC_vbpData = (*_r).bpData - (*_r).dataStack;	\
 UnlockH((*_r).ptask->PT_stack)

#define INT_OFF_LOW(_r)							  \
 (*_r).typeStack= (byte*)LockH((*_r).ptask->PT_stack);			  \
 (*_r).dataStack= (dword*)((*_r).typeStack + (*_r).ptask->PT_stackLength);\
 (*_r).spType	= (*_r).typeStack + (*_r).ptask->PT_vspType;		  \
 (*_r).spData	= (*_r).dataStack + (*_r).ptask->PT_vspData;		  \
 (*_r).pc	= (*_r).code      + (*_r).ptask->PT_context.FC_vpc;	  \
 (*_r).bpType	= (*_r).typeStack + (*_r).ptask->PT_context.FC_vbpType;	  \
 (*_r).bpData	= (*_r).dataStack + (*_r).ptask->PT_context.FC_vbpData;

#else	/* GEOS version below */

/* Unlock and lock code, just because */

#define INT_ON_LOW(_r)							\
 (*_r).ehs = NULL;							\
 (*_r).ptask->PT_vspType = ((*_r).spType - (*_r).typeStack);		\
 (*_r).ptask->PT_vspData = ((*_r).spData - (*_r).dataStack);		\
 (*_r).ptask->PT_context.FC_vpc = (*_r).pc - (*_r).code;		\
 (*_r).ptask->PT_context.FC_vbpType = (*_r).bpType - (*_r).typeStack;	\
 (*_r).ptask->PT_context.FC_vbpData = (*_r).bpData - (*_r).dataStack;	\
 (void)HugeArrayUnlock((*_r).code)

#define INT_OFF_LOW(_r)							     \
{									     \
 word __dummy;								     \
									     \
 (*_r).typeStack= MemDeref((*_r).ptask->PT_stack);			     \
 (*_r).dataStack= (dword*)((*_r).typeStack + (*_r).ptask->PT_stackLength);  \
 (*_r).spType	= (*_r).typeStack + (*_r).ptask->PT_vspType;		     \
 (*_r).spData	= (*_r).dataStack + (*_r).ptask->PT_vspData;		     \
 (*_r).bpType	= (*_r).typeStack + (*_r).ptask->PT_context.FC_vbpType;	     \
 (*_r).bpData	= (*_r).dataStack + (*_r).ptask->PT_context.FC_vbpData;	     \
									     \
 __dummy	= HugeArrayLock						     \
     ((*_r).rtask->RT_vmFile, (*_r).rtask->RT_funTabInfo.FTI_code,	     \
      (*_r).ptask->PT_context.FC_codeHandle, (void**)&(*_r).code, &__dummy); \
									     \
 (*_r).pc	= (*_r).code      + (*_r).ptask->PT_context.FC_vpc;	     \
}

#endif /* LIBERTY */

#if ERROR_CHECK

#define INT_ON(_r)  INT_ON_LOW(_r);  (*_r).ptask->PT_busy = FALSE
#define INT_OFF(_r) INT_OFF_LOW(_r); (*_r).ptask->PT_busy = TRUE

#else /* ERROR_CHECK */

#define INT_ON(_r)  INT_ON_LOW(_r)
#define INT_OFF(_r) INT_OFF_LOW(_r)

#endif /* ERROR_CHECK */


typedef WordFlags EHStateFlags;
/* It is possible to be !enabled but active, if onerror goto 0 is
 * within an error handler */
/* Enabled means ES_handler is set */
#define ESF_ENABLED	1
/* Active means currently handling an error */
#define ESF_ACTIVE	2
/* If any flags are added, change code that does == compares on ES_flags
 * in runmain and ehan
 */

/* Error-handling state, found in stack frames that have error handlers */
typedef struct
{
    word	ES_handler;	/* virt. code pointer to handler
				 * 0 means disabled
				 */

    word	ES_savedVspType;/* tos to restore -- if !active, is
				 * tos at start of current line.  If
				 * active, is tos upon entry to handler
				 */

    word	ES_errorVpc;	/* VPC to line causing error.  Updated
				 * by OP_LINE_BEGIN if !ES_enabled.
				 */

    RuntimeErrorCode	ES_pendingError;
    EHStateFlags	ES_flags;
    word	ES_padding;
} EHState;

/* Struct that sits on the stack, created by RunMainLoop.
 */
typedef struct
{
    PTaskPtr	ptask;
    RunTask	*rtask;

    byte	*code;		/* base of code segment */
    byte	*pc;		/* current opcode */
    
    byte*	typeStack;
    byte*	bpType;		/* frame pointer -- local variables */
    byte*	spType;
    byte*	dsType;		/* data pointer -- global variables */

    dword*	dataStack;
    dword*	bpData;
    dword*	spData;
    dword*	dsData;

/*  byte	*stack;		base of block containing the stack */
/*  byte	*vbp;		current frame */
/*  byte	*tos;		top of stack */
/*  byte	*moduleVars;	/pointer to current module variables */

    				/* TOS/vpc saved by OP_LINE_BEGIN
				 * for use with stack unrolling
				 */

    EHState*	ehs;		/* "weak" pointer to current frame's EHState */

#ifndef LIBERTY
    RunHeapInfo	*rhi;		/* pointer to ptask's runHeap */
#endif

    /* Fields used for communication with SetUpFrame
     */
    FrameContext prevContext;	/* Return info to be pushed on stack */
    byte	numCallArgs;    /* Number of arguments supplied to
				   first function to be executed... */

} RMLState;

/* Swat doesn't like the _ss
 */
#if defined(ERROR_CHECK) || defined(LIBERTY)
typedef RMLState *RMLPtr;
#else
typedef RMLState _ss *RMLPtr;
#endif

typedef struct
{
    dword	value;
    LegosType	type;
} RVal;

/* When switching functions or setting up frames at runtime,
   any of these checks might be required. (RSC_PROC and RSC_FUNC
   are mutually exclusive though...)

   Use an enum for symbol info. Unfortunately, it takes 16 bits though..
*/

#ifdef LIBERTY
typedef word RunSwitchCheck;
#define RSC_NONE 	0
#define RSC_PROC	1
#define RSC_FUNC	2
#define RSC_NUM_ARGS	4
#define RSC_TYPE_ARGS	8
#else
typedef enum {
    RSC_NONE = 0,
    RSC_PROC = 1,
    RSC_FUNC = 2,
    RSC_NUM_ARGS = 4,
    RSC_TYPE_ARGS = 8
} RunSwitchCheck;
#endif

#define RunTaskLock(rtaskHandle) (RunTask*)MemLock(rtaskHandle)

/* typePtr should be a byte*, dataPtr a dword* */
#define CEILING_DWORD(x) (((x)+3)&(~3L))

#define DATA_OFFSET(_blockPtr) \
 CEILING_DWORD((*(word*)(_blockPtr))+sizeof(word))

#define LOCK_GLOBALS(_han, _typePtr, _dataPtr)			\
do {								\
 (_typePtr) = (byte*)  MemLock(_han);				\
 (_dataPtr) = (dword*) (_typePtr + DATA_OFFSET(_typePtr));	\
 (_typePtr) += sizeof(word);					\
 ASSERT_ALIGNED(_dataPtr);					\
} while (0)

#define NUM_GLOBALS_FAST(_typePtr) ((word*)_typePtr)[-1]

#define MAKE_HIGH_BYTE_OF_WORD(x) ((x) << 8)



/* These next two global variables used to be fields in RMLState.
 * However, since RunMainLoop can be called recursively, it's possible
 * that a newer invocation of RunMainLoop might wipe out the cached
 * array referred to by an older invocation.  We use global variables
 * to avoid this bug.  (see 63139)
 *
 * Geos caveat:  Since cachedArray is in dgroup, we need to make sure
 * DS points to dgroup when we access it.  Here we define some useful
 * macros to make setting/restoring DS more clean and less error prone.
 */
extern MemHandle
cachedArray;                  /* last array used, already locked */
#ifdef LIBERTY
extern ArrayHeader
*cachedArrayPtr;              /* last array used, already deref'd */
#endif

#ifdef LIBERTY
#define BEGIN_USING_CACHED_ARRAY
#define END_USING_CACHED_ARRAY
#else /* GEOS */
#define BEGIN_USING_CACHED_ARRAY  { SET_DS_TO_DGROUP
#define END_USING_CACHED_ARRAY      RESTORE_DS;       }
#endif



extern void
Run_UpdatePTask(RMLPtr rms);

extern void
ECCheckFrameContext(FrameContext  *fc);

extern void
RunSendMessage(dword /*optr*/ dest, word msg);

RunFastFTabEntry*
Run_LockOrLoadFTabEntry(RunTask* rtask, word funcNum);

extern byte
RunPushArguments(PTaskHan ptaskHan, RTaskHan rtaskHan, byte* params,
		 byte isFunc);

extern  LegosType
AssignTypeCompatible(LegosType ltype, LegosType rtype, dword *rdw);

extern void
RunDoAction(RMLPtr rms, Opcode optype, RunHeapToken actionToken,
	    Boolean byteCompiled);

extern Boolean
Run_SetModuleVarLVal(RMLPtr rms, RVal* rv);

/* - Array routines */
/* TRUE if PT_err set */
word
Run_IndicesToArrayRef(RMLPtr rms, MemHandle array, byte numDims);

extern Boolean
Run_SetArrayEltLVal(RMLPtr rms, RVal* rv);

/* TRUE if PT_err set */
extern Boolean
Run_SetArrayRef(RMLPtr rms, MemHandle array, word elt, RVal* rv);

extern void
Run_GetArrayRef(RMLPtr rms, MemHandle array, word elt, RVal* rv);

#define ARRAY_DEC_REF_ALL (-1)

#ifdef LIBERTY
extern void
LArrayDecRefElements(MemHandle array, word startElement, int numElements);

#define ArrayDecRefElements(rhi, array, startElement, numElements) \
	LArrayDecRefElements(array, startElement, numElements)

#else
extern void
ArrayDecRefElements(RunHeapInfo *rhi, MemHandle array, word startElement,
		    int numElements);
#endif

extern void
BugHandleError(PTaskPtr ptask, RTaskHan rtaskHan);

word
RunGetFuncSeg(RunTask* rtask, word funcNumber);

#define RunUnlockCodeSeg HugeArrayUnlock

#ifndef LIBERTY
byte*
RunLockCodeSeg(VMFileHandle, VMBlockHandle, word seg, word* size);
#endif

/* Pushes property onto runtime stack
 */
extern void
GetProperty(RMLPtr rms, Opcode byteCompiled, RunHeapToken propName);

extern Boolean
SetProperty(RMLPtr rms, optr comp, 
	    PropertyName prop, 
	    dword value, 
	    LegosType type, 
	    PTaskPtr ptask,
	    LegosType byteCompiled);

void
RunSetUpFrame(RMLPtr rms, RunSwitchCheck checkingRequired, 
	      FrameContext *prevContext);

/* - RunMainLoop and helpers */

void RunSwitchFunctions(RMLPtr rms, RTaskHan newModule, word funcNum,
			RunSwitchCheck checkingRequired);
extern void RunCleanMain(RMLPtr rms);

void RunSetError(PTaskPtr ptask, RuntimeErrorCode error);
void RunSetErrorWithData(PTaskPtr ptask, RuntimeErrorCode error, dword data);
void RunSetErrorHandle(PTaskHan ptaskHan, RuntimeErrorCode error);

/* Returns TRUE if it left a return value on the runtime stack
 */
extern Boolean
RunMainLoop(PTaskHan ptaskHan, FrameContext* fc, byte nParams);

extern void RunModuleCallProcOrFunc(RMLPtr rms, Opcode op);

extern void
RunDoAggAction(RMLPtr rms, Opcode op, RunHeapToken actionToken);
extern void
RunGetAggProperty(RMLPtr rms, RunHeapToken propName);
extern void
RunSetAggProperty(RMLPtr rms, RVal* rvR);

extern word
RunDimsToOffset(word *dims, byte numdims, word *maxdims);

extern void SignalRuntimeError(RuntimeErrorCode err, dword errorData);

extern void OpCompInit(register RMLPtr rms);
extern void OpDim(register RMLPtr rms, Opcode op);
extern void OpFor(register RMLPtr rms, Opcode op);
extern void OpJmpSeg(register RMLPtr rms, word target);
extern Boolean OpEndRoutine(register RMLPtr rms, Opcode op);



typedef enum
{
OURT_OK,
OURT_HANDLE_RTE,
OURT_HANDLE_RTE_ERR,
OURT_HANDLE_RTE_ERR_DATA,
OURT_PUNT_RTE_ERR
} OpUtilReturnType;

extern OpUtilReturnType OpAssign(register RMLPtr rms, Opcode op, 
				 RuntimeErrorCode *ec, word *data);
extern OpUtilReturnType OpCoerce(register RMLPtr rms, 
				 RuntimeErrorCode *ec, word *data);
extern OpUtilReturnType OpModuleRef(register RMLPtr rms, Opcode op,
				 RuntimeErrorCode *ec, word *data);
#if ERROR_CHECK
extern void
ValidateStack(RMLPtr rms);
#endif

#if defined(LIBERTY) && defined(DEBUG_AID)
extern int theComponentTraceLogDepth;
#define TRACE_LOG_DEPTH(op) (op theComponentTraceLogDepth)
#else  /* LIBERTY and DEBUG_AID */
#define TRACE_LOG_DEPTH(op) 
#endif

#define USE_IT(x) (void)x
#define BORK NULL

#endif /* _RUNINT_H_ */
