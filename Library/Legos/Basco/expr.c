/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		expr.c

AUTHOR:		Jimmy Lefkowitz, Dec 16, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	12/16/94   	Initial version.

DESCRIPTION:
	code to do code generation for expressions

	$Id: expr.c,v 1.1 98/10/13 21:42:49 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <mystdapp.h>
#include <tree.h>
#include <Legos/opcode.h>
#include "bascoint.h"
#include "codegen.h"
#include "codeint.h"
#include "label.h"
#include "vars.h"
#include "types.h"
#include "stable.h"
#include "ftab.h"

Boolean CGE_Children(TaskPtr, Node, word start);
Boolean CGE_ChildrenLVal(TaskPtr, Node, word start);
Boolean CGE_ArrayRef(TaskPtr task, Node node, Boolean lval, TokenCode code);
Boolean CodeGenExprLow(TaskPtr task, Node node, Boolean lval);

/*********************************************************************
 *			CodeGenExpr
 *********************************************************************
 * SYNOPSIS:	code to code generate expression
 * CALLED BY:	CodeGenBlockOfCode
 * RETURN:  	true if everything ok, false otherwise
 * SIDE EFFECTS:
 * STRATEGY:
 *	The code is probably a little bulky (a lot of calls to
 *	CGE_Children), but I think it's worth it here. --dubois
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/16/94		Initial version			     
 * 
 *********************************************************************/
#define CG_GET_NTH(_node, _n) \
 HugeTreeGetNthChild(task->vmHandle, task->tree, _node, _n)

#define CG_GET_NUM(_node) \
 HugeTreeGetNumChildren(task->vmHandle, task->tree, _node)

#define EC_CHECK_NUM_CHILDREN(_node, _n) \
EC_ERROR_IF((HugeTreeGetNumChildren(task->vmHandle, task->tree, _node) != _n),\
	    BE_FAILED_ASSERTION)

Boolean
CodeGenExpr(TaskPtr task, Node node)
{
    return CodeGenExprLow(task, node, FALSE);
}

Boolean
CodeGenExprLow(TaskPtr task, Node node, Boolean lval)
{
    Token	nodeTok;
    Opcode      opcode;

    ;{
	Token*	nodePtr;

	nodePtr = (Token *)HugeTreeLock(task->vmHandle, task->tree, node);
	nodeTok = *nodePtr;
	HugeTreeUnlock(nodePtr);
    }

    if (LINE_TERM(nodeTok.code))
    {
	/* What's this for? I don't think these can get into the AST
	 * If this warning never gets hit I'm taking this out...
	 * --dubois */
	EC_WARNING(BW_OLD_KERNEL);
	return TRUE;
    }

    switch(nodeTok.code)
    {
    case MODULE_REF:	
    {
	/* Code stream: byte[OP_MODULE_REF_{RV, LV}]
	 * stack: string module TOS
	 */
	EC_CHECK_NUM_CHILDREN(node, 2);
	CHECK(CGE_Children(task, node, 0));
	opcode = lval ? OP_MODULE_REF_LV : OP_MODULE_REF_RV;
	CHECK(CodeGenEmitByte(task, opcode));
	break;
    }

    case MODULE_CALL:
    {
	Token*	nodePtr;
	Token*  parentPtr;
	Opcode  opcode;
	Node    parent;

	/* if the thing is being called directly under a NULLCODE
	 * node, it must not have a return value, so its a PROC
	 * not a FUNC
	 */
	parent = HugeTreeGetParent(task->vmHandle, task->tree, node);
	parentPtr = (Token *)HugeTreeLock(task->vmHandle, task->tree, parent);
	opcode = (parentPtr->code==NULLCODE) ? 
	    OP_MODULE_CALL_PROC : OP_MODULE_CALL_FUNC;
	HugeTreeUnlock(parentPtr);

	if (opcode == OP_MODULE_CALL_FUNC)
	{
	    Node	lastNode;
	    Token*	tok;

	    /* Create stack space for return value;
	     * don't forget to increment # args
	     */
	    CHECK(CodeGenCheckFreeSpace(task, 2));
	    CodeGenEmitByteNoCheck(task, OP_ZERO);
	    CodeGenEmitByteNoCheck(task, TYPE_NONE);

	    lastNode = CG_GET_NTH(node, CG_GET_NUM(node)-1);
	    tok = CurTree_LOCK(lastNode);
	    EC_ERROR_IF(tok->code != CONST_INT, BE_FAILED_ASSERTION);
	    tok->data.integer++;
	    HugeTreeDirty(tok);
	    HugeTreeUnlock(tok);
	}

	/* Code stream: byte[OP_MODULE_CALL] word[function name]
	 * stack: arg1 ... argN #args module TOS
	 */
	CHECK(CGE_Children(task, node, 2)); /* args */
	CHECK(CodeGenExprLow(task, CG_GET_NTH(node, 1), FALSE));
	

	/* Do the same kind of analysis as with actions. 
	   Check the parent to decide whether or not
	   the code is expecting a procedure call or a function call.
	   Always do the right thing, Mookie.
	*/

	CHECK(CodeGenCheckFreeSpace(task, 3));
	CodeGenEmitByteNoCheck(task, opcode);

	/* Extract string constant from 0th child and inline it in code
	 */
	nodePtr = HugeTreeLock(task->vmHandle, task->tree,
			       CG_GET_NTH(node, 0));
	CodeGenEmitWordNoCheck(task, nodePtr->data.integer);
	HugeTreeUnlock(nodePtr);
	break;
    }

    case ACTION:
    {
	Token*	tmpTok;
	Boolean	isFunc, isStack;
	dword	propKey;

	/* Child 0 is component.  Child 1 is action name. */

	/* Code stream: byte[opcode], word[action]?
	 * stack: (arg0?) arg1 ... argN #params component (name?) TOS
	 *
	 * action is inlined in code if it's a string constant,
	 * generated on the stack if not.  arg0 is generated if
	 * it's a function.
	 */

	tmpTok = CurTree_LOCK(CurTree_GET_PARENT(node));
	isFunc = (tmpTok->code != NULLCODE);
	HugeTreeUnlock(tmpTok);

	tmpTok = CurTree_LOCK(CurTree_GET_NTH(node, 1));
	if (tmpTok->code == CONST_STRING) 
	{
	    TCHAR   *str;

	    isStack = FALSE;
	    propKey = tmpTok->data.key;
	    /* now lets move the string into the string const table and
	     * use the const table key
	     */
	    str = StringTableLock(ID_TABLE, propKey);
	    propKey = StringTableAdd(CONST_TABLE, str);
	    StringTableUnlock(str);
	} else {
	    isStack = TRUE;
	}
	HugeTreeUnlock(tmpTok);
	
	opcode = (isStack? (isFunc ? OP_STACK_ACTION_FUNC
				   : OP_STACK_ACTION_PROC)
			 : (isFunc ? OP_ACTION_FUNC
				   : OP_ACTION_PROC));

	if (isFunc)
	{
	    /* Since we don't (as of 5/19/95) check action return types
	     * at runtime, supply TYPE_NONE as the type of the return value...
	     */
	    CHECK(CodeGenCheckFreeSpace(task, 2));
	    CodeGenEmitByteNoCheck(task, OP_ZERO);
	    CodeGenEmitByteNoCheck(task, TYPE_NONE);
	}
	
	/* Component is child zero, but it needs to be at the top of
	 * stack, so do children 2-$ first.  We want to make sure
	 * these are output as lvals since actions work by reference.
	 */

	/* dubois 8/18/95 -- remove by-ref support for now, so
	 * comp.action(comp2.property) works
	 CHECK(CGE_ChildrenLVal(task, node, 2));		*/
	CHECK(CGE_Children(task, node, 2));
	CHECK(CodeGenExprLow(task, CG_GET_NTH(node, 0), FALSE));

	if (isStack) {
	    CHECK(CodeGenExprLow(task, CurTree_GET_NTH(node, 1), FALSE));
	}

	if (!isStack) {
	    CHECK(CodeGenCheckFreeSpace(task, 3));
	    CodeGenEmitByteNoCheck(task, opcode);
	    CodeGenEmitWordNoCheck(task, propKey);
	} else {
	    CHECK(CodeGenEmitByte(task, opcode));
	}
	break;
    }

    case BC_ACTION:
    {
	Token*	tmpTok;
	Boolean	isFunc;

	/* Child 0 is component.  Child 1 is action name. */

	/* Code stream: byte[opcode], byte[action]
	 * stack: (arg0?) arg1 ... argN #params component TOS
	 * Arg 0 generated if it's a function
	 */

	tmpTok = CurTree_LOCK(CurTree_GET_PARENT(node));
	isFunc = (tmpTok->code != NULLCODE);
	HugeTreeUnlock(tmpTok);

	opcode = (isFunc ? OP_BC_ACTION_FUNC : OP_BC_ACTION_PROC);

	if (isFunc) 
	{
	    CHECK(CodeGenCheckFreeSpace(task, 2));
	    CodeGenEmitByteNoCheck(task, OP_ZERO);
	    CodeGenEmitByteNoCheck(task, TYPE_NONE);
	}

	/* dubois 8/18/95 -- remove by-ref support for now, so
	 * comp.action(comp2.property) works
	CHECK(CGE_ChildrenLVal(task, node, 2));		*/

	CHECK(CGE_Children(task, node, 2));
	CHECK(CodeGenExprLow(task, CG_GET_NTH(node, 0), FALSE));
	CHECK(CodeGenCheckFreeSpace(task, 2));
	CodeGenEmitByteNoCheck(task, opcode);
	CodeGenEmitByteNoCheck(task, nodeTok.data.key);
	break;
    }

    case BC_PROPERTY:
    {
	EC_CHECK_NUM_CHILDREN(node, 2);
	CHECK(CodeGenExprLow(task, CurTree_GET_NTH(node, 0), FALSE));

	if (lval) {
	    opcode = OP_BC_PROPERTY_LV;
	} else {
	    opcode = OP_BC_PROPERTY_RV;
	}

	CHECK(CodeGenCheckFreeSpace(task, 2));
	CodeGenEmitByteNoCheck(task, opcode);
	CodeGenEmitByteNoCheck(task, nodeTok.data.key);
	break;
    }

    case STRUCT_REF:
    {
	ExtendedType structET;
	word	structVtab;
	VTabEntry	vte;
	dword	fieldName;

	/* Code stream: byte[opcode], word[offset]
	 * stack: struct TOS
	 */
	EC_CHECK_NUM_CHILDREN(node, 2);
	CHECK(CodeGenExprLow(task, CurTree_GET_NTH(node, 0), FALSE));
	opcode = lval ? OP_STRUCT_REF_LV : OP_STRUCT_REF_RV;

	CHECK(CodeGenCheckFreeSpace(task, 3));

	CodeGenEmitByteNoCheck(task, opcode);

	structET = TypeOfNthChild(task, node, 0);
	EC_ERROR_IF(ET_TYPE(structET) != TYPE_STRUCT, BE_FAILED_ASSERTION);
	structVtab = StringTableGetData(STRUCT_TABLE, ET_DATA(structET));

	;{	/* Extract fieldName from child 1 */
	    Token*	tmpTok;
	    tmpTok = CurTree_LOCK(CurTree_GET_NTH(node, 1));
	    EC_ERROR_IF(tmpTok->code != INTERNAL_IDENTIFIER,
			BE_FAILED_ASSERTION);
	    fieldName = tmpTok->data.key;
	    HugeTreeUnlock(tmpTok);
	}

	if (!VTLookup(task->vtabHeap, structVtab, fieldName, &vte,NULL))
	{
	    /* The field is checked during the type checking phase; it should
	     * be correct here.
	     */
	    EC_ERROR(BE_FAILED_ASSERTION);
	    SetError(task, E_UNDEFINED_STRUCT_FIELD);
	    return FALSE;
	}
	CodeGenEmitWordNoCheck(task, vte.VTE_offset);
	break;
    }

    case PROPERTY:
    case CUSTOM_PROPERTY:
    {
	Boolean	isStack;
	Token*	tmpTok;
	dword	propKey;

	/* Code stream: byte[opcode], word[prop name]?
	 * stack: component (name?) TOS
	 */
	tmpTok = CurTree_LOCK(CurTree_GET_NTH(node, 1));
	if (tmpTok->code == CONST_STRING) 
	{
	    TCHAR   *str;
	    isStack = FALSE;
	    propKey = tmpTok->data.key;
	    /* now lets move the string into the string const table and
	     * use the const table key
	     */
	    str = StringTableLock(ID_TABLE, propKey);
	    propKey = StringTableAdd(CONST_TABLE, str);
	    StringTableUnlock(str);
	} else {
	    isStack = TRUE;
	}
	HugeTreeUnlock(tmpTok);

	if (nodeTok.code == CUSTOM_PROPERTY) {
	    opcode = lval ? OP_CUSTOM_PROPERTY_LV : OP_CUSTOM_PROPERTY_RV;
	} else {
	    opcode = (isStack ? (lval ? OP_STACK_PROPERTY_LV : 
				    	OP_STACK_PROPERTY_RV)
		      	: (lval ? OP_PROPERTY_LV : OP_PROPERTY_RV));
	}
	/* Name is either inlined in code or put on stack */
	EC_CHECK_NUM_CHILDREN(node, 2);

	CHECK(CodeGenExprLow(task, CurTree_GET_NTH(node, 0), FALSE));

	if (isStack) {
	    CHECK(CodeGenExprLow(task, CurTree_GET_NTH(node, 1), FALSE));
	    CHECK(CodeGenEmitByte(task, opcode));
	} else {
	    CHECK(CodeGenCheckFreeSpace(task, 3));
	    CodeGenEmitByteNoCheck(task, opcode);
	    CodeGenEmitWordNoCheck(task, (word)propKey);
	}
	break;
    }

    case IDENTIFIER:
    {
	EC_CHECK_NUM_CHILDREN(node, 0);

	switch (VAR_KEY_TYPE(nodeTok.data.key)) {
	case VAR_LOCAL:
	    if (lval) {
		opcode = OP_LOCAL_VAR_LV;
	    }
	    else {
		if (RUN_HEAP_TYPE_CT(nodeTok.type) 
		    || nodeTok.type == TYPE_UNKNOWN)  {
		    opcode = OP_LOCAL_VAR_RV_REFS;
		}
		else {
		    opcode = OP_LOCAL_VAR_RV;
		}
	    }
	    
	    break;
	case VAR_MODULE:
	    if (lval) {
		opcode = OP_MODULE_VAR_LV;
	    }
	    else {

		if (RUN_HEAP_TYPE_CT(nodeTok.type) ||
		    nodeTok.type == TYPE_UNKNOWN) {
		    opcode = OP_MODULE_VAR_RV_REFS;
		}
		else {
		    opcode = OP_MODULE_VAR_RV;
		}
	    }

	    break;
#if ERROR_CHECK
	default:
	    EC_ERROR(BE_FAILED_ASSERTION);
	    break;
#endif
	}

	/* check to see if this can qualify for the one byte version
	 * of the opcode
	 */
	CHECK(CG_EmitWordOrByteVar(task, opcode, nodeTok.data.key));
	    
	break;
    }
    case ARRAY_REF:
    case ARRAY_REF_C1:
    case ARRAY_REF_L1:
    case ARRAY_REF_M1:
    {
	CHECK(CGE_ArrayRef(task, node, lval, nodeTok.code));
	break;
    }

    case BUILT_IN_FUNC:
    {
	CHECK(CGE_Children(task, node, 0));

	/* output an OP_CALL_PRIMITIVE followed by the 
	 * built in function index into the table of functions
	 */
	CHECK(CodeGenCheckFreeSpace(task, 3));
	CodeGenEmitByteNoCheck(task,OP_CALL_PRIMITIVE);
	CodeGenEmitWordNoCheck(task,nodeTok.data.integer);
	break;
    }
	    
    case USER_PROC:
    case USER_FUNC:
    {
	TokenCode par_code;
	Token	*parentPtr;
	Node	parent;
	word    n,i;
	FTabEntry*	ftab;
	LegosType	argType;
	VTabEntry	funcVar;

	if (nodeTok.code == USER_FUNC) 
	{
	    CHECK(CodeGenCheckFreeSpace(task, 2));
	    CodeGenEmitByteNoCheck(task,OP_ZERO);
	    
	    /* Now find the return type of the function... */
	    
	    ftab = FTabLock(task->funcTable, nodeTok.data.integer);
	    
	    EC_ERROR_IF(ftab->compStatus < CS_PARSED,
			BE_FAILED_ASSERTION);

	    EC_ERROR_IF(ftab->funcType != FT_FUNCTION, BE_FAILED_ASSERTION);

	    VTLookupIndex(task->vtabHeap, ftab->vtab, 0, &funcVar);
	    CodeGenEmitByteNoCheck(task, funcVar.VTE_type);
	    FTabUnlock(ftab);
	}

	/* Now look and see if any types of our calling arguments
	   are unknown at compile time. If so, we need to tell our
	   runtime this...
	*/
	
	n = HugeTreeGetNumChildren(task->vmHandle, task->tree, node);
	for (i = 0; i < n; i++) {
	    argType = ET_TYPE(TypeOfNthChild(task, node, i));
	    if (argType == TYPE_UNKNOWN) {
		break;
	    }
	}

	CHECK(CGE_Children(task, node, 0));

	CHECK(CodeGenCheckFreeSpace(task, 3));
	CodeGenEmitByteNoCheck(task,
			       (argType == TYPE_UNKNOWN) ? 
			       OP_CALL_WITH_TYPE_CHECK :
			       OP_CALL);
	LabelCreateGlobalFixup(task, nodeTok.data.integer, 
			       nodeTok.code == USER_PROC ? 
			       GRT_PROC_CALL : GRT_FUNC_CALL);
	CodeGenEmitWordNoCheck(task,nodeTok.data.integer);

	/* procedures must come under NULLCODE (blocks of code),
	 * functions may not (or at least, require their return value
	 * to be discarded).
	 *
	 * Parse phase doesn't make checks along this line, so do it here.
	 * make sure we are ok in this pass
	 */
	parent = HugeTreeGetParent(task->vmHandle, task->tree, node);
	parentPtr = (Token *)HugeTreeLock(task->vmHandle, task->tree, parent);
	par_code = parentPtr->code;
	HugeTreeUnlock(parentPtr);

	if (par_code != NULLCODE)
	{
	    if (nodeTok.code == USER_PROC)
	    {
		SetError(task, E_SUB_NOT_RVAL);
		return FALSE;
	    }
	}
	else			/* par_code != NULLCODE */
	{
	    if (nodeTok.code == USER_FUNC)
	    {
		SetError(task, E_EXPECT_FUNC);
		return FALSE;
	    }
	}
	break;
    }

    case PUSH_ZERO:
    {
	CHECK(CodeGenCheckFreeSpace(task, 2));
	CodeGenEmitByteNoCheck(task, OP_ZERO);
	CodeGenEmitByteNoCheck(task, nodeTok.type);
	break;
    }

    case CONST_INT:
    case CONST_STRING:
    {
	int isByte = 0;
	opcode = TokenToOpCode(nodeTok.code);
	if ((unsigned int)nodeTok.data.integer < 256)
	{
	    if (opcode == OP_INTEGER_CONST) {
		opcode = OP_BYTE_INTEGER_CONST;
		isByte = 1;
	    } else if (opcode == OP_STRING_CONST) {
		opcode = OP_BYTE_STRING_CONST;
		isByte = 1;
	    }
	}
	CHECK(CodeGenCheckFreeSpace(task, 3-isByte));
	CodeGenEmitByteNoCheck(task, opcode);
	LabelCreateConstantRefIfNeeded(nodeTok.typeData);
	if (isByte) {
	    CodeGenEmitByteNoCheck(task, nodeTok.data.integer);
	} else {
	    CodeGenEmitWordNoCheck(task, nodeTok.data.integer);
	}
	break;
    }

    case CONST_LONG:
    case CONST_FLOAT:
    {
 	CHECK(CodeGenCheckFreeSpace(task, 5));
	opcode = TokenToOpCode(nodeTok.code);
	CodeGenEmitByteNoCheck(task, opcode);
	CodeGenEmitDwordNoCheck(task, nodeTok.data.key);
	break;
    }

    case ASSIGN:
    {
	Node	    parent;
	Token	    *parentPtr, *ltoken, *rtoken;
	TokenCode   lcode, rcode, par_code;
	LegosType   rtype, ltype;
	Opcode 	    lscope;
	dword 	    lkey,rkey;
	word 	    varindex;
	byte 	    rin;
	word	    rtypeData;
	int	    rcodeConst = 0; /* 1 for INT, 2 for other constant */
	Opcode      assOp = OP_ASSIGN;

	/* Codegen children by hand, so we can pass lval as TRUE
	 */
	EC_CHECK_NUM_CHILDREN(node, 2);

	/* Check to see if first child is a simple variable,
	   (where simple means a local or module variable).

	   Later we can special case additional assignments,
	   such as properties, arrays, etc.
	*/
	
	ltoken = (Token*) HugeTreeLock(task->vmHandle, task->tree,
				       CG_GET_NTH(node, 0));
	lcode = ltoken->code;
	lkey  = ltoken->data.key;
	ltype = ltoken->type;
    
	HugeTreeUnlock(ltoken);

	rtoken = (Token*) HugeTreeLock(task->vmHandle, task->tree,
				       CG_GET_NTH(node, 1));

	rtype = rtoken->type;
	rcode = rtoken->code;
	rkey = rtoken->data.key;
	rtypeData = rtoken->typeData;
	HugeTreeUnlock(rtoken);

	switch(rcode)
	{
	case CONST_STRING:
	case CONST_LONG:
	case CONST_FLOAT:
	case CONST_INT:
	    rcodeConst++;
	    break;
	}

	/* If the lval is a simple variable and the type
	   of both left and right side are known, then
	   we can inline the lval and perform assignment
	   without any additional type checking....
	*/
	if ((lcode == ARRAY_REF || lcode == ARRAY_REF_C1 ||
	    lcode == ARRAY_REF_L1 || lcode == ARRAY_REF_M1) &&
	    ltype != TYPE_UNKNOWN && rtype != TYPE_UNKNOWN &&
	    (rcodeConst || rcode == IDENTIFIER))
	{
	    /* ok, we have an opertunity to inline the assignment of a
	     * constant or simple variable to an array lvalue
	     */

	    if (RUN_HEAP_TYPE_CT(ltype) || RUN_HEAP_TYPE_CT(rtype)) {
		assOp = OP_ASSIGN_TYPED;
		goto LongVersion;
	    }
	    /* first, spit out the lval for the array */
	    CHECK(CodeGenExprLow(task, CG_GET_NTH(node, 0), TRUE));
	    if (rcodeConst) {
		CHECK(CodeGenCheckFreeSpace(task, 6));
		CodeGenEmitByteNoCheck(task, OP_DIR_ASSIGN_ARRAY_REF_C);
		CodeGenEmitByteNoCheck(task, rtype);
		LabelCreateConstantRefIfNeeded(rtypeData);
		CodeGenEmitDwordNoCheck(task, rkey);
	    } else {
		CHECK(CodeGenCheckFreeSpace(task, 3));
		if (VAR_KEY_TYPE(rkey) == VAR_LOCAL) {
		    CodeGenEmitByteNoCheck(task, OP_DIR_ASSIGN_ARRAY_REF_L);
		} else {
		    CodeGenEmitByteNoCheck(task, OP_DIR_ASSIGN_ARRAY_REF_M);
		    LabelCreateGlobalFixup(task, rkey, GRT_MODULE_VAR);
		}
		CodeGenEmitWordNoCheck(task, VAR_KEY_OFFSET(rkey, 
							    task->funcNumber));
	    }
	}
	else if (lcode == IDENTIFIER && ltype != TYPE_UNKNOWN &&
	    rtype != TYPE_UNKNOWN)
	{
	    /* yyyyyyyeeeeesssss! We can inline the lval */

	    if (RUN_HEAP_TYPE_CT(ltype) || RUN_HEAP_TYPE_CT(rtype)) {
		assOp = OP_ASSIGN_TYPED;
		goto LongVersion;
	    }

	    if (VAR_KEY_TYPE(lkey) == VAR_LOCAL) {
		lscope = OP_LOCAL_VAR_LV;
	    }
#if ERROR_CHECK
	    else if (VAR_KEY_TYPE(lkey) != VAR_MODULE) {
		EC_ERROR(BE_FAILED_ASSERTION);
	    }
#endif
	    else {
		lscope = OP_MODULE_VAR_LV;
	    }

	    varindex = VAR_KEY_OFFSET(lkey, task->funcNumber);

	    /* Now go right.. can we optimize even further
	       by inlining the rval?  We currently allow
	       inlining of constants, local, and module variables
	    */

	    rin = 0;

	    if (rcodeConst) 
	    {
		CHECK(CodeGenCheckFreeSpace(task, 7));

		if (lscope == OP_MODULE_VAR_LV) {
		    CodeGenEmitByteNoCheck(task, OP_DIR_ASSIGN_MC);
		    LabelCreateGlobalFixup(task, lkey, GRT_MODULE_VAR);
		}
		else {
		    CodeGenEmitByteNoCheck(task, OP_DIR_ASSIGN_LC);
		}

		CodeGenEmitWordNoCheck(task, varindex);
		LabelCreateConstantRefIfNeeded(rtypeData);
		CodeGenEmitDwordNoCheck(task, rkey);

		rin = 1;
	    } 
	    else if (rcode == IDENTIFIER) 
	    {
		Boolean	isGlob = FALSE;
		CHECK(CodeGenCheckFreeSpace(task, 5));
		if (VAR_KEY_TYPE(rkey) == VAR_LOCAL) {

		    if (lscope == OP_MODULE_VAR_LV) {
			CodeGenEmitByteNoCheck(task, OP_DIR_ASSIGN_ML);
			LabelCreateGlobalFixup(task, lkey, 
						   GRT_MODULE_VAR);
		    }
		    else {
			CodeGenEmitByteNoCheck(task, OP_DIR_ASSIGN_LL);
		    }
		}
#if ERROR_CHECK
		else if (VAR_KEY_TYPE(rkey) != VAR_MODULE) {
		    EC_ERROR(BE_FAILED_ASSERTION);
		}
#endif
		else {
		    isGlob = TRUE;   
		    if (lscope == OP_MODULE_VAR_LV) {
			CodeGenEmitByteNoCheck(task, OP_DIR_ASSIGN_MM);
			LabelCreateGlobalFixup(task, lkey, 
						   GRT_MODULE_VAR);
		    }
		    else {
			CodeGenEmitByteNoCheck(task, OP_DIR_ASSIGN_LM);
		    }
		}

		CodeGenEmitWordNoCheck(task, varindex);
		if (isGlob) {
		    LabelCreateGlobalFixup(task, rkey, GRT_MODULE_VAR);
		}
		CodeGenEmitWordNoCheck(task, VAR_KEY_OFFSET(rkey,
							    task->funcNumber));

		rin = 1;
	    }

	    
	    if (!rin) 
	    {
		Opcode		op;

		/* We weren't able to inline the rval... 
		   Recurse on the right side to generate the expression
		*/
		CHECK(CodeGenExprLow(task, CG_GET_NTH(node, 1), FALSE));
		if (lscope == OP_MODULE_VAR_LV) {
		    op = OP_EXP_ASSIGN_M;
		} else {
		    op = OP_EXP_ASSIGN_L;
		}

		CHECK(CG_EmitWordOrByteVar(task, op, lkey));
	    }
	}

	else {
LongVersion:
	    CHECK(CodeGenExprLow(task, CG_GET_NTH(node, 0), TRUE));
	    CHECK(CodeGenExprLow(task, CG_GET_NTH(node, 1), FALSE));
	    CHECK(CodeGenEmitByte(task, assOp));
	}

	/* do a semantics check here */
	parent = HugeTreeGetParent(task->vmHandle, task->tree, node);
	parentPtr = HugeTreeLock(task->vmHandle, task->tree, parent);
	par_code = parentPtr->code;
	HugeTreeUnlock(parentPtr);

	/* as assignment can only be a top level token, meaning it
	 * must  be directly below a NULLCODE token, as all blocks
	 * of code are held by a NULLCODE token
	 */
	if (par_code != NULLCODE) return FALSE;

	break;
    }

    case COERCE:

	CHECK(CGE_Children(task, node, 0));

	/* Emit some code to force coercion to the node's type */
	CHECK(CodeGenCheckFreeSpace(task, 2));
	CodeGenEmitByteNoCheck(task, OP_COERCE);
	CodeGenEmitByteNoCheck(task, nodeTok.type);

	break;

    case NOT:
    case NEGATIVE:
    case POSITIVE:

    case PLUS:
    case MINUS:
    case MULTIPLY:
    case DIVIDE:

	/* NOTE: XOR is not here as there is no logical XOR in C so we
	 * decided to bag it
	 */
    case AND:
    case OR:
    case EQUALS:
    case LESS_THAN:
    case LESS_EQUAL:
    case GREATER_THAN:
    case GREATER_EQUAL:
    case LESS_GREATER:

    case BIT_AND:
    case BIT_OR:
    case BIT_XOR:

    {
	LegosType t1;
	LegosType t2;

	CHECK(CGE_Children(task, node, 0));
	t1 = ET_TYPE(TypeOfNthChild(task, node, 0));

	/* For binary operators, check if the second operand is
	   unknown. If so, set t1 to that type since the code
	   to determine which opcode to use checks t1.
	*/
	if (nodeTok.code != NOT && nodeTok.code != NEGATIVE &&
	    nodeTok.code != POSITIVE) {
	    if ((t2=ET_TYPE(TypeOfNthChild(task, node, 1))) == TYPE_UNKNOWN) {
		t1 = TYPE_UNKNOWN;
	    }

#if ERROR_CHECK

	    /* Otherwise, types of both children should be the same! */

	    if (t1 != TYPE_UNKNOWN && t1 != t2)
	    {
		EC_ERROR(BE_FAILED_ASSERTION);
	    }

	    EC_CHECK_NUM_CHILDREN(node, 2);
#else
	    t2 = t2;   /* Get rid of non-ec warning */
#endif

	}
#if ERROR_CHECK
	else {
	    EC_CHECK_NUM_CHILDREN(node, 1);
	}
#endif

/* Cool, give the illusion that this code is much smaller than
   it really is...
*/

#define GEN_CASE(token,root)              \
	                                  \
    case token:                           \
                                          \
        switch(t1) {                      \
	case TYPE_INTEGER:                  \
	    opcode = OP_ ## root ## _INT; \
	    break;                        \
	case TYPE_LONG:                     \
	    opcode = OP_ ## root ## _LONG;\
	    break;                        \
	default:                          \
	    opcode = OP_ ## root  ;       \
	    break;                        \
	}                                 \
	                                  \
	break;                            \

    	if ((nodeTok.code == EQUALS || nodeTok.code == LESS_GREATER) &&
	    t1 == TYPE_STRING) {
	    if (nodeTok.code == EQUALS) {
		opcode = OP_EQUALS_STRING;
	    } else {
		opcode = OP_LESS_GREATER_STRING;
	    }
	} else 	switch(nodeTok.code) {

	    GEN_CASE(NOT          , NOT);
	    GEN_CASE(NEGATIVE     , NEGATIVE);
	    GEN_CASE(POSITIVE     , POSITIVE);

	    GEN_CASE(PLUS         , ADD);
	    GEN_CASE(MINUS        , SUB);
	    GEN_CASE(MULTIPLY     , MULTIPLY);
	    GEN_CASE(DIVIDE       , DIVIDE);
	/* NOTE: XOR is not here as there is no logical XOR in C so we
	 * decided to bag it
	 */
	    GEN_CASE(AND          , AND);
	    GEN_CASE(OR           , OR);
	    GEN_CASE(EQUALS       , EQUALS);
	    GEN_CASE(LESS_THAN    , LESS_THAN);
	    GEN_CASE(LESS_EQUAL   , LESS_EQUAL);
	    GEN_CASE(GREATER_THAN , GREATER_THAN);
	    GEN_CASE(GREATER_EQUAL, GREATER_EQUAL);
	    GEN_CASE(LESS_GREATER , LESS_GREATER);
	    GEN_CASE(BIT_AND	  , BIT_AND);
	    GEN_CASE(BIT_XOR	  , BIT_XOR);
	    GEN_CASE(BIT_OR	  , BIT_OR);
	}
	
	CHECK(CodeGenEmitByte(task, opcode));
	break;
    }

    default:
    {
	CHECK(CGE_Children(task, node, 0));
	opcode = TokenToOpCode(nodeTok.code);
	CHECK(CodeGenEmitByte(task, opcode));
	break;
    }

    } /* end switch */

    return TRUE;
}


/*********************************************************************
 *			CGE_ArrayRef
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Incoming tree looks like:
 *
 * ARRAY_REF(# indices)	<- root
 *   previous root (expression that evaluates to an array)
 *   N other children (expressions) where N = # indices
 *
 * Optimized case:
 *
 * Code:  byte[OP_{LOCAL,MODULE}_ARRAY_REF] byte[# dims] word[offset]
 * Stack: dim1 dim2 dim3
 *
 * General case:
 *
 * Code:  byte[OP_ARRAY_REF] byte[# dims]
 * Stack: dim1 dim2 dim3 array
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 4/26/95	Initial version			     
 * 
 *********************************************************************/
Boolean
CGE_ArrayRef(TaskPtr task, Node node, Boolean lval, TokenCode code)
{
    Token	leftTok, curTok;
    Opcode	opcode;
    word   	lvar;
    word    	isGlob=FALSE;

    do {
	Node	left;
	Token*	nodePtr;
 
	left = CG_GET_NTH(node, 0);
	nodePtr = HugeTreeLock(task->vmHandle, task->tree, left);
	leftTok = *nodePtr;
	HugeTreeUnlock(nodePtr);

	nodePtr = HugeTreeLock(task->vmHandle, task->tree, node);
	curTok = *nodePtr;
	HugeTreeUnlock(nodePtr);
    } while (0);

    lvar = VAR_KEY_TYPE(leftTok.data.key);

    switch (code)
    {
    case ARRAY_REF:
	/* Both cases need code generated for these children
	 */
	CHECK(CGE_Children(task, node, 1));

	if (leftTok.code == IDENTIFIER)
	{
	    switch(lvar) 
	    {
	    case VAR_LOCAL:
		if (lval) {
		    opcode = OP_LOCAL_ARRAY_REF_LV;
		} else {
		    opcode = OP_LOCAL_ARRAY_REF_RV;
		}
		break;
	    case VAR_MODULE:
		if (lval) {
		    opcode = OP_MODULE_ARRAY_REF_LV;
		} else {
		    opcode = OP_MODULE_ARRAY_REF_RV;
		}
		break;
#if ERROR_CHECK
	    default:
		EC_ERROR(BE_FAILED_ASSERTION);
		break;
#endif
	    }

	    CHECK(CodeGenCheckFreeSpace(task, 4));
	    CodeGenEmitByteNoCheck(task, opcode);
	    CodeGenEmitByteNoCheck(task, curTok.data.integer);
	    if (opcode == OP_MODULE_ARRAY_REF_LV ||
		opcode == OP_MODULE_ARRAY_REF_RV) {
		LabelCreateGlobalFixup(task, leftTok.data.key, 
					   GRT_MODULE_VAR);
	    }
	    CodeGenEmitWordNoCheck(task, VAR_KEY_OFFSET(leftTok.data.key,
							task->funcNumber));
	}
    	else
	{
	    /* General case -- 0th child should put array on stack
	     */
	    CHECK(CodeGenExprLow(task, CG_GET_NTH(node, 0), FALSE));
	    CHECK(CodeGenCheckFreeSpace(task, 2));
	    if (lval) {
		CodeGenEmitByteNoCheck(task, OP_ARRAY_REF_LV);
	    } else {
		CodeGenEmitByteNoCheck(task, OP_ARRAY_REF_RV);
	    }
	    CodeGenEmitByteNoCheck(task, curTok.data.integer);
	}
    	break;
    case ARRAY_REF_C1:
	if (lvar == VAR_LOCAL) 
	{
	    if (lval) {
		opcode = OP_LOCAL_ARRAY_REF_C1_LV;
	    } else {
		opcode = OP_LOCAL_ARRAY_REF_C1_RV;
	    }
	}
	else
	{
	    isGlob = TRUE;
	    if (lval) {
		opcode = OP_MODULE_ARRAY_REF_C1_LV;
	    } else {
		opcode = OP_MODULE_ARRAY_REF_C1_RV;
	    }
	}
	goto ARRAY_REF_1_COMMON;
    case ARRAY_REF_L1:
	if (lvar == VAR_LOCAL) 
	{
	    if (lval) {
		opcode = OP_LOCAL_ARRAY_REF_L1_LV;
	    } else {
		opcode = OP_LOCAL_ARRAY_REF_L1_RV;
	    }
	}
	else
	{
	    isGlob = TRUE;
	    if (lval) {
		opcode = OP_MODULE_ARRAY_REF_L1_LV;
	    } else {
		opcode = OP_MODULE_ARRAY_REF_L1_RV;
	    }
	}
	goto ARRAY_REF_1_COMMON;
    case ARRAY_REF_M1:
	if (lvar == VAR_LOCAL) 
	{
	    if (lval) {
		opcode = OP_LOCAL_ARRAY_REF_M1_LV;
	    } else {
		opcode = OP_LOCAL_ARRAY_REF_M1_RV;
	    }
	}
	else
	{
	    isGlob = TRUE;
	    if (lval) {
		opcode = OP_MODULE_ARRAY_REF_M1_LV;
	    } else {
		opcode = OP_MODULE_ARRAY_REF_M1_RV;
	    }
	}

    ARRAY_REF_1_COMMON:
	CHECK(CodeGenCheckFreeSpace(task, 5));
	CodeGenEmitByteNoCheck(task, opcode);
	if (code == ARRAY_REF_M1) {
	    LabelCreateGlobalFixup(task, curTok.data.key, GRT_MODULE_VAR);
	}
	if (code == ARRAY_REF_C1) {
	    LabelCreateConstantRefIfNeeded(curTok.data.key>>16);
	    CodeGenEmitWordNoCheck(task, curTok.data.integer);
	} else {
	    CodeGenEmitWordNoCheck(task, VAR_KEY_OFFSET(curTok.data.key,
							task->funcNumber));
	}
	if (isGlob) {
	    LabelCreateGlobalFixup(task, leftTok.data.key, GRT_MODULE_VAR);
	}
	CodeGenEmitWordNoCheck(task, VAR_KEY_OFFSET(leftTok.data.key,
						    task->funcNumber));
    }	

    return TRUE;
}

/*********************************************************************
 *			CGE_Children
 *********************************************************************
 * SYNOPSIS:	CodeGenExprLow on all children
 * CALLED BY:	INTERNAL CodeGenExprLow
 * RETURN:  	true if everything ok, false otherwise
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 4/26/95	Pulled out of CodeGenExprLow
 * 
 *********************************************************************/
Boolean
CGE_Children(TaskPtr task, Node node, word start)
{
    word	num, i;
    Node	next;

    num = HugeTreeGetNumChildren(task->vmHandle, task->tree, node);
    for (i = start; i < num; i++)
    {
	next = HugeTreeGetNthChild(task->vmHandle, task->tree, node, i);
	if (next == NullNode)
	{
	    EC_ERROR(BE_FAILED_ASSERTION); /* I think this should never
				happen --dubois */
	    break;
	}
	if (!CodeGenExprLow(task, next, FALSE))
	{
	    return FALSE;
	}
    }

    return TRUE;
}
/*********************************************************************
 *			CGE_ChildrenLVal
 *********************************************************************
 * SYNOPSIS:	CodeGenExprLow on all children with lval set true
 * CALLED BY:	INTERNAL CodeGenExprLow
 * RETURN:  	true if everything ok, false otherwise
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 4/26/95	Pulled out of CodeGenExprLow
 * 
 *********************************************************************/
Boolean
CGE_ChildrenLVal(TaskPtr task, Node node, word start)
{
    word	num, i;
    Node	next;

    num = HugeTreeGetNumChildren(task->vmHandle, task->tree, node);
    for (i = start; i < num; i++)
    {
	next = HugeTreeGetNthChild(task->vmHandle, task->tree, node, i);
	if (next == NullNode)
	{
	    EC_ERROR(BE_FAILED_ASSERTION); /* I think this should never
				happen --dubois */
	    break;
	}
	if (!CodeGenExprLow(task, next, TRUE))
	{
	    return FALSE;
	}
    }

    return TRUE;
}
