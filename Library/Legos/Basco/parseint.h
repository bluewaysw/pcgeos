/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		parseint.h

AUTHOR:		Roy Goldman, Dec 19, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/19/94		Initial version.

DESCRIPTION:
	Internal parsing stuff

	$Id: parseint.h,v 1.1 98/10/13 21:43:20 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _PARSEINT_H_
#define _PARSEINT_H_

#include "btoken.h"
#include <Legos/opcode.h>
#include "bascoint.h"
#include "parse.h"
#include "scanner.h"
#include "ftab.h"

/* some useful macros */
#define HT_Lock(el) (Token *)HugeTreeLock(vmfile, tree, el)
#define HT_AllocNode(n) HugeTreeAllocNode(vmfile, tree, sizeof(Token), n)
#define HT_AllocTokenNode(c, ln, d, n) \
                    ParseAllocTokenNode(vmfile, tree, c, ln, d, n)

#define Parse_ALLOC_NODE(_code, _line, _data, _nChildren) \
 ParseAllocTokenNode(vmfile, tree, _code, _line, _data, _nChildren)

#define Parse_GET_PARENT(_node) HugeTreeGetParent(vmfile, tree, _node)

#define Parse_SET_NTH(_node, _position, _child) \
 HugeTreeSetNthChild(vmfile, tree, _node, _position, PREALLOC, _child)

#define Parse_GET_NTH(_node, _position) \
 HugeTreeGetNthChild(vmfile, tree, _node, _position)

#define Parse_APPEND_CHILD(_node, _child) \
 HugeTreeAppendChild(vmfile, tree, _node, PREALLOC, _child)

/* do while (0) is a safe way to consume a semicolon */
#define Parse_ERROR_IF(_test, _error, _label)	\
 do						\
 if ( _test ) { err = _error; goto _label; }	\
 while (0)

#define INIT_CHILDREN_FOR_FUNC 12
#define F_CHILD 12
#define INIT_CHILDREN_FOR_OP 2
#define INIT_CHILDREN_NONE 0

#define NO_EXTRA_SPACE 0
#define EXPR_SIZE sizeof(TokenData)

#define LEFT_CHILD 0
#define RIGHT_CHILD 1
#define BUF_SIZE 1024

#define BLOCK_OF_CODE_MAX_LINES 10


#define PREALLOC USE_PREALLOCATED_NODE


typedef enum
{
    EXPR_NORMAL,
    EXPR_TERMINATE,
    EXPR_DONT_CONSUME
} expr_type;


/* used for keeping track of whats going on with constants */
#define CONSTANT_CLEARED (-1)
#define CONSTANT_DELETED (-2)

typedef struct
{
    Token   token;
    sword    funcNumber;
} ConstantInfo;

extern FTabEntry *FunctionFind( TaskPtr task, TCHAR *buffer);


extern Boolean ParseIsValidType(TaskPtr task, Token *token);

extern Node
Parse_Type(TaskPtr, VMBlockHandle tree, ScannerState *state);

extern Node Parse_CompInit(TaskPtr	    	task,
			   VMBlockHandle	tree,
			   ScannerState	    	*state);

extern Node Parse_OnError(TaskPtr	    	task,
			  VMBlockHandle	tree,
			   ScannerState	    	*state);

extern Node Parse_If(TaskPtr	    	task,
		     VMBlockHandle	tree,
		     ScannerState    	*state);

extern Token
Parse_ConstantExpression(TaskPtr	task,
			 VMBlockHandle	tree,
			 ScannerState    	*state,
			 Token	    	*lastTok);

/* For this one, the only point of the return is to
   signal an error (returns NullNode).  

   The routine itself handles the linking into the
   tree, passed in as root
*/
extern Node Parse_Dim(TaskPtr	    	task,
		      VMBlockHandle	tree,
		      Node              root,
		      ScannerState    	*state,
		      TokenCode	    	code);
extern Node Parse_Redim(TaskPtr	    	task,
		      VMBlockHandle	tree,
		      Node              root,
		      ScannerState    	*state,
		      TokenCode	    	code);
extern Node Parse_For(TaskPtr	    	task,
		      VMBlockHandle	tree,
		      ScannerState    	*state);

extern Node Parse_Do(TaskPtr    	task,
		     VMBlockHandle	tree,
		     ScannerState    	*state);

extern Node Parse_Select(TaskPtr    	task,
			 VMBlockHandle	tree,
			 ScannerState    	*state);

/* header for routine to parse an entire function
   If an error, return number in task->ln 

   Fill in return type if known, return root of parse tree*/
extern VMBlockHandle Parse_Function(TaskPtr 	    task,
				    word            funcNum);
/* header for expression parser */
extern Node Parse_Expr(TaskPtr	    	task,
		       VMBlockHandle 	tree, 
		       ScannerState    	*state,
		       Boolean 	    	assignment,
		       Token*		lastToken,
		       int      	min_prec);

/* Utility used by Parse_Expr -- parses args to binary ops */
extern Node
Parse_Literal(TaskPtr 	    task, 
	      VMBlockHandle tree,
	      ScannerState  *state);

/* Utility used by Parse_Literal */
extern Node
Parse_ProcCall(TaskPtr task, VMBlockHandle tree,
	       ScannerState  *state,
	       Node root);

/* Finds stable id of built-in functions (case insensitive search) */
extern dword
Parse_FindBuiltIn(TaskPtr task, TCHAR* name);

/* main loop routine to go through a block of code */
extern Token Parse_BlockOfCode(TaskPtr     	task,
			       VMBlockHandle	tree,
			       Node 	    	root, 
			       ScannerState  *state);

extern Node Parse_Struct(TaskPtr	task,
			 VMBlockHandle	tree,
			 ScannerState  *state);

extern Node ParseAllocTokenNode(VMFileHandle	vmfile,
				VMBlockHandle	tree,
				TokenCode	code,
				word            lineNum,
				dword		data,
				word		numChildren);

extern void Parse_ConvertToLabel(TaskPtr task, Node node);
#endif /* _PARSEINT_H_ */
