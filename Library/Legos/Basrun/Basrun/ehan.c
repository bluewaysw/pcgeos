/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Runtime
FILE:		ehan.c

AUTHOR:		dubois, Jan  9, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	1/9/96  	Initial version.

DESCRIPTION:
	Error-handling code.  Declares global array of type sizes
	on stack -- also declares local version of same thing.

	$Revision: 1.2 $

	Liberty version control
	$Id: ehan.c,v 1.2 98/10/05 12:40:14 martin Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/runint.h>
#include <Legos/stack.h>
#include "bugext.h"
#include <Legos/rheapint.h>
#include <Legos/builtin.h>

#include <Legos/ehan.h>
#include <Legos/ehanint.h>

#include <Ansi/string.h>

#else	/* GEOS version below */

#include <Ansi/string.h>

#include "mystdapp.h"
#include "runint.h"
#include "stack.h"
#include "bugext.h"
#include "rheapint.h"
#include "builtin.h"
#include "ehan.h"
#include "ehanint.h"
#include "fixds.h"
#endif

#define RMS (*rms)

extern void ECCheckFrameContext(FrameContext *fc);

/* This creates a table of data sizes.  sizes are given in dwords */

/* Round up to multiple of 4, then divide by 4 */ 
#define ROUND4(_x) (((word)(_x)+3)>>2)
#define DATASIZE_ERR 0xff

#define MakeDataSizeTable(_name)					\
const byte _name[] =							\
{									\
    1,				/* UNKNOWN */				\
    1,				/* FLOAT */				\
    1,				/* INTEGER */				\
    1,				/* LONG */				\
    1,				/* STRING */				\
    1,				/* COMPONENT */				\
    1,				/* ARRAY */				\
    2,				/* ARRAY_ELT_LV */			\
    DATASIZE_ERR,		/* ERROR */				\
    sizeof(LoopContext)/4,	/* FOR_LOOP */				\
    sizeof(FrameContext)/4,	/* FRAME_CONTEXT */			\
    1,				/* TYPE_MODULE */			\
    DATASIZE_ERR,		/* TYPE_ILLEGAL */			\
    1,				/* TYPE_COMPLEX */			\
    sizeof(EHState)/4,		/* ERROR_HANDLER */			\
    1,				/* LOCAL_VAR_LV */			\
    1,				/* MODULE_VAR_LV */			\
    1,				/* PROPERTY_LV */			\
    1,				/* BC_PROPERTY_LV */			\
    2,				/* MODULE_REF_LV */			\
    1,				/* STRUCT */				\
    2,				/* STRUCT_REF_LV */			\
    DATASIZE_ERR,		/* VOID */				\
    1,				/* CUSTOM_PROPERTY_LV */		\
    DATASIZE_ERR,		/* BYTE -- only shows up in compinit */	\
}


MakeDataSizeTable(EH_DataSizes);

#if defined(__BORLANDC__)
#pragma option -zEEHAN_TEXT -zFCODE
#endif

#ifndef LIBERTY
/* Make one of these tables in current code seg as well -- it's not large,
 * and is probably smaller/definitely easier than calling
 * setDSToDgroup/restoreDS all over the place.
 */
MakeDataSizeTable(_far EH_DataSizesCS);
#ifdef __BORLANDC__
#define EH_DataSizes ((const byte _cs*)((word)EH_DataSizesCS))
#else /* __HIGHC__ */
#define EH_DataSizes ((const byte *)((word)EH_DataSizesCS))
#endif
#endif

/* Table of opcode argument sizes
 *
 * OPSIZE_ERR is used for difficult cases that I don't expect to
 * need in this table.
 *
 * OPSIZE_SPECIAL means "process specially"
 */

#define OPSIZE_ERR 0xff
#define OPSIZE_SPECIAL 0xfe

#ifdef LIBERTY
#define EH_OpSizes EH_OpSizesCS
#else
#ifdef __BORLANDC__
#define EH_OpSizes ((const byte _cs*)((word)EH_OpSizesCS))
#else /*__HIGHC__*/
#define EH_OpSizes ((const byte *)((word)EH_OpSizesCS))
#endif
#endif
static const byte _far EH_OpSizesCS[] = {
    2,				/* OP_INTEGER_CONST */
    4,				/* OP_LONG_CONST */
    4,				/* OP_FLOAT_CONST */
    2,				/* OP_STRING_CONST */

    1,				/* OP_COERCE */

    OPSIZE_ERR,			/* OP_ILLEGAL */
    OPSIZE_SPECIAL,		/* OP_BREAK */
    
    OPSIZE_ERR,			/* OP_START_FUNCTION */
    OPSIZE_ERR,			/* OP_END_FUNCTION */
    OPSIZE_ERR,			/* OP_START_PROCEDURE */
    OPSIZE_ERR,			/* OP_END_PROCEDURE */
    2,				/* OP_CALL */
    2,				/* OP_MODULE_CALL_PROC */
    2,				/* OP_MODULE_CALL_FUNC */
    2,				/* OP_CALL_PRIMITIVE */

    4,				/* OP_LOCAL_ARRAY_REF_C1_RV */
    4,				/* OP_LOCAL_ARRAY_REF_L1_RV */
    4,				/* OP_LOCAL_ARRAY_REF_M1_RV */
    4,				/* OP_MODULE_ARRAY_REF_C1_RV */
    4,				/* OP_MODULE_ARRAY_REF_L1_RV */
    4,				/* OP_MODULE_ARRAY_REF_M1_RV */

    2,				/* OP_LOCAL_VAR_RV */
    2,				/* OP_MODULE_VAR_RV */
    3,				/* OP_LOCAL_ARRAY_REF_RV */
    3,				/* OP_MODULE_ARRAY_REF_RV */
    1,				/* OP_ARRAY_REF_RV */
    2,				/* OP_PROPERTY_RV */
    1,				/* OP_BC_PROPERTY_RV */
    0,				/* OP_MODULE_REF_RV */

    4,				/* OP_LOCAL_ARRAY_REF_C1_LV */
    4,				/* OP_LOCAL_ARRAY_REF_L1_LV */
    4,				/* OP_LOCAL_ARRAY_REF_M1_LV */
    4,				/* OP_MODULE_ARRAY_REF_C1_LV */
    4,				/* OP_MODULE_ARRAY_REF_L1_LV */
    4,				/* OP_MODULE_ARRAY_REF_M1_LV */

    2,				/* OP_LOCAL_VAR_LV */
    2,				/* OP_MODULE_VAR_LV */
    3,				/* OP_LOCAL_ARRAY_REF_LV */
    3,				/* OP_MODULE_ARRAY_REF_LV */
    1,				/* OP_ARRAY_REF_LV */
    2,				/* OP_PROPERTY_LV */
    1,				/* OP_BC_PROPERTY_LV */
    0,				/* OP_MODULE_REF_LV */

    2,				/* OP_ACTION_PROC */
    1,				/* OP_BC_ACTION_PROC */
    2,				/* OP_ACTION_FUNC */
    1,				/* OP_BC_ACTION_FUNC */

    5,				/* OP_DIM */

    0,				/* OP_ADD_INT */
    0,				/* OP_ADD_LONG */
    0,				/* OP_SUB_INT */
    0,				/* OP_SUB_LONG */
    0,				/* OP_MULTIPLY_INT */
    0,				/* OP_MULTIPLY_LONG */
    0,				/* OP_DIVIDE_INT */
    0,				/* OP_DIVIDE_LONG */
    0,				/* OP_AND_INT */
    0,				/* OP_AND_LONG */
    0,				/* OP_OR_INT */
    0,				/* OP_OR_LONG */
    0,				/* OP_EQUALS_INT */
    0,				/* OP_EQUALS_LONG */
    0,				/* OP_EQUALS_STRING */
    0,				/* OP_LESS_THAN_INT */
    0,				/* OP_LESS_THAN_LONG */
    0,				/* OP_LESS_EQUAL_INT */
    0,				/* OP_LESS_EQUAL_LONG */
    0,				/* OP_GREATER_THAN_INT */
    0,				/* OP_GREATER_THAN_LONG */
    0,				/* OP_GREATER_EQUAL_INT */
    0,				/* OP_GREATER_EQUAL_LONG */
    0,				/* OP_LESS_GREATER_INT */
    0,				/* OP_LESS_GREATER_LONG */
    0,				/* OP_LESS_GREATER_STRING */
    0,				/* OP_ADD */
    0,				/* OP_SUB */
    0,				/* OP_MULTIPLY */
    0,				/* OP_DIVIDE */
    0,				/* OP_LESS_THAN */
    0,				/* OP_GREATER_THAN */
    0,				/* OP_LESS_GREATER */
    0,				/* OP_LESS_EQUAL */
    0,				/* OP_GREATER_EQUAL */
    0,				/* OP_EQUALS */
    0,				/* OP_AND */
    0,				/* OP_OR */
    0,				/* OP_XOR */
    0,				/* OP_MOD */
    0,				/* OP_NEGATIVE_INT */
    0,				/* OP_NEGATIVE_LONG */
    0,				/* OP_POSITIVE_INT */
    0,				/* OP_POSITIVE_LONG */
    0,				/* OP_NOT_INT */
    0,				/* OP_NOT_LONG */
    0,				/* OP_NEGATIVE */
    0,				/* OP_POSITIVE */
    0,				/* OP_NOT */

    0,				/* OP_DUP */
    0,				/* OP_POP */

    0,				/* OP_ASSIGN */

    4,				/* OP_DIR_ASSIGN_LL */
    4,				/* OP_DIR_ASSIGN_LM */
    6,				/* OP_DIR_ASSIGN_LC */
    4,				/* OP_DIR_ASSIGN_ML */
    4,				/* OP_DIR_ASSIGN_MM */
    6,				/* OP_DIR_ASSIGN_MC */
    5,				/* OP_DIR_ASSIGN_ARRAY_REF_C */
    2,				/* OP_DIR_ASSIGN_ARRAY_REF_L */
    2,				/* OP_DIR_ASSIGN_ARRAY_REF_M */
    2,				/* OP_EXP_ASSIGN_L */
    2,				/* OP_EXP_ASSIGN_M */

    2,				/* OP_BEQ */
    1,				/* OP_BEQ_REL */
    2,				/* OP_BEQ_SEG */

    2,				/* OP_BNE */
    1,				/* OP_BNE_REL */
    2,				/* OP_BNE_SEG */
    
    2,				/* OP_JMP */
    1,				/* OP_JMP_REL */
    2,				/* OP_JMP_SEG */

    0,				/* OP_DEBUG */

    /* args to OP_FOR look like bytecode for a varref and a jmp
     * so instead of special handling, just treat these as having
     * 0 bytes of arg...
     */
    0,				/* OP_FOR_LM1_UNTYPED */
    0,				/* OP_FOR_LM_TYPED */

    0,				/* OP_NEXT_L1_INT */
    0,				/* OP_NEXT_M1_INT */
    OPSIZE_SPECIAL,		/* OP_NEXT_LM */

    0,				/* OP_POP_LOOP */

    1,				/* OP_ZERO */

    2,				/* OP_CALL_WITH_TYPE_CHECK */

    0,				/* OP_SWAP */

    2,				/* OP_STRUCT_REF_RV */
    2,				/* OP_STRUCT_REF_LV */
    4,				/* OP_DIM_STRUCT */

    0,				/* OP_ASSIGN_TYPED */
    
    2,				/* OP_LOCAL_VAR_RV_REFS */
    2,				/* OP_MODULE_VAR_RV_REFS */
    OPSIZE_SPECIAL,		/* OP_COMP_INIT */
    5,				/* OP_DIM_PRESERVE */

    0,				/* OP_STACK_PROPERTY_RV */
    0,				/* OP_STACK_PROPERTY_LV */
    0,				/* OP_STACK_ACTION_PROC */
    0,				/* OP_STACK_ACTION_FUNC */
    0,				/* OP_NO_OP */
    
    0,				/* OP_EHAN_PUSH */
    0,				/* OP_EHAN_POP */
    2,				/* OP_EHAN_MODIFY */
    2,				/* OP_EHAN_RESUME */
    0,				/* OP_LINE_BEGIN */
    0,				/* OP_LINE_BEGIN_NEXT */

    0,				/* OP_BIT_AND */
    0,				/* OP_BIT_AND_INT*/
    0,				/* OP_BIT_AND_LONG */
    0,				/* OP_BIT_OR */
    0,				/* OP_BIT_OR_INT */
    0,				/* OP_BIT_OR_LONG */
    0,				/* OP_BIT_XOR */
    0,				/* OP_BIT_XOR_INT */
    0,				/* OP_BIT_XOR_LONG */

    1,				/* OP_LOCAL_VAR_RV_INDEX */
    1,				/* OP_LOCAL_VAR_RV_INDEX_REFS */
    1,				/* OP_LOCAL_VAR_LV_INDEX */
    1,				/* OP_MODULE_VAR_RV_INDEX */
    1,				/* OP_MODULE_VAR_RV_INDEX_REFS */
    1,				/* OP_MODULE_VAR_LV_INDEX */

    2,				/* OP_CUSTOM_PROPERTY_LV */
    2,				/* OP_CUSTOM_PROPERTY_RV */
    1,				/* OP_EXP_ASSIGN_L_INDEX */
    1,				/* OP_EXP_ASSIGN_M_INDEX */
    1,				/* OP_BYTE_INTEGER_CONST */
    1,				/* OP_BYTE_STRING_CONST  */
};


#if defined(__BORLANDC__)
#pragma option -zE* -zF*
#endif

/*********************************************************************
 *			EHResume
 *********************************************************************
 * SYNOPSIS:	Implement RESUME
 * CALLED BY:	EXTERNAL RunMainLoop
 * RETURN:	FALSE on error
 * SIDE EFFECTS:
 * STRATEGY:
 *	code: <op> <arg: word>
 *
 *	arg = 0		resume
 *	arg = 0xffff	resume next
 *	else		resume <arg>, where arg is a code ptr.
 *
 *	If "resume" or "resume next", unroll stack to what it was
 *	at the beginning of the erroneous line (there are exceptions...
 *	see EH_FindNextLine).
 *
 *	If "resume <label>", unroll stack all the way to top of frame,
 *	leaving only the error trap.  The compiler will guarantee that
 *	<label> is at the top-level of the routine (not within any
 *	FOR or SELECT blocks)
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/12/96  	Initial version
 * 
 *********************************************************************/
Boolean
EHResume(RMLPtr rms)
{
    word	destAddr;
    byte*	dest_spType;

    /* errData should be either valid for the most recent error, or 0
     */
    rms->ptask->PT_errData = 0;

    GetWordBcl(rms->pc, destAddr);

    ASSERT(rms->ehs != NULL);
    ASSERT_ALIGNED(rms->ehs);

    if (!(rms->ehs->ES_flags & ESF_ACTIVE))
    {
	RunSetError(rms->ptask, RTE_INACTIVE_EHAN);
	return FALSE;
    }
    rms->ehs->ES_flags &= ~ESF_ACTIVE;

    /* Remove anything the error handler might have left on the stack
     */
    dest_spType = rms->typeStack + rms->ehs->ES_savedVspType;
    while (rms->spType > dest_spType)
    {
	EH_PopVal(rms, PVF_NO_FRAME_CONTEXT | PVF_NO_ERROR_HANDLER);
    }
    ASSERT(dest_spType == rms->spType);

    /* Special cases of destAddr: 0 (resume), 0xffff (resume next)
     */
    if (destAddr == 0) {
	CopyWord(&destAddr, &(rms->ehs->ES_errorVpc));
    } else if (destAddr == 0xffff) {
	destAddr = EH_FindNextLine(rms);
    } else {
	while (TopType() != TYPE_ERROR_HANDLER) {
	    EH_PopVal(rms, PVF_NO_FRAME_CONTEXT | PVF_NO_ERROR_HANDLER);
	}
    }

    OpJmpSeg(rms, destAddr);
    return TRUE;
}

/*********************************************************************
 *			EH_FindNextLine -d-
 *********************************************************************
 * SYNOPSIS:	Find line following line causing error
 * CALLED BY:	INTERNAL EHResume
 * RETURN:	VCP to line begin opcode
 * SIDE EFFECTS:
 * STRATEGY:
 *	Assume that ES_errorVpc is in the current function
 *
 *	Walk through code until an OP_LINE_BEGIN_* opcode is found
 *	It may not be in the current segment (ugh)
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/16/96  	Initial version
 * 
 *********************************************************************/
word
EH_FindNextLine(RMLPtr rms)
{
    byte	*start, *cursor;
    word	offset;
#if USES_SEGMENTS
    word	seg;
    word	startSeg;
    word	segSize;
#endif
    
    ASSERT_ALIGNED(rms->ehs);
    offset = rms->ehs->ES_errorVpc;

#if USES_SEGMENTS
    startSeg = rms->ptask->PT_context.FC_startSeg;
    seg = (offset >> 12);
    offset &= 0x0fff;
    HugeArrayLock(rms->rtask->RT_vmFile,
		  rms->rtask->RT_funTabInfo.FTI_code,
		  startSeg+seg, (void**)&start, &segSize);
#else
    start = rms->code;
#endif

    cursor = start+offset;

    if (*cursor == OP_LINE_BEGIN_NEXT)
    {
	/* Use supplied argument instead of searching through code
	 */
	NextWordBcl(cursor+1, offset);
#if USES_SEGMENTS
	/* Liberty doesn't need unlock because code was never switched
	   due to segmenting being unsupported in Liberty */
	HugeArrayUnlock(start);
#endif
	return offset;
    }
    ASSERT(*cursor == OP_LINE_BEGIN);

    while (1) {
	Opcode	op;
	GetOpcode(cursor, op);

OPSWITCH:
	switch(op) {
	case OP_NEXT_LM:
	case OP_NEXT_M1_INT:
	case OP_NEXT_L1_INT:
	{
	    /* If an error occurs on a NEXT line, we need to pop
	     * the for state off the stack.
	     */
	    ASSERT(TopType() == TYPE_FOR_LOOP);
	    PopTypeV();
	    PopBigDataVoid(LoopContext);
	    break;
	}
	case OP_BREAK:
	{
#ifndef LIBERTY
	    /* Grab the real opcode and try again */
	    BugBreakPoint	bbp;
	    word		funcNum;
	    
	    funcNum = BugGetFuncFromContext(&rms->ptask->PT_context);
	    bbp = BugDoesBreakAtOffset
		(rms->rtask->RT_bugHandle, funcNum,
		 ((cursor-start-1) | (seg<<12)),
		 BBF_NORMAL | BBF_ONE_TIME);
	    ASSERT(bbp.BBP_insn != OP_ILLEGAL);
	    op = bbp.BBP_insn;
#endif
	    goto OPSWITCH;
	}
	case OP_COMP_INIT:
	{
	    byte	i,nProps;
	    LegosType	t;
	    Boolean	bcProp;
	    
	    nProps = *cursor++;
	    for (i=0;i<nProps;i++) {
		t = *cursor++;
		bcProp = (Boolean)(t&0x80);
		t &= 0x7f;
		cursor += (t == TYPE_STRING || t == TYPE_INTEGER) ? 2 : 4;
		cursor += bcProp ? 1 : 2;
	    }
	    break;
	}
	default:
	{
	    byte	dataSize;
	    ASSERT(op < OP_NUM_OPS);
	    dataSize = EH_OpSizes[op];
	    ASSERT(dataSize != OPSIZE_SPECIAL && dataSize != OPSIZE_ERR);
	    cursor += dataSize;
	    break;
	}
	}
#if USES_SEGMENTS
	/* Switch to next segment, if necessary */
	ASSERT(cursor-start <= segSize);
	if (cursor-start == segSize) {
	    HugeArrayUnlock(start);
	    seg++;
	    ASSERT(! (seg & 0xfff0));
	    HugeArrayLock(rms->rtask->RT_vmFile,
			  rms->rtask->RT_funTabInfo.FTI_code,
			  startSeg+seg, (void**)&start, &segSize);
	    cursor = start;
	}
#endif

	if (*cursor == OP_LINE_BEGIN ||
	    *cursor == OP_LINE_BEGIN_NEXT) {
	    break;
	}
    }
    HugeArrayUnlock(start);

#if USES_SEGMENTS
    ASSERT(! ((cursor-start) & 0xf000));
    ASSERT(! (seg & 0xfff0));
    offset = (cursor-start) | (seg << 12);
#else
    offset = cursor - start;
#endif
    return offset;
}

/*********************************************************************
 *			EHHandleError -d-
 *********************************************************************
 * SYNOPSIS:	Jump to error trap on error
 * CALLED BY:	EXTERNAL, RunMainLoop
 * RETURN:	FALSE if there is no available error handler.
 * SIDE EFFECTS:lots
 * STRATEGY:
 *	0. Don't try to handle certain really bad errors
 *     .5. If debugging enabled, scan to see if there are any usable
 *	   error handlers.  If there aren't, don't do any stack unrolling,
 *	   as the debugger will want to snoop the stack first.
 *
 *	1. Search and unroll stack until enabled error handler is found
 *	2. Unroll current line
 *	3. Save tos and jump to error handler
 *
 *	tos is saved so that handler can RESUME even if it leaves shme
 *	on the stack.  This can happen if there is a RESUME within
 *	a FOR or SELECT block, for example.
 *
 * BUGS/IDEAS:
 *	Not unrolling the stack if debugger is around was tacked on later.
 *	Algorithm could be cleaned up to be 1-pass instead of 2-pass.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/12/96  	Initial version
 * 
 *********************************************************************/
Boolean
EHHandleError(RMLPtr rms)
{
    byte*	spType_dest;
    word	tmpW;

#pragma warn -rch
#pragma warn -ccc
    ASSERTS(sizeof EH_OpSizesCS == OP_NUM_OPS,
	    "Opcode size table is out of date");
#ifndef LIBERTY
    ASSERTS(sizeof EH_DataSizesCS == TYPE_NUM_TYPES,
	    "Type size table is out of date");
#endif
#pragma warn .ccc
#pragma warn .rch

    /* Don't catch these because...
     * RTE_INTERNAL_ERROR: stack might be messed up
     * RTE_QUIET_EXIT: designed to force an exit
     */
    if ((rms->ptask->PT_err == RTE_INTERNAL_ERROR) ||
	(rms->ptask->PT_err == RTE_QUIET_EXIT))
    {
	return FALSE;
    }

    /*- .5. Search for an error handler first
     */
    if (rms->ptask->PT_bugHandle != NullHandle) {
	if (EHFindState(rms, FSF_ENABLED_INACTIVE) == NULL)
	    return FALSE;
    }

    /*- 1. Look for an enabled error handler
     */

    /* Might have one from a few frames back; search for it anyway
     * because we unroll frames as we go up the stack
     */
    rms->ehs = NULL;
    do {
	byte*	typeCursor = rms->spType-1;
	dword*	dataCursor = rms->spData;

	while (*typeCursor != TYPE_ERROR_HANDLER)
	{
	    ASSERT(typeCursor >= rms->typeStack);
	    ASSERT(*typeCursor < TYPE_NUM_TYPES);

	    if (*typeCursor == TYPE_FRAME_CONTEXT) break;

	    dataCursor -= EH_DataSizes[*typeCursor];
	    typeCursor -= 1;
	}
	
	switch (*typeCursor) {

	case TYPE_ERROR_HANDLER:
	    rms->ehs = (EHState*)((byte*)dataCursor-sizeof(EHState));
	    ASSERT_ALIGNED(rms->ehs);
	    if (rms->ehs->ES_flags == ESF_ENABLED) {
		/* Cha-ching! Found one we can use */
		break;
	    } else {
		rms->ehs = NULL;
		/* Fall through */
	    }

	case TYPE_FRAME_CONTEXT:
	    if (!EH_UnrollFrame(rms)) {
		return FALSE;
	    }
	    break;

	default: EC_ERROR(-1);
	}

    } while (rms->ehs == NULL);
    ASSERT((byte*)rms->ehs > (byte*)rms->bpData);

    /*- 2. Unroll current line
     */
    spType_dest = rms->typeStack + rms->ehs->ES_savedVspType;

    while (rms->spType > spType_dest)
    {
	EH_PopVal(rms, PVF_NO_FRAME_CONTEXT | PVF_NO_ERROR_HANDLER);
    }

    /*- 3. Save error and jump to error handler
     */
    CopyWord(&(rms->ehs->ES_pendingError), &(rms->ptask->PT_err));
    rms->ptask->PT_err = RTE_NONE;
    rms->ehs->ES_flags |= ESF_ACTIVE;
    
    CopyWord(&tmpW, &(rms->ehs->ES_handler));
    OpJmpSeg(rms, tmpW);
    return TRUE;
}

/*********************************************************************
 *			EH_UnrollFrame -d-
 *********************************************************************
 * SYNOPSIS:	Unroll one frame.
 * CALLED BY:	INTERNAL, EHHandleError
 * RETURN:	FALSE if the top frame was hit.
 * SIDE EFFECTS:
 * STRATEGY:
 *	Do essentially the same thing as OP_END_[PROC/FUNC]
 *	except don't worry about cleaning up variables or
 *	anything like that; just switch code segments and/or
 *	modules, and update PT_context
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/12/96  	Initial version
 * 
 *********************************************************************/
Boolean
EH_UnrollFrame(RMLPtr rms)
{
    FrameContext*	fc;
    Boolean	newModule = FALSE;
    MemHandle	oldHan;

    while (1)
    {
	if (! EH_PopVal(rms, PVF_SIGNAL_FRAME_CONTEXT)) break;
    }
    ASSERT(rms->spType > rms->bpType);
    ASSERT(TopType() == TYPE_FRAME_CONTEXT);

    fc = TopBigData(FrameContext);
    EC_CHECK_CONTEXT(fc);

    if (fc->FC_vpc & VPC_RETURN) {
	return FALSE;
    }
    
    /* Returning to different module?
     */
    if (fc->FC_module != rms->rtask->RT_handle)
    {
	newModule = TRUE;
	if (rms->rtask->RT_moduleVars) {
	    MemUnlock(rms->rtask->RT_moduleVars);
	}
	MemUnlock(rms->rtask->RT_handle);
	rms->rtask = RunTaskLock(fc->FC_module);
	rms->ptask->PT_context.FC_module = fc->FC_module;

	if (rms->rtask->RT_moduleVars) {
	    LOCK_GLOBALS(rms->rtask->RT_moduleVars, rms->dsType, rms->dsData);
	}
    }
    ECG(ECCheckFrameContext(&rms->ptask->PT_context));

    oldHan = rms->ptask->PT_context.FC_codeHandle;
    rms->ptask->PT_context = *fc;

    rms->bpType = rms->typeStack + fc->FC_vbpType;
    rms->bpData = rms->dataStack + fc->FC_vbpData;

    if (newModule || (fc->FC_codeHandle != oldHan))
    {
#ifdef LIBERTY
	CheckUnlock(oldHan);
	rms->code = (byte*)CheckLock(fc->FC_codeHandle);
#else
	word dummy;
	USE_IT(oldHan);
	HugeArrayUnlock(rms->code);
	HugeArrayLock(rms->rtask->RT_vmFile, 
		      rms->rtask->RT_funTabInfo.FTI_code,
		      fc->FC_codeHandle, (void**)&rms->code, &dummy);
#endif
    }

    rms->pc = rms->code + fc->FC_vpc;

    PopTypeV();
    PopBigDataVoid(FrameContext);

    return TRUE;
}

/*********************************************************************
 *			EHCleanStack -d-
 *********************************************************************
 * SYNOPSIS:	Unwind the stack until we hit a return frame.
 * CALLED BY:	EXTERNAL
 * RETURN:	VPC_RETURN context
 * SIDE EFFECTS:
 * STRATEGY:
 *	1. Unroll stack until a VPC_RETURN context is hit
 *	2. Remove the rest of current frame (context and locals)
 *
 *	Returned context should be used to restore ptask context
 *	before exiting current interpreter invocation
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/19/96  	Initial version
 * 
 *********************************************************************/
FrameContext
EHCleanStack(RMLPtr rms)
{
    byte*	finalBpType;	/* To unroll arguments */
#if ERROR_CHECK
    dword*	finalBpData = rms->bpData;
#endif
    FrameContext fc;

    /* If it's an internal error, don't even bother unwinding
     * because there is probably weird stuff on the stack.
     * Avoiding ec code is better.
     */
    fc.FC_codeHandle = NullHandle;
    if (rms->ptask->PT_err == RTE_INTERNAL_ERROR)
    {
	return fc;
    }

    /* Unroll until we hit a return frame
     */
    finalBpType = rms->bpType;
    while(1)
    {
	ASSERT(rms->spData > rms->dataStack);
	if (!EH_PopVal(rms, PVF_SIGNAL_FRAME_CONTEXT))
	{
	    ASSERT(TopType() == TYPE_FRAME_CONTEXT);
	    fc = * TopBigData(FrameContext);

	    if (fc.FC_vpc & VPC_RETURN)
	    {
		/* top-level frame of the current interpreter invocation */
		fc.FC_vpc &= ~VPC_RETURN;
		EH_PopVal(rms,0);
		break;
	    }
	    else
	    {
		finalBpType = rms->typeStack + fc.FC_vbpType;
#if ERROR_CHECK
		finalBpData = rms->dataStack + fc.FC_vbpData;
#endif
		EH_PopVal(rms,0);
	    }
	}
    }
    
    /* Unroll arguments.  When done, sp == bp */
    while (rms->spType > finalBpType)
    {
	EH_PopVal(rms, PVF_NO_FRAME_CONTEXT);
    }
    ASSERT(rms->spType == finalBpType && rms->spData == finalBpData);

    return fc;
}

/*********************************************************************
 *			EH_PopVal -d-
 *********************************************************************
 * SYNOPSIS:	Pop a value off the stack
 * CALLED BY:	INTERNAL, stack cleanup routines
 * RETURN:	FALSE if failed (probably b/c of a passed PopValFlag)
 * SIDE EFFECTS:
 * STRATEGY:
 *	PopValFlags are mainly for EC, checking that we're not popping
 *	off things that we weren't expecting to pop.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/12/96  	Initial version
 * 
 *********************************************************************/
Boolean
EH_PopVal(RMLPtr rms, PopValFlags flags)
{
    switch ( TopType() )
    {
    case TYPE_STRUCT_REF_LV:	/* struct field TOS */
	PopDataV();		/* pop field offset */
	/* Fall through to pop and decref the struct */
    case TYPE_PROPERTY_LV:	/* just a string on the stack */
    case TYPE_RUN_HEAP_CASE:
    {
	RVal	rv;

	PopVal(rv);
	RunHeapDecRef(rms->rhi, rv.value);
	break;
    }
    case TYPE_COMPONENT:
    {
	RVal	rv;

	PopVal(rv);
	if (COMP_IS_AGG(rv.value)) {
	    RunHeapDecRef(rms->rhi, AGG_TO_STRUCT(rv.value));
	}
	break;
    }

    case TYPE_UNKNOWN:
    case TYPE_FLOAT: case TYPE_INTEGER: case TYPE_LONG: case TYPE_ARRAY:
    case TYPE_ARRAY_ELT_LV:
    case TYPE_FOR_LOOP:
    case TYPE_MODULE:
    case TYPE_LOCAL_VAR_LV:
    case TYPE_MODULE_VAR_LV:
    case TYPE_BC_PROPERTY_LV:
    case TYPE_MODULE_REF_LV:
    case TYPE_CUSTOM_PROPERTY_LV:
    {
	rms->spData -= EH_DataSizes[TopType()];
	PopTypeV();
	break;
    }

    case TYPE_FRAME_CONTEXT:
    {
	if (flags & PVF_SIGNAL_FRAME_CONTEXT) return FALSE;
	EC_ERROR_IF(flags & PVF_NO_FRAME_CONTEXT, RE_FAILED_ASSERTION);
	rms->spData -= EH_DataSizes[TYPE_FRAME_CONTEXT];
	PopTypeV();
	break;
    }

    case TYPE_ERROR_HANDLER:
    {
	EC_ERROR_IF(flags & PVF_NO_ERROR_HANDLER, RE_FAILED_ASSERTION);
	rms->spData -= EH_DataSizes[TYPE_ERROR_HANDLER];
	PopTypeV();
	break;
    }

    default:
    case TYPE_ILLEGAL: case TYPE_ERROR: case TYPE_VOID:
    {
	/* Otherwise, will just loop infinitely */
	CFatalError(-1);
    }

    }
    return TRUE;
}

/*********************************************************************
 *			EHFindState -d-
 *********************************************************************
 * SYNOPSIS:	Find EHState in current frame
 * CALLED BY:	EXTERNAL
 * RETURN:	Pointer to state, NULL if not found
 * SIDE EFFECTS:
 * STRATEGY:
 *	FSF_CURRENT_FRAME:	search current frame only
 *
 *	FSF_ENABLED_INACTIVE:	find only handlers that can handle new
 *	  errors.  They must be enabled (have somplace to jump to)
 *	  but inactive (not already handling an error)
 *
 *	In any case, search only until we find a frame with
 *	VPC_RETURN set.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/11/96  	Initial version
 * 
 *********************************************************************/
EHState*
EHFindState(RMLPtr rms, FindStateFlags flags)
{
    byte*	typeCursor = rms->spType-1;
    dword*	dataCursor = rms->spData;
    EHState*	es = NULL;

    while (1)
    {
	ASSERT(*typeCursor < TYPE_NUM_TYPES);

	if (*typeCursor == TYPE_ERROR_HANDLER)
	{
	    es = ((EHState*)dataCursor)-1;
	    if (!(flags & FSF_ENABLED_INACTIVE) ||
		(es->ES_flags == ESF_ENABLED)) {
		break;
	    }
	}

	if (*typeCursor == TYPE_FRAME_CONTEXT)
	{
	    FrameContext*	fc;

	    if (flags & FSF_CURRENT_FRAME) {
		es = NULL;
		break;
	    }

	    fc = ((FrameContext*)dataCursor)-1;
	    if (fc->FC_vpc & VPC_RETURN) {
		es = NULL;
		break;
	    }
	}

	ASSERT(EH_DataSizes[*typeCursor] != DATASIZE_ERR);

	dataCursor -= EH_DataSizes[*typeCursor];
	typeCursor -= 1;
    }

    /* Check FSF_CURRENT_FRAME assertion */
#if ERROR_CHECK
    if ((es != NULL) && (flags & FSF_CURRENT_FRAME))
    {
	ASSERT((byte*)es > (byte*)rms->bpData);
    }
#endif
    return es;
}

/*********************************************************************
 *			EHContactDebugger -d-
 *********************************************************************
 * SYNOPSIS:	Put up an error dialog; signal debugger if necessary
 * CALLED BY:	INTERNAL RunCallFunction
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	5/3/95  	Pulled out from RunCallFunction
 *	dubois	1/24/96  	Moved from runrout.c, renamed
 * 
 *********************************************************************/
void
EHContactDebugger(RMLPtr rms)
{
#ifdef LIBERTY
    USE_IT(rms);
    EC_WARN("No debugger in Liberty.");
#else
    optr	destObject;
    word	destMessage;
    byte	start;
    int		ln;
    BugInfoHeader *b;
    int	    	buildTime;
    BuilderState    bs;

    /* PT_context may not have been updated
     */
    rms->ptask->PT_context.FC_vbpType = rms->bpType - rms->typeStack;
    rms->ptask->PT_context.FC_vbpData = rms->bpData - rms->dataStack;
    rms->ptask->PT_context.FC_vpc = rms->pc-rms->code;

    rms->ptask->PT_vspType = rms->spType - rms->typeStack;
    rms->ptask->PT_vspData = rms->spData - rms->dataStack;

    if (rms->ptask->PT_bugHandle &&
	rms->ptask->PT_err != RTE_QUIET_EXIT)
    {
	RunTask*	bugRTask;

	b = (BugInfoHeader*) MemLock(rms->ptask->PT_bugHandle);

	destObject = b->BIH_destObject;
	destMessage= b->BIH_destMessage;
	BugSetSuspendStatus(rms->ptask->PT_bugHandle, BSS_ERROR);
	    
	/* since we are here because we hit an error, VPC will have
	 * advanced at least one byte past the start of the line as the
	 * opcode was read, and since VPC is sometimes at the beginning
	 * of the next line by the time we get here, subtracting one from
	 * vpcUnreloc should always do the right thing (sure it will!)
	 */
	if (rms->ptask->PT_context.FC_module == rms->ptask->PT_bugModule)
	{
	    ln = BugOffsetToLineNum
		(rms->ptask->PT_bugHandle,
		 BugGetFuncFromContext(&rms->ptask->PT_context),
		 rms->ptask->PT_context.FC_vpc - 1 |
		   ((rms->ptask->PT_context.FC_codeHandle - 
		     rms->ptask->PT_context.FC_startSeg) << 12),
		 &start);
	    b->BIH_breakLine = ln;
	}
	else
	{
	    b->BIH_breakLine = -1;
	}

	bugRTask = (RunTask*)MemLock(rms->ptask->PT_bugModule);
	buildTime = bugRTask->RT_buildTimeComponents;
	MemUnlock(rms->ptask->PT_bugModule);

	bs = b->BIH_builderState;
	MemUnlock(rms->ptask->PT_bugHandle);


	/* if buildTime is non-zero, we are probably trying to run duplo_ui
	 * code in the builder, probably in a LoadFile, so don't block on
	 * the semaphore, as we will get stuck here
	 * if we are already stopped for some reason then just exit
	 */
	if (!buildTime && bs != BS_STOPPED) 
	{
	    /* Ugh... unlock code segment here to avoid double-thread
	     * vmfile deadlock, because debugger code called by gandalf
	     * accesses the hugearray as well.  Perhaps we could set
	     * the single-thread-access bit instead, but ask adam first.
	     */
	    word	dummy;
	    HugeArrayUnlock(rms->code);

	    RunSendMessage((dword)destObject, destMessage);
	    BugSitAndSpin(destMessage);

	    HugeArrayLock(rms->rtask->RT_vmFile,
			  rms->rtask->RT_funTabInfo.FTI_code,
			  rms->ptask->PT_context.FC_codeHandle,
			  (void**)&rms->code, &dummy);
	}
    }
#endif
    return;
}

/*********************************************************************
 *			FunctionGetError -d-
 *********************************************************************
 * SYNOPSIS:	Get current pending error
 * CALLED BY:	EXTERNAL, OP_CALL_PRIMITIVE
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Push pending error for _current frame_.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/13/96  	Initial version
 * 
 *********************************************************************/
void
FunctionGetError(RMLPtr rms, BuiltInFuncEnum id)
{
    EHState*	ehs;

    USE_IT(id);
    ehs = EHFindState(rms, FSF_CURRENT_FRAME);
    if (ehs == NULL || !(ehs->ES_flags & ESF_ACTIVE)) {
	PushData(RTE_NONE);
    } else {
	PushData(ehs->ES_pendingError);
    }

    PushType(TYPE_INTEGER);
    return;
}

/*********************************************************************
 *			SubroutineRaiseError -d-
 *********************************************************************
 * SYNOPSIS:	Raise a runtime error.
 * CALLED BY:	EXTERNAL, OP_CALL_PRIMITIVE
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Preserve the error data if it looks like an error handler
 *	is just trying to propagate an error it can't handle.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/13/96  	Initial version
 * 
 *********************************************************************/
void
SubroutineRaiseError(RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rv1;
    EHState*	ehs;
    dword	errorData = 0;

    USE_IT(id);

    PopVal(rv1);

    if (rv1.type != TYPE_INTEGER)
    {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_INTEGER);
	return;
    }

    ehs = EHFindState(rms, FSF_CURRENT_FRAME);
    if (ehs != NULL && (ehs->ES_flags & ESF_ACTIVE))
    {
	if ((word)rv1.value == ehs->ES_pendingError) {
	    errorData = rms->ptask->PT_errData;
	}
    }

    RunSetErrorWithData(rms->ptask, (word)rv1.value, errorData);
}

/*********************************************************************
 *			FunctionRefCounts -d-
 *********************************************************************
 * SYNOPSIS:	Return # references a runheap thing has
 * CALLED BY:	EXTERNAL, OP_CALL_PRIMITIVE
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/21/96  	Initial version
 * 
 *********************************************************************/
void
FunctionRefCounts(RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rv1;
    word	counts = 0;
    GONLY(byte*	data;)

    USE_IT(id);

    PopVal(rv1);
    switch (rv1.type) {
    case TYPE_COMPONENT:
	if (!COMP_IS_AGG(rv1.value)) {
	    break;
	}

	rv1.value = AGG_TO_STRUCT(rv1.value);
	/* fall through */

    case TYPE_RUN_HEAP_CASE:
#ifdef LIBERTY
	counts = LRunHeapGetRefCount(rv1.value);
	LRunHeapDecRef(rv1.value);
#else
	RunHeapLock(rms->rhi, rv1.value, (void**)&data);
	counts = RHE_REFCOUNT(data);
	RunHeapDecRefAndUnlock(rms->rhi, rv1.value, data);
#endif
	break;

    default:
	break;
    }

    PushTypeData(TYPE_INTEGER, counts);
}
