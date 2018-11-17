
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		importTraverseTree.asm

AUTHOR:		Cheng, 10/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial revision

DESCRIPTION:
		
	$Id: importTraverseTree.asm,v 1.1 97/04/07 11:41:41 newdeal Exp $


-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportFormulaTraverseTree

DESCRIPTION:	Traverse the expression tree and translate the Lotus tokens
		into GeoCalc tokens in infix form.

		This routine gets recursively called.

CALLED BY:	INTERNAL (ImportFormulaLotusPostfixToCalcInfix)

PASS:		ImportStackFrame
		ds:si - node array offset of root
		es:di - GeoCalc output stream

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:
	ds:si - parent node
	bx - child node

PSEUDO CODE/STRATEGY:
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

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportTraverseTreeRoutineLookupTable	nptr \
	offset ImportTraverseTreeProcessOperand,
	offset ImportTraverseTreeProcessUnaryOp,
	offset ImportTraverseTreeProcessBinaryOp,
	offset ImportTraverseTreeProcessParentheses,
	offset ImportTraverseTreeProcessFunction,
	offset ImportTraverseTreeProcessEndOfExpr

ImportFormulaTraverseTree	proc	near	uses	bx
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	ForceRef SSM_local
	.enter	inherit near

	mov	bl, ds:[si].IFN_tokenType	; bl <- token type
	clr	bh
	shl	bx, 1				; bx <- offset into tbl
	mov	bx, cs:[ImportTraverseTreeRoutineLookupTable][bx]
	call	bx				; pass ds:si = node off
						; destroys ax,bx

	.leave
	ret
ImportFormulaTraverseTree	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTraverseTreeProcessOperand

DESCRIPTION:	Traverse the tree encoded in the node array to generate an
		infix expression.  Translation into the GeoCalc clipboard
		format is done at the same time.

CALLED BY:	INTERNAL (ImportFormulaTraverseTree)

PASS:		ImportStackFrame
		ds:si - current node in the node array
		es:di - GeoCalc output stream

RETURN:		nothing

DESTROYED:	ax,bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportTraverseTreeProcessOperand	proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	ForceRef SSM_local
	.enter	inherit near

	call	ImportTranslateOperand

	.leave
	ret
ImportTraverseTreeProcessOperand	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTraverseTreeProcessUnaryOp

DESCRIPTION:	Traverse the tree encoded in the node array to generate an
		infix expression.  Translation into the GeoCalc clipboard
		format is done at the same time.

CALLED BY:	INTERNAL (ImportFormulaTraverseTree)

PASS:		ImportStackFrame
		ds:si - current node in the node array
		es:di - GeoCalc output stream

RETURN:		nothing

DESTROYED:	ax,bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportTraverseTreeProcessUnaryOp	proc	near	uses	cx,si
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	ForceRef SSM_local
	.enter	inherit near

	;-----------------------------------------------------------------------
	; confirm unary operator
	; confirm 1 child

EC<	cmp	ds:[si].IFN_tokenType, IMPORT_UNARY_OP >
EC<	ERROR_NE IMPEX_REG_DESTROYED >
EC<	cmp	ds:[si].IFN_numChildren, 1 >
EC<	ERROR_NE IMPEX_INVALID_DATA_IN_NODE_ARRAY >

	;-----------------------------------------------------------------------
	; if operator is unary plus, ignore it

	mov	al, ds:[si].IFN_token		; al <- Lotus token
	cmp	al, LOTUS_FUNCTION_UPLUS	; unary plus?
	je	done				; done if so

	;-----------------------------------------------------------------------
	; process operator, one of plus minus / not

	mov	al, PARSER_TOKEN_OPERATOR
	ImportStosb
	jc	exit

	cmp	al, LOTUS_FUNCTION_UMINUS
	mov	al, OP_NEGATION
	je	doneTranslation

;	mov	al, OP_NOT

doneTranslation:
	ImportStosb
	jc	exit

done:
	;-----------------------------------------------------------------------
	; process operand

	clr	cl
	call	ImportGetChild			; bx <- node array off of child
	mov	si, bx
	call	ImportFormulaTraverseTree

exit:
	.leave
	ret
ImportTraverseTreeProcessUnaryOp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTraverseTreeProcessBinaryOp

DESCRIPTION:	Traverse the tree encoded in the node array to generate an
		infix expression.  Translation into the GeoCalc clipboard
		format is done at the same time.

CALLED BY:	INTERNAL (ImportFormulaTraverseTree)

PASS:		ImportStackFrame
		ds:si - current node in the node array
		es:di - GeoCalc output stream

RETURN:		nothing

DESTROYED:	ax,bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportTraverseTreeProcessBinaryOp	proc	near	uses	cx
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	ForceRef SSM_local
	.enter	inherit near

	;-----------------------------------------------------------------------
	; confirm binary operator
	; confirm 2 children

EC<	cmp	ds:[si].IFN_tokenType, IMPORT_BINARY_OP >
EC<	ERROR_NE IMPEX_REG_DESTROYED >
EC<	cmp	ds:[si].IFN_numChildren, 2 >
EC<	ERROR_NE IMPEX_INVALID_DATA_IN_NODE_ARRAY >

	;-----------------------------------------------------------------------
	; special case AND and OR
	; since Lotus has these as binary operators and GeoCalc has them
	; as functions

	mov	al, ds:[si].IFN_token		; al <- IFN_token
	cmp	al, LOTUS_FUNCTION_AND
	je	specialCaseAndOr
	cmp	al, LOTUS_FUNCTION_OR
	LONG	jne	notAndOr

specialCaseAndOr:
	;
	; translate function
	;
	push	ax				; save Lotus token
	mov	al, PARSER_TOKEN_FUNCTION	; mark as function
	ImportStosb
	pop	ax				; retrieve Lotus token
	LONG	jc 	exit

	cmp	al, LOTUS_FUNCTION_AND
	mov	ax, FUNCTION_ID_AND
	je	10$
	mov	ax, FUNCTION_ID_OR
10$:
	ImportStosw				; store GeoCalc function id
	LONG	jc	exit

	;
	; process operand #1
	;
	clr	cl				; specify 1st child
	call	ImportGetChild			; bx <- node array off of child
	push	si				; save parent
	mov	si, bx				; new root
	call	ImportFormulaTraverseTree
	pop	si
	jc	exit

	mov	al, PARSER_TOKEN_ARG_END
	ImportStosb
	jc	exit

	;
	; process operand #2
	;
	mov	cl, 1				; specify 2nd child
	call	ImportGetChild			; bx <- node array off of child
	push	si				; save parent
	mov	si, bx				; new root
	call	ImportFormulaTraverseTree
	pop	si
	jc	exit

	mov	al, PARSER_TOKEN_ARG_END
	ImportStosb
	jc	exit

	mov	al, PARSER_TOKEN_CLOSE_FUNCTION
	ImportStosb
	jc	exit

	mov	al, RT_VALUE
	jmp	short exit

notAndOr:
	;-----------------------------------------------------------------------
	; process first operand

	clr	cl				; specify 1st child
	call	ImportGetChild			; bx <- node array off of child
	push	si				; save parent
	mov	si, bx				; new root
	call	ImportFormulaTraverseTree	; go process, destroys ax
	pop	si				; retrieve parent
	jc	exit

	;-----------------------------------------------------------------------
	; confirm and translate binary op

EC<	cmp	ds:[si].IFN_tokenType, IMPORT_BINARY_OP >
EC<	ERROR_NE IMPEX_REG_DESTROYED >

	call	ImportTranslateBinaryOp		; translate operator
	jc	exit

	;-----------------------------------------------------------------------
	; process second operand

	mov	cl, 1
	call	ImportGetChild			; si <- node array off of child
	push	si				; save parent
	mov	si, bx				; new root
	call	ImportFormulaTraverseTree	; go process
	pop	si				; retrieve parent

exit:
	.leave
	ret
ImportTraverseTreeProcessBinaryOp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTraverseTreeProcessParentheses

DESCRIPTION:	Traverse the tree encoded in the node array to generate an
		infix expression.  Translation into the GeoCalc clipboard
		format is done at the same time.

CALLED BY:	INTERNAL (ImportFormulaTraverseTree)

PASS:		ImportStackFrame
		ds:si - current node in the node array
		es:di - GeoCalc output stream

RETURN:		nothing

DESTROYED:	ax,bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	TraverseTree(Child(node));
	TranslateNode(t);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportTraverseTreeProcessParentheses	proc	near	uses	cx
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	ForceRef SSM_local
	.enter	inherit near

EC<	cmp	ds:[si].IFN_tokenType, IMPORT_PARENTHESES >
EC<	ERROR_NE IMPEX_REG_DESTROYED >

	;-----------------------------------------------------------------------
	; write out an open parenthesis

	mov	al, PARSER_TOKEN_OPEN_PAREN
	ImportStosb
	jc	exit

	;-----------------------------------------------------------------------
	; process child

EC<	cmp	ds:[si].IFN_numChildren, 1 >
EC<	ERROR_NE IMPEX_INVALID_DATA_IN_NODE_ARRAY >

	clr	cl
	call	ImportGetChild			; bx <- node array off of child
	push	si				; save parent
	mov	si, bx				; new root
	call	ImportFormulaTraverseTree
	pop	si
	jc	exit

	;-----------------------------------------------------------------------
	; wrire out a close parenthesis

	mov	al, PARSER_TOKEN_CLOSE_PAREN
	ImportStosb
exit:
	.leave
	ret
ImportTraverseTreeProcessParentheses	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTraverseTreeProcessFunction

DESCRIPTION:	Traverse the tree encoded in the node array to generate an
		infix expression.  Translation into the GeoCalc clipboard
		format is done at the same time.

CALLED BY:	INTERNAL (ImportFormulaTraverseTree)

PASS:		ImportStackFrame
		ds:si - current node in the node array
		es:di - GeoCalc output stream

RETURN:		al - ReturnType

DESTROYED:	ah,bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	TranslateNode(t);
	x <- num children
	copy x operands

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportTraverseTreeProcessFunction	proc	near	uses	cx
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	ForceRef SSM_local
	.enter	inherit near

	call	ImportTranslateFunction		; translate function
						; al <- ReturnType
	jc	exit

	push	ax
	cmp	ds:[si].IFN_numChildren, 0
	je	done

	clr	cl

processLoop:
	call	ImportGetChild			; bx <- node array off of child
	push	si				; save parent
	mov	si, bx				; new root
	call	ImportFormulaTraverseTree
	pop	si
	jc	exitPop

	mov	al, PARSER_TOKEN_ARG_END
	ImportStosb
	jc	exitPop

	inc	cl
	cmp	cl, ds:[si].IFN_numChildren
	jl	processLoop

EC<	ERROR_G	IMPEX_REG_DESTROYED >

done:
	mov	al, PARSER_TOKEN_CLOSE_FUNCTION
	ImportStosb
	pop	ax				; retrieve ReturnType

exit:
	.leave
	ret

exitPop:
	add	sp, 2
	stc
	jmp	exit

ImportTraverseTreeProcessFunction	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTraverseTreeProcessEndOfExpr

DESCRIPTION:	Traverse the tree encoded in the node array to generate an
		infix expression.  Translation into the GeoCalc clipboard
		format is done at the same time.

CALLED BY:	INTERNAL (ImportFormulaTraverseTree)

PASS:		ImportStackFrame
		ds:si - current node in the node array
		es:di - GeoCalc output stream

RETURN:		nothing

DESTROYED:	ax,bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	TraverseTree(Child(node));
	TranslateNode(t);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportTraverseTreeProcessEndOfExpr	proc	near	uses	cx
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	ForceRef SSM_local
	.enter	inherit near

	clr	cl
	call	ImportGetChild			; bx <- node array off of child
	push	si				; save parent
	mov	si, bx				; new root
	call	ImportFormulaTraverseTree
	pop	si
	jc	exit

	mov	al, PARSER_TOKEN_END_OF_EXPRESSION
	ImportStosb
exit:
	.leave
	ret
ImportTraverseTreeProcessEndOfExpr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImpexGetChild

DESCRIPTION:	Retrieve the node array offset of the desired child.

CALLED BY:	INTERNAL (ImportFormulaTraverseTree)

PASS:		ImportStackFrame
		ds:si - node array of parent
		cl - child number (0 based, ie. 0 = 1st child)

RETURN:		bx - node array offset of child

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportGetChild	proc	near	uses	cx
	.enter

	clr	ch				; cx <- child offset
EC<	cmp	ds:[si].IFN_numChildren, 0 >	; error if no children
EC<	ERROR_LE IMPEX_INVALID_DATA_IN_NODE_ARRAY >
EC<	cmp	cl, ds:[si].IFN_numChildren >
EC<	ERROR_GE IMPEX_INVALID_DATA_IN_NODE_ARRAY >

	mov	bx, ds:[si].IFN_childOffset	; ds:[bx] <- child
	jcxz	done				; done if 1st child wanted

locateLoop:
EC<	cmp	ds:[bx].IFN_siblingOffset, NULL_PTR >
EC<	ERROR_E IMPEX_INVALID_DATA_IN_NODE_ARRAY >

	mov	bx, ds:[bx].IFN_siblingOffset	; next child
	loop	locateLoop

done:
	.leave
	ret
ImportGetChild	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTranslateBinaryOp

DESCRIPTION:	

CALLED BY:	INTERNAL (ImportTraverseTreeProcessBinaryOp)

PASS:		ImportStackFrame

RETURN:		

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
    Need to deal with:
	LOTUS_FUNCTION_PLUS
	LOTUS_FUNCTION_SUB
	LOTUS_FUNCTION_MULTIPLY
	LOTUS_FUNCTION_DIVIDE
	LOTUS_FUNCTION_EXPONENT
	LOTUS_FUNCTION_EQUAL
	LOTUS_FUNCTION_NOT_EQUAL
	LOTUS_FUNCTION_LT_OR_EQUAL
	LOTUS_FUNCTION_GT_OR_EQUAL
	LOTUS_FUNCTION_LT
	LOTUS_FUNCTION_GT
	LOTUS_FUNCTION_AND
	LOTUS_FUNCTION_OR
    Use fact that the Lotus operators are consecutive.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

if PZ_PCGEOS
GeoCalcBinaryOpEquivTable	byte \
	OP_ADDITION,
	OP_SUBTRACTION,
	OP_MULTIPLICATION,
	OP_DIVISION,
	OP_EXPONENTIATION,
	OP_EQUAL,
	OP_NOT_EQUAL,
	OP_LESS_THAN_OR_EQUAL,
	OP_GREATER_THAN_OR_EQUAL,
	OP_LESS_THAN,
	OP_GREATER_THAN,
	-1,			; AND
;1994-08-29(Mon)TOK ----------------
	-1,			; OR
	-1,	;#NOT#
	-1,	;unary +
	OP_STRING_CONCAT	;'&'(Concatenation)
;----------------

else
GeoCalcBinaryOpEquivTable	byte \
	OP_ADDITION,
	OP_SUBTRACTION,
	OP_MULTIPLICATION,
	OP_DIVISION,
	OP_EXPONENTIATION,
	OP_EQUAL,
	OP_NOT_EQUAL,
	OP_LESS_THAN_OR_EQUAL,
	OP_GREATER_THAN_OR_EQUAL,
	OP_LESS_THAN,
	OP_GREATER_THAN,
	-1,			; AND
	-1			; OR
endif

ImportTranslateBinaryOp	proc	near	uses	bx
	.enter	

	mov	al, PARSER_TOKEN_OPERATOR
	ImportStosb
	jc	exit

	mov	al, ds:[si].IFN_token
	sub	al, LOTUS_FUNCTION_PLUS		; make 0 based
	mov	bl, al
	clr	bh				; bx <- 0 based offset

	mov	al, cs:[GeoCalcBinaryOpEquivTable][bx]
EC <	cmp	al, -1					>
EC <	ERROR_E	IMPEX_ATTEMPT_TO_TRANSLATE_AND_OR	>

	ImportStosb
exit:
	.leave
	ret
ImportTranslateBinaryOp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTranslateOperand

DESCRIPTION:	Translate the Lotus operand into the GeoCalc equivalent.
		
		constant
		variable = cell
		2 byte integer
		string

CALLED BY:	INTERNAL (ImportTraverseTreeProcessOperand)

PASS:		ImportStackFrame
		ds:si - node of operand
		es:di - GeoCalc output stream

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	PARSER_TOKEN_NUMBER
	PARSER_TOKEN_STRING
	PARSER_TOKEN_CELL

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportTranslateOperandLookupTable	nptr \
	offset ImportTranslateOperandConstant,
	offset ImportTranslateOperandVariable,
	offset ImportTranslateOperandRange,
	-1,					; return
	-1,					; parentheses
	offset ImportTranslateOperandInteger,
	offset ImportTranslateOperandString

ImportTranslateOperand	proc	near	uses	bx,ds,si
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	ForceRef SSM_local
	.enter	inherit near

	mov	al, ds:[si].IFN_token		; al <- Lotus token
	mov	si, ds:[si].IFN_tokenOffset
	mov	ds, locals.ISF_lotusDataStream.segment	; ds:si <- token
	inc	si				; ds:si <- operand

	clr	ah
	mov	bx, ax
	shl	bx, 1
	mov	bx, cs:[ImportTranslateOperandLookupTable][bx]
EC<	cmp	al, LOTUS_FUNCTION_STR_CONST >
EC<	ERROR_G	IMPEX_ASSERTION_FAILED >
EC<	cmp	bx, -1 >
EC<	ERROR_E	IMPEX_ASSERTION_FAILED >
	call	bx

	.leave
	ret
ImportTranslateOperand	endp



ImportTranslateOperandConstant	proc	near
	locals	local	ImportStackFrame
	ForceRef locals
	.enter	inherit near

	mov	al, PARSER_TOKEN_NUMBER
	ImportStosb
	jc	exit

	;
	; ds:si = 64 bit IEEE number
	;
	mov	ax, di				; ax <- offset in output stream
	add	ax, FPSIZE			; ax <- cur offset + len to copy
	cmp	ax, (CELL_FORMULA_BUFFER_SIZE)
	jae	error

	call	FloatIEEE64ToGeos80		; convert number
	call	FloatPopNumber			; transfer to output stream
	add	di, FPSIZE			; update ptr in data stream
	clc
exit:
	.leave
	ret

error:
	call	ImportStoreErrFunction
	stc
	jmp	exit

ImportTranslateOperandConstant	endp


ImportTranslateOperandVariable	proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	ForceRef SSM_local
	.enter	inherit near

	call	ImportTranslateCellReference
	
	.leave
	ret
ImportTranslateOperandVariable	endp


ImportTranslateOperandRange	proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	ForceRef SSM_local
	.enter	inherit near

	call	ImportTranslateCellReference
	jc	exit

	mov	ax, (OP_RANGE_SEPARATOR shl 8) or PARSER_TOKEN_OPERATOR
	ImportStosw
	jc	exit

	call	ImportTranslateCellReference
exit:
	.leave
	ret
ImportTranslateOperandRange	endp


ImportTranslateOperandInteger	proc	near
	locals	local	ImportStackFrame
	ForceRef locals
	.enter	inherit near

	mov	al, PARSER_TOKEN_NUMBER
	ImportStosb
	jc	exit

	;
	; ds:si = 2 byte integer
	;
	;
	mov	ax, di				; ax <- offset in output stream
	add	ax, FPSIZE			; ax <- cur offset + len to copy
	cmp	ax, (CELL_FORMULA_BUFFER_SIZE)
	jae	error

	lodsw					; ax <- integer
	call	FloatWordToFloat
	call	FloatPopNumber			; pass es:di = location
	add	di, FPSIZE			; update ptr in data stream
	clc
exit:
	.leave
	ret

error:
	call	ImportStoreErrFunction
	stc
	jmp	exit

ImportTranslateOperandInteger	endp


ImportTranslateOperandString	proc	near	uses	cx
	locals	local	ImportStackFrame
	ForceRef locals
	.enter	inherit near

	mov	al, PARSER_TOKEN_STRING
	ImportStosb
	jc	exit

	;
	; ds:si = ASCIIZ string
	; determine length
	; store length
	; copy string
	;
	clr	cx				; init count
	push	si

locateLoop:
	lodsb					; al <- character
	tst	al				; null terminator?
	je	done				; branch if so
	inc	cx				; else inc count
	jmp	short locateLoop

done:
	pop	si
	;
	; check if entire operand string can fit in what's left of buffer
	;
	mov	ax, di				; ax <- offset in output stream
	add	ax, cx				; ax <- cur offset + len to copy
if DBCS_PCGEOS	;1994-07-27(Wed)TOK ----------------
	add	ax, cx
endif	;----------------
	add	ax, 2				; add 2 bytes for length
	cmp	ax, CELL_FORMULA_BUFFER_SIZE
	jae	error
	
if DBCS_PCGEOS	;1994-07-27(Wed)TOK ----------------
	push	bx
	push	cx
	push	dx
	push	ds
	push	si

	add	di, 2
	mov	ax, C_CTRL_A
	mov	bx, CODE_PAGE_SJIS
	clr	dx
	call	LocalDosToGeos

	mov	ax, es
	mov	ds, ax
	mov	ax, di
	mov	si, ax
	mov	dx, ax
Working:
	LocalGetChar ax, dssi
	LocalCmpChar ax, C_TAB
	jz	Store
	LocalCmpChar ax, C_CR
	jz	Store
	LocalCmpChar ax, C_PAGE_BREAK
	jz	Store
	LocalCmpChar ax, ' '
	jb	Skip
Store:
	LocalPutChar esdi, ax
Skip:
	loop	Working
	sub	di, dx
	mov	ax, di
	shr	ax, 1
	mov	di, dx
	sub	di, 2
	stosw	;store text(without NULL terminater) character number
	shl	ax, 1
	add	di, ax

	pop	si
	pop	ds
	pop	dx
	pop	cx
	pop	bx

	add	si, cx
else	;----------------
	mov	ax, cx				; ax <- length
	stosw
	rep	movsb				; copy string
endif	;----------------
	clc
exit:
	.leave
	ret

error:
	call	ImportStoreErrFunction
	stc	
	jmp	exit

ImportTranslateOperandString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTranslateCellReference

DESCRIPTION:	Translates a Lotus cell reference into a GeoCalc cell
		reference.

CALLED BY:	INTERNAL (utility)

PASS:		ds:si - Lotus cell reference
		es:di - GeoCalc output stream
		ImportStackFrame

RETURN:		ds:si - updated
		es:di - updated

DESTROYED:	ax,bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Lotus uses 14 bits for number storage.
	MS bit (bit 15) = absolute/relative.
	Bit 14 = ?

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Quattro Pro files exported to Lotus123 do not sign extend
	negative references properly, necessitating some icky hacks.
	For column references, QP files use the high bit of the low
	word to indicate negativity.  

	For row references, it gets uglier.  QP use the low bit of
	the high word to indiciate a negative cell reference.  But
	that bit is also needed to refer to large cell numbers.
	(8192 = 0001:0000h).  Thus, a relative cell reference to 
	somethine more than ffffh rows away can also be interpreted as
	a negative cell reference.  The only way to determine how to
	interpret it is to add the negative value to the current row
	number and check if it is a valid reference.  If not, treat
	it as a positive value.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ImportTranslateCellReference	proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef locals
	.enter	inherit near

	; check if there is enough room for the token and the CellReference
	;
	cmp	di, (CELL_FORMULA_BUFFER_SIZE - 1 - size CellReference)
	jae	error

	mov	al, PARSER_TOKEN_CELL
	stosb

	lodsw					; get column
	mov	bx, ax				; bx <- column
	lodsw					; ax <- row

	;
	; check both the Lotus and Quattro-Pro-saved-as-Lotus 
	; most significant bit for a column reference
	;
	test	bx, LOTUS_QPRO_COL_MS_CELL_REF_BIT or \
		(LOTUS_MS_CELL_REF_BIT shl 8)		; negative column ref?
	jz	checkRow				; nope, it's positive
	or	bh, LOTUS_QPRO_COL_SIGN_EXTEND_MASK

checkRow:
	test	ah, LOTUS_MS_CELL_REF_BIT	; Lotus negative ref?
	jnz	signExtend			; sign extend
	test	ah, LOTUS_QPRO_ROW_MS_CELL_REF_BIT	; QP negative ref?
	jz	doneRefCheck			; branch if not

	; More Quattro Pro hacks:
	; Check if this is a legal positive reference.
	; if not, assume it was meant to be a positive reference
	; and clear the sign bit.
	;
	push	ax
	andnf	ah, 1fh				; clear bits above MS bit
	add	ax, SSM_local.SSMDAS_row	; add this cell's row number
	cmp	ax, 8192			; is ax a valid row number?
	pop	ax
	jl	doneRefCheck			; yes: ax is a big pos reference
signExtend:
	or	ah, LOTUS_QPRO_ROW_SIGN_EXTEND_MASK

doneRefCheck:
	xor	bx, mask LCR_ABS_REL_REF
	xor	ax, mask LCR_ABS_REL_REF

	mov	es:[di].CR_row, ax
	mov	es:[di].CR_column, bx
	add	di, size CellReference
done:
	.leave
	ret

error:
	call	ImportStoreErrFunction
	stc
	jmp	done

ImportTranslateCellReference	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTranslateFunction

DESCRIPTION:	Translate the Lotus function into the GeoCalc equivalent.

CALLED BY:	INTERNAL (ImportTraverseTreeProcessFunction)

PASS:		ImportStackFrame
		ds:si - node of function
		es:di - GeoCalc output stream

RETURN:		al - ReturnType

DESTROYED:	ah,bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

if PZ_PCGEOS
ImportTranslateFunctionEquivTable	word \
	FUNCTION_ID_NA,
	FUNCTION_ID_ERR,
	FUNCTION_ID_ABS,
	FUNCTION_ID_INT,
	FUNCTION_ID_SQRT,
	FUNCTION_ID_LOG,
	FUNCTION_ID_LN,
	FUNCTION_ID_PI,
	FUNCTION_ID_SIN,
	FUNCTION_ID_COS,
	FUNCTION_ID_TAN,
	FUNCTION_ID_ATAN2,
	FUNCTION_ID_ATAN,
	FUNCTION_ID_ASIN,
	FUNCTION_ID_ACOS,
	FUNCTION_ID_EXP,
	FUNCTION_ID_MOD,
	FUNCTION_ID_CHOOSE,
	-1,			; ISNA
	FUNCTION_ID_ISERR,
	FUNCTION_ID_FALSE,
	FUNCTION_ID_TRUE,
	FUNCTION_ID_RANDOM,
	FUNCTION_ID_DATE,
;1994-08-30(Tue)TOK ----------------
	FUNCTION_ID_NOW,
;----------------
	FUNCTION_ID_PMT,
	FUNCTION_ID_PV,
	FUNCTION_ID_FV,
	FUNCTION_ID_IF,
	FUNCTION_ID_DAY,
	FUNCTION_ID_MONTH,
	FUNCTION_ID_YEAR,
	FUNCTION_ID_ROUND,
	FUNCTION_ID_TIME,
	FUNCTION_ID_HOUR,
	FUNCTION_ID_MINUTE,
	FUNCTION_ID_SECOND,
	FUNCTION_ID_ISNUMBER,
	FUNCTION_ID_ISSTRING,
	FUNCTION_ID_LENGTH,
	FUNCTION_ID_VALUE,
	FUNCTION_ID_STRING,
	FUNCTION_ID_MID,
	FUNCTION_ID_CHAR,
	FUNCTION_ID_CODE,
	FUNCTION_ID_FIND,
	FUNCTION_ID_DATEVALUE,
	FUNCTION_ID_TIMEVALUE,
	-1,			; CELL POINTER
	FUNCTION_ID_SUM,
	FUNCTION_ID_AVG,
	FUNCTION_ID_COUNT,
	FUNCTION_ID_MIN,
	FUNCTION_ID_MAX,
	FUNCTION_ID_VLOOKUP,
	FUNCTION_ID_NPV,
	FUNCTION_ID_VARP,
	FUNCTION_ID_STDP,
	FUNCTION_ID_IRR,
	FUNCTION_ID_HLOOKUP,
	-1,			; DSUM
	-1,			; DAVG
	-1,			; DCNT
	-1,			; DMIN
	-1,			; DMAX
	-1,			; DVAR
	-1,			; DSTD
	FUNCTION_ID_INDEX,
	FUNCTION_ID_COLS,
	FUNCTION_ID_ROWS,
	FUNCTION_ID_REPEAT,
	FUNCTION_ID_UPPER,
	FUNCTION_ID_LOWER,
	FUNCTION_ID_LEFT,
	FUNCTION_ID_RIGHT,
	FUNCTION_ID_REPLACE,
	FUNCTION_ID_PROPER,
	-1,			; CELL
	FUNCTION_ID_TRIM,
	FUNCTION_ID_CLEAN,
	-1,			; S
	FUNCTION_ID_N,
	FUNCTION_ID_EXACT,	; EXACT
	-1,			; CALL
	-1,			; APP
	FUNCTION_ID_RATE,
	FUNCTION_ID_TERM,
	FUNCTION_ID_CTERM,
	FUNCTION_ID_SLN,
	FUNCTION_ID_SYD,
;1994-08-30(Tue)TOK ----------------
	FUNCTION_ID_DDB,
	-1,	;@FULLP(7ah) is Japanese only.
	-1,	;@HALFP(7bh) is Japanese only.
	-1,	;dummy
	-1,	;@SUUJI(7dh) is Japanese only.
	-1,	;@NENGO(7eh) is Japanese only.
	-1,	;@DECIMAL(7fh) is Japanese only.
	-1,	;@HEX(80h) is Japanese only.
	FUNCTION_ID_DB	;@DB(81h) is Japanese only.
;----------------

else
ImportTranslateFunctionEquivTable	word \
	FUNCTION_ID_NA,
	FUNCTION_ID_ERR,
	FUNCTION_ID_ABS,
	FUNCTION_ID_INT,
	FUNCTION_ID_SQRT,
	FUNCTION_ID_LOG,
	FUNCTION_ID_LN,
	FUNCTION_ID_PI,
	FUNCTION_ID_SIN,
	FUNCTION_ID_COS,
	FUNCTION_ID_TAN,
	FUNCTION_ID_ATAN2,
	FUNCTION_ID_ATAN,
	FUNCTION_ID_ASIN,
	FUNCTION_ID_ACOS,
	FUNCTION_ID_EXP,
	FUNCTION_ID_MOD,
	FUNCTION_ID_CHOOSE,
	-1,			; ISNA
	FUNCTION_ID_ISERR,
	FUNCTION_ID_FALSE,
	FUNCTION_ID_TRUE,
	FUNCTION_ID_RANDOM,
	FUNCTION_ID_DATE,
	FUNCTION_ID_TODAY,
	FUNCTION_ID_PMT,
	FUNCTION_ID_PV,
	FUNCTION_ID_FV,
	FUNCTION_ID_IF,
	FUNCTION_ID_DAY,
	FUNCTION_ID_MONTH,
	FUNCTION_ID_YEAR,
	FUNCTION_ID_ROUND,
	FUNCTION_ID_TIME,
	FUNCTION_ID_HOUR,
	FUNCTION_ID_MINUTE,
	FUNCTION_ID_SECOND,
	FUNCTION_ID_ISNUMBER,
	FUNCTION_ID_ISSTRING,
	FUNCTION_ID_LENGTH,
	FUNCTION_ID_VALUE,
	FUNCTION_ID_STRING,
	FUNCTION_ID_MID,
	FUNCTION_ID_CHAR,
	FUNCTION_ID_CODE,
	FUNCTION_ID_FIND,
	FUNCTION_ID_DATEVALUE,
	FUNCTION_ID_TIMEVALUE,
	-1,			; CELL POINTER
	FUNCTION_ID_SUM,
	FUNCTION_ID_AVG,
	FUNCTION_ID_COUNT,
	FUNCTION_ID_MIN,
	FUNCTION_ID_MAX,
	FUNCTION_ID_VLOOKUP,
	FUNCTION_ID_NPV,
	FUNCTION_ID_VARP,
	FUNCTION_ID_STDP,
	FUNCTION_ID_IRR,
	FUNCTION_ID_HLOOKUP,
	-1,			; DSUM
	-1,			; DAVG
	-1,			; DCNT
	-1,			; DMIN
	-1,			; DMAX
	-1,			; DVAR
	-1,			; DSTD
	FUNCTION_ID_INDEX,
	FUNCTION_ID_COLS,
	FUNCTION_ID_ROWS,
	FUNCTION_ID_REPEAT,
	FUNCTION_ID_UPPER,
	FUNCTION_ID_LOWER,
	FUNCTION_ID_LEFT,
	FUNCTION_ID_RIGHT,
	FUNCTION_ID_REPLACE,
	FUNCTION_ID_PROPER,
	-1,			; CELL
	FUNCTION_ID_TRIM,
	FUNCTION_ID_CLEAN,
	-1,			; S
	FUNCTION_ID_N,
	FUNCTION_ID_EXACT,	; EXACT
	-1,			; CALL
	-1,			; APP
	FUNCTION_ID_RATE,
	FUNCTION_ID_TERM,
	FUNCTION_ID_CTERM,
	FUNCTION_ID_SLN,
	FUNCTION_ID_SYD,
	FUNCTION_ID_DDB
endif

if PZ_PCGEOS
LotusFunctionReturnTypeLookupTable	byte \
	RT_ERROR,		; LOTUS_FUNCTION_NA		1fh
	RT_ERROR,		; LOTUS_FUNCTION_ERR		20h
	RT_VALUE,		; LOTUS_FUNCTION_ABS		21h
	RT_VALUE,		; LOTUS_FUNCTION_INT		22h
	RT_VALUE,		; LOTUS_FUNCTION_SQRT		23h
	RT_VALUE,		; LOTUS_FUNCTION_LOG		24h
	RT_VALUE,		; LOTUS_FUNCTION_LN		25h
	RT_VALUE,		; LOTUS_FUNCTION_PI		26h
	RT_VALUE,		; LOTUS_FUNCTION_SIN		27h
	RT_VALUE,		; LOTUS_FUNCTION_COS		28h
	RT_VALUE,		; LOTUS_FUNCTION_TAN		29h
	RT_VALUE,		; LOTUS_FUNCTION_ATAN2		2ah
	RT_VALUE,		; LOTUS_FUNCTION_ATAN		2bh
	RT_VALUE,		; LOTUS_FUNCTION_ASIN		2ch
	RT_VALUE,		; LOTUS_FUNCTION_ACOS		2dh
	RT_VALUE,		; LOTUS_FUNCTION_EXP		2eh
	RT_VALUE,		; LOTUS_FUNCTION_MOD		2fh
	RT_VALUE, ;???		; LOTUS_FUNCTION_CHOOSE		30h
	RT_VALUE,		; LOTUS_FUNCTION_ISNA		31h
	RT_VALUE,		; LOTUS_FUNCTION_ISERR		32h
	RT_VALUE,		; LOTUS_FUNCTION_FALSE		33h
	RT_VALUE,		; LOTUS_FUNCTION_TRUE		34h
	RT_VALUE,		; LOTUS_FUNCTION_RAND		35h
	RT_VALUE,		; LOTUS_FUNCTION_DATE		36h
	RT_VALUE,		; LOTUS_FUNCTION_TODAY		37h
	RT_VALUE,		; LOTUS_FUNCTION_PMT		38h
	RT_VALUE,		; LOTUS_FUNCTION_PV		39h
	RT_VALUE,		; LOTUS_FUNCTION_FV		3ah
	RT_VALUE, ;???		; LOTUS_FUNCTION_IF		3bh
	RT_VALUE,		; LOTUS_FUNCTION_DAY		3ch
	RT_VALUE,		; LOTUS_FUNCTION_MONTH		3dh
	RT_VALUE,		; LOTUS_FUNCTION_YEAR		3eh
	RT_VALUE,		; LOTUS_FUNCTION_ROUND		3fh
	RT_VALUE,		; LOTUS_FUNCTION_TIME		40h
	RT_VALUE,		; LOTUS_FUNCTION_HOUR		41h
	RT_VALUE,		; LOTUS_FUNCTION_MINUTE		42h
	RT_VALUE,		; LOTUS_FUNCTION_SECOND		43h
	RT_VALUE,		; LOTUS_FUNCTION_ISNUMBER	44h
	RT_VALUE,		; LOTUS_FUNCTION_ISSTRING	45h
	RT_VALUE,		; LOTUS_FUNCTION_LENGTH		46h
	RT_VALUE,		; LOTUS_FUNCTION_VALUE		47h
	RT_ERROR, ;???		; LOTUS_FUNCTION_FIXED		48h
	RT_TEXT,		; LOTUS_FUNCTION_MID		49h
	RT_TEXT,		; LOTUS_FUNCTION_CHR		4ah
	RT_TEXT,		; LOTUS_FUNCTION_ASCII		4bh
	RT_VALUE,		; LOTUS_FUNCTION_FIND		4ch
	RT_VALUE,		; LOTUS_FUNCTION_DATEVALUE	4dh
	RT_VALUE,		; LOTUS_FUNCTION_TIMEVALUE	4eh
	RT_ERROR, ;???		; LOTUS_FUNCTION_CELLPOINTER	4fh
	RT_VALUE,		; LOTUS_FUNCTION_SUM		50h
	RT_VALUE,		; LOTUS_FUNCTION_AVG		51h
	RT_VALUE,		; LOTUS_FUNCTION_CNT		52h
	RT_VALUE,		; LOTUS_FUNCTION_MIN		53h
	RT_VALUE,		; LOTUS_FUNCTION_MAX		54h
	RT_VALUE, ;???		; LOTUS_FUNCTION_VLOOKUP	55h
	RT_VALUE,		; LOTUS_FUNCTION_NPV		56h
	RT_VALUE,		; LOTUS_FUNCTION_VAR		57h
	RT_VALUE,		; LOTUS_FUNCTION_STD		58h
	RT_VALUE,		; LOTUS_FUNCTION_IRR		59h
	RT_VALUE,		; LOTUS_FUNCTION_HLOOKUP	5ah
	RT_ERROR,		; LOTUS_FUNCTION_DSUM		5bh	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DAVG		5ch	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DCNT		5dh	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DMIN		5eh	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DMAX		5fh	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DVAR		60h	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DSTD		61h	; dbase
	RT_VALUE,		; LOTUS_FUNCTION_INDEX		62h
	RT_VALUE,		; LOTUS_FUNCTION_COLS		63h
	RT_VALUE,		; LOTUS_FUNCTION_ROWS		64h
	RT_TEXT,		; LOTUS_FUNCTION_REPEAT		65h
	RT_TEXT,		; LOTUS_FUNCTION_UPPER		66h
	RT_TEXT,		; LOTUS_FUNCTION_LOWER		67h
	RT_TEXT,		; LOTUS_FUNCTION_LEFT		68h
	RT_TEXT,		; LOTUS_FUNCTION_RIGHT		69h
	RT_TEXT,		; LOTUS_FUNCTION_REPLACE	6ah
	RT_TEXT,		; LOTUS_FUNCTION_PROPER		6bh
	RT_ERROR,		; LOTUS_FUNCTION_CELL		6ch
	RT_TEXT,		; LOTUS_FUNCTION_TRIM		6dh
	RT_TEXT,		; LOTUS_FUNCTION_CLEAN		6eh
	RT_TEXT,		; LOTUS_FUNCTION_S		6fh
	RT_VALUE, 		; LOTUS_FUNCTION_V		70h N
	RT_TEXT, 		; LOTUS_FUNCTION_REQ		71h EXACT
	RT_ERROR, ;???		; LOTUS_FUNCTION_CALL		72h
	RT_ERROR, ;???		; LOTUS_FUNCTION_APP		73h Sym 1.0
	RT_VALUE,		; LOTUS_FUNCTION_RATE		74h
	RT_VALUE,		; LOTUS_FUNCTION_TERM		75h
	RT_VALUE,		; LOTUS_FUNCTION_CTERM		76h
	RT_VALUE,		; LOTUS_FUNCTION_SLN		77h
	RT_VALUE,		; LOTUS_FUNCTION_SOY		78h
	RT_VALUE,		; LOTUS_FUNCTION_DDB		79h
;1994-08-30(Tue)TOK ----------------
	RT_ERROR,	;7ah = @FULLP is Japanese only.
	RT_ERROR,	;7bh = @HALFP is Japanese only.
	RT_ERROR,	;dummy
	RT_ERROR,	;7dh = @SUUJI is Japanese only.
	RT_ERROR,	;7eh = @NENGO is Japanese only.
	RT_ERROR,	;7fh = @DECIMAL is Japanese only.
	RT_ERROR,	;80h = @HEX is Japanese only.
	RT_VALUE,	;81h = @DB is Japanese only.
;----------------
	RT_ERROR,		; LOTUS_FUNCTION_AAF_START	9ch
	RT_ERROR,		; LOTUS_FUNCTION_AAF_UNKNOWN	0ceh 123/2
	RT_ERROR		; LOTUS_FUNCTION_AAF_END	0ffh 123/2

else
LotusFunctionReturnTypeLookupTable	byte \
	RT_ERROR,		; LOTUS_FUNCTION_NA		1fh
	RT_ERROR,		; LOTUS_FUNCTION_ERR		20h
	RT_VALUE,		; LOTUS_FUNCTION_ABS		21h
	RT_VALUE,		; LOTUS_FUNCTION_INT		22h
	RT_VALUE,		; LOTUS_FUNCTION_SQRT		23h
	RT_VALUE,		; LOTUS_FUNCTION_LOG		24h
	RT_VALUE,		; LOTUS_FUNCTION_LN		25h
	RT_VALUE,		; LOTUS_FUNCTION_PI		26h
	RT_VALUE,		; LOTUS_FUNCTION_SIN		27h
	RT_VALUE,		; LOTUS_FUNCTION_COS		28h
	RT_VALUE,		; LOTUS_FUNCTION_TAN		29h
	RT_VALUE,		; LOTUS_FUNCTION_ATAN2		2ah
	RT_VALUE,		; LOTUS_FUNCTION_ATAN		2bh
	RT_VALUE,		; LOTUS_FUNCTION_ASIN		2ch
	RT_VALUE,		; LOTUS_FUNCTION_ACOS		2dh
	RT_VALUE,		; LOTUS_FUNCTION_EXP		2eh
	RT_VALUE,		; LOTUS_FUNCTION_MOD		2fh
	RT_VALUE, ;???		; LOTUS_FUNCTION_CHOOSE		30h
	RT_VALUE,		; LOTUS_FUNCTION_ISNA		31h
	RT_VALUE,		; LOTUS_FUNCTION_ISERR		32h
	RT_VALUE,		; LOTUS_FUNCTION_FALSE		33h
	RT_VALUE,		; LOTUS_FUNCTION_TRUE		34h
	RT_VALUE,		; LOTUS_FUNCTION_RAND		35h
	RT_VALUE,		; LOTUS_FUNCTION_DATE		36h
	RT_VALUE,		; LOTUS_FUNCTION_TODAY		37h
	RT_VALUE,		; LOTUS_FUNCTION_PMT		38h
	RT_VALUE,		; LOTUS_FUNCTION_PV		39h
	RT_VALUE,		; LOTUS_FUNCTION_FV		3ah
	RT_VALUE, ;???		; LOTUS_FUNCTION_IF		3bh
	RT_VALUE,		; LOTUS_FUNCTION_DAY		3ch
	RT_VALUE,		; LOTUS_FUNCTION_MONTH		3dh
	RT_VALUE,		; LOTUS_FUNCTION_YEAR		3eh
	RT_VALUE,		; LOTUS_FUNCTION_ROUND		3fh
	RT_VALUE,		; LOTUS_FUNCTION_TIME		40h
	RT_VALUE,		; LOTUS_FUNCTION_HOUR		41h
	RT_VALUE,		; LOTUS_FUNCTION_MINUTE		42h
	RT_VALUE,		; LOTUS_FUNCTION_SECOND		43h
	RT_VALUE,		; LOTUS_FUNCTION_ISNUMBER	44h
	RT_VALUE,		; LOTUS_FUNCTION_ISSTRING	45h
	RT_VALUE,		; LOTUS_FUNCTION_LENGTH		46h
	RT_VALUE,		; LOTUS_FUNCTION_VALUE		47h
	RT_ERROR, ;???		; LOTUS_FUNCTION_FIXED		48h
	RT_TEXT,		; LOTUS_FUNCTION_MID		49h
	RT_TEXT,		; LOTUS_FUNCTION_CHR		4ah
	RT_TEXT,		; LOTUS_FUNCTION_ASCII		4bh
	RT_VALUE,		; LOTUS_FUNCTION_FIND		4ch
	RT_VALUE,		; LOTUS_FUNCTION_DATEVALUE	4dh
	RT_VALUE,		; LOTUS_FUNCTION_TIMEVALUE	4eh
	RT_ERROR, ;???		; LOTUS_FUNCTION_CELLPOINTER	4fh
	RT_VALUE,		; LOTUS_FUNCTION_SUM		50h
	RT_VALUE,		; LOTUS_FUNCTION_AVG		51h
	RT_VALUE,		; LOTUS_FUNCTION_CNT		52h
	RT_VALUE,		; LOTUS_FUNCTION_MIN		53h
	RT_VALUE,		; LOTUS_FUNCTION_MAX		54h
	RT_VALUE, ;???		; LOTUS_FUNCTION_VLOOKUP	55h
	RT_VALUE,		; LOTUS_FUNCTION_NPV		56h
	RT_VALUE,		; LOTUS_FUNCTION_VAR		57h
	RT_VALUE,		; LOTUS_FUNCTION_STD		58h
	RT_VALUE,		; LOTUS_FUNCTION_IRR		59h
	RT_VALUE,		; LOTUS_FUNCTION_HLOOKUP	5ah
	RT_ERROR,		; LOTUS_FUNCTION_DSUM		5bh	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DAVG		5ch	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DCNT		5dh	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DMIN		5eh	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DMAX		5fh	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DVAR		60h	; dbase
	RT_ERROR,		; LOTUS_FUNCTION_DSTD		61h	; dbase
	RT_VALUE,		; LOTUS_FUNCTION_INDEX		62h
	RT_VALUE,		; LOTUS_FUNCTION_COLS		63h
	RT_VALUE,		; LOTUS_FUNCTION_ROWS		64h
	RT_TEXT,		; LOTUS_FUNCTION_REPEAT		65h
	RT_TEXT,		; LOTUS_FUNCTION_UPPER		66h
	RT_TEXT,		; LOTUS_FUNCTION_LOWER		67h
	RT_TEXT,		; LOTUS_FUNCTION_LEFT		68h
	RT_TEXT,		; LOTUS_FUNCTION_RIGHT		69h
	RT_TEXT,		; LOTUS_FUNCTION_REPLACE	6ah
	RT_TEXT,		; LOTUS_FUNCTION_PROPER		6bh
	RT_ERROR,		; LOTUS_FUNCTION_CELL		6ch
	RT_TEXT,		; LOTUS_FUNCTION_TRIM		6dh
	RT_TEXT,		; LOTUS_FUNCTION_CLEAN		6eh
	RT_TEXT,		; LOTUS_FUNCTION_S		6fh
	RT_VALUE, 		; LOTUS_FUNCTION_V		70h N
	RT_TEXT, 		; LOTUS_FUNCTION_REQ		71h EXACT
	RT_ERROR, ;???		; LOTUS_FUNCTION_CALL		72h
	RT_ERROR, ;???		; LOTUS_FUNCTION_APP		73h Sym 1.0
	RT_VALUE,		; LOTUS_FUNCTION_RATE		74h
	RT_VALUE,		; LOTUS_FUNCTION_TERM		75h
	RT_VALUE,		; LOTUS_FUNCTION_CTERM		76h
	RT_VALUE,		; LOTUS_FUNCTION_SLN		77h
	RT_VALUE,		; LOTUS_FUNCTION_SOY		78h
	RT_VALUE,		; LOTUS_FUNCTION_DDB		79h
	RT_ERROR,		; LOTUS_FUNCTION_AAF_START	9ch
	RT_ERROR,		; LOTUS_FUNCTION_AAF_UNKNOWN	0ceh 123/2
	RT_ERROR		; LOTUS_FUNCTION_AAF_END	0ffh 123/2
endif

ImportTranslateFunction	proc	near	uses	cx,si
	locals	local	ImportStackFrame
	ForceRef locals
	.enter	inherit near

	mov	al, PARSER_TOKEN_FUNCTION
	ImportStosb
	jc	exit
	lodsb					; al <- Lotus token

EC<	cmp	al, IMPORT_START_FUNCTIONS >
EC<	ERROR_B	IMPEX_EXPORTING_INVALID_DATA >
if DBCS_PCGEOS	;1994-08-30(Tue)TOK ----------------
	cmp	al, 7ch
	je	NextCheck
	cmp	al, 8dh
	jae	NextCheck
	jmp	short DoneCheck	;@function is assigned in Japanese 1-2-3.
NextCheck:
endif	;----------------
EC<	cmp	al, IMPORT_END_FUNCTIONS >
EC<	ERROR_A IMPEX_EXPORTING_INVALID_DATA >
if DBCS_PCGEOS	;1994-08-30(Tue)TOK ----------------
DoneCheck:
endif	;----------------

	clr	ah
	sub	ax, IMPORT_START_FUNCTIONS	; make ax 0 based
	mov	bx, ax
	mov	cl, cs:[LotusFunctionReturnTypeLookupTable][bx]
	shl	bx, 1
	mov	ax, cs:[ImportTranslateFunctionEquivTable][bx]
	cmp	ax, -1
	jne	doStore

	mov	ax, FUNCTION_ID_ERR		; map unknowns to ERR
	mov	cl, RT_ERROR

doStore:
	ImportStosw
	mov	al, cl
	jnc	exit
	mov	al, RT_ERROR

exit:
EC<	pushf				>
EC<	cmp	al, RT_VALUE >
EC<	ERROR_L	IMPEX_ASSERTION_FAILED >
EC<	cmp	al, RT_ERROR >
EC<	ERROR_G	IMPEX_ASSERTION_FAILED >
EC<	popf				>

	.leave
	ret
ImportTranslateFunction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportStoreErrFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	While traversing the parse tree, have reached the
		end of the output buffer.

CALLED BY:	INTERNAL
PASS:		es:di	- output stream
RETURN:		al	- ReturnType (RT_ERROR)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportStoreErrFunction		proc	near
	.enter

	mov	di, size CellFormula		; es:di <- start of formula

	mov	al, PARSER_TOKEN_FUNCTION
	stosb

	mov	ax, FUNCTION_ID_ERR		; map unknowns to ERR
	stosw

	mov	al, PARSER_TOKEN_CLOSE_FUNCTION
	stosb

	mov	al, RT_ERROR

	.leave
	ret
ImportStoreErrFunction		endp
