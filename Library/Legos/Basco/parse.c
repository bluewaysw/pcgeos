/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		parse.c

AUTHOR:		Jimmy Lefkowitz, Dec  6, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	12/ 6/94	Initial version.

DESCRIPTION:
	code for parsing basic code into AST trees

	$Id: parse.c,v 1.1 98/10/13 21:43:14 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


#include <tree.h>
#include <Ansi/ctype.h>
#include <localize.h>

#include "mystdapp.h"
#include "btoken.h"
#include "scanner.h"
#include "stable.h"
#include "parse.h"
#include "scope.h"
#include "parseint.h"
#include "vars.h"
#include "table.h"
#include "typesint.h"
#include <Legos/opcode.h>
#include <Legos/edit.h>
#include <thread.h>

extern word setDSToDgroup(void);
extern void restoreDS(word);
extern void InitCompileTask(TaskPtr task);

/*********************************************************************
 *			ParseAllocTokenNode
 *********************************************************************
 * SYNOPSIS:	allocate a node with a given token code for data
 * CALLED BY:	many routines
 * RETURN:	allocated node (unlocked)
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 9/94		Initial version			     
 * 
 *********************************************************************/
Node
ParseAllocTokenNode(VMFileHandle vmfile,
		    VMBlockHandle tree,
		    TokenCode	code,
		    word	lineNum,
		    dword	data,
		    word	numChildren)
{
    Node    new;
    Token   *nodePtr;

    new = HT_AllocNode(numChildren);
    EC_ERROR_IF(new == NullNode, BE_FAILED_ASSERTION);
    nodePtr = HT_Lock(new);
    nodePtr->lineNum = lineNum;
    nodePtr->code = code;
    nodePtr->data.key = data;
    nodePtr->type = TYPE_NONE;
    nodePtr->typeData = 0xffff;
    HugeTreeDirty(nodePtr);
    HugeTreeUnlock(nodePtr);
    return new;
}


/*********************************************************************
 *			IsEndBlockToken
 *********************************************************************
 * SYNOPSIS:	see if we have reached the end of a block of code
 * CALLED BY:	Parse_BlockOfCode
 * RETURN:	true if we have reached an end of block token
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 7/94		Initial version			     
 * 
 *********************************************************************/
Boolean
IsEndBlockToken(Token *token)
{
    switch(token->code)
    {
	case END:
	case TOKEN_EOF:
	case ELSE:
	case NEXT:
	case CASE:
	case LOOP:
	    return TRUE;
	default:
	    return FALSE;
    }
}


/*********************************************************************
 *			ParseIsEndExprToken
 *********************************************************************
 * SYNOPSIS:	see if its an end of expression token
 * CALLED BY:	Parse_Expr
 * RETURN:	TRUE if its the end of an expression
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 8/94		Initial version			     
 * 
 *********************************************************************/
expr_type ParseIsEndExprToken(TokenCode code)
{
    /* Note: the EXPR_DONT_CONSUME isnt really used as that any more
     * parse_expr keeps consumed the token it grabbed and ended on,
     * but the token is stored in lastToken for others to check
     */
    if (LINE_TERM(code)) return EXPR_TERMINATE;

    switch (code)
    {
/* I'm pretty sure that this should never happen any more
 * if this error is hit, make them EXPR_TERMINATE again
 */
    case NULLCODE:
	EC_ERROR(-1);
    case CLOSE_PAREN:		/* End of argument list to routine */
    case COMMA:			/* End of argument to routine */
    case CLOSE_BRACKET:		/* End of array reference */
    case COLON:			/* Label.  Colon as module operator
				 * handled within literal, not expr */
	return EXPR_TERMINATE;

    case THEN:
    case ELSE:
    case TO:
    case AS:
    case STEP:
	return EXPR_DONT_CONSUME;

    default:
	break;
    }

    return EXPR_NORMAL;
}


/*********************************************************************
 *			Parse_ConstantExpression
 *********************************************************************
 * SYNOPSIS:	parse a constant expression
 * CALLED BY:	Parse_BlockOfCode, Parse_CompInit
 * RETURN:  	Token of constant expression or NullNode on error
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/10/95	Initial version
 * 
 *********************************************************************/
Token
Parse_ConstantExpression(TaskPtr	task,
			 VMBlockHandle	tree,
			 ScannerState	*state,
			 Token	    	*lastTok)
{
    Token   	    value, *t;
    Node	    expr;
    VMFileHandle vmfile;

    vmfile = task->vmHandle;

    /* store the parsed expression as the data for the constant
     */
    expr = Parse_Expr(task, tree, state, TRUE, lastTok, MIN_PREC);
    if (expr == NullNode)
/*	ParseIsEndExprToken(lastTok->code) != EXPR_TERMINATE)*/
    {
	SetError(task, E_NOT_CONSTANT_EXPRESSION);
	return *lastTok;
    }
    /* go ahead and type check the constant expression now
     * to crunch it down to a single constants node
     */
    task->tree = tree;
    (void) Type_Check(task, expr);
    t = HT_Lock(expr);
    value = *t;
    HugeTreeUnlock(t);
    if (! (isNumericConstant(value.code) || value.code == CONST_STRING))
    {
	SetError(task, E_NOT_CONSTANT_EXPRESSION);
	return *lastTok;
    }
    /* zero out high word for ease of comparisons */
    if (value.code == CONST_INT || value.code == CONST_STRING)
    {
	value.data.key &= 0x0000ffff;
    }
    return value;
}


/*********************************************************************
 *			Parse_BlockOfCode
 *********************************************************************
 * SYNOPSIS:	common routine use by the top level parse routines
 *		it parses arbitrary amounts of code until it gets to the
 *		end of the input stream or it reaches the end token passed
 *		in. 
 * CALLED BY:	Parse_(If, For, Select, Do)
 * RETURN:	NOTHING
 * SIDE EFFECTS:
 *	code parsed into abstract syntax tree
 *	WARNING Can shuffle/move the function table block
 *
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 6/94		Initial version			     
 * 
 *********************************************************************/
Token
Parse_BlockOfCode(TaskPtr	task,
		  VMBlockHandle	tree,
		  Node		root, 
		  ScannerState	*state)
{
    Node	    new;
    Token	    token;
    VMFileHandle    vmfile = task->vmHandle;
    Boolean	addChild;
    Token   	oldToken;

    do {
	new = NullNode;
	addChild = TRUE;

	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, TRUE);
	oldToken = token;

	if (IsEndBlockToken(&token))
	{
	    return token;
	} 
	else 
	{
	    switch (token.code)
	    {
	    case RESUME:
	    {
		Boolean	nextP = FALSE;
		Token	tok2;
		
		tok2 = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
		if (tok2.code == NEXT) {
		    nextP = TRUE;
		    tok2 = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
		}
		if (!LINE_TERM(tok2.code)) {
		    if (tok2.code != IDENTIFIER) {
			SetIdentError(task, tok2.code);
			new = NullNode;
		    } else {
			Node	child;
			new = Parse_ALLOC_NODE(RESUME, state->lineNum, 
					       FALSE, 1);
			child = Parse_ALLOC_NODE
			    (INTERNAL_IDENTIFIER, state->lineNum, 
			     tok2.data.key, 0);
			Parse_SET_NTH(new, 0, child);
		    }
		} else {
		    new = Parse_ALLOC_NODE(RESUME, state->lineNum, nextP, 0);
		}
		break;
	    }
		
	    case ONERROR:
		new = Parse_OnError(task, tree, state);
		break;

	    case COMP_INIT:
		new = Parse_CompInit(task, tree, state);
		break;

	    case IF:
		new = Parse_If(task, tree, state);
		break;
	    case FOR:
		new = Parse_For(task, tree, state);
		break;
	    case TOKEN_GOTO:
	    {
		token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
		if (token.code != IDENTIFIER)
		{
		    SetIdentError(task, token.code);
		    return token;
		}
		new = HT_AllocTokenNode(TOKEN_GOTO, token.lineNum, token.data.key, 0);
	    }
		break;
	    case DIM:
		/* We supply the root here, because we
		   may be creating a whole slew of DIM nodes.
		   Dim a,b,c,d,e as integer will create
		   separate DIM subtrees for each appending
		   each separately to root. So pass root in,
		   and set a flag so we don't try to link anything in...
		 */

		/* new is only interesting if it's a NullNOde,
		   so we can propagate the error.
		 */

		addChild = FALSE;
		new = Parse_Dim(task, tree, root, state, token.code);
		break;

	    case REDIM:
		addChild = FALSE;
		new = Parse_Redim(task, tree, root, state, token.code);
		break;

	    case DO:
		new = Parse_Do(task, tree, state);
		break;
	    case STRUCT:
	    {
		new = Parse_Struct(task, tree, state);
		break;
	    }
	    case DEBUG:
		new = HT_AllocTokenNode(DEBUG, token.lineNum, DEBUG, 0);
		break;
	    case EXIT:
		/* EXIT is a special case since it should only happen below
		 * a DO node, but it can be many levels below a DO node
		 */

		/* now parse off the DO that must follow the EXIT */
		token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
		if (token.code == DO || token.code == FOR || 
		    token.code == FUNCTION || token.code == SUB)
		{
		    new = Parse_ALLOC_NODE(EXIT, token.lineNum, token.code, 1);
		}
		else
		{
		    SetError(task, E_BAD_EXIT);
		    return token;
		}
		break;
	    case SELECT:
		new = Parse_Select(task, tree, state);
		break;
	    case EXPORT:
	    {
		token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
		if (token.code != IDENTIFIER) 
		{
		    SetError(task, E_EXPECT_IDENT);
		    return token;
		}
		new = Parse_ALLOC_NODE(EXPORT, token.lineNum, 
				       token.data.key, 0);

		token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
		if (!LINE_TERM(token.code))
		{
		    SetError(task, E_NO_EOL);
		    return token;
		}
		break;
	    }

	    case CONSTANT:
	    {
		Token	lastTok;
		while (1)
		{
		    ConstantInfo	ci, oldVal;
		    Token	sym;
		    TCHAR	*symName;
		    /* deal with symbolic constants, purely a compile time 
		     * event
		     */
		    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, 
					    FALSE);
		    if (token.code != IDENTIFIER) 
		    {
			SetIdentError(task, token.code);
			return token;
		    }
		    sym = token;

		    ci.token = Parse_ConstantExpression(task, tree, state, 
							&lastTok);
		    if (task->err_code != NONE)
		    {
			return ci.token;
		    }

		    symName = StringTableLock(ID_TABLE, sym.data.key);
		    if (StringTableLookupWithData(SYMBOLIC_CONST_TABLE,
						  symName, sizeof(oldVal), 
						  &oldVal) != NullElement)
		    {
			/* see if its being redefined and give an error
			 */
			if (oldVal.funcNumber != CONSTANT_DELETED &&
			    oldVal.funcNumber != CONSTANT_CLEARED)
			{
			    StringTableUnlock(symName);
			    SetError(task, E_CONSTANT_ALREADY_DEFINED);
			    return ci.token;
			}

			/* if a constant value changes, just force a full
			 * recompile, we also do this is a constant was
			 * removed and then added again, this happens when
			 * someone removes a constant, finds out its still
			 * needed and so puts it back. the constants never
			 * get deleted unless a CleanTask is done, this turns
			 * out to be perfect, since adding new constants for
			 * the first time doesnt need to force a full recompile
			 * yay!
			 */
			if (oldVal.token.code != ci.token.code ||
			    oldVal.token.data.key != ci.token.data.key ||
			    oldVal.funcNumber == CONSTANT_DELETED)
			{
			    task->flags |= COMPILE_NEEDS_FULL_RECOMPILE;
			}
		    }

		    ci.funcNumber = task->funcNumber;
		    StringTableAddWithData(SYMBOLIC_CONST_TABLE, 
					   symName,sizeof(ci),
					   &ci);
		    StringTableUnlock(symName);

		    if (lastTok.code != COMMA) {
			break;
		    }
		}

		/* the expression should have ended on a line termination */
		if (!LINE_TERM(lastTok.code))
		{
		    SetError(task, E_NO_EOL);
		    return token;
		}
		continue;
	    }

	    default: /* EXPR */
		ScannerPushToken(state, oldToken);
		new = Parse_Expr(task, tree, state, TRUE, &token, MIN_PREC);

		/* all expressions should end on an EOL or COLON EOL (label) */
		if (new != NullNode && token.code == COLON) {
		    Parse_ConvertToLabel(task, new);
		    if (ERROR_SET) new = NullNode;
		    token = ScannerGetToken(state,ID_TABLE,CONST_TABLE,FALSE);
		}
		if (!LINE_TERM(token.code)) {
		    SetError(task, E_NO_EOL);
		    new = NullNode;
		}
		break;
	    }	 /* end of switch */

	    if (new == NullNode) {
		token.code = NULLCODE;
		return token;
	    }
	} /* end of else */

	if (addChild)
	    HugeTreeAppendChild(task->vmHandle, tree, root, PREALLOC, new);
    } while(1);

}

/*********************************************************************
 *			Parse_If
 *********************************************************************
 * SYNOPSIS:	parse an if statement
 * CALLED BY:	Parse_BlockOfCode
 * RETURN:	IF node is AST tree
 * SIDE EFFECTS: an AST tree of the if statement is built out
 * STRATEGY:
 *		if statement look like so:
 *		    IF EXPR THEN
 *			Block of Code
 *		    END IF
 *
 *		or
 *		    IF EXPR THEN
 *			Block Of Code
 *		    ELSE
 *			Block Of Code
 *		    END IF
 *
 *		so look for those tokens and call Parse_BlockOfCode
 *		accordingly
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 8/94		Initial version			     
 * 
 *********************************************************************/
Node
Parse_If(TaskPtr	task,
	 VMBlockHandle	tree,
	 ScannerState	*state)
{
    Node	    expr, ifnode, tnode, fnode;
    Token	    token;
    VMFileHandle    vmfile;

    vmfile = task->vmHandle;

    /* look for an expression that is NOT an assignment
     * and add the expression to the ifnode 
     */
    expr = Parse_Expr(task, tree, state, FALSE, &token, MIN_PREC);
    if (expr == NullNode) return NullNode;

    /* allow leaving off the THEN for us C people who always forget it */
    if (token.code != THEN && !LINE_TERM(token.code)) 
    {
	SetError(task, E_NO_THEN);
	return NullNode;
    }
    else if (token.code == THEN)
    {
	/* make sure there is nothing behind the THEN */
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (!LINE_TERM(token.code))
	{
	    SetError(task, E_NO_EOL);
	    return NullNode;
	}
    }

    ifnode = HT_AllocTokenNode(IF, state->lineNum, 0, 3);
    HugeTreeAppendChild(vmfile, tree, ifnode, PREALLOC, expr);

    /* now allocate children to hold the code for the TRUE case
     */
    tnode = HT_AllocNode(BLOCK_OF_CODE_MAX_LINES);
    HugeTreeAppendChild(vmfile, tree, ifnode, PREALLOC, tnode);

    token = Parse_BlockOfCode(task, tree, tnode, state);
    if (token.code == ELSE)
    {
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (LINE_TERM(token.code))
	{
	    /* add a false node to the IF node */
	    fnode = HT_AllocNode(BLOCK_OF_CODE_MAX_LINES);
	    HugeTreeAppendChild(vmfile, tree, ifnode, PREALLOC, fnode);
	    token = Parse_BlockOfCode(task, tree, fnode, state);
	}
	else if (token.code == IF)
	{
	    /* be sure to allocate tnode BEFORE parsing the if statement
	     * so if we get a compiler error, the line number is correct
	     */
	    tnode = HT_AllocTokenNode(NULLCODE, state->lineNum, 0, 1);
	    /* create a NULLCODE to put the IF node under */
	    fnode = Parse_If(task, tree, state);
	    if (fnode == NullNode) {
		return NullNode;
	    }
	    HugeTreeAppendChild(vmfile, tree, tnode, PREALLOC, fnode);
	    HugeTreeAppendChild(vmfile, tree, ifnode, PREALLOC, tnode);
	    return ifnode;
	}
	else
	{
	    SetError(task, E_NO_EOL);
	    return NullNode;
	}
    }

    if (token.code != END) {
	SetError(task, E_NO_ENDIF);
	return NullNode;
    }

    /* now get back the last line parse block of code was in so we can
     * check out what type of end we hit
     */
    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    if (token.code != IF)
    {
    	SetError(task, E_NO_ENDIF);
	return NullNode;
    }
    return ifnode;
}


/*********************************************************************
 *			Parse_Expr
 *********************************************************************
 * SYNOPSIS:	parse an expression into PCODE
 * CALLED BY:	basco parser
 * RETURN:	node of top of tree for parsed expression
 * SIDE EFFECTS:
 * STRATEGY:
 *	Parse an expression consisting of binary operators of various
 *	precedence.  Operands are parsed using Parse_Literal.
 *	Halts after consuming an end expr token, which is then stuffed
 *	in lastToken.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 1/94		Initial version			     
 * 
 *********************************************************************/
Node
Parse_Expr(TaskPtr		task,
		VMBlockHandle	tree, 
		ScannerState	*state,
		Boolean		assignment,
		Token		*lastToken,
		int 	    	min_prec)
{
    ErrorCode	err;
    VMFileHandle vmfile;

    Node	root;		/* Root of expression tree */
    Node	last_op;	/* Operator lacking a RHS subtree */

    Node	new_arg;	/* Argument just parsed by Parse_Literal */
    Node	new_op;		/* Operator just grabbed by scanner */
    
    vmfile = task->vmHandle;
    if (tree == NullHandle)
    {
	tree = HugeTreeCreate(vmfile);
    }

    /* initialize out key parse state variables */
    root = last_op = NullNode;

    while (1)
    {
	Token	token;
	Token	oldToken;
	/* 1. Parse an argument (new_arg); scan an operator and turn
	 *    it into a node (new_op).
	 *    Or, determine that it's time to quit this loop and finish
	 *    off the tree.
	 */
	new_arg = Parse_Literal(task, tree, state);
	if (new_arg == NullNode) return NullNode; /* Propagate error */

	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	oldToken = token;
	if (ParseIsEndExprToken(token.code) != EXPR_NORMAL)
	{
	    *lastToken = token;
	    break;
	}
	else if (! BINARY_OP(token.code) )
	{
	    err = E_EXPECT_BINARY;
	    goto err_done;
	}
	else if (token.data.precedence >= min_prec)
	{
	    /* Unconsume so our caller will deal with it.
	     * Don't update lastToken
	     */
	    /* Is this case even used any more?  Everyone passes MIN_PREC
	     * to Parse_Expr --dubois
	     */
	    ScannerPushToken(state, oldToken);
	    break;
	}
	if (token.code == EQUALS && assignment)
	{
	    /* FIXME: should turn assignment off here? */
	    token.code = ASSIGN;
	    token.data.precedence = PREC_ASSIGN;
	}

	new_op = HT_AllocTokenNode(token.code, token.lineNum,
				   token.data.precedence, 2);

	/* 2. Splice new_op and new_arg into the tree.
	 *		 
	 */
	if (root == NullNode)
	{
	    /* if we are the first node, its really easy, no running
	     * through the tree like a chicken with its head cut off,
	     * just allocate a Node and proclaim it to be the root and
	     * the last_op as well
	     */
	    root = last_op = new_op;
	    Parse_SET_NTH(root, LEFT_CHILD, new_arg);
	}
	else
	{
	    Node	temp;	/* Pointer that goes running up tree */
	    Token*	tempPtr;
	    int		prec;	/* Higher means lower precedence; nodes
				 * with high prec stay high in the tree.
				 */

	    /* Go running through the tree looking for a good place to
	     * put new_op and new_arg.  The starting place for our
	     * search will be the operator lacking a RHS.
	     */
	    temp = last_op; 

	    /* new_arg will fill in last_op's RHS, or be new_op's LHS.
	     * Whoever binds more tightly (lower prec) gets it, with
	     * ties going to last_op since all these operators are left
	     * associative.
	     */
	    tempPtr = HT_Lock(last_op);
	    prec = tempPtr->data.precedence;
	    HugeTreeUnlock(tempPtr);

	    if (prec <= token.data.precedence) 
	    {
		/* last_op wins; now we have to run up the tree looking
		 * for a LHS for new_op.  Find an op whose prec is <= ours.
		 * (<= and not < because we are left-associative).
		 */

		Parse_SET_NTH(last_op, RIGHT_CHILD, new_arg);

		while(1)
		{
		    /* At end of loop, temp points to parent whose
		     * right child we're going to replace, or NullNode
		     * if we are to become the new root.
		     *
		     * Operation looks like:
		     * temp		temp
		     *  t_LHS	->	 t_LHS
		     *  t_RHS		 new_op
		     *			  t_RHS
		     *			  [new_op has no RHS yet]
		     */
		    if (temp == NullNode)
		    {
			/* well I'll be, we got to the top, so this is the
			 * operator of lowest precedence in this neck
			 * of the woods, looks like newbie is in for
			 * a rough initiation
			 */
			break;
		    }

		    /* grab out the precedence value for the next
		     * parent in the tree
		     */
		    tempPtr = HT_Lock(temp);
		    prec = tempPtr->data.precedence;
		    HugeTreeUnlock(tempPtr);

		    /* it's lower than us, we have gone far enough.
		     */
		    if (prec > token.data.precedence)
		    {
			break;
		    }

		    /* on to the next parent on our quest */
		    temp = Parse_GET_PARENT(temp);
		}

		if (temp == NullNode)
		{
		    /* ok, we were at the root, so we become the new
		     * root
		     */
		    Parse_SET_NTH(new_op, LEFT_CHILD, root);
		    root = new_op;
		} 
		else 
		{
		    Node	rhs;
		    /* Replace the node (which is the RHS child of temp)
		     * keeping it as new_op's LHS.
		     *
		     * it seems the it will always be the right child
		     * I can't prove it, but I have a gut feeling that
		     * it will always be the case - jimmy
		     *
		     * It's always the RHS child because last_op is always
		     * the right-most node.  (proof is an exercise for reader)
		     */
		    rhs = Parse_GET_NTH(temp, RIGHT_CHILD);
		    Parse_SET_NTH(new_op, LEFT_CHILD, rhs);
		    Parse_SET_NTH(temp, RIGHT_CHILD, new_op);
		}
	    }
	    else
	    {
		/* so this is the case where we are adding an operator
		 * of higer precedence than the last_op. because of the
		 * fact that we are building the tree left to right and
		 * that ties count as first come first serve, a higher
		 * precedence turns out to always be just the right
		 * child of the last_op node and we get the new_arg
		 */
		Parse_SET_NTH(last_op, RIGHT_CHILD, new_op);
		Parse_SET_NTH(new_op, LEFT_CHILD, new_arg);
	    }
	}
	/* INVARIANT: last_op now has a rhs, and new_op does not.
	 * So, update last_op so we know whom to give a rhs.
	 */
	last_op = new_op;
    } /* end of while */

    if (root == NullNode)
    {
	/* returning just a subtree is a special case in that it has
	 * no binary operators.
	 */
	EC_ERROR_IF(new_arg == NullNode, BE_FAILED_ASSERTION);
	root = new_arg;
    }
    else
    {
	/* this is the last argument, stick it in the tree */
	Parse_SET_NTH(last_op, RIGHT_CHILD, new_arg);
    }
    return root;

 err_done:
    SetError(task, err);
    return NullNode;
}

/*********************************************************************
 *			Parse_Literal
 *********************************************************************
 * SYNOPSIS:	parse an expression into PCODE
 * CALLED BY:	basco parser
 * RETURN:	node of top of tree for parsed literal
 * SIDE EFFECTS:
 * STRATEGY:
 *	Deals with unary operators, EXCLAMATION, COLON, PERIOD,
 *	array references (BRACKETs), function calls (PARENs),
 *	grouping (also PARENs)
 *
 *	Everything is left-associative.
 *
 *	Embodies the following rules (hacked-type BNF):

maybe_unary_op:   (NULL)
		| PLUS | MINUS | NOT

const:		  
symbolic_const:  CONST_{INT,LONG,FLOAT,STRING}


literal:	  unary_op const
		| unary_op simple_lit

simple_lit:	  IDENTIFIER
		| '(' expr ')'					grouping
		| simple_lit '(' expr_list ')'			procedures
		| simple_lit COLON string			modules
		| simple_lit EXCLAMATION string '(' expr_list ')'	actions
		| simple_lit PERIOD string			properties
		| simple_lit PERIOD '(' expr ')'		stack property
		| simple_lit CARET string			structures
		| simple_lit '[' expr_list ']'			arrays

expr_list is just exprs separated by commas.
expr is defined in Parse_Expr

 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------
 *	jimmy	12/ 1/94	Initial version			     
 *	dubois	 4/24/95  	Moved out of Parse_Expr
 * 
 *********************************************************************/
Node
Parse_Literal(TaskPtr task, VMBlockHandle tree, ScannerState *state)
{
    Node	root;		/* Root of tree -- return value */
    Token	token;		/* Token returned by scanner */
    Node	temp;
    Node	prefixOp;	/* If there is one, it's here */
    Boolean	expectParen;	/* hack to force paren after ! */
    VMFileHandle vmfile;
    ErrorCode	err;
    
    /* Initialize state variables
     */
    vmfile = task->vmHandle;
    EC_ERROR_IF(tree == NullHandle, BE_FAILED_ASSERTION);
    prefixOp = root = NullNode;
    expectParen = FALSE;

    /* Get the root node
     *
     * Ugh!  We must handle unary prefix operators, but they're at a
     * different precedence level.  Keep things simple: allow at
     * most one unary prefix operator; tack it on to the tree just
     * before returning.
     */
 getRoot:
    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    switch (token.code) {

	/* PLUS, MINUS, NOT: it's a unary operator */

    case PLUS:
	token.code = POSITIVE;
	goto allocPrefix;
    case MINUS:
	token.code = NEGATIVE;
    case NOT:
 allocPrefix:
	Parse_ERROR_IF(prefixOp != NullNode, E_ONE_UNARY, err_done);
	prefixOp = HT_AllocTokenNode(token.code, token.lineNum, 0, 1);
	goto getRoot;
/*	break;*/

	/* Otherwise, it's a valid root */

    case OPEN_PAREN:
    {
	Token	t;
	root = Parse_Expr(task, tree, state, FALSE, &t, MIN_PREC);
	if (root == NullNode) return NullNode;
	Parse_ERROR_IF(t.code != CLOSE_PAREN, E_EXPECT_CLOSE_PAREN, err_done);
	break;
    }

    case CONST_INT: case CONST_LONG: case CONST_FLOAT: case CONST_STRING:
	/* FIXME: assumes key is the largest element of the union
	 */
	root = HT_AllocTokenNode(token.code, token.lineNum, token.data.key, 0);
	goto return_const;

    case IDENTIFIER:
    {
	TCHAR	*name;
	ConstantInfo	sym;
	word	symIndex;
	Token   *t;

	/* check to see if the identifier is a symbolic constant */
	name = StringTableLock(ID_TABLE, token.data.key);
	symIndex = StringTableLookupWithData(SYMBOLIC_CONST_TABLE, name,
					     sizeof(sym), &sym);
	StringTableUnlock(name);

	if (symIndex != (word)NullElement) 
	{
	    if (sym.funcNumber > task->funcNumber) {
		err = E_CONSTANT_USE_BEFORE_DECL;
		goto err_done;
	    }
	    sym.token.lineNum = token.lineNum;    /* don't biff linenum */
	    token = sym.token;
	}
	    
	root = HT_AllocTokenNode(token.code, token.lineNum, 
				 token.data.key, 0);

	/* the way we remember this is a constant is to mark its typeData
	 * with the value from the constant's token
	 */
	t = HT_Lock(root);
	/* use plus since usually this value is initialize to zero, so 
	 * all non-zero values will be constants
	 */
	t->typeData = symIndex;
	HugeArrayDirty(t);
	HugeTreeUnlock(t);
	break;
    }

    case ERR_OVERFLOW:
	err = E_OVERFLOW;
	goto err_done;

    case ERR_NO_END_QUOTE:
	err = E_NO_END_QUOTE;
	goto err_done;

    case ERR_BAD_CHAR:
	err = E_BAD_CHAR;
	goto err_done;

    default:
	err = E_SYNTAX;
	goto err_done;
    }

    while (1)
    {
	/* Grab a token
	 */
	EC_ERROR_IF(root == NullNode, BE_FAILED_ASSERTION);
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);

	if (expectParen) {
	    Parse_ERROR_IF(token.code != OPEN_PAREN,
			   E_EXPECT_OPEN_PAREN, err_done);
	    expectParen = FALSE;
	}

	switch (token.code)
	{
	case PERIOD:		/* property or action */
	{
	    Node	propNameNode;

	    /* PROPERTY(name of property)
	     *   previous root	(evals to component)
	     *   expr		(evals to string -- name of property/action)
	     */

	    /* If followed by an expr list, OPEN_PAREN will change this
	     * node to ACTION.
	     */

	    /* Create a node for it, putting string in CONST_TABLE
	     * so it can be accessed at runtime
	     */
	    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	    Parse_ERROR_IF(token.code != IDENTIFIER &&
			   token.code != OPEN_PAREN,
			   E_EXPECT_IDENT, ident_err_done);

	    /*temp = HT_AllocTokenNode
		(((token.code == IDENTIFIER) ? PROPERTY : STACK_PROPERTY),
		 token.lineNum, token.data.key, 1);*/

	    temp = HT_AllocTokenNode
		(PROPERTY, token.lineNum, 0, 2);
	    Parse_SET_NTH(temp, 0, root);

	    if (token.code == OPEN_PAREN)
	    {
		/* Full-blown expression evaluating to a string.
		 * Because of our scanner and ambiguities we must
		 * force parens
		 */
		Token	t;

		propNameNode = Parse_Expr(task, tree, state,
					  FALSE, &t, MIN_PREC);
		Parse_ERROR_IF(t.code != CLOSE_PAREN, E_EXPECT_CLOSE_PAREN,
			       err_done);
	    } else {
		/* Just a token which we will turn into a const string
		 * as a convenience -- comp.prop is easier than comp.("prop")
		 */
		propNameNode = HT_AllocTokenNode
		    (CONST_STRING, token.lineNum, token.data.key, 0);
	    }
	    if (propNameNode == NullNode) return NullNode;
	    Parse_SET_NTH(temp, 1, propNameNode);
	    root = temp;
	    break;
	}

	case CARET:		/* struct field ref */
	{
	    Node	fieldNameNode;

	    /* STRUCT_REF
	     *   previous root
	     *   IDENTIFIER node (name of field)
	     */
	    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	    Parse_ERROR_IF(token.code != IDENTIFIER, E_EXPECT_IDENT, 
			   ident_err_done);

	    temp = Parse_ALLOC_NODE(STRUCT_REF, token.lineNum, 0, 2);

	    fieldNameNode = Parse_ALLOC_NODE
		(INTERNAL_IDENTIFIER, token.lineNum, token.data.key, 0);

	    Parse_SET_NTH(temp, 0, root);
	    Parse_SET_NTH(temp, 1, fieldNameNode);

	    root = temp;
	    break;
	}
#if 1
	case EXCLAMATION:	/* action */
	{
	    Node	actionNameNode;

	    /* NOTE: this has been superceded by the . operator.
	       it will go away soon
	       */

	    /* ACTION(name of action)
	     *   previous root
	     *   (arguments and # args will be appended by case OPEN_PAREN)
	     */

	    /* Create a node for it, putting string in CONST_TABLE
	     * so it can be accessed at runtime
	     * FIXME: cleaner to have string added at codegen
	     */
	    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	    Parse_ERROR_IF(token.code != IDENTIFIER, E_EXPECT_IDENT, 
			   ident_err_done);

	    temp = HT_AllocTokenNode(ACTION, token.lineNum, 0, 2);
	    Parse_SET_NTH(temp, 0, root);
	    actionNameNode = HT_AllocTokenNode
		(CONST_STRING, token.lineNum, token.data.key, 0);
	    Parse_SET_NTH(temp, 1, actionNameNode);

	    root = temp;
	    expectParen = TRUE;
	    /* Deal with parameter list when we hit a paren, as they share
	     * code with normal procedure calls
	     */
	}
	    break;
#endif
	case COLON:		/* module reference or label */
	{
	    /* If token stream is COLON EOF, push both back and
	     * take it as end of literal.  It will be converted
	     * to a label by a caller
	     */
	    /* MODULE_REF		<- root
	     *   CONST_STRING(name of module variable/function)
	     *   previous root (evaluates to a module)
	     */
	    Token	colonTok;
	    Node	moduleNode;

	    colonTok = token;
	    /* FIXME: cleaner to have string added at codegen
	     */
	    token = ScannerGetToken(state, CONST_TABLE, CONST_TABLE, FALSE);
	    if (LINE_TERM(token.code)) 
	    {
		/* let someone else deal with the COLON EOF */
		ScannerPushToken(state, token);
		ScannerPushToken(state, colonTok);
		return root;
	    }
	    Parse_ERROR_IF(token.code != IDENTIFIER, E_EXPECT_IDENT, 
			   ident_err_done);

	    temp = HT_AllocTokenNode(MODULE_REF, token.lineNum, 0, 2);
	    moduleNode = HT_AllocTokenNode(CONST_STRING, token.lineNum, 
					   token.data.key, 0);
	    Parse_SET_NTH(temp, 0, moduleNode);
	    Parse_SET_NTH(temp, 1, root);
	    /* Deal with module calls when we hit a paren, as they share
	     * code with normal procedure calls
	     */
	    root = temp;
	} 
	    break;

	case OPEN_BRACKET:	/* array reference */
	{
	    /* ARRAY_REF(# indices)	<- root
	     *   previous root (expression that evaluates to an array)
	     *   N other children (expressions) where N = # indices
	     */
	    
	    word	numIndices;
	    Token	t;

	    /* Assume most arrays will have 1 index = 2 children for node
	     */
	    temp = HT_AllocTokenNode(ARRAY_REF, token.lineNum, 1, 2);

	    Parse_SET_NTH(temp, 0, root);
	    
	    for (numIndices = 0, t.code = NULLCODE;
		 t.code != CLOSE_BRACKET;
		 numIndices++)
	    {
		Node	next;
		next = Parse_Expr(task, tree, state, FALSE, &t,
				  MIN_PREC);
		if (next == NullNode) return NullNode; /* propagate error */
		Parse_ERROR_IF(t.code != COMMA && t.code != CLOSE_BRACKET,
			       E_EXPECT_COMMA, err_done);
		Parse_APPEND_CHILD(temp, next);
	    }

	    /* Update temp to have the correct # of indices...
	     */
	    if (numIndices != 1)
	    {
		Token*	tempPtr;

		tempPtr = HT_Lock(temp);
		tempPtr->data.integer = numIndices;
		HugeTreeDirty(tempPtr);
		HugeTreeUnlock(tempPtr);
	    }

	    root = temp;
	}
	    break;

	case OPEN_PAREN:	/* function call */
	{
	    /* If an expr list doesn't make sense here, Parse_ProcCall
	     * will catch the error.
	     */
	    root = Parse_ProcCall(task, tree, state, root);
	    if (root == NullNode) return NullNode; /* propagate error */
	}
	    break;

	default:
	{
	    /* Anything else: end of literal.
	     * Assume caller will deal with this token, so put it back.
	     */
	    ScannerPushToken(state, token);
 return_const:
	    Parse_ERROR_IF(root == NullNode,E_EXPECT_BINARY_OPERAND, err_done);

	    /* Stick the unary prefix operator on top, if there was one.
	     */
	    if (prefixOp != NullNode)
	    {
		Parse_SET_NTH(prefixOp, 0, root);
		root = prefixOp;
	    }
	    return root;
	}
	} /* end switch */
    } /* end of while */

#pragma warn -rch
    EC_ERROR(BE_FAILED_ASSERTION); /* can't break out of while */
#pragma warn .rch

 err_done:
    SetError(task, err);
    return NullNode;
 ident_err_done:
    SetIdentError(task, token.code);
    return NullNode;
}

/*********************************************************************
 *			Parse_FindBuiltIn
 *********************************************************************
 * SYNOPSIS:	Find a built-in function given a case-insensitive name
 * CALLED BY:	INTERNAL, Parse_ProcCall
 * RETURN:	String table element # (or NullElement)
 * SIDE EFFECTS:none
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 4/24/95	Pulled out, DBCS'd
 *
 *********************************************************************/
dword
Parse_FindBuiltIn(TaskPtr task, TCHAR* name)
{
    TCHAR	builtin[MAX_BUILT_IN_FUNC_NAME+1];
    word	len;
    
    len = LocalStringLength(name);
    
    if (len <= MAX_BUILT_IN_FUNC_NAME)
    {
	strcpy(builtin, name);
	LocalUpcaseString(builtin, len);
    }
    return (StringTableLookupString(BUILT_IN_FUNC_TABLE, builtin));
}

/*********************************************************************
 *			Parse_ProcCall
 *********************************************************************
 * SYNOPSIS:	Parse a function-call like thing
 * CALLED BY:	INTERNAL, Parse_Literal
 * RETURN:	Root of proc call syntax tree, or NullNode on error
 * SIDE EFFECTS:
 * STRATEGY:
 *	The opening parenthesis has already been consumed.
 *	Parse until a close paren.
 *
 *	Trees passed in will look like:
 *
 *	PROPERTY
 *	  subtree (component)
 *	  subtree (string, name of prop)
 *
 *	IDENT("myFunction")
 *
 *	MODULE_REF
 *	  CONST_STRING("exportedVar")
 *	  subtree that evaluates to a module variable
 *
 *	The root will be modified (IDENT -> USER_FUNC or USER_PROC or
 *	BUILT_IN_FUNC, MODULE_REF -> MODULE_CALL, ACTION doesn't change,
 *	PROPERTY -> ACTION)
 *	and will have some children appended to it, eg:
 *
 *	USER_FUNC("someFunc")
 *	  [args...]
 *	  CONST_INT(# args)	[only for module calls]
 *
 *	Built-in funcs will not have the # args node, except for those
 *	that take a variable number of arguments.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 4/24/95	Initial version			     
 * 
 *********************************************************************/
Node
Parse_ProcCall(TaskPtr task, VMBlockHandle tree, ScannerState *state,
	       Node	root)	/* root of tree leading to proc call */
{
    TokenCode	funcCode;
    VMFileHandle vmfile;
    Token*	rootPtr;
    word	numArgs;
    word	i;
    ErrorCode	err;

    Token	t;

    vmfile = task->vmHandle;

    /* 1. Modify the root's code
     */
    rootPtr = HT_Lock(root);
    if (rootPtr->code == IDENTIFIER) /* user or built-in function call */
    {
	TCHAR*	st;
	dword	key;

	st = StringTableLock(ID_TABLE, rootPtr->data.key);
	EC_ERROR_IF(st == NULL, BE_FAILED_ASSERTION);
	key = Parse_FindBuiltIn(task, st);

	if (key != NullElement)
	{
	    BascoBuiltInEntry	*fe;

	    rootPtr->code = BUILT_IN_FUNC;
	    rootPtr->data.key = key;
/*	    HugeTreeDirty(rootPtr);	done below */
			
	    fe = MemLockFixedOrMovable(BuiltInFuncs);
	    fe += (word)key;
	    numArgs = fe->numArgs;
	    MemUnlockFixedOrMovable(BuiltInFuncs);
	}
	else
	{
	    BascoFuncType   ft;
	    FTabEntry	    *ftab;

	    ftab = FunctionFind(task, st);
	    if (ftab == NULL) {
		SetError(task, E_NO_FUNCTION);
		StringTableUnlock(st);
		HugeTreeUnlock(rootPtr);
		return NullNode;
	    }
	    ft = ftab->funcType;
	    FTabUnlock(ftab);

	    rootPtr->data.key = StringTableLookupString(FUNC_TABLE, st);
	    EC_ERROR_IF(rootPtr->data.key == NullElement, BE_FAILED_ASSERTION);

	    if (ft == FT_FUNCTION)
	    {
		rootPtr->code = USER_FUNC;
	    } 
	    else if (ft == FT_SUBROUTINE)
	    {
		rootPtr->code = USER_PROC;
	    }
#if ERROR_CHECK
	    else EC_ERROR(BE_FAILED_ASSERTION);
#endif
	}
	StringTableUnlock(st);
    }
    else if (rootPtr->code == MODULE_REF)
    {
	rootPtr->code = MODULE_CALL;
    }
    else if (rootPtr->code == PROPERTY)
    {
	/* property ref followed by arg list is really an action */
	rootPtr->code = ACTION;
    }
    else if (rootPtr->code == ACTION)
    {
    /* Nothing needs to be done here... rootPtr->code is already ACTION */
    }
#if ERROR_CHECK
    else EC_ERROR(BE_FAILED_ASSERTION);
#endif
	
    /* funcCode at this point will be USER_FUNC/USER_PROC
       for intramodule calls; ACTION for an action; MODULE_CALL
       for intermodule calls; and BUILT_IN_FUNC for built-in
       calls...

       */

    funcCode = rootPtr->code;
    HugeTreeDirty(rootPtr);
    HugeTreeUnlock(rootPtr);

    /* 2. Generate trees for argument expressions.
     */

    /* Argh, we need to special-case for no-arg calls like CurModule().
     * Yuck! This is a slight hack so the for loop can execute 0 times.
     */
    ;{
	t = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (t.code != CLOSE_PAREN) {
	    ScannerPushToken(state, t);
	}
    }

    for (i=0; t.code != CLOSE_PAREN; i++)
    {
	Node	next;

	next = Parse_Expr(task, tree, state, FALSE, &t, MIN_PREC);
	if (next == NullNode) return NullNode; /* propagate error */
	Parse_ERROR_IF(t.code != COMMA && t.code != CLOSE_PAREN,
		       E_EXPECT_COMMA, err_done);
	Parse_APPEND_CHILD(root, next);
    }

    /* 3. Tack on node for # arguments for intermodule calls and actions.
          Check correctness here for built-in calls.
	  Do nothing extra for intra-module calls.
	  */
    if (funcCode == BUILT_IN_FUNC &&
	numArgs != VARIABLE_NUM_ARGS)
    {
	Parse_ERROR_IF(i > numArgs, E_TOO_MANY_PARAMS, err_done);
	Parse_ERROR_IF(i < numArgs, E_TOO_FEW_PARAMS, err_done);
    }
    else if (funcCode == USER_FUNC || funcCode == USER_PROC) {
	/* During type analysis, make sure that the actual
	   number of children is the same as the number of
	   parameters required by the routine.

	   Ideally we'd check that here, but
	   Can't do it here because we may not have parsed
	   all routines yet....

	   Type analysis, however, is guaranteed to happen
	   AFTER all of a module is parsed...
	*/
	;
    }
    else {
	Node	temp;
	temp = HT_AllocTokenNode(CONST_INT, t.lineNum, i, 0);
	Parse_APPEND_CHILD(root, temp);
    }

    return root;

 err_done:
    SetError(task, err);
    return NullNode;
}

/*********************************************************************
 *			Parse_ConvertToLabel
 *********************************************************************
 * SYNOPSIS:	Convert a MODULE_REF to a LABEL
 * CALLED BY:	INTERNAL, Parse_Literal
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 *	We can get trees for things like "(3+5)*foobar:"
 *	which means <node> is not always an IDENTIFIER
 *	
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	5/14/96  	Initial version
 * 
 *********************************************************************/
void
Parse_ConvertToLabel(TaskPtr task, Node node)
{
    Token	*t;

    t = CurTree_LOCK(node);
    if (t->code != IDENTIFIER) {
	if (TokenIsKeyword(t->code)) {
	    SetError(task, E_BAD_KEYWORD_USE);
	} else {
	    SetError(task, E_MALFORMED_LABEL);
	}
	goto done;
    }
    
    t->code = LABEL;
    HugeTreeDirty(t);

    FTabAddLabel(task, t->data.key, node);
 done:
    HugeTreeUnlock(t);
    return;
}
