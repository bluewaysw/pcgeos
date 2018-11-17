COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Calendar/Main
FILE:		mainUpdateEvent.asm

AUTHOR:		Jason Ho, Feb 11, 1997

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_CALENDAR_CANCEL_SENT_APPOINTMENT
				Cancel the selected event appointment in
				the sent-to view list.

    MTD MSG_CALENDAR_UPDATE_APPOINTMENT
				Update the booking in sent-to list of
				currently selected day event, if its time
				is changed.

    INT UpdateSentToElementCallback
				Callback from ChunkArrayEnum to update SMS
				booking.

    INT NonTimeUpdateSentToElementCallback
				Callback from ChunkArrayEnum to update SMS
				booking, knowing that the event time hasn't
				changed.

    INT CancelBookingOnSentToElementCallback
				Callback from ChunkArrayEnum to cancel SMS
				booking.

    INT SendUpdateSMSText	Send an update to the specified recipient
				(defined by the EventSentToStruct) through
				SMS.

    INT CreateVersitUpdateIntoBlock
				Create Versit update text and write it to
				the block that is allocated.

    INT UpdateWriteStatus	Write status to buffer, in versit format.

    INT UpdateWriteUID		Write unique ID string to buffer, in versit
				format.

    INT UpdateWritePassword	Write password information to buffer, in
				versit format, if the event was sent as a
				reservation.

    INT GetSelectedDayEventObject
				Util to get selected DayEventClass object.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/11/97   	Initial revision


DESCRIPTION:
	Code for cancelling and updating event appointment made on an
	event.
	

	$Id: mainUpdateEvent.asm,v 1.1 97/04/04 14:48:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HANDLE_MAILBOX_MSG

MailboxCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerCancelSentAppointment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel the selected event appointment in the sent-to
		view list.

CALLED BY:	MSG_CALENDAR_CANCEL_SENT_APPOINTMENT
PASS:		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/11/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerCancelSentAppointment	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_CANCEL_SENT_APPOINTMENT
		.enter
	;
	; Find the selected item in the list.
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	bx, handle SentToList
		mov	si, offset SentToList
		call	ObjMessage_mailbox_call		; ax <- selection,
							;  GIGS_NONE if none
							;  cx, dx, bp destroyed
		Assert	ne, ax, GIGS_NONE
		mov_tr	cx, ax
	;
	; Find the currently selected event.
	;
		call	GetSelectedDayEventObject	; ^lbx:si <- DayEvent,
							;  si <- 0 if none
							;  selected 
	;
	; If no event is selected, quit.
	;
		tst	si
EC <		WARNING_Z EVENT_HANDLE_DOESNT_EXIST_SO_OPERATION_IGNORED>
		jz	quit
		Assert	optr, bxsi
	;
	; Get the sent-to chunk array block/chunk of the event.
	;
		push	bx, si
		push	cx
		mov	ax, MSG_DE_GET_SENT_TO_CHUNK_ARRAY
		call	ObjMessage_mailbox_call		; cxdx <- block/chunk
		movdw	axsi, cxdx			; axsi <- block/chunk
		pop	cx				; cx <- selected item
	;
	; Lock down chunk array.
	;
		; ax:si == block / chunk
		call	LockChunkArrayFar		; *ds:si <-chunk array,
							;  bp <- mem handle,
							;  ax, bx destroyed
		mov_tr	ax, cx				; ax <- element to find
	;
	; Find our element.
	;
		call	ChunkArrayElementToPtr		; carry set if out of
							; bound,
							; ds:di <- element
EC <		ERROR_C	CALENDAR_INTERNAL_ERROR				>
NEC <		jc	unlockQuit					>
	;
	; Do a flashing note.
	;
		push	si
		mov	ax, offset StartingToSendUpdateText
		call	PutUpFlashingNote		; ^lbx:si <- dialog
	;
	; Send DELETE SMS.
	;
		mov	ax, STUT_DELETE
		call	SendUpdateSMSText
	;
	; Bring down flashing note.
	;
		call	BringDownFlashingNote
		pop	si				; *ds:si <-
							;  chunk array
	;
	; Delete the element. VM block is marked dirty.
	;
		call	ChunkArrayDelete		; ds:di <- next element
unlockQuit::
	;
	; Unlock vm block
	;
		; bp == VM mem handle
		Assert	vmMemHandle, bp
		call	VMUnlock			; ds destroyed
	;
	; Refresh the list.
	;
		pop	bx, si				; ^lbx:si <- DayEvent
		mov	ax, MSG_DE_DISPLAY_SENT_TO_INFO
		call	ObjMessage_mailbox_send
quit:		
		.leave
		Destroy	ax, cx, dx, bp
		ret
GeoPlannerCancelSentAppointment	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
		GeoPlannerUpdateAppointment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the booking in sent-to list of currently 
		selected day event, if its time is changed.

CALLED BY:	MSG_CALENDAR_UPDATE_APPOINTMENT
PASS:		ax	= message #
		bp	= chunk handle of currently selected DayEvent
				object
		cx:dx	= sent-to info vmblock / chunk handle of 
				currently selected DayEvent object
		si	= DayEventBookingFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/ 4/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerUpdateAppointment	method dynamic GeoPlannerClass, 
				MSG_CALENDAR_UPDATE_APPOINTMENT
		.enter
		Assert	record, si, DayEventBookingFlags
	;
	; Find the right callback, according to the booking flags.
	;
		test	si, mask DEBF_CANCEL_ALL_BOOKING
		mov	di, offset CancelBookingOnSentToElementCallback
		jnz	gotCallback
		
		test	si, mask DEBF_TIME_CHANGED
		mov	di, offset UpdateSentToElementCallback
		jnz	gotCallback

		Assert	bitSet, si, DEBF_NON_TIME_CHANGE
		mov	di, offset NonTimeUpdateSentToElementCallback
gotCallback:
	;
	; Do a flashing note.
	;
		mov	ax, offset StartingToSendUpdateText
		call	PutUpFlashingNote		; ^lbx:si <- dialog
		push	bx, si
		
	;
	; Lock down chunk array.
	;
		; cx:dx == block / chunk
		mov_tr	ax, cx
		mov	si, dx				; ax:si <- block/chunk

		mov	cx, handle DayPlanObject
		mov	dx, bp				; ^lcx:dx <-
							;  DayEventObject

		call	LockChunkArrayFar		; *ds:si <-chunk array,
							;  bp <- mem handle,
							;  ax, bx destroyed
	;
	; Do update on each and every element in sent-to chunk array.
	;
		; di == offset of callback routine to use
		mov	bx, SEGMENT_CS
		call	ChunkArrayEnum			; ax, bx destroyed
	;
	; Because we might change the book ID in the sent-to array, we should
	; mark the vm block dirty. Then unlock vm block
	;
		; bp == VM mem handle
		Assert	vmMemHandle, bp
		call	VMDirty
		call	VMUnlock			; ds destroyed

	;
	; Bring down flashing note.
	;
		pop	bx, si
		call	BringDownFlashingNote

		.leave
		Destroy	ax, cx, dx, bp
		ret
GeoPlannerUpdateAppointment	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
		UpdateSentToElementCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback from ChunkArrayEnum to update SMS booking.

CALLED BY:	(INTERNAL) GeoPlannerUpdateAppointment through ChunkArrayEnum
PASS:		*ds:si	= array
		ds:di	= array element (EventSentToStruct)
		^lcx:dx	= currently selected DayEventClass object
RETURN:		carry	= clear to continue enumeration
		cx:dx	= not to be changed
DESTROYED:	ax, bx
ALLOWED TO DESTROY:
		bx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Change the EventSentToStruct first, because now that time is
		changed, update is sent to recipient, and the status is
		changed.

		if (ESTS_status == ERS_DISCARDED) {
		    // if user declined, why update him/her?
		    quit
		} else if (ESTS_status >= ERS_FOR_RESERVATION) {
		    // booking was sent as reservation, not request
		    ESTS_status := ERS_FORCED
		} else {
		    ESTS_status := ERS_NO_REPLY
		}
		Get new book ID from DayEventClass
		Use new date time (ESTS_yearSent, monthSent, ...)
		Send SMS

		The chunk array item has new info, so make sure VMDirty is
		called after the enum!

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/ 5/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSentToElementCallback	proc	far
		uses	cx, dx
		.enter
		Assert	optr, cxdx

	;----------------------------------------------------------------
	;	Deal with status.
	;----------------------------------------------------------------
	; Has the recipient declined appointment already?
	;
		mov	ax, ds:[di].ESTS_status
		cmp	ax, ERS_DISCARDED
EC <		WARNING_E CALENDAR_EVENT_DENIED_SO_NO_UPDATE_SENT	>
		je	quit
	;
	; If event was sent as reservation, mark status ERS_FORCED.
	;
		cmp	ax, ERS_FOR_RESERVATION
		mov	ax, ERS_FORCED
		jae	hasNewStatus
	;
	; Mark status no-reply.
	;
		mov	ax, ERS_NO_REPLY
hasNewStatus:
		mov	ds:[di].ESTS_status, ax

	;----------------------------------------------------------------
	;	Deal with book id.
	;----------------------------------------------------------------
	;
		mov	ax, MSG_DE_USE_NEXT_BOOK_ID
		movdw	bxsi, cxdx			; ^lbx:si <- DayEvent
		call	ObjMessage_mailbox_call		; cx <- bookID,
							;  ax destroyed
		mov	ds:[di].ESTS_bookID, cx

	;----------------------------------------------------------------
	;	New date/time.
	;----------------------------------------------------------------
	;
		call	TimerGetDateAndTime		; ax <- year
							; bl <- month
							; bh <- day 
							; cl <- day of the week
							; ch <- hours 
							; dl <- minutes 
							; dh <- seconds 
		mov	ds:[di].ESTS_yearSent, ax
		mov	{word} ds:[di].ESTS_monthSent, bx; month & day
		mov	ds:[di].ESTS_hourSent, ch
		mov	ds:[di].ESTS_minuteSent, dl
		
	;----------------------------------------------------------------
	;	Send SMS
	;----------------------------------------------------------------
	;
	; Send UPDATE SMS.
	;
		; ds:di == EventSentToStruct
		mov	ax, STUT_TIME_CHANGE
		call	SendUpdateSMSText
quit:
	;
	; Carry cleared to continue enumeration.
	;
		clc
		
		.leave
		Destroy	ax
		ret
UpdateSentToElementCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
		NonTimeUpdateSentToElementCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback from ChunkArrayEnum to update SMS booking,
		knowing that the event time hasn't changed.

CALLED BY:	(INTERNAL) GeoPlannerUpdateAppointment through ChunkArrayEnum
PASS:		*ds:si	= array
		ds:di	= array element (EventSentToStruct)
		^lcx:dx	= currently selected DayEventClass object
RETURN:		carry	= clear to continue enumeration
		cx:dx	= not to be changed
DESTROYED:	ax, bx
ALLOWED TO DESTROY:
		bx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Only the event text (or alarm, maybe) is changed, so
		we send out SMS, and don't expect reply to come back.

		if (ESTS_status == ERS_DISCARDED) {
		    // if user declined, why update him/her?
		    quit
		}

		Use new date time (ESTS_yearSent, monthSent, ...)
		Send SMS

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/11/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NonTimeUpdateSentToElementCallback	proc	far
		uses	cx, dx
		.enter
		Assert	optr, cxdx

	;----------------------------------------------------------------
	;	Deal with status.
	;----------------------------------------------------------------
	; Has the recipient declined appointment already?
	;
		mov	ax, ds:[di].ESTS_status
		cmp	ax, ERS_DISCARDED
EC <		WARNING_E CALENDAR_EVENT_DENIED_SO_NO_UPDATE_SENT	>
		je	quit

	;----------------------------------------------------------------
	;	New date/time.
	;----------------------------------------------------------------
	;
		call	TimerGetDateAndTime		; ax <- year
							; bl <- month
							; bh <- day 
							; cl <- day of the week
							; ch <- hours 
							; dl <- minutes 
							; dh <- seconds 
		mov	ds:[di].ESTS_yearSent, ax
		mov	{word} ds:[di].ESTS_monthSent, bx; month & day
		mov	ds:[di].ESTS_hourSent, ch
		mov	ds:[di].ESTS_minuteSent, dl
		
	;----------------------------------------------------------------
	;	Send SMS
	;----------------------------------------------------------------
	;
	; Send UPDATE SMS.
	;
		; ds:di == EventSentToStruct
		mov	ax, STUT_NON_TIME_CHANGE
		call	SendUpdateSMSText
quit:
	;
	; Carry cleared to continue enumeration.
	;
		clc
		
		.leave
		Destroy	ax
		ret
NonTimeUpdateSentToElementCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CancelBookingOnSentToElementCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback from ChunkArrayEnum to cancel SMS booking.

CALLED BY:	(INTERNAL) GeoPlannerUpdateAppointment through ChunkArrayEnum
PASS:		*ds:si	= array
		ds:di	= array element (EventSentToStruct)
		^lcx:dx	= currently selected DayEventClass object
RETURN:		carry	= clear to continue enumeration
		cx:dx	= not to be changed
DESTROYED:	???
ALLOWED TO DESTROY:
		bx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/14/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CancelBookingOnSentToElementCallback	proc	far
		.enter
	;
	; Send DELETE SMS.
	;
		mov	ax, STUT_DELETE
		call	SendUpdateSMSText
	;
	; Delete the element. VM block is marked dirty.
	;
		call	ChunkArrayDelete		; ds:di <- next element
	;
	; Carry cleared to continue enumeration.
	;
		clc
		
		.leave
		ret
CancelBookingOnSentToElementCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendUpdateSMSText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an update to the specified recipient (defined by
		the EventSentToStruct) through SMS.

CALLED BY:	(INTERNAL) GeoPlannerCancelSentAppointment
PASS:		ds:di	= EventSentToStruct
		ax	= SentToUpdateType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/12/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendUpdateSMSText	proc	near
sentToPtr	local	fptr.EventSentToStruct	push	ds, di
updateType	local	SentToUpdateType	;push	ax -- esp limitation
myAppRef	local	VMTreeAppRef
mrma		local	MailboxRegisterMessageArgs
mta		local	MailboxTransAddr
recipientNum	local	MAX_NUMBER_FIELD_DATA_LEN+1 dup (TCHAR)		
		uses	ax, bx, cx, dx, ds, si, es, di
		.enter
		Assert	fptr, dsdi
		Assert	etype, ax, SentToUpdateType
		mov	ss:[updateType], ax
	;
	; If the recipient has denied the appointment before, don't
	; send any update.
	;
		cmp	ds:[di].ESTS_status, ERS_DISCARDED
EC <		WARNING_E CALENDAR_EVENT_DENIED_SO_NO_UPDATE_SENT	>
		je	quit
	;
	; Check we have a good SC number, or input one.
	;
		call	CheckServiceNumber		; carry set if error
		jc	quit
	;
	; Fill in recipientNum. We copy it to stack because we have to
	; process it.
	;
		lea	si, ds:[di].ESTS_smsNum		; ds:si <- src
		segmov	es, ss, dx
		lea	di, ss:[recipientNum]		; es:di <- dest
		LocalCopyString				; ax destroyed,
							;  si/di adjusted
	;
	; Get back string length.
	;
		lea	di, ss:[recipientNum]		; es:di <- number
		call	LocalStringLength		; cx <- # chars not
							;  counting null
	;
	; Strip non-numeric chars from recipientNum.
	;
		mov	ds, dx				; ds:si <- source
		mov	si, di
		; cx == # of chars
		; es:di == number string
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
	; If user readable trans addr is NULL, use the SMS number.
	;
		movdw	ss:[mta].MTA_transAddr, dssi
		movdw	dsdi, ss:[sentToPtr]		; ds:di <- sent-to
							;  struct
		lea	di, ds:[di].ESTS_name
		LocalCmpChar	ds:[di], C_NULL
		je	noName
		mov	si, di				; ds:si <- name
noName:
		movdw	ss:[mta].MTA_userTransAddr, dssi
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
		LONG jc	quit
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
		call	VMLock				; ax <- segment,
							; bp <- memory handle
		mov_tr	es, ax				; es <- segment to
							;  write
		mov_tr	ax, bp				; ax <- mem handle
		pop	bp
	;
	; The routine inherits variable, so bp has to be restored
	; before calling.
	;
		call	CreateVersitUpdateIntoBlock	; cx <- size of
							;  text written
		push	bp
		mov_tr	bp, ax
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
EC <		tst	cx						>
EC <		ERROR_Z CALENDAR_INTERNAL_ERROR				>
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
	; Subject is the string MailboxUpdateSubjectText.
	;
		mov	bx, handle MailboxUpdateSubjectText
		call	MemLock
		mov_tr	ds, ax
		mov	ss:[mrma].MRA_summary.segment, ds
assume	ds:DataBlock
		mov	ax, ds:[MailboxUpdateSubjectText]
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
		movtok	ss:[mrma].MRA_destApp, cs:[recvAppToken], ax
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
quit:		
		.leave
		ret
SendUpdateSMSText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateVersitUpdateIntoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create Versit update text and write it to the block
		that is allocated.

CALLED BY:	(INTERNAL) SendUpdateSMSText
PASS:		es	= segment of block to write to, of size
			  INITIAL_VERSIT_TEXT_BLOCK_SIZE
		cx	= size of buffer available
		ss:bp	= inherited args from SendUpdateSMSText
RETURN:		cx	= actual size of text written to block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		In the block, we want to put in:

		o	a word of NULL (for VMCL_next, because this is a VM
			block)
		o	[Calendar]bookSMSPrefix
		o	versit start keywords
		o	event text in versit format
		o	versit end keywords

		Since we are writing from es:[0], and es:di will be the next
		char to write to, di will be the size of text written.

		To-do item should not be updated, and to-do item
		booking is not supported anyway. So this routine
		doesn't look exactly like CreateVersitTextIntoBlock.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/12/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateVersitUpdateIntoBlock	proc	near
		uses	ax, bx, dx, ds, si, es, di
		.enter	inherit SendUpdateSMSText
		
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
	; Read the INI file, and put in the prefix header.
	;
		call	AddBookSMSPrefixHeader		; es:di <- EOS,
							; cx adjusted
	;
	; Write versit header.
	;
		; BEGIN:VCALENDAR
		mov	ax, VersitStringFlags<CRLF_YES, VKT_BEGIN_VCALENDAR>
		call	WriteVersitKeyword		; es:di, cx adjusted
		
		; VERSION:1.0
		mov	ax, VersitStringFlags<CRLF_YES, VKT_VERSION_1_0>
		call	WriteVersitKeyword		; es:di, cx adjusted
	;
	; Find the selected event.
	;
		call	GetSelectedDayEventObject	; ^lbx:si <- DayEvent
	;
	; If no event is selected, quit.
	;
		tst	si
EC <		WARNING_Z EVENT_HANDLE_DOESNT_EXIST_SO_OPERATION_IGNORED>
		stc					; assume error
		jz	done
	;
	; Write event header.
	;
		; BEGIN:EVENT
		mov	ax, VersitStringFlags<CRLF_YES, VKT_BEGIN_EVENT>
		call	WriteVersitKeyword
	;
	; Write category. We will hardcode a category because GeoPlanner does
	; not support it.
	;
		; CATEGORIES:APPOINTMENT
		mov	ax, VersitStringFlags<CRLF_YES, \
					      VKT_CATEGORIES_APPOINTMENT>
		call	WriteVersitKeyword
	;
	; Write status.
	;
		mov	dx, ss:[updateType]
		call	UpdateWriteStatus
	;
	; Write Start/End Time.
	;
		call	WriteStartTime
		call	WriteEndTime
	;
	; Write subject summary.
	;
		; SUBJECT:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_SUMMARY_PROP>
		call	WriteVersitKeyword
	;
	; Subject is the string MailboxUpdateSubjectText.
	;
		push	bx, si
		mov	bx, handle MailboxUpdateSubjectText
		call	MemLock
		mov_tr	ds, ax
assume	ds:DataBlock
		mov	si, ds:[MailboxUpdateSubjectText]
assume	ds:nothing
		call	CopyStringUpdateCount		; cx, di adjusted
		call	MemUnlock
		pop	bx, si		
		; add CRLF
		call	WriteCRLF
	;
	; Write description (event text).
	;
		call	WriteDescriptionText		
	;
	; Write alarm info, if any.
	;
		call	WriteAlarmInfo
	;
	; Write reservation day info, if any.
	;
		call	WriteReserveDaysInfo
	;
	; Write repeat info, if any.
	;
		call	WriteRepeatInfo
	;
	; Write unique identifier.
	;
		push	bp
		movdw	dsbp, ss:[sentToPtr]
		mov	dx, ds:[bp].ESTS_bookID
		call	UpdateWriteUID
	;
	; Write remote event ID, if any.
	;
		movdw	dxax, ds:[bp].ESTS_remoteEventID
		call	WriteCreatedEventID
	;
	; Write password, if the event was sent as "reservation".
	;
		mov	dx, ds:[bp].ESTS_status
		call	UpdateWritePassword

		pop	bp
	;
	; Write event end keywords.
	;
		; END:EVENT
		mov	ax, VersitStringFlags<CRLF_YES, VKT_END_EVENT>
		call	WriteVersitKeyword
	;
	; Write versit end keywords.
	;
		; END:VCALENDAR
		mov	ax, VersitStringFlags<CRLF_YES, VKT_END_VCALENDAR>
		call	WriteVersitKeyword		; es:di, cx adjusted
	;
	; Return size.
	;
		mov	cx, di
done::
		.leave
		ret
CreateVersitUpdateIntoBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWriteStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write status to buffer, in versit format.

CALLED BY:	(INTERNAL)
PASS:		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
		dx	= SentToUpdateType (STUT_TIME_CHANGE / STUT_DELETE /
			  STUT_NON_TIME_CHANGE)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We are writing...

			STATUS:DELETED
		or
			STATUS:CHANGED

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/15/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateWriteStatus	proc	near
		uses	ax
		.enter
		Assert	segment, es
		Assert	etype, dx, SentToUpdateType
	;
	; Enough space?
	;
		cmp	cx, size statusProp+\
			VERSIT_VALUE_KEYWORD_MAX_LENGTH*(size TCHAR)
		jb	quit				; carry set if b
	;
	; Write the property.
	;
		; STATUS:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_STATUS_PROP>
		call	WriteVersitKeyword
	;
	; Write the value. Changed?
	;
		mov	ax, VersitStringFlags<CRLF_YES, VKT_CHANGED_VAL>
		cmp	dx, STUT_TIME_CHANGE
		je	writeVal
	;
	; Non-time (Text/alarm) changed?
	;
		mov	ax, VersitStringFlags<CRLF_YES, VKT_TEXT_CHANGED_VAL>
		cmp	dx, STUT_NON_TIME_CHANGE
		je	writeVal
	;
	; Must be "deleted".
	;
		Assert	e, dx, STUT_DELETE
		mov	ax, VersitStringFlags<CRLF_YES, VKT_DELETED_VAL>
writeVal:
		call	WriteVersitKeyword

		clc					; no error
quit:
		.leave
		ret
UpdateWriteStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWriteUID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write unique ID string to buffer, in versit format.

CALLED BY:	(INTERNAL)
PASS:		^lbx:si	= DayEventClass object
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
		dx	= book ID of the current appointment
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We are writing...

			UID:9000i-131074-15

		ie.
			UID: lizzy-uid-prefix <unique ID> <book ID>

		max length is VERSIT_UID_STRING_MAX_LENGTH + length(UID:).

		This is different from WriteUID, because we should use
		the bookID from EventSentToStruct.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/15/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateWriteUID	proc	near
		uses	ax, dx
		.enter
		Assert	optr, bxsi
		Assert	segment, es
	;
	; Enough space?
	;
		cmp	cx, VERSIT_UID_STRING_MAX_LENGTH*(size TCHAR)+\
				(size uidProp)
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set if b
	;
	; Write the property.
	;
		; UID:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_UID_PROP>
		call	WriteVersitKeyword
	;
	; Write the lizzy UID Prefix with the dash.
	;
		; 9000i-
		mov	ax, VersitStringFlags<CRLF_NO, VKT_LIZZY_UID_PREFIX>
		call	WriteVersitKeyword
	;
	; Get the unique event ID.
	;
		push	dx
		push	cx
		mov	ax, MSG_DE_GET_UNIQUE_ID
		call	ObjMessage_mailbox_call		; cxdx <- unique ID

		mov_tr	ax, dx
		mov	dx, cx				; dxax <- ID
		pop	cx				; cx <- size
	;
	; Write the unique event ID.
	;
		call	WriteDWordToAscii		; di, cx updated
	;
	; Write the dash.
	;
		mov	ax, VersitStringFlags<CRLF_NO, VKT_DASH>
		call	WriteVersitKeyword
	;
	; Write the book ID.
	;
		pop	ax
		clr	dx				; dxax <- ID
		call	WriteDWordToAscii		; di, cx updated
		; add CRLF
		call	WriteCRLF

		clc					; no error
quit:		
		.leave
		ret
UpdateWriteUID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWritePassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write password information to buffer, in versit format, if
		the event was sent as a reservation.

CALLED BY:	(INTERNAL)
PASS:		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
		dx	= EventRecipientStatus
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We write:

			X-NOKIA-PASSWD:blahblah

		Password is at most CALENDAR_PASSWORD_LENGTH (8) chars
		long.

		If the recipient status is above ERS_FOR_RESERVATION, then
		the appointment was sent as reservation.
		If the recipient status is ERS_FORCED_BUT_DISCARDED, update
		should NOT be sent because SendUpdateSMSText should have
		ignored the case.

		Because we didn't store password in file, we will write
		master key password. The update will be used only if the
		original event is found in the receipient device.


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/16/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateWritePassword	proc	near
		uses	ax
		.enter
		Assert	segment, es
		Assert	etype, dx, EventRecipientStatus
	;
	; Do we have enough space to write info?
	;
		cmp	cx, VERSIT_PASSWORD_INFO_MAX_LENGTH
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set
	;
	; Do we have a valid reservation?
	;
		cmp	dx, ERS_FOR_RESERVATION
		jb	done
	;
	; Write the password.
	;
		; X-NOKIA-PASSWD
		mov	ax, VersitStringFlags<CRLF_NO, VKT_X_NOKIA_PASSWD_PROP>
		call	WriteVersitKeyword
	;
	; Write the master password.
	;
		LocalLoadChar	ax, MASTER_PASSWORD_CHAR
		LocalPutChar	esdi, ax
		dec	cx				; update count
DBCS <		dec	cx						>
	;
	; Write CRLF
	;
		call	WriteCRLF
done:
		clc
quit:
		.leave
		ret
UpdateWritePassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectedDayEventObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Util to get selected DayEventClass object.

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		^lbx:si	= DayEventClass
		si	= 0 if none selected
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/ 4/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectedDayEventObject	proc	near
		uses	ax, bp
		.enter
		mov	bx, handle DayPlanObject
		mov	si, offset DayPlanObject
		mov	ax, MSG_DP_GET_SELECT
		call	ObjMessage_mailbox_call		; bp <- DayEvent chunk

		mov	si, bp
		
		.leave
		ret
GetSelectedDayEventObject	endp

MailboxCode	ends

endif	; HANDLE_MAILBOX_MSG
