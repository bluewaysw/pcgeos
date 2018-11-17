COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Calendar database API
MODULE:		Calendar
FILE:		mainApi.asm

AUTHOR:		Simon Auyeung, Feb  1, 1997

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_CALENDAR_ADD_EVENT	Add an event from another application to
				calendar database

    MTD MSG_CALENDAR_MODIFY_EVENT_BY_ID
				Modify a calendar event by event ID

    MTD MSG_CALENDAR_GET_EVENT_BY_ID
				Get a calendar event's data by event ID

    MTD MSG_CALENDAR_DELETE_EVENT_BY_ID
				Delete a calendar event by event ID

    MTD MSG_CALENDAR_CHECK_IF_EVENT_EXISTS
				Check if there is any event exists within a
				period of time

    INT GeoPlannerRetryMsgIfNotReady
				Check to see if the internal state of the
				appl is ready. If not, requeue the message
				and pass arguments on stack.

    INT GeoPlannerReplyCallback	Send callback object a reply message if
				defined

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/ 1/97   	Initial revision


DESCRIPTION:
	This file contains top level code to allow external applications to
	access calendar database.
	

	$Id: mainApi.asm,v 1.1 97/04/04 14:48:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ApiCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerAddEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an event from another application to calendar database

CALLED BY:	MSG_CALENDAR_ADD_EVENT
PASS:		ds, es 	= segment of GeoPlannerClass
		ax	= message #
		ss:bp	= CalendarAddEventParams
		dx	= size of CalendarAddEventParams
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Result of event addition is returned via callback message passed in:
	
		if there is error,
			cx	= CalendarEventError
		if there is no error,
			cx	= CEE_NORMAL
			dx:bp	= CalendarEventID

PSEUDO CODE/STRATEGY:
	If the database file is not set up, requeue this message;
	otherwise, call MSG_DP_CREATE_EVENT_FROM_API;
	if (has callback object and has callback message) {
		return results in callback;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon   2/ 1/97   	Initial version
	simon	2/24/97		Pulled out code of database checking and
				replying callback to common code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerAddEvent	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_ADD_EVENT
if	CALAPI
		uses	ax, cx, dx
		.enter
	;
	; Check if internal state is ready
	;
		call	GeoPlannerRetryMsgIfNotReady	
		jc	done			; carry set if DB not ready
	;
	; Add event
	;
		push	bp
		movdw	dxbp, ss:[bp].CAEP_param; dx:bp =
						; CalendarEventParamStruct
		GetResourceHandleNS DayPlanObject, bx
		mov	si, offset DayPlanObject; ^lbx:si = DayPlanObj,
		mov	ax, MSG_DP_CREATE_EVENT_FROM_API
		mov	di, mask MF_CALL
		call	ObjMessage		; cx = CalendarEventError
						; if cx == CEE_NORMAL
						;   dx:bp = event ID
		mov_tr	ax, bp			; dxax = event ID
		pop	bp
	;
	; Send the callback if exists
	;
		push	bp, ax
		movdw	bxsi, ss:[bp].CAEP_callbackObj
		mov	ax, ss:[bp].CAEP_callbackMsg
		pop	bp			; dxbp = event ID

		call	GeoPlannerReplyCallback ; may destroy bx,si,di,es,ds
		pop	bp			; restore stack

done:
		.leave
endif   ; CALAPI
		ret
GeoPlannerAddEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerModifyEventByID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify a calendar event by event ID

CALLED BY:	MSG_CALENDAR_MODIFY_EVENT_BY_ID
PASS:		ds, es 	= segment of GeoPlannerClass
		ax	= message #
		ss:bp	= CalendarModifyEventParams
		dx	= size of CalendarModifyEventParams
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Result of event modification is returned via callback message passed
	in: 
	
		if there is error,
			cx	= CalendarEventError
		if there is no error,
			cx	= CEE_NORMAL

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 6/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerModifyEventByID	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_MODIFY_EVENT_BY_ID
if	CALAPI
		uses	ax, dx
		.enter
	;
	; Check if internal state is ready
	;
		call	GeoPlannerRetryMsgIfNotReady	
		jc	done			; carry set if DB not ready
	;
	; Modify event. Pass arguments on the stack.
	;
		push	bp
		mov	dx, size DayPlanModifyEventParams
		sub	sp, dx			; allocate space on stack
		mov	si, sp
		movdw	ss:[si].DPMEP_param, ss:[bp].CMEP_param, ax
		movdw	ss:[si].DPMEP_eventID, ss:[bp].CMEP_eventID, ax
		mov	bp, si			; ss:bp =
						; DayPlanModifyEventParmas 
		GetResourceHandleNS DayPlanObject, bx
		mov	si, offset DayPlanObject; ^lbx:si = DayPlanObj,
		mov	ax, MSG_DP_MODIFY_EVENT_BY_ID_FROM_API
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage		; cx = CalendarEventError
		add	sp, dx			; claim back stack space
		pop	bp
	;
	; Send the callback if exists
	;
		movdw	bxsi, ss:[bp].CAEP_callbackObj
		mov	ax, ss:[bp].CAEP_callbackMsg

		call	GeoPlannerReplyCallback ; may destroy bx,si,di,es,ds

done:
		.leave
endif   ; CALAPI
		ret
GeoPlannerModifyEventByID	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerGetEventByID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a calendar event's data by event ID

CALLED BY:	MSG_CALENDAR_GET_EVENT_BY_ID
PASS:		ds, es 	= segment of GeoPlannerClass
		ax	= message #
		ss:bp	= CalendarGetEventByIDParams
		dx	= size of CalendarGetEventByIDParams
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Result of event deletion is returned via callback message passed in:
	
		if there is error,
			cx	= CalendarEventError
		if there is no error,
			cx	= CEE_NORMAL
			^hdx	= Unlocked block of
				CalendarReturnedEventStruct  

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/25/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerGetEventByID	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_GET_EVENT_BY_ID
if	CALAPI
		uses	ax
		.enter
	;
	; Check if internal state is ready
	;
		call	GeoPlannerRetryMsgIfNotReady	
		jc	done			; carry set if DB not ready
	;
	; Call DayPlanObject method handler
	;
		push	bp
		movdw	cxdx, ss:[bp].CGEBIDP_eventID
		mov	bp, ss:[bp].CGEBIDP_owner
		GetResourceHandleNS	DayPlanObject, bx
		mov	si, offset DayPlanObject
		mov	ax, MSG_DP_GET_EVENT_BY_ID_FROM_API
		mov	di, mask MF_CALL
		call	ObjMessage		; cx = CalendarEventError
		pop	bp			; if cx = CEE_NORMAL
						;   ^hdx =
						;   CalendarReturnedEventStruct
EC <		cmp	cx, CEE_NORMAL					>
EC <		jne	reply						>
EC <		Assert_handle	dx					>
	;
	; Send the callback if exists
	;
reply::
		movdw	bxsi, ss:[bp].CGEBIDP_callbackObj
		mov	ax, ss:[bp].CGEBIDP_callbackMsg
		call	GeoPlannerReplyCallback	; may destroy bx,si,di,es,ds
done:
		
		.leave
endif   ; CALAPI
		ret
GeoPlannerGetEventByID	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerDeleteEventByID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a calendar event by event ID

CALLED BY:	MSG_CALENDAR_DELETE_EVENT_BY_ID
PASS:		ds, es 	= segment of GeoPlannerClass
		ax	= message #
		ss:bp	= CalendarAccessEventByIDParams
		dx	= size of CalendarAccessEventByIDParams
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Result of event deletion is returned via callback message passed in:
	
		if there is error,
			cx	= CalendarEventError
		if there is no error,
			cx	= CEE_NORMAL

PSEUDO CODE/STRATEGY:
	If the database file is not set up, requeue this message;
	otherwise, call MSG_DP_DELETE_EVENT_FROM_API;
	if (has callback object and has callback message) {
		return results in callback;
	}

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/19/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerDeleteEventByID	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_DELETE_EVENT_BY_ID
if	CALAPI
		uses	ax, cx, dx
		.enter
	;
	; Check if internal state is ready
	;
		call	GeoPlannerRetryMsgIfNotReady	
		jc	done			; carry set if DB not ready
	;
	; Call DayPlanObject method handler
	;
		movdw	cxdx, ss:[bp].CAEBIDP_eventID
		GetResourceHandleNS	DayPlanObject, bx
		mov	si, offset DayPlanObject
		mov	ax, MSG_DP_DELETE_EVENT_BY_ID_FROM_API
		mov	di, mask MF_CALL
		call	ObjMessage		; cx = CalendarEventError
	;
	; Send the callback if exists
	;
		movdw	bxsi, ss:[bp].CAEBIDP_callbackObj
		mov	ax, ss:[bp].CAEBIDP_callbackMsg
		call	GeoPlannerReplyCallback	; may destroy bx,si,di,es,ds
done:
		.leave
endif	; CALAPI
		ret
GeoPlannerDeleteEventByID	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerCheckIfEventExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if there is any event exists within a period of time 

CALLED BY:	MSG_CALENDAR_CHECK_IF_EVENT_EXISTS
PASS:		ds, es 	= segment of GeoPlannerClass
		ax	= message #
		ss:bp	= CalendarCheckEventExistParams
		dx	= size of CalendarCheckEventExistParams
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Result of event deletion is returned via callback message passed in:
	
		if there is error,
			cx	= CalendarEventError
		if there is event overlapping the search range, 
			cx	= CEE_NORMAL
		if there is no event overlapping the search range,
			cx	= CEE_EVENT_NOT_FOUND

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 8/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerCheckIfEventExists	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_CHECK_IF_EVENT_EXISTS
if	CALAPI
		uses	ax, dx
		.enter
	;
	; Check if internal state is ready
	;
		call	GeoPlannerRetryMsgIfNotReady	
		jc	done			; carry set if DB not ready
	;
	; Call DayPlanObject method handler
	;
		PUSH_EC	CALLDP, bp
		mov	dx, size DayPlanCheckEventExistParams
		sub	sp, dx			; pass args on stack
		mov	si, sp
		movdw	ss:[si].DPCEEP_startDateTime, \
			ss:[bp].CCEEP_startDateTime, ax
		movdw	ss:[si].DPCEEP_endDateTime, \
			ss:[bp].CCEEP_endDateTime, ax
		mov	bp, si			; ss:bp =
						; DayPlanCheckEventExistParams
		GetResourceHandleNS	DayPlanObject, bx
		mov	si, offset DayPlanObject
		mov	ax, MSG_DP_CHECK_IF_EVENT_EXISTS
		mov	di, mask MF_CALL
		call	ObjMessage		; cx = CalendarEventError
		add	sp, dx			; restore stack
		POP_EC	CALLDP, bp
	;
	; Send the callback if exists
	;
		movdw	bxsi, ss:[bp].CCEEP_callbackObj
		mov	ax, ss:[bp].CCEEP_callbackMsg
		call	GeoPlannerReplyCallback	; may destroy bx,si,di,es,ds
done:
		.leave
endif   ; CALAPI
		ret
GeoPlannerCheckIfEventExists	endm

if	CALAPI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerRetryMsgIfNotReady
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the internal state of the appl is ready. If
		not, requeue the message and pass arguments on stack.

CALLED BY:	(INTERNAL) GeoPlannerAddEvent, GeoPlannerCheckIfEventExists,
		GeoPlannerDeleteEventByID, GeoPlannerGetEventByID,
		GeoPlannerModifyEventByID
PASS:		ax	= current message # to check
		ss:bp	= arguments passed on the stack
		dx	= size of arguments passed on the stack
		cx	= argument of the message
RETURN:		carry set if internal state not ready and message requeued
DESTROYED:	nothing
SIDE EFFECTS:	
	If the database file is not ready, the message is requeued.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/19/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerRetryMsgIfNotReady	proc	near
		uses	es, di, bx
		.enter
	;
	; If the database file is not opened, force queue the message
	;
		GetResourceSegmentNS	dgroup, es
		test	es:[systemStatus], SF_VALID_FILE
		jnz	done			; carry clear
	;
	; Force queue message to rety to wait until everything else is set up
	;
		call	GeodeGetProcessHandle	; bx = process handle
		mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
		call	ObjMessage
		stc				; msg requeued
done:
		.leave
		ret
GeoPlannerRetryMsgIfNotReady	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerReplyCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send callback object a reply message if defined

CALLED BY:	(INTERNAL) GeoPlannerAddEvent, GeoPlannerCheckIfEventExists,
		GeoPlannerDeleteEventByID, GeoPlannerGetEventByID,
		GeoPlannerModifyEventByID
PASS:		ax	= callback message or NULL if no callback
		^lbx:si	= callback object or process, OR
			  NULL if no callback
		cx, dx, bp
			= arguments to return to callback message
RETURN:		nothing
DESTROYED:	may destroy bx, si, di, es, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/19/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerReplyCallback	proc	near
		.enter

		CheckHack <NULL eq 0>
		tstdw	bxsi			; any callback object?
		jz	done

		tst	ax			; any callback message?
		jz	done

		Assert	handle	bx
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage		; may destroy bx,si,di,ds,es
done:
		.leave
		ret
GeoPlannerReplyCallback	endp

endif	; CALAPI

ApiCode		ends

