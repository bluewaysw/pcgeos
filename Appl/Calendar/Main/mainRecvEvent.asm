COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Calendar/Main
FILE:		mainRecvEvent.asm

AUTHOR:		Jason Ho, Nov 18, 1996

METHODS:
	Name				Description
	----				-----------

ROUTINES:
	Name				Description
	----				-----------
    INT HandleEventSMSMsg	Create an event based on the SMS text block
				passed, after confirmation from user.

    INT CreateMBAppointmentFromSMS
				Parse the SMS text, and create an
				MBAppointment structure.

    INT AddNewEventFromMBAppoint
				The SMS received specifies an appointment
				to be added. So create a (confirm) dialog,
				and add the event to database.

    INT HandleAcceptDenyReply	The SMS received specifies an appointment
				to be marked accepted. Just search for the
				original event, and change the send-to
				chunk array.

    INT LockSentToArrayFromEventGrIt
				From Gr:It of an event, lock down the
				database item, get the sent-to array
				block/chunk, and lock down the chunk array.

    INT SetStatusOnSentToWithBookIDCallback
				Callback from ChunkArrayEnum to search for
				the EventSentToStruct that has a specific
				book id, and set the status of the struct.

    INT HandleDeleteNotice	The SMS received specifies an appointment
				to be deleted from device. Search for the
				specified event, and delete it.

    INT GetCreatedEventGrIt	From the MBAppointment that specifies a
				created event to be changed (sent by an SMS
				from the event originator), get the event
				ID of the created event in the local
				calendar.

    INT GetCreatedEventGrItCallback
				Callback from HugeArrayEnum to search for
				the created event Gr:It.

    INT HandleChangedEventNotice
				The SMS received specifies an appointment
				to be changed (time change / text change).

    INT AllocateAndInitMBAppointment
				Allocate and initialize an MBAppointment
				structure.

    INT FetchSenderInfo		Fetch the sender name / number info from
				the MailboxMessage number, and store the
				info into MBAppointment struct.

    INT ParseVCalendarText	Parse the block of text, knowing that the
				content should describe a VCalendar.

    INT ReadPrefixAndConstructReplyPrefix
				Read in the SMS prefix, and if it is in
				long-sms-prefix format, reverse the
				source/destination port to form the reply
				prefix.

    INT SearchPropertyKeyword	Search for the property keyword in
				buffer. The keyword always starts a new
				line.

    INT ConsumeKeyword		Consume the keyword from buffer. This
				routine will NOT work with property keyword
				(because they have a colon at the end, and
				the spec allows infinite amount of space
				between the word and the colon.) Use
				SearchPropertyKeyword for property
				keywords.

    INT ConsumeWhiteSpaces	Consume any white spaces from the buffer.

    INT ConsumeLineNoUnfold	Consume the rest of the line. Don't do any
				unfolding.

    INT UnfoldAndConsumeLine	Consume the rest of the line. The line
				might be 'folded', ie. it is broken into
				two or more lines by folding technique. In
				that case, consume the next line(s) too.

    INT GetNextProperty		Find the next property (i.e. those keywords
				that start the line and end with ':') and
				return the enum value.
				
				If the first word in the line is not a
				property, the next line will be searched.

    INT GetNextValue		Find the next value and return the enum
				value. (Value has CR at the end.)
				
				If the remaining words in the line do not
				make up a value, VKT_UNKNOWN_KEYWORD is
				returned. (i.e. only current line is
				searched.)

    INT BinarySearchOnKeywordTable
				Search for the passed strings in the
				keyword table.

    INT ParseEventText		We found "BEGIN:EVENT", so now we are
				parsing the normal event (i.e. not to-do),
				and add info to the MBAppointment
				structure.

    INT ParseTodoText		We found "BEGIN:TODO", so now we are
				parsing the todo item (i.e. not event), and
				add info to the MBAppointment structure.

    INT HandleDAlarmProp	Handle "DALARM:" property.

    INT CalculateTimeDiffInMinutes
				Calculate the difference of two
				FileDate/Time combinations, in minutes.

    INT BreakUpFileTime		Break up a FileTime into hour/min.

    INT HandleDescriptionProp	Handle "DESCRIPTION:" property.

    INT CopyOneLineEscapedString
				Do string copy, and stop at C_CR/LF. The
				src string might be escaped by backslash.

    INT HandleStartTimeProp	Handle "DTSTART:" property.

    INT HandleEndTimeProp	Handle "DTEND:" property.

    INT GetFileDateTimeFromISOString
				Read the iso8601 string, and return
				date/time as FileDate/FileTime.

    INT HandleRepeatRuleProp	Handle "RRULE:" property.

    INT HandleStatusProp	Handle "STATUS:" property.

    INT HandleUIDProp		Handle "UID:" property.

    INT ExtractDWordFromUID	Extract a DWord from the ascii string which
				might be terminated from
				non-numeric. (e.g. 1812-blah blah)

    INT HandleCreatedEventProp	Handle "X-NOKIA-CREATED-EVENT:" property.

    INT HandlePasswordProp	Handle "X-NOKIA-PASSWD:" property.

    INT HandleReservedDaysProp	Handle "X-NOKIA-RESERVED-DAYS:" property.

    INT DisplayDayPlanGStateWindow
				If appropriate, open the
				ConfirmEventsListDialog that shows the list
				of event of the day.

    INT CallRoutineViaUIThread	Call the specified routine on the app UI
				thread (probably because the routine calls
				ObjLockObjBlock, and the object block's
				exec thread is always the app UI thread.)

    INT CreateAndStuffConfirmDialog
				Fill in the info for confirmation dialog.

    INT ChangeDialogForUpdate	Change the complex moniker title of the
				dialog, if the appointment status is
				text-update / update.

    INT CopyAndFormatWritableChunk
				Copy a format string to the writable chunk,
				and stuff in all info we have about it
				(from the MBAppointment).

    INT ResizeWritableChunk	Resize the writable chunk.

    INT ReplaceTokenWithTimeRelatedInfo
				Replace the token char in the text object
				to the date, time, alarm, etc info
				specified in MBAppointment struct.

    INT DeleteTokenFromString	Replace the token char in the text object
				to NULL.

    INT ReplaceTokenWithStartTime
				Replace the token in the string with start
				date/time text.

    INT ReplaceTokenWithEndTime	Replace the token in the string with end
				date/time text.

    INT ReplaceDateTimeTokensWithDateTimeFar
				Replace date/time tokens in the string with
				real date/time text.

    INT ReplaceDateTimeTokensWithDateTime
				Replace date/time tokens in the string with
				real date/time text.

    INT ReplaceTokenWithDate	Replace the token char in the text object
				to the date specified.

    INT ReplaceTokenWithTime	Replace the token char in the text object
				to the time specified.

    INT ReplaceTokenWithDayOfWeek
				Replace the token char in string chunk to
				the day of week specified.

    INT ReplaceTokenWithReservation
				Replace the token in the string with
				reservation text.

    INT ReplaceTokenWithAlarm	Replace the token in the string with alarm
				text.

    INT ReplaceTokenWithRepetition
				Replace the token in the string with
				repetition text.

    INT ReplaceTokenWithRepeatUntilDate
				Replace the token in the string with
				repetition text.

    INT ReplaceTokenWithReplyStatus
				Replace the token char in the text object
				by reply status.

    INT RepaceTokenWithUpdateAction
				Replace the token char in the text object
				with the update action ("removed from" or
				"changed in".)

    INT ReplaceTokenWithSenderInfo
				Replace the token char in the text object
				with the sender info.

    INT MatchSMSNumberAndGetName
				Match the passed SMS number in contdb, and
				fetch the name into the same buffer if we
				have a match.

    INT PutUpFlashingNote	Put up the right flashing note after user
				accepts / denies an incoming event, or
				sends an appointment.

    INT BringDownFlashingNote	Bring down the flashing note.

    INT ReplyAcceptOrDeny	Reply (to an SMS) that the user accepts or
				denies the event appointment.

    INT CreateVersitReplyIntoBlock
				Create the reply in human readable form or
				versit format, and write it to the block
				allocated.

    INT WriteReplyVersitFromRecvVersit
				Write reply in versit format to buffer, by
				copying (most of) the original recevied
				versit.

    INT CopyLineNoUnfold	Copy the rest of the line. Don't do any
				unfolding.

    INT UnfoldAndCopyLine	Copy the rest of the line to buffer. The
				line might be 'folded', ie. it is broken
				into two or more lines by folding
				technique. In that case, copy the next
				line(s) too.

    INT DisplayErrorDialog	The incoming SMS cannot be parsed as versit
				format.  Put up a dialog and bail.

    INT ReplaceTokenWithSenderInfoFromMailboxMessage
				Given the MailboxMessage number, find the
				sender name / sms number and replace the
				token in text with it.

    INT SubstituteStringArg	Substitute a string for a character in a
				chunk.

    INT CreateFileDateTimeRecordsFar
				Create FileDate and FileTime structs based
				on the date/time passed from caller.

    INT CreateFileDateTimeRecords
				Create FileDate and FileTime structs based
				on the date/time passed from caller.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		11/18/96   	Initial revision


DESCRIPTION:
	Code of GeoPlannerClass that is used when calendar event
	requests are received from other users.
		

	$Id: mainRecvEvent.asm,v 1.1 97/04/04 14:48:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HANDLE_MAILBOX_MSG

MailboxCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleEventSMSMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an event based on the SMS text block passed, after
		confirmation from user.

CALLED BY:	(INTERNAL) GeoPlannerMetaMailboxNotifyMessageAvailable
PASS:		ax	= VM block handle containing SMS text
		bx	= VM file handle
		cx:dx	= MailboxMessage
RETURN:		di	= VM block handle containing next
			  MBAppointment struct, 0 if none.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleEventSMSMsg	proc	near
		uses	ax, bx, cx, dx, bp, ds, si, es
		.enter
		Assert	vmFileHandle, bx
	;
	; Lock down the SMS text block from clavin
	;
		push	ax
		call	VMLock			; ax <- segment,
						; bp <- mem handle of
						; VM block
		mov_tr	ds, ax
		pop	ax
	;
	; Parse it, and create an MBAppointment block with the info.
	;
		call	CreateMBAppointmentFromSMS	; es <- MBAppointment
							;  segment,
							; di <- next VM block
							;  handle
							; bx <- block handle,
							; si <- status,
							; carry set if error
	;
	; Unlock the block.
	;
		; bp == mem handle of VM block
		call	VMUnlock			; ds destroyed
		jc	error
	;
	; Call a MBAppointment handler, based on the status specified
	; in SMS.
	;
		; si == CalendarApptStatusType
		Assert	etype, si, CalendarApptStatusType
		call	cs:[mbAppointHandler][si]	; can destroy ax, cx,
							;  dx, ds, si, es, bp
	;
	; Free MBAppointment block.
	;
		Assert	handle, bx
		call	MemFree
quit:
		.leave
		ret
error:
	;
	; Display a dialog.
	;
		; cxdx == MailboxMessage
		mov	ax, vseg DisplayErrorDialog
		mov	si, offset DisplayErrorDialog
		call	CallRoutineViaUIThread		; ax, cx, dx destroyed
		jmp	quit
HandleEventSMSMsg	endp

;
; These are the routines that handle MBAppointment struct (created
; from SMS). We pick the routine based on the status defined in SMS.
;
; Prototype of handlers:
;
; PASS:		es	= MBAppointment struct
;		bx	= MBAppointment block handle
; RETURN:	nothing
; DESTROYED:	everything except bx, di
;
mbAppointHandler	nptr \
	offset	AddNewEventFromMBAppoint,	; CAST_NEED_ACTIONS
	offset	HandleAcceptDenyReply,		; CAST_ACCEPTED
	offset	HandleAcceptDenyReply,		; CAST_DECLINED
	offset	HandleDeleteNotice,		; CAST_DELETED
	offset	HandleChangedEventNotice,	; CAST_CHANGED
	offset	HandleChangedEventNotice	; CAST_TEXT_CHANGED

CheckHack<(length mbAppointHandler*2) eq CalendarApptStatusType>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateMBAppointmentFromSMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the SMS text, and create an MBAppointment structure.

CALLED BY:	(INTERNAL) HandleEventSMSMsg
PASS:		ds	= segment containing SMS text
		cx:dx	= MailboxMessage
		ax	= VM block handle containing SMS text
		bx	= VM file handle
RETURN:		if no error in parsing / allocating memory:
		    es	= segment containing MBAppointment
		    di	= next VM block handle
		    bx	= block handle containing the struct (must be
			  MemFree'd later)
		    si	= CalendarApptStatusType
		    carry cleared
		if error:
		    carry set
		    di  = next VM block handle
		    es / bx / cx / si = destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		MailboxMessage number has to be put into MBAppointment struct
		too.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateMBAppointmentFromSMS	proc	near
		uses	ax, cx, ds
		.enter
		Assert	segment, ds
	;
	; Allocate the struct.
	;
		mov	di, bx
		call	AllocateAndInitMBAppointment	; es <- MBAppointment,
							;  bx <- block handle,
							;  carry set if error.
		jc	quit
		mov	si, size VMChainLink		; ds:si <- text buffer
	;
	; Store the versit vm file handle and block handle to escape info.
	;
		mov	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_versitVMFile, di
		mov	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_versitBlock, ax
	;
	; Fetch sender name / sender number, and store into
	; MBAppointment.
	;
		call	FetchSenderInfo
	;
	; Parse versit text.
	;
		call	ParseVCalendarText		; carry set if error
		jc	freeBlock
	;
	; Return CalendarApptStatusType.
	;
		mov	si, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_apptStatus
quit:
	;
	; Get the next VM block handle to be returned.
	;
		mov	di, ds:[SMSTH_meta].VMCL_next
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
freeBlock:
	;
	; Free the mem block we allocated.
	;
		; bx == block handle
		Assert	handle, bx
		call	MemFree				; bx, es destroyed
		stc					; error
		jmp	quit
CreateMBAppointmentFromSMS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNewEventFromMBAppoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The SMS received specifies an appointment to be
		added. So create a (confirm) dialog, and add the event
		to database.

CALLED BY:	(INTERNAL) HandleEventSMSMsg
PASS:		es	= MBAppointment struct
		bx	= MBAppointment block handle
RETURN:		nothing
DESTROYED:	everything except bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/21/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddNewEventFromMBAppoint	proc	near
		uses	bx
		.enter
		Assert	segment, es
		Assert	handle, bx
	;
	; Make our UI thread create the confirmation dialog.
	;
		call	CreateAndStuffConfirmDialog	; ^lcx:dx <- dialog,
							;  cx <-0 if no dialog,
		jcxz	quit
		Assert	optr, cxdx
		movdw	bxsi, cxdx
	;
	; Initiate the accompanying event list dialog, if necessary.
	;
		call	DisplayDayPlanGStateWindow
	;
	; Do dialog.
	;
		call	UserDoDialog			; ax <- IC_YES/OK/NO/
							; NULL, ds may be
							; destroyed
		mov	bp, ax				; bp <- IC_...
	;
	; Accept, deny or cancel?
	;
		cmp	ax, IC_YES
		je	accept
		cmp	ax, IC_OK			; from reservation
							;  dialog "OK"
		je	accept
		cmp	ax, IC_NO
		je	deny
quit:
		.leave
		Destroy	ax, cx, dx, bp
		ret
accept:
	;
	; Add the MBAppointment structure to calendar database, by sending a
	; message to DayPlanObject.
	;
		mov	bx, handle DayPlanObject
		mov	si, offset DayPlanObject	; ^lbx:si = DayPlanObj,
							; dx <- VM file handle
		mov	cx, es				; MBAppointment segment
		mov	ax, MSG_DP_CREATE_EVENT_FROM_MBAPPOINTMENT
		call	ObjMessage_mailbox_call		; cxdx <- unique ID
		mov	ax, IC_YES
deny:
	;
	; Record action to MBAppointment.
	;
		mov	si, CALENDAR_ESCAPE_DATA_OFFSET
		Assert	e, ah, 0
		mov	es:[si].CAET_userReply, al
	;
	; Record created event ID to MBAppointment too, if an event is
	; created.
	;
		cmp	ax, IC_YES
		jne	noEventCreated
		movdw	es:[si].CAET_createdEventID, cxdx
noEventCreated:
	;
	; Skip reply if user receives a forced event, and presses OK
	; to close the dialog.
	;
		; bp == real user response
		cmp	bp, IC_OK
		je	quit
	;
	; Do reply even if this is a forced event.
	;
	; Display flashing note that says, "Received Calendar event
	; .... Reply started to send."
	;
		; ax == IC_YES or IC_NO
		cmp	ax, IC_YES
		mov	ax, offset AcceptFlashingText
		je	flash
		mov	ax, offset DenyFlashingText
flash:
		call	PutUpFlashingNote		; ^lbx:si <- dialog
	;
	; Do the SMS reply.
	;
		call	ReplyAcceptOrDeny
	;
	; Bring down flashing note.
	;
		call	BringDownFlashingNote

		jmp	quit
AddNewEventFromMBAppoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleAcceptDenyReply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The SMS received specifies an appointment to be
		marked accepted. Just search for the original event, and
		change the send-to chunk array.

CALLED BY:	(INTERNAL) HandleEventSMSMsg
PASS:		es	= MBAppointment struct
		bx	= MBAppointment block handle
RETURN:		nothing
DESTROYED:	everything except bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get unique ID of original event.
		Search for the group:item of the event.
		Get sent-to array handle/chunk of the event.
		Lock down sent-to chunk array.
		Call ChunkArrayEnum to find the right sent-to, and set the
		status (and remote event id)

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/22/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleAcceptDenyReply	proc	near
		uses	bx, di
		.enter
		Assert	segment, es
		Assert	handle, bx
	;
	; Create a note dialog.
	;
		call	CreateAndStuffConfirmDialog	; ^lcx:dx = dialog
EC <		tst	cx						>
EC <		ERROR_Z	CALENDAR_INTERNAL_ERROR				>
		Assert	optr, cxdx
	;
	; Display it.
	;
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage_mailbox_send		; nothing destroyed
	;
	; Move MBAppointment segment to something useful.
	;
		segmov	ds, es, bp
		mov	bp, CALENDAR_ESCAPE_DATA_OFFSET
	;
	; Get the unique id of the event, which is stored in escape info
	; CAET_senderEventID.
	;
		movdw	cxdx, ds:[bp].CAET_senderEventID
	;
	; If this is illegal (possibly a reply from non-lizzy device)
	; don't try to search for the event.
	;
		cmpdw	cxdx, FIRST_EVENT_ID
EC <		WARNING_B CALENDAR_CANNOT_FIND_ORIGINAL_EVENT_FOR_UPDATE>
		jb	failed
	;
	; Search for the Group:Item of the event.
	;
		; cxdx == unique id
		call	DBSearchEventIDArray	; ax:di <- Gr:It of event,
						; cxdx <- element index,
						; carry cleared if not found
EC <		WARNING_NC CALENDAR_CANNOT_FIND_ORIGINAL_EVENT_FOR_UPDATE>
		jnc	failed
	;
	; Access sent-to array.
	;
		mov	cx, ds			; cx:dx <-
		mov	dx, bp			; CalendarApptEscapeType
	;
	; Lock down the database item, and lock down sent-to array.
	;
		call	LockSentToArrayFromEventGrIt
						; es:di <- db item,
						; if has sent-to:
						;  *ds:si <- array, bp <-
						;  array mem handle, carry
						;  cleared
		jc	unlockItem
	;
	; Look for the EventSentToStruct that has the book ID specified in
	; MBAppointment, and set the status.
	;
		mov	bx, SEGMENT_CS
		mov	di, offset SetStatusOnSentToWithBookIDCallback
		call	ChunkArrayEnum		; bx destroyed
	;
	; Mark vm block dirty, and unlock.
	;
		; bp == VM mem handle
		Assert	vmMemHandle, bp
		call	VMDirty
		call	VMUnlock		; ds destroyed	
unlockItem:
	;
	; Unlock item.
	;
		; es == DB segment
		call	GP_DBDirtyUnlock	; es destroyed
quit:
		.leave
		Destroy	ax, cx, dx, bp
		ret
failed:
	;
	; Display a dialog (original event cannot be found).
	;
		mov	cx, handle OriginalEventCannotBeFoundWarning
		mov	dx, offset OriginalEventCannotBeFoundWarning
		call	FoamDisplayNoteNoBlock
		jmp	quit
HandleAcceptDenyReply	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockSentToArrayFromEventGrIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	From Gr:It of an event, lock down the database item, get the
		sent-to array block/chunk, and lock down the chunk array.

CALLED BY:	(INTERNAL) HandleAcceptDenyReply
PASS:		axdi	= Gr:It of event
RETURN:		es:di	= pointer to database item
		if the item has sent-to array info:
			*ds:si	= sent-to chunk array
			bp	= mem handle of chunk array
			carry cleared
		else
			ds, si, bp destroyed
			carry set
DESTROYED:	nothing
SIDE EFFECTS:	
		*MUST* call DBUnlock on the returned es (db segment) to
		unlock the database item.

		*MUST* call VMUnlock on the returned bp (mem handle) to
		unlock the chunk array, if the array is locked.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/27/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockSentToArrayFromEventGrIt	proc	near
		uses	ax, bx
		.enter
	;
	; Now lock down the item, and get the sent-to info array.
	;
		call	GP_DBLockDerefDI	; es:di <- item
	;
	; Check if event is repeat event.
	;
		IsEventRepeatEvent	ax	; ZF set if repeat event
		mov	ax, es:[di].RES_sentToArrayBlock
		mov	si, es:[di].RES_sentToArrayChunk
		jz	repeatEvent
		
		mov	ax, es:[di].ES_sentToArrayBlock
		mov	si, es:[di].ES_sentToArrayChunk
repeatEvent:
	;
	; If there is no sent-to array, don't lock.
	;
		tst	ax
		stc				; assume no sent-to array
		jz	quit
		
		call	LockChunkArrayFar	; *ds:si <- array,
						;  bp <- mem handle
						;  ax, bx destroyed
quit:
		.leave
		ret
LockSentToArrayFromEventGrIt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetStatusOnSentToWithBookIDCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback from ChunkArrayEnum to search for the
		EventSentToStruct that has a specific book id, and set the
		status of the struct.

CALLED BY:	(INTERNAL) HandleAcceptDenyReply through ChunkArrayEnum
PASS:		*ds:si	= array
		ds:di	= array element
		cx:dx	= CalendarApptEscapeType
RETURN:		carry set to end enumeration
		cx, dx	= not changed: data to pass to next
DESTROYED:	bx, si
ALLOWED TO DESTROY:
		bx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if (bookID doesn't match) quit

		if (appointment status == CAST_DECLINED) {
		    status := ERS_DISCARDED
		} else {
		    appointment status must be CAST_ACCEPTED

		    if (old status == ERS_FORCED) {
			status := ERS_FORCED_AND_ACCEPTED
		    } else {
			status := ERS_ACCEPTED
		    }

		    set remote event id if specified
		}

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/22/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetStatusOnSentToWithBookIDCallback	proc	far
		uses	ax, es
		.enter
		Assert	fptr, cxdx
	;
	; Move fptr to meaningful registers.
	;
		movdw	essi, cxdx
		mov	ax, es:[si].CAET_senderBookID
		mov	bx, es:[si].CAET_apptStatus
	;
	; Same book ID?
	;
		cmp	ds:[di].ESTS_bookID, ax
		clc				; assume not match, and
						;  continue enumeration
		jne	quit
	;
	; Is this a declined appointment?
	;
		cmp	bx, CAST_DECLINED
		jne	accepted

EC <		cmp	ds:[di].ESTS_status, ERS_FORCED			>
EC <		WARNING_E CALENDAR_HOW_COME_RESERVATION_IS_DECLINED	>
	;
	; Write ESTS_status := ERS_DISCARDED.
	;
		mov	ax, ERS_DISCARDED
writeStatus:
		mov	ds:[di].ESTS_status, ax
if 0
	;
	; Should redraw the sent-to list, if it is open.
	;
	; It doesn't work, because when the app sends out MSG_DP_RESET_UI,
	; no event gets selected, and the list cannot get moniker anymore.
	;
		push	cx
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	bx, handle SentToList
		mov	si, offset SentToList
		mov	cx, GDLI_NO_CHANGE
		call	ObjMessage_mailbox_send
		pop	cx
endif
		stc				; stop enumeration
quit:
		
		.leave
		ret
accepted:
	;
	; The appointment is accepted. See if we are given the remote event
	; id.
	;
		cmpdw	es:[si].CAET_createdEventID, INVALID_EVENT_ID
		jbe	noRemoteEventID
	;
	; Remember the remote event id.
	;
		movdw	ds:[di].ESTS_remoteEventID, \
			 es:[si].CAET_createdEventID, ax
noRemoteEventID:
	;
	; Was this sent as an reservation? If so, write status =
	; ERS_FORCED_AND_ACCEPTED.
	;
		cmp	ds:[di].ESTS_status, ERS_FOR_RESERVATION
		mov	ax, ERS_FORCED_AND_ACCEPTED
		jae	writeStatus
	;
	; So this was sent as an ordinary event. Write status = ERS_ACCEPTED.
	;
		mov	ax, ERS_ACCEPTED
		jmp	writeStatus

SetStatusOnSentToWithBookIDCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleDeleteNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The SMS received specifies an appointment to be
		deleted from device. Search for the specified event, and
		delete it.

CALLED BY:	(INTERNAL) HandleEventSMSMsg
PASS:		es	= MBAppointment struct
		bx	= MBAppointment block handle
RETURN:		nothing
DESTROYED:	everything except bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Create a note dialog.
		Display the dialog.
		Search for the group:item of the event.
		Delete it.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/26/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleDeleteNotice	proc	near
		uses	bx, di
		.enter
		Assert	segment, es
		Assert	handle, bx
	;
	; Create a note dialog.
	;
		call	CreateAndStuffConfirmDialog	; ^lcx:dx = dialog
EC <		tst	cx						>
EC <		ERROR_Z	CALENDAR_INTERNAL_ERROR				>
		Assert	optr, cxdx
	;
	; Display it.
	;
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage_mailbox_send		; nothing destroyed
	;
	; First call a routine to get the db Gr/It of the specified
	; event. Note that the SMS might not specify it at all, if the sender
	; sends out the delete notice before the recipient (ie. WE) can
	; reply.
	;
		call	GetCreatedEventGrIt		; axdi <- Gr:It,
							;  carry clear if error
		jnc	failed
	;
	; Reset UI first.
	;
		push	ax, di

		mov	bx, handle DayPlanObject
		mov	si, offset DayPlanObject	; ^lbx:si = DayPlanObj
		mov	ax, MSG_DP_RESET_UI
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone

		pop	cx, dx
	;
	; Delete event.
	;
		mov	ax, MSG_DP_DELETE_EVENT_BY_EVENT
		mov	di, mask MF_CALL
		call	ObjMessage
quit:
		.leave
		Destroy	ax, cx, dx, bp
		ret
failed:
	;
	; Display a dialog (event to be deleted cannot be found).
	;
		mov	cx, handle EventToBeDeletedCannotBeFoundWarning
		mov	dx, offset EventToBeDeletedCannotBeFoundWarning
		call	FoamDisplayNoteNoBlock
		jmp	quit
HandleDeleteNotice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCreatedEventGrIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	From the MBAppointment that specifies a created event to be
		changed (sent by an SMS from the event originator), get the
		event ID of the created event in the local calendar.

CALLED BY:	(INTERNAL) HandleDeleteNotice
PASS:		es	= MBAppointment struct
RETURN:		if the created event is found:
			axdi	= Gr:It
			carry set
		else
			axdi	= destroyed
			carry cleared

		*** NOTE *** even if the event is a repeated event,
		this routine would NOT return ax with REPEAT_MASK
		(because that is not the real group number). So to
		check for repeat event, use macro IsEventRepeatEvent.

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Story time:

		Sender Tom sends out appointment (that contains Tom's
		event ID and book ID) to the recipient, Jerry.

		Scenario one:
		-------------
		Jerry accepts the appointment, and Tom gets a confirm
		SMS. That reply has the event ID of the created event
		(on Jerry's calendar).

		So if Tom wants to cancel the event, he already has
		Jerry's event ID. Then, the update SMS would have the
		created event ID.

		Even if we have the event ID, it doesn't guarantee the event
		is not deleted.

		Scenario two:
		-------------
		Before Jerry replies to the appointment, Tom cancels
		the appointment. The update SMS would not have Jerry's
		event ID.

		How are we going to search for the created event?
		We cannot search by date/time/text, because Jerry
		could have changed it.

		We would use a few things to do the search: Tom's
		event ID and book ID (which are stored into Jerry's
		created event when event is created). We lock down the
		huge array of unique ID -> Gr:It mapping, and starts
		comparing event ID and book ID.

		But Jerry could have another appointment from Barney,
		that happens to have the same event ID and book ID. So
		we would compare SMS number (CAET_senderAddress) too.

		If Jerry deleted the event after it is received, then the
		search will fail.


		If (CAET_createdEventID is valid) {
		    find Gr:It of event
		    return it
		}

		Lock down the event ID huge array, and do hugh array
		enum. 

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/26/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCreatedEventGrIt	proc	near
		uses	bx, cx, dx, bp, es
		.enter
		Assert	segment, es
	;
	; First, see if we have the easy way out.
	;
		movdw	cxdx, \
			es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_createdEventID
		cmpdw	cxdx, INVALID_EVENT_ID
		jbe	hardWay
	;
	; Just get the Gr:It, and return.
	;
		call	DBSearchEventIDArray	; ax:di <- Gr:It, cx:dx <-
						;  index, es destroyed,
						; carry clear if error.
EC <		WARNING_NC CALENDAR_DB_UNIQUE_ID_SEARCH_FAILED		>
	;	jmp	quit
		jc	quit
hardWay:
	;
	; Enumerate the array to find the created event, by matching sender
	; event id, sender book id, and sender SMS number.
	;
	; Set up the arguments for HughArrayEnum.
	;
		mov	cx, es			; backup es
		
		GetResourceSegmentNS	dgroup, es
		Assert	vmFileHandle	es:[vmFile]
		push	es:[vmFile]		; VM File (1st arg)
		
		call	GP_DBLockMap		; *es:di = map block
		mov	di, es:[di]		; es:di = YearMapHeader
		push	es:[di].YMH_eventIDArray; huge array (2nd arg)
		call	DBUnlock		; es destroyed
						
		mov	ax, SEGMENT_CS
		mov	bx, offset GetCreatedEventGrItCallback
		pushdw	axbx			; vfptr of callback (3rd arg)

		clr	ax			; start from 1st elem
		pushdw	axax			; starting elem (4th arg)

		mov	ax, -1			; enum to the end 
		pushdw	axax			; # elem to process (5th arg)
	;
	; Set up the arguments for callback.
	;
		mov	es, cx			; es <- MBAppointment
		mov	di, CALENDAR_ESCAPE_DATA_OFFSET
		movdw	cxdx, es:[di].CAET_senderEventID
		mov	bp, es:[di].CAET_senderBookID
		call	HugeArrayEnum		; cx:dx <- Gr:It
						;  ax destroyed, 
						; carry cleared if error
EC <		WARNING_NC CALENDAR_CANNOT_FIND_ORIGINAL_EVENT_FOR_UPDATE>
		mov_tr	ax, cx
		mov	di, dx
quit:
		.leave
		ret
GetCreatedEventGrIt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCreatedEventGrItCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback from HugeArrayEnum to search for the created event
		Gr:It.

CALLED BY:	(INTERNAL) GetCreatedEventGrIt via HugeArrayEnum
PASS:		ds:di	= EventIDArrayElemStruct of current element
		cxdx	= sender's event ID
		bp	= sender's book ID
		es	= MBAppointment struct
RETURN:		carry set to abort
		cx, dx, bp, es = Data for next callback
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get Gr:It of event that is represented by current element.
		Lock it down.
		If the event does not have sent-to array info (which stores
		originator's event id / book id / sms number) then this is
		not a match.
		Lock down the sent-to array.
		If (event id does not match) or (book id does not match) {
		    no match
		}
		If (originator's SMS number does not match the number in
		MBAppointment) {
		    no match  (what is the odd for that ??)
		}

		Just one more note about book ID matching: when
		sender's event time is changed, update SMS is sent
		out. But the update SMS has new book ID (because that
		is considered a new booking), and the new ID is always
		bigger. So when checking book ID, we don't need a
		perfect match, just a "below-or-equal" match.


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/27/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCreatedEventGrItCallback	proc	far
bookID		local	word		push	bp
mbApptSegment	local	sptr		push	es
eventGr		local	word
eventIt		local	word
		uses	ds, si, es, di
		.enter

		Assert	fptr, dsdi
		Assert	eventID, cxdx
		Assert	segment, es
	;
	; Get Gr:It of event that is represented by current element.
	;
		mov	ax, ds:[di].EIDAES_eventGr
		mov	di, ds:[di].EIDAES_eventIt
		mov	ss:[eventGr], ax
		mov	ss:[eventIt], di
	;
	; Lock down db item, and lock down the sent-to array associated with
	; the event if any.
	;
		push	bp
		call	LockSentToArrayFromEventGrIt
						; es:di <- db item,
						; if has sent-to:
						;  *ds:si <- array, bp <-
						;  array mem handle, carry
						;  cleared
		mov_tr	ax, bp			; flag not changed
		pop	bp
		cmc
		jnc	quit			; no sent-to
	;
	; Compare event ID.
	;
		mov	si, ds:[si]		; ds:si <- EventSentToHeader
		cmpdw	ds:[si].ESTH_senderEventID, cxdx
		jne	noMatch

		mov	di, ss:[bookID]
		cmp	ds:[si].ESTH_senderBookID, di
		ja	noMatch			; read note above to see why we
						;  use ja instead of jne
	;
	; Finally, to make sure this event is originated from the sender, we
	; do a string compare on sms number.
	;
		lea	si, ds:[si].ESTH_senderSMS ; ds:si <- originator
		push	es
		mov	es, ss:[mbApptSegment]
		lea	di, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderAddress
						   ; es:di <- sender
		clr	cx			   ; null terminated
		call	LocalCmpStrings
		pop	es
		jne	noMatch
	;
	; We found it! Return values.
	;
		mov	cx, ss:[eventGr]
		mov	dx, ss:[eventIt]
		stc
		jmp	unlockSentTo
noMatch:
	;
	; Signal we should continue the enumeration.
	;
		clc
unlockSentTo:
	;
	; Unlock sent-to array.
	;
		; ax == VM mem handle
		Assert	vmMemHandle, ax
		push	bp
		mov_tr	bp, ax
		call	VMUnlock		; ds destroyed
		pop	bp
quit:
	;
	; Unlock item.
	;
		; es == DB segment
		call	DBUnlock		; es destroyed

		.leave
		ret
GetCreatedEventGrItCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleChangedEventNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The SMS received specifies an appointment to be
		changed (time change / text change).

CALLED BY:	(INTERNAL) HandleEventSMSMsg
PASS:		es	= MBAppointment struct
		bx	= MBAppointment block handle
RETURN:		nothing
DESTROYED:	everything except bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Create confirm dialog.
		Display DayPlan window, if appropriate.
		Do confirm dialog.
		if (IC_YES/IC_OK) attempt to change event.
		if (IC_YES/IC_NO) reply (accept/reject).


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/10/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleChangedEventNotice	proc	near
		uses	bx, di
		.enter
		Assert	segment, es
		Assert	handle, bx
	;
	; Create a note dialog.
	;
		call	CreateAndStuffConfirmDialog	; ^lcx:dx = dialog
EC <		tst	cx						>
EC <		ERROR_Z	CALENDAR_INTERNAL_ERROR				>
		Assert	optr, cxdx
		movdw	bxsi, cxdx
	;
	; Initiate the accompanying event list dialog, if necessary.
	;
		call	DisplayDayPlanGStateWindow
	;
	; Do dialog.
	;
		call	UserDoDialog			; ax <- IC_YES/OK/NO/
							; NULL, ds may be
							; destroyed
		mov	bp, ax				; bp <- IC_...
	;
	; Accept, deny or cancel?
	;
		cmp	ax, IC_YES
		je	accept
		cmp	ax, IC_OK			; from reservation
							;  dialog "OK"
		je	accept
		cmp	ax, IC_NO
		je	deny
quit:
		.leave
		ret
accept:
	;
	; First call a routine to get the db Gr/It of the specified
	; event. Note that the SMS might not specify it at all, if the sender
	; sends out the delete notice before the recipient (ie. WE) can
	; reply.
	;
		call	GetCreatedEventGrIt		; axdi <- Gr:It,
							;  carry clear if error
		jnc	failed
	;
	; Change event.
	;
		mov	bx, handle DayPlanObject
		mov	si, offset DayPlanObject	; ^lbx:si = DayPlanObj
		mov_tr	cx, ax
		mov	dx, di				; cx:dx <- Gr:It
		push	bp
		mov	bp, es				; MBAppointment segment
		mov	ax, MSG_DP_MODIFY_EVENT_BY_GR_IT_FROM_MBAPPOINTMENT
		call	ObjMessage_mailbox_call		; cxdx <- unique ID
		pop	bp
		
		mov	ax, IC_YES
deny:
	;
	; Record action to MBAppointment.
	;
		mov	si, CALENDAR_ESCAPE_DATA_OFFSET
		Assert	e, ah, 0
		mov	es:[si].CAET_userReply, al
	;
	; Record created event ID to MBAppointment too, if an event is
	; created.
	;
		cmp	ax, IC_YES
		jne	noEventChanged
		movdw	es:[si].CAET_createdEventID, cxdx
noEventChanged:
	;
	; Skip reply if user receives a forced event, and presses OK
	; to close the dialog.
	;
		; bp == real user response
		cmp	bp, IC_OK
		je	quit
	;
	; Display flashing note that says, "Received Calendar event
	; .... Reply started to send."
	;
		; ax == IC_YES or IC_NO
		cmp	ax, IC_YES
		mov	ax, offset AcceptFlashingText
		je	flash
		mov	ax, offset DenyFlashingText
flash:
		call	PutUpFlashingNote		; ^lbx:si <- dialog
	;
	; Do the SMS reply.
	;
		call	ReplyAcceptOrDeny
	;
	; Bring down flashing note.
	;
		call	BringDownFlashingNote

		jmp	quit
failed:
	;
	; Display a dialog (event to be deleted cannot be found).
	;
		mov	cx, handle EventToBeChangedCannotBeFoundWarning
		mov	dx, offset EventToBeChangedCannotBeFoundWarning
		call	FoamDisplayNoteNoBlock
		jmp	quit
HandleChangedEventNotice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateAndInitMBAppointment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize an MBAppointment structure.

CALLED BY:	(INTERNAL) CreateMBAppointmentFromSMS,
			   StuffSMSEventSummary
PASS:		nothing
RETURN:		bx	= handle of MBAppointment block,
		es	= segment or locked block
		carry set if error (e.g. not enough memory)
DESTROYED:	nothing
SIDE EFFECTS:	
		MUST do MemFree on the handle after you are done with
		the block!

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateAndInitMBAppointment	proc	near
		uses	ax, cx, si
		.enter
	;
	; First, allocate a block of memory to store the MBAppointment
	; struct.
	;
		push	cx
		mov	ax, MBAPPOINTMENT_BLOCK_SIZE
		mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK or \
			      mask HAF_NO_ERR) shl 8) or \
			     mask HF_SWAPABLE
		call	MemAlloc			; bx <- handle,
							; ax <- block address,
							; cx destroyed
EC <		WARNING_C CALENDAR_NO_MEMORY_TO_ADD_APPOINTMENT		>
		pop	cx
		jc	quit
	;
	; MBAppointment will be written to es segment.
	;
		mov_tr	es, ax				; es <- block address
	;
	; Initialization of struct.
	; no next appointment
	;
		clr	es:[MBA_meta].VMCL_next
	;
	; todo-normal priority, no end time
	;
		mov	es:[MBA_start].FDAT_date, MB_NO_TIME
		mov	es:[MBA_start].FDAT_time, MB_TODO_NORMAL_PRIORITY
		movdw	es:[MBA_end], MB_NO_TIME
	;
	; Escape info: password boolean, mailbox message number and
	; UID, SMS prefix, reply status and reply format.
	;
		mov	si, CALENDAR_ESCAPE_TABLE_OFFSET
		mov	es:[MBA_escapes], si
		mov	es:[si].MBET_numEscapes, INITIAL_NUM_OF_ESCAPES
		mov	si, CALENDAR_ESCAPE_INFO_OFFSET
		mov	es:[si].MBEI_size, \
				size MBEscapeInfo+size CalendarApptEscapeType
		mov	es:[si].MBEI_manufacturer, MANUFACTURER_ID_GEOWORKS
		mov	si, CALENDAR_ESCAPE_DATA_OFFSET
		mov	es:[si].CAET_passwdStat, CAPB_NO_PASSWORD
		mov	{TCHAR} es:[si].CAET_smsReplyPrfx, C_NULL
		mov	es:[si].CAET_userReply, CERS_NO_REPLY_YET
		mov	es:[si].CAET_replyFormat, CRSMSF_VERSIT
		mov	{TCHAR} es:[si].CAET_senderAddress, C_NULL
		mov	{TCHAR} es:[si].CAET_senderName, C_NULL
		movdw	es:[si].CAET_senderEventID, INVALID_EVENT_ID
		clr	es:[si].CAET_senderBookID
		movdw	es:[si].CAET_createdEventID, INVALID_EVENT_ID
		clr	es:[si].CAET_reserveWholeDay

		CheckHack<CAST_NEED_ACTIONS eq 0>
		clr	es:[si].CAET_apptStatus
	;
	; No error!
	;
		clc
quit:
		.leave
		ret
AllocateAndInitMBAppointment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchSenderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the sender name / number info from the
		MailboxMessage number, and store the info into
		MBAppointment struct.

CALLED BY:	(INTERNAL) CreateMBAppointmentFromSMS
PASS:		es	= segment containing MBAppointment struct
		cx:dx	= MailboxMessage
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Grab SMS number by calling MailboxGetTransAddr
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FetchSenderInfo	proc	near
		uses	ax, bx, cx, ds, si, di
		.enter
	;
	; Grab SMS number by calling MailboxGetTransAddr.
	;
		lea	di, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderAddress
		mov	ax, size SMSAddressType-size TCHAR
		clr	bx				; want the first addr
		call	MailboxGetTransAddr	; carry set if error, 
						;  ax <- 0 if message invalid,
						;  # bytes if buffer too small
						; else
						;  carry cleared,
						;  ax <- #bytes copied,
						;  null NOT copied
		jc	error
writeNull:
	;
	; Write null to buffer.
	;
DBCS <		shl	ax						>
		add	di, ax
		mov	{TCHAR} es:[di], C_NULL
	;
	; Copy the SMS number into name, in case we cannot find the
	; name in contdb.
	;
		segmov	ds, es, si
		lea	si, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderAddress
							; ds:si <- src
		lea	di, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderName
							; es:di <- dest
		push	di
		LocalCopyString				; ax destroyed,
							;  si, di adjusted
		pop	di
		mov	cx, size CAET_senderName
		call	MatchSMSNumberAndGetName	; es:di <- filled or
							;  not changed
		
		.leave
		ret
error:
EC <		tst	ax						>
EC <		WARNING_Z CALENDAR_NO_VALID_TRANS_ADDR			>
EC <		WARNING_NZ CALENDAR_TRANS_ADDR_BUFFER_TOO_SMALL		>
	;
	; Put question mark to buffer, and null terminate.
	;
		mov	{TCHAR} es:[di], C_QUESTION_MARK
		LocalNextChar	esdi
		jmp	writeNull
FetchSenderInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseVCalendarText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the block of text, knowing that the content should
		describe a VCalendar.

CALLED BY:	(INTERNAL) CreateMBAppointmentFromSMS
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if parsing is successful
			carry clear
			MBAppointment struct in ds updated
			ds:si	= points to remaining text
		if parsing fails
			carry set
			MBAppointment likely not unusable
			ds:si	= points to whatever text not read
			cx	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get the SMS prefix, and construct the SMS reply prefix.
		Read		BEGIN:VCALENDAR
		Read		VERSION:1.0
		Read		BEGIN:
		if (next value is EVENT) {
			Parse event
		} else if (next value is TODO) {
			Parse todo
		}
		Read		END:VCALENDAR
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseVCalendarText	proc	near
		uses	ax, di
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Handle SMS prefix.
	;
		call	ReadPrefixAndConstructReplyPrefix
	;
	; Search for keyword "BEGIN:"
	;
		mov	di, VKT_BEGIN_PROP
		call	SearchPropertyKeyword		; carry set if not
							; found
		jc	quit
	;
	; Consume keyword "VCALENDAR"
	;
		mov	di, VKT_VCALENDAR_VAL
		call	ConsumeKeyword			; carry set if not
							; found
		jc	quit
	;
	; Search for keyword "VERSION:"
	;
		mov	di, VKT_VERSION_PROP
		call	SearchPropertyKeyword		; carry set if not
							; found
		jc	quit
	;
	; Consume keyword "1.0"
	;
		mov	di, VKT_1_0_VAL
		call	ConsumeKeyword			; carry set if not
							; found
		jc	quit
nextProp:
	;
	; See what the next property is.
	;
		call	GetNextProperty			; ax= VersitKeywordType
		jc	quit
	;
	; Is it "BEGIN:"?
	;
		cmp	ax, VKT_BEGIN_PROP
		jne	nextProp
	;
	; We get "BEGIN:". Is it "TODO" or "EVENT"?
	;
		call	GetNextValue			; ax= VersitKeywordType
		jc	quit
		cmp	ax, VKT_EVENT_VAL
		jne	notEvent
	;
	; Parse event block.
	;
		call	ParseEventText
		jc	quit
		jmp	finishVCalendar
notEvent:
		call	ParseTodoText
		jc	quit
finishVCalendar:
	;
	; Search for keyword "END:"
	;
		mov	di, VKT_END_PROP
		call	SearchPropertyKeyword		; carry set if not
							; found
		jc	quit
	;
	; Consume keyword "VCALENDAR"
	;
		mov	di, VKT_VCALENDAR_VAL
		call	ConsumeKeyword			; carry set if not
							; found
quit:
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
ParseVCalendarText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadPrefixAndConstructReplyPrefix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the SMS prefix, and if it is in
		long-sms-prefix format, reverse the source/destination
		port to form the reply prefix.

CALLED BY:	(INTERNAL) ParseVCalendarText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		ds:si	= rest of text
DESTROYED:	nothing
SIDE EFFECTS:	
		If we find a prefix in long-sms-prefix format,
		MBAppointment would be updated with a reply prefix.

PSEUDO CODE/STRATEGY:
		The long SMS prefix looks like this	//SCKddoo<space>

		dd - destination port  (e.g. 09)
		oo - originated port (e.g. 05)

		So the reply prefix would be		//SCKoodd<space>

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

longSMSPrefixNoPorts	TCHAR	LONG_SMS_PREFIX_WITH_NO_PORTS, 0 ; //SCK

ReadPrefixAndConstructReplyPrefix	proc	near
		uses	ax, cx, di
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Compare string, and see if we see the longSMSPrefix in the
	; buffer.
	;
		; ds:si - versit text
		push	es
		segmov	es, cs, di
		mov	di, offset longSMSPrefixNoPorts   ; es:di <- text
		mov	cx, length longSMSPrefixNoPorts-1 ; for null
		call	LocalCmpStrings
		pop	es
EC <		WARNING_NE CALENDAR_SCK_PREFIX_NOT_FOUND_IN_VERSIT_TEXT	>
		jne	useDefault
	;
	; We will do no more error checking. Just construct the reply
	; prefix.
	;
	; First write the sms prefix with no port numbers.
	;
		mov	cx, CALENDAR_BOOK_SMS_PREFIX_MAX_LENGTH*size TCHAR
		lea	di, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_smsReplyPrfx
		mov	ax, VersitStringFlags<CRLF_NO, VKT_SMS_PREFIX_NO_PORTS>
		call	WriteVersitKeyword
	;
	; Write the port numbers.
	;
		add	si, size longSMSPrefixNoPorts-size TCHAR 
							; ds:si <- port string
if DBCS_PCGEOS
		mov	ax, {word} ds:[si]
		mov	{word} es:[di+4], ax
		mov	ax, {word} ds:[si+2]
		mov	{word} es:[di+6], ax
		mov	ax, {word} ds:[si+4]
		mov	{word} es:[di], ax
		mov	ax, {word} ds:[si+6]
		mov	{word} es:[di+2], ax
else
		mov	ax, {word} ds:[si]
		mov	{word} es:[di+2], ax
		mov	ax, {word} ds:[si+2]
		mov	{word} es:[di], ax
endif
	;
	; Write a space and null.
	;
		add	di, size TCHAR*4
		add	si, size TCHAR*4
		mov	{TCHAR} es:[di], C_SPACE
		LocalNextChar esdi
		mov	{TCHAR} es:[di], C_NULL
quit:
		.leave
		ret
useDefault:
		mov	cx, CALENDAR_BOOK_SMS_PREFIX_MAX_LENGTH*size TCHAR
		lea	di, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_smsReplyPrfx
		mov	ax, VersitStringFlags<CRLF_NO, VKT_SMS_REPLY_PREFIX>
		call	WriteVersitKeyword
		jmp	quit
ReadPrefixAndConstructReplyPrefix	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchPropertyBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for the property keyword in buffer. The keyword always
		starts a new line.

CALLED BY:	(INTERNAL)
PASS:		di	= VersitKeywordType, a property keyword
		ds:si	= buffer to search for
RETURN:		if found:
			clear	= cleared
			ds:si	= next char in the buffer
		if not found:
			clear	= set
			ds:si	= NULL (end of buffer)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	(*)
		if (keyword in buffer != keyword to be searched) {
			consume line
			if (EOS) {return}
			jmp (*)
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchPropertyKeyword	proc	near
		uses	ax, cx, es, di
		.enter
		Assert	segment, ds
		Assert	etype, di, VersitKeywordType
		Assert	be, di, VKT_LAST_PROPERTY
	;
	; Get the keyword we are searching for.
	;
		segmov	es, cs, ax
		mov	cx, cs:[keywordSizeTable][di]	; size of string
		dec	cx				; size, excluding NULL
		dec	cx				; size, excluding colon
DBCS <		dec	cx						>
DBCS <		dec	cx						>
		mov	di, cs:[keywordStringTable][di]	; es:di <- string
oneLine:
		; cx == size of string
		call	LocalCmpStringsNoCase		; flags set
		je	match
noMatch:
	;
	; Not match, so consume line and try again.
	;
		call	UnfoldAndConsumeLine		; carry set if EOS
		jc	quit
		jmp	oneLine
match:
	;
	; Match! ds:si adjusted after the string.
	;
		add	si, cx
	;
	; We are looking at property, and we expect a colon after any white
	; spaces.
	;
		call	ConsumeWhiteSpaces
		LocalCmpChar	ds:[si], C_COLON
		jne	noMatch
		LocalNextChar	dssi
		
		clc					; success!
quit:
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
SearchPropertyKeyword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConsumeKeyword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Consume the keyword from buffer. This routine will NOT work
		with property keyword (because they have a colon at the end,
		and the spec allows infinite amount of space between the word
		and the colon.) Use SearchPropertyKeyword for property
		keywords.

CALLED BY:	(INTERNAL)
PASS:		di	= VersitKeywordType
		ds:si	= buffer
RETURN:		if found:
			clear	= cleared
			ds:si	= next char in the buffer
		if not found:
			clear	= set
			ds:si	= next non-space char in buffer
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The keyword is expected to be next word in the buffer.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConsumeKeyword	proc	near
		uses	cx, es, di
		.enter
		Assert	segment, ds
		Assert	etype, di, VersitKeywordType
		Assert	a, di, VKT_LAST_PROPERTY
	;
	; Consume any white space first.
	;
		call	ConsumeWhiteSpaces		; carry set if EOS
		jc	quit
	;
	; Get the keyword we are searching for.
	;
		segmov	es, cs, cx
		mov	cx, cs:[keywordSizeTable][di]	; size of string
		dec	cx				; size, excluding NULL
DBCS <		dec	cx						>
		mov	di, cs:[keywordStringTable][di]	; es:di <- string
	;
	; Do compare string.
	;
		call	LocalCmpStringsNoCase		; flags set
		stc					; assume not equal
		jne	quit
	;
	; Update ds:si
	;
		add	si, cx
		clc					; error
quit:
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
ConsumeKeyword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConsumeWhiteSpaces
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Consume any white spaces from the buffer.

CALLED BY:	(INTERNAL)
PASS:		ds:si	= buffer to search for
RETURN:		if end-of-buffer
			carry	= set
		else
			carry	= cleared
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConsumeWhiteSpaces	proc	near
		.enter
start:
	;
	; Is it a null?
	;
		LocalCmpChar	ds:[si], NULL
		stc					; assume null
		je	quit				; je == jz
	;
	; A space?
	;
		LocalCmpChar	ds:[si], C_SPACE
		je	skip
	;
	; A tab?
	;
		LocalCmpChar	ds:[si], C_TAB
		clc					; assume not equal
		jne	quit
skip:
		LocalNextChar	dssi
		jmp	start
quit:
		.leave
		ret
ConsumeWhiteSpaces	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConsumeLineNoUnfold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Consume the rest of the line. Don't do any unfolding.

CALLED BY:	(INTERNAL)
PASS:		ds:si	= buffer
RETURN:		if end of buffer (NULL seen):
			carry	= set
		else
			carry	= cleared
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConsumeLineNoUnfold	proc	near
		.enter
nextChar:
	;
	; Is this a NULL?
	;
		LocalCmpChar	ds:[si], NULL
		je	nullFound
	;
	; Is this a carriage return?
	;
		LocalCmpChar	ds:[si], C_CR		; carriage return?
		je	crFound
	;
	; Check next char.
	;
		LocalNextChar	dssi
		jmp	nextChar
crFound:
lfFound:
	;
	; Skip the cariage return that we found.
	;
		LocalNextChar	dssi
	;
	; Is this a line feed?
	;
		LocalCmpChar	ds:[si], C_LF
		je	lfFound
	;
	; Is this a NULL?
	;
		LocalCmpChar	ds:[si], NULL
		je	nullFound
	;
	; Next one not null, so no error.
	;
		clc
quit:
		.leave
		ret
nullFound:
		stc					; carry set for NULL
		jmp	quit
ConsumeLineNoUnfold	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnfoldAndConsumeLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Consume the rest of the line.
		The line might be 'folded', ie. it is broken into two or more
		lines by folding technique. In that case, consume the next
		line(s) too.

CALLED BY:	(INTERNAL)
PASS:		ds:si	= buffer
RETURN:		if end of buffer (NULL seen):
			carry	= set
		else
			carry	= cleared
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Folding technique: if the start of next line is space or tab,
		the next line is considered a continuation of the current
		line.

		i.e.	CRLF + {SPACE|TAB}  <=> {SPACE|TAB}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnfoldAndConsumeLine	proc	near
		.enter
nextLine:
		call	ConsumeLineNoUnfold		; carry set if NULL
		jc	quit
	;
	; Is the next char SPACE or TAB?
	;
		LocalCmpChar	ds:[si], C_SPACE
		je	nextLine			; a space, so consume
							; this line too
		LocalCmpChar	ds:[si], C_TAB
		je	nextLine
	;
	; Done, and next char is not null.
	;
		clc
quit:
		.leave
		ret
UnfoldAndConsumeLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next property (i.e. those keywords that start the
		line and end with ':') and return the enum value.

		If the first word in the line is not a property, the next
		line will be searched.

CALLED BY:	(INTERNAL)
PASS:		ds:si	= text buffer to search
RETURN:		if property is known:
			ax	= VersitKeywordType
				  (VKT_FIRST_PROPERTY <= ax <=
				   VKT_LAST_PROPERTY)
			ds:si	= rest of text (i.e. after ':')
			carry	= cleared
		if property is not known:
			ax	= VKT_UNKNOWN_KEYWORD
			ds:si	= rest of text (i.e. after ':')
			carry	= cleared
		if no property is found in the buffer:
			ax	= VKT_UNKNOWN_KEYWORD
			ds:si	= end of buffer (NULL)
			carry	= set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if (NULL) quit

		copy the first VERSIT_PROP_KEYWORD_MAX_LENGTH-2 chars to
		buffer (if encounter ':'/';'/space/tab/null/CR  quit loop)

		consume white space if any
		read ':' or ';'
		if (failed) consume current line and try again.

		put NULL to buffer, and do string cmp.

		PS. VERSIT_PROP_KEYWORD_MAX_LENGTH-2, one char for null, one
			for ':'.
		PPS. Properties can end with a ';' too: e.g.
			DESCRIPTION;ENCODING=BLAH:this is the text

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextProperty	proc	near
		uses	cx, dx, es, di
txtBuffer	local	VERSIT_PROP_KEYWORD_MAX_LENGTH dup (TCHAR)
		.enter
	;
	; Start the loop.
	;
		segmov	es, ss, cx
oneLine:
		lea	di, ss:[txtBuffer]		; es:di <- buffer
		mov	cx, VERSIT_PROP_KEYWORD_MAX_LENGTH-2

oneChar:	; ----------------------------------------------------------
	;
	; A null means we couldn't find any property.
	;
		LocalCmpChar	ds:[si], NULL
		je	error
	;
	; If we see a carriage return, start from the next line.
	;
		LocalCmpChar	ds:[si], C_CR
		je	nextLine
	;
	; Is it a space?
	;
		LocalCmpChar	ds:[si], C_SPACE
		je	doneLoop
	;
	; Is it a tab?
	;
		LocalCmpChar	ds:[si], C_TAB
		je	doneLoop
	;
	; Is it a colon?
	;
		LocalCmpChar	ds:[si], ':'
		je	doneLoop
	;
	; Is it a semi-colon?
	;
		LocalCmpChar	ds:[si], ';'
		je	doneLoop

	;
	; OK, copy the character to buffer, and go to next.
	;
if DBCS_PCGEOS
		lodsw					; ax <- char
		stosw
else
		lodsb					; al <- char
		stosb
endif		
		loop	oneChar				; -------------------
		
doneLoop:
	;
	; Consume any white space we might have.
	;
		call	ConsumeWhiteSpaces
	;
	; Is the next char ':' or ';'??
	;
		cmp	{TCHAR} ds:[si], ':'
		je	colonFound
		cmp	{TCHAR} ds:[si], ';'
		je	colonFound

	;
	; Finish the current line, and try the next line.
	;
nextLine:
		call	UnfoldAndConsumeLine		; carry set if EOS
		jmp	oneLine
quit:
		
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
error:
	;
	; Well, nothing left to do..
	;
		mov	ax, VKT_UNKNOWN_KEYWORD
		stc
		jmp	quit
colonFound:
	;
	; Complete the buffer to have the whole property. Property strings in
	; table do NOT have colon.
	;
		LocalNextChar	dssi			; consume ':'
		mov	{TCHAR} es:[di], C_NULL
	;
	; Do binary search for the string. The table we use is
	; keywordStringTable, and we look at only the property strings.
	;
		mov	ax, VKT_FIRST_PROPERTY
		mov	dx, VKT_LAST_PROPERTY
		lea	di, ss:[txtBuffer]		; es:di <- buffer
		call	BinarySearchOnKeywordTable	; ax <-
							; VersitKeywordType
							; / VKT_UNKNOWN_KEYWORD
		clc					; no error
		jmp	quit
		
GetNextProperty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next value and return the enum value. (Value has CR
		at the end.)

		If the remaining words in the line do not make up a value,
		VKT_UNKNOWN_KEYWORD is returned. (i.e. only current line is
		searched.)

CALLED BY:	(INTERNAL)
PASS:		ds:si	= text buffer to search
RETURN:		if value is known:
			ax	= VersitKeywordType
				  (VKT_FIRST_VALUE <= ax <=
				   VKT_LAST_VALUE)
			ds:si	= rest of text (i.e. next line)
			carry	= cleared
		if value is not known:
			ax	= VKT_UNKNOWN_KEYWORD
			ds:si	= rest of text (i.e. next line)
			carry	= cleared
		if EOS encountered:
			ax	= VKT_UNKNOWN_KEYWORD
			ds:si	= end of buffer (NULL)
			carry	= set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if (NULL) quit

		consume white space if any
		copy the first VERSIT_VALUE_KEYWORD_MAX_LENGTH-1 chars to
		buffer (if encounter null/CR  quit loop)

		put NULL to buffer, and do string cmp.

		PS. VERSIT_VALUE_KEYWORD_MAX_LENGTH-1, one char for null
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextValue	proc	near
		uses	cx, dx, es, di
txtBuffer	local	VERSIT_VALUE_KEYWORD_MAX_LENGTH dup (TCHAR)
		.enter
	;
	; Start the loop.
	;
		segmov	es, ss, cx
		lea	di, ss:[txtBuffer]		; es:di <- buffer
		mov	cx, VERSIT_VALUE_KEYWORD_MAX_LENGTH-1

oneChar:	; ----------------------------------------------------------
	;
	; A null means we couldn't find any value.
	;
		LocalCmpChar	ds:[si], NULL
		je	error
	;
	; If we see a carriage return, do string search.
	;
		LocalCmpChar	ds:[si], C_CR
		je	doneLoop
	;
	; OK, copy the character to buffer, and go to next.
	;
if DBCS_PCGEOS
		lodsw					; ax <- char
		stosw
else
		lodsb					; al <- char
		stosb
endif		
		loop	oneChar				; -------------------
		
doneLoop:
	;
	; Consume any white space we might have.
	;
		call	ConsumeWhiteSpaces
	;
	; Is the next char carriage return ??
	;
		cmp	{TCHAR} ds:[si], C_CR
		je	crFound
	;
	; Finish the current line, and return error.
	;
		call	UnfoldAndConsumeLine		; carry set if EOS
error:
	;
	; Well, nothing left to do..
	;
		mov	ax, VKT_UNKNOWN_KEYWORD
		stc
quit:
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
crFound:
	;
	; Consume current line, and null terminate the value.
	;
		call	UnfoldAndConsumeLine
		mov	{TCHAR} es:[di], C_NULL
	;
	; Do binary search for the string. The table we use is
	; keywordStringTable, and we look at only the value strings.
	;
		mov	ax, VKT_FIRST_VALUE
		mov	dx, VKT_LAST_VALUE
		lea	di, ss:[txtBuffer]		; es:di <- buffer
		call	BinarySearchOnKeywordTable	; ax <-
							; VersitKeywordType
							; / VKT_UNKNOWN_KEYWORD
		clc					; no error
		jmp	quit
		
GetNextValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BinarySearchOnKeywordTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for the passed strings in the keyword table.

CALLED BY:	(INTERNAL) GetNextProperty, GetNextValue
PASS:		ax	= lowest bound in table
		dx	= highest bound in table
		es:di	= string (null terminated)
RETURN:		ax	= VersitKeywordType
		if not found:
		ax	= VKT_UNKNOWN_KEYWORD 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Remember the keyword enum are 2 apart.

		midPoint = (high + low) / 2
		if (keyword[midPoint] == string) {
			return midPoint
		}
		if (keyword[midPoint] > string) {
			high = midPoint - 2
		} else {
			low = midPoint + 2
		}
		if (high < low) {
			return NOT-FOUND
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BinarySearchOnKeywordTable	proc	near
		uses	bx, cx, dx, ds, si
		.enter
		Assert	etype, ax, VersitKeywordType
		Assert	etype, dx, VersitKeywordType
	;
	; ds <- segment of keyword table.
	;
		segmov	ds, cs, bx
	;
	; All strings are null terminated.
	;
		clr	cx				; for LocalCmpStrings
again:
	;
	; midPoint = (high + low) /2
	;
		mov	bx, ax
		add	bx, dx
		shr	bx				; bx <- midPoint
	;
	; Just in case this is not an even number.
	;
		shr	bx
		shl	bx
		Assert	etype, bx, VersitKeywordType
	;
	; keyword[midPoint] == string?
	;
		mov	si, cs:[keywordStringTable][bx]
		call	LocalCmpStringsNoCase		; (ds:si, es:di)
		je	found
		ja	bigger				
	;
	; low = midPoint + 2
	;
		mov_tr	ax, bx
		inc	ax
		inc	ax
		jmp	checkTerminate
bigger:
	;
	; high = midPoint - 2
	;
		mov	dx, bx
		dec	dx
		dec	dx
checkTerminate:
	;
	; if (low > high) --> not found, ie. if (low <= high) -> try again
	;
		cmp	ax, dx
		jle	again				; *signed* because
							; some bounds might
							; be negative
EC <		WARNING	CALENDAR_UNKNOWN_VERSIT_KEYWORD_FOUND		>
		mov	bx, VKT_UNKNOWN_KEYWORD
found:
		mov_tr	ax, bx
		.leave
		ret
BinarySearchOnKeywordTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseEventText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We found "BEGIN:EVENT", so now we are parsing the normal
		event (i.e. not to-do), and add info to the MBAppointment
		structure.

CALLED BY:	(INTERNAL) ParseVCalendarText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error
			carry set
			MBAppointment struct likely unusable
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment updated
			ds:si	= whatever not read yet
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		loop {
			get next property
			case (next property) {
			 STATUS:	consume "NEEDS ACTION"; brk;
			 DALARM:	update alarm; brk;
			 DTSTART:	update start time; brk;
			 DTEND:		update end time; brk;
			 DESCRIPTION:	update description; brk;
			 RRULE:		update repeat info; brk;
			 XNOKIAPASSWD:	update passwd info; brk;
			 END:		exit loop; brk;
			 UID:		store UID string; brk;
			 anything else:	ignore; brk;
			  (including CATEGORIES, SUMMARY, CLASS)
			}
		}
		consume "EVENT";

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseEventText	proc	near
		uses	ax, cx, es, di
mbaStructSeg	local	sptr	push	es
		.enter
		Assert	segment, es
		Assert	segment, ds
nextPropSetES:
	;
	; es <- code segment for searching.
	;
		segmov	es, cs, ax
nextProp:
	;
	; Get next property.
	;
		call	GetNextProperty			; ax= VersitKeywordType
		jc	quit
	;
	; Do we get "END:"?? (Special case because we would quit the loop.)
	;
		cmp	ax, VKT_END_PROP
		je	endFound
	;
	; Is the property being handled?
	;
		mov	di, offset eventPropHandled
		mov	cx, length eventPropHandled	; cx <- # entries
		repnz	scasw
		jnz	nextProp
	;
	; Find which routine to call.
	;
		mov	es, ss:[mbaStructSeg]		; es <- MBAppointment
		sub	di, offset eventPropHandled+size VersitKeywordType
							; di <- item that hits
		call	cs:[eventPropHandler][di]
		jnc	nextPropSetES			; restore es and look
							; again. 
quit:
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
endFound:
	;
	; After we see "END:" we should have "EVENT".
	;
		mov	di, VKT_EVENT_VAL
		call	ConsumeKeyword			; carry set if not
							; found
		jmp	quit
ParseEventText	endp

eventPropHandled	VersitKeywordType \
	VKT_DALARM_PROP,
	VKT_DESCRIPTION_PROP,
	VKT_DTEND_PROP,
	VKT_DTSTART_PROP,
	VKT_RRULE_PROP,
	VKT_STATUS_PROP,
	VKT_UID_PROP,
	VKT_X_NOKIA_CREATED_EVENT_PROP,
	VKT_X_NOKIA_PASSWD_PROP,
	VKT_X_NOKIA_RESERVED_DAYS_PROP
;
; Prototype for all property handlers:
;
; Pass:		es	= segment containing MBAppointment struct
;		ds:si	= SMS text buffer
; Return:	if error
;			carry set
;		else
;			carry cleared
;
eventPropHandler	nptr \
	offset	HandleDAlarmProp,	; VKT_DALARM_PROP,       
	offset	HandleDescriptionProp,	; VKT_DESCRIPTION_PROP,  
	offset	HandleEndTimeProp,	; VKT_DTEND_PROP,        
	offset	HandleStartTimeProp,	; VKT_DTSTART_PROP,      
	offset	HandleRepeatRuleProp,	; VKT_RRULE_PROP,        
	offset	HandleStatusProp,	; VKT_STATUS_PROP,
	offset	HandleUIDProp,		; VKT_UID_PROP,
	offset	HandleCreatedEventProp,	; VKT_X_NOKIA_CREATED_EVENT_PROP
	offset	HandlePasswordProp,	; VKT_X_NOKIA_PASSWD_PROP
	offset	HandleReservedDaysProp	; VKT_X_NOKIA_RESERVED_DAYS_PROP

CheckHack<length eventPropHandled eq length eventPropHandler>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseTodoText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We found "BEGIN:TODO", so now we are parsing the todo item
		(i.e. not event), and add info to the MBAppointment
		structure.

CALLED BY:	(INTERNAL) ParseVCalendarText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error
			carry set
			MBAppointment struct likely unusable
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment updated
			ds:si	= whatever not read yet
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		loop {
			get next property
			case (next property) {
			 STATUS:	consume "NEEDS ACTION"; brk;
			 DESCRIPTION:	update description; brk;
			 XNOKIAPASSWD:	update passwd info; brk;
			 END:		exit loop; brk;
			 anything else:	ignore; brk;
			  (including CATEGORIES, SUMMARY, CLASS, UID)
			}
		}
		consume "TODO";

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseTodoText	proc	near
		uses	ax, cx, es, di
mbaStructSeg	local	sptr	push	es
		.enter
		Assert	segment, es
		Assert	segment, ds
nextPropSetES:
	;
	; es <- code segment for searching.
	;
		segmov	es, cs, ax
nextProp:
	;
	; Get next property.
	;
		call	GetNextProperty			; ax= VersitKeywordType
		jc	quit
	;
	; Do we get "END:"?? (Special case because we would quit the loop.)
	;
		cmp	ax, VKT_END_PROP
		je	endFound
	;
	; Is the property being handled?
	;
		mov	di, offset todoPropHandled
		mov	cx, length todoPropHandled	; cx <- # entries
		repnz	scasw
		jnz	nextProp
	;
	; Find which routine to call.
	;
		mov	es, ss:[mbaStructSeg]		; es <- MBAppointment
		sub	di, offset todoPropHandled+size VersitKeywordType
							; di <- item that hits
		call	cs:[todoPropHandler][di]
		jnc	nextPropSetES			; restore es and look
							; again. 
quit:
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
endFound:
	;
	; After we see "END:" we should have "TODO".
	;
		mov	di, VKT_TODO_VAL
		call	ConsumeKeyword			; carry set if not
							; found
		jmp	quit
ParseTodoText	endp

todoPropHandled	VersitKeywordType \
	VKT_DESCRIPTION_PROP,
	VKT_STATUS_PROP,
	VKT_UID_PROP,
	VKT_X_NOKIA_CREATED_EVENT_PROP,
	VKT_X_NOKIA_PASSWD_PROP
;
; Prototype for all property handlers:
;
; Pass:		es	= segment containing MBAppointment struct
;		ds:si	= SMS text buffer
; Return:	if error
;			carry set
;		else
;			carry cleared
;
todoPropHandler	nptr \
	offset	HandleDescriptionProp,	; VKT_DESCRIPTION_PROP,  
	offset	HandleStatusProp,	; VKT_STATUS_PROP,       
	offset	HandleUIDProp,		; VKT_UID_PROP,
	offset	HandleCreatedEventProp,	; VKT_X_NOKIA_CREATED_EVENT_PROP
	offset	HandlePasswordProp	; VKT_X_NOKIA_PASSWD_PROP

CheckHack<length todoPropHandled eq length todoPropHandler>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleDAlarmProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "DALARM:" property.

CALLED BY:	(INTERNAL) ParseEventText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		carry	= cleared
		MBAppointment updated
		ds:si	= whatever not read yet

PSEUDO CODE/STRATEGY:
		The alarm date/time is encoded in ISO8601 format.

		Calendar only understands alarm in terms of offset of
		minutes from start time (e.g. 5 mins before start), so
		if start time is not specified at this moment, we
		assume alarm time == start time.

		If alarm property is not valid, use start time as
		alarm time. (i.e. no error ever)

		if (eventTime not specified yet) {
			offset = 0
			jmp record
		}
		call CalculateAlarmPrecedeMins
		create ax <- MBAlarmInfo
		store in MBAppointment struct


		FileTime:
			FT_HOUR:5
			FT_MIN:6
			FT_2SEC:5

		MBAlarmInfo:
			MBAI_TYPE MBAlarmIntervalType:2
			MBAI_HAS_ALARM:1
			MBAI_INTERVAL:13

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleDAlarmProp	proc	near
		uses	ax, bx, cx, dx, bp
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Get alarm date / time.
	;
		call	GetFileDateTimeFromISOString	; dx <- FileDate,
							; cx <- FileTime
		jc	useStartTime
	;
	; Is start time recorded yet? If not, we cannot find the alarm
	; offset, and we assume start time.
	;
		mov	ax, es:[MBA_start].FDAT_date	; ax <- eventDate
		cmp	ax, MB_NO_TIME
EC <		WARNING_E CALENDAR_START_TIME_NOT_FOUND_BEFORE_ALARM	>
		je	useStartTime
	;
	; Calculate the alarm offset, in minute.
	;
		mov	bx, es:[MBA_start].FDAT_time	; bx <- eventTime
		xchg	cx, dx				; cx <- alarmDate,
							;  dx <- alarmTime
		call	CalculateTimeDiffInMinutes	; ax <- # min,
							;  bx, cx, dx destroyed

recordAlarm:
	;
	; ax == interval in minutes
	;
		ornf	ax, MBAlarmInfo<MBAIT_MINUTES, 1, 0>
		mov	es:[MBA_alarmInfo], ax
	;
	; Consume the rest of line.
	;
		call	UnfoldAndConsumeLine		; carry set/cleared

		.leave
		ret
useStartTime:
		clr	ax				; offset = 0
		jmp	recordAlarm
HandleDAlarmProp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateTimeDiffInMinutes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the difference of two FileDate/Time combinations,
		in minutes.

CALLED BY:	(INTERNAL) HandleDAlarmProp
PASS:		ax	= Event FileDate
		bx	=	FileTime
		cx	= Alarm FileDate
		dx	=	FileTime
RETURN:		ax	= (Event - Alarm time), in minutes
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/21/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateTimeDiffInMinutes	proc	near
		uses	si, di, bp
		.enter
		Assert	record, ax, FileDate
		Assert	record, bx, FileTime
		Assert	record, cx, FileDate
		Assert	record, dx, FileTime
	;
	; Event time.
	;
		mov_tr	si, ax			; si <- event date
		
		mov_tr	ax, bx			; ax <- event time
		call	BreakUpFileTime		; ah / al <- event hr/min

		xchg	cx, ax			; ch / cl <- event hr/min (*)
						;  ax <- alarm date
	;
	; Alarm date.
	;
		call	BreakUpFileDateFar	; ax / bh / bl <- alarm y/m/d

		mov_tr	di, ax			; di <- alarm year (*)
	;
	; Alarm time.
	;
		mov_tr	ax, dx			; ax <- alarm time
		call	BreakUpFileTime		; ah / al <- alarm hr/min
		xchg	bx, ax			; bh / bl <- alarm hr/min (*)
						;  ah / al <- alarm m/d (*)
	;
	; Event date.
	;
		push	ax, bx

		mov_tr	ax, si			; ax <- event date
		call	BreakUpFileDateFar	; ax / bh / bl <- event y/m/d
		mov_tr	bp, ax			; bp <- event year (*)
		mov	dx, bx			; dh / dl <- event m/d (*)
		
		pop	ax, bx			; ah / al <- alarm m/d 
						;  bh / bl <- alarm hr/min
		
	; di / ah / al / bh / bl = alarm year, month, day, hour, min
	; bp / dh / dl / ch / cl = event year, month, day, hour, min

		call	CalculateAlarmPrecedeMins	; ax <- # minutes
		
		.leave
		ret
CalculateTimeDiffInMinutes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakUpFileTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break up a FileTime into hour/min.

CALLED BY:	(INTERNAL) CalculateTimeDiffInMinutes
PASS:		ax	= FileTime
RETURN:		ah	= Hour (0-23)
		al	= Minute (0-59)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		FileTime	record
		    FT_HOUR:5,	; hour (24-hour clock)
		    FT_MIN:6,	; minute
		    FT_2SEC:5,	; 2-second (0-29 giving 0-58 seconds..)
		FileTime	end

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/21/97    	Initial version (modified from
					LocalFormatFileDateTime)
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakUpFileTime	proc	near
		uses	cx
		.enter

		mov	cx, ax
		CheckHack <offset FT_HOUR + width FT_HOUR eq width FileTime>

		shr     ax, offset FT_HOUR
EC <		cmp	al, 23						>
EC <		ERROR_A	CALENDAR_DATE_TIME_ILLEGAL_HOUR			>

		xchg	ax, cx				; ax <- FileTime
							;  cl <- hour

		andnf   ax, mask FT_MIN
		shr     ax, offset FT_MIN		; al <- minutes
EC <		cmp	al, 59						>
EC <		ERROR_A	CALENDAR_DATE_TIME_ILLEGAL_MINUTE		>

		mov	ah, cl				; ah <- hour
		
		.leave
		ret
BreakUpFileTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleDescriptionProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "DESCRIPTION:" property.

CALLED BY:	(INTERNAL) ParseEventText, ParseToDoText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error
			carry set
			MBAppointment struct likely unusable
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment updated
			ds:si	= whatever not read yet

PSEUDO CODE/STRATEGY:
		Read in the text string til the end of line, and put them
		into MBA_description filed of the struct.

		We might have to unfold the line too...

		Folding technique: if the start of next line is space or tab,
		the next line is considered a continuation of the current
		line.

		i.e.	CRLF + {SPACE|TAB}  <=> {SPACE|TAB}

		We read at most MAX_TEXT_FIELD_LENGTH-1 chars.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleDescriptionProp	proc	near
		uses	ax, cx, dx, di
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Description type is geos text.
	;
		mov	es:[MBA_descType], MBADT_GEOS_TEXT
	;
	; es:di <- destination string
	;
		mov	di, offset MBA_description
	;
	; cx: character counter
	;
		mov	cx, MAX_TEXT_FIELD_LENGTH-1	; limit of how much
							; to write
doLine:
	;
	; Copy one line.
	;
		call	CopyOneLineEscapedString	; cx, si, di adjusted,
							; carry set if NULL.
		jc	done
		jcxz	bufferFull
	;
	; Should we unfold the line? Is the next char a space/tab?
	;
		LocalCmpChar	ds:[si], C_SPACE
		je	doLine
		LocalCmpChar	ds:[si], C_TAB
		je	doLine
done:
	;
	; Null-terminate the description.
	;
		clr	ax
SBCS <		stosb							>
DBCS <		stosw							>
	;
	; Calculate size of chars we've written.
	; cx == (MAX_TEXT_FIELD_LENGTH-1) - (# char we've written - 1 for null)
	; so (# char) = MAX_TEXT_FIELD_LENGTH - cx
	;	      = -(cx - MAX_TEXT_FIELD_LENGTH)
	;	      = NOT (cx - MAX_TEXT_FIELD_LENGTH) + 1
	;             = NOT (cx - MAX_TEXT_FIELD_LENGTH - 1)
	;	      = NOT (cx - (MAX_TEXT_FIELD_LENGTH + 1)
	;		
		sub	cx, MAX_TEXT_FIELD_LENGTH+1
		not	cx
DBCS <		shl	cx						>
		mov	es:[MBA_descSize], cx
	;
	; No error
	;
		clc
		.leave
		ret
bufferFull:
	;
	; Buffer is full. Consume the rest of line.
	;
		call	UnfoldAndConsumeLine
		jmp	done
HandleDescriptionProp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyOneLineEscapedString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do string copy, and stop at C_CR/LF. The src string might be
		escaped by backslash.

CALLED BY:	(INTERNAL) HandleDescriptionProp
PASS:		ds:si	= source string
		es:di	= destination string
		cx	= max # of char to write
RETURN:		cx	= # char left in buffer,
		si, di adjusted to end of string.
		if NULL found:
			carry set
		else
			carry cleared
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		All ';'/'\' chars are escaped by '\'.

		We should translate tabs to spaces too, because foam
		underlined text cannot have tabs.

		loop {
			case (next char):
			 NULL {return}
			 CR {consume LF, return}
			 if (backslash found before) {
				add this char no matter what
			 }
			 '\': {backslash found; jmp next char}
			 others: {add this char}
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyOneLineEscapedString	proc	near
		uses	ax, dx
		.enter
	;
	; dx: Boolean: is backslash escape found?
	;
		clr	dx
nextChar:
	;
	; Is this a NULL?
	;
SBCS <		lodsb							>
DBCS <		lodsw							>
		LocalCmpChar	ax, NULL
		je	nullFound
	;
	; Is this a carriage return?
	;
		LocalCmpChar	ax, C_CR
		je	crFound
	;
	; Is this a tab?
	;
		LocalCmpChar	ax, C_TAB
		jne	notTab
		LocalLoadChar	ax, C_SPACE		; replace it by space
notTab:
	;
	; If backslash escape is encountered, take the next char as-is.
	;
		tst	dx
		jnz	addChar
	;
	; Is this a backslash?
	;
		LocalCmpChar	ax, C_BACKSLASH
		jne	addChar
	;
	; This is a backslash, so whatever character that comes next would go
	; to the text (including ';' and '\'.)
	;
		mov	dx, TRUE			; escape found
		jmp	nextChar
addChar:
	;
	; Write the char to structure.
	;
SBCS <		stosb							>
DBCS <		stosw							>
		clr	dx				; no escape now
	;
	; Is buffer full?
	;
		loop	nextChar			; -----------------

		clc					; no error
quit:
		.leave
		ret
crFound:
	;
	; Consume the rest of line.
	;
		LocalPrevChar	dssi			; put back the C_CR
		call	ConsumeLineNoUnfold		; carry set if NULL
		jmp	quit
nullFound:
	;
	; Signal error.
	;
		stc
		jmp	quit
CopyOneLineEscapedString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleStartTimeProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "DTSTART:" property.

CALLED BY:	(INTERNAL) ParseEventText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error
			carry set
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment updated
			ds:si	= whatever not read yet

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleStartTimeProp	proc	near
		uses	cx, dx
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Parse iso string, and get FileDate / FileTime.
	;
		call	GetFileDateTimeFromISOString	; dx <- FileDate,
							; cx <- FileTime
		jc	quit
	;
	; Fill them into MBAppointment struct.
	;
		mov	es:[MBA_start].FDAT_date, dx
		mov	es:[MBA_start].FDAT_time, cx
		clc					; no error
quit:
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
HandleStartTimeProp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleEndTimeProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "DTEND:" property.

CALLED BY:	(INTERNAL) ParseEventText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error
			carry set
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment updated
			ds:si	= whatever not read yet

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleEndTimeProp	proc	near
		uses	cx, dx
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Parse iso string, and get FileDate / FileTime.
	;
		call	GetFileDateTimeFromISOString	; dx <- FileDate,
							; cx <- FileTime
		jc	quit
	;
	; Fill them into MBAppointment struct.
	;
		mov	es:[MBA_end].FDAT_date, dx
		mov	es:[MBA_end].FDAT_time, cx
		clc					; no error
quit:
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
HandleEndTimeProp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileDateTimeFromISOString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the iso8601 string, and return date/time as
		FileDate/FileTime.

CALLED BY:	(INTERNAL) HandleStartTimeProp, HandleEndTimeProp
PASS:		ds:si	= SMS text buffer
RETURN:		if successful
			carry cleared
			ds:si	= next char after string
			dx	= FileDate
			cx	= FileTime
		else
			carry set
			ds:si	= whatever not read
			cx, dx destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Use LocalCustomParseDateTime to decypher the date/time
		string. It looks like this..  19961121T160000

		The custom format string is iso8601FormatString.

		There might be a ';' after the string, so if we see ';',
		erase it.

		If the parse fails, we might have just the date
		string. It looks like this..  19961121

		That custom format string is iso8601DateFormatString.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileDateTimeFromISOString	proc	near
		uses	ax, bx, ds, es, di
dateTimeString	local	ISO8601_DATE_TIME_STRING_LENGTH+1 dup (TCHAR)
		.enter
	;
	; Consume any white spaces.
	;
		call	ConsumeWhiteSpaces
		jc	quit
	;
	; Copy the iso8601 string to local.
	;
		segmov	es, ss, di
		lea	di, ss:[dateTimeString]
		mov	cx, ISO8601_DATE_TIME_STRING_LENGTH
		call	CopyOneLineEscapedString	; carry set if NULL
		jc	quit
	;
	; Do we have ';' as last char? If so, discard it.
	;
		cmp	{TCHAR} es:[di-size TCHAR], ';'
		jne	notSemiColon

		LocalPrevChar	esdi
notSemiColon:
	;
	; Null terminate string.
	;
		mov	{TCHAR} es:[di], C_NULL		; null terminated
	;
	; es:di <- string to parse.
	;
		lea	di, ss:[dateTimeString]
	;
	; ds:si <- format string.
	;
		push	si
		segmov	ds, cs, si
		mov	si, offset iso8601FormatString
	;
	; Parse date time!
	;
		call	LocalCustomParseDateTime; ax <- year, bl <- month,
						; bh <- day, ch <- hour,
						; dl <- min, dh <- sec,
						; carry *clear* if error
		cmc
		pop	si
		jnc	continue
	;
	; If the first parse is bad, let's try another format string.
	;
		push	si
		mov	si, offset iso8601DateFormatString
		call	LocalCustomParseDateTime; ax <- year, bl <- month,
						; bh <- day, ch <- -1,
						; dl <- -1, dh <- -1,
						; carry *clear* if error
		cmc
		pop	si
		jc	quit
continue:
	;
	; Get FileDate FileTime records from the date/time.
	;
		call	CreateFileDateTimeRecords	; dx <- FileDate,
							; cx <- FileTime
		
		clc					; no error
quit:
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
GetFileDateTimeFromISOString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleRepeatRuleProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "RRULE:" property.

CALLED BY:	(INTERNAL) ParseEventText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error
			carry set
			MBAppointment struct not changed
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment updated
			ds:si	= whatever not read yet
DESTROY:	nothing

PSEUDO CODE/STRATEGY:
		The possible values are:

			D1			daily
			W1			weekly
			M1			monthly
			Y1			yearly
			W2			every other week
			W1 MO TU WE TH FR	working day

		followed by:

			#0			forever
			19970701Txxxxxx		until date

		e.g.	D1 #0
			W2 19970701T000000
			W1 MO TU WE TH FR #0
			W1 MO TU WE TH FR 19970701T000000

		To parse the first part: take the first three chars,
		and everything else until we get a '#' or a number.
		(Take a max of VERSIT_REPEAT_RULE_MAX_LENGTH chars)

		Add a space, null terminate it, and do a binary
		search. (see mainVersitStrings.asm for the rules)

		For the second part, if we see "#?" we assume repeat
		forever. Otherwise, parse a date/time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleRepeatRuleProp	proc	near
		uses	ax, cx, dx, di
ruleBuffer	local	VERSIT_REPEAT_RULE_MAX_LENGTH+1 dup (TCHAR) ; buffer
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Clear white space.
	;
		call	ConsumeWhiteSpaces
	;
	; Get the first three chars into local buffer.
	;
		push	es
		
		segmov	es, ss, ax			; es:di <- buffer
		lea	di, ss:[ruleBuffer]

		mov	cx, VERSIT_REPEAT_RULE_MIN_LENGTH-1	; 4-1=3
firstPart:
		LocalGetChar	ax, dssi		; si advanced
		LocalPutChar	esdi, ax
		loop	firstPart
	;
	; We take at most VERSIT_REPEAT_RULE_MAX_LENGTH-3 chars.
	;
		mov	cx, VERSIT_REPEAT_RULE_MAX_LENGTH-\
				VERSIT_REPEAT_RULE_MIN_LENGTH
secondPart:
	;
	; Get the rest as long as they are not '#' or digits.
	;
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, C_NUMBER_SIGN
		je	firstPartTerminated
SBCS <		clr	ah				; LocalGetChar	>
							; doesn't clear ah
		call	LocalIsDigit			; nz if digit
		jnz	firstPartTerminated

		LocalPutChar	esdi, ax
		loop	secondPart
		
firstPartTerminated:
	;
	; Unread the last chars.
	;
		LocalPrevChar	dssi
	;
	; Null terminate.
	;
		LocalClrChar	es:[di]
	;
	; Do a search on keyword table.
	;
		lea	di, ss:[ruleBuffer]		; es:di <- buffer
		mov	ax, VKT_FIRST_REPEAT_RULE
		mov	dx, VKT_LAST_REPEAT_RULE
		call	BinarySearchOnKeywordTable	; ax <-
							;  VersitKeywordType
		pop	es
	;
	; Did we find something?
	;
		cmp	ax, VKT_UNKNOWN_KEYWORD
		stc					; assume error
		je	quit				; je == jz
	;
	; Get the corresponding MBRepeatInterval
	;
		mov_tr	di, ax
		sub	di, VKT_FIRST_REPEAT_RULE
		mov	ax, cs:[repeatIntervalTable][di]
	;
	; Fill in struct.
	;
		mov	es:[MBA_repeatInfo], CALENDAR_REPEAT_INFO_OFFSET
		mov	di, CALENDAR_REPEAT_INFO_OFFSET
		mov	es:[di].MBRI_interval, ax
		clr	es:[di].MBRI_numExceptions
	;
	; Duration. Do we have repeat forever "#0" or an until-date?
	; (As you can see, I am only looking for a #, because responder won't
	; generate any other pattern.)
	;
		call	ConsumeWhiteSpaces
		LocalCmpChar	ds:[si], C_NUMBER_SIGN
		jne	getUntilDate
		
		CheckHack<MBRD_FOREVER eq 0>
		clr	es:[di].MBRI_duration
		clr	es:[di].MBRI_durationData
		clc					; no error
quit:
		
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>

		.leave
		ret
getUntilDate:
	;
	; Possibly we found an until date in versit format. So parse it, and
	; fill the info to MBAppointment struct.
	;
		; ds:si == versit buffer
		; es:di == MBRepeatInterval
		call	GetFileDateTimeFromISOString	; dx <- FileDate,
							; cx <- FileTime
							; carry set if error
		jc	quit
		mov	es:[di].MBRI_duration, MBRD_UNTIL
		mov	es:[di].MBRI_durationData.MBRDD_until, dx ; file date
		jmp	quit
HandleRepeatRuleProp	endp

CheckHack< (VKT_LAST_REPEAT_RULE-VKT_FIRST_REPEAT_RULE+2) eq \
	   ((length repeatIntervalTable)*2) >

repeatIntervalTable	MBRepeatInterval \
	MBRepeatInterval<0, 0, 0, MBRIT_DAILY>,		; VKT_DAILY_RULE
	MBRepeatInterval<0, 0, 0, MBRIT_MONTHLY_DATE>,	; VKT_MONTHLY_RULE
	MBRepeatInterval<0, 0, 0, MBRIT_WEEKLY>,	; VKT_WEEKLY_RULE
	MBRepeatInterval<0, 0, 0, MBRIT_MON_TO_FRI>,	; VKT_WORKING_DAYS_RULE
	MBRepeatInterval<0, 0, 1, MBRIT_WEEKLY>,	; VKT_BIWEEKLY_RULE
	MBRepeatInterval<0, 0, 0, MBRIT_YEARLY_DATE>	; VKT_YEARLY_RULE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleStatusProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "STATUS:" property.

CALLED BY:	(INTERNAL) ParseEventText, ParseToDoText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error
			carry set
			MBAppointment struct not changed
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment struct not changed (nothing to change)
			ds:si	= whatever not read yet
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		parse status.
		insist it being "accepted", "declined", "deleted",
		"need actions" or "changed".
		Fill in the MBAppointment escape struct.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleStatusProp	proc	near
		uses	ax, cx, di
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Get next value.
	;
		call	GetNextValue			; ax <-
							; VersitKeywordType,
							; carry set if error
		jc	quit
	;
	; Do we handle the value?
	;
		push	es
		segmov	es, cs, cx			; es:di <- table
		mov	di, offset statusKeywordsHandled
		mov	cx, length statusKeywordsHandled ; cx <- # entries
		repnz	scasw
		pop	es

		stc					; assume none found
		jnz	quit
	;
	; Find the corresponding CalendarApptStatusType.
	;
		sub	di, offset statusKeywordsHandled+size VersitKeywordType
							; di <- item that hits
		mov	cx, cs:[statusValueTable][di]	; cx <-
							;CalendarApptStatusType
		Assert	etype, cx, CalendarApptStatusType
	;
	; Store the status type into MBAppointment escape type.
	;
		mov	di, CALENDAR_ESCAPE_DATA_OFFSET
		mov	es:[di].CAET_apptStatus, cx
	;
	; Also, if the status is CAST_ACCEPTED or CAST_DECLINED, write
	; CAET_userReply CERS_EVENT_ACCEPTED or CERS_EVENT_DENIED.
	;
		cmp	cx, CAST_ACCEPTED
		mov	al, CERS_EVENT_ACCEPTED
		je	setUserStatus

		cmp	cx, CAST_DECLINED
		mov	al, CERS_EVENT_DENIED
		jne	done
setUserStatus:
		mov	es:[di].CAET_userReply, al
done:
	;
	; No error.
	;
		clc
quit:
EC <		WARNING_C CALENDAR_POSSIBLE_PARSING_SMS_ERROR		>
		.leave
		ret
HandleStatusProp	endp

statusKeywordsHandled VersitKeywordType \
	VKT_ACCEPTED_VAL,
	VKT_CHANGED_VAL,
	VKT_TEXT_CHANGED_VAL,
	VKT_DECLINED_VAL,
	VKT_DELETED_VAL,
	VKT_NEEDS_ACTION_VAL

statusValueTable CalendarApptStatusType \
	CAST_ACCEPTED,		; VKT_ACCEPTED_VAL
	CAST_CHANGED,		; VKT_CHANGED_VAL
	CAST_TEXT_CHANGED,	; VKT_TEXT_CHANGED_VAL
	CAST_DECLINED,		; VKT_DECLINED_VAL
	CAST_DELETED,		; VKT_DELETED_VAL
	CAST_NEED_ACTIONS	; VKT_NEEDS_ACTION_VAL


CheckHack<length statusKeywordsHandled eq length statusValueTable>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleUIDProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "UID:" property.

CALLED BY:	(INTERNAL) ParseEventText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error
			carry set
			MBAppointment struct not changed
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment updated
			ds:si	= whatever not read yet
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If the UID string is "0", that means a human readable
		SMS should be used for reply. Mark that as such.
		Otherwise, versit format should be used.

		If the UID string starts with "9000i-",
		(ie. keyword VKT_LIZZY_UID_PREFIX) then the UID should
		look like this:

			UID:9000i-123556-5

		the second part being sender's event ID, the third
		part being sender's book ID. Parse them and put into
		escape info. (CAET_senderEventID / CAET_senderBookID)

		If the UID string is not "0", and doesn't start with
		"9000i", then it is not sent from a responder.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleUIDProp	proc	near
		uses	ax, cx, dx, di
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Should we generate human readable reply or versit reply? Depends on
	; UID string.
	;
		mov	al, CRSMSF_VERSIT		; assume versit format
if DBCS_PCGEOS
		cmp	{TCHAR} ds:[si], DONT_REPLY_IN_VERSIT_UID_TOKEN
		jne	useVersit
		cmp	{TCHAR} ds:[si+2], C_CR
		jne	useVersit
else
		cmp	{word} ds:[si], \
			(C_CR shl 8) or DONT_REPLY_IN_VERSIT_UID_TOKEN
		jne	useVersit
endif
		mov	al, CRSMSF_PLAIN_READABLE
useVersit:
		mov	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_replyFormat, al
	;
	; Analyze the string again, if we reply in versit text.
	;
		cmp	al, CRSMSF_VERSIT
		jne	quit
	;		
	; Do we have "9000i-" as UID prefix?
	;
		mov	di, VKT_LIZZY_UID_PREFIX
		call	ConsumeKeyword			; carry clear if found,
							;  ds:si <- next char,
							;  else carry set
		jc	notLizzy
	;
	; Extract the first number (dword, sender's event ID)
	;
		call	ExtractDWordFromUID		; ds:si <- next char,
							;  dxax <- dword, 
							;  else carry set
		jc	notLizzy
	;
	; Write event ID to escape info.
	;
		movdw	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderEventID, \
				dxax
	;
	; Read dash.
	;
		mov	di, VKT_DASH
		call	ConsumeKeyword			; carry clear if found,
							;  ds:si <- next char,
							;  else carry set
		jc	notLizzy
	;
	; Extract the second number (word, sender's book ID)
	;
		call	ExtractDWordFromUID		; ds:si <- next char,
							;  dxax <- dword, 
							;  else carry set
		jc	notLizzy
	;
	; Make sure it is a word.
	;
		cmp	dx, 0
		jne	notLizzy
	;
	; Write book ID to escape info.
	;
		mov	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderBookID, ax
quit:
	;
	; Consume rest of line.
	;
		call	UnfoldAndConsumeLine

		clc					; no error. (UID
							; not lizzy style
							; is not an error)
		.leave
		ret
notLizzy:
	;
	; Write sender Event ID = invalid.
	;
		movdw	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderEventID, \
				INVALID_EVENT_ID
EC <		WARNING CALENDAR_NOT_LIZZY_STYLE_UID			>
		jmp	quit
		
HandleUIDProp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractDWordFromUID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a DWord from the ascii string which might be
		terminated from non-numeric. (e.g. 1812-blah blah)

CALLED BY:	(INTERNAL) HandleUIDProp
PASS:		ds:si	= text buffer
RETURN:		carry set if the first character is not a numeric or
		if the number is larger than a dword:
			dx,ax	= destroyed
			ds:si	= whatever unread
		else:
			dxax	= dword
			ds:si	= character after the dword
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Copy at most 14 numerics from text to local buffer
		(2^32 = 4294967296, 10 digits long)
		null terminate
		call UtilAsciiToHex32
		(if the number is too long, the routine will return
		overflow error)


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 7/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtractDWordFromUID	proc	near
asciiBuffer	local	15 dup (TCHAR)		
		uses	cx, ds, es, di
		.enter
		
		segmov	es, ss, cx
		lea	di, ss:[asciiBuffer]		; es:di <- buffer
	;
	; Copy at most 14 chars.
	;
		mov	cx, (length asciiBuffer-1)	; save space for NULL
oneChar:
	;
	; Is the next char a digit?
	;
SBCS <		clr	ah				; LocalGetChar	>
							;  doesn't clear ah
		LocalGetChar	ax, dssi		; si advanced
		call	LocalIsDigit			; z flag clear if
							;  valid digit
		jz	notDigit
	;
	; Copy digit to buffer.
	;
		LocalPutChar	esdi, ax		; di advanced
		loop	oneChar
notDigit:
	;
	; Un-read the last character.
	;
		LocalPrevChar	dssi
	;
	; Null terminate the string.
	;
		LocalClrChar	es:[di]
	;
	; If nothing has been copied to buffer, that means the first
	; character of text is not a digit, and we return error.
	;
		cmp	cx, (length asciiBuffer-1)
		stc					; assume error
		je	quit
	;
	; Translate the ascii buffer to hex.
	;
		push	si
		segmov	ds, ss, si
		lea	si, ss:[asciiBuffer]		; ds:si <- buffer
		call	UtilAsciiToHex32		; carry set if error,
							;  else
							;  dxax <- dword 
		pop	si
quit:
EC <		WARNING_C CALENDAR_EXTRACT_DWORD_FAILED			>
		.leave
		ret
ExtractDWordFromUID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleCreatedEventProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "X-NOKIA-CREATED-EVENT:" property.

CALLED BY:	(INTERNAL) ParseEventText, ParseToDoText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error / password not correct
			carry set
			MBAppointment struct not changed
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment updated
			ds:si	= whatever not read yet
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The property specifies the unique event ID of the
		created event at the recipient's device.

		Just fetch the number and put into MBAppointment
		escape info.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/10/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleCreatedEventProp	proc	near
		uses	ax, dx
		.enter
	;
	; Extract the number.
	;
		call	ExtractDWordFromUID		; ds:si <- next char,
							;  dxax <- dword, 
							;  else carry set
		jc	quit
	;
	; Store the number in MBAppointment escpae info.
	;
		movdw	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_createdEventID, \
				dxax
quit:
		.leave
		ret
HandleCreatedEventProp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandlePasswordProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "X-NOKIA-PASSWD:" property.

CALLED BY:	(INTERNAL) ParseEventText, ParseToDoText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error / password not correct
			carry set
			MBAppointment struct not changed
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment updated
			ds:si	= whatever not read yet
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Password init file category: calendarCategory
		Password init file key: passwdInitKey

		If this is a reply {
			mark reply-has-password
			quit
		}
		Read in versit password.
		Read in init file password (ie. real password).
		if (real password doesn't exist) {
			password valid
		}
		if (strings don't match) {
			password invalid
		} else {
			password valid
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HandlePasswordProp	proc	near
		uses	bx, cx, dx, ds, es, di
mbaStructSeg	local	sptr	push	es
versitPass	local	CALENDAR_PASSWORD_LENGTH+1 dup (TCHAR)
initPasswd	local	CALENDAR_PASSWORD_LENGTH+1 dup (TCHAR)
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Check the status. If this is not "need-actions", mark
	; reply-or-update-has-password.
	;
		cmp	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_apptStatus,\
				CAST_NEED_ACTIONS
		je	notReply
		mov	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_passwdStat,\
				CAPB_REPLY_OR_UPDATE_HAS_PASSWORD
		clc
		jmp	quit
notReply:
	;
	; Read in the password.
	;
		segmov	es, ss, di
		lea	di, ss:[versitPass]
		mov	cx, CALENDAR_PASSWORD_LENGTH
		call	CopyOneLineEscapedString	; cx, si, di adjusted,
							; carry set if NULL.
		jc	quit
		mov	{TCHAR} es:[di], C_NULL		; null terminated
	;
	; Get real password from init file.
	;
		push	si
		push	bp
		GetResourceSegmentNS	dgroup, ds
		mov	cx, ds
		mov	si, offset calendarCategory	; ds:si <- category
		mov	dx, offset passwdInitKey	; cx:dx <- key
		lea	di, ss:[initPasswd]		; es:di <- buffer
		mov	bp, InitFileReadFlags<IFCC_INTACT, 0, 0, \
					      size initPasswd>
		call	InitFileReadString		; carry set if error,
							;  else cx <- # char,
							;       es:di filled
							; bx destroyed
		pop	bp
EC <		WARNING_C CALENDAR_PASSWORD_NOT_SET			>
		jc	passwdValid			; passwd not found,
							;  considered valid
		jcxz	passwdValid			; null password,
							;  considered valid
	;
	; Compare string.
	;
		segmov	ds, ss, si
		lea	si, ss:[versitPass]		; ds:si <-versit passwd
		clr	cx				; null terminated
		call	LocalCmpStrings
	;
	; Write the password validity to the appointment struct.
	;
EC <		WARNING_NE CALENDAR_PASSWORD_INVALID			>
		mov	cl, CAPB_PASSWORD_INVALID
		stc					; assume error
		jne	passwdInvalid			; (looking at z flag)
passwdValid:
		mov	cl, CAPB_PASSWORD_VALID
		clc					; no error
passwdInvalid:
		mov	es, ss:[mbaStructSeg]
		mov	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_passwdStat, cl
		pop	si
quit:
		.leave
		ret
HandlePasswordProp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleReservedDaysProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "X-NOKIA-RESERVED-DAYS:" property.

CALLED BY:	(INTERNAL) ParseEventText
PASS:		ds:si	= SMS text buffer
		es	= segment containing MBAppointment struct
RETURN:		if error
			carry set
			MBAppointment struct not changed
			ds:si	= whatever not read yet
		else
			carry cleared
			MBAppointment updated
			ds:si	= whatever not read yet
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Parse a number, and stick it into escape info.
		It should look like this:

			X-NOKIA-RESERVED-DAYS: 5

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/20/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleReservedDaysProp	proc	near
		uses	ax, dx
		.enter
		Assert	segment, ds
		Assert	segment, es
	;
	; Skip all whitespaces.
	;
		call	ConsumeWhiteSpaces
	;
	; Read in a number.
	;
		call	ExtractDWordFromUID		; dxax <- dword, 
							; carry set if error
	;
	; Is it a word?
	;
		tst	dx
		stc					; assume error
		jnz	quit
	;
	; Store the number in MBAppointment escpae info.
	;
		mov	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_reserveWholeDay,\
				ax
		clc					; no error!
quit:
		.leave
		ret
HandleReservedDaysProp	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayDayPlanGStateWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If appropriate, open the ConfirmEventsListDialog that
		shows the list of event of the day.

CALLED BY:	(INTERNAL) HandleEventSMSMsg
PASS:		es	= segment containing MBAppointment struct
		^lcx:dx	= ConfirmEventDialog dialog
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If (valid password) {
			No dayplan-like window
		}
		If (text-changed) {
			No dayplan-like window
		}
		If (to-do) {
			No dayplan-like window
		}

		Decide whether the event is to-do:
			if (MBA_start.FDAT_date == MB_NO_TIME) {
				to-do item
			}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayDayPlanGStateWindow	proc	near
		uses	ax, bx, cx, dx, bp, si, di
		.enter
		Assert	segment, es
		Assert	optr, cxdx
	;
	; Is password given?
	;
		CheckHack<CAPB_NO_PASSWORD eq 0>
		tst	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_passwdStat
		jnz	quit
	;
	; Is it a text-change notification?
	;
		cmp	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_apptStatus,\
				CAST_TEXT_CHANGED
		je	quit
	;
	; Is it a to-do item?
	;
		cmp	es:[MBA_start].FDAT_date, MB_NO_TIME
		je	quit
	;
	; Create a gstring for DayPlan object to draw to.
	; Allocate a block to hold the graphics string we are creating.
	;
		push	cx
		mov	ax, LMEM_TYPE_GSTRING
		clr	cx				; default size
		call	MemAllocLMem			; bx <- handle
	;
	; Create a gstring that is what will be drawn.
	;
		push	bx
		mov	cl, GST_CHUNK
		call	GrCreateGString			; si <- chunk handle
							;  that will hold the
							;  graphics string
							; di <- gstate
	;
	; Make the DayPlan object print to gstring.
	;
		mov	bp, di
		mov	ax, MSG_DP_PRINT_ONE_DAY_TO_GSTATE
		mov	cx, es:[MBA_start].FDAT_date
		mov	bx, handle DayPlanObject
		mov	si, offset DayPlanObject
		call	ObjMessage_mailbox_call
	;
	; End the gstring.
	;
		call	GrEndGString			; ax <-
							;  GStringErrorType 
	;
	; Tell the content which gstring to print.
	;
		pop	cx				; handle of
							;  gstate block
		pop	bx				; ^hbx <- handle of
							; ConfirmEventDialog 
		mov	dx, di
		mov	si, offset EventsListVisContent
		mov	ax, MSG_CALENDAR_EVENTS_LIST_CONTENT_SET_GSTRING
		call	ObjMessage_mailbox_call
	;
	; Tell the confirm dialog that we have a GenView/GenContent
	; associated with it.
	;
		mov	cx, mask CDF_HAS_GEN_VIEW	; set flag
		mov	si, offset ConfirmEventDialog
		mov	ax, MSG_CALENDAR_CONFIRM_DLG_SET_FLAGS
		call	ObjMessage_mailbox_call
	;
	; Initiate the window.
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	si, offset ConfirmEventsListDialog
		call	ObjMessage_mailbox_send
quit:
		.leave
		ret
DisplayDayPlanGStateWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRoutineViaUIThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the specified routine on the app UI thread (probably
		because the routine calls ObjLockObjBlock, and the object
		block's exec thread is always the app UI thread.)

CALLED BY:	(INTERNAL)
PASS:		ax:si	= vfptr to routine to call
		cx, dx	= whatever that should be passed to the routine
RETURN:		ax, cx, dx = whatever the routine returns
			     (destroyed if not returned)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallRoutineViaUIThread	proc	near
		uses	bx, si, di
pcrParams	local	ProcessCallRoutineParams
		.enter
	;
	; Set up the pcrParams.
	;
		movdw	ss:[pcrParams].PCRP_address, axsi
		mov	ss:[pcrParams].PCRP_dataCX, cx
		mov	ss:[pcrParams].PCRP_dataDX, dx
	;
	; Get our ui thread handle.
	;
		mov	bx, handle Interface
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo			; ax <- exec thread,
							; ie. app ui thread
		mov_tr	bx, ax
		clr	si				; ^lbx:si <- ui thread
	;
	; Call MSG_PROCESS_CALL_ROUTINE.
	;
		mov	ax, MSG_PROCESS_CALL_ROUTINE
		mov	di, mask MF_CALL or mask MF_STACK
		mov	dx, size ProcessCallRoutineParams
		push	bp
		lea	bp, pcrParams
		call	ObjMessage			; ax, cx, dx, bp
							; returned
		pop	bp

		.leave
		ret
CallRoutineViaUIThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAndStuffConfirmDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the info for confirmation dialog.

CALLED BY:	(INTERNAL) HandleEventSMSMsg
PASS:		es	= segment containing MBAppointment struct
RETURN:		^lcx:dx	= dialog
		cx	= 0 if no dialog is appropriate (ie. password
			  invalid -- shouldn't have called this routine)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get the dialog:
			status accepted:   EventReplyDialog
			status declined:   EventReplyDialog
			status deleted:    EventReplyDialog
			status text-changed:
					   ForcedEventDialog
			else:

			(need actions / changed:)
			no password given: ConfirmEventDialog
			password valid/reply-or-update-has-password:
					   ForcedEventDialog
			password invalid:  no dialog, the event should be
					   discarded quietly.

		Create the dialog text in tempWritableChunk.

		Replace EventInfoText with the text in tempWritableChunk.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAndStuffConfirmDialog	proc	near
		uses	ax, bx, si, di, bp
		.enter
		Assert	segment, es
	;
	; If status of appointment is accepted / declined / deleted /
	; use EventReplyDialog.
	;
	; Text-change: use ForcedEventDialog.
	;
		mov	di, CALENDAR_ESCAPE_DATA_OFFSET
		mov	cx, es:[di].CAET_apptStatus

		mov	bx, handle EventReplyDialog
		cmp	cx, CAST_ACCEPTED
		je	dlgFound
		cmp	cx, CAST_DECLINED
		je	dlgFound
		cmp	cx, CAST_DELETED
		je	dlgFound

		mov	bx, handle ForcedEventDialog
		cmp	cx, CAST_TEXT_CHANGED
		je	dlgFound

	;
	; Find the right dialog to create. We either create
	; ConfirmEventDialog (normal event) or ForcedEventDialog
	; (forced event) or no dialog at all, based on whether password is
	; given or valid or not.
	;
		; bx == handle ForcedEventDialog
		mov	cl, es:[di].CAET_passwdStat
		cmp	cl, CAPB_PASSWORD_VALID
		je	dlgFound
		cmp	cl, CAPB_REPLY_OR_UPDATE_HAS_PASSWORD
		je	dlgFound
		
		mov	bx, handle ConfirmEventDialog
		cmp	cl, CAPB_NO_PASSWORD
		je	dlgFound

		Assert	e, cl, CAPB_PASSWORD_INVALID
		clr	cx				; password not valid
EC <		WARNING	CALENDAR_PASSWORD_INVALID_WHY_CALL_THIS_ROUTINE	>
		jmp	quit
dlgFound:
		CheckHack<offset ConfirmDlgsInteraction eq \
			  offset ForcedDlgsInteraction>
		CheckHack<offset ConfirmDlgsInteraction eq \
			  offset EventReplyDlgsInteraction>
		mov	si, offset ConfirmDlgsInteraction
		call	UserCreateDialog		; ^lbx:si <- dialog
	;
	; Change dialog complex moniker and / or disable confirm button, if
	; this is an update.
	;
		call	ChangeDialogForUpdate
	;
	; Create the dialog text in tempWritableChunk.
	;
		mov	si, EFST_UNKNOWN		; don't know which
							;  format string to use
		call	CopyAndFormatWritableChunk	; tempWritableChunk <-
							;  display string
	;
	; Change the text in the dialog to be the tempWritableChunk.
	;
		CheckHack<offset EventInfoText eq offset ForcedEventInfoText>
		CheckHack<offset EventInfoText eq offset EventReplyInfoText>
		mov	si, offset EventInfoText	; ^bx:si - text obj
		mov	dx, handle tempWritableChunk
		mov	bp, offset tempWritableChunk
		clr	cx				; null terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		call	ObjMessage_mailbox_call		; ax, cx, dx, bp gone

		mov	cx, bx				; ^lcx:dx <- dialog
		mov	dx, offset ConfirmEventDialog
quit:
		.leave
		ret
CreateAndStuffConfirmDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeDialogForUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the complex moniker title of the dialog, if the
		appointment status is text-update / update.

CALLED BY:	(INTERNAL) CreateAndStuffConfirmDialog
PASS:		^lbx:si	= dialog
		es:di	= fptr to CalendarApptEscapeType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Status could be:
		CAST_NEED_ACTIONS (=0), CAST_ACCEPTED, CAST_DECLINED,
		CAST_DELETED, CAST_CHANGED, CAST_TEXT_CHANGED.

		if (not CAST_CHANGED/CAST_TEXT_CHANGED) {
		    quit
		}

		if (CAST_TEXT_CHANGED) {
		    disable the confirm button
		}

		Change ConfirmStuffInteraction /
		ForcedStuffInteraction / EventReplyStuffInteraction
		complex moniker:

		if (password given) {
		    use CalendarReservationChangeText
		} else {
		    use CalendarRequestChangeText
		}

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/12/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeDialogForUpdate	proc	near
		uses	ax, cx, dx, si, es, di
rcm		local	ReplaceComplexMoniker
		.enter
		Assert	optr, bxsi
		Assert	fptr, esdi
	;
	; Is this an update (time or non-time) SMS?
	;
		CheckHack<CAST_CHANGED lt CAST_TEXT_CHANGED>
		mov	ax, es:[di].CAET_apptStatus
		cmp	ax, CAST_CHANGED
		jb	quit
	;
	; Disable "Confirm" trigger, if text-changed.
	;
		cmp	ax, CAST_TEXT_CHANGED
		jne	notTextChange

		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	si, offset AcceptAndConfirmTrigger
		Assert	optr, bxsi
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjMessage_mailbox_send		; nothing destroyed

notTextChange:
	;
	; Decide which text to use. Is password given?
	;
		mov	dx, offset CalendarRequestChangeText
		cmp	es:[di].CAET_passwdStat, CAPB_NO_PASSWORD
		je	gotText

		mov	dx, offset CalendarReservationChangeText
gotText:
	;
	; Fill in ReplaceComplexMoniker, rcm. First, clear all the
	; unused fields.
	;
		clr	ax
		segmov	es, ss, di
		lea	di, ss:[rcm]			; es:di <- rcm
		mov	cx, size rcm
		rep	stosb
	;
	; Add relevant info.
	;
		; dx == offset of text to use
		CheckHack<handle CalendarRequestChangeText eq \
			  handle CalendarReservationChangeText>

		mov	ss:[rcm].RCM_topTextSource.handle, \
				handle CalendarRequestChangeText
		mov	ss:[rcm].RCM_topTextSource.offset, dx
		mov	ss:[rcm].RCM_topTextSourceType, CMST_OPTR
		mov	ss:[rcm].RCM_iconBitmapSourceType, CMST_KEEP
		mov	ss:[rcm].RCM_overwrite, mask RCMO_TOP_TEXT
	;
	; Set the complex moniker!
	;
		; ^lbx:si <- dialog top level
		CheckHack<offset ConfirmStuffInteraction eq \
			  offset ForcedStuffInteraction>
		CheckHack<offset ConfirmStuffInteraction eq \
			  offset EventReplyStuffInteraction>
		push	bp
		mov	ax, MSG_COMPLEX_MONIKER_REPLACE_MONIKER
		mov	si, offset ConfirmStuffInteraction
		mov	dx, ss
		lea	bp, ss:[rcm]
		call	ObjMessage_mailbox_call		; ax, dx gone
		
		pop	bp
quit:
		.leave
		ret
ChangeDialogForUpdate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyAndFormatWritableChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a format string to the writable chunk, and stuff
		in all info we have about it (from the MBAppointment).

CALLED BY:	(INTERNAL) CreateAndStuffConfirmDialog, ReplyAcceptOrDeny
PASS:		es	= segment containing MBAppointment struct
		es	= 0 if we should just copy the string to
			  chunk, and don't do any formatting.
		si	= EventFormatStringType, or EFST_UNKNOWN if the
			  routine should find the right string based on the
			  MBAppointment.
RETURN:		tempWritableChunk written
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Pick the text to copy to chunk, depending on the type
		of event.

		Get UI thread to copy the text to chunk.

		Replace tokens with end date.
		Replace tokens with end time.
		Replace tokens with start time.
		Replace tokens with start time.
		Replace tokens with reply status.
		Replace tokens with sender info.

	******	Stuff the event text LAST (because we use some printable
		characters (sigma, delta) to represent arguments.) ******

		If the CAET_userReply is not CERS_NO_REPLY_YET, or if
		the CAET_apptStatus is CAST_ACCEPTED / CAST_DECLINED,
		use the NormalEventReplyString.

		If the CAET_apptStatus is CAST_DELETED or CAST_TEXT_CHANGED,
		use the NormalEventUpdateString.

		If the CAET_apptStatus is CAST_NEEDS_ACTIONS, use the
		NormalEventNotifyText.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LAST_FORMAT_STRING_OFFSET	equ	(offset BadSMSNotifyText)

CopyAndFormatWritableChunk	proc	near
		uses	ax, bx, cx, dx, ds, si, di, bp
		.enter
	;
	; Are we given a string to use?
	;
		cmp	si, EFST_UNKNOWN
		jne	gotText

	;------------------------------------------------------------------
	;	Find the text to copy from.
	;------------------------------------------------------------------

		Assert	segment, es
	;
	; If this is an accepted / denied REPLY from recipient, we
	; use XXXReplyString, instead of XXXNotifyString.
	;
	; If this is a deleted / changed UPDATE from sender, we use
	; XXXUpdateString, instead of XXXNotifyString.
	;
	; If this is a text change UPDATE from sender, we use
	; XXXNotifyString.
	;
		mov	di, CALENDAR_ESCAPE_DATA_OFFSET
		mov	bx, es:[di].CAET_apptStatus
		Assert	etype, bx, CalendarApptStatusType
		mov	si, cs:[statusToStringMapping][bx]
	;
	; If the user already replied, and thus we are sending the
	; text as a reply, we use XXXReplyString, instead of XXXNotifyString.
	;
		cmp	es:[di].CAET_userReply, CERS_NO_REPLY_YET
		je	gotText

		mov	si, EFST_NORMAL_EVENT_REPLY
gotText:
	;------------------------------------------------------------------
	;	Copy text to tempWritableChunk
	;------------------------------------------------------------------
	;
	; Find the source string offset
	;
		Assert	etype, si, EventFormatStringType
		mov	si, cs:[formatStringOffsetTable][si]
	;
	; Find the source string.
	;
		push	es
		mov	bx, handle DataBlock
		call	ObjLockObjBlock			; ax <- segment
		mov_tr	es, ax
		mov	di, es:[si]			; es:di <- text
	;
	; Construct CopyChunkFlags
	;
		push	di
		LocalStrLength includeNull		; cx <- size with null
							; ax, di destroyed
		pop	di
		ornf	cx, CopyChunkFlags<0, CCM_FPTR, 0>
							; cx <- CopyChunkFlags
	;
	; Get ready to copy chunk.
	;
		push	bp
		sub	sp, size CopyChunkOutFrame

		mov	bp, sp
		mov	ss:[bp].CCOF_source.segment, es
		mov	ss:[bp].CCOF_source.offset, di
		mov	ss:[bp].CCOF_dest.handle, handle tempWritableChunk
		mov	ss:[bp].CCOF_dest.chunk, offset tempWritableChunk
		mov	ss:[bp].CCOF_copyFlags, cx
	;
	; Find the UI thread that owns the block.
	;
		mov	bx, handle Interface
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo		;Returns ax <- id of process
						; that runs dest block.
	;
	; Send method to process to copy chunk.
	;
		mov_tr	bx, ax
		mov	ax, MSG_PROCESS_COPY_CHUNK_OVER
		mov	dx, size CopyChunkOutFrame
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage			; ax, cx, dx, bp gone
		
		add	sp, size CopyChunkOutFrame
		pop	bp
	;
	; Unlock DataBlock.
	;
		mov	bx, handle DataBlock
		call	MemUnlock			; es destroyed
		pop	es
	;
	; Should we stuff the string?
	;
		mov	ax, es				; can't tst on es
		tst	ax
		jz	quit

	;------------------------------------------------------------------
	;	Stuff tempWritableChunk with real data
	;------------------------------------------------------------------
	;
	; First, get *ds:si = chunk of text.
	;
		mov	bx, handle WritableStrings
		call	ObjLockObjBlock			; ax <- segment
		mov_tr	ds, ax
		mov	si, offset tempWritableChunk	; *ds:si <- string
	;
	; Change the date & time (including start/end time, alarm,
	; repeat, etc.)
	;
SBCS <		mov	al, CONFIRM_DLG_EVENT_DATE_TIME_ARG_CHAR	>
DBCS <		mov	ax, CONFIRM_DLG_EVENT_DATE_TIME_ARG_CHAR	>
		call	ReplaceTokenWithTimeRelatedInfo	; ax, cx, dx destroyed
	;
	; Change the reply status, if any.
	;
		mov	cl, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_userReply
		cmp	cl, CERS_NO_REPLY_YET
		je	noReply

		mov	dl, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_passwdStat
SBCS <		mov	al, CONFIRM_DLG_REPLY_ARGUMENT_CHAR		>
DBCS <		mov	ax, CONFIRM_DLG_REPLY_ARGUMENT_CHAR		>
		call	ReplaceTokenWithReplyStatus	; ax, cx destroyed
noReply:
	;
	; Change the update action, if any.
	;
		mov	cx, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_apptStatus
		LocalLoadChar	ax, CONFIRM_DLG_UPDATE_ACTION_ARG_CHAR
		call	RepaceTokenWithUpdateAction	; ax, cx, dx destroyed
	;
	; Change sender info.
	;
SBCS <		mov	al, CONFIRM_DLG_SENDER_CHAR			>
DBCS <		mov	ax, CONFIRM_DLG_SENDER_CHAR			>
		call	ReplaceTokenWithSenderInfo	; ax, cx, dx destroyed
	;
	; Finally, change the event text.
	;
		mov	cx, es
		lea	dx, es:[MBA_description]	; cx:dx <- text
		mov	di, dx
	;
	; See if the text is too big.
	;
		cmp	es:[MBA_descSize], EVENT_DESCRIPTION_SIZE
		jb	sizeOk				; (*)
	;
	; Write a null to the string.
	;
		add	di, EVENT_DESCRIPTION_SIZE
		mov	bp, es:[di]
		mov	{word} es:[di], NULL
sizeOk:
		
SBCS <		mov	al, CONFIRM_DLG_EVENT_TEXT_ARGUMENT_CHAR	>
DBCS <		mov	ax, CONFIRM_DLG_EVENT_TEXT_ARGUMENT_CHAR	>
		pushf
		call	SubstituteStringArg
		popf
	;
	; Restore the char replaced by null.
	;
		jb	noNeedRestore			; (*)
		mov	es:[di], bp
noNeedRestore:
		call	MemUnlock			; ds destroyed
quit:		
		.leave
		ret
CopyAndFormatWritableChunk	endp

formatStringOffsetTable	nptr \
	offset NormalEventNotifyText,		; EFST_NORMAL_EVENT_NOTIFY
	offset NormalEventReplyText,		; EFST_NORMAL_EVENT_REPLY
	offset NormalEventUpdateText,		; EFST_NORMAL_EVENT_UPDATE
	offset NormalEventRequestText,		; EFST_NORMAL_EVENT_REQUEST
	offset BadSMSNotifyText,		; EFST_BAD_SMS_NOTIFY
	offset BookEventRecipientInfo		; EFST_RECIPIENT_INFO


CheckHack<length formatStringOffsetTable eq (EventFormatStringType/2)>

statusToStringMapping EventFormatStringType \
	EFST_NORMAL_EVENT_NOTIFY,		; CAST_NEED_ACTIONS
	EFST_NORMAL_EVENT_REPLY,		; CAST_ACCEPTED
	EFST_NORMAL_EVENT_REPLY,		; CAST_DECLINED
	EFST_NORMAL_EVENT_UPDATE,		; CAST_DELETED
	EFST_NORMAL_EVENT_NOTIFY,		; CAST_CHANGED
	EFST_NORMAL_EVENT_UPDATE		; CAST_TEXT_CHANGED

CheckHack<length statusToStringMapping eq (CalendarApptStatusType/2)>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeWritableChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize the writable chunk.

CALLED BY:	(INTERNAL)
PASS:		cx	= size to resize to
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
ResizeWritableChunk	proc	near
		uses	ax, bx, ds
		.enter
		
		mov	bx, handle tempWritableChunk
		call	MemLock				; ax <- segment

		mov_tr	ds, ax
		mov	ax, bx
		call	LMemReAlloc
		call	MemUnlock			; ds destroyed
		
		.leave
		ret
ResizeWritableChunk	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithTimeRelatedInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token char in the text object to the date,
		time, alarm, etc info specified in MBAppointment struct.

CALLED BY:	(INTERNAL) CopyAndFormatWritableChunk
PASS:		*ds:si	= chunk of text
		es	= MBAppointment struct
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		If there is no start date, assume no time info, and
		delete the token.

		Lock string resource.

		Replace DateTime token with a string that contains 6
		other tokens (start time, end time, reservation,
		alarm, repeat, repeat until).

		Replace each of 6 tokens with real strings, by calling
		different routines.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/24/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithTimeRelatedInfo	proc	near
		uses	bx
		.enter
		Assert	segment, es
	;
	; Is there any time info? If not, delete the token from
	; string.
	;
		cmp	es:[MBA_start].FDAT_date, MB_NO_TIME
		jne	hasTime
	;
	; Delete date/time token from string.
	;
		call	DeleteTokenFromString		; cx, dx destroyed
		jmp	quit
hasTime:
	;
	; First, replace the date/time token with a string that
	; contains all tokens that make up a date/time string.
	;
		push	ax, ds
		mov	bx, handle DataBlock
		call	MemLock				; ax <- segment
		mov	cx, ax

		mov_tr	ds, ax
assume	ds:DataBlock
		mov	dx, \
		ds:[Space_StartTime_EndTime_Reserve_Alarm_Repeat_RepeatUntil_String]
							; cx:dx <- string
assume	ds:nothing
		pop	ax, ds				; ax <- token,
							; *ds:si <- string
		call	SubstituteStringArg
	;
	; Unlock string resource.
	;
		; bx == resource handle
		Assert	handle, bx
		call	MemUnlock
	;
	; Replace start date/time, if any.
	;
		LocalLoadChar	ax, CONFIRM_DLG_EVENT_START_TIME_ARG_CHAR
		call	ReplaceTokenWithStartTime	; ax, cx, dx destroyed
	;
	; Replace end date/time, if any.
	;
		LocalLoadChar	ax, CONFIRM_DLG_EVENT_END_TIME_ARG_CHAR
		call	ReplaceTokenWithEndTime		; ax, cx, dx destroyed
	;
	; Replace reservation char with string, if any.
	;
		LocalLoadChar	ax, CONFIRM_DLG_EVENT_RESERVE_ARG_CHAR
		call	ReplaceTokenWithReservation	; ax, cx, dx destroyed
	;
	; Replace alarm char with string, if any.
	;
		LocalLoadChar	ax, CONFIRM_DLG_EVENT_ALARM_ARG_CHAR
		call	ReplaceTokenWithAlarm		; ax, cx, dx destroyed
	;
	; Replace repetition char with string, if any.
	;
		LocalLoadChar	ax, CONFIRM_DLG_EVENT_REPEAT_ARG_CHAR
		call	ReplaceTokenWithRepetition	; ax, cx, dx destroyed
	;
	; Replace repeat-until char with string, if any.
	;
		LocalLoadChar	ax, CONFIRM_DLG_EVENT_REPEAT_UNTIL_ARG_CHAR
		call	ReplaceTokenWithRepeatUntilDate	; ax, cx, dx destroyed
quit:		
		.leave
		ret
ReplaceTokenWithTimeRelatedInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteTokenFromString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token char in the text object to NULL.

CALLED BY:	(INTERNAL) ReplaceTokenWithDateTimeInfo
PASS:		*ds:si	= chunk of text
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
RETURN:		nothing
DESTROYED:	cx, dx
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		Replace token with null char.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/24/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteTokenFromString	proc	near
nullString	local	TCHAR
		.enter
	;
	; Make the null string.
	;
		LocalClrChar	ss:[nullString]
	;
	; Replace token with space string.
	;
		mov	cx, ss
		lea	dx, ss:[nullString]
		call	SubstituteStringArg

		.leave
		Destroy	cx, dx
		ret
DeleteTokenFromString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithStartTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token in the string with start date/time text.

CALLED BY:	(INTERNAL) ReplaceTokenWithTimeRelatedInfo
PASS:		*ds:si	= chunk of text
		es	= MBAppointment struct
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If (no start date) {
		    replace token with null
		} else {
		    replace token with Date_Time_String
		    replace date/time token in Date_Time_String with
		    real date/time.
		}

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/25/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithStartTime	proc	near
		uses	bx
		.enter
		Assert	segment, es
	;
	; Is there start date/time?
	;
		cmp	es:[MBA_start].FDAT_date, MB_NO_TIME
		jne	hasStartTime
	;
	; Delete start date/time token from string.
	;
		call	DeleteTokenFromString		; cx, dx destroyed
		jmp	quit
hasStartTime:
	;
	; Change the start time token to Date_Time_String.
	;
		push	ax, ds
		
		mov	bx, handle DataBlock
		call	MemLock				; ax <- segment
		mov	cx, ax

		mov_tr	ds, ax
assume	ds:DataBlock
		mov	dx, ds:[Date_Time_String]	; cx:dx <- string
assume	ds:nothing

		pop	ax, ds
		call	SubstituteStringArg
	;
	; Do start date and time.
	;
		mov	cx, es:[MBA_start].FDAT_date
		mov	dx, es:[MBA_start].FDAT_time
		call	ReplaceDateTimeTokensWithDateTime ; ax, cx, dx gone
	;
	; Unlock string resource.
	;
		; bx == resource handle
		Assert	handle, bx
		call	MemUnlock
quit:
		.leave
		Destroy	ax, cx, dx
		ret
ReplaceTokenWithStartTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithEndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token in the string with end date/time text.

CALLED BY:	(INTERNAL) ReplaceTokenWithTimeRelatedInfo
PASS:		*ds:si	= chunk of text
		es	= MBAppointment struct
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If (no end date) {
		    replace token with null
		} else {
		    replace token with Hyphen_Date_Time_String
		    if (start date == end date) delete date token.
		    replace date/time token in Hyphen_Date_Time_String with
		    real date/time.
		}

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/25/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithEndTime	proc	near
		uses	bx
		.enter
		Assert	segment, es
	;
	; Is there end date/time?
	;
		cmp	es:[MBA_end].FDAT_date, MB_NO_TIME
		jne	hasEndTime
	;
	; Delete end date/time token from string.
	;
		call	DeleteTokenFromString		; cx, dx destroyed
		jmp	quit
hasEndTime:
	;
	; Change the end time token to Date_Time_String.
	;
		push	ax, ds
		
		mov	bx, handle DataBlock
		call	MemLock				; ax <- segment
		mov	cx, ax

		mov_tr	ds, ax
assume	ds:DataBlock
		mov	dx, ds:[Hyphen_Date_Time_String] ; cx:dx <- string
assume	ds:nothing

		pop	ax, ds
		call	SubstituteStringArg
	;
	; Is start date == end date?
	;
		mov	cx, es:[MBA_end].FDAT_date
		cmp	es:[MBA_start].FDAT_date, cx
		jne	datesNotSame
	;
	; Erase date token in string.
	;
		LocalLoadChar	ax, CONFIRM_DLG_EVENT_DATE_ARGUMENT_CHAR
		call	DeleteTokenFromString		; cx, dx destroyed
datesNotSame:
	;
	; Do end date and time.
	;
		mov	cx, es:[MBA_end].FDAT_date
		mov	dx, es:[MBA_end].FDAT_time
		call	ReplaceDateTimeTokensWithDateTime ; ax, cx, dx gone
	;
	; Unlock string resource.
	;
		; bx == resource handle
		Assert	handle, bx
		call	MemUnlock
quit:
		.leave
		Destroy	ax, cx, dx
		ret
ReplaceTokenWithEndTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceDateTimeTokensWithDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace date/time tokens in the string with real
		date/time text.

CALLED BY:	(INTERNAL) ReplaceTokenWithTimeRelatedInfo
PASS:		*ds:si	= chunk of text
		cx	= FileDate
		dx	= FileTime (MB_NO_TIME ie. -1 if none)
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		Replace time token with real time.
		Replace date token with real date.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/24/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceDateTimeTokensWithDateTime	proc	near
		.enter
	;
	; Replace time.
	;
		LocalLoadChar	ax, CONFIRM_DLG_EVENT_TIME_ARGUMENT_CHAR
		call	ReplaceTokenWithTime		; ax, dx destroyed
	;
	; Replace date.
	;
		LocalLoadChar	ax, CONFIRM_DLG_EVENT_DATE_ARGUMENT_CHAR
		mov	dx, cx
		call	ReplaceTokenWithDate		; ax, dx destroyed
		
		.leave
		Destroy	ax, cx, dx
		ret
ReplaceDateTimeTokensWithDateTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token char in the text object to the date
		specified.

CALLED BY:	(INTERNAL) CopyAndFormatWritableChunk
PASS:		*ds:si	= chunk of text
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
		dx	= FileDate
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithDate	proc	near
		uses	bx, cx, es, di
dateBuffer	local	20 dup (TCHAR)			; for a date, 20
							; should be enough
		.enter

		push	ax, si
		mov_tr	ax, dx				; ax <- FileDate
		clr	bx				; bx <- FileTime<0,0,0>
	;
	; Create the date text.
	;
		mov	si, DTF_ZERO_PADDED_SHORT
		segmov	es, ss, cx
		lea	di, ss:[dateBuffer]
		call	LocalFormatFileDateTime		; cx <- # of chars

		pop	ax, si
	;
	; Now replace the token char with dateBuffer text.
	;
		movdw	cxdx, esdi
		call	SubstituteStringArg
		
		.leave
		Destroy	ax, dx
		ret
ReplaceTokenWithDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token char in the text object to the time
		specified.

CALLED BY:	(INTERNAL) CopyAndFormatWritableChunk
PASS:		*ds:si	= chunk of text
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
		dx	= FileTime, MB_NO_TIME (-1) if none
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithTime	proc	near
		uses	bx, cx, es, di
timeBuffer	local	20 dup (TCHAR)			; for a time, 20
							; should be enough
		.enter
	;
	; If no time, delete token from string.
	;
		cmp	dx, MB_NO_TIME
		jne	hasTime

		call	DeleteTokenFromString		; cx, dx destroyed
		jmp	quit
hasTime:
	;
	; Get buffer.
	;
		segmov	es, ss, di
		lea	di, ss:[timeBuffer]
	;
	; Create the time text.
	;
		push	ax, si
		mov	ax, FileDate<0,1,1>		; 1980/1/1
		mov	bx, dx
		mov	si, DTF_HM
		call	LocalFormatFileDateTime		; cx <- # of chars

		pop	ax, si
	;
	; Now replace the token char with timeBuffer text.
	;
		movdw	cxdx, esdi
		call	SubstituteStringArg
quit:		
		.leave
		Destroy	ax, dx
		ret
ReplaceTokenWithTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithDayOfWeek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token char in string chunk to the day of week
		specified.

CALLED BY:	(INTERNAL) ConstructMidnightAlarmWarning
PASS:		*ds:si	= format string
		ax	= token to replace
		dl	= day of week	( 1 = monday )
RETURN:		nothing
DESTROYED:	nothing		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	3/16/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithDayOfWeek	proc	far
		dayOfWeek	local	DayOfWeekString
		uses	bx,cx,dx,si,di,es
		.enter
	;
	; format day of week string
	;
		push	ax, si
		mov_tr	cl, dl
		segmov	es, ss, di
		lea	di, dayOfWeek
		mov	si, DTF_WEEKDAY
		call	LocalFormatDateTime	; cx = # of characters
		pop	ax, si			; ax = token char
	;
	; replace the token char
	;
		movdw	cxdx, esdi
		call	SubstituteStringArg	; nothing trashed
		
		.leave
		ret
ReplaceTokenWithDayOfWeek	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithReservation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token in the string with reservation text.

CALLED BY:	(INTERNAL) ReplaceTokenWithTimeRelatedInfo
PASS:		*ds:si	= chunk of text
		es	= MBAppointment struct
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If (no reservation) {
		    replace token with null
		} else {
		    replace token with Comma_LineFeed_Reserve_X_Days_String
		    replace (# of days) token in
		    Comma_LineFeed_Reserve_X_Days_String with real number
		}

		A dword is at most 10 chars (2^32 = 4294967296).

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/25/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithReservation	proc	near
		uses	bx, es, di
numberBuffer	local	11 dup (TCHAR)		; a dword is at most 10
						; chars, plus null
		.enter
		Assert	segment, es
	;
	; Is there reservation?
	;
		mov	cx, \
			es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_reserveWholeDay
		jcxz	noReservation
	;
	; Change the reservation token to Comma_LineFeed_Reserve_X_Days_String
	;
		push	cx
		push	ax, ds
		
		mov	bx, handle DataBlock
		call	MemLock				; ax <- segment
		mov	cx, ax

		mov_tr	ds, ax
assume	ds:DataBlock
		mov	dx, ds:[Comma_LineFeed_Reserve_X_Days_String]
							; cx:dx <- string
assume	ds:nothing

		pop	ax, ds
		call	SubstituteStringArg

	;
	; Construct the number string by converting the number value.
	;
		clr	dx
		pop	ax				; dx:ax <- dword,
							;  # of days
		segmov	es, ss, cx
		lea	di, ss:[numberBuffer]		; es:di <- buffer
		mov	cx, size numberBuffer
		call	WriteDWordToAscii		; numberBuffer filled
							;  cx, di destroyed
	;
	; Replace N_day_token with the correct day string.
	;
		LocalLoadChar	ax, CONFIRM_DLG_RESERVE_DAYS_ARG_CHAR
		mov	cx, ss
		lea	dx, ss:[numberBuffer]
		call	SubstituteStringArg
	;
	; Unlock string resource.
	;
		; bx == resource handle
		Assert	handle, bx
		call	MemUnlock
quit:
		.leave
		Destroy	ax, cx, dx
		ret
noReservation:
	;
	; Delete reservation token from string.
	;
		call	DeleteTokenFromString		; cx, dx destroyed
		jmp	quit
ReplaceTokenWithReservation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token in the string with alarm text.

CALLED BY:	(INTERNAL) ReplaceTokenWithTimeRelatedInfo
PASS:		*ds:si	= chunk of text
		es	= MBAppointment struct
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If (no alarm) {
		    replace token with null
		} else {
		    if (alarm interval is zero) {
			replace token with
			 Comma_LineFeed_Alarm_At_Start_Time_String
		    } else
			replace token with
			 Comma_LineFeed_Alarm_X_Minutes_Before_String
		    }
		    replace (# of minute) token in
		     Comma_LineFeed_Alarm_X_Minutes_Before_String with
		     real number.
		}

		A dword is at most 10 chars (2^32 = 4294967296).

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/25/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithAlarm	proc	near
		uses	bx, es, di
numberBuffer	local	11 dup (TCHAR)		; a dword is at most 10
						; chars, plus null
		.enter
		Assert	segment, es
	;
	; Is there alarm?
	;
		mov	bx, es:[MBA_alarmInfo]
		test	bx, mask MBAI_HAS_ALARM
		jz	noAlarm
	;
	; Find alarm type and interval.
	;
		mov	dx, bx
		andnf	bx, mask MBAI_TYPE
		mov	cl, offset MBAI_TYPE
		shr	bx, cl			; bl=MBAlarmIntervalType
		andnf	dx, mask MBAI_INTERVAL	; dx=interval
	;
	; We cannot handle anything other than minute.
	;
		cmp	bl, MBAIT_MINUTES
EC <		WARNING_NE ALARM_INTERVAL_TYPE_NOT_SUPPORTED		>
		jne	noAlarm
	;
	; Change the alarm token to something, depending on interval.
	;
		push	dx
		push	ax, ds
		
		mov	bx, handle DataBlock
		call	MemLock				; ax <- segment
		mov	cx, ax

		mov_tr	ds, ax
assume	ds:DataBlock
		tst	dx				; is interval zero?
		mov	dx, ds:[Comma_LineFeed_Alarm_At_Start_Time_String]
							; cx:dx <- string
		jz	gotString
		mov	dx, ds:[Comma_LineFeed_Alarm_X_Minutes_Before_String]
gotString:
assume	ds:nothing
		pop	ax, ds
		call	SubstituteStringArg
	;
	; Construct the number string by converting the number value.
	;
		clr	dx
		pop	ax				; dx:ax <- dword,
							;  # of minute
		segmov	es, ss, cx
		lea	di, ss:[numberBuffer]		; es:di <- buffer
		mov	cx, size numberBuffer
		call	WriteDWordToAscii		; numberBuffer filled
							;  cx, di destroyed
	;
	; Replace N_minute_token with the correct day string.
	;
		LocalLoadChar	ax, CONFIRM_DLG_ALARM_MINUTES_ARG_CHAR
		mov	cx, ss
		lea	dx, ss:[numberBuffer]
		call	SubstituteStringArg
	;
	; Unlock string resource.
	;
		; bx == resource handle
		Assert	handle, bx
		call	MemUnlock
quit:
		.leave
		Destroy	ax, cx, dx
		ret
noAlarm:
	;
	; Delete alarm token from string.
	;
		call	DeleteTokenFromString		; cx, dx destroyed
		jmp	quit
ReplaceTokenWithAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithRepetition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token in the string with repetition text.

CALLED BY:	(INTERNAL) ReplaceTokenWithTimeRelatedInfo
PASS:		*ds:si	= chunk of text
		es	= MBAppointment struct
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If (no repetition) {
		    replace token with null
		} else {
		    replace token with Comma_LineFeed_Reserve_X_Days_String
		    replace (# of days) token in
		    Comma_LineFeed_Reserve_X_Days_String with real number
		}

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/25/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithRepetition	proc	near
		uses	bx, es, di
		.enter
		Assert	segment, es
	;
	; Is there repetition?
	;
		mov	di, es:[MBA_repeatInfo]
		tst	di
		jz	noRepetition

		mov	cx, es:[di].MBRI_interval	; cx <-MBRepeatInterval
	;
	; Change the repetition token to
	; Comma_LineFeed_Repetition_Info_String.
	;
		push	cx
		push	ax
		
		mov	bx, handle DataBlock
		call	MemLock				; ax <- segment
		mov	cx, ax

		mov_tr	es, ax
assume	es:DataBlock
		mov	dx, es:[Comma_LineFeed_Repetition_Info_String]
							; cx:dx <- string
assume	es:nothing
		pop	ax
		call	SubstituteStringArg
	;
	; Find the right repetition string, ie, monthly, weekly, etc.
	;
		pop	cx				; cx <-MBRepeatInterval
	;
	; Handle special case, bi-weekly.
	;
		cmp	cx, MBRepeatInterval<0, 0, 1, MBRIT_WEEKLY>
		mov	di, offset BiweeklyString
		je	gotStringOffset

		andnf	cx, mask MBRI_TYPE		; cx <-
							; MBRepeatIntervalType
		Assert	etype, cx, MBRepeatIntervalType

		mov	di, cx
		shl	di
		mov	di, cs:[repetitionStringOffsetTable][di]
gotStringOffset:
	;
	; Replace repetition_token with the correct day string.
	;
		LocalLoadChar	ax, CONFIRM_DLG_REPETITION_ARG_CHAR
		mov	cx, es
		mov	dx, es:[di]			; cx:dx <- string
		call	SubstituteStringArg
	;
	; Unlock string resource.
	;
		; bx == resource handle
		Assert	handle, bx
		call	MemUnlock
quit:
		.leave
		Destroy	ax, cx, dx
		ret
noRepetition:
	;
	; Delete repetition token from string.
	;
		call	DeleteTokenFromString		; cx, dx destroyed
		jmp	quit
ReplaceTokenWithRepetition	endp

repetitionStringOffsetTable nptr \
	offset DailyString,		; MBRIT_DAILY
	offset WeeklyString,		; MBRIT_WEEKLY
	offset MonthlyString,		; MBRIT_MONTHLY_WEEKDAY
	offset MonthlyString,		; MBRIT_MONTHLY_DATE
	offset AnniversaryString,	; MBRIT_YEARLY_WEEKDAY	
	offset AnniversaryString,	; MBRIT_YEARLY_DATE	
	offset WorkingDaysString,	; MBRIT_MON_TO_FRI
	offset WorkingDaysString	; MBRIT_MON_TO_SAT (not
					;  specially handled)

CheckHack<length repetitionStringOffsetTable eq MBRepeatIntervalType>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithRepeatUntilDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token in the string with repetition text.

CALLED BY:	(INTERNAL) ReplaceTokenWithTimeRelatedInfo
PASS:		*ds:si	= chunk of text
		es	= MBAppointment struct
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If (no repeat) or (no RepeatUntilDate) {
		    replace token with null
		} else {
		    replace token with
		      Comma_LineFeed_Repeat_Until_Date_Time_String 
		    replace date/time token with real date/time.
		}

		A dword is at most 10 chars (2^32 = 4294967296).

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/25/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithRepeatUntilDate	proc	near
		uses	bx, es, di
		.enter
		Assert	segment, es
	;
	; Is there repetition?
	;
		mov	di, es:[MBA_repeatInfo]
		tst	di
		jz	noRepeatUntilDate

		cmp	es:[di].MBRI_duration, MBRD_UNTIL
		jne	noRepeatUntilDate
		
		mov	cx, es:[di].MBRI_durationData.MBRDD_until
							; cx <- FileDate
	;
	; Change the RepeatUntilDate token to
	; Comma_LineFeed_Repeat_Until_Date_Time_String.
	;
		push	cx
		push	ax
		
		mov	bx, handle DataBlock
		call	MemLock				; ax <- segment
		mov	cx, ax

		mov_tr	es, ax
assume	es:DataBlock
		mov	dx, es:[Comma_LineFeed_Repeat_Until_Date_Time_String]
							; cx:dx <- string
assume	es:nothing
		pop	ax
		call	SubstituteStringArg
	;
	; Get back until date, and replace date token with real date.
	;
		pop	cx				; cx <- FileDate
		mov	dx, MB_NO_TIME			; dx <- time, -1
		call	ReplaceDateTimeTokensWithDateTime
	;
	; Unlock string resource.
	;
		; bx == resource handle
		Assert	handle, bx
		call	MemUnlock
quit:
		.leave
		Destroy	ax, cx, dx
		ret

noRepeatUntilDate:
	;
	; Delete RepeatUntilDate token from string.
	;
		call	DeleteTokenFromString		; cx, dx destroyed
		jmp	quit
ReplaceTokenWithRepeatUntilDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithReplyStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token char in the text object by reply status.

CALLED BY:	(INTERNAL) CopyAndFormatWritableChunk
PASS:		*ds:si	= chunk of text
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
		cl	= CalendarEventReplyStatus (CERS_EVENT_ACCEPTED
			  or CERS_EVENT_DENIED)
		dl	= CalendarApptPasswdBool
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		if accepted: reply char with EventAcceptedText.
		if accepted and reply has password: this is a reply from
			reservation, so reply with EventConfirmedText.
		if denied: reply char with EventDeniedText.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithReplyStatus	proc	near
		uses	bx, dx, es, di
		.enter
		Assert	etype, cl, CalendarEventReplyStatus
		Assert	etype, dl, CalendarApptPasswdBool
	;
	; Lock down string resource for the string.
	;
		push	ax
		mov	bx, handle DataBlock
		call	MemLock				; ax <- segment
		mov_tr	es, ax
	;
	; Which text to be used?
	;
	; Denied?
	;
		cmp	cl, CERS_EVENT_DENIED
		mov	di, offset EventDeniedText	; denied?
		je	gotText
	;
	; Accepted, with password in reply?
	;
		Assert	e, cl, CERS_EVENT_ACCEPTED
		cmp	dl, CAPB_REPLY_OR_UPDATE_HAS_PASSWORD
		mov	di, offset EventConfirmedText	; accepted with passwd?
		je	gotText

		mov	di, offset EventAcceptedText
gotText:
		pop	ax
		mov	cx, es
		mov	dx, es:[di]			; cx:dx <- text
		call	SubstituteStringArg
	;
	; Unlock resource.
	;
		call	MemUnlock
		
		.leave
		Destroy	ax, cx
		ret
ReplaceTokenWithReplyStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepaceTokenWithUpdateAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token char in the text object with the
		update action ("removed from" or "changed in".)

CALLED BY:	(INTERNAL) CopyAndFormatWritableChunk
PASS:		*ds:si	= chunk of text
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
		cx	= CalendarApptStatusType
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		CalendarApptStatusType:
			CAST_NEED_ACTIONS
			CAST_ACCEPTED
			CAST_DECLINED
			CAST_DELETED
			CAST_CHANGED

		If status is "DELETED" or "CHANGED", replace token
		with RemovedFromText or ChangedInText.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/ 3/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RepaceTokenWithUpdateAction	proc	near
		uses	bx, es, di
		.enter
		Assert	etype, cx, CalendarApptStatusType
	;
	; If appointment status is not CAST_DELETED or CAST_CHANGED,
	; delete the token.
	;
		cmp	cx, CAST_DELETED
		jae	hasAction

		call	DeleteTokenFromString		; cx, dx destroyed
		jmp	quit
hasAction:
	;
	; Lock down string resource for the string.
	;
		push	ax
		mov	bx, handle DataBlock
		call	MemLock				; ax <- segment
		mov_tr	es, ax
	;
	; Which text to be used?
	;
		cmp	cx, CAST_DELETED
		mov	di, offset RemovedFromText	; deleted?
		je	gotText

		mov	di, offset ChangedInText	; must be changed
gotText:
		pop	ax
		mov	cx, es
		mov	dx, es:[di]			; cx:dx <- text
		call	SubstituteStringArg
	;
	; Unlock resource.
	;
		call	MemUnlock
quit:
		.leave
		Destroy	ax, cx, dx
		ret
RepaceTokenWithUpdateAction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithSenderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the token char in the text object with the
		sender info.

CALLED BY:	(INTERNAL) CopyAndFormatWritableChunk
PASS:		*ds:si	= chunk of text
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
		es	= segment containing MBAppointment struct
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithSenderInfo	proc	near
		.enter
		Assert	segment, es
	;
	; Substitute the argument with name string.
	;
		mov	cx, es
		lea	dx, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderName
							; cx:dx - substitution
		call	SubstituteStringArg

		.leave
		Destroy	ax, cx, dx
		ret
ReplaceTokenWithSenderInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatchSMSNumberAndGetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Match the passed SMS number in contdb, and fetch the
		name into the same buffer if we have a match.

CALLED BY:	(INTERNAL) ReplaceTokenWithSenderInfo
PASS:		es:di	= SMS number string
		cx	= size of string (including null)
RETURN:		es:di	= name string if SMS is matched in contdb;
			  not changed if no match
		carry	= set if no match
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MatchSMSNumberAndGetName	proc	near
		uses	ax, bx, cx, dx, si
		.enter
	;
	; Go match the SMS number.
	;
		mov	si, cx				; backup size

		mov	dl, CCT_SMS
		call	ContactMatchNumber		; dx.ax <- RecordID,
							;  cx <- FieldID,
							;  bx <- # matches,
							;  carry set if 
							;  not found
EC <		WARNING_C CALENDAR_SMS_NUMBER_NOT_FOUND_IN_CONTDB	>
		jc	quit
	;
	; Just some warnings for nice folks who run swat..
	;
EC <		cmp	bx, 1						>
EC <		WARNING_NE CALENDAR_SMS_NUMBER_MULTIPLE_MATCHES_IN_CONTDB>
	;
	; Go fetch the name of entry.
	; Get record handle.
	;
		call	ContactGetDBHandle		; bx <- db handle
		call	FoamDBGetRecordFromID		; ax <- block handle
							;  0 if deleted
		tst	ax
EC <		WARNING_Z CALENDAR_CONTACT_RECORD_DELETED		>
		stc					; assume no match
		jz	releaseDB
	;
	; And get name.
	;
		mov	cx, si				; cx <- size
		call	ContactGetTruncatedName
	;
	; Discard the record handle, now that we are done.
	;
		call	FoamDBDiscardRecord		; ax destroyed
		clc					; matched!
releaseDB:
	;
	; Release DB handle.
	;
		call	ContactReleaseDBHandle		; flags preserved
quit:
		.leave
		ret
MatchSMSNumberAndGetName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutUpFlashingNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up the right flashing note after user accepts / denies an
		incoming event, or sends an appointment.

CALLED BY:	(INTERNAL) HandleEventSMSMsg
PASS:		ax	= offset of string to use in DataBlock
RETURN:		^lbx:si	= dialog
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutUpFlashingNote	proc	near
if not _LOCAL_SMS
		uses	ax, cx, dx, bp
		.enter
	;
	; Turn off the flashing note if sending SMS text to local
	; responder.
	;
	;
	; Make the dialog first.
	;
		mov	bx, handle ConfirmFlashingNote
		mov	si, offset ConfirmFlashingNote
		call	UserCreateDialog		; ^lbx:si <- dialog
	;
	; Find the right text that goes into the flashing note
	; (ConfirmFlashingText).
	;
		push	si
		mov	si, offset ConfirmFlashingText
		mov	dx, handle DataBlock
		mov_tr	bp, ax				; ^ldx:bp <- text
	;
	; Replace ConfirmFlashingText text.
	;
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		clr	cx
		call	ObjMessage_mailbox_call		; ax, cx, dx, bp gone
		pop	si
	;
	; Initiate the dialog.
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage_mailbox_call		; ax, cx, dx, bp gone

		.leave
endif	; not _LOCAL_SMS
		ret
PutUpFlashingNote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BringDownFlashingNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring down the flashing note.

CALLED BY:	(INTERNAL)
PASS:		^lbx:si	= flashing note
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Because the flashing note has no duration (ie no
		timer) we cannot use MSG_FLASHING_NOTE_DISMISS_DIALOG.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/15/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BringDownFlashingNote	proc	near
if not _LOCAL_SMS
		uses	ax, cx
		.enter
		Assert	optr, bxsi
	;
	; Just do it.
	;
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	cx, IC_DISMISS
		call	ObjMessage_mailbox_send		; nothing destroyed
		
		.leave
endif	; not _LOCAL_SMS
		ret
BringDownFlashingNote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplyAcceptOrDeny
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reply (to an SMS) that the user accepts or denies the
		event appointment.

CALLED BY:	(INTERNAL) HandleEventSMSMsg
PASS:		es	= MBAppointment struct segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		User reply is already stored at the MBAppointment
		escape info.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_LOCAL_SMS
sendAppToken	GeodeToken <<'PLNR'>,MANUFACTURER_ID_GEOWORKS>
endif

ReplyAcceptOrDeny	proc	near
		uses	ax, bx, cx, dx, ds, si, es, di
myAppRef	local	VMTreeAppRef
mrma		local	MailboxRegisterMessageArgs
mta		local	MailboxTransAddr
		.enter
	;
	; Check we have a good SC number, or input one.
	;
		call	CheckServiceNumber		; carry set if error
		jc	error
	;
	; Process senderNumber.
	;
		segmov	ds, es
		lea	si, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderAddress
							; ds:si <- source
		mov	di, si				; es:di <- destination
		call	LocalStringLength		; cx <- # of chars
		call	CalStripNonNumeric		; cx <- # chars in
							;  dest string
	;
	; If the number is too long, change the length.
	;
		cmp	cx, TRANS_ADDR_STRING_MAX_LENGTH-1	; 23-1
		jbe	smsLengthGood
EC <		WARNING CALENDAR_SMS_NUMBER_TRUNCATED			>
		mov	cx, TRANS_ADDR_STRING_MAX_LENGTH-1
smsLengthGood:
	;
	; Address to receive this SMS, and user readable trans addr.
	;
		movdw	ss:[mta].MTA_transAddr, esdi
		lea	di, es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderName
		movdw	ss:[mta].MTA_userTransAddr, esdi
		mov	ss:[mta].MTA_transAddrLen, cx
	;
	; Now create the message in mailbox vm file.
	; Get mailbox VM file.
	;
		mov	bx, 1				; 1 VM block
		call	MailboxGetVMFile		; carry set on error,
							; else
							;  bx <- VMFileHandle,
							;  ax destroyed
		LONG jc	error
		Assert	vmFileHandle, bx
	;
	; Allocate a block of size INITIAL_VERSIT_TEXT_BLOCK_SIZE.
	;
		GetResourceSegmentNS	dgroup, ds
		mov	cx, INITIAL_VERSIT_TEXT_BLOCK_SIZE
		clr	ax				; user id?
		call	VMAlloc				; ax <- VM block handle
							; marked dirty
	;
	; Remember the chain info before we lose it.
	;
		mov	ss:[myAppRef].VMTAR_vmChain.segment, ax
		clr	ss:[myAppRef].VMTAR_vmChain.offset
		mov	ss:[myAppRef].VMTAR_vmFile, bx
	;
	; Lock down the block to write.
	;
		push	bp
		segmov	ds, es				; ds <- MBAppointment
		call	VMLock				; ax <- segment,
							; bp <- memory handle
		mov_tr	es, ax				; es <- segment to
							;  write
		call	CreateVersitReplyIntoBlock	; cx <- size of
							;  text written
		call	VMDirty
		call	VMUnlock			; es destroyed
		pop	bp
	;
	; Register a VM chain with the mailbox system.
	;
		CheckHack<MANUFACTURER_ID_GEOWORKS eq 0>
		clr	ss:[mrma].MRA_bodyStorage.MS_manuf
		mov	ss:[mrma].MRA_bodyStorage.MS_id, GMSID_VM_TREE
		clr	ss:[mrma].MRA_bodyFormat.MDF_manuf
		mov	ss:[mrma].MRA_bodyFormat.MDF_id, GMDFID_SHORT_MESSAGE
		mov	ss:[mrma].MRA_bodyRef.segment, ss
		lea	ax, ss:[myAppRef]
		mov	ss:[mrma].MRA_bodyRef.offset, ax
		mov	ss:[mrma].MRA_bodyRefLen, cx
	;
	; Allocate a DB item in the mailbox admin file to store
	; SMSendingOptions. This is passed to transport driver as trans
	; data. These options can also read from .ini file under category
	; [SMS].
	;
		push	bx
		call	MailboxGetAdminFile		; bx <- file handle
		Assert	vmFileHandle, bx
		mov	ax, DB_UNGROUPED
		mov	cx, size SMSendingOptions
		call	DBAlloc				; ax <- group,
							; di <- item
		movdw	ss:[mrma].MRA_transData, axdi
		call	DBLock				; *es:di <- item ptr
		mov	di, es:[di]
		mov	es:[di].SMSO_replyPath, SMRP_NO
		mov	es:[di].SMSO_validityPeriod, SMVP_24_HOURS
		CheckHack<SMMC_NORMAL eq 0>
		clr	es:[di].SMSO_messageConversion	; no conversion
		clr	es:[di].SMSO_dataCodingScheme
		clr	es:[di].SMSO_userDataLength
		clr	es:[di].SMSO_userDataHeader
	;
	; Read in center number from init file.
	;
		push	bp
		lea	di, es:[di].SMSO_scAddress	; es:di <- buffer
		segmov	ds, cs, cx
		mov	si, offset smsCategory		; ds:si <- category
		mov	dx, offset smsSCNumber		; cx:dx <- key
		mov	bp, InitFileReadFlags<IFCC_INTACT, 0, 0, \
					      size SMSO_scAddress>
		call	InitFileReadString		; cx <- # chars not
							;  including null
	;
	; Strip non numeric chars.
	;
		; es:di <- buffer
		segmov	ds, es, si
		mov	si, di				; ds:si <- buffer
		call	CalStripNonNumeric		; cx <- # chars
		pop	bp
	;
	; Mark the item dirty.
	;
		call	DBDirty
		call	DBUnlock			; es destroyed
	;
	; Transport info.
	;
if	_LOCAL_SMS
		mov	ss:[mrma].MRA_transport.MT_id, GMTID_LOCAL
else
		mov	ss:[mrma].MRA_transport.MT_id, GMTID_SM
endif
		clr	ss:[mrma].MRA_transport.MT_manuf
		clr	ss:[mrma].MRA_transOption
	;
	; Transport addr. mta is already filled.
	;
		mov	ss:[mrma].MRA_transAddrs.segment, ss
		lea	ax, ss:[mta]
		mov	ss:[mrma].MRA_transAddrs.offset, ax
		mov	ss:[mrma].MRA_numTransAddrs, 1
	;
	; Subject is the string MailboxReplySubjectText.
	;
		mov	bx, handle MailboxReplySubjectText
		call	MemLock
		mov_tr	ds, ax
		mov	ss:[mrma].MRA_summary.segment, ds
assume	ds:DataBlock
		mov	ax, ds:[MailboxReplySubjectText]
		mov	ss:[mrma].MRA_summary.offset, ax
assume	ds:nothing
	;
	; Flags and time.
	;
		mov	ss:[mrma].MRA_flags, CALENDAR_SEND_APPT_MAILBOX_FLAGS

		CheckHack<(MAILBOX_NOW eq 0)>
		clrdw	ss:[mrma].MRA_startBound	; MAILBOX_NOW
		movdw	ss:[mrma].MRA_endBound, MAILBOX_ETERNITY
	;
	; SMS receive app is the geode to receive the SMS text.
	;
if	_LOCAL_SMS		
		movtok	ss:[mrma].MRA_destApp, cs:[sendAppToken], ax
else
		movtok	ss:[mrma].MRA_destApp, cs:[smsAppToken], ax
endif
	;
	; do the register!
	;
		mov	cx, ss
		lea	dx, mrma
doTheRegister::
		call	MailboxRegisterMessage		; carry set on error
							; dxax <-MailboxMessage
	;
	; Unlock string resource.
	;
		call	MemUnlock			; ds destroyed
	;
	; Done with vm file
	;
		pop	bx				; file handle
		call	MailboxDoneWithVMFile
error:
		.leave
		ret
ReplyAcceptOrDeny	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateVersitReplyIntoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the reply in human readable form or
		versit format, and write it to the block allocated.

CALLED BY:	(INTERNAL) ReplyAcceptOrDeny
PASS:		ds	= segment of MBAppointment
		es	= segment of block to write to, of size
			  INITIAL_VERSIT_TEXT_BLOCK_SIZE
		cx	= size of buffer available
RETURN:		cx	= actual size of text written to block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		In the block, we want to put in:

		o	a word of NULL (for VMCL_next, because this is a VM
			block)

		o	reply prefix, as specified in MBAppointment

		if (UID string is "0") {
			Human readable reply
			--------------------
			Call CopyAndFormatWritableChunk to get the
			human-readable reply string.
			Copy to buffer
		} else {
			Call WriteReplyVersitFromRecvVersit
		}

		cx is used as bytes count as how much space is
		available in the buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateVersitReplyIntoBlock	proc	near
		uses	ax, bx, ds, si, di
		.enter
		Assert	segment, ds
		Assert	segment, es
		Assert	e, cx, INITIAL_VERSIT_TEXT_BLOCK_SIZE

		clr	di				; es:di <- destination
	;
	; This will be a VM block, which has VMChainLink at the start.
	;
		clr	es:[VMCL_next]
		add	di, size VMCL_next
		sub	cx, size VMCL_next

	;
	; Should we generate human readable reply or versit reply?
	; Look at escape info to find out.
	;
		cmp	ds:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_replyFormat, \
				CRSMSF_VERSIT
		je	doVersit
		
	;-----------------------------------------------------------------
	; Human readable reply.
	;-----------------------------------------------------------------
	; Construct the human readable reply.
	;
		push	es
		segmov	es, ds, si
		mov	si, EFST_UNKNOWN		; don't know which
							;  format string to use
		call	CopyAndFormatWritableChunk	; tempWritableChunk <-
							;  display string
		pop	es
	;
	; Copy that reply to buffer.
	;
		mov	bx, handle WritableStrings
		call	MemLock				; ax <- segment
		mov_tr	ds, ax
assume ds:WritableStrings
		mov	si, ds:[tempWritableChunk]	; ds:si <- string
assume nothing
		LocalCopyString
		LocalPrevChar	esdi			; for the null written
		call	MemUnlock
	;
	; Need to update char left count = INITIAL_VERSIT_TEXT_BLOCK_SIZE-di
	;
	; The tempWritableString should not be longer than
	; CONFIRM_DLG_DESC_TEXT_MAX_LENGTH so we should have space
	; left.
	;
		Assert	b, di, INITIAL_VERSIT_TEXT_BLOCK_SIZE
		mov	cx, INITIAL_VERSIT_TEXT_BLOCK_SIZE
		sub	cx, di
quit:
	;
	; Return size.
	;
		mov	cx, di
		
		.leave
		ret
doVersit:
		call	WriteReplyVersitFromRecvVersit
		jmp	quit

CreateVersitReplyIntoBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteReplyVersitFromRecvVersit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write reply in versit format to buffer, by copying
		(most of) the original recevied versit.

CALLED BY:	(INTERNAL) CreateVersitReplyIntoBlock
PASS:		ds	= segment of MBAppointment
		es	= segment of block to write to
		cx	= size of buffer available
RETURN:		cx	= actual size of text written to block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/23/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteReplyVersitFromRecvVersit	proc	near
		uses	ax, bx, dx, ds, si, bp
		.enter
		Assert	segment, ds
		Assert	segment, es

	;-----------------------------------------------------------------
	; Write reply prefix.
	;-----------------------------------------------------------------
	; Copy the CAET_smsReplyPrfx to buffer, if any.
	;
		lea	si, ds:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_smsReplyPrfx
							; ds:si <- prefix
EC <		LocalIsNull	ds:[si]					>
EC <		ERROR_Z CALENDAR_REPLY_PREFIX_NOT_IN_ESCAPE_INFO	>
		
		LocalCopyString				; ax destroyed,
							; si, di adjusted
		LocalPrevChar	esdi			; for the null written
		sub	cx, CALENDAR_BOOK_SMS_PREFIX_MAX_LENGTH*size TCHAR
	;
	; Add CR-LF.
	;
		call	WriteCRLF

	;-----------------------------------------------------------------
	; Versit reply.
	;-----------------------------------------------------------------
	; Simply copy the original versit text to the buffer. But we
	; should change the status to be (accepted/declined), and add
	; created-event-id.
	;

	;
	; Find the original versit text.
	;
		mov	dx, ds
		mov	bx, ds:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_versitVMFile
		mov	ax, ds:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_versitBlock
		call	VMLock				; ax <- segment,
							; bp <- mem handle of
							; VM block
		mov_tr	ds, ax
		mov	si, size VMChainLink		; ds:si <- text buffer
nextProp:
	;
	; Get next property.
	;
		call	GetNextProperty
EC <		ERROR_C	CALENDAR_NO_END_PROPERTY_FOUND_IN_VERSIT	>
NEC <		jc	quit						>
	;
	; Do we get "END:"?? (Special case because we would write
	; "created-event-id" property before  END:EVENT.
	;
		cmp	ax, VKT_END_PROP
		je	endFound
	;
	; Do we get "STATUS:"??
	;
		cmp	ax, VKT_STATUS_PROP
		je	statusFound
	;
	; Ignore X-NOKIA-CREATED-EVENT, because we are going to add
	; that later.
	;
		cmp	ax, VKT_X_NOKIA_CREATED_EVENT_PROP
		je	nextProp
	;
	; Write the versit keyword to buffer.
	;
		call	WriteVersitKeyword
	;
	; And copy the rest of string to buffer.
	;
		call	UnfoldAndCopyLine		; si, di, cx updated
		jmp	nextProp
statusFound:
	;
	; Write status.
	;
		; ax == VKT_STATUS_PROP
		; dx == MBAppointment segment
		Assert	e, ax, VKT_STATUS_PROP
		Assert	segment, dx

		call	WriteVersitKeyword
	;
	; Decide whether to write DECLINED / ACCEPTED depending on escape
	; info.
	;
		push	ds

		mov	ds, dx				; ds <- MBAppointment
		mov	bl, ds:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_userReply
		
		; DECLINED or ACCEPTED
		cmp	bl, CERS_EVENT_ACCEPTED
		mov	ax, VersitStringFlags<CRLF_YES, VKT_ACCEPTED_VAL>
		je	accepted
		
		Assert	e, bl, CERS_EVENT_DENIED
		mov	ax, VersitStringFlags<CRLF_YES, VKT_DECLINED_VAL>
accepted:
		call	WriteVersitKeyword

		pop	ds				; versit segment

		jmp	nextProp
endFound:
		; ax == VKT_END_PROP
		; dx == MBAppointment segment
		Assert	e, ax, VKT_END_PROP
		Assert	segment, dx
	;
	; Add created event ID.
	;
		push	ds
		mov	ds, dx
		movdw	dxax, \
			ds:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_createdEventID
		call	WriteCreatedEventID
		pop	ds
	;
	; Write END property.
	;
		; END:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_END_PROP>
		call	WriteVersitKeyword
	;
	; Write whatever that is left on the END: line.
	;
		call	UnfoldAndCopyLine		; si, di, cx updated

		; END:VCALENDAR
		mov	ax, VersitStringFlags<CRLF_YES, VKT_END_VCALENDAR>
		call	WriteVersitKeyword		; es:di, cx adjusted

quit::
		; bp == mem handle of VM block
		Assert	vmMemHandle, bp
		call	VMUnlock			; ds destroyed
		
		.leave
		ret
WriteReplyVersitFromRecvVersit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyLineNoUnfold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the rest of the line. Don't do any unfolding.

CALLED BY:	(INTERNAL)
PASS:		ds:si	= buffer to read from
		es:di	= buffer to write to
		cx	= # of bytes left in the write buffer
RETURN:		if end of buffer (NULL seen):
			carry	= set
		else
			carry	= cleared
		cx	= # of bytes count updated
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/23/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyLineNoUnfold	proc	near
		uses	ax
		.enter
nextChar:
	;
	; Is this a NULL?
	;
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, NULL
		je	nullFound
	;
	; Copy this character.
	;
		LocalPutChar	esdi, ax
		dec	cx				; update count
DBCS <		dec	cx						>
	;
	; Is this a line feed?
	;
		LocalCmpChar	ax, C_LF
		je	lfFound
	;
	; Check next char.
	;
		jmp	nextChar
lfFound:
	;
	; Is the next char a NULL?
	;
		LocalCmpChar	ds:[si], NULL
		je	nullFound
	;
	; Next one not null, so no error.
	;
		clc
quit:
		.leave
		ret
nullFound:
		stc					; carry set for NULL
		jmp	quit
CopyLineNoUnfold	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnfoldAndCopyLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the rest of the line to buffer.
		The line might be 'folded', ie. it is broken into two or more
		lines by folding technique. In that case, copy the next
		line(s) too.

CALLED BY:	(INTERNAL)
PASS:		ds:si	= buffer to read from
		es:di	= buffer to write to
		cx	= # of bytes left in the write buffer
RETURN:		if end of buffer (NULL seen):
			carry	= set
		else
			carry	= cleared
		cx	= # of bytes count updated
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Folding technique: if the start of next line is space or tab,
		the next line is considered a continuation of the current
		line.

		i.e.	CRLF + {SPACE|TAB}  <=> {SPACE|TAB}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/23/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnfoldAndCopyLine	proc	near
		.enter
nextLine:
		call	CopyLineNoUnfold		; carry set if NULL
		jc	quit
	;
	; Is the next char SPACE or TAB?
	;
		LocalCmpChar	ds:[si], C_SPACE
		je	nextLine			; a space, so copy
							; this line too
		LocalCmpChar	ds:[si], C_TAB
		je	nextLine
	;
	; Done, and next char is not null.
	;
		clc
quit:
		.leave
		ret
UnfoldAndCopyLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayErrorDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The incoming SMS cannot be parsed as versit format. 
		Put up a dialog and bail.

CALLED BY:	(INTERNAL)
PASS:		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayErrorDialog	proc	far
		uses	ax, bx, cx, dx, ds, si, di, bp
		.enter
	;
	; Find dialog.
	;
		mov	bx, handle BadSMSDialog
		mov	si, offset BadSMSDialog
		call	UserCreateDialog		; ^lbx:si <- dialog
	;
	; Lock it down to replace text.
	;
		call	ObjLockObjBlock
		mov_tr	ds, ax				; *ds:si <- dialog
	;
	; Replace the text in BadSMSText with BadSMSNotifyText.
	;
		push	si
		push	cx, dx				; MailboxMessage
		mov	dx, handle DataBlock
		mov	bp, offset BadSMSNotifyText	; ^ldx:bp - string
		mov	si, offset BadSMSText		; *ds:si - text obj
		clr	cx				; null terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		call	ObjCallInstanceNoLock		; ax, cx, dx, bp gone
	;
	; Substitute arguments.
	;
	; First, get *ds:si = chunk of text.
	;
		mov	si, ds:[si]
		add	si, ds:[si].Gen_offset
		mov	si, ds:[si].GTXI_text
	;
	; Change sender info.
	;
SBCS <		mov	al, CONFIRM_DLG_SENDER_CHAR			>
DBCS <		mov	ax, CONFIRM_DLG_SENDER_CHAR			>
		pop	cx, dx				; MailboxMessage
		call	ReplaceTokenWithSenderInfoFromMailboxMessage
							; ax, cx, dx destroyed
	;
	; Unlock block.
	;
		pop	si
		call	MemUnlock			; ds destroyed
	;
	; Do dialog.
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage_mailbox_call		; ax, cx, dx, bp
							; destroyed
		
		.leave
		ret
DisplayErrorDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTokenWithSenderInfoFromMailboxMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the MailboxMessage number, find the sender name
		/ sms number and replace the token in text with it.

CALLED BY:	(INTERNAL) DisplayErrorDialog
PASS:		*ds:si	= chunk of text
	SBCS<	al	= token char >
	DBCS<	ax	= token char >
		cx:dx	= MailboxMessage
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		Create MBAppointment struct.
		Fetch sender info, and put into MBAppointment struct.
		call ReplaceTokenWithSenderInfo.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTokenWithSenderInfoFromMailboxMessage	proc	near
		uses	bx, es
		.enter
	;
	; Allocate the struct.
	;
		call	AllocateAndInitMBAppointment	; es <- MBAppointment,
							;  bx <- block handle,
							;  carry set if error.
		jc	quit
	;
	; Fetch sender info to MBAppointment.
	;
		call	FetchSenderInfo
	;
	; Replace token.
	;
		call	ReplaceTokenWithSenderInfo	; ax, cx, dx destroyed
	;
	; Free the mem block we allocated.
	;
		; bx == block handle
		Assert	handle, bx
		call	MemFree				; es destroyed
quit:
		.leave
		ret
ReplaceTokenWithSenderInfoFromMailboxMessage	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SubstituteStringArg

DESCRIPTION:	Substitute a string for a character in a chunk.

CALLED BY:	(INTERNAL) CopyAndFormatWritableChunk

PASS:
	*ds:si - chunk to substitute in
	SBCS<	al - arg # to substitute for >
	DBCS<	ax - arg # to substitute for >
	
	cx:dx - string to substitute

RETURN:
	none

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version
	kho	3/ 7/96		Make ax = character in DBCS

------------------------------------------------------------------------------@
SubstituteStringArg	proc	near
		uses	ax, bx, cx, dx, di, si, es
if DBCS_PCGEOS

substString	local	fptr	push cx, dx
target		local	lptr	push si

else

substString	local	fptr
target		local	lptr
targetOffset	local	word

endif
	.enter

if DBCS_PCGEOS
	LONG	jcxz	done				; branch if no
							; substition string 

		; clr	ah				; ax <- character
		clr	bx
else
	LONG	jcxz	done
		mov	substString.handle, cx
		mov	substString.chunk, dx
		mov	target, si
		clr	targetOffset
endif

outerLoop:
SBCS <		mov	bx, targetOffset				>
		mov	si, target
		mov	di, ds:[si]
innerLoop:
SBCS <		mov	ah, ds:[di][bx]					>
DBCS <		mov	dx, ds:[di][bx]					>
SBCS <		tst	ah						>
DBCS <		tst	dx						>
		LONG jz	done
SBCS <		cmp	al, ah						>
DBCS <		cmp	ax, dx						>
		jz	match
		inc	bx
DBCS <		inc	bx						>
		jmp	innerLoop

match:
SBCS <		mov	targetOffset, bx				>

	; find the string length

		push	ax				; save the compare
							; value in AL
		les	di, substString
		mov	si, di
if DBCS_PCGEOS
		call	LocalStringLength		; cx <- length of
							; subst string
		mov	dx, cx				; dx <- length of
							; subst string
		dec	cx				; cx <- -1 for
							; replaced char
		sal	cx, 1				; cx <- # bytes change
		mov	ax, ss:target			; ax <- chunk of target
		js	delete				; branch if removing
							; bytes
else
		mov	cx, 1000
		clr	al
		repne	scasb
		sub	cx, 999-1			; since we will
							; replace a char
		neg	cx				; cx = # bytes
		mov	ax, target
		cmp	cx, 0				; possible to
							; substitute nothing
		jl	delete				; jump to remove bytes
endif
		call	LMemInsertAt
		mov	di, ax				; *ds:di = target
		mov	di, ds:[di]
SBCS <		add	di, targetOffset		; ds:di = dest	>
DBCS <		add	di, bx				; ds:di = dest	>
		segxchg	ds, es				; ds = source, es =
							; dest
SBCS <		inc	cx						>
SBCS <		rep	movsb						>
DBCS <		mov	cx, dx				; cx <- # of chars>
DBCS <		rep	movsw						>
		segmov	ds, es
		pop	ax				; restore compare
							; value to AL
		jmp	outerLoop
delete:
		neg	cx				; make into a
							; positive number
		call	LMemDeleteAt			; delete the byte(s)
		pop	ax				; restore compare
							; value to AL
		jmp	outerLoop			; loop again

done:
		.leave
		ret

SubstituteStringArg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateFileDateTimeRecords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create FileDate and FileTime structs based on the date/time
		passed from caller.

CALLED BY:	(INTERNAL)
PASS:		ax	= year (1980 through 2099)
		bl	= month (1 through 12)
		bh	= day (1 through 31)
		ch	= hours (0 through 23)
		dl	= minutes (0 through 59)
		dh	= seconds (0 through 59)
		ch:dl	= CAL_NO_TIME (-1) if no time specified
RETURN:		dx	= FileDate
		cx	= FileTime, MB_NO_TIME (-1) if no time specified
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version
	kho	11/24/96    	Modified from DOSGetTimeStamp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateFileDateTimeRecords	proc	near
		uses	ax, bx
		.enter
	;
	; Create the FileDate record first, as we need to use CL to the end...
	; 
		sub	ax, 1980	; convert to fit in FD_YEAR
			CheckHack <offset FD_YEAR eq 9>
		mov	ah, al
		shl	ah		; shift year into FD_YEAR
		mov	al, bh		; install FD_DAY in low 5 bits
		
		mov	cl, offset FD_MONTH
		clr	bh
		shl	bx, cl		; shift month into place
		or	ax, bx		; and merge it into the record
		xchg	dx, ax		; dx <- FileDate, al <- minutes,
					;  ah <- seconds
		xchg	al, ah
	;
	; Now for FileTime. Need seconds/2 and both AH and AL contain important
	; stuff, so we can't just sacrifice one. The seconds live in b<0:5> of
	; AL (minutes are in b<0:5> of AH), so left-justify them in AL and
	; shift the whole thing enough to put the MSB of FT_2SEC in the right
	; place, which will divide the seconds by 2 at the same time.
	; 
		cmp	ch, CAL_NO_TIME
		je	noTime
		
		shl	al
		shl	al		; seconds now left justified
		mov	cl, (8 - width FT_2SEC)
		shr	ax, cl		; slam them into place, putting 0 bits
					;  in the high part
	;
	; Similar situation for FT_HOUR as we need to left-justify the thing
	; in CH, so just shift it up and merge the whole thing.
	; 
		CheckHack <(8 - width FT_2SEC) eq (8 - width FT_HOUR)>
		shl	ch, cl
		or	ah, ch
		mov_tr	cx, ax		; smaller to do this than clr cl and
					;  or ax into cx...
quit:
		.leave
		ret
noTime:
		mov	cx, MB_NO_TIME	; -1
		jmp	quit
CreateFileDateTimeRecords	endp

MailboxCode	ends

endif	; HANDLE_MAILBOX_MSG
