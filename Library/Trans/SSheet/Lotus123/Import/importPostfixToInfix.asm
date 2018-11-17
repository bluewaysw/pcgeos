
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		exportPostfixToInfix.asm

AUTHOR:		Cheng, 10/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial revision

DESCRIPTION:
	Code that converts Lotus' postfix formulas into GeoCalc's infix
	formulas.

GOALS:
	Hopefully, stuff will be written in a generic enough manner that
	getting this code to work with formulas other than Lotus' will
	be easy.

TERMINOLOGY:

    EXPRESSION TREE:
	In the course of our translation, we will build an
	expression tree such that:

	* binary operators will have 2 expression trees as children

	* unary operators will have an expression tree as a child

	* operands will have no children

	* close paren will have an expression tree as a child

	* functions will have their arguments chained together as children

PROBLEMS:

	$Id: importPostfixToInfix.asm,v 1.1 97/04/07 11:41:43 newdeal Exp $


-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportFormulaLotusPostfixToCalcInfix

DESCRIPTION:	Translate a Lotus formula into GeoCalc parser tokens.  The
		task is complicated by the fact that Lotus stores formulas
		in postorder whereas GeoCalc stores stuff in infix.

CALLED BY:	INTERNAL ()

PASS:		ImportStackFrame
		ds:si - Lotus data stream
		es:di - GeoCalc output stream

RETURN:		ds:si - updated
		es:di - updated
		carry set if error
			ax - TransError

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

    FIRST SHOT AT ALGORITHM:
    ------------------------

    repeat
	t <- GetToken
	save di
	if (t in {range,cell,number,string}) then begin		; name=range
	    PushToken(t)			; save operand
	end else if (t = operator) then begin
	    if (t is unary) then		; t is unary
		PutToken(t)			; put operator
		PopToken(x)			; retrieve operand
		PutToken(x)			; put operand
	    else				; t is binary
		x <- GetStackItem(2)		; retrieve first operand
		PutToken(x)			; put first operand
		PutToken(t)			; put operator
		PopToken(x)			; retrieve 2nd operand
		PutToken(x)			; put 2nd operand
		DropToken(1)			; lose first operand
	end else if (t = function) then begin
	    n <- GetNumArgs
	    PutToken(t)				; put function
	    for (i = n downto 1) do begin
		x <- GetStackItem(i)
		PutToken(x)
		DropToken(n)			; lose n items
	    end
	end else if (t = parenthesis) then begin
	    ; parenthesize the last expression...
	    PutToken(right paren)
	    retrieve di
	    shift stuff down
	    PutToken(left paren)
	end
    until (t = return)

    won't work because of inability to resolve parentheses
    can I get by without building a tree?

    SECOND ATTEMPT:
    ---------------
    2 step process:

    BuildTree();
    TraverseTree();

    BuildTree(expr)
    ;
    ; encodes an expression tree in a node array
    ;
    begin
	repeat
	    GetToken(t);			; get token and create a node
	    if (t in {range,cell,number,string}) then begin
		PushNode(t);
	    end else if (t = UNARY_OPERATOR) then begin
		PopNode(x)			; get node
		AddChild(t,x)
		PushNode(t)
	    end else if (t = BINARY_OPERATOR) then begin
		PopNode(x)
		AddChild(t,x)
		PopNode(x)
		AddChild(t,x)
		PushNode(t)
	    end else if (t = CLOSE_PAREN) then begin
		PopNode(x)
		AddChild(t,x)
		PushNode(t)
	    end else if (t = FUNCTION) then begin
		a <- GetNumArgs()
		for x = 1 to a do begin
		    PopNode(y)
		    AddChild(t,y)
		endfor
	    end else if ((t = END_OF_FORMULA) then begin
		PopNode(x)
		x = root of expression tree
	    endif
	until (t = END_OF_FORMULA)
    end

    TraverseTree(node)
    begin
	t <- GetToken(node);
	if (t = CLOSE_PAREN) then begin
	    TranslateNode(OPEN_PAREN);
	    TraverseTree(Child(node));
	    TranslateNode(t);
	end else if (t = UNARY_OPERATOR) then begin
	    TranslateNode(t);
	    TraverseTree(Child(node));
	end else if (t = BINARY_OPERATOR) then begin
	    TraverseTree(Child1(node));
	    TranslateNode(t);
	    TraverseTree(Child2(node);
	end else if (t = operand) then begin
	    TranslateNode(t);
	end else if (t = FUNCTION) then begin
	    TranslateNode(t);
	    n <- num children
	    for x = 1 to n do
		TraverseTree(ChildX(node))
	    endfor
	end else if (t = END_OF_EXPR) then begin
	    TraverseTree(Child(node));
	    TranslateNode(t);
	endif
    end; {Translate}


    TERMINOLOGY:
    ------------

    EXPRESSION TREE:
	Orgainized such that each node has a child pointer and a sibling
	pointer.  Multiple siblings form a chain.  This is necessary because
	functions can have multiple arguments.

    NODE STRUCTURE:
	Contains info about the node's token, its child and its sibling.

Frame nodes:

    FRAME NODE:
	A temporary node contained in the stack frame.  We will have 2 frame
	nodes.  By giving an frame node offset, we can operate on either node.

    FRAME NODE OFFSET:
	An offset into the stack frame to a frame node.

Node array:

    NODE ARRAY:
	An array of node structures.  This array will encode the expression
	tree.  Pointers to other nodes will actually be offsets into this
	array.

    NODE ARRAY OFFSET:
	An offset into the node array to a node structure (possibly 0).

    NODE ARRAY FREE POINTER:
	Pointer to the next available location in the node array.

Node stack:

    NODE STACK:
	Stack used for node offsets.

    NODE STACK POINTER:
	Pointer to the top of the node stack.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportFormulaLotusPostfixToCalcInfix	proc	near	uses	bx
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	call	ImportFormulaInit		; destroys ax
	jc	exit				; out of memory

	call	ImportFormulaBuildTree
	jc	exit

	push	ds,si
	mov	ds, locals.ISF_nodeArraySeg
	mov	si, locals.ISF_nodeArrayRoot	; ds:bx <- root of expr tree
	call	ImportFormulaTraverseTree
	pop	ds,si

	call	ImportFormulaExit
	clc

exit:
	.leave
	ret
ImportFormulaLotusPostfixToCalcInfix	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportFormulaBuildTree

DESCRIPTION:	

CALLED BY:	INTERNAL (ImportFormulaLotusPostfixToCalcInfix)

PASS:		ImportStackFrame
		ds:si - Lotus data stream

RETURN:		ds:si - updated
		CF set on error
			ax	= TransError

DESTROYED:	ax

REGISTER/STACK USAGE:
	es:di - current node in the node array

PSEUDO CODE/STRATEGY:
    BuildTree(expr)
    ;
    ; encodes an expression tree in a node array
    ;
    begin
	repeat
	    GetToken(t);			; get token and create a node
	    if (t in {range,cell,number,string}) then begin
		PushNode(t);
	    end else if (t = UNARY_OPERATOR) then begin
		PopNode(x)			; get node
		AddChild(t,x)
		PushNode(t)
	    end else if (t = BINARY_OPERATOR) then begin
		PopNode(x)
		AddChild(t,x)
		PopNode(x)
		AddChild(t,x)
		PushNode(t)
	    end else if (t = CLOSE_PAREN) then begin
		PopNode(x)
		AddChild(t,x)
		PushNode(t)
	    end else if (t = FUNCTION) then begin
		a <- GetNumArgs()
		for x = 1 to a do begin
		    PopNode(y)
		    AddChild(t,y)
		endfor
	    end else if ((t = END_OF_FORMULA) then begin
		PopNode(x)
		x = root of expression tree
	    endif
	until (t = END_OF_FORMULA)
    end

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportBuildTreeRoutineLookup	nptr \
	offset ImportBuildTreeProcessOperand,
	offset ImportBuildTreeProcessUnaryOp,
	offset ImportBuildTreeProcessBinaryOp,
	offset ImportBuildTreeProcessParentheses,
	offset ImportBuildTreeProcessFunction,
	offset ImportBuildTreeProcessEndOfExpr

if PZ_PCGEOS
BuildTreeClassificationLookup	byte \
	IMPORT_OPERAND,		; LOTUS_FUNCTION_CONSTANT	0h
	IMPORT_OPERAND,		; LOTUS_FUNCTION_VARIABLE	1h
	IMPORT_OPERAND,		; LOTUS_FUNCTION_RANGE		2h
	IMPORT_END_OF_EXPR,	; LOTUS_FUNCTION_RETURN		3h
	IMPORT_PARENTHESES,	; LOTUS_FUNCTION_PARENTHESES	4h
	IMPORT_OPERAND,		; LOTUS_FUNCTION_2BYTE_INT	5h
	IMPORT_OPERAND,		; LOTUS_FUNCTION_STR_CONST	6h
	-1,			;				7h
	IMPORT_UNARY_OP,	; LOTUS_FUNCTION_UMINUS		8h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_PLUS		9h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_SUB		0ah
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_MULTIPLY	0bh
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_DIVIDE		0ch
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_EXPONENT	0dh
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_EQUAL		0eh
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_NOT_EQUAL	0fh
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_LT_OR_EQUAL	10h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_GT_OR_EQUAL	11h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_LT		12h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_GT		13h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_AND		14h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_OR		15h
	IMPORT_UNARY_OP,	; LOTUS_FUNCTION_NOT		16h
;1994-08-29(Mon)TOK ----------------
	IMPORT_UNARY_OP,		; LOTUS_FUNCTION_UPLUS		17h
	IMPORT_BINARY_OP	;'&'(Concatenation)
;----------------
else
BuildTreeClassificationLookup	byte \
	IMPORT_OPERAND,		; LOTUS_FUNCTION_CONSTANT	0h
	IMPORT_OPERAND,		; LOTUS_FUNCTION_VARIABLE	1h
	IMPORT_OPERAND,		; LOTUS_FUNCTION_RANGE		2h
	IMPORT_END_OF_EXPR,	; LOTUS_FUNCTION_RETURN		3h
	IMPORT_PARENTHESES,	; LOTUS_FUNCTION_PARENTHESES	4h
	IMPORT_OPERAND,		; LOTUS_FUNCTION_2BYTE_INT	5h
	IMPORT_OPERAND,		; LOTUS_FUNCTION_STR_CONST	6h
	-1,			;				7h
	IMPORT_UNARY_OP,	; LOTUS_FUNCTION_UMINUS		8h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_PLUS		9h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_SUB		0ah
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_MULTIPLY	0bh
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_DIVIDE		0ch
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_EXPONENT	0dh
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_EQUAL		0eh
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_NOT_EQUAL	0fh
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_LT_OR_EQUAL	10h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_GT_OR_EQUAL	11h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_LT		12h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_GT		13h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_AND		14h
	IMPORT_BINARY_OP,	; LOTUS_FUNCTION_OR		15h
	IMPORT_UNARY_OP,	; LOTUS_FUNCTION_NOT		16h
	IMPORT_UNARY_OP		; LOTUS_FUNCTION_UPLUS		17h
endif


if 0	;** OUT ****************************************************************
  ;
  ; we will perform checks instead of doing lookup for these
  ;
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_NA		1fh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ERR		20h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ABS		21h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_INT		22h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_SQRT		23h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_LOG		24h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_LN		25h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_PI		26h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_SIN		27h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_COS		28h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_TAN		29h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ATAN2		2ah
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ATAN		2bh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ASIN		2ch
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ACOS		2dh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_EXP		2eh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_MOD		2fh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_CHOOSE		30h, 
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ISNA		31h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ISERR		32h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_FALSE		33h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_TRUE		34h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_RAND		35h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DATE		36h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_TODAY		37h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_PMT		38h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_PV		39h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_FV		3ah
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_IF		3bh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DAY		3ch
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_MONTH		3dh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_YEAR		3eh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ROUND		3fh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_TIME		40h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_HOUR		41h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_MINUTE		42h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_SECOND		43h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ISNUMBER	44h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ISSTRING	45h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_LENGTH		46h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_VALUE		47h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_FIXED		48h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_MID		49h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_CHR		4ah
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ASCII		4bh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_FIND		4ch
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DATEVALUE	4dh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_TIMEVALUE	4eh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_CELLPOINTER	4fh
    ;
    ; multiple argument opcodes follow
    ;
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_SUM		50h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_AVG		51h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_CNT		52h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_MIN		53h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_MAX		54h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_VLOOKUP	55h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_NPV		56h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_VAR		57h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_STD		58h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_IRR		59h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_HLOOKUP	5ah
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DSUM		5bh	; dbase
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DAVG		5ch	; dbase
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DCNT		5dh	; dbase
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DMIN		5eh	; dbase
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DMAX		5fh	; dbase
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DVAR		60h	; dbase
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DSTD		61h	; dbase
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_INDEX		62h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_COLS		63h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_ROWS		64h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_REPEAT		65h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_UPPER		66h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_LOWER		67h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_LEFT		68h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_RIGHT		69h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_REPLACE	6ah
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_PROPER		6bh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_CELL		6ch
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_TRIM		6dh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_CLEAN		6eh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_S		6fh
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_V		70h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_REQ		71h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_CALL		72h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_APP		73h Symphony 1.0
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_RATE		74h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_TERM		75h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_CTERM		76h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_SLN		77h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_SOY		78h
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_DDB		79h

  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_AAF_START	9ch
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_AAF_UNKNOWN	0ceh 123/2
  byte	IMPORT_FUNCTION		; LOTUS_FUNCTION_AAF_END	0ffh 123/2
endif	;***********************************************************************

LOTUS_MULT_ARG_FUNCTION = -128
LOTUS_SPECIAL_FUNCTION = -127

  ;
  ; (value >= 0) => number of arguments
  ; (value == LOTUS_MULT_ARG_FUNCTION) => variable number of arguments
  ; (-value (other than LOTUS_MULT_ARG_FUNCTION)) => function is not supported
  ;     but value is the number of args the function takes
  ;

if PZ_PCGEOS
BuildTreeFixedArgFunctionNumArgsLookupTable	byte \
	0,			; LOTUS_FUNCTION_NA		1fh
	0,			; LOTUS_FUNCTION_ERR		20h
	1,			; LOTUS_FUNCTION_ABS		21h
	1,			; LOTUS_FUNCTION_INT		22h
	1,			; LOTUS_FUNCTION_SQRT		23h
	1,			; LOTUS_FUNCTION_LOG		24h
	1,			; LOTUS_FUNCTION_LN		25h
	0,			; LOTUS_FUNCTION_PI		26h
	1,			; LOTUS_FUNCTION_SIN		27h
	1,			; LOTUS_FUNCTION_COS		28h
	1,			; LOTUS_FUNCTION_TAN		29h
	2,			; LOTUS_FUNCTION_ATAN2		2ah
	1,			; LOTUS_FUNCTION_ATAN		2bh
	1,			; LOTUS_FUNCTION_ASIN		2ch
	1,			; LOTUS_FUNCTION_ACOS		2dh
	1,			; LOTUS_FUNCTION_EXP		2eh
	2,			; LOTUS_FUNCTION_MOD		2fh
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_CHOOSE		30h
	1,			; LOTUS_FUNCTION_ISNA		31h
	1,			; LOTUS_FUNCTION_ISERR		32h
	0,			; LOTUS_FUNCTION_FALSE		33h
	0,			; LOTUS_FUNCTION_TRUE		34h
	0,			; LOTUS_FUNCTION_RAND		35h
	3,			; LOTUS_FUNCTION_DATE		36h
	0,			; LOTUS_FUNCTION_TODAY		37h
	3,			; LOTUS_FUNCTION_PMT		38h
	3,			; LOTUS_FUNCTION_PV		39h
	3,			; LOTUS_FUNCTION_FV		3ah
	3,			; LOTUS_FUNCTION_IF		3bh
	1,			; LOTUS_FUNCTION_DAY		3ch
	1,			; LOTUS_FUNCTION_MONTH		3dh
	1,			; LOTUS_FUNCTION_YEAR		3eh
	2,			; LOTUS_FUNCTION_ROUND		3fh
	3,			; LOTUS_FUNCTION_TIME		40h
	1,			; LOTUS_FUNCTION_HOUR		41h
	1,			; LOTUS_FUNCTION_MINUTE		42h
	1,			; LOTUS_FUNCTION_SECOND		43h
	1,			; LOTUS_FUNCTION_ISNUMBER	44h
	1,			; LOTUS_FUNCTION_ISSTRING	45h
	1,			; LOTUS_FUNCTION_LENGTH		46h
	1,			; LOTUS_FUNCTION_VALUE		47h
	2,			; LOTUS_FUNCTION_STRING		48h
	3,			; LOTUS_FUNCTION_MID		49h
	1,			; LOTUS_FUNCTION_CHR		4ah
	1,			; LOTUS_FUNCTION_ASCII		4bh
	3,			; LOTUS_FUNCTION_FIND		4ch
	1,			; LOTUS_FUNCTION_DATEVALUE	4dh
	1,			; LOTUS_FUNCTION_TIMEVALUE	4eh
	1,			; LOTUS_FUNCTION_CELLPOINTER	4fh
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_SUM		50h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_AVG		51h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_CNT		52h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_MIN		53h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_MAX		54h
	3,			; LOTUS_FUNCTION_VLOOKUP	55h
	2,			; LOTUS_FUNCTION_NPV		56h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_VAR		57h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_STD		58h
	2,			; LOTUS_FUNCTION_IRR		59h
	3,			; LOTUS_FUNCTION_HLOOKUP	5ah
	3,			; LOTUS_FUNCTION_DSUM		5bh	; dbase
	3,			; LOTUS_FUNCTION_DAVG		5ch	; dbase
	3,			; LOTUS_FUNCTION_DCNT		5dh	; dbase
	3,			; LOTUS_FUNCTION_DMIN		5eh	; dbase
	3,			; LOTUS_FUNCTION_DMAX		5fh	; dbase
	3,			; LOTUS_FUNCTION_DVAR		60h	; dbase
	3,			; LOTUS_FUNCTION_DSTD		61h	; dbase
	3,			; LOTUS_FUNCTION_INDEX		62h
	1,			; LOTUS_FUNCTION_COLS		63h
	1,			; LOTUS_FUNCTION_ROWS		64h
	2,			; LOTUS_FUNCTION_REPEAT		65h
	1,			; LOTUS_FUNCTION_UPPER		66h
	1,			; LOTUS_FUNCTION_LOWER		67h
	2,			; LOTUS_FUNCTION_LEFT		68h
	2,			; LOTUS_FUNCTION_RIGHT		69h
	4,			; LOTUS_FUNCTION_REPLACE	6ah
	1,			; LOTUS_FUNCTION_PROPER		6bh
	2,			; LOTUS_FUNCTION_CELL		6ch
	1,			; LOTUS_FUNCTION_TRIM		6dh
	1,			; LOTUS_FUNCTION_CLEAN		6eh
	1,			; LOTUS_FUNCTION_S		6fh
	1,			; LOTUS_FUNCTION_N		70h
	2, 			; LOTUS_FUNCTION_EXACT		71h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_CALL		72h
	1,			; LOTUS_FUNCTION_APP		73h Sym 1.0
	3,			; LOTUS_FUNCTION_RATE		74h
	3,			; LOTUS_FUNCTION_TERM		75h
	3,			; LOTUS_FUNCTION_CTERM		76h
	3,			; LOTUS_FUNCTION_SLN		77h
	4,			; LOTUS_FUNCTION_SOY		78h
	4,			; LOTUS_FUNCTION_DDB		79h
;1994-08-04(Thu)TOK ----------------
	-1,	;7ah = @FULLP is Japanese only.
	-1,	;7bh = @HALFP is Japanese only.
	-1,	;dummy
	-2,	;7dh = @SUUJI is Japanese only.
	-1,	;7eh = @NENGO is Japanese only.
	-1,	;7fh = @DECIMAL is Japanese only.
	-1,	;80h = @HEX is Japanese only.
	4,	;81h = @DB is Japanese only.
	-2,	;82h = @RANK is Japanese only.
	-1,	;83h = @PUREAVG is Japanese only.
	-1,	;84h = @PURECOUNT is Japanese only.
	-1,	;85h = @PUREMAX is Japanese only.
	-1,	;86h = @PUREMIN is Japanese only.
	-1,	;87h = @PURESTD is Japanese only.
	-1,	;88h = @PUREVAR is Japanese only.
	-3,	;89h = @DATEDIF is Japanese only.
	-1,	;8ah = @AYOUBI is Japanese only.
	-4,	;8bh = @GANRI is Japanese only.
	-4,	;8ch = @GANKIN is Japanese only.
	LOTUS_SPECIAL_FUNCTION,	; LOTUS_FUNCTION_AAF_START	9ch
	LOTUS_SPECIAL_FUNCTION,	; LOTUS_FUNCTION_AAF_UNKNOWN	0ceh 123/2
	LOTUS_SPECIAL_FUNCTION	; LOTUS_FUNCTION_AAF_END	0ffh 123/2

else
BuildTreeFixedArgFunctionNumArgsLookupTable	byte \
	0,			; LOTUS_FUNCTION_NA		1fh
	0,			; LOTUS_FUNCTION_ERR		20h
	1,			; LOTUS_FUNCTION_ABS		21h
	1,			; LOTUS_FUNCTION_INT		22h
	1,			; LOTUS_FUNCTION_SQRT		23h
	1,			; LOTUS_FUNCTION_LOG		24h
	1,			; LOTUS_FUNCTION_LN		25h
	0,			; LOTUS_FUNCTION_PI		26h
	1,			; LOTUS_FUNCTION_SIN		27h
	1,			; LOTUS_FUNCTION_COS		28h
	1,			; LOTUS_FUNCTION_TAN		29h
	2,			; LOTUS_FUNCTION_ATAN2		2ah
	1,			; LOTUS_FUNCTION_ATAN		2bh
	1,			; LOTUS_FUNCTION_ASIN		2ch
	1,			; LOTUS_FUNCTION_ACOS		2dh
	1,			; LOTUS_FUNCTION_EXP		2eh
	2,			; LOTUS_FUNCTION_MOD		2fh
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_CHOOSE		30h
	1,			; LOTUS_FUNCTION_ISNA		31h
	1,			; LOTUS_FUNCTION_ISERR		32h
	0,			; LOTUS_FUNCTION_FALSE		33h
	0,			; LOTUS_FUNCTION_TRUE		34h
	0,			; LOTUS_FUNCTION_RAND		35h
	3,			; LOTUS_FUNCTION_DATE		36h
	0,			; LOTUS_FUNCTION_TODAY		37h
	3,			; LOTUS_FUNCTION_PMT		38h
	3,			; LOTUS_FUNCTION_PV		39h
	3,			; LOTUS_FUNCTION_FV		3ah
	3,			; LOTUS_FUNCTION_IF		3bh
	1,			; LOTUS_FUNCTION_DAY		3ch
	1,			; LOTUS_FUNCTION_MONTH		3dh
	1,			; LOTUS_FUNCTION_YEAR		3eh
	2,			; LOTUS_FUNCTION_ROUND		3fh
	3,			; LOTUS_FUNCTION_TIME		40h
	1,			; LOTUS_FUNCTION_HOUR		41h
	1,			; LOTUS_FUNCTION_MINUTE		42h
	1,			; LOTUS_FUNCTION_SECOND		43h
	1,			; LOTUS_FUNCTION_ISNUMBER	44h
	1,			; LOTUS_FUNCTION_ISSTRING	45h
	1,			; LOTUS_FUNCTION_LENGTH		46h
	1,			; LOTUS_FUNCTION_VALUE		47h
	2,			; LOTUS_FUNCTION_STRING		48h
	3,			; LOTUS_FUNCTION_MID		49h
	1,			; LOTUS_FUNCTION_CHR		4ah
	1,			; LOTUS_FUNCTION_ASCII		4bh
	3,			; LOTUS_FUNCTION_FIND		4ch
	1,			; LOTUS_FUNCTION_DATEVALUE	4dh
	1,			; LOTUS_FUNCTION_TIMEVALUE	4eh
	1,			; LOTUS_FUNCTION_CELLPOINTER	4fh
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_SUM		50h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_AVG		51h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_CNT		52h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_MIN		53h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_MAX		54h
	3,			; LOTUS_FUNCTION_VLOOKUP	55h
	2,			; LOTUS_FUNCTION_NPV		56h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_VAR		57h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_STD		58h
	2,			; LOTUS_FUNCTION_IRR		59h
	3,			; LOTUS_FUNCTION_HLOOKUP	5ah
	3,			; LOTUS_FUNCTION_DSUM		5bh	; dbase
	3,			; LOTUS_FUNCTION_DAVG		5ch	; dbase
	3,			; LOTUS_FUNCTION_DCNT		5dh	; dbase
	3,			; LOTUS_FUNCTION_DMIN		5eh	; dbase
	3,			; LOTUS_FUNCTION_DMAX		5fh	; dbase
	3,			; LOTUS_FUNCTION_DVAR		60h	; dbase
	3,			; LOTUS_FUNCTION_DSTD		61h	; dbase
	3,			; LOTUS_FUNCTION_INDEX		62h
	1,			; LOTUS_FUNCTION_COLS		63h
	1,			; LOTUS_FUNCTION_ROWS		64h
	2,			; LOTUS_FUNCTION_REPEAT		65h
	1,			; LOTUS_FUNCTION_UPPER		66h
	1,			; LOTUS_FUNCTION_LOWER		67h
	2,			; LOTUS_FUNCTION_LEFT		68h
	2,			; LOTUS_FUNCTION_RIGHT		69h
	4,			; LOTUS_FUNCTION_REPLACE	6ah
	1,			; LOTUS_FUNCTION_PROPER		6bh
	2,			; LOTUS_FUNCTION_CELL		6ch
	1,			; LOTUS_FUNCTION_TRIM		6dh
	1,			; LOTUS_FUNCTION_CLEAN		6eh
	1,			; LOTUS_FUNCTION_S		6fh
	1,			; LOTUS_FUNCTION_N		70h
	2, 			; LOTUS_FUNCTION_EXACT		71h
	LOTUS_MULT_ARG_FUNCTION,; LOTUS_FUNCTION_CALL		72h
	1,			; LOTUS_FUNCTION_APP		73h Sym 1.0
	3,			; LOTUS_FUNCTION_RATE		74h
	3,			; LOTUS_FUNCTION_TERM		75h
	3,			; LOTUS_FUNCTION_CTERM		76h
	3,			; LOTUS_FUNCTION_SLN		77h
	4,			; LOTUS_FUNCTION_SOY		78h
	4,			; LOTUS_FUNCTION_DDB		79h
	LOTUS_SPECIAL_FUNCTION,	; LOTUS_FUNCTION_AAF_START	9ch
	LOTUS_SPECIAL_FUNCTION,	; LOTUS_FUNCTION_AAF_UNKNOWN	0ceh 123/2
	LOTUS_SPECIAL_FUNCTION	; LOTUS_FUNCTION_AAF_END	0ffh 123/2
endif

if DBCS_PCGEOS	;1994-08-29(Mon)TOK ----------------
IMPORT_END_OPERATORS_AND_OPERANDS = 18h	;18h = '&'(Concatenation)
else	;----------------
IMPORT_END_OPERATORS_AND_OPERANDS	= LOTUS_FUNCTION_UPLUS
endif	;----------------
IMPORT_START_FUNCTIONS			= LOTUS_FUNCTION_NA
IMPORT_END_FUNCTIONS			= LOTUS_FUNCTION_DDB
IMPORT_MISC_FUNC1			= LOTUS_FUNCTION_AAF_START
IMPORT_MISC_FUNC2			= LOTUS_FUNCTION_AAF_UNKNOWN
IMPORT_MISC_FUNC3			= LOTUS_FUNCTION_AAF_END

ImportFormulaBuildTree	proc	near	uses	bx,es,di
	locals	local	ImportStackFrame
	.enter	inherit near

	mov	es, locals.ISF_nodeArraySeg

processLoop:
	call	ImportFormulaGetToken	; al <- token type, bx <- offset
	jc	done			; return CF set on error

	cmp	al, IMPORT_FUNCTION
	jne	doNonFunction

	;-----------------------------------------------------------------------
	; functions

	mov	al, es:[bx].IFN_token
if DBCS_PCGEOS	;1994-08-04(Thu)TOK ----------------
	cmp	al, 7ch
	je	NextCheck
	cmp	al, 8dh
	jae	NextCheck
	jmp	short DoneCheck	;@function is assigned in Japanese 1-2-3.
NextCheck:
endif	;----------------
	cmp	al, IMPORT_END_FUNCTIONS
	jg	processSpecialFunction
if DBCS_PCGEOS	;1994-08-04(Thu)TOK ----------------
DoneCheck:
endif	;----------------

	;
	; get number of args the function takes
	;
	clr	ah
	mov	di, ax
	sub	di, LOTUS_FUNCTION_NA		; di <- offset into table
	mov	al, cs:[BuildTreeFixedArgFunctionNumArgsLookupTable][di]

	cmp	al, LOTUS_MULT_ARG_FUNCTION
	je	processMultArgFunction
;	cmp	al, LOTUS_SPECIAL_FUNCTION
;	je	processSpecialFunction

	tst	al
	jns	processFunction

;processUnsupportedFunction:
	; pop args off node stack
	; substitute function with error function
	neg	al				; al <- num args
	call	ImportBuildTreeIgnoreFunction
	jmp	short processLoop

processSpecialFunction:
	; fatal error for now
EC<	ERROR	IMPEX_ASSERTION_FAILED >
;	jmp	short processLoop

processMultArgFunction:
	lodsb					; al <- num args

processFunction:
	call	ImportBuildTreeProcessFunction
	jmp	short processLoop

	;-----------------------------------------------------------------------
	; non-functions

doNonFunction:
	;
	; retrieve routine offset from lookup table
	;
	clr	ah
	mov	di, ax
	shl	di, 1				; di <- offset into table
	mov	di, cs:[ImportBuildTreeRoutineLookup][di]
	call	di				; pass bx = node array offset

	cmp	es:[bx].IFN_token, LOTUS_FUNCTION_RETURN	; end?
	jne	processLoop			; loop if not

	;
	; make sure that nothing is left on the node stack
	;
EC<	cmp	locals.ISF_nodeStackTopOff, 0 >
EC<	ERROR_NE IMPEX_NODE_STACK_NOT_EMPTY >

	;
	; NOTE: carry *IS* already clear at this point in both EC and non-EC
	;

done:
	; return carry flag
	.leave
	ret
ImportFormulaBuildTree	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportBuildTreeProcess...

DESCRIPTION:	Add to the structure of the tree by processing the current token
		and making the necessary child and sibling links.

CALLED BY:	INTERNAL (ImportFormulaBuildTree)

PASS:		ImportStackFrame
		bx - node array offset of current token

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportBuildTreeProcessOperand	proc	near
	locals	local	ImportStackFrame
	ForceRef locals
	.enter inherit near

	call	ImportFormulaPushNode		; pass bx=node array offset

	.leave
	ret
ImportBuildTreeProcessOperand	endp


ImportBuildTreeProcessUnaryOp	proc	near	uses	di
	locals	local	ImportStackFrame
	ForceRef locals
	.enter inherit near

	call	ImportFormulaPopNode		; di <- node array offset
	call	ImportFormulaAddChild		; pass bx=parent, di=child
if DBCS_PCGEOS	;1994-08-31(Wed)TOK ----------------
	cmp	es:[bx].IFN_token, LOTUS_FUNCTION_NOT
	jne	NotNOT
	mov	es:[bx].IFN_token, LOTUS_FUNCTION_ERR
	mov	es:[bx].IFN_tokenType, IMPORT_FUNCTION
NotNOT:
endif	;----------------
	call	ImportFormulaPushNode		; pass bx=node array offset

	.leave
	ret
ImportBuildTreeProcessUnaryOp	endp


ImportBuildTreeProcessBinaryOp	proc	near	uses	di
	locals	local	ImportStackFrame
	ForceRef locals
	.enter inherit near

	call	ImportFormulaPopNode		; di <- node array offset
	call	ImportFormulaAddChild		; pass bx=parent, di=child
	call	ImportFormulaPopNode		; di <- node array offset
	call	ImportFormulaAddChild		; pass bx=parent, di=child
	call	ImportFormulaPushNode		; pass bx=node array offset

	.leave
	ret
ImportBuildTreeProcessBinaryOp	endp


ImportBuildTreeProcessParentheses	proc	near
	locals	local	ImportStackFrame
	ForceRef locals
	.enter inherit near

	call	ImportFormulaPopNode		; di <- node array offset
	call	ImportFormulaAddChild		; pass bx=parent, di=child
	call	ImportFormulaPushNode		; pass bx=node array offset

	.leave
	ret
ImportBuildTreeProcessParentheses	endp


ImportBuildTreeProcessEndOfExpr	proc	near
	locals	local	ImportStackFrame
	.enter inherit near

	call	ImportFormulaPopNode		; di <- node array offset
	call	ImportFormulaAddChild		; pass bx=parent, di=child
	mov	locals.ISF_nodeArrayRoot, di	; store root

	.leave
	ret
ImportBuildTreeProcessEndOfExpr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportBuildTreeProcessFunction

DESCRIPTION:	Add to the structure of the tree by processing the current
		function and making the necessary child and sibling links.

CALLED BY:	INTERNAL (ImportFormulaBuildTree)

PASS:		ImportStackFrame
		al - number of arguments
		ds:si - Lotus data stream
		bx - node array offset of function token

RETURN:		nothing

DESTROYED:	ax,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportBuildTreeProcessFunction	proc	near
	locals	local	ImportStackFrame
	ForceRef locals
	.enter inherit near

	call	ImportBuildTreeProcessFunctionAddChildren
	call	ImportFormulaPushNode		; pass bx=node array offset

	.leave
	ret
ImportBuildTreeProcessFunction	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportBuildTreeIgnoreFunction

DESCRIPTION:	The current function is not supported.  Add to the structure of
		the tree by processing the current function and making the
		necessary child and sibling links but substitute ERR for the
		function.

CALLED BY:	INTERNAL (ImportFormulaBuildTree)

PASS:		ImportStackFrame
		al - number of arguments
		ds:si - Lotus data stream
		bx - node array offset of function token

RETURN:		nothing

DESTROYED:	ax,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportBuildTreeIgnoreFunction	proc	near	uses	ch
	locals	local	ImportStackFrame
	ForceRef locals
	.enter inherit near

	call	ImportBuildTreeProcessFunctionAddChildren

	;
	; Alternatively, I could have copied much of function
	; ImportBuildTreeProcessFunctionAddChildren and not have built
	; the child and sibling links but using the function seems to allow
	; more possibilities for now...
	; This probably should be changed as an optimization.
	;

	mov	es:[bx].IFN_token, LOTUS_FUNCTION_ERR
;	mov	es:[bx].IFN_numChildren, 0
;	mov	es:[bx].IFN_childOffset, NULL_PTR
;	mov	es:[bx].IFN_siblingOffset, NULL_PTR
	call	ImportFormulaPushNode		; pass bx=node array offset

	.leave
	ret
ImportBuildTreeIgnoreFunction	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportBuildTreeProcessFunctionAddChildren

DESCRIPTION:	Add to the structure of the tree by processing the current
		function and making the necessary child and sibling links.

CALLED BY:	INTERNAL (ImportBuildTreeProcessFunction,
		ImportBuildTreeIgnoreFunction)

PASS:		ImportStackFrame
		al - number of arguments
		ds:si - Lotus data stream
		bx - node array offset of function token

RETURN:		nothing

DESTROYED:	ax,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportBuildTreeProcessFunctionAddChildren	proc	near	uses	cx
	locals	local	ImportStackFrame
	ForceRef locals
	.enter inherit near

	;
	; a == num args
	; for x = 1 to a do begin
	;    PopNode()
	;    AddChild()
	; endfor
	; note top of stack
	;

	tst	al
	je	done

	mov	cl, al
	clr	ch				; cx <- num args

popLoop:
	call	ImportFormulaPopNode		; di <- node array offset
	call	ImportFormulaAddChild		; pass bx=parent, di=child
	loop	popLoop

done:
	.leave
	ret
ImportBuildTreeProcessFunctionAddChildren	endp


;*******************************************************************************
;
;	SUPPORT ROUTINES
;
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportFormulaInit

DESCRIPTION:	Allocate the mem blocks that will be used as the node array
		and the node stack.

CALLED BY:	INTERNAL (ImportFormulaLotusPostfixToCalcInfix)

PASS:		ImportStackFrame
		ds:si - Lotus data stream
		es:di - GeoCalc output stream

RETURN:		carry set if error
			ax - TransError

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportFormulaInit	proc	near	uses	bx,cx
	locals	local	ImportStackFrame
	.enter	inherit near

	;
	; save addresses
	;
	mov	locals.ISF_lotusDataStream.offset, si
	mov	locals.ISF_lotusDataStream.segment, ds
	mov	locals.ISF_geocalcOutputStream.offset, di
	mov	locals.ISF_geocalcOutputStream.segment, es

	;
	; allocate space
	;
	mov	ax, size ImportFormulaNode * IMPORT_FORMULA_MAX_NODES
	mov	cx, (mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8 or \
		     mask HF_SWAPABLE			
	call	MemAlloc
	jc	error

	mov	locals.ISF_nodeArrayHan, bx
	clr	locals.ISF_nodeArrayFreeOff
	mov	locals.ISF_nodeArraySeg, ax

	mov	ax, IMPORT_FORMULA_MAX_TOKENS * 2	; we're using words
	mov	cx, (mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8 or \
		     mask HF_SWAPABLE			
	call	MemAlloc
	jc	error

	mov	locals.ISF_nodeStackHan, bx
	clr	locals.ISF_nodeStackTopOff
	mov	locals.ISF_nodeStackSeg, ax

done:
	.leave
	ret

error:
	mov	ax, TE_OUT_OF_MEMORY
	jmp	done
	
ImportFormulaInit	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportFormulaExit

DESCRIPTION:	Clean up.

CALLED BY:	INTERNAL (ImportFormulaLotusPostfixToCalcInfix)

PASS:		ImportStackFrame

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportFormulaExit	proc	near	uses	bx
	locals	local	ImportStackFrame
	.enter	inherit near

	mov	bx, locals.ISF_nodeStackHan
	call	MemFree
	mov	bx, locals.ISF_nodeArrayHan
	call	MemFree

	.leave
	ret
ImportFormulaExit	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportFormulaGetToken

DESCRIPTION:	Retrieves a token from the Lotus data stream and create a
		node for it.  This node will then be added to the token
		stack array.

CALLED BY:	INTERNAL (ImportFormulaBuildTree)

PASS:		ds:si - Lotus data stream

RETURN:		ds:si - updated to point to next token
		al - token type (ImportFunctionTokenType)
		bx - node array offset
		CF set if error
			ax = TransError

DESTROYED:	ah

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

if PZ_PCGEOS
ImportLotusTokenDataSizeLookup	byte \
	8,			; constant		0
	4,			; variable
	8,			; range
	0,			; return
	0,			; parentheses
	2,			; 2 byte int		5
	-2,			; string constant
	-1,			; illegal
	0,			; unary minus
	0,			; plus
	0,			; minus			10
	0,			; multiplication
	0,			; division
	0,			; exponentiation
	0,			; =
	0,			; <>			15
	0,			; <=
	0,			; >=
	0,			; <
	0,			; >
	0,			; AND			20
	0,			; OR
	0,			; NOT
;1994-08-29(Mon)TOK ----------------
	0,			; unary plus
	0	;'&'(Concatenation)
;----------------

else
ImportLotusTokenDataSizeLookup	byte \
	8,			; constant		0
	4,			; variable
	8,			; range
	0,			; return
	0,			; parentheses
	2,			; 2 byte int		5
	-2,			; string constant
	-1,			; illegal
	0,			; unary minus
	0,			; plus
	0,			; minus			10
	0,			; multiplication
	0,			; division
	0,			; exponentiation
	0,			; =
	0,			; <>			15
	0,			; <=
	0,			; >=
	0,			; <
	0,			; >
	0,			; AND			20
	0,			; OR
	0,			; NOT
	0			; unary plus
endif

ImportFormulaGetToken	proc	near	uses	es,di
	locals	local	ImportStackFrame
	.enter	inherit near

	;-----------------------------------------------------------------------
	; create a node
	; we assume that the array has been zero-initialized

	les	di, locals.ISF_nodeArrayFreePtr
	mov	es:[di].IFN_tokenOffset, si
	lodsb
	mov	es:[di].IFN_token, al

EC<	cmp	es:[di].IFN_numChildren, 0 >
EC<	ERROR_NE IMPEX_INVALID_DATA_IN_NODE_ARRAY >
EC<	cmp	es:[di].IFN_childOffset, 0
EC<	ERROR_NE IMPEX_INVALID_DATA_IN_NODE_ARRAY >
EC<	cmp	es:[di].IFN_siblingOffset, 0
EC<	ERROR_NE IMPEX_INVALID_DATA_IN_NODE_ARRAY >

	mov	{word} es:[di].IFN_childOffset, NULL_PTR
	mov	{word} es:[di].IFN_siblingOffset, NULL_PTR

	add	locals.ISF_nodeArrayFreeOff, size ImportFormulaNode

	cmp	locals.ISF_nodeArrayFreeOff, \
		size ImportFormulaNode * IMPORT_FORMULA_MAX_NODES
EC <	WARNING_GE	IMPEX_NODE_ARRAY_OVERFLOW			>
	jge	error

	;-----------------------------------------------------------------------
	; al = Lotus token
	; store token type

	clr	ah
	mov	bx, ax
	cmp	al, IMPORT_END_OPERATORS_AND_OPERANDS
	ja	doFunction

	;
	; put ImportFunctionTokenType in al
	;
	mov	al, cs:[BuildTreeClassificationLookup][bx]
	mov	es:[di].IFN_tokenType, al ; store token type
	jmp	short doneTokenType

doFunction:
	;
	; ensure valid function
	; check for garbage
	; take care of special functions first
	;

	cmp	al, IMPORT_MISC_FUNC1
	je	checkDone
	cmp	al, IMPORT_MISC_FUNC2
	je	checkDone
	cmp	al, IMPORT_MISC_FUNC3
	je	checkDone
	cmp	al, IMPORT_START_FUNCTIONS
EC <	WARNING_B	IMPEX_IMPORTING_INVALID_DATA			>
	jb	error
if DBCS_PCGEOS	;1994-08-04(Thu)TOK ----------------
	cmp	al, 7ch
	je	NextCheck
	cmp	al, 8dh
	jae	NextCheck
	jmp	short checkDone	;@function is assigned in Japanese 1-2-3.
NextCheck:
endif	;----------------
	cmp	al, IMPORT_END_FUNCTIONS
EC <	WARNING_A	IMPEX_IMPORTING_INVALID_DATA			>
	ja	error
checkDone:

	mov	al, IMPORT_FUNCTION
	mov	es:[di].IFN_tokenType, al
	clr	al				; al <- length of token data
	jmp	short incSI

doneTokenType:
	;-----------------------------------------------------------------------
	; inc si depending on token

	mov	al, cs:[ImportLotusTokenDataSizeLookup][bx] ; al <- size
	cmp	al, -2
	jne	incSI

	;
	; string constant => need to skip past null terminator
	;
locateLoop:
	lodsb
	tst	al
	jne	locateLoop
	jmp	short done

incSI:
	add	si, ax				; update si
if DBCS_PCGEOS	;1994-09-01(Thu)TOK ----------------
	cmp	bl, 38h	;38h = @PMT
	je	IsNumberArgument3
	cmp	bl, 39h	;39h = @PV
	je	IsNumberArgument3
	cmp	bl, 3ah	;3ah = @FV
	je	IsNumberArgument3
	cmp	bl, 46h	;46h = @LENGTH
	je	IsNumberArgument1
	cmp	bl, 49h	;49h = @MID
	je	IsNumberArgument3
	cmp	bl, 4ch	;4ch = @FIND
	je	IsNumberArgument3
	cmp	bl, 68h	;68h = @LEFT
	je	IsNumberArgument2
	cmp	bl, 69h	;69h = @RIGHT
	je	IsNumberArgument2
	cmp	bl, 6ah	;6ah = @REPLACE
	je	IsNumberArgument4
	cmp	bl, 75h	;75h = @TERM
	je	IsNumberArgument3
	cmp	bl, 82h	;82h = @RANK is Japanese only.
	je	IsNumberArgument2
	jmp	short CheckNext
IsNumberArgument1:
	lodsb
	cmp	al, 1
	jne	SetNumberArgument
	jmp	short done
IsNumberArgument2:
	lodsb
	cmp	al, 2
	jne	SetNumberArgument
	jmp	short done
IsNumberArgument3:
	lodsb
	cmp	al, 3
	jne	SetNumberArgument
	jmp	short done
IsNumberArgument4:
	lodsb
	cmp	al, 4
	jne	SetNumberArgument
	jmp	short done
SetNumberArgument:
	neg	al
	push	di
	mov	di, bx
	sub	di, LOTUS_FUNCTION_NA
	mov	cs:[BuildTreeFixedArgFunctionNumArgsLookupTable][di], al
	pop	di
	jmp	short done

CheckNext:
	cmp	bl, 00h	;00h = constant, floating point
	je	SkipOver
	cmp	bl, 83h	;83h = @PUREAVG is Japanese only.
	je	SkipOver
	cmp	bl, 84h	;84h = @PURECOUNT is Japanese only.
	je	SkipOver
	cmp	bl, 85h	;85h = @PUREMAX is Japanese only.
	je	SkipOver
	cmp	bl, 86h	;86h = @PUREMIN is Japanese only.
	je	SkipOver
	cmp	bl, 87h	;87h = @PURESTD is Japanese only.
	je	SkipOver
	cmp	bl, 88h	;88h = @PUREVAR is Japanese only.
	je	SkipOver
	jmp	short done
SkipOver:
	inc	si	;for Japanese 1-2-3 worksheet file format
endif	;----------------

done:
	mov	al, es:[di].IFN_tokenType
	mov	bx, di				; bx <- node array offset
	clc

exit:
	.leave
	ret

error:
	mov	ax, TE_IMPORT_ERROR
	stc
	jmp	exit

ImportFormulaGetToken	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportFormulaPushNode

DESCRIPTION:	Push the node array offset onto the node stack.

CALLED BY:	INTERNAL (ImportFormulaBuildTree)

PASS:		ImportStackFrame
		bx - node array offset

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportFormulaPushNode	proc	near	uses	es,di
	locals	local	ImportStackFrame
	.enter	inherit near

	les	di, locals.ISF_nodeStackTopAddr	; es:di <- top of stk
	mov	ax, bx
	stosw					; store offset
	mov	locals.ISF_nodeStackTopOff, di	; update top of stk

EC<	cmp	di, IMPORT_FORMULA_MAX_TOKENS * 2 >
EC<	ERROR_AE IMPEX_NODE_STACK_OVERFLOW >

	.leave
	ret
ImportFormulaPushNode	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportFormulaPopNode

DESCRIPTION:	Pop an node array offset off of the node stack.

CALLED BY:	INTERNAL (ImportFormulaBuildTree)

PASS:		ImportStackFrame

RETURN:		ax,di - node array offset

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportFormulaPopNode	proc	near	uses	ds,si
	locals	local	ImportStackFrame
	.enter	inherit near

	sub	locals.ISF_nodeStackTopOff, 2		; dec top of stk
	lds	si, locals.ISF_nodeStackTopAddr		; ds:si <- top of stk
EC<	cmp	si, 0 >
EC<	ERROR_L	IMPEX_NODE_STACK_UNDERFLOW >
	lodsw						; ax <- offset
	mov	di, ax

	.leave
	ret
ImportFormulaPopNode	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportFormulaAddChild

DESCRIPTION:	Make the given node a child of another.

CALLED BY:	INTERNAL (ImportFormulaBuildTree)

PASS:		ImportStackFrame
		es - ISF_nodeArraySeg
		bx - node array offset of parent
		di - node array offset of child

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportFormulaAddChild	proc	near	uses	bx,di
	locals	local	ImportStackFrame
	.enter	inherit near

	inc	es:[bx].IFN_numChildren		; up child count
	push	di				; save new child
	xchg	es:[bx].IFN_childOffset, di	; di<-old child,new child stored
	pop	bx				; retrieve new child
	mov	es:[bx].IFN_siblingOffset, di	; make old child the sibling

if 0	; LIFO addition, unwanted **********************************************
	xchg	bx, di				; di <- parent, bx <- child
	cmp	es:[di].IFN_numChildren, 0
	jne	notFirstChild

	;-----------------------------------------------------------------------
	; tack on child as 1st child

EC<	cmp	es:[di].IFN_childOffset, NULL_PTR >
EC<	ERROR_NE IMPEX_INVALID_DATA_IN_NODE_ARRAY >

	mov	es:[di].IFN_childOffset, bx	; store child's offset
	jmp	short doneAdding

notFirstChild:
	;-----------------------------------------------------------------------
	; locate end of child chain
	; tack on child as sibling

	push	bx				; save child ptr
	mov	bx, es:[di].IFN_childOffset	; es:bx <- 1st child

locateLastChildLoop:
	cmp	{word} es:[bx].IFN_siblingOffset, NULL_PTR
	je	lastChildFound

	mov	bx, es:[bx].IFN_siblingOffset	; es:bx <- next child
	jmp	short locateLastChildLoop

lastChildFound:
	pop	es:[bx].IFN_siblingOffset

doneAdding:
	;
	; inc child count
	;
	inc	es:[di].IFN_numChildren		; up child count
endif	;***********************************************************************

	.leave
	ret
ImportFormulaAddChild	endp

