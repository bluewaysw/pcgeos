COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		intCommonDateAndTime.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.


	GetDateNumber
	DateNumberGetYear
	DateNumberGetMonthAndDay
	DateNumberWeekday
	GetTimeYear
	TimeNumberGetHour
	TimeNumberGetMinutes
	TimeNumberGetSeconds
	StringGetTimeNumber
	StringGetDateNumber
	GetDaysInMonth	
DESCRIPTION:
	date and time functions for intel coprocessor library

	$Id: intCommonDateAndTime.asm,v 1.1 97/04/04 17:48:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DateAndTimeCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87DateTimeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common co-routine to get date and time values.

CALLED BY:	(INTERNAL)
PASS:		various and sundry
RETURN:		carry set on error:
			al	= error code
		carry clear if ok:
			result left as top entry on FPU stack
			al	= destroyed
DESTROYED:	ah
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Intel80X87DateTimeCommon proc	near
myfloat	local	FloatNum
stackhan local	hptr
	uses	es, di, cx, bx, ds
	.enter
	;
	; Gain exclusive access to the FPU, declaring our intention to consume
	; one slot in the FPU stack.
	; 
	push	ax
	mov	ax, 1		; going to use one slot
	call	FloatHardwareEnter
	jc	fail
	;
	; Our caller will be using the emulation library's function to do
	; its thing, so lock down the software floating point stack for its use.
	; 
	push	bx
	call	FloatGetSoftwareStackHandle
	mov	ss:[stackhan], bx
	call	MemLock
	mov	ds, ax
	pop	bx
	pop	ax
	;
	; Call our caller back.
	; 
	push	cs
	call	{word}ss:[bp+2]
	jc	error			; => nothing to be popped
	;
	; Pop the result from the software stack into our local variable.
	; 
	segmov	es, ss, di
	lea	di, ss:[myfloat]
	call	FloatPopNumberInternal	; remove from software stack

	;
	; Unlock the software stack
	; 
	mov	bx, ss:[stackhan]
	call	MemUnlock
	;
	; Push the result onto the FPU stack
	; 
	fld	ss:[myfloat]
	fwait				; wait for it to be consumed before
					;  we destroy the frame...
	mov_tr	cx, ax			; save ax
	clr	ax			; indicate no change from what we
					;  declared on entry
	call	FloatHardwareLeave
	mov_tr	ax, cx			; restore ax, cx gets saved anyways
done:
	.leave
	inc	sp			; clear our own return address...
	inc	sp
	retf				; ...and return to our caller's caller

fail:
	inc	sp			; clear passed ax so error code is
	inc	sp			;  returned in ax
	jmp	done

error:
	push	ax
	mov	bx, ss:[stackhan]
	call	MemUnlock
	mov	ax, -1			; didn't use the slot we allocated
	call	FloatHardwareLeave
	pop	ax
	stc
	jmp	done
Intel80X87DateTimeCommon endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87GetDateNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the date number for the given date.
		A Date Number is the number of days from Jan 1, 1900 (date
		number 1) to through December 31, 2099 (date number 73050).

CALLED BY:	GLOBAL

PASS:		ax - year (1900 through 2099)
		bl - month (1 through 12)
		bh - day (1 through 31)

RETURN:		carry clear if successful
		    date number on the fp stack
		else carry set
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87GetDateNumber	proc	far
	call	Intel80X87DateTimeCommon
	call	GetDateNumber
	ret
Intel80X87GetDateNumber	endp
	public	Intel80X87GetDateNumber


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87DateNumberGetYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

DESCRIPTION:	Given a date number, extract the year.

CALLED BY:	GLOBAL

PASS:		date number on the fp stack

RETURN:		ax - year
		date number popped off the fp stack

DESTROYED:	carry set if error
		    al - error code (FLOAT_GEN_ERR)
		carry clear otherwise

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87DateNumberGetYear	proc	far
myfloat	local	FloatNum
	uses	es, ds, si, bx
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	fstp	myfloat
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	es, ax
	segmov	ds, ss, si
	lea	si, myfloat
	fwait
	call	FloatPushNumberInternal
	call	MemUnlock
	call	DateNumberGetYear
	pushf
	push	ax
	mov	ax, -1
	call	FloatHardwareLeave
	pop	ax
	popf
done:
	.leave
	ret
Intel80X87DateNumberGetYear	endp
	public	Intel80X87DateNumberGetYear


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87DateNumberGetMonthAndDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

DESCRIPTION:	Given a date number, extract the month.

CALLED BY:	GLOBAL

PASS:		date number on the fp stack

RETURN:		bl - month
		bh - day
		date number popped off the fp stack

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87DateNumberGetMonthAndDay	proc	far
myfloat	local	FloatNum
	uses	ds, es, si, ax
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	fstp	myfloat
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	es, ax
	segmov	ds, ss, si
	lea	si, myfloat
	fwait
	call	FloatPushNumberInternal
	call	MemUnlock
	call	DateNumberGetMonthAndDay
	pushf
	push	ax
	mov	ax, -1
	call	FloatHardwareLeave
	pop	ax
	popf
done:		
	.leave
	ret
Intel80X87DateNumberGetMonthAndDay	endp
	public	Intel80X87DateNumberGetMonthAndDay


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87DateNumberGetWeekday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Given a date number, return the day of the week.  The day
		ranges from 1 (Sunday) to 7 (Saturday).

CALLED BY:	GLOBAL

PASS:		date number on the fp stack

RETURN:		weekday number on the fp stack

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87DateNumberGetWeekday	proc	far
myfloat	local	FloatNum
	uses	ds, es, si, ax, di, bx
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	fstp	myfloat
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	es, ax
	segmov	ds, ss, si
	lea	si, myfloat
	fwait
	call	FloatPushNumberInternal
	call	DateNumberGetWeekday
	segmov	ds, es, di
	segmov	es, ss, di
	lea	di, myfloat
	call	FloatPopNumberInternal
	call	MemUnlock
	fld	myfloat	
	fwait
	clr	ax
	call	FloatHardwareLeave
done:		
	.leave
	ret
Intel80X87DateNumberGetWeekday	endp
	public	Intel80X87DateNumberGetWeekday


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87GetTimeNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Calculate a time number given the time.

		Time Numbers are consecutive decimal values that correspond
		to times from midnight (time number 0.000000) through
		11:59:59 PM (time number 0.999988)

CALLED BY:	GLOBAL

PASS:		ch - hours (0 through 23)
		dl - minutes (0 through 59)
		dh - seconds (0 through 59)

RETURN:		carry clear if successful
		    time number on the fp stack
		else carry set
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87GetTimeNumber	proc	far
	call	Intel80X87DateTimeCommon
	call	GetTimeNumber
	ret
Intel80X87GetTimeNumber	endp
	public	Intel80X87GetTimeNumber


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87StringGetTimeNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	parse the string containing a time and return its time number.

CALLED BY:	GLOBAL

PASS:		es:di - string to parse

RETURN:		carry clear if successful
		    date number on the fp stack
		carry set otherwise
		    al - error code (FLOAT_GEN_ERR)

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87StringGetTimeNumber	proc	far
	call	Intel80X87DateTimeCommon
	call	StringGetTimeNumber
	ret
Intel80X87StringGetTimeNumber	endp
	public	Intel80X87StringGetTimeNumber


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87StringGetDateNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

DESCRIPTION:	Parse the sting containing a date and return its date number.

CALLED BY:	GLOBAL

PASS:		es:di - string to parse

RETURN:		carry clear if successful
		    date number on the fp stack
		carry set otherwise
		    al - error code (FLOAT_GEN_ERR)


DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87StringGetDateNumber	proc	far
	call	Intel80X87DateTimeCommon
	call	StringGetDateNumber
	ret
Intel80X87StringGetDateNumber	endp
	public	Intel80X87StringGetDateNumber


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87TimeNumberGetHour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the hour given the time number.

CALLED BY:	GLOBAL

PASS:		time number on the fp stack

RETURN:		hour on the fp stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87TimeNumberGetHour	proc	far
myfloat	local	FloatNum
	uses	ds, es, si, ax, di, bx
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	fstp	myfloat
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	es, ax
	segmov	ds, ss, si
	lea	si, myfloat
	fwait
	call	FloatPushNumberInternal
	call	TimeNumberGetHour
	segmov	ds, es, di
	segmov	es, ss, di
	lea	di, myfloat
	call	FloatPopNumberInternal
	call	MemUnlock
	fld	myfloat	
	fwait
	clr	ax
	call	FloatHardwareLeave
done:		
	.leave
	ret
Intel80X87TimeNumberGetHour	endp
	public	Intel80X87TimeNumberGetHour


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87TimeNumberGetMinutes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the minutes given the time number.

CALLED BY:	GLOBAL

PASS:		time number on the fp stack

RETURN:		minutes on the fp stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87TimeNumberGetMinutes	proc	far
myfloat	local	FloatNum
	uses	ds, es, si, ax, di, bx
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	fstp	myfloat
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	es, ax
	segmov	ds, ss, si
	lea	si, myfloat
	fwait
	call	FloatPushNumberInternal
	call	TimeNumberGetMinutes
	segmov	ds, es, di
	segmov	es, ss, di
	lea	di, myfloat
	call	FloatPopNumberInternal
	call	MemUnlock
	fld	myfloat	
	fwait
	clr	ax
	call	FloatHardwareLeave
done:		
	.leave
	ret
Intel80X87TimeNumberGetMinutes	endp
	public	Intel80X87TimeNumberGetMinutes

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87TimeNumberGetSeconds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the minutes given the time number.

CALLED BY:	GLOBAL

PASS:		time number on the fp stack

RETURN:		seconds on the fp stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87TimeNumberGetSeconds	proc	far
myfloat	local	FloatNum
	uses	ds, es, si, ax, di, bx
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	fstp	myfloat
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	es, ax
	segmov	ds, ss, si
	lea	si, myfloat
	fwait
	call	FloatPushNumberInternal
	call	TimeNumberGetSeconds
	segmov	ds, es, di
	segmov	es, ss, di
	lea	di, myfloat
	call	FloatPopNumberInternal
	call	MemUnlock
	fld	myfloat	
	fwait
	clr	ax
	call	FloatHardwareLeave
done:		
	.leave
	ret
Intel80X87TimeNumberGetSeconds	endp
	public	Intel80X87TimeNumberGetSeconds


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87GetDaysInMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Given a year and a month, calculate the number of days
		in that month.

CALLED BY:	INTERNAL (CheckDateValid)

PASS:		ax - year (YEAR_MIN <= ax <= YEAR_MAX)
		bl - month (MONTH_MIN <= bl <= MONTH_MAX)

RETURN:		bh - number of days in the month

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87GetDaysInMonth	proc	far
	call	GetDaysInMonth
	ret
Intel80X87GetDaysInMonth	endp
	public	Intel80X87GetDaysInMonth


DateAndTimeCode	ends
