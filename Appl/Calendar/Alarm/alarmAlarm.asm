COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Alarm
FILE:		alarmAlarm.asm

AUTHOR:		Don Reeves, September 1, 1989

ROUTINES:
	Name			Description
	----			-----------
	AlarmClockStart		Starts the alarm clock ticking
	AlarmClockStop		Kills clock prior to detach
	AlarmClockReset		Reset clock for new file
	GetNextAlarm		Returns the next alarm group & item numbers
	SetNextAlarm		Sets the next alarm group & item numbers
	SearchNextAlarm		Reset the next alarm info after adding an event
	CompareAlarmTime	Compares event alarm time w/ passed time/date
	AlarmTimeChange		Deal with alarms when user resets clock
	AlarmClockTick		Called every minute to deal with alarms

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/1/89		Initial revision
	Don	2/26/91		Moved to different file/module

DESCRIPTION:
	Implements the alarm object, which keeps track of the
	next event's alarm to go off.
		
	$Id: alarmAlarm.asm,v 1.1 97/04/04 14:47:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata		segment
	timerHandle	word	(?)		; handle to timer
	nextAlarmGroup	word	(?)		; group # of next event
	nextAlarmItem	word	(?)		; item # of next event
udata		ends


InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmClockStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the alarm clock

CALLED BY:	CalendarAttach

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmClockStart	proc	near

	; Simply set up the timer structure
	;
	call	TimerGetDateAndTime		; get the time
	mov	ax, 60
	mov	cl, 60
	sub	cl, dh				; seconds until next minute
	mul	cl				; change to ticks
	mov	cx, ax				; time until first event
	mov	di, 3600			; go off once a minute
	mov	ax, TIMER_EVENT_CONTINUAL	; a continual timer
	call	GeodeGetProcessHandle		; process handle to BX
	push	bx
	mov	dx, MSG_CALENDAR_CLOCK_TICK	; method to send
	call	TimerStart
	
	; Now save the timer handle and call for immediate update
	;
	mov	ds:[timerHandle], bx		; save the handle
	pop	bx				; restore the process handle
	mov	ax, MSG_CALENDAR_CLOCK_TICK
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; start the clock
	ret
AlarmClockStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmClockStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kill the alarm clock

CALLED BY:	GLOBAL

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, DI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/6/89		Initial version
	Don	3/18/90		Fixed bug, added check for application mode

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmClockStop	proc	near
	mov	bx, ds:[timerHandle]		; timer handle => BX
	clr	ax				; 0 => continual
	call	TimerStop			; stop the timer
	ret					; end the alarm clock
AlarmClockStop	endp

InitCode	ends



FileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmClockReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in any cached alarm data

CALLED BY:	GLOBAL
	
PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, DI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmClockReset	proc	near
	.enter

	; Set up the alarm stuff
	;
EC <	call	GP_DBVerify			; verify it		>
	call	GP_DBLockMap			; lock the true map block
	mov	di, es:[di]			; dereference the handle
	mov	ax, es:[di].YMH_nextAlarmGr
	mov	ds:[nextAlarmGroup], ax		; the next alarm group
	mov	ax, es:[di].YMH_nextAlarmIt
	mov	ds:[nextAlarmItem], ax		; the next alarm item
	call	DBUnlock			; unlock the map block
	call	SearchNextAlarm			; initialize the next pointer

	.leave
	ret
AlarmClockReset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmClockWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out any cached alarm data

CALLED BY:	GLOBAL
	
PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, DI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/17/90		Initial version
	kho	5/02/96		Call GP_DBDirtyUnlock

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmClockWrite	proc	near
	.enter

	; Set up the alarm stuff
	;
EC <	call	GP_DBVerify			; verify it		>
	call	GP_DBLockMap			; lock the true map block
	mov	di, es:[di]			; dereference the handle
	mov	ax, ds:[nextAlarmGroup]		
	mov	es:[di].YMH_nextAlarmGr, ax	; the next alarm group
	mov	ax, ds:[nextAlarmItem]		
	mov	es:[di].YMH_nextAlarmIt, ax	; the next alarm item
	call	GP_DBDirtyUnlock		; unlock the map block

	.leave
	ret
AlarmClockWrite	endp

FileCode	ends



ResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the group and item numbers for the next alarm to go off

CALLED BY:	INTERNAL to DataBase

PASS:		Nothing

RETURN:		AX	= Group # for the event
		DI	= Item # for the event

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/1/89		Initial version
	Don	4/7/90		Moved out of DB stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetNextAlarm	proc	far
	.enter
	
	; Get the dgroup segment, verify it, and return values
	;
	GetResourceSegmentNS	dgroup, es	; DGroup segment => ES
EC <	VerifyDGroupES				; verify it		>
	mov	ax, es:[nextAlarmGroup]		; the next alarm group
	mov	di, es:[nextAlarmItem]		; the next alarm item

	.leave
	ret
GetNextAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNextAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the next alarm event (absolutely)

CALLED BY:	INTERNAL to DataBase

PASS:		BP	= Group # of event
		DX	= Item # of event

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		No check is made to verify that the given event
		is the next alarm event.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/1/89		Initial version
	Don	4/7/90		Moved out of DB stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetNextAlarm	proc	far
	.enter

	; Simply store the stuff away
	;
	GetResourceSegmentNS	dgroup, es	; DGroup segment => ES
EC <	VerifyDGroupES				; verify it		>
	mov	es:[nextAlarmGroup], bp		; save the group #
	mov	es:[nextAlarmItem], dx		; save the item #

	.leave
	ret
SetNextAlarm	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchNextAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search database to find correct next alarm to go off.
		To be used after any alarm addition or time change.

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	ES

PSEUDO CODE/STRATEGY:
		Lock the map block
		Get the current alarm
		If none, done
		Else 
			Get current time
			Search 1st event's alarm time after current time
		Reset the alarm

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SearchNextAlarm	proc	far
	uses	ax, bx, cx, dx, si, di, bp, ds
	.enter

	GetResourceSegmentNS	dgroup, ds
	test	ds:[systemStatus], SF_VALID_FILE
LONG	jz	reallyQuit

	; Get the map block, and verify it
	;
	call	TimerGetDateAndTime		; get the current time
	mov	dh, ch				; Hour/Min => DX
	mov	ch, bl				; month => CH
	mov	cl, bh				; day => CL
	mov	bx, ax				; Year => BX
	
	; Get the data, and start the search loop
	;
	call	GetNextAlarm			; get the next alarm
	mov	bp, di				; item # also to BP
	tst	di				; no event ?
	je	quit				; then we're done
	call	GP_DBLockDerefSI
NRSP <	call	CompareAlarmTime					>
RSP <	call	CompareAlarmTimeOld					>
	jg	backward			; jump backward

	; Search forward
forward:
	cmp	es:[si].ES_alarmNextGr, nil	; check for next nil
	je	done				; we're done
	mov	ax, es:[si].ES_alarmNextGr	; get the next group
	mov	bp, es:[si].ES_alarmNextIt	; get the next item
	call	DBUnlock
	mov	di, bp
	call	GP_DBLockDerefSI
NRSP <	call	CompareAlarmTime					>
RSP <	call	CompareAlarmTimeOld					>
	jl	forward				; jump if less
	jmp	done				; we're done

	; Search backward
backward:
	cmp	es:[si].ES_alarmPrevGr, nil	; check for next nil
	je	done				; we're done
	mov	ax, es:[si].ES_alarmPrevGr	; get the next group
	mov	bp, es:[si].ES_alarmPrevIt	; get the next item
	call	DBUnlock
	mov	di, bp
	call	GP_DBLockDerefSI
NRSP <	call	CompareAlarmTime					>
RSP <	call	CompareAlarmTimeOld					>
	jge	backward			; jump if less
	
	; Went too far - get next item
	;
	mov	ax, es:[si].ES_alarmNextGr	; go to next group
	mov	bp, es:[si].ES_alarmNextIt	; go to next item

	; We're done
done:
	call	DBUnlock			; unlock any locked segment
quit:
	mov	dx, bp				; item # => DX
	mov	bp, ax				; group # => BP
	call	SetNextAlarm			; set the next alarm

reallyQuit:
	.leave
	ret
SearchNextAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareAlarmTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare an event's alarm time with the current time

CALLED BY:	SearchNextAlarm

PASS:		ES:SI	= Current event
		BX	= Year
		CX	= Month/Day
		DX	= Hour/Minute

RETURN:		Nothing

DESTROYED:	Nothing (but sets appropriate flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/1/89		Initial version
	Don	4/7/90		Cleaned up a bit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CompareAlarmTime	proc	near
	uses	ax
	.enter

	; First comapre the years
	;
	mov	ax, es:[si].ES_alarmYear	; get the year
	sub	ax, bx				; subtract current year
	jne	done

	; Now compare the month & day
	;
	mov	ax, {word} es:[si].ES_alarmDay	; get the day & month
	sub	ax, cx				; subtract current D/M
	jne	done
	
	; Finally copmare the hour and minute
	;
	mov	ax, {word} es:[si].ES_alarmMinute	; get the hour & min
	sub	ax, dx					; subtract current H/M
done:
	.leave
	ret
CompareAlarmTime	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmTimeChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The time has been changed by the user. Search for the
		next alarm to go off, and then proceed normally with the
		timer handler.

CALLED BY:	CalendarGeneralChangeNotification (MSG_CALENDAR_TIME_CHANGE)
	
PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/8/90		Initial version
	kho	11/25/95	Make some changes in responder version
				(or rather, RTCM version)
	sean	11/30/95	Responder changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmTimeChange	proc	far
if USE_RTCM

EC <	Assert	dgroup, ds						>
	;
	; Check if the vm file is opened yet.  If not, resend message
	; on the queue. If RTCM launches the app, the file will not be open
	; the first time we receive the message. (If the app is running when
	; user changes date/time, and RTCM calls us, then the file would be
	; open.)
	;
	test	ds:[systemStatus], SF_VALID_FILE
	jz	sendMessageAgain
	;
	; mark any alarm event to be NOT(alarm) type, if the event is before
	; current time
	;
	call	TurnOffOldAlarms		; turn off alarms past
	;
	; we want to be notified by RTCM next time the date/time is changed..
	;
	call	SetTimeChangeAlarm	
	call	SearchNextAlarm			; set the next alarm correctly
	call	FindNextRTCMAlarm		; set next RTCM alarm
	call	AlarmClockTick			; and do normal timer work
done:
	ret

sendMessageAgain:
	;
	; VMFile is not valid yet, so send message again on the
	; queue.
	;
	mov	ax, MSG_CALENDAR_TIME_CHANGE
	call	GeodeGetProcessHandle		; bx = process handle
	mov	di, mask MF_FORCE_QUEUE or\
		    mask MF_FIXUP_DS
	call	ObjMessage
	jmp	done

else	; NON-RTCM		; -------------------------------------------

	call	SearchNextAlarm			; set the next alarm correctly
	FALL_THRU	AlarmClockTick		; and do normal timer work
	
endif				; -------------------------------------------
	
AlarmTimeChange	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmClockTick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep track of time (called once a minute)

CALLED BY:	Time (MSG_CALENDAR_CLOCK_TICK)

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:
		Notify the Year object of the new time
		Look for alarms to go off

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmClockTick	proc	far

	; Get the true time, notify the year object
start:
	call	TimerGetDateAndTime		; get the true time
	mov	bp, ax				; year to BP
	mov	cl, dl				; hour/minute => CX
	mov	dx, bx				; month and day into DX
	xchg	dl, dh				; month/day => DX
	call	GeodeGetProcessHandle		; process handle => BX
	mov	ax, MSG_CALENDAR_SET_DATE	; method to send
	clr	di				; not a call!
	call	ObjMessage			; update the screen display

	;
	; See if the data file is open yet. If not, we quit. (And the
	; message will come back after the file is opened.)
	;
	test	ds:[systemStatus], SF_VALID_FILE
	jz	quit				; quit if no valid file


	; Look for events whose alarm should go off
	;
	call	GetNextAlarm			; get the next alarm
	mov	bx, bp				; year => BP
	xchg	cx, dx				; M/D => CX, H/M => DX
	mov	bp, di				; put handle to BP

	; Lock the block, and compare real times
checkLoop:
	cmp	bp, nil				; is there an event ??
	je	exit				; nothing to do - no event
	mov	di, bp				; item to DI
	call	GP_DBLock			; lock the item
	mov	si, es:[di]			; dereference the chunk
	call	CompareAlarmTime
	jg	done
	je	found
	call	DBUnlock			; unlock the chunk
	call	SearchNextAlarm			; reset the alarm pointer
	jmp	start				; start over!

	; Put this event up in an alarm
found:
	test	es:[si].ES_flags, mask EIF_ALARM_ON
	jz	skip				; if alarm off, skip it

	; Turn off alarm since we're putting this alarm on the 
	; screen.
	;
	call	DBUnlock			; unlock the EventStruct
	call	AlarmToScreen			; put up an alarm box
	mov	si, es:[di]			; locked EventStruct => ES:*DI
skip:
	mov	ax, es:[si].ES_alarmNextGr	; get the next group
	mov	bp, es:[si].ES_alarmNextIt	; get the next item
	call	DBUnlock
	jmp	checkLoop			; continue the loop
done:

	call	DBUnlock			; unlock the item
exit:

	; Now check for any repeat event alarms due at this
	; time.
	;
	mov	dx, bp				; item to DX
	mov	bp, ax				; group to BP
	call	SetNextAlarm			; set the next alarm

	; If an alarm went off, we need to find the next one
	; to register with the RTCM library.  Also, reset 
	; alarms & correct alarm linkage.
	;
quit:
	ret
AlarmClockTick	endp


ResidentCode ends

