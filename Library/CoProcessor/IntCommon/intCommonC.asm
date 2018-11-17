COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		intCommonC.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/12/92		Initial version.

DESCRIPTION:
	c stubs for hardware library

	$Id: intCommonC.asm,v 1.1 97/04/04 17:48:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


	SetGeosConvention

C_Float	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATINIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatInit

C DECLARATION:	extern void _far_pascal FloatInit(word stackSize);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global INTEL80X87INIT:far
INTEL80X87INIT	proc	far	;stackSize:word
	C_GetTwoWordArgs		ax, bx, cx, dx		;ax <- size
	call	FloatInit
	ret
INTEL80X87INIT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatAsciiToFloat

C DECLARATION:	extern void Boolean
			_far _pascal FloatAsciiToFloat
    				    (word floatAtoFflags, word stringLength,
				     void *string, void *resultLocation);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	2/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87ASCIITOFLOAT:far
INTEL80X87ASCIITOFLOAT	proc	far	floatAtoFflags:word, stringLength:word,
					string:fptr, resultLocation:fptr
			uses ds,di,si

	.enter

	lds	si, string
	les	di, resultLocation
	mov	ax, floatAtoFflags
	mov	cx, stringLength
	call	FloatAsciiToFloat
	mov	ax, 0			; (don't destroy carry)
	jnc	done
	dec 	ax
done:
	.leave
	ret
INTEL80X87ASCIITOFLOAT	endp

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
global INTEL80X87COMP:far
INTEL80X87COMP	proc	far 	

	call	FloatComp
	jmp	compFinishCommon

INTEL80X87COMP	endp


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
global INTEL80X87COMPANDDROP:far
INTEL80X87COMPANDDROP	proc	far 	
	on_stack	retf

	call	FloatCompAndDrop

compFinishCommon	label far
	pushf			; XXX: why?
	on_stack	cc retf
	mov	ax, 0		; assume equal
	jz	done
	dec	ax		; X1 < X2 (doesn't change carry)
	jc	done		
	mov	ax, 1		; X1 > X2
done:
	popf
	on_stack	retf
	ret
INTEL80X87COMPANDDROP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatCompESDI

C DECLARATION:	extern word 
			_far FloatCompESDI()
	Returns: 0  if X1 = X2
		 1  if X1 > X2
		-1  if X1 < X2


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87COMPESDI:far
INTEL80X87COMPESDI	proc	far 	floatPtr:fptr
	uses	es,di
	.enter
	les	di, floatPtr
	call	FloatCompESDI
	.leave
	jmp	compFinishCommon
INTEL80X87COMPESDI	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatPushNumber

C DECLARATION:	extern word 
			_far FloatPushNumber(FloatNum *number)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87PUSHNUMBER:far
INTEL80X87PUSHNUMBER	proc	far 	number:fptr 
	
				uses ds, si, es
		.enter
		lds	si, number
		call	FloatPushNumber
		mov	ax, 0	;assume no error
		jnc	done
		dec	ax
done:
		.leave
		ret

INTEL80X87PUSHNUMBER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatPopNumber

C DECLARATION:	extern word 
			_far FloatPopNumber(FloatNum *number)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	3/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87POPNUMBER:far
INTEL80X87POPNUMBER	proc	far 	number:fptr 
	
				uses di, es
		.enter
		les	di, number
		call	FloatPopNumber
		mov	ax, 0	;assume no error
		jnc	done
		dec	ax
done:
		.leave
		ret

INTEL80X87POPNUMBER	endp

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
global INTEL80X87STRINGGETDATENUMBER:far
INTEL80X87STRINGGETDATENUMBER	proc	far 	dateString:fptr 
	
				uses di, es
		.enter
		les	di, dateString
		call	FloatStringGetDateNumber
		mov	ax, 0	;assume no error
		jnc	done
		dec	ax
done:
		.leave
		ret

INTEL80X87STRINGGETDATENUMBER	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatFloatToAscii_StdFormat

C DECLARATION:	extern void Boolean
			_far _pascal FloatFloatToAscii_StdFormat


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	2/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87FLOATTOASCII_STDFORMAT:far
INTEL80X87FLOATTOASCII_STDFORMAT	proc	far 	string:fptr,
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
INTEL80X87FLOATTOASCII_STDFORMAT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatFloatToAscii

C DECLARATION:	extern word
			_far _pascal FloatFloatToAscii_StdFormat
			(FFA_stackFrame *stackFrame,
			 char *resultString,
			 FloatNum *number)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	4/27/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87FLOATTOASCII:far
INTEL80X87FLOATTOASCII	proc	far 		stackFrame:fptr,
						resultString:fptr,
						number:fptr

	uses	ax, es, ds, si, di
	.enter	

	les	di, resultString
	lds	si, number

	push 	bp
	mov	bp, stackFrame.low
	add	bp, (size FFA_stackFrame)	; add size of variable

	call	FloatFloatToAscii
	pop	bp

	mov_tr	ax, cx			; put number of digits in ax
	.leave
	ret
INTEL80X87FLOATTOASCII	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatFloatIEEE64ToAscii_StdFormat

C DECLARATION:	extern word
			_far _pascal FloatFloatToAscii_StdFormat
			(char *string, IEEE64FloatNum number,
			 FloatFloatToAsciiFormatFlags format,
			 word numDigits, word numFractionalDigits)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87FLOATIEEE64TOASCII_STDFORMAT:far
INTEL80X87FLOATIEEE64TOASCII_STDFORMAT	proc	far 	string:fptr,
						number:IEEE64,
						format:word,
						numDigits:word,
						numFractionalDigits:word

	bigfloat	local	FloatNum
	uses	es, ds, si, di
	.enter	

	segmov	ds, ss
	lea	si, number		; ds:si <- IEEE64 number
	call	FloatIEEE64ToGeos80	; puts a Geos80 float of FP stack
	lea	di, bigfloat
	segmov	es, ss	
	call	FloatPopNumber		; put Geos80 float in local variable
	
	segmov	ds, ss
	mov	si, di			; ds:si <- IEEE64 number
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
INTEL80X87FLOATIEEE64TOASCII_STDFORMAT	endp

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
global INTEL80X87STRINGGETTIMENUMBER:far
INTEL80X87STRINGGETTIMENUMBER	proc	far 	timeString:fptr 
	
				uses di, es
		.enter
		les	di, timeString
		call	FloatStringGetTimeNumber
		mov	ax, 0	;assume no error
		jnc	done
		dec	ax
done:
		.leave
		ret

INTEL80X87STRINGGETTIMENUMBER	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global INTEL80X87EQ0:far
INTEL80X87EQ0	proc	far 	

	call	FloatEq0	; carry set if value was zero
	mov	ax, 0		; assume X <> 0 and preserve carry flag
	jnc	done
	inc	ax		; X = 0
done:
	ret
INTEL80X87EQ0	endp


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
global INTEL80X87LT0:far
INTEL80X87LT0	proc	far 	

	call	FloatLt0
	mov	ax, 1		; assume X < 0
	jc	done
	dec	ax		; X <> 0
done:
	ret
INTEL80X87LT0	endp

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
global INTEL80X87GT0:far
INTEL80X87GT0	proc	far 	

	call	FloatGt0
	mov	ax, 1		; assume X > 0
	jc	done
	dec	ax		; X <= 0
done:
	ret
INTEL80X87GT0	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		INTEL80X87ROUND
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	round of the top of the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/23/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global INTEL80X87ROUND:far
INTEL80X87ROUND	proc	far
	C_GetOneWordArg	ax, 	cx, dx		; al <- numDecimalPlaces
	call	FloatRound
	ret
INTEL80X87ROUND	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		INTEL80X87SETSTACKSIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the stack size in number of elements

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global INTEL80X87SETSTACKSIZE:far
INTEL80X87SETSTACKSIZE	proc	far
	C_GetOneWordArg	ax, 	cx, dx		; ax <- stack size
	call	FloatSetStackSize
	ret
INTEL80X87SETSTACKSIZE	endp




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
global INTEL80X87GEOS80TOIEEE64:far
INTEL80X87GEOS80TOIEEE64	proc	far	numPtr:fptr
	uses	es, di
	.enter
	les	di, numPtr
	call	FloatGeos80ToIEEE64
	.leave
	ret
INTEL80X87GEOS80TOIEEE64	endp

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
global INTEL80X87GEOS80TOIEEE32:far
INTEL80X87GEOS80TOIEEE32	proc	far	numPtr:fptr
	uses	es, di
	.enter
	call	FloatGeos80ToIEEE32		; dx:ax = value
	les	di, numPtr
	mov	es:[di].low, ax
	mov	es:[di].high, dx
	.leave
	ret
INTEL80X87GEOS80TOIEEE32	endp

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
global INTEL80X87IEEE32TOGEOS80:far
INTEL80X87IEEE32TOGEOS80	proc	far	numPtr:fptr
	uses	es, di
	.enter
	les	di, numPtr
	mov	ax, es:[di].low
	mov	dx, es:[di].high
	call	FloatIEEE32ToGeos80	
	.leave
	ret
INTEL80X87IEEE32TOGEOS80	endp

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
global INTEL80X87IEEE64TOGEOS80:far
INTEL80X87IEEE64TOGEOS80	proc	far	numPtr:fptr
	uses	ds, si
	.enter
	lds	si, numPtr
	call	FloatIEEE64ToGeos80	
	.leave
	ret
INTEL80X87IEEE64TOGEOS80	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatWordToFloat

C DECLARATION:	extern void
			_far FloatWordToFloat(word num);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		convert the long number passed in to an 80 bit floating point 
		number on the top of the stack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87WORDTOFLOAT:far
INTEL80X87WORDTOFLOAT	proc	far
	C_GetOneWordArg	ax,	cx, dx		; ax <- word
	call	FloatWordToFloat
	ret
INTEL80X87WORDTOFLOAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatDwordToFloat

C DECLARATION:	extern void
			_far FloatDwordToFloat(long num);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		convert the long number passed in to an 80 bit floating point 
		number on the top of the stack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87DWORDTOFLOAT:far
INTEL80X87DWORDTOFLOAT	proc	far
	C_GetOneDWordArg	dx, ax,	bx, cx	; dxax <- num
	call	FloatDwordToFloat
	ret
INTEL80X87DWORDTOFLOAT	endp

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
global INTEL80X87GETDAYSINMONTH:far
INTEL80X87GETDAYSINMONTH	proc	far
	C_GetTwoWordArgs ax, bx,	cx, dx	; ax <- year, bx <- month
	call	FloatGetDaysInMonth
	mov_tr	ax, bx			; ax = # of days in month
	clr	ah			; zero-extend
	ret
INTEL80X87GETDAYSINMONTH	endp	


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
global INTEL80X87GETDATENUMBER:far
INTEL80X87GETDATENUMBER	proc	far	year:word,
					month:word,	; actually byte
					day:word	; actually byte
	.enter
	mov	bl, {byte}month		
	mov	bh, {byte}day
	mov	ax, year
	call	FloatGetDateNumber
	.leave
	ret
INTEL80X87GETDATENUMBER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatGetTimeNumber

C DECLARATION:	extern FloatErrorType
		     _far FloatGetTimeNumber(byte hours, 
					     byte minutes,
					     byte seconds);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		take top number of floating point stack and pops it into
		the num double pointer passed as a parameter

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87GETTIMENUMBER:far
INTEL80X87GETTIMENUMBER	proc	far	hours:word,	; actually word
					minutes:word,	; actually byte
					seconds:word	; actually byte
	.enter
	mov	ch, {byte}hours
	mov	dl, {byte}minutes
	mov	dh, {byte}seconds
	call	FloatGetTimeNumber
	.leave
	ret
INTEL80X87GETTIMENUMBER	endp

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
global INTEL80X87DATENUMBERGETMONTHANDDAY:far
INTEL80X87DATENUMBERGETMONTHANDDAY	proc	far	monthPtr:fptr,
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
INTEL80X87DATENUMBERGETMONTHANDDAY	endp


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
global INTEL80X87SETSTACKPOINTER:far
INTEL80X87SETSTACKPOINTER	proc	far
	C_GetOneWordArg	ax, 	cx, dx		; ax <- new stack ptr
	call	FloatSetStackPointer
	ret
INTEL80X87SETSTACKPOINTER	endp

	

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
global INTEL80X87ROLL:far
INTEL80X87ROLL	proc	far
	C_GetOneWordArg	bx, 	cx, dx		; bx <- roll amount
	call	FloatRoll
	ret
INTEL80X87ROLL	endp

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
global INTEL80X87ROLLDOWN:far
INTEL80X87ROLLDOWN	proc	far
	C_GetOneWordArg	bx, 	cx, dx	; bx <- roll amount
	call	FloatRollDown
	ret
INTEL80X87ROLLDOWN	endp

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
global INTEL80X87PICK:far
INTEL80X87PICK	proc	far
	C_GetOneWordArg	bx, 	cx, dx		; bx <- num
	call	FloatPick
	ret
INTEL80X87PICK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FloatRandomize

C DECLARATION:	extern void
			_far FloatRandomize(RandomGenInitFlag rgitflag,
						dword seed);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/92		Initial version

------------------------------------------------------------------------------@
global INTEL80X87RANDOMIZE:far
INTEL80X87RANDOMIZE	proc	far	rgiflag:word, seed:dword
	uses	ds, di
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	ds, ax
	mov	ax, rgiflag
	mov	cx, seed.high
	mov	dx, seed.low
	call	FloatRandomizeInternal
	call	MemUnlock
	clr	ax
	call	FloatHardwareLeave
done:		
	.leave
	ret
INTEL80X87RANDOMIZE	endp

C_Float	ends

	SetDefaultConvention
