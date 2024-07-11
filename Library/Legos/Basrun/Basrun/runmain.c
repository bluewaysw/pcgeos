/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        Legos
MODULE:         Runtime interpreter
FILE:           runmain.c

AUTHOR:         Roy Goldman, Dec 27, 1994

ROUTINES:
	Name                    Description
	----                    -----------

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy     12/27/94        Initial version.

DESCRIPTION:
	Main runtime interpreter engine

	$Id: runmain.c,v 1.2 98/10/05 12:43:07 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* This should go in geos.h at some point
 */
#if defined __BORLANDC__
#define _near near
#elif defined LIBERTY
#define _near
#endif

#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/runint.h>
#include <Legos/funtab.h>
#include <Legos/prog.h>
#include <Legos/builtin.h>
#include <Legos/sst.h>
#include <Legos/runmath.h>
#include <Legos/strmap.h>
#include <Legos/rheapint.h>
#include <Ansi/string.h>
#include <Legos/ehan.h>
#include <Legos/stack.h>
#include "legosdb.h"
#include "legoslog.h"

/* for checking theHeap */
//#include <pos/hpalloc.h>

#else	/* GEOS version below */

#include "mystdapp.h"
#include <chunkarr.h>
#include <Ansi/string.h>
#include <hugearr.h>
#include <resource.h>
#include "funtab.h"
#include "prog.h"
#include "runint.h"
#include "stack.h"
#include "builtin.h"
#include "sst.h"

#include "runmath.h"
#include "profile.h"
#include "strmap.h"
#include "rheapint.h"
#include "bugext.h"
#include "ehan.h"
#endif
#define RMS rms

extern void ECCheckFrameContext(FrameContext *fc);
extern void RunMainMessageDispatch(RTaskHan rtaskHan);

#if defined(LIBERTY) && defined(DEBUG_AID) && defined(LOG_OPCODES)
static void log_opcode(int opcode) 
{
    extern char *opCodes[];
    for (int i = 0; i < theComponentTraceLogDepth; i++) {
	theLog << "    ";
    }
    theLog << "op " << opCodes[opcode] << '\n';
}
static void log_error() 
{
    for (int i = 0; i < theComponentTraceLogDepth; i++) {
	theLog << "    ";
    }
    theLog << "ERROR\n";
}
#define LOG_OPCODE(op) log_opcode(op)
#define LOG_ERROR() log_error()
#else
#define LOG_OPCODE(op)
#define LOG_ERROR()
#endif


#if ERROR_CHECK
/* For breakpoints */
void _near RMLError(void) {
    LONLY(LOG_ERROR());
    return;
}
#else
#define RMLError()
#endif

#ifdef __BORLANDC__
#define strcmp RunMainStrCmp


/*********************************************************************
 *		        RunMainStrCmp
 *********************************************************************
 * SYNOPSIS:	local copy of strcmp
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 6/ 9/95	Initial version
 * 
 *********************************************************************/
#pragma warn -rvl
int strcmp(TCHAR *s1, TCHAR *s2)
{
asm {	push	es						}
asm {	push	ds						}
asm {	les	di, s2						}
asm {	lds	si, s1						}
asm {	mov	cx, -1						}
asm {	mov	ax, 0						}
asm {	push	di						}
#ifdef DO_DBCS
asm {	repne	scasw						}
#else
asm {	repne	scasb						}
#endif
asm {	pop	di						}
asm {	not	cx						}
#ifdef DO_DBCS
asm {	repe	cmpsw						}
#else
asm {	repe	cmpsb						}
#endif
asm {	jz	strcmp_exit					}
asm {	mov	al, 1						}
strcmp_exit:
asm {	pop	ds						}
asm {	pop	es						}
}
#endif	/* if !LIBERTY */

/* OK, so here's the deal with recursive calls to RunMainLoop:
 * The PTask fields that may change during a call to RML are:
 *      PT_tosUnreloc
 *      PT_context.<all fields>
 *
 * To start a recursive call, set PT_context to point to the desired
 * function, and call RunMainLoop, passing a pointer to a FrameContext
 * to be pushed on the stack.  This will usually be filled in with
 * whatever values were in the PTask before they were modified.
 *
 * RunMainLoop will exit if the high bit of FC_vpc is != 0
 * in OP_END_{PROCEDURE,FUNCTION}.  You should take advantage of this.
 *
 * The caller of RunMainLoop is responsible for saving PT_tosUnreloc,
 * at least until runtime errors unroll the stack.  The PT_context
 * fields are saved "for free" by OP_END_* functionality.
 */
/* -IMPLICATIONS for code within RunMainLoop */
/* 
 * During runtime, PT_context and PT_tosUnreloc are usually not used;
 * the "relocated" versions in the RMLState are used instead.  So, if
 * PT_context or PT_tosUnreloc were trashed by some recursive call, it
 * might not harm anything, or it might cause subtle problems further
 * on.
 * 
 * Recursive calls can happen at a few points within the loop.  Wherever
 * these calls might occur, PT_tosUnreloc must be valid; after all, the
 * caller can't see our RMLState to know where the tos "really" is.
 * Since the stack might have been re-allocated, we have to re-MemDeref
 * the damn stack as well.  vpcUnreloc is fixed up as well, for the
 * debugger's benefit (so it can traverse the stack frame as it pleases)
 * 
 * If this turns out to be a performance problem, we can keep around
 * a chain of RMLState structs and fix them up only as necessary...
 *
 * The macros INT_ON and INT_OFF (defined in runint.h) are used around
 * sections of code that might generate recursive calls.
 * These sections are:
 *      around MSG_ENT_DO_ACTION in RunDoAction
 *      around SetProperty calls
 *              --dubois 4/11
 */

/*********************************************************************
 *                      RunMainLoop
 *********************************************************************
 * SYNOPSIS:    Execute p-code.  Somewhat re-entrant...
 *
 * CALLED BY:   INTERNAL RunCallFunction
 * RETURN:      TRUE if a return value was left on the stack.
 *
 * SIDE EFFECTS:
 *      Modifies ptask->PT_context fields, ptask->PT_spType/Data, and
 *      probably module variables as well.
 *
 * STRATEGY:
 *      Return when return pc has high nibble set, or when
 *      a runtime error is hit.  See above comment for discussion of
 *      recursive calls.
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     12/27/94        Initial version                      
 * 
 *********************************************************************/

/* (#@*&!@$ runtime.h has a RTASK macro as well... */
#undef RTASK
#define RTASK (rms.rtask)
#define PTASK (rms.ptask)
#define PC (rms.pc)

#ifdef LIBERTY

#define RHI 1
#define _SET_RUNERR(_r, _d) runError = _r; errorData = _d

#else	/* GEOS version below */

#define RHI (rms.rhi)

#ifdef __BORLANDC__
#define _SET_RUNERR(_r, _d)			\
asm { mov cx, _d }				\
asm { mov dx, _r }
#else /*__HIGHC__*/
#define _SET_RUNERR(_r, _d) runError = _r; errorData = _d
#endif

#endif

#define PUNT_RTE		RMLError();goto punt_error
#define PUNT_RTE_ERR(_rte)	PUNT_RTE_ERR_DATA(_rte, 0)
#define PUNT_RTE_ERR_DATA(_rte, _data)			\
 RMLError();_SET_RUNERR(_rte, _data); goto punt_error_with_error

#define HANDLE_RTE		RMLError();goto handle_error
#define HANDLE_RTE_ERR(_rte)	HANDLE_RTE_ERR_DATA(_rte, 0)
#define HANDLE_RTE_ERR_DATA(_rte, _data)	\
 RMLError();_SET_RUNERR(_rte, _data); goto handle_error_with_error

#define OURT_RTE RMLError(); goto ourt_error

#define ASSERT_T(expr) EC_ERROR_IF(!(expr), RE_TYPE_ASSUMPTION_FAILED)

#define OP_BINARY_INT_INT(OPER)						    \
{									    \
    ASSERT_T((NthType(1) == TYPE_INTEGER) && (NthType(2) == TYPE_INTEGER)); \
    NthData(2) = (sword)NthData(2) OPER (sword)NthData(1);		    \
    /* NthType(2) = TYPE_INTEGER; Not necessary */			    \
    PopValVoid();							    \
    goto TOP;								    \
}

#define OP_BINARY_LONG_LONG(OPER)					\
{									\
    ASSERT_T((NthType(1) == TYPE_LONG) && (NthType(2) == TYPE_LONG));	\
    NthData(2) = (sdword)NthData(2) OPER (sdword)NthData(1);		\
    /* NthType(2) = TYPE_LONG; Not necessary */				\
    PopValVoid();							\
    goto TOP;								\
}

#define OP_BINARY_LONG_INT(OPER)					\
{									\
    ASSERT_T((NthType(1) == TYPE_LONG) && (NthType(2) == TYPE_LONG));	\
    NthData(2) = (sdword)NthData(2) OPER (sdword)NthData(1);		\
    NthType(2) = TYPE_INTEGER;						\
    PopValVoid();							\
    goto TOP;								\
}

#define OP_UNARY_INT_INT(OPER)			\
{						\
    ASSERT_T(TopType() == TYPE_INTEGER);	\
    TopData() = OPER (sword)TopData();	\
    /* No need to alter type */			\
    break;					\
}

#define OP_UNARY_LONG_LONG(OPER)		\
{						\
    ASSERT_T(TopType() == TYPE_LONG);		\
    TopData() = OPER (sdword)TopData();		\
    /* No need to alter type */			\
    break;					\
}

#define OP_UNARY_LONG_INT(OPER)			\
{						\
    ASSERT_T(TopType() == TYPE_LONG);		\
    TopData() = OPER (sdword)TopData();		\
    TopType() = TYPE_INTEGER;			\
    break;					\
}

#define VALIDINT(x) ((sword) (x) == (sdword) (x))

#ifdef LIBERTY
#define INC_REF_IF_RUN_HEAP_TYPE(type, data)			\
{								\
    if (RUN_HEAP_TYPE((type),(data))) {		    	    	\
	LRunHeapIncRef						\
	    ( ((type) == TYPE_COMPONENT && COMP_IS_AGG(data)) ?	\
	      AGG_TO_STRUCT(data) : (RunHeapToken)(data) );	\
    }								\
}

#define DEC_REF_IF_RUN_HEAP_TYPE(type, data)			\
{								\
    if (RUN_HEAP_TYPE((type),(data))) {				\
	LRunHeapDecRef						\
	    ( ((type) == TYPE_COMPONENT && COMP_IS_AGG(data)) ?	\
	      AGG_TO_STRUCT(data) : (RunHeapToken)(data) );	\
    }								\
}

#else
#define INC_REF_IF_RUN_HEAP_TYPE(type, data)		\
{							\
    if (RUN_HEAP_TYPE((type), (data))) {		\
	RunHeapIncRef(RHI, (data));			\
    }							\
}

#define DEC_REF_IF_RUN_HEAP_TYPE(type, data)		\
{							\
    if (RUN_HEAP_TYPE((type), (data))) {		\
	RunHeapDecRef(RHI, (data));			\
    }							\
}

#endif


extern Opcode 	BugRestoreFromBreakpoint(RMLPtr rms);
extern Boolean	BugCheckForBreakpoint(RMLPtr rms);
extern void 	OpBreak(RMLPtr rms);
extern void 	RunSetupRML(PTaskHan ptaskHandle, RMLPtr rms);

#ifdef OP_PROFILE
#include "fixds.h"
dword	opProfileCount[256];

void OpProfileResetCount()
{
    int	i;
    DS_DECL;
    DS_DGROUP;
    for (i = 0; i < 256; i++) {
	opProfileCount[i] = 0;
    }
    RESTORE_DS;
} 
#endif

/*********************************************************************
 *                      RunStepBrk
 *********************************************************************
 * SYNOPSIS:    Stub routine break point for bstep.tcl swat command
 *                   when C compilers don't output brk_labels:
 *                   when [src addr <file> <line>] isn't TCLing...
 *
 * CALLED BY:   INTERNAL RunMainLoop
 *                also called as a swat brk by bstep.tcl
 *
 * SIDE EFFECTS:
 * STRATEGY:
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      martin  3/27/98         Initial version                      
 * 
 *********************************************************************/
static void RunStepBrk() {}

Boolean
RunMainLoop(PTaskHan ptaskHan, FrameContext* oldContext, byte numParamsAdjust)
{
    word		errorData = 0;
    RuntimeErrorCode    runError = RTE_NONE;
    Opcode      op = OP_ILLEGAL;
    RMLState    rms;

#ifndef LIBERTY
    word		opcodeCount = 0;
#endif


    /* some often useful variables that can be s_hared,
     * or that are tmp_orary
     */
    Boolean    	s_lval;
    RVal    	s_rv, s_rv2;
    word    	s_offset;
    word    	s_loff, s_roff;
    OpUtilReturnType	ourt;
    word    	    	ourt_data;
    RuntimeErrorCode   	ourt_ec;
    dword*	s_varsData;

    dword   	tmpDword;
    word   	tmpWord;
    RunHeapToken    tmpToken;

EC( Opcode      lastop);

    PROFILE_START_SECTION(PS_RUN_MAIN_LOOP);

    /* Caller normally provides us with return context; first opcode
     * is almost always OP_START_{PROCEDURE,FUNCTION}
     */
    rms.numCallArgs = numParamsAdjust;

    ASSERT(oldContext != NULL);
    EC_BOUNDS(oldContext);
    rms.prevContext = *oldContext;
    rms.prevContext.FC_vpc |= VPC_RETURN;

RE_ENTRY:
    RunSetupRML(ptaskHan, &rms);

    /* Coming back from a breakpoint; restore state appropriately */
    if (RTASK->RT_bugHandle != NullHandle)
    {
	/* Invariants -- I'm trying to make these global */
	/* FIXME remove when done */
	ASSERT(RTASK->RT_bugHandle == PTASK->PT_bugHandle);
	ASSERT(RTASK->RT_handle == PTASK->PT_bugModule);

	if (RTASK->RT_builderRequest == BBR_SUSPEND)
	{
	    PTASK->PT_context.FC_vbpType = rms.bpType - rms.typeStack;
	    PTASK->PT_context.FC_vbpData = rms.bpData - rms.dataStack;
	    PTASK->PT_context.FC_vpc = rms.pc - rms.code;

	    RunCleanMain(&rms);
	    PROFILE_END_SECTION(PS_RUN_MAIN_LOOP);
	    return FALSE;
	}

	if ((op = BugRestoreFromBreakpoint(&rms)) != OP_ILLEGAL) {
#ifndef LIBERTY
	    /* avoid problems with opcodeCount hack */
	    opcodeCount = 0;
#endif
	    goto SWITCH;
	}
    }

    while(1)
    {
	/* TOP:   (For NO debugging checks) */
    TOP:
	if (RTASK->RT_builderRequest != BBR_NONE)
	{
	    /* sets a breakpoint if need be */
	    if (BugCheckForBreakpoint(&rms) == FALSE) {
		return FALSE;
	    }
	}
EC(	lastop = op; op = lastop; )
	GetOpcode(rms.pc, op);
	/*       LONLY(LOG_OPCODE(op));    */
    SWITCH:
	ASSERT(rms.ptask->PT_context.FC_codeHandle != ECNullHandle);
#ifndef LIBERTY
#if ERROR_CHECK
    {
	word	dummy;
	if (SysGetECLevel(&dummy) & ECF_HIGH)
	{
	    ECCheckFrameContext(&(rms.ptask->PT_context));
	}
    }
#endif
#endif

	/* if this check fails, we probably need to increase
	 * STACK_REALLOC_THRESHHOLD */
	ASSERT(rms.spType - rms.typeStack < PTASK->PT_stackLength);

#ifndef LIBERTY
	/* NOTE: this is a hack to make sure that we don't leave
	 * MSG_META_QUERY_IF_PRESS_IS_INK sitting on the input queue too
	 * long, as that prevents interaction with the builder
	 * this causes updates to happen as if the user had spread Update()
 	 * calls througout their code - but it prevents the hang that
	 * happens when legos code is looping inifinitely and the user clicks
	 * on the running app
	 */
	opcodeCount++;
	if (!opcodeCount)
	{
	    INT_ON(&rms);
	    RunMainMessageDispatch(rms.rtask->RT_handle);
	    INT_OFF(&rms);
 
           /* HACK upon HACK alert, since its possible that somebody
            * requested a HALT inside of this, we are checking for
            * a breakpoint here. this code will deal with HALTS
            * correctly
            */
           if (RTASK->RT_builderRequest != BBR_NONE)
           {
               /* sets a breakpoint if need be */
               if (BugCheckForBreakpoint(&rms) == FALSE) {
                   return FALSE;
               }
           }
	}
#endif

#ifdef OP_PROFILE
	opProfileCount[op]++;
#endif
#if (defined(DEBUG_AID) && defined(EC_LOG)) || defined(LEGOS_NONEC_LOG)
	/* This is for the benefit of the function-call log */
	theLegosOpcodeCount++;
#endif

//	ECL(CheckHeap());

        RunStepBrk();
	switch (op)
	{

	case OP_START_PROCEDURE:
	case OP_START_FUNCTION:
	{
 
	    /* Only actually executed when running routines
	       from the top level (outside the interpreter).

	       Otherwise, all variants of OP_CALL will handle all the work
	       done here and the START_ROUTINE opcode will
	       be skipped entirely. Same for loading new modules, etc.
	     */
	    ASSERT( (rms.pc-1) == rms.code);

//	    ECL(CheckHeap());

	    PROFILE_START_SECTION(PS_OP_START_ROUTINE);

	    /* Assume the prevContext has been initialized correctly...
	     */

	    RunSetUpFrame(&rms, (RunSwitchCheck)(RSC_NUM_ARGS | RSC_TYPE_ARGS),
			  &(rms.prevContext));

	    if (PTASK->PT_err) { HANDLE_RTE; } /* XXX */

	    PROFILE_END_SECTION(PS_OP_START_ROUTINE);
	    break;
	}

	case OP_END_PROCEDURE:
	case OP_END_FUNCTION:
	    tmpWord = OpEndRoutine(&rms, op);
	    if (PTASK->PT_err) { PUNT_RTE; }

	    if (tmpWord) {
		return (Boolean)(op == OP_END_FUNCTION);
	    }
	    goto TOP;

	    /* - Function calls */

	case OP_CALL_PRIMITIVE:
	{
	    sword               funcNumber;
#ifdef LIBERTY
	    GetWordBcl(PC, funcNumber);
	    (*GetBuiltInFunction(funcNumber))(&rms, (BuiltInFuncEnum)funcNumber);
#else
	    BuiltInFuncEntry	*fe;
	    void                *funcptr;

	    PROFILE_START_SECTION(PS_OP_CALL_PRIMITIVE);

	    GetWordBcl(PC, funcNumber);
	    fe = MemLockFixedOrMovable(BuiltInFuncs);
	    fe += funcNumber;   /* now points at appropriate offset */
	    funcptr = (void *)fe->BIFE_vector; /* get function pointer */

	    MemUnlockFixedOrMovable(BuiltInFuncs);

	    /* call the actual built in function */
	    ProcCallFixedOrMovable_cdecl(funcptr, &rms, 
					 (BuiltInFuncEnum)funcNumber);
	    PROFILE_END_SECTION(PS_OP_CALL_PRIMITIVE);
#endif

	    if (PTASK->PT_err) { HANDLE_RTE; } /* XXX */
	    break;
	}

	case OP_MODULE_CALL_PROC:
	case OP_MODULE_CALL_FUNC:
	{
	    RunModuleCallProcOrFunc(&rms, op);
	    if (PTASK->PT_err) { HANDLE_RTE; } /* XXX */
	    break;
	}

	case OP_CALL:
	{
	    RunSwitchCheck	rsc;
	    word        funcNum;

	    rsc = RSC_NONE;
	    goto	OP_CALL_COMMON;

	case OP_CALL_WITH_TYPE_CHECK:
	    rsc = RSC_TYPE_ARGS;

OP_CALL_COMMON:
	 
	    GetWordBcl(PC, funcNum);
	    RunSwitchFunctions(&rms, rms.rtask->RT_handle, funcNum, rsc);

	    /* Must actually check for an error here always as we could
	     * get a stack overflow
	     */
	    if (PTASK->PT_err) { HANDLE_RTE; } /* XXX */
	    goto TOP;
	}           

	    /* - ACTIONS */

	case OP_BC_ACTION_PROC:
	case OP_BC_ACTION_FUNC:
	PROFILE_START_SECTION(PS_OP_ACTION_ROUTINE);
	RunDoAction(&rms, op, (RunHeapToken)0, TRUE);
	    PROFILE_END_SECTION(PS_OP_ACTION_ROUTINE);
	    if (PTASK->PT_err) { HANDLE_RTE; } /* XXX */
	    break;

	case OP_STACK_ACTION_PROC:
	case OP_STACK_ACTION_FUNC:
	{
	    word	actionKey;
	    RunHeapToken	actionToken;

	    if (TopType() != TYPE_STRING) {
		HANDLE_RTE_ERR_DATA(RTE_TYPE_MISMATCH, TYPE_STRING);
	    }
	    actionToken = TopData();
	    PopValVoid();
	    goto DO_ACTION_COMMON;

	case OP_ACTION_PROC:
	case OP_ACTION_FUNC:

	    PROFILE_START_SECTION(PS_OP_ACTION_ROUTINE);

	    GetWordBcl(PC, actionKey);
	    actionToken = StrMapLookup(RTASK->RT_strConstMap, actionKey);
	    /* Fall through */

DO_ACTION_COMMON:
	    if (COMP_IS_AGG(TopData())) {
		/* XXX refct ok? */
		RunDoAggAction(&rms, op, actionToken);
	    }
	    else {
		RunDoAction(&rms, op, actionToken, FALSE);
	    }
	    if (op == OP_STACK_ACTION_PROC) {
		RunHeapDecRef(RHI, actionToken);
	    }
	    PROFILE_END_SECTION(PS_OP_ACTION_ROUTINE);

	    if (PTASK->PT_err) { HANDLE_RTE; }
	    break;
	}

	    /* - Jumps ---------------------------------------- */

	    /* Don't move this without moving OP_JMP_REL as well */

	case OP_BNE_REL:
	case OP_BEQ_REL:

	    /* FIXME: spec this
	     * Currently, TRUE is anything that's not zero.
	     * That is, any type is accepted as a truth value
	     * (even components and strings), but nothing "special"
	     * is done with them.
	     */
	    PROFILE_START_SECTION(PS_OP_BRANCH_REL);

	    tmpDword = PopData();
	    if (PopType() == TYPE_INTEGER) {
		tmpDword = (word)tmpDword; /* zero the high word */
	    }

	    if ((tmpDword && (op == OP_BEQ_REL)) ||
		(!tmpDword && (op == OP_BNE_REL)))
	    {
		/* Consume the offset, but don't take the branch */
		PC += 1;
		PROFILE_END_SECTION(PS_OP_BRANCH_REL);
		break;
	    }

	    PROFILE_END_SECTION(PS_OP_BRANCH_REL);
	    /* This is supposed to fall through. */

	case OP_JMP_REL:
	{
	    /* Take the branch -- PC has already been incremented once,
	     * so decrement to account for that. */
	    sbyte relativeOffset;
	    
	    PROFILE_START_SECTION(PS_OP_JMP_REL);
	    relativeOffset = *PC;
	    PC = (PC-1) + relativeOffset;

	    PROFILE_END_SECTION(PS_OP_JMP_REL);
	    break;
	}

	    /* Don't move this without moving OP_JMP as well */

	case OP_BNE:
	case OP_BEQ:
	case OP_BNE_SEG:
	case OP_BEQ_SEG:
	    /* FIXME: spec this
	     * Currently, TRUE is anything that's not zero.
	     * That is, any type is accepted as a truth value
	     * (even components and strings), but nothing "special"
	     * is done with them.
	     */
	    PROFILE_START_SECTION(PS_OP_BRANCH);

	    /* FIXME: is it safe to assume high word is zero
	     * for word-sized data */
	    tmpDword = PopData();
	    PopTypeV();

	    if ((tmpDword && (op == OP_BEQ || op == OP_BEQ_SEG)) ||
		(!tmpDword && (op == OP_BNE || op == OP_BNE_SEG)))
	    {
		/* Consume the target, but don't take the branch */
		PC += 2;
		PROFILE_END_SECTION(PS_OP_BRANCH);
		break;
	    }
	    PROFILE_END_SECTION(PS_OP_BRANCH);
	    /* fall through */
	case OP_JMP:
	case OP_JMP_SEG:
	    /* jump to another segment - for non-segmented architectures
	     * this should be the same as OP_JMP
	     */
	    NextWordBcl(PC, tmpWord);
	    OpJmpSeg(&rms, tmpWord);
	    break;


	case OP_POP:    /* pop the top value on the stack */
	{
	    PROFILE_START_SECTION(PS_OP_POP);
	    PopVal(s_rv);
	    DEC_REF_IF_RUN_HEAP_TYPE(s_rv.type, s_rv.value);
	    PROFILE_END_SECTION(PS_OP_POP);
	    break;
	}

	case OP_DUP:    /* duplicate whatever is on the top of the stack */
	{
	    NthData(0) = NthData(1);
	    NthType(0) = NthType(1);
	    rms.spType++;
	    rms.spData++;

/*	    PushData(TopData());	don't access stack and push */
/*	    PushType(TopType());	at the same time! */

MAYBE_INC_STACKTOP:
	    INC_REF_IF_RUN_HEAP_TYPE(TopType(), TopData());
	    break;
	 }
	    
	case OP_SWAP:
	{
	    byte topType;
	    dword topData;

	    topType = TopType();
	    topData = TopData();

	    TopType() = NthType(2);
	    TopData() = NthData(2);
	    
	    NthType(2) = topType;
	    NthData(2) = topData;
	    
	    goto TOP;
	}
	    
	    /* - Constants ---------------------------------------*/
	case OP_BYTE_INTEGER_CONST:
	{
	    GetByte(PC, tmpWord);
	    PushTypeData(TYPE_INTEGER, tmpWord);
	    goto    TOP;
	}
	case OP_INTEGER_CONST:
	{
	    PROFILE_START_SECTION(PS_OP_INTEGER);
	    GetWordBcl(PC, tmpWord);
	    PushTypeData(TYPE_INTEGER, tmpWord);
	    PROFILE_END_SECTION(PS_OP_INTEGER);
	    goto TOP;
	}
	case OP_ZERO:
	{
	    /* Push a typed zero; type is in code */
	    PushTypeData(*PC, 0);
	    PC++;
	    goto TOP;
	}    
        
	case OP_STRING_CONST:
	    GetWordBcl(PC, tmpWord);
	    goto STRING_CONST_COMMON;
   
	case OP_BYTE_STRING_CONST:
	    GetByte(PC, tmpWord);
STRING_CONST_COMMON:
	    tmpToken = StrMapLookup(RTASK->RT_strConstMap, tmpWord);
	    RunHeapIncRef(RHI, tmpToken);
	    PushTypeData(TYPE_STRING, tmpToken);
	    
	    PROFILE_END_SECTION(PS_OP_STRING);
	    break;

	case OP_LONG_CONST:
	    GetDwordBcl(PC, tmpDword);
	    PushTypeData(TYPE_LONG, tmpDword);
	    break;

	case OP_FLOAT_CONST:
	    GetDwordBcl(PC, tmpDword);
	    PushTypeData(TYPE_FLOAT, tmpDword);
	    break;


	case OP_LOCAL_ARRAY_REF_C1_LV:
	case OP_LOCAL_ARRAY_REF_L1_LV:
	case OP_LOCAL_ARRAY_REF_M1_LV:
	case OP_MODULE_ARRAY_REF_C1_LV:
	case OP_MODULE_ARRAY_REF_L1_LV:
	case OP_MODULE_ARRAY_REF_M1_LV:
	    s_lval = TRUE;
	    goto OP_ARRAY_SPECIAL;
 	case OP_LOCAL_ARRAY_REF_C1_RV:
	case OP_LOCAL_ARRAY_REF_L1_RV:
	case OP_LOCAL_ARRAY_REF_M1_RV:
 	case OP_MODULE_ARRAY_REF_C1_RV:
	case OP_MODULE_ARRAY_REF_L1_RV:
	case OP_MODULE_ARRAY_REF_M1_RV:
	    s_lval = FALSE;
OP_ARRAY_SPECIAL:

	{
	    word    	element;
	    MemHandle	array = NullHandle; /* mchen, LIBERTY, give initial
					       value to surpress warning */

	    GetWordBcl(PC, element);	/* constant or offset to a variable */
	    GetWordBcl(PC, s_offset);	/* offset of array (local or module) */
	    switch(op) 
	    {
	    case OP_LOCAL_ARRAY_REF_C1_LV:
	    case OP_LOCAL_ARRAY_REF_C1_RV:
		array = rms.bpData[s_offset];
		break;
	    case OP_MODULE_ARRAY_REF_C1_LV:
	    case OP_MODULE_ARRAY_REF_C1_RV:
		array = rms.dsData[s_offset];
		break;
	    case OP_LOCAL_ARRAY_REF_L1_LV:
	    case OP_LOCAL_ARRAY_REF_L1_RV:
		array = rms.bpData[s_offset];
		element = rms.bpData[element];
		break;
	    case OP_MODULE_ARRAY_REF_L1_LV:
	    case OP_MODULE_ARRAY_REF_L1_RV:
		array = rms.dsData[s_offset];
		element = rms.bpData[element];
		break;
	    case OP_LOCAL_ARRAY_REF_M1_LV:
	    case OP_LOCAL_ARRAY_REF_M1_RV:
		array = rms.bpData[s_offset];
		element = rms.dsData[element];
		break;
	    case OP_MODULE_ARRAY_REF_M1_LV:
	    case OP_MODULE_ARRAY_REF_M1_RV:
		array = rms.dsData[s_offset];
		element = rms.dsData[element];
	    default:
		break;
	    }
	    if (s_lval) 
	    {
		PushData(array);
		PushData(element);
		PushType(TYPE_ARRAY_ELT_LV);
	    }
	    else
	    {
		RVal	rvData;

		Run_GetArrayRef(&rms, array, element, &rvData);
		if (PTASK->PT_err)
		{
		    HANDLE_RTE;	/* XXX */
		}
		PushTypeData(rvData.type, rvData.value);
		goto MAYBE_INC_STACKTOP;
	    }
	    break;
	}

	case OP_STRUCT_REF_RV:
	{
	    RunHeapToken structToken;
	    byte*	strucP;

	    GetWordBcl(PC, s_offset);

	    if (TopType() != TYPE_STRUCT)
	    {
		HANDLE_RTE_ERR_DATA(RTE_TYPE_MISMATCH, TYPE_STRUCT);
	    }
	    else if (!(RunHeapToken)TopData())
	    {
		HANDLE_RTE_ERR(RTE_VALUE_IS_NULL);
	    }
	    structToken = PopData();
	    PopTypeV();
	    
	    RunHeapLock(RHI, structToken, (void**)(&strucP));
	    FieldDword(strucP+s_offset, tmpDword);
	    PushTypeData(strucP[s_offset+4], tmpDword);
	    RunHeapDecRefAndUnlock(RHI, structToken, strucP);

	    goto MAYBE_INC_STACKTOP;
	    /* break; */
	}

	case OP_STRUCT_REF_LV:
	{
	    GetWordBcl(PC, s_offset);

	    if (TopType() != TYPE_STRUCT)
	    {
		HANDLE_RTE_ERR_DATA(RTE_TYPE_MISMATCH, TYPE_STRUCT);
	    }
	    else if (!TopData())
	    {
		HANDLE_RTE_ERR(RTE_VALUE_IS_NULL);
	    }

	    /* Keep the struct token, push the field number, modify type */
	    PushData(s_offset);
	    TopType() = TYPE_STRUCT_REF_LV;

	    break;
	}


	case OP_LOCAL_ARRAY_REF_RV:
	case OP_MODULE_ARRAY_REF_RV:
	case OP_ARRAY_REF_RV:
		s_lval = FALSE;
		goto OP_ARRAY_COMMON;
	case OP_LOCAL_ARRAY_REF_LV:
	case OP_MODULE_ARRAY_REF_LV:
	case OP_ARRAY_REF_LV:
		s_lval = TRUE;
OP_ARRAY_COMMON:
	{
	    word        element, numDims;
	    MemHandle   array = NullHandle; /* mchen, LIBERTY, gave initial
					       value to surpress warning */
	    RVal        rvData;

	    /* # dimensions inlined in code */
	    numDims = *PC++;
	    switch (op)		/* Grab array from vars, or stack */
	    {
	    case OP_LOCAL_ARRAY_REF_LV:
	    case OP_LOCAL_ARRAY_REF_RV:
		GetWordBcl(PC, s_offset);
		array = rms.bpData[s_offset];
		break;
	    case OP_MODULE_ARRAY_REF_LV:
	    case OP_MODULE_ARRAY_REF_RV:
		GetWordBcl(PC, s_offset);
		array = rms.dsData[s_offset];
		break;
	    case OP_ARRAY_REF_LV:
	    case OP_ARRAY_REF_RV:
	    {
		if (TopType() != TYPE_ARRAY)
		{
		    HANDLE_RTE_ERR_DATA(RTE_TYPE_MISMATCH, TYPE_ARRAY);
		}
		array = PopData();
		PopTypeV();
		break;
	    }
	    default:   /* default added to get rid of g++ warning, mchen */
		EC_ERROR(RE_FAILED_ASSERTION);
		break;
	    } 
 
	    element = Run_IndicesToArrayRef(&rms, array, numDims);
	    if (PTASK->PT_err) {
		HANDLE_RTE;
	    }
 
	    if (s_lval) 
	    {
		PushData(array);
		PushData(element);
		PushType(TYPE_ARRAY_ELT_LV);
	    }
	    else
	    {
		Run_GetArrayRef(&rms, array, element, &rvData);
		if (PTASK->PT_err)
		{
		    HANDLE_RTE;
		}

		PushTypeData(rvData.type, rvData.value);
		goto MAYBE_INC_STACKTOP;
	    }
	    break;
	}
   
	case OP_MODULE_REF_RV:
	case OP_MODULE_REF_LV:
	{
	    ourt = OpModuleRef(&rms, op, &ourt_ec, &ourt_data);
	    if (ourt != OURT_OK)
	    {
		OURT_RTE;
	    }
	    break;
	}

	case OP_COMP_INIT:
	{
	    OpCompInit(&rms);
	    if (PTASK->PT_err) { HANDLE_RTE; } /* XXX */
	    break;
	}

	case OP_STACK_PROPERTY_RV:
	{
	    word	strConst;
	    RunHeapToken strToken;

	    PROFILE_START_SECTION(PS_OP_GET_PROPERTY);
	    if (NthType(1) != TYPE_STRING) {
		HANDLE_RTE_ERR_DATA(RTE_TYPE_MISMATCH, TYPE_STRING);
	    }
	    if (NthType(2) != TYPE_COMPONENT) {
		HANDLE_RTE_ERR_DATA(RTE_TYPE_MISMATCH, TYPE_COMPONENT);
	    }

	    strToken = PopData();
	    PopTypeV();
	    goto PROP_RV_COMMON;

	case OP_PROPERTY_RV:
	case OP_CUSTOM_PROPERTY_RV:
	    PROFILE_START_SECTION(PS_OP_GET_PROPERTY);
	    GetWordBcl(PC, strConst);
	    strToken = StrMapLookup(RTASK->RT_strConstMap, strConst);
	    /* Fall through */

	    if (TopType() != TYPE_COMPONENT)
	    {
		HANDLE_RTE_ERR_DATA(RTE_TYPE_MISMATCH, TYPE_COMPONENT);
	    }

PROP_RV_COMMON:
	    if (COMP_IS_AGG(TopData())) {
		RunGetAggProperty(&rms, strToken);
	    } else {
		GetProperty(&rms, op, strToken);
	    }
	    if (op == OP_STACK_PROPERTY_RV) {
		RunHeapDecRef(RHI, strToken);
	    }
	    if (PTASK->PT_err) { HANDLE_RTE; }

	    PROFILE_END_SECTION(PS_OP_GET_PROPERTY);
	    break;
	}
	case OP_BC_PROPERTY_RV:
	{
	    PROFILE_START_SECTION(PS_OP_GET_PROPERTY);
	    GetProperty(&rms, op, (RunHeapToken)0);
	    PROFILE_END_SECTION(PS_OP_GET_PROPERTY);

	    if (PTASK->PT_err) { HANDLE_RTE; }
	    break;
	}


	case OP_LOCAL_VAR_RV_INDEX:
	    op = OP_LOCAL_VAR_RV; /* avoid 2 compares down below */
	case OP_LOCAL_VAR_RV_INDEX_REFS:
	    GetByte(PC, s_offset);
	    goto LOCAL_RV_COMMON;
	case OP_LOCAL_VAR_RV_REFS:
	case OP_LOCAL_VAR_RV:	/* compiler-guaranteed not a runheap type */
	{
	    GetWordBcl(PC, s_offset);
LOCAL_RV_COMMON:
	    PushTypeData(rms.bpType[s_offset], rms.bpData[s_offset]);
	    if (op == OP_LOCAL_VAR_RV) {
		ASSERT(!RUN_HEAP_TYPE(TopType(), TopData()));
		break;
	    }
	    goto MAYBE_INC_STACKTOP;
	}

	case OP_MODULE_VAR_RV_INDEX:
	    op = OP_MODULE_VAR_RV; /* avoid 2 compares down below */
	case OP_MODULE_VAR_RV_INDEX_REFS:
	    GetByte(PC, s_offset);
	    goto MODULE_RV_COMMON;
	case OP_MODULE_VAR_RV_REFS:
	case OP_MODULE_VAR_RV:	/* compiler-guaranteed not a runheap type */
	{
	    GetWordBcl(PC, s_offset);
MODULE_RV_COMMON:
	    PushTypeData(rms.dsType[s_offset], rms.dsData[s_offset]);
	    if (op == OP_MODULE_VAR_RV) {
		ASSERT(!RUN_HEAP_TYPE(TopType(), TopData()));
		break;
	    }
	    goto MAYBE_INC_STACKTOP;
	}
   
	case OP_MODULE_VAR_LV_INDEX:
	{
	    PushType(TYPE_MODULE_VAR_LV);
	    GetByte(PC, s_offset);
	    goto    MORE_COMMON_VAR_LV;

	case OP_LOCAL_VAR_LV_INDEX:
	    PushType(TYPE_LOCAL_VAR_LV);
	    GetByte(PC, s_offset);
	    goto    MORE_COMMON_VAR_LV;

	case OP_MODULE_VAR_LV:
	    PushType(TYPE_MODULE_VAR_LV);
	    goto COMMON_VAR_LV;
	case OP_LOCAL_VAR_LV:
	    PushType(TYPE_LOCAL_VAR_LV);
COMMON_VAR_LV:
	    GetWordBcl(PC, s_offset);
MORE_COMMON_VAR_LV:
	    PushData(s_offset);
	    break;
	}

	case OP_STACK_PROPERTY_LV:
	{
	    /* prop name already on stack, just want to pop the type byte */
	    TopType() = TYPE_PROPERTY_LV;
	    break;
	}

	case OP_PROPERTY_LV:
	{
	    RunHeapToken	tmpToken;
	    PushType(TYPE_PROPERTY_LV);
	    goto PROP_AFTER_PUSH;

	case OP_CUSTOM_PROPERTY_LV:
	    PushType(TYPE_CUSTOM_PROPERTY_LV);
PROP_AFTER_PUSH:
	    GetWordBcl(PC, tmpWord);
	    tmpToken = StrMapLookup(RTASK->RT_strConstMap, tmpWord);
	    RunHeapIncRef(RHI, tmpToken);
	    PushData(tmpToken);
	    break;
	}

	case OP_BC_PROPERTY_LV:
	{
	    GetByte(PC, tmpWord);

#ifndef LIBERTY
	    /* handle separately to deal with byte-sized compiled properties
	     * prop #s go from 0-511; odd #s are SET */
	    tmpWord = (tmpWord<<1) + 1;
#endif
	    PushTypeData(TYPE_BC_PROPERTY_LV, tmpWord);
	    break;
	}
   
	    /* ----------------------------------------*/
   
	case OP_DIR_ASSIGN_MC:
	    /* Direct assignment of a constant to a module variable,
	       OP <variable offset:word> <constant:dword>
	    */
   
	    GetWordBcl(PC, s_loff);
	    GetDwordBcl(PC, tmpDword);
	    rms.dsData[s_loff] = tmpDword;
	    goto TOP;
   
	case OP_DIR_ASSIGN_ML:
	    /* Direct assignment of a local variable to a module variable,
	       OP <mod var:word> <loc var: word>
	    */
	    GetWordBcl(PC, s_loff);
	    GetWordBcl(PC, s_roff);

	    rms.dsData[s_loff] = rms.bpData[s_roff];
	    goto TOP;
   
	case OP_DIR_ASSIGN_MM:
	    /* Direct assignment of a module variable to a module variable
	       OP <dest mod var:word> <src mod var:word>
	     */
   
	    GetWordBcl(PC, s_loff);
	    GetWordBcl(PC, s_roff);

	    rms.dsData[s_loff] = rms.dsData[s_roff];
	    goto TOP;

	case OP_DIR_ASSIGN_LL:
	    /* Direct assignment of one local variable to another
	       OP <dest var:word> <src var: word>
	    */
   
	    GetWordBcl(PC, s_loff);
	    GetWordBcl(PC, s_roff);

	    rms.bpData[s_loff] = rms.bpData[s_roff];
	    goto TOP;

	case OP_DIR_ASSIGN_LM:
	    /* Direct assignment of a module variable to a local
	       OP <dest local:word> <src module: word>
	    */
	    GetWordBcl(PC, s_loff);
	    GetWordBcl(PC, s_roff);

	    rms.bpData[s_loff] = rms.dsData[s_roff];
	    goto TOP;

	case OP_DIR_ASSIGN_LC:
	    /* Direct assignment of a constant to a local variable,
	       OP <var offset:word> <constant:dword>
	    */
	    GetWordBcl(PC, s_loff);
	    GetDwordBcl(PC, tmpDword);
	    rms.bpData[s_loff] = tmpDword;
	    goto TOP;

	    /* Assignment of constant or variable to array ref on the stack
	     */
	case OP_DIR_ASSIGN_ARRAY_REF_C:
	    GetType(PC, s_rv.type);
	    GetDwordBcl(PC, s_rv.value);
	    goto DIR_ASSIGN_ARRAY_REF_COMMON;

	case OP_DIR_ASSIGN_ARRAY_REF_M:
	    GetWordBcl(PC, s_offset);
	    s_rv.type  = rms.dsType[s_offset];
	    s_rv.value = rms.dsData[s_offset];
	    goto DIR_ASSIGN_ARRAY_REF_COMMON;

	case OP_DIR_ASSIGN_ARRAY_REF_L:
	    GetWordBcl(PC, s_offset);
	    s_rv.type  = rms.bpType[s_offset];
	    s_rv.value = rms.bpData[s_offset];
	    /* goto DIR_ASSIGN_ARRAY_REF_COMMON;*/

DIR_ASSIGN_ARRAY_REF_COMMON:
	    PopTypeV();
	    Run_SetArrayEltLVal(&rms, &s_rv);
	    if (PTASK->PT_err) {
		HANDLE_RTE;	/* XXX */
	    }
	    goto TOP;

	case OP_EXP_ASSIGN_M_INDEX:
	    s_varsData = rms.dsData;
	    GetByte(PC, s_offset);
	    goto    EXP_ASSIGN_MORE_COMMON;
	case OP_EXP_ASSIGN_L_INDEX:
	    s_varsData = rms.bpData;
	    GetByte(PC, s_offset);
	    goto    EXP_ASSIGN_MORE_COMMON;
	case OP_EXP_ASSIGN_M:
	    s_varsData = rms.dsData;
	    goto EXP_ASSIGN_COMMON;
	case OP_EXP_ASSIGN_L:
	    s_varsData = rms.bpData;
	    /* fall through goto EXP_ASSIGN_COMMON: */
EXP_ASSIGN_COMMON:

	    /* Assignment of value at TOS to a local/module variable,
	     * with NO type checking. */
	    GetWordBcl(PC, s_offset);
EXP_ASSIGN_MORE_COMMON:
	    EC_BOUNDS(s_varsData+s_offset);
	    s_varsData[s_offset] = TopData();
	    PopValVoid();
   	    goto TOP;
  
   
	case OP_ASSIGN:
	case OP_ASSIGN_TYPED:
	{
	    ourt = OpAssign(&rms,op, &ourt_ec, &ourt_data);
	    if (ourt != OURT_OK)
	    {
		OURT_RTE;
	    }
	    break;
	}

	case OP_FOR_LM1_UNTYPED:
	case OP_FOR_LM_TYPED:
	{
	    OpFor(&rms, op);
	    if (PTASK->PT_err) { PUNT_RTE; }
	    break;
	}

	case OP_POP_LOOP:
	{
	    if (TopType() != TYPE_FOR_LOOP) {
		PUNT_RTE_ERR(RTE_UNEXPECTED_END_OF_LOOP);
	    }
	    PopTypeV();
	    PopBigDataVoid(LoopContext);
	    break;
	}

	case OP_NEXT_M1_INT:
	    s_varsData = rms.dsData;
	    goto OP_NEXT_COMMON;
	case OP_NEXT_L1_INT:
	    s_varsData = rms.bpData;
	{
	    LoopContext*	lc;
	    sword		newVal;
 OP_NEXT_COMMON:
	    /* if we dont have a TYPE_FOR_LOOP byte here, something is
	     * really messed up, produce a runtime error and exit
	     */
	    if (TopType() != TYPE_FOR_LOOP) {
		PUNT_RTE_ERR(RTE_UNEXPECTED_END_OF_LOOP);
	    }
	    lc = TopBigData(LoopContext);
	    ASSERT_ALIGNED(lc);
	    EC_BOUNDS(s_varsData + lc->LC_var);

	    /* do we care that we are treating this as unsigned? */
	    newVal = ++s_varsData[lc->LC_var];
	    if ((word)newVal == 0x8000) {
		HANDLE_RTE_ERR(RTE_OVERFLOW);
	    }

	    ASSERT((lc->LC_scope == OP_MODULE_VAR_LV) ||
		   (lc->LC_scope == OP_LOCAL_VAR_LV));

	    if (newVal > (sdword) lc->LC_end) 
	    {
		OpJmpSeg(&rms, lc->LC_cont); /* FIXME: necessary? */
		PopBigDataVoid(LoopContext);
		PopTypeV();
	    }
	    else {
		OpJmpSeg(&rms, lc->LC_code);
	    }
	    break;
	}

	case OP_NEXT_LM:
	{
	    /* Next with non-unit increment.  Calculations always done
	     * with long ints.  OP_FOR will have caught cases where
	     * bounds overflow the variable
	     */
	    LoopContext*	lc;
	    LegosType	varType;
	    sdword	result, oldValue;
	    byte	intVarP = 0;

	    if (TopType() != TYPE_FOR_LOOP) {
		PUNT_RTE_ERR(RTE_UNEXPECTED_END_OF_LOOP);
	    }
	    lc = TopBigData(LoopContext);

	    if (lc->LC_scope == OP_LOCAL_VAR_LV) {
		s_varsData = rms.bpData;
		varType = rms.bpType[lc->LC_var];
	    } else {
		s_varsData = rms.dsData;
		varType = rms.dsType[lc->LC_var];
	    }

	    oldValue = s_varsData[lc->LC_var];

	    ASSERT( varType == TYPE_INTEGER || varType == TYPE_LONG );
	    if (varType == TYPE_INTEGER)
	    {
		intVarP = 1;
		oldValue = (sdword)(sword)oldValue;
	    }
		
	    ASSERT( !intVarP || VALIDINT(lc->LC_inc) );
	    result = oldValue + lc->LC_inc;

	    s_varsData[lc->LC_var] = result;

	    /* Check for overflow -- Important that this happen
	     * after assigning
	     */
	    if (((oldValue ^ result) < 0) &&
		((oldValue ^ lc->LC_inc) >= 0))
	    {
		HANDLE_RTE_ERR(RTE_OVERFLOW);
	    }

	    if ((lc->LC_inc > 0 && result > lc->LC_end) ||
		(lc->LC_inc < 0 && result < lc->LC_end)) 
	    {
		if (intVarP && !VALIDINT(result))
		{
		    HANDLE_RTE_ERR(RTE_OVERFLOW);
		}

		OpJmpSeg(&rms, lc->LC_cont); /* FIXME: necessary? */
		PopBigDataVoid(LoopContext);
		PopTypeV();
	    } else {
		ASSERT( !intVarP || VALIDINT(result) );
		OpJmpSeg(&rms, lc->LC_code);
	    }
	    goto TOP;
	}

	case OP_COERCE:
	{
	    ourt = OpCoerce(&rms, &ourt_ec, &ourt_data);
	    if (ourt != OURT_OK)
	    {
		OURT_RTE;
	    }
	    break;
	}	    

	    
	case OP_NEGATIVE_INT:
	    OP_UNARY_INT_INT(-);

	case OP_NEGATIVE_LONG:
	    OP_UNARY_LONG_LONG(-);
	    
	case OP_NOT_INT:
	    OP_UNARY_INT_INT(!);
	    
	case OP_NOT_LONG:
	    OP_UNARY_LONG_INT(!);
	    
	    /* unary operations */
	case OP_NEGATIVE:
	case OP_NOT:
	{
	    RVal        rvOp1;
	    
	    PROFILE_START_SECTION(PS_OP_UNARY_OPS);
	    
	    PopVal(rvOp1);
	    switch(op)
	    {
	    case OP_NEGATIVE:
		OpNegative(&rms, rvOp1);
		break;
	    case OP_NOT:
		OpNot(&rms, rvOp1);
	    default:    /* default added to get rid of g++ warning, mchen */
		break;
	    }
	    PROFILE_END_SECTION(PS_OP_UNARY_OPS);

	    if (PTASK->PT_err) { HANDLE_RTE; }
	    break;
	}

	case OP_ADD_INT:
	{
	    sword op2, op1, res;
	    /* For no overflow checking, use OP_BINARY_INT_INT(+); */

	    op1 = NthData(1);
	    op2 = NthData(2);
	    res = op2 + op1;

#ifdef __BORLANDC__
	    /* Fast overflow check... */
	    asm {jno OP_ADD_INT_NO_OVERFLOW}
	    HANDLE_RTE_ERR(RTE_OVERFLOW);
	OP_ADD_INT_NO_OVERFLOW:
#else
	    /* This should work for all 2's complement architectures */
	    /* Overflow checking code stolen from Mips Risc Architecture,
	       by Gerry Kane, Prentice Hall, 1987, pp C8-C9 */
	    if (((res ^ op2) < 0) && ((op1 ^ op2) >= 0)) {
		HANDLE_RTE_ERR(RTE_OVERFLOW);
	    }
#endif
	    NthData(2) = res;	/* no need to set type */
	    PopValVoid();
	    goto TOP; 
	}   

	case OP_ADD_LONG:
	{
	    sdword op1, op2, res;

	    op1 = NthData(1);
	    op2 = NthData(2);
	    res = op2 + op1;

#ifdef __BORLANDC__
	    asm {jno OP_ADD_LONG_NO_OVERFLOW}
	    HANDLE_RTE_ERR(RTE_OVERFLOW);
	OP_ADD_LONG_NO_OVERFLOW:
#else
	    if (((res ^ op2) < 0) && ((op1 ^ op2) >= 0)) {
		HANDLE_RTE_ERR(RTE_OVERFLOW);
	    }
#endif
	    NthData(2) = res;	/* no need to set type */
	    PopValVoid();
	    goto TOP; 
	}

	case OP_SUB_INT:
	{
	    sword op1, op2, res;

	    op1 = NthData(1);
	    op2 = NthData(2);
	    res = op2 - op1;

#ifdef __BORLANDC__
	    asm {jno OP_SUB_INT_NO_OVERFLOW}
	    HANDLE_RTE_ERR(RTE_OVERFLOW);
	OP_SUB_INT_NO_OVERFLOW:
#else
	    /* Opposite of addition, overflow can occur if signs
	     * of operands are different. */
	    if ((res ^ op2) < 0 && (op1 ^ op2) < 0) {
		HANDLE_RTE_ERR(RTE_OVERFLOW);
	    }
#endif
	    NthData(2) = res;	/* no need to set type */
	    PopValVoid();
	    goto TOP; 
	}

	case OP_SUB_LONG:
	{
	    sdword op1, op2, res;

	    op1 = NthData(1);
	    op2 = NthData(2);
	    res = op2 - op1;

#ifdef __BORLANDC__
	    asm {jno OP_SUB_LONG_NO_OVERFLOW}
	    HANDLE_RTE_ERR(RTE_OVERFLOW);
	OP_SUB_LONG_NO_OVERFLOW:
#else
	    if ((res ^ op2) < 0 && (op1 ^ op2) < 0) {
		HANDLE_RTE_ERR(RTE_OVERFLOW);
	    }
#endif
	    NthData(2) = res;	/* no need to set type */
	    PopValVoid();
	    goto TOP; 
	}

	case OP_MULTIPLY_INT:
	{
#ifdef __BORLANDC__

	    sword	res;

	    res = (sword)NthData(2) * (sword)NthData(1);
	    asm {jno OP_MULTIPLY_INT_NO_OVERFLOW}
	    HANDLE_RTE_ERR(RTE_OVERFLOW);

	OP_MULTIPLY_INT_NO_OVERFLOW:
#else
	    /* Easiest way I can think of is
	       to upgrade multiplication to 32 bits
	       and then see if any high bits
	       are set in the result...
	     */
	    sdword res;

	    res = (sword)NthData(2) * (sword)NthData(1);
	    if ((res > 32767) || (res < -32768))
	    {
		HANDLE_RTE_ERR(RTE_OVERFLOW);
	    }
#endif
	    NthData(2) = res;	/* no need to set type */
	    PopValVoid();
	    goto TOP; 
	}   
	    
	case OP_MULTIPLY_LONG:
	{
	    /* FIXME There is no easy way to check overflow here */

	    sdword res;
	    res = (sdword)NthData(2) * (sdword)NthData(1);

	    NthData(2) = res;	/* no need to set type */
	    PopValVoid();
	    goto TOP; 
	}
	    
	case OP_DIVIDE_INT:
	{
	    if (NthData(1) == 0) {
		HANDLE_RTE_ERR(RTE_OVERFLOW);
	    }
	    NthData(2) = (sword)NthData(2) / (sword)NthData(1);
	    PopValVoid();	/* No need to set type */
	    goto TOP; 
	}   

	case OP_DIVIDE_LONG:
	{
	    if (NthData(1) == 0) {
		HANDLE_RTE_ERR(RTE_OVERFLOW);
	    }
	    NthData(2) = (sdword)NthData(2) / (sdword)NthData(1);
	    PopValVoid();	/* No need to set type */
	    goto TOP; 
	}

	case OP_BIT_AND_INT:
	    OP_BINARY_INT_INT(&);
	case OP_BIT_XOR_INT:
	    OP_BINARY_INT_INT(^);
	case OP_BIT_OR_INT:
	    OP_BINARY_INT_INT(|);
	case OP_AND_INT:
	    OP_BINARY_INT_INT(&&);
	case OP_OR_INT:
	    OP_BINARY_INT_INT(||);
	case OP_EQUALS_INT:
	    OP_BINARY_INT_INT(==);
	case OP_LESS_THAN_INT:
	    OP_BINARY_INT_INT(<);
	case OP_LESS_EQUAL_INT:
	    OP_BINARY_INT_INT(<=);
	case OP_GREATER_THAN_INT:
	    OP_BINARY_INT_INT(>);
	case OP_GREATER_EQUAL_INT:
	    OP_BINARY_INT_INT(>=);
	case OP_LESS_GREATER_INT:
	    OP_BINARY_INT_INT(!=);
	case OP_BIT_AND_LONG:
	    OP_BINARY_LONG_LONG(&);
	case OP_BIT_XOR_LONG:
	    OP_BINARY_LONG_LONG(^);
	case OP_BIT_OR_LONG:
	    OP_BINARY_LONG_LONG(|);
	case OP_AND_LONG:
	    OP_BINARY_LONG_INT(&&);
	case OP_OR_LONG:
	    OP_BINARY_LONG_INT(||);
	case OP_EQUALS_LONG:
	    OP_BINARY_LONG_INT(==);
	case OP_LESS_THAN_LONG:
	    OP_BINARY_LONG_INT(<);
	case OP_LESS_EQUAL_LONG:
	    OP_BINARY_LONG_INT(<=);
	case OP_GREATER_THAN_LONG:
	    OP_BINARY_LONG_INT(>);
	case OP_GREATER_EQUAL_LONG:
	    OP_BINARY_LONG_INT(>=);
	case OP_LESS_GREATER_LONG:
	    OP_BINARY_LONG_INT(!=);

	case OP_LESS_GREATER_STRING:
	case OP_EQUALS_STRING:
	{
	    word    res;
	    TCHAR    *s1, *s2;

	    PopVal(s_rv);
	    PopVal(s_rv2);
	    ASSERT(s_rv.type == TYPE_STRING && s_rv2.type == TYPE_STRING);

	    if (s_rv.value == s_rv2.value) {
		/* trivial quick check */
		res = TRUE;
		RunHeapDecRef(RHI, (RunHeapToken) s_rv.value);
		RunHeapDecRef(RHI, (RunHeapToken) s_rv2.value);
	    }
	    else
	    {
		RunHeapLock(RHI,(RunHeapToken) s_rv.value, (void**)(&s1));
		RunHeapLock(RHI,(RunHeapToken)s_rv2.value, (void**)(&s2));

		EC_BOUNDS(s1);
		EC_BOUNDS(s2);
		res = !strcmp(s1, s2);

		RunHeapDecRefAndUnlock(RHI, (RunHeapToken) s_rv.value,  s1);
		RunHeapDecRefAndUnlock(RHI, (RunHeapToken) s_rv2.value, s2);
	    }

	    if (op == OP_LESS_GREATER_STRING) {
		res = !res;
	    }

	    PushTypeData(TYPE_INTEGER, res);
	    break;
	}

	case OP_SUB:
	case OP_MULTIPLY:
	case OP_ADD:
	case OP_DIVIDE:
	case OP_AND:
	case OP_XOR:
	case OP_OR:
	case OP_EQUALS:
	case OP_LESS_THAN:
	case OP_GREATER_THAN:
	case OP_LESS_GREATER:
	case OP_LESS_EQUAL:
	case OP_GREATER_EQUAL:
	case OP_MOD:
	case OP_BIT_AND:
	case OP_BIT_OR:
	case OP_BIT_XOR:
	{
	    RVal        rvOp1, rvOp2;

	    PROFILE_START_SECTION(PS_OP_BINARY_OPS);

	    /* lhs value is pushed first */
	    PopVal(rvOp2);
	    PopVal(rvOp1);

	    switch(op)
	    {
	    case OP_LESS_THAN:
		OpLessThan(&rms, rvOp1, rvOp2);
		break;
	    case OP_GREATER_THAN:
		OpGreaterThan(&rms, rvOp1, rvOp2);
		break;
	    case OP_LESS_EQUAL:
		OpLessEqual(&rms, rvOp1, rvOp2);
		break;
	    case OP_LESS_GREATER:
		OpLessGreater(&rms, rvOp1, rvOp2);
		break;
	    case OP_GREATER_EQUAL:
		OpGreaterEqual(&rms, rvOp1, rvOp2);
		break;
	    case OP_EQUALS:
		OpEquals(&rms, rvOp1, rvOp2);
		break;
	    case OP_MULTIPLY:
		OpMultiply(&rms, rvOp1, rvOp2);
		break;
	    case OP_DIVIDE:
		OpDivide(&rms, rvOp1, rvOp2);
		break;
	    case OP_SUB:
		OpSubtract(&rms, rvOp1, rvOp2);
		break;
	    case OP_ADD:
		OpAdd(&rms, rvOp1, rvOp2);
		break;
	    case OP_OR:
		OpOr(&rms, rvOp1, rvOp2);
		break;
	    case OP_AND:
		OpAnd(&rms, rvOp1, rvOp2);
		break;
	    case OP_XOR:
		OpXor(&rms, rvOp1, rvOp2);
		break;
	    case OP_MOD:
		OpMod(&rms, rvOp1, rvOp2);
		break;
	    case OP_BIT_AND:
		OpBitAnd(&rms, rvOp1, rvOp2);
		break;
	    case OP_BIT_XOR:
		OpBitXor(&rms, rvOp1, rvOp2);
		break;
	    case OP_BIT_OR:
		OpBitOr(&rms, rvOp1, rvOp2);
		break;

	    default:    /* default added to get rid of g++ warning, mchen */
		break;
	    }

	    PROFILE_END_SECTION(PS_OP_BINARY_OPS);
	    if (PTASK->PT_err)
	    {
		/* Ehan code will decref these if necessary */
		PushTypeData(rvOp1.type, rvOp1.value);
		PushTypeData(rvOp2.type, rvOp2.value);
		HANDLE_RTE;
	    }
	    break;
	}

	case OP_DIM:
	case OP_DIM_PRESERVE:
	case OP_DIM_STRUCT:
	    OpDim(&rms, op);
	    if (PTASK->PT_err) { HANDLE_RTE; }
	    break;

	case OP_EHAN_PUSH:
	{
	    rms.ehs = (EHState*)&NthData(0);
	    PushBigDataVoid(EHState);
	    PushType(TYPE_ERROR_HANDLER);
	    ASSERT_ALIGNED(rms.ehs);
	    rms.ehs->ES_handler = 0;
	    rms.ehs->ES_errorVpc = 0;
	    rms.ehs->ES_flags = 0;
	    break;
	}

	case OP_EHAN_POP:
	{
	    if (rms.ehs == NULL) {
		rms.ehs = EHFindState(&rms, FSF_CURRENT_FRAME);
		ASSERT(rms.ehs != NULL);
	    }

	    ASSERT(TopType() == TYPE_ERROR_HANDLER);
	    /* Trying to exit the routine with a pending error, eh? */
	    if (rms.ehs->ES_flags & ESF_ACTIVE) {
		PUNT_RTE_ERR(RTE_ACTIVE_EHAN);
	    }
	    PopBigDataVoid(EHState);
	    PopTypeV();
	    rms.ehs = NULL;
	    break;
	}

	case OP_EHAN_MODIFY:
	{
	    ASSERT(rms.ehs != NULL);
	    ASSERT_ALIGNED(rms.ehs);
	    GetWordBcl(PC, s_offset);
	    rms.ehs->ES_handler = s_offset;
	    if (s_offset == 0) {
		/* ONERROR GOTO 0 */
		rms.ehs->ES_flags &= ~ESF_ENABLED;
	    } else {
		rms.ehs->ES_flags |= ESF_ENABLED;
	    }
	    break;
	}
	case OP_EHAN_RESUME:
	{
	    if (! EHResume(&rms)) { HANDLE_RTE; }
	    break;
	}
	case OP_LINE_BEGIN:
	case OP_LINE_BEGIN_NEXT:
	    /* Save some information in current routine's EHState
	     * so we can restore context if an error occurs on this line.
	     *
	     * rms.ehs Could be nulled out if we called a routine that had
	     * its own error handler
	     */
	    if (rms.ehs == NULL) {
		rms.ehs = EHFindState(&rms, FSF_CURRENT_FRAME);
		EC_ERROR_IF(rms.ehs == NULL, RE_FAILED_ASSERTION);
	    }

	    /* If this handler is active, don't dork ES_tos or
	     * ES_errorVpc; ES_errorVpc is needed to resume, and tos
	     * has a different meaning within an error handler.
	     *
	     * If it's not enabled, or if it's active,
	     * optimize out setting the state,
	     * since it won't be useful anyway.
	     */
	    if (rms.ehs->ES_flags == ESF_ENABLED)
	    {
		rms.ehs->ES_savedVspType = rms.spType - rms.typeStack;
#if !USES_SEGMENTS
		rms.ehs->ES_errorVpc = rms.pc - rms.code - 1;
#else
		/* high 4 bits are seg #; low 12 bits are offset w/in seg */
		rms.ehs->ES_errorVpc =
		    ((PTASK->PT_context.FC_codeHandle-
		      PTASK->PT_context.FC_startSeg) << 12) |
			  (rms.pc-rms.code-1);
#endif
	    }

	    if (op == OP_LINE_BEGIN_NEXT) {
		PC += 2;		/* discard next-line info for now */
	    }
	    break;

	case OP_NO_OP:
	case OP_DEBUG:
	    /*op = OP_ILLEGAL;*/        /* dummy code to set breakpoint at */
	    break;

	case OP_BREAK:
	{
	    OpBreak(&rms);
	    if (PTASK->PT_err) {
		/* rpctest might raise RTE_QUIET_EXIT if it wants us to stop.
		 * Need to duplicate a bit of the RE_ENTRY code here before
		 * punting -- dubois 11/96 */
		RunSetupRML(ptaskHan, &rms);
		HANDLE_RTE;
	    }
	    goto RE_ENTRY;
	    /* return; */
	}

	default:
	    PUNT_RTE_ERR( RTE_BAD_OPCODE );
	    /* return; UNREACHED */

	} /* switch (op) */
    } /* while (1) */

    /* Shouldn't be able to get out of that while (1) !
     * And don't give us guff about unreachable code...
     */
#ifndef LIBERTY
#pragma warn -rch
    EC_ERROR(-1);
#pragma warn .rch
#endif

    /*- Handle errors
     */
 ourt_error:
    switch(ourt)
    {
    case OURT_HANDLE_RTE:
	HANDLE_RTE;
    case OURT_HANDLE_RTE_ERR:
	HANDLE_RTE_ERR(ourt_ec);
    case OURT_HANDLE_RTE_ERR_DATA:
	HANDLE_RTE_ERR_DATA(ourt_ec, ourt_data);
    case OURT_PUNT_RTE_ERR:
	PUNT_RTE_ERR(ourt_ec);
    case OURT_OK:
	break;
    }


    /* Type 1: Search for error trap
     */
/* FIXME: does there need to be BugSetSuspendStatus stuff here like
 * in OP_END_PROC?  Jimmy?		--dubois
 */
 handle_error_with_error:
#ifdef __BORLANDC__
    asm { mov errorData, cx }
    asm { mov runError, dx }
#endif
    RunSetErrorWithData(PTASK, runError, (dword) errorData);
 handle_error:
    if (! EHHandleError(&rms))
    {
 punt_error:


	/* if we are running in some rtask that is not being debugged, and
	 * the HALT flag is set in the ptask, then don't put up any error
	 * since we are just halting anyways.
	 *
	 * Liberty uses RTE_QUIET_EXIT in a similar way; PT_HALT is #ifdef'd
	 * out in various places (why?) --dubois 11/96
	 */
	tmpWord = FALSE;
	if ((PTASK->PT_err == RTE_QUIET_EXIT) ||
	    ( (PTASK->PT_bugHandle == NullHandle) &&
	      (PTASK->PT_flags & PT_HALT) ))
	{
	    tmpWord = TRUE;
	}

	if (!tmpWord && !PTASK->PT_suspendedErrorCount)
	{
	    if (PTASK->PT_bugHandle != NullHandle)
	    {
		/* avoid putting up dialog if the user hit stop just
		 * before the error was hit
		 */
		BugInfoHeader *b =(BugInfoHeader*)MemLock(PTASK->PT_bugHandle);
		if (b->BIH_builderState != BS_STOPPED)
		{
		    SignalRuntimeError(PTASK->PT_err, PTASK->PT_errData);
		    EHContactDebugger(&rms);
		}
		MemUnlock(PTASK->PT_bugHandle);
	    }
	    else
	    {
		byte	args[12];
		int 	doDialog;
		/* handle system error handler before punt_error so punt really does punt
		 *  - its unclear to me why we would ever have PUNT instead of HANDLE error
		 */
		RTaskHan    sys;
		LegosType   type;
		LegosData   ld;
		*args = 2;
		*(args + 1) = TYPE_MODULE;
		CopyDword(args+2, &RTASK->RT_handle);
		/* *(dword *)(args+2) = RTASK->RT_handle; */
		*(args+6) = TYPE_INTEGER;
		CopyWordToDword(args+7, &PTASK->PT_err);
		/* *(dword *)(args+7) = PTASK->PT_err; */
		/* tempororily set the err to RT_NONE so RunCallFunction
		 * doesn't reject the call
		 */
		PTASK->PT_err = RTE_NONE;
		sys = GetSystemModule(PTASK);
		PTASK->PT_suspendedErrorCount++;
		doDialog = TRUE;
		/* enabled re-entrant calls in the ptask */
		INT_ON(&rms);
		if (sys != NullHandle) {
		    ld.LD_gen_dword = 0;
		    if (RunCallFunction(sys, _TEXT("runTimeError"), 
					   args, &type, &ld.LD_gen_dword))
		    {
			/* Do not test ld.LD_integer because we pass
                           ld.LD_gen_dword above, and the position of
                           ld.LD_integer within gen_dword is byte
                           order dependent. */
			if (type == TYPE_INTEGER && ld.LD_gen_dword)
			{
			    doDialog = FALSE;
			}
		    }
		}
		INT_OFF(&rms);
		PTASK->PT_suspendedErrorCount--;
		CopyWordFromDword(&PTASK->PT_err, args+7);
		/* PTASK->PT_err = *(dword *)(args+7); */
		if (doDialog) {
		    SignalRuntimeError(PTASK->PT_err, PTASK->PT_errData);
		}
	    }
	}
    {
	FrameContext	fc;
	fc = EHCleanStack(&rms);
	RunCleanMain(&rms);
	if (fc.FC_codeHandle != NullHandle) {
	    PTASK->PT_context = fc;
	}
    }
	return FALSE;
    } else {
	goto TOP;
    }

    /* Type 2: (old-style) Ignore error traps.
     *  These should eventually all be converted to type 1
     */
 punt_error_with_error:
#ifdef __BORLANDC__
    asm { mov errorData, cx }
    asm { mov runError, dx }
#endif
    RunSetErrorWithData(PTASK, runError, (dword) errorData);
    goto punt_error;
}
#undef PTASK
#undef RTASK
#undef PC

/*********************************************************************
 *                      RunSetError
 *********************************************************************
 * SYNOPSIS:    Set an error in the curren task
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *      Remove the EC_ERROR when we're done debugging.
 *      Right now it sucks to hit an anomalous situation and have
 *      the error propagate upwards, because all the higher-level
 *      stuff does is fatal error anyway.
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     12/27/94        Initial version                      
 * 
 *********************************************************************/
void RunSetError(PTaskPtr ptask, RuntimeErrorCode error)
{
    /* Call RunSetErrorWithData so we can just set a breakpoint there
     * to catch all error setting
     */
    RunSetErrorWithData(ptask, error, 0);
    return;
}

void RunSetErrorWithData(PTaskPtr ptask, RuntimeErrorCode error, dword data)
{
    if (ptask->PT_err == RTE_NONE)
    {
#if defined(DEBUG_AID) && defined(EC_LOG)
	extern char* theComponentTraceFile;
	if (theComponentTraceFile) {
	    theLog << "Legos runtime error " << error 
		   << " with data " << data << '\n';
	    theLog.Flush();
	}
#endif
	ptask->PT_err = error;
	ptask->PT_errData = data;
    }
}

void RunSetErrorHandle(PTaskHan ptaskHan, RuntimeErrorCode error)
{
    PTaskPtr    ptask;
    ptask = (PTaskPtr) MemLock(ptaskHan);
    RunSetErrorWithData(ptask, error, 0);
    MemUnlock(ptaskHan);
    return;
}


#ifndef LIBERTY
#pragma warn -def
void
DummyFunc()
{
    /* Just some crap to get ProfileSections into our symbol file */
    RunVTab		rvt;
    RunVTabEntry	rvte;
    ProfileSections	dummy;
    Warnings		w = 0;
    FatalErrors		f = 0;

    rvt = rvt;
    rvte = rvte;
    w=w;f=f;
    dummy = PS_RUN_MAIN_LOOP;
    dummy=dummy;
}
#pragma warn .def
#endif
