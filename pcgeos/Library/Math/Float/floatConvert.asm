
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		floatConvert.asm

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name				Description
	----				-----------
	FloatAsciiToFloat		- Global
	FloatAsciiToInteger
	FloatAsciiToFraction
	NextDigit
	ConvertDigit
	NextNonSpaceChar
	NextChar
	UngetChar
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision
	witt	10/93		DBCS-ized character getting and putting.

DESCRIPTION:

	$Id: floatConvert.asm,v 1.1 97/04/05 01:22:57 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatAsciiToFloat (originally STRM->FP#)

DESCRIPTION:	Given a parsed string, convert it into a floating point
		number.

CALLED BY:	GLOBAL ()

PASS:		al - FloatAsciiToFloatFlags
		    FAF_PUSH_RESULT - place result onto the fp stack
		    FAF_STORE_NUMBER - store result into the location given by
			es:di
		cx - number of characters in the string that the routine
		    should concern itself with
		ds:si - string in this format:

		    "[+-] dddd.dddd [Ee] [+-] dddd"

		    Notes:
		    ------

		    * The string is assumed to be legal because duplicating
		    the error checking that is done in the parser seems
		    unnecessary.

		    * There can be at most a single decimal point.

		    * Spaces and thousands seperators are ignored.

RETURN:		carry clear if successful
		carry set if error

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	convert pre-exponent portion into a float
	keep track of the number of digits after the decimal
	convert the exponent
	modify the exponent based on the number of digits after the decimal
	incorporate the exponent into the float
	store the result

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FAF_stackFrame	struct
	resultFlag	FloatAsciiToFloatFlags
				  ; how the resulting number should be stored
	sourceAddr	fptr.char ; address of string
	resultAddr	fptr.char ; result to be placed here if so specified
	numChars	byte	; number of characters in the string
	numCharsRead	byte	; number of characters processed
	negNum		byte	; boolean - number is negative
	negExp		byte	; boolean - number has a negative exponent
SBCS<	thousandsSep	char	; char - the thousands seperator	>
DBCS<	thousandsSep	wchar	; wchar - the thousands seperator	>
SBCS<	decimalSep	char	; char - the decimal seperator	>
DBCS<	decimalSep	wchar	; wchar - the decimal seperator	>
	errorFlag	byte	; boolean - error encountered
	errorType	word	; unused right now
FAF_stackFrame	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatAsciiToFloatInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	internal call to FloatAsciiToFloat
CALLED BY:	GLOBAL

		see header directly above for details
		exported for coprocessor libriaries		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global FloatAsciiToFloatInternal:far
FloatAsciiToFloatInternal	proc	far
	call	FloatAsciiToFloat
	ret
FloatAsciiToFloatInternal	endp

FloatAsciiToFloat	proc	far	uses	ax,bx,cx,dx,ds,di,si

	FAF_local	local	FAF_stackFrame

	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the passed float point string is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif

EC<	push	ax >
EC<	test	al, not (mask FAF_PUSH_RESULT or mask FAF_STORE_NUMBER) >
EC<	ERROR_NZ	FLOAT_BAD_FLAGS >
EC<	test	al, mask FAF_PUSH_RESULT >
EC<	je	ok >
EC<	test	al, mask FAF_STORE_NUMBER >
EC<	ERROR_NZ	FLOAT_BAD_FLAGS >
EC< ok: >
EC<	pop	ax >

	;-----------------------------------------------------------------------
	; initialize vars and such

	mov	FAF_local.resultFlag, al
	mov	FAF_local.numChars, cl
	mov	FAF_local.sourceAddr.offset, si
	mov	FAF_local.sourceAddr.segment, ds
	mov	FAF_local.resultAddr.offset, di
	mov	FAF_local.resultAddr.segment, es

	clr	ax
	mov	FAF_local.numCharsRead, al
	mov	FAF_local.negNum, al
	mov	FAF_local.negExp, al
	mov	FAF_local.errorFlag, al
	mov	FAF_local.errorType, ax

	;
	; get local chars
	;
	; DR_LOCAL_GET_NUMERIC_FORMAT

	call	FloatGetDecimalSeperator
SBCS<	mov	FAF_local.decimalSep, al			>
DBCS<	mov	FAF_local.decimalSep, ax			>

	call	FloatGetThousandsSeperator
SBCS<	mov	FAF_local.thousandsSep, al			>
DBCS<	mov	FAF_local.thousandsSep, ax			>

	;-----------------------------------------------------------------------
	; start conversion

	call	FloatEnter			; ds <- fp stack seg

	call	NextNonSpaceChar		; al <- char
	LocalCmpChar	ax, '+'
	je	convertInt

	LocalCmpChar	ax, '-'
	je	negNumber

	call	UngetChar
	jmp	short convertInt

negNumber:
	dec	FAF_local.negNum

convertInt:
	call	FloatAsciiToInteger		; al <- non-numeric ASCII char

	LocalCmpChar	ax, FAF_local.decimalSep
	jne	fractionProcessed

	call	FloatAsciiToFraction		; al <- non-numeric ASCII char
	push	ax				; save it
	call	FloatAdd
	pop	ax

fractionProcessed:
	;
	; al = non-numeric ASCII char
	;
	LocalCmpChar	ax, 'E'
	je	processExp

	LocalCmpChar	ax, 'e'
	je	processExp

	LocalIsNull	ax
	je	doneConvert			; we're done

errorFound:
	dec	FAF_local.errorFlag		; note error
	jmp	short doneConvert		; store what results we have

	;-----------------------------------------------------------------------
	; deal with exponent here

processExp:
	;
	; check for sign
	;
	call	NextDigit			; al <- digit
	jc	processSign			; branch if non-digit

	call	UngetChar
	jmp	short convertExp

processSign:
	LocalCmpChar	ax, '+'
	je	convertExp

	LocalCmpChar	ax, '-'
	jne	errorFound

	dec	FAF_local.negExp

convertExp:
	call	FloatAsciiToInteger
	tst	al
	je	terminationOK
	
	dec	FAF_local.errorFlag		; note error found

terminationOK:
	;
	; ( fp: mantissa exponent )
	;
	call	FloatFloatToDword		; dx:ax <- exponent

	;-----------------------------------------------------------------------
	; limit checks...

	tst	dx
	js	expIsNegative			; branch if negative
	jne	posExpError			; if <>0, out of range for sure

	cmp	ax, DECIMAL_EXPONENT_UPPER_LIMIT
	jle	doneLimitChecks

posExpError:
	mov	ax, DECIMAL_EXPONENT_UPPER_LIMIT ; force upper limit
	jmp	short expError

expIsNegative:
	cmp	dx, 0ffffh			; out of range if <>0ffffh
	jne	negExpError

	cmp	ax, DECIMAL_EXPONENT_LOWER_LIMIT
	jge	doneLimitChecks			; error if limit exceeded

negExpError:
	mov	ax, DECIMAL_EXPONENT_LOWER_LIMIT ; force lower limit

expError:
	dec	FAF_local.errorFlag		; note error found

doneLimitChecks:

	; end limit checks
	;-----------------------------------------------------------------------

	call	Float10ToTheX			; push 10^ax onto the fp stack

	cmp	FAF_local.negExp, 0
	je	posExp

	call	FloatDivide
	jmp	short doneConvert

posExp:
	call	FloatMultiply

	;-----------------------------------------------------------------------
	; we're done

doneConvert:
	;
	; negate if negative number
	;
	cmp	FAF_local.negNum, 0
	je	storeResult

	call	FloatNegate

storeResult:
	;
	; store the result
	;
	mov	al, FAF_local.resultFlag
	test	al, mask FAF_PUSH_RESULT
	jnz	done				; result already on stack

	test	al, mask FAF_STORE_NUMBER
	jz	done				; for now...

	les	di, FAF_local.resultAddr
	call	FloatPopNumber

done:
	cmp	FAF_local.errorFlag, 0
	clc
	je	exit
	stc
exit:
	call	FloatOpDone
	.leave
	ret
FloatAsciiToFloat	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatAsciiToInteger

DESCRIPTION:	Converts the ASCII string into an integer.
		( fp: -- X)
		Thousands seperators are ignored.

CALLED BY:	INTERNAL (FloatAsciiToFloat)

PASS:		FAF_stackFrame

RETURN:		al/ax - ASCII character that stopped the conversion
		cx - number of digits converted
		stack frame vars updated
		integer on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatAsciiToInteger	proc	near

	FAF_local	local	FAF_stackFrame

	.enter inherit near

	call	Float0				; initialize number
	clr	cx				; init count of digits

nextDigit:
	call	NextDigit			; al <- digit
	jc	checkDone			; branch if non-digit

	;
	; process digit
	;
	inc	cx				; inc count
	clr	ah
	push	ax				; save digit
	call	FloatMultiply10			; destroys ax,cx,dx
	pop	ax				; retrieve digit
	call	FloatWordToFloat		; destroys ax,cx,dx,di
	call	FloatAdd
	jmp	short nextDigit

checkDone:
	LocalCmpChar	ax, FAF_local.thousandsSep
	je	nextDigit			; ignore

	.leave
	ret
FloatAsciiToInteger	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatAsciiToFraction

DESCRIPTION:	Converts the ASCII decimal string into a fraction.
		( fp: -- X)

CALLED BY:	INTERNAL (FloatAsciiToFloat)

PASS:		FAF_stackFrame

RETURN:		al/ax - ASCII character that stopped the conversion
		cx - number of digits converted
		stack frame vars updated
		fraction on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatAsciiToFraction	proc	near	uses	bx,di
	.enter

	call	Float0			; initialize number
	clr	cx			; init count

nextDigit:
	call	NextDigit		; al <- digit
	jc	startConversion

	inc	cx			; inc count
	clr	ah
	push	ax			; save digit
	jmp	short nextDigit

startConversion:
	; cx = num digits found

	jcxz	done

	mov	bx, cx			; save num digits
	mov	di, ax			; save non-numeric ASCII char

convLoop:
	call	Float10
	call	FloatDivide
	pop	ax
	call	FloatWordToFloat
	call	FloatAdd
	loop	convLoop

	call	Float10
	call	FloatDivide

	mov	cx, bx			; retrieve num digits
	mov	ax, di			; retrieve non-numeric ASCII char

done:
	.leave
	ret
FloatAsciiToFraction	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NextDigit

DESCRIPTION:	Retrieves the next numeric char and converts it into a number
		if possible.

CALLED BY:	INTERNAL (FloatAsciiToFloat)

PASS:		nothing

RETURN:		carry clear if successful
		    al - number (not ASCII)
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

NextDigit	proc	near
	call	NextNonSpaceChar	; al <- ASCII char
	jc	exit

	call	ConvertDigit		; transform char to number
exit:
	ret
NextDigit	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ConvertDigit

DESCRIPTION:	Converts an ASCII numeral into a number if possible.

CALLED BY:	INTERNAL (FloatAsciiToFloat, NextDigit)

PASS:		al/ax - ASCII/Unicode char

RETURN:		carry clear if char is numberic
		    0 <= al <= 9
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

ConvertDigit	proc	near
	LocalCmpChar	ax, '0'			; check bounds
	jl	error
	LocalCmpChar	ax, '9'
	jg	error

	sub	al, '0'			; convert
	clc				; signal success
	ret

error:
	stc				; signal failure
	ret
ConvertDigit	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NextNonSpaceChar

DESCRIPTION:	Return the next non-whiespace character from the
		string.

CALLED BY:	INTERNAL (FloatAsciiToFloat, NextDigit)

PASS:		nothing

RETURN:		C clear if successful
		    al - ASCII char
		C set if ds:[si] = NULL

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

NextNonSpaceChar	proc	near

space:
	call	NextChar
	jc	exit			; exit with failure if unsuccessful

	; get the next character if the current one is a white space char
if DBCS_PCGEOS
	call	LocalIsSpace
	jnz	space
else
	LocalCmpChar	ax, C_LINEFEED
	je	space
	LocalCmpChar	ax, C_ENTER
	je	space
	LocalCmpChar	ax, C_TAB
	je	space
	LocalCmpChar	ax, C_SPACE
	je	space
endif

	clc				; signal success
exit:
	ret
NextNonSpaceChar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NextChar

DESCRIPTION:	Return the next character from the string.  A check is made
		to see that the string length that was given is not
		exceeded.  The routine returns C set if a null is
		encountered, or if the length limit is hit.

CALLED BY:	INTERNAL (NextNonSpaceChar)

PASS:		stack frame

RETURN:		al/ax - ds:[si]    (SBCS/DBCS)		
		C set if al = NULL
		si <- si + 1

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version
	witt	10/93		DBCS-ized character getting..

-------------------------------------------------------------------------------@

NextChar	proc	near	uses	ds,si

	FAF_local	local	FAF_stackFrame

	.enter inherit near

	mov	al, FAF_local.numChars	; num chars in string
	cmp	al, FAF_local.numCharsRead
	jbe	error			; error if all have been processed

	inc	FAF_local.numCharsRead

	lds	si, FAF_local.sourceAddr
	LocalGetChar	ax, dssi
	LocalNextChar	FAF_local.sourceAddr

	LocalIsNull	ax		; null term?
	jnz	done			; branch if not, C = 0

error:
	clr	ax
	stc				; set C if null term
done:
	.leave
	ret
NextChar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UngetChar

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		al - char to 'unget'

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

UngetChar	proc	near

	FAF_local	local	FAF_stackFrame

	.enter inherit near

	; NOTE! : Changed the code below so that an *INTEGER*,
	; not byte, decrement is performed to solve mysterious
	; float/parse errors if a numeric string just happened
	; to end of a 256-byte boundary.  -Don 5/16/00

;;;	LocalPrevChar	FAF_local.sourceAddr.offset
	LocalPrevChar	FAF_local.sourceAddr
	dec	FAF_local.numCharsRead

	.leave
	ret
UngetChar	endp
