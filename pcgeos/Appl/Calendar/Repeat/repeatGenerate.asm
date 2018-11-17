COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Repeat
FILE:		repeatGenerate.asm

AUTHOR:		Don Reeves, November 20, 1989

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial revision

DESCRIPTION:
	Contains routines to generate all types of supported repeating
	events, storing the Repeat ID's in the RepeatTable.
		
	$Id: repeatGenerate.asm,v 1.1 97/04/04 14:48:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserts a new RepeatEvent into all the current year tables

CALLED BY:	RepeatStore

PASS:		DS	= DGroup
		ES:0	= Valid block handle
		AX	= RepeatEvent group #
		DX	= RepeatEvent item #

RETURN:		Nothing

DESTROYED:	ES, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenerateInsert	proc	near
	uses	bx, cx, di, bp
	.enter

	; Some set-up
	;
	mov	cx, NUM_REPEAT_TABLES		; loop this many times
	mov	bx, offset repeatTableStructs	; offset to the structures
	
	; Now loop
loopAll:
	mov	bp, ds:[bx].RTS_tableOD.handle
	tst	bp				; a valid handle ??
	je	nextStruct			; if not, jump!
	mov	ds:[tableHandle], bp
	mov	bp, ds:[bx].RTS_tableOD.chunk
	mov	ds:[tableChunk], bp
	mov	bp, ds:[bx].RTS_yearYear
	call	GenerateParse			; perform the insertion
nextStruct:
	add	bx, size RepeatTableStruct	; go to the next structure
	loop	loopAll				; go through all the tables
	
	.leave
	ret
GenerateInsert	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateUninsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Un-Inserts a RepeatEvent from all the current year tables

CALLED BY:	RepeatDelete

PASS:		DS	= DGroup
		ES:0	= Valid block handle
		AX	= RepeatEvent group #
		DX	= RepeatEvent item #

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenerateUninsert	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter

	; Now remove all traces of the RepeatEvent from the RepeatTable
	;
	mov	ds:[repeatGenProc], offset RemoveEvent	; call delete routine
	call	GenerateInsert				; remove the event
	mov	ds:[repeatGenProc], offset AddNewEvent	; back to normal routine

	; Now remove any instances of the RepeatEvent from the DayPlan
	; This is commented out for Responder as one needs to be able to
	; delete repeating events w/o worrying about UI updates (which
	; seems like a much cleaner way of doing stuff anyway).
	;
	GetResourceHandleNS	DPResource, bx
	mov	si, offset DPResource:DayPlanObject
	mov	cx, ax				; group => CX, item in DX
	mov	ax, MSG_DP_DELETE_REPEAT_EVENT	; method to send
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage
	.leave
	ret
GenerateUninsert 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateFixupException
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup an exception for a specific date (either remove the
		reference to the event, or add a reference)

CALLED BY:	GLOBAL

PASS:		DS	= DGroup
		AX	= RepeatStruct Group #
		DL	= Day of exception
		DH	= Month of exception
		BP	= Year of exception
		DI	= RepeatStruct Item #
		SI	= offset to RemoveEvent or AddNewEvent

RETURN:		Nothing

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/26/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_REPEAT_DATE_EXCEPTIONS
GenerateFixupException	proc	near
		uses	bx, cx, si
		.enter
	;
	; Loop through the year tables, and then fix up the reference
	; to the RepeatStruct for the year/month/day in question
	;
EC <		VerifyDGroupDS						>
		mov	ds:[repeatGenProc], si
		mov	cx, NUM_REPEAT_TABLES
		mov	bx, offset repeatTableStructs
tableLoop:
		cmp	ds:[bx].RTS_yearYear, bp
		jne	nextStruct
		mov	si, ds:[bx].RTS_tableOD.handle
		tst	si			; a valid handle ??
		jz	nextStruct		; ...nope, so do nothing
	;
	; OK - we found the right year table. Now lock down the
	; RepeatStruct and call the correct low-level routine
	;
		push	di
		mov	ds:[tableHandle], si
		mov	si, ds:[bx].RTS_tableOD.chunk
		mov	ds:[tableChunk], si
		call	GP_DBLock
		call	GenerateAddEventFar
		call	DBUnlock
		pop	di
	;
	; Continue to loop through the remaining year tables, but
	; once we're done, restore the low-level generation routine
	;
nextStruct:
		add	bx, size RepeatTableStruct
		loop	tableLoop
		mov	ds:[repeatGenProc], offset AddNewEvent

		.leave
		ret
GenerateFixupException	endp
endif

RepeatCode	ends


CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateParse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine which generate routine should get called

CALLED BY:	GLOBAL

PASS:		DS	= DGroup
		ES	= A relocatable block, ES:0 must contain block handle
		AX	= Group # of RepeatStruct
		DX	= Item # of RepeatStruct
		BP	= Year to generate for

RETURN:		Nothing

DESTROYED:	SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatGenerateTable	nptr.near \
			GenerateWeekly, 	; RET_WEEKLY
			GenerateMonthlyDate, 	; RET_MONTHLY_DATE
			GenerateMonthlyDOW, 	; RET_MONTHLY_DOW
			GenerateYearlyDate, 	; RET_YEARLY_DATE
			GenerateYearlyDOW	; RET_YEARLY_DOW

GenerateParse	proc	far
	uses	bx, cx, dx, di
	.enter

	; Lock the item, roughly check the range
	;
	push	es:[LMBH_handle]		; save the handle
	mov	di, dx				; item # to DI
	call	GP_DBLockDerefSI		; lock the item
	cmp	es:[si].RES_startYear, bp	; check start year
	jg	done				; done if greater
	cmp	es:[si].RES_endYear, bp		; check the end year
	jl	done				; done if less

	; Determine the type of repeat event - call the proper routine
	; 
	mov	bl, es:[si].RES_type		; get the enumerated type
	clr	bh
EC <	cmp	bx, RepeatEventType		; bad enumerated type ??>
EC <	ERROR_GE	GENERATE_BAD_REPEAT_TYPE			> 
	sub	bx, RET_WEEKLY			; make type zero-based
EC <	ERROR_L		GENERATE_BAD_REPEAT_TYPE			> 
	shl	bx, 1				; double to word counter
	call	{word} cs:[RepeatGenerateTable][bx]

	; If we are supporting repeating date exceptions, then we
	; must see if there are any exception dates for this event
	;
RDE <	call	GenerateExceptionDates					>

	; We're done - clean up and exit
done:
	call	DBUnlock			; unlock the item
	pop	bx
	call	MemDerefES			; dereference the handle

	.leave
	ret
GenerateParse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateExceptionDates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the exception dates for a given event for the
		passed year, and update the year table

CALLED BY:	GenerateParse

PASS:		DS	= DGroup
		*ES:DI	= RepeatStruct
		BP	= Year to generate for

RETURN:		Nothing

DESTROYED:	BX, CX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 4/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_REPEAT_DATE_EXCEPTIONS
GenerateExceptionDates	proc	near
		uses	ax
		.enter
	;
	; If we are deleting the event, then we need not do anything.
	;
EC <		VerifyDGroupDS						>
		cmp	ds:[repeatGenProc], offset RemoveEvent
		je	exit
	;
	; If there aren't any date exception structures at the end of
	; this event, there is likewise no work to be done
	;
		mov	si, es:[di]
		ChunkSizePtr	es, si, cx
		mov	bx, es:[si].RES_dataLength
		add	bx, (size RepeatStruct)
		cmp	bx, cx
		je	exit
EC <		ERROR_A	REPEAT_EVENT_ILLEGAL_STRUCTURE			>
	;
	; See how many RepeatDateException structures exist
	;
		CheckHack <(size RepeatDateException) eq 4>
		sub	cx, bx
		shr	cx, 1
EC <		ERROR_C	REPEAT_EVENT_ILLEGAL_STRUCTURE			>
		shr	cx, 1			; # of structures => CX
EC <		ERROR_C	REPEAT_EVENT_ILLEGAL_STRUCTURE			>
	;
	; Loop through the exceptions and update the year table
	;
		add	si, bx		
		mov	ds:[repeatGenProc], offset RemoveEvent
exceptionLoop:
		cmp	es:[si].RDE_year, bp	; if different year,
		jne	next			; ...don't generate exception
		mov	dx, {word} es:[si].RDE_day
		call	GenerateAddEvent
next:
		add	si, (size RepeatDateException)
		loop	exceptionLoop				
		mov	ds:[repeatGenProc], offset AddNewEvent
exit:
		.leave
		ret
GenerateExceptionDates	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateWeekly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate all weekly repeat events

CALLED BY:	GenerateRepeat

PASS:		DS	= DGroup
		ES:*DI	= RepeatStruct
		BP	= Year
		AX	= Group # for Repeat
				
RETURN:		Nothing

DESTROYED:	BX, CX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenerateWeekly	proc	near
	uses	bp
	.enter
	;
	; get the first month & day
	;
		mov	si, es:[di]
		mov	dx, (1 shl 8) or 1	; January 1
		cmp	bp, es:[si].RES_startYear
		jl	done
		jg	setupLoop
		mov	dx, {word} es:[si].RES_startDay
setupLoop:
	;
	; initialize the week array, and find first Day of Week match
	;
		mov	ds:[weeklyYear], bp
		call	WeeklyInitArray
		call	CalcDayOfWeek		; cl = day of the week(0 - 6)
		clr	bh
		mov	bl, cl			; bx = day of the week(0 - 6)
		cmp	cl, 0
		jg	setupCont
		mov	cl, 7
setupCont:
		dec	cl
		mov	ch, 1
		sal	ch, cl
		test	es:[si].RES_DOWFlags, ch
		jne	weekLoopMid
		
weekLoop:
	;
	; loop until the end of the year
	;
	; es:*di = RepeatStruct
	;
	; bp	= year
	; dh	= month
	; dl	= day
	; bx	= current day of the week (0 - 6)
	;
		mov	cl, ds:[GenDayArray][bx]; get increment to
		clr	ch			; next day of week
		add	bl, ds:[GenDayArray][bx]
		cmp	bl, 7
		jl	next
		sub	bl, 7
next:
	;
	; go to next day of week
	;
		call	CalcDateAltered		; bp/dh/dl - new date
		cmp	bp, ds:[weeklyYear]	; to next year ??
		jne	done
weekLoopMid:
	;
	; are we within the boundary of the week
	;
		call	CompareStartEnd
		jc	done			; carry set if out of bound
	;
	; add event
	;
		call	GenerateAddEvent
		jmp	weekLoop
done:
	.leave
	ret
GenerateWeekly	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipOneWeek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip a week from a given day

CALLED BY:	GenerateWeekly
PASS:		ds	= dgroup
		bp	= year
		dh	= month
		dl	= day
		bx	= current day of the week (0 - 6)
RETURN:		bp	= year after skipping 1 week
		dh	= month after skipping 1 week
		dl	= day after skipping 1 week
		carry set if not the same year anymore
DESTROYED:	nothing

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	2/ 3/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckValidBiweeklyDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check whether current date is a valid biweekly date starting
		from the start date.

CALLED BY:	GenerateWeekly
PASS:		es:si	= RepeatStruct
		bp	= current year
		dh	= current month
		dl	= current day
RETURN:		carry set if not valid
		carry clear if valid
DESTROYED:	nothing

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	1/31/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WeeklyInitArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the DayArray

CALLED BY:	GenerateWeekly

PASS:		ES:*DI	= RepeatStruct

RETURN:		Nothing

DESTROYED:	BX, CX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WeeklyInitArray	proc	near
	uses	ax
	.enter

	; First generate the day array
	;
	mov	si, es:[di]			; dereference the handle
	mov	al, es:[si].RES_DOWFlags	; get the DOWFlags
EC <	tst	al						>
EC <	ERROR_Z	WEEKLY_REPEAT_EVENT_MUST_HAVE_DOW_SET		>
	mov	bx, offset GenDayArray		; go to start of array
	mov	ch, 1				; set a flag
	clr	cl				; start the day counter
	mov	ah, 1				; clear the counter

arrayLoop:
	inc	cl				; another day gone by
	sar	al				; shift right DOWFlags
	jc	firstCheck			; if carry, leave loop
	inc	ah				; increment the counter
	cmp	cl, 7
	jl	arrayLoop
	jmp	arrayLast

firstCheck:
	cmp	ch, 1				; is the flag set ??
	jne	secondLoop			; no - jump
	push	ax				; save 1st occurrence
	clr	ch				; clear the flag

secondLoop:
	cmp	bx, (offset GenDayArray) + 7	; compare with end of array
	je	done
	mov	ds:[bx], ah			; store the jump value
	inc	bx				; go to next entry
	dec	ah				; decrement the value
	jg	secondLoop
	mov	ah, 1				; reset jump value
	jmp	arrayLoop			; continue with the big loop

	; Fixup the final entries
	;
arrayLast:
	mov	cl, ah				; current count to CL
	pop	ax				; restore first count
	dec	ah				; offset to first DOW in AH
	add	ah, cl				; add together
	jmp	secondLoop
done:
	.leave
	ret
WeeklyInitArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateMonthlyDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate monthly repeat events by specific day

CALLED BY:	GenerateRepeat

PASS:		ES:*DI	= RepeatStruct
		BP	= Year
		AX	= Group # for Repeat

RETURN:		Nothing

DESTROYED:	CX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenerateMonthlyDate	proc	near

	; Some set-up work
	;
	mov	si, es:[di]			; dereference the handle
	mov	dh, 1				; the first month

	; Now loop
	;
genLoop:
	call	MonthDateGuts			; calc the day of month
	jc	next				; jump if invalid day
	call	CompareStartEnd
	jc	next				; go to the next event
	call	GenerateAddEvent
next:
	inc	dh				; go to the next month
	cmp	dh, 12				; are we done ??
	jle	genLoop				; loop again

	ret
GenerateMonthlyDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateMonthlyDOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate monthly repeat events by specific DOW & occurrence

CALLED BY:	GenerateRepeat

PASS:		ES:*DI	= RepeatStruct
		BP	= Year
		AX	= Group # for Repeat

RETURN:		Nothing

DESTROYED:	CX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenerateMonthlyDOW	proc	near

	; Some set up work
	;
	mov	si, es:[di]			; dereference the handle
	mov	dh, 1				; the first month

	; Now loop
	;
genLoop:
	call	MonthDOWGuts
	jc	next				; if carry set, bad occurrence
	call	CompareStartEnd
	jc	next				; if carry set, bad event
	call	GenerateAddEvent
next:
	inc	dh				; go to the next month
	cmp	dh, 12				; are we done ??
	jle	genLoop				; loop again

	ret
GenerateMonthlyDOW	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateYearlyDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate yearly repeat events by specific month & day

CALLED BY:	GenerateRepeat

PASS:		ES:*DI	= RepeatStruct
		BP	= Year
		AX	= Group # for Repeat

RETURN:		Nothing

DESTROYED:	CX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenerateYearlyDate	proc	near

	; Simple - get month & calc
	;
	mov	si, es:[di]			; dereference the handle
	mov	dh, es:[si].RES_month		; get the month
	call	MonthDateGuts			; calc the day => DL
	jc	done				; if carry set, bad occurrence
	call	CompareStartEnd
	jc	done				; if carry set, bad event
	call	GenerateAddEvent
done:	
	ret
GenerateYearlyDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateYearlyDOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate yearly repeat events using a month, DOW, & occurrence

CALLED BY:	GenerateRepeat

PASS:		ES:*DI	= RepeatStruct
		BP	= Year
		AX	= Group # for Repeat

RETURN:		Nothing

DESTROYED:	CX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenerateYearlyDOW	proc	near

	; Simple - get month & calc
	;
	mov	si, es:[di]			; dereference the handle
	mov	dh, es:[si].RES_month		; get the month
	call	MonthDOWGuts			; calc the day => DL
	jc	done				; if carry set, bad occurrence
	call	CompareStartEnd
	jc	done				; if carry set, bad event
	call	GenerateAddEvent
done:	
	ret
GenerateYearlyDOW	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareStartEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if given year/month/day falls in start-end period

CALLED BY:	Generate GLOBAL

PASS:		ES:*DI	= RepeatStruct
		BP	= Year
		DH	= Month
		DL	= Day

RETURN:		CarrySet if not in range

DESTROYED:	SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	Don	6/12/90		Optimized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CompareStartEnd	proc	near
	
	mov	si, es:[di]			; dereference the handle
	cmp	bp, es:[si].RES_startYear	; compare with start year
	jl	done				; if less, fail (carry set)
	jg	checkEnd			; if greater, check end
	cmp	dx, {word} es:[si].RES_startDay	; compare with start M/D
	jl	done				; if less, fail (carry set)
checkEnd:
	cmp	es:[si].RES_endYear, bp		; compare with end year
	jnz	done				; fail or OK (carry determines)
	cmp	{word} es:[si].RES_endDay, dx	; compare with end M/D
done:
	ret
CompareStartEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDateGuts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform true work for a specific day in a month

CALLED BY:	GenerateMonthlyDate, GenerateYearlyDate

PASS:		ES:*DI	= RepeatStruct
		BP	= Year
		DH	= Month

RETURN:		DL	= Day
		CarrySet if not a valid day for this month

DESTROYED:	CH, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	Don	6/12/90		Optimized
	sean	4/5/96		Responder change to make monthly
				repeat events after the 29th of month
				appear at the end of February

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthDateGuts	proc	near

	mov	si, es:[di]			; dereference the handle
	mov	dl, es:[si].RES_day		; get the day
	call	CalcDaysInMonth			; get days in this month
	xchg	dl, ch				; exchange day & requested
	cmp	ch, LAST_DAY_OF_MONTH		; is requested the last day ?
	je	done

	; If it's February & if the day we're repeating is after the
	; last day in February, then put this event at the end of
	; February.
	;

	cmp	dl, ch				; sets the carry flag...
	mov	dl, ch				; my day => DL
done:
	ret

MonthDateGuts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDOWGuts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform true work for specfic day of week in a month

CALLED BY:	GenertateMonthlyDOW, GenerateYearlyDOW

PASS:		ES:*DI	= RepeatStruct
		BP	= Year
		DH	= Month

RETURN:		DL	= Day
		Carry	= Set if not a valid occurrence

DESTROYED:	CX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	Don	6/12/90		Partially optimized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthDOWGuts	proc	near
	uses	bx
	.enter
	
	; Get the days in the month; determine type of occurrence
	;
	mov	si, es:[di]			; dereference the handle
	call	CalcDaysInMonth			; get the days in this month
	cmp	es:[si].RES_occur, LAST_DOW_OF_MONTH
	je	lastDOW				; if last DOW, jump!

	; Find the 1st Day of Week in this month
	;
	mov	dl, 1				; get DOW of 1st day
	mov	bh, ch				; days in the month to BH
	call	CalcDayOfWeek
	cmp	cl, es:[si].RES_DOW		; compare the DOW's
	je	loopSetUp			; jump to occurrence loop
	sub	cl, es:[si].RES_DOW
	neg	cl
	jg	adjust1
	add	cl, 7
adjust1:
	add	dl, cl				; go to 1st DOW

	; Now find the nth Day of Week in this month
	;
loopSetUp:
	mov	cl, es:[si].RES_occur		; get the occurrence
	tst	cl				; set the flags appropriately
	jmp	midLoop
dowLoop:
	add	dl, 7				; go to next week
	dec	cl				; decrement the occurrence
midLoop:
	jg	dowLoop				; loop until done
	cmp	bh, dl				; check last day & request
	jmp	done				; carry determines success

	; Handle the last DOW
	;
lastDOW:
	mov	dl, ch				; last day is day we want
	call	CalcDayOfWeek			; calculate the day of week
	cmp	cl, es:[si].RES_DOW		; compare the DOW's
	je	done				; we're done (carry clear)
	sub	cl, es:[si].RES_DOW
	jg	adjust2
	add	cl, 7
adjust2:
	sub	dl, cl				; correct DOW (carry clear)
done:
	.leave
	ret
MonthDOWGuts	endp

CommonCode	ends
