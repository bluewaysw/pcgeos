COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Parse Library
FILE:		parseFunctSingleArgs.asm

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

	$Id: parseFunctSingleArgs.asm,v 1.1 97/04/05 01:27:34 newdeal Exp $

-------------------------------------------------------------------------------@

EvalCode	segment resource


;*******************************************************************************
;	ROUTINES THAT TAKE ONE NUMERIC ARGUMENT
;*******************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FunctionDegrees
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implement the DEGREES() function (convert radians to degrees)

CALLED BY:	PopOperatorAndEval()
PASS:		es:bx - pointer to top of argument stack
		cx - # of arguments passed to function
		ss:bp - EvalParameters on stack
RETURN:		es:bx - pointer to new top of argument stack
		carry - set if error
			al - error code (ParserScannerEvaluatorError)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FunctionDegrees		proc	near
	call	FunctionCheck1NumericArg
	jc	numArgs				;branch if wrong # of args

	push	ds, si
	segmov	ds, cs
	mov	si, offset toDegreesValue	;ds:si <- FloatNum
FXIP <	push	cx							>
FXIP <	mov	cx, size FloatNum		; # bytes to copy	>
FXIP <	call	SysCopyToStackDSSI		; ds:si = data on stack	>
FXIP <	pop	cx							>
	call	FloatPushNumber
	call	FloatMultiply
FXIP <	call	SysRemoveFromStack		; release stack space	>
	pop	ds, si
numArgs:
	GOTO    FunctionCleanUpNumOp
FunctionDegrees		endp

toDegreesValue	FloatNum <0xbdc3, 0x1e0f, 0xe0d3, 0xe52e, 0x4004>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FunctionRadians
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implement the RADIANS() function (convert degrees to radians)

CALLED BY:	PopOperatorAndEval()
PASS:		es:bx - pointer to top of argument stack
		cx - # of arguments passed to function
		ss:bp - EvalParameters on stack
RETURN:		es:bx - pointer to new top of argument stack
		carry - set if error
			al - error code (ParserScannerEvaluatorError)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FunctionRadians	proc	near
	call	FunctionCheck1NumericArg
	jc	numArgs				;branch if wrong # of args

	push	ds, si
	segmov	ds, cs
	mov	si, offset toRadiansValue	;ds:si <- FloatNum
FXIP <	push	cx							>
FXIP <	mov	cx, size FloatNum		; # bytes to copy	>
FXIP <	call	SysCopyToStackDSSI		; ds:si = data on stack	>
FXIP <	pop	cx							>
	call	FloatPushNumber
	call	FloatMultiply
FXIP <	call	SysRemoveFromStack		; release stack space	>
	pop	ds, si
numArgs:
	GOTO    FunctionCleanUpNumOp
FunctionRadians		endp

toRadiansValue	FloatNum <0xc8ae, 0x94e9, 0x3512, 0x8efa, 0x3ff9>

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionAbs

DESCRIPTION:	Implements the ABS() function

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

FunctionAbs	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatAbs
done:
	GOTO    FunctionCleanUpNumOp
FunctionAbs	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionACos

DESCRIPTION:	Implements the ACOS() function

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

FunctionACos	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatArcCos
done:
	GOTO    FunctionCleanUpNumOp
FunctionACos	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionACosh

DESCRIPTION:	Implements the ACOSH() function

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

FunctionACosh	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatArcCosh
done:
	GOTO    FunctionCleanUpNumOp
FunctionACosh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionASin

DESCRIPTION:	Implements the ASIN() function

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

FunctionASin	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatArcSin
done:
	GOTO    FunctionCleanUpNumOp
FunctionASin	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionASinh

DESCRIPTION:	Implements the ASINH() function

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

FunctionASinh	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatArcSinh
done:
	GOTO    FunctionCleanUpNumOp
FunctionASinh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionATan

DESCRIPTION:	Implements the ATAN() function

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

FunctionATan	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatArcTan
done:
	GOTO    FunctionCleanUpNumOp
FunctionATan	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionATanh

DESCRIPTION:	Implements the ATANH() function

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

FunctionATanh	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatArcTanh
done:
	GOTO    FunctionCleanUpNumOp
FunctionATanh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCos

DESCRIPTION:	Implements the COS() function

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

FunctionCos	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatCos
done:
	GOTO    FunctionCleanUpNumOp
FunctionCos	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCosh

DESCRIPTION:	Implements the COSH() function

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

FunctionCosh	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatCosh
done:
	GOTO    FunctionCleanUpNumOp
FunctionCosh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionExp

DESCRIPTION:	Implements the EXP() function

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

FunctionExp	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatExp
done:
	GOTO    FunctionCleanUpNumOp
FunctionExp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionInt

DESCRIPTION:	Implements the INT() function

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

FunctionInt	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatInt
done:
	GOTO    FunctionCleanUpNumOp
FunctionInt	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLn

DESCRIPTION:	Implements the LN() function

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

FunctionLn	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatLn
done:
	GOTO    FunctionCleanUpNumOp
FunctionLn	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLog

DESCRIPTION:	Implements the LOG() function

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

FunctionLog	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatLog
done:
	GOTO    FunctionCleanUpNumOp
FunctionLog	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionSin

DESCRIPTION:	Implements the SIN() function

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

FunctionSin	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatSin
done:
	GOTO	FunctionCleanUpNumOp
FunctionSin	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionSinh

DESCRIPTION:	Implements the SINH() function

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

FunctionSinh	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatSinh
done:
	GOTO    FunctionCleanUpNumOp
FunctionSinh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionSqrt

DESCRIPTION:	Implements the SQRT() function

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

FunctionSqrt	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatSqrt
done:
	GOTO    FunctionCleanUpNumOp
FunctionSqrt	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionTan

DESCRIPTION:	Implements the TAN() function

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

FunctionTan	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatTan
done:
	GOTO	FunctionCleanUpNumOp
FunctionTan	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionTanh

DESCRIPTION:	Implements the TANH() function

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

FunctionTanh	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatTanh
done:
	GOTO    FunctionCleanUpNumOp
FunctionTanh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionTrunc

DESCRIPTION:	Implements the TRUNC() function.
		TRUNC() truncates a number by removing the fractional part.

		TRUNC(7.8) equals 7
		TRUNC(-7.8) equals -7

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

FunctionTrunc	proc	near
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatTrunc
done:
	GOTO	FunctionCleanUpNumOp
FunctionTrunc	endp

EvalCode	ends
