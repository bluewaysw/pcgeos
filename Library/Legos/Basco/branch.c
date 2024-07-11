/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		branch.c

AUTHOR:		Roy Goldman, Dec 15, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/15/94   	Initial version.

DESCRIPTION:
	
        Code generation for branches and loops

	$Id: branch.c,v 1.1 98/10/13 21:42:23 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "codeint.h"
#include "codegen.h"
#include "bascoint.h"
#include "label.h"
#include "vars.h"


/*********************************************************************
 *			CodeGenIf
 *********************************************************************
 * SYNOPSIS:	Generate code for if/then/else parse subtrees
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	If this IF is really part of a DO (either the DO WHILE test
 *	at the top, or the LOOP UNTIL test at the bottom), the
 *	"next line" is really the end of the do, not the end of the if;
 *	this IF is really part of the DO structure, not the DO body.
 *
 * --	LINE_BEGIN_NEXT endIfLabel
 *	<test expr>
 *	BEQ elseLabel			'jmp if zero
 *	<then block>
 * --	LINE_BEGIN			'only if there is an else clause
 *	JMP endIfLabel			'only if there is an else clause
 *  elseLabel:
 *	<else block>			'only if there is an else clause
 *  endIfLabel:
 *	
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/15/94		Initial version			     
 * 
 *********************************************************************/
Boolean
CodeGenIf(TaskPtr task, Node node, Label forExitLabel, Label doExitLabel)
{
    TokenCode	tc;
    int		num;
    Label	elseLabel, endIfLabel;

    ;{
	Token*	t = CurTree_LOCK(node);
	tc = t->code;
	HugeTreeUnlock(t);
    }
	
    elseLabel = endIfLabel = NULL_LABEL;
    num = CurTree_NUM_CHILDREN(node);

    if (tc == IF_DOWHILE || tc == IF_LOOPUNTIL) {
	CHECK(CodeGenLineBeginNext(task, &doExitLabel));
    } else {
	CHECK(CodeGenLineBeginNext(task, &endIfLabel));
    }
    CHECK(CodeGenExpr(task, CurTree_GET_NTH(node, 0)));

    /* Don't execute THEN clause if it was false
     */
    CHECK(CodeGenCheckFreeSpace(task, 3));
    elseLabel = LabelCreateTarget(task);
    LabelCreateFixup(task, FT_JUMP, elseLabel);
    CodeGenEmitByteNoCheck(task, OP_BEQ);
    CodeGenEmitLabelNoCheck(task, elseLabel);
    
    CHECK(CodeGenBlockOfCode(task, CurTree_GET_NTH(node, 1),
			     forExitLabel, doExitLabel));

    /* Jump around the ELSE clause if necessary
     */
    if (num == 3)
    {
	if (endIfLabel == NULL_LABEL) {
	    endIfLabel = LabelCreateTarget(task);
	}
	CHECK(CodeGenLineBegin(task, -1));
	CHECK(CodeGenCheckFreeSpace(task, 3));
	LabelCreateFixup(task, FT_JUMP, endIfLabel);
	CodeGenEmitByteNoCheck(task, OP_JMP);
	CodeGenEmitLabelNoCheck(task, endIfLabel);
    }
	
    /* This is the target of elseLabel, either the beginning
     * of else code or the code after an IF/THEN.
     * Generate else code, if there is any
     */
    LabelSetOffset(task, elseLabel);
    if (num == 3) 
    {
	CHECK(CodeGenBlockOfCode(task, CurTree_GET_NTH(node, 2),
				 forExitLabel, doExitLabel));
    }
    if (endIfLabel != NULL_LABEL) {
	LabelSetOffset(task, endIfLabel);
    }

    return TRUE;
}

/*********************************************************************
 *			CodeGenDo
 *********************************************************************
 * SYNOPSIS:	Code generate all kinds of do loops. Gee this is easy.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/16/94		Initial version			     
 * 
 *********************************************************************/
Boolean
CodeGenDo(TaskPtr task, Node node, Label forExitLabel)
{
    Label	jTop, jExit;
    Token*	token;

    jTop  = LabelCreateTarget(task);
    LabelSetOffset(task, jTop);
    jExit = LabelCreateTarget(task);

    /* emit a NO_OP so we can set breakpoints at the do */
    CHECK(CodeGenEmitNoOp(task, node, FALSE));

    /* No need for LineBeginNext; there is no code associated with
     * the DO itself.  The WHILE/UNTIL is handled in CodeGenIf (ick)
     *
     * Actually, no need for LineBegin either; there is NO code
     * associated with a DO.  DO/LOOP just translates to a GOTO at
     * the bottom of the loop...
     */
/*    CHECK(CodeGenLineBegin(task));*/
    CHECK(CodeGenBlockOfCode(task, CurTree_GET_NTH(node, 0),
			     forExitLabel, jExit));

    /* Let's assign the code which jumps to top to the
     * "LOOP" line, which is the final node under our For node.  This
     * may be redundant in LOOP UNTIL cases, because we will spit out
     * the line number right before the UNTIL check.  BUT Paul said
     * redundancies are okay....
     */
    token = HugeTreeLock(task->vmHandle, task->tree,
			 HugeTreeGetNthChild(task->vmHandle, task->tree,
					     node, 1));
    CHECK(CodeGenLineBegin(task, token->lineNum));
    HugeTreeUnlock(token);
    CHECK(CodeGenCheckFreeSpace(task, 3));
    LabelCreateFixup(task, FT_JUMP, jTop);
    CodeGenEmitByteNoCheck(task, OP_JMP);
    CodeGenEmitLabelNoCheck(task, jTop);

    LabelSetOffset(task, jExit);
			     
    return TRUE;
}

/*********************************************************************
 *			CodeGenFor
 *********************************************************************
 * SYNOPSIS:	Generate code for FOR/NEXT loops
 * CALLED BY:	EXTERNAL
 * RETURN:	FALSE if unsuccessful
 * SIDE EFFECTS:
 * STRATEGY:    
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/16/94	Initial version
 *      roy     1/28/95 	rewritten to use OP_FOR/OP_NEXT
 *
 *********************************************************************/
Boolean
CodeGenFor(TaskPtr task, Node node, Label doExitLabel)
{
    Label	jExit;
    Token*	token;
    Node	address, startExpr, endExpr, stepExpr, codeBlock, nextNode;
    Opcode	adrScope;
    LegosType	adrType;
    word	adrIndex, adrKey;
    byte	fastOp;
    byte	allTypesKnown;

/*-	    emit = CodeGenLineBegin(task);*/

    address   = CurTree_GET_NTH(node, 0);
    startExpr = CurTree_GET_NTH(node, 1);
    endExpr   = CurTree_GET_NTH(node, 2);
    stepExpr  = CurTree_GET_NTH(node, 3);
    codeBlock = CurTree_GET_NTH(node, 4);
    nextNode  = CurTree_GET_NTH(node, 5);

    jExit = LabelCreateTarget(task);
    CHECK(CodeGenLineBeginNext(task, &jExit));

    /* We insist that loop variables must be local or module vars
     */
    token = CurTree_LOCK(address);
    EC_ERROR_IF(token->type != TYPE_INTEGER && token->type != TYPE_LONG,
		 BE_FAILED_ASSERTION);
    if (token->code == IDENTIFIER)
    {
	if (VAR_KEY_TYPE(token->data.key) == VAR_LOCAL) {
	    adrScope = OP_LOCAL_VAR_LV;
	}
#if ERROR_CHECK
	else if (VAR_KEY_TYPE(token->data.key != VAR_MODULE)) {
	    EC_ERROR(BE_FAILED_ASSERTION);
	}
#endif
	else {
	    adrScope = OP_MODULE_VAR_LV;
	}

	adrType  = token->type;
	adrKey = token->data.key;
	adrIndex = VAR_KEY_OFFSET(token->data.key, task->funcNumber);
    }
    else
    {
	task->ln = token->lineNum;
	SetError(task, E_BAD_LOOP_VAR);
	HugeTreeUnlock(token);
	return FALSE;
    }
    HugeTreeUnlock(token);


    /* At this point, we are guaranteed that the type of each
       of the four nodes underneath us (address, startExpr, endExpr,
       stepExpr) are ints, longs, or unknown.

       if loop var is int, and other exprs are ints, no checking needed
       if loop var is long, other exprs are int/long, ditto.
       else, need type checking at runtime
       */

    allTypesKnown = 1;
    if (adrType == TYPE_INTEGER)
    {
	byte i;
	for (i = 1; i <= 3; i++) {
	    token = CurTree_LOCK(CurTree_GET_NTH(node, i));
	    if (token->type != TYPE_INTEGER) {
		allTypesKnown = 0;
	    }
	    HugeTreeUnlock(token);
	}
    }
    else if (adrType == TYPE_LONG)
    {
	byte i;
	for (i = 1; i <= 3; i++) {
	    token = CurTree_LOCK(CurTree_GET_NTH(node, i));
	    if (token->type != TYPE_INTEGER && token->type != TYPE_LONG) {
		allTypesKnown = 0;
	    }
	    HugeTreeUnlock(token);
	}
    }
    else {
	allTypesKnown = 0;
    }

    /* Generate code for step expression first, if necessary.
       This allows us at runtime to always find the necessary
       expressions at top of stack...
 
       See if we can use the faster FOR operation.
       Currently we can do this if all types are known at compile
       time to be all int or all long, 
       and if the increment is 1. If we pass, we don't
       put the step expression on the stack and instead make
       the opcode know what's going on.
    */

    token = CurTree_LOCK(stepExpr);
    
    if (token->code == CONST_INT && token->data.key == (long) 1 &&
	allTypesKnown) {
	HugeTreeUnlock(token);
        fastOp = 1;
    }
    else {
	HugeTreeUnlock(token);
	CHECK(CodeGenExpr(task, stepExpr));
	fastOp = 0;
    }

    /* Now generate code for the start expression */

    CHECK(CodeGenExpr(task, startExpr));

    /* Now generate code for the end expression */

    CHECK(CodeGenExpr(task, endExpr));

    /* Now we can generate the actual opcode.
       If all types are known and the step increment is 1, 
       use the fast opcode.
    */



    CHECK(CodeGenCheckFreeSpace(task, 4));
    if (fastOp) {
	CodeGenEmitByteNoCheck(task, OP_FOR_LM1_UNTYPED);
    }
    else {
	CodeGenEmitByteNoCheck(task, OP_FOR_LM_TYPED);
    }

    CodeGenEmitByteNoCheck(task, adrScope);
    if (adrScope == OP_MODULE_VAR_LV ||
	adrScope == OP_MODULE_VAR_LV_INDEX)
    {
	LabelCreateGlobalFixup(task, adrKey, GRT_MODULE_VAR);
    }
    CodeGenEmitWordNoCheck(task, adrIndex);

    /* Generate a jump to where code should continue
       after loop.  Note that runtime just disassembles
       this code to determine the address and then
       runtime for/next supports jumps when appropriate. 
    */

    CHECK(CodeGenCheckFreeSpace(task, 3));
    LabelCreateFixup(task, FT_JUMP, jExit);
    CHECK(CodeGenEmitByte(task, OP_JMP));
    CHECK(CodeGenEmitLabel(task, jExit));

    /* This is where the actual loop code goes. */

    /* At runtime, the interpreter will be able to determine
       this address and maintain it for repeated iterations.
    */

    CHECK(CodeGenBlockOfCode(task, codeBlock, jExit, doExitLabel));

    /* Let's assign the code which increments and jumps to top
       to the "NEXT" line, which is the final node under our For node */

    token = CurTree_LOCK(nextNode);
    /* Now emit the correct OP_NEXT..
     */
    CHECK(CodeGenLineBegin(task, token->lineNum));
    HugeTreeUnlock(token);
    if (fastOp && adrType == TYPE_INTEGER) {

	/* These are the most specific, fastest opcodes */

	if (adrScope == OP_LOCAL_VAR_LV) {
	    CHECK(CodeGenEmitByte(task, OP_NEXT_L1_INT));
	}
	else {
	    CHECK(CodeGenEmitByte(task, OP_NEXT_M1_INT));
	}
    }
    else {
	
	/* For cases where unknown variables are involved
	   (or longs), or non-1 steps, use the more general version.
	*/
	CHECK(CodeGenEmitByte(task, OP_NEXT_LM));
    }

    LabelSetOffset(task, jExit);

    return TRUE;
}    
    
/*********************************************************************
 *			CodeGenCheckContext
 *********************************************************************
 * SYNOPSIS:	check to see if we are in a propert context
 * CALLED BY:	CodeGenExit
 * RETURN:  	TRUE if we are in a proper context, FALSE otherwise
 * SIDE EFFECTS:
 * STRATEGY:	run up the tree looking for a node of a specific type
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/16/94		Initial version			     
 * 
 *********************************************************************/
Boolean CodeGenCheckContext(TaskPtr 	    task, 
			    Node    	    start, 
			    TokenCode 	    code)
{
    Node    next;
    Token   *token;
    
    next = start;
    while (next != NullNode)
    {
	token = (Token *)HugeTreeLock(task->vmHandle, task->tree, next);
	if (token->code == code)
	{
	    HugeTreeUnlock(token);
	    return TRUE;
	}
	HugeTreeUnlock(token);
	next = HugeTreeGetParent(task->vmHandle, task->tree, next);
    }
    return FALSE;
}

/*********************************************************************
 *			CG_EmitCleanup
 *********************************************************************
 * SYNOPSIS:	Emit cleanup code for EXIT statements
 * CALLED BY:	INTERNAL, CodeGenExit
 * RETURN:	TRUE if successful, final node reached
 * SIDE EFFECTS:
 * STRATEGY:
 *	Tree walk actually starts at the parent of <start>, but
 *	this should never be a problem.
 *
 *	Walk up the tree, emitting cleanup POPs for any nodes
 *	(including the final node) that put things on the stack.
 *
 *	If *finalNode != NullNode, end our traversal when we hit
 *	that node.  Otherwise, keep going until we find a node of
 *	type <code>.  If exit conditions are never met, return FALSE.
 *
 *	*finalNode will be filled in with the last node traversed.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	1/29/96  	Initial version
 * 
 *********************************************************************/
Boolean
CG_EmitCleanup(TaskPtr task, Node start, Node* finalNode, TokenCode code)
{
    Boolean	success, done;
    Node	curNode;
    Token*	token;

    done = FALSE;
    curNode = start;

    do
    {
	curNode = CurTree_GET_PARENT(curNode);
	if (curNode == NullNode) {
	    return FALSE;
	}

	token = CurTree_LOCK(curNode);

	if (*finalNode != NullNode) {
	    done = (curNode == *finalNode);
	} else {
	    done = (token->code == code);
	}
		
	switch (token->code)
	{
	case FOR:
	    success = CodeGenEmitByte(task, OP_POP_LOOP);
	    break;
	case SELECT:
	    success = CodeGenEmitByte(task, OP_POP);
	    break;
	default:
	    success = TRUE;
	    break;
	}

	HugeTreeUnlock(token);

    } while (!done && success);

    *finalNode = curNode;
    return success;
}

/*********************************************************************
 *			CodeGenExit
 *********************************************************************
 * SYNOPSIS:	spit out a jump to the right label
 * CALLED BY:	CodeGenBlockOfCode
 * RETURN:  	true if everything is kosher, false otherwise
 * SIDE EFFECTS:
 * STRATEGY:	use CG_EmitCleanup to make sure we are ok
 *
 * REVISION HISTORY:	
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/16/94	Initial version
 * 
 *********************************************************************/
Boolean 
CodeGenExit(TaskPtr task, Node node, Label ForExitLabel, Label DoExitLabel)
{
    Token   	*token;
    TokenCode	code;
    Node	targetNode;
    Label	targetLabel;

    token = CurTree_LOCK(node);
    code = token->data.precedence; /* using precedence cause its a byte */
    HugeTreeUnlock(token);

    targetNode = NullNode;	/* stop when <code> is reached */
    if (!CG_EmitCleanup(task, node, &targetNode, code))
    {
	token = CurTree_LOCK(node);
	task->ln = token->lineNum;
	HugeTreeUnlock(token);
	SetError(task, E_BAD_EXIT);
	return FALSE;
    }

    /* targetNode not used yet, but eventually its end label should be
     * stored there, instead of passed around to all the CodeGen routines
     */
    /* targetLabel = Get_that_label(targetNode); */
    switch (code)
    {
    case DO:
	targetLabel = DoExitLabel;
	break;
    case FOR:
	targetLabel = ForExitLabel;
	break;
    case SUB:
    case FUNCTION:
	targetLabel = task->endRoutineLabel;
	break;
    default:
	EC_ERROR(BE_FAILED_ASSERTION);
#if !ERROR_CHECK
	return FALSE;
#endif
    }

    CHECK(CodeGenCheckFreeSpace(task, 3));
    LabelCreateFixup(task, FT_JUMP, targetLabel);
    CodeGenEmitByteNoCheck(task, OP_JMP);
    CodeGenEmitLabelNoCheck(task, targetLabel);
    return TRUE;
}
    
/*********************************************************************
 *			CodeGenCase
 *********************************************************************
 * SYNOPSIS:	deal with a case in a select statement
 * CALLED BY:	CodeGenSelect
 * RETURN:  	true if everything ok, false otherwise
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/16/94		Initial version			     
 * 
 *********************************************************************/
Boolean
CodeGenCase(TaskPtr task, Node node, Label codeLabel, Label endSelectLabel,
	    LegosType st)
{
    Token   *token;
    Node    next, low, high;
    int	    numSubCases, i;
    LegosType	lt;
    Opcode  op;

    /* CASE node says how many tests for this block */
    /* spit out a line number */
    token = HugeTreeLock(task->vmHandle, task->tree, node);
    lt = token->type;
    LabelCreateLine(task, token->lineNum);
    numSubCases = token->data.integer;
    HugeTreeUnlock(token);

    CHECK(CodeGenLineBeginNext(task, &endSelectLabel));

    /* if the select type is different than the case type then use
     * generic opcodes
     */
    if (st != lt) {
	lt = TYPE_UNKNOWN;
    }

    /* now deal with all the cases */
    for (i = 0; i < numSubCases; i++)
    {
	next = HugeTreeGetNthChild(task->vmHandle, task->tree, node, i);
	token = HugeTreeLock(task->vmHandle, task->tree, next);
	switch(token->code)
	{
	case TO:

	    low = HugeTreeGetNthChild(task->vmHandle, task->tree, next, 0);
	    high = HugeTreeGetNthChild(task->vmHandle,task->tree, next, 1);

	    CHECK(CodeGenEmitByte(task, OP_DUP));
	    CHECK(CodeGenEmitByte(task, OP_DUP));

	    CHECK(CodeGenExpr(task, low));
	    CHECK(CodeGenEmitByte(task, TTOC(GREATER_EQUAL)));

	    /* now see if we are greater than the high */

	    /* First, swap the result of the previous comparison
	       with the value we DUP'ed before. Bug fixed 6/2/95 by RG */

	    CHECK(CodeGenEmitByte(task, OP_SWAP));

	    CHECK(CodeGenExpr(task, high));
	    CHECK(CodeGenEmitByte(task, TTOC(LESS_EQUAL)));
	    CHECK(CodeGenEmitByte(task, TTOC(AND)));

	    CHECK(CodeGenCheckFreeSpace(task, 3));
	    LabelCreateFixup(task, FT_JUMP, codeLabel);
	    CodeGenEmitByteNoCheck(task, OP_BNE);
	    CodeGenEmitLabelNoCheck(task, codeLabel);

	    break;
	case ELSE:
	    /* Shouldn't have been called from CodeGenSelect */
	    EC_ERROR(BE_FAILED_ASSERTION);
	    break;
	default:

	    CHECK(CodeGenEmitByte(task, OP_DUP));
	    CHECK(CodeGenExpr(task, next));

	    switch(lt) {
	    case TYPE_INTEGER:
		op = OP_EQUALS_INT;
		break;
	    case TYPE_LONG:
		op = OP_EQUALS_LONG;
		break;
	    case TYPE_STRING:
		op = OP_EQUALS_STRING;
		break;
	    case TYPE_UNKNOWN:
	    case TYPE_FLOAT:
	    default:
		op = OP_EQUALS;
		break;
	    }
	    CHECK(CodeGenEmitByte(task, op));
	    CHECK(CodeGenCheckFreeSpace(task, 3));
	    LabelCreateFixup(task, FT_JUMP, codeLabel);
	    CodeGenEmitByteNoCheck(task, OP_BNE);
	    CodeGenEmitLabelNoCheck(task, codeLabel);
	    break;
        }		
	HugeTreeUnlock(token);
    }

    return TRUE;
}

/*********************************************************************
 *			CodeGenSelect
 *********************************************************************
 * SYNOPSIS:	generate code for a select statement
 * CALLED BY:	COdeGenBlockOfCode
 * RETURN:  	true if everything ok, false otherwise
 * SIDE EFFECTS:
 * STRATEGY:
 *	1. Output expression to test
 *	2. Output code for CASE checks (failed checks just fall through
 *	   to next CASE)
 *	3. Output CASE bodies in reverse order, so CASE ELSE can just
 *	   fall through.
 *		Original strategy preserved for posterity
 *
 *		Rewritten by Roy; Jimmy's variant would work just
 *              fine, but I figured we might as well make
 *              the code more efficient, cutting the number
 *              of jumps in half.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/16/94	Initial version
 *	dubois	1/17/96 	I rewrote the strategy; Roy's comments
 *				were accurate but I figured I might as
 *				well make it more informative, cutting the
 *				time needed for me to modify this routine
 *				in half.
 * 
 *********************************************************************/
Boolean
CodeGenSelect(TaskPtr task, Node node, Label forExit, Label doExit)
{
    int	    	nonElse, num, i;
    Label   	endselect, afterPop;
    Boolean     foundElse = FALSE;
    Token       *token;

    MemHandle	labelHandle;	/* Holds labels for CASE bodies */
    Label*	caseCode;
    LegosType	lt;

    endselect = LabelCreateTarget(task);
    afterPop = LabelCreateTarget(task);

    num = CurTree_NUM_CHILDREN(node);
    
    /* No CASEs?  Just punt
     * FIXME: generate some code instead?  EXPR might have side effects
     */
    if (num == 1) 
    {
	return CodeGenEmitNoOp(task, node, FALSE);
    }

    token = HugeTreeLock(task->vmHandle, task->tree, node);
    lt = token->type;
    HugeTreeUnlock(token);

    /* token = 1st child of last child */
    token = CurTree_LOCK(CurTree_GET_NTH(CurTree_GET_NTH(node, num-1), 0));
    /* nonElse is the highest index of a non-else block */
    if (token->code == ELSE) {
	foundElse = TRUE;
	nonElse = num-1;
    }
    else 
	nonElse = num;
    HugeTreeUnlock(token);

    labelHandle = MemAlloc( nonElse * sizeof(Label),
			   HF_SWAPABLE,
			   HAF_LOCK);
    
    /*- 1. Output expression to test.
     */
    CHECK(CodeGenLineBeginNext(task, &afterPop));
    CHECK(CodeGenExpr(task, CurTree_GET_NTH(node, 0)));

    /*- 2. Spit out CASE tests.  Failed tests fall through to the
     * next CASE
     */
    caseCode = MemLock(labelHandle);
    for (i = 1; i < nonElse; i++)
    {
	Node	next;
	next = CurTree_GET_NTH(node, i);
	caseCode[i-1] = LabelCreateTarget(task);
	if(!CodeGenCase(task, next, caseCode[i-1], endselect, lt)) {
	    MemFree(labelHandle);
	    return FALSE;
	}
    }

    /*- 3. Spit out CASE bodies in reverse order, so CASE ELSE
     * can just fall through
     */
    if (!foundElse) 
    {
	if (!CodeGenCheckFreeSpace(task, 3))
	{
	    MemFree(labelHandle);
	    return FALSE;
	}

	/* Don't need CodeGenLineBegin here, because case tests above
	 * all used CodeGenLineBeginNext
	 */
	LabelCreateFixup(task, FT_JUMP, endselect);
	CodeGenEmitByteNoCheck(task, OP_JMP);
	CodeGenEmitLabelNoCheck(task, endselect);
    }

    for ( i = num-1; i >= 1; i--)
    {
	Node	next;
	int	numCaseConstants;
	/* Don't set an offset for ELSE code (last block of code) */

	if(!(foundElse && i == num-1))
	    LabelSetOffset(task,caseCode[i-1]);

	next = CurTree_GET_NTH(node, i);
	token = CurTree_LOCK(next);
	numCaseConstants = token->data.integer;
	HugeTreeUnlock(token);
	
	if(!CodeGenBlockOfCode(task,
			       CurTree_GET_NTH(next, numCaseConstants),
			       forExit, doExit))
	{
	    MemFree(labelHandle);
	    return FALSE;
	}

	/* Just fall through directly on last case */

	if (i > 1) 
	{
	    /* Don't need LineBeginNext here, because OP_JMP
	     * can't cause errors.
	     */
	    CHECK(CodeGenLineBegin(task, -1));
	    if (!CodeGenCheckFreeSpace(task, 3))
	    {
		MemFree(labelHandle);
		return FALSE;
	    }
	    LabelCreateFixup(task, FT_JUMP, endselect);
	    CodeGenEmitByteNoCheck(task, OP_JMP);
	    CodeGenEmitLabelNoCheck(task, endselect);
	}
    }
    MemFree(labelHandle);

    LabelSetOffset(task, endselect);
    CHECK(CodeGenLineBegin(task, -1));
    CHECK(CodeGenEmitByte(task, OP_POP));
    LabelSetOffset(task, afterPop);

    return TRUE;
}


