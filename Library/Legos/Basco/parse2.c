/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		parse2.c

AUTHOR:		Jimmy Lefkowitz, Dec 12, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	12/12/94   	Initial version.

DESCRIPTION:
 	    	more parse routines

	$Id: parse2.c,v 1.1 98/10/13 21:43:18 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


#include <mystdapp.h>
#include <tree.h>
#include <Legos/fido.h>
#include "btoken.h"
#include "stable.h"
#include "parse.h"
#include "scope.h"
#include "scanner.h"
#include "parseint.h"
#include "comptime.h"
#include "vars.h"


/*********************************************************************
 *			Parse_OnError
 *********************************************************************
 * SYNOPSIS:	Parse ON ERROR GOTO
 * CALLED BY:	EXTERNAL Parse_BlockOfCode
 * RETURN:	ONERROR node
 * SIDE EFFECTS:
 * STRATEGY:
 *	ONERROR GOTO <label>		token.data.key is string id
 *	ONERROR GOTO 0			token.data.key is KEY_GOTO_ZERO
 *	ONERROR RESUME NEXT		token.data.key is KEY_RESUME_NEXT
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	12/27/95	Initial version
 * 
 *********************************************************************/
Node
Parse_OnError(TaskPtr	    	task,
	      VMBlockHandle	tree,
	      ScannerState  	*state)
{
    FTabEntry*	ftab;
    Node	root;
    Token	token;
    VMFileHandle	vmfile;

    vmfile = task->vmHandle;
    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);

    if (token.code == RESUME)
    {
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (token.code == NEXT) {
	    FTabEntry*	ftab;
	    token.data.key = KEY_RESUME_NEXT;
	    ftab = FTabLock(task->funcTable, task->funcNumber);
	    ftab->hasResumeNext = TRUE;
	    FTabUnlock(ftab);
	} else {
	    SetError(task, E_SYNTAX);
	    return NullNode;
	}
    }
    else if (token.code == TOKEN_GOTO)
    {
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (token.code == CONST_INT && token.data.integer == 0)
	{
	    token.data.key = KEY_GOTO_ZERO;
	}
	else if (token.code != IDENTIFIER)
	{
	    SetError(task, E_SYNTAX);
	    return NullNode;
	}
    }
    else
    {
	SetError(task, E_SYNTAX);
	return NullNode;
    }

    root = Parse_ALLOC_NODE(ONERROR, state->lineNum, token.data.key, 0);

    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    if (!LINE_TERM(token.code)) {
	SetError(task, E_NO_EOL);
	return NullNode;
    }

    ftab = FTabLock(task->funcTable, task->funcNumber);
    ftab->hasErrorTrap = TRUE;
    FTabUnlock(ftab);
    return root;
}

/*********************************************************************
 *			Parse_Type
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/24/95	Initial version
 * 
 *********************************************************************/
Node
Parse_Type(TaskPtr	task,
	   VMBlockHandle tree,
	   ScannerState	*state)
{
    Token	token;
    VMFileHandle vmfile = task->vmHandle;
    Node	retval;
    ErrorCode	err;
    
    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    switch (token.code)
    {
    case COMPONENT:
	/* if its the generic component type, set the data to
	 * NullElement so we don't mistakenly think its some specific
	 * component type later.
	 */
	token.data.key = NullElement;
	break;

    case STRING:
    case INTEGER:
    case FLOAT:
    case LONG:
    case MODULE:
    case COMPLEX:
	break;

    case STRUCT:
    {
	/* Don't do any checks here -- just create a Token:
	 * STRUCT(<ident>)
	 */
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	Parse_ERROR_IF(token.code != IDENTIFIER, E_EXPECT_IDENT, 
		       ident_err_done);

	token.code = STRUCT;
    }	
	break;

    case IDENTIFIER:
    {
	/* Identifiers become components of a specific type, unless
	 * build-time.
	 */
	TCHAR*	name;
	word	data;

	/* no byte compiling for buildtime */
#ifdef DOS
	if (1)
#else
	if (task->flags & COMPILE_BUILD_TIME) 
#endif
	{
	    token.code = COMPONENT;
	    token.data.key = NullElement;
	    break;
	}

	name = StringTableLock(ID_TABLE, token.data.key);
	EC_ERROR_IF(name == NULL, BE_FAILED_ASSERTION);

	/* if its a new type, instantiate an object of that type to have
	 * around for questioning, we will store the chunk handle of the
	 * object with the string for later reference
	 */
	token.code = COMPONENT;
	token.data.key = StringTableLookupWithData(task->compTypeNameTable, 
						   name, sizeof(word), &data);
	if (token.data.key == NullElement)
	{
	    LibraryClassPointer     lcp;
	    MemHandle   	    libHan;
	    optr	    	    comp;
	    ChunkHandle	    	    chan;

	    libHan = FidoFindComponent(task->fidoTask, NULL_MODULE,
				       name, 0, &lcp);
	    if (libHan == NullHandle) 
	    {
		SetError(task, E_BAD_COMPONENT_TYPE);
		StringTableUnlock(name);
		return NullNode;
	    }

	    comp = ObjInstantiate(task->compTypeObjBlock, lcp.LCP_class);
	    chan = OptrToChunk(comp);
	    token.data.key = StringTableAddWithData(task->compTypeNameTable, 
						    name, sizeof(word), 
					    	    &chan);
	}
	StringTableUnlock(name);
	break;
    }
    default:
	SetError(task, E_BAD_TYPE);
	return NullNode;
    } /* switch */

    retval = Parse_ALLOC_NODE(token.code, token.lineNum, token.data.key, 0);
    return retval;

 err_done:
    SetError(task, err);
    return NullNode;
 ident_err_done:
    SetIdentError(task, token.code);
    return NullNode;
}

/*********************************************************************
 *			Parse_Select
 *********************************************************************
 * SYNOPSIS:	parse a select statement into an AST tree
 * CALLED BY:	Parse_BlockOfCode
 * RETURN:	select node for AST tree
 * SIDE EFFECTS:    select AST tree built out
 * STRATEGY:
 *
 *		    a select statement looks like so:
 *  
 *			SELECT CASE EXPR
 *			    CASE_BLOCK
 *			    ...
 *			END SELECT
 *
 *		    and a CASE_BLOCK looks like so:
 *
 *			CASE CASE_EXPR [, CASE_EXPR ]*
 *
 *			or
 *	    
 *			CASE ELSE
 *
 *		    and a CASE_EXPR looks like so:
 *
 *			EXPR
 *
 *			or
 *
 *			EXPR TO EXPR
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 9/94		Initial version			     
 * 
 *********************************************************************/
Node
Parse_Select(TaskPtr		task,
	     VMBlockHandle	tree,
	     ScannerState   	*state)
{
    VMFileHandle    vmfile = task->vmHandle;
    Node	    selectNode, expr;
    Token	    token, *nodePtr;
    int	    	    num;
    Boolean         seenElse = FALSE;

/*
SELECT		selectNode
 <expr>
 CASE (#)
  [ELSE]
  [expr]
  [TO]
   <expr>
   <expr>
 CASE
  <int>		# cases for next case
*/
    selectNode = HT_AllocTokenNode(SELECT, state->lineNum, 
				   0, BLOCK_OF_CODE_MAX_LINES);

    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    if (token.code != CASE)
    {
	SetError(task, E_NO_CASE);
	return NullNode;
    }
    
    expr = Parse_Expr(task, tree, state, FALSE, &token, MIN_PREC);
    if (expr == NullNode) {
	return NullNode;
    }
    HugeTreeAppendChild(vmfile, tree, selectNode, PREALLOC, expr);


    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, TRUE);

    /* loop through the cases */
    while (1) 
    {
	Node	caseNode;	/* Top-level node for this CASE */
	Node	codeNode;	/* code for this CASE */

	if (token.code == END)
	{
	    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	    if (token.code != SELECT) {
		SetError(task, E_NO_ENDSELECT);
		return NullNode;
	    } else {
		token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
		if (!LINE_TERM(token.code)) {
		    SetError(task, E_NO_EOL);
		    return NullNode;
		}
		return selectNode;
	    }	      
	}

	if (token.code != CASE)
	{
	    SetError(task, E_NO_CASE);
	    return NullNode;
	}

	if (seenElse) 
	{
	    SetError(task, E_ELSE_NOT_LAST);
	    return NullNode;
	}

	/* Create top-level CASE node.  Number will be filled in later.
	 */
	caseNode = HT_AllocTokenNode(CASE, token.lineNum,
				     0, BLOCK_OF_CODE_MAX_LINES);
	HugeTreeAppendChild(vmfile, tree, selectNode, PREALLOC, caseNode);

	/* Parse an ELSE token, or a list of expressions.
	 */
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (token.code == ELSE)
	{
	    expr = HT_AllocTokenNode(ELSE, token.lineNum, 0, 0);
	    HugeTreeAppendChild(vmfile, tree, caseNode, PREALLOC, expr);
	    num = 1;
	    seenElse = TRUE;
	}
	else
	{
	    ScannerPushToken(state, token);
	    for (num=0, token.code = NULLCODE;
		 ! LINE_TERM(token.code);
		 num++)
	    {
		expr = Parse_Expr(task, tree, state, FALSE, &token, MIN_PREC);

		if (expr == NullNode) return NullNode; /* propagate errors */
		if (token.code == TO)
		{
		    Node	toNode;
		    toNode = HT_AllocTokenNode(TO, token.lineNum,0, 2);
		    HugeTreeAppendChild(vmfile, tree, toNode, PREALLOC, expr);
		    expr = Parse_Expr(task, tree, state, FALSE,
				      &token, MIN_PREC);
		    if (expr == NullNode) return NullNode;
		    HugeTreeAppendChild(vmfile, tree, toNode, PREALLOC, expr);
		    HugeTreeAppendChild(vmfile, tree, caseNode, PREALLOC,
					toNode);
		}
		else
		{
		    HugeTreeAppendChild(vmfile, tree, caseNode,PREALLOC, expr);
		}	    
	    }
	}

	/* Fill in caseNode
	 */
	nodePtr = HT_Lock(caseNode);
	nodePtr->data.integer = num;
	HugeTreeDirty(nodePtr);
	HugeTreeUnlock(nodePtr);

	/* Parse the code for this case
	 */
	codeNode = HT_AllocTokenNode(NULLCODE, token.lineNum,
				     0, BLOCK_OF_CODE_MAX_LINES);
	token = Parse_BlockOfCode(task, tree, codeNode, state);

	HugeTreeAppendChild(vmfile, tree, caseNode, PREALLOC, codeNode);

    } /* End while */
}

/*********************************************************************
 *			Parse_Redim
 *********************************************************************
 * SYNOPSIS:	parse a dim statement into the AST tree
 * CALLED BY:	Parse_BlockOfCode
 * RETURN:	root that was passed in
 * SIDE EFFECTS:    a redim AST tree is built out
 * STRATEGY:
 *		    a redim statement looks like this:
 *
 *			DIM [CLAUSE] [, CLAUSE]*
 * 
 *                  where CLAUSE is 
 *
 *                      [PRESERVE] VAR
 *
 *		    and VAR is
 *
 *			IDENTIFIER | IDENTIFIER '[' EXPR ',' EXPR ',' ... ']'
 *
 *		REDIMs are terminated with newlines.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 8/94	Initial version			     
 *	dubois	12/ 5/95	Changed for redim
 * 
 *********************************************************************/
Node
Parse_Redim(TaskPtr	    	task,
	    VMBlockHandle	tree,
	    Node            	root,
	    ScannerState    	*state,
	    TokenCode  	    	code)
{
    Node	dimNode;	/* Root of the current DIM subtree */
    Node	numDimsNode;
    Node	exprNode;	/* for expressions and other random stuff */
    Token	token;
    VMFileHandle	vmfile;
    word    	preserve;
    Node    	pNode;

    vmfile = task->vmHandle;
    /* Can have more than one clause here... */

    while(1) 
    {
	/* Clauses */
	
	/* Tree for a clause looks like:
	    dimNode
	     PRESERVE (0 or 1)
	     ident
	     numDims (usu 0)
	     dims (0-3 of these)
	 */

	/* 1st child of DIM node is identifier
	 */
	preserve = FALSE;
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (token.code != IDENTIFIER) 
	{
	    if (token.code != PRESERVE)
	    {
		SetIdentError(task, token.code);
		return NullNode;
	    }
	    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	    preserve = TRUE;
	}

	dimNode = 
	    HT_AllocTokenNode(code, state->lineNum, preserve, MAX_DIMS + 4);

	Parse_APPEND_CHILD(root, dimNode);

	pNode = HT_AllocTokenNode(PRESERVE, state->lineNum, 
				  preserve, MAX_DIMS + 4);
	Parse_APPEND_CHILD(dimNode, pNode);

	exprNode = HT_AllocTokenNode(IDENTIFIER,
				     token.lineNum, token.data.key, 0);
	Parse_SET_NTH(dimNode, ARRAY_IDENT_NODE, exprNode);
	
	/* 2nd child is # indices; default to zero and fix up later if needed.
	 */
	numDimsNode = HT_AllocTokenNode(CONST_INT, token.lineNum, 0, 0);
	Parse_SET_NTH(dimNode, ARRAY_NUM_DIMS_NODE, numDimsNode);
    
	/* Parse:
	 *	  '[' exprlist ']'
	 * Append these expressions to DIM node
	 */
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (token.code == OPEN_BRACKET)
	{
	    word	numDimensions;
	    Token*	nodePtr;

	    for (numDimensions = 0;
		 token.code != CLOSE_BRACKET;
		 numDimensions++)
	    {
		exprNode = Parse_Expr(task, tree, state, FALSE,
				      &token, MIN_PREC);
		if (exprNode == NullNode)
		    return NullNode; /* Propagate error */
		Parse_APPEND_CHILD(dimNode, exprNode);
	    }

	    /* Fix the number of dimensions and read another token,
	     * which should be AS
	     */
	    nodePtr = HT_Lock(numDimsNode);
	    nodePtr->data.integer = numDimensions;
	    HugeTreeDirty(nodePtr);
	    HugeTreeUnlock(nodePtr);
	}
	else
	{
	    /* Expect open bracket */
	    SetError(task, E_SYNTAX);
	    return NullNode;
	}

	/* Parse another clause, or exit
	 */
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);

	if (token.code == COMMA)
	{
	    /* Another clause... keep on chugging */
	    continue;
	}
	else if (LINE_TERM(token.code))
	{
	    /* No more clauses -- exit */
	    break;
	}
	else
	{
	    SetError(task, E_NO_EOL);
	    return NullNode;
	}
    }
    
    /* Caller passes in the root to be returned, so this is slightly
     * redundant
     */
    return root;
}

/*********************************************************************
 *			Parse_Dim
 *********************************************************************
 * SYNOPSIS:	parse a dim statement into the AST tree
 * CALLED BY:	Parse_BlockOfCode
 * RETURN:	root that was passed in
 * SIDE EFFECTS:    a dim AST tree is built out
 * STRATEGY:
 *		    a dim statement looks like this:
 *
 *			DIM [CLAUSE] [, CLAUSE]*
 * 
 *                  where CLAUSE is 
 *
 *                      [PRESERVE] VAR AS <TYPE>
 *
 *		    and VAR is
 *
 *			IDENTIFIER | IDENTIFIER '[' EXPR ',' EXPR ',' ... ']'
 *
 *		DIMs are terminated with newlines.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 8/94		Initial version			     
 * 
 *********************************************************************/
Node
Parse_Dim(TaskPtr	task,
	 VMBlockHandle	tree,
	 Node           root,
	 ScannerState	*state,
	 TokenCode  	code)
{
    Node	dimNode;	/* Root of the current DIM subtree */
    Node	numDimsNode;
    Node	exprNode;	/* for expressions and other random stuff */
    Token	token;
    VMFileHandle	vmfile;
    word    	preserve;
    Node    	pNode;
    word    	lineNum;
    vmfile = task->vmHandle;
    /* Can have more than one clause here... */


    /* only emit a line number for the first one, so we don't get muliple
     * labels for the same line at code generation time
     */
    lineNum = state->lineNum;
    while(1) 
    {
	/* Clauses */
	
	/* Tree for a clause looks like:
	    dimNode
	     PRESERVE (0 or 1)
	     ident
	     numDims (usu 0)
	     type
	 */

	/* 1st child of DIM node is identifier
	 */
	preserve = FALSE;
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (token.code != IDENTIFIER) 
	{
	    if (token.code != PRESERVE)
	    {
		SetIdentError(task, token.code);
		return NullNode;
	    }
	    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	    preserve = TRUE;
	}

	dimNode = 
	    HT_AllocTokenNode(code, lineNum, preserve, MAX_DIMS + 4);

	Parse_APPEND_CHILD(root, dimNode);

	pNode = HT_AllocTokenNode(PRESERVE, state->lineNum, 
				  preserve, MAX_DIMS + 4);
	Parse_APPEND_CHILD(dimNode, pNode);

	exprNode = HT_AllocTokenNode(IDENTIFIER,
				     token.lineNum, token.data.key, 0);
	Parse_SET_NTH(dimNode, ARRAY_IDENT_NODE, exprNode);
	
	/* 2nd child is # indices; default to zero and fix up later if needed.
	 */
	numDimsNode = HT_AllocTokenNode(CONST_INT, token.lineNum, 0, 0);
	Parse_SET_NTH(dimNode, ARRAY_NUM_DIMS_NODE, numDimsNode);
    
	/* Parse:
	 *	  '[' exprlist ']' AS
	 *	| AS
	 * Append these expressions to DIM node
	 */
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (token.code == OPEN_BRACKET)
	{
	    word	numDimensions;
	    Token*	nodePtr;

	    for (numDimensions = 0;
		 token.code != CLOSE_BRACKET;
		 numDimensions++)
	    {
		exprNode = Parse_Expr(task, tree, state, FALSE,
				      &token, MIN_PREC);
		if (exprNode == NullNode)
		    return NullNode; /* Propagate error */
		Parse_APPEND_CHILD(dimNode, exprNode);
	    }

	    /* Fix the number of dimensions and read another token,
	     * which should be AS
	     */
	    nodePtr = HT_Lock(numDimsNode);
	    nodePtr->data.integer = numDimensions;
	    HugeTreeDirty(nodePtr);
	    HugeTreeUnlock(nodePtr);

	    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	}
	if (token.code != AS)
	{
	    SetError(task, E_NO_AS);
	    return NullNode;
	}

	/* Last child is the type for this clause
	 */
	exprNode = Parse_Type(task, tree, state);
	if (exprNode == NullNode) return NullNode;
	Parse_APPEND_CHILD(dimNode, exprNode);
	
	/* Parse another clause, or exit
	 */
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);

	if (token.code == COMMA)
	{
	    lineNum = -1;
	    /* Another clause... keep on chugging */
	    continue;
	}
	else if (LINE_TERM(token.code))
	{
	    /* No more clauses -- exit */
	    break;
	}
	else
	{
	    SetError(task, E_NO_EOL);
	    return NullNode;
	}
    }

    /* Caller passes in the root to be returned, so this is slightly
     * redundant
     */
    return root;
}

/*********************************************************************
 *			Parse_AddCheckForExitNode
 *********************************************************************
 * SYNOPSIS:	create an IF EXPR THEN EXIT node for DO LOOPS
 * CALLED BY:	Parse_Do
 * RETURN:	void
 * SIDE EFFECTS:
 * STRATEGY:
 *	Need to differentiate between normal IF and IF used for
 *	do while/loop until for purposes of "RESUME NEXT" behavior
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 9/94		Initial version			     
 * 
 *********************************************************************/
void Parse_AddCheckForExitNode(TaskPtr		task,
			       VMBlockHandle	tree,
			       Node		donode,
			       Node		expr,
			       Boolean		exitOnTrue,
			       word             lineNumForIf)
{
    TokenCode	tc;
    Node	ifnode, exitnode, notnode, tnode;
    VMFileHandle vmfile;

    vmfile = task->vmHandle;

    /* allocate an IF node using linenumber determined by DO */
    tc = exitOnTrue ? IF_DOWHILE : IF_LOOPUNTIL;
    ifnode = HT_AllocTokenNode(tc, lineNumForIf, 0, 4);

    /* add IF node as next child for do node */	     
    HugeTreeAppendChild(vmfile, tree, donode, PREALLOC, ifnode);
    if (exitOnTrue)
    {
	/* this is the easy case! just put in the EXPR as is */
	HugeTreeAppendChild(vmfile, tree, ifnode, PREALLOC, expr);
	/* now create the EXIT node for the IF true body of code */
    }
    else
    {
	/* we need to perform a unary NOT on the expression's result
	   since we exit when the expression evaluates to false */
	
	notnode = HT_AllocTokenNode(NOT, lineNumForIf, 4, 1);
	HugeTreeAppendChild(vmfile, tree, ifnode, PREALLOC, notnode);
	HugeTreeAppendChild(vmfile, tree, notnode, PREALLOC, expr);

    }

    tnode = HT_AllocNode(1);
    HugeTreeAppendChild(vmfile, tree, ifnode, PREALLOC, tnode);
    
    /* now add EXIT to if node */
    exitnode = HT_AllocTokenNode(EXIT, lineNumForIf, DO, 0);
    HugeTreeAppendChild(vmfile, tree, tnode, PREALLOC, exitnode);
}

/*********************************************************************
 *			Parse_Do
 *********************************************************************
 * SYNOPSIS:	parse with the various DO loops into an AST tree
 * CALLED BY:	Parse_BlockOfCode
 * RETURN:	DO node for the AST tree
 * SIDE EFFECTS:    do loop AST tree built out
 * STRATEGY:	
 *
 *		do loops have various forms.
 *
 *		plain vanilla DO loops:
 *		    DO
 *			Block Of Code
 *		    LOOP
 *
 *		    do 
 *
 *		DO WHILE loops:
 *		    
 *		    DO WHILE EXPR
 *			Block Of Code
 *		    LOOP
 *
 *		DO UNTIL loops:
 *
 *		    DO
 *			Block Of Code
 *		    LOOP UNTIL EXPR
 *
 * The easiest way to handle DO WHILE and DO UNTIL is to just insert an IF
 * node that checks the EXPR and does an EXIT if needed. The WHILE loop does
 * this as the first statement and exits if EXPR is false, the UNTIL does the
 * check after the Block Of Code and EXITS if its true. I will just stick an
 * IF node into the tree with the proper nodes under to emulate a DO LOOP with
 * an EXIT node in it
 * 
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 9/94		Initial version			     
 * 
 *********************************************************************/
Node
Parse_Do(TaskPtr	task,
	 VMBlockHandle	tree,
	 ScannerState	*state)
{
    Token	    token;
    Node	    donode, expr, codenode, loopNode;
    VMFileHandle    vmfile;

    vmfile = task->vmHandle;

    /* allocate a FOR node */
    donode = HT_AllocTokenNode(DO, state->lineNum, 0, BLOCK_OF_CODE_MAX_LINES);

    codenode = HT_AllocTokenNode(NULLCODE, state->lineNum,
				 0, BLOCK_OF_CODE_MAX_LINES);


    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    if (token.code == WHILE)
    {
	/* the while must be followed by an EXPR */
	expr = Parse_Expr(task, tree, state, FALSE, &token, MIN_PREC);
	if (expr == NullNode) {
	    return NullNode;
	}
	Parse_AddCheckForExitNode(task, tree, codenode, expr, FALSE, 
				  state->lineNum);
    } 
    else if (! LINE_TERM(token.code))
    {
	SetError(task, E_NO_EOL);
	return NullNode;
    }

    token = Parse_BlockOfCode(task, tree, codenode, state);
    if (token.code != LOOP)
    {
	SetError(task, E_NO_LOOP);
	return NullNode;
    }
    loopNode = HT_AllocTokenNode(LOOP, token.lineNum, 0, 0);

    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    if (token.code == UNTIL)
    {
	/* the UNTIL must be followed by an EXPR */
	expr = Parse_Expr(task, tree, state, FALSE, &token, MIN_PREC);
	if (expr == NullNode) {
	    return NullNode;
	}
	Parse_AddCheckForExitNode(task, tree, codenode, expr, TRUE, 
				  state->lineNum);
    }

    HugeTreeAppendChild(vmfile, tree, donode, PREALLOC, codenode);
    HugeTreeAppendChild(vmfile, tree, donode, PREALLOC, loopNode);
    return donode;
}

/*********************************************************************
 *			Parse_Struct
 *********************************************************************
 * SYNOPSIS:	Parse struct decls
 * CALLED BY:	Parse_BlockOfCode
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	STRUCTDECL	identifier
 *	  DIM statements
 *	END STRUCT
 *	tree looks like:
 *	STRUCT(ident)
 *	  dim node
 *	  dim node
 *	  dim node
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/11/95	Initial version
 * 
 *********************************************************************/
Node
Parse_Struct(TaskPtr task, VMBlockHandle tree, ScannerState   *state)
{
    Token	token;
    Node	structNode;
    ErrorCode	err;
    VMFileHandle vmfile;

    vmfile = task->vmHandle;

    /* Create the top-level node of our subtree
     */
    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    Parse_ERROR_IF(token.code != IDENTIFIER, E_EXPECT_IDENT, 
		   ident_error_unlock);
    structNode = HT_AllocTokenNode(STRUCTDECL, token.lineNum,
				   token.data.key, 0);

    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    Parse_ERROR_IF(!LINE_TERM(token.code), E_NO_EOL, error_unlock);

    while(1)
    {
	Node	dimNode;

	
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	/* this should allow whitespace lines inside the struct */
	if (LINE_TERM(token.code)) {
	    continue;
	}

	if (token.code == END) break;
	Parse_ERROR_IF(token.code != DIM, E_NO_DIM, error_unlock);

	/* Parse_Dim will append children itself */
	dimNode = Parse_Dim(task, tree, structNode, state, DIM);
	if (dimNode == NullNode) goto error_unlock;
    }
    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    Parse_ERROR_IF(token.code != STRUCT, E_NO_STRUCT, error_unlock);
    return structNode;

 error_unlock:
    SetError(task, err);
 ident_error_unlock:
    SetIdentError(task, token.code);

    return NullNode;
}

/*********************************************************************
 *			Parse_For
 *********************************************************************
 * SYNOPSIS:	parse for loops
 * CALLED BY:	Parse_BlockOfCode
 * RETURN:	root node for FOR AST tree
 * SIDE EFFECTS:    AST tree for FOR code built out
 * STRATEGY:
 *
 *		       for statement look like so:
 *
 *			    FOR IDENT = EXPR to EXPR [ STEP EXPR ]
 *				Block of Code
 *			    NEXT IDENT
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 8/94		Initial version			     
 * 
 *********************************************************************/
Node
Parse_For(TaskPtr	task,
	 VMBlockHandle	tree,
	 ScannerState	*state)
{
    Node	    expr, fornode, codenode, nextNode;
    Token	    token;
    VMFileHandle    vmfile;
    ErrorCode	err;

    vmfile = task->vmHandle;

    /* allocate a FOR node */
    fornode = HT_AllocTokenNode(FOR, state->lineNum, 0, 5);

    /* make sure the next node is an identifier */
    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    if (token.code != IDENTIFIER) {
	err = E_EXPECT_IDENT;
	goto ident_unlock_err_done;
    }

    /* add a child for the identifier */
    expr = HT_AllocTokenNode(IDENTIFIER, token.lineNum, token.data.key, 0);
    HugeTreeAppendChild(vmfile, tree, fornode, PREALLOC, expr);


    /* now make sure we got the equal sign */
    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    if (token.code != EQUALS)
    {
	err = E_NO_EQUALS;
	goto unlock_err_done;
    }

    /* parse off the first expression */
    expr = Parse_Expr(task, tree, state, FALSE, &token, MIN_PREC);
    HugeTreeAppendChild(vmfile, tree, fornode, PREALLOC, expr);

    /* last token parsed by Parse_Expr was returned in token, it had better
     * be a TO
     */
    if (token.code != TO)
    {
	err = E_NO_TO;
	goto unlock_err_done;
    }

    /* parse off the next expression directly */
    expr = Parse_Expr(task, tree, state, FALSE, &token, MIN_PREC);
    if (expr == NullNode) goto unlock_err_done;
	
    HugeTreeAppendChild(vmfile, tree, fornode, PREALLOC, expr);

    /* last token parsed by Parse_Expr was returned in token, it might
     * be a STEP
     */
    if (token.code == STEP)
    {
	expr = Parse_Expr(task, tree, state, FALSE, &token, MIN_PREC);
	if (expr == NullNode) goto unlock_err_done;
    }
    else
    {
	/* default step of 1 */
	expr = HT_AllocTokenNode(CONST_INT, token.lineNum, 1, 0);
    }
    HugeTreeAppendChild(vmfile, tree, fornode, PREALLOC, expr);

    codenode = HT_AllocTokenNode(NULLCODE, token.lineNum,
				 0, BLOCK_OF_CODE_MAX_LINES);
    token = Parse_BlockOfCode(task, tree, codenode, state);
    if (token.code != NEXT)
    {
	err = E_NO_NEXT;
	goto err_done;
    }
    HugeTreeAppendChild(vmfile, tree, fornode, PREALLOC, codenode);

    /* Append a NEXT node so we can generate line label information
       for it--(let the user skip over it, step into it, etc.) */
    
    nextNode = HT_AllocTokenNode(NEXT, token.lineNum, 0, 0);
    HugeTreeAppendChild(vmfile, tree, fornode, PREALLOC, nextNode);

    /* we need to chew up the next token, which will either be the
     * IDENT for the loop, or an EOL since the IDENT is optional
     */
    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    if (token.code != IDENTIFIER && !LINE_TERM(token.code))
    {
	err = E_NO_EOL;
	goto	err_done;
    }
    return fornode;	

 unlock_err_done:
 err_done:
    SetError(task, err);
    return NullNode;
 ident_unlock_err_done:
    SetIdentError(task, token.code);
    return NullNode;
}

/*********************************************************************
 *			Parse_FormalParam
 *********************************************************************
 * SYNOPSIS:	parse a formal parameter
 * CALLED BY:	Parse_Function
 * RETURN:	true if no errors
 * SIDE EFFECTS:
 * STRATEGY:	formal paramters have this form:
 *		    INDENTIFIER [COMMA | CLOSE_PAREN | 
 *                               [ [OPEN_BRACKET CLOSE_BRACKET] AS 
 *                                               <type> [COMMA | CLOSE_PAREN]]
 *              English: Right now, type is optional except
 *                       in cases when we are declaring things as an array.
 *
 *		so look for that pattern
 *
 *	Tree output looks like:
 *	(array)		(typed param)	(untyped param)
 *	
 *	Ident(name) 	Ident(name)	Ident(name)
 *	 Type		 Type
 *	  isArray
 *
 *	If the type is STRUCT then the type node will contain the name
 *	of the struct
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 7/94		Initial version			     
 * 
 *********************************************************************/
Boolean
Parse_FormalParam(TaskPtr	task,
		  VMBlockHandle	tree, 
		  Node		root, 
		  ScannerState	*state,
		  int		num)
{
    ErrorCode	err;
    Token	token;
    Node	ident, type;
    VMFileHandle vmfile = task->vmHandle;
    int	 	isarray;
    Token   	oldToken;


    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);

    if (token.code != IDENTIFIER)
    {
	/* a close paren is ok, anything else is an error */
	if (token.code != CLOSE_PAREN) {
	    SetError(task, E_BAD_FORMAL_PARAM);
	}
	return FALSE;
    }

    /* allocate	IDENT node and put it under tree
     */
    ident = HT_AllocTokenNode(IDENTIFIER, token.lineNum, token.data.key, 1);
    Parse_SET_NTH(root, num, ident);

    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    oldToken = token;
    /* If followed by [] then set isarray
     */
    if (token.code == OPEN_BRACKET)
    {
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	Parse_ERROR_IF(token.code != CLOSE_BRACKET, E_BAD_FORMAL_PARAM,
		       error_done);
	isarray = 1;

	/* now parse the AS */
	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
    }
    else 
    {
	isarray = 0;
    }

    /* Allow non-arrays to have no AS <type>
     */
    if (isarray == 0 && (token.code == COMMA || token.code == 
			     CLOSE_PAREN)) 
    {
	ScannerPushToken(state, oldToken);
	/* The IDENT node simply has no child in this case... */
	return TRUE;
    }
	
    if (token.code != AS)
    {
	SetError(task, E_BAD_FORMAL_PARAM);
	return FALSE;
    }

    /* Identifier's child is a type node.
     * Add a (non-token) child to type if it is an array.
     */
    type = Parse_Type(task, tree, state);
    if (type == NullNode) return NullNode;
    Parse_APPEND_CHILD(ident, type);
    if (isarray) {
	HugeTreeAppendChild(vmfile, tree, type, 1, 0);
    }

    return  TRUE;

 error_done:
    SetError(task, err);
    return FALSE;
}



/*********************************************************************
 *			Parse_ResetConstantsForFunction
 *********************************************************************
 * SYNOPSIS:	reset constants for functions
 * CALLED BY:	Parse_Functions
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	1/ 9/96	Initial version
 * 
 *********************************************************************/
void
Parse_ResetConstantsForFunction(TaskPtr task)
{
    int    count, i;
    ConstantInfo    ci;

    count = StringTableGetCount(SYMBOLIC_CONST_TABLE);
    for (i = 0; i < count; i++)
    {
	StringTableGetDataPtr(SYMBOLIC_CONST_TABLE, i, sizeof(ci),
			      (void *)&ci);
	if (ci.funcNumber == task->funcNumber)
	{
	    TCHAR   *name;

	    ci.funcNumber = CONSTANT_CLEARED;
	    name = StringTableLock(SYMBOLIC_CONST_TABLE, i);
	    StringTableAddWithData(SYMBOLIC_CONST_TABLE, name, sizeof(ci),
				   (void *)&ci);
	    StringTableUnlock(name);
	}
    }
}

/*********************************************************************
 *			Parse_CheckForDdeletedConstants
 *********************************************************************
 * SYNOPSIS:	reset constants for functions
 * CALLED BY:	Parse_Functions
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	1/ 9/96	Initial version
 * 
 *********************************************************************/
Boolean
Parse_CheckForDeletedConstants(TaskPtr task)
{
    int    count, i, retval = FALSE;
    ConstantInfo    ci;

    count = StringTableGetCount(SYMBOLIC_CONST_TABLE);
    for (i = 0; i < count; i++)
    {
	StringTableGetDataPtr(SYMBOLIC_CONST_TABLE, i, sizeof(ci), 
			      (void *)&ci);
	if (ci.funcNumber == CONSTANT_CLEARED)
	{
	    TCHAR   *name;

	    retval = TRUE;
	    ci.funcNumber = CONSTANT_DELETED;
	    name = StringTableLock(SYMBOLIC_CONST_TABLE, i);
	    StringTableAddWithData(SYMBOLIC_CONST_TABLE, name, sizeof(ci),
				   (void *)&ci);
	    StringTableUnlock(name);
	}
    }
    return retval;
}

/*********************************************************************
 *			Parse_Function
 *********************************************************************
 * SYNOPSIS:	high level parse routine to parse a function
 * CALLED BY:	
 * RETURN:      If error occurs, it's returned in lineNum.
 *              Returns tree as a VMBLockHandle, and if we can
 *              determine
 *              the type we fill it in the type parameter.
 * SIDE EFFECTS:
 * STRATEGY:
 *	tree looks like:
 *	SUB | FUNCTION
 *	  # parameters
 *	  Ident		(parameters)
 *	    type
 *	  [...]
 *	  type		(if function, function return type goes here)
 *	  code subtree
 *	  
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 6/94		Initial version			     
 * 
 *********************************************************************/
#define MAX_LINES_PER_FUNC 250
VMBlockHandle
Parse_Function(TaskPtr task, word funcNumber)
{
    Node	root, num, codeNode, endNode;
    VMFileHandle    vmfile;
    VMBlockHandle   tree;
    Token	token;
    int		i;
    BascoFuncType	ft;
    TokenCode	tc;
    FTabEntry*	ftab;
    word	numParams;
    ScannerState    state;

    ftab = FTabLock(task->funcTable, funcNumber);

    /* Reset tree-specific things in the ftab */
    ftab->hasErrorTrap = FALSE;
    ftab->hasResumeNext = FALSE;
    if (ftab->tree != NullHandle) 
    {
	/* dubois 5/22/96, testing out destroying trees after codegen
	 * they should never be left around
	 * FIXME I guess they should be destroyed on errors too
	 */
	EC_WARNING_IF(ftab->lastCompileError==NONE,-1);
	HugeTreeDestroy(task->vmHandle, ftab->tree);
	ftab->tree = NullHandle;
    }
    if (ftab->labelNameTable != NullOptr)
    {
	LMemFree(ftab->labelNameTable);
	ftab->labelNameTable = NullOptr;
    }

    ft = ftab->funcType;
    vmfile = task->vmHandle;

    Parse_ResetConstantsForFunction(task);

    /* initialize our scanner state starting with the first line */
    ScannerInitState(&state, task, ftab->lineElement);


    /* now lets scan through the line, first, get the FUNCTION token */
    token = ScannerGetToken(&state, ID_TABLE, CONST_TABLE, FALSE);

    /* make sure the function or subroutine is what it should be */
    if ((ft == FT_FUNCTION && token.code != FUNCTION) ||
	(ft == FT_SUBROUTINE && token.code != SUB))
    {
	SetError(task, E_BAD_FUNCTION_DECL);
	goto err_done;
    }

    /* now get the IDENTIFIER (or a global token) */
    token = ScannerGetToken(&state, ID_TABLE, CONST_TABLE, FALSE);

    if (token.code != IDENTIFIER)
    {
	SetError(task, E_BAD_FUNCTION_DECL);
	goto err_done;
    }

    tree = task->tree = HugeTreeCreate(vmfile);

    if (ft == FT_FUNCTION) {
	tc = FUNCTION;
    } else {
	tc = SUB;
    }

    /* allocate FUNCTION or SUB node and put it under tree */
    root = HT_AllocTokenNode(tc, token.lineNum,
			    token.data.key, BLOCK_OF_CODE_MAX_LINES);

    token = ScannerGetToken(&state, ID_TABLE, CONST_TABLE, FALSE);
    if (token.code != OPEN_PAREN)
    {
	SetError(task, E_BAD_FUNCTION_DECL);
	goto err_done;
    }

    /* allocate a node for each paramter, starting as the second or
     * third child the first child will be the number of parameters,
     * the second child will be for the return type, if this is a
     * function
     */
    for (i=1; 1; i++)
    {

	if (!Parse_FormalParam(task, task->tree, root, &state, i))
	{
	    /* might have been an error, might have been a CLOSE_PAREN for
	     * case of no parameters, check to make sure we are at the
	     * first param, or its an error either way
	     */
	    if (i != 1)
	    {
		SetError(task, E_BAD_FORMAL_PARAM);
	    }
	    i--;
	    break;
	}

	token = ScannerGetToken(&state, ID_TABLE, CONST_TABLE, FALSE);

	if (token.code == CLOSE_PAREN)
	{
	    break;
	}
	if (token.code != COMMA)
	{
	    SetError(task, E_BAD_FORMAL_PARAM);
	    break;
	}

    }
    numParams = i;
    num = HT_AllocTokenNode(CONST_INT, token.lineNum, numParams, 0);
    Parse_SET_NTH(root, 0, num);

    if (numParams > 254) {
	/* Leave one because we might add one more for return value... */
	SetError(task, E_TOO_MANY_PARAMS);
    }

    /* Functions can optionally specify a return type and both functions
     * and subroutines can declare themselves to be global
     */
    token = ScannerGetToken(&state, ID_TABLE, CONST_TABLE, FALSE);

    /* if its a global token, mark the routine as global and
     * scan next token, should be an indentifier 
     */
    if (token.code == GLOBAL) 
    {
	ftab->global = TRUE;

	/* now get the AS token or an EOF */
	token = ScannerGetToken(&state, ID_TABLE, CONST_TABLE, FALSE);
    }

    if (ft == FT_FUNCTION)
    {
	Node	typeNode;

	if (token.code == AS)
	{
	    /* if it has an AS then parse the TYPE and then grab the EOF */
	    typeNode = Parse_Type(task, task->tree, &state);
	    if (typeNode != NullNode) {
		token = ScannerGetToken(&state, ID_TABLE, CONST_TABLE, FALSE);
	    }
	} 
	else
	{
	    /* TYPENONE is a lousy kludge, just there so TokenToType
	     * can convert it to TYPE_NONE */
	    typeNode = Parse_ALLOC_NODE(TYPENONE, 0, 0, 0);
	}
	if (typeNode != NullNode)
	{
	    Parse_APPEND_CHILD(root, typeNode);
	}
    }

    /* Should be at end of line by now
     */
    if ( !LINE_TERM(token.code) ) {
	SetError(task, E_BAD_FUNCTION_DECL);
    }

    /* check for errors from Parse_FormalParams, after unlocking the line */
    if (ERROR_SET)
    {
	goto err_done;
    }
    /* now add all the code for the routine
     */
    codeNode = HT_AllocTokenNode(NULLCODE, token.lineNum, 
				 0, BLOCK_OF_CODE_MAX_LINES);
    token =  Parse_BlockOfCode(task, task->tree, codeNode, &state);
    ftab = FTabDeref(task->funcTable, funcNumber);

    /* make sure we ended properly */
    if (token.code != END)
    {
	SetError(task, E_NO_ENDFUNCTION);
	goto err_done;
    }

    Parse_APPEND_CHILD(root, codeNode);

    token = ScannerGetToken(&state, CONST_TABLE, CONST_TABLE, FALSE);
    if ((ft == FT_FUNCTION && token.code != FUNCTION) ||
	(ft == FT_SUBROUTINE && token.code != SUB))
    {
	SetError(task, E_NO_ENDFUNCTION);
	goto err_done;
    }

    /* We want line number information for ends of routines,
       so we will spit out a node to mark the routine end.
       The line number is all we use it for...
    */

    endNode = HT_AllocTokenNode(END, token.lineNum,
				0, 0);

    HugeTreeAppendChild(vmfile, task->tree, root, PREALLOC, endNode); 

    ftab->tree             = task->tree;
    ftab->size             = 0;
    ftab->startSeg         = 0;
    /* This number does NOT include the potential "return value"
       argument that every function requires.
    */

    ftab->numParams        = numParams;
    ftab->compStatus       = CS_PARSED;
    FTabUnlock(ftab);

    /* if a constant went away, force a full recompile */
    if (Parse_CheckForDeletedConstants(task))
    {
	task->flags |= COMPILE_NEEDS_FULL_RECOMPILE;
    }
    ScannerClean(&state);
    return task->tree;

 err_done:
    FTabUnlock(ftab);
    task->ln = state.lineNum;
    ScannerClean(&state);
    return NullHandle;
}

/*********************************************************************
 *			Parse_CompInit
 *********************************************************************
 * SYNOPSIS:	parse an CompInit statement
 * CALLED BY:	Parse_BlockOfCode
 * RETURN:	COMP_INIT node is AST tree
 * SIDE EFFECTS: an AST tree of the if statement is built out
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/ 8/94		Initial version			     
 * 
 *********************************************************************/
Node
Parse_CompInit(TaskPtr	    	task,
	       VMBlockHandle	tree,
	       ScannerState 	*state)
{
    Node	    topnode, comp;
    Token	    token;
    VMFileHandle    vmfile;
    Token   	    compdata, *compPtr;

    vmfile = task->vmHandle;

    topnode = HT_AllocTokenNode(COMP_INIT, state->lineNum, 0, 
				BLOCK_OF_CODE_MAX_LINES);

    /* this is overkill, as (for now) we are only expecting a literal
     * but what the hell
     */
    comp = Parse_Expr(task, tree, state, FALSE, &token, MIN_PREC);
    
    if (comp == NullNode || !LINE_TERM(token.code))
    {
	SetError(task, E_NO_EOL);
	return NullNode;
    }

    compPtr = HT_Lock(comp);
    compdata = *compPtr;
    HugeTreeUnlock(compPtr);

    HugeTreeAppendChild(vmfile, tree, topnode, PREALLOC, comp);


    /* now loop through the property settings creating pairs of nodes
     * that get added to the tree under the topnode
     */
    while(1)
    {
	Node    propNode, valNode, compNode, nameNode;
	Token	lastTok;

	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);

	if (LINE_TERM(token.code)) {
	    continue;
	}

	if (token.code == END)
	{
	    token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	    if (token.code != COMP_INIT) 
	    {
		SetError(task, E_SYNTAX);
		return NullNode;
	    }
	    return topnode;
	}

	/* should be an identifier for a property name */
	if (token.code != IDENTIFIER)
	{
	    SetIdentError(task, token.code);
	    return NullNode;
	}

	/* create a property node using the compdata from above and the
	 * new property data
	 */
	propNode = Parse_ALLOC_NODE(PROPERTY, state->lineNum, 0, 2);
	compNode = Parse_ALLOC_NODE(IDENTIFIER, state->lineNum, compdata.data.key, 0);
	nameNode = Parse_ALLOC_NODE(CONST_STRING, state->lineNum, token.data.key, 0);

	Parse_APPEND_CHILD(topnode, propNode);
	Parse_SET_NTH(propNode, 0, compNode);
	Parse_SET_NTH(propNode, 1, nameNode);

	token = ScannerGetToken(state, ID_TABLE, CONST_TABLE, FALSE);
	if (token.code != EQUALS)
	{
	    SetError(task, E_NO_EQUALS);
	    return NullNode;
	}

	/* now we are only expecting constant values here */
	token = Parse_ConstantExpression(task, tree, state, &lastTok);
	if (task->err_code != NONE)
	{
	    return NullNode;
	}
	valNode = HT_AllocTokenNode(token.code, state->lineNum, 
				    token.data.key, 0);
	HugeTreeAppendChild(vmfile, tree, topnode, PREALLOC, valNode);
    }
}










