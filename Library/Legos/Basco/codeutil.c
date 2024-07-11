/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		codeutil.c

AUTHOR:		Roy Goldman, Dec 13, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/13/94   	Initial version.

DESCRIPTION:
	Code generation utility functions:

	* Top level initialization routine to get the ball rolling
	      and code generate each function.

	* Code emitting routines

        * Lower level routines for initializing or finishing
	  off code "segments" (huge array elements used for storing
	  the code we generate)

	* Routine to check if the current segment has enough
	  free space, adjusting if necessary.

	$Id: codeutil.c,v 1.1 98/10/13 21:42:36 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "mystdapp.h"
#include "bascoint.h"
#include <tree.h>
#include <Legos/opcode.h>
#include <Legos/bug.h>

#include "codegen.h"
#include "codeint.h"
#include "ftab.h"
#include "label.h"
#include "stable.h"
#include "vars.h"

/* Need to grab LineData struct out of labelint.h. */
#include "labelint.h"

static Label
CG_LookupLabel(TaskPtr task, word id, NamedLabel* retEntry);

static Node
FindCommonAncestor(TaskPtr task, Node n1, Node n2);

/*********************************************************************
 *			CodeGenAddFunction
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 3/22/95	Initial version			     
 * 
 *********************************************************************/
Boolean
CodeGenAddFunction(TaskPtr task, int	funcNumber)
{
    FTabEntry*	ftab;

    /* Do some housekeeping to set up allocation space
       to store this puppy in memory.  Typically,
       we will store one function per huge array element,
       (or "segment" in my abstraction).  Support
       for functions whose code is larger than 4K is also supported.
       It is handled entirely behind the scenes in most cases.
       
       However, there exists support for optimizations, mainly
       avoiding breaking a looping construct across segments.
     */
	   
    /* Number of current function */
    task->funcNumber = funcNumber;

    /* Absolute size of current routine */
    task->ip = 0;

	
    /* Get a new segment. Weirdness: in this case only,
       make sure this call happens
       after setting task->ip to 0*/

    /* FIXME: If we already had generated code for this routine
       around somewhere, it becomes garbage at this point
       because we lose track of it within the codeBlock. the code
       allocation mechanism wasn't designed to support a free list
       and handle deleted blocks, though it should..

       Anyway, it's not the end of the world, because it's not
       lost forever. When we delete the codeBlock we'll get rid
       of this too.

    */
    
    CodeGenNewSegment(task);

    /* Store it in our function table */

    ftab = FTabLock(task->funcTable, funcNumber);
    EC_BOUNDS(ftab);
    ftab->startSeg = task->curSeg;
    ftab->size     = 1;

    /* And get the parse tree while we're at it */
    task->tree = ftab->tree;

    if (LabelInitHeap(task) == FALSE)
    {
	if (task->segPtr != NULL) {
	    CodeSegUnlock(task->segPtr);
	}
	return FALSE;
    }

    if (CodeGenRoutine(task) == FALSE)
    {
	if (task->segPtr != NULL) {
	    CodeSegUnlock(task->segPtr);
	}
	FTabDirty(ftab);
	FTabUnlock(ftab);
	return FALSE;
    }

    /* This does a ton of stuff to finish off a segment*/
    CodeGenFinishSegment(task);

    /* Perform label fixups; store the offset/range of the labels
     * we're adding to the hugearray.
     * FIXME: delete the old range and fix up other offsets!
     */
    ftab->labelOffset = HugeArrayGetCount(task->vmHandle,
					  task->hugeLineArray);
    if (LabelDoLocalFixups(task) == FALSE)
    {
	FTabResetLabelEntries(task);
	LabelDestroyHeap(task);
	FTabUnlock(ftab);
	return FALSE;
    }

    ftab->labelSize = HugeArrayGetCount(task->vmHandle, task->hugeLineArray) -
	ftab->labelOffset;
    FTabResetLabelEntries(task);
    LabelDestroyHeap(task);

    if (task->bugHandle != NULL)
    {
    	FuncLabelInfo	*fli;
	BugInfoHeader	*b;

	b = MemLock(task->bugHandle);
	fli = (FuncLabelInfo *)MemLock(b->BIH_funcLabelTable);
	fli += funcNumber;
	fli->FLI_labelOffset = ftab->labelOffset;
	fli->FLI_labelSize   = ftab->labelSize;
	MemUnlock(b->BIH_funcLabelTable);
	MemUnlock(task->bugHandle);
    }

    ftab->compStatus = CS_CODE_GENERATED;
    /* 5/22/96 dubois
     * After codegen, don't think we need that tree no more */
    HugeTreeDestroy(task->vmHandle, ftab->tree);
    task->tree = ftab->tree = NullHandle;
    FTabUnlock(ftab);

    return TRUE;
}

/*********************************************************************
 *			CodeGenEmitNoOp
 *********************************************************************
 * SYNOPSIS:	emit a no-op for non-optimized case
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	5/ 6/96  	Initial version
 * 
 *********************************************************************/
Boolean
CodeGenEmitNoOp(TaskPtr	task, Node node, Boolean force)
{
    if (!(task->flags & COMPILE_OPTIMIZE) || force)
    {
	Token	*t;
	int 	ln;

	t = CurTree_LOCK(node);
	ln = t->lineNum;
	HugeTreeUnlock(t);
	if (ln != -1)
	{
	    /* create something to break at while debugging */
	    CHECK(CodeGenLineBegin(task, ln));
	    CHECK(CodeGenEmitByte(task, OP_NO_OP));
	}
	else if (force)
	{
	    CHECK(CodeGenEmitByte(task, OP_NO_OP));
	}
    }
    return TRUE;
}

/*********************************************************************
 *			CodeGenDim
 *********************************************************************
 * SYNOPSIS:	generate code for a DIM statement
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	    spit out all the dimension info from the VTab entry
 *	    	    the bytes we spit out are
 *
 *		Arrays:
 *			OP_DIM | OP_DIM_PRESERVE
 *			VAR_MODULE or VAR_LOCAL
 *			word offset for variable in scope
 *			number of dimensions (byte)
 *			TYPE byte for element type
 *			[if TYPE_STRUCT then 1 byte of struct info]
 *
 *		Structs:
 *			OP_DIM_STRUCT
 *			VAR_MODULE or VAR_LOCAL
 *			word offset for variable in scope
 *			1 byte of struct info
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/ 4/95	Initial version			     
 * 
 *********************************************************************/
Boolean
CodeGenDim(TaskPtr task, Node node)
{
    VTabEntry	vte;
    dword	varkey;
    Token*	token;		/* Used for random HugeTreeLocks */
    word	ln;

    token = CurTree_LOCK(CurTree_GET_NTH(node, ARRAY_IDENT_NODE));
    varkey = token->data.key;
    ln = token->lineNum;
    VarGetVTabEntry(task, task->funcNumber, token->data.key, &vte);
    HugeTreeUnlock(token);

    /* If array or structure, emit code; otherwise bail
     */
    if (vte.VTE_type & TYPE_ARRAY_FLAG)
    {
	byte	numDims, i;
	Opcode	dimCode = OP_DIM;
	LegosType outputType;

	CHECK(CodeGenLineBegin(task, ln));
	outputType = vte.VTE_type & ~TYPE_ARRAY_FLAG;


	;{			/* preserve */
	    token = CurTree_LOCK(CurTree_GET_NTH(node, ARRAY_PRESERVE_NODE));
	    if (token->data.integer) {
		dimCode = OP_DIM_PRESERVE;
	    }
	    HugeTreeUnlock(token);
	}

	;{			/* numDims */
	    token = CurTree_LOCK(CurTree_GET_NTH(node, ARRAY_NUM_DIMS_NODE));
	    numDims = token->data.integer;
	    HugeTreeUnlock(token);
	}
	EC_ERROR_IF(numDims == 0, -1);

	/* Generate code for the expressions.
	 */
	for (i = ARRAY_DIMS_START_NODE; 
	     i < numDims + ARRAY_DIMS_START_NODE; i++)
	{
	    CHECK(CodeGenExpr(task, CurTree_GET_NTH(node, i)));
	}

	/* Now spit out the DIM statement, var info, # dims, type
	 */
	CHECK(CodeGenCheckFreeSpace(task, 7));

	CodeGenEmitByteNoCheck(task, dimCode);
	CodeGenEmitByteNoCheck(task, VAR_KEY_TYPE(varkey));
	if (VAR_KEY_TYPE(varkey) == VAR_MODULE) {
	    LabelCreateGlobalFixup(task, varkey, GRT_MODULE_VAR);
	}
	CodeGenEmitWordNoCheck(task, vte.VTE_offset/VAR_SIZE);
	CodeGenEmitByteNoCheck(task, numDims);
	CodeGenEmitByteNoCheck(task, outputType);
	if (outputType == TYPE_STRUCT) {
	    CodeGenEmitByteNoCheck(task, vte.VTE_extraInfo);
	}
    }
    else if (vte.VTE_type == TYPE_STRUCT)
    {
	CHECK(CodeGenLineBegin(task, ln));
	/* Emit the string table ID of the struct;
	 * at runtime, this ID will reference a table entry
	 * that is used to construct a skeleton structure
	 */
	CHECK(CodeGenCheckFreeSpace(task, 5));
	CodeGenEmitByteNoCheck(task, OP_DIM_STRUCT);
	CodeGenEmitByteNoCheck(task, VAR_KEY_TYPE(varkey));
	if (VAR_KEY_TYPE(varkey) == VAR_MODULE) {
	    LabelCreateGlobalFixup(task, varkey, GRT_MODULE_VAR);
	}
	CodeGenEmitWordNoCheck(task, vte.VTE_offset/VAR_SIZE);
	/* FIXME XXX: add non-fatal error earlier in compile sequence
	 * to detect "too many struct decls"
	 */
	EC_ERROR_IF(vte.VTE_extraInfo > 0xff, BE_FAILED_ASSERTION);
	CodeGenEmitByteNoCheck(task, vte.VTE_extraInfo);
    }
    else
    {
	return CodeGenEmitNoOp(task, node, FALSE);
    }
    return TRUE;
}

    /* This is Paul's cool idea. This is a great place to put garbage
     * indicators. When a called frame exits, it checks these bytes to
     * see which local variables are "garbage" requiring special
     * attention.

     * For now, I'm going with a very simple, fast scheme.  The first
     * byte says how many garbage variables there are.  What follows
     * are the indices of each such variable (a byte value 0-255).

     * Hence if for a given routine there are 4 garbage variables,
     * variables 0, 2, 6, and 7, then the byte stream would look like
       
           4 0 2 6 7.

     * If code size becomes a concern, a packing scheme could be used
     * such as using each bit in a byte representing garbage/non
     * garbage.  This scheme would require numLocals/8 + 1 bytes.  So
     * for the above example, if there were 8 local variables, we
     * could use 2 bytes. The first would be a 1, to indicate there
     * are 8 bytes.  The second byte would be

              11000101

	 bits 76543210 
       
     * and then use some masking to do the right thing.  Like I said,
     * I'm going with the simpler approach right now.
     */

/*********************************************************************
 *			CodeGenRoutine
 *********************************************************************
 * SYNOPSIS:	Recursively generate code for the given function
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Tree looks like:
 *
 *	FUNCTION or PROCEDURE
 *	 # parameters to pass
 *	 type bytes
 *	 return type, if function
 *	 NULLCODE (body resides here)
 *	 END
 *
 *	Functions have an extra param (#0) for the return value
 *
 *	 OP_START_??		
 *	  byte(# params) byte(total # locals) N bytes(types of locals)
 *	 OP_EHAN_PUSH		if error-trapping is enabled
 *
 *	 [body of routine]
 *
 *  <endRoutineLabel>:
 *	 OP_EHAN_POP		if error-trapping is enabled
 *	 OP_END_??
 *	  byte(total # locals) byte(# GC vars) N bytes(GC var indices)
 *
 *  <resumeNextLabel>:
 *	 OP_RESUME (next)	if ONERROR RESUME NEXT was found
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/14/94	Initial version
 * 
 *********************************************************************/
Boolean
CodeGenRoutine(TaskPtr task) 
{
    Node	n;
    Token	*nPtr, *endptr;
    byte	numParams;	/* Includes "hidden" func return value */
    byte	i, numLocals;
    word	vtab;
    Opcode	op;
    word	ln;
    byte        startPoint;
    Boolean	hasErrorTrap, hasResumeNext, ok;

    ;{
	FTabEntry*	ftab;

	ftab = FTabLock(task->funcTable, task->funcNumber);
	vtab = ftab->vtab;
	hasErrorTrap = ftab->hasErrorTrap;
	hasResumeNext = ftab->hasResumeNext;
	FTabUnlock(ftab);
	numLocals = VTGetCount(task->vtabHeap, vtab);
    }

    if (hasErrorTrap) {
	task->flags |= COMPILE_HAS_ERROR_TRAP;
    }

    task->endRoutineLabel = LabelCreateTarget(task);
    task->resumeNextLabel = LabelCreateTarget(task);

    /*- 1. Generate OP_START_?? opcode and its arguments
     */
    nPtr = HugeTreeLock(task->vmHandle, task->tree, 0);
    op = (nPtr->code == FUNCTION) ? OP_START_FUNCTION : OP_START_PROCEDURE;
    HugeTreeUnlock(nPtr);

    CHECK(CodeGenCheckFreeSpace(task, 3 + numLocals + 
				(task->flags & COMPILE_OPTIMIZE) ? 1 : 0));

    CodeGenEmitByteNoCheck(task, op);
   
    /* byte(numParams)
     */
    n = HugeTreeGetNthChild(task->vmHandle, task->tree,0, 0);
    nPtr = HugeTreeLock(task->vmHandle, task->tree, n);
    numParams = nPtr->data.integer;
    ln = nPtr->lineNum;
    if (op == OP_START_FUNCTION) numParams += 1;
    HugeTreeUnlock(nPtr);
    CodeGenEmitByteNoCheck(task, numParams);
    
    /* byte(numLocals) and their types
     */
    CodeGenEmitByteNoCheck(task, numLocals);
    for (i = 0; i < numLocals; i++)
    {
	VTabEntry	vte;

	VTLookupIndex(task->vtabHeap, vtab, i, &vte);
	/* if its an array, spit out more info */
	if (vte.VTE_type & TYPE_ARRAY_FLAG) {
	    CodeGenEmitByteNoCheck(task, TYPE_ARRAY);
	} else	{
	    CodeGenEmitByteNoCheck(task, vte.VTE_type);
	}
    }

    if (!(task->flags & COMPILE_OPTIMIZE))
    {
	/* emit a label and NO_OP for setting breakpoints at */
	LabelCreateLine(task, ln);
	/* Don't put an OP_LINE_BEGIN in before the OP_EHAN_PUSH!
	 * It will dork cached rms.line_vpc and rms.line_vbp before
	 * OP_EHAN_PUSH has a chance to save them for previous
	 * error handler
	 */
	CodeGenEmitByteNoCheck(task, OP_NO_OP);
    }

    /*- 2. Generate code for the body.
     * numParams has already been adjusted if this is a function.
     */
    n = CurTree_GET_NTH(0, numParams+1);
#if ERROR_CHECK
    ;{
	Token*	t;
	t = CurTree_LOCK(n);
	EC_ERROR_IF(t->code != NULLCODE, BE_FAILED_ASSERTION);
	HugeTreeUnlock(t);
    }
#endif
	  
    /* Codegen body
     */
    ok = TRUE;
    if (hasErrorTrap)	ok &= CodeGenEmitByte(task, OP_EHAN_PUSH);
    ok &= CodeGenBlockOfCode(task, n, NULL_LABEL, NULL_LABEL);

    if (!ok) return FALSE;

    /*- 3. OP_END_?? and its arguments
     */
{
    word    ln;

    /* Line number */
    endptr = CurTree_LOCK(CurTree_GET_NTH(TREE_ROOT, numParams+2));
    ln = endptr->lineNum;
    HugeTreeUnlock(endptr);

    LabelSetOffset(task, task->endRoutineLabel);
    CHECK(CodeGenLineBegin(task, ln));
}
    if (hasErrorTrap) {
	CHECK(CodeGenEmitByte(task, OP_EHAN_POP));
    }

    if (vtab == GLOBAL_VTAB) {
	CHECK(CodeGenCheckFreeSpace(task, 3));
    } else {
	/* not totally optimal, but close enough */
	CHECK(CodeGenCheckFreeSpace(task, 3 + numLocals * 2));
    }
    if (op == OP_START_FUNCTION) {
	CodeGenEmitByteNoCheck(task, OP_END_FUNCTION);
    } else {
	CodeGenEmitByteNoCheck(task, OP_END_PROCEDURE);
    }

    /* Emit: byte(# locals) for help unrolling the stack
     */
    CodeGenEmitByteNoCheck(task, numLocals);

    startPoint = 0;
    if (op == OP_START_FUNCTION) {
	startPoint++;
    }
    CodeGenEndRoutine(task, vtab, startPoint, numParams);

    /* Maybe emit OP_RESUME (next) */
    if (hasResumeNext) {
	LabelSetOffset(task, task->resumeNextLabel);
	CHECK(CodeGenCheckFreeSpace(task, 3));
	CodeGenEmitByteNoCheck(task, OP_EHAN_RESUME);
	CodeGenEmitWordNoCheck(task, 0xffff);
    }
    task->flags &= ~COMPILE_HAS_ERROR_TRAP;
    return TRUE;
}

/*********************************************************************
 *			CodeGenEndRoutine
 *********************************************************************
 * SYNOPSIS:	Generate arguments to OP_END_PROC|FUNC opcode
 * CALLED BY:	CodeGenRoutine
 * RETURN:	TRUE if successful
 * SIDE EFFECTS:
 * STRATEGY:
 *	So I don't have to loop through vars twice, grab a ton of
 *	stack space.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/13/95	Initial version
 * 
 *********************************************************************/
void
CodeGenEndRoutine(TaskPtr task, word vtab, word firstLocal, word numParams)
{
    VTabEntry	vte;
    byte	i, numGarbage;
    word	numVars;

    if (vtab == GLOBAL_VTAB)
    {
	/* Don't perform any cleanups for decl routines
	 * (or any routines who work in the global scope)
	 */
	CodeGenEmitByteNoCheck(task, 0);
	return;
    }

    numVars = VTGetCount(task->vtabHeap, vtab);
    EC_ERROR_IF(numVars > 255, BE_FAILED_ASSERTION);

    /* Skip the first param, we don't want to dec that ref count
     * because it is being returned on the stack.
     *  
     * Right now, collect:
     *  TYPE_NONE (could have passed in anything!)
     *	Arrays (only local variable arrays, not parameters)
     *	Structs
     *	Strings
     *	Complex
     *	Components that aren't a specific component type
     *	  (because they might be aggregates, ie. structs)
     */
    for (numGarbage=0, i=firstLocal; i<numVars; i++)
    {
	VTLookupIndex(task->vtabHeap, vtab, i, &vte);
	if ( (vte.VTE_type & TYPE_ARRAY_FLAG) && i < numParams) {
	    continue;
	}
	/* if you change this, remember to modify OP_END_PROCEDURE! */
	if ((vte.VTE_type & TYPE_ARRAY_FLAG) ||
	    vte.VTE_type == TYPE_NONE	||
	    vte.VTE_type == TYPE_STRUCT ||
	    vte.VTE_type == TYPE_STRING ||
	    (vte.VTE_type == TYPE_COMPONENT && vte.VTE_extraInfo == 0xffff) ||
	    vte.VTE_type == TYPE_COMPLEX)
	{
	    numGarbage++;
	}
    }

    CodeGenEmitByteNoCheck(task, numGarbage);

    for (i=firstLocal; i<numVars; i++)
    {
	VTLookupIndex(task->vtabHeap, vtab, i, &vte);
	if ( (vte.VTE_type & TYPE_ARRAY_FLAG) && i < numParams) {
	    continue;
	}
	/* if you change this, remember to modify OP_END_PROCEDURE! */
	if ((vte.VTE_type & TYPE_ARRAY_FLAG) ||
	    vte.VTE_type == TYPE_STRUCT ||
	    vte.VTE_type == TYPE_STRING ||
	    (vte.VTE_type == TYPE_COMPONENT && vte.VTE_extraInfo == 0xffff) ||
	    vte.VTE_type == TYPE_COMPLEX)
	{
	    CodeGenEmitWordNoCheck(task, vte.VTE_offset/VAR_SIZE);
	}
	else if (vte.VTE_type == TYPE_NONE)
	{
	    CodeGenEmitWordNoCheck(task, (vte.VTE_offset/VAR_SIZE) | VARIANT_PARAM);
	}
    }

    return;
}

/*********************************************************************
 *			CodeGenLabel
 *********************************************************************
 * SYNOPSIS:	code generation for labels
 * CALLED BY:	CodeGenBlockOfCode
 * RETURN:  	FALSE if problems
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 1/95	Initial version
 * 
 *********************************************************************/
Boolean
CodeGenLabel(TaskPtr task, Node curNode)
{
    Label   	label;
    Token   	*t;

    t = HugeTreeLock(task->vmHandle, task->tree, curNode);
    label = CG_LookupLabel(task, t->data.key, NULL);
    HugeTreeUnlock(t);
    LabelSetOffset(task, label);
    return (!ERROR_SET);
}

/*********************************************************************
 *			CodeGenOnError
 *********************************************************************
 * SYNOPSIS:	Generate code for ONERROR statements
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/29/95	Initial version
 * 
 *********************************************************************/
Boolean
CodeGenOnError(TaskPtr task, Node node)
{
    Label	label;
    dword	ident;
    Token*	t;

    t = CurTree_LOCK(node);
    ident = t->data.key;
    HugeTreeUnlock(t);

    /* Fetch/create the named label, unless there is no name
     * associated with the ONERROR (ie, ONERROR GOTO 0)
     */
    CHECK(CodeGenCheckFreeSpace(task, 3));
    CodeGenEmitByteNoCheck(task, OP_EHAN_MODIFY);

    switch (ident)
    {
    case KEY_GOTO_ZERO:
	/* Don't emit a label for ONERROR GOTO 0 */
	CodeGenEmitWordNoCheck(task, 0);
	break;

    case KEY_RESUME_NEXT:
	LabelCreateFixup(task, FT_LABEL, task->resumeNextLabel);
	CodeGenEmitLabelNoCheck(task, task->resumeNextLabel);
	break;

    default:
    {
	NamedLabel	entry;
	label = CG_LookupLabel(task, ident, &entry);
	if (ERROR_SET) return FALSE;

	/* Target must be within NO FOR/SELECT blocks,
	 * so use root as ancestor */
	if (!CG_CheckTarget(task, entry.node, TREE_ROOT)) {
	    SetError(task, E_EHAN_IN_BLOCK);
	    return FALSE;
	}
	LabelCreateFixup(task, FT_LABEL, label);
	CodeGenEmitLabelNoCheck(task, label);
	break;
    }
    }
    return TRUE;
}

/*********************************************************************
 *			CodeGenResume
 *********************************************************************
 * SYNOPSIS:	emit code for resume
 * CALLED BY:	CodeGenBlockOfCode
 * RETURN:	FALSE if unsuccessful
 * SIDE EFFECTS:
 * STRATEGY:
 *	RESUME			OP_RESUME 0x0000
 *	RESUME NEXT		OP_RESUME 0xffff
 *	RESUME <label>		OP_RESUME <target>
 *	  <label> must be at top-level of routine; the runtime pops
 *	  everything off the stack on an OP_RESUME
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/13/96  	Initial version
 * 
 *********************************************************************/
Boolean
CodeGenResume(TaskPtr task, Node node)
{
    Boolean	hasLabel, nextP;
    Label	label;
    Token*	token;
    NamedLabel	entry;

    /* If you change the way resume is generated, change the end
     * of CodeGenRoutine as well; it sometimes produces code for
     * a RESUME NEXT
     */
    hasLabel = nextP = FALSE;
    CHECK(CodeGenCheckFreeSpace(task, 3));

    token = CurTree_LOCK(node);
    nextP = token->data.key;
    HugeTreeUnlock(token);

    if (CurTree_NUM_CHILDREN(node) == 1)
    {
	token = CurTree_LOCK(CurTree_GET_NTH(node, 0));
	ASSERT(token->code == INTERNAL_IDENTIFIER);
	label = CG_LookupLabel(task, token->data.key, &entry);
	hasLabel = TRUE;
	HugeTreeUnlock(token);
	if (ERROR_SET) return FALSE;
    }

    EC_ERROR_IF(nextP && hasLabel, BE_FAILED_ASSERTION);

    CodeGenEmitByteNoCheck(task, OP_EHAN_RESUME);
    if (hasLabel) {
	if (!CG_CheckTarget(task, entry.node, TREE_ROOT)) {
	    SetError(task, E_RESUME_INTO_BLOCK);
	    return FALSE;
	}
#if 0
	/* Explicit cleanups not needed; runtime will perform them */
	if (!CG_EmitCleanup(task, node, &ancestor, NULLCODE /* ignored */)) {
	    SetError(task, E_INTERNAL);
	    return FALSE;
	}
#endif
	LabelCreateFixup(task, FT_LABEL, label);
	CodeGenEmitLabelNoCheck(task, label);
    } else if (nextP) {
	CodeGenEmitWordNoCheck(task, 0xffff);
    } else {
	CodeGenEmitWordNoCheck(task, 0x0000);
    }
    return TRUE;
}

/*********************************************************************
 *			CodeGenGoto
 *********************************************************************
 * SYNOPSIS:	emit code for a goto
 * CALLED BY:	CodeGenBlockOfCode
 * RETURN:  	FALSE if problems
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 1/95	Initial version
 * 
 *********************************************************************/
Boolean
CodeGenGoto(TaskPtr task, Node curNode)
{
    Token   	*token;
    NamedLabel	entry;
    word	labelName;
    Node	ancestor;

    token = HugeTreeLock(task->vmHandle, task->tree, curNode);
    labelName = token->data.key;
    HugeTreeUnlock(token);

    (void) CG_LookupLabel(task, labelName, &entry);
    if (ERROR_SET) return FALSE;

    /* Don't allow jumping into FOR or SELECT blocks */
    ancestor = FindCommonAncestor(task, curNode, entry.node);
    if (!CG_CheckTarget(task, entry.node, ancestor)) {
	SetError(task, E_JUMPING_INTO_BLOCK);
	return FALSE;
    }
    
    /* Emit cleanup code if jumping out of blocks */
    if (!CG_EmitCleanup(task, curNode, &ancestor, NULLCODE /* ignored */)) {
	SetError(task, E_INTERNAL);
	return FALSE;
    }
    
    LabelCreateFixup(task, FT_JUMP, entry.label);
    CHECK(CodeGenCheckFreeSpace(task, 3));
    CodeGenEmitByteNoCheck(task, OP_JMP);
    CodeGenEmitLabelNoCheck(task, entry.label);
    return TRUE;
}

/*********************************************************************
 *			CodeGenBlockOfCode
 *********************************************************************
 * SYNOPSIS:	Top level code generation switch/case statement,
 *              called recursively.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/14/94		Initial version			     
 * 
 *********************************************************************/
Boolean
CodeGenBlockOfCode(TaskPtr task, Node node, Label forExitLabel,
		   Label doExitLabel)
{

    Token *t;
    TokenCode code;
    int i,num, ln;
    Boolean 	emit = TRUE;
    Node curNode;

    num = HugeTreeGetNumChildren(task->vmHandle, task->tree, node);

    for (i = 0; i < num; i++) {
	curNode = HugeTreeGetNthChild(task->vmHandle, task->tree,node,i);

	t = HugeTreeLock(task->vmHandle, task->tree, curNode);
	code = t->code;
	ln = t->lineNum;
	HugeTreeUnlock(t);

	switch(code)
	{
	case EXPORT:
	case STRUCTDECL:
	    /* No code generated for these */
	    break;
	case IF:
	case IF_DOWHILE:
	case IF_LOOPUNTIL:
	    /* LineBegin generated by CodeGenIf */
	    LabelCreateLine(task, ln);
	    emit = CodeGenIf(task, curNode, forExitLabel, doExitLabel);
	    break;

	case FOR:
	    LabelCreateLine(task, ln);
	    /* LineBegin generated by CodeGenFor */
	    emit &= CodeGenFor(task, curNode, doExitLabel);
	    break;

	case DEBUG:
	    emit = CodeGenLineBegin(task, ln);
	    emit &= CodeGenEmitByte(task, TTOC(DEBUG));
	    break;

	case DO:
	    /* This might be optimized out? */
	    /* LineBegin generated by CodeGenDo */
	    emit = CodeGenDo(task, curNode, forExitLabel);
	    break;
		
	case EXIT:
	    emit = CodeGenLineBegin(task, ln);
	    emit &= CodeGenExit(task, curNode, forExitLabel, doExitLabel);
	    break;

	case SELECT:
	    LabelCreateLine(task, ln);
	    /* LineBegin generated by CodeGenSelect */
	    emit = CodeGenSelect(task, curNode, forExitLabel, doExitLabel);
	    break;

	case DIM:
	case REDIM:
	    emit = CodeGenDim(task, curNode);
	    break;
	    
	case COMP_INIT:
	    /* LineBegin generated by CodeGenCompInit */
	    emit = CodeGenCompInit(task, curNode, ln);
	    break;

	case LABEL:
	    emit = CodeGenLabel(task, curNode);
	    break;

	case ONERROR:
	    emit = CodeGenLineBegin(task, ln);
	    emit &= CodeGenOnError(task, curNode);
	    break;

	case RESUME:
	    emit = CodeGenLineBegin(task, ln);
	    if (task->flags & COMPILE_HAS_ERROR_TRAP) {
		emit = CodeGenResume(task, curNode);
	    } else {
		SetError(task, E_NO_EHAN);
		emit = FALSE;
	    }
	    break;

	case TOKEN_GOTO:
	    emit = CodeGenLineBegin(task, ln);
	    emit &= CodeGenGoto(task, curNode);
	    break;

	default:
	    emit = CodeGenLineBegin(task, ln);
	    emit &= CodeGenExpr(task, curNode);
	}
	if (emit == FALSE)
	{
	    return FALSE;
	}
    }

    return TRUE;
}

/*********************************************************************
 *			CodeGenNewSegment
 *********************************************************************
 * SYNOPSIS:	Set up a new code segment and set up task to be ready 
 *              to emit code to it.
 *              Assumes old segment (if it exists) has already
 *              been taken care of.
 *
 * CALLED BY:	Three places:
 *               CodeGenAllFunctions: once for each function for
 *                                    initial storage
 *               CodeGenEmit{Byte,Word,Dword,Var}: if necessary
 *                                     to break up function across segs.
 *
 *               CodeGenCheckFreeSpace: For certain optimizations,
 *                                      use this call to see in advance
 *                                      if the current segment has
 *                                      enough free space. If not,
 *                                      it will call here to create a new
 *                                      segment.
 *
 * 
 * 
 * RETURN:      New segment number in task->curseg.
 *              Resets instruction pointer for current segment to 0.
 *              Locks down the new segment so you can access it directly
 *              with segPtr.
 *
 *              Remember a segment has a max size of 4096 bytes.
 *
 *              Adds one to the function table's notion of how
 *              many segments are used for the current function.
 *
 * SIDE EFFECTS:  Modifies some task slots.
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
void CodeGenNewSegment(TaskPtr task) 
{
    FTabEntry *ftab;
    word size;


    task->segIp  = 0;

#if ERROR_CHECK
{    
    word oldseg;
    oldseg = task->curSeg;
    task->curSeg = CodeSegAlloc(task->vmHandle, task->codeBlock);
    if (task->ip != 0 && task->curSeg != oldseg + 1) EC_ERROR(-1);
}
#else
    task->curSeg = CodeSegAlloc(task->vmHandle, task->codeBlock);
#endif

    task->segPtr = CodeSegLock(task->vmHandle,
			       task->codeBlock,
			       task->curSeg,&size);

    /* Update function table, letting it know that this
       function has one more segment */

    ftab = FTabLock(task->funcTable, task->funcNumber);
    ftab->size ++;
    FTabDirty(ftab);
    FTabUnlock(ftab);
}
    

/*********************************************************************
 *			CodeGenFinishSegment
 *********************************************************************
 * SYNOPSIS:	Given a task, assume we are finished
 *              writing code to the task's current segment
 *              of the current function.
 *              Set the segment to its correct size, and update
 *              the function table.
 * CALLED BY:	Exact three places mentioned above in CodeGenNewSegment,
 *              called right before creating a new segment or for finishing
 *              off the last segment.
 * RETURN:
 * SIDE EFFECTS: Modifies some task slots.
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
void CodeGenFinishSegment(TaskPtr task) 
{

    /* Set current segment to its actual size */

    CodeSegDirty(task->segPtr);
    CodeSegUnlock(task->segPtr);
    task->segPtr = NULL;

    if (task->segIp != 0)
    {
	CodeSegContract(task->vmHandle, task->codeBlock,
			task->curSeg,
			task->segIp);
    }
}



/*********************************************************************
 *			CodeGenEmitByteNoCheck
 *********************************************************************
 * SYNOPSIS:	force out a byte, ignoring the space limitations
 * CALLED BY:	CheckFreeSpace
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	1/ 3/96	Initial version
 * 
 *********************************************************************/
void
CodeGenEmitByteNoCheck(TaskPtr task, byte data)
{
    if (!(task->flags&COMPILE_CODE_GEN_ON)) {
	task->codeSize+= 1;
	return;
    }

    EC_BOUNDS(task->segPtr + task->segIp);
    task->segPtr[task->segIp] = data;
    task->segIp++;
    task->ip++;
}


/*********************************************************************
 *			CodeGenEmitWordNoCheck
 *********************************************************************
 * SYNOPSIS:	force out a word, ignoring the space limitations
 * CALLED BY:	CheckFreeSpace
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	1/ 3/96	Initial version
 * 
 *********************************************************************/
void
CodeGenEmitWordNoCheck(TaskPtr task, word data)
{
    if (!(task->flags&COMPILE_CODE_GEN_ON)) {
	task->codeSize+= 1;
	return;
    }
    EC_BOUNDS(task->segPtr + task->segIp);
    memcpy(task->segPtr + task->segIp, &data, 2);
    if (BIG_ENDIAN) {
	swapWord((word*)(task->segPtr + task->segIp));
    }
    
    task->segIp += 2;
    task->ip += 2;
}

/*********************************************************************
 *			CodeGenEmitDwordNoCheck
 *********************************************************************
 * SYNOPSIS:	force out a dword, ignoring the space limitations
 * CALLED BY:	CheckFreeSpace
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	1/ 3/96	Initial version
 * 
 *********************************************************************/
void
CodeGenEmitDwordNoCheck(TaskPtr task, dword data)
{
    if (!(task->flags&COMPILE_CODE_GEN_ON)) {
	task->codeSize+= 1;
	return;
    }

    EC_BOUNDS(task->segPtr + task->segIp);
    memcpy(task->segPtr + task->segIp, &data, 4);
    if (BIG_ENDIAN) {
	swapDword((dword*)(task->segPtr + task->segIp));
    }

    task->segIp += 4;
    task->ip += 4;
}


/*********************************************************************
 *			CodeGenEmitByte
 *********************************************************************
 * SYNOPSIS:	Emit one byte of code for current function
 *              , adjusting all instruction
 *              pointers, counters, segments, etc.
 * CALLED BY:	
 * RETURN:      False if there is no more room for this function
 *              (Hit 64K barrier!)
 *
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
Boolean CodeGenEmitByte(TaskPtr task, byte data) 
{

    EC_BOUNDS(task);
    if (!(task->flags&COMPILE_CODE_GEN_ON)) {
	task->codeSize+= 1;
	return TRUE;
    }

    if(!CodeGenCheckFreeSpace(task,1)) {
	return FALSE;
    }

    EC_BOUNDS(task->segPtr + task->segIp);
    task->segPtr[task->segIp] = data;

    task->segIp++;
    task->ip++;
    return TRUE;
}

/*********************************************************************
 *			CodeGenEmitWord
 *********************************************************************
 * SYNOPSIS:	Same as above, just for word
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
Boolean CodeGenEmitWord(TaskPtr task, word data) 
{

    if (!(task->flags&COMPILE_CODE_GEN_ON)) {
	task->codeSize+= 2;
	return TRUE;
    }

    if(!CodeGenCheckFreeSpace(task,2)) {
	return FALSE;
    }


    EC_BOUNDS(task->segPtr + task->segIp);
    memcpy(task->segPtr + task->segIp, &data, 2);
    if (BIG_ENDIAN) {
	swapWord((word*)(task->segPtr + task->segIp));
    }
    
    task->segIp += 2;
    task->ip += 2;

    return TRUE;
}

/*********************************************************************
 *			CodeGenEmitLabel
 *********************************************************************
 * SYNOPSIS:	Emits a word, not byte-swapped so the linker doesn't
 *		get confused.
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 7/24/95	Initial version
 * 
 *********************************************************************/
Boolean
CodeGenEmitLabel(TaskPtr task, Label data)
{

    if (!(task->flags&COMPILE_CODE_GEN_ON)) {
	task->codeSize+= 2;
	return TRUE;
    }

    if(!CodeGenCheckFreeSpace(task,2)) {
	return FALSE;
    }

    EC_BOUNDS(task->segPtr + task->segIp);
    memcpy(task->segPtr + task->segIp, &data, 2);
    
    task->segIp += 2;
    task->ip += 2;

    return TRUE;
}


/*********************************************************************
 *			CodeGenEmitLabelNoCheck
 *********************************************************************
 * SYNOPSIS:	Emits a word, not byte-swapped so the linker doesn't
 *		get confused.
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 7/24/95	Initial version
 * 
 *********************************************************************/
void
CodeGenEmitLabelNoCheck(TaskPtr task, Label data)
{
    if (!(task->flags&COMPILE_CODE_GEN_ON)) {
	task->codeSize+= 2;
	return;
    }

    EC_BOUNDS(task->segPtr + task->segIp);
    memcpy(task->segPtr + task->segIp, &data, 2);
    
    task->segIp += 2;
    task->ip += 2;
}


/*********************************************************************
 *			CodeGenEmitDword
 *********************************************************************
 * SYNOPSIS:	Same as above, just for dword
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
Boolean CodeGenEmitDword(TaskPtr task, dword data) 
{
    if (!(task->flags&COMPILE_CODE_GEN_ON)) {
	task->codeSize+= 4;
	return TRUE;
    }

    if(!CodeGenCheckFreeSpace(task,4)) {
	return FALSE;
    }

    EC_BOUNDS(task->segPtr + task->segIp);
    memcpy(task->segPtr + task->segIp, &data, 4);
    if (BIG_ENDIAN) {
	swapDword((dword*)(task->segPtr + task->segIp));
    }

    task->segIp += 4;
    task->ip += 4;
    return TRUE;

}    
    
/*********************************************************************
 *			CodeGenEmitVar
 *********************************************************************
 * SYNOPSIS:	Same as above, but takes a pointer and emits
 *              a variable length of code.
 *
 *              NOTE: This variable length should still be relatively
 *              "small," since each node should emit a small
 *              amount of data..
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
Boolean CodeGenEmitVar(TaskPtr task, byte *adr, word len) {
    word i;
    
    /* If we have enough room in the current segment for all of it,
       go for it... */

    if (!(task->flags&COMPILE_CODE_GEN_ON)) {
	task->codeSize+= len;
	return TRUE;
    }

    if (CodeGenEnoughRoom(task, len)) {
	EC_BOUNDS(task->segPtr + task->segIp);
	EC_BOUNDS(task->segPtr + task->segIp + len - 1);
	memcpy(task->segPtr + task->segIp, adr, len);
	task->segIp += len;
	task->ip += len;
    }

    else {
	/* Else emit this puppy byte by byte */

	for (i = 0; i < len; i++) {
	    if(!CodeGenEmitByte(task, adr[i]))
		return FALSE;
	}
    }

    return TRUE;
}

/*********************************************************************
 *			CodeGenCheckFreeSpace
 *********************************************************************
 * SYNOPSIS:	Check the current segment, seeing if there is still
 *              enough free space in the current segment.
 *              If not, and we haven't used up all available segments
 *              for this function (16), then set up the task
 *              for the next one and return true.
 *
 *              If we are Full Full, return False. 
 *
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
Boolean CodeGenCheckFreeSpace(TaskPtr task, word len) 
{
    FTabEntry *ftab;
    word ss;
    Label   label;

    if (CodeGenEnoughRoom(task, len)) {
	return TRUE;
    }

    /* See if we haven't run out of segments yet by comparing
       the current segment to this function's starting segment */

    ftab = FTabLock(task->funcTable, task->funcNumber);
    EC_BOUNDS(ftab);

    /* Max sixteen segments per function */

    ss = ftab->startSeg;

    FTabUnlock(ftab);

    /* since there are always at least 3 bytes left we can emit the
     * OP_JMP_SEG.
     */
    label = LabelCreateTarget(task);
    LabelCreateFixup(task, FT_JUMP, label);
    CodeGenEmitByteNoCheck(task, OP_JMP);
    /* jump to the 0 offset of the next segment */
    CodeGenEmitLabelNoCheck(task, label);
#if 0
    CodeGenEmitWordNoCheck(task, (task->curSeg+1-ss)<<12);
#endif
    CodeGenFinishSegment(task);

    /* make sure we aren't exceeding the maximum size of a routine */
    if (task->curSeg - ss == CG_MAXSEGSPERFUNC - 1) 
    {
	SetError(task, E_ROUTINE_TOO_BIG);
	return FALSE;
    }

    CodeGenNewSegment(task);
    LabelSetOffset(task, label);
    return TRUE;
}

/*********************************************************************
 *			CodeGenEnable
 *********************************************************************
 * SYNOPSIS:	Turn code generation on. This should be the
 *              default behavior, and need only be called after
 *              code generation is turned off.
 *
 *              Turn code generation off when you want to do a
 *              code-generating traversal only to find out the SIZE
 *              of the code to be generated, not to actually emit any.
 *
 *              This is here in anticipation of optimizing segment breaks,
 *              such as if checking the amount of code in a looping
 *              construct and then deciding whether or not to push
 *              it to the next segment.
 *
 *              To do this:
 *                 Turn code generation off with CodeGenDisable
 *                 Call code generation code for desired tree
 *                        (These calls will now increment task->codeSize
 *                        instead of emitting code)
 *                 Check task->codeSize for size of the block of code.
 *                 Turn code generation back on with CodeGenEnable
 *
 *
 *
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:  
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/14/94		Initial version			     
 * 
 *********************************************************************/
void CodeGenEnable(TaskPtr task) {
    task->flags |= COMPILE_CODE_GEN_ON;
}

/*********************************************************************
 *			CodeGenDisable
 *********************************************************************
 * SYNOPSIS:	See above, CodeGenEnable
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:    Sets codeSize counter to 0.
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/14/94		Initial version			     
 * 
 *********************************************************************/
void CodeGenDisable(TaskPtr task) {
    task->flags &= ~COMPILE_CODE_GEN_ON;
    task->codeSize = 0;
}

#if ERROR_CHECK
/*********************************************************************
 *			CodeGenCheckIntegrity
 *********************************************************************
 * SYNOPSIS:	After code generation, pass through the function
 *              table to make sure everything is kosher.
 *              
 *              Doesn't really do anything interesting, but
 *              programmer can use swat to examine everything...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/14/94		Initial version			     
 * 
 *********************************************************************/
void CodeGenCheckIntegrity(TaskPtr task) 
{
    FTabEntry*	ftab;
    word	i, j, num, size;
    byte*	code;

    num = FTabGetCount(task->funcTable);

    for (i=0; i < num; i++) 
    {

	ftab = FTabLock(task->funcTable, i);

	for (j = 0; j < ftab->size; j++) {
	    code = CodeSegLock(task->vmHandle, task->codeBlock,
			       ftab->startSeg + j, &size);
	    CodeSegUnlock(code);
	}
	
	FTabUnlock(ftab);
    }

}
#endif


/*********************************************************************
 *			CodeSegAlloc
 *********************************************************************
 * SYNOPSIS:	Allocate a new segment for the current function.
 *              Will ALWAYS succeed--so client has to check
 *              to make sure no max seg/function limit has been passed.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
word CodeSegAlloc(VMFileHandle vmfile, VMBlockHandle block) 
{
    dword count;

    count = HugeArrayGetCount(vmfile, block);

    HugeArrayAppend(vmfile, block, CG_MAXSEGSIZE, NULL);

    return (word) count;
}

/*********************************************************************
 *			CodeSegLock
 *********************************************************************
 * SYNOPSIS:	Return a pointer to the given code segment,
 *              and if size is non-NUL, return size of block in size.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
byte *CodeSegLock(VMFileHandle vmfile, VMBlockHandle block,
		  word seg, word *size) 
{
    
    byte *p;

    HugeArrayLock(vmfile, block, (dword) seg, (void**)&p, size);
    EC_BOUNDS(p);

    return p;
}

/*********************************************************************
 *			CodeSegContract
 *********************************************************************
 * SYNOPSIS:	Cut down a segment to its new size...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
void CodeSegContract(VMFileHandle vmfile,
		     VMBlockHandle block,
		     word seg,
		     word newSize) {

    MemHandle tempHandle;
    byte *tempPtr;
    
    word size;
    byte *p;

    HugeArrayLock(vmfile, block, seg, (void**)&p, &size);

    EC_ERROR_IF (size < newSize, -1);

    tempHandle = MemAlloc(newSize, HF_SWAPABLE, HAF_LOCK);

    tempPtr = MemLock(tempHandle);

    EC_BOUNDS(tempPtr);
    EC_BOUNDS(tempPtr+newSize-1);
    memcpy(tempPtr, p, newSize);

    HugeArrayUnlock(p);

    HugeArrayReplace(vmfile, block, newSize, seg, tempPtr);

    MemFree(tempHandle);
}

/*********************************************************************
 *			CodeGenCompInit
 *********************************************************************
 * SYNOPSIS:	generate code for CompInit statements
 * CALLED BY:	CodeGenBlockOfCode
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	    our node looks like so:
 *	    	    COMP_INIT
 *	    	    	IDENT <comp>
 *	    	    	n of the following
 *	    	    	PROPERTY/BC_PROPERTY <prop key, if BC>
 *			   IDENT<comp>
 *			   CONST_STRING(prop name)
 *	    	    	CONST_<INT|LONG|FLOAT|STRING>
 *	emit:
 *	byte(OP) byte(# props)
 *	  [bit(bcPropP) 7bits(type) word/dword(data) byte/word(prop)]*
 *
 *	prop is emitted after data for runtime efficiency.
 *
 *	If type byte has high bit set then prop is a BC prop (byte),
 *	otherwise it's a normal string property (word).
 *
 *	strings and ints have 1 word of data; floats and longs have 2.
 *	    	    	
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	10/26/95	Initial version
 * 
 *********************************************************************/
Boolean
CodeGenCompInit(TaskPtr task, Node node, int lineNum)
{
    int	    num, i;
    Label	endLabel = NULL_LABEL;


    LabelCreateLine(task, lineNum);

    num = HugeTreeGetNumChildren(task->vmHandle, task->tree, node);
    CHECK(CodeGenLineBeginNext(task, &endLabel));

    /* output code for the component IDENT */

    CHECK(CodeGenExpr(task, CurTree_GET_NTH(node, 0)));

    /* the maximum space we will need is 7 bytes per field, so make
     * sure the whole CompInit operation fits in the current segment
     * this could be totally optimized for space by running through the
     * list twice, but its more bother than its worth -- jimmy
     */
    CHECK(CodeGenCheckFreeSpace(task, 2 + (((num-1)/2)*7)));

    /* when we hit this opcode, the component will be on the stack
     */
    CodeGenEmitByteNoCheck(task, OP_COMP_INIT);

    /* emit the number of properties being initialized */
    CodeGenEmitByteNoCheck(task, (num-1)/2);

    for (i = 1; i < num; i++)
    {
	TokenCode	code;
	Token	*nodePtr;
	dword	data, prop;
	LegosType   lt;
	Node	propNode;

	lineNum++;
	LabelCreateLine(task, lineNum);
	
	propNode = CurTree_GET_NTH(node, i);
	nodePtr = CurTree_LOCK(propNode);
	prop = nodePtr->data.key;
	code = nodePtr->code;
	HugeTreeUnlock(nodePtr);

	if (code == PROPERTY)	/* Grab prop from RH child */
	{
	    TCHAR   *str;

	    nodePtr = CurTree_LOCK(CurTree_GET_NTH(propNode, 1));
	    EC_ERROR_IF(nodePtr->code != CONST_STRING, BE_FAILED_ASSERTION);
	    prop = nodePtr->data.key;
	    HugeTreeUnlock(nodePtr);

	    /* now lets move the string into the string const table and
	     * use the const table key
	     */
	    str = StringTableLock(ID_TABLE, prop);
	    prop = StringTableAdd(CONST_TABLE, str);
	    StringTableUnlock(str);
	    
	}

	/* emit words for word-sized values, dwords otherwise.  this
	 * requires putting in type info but it turns out we need type
	 * info at runtime.
	 */
	i++;
	nodePtr = CurTree_LOCK(CurTree_GET_NTH(node, i));
	data = nodePtr->data.key;
	lt = nodePtr->type;
	HugeTreeUnlock(nodePtr);

	/* Emit type (possibly with high bit set)
	 */

#ifdef USE_COMP_INIT_BYTE_OPTIMIZATION
	/* if its a small integer that fits in a 
	 * single byte, convert it to type BYTE
	 */
	if ((lt == TYPE_INTEGER) &&
	    ((word)data < 256)) {
	    lt = TYPE_BYTE;
	}
#endif
	CodeGenEmitByteNoCheck(task,
			       (code == BC_PROPERTY ? lt|0x80 : lt));

	/* Emit data
	 */
	switch(lt) {
	case TYPE_BYTE:
	    CodeGenEmitByteNoCheck(task, data);
	    break;
	case TYPE_INTEGER:
	case TYPE_STRING:
	    CodeGenEmitWordNoCheck(task, data);
	    break;
	default:
	    CodeGenEmitDwordNoCheck(task, data);
	}

	/* Emit property (word or byte)
	 */
	if (code == BC_PROPERTY) {
	    CodeGenEmitByteNoCheck(task, prop);
	} else {
	    CodeGenEmitWordNoCheck(task, prop);
	}
    }

    if (task->flags & COMPILE_HAS_ERROR_TRAP) {
	LabelSetOffset(task, endLabel);
    } else {
	EC_ERROR_IF(endLabel != NULL_LABEL, BE_FAILED_ASSERTION);
    }

    return TRUE;
}

/*********************************************************************
 *			CodeGenLineBegin
 *********************************************************************
 * SYNOPSIS:	Conditionally generate OP_LINE_BEGIN
 * CALLED BY:	EXTERNAL
 * RETURN:	FALSE if couldn't emit
 * SIDE EFFECTS:
 * STRATEGY:
 *	Only generate if current routine has an error handler
 *	This is not just a space optimization; the runtime cannot
 *	handle OP_LINE_BEGIN in a routine without a handler.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/11/96  	Initial version
 * 
 *********************************************************************/
Boolean
CodeGenLineBegin(TaskPtr task, sword lineNum)
{
    if (lineNum != -1) {
	LabelCreateLine(task, lineNum);
    }
    if (task->flags & COMPILE_HAS_ERROR_TRAP) {
	return CodeGenEmitByte(task, OP_LINE_BEGIN);
    }
    return TRUE;
}

/*********************************************************************
 *			CodeGenLineBeginNext
 *********************************************************************
 * SYNOPSIS:	Conditionally generagte OP_LINE_BEGIN_NEXT
 * CALLED BY:	EXTERNAL
 * RETURN:	FALSE if couldn't emit
 * SIDE EFFECTS:
 * STRATEGY:
 *	Create a label if l == NULL_LABEL; otherwise use *l
 *
 *	Use this if concept of "next line" is non-trivial.
 *	l should be set to the position of the next line.
 *	(example: "next line" of an IF is the matching END IF)
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/17/96  	Initial version
 * 
 *********************************************************************/
Boolean
CodeGenLineBeginNext(TaskPtr task, Label* l)
{
    if (!(task->flags & COMPILE_HAS_ERROR_TRAP)) {
	return TRUE;
    }

    CHECK(CodeGenCheckFreeSpace(task, 3));
    if (*l == NULL_LABEL) {
	*l = LabelCreateTarget(task);
    }
    CodeGenEmitByteNoCheck(task, OP_LINE_BEGIN_NEXT);
    LabelCreateFixup(task, FT_LABEL, *l);
    CodeGenEmitLabelNoCheck(task, *l);
    return TRUE;
}

/*********************************************************************
 *			CG_LookupLabel
 *********************************************************************
 * SYNOPSIS:	Find/create a Label given an ID
 * CALLED BY:	INTERNAL, CodeGen{Goto,Resume}
 * RETURN:	Label; entry if retEntry is non-NULL
 * SIDE EFFECTS:
 *	May create a Label.  Sets error if the ID doesn't correspond
 *	to a NamedLabel.
 *		
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	3/ 7/96  	Initial version
 * 
 *********************************************************************/
static Label
CG_LookupLabel(TaskPtr task, word id, NamedLabel* retEntry)
{
    NamedLabel*	entry;
    Label	label;

    (void)MemLock(task->funcTable);
    entry = FTabGetLabelEntry(task, id);
    if (entry == NULL) {
	label = NULL_LABEL;
	SetError(task, E_UNDEFINED_LABEL);
    } else {
	if (entry->label == NULL_LABEL) {
	    entry->label = LabelCreateTarget(task);
	}
	label = entry->label;
	if (retEntry) *retEntry = *entry;
    }
    MemUnlock(task->funcTable);
    return label;
}

/*********************************************************************
 *			FindCommonAncestor
 *********************************************************************
 * SYNOPSIS:	Find common ancestor of two nodes
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	5/15/96  	Initial version
 * 
 *********************************************************************/
#define TOK_MARK(_tok)				\
  (_tok->lineNum |= 0x8000)

#define TOK_UNMARK(_tok)			\
  (_tok->lineNum &= 0x7fff)
  
#define TOK_ISMARKED(_tok)			\
  (_tok->lineNum & 0x8000)

static Node
FindCommonAncestor(TaskPtr task, Node n1, Node n2)
{
    Token*	tmpTok;
    Node	cursor;
    Node	ancestor = NullNode;

    /* Mark nodes to the root */
    for (cursor=n1; cursor!=NullNode; cursor=CurTree_GET_PARENT(cursor))
    {
	tmpTok = CurTree_LOCK(cursor);
	EC_ERROR_IF(TOK_ISMARKED(tmpTok), BE_FAILED_ASSERTION);
	TOK_MARK(tmpTok);
	HugeTreeDirty(tmpTok);
	HugeTreeUnlock(tmpTok);
    }

    /* Find a marked node */
    for (cursor=n2; cursor!=NullNode; cursor=CurTree_GET_PARENT(cursor))
    {
	tmpTok = CurTree_LOCK(cursor);
	if (TOK_ISMARKED(tmpTok)) {
	    ancestor = cursor;
	    HugeTreeUnlock(tmpTok);
	    break;
	}
	HugeTreeUnlock(tmpTok);
    }

    EC_ERROR_IF(ancestor == NullNode, BE_FAILED_ASSERTION);

    /* Unmark nodes */
    for (cursor=n1; cursor!=NullNode; cursor=CurTree_GET_PARENT(cursor))
    {
	tmpTok = CurTree_LOCK(cursor);
	EC_ERROR_IF(!TOK_ISMARKED(tmpTok), BE_FAILED_ASSERTION);
	TOK_UNMARK(tmpTok);
	HugeTreeDirty(tmpTok);
	HugeTreeUnlock(tmpTok);
    }

    return ancestor;
}

/*********************************************************************
 *			CG_CheckTarget
 *********************************************************************
 * SYNOPSIS:	Check that node isn't within a FOR or SELECT block
 * CALLED BY:	
 * RETURN:	FALSE if within a block
 * SIDE EFFECTS:
 * STRATEGY:
 *	Return FALSE if startNode is within a FOR or SELECT block
 *	contained by stopNode.  This is useful when startNode is
 *	a named label and we are jumping to it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	5/16/96  	Initial version
 * 
 *********************************************************************/
Boolean
CG_CheckTarget(TaskPtr task, Node startNode, Node stopNode)
{
    Node	cursor;
    Token*	token;
    TokenCode	tc;

    for (cursor = startNode; cursor != stopNode;
	 cursor = CurTree_GET_PARENT(cursor))
    {

	ASSERT(cursor != NullNode);
	token = CurTree_LOCK(cursor);
	tc = token->code;
	HugeTreeUnlock(token);
	if (tc == FOR || tc == SELECT) {
	    return FALSE;
	}
    }
    return TRUE;
}





/*********************************************************************
 *			CG_ConvertToIndexVar
 *********************************************************************
 * SYNOPSIS:	convert a variable opcode to an indexed variable opcode
 * CALLED BY:	various codegen routines
 * RETURN:  	new opcode
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/12/96  	Initial version
 * 
 *********************************************************************/
Boolean CG_EmitWordOrByteVar(TaskPtr task, Opcode opcode, dword key)
{
    int	    isGlob = FALSE;
    int	    isByte = TRUE;
    word    offset;

    GlobalRefType   grt = GRT_MODULE_VAR;

    offset = VAR_KEY_OFFSET(key, task->funcNumber);

    if (offset > 255 ) {
	isByte = FALSE;
    }

    CHECK(CodeGenCheckFreeSpace(task, 3-isByte));
    if (isByte) 
    {
	switch (opcode) {
	case OP_LOCAL_VAR_RV:   opcode = OP_LOCAL_VAR_RV_INDEX; break;
	case OP_LOCAL_VAR_RV_REFS: opcode = OP_LOCAL_VAR_RV_INDEX_REFS; break;
	case OP_LOCAL_VAR_LV:   opcode = OP_LOCAL_VAR_LV_INDEX; break;
	case OP_MODULE_VAR_RV:  opcode = OP_MODULE_VAR_RV_INDEX; 
			    isGlob = TRUE; break;
	case OP_MODULE_VAR_RV_REFS: opcode = OP_MODULE_VAR_RV_INDEX_REFS; 
			    isGlob = TRUE; break;
	case OP_MODULE_VAR_LV: opcode = OP_MODULE_VAR_LV_INDEX; 
			    isGlob = TRUE; break;
	case OP_EXP_ASSIGN_L:  opcode = OP_EXP_ASSIGN_L_INDEX; break;
	case OP_EXP_ASSIGN_M:  opcode = OP_EXP_ASSIGN_M_INDEX; 
			    isGlob = TRUE; break;
	default: EC_ERROR(BE_FAILED_ASSERTION);
	}
	
	grt = GRT_MODULE_VAR_INDEX;
    }
	

    CodeGenEmitByteNoCheck(task, opcode);
    if (isGlob) {
	LabelCreateGlobalFixup(task, key, grt);
    }
    if (isByte) {
	CodeGenEmitByteNoCheck(task, offset);
    } else {
	CodeGenEmitWordNoCheck(task, offset);
    }
    
    return TRUE;
}




