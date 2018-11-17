COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseEval.asm

AUTHOR:		John Wedgwood, Jan 16, 1991

ROUTINES:
	Name			Description
	----			-----------
GLBL	ParserEvalExpression		Evaluate a stream of parser tokens.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/16/91	Initial revision

DESCRIPTION:
	Evaluation routines.  ParserEvalPushString takes a string size.

	$Id: parseEval.asm,v 1.1 97/04/05 01:27:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EvalCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate a stream of parser tokens.

CALLED BY:	Global
PASS:		ds:si	= Pointer to parsed expression
		es:di	= Pointer to the base of a scratch buffer.
			  This buffer consists of two stacks. The argument
			  stack grows down from the top of the buffer and
			  the operator/function stack grows up from the
			  bottom of the buffer. When the two stacks collide
			  an error is reported.
		cx	= Size of scratch buffer
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set if there was a serious error
		al	= ParserScannerEvalError code
		es:bx	= Pointer to the result
		If we were generating dependencies then ss:bp.EP_depHandle
		  holds the block handle of the locked block which contains
		  the list of cells, ranges, names, and functions that the
		  expression depends on.
		If there was a "not so serious" error in evaluating, then the
		  evaluator argument stack will contain the error token.
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
	The operator/function stack is referenced with es:di. It grows up.
	The argument stack is referenced with es:bx. It grows down.

	It is easy to tell if there is no more scratch space. As soon as
	di >= bx, then there is no more space.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserEvalExpression	proc	far
	uses	cx, dx, di, si
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	mov	bx, ds						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	movdw	bxsi, ss:[bp].EP_common.CP_callback		>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
else
EC <	call	ECCheckPointer					>
EC <	call	ECCheckEvalParameters				>
endif		
EC <	call	ECCheckPointerESDI				>
EC <	cmp	cx, MINIMUM_STACK_SPACE		; enough bytes?	>
EC <	ERROR_B	EVAL_NOT_ENOUGH_STACK_SPACE			>

	call	FloatGetStackPointer	; ax <- fp-stack pointer
	mov	ss:[bp].EP_fpStack, ax	; Save the stack pointer

	mov	ss:[bp].EP_depHandle, 0	; No dependencies yet.
	
	;
	; Mark that there has been no error pushed yet.
	;
	and	ss:[bp].EP_flags, not mask EF_ERROR_PUSHED

	;
	; Init the OperatorStack.
	;
	mov	es:[di].OSE_type, ESOT_TOP_OF_STACK
	;
	; Init the ArgumentStack
	;
	mov	bx, di
	add	bx, cx			; bx <- top of argument stack.
					; Don't point past end of buffer
	sub	bx, size EvalStackArgumentType
	mov	es:[bx].ASE_type, ESAT_TOP_OF_STACK

	mov	ss:[bp].EP_nestedLevel, 0

evalLoop:
	;
	; ds:si	= Pointer to next parser-token
	; es:di	= Pointer to operator/function stack
	; es:bx	= Pointer to argument stack
	;
EC <	call	ECCheckPointer			>
EC <	call	ECCheckPointerESDI		>
EC <	call	ECCheckPointerESBX		>

	clr	ah			; Always want ah clear in this loop
	lodsb				; ax <- token

EC <	cmp	ax, ParserTokenType		>
EC <	ERROR_AE EVAL_ILLEGAL_PARSER_TOKEN	>

	push	bx			; Save arg ptr
	mov	bx, ax			; bx <- token
	shl	bx, 1			; Index into table of words
	mov	cx, cs:evalHandlers[bx]	; cx <- the handler routine
	pop	bx			; Restore arg ptr
	;
	; al	= The token
	; cx	= Handler for the token
	; ds:si	= Pointer to the parser-token data
	; es:di	= Pointer to the operator/function stack
	; es:bx	= Pointer to the argument stack
	;
	mov	dh, al			; Save token in dh

	push	cs			; The functions are far routines.
	call	cx			; Call the handler
	jc	quit			; Quit if error

	mov	al, dh			; Restore token from dh

	cmp	al, PARSER_TOKEN_END_OF_EXPRESSION
	jne	evalLoop		; Loop while not end of expression
	clc				; Signal: no error

EC <	push	ax						>
EC <	lahf				; Save flags		>

EC <	cmp	es:[di].OSE_type, ESOT_TOP_OF_STACK		>
EC <	ERROR_NZ EVAL_SUCCESSFUL_BUT_TOP_OF_STACK_NOT_FOUND	>
	;
	; There should only be a single argument on the stack
	;
EC <	push	bx			; Save the arg ptr	>
EC <	call	Pop1Arg			; Pop a single argument	>
EC <	cmp	es:[bx].ASE_type, ESAT_TOP_OF_STACK		>
EC <	ERROR_NZ EVAL_LEFT_TOO_MANY_ARGUMENTS			>
EC <	pop	bx			; Restore the arg ptr	>

EC <	sahf				; Restore flags		>
EC <	pop	ax						>
quit:
	;
	; We're done, unless the nesting level is non-zero.
	;
	jnc	noError			; Branch if no error
	call	RecoverFromError	; Handle error related stuff
noError:
	call	FixupFPStack		; Fixup the fp-stack
	.leave
	ret
ParserEvalExpression	endp

;
; This table lists handlers for each of the parser tokens. It depends on
; the order of definition of the ParserTokenType enums. All the routines
; should be in this code segment, and should be declared far.
;
evalHandlers	word	offset	cs:ParserEvalPushNumericConstant,
			offset	cs:HandleStringConstant,
			offset	cs:ParserEvalPushCellReference,
			offset	cs:EvalEndOfExpression,
			offset	cs:EvalOpenParen,
			offset	cs:EvalCloseParen,
			offset	cs:EvalName,
			offset	cs:EvalFunction,
			offset	cs:EvalCloseFunction,
			offset	cs:EvalArgEnd,
			offset	cs:EvalOperator


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalPushNumericConstant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a number constant on the argument stack

CALLED BY:	Global, ParserEvalExpression via evalHandlers
PASS:		ds:si	= Pointer to ParserTokenNumberData
		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code.
		ds:si	= Pointer past the ParserTokenNumberData
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Load the number into the co-processor stack
	Push a reference to that number on the argument stack

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserEvalPushNumericConstant	proc	far
	uses	cx, di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, ss:[bp].EP_common.CP_callback		>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

	clr	cx			; No additional space needed
	mov	al, mask ESAT_NUMBER
	call	ParserEvalPushArgument		; Make space on the argument stack
	jc	quit			; Quit if no space

	test	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
	jnz	quit			; branch if making dependencies
	;
	; We are really evaluating, push the number on the fp-stack.
	;
	call	FloatPushNumber		; Push the number on the stack
	clc				; Signal: no error
quit:
	lahf				; Save the error flag (carry)
	add	si, size ParserTokenNumberData
	sahf				; Restore the error flag (carry)
	.leave
	ret
ParserEvalPushNumericConstant	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalPushNumericConstantWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a word constant onto the argument stack

CALLED BY:	Global
PASS:		es:bx	= Pointer to the argument stack
		es:di	= Poiner to operator/function stack
		ss:bp	= Pointer to EvalParameters
		cx	= Word value to push
RETURN:		es:bx	= New argument stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserEvalPushNumericConstantWord	proc	far
	uses	cx, di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, ss:[bp].EP_common.CP_callback		>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

	push	cx			; Save word to push
	clr	cx			; No additional space needed
	mov	al, mask ESAT_NUMBER
	call	ParserEvalPushArgument		; Make space on the argument stack
	pop	cx			; Restore word to push

	jc	quit			; Quit if no space

	test	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
	jnz	quit			; branch if making dependencies
	;
	; We are really evaluating, push the number on the fp-stack.
	;
	mov	ax, cx			; ax <- number to push
	call	FloatWordToFloat	; Push the number on the stack
	clc				; Signal: no error
quit:
	.leave
	ret
ParserEvalPushNumericConstantWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleStringConstant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a string constant on the argument stack

CALLED BY:	ParserEvalExpression via evalHandlers
PASS:		ds:si	= Pointer to ParserTokenStringData
		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
		ds:si	= Pointer past the ParserTokenStringData
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	call ParserEvalPushStringConstant with cx = size.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/18/91	Initial version
	witt	11/16/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleStringConstant	proc	far
	uses	cx
	.enter
	mov	cx, ds:[si].PTSD_length	; cx <- length of the string
DBCS<	shl	cx, 1			; cx <- size of string		>
	add	si, 2			; ds:si <- ptr to the string
	call	ParserEvalPushStringConstant	; Push the string
	jc	quit			; Quit on error
	add	si, cx			; Else skip past the string data
	;
	; carry is always clear here (unless si wraps in which case we
	; are really screwed anyway.
	;
quit:
	.leave
	ret
HandleStringConstant	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalPushStringConstant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a string constant on the argument stack.

CALLED BY:	Global, HandleStringConstant
PASS:		ds:si	= Pointer to string data
		cx	= Size of the string (w/o NULL)
		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Copy the string onto the argument stack.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version
	witt	11/16/93	DBCS-ized; convert all callers for cx = size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserEvalPushStringConstant	proc	far
	uses	cx, di, si
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, ss:[bp].EP_common.CP_callback		>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>
DBCS< EC <	test	cx, 1		; odd size string?	>	>
DBCS< EC < 	ERROR_NZ ODDSIZED_DBCS_STRING	; crash burn	>	>

	push	cx			; save string size
SBCS< EC <	cmp	cx, MAX_STRING_LENGTH			>	>
DBCS< EC <	cmp	cx, MAX_STRING_LENGTH*(size wchar)	>	>
EC <	ERROR_A	PARSE_STRING_TOO_LONG					>
	LocalNextChar	escx		; cx <- +1 for C_NULL

	mov	al, mask ESAT_STRING
	call	ParserEvalPushArgument	; Make space on the argument stack
	pop	cx
	jc	quit			; Quit on error
	;
	; Space was allocated. Save the length of the string and then the
	; string data.
	;
DBCS<	shr	cx, 1			; cx <- string length		>
	mov	es:[bx].ASE_data.ESAD_string.ESD_length, cx
	lea	di, es:[bx].ASE_data	; es:di <- ptr to data
	add	di, size ESAD_string	; es:di <- ptr past length

EC <	cmp	cx, MAX_STRING_LENGTH					>
EC <	ERROR_A	PARSE_STRING_TOO_LONG					>
	LocalCopyNString		; Copy the string data
					; si is now set correctly
	;
	; NULL-terminate the string, too, since various functions
	; (unwisely) assumed this was the case.
	;
	clr	ax
	LocalPutChar esdi, ax		; NULL-terminate me jesus
	clc				; Signal: no error
quit:
	.leave
	ret
ParserEvalPushStringConstant	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalPushCellReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a cell reference on the argument stack

CALLED BY:	Global, ParserEvalExpression via evalHandlers
PASS:		ds:si	= Pointer to ParserTokenCellData
		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
		si	= Pointer past the ParserTokenCellData
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Push the absolute cell-reference onto the argument stack.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserEvalPushCellReference	proc	far
	uses	cx, dx, ds
	.enter
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>
	;
	; Allocate a range on the stack and then duplicate the passed cell
	; into it to get a range.
	;
	push	si			; Save ptr to passed data

	mov	dx, es			; Save op-stack pointer into dx:ax
	mov	ax, di

	sub	sp, size EvalRangeData	; Allocate space on the stack for range
	segmov	es, ss, di		; es:di <- ptr to range data
	mov	di, sp

	push	di			; Save pointer to range
	mov	cx, size CellReference	; Duplicate the cell twice
	push	si, cx			; Save source, size
	rep	movsb			; Copy the cell
	pop	si, cx			; Restore source, size

	rep	movsb			; Copy the cell again
	;
	; Now we have a range on the stack, we call ParserEvalPushRange to put it on the
	; argument stack.
	;	ss:bp	= Pointer to EvalParameters
	;	dx	= Segment address of argument and operator stack
	;	ax	= Offset to operator stack
	;	bx	= Offset to argument stack
	;	on-stack:
	;		Offset to range data
	;
	pop	si			; Restore offset to range
	segmov	ds, ss			; ds:si <- ptr to the source

	mov	es, dx			; Restore op-stack pointer
	mov	di, ax

	call	ParserEvalPushRange		; Push it, returning error
	
	lahf				; Save error flag (carry)
	add	sp, size EvalRangeData	; Restore the stack

	pop	si			; Restore pointer to cell data
	add	si, size CellReference	; Skip past it
	sahf				; Restore error flag (carry)

	.leave
	ret

ParserEvalPushCellReference	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate a function call

CALLED BY:	ParserEvalExpression via evalHandlers
PASS:		ds:si	= Pointer to ParserTokenFunctionData
		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
		ds:si	= Pointer past ParserTokenFunctionData
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Push the function on the OperatorStack.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalFunction	proc	far
	uses	dx
	.enter
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

	mov	dx, ds:[si].PTFD_functionID
	mov	al, ESOT_FUNCTION	; al <- operator
	call	PushOperator		; Push a function operator
	
	lahf				; Save error code (carry)
	add	si, size ParserTokenFunctionData
	sahf				; Restore error code (carry)
	.leave
	ret
EvalFunction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalEndOfExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate an end-of-expression

CALLED BY:	ParserEvalExpression via evalHandlers
PASS:		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
		dh	= The token that the evaluator should "believe" it
			  just handled.
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalEndOfExpression	proc	far
	uses	cx
	.enter
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>
	
	tst	ss:[bp].EP_nestedLevel		; Check for nested levels
	jz	finishEvalLoop			; Branch if none
	;
	; If there are nested levels we want to unlock the current one,
	; re-load the next one, then eval a close-paren.
	;
	call	UnwindOneNesting		; Unwind one level
	call	EvalCloseParen			; Close the current name
	mov	dh, PARSER_TOKEN_CLOSE_PAREN	; Fool the evaluator into
						;   thinking it just did a
						;   close-paren and not an
						;   end-of-expression
	jmp	quit

finishEvalLoop:
	cmp	es:[di].OSE_type, ESOT_TOP_OF_STACK
	;;; Carry clear if the 'equal' condition is met
	je	finishEval			; Quit if top of stack

	call	PopOperatorAndEval		; Evaluate operator
	jnc	finishEvalLoop			; Loop to check next operator
	;
	; We have an error if we get here.
	;
	jmp	quit				; Quit if error
finishEval:
	;
	; The result may be a single cell on the top of the stack. If it is
	; then we dereference it, unless we are leaving that last cell
	; as requested by the caller.
	;
	test	ss:[bp].EP_flags, mask EF_KEEP_LAST_CELL
	jnz	quit				; Wait if we want to keep it
	;
	; If we are making dependencies then we want to add a dependency for
	; this cell.
	;
	test	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
	jz	derefCell			; Branch if not making deps
	;
	; Add a dependency for this cell.
	;
	push	bx
	mov	cx, 1				; cx <- # of args on stack
	mov	al, es:[bx]			; al <- argument type
	inc	bx				; bx <- ptr to the data
	call	AddEntryToDependencyBlock	; add the dependency
	pop	bx
	jmp	quit

derefCell:
	;
	; Not keeping the last cell and not making dependencies... Dereference
	; the cell (if there is one).
	;
	call	DereferenceCell			; Deref cell, if there is one
	;;; Carry is set here if there is an error
quit:
	;
	; Carry is set correctly here.
	;
	.leave
	ret
EvalEndOfExpression	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalOpenParen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate an open-paren

CALLED BY:	ParserEvalExpression via evalHandlers
PASS:		es:di	= Pointer to the top of the operator/function stack
		es:bx	= Pointer to the top of the argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Push an open-paren on the OperatorStack

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalOpenParen	proc	far
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

	mov	al, ESOT_OPEN_PAREN	; al <- operator
	call	PushOperator		; Push a function operator
	;
	; There is no data associated with this operator, so the carry
	; and error-code from PushOperator() can be returned.
	;
	ret
EvalOpenParen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalCloseParen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate a close-paren

CALLED BY:	ParserEvalExpression via evalHandlers
PASS:		es:di	= Pointer to the top of the operator/function stack
		es:bx	= Pointer to the top of the argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Evaluate operators until an OpenParen reaches the top of the
	OperatorStack.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalCloseParen	proc	far
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

checkOpLoop:
	cmp	es:[di].OSE_type, ESOT_OPEN_PAREN
	je	popOpenParen			; Quit if found open-paren

	call	PopOperatorAndEval		; Evaluate operator
	jc	quit				; Quit on error
	jmp	checkOpLoop			; Else loop to keep looking

popOpenParen:
	;
	; Pop the open-paren off the stack.
	;
	call	PopOperator			; Remove the operator
quit:
	;
	; Carry is set correctly here.
	;
	ret
EvalCloseParen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a name in the token stream

CALLED BY:	ParserEvalExpression via evalHandlers
PASS:		es:di	= Pointer to the top of the operator/function stack
		es:bx	= Pointer to the top of the argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
		ds:si	= Pointer to the ParserTokenNameData
RETURN:		carry set on error
		al	= Error code
		ds:si	= Pointer to next token to read
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalName	proc	far	uses	cx	; (was two lines)
	.enter
	cmp	ss:[bp].EP_nestedLevel, EVAL_MAX_NESTED_LEVELS
	je	errorTooNested			; Branch if error
	;
	; Add the name to the dependency list (if we are adding dependencies)
	; We add the name only if the name is directly referenced in the
	; original formula. We can check this by checking the nesting
	; level... It will be zero if it is a direct reference.
	;
	test	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
	jz	noNameDependency
	tst	ss:[bp].EP_nestedLevel		; Only direct references
	jnz	noNameDependency		; Branch if not direct

	push	es, bx				; Save the arg ptr
	mov	al, ESAT_NAME			; al <- the token
	segmov	es, ds				; es:bx <- ptr to the name data
	mov	bx, si

	call	AddEntryToDependencyBlock	; Add the dependency
	pop	es, bx				; Restore the arg ptr

	jc	quit				; Quit on error
	;
	; If we are only doing names, then we can push any token we want and
	; quit. Otherwise we need to continue processing...
	;
	test	ss:[bp].EP_flags, mask EF_ONLY_NAMES
	jz	noNameDependency		; Branch if doing more than names

	add	si, size ParserTokenNameData	; Point to past the name
	;
	; Now we want to push something, anything at all. Since we have a label
	; that pushes an error, we branch there. Like I said, it doesn't really
	; matter where we go. It's not like we're really returning an error
	; here.
	;
	jmp	errorCircNameDependency

noNameDependency:
	;
	; Now save the current state on the nestedAddresses stack and
	; call back to the application to dereference the name.
	;
	mov	cx, ds:[si].PTND_name		; cx <- the name

	push	di				; Save opStack ptr
	mov	di, ss:[bp].EP_nestedLevel
	shl	di, 1				; dword sized structures
	shl	di, 1
	add	si, size ParserTokenNameData	; Set to past the name
	;
	; Save current pointer so we can get it back
	;
	mov	ss:[bp].EP_nestedAddresses[di].segment, ds
	mov	ss:[bp].EP_nestedAddresses[di].offset,  si
	
	call	CheckCircularNameRef		; Check for circ name reference
	pop	di				; Restore opStack ptr
	jc	errorCircNameDependency		; Branch if there's a problem
	;
	; Now call the callback to get the new pointer
	;
	mov	al, CT_LOCK_NAME		; al <- the reason
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[bp].CP_callback		; ds:si <- token data
endif
	jc	checkUndefined			; Branch on error
	inc	ss:[bp].EP_nestedLevel		; One more nested level
	call	EvalOpenParen			; Force an open-paren on the
						;    stack.
	;;; carry is set correctly here.
quit:
	.leave
	ret

errorTooNested:
	mov	al, PSEE_NESTING_TOO_DEEP
	stc					; Signal: abort processing
	jmp	quit				; Quit

checkUndefined:
	;
	; Check for the application returning that a name is undefined.
	;
	; In this case we actually just push an error on the stack and
	; pretend that we never actually saw this name...
	;
	cmp	al, PSEE_UNDEFINED_NAME
	jne	quit				; Quit if it's a different error
	
	clr	cx				; Don't pop anything
	call	PropogateError			; Push the error token
	jmp	quit

errorCircNameDependency:
	;
	; The names used by this cell contain a circular name dependency.
	;
	mov	al, PSEE_CIRC_NAME_REF		; Note circularity...
	clr	cx				; Don't pop anything
	call	PropogateError			; Generate the error token
	jmp	quit
EvalName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCircularNameRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a circular name reference.

CALLED BY:	EvalName
PASS:		ss:bp.di= Pointer to end of list of nested addresses
		ds	= Segment of the current address
		si	= Offset  of the current address
RETURN:		carry set if this position already exists
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckCircularNameRef	proc	near
	uses	di, ax
	.enter
	mov	ax, ds		; ax <- segment address to check
checkLoop:
	tst	di		; Check for no more to check (clears carry)
	jz	quit		; Quit if no more to check
	sub	di, size dword	; ss:bp.di <- ptr to entry to check

	cmp	ax, ss:[bp].EP_nestedAddresses[di].segment
	jne	checkLoop	; Branch if different
	cmp	si, ss:[bp].EP_nestedAddresses[di].offset
	jne	checkLoop	; Branch if different
	;
	; The entry already exists. Signal the caller.
	;
	stc			; Tell caller about circular name reference
quit:
	.leave
	ret
CheckCircularNameRef	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalPushRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Global, Push a range on the argument stack

CALLED BY:	Global, ParserEvalExpression via evalHandlers
PASS:		ds:si	= Pointer to EvalRangeData
		es:di	= Pointer to the top of the operator/function stack
		es:bx	= Pointer to the top of the argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Check to make sure the range is valid
	Push the range onto the argument stack.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserEvalPushRange	proc	far
	uses	cx, di, si
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, ss:[bp].EP_common.CP_callback		>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

	clr	cx			; No additional space needed
	mov	al, mask ESAT_RANGE	; al <- the type of the argument
	call	ParserEvalPushArgument		; Make space on the argument stack
	jc	quit			; Quit on error
	;
	; Space was allocated. Copy the range structure.
	;
	mov	cx, size EvalRangeData

	lea	di, es:[bx].ASE_data	; es:di <- destination

	push	di			; Save the pointer to the range
	rep	movsb			; Copy the range data
	pop	di			; Restore pointer to range
	;
	; Now adjust the rows and columns if they are relative references
	;
	call	AdjustForRelativeReference
	jc	replaceWithError	; Quit if error
	
	add	di, offset ERD_lastCell
	
	call	AdjustForRelativeReference
	jnc	quit			; Branch if no error

replaceWithError:
	;
	; There was something wrong with the range we pushed. Replace it
	; with an error of the appropriate type.
	;
	call	ReplaceArgumentWithError
quit:
	.leave
	ret
ParserEvalPushRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustForRelativeReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a row/column for relative references

CALLED BY:	EvalCellReference, EvalRange
PASS:		ss:bp	= Pointer to EvalParameters
		es:di	= Pointer to the cell reference
RETURN:		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Adjust the reference (if it is relative) by adding in the current
	cell.
	
	Always sets the flags which say that the reference is absolute before
	returning so that this routine can be called over and over on the
	same cell without screwing up.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustForRelativeReference	proc	near
	mov	ax, es:[di].CR_row
	and	ax, mask CRC_VALUE
	shl	ax, 1			; Sign extends ax by shifting the
	sar	ax, 1			; 15th bit into the high bit and then
					; shifting it back, duplicating the
					; high bit (that's what sar does).

	test	es:[di].CR_row, mask CRC_ABSOLUTE
	jnz	saveRow
	;
	; Relative reference, add in the current row
	;
	add	ax, ss:[bp].CP_row
saveRow:
	;
	; Check for row in bounds (>maxRow)
	;
	cmp	ax, ss:[bp].CP_maxRow
	ja	errorRowOutOfRange

	mov	es:[di].CR_row, ax
	or	es:[di].CR_row, mask CRC_ABSOLUTE

	mov	ax, es:[di].CR_column
	and	ax, mask CRC_VALUE

	shl	ax, 1			; Sign extends ax by shifting the
	sar	ax, 1			; 15th bit into the high bit and then
					; shifting it back, duplicating the
					; high bit (that's what sar does).

	test	es:[di].PTCD_cellRef.CR_column, mask CRC_ABSOLUTE
	jnz	saveColumn
	;
	; Relative reference, add in the current column
	;
	add	ax, ss:[bp].CP_column
saveColumn:
	;
	; Check for column in bounds (>maxColumn)
	;
	cmp	ax, ss:[bp].CP_maxColumn
	ja	errorColumnOutOfRange

	mov	es:[di].CR_column, ax
	or	es:[di].CR_column, mask CRC_ABSOLUTE

	clc				; Signal: no error
quit:
	ret

errorColumnOutOfRange:
	mov	al, PSEE_COLUMN_OUT_OF_RANGE
	stc
	jmp	quit

errorRowOutOfRange:
	mov	al, PSEE_ROW_OUT_OF_RANGE
	stc
	jmp	quit
AdjustForRelativeReference	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalCloseFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate a close-function

CALLED BY:	ParserEvalExpression via evalHandlers
PASS:		es:di	= Pointer to the top of the operator/function stack
		es:bx	= Pointer to the top of the argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Evaluate the function on the OperatorStack

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalCloseFunction	proc	far
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

	call	PopOperatorAndEval		; Evaluate the function
	ret
EvalCloseFunction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalArgEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate an arg-end

CALLED BY:	ParserEvalExpression via evalHandlers
PASS:		es:di	= Pointer to the top of the operator/function stack
		es:bx	= Pointer to the top of the argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Evaluate operators on the OperatorStack until a function is at the
	top of the stack.

	Increment the number of arguments being passed to the function.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalArgEnd	proc	far
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

	call	DereferenceCell			; Deref cell, if there is one
	jc	quit				; quit on error

checkOpLoop:
	cmp	es:[di].OSE_type, ESOT_FUNCTION
	;;; Carry clear if the 'equal' condition is met
	je	incArgCount			; Done if reached a function

	call	PopOperatorAndEval		; Evaluate operator
	jc	quit				; Quit if error
	jmp	checkOpLoop			; Loop to check next operator

incArgCount:
	;
	; Increment the count of the number of arguments passed to the function
	;
	inc	es:[di].OSE_data.ESOD_function.EFD_nArgs
	clc					; Signal: no error
quit:
	ret
EvalArgEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalOperator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate an operator

CALLED BY:	ParserEvalExpression via evalHandlers
PASS:		ds:si	= Pointer to ParserTokenOperatorData
		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to the top of the argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
		ds:si	= Pointer past the ParserTokenOperatorData
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	If the precedence of this operator is less than the precedence of
	the top of the operator stack then eval top of OperatorStack
	until an operator of lower precedence rises to the top
	
	Push operator on OperatorStack.
	
	The precedence of the operator is the value of the operator-id.
	The lower the number, the higher the precedence.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalOperator	proc	far
	uses	dx
	.enter
EC <	call	ECCheckPointer		>
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

checkOpLoop:
	cmp	es:[di].OSE_type, ESOT_OPERATOR
	jne	pushOperator			; Branch if not operator
	;
	; special case to allow something like ABS(--45).  You'll have
	; tokens like: (ABS func) (NEG op) (NEG op) (45).  The two NEG ops
	; have the same precedence, so the first NEG op will attempt to
	; get an argument.  Unfortunately, there isn't any. - brianc 9/2/94
	;
	cmp	es:[di].OSE_data.ESOD_operator.EOD_opType, OP_NEGATION
	jne	notNegNeg
	cmp	ds:[si].PTOD_operatorID, OP_NEGATION
	je	pushOperator			; push it
notNegNeg:
	;
	; The top of the OperatorStack is an operator (not a function
	; or an open-paren).
	; Check to see if the current operator has a higher (or same)
	; precedence than the one on the operator stack.
	;
	push	ds, bx				; Need these later
	clr	bh
	mov	bl, ds:[si].PTOD_operatorID	; bx <- current operator

NOFXIP< segmov	ds, dgroup, dx			; ds <- seg addr of table >
FXIP <	mov	dx, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
FXIP <	mov	bx, dx							>
	mov	dl, ds:opPrecedenceTable[bx]	; dl <- current precedence

	mov	bl, es:[di].OSE_data.ESOD_operator.EOD_opType
	mov	dh, ds:opPrecedenceTable[bx]	; dh <- other precedence
	pop	ds, bx				; Need these for PushOperator
	;
	; dl = precedence of the operator we are looking at
	; dh = precedence of the operator on the stack
	;
	cmp	dl, dh				; Compare current vs. on stack
	ja	pushOperator			; Branch if current is higher
						;   precedence
	;
	; The operator on the stack is of a higher or equal precedence. We
	; want to evaluate operators on the stack until the top item is no
	; longer an operator, or is no longer an operator of higher or equal
	; precedence.
	;
	call	PopOperatorAndEval		; Evaluate operator
	jc	quit				; Quit if error
	jmp	checkOpLoop			; Loop to check next operator

pushOperator:
	;
	; Push the current operator on the OperatorStack.
	;
	mov	dl, ds:[si].PTOD_operatorID	; dl <- operator ID
	mov	al, ESOT_OPERATOR		; al <- type of operator
	call	PushOperator			; Push the operator
	
quit:
CheckHack <(size ParserTokenOperatorData) eq 1>
	inc	si				; si <- skip op, preserve carry

	.leave
	ret
EvalOperator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalPushArgument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push an argument onto the ArgumentStack

CALLED BY:	Utility
PASS:		es:bx	= Pointer to the top of the argument stack
		al	= Type of the item (EvalArgumentType)
		cx	= Additional size to allocate beyond that which
			  would normally be assumed for this item.
		es:di	= Pointer to the OperatorStack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		es:bx	= New top of the argument stack. (Points to the
			  allocated item).
		carry set on error
		    al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserEvalPushArgument	proc	far
	uses	si, cx, dx
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, ss:[bp].EP_common.CP_callback		>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

EC <	cmp	al, EvalStackArgumentType	>
EC <	ERROR_AE EVAL_BAD_ARGUMENT_TYPE		>

	;
	; Check for pushing an error.
	;
	cmp	al, mask ESAT_ERROR	; Check for pushing an error
	jne	notError		; Branch if not an error
	or	ss:[bp].EP_flags, mask EF_ERROR_PUSHED
notError:

	mov	dl, al			; Save type of item

	call	DereferenceCell		; Deref cell, if there is one
	jc	quit			; Quit on error
	
	mov	al, dl			; Restore type of item
	;
	; Add the size of the necessary structure to the "extra space" value
	; that was passed in in cx. The table of sizes to use is in the code
	; segment and depends on the order of definition of the
	; EvalArgumentType enum.
	;
	call	GetArgumentSize		; si <- size of the arguments
	add	cx, si			; Add in the size
	inc	cx			; One byte for the type too

	sub	bx, cx			; Adjust the stack pointer

	call	CheckStackPointers	; Check for collision of pointers
	jc	quitRestoreStack	; Quit if error
	;
	; OK... There is space.
	;
	mov	es:[bx].ASE_type, al	; Save the type of the argument.
	clc				; Signal: no error
quit:
	.leave
	ret

quitRestoreStack:
	add	bx, cx			; Restore stack pointer
	stc				; Signal the error again
	jmp	quit

ParserEvalPushArgument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetArgumentSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the size of an argument.

CALLED BY:	ParserEvalPushArgument
PASS:		al	= EvalStackArgumentType
RETURN:		si	= Size of the argument data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetArgumentSize	proc	near
	mov	si, size EvalErrorData	; Size for an error type
	test	al, mask ESAT_ERROR
	jnz	quit			; Branch if error
	
	mov	si, size EvalRangeData	; Size for a range
	test	al, mask ESAT_RANGE
	jnz	quit			; Branch if range

	mov	si, size EvalStringData	; Size for a string
	test	al, mask ESAT_STRING
	jnz	quit			; Branch if string

	clr	si			; Size for a number
	test	al, mask ESAT_NUMBER
	jnz	quit			; Branch if number

	ERROR	ILLEGAL_ARGUMENT_TO_GET_ARG_SIZE
quit:
	ret
GetArgumentSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushOperator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push an operator on the operator stack

CALLED BY:	Utility
PASS:		es:di	= Top of OperatorStack
		es:bx	= Argument stack
		al	= Operator type (EvalOperatorType)
		For different types we have different data:
			ESOT_OPERATOR	-	dl = OperatorType
			ESOT_FUNCTION	-	dx = Function ID
			ESOT_OPEN_PAREN	-	no data
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		es:di	= New top of OperatorStack.
		carry set on error
		    al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PushOperator	proc	near
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

EC <	cmp	al, EvalStackOperatorType	>
EC <	ERROR_AE EVAL_BAD_OPERATOR_TYPE		>
	;
	; Adjust the stack pointer.
	;
	add	di, size OperatorStackElement
	call	CheckStackPointers	; Make sure stacks are OK.
	jc	quitRestoreStack	; Quit on error

	mov	es:[di].OSE_type, al	; Save the type of the operator

	cmp	al, ESOT_OPEN_PAREN	; Check for open-paren
	je	quit			; Branch if open-paren, carry is clear

	cmp	al, ESOT_OPERATOR	; Check for operator
	jne	isFunction		; Must be a function...
	;;; carry is clear here because the "equal" condition was met
	mov	es:[di].OSE_data.ESOD_operator.EOD_opType, dl
	jmp	quit			; Quit

isFunction:
EC <	cmp	al, ESOT_FUNCTION	; Check for function	>
EC <	ERROR_NZ EVAL_UNEXPECTED_OPERATOR_TYPE			>
	
	mov	es:[di].OSE_data.ESOD_function.EFD_functionID, dx
	mov	es:[di].OSE_data.ESOD_function.EFD_nArgs, 0
	clc				; Signal: no error
quit:
	ret

quitRestoreStack:
	sub	di, size OperatorStackElement	; Restore stack pointer
	stc				; Signal the error again
	jmp	quit

PushOperator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckStackPointers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to make sure that the argument and operator stacks
		haven't collided

CALLED BY:	ParserEvalPushArgument, PushOperator
PASS:		es:di	= Pointer to top of OperatorStack
		es:bx	= Pointer to top of ArgumentStack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		    al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckStackPointers	proc	near
	uses	cx
	.enter
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>
	;
	; Check for a possible conflict of stack pointers.
	;
	mov	cx, bx
	sub	cx, di			; cx <- distance between pointers
	jc	outOfStackError		; Quit if already past
	cmp	cx, size OperatorStackElement
	jbe	outOfStackError		; Quit if no space for operator
					;   which is below us
quit:
	.leave
	ret

outOfStackError:
	mov	al, PSEE_OUT_OF_STACK_SPACE
	stc				; Signal: error
	jmp	quit			; Branch to quit

CheckStackPointers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PopOperatorAndEval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop an operator off the OperatorStack and evaluate it.

CALLED BY:	
PASS:		ds:si	= Pointer to the token stream
		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
		es:bx	= Pointer to new top of argument stack
		es:di	= Pointer to new top of operator stack.
		ds:si	= Pointer to the token stream.
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	type = The type of the operator at the top of the stack.
	if type == OPERATOR then
	    Call operator handler
	else if type == FUNCTION then
	    if internal function then
	        Call function handler
	    else
	        Callback to application
	    endif
	endif
	opStackPtr -= size OperatorStackElement
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PopOperatorAndEval	proc	near
	uses	si, cx, dx
	.enter
EC <	cmp	es:[di].OSE_type, ESOT_TOP_OF_STACK		>
EC <	ERROR_Z	EVAL_CANT_POP_AND_EVAL_TOP_OF_STACK		>

EC <	cmp	es:[di].OSE_type, ESOT_OPEN_PAREN		>
EC <	ERROR_Z EVAL_OPEN_PAREN_SHOULD_NOT_BE_ON_OPERATOR_STACK	>

	call	DereferenceCell		; Deref the cell if we need to
	jc	quit			;branch if error
	;
	; Check for creating dependencies rather than evaluating.
	;
	test	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
	jnz	makeDependencies	; Branch if making dependencies
	;
	; Save current stack depth 
	;
	call	FloatDepth		; ax <- current FPStack size
	push	ax		
	;
	; Not making dependencies, check for the type of the operator and
	; handle it appropriately.
	;
	cmp	es:[di].OSE_type, ESOT_FUNCTION
	jne	evalOperator
	;
	; Get the number of numeric arguments on the FPStack for this function
	; 
	mov	cx, es:[di].OSE_data.ESOD_function.EFD_nArgs
	call	GetNumberOfNumericArgs	; dx <- # numeric args
	push	dx			; original # args on FPStack
	;
	; Evaluate an internally defined function
	;
	mov	si, es:[di].OSE_data.ESOD_function.EFD_functionID
	cmp	si, FUNCTION_ID_FIRST_EXTERNAL_FUNCTION
	jae	external		; Branch if external function

	;
	; Function is internally defined
	;
	call	cs:functionHandlers[si]	; Call function handler
	jmp	checkErrorPopOperator

external:
	;
	; Evaluate an externally defined function
	;
	mov	al, CT_EVAL_FUNCTION	; Callback for a function
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[bp].CP_callback	; Call the application
endif
	jmp	checkErrorPopOperator

evalOperator:
	;
	; Evaluate an operator
	;
EC <	cmp	es:[di].OSE_type, ESOT_OPERATOR			>
EC <	ERROR_NE EVAL_TOP_OF_OPSTACK_NOT_OPERATOR_OR_FUNCTION	>
	
	clr	ah			; ax <- operator type
	mov	al, es:[di].OSE_data.ESOD_operator.EOD_opType
	shl	ax, 1			; ax <- index into word table
	mov	si, ax			; si <- index
	call	cs:operatorHandlers[si]	; Call the function handler
	push	dx			; dx <- # of numeric args 

checkErrorPopOperator:
	pop	si			; si <- # numeric args that were passed
	pop	cx			; cx <- previous FPStack depth
	jc	quit			; Quit on really bad error

	;
	; If evaluating the function or operator produced an
	; error, fixup the FPStack before continuing
	;
	test	es:[bx].ASE_type, mask ESAT_ERROR
	jz	noError
	call	FunctionErrorFixupFPStack

noError:
	call	PopOperator		; Remove the operator

	; Carry is set correctly
quit:
	.leave
	ret

;-----------------------------------------------------------------------------
makeDependencies:
	;
	; Make dependencies by calling back for each argument to the operator
	; or function.
	;
	mov	ax, offset cs:FuncArgDependencies

	cmp	es:[di].OSE_type, ESOT_FUNCTION
	je	dependFuncArgs
	;
	; Well... Assume that it's an operator.
	;
EC <	cmp	es:[di].OSE_type, ESOT_OPERATOR			>
EC <	ERROR_NE EVAL_TOP_OF_OPSTACK_NOT_OPERATOR_OR_FUNCTION	>

	mov	ax, offset cs:OpArgDependencies
dependFuncArgs:
	call	ax			; Call the appropriate routine
	jc	quit
	jmp	noError

PopOperatorAndEval	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FunctionErrorFixupFPStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup the FPstack after a function error.

CALLED BY:	PopOperatorAndEval
PASS:		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
		cx = number items on FPStack before function was evaluated.
		si = number of numeric arguments passed to the function.

DESTROYED:	nothing
RETURN:		FPStack fixed up.
DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FunctionErrorFixupFPStack		proc	near
	uses	ax
	.enter

	call	FloatDepth	; ax <- # items on stack
	sub	cx, si		; cx <- depth we want the stack to be
	sub	ax, cx		; ax <- excess number of elements on stack
EC<	ERROR_S	FUNCTION_BAD_FP_STACK_DEPTH				>
	jz	done
	mov	cx, ax

dropLoop:
	call	FloatDrop
	loop	dropLoop
	
done:
	.leave
	ret
FunctionErrorFixupFPStack		endp

;
; A list of handlers for the functions.
; Make sure that the list of function handlers corresponds to the order in
; which the function id's are defined.
;
if PZ_PCGEOS
functionHandlers	word	offset cs:FunctionAbs,
				offset cs:FunctionACos,
				offset cs:FunctionACosh,
				offset cs:FunctionAnd,
				offset cs:FunctionASin,
				offset cs:FunctionASinh,
				offset cs:FunctionATan,
				offset cs:FunctionATan2,
				offset cs:FunctionATanh,
				offset cs:FunctionAvg,
				offset cs:FunctionChar,
				offset cs:FunctionChoose,
				offset cs:FunctionClean,
				offset cs:FunctionCode,
				offset cs:FunctionCols,
				offset cs:FunctionCos,
				offset cs:FunctionCosh,
				offset cs:FunctionCount,
				offset cs:FunctionCTerm,
				offset cs:FunctionDate,
				offset cs:FunctionDateValue,
				offset cs:FunctionDay,
				offset cs:FunctionDDB,
				offset cs:FunctionErr,
				offset cs:FunctionExact,
				offset cs:FunctionExp,
				offset cs:FunctionFact,
				offset cs:FunctionFalse,
				offset cs:FunctionFind,
				offset cs:FunctionFV,
				offset cs:FunctionHLookup,
				offset cs:FunctionHour,
				offset cs:FunctionIf,
				offset cs:FunctionIndex,
				offset cs:FunctionInt,
				offset cs:FunctionIRR,
				offset cs:FunctionIsErr,
				offset cs:FunctionIsNumber,
				offset cs:FunctionIsString,
				offset cs:FunctionLeft,
				offset cs:FunctionLength,
				offset cs:FunctionLn,
				offset cs:FunctionLog,
				offset cs:FunctionLower,
				offset cs:FunctionMax,
				offset cs:FunctionMid,
				offset cs:FunctionMin,
				offset cs:FunctionMinute,
				offset cs:FunctionMod,
				offset cs:FunctionMonth,
				offset cs:FunctionN,
				offset cs:FunctionNA,
				offset cs:FunctionNow,
				offset cs:FunctionNPV,
				offset cs:FunctionOr,
				offset cs:FunctionPi,
				offset cs:FunctionPMT,
				offset cs:FunctionProduct,
				offset cs:FunctionProper,
				offset cs:FunctionPV,
				offset cs:FunctionRandomN,
				offset cs:FunctionRandom,
				offset cs:FunctionRate,
				offset cs:FunctionRepeat,
				offset cs:FunctionReplace,
				offset cs:FunctionRight,
				offset cs:FunctionRound,
				offset cs:FunctionRows,
				offset cs:FunctionSecond,
				offset cs:FunctionSin,
				offset cs:FunctionSinh,
				offset cs:FunctionSLN,
				offset cs:FunctionSqrt,
				offset cs:FunctionStd,
				offset cs:FunctionStdP,
				offset cs:FunctionString,
				offset cs:FunctionSum,
				offset cs:FunctionSYD,
				offset cs:FunctionTan,
				offset cs:FunctionTanh,
				offset cs:FunctionTerm,
				offset cs:FunctionTime,
				offset cs:FunctionTimeValue,
				offset cs:FunctionToday,
				offset cs:FunctionTrim,
				offset cs:FunctionTrue,
				offset cs:FunctionTrunc,
				offset cs:FunctionUpper,
				offset cs:FunctionValue,
				offset cs:FunctionVar,
				offset cs:FunctionVarP,
				offset cs:FunctionVLookup,
				offset cs:FunctionWeekday,
				offset cs:FunctionYear,
				offset cs:FunctionFilename,
				offset cs:FunctionPage,
				offset cs:FunctionPages,
				offset cs:FunctionDegrees,
				offset cs:FunctionRadians,
				offset cs:FunctionDB		; Pizza
else
functionHandlers	word	offset cs:FunctionAbs,		; Standard
				offset cs:FunctionACos,
				offset cs:FunctionACosh,
				offset cs:FunctionAnd,
				offset cs:FunctionASin,
				offset cs:FunctionASinh,
				offset cs:FunctionATan,
				offset cs:FunctionATan2,
				offset cs:FunctionATanh,
				offset cs:FunctionAvg,
				offset cs:FunctionChar,
				offset cs:FunctionChoose,
				offset cs:FunctionClean,
				offset cs:FunctionCode,
				offset cs:FunctionCols,
				offset cs:FunctionCos,
				offset cs:FunctionCosh,
				offset cs:FunctionCount,
				offset cs:FunctionCTerm,
				offset cs:FunctionDate,
				offset cs:FunctionDateValue,
				offset cs:FunctionDay,
				offset cs:FunctionDDB,
				offset cs:FunctionErr,
				offset cs:FunctionExact,
				offset cs:FunctionExp,
				offset cs:FunctionFact,
				offset cs:FunctionFalse,
				offset cs:FunctionFind,
				offset cs:FunctionFV,
				offset cs:FunctionHLookup,
				offset cs:FunctionHour,
				offset cs:FunctionIf,
				offset cs:FunctionIndex,
				offset cs:FunctionInt,
				offset cs:FunctionIRR,
				offset cs:FunctionIsErr,
				offset cs:FunctionIsNumber,
				offset cs:FunctionIsString,
				offset cs:FunctionLeft,
				offset cs:FunctionLength,
				offset cs:FunctionLn,
				offset cs:FunctionLog,
				offset cs:FunctionLower,
				offset cs:FunctionMax,
				offset cs:FunctionMid,
				offset cs:FunctionMin,
				offset cs:FunctionMinute,
				offset cs:FunctionMod,
				offset cs:FunctionMonth,
				offset cs:FunctionN,
				offset cs:FunctionNA,
				offset cs:FunctionNow,
				offset cs:FunctionNPV,
				offset cs:FunctionOr,
				offset cs:FunctionPi,
				offset cs:FunctionPMT,
				offset cs:FunctionProduct,
				offset cs:FunctionProper,
				offset cs:FunctionPV,
				offset cs:FunctionRandomN,
				offset cs:FunctionRandom,
				offset cs:FunctionRate,
				offset cs:FunctionRepeat,
				offset cs:FunctionReplace,
				offset cs:FunctionRight,
				offset cs:FunctionRound,
				offset cs:FunctionRows,
				offset cs:FunctionSecond,
				offset cs:FunctionSin,
				offset cs:FunctionSinh,
				offset cs:FunctionSLN,
				offset cs:FunctionSqrt,
				offset cs:FunctionStd,
				offset cs:FunctionStdP,
				offset cs:FunctionString,
				offset cs:FunctionSum,
				offset cs:FunctionSYD,
				offset cs:FunctionTan,
				offset cs:FunctionTanh,
				offset cs:FunctionTerm,
				offset cs:FunctionTime,
				offset cs:FunctionTimeValue,
				offset cs:FunctionToday,
				offset cs:FunctionTrim,
				offset cs:FunctionTrue,
				offset cs:FunctionTrunc,
				offset cs:FunctionUpper,
				offset cs:FunctionValue,
				offset cs:FunctionVar,
				offset cs:FunctionVarP,
				offset cs:FunctionVLookup,
				offset cs:FunctionWeekday,
				offset cs:FunctionYear,
				offset cs:FunctionFilename,
				offset cs:FunctionPage,
				offset cs:FunctionPages,
				offset cs:FunctionDegrees,
				offset cs:FunctionRadians	; Standard
endif
CheckHack <(length functionHandlers) eq (length funcTable)>
;
; A list of handlers for operators.
;
operatorHandlers	word	offset cs:OpRangeSeparator,
				offset cs:OpNegation,
				offset cs:OpPercent,
				offset cs:OpExponentiation,
				offset cs:OpMultiplication,
				offset cs:OpDivision,
				offset cs:OpModulo,
				offset cs:OpAddition,
				offset cs:OpSubtraction,
				offset cs:OpEqual,
				offset cs:OpNotEqual,
				offset cs:OpLessThan,
				offset cs:OpGreaterThan,
				offset cs:OpLessThanOrEqual,
				offset cs:OpGreaterThanOrEqual,
				offset cs:OpStringConcat,
				offset cs:OpParserRangeIntersection,
				offset cs:OpNotEqual,
				offset cs:OpDivision,
				offset cs:OpLessThanOrEqual,
				offset cs:OpGreaterThanOrEqual
				


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalPopNArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop a number of arguments off the argument stack.

CALLED BY:	Global
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
		cx	= Number of arguments to pop off.
RETURN:		es:bx	= Pointer to new top of argument stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		It is important to note that this routine does not perform
		any sort of destructive acts to the ArgumentStack.
		
		It only changes the stack pointer.
		
		There is code that depends on the only effect of this
		routine being to change the stack pointer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version
	witt	11/16/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserEvalPopNArgs	proc	far
	uses	ax, cx, dx, di
	.enter
	jcxz	quit			; Quit if no arguments to pop
popLoop:
	;
	; Pop a single argument off the stack.
	;
	clr	ah
	mov	al, es:[bx].ASE_type	; ax <- argument type
	;
	; Check for popping top of stack item.
	;
EC <	cmp	al, ESAT_TOP_OF_STACK			>
EC <	ERROR_Z	EVAL_CANT_POP_ARGUMENT_TOP_OF_STACK	>

	push	si
	call	GetArgumentSize		; si <- size of the argument
	mov	dx, si			; dx <- size of the argument
	pop	si

	inc	dx			; One byte for the type
	
	test	al, mask ESAT_STRING
	jz	doPop			; Branch if not string constant
	;
	; For string constants we need to add the string length to get the
	; true size of the argument, and also include the NULL
	;
if DBCS_PCGEOS
	mov	ax, es:[bx].ASE_data.ESAD_string.ESD_length
	inc	ax			; +1 for NULL
	shl	ax, 1			; ax <- string size
	add	dx, ax
else
	add	dx, es:[bx].ASE_data.ESAD_string.ESD_length
	inc	dx			; +1 for NULL
endif
doPop:
	;
	; dx = amount to add to argStackPtr
	;
	add	bx, dx			; Update the argument stack pointer
	loop	popLoop			; Loop to pop next argument
quit:
	.leave
	ret
ParserEvalPopNArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PopOperator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an operator from the OperatorStack

CALLED BY:	PopOperatorAndEval, EvalCloseParen, EvalCloseFunction
PASS:		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
		es:bx	= Pointer to new top of argument stack
		es:di	= Pointer to new top of operator stack.
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PopOperator	proc	near
EC <	call	ECCheckPointerESDI	>
EC <	call	ECCheckPointerESBX	>

EC <	cmp	es:[di].OSE_type, ESOT_TOP_OF_STACK	>
EC <	ERROR_Z	EVAL_CANT_POP_OPERATOR_TOP_OF_STACK	>
	;
	; Adjust the stack pointer.
	;
	sub	di, size OperatorStackElement
	clc				; Signal: no error
	ret
PopOperator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalForeachArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback once for each argument

CALLED BY:	Internal and External functions
PASS:		es:bx	= Pointer to ArgumentStack
		cx	= # of arguments
		ss:bp	= Pointer to EvalParameters structure on the stack
		ax:si	= Pointer to callback routine
RETURN:		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Callback should be defined as...
		Pass:	es:bx	= Pointer to an argument on the stack
			cx	= Argument number (numbered from 0)
		Return:	carry set on error
				al = error code
		Destroyed: ax

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FA_vars	struct
    FAV_callback	dword
FA_vars	ends

ParserEvalForeachArg	proc	far
	uses	bx, cx, dx, di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ax						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, ss:[bp].EP_common.CP_callback		>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	di, bp				; Save frame pointer

	sub	sp, size FA_vars		; Make a stack frame
	mov	bp, sp				; bp <- frame ptr
	
	mov	ss:[bp].FAV_callback.segment,ax	; Save callback segment
	mov	ss:[bp].FAV_callback.offset, si	; Save callback offset

	xchg	di, bp				; ss:di <- ptr to our frame
						; ss:bp <- Passed frame

	mov	dx, cx				; dx <- # of arguments
	clr	cx				; Current argument number
argLoop:
	;
	; es:bx	= Pointer to arguments
	; cx	= Current argument
	; dx	= # of arguments
	; ss:bp	= Pointer to EvalParameters
	; ss:di	= Pointer to FAV_frame
	;
	tst	dx				; Clears the carry
	jz	quit				; Quit if no arguments
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[di].FAV_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[di].FAV_callback		; Call the callback
endif
	jc	quit				; Quit on error

	dec	dx				; One less argument
	jz	quit				; Quit if no more
	;
	; More arguments, pop the current one off.
	;
	push	cx				; Save current arg#
	mov	cx, 1				; Pop one argument please
	call	ParserEvalPopNArgs
	pop	cx				; Restore current arg#

	inc	cx				; Next argument number
	jmp	argLoop				; Branch to handle it.
quit:
	lahf					; Save carry (error) flag
	add	sp, size FA_vars		; Restore stack frame
	sahf					; Restore carry (error) flag
	.leave
	ret
ParserEvalForeachArg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecoverFromError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do any error-recovery necessary

CALLED BY:	ParserEvalExpression
PASS:		ss:bp	= Pointer to EvalParameters
RETURN:		ds	= segment address we started with
		carry set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Unwind any nested expressions we might be evaluating. Also free
	the dependency block handle if one exists.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecoverFromError	proc	near
	uses	bx, ds, si
	.enter
	clr	bx			; bx <- dependency block handle
					; Zero dependency block handle
	xchg	bx, ss:[bp].EP_depHandle
	tst	bx			; Check for no dependencies
	jz	keepDepBlock		; Branch if none

	call	MemUnlock		; Unlock it...
	call	MemFree			; Then free it
keepDepBlock:
	;
	; Unlock the nested locked names.
	;
unlockLoop:
	tst	ss:[bp].EP_nestedLevel	; Check for no more to do
	jz	done			; Quit if no more
	call	UnwindOneNesting	; Unwind a single level
	jmp	unlockLoop		; Loop to do the next one
done:
	stc				; Signal: error
	.leave
	ret
RecoverFromError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnwindOneNesting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	UnwindNesting
PASS:		ss:bp	= Pointer to EvalParameters
		ds:si	= Pointer to the current expression
RETURN:		ds:si	= Pointer that was saved for a given nesting level
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnwindOneNesting	proc	near
	uses	ax, di
	.enter
	mov	al, CT_UNLOCK

if FULL_EXECUTE_IN_PLACE
	push	bx
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	movdw	bxax, ss:[bp].CP_callback	; Call the application
	call	ProcCallFixedOrMovable
	pop	bx
else
	call	ss:[bp].CP_callback		; Have application unlock block
endif

	dec	ss:[bp].EP_nestedLevel		; One less nesting level
	;
	; Restore the segment/ and loop
	;
	mov	di, ss:[bp].EP_nestedLevel	; di <- index into the table
	shl	di, 1				; dword sized structures
	shl	di, 1
	mov	ds, ss:[bp].EP_nestedAddresses[di].segment
	mov	si, ss:[bp].EP_nestedAddresses[di].offset
	.leave
	ret
UnwindOneNesting	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DereferenceCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference a cell which is sitting on the top of the argument
		stack.

CALLED BY:	EvalEndOfExpression, EvalArgEnd, ParserEvalPushArgument
PASS:		es:bx	= Pointer to top of argument stack
		es:di	= Pointer to operator stack
		ss:bp	= Pointer to EvalParameters on the stack
RETURN:		es:bx	= New pointer to top of argument stack
		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DereferenceCell	proc	near
	uses	cx, dx
	.enter
	test	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
	jnz	quitNoError			; Branch if making dependencies
	;
	; Check the top of the operator-stack to see if it's a range-separator
	; or a range-intersection.
	;
	cmp	es:[di].OSE_type, ESOT_OPERATOR
	jne	deref				; Branch if it's not
	
	cmp	es:[di].OSE_data.ESOD_operator.EOD_opType, OP_RANGE_SEPARATOR
	je	quit				; Branch if it is
	cmp	es:[di].OSE_data.ESOD_operator.EOD_opType, OP_RANGE_INTERSECTION
	je	quit				; Branch if it is

deref:
	;
	; Dereference the cell...
	;
	test	es:[bx].ASE_type, mask ESAT_RANGE
	jz	quitNoError			; Branch if not a cell
	;
	; It's a range, check for start and end cells being the same.
	;
	mov	dx, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_row
	cmp	dx, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_row
	jne	quitNoError			; Not a cell if rows differ

	mov	cx, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_column
	cmp	cx, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_column
	jne	quitNoError			; Not a cell if columns differ
	;
	; It's a cell, we have the row/column, pop the range, then call the
	; application to push the cell data.
	;
	and	dx, mask CRC_VALUE		; dx/cx <- row/column of cell
	and	cx, mask CRC_VALUE

	clr	ch				; Pop argument
	mov	al, CT_DEREF_CELL		; Push the cell data

if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback	; Call the application
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[bp].CP_callback		; Call the application
endif
	jc	quit				; Branch on error
quitNoError:
	clc					; Signal: no error
quit:
	.leave
	ret
DereferenceCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceArgumentWithError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the top element of the argument stack with an error.

CALLED BY:	Utility
PASS:		al	= error code
		es:bx	= Pointer to the argument stack
RETURN:		es:bx	= New pointer to the argument stack
		carry set on serious error
		al	= error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceArgumentWithError	proc	near
	uses	cx
	.enter
	mov	cx, 1			; Replace one element
	call	PropogateError		; Put the error code on the stack
	.leave
	ret
ReplaceArgumentWithError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupFPStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup the fp-stack

CALLED BY:	ParserEvalExpression
PASS:		carry set if an error was encountered
		carry clear otherwise
		ss:bp	= Pointer to EvalParameters
		es:bx	= Pointer to arg-stack
RETURN:		carry unchanged
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixupFPStack	proc	near
	uses	ax
	.enter
	pushf				; Save error flag

	;
	; Check for a basic serious error...
	;
	jc	restoreStackPointer	; Branch if error

	;
	; Check for generating dependencies.
	;
	test	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
	jnz	restoreStackPointer	; Branch if making dependencies

	;
	; Check for not returning a number.
	;
	test	es:[bx].ASE_type, mask ESAT_NUMBER
	jz	restoreStackPointer	; Branch if not returning a number
	
	;
	; We are returning a number. This means that we really want to promote
	; the number at the bottom of the fp-stack to reside at the position
	; just below the stack pointer we saved when we came into the
	; evaluation code. Currently we don't have any faster technique for
	; doing this than what I'm doing here.
	;
	; If the expression evaluated correctly (and it did) then the only
	; reason for promoting the last number on the stack is if some error
	; was generated in the expression.
	;
	; If there was an error and we are returning a number then that means
	; that we somehow handled the error (like with ISERR()) and the
	; fp-stack is possibly screwed up.
	;

	;
	; Check for any error generated.
	;
	test	ss:[bp].EP_flags, mask EF_ERROR_PUSHED
	jz	quit			; Branch if no error generated

	push	es, di, ds, si		; Save pointer
	sub	sp, size FloatNum	; Make space on the stack
	
	segmov	es, ss, si		; es:di and ds:si <- pointer to the
	mov	ds, si			;   FloatNum on the stack
	mov	si, sp
	mov	di, si

	call	FloatPopNumber		; Get result from fp-stack

	mov	ax, ss:[bp].EP_fpStack	; ax <- stack pointer to restore
	call	FloatSetStackPointer	; Restore the stack pointer
	
	call	FloatPushNumber		; Put result back on fp-stack
	
	add	sp, size FloatNum	; Restore stack
	pop	es, di, ds, si		; Restore pointers
	jmp	quit			; All done...

restoreStackPointer:
	;
	; Either we are returning a serious error or we are not returning
	; a number. In either case we can restore the fp-stack without
	; damaging anyone.
	;
	mov	ax, ss:[bp].EP_fpStack	; ax <- stack pointer to restore
	call	FloatSetStackPointer	; Set the new stack pointer

quit:
	popf				; Restore error flag
	.leave
	ret
FixupFPStack	endp

EvalCode	ends
