COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Calendar/Dayplan
FILE:		dayplanMailbox.asm

AUTHOR:		Jason Ho, Aug  8, 1996

ROUTINES:
	Name				Description
	----				-----------
    MTD MSG_DP_CREATE_EVENT_FROM_CLAVIN
				Create an event based on info passed by
				mailbox.

    MTD MSG_DP_CREATE_EVENT_FROM_MBAPPOINTMENT
				Create an event based on info passed by the
				MBAppointment struct.

    INT StuffClavinInfoIntoEvent
				Extract info from clavin block
				(MBAppointment), and stuff them to the
				DayEventObject.

    INT SetClavinEventStartDateTime
				Set the starting time/date in the DayEvent
				object. In case of to-do item, set the
				priority (in the time field).

    INT CheckValidDate		Verify that the year/month/day are valid.

    INT CheckValidTime		Verify that the hour/min are valid.

    INT SetClavinEventText	Set the event text to be the description
				text in the struct.

    INT SetClavinEventReserveWholeDay
				Set the reserve whole day of the event

    INT SetClavinEventEndTime	Set the end time or event, if any.

    INT SetClavinEventAlarm	Set the alarm info of the DayEvent object,
				if any.

    INT StoreSenderInfo		Create chunk array of EventSentToStruct,
				and put the sender's info (SMS number,
				event ID and book ID) into chunk array
				header.

    INT SetClavinEventRepeatInfo
				Set the repeat info of the DayEvent object,
				if any.

    INT StuffClavinTextAndAlarmIntoEvent
				Extract info from clavin block
				(MBAppointment), and stuff the text and
				alarm info to the DayEventObject.

    MTD MSG_DP_PRINT_ONE_DAY_TO_GSTATE
				Print the event list of the day to a
				gstate.

    MTD MSG_DP_MODIFY_EVENT_BY_GR_IT_FROM_MBAPPOINTMENT
				Change an event (specifed by Gr:It) based
				on info passed by the MBAppointment struct.

    INT BreakUpFileDateFar	Break up a FileDate into year, month, day.

    INT BreakUpFileDate		Break up a FileDate into year, month, day.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		8/ 8/96   	Initial revision
	simon		2/12/97		Moved some common code to
					dayplanUtils.asm 

DESCRIPTION:
	Create new events based on information supplied by clavin.
		

	$Id: dayplanMailbox.asm,v 1.1 97/04/04 14:47:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if HANDLE_MAILBOX_MSG

ApiCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCreateEventFromClavin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an event based on info passed by mailbox.

CALLED BY:	MSG_DP_CREATE_EVENT_FROM_CLAVIN
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		cx	= VM block handle containing MBAppointment struct
		dx	= VM file handle
RETURN:		cx	= VM block handle containing next MBAppointment
			  struct, 0 if none.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/ 8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanCreateEventFromClavin	method dynamic DayPlanClass, 
					MSG_DP_CREATE_EVENT_FROM_CLAVIN
		uses	ax, dx, bp
		.enter
		Assert	vmFileHandle, dx
	;
	; Lock down the block from clavin
	;
		mov_tr	ax, cx
		mov	bx, dx
		call	VMLock			; ax <- segment,
						; bp <- mem handle of
						; VM block
		mov	es, ax
		mov_tr	cx, ax			; cx <- segment
	;
	; Call message to create event.
	;
		mov	ax, MSG_DP_CREATE_EVENT_FROM_MBAPPOINTMENT
		call	ObjCallInstanceNoLock
	;
	; Get the next VM block handle to be returned.
	;
		mov	cx, es:[MBA_meta].VMCL_next
	;
	; Unlock the block.
	;
	; bp == mem handle of VM block
	;
		call	VMUnlock

		.leave
		ret
DayPlanCreateEventFromClavin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCreateEventFromMBAppoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an event based on info passed by the
		MBAppointment struct.

CALLED BY:	MSG_DP_CREATE_EVENT_FROM_MBAPPOINTMENT
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		cx	= segment containing MBAppointment structure
RETURN:		cxdx	= unique event ID of created event
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanCreateEventFromMBAppoint	method dynamic DayPlanClass, 
					MSG_DP_CREATE_EVENT_FROM_MBAPPOINTMENT
		uses	ax
		.enter
		Assert	segment, cx
	;
	; Create a buffer for event
	;
		mov_tr	ax, cx
		mov	di, offset DayEventClass
		call	BufferCreate			; ^lcx:dx <- new event
		mov_tr	es, ax				; es <- struct segment
		movdw	bxsi, cxdx			; ^lbx:si <- new event
	;
	; Extract info from struct, and fill in the event obj
	;
		call	StuffClavinInfoIntoEvent	; event is updated
							; when info added.
							; cxdx <- event id,
							; carry set if error
	;
	; Done with the buffer, so destroy it.
	;
		call	BufferDestroy
		
		.leave
		ret
DayPlanCreateEventFromMBAppoint	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffClavinInfoIntoEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract info from clavin block (MBAppointment), and
		stuff them to the DayEventObject.

CALLED BY:	(INTERNAL) DayPlanCreateEventFromMBAppoint
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object
		es	= segment containing MBAppointment struct
RETURN:		carry set if error occurs (e.g. illegal date/time)
		cx:dx	= event ID, INVALID_EVENT_ID if illegal
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		create chunk array of sent-to info
		store sender's info in header
		set start date/time
		set text
		set end time
		set alarm

		as the info is set, MSG_DE_UPDATE is sent to event.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/ 8/96    	Initial version
	simon	2/11/97		Use common codes in dayplanUtils.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StuffClavinInfoIntoEvent	proc	near
		uses	ax, bp
		.enter
		Assert	optr, bxsi
		Assert	segment, ds
		Assert	segment, es
	;
	; Do event initialization, set date/time of normal event, or
	; init the to-do item.
	;
		call	SetClavinEventStartDateTime
						; carry set if error
						; ax = CalendarEventError 
		jc	quit			; otherwise, bp = year
						; dx = month/day
						; cx = hour/minute
	;
	; Set the text in event obj to the passed string.
	;
		call	SetClavinEventText
	;
	; If this is a to-do item, it will not have end-time, alarm, and
	; repeat event info.
	; MBA_start.FDAT_date == MB_NO_TIME means this is a to-do item.
	;
		cmp	es:[MBA_start].FDAT_date, MB_NO_TIME
		je	insertEvent
	;
	; Set reserve whole day event, if any.
	;
		call	SetClavinEventReserveWholeDay ; carry set if error
		jc	quit
	;
	; If this is a same day to-do item, it will not have end-time, alarm
	; repeat info.
	;
	; If this is a reserved whole day event, it may have end time and
	; alarm info, but not repeat info.
	;
		cmp	es:[MBA_start].FDAT_time, CAL_NO_TIME
		jne	insertEndDateTime	; same day to-do item

		tst	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_reserveWholeDay
		jz	insertEvent		; same day to-do event!

	;
	; Set end time, if any.
	;
insertEndDateTime::
if	END_TIMES
		call	SetClavinEventEndTime	; carry set if error
		jc	quit
endif
	;
	; Set alarm stuff, if any.
	;
		call	SetClavinEventAlarm

insertEvent:
	;
	; Create ChunkArray of sent-to info, and put sender's info in
	; chunk array header.
	;
		call	StoreSenderInfo			; carry set if error
		jc	quit
	;
	; Do update.
	;
		call	SetEventUpdateNewEvent	; update event
	;
	; Set repeating info, if any.
	;
	;
	; Get the unique ID.
	;
		call	SetEventGetUniqueID		; cxdx <- ID
		clc					; no error
quit:
EC <		WARNING_C CLAVIN_EVENT_INVALID_SOME_INFO_DISCARDED	>
		jnc	done

		movdw	cxdx, INVALID_EVENT_ID		; return invalid id
done:
		.leave
		ret
StuffClavinInfoIntoEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClavinEventStartDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the starting time/date in the DayEvent object. In
		case of to-do item, set the priority (in the time field).

CALLED BY:	(INTERNAL) StuffClavinInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es	= segment containing MBAppointment struct
RETURN:		if this is not to-do item:
		bp	= year
		dx	= month/day
		cx	= hour/minute
		carry set if error occurs (e.g. illegal date/time)
			ax	= CalendarEventError
DESTROYED:	if this is to-do item:
		cx, dx, bp destroyed.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/ 9/96    	Initial version
	simon	2/11/97		Use common code SetEventStartDateTime

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetClavinEventStartDateTime	proc	near
		.enter

		movdw	cxdx, es:[MBA_start]
	;
	; Pass TRUE if create to-do item
	;
		CheckHack <(MB_NO_TIME eq -1) and (TRUE eq -1)>

		call	SetEventStartDateTime	; if this is not to-do item:
						; bp = year
						; dx = month/day
						; cx = hour/minute
						; carry set if error occurs
						; (e.g. illegal date/time)  
						; ax=CalendarEventError
		.leave
		ret
SetClavinEventStartDateTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckValidDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the year/month/day are valid.

CALLED BY:	(INTERNAL) SetEventGetDateTime
PASS:		bp	= year
		dh	= month
		dl	= day
RETURN:		carry set if not valid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Year: cannot be smaller than 1900 or greater than 9999

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckValidDate	proc	near
		uses	ax, bx, cx
		.enter
	;
	; Check year
	;
		cmp	bp, 1900			; carry set if below
		jc	quit
		cmp	bp, 9999+1
		cmc
		jc	quit
	;
	; Check month
	;
		cmp	dh, 1
		jc	quit
		cmp	dh, 12+1
		cmc
		jc	quit
	;
	; Check day
	;
		cmp	dl, 1
		jc	quit
		cmp	dl, 31+1
		cmc
		jc	quit
	;
	; See if the day is illegal, e.g. 2/30/1996.
	;
		mov	ax, bp
		mov	bl, dh
		call	LocalCalcDaysInMonth		; ch - days in month
		cmp	ch, dl				; carry set if below
quit:
		.leave
		ret
CheckValidDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckValidTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the hour/min are valid.

CALLED BY:	(INTERNAL) SetClavinEventEndTime, SetEventGetDateTime
PASS:		ch	= hour
		cl	= min
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckValidTime	proc	near
		.enter
	;
	; Check hour
	;
		cmp	ch, 0				; carry set if below
		jc	quit
		cmp	ch, 23+1
		cmc
		jc	quit
	;
	; Check min
	;
		cmp	cl, 0
		jc	quit
		cmp	cl, 59+1
		cmc
quit:
		.leave
		ret
CheckValidTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClavinEventText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the event text to be the description text in the
		struct.

CALLED BY:	(INTERNAL) StuffClavinInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es	= segment containing MBAppointment struct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/ 9/96    	Initial version
	simon	2/11/97		Use common code SetEventText

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetClavinEventText	proc	near
		uses	ax, dx, bp
		.enter
		Assert	segment	es

		mov	dx, es
		mov	bp, offset MBA_description; dx:bp = text
		call	SetEventText		; carry set if text too long
						; ax=CalendarEventError
		.leave
		ret
SetClavinEventText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClavinEventReserveWholeDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the reserve whole day of the event

CALLED BY:	(INTERNAL) StuffClavinInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es	= segment containing MBAppointment struct
RETURN:		carry set if invalid reserve whole day
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/20/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetClavinEventReserveWholeDay	proc	near
		uses	ax, cx
		.enter
	;
	; call a util routine.
	;
		mov	cx, \
			es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_reserveWholeDay
		call	SetEventReserveWholeDay	; carry set if error
						; ax = CalendarEventError
		.leave
		ret
SetClavinEventReserveWholeDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClavinEventEndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the end time or event, if any.

CALLED BY:	(INTERNAL) StuffClavinInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object
		es	= segment containing MBAppointment struct
RETURN:		carry set if error occurs (e.g. illegal date/time)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		To-do list item would not have called this.

		FileTime:	hhhhhMMM:MMMsssss
			FT_HOUR:5
			FT_MIN:6
			FT_2SEC:5		

		If event end time <= start time, let's not signal that
		as error because it's no big deal.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/ 9/96    	Initial version
	simon	2/11/97		Use common code SetEventEndDateTime

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	END_TIMES
SetClavinEventEndTime	proc	near
		uses	ax, cx, dx
		.enter
		Assert	optr, bxsi
		Assert	segment, ds
		Assert	segment, es

	;
	; If the event is reserve whole day, don't set end date.
	;
		mov	cx, es:[MBA_end].FDAT_time
		mov	dx, es:[MBA_end].FDAT_date

		tst	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_reserveWholeDay
		mov	ax, FALSE			; not always set time
		jz	setEndDateTime
		
		mov	dx, CAL_NO_DATE		; don't set date
		mov	al, TRUE		; always set the time

setEndDateTime:
		call	SetEventEndDateTime	; carry set if error
						; ax=CalendarEventError

		.leave
		ret
SetClavinEventEndTime	endp
endif		; END_TIMES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClavinEventAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the alarm info of the DayEvent object, if any.

CALLED BY:	(INTERNAL) StuffClavinInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es	= segment containing MBAppointment struct
		bp	= year
		dx	= month/day
		cx	= hour/minute or MB_NO_TIME if using default time
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/12/96    	Initial version
	simon	2/11/97		Use common code SetEventAlarm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetClavinEventAlarm	proc	near
		uses	ax
		.enter
	;
	; Make sure the Mailbox alarm struct is the same as
	; CalendarAlarmStruct
	;
		CheckHack <size MBAlarmInfo eq size CalendarAlarmStruct>
		CheckHack <offset MBAI_TYPE eq offset CAS_TYPE>
		CheckHack <offset MBAI_HAS_ALARM eq offset CAS_HAS_ALARM>
		CheckHack <offset MBAI_INTERVAL eq offset CAS_INTERVAL>
		CheckHack <MB_NO_TIME eq TRUE>
		mov	ax, es:[MBA_alarmInfo]
		call	SetEventAlarm

		.leave
		ret
SetClavinEventAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreSenderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create chunk array of EventSentToStruct, and put the
		sender's info (SMS number, event ID and book ID) into
		chunk array header.

CALLED BY:	(INTERNAL) StuffClavinInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es	= segment containing MBAppointment struct
RETURN:		carry set if error (not enough disk space)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 8/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreSenderInfo	proc	near
		uses	ax, cx, dx, bp, di
		.enter
		Assert	optr, bxsi
		Assert	segment, ds
		Assert	segment, es
	;
	; Send a message to DayEventClass object.
	;
		mov	cx, es				; cx <- segment
		mov	ax, MSG_DE_ADD_SENDER_INFO
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax, cx, dx, bp gone
							;  carry set if error
		.leave
		ret
StoreSenderInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClavinEventRepeatInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the repeat info of the DayEvent object, if any.

CALLED BY:	(INTERNAL) StuffClavinInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es	= segment containing MBAppointment struct
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
		StuffClavinTextAndAlarmIntoEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract info from clavin block (MBAppointment), and
		stuff the text and alarm info to the DayEventObject.

CALLED BY:	(INTERNAL) DayPlanModifyEventByGrItFromMBAppointment
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object
		es	= segment containing MBAppointment struct
RETURN:		cx:dx	= event ID, INVALID_EVENT_ID if illegal
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		So what is this for? If an event's text and/or alarm time is
		changed, SMS update is sent. However, this kind of change is
		considered non-time related, so user isn't prompted whether
		s/he wants to accept / deny it.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/25/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StuffClavinTextAndAlarmIntoEvent	proc	near
		uses	ax, bp, di
		.enter
		Assert	optr, bxsi
		Assert	segment, ds
		Assert	segment, es
	;
	; Set the text in event obj to the passed string.
	;
		call	SetClavinEventText
	;
	; Get event date/time.
	;
		mov	ax, MSG_DE_GET_TIME
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; bp <- year,
						;  dx <- month/date, 
						;  cx <- hr/min,
						;  carry set if no start time
		jc	skipAlarm
	;
	; Set alarm stuff, if any.
	;
		; bp == year, dx == month/day, cx == hr/min
		call	SetClavinEventAlarm		; alarm info updated
skipAlarm:
	;
	; Create ChunkArray of sent-to info, and put sender's info in
	; chunk array header.
	;
		call	StoreSenderInfo			; carry set if error
		jc	quit
	;
	; Do text update.
	;
		mov	ax, MSG_DE_UPDATE
		mov	cl, DBUF_EVENT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; di destroyed
	;
	; Get the unique ID.
	;
		call	SetEventGetUniqueID		; cxdx <- ID
		clc					; no error
quit:
EC <		WARNING_C CLAVIN_EVENT_INVALID_SOME_INFO_DISCARDED	>
		jnc	done

		movdw	cxdx, INVALID_EVENT_ID		; return invalid id
done:
		.leave
		ret
StuffClavinTextAndAlarmIntoEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPrintOneDayToGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the event list of the day to a gstate.

CALLED BY:	MSG_DP_PRINT_ONE_DAY_TO_GSTATE
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		^hbp	= GState
		cx	= FileDate
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This method essentially provides a snapshot of events
		of the day, and print it to the gstate. When the
		EventsListVisContent handles MSG_VIS_DRAW, it plays
		back the whole gstring.

		// To make sure the brief version of DayPlan gets printed
		backup viewInfo
		viewInfo = VT_CALENDAR_AND_EVENTS

		set up PrintRangeStruct
		send myself MSG_DP_PRINT_ENGINE

		restore viewInfo

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/12/96   	Initial version (mostly modified from
				DayPlanStartPrinting)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanPrintOneDayToGState	method dynamic DayPlanClass, 
					MSG_DP_PRINT_ONE_DAY_TO_GSTATE
		.enter
		Assert	gstate, bp
		Assert	record, cx, FileDate
	;
	; Backup viewInfo, a global variable that defines how
	; DayPlanObject draws (in narrow mode, or extended mode.)
	;
		GetResourceSegmentNS	dgroup, es
		mov	al, es:[viewInfo]
		push	ax
		mov	es:[viewInfo], VT_CALENDAR_AND_EVENTS
	;
	; Break up the FileDate.
	;
		mov_tr	ax, cx
		call	BreakUpFileDate			; ax <- year,
							; bh <- month
							; bl <- day
		mov	dx, bx
	;
	; Some set-up work
	;
		sub	sp, size PrintRangeStruct	; allocate this
							; structure 
		mov	bx, sp
		mov	ss:[bx].PRS_width, CONFIRM_EVENT_LIST_WIDTH*2
		mov	ss:[bx].PRS_height, CONFIRM_EVENT_LIST_HEIGHT
		mov	ss:[bx].PRS_gstate, bp
		mov	ss:[bx].PRS_pointSize, FOAM_NORMAL_FONT_SIZE
		mov	ss:[bx].PRS_specialValue, 2	; normal event printing

		mov	ss:[bx].PRS_range.RS_startYear, ax
		mov	ss:[bx].PRS_range.RS_endYear, ax
		mov	{word} ss:[bx].PRS_range.RS_startDay, dx
		mov	{word} ss:[bx].PRS_range.RS_endDay, dx
		mov	ss:[bx].PRS_currentSizeObj, 0	; no handle allocated
	;
	; Perform the actual printing
	;
		mov	cl, ds:[di].DPI_flags
		mov	ch, mask DPPF_FORCE_HEADERS or mask DPPF_ONE_LINE_EVENT
							; force a header and
							; one-line event
		
		mov	bp, bx				; ss:bp <-
							;  PrintRangeStruct
		mov	ax, MSG_DP_PRINT_ENGINE		; now do the real work
aboutToPrint::
		call	ObjCallInstanceNoLock

		add	sp, size PrintRangeStruct	; clean up the stack
	;
	; Restore viewInfo.
	;
		pop	ax
		mov	es:[viewInfo], al
		
		.leave
		ret
DayPlanPrintOneDayToGState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanModifyEventByGrItFromMBAppointment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change an event (specifed by Gr:It) based on info
		passed by the MBAppointment struct.

CALLED BY:	MSG_DP_MODIFY_EVENT_BY_GR_IT_FROM_MBAPPOINTMENT
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		cxdx	= Gr:It of event being changed
		bp	= segment containing MBAppointment struct
RETURN:		cxdx	= unique event ID of the changed event
		carry set if error
DESTROYED:	Nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Create temp DayEvent object;
		Stuff temp DayEvent object with data passed in;
		Transfer the internal info from event in database to
			temp DayEvent obj;
		Update the internal info;
		Delete the original event from database;
		Set the next alarm;
		Clean up temp DayEvent object;

		You might ask why the update part is done in a
		different way from DayPlanModifyEventByIDFromApi. In
		this routine, StuffClavinInfoIntoEvent is called, and
		event is updated (with DBUF_NEW) already, so we don't
		need to call SetEventUpdateNewEvent.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/13/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanModifyEventByGrItFromMBAppointment	method dynamic DayPlanClass, 
				MSG_DP_MODIFY_EVENT_BY_GR_IT_FROM_MBAPPOINTMENT
		uses	ax, bp
		.enter
		Assert	segment, bp
	;
	; Create a buffer for event.
	;
		pushdw	cxdx				; DB Gr:It

		mov	di, offset DayEventClass
		call	BufferCreate			; ^lcx:dx <- DayEvent
		movdw	bxsi, cxdx			; ^lbx:si <- DayEvent
		popdw	cxdx				; cx:dx <- Gr:It
							;  Gr:It of old event 
	;
	; Load the old event into the new DayEvent object.
	;
		mov	es, bp				; MBAppointment segment
		
		push	cx, dx
		mov	ax, MSG_DE_INIT
		IsEventRepeatEvent cx			; z set if repeat
		jnz	notRepeat
		mov	ax, MSG_DE_INIT_REPEAT_BY_GR_IT
		ornf	cx, REPEAT_MASK
notRepeat:
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax, cx, dx, bp gone
		pop	cx, dx
	;
	; Are we doing full-blown time change, or just text (and alarm time)
	; change?
	;
		cmp	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_apptStatus,\
				CAST_TEXT_CHANGED
		jne	timeChange
	;
	; Set text and alarm.
	;
		call	StuffClavinTextAndAlarmIntoEvent; cx:dx <- ID,
							;  carry set if error
							; >> EVENT ALSO
							;  UPDATED << 
		jmp	checkError
timeChange:
	;
	; Now that the internal data about the old event is copied to new
	; event, clear them in the old event struct, so that the associated
	; data (sent-to array, memo) won't get deleted when event is
	; deleted. 
	;
		call	ClearEventInternalInfo
	;
	; Delete the old event
	;
		; cx:dx == Gr:It
		push	si
		mov	si, offset DayPlanObject
		mov	ax, MSG_DP_DELETE_EVENT_BY_EVENT
		call	ObjCallInstanceNoLock
		pop	si
	;
	; Stuff the buffer event with updated info.
	;
		; es == MBAppointment struct
		call	StuffClavinInfoIntoEvent	; cx:dx <- ID,
							;  carry set if error
							; >> EVENT ALSO
							;  UPDATED << 
checkError:
		jc	error
	;
	; Re-set the next alarm. Alarm might be changed.
	;
RSP <		call	FindNextRTCMAlarm		; ds,es,ax,di gone>

		clc					; no error
quit:
	;
	; Delete the buffer.
	;
		; ^lbx:si == DayEventClass
		Assert	optr, bxsi
		call	BufferDestroy			; flags preserved
		
		.leave
		ret
error:
	;
	; Return unique id == INVALID_EVENT_ID.
	;
		movdw	cxdx, INVALID_EVENT_ID
		jmp	quit
DayPlanModifyEventByGrItFromMBAppointment	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakUpFileDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break up a FileDate into year, month, day.

CALLED BY:	(INTERNAL) DayPlanPrintOneDayToGState
PASS:		ax	= FileDate
RETURN:		ax	= Year
		bl	= Day (1-31)
		bh	= Month (1-12)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/11/96    	Initial version (modified from
				LocalFormatFileDateTime)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakUpFileDateFar	proc	far
		.enter
		call	BreakUpFileDate
		.leave
		ret
BreakUpFileDateFar	endp

BreakUpFileDate	proc	near
		uses	cx
		.enter
	;
	; Break FileDate into its components
	; ax <- year
	; bl <- month (1-12)
	; bh <- day (1-31)
	; 
		mov	bx, ax
		and   	bx, mask FD_MONTH               ; month
EC <		ERROR_Z	CALENDAR_DATE_TIME_ILLEGAL_MONTH		>
		mov     cl, offset FD_MONTH
		shr     bx, cl                          ; bl <- month
EC <		cmp	bx, 12						>
EC <		ERROR_A	CALENDAR_DATE_TIME_ILLEGAL_MONTH		>

		CheckHack <offset FD_DAY eq 0 and width FD_DAY lt 8>
		mov     bh, al                          ; bh = day
		and   	bh, mask FD_DAY                 ; day
EC <		ERROR_Z	CALENDAR_DATE_TIME_ILLEGAL_DAY			>
EC <		cmp	bh, 31						>
EC <		ERROR_A	CALENDAR_DATE_TIME_ILLEGAL_DAY			>

		CheckHack <offset FD_YEAR + width FD_YEAR eq width FileDate>
		mov     cl, offset FD_YEAR
		shr     ax, cl                          ; ax = DOS year
		add     ax, 1980                        ; ax <- actual year

		xchg	bh, bl
		.Leave
		ret
BreakUpFileDate	endp

ApiCode	ends

endif	; HANDLE_MAILBOX_MSG
