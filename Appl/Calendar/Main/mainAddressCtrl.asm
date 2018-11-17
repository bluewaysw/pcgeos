COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Calendar/Main
FILE:		mainAddressCtrl.asm

AUTHOR:		Jason Ho, Dec 21, 1996

ROUTINES:
	Name				Description
	----				-----------
    MTD MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_SMS_NUM
				Get the SMS number of selected contact. The
				buffer should be at least
				MAX_NUMBER_FIELD_DATA_LEN+1 /
				MAX_NAME_DATA_LEN+1 chars big.

    MTD MSG_CALENDAR_ADDRESS_CTRL_GET_BOOK_ID
				Get the book ID of the current booking for
				the particular event.

    MTD MSG_CALENDAR_ADDRESS_CTRL_SET_BOOK_ID
				Set the book ID of the current booking for
				the particular event.

    MTD MSG_SMAC_CONTACT_SELECTED
				User pressed the "select" trigger in the
				address control. Get ready to send our
				message.

    MTD MSG_SMAC_MULTIPLE_CONTACTS_SELECTED
				User pressed the "select" trigger in the
				address control, and we are doing multiple
				selection. Get ready to send our message.

    MTD MSG_SMAC_MULTIPLE_RECENT_NUMBER_SELECTED
				Sent when the user has selected a "recent
				sms number" from the "recent contact"
				control, only this time the user selects
				multiple numbers.

    INT CloseContactListShowSummary
				Close the contact list, and show the
				summary of SMS event.

    INT GetNumberAndNameFromContdb
				Fetch the SMS number and name of a contact
				from the contdb.

    MTD MSG_SMAC_RECENT_NUMBER_SELECTED
				Sent when the user has selected a "recent
				sms number" from the "recent contact"
				control.

    MTD MSG_SMAC_MANUAL_DIALING	Received when the user presses the "manual
				dialing" trigger.

    MTD MSG_CALENDAR_ADDRESS_CTRL_MANUAL_DIAL_OK
				User enters the manual dial number, and
				presses OK.

    INT HandleManualNumberCommon
				Now that we have the manual / recent number
				in instance data, do name matching, fetch
				password if contact is found, etc.

    MTD MSG_CALENDAR_ADDRESS_CTRL_GET_MISC_FLAGS
				Get the CACI_miscFlags.

    MTD MSG_CALENDAR_ADDRESS_CTRL_COPY_SENT_TO_INFO
				From instance data, copy info to
				EventSentToStruct.

    MTD MSG_CALENDAR_ADDRESS_CTRL_FETCH_RECIPIENT_INFO
				Fetch the recipient info from contdb.

    MTD MSG_CALENDAR_ADDRESS_CTRL_FREE_SELECTION_BLOCKS
				Free the multiple selection mem blocks in
				instance.

    MTD MSG_SMAC_CANCEL		When the controller is closed, free all the
				blocks that are allocated for multiple
				recipient purpose.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		12/21/96   	Initial revision


DESCRIPTION:
	Code for CalendarAddressCtrlClass.
		

	$Id: mainAddressCtrl.asm,v 1.1 97/04/04 14:48:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HANDLE_MAILBOX_MSG

	;
	; There must be an instance of every class in a resource.
	;
idata		segment
	CalendarAddressCtrlClass
idata		ends

MailboxCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlGetSelectedSMSNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the SMS number of selected contact. The buffer
		should be at least MAX_NUMBER_FIELD_DATA_LEN+1 /
		MAX_NAME_DATA_LEN+1 chars big.

CALLED BY:	MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_SMS_NUM
		MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_NAME
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
		dx:bp	= Pointer to the text buffer
RETURN:		cx	= String length not counting the NULL
		dx, bp	= not changed
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlGetSelectedSMSNum method dynamic CalendarAddressCtrlClass,
				MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_SMS_NUM,
				MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_NAME,
				MSG_CALENDAR_ADDRESS_CTRL_GET_RECIPIENT_PASSWD
		.enter
		Assert	fptr, dxbp
	;
	; Get source
	;
		lea	si, ds:[di].CACI_selectedSMSNum	; ds:si <- src
		cmp	ax, MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_SMS_NUM
		je	gotSrc
		lea	si, ds:[di].CACI_selectedName	; ds:si <- src
		cmp	ax, MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_NAME
		je	gotSrc
		lea	si, ds:[di].CACI_recipientPasswd; ds:si <- src
gotSrc:
	;
	; Get destination
	;
		movdw	esdi, dxbp			; es:di <- dest
	;
	; Copy string!
	;
		LocalCopyString				; si, di adjusted,
							; ax destroyed
	;
	; Compute # char written.
	;
		mov	cx, di
		sub	cx, bp
DBCS <		shr	cx						>
		dec	cx				; not counting null

		.leave
		Destroy	ax
		ret
CalendarAddressCtrlGetSelectedSMSNum	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlGetBookId
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the book ID of the current booking for the
		particular event.

CALLED BY:	MSG_CALENDAR_ADDRESS_CTRL_GET_BOOK_ID
		MSG_CALENDAR_ADDRESS_CTRL_SET_BOOK_ID

PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #

PASS:		nothing
RETURN:		cx	= book ID
DESTROY:	ax

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 3/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlGetBookId	method dynamic CalendarAddressCtrlClass, 
					MSG_CALENDAR_ADDRESS_CTRL_GET_BOOK_ID
		.enter

		mov	cx, ds:[di].CACI_bookID

		.leave
		Destroy	ax
		ret
CalendarAddressCtrlGetBookId	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlSetBookId
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the book ID of the current booking for the
		particular event.

CALLED BY:	MSG_CALENDAR_ADDRESS_CTRL_SET_BOOK_ID
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
		cx	= book ID
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 5/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlSetBookId	method dynamic CalendarAddressCtrlClass, 
					MSG_CALENDAR_ADDRESS_CTRL_SET_BOOK_ID
		.enter
	;
	; Just set it.
	;
		mov	ds:[di].CACI_bookID, cx
		
		.leave
		Destroy	ax, cx
		ret
CalendarAddressCtrlSetBookId	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlContactSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User pressed the "select" trigger in the address
		control. Get ready to send our message.

CALLED BY:	MSG_SMAC_CONTACT_SELECTED
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
		cx:dx	= RecordID
		bp	= FieldID
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0	; old API
CalendarAddressCtrlContactSelected method dynamic CalendarAddressCtrlClass, 
					MSG_SMAC_CONTACT_SELECTED
		.enter
	;
	; We surely have matching contact.
	;
		ornf	ds:[di].CACI_miscFlags, mask CACF_HAS_MATCHING_CONTACT
	;
	; Get number and name from contdb, and store into instance
	; data.
	;
		call	GetNumberAndNameFromContdb	; ax, bx, cx, dx,
							; es, di destroyed
	;
	; Close the contact window and show the summary window.
	;
		call	CloseContactListShowSummary	; everything destroyed

		.leave
		ret
CalendarAddressCtrlContactSelected	endm
endif	; 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlMultipleContactsSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User pressed the "select" trigger in the address
		control, and we are doing multiple selection. Get
		ready to send our message.

CALLED BY:	MSG_SMAC_MULTIPLE_CONTACTS_SELECTED
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
		^hcx	= block containing sets of ContactListSelectedEntry
			  (MUST be freed by recipient)
		dx	= # of sets in the blocks	
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The block will be freed when the controller is closed
		(MSG_SMAC_CANCEL).

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/13/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlMultipleContactsSelected	method dynamic \
					CalendarAddressCtrlClass, 
					MSG_SMAC_MULTIPLE_CONTACTS_SELECTED
		.enter
		Assert	handle, cx
		Assert	e, ds:[di].CACI_selectedContactsHandle, 0
		Assert	e, ds:[di].CACI_recentContactsHandle, 0
	;
	; We surely have matching contact.
	;
		ornf	ds:[di].CACI_miscFlags, mask CACF_HAS_MATCHING_CONTACT
	;
	; Remember all the passed parameters in instance data.
	;
		mov	ds:[di].CACI_selectedContactsHandle, cx
		mov	ds:[di].CACI_numOfSelection, dx
	;
	; We don't have recent contacts.
	;
		clr	ds:[di].CACI_recentContactsHandle
	;
	; If just one selection, clear the flag
	; CACF_MULTIPLE_RECIPIENTS; else set the flag.
	;
		BitClr	ds:[di].CACI_miscFlags, CACF_MULTIPLE_RECIPIENTS
		cmp	dx, 1
		je	flagSet

		BitSet	ds:[di].CACI_miscFlags, CACF_MULTIPLE_RECIPIENTS
flagSet:
	;
	; Close the contact window and show the summary window.
	;
		call	CloseContactListShowSummary	; everything destroyed

		.leave
		Destroy	ax, cx, dx, bp
		ret
CalendarAddressCtrlMultipleContactsSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlMultipleRecentNumberSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent when the user has selected a "recent sms number"
		from the "recent contact" control, only this time the
		user selects multiple numbers.

CALLED BY:	MSG_SMAC_MULTIPLE_RECENT_NUMBER_SELECTED
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
		^hcx	= block containing RecentContactsData entries
		dx	= # of RecentContactsData entries
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The block will be freed when the controller is closed
		(MSG_SMAC_CANCEL).

		Clear the password, because recent number + calendar
		reservation would use the password.

		When doing multiple recent number reservation, if the
		number is not matched in contdb, a empty password
		would be used. So give a warning.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/13/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlMultipleRecentNumberSelected	method dynamic \
				CalendarAddressCtrlClass, 
				MSG_SMAC_MULTIPLE_RECENT_NUMBER_SELECTED
		.enter
		Assert	handle, cx
		Assert	e, ds:[di].CACI_selectedContactsHandle, 0
		Assert	e, ds:[di].CACI_recentContactsHandle, 0
	;
	; Remember all the passed parameters in instance data.
	;
		mov	ds:[di].CACI_recentContactsHandle, cx
		mov	ds:[di].CACI_numOfSelection, dx
	;
	; We don't have regular contacts selected.
	;
		clr	ds:[di].CACI_selectedContactsHandle
	;
	; If just one selection, clear the flag CACF_MULTIPLE_RECIPIENTS.
	;
		BitClr	ds:[di].CACI_miscFlags, CACF_MULTIPLE_RECIPIENTS
		cmp	dx, 1
		je	singleRecipient
	;
	; OK, set the flag CACF_MULTIPLE_RECIPIENTS.
	;
		BitSet	ds:[di].CACI_miscFlags, CACF_MULTIPLE_RECIPIENTS
	;
	; Give a warning if we are doing reservation.
	;
		call	GetBookEventType		; ax <-BookingEventType
							;  ds destroyed
		cmp	ax, BET_NORMAL_EVENT
		je	singleRecipient

		mov	cx, handle MultipleRecentNumersReservationWarning
		mov	dx, offset MultipleRecentNumersReservationWarning
		call	FoamDisplayNote

singleRecipient:
	;
	; Clear the password text.
	;
		mov	bx, handle PasswordText
		mov	si, offset PasswordText
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	ObjMessage_mailbox_call		; ax, cx, dx, bp gone
	;
	; Close the contact window and show the summary window.
	;
		call	CloseContactListShowSummary	; everything destroyed

		.leave
		Destroy ax, cx, dx, bp
		ret
CalendarAddressCtrlMultipleRecentNumberSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseContactListShowSummary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the contact list, and show the summary of SMS event.

CALLED BY:	(INTERNAL) CalendarAddressCtrlContactSelected,
			   CalendarAddressCtrlRecentNumberSelected,
			   CalendarAddressCtrlManualDialOK
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseContactListShowSummary	proc	near
		.enter
	;
	; Stuff the summary window. Have to do the stuffing on process
	; thread.
	;
		call	GeodeGetProcessHandle		; bx <- process handle
		clr	si
		mov	ax, MSG_CALENDAR_DISPLAY_EVENT_SUMMARY
		call	ObjMessage_mailbox_send
		
		.leave
		ret
CloseContactListShowSummary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNumberAndNameFromContdb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the SMS number and name of a contact from the
		contdb.

CALLED BY:	(INTERNAL) CalendarAddressCtrlContactSelected
PASS:		*ds:si	= CalendarAddressCtrlClass object
		cx:dx	= RecordID
		bp	= FieldID, 0 if none (i.e. only fetch name/passwd)
RETURN:		*ds:si	= CalendarAddressCtrlClass object
DESTROYED:	ax, bx, cx, dx, es, di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
		Store contact record ID and field ID into instance
		Get SMS number from contdb
		Get recipient password from contdb, if any
		Get name from contdb

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNumberAndNameFromContdb	proc	near
		.enter
		Assert	objectPtr, dssi, CalendarAddressCtrlClass
	;
	; Fetch the SMS number from contdb.
	;
	; Get record handle.
	;
		call	ContactGetDBHandle		; bx <- db handle
		movdw	dxax, cxdx			; dxax <- ID
		call	FoamDBGetRecordFromID		; ax <- block handle
							;  0 if deleted
		tst	ax
EC <		WARNING_Z CALENDAR_CONTACT_RECORD_DELETED		>
		jz	dbError
	;
	; Dereference, and get field data.
	;
		segmov	es, ds, cx
		tst	bp
		jz	numNotFetched
		mov	dx, bp				; dx <- field ID
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		lea	di, ds:[di].CACI_selectedSMSNum	; es:di <- buffer
		mov	cx, size CACI_selectedSMSNum-size TCHAR
		call	FoamDBGetFieldData		; cx <- bytes copied,
							;  carry set if
							;  field not found
EC <		WARNING_C CALENDAR_SMS_FIELD_NOT_FOUND_IN_CONTACT	>
		jc	dbError
	;
	; Null terminate the data string.
	;
		add	di, cx
		mov	{TCHAR} es:[di], C_NULL
numNotFetched:
	;
	; Get the password field. First, dereference.
	;
		; bx == db handle
		; ax == record handle
		; *ds:si == CalendarAddressCtrlClass object
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		lea	di, ds:[di].CACI_recipientPasswd; es:di <- buffer
		mov	cx, size CACI_recipientPasswd-size TCHAR
	;
	; Ensure password field is in record.
	;
		push	bx
		mov	dl, CFT_PASSWORD
		clr	bx
		call	ContactEnsureField		; dx <- field ID
		pop	bx
		call	FoamDBGetFieldData		; cx <- bytes copied,
							;  carry set if
							;  field not found
EC <		ERROR_C CALENDAR_ENSURED_PASSWORD_FIELD_NOT_FOUND	>
	;
	; Null terminate the data string.
	;
		add	di, cx
		mov	{TCHAR} es:[di], C_NULL
	;
	; Get the name field too. First, dereference.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		lea	di, ds:[di].CACI_selectedName	; es:di <- buffer
		call	ContactGetName			; carry set if unnamed
	;
	; Discard the record handle, now that we are done.
	;
		call	FoamDBDiscardRecord		; ax destroyed
dbError:
		call	ContactReleaseDBHandle

		.leave
		ret
GetNumberAndNameFromContdb	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlRecentNumberSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent when the user has selected a "recent sms number"
		from the "recent contact" control.

CALLED BY:	MSG_SMAC_RECENT_NUMBER_SELECTED
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
		ss:bp	= RecentContactsData
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Consider the "recent number" as manual entered number,
		because there is no guarantee that the contact it
		specifies (RCD_contactID) exists anyway.

		CACI_selectedSMSNum = recent number;
		HandleManualNumberLow();

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0	; old API
CalendarAddressCtrlRecentNumberSelected	method dynamic \
					CalendarAddressCtrlClass, 
					MSG_SMAC_RECENT_NUMBER_SELECTED
		.enter
	;
	; Copy the number field into instance data.
	;
		push	ds, si
		segmov	es, ds, ax
		lea	di, ds:[di].CACI_selectedSMSNum	; es:di <- destination
		segmov	ds, ss, ax
		mov	si, bp
		add	si, offset RCD_number
		LocalCopyString				; ax destroyed,
							; si, di adjusted
		pop	ds, si
	;
	; Do number matching, and close the contact list.
	;
		call	HandleManualNumberCommon	; everything destroyed

		.leave
		ret
CalendarAddressCtrlRecentNumberSelected	endm
endif	; 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlManualDialing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received when the user presses the "manual dialing" trigger.

CALLED BY:	MSG_SMAC_MANUAL_DIALING
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Clear the password, because manual dial + calendar
		reservation would use the password.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlManualDialing method dynamic CalendarAddressCtrlClass, 
					MSG_SMAC_MANUAL_DIALING
		.enter
	;
	; Clear the password text first.
	;
		mov	bx, handle PasswordText
		mov	si, offset PasswordText
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	ObjMessage_mailbox_call_fixup	; ax, cx, dx, bp gone
	;
	; Initiate the manual dialing dialog.
	;
		mov	bx, handle InputManualDialDialog
		mov	si, offset InputManualDialDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage_mailbox_send
		
		.leave
		ret
CalendarAddressCtrlManualDialing	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlManualDialOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User enters the manual dial number, and	presses OK.

CALLED BY:	MSG_CALENDAR_ADDRESS_CTRL_MANUAL_DIAL_OK
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		CACI_selectedSMSNum = ManualDialText;
		HandleManualNumberLow();

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlManualDialOK	method dynamic CalendarAddressCtrlClass, 
				MSG_CALENDAR_ADDRESS_CTRL_MANUAL_DIAL_OK
		.enter
	;
	; Remember that we have one recipient.
	;
		mov	ds:[di].CACI_numOfSelection, 1
	;
	; And of course, no multiple recipient.
	;
		BitClr	ds:[di].CACI_miscFlags, CACF_MULTIPLE_RECIPIENTS
	;
	; Get the SMS number to instance data.
	;
		push	si
		mov	bx, handle ManualDialText
		mov	si, offset ManualDialText
		mov	dx, ds
		lea	bp, ds:[di].CACI_selectedSMSNum
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage_mailbox_call_fixup	; cx <- str len not
							;  counting the NULL
		pop	si
	;
	; Do number matching.
	;
		call	HandleManualNumberCommon	; everything destroyed
	;
	; Close the contact window and show the summary window.
	;
		call	CloseContactListShowSummary	; everything destroyed

		.leave
		ret
CalendarAddressCtrlManualDialOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleManualNumberCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Now that we have the manual / recent number in
		instance data, do name matching, fetch password if contact is
		found, etc.

CALLED BY:	(INTERNAL) CalendarAddressCtrlManualDialOK,
		CalendarAddressCtrlRecentNumberSelected
PASS:		*ds:si	= CalendarAddressCtrlClass object
			  CACI_selectedSMSNum is filled in
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/27/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleManualNumberCommon	proc	near
		.enter
		Assert	objectPtr, dssi, CalendarAddressCtrlClass
	;
	; Redereference.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	; First assume that the manual number has matching contact.
	;
		ornf	ds:[di].CACI_miscFlags, mask CACF_HAS_MATCHING_CONTACT
	;
	; Get SMS number.
	;
		segmov	es, ds, ax 
		lea	di, ds:[di].CACI_selectedSMSNum	; es:di <- SMS num 
	;
	; Is the phone number matched in contdb?
	;
		mov	dl, CCT_SMS
		call	ContactMatchNumber		; dx.ax <- RecordID,
							;  cx <- FieldID,
							;  bx <- # matches,
							;  carry set if 
							;  not found
EC <		WARNING_C CALENDAR_SMS_NUMBER_NOT_FOUND_IN_CONTDB	>
		jc	noMatch
	;
	; Fetch the name and password into instance data.
	;
		; *ds:si == CalendarAddressCtrlClass object
		mov	cx, dx
		mov_tr	dx, ax				; cxdx <- RecordID
		clr	bp				; just fetch name
		call	GetNumberAndNameFromContdb	; ax, bx, cx, dx,
							; dx, es, di destroyed
quit:
		.leave
		ret
noMatch:
	;
	; Mark the CACI_selectedName field NULL because we have no match.
	;
		Assert	objectPtr, dssi, CalendarAddressCtrlClass
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	{TCHAR} ds:[di].CACI_selectedName, C_NULL
	;
	; And the number has no matching contacts.
	;
		andnf	ds:[di].CACI_miscFlags, \
				not (mask CACF_HAS_MATCHING_CONTACT)
		jmp	quit
		
HandleManualNumberCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlGetMiscFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the CACI_miscFlags.

CALLED BY:	MSG_CALENDAR_ADDRESS_CTRL_GET_MISC_FLAGS
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
RETURN:		cl	= CalAddressCtrlFlags
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/28/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlGetMiscFlags	method dynamic CalendarAddressCtrlClass, 
				MSG_CALENDAR_ADDRESS_CTRL_GET_MISC_FLAGS
		.enter
	;
	; Just return the flag.
	;
		mov	cl, ds:[di].CACI_miscFlags
		
		.leave
		ret
CalendarAddressCtrlGetMiscFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlCopySentToInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	From instance data, copy info to EventSentToStruct.

CALLED BY:	MSG_CALENDAR_ADDRESS_CTRL_COPY_SENT_TO_INFO
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
		cx:dx	= EventSentToStruct
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Fill in all fields:
			ESTS_bookID	word	; the # of booking that has
						;  been sent with the current
						;  event
			ESTS_yearSent	word	; date the appointment is sent
			ESTS_monthSent	byte
			ESTS_daySent	byte
			ESTS_hourSent	byte	; time the appointment is sent
			ESTS_minuteSent	byte
			ESTS_name	TCHAR XX dup (?)
						; name of recipient
			ESTS_smsNum	TCHAR YY dup (?)
						; SMS number of recipient
			ESTS_status	EventRecipientStatus
						; recipient's status
			ESTS_remoteEventID dword; ID of created event in 
						;  recipient's device

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	1/29/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlCopySentToInfo method dynamic CalendarAddressCtrlClass, 
				MSG_CALENDAR_ADDRESS_CTRL_COPY_SENT_TO_INFO
		uses	cx, dx, bp
		.enter
	;
	; Move regs to something useful.
	;
		mov	si, di				; ds:si <- instance
		movdw	esdi, cxdx			; es:di <- struct
	;
	; Copy book ID.
	;
		mov	ax, ds:[si].CACI_bookID		; book ID
		mov	es:[di].ESTS_bookID, ax
	;
	; Time / Date.
	;
		call	TimerGetDateAndTime		; ax <- year
							; bl <- month
							; bh <- day 
							; cl <- day of the week
							; ch <- hours 
							; dl <- minutes 
							; dh <- seconds 
		mov	es:[di].ESTS_yearSent, ax
		mov	{word} es:[di].ESTS_monthSent, bx; month & day
		mov	es:[di].ESTS_hourSent, ch
		mov	es:[di].ESTS_minuteSent, dl
	;
	; Copy name. We copy at most SENT_TO_NAME_FIELD_MAX_LEN (20)
	; chars, plus a null at the end.
	;
	; If the name is shorter than 20 chars, that's alright,
	; because we would have copied the NULL in the string, and the
	; string is then null-terminated.
	;
		mov	bx, si
		mov	bp, di				; backup si, di

		mov	cx, SENT_TO_NAME_FIELD_MAX_LEN
		lea	si, ds:[bx].CACI_selectedName	; ds:si <- src
		lea	di, es:[bp].ESTS_name		; es:di <- dest
		LocalCopyNString			; cx, si destroyed,
							;  di <- end of string
		LocalClrChar	es:[di]
	;
	; Copy SMS number too.
	;
		mov	cx, MAX_NUMBER_FIELD_DATA_LEN
		lea	si, ds:[bx].CACI_selectedSMSNum	; ds:si <- src
		lea	di, es:[bp].ESTS_smsNum		; es:di <- dest
		LocalCopyNString			; cx, si, di destroyed
		LocalClrChar	es:[di]
	;
	; Restore pointer.
	;
		mov	di, bp				; es:di <-
							; EventSentToStruct
	;
	; Clear unused fields.
	;
		movdw	es:[di].ESTS_remoteEventID, INVALID_EVENT_ID
	;
	; Status. If we are doing normal event, status is "no reply";
	;  if we are doing forced event, status is "forced".
	;
		call	GetBookEventType		; ax <-BookingEventType
							;  ds destroyed
		mov	cx, ERS_NO_REPLY
		cmp	ax, BET_NORMAL_EVENT
		je	gotStatus
		
		mov	cx, ERS_FORCED			; doing forced event
gotStatus:
		mov	es:[di].ESTS_status, cx

		.leave
		Destroy	ax
		ret
CalendarAddressCtrlCopySentToInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlFetchRecipientInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the recipient info from contdb.

CALLED BY:	MSG_CALENDAR_ADDRESS_CTRL_FETCH_RECIPIENT_INFO
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
		cx	= element number in contact selection list or
			  recent contact selection list (0 based)
RETURN:		carry set if element number out of bounds
		carry cleared otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/13/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlFetchRecipientInfo	method dynamic \
				CalendarAddressCtrlClass, 
				MSG_CALENDAR_ADDRESS_CTRL_FETCH_RECIPIENT_INFO
		uses	ax, cx, dx, bp
		.enter
	;
	; Is the number out of bound?
	;
		inc	cx
		cmp	ds:[di].CACI_numOfSelection, cx
		jb	quit				; jb == jc, carry set
		dec	cx
	;
	; Lock down the block that has the selected item info. We have
	; two handles in instance data, and one of them should be used;
	; the other should be zero.
	;
		mov	bx, ds:[di].CACI_selectedContactsHandle
		tst	bx
		jz	notRegularContact
		Assert	e, ds:[di].CACI_recentContactsHandle, 0
	;
	; Lock the block handle down.
	;
		call	MemLock				; ax <- segment
		mov_tr	es, ax
	;
	; Now, find our offset to the ContactListSelectedEntry in the
	; list.
	;
		; cx == element number
		clr	bp
		jcxz	offsetFound
addOffset:
		add	bp, size ContactListSelectedEntry
		loop	addOffset
offsetFound:
	;
	; Get our contact record ID and field ID.
	;
		movdw	cxdx, es:[bp].CLSE_recordID
		mov	bp, es:[bp].CLSE_fieldID
	;
	; Fetch our name and number and password.
	;
		push	bx
		call	GetNumberAndNameFromContdb	; ax, bx, cx, dx,
							;  es, di destroyed
popUnlock:
		pop	bx
	;
	; Unlock the block.
	;
		call	MemUnlock

		clc					; no error!
quit:
		.leave
		ret

	;----------------------------------------------------------------
	;
notRegularContact:
	;
	; Could it be recent contact? If not, then this is manual dial.
	;
		mov	bx, ds:[di].CACI_recentContactsHandle
		tst	bx
		clc					; assume manual
							;  dial, ie. no error.
		jz	quit
	;
	; Fetch the (cx)th number in the recent contact block.
	;
		call	MemLock				; ax <- segment
		mov_tr	es, ax		
	;
	; Now, find our offset to the RecentContactsData in the
	; list.
	;
		; cx == element number
		clr	bp
		jcxz	offsetFound2
addOffset2:
		add	bp, size RecentContactsData
		loop	addOffset2
	;
	; Copy the SMS number to instance data.
	;
offsetFound2:
		; es:bp == RecentContactsData
		; ds:di == CalendarAddressCtrl instance data
		push	ds, si
		segxchg	ds, es
		mov	si, bp
		add	si, offset RCD_number		; ds:si <- source
		lea	di, es:[di].CACI_selectedSMSNum	; es:di <- destination
		LocalCopyString				; ax destroyed,
							; si, di adjusted
		pop	ds, si
	;
	; Do number matching.
	;
		push	bx
		call	HandleManualNumberCommon	; everything destroyed
		jmp	popUnlock
		
CalendarAddressCtrlFetchRecipientInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlFreeSelectionBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the multiple selection mem blocks in instance.

CALLED BY:	MSG_CALENDAR_ADDRESS_CTRL_FREE_SELECTION_BLOCKS
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/15/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlFreeSelectionBlocks	method dynamic \
				CalendarAddressCtrlClass, 
				MSG_CALENDAR_ADDRESS_CTRL_FREE_SELECTION_BLOCKS
		.enter
	;
	; Free the first block.
	;
		clr	bx
		xchg	bx, ds:[di].CACI_selectedContactsHandle
		tst	bx
		jz	notHandle

		call	MemFree				; bx destroyed
notHandle:
	;
	; Free the second block.
	;
		clr	bx
		xchg	bx, ds:[di].CACI_recentContactsHandle
		tst	bx
		jz	quit

		call	MemFree				; bx destroyed
quit:
		
		.leave
		ret
CalendarAddressCtrlFreeSelectionBlocks	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAddressCtrlCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the controller is closed, free all the blocks
		that are allocated for multiple recipient purpose.

CALLED BY:	MSG_SMAC_CANCEL
PASS:		*ds:si	= CalendarAddressCtrlClass object
		ds:di	= CalendarAddressCtrlClass instance data
		ds:bx	= CalendarAddressCtrlClass object (same as *ds:si)
		es 	= segment of CalendarAddressCtrlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/14/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarAddressCtrlCancel	method dynamic CalendarAddressCtrlClass, 
					MSG_SMAC_CANCEL
	;
	; Free blocks first.
	;
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_FREE_SELECTION_BLOCKS
		call	ObjCallInstanceNoLock
	;
	; Call super.
	;
		mov	ax, MSG_SMAC_CANCEL
		mov	di, offset CalendarAddressCtrlClass
		GOTO	ObjCallSuperNoLock
CalendarAddressCtrlCancel	endm

MailboxCode	ends

endif	; HANDLE_MAILBOX_MSG
