/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		runmain2.c

AUTHOR:		jimmy, Nov  6, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/ 6/95	Initial version.

DESCRIPTION:
	more stuff that doesn't fit in runmain.c

	$Id: runmain2.c,v 1.2 98/10/05 12:31:51 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


#ifdef LIBERTY
#include <Legos/interp.h>
#include <Legos/runheap.h>
#include <Legos/runint.h>
#include <Legos/stack.h>
#include <Legos/sst.h>
#include <Ansi/string.h>
#include <Legos/funtab.h>
#include <Legos/strmap.h>
#include <Legos/fixds.h>
#include <Legos/builtin.h>
#include <Legos/runmath.h>
#include <Legos/fformat.h>
#include <driver/keyboard/tchar.h>
#include <pos/ramalloc.h>
#include <kernel/system.h>
#include "legosdb.h"
#include "legoslog.h"

#ifdef EC_DEBUG_SERCOMP
#include <driver/log.h>
extern Log *myLog;
#endif

#else	/* GEOS version below */

#include "mystdapp.h"
#include <Ansi/string.h>
#include <sem.h>
#include <chunkarr.h>
#include <hugearr.h>
#include <Legos/ent.h>
#include "runint.h"
#include "stack.h"
#include "sst.h"
#include "funtab.h"
#include "strmap.h"
#include "profile.h"
#include "fixds.h"
#include "rheapint.h"
#include "builtin.h"
#include "runmath.h"
#endif

#include "bugext.h"        /* Both Geos/Lib need BugSetSuspendStatus. */

#define RMS (*rms)

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
	RunHeapIncRef(rms->rhi, (data));			\
    }							\
}

#define DEC_REF_IF_RUN_HEAP_TYPE(type, data)		\
{							\
    if (RUN_HEAP_TYPE((type), (data))) {		\
	RunHeapDecRef(rms->rhi, (data));			\
    }							\
}

#endif


static Boolean RunInitStructArray(RMLPtr, ArrayHeader*, byte structNum,
				 word numInitializedElements);

static RunHeapToken RunAllocStruct(RMLPtr rms, byte structNum);


/*********************************************************************
 *			Run_UpdatePTask
 *********************************************************************
 * SYNOPSIS:	Update "unreloc" fields in ptask
 * CALLED BY:	EXTERNAL
 * RETURN:	nothing
 * SIDE EFFECTS:
 *	Updates "unreloc" fields (offsets from handles) in ptask
 *	from cached pointer versions stored in RMLState.
 *
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/25/96  	Initial version
 * 
 *********************************************************************/
void
Run_UpdatePTask(RMLPtr rms)
{
    rms->ptask->PT_vspType = rms->spType - rms->typeStack;
    rms->ptask->PT_vspData = rms->spData - rms->dataStack;
    
    rms->ptask->PT_context.FC_vbpType = rms->bpType - rms->typeStack;
    rms->ptask->PT_context.FC_vbpData = rms->bpData - rms->dataStack;

    rms->ptask->PT_context.FC_vpc = rms->pc - rms->code;
}

/*********************************************************************
 *                      RunCleanMain
 *********************************************************************
 * SYNOPSIS:    Clean up the rtask before we leave execution
 * CALLED BY:   EXTERNAL, RunMainLoop
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Unlocks things locked during interpreter main loop
 *	like code, stack, rtask, ptask
 *	Updates unrelocated stack pointers
 *	Does not update PT_context; callers don't always want it
 *	updated with current rms stuff.
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     12/27/94        Initial version                      
 * 
 *********************************************************************/
void
RunCleanMain(RMLPtr rms)
{

    register PTaskPtr ptask = rms->ptask;

    rms->ptask->PT_vspType = rms->spType - rms->typeStack;
    rms->ptask->PT_vspData = rms->spData - rms->dataStack;

#if ERROR_CHECK
    ptask->PT_busy              = FALSE;
#endif
    EC_BOUNDS(ptask);
    EC_BOUNDS(rms);
    EC_BOUNDS(rms->rtask);

    BEGIN_USING_CACHED_ARRAY;
    if (cachedArray != NullHandle) {
	MemUnlock(cachedArray);
	cachedArray = NullHandle;
	LONLY(cachedArrayPtr = NULL);
    }
    END_USING_CACHED_ARRAY;

#ifdef LIBERTY
    CheckUnlock(ptask->PT_context.FC_codeHandle);
#else
    HugeArrayUnlock(rms->code);
#endif

    if (rms->rtask->RT_moduleVars) {
	MemUnlock(rms->rtask->RT_moduleVars);
    }

    MemUnlock(ptask->PT_stack);
    MemUnlock(rms->rtask->RT_handle);
#if ERROR_CHECK
    rms->rtask = NULL;
#endif
    MemUnlock(ptask->PT_handle);
    return;
}

/*********************************************************************
 *			RunAllocStruct
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	EXTERNAL
 * RETURN:	token to a structure (memhandle for now)
 * SIDE EFFECTS:allocates memory
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/ 7/95	Initial version
 * 
 *********************************************************************/
static RunHeapToken
RunAllocStruct(RMLPtr rms, byte structNum)
{
#ifndef LIBERTY
    optr	info;
#endif
    RunVTab 	*rvt;
    RunVTabEntry *rvte;
    word	i;
    byte    	*structPtr, *sPtr;
    RunHeapToken	retval;
    
#ifdef LIBERTY
    /* liberty doesn't convert to rvte to trade space for time
     * reduce the amount of ifdef by converting
     * interpreter-global struct information is tentatively planned
     * so "optimizing" this code for speed is a frivolous activity
     */
    byte*	elt;
    RunVTab	real_rvt;
    BCLVTab	*bvt;
    RunVTabEntry real_rvte;
    BCLVTabEntry *bvte;		

    rvt = &real_rvt;
    rvte = &real_rvte;

    elt = (byte*)CheckLock(rms->rtask->RT_structInfo);

    /* the information to define all structs is just contiguous in memory. */
    /* we find the right structNum by parsing through and skipping the */
    /* definitions of other structs until we get to the right one.  */
    /* This is slow, but saves RAM (by not creating an indexed structure */
    /* to locate such info quickly) and structs should not be created */
    /* that much anyways. (?) */
    for(i = 0; i < structNum; i++) {
	word	nFields;
	NextWordBcl(elt, nFields);	/* BCLVTab::numFields */
	elt += sizeof(BCLVTab) + nFields * sizeof(BCLVTabEntry);
    }

    /* convert BCLVTab to RunVTab (actually same layout, but safer this way) */
    bvt = (BCLVTab*)elt;
    NextWordBcl(&bvt->numFields, rvt->RVT_numFields);
    NextWordBcl(&bvt->size, rvt->RVT_size);
    bvte = (BCLVTabEntry*)(bvt+1);
#else	/* GEOS version below */
    (void) MemLock(OptrToHandle(rms->rtask->RT_structInfo));
    rvt = ChunkArrayElementToPtr(rms->rtask->RT_structInfo, structNum, NULL);
    rvte = (RunVTabEntry*)(rvt+1);
#endif
    retval = RunHeapAlloc(rms->rhi, RHT_STRUCT, 1, rvt->RVT_size, NULL);
    if (retval != NULL_TOKEN) {
	RunHeapLock(rms->rhi, retval, (void**)(&structPtr));
	sPtr = structPtr;
	memset(structPtr, 0, rvt->RVT_size);

	for (i = 0; i < rvt->RVT_numFields; i++) {
	    RunHeapToken	newStruct;
#ifdef LIBERTY
	    rvte->RVTE_type = bvte->type;
	    rvte->RVTE_structType = bvte->structType;
#endif

	    if (rvte->RVTE_type == TYPE_STRUCT) {
		word    spIndex;
	    
		/* check for old BCL file */
		ASSERT(rvte->RVTE_structType != 0xcc);

		/* since this recursive call can invalidate the structPtr
		 * we need to save away the relative index into the struct
		 * and unlock the structPtr, then relock it after the
		 * call and add back in the index
		 */
		spIndex = structPtr - sPtr;
		RunHeapUnlock(rms->rhi, retval);
		newStruct = RunAllocStruct(rms, rvte->RVTE_structType);
		RunHeapLock(rms->rhi, retval, (void**)(&structPtr));
		sPtr = structPtr;
		structPtr += spIndex;
		CopyRunHeapToken(structPtr, &newStruct);
	    }
	    structPtr[4] = rvte->RVTE_type;
	    structPtr += 5;

#ifdef LIBERTY
	    bvte++;
#else
	    rvte++;
#endif
	}
    }

#ifdef LIBERTY
    CheckUnlock(rms->rtask->RT_structInfo);
#else
    MemUnlock(OptrToHandle(rms->rtask->RT_structInfo));
#endif
    RunHeapUnlock(rms->rhi, retval);
    return retval;
}

/*********************************************************************
 *			RunInitStructArray
 *********************************************************************
 * SYNOPSIS:	Fill in an array with newly-created struct tokens
 * CALLED BY:	OP_DIM
 * RETURN:	FALSE on alloc error
 * SIDE EFFECTS:allocates a bunch of heap entries
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/30/95	Initial version
 * 
 *********************************************************************/
Boolean
RunInitStructArray(RMLPtr rms, ArrayHeader* arrh, byte structNum,
		   word numInitedElts)
{
    word    i, max;

    RunHeapToken* cursor = (RunHeapToken*)(arrh+1);
    ASSERT_ALIGNED(cursor);

    max = arrh->AH_maxElt;

    /* The first <numInitedElts> elements already have structs, so skip
     * over those.
     */
    cursor += numInitedElts;
    for (i=numInitedElts; i<max; i++)
    {
	*cursor = RunAllocStruct(rms, structNum);
	if (*cursor == NULL_TOKEN) {
	    return FALSE;		/* don't bother continuing */
	}
	cursor++;
    }
    return TRUE;
}

/*********************************************************************
 *			OpFor
 *********************************************************************
 * SYNOPSIS:	Implement OP_FOR_* opcodes
 * CALLED BY:	EXTERNAL RunMainLoop
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	OP_FOR_LM1_UNTYPED:
 *		loop variable is a long or an integer, step is 1
 *	OP_FOR_LM_TYPED:
 *		arbitrary step, or if type of any expression/var
 *		is unknown at compile time
 *
 *	OP
 *	<OP_LOCAL_VAR/OP_MODULE_VAR> <var:word>
 *	(identify our loop variable)
 *	<JMP/JMP_REL> <target:byte/word>
 *	(where to jump to when test fails)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dubois	1/10/96  	Initial version
 *
 *********************************************************************/
#define VALIDINT(x) ((sword) (x) == (sdword) (x))
void
OpFor(register RMLPtr rms, Opcode op)
{
    LoopContext	lc;
    byte	opsize = 5;
    byte	quit = 0;
    sdword	start;
    LegosType	tStart, tEnd, tStep, tVar;
    byte*	varsType;
    dword*	varsData;
   
    /* Sign extend start and end
     */
    lc.LC_end = PopData();
    tEnd = PopType();

    start = PopData();
    tStart = PopType();
    
    if (tStart == TYPE_INTEGER) {
	start = (sword) start;
    }
	    
    if (tEnd == TYPE_INTEGER) {
	lc.LC_end = (sword) lc.LC_end;
    }

    lc.LC_scope = (Opcode)*rms->pc;

    /* If LC_scope no longer looks like an opcode, change table
     * in ehan.c; it relies on this fact when scanning through code
     */
    if (lc.LC_scope == OP_LOCAL_VAR_LV) {
	varsData = rms->bpData;
	varsType = rms->bpType;
    } else {
	ASSERT(lc.LC_scope == OP_MODULE_VAR_LV);
	varsData = rms->dsData;
	varsType = rms->dsType;
    }

    NextWordBcl(rms->pc+1, lc.LC_var);
    EC_BOUNDS(varsData + lc.LC_var);
   
    if (op == OP_FOR_LM1_UNTYPED)
    {
	lc.LC_inc   = 1;

	if (start > lc.LC_end) {
	    quit = 1;
	}
    }
    else 
    {
	/* In case any expression is unknown, (including
	   the loop variable being a variant), or if
	   the address is an integer and there are
	   some long exressions, we need
	   to check and make sure everything is cool...
	   
	   It would be possible to add yet another opcode
	   to separate out cases which need type-checking,
	   but I imagine those cases and variable increments
	   will both be uncommon.
	   
	   */
	byte err, foundLong;

	lc.LC_inc = PopData();
	tStep = PopType();
		
	if (tStep == TYPE_INTEGER) {
	    lc.LC_inc = (sword) lc.LC_inc;
	}
   
	err = 0;
	foundLong = 0;
   
	/* If any expression isn't an integer or long,
	   no way jose! */
   
   
	if (   (tStart != TYPE_INTEGER && tStart != TYPE_LONG)
	    || (tEnd   != TYPE_INTEGER && tEnd   != TYPE_LONG)
	    || (tStep  != TYPE_INTEGER && tStep  != TYPE_LONG))
	{
	    err = 1;
	}
   
	if (tStart == TYPE_LONG || tEnd == TYPE_LONG || tStep == TYPE_LONG) 
	{
	    foundLong = 1;
	}

	/* Let's see if the variable we're working with has a useful type */
	tVar = varsType[lc.LC_var];
	if (tVar == TYPE_NONE) 
	{
	    if (foundLong) {
		tVar = TYPE_LONG;
	    } else {
		tVar = TYPE_INTEGER;
	    }
	    varsType[lc.LC_var] = (byte)tVar;
	}

	if (foundLong && tVar != TYPE_LONG) {

	    /* See if the expressions are valid integers and
	       we're using a int variable. That would be ok.
	       */

	    if (!(tVar == TYPE_INTEGER &&
		  VALIDINT(start) &&
		  VALIDINT(lc.LC_end) &&
		  VALIDINT(lc.LC_inc)))
	    {
		RunSetError(rms->ptask, RTE_OVERFLOW);
		return;
	    }
	}
	else if (tVar != TYPE_INTEGER && tVar != TYPE_LONG) {
	    err = 1;
	}

	if (err) {
	    RunSetError(rms->ptask, RTE_TYPE_MISMATCH);
	    return;
	}
		
	if (lc.LC_inc > 0 && start > lc.LC_end) {
	    quit = 1;
	}
	if (lc.LC_inc < 0 && start < lc.LC_end) {
	    quit = 1;
	}
    }


    /* Store the offset where we should jump to
       when the test condition fails.
       */
    EC_ERROR_IF (*(rms->pc+3) != OP_JMP && *(rms->pc+3) != OP_JMP_REL && 
		 *(rms->pc+3) != OP_JMP_SEG, RE_FAILED_ASSERTION);

    /* If data here no longer looks like bytecode for a jmp, change table
     * in ehan.c; it relies on this fact
     */
    switch (*(rms->pc+3))
    {
    case OP_JMP_REL:
	/* JMP_REL means a one-byte relative offset */
#if USES_SEGMENTS
	lc.LC_cont = ((rms->pc+3) + *(rms->pc+4) - rms->code) | 
	    ((rms->ptask->PT_context.FC_codeHandle - 
	      rms->ptask->PT_context.FC_startSeg) << 12);
#else
	lc.LC_cont = ((rms->pc+3) + *(rms->pc+4) - rms->code);
#endif
	break;
    case OP_JMP:
    case OP_JMP_SEG:
	/* Must be OP_JMP or OP_JMP_SEG. Word size target is
	 * indeed the unrelocated offset we want
	 */
	NextWordBcl(rms->pc+4, lc.LC_cont);
	opsize++;
	break;
    }
       
    /* Now store the virtual offset (includes seg #) of the top of the
     * loop body.
     */
#ifdef LIBERTY
    lc.LC_code  = (rms->pc + opsize - rms->code);
#else
    lc.LC_code  = (rms->pc + opsize - rms->code) | 
	((rms->ptask->PT_context.FC_codeHandle -
	  rms->ptask->PT_context.FC_startSeg) << 12);
#endif

    /* Make the initial assignment
     */
    EC_BOUNDS(varsData+lc.LC_var);
    varsData[lc.LC_var] = start;
    
    /* See if we should even bother entering the loop
     */
    if (quit) {
	OpJmpSeg(rms, lc.LC_cont);
    } else {
	rms->pc += opsize;
	PushBigData(&lc, LoopContext);
	PushType(TYPE_FOR_LOOP);
    }
    return;
}

/*********************************************************************
 *			ArrayDecRefElements
 *********************************************************************
 * SYNOPSIS:	dec ref array elements as needed
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/22/96  	Initial version
 * 
 *********************************************************************/
#ifdef LIBERTY
void
LArrayDecRefElements(MemHandle array, word startElement, int numElements)
#else
void
ArrayDecRefElements(RunHeapInfo *rhi, MemHandle array, 
		    word startElement, int numElements)
#endif
{
    word    	    lastElement;
    ArrayHeader	    *arrh;
    RunHeapToken    *data;

    arrh = (ArrayHeader*)MemLock(array);
    if (numElements == ARRAY_DEC_REF_ALL) {
	lastElement = arrh->AH_maxElt;
    } else {
	lastElement = startElement + numElements;
    }
    if (arrh->AH_type == TYPE_STRUCT || arrh->AH_type == TYPE_STRING || 
	arrh->AH_type == TYPE_COMPLEX)
    {
    	arrh++;
	data = (RunHeapToken *)(arrh);
	data += startElement;
	while (startElement < lastElement)
	{
	    RunHeapDecRef(rhi, *data);
	    data++;
	    startElement++;
	}
    }
    MemUnlock(array);
}


/*********************************************************************
 *			OpDim
 *********************************************************************
 * SYNOPSIS:	deal with runtime dims
 * CALLED BY:	RunMainLoop (OP_DIM, OP_DIM_PRESERVE, OP_DIM_STRUCT)
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 6/95	Initial version
 * 
 *********************************************************************/
#define MAX_ARRAY_SIZE	8192

void
OpDim(register RMLPtr rms, Opcode op)
{
    /* Code: byte(VAR_{MODULE,LOCAL}) word(offset)
     *	     byte(# dimensions) byte(type)
     *
     *	if TYPE_STRUCT, also:
     *	     byte(struct ID)
     */
    word        arrtype;
    dword	new_size;
    sword       i;
    MemHandle   array;
    ArrayHeader *arrptr, new_header;
    dword*	varsData;
    word	s_offset;
    word	old_num_elts;	/* first element to init, if array of struct */

    if (op == OP_DIM_STRUCT)
    {
	byte	varScope;
	byte	structType;
	dword*	dataPtr;
	RunHeapToken structToken;

	GetByte(rms->pc, varScope);
	GetWordBcl(rms->pc, s_offset);
	GetByte(rms->pc, structType);

	/* Allocate and store a struct
	 */
	structToken = RunAllocStruct(rms, structType);
	dataPtr = (varScope == VAR_LOCAL) ?
	    &rms->bpData[s_offset] : &rms->dsData[s_offset];
	if ((RunHeapToken)*dataPtr != NULL_TOKEN) {
	    RunHeapDecRef(rms->rhi, *dataPtr);
	}
	*dataPtr = structToken;

	return; 
    }

    GetByte(rms->pc, arrtype);
    GetWordBcl(rms->pc, s_offset);
    GetByte(rms->pc, new_header.AH_numDims);
    GetType(rms->pc, new_header.AH_type);
    /* the dimensions should all be pushed on the run time stack
     * in the reverse order that we want them in the dims array
     */
    for (i = new_header.AH_numDims-1, new_size = 1; i >= 0; i--)
    {
	RVal    rvDim;

	PopVal(rvDim);
	rvDim.type = AssignTypeCompatible(TYPE_INTEGER, rvDim.type,
					  &rvDim.value);
	if (rvDim.type == TYPE_ILLEGAL || rms->ptask->PT_err) 
	{
	    RunSetError(rms->ptask, RTE_BAD_TYPE);
	    return;
	}
	if ((sword)rvDim.value < 0) {
	    RunSetError(rms->ptask, RTE_NEGATIVE_DIM);
	    return;
	}
	new_header.AH_dims[i] = (sword)rvDim.value;
	new_size *= (sword)rvDim.value;
    }

    new_header.AH_maxElt = new_size;
    switch (new_header.AH_type) 
    {
    case TYPE_LONG:
    case TYPE_FLOAT:
    case TYPE_COMPONENT:
#ifdef LIBERTY
    /* MemHandles are 4 byte values in Liberty */
    case TYPE_MODULE:
#endif
	new_size *= 4;
	break;
    case TYPE_RUN_HEAP_CASE:
	new_size *= sizeof(RunHeapToken);
	break;
    default:
	/* for TYPE_INTEGER */
	new_size *= 2;
	break;
    }

#ifndef LIBERTY
    /* GEOS cannot handle more than about 8kb arrays */
    if (new_size > MAX_ARRAY_SIZE)
    {
	PROFILE_END_SECTION(PS_OP_DIM);
	RunSetError(rms->ptask, RTE_ARRAY_TOO_BIG);
	return;
    }
#endif

    if (arrtype == VAR_LOCAL) {
	varsData = &rms->bpData[s_offset];
    } else {
	varsData = &rms->dsData[s_offset];
    }

    array = *varsData;

    CopyMemHandle(&array, varsData);

    /* MemFree is Bad -- there might be other handles to the freed block
     * on the stack or in the global scope
     */
    if (array == NullHandle) {
	array = MemAlloc(new_size + sizeof(ArrayHeader), 
			 HF_SWAPABLE | HF_SHARABLE,
			 HAF_LOCK | HAF_ZERO_INIT);
	if(array == NullHandle) {
	    ASSERTS_WARN(FALSE, "OpDim failed to allocate memory of an array");
	    RunSetError(rms->ptask, RTE_OUT_OF_MEMORY);
	    return;
	}
	arrptr = (ArrayHeader *)MemDeref(array);
	ECL(theHeap.SetTypeAndOwner(arrptr, "ARAY", (Geode*)0);)
	old_num_elts = 0;
    } else if (op == OP_DIM) {
	ArrayDecRefElements(rms->rhi, array, 0, ARRAY_DEC_REF_ALL);
	array = MemReAlloc(array, new_size + sizeof(ArrayHeader), 
			   HAF_LOCK | HAF_ZERO_INIT);
	if(array == NullHandle) {
	    ASSERTS_WARN(FALSE, "OpDim failed to allocate memory of an array");
	    RunSetError(rms->ptask, RTE_OUT_OF_MEMORY);
	    return;
	}
	arrptr = (ArrayHeader *)MemDeref(array);
	ECL(theHeap.SetTypeAndOwner(arrptr, "ARAY", (Geode*)0);)
	memset(((byte*)(arrptr+1)), 0, new_size);
	old_num_elts = 0;	/* Treat like a brand-new array */

#ifdef LIBERTY
	if (cachedArray == array) {
	    /* Liberty should re-deref the cached array  */
	    /* Note that we don't set ds to dgroup since we're Liberty. */
	    cachedArrayPtr = (ArrayHeader*) MemDeref(array);
	}
#endif
    } else {
	/* OP_DIM_PRESERVE */
	ArrayDecRefElements(rms->rhi, array, new_header.AH_maxElt,
			    ARRAY_DEC_REF_ALL);
	array = MemReAlloc(array, new_size + sizeof(ArrayHeader), 
			   HAF_LOCK | HAF_ZERO_INIT);
	if(array == NullHandle) {
	    ASSERTS_WARN(FALSE, "OpDim failed to reallocate memory of an array");
	    RunSetError(rms->ptask, RTE_OUT_OF_MEMORY);
	    return;
	}
	arrptr = (ArrayHeader *)MemDeref(array);
	ECL(HeapSetTypeAndOwner(arrptr, "ARAY"));
	old_num_elts = arrptr->AH_maxElt;

#ifdef LIBERTY
	if (cachedArray == array) {
	    /* Liberty should re-deref the cached array  */
	    /* Note that we don't set ds to dgroup since we're Liberty. */
	    cachedArrayPtr = (ArrayHeader*) MemDeref(array);
	}
#endif
    }

    EC_BOUNDS(arrptr);
    *arrptr = new_header;

    if (new_header.AH_type == TYPE_STRUCT) 
    {
	/* Populate the array with structs.  If we're redimming,
	 * only init the tail end of the array
	 */
	byte	structType;
	GetByte(rms->pc,structType);
	if (RunInitStructArray(rms, 
			       arrptr, 
			       structType, 
			       old_num_elts) == FALSE) {
	    /* On failure, back out the redim and raise an error.
               OP_DIM_PRESERVE leaves the array as it was, OP_DIM
               leaves a 0 element array. */
	    ArrayDecRefElements(rms->rhi, array, 
				old_num_elts, ARRAY_DEC_REF_ALL);
	    array = MemReAlloc(array, 
			       (old_num_elts * sizeof(RunHeapToken) +
				sizeof(ArrayHeader)), 
			       HAF_LOCK | HAF_ZERO_INIT);
	    arrptr = (ArrayHeader *)MemDeref(array);
	    ECL(HeapSetTypeAndOwner(arrptr, "ARAY"));
	    arrptr->AH_maxElt = old_num_elts;
	    RunSetError(rms->ptask, RTE_OUT_OF_MEMORY);
	}
    }
    MemUnlock(array);

    /* Store into variable
     */
    *varsData = array;
    
    PROFILE_END_SECTION(PS_OP_DIM);
}



/*********************************************************************
 *                      SubroutineSetTop
 *********************************************************************
 * SYNOPSIS:    set rtask->uiparent to a new top from basic
 * CALLED BY:   RunMainLoop
 * PASS:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:    
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      jimmy    2/ 1/95        Initial version                      
 * 
 *********************************************************************/
void
SubroutineSetTop(RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvComp;
    USE_IT(id);

    if (TopType() != TYPE_COMPONENT && TopType() != TYPE_STRING) {
	RunSetError(rms->ptask, RTE_TYPE_MISMATCH);
	return;
    }

    PopVal(rvComp);
    if (rvComp.type == TYPE_STRING)
    {
	TCHAR    *top;

	RunHeapLock(rms->rhi, rvComp.value, (void**)&top);
	if (!strcmp(top, _TEXT("app"))) {
	    rms->rtask->RT_uiParent = rms->rtask->RT_appObject;
	} else {
	    RunHeapDecRefAndUnlock(rms->rhi, rvComp.value, top);
	    RunSetError(rms->ptask, RTE_TYPE_MISMATCH);
	    PROFILE_END_SECTION(PS_ROUTINE_SET_TOP);
	    return;
	}
	RunHeapDecRefAndUnlock(rms->rhi, rvComp.value, top);
    } 
    else 
    {
	if (rvComp.value == NullOptr) 
	{
	    RunSetError(rms->ptask, RTE_VALUE_IS_NULL);
	    PROFILE_END_SECTION(PS_ROUTINE_SET_TOP);
	    return;
	}
	rms->rtask->RT_uiParent = rvComp.value;
    }
    return;
}

/*********************************************************************
 *			FunctionIsNullComponent
 *********************************************************************
 * SYNOPSIS:	Returns true if the component given as an
 *              argument is null (equals 0)
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 3/ 7/95	Initial version			     
 * 
 *********************************************************************/
void
FunctionIsNullComponent(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvComp;
    USE_IT(id);

    PROFILE_START_SECTION(PS_FUNC_IS_NULL_COMPONENT);

    /* Grab our only argument, which should be a component */
    if (TopType() != TYPE_COMPONENT) {
	RunSetError(rms->ptask, RTE_TYPE_MISMATCH);
	PROFILE_END_SECTION(PS_FUNC_IS_NULL_COMPONENT);
	return;
    }

    PopVal(rvComp);

    if (rvComp.value == NullOptr) {
	PushData(1);
    } else {
	PushData(0);
    }
    PushType(TYPE_INTEGER);

    PROFILE_END_SECTION(PS_FUNC_IS_NULL_COMPONENT);
    return;
}

/*********************************************************************
 *			FunctionIsNullComplex
 *********************************************************************
 * SYNOPSIS:	Returns true if the complex given as an
 *              argument is null (equals 0)
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 3/ 7/95	Initial version			     
 * 
 *********************************************************************/
void
FunctionIsNullComplex(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvComp;
    USE_IT(id);

    PROFILE_START_SECTION(PS_FUNC_IS_NULL_COMPONENT);

    if (TopType() != TYPE_COMPLEX) {
	RunSetError(rms->ptask, RTE_TYPE_MISMATCH);
	PROFILE_END_SECTION(PS_FUNC_IS_NULL_COMPONENT);
	return;
    }

    PopVal(rvComp);

    if (((RunHeapToken)rvComp.value) == NULL_TOKEN) {
	PushData(1);
    } else {
        RunHeapDecRef(rms->rhi, (RunHeapToken)rvComp.value);
	PushData(0);
    }

    PushType(TYPE_INTEGER);
    PROFILE_END_SECTION(PS_FUNC_IS_NULL_COMPONENT);
    return;
}

/*********************************************************************
 *			RunCreateAggregateComponent
 *********************************************************************
 * SYNOPSIS: 	Create an aggregate by calling basic code
 * CALLED BY:	INTERNAL, FunctionComponent
 * PASS:
 * RETURN:	Component, on runtime stack
 * SIDE EFFECTS:
 * STRATEGY:
 *	Aggregate creation routines look like:
 *	FUNCTION Make(top as component, loader as module) as component
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 8/ 4/95	Initial version
 * 
 *********************************************************************/
void
RunCreateAggregateComponent(RMLPtr rms, RTaskHan aggLib,
			    word funcNum, optr parentOptr)
{
    /* Push: return value, top, loader, # args */
    PushTypeData(TYPE_NONE, 0);
    PushTypeData(TYPE_COMPONENT, parentOptr);
    PushTypeData(TYPE_MODULE, rms->rtask->RT_handle);
    PushTypeData(TYPE_INTEGER, 3);

    RunSwitchFunctions(rms, aggLib, funcNum,
		       RSC_FUNC | RSC_NUM_ARGS | RSC_TYPE_ARGS);
    return;
}

/*********************************************************************
 *			OpEndRoutine -d-
 *********************************************************************
 * SYNOPSIS:	code for OP_START_FUNCTION|PROCEDURE
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/29/96  	Initial version
 * 
 *********************************************************************/
Boolean
OpEndRoutine(RMLPtr rms, Opcode op)
{
    FrameContext *context;
    byte        numGarbage, i;
    MemHandle   oldHan;
    byte    	newModule;

/*    LONLY(TRACE_LOG_DEPTH(--));	/* Delete this and Matt deletes you. */
    PROFILE_START_SECTION(PS_OP_END_ROUTINE);

    if (TopType() != TYPE_FRAME_CONTEXT) {
	RunSetError(rms->ptask, RTE_UNEXPECTED_END_OF_ROUTINE);
	return FALSE;
    }

    rms->pc++;  	/* skip num locals */
    numGarbage = *(rms->pc)++;

    for (i=0; i<numGarbage; i++)
    {
	LegosType	garbageType;
	dword		garbageData;
	byte		variantParam=0;
	word	    	s_offset;
	/* Compiler shouldn't ask to free variable zero of
	   a function, since that's the return variable! */

	GetWordBcl(rms->pc, s_offset);
	if (s_offset & VARIANT_PARAM)
	{
	    variantParam = 1;
	    s_offset &= ~VARIANT_PARAM;
	}		
	EC_ERROR_IF(s_offset == 0 && op == OP_END_FUNCTION,
		    RE_FAILED_ASSERTION);
	garbageType = rms->bpType[s_offset];
	garbageData = rms->bpData[s_offset];

	switch (garbageType) 
	{
	case TYPE_ARRAY:
	{
	    if (variantParam) 
	    {
		/* it's a parameter, not a local variable, and only
		 * arrays should be destroyed only if they're local
		 */
		variantParam = 0;
		break;
	    }

	    /* never got allocated, so don't try to free it */
	    if ((MemHandle)garbageData == NullHandle)
	    {
		break;
	    }

	    BEGIN_USING_CACHED_ARRAY;
	    if ((MemHandle)garbageData == cachedArray) 
	    {
		ECL(UnlockH(garbageData));
		cachedArray = NullHandle;
		LONLY(cachedArrayPtr = NULL);
	    }
	    END_USING_CACHED_ARRAY;

	    ArrayDecRefElements(rms->rhi, (MemHandle)garbageData, 
				0, ARRAY_DEC_REF_ALL);

	    MemFree((MemHandle)garbageData);
	    break;
	}

	case TYPE_COMPONENT:
	    if (!COMP_IS_AGG(garbageData)) break;
	    garbageData = AGG_TO_STRUCT(garbageData);
	    /* fall through */
	case TYPE_RUN_HEAP_CASE:
	    RunHeapDecRef(rms->rhi, (RunHeapToken)garbageData);
	    break;

	default:
	    break;
	}
    }

    ASSERT(TopType() == TYPE_FRAME_CONTEXT);
    context = TopBigData(FrameContext);
    EC_CHECK_CONTEXT(context);

    /* Remove the rest of the frame */
    rms->spData = rms->bpData;
    rms->spType = rms->bpType;
    if (op == OP_END_FUNCTION) {
	/* push return value back on */
	rms->spData++; rms->spType++;
    }

#if (defined(DEBUG_AID) && defined(EC_LOG)) || defined(LEGOS_NONEC_LOG)
    if (theLegosFunctionTraceFlag > 1) {
	if ((dword)context->FC_vpc & VPC_RETURN) {
	    *theLegosFunctionTraceLog << "<< ";
	} else {
	    *theLegosFunctionTraceLog << " < ";
	}
	LOG_INDENT(*theLegosFunctionTraceLog);
	*theLegosFunctionTraceLog << theLegosOpcodeCount << " time: ";
	*theLegosFunctionTraceLog << theSystem.GetSystemTime() << '\n';
    }
#endif


    /* Exiting RML?
     */
    if ((dword)context->FC_vpc & VPC_RETURN)
    {
	FrameContext	tcontext;
	MemHandle	bugHandle, rtaskHan;

	EC_BOUNDS(rms->rtask);
	bugHandle = rms->rtask->RT_bugHandle;
	rtaskHan = rms->rtask->RT_handle;
	    
	/* RunCleanMain() must be called before the old context is restored
	   because Liberty code needs the code handle to unlock it - mchen */

	tcontext = *context;
	RunCleanMain(rms);
	memcpy(&(rms->ptask->PT_context), &tcontext, sizeof(FrameContext));
	rms->ptask->PT_context.FC_vpc &= ~VPC_RETURN;

	if (bugHandle)
	{
	    BugInfoHeader   *b;
	    RunTask 	    *rt;

	    b = (BugInfoHeader*)MemLock(bugHandle);
	    rt = (RunTask*)MemLock(rtaskHan);
	    /* lets make sure we are finishing the correct runmainloop
	     * if vbp-stack > b->breakFrame then we must have entered a
	     * second runmainloop and exited, so lets ignore it and
	     * hope we can continue debugging the original runmainloop call
	     */
	    if ((rt->RT_builderRequest == BBR_NONE) ||
		(b->BIH_runMainLoopCount == b->BIH_breakRunMainLoopCount))
	    {
		rt->RT_builderRequest = BBR_NONE;
		BugSetSuspendStatus(bugHandle, BSS_NORMAL);
		RunSendMessage(b->BIH_destObject, b->BIH_finishMessage);
	    }
	    --(b->BIH_runMainLoopCount);
	    MemUnlock(rtaskHan);
	    MemUnlock(bugHandle);
	}
	PROFILE_END_SECTION(PS_OP_END_ROUTINE);
	PROFILE_END_SECTION(PS_RUN_MAIN_LOOP);

	return TRUE;
    }

    newModule = FALSE;
    if (context->FC_module != rms->rtask->RT_handle)
    {
	/* Returning to a different module */
	/* FIXME: copy code from ehan.c */
	/* unlock old modules globals */
	newModule = TRUE;
	EC_BOUNDS(rms->rtask);
	if (rms->rtask->RT_moduleVars) {
	    MemUnlock(rms->rtask->RT_moduleVars);
	}
	MemUnlock(rms->rtask->RT_handle);
	rms->rtask = RunTaskLock(context->FC_module);
	rms->ptask->PT_context.FC_module = context->FC_module;

	/* lock down new module's globals */
	if (rms->rtask->RT_moduleVars) {
	    LOCK_GLOBALS(rms->rtask->RT_moduleVars, rms->dsType, rms->dsData);
	}
    }

    ECG(ECCheckFrameContext(&(rms->ptask->PT_context)));
    oldHan = rms->ptask->PT_context.FC_codeHandle;

    rms->ptask->PT_context = *context;
    rms->bpType = rms->typeStack + context->FC_vbpType;
    rms->bpData = rms->dataStack + context->FC_vbpData;

    /* lock down code segment if we are returning to a different
     * module, or a different code segment within same module
     */
    if (newModule || (context->FC_codeHandle != oldHan))
    {
#ifdef LIBERTY
	CheckUnlock(oldHan);
	rms->code = (byte*)CheckLock(context->FC_codeHandle);
#else
	word dummy;
	HugeArrayUnlock(rms->code);
	HugeArrayLock(rms->rtask->RT_vmFile, 
		      rms->rtask->RT_funTabInfo.FTI_code,
		      context->FC_codeHandle, (void**)&rms->code, &dummy);
#endif
    }
		
    rms->pc = rms->code + context->FC_vpc;

    PROFILE_END_SECTION(PS_OP_END_ROUTINE);
    return FALSE;
}

/*********************************************************************
 *			OpAssign -d-
 *********************************************************************
 * SYNOPSIS:	code for generic assigments
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/29/96  	Initial version
 * 
 *********************************************************************/
OpUtilReturnType
OpAssign(RMLPtr rms, Opcode op, RuntimeErrorCode *ec, word *data)
{
    RVal        rvR;    /* the rval for right side -- don't modify */
    LegosType   ltype;  /* flavor of variable on left (for switch).
			 * Later used as the type of the variable
			 */
    dword   	tmpDword;
    LegosType	mismatchType;

    USE_IT(data);
    PROFILE_START_SECTION(PS_OP_ASSIGN);
   
    PopVal(rvR);
    ltype = PopType();
   
    switch(ltype) 
    {
    case TYPE_STRUCT_REF_LV: /* C TC R */
    {
	/* No coercion ever needed -- compiler always knows
	 * type of lval but as of now if rhs is type_unknown
	 * compiler will not coerce (FIXME).
	 */
	byte*	structP;
	byte*	fieldP;
	RunHeapToken	structToken;
	word	fieldNum;

	fieldNum = PopData();
	structToken = PopData();

	RunHeapLock(rms->rhi, structToken, (void**)(&structP));
	fieldP = structP+fieldNum;

	if (fieldP[4] != rvR.type)
	{
	    LegosType	newType;
	    newType = AssignTypeCompatible(fieldP[4], rvR.type,
					   &rvR.value);
	    if (newType == TYPE_ILLEGAL)
	    {
		RunHeapDecRefAndUnlock(rms->rhi, structToken, structP);
		newType = fieldP[4]; /* avoid borland error */
		/* push is for cleanup --dubois */
		PushTypeData(rvR.type, rvR.value);
		mismatchType = fieldP[4];
		goto mismatch;	/* untested */
	    }
	}

	NextDword(fieldP, tmpDword);
	DEC_REF_IF_RUN_HEAP_TYPE(fieldP[4], tmpDword);
	CopyDword(fieldP, &rvR.value);
	RunHeapDecRefAndUnlock(rms->rhi, structToken, structP);
	break;
    }

    case TYPE_MODULE_REF_LV: /* C TC R */
    {
	if (Run_SetModuleVarLVal(rms, &rvR) == FALSE)
	{
	    /* push is for cleanup --dubois */
	    PushTypeData(rvR.type, rvR.value);
	    return OURT_HANDLE_RTE;
	}
	break;
    }
   
    case TYPE_MODULE_VAR_LV: /* ?C ?TC R */
    case TYPE_LOCAL_VAR_LV:
    {
	LegosType	prevType;
	RunHeapToken	toDec = NULL_TOKEN;
	word		index;
	byte*		s_varsType;
	dword*		s_varsData;

	if (ltype == TYPE_MODULE_VAR_LV) {
	    s_varsType = rms->dsType;
	    s_varsData = rms->dsData;
	} else {
	    s_varsType = rms->bpType;
	    s_varsData = rms->bpData;
	}

	index = PopData();
	EC_BOUNDS(s_varsData + index);

	/* Previous value might need DecRef
	 */
	prevType = s_varsType[index];
	if (RUN_HEAP_TYPE_CT(prevType))
	{
	    tmpDword = s_varsData[index];
	    if (prevType != TYPE_COMPONENT) {
		toDec = tmpDword;
	    } else if (COMP_IS_AGG(tmpDword)) {
		toDec = AGG_TO_STRUCT(tmpDword);
	    }
	}

	/* Typecheck and coerce if necessary
	 */
	if (op == OP_ASSIGN && (prevType != rvR.type))
	{
	    LegosType   newtype;

	    newtype = AssignTypeCompatible(prevType, rvR.type, &rvR.value);
	    if (newtype == TYPE_ILLEGAL) {
		/* push is for cleanup --dubois */
		PushTypeData(rvR.type, rvR.value);
		mismatchType = prevType;
		goto mismatch;	/* XXX */
	    }
	    s_varsType[index] = newtype;
	}
	else
	{
	    EC_ERROR_IF(s_varsType[index] != rvR.type,
			RE_TYPE_ASSUMPTION_FAILED);
	}

	/* IncRef (assign to var) + DecRef (pop off stack) cancel
	 * each other out, so nothing needed here */
	s_varsData[index] = rvR.value;
	if (toDec != NULL_TOKEN) {
	    RunHeapDecRef(rms->rhi, toDec);
	}
	break;
    }
   
    case TYPE_ARRAY_ELT_LV: /* C TC R */
    {
	Run_SetArrayEltLVal(rms, &rvR);
	if (rms->ptask->PT_err) 
	{
	    /* push is for cleanup --dubois */
	    PushTypeData(rvR.type, rvR.value);
	    return OURT_HANDLE_RTE;	/* XXX */
	}
	break;
    }
   
    case TYPE_PROPERTY_LV:
    case TYPE_CUSTOM_PROPERTY_LV:
    {
	/* stack: component dword(string) rms->tos */
	RVal		rvComp;
	RunHeapToken	nameToken;
	PropertyName	name;
   
	/* Makes logic easier; plus, it's what RunSetAgg expects */
	PushType(TYPE_STRING);
	nameToken = NthData(1);
	rvComp.value = NthData(2);
	rvComp.type = NthType(2);

	if (rvComp.type != TYPE_COMPONENT || rvComp.value == NullOptr)
	{
	    /* push is for cleanup --dubois */
	    PushTypeData(rvR.type, rvR.value);
	    if (rvComp.type != TYPE_COMPONENT) {
		mismatchType = TYPE_COMPONENT;
		goto mismatch;
	    } else {
		*ec = RTE_VALUE_IS_NULL;
		return OURT_HANDLE_RTE_ERR;
	    }
		    /* unreached */
	}
	else if (COMP_IS_AGG(rvComp.value))
	{
	    RunSetAggProperty(rms, &rvR);
	    if (rms->ptask->PT_err) {
		return OURT_HANDLE_RTE;
	    }
	    break;
	}

#ifdef LIBERTY
	name.nameToken = nameToken;
	ASSERT(name.nameToken != NULL_TOKEN);
#else
	RunHeapLock(rms->rhi, nameToken,
		    (void**)(&(name.nameString)));
	EC_ERROR_IF(name.nameString == NULL, RE_FAILED_ASSERTION);
#endif
	PopValVoid();
	PopValVoid();
	goto SET_NONAGG_PROP_COMMON;

    case TYPE_BC_PROPERTY_LV:
	/* stack: component dword(message) rms->tos */

	/* Pop property message and component
	 */
	name.nameMessage = PopData();
	PopVal(rvComp);
	ASSERT(rvComp.type == TYPE_COMPONENT);
	if (rvComp.value == NullOptr) {
	    *ec = RTE_VALUE_IS_NULL;
	    return OURT_PUNT_RTE_ERR;
	}
	LONLY(nameToken = 0;)	/* to get rid of a gnu warning */

 SET_NONAGG_PROP_COMMON:
	SetProperty(rms, (optr)rvComp.value, name,
		    rvR.value, (LegosType)rvR.type,
		    rms->ptask, ltype);
	
	if (ltype != TYPE_BC_PROPERTY_LV)
	{
	    GONLY(RunHeapUnlock(rms->rhi, nameToken));
	    RunHeapDecRef(rms->rhi, nameToken);
	}

	/* Error must have come from SetProperty.
	 * No need to dec.
	 */
	if (rms->ptask->PT_err) 
	{
	    return OURT_HANDLE_RTE;
	}
   
	break;
    } /* case TYPE_PROPERTY_* */

    default:
    {
	/* push is for cleanup --dubois */
	PushTypeData(rvR.type, rvR.value);
	*ec = RTE_INTERNAL_ERROR;
	return OURT_PUNT_RTE_ERR;
    }
    } /* switch */

    PROFILE_END_SECTION(PS_OP_ASSIGN);
    return OURT_OK;

 mismatch:
    RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, mismatchType);
    return OURT_HANDLE_RTE;
}

/*********************************************************************
 *			OpCoerce -d-
 *********************************************************************
 * SYNOPSIS:	coercion code
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/29/96  	Initial version
 * 
 *********************************************************************/
OpUtilReturnType
OpCoerce(RMLPtr	rms, RuntimeErrorCode *ec, word *data)
{
    LegosType	typeToConvert, finalType;
    dword	valToConvert;
    LegosData	newVal;

    newVal.LD_gen_dword = 0;
    GetType(rms->pc, finalType);

    typeToConvert = TopType();
    valToConvert = TopData();

    /* Coercion works for:
     * numeric	-> numeric
     * struct	-> component
     * X	-> X (the null coercion)
     */
	       
    if (finalType == typeToConvert) return OURT_OK;

    if (finalType == TYPE_COMPONENT) 
    {
	ASSERT(typeToConvert == TYPE_STRUCT);
	newVal.LD_gen_dword = STRUCT_TO_AGG(valToConvert);
	goto PUSH_IT;
    }

    ASSERT(finalType == TYPE_LONG ||
	   finalType == TYPE_INTEGER ||
	   finalType == TYPE_FLOAT);

    switch (typeToConvert) {
    case TYPE_LONG:
    {
	if (finalType == TYPE_FLOAT) {
	    newVal.LD_float = (float)(*(sdword*)(&valToConvert));
	} else {
	    ASSERT(finalType == TYPE_INTEGER);
	    if (!VALIDINT(valToConvert)) {
		*ec = RTE_OVERFLOW;
		return OURT_HANDLE_RTE_ERR;
	    }
	    /* always store integers as longs, mchen */
	    newVal.LD_long = (sdword) valToConvert;
	}
	break;
    }
    case TYPE_FLOAT:
    {
	float floatVal = *(float*)(&valToConvert);
#ifdef EC_DEBUG_SERCOMP
	if((rms->pc - rms->code) == 28) {
	    if(myLog == NULL) {
		myLog = new Log("arraylog", 37000, WRAP_AT_END);
		EC(HeapSetTypeAndOwner(myLog, "SXYZ"));
		Result r = myLog->Initialize();
		ASSERT(r == SUCCESS);
	    }
	    myLog->Write("float to long [%.1f,%d][%.1f,%d][%.1f,%d]\n",floatVal,(int)floatVal,floatVal,(int)floatVal,floatVal,(int)floatVal);
	}
#endif
	if (finalType == TYPE_LONG)
	{
	    if (floatVal >  (float) 2147483647.0 || 
		floatVal <  (float ) -2147483648.0)
	    {
		*ec = RTE_OVERFLOW;
		return OURT_HANDLE_RTE_ERR;
		/* return; unreached */
	    }
#ifdef LIBERTY
	    newVal.LD_long = (sdword)floatVal;		    
#else
	    newVal.LD_long = SmartTrunc(floatVal);
#endif

	} else {
	    ASSERT(finalType == TYPE_INTEGER);
	    if (floatVal > 32767 || floatVal < -32768) {
		*ec = RTE_OVERFLOW;
		return OURT_HANDLE_RTE_ERR;
	    }
#ifdef LIBERTY
	    newVal.LD_long = (sdword) floatVal;
#else
	    newVal.LD_integer = (int) SmartTrunc(floatVal);
#endif
	}
	break;
    }

    case TYPE_INTEGER:
    {
	if (finalType == TYPE_FLOAT) {
	    /* assume integer was stored on stack as long */
	    newVal.LD_float = (float)(sword)valToConvert;
#ifdef EC_DEBUG_SERCOMP
	    if((rms->pc - rms->code) == 25) {
		if(myLog == NULL) {
		    myLog = new Log("arraylog", 37000, WRAP_AT_END);
		    EC(HeapSetTypeAndOwner(myLog, "SXYZ"));
		    Result r = myLog->Initialize();
		    ASSERT(r == SUCCESS);
		}
		myLog->Write("int to float [%d,%.0f][%d,%.0f][%d,%.0f]\n",*(int*)&valToConvert,newVal.LD_float,*(int*)&valToConvert,newVal.LD_float,*(int*)&valToConvert,newVal.LD_float);
	    }
#endif
	} else {
	    ASSERT(finalType == TYPE_LONG);
	    /* assume integer was stored on stack as long */
	    newVal.LD_long = (sword)valToConvert;
	}
	break;
    }

    default:
	*data = finalType;
	*ec = RTE_TYPE_MISMATCH;
	return OURT_HANDLE_RTE_ERR_DATA;
	/*break;*/
    }

 PUSH_IT:
    PopValVoid();
    PushTypeData(finalType, newVal.LD_gen_dword);
    return OURT_OK;
}

/*********************************************************************
 *			OpModuleRef -d-
 *********************************************************************
 * SYNOPSIS:	code to deal with module refs
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/ 7/96  	Initial version
 * 
 *********************************************************************/
OpUtilReturnType
OpModuleRef(RMLPtr rms, Opcode op, RuntimeErrorCode *ec, word *data)
{
    RVal        rvModule, rvStr;
    RunTask     *rt;
    TCHAR        *name;
    word    	s_offset;
    byte*	s_varsType;
    dword*	s_varsData;

    PROFILE_START_SECTION(PS_OP_GET_MODULE_REF);
   
#if defined (DEBUG_AID) && defined(EC_LOG)
    theLegosModuleRefVarCount++;
    if (theLegosModuleRefTraceFlag) {
	theLog << "module ref #" << theLegosModuleRefVarCount << '\n';
    }
#endif

    /* get the memhandle for the module */
    if (TopType() != TYPE_MODULE) {
	*data = TYPE_MODULE;
	*ec = RTE_BAD_MODULE;
	return OURT_HANDLE_RTE_ERR_DATA;
    }

    PopVal(rvModule);
    if (rvModule.value == 0)
    {
	*ec = RTE_BAD_MODULE;
	return OURT_HANDLE_RTE_ERR;
    }

    /* now get the string of the module variable */
    PopVal(rvStr);
    ASSERT(rvStr.type == TYPE_STRING);
   
    /* lock down the string name and look and see if it's really
     * exported by the module
     */
    RunHeapLock(rms->rhi, (RunHeapToken) rvStr.value, (void**)(&name));
    rt = RunTaskLock(rvModule.value);

    ASSERT(name != NULL);
    ASSERT(rt->RT_cookie == RTASK_COOKIE);

#ifdef LIBERTY
    s_offset = SSTLookup(rt->RT_exportTable, name,
		       rt->RT_exportTableCount);
#else
    s_offset = SSTLookup(rt->RT_exportTable, name);
#endif

    RunHeapDecRefAndUnlock(rms->rhi, rvStr.value, name);

    if (s_offset == SST_NULL)
    {
	MemUnlock(rvModule.value);
	*ec = RTE_BAD_MODULE_REFERENCE;
	return OURT_HANDLE_RTE_ERR;
    }
   
    /* ok, lets fetch the sucker */
    if (op == OP_MODULE_REF_RV)
    {
	/* its an rval , so just fetch the actual value */
	LOCK_GLOBALS(rt->RT_moduleVars, s_varsType, s_varsData);
	PushType(s_varsType[s_offset]);
	PushData(s_varsData[s_offset]);
	MemUnlock(rt->RT_moduleVars);
	INC_REF_IF_RUN_HEAP_TYPE(TopType(), TopData());
    }
    else
    {
	/* the LV will consist of the global variable handle for the
	 * module, and the offset into the global variables
	 */
	PushData(rt->RT_moduleVars);
	PushData(s_offset);
	PushType(TYPE_MODULE_REF_LV);
    }
    MemUnlock(rvModule.value);

    PROFILE_END_SECTION(PS_OP_GET_MODULE_REF);
    return OURT_OK;
}
