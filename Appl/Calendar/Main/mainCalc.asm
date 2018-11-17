COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar\Main
FILE:		mainCalc.asm

AUTHOR:		Don Reeves, March 25, 1991

ROUTINES:
	Name			Who   	Description
	----			---   	-----------
	CalcDateAltered		GLB	Get date from offset to current date
	CalcDaysInRange		GLB	Get number of days in passed range
	CalcDayOfWeek		GLB	Calculate day of week for passed date
	IsLeapYear		GLB	Determines if year is a leap year
	CalcDaysInMonth		GLB	Get number of days in the passed month
	CheckFiftyThreeWeeks	GLB	Tells if there's 53 weeks in a year
	CalcWeekNumber		GLB	Calculates the week number for a date
	MinutesToTime		GLB	Convert no. of minutes to time. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/25/91		Broken out from mainCalendar.asm

DESCRIPTION:
	Contains all the date calculation code

	$Id: mainCalc.asm,v 1.1 97/04/04 14:47:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode segment resource

include		data.def			; month length & starting info


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDateAltered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a date N days before or after the current date

CALLED BY:	GLOBAL

PASS:		BP	= Year
		DH	= Month
		DL	= Day
		CX	= Days to desired date (+ or -)

RETURN:		BP	= New year
		DH	= New month
		DL	= New day
		Carry	= Clear if a valid year
			= Set if not (less than 1900, greater than 9999)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Loop forward or backward in time, until CX is a positive
		number less than or equal to the number of days in the
		current month.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	Don	11/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcDateAltered	proc	far
	uses	ax, bx, cx
	.enter

	; Determine direction to loop
	;
	mov	bx, cx				; store day offset in CX
	mov	cl, dl
	clr	ch				; today's day in CH
	cmp	bx, 0
	jl	backward

	; Set up the forward looping
	;
	add	bx, cx					
loopForward:
	call	CalcDaysInMonth
	mov	cl, ch
	clr	ch
	cmp	bx, cx				; cur day with days in month
	jle	done				; we're done
	sub	bx, cx
	inc	dh
	cmp	dh, 12
	jle	loopForward
	mov	dh, 1
	inc	bp
	jmp	loopForward

	; Set up the backward looping
	;
backward:
	add	bx, cx
loopBackward:
	cmp	bx, 0				; a positive day
	jg	done
	dec	dh				; back up one month
	jg	LB_10
	mov	dh, 12
	dec	bp
LB_10:
	call	CalcDaysInMonth
	mov	cl, ch
	clr	ch
	add	bx, cx
	jmp	loopBackward

	; We're done - clean up (set carry if invalid year)
	;
done:		
	mov	dl, bl				; store the new day in DL
	cmp	bp, LOW_YEAR			; compare with low year
	jl	exit				; jump if less (carry set)
	cmp	bp, HIGH_YEAR+1			; compare with the high year
	cmc					; invert the carry flag
exit:
	.leave
	ret
CalcDateAltered	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDaysInRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the number of days in a range M/D/Y -> M/D/Y

CALLED BY:	GLOBAL

PASS:		ES:BP	= RangeStruct

RETURN:		CX	= # of days in the range

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcDaysInRange	proc	far
	uses	bx, dx, si
	.enter

	; Perform some set-up work
	;
	mov	si, bp				; ES:SI points to the struct
	mov	bp, es:[si].RS_startYear	; starting year
	mov	dx, {word} es:[si].RS_startDay	; starting month & day
	clr	bx				; clear the counter

	; Loop through the months, adding up the days
	;
dayLoop:
	cmp	bp, es:[si].RS_endYear
	jne	calc
	cmp	dh, es:[si].RS_endMonth
	je	done				; we're done
calc:
	call	CalcDaysInMonth			; get the days in the month
	sub	ch, dl				; take care of starting day
	mov	cl, ch
	clr	ch
	add	bx, cx				; keep a running total
	clr	dl				; first day this month
	inc	dh
	cmp	dh, 12
	jle	dayLoop
	mov	dh, 1
	inc	bp
	jmp	dayLoop

	; We're done, except for difference in the current month
	;
done:
	mov	cl, es:[si].RS_endDay
	clr	ch
	sub	cl, dl				; subtract start from end
	add	bx, cx				; add to the running total
	inc	bx				; must add one day
	mov	cx, bx				; move total to CX
	mov	bp, si				; SS:BP points to RangeStruct
	
	.leave
	ret
CalcDaysInRange	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 		CalcDayOfWeek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate 1st day of week of for given (month,year)

CALLED BY:	MonthDraw

PASS:		BP	= desired year
		DH	= desired month (Jan = 1; Dec = 12)
		DL	= desired day

RETURN: 	CL	= day of the week

DESTROYED:	CH

PSEUDO CODE/STRATEGY:
		Calculate day "shifts" between base year and needed year
		
	DayofWeek = ((this year - base year) + leap years in that interval
			+ monthOffset[this month]) mod (daysinWeek = 7)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/12/89		Initial version
	Don	7/6/89		Fixed up leap year stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcDayOfWeek	proc	far
	uses	ax, bx, si, es
	.enter

	; Calculate difference between this year and base year
	;
	mov	bx, bp				; move year
	sub	bx, BASE_YEAR			; find difference
	jz	almostDone			; if 1900, skip this mess
	mov	cx, bx				; diff in CX
	mov	ax, bx				; diff in AX

	; Now account for leap years (running total in BX)
	;
	dec	cx				; ignore the current year
	shr	cx, 1
	shr	cx, 1				; divide by 4
	add	bx, cx				; add in leap years

	; No leap years on century marks
	;
	dec	ax				; ignore the current year
	push	dx				; save the reg
	clr	dx
	mov	cx, 100				; set up divide
	div	cx				; divide 
	sub	bx, ax				; update count
	pop	dx				; restore this register

	; Except on years evenly divisible by 400
	;
	add	al, 3				; ease the math
	shr	ax, 1
	shr	ax, 1				; divide by 4
	add	bx, ax				; update the count

	; What if this year is a leap year ??
	;
	cmp	dh, 2				; compare month with Feb
	jle	almostDone			; leap year doesn't matter
	call	IsLeapYear			; is this year a leap year ?
	jnc	almostDone			; carry clear - not a leap year
	inc	bx				; add one day for leap year

	; Add in the base day & month offset
	;
almostDone:
	add	bx, BASE_DAY			; add in base day
	mov	ax, bx				; total day offset to AX
	mov	bl, dh
	clr	bh
	mov	cl, {byte}cs:[monthOffsets][bx]	; add month offset
	add	cl, dl				; account for day of month
	dec	cl				; 1st day is zero offset
	clr	ch
	add	ax, cx				; update total day offset

	; Finally - one big divide
	;
	push	dx				; save the month & day
	clr	dx
	mov	cx, 7				; set up divide
	div	cx				; days mod 7
	mov	cl, dl				; day of week to CL
	pop	dx				; restore this registers
	
	.leave
	ret
CalcDayOfWeek	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsLeapYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the given year is a leap year

CALLED BY:	GLOBAL

PASS:		BP	= Year

RETURN:		Carry	= Set if a leap year
			= Clear if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsLeapYear	proc	far
	uses	ax, cx, dx
	.enter

	; Is the year divisible by 4
	;
	mov	ax, bp				; year to BP
	and	ax, 3				; is a leap year?
	jnz	done				; carry is clear

	; Maybe a leap year - check for divisible by 100
	;
	mov	ax, bp				; get the year again
	clr	dx				; clear the high byte
	mov	cx, 100				; set up divisor
	div	cx				; is it a century ??
	tst	dx				; check remainder
	jne	setCarry			; a leap year - carry clear

	; Still a leap year if divisible by 400 (at this point by 4)
	;
	and	ax, 3				; is evenly divisble by 4 ??
	jnz	done				; no
setCarry:
	stc					; set carry for leap year
done:
	.leave
	ret
IsLeapYear	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDaysInMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the number of days in a month

CALLED BY:	GLOBAL

PASS:		BP	= Year
		DH	= Month

RETURN:		CH	= Days in the month

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/2/89		Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcDaysInMonth	proc	far
	uses	ax, bx, si, es
	.enter

	; First get number of days in this month
	;
	mov	bl, dh				; month to BL
	clr	bh				; make it a word
	mov	ch, {byte}cs:[monthLengths][bx]	; get days in this month

	; Now look for a leap year
	;
	cmp	dh, 2				; is the month February
	jne	done				; no - we're done
	call	IsLeapYear			; is it a leap year ?
	jnc	done
	inc	ch				; add a day
done:	
	.leave
	ret
CalcDaysInMonth	endp

if WEEK_NUMBERING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFiftyThreeWeeks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells if there's 53 weeks in year passed.

CALLED BY:	Global

PASS:		bp	= year 

RETURN:		carry set 	= YES, fifty-three weeks in year
		carry clear 	= NO, only fifty-two weeks in year

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		We have 53 weeks in year if the following conditions
		apply:
			1) Jan 1 starts on a Thursday
			2) Jan 1 starts on Wednesday &
			    this is a leap year.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	4/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFiftyThreeWeeks	proc	far
	uses	cx,dx
	.enter

	; Get day of week for Jan 1.
	;
	mov	dl, 1
	mov	dh, 1
 	call	CalcDayOfWeek		; cl = dow for Jan 1	
	
	; If Jan 1 was Thurday, then there are 53 weeks for that year
	;
	cmp	cl, 4			; Thursday ?
	stc				; assume yes
	je	exit
	
	; If Jan 1 was Wednesday, then there are 53 weeks only if 
	; it's a leap year.
	;
	cmp	cl, 3			; Wednesday ?
	je	testLeapYear		; yes--test leap year
	
	clc				; not 53 weeks
exit:
	.leave
	ret

testLeapYear:
	mov	dx, bp			; dx = year
	test 	dl, 00000011b		; leap year ? ( /4 equally)
	stc				; assume yes
	jz	exit
	clc				; not leap year--52 weeks in year
	jmp	exit

CheckFiftyThreeWeeks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcWeekNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the week number for a date

CALLED BY:	Global

PASS:		ax	= Year
		bl	= Month (1-12)
		bh	= Day (1-31)
				
RETURN:		ax	= Week number
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	calculate days between Jan 1 and passed date
	;
	MUST ADD DAYS WHICH ARE MISSING IN FIRST WEEK
	(sean 12/12/95)
	; 
	divide it by 7 and add 1 to get week number

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RR	4/20/95    	Initial version
	sean	10/5/95		Fixed one day too many bug
	sean 	12/12/95	Fixed bugs #48617 & #48114
	sean	4/4/96		Fixed 53 week year problem.
				Fixes #54031.
	awu	1/21/97		Moved over and modified from
				MonthDrawWeekNumbers.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcWeekNumber	proc	far
	range	local	RangeStruct	; Jan 1 to month 1
	totalWeeks	local	byte	
	uses	bx,cx,dx,si,di,bp
	.enter

	mov	range.RS_startDay, 1
	mov	range.RS_startMonth, 1

	mov	range.RS_endDay, bh
	mov	range.RS_endMonth, bl

	mov	range.RS_startYear, ax
	mov	range.RS_endYear, ax

;; How many weeks are there this year?
		mov	totalWeeks, 52
		push	bp
		mov	bp, ax
		call	CheckFiftyThreeWeeks
		pop	bp
		jnc	not53
		mov	totalWeeks, 53
not53:		

	push	es, bp
	segmov	es, ss, ax
	lea	bp, range
	call	CalcDaysInRange			; days in cx
	dec	cx			; range inclusive--decrement(sean)
	pop	es, bp
	mov	ax, cx			

	push	bp
	mov	dl, 1
	mov	dh, 1
	mov	bp, range.RS_startYear
	call	CalcDayOfWeek		; cl = dow for Jan 1
	pop 	bp

 	; if Jan 1 is fri, sat, or sun, add 1 to week #

	tst	cl			; check for sunday
	jne	checkFri
	dec	ax			; Year starts Jan 2
	jmp	doDivide

checkFri:
	cmp	cl, 5
	jne	checkSat		; check fri
	sub	ax, 3			; year starts Jan 4
	jmp	doDivide

checkSat:
	cmp	cl, 6
	jne	notFriSatSun
	sub	ax, 2			; year starts Jan 3
	jmp	doDivide

	; We have to add the number of days that we're missing in
	; first week.  For example, if Jan 1st is on a Wed., then
	; the first week can only hold 5 days, and we must add two
	; days for our upcoming division.  sean 12/12/95.  Fixes
	; #48114 & #48617.
	;
notFriSatSun:
	dec	cl			; cl = number of days missing
	clr	ch
	add	ax, cx			; in first week of year
	
doDivide:
		tst	ax
		jge	normalOp
		push	bp
		mov	bp, range.RS_startYear
	;; Check previous year
		dec	bp
		call	CheckFiftyThreeWeeks
		pop	bp
		mov	ax, 53
		jc	exit
		mov	ax, 52
		jmp	exit
normalOp:		
	mov	dl, 7		; divide range by 7 to get week #
	div	dl
	inc	al			; al = week #
;; Check that we don't go past week 52 (or 53 if this year has an
;; extra week
		cmp	al, totalWeeks
		jle	exit

		sub	al, totalWeeks
exit:
		clr	ah
		.leave
	ret
CalcWeekNumber	endp
		
endif


CommonCode ends

