COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		rstartupECI.asm

AUTHOR:		Jason Ho, Jun 14, 1995

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		6/14/95   	Initial revision


DESCRIPTION:
	Code to handle ECI messages
	If _DO_ECI_SIM_CARD_CHECK is 0, nothing is included in this
	file.


	$Id: rstartupECI.asm,v 1.1 97/04/04 16:52:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DO_ECI_SIM_CARD_CHECK

CommonCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPVpClientEciReceive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a ECI message from the RU. The application have
		to free the message block after it is done with it.

CALLED BY:	MSG_VP_CLIENT_ECI_RECEIVE
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
		cx	= MemHandle of message structure
		dx	= messageId

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		switch (messageId) {
		    case ECI_SIM_INFO_STATUS (13002):
			// this case needed by UserDataEditDialog
			if (status_13002 != ECI_SIM_CARD_MISSING) {
			    extract user name and phone num
			    put into contdb
			}
			show UserDataEditDialog
			break;

		    default:
			return
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	6/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPVpClientEciReceive	method dynamic RStartupProcessClass, 
					MSG_VP_CLIENT_ECI_RECEIVE
		.enter
	;
	; lock the MemHandle
	;
		mov	bx, cx
		push	bx				; need to free the
							; block later
		call	MemLock
		mov_tr	ds, ax				; ds <- segment
	;
	; Depending on message, deal with them
	;
		cmp	dx, ECI_SIM_INFO_STATUS
		jne	20$

	;---------------------------------
	; ECI_SIM_INFO_STATUS
	;---------------------------------
	;
	; If we don't expect this message, don't answer
	;
		call	DerefDgroupES			; es <- dgroup
EC <		Assert	dgroup, es					>
		test	es:[eciSentFlags], mask	RSEF_SIM_INFO_STATUS_SENT
EC <		WARNING_Z ECI_SIM_INFO_STATUS_NOT_EXPECTED		>
		jz	quit
	;
	; Mark that we won't answer it the second time
	;
		BitClr	es:[eciSentFlags], RSEF_SIM_INFO_STATUS_SENT
	;
	; If there is SIM card, extract user info to contdb
	; Show the edit dialog
	;
		cmp	ds:[status_13002], ECI_SIM_CARD_MISSING
		je	showEditDialog

		call	RStartupAddOwnerInfo		; nothing destroyed
showEditDialog:
	;
	; Initialize the dialog
	;
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_UINFO_EDITOR
		call	CallProcess			; ax, cx, dx gone
20$:
quit:
		pop	bx
EC <		Assert	handle bx					>
		call	MemFree				; bx destroyed

		.leave
		ret
RSPVpClientEciReceive	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupAddOwnerInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add owner info to the contdb secret user data record, and
		save the record.

CALLED BY:	INTERNAL
PASS:		ds	- segment with struct STR_ECI_SIM_INFO_STATUS
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	6/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RStartupAddOwnerInfo	proc	near
		uses	ax, bx, cx, dx, si, es, di
		.enter
EC <		Assert	segment, ds					>
	;
	; Get the Contact DB handle
	;
		call	ContactGetDBHandle		; bx <- db handle
	;
	; Get the secret user data card record ID
	;
		call	ContactGetUserDataID		; dx.ax <- record id
	;
	; With the record ID, get the record from Contact DB
	;
		call	FoamDBGetRecordFromID		; ax <- block handle
							; 0 if deleted
							; inUseCount
							; incremented in FoamDB
EC <		Assert	ne, ax, 0					>
	;
	; Find field ID of "Phone", push it, and find field ID of "Name"
	;
		mov	cx, bx				; cx <- db handle
		clr	bx
		mov	dl, CFT_PHONE
		call	ContactEnsureField		; dx <- Phone ID
		push	dx
		mov	dl, CFT_NAME
		call	ContactEnsureField		; dx <- Name ID
		mov_tr	bx, cx
	;
	; Put Name/Phone fields into secret record
	;
		lea	si, ds:[own_name_13002]		; ds:si <- ptr to name
	;	lea	si, ds:[imsi_number_13002]	; ds:si <- ptr to name
		movdw	esdi, dssi
		call	LocalStringSize			; cx <- strlen
		call	FoamDBSetFieldData
		lea	si, ds:[own_number_13002]	; ds:si <- ptr to phone
		mov	di, si
		call	LocalStringSize
		pop	dx				; dx <- Phone ID
		call	FoamDBSetFieldData
	;
	; Save the record and release DB handle
	;
		call	ContactSaveRecord
		call	ContactReleaseDBHandle

		.leave
		ret
RStartupAddOwnerInfo	endp

CommonCode	ends

endif		; DO_ECI_SIM_CARD_CHECK


if 0		; THE REST OF THIS FILE IS ARCHIVE OF OLD THINGS NO
		; LONGER USE !!!!!!!!!!!!!!!!!!!!!!!!!!!!

this is used to deal with ECI_SIM_MEM_LOC_COUNT_STATUS
which is changed dramatically coz we don't do memory change
anymore

if DO_MEMORY_CHANGE		;++++++++++++++++++++++++++++++++++++++++++
	;
	; See how many contacts there are in the SIM card. If none, show
	; MemoryChangeDialog "Do you want to activate device memory instead
	; of SIM..." else show SIMMemoryDialog "Do you want to copy the
	; contents of SIM..." 
	;
	; MemoryChangeDialog and SIMMemoryDialog in same handle
	;
		mov	bx, handle MemoryChangeDialog
		mov	si, offset MemoryChangeDialog
		tst	ds:[contact_count_13010]
		jz	showMemDialog
		mov	si, offset SIMMemoryDialog
showMemDialog:
	;
	; Initialize the next dialog
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
		jmp	quit
else				; =========================================
		
endif				;++++++++++++ DO_MEMORY_CHANGE ++++++++++++


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPVpClientEciReceive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a ECI message from the RU. The application have
		to free the message block after it is done with it.

CALLED BY:	MSG_VP_CLIENT_ECI_RECEIVE
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
		cx	= MemHandle of message structure
		dx	= messageId

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		switch (messageId) {
		    case ECI_SIM_MEM_LOC_COUNT_STATUS (13010?):
			Responder's memory is set as active memory
			if (no contact) {
			    Final Start Up-view is shown.
			} else {
			    SimMemoryDialog is shown.
			}
			break;

		    case ECI_SIM_INFO_STATUS (13002):
			// this case needed by UserDataEditDialog
			if (status_13002 != ECI_SIM_CARD_MISSING) {
			    extract user name and phone num
			    put into contdb
			}
			show UserDataEditDialog
			break;

		    case ECI_SCM_SIM_READ_READY (6014):
			// we are copying SIM entries to Cmgr
			HandleSIMReadReady();
			break;

		    default:
			return
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	6/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPVpClientEciReceive	method dynamic RStartupProcessClass, 
					MSG_VP_CLIENT_ECI_RECEIVE

activeMemSetStr	local	STR_ECI_SCM_ACTIVE_MEM_SET
		.enter
	;
	; lock the MemHandle
	;
		mov	bx, cx
		push	bx				; need to free the
							; block later
		call	MemLock
		mov_tr	ds, ax				; ds <- segment
	;
	; Depending on message, deal with them
	;
		cmp	dx, ECI_SIM_MEM_LOC_COUNT_STATUS
		jne	10$

	;---------------------------------
	; ECI_SIM_MEM_LOC_COUNT_STATUS
	;---------------------------------
	;
if DO_MEMORY_CHANGE		;++++++++++++++++++++++++++++++++++++++++++
PrintMessage<This part of code is not valid if we do memory change \
		dialog again.>
endif				;++++++++++++ DO_MEMORY_CHANGE ++++++++++++
	;
	; Responder's memory is set as active memory
	;
		mov	ss:[activeMemSetStr].mem_type_6021, ECI_SCM_AD
		lea	ax, ss:[activeMemSetStr]

		push	bp
		sub	sp, size VpSendEciMessageParams
		mov	bp, sp
		mov	ss:[bp].VSEMP_eciMessageID, ECI_SCM_ACTIVE_MEM_SET
		movdw	ss:[bp].VSEMP_eciStruct, ssax
		call	VpSendEciMessage		; ax <- VpSendEciStatus
							; bx, cx destroyed
EC <		cmp	ax, VPSE_UNKNOWN_ECI_ID				>
EC <		ERROR_NC SEND_ECI_ERROR					>
		add	sp, size VpSendEciMessageParams
	;
	; if (no contact) {
	; 	Final Start Up-view is shown.
	; } else {
	; 	SimMemoryDialog is shown.
	; }
	; break;
	;
		tst	ds:[contact_count_13010]
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_EXIT
		jz	showExitDialog
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_SIM_MEMORY
		
showExitDialog:
		call	CallProcess			; ax, cx, dx,
							; bp destroyed
		pop	bp

		jmp	quit
10$:
		cmp	dx, ECI_SIM_INFO_STATUS
		jne	20$

	;---------------------------------
	; ECI_SIM_INFO_STATUS
	;---------------------------------
	;
	; If there is SIM card, extract user info to contdb
	; Show the edit dialog
	;
		cmp	ds:[status_13002], ECI_SIM_CARD_MISSING
		je	showEditDialog

		call	RStartupAddOwnerInfo		; nothing destroyed
showEditDialog:
	;
	; Initialize the dialog
	;
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_UINFO_EDITOR
		call	CallProcess			; ax, cx, dx gone
		jmp	quit	

20$:
		cmp	dx, ECI_SCM_SIM_READ_READY
		jne	quit

	;---------------------------------
	; ECI_SCM_SIM_READ_READY
	;---------------------------------
		call	HandleSIMReadReady	

quit:
		pop	bx
EC <		Assert	handle bx					>
		call	MemFree				; bx destroyed

		.leave
		ret
RSPVpClientEciReceive	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RequestSIMReadLocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a ECI request to read in one SIM location.

CALLED BY:	INTERNAL
PASS:		cx	= location to read (1-based, NOT 0-based)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	6/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RequestSIMReadLocation	proc	near
		uses	ax, bx, cx, es
eciStruct	local	STR_ECI_SCM_SIM_READ
		.enter
	;
	; Fill up the ECI struct
	;
		mov	ss:[eciStruct].req_id_6013, 1
		mov	ss:[eciStruct].location_6013, cx
	;
	; Send the structure off to VP lib
	;
		lea	ax, ss:[eciStruct]
		push	bp
		sub	sp, size VpSendEciMessageParams
		mov	bp, sp
		mov	ss:[bp].VSEMP_eciMessageID, ECI_SCM_SIM_READ
		movdw	ss:[bp].VSEMP_eciStruct, ssax
		call	VpSendEciMessage		; ax <- VpSendEciStatus
							; bx, cx destroyed
EC <		cmp	ax, VPSE_UNKNOWN_ECI_ID				>
EC <		ERROR_NC SEND_ECI_ERROR					>
		add	sp, size VpSendEciMessageParams
		pop	bp
		
		.leave
		ret
RequestSIMReadLocation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupMergeContact
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Merge the info to a contact in contdb (make a new record if
		necessary), and save it.

CALLED BY:	INTERNAL
PASS:		ds	- segment with struct STR_ECI_SCM_SIM_READ_READY
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Use ContactMatchName to search for names in contdb.
		Use ContactEnsureEmptyField to find or create an empty phone
		field in a record.

		We have name and phone number from struct.
		if (name is found in contdb -- record (*)) {
		    if (phone number is in that record (*)) {
			quit
		    } else {
			add new phone field to the record
		    }
		} else {
		    create new card
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	6/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RStartupMergeContact	proc	near
		uses	ax, bx, cx, dx, si, es, di
		.enter
EC <		Assert	segment, ds					>
	;
	; We will need es as segment for string operations
	;
		segmov	es, ds, bx			; es <- struct segment
	;
	; Get the Contact DB handle
	;
		call	ContactGetDBHandle		; bx <- db handle
	;
	; Do a search of name in contdb
	;
		push	bx
		lea	di, ds:[name_6014]
		mov	dl, CFT_NAME
		mov	bx, TRUE			; stop after first
							; match. 
		call	ContactMatchName		; dx.ax - RecordID,
							; cx - FieldID,
							; bx - #matches,
							; carry set if not
							; found 
		pop	bx
		jnc	mergeContact
	;
	; Get a new record
	;
		call	ContactCreateRecordFromTemplate	; ax <- record handle
EC <		Assert	ne, ax, 0					>
	;
	; Find field ID of "Phone", push it, and find field ID of "Name"
	;
		mov	cx, bx				; cx <- db handle
		clr	bx
		mov	dl, CFT_PHONE
		call	ContactEnsureField		; dx <- Phone ID
		push	dx
		mov	dl, CFT_NAME
		call	ContactEnsureField		; dx <- Name ID
		mov_tr	bx, cx
	;
	; Put Name/Phone fields into record
	;
		lea	si, ds:[name_6014]		; ds:si <- ptr to name
		mov	di, si
		call	LocalStringSize			; cx <- strlen
		call	FoamDBSetFieldData
		
		pop	dx				; dx <- Phone ID
		push	cx				; strlen(name)
		lea	si, ds:[number_6014]		; ds:si <- ptr to phone
		mov	di, si
		call	LocalStringSize			; cx <- strlen
		call	FoamDBSetFieldData
	;
	; If both strings are empty, ie. strlen(name) + strlen(phone) == 0,
	; discard the record  instead of saving it.
	;
		pop	dx				; dx <- strlen(name)
		add	cx, dx
		jcxz	discardRecord
save:
	;
	; Save the record and release DB handle
	;
		call	ContactSaveRecord		; dx.ax <- record ID
release:
		call	ContactReleaseDBHandle

		.leave
		ret
discardRecord:
		call	FoamDBDiscardRecord
		jmp	release
mergeContact:
	;
	; dx.ax - RecordID,
	; bx - contdb handle
	;
	; Get the record handle
	;
		call	FoamDBGetRecordFromID		; ax <- block handle,
							; 0 if deleted
							; inUseCount
							; incremented in FoamDB
EC <		Assert	ne, ax, 0					>
	;
	; Get string length of phone number to be searched
	;
		lea	di, ds:[number_6014]
		call	LocalStringSize			; cx <- strlen
	;
	; Find out if the phone number in STR_ECI_SCM_SIM_READ_READY is
	; already in the record.
	;
		push	bx, bp				; contdb handle and bp
		mov	dx, ds
		mov_tr	bp, di				; dx:bp - string to
							; search in record
		mov	bx, vseg SearchPhoneInOneRecordCallback
		mov	di, offset SearchPhoneInOneRecordCallback
		call	FoamDBFieldEnum			; cx <- TRUE if found
							; otherwise not changed
		pop	bx, bp				; bx <- contdb handle
	;
	; if phone already in record, do nothing
	;
		cmp	cx, TRUE
		je	discardRecord
	;
	; Add the phone number into a new phone field of the existing contdb
	; record
	;
		mov_tr	cx, bx				; cx <- contdb handle
		clr	bx
		mov	dl, CFT_PHONE
		call	ContactEnsureEmptyField		; dx <- Phone ID
		mov_tr	bx, cx				; bx <- contdb handle

		lea	si, ds:[number_6014]
		mov	di, si
		call	LocalStringSize			; cx <- strlen
		call	FoamDBSetFieldData		; dx <- field ID 

		jmp	save
		
RStartupMergeContact	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchPhoneInOneRecordCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a phone number string in the current field of a
		record. If this field is not CFT_PHONE, just skip to next
		field.

CALLED BY:	INTERNAL (RStartupMergeContact)
PASS:		ss:[bp] - inherited stack frame (for ss:[phoneNumLen])
		ds:si	- ptr to FieldHeader structure
		dx:bp 	- phone number string (NULL terminated)
		cx	- strlen(phone number to be searched in record)
RETURN:		cx 	- TRUE if passed string is same as phone number in
			  the field, and carry set abort callback
		carry clear otherwise
DESTROYED:	ds, es, si, di, as allowed by FoamDBFieldEnum
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	9/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchPhoneInOneRecordCallback	proc	far
		uses	ax
		.enter
	;
	; strlen cannot be -1, and beside, TRUE is used as return value of
	; FoamDBFieldEnum.
	;
EC <		Assert	ne, cx, TRUE					>

		cmp	ds:[si].FH_type, CFT_PHONE
		je	cmpString
traverseNext:
		clc
quit:
		.leave
		ret

cmpString:
		mov	ax, ds:[si].FH_size
DBCS <		shr	ax, 1						>
		cmp	cx, ax
		jne	traverseNext			; size not match
		add	si, offset FH_data		; ds:si - phone
							; string (1) in record
		mov	es, dx
		mov	di, bp				; es:bp - string (2) to
							; search
		call	LocalCmpStrings			; flags changed: 
							; cmp string1 string2
		jne	traverseNext			; string not same

		mov	cx, TRUE
		stc
		jmp	quit
SearchPhoneInOneRecordCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleSIMReadReady
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ECI message ECI_SCM_SIM_READ_READY is receive from
		RU. Depending on status, we should extract info to
		cmgr and request another read, or initiate the last
		dialog. 

CALLED BY:	INTERNAL
PASS:		ds	- segment with struct STR_ECI_SCM_SIM_READ_READY
		(6014)
		dx	- ECI_SCM_SIM_READ_READY
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		switch (status_6014) {
		    case ECI_SCM_SIM_NUMBER_TOO_LONG:
			Show warning
			(no break)
		    case ECI_OK:
			Read the name and phone
			Add to cmgr
			Request next SIM location info
			break
		    case ECI_SCM_SIM_COMMUNICATION_ERROR:
			show ExitDialog
		    case ECI_SCM_LOCATION_ILLEGAL:
			show ExitDialog
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	6/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleSIMReadReady	proc	near
		.enter
		
EC <		Assert	segment, ds					>
EC <		Assert	e, dx, ECI_SCM_SIM_READ_READY			>

		cmp	ds:[status_6014], ECI_SCM_SIM_NUMBER_TOO_LONG
		jne	10$

	;---------------------------------
	; status: ECI_SCM_SIM_NUMBER_TOO_LONG
	;---------------------------------
	;
	; show warning
	;
		mov	cx, handle PhoneNumberTooLongText
		mov	dx, offset PhoneNumberTooLongText
		call	FoamDisplayWarning
		jmp	addRecord
10$:
		cmp	ds:[status_6014], ECI_OK
		jne	20$
addRecord:
	;---------------------------------
	; status: ECI_OK
	;---------------------------------
	;
	; add info to contact db
	;
		call	RStartupMergeContact
	;
	; ask for the next SIM Location reading
	;
		push	cx
		mov	cx, ds:[location_6014]
		inc	cx
		call	RequestSIMReadLocation
		pop	cx
		jmp	quit
20$:
		cmp	ds:[status_6014], ECI_SCM_SIM_COMMUNICATION_ERROR
		je	showExit
		cmp	ds:[status_6014], ECI_SCM_LOCATION_ILLEGAL
		je	showExit
quit:
		.leave
		ret
showExit:
	;---------------------------------
	; status: ECI_SCM_SIM_COMMUNICATION_ERROR
	;	  / ECI_SCM_LOCATION_ILLEGAL
	;---------------------------------
	;
	; bring down "Copying..." dialog, and show ExitDialog
	;
		push	ax, cx, dx, bp
		mov	ax, MSG_RSTARTUP_PROCESS_STOP_COPYING
		call	CallProcess			; ax, cx, dx,
							; bp destroyed.
		pop	ax, cx, dx, bp
		jmp	quit
HandleSIMReadReady	endp


endif
