COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseOperators.asm

AUTHOR:		John Wedgwood, Jan 30, 1991

ROUTINES:
	Name			Description
	----			-----------
	OpNegation		Implements the unary-minus operator	(-)
	OpPercent		Implements the unary-percent operator	(%)
	OpExponentiation	Implements the exponentiation operator	(^)
	OpMultiplication	Implements the multiplication operator	(*)
	OpDivision		Implements the division operator	(/)
	OpModulo		Implements the modulo operator		(%)
	OpAddition		Implements the addition operator	(+)
	OpSubtraction		Implements the subtraction operator	(-)
	OpEqual			Implements the equals operator		(=)
	OpNotEqual		Implements the not-equal operator	(<>)
	OpLessThan		Implements the less-than operator	(<)
	OpGreaterThan		Implements the greater-than operator	(>)
	OpLessThanOrEqual	Implements the less-than or equal op	(<=)
	OpGreaterThanOrEqual	Implements the greater-than or equal op	(>=)
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	1/30/91		Initial revision


DESCRIPTION:
	Implementation of the operator functions.
		

	$Id: parseOperators.asm,v 1.1 97/04/05 01:27:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EvalCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpNegation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the negation operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpNegation	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER	; al <- Type of arguments to check
	mov	cx, 1			; 1 argument to this function
	call	PropogateErrorsCheckArgs ; dx <- # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	call	FloatNegate		; Negate the numeric argument.
	mov	cx, 1			; 1 argument operation
	call	FinishFloatOp		; Do cleanup
quit:
	.leave
	ret
OpNegation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpPercent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the percent operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
		es:di	= Pointer to top of operator stack
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Smart % would be much smarter if the parser parsed it
	as a new operator, but how would parser know?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version
	witt	11/16/93	DBCS-ized
	jwu	10/24/96	added smart % feature (kind of hackish)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	LocalDefNLString   String100, "100"

OpPercent	proc	near
	uses	ds, cx, si
	.enter

	mov	al, mask ESAT_NUMBER		; al <- Type of args to check
	mov	cx, 1				; 1 argument to this function
	call	PropogateErrorsCheckArgs	; dx <- # of numeric args
	jc	quit				; Quit on general error
	jnz	quit				; Quit on eval error
	;
	; Push a 100 on the stack and then divide.
	;
	mov	ax, mask FAF_PUSH_RESULT	; Push the result
	mov	cx, length String100		; cx <- char count of "100"
	segmov	ds, cs				; ds:si <- ptr to the text
	mov	si, offset cs:String100
FXIP <	call	SysCopyToStackDSSI		; ds:si = str on stack	>
	call	FloatAsciiToFloat		; Push 100 on the stack
	call	FloatDivide			; Divide # by 100
FXIP <	call	SysRemoveFromStack		; release stack space	>
	mov	cx, 1				; 1 argument operation
	call	FinishFloatOp			; Do cleanup

if _SMART_PERCENT

	jc	quit

	;
	; If previous operator is + or -, do smart %.
	; e.g. 500 + 22% = 500 + (500 * .22) = 610.
	;

EC <	cmp	es:[di].OSE_data.ESOD_operator.EOD_opType, OP_PERCENT	>
EC <	ERROR_NE EVAL_BAD_OPERATOR_TYPE					>

	push	di
	call	PopOperator			; es:di = new top of op stack
	mov	cl, es:[di].OSE_data.ESOD_operator.EOD_opType
	pop	di

	cmp	cl, OP_ADDITION
	je	doSmart
	cmp	cl, OP_SUBTRACTION
	je	doSmart

	clc					; no error
	jmp	quit

doSmart:
	push	dx
	mov	al, mask ESAT_NUMBER		; al <- Type of args to check
	mov	cx, 2				; 2 arguments to this function
	call	PropogateErrorsCheckArgs 	; dx <- # of numeric args
	pop	dx
	jc	quit				; Quit on general error
	jnz	quit				; Quit on eval error

	call	FloatOver			; put prior arg on stack
	call	FloatMultiply			; multiply with % result

endif	; _SMART_PERCENT

quit:
	.leave
	ret
OpPercent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpExponentiation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the exponentiation operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpExponentiation	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER	; al <- Type of args to check
	mov	cx, 2			; 2 arguments to this function
	call	PropogateErrorsCheckArgs
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error
	
	call	FloatExponential	; Do the operation

	mov	cx, 2			; 2 argument operation
	call	FinishFloatOp		; Do cleanup
quit:
	.leave
	ret
OpExponentiation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpMultiplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the multiplication operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpMultiplication	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER	; al <- Type of arguments to check
	mov	cx, 2			; 2 arguments to this function
	call	PropogateErrorsCheckArgs ; dx <- # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	call	FloatMultiply		; Multiply the numbers

	mov	cx, 2			; 2 argument operation
	call	FinishFloatOp		; Do cleanup
quit:
	.leave
	ret
OpMultiplication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpDivision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the division operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpDivision	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER	; al <- Type of arguments to check
	mov	cx, 2			; 1 argument to this function
	call	PropogateErrorsCheckArgs ; dx <- # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	call	FloatDivide		; Do the division
	
	mov	cx, 2			; 2 argument function
	call	FinishFloatOp		; Do any cleanup necessary
quit:
	.leave
	ret
OpDivision	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpModulo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the modulo operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpModulo	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER	; al <- Type of arguments to check
	mov	cx, 2			; 2 arguments to this function
	call	PropogateErrorsCheckArgs ; # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	call	FloatMod		; Do the operation
	
	mov	cx, 2			; 2 argument function
	call	FinishFloatOp		; Do any cleanup necessary
quit:
	.leave
	ret
OpModulo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpAddition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the addition operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpAddition	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER	; al <- Type of arguments to check
	mov	cx, 2			; 2 arguments to this function
	call	PropogateErrorsCheckArgs ; # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	call	FloatAdd		; Add the two numbers on the fp-stack
	
	mov	cx, 2			; 2 argument function
	call	FinishFloatOp		; Do any cleanup necessary
quit:
	.leave
	ret
OpAddition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpSubtraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the subtraction operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpSubtraction	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER	; al <- Type of arguments to check
	mov	cx, 2			; 2 arguments to this function
	call	PropogateErrorsCheckArgs ; # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	call	FloatSub		; Subtract two numbers on the fp-stack
	
	mov	cx, 2			; 2 argument function
	call	FinishFloatOp		; Do any cleanup necessary
quit:
	.leave
	ret
OpSubtraction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpEqual
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the equal operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx	= Number of numeric args passed to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpEqual	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER or mask ESAT_STRING
	mov	cx, 2			; 2 arguments to this function
	call	PropogateErrorsCheckArgs
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	push	dx
	mov	dl, mask CF_ZERO	; Zero set
	mov	dh, -1			; Always rejected
	call	CompareOperator		; Handle the comparison
	pop	dx
quit:
	.leave
	ret
OpEqual	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpNotEqual
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the not-equal operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpNotEqual	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER or mask ESAT_STRING
	mov	cx, 2			; 2 argument to this function
	call	PropogateErrorsCheckArgs ; dx <-# numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	push	dx
	mov	dl, mask CF_SIGN	; Sign set, zero clear
	clr	dh			; Sign clear, zero clear
	call	CompareOperator		; Handle the comparison
	pop	dx
quit:
	.leave
	ret
OpNotEqual	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpLessThan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the < operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpLessThan	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER or mask ESAT_STRING
	mov	cx, 2			; 2 argument to this function
	call	PropogateErrorsCheckArgs ; dx <- # numeric args passed
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	push	dx
	mov	dl, mask CF_SIGN	; Sign set, zero clear
	mov	dh, -1			; Always fails
	call	CompareOperator		; Handle the comparison
	pop	dx
quit:
	.leave
	ret
OpLessThan	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpGreaterThan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the > operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpGreaterThan	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER or mask ESAT_STRING
	mov	cx, 2			; 2 argument to this function
	call	PropogateErrorsCheckArgs ; dx <- # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	push	dx
	clr	dl			; Sign clear, zero clear
	mov	dh, -1			; Always fails
	call	CompareOperator		; Handle the comparison
	pop	dx
quit:
	.leave
	ret
OpGreaterThan	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpLessThanOrEqual
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the <= operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpLessThanOrEqual	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER or mask ESAT_STRING
	mov	cx, 2			; 2 argument to this function
	call	PropogateErrorsCheckArgs ; dx <- # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	push	dx
	mov	dl, mask CF_ZERO	; Zero set, Sign clear (zero)
	mov	dh, mask CF_SIGN	; Sign set, Zero clear (less than)
	call	CompareOperator		; Handle the comparison
	pop	dx
quit:
	.leave
	ret
OpLessThanOrEqual	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpGreaterThanOrEqual
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implementation of the >= operator

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpGreaterThanOrEqual	proc	near
	uses	cx
	.enter
	mov	al, mask ESAT_NUMBER or mask ESAT_STRING
	mov	cx, 2			; 2 argument to this function
	call	PropogateErrorsCheckArgs ; dx <- # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error

	push	dx
	mov	dl, mask CF_ZERO	; Zero set, Sign clear (zero)
	clr	dh			; Sign clear, Zero clear (greater than)
	call	CompareOperator		; Handle the comparison
	pop	dx
quit:
	.leave
	ret
OpGreaterThanOrEqual	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareOperator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two non-error arguments on the stack.

CALLED BY:	OpEqual, OpNotEqual, OpGreaterThan, OpLessThan,
		OpGreaterThanOrEqual, OpLessThanOrEqual
PASS:		es:bx	= Argument stack
		es:di	= Operator stack
		dl	= One set of CompareFlags to check
		dh	= Another set of CompareFlags to check
			= -1 for no second set of flags to check
		ss:bp	= Pointer to EvalParameters
RETURN:		es:bx	= Result on stack
		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Currently:
		- Strings are 0 in comparison with numbers
		- String comparison is case-insensitive
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareOperator	proc	near
	uses	cx, dx, si
	.enter
	mov	si, bx			; es:si <- ptr to arg2
	call	Pop1Arg			; es:bx <- ptr to arg1
	;
	; See if the arguments are the same type.
	;
	mov	al, es:[bx].ASE_type
	mov	ah, es:[si].ASE_type
	and	al, mask ESAT_STRING or mask ESAT_NUMBER
	and	ah, mask ESAT_STRING or mask ESAT_NUMBER
	;
	; OK... Now we can check to see if they are the same type.
	;
	cmp	al, ah			; Check for same type
	jne	typesDiffer		; Branch if different types
	;
	; If we get here we are comparing either numbers or strings...
	; This makes life simple.
	;
	test	al, mask ESAT_NUMBER	; Check for a number
	jnz	compareNumbers		; Branch if comparing numbers
	;
	; Comparing strings.
	;
	push	ds, si, bx, cx, dx, di	; Save (about to be) nuked registers

	mov	dx, es:[si].ASE_data.ESAD_string.ESD_length
	lea	di, es:[si][ASE_data + size EvalStringData]
	;
	; Now:
	; es:di	= pointer to arg2
	; dx	= size of arg2
	;
	mov	cx, es:[bx].ASE_data.ESAD_string.ESD_length
	lea	si, es:[bx][ASE_data + size EvalStringData]
	segmov	ds, es			; ds:si <- ptr to arg1
	
	mov	bx, dx			; Pass arg2 size in bx
	
	call	CompareStringsNoCase	; Do the comparison
	pop	ds, si, bx, cx, dx, di	; Restore nuked registers
	jmp	checkCompareFlags	; Branch to put right value on stack

compareNumbers:
	;
	; Compare numbers.
	;
	call	FloatCompAndDrop	; Flags are set

checkCompareFlags:
	;
	; Comparison flags are set here.
	; dx = CompareFlags
	;
	; There are no arguments on the fp-stack. We need to push the result
	; (0 or 1) on the fp-stack.
	;
	lahf				; ah <- flags to compare against
	and	ah, mask CF_SIGN or mask CF_ZERO
	
	cmp	ah, dl			; Check for same flags
	je	resultTrue		; Branch if same
	cmp	dh, -1			; Check for nothing else to check
	je	resultFalse		; Branch if failed
	cmp	ah, dh			; Check for same flags
	je	resultTrue		; Branch if same
resultFalse:
	clr	ax			; Value to push
	jmp	pushResult		; Branch to push result
resultTrue:
	mov	ax, 1			; Value to push
pushResult:
	call	FloatWordToFloat	; Push the result
	jc	propError		; Branch on error

	call	Pop1Arg			; Remove the 1 remaining passed arg
	
	clr	cx			; No extra space needed
	mov	al, mask ESAT_NUMBER	; al <- type of argument
	call	ParserEvalPushArgument		; Push a place-holder for the result
	;;; Carry set here
quit:
	.leave
	ret

propError:
	;
	; Propogate an error from the fp-code.
	;
	mov	cx, 1			; Remove the 1 remaining argument
	call	PropogateError		; Generate the error
	jmp	quit			; Branch to quit

typesDiffer:
	;
	; The types are different... For now generate an error.
	;
	mov	al, PSEE_WRONG_TYPE
	jmp	propError
CompareOperator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareStringsNoCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two strings without regard to case

CALLED BY:	NameFindByName
PASS:		ds:si	= Pointer to one string
		cx	= Length of that string
		es:di	= Pointer to the other string
		bx	= Length of the other string
RETURN:		flags set for compare of (ds:si vs es:di)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareStringsNoCase	proc	near
	uses	cx, dx, di, bp
	.enter
	mov	bp, cx			; bp <- length of first string

	cmp	cx, bx			; Want to use the smallest length
	jbe	compare			; Branch if cx is smaller
	mov	cx, bx			; cx <- smallest length
compare:
	;
	; Do the comparison.
	;
	call	LocalCmpStringsNoCase
	jne	done			; Branch if different
	;
	; The strings are the same... Unless they are of different lengths.
	; In that case the smaller string is less than the largest string.
	; We can just basically compare the length of the first string to
	; the length of the second.
	;
	cmp	bp, bx			; Compare the lengths
done:
	.leave
	ret
CompareStringsNoCase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpRangeSeparator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate a range-separator argument

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= Number of numeric arguments to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpRangeSeparator	proc	near
	uses	ds, cx, si
	.enter
	sub	sp, size EvalRangeData	; Make a range on the stack
	segmov	ds, ss			; ds:si <- ptr to the range
	mov	si, sp

	mov	al, mask ESAT_RANGE	; Both types should be ranges
	mov	cx, 2			; 2 arguments to this function
	call	PropogateErrorsCheckArgs ; dx <- # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error
	;
	; Save the row and column of the last-cell of the range on top
	; of the stack
	;
	mov	ax, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_row
	mov	ds:[si].ERD_lastCell.CR_row, ax
	mov	ax, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_column
	mov	ds:[si].ERD_lastCell.CR_column, ax
	
	call	Pop1Arg			; Pop the 2nd argument off the stack
	;
	; The argument on the stack is a range. We can just fill in
	; lastCell field of the range.
	;
	mov	ax, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_row
	mov	ds:[si].ERD_firstCell.CR_row, ax
	mov	ax, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_column
	mov	ds:[si].ERD_firstCell.CR_column, ax

	call	Pop1Arg			; Remove the 1st range
	
	call	ParserEvalPushRange		; Push the result range onto the stack
	jc	quit			; quit if error
	;
	; Now make sure that the cells in the range are ordered correctly.
	;
	call	OrderRangeCells		; Rearrange them
	clc				; Signal: no error
quit:
	lahf				; Save error flag (carry)
	add	sp, size EvalRangeData	; Restore the stack
	sahf				; Restore error flag (carry)
	.leave
	ret
OpRangeSeparator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OrderRangeCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-order the cells in a range if they need it.

CALLED BY:	OpRangeSeparator
PASS:		es:bx	= Pointer to range on the argument stack
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Both elements of the range are assumed to be marked with the
	CRC_ABSOLUTE bit. We don't bother masking this bit out since
	all fields should have it set.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OrderRangeCells	proc	near
	uses	ax
	.enter
	mov	ax, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_row
	cmp	ax, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_row
	jbe	rowsOrdered
	;
	; The rows aren't ordered... Swap them.
	;
	xchg	ax, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_row
	mov	es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_row, ax
rowsOrdered:

	mov	ax, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_column
	cmp	ax, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_column
	jbe	columnsOrdered
	;
	; The columns aren't ordered... Swap them.
	;
	xchg	ax, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_column
	mov	es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_column, ax
columnsOrdered:
	.leave
	ret
OrderRangeCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpParserRangeIntersection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate a range-intersection argument

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx 	= number of numeric args passed to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpParserRangeIntersection	proc	near
	uses	ds, si, cx
	.enter
	mov	al, mask ESAT_RANGE	; Both types should be ranges
	mov	cx, 2			; 2 arguments to this function
	call	PropogateErrorsCheckArgs ; dx <- # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error
	
	;
	; Set up two pointers...
	;
	push	di			; Save operator stack pointer
	segmov	ds, es, si		; ds:si <- ptr to arg 1
	lea	si, es:[bx].ASE_data.ESAD_range
	
	call	Pop1Arg			; es:di <- ptr to 2nd arg
	lea	di, es:[bx].ASE_data.ESAD_range
	
	call	ParserEvalRangeIntersection	; Take the intersection
	pop	di			; Restore operator stack pointer

	jnc	quit			; Branch if intersection is valid
	
	;
	; We encountered an error, put it on the stack
	;
	mov	cx, 1			; Replace 1 argument
	call	PropogateError		; Generate the error

quit:
	clr	cx			; No numeric args were passed
	.leave
	ret
OpParserRangeIntersection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalRangeIntersection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implements the range intersection operator

CALLED BY:	Global and locally
PASS:		ds:si	= Pointer to one range all values absolute
		es:di	= Pointer to another range all values absolute
RETURN:		es:di	= Intersection of the two range
		carry set on error
		al	= Error code (always PSEE_ROW_OUT_OF_RANGE or
				PSEE_COLUMN_OUT_OF_RANGE)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	The intersection should always follow these rules:
		top	= max( source.top, dest.top )
		left	= max( source.left, dest.left )
		bottom	= min( source.bottom, dest.bottom )
		right	= min( source.right, dest.right )
	
	then we can make sure that we have a valid range...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If al == PSEE_ROW_OUT_OF_RANGE or PSEE_COLUMN_OUT_OF_RANGE
	then you can assume that the intersection is NULL.
	
	The CRC_ABSOLUTE bits will be set in the result.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserEvalRangeIntersection	proc	far
	uses	bx, cx, dx, bp
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; We have some preprocessing to do. We need to be working with only
	; the values of the different cells. The CRC_ABSOLUTE bit is
	; redundant.
	;
	mov	ax, ds:[si].ERD_firstCell.CR_row	; ax <- source top
	mov	bx, ds:[si].ERD_lastCell.CR_row		; bx <- source bottom
	mov	cx, ds:[si].ERD_firstCell.CR_column	; cx <- source left
	mov	dx, ds:[si].ERD_lastCell.CR_column	; bx <- source right

	;
	; Zero out the 'absolute' bit in everything since it's implied
	;
	mov	bp, mask CRC_VALUE
	
	and	ax, bp
	and	bx, bp
	and	cx, bp
	and	dx, bp
	
	and	es:[di].ERD_firstCell.CR_row, bp
	and	es:[di].ERD_firstCell.CR_column, bp
	and	es:[di].ERD_lastCell.CR_row, bp
	and	es:[di].ERD_lastCell.CR_column, bp

	;
	; Check for not intersecting at all.
	; The checks we make are:
	;	source.top > dest.bottom
	;	source.bottom < dest.top
	;	source.left > dest.right
	;	source.right < dest.left
	;
	cmp	ax, es:[di].ERD_lastCell.CR_row		; src.top & dst.bottom
	ja	badRow

	cmp	bx, es:[di].ERD_firstCell.CR_row	; src.bottom & dst.top
	jb	badRow

	cmp	cx, es:[di].ERD_lastCell.CR_column	; src.left & dst.right
	ja	badColumn

	cmp	dx, es:[di].ERD_firstCell.CR_column	; src.right & dst.left
	jb	badColumn

	;
	; We now know that the ranges intersect.
	; Set up the result of the intersection.
	;
	cmp	ax, es:[di].ERD_firstCell.CR_row	; Compare tops
	jbe	gotTop
	mov	es:[di].ERD_firstCell.CR_row, ax	; dst.top <- src.top
gotTop:
	
	cmp	bx, es:[di].ERD_lastCell.CR_row		; Compare bottoms
	jae	gotBottom
	mov	es:[di].ERD_lastCell.CR_row, bx		; dst.bot <- src.bot
gotBottom:

	cmp	cx, es:[di].ERD_firstCell.CR_column	; Compare lefts
	jbe	gotLeft
	mov	es:[di].ERD_firstCell.CR_column, cx	; dst.left <- src.left
gotLeft:
	
	cmp	dx, es:[di].ERD_lastCell.CR_column	; Compare rights
	jae	gotRight
	mov	es:[di].ERD_lastCell.CR_column, dx	; dst.right <- src.right
gotRight:
	
	;
	; Mark all references as absolute.
	;
	mov	ax, mask CRC_ABSOLUTE
	or	es:[di].ERD_firstCell.CR_row, ax
	or	es:[di].ERD_firstCell.CR_column, ax
	or	es:[di].ERD_lastCell.CR_row, ax
	or	es:[di].ERD_lastCell.CR_column, ax

	clc						; Signal: no error
	
quit:
	.leave
	ret

badRow:
	mov	al, PSEE_ROW_OUT_OF_RANGE
	stc						; Signal: error
	jmp	quit

badColumn:
	mov	al, PSEE_COLUMN_OUT_OF_RANGE
	stc						; Signal: error
	jmp	quit
ParserEvalRangeIntersection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpStringConcat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate a string concatenation

CALLED BY:	PopOperatorAndEval via operatorHandlers
PASS:		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters on the stack.
RETURN:		es:bx	= Pointer to new top of argument stack
		dx	= Number of numeric args passed to this function
		carry set on error
			al = error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpStringConcat	proc	near
	uses	cx, di, si, ds
	.enter
	sub	sp, MAX_STRING_LENGTH_BUF_SIZE
	mov	di, sp			; ss:di <- ptr to the buffer

	mov	al, mask ESAT_STRING or mask ESAT_NUMBER
	mov	cx, 2			; 2 arguments to this function
	call	PropogateErrorsCheckArgs ; dx <- # of numeric args
	jc	quit			; Quit on general error
	jnz	quit			; Quit on eval error
	;
	; There are two strings on the stack. We want to append the second
	; to the end of the first.
	;
	push	dx			; Save # of numeric args
	push	di			; Save address of the buffer
	push	bx			; Save arg-stack pointer
	call	Pop1Arg			; es:bx <- ptr to first arg
	mov	cx, MAX_STRING_LENGTH	; cx <- Max # of chars to copy
	call	CopyArgString		; cx <- # of characters left
	pop	bx			; Restore arg-stack pointer

	call	CopyArgString		; cx <- # of chars left
	mov	dx, MAX_STRING_LENGTH
	sub	dx, cx			; dx <- length of the string
	;
	; Remove the arguments and push the result.
	;
	mov	cx, 2			; Remove the old arguments
	call	ParserEvalPopNArgs
	
	segmov	ds, ss			; ds <- segment address of the string
	pop	si			; si <- offset to the string
	mov	cx, dx			; cx <- length of the string
DBCS<	shl	cx, 1			; cx <- size of string		>
	call	ParserEvalPushStringConstant	; Push the new string
	pop	dx			; dx <- # of numeric args
quit:
	lahf					;ah <- carry
	add	sp, MAX_STRING_LENGTH_BUF_SIZE
	sahf					;carry <- ah

	.leave
	ret
OpStringConcat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyArgString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string from the argument stack

CALLED BY:	OpStringConcat
PASS:		es:bx	= Pointer to string argument on the stack
		ss:di	= Pointer to the place to copy the string
		cx	= Max # of characters to copy (length)
RETURN:		ss:di	= Pointer past last character written
		cx	= # of characters left in the buffer (length)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/18/91	Initial version
	witt	11/16/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyArgString	proc	near
	uses	ax, bx, ds, si, es, bp
SBCS< numFormatBuf	local	FLOAT_TO_ASCII_HUGE_BUF_LEN dup (char)	>
DBCS< numFormatBuf	local	FLOAT_TO_ASCII_HUGE_BUF_LEN dup (wchar)	>
	.enter

	push	cx			; Save passed count

	test	es:[bx].ASE_type, mask ESAT_NUMBER
	jz	getString		; Branch if not a number
	;
	; Because we are working with strings, we don't want to treat
	; empty cells as zero the way numeric operators do.  This is
	; so something like ="Dear "&first&" "&"last doesn't give
	; "Dear John 0" if the 'last' field is empty.  (eca 6/30/94)
	;
	clr	ax			; ax <- no data (if empty)
	test	es:[bx].ASE_type, mask ESAT_EMPTY
	jnz	skipCopy		; branch if empty cell

	;
	; Duplicate the number on the fp-stack and then pop the number off
	; and convert it to ascii.
	;
	push	di, cx			; Save destination for string, count
	segmov	es, ss, di		; es:di <- destination
	lea	di, ss:numFormatBuf

	mov	ax, mask FFAF_NO_TRAIL_ZEROS
	mov	bh, DECIMAL_PRECISION
	mov	bl, DECIMAL_PRECISION - 1
	call	FloatFloatToAscii_StdFormat

	segmov	ds, es, si		; ds:si <- ptr to string
	mov	si, di
	;
	; Compute the string length.
	;
	call	LocalStringLength
	mov	ax, cx			; ax <- length w/o NULL
	pop	di, cx			; Restore destination for string, count

	;
	; ss:di	= Pointer to place to put the string.
	; ds:si	= Pointer to the string
	; ax	= # of characters in the string
	; cx	= Max # of characters to write
	;
	jmp	gotStringParams		; Branch to copy the text

getString:
	segmov	ds, es			; ds:si <- ptr to EvalStringData
	lea	si, ds:[bx].ASE_data

	lodsw				; ax <- length of the string

gotStringParams:
	segmov	es, ss			; es:di <- destination
	;
	; ds:si = pointer to the string
	; es:di = pointer to the destination
	; cx	= Max # of characters to write
	; ax	= # of characters in the string
	;
	cmp	ax, cx			; Check for string too long
	jbe	lengthOK		; Branch if length is OK
	mov	ax, cx			; ax <- # of chars to copy
lengthOK:
	mov	cx, ax			; cx <- # of chars to copy
	
	jcxz	skipCopy		; Branch if no space left
EC <	cmp	cx, MAX_STRING_LENGTH					>
EC <	ERROR_A	PARSE_STRING_TOO_LONG					>
	LocalCopyNString		; Copy the data
skipCopy:
	pop	cx			; Restore passed count
	sub	cx, ax			; cx <- # of bytes left
	.leave
	ret
CopyArgString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Pop1Arg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop a single argument off the argument stack

CALLED BY:	OpNegation, OpPercent
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Pop1Arg	proc	near
	uses	cx
	.enter
	mov	cx, 1		; Remove 1 argument
	call	ParserEvalPopNArgs
	.leave
	ret
Pop1Arg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNumberOfNumericArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find out how many arguments are on the FPStack.

CALLED BY:	PopOperatorAndEval
PASS:		ds:si	= Pointer to the token stream
		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
		cx = number of arguments to internal function
RETURN:		dx = number of numeric arguments
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNumberOfNumericArgs		proc	near
	uses	ax, bx, cx
	.enter

	clr	dx
	jcxz	done

checkArg:
	mov	al, mask ESAT_NUMBER
	call	FunctionCheckArgType		; go check type
	jc	notNumber
	inc	dx
notNumber:
	call	Pop1Arg
	loop	checkArg
done:
	.leave
	ret
GetNumberOfNumericArgs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PropogateErrorsCheckArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Propogate an error up the stack (if there is one).
		Type check arguments to make sure they're numbers.

CALLED BY:	Op*
PASS:		cx	= # of arguments passed to the operator (1 or 2)
		al	= The EvalStackArgumentType to check args against
		es:bx	= Pointer to the ArgumentStack
		es:di	= Pointer to the OperatorStack
RETURN:		dx	= number of numeric args that were passed
		carry set on error
		al	= Error code
		zero flag clear (nz) if there was an error propogated or if
			there was some type incompatibility
		zero flag set (z) if there was no error and the calculation
			should proceed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PropogateErrorsCheckArgs	proc	near
	uses	cx, si
	.enter

	call	GetNumberOfNumericArgs	; dx <- # of args that are numeric

	mov	si, bx			; Save argument pointer in si

	test	es:[bx].ASE_type, mask ESAT_ERROR
	jnz	propogateError		; Branch if one argument is an error

	test	es:[bx].ASE_type, al	; Make sure arg is the right type
	jz	badType			; Branch if wrong type
	
	dec	cx			; One less argument to check
	jz	quit			; Quit if only 1 argument (it's OK)
					; If we branch, then the z flag is set
					;   and the carry is clear
	;
	; The first argument checks out, try the second one.
	;
	call	Pop1Arg			; es:bx <- ptr to next argument
	test	es:[bx].ASE_type, mask ESAT_ERROR
	jnz	propogateError		; Branch if one argument is an error
	test	es:[bx].ASE_type, al	; Check for right type
	jz	badType			; Branch if wrong type

	mov	bx, si			; Restore the argument pointer
	clr	si			; Force zero flag set (no error)
					; Force carry flag clear (no error)
quit:
	;
	; Zero flag set if no evaluator error
	; Carry clear if no general error
	;
	.leave
	ret

badType:
	mov	al, PSEE_WRONG_TYPE	; dl <- error code
	jmp	propogateErrorAL	; Propogate the error in al

propogateError:
	mov	al, es:[bx].ASE_data.ESAD_error.EED_errorCode

propogateErrorAL:
	;
	; cx = # of arguments to pop before pushing the error.
	; es:bx = pointer to the error to propogate.
	;
	call	PropogateError		; Propogate the error up the arg-stack
	or	si, 1			; Force zero flag clear (eval error)
	jmp	quit
PropogateErrorsCheckArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserEvalPropagateEvalError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Propogate an error up the argument stack

CALLED BY:	PropogateErrorsCheckArgs
PASS:		es:bx	= Pointer to the argument stack
		es:di	= Pointer to the operator stack
		cx	= # of arguments to pop
		al	= Error code to put on the stack
RETURN:		es:bx	= New pointer to top of argument stack
		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserEvalPropagateEvalError	proc	far
	call	PropogateError
	ret
ParserEvalPropagateEvalError	endp

PropogateError	proc	near
	uses	cx, dx
	.enter
	mov	dl, al			; Save argument in dl
	call	ParserEvalPopNArgs		; Pop the arguments
	
	clr	cx			; No extra space
	mov	al, mask ESAT_ERROR	; al <- type of the token
	call	ParserEvalPushArgument		; Push the argument
	jc	quit			; Quit on general error
	;
	; Save the error code.
	;
	mov	es:[bx].ASE_data.ESAD_error.EED_errorCode, dl
quit:
	.leave
	ret
PropogateError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishFloatOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish up after a floating point operation.

CALLED BY:	OpNegation, OpPercent, OpExponentiation, OpMultiplication,
		OpDivision, OpModulo, OpAddition, OpSubtraction
PASS:		es:bx	= Pointer to argument stack
		es:di	= Pointer to the operator stack
		ss:bp	= Pointer to EvalParameters on stack
		cx	= # of arguments this function takes
		carry set if there was a floating-point error
		al	= FP error code
RETURN:		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:b
	Name	Date		Description
	----	----		-----------
	jcw	 4/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FinishFloatOp	proc	near
	uses	cx
	.enter
	jnc	quitPopOneArg		; Quit if no error

	call	FloatDrop		; drop the NAN from the stack

	call	PropogateError		; Force an error onto the stack
	;;; Carry set if there was an error generating the error...
quit:
	.leave
	ret

quitPopOneArg:
	dec	cx			; Leave a place holder
	call	ParserEvalPopNArgs		; Remove that many arguments
	clc				; Signal: no error
	jmp	quit			; Branch to close
FinishFloatOp	endp


EvalCode	ends
