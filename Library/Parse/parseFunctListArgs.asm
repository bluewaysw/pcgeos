COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Parse Library
FILE:		parseFunctListArgs.asm

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

	$Id: parseFunctListArgs.asm,v 1.1 97/04/05 01:27:31 newdeal Exp $

-------------------------------------------------------------------------------@


EvalCode	segment resource

;*******************************************************************************
;	ROUTINES THAT TAKE A LIST OF ARGUMENTS
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionAvg

DESCRIPTION:	Implements the AVG() function.

CALLED BY:	PopOperatorAndEval via functionHandlers

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

FunctionAvg	proc	near
	mov	ax, bp
	FA_local	local	functionEnv
	.enter

	call	InitFunctionEnv

	mov	FA_local.FE_argProcessingRoutine.handle, handle FloatAdd
	mov	FA_local.FE_argProcessingRoutine.offset, offset FloatAdd
	mov	FA_local.FE_argsReqForProcRoutine, 2
	mov	FA_local.FE_returnSingleArg, 0ffh
	mov	FA_local.FE_ignoreEmpty, 0ffh
	call	ProcessListOfArgs
	jc	done

	mov	ax, FA_local.FE_cellCount
	call	FloatWordToFloat
	call	FloatDivide

done:
	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionAvg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCount

SYNOPSIS:	Implements the COUNT() function.

CALLED BY:	PopOperatorAndEval via functionHandlers

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

FunctionCount	proc	near
	mov	ax, bp
	FC_local	local	functionEnv
	.enter

	call	InitFunctionEnv

	mov	FC_local.FE_nearRoutine, 0ffh
	mov	FC_local.FE_argProcessingRoutine.handle, offset CountCallback
	mov	FC_local.FE_argsReqForProcRoutine, 0
	mov	FC_local.FE_ignoreEmpty, 0ffh
	mov	FC_local.FE_nonNumsOK, 0ffh
	call	CountNonEmptyInListOfArgs
	jc	done

	mov	ax, FC_local.FE_numCount
	call	FloatWordToFloat

done:
	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionCount	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CountCallback

DESCRIPTION:	Drops argument off stack, since it is not needed.

CALLED BY:	INTERNAL (DoOperation)

PASS:		functionEnv on stack

RETURN:		carry clear

DESTROYED:	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

CountCallback	proc	near	uses	es
	CC_local	local	functionEnv
	.enter	inherit	near

	test	CC_local.FE_curArgType, mask ESAT_NUMBER
	jz	notNumber
	call	FloatDrop

notNumber:
	clc

	.leave
	ret
CountCallback	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionMax

SYNOPSIS:	Implements the MAX() function.

CALLED BY:	PopOperatorAndEval via functionHandlers

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

FunctionMax	proc	near
	mov	ax, bp
	FM_local	local	functionEnv
	.enter

	call	InitFunctionEnv

	mov	FM_local.FE_argProcessingRoutine.handle, handle FloatMax
	mov	FM_local.FE_argProcessingRoutine.offset, offset FloatMax
	mov	FM_local.FE_argsReqForProcRoutine, 2
	mov	FM_local.FE_returnSingleArg, 0ffh
	mov	FM_local.FE_ignoreEmpty, 0ffh
	call	ProcessListOfArgs

	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionMax	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionMin

SYNOPSIS:	Implements the MIN() function.

CALLED BY:	PopOperatorAndEval via functionHandlers

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

FunctionMin	proc	near	uses	cx
	mov	ax, bp
	FM_local	local	functionEnv
	.enter

	call	InitFunctionEnv

	mov	FM_local.FE_argProcessingRoutine.handle, handle FloatMin
	mov	FM_local.FE_argProcessingRoutine.offset, offset FloatMin
	mov	FM_local.FE_argsReqForProcRoutine, 2
	mov	FM_local.FE_returnSingleArg, 0ffh
	mov	FM_local.FE_ignoreEmpty, 0ffh
	call	ProcessListOfArgs

	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionMin	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionProduct

SYNOPSIS:	Multiplies its arguments.

CALLED BY:	PopOperatorAndEval via functionHandlers

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

FunctionProduct	proc	near	uses	cx
	mov	ax, bp
	FP_local	local	functionEnv
	.enter

	call	InitFunctionEnv

	mov	FP_local.FE_argProcessingRoutine.handle, handle FloatMultiply
	mov	FP_local.FE_argProcessingRoutine.offset, offset FloatMultiply
	mov	FP_local.FE_argsReqForProcRoutine, 2
	mov	FP_local.FE_ignoreEmpty, 0ffh
	call	ProcessListOfArgs
	jc	done

	cmp	FP_local.FE_cellCount, 2
	jae	done				; carry is clear (JAE = JNC)

	; carry is set
	mov	al, PSEE_BAD_ARG_COUNT

done:
	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionProduct	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionStd, FunctionStdP

SYNOPSIS:	Implements the STD() and STDP() functions.
		Calculate the population standard deviation of the values
		in the list.

		STDP assumes that its arguments are the entire population.
		If the data represents a sample of the entire population,
		use STD instead.

		STD = SQRT( VAR(list) )
		STDP = SQRT( VARP(list) )

CALLED BY:	PopOperatorAndEval via functionHandlers

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

SqrtOrZero	proc	near
	;
	; There are cases where the variance should be zero
	; (e.g., STD(2.11, 2.11, 2.11), but is instead calculated
	; as a very small negative number close to zero. We check
	; for those and return zero.
	;
	call	FloatDup
	call	FloatLt0				;less than zero?
	jnc	done					;branch if not
	call	FloatDrop
	call	Float0					;return zero
done:
	call	FloatSqrt
	ret
SqrtOrZero	endp

FunctionStd	proc	near	uses	cx
	mov	ax, bp
	FS_local	local	functionEnv
	.enter

	call	InitFunctionEnv
	mov	FS_local.FE_miscFlag, 0

	call	FunctionVarLow
	jc	done

	call	SqrtOrZero

done:
	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionStd	endp

FunctionStdP	proc	near	uses	cx
	mov	ax, bp
	FS_local	local	functionEnv
	.enter

	call	InitFunctionEnv
	mov	FS_local.FE_miscFlag, mask VF_FOR_ENTIRE_POPULATION

	call	FunctionVarLow
	jc	done

	call	SqrtOrZero

done:
	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionStdP	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionSum

SYNOPSIS:	Implements the SUM() function.
		SUM(list) adds the values in list.

CALLED BY:	PopOperatorAndEval via functionHandlers

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

FunctionSum	proc	near	uses	cx
	mov	ax, bp
	FS_local	local	functionEnv
	.enter

	call	InitFunctionEnv

	mov	FS_local.FE_argProcessingRoutine.handle, handle FloatAdd
	mov	FS_local.FE_argProcessingRoutine.offset, offset FloatAdd
	mov	FS_local.FE_argsReqForProcRoutine, 2
	mov	FS_local.FE_returnSingleArg, 0ffh
;	mov	FS_local.FE_ignoreEmpty, 0ffh
	call	ProcessListOfArgs

	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionSum	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionVar, FunctionVarP

SYNOPSIS:	Implements the VAR() and VARP() function.
		Calculate the population variance of the values in the list.

		VARP assumes that its arguments are the entire population.
		If the data represents a sample of the entire population,
		use VAR instead.

CALLED BY:	PopOperatorAndEval via functionHandlers

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

FunctionVar	proc	near	uses	cx
	mov	ax, bp
	FV_local	local	functionEnv
	.enter

	call	InitFunctionEnv
	mov	FV_local.FE_miscFlag, 0

	call	FunctionVarLow

	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionVar	endp

FunctionVarP	proc	near	uses	cx
	mov	ax, bp
	FV_local	local	functionEnv
	.enter

	call	InitFunctionEnv
	mov	FV_local.FE_miscFlag, mask VF_FOR_ENTIRE_POPULATION

	call	FunctionVarLow

	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	ret
FunctionVarP	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionVarLow

DESCRIPTION:	Routine common to FunctionStd and FunctionVar.

CALLED BY:	INTERNAL (FunctionStd, FunctionVar)

PASS:		initialized functionEnv stack frame
		FE_miscFlag - VarianceFlags

		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:ax	- pointer to EvalParameters on the stack.

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

FunctionVarLow	proc	near

	FVL_local	local	functionEnv

	.enter inherit near

	mov	FVL_local.FE_nearRoutine, 0ffh
	mov	FVL_local.FE_argProcessingRoutine.handle, offset VarCallback
	mov	FVL_local.FE_argsReqForProcRoutine, 1
	mov	FVL_local.FE_ignoreEmpty, 0ffh
	call	ProcessListOfArgs
	LONG jc	done

	cmp	FVL_local.FE_cellCount, 2
	jae	ok

	;
	; carry is set (JAE = JNC)
	;
	mov	al, PSEE_BAD_ARG_COUNT
	jmp	done

ok:
	;
	; retrieve intermediate results from the stack frame
	;
	push	ds,si
	segmov	ds,ss,si
	lea	si, FVL_local.FE_result1	; push sum
	call	FloatPushNumber
	lea	si, FVL_local.FE_result2	; push sqr
	call	FloatPushNumber
	pop	ds,si

	mov	ax, FVL_local.FE_cellCount
	call	FloatWordToFloat

	call	FloatOver		; ( fp: sum sqr n sqr )
	call	FloatOver		; ( fp: sum sqr n sqr n )
	call	FloatMultiply		; ( fp: sum sqr n nsqr )

	mov	bx, 4
	call	FloatPick		; ( fp: sum sqr n nsqr sum )
	call	FloatSqr		; ( fp: sum sqr n nsqr sum^2 )
	call	FloatSub		; ( fp: sum sqr n nsqr-sum^2 )

	call	FloatSwap		; ( fp: sum sqr nsqr-sum^2 n )

	test	FVL_local.FE_miscFlag, mask VF_FOR_ENTIRE_POPULATION
	je	notEntirePop

	call	FloatSqr
	jmp	short doDivide

notEntirePop:
	call	FloatDup		; ( fp: sum sqr nsqr-sum^2 n n )
	call	FloatSqr		; ( fp: sum sqr nsqr-sum^2 n n^2 )
	call	FloatSwap		; ( fp: sum sqr nsqr-sum^2 n^2 n )
	call	FloatSub		; ( fp: sum sqr nsqr-sum^2 n^2-n )

doDivide:
	call	FloatDivide		; ( fp: sum sqr Var )

	call	FloatRot		; ( fp: sqr Var sum )
	call	FloatDrop
	call	FloatSwap		; ( fp: Var sum )
	call	FloatDrop		; ( fp: Var )

	mov	bx, FVL_local.FE_argStack.offset	; restore bx
done:
	.leave
	ret
FunctionVarLow	endp


VarCallback	proc	near	uses	es,di
	VC_local	local	functionEnv
	.enter inherit near

	mov	di, ss			; di <- ss

	cmp	VC_local.FE_cellCount, 1
	jne	trackArgs

	;
	; very first number, set fp stack up to track the
	;     * sum of the numbers
	;     * sum of the squares of the numbers
	;
	call	FloatDup		; ( fp: # # )
	call	FloatSqr		; ( fp: # #^2 )
	jmp	short done

trackArgs:
	;
	; subsequent (ie. not the first) numbers, track sum and sum of squares
	;
	push	ds,si
	mov	ds, di			; ds <- ss

	call	FloatDup		; ( fp: # # )
	lea	si, VC_local.FE_result1
	call	FloatPushNumber		; ( fp: # # sum )
	call	FloatAdd		; ( fp: # sum' )

	call	FloatSwap		; ( fp: sum' # )
	call	FloatSqr		; ( fp: sum' #^2 )
	lea	si, VC_local.FE_result2
	call	FloatPushNumber		; ( fp: sum' #^2 sqr )
	call	FloatAdd
	pop	ds,si
	
done:
	mov	es, di				; es <- ss
	lea	di, VC_local.FE_result2		; save sqr
	call	FloatPopNumber
	lea	di, VC_local.FE_result1		; save sum
	call	FloatPopNumber

	.leave
	ret
VarCallback	endp

EvalCode	ends
