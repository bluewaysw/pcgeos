
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
	Routines are grouped togerther thus:
	    Global routines
	    Date routines
	    Time routines

	A Date Number is the number of days from Jan 1, 1900 (date
	number 1) to through December 31, 2099 (date number 73049).
	NOTE: PC/GEOS date numbers differ from Lotus 1-2-3 date numbers
	because Lotus counts Feb 29, 1900, a date that did not exist,
	so PC/GEOS dates after that will alyays be one higher.

	Time Numbers are consecutive decimal values that correspond
	to times from midnight (time number 0.000000) through 11:59:59 PM
	(time number 0.999988)
		
	$Id: floatDateTime.asm,v 1.1 97/04/05 01:22:55 newdeal Exp $

-------------------------------------------------------------------------------@

;*******************************************************************************
;	GLOBAL ROUTINES
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	Global routines

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		possible parameters:
		    ax, bx, cx, dx
		    date/time number on fp stack

RETURN:		see individual routines

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGetDateNumber

DESCRIPTION:	Get the date number for the given date.
		A Date Number is the number of days from Jan 1, 1900 (date
		number 1) to through December 31, 2099 (date number 73050).

		NOTE: PC/GEOS date numbers differ from Lotus 1-2-3 date numbers
		because Lotus counts Feb 29, 1900, a date that did not exist.

CALLED BY:	Global

PASS:		ax - year (1900 through 2099)
		bl - month (1 through 12)
		bh - day (1 through 31)

RETURN:		carry clear if successful
		    date number on the fp stack
		else carry set
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	use dx:ax to track number of days

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatGetDateNumber	proc	far
	call	GetDateNumber
	ret
FloatGetDateNumber	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FLOATDATENUMBERGETYEAR

DESCRIPTION:	Given a date number, extract the year.

CALLED BY:	Global

PASS:		date number on the fp stack

RETURN:		ax - year
		date number popped off the fp stack

DESTROYED:	carry set if error
		    al - error code (FLOAT_GEN_ERR)
		carry clear otherwise

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FLOATDATENUMBERGETYEAR	proc	far
	call	DateNumberGetYear
	ret
FLOATDATENUMBERGETYEAR	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDateNumberGetMonthAndDay

DESCRIPTION:	Given a date number, extract the month.

CALLED BY:	Global

PASS:		date number on the fp stack

RETURN:		bl - month
		bh - day
		date number popped off the fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	remove number of days in the years preceeding the current one from
	    the date number
	scan down the daysRunningTotal table to get the month and the day

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatDateNumberGetMonthAndDay	proc	far
	call	DateNumberGetMonthAndDay
	ret
FloatDateNumberGetMonthAndDay	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FlOATDATENUMBERGETWEEKDAY

DESCRIPTION:	Given a date number, return the day of the week.  The day
		ranges from 1 (Sunday) to 7 (Saturday).

CALLED BY:	Global

PASS:		date number on the fp stack

RETURN:		weekday number on the fp stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FLOATDATENUMBERGETWEEKDAY	proc	far
	call	DateNumberGetWeekday
	ret
FLOATDATENUMBERGETWEEKDAY	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGetTimeNumber

DESCRIPTION:	Calculate a time number given the time.

		Time Numbers are consecutive decimal values that correspond
		to times from midnight (time number 0.000000) through
		11:59:59 PM (time number 0.999988)

CALLED BY:	Global

PASS:		ch - hours (0 through 23)
		dl - minutes (0 through 59)
		dh - seconds (0 through 59)

RETURN:		carry clear if successful
		    time number on the fp stack
		else carry set
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatGetTimeNumber	proc	far
	call	GetTimeNumber
	ret
FloatGetTimeNumber	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FLOATTIMENUMBERGETHOUR

DESCRIPTION:	Get the hour given the time number.

CALLED BY:	Global

PASS:		time number on the fp stack

RETURN:		hour on the fp stack

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FLOATTIMENUMBERGETHOUR	proc	far
	call	TimeNumberGetHour
	ret
FLOATTIMENUMBERGETHOUR	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FLOATTIMENUMBERGETMINUTES

DESCRIPTION:	Get the minutes given the time number.

CALLED BY:	Global

PASS:		time number on the fp stack

RETURN:		minutes on the fp stack

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FLOATTIMENUMBERGETMINUTES	proc	far
	call	TimeNumberGetMinutes
	ret
FLOATTIMENUMBERGETMINUTES	endp
COMMENT @-----------------------------------------------------------------------

FUNCTION:	FLOATTIMENUMBERGETSECONDS

DESCRIPTION:	Get the seconds given the time number.

CALLED BY:	Global

PASS:		time number on the fp stack

RETURN:		seconds on the fp stack

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FLOATTIMENUMBERGETSECONDS	proc	far
	call	TimeNumberGetSeconds
	ret
FLOATTIMENUMBERGETSECONDS	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatStringGetDateNumber

DESCRIPTION:	Parse the sting containing a date and return its date number.

CALLED BY:	global

PASS:		es:di - string to parse

RETURN:		carry clear if successful
		    date number on the fp stack
		    ax = DateTimeFormat
		carry set otherwise
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@

FloatStringGetDateNumber	proc	far
	call	StringGetDateNumber
	ret
FloatStringGetDateNumber	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatStringGetTimeNumber

DESCRIPTION:	parse the string containing a time and return its time number.

CALLED BY:	Global

PASS:		es:di - string to parse

RETURN:		carry clear if successful
		    date number on the fp stack
		carry set otherwise
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@

FloatStringGetTimeNumber	proc	far
	call	StringGetTimeNumber
	ret
FloatStringGetTimeNumber	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGetDaysInMonth

DESCRIPTION:	Given a year and a month, calculate the number of days
		in that month.

CALLED BY:	global

PASS:		ax - year (YEAR_MIN <= ax <= YEAR_MAX)
		bl - month (MONTH_MIN <= bl <= MONTH_MAX)

RETURN:		bh - number of days in the month

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatGetDaysInMonth	proc	far
	call	GetDaysInMonth
	ret
FloatGetDaysInMonth	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFloatToDateTime

DESCRIPTION:	

CALLED BY:	GLOBAL ()

PASS:		FFA_stackFrame containing FloatFloatToDateTimeData
		FFA_dateTimeParams.FFA_dateTimeFlags.FFDT_DATE_TIME_OP must be 1
		if (FFA_dateTimeParams.FFA_dateTimeFlags.FFDT_FROM_ADDR == 1)
		    ds:si = location of number
		es:di - destination address of string
			(at least DATE_TIME_FORMAT_SIZE)

RETURN:		carry clear if successful
		    es:di - the formatted string, null terminated
		    cx - # of characters in formatted string.
			This does not include the NULL terminator at the
			end of the string.
		carry set otherwise
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFloatToDateTime	proc	far	uses	bx,dx,di,si
	locals	local	FFA_stackFrame
	.enter	inherit far

;EC<	call	FloatCheckDateTimeParams >

	call	FloatGetDateTimeParams
	jc	done

	call	LocalFormatDateTime
done:
	.leave
	ret
FloatFloatToDateTime	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGetDateTimeParams

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		FFA_stackFrame containing FloatFloatToDateTimeData
		FFA_dateTimeParams.FFA_dateTimeFlags.FFDT_DATE_TIME_OP must be 1
		if (FFA_dateTimeParams.FFA_dateTimeFlags.FFDT_FROM_ADDR == 1)
		    ds:si = location of number

RETURN:		carry set if error
		else carry clear
		  for LocalFormatDateTime():
		    ax - year
		    bl - month		(1-12)
		    bh - day		(1-31)
		    cl - weekday	(0-6)
		    ch - hours		(0-23)
		    dl - minutes	(0-59)
		    dh - seconds	(0-59)
		    si - DateTimeFormat

DESTROYED:	carry clear is successful
		else carry set
		    al - error code (FLOAT_GEN_ERR)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatGetDateTimeParams	proc	near	uses	ds
	locals	local	FFA_stackFrame
	.enter	inherit far

	mov	ax, locals.FFA_dateTime.FFA_dateTimeParams.FFA_dateTimeFlags
	test	ax, mask FFDT_FROM_ADDR
	LONG je	argInFrame

	call	FloatPushNumberFar
	call	FloatEnterFar
	
	;-----------------------------------------------------------------------
	; distinguish between date and time operation

	and	ax, mask FFDT_FORMAT
	cmp	ax, DTF_START_TIME_FORMATS	; date or time op?
	jge	timeFormat

	;
	; lose any time component
	; truncation is OK because the range of possible date numbers is
	; small enough for every number to be fully represented
	;
	call	FLOATTRUNC

	;
	; error check date number
	;
	mov	ax, DATE_NUMBER_MIN
	call	FloatWordToFloatFar		; ( fp: # min )
	call	FloatCompFar			; # - min
	call	FLOATDROP			; lose min
	jl	error				; error if # < min

	mov	dx, DATE_NUMBER_MAX / 65536
	mov	ax, DATE_NUMBER_MAX and 0ffffh
	call	FloatDwordToFloatFar
	call	FloatCompFar			; # - max
	call	FLOATDROP			; lose max
	jle	dateFormat			; else legal

error:
	mov	si, offset errorStr
	call	FloatCopyErrorStr

	call	FLOATDROP			; lose number
	call	FloatOpDoneFar
	mov	al, FLOAT_GEN_ERR
	stc
	jmp	exit

	;-----------------------------------------------------------------------
	; date format

dateFormat:
	call	FLOATDUP
	call	FLOATTRUNC
	mov	ax, 7
	call	FloatWordToFloatFar
	call	FLOATMOD
	call	FLOATFLOATTODWORD		; dx:ax <- weekday (0-6)
	mov	cl, al

	call	FLOATDUP
	call	DateNumberGetMonthAndDay	; bl <- month,  bh <- day

;;;	call	FLOATDUP			; LOSE NUMBER NOW!
	call	DateNumberGetYear		; ax <- year
	jmp	short formatDone

	;-----------------------------------------------------------------------
	; time format

timeFormat:
	;
	; error check time number
	;
	call	FLOAT0
	call	FloatCompFar
	call	FLOATDROP
	jl	error

	call	FLOATDUP
	call	TimeNumberGetHour
	call	FLOATFLOATTODWORD		; dx:ax <- hour
	mov	ch, al				; ch <- hour
	
	cmp	ch, HOUR_MAX
	ja	error

	call	FLOATDUP
	call	TimeNumberGetMinutes
	call	FLOATFLOATTODWORD		; dx:ax <- hour
	mov	bl, al				; bl <- minutes
	
	cmp	bl, MINUTE_MAX
	ja	error

	call	FLOATDUP
	call	TimeNumberGetSeconds
	call	FLOATFLOATTODWORD		; dx:ax <- seconds
	mov	dh, al				; dh <- seconds
	mov	dl, bl				; dl <- minutes

	cmp	dh, SECOND_MAX
	LONG ja	error
	call	FLOATDROP

formatDone:
	call	FloatOpDoneFar			; nothing destroyed, incl flags
	jmp	short done

	;-----------------------------------------------------------------------
	; parameters supplied in stack frame

argInFrame:
	mov	ax, locals.FFA_dateTime.FFA_dateTimeParams.FFA_year
	mov	bh, locals.FFA_dateTime.FFA_dateTimeParams.FFA_day
	mov	bl, locals.FFA_dateTime.FFA_dateTimeParams.FFA_month
	mov	cl, locals.FFA_dateTime.FFA_dateTimeParams.FFA_weekday
	mov	ch, locals.FFA_dateTime.FFA_dateTimeParams.FFA_hours
	mov	dl, locals.FFA_dateTime.FFA_dateTimeParams.FFA_minutes
	mov	dh, locals.FFA_dateTime.FFA_dateTimeParams.FFA_seconds

done:
	mov	si, locals.FFA_dateTime.FFA_dateTimeParams.FFA_dateTimeFlags
	and	si, mask FFDT_FORMAT

exit:
	.leave
	ret
FloatGetDateTimeParams	endp



;*******************************************************************************
;	DATE ROUTINES
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetDateNumber

DESCRIPTION:	Get the date number for the given date.
		A Date Number is the number of days from Jan 1, 1900 (date
		number 1) to through December 31, 2099 (date number 73050).

CALLED BY:	INTERNAL ()

PASS:		ax - year (1900 through 2099)
		bl - month (1 through 12)
		bh - day (1 through 31)

RETURN:		carry clear if successful
		    date number on the fp stack
		else carry set
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	use dx:ax to track number of days

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
global GetDateNumber:far
GetDateNumber	proc	far	uses	cx,dx,si
	.enter

	call	CheckDateValid
	jc	done

	mov	si, ax			; save year in si

	;-----------------------------------------------------------------------
	; get number of days up to the year given

	call	GetDaysInYearsSinceYearMin	; dx:cx <- date number

	;-----------------------------------------------------------------------
	; get number of days up to, but not including the month given

	push	bx
	clr	bh			; bx <- month
	dec	bx			; dec to get offset
	shl	bx, 1			; get offset into word-based table

	add	cx, cs:daysRunningTotal[bx]
	adc	dx, 0
	pop	bx

	;
	; account for leap years
	;
	cmp	bl, 2			; feb?
	jle	doneMonth		; no accounting if jan or feb

	mov	ax, si			; get year
	call	IsLeapYear		; leap year?
	jnc	doneMonth		; done accounting if non-leap year

	add	cx, 1			; else inc date-number
	adc	dx, 0

doneMonth:

	;-----------------------------------------------------------------------
	; get number of days up to and including the day given

	add	cl, bh
	adc	ch, 0
	adc	dx, 0

	;-----------------------------------------------------------------------
	; dx:cx = date number, convert to floating point

	mov	ax, cx
	call	FloatDwordToFloatFar
done:
	.leave
	ret
GetDateNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckDateValid

DESCRIPTION:	Checks to see if the date given is valid for our purposes.
		A date is valid if it is legal and it falls within our
		defined range.

CALLED BY:	INTERNAL (GetDateNumber)

PASS:		ax - year
		bl - month
		bh - day

RETURN:		carry clear if successful
		else carry set
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

CheckDateValid	proc	near
	cmp	ax, YEAR_MIN
	jl	error

	cmp	ax, YEAR_MAX
	jg	error

	cmp	bl, MONTH_MIN
	jl	error

	cmp	bl, MONTH_MAX
	jg	error

	cmp	bh, DAY_MIN
	jl	error

	cmp	bh, DAY_MAX
	jg	error

	;
	; ok, limits not exceeded
	; now check specifics
	;
	push	cx
	mov	cx, bx			; save num days in cx
	call	GetDaysInMonth		; bh <- num days
	cmp	bh, ch
	mov	bx, cx			; restore num days
	pop	cx
	clc
	jge	done

error:
	mov	al, FLOAT_GEN_ERR
	stc

done:
	ret
CheckDateValid	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetDaysInYearsSinceYearMin

DESCRIPTION:	Calculate the number of days in the years from the year
		YEAR_MIN to the year before the current year.

CALLED BY:	INTERNAL (DateNumberGetMonthAndDay, GetDateNumber)

PASS:		ax - year

RETURN:		dx:cx - answer

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	!!! NOTE !!!

	The code written is not a general solution.

	It taks advantage of 1900 and 2000 being the only centuries in the
	legal range. (2000 is a leap year, 1900 is not)

	let year offset = year - YEAR_MIN
	then number of leap years = (year offset - 1) DIV 4

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

GetDaysInYearsSinceYearMin	proc	near	uses	ax
	.enter
	sub	ax, YEAR_MIN		; ax <- year offset

	push	ax			; save year offset
	mov	cx, YEAR_LENGTH
	mul	cx			; dx:ax <- num days excl leap days
	mov	cx, ax			; save num days
	pop	ax			; retrieve year offset

	tst	ax
	je	done

	dec	ax
	shr	ax, 1
	shr	ax, 1			; year offset DIV 4 = num leap days

	; dx:cx = number of days excluding leap days
	; ax = number of leap days

	add	cx, ax
	adc	dx, 0

done:
	.leave
	ret
GetDaysInYearsSinceYearMin	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetDaysInMonth

DESCRIPTION:	Given a year and a month, calculate the number of days
		in that month.

CALLED BY:	INTERNAL (CheckDateValid)

PASS:		ax - year (YEAR_MIN <= ax <= YEAR_MAX)
		bl - month (MONTH_MIN <= bl <= MONTH_MAX)

RETURN:		bh - number of days in the month

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
global	GetDaysInMonth:far
GetDaysInMonth	proc	far
	.enter

	;
	; error check year
	;
EC<	cmp	ax, YEAR_MIN >
EC<	ERROR_L FLOAT_BAD_ARGUMENT >
EC<	cmp	ax, YEAR_MAX >
EC<	ERROR_G FLOAT_BAD_ARGUMENT >

	;
	; error check month
	;
EC<	cmp	bl, MONTH_MIN >
EC<	ERROR_L FLOAT_BAD_ARGUMENT>
EC<	cmp	bl, MONTH_MAX >
EC<	ERROR_G FLOAT_BAD_ARGUMENT >

	clr	bh
	mov	bh, cs:monthLengths[bx]

	cmp	bl, 2			; feb?
	jne	done

	call	IsLeapYear		; leap year?
	jnc	done			; done if not

	inc	bh			; else add a day

done:
	.leave
	ret
GetDaysInMonth	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	IsLeapYear

DESCRIPTION:	Determines if the given year is a leap year.

CALLED BY:	INTERNAL (GetDateNumber)

PASS:		ax - year

RETURN:		carry set if leap year

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

IsLeapYear	proc	near	uses	ax,cx,dx
	.enter

	;
	; is year divisible by 4?
	;
	test	ax, 3			; leap year?
	jne	done			; branch if not, carry is clear

	;
	; may be a leap year - see if divisible by 100
	;
	clr	dx			; prepare for division
	mov	cx, 100
	div	cx			; century?
	tst	dx			; any remainder?
	jne	leapYear		; branch if leap year (non-century)

	;
	; century
	; may still be a leap year if divisible by 400 (at this point by 4)
	;
	test	ax, 3			; divisible by 4?
	jne	done			; non-leap year if not, carry is clear

leapYear:
	stc

done:
	.leave
	ret
IsLeapYear	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DateNumberGetYear

DESCRIPTION:	Given a date number, extract the year.

CALLED BY:	INTERNAL (+DateNumberGetMonthAndDay)

PASS:		date number on the fp stack

RETURN:		ax - year
		date number popped off the fp stack

DESTROYED:	carry set if error
		    al - error code (FLOAT_GEN_ERR)
		carry clear otherwise

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
global DateNumberGetYear:far
DateNumberGetYear	proc	far	uses	cx,dx,ds,si
	.enter

	call	FLOATTRUNC
	call	FLOATFLOATTODWORD	; dx:ax <- date number
	jc	error

	;-----------------------------------------------------------------------
	; error check the number

	cmp	dx, DATE_NUMBER_MAX / 65536
	ja	error
	jb	checkMin
	cmp	ax, DATE_NUMBER_MAX and 0ffffh
	ja	error
checkMin:
	tst	dx
	jne	doneCheck
	cmp	ax, DATE_NUMBER_MIN
	jb	error


doneCheck:
	;-----------------------------------------------------------------------
	; locate the decade entry

	mov	si, size decadeDateNum - size dword	;si <- last decade

locateLoop:
	cmp	dx, cs:decadeDateNum[si].high
	jb	next
	ja	found

	cmp	ax, cs:decadeDateNum[si].low
	jae	found

next:
	sub	si, size dword
	jmp	locateLoop


	;-----------------------------------------------------------------------
	; dx:ax = date number such that date number >= decadeDateNum

found:
	sub	ax, cs:decadeDateNum[si].low	; ax <- residual number of days

EC<	sbb	dx, cs:decadeDateNum[si].high >
EC<	tst	dx >
EC<	ERROR_NE FLOAT_BAD_DATE >

	;
	; ax = residual number of days
	; need to loop for years
	;
	mov_tr	cx, ax			; cx <- residual number of days

	;
	;  Calculate the decade indicated by si = 10 * (si/size dword)
	;

	mov	ax, si			; ax <- 4 * index
	add	ax, ax			; ax <- 8 * index
	shr	si			; si <- 2 * index
	add	ax, si			; ax <- 10 * index
	add	ax, YEAR_MIN		; ax <- decade year

	;-----------------------------------------------------------------------
	; ax = decade year
	; cx = residual number of days = day offset from jan 1 of decade

	inc	cx
residLoop:
	sub	cx, YEAR_LENGTH		; remove number of days in year
	call	IsLeapYear		; carry set if leap year
	jnc	checkDone

	dec	cx

checkDone:
	tst	cx			; any residual? (carry is cleared)
	jle	done			; done if not

	inc	ax			; up the year
	jmp	short residLoop

error:
EC<	mov	ah, 0ffh >		; make year patently illegal
	mov	al, FLOAT_GEN_ERR
	stc

done:
	.leave
	ret
DateNumberGetYear	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DateNumberGetMonthAndDay

DESCRIPTION:	Given a date number, extract the month.

CALLED BY:	INTERNAL ()

PASS:		date number on the fp stack

RETURN:		bl - month
		bh - day
		date number popped off the fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	remove number of days in the years preceeding the current one from
	    the date number
	scan down the daysRunningTotal table to get the month and the day

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
global DateNumberGetMonthAndDay:far
DateNumberGetMonthAndDay	proc	far	uses	ax,cx,dx,ds,di
	.enter

	call	FLOATDUP		; duplicate date number
	call	DateNumberGetYear	; ax <- year
	jnc	yearOK

	call	FLOATDROP		; lose the number
	jmp	short exit

yearOK:
	call	IsLeapYear
	mov	di, offset daysRunningTotal
	jnc	10$

	mov	di, offset daysRunningTotalLeap

10$:
	call	GetDaysInYearsSinceYearMin	; dx:cx <- answer
	mov	bx, dx			; bx:cx = days in years

	call	FLOATFLOATTODWORD	; dx:ax <- date number
	sub	ax, cx
	sbb	dx, bx			; ax <- residual days

EC<	tst	dx >
EC<	ERROR_NE FLOAT_BAD_DATE >
EC<	cmp	ax, YEAR_LENGTH+1 >
EC<	ERROR_G FLOAT_BAD_DATE >

	;
	; ax = residual days
	; scan down running total table to get the month
	;
	segmov	ds, cs, bx
	mov	bx, (12-1)*2		; bx <- offset to last entry
					; (12 months - 1) * size of each entry
cmpLoop:
	cmp	ax, ds:[bx][di]
	jg	cmpDone

	sub	bx, 2			; next entry
	jmp	short cmpLoop

cmpDone:
	; ax = residual days
	; bx = offset to number of days of prior months

	sub	ax, ds:[bx][di]			; ax <- day
EC<	cmp	ax, DAY_MAX >
EC<	ERROR_G	FLOAT_BAD_DATE >
EC<	cmp	ax, DAY_MIN >
EC<	ERROR_L	FLOAT_BAD_DATE >

	shr	bx, 1
	inc	bx				; bx <- month
EC<	cmp	bx, MONTH_MAX >
EC<	ERROR_G	FLOAT_BAD_DATE >
EC<	cmp	bx, MONTH_MIN >
EC<	ERROR_L	FLOAT_BAD_DATE >

	mov	bh, al				; bh <- day

exit:
	.leave
	ret
DateNumberGetMonthAndDay	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DateNumberGetWeekday

DESCRIPTION:	Given a date number, return the day of the week.  The day
		ranges from 1 (Sunday) to 7 (Saturday).

CALLED BY:	INTERNAL ()

PASS:		date number on the fp stack

RETURN:		weekday number on the fp stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
global DateNumberGetWeekday:far
DateNumberGetWeekday	proc	far	uses	dx
	.enter
	call	FLOATTRUNC
	mov	ax, 7
	call	FloatWordToFloatFar
	call	FLOATMOD

	mov	ax, 1
	call	FloatWordToFloatFar
	call	FLOATADD
	.leave
	ret
DateNumberGetWeekday	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StringGetDateNumber

DESCRIPTION:	Parse the sting containing a date and return its date number.

CALLED BY:	INTERNAL ()

PASS:		es:di - string to parse

RETURN:		carry clear if successful
		    date number on the fp stack
		    ax - DateTimeFormat that matched
		carry set otherwise
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@
global StringGetDateNumber:far
StringGetDateNumber	proc	far	uses	bx,cx,dx,bp,di,si
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	bp, di				; es:bp <- string
	clr	si
	mov	cx, (length stringGetDateNumberLookup)
xlatLoop:
	push	cx,si
	mov	si, cs:stringGetDateNumberLookup[si]	; si <- format
	call	LocalParseDateTime		; modifies ax,bx,cx,dx
	jc	found				;branch if parsed OK
	pop	cx,si

	inc	si
	inc	si
	loop	xlatLoop

	;
	; parsing unsuccessful
	;
	mov	al, FLOAT_GEN_ERR
	stc
	jmp	short done

found:
	mov	dx, -1			;we use this a lot...
	;
	; ax - year
	; bl - month (1-12)
	; bh - day (1-31)
	; cl - weekday (0-6)
	;
	; The checks below are to give the following behavior:
	; "March"	-- 3/1/<this year>
	; "Monday"	-- <nearest month>/nearest Monday/<this year>
	; "3/31"	-- 3/31/<this year>
	; "1993"	-- 1/1/93
	;

	;
	; See if the weekday is the only thing present -- if so
	; we set other stuff based on the current date
	;
	cmp	cl, dl			;weekday present?
	je	skipWeekdayCheck	;branch if no weekday
	cmp	ax, dx			;year present?
	jne	skipWeekdayCheck	;branch if year present
	cmp	bx, dx			;month or day present?
	jne	skipWeekdayCheck	;branch if month or day present
	;
	; There is only a weekday -- use the current month and year,
	; and calculate the nearest day of the specified weekday.
	;
	push	dx
	mov	dl, cl			;dl <- weekday
	call	getCurrentDate
	sub	cl, dl			;cl <- delta to specified weekday
	jnc	newDay
	add	cl, 7			;make sure delta is position
newDay:		
	;
	; Make sure bh is larger than cl, so it won't end up with 
	; negative day. If bh <= cl, we need to add 7 more days
	; in order to make the weekday right.
	;
	sub	bh, cl
	ja	daySet
	add	bh, 7
daySet:
	pop	dx
skipWeekdayCheck:
	;
	; all unknowns are mapped by the localization driver to -1
	; we will map these to the current year, but the first
	; day or month.
	;
	cmp	ax, dx 			; year present?
	jne	afterYear		; branch if so
	push	bx
	call	getCurrentDate
	pop	bx
afterYear:
	cmp	bl, dl			; month present?
	jne	afterMonth		; branch if so
	mov	bl, MONTH_MIN		; bl <- 1st month
afterMonth:
	cmp	bh, dl			; day present?
	jne	afterDay		; branch if so
	mov	bh, DAY_MIN		; bh <- 1st day
afterDay:
	;
	; We've finally got a month/day/year -- make sure it is OK,
	; then convert it to floating point.
	;
	call	CheckDateValid
	jc	skipFormat
	call	GetDateNumber
	jc	skipFormat		;branch if error
	mov	ax, si			;ax <- matching DateTimeFormat
skipFormat:
	pop	cx,si			;clean up cx,si, preserve carry
done:
	.leave
	ret

getCurrentDate:
	push	dx
	call	TimerGetDateAndTime
	pop	dx
	retn
StringGetDateNumber	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	StringGetTimeNumber

DESCRIPTION:	parse the string containing a time and return its time number.

CALLED BY:	INTERNAL ()

PASS:		es:di - string to parse

RETURN:		carry clear if successful
		    date number on the fp stack
		    ax - DateTimeFormat that matched
		carry set otherwise
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@
global StringGetTimeNumber:far
StringGetTimeNumber	proc	far	uses	bx,cx,dx,bp,di,si
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	mov	bp, di				; es:bp <- string
	clr	bx
	mov	ax, (length stringGetTimeNumberLookup)
xlatLoop:

	mov	si, cs:stringGetTimeNumberLookup[bx]	; si <- format
	push	ax,bx
	call	LocalParseDateTime		; modifies ax,bx,cx,dx
	pop	ax,bx
	jc	found

	inc	bx
	inc	bx
	dec	ax				; dec count
	jne	xlatLoop			; loop while not done

	;
	; parsing unsuccessful
	;
	mov	al, FLOAT_GEN_ERR
	stc
	jmp	done

found:
	;
	; ch - hours
	; dl - minutes
	; dh - seconds
	;
	; all unknowns are mapped by the localization driver to -1
	; we will map these to the min values (0)
	;

	cmp	ch, -1
	jne	checkMinutes
	clr	ch
checkMinutes:
	cmp	dl, -1
	jne	checkSeconds
	clr	dl
checkSeconds:
	cmp	dh, -1
	jne	getTimeNumber
	clr	dh
getTimeNumber:
	call	GetTimeNumber

	mov	ax, si				;ax <- matching DateTimeFormat
done:
	.leave
	ret
StringGetTimeNumber	endp


;*******************************************************************************
;	TIME ROUTINES
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetTimeNumber

DESCRIPTION:	Calculate a time number given the time.

		Time Numbers are consecutive decimal values that correspond
		to times from midnight (time number 0.000000) through
		11:59:59 PM (time number 0.999988)

CALLED BY:	INTERNAL ()

PASS:		ch - hours (0 through 23)
		dl - minutes (0 through 59)
		dh - seconds (0 through 59)

RETURN:		carry clear if successful
		    time number on the fp stack
		else carry set
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
global	GetTimeNumber:far
GetTimeNumber	proc	far	uses	bx,dx,si
	.enter

	call	CheckTimeValid
	jc	done

	mov	si, 60
	mov	bx, dx		; save seconds and minutes in bx

	mov	al, ch
	clr	ah

	mul	si		; dx:ax <- hrs * 60
EC<	tst	dx >
EC<	ERROR_NE FLOAT_BAD_TIME >

	add	al, bl		; dx:ax <- hrs * 60 + min
	adc	ah, 0
	mul	si		; dx:ax <- (hrs*60 + min)*60

	add	al, bh		; add seconds
	adc	ah, 0
	adc	dx, 0		; dx:ax = unnormalized time number

	call	FloatDwordToFloatFar
	call	FLOAT86400
	call	FLOATDIVIDE

done:
	.leave
	ret
GetTimeNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckTimeValid

DESCRIPTION:	Checks to see if the time given is valid.

CALLED BY:	INTERNAL (GetTimeNumber)

PASS:		ch - hours
		dl - minutes
		dh - seconds

RETURN:		carry clear if successful
		else carry set
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

CheckTimeValid	proc	near
	cmp	ch, HOUR_MAX
	jg	error

	cmp	dl, MINUTE_MAX
	jg	error

	cmp	dh, SECOND_MAX
	clc
	jle	done

error:
	mov	al, FLOAT_GEN_ERR
	stc

done:
	ret
CheckTimeValid	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	TimeNumberGetHour

DESCRIPTION:	Get the hour given the time number.

CALLED BY:	INTERNAL ()

PASS:		time number on the fp stack

RETURN:		hour on the fp stack

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
global TimeNumberGetHour:far
TimeNumberGetHour	proc	far	uses	dx
	.enter

if 0	; Commented out by Allen on 7/28/95.  (See below)
; Changed 5/19/95 -jw
;
; The problem was that if you did a combination of expressions in GeoCalc,
; you could end up with a seemingly incorrect answer due to a loss of
; precision. For example:
;
;	=hour(time(13,0,0)-time(12,0,0))
;
; would produce zero instead of one, due to a very subtle loss of precision.
;
; By rearranging the order of the instructions, we sort of introduce
; our own loss of precision in the calculation of the number of
; minutes per hour.
;
;	call	FLOATFRAC
;	call	FLOAT86400
;	call	FLOATMULTIPLY
;	call	FLOAT3600
;	call	FLOATDIV

	call	FLOATFRAC
	call	FLOAT86400
	call	FLOAT3600
	call	FLOATDIV
	call	FLOATMULTIPLY
;
; urk!  changing the order no longer leaves us with an integer, so we have
; to dump the fraction -- brianc 7/26/95
;
	call	FLOATINT
endif	; --- AY 7/28/95

;
; For some on-the-hour time values (1am, 2am, 3am, 4am, 8am, 1pm and 4pm),
; calling FLOATINT ends up one hour early (1am becomes 12am, etc.) due to loss
; of precision.  Also hour(time(13,0,0)-time(12,0,0)) results in 0 again after
; calling FLOATINT.  Adding one espilon (FLOATEPSILON) before FLOATINT solves
; the above cases except hour(time(13,0,0)-time(12,0,0)).
;
; The solution is to round off the time value at the sec granularity before
; truncating the value to an hour integer.  The only drawback is if the
; routine is passed time(x,59,59.5), it returns x+1 instead of x.  However
; there is no way for a user to specify a fractional second and pass it to
; this routine without first being rounded off by some other code.  Hence
; the drawback is tolerable.
;
; --- AY 7/28/95
;

	call	FLOATFRAC
	call	FLOAT86400
	call	FLOATMULTIPLY

	; add 0.5sec, for rouding at the sec granularity
	call	FLOATPOINT5
	call	FLOATADD

	call	FLOAT3600
	call	FLOATDIV		; result truncated to integer

	.leave
	ret
TimeNumberGetHour	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	TimeNumberGetMinutes

DESCRIPTION:	Get the minutes given the time number.

CALLED BY:	INTERNAL ()

PASS:		time number on the fp stack

RETURN:		minutes on the fp stack

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
global TimeNumberGetMinutes:far
TimeNumberGetMinutes	proc	far	uses	dx
	.enter
	call	FLOATFRAC
	call	FLOAT86400
	call	FLOATMULTIPLY
	call	FLOAT3600
	call	FLOATMOD
	mov	ax, 60
	call	FloatWordToFloatFar
	call	FLOATDIV
	.leave
	ret
TimeNumberGetMinutes	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	TimeNumberGetSeconds

DESCRIPTION:	Get the seconds given the time number.

CALLED BY:	INTERNAL ()

PASS:		time number on the fp stack

RETURN:		seconds on the fp stack

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
global TimeNumberGetSeconds:far
TimeNumberGetSeconds	proc	far	uses	dx
	.enter
	call	FLOATFRAC
	call	FLOAT86400
	call	FLOATMULTIPLY
	mov	ax, 60
	call	FloatWordToFloatFar
	call	FLOATMOD
	.leave
	ret
TimeNumberGetSeconds	endp

