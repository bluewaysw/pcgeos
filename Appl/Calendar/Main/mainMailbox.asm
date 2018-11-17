COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Calendar\Main
FILE:		mainMailbox.asm

AUTHOR:		Jason Ho, Aug  8, 1996

ROUTINES:
	Name				Description
	----				-----------
    MTD MSG_META_MAILBOX_NOTIFY_MESSAGE_AVAILABLE
				Handle message from clavin telling us an
				appointment has arrived.

    MTD MSG_CALENDAR_HANDLE_AVAILABLE_MESSAGE
				Handle the available message from mailbox.

    INT CreateEventFromMBAppointmentBlock
				Create an event based on MBAppointment
				block passed.

    MTD MSG_CALENDAR_SHOW_SENT_TO_INFO
				Show the Sent-to info of currently selected
				event.

    MTD MSG_CALENDAR_QUERY_ITEM_MONIKER
				The message to use in querying for the list
				item monikers.

    INT ObjMessage_mailbox_call_fixup

    INT ObjMessage_mailbox_call

    INT ObjMessage_mailbox_send

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		8/ 8/96   	Initial revision


DESCRIPTION:
	Code to deal with mailbox notification (new appointment event
	defined outside GeoPlanner.)
		

	$Id: mainMailbox.asm,v 1.1 97/04/04 14:48:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HANDLE_MAILBOX_MSG
MailboxCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerMetaMailboxNotifyMessageAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle message from clavin telling us an appointment
		has arrived.

CALLED BY:	MSG_META_MAILBOX_NOTIFY_MESSAGE_AVAILABLE
PASS:		ax	= message #
		cx:dx	= MailboxMessage
RETURN:		carry set if handled
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Make sure it is an appointment / text / SMS.
		Get all the info from clavin and create a new
		appointment.

		Because of complications from CharsetDialog, need to queue
		another message to handle the relevant message.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/ 8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerMetaMailboxNotifyMessageAvailable	method dynamic GeoPlannerClass,
				MSG_META_MAILBOX_NOTIFY_MESSAGE_AVAILABLE
		.enter
	;
	; Make sure that this is an appointment or short message or
	; text chain. If it is not, ignore it.
	;
	; cxdx == MailboxMessage
	;
		call	MailboxGetBodyFormat	; carry set on error (bad msg)
						; bxax <- MailboxDataFormat
						; ax <- MailboxError if error
		jc	error
		
		cmp	bx, MANUFACTURER_ID_GEOWORKS
		jne	error
		cmp	ax, GMDFID_APPOINTMENT
		je	goodFormat
		cmp	ax, GMDFID_SHORT_MESSAGE
		je	goodFormat
		cmp	ax, GMDFID_TEXT_CHAIN
		jne	error
goodFormat:
if 0
	;
	; Dismiss any blocking dialog, especially charset dialog.
	;
	; Change my mind.. if we do that, then the second received
	; appt would close the first dialog, etc.
	;
		push	ax, cx, dx
		clr	bx
		call	GeodeGetAppObject		; ^lbx:si <- app obj
		mov	ax, MSG_GEN_APPLICATION_REMOVE_ALL_BLOCKING_DIALOGS
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	ax, cx, dx
endif
	;
	; Force queue the message to the process, so that the second
	; received appt won't appear until the first one is dismissed.
	;
		mov_tr	bp, ax				; bp <- data format
		mov	ax, MSG_CALENDAR_HANDLE_AVAILABLE_MESSAGE
		call	GeodeGetProcessHandle		; bx <- process handle
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		
		stc					; message handled
quit:
		.leave
		ret
error:
		clc					; not handled
		jmp	quit
GeoPlannerMetaMailboxNotifyMessageAvailable	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerHandleAvailableMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the available message from mailbox.

CALLED BY:	MSG_CALENDAR_HANDLE_AVAILABLE_MESSAGE
PASS:		ax	= message #
		cx:dx	= MailboxMessage
		bp	= GeoworksMailboxDataFormatID
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If the file is not valid, lower app window to bottom
		because mailbox just raises us. Then sleep for a while
		and force queue the message again.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/16/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerHandleAvailableMessage	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_HANDLE_AVAILABLE_MESSAGE
dataFormat	local	word	push bp
myAppRef	local	VMTreeAppRef
		.enter
	;
	; Is the file opened yet? If not, force queue the message.
	;
		GetResourceSegmentNS	dgroup, es	; es <- dgroup
		test	es:[systemStatus], SF_VALID_FILE
		jz	tryLater
	;
	; Bring app window to top, because we might have lowered it to
	; bottom before.
	;
		mov	ax, MSG_GEN_BRING_TO_TOP
		clr	bx
		call	GeodeGetAppObject		; ^lbx:si <- app obj
		call	ObjMessage_mailbox_send
	;
	; Tell the mailbox system that it can remove the entry from the inbox.
	; cxdx == MailboxMessage
	;
		call	MailboxAcknowledgeMessageReceipt
	;
	; Get the VMTreeAppRef filled.
	;
		segmov	es, ss, ax
		lea	di, myAppRef
		mov	ax, size myAppRef
		
		;cxdx	= MailboxMessage
		;es:di	= place to store app-reference to body
		;ax	= # bytes pointed to by es:di
		call	MailboxStealBody	; carry set on error,
						; ax <- MailboxError
						; else ax <- bytes used in buf 
		jc	error
	;
	; Find the VM block handle and file handle.
	;
		mov	di, ss:[myAppRef].VMTAR_vmChain.segment
		mov	bx, ss:[myAppRef].VMTAR_vmFile
oneEvent:
	; ----------------------------------------------------------------
		mov	ax, di
	;
	; Depend on data format, call routine to deal with it.
	;
		cmp	ss:[dataFormat], GMDFID_APPOINTMENT
		je	addMBAppoint
	;
	; It should be an SMS / text then. Deal with it.
	;
		call	HandleEventSMSMsg		; di <- next block
							;  handle
		jmp	doneWithBlock
addMBAppoint:
	;
	; Create an event from the block.
	;
		call	CreateEventFromMBAppointmentBlock ; di <- next block
							  ;  handle
doneWithBlock:		
	;
	; Free the block, now that we are done.
	; bx == file handle
	; ax == block handle
	;
		call	VMFree			; ds destroyed
	;
	; Any more struct to handle?
	;
		tst	di
		jnz	oneEvent

	; -----------------------------------------------------------------
	;
	; Done with all events
	; bx == file handle
	;
		call	MailboxDoneWithVMFile	
	;
	; Send MSG_DP_RESET_UI_IF_DETAILS_NOT_UP to DayPlan object to
	; update the screen.
	;
		push	bp
		mov	bx, handle DayPlanObject
		mov	si, offset DayPlanObject	; ^lbx:si = DayPlanObj
		mov	ax, MSG_DP_RESET_UI_IF_DETAILS_NOT_UP
		mov	di, mask MF_CALL		
		call	ObjMessage			; ax, cx, dx, bp gone
		pop	bp
error:
		.leave
		ret
tryLater:
	;
	; Lower app window to bottom.
	;
EC <		WARNING	CALENDAR_BOOKING_RETRY_IN_TEN_SECS		>
		mov	ax, MSG_GEN_LOWER_TO_BOTTOM
		clr	bx
		call	GeodeGetAppObject		; ^lbx:si <- app obj
		call	ObjMessage_mailbox_send
	;
	; Sleep for a while.
	;
		mov	ax, CALENDAR_IMPEX_WAIT_PERIOD	; 10 seconds
		call	TimerSleep
	;
	; Force queue message with the passed bp.
	;
		mov	ax, MSG_CALENDAR_HANDLE_AVAILABLE_MESSAGE
		call	GeodeGetProcessHandle		; bx = process handle
		mov	di, mask MF_FORCE_QUEUE
		push	bp
		mov	bp, ss:[dataFormat]
		call	ObjMessage
		pop	bp
		jmp	error
GeoPlannerHandleAvailableMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateEventFromMBAppointmentBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an event based on MBAppointment block passed.

CALLED BY:	(INTERNAL) GeoPlannerMetaMailboxNotifyMessageAvailable
PASS:		ax	= VM block handle containing MBAppointment struct
		bx	= VM file handle
RETURN:		di	= VM block handle containing next
			  MBAppointment struct, 0 if none.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateEventFromMBAppointmentBlock	proc	near
		uses	ax, bx, cx, dx, si
		.enter
		Assert	vmFileHandle, bx
	;
	; Send the DayPlanObject a message to create an event.
	;
		mov	cx, ax				; VM block handle
		mov	dx, bx				; VM file handle
		GetResourceHandleNS DayPlanObject, bx
		mov	si, offset DayPlanObject	; ^lbx:si = DayPlanObj,
							; dx <- VM file handle
		mov	ax, MSG_DP_CREATE_EVENT_FROM_CLAVIN
		mov	di, mask MF_CALL
		call	ObjMessage			; cx <- next block
		mov	di, cx
		
		.leave
		ret
CreateEventFromMBAppointmentBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerShowSentToInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the Sent-to info of currently selected event.

CALLED BY:	MSG_CALENDAR_SHOW_SENT_TO_INFO
PASS:		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Find the currently selected event.
		Send the event a message.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	1/31/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerShowSentToInfo	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_SHOW_SENT_TO_INFO
		.enter
	;
	; Find the currently selected event.
	;
		GetResourceHandleNS 	DPResource, bx
		mov	si, offset DayPlanObject
		mov	ax, MSG_DP_GET_SELECT
		call	ObjMessage_mailbox_call		; bp <- DayEvent chunk
	;
	; If no event is selected, quit.
	;
		tst	bp
EC <		WARNING_Z EVENT_HANDLE_DOESNT_EXIST_SO_OPERATION_IGNORED>
		jz	quit
		mov	si, bp				; ^lbx:si <- DayEvent
	;
	; Send it a message to do list initialization and open the
	; dilaog.
	;
		mov	ax, MSG_DE_DISPLAY_SENT_TO_INFO
		call	ObjMessage_mailbox_send
quit:
		.leave
		Destroy	ax, cx, dx, bp
		ret
GeoPlannerShowSentToInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The message to use in querying for the list item monikers.

CALLED BY:	MSG_CALENDAR_QUERY_ITEM_MONIKER
PASS:		ax	= message #
		^lcx:dx	= the dynamic list requesting the moniker
		bp	= the position of the item requested
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		>> From GenDynamicListClass documentation:
		The message will be sent to the destination for the
		list.  The handler is expected to reply by sending a
		MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER back to the
		list.


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	1/31/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerQueryItemMoniker	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_QUERY_ITEM_MONIKER
		.enter
		Assert	optr, cxdx
	;
	; Find the currently selected event.
	;
		push	bp
		GetResourceHandleNS 	DPResource, bx
		mov	si, offset DayPlanObject
		mov	ax, MSG_DP_GET_SELECT
		call	ObjMessage_mailbox_call		; bp <- DayEvent chunk
		mov	si, bp				; ^lbx:si <- DayEvent
		pop	bp
	;
	; If no event is selected, die.
	;
		tst	si
EC <		WARNING_Z EVENT_HANDLE_DOESNT_EXIST_SO_OPERATION_IGNORED>
		jz	quit
	;
	; Send it a message to create the moniker.
	;
		; ^lcx:dx == list item,
		; bp == position of the item request
		mov	ax, MSG_DE_QUERY_SENT_TO_ITEM_MONIKER
		call	ObjMessage_mailbox_send
quit::		
		.leave
		ret
GeoPlannerQueryItemMoniker	endm

ObjMessage_mailbox_call_fixup	proc	near
		push	di
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
			; mask MF_FIXUP_ES 
		call	ObjMessage
		pop	di
		ret
ObjMessage_mailbox_call_fixup	endp

ObjMessage_mailbox_call	proc	near
		push	di
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	di
		ret
ObjMessage_mailbox_call	endp

ObjMessage_mailbox_send	proc	near
		push	di
		clr	di
		call	ObjMessage
		pop	di
		ret
ObjMessage_mailbox_send	endp

MailboxCode	ends

endif

