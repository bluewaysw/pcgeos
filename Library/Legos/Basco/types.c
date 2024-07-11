/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	L E G O S
MODULE:		Basco
FILE:		types.c

AUTHOR:		Roy Goldman, Apr 21, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 4/21/95   	Initial version.

DESCRIPTION:
	
        Type checker
	
	The type-checking phase should directly follow variable analysis.
	It is simply a depth first recursive traversal of the parse tree,
	checking types for operations and propagating types up the tree.

	The one other function it performs is to insert additional
	nodes to indicate coercion from one type to another.

	All typing is implemented through a new word-sized slot
	on each parse tree node which stores a type (currently
	a code-generation opcode).
	
	We use TYPE_UNKNOWN to represent types of nodes whose type
	cannot be determined at compile time. A perfect example of
	this is a intermodule function call; we don't know what the
	type of its return value is.

	When TYPE_UNKNOWN is encountered at code generation time,
	we emit general purpose code to do type checking at runtime.

	TYPE_UNKNOWN is currently the default type for all nodes.
	It will be ignored in certain cases, like the FOR node; its
	type is irrelevant.

	We never generate any code using TYPE_UNKNOWN; it's only useful
	for analysis. Hence it's not an actual opcode, and is instead
	defined to be TYPE_ILLEGAL to help conserve opcodes...

	$Id: types.c,v 1.1 98/10/13 21:43:47 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <limits.h>
#include "bascoint.h"
#include "types.h"
#include "typesint.h"
#include "btoken.h"
#include "stable.h"
#include "table.h"
#include "vars.h"

/* include this to get HT_AllocTokenNode.. */

#include "parseint.h"
#include <Legos/legtype.h>

#include <tree.h>

#include "comptime.h"

/* math hack from runtime engine */
extern long SmartTrunc(float number);

/*********************************************************************
 *			TypeCheckFunction
 *********************************************************************
 * SYNOPSIS:	Type check a function
 * CALLED BY:	
 * RETURN:      True if no errors, else false (with error set in task)
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 4/21/95	Initial version			     
 * 
 *********************************************************************/
Boolean
TypeCheckFunction(TaskPtr task, word funcNumber) 
{
    FTabEntry*	ftab;
    Boolean	retVal;

    ftab = FTabLock(task->funcTable, funcNumber);

    task->tree       = ftab->tree;
    task->funcNumber = funcNumber;

    FTabUnlock(ftab);

    if (ET_TYPE(Type_Check(task, TREE_ROOT)) == TYPE_ERROR)
    {
	SetError(task, E_TYPE_MISMATCH);
    }
    retVal = (task->err_code == NONE);

    if (retVal)
    {
	ftab = FTabLock(task->funcTable, funcNumber);
	ftab->compStatus = CS_TYPE_CHECKED;
	FTabDirty(ftab);
	FTabUnlock(ftab);
    }
    return retVal;
}
	
/* what kind of typing information must be checked and established.

       Examples of different nodes:

       - It's a constant, variable, (or eventually a function call).
         These are leaves.  Simply record their type within the node.

       - It's an arithmetic or relational operator or an assignment.
         Check to see if children are compatible for the operation to occur.
         If a child must be coerced (upgraded) to a float, mark it
         so. This coercion mechanism could also be used for allowing
         arithmetic with integer strings, though things could get a
         bit tricky.  If the operation is possible, we then label
	 the operator node itself with the resultant type.

       - It's another node which requires that one or more of its children
         is of a certain type.  For example, in a while loop, we
	 require that the expression node be a number of some sort.
	 We do similar work with for/loops.  Coercion of children
	 would also be possible.  Note that we do not, however, mark
	 the node with a type. For loops and while loops do not have 
	 useful types.

  */

/*********************************************************************
 *			Type_CheckChildren
 *********************************************************************
 * SYNOPSIS:	Utility routine to help with the tree recursion
 * CALLED BY:	
 * RETURN:	TRUE if all children were checked successfully
 * SIDE EFFECTS:
 * STRATEGY:
 *	Check children starting from child <initial>
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/31/95	Initial version
 * 
 *********************************************************************/
Boolean
Type_CheckChildren(TaskPtr task, Node parent, byte initial)
{
    word	num, i;

    num = HugeTreeGetNumChildren(task->vmHandle, task->tree, parent);
    for (i = initial; i < num; i++) {
	if (ET_TYPE(Type_Check(task, CurTree_GET_NTH(parent, i)))
	    == TYPE_ERROR)
	{
	    return FALSE;
	}
    }
    return TRUE;
}

/*********************************************************************
 *			Type_Check
 *********************************************************************
 * SYNOPSIS:	Traverse a routine's parse tree,
 *              checking and marking types as we go.
 *              Also, adds coercion nodes where necessary
 * CALLED BY:	
 * RETURN:	LegosType of node just checked
 * SIDE EFFECTS:
 * STRATEGY:
 *
 * Depth first traversal; for each node check types of children
 * and establish a type for the current node.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 4/21/95	Initial version			     
 * 
 *********************************************************************/
ExtendedType
Type_Check(TaskPtr task, Node node)
{
    Token*	token;		/* for scratch use within the switch */
    TokenData	data;
    TokenCode	code;
    
    /* These fields will be written back out to the node after the switch
     */
    LegosType	retType;
    word	typeData = 0xffff; /* default to null string/null vtab */

    EC_ERROR_IF(node == NullNode, BE_FAILED_ASSERTION);

    /* Initialize vars from the token
     * Special-case identifiers here, which start out with types
     * TYPE_VOID is a hacked signal that means this node needs more work
     */
    token = CurTree_LOCK(node);
    code = token->code;
    retType = token->type;
    if (code == IDENTIFIER && token->type != TYPE_VOID)
    {
	typeData = token->typeData;
	HugeTreeUnlock(token);
	return MAKE_ET(typeData, retType);
    }
    data = token->data;
    task->ln = token->lineNum;
    HugeTreeUnlock(token);
    
    switch(code)
    {
    case MODULE_CALL:
    case MODULE_REF:
    {
	LegosType t1;
	
	t1 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 1)));
	if ((t1 != TYPE_UNKNOWN) && (t1 != TYPE_MODULE)) {
	    goto mismatch_done;
	}
	if (!Type_CheckChildren(task, node, 2)) {
	    goto    error_done;
	}

	retType = TYPE_UNKNOWN;
	break;
    }

    case PROPERTY:
    case ACTION:
    {
	Node		compNode;
	Token*		compToken;
	LegosType	tmpType;

	/* First child must be a component
	 */
	compNode = CurTree_GET_NTH(node, 0);
	tmpType = ET_TYPE(Type_Check(task, compNode));
	if (tmpType == TYPE_ERROR) {
	    goto error_done;
	}

	/* This is a pretty safe-looking hack... if we get a property
	 * ref but child 0 is a struct, it just means user used PERIOD
	 * instead of CARET.  This should be cleaned up by just moving
	 * the code for STRUCT_REF in here; using GOTO means child 0
	 * will be typechecked twice, no biggie.  Also, property/action
	 * strings should initially be in the ID table instead of the
	 * CONST table.  They only need to be in the CONST table if the
	 * prop/action isn't resolved.
	 */
	if (tmpType == TYPE_STRUCT && code == PROPERTY)
	{
	    Token*	tmpTok;
	    TCHAR*	constStr;

	    tmpTok = CurTree_LOCK(node);
	    tmpTok->code = STRUCT_REF;
	    HugeTreeDirty(tmpTok);
	    HugeTreeUnlock(tmpTok);

	    tmpTok = CurTree_LOCK(CurTree_GET_NTH(node, 1));
	    if (tmpTok->code == CONST_STRING)
	    {
		/* It might be some kind of expression, in which case
		 * this will be caught in the struct_ref code
		 */
		constStr = StringTableLock(ID_TABLE, tmpTok->data.key);
		tmpTok->code = INTERNAL_IDENTIFIER;
		tmpTok->data.key = StringTableAdd(ID_TABLE, constStr);
		StringTableUnlock(constStr);
		HugeTreeDirty(tmpTok);
	    }
	    HugeTreeUnlock(tmpTok);

	    goto STRUCT_REF_LABEL;
	}

	if (tmpType != TYPE_COMPONENT && tmpType != TYPE_UNKNOWN) {
	    goto mismatch_done;
	}

	if (ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 1)))!=TYPE_STRING)
	    goto mismatch_done;
	if (!Type_CheckChildren(task, node, 2))
	    goto error_done;

	retType = TYPE_UNKNOWN;

	/* If we can, pre-resolve property and action references
	 */
	compToken = CurTree_LOCK(compNode);
	if (compToken->typeData == (word)NullElement ||
	    task->flags & COMPILE_BUILD_TIME)
	{
	    /* Not a specific component type -- bail
	     */
	    HugeTreeUnlock(compToken);
	} else {
	    optr	comp;
	    word	chunk;
	    ExtendedType et;
	    word    	numParams;

	    HugeTreeUnlock(compToken);
	    chunk = StringTableGetData(task->compTypeNameTable,
				       compToken->typeData);
	    comp = ConstructOptr(task->compTypeObjBlock, chunk);
	    et = Type_ResolvePropOrAction(task, node, comp, code, &numParams);
	    retType = ET_TYPE(et);
	    if (retType == TYPE_ERROR) {
		goto	error_done;
	    }
	    typeData = ET_DATA(et);
	    if (code == ACTION && numParams != 0xffff)
	    {
		/* check number of params if its fixed and known at compile
		 * time - the first 3 children are the compoment, the action
		 * and the number of params, so just subtract 3 from the
		 * number of children to get the number of params
		 */
		if (numParams != HugeTreeGetNumChildren(task->vmHandle,
							task->tree, node) - 3)
		{
		    SetError(task, E_BAD_NUM_PARAMS);
		    goto    error_done;
		}
	    }
	}
	break;
    }

    case BUILT_IN_FUNC:
    {
	/* we want to check for MakeComponent calls, so we can return
	 * a specific component type.
	 */
	if (data.key == FUNCTION_MAKE_COMPONENT)
	{
	    Node	arg1Node;
	    Token*	arg1Tok;
	    TCHAR*	str;
	    LegosType	t1;

	    retType = TYPE_COMPONENT;

	    /* Require arg 1 to be a string
	     */
	    arg1Node = CurTree_GET_NTH(node, 0);
	    t1 = ET_TYPE(Type_Check(task, arg1Node));

	    if ((t1 != TYPE_STRING && t1 != TYPE_UNKNOWN) ||
		!Type_CheckChildren(task, node, 1))
	    {
		goto mismatch_done;
	    }

	    /* If the first arg is a string constant, try and match it to
	     * a string in the compTypeNameTable.  If it doesn't match,
	     * or it isn't a string const that's OK, typeData will be set
	     * to NullElement, which means "not a specific component type"
	     */
	    arg1Tok = CurTree_LOCK(arg1Node);
	    if (arg1Tok->code == CONST_STRING)
	    {
		str = StringTableLock(CONST_TABLE, arg1Tok->data.key);
		typeData = StringTableLookupString(task->compTypeNameTable,
						   str);
		StringTableUnlock(str);
	    } else {
		typeData = NullElement;
	    }
	    HugeTreeUnlock(arg1Tok);
	}
	else
	{
	    BascoBuiltInEntry*	fe;
	    int	    	    	i;
	    LegosType	    	t1;

	    /* check return type and arguments to built in functions */

	    fe = MemLockFixedOrMovable(BuiltInFuncs);
	    fe += data.key; /* now points at appropriate offset */

	    retType = fe->returnType;

	    if (fe->numArgs != VARIABLE_NUM_ARGS)
	    {
		/* this should be caught in parse.c */
		EC_ERROR_IF(CurTree_NUM_CHILDREN(node)
			    != fe->numArgs, BE_FAILED_ASSERTION);

		for (i = 0; i < fe->numArgs; i++) 
		{
		    t1 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node,i)));
		    if (t1 == TYPE_ERROR) {
			MemUnlockFixedOrMovable(BuiltInFuncs);
			goto error_done;
		    }
		    if (fe->argTypes[i] != TYPE_UNKNOWN && 
			t1 != TYPE_UNKNOWN &&
			fe->argTypes[i] != t1 )
		    {
			if (isNumber(fe->argTypes[i]) && isNumber(t1)) 
			{
			    if (!Type_CoerceNth(task, node, i,
					   fe->argTypes[i], t1))
			    {
				goto error_done;
			    }
			}
			else if (!ET_ARRAY_TYPE(t1) ||
				 (fe->argTypes[i] != TYPE_ARRAY))
			{
			    MemUnlockFixedOrMovable(BuiltInFuncs);
			    goto mismatch_done;
			}
		    }
		}
	    } else {
		if (! Type_CheckChildren(task, node, 0)) goto error_done;
	    }

	    MemUnlockFixedOrMovable(BuiltInFuncs);
	}

	/* if we are not type void, make sure we are not being called
	 * as a subroutine
	 * FIXME: TYPE_VARIANT causes problems if it includes TYPE_VOID
	 */
	if (retType != TYPE_VOID && retType != TYPE_VARIANT)
	{
	    Node	parent;
	    Token	*tp;

	    parent = HugeTreeGetParent(task->vmHandle, task->tree, node);
	    /* this would only happen if somebody tried to use the built
	     * in function in a CompInit or CONST expression
	     */
	    if (parent == NullNode)
	    {
		SetError(task, E_NOT_CONSTANT_EXPRESSION);
		goto error_done;
	    }
	    tp = CurTree_LOCK(parent);
	    if (tp->code == NULLCODE)
	    {
		HugeTreeUnlock(tp);
		SetError(task, E_FUNC_NOT_USED_AS_RVAL);
		goto error_done;
	    }
	    HugeTreeUnlock(tp);
	}
	break;
    }

    case CONST_STRING:
    case CONST_INT:
    case CONST_LONG:
    case CONST_FLOAT:
    {
	/* be sure not to touch the typeData */
	retType = TokenToType(code);
	token = CurTree_LOCK(node);
	token->type = retType;
	HugeTreeDirty(token);
	HugeTreeUnlock(token);
	/* no reason to make the changes twice, so goto nochange_done */
	goto	nochange_done;
    }

    case STRUCT_REF:
    {
	ExtendedType	et;
	word		structVtab;
	VTabEntry	vte;
	Token*		fieldTok;
	dword		fieldKey;
	TokenCode	fieldCode;

	/* node: STRUCT_REF
	 * child 0: TYPE_STRUCT(struct name)
	 * child 1: CONST_STRING(const STABLE id -- name of struct field)
	 */

	if (0) {
 STRUCT_REF_LABEL:
	    /* If we're jumping here from PROPERTY, don't re-typecheck
	     * 'cause that has problems if the tree had COERCE nodes
	     * added
	     */
	    et = TypeOfNthChild(task, node, 0);
	} else {
	    et = Type_Check(task, CurTree_GET_NTH(node, 0));
	}

	if (ET_TYPE(et) != TYPE_STRUCT)	{
	    SetError(task, E_EXPECT_STRUCT_TYPE);
	    goto error_done;
	}

	fieldTok = CurTree_LOCK(CurTree_GET_NTH(node, 1));
	fieldCode = fieldTok->code;
	fieldKey = fieldTok->data.key;
	HugeTreeUnlock(fieldTok);

	if (fieldCode != INTERNAL_IDENTIFIER) {
	    SetError(task, E_NEED_EXPLICIT_STRUCT_FIELD);
	    goto error_done;
	}

	structVtab = StringTableGetData(STRUCT_TABLE, ET_DATA(et));
	if (!VTLookup(task->vtabHeap, structVtab, fieldKey, &vte, NULL)) {
	    SetError(task, E_UNDEFINED_STRUCT_FIELD);
	    goto error_done;
	}
	retType = vte.VTE_type;
	typeData = vte.VTE_extraInfo;
	break;
    }
    case ARRAY_REF:
    {
	ExtendedType et;
	byte	i, numDims;

	/* node: ARRAY_REF(num dims) 
	 *  child 0: TYPE_ARRAY(subtype)
	 *  child 1-: integral type, coerced to TYPE_INTEGER
	 *	OK to be TYPE_UNKNOWN, also
	 * retType: subtype
	 */
	et = Type_Check(task, CurTree_GET_NTH(node, 0));

	/* Must have an array, or UNKNOWN
	 * If unknown, don't try to do the only-one-dimension optimization,
	 * because we'll be using plain old OP_ARRAY_REF
	 */
	if (!ET_ARRAY_TYPE(et) && ET_TYPE(et) != TYPE_UNKNOWN)
	{
	    goto mismatch_done;
	}
	retType = ET_ARRAY_ELT_TYPE(et);
	typeData = ET_DATA(et);

	numDims = data.integer;
	for (i=1; i<=numDims; i++)
	{
	    LegosType	t1;
	    t1 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, i)));

	    if (!isNumber(t1) && t1 != TYPE_UNKNOWN) {
		goto mismatch_done;
	    }

	    if (t1 != TYPE_INTEGER && t1 != TYPE_UNKNOWN)
	    {
		if (!Type_CoerceNth(task, node, i, TYPE_INTEGER, t1))
		{
		    goto error_done;
		}
	    }
	}

	/* use special opcodes for certain cases
	 * Why is done during typechecking instead of codegen? --dubois
	 */
	if (numDims == 1 && ET_TYPE(et) != TYPE_UNKNOWN)
	{
	    Token*	indexTok;

	    indexTok = CurTree_LOCK(CurTree_GET_NTH(node, 1));
	    token = CurTree_LOCK(node);
	    switch (indexTok->code)
	    {
	    case IDENTIFIER:
		if (VAR_KEY_TYPE(indexTok->data.key) == VAR_LOCAL)
		{
		    token->code = ARRAY_REF_L1;
		}
		else 
		{
		    token->code = ARRAY_REF_M1;
		}
		token->data.key = indexTok->data.key;
		break;
	    case CONST_INT:
		token->code = ARRAY_REF_C1;
		/* stuff typeData info (in case its a constant) into
		 * the high word of the key
		 */
		token->data.key = (long) indexTok->data.integer | 
		    (long)((long)token->typeData << 16);
		break;
	    }
	    HugeTreeDirty(token);
	    HugeTreeUnlock(token);
	    HugeTreeUnlock(indexTok);
	}

	break;
    }

    case USER_FUNC:
    case USER_PROC:
    {
	ExtendedType	et;

	et = Type_CheckRoutineCall(task, node);
	retType = ET_TYPE(et);
	typeData = ET_DATA(et);
	break;
    }

    case AND:
    case OR:
    case XOR:
    {
	LegosType	t1, t2;

	/* Binary operators which take ints/longs and return integers
	 */
	/* Right now we assume we're doing logical operations,
	 * but we still require that operands are not floats
	 */

	t1 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 0)));
	t2 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 1)));

	if (!( (isInteger(t1) && isInteger(t2)) ||
	       SafeForUnknownAndInteger(t1,t2) ))
	{
	    goto mismatch_done;
	}

	retType = TYPE_INTEGER;
	break;
    }	

    case NOT:
    {
	LegosType	t1;

	/* Similar to And/or/xor above but unary */

	t1 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 0)));

	if (isInteger(t1) || t1 == TYPE_UNKNOWN) {
	    retType = TYPE_INTEGER;
	    break;
	} else {
	    goto mismatch_done;
	}
    }

    case MOD:
    case MULTIPLY:
    case DIVIDE:
    case MINUS:
    case PLUS:
    case BIT_AND:
    case BIT_OR:
    case BIT_XOR:
    {
	LegosType	t1, t2;

	/* Operators which always take and return numbers, except for PLUS
	 */

	t1 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 0)));
	if (t1 == TYPE_ERROR) goto error_done;
	t2 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 1)));
	if (t2 == TYPE_ERROR) goto error_done;

	if (code == PLUS && t1 == TYPE_STRING && t2 == TYPE_STRING) 
	{
	    retType = TYPE_STRING;
	    break;
	}

        if (code == BIT_AND || code == BIT_OR || code == BIT_XOR)
	{
	    if (!(isInteger(t1) || isInteger(t2)))
	    {
		goto mismatch_done;
	    }
	}

	if (isNumber(t1) && isNumber(t2))
	{
	    Token   t;
	    t = EvalConstantExpression(task, node, code);
	    if (ERROR_SET) {
		goto error_done;
	    }
	    if (isNumber(t.type))
	    {
		return MAKE_ET(0xffff, t.type);
	    }

	    retType = ArithResultType(t1,t2);
	    
	    if (retType != t1) {
		if (!Type_CoerceNth(task, node, 0, retType, t1)) {
		    goto error_done;
		}
	    }
	    if (retType != t2) {
		if (!Type_CoerceNth(task, node, 1, retType, t2)) {
		    goto error_done;
		}
	    }
	}
	else if (SafeForUnknownAndNumber(t1,t2))
	{
	    retType = TYPE_UNKNOWN;
	} 
	else if (code == PLUS && SafeForUnknown(t1, t2, TYPE_STRING))
	{
	    if (t1 == TYPE_STRING || t2 == TYPE_STRING) {
		retType = TYPE_STRING;
	    }
	    else {
		retType = TYPE_UNKNOWN;
	    }
	}
	else
	{
	    goto mismatch_done;
	}

	break;
    }

    case POSITIVE:
    case NEGATIVE:
    {
	LegosType	t1;
	Token	    	*childPtr, *nodePtr;

	/* Unary operators which take a number and always return
	 * the same kind of number
	 * evaluate constant values now
	 */
	t1 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 0)));
	childPtr = CurTree_LOCK(CurTree_GET_NTH(node, 0));
	if (isNumericConstant(childPtr->code))
	{
	    nodePtr = CurTree_LOCK(node);
	    nodePtr->type = childPtr->type;
	    if (code == POSITIVE) {
		nodePtr->data.key = childPtr->data.key;
	    } else {
		switch(childPtr->type) {
		case TYPE_INTEGER:
		    nodePtr->code = CONST_INT;
		    nodePtr->data.key = -(childPtr->data.integer);
		    break;
		case TYPE_LONG:
		    nodePtr->code = CONST_LONG;
		    nodePtr->data.key = -(childPtr->data.key);
		    break;
		case TYPE_FLOAT:
		    nodePtr->code = CONST_FLOAT;
		    *(float *)&nodePtr->data.key = 
			    	- (float)(*(float *)&childPtr->data.key);
		    break;
		}
	    }
	    HugeTreeDirty(nodePtr);
	    HugeTreeUnlock(nodePtr);
	    HugeTreeUnlock(childPtr);
	    return t1;
	} else {
	    HugeTreeUnlock(childPtr);
	}

	if (isNumber(t1) || t1 == TYPE_UNKNOWN) {
	    retType = t1;
	    break;
	} else {
	    goto mismatch_done;
	}
    }

    case LESS_THAN:
    case GREATER_THAN:
    case LESS_EQUAL:
    case GREATER_EQUAL:
    case LESS_GREATER:
    case EQUALS:
    {
	LegosType	t1, t2, maxType;
	
	/* Takes two strings and returns an integer OR
	 * takes two numbers and returns an integer OR
	 * takes two components and returns an integer (EQUALS and
	 * LESS_GREATER only)
	 */
	t1 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 0)));
	t2 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 1)));

	if (t1 == t2)
	{
	    retType = TYPE_INTEGER;
	    break;
	}

	if ((isNumber(t1) && isNumber(t2))) {
	    maxType = ArithResultType(t1,t2);

	    /* Still need coercion to make comparisons work */
	    retType = TYPE_INTEGER;
	    if (maxType != t1) {
		if (!Type_CoerceNth(task, node, 0, maxType, t1)) {
		    goto error_done;
		}
	    }

	    if (maxType != t2) {
		if (!Type_CoerceNth(task, node, 1, maxType, t2)) {
		    goto error_done;
		}
	    }

	    break;
	}

	/* Allow numbers,strings,components and unknown to be mixed
	 * The latter two are allowed only for comparisons
	 * (this also allows unknown unknown)
	 */
	if (SafeForUnknownAndNumber(t1,t2) ||
	    (((code == LESS_GREATER) || (code == EQUALS)) 
	     && (SafeForUnknown(t1,t2,TYPE_STRING) ||
		 SafeForUnknown(t1,t2,TYPE_COMPONENT))))
	{
	    retType = TYPE_INTEGER;
	    break;
	}
	goto mismatch_done;
    }	

    case ASSIGN:	
    {
	ExtendedType	et1, et2;

	retType = TYPE_VOID;

	/* Compatible left and right types
	 * type: TYPE_NONE
	 */
	et1 = Type_Check(task, CurTree_GET_NTH(node, 0));
	if (ET_TYPE(et1) == TYPE_ERROR) {
	    goto error_done;
	}
	et2 = Type_Check(task, CurTree_GET_NTH(node, 1));
	if (ET_TYPE(et2) == TYPE_ERROR) {
	    goto error_done;
	}

	/* We require specific component types and structures to match
	 * exactly.  Array assignment is also not allowed.
	 */
	if ( SPEC_COMP_TYPE(et1) && et1 != et2 )
	    goto mismatch_done;
	if ( ET_ARRAY_TYPE(et1) && ET_ARRAY_TYPE(et2) )
	{
	    SetError(task, E_ARRAY_ASSIGN_DISALLOWED);
	    goto error_done;
	}

	/* Hack, make it safe to assign from a user property into
	 * a structure.  This allows components to store the struct
	 * containing their aggregate instance data.
	 * Hack 2: allow assigning zero to a structure
	 */
	if (ET_TYPE(et1) == TYPE_STRUCT)
	{
	    Boolean	safeAssign = FALSE;

	    if (ET_TYPE(et2) == TYPE_UNKNOWN)
	    {
		Token*	tmpTok;
		tmpTok = CurTree_LOCK(CurTree_GET_NTH(node, 1));
		if (tmpTok->code == CUSTOM_PROPERTY)
		{
		    safeAssign = TRUE;
		}
		HugeTreeUnlock(tmpTok);
	    }
	    else
	    {
		safeAssign = (et1 == et2);
	    }

	    /* Assign const_int 0 to a struct -- change RHS to
	     * OP_ZERO(TYPE_STRUCT) and the runtime will do the right thing */
	    if (!safeAssign && ET_TYPE(et2) == TYPE_INTEGER)
	    {
		Token*	tmpTok;
		tmpTok = CurTree_LOCK(CurTree_GET_NTH(node, 1));
		if (tmpTok->code == CONST_INT &&
		    tmpTok->data.integer == 0)
		{
		    /* ( Unfortunately, no OP_CONST_STRUCT :-) */
		    safeAssign = TRUE;
		    tmpTok->code = PUSH_ZERO;
		    tmpTok->type = TYPE_STRUCT;
		    tmpTok->typeData = ET_DATA(et1);
		    et2 = et1;
		    HugeTreeDirty(tmpTok);
		}
		HugeTreeUnlock(tmpTok);
	    }
	    if (!safeAssign) goto mismatch_done;
	}

	/* If either is unknown, we have to wait until runtime.
	 */
	if (ET_TYPE(et1) == TYPE_UNKNOWN ||
	    ET_TYPE(et2) == TYPE_UNKNOWN ||
	    ET_TYPE(et1) == ET_TYPE(et2))
	{
	    break;
	}
	else
	{
	    /* Type_CoerceNth will raise errors if it can't deal
	     */
	    if (!Type_CoerceNth(task, node, 1, et1, et2))
	    {
		goto error_done;
	    }
	}
	break;
    }

    case IF:
    case IF_DOWHILE:
    case IF_LOOPUNTIL:
    {
	LegosType	t1;
	/* Test expression must be an int/long.
	   (Relational operators return numbers)

	   For if nodes, that's the first child.

	   Note that Do/Loop, Do/Until, Do/While loops all use
	   IF nodes to check loop and exit conditions 
	*/

	retType = TYPE_VOID;
	t1 = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 0)));
	if (!(isInteger(t1) || t1 == TYPE_UNKNOWN))
	{
	    goto mismatch_done;
	}

	if (! Type_CheckChildren(task, node, 1)) goto error_done;
	break;
    }

    case FOR:
    {
	byte		mookie;
	LegosType	type;
	
	/* Check that identifier, initial, final, and step expressions
	 * are ints/longs (or unknowns).  These are in children 0, 1, 2.
	 */
	retType = TYPE_VOID;
	for (mookie = 0; mookie <= 3; mookie++)
	{
	    type = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, mookie)));
	    if (type != TYPE_UNKNOWN && !isInteger(type)) {
		goto mismatch_done;
	    }
	}
	if (ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 4))) == TYPE_ERROR)
	{
	    goto error_done;
	}
	/* don't bother to check node 5; it's just a NEXT
	 */
	EC_ERROR_IF(CurTree_NUM_CHILDREN(node) != 6, BE_FAILED_ASSERTION);
	break;
    }

    case DO:
	retType = TYPE_VOID;
	if (ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, 0))) == TYPE_ERROR)
	{
	    goto error_done;
	}
	break;

    case REDIM:
    {
	Token*		tmpTok;
	LegosType	tmpType;

	retType = TYPE_VOID;
	tmpTok = CurTree_LOCK(CurTree_GET_NTH(node, ARRAY_IDENT_NODE));
	tmpType = tmpTok->type;
	HugeTreeUnlock(tmpTok);

	if (! (tmpType & TYPE_ARRAY_FLAG)) {
	    goto mismatch_done;
	}

	/* Fall through to get DIM's checking/coercion of indices */
    case DIM:
	/* FIXME: add COERCE nodes so runtime doesn't have to
	 * AssignTypeCompatible
	 */
	retType = TYPE_VOID;
	break;
    }

    case IDENTIFIER:
    {
	VTabEntry	vte;

	/* Most of these are handled up above, but we let one case through
	 * by checking for the arbitrary type TYPE_VOID
	 *
	 * The case is: unknown variable at var analysis time which is
	 * assumed to be a variable that hasn't been declared yet.
	 */
	EC_ERROR_IF(retType != TYPE_VOID, BE_FAILED_ASSERTION);
	VTLookupIndex(task->vtabHeap, GLOBAL_VTAB,
		      VAR_KEY_ELEMENT(data.key), &vte);
	if (vte.VTE_flags & VTF_FORWARD_REF) {
	    SetError(task, E_UNDECLARED);
	    goto error_done;
	}
	retType = vte.VTE_type;
	typeData = vte.VTE_extraInfo;
	break;
    }

	/* - Select/case nodes */
    case SELECT:		/* FIXME: compare type against cases */
    {
	LegosType	t1, t2;
	byte		numChildren, i;


	/* for now just set the type of the select to the type of the
	 * first child which is the variable we are selecting
	 * the CASE type will set its type to a specific type if all
	 * its cases are the same, and codegen will use type specific
	 * opcodes if the case type matches the select type
	 * -jimmy 
	 */

	t1 = retType = ET_TYPE(Type_CHECK_NTH(node, 0));
	if (retType == TYPE_ERROR) goto error_done;
	
	numChildren = CurTree_NUM_CHILDREN(node);
	for (i=1; i<numChildren; i++)
	{
	    t2 = ET_TYPE(Type_CHECK_NTH(node, i));
	    if (t2 == TYPE_ERROR)
	    {
		goto error_done;
	    }
	    if (t2 == TYPE_VOID)
	    {
		Node	caseNode;	/* To find the case's expr node */
		TokenCode c;
		/* Kludge so ELSE node is correctly typed -- it comes to
		 * us as TYPE_VOID
		 */
		caseNode = CurTree_GET_NTH(node, i);
		token = CurTree_LOCK(CurTree_GET_NTH(caseNode, 0));
		c = token->code;
		HugeTreeUnlock(token);

		if (c == ELSE)
		{
		    /* Changing the token type is maybe not necessary
		     * but it keeps the tree from looking invalid
		     */
		    token = CurTree_LOCK(caseNode);
		    token->type = t2 = t1;
		    HugeTreeDirty(token);
		    HugeTreeUnlock(token);
		}
	    }
#if 0
	    /* FIXME: unify t1 and t2 instead of merely checking for
	     * type equality.  CASE nodes are always TYPE_UNKNOWN for now
	     * so this still works (but in a kludgy way)
	     */
	    if (t2 != t1 && t2 != TYPE_UNKNOWN && t1 != TYPE_UNKNOWN)
		goto mismatch_done;
#endif
	} /* for */
	break;
    }
    case CASE:
    {
	/* All expressions under this case node must have the same type
	 * (which is also the return type).
	 */

	word		i, numExprs;
	LegosType	t1;

	numExprs = data.integer;
    
	retType = TYPE_UNKNOWN;	/* hopefully it will be filled in below */
	for (i=0; i<numExprs; i++)
	{
	    t1 = ET_TYPE(Type_CHECK_NTH(node, i));
	    if (t1 == TYPE_ERROR) goto error_done;
	    if (retType == TYPE_UNKNOWN) 
	    {
		retType = t1;
	    } 
	    else 
	    {
		/* allow type mismatches, just use generic TYPE_UNKNOWN */
		if (t1 != retType && t1 != TYPE_UNKNOWN) 
		{
		    retType = TYPE_UNKNOWN;
		    break;
		}
	    }
	}

	/* And then do checking on the body */
	if (Type_CHECK_NTH(node, i) == TYPE_ERROR)
	{
	    goto error_done;
	}
	break;
    }
    case TO:
    {
#if 0
	/* Two sub-expressions must be same type (also the return type)
	 */
	LegosType	t1, t2;
	retType = t1 = ET_TYPE(Type_CHECK_NTH(node, 0));
	if (t1 == TYPE_ERROR) goto error_done;
	t2 = ET_TYPE(Type_CHECK_NTH(node, 1));
	if (t1 == TYPE_ERROR) goto error_done;
	if (t1 == TYPE_UNKNOWN)
	{
	    retType = t2;
	} else {
	    if (t1 != t2 && t2 != TYPE_UNKNOWN)
		goto mismatch_done;
	}
	EC_ERROR_IF(CurTree_NUM_CHILDREN(node) != 2, BE_FAILED_ASSERTION);
#endif	
	retType = TYPE_UNKNOWN;
	if (!Type_CheckChildren(task, node, 0)) goto error_done;
	break;
    }
    case ELSE:
	retType = TYPE_VOID;
	break;

    case SUB:
    case FUNCTION:
    {
	Token*	numArgsTok;
	word	codeChild;	/* used to find the child containing code */

	/* children look like: #args, args... , [ret type], code
	 * only functions have the ret type node
	 */
	numArgsTok = CurTree_LOCK(CurTree_GET_NTH(node, 0));

	codeChild = numArgsTok->data.integer + 1;
	if (code == FUNCTION) codeChild += 1;

	HugeTreeUnlock(numArgsTok);

	retType = TYPE_VOID;
	if (Type_Check(task, CurTree_GET_NTH(node, codeChild)) == TYPE_ERROR)
	    goto error_done;
	break;
    }

    case PUSH_ZERO:
	/* The parser should never output one of these -- it only appears
	 * as a result of a tree transformation in lines like:
	 *	myStructVariable = 0
	 */
	EC_WARNING(BW_UNHANDLED_CASE);
	break;

	/* These all just recurse on the children, which is also
	 * the defult behavior
	 */
    default:
	EC_WARNING(BW_UNHANDLED_CASE);
    case COMP_INIT:
	if (!Type_CheckChildren(task, node, 0))
	    goto error_done;
	retType = TYPE_VOID;
	break;

    case NULLCODE:
    {
	word	num, i;
	LegosType t;

	retType = TYPE_VOID;

	num = CurTree_NUM_CHILDREN(node);
	for (i=0; i<num; i++) {
	    t = ET_TYPE(Type_Check(task, CurTree_GET_NTH(node, i)));
	    if (t == TYPE_ERROR) goto error_done;
	    if (t != TYPE_VOID)
	    {
		/* FIXME: Select has a type attached to it because it
		 * used to be convenient to store one there.  It would
		 * be cleaner to make select TYPE_VOID and move the type
		 * somewhere else, but this works for now.
		 */

		/* Is ok for non-void ACTION nodes to be below NullCode;
		 * the compiler will generate an OP_ACTION_PROC and toss
		 * the returned value.  Very convenient.
		 *
		 * Similarly for MODULE_CALL -- it has PROC and FUNC
		 * versions
		 */
		Token*	tmpTok;
		TokenCode tc;

		tmpTok = CurTree_LOCK(CurTree_GET_NTH(node, i));
		tc = tmpTok->code;
		HugeTreeUnlock(tmpTok);
		switch (tc)
		{
		case SELECT:
		case ACTION: case BC_ACTION:
		case MODULE_CALL:
		    /* These are all OK -- see comments above */
		    break;
		default:
		    SetError(task, E_DANGLING_RVAL);
		    goto error_done;
		}
	    }
	}
	break;
    }

	/* These are leaves whose type is just void
	 */
    case EXPORT:
    case ONERROR:
    case RESUME:
    case STRUCTDECL:
    case EXIT:
    case LOOP:
    case END:
    case LABEL:
    case TOKEN_GOTO:
	retType = TYPE_VOID;
	goto nochange_done;

    } /* switch */

    /* Write data back out to the current node
     */
 done:
    token = CurTree_LOCK(node);
    token->type = retType;
    token->typeData = typeData;
    HugeTreeDirty(token);
    HugeTreeUnlock(token);
 nochange_done:
    return MAKE_ET(typeData, retType);

 mismatch_done:
    SetError(task, E_TYPE_MISMATCH);
 error_done:
    return TYPE_ERROR;
}

/*********************************************************************
 *			Type_CheckRoutineCall
 *********************************************************************
 * SYNOPSIS:	Type check a func/procedure call
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Check argument types against formal paramter types
 *	Add coercion nodes if necessary.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/26/95	Initial version
 * 
 *********************************************************************/
ExtendedType
Type_CheckRoutineCall(TaskPtr task, Node node)
{
    LegosType	retType;
    TokenCode	code;
    word	typeData=0xffff;
    word	funcNum;

    FTabEntry*	ftab;
    word	i;
    byte	numParams, numCallArgs;
    byte	adjust = 0;	/* compensate for functions' return values */
    word	varTable;

    if (!Type_CheckChildren(task, node, 0))
    {
	return MAKE_ET(0xffff, TYPE_ERROR);
    }

    /* funcNum <- data from node */
    ;{
	Token*	token;
	token = CurTree_LOCK(node);
	funcNum = token->data.integer;
	code = token->code;
	HugeTreeUnlock(token);
    }

    /* This isn't a type-checking check.  It's actually a semantics
     * check to make sure the number of supplied args matches thnumber
     * required by the routine. We can't do this at parse time because
     * we have no guarantee that the number of required parameters is
     * known for all routines in a module. We do make sure, however,
     * that all parsing occurs before we get here so this is a
     * reasonable place to make the check...
     * 
     * Similarly, we check vtab entries here for other
     * functions. Hence we must demand that variable analysis has
     * occured for all routines in the module before doing this
     * work...
     */
    ftab = FTabLock(task->funcTable, funcNum);
    /* Must have at least parsed and var analyzed
       by the time we do this... */
    EC_ERROR_IF (ftab->compStatus < CS_VAR_ANALYZED, 
		 BE_FAILED_ASSERTION);

    if (code == USER_FUNC)
    {
	VTabEntry	vte;

	EC_ERROR_IF(ftab->funcType != FT_FUNCTION, 
		    BE_FAILED_ASSERTION);
	VTLookupIndex(task->vtabHeap, ftab->vtab, 0, &vte);
	retType = vte.VTE_type;
	typeData = vte.VTE_extraInfo;
    } else {
	retType = TYPE_VOID;
    }
    
    numParams = ftab->numParams;
    varTable = ftab->vtab;
    FTabUnlock(ftab);
	    
    numCallArgs = CurTree_NUM_CHILDREN(node);
    if (numCallArgs != numParams) {
	SetError(task, E_BAD_NUM_PARAMS);
	return TYPE_ERROR;
    }

    if (code == USER_FUNC) {
	/* We skip over the first "local" when calling
	   functions; this is just the return variable.*/
	adjust = 1;
    }

    for (i = 0; i < numParams; i++)
    {
	/* Parameters are the first locals so we can
	   just lock the corresponding variable in the local table.
	   
	   If this is a function, however, we skip over the
	   first local variable in the localTable, since
	   that is for the return value.
	   */
	Boolean		fullCheck = FALSE;
	VTabEntry	vte;
	ExtendedType	callET, formalET;

	/* Can't check squat if the call type is unknown.
	 * Don't need to check squat if the formal type is unknown.
	 */
	callET = TypeOfNthChild(task, node, i);
	if (ET_TYPE(callET) == TYPE_UNKNOWN) continue;

	VTLookupIndex(task->vtabHeap, varTable, i + adjust, &vte);

	formalET = MAKE_ET(vte.VTE_extraInfo, vte.VTE_type);
	if (ET_TYPE(formalET) == TYPE_UNKNOWN) continue;

	switch (ET_TYPE(formalET))
	{
	case TYPE_COMPONENT:
	    /* If formal param is just "as component" then
	     * don't perform full check
	     */
	    fullCheck = (vte.VTE_extraInfo != (word)NullElement);
	    break;
	case TYPE_STRUCT:
	    fullCheck = TRUE;
	    break;
	default:
	    if (ET_ARRAY_TYPE(formalET)) {
		fullCheck = TRUE;
	    } else {
		fullCheck = FALSE;
	    }
	}
	
	if (fullCheck && (callET != formalET))
	{
	    /* No way to coerce any type which requires a full ExtendedType */
	    SetError(task, E_TYPE_MISMATCH);
	    retType = TYPE_ERROR;
	}
	else if (ET_TYPE(callET) != ET_TYPE(formalET))
	{
	    /* Can we coerce successfully? */
	    if (isNumber(ET_TYPE(callET)) &&
		isNumber(ET_TYPE(formalET)))
	    {
		if (!Type_CoerceNth(task, node, i, formalET, callET))
		{
		    retType = TYPE_ERROR;
		}
	    }
	    else
	    {
		SetError(task, E_TYPE_MISMATCH);
		retType = TYPE_ERROR;
	    }
	}
    }
    return MAKE_ET(typeData, retType);
}

/*********************************************************************
 *			isNumber
 *********************************************************************
 * SYNOPSIS:	Check the opcode and see if it's a number
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 4/21/95	Initial version			     
 * 
 *********************************************************************/
Boolean isNumber(LegosType t) 
{
    return (t == TYPE_INTEGER || t == TYPE_LONG || t == TYPE_FLOAT);
}


Boolean isInteger(LegosType t) 
{
    return (t == TYPE_INTEGER || t == TYPE_LONG);
}


Boolean isNumericConstant(TokenCode	t)
{
    return (t == CONST_INT || t == CONST_FLOAT || t == CONST_LONG);
}



/*********************************************************************
 *			EvalConstantExpression
 *********************************************************************
 * SYNOPSIS:	do some compile time evaluation
 * CALLED BY:	Type_Check
 * RETURN:  	value token should be (TYPE_ILLEGAL meaning no change)
 *		Sets error as well.
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 1/95	Initial version
 * 
 *********************************************************************/
Token EvalConstantExpression(TaskPtr task, Node node, TokenCode code)
{
    Node    	right, left;
    Token   	*l, *r, retVal;
    LegosType	type;
    word	oldDS;		/* around the switch -- for FP constants */

    retVal.type = TYPE_ILLEGAL;
    retVal.typeData = 0xffff;

    left = CurTree_GET_NTH(node, 0);
    l = CurTree_LOCK(left);
    if (! isNumericConstant(l->code)) 
    {
	HugeTreeUnlock(l);
	return retVal;
    }
    l->type = TokenToType(l->code);
    if (code != NOT)
    {
	right = CurTree_GET_NTH(node, 1);
	r = CurTree_LOCK(right);
	if (! isNumericConstant(r->code))
	{
	    HugeTreeUnlock(l);
	    HugeTreeUnlock(r);
	    return retVal;
	}

	r->type = TokenToType(r->code);
	type = ArithResultType(l->type, r->type);
	EC_ERROR_IF(type == TYPE_ILLEGAL, BE_FAILED_ASSERTION);
    }
    else
    {
	type = l->type;
    }

    oldDS = setDSToDgroup();	/* for FP constants */
    switch (type)
    {
    case TYPE_INTEGER:
    {
	int	i1, i2;
	long	res;
	
	/* zero out high word for liberety */
	retVal.data.key = 0;
	i1 = l->data.integer;
	if (code != NOT) {
	    i2 = r->data.integer;
	}

	switch (code) 
	{
	case AND: res = i1 && i2; break;
	case XOR: res = ( (i1 && !i2) || (!i1 && i2)); break;
	case OR: res = i1 || i2; break;
	case NOT: res = !i1; break;
	case MULTIPLY: res = (long)i1 * (long)i2; break;
	case MINUS: res = (long)i1 - (long)i2; break;
	case PLUS: res = (long)i1 + (long)i2; break;
	case MOD:   res = i2 ? (i1 % i2) : (retVal.type=TYPE_ERROR); 
	    	    if (res < 0) res += i2; break;
	case DIVIDE: res = i2 ? (i1 / i2) : (retVal.type=TYPE_ERROR); break;
	case LESS_THAN: res = (i1 < i2); break;
	case GREATER_THAN: res = (i1 > i2); break;
	case LESS_EQUAL: res = (i1 <= i2); break;
	case GREATER_EQUAL: res = (i1 >= i2); break;
	case LESS_GREATER: res = (i1 != i2); break;
	case EQUALS: res = (i1 == i2); break;
	case BIT_AND: res = (i1 & i2); break;
	case BIT_XOR: res = (i1 ^ i2); break;
	case BIT_OR: res = (i1 | i2); break;
	}

	if (retVal.type == TYPE_ERROR) {
	    break;
	}
	if (res > INT_MAX || res < INT_MIN) {
	    retVal.type = TYPE_LONG;
	    retVal.data.long_int = res;
	    retVal.code = CONST_LONG;
	} else {
	    retVal.type = TYPE_INTEGER;
	    retVal.data.integer = res;
	    retVal.code = CONST_INT;
	}
    }
	break;
    case TYPE_LONG:
    {
	long i1, i2, res;
	
	retVal.type = type;

	/* if the type is long, both args are either int or long so cast
	 * them both up to long
	 */
	if (l->type == TYPE_INTEGER) {
	    i1 = l->data.integer;
	} else {
	    i1 = l->data.key;
	}
	if (code != NOT) {
	    if (r->type == TYPE_INTEGER) {
		i2 = r->data.integer;
	    } else {
		i2 = r->data.key;
	    }
	}

	switch (code) 
	{
	case AND: res = i1 && i2; break;
	case XOR: res = ( (i1 && !i2) || (!i1 && i2)); break;
	case OR: res = i1 || i2; break;
	case NOT: res = !i1; break;

	case MULTIPLY:
	{
	    double	dres;
	    /* Sigh... slow way to do overflow checking */
	    res = i1 * i2;
	    dres = (double)i1 * (double)i2;
	    if ((dres > LONG_MAX) || (dres < LONG_MIN))
	    {
		SetError(task, E_OVERFLOW);
		retVal.type = TYPE_ILLEGAL;
	    }
	    break;
	}
	case MINUS:
	    res = i1 - i2;
	    goto check_overflow;
	case PLUS:
	    res = i1 + i2;
 check_overflow:
#ifdef __BORLANDC__
/* z! */
asm{	    jno	no_overflow	}
	    SetError(task, E_OVERFLOW);
	    retVal.type = TYPE_ILLEGAL;
#endif
no_overflow:
	    break;

	case MOD: res = i2 ? (i1 % i2) : (retVal.type=TYPE_ERROR); break;
	case DIVIDE: res = i2 ? (i1 / i2) : (retVal.type=TYPE_ERROR); break;
	case LESS_THAN: res = (i1 < i2); break;
	case GREATER_THAN: res = (i1 > i2); break;
	case LESS_EQUAL: res = (i1 <= i2); break;
	case GREATER_EQUAL: res = (i1 >= i2); break;
	case LESS_GREATER: res = (i1 != i2); break;
	case EQUALS: res = (i1 == i2); break;
	case BIT_AND: res = (i1 & i2); break;
	case BIT_XOR: res = (i1 ^ i2); break;
	case BIT_OR: res = (i1 | i2); break;
	}

	retVal.data.key = res;
	retVal.code = CONST_LONG;
    }
	break;
    case TYPE_FLOAT:
    {
	float i1, i2, res;
	
	retVal.type = type;

	/* if the type is long, both args are either int or long so cast
	 * them both up to long
	 */
	if (l->type == TYPE_INTEGER) {
	    i1 = l->data.integer;
	} else if (l->type == TYPE_LONG) {
	    i1 = l->data.key;
	} else {
	    i1 = *(float *)&(l->data);
	}
	if (code != NOT) {
	    if (r->type == TYPE_INTEGER) {
		i2 = r->data.integer;
	    } else if (r->type == TYPE_LONG) {
		i2 = r->data.key;
	    } else {
		i2 = *(float *)&(r->data);
	    }
	}

	switch (code) 
	{
	case AND: res = i1 && i2; break;
	case XOR: res = ( (i1 && !i2) || (!i1 && i2)); break;
	case OR: res = i1 || i2; break;
	case NOT: res = !i1; break;
	case MULTIPLY: res = i1 * i2; break;
	case MINUS: res = i1 - i2; break;
	case PLUS: res = i1 + i2; break;
	case DIVIDE: res = i2 ? (i1 / i2) : (retVal.type=TYPE_ERROR); break;
	case LESS_THAN: res = (i1 < i2); break;
	case GREATER_THAN: res = (i1 > i2); break;
	case LESS_EQUAL: res = (i1 <= i2); break;
	case GREATER_EQUAL: res = (i1 >= i2); break;
	case LESS_GREATER: res = (i1 != i2); break;
	case EQUALS: res = (i1 == i2); break;
	}

	*(float *)&(retVal.data) = res;
	retVal.code = CONST_FLOAT;
    }
	break;

    }
    restoreDS(oldDS);

    HugeTreeUnlock(l);
    if (code != NOT) 
    {
	HugeTreeUnlock(r);
    }

    if (isNumber(retVal.type))
    {
	Token	*temp;
	temp = CurTree_LOCK(node);
	*temp = retVal;
	HugeTreeDirty(temp);
	HugeTreeUnlock(temp);
    }

    if (retVal.type == TYPE_ERROR) {
	SetError(task, E_OVERFLOW);
    }


    return retVal;
}

/*********************************************************************
 *			SafeForUnknown
 *********************************************************************
 * SYNOPSIS:	Given two test types t1, t2, and a type key, return
 *              TRUE iff t1, t2, are some combination of the UNKNOWN
 *              type and the key type to yield a legal combination.
 *               
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 4/21/95	Initial version			     
 * 
 *********************************************************************/
Boolean SafeForUnknown(LegosType t1, LegosType t2, LegosType key) {


    return ((t1 == key || t1 == TYPE_UNKNOWN) &&
	    (t2 == key || t2 == TYPE_UNKNOWN));
}
    

/*********************************************************************
 *			SafeForUnknownAndNumber
 *********************************************************************
 * SYNOPSIS:	Similar to SafeForUnknown but where key is
 *              any number.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 4/21/95	Initial version			     
 * 
 *********************************************************************/

Boolean SafeForUnknownAndNumber(LegosType t1, LegosType t2) {

    return ((isNumber(t1) || t1 == TYPE_UNKNOWN) &&
	    (isNumber(t2) || t2 == TYPE_UNKNOWN));
}


/*********************************************************************
 *			SafeForUnknownAndInteger
 *********************************************************************
 * SYNOPSIS:	Just like SafeForUnknownAndNumber, but only allows
 *              int/long values
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 4/21/95	Initial version			     
 * 
 *********************************************************************/

Boolean SafeForUnknownAndInteger(LegosType t1, LegosType t2) {

    return ((isInteger(t1) || t1 == TYPE_UNKNOWN) &&
	    (isInteger(t2) || t2 == TYPE_UNKNOWN));
}

    
/*********************************************************************
 *			TypeOfNthChild
 *********************************************************************
 * SYNOPSIS:	Just what the name says...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 4/21/95	Initial version			     
 * 
 *********************************************************************/
ExtendedType
TypeOfNthChild(TaskPtr task, Node node, word childNum) 
{
    Token*		token;
    ExtendedType	code;

    token = CurTree_LOCK(CurTree_GET_NTH(node, childNum));
    code = MAKE_ET(token->typeData, token->type);
    HugeTreeUnlock(token);
    return code;
}

/*********************************************************************
 *			Type_CoerceNth
 *********************************************************************
 * SYNOPSIS:	Instrument parse tree section with an additional node
 *              to coerce the specified child node's type into
 *              the finalType.
 *
 *                    node                        node
 *                    |                  -->       |
 *                    |                            |
 *                    child of type t             coerce to finalType
 *                                                 |
 *                                                 |
 *                                                child of type t
 *
 * CALLED BY:	
 * RETURN:	FALSE and error set to E_TYPE_MISMATCH if unsuccessful
 * SIDE EFFECTS:
 * STRATEGY:
 *	Does the right thing if the types are the same
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 4/21/95	Initial version			     
 * 
 *********************************************************************/
Boolean
Type_CoerceNth(TaskPtr task, Node node, word childNum,
	       LegosType finalType, LegosType origType)
{
    Node	coerce;
    Token	*token;
    word	ln;
    word	oldDS;

    if (finalType == origType) return TRUE;

    /* At the moment, can only handle numeric and struct->component coercion
     */
    if (isNumber(finalType) &&
	(isNumber(origType) || origType == TYPE_UNKNOWN))
    {
	/* pass through */
    }
    else if (origType == TYPE_STRUCT
	     && finalType == TYPE_COMPONENT)
    {
	word	origTypeData;

	token = CurTree_LOCK(CurTree_GET_NTH(node, childNum));
	origTypeData = token->typeData;
	HugeTreeUnlock(token);

	if (Type_IsValidStruct(task, origTypeData))
	{
	    /* pass through */
	} else {
	    SetError(task, E_INVALID_STRUCT_FOR_AGG);
	    return FALSE;
	}
    }
    else
    {
	SetError(task, E_TYPE_MISMATCH);
	return FALSE;
    }

    token = CurTree_LOCK(node);
    ln = token->lineNum;
    HugeTreeUnlock(token);

    token = CurTree_LOCK(CurTree_GET_NTH(node, childNum));

    /* if its a constant, just convert the node to the appropriate type
     * and stuff in the value, rather than doing work at runtime
     */
    oldDS = setDSToDgroup();	/* for FP constants */
    if (isNumericConstant(token->code))
    {
	Boolean retval = TRUE;

	switch(finalType) 
	{
	case TYPE_INTEGER:
	    token->code = CONST_INT;
	    if (token->type == TYPE_LONG) {
		if ((token->data.long_int > INT_MAX) ||
		    (token->data.long_int < INT_MIN)) {
		    SetError(task, E_OVERFLOW);
		    retval = FALSE;
		} else {
		    token->data.integer = token->data.long_int;
		}
	    } else {
		/* float */
		if ((token->data.num > INT_MAX) ||
		    (token->data.num < INT_MIN))
		{
		    SetError(task, E_OVERFLOW);
		    retval = FALSE;
		} else {
		    token->data.integer = token->data.num;
		}
	    }
	    break;
	case TYPE_LONG:
	    token->code = CONST_LONG;
	    if (token->type == TYPE_INTEGER) {
		token->data.key = token->data.integer;
	    } else {
		/* float */
		if ((token->data.num > LONG_MAX) ||
		    (token->data.num < LONG_MIN))
		{
		    SetError(task, E_OVERFLOW);
		    retval = FALSE;
		} else {
		    token->data.key = *(float *)&(token->data);
		}
	    } break;
	case TYPE_FLOAT:
	    token->code = CONST_FLOAT;
	    if (token->type == TYPE_INTEGER) {
		*(float *)&(token->data) = token->data.integer;
	    } else {
		*(float *)&(token->data) = token->data.key;
	    } break;
	}
	token->type = finalType;
	HugeTreeDirty(token);
	HugeTreeUnlock(token);
	return retval;
    }
    restoreDS(oldDS);
    HugeTreeUnlock(token);

    /* No data, 1 child, same debugging line number as previous...
     */
    coerce = ParseAllocTokenNode(task->vmHandle, task->tree,
				 COERCE, ln, 0, 1);
    token = CurTree_LOCK(coerce);
    token->type = finalType;
    HugeTreeDirty(token);
    HugeTreeUnlock(token);

    /* Insert coerce node between parent and child.
     */
    CurTree_APPEND(coerce, CurTree_GET_NTH(node, childNum));
    CurTree_SET_NTH(node, childNum, coerce);

    return TRUE;
}

/*********************************************************************
 *			Type_IsValidStruct
 *********************************************************************
 * SYNOPSIS:	Determine if a struct is a valid aggregate component
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	First 4 fields of struct must be:
 *
 *	MODULE	library module
 *	MODULE	loading module
 *	STRING	class name
 *	STRING	proto
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/14/95	Initial version
 * 
 *********************************************************************/
Boolean
Type_IsValidStruct(TaskPtr task, word structName)
{
    word	vtab;
    word	i;
    VTabEntry	vte;
    word	oldDS = setDSToDgroup(); /* for the next line... */
    LegosType	types[AF_NUM_FIELDS] = AGG_FIELD_TYPES;

    vtab = StringTableGetData(STRUCT_TABLE, structName);

    if (VTGetCount(VTAB_HEAP, vtab) < AF_NUM_FIELDS) return FALSE;
    for (i=0; i<AF_NUM_FIELDS; i++)
    {
	VTLookupIndex(task->vtabHeap, vtab, i, &vte);
	if (vte.VTE_type != types[i]) return FALSE;	
    }

    restoreDS(oldDS);
    return TRUE;
}

/*********************************************************************
 *			ArithResultType
 *********************************************************************
 * SYNOPSIS:	For arithmetic between two types, return
 *              the type of the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 4/21/95	Initial version			     
 * 
 *********************************************************************/
LegosType ArithResultType(LegosType t1, LegosType t2) {

    switch (t1) {
    case TYPE_INTEGER:
	return t2;

    case TYPE_LONG:
	if (t2 == TYPE_INTEGER || t2 == TYPE_LONG) {
	    return TYPE_LONG;
	}

	/* Fall through... */

    case TYPE_FLOAT:
    default:
	return TYPE_FLOAT;
    }
}

/*********************************************************************
 *			Type_ResolvePropOrAction
 *********************************************************************
 * SYNOPSIS:	Resolve a prop or action into a BC-prop/action
 * CALLED BY:	INTERNAL, Type_Check
 * RETURN:	Node's type (could be TYPE_UNKNOWN, TYPE_ERROR)
 * SIDE EFFECTS:Might change node code to BC_PROP or BC_ACTION
 *
 * STRATEGY:
 *	This routine is called only if the component has a specific
 *	type.  If the property/action specifier is an expression and
 *	not just a string const, we can bail.
 *
 *	If it is a string constant, allow unresolved properties to
 *	stay unresolved (component allows these).  However, unresolved
 *	actions will always be runtime errors, so catch those.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	11/16/95	Pulled out of Type_Check
 * 
 *********************************************************************/
ExtendedType
Type_ResolvePropOrAction(TaskPtr task, Node node, optr comp, TokenCode code,
			 word *numParams)
{
    Token*	nameTok;
    dword	nameKey;
    TCHAR*	str;
    LegosType	propType;
    ExtendedType retval;
    Boolean	success;
    byte	bcMess;
    word	typeData=0xffff;
    Token*	token;

    EC_ERROR_IF(comp == NullOptr, BE_FAILED_ASSERTION);

    nameTok = CurTree_LOCK(CurTree_GET_NTH(node, 1));
    if (nameTok->code != CONST_STRING) {
	HugeTreeUnlock(nameTok);
	*numParams = 0xffff;
	return MAKE_ET(0xffff, TYPE_UNKNOWN);
    } else {
	nameKey = nameTok->data.key;
	HugeTreeUnlock(nameTok);
    }
			
    /* resolve the property to a message # to be used at runtime,
     * and fill in the return type.
     */
    str = StringTableLock(ID_TABLE, nameKey);
    EC_ERROR_IF(str == NULL, BE_FAILED_ASSERTION);
    success = CompileResolvePropertyOrAction(task, comp, code, str,
					     &bcMess, &propType, &typeData,
					     numParams);
    StringTableUnlock(str);

    token = CurTree_LOCK(node);
    if (success)
    {

	/* mark the token as a byte-compiled property
	 * and put the message number in the data.
	 */
	if (code == PROPERTY) {
	    token->code = BC_PROPERTY;
	} else {
	    token->code = BC_ACTION;
	}
	token->data.key = bcMess;
	retval = MAKE_ET(typeData, propType);
	HugeTreeDirty(token);
    }
    else
    {
	retval = MAKE_ET(0xffff, TYPE_UNKNOWN);
	if (code == ACTION)
	{
	    SetError(task, E_UNRESOLVED_ACTION);
	    retval = MAKE_ET(0xffff, TYPE_ERROR);
	}
	else
	{
	    /* since we got this far, it must be a specific property type
	     * thus this has to be a custom property
	     */
	    token->code = CUSTOM_PROPERTY;
	    HugeTreeDirty(token);
	}
    }

    HugeTreeUnlock(token);
    return retval;
}
