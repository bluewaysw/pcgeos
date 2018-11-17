COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Lizzy
MODULE:		Calendar
FILE:		dayplanUtils.asm

AUTHOR:		Simon Auyeung, Feb  2, 1997

ROUTINES:
	Name			Description
	----			-----------
    INT BufferDestroy		Destroy the DayEvent (DayEvent, TimeText,
				EventText) that BufferCreate creates.

    INT SetEventStartDateTime	Set the starting time/date in the DayEvent
				object. In case of to-do item, set the
				priority (in the time field).

    INT SetEventEndDateTime	Set the ending time/date in the DayEvent
				object.

    INT SetEventGetDateTime	Extract date and time

    INT SetEventText		Set the event text

    INT SetEventReserveWholeDay	Set event's reserve whole day

    INT SetEventUpdateNewEvent	Set up a new event via update

    INT SetEventAlarm		Set the event alarm

    INT SetEventRepeatInfo	Set the repeat info of the DayEvent object,
				if any.

    INT SetEventInternalInfo	Set the internal data of the DayEvent
				object and reset DB item for deletion

    INT SetEventInternalInfoCommon
				Set the internal data of the DayEvent
				object regardless of normal event or repeat
				event

    INT ClearEventInternalInfo	Clear the info in EventStruct or
				RepeatStruct, similar to
				SetEventInternalInfo, so that when the
				struct is deleted, the associating data
				would not be deleted.

    INT SetEventGetUniqueID	Get unique ID of the day event

    INT DayPlanIsEventByIDSelected
				Check if an event is currently selected by
				comparing event ID

    INT DateTimeToFileDateAndTime
				Convert date and time into FileDate and
				FileTime format

    INT DayPlanCopyEventString	Copy event data string from a source to
				destination

    INT AlarmToCalendarAlarmStruct
				Convert an alarm to CalendarAlarmStruct

    INT CalendarDoesReserveDayEventExist
				Find out if a reserve whole day event
				exists within a given time period

    INT CalendarFindReserveDayEvent
				Find the first reserve day event at or
				after a time

    INT CalendarCompareRange	Compare two time range and determine if
				they overlap

    INT CalendarCompareDateTime	Compare date and time of two events to see
				which one is earlier

    INT CalendarVerifyEndDateTimeNotEarlier
				Verify that the end date and end time of
				DateTimeRangeStruct is not earlier than its
				start date and start time.

    EXT CalculateAlarmPrecedeMins
				Convert the alarm to preceding minutes of
				the start time.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/ 2/97   	Initial revision


DESCRIPTION:
	This file contains shared utility codes of DayPlan object 
	

	$Id: dayplanUtils.asm,v 1.1 97/04/04 14:47:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HANDLE_MAILBOX_MSG or CALAPI

ApiCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the DayEvent (DayEvent, TimeText, EventText) that
		BufferCreate creates.

CALLED BY:	(INTERNAL) DayPlanCreateEventFromApi,
		DayPlanCreateEventFromMBAppoint,
		DayPlanModifyEventByIDFromApi
PASS:		^lbx:si	= DayEvent object to be destroyed
		ds	= segment for FIXUP_DS
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		BufferDestroy was never needed because when calendar shuts
		down, all events will be freed. And "BufferCreate" is only
		called a few times to fill the whole screen.

		But now, we are calling BufferCreate more often over the life
		of the calendar application, so we don't want buffers to hang
		around forever.

		Must do MF_FORCE_QUEUE, otherwise queued message could be
		sent to a destroyed obj.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BufferDestroy	proc	near
		pushf
		uses	ax, dx, di
		.enter
		Assert	optr, bxsi
	;
	; Destroy the DayEvent object.
	;
		mov	ax, MSG_VIS_DESTROY
		mov	dl, VUM_NOW
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		popf
		ret
BufferDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventStartDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the starting time/date in the DayEvent object. In
		case of to-do item, set the priority (in the time field).

CALLED BY:	(INTERNAL) SetApiEventStartDateTime,
		SetClavinEventStartDateTime 
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		cx	= FileTime or TRUE to create same to-do list item
		dx	= FileDate or TRUE to create to do list item
RETURN:		if this is not a to-do item:
			bp	= year
			dx	= month/day
			cx	= hour/minute
			ax	= CEE_NORMAL
		carry set if error occurs (e.g. illegal date/time)
			ax	= CalendarEventError
				CEE_INVALID_DATE
				CEE_INVALID_TIME
				CEE_INVALID_TODO_ITEM_STATUS
DESTROYED:	if this is a to-do item,
		cx, dx, bp destroyed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if (start time = TRUE) {
			create to-do list item
		} else {
			create day event
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 2/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventStartDateTime	proc	near
		uses	di
		.enter
		Assert	optr, bxsi
		Assert	segment, ds

if      _TODO
		cmp	dx, TRUE
		je	createTodo
endif
	;
	; Extract date and time in the right registers
	;
		call	SetEventGetDateTime
	;
	; carry set if error, ax = CalendarEventError
	; bp = year, dx = month/day, cx = hour/min
	;
	; If this is a same day to-do event, CX = CAL_NO_TIME
	;
		jc	quit
		mov     ax, MSG_DE_INIT_VIRGIN_PRESERVE_UNIQUE_ID
goInit::
		push	cx, dx, bp
                mov     di, mask MF_CALL or mask MF_FIXUP_DS
                call    ObjMessage		; ax, cx, dx, bp gone
		pop	cx, dx, bp

		mov	ax, CEE_NORMAL
                clc				; no error
quit:
		Assert	CalendarEventErrorAndFlags	ax
                .leave
                ret

if      _TODO
        ;
        ; Two check hacks to see that the MB_TODO_NORMAL_PRIORITY and
        ; MB_TODO_HIGH_PRIORITY match our constants.
        ;
                CheckHack<MB_TODO_NORMAL_PRIORITY eq \
                        (TODO_DUMMY_HOUR * 256 + TODO_NORMAL_PRIORITY)>
                CheckHack<MB_TODO_HIGH_PRIORITY eq \
                        (TODO_DUMMY_HOUR * 256 + TODO_HIGH_PRIORITY)>
createTodo:
        ;
        ; Set up the dummy time and call MSG_DE_INIT_TODO.
        ; In To-do list, the "minute" field is priority, and
        ; year/month/day/hour all have dummy values.
	;
	; Verify the to-do item status
	;
		CheckHack <(TODO_HIGH_PRIORITY+1) eq TODO_NORMAL_PRIORITY>
		CheckHack <(TODO_NORMAL_PRIORITY+1) eq TODO_COMPLETED>
		cmp	cl, TODO_HIGH_PRIORITY
		jb	invalidToDoStatus
		cmp	cl, TODO_COMPLETED
		ja	invalidToDoStatus

		Assert	etype	cx, CalendarToDoItemStatus
                mov     ax, MSG_DE_INIT_TODO
                jmp     goInit

invalidToDoStatus:
		mov	ax, CEE_INVALID_TODO_ITEM_STATUS
		stc
		jmp	quit
endif	; _TODO
SetEventStartDateTime	endp

if	END_TIMES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventEndDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the ending time/date in the DayEvent object.

CALLED BY:	(INTERNAL) SetApiEventEndDateTime, SetClavinEventEndTime
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		al	= TRUE if always set end time even if end
			time is earlier than start time

			  FALSE otherwise: set end time if end date/time is
			later than or equal to start date/time.

		cx	= FileTime or TRUE if no end time
		dx	= FileDate or TRUE if no end date
RETURN:		carry set if error occurs (e.g. illegal date/time)
			ax	= CalendarEventError
				CEE_INVALID_DATE
				CEE_INVALID_TIME
				CEE_START_TIME_LATER_THAN_END_TIME
				CEE_START_DATE_LATER_THAN_END_DATE
				CEE_MISSING_END_TIME_WHEN_START_TIME_AND_END_DATE_ARE_SET
		carry clear, otherwise
			ax	= CEE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get date and time from flags;
	if (event has end date) {
		Check if event has start time;
		if (event has start time and finish date and no finish time) {
			return error;
		}
		call MSG_DE_SET_END_DATE;
		return error if any;
	}
	if (event has end time) {

	} else {
		call MSG_DE_SET_END_TIME;
		return error if any;
	}

	*WARNING*

	It checks end date and time against the start date/time. So, if you
	want to set both start and end date/time info, you should have set
	start date and time first.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 2/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventEndDateTime	proc	near
		uses	cx, dx, di, bp
		.enter
		Assert	optr	bxsi
		Assert	segment	ds
	;
	; Get date and time into right registers
	;
		call	SetEventGetDateTime	; carry set if err
						; bp =year, dx=month/day,
						; cx=hour/min
		jc	quit
	;
	; If there is no end date, only set end time
	;
		cmp	dx, TRUE
		je	checkEndTime
	;
	; If end date is given and there is no start time, do nothing.
	;
		push	cx, dx, bp
		mov	ax, MSG_DE_GET_TIME
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; bp=yr, dx=month/day, 
						; cx=hour/min
		pop	cx, dx, bp		; carry set if no start time
EC <		ERROR_C CALENDAR_SHOULD_NOT_SET_END_DATE_IF_NO_START_TIME>
NEC <		jc	okay						>
	;
 	; If start time is set and end date is set, end time must be given.
	;
		cmp	cx, TRUE
		jne	setEndDate
		mov	ax, CEE_MISSING_END_TIME_WHEN_START_TIME_AND_END_DATE_ARE_SET
		stc
		jmp	quit
	;
	; Set the end date
	;
setEndDate:
		push	cx
		mov_tr	cx, bp			; cx = year
		mov	ax, MSG_DE_SET_END_DATE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; carry set if invalid date
						; ax = FALSE if equ start date
		pop	cx
		mov	ax, CEE_START_DATE_LATER_THAN_END_DATE
		jc	quit
	;
	; Check end time. If there no end time, do nothing
	;
checkEndTime:
		cmp	cx, TRUE
		je	okay
	;
	; Set end time
	;
		mov	ax, MSG_DE_SET_END_TIME
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ax,cx,dx,bp gone
						; carry set if error
		mov	ax, CEE_START_TIME_LATER_THAN_END_TIME
		jc	quit

okay:
		mov	ax, CEE_NORMAL
		clc
quit:
		Assert	CalendarEventErrorAndFlags	ax
		.leave
		ret
SetEventEndDateTime	endp
endif	; END_TIMES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventGetDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract date and time 

CALLED BY:	(INTERNAL) DayPlanCheckIfEventExists, SetEventEndDateTime,
		SetEventStartDateTime
PASS:		cx	= FileTime or TRUE if this is a same day to-do item
		dx	= FileDate or TRUE if this is a to-do item
RETURN:		bp	= year if FileDate passed is not TRUE
		dx	= month/day or unchanged if FileDate passed is TRUE
		cx	= hour/minute or unchanged if FileTime passed is TRUE
		carry set if error occurs (e.g. illegal date/time)
			ax	= CalendarEventError
				CEE_INVALID_DATE
				CEE_INVALID_TIME
		carry clear, otherwise
			ax	= CEE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		FileDate:	yyyyyyyM:MMMddddd
			FD_YEAR:7
			FD_MONTH:4
			FD_DAY:5		
		FileTime:	hhhhhMMM:MMMsssss
			FT_HOUR:5
			FT_MIN:6
			FT_2SEC:5		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 2/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventGetDateTime	proc	near
		.enter
        ;
	; DX = FileDate
        ; We need:      dx = month/day. bp = year
	;
	; If FileDate = TRUE, don't do anything
        ;
		cmp	dx, TRUE
		je	checkTime

		push	cx				; save FileTime
		Assert	record	dx, FileDate
		mov	bp, dx				; bp = FileDate
                andnf   dx, mask FD_MONTH
                shl     dx
                shl     dx
                shl     dx                              ; dh <- month (*)

                mov_tr  cx, bp                          ; cx <- FileDate
                andnf   cx, mask FD_DAY
                mov     dl, cl                          ; dl <- day (*)

                mov     cl, offset FD_YEAR
                shr     bp, cl
                add     bp, FILE_BASE_YEAR              ; bp <- year (*)
		pop	cx				; restore FileTime

		call    CheckValidDate                  ; carry set if error
		mov	ax, CEE_INVALID_DATE
                jc      quit
        ;
	; CX = FileTime
        ; Get time from struct. Need: cx = hour/min
	;
	; If this is CAL_NO_TIME, don't do anything
	;
checkTime:
		cmp	cx, CAL_NO_TIME
		je	ok

		Assert	record	cx, FileTime
                shr     cx
                shr     cx
                shr     cx                              ; ch <- hour (*)
                shr     cl
                shr     cl                              ; cl <- min (*)

                call    CheckValidTime                  ; ditto
		mov	ax, CEE_INVALID_TIME
		jc	quit

ok:
		mov	ax, CEE_NORMAL
		clc
quit:
		Assert	CalendarEventErrorAndFlags	ax
		.leave
		ret
SetEventGetDateTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the event text

CALLED BY:	(INTERNAL) SetApiEventText, SetClavinEventText
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		dx:bp	= fptr to null-terminated text
RETURN:		carry set if text too long
			ax	= CEE_EVENT_TEXT_TOO_LONG
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 2/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventText	proc	near
		uses	cx, es, di
		.enter
		Assert	optr, bxsi
		Assert	segment, ds
		Assert	nullTerminatedAscii,	dxbp
	;
	; If the text is too long, return error
	;
		movdw	esdi, dxbp		; es:di = text
		LocalStrLength			; cx = #chars
		mov	ax, CEE_EVENT_TEXT_TOO_LONG
		cmp	cx, CALENDAR_MAX_EVENT_TEXT_LENGTH
		ja	done			; carry clear if > max length
	;
	; Set the text in event obj to the passed string.
	;
		mov	ax, MSG_DE_REPLACE_TEXT
		clr	cx			; null-terminated
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; nothing destroyed

		stc				; no error
done:
		cmc				; invert result
		.leave				
		ret
SetEventText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventReserveWholeDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set event's reserve whole day

CALLED BY:	(INTERNAL) SetApiEventReserveWholeDay
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		cx	= number of reserve whole day
RETURN:		carry set if invalid reserve whole day
			ax	= CEE_INVALID_RESERVE_WHOLE_DAY
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/ 8/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventReserveWholeDay	proc	near
		uses	di
		.enter
		Assert	optr	bxsi

		mov	ax, MSG_DE_SET_RESERVED_DAYS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; carry set if invalid days
		jnc	done

		mov	ax, CEE_INVALID_RESERVE_WHOLE_DAY
done:
		.leave
		ret
SetEventReserveWholeDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventUpdateNewEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a new event via update

CALLED BY:	(INTERNAL) DayPlanCreateEventFromApi,
		DayPlanModifyEventByIDFromApi, StuffClavinInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlanObject
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Also reset UI.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/ 5/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventUpdateNewEvent	proc	near
		uses	ax, bx, cx, dx, bp, di, si
		.enter
		Assert	segment	ds
		Assert	optr	bxsi
	;
	; Call MSG_DE_UPDATE on the DayEvent object
	; ^lbx:si = DayEvent object
	;
		mov	cl, DBUF_NEW		; database update mode
		mov	ax, MSG_DE_UPDATE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Make sure DS is point to DayPlanObject segment
	;
EC <		push	ax, bx, cx					>
EC <		mov	ax, ds			; ds = DayPlanObject seg>
EC <		GetResourceHandleNS	DayPlanObject, bx		>
EC <		call	MemDerefDS		; ds = new segment	>
EC <		mov	cx, ds			; cx = new segment	>
EC <		cmp	ax, cx			; cmp segments		>
EC <		ERROR_NE CALENDAR_INTERNAL_ERROR			>
EC <		pop	ax, bx, cx					>
	;
	; Reset DayPlanObject UI to display the event
	;
		mov	si, offset DayPlanObject
RSP <		mov	ax, MSG_DP_RESPONDER_RESET_UI			>
NRSP <		mov	ax, MSG_DP_RESET_UI				>
		call	ObjCallInstanceNoLock

		.leave
		ret
SetEventUpdateNewEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the event alarm

CALLED BY:	(INTERNAL) SetApiEventAlarm, SetClavinEventAlarm
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		ax	= CalendarAlarmStruct
		bp	= year
		dx	= month/date
		cx	= hour/minute or TRUE if use default alarm time
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if (no alarm) quit;
		check what time the alarm goes off {
			if (unit not minute) {		// responder
				set alarm = 60 min before
			}
		}
		Calculate what time the alarm goes off;
		Set alarm on the event;
		(no need to send MSG_DE_UPDATE because MSG_DE_SET_ALARM will
		do so.)

		The routine will try to recover from errors. e.g. if an alarm
		is to be made one day in advance, and responder does not
		support that, alarm will be made one hour in advance (the
		most responder will handle.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 3/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventAlarm	proc	near
		uses	ax, cx, dx, ds, es, di
		.enter
		Assert	optr, bxsi
		Assert	segment, ds
		Assert	record	ax, CalendarAlarmStruct
	;
	; Any alarm in the appointment?
	;
		test	ax, mask CAS_HAS_ALARM
		jz	noAlarm
	;
	; Check if default time is to be used
	;
EC <		call	CheckValidDate		; carry set if err	>
EC <		ERROR_C INVALID_EVENT_DATE				>
		cmp	cx, TRUE
NEC <		jne	extractAlarm					>
EC <		je	setDefaultAlarm					>
EC <		call	CheckValidTime		; carry set if err	>
EC <		ERROR_C INVALID_EVENT_TIME				>
EC <		jmp	extractAlarm					>

setDefaultAlarm::
		mov	cx, DEFAULT_START_TIME
	;
	; See how many minutes the alarm is ahead of the appointment.
	;
extractAlarm:
		push	cx, dx, bp		; event time/date/year,

		mov	dx, ax
		andnf	ax, mask CAS_TYPE
		mov	cl, offset CAS_TYPE
		shr	ax, cl			; ax=CalendarAlarmIntervalType
		andnf	dx, mask CAS_INTERVAL	; dx=interval
		GetResourceSegmentNS	dgroup, es

	;
	; Non-responder. Set up precedeMinute or precedeHour
	;
PrintMessage<Not thoroughly test. -- kho, 8/12/96>
		cmp	ax, CAIT_MINUTES
		jne	10$
	;
	; Deal with CAIT_MINUTES
	;
		cmp	dx, 59
EC <		WARNING_G ALARM_INTERVAL_TOO_BIG			>
		jbe	goodMin
		mov	dx, 59
goodMin:
		mov	es:[precedeMinute], dl
		jmp	doneSetup
10$:
		cmp	ax, CAIT_HOURS
		jne	20$
	;
	; Deal with CAIT_HOURS
	;
		cmp	dx, 23
EC <		WARNING_G ALARM_INTERVAL_TOO_BIG			>
		jbe	goodHour
		mov	dx, 23
goodHour:
		mov	es:[precedeHour], dl
		jmp	doneSetup
20$:
		cmp	ax, CAIT_DAYS
EC <		WARNING_NE ALARM_INTERVAL_TYPE_NOT_SUPPORTED		>
		jne	doneSetup		
	;
	; Deal with CAIT_DAYS
	;
		cmp	dx, 365
EC <		WARNING_G ALARM_INTERVAL_TOO_BIG			>
		jbe	goodDay
		mov	dx, 365
goodDay:
		mov	es:[precedeDay], dx
doneSetup:

	;
	; Now that dgroup precedeHour/Minute/Day are set, calculate what time
	; should the alarm go off.
	;
		pop	cx, dx, bp			; event time/date/year
		call	CalculateAlarmTimeFar		; alarm time/date/year
	;
	; Restore the precede[Day|Hour|Minute] to zero.
	;
		clr	es:[precedeHour], es:[precedeMinute], es:[precedeDay]
	;
	; Set our alarm time. Handler will update the event.
	;
		mov	ax, MSG_DE_SET_ALARM
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; And set the alarm flag.
	;
		mov	ax, MSG_DE_SET_STATE_FLAGS
		mov	cl, mask EIF_ALARM_ON
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
noAlarm:
		.leave
		ret
SetEventAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventRepeatInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the repeat info of the DayEvent object, if any.

CALLED BY:	(INTERNAL) SetClavinEventRepeatInfo
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		dl	= MBRepeatDuration (MBRD_FOREVER or MBRD_UNTIL)
			if MBRD_UNTIL:
			bp	= FileDate
		di	= MBRepeatInterval
RETURN:		carry set if error
		carry cleared otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Special case: MBRepeatInterval<0, 0, 1, MBRIT_WEEKLY>
		is biweekly.

		Set the type of repeat event.
		Set the repeat-until date, if any.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/20/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventRepeatInfo	proc	near
		uses	ax, cx, dx, bp, di
		.enter
		Assert	segment, ds
		Assert	etype, dl, MBRepeatDuration
		Assert	record, di, MBRepeatInterval
	;
	; Handle special case.
	;
		cmp	di, MBRepeatInterval<0, 0, 1, MBRIT_WEEKLY>
		mov	cx, EOTT_BIWEEKLY
		je	setType
	;
	; Extract MBRepeatIntervalType.
	;
		andnf	di, mask MBRI_TYPE		; di <-
							; MBRepeatIntervalType
		cmp	di, MBRepeatIntervalType
		ja	error
	;
	; Find the corresponding alarm type for responder.
	;
		shl	di
		mov	cx, cs:[repeatEnumTable][di]
setType:
		mov	ax, MSG_DE_CHANGE_TYPE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Any repeat-until date?
	;
		; dl == MBRepeatDuration
		cmp	dl, MBRD_UNTIL
		clc					; assume no error
		jne	quit

		; bp == FileDate
		mov_tr	ax, bp
		push	bx
		call	BreakUpFileDate			; ax <- year, bl<-day,
							; bh <- month
		mov_tr	cx, ax
		mov	dx, bx
		pop	bx
	;
	; Set repeat-until date.
	;
		mov	ax, MSG_DE_SET_REPEAT_UNTIL_DATE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; carry set if
							;  invalid date
quit:
		.leave
		ret
error:
		stc
		jmp	quit
SetEventRepeatInfo	endp

repeatEnumTable EventOptionsTypeType \
	EOTT_DAILY,		; MBRIT_DAILY
	EOTT_WEEKLY,		; MBRIT_WEEKLY
	EOTT_MONTHLY,		; MBRIT_MONTHLY_WEEKDAY
	EOTT_MONTHLY,		; MBRIT_MONTHLY_DATE
	EOTT_ANNIVERSARY,	; MBRIT_YEARLY_WEEKDAY
	EOTT_ANNIVERSARY,	; MBRIT_YEARLY_DATE
	EOTT_WORKING_DAYS,	; MBRIT_MON_TO_FRI
	EOTT_WORKING_DAYS	; MBRIT_MON_TO_SAT -- not specially handled!

CheckHack<length repeatEnumTable eq MBRepeatIntervalType>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventInternalInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the internal data of the DayEvent object and reset DB
		item for deletion

CALLED BY:	(INTERNAL) DayPlanModifyEventByIDFromApi
PASS:		^lbx:si	= DayEventClass object to put info to
		cx:dx	= DB Group:Item of event to copy information from
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	DB item passed in will have some fields reset so that the associating
	data will be preserved upon event deletion.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 6/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventInternalInfo	proc	near
		uses	ax, es, di
		.enter
		
		movdw	axdi, cxdx
		call	GP_DBLockDerefDI	; es:di = event data

		IsEventRepeatEvent	ax
		jz	repeatEvent
	;
	; Copy internal information from a normal event
	;
		push	es:[di].ES_memoToken
		pushdw	es:[di].ES_uniqueID
		push	es:[di].ES_sentToArrayBlock
		push	es:[di].ES_sentToArrayChunk
		push	es:[di].ES_nextBookID
	;
	; Nullify the info in EventStruct so that deleting event will not
	; delete those associating data: memo token, sent-to array. 
	;
		mov	es:[di].ES_memoToken, NO_MEMO_TOKEN
		clr	es:[di].ES_sentToArrayBlock
		clr	es:[di].ES_sentToArrayChunk
		jmp	setDayEvent
	;
	; Copy internal information from a repeat event
	;
repeatEvent:
		push	es:[di].RES_memoToken
		pushdw	es:[di].RES_uniqueID
		push	es:[di].RES_sentToArrayBlock
		push	es:[di].RES_sentToArrayChunk
		push	es:[di].RES_nextBookID
	;
	; Nullify the info in RepeatStruct so that deleting event will not
	; delete those associating data: memo token, sent-to array. 
	;
		mov	es:[di].RES_memoToken, NO_MEMO_TOKEN
		clr	es:[di].RES_sentToArrayBlock
		clr	es:[di].RES_sentToArrayChunk
setDayEvent:
		call	SetEventInternalInfoCommon

		call	GP_DBDirtyUnlock	; es destroyed
		.leave
		ret
SetEventInternalInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventInternalInfoCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the internal data of the DayEvent object regardless of
		normal event or repeat event

CALLED BY:	(INTERNAL) SetEventInternalInfo
PASS:		memoToken	= memo token of event		(push first)
		uniqueID	= unique ID of event		(push 2nd)
		sentToArrayBlock= Sent-to array VM block	(push 3rd)
		sentToArrayChunk= Sent-to array chunk handle	(push 4th)
		nextBookID	= next Booking ID		(push 5th)
		^lbx:si		= DayEventClass object
		ds		= to be fixed up if necessary
RETURN:		ds		= fixed up if necessary
		(arguments cleaned up by this routine)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Set memo token;
	Set unique ID;
	Set Sent-to chunk array;
	Set next book ID;		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 6/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventInternalInfoCommon	proc	near	nextBookID:word,
						sentToArrayChunk:word,
						sentToArrayBlock:word,
						uniqueID:dword,
						memoToken:word
		uses	ax, cx, dx, di
		.enter
		Assert	optr	bxsi
	;
	; Set memo token
	;
		mov	cx, ss:[memoToken]
		mov	ax, MSG_DE_SET_MEMO_TOKEN
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Set unique ID
	;
		movdw	cxdx, ss:[uniqueID]
		mov	ax, MSG_DE_SET_UNIQUE_ID
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Set Sent-to array
	;
		mov	cx, ss:[sentToArrayBlock]
		mov	dx, ss:[sentToArrayChunk]
		mov	ax, MSG_DE_SET_SENT_TO_CHUNK_ARRAY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Set next booking ID
	;
		mov	cx, ss:[nextBookID]
		mov	ax, MSG_DE_SET_NEXT_BOOK_ID
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		
		.leave
		ret	@ArgSize
SetEventInternalInfoCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearEventInternalInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the info in EventStruct or RepeatStruct, similar
		to SetEventInternalInfo, so that when the struct is
		deleted, the associating data would not be deleted.
CALLED BY:	(INTERNAL) DayPlanModifyEventByGrItFromMBAppointment
PASS:		cx:dx	= DB Group:Item of event to clear
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/25/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearEventInternalInfo	proc	near
		uses	ax, es, di
		.enter
		movdw	axdi, cxdx
		call	GP_DBLockDerefDI	; es:di = event data
	;
	; Repeat event?
	;
		IsEventRepeatEvent	ax
		mov	ax, 0			; preserve z flag!
		jz	repeatEvent
	;
	; Nullify the info in EventStruct so that deleting event will not
	; delete those associating data: memo token, sent-to array. 
	;
		mov	es:[di].ES_memoToken, NO_MEMO_TOKEN
		mov	es:[di].ES_sentToArrayBlock, ax
		mov	es:[di].ES_sentToArrayChunk, ax
		jmp	quit
		
repeatEvent:
	;
	; Nullify the info in RepeatStruct so that deleting event will not
	; delete those associating data: memo token, sent-to array. 
	;
		mov	es:[di].RES_memoToken, NO_MEMO_TOKEN
		mov	es:[di].RES_sentToArrayBlock, ax
		mov	es:[di].RES_sentToArrayChunk, ax
quit:
		call	GP_DBDirtyUnlock	; es destroyed

		.leave
		ret
ClearEventInternalInfo	endp

if	CALAPI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEventGetUniqueID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get unique ID of the day event

CALLED BY:	(INTERNAL) DayPlanCreateEventFromApi,
		DayPlanModifyEventByIDFromApi, StuffClavinInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object to get unique ID from
		ds	= DayPlanObject segment
RETURN:		cxdx	= unique ID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/11/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEventGetUniqueID	proc	near
		uses	ax, di
		.enter
		Assert	optr	bxsi

		mov	ax, MSG_DE_GET_UNIQUE_ID
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cxdx = unique ID

		Assert	eventID	cxdx
		.leave
		ret
SetEventGetUniqueID	endp

endif	; CALAPI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanIsEventByIDSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if an event is currently selected by comparing event ID

CALLED BY:	(INTERNAL) DayPlanDeleteEventByIDFromApi,
		DayPlanModifyEventByIDFromApi
PASS:		*ds:si	= DayPlanClass object
		cxdx	= event ID to check
RETURN:		carry set if passed event is currently selected
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get the current selection of DayPlanObject;
	if (selection == NULL) {
		return NOT SELECTED;
	}
	Get event ID of selected DayEvent;
	if (event ID got == INVALID_EVENT_ID) {
		return NOT SELECTED;
	}
	if (event ID of selected DayEvent != event ID to check) {
		return NOT SELECTED;
	} else {
		return SELECTED;
	} 

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/20/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanIsEventByIDSelected	proc	near
	eventID		local	dword	push	cx, dx
		uses	ax, cx, dx, si
		.enter
		Assert	eventID		cxdx
		Assert	objectPtr	dssi, DayPlanClass
	;
	; Get selected DayEvent object
	;
		push	bp
		mov	ax, MSG_DP_GET_SELECT
		call	ObjCallInstanceNoLock	; bp = DayEvent chunk handle
						;   (maybe 0)
		mov	si, bp			; *ds:si = DayEvent object

		tst	bp			; any selection? carry cleared
		pop	bp			; restore stack
EC <		WARNING_Z EVENT_HANDLE_DOESNT_EXIST_SO_OPERATION_IGNORED>
		jz	done
	;
	; Get the event's unique ID
	;
		mov	ax, MSG_DE_GET_UNIQUE_ID
		call	ObjCallInstanceNoLock	; cxdx = ID of selected event
	;
	; If the selected event is virgin, it is not a match
	;
		cmpdw	cxdx, INVALID_EVENT_ID
		je	done			; carry clear if equal

		Assert	eventID	cxdx
		cmpdw	cxdx, ss:[eventID]	; cmp selected event's ID
		stc				; default: IDs are the same
		je	done

		clc				; not equal
done:
		.leave
		ret
DayPlanIsEventByIDSelected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateTimeToFileDateAndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert date and time into FileDate and FileTime format

CALLED BY:	(INTERNAL) DayPlanGetNormalEventData
PASS:		if there is a date,
			bp	= year
			dh	= month
			dl	= day
		otherwise,
			dx	= CAL_NO_DATE

		if there is a time,
			ch	= hour
			cl	= minute
		otherwise,
			cx	= CAL_NO_TIME

RETURN:		dx	= FileDate if there is a date,
			otherwise, CAL_NO_DATE
		cx	= FileTime if there is a time,
			otherwise, CAL_NO_TIME
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (has date) {
		Convert date;
	} else {
		return date as CAL_NO_DATE;
	}
	if (has time) {
		Convert time;
	} else {
		return time as CAL_NO_TIME;
	}

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/25/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DateTimeToFileDateAndTime	proc	near
		uses	ax, bp
		.enter
	;
	; Check if there is a date
	;
		cmp	dx, CAL_NO_DATE		; any date?
		je	convertTime
EC <		call	CheckValidDate		; carry set if invalid	>
EC <		ERROR_C INVALID_EVENT_DATE				>
	;
	; Convert date to FileDate
	;
	; FileDate is word size. The high bit of FD_MONTH is the last bit of
	; DH. Since FD_MONTH has 4 bits, we rotate DX right 3 times to make
	; high bit of FD_MONTH to be the LSB of DH.
	;
		mov_tr	al, dl			; al = day
		.assert (offset FD_MONTH eq 5) and (width FD_MONTH eq 4) \
			and (size FileDate eq 2)
		shr	dx
		shr	dx
		shr	dx			; FD_MONTH set
		andnf	dx, mask FD_MONTH	; clear non FD_MONTH stuff
	;
	; Now we can set the day by "OR"ing since FD_DAY has offset 0
	;
		.assert (offset FD_DAY eq 0)
		ornf	dl, al			; FD_DAY set
	;
	; Set year here
	;
		sub	bp, FILE_BASE_YEAR	; bp = year since base year
		push	cx			; save time
		mov	cl, offset FD_YEAR
		shl	bp, cl			; bp = FD_YEAR
		ornf	dx, bp			; FD_YEAR set, dx = FileDate
		pop	cx			; restore time
		Assert	record	dx, FileDate

convertTime:
	;
	; Check if there is a time
	;
		cmp	cx, CAL_NO_TIME		; any time?
		je	done
EC <		call	CheckValidTime		; carry set if error	>
EC <		ERROR_C INVALID_EVENT_TIME				>
	;
	; FileTime is word size. FD_HOUR is at high bits and so CH (hour) has
	; to be rotated left.
	;
		.assert (offset FT_HOUR eq 11) and (offset FT_MIN eq 5) and \
			(size FileTime eq 2)
		clr	ah
		mov_tr	al, cl			; ax = min
		shl	ch
		shl	ch
		shl	ch			; FT_HOUR set
		andnf	cx, mask FT_HOUR	; clear non FT_HOUR stuff
	;
	; Shift minutes to FT_MIN mask and set FileTime
	;
		push	cx
		mov	cl, offset FT_MIN
		shl	ax, cl			; ax = FT_MIN
		pop	cx			; restore FT_HOUR 
		ornf	cx, ax			; cx = FileTime
		Assert	record	cx, FileTime
		
done:
		.leave
		ret
DateTimeToFileDateAndTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCopyEventString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy event data string from a source to destination

CALLED BY:	(INTERNAL) DayPlanGetNormalEventData
PASS:		ds:[si][bp]	= destination to copy text to
		es:[di][bx]	= source of null-terminated text to copy from
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/27/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanCopyEventString	proc	near
		uses	ax, ds, si, es, di
		.enter

EC <		push	cx						>

EC <		push	di						>
EC <		add	di, bx						>
EC <		Assert_nullTerminatedAscii	esdi			>
EC <		call	LocalStringSize		; cx = size in bytes w/o NULL>
EC <		inc	cx			; reserve a space for NULL>
EC < DBCS <	inc	cx			; 1 more for DBCS	>>
EC <		Assert_buffer	dssi, cx				>
EC <		pop	di						>

		add	si, bp			; ds:si = dest
		add	di, bx			; es:di = src
		segxchg	ds, es
		xchg	si, di			; ds:si = src, es:di = dest
		LocalCopyString			; ax,si,di destroyed

EC <		pop	cx						>

		.leave
		ret
DayPlanCopyEventString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmToCalendarAlarmStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an alarm to CalendarAlarmStruct

CALLED BY:	(INTERNAL) DayPlanGetNormalEventData
PASS:           di	= alarm date year
		ah	= alarm date month
		al	= alarm date day
		bh	= alarm time hour
		bl	= alarm time minute

		bp	= start date year
		dh	= start date month
		dl	= start date day
		ch	= start time hour
		cl	= start time minute		
		
RETURN:		ax	= CalendarAlarmStruct
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/26/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlarmToCalendarAlarmStruct	proc	near
		.enter
	;
	; Find out the preceding minutes
	;
		call	CalculateAlarmPrecedeMins; ax = # of preceding minutes

		CheckHack <offset CAS_INTERVAL eq 0>
		BitSet	ax, CAS_HAS_ALARM

		CheckHack <CAIT_MINUTES eq 0>
		andnf	ax, not (mask CAS_TYPE)	; assign 0 to CAS_TYPE

		.leave
		ret
AlarmToCalendarAlarmStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarDoesReserveDayEventExist
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find out if a reserve whole day event exists within a given
		time period

CALLED BY:	(INTERNAL) DayPlanCheckIfMultipleDayEventExistsCallback
PASS:		es:di	= DateTimeRangeStruct of reserve whole day event time
			period
		ds:si	= DateTimeRangeStruct of query period
RETURN:		carry set if there exists reserve whole day event in query
			period 
		carry clear, otherwise
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Pre-condition:	These ranges overlap.

	Find out the first reserve whole day event at or after the
		query period;
	Compare first reserve whole day event with query period;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/11/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarDoesReserveDayEventExist	proc	near
	currentEventRange	local	DateTimeRangeStruct
						; current event to check
		uses	es, di
		.enter
EC <		call	CalendarCompareRange	; carry set if overlap	>
EC <		ERROR_NC CALENDAR_EXPECTED_TIME_RANGES_TO_OVERLAP	>
	;
	; Find the first event at or after start time of query period
	;
		call	CalendarFindReserveDayEvent
						; currentEventRange updated
	;
	; Compare the range of current event range and query period. If there
	; is no match, that means the query period does not overlap with any
	; reserve day event at all.
	;
		segmov	es, ss, ax
		lea	di, ss:[currentEventRange]
		call	CalendarCompareRange	; carry set if overlap
		
		lahf				; save flags
		.leave
		sahf				; restore flags
		ret
CalendarDoesReserveDayEventExist	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarFindReserveDayEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first reserve day event at or after a time

CALLED BY:	(INTERNAL) CalendarDoesReserveDayEventExist
PASS:		ss:bp	= inherited stack of CalendarDoesReserveDayEventExist
		es:di	= DateTimeRangeStruct of reserve whole day event time
			period
		ds:si	= DateTimeRangeStruct of query period
RETURN:		ss:[currentEventRange] filled with matched reserve day event.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Use current's start and end times in param;
	Load query period's info;
	if (event's start date > query period's start date) {
		Use the event's start date;
	} else {
		Use query period's start date;
		if (event's end time < query period's start time) {
			Use next date of query period's start date
				because the event has passed;
		}
	}
	Fill out the rest of date info;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/12/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarFindReserveDayEvent	proc	near
		uses	ax, bx, cx, dx
		.enter	inherit	CalendarDoesReserveDayEventExist
	;
	; ** WARNING **
	; There is some optimization of code based on the order of the fields
	; in structures. Please take a second to review the code if any of
	; these CheckHack's fails.
	;
		CheckHack <(offset RS_startDay)+1 eq (offset RS_startMonth)>
		CheckHack <(offset RS_endDay)+1 eq (offset RS_endMonth)>
		CheckHack <(offset DTRS_startMin)+1 eq (offset DTRS_startHour)>
		CheckHack <(offset DTRS_endMin)+1 eq (offset DTRS_endHour)>
	;
	; Copy the time of event first of 1 reserve whole day. Also load the
	; query period start date and time into the right registers.
	;
		movm	{word}ss:[currentEventRange].DTRS_startMin, \
			{word}es:[di].DTRS_startMin, ax
						; get both hour and min
		mov	ax, ds:[si].DTRS_dateRange.RS_startYear
		mov	dx, {word} ds:[si].DTRS_dateRange.RS_startDay
						; get both month and day
		mov	cx, {word} es:[di].DTRS_endMin
						; get both hour and min

		mov	{word} ss:[currentEventRange].DTRS_endMin, cx
						; set both hour and min
	;
	; If the event's start date is later than query period's start date,
	; that means the event is within query period and use event's start
	; date then.
	;
		cmp	ax, es:[di].DTRS_dateRange.RS_startYear
		jb	useEventDate
		cmp	dx, {word} es:[di].DTRS_dateRange.RS_startDay
		jae	checkEndTime		; compare both month and day
		
useEventDate:
		mov	ax, es:[di].DTRS_dateRange.RS_startYear
		mov	dx, {word} es:[di].DTRS_dateRange.RS_startDay
		jmp	setDate			; get both month and day
	;
	; Compare the start time of query period and the end time of
	; event.
	;
	; AX = start date year to check
	; DH = start date month to check
	; DL = start date day to check
	;
	; If query period's start time is the same or earlier, that
	; means the matching event is on query period's start date.
	;
	; If query period's start time is later than the end time of the
	; event, it means the matching event is the next day of query
	; period's start date.
	;
checkEndTime:
		mov	bx, {word} ds:[si].DTRS_startMin
						; bh=start hr, bl=start min
		cmp	bx, cx			; matching event on today?
		jbe	setDate			; jmp if today
	;
	; The event on query period's start date has passed. Use the next
	; day's event.
	;
nextDay::
		push	bp
		mov_tr	bp, ax			; bp = query start year 
		mov	cx, 1			; advance only 1 day
		call	CalcDateAltered		; bp=yr, dh=month, dl=day
						; carry set if error
EC <		ERROR_C INVALID_EVENT_DATE				>
		mov_tr	ax, bp			; ax = new year
		pop	bp
	;
	; Matching event is on query period's start date. Also, the event is
	; same day only.
	;
setDate:
		mov	ss:[currentEventRange].DTRS_dateRange.RS_startYear, ax
		mov	ss:[currentEventRange].DTRS_dateRange.RS_endYear, ax
		mov	{word} ss:[currentEventRange].DTRS_dateRange.RS_startDay, dx
		mov	{word} ss:[currentEventRange].DTRS_dateRange.RS_endDay, dx
						; set both month and day
		.leave
		ret
CalendarFindReserveDayEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarCompareRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two time range and determine if they overlap

CALLED BY:	(INTERNAL) CalendarDoesReserveDayEventExist,
		DayPlanCheckIfEventExistsCommon
PASS:		es:di	= DateTimeRangeStruct (call it event A)
		ds:si	= DateTimeRangeStruct (call it event B)
RETURN:		carry set if they overlap
		carry clear if they do not overlap
DESTROYED:	nothing
SIDE EFFECTS:	
	** NOTES **

	The comparison is inclusive. It means if the start time of a range is
	the same as the end time of another, they are considered
	overlapping. For example, if range A is (08:00 - 10:00) and range B
	is (10:00 - 12:00), they overlap at 10:00. 

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/11/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarCompareRange	proc	near
		uses	ax, bx, cx, dx, bp
		.enter
		Assert	fptr	dssi
		Assert	fptr	esdi
	;
	; ** WARNING **
	; There is some optimization of code based on the order of the fields
	; in structures. Please take a second to review the code if any of
	; these CheckHack's fails.
	;
		CheckHack <(offset RS_startDay)+1 eq (offset RS_startMonth)>
		CheckHack <(offset RS_endDay)+1 eq (offset RS_endMonth)>
		CheckHack <(offset DTRS_startMin)+1 eq (offset DTRS_startHour)>
		CheckHack <(offset DTRS_endMin)+1 eq (offset DTRS_endHour)>
	;
	; Find out whether the event or the period to search is earlier.
	;
		push	di
		mov	ax, {word} es:[di].DTRS_dateRange.RS_startDay
						; get A's start month and day
		mov	bx, {word} es:[di].DTRS_startMin
						; get A's start hour and min
		mov	di, es:[di].DTRS_dateRange.RS_startYear
						; Got event (A)'s start time

		mov	bp, ds:[si].DTRS_dateRange.RS_startYear
		mov	dx, {word} ds:[si].DTRS_dateRange.RS_startDay
						; get B's start month and day
		mov	cx, {word} ds:[si].DTRS_startMin
						; Got event (B)'s start time
		call	CalendarCompareDateTime	; cmp  (A's start), (B's start)
		pop	di			; es:di = event (A)
		jb	queryPeriodLater
	;
	; Start time of event (A) is equal to or later than that of event (B)
	; Now, we want to compare the end time of event (B) against the start
	; time of event (A). If the former is later than or equal to the
	; latter, these events overlap.
	;
		push	di
		mov	di, es:[di].DTRS_dateRange.RS_startYear
						; recover A's year
		mov	bp, ds:[si].DTRS_dateRange.RS_endYear
		mov	dx, {word} ds:[si].DTRS_dateRange.RS_endDay
						; get B's end month and day
		mov	cx, {word} ds:[si].DTRS_endMin
						; Got event (B)'s end time
		call	CalendarCompareDateTime	; cmp  (A'start), (B's end)
		pop	di
		jbe	match
		jmp	noMatch
	;
	; Start time of query period is later than that of event. We want to
	; see if the end time of event is equal to or later than the start
	; time of query period. If so, these events overlap.
	;
queryPeriodLater:
		push	di
		mov	ax, {word} es:[di].DTRS_dateRange.RS_endDay
						; get A's end month and day
		mov	bx, {word} es:[di].DTRS_endMin
						; get A's end hour and min
		mov	di, es:[di].DTRS_dateRange.RS_endYear
						; Becomes event (A)'s end time
		call	CalendarCompareDateTime	; cmp  (A's end), (B's start)
		pop	di			; es:di = event (A)
		jb	noMatch
		
match:
		stc
		jmp	done

noMatch:
		clc				; enumerate next event

done:
		.leave
		ret
CalendarCompareRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarCompareDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare date and time of two events to see which one is
		earlier 

CALLED BY:	(INTERNAL) CalendarCompareRange
PASS:		di	= event (A) date year
		ah	= event (A) date month
		al	= event (A) date day
		bh	= event (A) time hour
		bl	= event (A) time minute

		bp	= event (B) date year
		dh	= event (B) date month
		dl	= event (B) date day
		ch	= event (B) time hour
		cl	= event (B) time minute		
RETURN:		Flags are the same as "cmp <event A>,<event B>":

		For example,

		If both times are equal:
			ZF is set and carry is clear

		If event (A) is later than event (B),
			ZF is clear and carry is clear

		If event (A) is earlier than event (B),
			ZF is set and carry is set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 9/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarCompareDateTime	proc	near
		.enter

		cmp	di, bp			; compare year
		jne	done
		cmp	ax, dx			; compare month/day
		jne	done
		cmp	bx, cx			; compare hour/minute

done:
		.leave
		ret
CalendarCompareDateTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarVerifyEndDateTimeNotEarlier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the end date and end time of
		DateTimeRangeStruct is not earlier than its start date
		and start time.

CALLED BY:	(INTERNAL) DayPlanCheckIfEventExists
PASS:		ds:si	= DateTimeRangeStruct
RETURN:		carry set if error (end date and end time are earlier
		than start date and start time)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/17/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarVerifyEndDateTimeNotEarlier	proc	near
		uses	ax
		.enter
	;
	; Compare dates
	;
		cmpm	ds:[si].DTRS_dateRange.RS_endYear, \
			ds:[si].DTRS_dateRange.RS_startYear, ax
		jne	done
		CheckHack <(offset RS_endDay)+1 eq (offset RS_endMonth)>
		CheckHack <(offset RS_startDay)+1 eq (offset RS_startMonth)>
		cmpm	{word}ds:[si].DTRS_dateRange.RS_endDay, \
			{word}ds:[si].DTRS_dateRange.RS_startDay, ax
		jne	done			; compare month and day
	;
	; Compare times
	;
		CheckHack <(offset DTRS_startMin)+1 eq (offset DTRS_startHour)> 
		CheckHack <(offset DTRS_endMin)+1 eq (offset DTRS_endHour)>
		cmpm	{word}ds:[si].DTRS_endMin, \
			{word}ds:[si].DTRS_startMin, ax
						; compare hour and mins
	;
	; Carry set if end date/time is earlier than start date/time.
	;
done:
		.leave
		ret
CalendarVerifyEndDateTimeNotEarlier	endp

ApiCode	ends

endif	; HANDLE_MAILBOX_MSG or CALAPI

