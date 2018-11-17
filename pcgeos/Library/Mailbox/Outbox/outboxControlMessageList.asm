COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxControlMessageList.asm

AUTHOR:		Adam de Boor, Mar 22, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/22/95		Initial revision


DESCRIPTION:
	Class to display messages in the MailboxOutboxControl
		

	$Id: outboxControlMessageList.asm,v 1.1 97/04/05 01:21:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource

if	_RESPONDER_OUTBOX_CONTROL
	OutboxControlHeaderViewClass
	OutboxControlHeaderGlyphClass
endif	; _RESPONDER_OUTBOX_CONTROL

	OutboxControlMessageListClass

MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLMlGetScanRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the routines to call for building the list
		(RESPONDER ONLY)

CALLED BY:	MSG_ML_GET_SCAN_ROUTINES
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
		cx:dx	= MLScanRoutines to fill in
RETURN:		MLScanRoutines filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLMlGetScanRoutines method dynamic OutboxControlMessageListClass, 
				MSG_ML_GET_SCAN_ROUTINES
		.enter
		movdw	esdi, cxdx
		mov	es:[di].MLSR_select.offset, offset OCMLSelect
		mov	es:[di].MLSR_select.segment, vseg OCMLSelect
		mov	es:[di].MLSR_compare.offset, offset OCMLCompare
		mov	es:[di].MLSR_compare.segment, segment OCMLCompare
		.leave
		ret
OCMLMlGetScanRoutines endm
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this message should be displayed

CALLED BY:	(EXTERNAL) MessageList::ML_RESCAN
PASS:		dxax	= MailboxMessage to check
		bx	= admin file
		*ds:si	= OutboxControlMessageList object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	message+address(es) may be added to the list

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLSelect	proc	far
msg		local	MailboxMessage	push	dx, ax
listObj		local	dword		push	ds, si
	ForceRef	msg		; used by address callback
		uses	bx, di, cx
		class	OutboxControlMessageListClass
		.enter
	;
	; Enumerate all the addresses, adding each one to the list if it hasn't
	; been sent to yet.
	;
		clr	cx		; cx <- address #
		mov	bx, vseg OCMLSelectCallback
		mov	di, offset OCMLSelectCallback
		call	MessageAddrEnum
		lds	si, ss:[listObj]
		.leave
		ret
OCMLSelect 	endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLSelectCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the address hasn't been sent to yet, add it to the list.
		(RESPONDER ONLY)

CALLED BY:	(INTERNAL) OCMLSelect via MessageAddrEnum
PASS:		ds:di	= MailboxInternalTransAddr
		*ds:si	= address array
		*ds:bx	= MailboxMessageDesc
		ss:bp	= inherited frame
		cx	= address #
RETURN:		carry set to stop enumerating (always clear)
		cx incremented
DESTROYED:	ax, bx, dx, si, di all allowed
SIDE EFFECTS:	message added to message list

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLSelectCallback proc	far
		class	OutboxControlMessageListClass
		uses	ds
		.enter	inherit	OCMLSelect
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	done
	;
	; Tell the list object to add this message + address, since it's not
	; been sent yet.
	;
		mov	bx, ds:[bx]	; ds:bx = MMD
		push	cx, bp
		mov	dx, cx		; dx = address #

		StructPushBegin	MLMessage
		mov	al, ds:[di].MITA_flags
			CheckHack <offset MTF_STATE + width MTF_STATE eq 8>
		mov	cl, offset MTF_STATE
		shr	al, cl		; al = MailboxAddressState
		StructPushField	MLM_state, ax	; MLM_state + MLM_priority (we
						;  don't use MLM_priority for
						;  comparison so we are pushing
						;  trash here
		StructPushField	MLM_registered, \
			<ds:[bx].MMD_registered.FDAT_time, \
			 ds:[bx].MMD_registered.FDAT_date>
		StructPushField	MLM_autoRetryTime, \
			<ds:[bx].MMD_autoRetryTime.FDAT_time, \
			 ds:[bx].MMD_autoRetryTime.FDAT_date>
		StructPushField	MLM_medium, ds:[di].MITA_medium
		StructPushField	MLM_transport, \
			<ds:[bx].MMD_transport.MT_manuf, \
			 ds:[bx].MMD_transport.MT_id>
		StructPushField	MLM_address, dx
		StructPushField	MLM_message, <ss:[msg].high, ss:[msg].low>
		StructPushEnd
		call	MailboxGetAdminFile	; bx <- admin file

		lds	si, ss:[listObj]
		mov	bp, sp			; ss:bp = MLMessage
		call	MessageListAddMessage
		add	sp, size MLMessage
		pop	cx, bp
	;
	; Record fixed-up object segment
	;
		mov	ss:[listObj].segment, ds
done:
		inc	cx			; advance address # for next
						;  callback
		clc				; CF <- keep going
		.leave
		ret
OCMLSelectCallback endp
endif	; _RESPONDER_OUTBOX_CONTROL

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two message entries for sorting purposes.
		(RESPONDER ONLY)

CALLED BY:	(EXTERNAL) MessageList::ML_RESCAN
PASS:		ds:si	= MLMessage #1
		es:di	= MLMessage #2 (ds = es)
RETURN:		flags set so caller can jl, je, or jg according as
		ds:si is less than, equal to, or greater than es:di
DESTROYED:	ax, bx, cx, dx, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		sorting fields are (in order of precedence):
			GMTID_SM before anything else
			MTF_SENDING before anything else
			MTF_QUEUED before anything else
			numeric order of medium tokens (very arbitrary,
				but groups messages using same medium
				even if using different transports)
			closer open-window time
			address #

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLCompare	proc	far
		.enter
		call	OCMLCompareTransports
		jne	done
		call	OCMLCompareMedia
		jne	done
		call	OCMLCompareState
		jne	done
		call	OCMLCompareRetry
		jne	done
		call	OCMLCompareAddressNumbers
		jne	done
		call	OCMLCompareRegistrationTime
done:
		.leave
		ret
OCMLCompare	endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLCompareTransports
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the transports of the two messages to determine if
		one should be before the other

CALLED BY:	(INTERNAL) OCMLCompare
		ds:si	= MLMessage #1
		es:di	= MLMessage #2 (ds = es)
RETURN:		flags set so jl, je, or jg will take according as message #1
			should come before, equivalent to, or after message #2
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLCompareTransports proc near
		.enter
		clr	ax	; assume both or neither is SMS
		CmpTok	ds:[si].MLM_transport, \
				MANUFACTURER_ID_GEOWORKS, \
				GMTID_SM, \
				checkSecondMessage
		dec	ax	; set so JL will take if second not SMS
checkSecondMessage:
		CmpTok	ds:[di].MLM_transport, \
				MANUFACTURER_ID_GEOWORKS, \
				GMTID_SM, \
				checkResult
		inc	ax	; set so JG will take if first not SMS,
				;  or JE will take if first was SMS
checkResult:
		tst	ax
		.leave
		ret
OCMLCompareTransports endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLCompareState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the MTF_STATE flag of the two addresses to determine
		if one should be before the other

CALLED BY:	(INTERNAL) OCMLCompare
		ds:si	= MLMessage #1
		es:di	= MLMessage #2 (ds = es)
RETURN:		flags set so jl, je, or jg will take according as message #1
			should come before, equivalent to, or after message #2
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		if the MTF_STATE flag of one address is numerically larger
			than the other, that address should come first

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLCompareState proc near
		.enter
		mov	al, ds:[si].MLM_state
		cmp	ds:[di].MLM_state, al	; order is purposedly inverted
						;  because ordering is inverse
						;  from ordering of state
						;  values
		.leave
		ret
OCMLCompareState endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLCompareMedia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the media tokens of the two addresses to determine
		if one should be before the other

CALLED BY:	(INTERNAL) OCMLCompare
		ds:si	= MLMessage #1
		es:di	= MLMessage #2 (ds = es)
RETURN:		flags set so jl, je, or jg will take according as message #1
			should come before, equivalent to, or after message #2
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLCompareMedia proc near
		.enter
		mov	ax, ds:[si].MLM_medium
		cmp	ax, ds:[di].MLM_medium
		.leave
		ret
OCMLCompareMedia endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLCompareRetry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the autoRetryType stamp of the two messages to
		determine if one should be before the other

CALLED BY:	(INTERNAL) OCMLCompare
		ds:si	= MLMessage #1
		es:di	= MLMessage #2 (ds = es)
RETURN:		flags set so jl, je, or jg will take according as message #1
			should come before, equivalent to, or after message #2
DESTROYED:	ax, cx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLCompareRetry proc near
		.enter
		clr	ax	; assume equal
		mov	cx, ds:[si].MLM_autoRetryTime.FDAT_date
		cmp	cx, ds:[di].MLM_autoRetryTime.FDAT_date
		jne	setFlags		; => set flags from date
						;  difference
		mov	cx, ds:[si].MLM_autoRetryTime.FDAT_time
		cmp	cx, ds:[di].MLM_autoRetryTime.FDAT_time
setFlags:
		je	checkResult		; => leave ax alone
		dec	ax			; assume < (doesn't change CF)
		jb	checkResult
		neg	ax
checkResult:
		tst	ax
		.leave
		ret
OCMLCompareRetry endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLCompareAddressNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the indices of the two addresses to determine
		if one should be before the other

CALLED BY:	(INTERNAL) OCMLCompare
		ds:si	= MLMessage #1
		es:di	= MLMessage #2 (ds = es)
RETURN:		flags set so jl, je, or jg will take according as message #1
			should come before, equivalent to, or after message #2
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLCompareAddressNumbers proc near
		.enter
	;
	; We do our own double comparison instead of using "cmpdw", because
	; all we care is whether they are equal or not.  This way we can avoid
	; jumping twice if the first match fails.  And we can compare the low
	; word first (which is more likely to differ than the high word).
	;
		mov	ax, ds:[si].MLM_message.low
		cmp	ax, ds:[di].MLM_message.low
		jne	equivalent
		mov	ax, ds:[si].MLM_message.high
		cmp	ax, ds:[di].MLM_message.high
		jne	equivalent
		mov	ax, ds:[si].MLM_address
		cmp	ax, ds:[di].MLM_address
done:
		.leave
		ret
equivalent:
		cmp	ax, ax		; indicate we can't use this to decide
					;  by returning so JE will take
		jmp	done
OCMLCompareAddressNumbers endp
endif	; _RESPONDER_OUTBOX_CONTROL

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLCompareRegistrationTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the registration stamp of the two messages to determine
		if one should be before the other

CALLED BY:	(INTERNAL) OCMLCompare
		ds:si	= MLMessage #1
		es:di	= MLMessage #2 (ds = es)
RETURN:		flags set so jl, je, or jg will take according as message #1
			should come before, equivalent to, or after message #2
DESTROYED:	ax, cx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLCompareRegistrationTime proc near
		.enter
		clr	ax	; assume equal
		mov	cx, ds:[si].MLM_registered.FDAT_date
		cmp	cx, ds:[di].MLM_registered.FDAT_date
		jne	setFlags		; => set flags from date
						;  difference
		mov	cx, ds:[si].MLM_registered.FDAT_time
		cmp	cx, ds:[di].MLM_registered.FDAT_time
setFlags:
		je	checkResult		; => leave ax alone
		dec	ax			; assume < (doesn't change CF)
		jb	checkResult
		neg	ax
checkResult:
		tst	ax
		.leave
		ret
OCMLCompareRegistrationTime endp
endif	; _RESPONDER_OUTBOX_CONTROL

Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLDeleteMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the currently-selected message.

CALLED BY:	MSG_OCML_DELETE_MESSAGE
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLDeleteMessage method dynamic OutboxControlMessageListClass, 
				MSG_OCML_DELETE_MESSAGE
		.enter
	;
	; Make sure the user wants to delete the message.
	;
		mov	bp, ds:[LMBH_handle]
		push	bp
		push	si
		mov	si, offset uiConfirmDeleteStr
		call	UtilDoConfirmation
		pop	si
		call	MemDerefStackDS
		cmp	ax, IC_YES
		jne	done

		call	OCMLCancelSend			; CF set if msg gone
		jc	done
			CheckHack <MAS_SENT eq 0>
		BitClr	ds:[bx].MITA_flags, MTF_STATE	; MTF_STATE = MAS_SENT
		call	notifyApp
if 	_DUPS_ALWAYS_TOGETHER
		push	di, cx
		mov	cx, ds:[bx].MITA_next
			CheckHack <MITA_NIL eq -1>
		inc	cx
		jz	dupsDone
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
dupLoop:
		dec	cx
		call	notifyApp
		push	ax
		mov_tr	ax, cx
		call	ChunkArrayElementToPtr
		pop	ax
			CheckHack <MAS_SENT eq 0>
		BitClr	ds:[di].MITA_flags, MTF_STATE	; MTF_STATE = MAS_SENT
		mov	cx, ds:[di].MITA_next
			CheckHack <MITA_NIL eq -1>
		inc	cx
		jnz	dupLoop
dupsDone:
		pop	di, cx
endif	; _DUPS_ALWAYS_TOGETHER
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		call	MainThreadUnlock
		call	OUDeleteMessageIfNothingUnsent

if	_RESPONDER_OUTBOX_CONTROL
	;
	; Disable Delete trigger so that the user can't delete the same message
	; twice.  It will be re-enabled (if appropriate) when rescan happens.
	;
		mov	bx, bp				; ^hbx = msg list blk
		mov	si, offset MOCDeleteTrigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	di, mask MF_CALL
		call	ObjMessage
endif	; _RESPONDER_OUTBOX_CONTROL

done:
		.leave
		ret
	;--------------------
	;Let everyone know this address has been deleted for the message.
	;
	;Pass:
	;	dxax	= MailboxMessage
	;	cx	= address #
	;Return:
	;	nothing
	;Destroyed:
	;	nothing
notifyApp:
		push	bp, ax, cx, di, dx
		Assert	bitClear, cx, <not mask MABC_ADDRESS>
		ornf	cx, mask MABC_OUTBOX or \
			(MACT_REMOVED shl offset MABC_TYPE)
		mov	bp, cx
		MovMsg	cxdx, dxax
		mov	ax, MSG_MA_BOX_CHANGED
		clr	di
		call	UtilForceQueueMailboxApp
		pop	bp, ax, cx, di, dx
		retn
OCMLDeleteMessage endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLStopMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop transmission of the selected message

CALLED BY:	MSG_OCML_STOP_MESSAGE
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLStopMessage	method dynamic OutboxControlMessageListClass, 
				MSG_OCML_STOP_MESSAGE
		.enter
		call	OCMLCancelSend	; CF set if message gone
		jc	done
		call	UtilVMUnlockDS
		call	MainThreadUnlock

done:
		.leave
		ret
OCMLStopMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLSendMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Submit the selected message for transmission

CALLED BY:	MSG_OCML_SEND_MESSAGE
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLSendMessage method dynamic OutboxControlMessageListClass, 
				MSG_OCML_SEND_MESSAGE
		.enter
		call	OCMLGetMessage
		segmov	es, ds
		MovMsg	dxax, cxdx
		call	MessageLock
		mov	di, ds:[di]
if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; If message is in Upon Request mode, we want to find all other messages
	; in Upon Request mode going to the same place and transmit them.
	;
		mov	cx, ds:[di].MMD_autoRetryTime.FDAT_date
		and	cx, ds:[di].MMD_autoRetryTime.FDAT_time
		cmp	cx, -1
		jne	checkMediumAvailable
		call	OCMLSendUponRequestMessages
		jmp	done

checkMediumAvailable:
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

		push	ax
		push	di
		mov	si, ds:[di].MMD_transAddrs
		mov	ax, bp
		call	ChunkArrayElementToPtr
	;
	; Make sure the message hasn't already changed state.
	;
		mov	al, ds:[di].MITA_flags
		andnf	al, mask MTF_STATE
		cmp	al, MAS_EXISTS shl offset MTF_STATE
		mov	ax, ds:[di].MITA_medium
	;
	; Clear phone blacklist, if necessary
	;

		pop	di
		je	checkAvailable

		pop	ax
		call	UtilVMUnlockDS
		jmp	done

checkAvailable:
	;
	; It hasn't. Make sure the medium for transmitting it exists.
	;
		call	OMCheckMediumAvailable
		jc	transMessage
	;
	; Medium doesn't exist. Shift message to Waiting state and let user
	; know why.
	;
if	_AUTO_RETRY_AFTER_TEMP_FAILURE
		movdw	ds:[di].MMD_autoRetryTime, MAILBOX_NOW
		call	UtilVMDirtyDS
		mov_tr	bx, ax
		pop	ax
		call	OCMLNotifyOfSwitchToWaitingState
		mov_tr	ax, bx
else
		pop	ax
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

		movdw	bxcx, ds:[di].MMD_transport
		mov	dx, ds:[di].MMD_transOption
		call	UtilVMUnlockDS		; release message before
						;  notifying the user, to
						;  avoid blocking transmission
						;  of other messages
		call	OCMLTellWhyCantTransmit
		jmp	done

transMessage:
		pop	ax
		call	UtilVMUnlockDS

		mov	cx, bp
		ornf	cx, mask TID_ADDR_INDEX
		call	OutboxTransmitMessage
done:
		.leave
		ret
OCMLSendMessage endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLTellWhyCantTransmit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the user know why the medium's not available

CALLED BY:	(INTERNAL) OCMLSendMessage
			   OCMLSendUponRequestMessages
PASS:		es	= OCML object block
		ax	= OutboxMedia token for medium
		bxcx	= MailboxTransport
		dx	= MailboxTransportOption
RETURN:		nothing
DESTROYED:	ds, if same as es
SIDE EFFECTS:	thread blocks until user acknowledges the dialog.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/14/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLTellWhyCantTransmit proc	near
		uses	ds, ax, si, bx
		.enter
	;
	; Use common code to find the reason.
	;
		call	ORGetMediumNotAvailReason	; ^lax:si <- reason
		mov_tr	bx, ax
	;
	; Put up the error box.
	;
	; ^lbx:si	= reason medium's not available.
	;
		push	es:[LMBH_handle]	; save for fixup
		clr	ax			; ax <- 0 for initializing
						;  most fields

		StructPushBegin	StandardDialogOptrParams

		StructPushField SDOP_helpContext, <ax, ax>

		StructPushField SDOP_customTriggers, <ax, ax>

		StructPushField SDOP_stringArg2, <ax, ax>

		StructPushField SDOP_stringArg1, <bx, si>

		mov	ax, handle ROStrings
		mov	si, offset uiCannotStartString
		StructPushField SDOP_customString, <ax, si>

		mov	ax, CustomDialogBoxFlags <0,
				CDT_ERROR,
				GIT_NOTIFICATION,
				0>
		StructPushField SDOP_customFlags, <ax>

		StructPushEnd

		call	UserStandardDialogOptr
		call	MemDerefStackES
	;
	; Free the reason string block, if we allocated one.
	;
		cmp	bx, handle ROStrings
		je	done
		call	MemFree
done:
		.leave
		ret
OCMLTellWhyCantTransmit endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLSendUponRequestMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find all existing Upon Request messages going to the same 
		place as this one and queue them all for transmission.

CALLED BY:	(INTERNAL) OCMLSendMessage
PASS:		ds:di	= MailboxMessageDesc of message to be sent
		dxax	= MailboxMessage of same
		bp	= address # to be sent to
		es	= OCML block
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds
SIDE EFFECTS:	message block is unlocked

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/14/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_AUTO_RETRY_AFTER_TEMP_FAILURE
OCMLSendUponRequestMessages proc near
addrNum		local	word	push bp
;;msg		local	MailboxMessage	push dx, ax
medium		local	word
transQ		local	word
addrBlock	local	hptr
transport	local	MailboxTransport
transOption	local	MailboxTransportOption
addrSize	local	word
talID		local	TalID
		.enter
	;
	; Initialize state variables.
	;
		clr	si
		mov	ss:[transQ], si
		mov	ss:[addrBlock], si
	;
	; Point to the selected address
	;
		mov	si, ds:[di].MMD_transAddrs
		push	di
		mov	ax, ss:[addrNum]
		call	ChunkArrayElementToPtr
		mov	ax, ds:[di].MITA_medium
		mov	ss:[medium], ax
		mov	si, di
		pop	di
		push	cx		; save address size
	;
	; Clear phone blacklist, if necessary
	;

	;
	; Find the number of bytes that are significant.
	;
		movdw	cxdx, ds:[di].MMD_transport
		mov	bx, ds:[di].MMD_transOption
		movdw	ss:[transport], cxdx
		mov	ss:[transOption], bx
		call	OMGetSigAddrBytes
		mov	ss:[addrSize], ax
	;
	; Allocate a block to hold the entire address.
	;
		pop	ax
		push	ax
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		pop	cx
		jc	allocErr
	;
	; Copy the address in.
	;
		push	es
		mov	es, ax
		mov	ss:[addrBlock], bx
		clr	di
		rep	movsb
	;
	; If the medium's available, allocate a queue on which to place
	; the messages that match, and a TalID with which to mark them.
	;
		mov	ax, ss:[medium]
		call	OMCheckMediumAvailable
		call	UtilVMUnlockDS
		jnc	doEnum

		call	OTCreateQueue
		mov	ss:[transQ], ax
		call	AdminAllocTALID
		mov	ss:[talID], ax
doEnum:
	;
	; Run through the outbox finding Upon Request messages that match.
	;
		call	AdminGetOutbox
		mov	cx, SEGMENT_CS
		mov	dx, offset messageCallback
		call	DBQEnum
		pop	es
	;
	; If we put them on a queue, transmit them.
	;
		mov	di, ss:[transQ]
		tst	di
		jz	notifyUser
		mov	cx, ss:[talID]
		call	OutboxTransmitMessageQueue
		jnc	freeStuff
		call	OutboxCleanupFailedTransmitQueue
freeStuff:
	;
	; Free up the address block.
	;
		mov	bx, ss:[addrBlock]
		call	MemFree
done:
		.leave
		ret
allocErr:
	;
	; Couldn't allocate a block to hold the address. Release the message
	; and bail out.
	; XXX: TELL THE USER.
	;
		call	UtilVMUnlockDS
		jmp	done

notifyUser:
	;
	; Tell the user why we couldn't actually transmit the things.
	;
		mov	ax, ss:[medium]
		movdw	bxcx, ss:[transport]
		mov	dx, ss:[transOption]
		call	OCMLTellWhyCantTransmit
		jmp	freeStuff

	;--------------------
	; See if the addresses of the message are the same as that the user
	; selected for transmission and, if creating a queue, mark them
	; as such as put the message in the queue.
	;
	; If not forming a queue (medium not available), just switch the
	; message to Waiting.
	;
	; Pass:
	; 	sidi	= MailboxMessage
	; 	bx	= admin file
	; 	ss:bp	= inherited frame:
	;		  transQ = DBQ to which to add the message if should
	;			   transmit
	;			 = 0 if should switch to Waiting
	;		  talID	 = id with which to mark matching addresses
	;			   if should transmit
	;		  addrSize = # of significant bytes
	;		  transport = transport of selected message
	;		  transOption = transport option of selected message
	;	es	= address to match
messageCallback:
		push	ds
		movdw	dxax, sidi
		call	MessageLock
		mov	di, ds:[di]
	;
	; See if the message is in the Upon Request state.
	;
			CheckHack <MAILBOX_ETERNITY eq -1>
		mov	cx, ds:[di].MMD_autoRetryTime.FDAT_date
		and	cx, ds:[di].MMD_autoRetryTime.FDAT_time
		cmp	cx, -1
		jne	messageCallbackDone	; => not Upon Request
	;
	; It is. See if it's going via the same transport.
	;
		cmpdw	ds:[di].MMD_transport, ss:[transport], cx
		jne	messageCallbackDone
		mov	cx, ds:[di].MMD_transOption
		cmp	ss:[transOption], cx
		jne	messageCallbackDone
	;
	; It is. Go find any addresses that are the same as the selected one.
	;
		clr	cx			; cx <- none matched
		mov	bx, SEGMENT_CS
		mov	di, offset addrCallback
		call	MessageAddrEnum
		jcxz	messageCallbackDone
	;
	; At least one address matched. Queue the message if we're doing that
	; sort of thing.
	;
		mov	di, ss:[transQ]
		tst	di
		jz	notifyOfSwitch
		call	MailboxGetAdminFile
		call	DBQAdd

notifyOfSwitch:
		call	OCMLNotifyOfSwitchToWaitingState

messageCallbackDone:
		call	UtilVMUnlockDS
		pop	ds
		clc
		retf

	;--------------------
	; Examine a single address to see if it matches and put it in the
	; queue or into Waiting if it does.
	;
	; Pass:	ds:di	= MITA to check
	; 	*ds:bx	= MMD
	; 	ss:bp	= frame
	; 	es:0	= MITA to compare with
	; Return:
	; 	carry set to stop enumerating (always clear)
	; 	cx	= non-z if address marked
	; Destroyed:
	; 	bx, si, di allowed
addrCallback:
		mov	ax, ds:[di].MITA_medium
		cmp	ss:[medium], ax
		jne	addrCallbackDone

		mov	si, di
		clr	di
		push	bp
		mov	bp, ss:[addrSize]
		call	OUCompareAddresses
		pop	bp
		jne	addrCallbackDone
EC <		mov	di, si		; for warning print-out Tcl code>
EC <		tst	ds:[si].MITA_addrList				>
EC <		WARNING_NZ OVERWRITING_EXISTING_ADDRESS_MARK		>
		mov	ax, ss:[talID]
		mov	ds:[si].MITA_addrList, ax
		mov	si, ds:[bx]
				CheckHack <MAILBOX_NOW eq 0>
		clr	cx
		movdw	ds:[si].MMD_autoRetryTime, cxcx

if	_OUTBOX_SEND_WITHOUT_QUERY
	;
	; Can now set this silly thing.
	;
		ornf	ds:[si].MMD_flags, mask MMF_SEND_WITHOUT_QUERY
endif	; _OUTBOX_SEND_WITHOUT_QUERY

		dec	cx		; cx <- non-z to indicate marked
		call	UtilVMDirtyDS
addrCallbackDone:
		clc
		retf
OCMLSendUponRequestMessages endp
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLNotifyOfSwitchToWaitingState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let everyone know that the passed message has switched from
		Upon Request or Retry state to Waiting

CALLED BY:	(INTERNAL) OCMLSendUponRequestMessages
			   OCMLSendMessage
PASS:		dxax	= message affected
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	notification queued to mailbox app

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/15/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_AUTO_RETRY_AFTER_TEMP_FAILURE
OCMLNotifyOfSwitchToWaitingState proc	near
		uses	ax, cx, dx, bp, di
		.enter
		MovMsg	cxdx, dxax
		mov	bp, mask MABC_OUTBOX or \
				(MACT_EXISTS shl offset MABC_TYPE) or \
				(MABC_ALL shl offset MABC_ADDRESS)
		mov	ax, MSG_MA_BOX_CHANGED
		clr	di
		call	UtilForceQueueMailboxApp
		
	;
	; Reevaluate when the next timer should go off, since retry time no
	; longer enters into the picture for this message.
	;
		mov	ax, MSG_MA_RECALC_NEXT_EVENT_TIMER
		clr	di
		call	UtilForceQueueMailboxApp
		.leave
		ret
OCMLNotifyOfSwitchToWaitingState endp
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLGetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the MailboxMessage and address # of the selected message

CALLED BY:	(INTERNAL) OCMLStartMessage, OCMLCancelSend
PASS:		*ds:si	= OutboxControlMessageList
RETURN:		cxdx	= MailboxMessage
		bp	= address #
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLGetMessage	proc	near
		class	OutboxControlMessageListClass
		.enter
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock	; ax <- message #
		mov_tr	cx, ax
		mov	ax, MSG_ML_GET_MESSAGE
		call	ObjCallInstanceNoLock
		.leave
		ret
OCMLGetMessage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLCancelSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel transmission of the currently selected message, if
		it's queued or undergoing transmission.

CALLED BY:	(INTERNAL) OCLMDeleteMessage, OCMLStopMessage
PASS:		*ds:si	= OutboxControlMessageList
RETURN:		carry clear if message exists
			*ds:di	= MailboxMessageDesc
			ds:bx	= MailboxInternalTransAddr
			dxax	= MailboxMessage
			cx	= address #
			MainThreads block locked; caller must call
			MainThreadUnlock
		carry set otherwise
			ax, cx, dx, ds, di destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		fetch the selected message & address
		extract the transport, trans opt, and medium token from it
		find the transmit thread, if any, so we can be sure the
			message can't be queued up while we or our caller
			mess with it
		lock the message address again
		if queued, change address marks by index to 0
		if sending, MainThreadCancel(); this will adjust the address
			marks for the message once the cancel takes effect
			
		XXX: MAY NEED TO EXTEND DEADLINE HERE		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLCancelSend	proc	near
		class	OutboxControlMessageListClass
		uses	bp
		.enter
	;
	; Fetch the MailboxMessage and address number.
	;
		call	OCMLGetMessage
		
		push	cx, dx, bp		; save msg info for later
	;
	; Obtain the transport, transOpt and medium token so we can find any
	; transmission thread.
	;
		call	MessageLockCXDX		; *ds:di <- MMD
		jnc	msgFound
	;
	; Message is gone.  Return carry set.
	;
		pop	ax, ax, ax	; discard msg & addr #, carry preserved
		jmp	exit

msgFound:
		mov	si, ds:[di]
		mov_tr	ax, bp			; ax <- addr #
		movdw	bpdx, ds:[si].MMD_transport
		mov	bx, ds:[si].MMD_transOption
		mov	si, ds:[si].MMD_transAddrs
		call	ChunkArrayElementToPtr	; (cx <- addr size)
		mov	ax, ds:[di].MITA_medium
		call	UtilVMUnlockDS
		mov	cx, bp			; cxdx <- transport
	;
	; Locate the thread. We don't need to worry about the CF return because
	; we can base our actions on the QUEUED and SENDING flags...
	;
		call	OTFindThread
		
		pop	dx, ax, cx		; dxax <- msg, cx <- addr #
EC <		pushf							>
		push	ds, di			; for MainThreadCancel
	;
	; Point to the address again.
	;
		call	MessageLock
		push	di, ax
		
		mov_tr	ax, cx
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		call	ChunkArrayElementToPtr
		mov_tr	cx, ax			; cx <- addr #
		mov	bx, di			; ds:bx <- MITA
	;
	; See if the message is queued and needs to be removed from the queue.
	;
		mov	al, ds:[bx].MITA_flags
		andnf	al, mask MTF_STATE
		cmp	al, MAS_QUEUED shl offset MTF_STATE
		je	checkQueuedRes
		cmp	al, MAS_READY shl offset MTF_STATE
checkQueuedRes:
		pop	di, ax			; dxax <- msg, *ds:di <- MMD
		jne	checkSending
	;
	; It does. We accomplish this by setting the address marks for the
	; thing to 0, which will cause it to be ignored when the transmit thread
	; goes to look for the next thing to process.
	;
	; XXX: There might be a race condition during the callback for
	; preparing or sending a message in the transmit thread, between when
	; an address is found and when it gets processed, as I don't believe
	; that uses the MainThreads block for synchronization.
	;
if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; Switch the message into Upon Request mode first, as we assume if
	; the user stopped its transmission, she doesn't want it to go until
	; she says it should. Seems like a reasonable assumption. In the
	; case of _OUTBOX_SEND_WITHOUT_QUERY being set, this also prevents
	; us from having to cope with having to do something intelligent
	; if there's a TRANS_WIN_OPEN message sent to the application,
	; as will happen during the next outbox event handling if we leave the
	; retry time as the MAILBOX_NOW it is now. -- ardeb 11/16/95
	;
		mov	si, ds:[di]
		movdw	ds:[si].MMD_autoRetryTime, MAILBOX_ETERNITY
		call	UtilVMDirtyDS
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

		push	bx, cx
		mov	bx, cx			; bx <- MABoxChange
		ornf	bx, (MACT_EXISTS shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		ornf	cx, mask TID_ADDR_INDEX	; cx <- TalID to mark
		clr	si			; si <- new address mark
		call	OTQChangeAddressMarks
		pop	bx, cx

		jmp	done

checkSending:
	;
	; Not queued. Perhaps it's being sent?
	;
		push	ax
		mov	al, ds:[bx].MITA_flags
		andnf	al, mask MTF_STATE
		cmp	al, MAS_SENDING shl offset MTF_STATE
		je	checkSendingRes
		cmp	al, MAS_PREPARING shl offset MTF_STATE
checkSendingRes:
		pop	ax
		jne	done
	;
	; It is -- cancel the thing.
	;
		push	ds, di
		mov	bp, sp
		lds	di, ss:[bp+4]		; ds:di <- OutboxThreadData
EC <		push	ss:[bp+8]					>
EC <		popf							>
EC <		ERROR_NC TRANSMISSION_THREAD_MISSING			>
		push	ax, cx, dx, bp
		mov	ax, MCA_CANCEL_MESSAGE	; ax <- cancel extent
		clr	dx, bp, cx		; dx:bp, cx <- no ACK needed
		call	MainThreadCancel
		pop	ax, cx, dx, bp
		pop	ds, di			; *ds:di <- MMD
done:
EC <		add	sp, 6		; discard thread data & flags	>
NEC <		add	sp, 4		; discard OutboxThreadData pointer>
	;
	; Return carry clear (cleared by "add" above).
	;

exit:
		.leave
		ret
OCMLCancelSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLGenItemGroupSetNoneSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let MailboxOutboxControl know nothing can be done.

CALLED BY:	MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
		dx	= non-z if indeterminate
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLGenItemGroupSetNoneSelected method dynamic OutboxControlMessageListClass, 
				MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		clr	bx
		call	OCMLNotifyController
		
		mov	ax, MSG_OCML_ENSURE_SELECTION
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		GOTO	ObjMessage
OCMLGenItemGroupSetNoneSelected endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLEnsureSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If nothing currently selected, select the first item in the
		list.

CALLED BY:	MSG_OCML_ENSURE_SELECTION
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLEnsureSelection method dynamic OutboxControlMessageListClass,
					MSG_OCML_ENSURE_SELECTION
		.enter
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jnc	done			; => have selection
		
		mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
		call	ObjCallInstanceNoLock
		jcxz	done			; => nothing to select

		clr	cx, dx			; cx <- sel #, dx <- not indet.
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
OCMLEnsureSelection endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLGenItemGroupSetSingleSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Examine the selection to decide what features the controller
		should have enabled

CALLED BY:	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
		cx	= identifier (list entry #)
		dx	= non-z if indeterminate
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		lock address & message
		if sending/queued enable cancel, disable send
		RESP: if sending & SMS, disable delete & cancel
		release message

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLGenItemGroupSetSingleSelection method dynamic OutboxControlMessageListClass,
				   	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		uses	ax, cx, dx, bp, si
		.enter
		mov	bx, mask MOCFeatures	; assume all enabled
		mov	ax, MSG_ML_GET_MESSAGE
		call	ObjCallInstanceNoLock
		push	ds
		call	MessageLockCXDX
		mov	di, ds:[di]
		mov	si, ds:[di].MMD_transAddrs
		push	di
		mov_tr	ax, bp
		call	ChunkArrayElementToPtr
		mov	al, ds:[di].MITA_flags
		pop	di
		mov	ah, not mask MOCF_STOP_SENDING	; assume not sending, so
							;  can't stop
		andnf	al, mask MTF_STATE
			CheckHack <MAS_SENDING gt MAS_PREPARING>
			CheckHack <MAS_READY gt MAS_PREPARING>
			CheckHack <MailboxAddressState eq MAS_SENDING+1>
		cmp	al, MAS_PREPARING shl offset MTF_STATE
		jae	cantStartSending
		cmp	al, MAS_QUEUED shl offset MTF_STATE
		jne	tweakFlags

cantStartSending:

		mov	ah, not mask MOCF_START_SENDING	; is sending, so can't
							;  start
if	_RESPONDER_OUTBOX_CONTROL
	;
	; Can't do anything to a message being transmitted via SMS if it's
	; actively being transmitted
	; 
		CmpTok	ds:[di].MMD_transport, \
				MANUFACTURER_ID_GEOWORKS, \
				GMTID_SM, \
				tweakFlags
		mov	ah, not (mask MOCF_START_SENDING or \
				 mask MOCF_STOP_SENDING or \
				 mask MOCF_DELETE_MESSAGE)
endif	; _RESPONDER_OUTBOX_CONTROL
tweakFlags:
		and	bl, ah
		call	UtilVMUnlockDS
		pop	ds
		.leave
		FALL_THRU OCMLNotifyController
OCMLGenItemGroupSetSingleSelection endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLNotifyController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the MailboxOutboxControl what to do with its features
		before we call our superclass

CALLED BY:	(INTERNAL) OCMLGenItemGroupSetSingleSelection,
			   OCMLGenItemGroupSetNoneSelected
PASS:		*ds:si	= OutboxControlMessageList
		ax, cx, dx, bp = message info to pass to superclass
		bx	= MOCFeatures to be enabled.
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLNotifyController proc far
		uses	ax, cx, dx, bp, si
		.enter
		mov	cx, bx
		clr	dx
		mov	ax, MSG_MAILBOX_OUTBOX_CONTROL_ENABLE_FEATURES
		call	ObjBlockGetOutput
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		mov	di, offset OutboxControlMessageListClass
		GOTO	ObjCallSuperNoLock
OCMLNotifyController endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLMlRescan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set default selection after rebuilding the list.

CALLED BY:	MSG_ML_RESCAN
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
RETURN:		carry set if list is empty
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLMlRescan	method dynamic OutboxControlMessageListClass, MSG_ML_RESCAN
		.enter
		mov	di, offset OutboxControlMessageListClass
		call	ObjCallSuperNoLock
	;
	; If empty, tell us that nothing's selected...
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		jc	setSelection
	;
	; Else select first one.
	; 
		clr	cx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
setSelection:
		pushf
		clr	dx			; dx <- not indeterminate
		call	ObjCallInstanceNoLock
		popf
		.leave
		ret
OCMLMlRescan	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLMlCheckBeforeRemoval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the message should be removed from the list.

CALLED BY:	MSG_ML_CHECK_BEFORE_REMOVAL
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
		cxdx	= MailboxMessage
		bp	= MABoxChange holding address #affected
RETURN:		carry set to keep message:
			bp	= address number to display for entry
		carry clear to remove message:
			bp	= destroyed
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Under Responder, messages remain in the list even when 
		they've been queued or are being sent. Only allow removal
		if MACT_REMOVED is the change type.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCMLMlCheckBeforeRemoval method dynamic OutboxControlMessageListClass, 
				MSG_ML_CHECK_BEFORE_REMOVAL
		.enter
			CheckHack <MACT_REMOVED eq 0>
		test	bp, mask MABC_TYPE
		jz	done
		andnf	bp, mask MABC_ADDRESS
		stc
done:
		.leave
		ret
OCMLMlCheckBeforeRemoval endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLMlGenerateMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the moniker for the passed message.

CALLED BY:	MSG_ML_GENERATE_MONIKER
PASS:		cxdx	= MailboxMessage for which to create moniker
		bp	= address # for which to create moniker
RETURN:		ax	= lptr of gstring moniker in object block
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLMlGenerateMoniker	method dynamic OutboxControlMessageListClass, 
					MSG_ML_GENERATE_MONIKER

	MovMsg	dxax, cxdx
	mov	cx, bp					; cx < addr #
	Assert  bitClear, cx, <not mask TID_NUMBER>
	ornf	cx, mask TID_ADDR_INDEX			; cx <- TalID
	call	MessageCreateOutboxControlMoniker	; *ds:ax = moniker

	ret
OCMLMlGenerateMoniker	endm
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLMlGetInitialMinimumSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the initial minimum size for the list

CALLED BY:	MSG_ML_GET_INITIAL_MINIMUM_SIZE
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
RETURN:		cx	= default width
		dx	= default height
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLMlGetInitialMinimumSize method dynamic OutboxControlMessageListClass, 
					MSG_ML_GET_INITIAL_MINIMUM_SIZE
		.enter
		call	MessageEnsureSizes
		mov	dx, bx			; dx <- height
		segmov	ds, dgroup, ax
		mov	cx, ds:[mmAddrStateRightBorder]
		add	cx, OUTBOX_RIGHT_GUTTER
		.leave
		ret
OCMLMlGetInitialMinimumSize endm
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCHVVisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we are of the size of one message item.

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= OutboxControlHeaderViewClass object
		es 	= segment of OutboxControlHeaderViewClass
		ax	= message #
		cx	= RecalcSizeArgs -- suggested width for object
		dx	= RecalcSizeArgs -- suggested height
RETURN:		cx	= width of one message item
		dx	= height of one message item
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/31/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCHVVisRecalcSize	method dynamic OutboxControlHeaderViewClass, 
					MSG_VIS_RECALC_SIZE

	mov	di, offset OutboxControlHeaderViewClass
	GOTO_ECN OCHSetHeaderSize

OCHVVisRecalcSize	endm
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCHGVisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we are of the size of one message item.

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= OutboxControlHeaderGlyphClass object
		es	= segment of OutboxControlHeaderGlyphClass
		ax	= message #
		cx	= RecalcSizeArgs -- suggested width for object
		dx	= RecalcSizeArgs -- suggested height
RETURN:		cx	= width of one message item
		dx	= height of one message item
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/31/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCHGVisRecalcSize	method dynamic OutboxControlHeaderGlyphClass, 
					MSG_VIS_RECALC_SIZE

	mov	di, offset OutboxControlHeaderGlyphClass
	FALL_THRU_ECN OCHSetHeaderSize

OCHGVisRecalcSize	endm
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCHSetHeaderSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed Vis object is of the size of one message
		item by	returning the width and the height to
		MSG_VIS_RECALC_SIZE

CALLED BY:	OCHVVisRecalcSize, OCHGVisRecalcSize
PASS:		*ds:si	= any Vis object
		es:di	= actual class of passed object
		ax	= MSG_VIS_RECALC_SIZE
		cx	= RecalcSizeArgs -- suggested width for object
		dx	= RecalcSizeArgs -- suggested height
RETURN:		cx	= width of one message item
		dx	= height of one message item
		ds fixed up
DESTROYED:	ax, bx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCHSetHeaderSize	proc	ecnear

	;
	; Call superclass even though we are returning our own values, or
	; else we die with
	; UI_CANT_DO_CUSTOM_RECALC_SIZE_AND_DO_SPECIAL_JUSTIFICATION
	;
	call	ObjCallSuperNoLock

	call	MessageEnsureSizes	; ax = width, bx = height
	mov_tr	cx, ax			; cx = width
	mov	dx, bx			; dx = height

	ret
OCHSetHeaderSize	endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLBypassSpui
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bypass annoying behaviour in OLCtrl to get it from
		VisComp, which obeys our requests for margins.

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
		random args
RETURN:		random results
DESTROYED:	random things
SIDE EFFECTS:	ditto

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLBypassSpui method dynamic OutboxControlMessageListClass, 
				MSG_VIS_RECALC_SIZE
		segmov	es, <segment VisCompClass>, di
		mov	di, offset VisCompClass
		call	ObjCallClassNoLock
	;
	; Make sure we have a non-zero height when the superclass thinks we
	; should have zero height, or else we eventually end up with zero
	; height somehow.
	;
		tst	dx
		jnz	done
		inc	dx
done:
		ret
OCMLBypassSpui endm
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCHGVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw the title of the list

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= OutboxControlHeaderGlyph object
		ds:di	= OutboxControlHeaderGlyphInstance
		cl	= DrawFlags
		bp	= gstate for drawing
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/10/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCHGVisDraw	method dynamic OutboxControlHeaderGlyphClass, MSG_VIS_DRAW
		.enter
	;
	; Let superclass handle the bulk of the work.
	;
		push	bp
		mov	di, offset OutboxControlHeaderGlyphClass
		call	ObjCallSuperNoLock
		pop	di

		;
		; Set font for outbox
		;
		call	GrSaveState
		mov	cx, OUTBOX_TITLE_FONT
		mov	dx, OUTBOX_TITLE_FONT_SIZE
		clr	ah
		call	GrSetFont
		
		mov	ax, C_BLACK
		call	GrSetLineColor
		call	GrSetTextColor

		mov	ax, mask TS_BOLD or \
				((not mask TS_BOLD and mask TextStyle) shl 8)
		call	GrSetTextStyle

		segmov	es, dgroup, ax
		mov	bx, offset uiRespSubjTitle
		mov	ax, es:[mmSubjectRightBorder]
		call	OCHGDrawTitle
		
		mov	bx, offset uiRespDestTitle
		mov	ax, es:[mmDestinationRightBorder]
		call	OCHGDrawTitle
		
		mov	bx, offset uiRespTransTitle
		mov	ax, es:[mmTransMediumAbbrevRightBorder]
		call	OCHGDrawTitle
		
		mov	bx, offset uiRespStateTitle
		mov	ax, es:[mmAddrStateRightBorder]
		call	OCHGDrawTitle

		call	GrRestoreState

		.leave
		ret
OCHGVisDraw	endm
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCHGDrawTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw part of the title of the list, with the funky line
		going the entire height of the header

CALLED BY:	(INTERNAL) OCHGVisDraw
PASS:		*ds:si	= OutboxControlHeaderGlyph object
		ax	= right edge of field
		bx	= chunk handle of title string in ROStrings
		di	= gstate to use for drawing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/10/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCHGDrawTitle	proc	near
		uses	si
		.enter
	;
	; Find the bounds of the object, for translating coordinates and
	; figuring how tall a line to draw at the right edge of the field.
	;
		push	ax, bx
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		pop	cx, si
	;
	; Find the width of the string we want to draw for the title.
	;
		add	ax, cx		; ax <- actual right edge coord, in
					;  parent window
					; bp = actual top edge coord
					; dx = bottom edge

		push	ds
		push	ax
		mov	bx, handle ROStrings
		call	MemLock
		mov	ds, ax
		pop	ax		; ax <- right edge
		mov	si, ds:[si]
		clr	cx		; cx <- null-terminated
		
		push	dx
		call	GrTextWidth	; dx <- width
		pop	bx		; bx <- bottom edge
	;
	; Draw the text that far from the left edge of the edge marker,
	; with reasonable separation between the text and the marker.
	;
		push	ax
		sub	ax, OUTBOX_TITLE_SEPARATION + OUTBOX_TITLE_CORNER_LEN
		sub	ax, dx
		xchg	bx, bp		; bx <- top edge, bp <- bottom
		call	GrDrawText
	;
	; Draw the horizontal part of the field edge marker. We use swapped
	; X coords drawing this part so we can reuse what's in AX for drawing
	; the vertical part.
	;
		push	dx, si
		mov	si, GFMI_STRIKE_POS or GFMI_ROUNDED
		call	GrFontMetrics
		add	bx, dx		; start corner at strike-through
					;  pos for font.
		pop	dx, si
		pop	ax		; ax <- right edge of field
;		inc	ax
;		inc	ax		; cope with two-pixel inset of list
					;  item monikers (sigh)
		mov	cx, ax
		sub	cx, OUTBOX_TITLE_CORNER_LEN
		call	GrDrawHLine
	;
	; Now draw the vertical part from the top of the object to the bottom
	;
		mov	dx, bp		; dx <- bottom edge
		call	GrDrawVLine
		call	UtilUnlockDS
		pop	ds
		.leave
		ret
OCHGDrawTitle	endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hack to tweak some Vis data to reflect how we draw, once
		our superclass has finished setting it wrong.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLSpecBuild	method dynamic OutboxControlMessageListClass, MSG_SPEC_BUILD
		.enter
		mov	di, offset OutboxControlMessageListClass
		call	ObjCallSuperNoLock
		
		DerefDI	VisComp
		andnf	ds:[di].VCI_geoAttrs, 
			not mask VCGA_ONLY_DRAWS_IN_MARGINS
		.leave
		ret
OCMLSpecBuild	endm
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLSpecScanGeometryHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hack to tweak some Vis data to reflect how we draw, once
		our superclass has finished setting it wrong.

CALLED BY:	MSG_SPEC_SCAN_GEOMETRY_HINTS
PASS:		*ds:si	= OutboxControlMessageList object
		ds:di	= OutboxControlMessageListInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/12/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLSpecScanGeometryHints method dynamic OutboxControlMessageListClass, 
			MSG_SPEC_SCAN_GEOMETRY_HINTS
		.enter
		mov	di, offset OutboxControlMessageListClass
		call	ObjCallSuperNoLock
		
		DerefDI	VisComp
		ornf	ds:[di].VCI_geoDimensionAttrs, 
				mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
				mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
		.leave
		ret
OCMLSpecScanGeometryHints endm
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCMLVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the edge markers (the funky vertical lines) thru our
		message items.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= OutboxControlMessageListClass object
		ds:di	= OutboxControlMessageListClass instance data
		ds:bx	= OutboxControlMessageListClass object (same as *ds:si)
		es 	= segment of OutboxControlMessageListClass
		ax	= message #
		cl	= DrawFlags
		bp	= GState handle
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
OCMLVisDraw	method dynamic OutboxControlMessageListClass, 
					MSG_VIS_DRAW

	;
	; Let superclass handle the bulk of the work.
	;
	push	bp
	mov	di, offset OutboxControlMessageListClass
	call	ObjCallSuperNoLock
	pop	di

	;
	; Get the top and bottom bounds of the object.
	;
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock	; (ax, bp), (cx, dx)
	mov	bx, bp			; bx = top

	mov	ax, C_BLACK
	call	GrSetLineColor

	;
	; Draw the vertical lines.
	;
	segmov	ds, dgroup, ax
	mov	ax, ds:[mmSubjectRightBorder]
	call	GrDrawVLine
	mov	ax, ds:[mmDestinationRightBorder]
	call	GrDrawVLine
	mov	ax, ds:[mmTransMediumAbbrevRightBorder]
	call	GrDrawVLine
	mov	ax, ds:[mmAddrStateRightBorder]
	GOTO	GrDrawVLine

OCMLVisDraw	endm
endif	; _RESPONDER_OUTBOX_CONTROL

OutboxUICode	ends
