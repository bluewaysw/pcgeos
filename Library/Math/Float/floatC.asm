COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Float
FILE:		floatC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	2/92		Initial version

DESCRIPTION:
	This file contains C interface routines for the float library routines

	$Id: floatC.asm,v 1.1 97/04/05 01:23:04 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Float	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATINIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatInit

C DECLARATION:	extern void _far_pascal FloatInit(word stackSize,
						 FloatStackType stackType);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATINIT	proc	far	;stackSize:word
	C_GetTwoWordArgs		ax, bx, dx, cx		;ax <- size
								; bx <- type
	call	FloatInit
	ret
FLOATINIT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatAsciiToGeos80

C DECLARATION:	extern void Boolean
			_far _pascal FloatAsciiToGeos80
    				    (word floatAtoFflags, word stringLength,
				     void *string, void *resultLocation);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	2/92		Initial version

------------------------------------------------------------------------------@
FLOATASCIITOGEOS80	proc	far	floatAtoFflags:word, stringLength:word,
					string:fptr, resultLocation:fptr
			uses ds,di,si

	.enter

	lds	si, string
	les	di, resultLocation
	mov	ax, floatAtoFflags
	mov	cx, stringLength
	call	FloatAsciiToFloat
	mov	ax, 0		; Leave this as a mov, so the carry is left
				; alone.
	jnc	done
	dec 	ax
done:
	.leave
	ret
FLOATASCIITOGEOS80	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatComp

C DECLARATION:	extern word 
			_far FloatComp()
	Returns: 0  if X1 = X2
		 1  if X1 > X2
		-1  if X1 < X2


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
FLOATCOMP	proc	far 	

	call	FloatCompFar
	pushf
	mov	ax, 0		; assume equal
	jz	done
	mov	ax, -1		; X1 < X2
	jc	done		
	mov	ax, 1		; X1 > X2
done:
	popf

	ret
FLOATCOMP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatCompAndDrop

C DECLARATION:	extern word 
			_far FloatCompAndDrop()
	Returns: 0  if X1 = X2
		 1  if X1 > X2
		-1  if X1 < X2


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
FLOATCOMPANDDROP	proc	far 	

	call	FloatCompFar
	pushf
	mov	ax, 0		; assume equal
	jz	done
	mov	ax, -1		; X1 < X2
	jc	done		
	mov	ax, 1		; X1 > X2
done:
	call	FLOATDROP
	call	FLOATDROP
	popf

	ret
FLOATCOMPANDDROP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatCompGeos80ESDI

C DECLARATION:	extern word 
			_far FloatCompGeos80ESDI()
	Returns: 0  if X1 = X2
		 1  if X1 > X2
		-1  if X1 < X2


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
FLOATCOMPGEOS80ESDI	proc	far 	floatPtr:fptr
	uses	es, di
	.enter
	les	di, floatPtr
	call	FloatCompESDIFar
	pushf
	mov	ax, 0		; assume equal
	jz	done
	mov	ax, -1		; X1 < X2
	jc	done		
	mov	ax, 1		; X1 > X2
done:
	popf
	.leave
	ret
FLOATCOMPGEOS80ESDI	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatEq0

C DECLARATION:	extern word 
			_far FloatEq0()
	Returns: 0  if X <> 0
		 1  if X =  0


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/27/92		Initial version

------------------------------------------------------------------------------@
FLOATEQ0	proc	far 	

	call	FloatEq0Far
	mov	ax, 1		; assume X = 0
	jc	done
	mov	ax, 0		; X <> 0
done:
	ret
FLOATEQ0	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatLt0

C DECLARATION:	extern word 
			_far FloatLt0()

	Returns: 0  if X >= 0
		 1  if X <  0


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/27/92		Initial version

------------------------------------------------------------------------------@
FLOATLT0	proc	far 	

	call	FloatLt0Far
	mov	ax, 1		; assume X < 0
	jc	done
	mov	ax, 0		; X <> 0
done:
	ret
FLOATLT0	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatGt0

C DECLARATION:	extern word 
			_far FloatGt0()
	Returns: 0  if X <= 0
		 1  if X >  0


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/27/92		Initial version

------------------------------------------------------------------------------@
FLOATGT0	proc	far 	

	call	FloatGt0Far
	mov	ax, 1		; assume X > 0
	jc	done
	mov	ax, 0		; X <= 0
done:
	ret
FLOATGT0	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatPushGeos80Number

C DECLARATION:	extern word 
			_far FloatPushGeos80Number(FloatNum *number)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
FLOATPUSHGEOS80NUMBER	proc	far 	number:fptr 
	
				uses ds, si, es
		.enter
		lds	si, number
		call	FloatPushNumberFar
		mov	ax, 0	;assume no error
		jnc	done
		mov	ax, -1
done:
		.leave
		ret

FLOATPUSHGEOS80NUMBER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatPopGeos80Number

C DECLARATION:	extern word 
			_far FloatPopGeos80Number(FloatNum *number)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
FLOATPOPGEOS80NUMBER	proc	far 	number:fptr 
	
				uses di, es
		.enter
		les	di, number
		call	FloatPopNumberFar
		mov	ax, 0	;assume no error
		jnc	done
		mov	ax, -1
done:
		.leave
		ret

FLOATPOPGEOS80NUMBER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatRound

C DECLARATION:	extern void 
			_far FloatRound(numDecimalPlaces)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jeremy	6/23/92		Initial version

------------------------------------------------------------------------------@
FLOATROUND	proc	far 	numDecimalPlaces:word
	.enter

	mov	al, numDecimalPlaces.low
	call	FloatRoundFar

	.leave
	ret

FLOATROUND	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatStringGetDateNumber

C DECLARATION:	extern word 
			_far FloatStringGetDateNumber(char *dateString)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
FLOATSTRINGGETDATENUMBER	proc	far 	dateString:fptr 
	
				uses di, es
		.enter
		les	di, dateString
		call	FloatStringGetDateNumber
		mov	ax, 0	;assume no error
		jnc	done
		mov	ax, -1
done:
		.leave
		ret

FLOATSTRINGGETDATENUMBER	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatGeos80ToAscii_StdFormat

C DECLARATION:	extern word
			_far _pascal FloatGeos80ToAscii_StdFormat
			(char *string, FloatNum *number,
			 FloatFloatToAsciiFormatFlags format,
			 word numDigits, word numFractionalDigits)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	4/22/92		Initial version

------------------------------------------------------------------------------@

FLOATGEOS80TOASCII_STDFORMAT	proc	far 	string:fptr,
						number:fptr,
						format:word,
						numDigits:word,
						numFractionalDigits:word

	uses	es, ds, si, di
	.enter	

	les	di, string
	lds	si, number
	mov	ax, format
	mov	bh, numDigits.low
	mov	bl, numFractionalDigits.low

	call	FloatFloatToAscii_StdFormat
	mov	ax, cx			; put number of digits in ax
	.leave
	ret
FLOATGEOS80TOASCII_STDFORMAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatGeos80ToAscii

C DECLARATION:	extern word
			_far _pascal FloatGeos80ToAscii_StdFormat
			(FFA_stackFrame *stackFrame,
			 char *resultString,
			 FloatNum *number)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	4/27/92		Initial version
	jeremy	11/10/93	Removed ax from the "uses" line.  D'ohh!

------------------------------------------------------------------------------@
;
; Exported as a placeholder for the old FLOATFLOATTOASCII
;
global FLOATFLOATTOASCII_OLD:far
FLOATFLOATTOASCII_OLD	proc	far
	FALL_THRU	FLOATGEOS80TOASCII
FLOATFLOATTOASCII_OLD	endp

FLOATGEOS80TOASCII	proc	far 		stackFrame:fptr,
						resultString:fptr,
						number:fptr

	uses	es, ds, si, di
	.enter	

EC <	mov	ax, ss							>
EC <	cmp	ax, stackFrame.high					>
EC <	ERROR_NE POINTER_SEGMENT_NOT_SAME_AS_STACK_FRAME		>

	les	di, resultString
	lds	si, number

	push 	bp
	mov	bp, stackFrame.low
	add	bp, (size FFA_stackFrame)	; add size of variable

	call	FloatFloatToAscii
	pop	bp

	mov	ax, cx			; put number of digits in ax
	.leave
	ret
FLOATGEOS80TOASCII	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatFloatIEEE64ToAscii_StdFormat

C DECLARATION:	extern word
			_far _pascal FloatIEEE64ToAscii_StdFormat
			(char *string, IEEE64FloatNum number,
			 FloatFloatToAsciiFormatFlags format,
			 word numDigits, word numFractionalDigits)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/92		Initial version

------------------------------------------------------------------------------@

FLOATFLOATIEEE64TOASCII_STDFORMAT	proc	far 	string:fptr,
						number:IEEE64,
						format:word,
						numDigits:word,
						numFractionalDigits:word

	bigfloat	local	FloatNum
	uses	ds, si, di
	.enter	

	segmov	ds, ss
	lea	si, number		; ds:si <- IEEE64 number
	call	FloatIEEE64ToGeos80Far	; puts a Geos80 float of FP stack
	lea	di, bigfloat
	segmov	es, ss	
	call	FloatEnter		; ds <- seg addr of fp stack
	call	FloatPopNumber		; put Geos80 float in local variable
	call	FloatOpDone		; unlock fp stack

	; 
	; Added 9/99 CHR to properly set up ds:si with our Geos80 number!
	segmov  ds, es
	mov		si, di

	mov	ax, ss:[string].segment
	mov	es, ax
	mov	ax, ss:[string].offset
	mov	di, ax
	mov	ax, ss:[numDigits]
	mov	bx, ss:[numFractionalDigits]
	mov	bh, al
	mov	ax, ss:[format]

	call	FloatFloatToAscii_StdFormat
	mov	ax, cx			; put number of digits in ax
	.leave
	ret
FLOATFLOATIEEE64TOASCII_STDFORMAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatStringGetTimeNumber

C DECLARATION:	extern word 
			_far FloatStringGetTimeNumber(char *timeString)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
FLOATSTRINGGETTIMENUMBER	proc	far 	timeString:fptr 
	
				uses di, es
		.enter
		les	di, timeString
		call	FloatStringGetTimeNumber
		mov	ax, 0	;assume no error
		jnc	done
		mov	ax, -1
done:
		.leave
		ret
FLOATSTRINGGETTIMENUMBER	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatSetStackSize

C DECLARATION:	extern word 
			_far FloatSetStackSize(int size)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@


FLOATSETSTACKSIZE	proc	far	stacksize:word
	.enter
	mov	ax, stacksize
	call	FloatSetStackSizeFar	
	.leave
	ret
FLOATSETSTACKSIZE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatGeos80ToIEEE64

C DECLARATION:	extern void
			_far FloatGeos80ToIEEE64(double *num)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		take top number of floating point stack and pops it into
		the num double pointer passed as a parameter

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@

FLOATGEOS80TOIEEE64	proc	far	numPtr:fptr
	uses	es, di
	.enter
	les	di, numPtr
	call	FloatGeos80ToIEEE64Far
	.leave
	ret
FLOATGEOS80TOIEEE64	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatGeos80ToIEEE32

C DECLARATION:	extern void
			_far FloatGeos80ToIEEE32(float *num)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		take top number of floating point stack and pops it into
		the num float pointer passed as a parameter

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@

FLOATGEOS80TOIEEE32	proc	far	numPtr:fptr
	uses	es, di
	.enter
	call	FloatGeos80ToIEEE32Far		; dx:ax = value
	les	di, numPtr
	mov	es:[di].low, ax
	mov	es:[di].high, dx
	.leave
	ret
FLOATGEOS80TOIEEE32	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatIEEE32ToGeos80

C DECLARATION:	extern void
			_far FloatIEEE32ToGeos80(float *num)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		take top number of floating point stack and pops it into
		the num double pointer passed as a parameter

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@

FLOATIEEE32TOGEOS80	proc	far	numPtr:fptr
	uses	es, di
	.enter
	les	di, numPtr
	mov	ax, es:[di].low
	mov	dx, es:[di].high
	call	FloatIEEE32ToGeos80Far
	.leave
	ret
FLOATIEEE32TOGEOS80	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatIEEE64ToGeos80

C DECLARATION:	extern void
			_far FloatIEEE64ToGeos80(float *num)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		take top number of floating point stack and pops it into
		the num double pointer passed as a parameter

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@

FLOATIEEE64TOGEOS80	proc	far	numPtr:fptr
	uses	ds, si
	.enter
	lds	si, numPtr
	call	FloatIEEE64ToGeos80Far	
	.leave
	ret
FLOATIEEE64TOGEOS80	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatWordToFloat

C DECLARATION:	extern void
			_far FloatWordToFloat(word num)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		convert the long number passed in to an 80 bit floating point 
		number on the top of the stack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
FLOATWORDTOFLOAT	proc	far	num:word
	.enter
	mov	ax, num
	call	FloatWordToFloatFar	
	.leave
	ret
FLOATWORDTOFLOAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatDwordToFloat

C DECLARATION:	extern void
			_far FloatDwordToFloat(long num)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		convert the long number passed in to an 80 bit floating point 
		number on the top of the stack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
FLOATDWORDTOFLOAT	proc	far	num:dword
	.enter
	mov	dx, num.high
	mov	ax, num.low
	call	FloatDwordToFloatFar	
	.leave
	ret
FLOATDWORDTOFLOAT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatGetDaysInMonth

C DECLARATION:	extern word
			_far FloatGetDaysInMonth(word year, byte month);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		take top number of floating point stack and pops it into
		the num double pointer passed as a parameter

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
FLOATGETDAYSINMONTH	proc	far	year:word,
					month:word	; actually byte
	.enter
	mov	ax, year
	mov	bx, month		; don't care about bh
	call	FloatGetDaysInMonth
	clr	ah
	mov	al, bh			; ax = # of days in month
	.leave
	ret
FLOATGETDAYSINMONTH	endp	

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatGetDateNumber

C DECLARATION:	extern FloatErrorType
		     _far FloatGetDateNumber(word year, byte month, byte day);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		take top number of floating point stack and pops it into
		the num double pointer passed as a parameter

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
FLOATGETDATENUMBER	proc	far	year:word,
					month:word,	; actually byte
					day:word	; actually byte
	.enter
	mov	bl, {byte}month		
	mov	bh, {byte}day
	mov	ax, year
	call	FloatGetDateNumber
	.leave
	ret
FLOATGETDATENUMBER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatGetTimeNumber

C DECLARATION:	extern FloatErrorType
		     _far FloatGetTimeNumber(byte hours, 
					     byte minutes,
					     byte seconds);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
FLOATGETTIMENUMBER	proc	far	hours:word,	; actually word
					minutes:word,	; actually byte
					seconds:word	; actually byte
	.enter
	mov	ch, {byte}hours
	mov	dl, {byte}minutes
	mov	dh, {byte}seconds
	call	FloatGetTimeNumber
	.leave
	ret
FLOATGETTIMENUMBER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatDateNumberGetMonthAndDay

C DECLARATION:	extern void
			_far FloatDateNumberGetMonthAndDay(byte *month, 
							   byte *day);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
FLOATDATENUMBERGETMONTHANDDAY	proc	far	monthPtr:fptr,
						dayPtr:fptr
	uses	es, di
	.enter
	call	FloatDateNumberGetMonthAndDay
	les	di, monthPtr
	mov	{byte}es:[di], bl
	les	di, dayPtr
	mov	{byte}es:[di], bh
	.leave
	ret
FLOATDATENUMBERGETMONTHANDDAY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatSetStackPointer

C DECLARATION:	extern void
			_far FloatSetStackPointer(word newValue);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		Primarily for use by applications for error recovery.
		Applications can bail out of involved operations by saving
		the stack pointer prior to commencing operations and
		restoring the stack pointer in the event of an error.

		NOTE:
		-----
		If you set the stack pointer, the current stack pointer
		must be less than or equal to the value you pass. Ie.
		you must be throwing something (or nothing) away.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
FLOATSETSTACKPOINTER	proc	far	newValue:word
	.enter
	mov	ax, newValue
	call	FloatSetStackPointer
	.leave
	ret
FLOATSETSTACKPOINTER	endp

	

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatRoll

C DECLARATION:	extern void
			_far FloatRoll(word N);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
FLOATROLL	proc	far	num:word
	.enter
	mov	bx, num
	call	FloatRollFar
	.leave
	ret
FLOATROLL	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatRollDown

C DECLARATION:	extern void
			_far FloatRollDown(word N);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
FLOATROLLDOWN	proc	far	num:word
	.enter
	mov	bx, num
	call	FloatRollDownFar
	.leave
	ret
FLOATROLLDOWN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatPick

C DECLARATION:	extern void
			_far FloatPick(word N);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
FLOATPICK	proc	far	num:word
	.enter
	mov	bx, num
	call	FloatPickFar
	.leave
	ret
FLOATPICK	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatRandomize

C DECLARATION:	extern void
			_far FloatRandomize(RandomGenInitFlag randominitflag, 
						dword seed);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@


FLOATRANDOMIZE	proc	far	initFlag:word, seed:dword
	.enter
	mov	ax, initFlag
	mov	cx, seed.high
	mov	dx, seed.low
	call	FloatRandomizeFar
	.leave
	ret
FLOATRANDOMIZE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatFormatGeos80Number

C DECLARATION:	extern void Boolean
			_far _pascal FloatFormatGeos80Number
    				    (word formatToken, 
				     word userDefBlkHan,
				     word userDefFileHan,
				     void *floatNum, void *resultLocation);
		
Pass VM block handle of array containing user defined formats in userDefBlkHan.
If (userDefBlkHan == 0), userDefFileHan will not be used.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
FLOATFORMATGEOS80NUMBER	proc	far 	formatToken:word, 
					userDefBlkHan:word,
					userDefFileHan:word,
					floatNum:fptr,
					resultLocation:fptr
	uses ds,di,si
	.enter

	lds	si, floatNum
	les	di, resultLocation
	mov	ax, formatToken
	mov	cx, userDefBlkHan
	mov	bx, userDefFileHan
	call	FloatFormatNumber
	mov	ax, 0		; Leave this as a mov, so the carry is left
				; alone.
	jc	done
	dec 	ax
done:
	.leave
	ret
FLOATFORMATGEOS80NUMBER	endp

C_Float	ends

	SetDefaultConvention



