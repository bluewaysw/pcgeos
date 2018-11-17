
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		floatFloatToAscii.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name				Description
	----				-----------
	FloatFloatToAscii_StdFormat	Global routine that save the caller
					from having to deal with the
					FFA_stackFrame.

	FloatFloatToAscii		Global routine that expects the
					FFA_stackFrame.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision
	witt	10/93		DBCS string routines and such..

DESCRIPTION:
		
	$Id: floatFloatToAscii.asm,v 1.1 97/04/05 01:23:00 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFloatToAscii_StdFormat

DESCRIPTION:	Converts the floating point number into an ASCII string
		in the format specified by al.
		
		This routine provides a way to obtain an ASCII string from
		a floating point number without having to deal with the
		FFA_stackFrame.

		!!! NOTE !!!
		Rounding is based on decimalDigits and not total Digits.

CALLED BY:	GLOBAL ()

PASS:		ax - FloatFloatToAsciiFormatFlags

		    Flags permitted:

		    FFAF_FROM_ADDR - source of number
			If FFAF_FROM_ADDR=1,
			    Use the number at the given address
			    ds:si - location
			If FFAF_FROM_ADDR=0,
			    Use number from the fp stack.
			    Number will be popped
		    FFAF_SCIENTIFIC - scientific format
			If FFAF_SCIENTIFIC=1,
			    Returns numbers in the form x.xxxE+xxx
			    in accordance with bh and bl
			    Numbers are normalized ie. the mantissa m satisfies
				1 <= m < 10
			If FFAF_SCIENTIFIC=0,
			    Returns numbers in the form xxx.xxx
			    in accordance with bh and bl
		    FFAF_PERCENT - percentage format
			Returns numbers in the form xxx.xxx%
			in accordance with bh and bl
		    FFAF_USE_COMMAS
		    FFAF_NO_TRAIL_ZEROS

		bh - number of significant digits desired (>=1)
		     (A significant digit is a decimal digit derived from
		     the floating point number's mantissa and it may preceed
		     or follow a decimal point).

		     Fixed format numbers that require more digits than limited
		     will be forced into scientific notation.

		bl - number of fractional digits desired (ie. number of
		     digits following the decimal point)

		es:di - destination address of string

		NOTE:
		-----

		* Numbers are rounded away from 0.
		  eg. if number of fractional digits desired = 1,
		      0.56 will round to 1
		      -0.56 will round to -1

		* Commas only apply to the integer portion of fixed and
		  percentage format numbers.
		  ie. scientific formats, the fractional and exponent portions
		  of numbers will have no commas even if FFAF_USE_COMMAS is
		  passed.

RETURN:		cx - number of characters in the string
		     (excluding the null terminator)
		cx == 0 menas that the string produced was a Nan, i.e
			either "underflow", "overflow", or "error"

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatFloatToAscii_StdFormatInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	internal call to FloatFloatToAscii_StdFormat
CALLED BY:	INTERNAL
	
		see header directoly above for details
		exported for coprocessor libriaries		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global FloatFloatToAscii_StdFormatInternal:far
FloatFloatToAscii_StdFormatInternal	proc	far
	call	FloatFloatToAscii_StdFormat
	ret
FloatFloatToAscii_StdFormatInternal	endp

FloatFloatToAscii_StdFormat	proc	far	uses	ax
	locals	local	FFA_stackFrame
	.enter

	;
	; check for illegal bits
	;
EC<	test	ax, mask FFAF_HEADER_PRESENT or \
		    mask FFAF_TRAILER_PRESENT or \
		    mask FFAF_SIGN_CHAR_TO_FOLLOW_HEADER or \
		    mask FFAF_SIGN_CHAR_TO_PRECEDE_TRAILER >
EC<	ERROR_NZ FLOAT_BAD_FLAGS >

	mov	locals.FFA_float.FFA_params.formatFlags, ax
	clr	ax
	mov	locals.FFA_float.FFA_params.decimalOffset, al
	mov	locals.FFA_float.FFA_params.totalDigits, bh
	mov	locals.FFA_float.FFA_params.decimalLimit, bl
if DBCS_PCGEOS
	mov	locals.FFA_float.FFA_params.header, ax
	mov	locals.FFA_float.FFA_params.trailer, ax
	mov	locals.FFA_float.FFA_params.preNegative, '-'
	mov	locals.FFA_float.FFA_params.preNegative+2, ax
	mov	locals.FFA_float.FFA_params.postNegative, ax
	mov	locals.FFA_float.FFA_params.prePositive, ax
	mov	locals.FFA_float.FFA_params.postPositive, ax
else
	mov	locals.FFA_float.FFA_params.header, al
	mov	locals.FFA_float.FFA_params.trailer, al
	mov	{word} locals.FFA_float.FFA_params.preNegative, '-'
	mov	locals.FFA_float.FFA_params.postNegative, al
	mov	locals.FFA_float.FFA_params.prePositive, al
	mov	locals.FFA_float.FFA_params.postPositive, al
endif
	call	FloatFloatToAscii

	.leave
	ret
FloatFloatToAscii_StdFormat	endp


if 0
FloatFloatToAscii_CurrencyFormat	proc	near	uses	ax
	locals	local	FFA_stackFrame
	.enter

	mov	locals.FFA_float.FFA_params.formatFlags, mask FFAF_USE_COMMAS or \
				     mask FFAF_HEADER_PRESENT
DBCS<   .assert (size char) eq (size wchar)   ; need to DBCS routine	>
	clr	al
	mov	locals.FFA_float.FFA_params.decimalOffset, al
	mov	locals.FFA_float.FFA_params.totalDigits, bh
	mov	locals.FFA_float.FFA_params.decimalLimit, 2
;	mov	locals.FFA_float.FFA_params.header, al
	mov	locals.FFA_float.FFA_params.trailer, al
	mov	locals.FFA_float.FFA_params.preNegative, '('
	mov	locals.FFA_float.FFA_params.postNegative, ')'
	mov	locals.FFA_float.FFA_params.prePositive, al
	mov	locals.FFA_float.FFA_params.postPositive, al
	call	FloatFloatToAscii

	.leave
	ret
FloatFloatToAscii_CurrencyFormat	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFloatToAscii

DESCRIPTION:	Converts the floating point number into an ASCII string.

		This routine requires that you initialize the FFA_stackFrame.

CALLED BY:	GLOBAL ()

PASS:		ss:bp - FFA_stackFrame stack frame
		es:di - destination address of string
		    this buffer must either be FLOAT_TO_ASCII_NORMAL_BUF_LEN or
		    FLOAT_TO_ASCII_HUGE_BUF_LEN in size (see math.def)
		If FFA_stackFrame.FFA_FROM_ADDR = 1
		    ds:si - location of number to convert

		NOTE:
		-----

		* Numbers are rounded away from 0.
		  eg. if number of fractional digits desired = 1,
		      0.56 will round to 1
		      -0.56 will round to -1

		* Commas only apply to the integer portion of fixed and
		  percentage format numbers.
		  ie. scientific formats, the fractional and exponent portions
		  of numbers will have no commas even if FFAF_USE_COMMAS is
		  passed.

RETURN:		cx - number of characters in the string
		     (excluding the null terminator)
		cx == 0 means that the string produced was a Nan, i.e
			either "underflow", "overflow", or "error"
		some useful fields in the stack frame, see math.def

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	FloatFloatToAscii is a big body of code!

	A FloatFloatToAsciiFixed routine exists to format fixed format numbers
	quickly. Some demands may exceed its ability, so once this is detected,
	it bails and the generalized (& significantly slower) FloatFloatToAscii
	routine takes over.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version
	witt	10/93		DBCS-ized strings and such.

-------------------------------------------------------------------------------@

FloatFloatToAscii	proc	far	uses	ax,bx,dx,ds,di,si
	locals	local	FFA_stackFrame
	.enter	inherit far

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_FROM_ADDR >
EC <	jz	xipSave
EC <	push	bx						>
EC <	mov	bx, ds					>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	pop	bx						>
xipSave::
endif

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_FLOAT_RESERVED
	je	floatOp

	call	FloatFloatToDateTime
   LONG	jnc	straightExit			; If no error, exit.
	clr	cx				; An error occurred.
	jmp	straightExit

floatOp:
EC<	call	CheckFloatToAsciiParams >

	;-----------------------------------------------------------------------
	; initialize vars and such

	mov	locals.FFA_float.FFA_saveDI, di
	call	FloatGetDecimalSeperator
SBCS<	mov	locals.FFA_float.FFA_decimalChar, al	>
DBCS<	mov	locals.FFA_float.FFA_decimalChar, ax	>

SBCS<	mov	cx, FLOAT_TO_ASCII_NORMAL_BUF_LEN			>
DBCS<	mov	cx, FLOAT_TO_ASCII_NORMAL_BUF_LEN*(size wchar)		>
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_DONT_USE_SCIENTIFIC
	je	10$
SBCS<	mov	cx, FLOAT_TO_ASCII_HUGE_BUF_LEN				>
DBCS<	mov	cx, FLOAT_TO_ASCII_HUGE_BUF_LEN*(size wchar)		>
10$:	
	mov	locals.FFA_float.FFA_bufSize, cx	; store byte count

	clr	cx
	mov	locals.FFA_float.FFA_startNumber, cx
	mov	locals.FFA_float.FFA_decimalPoint, cx
	mov	locals.FFA_float.FFA_endNumber, cx
	mov	locals.FFA_float.FFA_numChars, cx
	mov	locals.FFA_float.FFA_startExponent, cx

	mov	locals.FFA_float.FFA_numSign, cx
	mov	locals.FFA_float.FFA_startSigCount, cl
	mov	locals.FFA_float.FFA_sigCount, cl
	mov	locals.FFA_float.FFA_noMoreSigInfo, cl
	mov	locals.FFA_float.FFA_startDecCount, cl
	mov	locals.FFA_float.FFA_decCount, cl
	mov	locals.FFA_float.FFA_useCommas, cl

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_FROM_ADDR
						; source=stack?
	je	sourceOK			; branch if not

	call	FloatPushNumberFar		; else place number on stack

sourceOK:
	;-----------------------------------------------------------------------
	; examine the number

	call	FloatEnter_DSSI			; ds:si <- top of fp stack
						; we will access the exponent
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	jnc	nan

	call	FloatDoPreNumeric		; initializes FFA_numSign

	;
	; Zero is no longer special cased here.
	;
	jmp	nonZero

nan:
	;-----------------------------------------------------------------------
	; if +/- infinity, return the text
	; else return "error"

	call	FloatIsInfinity			; dl <- ASCII sign if infinity

	mov	si, offset errorStr		; assume not infinity
	jnc	copyString			; branch if assumption correct

	mov	si, offset overflowStr
	cmp	dl, '+'				; ASCII char "+" is flag
	je	copyString

	mov	si, offset underflowStr

copyString:
	call	FloatCopyErrorStr
	clr	cx
	jmp	short exit

nonZero:
	;-----------------------------------------------------------------------
	; perform the conversion

	;
	; First initialize the buffer to a stream of "0" characters.
	;
	push	cx, di				; Save counter, pointer
	mov	cx, locals.FFA_float.FFA_bufSize
	LocalPrevChar	sscx			; don't count NULL
	add	cx, locals.FFA_float.FFA_saveDI	; Adjust by # of bytes written
	sub	cx, locals.FFA_float.FFA_startNumber	;    already

	LocalLoadChar	ax, '0'			; character to store
if DBCS_PCGEOS
 	shr	cx, 1				; bytes --> char count
	rep	stosw				; Zero out the buffer
else
	rep	stosb				; Zero out the buffer
endif
	pop	cx, di				; Retrieve counter, pointer

	; if format is fixed see if fast formatting code will work

	call	FloatAbs

	test    locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC
	jne	doScientific

	call	FloatFloatToAsciiFixed
	jnc	done

doScientific:
	call	GetDecimalExponent      ; sets FFA_decExponent & FFA_curExponent
	;
	; If the number is zero, then the rounding code messes up, so since
	; zero is already rounded, we just skip this.
	;
	cmp	locals.FFA_float.FFA_numSign,0
	je	afterRounding		; Branch if number is zero
	call	RoundNumber
	call	GetDecimalExponent      ; sets FFA_decExponent & FFA_curExponent
afterRounding:

	call	ConvertBase10Mantissa	; cx <- base 10 exponent
	call	RemoveTrailingZeros

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC
	je	done

if DBCS_PCGEOS
	cmp	cx, 0
	mov	bl, '+'			; only load low byte (save a little)
	jge	expSignOK

	mov	bl, '-'
	neg	cx

expSignOK:
	mov	ax, 'E'
	mov	locals.FFA_float.FFA_startExponent, di
	LocalPutChar	esdi, ax
	mov	al, bl			; high byte already 0.
	LocalPutChar	esdi, ax
else
	cmp	cx, 0
	mov	ah, '+'
	jge	expSignOK

	mov	ah, '-'
	neg	cx

expSignOK:
	mov	al, 'E'
	mov	locals.FFA_float.FFA_startExponent, di
	stosw
endif

	;
	; have at least 2 digits in the exponent
	;
	cmp	cx, 10
	jae	convExp
	LocalLoadChar	ax, '0'
	LocalPutChar	esdi, ax
convExp:
	mov	ax, cx
	call	ConvertWordToAscii

done:
	;-----------------------------------------------------------------------
	; done, tidy up

	call	FloatDoPostNumeric

	mov	cx, di
	sub	cx, locals.FFA_float.FFA_saveDI
DBCS<	shr	cx, 1			; bytes --> char count		>
	mov	locals.FFA_float.FFA_numChars, cx

	clr	ax			; null terminate string
	LocalPutChar	esdi, ax

exit:
	FloatDrop	trashFlags
	call	FloatOpDone

straightExit:
	.leave
	ret
FloatFloatToAscii	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCopyErrorStr

DESCRIPTION:	Copies an error string into the given location.

CALLED BY:	INTERNAL ()

PASS:		es:di - location to place string
		si - chunk handle of error string

RETURN:		nothing

DESTROYED:	di,si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatCopyErrorStr	proc	far	uses	ds
	.enter

	mov	bx, handle overflowStr
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]

	LocalCopyString

	call	MemUnlock

	.leave
	ret
FloatCopyErrorStr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckFloatToAsciiParams

DESCRIPTION:	Error checking code for FloatFloatToAscii.

CALLED BY:	INTERNAL (FloatFloatToAscii)

PASS:		parameters for FloatFloatToAscii

RETURN:		nothing

DESTROYED:	dies if assertions fail

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version
	witt	10/93		DBCS'ized string length checks.

-------------------------------------------------------------------------------@

if ERROR_CHECK
CheckFloatToAsciiParams	proc	near	uses	ax,bx,cx,es,di
	locals	local	FFA_stackFrame
	.enter	inherit near

	mov	bh, locals.FFA_float.FFA_params.totalDigits
	cmp	bh, 1
	ERROR_B	FLOAT_BAD_SIGNIFICANT_DIGITS

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_DONT_USE_SCIENTIFIC
	je	normalNum

	cmp	bh, MAX_DIGITS_FOR_HUGE_NUMBERS
	ERROR_A	FLOAT_BAD_SIGNIFICANT_DIGITS
	jmp	short doneCheck

normalNum:
	cmp	bh, DECIMAL_PRECISION
	ERROR_A	FLOAT_BAD_SIGNIFICANT_DIGITS

doneCheck:
	mov	bl, locals.FFA_float.FFA_params.decimalLimit
	cmp	bl, DECIMAL_PRECISION
	ERROR_A	FLOAT_BAD_DECIMAL_DIGITS

	;
	; check sign strings
	;
	segmov	es,ss,ax			; es <- ss
	clr	ax				; null-terminator

	mov	cx, SIGN_STR_LEN+1
	lea	di, locals.FFA_float.FFA_params.preNegative
	LocalFindChar
	ERROR_NE FLOAT_BAD_HEADER

	mov	cx, SIGN_STR_LEN+1
	lea	di, locals.FFA_float.FFA_params.postNegative
	LocalFindChar
	ERROR_NE FLOAT_BAD_HEADER

	mov	cx, SIGN_STR_LEN+1
	lea	di, locals.FFA_float.FFA_params.prePositive
	LocalFindChar
	ERROR_NE FLOAT_BAD_HEADER

	mov	cx, SIGN_STR_LEN+1
	lea	di, locals.FFA_float.FFA_params.postPositive
	LocalFindChar
	ERROR_NE FLOAT_BAD_HEADER

	;
	; check header and trailer
	;
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_HEADER_PRESENT
	je	doneHeaderCheck			; branch if absent

	mov	cx, PAD_STR_LEN+1
	lea	di, locals.FFA_float.FFA_params.header
	LocalFindChar
	ERROR_NE FLOAT_BAD_HEADER

doneHeaderCheck:
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_TRAILER_PRESENT
	je	doneTrailerCheck		; branch if absent

	mov	cx, PAD_STR_LEN+1
	lea	di, locals.FFA_float.FFA_params.trailer
	LocalFindChar
	ERROR_NE FLOAT_BAD_TRAILER

doneTrailerCheck:
	.leave
	ret
CheckFloatToAsciiParams	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetDecimalExponent

DESCRIPTION:	Compute the decimal exponent which we will use to start
		the decimal conversion.

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		FFA_stackFrame stack frame
		ds - fp stack seg

RETURN:		X on fp stack
		FFA_decExponent
		FFA_curExponent
		ax - decimal exponent

DESTROYED:	dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	Let b = binary exponent of X
	and d = decimal exponent we seek

	Let X = a * 2^b where a = mantissa

	we seek log X, but log X is an expensive operation

	log X	= lg X / lg 10

		= (b + lg a) / lg 10

		= b / lg 10  +  lg a / lg 10
	
	if we take int(b / lg 10) to be our estimate,
	then our error will be

		frac(b / lg 10) + lg a / lg 10
	
	a / lg 10 	<= .602
	frac(b / lg 10)	< 1
	so we can be off as much as 1.602

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

GetDecimalExponent	proc	near	uses	bx,si
	locals	local	FFA_stackFrame
	.enter inherit near

EC<	call	FloatCheck1Arg >

	clr	ax
	call	FloatSign		; --> bx=neg/non-neg, flags
	je	expGotten
EC<	ERROR_L FLOAT_POSITIVE_NUMBER_EXPECTED >
	call	FloatDup
	call	FloatLog
EC<	call	FloatIsNoNAN1 >
EC<	ERROR_NC FLOAT_BAD_DECIMAL_EXPONENT >
	call	FloatInt		; don't want rounding
	call	FloatFloatToDword	; dx:ax <- answer

expGotten:
	mov	locals.FFA_float.FFA_decExponent, ax
	mov	locals.FFA_float.FFA_curExponent, ax

	;-----------------------------------------------------------------------
	; if number format is FIXED, check to see that there won't be overflow

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC
	jne	done

	mov	dl, locals.FFA_float.FFA_params.totalDigits
	clr	dh

	push	ax			; store char offset in exponent
	tst	ax
	jns	10$
	neg	ax
10$:
	cmp	ax, dx			; larger than limit?
	pop	ax
	jl	noScientific		; branch if not

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_DONT_USE_SCIENTIFIC
	je	forceScientific		; branch if no preference for fixed

	;
	; User wants fixed format.  That is permissible if the limit is not
	; exceeded.
	;
	cmp	ax, MAX_DIGITS_FOR_HUGE_NUMBERS-1
	jle	done

forceScientific:
	;
	; ok... number is too big, force scientific
	; don't do the same for numbers that are too small?
	; (use a "jb" instead of a "jl" otherwise)
	; take abs value of ax if that is desired
	;

	or	locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC

done:
	.leave
	ret

noScientific:
	tst	ax
	jns	done
	clr	locals.FFA_float.FFA_decExponent
	clr	locals.FFA_float.FFA_curExponent
	jmp	done

GetDecimalExponent	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ConvertBase10Mantissa

DESCRIPTION:	

CALLED BY:	INTERNAL (FloatFloatToAscii)

PASS:		number on the floating point stack
		ds - fp stack seg
		es:di - location to store ASCII string
		FFA_stackFrame stack frame

RETURN:		cx - base 10 exponent

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	iterative DIV to extract digits (in the order of ms to ls)
	start with 10^x such that
	    2^exp <= 10^x, where exp is the exponent of the fp number

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

ConvertBase10Mantissa	proc	near	uses	bx
	locals	local	FFA_stackFrame

	.enter inherit near

	call	InitCommaHandling
	mov	ax, locals.FFA_float.FFA_decExponent
	call	Float10ToTheX

intLoop:
	;
	; ( fp: num 10^x )
	;
	cmp	locals.FFA_float.FFA_noMoreSigInfo, 0
	je	processSigDigit

	clr	al
	call	ConvertMantissa_ProcessDigit
	jmp	short nextDigit

processSigDigit:
	call	FloatOver		; ( fp: num 10^x num )
	call	FloatOver		; ( fp: num 10^x num 10^x )

	call	FloatDIV		; ( fp: num 10^x digit )
	call	FloatDup
	call	FloatFloatToDword		; al <- digit

	push	ax			; save digit
	call	FloatOver		; ( fp: num 10^x digit 10^x )
	call	FloatMultiply		; ( fp: num 10^x digit*10^x )
	call	FloatNegate
	call	FloatRot		; ( fp: 10^x -digit*10^x num )
	pop	ax			; retrieve digit
	call	ConvertMantissa_ProcessDigit

	call	FloatAdd		; ( fp: 10^x newNum )
	call	FloatSwap
	call	Float10
	call	FloatDivide		; ( fp: newNum 10^(x-1) )

nextDigit:
	dec	locals.FFA_float.FFA_curExponent

	;
	; done if any of the limits hit or if (newNum = 0)
	;
	call	ConvertMantissa_CheckDone
	jnc	intLoop

	FloatDrop trashFlags		; drop 10^x

	mov	cx, locals.FFA_float.FFA_decExponent
	.leave
	ret
ConvertBase10Mantissa	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ConvertMantissa_ProcessDigit

DESCRIPTION:	This routine is complicated by the requirement that it deal
		with fixed and scientific formats.

CALLED BY:	INTERNAL (ConvertBase10Mantissa)

PASS:		al - digit ( 0 <= ax <= 9 )
		X on fp stack
		ds - fp stack seg
		es:di - location to store ASCII string
		FFA_stackFrame stack frame

RETURN:		

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

    Rounding
    --------
    Rounding is done seperately for fixed and scientific formats.

    Let d = number of decimal digits desired (for the scientific format,
	    this is the number of digits following the normalization digit)
    and r = number that is added to obtain the desired rounding
    and x = decimal exponent of the rounding number r

    r = 5 * 10^x

    To round fixed format numbers,
	x = -d-1

    To round scientific numbers,
	x = current exponent - d - 1

    Rounding is performed once the first significant digit is encountered.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

ConvertMantissa_ProcessDigit	proc	near
	locals	local	FFA_stackFrame

	.enter inherit near

	cmp	locals.FFA_float.FFA_startSigCount, 0 ; lead 0s eliminated?
	je	checkSigStart			; branch if not

	inc	locals.FFA_float.FFA_sigCount		; up count of sig digits
if DBCS_PCGEOS
	clr	ah
	add	al, '0'				; convert to Unicode
else
	add	al, '0'				; convert to ASCII
endif
	LocalPutChar	esdi, ax		; store

	cmp	locals.FFA_float.FFA_startDecCount, 0 ; decimals started yet?
	je	checkDecStart			; branch if not

	inc	locals.FFA_float.FFA_decCount
	jmp	short done

checkSigStart:
	;-----------------------------------------------------------------------
	; deal with lead 0s
	; lead 0s may be significant for fixed format numbers

	tst	al				; lead 0 ?
	jne	countSig
	
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC
	je	checkDropLead0			; lose lead 0 if scientific
	;
	; For scientific notation, if the number is zero then we do want 
	; to count this zero rather than dropping it.
	;
	cmp	locals.FFA_float.FFA_numSign,0
	jne	dropLead0
	jmp	countSig

checkDropLead0:
	call	FloatDup
	call	FloatIntFrac			; ( fp: int frac )
	FloatDrop trashFlags			; lose fraction
	call	FloatEq0			; int part = 0?
	jnc	dropLead0			; branch if not

	;
	; fixed format number < 1
	; want 0 preceeding decimal point
	;
	cmp	locals.FFA_float.FFA_curExponent, 0
	jne	done

	clr	al				; reinstate 0 digit (destroyed)

countSig:
EC<	cmp	locals.FFA_float.FFA_startSigCount, 0 >
EC<	ERROR_NE FLOAT_BAD_STACK_FRAME >
	;
	; start count and store digit
	;
	dec	locals.FFA_float.FFA_startSigCount	; indicate start of sig count
	inc	locals.FFA_float.FFA_sigCount		; up count of sig digits

	tst	al
	jne	10$

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_NO_LEAD_ZERO
	jne	20$

10$:
if DBCS_PCGEOS
	clr	ah
	add	al, '0'				; convert to Unicode
	stosw
else
	add	al, '0'				; convert to ASCII
	stosb					; store
endif

20$:
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC
	jne	startDecimal			; branch if scientific

checkDecStart:
	cmp	locals.FFA_float.FFA_curExponent, 0
	jne	done

startDecimal:
	;-----------------------------------------------------------------------
	; found spot for decimal point

	dec	locals.FFA_float.FFA_startDecCount	; indicate start of dec count
	mov	locals.FFA_float.FFA_useCommas, 0	; no commas in fraction

	cmp	locals.FFA_float.FFA_params.decimalLimit, 0	; does caller want decimals?
	je	done				; done if not

	call	StuffDecimalPoint
	jmp	short done

dropLead0:
	dec	locals.FFA_float.FFA_decExponent	; adjust
	jmp	short commaDone

done:
	;-----------------------------------------------------------------------
	; deal with commas

	cmp	locals.FFA_float.FFA_useCommas, 0
	je	commaDone

	dec	locals.FFA_float.FFA_charsToComma
	jne	commaDone

	LocalLoadChar	ax, locals.FFA_float.FFA_commaChar
	LocalPutChar	esdi, ax

	mov	locals.FFA_float.FFA_charsToComma, 3

commaDone:
	.leave
	ret
ConvertMantissa_ProcessDigit	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitCommaHandling

DESCRIPTION:	Sees if commas are required.

CALLED BY:	INTERNAL (ConvertBase10Mantissa)

PASS:		FFA_params.formatFlags
		FFA_startDecCount
		FFA_useCommas = 0
		FFA_curExponent

RETURN:		FFA_useCommas
		FFA_charsToComma

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	FFA_useCommas has been initialized by FloatFloatToAscii to 0

	No commas if:
	    * caller does not want them
	    * format = scientific
	    * currently converting decimal portion

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

InitCommaHandling	proc	near
	locals	local	FFA_stackFrame
	.enter	inherit near

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_USE_COMMAS
	je	done

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC
	jne	done

	cmp	locals.FFA_float.FFA_startDecCount, 0
	jne	done

	;-----------------------------------------------------------------------
	; commas required

	dec	locals.FFA_float.FFA_useCommas; note commas required

	mov	ax, locals.FFA_float.FFA_curExponent
EC<	tst	ah >
EC<	ERROR_NE FLOAT_ASSERTION_FAILED >
	inc	al				; al <- num chars in integer
	mov	dl, 3
	div	dl				; ah <- remainder = chars
						; before comma
	tst	ah
	jne	storeCharsToComma

	mov	ah, dl				; ah <- 3

storeCharsToComma:
	mov	locals.FFA_float.FFA_charsToComma, ah

	call	FloatGetThousandsSeperator
SBCS<	mov	locals.FFA_float.FFA_commaChar, al		>
DBCS<	mov	locals.FFA_float.FFA_commaChar, ax		>

done:
	.leave
	ret
InitCommaHandling	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	RoundNumber

DESCRIPTION:	

CALLED BY:	INTERNAL (ConvertMantissa_ProcessDigit, FloatFloatToAsciiFixed)

PASS:		ax - exponent d as explained in ConvertMantissa_ProcessDigit's
		     routine header
		X on fp stack
		ds - fp stack seg

RETURN:		X rounded

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Rounding is done "away" from 0
	ie. for 0 decimal places, 
	    1.5 rounds to 2
	    -0.56 rounds to -1
	
	see also notes in header of ConvertMantissa_ProcessDigit
	
	The way we do rounding is we take the place we want to round to (ax)
	and add to the current fp-number starting at that position.
	
	Basically we're adding .5 * 10^ax to the existing number.
	This is the same as adding:
		.5 * 2^(log2(10)*ax)
	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

RoundNumber	proc	near	uses	bx, si, dx
	locals	local	FFA_stackFrame
	.enter inherit near

	clr	ah
	mov	al, locals.FFA_float.FFA_params.decimalLimit
						; get number of decimal places
	inc	ax				; one more to get rounding pos
	neg	ax

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC
						; scientific?
	je	doRounding			; branch if not

	;
	; scientific format rounding
	;

	add	ax, locals.FFA_float.FFA_curExponent
;	dec	ax

doRounding:

	call	FloatSign			; bx <- sign, flags set
	pushf

	call	FloatAbs

	call	Float10ToTheX			; ( fp: X 10^ax )
	call	Float5
	call	FloatMultiply			; ( fp: X 5*(10^ax) )
	call	FloatAdd

	;
	; HACK - to guard against numbers that are 1 bit less than desired
	;
	call	FloatEpsilon
	call	FloatAdd
	popf

	jge	done

	call	FloatNegate

done:
	.leave
	ret
RoundNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ConvertMantissa_CheckDone

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		FFA_stackFrame stack frame
		ds - fp stack seg
		( fp: num 10^x )

RETURN:		carry - boolean bit
			set = TRUE
			clear = FALSE

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

ConvertMantissa_CheckDone	proc	near
	locals	local	FFA_stackFrame
	.enter inherit near

	cmp	locals.FFA_float.FFA_startSigCount, 0	; started counting sig digits?
	je	notDone				; branch if not

	mov	al, locals.FFA_float.FFA_sigCount
	cmp	al, locals.FFA_float.FFA_params.totalDigits ; else has limit been hit?
	je	done

	;
	; if FFA_sigCount exceeds DECIMAL_PRECISION, no more meaningful
	; information can be extracted so we zero out the number in such an
	; event
	;
	cmp	locals.FFA_float.FFA_noMoreSigInfo, 0
	jne	20$				; branch if already detected
	cmp	al, DECIMAL_PRECISION		; else sig limit exceeded?
	jbe	20$				; branch if not

	call	FloatSwap			; ( fp: 10^x num )
	FloatDrop trashFlags			; ( fp: 10^x )
	call	Float0				; ( fp: 10^x 0 )
	call	FloatSwap			; ( fp: 0 10^x )
	dec	locals.FFA_float.FFA_noMoreSigInfo	; flag condition detected

20$:
	cmp	locals.FFA_float.FFA_startDecCount, 0	; started counting dec digits?
	je	notDone				; branch if not

	mov	al, locals.FFA_float.FFA_decCount
	cmp	al, locals.FFA_float.FFA_params.decimalLimit
						; else has limit been hit?
	je	done

notDone:
	clc
	jmp	short exit

done:
	stc

exit:
	.leave
	ret
ConvertMantissa_CheckDone	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ConvertWordToAscii

DESCRIPTION:	Converts a hex number into a non-terminated ASCII string.
		If a 0 is passed, a '0' will be stored.

CALLED BY:	INTERNAL (FloatFloatToAscii)

PASS:		ax - number to convert
		es:di - location to store ASCII chars

RETURN:		es:di - addr past last char converted

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Called upon to convert the exponent so there's no provision for
	sticking in commas.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

ConvertWordToAscii	proc	near	uses	bx,cx
	.enter
	clr	cx			; init count
	mov	bx, 10

convLoop:
	clr	dx
	div	bx			; ax <- quotient, dx <- remainder
	push	dx			; save digit
	inc	cx			; inc count
	tst	ax			; done?
	jnz	convLoop		; loop while not

storeLoop:
	pop	ax			; retrieve digit
	add	ax, '0'			; convert to ASCII/Unicode
	LocalPutChar	esdi, ax	; save it
	loop	storeLoop

	.leave
	ret
ConvertWordToAscii	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFloatToAsciiFixed

DESCRIPTION:	Provides faster formatting of fixed format numbers.

CALLED BY:	INTERNAL (FloatFloatToAscii)

PASS:		FFA_stackFrame
		es:di - destination address of string

		NOTE:
		-----
		Numbers are rounded away from 0.
		eg. if number of fractional digits desired = 1,
		    0.56 will round to 1
		    -0.56 will round to -1

RETURN:		carry set if fixed format won't work (totalDigits exceeded)

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	The reason why we resort to this is because having the scientific
	format code organize a fixed format number as well is very slow
	(in the order of 250,000 cycles).

	The approach here is to convert the integer and fraction parts
	into integers in registers which can be passed on to routines
	like ConvertDwordToAscii which should work quite a bit faster
	than the methods employed in FloatFloatToAscii (in the order of
	25,000 cycles).

	In the event of the number overflowing a 32 bit register pair,
	the codition is signaled and FloatFloatToAscii can use the original
	code.  We do quite a bit of work, possibly to no avail, but
	these occasions should be relatively rare.

	An even faster approach may be to convert both the integer and
	fraction together by shifting the significant decimals to the
	left of the decimal point, add .5 to round, and then perform
	the conversion.  We save a call to ConvertDwordToAscii and
	the series of float calls to round the number.  The drawback to
	this method is the total number of significant digits (integer &
	fraction) is limited to 10.  (The code below limits the integer
	to 10 digits and the fraction to 10 digits).

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFloatToAsciiFixed	proc	near	uses	bx,cx
	locals	local	FFA_stackFrame

	.enter inherit near

	;
	; Preliminary checks to see if we should proceed

;;; Removed, 10/11/91 - cheng
;;;	;
;;;	; If the number has anything but zeros after the first 2 words of the
;;;	; number then we can't format it here.
;;;	;
;;;	call	CheckNumberIn32Bits
;;;	LONG jc	quit			; Branch if it doesn't fit

;;; Removed,  7/ 4/91 -jw
;;; In the hope that the check above will work correctly and will allow more
;;; numbers to be formatted by this routine.
;;; Restored, 10/11/91 - cheng
;;; CheckNumberIn32Bits won't work.

	;
	; If the user asks for more decimal digits than we can process with 
	; ConvertDwordToAscii, there is no way we can do it.
	;
	cmp	locals.FFA_float.FFA_params.decimalLimit, NUM_DEC_DIGITS_IN_32_BITS
	stc
	LONG jg	quit

	push	di			; save di, restored if we bail
	call	FloatDup		; duplicate in case we need to bail

	;-----------------------------------------------------------------------
	; round number now
	
	call	RoundNumber

	;-----------------------------------------------------------------------
	; convert the integer portion

	call	FloatIntFrac
	call	FloatSwap		; ( fp: # frac int )
	call	FloatFloatToDword	; ( fp: # frac ), dx:ax <- int
	jc	popNum			; done if overflow, rid fraction

	push	ax
	or	ax, dx
	pop	ax
	jne	10$

	;
	; integer portion = 0
	;
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_NO_LEAD_ZERO
	jne	checkProcessFraction
	LocalLoadChar	ax, '0'
	LocalPutChar	esdi, ax
	jmp	short checkProcessFraction

10$:
	xchg	ax, dx			; ax:dx <- number
	clr	cl
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_USE_COMMAS
	je	20$
	mov	cl, mask DTAF_INCLUDE_COMMAS
20$:
	call	ConvertDwordToAscii	; cl <- num digits, es:di <- next loc

checkProcessFraction:
	cmp	cl, locals.FFA_float.FFA_params.totalDigits
	jl	processFraction		; branch if there's space for a fraction
	je	popNum			; done if no more space, rid fraction

	;
	; too little space given to represent this number in fixed format
	;
	mov	locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC
	stc				; bail
	jmp	short popNum		; rid fraction

processFraction:
	;-----------------------------------------------------------------------
	; convert the fractional portion

	;
	; cl = length so far
	;
	mov	ch, locals.FFA_float.FFA_params.totalDigits
	sub	ch, cl			; ch = max decimal digits allowed
	mov	al, locals.FFA_float.FFA_params.decimalLimit
	cmp	ch, al
	jge	numDecOK

	mov	al, ch			; adjust to contain max decimal digits

numDecOK:
	tst	al			; 0 decimal digits?
	je	popNum			; done if so, rid fraction

	clr	ah
	mov	bx, ax			; bx <- number of decimals
	call	Float10ToTheX
	call	FloatMultiply
	call	FloatIntFrac		; truncate number at the decimal point
	FloatDrop trashFlags		; lose fraction

	call	StuffDecimalPoint

	call	FloatFloatToDword	; dx:ax <- int
	jc	done			; done if overflow

	;
	; 0s are significant
	; bx = number of decimals
	;
	xchg	ax, dx
	mov	cl, mask DTAF_INCLUDE_LEADING_ZEROS_FIXED
if 0
; no commas in fractional portion
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_USE_COMMAS
	je	20$
	or	cl, mask DTAF_INCLUDE_COMMAS
20$:
endif
	call	ConvertDwordToAscii
	mov	locals.FFA_float.FFA_decCount, cl
	call	RemoveTrailingZeros
	clc
	jmp	short done

popNum:
	FloatDrop			; dropping fraction if not successful
					; carry flag intact
done:
	pop	ax			; retrieve original di
	jnc	quit

	mov	di, ax			; restore di if op unsuccessful

quit:
	.leave
	ret
FloatFloatToAsciiFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNumberIn32Bits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the number on the fp stack fits in 32 bits

CALLED BY:	FloatFloatToAsciiFixed

		Taken out on 10/11/91 by cheng because a floating point number
		containing bits in the low 32 bits does not mean that the
		number cannot be represented in 10 digits of integer and
		10 digits of fraction.

PASS:		ds	= fp stack
RETURN:		carry set if the number *does not* fall in 32 bits
		carry clear otherwise
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
CheckNumberIn32Bits	proc	near
	uses	si
	.enter
;	call	FloatGetSP_DSSI		; ds:si <- top of stac
	FloatGetSP_DSSI
	mov	ax, ds:[si].F_mantissa_wd0
	or	ax, ds:[si].F_mantissa_wd1
	
	tst	ax			; Check for zero in low 2 words
					; 'tst' clears the carry
	jz	fits			; Branch if it fits in 32 bits
	
	stc				; Signal: doesn't fit in 32 bits
fits:
	.leave
	ret
CheckNumberIn32Bits	endp
endif




COMMENT @-----------------------------------------------------------------------

FUNCTION:	ConvertDwordToAscii

DESCRIPTION:	Converts a 32 bit unsigned number to its ASCII/Unicode
		representation.

CALLED BY:	INTERNAL (GenerateLabel, FloatFloatToAsciiFixed)

PASS:		ax:dx - dword to convert
		cl - DwordToAsciiFlags
		     DTAF_INCLUDE_LEADING_ZEROS
		     DTAF_INCLUDE_LEADING_ZEROS_FIXED
			 bx = total number of digits, bx > 0
		     DTAF_NULL_TERMINATE
		     DTAF_INCLUDE_COMMAS
		es:di - address of buffer to place null terminated string
			(should have 10 chars/wchars if DTAF_NULL_TERMINATE=0,
			11 chars/wchars if DTAF_NULL_TERMINATE=1)

RETURN:		es:di - next available location
		cx - number of digits stored

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	You might think that one could use the 8086 32bit divide instruction
	to perform the conversion here. You'd be wrong. The divisor (10) is
	too small. Given something greater than 64k * 10, we will get a divide-
	by-zero trap the first time we try to divide. So we use "32-bit"
	division with a 16-bit divisor to avoid such problems, doing two
	divides instead of one, etc.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	When UtilHex32ToAscii has commas, that routine should be called instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	Cheng	3/91		Modified to handle DTAF_INCLUDE_LEADING_ZEROS_FIXED
	witt	10/93		DBCS-ized.

-------------------------------------------------------------------------------@

convertStackFrame	struct
	CSF_flags	byte
	CSF_numDigits	word
convertStackFrame	ends

ConvertDwordToAscii	proc	near	uses	si, dx, bx, ax
	locals	local	convertStackFrame
	.enter

	mov	locals.CSF_flags, cl
	mov	locals.CSF_numDigits, bx
	mov	bx, 10			; print in base ten
	clr	cx			; initialize character count

nextDigit:
	mov	si, dx			; si = low word
	clr	dx
	div	bx
	xchg	ax, si			; ax = low word, si = quotient
	div	bx
	xchg	ax, dx			; ax = remainder, dx = quotient

	add	al, '0'			; convert to ASCII/Unicode
	push	ax			; save character
	inc	cx			; inc count

	mov	ax, si			; retrieve quotient of high word
	or	si, dx			; done?
	jnz	nextDigit		; loop if not

	;-----------------------------------------------------------------------
	; conversion done, see if any other formatting needs to be done
	; cx = number of digits on stack

	test	locals.CSF_flags, mask DTAF_INCLUDE_LEADING_ZEROS_FIXED
	jne	doPadZeros

	test	locals.CSF_flags, mask DTAF_INCLUDE_LEADING_ZEROS
	mov	locals.CSF_numDigits, cx
	je	doStore			; branch if no padding requested

	;
	; number of decimal chars from a 32 bit binary binary number = 10
	;
	mov	locals.CSF_numDigits, bx	; CSF_numDigits <- 10
	jmp	short doLeadZeros

doPadZeros:
	mov	bx, locals.CSF_numDigits	; retrieve total number of digits

doLeadZeros:
	;
	; bx = locals.CSF_numDigits = total number of digits
	; cx = number of digits on stack
	;
	sub	bx, cx				; bx <- 0s needed for padding
EC<	ERROR_L	FLOAT_ASSERTION_FAILED >
	je	doStore				; branch if none

	mov	cx, bx				; else place count in cx
	mov	ax, '0'				; character to push

addLeadZeros:
	;
	; cx = number of '0's to push
	; locals.CSF_numDigits = total number of digits
	;
	push	ax
	loop	addLeadZeros

	;-----------------------------------------------------------------------
	; store what's on the stack
doStore:
	mov	cx, locals.CSF_numDigits	; cx <- total number of digits

	;
	; deal with commas if necessary
	; use bl to contain the number of characters before next comma
	; use bh to contains flag as to whether or not to include commas
	; dl = comma character
	;
	mov	bh, locals.CSF_flags		; get flags
	and	bh, mask DTAF_INCLUDE_COMMAS	; isolate flag
	je	storeLoop			; branch if no commas

	mov	bl, 3				; cx MOD 3 = chars before comma
	mov	ax, cx				; ax <- num chars on stack
	div	bl				; ah <- remainder
	tst	ah				; remainder = 0?
	je	initComma			; bl = 3 if so

	mov	bl, ah				; bl <- chars before comma

initComma:
	call	FloatGetThousandsSeperator
SBCS<	mov	dl, al				; dl <- comma character	>
DBCS<	mov	dx, ax				; dx <- comma character	>

storeLoop:
	pop	ax				; retrieve character
	LocalPutChar	esdi, ax
	tst	bh				; include commas?
	je	nextChar			; branch if not
	
	dec	bl				; else dec count to comma pos
	jne	nextChar			; branch if not there yet

	cmp	cx, 1				; else last character stored?
	je	nextChar			; no comma will follow last char

SBCS<	mov	al, dl				; store comma		>
DBCS<	mov	ax, dx				; store comma		>
	LocalPutChar	esdi, ax
	mov	bl, 3				; reinitialize count

nextChar:
	loop	storeLoop			; loop to store all

	test	locals.CSF_flags, mask DTAF_NULL_TERMINATE
	je	done
	clr	al
	stosb

done:
	mov	cx, locals.CSF_numDigits	; return cx <- total number of digits
	.leave
	ret
ConvertDwordToAscii	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDoPreNumeric

DESCRIPTION:	Stuff the pre-numeric characters.

CALLED BY:	INTERNAL (FloatFloatToAscii, FloatGenFormatStr)

PASS:		ss:bp - FFA_stackFrame
		es:di - next storage location

RETURN:		FFA_numSign

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Deal with header and sign
	Deal with percentage
	Deal with decimal offset

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatDoPreNumeric	proc	near	uses	si
	locals	local	FFA_stackFrame
	.enter	inherit near

	;-----------------------------------------------------------------------
	; deal with header and sign

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_HEADER_PRESENT
	jne	doHeader			; branch if header present

	call	StuffPreSign			; store sign
	jmp	short doOffsets

doHeader:
	lea	si, locals.FFA_float.FFA_params.header
	test	locals.FFA_float.FFA_params.formatFlags, \
		mask FFAF_SIGN_CHAR_TO_FOLLOW_HEADER
	pushf					; save flags
	je	doSign
	call	StuffChars
doSign:
	call	StuffPreSign			; store sign
	popf					; retrieve flags from test
	jne	doOffsets
	call	StuffChars

doOffsets:
	;-----------------------------------------------------------------------
	; deal with offsets

	cmp	locals.FFA_float.FFA_params.decimalOffset, 0
	je	checkPct

	mov	al, locals.FFA_float.FFA_params.decimalOffset
	cbw
	call	Float10ToTheX
	call	FloatMultiply

checkPct:
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_PERCENT
	je	notPct

	call	FloatMultiply10
	call	FloatMultiply10

notPct:

	;-----------------------------------------------------------------------
	; note position where number will start

	mov	locals.FFA_float.FFA_startNumber, di

	.leave
	ret
FloatDoPreNumeric	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDoPostNumeric

DESCRIPTION:	Stuff the post-numeric characters.

CALLED BY:	INTERNAL (FloatFloatToAscii, FloatGenFormatStr)

PASS:		ss:bp - FFA_stackFrame
		es:di - next storage location

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Deal with percentage
	Deal with trailer and sign

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatDoPostNumeric	proc	near	uses	si
	locals	local	FFA_stackFrame
	.enter	inherit near

	;-----------------------------------------------------------------------
	; note position where number ends

	mov	locals.FFA_float.FFA_endNumber, di

	;-----------------------------------------------------------------------
	; deal with percentages

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_PERCENT
	je	donePct

	LocalLoadChar	ax, '%'
	LocalPutChar	esdi, ax

donePct:
	;-----------------------------------------------------------------------
	; deal with trailer and sign

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_TRAILER_PRESENT
	jne	doTrailer

	call	StuffPostSign
	jmp	short done

doTrailer:
	lea	si, locals.FFA_float.FFA_params.trailer	; si <- trailer
	test	locals.FFA_float.FFA_params.formatFlags, \
		mask FFAF_SIGN_CHAR_TO_PRECEDE_TRAILER
	pushf					; save flags
	jne	doSign
	call	StuffChars
doSign:
	call	StuffPostSign
	popf					; retrieve flags from test
	je	done
	call	StuffChars

done:
	.leave
	ret
FloatDoPostNumeric	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StuffPreSign

DESCRIPTION:	Store the sign character if one should precede the number.

CALLED BY:	INTERNAL (FloatDoPreNumeric)

PASS:		es:di - next storage location

RETURN:		es:di - next storage location

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

StuffPreSign	proc	near	uses	bx,si
	locals	local	FFA_stackFrame
	.enter	inherit near

	call	FloatSign			; bx <- sign
	mov	locals.FFA_float.FFA_numSign, bx	; save sign
	lea	si, locals.FFA_float.FFA_params.prePositive	; assume positive
	jge	storeSign			; branch if assumption correct

	lea	si, locals.FFA_float.FFA_params.preNegative	; else modify char

storeSign:
	call	StuffChars
	.leave
	ret
StuffPreSign	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StuffPostSign

DESCRIPTION:	Store the sign character if one should follow the number.

CALLED BY:	INTERNAL (FloatDoPostNumeric)

PASS:		es:di - next storage location

RETURN:		es:di - next storage location

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

StuffPostSign	proc	near	uses	si
	locals	local	FFA_stackFrame
	.enter	inherit near

	cmp	locals.FFA_float.FFA_numSign, 0
	lea	si, locals.FFA_float.FFA_params.postPositive	; assume positive
	jge	storeSign			; branch if assumption correct
	lea	si, locals.FFA_float.FFA_params.postNegative	; else modify char
storeSign:
	call	StuffChars
	.leave
	ret
StuffPostSign	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StuffChars

DESCRIPTION:	Copy a null-terminated string to the destination.
		The null-terminator will not be copied.

CALLED BY:	INTERNAL (FloatDoPreNumeric, FloatDoPostNumeric)

PASS:		si - offset from ss to null-terminated string
		es:di - next storage location

RETURN:		string copied over
		es:di - next storage location

DESTROYED:	ax,si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	witt	10/93		DBCS-ized string copy.

-------------------------------------------------------------------------------@

StuffChars	proc	near
	LocalIsNull	ss:[si]		; something to work on?
	je	exit			; quit if not

	push	ds
	segmov	ds,ss,ax		; ds:si <- source string
copyLoop:
	LocalGetChar	ax, dssi	; grab character
	LocalIsNull	ax		; null terminator?
	je	done			; done if so

	LocalPutChar	esdi, ax	; else stuff char
	jmp	short copyLoop

done:
	pop	ds

exit:
	ret
StuffChars	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StuffDecimalPoint

DESCRIPTION:	Store the decimal point and make note of it in the
		stack frame.

CALLED BY:	INTERNAL ()

PASS:		es:di - next storage location
		FFA_stackFrame

RETURN:		es:di - next storage location

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

StuffDecimalPoint	proc	near
	locals	local	FFA_stackFrame
	.enter	inherit near

	mov	locals.FFA_float.FFA_decimalPoint, di	; note position

	call	FloatGetDecimalSeperator
	LocalPutChar	esdi, ax		; store the decimal point

	.leave
	ret
StuffDecimalPoint	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	RemoveTrailingZeros

DESCRIPTION:	Routine that removes trailing zeros and the decimal point
		if that is the trailing character.

CALLED BY:	INTERNAL (FloatFloatToAscii, FloatFloatToAsciiFixed)

PASS:		FFA_stackFrame
		es:di - next storage location

RETURN:		es:di - next storage location

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Can't call RemoveTrailingZeros at the end of conversion cos of
	numbers in scientific format. So calls to this routine need to be
	placed judiciously.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

RemoveTrailingZeros	proc	near	uses	cx
	locals	local	FFA_stackFrame
	.enter	inherit near

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_NO_TRAIL_ZEROS
	je	checkDecimalPoint

	mov	cl, locals.FFA_float.FFA_decCount	; decimals present?
	tst	cl
	je	checkDecimalPoint		; branch if not

	clr	ch				; else loop to remove
delLoop:
SBCS<	cmp	{char} es:[di-1], '0'		; trailing zero?	>
DBCS<	cmp	{wchar} es:[di-2], '0'		; trailing zero?	>
	jne	checkDecimalPoint		; done if not

	LocalPrevChar	esdi
	loop	delLoop

checkDecimalPoint:
	;
	; these lines can be taken out if zero padding out to a fixed
	; number of decimal digits is desired (ie pad out even if totalDigits is
	; exceeded)
	;
	LocalLoadChar	ax, locals.FFA_float.FFA_decimalChar
SBCS<	cmp	al, es:[di-1]			; is last char a decimal point?	>
DBCS<	cmp	ax, es:[di-2]			; is last char a decimal point?	>
	jne	done				; branch if not

	LocalPrevChar	esdi			; else lose it
	clr	locals.FFA_float.FFA_decimalPoint	; note no decimal point

done:
	.leave
	ret
RemoveTrailingZeros	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGetNumDigitsInIntegerPart

DESCRIPTION:	As routine says, eg. with 5678.956, routine returns 4.

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		ax - number of digits in the integer part
		X is popped off the stack

DESTROYED:	dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
    complications:
	* log of -ve numbers is undefined, fix by taking absolute value
	* want to return 1 for x such that 0 <= x < 1

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

FloatGetNumDigitsInIntegerPart	proc	far
	.enter
	call	FloatAbs		; log of negative numbers is undefined
	call	FloatTrunc		; want 1 to be returned for 0.00...
	call	FloatLog

	call	FloatIsNoNAN1		; was log taken of 0?
	jnc	return1			; branch if so

	call	FloatTrunc		; don't want rounding
	call	FloatFloatToDword	; dx:ax <- answer
	inc	ax			; log(X)+1 = number of digits

done:
	.leave
	ret

return1:
	FloatDrop trashFlags		; lose fraction
	mov	ax, 1
	jmp	short done
FloatGetNumDigitsInIntegerPart	endp
	public FloatGetNumDigitsInIntegerPart
