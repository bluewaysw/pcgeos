COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Calendar database API
MODULE:		Calendar
FILE:		dayplanApi.asm

AUTHOR:		Simon Auyeung, Feb  2, 1997

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_DP_CREATE_EVENT_FROM_API
				Create a new event from Calendar API

    MTD MSG_DP_MODIFY_EVENT_BY_ID_FROM_API
				Modify a calendar event by unique ID from
				Calendar API

    INT StuffApiInfoIntoEvent	Extract API info into the event

    INT SetApiEventStartDateTime
				Set the start date and time from API to an
				event

    INT SetApiEventEndDateTime	Set the end date and time from API to an
				event

    INT SetApiEventText		Set event text from API to event

    INT SetApiEventReserveWholeDay
				Set the reserve whole day of the event

    INT SetApiEventAlarm	Set the event alarm

    MTD MSG_DP_DELETE_EVENT_BY_ID_FROM_API
				Delete an event by unique event ID from
				Calendar API

    MTD MSG_DP_DELETE_EVENT_BY_EVENT
				Delete an event by event DB group:item
				without bringing up additional UI

    MTD MSG_DP_GET_EVENT_BY_ID_FROM_API
				Get an event by unique event ID from
				Calendar API

    INT DayPlanGetNormalEvent	Get normal event data

    INT DayPlanGetNormalEventData
				Copy data from normal event EventStrct to
				CalendarReturnedEventStruct

    INT DayPlanGetNormalEventDataSetTodo
				Return to-do event info from an event

    MTD MSG_DP_CHECK_IF_EVENT_EXISTS
				Check there exists any event within a
				period of time

    INT CalendarEnumMultipleDayEvents
				Enumerate all multiple day events and call
				the callback message

    MTD MSG_DP_CHECK_IF_MULTIPLE_DAY_EVENT_EXISTS_CALLBACK
				Callback to see if a multiple day event
				coincides with a period of time

    INT CalendarEnumNormalEvents
				Enumerate normal events (single day and
				non-repeating) within a date range and call
				the callback.

    INT CalendarEnumNormalEventsInDay
				Enumerate normal events (single day and
				non-repeating) in a given day and call the
				callback.

    MTD MSG_DP_CHECK_IF_NORMAL_EVENT_EXISTS_CALLBACK
				Callback to see if a normal event coincides
				with a period of time.

    INT DayPlanCheckIfEventExistsCommon
				Check if an event of EventStruct exists
				over a period of time

    INT CalendarEnumCommonEventsCallback
				Invoke the callback message on the
				currently enumerated event.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/ 2/97   	Initial revision


DESCRIPTION:
	This file contains codes to access and manipulate calendar database
	via external API with other applications.
	

	$Id: dayplanApi.asm,v 1.1 97/04/04 14:47:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	CALAPI

ApiCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCreateEventFromApi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new event from Calendar API

CALLED BY:	MSG_DP_CREATE_EVENT_FROM_API
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
                ds:bx   = DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		dx:bp	= fptr to CalendarEventParamStruct
RETURN:		if there is error,
			cx = CalendarEventError
		if there is no error
			cx	= CEE_NORMAL
			dx:bp	= unique event ID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Create a bogus DayEvent object;
	Stuff it with new data and update it to database;
	Insert stuffed DayEvent object into database;
	Return unique ID;
	Delete the bogus DayEvent object;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 2/97   	Initial version
	simon   3/ 7/97		Insert event and get unique ID here

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanCreateEventFromApi	method dynamic DayPlanClass, 
					MSG_DP_CREATE_EVENT_FROM_API
		uses	ax
		.enter
		Assert	fptrXIP	dxbp
	;
	; Create a buffer for event
	;
		push	dx
		mov	di, offset DayEventClass
		call	BufferCreate		; ^lcx:dx <- DayEvent obj
		movdw	bxsi, cxdx		; ^lbx:si <- DayEvent obj
		pop	dx			; dx:bp =
						; CalendarEventParamStruct 
	;
	; Extract info from struct, and fill in the event obj
	;
		call	StuffApiInfoIntoEvent	; event is updated when info
						;   added. 
						; carry set if error
						;   ax = CalendarEventError
						; carry clear if no error
						;   ax = CEE_NORMAL
		jc	error
	;
	; Create event in calendar database
	;
		call	SetEventUpdateNewEvent
	;
	; Get and return event ID
	;
		call	SetEventGetUniqueID	; cxdx = ID

		Assert	eventID	cxdx
		movdw	dxbp, cxdx		; return unique ID
		mov	cx, CEE_NORMAL
		jmp	done

error:
		mov_tr	cx, ax			; cx = CalendarEventError
	;
	; Done with the buffer, so destroy it.
	;
done:
		call	BufferDestroy		; flags preserved

		.leave
		ret
DayPlanCreateEventFromApi	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanModifyEventByIDFromApi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify a calendar event by unique ID from Calendar API

CALLED BY:	MSG_DP_MODIFY_EVENT_BY_ID_FROM_API
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
                ds:bx   = DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		ss:bp	= DayPlanModifyEventParams
		dx	= size of DayPlanModifyEventParams
RETURN:		if there is error,
			cx	= CalendarEventError
		if there is no error
			cx	= CEE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (event not found) {
		return CEE_EVENT_NOT_FOUND;
	}
	if (event has focus) {
		return CEE_ACCESS_DENIED;
	}
	Create temp DayEvent object;
	Stuff temp DayEvent object with data passed in;
	Transfer the internal info from event in database to temp DayEvent
		obj;
	Delete the original event from database;
	Re-insert the updated event via temp DayEvent object;
	Set the next alarm;
	Clean up temp DayEvent object;
	return CEE_NORMAL;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 6/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanModifyEventByIDFromApi	method dynamic DayPlanClass, 
					MSG_DP_MODIFY_EVENT_BY_ID_FROM_API
		uses	ax, dx
		.enter
	;
	; Is the event in the database?
	;
		push	es
		movdw	cxdx, ss:[bp].DPMEP_eventID			
		call	DBSearchEventIDArray	; carry set if event found
						;   ax:di = Gr:It of event
						;   cxdx = element index
						;   es destroyed
		pop	es
		mov	cx, CEE_EVENT_NOT_FOUND
		jnc	done
	;
	; If DayPlanObject has focus on the event (being deleted), return
	; access denied error. This seems to be the easiest way to avoid many
	; synchronization errors. If we have more time, we can implement a
	; better synchronization scheme.
	;
		movdw	cxdx, ss:[bp].DPMEP_eventID
		call	DayPlanIsEventByIDSelected
		mov	cx, CEE_ACCESS_DENIED	; carry if event has focus
		jc	done
	;
	; Create a buffer for event
	;
		pushdw	axdi			; save old event DB Gr:It 
		mov	di, offset DayEventClass
		call	BufferCreate		; ^lcx:dx = DayEvent object
		movdw	bxsi, cxdx		; ^lbx:si = DayEvent object
	;
	; Stuff the buffer event with updated info
	;
		push	bp
		movdw	dxbp, ss:[bp].DPMEP_param
		call	StuffApiInfoIntoEvent	; carry set if error
						;   ax = CalendarEventError
						; otherwise, ax = CEE_NORMAL
		pop	bp
		popdw	cxdx			; cx:dx = Gr:It of old event
		jc	error
	;
	; If there is no error, copy the internal data about the old event to
	; the new event.
	;
		call	SetEventInternalInfo
	;
	; Delete the old event
	;
		push	si
		mov	si, offset DayPlanObject
		mov	ax, MSG_DP_DELETE_EVENT_BY_EVENT
		call	ObjCallInstanceNoLock
		pop	si
	;
	; Re-insert the modified event
	;
		call	SetEventUpdateNewEvent	; also reset UI
	;
	; Re-set the next alarm because inserting the alarm doesn't 
	;
RSP <		call	FindNextRTCMAlarm	; ds,es,ax,di destroyed	>

EC <		call	SetEventGetUniqueID	; cxdx = unique ID	>
EC <		cmpdw	cxdx, ss:[bp].DPMEP_eventID			>
EC <		ERROR_NE CALENDAR_MODIFY_EVENT_ERROR			>
		mov	cx, CEE_NORMAL
		jmp	noError	
		
error:
		mov_tr	cx, ax			; cx = CalendarEventError
	;
	; Delete the buffer
	;
noError:
		call	BufferDestroy		; flags preserved

done:
		Assert	CalendarEventError	cx
		.leave
		ret
DayPlanModifyEventByIDFromApi	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffApiInfoIntoEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract API info into the event

CALLED BY:	(INTERNAL) DayPlanCreateEventFromApi,
		DayPlanModifyEventByIDFromApi
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object
		dx:bp	= fptr to CalendarEventParamStruct
RETURN:		carry set if error
			ax	= CalendarEventError
		carry clear if no error
			ax	= CEE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Update start date time;
	Update event text;
	if (has start date) {
		Update reserved whole days;
		if (has end time || (no end time but has reserved days)) {
			Update end time;
			Update alarm;
		} else {
			/* this is same-day to-do item */
		}
	} else {
		/* this is to-do item */
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 2/97    	Initial version
	simon	3/ 7/97		Do not insert event nor return unique ID

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StuffApiInfoIntoEvent	proc	near
		uses	cx, dx, bp, es, di
		.enter
		Assert	optr	bxsi
		Assert	segment	ds
		Assert	fptrXIP	dxbp
	;
	; Set start date and time
	;
		movdw	esdi, dxbp		; es:di = params
		call	SetApiEventStartDateTime
	;
	; carry set if error, ax = CalendarEventError
	; Otherwise, cx = hour/min, dx = date and bp = year
	;
		jc	quit
	;
	; Set event text
	;
		call	SetApiEventText		; carry set if error,
		jc	quit			;   ax = CalendarEventError
	;
	; If this is a global to-do event, we don't need to set any other info.
	;
		cmp	es:[di].CEPS_startDateTime.FDAT_date, CAL_NO_DATE
		je	noError			; to-do item
	;
	; Set reserve whole day event
	;
		call	SetApiEventReserveWholeDay; carry set if error
		jc	quit			;   ax = CalendarEventError
	;
	; If this is a same day to-do item, start time is CAL_NO_TIME and
	; there is no reserved whole day. This event will not have end-time,
	; alarm repeat info. So, we just insert it.
	;
	; If this is a reserve whole day event, it can have no start time but
	; have end time.
	;
		cmp	es:[di].CEPS_startDateTime.FDAT_time, CAL_NO_TIME
		jne	insertEndDateTime	; same day to-do item

		tst	es:[di].CEPS_reserveWholeDay
		jz	noError			; same day to-do event!
	;
	; Set end time, if any
	;
insertEndDateTime::
if	END_TIMES
		call	SetApiEventEndDateTime	; carry set if error
		jc	quit			;   ax=CalendarEventError
endif
	;
	; Set alarm, if any
	;
		call	SetApiEventAlarm

noError:
		mov	ax, CEE_NORMAL
		clc				; no error

quit:
		Assert	CalendarEventErrorAndFlags	ax
		.leave
		ret
StuffApiInfoIntoEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetApiEventStartDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the start date and time from API to an event

CALLED BY:	(INTERNAL) StuffApiInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es:di	= fptr to CalendarEventParamStruct
RETURN:		if this is not to-do item:
		bp	= year
		dx	= month/day
		cx	= hour/minute
		carry set if error occurs (e.g. illegal date/time)
			ax	= CalendarEventError
				CEE_INVALID_DATE
				CEE_INVALID_TIME
				CEE_INVALID_TODO_ITEM_STATUS
DESTROYED:	if this is to-do item:
		cx, dx, bp destroyed.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 2/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetApiEventStartDateTime	proc	near
		.enter

		Assert	fptrXIP	esdi
		movdw	cxdx, es:[di].CEPS_startDateTime
	;
	; Make sure the CAL_NO_DATE is equal to TRUE
	;
		CheckHack <(CAL_NO_DATE eq TRUE) and (TRUE eq -1)>
		CheckHack <(CAL_NO_TIME eq TRUE) and (TRUE eq -1)>

		call	SetEventStartDateTime	; if this is not to-do item:
						; bp = year
						; dx = month/day
						; cx = hour/minute
						; carry set if error occurs
						; (e.g. illegal date/time)  
						; ax=CalendarEventError
		.leave
		ret
SetApiEventStartDateTime	endp

if	END_TIMES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetApiEventEndDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the end date and time from API to an event

CALLED BY:	(INTERNAL) StuffApiInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es:di	= fptr to CalendarEventParamStruct
RETURN:		carry set if error
			ax	= CalendarEventError
				CEE_INVALID_DATE
				CEE_INVALID_TIME
				CEE_START_TIME_LATER_THAN_END_TIME
				CEE_START_DATE_LATER_THAN_END_DATE
				CEE_MISSING_END_TIME_WHEN_START_TIME_AND_END_DATE_ARE_SET
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 2/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetApiEventEndDateTime	proc	near
		uses	cx, dx
		.enter

		Assert	fptrXIP	esdi
		movdw	cxdx, es:[di].CEPS_endDateTime
	;
	; If the event is reserve whole day, don't set end date.
	;
		tst	es:[di].CEPS_reserveWholeDay
		mov	ax, FALSE		; not always set time
		jz	setEndDateTime

		mov	dx, CAL_NO_DATE		; don't set date
		mov	al, TRUE		; always set the time

setEndDateTime:
		call	SetEventEndDateTime	; carry set if error
						; ax=CalendarEventError
		.leave
		ret
SetApiEventEndDateTime	endp
endif	; END_TIMES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetApiEventText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set event text from API to event

CALLED BY:	(INTERNAL) StuffApiInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es:di	= fptr to CalendarEventParamStruct
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
SetApiEventText	proc	near
		uses	dx, bp
		.enter

		Assert	fptrXIP	esdi
		movdw	dxbp, es:[di].CEPS_data
		call	SetEventText		; carry set if error
						;  ax = CalendarEventError
		.leave
		ret
SetApiEventText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetApiEventReserveWholeDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the reserve whole day of the event

CALLED BY:	(INTERNAL) StuffApiInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es:di	= fptr to CalendarEventParamStruct
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
SetApiEventReserveWholeDay	proc	near
		uses	cx
		.enter
		Assert	fptrXIP	esdi

		mov	cx, es:[di].CEPS_reserveWholeDay
		call	SetEventReserveWholeDay	; carry set if error
						; ax = CalendarEventError
		.leave
		ret
SetApiEventReserveWholeDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetApiEventAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the event alarm

CALLED BY:	(INTERNAL) StuffApiInfoIntoEvent
PASS:		^lbx:si	= DayEventClass object
		ds	= segment of DayPlan object (for FIXUP)
		es:di	= fptr to CalendarEventParamStruct
		bp	= year
		dx	= month/date
		cx	= hour/minute or CAL_NO_TIME if use default time 
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 3/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetApiEventAlarm	proc	near
		uses	ax
		.enter
		Assert	fptrXIP	esdi

		CheckHack <CAL_NO_TIME eq TRUE>
		mov	ax, es:[di].CEPS_alarm
		call	SetEventAlarm

		.leave
		ret
SetApiEventAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanDeleteEventByIDFromApi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an event by unique event ID from Calendar API

CALLED BY:	MSG_DP_DELETE_EVENT_BY_ID_FROM_API
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
                ds:bx   = DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		cxdx	= event ID
RETURN:		if event found and deleted:
			cx	= CEE_NORMAL
		otherwise,
			cx	= CalendarEventError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (event ID not found) {
		return CEE_EVENT_NOT_FOUND;
	}
	if (event current selected) {
		return CEE_ACCESS_DENIED;
	}
	Delete event via MSG_DP_DELETE_EVENT_BY_EVENT;
	Reset UI;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/20/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanDeleteEventByIDFromApi	method dynamic DayPlanClass, 
					MSG_DP_DELETE_EVENT_BY_ID_FROM_API
		uses	ax, dx, bp
		.enter
		Assert	eventID	cxdx
	;
	; Is the event in the database?
	;
		pushdw	cxdx
		call	DBSearchEventIDArray	; carry set if event found
						;   ax:di = Gr:It of event
						;   cxdx = element index
						; es destroyed
		popdw	cxdx			; cxdx = event ID
		jnc	eventNotFound
	;
	; If DayPlanObject has focus on the event (being deleted), return
	; access denied error. This seems to be the easiest way to avoid many
	; synchronization errors. If we have more time, we can implement a
	; better synchronization scheme.
	;
		call	DayPlanIsEventByIDSelected
		mov	cx, CEE_ACCESS_DENIED	; carry if event has focus
		jc	done
	;
	; Delete event from database
	;
		mov_tr	cx, ax
		mov	dx, di			; cx:dx = Gr:It of event
		mov	ax, MSG_DP_DELETE_EVENT_BY_EVENT
		call	ObjCallInstanceNoLock
	;
	; Reset DayPlanObject UI to reflect the deletion
	;
		mov	si, offset DayPlanObject
RSP <		mov	ax, MSG_DP_RESPONDER_RESET_UI			>
NRSP <		mov	ax, MSG_DP_RESET_UI				>
		call	ObjCallInstanceNoLock

		mov	cx, CEE_NORMAL		; return no error

done:
		Assert	CalendarEventError	cx
		.leave
		ret

eventNotFound:
		mov	cx, CEE_EVENT_NOT_FOUND
		jmp	done
DayPlanDeleteEventByIDFromApi	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanDeleteEventByEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an event by event DB group:item without bringing up
		additional UI

CALLED BY:	MSG_DP_DELETE_EVENT_BY_EVENT
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
                ds:bx   = DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		cx:dx	= DB group:item to delete (The event must exist)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (event is not repeat event) {
RSP <		Delete memo token from array;				>
		Delete event from database via MSG_CALENDAR_DELETE_EVENT
	} else {
RSP <		Delete memo token from array;				>
		Delete repeat event vai RepeatDelete;
	}
	Find and set the next RTCM alarm;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/24/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanDeleteEventByEvent	method dynamic DayPlanClass, 
					MSG_DP_DELETE_EVENT_BY_EVENT
		uses	ax, cx, dx, bp
		.enter
	;
	; Check if event is repeat event
	;
		movdw	axdi, cxdx		; ax:di = Gr:It
		IsEventRepeatEvent	cx	; ZF set if repeat event
		jz	repeatEvent
	;---------------------------------
	; Delete a normal event
	;---------------------------------
	;
	; Delete memo token first
	;
RSP <		push	dx						>
RSP <		call	GP_DBLockDerefDI	; es:di = EventStruct	>
RSP <		mov	dx, es:[di].ES_memoToken; dx = memo token	>
RSP <		call	DBUnlock		; es destroyed		>
RSP <		call	DeleteEventMemoFar				>
RSP <		pop	dx			; cx:dx = Gr:It		>
	;
	; Delete the event given Group:Item of EventStruct
	;
		call	GeodeGetProcessHandle	; bx = process handle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_CALENDAR_DELETE_EVENT
		call	ObjMessage		; ax,cx,dx,bp destroyed
		jmp	done
	;---------------------------------
	; Delete a repeat event
	;---------------------------------
repeatEvent:
		call	GP_DBLockDerefDI	; es:di = RepeatStruct
		mov	cx, es:[di].RES_ID	; cx = repeat ID
RSP <		mov	dx, es:[di].RES_memoToken;dx = memo token	>
		call	DBUnlock		; es destroyed		
	;
	; Delete memo token
	;
RSP <		call	DeleteEventMemoFar				>
	;
	; Delete Repeat event
	;
		GetResourceSegmentNS	dgroup, ds
		call	RepeatDelete		; ax,bx,cx,dx,di,si,bp,es gone
done:		
	;
	; Alarm may have changed. Schedule the next RTCM event.
	;
		call	FindNextRTCMAlarm	; ax,ds,es,di destroyed

		.leave
		ret
DayPlanDeleteEventByEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanGetEventByIDFromApi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an event by unique event ID from Calendar API

CALLED BY:	MSG_DP_GET_EVENT_BY_ID_FROM_API
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
                ds:bx   = DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		cxdx	= event ID
		^hbp	= owner of the returned block
RETURN:		if event found
			cx	= CEE_NORMAL
			^hdx	= Unlocked block of CalendarReturnedEventStruct
		Otherwise,
			cx	= CalendarEventError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get event from event ID array;
	if (event not found) {
		return CEE_EVENT_NOT_FOUND;
	}
	if (event == repeat event) {
		return CEE_EVENT_NOT_SUPPORTED;
	}
	Stuff data into block to return;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/25/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanGetEventByIDFromApi	method dynamic DayPlanClass, 
					MSG_DP_GET_EVENT_BY_ID_FROM_API
		uses	ax
		.enter
	;
	; Is the event in the database?
	;
		call	DBSearchEventIDArray	; carry set if event found
						;   ax:di = Gr:It of event
						;   cxdx = element index
						; es destroyed
		mov	cx, CEE_EVENT_NOT_FOUND
		jnc	done
	;
	; Check if event is a repeat event. Currently, we do not support any
	; repeat event.
	;
		IsEventRepeatEvent	ax	; ZF set if repeat event
		mov	cx, CEE_EVENT_NOT_SUPPORTED
		jz	done
	;
	; Get the event
	;
		call	DayPlanGetNormalEvent	; cx = CalendarEventError
						; if no err, ^hdx = data block 
						; ds,es destroyed
EC <		cmp	cx, CEE_NORMAL					>
EC <		jne	done						>
EC <		Assert_handle	dx					>

done:
		Assert	CalendarEventError	cx
		.leave
		ret
DayPlanGetEventByIDFromApi	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanGetNormalEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get normal event data 

CALLED BY:	(INTERNAL) DayPlanGetEventByIDFromApi
PASS:		ax:di	= DB group:item
		^hbp	= owner of the returned block
RETURN:		if there is no error,
			cx	= CEE_NORMAL
		if there is error,
			cx	= CalendarEventError
			^hdx	= CalendarReturnedEventStruct
DESTROYED:	ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Lock event data;
	Find out total size of event data;
	Allocate memory block;
	if (no more memory) {
		return CEE_NOT_ENOUGH_MEMORY;
	} else {
		Fill the memory with event data;
		Unlock memory block;
	}
	Unlock event data;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/27/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanGetNormalEvent	proc	near
		uses	ax, bx, si, di
		.enter
		Assert	handle	bp
	;
	; Figure out the size of returned data
	;
		call	GP_DBLockDerefDI	; es:di = EventStruct
		mov	ax, es:[di].ES_dataLength; ax = text length in bytes
		inc	ax			; add one for NULL char
DBCS <		inc	ax			; add one for DBCS	>
		add	ax, size CalendarReturnedEventStruct
						; ax = size of return data blk
	;
	; Allocate block for returned data
	;
		mov	bx, bp			; bx = owner
		mov	cx, ALLOC_STATIC_LOCK
		call	MemAllocSetOwner	; carry set if no memory
						; otherwise, ^hbx = block
						;   ax = sptr of block
						;   cx destroyed
		mov	cx, CEE_NOT_ENOUGH_MEMORY
		jc	done
	;
	; Stuff the event data
	;
		mov	ds, ax			; ds:si =
		clr	si			; CalendarReturnedEventStruct
		call	DayPlanGetNormalEventData
	;
	; Unlock source and destination blocks
	;
		mov	dx, bx			; ^hdx = returned block
		mov	cx, CEE_NORMAL		; success!
		call	MemUnlock		; ds destroyed

done:
		call	DBUnlock		; es destroyed
		.leave
		ret
DayPlanGetNormalEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanGetNormalEventData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy data from normal event EventStrct to
		CalendarReturnedEventStruct

CALLED BY:	(INTERNAL) DayPlanGetNormalEvent
PASS:		ds:si	= CalendarReturnedEventStruct
		es:di	= EventStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
	CalendarReturnedEventStruct will be updated with event data from
	EventStruct. 

PSEUDO CODE/STRATEGY:
	Fill in misc info of returned block;
	if (event is to-do event) {
		Get to-do event info;
	} else {
		Get start date;
		if (event has start time) {
			Get start time;
			if (event has alarm) {
				Get alarm;
				Fill in alarm info;
			}
		}
		Set start date and time or to-do info;
	}
	Get end date and end time;
	Set end date and end time;
	Copy event text;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/25/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanGetNormalEventData	proc	near
		uses	ax, bx, cx, dx, bp, ds, si, es, di
		.enter
		Assert	fptr	dssi
		Assert	fptr	esdi
	;
	; Fill in misc information first
	;
		movdw	ds:[si].CRES_eventID, es:[di].ES_uniqueID, ax
RSP <		movm	ds:[si].CRES_reserveWholeDay, \
			es:[di].ES_reservedDays, ax			>
		mov	ds:[si].CRES_eventType, CEDT_GEOS_TEXT
						; only Text is calendar data
		clr	ds:[si].CRES_repeatInfo	; no repeat info
		movm	ds:[si].CRES_dataLength, es:[di].ES_dataLength, ax
		clr	ds:[si].CRES_alarm	; default is no alarm
	;
	; Data is retrieved in a different way for To-do items.
	;
		test	es:[di].ES_flags, mask EIF_TODO
		jz	getStartTime		; to-do event?

		call	DayPlanGetNormalEventDataSetTodo
						; cx = CalendarToDoItemStatus
						; dx = CAL_NO_DATE
		jmp	setStartTime		; don't care about alarm
	;
	; Fill out start date and time info. There must be a start date for
	; non to-do event.
	;
getStartTime:
		mov	bp, es:[di].ES_timeYear	; bp = year
		mov	dh, es:[di].ES_timeMonth; dh = month
		mov	dl, es:[di].ES_timeDay	; dl = day
	;
	; Fill out start time info. If there is no start time, don't get it
	; from EventStruct and don't set
	;
		mov	cx, CAL_NO_TIME		; default is no start time
		test	es:[di].ES_varFlags, VL_START_TIME
		jz	convertStartTime
		mov	ch, es:[di].ES_timeHour	; ch = hourn
		mov	cl, es:[di].ES_timeMinute; cl = min
	;
	; Return alarm info
	;
checkAlarm::
		test	es:[di].ES_flags, mask EIF_ALARM_ON
		jz	convertStartTime

		push	di		
		mov	ah, es:[di].ES_alarmMonth
		mov	al, es:[di].ES_alarmDay	; ax = alarm month/day
		mov	bh, es:[di].ES_alarmHour
		mov	bl, es:[di].ES_alarmMinute
						; bx = alarm hour/min
		mov	di, es:[di].ES_alarmYear; di = alarm year
		call	AlarmToCalendarAlarmStruct
		mov	ds:[si].CRES_alarm, ax	; ax = CalendarAlarmStruct
		pop	di

convertStartTime:
		call	DateTimeToFileDateAndTime; dx = FileDate or CAL_NO_DATE
						; cx = FileTime or CAL_NO_TIME

setStartTime:
		movdw	ds:[si].CRES_startDateTime, cxdx
	;
	; Fill out end date and time info. 
	;
		mov	dx, CAL_NO_DATE		; default is no date
RSP <		test	es:[di].ES_varFlags, VL_END_DATE		>
RSP <		jz	getEndTime					>
RSP <		mov	bp, es:[di].ES_endYear	; bp = end year		>
RSP <		mov	dh, es:[di].ES_endMonth	; dh = end month	>
RSP <		mov	dl, es:[di].ES_endDay	; dl = end day		>
RSP < getEndTime:							>

		mov	cx, CAL_NO_TIME		; default is no end time
if	END_TIMES
		test	es:[di].ES_varFlags, VL_END_TIME
		jz	setEndTime
		mov	ch, es:[di].ES_endTimeHour
		mov	cl, es:[di].ES_endTimeMinute
						; ch = end hour, cl = end min
endif   ; END_TIMES

setEndTime:
		call	DateTimeToFileDateAndTime; dx = FileDate or CAL_NO_DATE
						; cx = FileTime or CAL_NO_TIME
		movdw	ds:[si].CRES_endDateTime, cxdx
	;
	; Copy calendar event data (text)
	;
		mov	bx, offset ES_data
		mov	bp, offset CRES_data
		call	DayPlanCopyEventString

		.leave
		ret
DayPlanGetNormalEventData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanGetNormalEventDataSetTodo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return to-do event info from an event 

CALLED BY:	(INTERNAL) DayPlanGetNormalEventData
PASS:		ss:bp	= inherited stack of DayPlanGetNormalEventData
		es:di	= EventStruct
RETURN:		cx	= CalendarToDoItemStatus
		dx	= CAL_NO_DATE
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 4/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanGetNormalEventDataSetTodo	proc	near
		.enter	inherit	DayPlanGetNormalEventData
		Assert	fptr	esdi
	;
	; This is to-do item, specially return the item priorty in start
	; time. We need to convert the to-do item priority to
	; CalendarToDoItemStatus. Since CalendarToDoItemStatus is a word-size
	; enum, and priority in EventStruct is byte size, we need to get a
	; mask for the high byte of CalendarToDoItemStatus
	;
		CheckHack <(first CalendarToDoItemStatus eq \
			CTDIS_HIGH_PRIORITY)>
		CheckHack <(size CalendarToDoItemStatus) eq (size word)>
		CheckHack <(TODO_HIGH_PRIORITY lt TODO_NORMAL_PRIORITY) and \
			(TODO_NORMAL_PRIORITY lt TODO_COMPLETED)>
		CheckHack <(TODO_HIGH_PRIORITY eq \
			((CTDIS_HIGH_PRIORITY and 0xff00) shr 8))>
		mov	ch, (CTDIS_HIGH_PRIORITY - TODO_HIGH_PRIORITY) shr 8
	;
	; If the event is completed, we return status COMPLETED rather than
	; the priority
	;
		mov	cl, TODO_COMPLETED
		cmp	es:[di].ES_alarmMinute, cl
		je	setTodoEventDate
		mov	cl, es:[di].ES_timeMinute; cx = CalendarToDoItemStatus

setTodoEventDate:
		mov	dx, CAL_NO_DATE		; no date for to-do item

		Assert	etype	cx, CalendarToDoItemStatus
		Assert	e	dx, CAL_NO_DATE
		.leave
		ret
DayPlanGetNormalEventDataSetTodo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCheckIfEventExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check there exists any event within a period of time

CALLED BY:	MSG_DP_CHECK_IF_EVENT_EXISTS
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
                ds:bx   = DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		ss:bp	= DayPlanCheckEventExistParams
RETURN:		nothing
DESTROYED:	if there is error,
			cx	= CalendarEventError
		if there is event overlapping the search range, 
			cx	= CEE_NORMAL
		if there is no event overlapping the search range,
			cx	= CEE_EVENT_NOT_FOUND
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Allocate memory to pass argument;
	if (no memory to allocate space to pass argument) {
		return CEE_NOT_ENOUGH_MEMORY;
	}
	if (start date and time format invalid) {
		return error;
	}
	Copy start date and time info to argument;
	if (end date and time format invalid) {
		return error;
	}
	Copy end date and time info to argument;
	if (end date/time < start date/time) {
		return error;
	}
	Set up callback to check on multiple day events;
	if (found) {
		Clean up arguments;
		return;
	}
	Set up callback to check on nomrla events;
	Clean up arguments;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 8/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanCheckIfEventExists	method dynamic DayPlanClass, 
					MSG_DP_CHECK_IF_EVENT_EXISTS
		uses	ax, dx, bp
		.enter
	;
	; Allocate space to pass argument
	;
		mov	ax, size EventEnumParamStruct
		mov	cx, ALLOC_STATIC_LOCK
		call	MemAlloc		; ax = sptr, ^hbx = handle
		mov	cx, CEE_NOT_ENOUGH_MEMORY
		jc	done			; carry set if error

		mov	ds, ax
		clr	si			; ds:si = EventEnumParamStruct
	;
	; Verify the start dates and times are correct
	;
		mov	di, bp			; save bp
		movdw	cxdx, ss:[bp].DPCEEP_startDateTime
		call	SetEventGetDateTime	; bp=yr, 
						; cx=hour/min, dx=month/day,
						; ax=CalendarEventError
		xchg	di, bp			; di = yr, stack restored
		jc	cleanup			; carry set if error

		CheckHack <(offset RS_startDay)+1 eq (offset RS_startMonth)>
		CheckHack <(offset DTRS_startMin)+1 eq (offset DTRS_startHour)>
		mov	ds:[si].EEPS_range.DTRS_dateRange.RS_startYear, di
		mov	{word} ds:[si].EEPS_range.DTRS_dateRange.RS_startDay, \
			dx			; assign both month and day
		mov	{word} ds:[si].EEPS_range.DTRS_startMin, cx
						; assign both hour and min
	;
	; Verify the end date and time are correct
	;
		mov	di, bp			; save bp
		movdw	cxdx, ss:[bp].DPCEEP_endDateTime
		call	SetEventGetDateTime	; bp=yr, 
						; cx=hour/min, dx=month/day,
						; ax=CalendarEventError
		xchg	di, bp			; di = year, stack restored
		jc	cleanup			; carry set if error

		CheckHack <(offset RS_endDay)+1 eq (offset RS_endMonth)>
		CheckHack <(offset DTRS_endMin)+1 eq (offset DTRS_endHour)>
		mov	ds:[si].EEPS_range.DTRS_dateRange.RS_endYear, di
		mov	{word} ds:[si].EEPS_range.DTRS_dateRange.RS_endDay, dx
						; assign both month and day
		mov	{word} ds:[si].EEPS_range.DTRS_endMin, cx
						; assign both hour and min
	;
	; Verify that the end date and time is equal to or later than start
	; date and start time.
	;
		push	si
		add	si, offset EEPS_range	; ds:si = DateTimeRangeStruct
		call	CalendarVerifyEndDateTimeNotEarlier
		pop	si			; carry set if end time earlier
		mov	ax, CEE_INVALID_TIME_RANGE
		jc	cleanup	
	;
	; Set the callback message and object
	;
NRSP <		GetResourceHandleNS	DayPlanObject, ax		>
NRSP <		mov	ds:[si].EEPS_callbackObj, ax			>
RSP <		mov	ds:[si].EEPS_callbackObj.handle, handle DayPlanObject>
		mov	ds:[si].EEPS_callbackObj.offset, offset DayPlanObject
	;
	; Enumerate the date and time range over multiple day events
	;
		mov	ds:[si].EEPS_callbackMsg, \
			MSG_DP_CHECK_IF_MULTIPLE_DAY_EVENT_EXISTS_CALLBACK
		call	CalendarEnumMultipleDayEvents
						; ax = CalendarEventError
		jnc	checkNormalEvents	; carry clear if no event enum

		cmp	ax, CEE_EVENT_NOT_FOUND	; if event found or there are
		jne	cleanup			;   are other errors, return
	;
	; Enumerate the date and time range over normal events
	;
checkNormalEvents:
		mov	ds:[si].EEPS_callbackMsg, \
			MSG_DP_CHECK_IF_NORMAL_EVENT_EXISTS_CALLBACK
		call	CalendarEnumNormalEvents; carry clear if no event enum
						; ax = CalendarEventError
		jc	cleanup
		mov	ax, CEE_EVENT_NOT_FOUND
	;
	; Enumerate the date and time range over repeat events (to be
	; implemented) 
	;
	;		call	CalendarEnumRepeatEvents

cleanup:
		mov_tr	cx, ax			; cx = CalendarEventError
		call	MemFree			; bx destroyed

done:
		Assert	CalendarEventError	cx
		.leave
		ret
DayPlanCheckIfEventExists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarEnumMultipleDayEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all multiple day events and call the callback
		message 

CALLED BY:	(INTERNAL) DayPlanCheckIfEventExists
PASS:		ds:si	= EventEnumParamStruct
		cx, dx, bp
			= passed to enumerated callback

		=======================================================
		The format of the callback message in EventEnumParamStruct:

		PASS:	cx, dx, bp
				= values to callback
		RETURN:	ax	= CalendarEventError
			cx, dx	= values returned from callback
			if carry set,
				abort enumeration
			if carry clear,
				continue enumeration
		=======================================================

RETURN:		carry clear if no events enumerated
		carry set otherwise,
			ax	= CalendarEventError returned by last
				callback message
			cx, dx	= other values returned by last callback
				message 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	** WARNING **

	The callback message will be called. So, it should not create any
	deadlock problems.

	anyEvent = FALSE;
	Lock down the multiple day event table;
	for (event = first entry in table; event count <= #events;
	     event = next event) {
		if (event's group:item is non-zero) {
			/* event valid */
			anyEvent = TRUE;
			call callback on this event;
		}
	}
	Unlock multiple day event able;
	Return callback results if any;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 8/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarEnumMultipleDayEvents	proc	near
	argBP		local	word	push	bp
	argCX		local	word	push	cx
	argDX		local	word	push	dx
	returnAX	local	word		; ax to return
	returnCX	local	word		; cx to return
	returnDX	local	word		; dx to return
	anyEvent	local	byte		; TRUE if there is multi-day
						; event 
		ForceRef	argBP
		ForceRef	argCX
		ForceRef	argDX
		uses	bx, di
		.enter
		Assert	fptr	dssi	

		mov	ss:[anyEvent], FALSE	; default is no event enum
	;
	; Lock down the multiple day event array and access the elements
	;
		call	MultipleDayTableLockFar	; *es:di=MultipleDayTableHeader
						; ax:di =Gr:It of header
		mov	di, es:[di]		; es:di =MultipleDayTableHeader
		mov	ax, es:[di].MDTH_totalSize
		sub	ax, offset MDTH_data	; ax = size of all entries
		mov	cx, es:[di].MDTH_validCount
		jcxz	return			; return if no multi-day event
		add	di, offset MDTH_data	; es:di = 1st
						; MultipleDayTableEntry 
	;
	; Loop through the whole multiple day array and call the callback
	; function on each one.
	;
	; Not all MultipleDayTableEntry's are valid. Some are on free list
	; and thus empty and should be skipped.
	;
findLoop:
		tstdw	es:[di].MDTE_groupItem	; entry valid?
		jz	next			; not valid, next...
	;
	; Call the callback message, if any. If none, return immediately. 
	;
		mov	ss:[anyEvent], TRUE	; found a match
		push	ax
		movdw	axbx, es:[di].MDTE_groupItem
		call	CalendarEnumCommonEventsCallback
		pop	ax
		jc	return			; carry set if abort enum

checkValidCount::
		dec	cx			; update remaining elem count
		jcxz	return			; abort if no more elements
	;
	; Go to next element
	;
next:
		add	di, size MultipleDayTableEntry
						; es:di = next entry
		sub	ax, size MultipleDayTableEntry
						; ax = remaining sz of entries
		jnz	findLoop		; end of all entries?
	;
	; Done with everything. Unlock multiple day event array and return
	; result.
	;
return:
		call	DBUnlock		; unlock multi-day table.
						; flags preserved. es destroyed
		tst_clc	ss:[anyEvent]		; carry clear
		jz	done
		stc				; has enumerated events...
	;
	; Return arguments from callback message
	;
		mov	ax, ss:[returnAX]
		mov	cx, ss:[returnCX]
		mov	dx, ss:[returnDX]
		Assert	CalendarEventError	ax

done:
		.leave
		ret
CalendarEnumMultipleDayEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCheckIfMultipleDayEventExistsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to see if a multiple day event coincides with a
		period of time 

CALLED BY:	MSG_DP_CHECK_IF_MULTIPLE_DAY_EVENT_EXISTS_CALLBACK (via
		CalendarEnumMultipleDayEvents)
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
                ds:bx   = DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		ss:bp	= DayPlanEnumDateTimeRangeParams
		dx	= size of DayPlanEnumDateTimeRangeParams
RETURN:		carry set if the multiple event exists over the given
		period of time, and should abort enumeration of multiple day
		events
			ax	= CEE_NORMAL
		otherwise,
			ax	= CEE_EVENT_NOT_FOUND
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Lock down current event's DB group:item;
	Check if event overlaps with query period;
	if (not overlapping) {
		result = CEE_EVENT_NOT_FOUND;
	}
	if (event is reserve whole day event) {
		result = Check if reserve day event overlaps with query period;
	} else {
		result = CEE_NORMAL;
	}
	Unlock current event's DB group:item;
	Return result;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 8/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanCheckIfMultipleDayEventExistsCallback	method dynamic DayPlanClass, 
			MSG_DP_CHECK_IF_MULTIPLE_DAY_EVENT_EXISTS_CALLBACK
		uses	cx, dx, bp
		.enter
	;
	; Lock down the DB item
	;
		movdw	dssi, ss:[bp].DPEDTRP_dateTimePtr
		Assert	fptr	dssi
		mov	ax, ss:[bp].DPEDTRP_eventGr
		mov	di, ss:[bp].DPEDTRP_eventIt

		call	GP_DBLockDerefDI	; es:di = EventStruct
		Assert	eventID	es:[di].ES_uniqueID
EC <		test	es:[di].ES_flags, mask EIF_REPEAT		>
EC <		ERROR_NZ CALENDAR_ENUM_MULTIPLE_DAY_EVENT_ERROR		>
						; no repeat event!
	;
	; Prepare arguments to compare the range of event and query
	; period. 
	;
		sub	sp, size DateTimeRangeStruct
		mov	bp, sp			; ss:bp = DateTimeRangeStruct
		call	DayPlanCheckIfEventExistsCommon
						; DateTimeRangeStruct filled
		jnc	noMatch			; carry set if overlap
	;
	; We have a match over time period. However, if this is a reserve
	; whole day event, we have to specially check each day since the
	; reserve whole day event does not necessarily span full
	; days. Reserve whole day events are just like daily repeat events.
	;
		test	es:[di].ES_varFlags, VL_WHOLE_DAY_RES
		stc				; default is not reserve day
		jz	match

		push	es
		movdw	esdi, ssbp, ax		; es:di = DateTimeRangeStruct
		call	CalendarDoesReserveDayEventExist
						; carry set if event exists
						; ax destroyed
		pop	es			; es = EventStruct segment
		jc	match

noMatch:
		mov	cx, CEE_EVENT_NOT_FOUND
		jmp	cleanup
		
match:
		mov	cx, CEE_NORMAL
		
cleanup:
		lahf
		add	sp, size DateTimeRangeStruct
		sahf				; stack restored
		call	DBUnlock		; es destroyed
						; flags preserved

		mov_tr	ax, cx			; ax = CalendarEventError

		Assert	CalendarEventError	ax
		.leave
		ret
DayPlanCheckIfMultipleDayEventExistsCallback	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarEnumNormalEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate normal events (single day and non-repeating)
		within a date range and call the callback.

CALLED BY:	(INTERNAL) DayPlanCheckIfEventExists
PASS:		ds:si	= EventEnumParamStruct
		cx, dx, bp
			= passed to enumerated callback

		=============================================
		The format of the callback message:

		PASS:	cx, dx, bp
				= values to callback
		RETURN:	ax	= CalendarEventError
			cx, dx	= values returned from callback
			if carry set,
				abort enumeration
			if carry clear,
				continue enumeration
		=============================================

RETURN:		carry clear if no events enumerated
		carry set otherwise,
			ax	= CalendarEventError returned by last
				callback message
			cx, dx	= other values returned by last callback
				message 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Set up initial year, month and day to start with;
	do {
		if (current year != end year) {
			Use Dec 31 as temp end date to find out which date to
			scan to; 
		} else {
			Use query period's end date to find out which date to
			scan to; 
		}
		Get the offset to which date to scan to in the year map;
		Get current year's year map table;
		if (year map table exists) {
			Lock down the year map;
			Get start date offset in year map table;
			while (not the end of date search for this yr) {
				eventDay = Scan for the next day for non-zero
					entry; 
				Enumerate events on eventDay;
				if (event found) {
					Unlock year map;
					break;
				}
			}
			Unlock year map;
		}
	} (;current year != search end year; current year++, start date=Jan_1)
	Return results;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/13/97    	Initial version: Core code borrowed
					from GetRangeOfEvents

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarEnumNormalEvents	proc	near
	argBP		local	word	push	bp
	argCX		local	word	push	cx
	argDX		local	word	push	dx
	returnAX	local	word		; ax to return
	returnCX	local	word		; cx to return
	returnDX	local	word		; dx to return
	enumParamOffset	local	nptr		; nptr to EventEnumParamStruct
	curEnumYear	local	word		; current year enumerating
	curEnumMonth	local	byte		; current month enumerating
	curEnumDay	local	byte		; current day enumerating
	anyEvent	local	byte		; TRUE if there is multi-day
						; event 
		ForceRef	argBP
		ForceRef	argCX
		ForceRef	argDX
		uses	bx, es, di, si
		.enter
		Assert	fptr	dssi

		mov	ss:[enumParamOffset], si
		mov	ss:[anyEvent], FALSE
	;
	; Search the year map structures to check out the days that have
	; events in the query range. Set up the initial variables.
	;
		movm	ss:[curEnumMonth], \
			ds:[si].EEPS_range.DTRS_dateRange.RS_startMonth, al
		movm	ss:[curEnumDay], \
			ds:[si].EEPS_range.DTRS_dateRange.RS_startDay, al
		mov	ax, ds:[si].EEPS_range.DTRS_dateRange.RS_startYear
		mov	ss:[curEnumYear], ax	; ax = start year
	;
	; If the currently enumerated year is earlier than the end year, the
	; end day becomes the last day of the year. We want to find out the
	; last day so that we know when to stop enumerating events of the
	; currently enumerated year.
	;
yearLoop:
		Assert	urange	ax, FILE_BASE_YEAR, 9999
		cmp	ax, ds:[si].EEPS_range.DTRS_dateRange.RS_endYear
		je	enumLastYear		; jmp enumerating last year
		mov	dx, DEC_31		; use last day of year
		jmp	getTableSize

enumLastYear:
		mov	dh, ds:[si].EEPS_range.DTRS_dateRange.RS_endMonth
		mov	dl, ds:[si].EEPS_range.DTRS_dateRange.RS_endDay
						; dx = end month/day 
getTableSize:
		call	DateToTablePos		; bx = end offset in year map
		mov	cx, bx			; cx = end offset in year map
	;
	; Go to the first day of this series of events 
	;
		push	bp
		mov_tr	bp, ax			; bp = current year to search
		call	DBSearchYearFar		; ax:di = Gr:It of map block
						; si = offset to yr map blk
		pop	bp

		tst	di			; any event found?
		jz	nextYear		; jmp if nothing found
	;
	; Find the offset of the first day to search in year map and get the
	; year map.
	;
		mov	dh, ss:[curEnumMonth]
		mov	dl, ss:[curEnumDay]
		call	DateToTablePos		; bx = start day offset
		call	GP_DBLock		; *es:di = Year Map
		mov	si, di			; *es:si = Year Map
		mov	dx, cx			; dx = end offset in year map
		jmp	midLoop			; start looping the days
	;
	; We've found a real day - now enumerate the events
	;
dayLoop:
		mov	di, es:[di]		; item # for EventMap => DI
EC <		tst	di			; EventMap here ??	>
EC <		ERROR_Z	GET_RANGE_OF_EVENTS_BAD_YEARMAP_ITEM		>
		call	CalendarEnumNormalEventsInDay
		jc	foundEvent		; if carry set, exit
		inc	bx
		inc	bx			; go to the next day
	;
	; Starting from the start day, look for the first day that has
	; events. If the day has event, the entry in year map will be
	; non-zero.
	;
midLoop:
		mov	di, es:[si]		; es:di = Year Map
		add	di, bx			; es:di = map entry of this day
		mov	cx, YearMapSize		
		sub	cx, bx
		shr	cx			; cx = # of days to scan
		push	ax			; save event map group
		clr	ax			; ax = value of day w/o event
		repz	scasw			; look for non-zero value
		pop	ax			; ax = event map DB group
		jz	calcOffset		; if off array, don't back up
		dec	di
		dec	di			; account for over-scan

calcOffset:
		mov	bx, di			; bx = current position
		sub	bx, es:[si]		; bx = new offset
		cmp	bx, dx			; compare current w/ end offset
		jbe	dayLoop			; loop again (else carry clear)
	;
	; Unlock this year's map block
	;
		call	DBUnlock		; es destroyed
	;
	; Check if we have reached the last year. If so, exit
	;
nextYear:
		mov_tr	ax, ss:[curEnumYear]	; ax = currently enum year
		mov	si, ss:[enumParamOffset]; ds:si = EventEnumParamStruct
		cmp	ax, ds:[si].EEPS_range.DTRS_dateRange.RS_endYear
		je	exit
	;
	; Search the next year. Set the start date to be first day of next
	; year.
	;
		inc	ax			; ax = next year
		mov	ss:[curEnumYear], ax
		mov	ss:[curEnumMonth], (JAN_1 shr 8)
		mov	ss:[curEnumDay], (JAN_1 and 11111111b)
		jmp	yearLoop

foundEvent:
		call	DBUnlock		; es destroyed
	;
	; Is there any event enumerated at all? If so, return values
	; in registers.
	;
exit:
		tst_clc	ss:[anyEvent]		; carry clear
		jz	done

		mov	ax, ss:[returnAX]
		mov	cx, ss:[returnCX]
		mov	dx, ss:[returnDX]
		stc				; event enumerated

done:
		.leave
		ret
CalendarEnumNormalEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarEnumNormalEventsInDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate normal events (single day and non-repeating)
		in a given day and call the callback.

CALLED BY:	(INTERNAL) CalendarEnumNormalEvents
PASS:		ss:bp	= inherited stack of CalendarEnumNormalEvents
		ds	= segment of EventEnumParamStruct
		es	= segment to preserve
		ax:di	= DB Group:Item of EventMap of a day
RETURN:		Returned values from callback message that aborts enumeration
			ss:[returnAX]	= ax from callback
			ss:[returnCX]	= cx from callback
			ss:[returnDX]	= dx from callback
			carry
		if carry set,
			abort enumeration as indicated by the callback
		if carry clear,
			enumeration should continue
			
DESTROYED:	nothing
SIDE EFFECTS:	
	** Warning **

	There is pre-condition that this day must have events.

PSEUDO CODE/STRATEGY:
	Lock down EventMapHeader;
	for (event = 1st EventMapStruct;
	     event# <= # of events in EventMapHeader;
	     event = next EventMapStruct) {
		if (event in EventMapStruct has start time and no end date) {
			Call callback on this event;
		}
	}
	Unlock EventMapHeader;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/14/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarEnumNormalEventsInDay	proc	near
		uses	ax, bx, cx, dx, si, es, di
		.enter inherit CalendarEnumNormalEvents
		Assert	segment	ds
	;
	; Get initial variables first
	;
		call	GP_DBLockDerefDI	; es:di = EventMapHeader
		mov	cx, es:[di].EMH_numEvents
EC <		tst	cx						>
EC <		ERROR_Z CALENDAR_CORRUPTED_EVENT_MAP_HEADER		>
		mov	si, ss:[enumParamOffset]; ds:si = EventEnumParamStruct
		add	di, size EventMapHeader	; es:di = 1st EventMapStruct
	;
	; Process each event that starts today
	;
dayLoop:
		push	es, di
		mov	di, es:[di].EMS_event	; ax:di = DB Gr:It of cur event
		mov	bx, di			; bx = current DB Item
		call	GP_DBLockDerefDI	; es:di = EventStruct
	;
	; Skip this event if it is a multiple day event or event without
	; start time
	;
		Assert	eventID	es:[di].ES_uniqueID
EC <		test	es:[di].ES_flags, mask EIF_REPEAT or mask EIF_TODO>
EC <		ERROR_NZ CALENDAR_ENUM_NORMAL_EVENT_ERROR		>
						; cannot be to-do or repeat
		mov	dh, es:[di].ES_varFlags	; dh = VariableLengthFlags
		call	DBUnlock		; es destroyed (flags saved)
		pop	es, di			; es:di = EventMapStruct

		test	dh, VL_END_DATE		; skip multiple day event
		jnz	next

		test	dh, VL_START_TIME	; skip event w/o start time
		jz	next
	;
	; Call the callback
	;
		mov	ss:[anyEvent], TRUE
		call	CalendarEnumCommonEventsCallback	
		jc	done			; carry set if abort enum
	;
	; Advance to next event
	;
next:
		add	di, size EventMapStruct	; es:di = next EventMapStruct
		loop	dayLoop
		clc

done:
		call	DBUnlock		; es destroyed

		.leave
		ret
CalendarEnumNormalEventsInDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCheckIfNormalEventExistsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to see if a normal event coincides with a period of
		time. 

CALLED BY:	MSG_DP_CHECK_IF_NORMAL_EVENT_EXISTS_CALLBACK
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
                ds:bx   = DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		ss:bp	= DayPlanEnumDateTimeRangeParams
		dx	= size of DayPlanEnumDateTimeRangeParams
RETURN:		carry set if a normal event exists over the given period of
		time, and should abort enumeration of multiple day events 
			ax	= CEE_NORMAL
		otherwise,
			ax	= CEE_EVENT_NOT_FOUND
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/14/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanCheckIfNormalEventExistsCallback	method dynamic DayPlanClass, 
				MSG_DP_CHECK_IF_NORMAL_EVENT_EXISTS_CALLBACK
		uses	bp
		.enter
	;
	; Lock down the DB item
	;
		movdw	dssi, ss:[bp].DPEDTRP_dateTimePtr
		Assert	fptr	dssi
		mov	ax, ss:[bp].DPEDTRP_eventGr
		mov	di, ss:[bp].DPEDTRP_eventIt
		call	GP_DBLockDerefDI	; es:di = EventStruct
EC <		test	es:[di].ES_varFlags, VL_END_DATE		>
EC <		ERROR_NZ CALENDAR_ENUM_NORMAL_EVENT_ERROR		>
EC <		test	es:[di].ES_varFlags, VL_START_TIME		>
EC <		ERROR_Z CALENDAR_ENUM_NORMAL_EVENT_ERROR		>
EC <		test	es:[di].ES_flags, mask EIF_REPEAT or mask EIF_TODO>
EC <		ERROR_NZ CALENDAR_ENUM_NORMAL_EVENT_ERROR		>
		Assert	eventID	es:[di].ES_uniqueID
	;
	; Check if event exists over the time range
	;
		sub	sp, size DateTimeRangeStruct
		mov	bp, sp			; ss:bp = DateTimeRangeStruct

		call	DayPlanCheckIfEventExistsCommon
						; carry set if event exists
		lahf
		add	sp, size DateTimeRangeStruct
		sahf				; stack restored

		mov	ax, CEE_EVENT_NOT_FOUND
		jnc	cleanup
		mov	ax, CEE_NORMAL

cleanup:
		call	DBUnlock		; es destroyed
						; flags preserved
		Assert	CalendarEventError	ax
		.leave
		ret
DayPlanCheckIfNormalEventExistsCallback	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCheckIfEventExistsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if an event of EventStruct exists over a period of time

CALLED BY:	(INTERNAL) DayPlanCheckIfMultipleDayEventExistsCallback,
		DayPlanCheckIfNormalEventExistsCallback
PASS:		es:di	= EventStruct of event to examine
		ds:si	= DateTimeRangeStruct of query time period
		ss:bp	= DateTimeRangeStruct of event specified by es:di to
			be filled in
RETURN:		ss:bp	= DateTimeRangeStruct filled in
		carry set if event exists over the period of time
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Update start date and time;
	if (VLF_END_DATE not set) {
		Copy event start date to end date fields;
	} else {
		Copy event end date to end date fields;
	}
	if (VLF_END_TIME not set) {
		Copy event start time to end time fields;
	} else {
		Copy event end time to end time fields;
	}
	Compare the event time range and query period time range;

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/14/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanCheckIfEventExistsCommon	proc	near
		uses	ax, es, di
		.enter
		Assert	fptr	esdi
		Assert	fptr	dssi
	;
	; ** WARNING **
	; There is some optimization of code based on the order of the fields
	; in structures. Please take a second to review the code if any of
	; these CheckHack's fails.
	;
		CheckHack <(offset RS_startDay)+1 eq (offset RS_startMonth)>
		CheckHack <(offset RS_endDay)+1 eq (offset RS_endMonth)>
		CheckHack <(offset ES_timeDay)+1 eq (offset ES_timeMonth)>
		CheckHack <(offset ES_endDay)+1 eq (offset ES_endMonth)>
		CheckHack <(offset ES_timeMinute)+1 eq (offset ES_timeHour)>
		CheckHack <(offset ES_endTimeMinute)+1 eq (offset ES_endTimeHour)>
		CheckHack <(offset DTRS_startMin)+1 eq (offset DTRS_startHour)>
		CheckHack <(offset DTRS_endMin)+1 eq (offset DTRS_endHour)>
	;
	; Prepare arguments to compare the range of event and query
	; period. 
	;
		movm	ss:[bp].DTRS_dateRange.RS_startYear, \
			es:[di].ES_timeYear, ax
		movm	{word}ss:[bp].DTRS_dateRange.RS_startDay, \
			{word}es:[di].ES_timeDay, ax
						; get both month and day
		movm	{word}ss:[bp].DTRS_startMin, \
			{word}es:[di].ES_timeMinute, ax
						; get both hour and min
	;
	; If the event does not have end date, use start date
	;
		test	es:[di].ES_varFlags, VL_END_DATE
		jz	noEndDate

		movm	ss:[bp].DTRS_dateRange.RS_endYear, \
			es:[di].ES_endYear, ax
		movm	{word}ss:[bp].DTRS_dateRange.RS_endDay, \
			{word}es:[di].ES_endDay, ax
		jmp	getEndTime		; get both month and day

noEndDate:
		movm	ss:[bp].DTRS_dateRange.RS_endYear, \
			es:[di].ES_timeYear, ax
		movm	{word}ss:[bp].DTRS_dateRange.RS_endDay, \
			{word}es:[di].ES_timeDay, ax
						; get both month and day
	;
	; If the event does not have end time, use start time
	;
getEndTime:
		test	es:[di].ES_varFlags, VL_END_TIME
		jz	noEndTime
		
		movm	{word}ss:[bp].DTRS_endMin, \
			{word}es:[di].ES_endTimeMinute, ax
		jmp	doQuery			; got both hour and min

noEndTime:
		movm	ss:[bp].DTRS_endHour, es:[di].ES_timeHour, al
		movm	ss:[bp].DTRS_endMin, es:[di].ES_timeMinute, al

doQuery:
		movdw	esdi, ssbp, ax		; es:di = event period
	;
	; ds:si	= event A (query period), es:di = event B (event period)
	; Check to see if they overlap.
	;
		call	CalendarCompareRange	; carry set if overlap
		.leave
		ret
DayPlanCheckIfEventExistsCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarEnumCommonEventsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invoke the callback message on the currently enumerated
		event. 

CALLED BY:	(INTERNAL) CalendarEnumMultipleDayEvents,
		CalendarEnumNormalEventsInDay
PASS:		ds:si	= EventEnumParamStruct
		ax:bx	= DB Group:Item of event passed to callback
		ss:bp	= inherited stack of CalendarEnumNormalEventsInDay or
			CalendarEnumMultipleDayEvents
RETURN:		Returned values from callback message:
			ss:[returnAX]	= ax from callback
			ss:[returnCX]	= cx from callback
			ss:[returnDX]	= dx from callback
			carry
		if carry set,
			abort enumeration as indicated by the callback
		if carry clear,
			enumeration should continue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/14/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarEnumCommonEventsCallback	proc	near
		uses	ax, bx, cx, dx, si, di
		.enter	inherit	CalendarEnumNormalEventsInDay
		Assert	fptr	dssi
	;
	; Prepare arguments to callback function
	;
		PUSH_EC	CALLBACK, bp
		mov	dx, size DayPlanEnumDateTimeRangeParams
		sub	sp, dx
		mov	di, sp			; ss:di = enum params to fill
		mov	ss:[di].DPEDTRP_eventGr, ax
		mov	ss:[di].DPEDTRP_eventIt, bx
		movm	ss:[di].DPEDTRP_argCX, ss:[argCX], ax
		movm	ss:[di].DPEDTRP_argDX, ss:[argDX], ax
		movm	ss:[di].DPEDTRP_argBP, ss:[argBP], ax
		mov	bp, di			; ss:bp = enum params filled
		mov	ax, si
		add	ax, offset EEPS_range	; ds:ax = DateTimeRangeStruct
		movdw	ss:[bp].DPEDTRP_dateTimePtr, dsax
	;
	; Call callback message
	;
		mov	ax, ds:[si].EEPS_callbackMsg
		movdw	bxsi, ds:[si].EEPS_callbackObj
		Assert	handle	bx
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage		; needs to return carry
	;
	; Move the returned result to local variables and save the flag
	;
		mov_tr	bx, ax			; bx = returned AX
		lahf				; save flags
		add	sp, size DayPlanEnumDateTimeRangeParams
						; restore stack
		sahf				; restore flags from callback
		POP_EC	CALLBACK, bp
		mov	ss:[returnAX], bx
		mov	ss:[returnCX], cx
		mov	ss:[returnDX], dx
		
		.leave
		ret
CalendarEnumCommonEventsCallback	endp

ApiCode	ends

endif	; CALAPI
