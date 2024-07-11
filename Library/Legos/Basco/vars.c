/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Compiler
FILE:		vars.c

AUTHOR:		Roy Goldman, Dec 22, 1994

ROUTINES:
	Name			Description
	----			-----------
    EXT VarGetVTabEntry		get a vtab entry for a function's scope/elt
				identifier

    EXT VarGetOffset		Retrieve the offset for a function's
				scope/var# token

    EXT VarAnalyzeFunction	do variable analysis on a single function

    INT Var_Analyze		Recursively var analyze a function

    INT Var_CheckUnused		Check if an identifier hasn't been seen
				before

    INT Var_InstallStruct	Install a structure definition to the
				vtabHeap

    INT Var_InstallDim		Store DIM info in a VTab and add var info
				to DIM

    INT Var_AddExports		Add entries from export table to
				GLOBAL_VTAB as forward refs

    INT Var_VTAdd		Front-end to VTAdd to deal correctly with
				struct IDs

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/22/94   	Initial version.

DESCRIPTION:
	Code for variable analysis phase of parsing a function.
	Uses variable table routines defined in vtab.c

	$Id: vars.c,v 1.1 98/10/13 21:43:53 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "bascoint.h"
#include <tree.h>
#include <Legos/legtype.h>
#include <Legos/edit.h>

#include "vars.h"
#include "stable.h"
#include "btoken.h"
#include "label.h"
#include "ftab.h"

/* - Internal things */

typedef struct {
    word	vtab;
    optr	usedTable;
    Boolean	global;

    /* Maybe set by the LHS of an assign, _just_ before returning
     */
    Boolean	assignDone;
} VarAnalyzeState;

static Boolean	Var_Analyze(TaskPtr task, VarAnalyzeState* vas, Node node,
			    Boolean lval);
static Node	Var_ConvertArrayPropLV(TaskPtr task, Node node);
static Node	Var_ConvertArrayPropRV(TaskPtr task, Node node);

static Boolean	Var_CheckUnused(TaskPtr, optr usedTable, Node);
static void	Var_InstallStruct(TaskPtr task, Node node);
static void	Var_InstallDim(TaskPtr, word vtab, Node, Boolean inStruct);
/*static void	Var_AddExports(TaskPtr);*/
static Boolean	Var_AddExport(TaskPtr task, VarAnalyzeState* vas, word ident);
static word	Var_VTAdd(TaskPtr, word table, word nameId, LegosType,
			  byte varSize, byte flags, word typeData);


#define VTAdd USE_VAR_VTAdd_instead

/*********************************************************************
 *			VarGetVTabEntry
 *********************************************************************
 * SYNOPSIS:	get a vtab entry for a function's scope/elt identifier
 * CALLED BY:	EXTERNAL
 * RETURN:  	vtab entry
 * SIDE EFFECTS:
 * STRATEGY:	look first locally, then globally
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 5/ 5/95	Initial version
 * 
 *********************************************************************/
void
VarGetVTabEntry(TaskPtr task, word funcNumber, dword key, VTabEntry* vte)
{
    word	vtab;

    EC_ERROR_IF(VAR_KEY_TYPE(key) != VAR_MODULE &&
		VAR_KEY_TYPE(key) != VAR_LOCAL, BE_FAILED_ASSERTION);

    if (VAR_KEY_TYPE(key) == VAR_MODULE)
    {
	vtab = GLOBAL_VTAB;
    }
    else
    {
	FTabEntry	*ftab;

	ftab = FTabLock(task->funcTable, funcNumber);
	vtab = ftab->vtab;
	FTabUnlock(ftab);
    }

    VTLookupIndex(task->vtabHeap, vtab, VAR_KEY_ELEMENT(key), vte);
    return;
}

/*********************************************************************
 *			VarGetOffset
 *********************************************************************
 * SYNOPSIS:	Retrieve the offset for a function's scope/var# token
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Just for convenience
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/17/95	Initial version
 * 
 *********************************************************************/
word
VarGetOffset(TaskPtr task, word funcNumber, dword key)
{
    VTabEntry	vte;
    VarGetVTabEntry(task, funcNumber, key, &vte);
    return vte.VTE_offset;
}

/*********************************************************************
 *			VarAnalyzeFunction
 *********************************************************************
 * SYNOPSIS:	do variable analysis on a single function
 * CALLED BY:	EXTERNAL, BascoCompileFunction
 * RETURN:  	TRUE if everything is ok
 * SIDE EFFECTS:
 *	variables are converted from strings to entry numbers in the
 *	function's vtab or the global vtab
 *
 * STRATEGY:
 *	Create a temporary string table to store all identifier
 *	refs; this helps catch var-use-before-dim errors (like use of
 *	global, then re-dim to local)
 *
 *	Table is destroyed before exit.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/22/94	Initial version			     
 * 
 *********************************************************************/
Boolean
VarAnalyzeFunction(TaskPtr task, word funcNumber)
{
    FTabEntry*	ftab;
    word	vtab;		/* VTable used for this function */
    Boolean	retval, isFunc;
    optr	usedTable;	/* Temporary string table */
    word	i, numParams;
    TCHAR	buf[64];
    VarAnalyzeState vas;
    word	oldDS;

    /* right off we can reset the global variables for this function */
    VTResetGlobalsForFunction(task->vtabHeap, funcNumber, FALSE);

    EC_ERROR_IF(FTabGetCount(task->funcTable) <=
		    	    	    	    funcNumber, BE_FAILED_ASSERTION);

    /* Set up the current function in the task,
     * Create a new VTab.
     */
    ftab = FTabLock(task->funcTable, funcNumber);

    /* Set up vas.global
     */
    EditGetRoutineName(task->task_han, funcNumber, buf);

    oldDS = setDSToDgroup();
    if (ftab->global
	|| !strcmp(buf,_TEXT("duplo_start"))
	|| !strcmp(buf, _TEXT("duplo_ui_ui_ui")))
    {
	vas.global = TRUE;
	ftab->global = TRUE;
	FTabDirty(ftab);
    } else {
	vas.global = FALSE;
    }
    restoreDS(oldDS);
    task->tree = ftab->tree;
    task->funcNumber = funcNumber;

    usedTable = StringTableCreate(task->vmHandle);
    if (ftab->vtab != NULL_VTAB)
    {
	VTDestroy(task->vtabHeap, ftab->vtab);
    }
    vtab = ftab->vtab = VTAlloc(task->vtabHeap);
    FTabDirty(ftab);
    FTabUnlock(ftab);
    EC( ftab = (void*)0xcccccccc; )

    /* numParams <- number of parameters to routine
     * isFunc    <- FALSE if this is a procedure
     */
    ;{
	Node	numNode;
	Token*	temp;

	numNode = CurTree_GET_NTH(TREE_ROOT, 0);
	EC_ERROR_IF(numNode == NullNode, BE_FAILED_ASSERTION);
	temp = CurTree_LOCK(numNode);
	numParams = temp->data.integer;
	HugeTreeUnlock(temp);
	
	temp = CurTree_LOCK(TREE_ROOT);
	EC_ERROR_IF(temp->code != FUNCTION && temp->code != SUB,
		    BE_FAILED_ASSERTION);
	isFunc = (temp->code == FUNCTION);
	HugeTreeUnlock(temp);

    }

    /* If function, install return value first.
     * It will be the node after all the params.
     */
    if (isFunc)
    {
	Token*	typeTok;
	TCHAR*	fname;
	word	stringId;
	word	varNum;

	fname = StringTableLock(task->stringFuncTable, funcNumber);
	EC_ERROR_IF(fname == NULL, BE_FAILED_ASSERTION);
	stringId = StringTableAdd(task->stringIdentTable, fname);
	(void)     StringTableAdd(usedTable, fname);
	StringTableUnlock(fname);

	typeTok = CurTree_LOCK(CurTree_GET_NTH(TREE_ROOT, numParams+1));
	varNum = Var_VTAdd(task, vtab,
			   stringId, TokenToType(typeTok->code),
			   STD_SIZE, 0, typeTok->data.key);
	HugeTreeUnlock(typeTok);
	if (ERROR_SET) 
	{
	    retval = FALSE;
	    goto    done;
	}

	EC_ERROR_IF(varNum != 0, BE_FAILED_ASSERTION);
	NEC((void) varNum);
    }


    /* Handle the routine's parameters (child 1 - child <numParams>)
     */
    for (i = 1; i <= numParams; i++) 
    {
	Node	paramNode;
	word	paramName;
	LegosType paramType;
	word    varNum;

	Token*	t;
	word	ln;
	dword	extraData;
	word	numChildren;

	paramNode = CurTree_GET_NTH(TREE_ROOT, i);
	EC_ERROR_IF(paramNode == NullNode, BE_FAILED_ASSERTION);

	t = CurTree_LOCK(paramNode);
	ln = t->lineNum;
	paramName = t->data.key;

	/* Don't allow redeclaration of the same variable
	 */
	if ( VTLookup(task->vtabHeap, vtab, paramName, NULL, NULL) )
	{
	    HugeTreeUnlock(t);
	    task->ln = ln;
	    SetError(task, E_VARIABLE_ALREADY_DEFINED);
	    retval = FALSE;
	    goto    done;
	}

	/* If the identifier has a child, that's its type.
	 * Identifiers need not have types
	 */
	numChildren = CurTree_NUM_CHILDREN(paramNode);
	EC_ERROR_IF(numChildren > 1, BE_FAILED_ASSERTION);
	if (numChildren == 0)
	{
	    paramType = TYPE_NONE;
	    extraData = NullElement;
	    t->type = TYPE_UNKNOWN;
	    HugeTreeDirty(t);
	}
	else
	{
	    Node	typeNode;
	    Token*	typeToken;

	    typeNode = CurTree_GET_NTH(paramNode, 0); /* # children - 1 */
	    typeToken = CurTree_LOCK(typeNode);

	    paramType = TokenToType(typeToken->code);
	    if (CurTree_NUM_CHILDREN(typeNode)==1)
	    {
		paramType |= TYPE_ARRAY_FLAG;
	    }
	    extraData = typeToken->data.key;

	    HugeTreeUnlock(typeToken);
	}

	/* Technically don't need to store key here, but
	 * it makes BascoRestoreModuleToParsedStatus hella easier...
	 */
	varNum = Var_VTAdd(task, vtab, paramName, paramType,
			   STD_SIZE, 0, extraData);
	t->data.key = MAKE_VAR_KEY(VAR_LOCAL, varNum);
	
	HugeTreeDirty(t);
	HugeTreeUnlock(t);
	if (ERROR_SET) 
	{
	    retval = FALSE;
	    goto    done;
	}

	/* Add param name to usedTable
	 */
	;{
	    TCHAR*	str;
	    str = StringTableLock(task->stringIdentTable, paramName);
	    StringTableAdd(usedTable, str);
	    StringTableUnlock(str);
	}
    }

    /* If this is a function, return type is after params; skip over
     * it to get to the body.
     */
    if (isFunc) i++;

    vas.vtab		= vtab;
    vas.usedTable	= usedTable;
 /* vas.global		= already set */
    vas.assignDone	= FALSE;
    retval = Var_Analyze(task, &vas, CurTree_GET_NTH(TREE_ROOT, i), FALSE);

 done:
    StringTableDestroy(usedTable);

    if (retval) {
	ftab = FTabLock(task->funcTable, funcNumber);
	ftab->compStatus = CS_VAR_ANALYZED;
	FTabDirty(ftab);
	FTabUnlock(ftab);
    }

    return retval;
}

/*********************************************************************
 *			Var_Analyze
 *********************************************************************
 * SYNOPSIS:	Recursively var analyze a function
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Convert identifiers into variable references (scope/var# pairs)
 *
 *	Convert STRUCT_REFs into vtab/var# pairs
 *
 *	Add DIMs to variable table; also add unknown variables unless
 *	force_declarations is true, in which case raise an error.
 *
 *	Add EXPORTs to export table.  At end of recursion, caller
 *	will shuffle these to the beginning of the global vtab.
 *
 *	if vas->global, vtab is ignored
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/22/94	Initial version			     
 * 
 *********************************************************************/
static Boolean
Var_Analyze(TaskPtr task, VarAnalyzeState* vas, Node node, Boolean lval)
{
    word	i, numChildren;
    TokenCode	code;
    Token*	t;
 
#if ERROR_CHECK
    /* Should only be set when returning from ARRAY_REF to ASSIGN, and
     * never on a recursion
     */	
    if (vas->assignDone) {
	SetError(task, E_INTERNAL);
	return FALSE;
    }
#endif

    t = HugeTreeLock(task->vmHandle, task->tree, node);
    task->ln = t->lineNum;
    code = t->code;
    HugeTreeUnlock(t);

    switch(code)
    {
    case ASSIGN:
    {
	Boolean	retval;

	retval = Var_Analyze(task, vas, CurTree_GET_NTH(node, 0), TRUE);
	if (vas->assignDone || !retval)
	{
	    vas->assignDone = FALSE;	/* reset */
	    return retval;
	}	    
	
	return (Var_Analyze(task, vas, CurTree_GET_NTH(node, 1), FALSE));
	/* Don't break, as that will cause us to recurse down below */
    }

    case ARRAY_REF:
    {
	Token*		tok;
	TokenCode	childCode;
	Boolean		retval;
	Node		newNode;

	tok = CurTree_LOCK(CurTree_GET_NTH(node,0));
	childCode = tok->code;
	HugeTreeUnlock(tok);
	
	if (childCode != PROPERTY) break;
	
	if (lval) {
	    /* Returns the node with which the ASSIGN just above us
	     * has been replaced.  Analyze that node instead, and
	     * signal to caller that the rest of the ASSIGN should
	     * not be analyzed
	     */
	    newNode = Var_ConvertArrayPropLV(task, node);
	    if (ERROR_SET) return FALSE;
	    retval = Var_Analyze(task, vas, newNode, FALSE);
	    vas->assignDone = TRUE;
	    return retval;
	} else {
	    newNode = Var_ConvertArrayPropRV(task, node);
	    if (ERROR_SET) return FALSE;
	    return Var_Analyze(task, vas, newNode, FALSE);
	}
    }

    case DIM:
    {
	/* Temporarily, we don't make this check in a decl routine,
	 * to keep globals from shifting about.
	 * FIXME: replace this with something that doesn't hide
	 * valid errors
	 */
	if (vas->global
	    || Var_CheckUnused(task, vas->usedTable, node))
	{
	    Var_InstallDim(task,
			   vas->global ? GLOBAL_VTAB : vas->vtab,
			   node, FALSE);
	    if (task->flags & COMPILE_NEEDS_FULL_RECOMPILE) {
		return TRUE;
	    }
	    if (ERROR_SET)
	    {
		return FALSE;
	    }
	}
	else
	{
	    return FALSE;
	}
	break;
    }
    case EXPORT:
    {
	Boolean	retval;

	t = CurTree_LOCK(node);
	retval = Var_AddExport(task, vas, t->data.integer);
	HugeTreeUnlock(t);

	if (!retval)
	{
	    return FALSE;
	}
	break;
    }
    case IDENTIFIER:
    {
	TCHAR*		str;
	VTabEntry	vte;
	word		index;

	/* First record that we've seen this string
	 */
	t = HugeTreeLock(task->vmHandle, task->tree, node);
	str = StringTableLock(task->stringIdentTable, t->data.integer);
	EC_ERROR_IF(str == NULL, BE_FAILED_ASSERTION);
	StringTableAdd(vas->usedTable, str);
	StringTableUnlock(str);

	/* even declaration routines could have return values */
	if (VTLookup(task->vtabHeap, vas->vtab, t->data.key, &vte, &index) )
	{
	    /* Local -- declaration routines have no local vars
	     */
	    t->type = vte.VTE_type;
	    t->typeData = vte.VTE_extraInfo;
	    t->data.key = MAKE_VAR_KEY(VAR_LOCAL, index);
	}
	else if ( VTLookup(task->vtabHeap, GLOBAL_VTAB,
			   t->data.key, &vte, &index) )
	{
	    /* Global
	     */
	    t->type = vte.VTE_type;
	    t->typeData = vte.VTE_extraInfo;
	    t->data.key = MAKE_VAR_KEY(VAR_MODULE, index);
	}
	else
	{
	    /* Undeclared variable.  Add a forward ref to it.  Type checker
	     * will raise an error if it's still not defined then
	     */
	    dword	identKey;

	    /* Hack -- so type checker actually looks up the var */
	    t->type = TYPE_VOID;

	    identKey = t->data.key;
	    index = Var_VTAdd(task, GLOBAL_VTAB, identKey, TYPE_VOID,
			      STD_SIZE, VTF_FORWARD_REF, 0);
	    t->data.key = MAKE_VAR_KEY(VAR_MODULE, index);
	    task->ln = t->lineNum;
	}
	HugeTreeDirty(t);
	HugeTreeUnlock(t);
	if (ERROR_SET) return FALSE; /* Var_VTAdd can fail */
	break;
    }
    case STRUCTDECL:
    {
	if (vas->global) {
	    Var_InstallStruct(task, node);
	    if (task->flags & COMPILE_NEEDS_FULL_RECOMPILE) {
		return FALSE;
	    }
	    if (ERROR_SET) return FALSE;
	} else {
	    SetError(task, E_STRUCT_DEFN_NOT_ALLOWED);
	    return FALSE;
	}
	return TRUE;		/* Don't recurse on children */
    }
    } /* switch */
	
    /* Recurse for all cases which don't recurse themselves
     */
    numChildren = CurTree_NUM_CHILDREN(node);
    for (i = 0; i < numChildren; i++)
    {
	Node	child;
	child = CurTree_GET_NTH(node, i);
	if (! Var_Analyze(task, vas, child, FALSE))
	{
	    return FALSE;
	}
    }
    return TRUE;
}

/*********************************************************************
 *			Var_ConvertArrayPropLV
 *********************************************************************
 * SYNOPSIS:	Convert an array prop lval to an action
 * CALLED BY:	INTERNAL
 * RETURN:	Node with which ASSIGN was replaced
 * SIDE EFFECTS:
 * STRATEGY:
 *			Mess with tree, so:
 *
 *	ASSIGN
 *	 AREF(# indices)
 *	  PROP
 *	   Subtree A (comp)
 *	   CONST_STRING("p")
 *	  Subtrees B (indices)
 *	 Subtree C (value)
 *			goes to
 *	ACTION
 *	 Subtree A (comp)
 *	 CONST_STRING("Setp")
 *	 Subtrees B (indices)
 *	 Subtree C (value)
 *	 CONST_INT(# nodes)
 *
 *	<node> is the AREF, ASSIGN is our parent.
 *
 *	1. Remove ASSIGN from parent; put PROP there instead.
 *	   This makes the ASSIGN-AREF tree orphaned.
 *	2. Append indices and value to PROP node
 *	3. Make PROP into ACTION
 *	4. Append AREF to PROP node; make AREF into CONST_INT
 *
 *	Recycle the PROP node for the # nodes node.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	10/23/95	Initial version
 * 
 *********************************************************************/
static Node
Var_ConvertArrayPropLV(TaskPtr task, Node node)
{
    Node	propNode, assignNode;
    Token	*tmpTok;
    sword	nIndices;
    word	oldDS;

    assignNode = CurTree_GET_PARENT(node);
    propNode = CurTree_GET_NTH(node, 0);

    tmpTok = CurTree_LOCK(node);		/* AREF */
    nIndices = (word)tmpTok->data.key;
    HugeTreeUnlock(tmpTok);

    /* 1. Remove ASSIGN from parent; replace it with PROP
     */
    ;{
	Node	parentNode;
	sword	index;

	parentNode = CurTree_GET_PARENT(assignNode);
	index = CurTree_GET_INDEX(assignNode);
	/* Remove PROP from aref for kicks */
	CurTree_SET_NTH(node, 0, NullNode);
	CurTree_SET_NTH(parentNode, index, propNode);
    }

    /* 2. Append indices and value to PROP node
     */
    ;{
	word	i;
	Node	valNode;
	for (i=0; i<nIndices; i++)
	{
	    Node	indexNode;
	    indexNode = CurTree_GET_NTH(node, i+1);
	    CurTree_SET_NTH(node, i+1, NullNode);
	    CurTree_APPEND(propNode, indexNode);
	}
	valNode = CurTree_GET_NTH(assignNode, 1);
	CurTree_SET_NTH(assignNode, 1, NullNode);
	CurTree_APPEND(propNode, valNode);
    }
    
    /* 3. Make PROP into ACTION
     */
    ;{
	TCHAR	actionBuf[84], *propName;
	Node	propNameNode;

	tmpTok = CurTree_LOCK(propNode);
	tmpTok->code = ACTION;
	HugeTreeDirty(tmpTok);
	HugeTreeUnlock(tmpTok);

	propNameNode = CurTree_GET_NTH(propNode, 1);
	tmpTok = CurTree_LOCK(propNameNode);
	if (tmpTok->code != CONST_STRING) {
	    /* Don't want to handle creating a + now; maybe later */
	    SetError(task, E_ARRAY_PROP_NOT_ALLOWED);
	    HugeTreeUnlock(tmpTok);
	    return NullNode;
	}

	oldDS = setDSToDgroup();
	propName = StringTableLock(ID_TABLE, tmpTok->data.integer);
	strcpy(actionBuf, _TEXT("Set"));
	strncat(actionBuf, propName, 80);
	StringTableUnlock(propName);
	tmpTok->data.key = StringTableAdd(ID_TABLE, actionBuf);
	restoreDS(oldDS);

	HugeTreeDirty(tmpTok);
	HugeTreeUnlock(tmpTok);
    }

    /* 4. Append AREF to PROP node; make AREF into CONST_INT
     */
    ;{
	/* CONST_INT is for # args: indices + 1 for the value */
	tmpTok = CurTree_LOCK(node);
	tmpTok->code = CONST_INT;
	tmpTok->data.key++;	/* add 1 for value */
	HugeTreeDirty(tmpTok);
	HugeTreeUnlock(tmpTok);

	CurTree_SET_NTH(assignNode, 0, NullNode); /* remove node */
	CurTree_APPEND(propNode, node);
    }

    return propNode;
}

/*********************************************************************
 *			Val_ConvertArrayPropRV
 *********************************************************************
 * SYNOPSIS:	Convert an array prop rval to an action
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *			Mess with tree, so:
 *	ARRAY_REF
 *	 PROPERTY
 *	  Subtree A (comp)
 *	  CONST_STRING("p")
 *	 Subtrees B (indices)
 *			goes to
 *	ACTION
 *	 Subtree A (comp)
 *	 CONST_STRING("Getp")
 *	 Subtrees B (indices)
 *	 CONST_INT(# nodes)
 *
 *	1. Remove AREF from parent; put PROP there instead.
 *	   This makes the AREF tree orphaned.
 *	2. Append indices to PROPERTY
 *	3. Change PROPERTY to ACTION
 *	4. Append ARRAY_REF and change it to CONST_INT (# args)
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	10/23/95	Initial version
 * 
 *********************************************************************/
static Node
Var_ConvertArrayPropRV(TaskPtr task, Node node)
{
    Node	propNode;
    Token	*tmpTok;
    sword	nIndices;
    word	oldDS;

    propNode = CurTree_GET_NTH(node, 0);

    tmpTok = CurTree_LOCK(node);
    nIndices = (word)tmpTok->data.key;
    HugeTreeUnlock(tmpTok);

    /* 1. Remove ASSIGN from parent; replace it with PROP
     */
    ;{
	Node	parentNode;
	sword	index;

	parentNode = CurTree_GET_PARENT(node);
	index = CurTree_GET_INDEX(node);
	/* Remove PROP from aref for kicks */
	CurTree_SET_NTH(node, 0, NullNode);
	CurTree_SET_NTH(parentNode, index, propNode);
    }

    /* 2. Append indices to PROP node
     */
    ;{
	word	i;

	for (i=0; i<nIndices; i++)
	{
	    Node	indexNode;
	    indexNode = CurTree_GET_NTH(node, i+1);
	    CurTree_SET_NTH(node, i+1, NullNode);
	    CurTree_APPEND(propNode, indexNode);
	}
    }

    /* 3. Make PROP into ACTION
     */
    ;{
	TCHAR	actionBuf[84], *propName;
	Node	propNameNode;

	tmpTok = CurTree_LOCK(propNode);
	tmpTok->code = ACTION;
	HugeTreeDirty(tmpTok);
	HugeTreeUnlock(tmpTok);

	propNameNode = CurTree_GET_NTH(propNode, 1);
	tmpTok = CurTree_LOCK(propNameNode);
	if (tmpTok->code != CONST_STRING) {
	    /* Don't want to handle creating a + now; maybe later */
	    SetError(task, E_ARRAY_PROP_NOT_ALLOWED);
	    HugeTreeUnlock(tmpTok);
	    return NullNode;
	}

	oldDS = setDSToDgroup();
	propName = StringTableLock(ID_TABLE, tmpTok->data.integer);
	strcpy(actionBuf, _TEXT("Get"));
	strncat(actionBuf, propName, 80);
	StringTableUnlock(propName);
	tmpTok->data.key = StringTableAdd(ID_TABLE, actionBuf);
	restoreDS(oldDS);

	HugeTreeDirty(tmpTok);
	HugeTreeUnlock(tmpTok);
    }

    /* 4. Append AREF to PROP node; make AREF into CONST_INT
     */
    ;{
	/* CONST_INT is for # args */
	tmpTok = CurTree_LOCK(node);
	tmpTok->code = CONST_INT;
	HugeTreeDirty(tmpTok);
	HugeTreeUnlock(tmpTok);

	CurTree_SET_NTH(node, 0, NullNode); /* remove node */
	CurTree_APPEND(propNode, node);
    }

    return propNode;
}

/*********************************************************************
 *			Var_CheckUnused
 *********************************************************************
 * SYNOPSIS:	Check if an identifier hasn't been seen before
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Return FALSE if this DIM's identifier has already been used.
 *	This is illegal.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/25/95	Initial version			     
 * 
 *********************************************************************/
static Boolean
Var_CheckUnused(TaskPtr task, optr usedTable, Node node)
{
    Node	nameNode;
    TCHAR*	str;
    Token*	nameToken;
    word	ln;
    Boolean	retval;

    nameNode = CurTree_GET_NTH(node, ARRAY_IDENT_NODE);
    EC_ERROR_IF(nameNode == NullNode, BE_FAILED_ASSERTION);

    nameToken = CurTree_LOCK(nameNode);
    ln  = nameToken->lineNum;
    str = StringTableLock(task->stringIdentTable, nameToken->data.integer);
    EC_ERROR_IF(str == NULL, BE_FAILED_ASSERTION);
    HugeTreeUnlock(nameToken);

    if (StringTableLookupString(usedTable, str) != NullElement)
    {
	/* Can't dimension a variable after you refer to it */
	task->ln = ln;
	SetError(task, E_VARIABLE_ALREADY_DEFINED);
	retval = FALSE;
    }
    else
    {
	StringTableAdd(usedTable, str);
	retval = TRUE;
    }

    StringTableUnlock(str);
    return retval;
}

/*********************************************************************
 *			Var_InstallStruct
 *********************************************************************
 * SYNOPSIS:	Install a structure definition to the vtabHeap
 * CALLED BY:	INTERNAL, Var_Check
 * RETURN:	nothing
 * SIDE EFFECTS:	May return with error set
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/26/95	Initial version
 * 
 *********************************************************************/
static void
Var_InstallStruct(TaskPtr task, Node node)
{
    Token*	t;
    TCHAR*	structName;
    dword	key;
    word	oldVtab;
    word	vtab;
    word	i, numChildren;

    /* Find old vtab for this struct; install a fresh one.
     */
    t = CurTree_LOCK(node);
    structName = StringTableLock(ID_TABLE, t->data.integer);
    HugeTreeUnlock(t);

    key = StringTableLookupWithData(STRUCT_TABLE, structName, sizeof(word), 
				    &oldVtab);
    if (key == NullElement) {
	oldVtab = NULL_VTAB;
    }

    vtab = VTAlloc(task->vtabHeap);
    (void) StringTableAddWithData(task->structIndex, structName, sizeof(word),
				  &vtab);
    StringTableUnlock(structName);

    numChildren = CurTree_NUM_CHILDREN(node);
    for (i=0; i<numChildren; i++)
    {
	Var_InstallDim(task, vtab, CurTree_GET_NTH(node, i), TRUE);
	if (task->flags & COMPILE_NEEDS_FULL_RECOMPILE) {
	    return;
	}
    }

    /* FIXME: compare oldVtab and vtab, determine if recompile needed */
    if (oldVtab != NULL_VTAB)
    {
	int	diff;

	diff = VTCompareTables(task->vtabHeap, oldVtab, vtab);
	VTDestroy(task->vtabHeap, oldVtab);
	if (diff) {
	    task->flags |= COMPILE_NEEDS_FULL_RECOMPILE;
	}
    }
    return;
}

/*********************************************************************
 *			Var_InstallDim
 *********************************************************************
 * SYNOPSIS:	Store DIM info in a VTab and add var info to DIM 
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS: Could return with error set
 * STRATEGY:
 *	DIM tree looks like:
 *
 *	(DIM (ident) (# indices) [subtrees for indices...] type)
 *
 *	If the DIM is for an array, a scope/var# is added to the
 *	data for the DIM node.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/23/94	Initial version			     
 * 
 *********************************************************************/
static void
Var_InstallDim(TaskPtr task, word vtab, Node node, Boolean inStruct)
{
    word	nameId;
    word	numDims;
    VTabStaticDims	staticDims;
    LegosType	type;
    word	typeData;

    Token*	identToken;
    word	varNum;

    /* nameId <- stable id of identifier; set current line #
     */
    ;{
	Node	nameNode;
	Token*	nameToken;

	nameNode = CurTree_GET_NTH(node, ARRAY_IDENT_NODE);
	EC_ERROR_IF(nameNode == NullNode, BE_FAILED_ASSERTION);
	nameToken = CurTree_LOCK(nameNode);
	task->ln = nameToken->lineNum;
	nameId = nameToken->data.key;
	HugeTreeUnlock(nameToken);
    }

    /* numDims <- # indices (0 if not an array)
     */
    ;{
	Node	numDimNode;
	Token*	numDimToken;

	numDimNode = CurTree_GET_NTH(node, ARRAY_NUM_DIMS_NODE);
	EC_ERROR_IF(numDimNode == NullNode, BE_FAILED_ASSERTION);
	numDimToken = CurTree_LOCK(numDimNode);
	numDims = numDimToken->data.integer;
	HugeTreeUnlock(numDimToken);
    }

    /* Arrays in structures must have constants for their dimensions.
     * Fill in staticDims
     */
    if (numDims != 0 && inStruct)
    {
	word	i;
	Token*	dimToken;

	staticDims.VTSD_num = numDims;
	for (i=0; i<numDims; i++) /* dims start from node 2 */
	{
	    dimToken = CurTree_LOCK(CurTree_GET_NTH(node, 
						    i+ARRAY_DIMS_START_NODE));
	    if (dimToken->code != CONST_INT)
	    {
		SetError(task, E_CONSTANT_NEEDED_HERE);
		HugeTreeUnlock(dimToken);
		return;
	    }
	    staticDims.VTSD_dim[i] = dimToken->data.integer;
	    HugeTreeUnlock(dimToken);
	}
    }

    /* type, typeData <- initialized from child <numDims>+2
     *			 and numDims
     */
    ;{
	Token*	typeToken;
	typeToken = CurTree_LOCK(CurTree_GET_NTH(node, 
					     numDims+ARRAY_DIMS_START_NODE));
	type = TokenToType(typeToken->code);
	if (numDims != 0) type |= TYPE_ARRAY_FLAG;
	typeData = typeToken->data.key;
	HugeTreeUnlock(typeToken);
    }

    varNum = Var_VTAdd(task, vtab, nameId, type, STD_SIZE, 0, typeData);
    if (ERROR_SET) return;

    if (inStruct) VTAppendDims(VTAB_HEAP, vtab, nameId, &staticDims);
    
    identToken = HugeTreeLock(task->vmHandle, task->tree, node);
    if (vtab == GLOBAL_VTAB)
    {
	identToken->data.key = MAKE_VAR_KEY(VAR_MODULE, varNum);
    }
    else
    {
	identToken->data.key = MAKE_VAR_KEY(VAR_LOCAL, varNum);
    }
    HugeTreeDirty(identToken);
    HugeTreeUnlock(identToken);
    return;
}

/*********************************************************************
 *			Var_AddExport
 *********************************************************************
 * SYNOPSIS:	Add to export table; shuffle entry in global vtab
 * CALLED BY:	INTERNAL
 * RETURN:	FALSE if unsuccessful
 * SIDE EFFECTS:
 * STRATEGY:
 *	Error if var is not already in vtab.
 *
 *	Adjust offsets of variables so exported variables come first,
 *	in order of their appearance in the export string table.
 *
 * BUGS:
 *	ExportTable actually has no reason to be a separate string
 *	table, except that it's easier to copy it over to an rtask
 *	from a ctask that way.  It actually makes more work for us
 *	here.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 5/23/95	Initial version
 * 
 *********************************************************************/
static Boolean
Var_AddExport(TaskPtr task, VarAnalyzeState* vas, word ident)
{
    TCHAR*	str;
    word	index,exportNum;

    if (!vas->global) {
	SetError(task, E_BAD_EXPORT);
	return FALSE;
    }

    if (!VTLookup(task->vtabHeap, GLOBAL_VTAB, ident, NULL, &index))
    {
	SetError(task, E_EXPECT_IDENT);
	return FALSE;
	/* AddExports now comes at the end of var analysis, instead of at
	 * the beginning.  All exported vars should be defined already.
	 *
	 index = Var_VTAdd(task, GLOBAL_VTAB, ident,
	 TYPE_NONE, STD_SIZE, VTF_FORWARD_REF, 0);
	 */
    }

    str = StringTableLock(ID_TABLE, ident);
    exportNum = StringTableAdd(EXPORT_TABLE, str);
    StringTableUnlock(str);
    VTMove(task->vtabHeap, GLOBAL_VTAB, index, 5*exportNum);

    return TRUE;
}

/*********************************************************************
 *			Var_VTAdd
 *********************************************************************
 * SYNOPSIS:	Front-end to VTAdd to deal correctly with struct IDs
 * CALLED BY:	INTERNAL
 * RETURN:	Same as VTAdd
 * SIDE EFFECTS:
 * STRATEGY:
 *	If adding a struct, convert typeData from index in ID table
 *	to index in STRUCT table.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/26/95	Initial version
 * 
 *********************************************************************/
static word
Var_VTAdd(TaskPtr task, word table, word nameId,
	  LegosType type, byte varSize, byte flags, word typeData)
{
#undef VTAdd
    TCHAR*	structName;
    word    	retval;

    if (type == TYPE_STRUCT
	|| (word)type == (TYPE_ARRAY_FLAG | TYPE_STRUCT))
    {
	/* convert from entry in ID_TABLE to entry in STRUCT_TABLE
	 * can't do this at parse time, as struct table entries would
	 * not exist then.
	 */
	structName = StringTableLock(ID_TABLE, typeData);
	typeData = StringTableLookupString(STRUCT_TABLE, structName);
	StringTableUnlock(structName);
	if (typeData == (word)NullElement)
	{
	    SetError(task, E_UNDEFINED_STRUCT);
	    return 0;
	}
    }
    
    retval = VTAdd(task->vtabHeap, table, nameId, type, varSize,
		    flags, typeData, task->funcNumber);
    if (retval == (word)VTAB_ERROR)
    {
	SetError(task, E_VARIABLE_ALREADY_DEFINED);
	return 0;
    }
    if (retval == (word)VTAB_RECOMPILE)
    {
	task->flags |= COMPILE_NEEDS_FULL_RECOMPILE;
	/* its not really an error, but we want VarAnayize to think
	 * there is an error so it exits
	 */
	SetError(task, E_VARIABLE_ALREADY_DEFINED);
	return 0;
    }
    return retval;
}
