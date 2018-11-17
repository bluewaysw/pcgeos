COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Parse Library
FILE:		parseFunctFixedArgs.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of parseFunctions.asm

DESCRIPTION:

Expected behavior of routines:
------------------------------

	A function is called with a list (possibly empty) of arguments
	on the argument stack.  These entries describe what arguments
	have been passed and in the case of numbers, they will have
	corresponding floating point numbers on the floating point stack.

	The function routine then uses these arguments to compute the
	desired result.

	Ranges are processed by calling DoRangeEnum, passing along
	a callback routine that will process each cell in the range.  

	The functionEnv stack frame should be initialized if any ranges
	are expected.

	When a result is computed, the original arguments are popped
	off and a new descriptor of the result pushed on.  If the
	result is a number, the number will be on the fp stack.  If
	the result is a string, the string will be part of the
	argument descriptor.

Error handling:
---------------
	
	When an error is encountered, the error is propagated via
	PropogateError.  This routine pops the arguments off the
	stacks and pushes on an error descriptor.  Only if a severe
	error occurs, like if PropogateError were unable to complete
	its task, will it return with the carry flag set.  The function
	bails out in such an event.

	Since PropogateError clears the stack and the carry flag,
	deciding when to place the call is important. We don't
	want to do it at a low level because we will then need
	to propagate the fact that an error has been propagated
	upwards through all the callers. This propagation will be
	complicated by the fact that PropogateError can itself return
	an error.

	We therefore adopt the convention that errors will trigger
	the carry flag to be set with the error code placed in al.
	Routines should then bail out whenever one of its subroutines
	return an error.  The routine that makes the call to PropogateError
	will be the highest level function routine.

	$Id: parseFunctFixedArgs.asm,v 1.1 97/04/05 01:27:32 newdeal Exp $

-------------------------------------------------------------------------------@

EvalCode	segment resource

;*******************************************************************************
;	ROUTINES THAT TAKE A FIXED (POSSIBLY 0) NUMBER OF NUMERIC ARGUMENTS
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionATan2

DESCRIPTION:	Implements the ATAN2() function
		ATAN(x, y) calculates the four-quadrant arc tangent of y/x.
		The four-quadrant arc (or inverse) tangent is the angle,
		measured in radians, whose tangent is y/x.

		x	y	ATAN(2(x,y)
		---------------------------
		+	+	from 0 to pi/2
		-	+	from pi/2 to pi
		-	-	from -pi to -pi/2
		+	-	from -pi/2 to 0

		eg. ATAN(1.5, 2) = .0927295 radians

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionATan2	proc	near
	mov	ax, 2
	call	FunctionCheckNNumericArgs
	jc	done

	call	FloatArcTan2
done:
	GOTO    FunctionCleanUpNumOp
FunctionATan2	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionChoose

DESCRIPTION:	Implements the CHOOSE() function.
		
		CHOOSE(offset, list) finds the value or string in list
		that is specified by offset.

		Offset can be 0 or any positive integer that is less than
		the number of items in list.

		List is one or more values, strings, references to ranges
		that contain values or strings, or any combination of
		values, strings, or range references.

		If the chosen item is a range, CHOOSE will return its SUM.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Let x = offset
	    e0, e1, ... en = list
	ie. we will get
	    x, e0, e1, ... en on the argument stack
	
	n = cx - 2, since x is a 0 based offset

	1. get x
	2. StacksRotateUp(cx-x-1) will move chosen item to the top of the stack
	3. StacksRotateDown(cx) will make the top item the cxth item
	4. pop cx-1 args

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	!!! still need to deal with ranges

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionChoose	proc	near	uses	cx,dx,si
	.enter

	mov	si, bx			; si <- top of stack

	cmp	cx, 2
	mov	al, PSEE_BAD_ARG_COUNT
	jb	err			; carry is set

	;-----------------------------------------------------------------------
	; get offset
	; cx = number of arguments, pop all but 1 off to get the offset
	; we need to count the number of numbers we encounter so
	; that we can get the offset

	dec	cx			; cx <- count-1
	push	cx			; save count-1
	clr	dx			; init count of fp numbers

popLoop:
	test	es:[bx].ASE_type, mask ESAT_NUMBER
	je	next
	inc	dx
next:
	call	Pop1Arg
	loop	popLoop
	pop	cx			; retrieve count-1

	;-----------------------------------------------------------------------
	; ok, dx = number of fp numbers on top off the offset
	; we will copy it to the top of the fp stack
	; si = top of arg stack
	; cx = count

	mov	al, mask ESAT_NUMBER
	call	FunctionCheckArgType	; numeric offset
	jc	err			; branch if not

	inc	dx
	mov	bx, dx
	call	FloatPick		; copy offset to top of stack
	call	FloatFloatToDword	; dx:ax <- int
	mov	bx, ax			; bx <- number

	mov	al, PSEE_GEN_ERR
	tst	dx
	jne	err			; error if dx <> 0

	cmp	bx, cx			; compare offset and (count-1)
	jge	err			; error if offset >= (count-1)

	;-----------------------------------------------------------------------
	; things check out...

	mov	dx, cx			; dx <- count-1
	sub	dx, bx			; convert to 1 based offset from TOS
	mov	bx, si			; restore top of argument stack
	call	StacksRotateUp		; make chosen item the top of the stack

	mov	dx, cx
	inc	dx			; dx <- count
	call	StacksRotateDown	; make top item the cxth item

	call	StacksDropNArgs
	clc
	jmp	short done

err:
	mov	bx, si			; restore original top of stack
	stc

done:
	.leave
	jnc	sumIfRange

	GOTO	PropogateError

sumIfRange:
	test	es:[bx].ASE_type, mask ESAT_RANGE
	je	exit

	push	cx
	mov	cx, 1
	call	FunctionSum
	pop	cx

exit:
	ret
FunctionChoose	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCols

DESCRIPTION:	Implements the COLS() function.

		COLS(range) counts the number of columns in range.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCols	proc	near	uses	dx
	.enter
	call	FunctionCheck1RangeArg
	jnc	10$

	mov	al, mask ESAT_NUMBER
	call	FunctionCheckArgType
	jc	done

	mov	ax, 1
	jmp	short 20$

10$:
	mov	ax, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_column
	and	ax, mask CRC_VALUE

	mov	dx, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_column
	and	dx, mask CRC_VALUE

	sub	ax, dx
	inc	ax

20$:
	call	FloatWordToFloat
	call	FloatAbs

done:
	call	FunctionCleanUpNumOp
	.leave
	ret
FunctionCols	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCTerm

DESCRIPTION:	Implements the CTERM() function
		CTERM(interest, future-value, present-value) calculates the
		number of periods it takes for an investment (present-value)
		to grow to a future-value, earning a fixed interest rate
		per compounding period.

		Let fv = future-value
		    pv = present-value
		    int = interest rate

			ln( fv/pv)
		CTERM =	-----------
			ln(1 + int)

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCTerm	proc	near
	mov	ax, 3
	call	FunctionCheckNNonNegativeNumericArgs
	jc	done

	; ( fp: int fv pv )

	call	FloatDivide		; ( fp: int fv/pv )
	call	FloatLn			; ( fp: int ln(fv/pv) )
	call	FloatSwap
	call	FloatLn1plusX		; ( fp: ln(fv/pv) ln(1 + int) )
	call	FloatDivide		; ( fp: CTERM )

done:
	GOTO	FunctionCleanUpNumOp
FunctionCTerm	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FunctionDDB

DESCRIPTION:	Implements the DDB() function
		DDB(cost, salvage, life, period) calculates the depreciation
		allowance of an asset for a specified period, using the double-
		declining balance method.

		Let bv = book value in that period
		    n = life of asset
		DDB = (bv * 2) / n.

		The total depreciation must not exceed cost-salvage.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if( life == 0 ), then return ERROR_OUT_OF_RANGE
	r	= 2/n		; double declining rate of depreciation
	DBCommon( cost, salvage, life, period, rate )

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	witt/gene  2/94 	Corrected n==p final period calc

------------------------------------------------------------------------------@

FunctionDDB	proc	near
	mov	ax, 4
	call	FunctionCheckNNonNegativeNumericArgs
	jc	done

	; Compute depreciation rate: 2 / life
	call	FloatOver		; ( fp: c s n p n )

	call	FloatDup		; cuz compare drops value
	call	FloatGt0
	jnc	argBelow0

	call	Float2			; double declining, 2 / life
					
	call	FloatSwap		; ( fp: c s n p 2 n )
	call	FloatDivide		; ( fp: c s n p rate )

	call	FuncDBCommon		; ( fp: depreciatedValue )
done:
	GOTO    FunctionCleanUpNumOp

argBelow0:
	mov	al, PSEE_NUMBER_OUT_OF_RANGE	; ERROR: arg <= 0
	stc
	jmp	done

FunctionDDB	endp


if PZ_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FunctionDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	FunctionDB

DESCRIPTION:	Implements the DB() function
		DDB(cost, salvage, life, period) calculates the depreciation
		allowance of an asset for a specified period, using a
		declining balance method.

		Let bv = book value in that period
		    n = life of asset
		DDB = (1 - (salvage/cost)^(1/life)) * UndeprecBalance

		The total depreciation must not exceed cost-salvage.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if cost == 0 OR life == 0, return ERROR_BAD_VALUE.
	r = 1 - (salv/cost)^(1/life)	; rate of depreciation
	DBCommon( cost, salvage, life, period, rate )

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	2/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FunctionDB	proc	near
	mov	ax, 4
	call	FunctionCheckNNumericArgs
	jc	done

	push	bx
	; Compute depreciation rate: 1 - (salvage/cost) ^ ( 1 / life )
	call	Float1			; ( fp: c s n p 1 )
	mov	bx, 4
	call	FloatPick		; ( fp: c s n p 1 s )
	mov	bx, 6
	call	FloatPick		; ( fp: c s n p 1 s c )

	call	FloatDup		; cuz compare drops value
	call	FloatGt0
	jnc	argBelow0		; abort if c <= 0
	call	FloatDivide		; ( fp: c s n p 1 s/c )

	call	FloatOver		; ( fp: c s n p 1 s/c 1 )
	mov	bx, 5
	call	FloatPick		; ( fp: c s n p 1 s/c 1 n )

	call	FloatDup		; cuz compare drops value
	call	FloatGt0
	jnc	argBelow0		; abort if n <= 0
	call	FloatDivide		; ( fp: c s n p 1 s/c 1/n )

	call	FloatExponential	; ( fp: c s n p 1 (s/c)^(1/n) )
	call	FloatSub		; ( fp: c s n p 1-(s/c)^(1/n) )

	pop	bx
	call	FuncDBCommon		; ( fp: depreciatedValue )
done:
	GOTO    FunctionCleanUpNumOp

argBelow0:
	pop	bx
	mov	al, PSEE_NUMBER_OUT_OF_RANGE	; ERROR: arg <= 0
	stc
	jmp	done

FunctionDB	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FuncDBCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute a declining balance type of depreciation; caller
		provides the depreciation rate.  The last period contains
		the remaining depreciation balance to reach salvage value.

CALLED BY:	FunctionsDDB

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to your function
		ss:bp	- pointer to EvalParameters on the stack.
		FP stack -> ( cost, salvage, life, period, rate )

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)
		FP stack -> ( depreciationValue )

DESTROYED:	ax

SIDE EFFECTS:	Uses up all arguments on FP stack.  Returns one FP value.

PSEUDO CODE/STRATEGY:
	if( period <= 0 OR period >= 65536 ) then ERROR.
	specialLastPeriodProcessing = ( lifespan == period ).
	bv0	= c		; initial book value = cost
	For each period:
	    d	= bv*r		; depreciation
	    If( (cost-salvage) - depreciation < sum(Depreciation) ) then
		if( periodsRemainingToCompute >= 2 ) return 0.
		return cost - salvage - sum(Depreciation)

	    sum(Depreciation) += d
	    bv'	= bv - d	; new book value

	If( lifespan == period AND sum(Deprec) < (cost - salvage)) then
	    return cost - salvage - sum(Depreciation).
	return d.

NOTES/INSIGHTS/CAEVENTS:
	* When not last period, then gone-too-far check stops depreciation
	  if there is no more value left before requested periods reached.
	* Last period flag ensures last period contains the remaining
	  book value to reach the salvage value.  For too short lifespans,
	  this value can be larger than the DDB for the previous period.
	* Assumes the lifespan is an integer, and silently truncates the
	  fraction if it isn't.
	* Negative rates (appriciation) are allowed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	2/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FuncDBCommon	proc	near
	uses	bx, dx di, es, ds

	sumDeprec	local	FloatNum ; all depreciation before this period
	doLastPeriod	local	BooleanByte
	.enter

	lea	si, ss:sumDeprec	; ptrs to local var
	mov	di, si

	;	( fp: cost salvage life(n) period rate )
	mov	bx, 5			; ( fp: c s n p rate )
	call	FloatRollDown		; ( fp: rate c s n p )

	clr	bl			; bl <- FALSE: not last period
	call	FloatComp
	jl	zero_5			; depreciation=0 if (period > life)
	jne	storeLastPeriodFlag
	dec	bl			; bl <- TRUE: special last period,
storeLastPeriodFlag:
	mov	ss:doLastPeriod, bl

	call	FloatFloatToDword	; dx:ax <- p, ( fp: rate c s n )
	tst	dx
	jne	err			; error if too large or negative

	tst	ax
	je	err			; error if 0
	push	ax			; save period

	;  "lifespan" no longer needed.
	call	FloatDrop		; ( fp: rate c s )

	call	Float0			; ( fp: rate c s 0 )
	mov	ax, ss			; use ds, es thru loop below, too.
	mov	es, ax
	mov	ds, ax
	call	FloatPopNumber		; es:di <- 0.0

	;-----------------------------------------------------------------------
	;  Replace the "salvage" value on the stack with the residual value,
	;  ie,  "cost-salvage"

	; ( fp: rate c s )
	call	FloatOver		; ( fp: rate c s c )
	call	FloatSwap		; ( fp: rate c c s )
	call	FloatSub		; ( fp: rate c c-s )

	pop	dx			; dx <- period

loopInit::
	mov	bx, 3			; bv0 <- cost
	call	FloatRollDown		; ( fp: c-s rate c )
	jmp	DBLoop

err:	
	mov	al, PSEE_GEN_ERR
	stc
	jmp	done


	;
	; drop 5 numbers, push a 0.0, then return.
	;
zero_5:
	call	FloatDrop
	call	drop4Floats
	call	Float0
	jmp	done


	;-----------------------------------------------------------------------
	; loop to compute
	;
	;	( fp: c-s r bv )
	;	ds = es = ss. ss:di, ss:si -> DB locals
DBLoop:
	;	depreciation := bookvalue * rate
	call	FloatOver		; ( fp: c-s r bv r )
	call	FloatOver		; ( fp: c-s r bv r bv )
	call	FloatMultiply		; ( fp: c-s r bv d )

	;	if( residual - depreciation < sumDeprec) then
	mov	bx, 4
	call	FloatPick		; ( fp: c-s r bv d c-s )
	call	FloatOver		; ( fp: c-s r bv d c-s d )
	call	FloatSub		; ( fp: c-s r bv d c-s-d )

	call	FloatPushNumber		; ( fp: c-s r bv d c-s-d sum )

	call	FloatComp		; ( fp: c-s r bv d c-s-d sum )
	jl	tooMuchDeprec		; jump if deprec exceeds worth

	call	FloatSwap		; ( fp: c-s r bv d sum c-s-d )
	call	FloatDrop		; ( fp: c-s r bv d sum )

	dec	dx
	jbe	doneCompute

	;
	;	Accumulate a total depreciation so far
	;
	;	sumDeprec += depreciation
	call	FloatOver		; ( fp: c-s r bv d sum d )
	call	FloatAdd		; ( fp: c-s r bv d sum+d )
	call	FloatPopNumber		; sumDeprec <- sum+d (fp: c-s r bv d)

	;	bookvalue -= depreciation
	call	FloatSub		; ( fp: c-s r bv' )
	jmp	DBLoop


tooMuchDeprec:
	;  Oopppss!  About to depreciate too much.

	call	FloatSwap		; ( fp: c-s r bv d sum c-s-d )
	call	FloatDrop		; ( fp: c-s r bv d sum )

	;	if( periods_remaining >= 2 ) return 0.0
	cmp	dx, 2			; doing last period?
	jae	zero_5			; nope. return the big 0.0

	;	return( residual - sumDeprec )
	mov	bx, 5
	call	FloatPick		; ( fp: c-s r bv d sum c-s )
	call	FloatSwap		; ( fp: c-s r bv d c-s sum )
	call	FloatSub		; ( fp: c-s r bv d c-s-sum )

	jmp	take5th

	;-----------------------------------------------------------------------
	;
	; We're done computing and the answer is on top of the stack.
	; However, underneath it are several values we used in
	; computing it that we need to get rid of.
	;
	;	( fp: c-s r bv d sum )
doneCompute:
	tst	ss:doLastPeriod
	jnz	specialLastPeriodTest
	call	FloatDrop		; ( fp: c-s r bv d sum )

take4th:
	mov	bx, 4
	call	FloatRollDown		; push answer down
	call	drop3Floats		; drop everything else
done:
	.leave				; preserves carry flag
	ret

	;-----------------------------------------------------------------------
	;  Too much depreciation is about to happen.  Return remaining
	;  value.
	;	( fp: c-s r bv d sum )
specialLastPeriodTest:
	mov	bx, 5
	call	FloatPick		; ( fp: c-s r bv d sum c-s )
	call	FloatComp
	pushf
	call	FloatSwap		; ( fp: c-s r bv d c-s sum )
	call	FloatSub		; ( fp: c-s r bv d c-s-sum )
	popf
	jge	take4th			; return d

take5th:				; return c-s-sum.
	mov	bx, 5
	call	FloatRollDown
	call	drop4Floats
	jmp	done

drop4Floats:
	call	FloatDrop
drop3Floats:
	call	FloatDrop
	call	FloatDrop
	call	FloatDrop
	retn
FuncDBCommon	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionErr

DESCRIPTION:	Implements the ERR() function
		ERR returns an argument desciptor of type error on
		the stack. The specific error is PSEE_GEN_ERR.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionErr	proc	near
	mov	al, PSEE_GEN_ERR
	stc

	GOTO	PropogateError
FunctionErr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionFact

DESCRIPTION:	Returns the factorial of a number.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionFact	proc	near
	call	FunctionCheck1NumericArg
	jc	done

	call	FloatFactorial

done:
	GOTO	FunctionCleanUpNumOp
FunctionFact	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionFV

DESCRIPTION:	Implements the FV() function
		FV(payments, interest, term) calculates the future value
		of an investment, based on a series of equal payments,
		earning a periodic interest rate, over the number of
		payment periods in term.

		Let p = periodic payment
		    i = interest rate
		    n = number of periods

			    (1 + i)^n - 1
		FV =	p * -------------
			         i

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionFV	proc	near
	mov	ax, 3
	call	FunctionCheckNNonNegativeNumericArgs	; ( fp: p i n )
	jc	done

	; If the interest rate is zero, we have a much simpler formula
	; (result = P * N)
	;
	call	FloatOver		; ( fp: p i n i )
	call	FloatEq0		; ( fp: p i n )
	jc	intEqZero		; if zero, do something different

	call	FloatOver		; ( fp: p i n i )
	call	Float1
	call	FloatAdd		; ( fp: p i n 1+i )
	call	FloatSwap		; ( fp: p i 1+i n )
	call	FloatExponential	; ( fp: p i (1+i)^n )
	call	Float1
	call	FloatSub		; ( fp: p i (1+i)^n-1 )
	call	FloatSwap
	call	FloatDivide
multiply:
	call	FloatMultiply		; ( fp: FV )

done:
	GOTO	FunctionCleanUpNumOp

intEqZero:
	; The interest rate is 0. Clean up the stack ( fp: p i n )
	;
	call	FloatSwap		; ( fp: p n i )
	call	FloatDrop		; ( fp: p n )
	jmp	multiply
FunctionFV	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionHLookup

DESCRIPTION:	Implements the HLOOKUP() function.

		HLOOKUP(x, range, rowOffset) finds the contents of a cell
		in the specified row of a horizontal lookup table.

		A horizontal lookup table is a range with value information
		in ascending order in the top row.

		HLOOKUP compares the value x to each cell in the top row of
		the table.  When a cell is located in the top row that contains
		the value x (or the value closest to, but not larger than x)
		it moves down that column the number of rows specified by
		rowOffset and returns the contents of the cell as the answer.

		X can be any value greater than or equal to the first value in
		the range.  If x is smaller than the first value in the range,
		an error is returned. If x is larger than the last value in
		range, HLOOKUP stops at the last cell in the row and returns
		the contents of that cell.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionHLookup	proc	near	uses	si
	mov	ax, bp
	FV_local	local	rangeInfoStruct
	.enter

	mov	si, ax			; ss:si <- EvalParameters

	mov	al, 3
	call	FunctionCheckNArgs
	jc	done

	;-----------------------------------------------------------------------
	; get colOffset

	call	GetWordArg		; ax <- int, dec cx
	jc	done

	mov	FV_local.RIS_rowOffset, ax

	;-----------------------------------------------------------------------
	; get range info

	test	es:[bx].ASE_type, mask ESAT_RANGE
	mov	al, PSEE_WRONG_TYPE
	je	err

	mov	ax, si			; ax <- original bp
	call	InitRangeInfo		; get range bounds, destroys ax
	call	Pop1Arg			; lose the range
	dec	cx			; dec arg count

	;-----------------------------------------------------------------------
	; see that offset is in range bounds

	mov	ax, FV_local.RIS_rowTop
	add	ax, FV_local.RIS_rowOffset
	cmp	ax, FV_local.RIS_rowBot
	ja	genErr

	;-----------------------------------------------------------------------
	; things check out, now conduct search

	clr	al			; specify HLOOKUP
	call	FunctionLookupDoSearch	; changes ax,bx
	jmp	short done

genErr:
	mov	al, PSEE_GEN_ERR
err:
	stc
done:
	jnc	quit
	call	PropogateError
quit:
	.leave
	ret
FunctionHLookup	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionIf

DESCRIPTION:	Implements the IF() function.

		IF(condition, x, y) evaluates condition and returns x if
		the condition is true and y if the condition is false.

		Any condition that evaluates to non-zero is taken to be true.
		Blank cells and strings equal 0 when used as the condition.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionIf	proc	near	uses	dx
	.enter
	mov	al, 3
	call	FunctionCheckNArgs
	jc	done

	mov	dx, 3
	call	StacksRotateUp		; move condition to top

	;
	; check for illegal conditions
	;
	test	es:[bx].ASE_type, mask ESAT_RANGE	; range?
	jne	err
	test	es:[bx].ASE_type, mask ESAT_ERROR	; error?
	jne	err

	;
	; what we have now are empty cells, strings and numbers
	;
	test	es:[bx].ASE_type, mask ESAT_EMPTY	; empty?
	jne	false					; false if so
	test	es:[bx].ASE_type, mask ESAT_STRING	; string?
	jne	false					; false if so

EC<	test	es:[bx].ASE_type, mask ESAT_NUMBER >
EC<	ERROR_E	FUNCTION_ASSERTION_FAILED >
	
	call	FloatDup		; duplicate numeric condition
	call	FloatEq0		; 0?
	jc	false

	call	StacksDropArg		; lose the condition
	call	StacksDropArg		; lose the false result
	clc
	jmp	short done

false:
	call	StacksDropArg		; lose the condition
	mov	dx, 2
	call	StacksRotateUp		; swap true and false results
	call	StacksDropArg
	clc
	jmp	short done

err:
	mov	al, PSEE_GEN_ERR
	stc
done:
	jnc	quit

	call	PropogateError
quit:
	.leave
	ret
FunctionIf	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionIndex

DESCRIPTION:	Implements the INDEX() function.

		INDEX(range, columnOffset, rowOffset) finds the value in the
		cell located at a specified columnOffset and rowOffset of range.

		columnOffset and rowOffset are 0 based offset numbers.

		Use INDEX instead of HLOOKUP or VLOOKUP when you want to use
		a lookup table but need to use relative positions of the
		rows or columns, instead of specified values, to find
		an entry.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionIndex	proc	near	uses	cx,dx,si
	mov	ax, bp
	FI_local	local	rangeInfoStruct
	.enter
	mov	si, ax

	mov	al, 3
	call	FunctionCheckNArgs
	jc	done

	mov	dx, 3
	call	StacksRotateUp		; move range arg to top of stack

	test	es:[bx].ASE_type, mask ESAT_RANGE
	je	err

	;-----------------------------------------------------------------------
	; get range info

	mov	ax, si			; ax <- original bp
	call	InitRangeInfo		; get range bounds
	call	Pop1Arg			; lose range
	dec	cx			; dec arg count

	;-----------------------------------------------------------------------
	; get rowOffset

	call	GetWordArg		; ax <- int, dec cx
	jc	done

	mov	FI_local.RIS_rowOffset, ax

	;-----------------------------------------------------------------------
	; get colOffset

	call	GetWordArg		; ax <- int, dec cx
	jc	done

	mov	FI_local.RIS_colOffset, ax

	;-----------------------------------------------------------------------
	; see that cell is in range bounds
	; ax = colOffset

	mov	dx, FI_local.RIS_columnLeft
	add	ax, dx
	cmp	ax, FI_local.RIS_columnRight
	ja	err

	mov	dx, FI_local.RIS_rowTop
	add	dx, FI_local.RIS_rowOffset
	cmp	dx, FI_local.RIS_rowBot
	ja	err

	;-----------------------------------------------------------------------
	; things check out
	; drop all args and dereference cell
	; dx, ax = (r, c)

	push	ax			; save column
	call	StacksDropNArgs
	pop	cx			; retrieve column

	push	bp
	mov	bp, FI_local.RIS_saveBP
	mov	ch, mask DF_DONT_POP_ARGUMENT
        mov     al, CT_DEREF_CELL	; push the cell data
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[bp].CP_callback	; call the application
endif
	pop	bp
	jmp	short done

err:
	mov	al, PSEE_GEN_ERR
	stc

done:
	jnc	quit

	call	PropogateError
quit:
	.leave
	ret
FunctionIndex	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionIRR

DESCRIPTION:	Implements the IRR() function

		IRR is complicated...

		IRR(guess, range) calculates the internal rate of return
		expected from a series of cash flows generated by an investment.
		The internal rate of return is the percentage rate at which the
		present value of an expected series of cash flows is
		equal to the present value of the initial investment.

		The cash flow is assumed to be received at regualr, equal
		intervals.

		Values containing text, logical, or empty cells are ignored.

		IRR uses the order of values to interpret the order of cash
		flows.

		Guess represents the estimate of the internal rate of return.
		Guess can be any value greater than 0 (0%) and less than 1
		(100%).

		Range can be the name or address of the range that contains
		the cash flows. Negative numbers are considered as cash
		outflows and positive numbers as cash inflows. The first
		number in the range is normally negative representing the
		investment.

		Starting with guess, IRR cycles through the calculation until
		the result is accurate to within 0.00001%.  If IRR cannot find
		a result that works after 20 tries, the #VALUE! error value is
		returned.

		NOTES
		-----
		IRR is closely related to NPV.  The rate of return calculated
		by IRR is the interest rate corresponding to a zero net
		present value.  NPV(IRR(range), range) = 0.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	adopt a binary search strategy using NPV
	attempt to head toward 0

	more detailed:

	if the guess is missing, use 10%
	else error check guess

	oldguess = 100%

	for i = 1 to 20 do
	    if (npv=NPV(guess, range)) <= 0.00001% then
		break;
	    else if npv < 0 then
		want smaller guess
		guess = guess - abs((guess-oldguess)/2);
	    else
		want larger guess
		guess = guess + abs((guess-oldguess)/2);
	    endif
	end for

	if found then return result
	else return error

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionIRR	proc	near
	mov	ax, bp
	FIRR_local	local	functionEnv
	ForceRef	FIRR_local
	.enter

	call	InitFunctionEnv

	;-----------------------------------------------------------------------
	; check number of arguments

	mov	al, 2
	call	FunctionCheckNArgs
	jc	done

	;-----------------------------------------------------------------------
	; check to see that the 2nd arg is a range

	mov	al, mask ESAT_RANGE
	call	FunctionCheckArgType
	jc	done

	;-----------------------------------------------------------------------
	; check guess

	push	bx
	call	Pop1Arg
	mov	al, mask ESAT_NUMBER
	call	FunctionCheckArgType
	pop	bx
	jc	done				;branch if error
	;
	; NOTE: we don't error check the guess, since answers can
	; be any value.  Normally they fall in the range -1 to 1
	; (-100% to 100%), which will be quickly found by the search,
	; but there are answers that are > 100%.
	;
	call	FunctionIRRDoSearch
done:
	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionIRR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	FunctionIRRDoSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

CALLED BY:	INTERNAL (FunctionIRR)

PASS:		

RETURN:		carry set on error

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	call NPV
	if npv < threshold then
	    done
	else if npv < 0 then
	    make guess smaller
	else
	    make guess larger
	endif

	to make a smaller guess,
	    upperBound <- guess
	    guess <- guess - (upperBound - lowerBound)/2
	
	to make a larger guess,
	    lowerBound <- guess
	    guess <- guess + (upperBound - lowerBound)/2

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FunctionIRRDoSearch	proc	near
	FIRR_local	local	functionEnv
	.enter	inherit near

	;-----------------------------------------------------------------------
	; initialize the threshold, bounds and the loop count

	mov	ax, FUNCTION_IRR_THRESHOLD_EXP
	call	Float10ToTheX			; ( fp: guess 10^7 )
	call	FloatInverse			; ( fp: guess 1/10^7 )
	lea	ax, FIRR_local.FE_threshold
	call	FunctionIRRPopNumber		; ( fp: guess )

	;
	; NOTE! we will restrict the search to between:
	;     * half of the guess
	;     * twice of the guess or 1 whichever is smaller
	;
	; WRONG! the above means you won't find answers much of
	; the time, so instead we restrict the initial search to:
	;     * -1
	;     * 1
	; instead.  The binary nature of the search means
	; it will converge rapidly enough that not much is gained by the
	; original restriction, only an interation or two.
	; NOTE: ideally this would use interpolation where the amount
	; the previous guess is off is used to assign the next guess.
	; This will allow it to converge much more rapidly.
	;

	call	FloatMinus1			; ( fp: guess -1 )
	lea	ax, FIRR_local.FE_lowerBound
	call	FunctionIRRPopNumber

	call	Float1				; ( fp: guess 1 )
	lea	ax, FIRR_local.FE_upperBound
	call	FunctionIRRPopNumber

	mov	FIRR_local.FE_loopCount, FUNCTION_IRR_LOOP_COUNT

npvLoop:
	;-----------------------------------------------------------------------
	; ( fp: guess )

	call	FunctionIRRCallNPV		; ( fp: guess npv )
	jc	done				; branch on error (al = error)
						
EC<	call	FloatDepth >
EC<	cmp	ax, 2 >
EC<	ERROR_L FUNCTION_BAD_FP_STACK_DEPTH >
	
	;
	; check npv
	;
	call	FloatDup
	call	FloatAbs			; ( fp: guess npv |npv| )
	lea	ax, FIRR_local.FE_threshold	; ax <- address of threshold
	call	FunctionIRRComp			; compare |npv| with threshold
	call	FloatDrop			; ( fp: guess npv )
	jbe	found

	call	FunctionIRRAdjustGuess		; ( fp: newguess )

	dec	FIRR_local.FE_loopCount
	ja	npvLoop

	;
	; not found
	; return #VALUE! error
	; there are no excess args on the stack
	;
	mov	al, PSEE_NUMBER_OUT_OF_RANGE
	stc
	jmp	short done

found:
	; ( fp: guess npv )
	; return the guess that hit the mark
	;
	call	FloatDrop		; lose npv
	clc

done:
	.leave
	ret
FunctionIRRDoSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	FunctionIRRCallNPV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Duplicate the the arguments on the argument and floating
		point stacks and call FunctionNPV.
		The argument stack is assumed to contain a number and a range,
		with the range on top.

CALLED BY:	INTERNAL (FunctionIRRDoSearch)

PASS:		( fp: guess -- guess npv )
		( arg: NUMBER RANGE -- NUMBER RANGE )
		es:bx	= Pointer to the top of the argument stack
		es:di	= Pointer to the OperatorStack
		ss:bp	= Pointer to EvalParameters structure on the stack.

RETURN:		npv on the floating point stack, argument stack intact
		carry set on error (arg-stack holds error token)
			al = error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FunctionIRRCallNPV	proc	near
	FIRR_local	local	functionEnv
	uses	cx,dx,ds,si
	.enter	inherit near

	; (fp: guess )

	push	bp
	segmov	ds, es, si
	lea	si, es:[bx].ASE_data	; ds:si <- range data
	mov	bp, FIRR_local.FE_evalParams

	mov	al, mask ESAT_NUMBER	; push a number
	clr	cx			; with no extra space
	call	ParserEvalPushArgument	; ax destroyed, bx changed
	jc	quitPopBP

	call	FloatDup		; duplicate the guess on the fp stack

	call	ParserEvalPushRange	; ax destroyed, bx changed
	jc	noError			; quit, but remove other arg first

	; 
	; Save the current depth of the FPStack (fp: guess guess)
	;
	call	FloatDepth		; ax <- current FPStack size
	push	ax		
	;
	; Get the actual number of numeric arguments on the FPStack 
	; 
	mov	cx, 2			; 
	call	GetNumberOfNumericArgs	; dx <- # numeric args
	push	dx		

	mov	ch, 0ffh		; flag that args have been checked
	call	FunctionNPV		; destroys ax

	pop	si			; si <- # numeric args that were passed
	pop	cx			; cx <- previous FPStack depth
	jc	quitPopBP		; branch if horrible error

	;
	; If evaluating the function or operator produced an
	; error, fixup the FPStack before continuing
	;
	test	es:[bx].ASE_type, mask ESAT_ERROR
	jz	noError			; carry is clear if we branch

	call	FunctionErrorFixupFPStack

	mov	al, es:[bx].ASE_data.ESAD_error.EED_errorCode	; propagate
	stc
	
	; Fall thru... we will end up losing the error token, which
	; is really just fine, as long as we finish this code with
	; the same number of arguments on the stack as we had before.
	;
	; The carry being set and the error code in al should be all
	; that we need here.

noError:
	; carry set or clear depending on error
	pushf
	call	Pop1Arg			; lose the NUMBER place holder
	popf

quitPopBP:
	pop	bp

	.leave
	ret
FunctionIRRCallNPV	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	FunctionIRRAdjustGuess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Adjust the guess according to the NPV result.  A binary
		search approach is taken.  The upper and lower bounds in
		the stack frame are modified accordingly.

CALLED BY:	INTERNAL (FunctionIRRDoSearch)

PASS:		( fp: guess npv )

RETURN:		( fp: newguess )

DESTROYED:	FE_miscFlag

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if npv < 0 then
	    make guess smaller
	else
	    make guess larger
	endif

	to make a smaller guess,
	    upperBound <- guess
	    guess <- guess - (upperBound - lowerBound)/2
	
	to make a larger guess,
	    lowerBound <- guess
	    guess <- guess + (upperBound - lowerBound)/2

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FunctionIRRAdjustGuess	proc	near
	FIRR_local	local	functionEnv
	.enter	inherit near

	clr	FIRR_local.FE_miscFlag	; use this as the less than 0 flag
	call	Float0
	call	FloatComp		; result < 0?
	pushf
	call	FloatDrop		; ( fp: guess npv )
	call	FloatDrop		; ( fp: guess )
	call	FloatDup		; ( fp: guess guess )
	popf
	ja	npvPositive

	;
	; npv < 0
	; need to make guess smaller
	;
	dec	FIRR_local.FE_miscFlag	; mark less than 0
	lea	ax, FIRR_local.FE_upperBound
	jmp	short updateBound

npvPositive:
	;
	; npv > 0
	; need to make guess larger
	;
	lea	ax, FIRR_local.FE_lowerBound

updateBound:
	call	FunctionIRRPopNumber	; ( fp: guess )

	;
	; compute adjustment
	;
	lea	ax, FIRR_local.FE_upperBound
	call	FunctionIRRPushNumber
	lea	ax, FIRR_local.FE_lowerBound
	call	FunctionIRRPushNumber
	call	FloatSub
	call	FloatDivide2		; ( fp: guess adjustment )

	;
	; adjust guess
	;
	cmp	FIRR_local.FE_miscFlag, 0
	je	adjustGuess

	call	FloatNegate		; ( fp: guess -adjustment )

adjustGuess:
	call	FloatAdd		; ( fp: newguess )
	
	.leave
	ret
FunctionIRRAdjustGuess	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	FunctionIRRPushNumber, FunctionIRRPopNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load the appropriate registers with the address of the field
		in the stack frame and issue the call to the float routine

CALLED BY:	INTERNAL ()

PASS:		ax - effective address of the FE_result* field

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FunctionIRRPushNumber	proc	near	uses	ds,si
	.enter
	segmov	ds, ss, si
	mov	si, ax
	call	FloatPushNumber
	.leave
	ret
FunctionIRRPushNumber	endp

FunctionIRRPopNumber	proc	near	uses	es,di
	.enter
	segmov	es, ss, di
	mov	di, ax
	call	FloatPopNumber
	.leave
	ret
FunctionIRRPopNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	FunctionIRRComp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Push the given number and perform a comparison.

CALLED BY:	INTERNAL ()

PASS:		ax - effective address of the field in the stack frame
		     containing the floating point number

RETURN:		flags set
		fp stack remains intact

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FunctionIRRComp	proc	near	uses	ds,si
	.enter
	segmov	ds, ss, si
	mov	si, ax
	call	FloatPushNumber		; ( fp: npv threshold )

	call	FloatComp		; flags set to X-Y
	call	FloatDrop		; lose threshold, flags remain intact
	.leave
	ret
FunctionIRRComp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionMod

DESCRIPTION:	Implements the MOD() function

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionMod	proc	near
	mov	ax, 2
	call	FunctionCheckNNumericArgs
	jc	done

	call	FloatMod
done:
	GOTO    FunctionCleanUpNumOp
FunctionMod	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionN

DESCRIPTION:	Implements the N() function
		N(range) returns the entry in the first cell in the range
		as a value, if the cell contains a value.  If the cell
		contains a label, N returns the value 0.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if arg is a cell ref
	    return N(cell contents)
	else if arg is a range
	    deref first cell
	    return N(cell contents)
	else
	    wrong type

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionN	proc	near
	mov	ax, bp
	FN_local	local	functionEnv
	.enter

	call	InitFunctionEnv

	;
	; check 1 arg
	;
	mov	al, 1
	call	FunctionCheckNArgs
	jc	done

	;
	; check for error
	;
	test	es:[bx].ASE_type, mask ESAT_ERROR
	jz	argNotError

	mov	al, es:[bx].ASE_data.ESAD_error.EED_errorCode	; propagate
	stc
	jmp	short done

argNotError:
	;-----------------------------------------------------------------------
	; we have 1 arg that's not an error

	test	es:[bx].ASE_type, mask ESAT_RANGE	; range?
	jnz	doRange

	test	es:[bx].ASE_type, mask ESAT_NUMBER	; number?
	jnz	doNumber

return0:
	;
	; return 0
	;
	call	Float0
	mov	al, (NT_BOOLEAN shl offset ESAT_NUM_TYPE) or mask ESAT_NUMBER
	call	ArgStackPopAndLeaveArgTypeWithFunctionEnv
	jmp	short exit

doNumber:
	;
	; return the number
	;
	mov	al, (NT_BOOLEAN shl offset ESAT_NUM_TYPE) or mask ESAT_NUMBER
	call	ArgStackPopAndLeaveArgTypeWithFunctionEnv
	jmp	short exit

doRange:
	;-----------------------------------------------------------------------
	; range

	push	cx
	mov     ax, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_row
	and	ax, mask CRC_VALUE

	mov     cx, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_column
	and	cx, mask CRC_VALUE

	call	FunctionNDerefCell
	pop	cx
	jnc	done

	;
	; distinguish between errors
	; if error is propagated, leave alone
	; else return 0
	;
	cmp	FN_local.FE_errorPropagated, 0	; error propagated?
	jz	return0				; branch if error propagated
	stc

done:
	call	FunctionCleanUpNumOpWithFunctionEnv

exit:
	.leave
	ret
FunctionN	endp


FunctionNDerefCell	proc	near	uses	bx,dx,es
	DC_local	local	functionEnv
	.enter inherit near

	mov	dx, ax			; dx <- row

	;
	; restore the parser's environment
	;
	les	bx, DC_local.FE_argStack
	push	bp			; save offset to functionEnv
	mov	bp, DC_local.FE_evalParams

	;***********************************************************************
	; don't use DC_local between here...

	mov	ch, mask DF_DONT_POP_ARGUMENT
        mov     al, CT_DEREF_CELL	; push the cell data
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].EP_common.CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call    ss:[bp].EP_common.CP_callback	; call the application
endif
	jc	derefErr

	;
	; deref successful
	;
	clr	al			; al <- no error
	mov	dl, es:[bx].ASE_type	; dl <- type
	mov	dh, es:[bx].ASE_data.ESAD_error.EED_errorCode	; dh <- error
	test	dl, mask ESAT_NUMBER	; number?
	jne	popArg			; branch if number

	mov	al, PSEE_WRONG_TYPE	; assume error
	stc

popArg:
	pushf				; save z flag
	call	Pop1Arg			; drop the place holder
	popf				; restore z flag

derefErr:
	; ...and here.
	;***********************************************************************

	pop	bp			; restore offset to functionEnv
	mov	DC_local.FE_curArgType, dl
	jnc	updateNumCount

	test	dl, mask ESAT_ERROR
	jz	err

	mov	al, dh				; propagate error
	mov	DC_local.FE_errorPropagated, 0ffh

err:
	mov	DC_local.FE_errorCode, al
	stc
	jmp	short updateArgStack

updateNumCount:
EC<	ERROR_C	0 >
	test	dl, mask ESAT_EMPTY
	jne	updateArgStack

	inc	DC_local.FE_numCount
	clc

updateArgStack:
	mov	DC_local.FE_argStack.segment, es
	mov	DC_local.FE_argStack.offset, bx

	.leave
	ret
FunctionNDerefCell	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionNA

DESCRIPTION:	Implements the NA() function
		NA returns an argument desciptor of type error on
		the stack. The specific error is PSEE_NA.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionNA	proc	near
	mov	al, PSEE_NA
	stc

	GOTO	PropogateError
FunctionNA	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionNPV

DESCRIPTION:	Implements the NPV() function
		NPV(interest, range) calculates the net present value of
		a series of future cash flows discounted at a fixed,
		periodic interest rate.

		Let v1...vn = series of cash flows in the range
		    int = interest rate
		    n = number of cash flows
		    i = the current iteration of 1 through n

			 n	 vi
		NPV =	SUM  -----------
			i=1  (1 + int)^i

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		ch	- flag to signal the routine to skip argument checking
			  This is done because FunctionIRR call this routine
			  in the course of its computations and this is added
			  as an optimization.

			  ***** It assumes that the user cannot feed this
			  routine more than 255 arguments. *****

		cl	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionNPV	proc	near
	mov	ax, bp
	FNPV_local	local	functionEnv
	.enter

	call	InitFunctionEnv

	cmp	ch, 0
	je	checkArgs

EC<	cmp	ch, 0ffh >
EC<	ERROR_NE FUNCTION_ASSERTION_FAILED >
	clr	ch
	mov	FNPV_local.FE_numArgs, cx
	jmp	short workOnRange

checkArgs:
	;
	; check number of arguments
	;
	mov	al, 2
	call	FunctionCheckNArgs
	jc	done

	;
	; check to see that the 2nd arg is a range
	;
	mov	al, mask ESAT_RANGE
	call	FunctionCheckArgType
	jc	done

	;
	; check interest rate
	;
	push	bx
	call	Pop1Arg
	mov	al, mask ESAT_NUMBER
	call	FunctionCheckArgType
	pop	bx
	jc	done

workOnRange:
	;
	; arguments check out, go work on the range
	;
	mov	FNPV_local.FE_nearRoutine, 0ffh
	mov	FNPV_local.FE_argProcessingRoutine.handle, offset NPVCallback
	mov	FNPV_local.FE_argsReqForProcRoutine, 1
	call    DoRangeEnum
	jc	done

	mov	al, 3
	call	FunctionCheckIntermediateResultCount
	jc	done

	; ( fp: x x result )
	call	FloatSwap
	call	FloatDrop

	call	FloatSwap
	call	FloatDrop

done:
	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionNPV	endp


NPVCallback	proc	near	uses	bx
	NPVC_local	local	functionEnv
	.enter inherit near

	cmp	NPVC_local.FE_cellCount, 1
	jne	trackArgs

	;
	; very first number, set fp stack up to track
	;     vi / (1+int)^i	- the sum
	;     (int is already on the fp stack)
	;
	; subsequent calls will maintain:
	;     ( fp: int+1  (int+1)^i  sum )
	;
	call	FloatSwap		; ( fp: v1 int )
	call	Float1
	call	FloatAdd		; ( fp: v1 int+1 )
	call	FloatDup		; ( fp: v1 int+1 int+1 )
	call	FloatRot		; ( fp: int+1 int+1 v1 )

	call	FloatOver		; ( fp: int+1 int+1 v1 int+1 )
	call	FloatDivide		; ( fp: int+1 int+1 sum )
	jmp	short done

trackArgs:
	;
	; ( fp: int+1 (int+1)^(i-1) sum vi )
	;
	; let I = (int+1)^(i-1)
	;     I' = (int+1)^i
	;
	mov	bx, 3
	call	FloatPick		; ( fp: int+1 I sum vi I )
	mov	bx, 5
	call	FloatPick
	call	FloatMultiply		; ( fp: int+1 I sum vi I' )

	mov	bx, 4
	call	FloatRoll		; ( fp: int+1 sum vi I' I )
	call	FloatDrop		; ( fp: int+1 sum vi I' )
	call	FloatSwap		; ( fp: int+1 sum I' vi )
	call	FloatOver		; ( fp: int+1 sum I' vi I' )
	call	FloatDivide		; ( fp: int+1 sum I' vi/I' )

	call	FloatRot		; ( fp: int+1 I' vi/I' sum )
	call	FloatAdd		; ( fp: int+1 I' sum' )
	
done:
	.leave
	ret
NPVCallback	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionPi

DESCRIPTION:	Implements the PI() function

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionPi	proc	near
	call	FunctionCheck0Args
	jc	done			; branch if wrong number of arguments

	call	FloatPi
done:
	GOTO    FunctionCleanUpNumOp
FunctionPi	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionPMT

DESCRIPTION:	Implements the PMT() function
		PMT(principal, interest, term) calculates the amount of the
		periodic payment needed to pay off a loan, given a periodic
		interest rate and number of payment periods.  It is assumed
		that the payments are made at the end of each payment period.

		Let p = principal
		    i = periodic interest rate
		    n = term

				  i
		PMT =	p * --------------
			    1 - (i + 1)^-n

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionPMT	proc	near
	mov	ax, 3
	call	FunctionCheckNNonNegativeNumericArgs	; ( fp: p i n )
	jc	done

	; If the interest rate is zero, we have a much simpler formula
	; (result = P / N)
	;
	call	FloatOver		; ( fp: p i n i )
	call	FloatEq0		; ( fp: p i n )
	jc	intEqZero		; if zero, do something different

	call	FloatNegate
	call	FloatOver		; ( fp: p i -n i )
	call	Float1
	call	FloatAdd		; ( fp: p i -n i+1 )
	call	FloatSwap
	call	FloatExponential	; ( fp: p i (i+1)^-n )
	call	FloatNegate
	call	Float1
	call	FloatAdd		; ( fp: p i 1-(i+1)^-n )
	call	FloatDivide
	call	FloatMultiply		; ( fp: PMT )

done:
	GOTO    FunctionCleanUpNumOp

intEqZero:
	; The interest rate is 0. Clean up the stack ( fp: p i n )
	;
	call	FloatSwap		; ( fp: p n i )
	call	FloatDrop		; ( fp: p n )
	call	FloatDivide		; ( fp: PMT )
	jmp	done
FunctionPMT	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionPV

DESCRIPTION:	Implements the PV() function
		PV(payments, interest, term) determines the present value
		of an investment.  PV calculates the present value based
		on a series of equal payments, discounted at a periodic
		interest rate over the number of periods.

		Let p = periodic payment
		    i = periodic interest rate
		    n = term
		
		PV = p * (1 - (1 + i)^-n) / i

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionPV	proc	near
	mov	ax, 3
	call	FunctionCheckNNonNegativeNumericArgs	; ( fp: p i n )
	jc	done

	; If the interest rate is zero, we have a much simpler formula
	; (result = P * N)
	;
	call	FloatOver		; ( fp: p i n i )
	call	FloatEq0		; ( fp: p i n )
	jc	intEqZero		; if zero, do something different

	call	FloatOver		; ( fp: p i n i )
	call	Float1
	call	FloatAdd		; ( fp: p i n i+1 )
	call	FloatOver		; ( fp: p i n i+1 n )
	call	FloatNegate		; ( fp: p i n i+1 -n )
	call	FloatExponential	; ( fp: p i n i+1^-n )
	call	FloatNegate
	call	Float1
	call	FloatAdd		; ( fp: p i n (1-(i+1^-n)) )
	call	FloatSwap
	call	FloatDrop		; ( fp: p i (1-(i+1^-n)) )
	call	FloatSwap		; ( fp: p (1-(i+1^-n)) i )
	call	FloatDivide		; ( fp: p (1-(i+1^-n))/i )
multiply:
	call	FloatMultiply		; PV

done:
	GOTO    FunctionCleanUpNumOp

intEqZero:
	; The interest rate is 0. Clean up the stack ( fp: p i n )
	;
	call	FloatSwap		; ( fp: p n i )
	call	FloatDrop		; ( fp: p n )
	jmp	multiply
FunctionPV	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionRandom

DESCRIPTION:	Implements the RANDOM() function.
		
		Generates a random value between 0 and 1.  Each time
		a recalculation is performed, a new random value is
		generated.

		RAND uses a linear congruential random number generator
		with period 2^32 to return successive pseudo-random numbers.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionRandom	proc	near
	call	FunctionCheck0Args
	jc	done			; branch if wrong number of arguments

	call	FloatRandom
done:
	GOTO    FunctionCleanUpNumOp
FunctionRandom	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionRandomN

DESCRIPTION:	Generates a random value between 0 and N-1.  Each time
		a recalculation is performed, a new random value is
		generated.

		RAND uses a linear congruential random number generator
		with period 2^32 to return successive pseudo-random numbers.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.
		N on the fp stack

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionRandomN	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatRandomN
done:
	GOTO    FunctionCleanUpNumOp
FunctionRandomN	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionRate

DESCRIPTION:	Implements the RATE() function
		RATE(future-value, present-value, term) calculates the
		periodic interest rate necessary for an investment to grow
		to a future-value over the number of compounding periods in
		term.

		Let fv = future value
		    pv = present value
		    n = term

		RATE =	(fv/pv)^(1/n) - 1

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionRate	proc	near
	mov	ax, 3
	call	FunctionCheckNNonNegativeNumericArgs
	jc	done

	; ( fp: fv pv n )
	call	FloatInverse		; ( fp: fv pv 1/n )
	call	FloatRot
	call	FloatRot		; ( fp: 1/n fv pv )
	call	FloatDivide		; ( fp: 1/n fv/pv )
	call	FloatSwap
	call	FloatExponential
	call	Float1
	call	FloatSub		; ( fp: RATE )

done:
	GOTO	FunctionCleanUpNumOp
FunctionRate	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionRound

DESCRIPTION:	Implements the ROUND() function.

		ROUND(x, n) rounds the value of x to n places.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionRound	proc	near	uses	cx
	.enter
	mov	al, 2
	call	FunctionCheckNNumericArgs
	jc	done

	call	GetByteArg		; ax <- int, dec cx
	jc	done

	call	FloatRound

done:
	jnc	quit

	call	PropogateError
quit:
	.leave
	ret
FunctionRound	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionRows

DESCRIPTION:	Implements the ROWS() function.

		ROWS(range) counts the number of rows in range.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionRows	proc	near	uses	dx
	.enter
	call	FunctionCheck1RangeArg
	jnc	10$

	mov	al, mask ESAT_NUMBER
	call	FunctionCheckArgType
	jc	done

	mov	ax, 1
	jmp	short 20$

10$:
	jc	done

	mov	ax, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_row
	and	ax, mask CRC_VALUE

	mov	dx, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_row
	and	dx, mask CRC_VALUE

	sub	ax, dx
	inc	ax
20$:
	call	FloatWordToFloat
	call	FloatAbs

done:
	call	FunctionCleanUpNumOp
	.leave
	ret
FunctionRows	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionSLN

DESCRIPTION:	Implements the SLN() function
		SLN(cost, salvage, life) calculates the straight -line
		depreciation allowance of an asset for one period.

		Let c = cost of asset
		    s = salvage value of asset
		    n = useful life of asset

		SLN = (c -s) / n.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionSLN	proc	near
	mov	ax, 3
	call	FunctionCheckNNonNegativeNumericArgs
	jc	done

	call	FloatSwap		; ( fp: c n s )
	call	FloatNegate		; ( fp: c n -s )
	call	FloatRot		; ( fp: n -s c )
	call	FloatAdd		; ( fp: n c-s )
	call	FloatSwap
	call	FloatDivide		; ( fp: SLN )
	
done:
	GOTO	FunctionCleanUpNumOp
FunctionSLN	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionSYD

DESCRIPTION:	Implements the SYD() function.
		SYD(cost, salvage, life, period) calculates the sum-of-the-
		years'-digits depreciation allowance of an asset for a
		specified period.

		Let c = cost of the asset
		    s = salvage value of the asset
		    n = calculated useful life of the asset
		    p = period for which depreciation is being calculated
		
			(c - s)*(n - p + 1)
		SYD =	-------------------
			    (n*(n+1)/2)

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionSYD	proc	near
	mov	ax, 4
	call	FunctionCheckNNonNegativeNumericArgs
	jc	done

	call	FloatNegate		; ( fp: c s n -p )
	call	Float1			; ( fp: c s n -p 1)
	call	FloatAdd		; ( fp: c s n -p+1)

	call	FloatOver
	call	FloatAdd		; ( fp: c s n n-p+1 )

	call	FloatSwap		; ( fp: c s n-p+1 n )
	call	FloatDup		; ( fp: c s n-p+1 n n )
	call	Float1			; ( fp: c s n-p+1 n n 1 )
	call	FloatAdd		; ( fp: c s n-p+1 n n+1 )
	call	FloatMultiply		; ( fp: c s n-p+1 n*(n+1) )
	call	FloatDivide2		; ( fp: c s n-p+1 n*(n+1)/2 )

	call	FloatDivide		; ( fp: c s (n-p+1)/(n*(n+1)/2) )
	call	FloatRot
	call	FloatRot		; ( fp: n' c s )

	call	FloatSub
	call	FloatMultiply

done:
	GOTO	FunctionCleanUpNumOp
FunctionSYD	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionTerm

DESCRIPTION:	Implements the TERM() function.
		TERM(payments, interest, future-value) calculates the number
		of payment periods in the term of an investment necessary
		to accumulate a future-value, assuming payments of equal value,
		when the investment earns a periodic interest rate.

		Let p = periodic payment
		    i = periodic interest rate
		    f = future value

			ln(1 + (f*i/p))
		TERM =	---------------
			  ln(1 + i)

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionTerm	proc	near
	mov	ax, 3
	call	FunctionCheckNNonNegativeNumericArgs
	jc 	done

	call	FloatRot		; ( fp: i f p )
	call	FloatDivide		; ( fp: i f/p )

	call	FloatSwap
	call	FloatDup		; ( fp: f/p i i )
	call	FloatLn1plusX		; ( fp: f/p i ln(1+i) )

	call	FloatRot
	call	FloatRot		; ( fp: ln(1+i) f/p i )
	call	FloatMultiply		; ( fp: ln(1+i) f/p*i )
	call	FloatLn1plusX
	call	FloatSwap
	call	FloatDivide		; ( fp: TERM )

done:
	GOTO    FunctionCleanUpNumOp
FunctionTerm	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionVLookup

DESCRIPTION:	Implements the VLOOKUP() function.

		VLOOKUP(x, range, colOffset) searches the leftmost column
		of an array for a particular value, and returns the value in
		the cell indicated.

		A vertical lookup table is a range with value information
		in ascending order in the leftmost column.

		VLOOKUP compares the value x to each cell in the leftmost
		column of the table.  When a cell is located in the left column
		that contains the value x (or the value closest to, but not
		larger than x) it moves down that row the number of columns
		specified by colOffset and returns the contents of the cell
		as the answer.

		X can be any value greater than or equal to the first value in
		the range.  If x is smaller than the first value in the range,
		an error is returned. If x is larger than the last value in
		range, VLOOKUP stops at the last cell in the row and returns
		the contents of that cell.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionVLookup	proc	near	uses	cx,dx,si
	mov	ax, bp
	FV_local	local	rangeInfoStruct
	.enter

	mov	si, ax			; ss:si <- EvalParameters

	mov	al, 3
	call	FunctionCheckNArgs
	jc	done

	;-----------------------------------------------------------------------
	; get colOffset

	call	GetWordArg		; ax <- int, dec cx
	jc	done

	mov	FV_local.RIS_colOffset, ax

	;-----------------------------------------------------------------------
	; get range info

	test	es:[bx].ASE_type, mask ESAT_RANGE
	je	err

	mov	ax, si			; ax <- original bp
	call	InitRangeInfo		; get range bounds, destroys ax
	call	Pop1Arg			; lose the range
	dec	cx			; dec arg count

	;-----------------------------------------------------------------------
	; see that offset is in range bounds

	mov	ax, FV_local.RIS_columnLeft
	add	ax, FV_local.RIS_colOffset
	cmp	ax, FV_local.RIS_columnRight
	ja	err

	;-----------------------------------------------------------------------
	; things check out, now conduct search

	mov	al, mask LSF_VERTICAL	; specify VLOOKUP
	call	FunctionLookupDoSearch
	jmp	short done

err:
	mov	al, PSEE_GEN_ERR
	stc
done:
	jnc	quit

	push	bp
	mov	bp, si			; ss:bp <- EvalParameters
	call	PropogateError
	pop	bp
quit:
	.leave
	ret
FunctionVLookup	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLookupDoSearch

DESCRIPTION:	Search the column or row for the value that is on the
		top of the stack.
		
		Notes:

		* Values are assumed to be in ascending order. Ie. -2, -1,
		0..., A - Z, FALSE, TRUE.  FunctionLookupDoSearch will not
		return the correct value otherwise.

		* values that can be searched for are text, numbers or
		logical values.

		* upper and lower case text are equivalent

		* if the value cannot be found, the largest value that is
		less than or equal to the value will be returned

CALLED BY:	INTERNAL ()

PASS:		al - LookupSearchFlags
		     LSF_VERTICAL
		carry clear if successful
		carry set if error
		    al - error code (ParserScannerEvaluatorError)

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

loop:
	dereference the current cell
	do a "no-drop" comparison
	if exact match then {
	    drop arg
	} else if search value is less than cell contents then {
	    drop args
	    if there aren't any cell contents saved then
		error
	    else
	        push the contents of the cell that was saved onto the stack
	} else {		; search value > cell contents
	    save top of stack
	    drop arg
	    next cell
	    goto loop
	}
	return top of argument stack

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

FunctionLookupDoSearch	proc	near
	FL_local	local	rangeInfoStruct
	.enter	inherit near

	mov	FL_local.RIS_searchFlag, al	; save flags

	mov	ax, FL_local.RIS_rowTop		; start at topmost
	mov	FL_local.RIS_curRow, ax

	mov	ax, FL_local.RIS_columnLeft	; start at leftmost
	mov	FL_local.RIS_curCol, ax

locateLoop:
	;-----------------------------------------------------------------------
	; dereference cell and perform comparison

	call	FunctionLookupDerefCell
	mov	cx, 1
	jc	err				; exit if error

	call	FunctionLookupDoCompare		; flags set to (value - cell)
	lahf					; save flags from comp
	tst	al				; any error?
	jne	errDrop2			; exit if error
	sahf					; else retrieve flags

	jl	valueIsLessThan
	jg	valueIsGreater

;match:
	;-----------------------------------------------------------------------
	; match found

	mov	cx, 2
	call	StacksDropNArgs			; both args are equal, lose one
	jmp	short found

errDrop2:
	mov	cx, 2				; lose both args
err:
	call	StacksDropNArgs
	stc
	jmp	short exit

valueIsLessThan:
	;-----------------------------------------------------------------------
	; search value is less than current cell contents

	mov	cx, 2				; lose both args
	call	StacksDropNArgs
	jmp	short foundBackup

valueIsGreater:
	;-----------------------------------------------------------------------
	; search value is greater than current cell contents
	; lose the cell contents and move on to the next cell

	call	StacksDropArg		; lose the cell contents

	call	FunctionLookupGetNextCell
	jnc	locateLoop

	;
	; value is greater than the contents of the cells in the range
	;
	call	StacksDropArg

foundBackup:
	;
	; we will back up
	; that will be our target row (VLOOKUP) or column (HLOOKUP)
	;
	call	FunctionLookupGetPrevCell
	jc	exit

found:
	call	FunctionLookupAddOffset
	call	FunctionLookupDerefCell
	jc	exit

	clr	ax			; operation clears carry as well
exit:
	.leave
	ret
FunctionLookupDoSearch	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLookupDerefCell

DESCRIPTION:	Dereference the current cell.

CALLED BY:	INTERNAL ()

PASS:		RangeInfoStruct stack frame
		es:bx	= Pointer to the argument stack
		es:di	= Pointer to operator/function stack

RETURN:		carry set on error
		    al - error code (ParserScannerEvaluatorError)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

FunctionLookupDerefCell	proc	near	uses	cx,dx
	FL_local	local	rangeInfoStruct
	.enter	inherit near

	;-----------------------------------------------------------------------
	; get contents of the cell
	;
	; pass:
	;	es:bx	= Pointer to the argument stack
	;	es:di	= Pointer to operator/function stack
	;	ss:bp	= Pointer to EvalParameters
	;	dx	= Row of the cell to dereference
	;	cx	= Column of the cell to dereference
	; return:
	;	es:bx	= New pointer to the argument stack
	;	carry set on error
	;	   al	= Error code

	mov	dx, FL_local.RIS_curRow
	mov	cx, FL_local.RIS_curCol
	push	bp
	mov	bp, FL_local.RIS_saveBP	; ss:bp <- EvalParameters
	mov	ch, mask DF_DONT_POP_ARGUMENT
	mov	al, CT_DEREF_CELL	; push the cell data
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[bp].CP_callback
endif
	pop	bp

	.leave
	ret
FunctionLookupDerefCell	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLookupDoCompare

DESCRIPTION:	Do a comparison of the top two elements of the argument stack.
		Strings and numbers are compared.  All others generate errors.
		Case in string comparison is ignored.

CALLED BY:	INTERNAL ()

PASS:		RangeInfoStruct stack frame
		es:bx	= Pointer to the argument stack
		es:di	= Pointer to operator/function stack

RETURN:		carry set on error
		    al - error code (ParserScannerEvaluatorError)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

FunctionLookupDoCompare	proc	near
	.enter
	test	es:[bx].ASE_type, mask ESAT_NUMBER
	jne	number

	test	es:[bx].ASE_type, mask ESAT_STRING
	jne	string

	;
	; return error
	;
	mov	al, PSEE_WRONG_TYPE
	stc
	jmp	short exit

number:
	;-----------------------------------------------------------------------
	; dealing with numbers

	;
	; check to see that the first arg is a number as well
	;
	push	bx
	call	Pop1Arg
	mov	al, mask ESAT_NUMBER
	call	FunctionCheckArgType		; else go check type
	pop	bx
	jc	exit

	;
	; perform comparison
	;
	call	FloatComp
	jmp	short doneOK

string:
	;-----------------------------------------------------------------------
	; dealing with strings
	; perform a comparison without consideration of case

	;
	; check to see that the first arg is a string as well
	;
	push	bx
	call	Pop1Arg
	mov	al, mask ESAT_STRING
	call	FunctionCheckArgType		; else go check type
	pop	bx
	jc	exit

	;
	; perform comparison
	;
	push	bx,dx,ds,si,es,di
	segmov	ds,es,si

	lea	di, es:[bx].ASE_data.ESAD_string.ESD_length+2	; es:di <- s2
	mov	dx, es:[bx].ASE_data.ESAD_string.ESD_length	; dx <- len(s2)
	call	Pop1Arg
	lea	si, es:[bx].ASE_data.ESAD_string.ESD_length+2	; ds:si <- s1
	mov	cx, es:[bx].ASE_data.ESAD_string.ESD_length	; cx <- len(s1)

	;
	; If lengths are different, we have a problem because of the
	; possibility of prefixes, eg. "ABC" and "ABCZ"
	; Solution:
	;	use the shorter length.
	;	if the strings are equal, then change the flags
	;
	cmp	cx, dx
	je	doStraightCmp
	jl	s1ShorterThanS2

	;-----------------------------------------------------------------------
	; len(s1) > len(s2)

	mov	cx, dx
	call	LocalCmpStringsNoCase
	jne	doneString			; branch if flags are correct

	;
	; s1 has a prefix of len(s2) than matches s2
	; make s1 greater than s2
	;
	cmp	cx, 0				; set greater than flags
	jmp	short doneString

s1ShorterThanS2:
	;-----------------------------------------------------------------------
	; len(s1) < len(s2)

	call	LocalCmpStringsNoCase
	jne	doneString			; branch if flags are correct

	;
	; s2 has a prefix of len(s1) that matches s1
	; make s1 less than s2
	;

	cmp	cx, dx				; set less than flags
	jmp	short doneString

doStraightCmp:
	call	LocalCmpStringsNoCase

doneString:
	pop	bx,dx,ds,si,es,di

doneOK:
	mov	al, 0			; don't nuke carry

exit:
	.leave
	ret
FunctionLookupDoCompare	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLookupGetPrevCell

DESCRIPTION:	Decrements the proper field in the stack frame so that the
		previous cell in the LOOKUP sequence will be current.  This
		cell will then be dereferenced.

CALLED BY:	INTERNAL ()

PASS:		rangeInfoStruct stack frame
		es:bx	= Pointer to the argument stack
		es:di	= Pointer to operator/function stack

RETURN:		carry clear if successful
		carry set otherwise
		    al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionLookupGetPrevCell	proc	near
	FL_local	local	rangeInfoStruct
	.enter	inherit near

	;
	; if cell is the first then we have an error
	;
	mov	ax, FL_local.RIS_curRow
	cmp	ax, FL_local.RIS_rowTop
	jne	notFirstCell

	mov	ax, FL_local.RIS_curCol
	cmp	ax, FL_local.RIS_columnLeft
	je	err

notFirstCell:
	test	FL_local.RIS_searchFlag, mask LSF_VERTICAL	; VLOOKUP?
	jne	decRow			; branch if so

	dec	FL_local.RIS_curCol	; HLOOKUP, get prev column
	jmp	short done

decRow:
	dec	FL_local.RIS_curRow	; VLOOKUP, get prev row

done:
	.leave
	ret

err:
	mov	al, PSEE_GEN_ERR
	stc
	jmp	short done
FunctionLookupGetPrevCell	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLookupGetNextCell

DESCRIPTION:	Increments the proper field in the stack frame so that the
		next cell in the LOOKUP sequence will be current.

CALLED BY:	INTERNAL ()

PASS:		rangeInfoStruct stack frame

RETURN:		carry clear if next cell gotten
		carry set if LOOKUP complete

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionLookupGetNextCell	proc	near
	FL_local	local	rangeInfoStruct
	.enter	inherit near

	test	FL_local.RIS_searchFlag, mask LSF_VERTICAL	; VLOOKUP?
	jne	incRow			; branch if so

	;
	; HLOOKUP
	;
	inc	FL_local.RIS_curCol	; next column
	mov	ax, FL_local.RIS_curCol	; ax <- column
	cmp	ax, FL_local.RIS_columnRight	; done?
	ja	lookupComplete
	jmp	short nextCellGotten

incRow:
	;
	; VLOOKUP
	;
	inc	FL_local.RIS_curRow	; next row
	mov	ax, FL_local.RIS_curRow	; ax <- row
	cmp	ax, FL_local.RIS_rowBot	; done?
	ja	lookupComplete

nextCellGotten:
	clc

exit:
	.leave
	ret

lookupComplete:
	stc
	jmp	short exit

FunctionLookupGetNextCell	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLookupAddOffset

DESCRIPTION:	The target row (VLOOKUP) or column (HLOOKUP) has been found.
		Add the offset to get the target cell.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		rangeInfoStruct stack frame

RETURN:		RIS_curRow / RIS_curCol with the offset incorporated

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionLookupAddOffset	proc	near
	FL_local	local	rangeInfoStruct
	.enter	inherit near

	test	FL_local.RIS_searchFlag, mask LSF_VERTICAL	; VLOOKUP?
	jne	addToCol			; branch if so

	;
	; HLOOKUP, add to row
	;
	mov	ax, FL_local.RIS_rowOffset
	add	FL_local.RIS_curRow, ax
	jmp	short done

addToCol:
	;
	; VLOOKUP, add to column
	;
	mov	ax, FL_local.RIS_colOffset
	add	FL_local.RIS_curCol, ax

done:
	.leave
	ret
FunctionLookupAddOffset	endp


EvalCode	ends
