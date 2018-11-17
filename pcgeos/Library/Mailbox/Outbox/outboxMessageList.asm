COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox
FILE:		outboxMessageList.asm

AUTHOR:		Adam de Boor, May 19, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/19/94		Initial revision


DESCRIPTION:
	
		

	$Id: outboxMessageList.asm,v 1.1 97/04/05 01:21:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS		; REST OF FILE IS A NOP UNLESS THIS IS TRUE

MailboxClassStructures	segment	resource

	OutboxMessageListClass

MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLMlRescan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin the process of rescanning the outbox for suitable 
		messages. This includes possibly queueing some messages for
		transmission if they are SEND_WITHOUT_QUERY and the medium
		for sending them exists.

CALLED BY:	MSG_ML_RESCAN
PASS:		*ds:si	= OutboxMessageList object
		ds:di	= OutboxMessageListInstance
RETURN:		carry set if list is empty
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	messages may be queued for transmission

PSEUDO CODE/STRATEGY:
		figure if the required medium is available (required medium
			gotten from primary criteria if by_medium, else from
			secondary criteria)
		if so, allocate a DBQ for OMLI_transmitQueue and a talID for
			OMLI_transmitID
		else zero OMLI_transmitQueue
		call superclass
		if anything in OMLI_transmitQueue, call 
			OutboxTransmitMessageQueue on the thing
		else if OMLI_transmitQueue exists, destroy it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLMlRescan	method dynamic OutboxMessageListClass, MSG_ML_RESCAN
		.enter
	;
	; Figure out which of the two possible criteria holds the medium for
	; which we're displaying stuff...
	; 
		mov	bx, ds:[di].MLI_primaryCriteria
		tst	bx
		jz	setTransQ		; => display everything and
						;  transmit nothing
		
		Assert	chunk, bx, ds
		mov	bx, ds:[bx]
		cmp	ds:[bx].MCPC_type, MDPT_BY_MEDIUM
		je	haveMedium
		mov	bx, ds:[di].MLI_secondaryCriteria
		Assert	chunk, bx, ds
		mov	bx, ds:[bx]
EC <		cmp	ds:[bx].MCPC_type, MDPT_BY_MEDIUM		>
EC <		ERROR_NE SECONDARY_CRITERIA_NOT_BY_MEDIUM		>
haveMedium:
	;
	; See if that medium exists.
	; 
		push	es, di
		segmov	es, ds
		lea	di, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_medium
		call	MediaCheckMediumAvailableByPtr
		pop	es, di
		mov	bx, 0		; assume not available
		jnc	setTransQ
	;
	; It does. Allocate a talID for marking eligible addresses.
	; 
		call	AdminAllocTALID
		mov	ds:[di].OMLI_transmitID, ax
	;
	; Allocate a queue on which to put messages that are to be transmitted
	; immediately.
	; 
		mov	dx, DBQ_NO_ADD_ROUTINE
		call	MessageCreateQueue
		jc	setTransQ
		
		call	MailboxGetAdminFile		; ^vbx:ax
setTransQ:
		movdw	ds:[di].OMLI_transmitQueue, bxax
	;
	; Record the current time so we don't have to fetch it over and 
	; over and over and over again.
	; 
		call	TimerGetFileDateTime
		mov	ds:[di].OMLI_currentTime.FDAT_date, ax
		mov	ds:[di].OMLI_currentTime.FDAT_time, dx
	;
	; If MDPT_BY_TRANSPORT, find the number of significant bytes in
	; addresses for the pair.
	; 
		mov	bx, ds:[di].MLI_primaryCriteria
		tst	bx
		jz	doScan			; => displaying everything, so
						;  no need for this shme

		mov	bx, ds:[bx]
		cmp	ds:[bx].MCPC_type, MDPT_BY_TRANSPORT
		jne	doScan
		
		push	si
		movdw	axcx, ds:[bx].MCPC_data.MDPC_byTransport.MDBTD_transport
		mov	si, ds:[bx].MCPC_data.MDPC_byTransport.MDBTD_transOption
		mov	bx, ds:[di].MLI_secondaryCriteria
		mov	bx, ds:[bx]
		mov	dx, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_medium.MMD_medium.low
		mov	bx, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_medium.MMD_medium.high
		xchg	bx, cx
		call	MediaGetTransportSigAddrBytes
EC <		ERROR_C	HOW_CAN_MEDIA_TRANSPORT_BE_INVALID?		>
		pop	si
		mov	ds:[di].OMLI_sigAddrBytes, ax
doScan:
	;
	; Now we've got the queue created, call our superclass to perform the
	; actual scan.
	; 
		mov	di, offset OutboxMessageListClass
		mov	ax, MSG_ML_RESCAN
		call	ObjCallSuperNoLock
		pushf				; save list-is-empty flag
	;
	; See if we've got anything in the transmit queue.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].OutboxMessageList_offset
		mov	cx, ds:[di].OMLI_transmitID
		mov	bx, ds:[di].OMLI_transmitQueue.high
		mov	di, ds:[di].OMLI_transmitQueue.low

		tst	bx			; => no queue, so nothing else
		jz	done			;  to do

		call	DBQGetCount		; dxax <- # entries in the queue
		or	ax, dx
		jz	destroyQueue		; => nothing to transmit, but
						;  we need to nuke the queue
	;
	; We've got something to transmit -- call the proper function.
	; 
		call	OutboxTransmitMessageQueue
		jc	destroyQueue		; => something left in the
						;  queue. XXX: We should likely
						;  notify the user here...
						;  
done:
		popf			; CF <- list-is-empty flag
		.leave
		ret

destroyQueue:
		call	OutboxCleanupFailedTransmitQueue
		jmp	done
OMLMlRescan	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLMlGetScanRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the routines to use during the scan for messages to
		display.

CALLED BY:	MSG_ML_GET_SCAN_ROUTINES
PASS:		*ds:si	= OutboxMessageList object
		cx:dx	= fptr.MLScanRoutines to fill in
RETURN:		MLScanRoutines filled in
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLMlGetScanRoutines method dynamic OutboxMessageListClass, 
				MSG_ML_GET_SCAN_ROUTINES
		.enter
		movdw	dssi, cxdx
		mov	ds:[si].MLSR_select.segment, vseg OMLSelect
		mov	ds:[si].MLSR_select.offset, offset OMLSelect

		mov	ds:[si].MLSR_compare.segment, vseg OMLCompare
		mov	ds:[si].MLSR_compare.offset, offset OMLCompare
		.leave
		ret
OMLMlGetScanRoutines endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this message should be displayed (or possibly
		transmitted)

CALLED BY:	(INTERNAL) OMLMlRescan via MessageList::ML_RESCAN
PASS:		dxax	= MailboxMessage to check
		bx	= admin file
		*ds:si	= OutboxMessageList object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	message+address(es) may be added to the list
     		message w/marked addresses may be added to the transmit queue

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLSelect	proc	far
msg		local	MailboxMessage	push dx, ax
listObj		local	dword		push ds, si
xmitID		local	word
needXmit	local	byte
canXmit		local	byte
	ForceRef	msg	; used by callbacks
		class	OutboxMessageListClass
		.enter
	;
	; Fetch the TalID to use for marking addresses for messages that are
	; to be transmitted.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].OutboxMessageList_offset
		mov	cx, ds:[di].OMLI_transmitID
		mov	ss:[xmitID], cx
	;
	; Initialize needXmit to 0, please.
	; 
		clr	cx
		mov	ss:[needXmit], cl
	;
	; See if there's a transmit queue and set canXmit true if there is.
	; 
		tst	ds:[di].OMLI_transmitQueue.high
		jz	setCanXmit
		dec	cx			; (1-byte inst)
setCanXmit:
		mov	ss:[canXmit], cl
	;
	; Iterate over the addresses, looking for ones that match the
	; criteria.
	; 
		mov	bx, ds:[di].MLI_primaryCriteria
		mov	di, offset OMLSelectUnsentCallback
		tst	bx
		jz	enumAddrs		; => no criteria, so accept
						;  all that haven't been sent
						;  and aren't dups

		mov	bx, ds:[bx]
		mov	di, offset OMLSelectByMediumCallback
		cmp	ds:[bx].MCPC_type, MDPT_BY_MEDIUM
		je	checkTransport
		mov	di, offset OMLSelectByTransportCallback
checkTransport:
	;
	; Make sure the message actually uses the transport in the criteria
	; before bothering with its addresses.
	; 
		push	ds, di
		CheckHack <MDPC_byTransport.MDBTD_transport eq \
			   MDPC_byMedium.MDBMD_transport>
		mov	si, 
			ds:[bx].MCPC_data.MDPC_byTransport.MDBTD_transOption
		mov	cx, 
			ds:[bx].MCPC_data.MDPC_byTransport.MDBTD_transport.high
		mov	bx,
			ds:[bx].MCPC_data.MDPC_byTransport.MDBTD_transport.low
		call	MessageLock
		mov	di, ds:[di]
		cmpdw	ds:[di].MMD_transport, cxbx
		jne	unlockIt
		cmp	ds:[di].MMD_transOption, si
unlockIt:
		call	UtilVMUnlockDS
		pop	ds, di
		jne	done		; => don't bother

enumAddrs:
		mov	bx, SEGMENT_CS
		clr	cx		; first address is #0
		call	MessageAddrEnum
	;
	; If the callback flagged the message as needing to be transmitted, add
	; it to the queue.
	; 
		lds	si, ss:[listObj]
		tst	ss:[needXmit]
		jz	done
		mov	di, ds:[si]
		add	di, ds:[di].OutboxMessageList_offset
		mov	bx, ds:[di].OMLI_transmitQueue.high
		mov	di, ds:[di].OMLI_transmitQueue.low
		call	DBQAdd
done:
		.leave
		ret
OMLSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLSelectUnsentCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this address should be listed or transmitted.

CALLED BY:	(INTERNAL) OMLSelect via MessageAddrEnum
PASS:		ds:di	= MailboxInternalTransAddr
		*ds:si	= address array
		*ds:bx	= MailboxMessageDesc
		cx	= address #
		ss:bp	= inherited frame (from OMLSelect)
RETURN:		carry set if enum should stop:
			bx, cx, bp, di = return values
		carry clear if should keep going:
			cx, bp = data for next callback (cx = next address #)
DESTROYED:	bx, di
SIDE EFFECTS:	message+address may be added to the list

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLSelectUnsentCallback proc	far
		.enter	inherit OMLSelect
	;
	; If address has been sent to, or is a duplicate of something we've
	; already seen, then just ignore it. If it's a duplicate, the handling
	; of the original address will also take care of this duplicate.
	; 
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	done		; jump if MAS_SENT
if 	_DUPS_ALWAYS_TOGETHER
		test	ds:[di].MITA_flags, mask MTF_DUP
		jnz	done
endif	; _DUPS_ALWAYS_TOGETHER
	;
	; Otherwise, we just add the address in.
	; 
		les	si, ss:[listObj]
		mov	si, es:[si]
		add	si, es:[si].OutboxMessageList_offset
		call	OMLAddIfNotAlreadyTransmitting
	;
	; Store possibly-fixed-up object segment.
	; 
		mov	ss:[listObj].segment, es
done:
		inc	cx
		clc
		.leave
		ret
OMLSelectUnsentCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLSelectByTransportCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this address should be listed or transmitted. Message
		has already been checked for using the proper transport.

CALLED BY:	(INTERNAL) OMLSelect via MessageAddrEnum
PASS:		ds:di	= MailboxInternalTransAddr
		*ds:si	= address array
		*ds:bx	= MailboxMessageDesc
		cx	= address #
		ss:bp	= inherited frame (from OMLSelect)
RETURN:		carry set if enum should stop:
			bx, cx, bp, di = return values
		carry clear if should keep going:
			cx, bp = data for next callback (cx = next address #)
DESTROYED:	bx, di
SIDE EFFECTS:	message+address may be added to the list

PSEUDO CODE/STRATEGY:
		if message uses different transport, no match

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLSelectByTransportCallback proc	far
		uses	ds, es, cx
		class	OutboxMessageListClass
		.enter	inherit	OMLSelect
	;
	; If address has been sent to, or is a duplicate of something we've
	; already seen, then just ignore it. If it's a duplicate, the handling
	; of the original address will also take care of this duplicate.
	; 
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	exit		; jump if MAS_SENT
if 	_DUPS_ALWAYS_TOGETHER
		test	ds:[di].MITA_flags, mask MTF_DUP
		jnz	exit
endif	; _DUPS_ALWAYS_TOGETHER
		les	si, ss:[listObj]
		mov	si, es:[si]
		add	si, es:[si].OutboxMessageList_offset
	;
	; See if this address can use the medium in the secondary criteria.
	; If not, we have no basis for comparing the addresses.
	; 
		push	bx
		mov	bx, es:[si].MLI_secondaryCriteria
		call	OMLCheckMediumCompatible
		pop	bx
		jnc	done
	;
	; Now compare the address bytes up to the number of significant
	; bytes, or the shorter of the two addresses, whichever is least.
	;
		push	bx, cx, si, di
		mov	bx, es:[si].MLI_primaryCriteria
		mov	bx, es:[bx]

		mov	cx, es:[bx].MCPC_data.MDPC_byTransport.MDBTD_addrSize
		cmp	cx, ds:[di].MITA_opaqueLen
		jb	haveSize
		mov	cx, ds:[di].MITA_opaqueLen
haveSize:
		cmp	cx, es:[si].OMLI_sigAddrBytes
		jb	doCompare
		mov	cx, es:[si].OMLI_sigAddrBytes
doCompare:
		tst	cx
		je	foundMatch
		lea	si, ds:[di].MITA_opaque
		lea	di, es:[bx].MCPC_data.MDPC_byTransport.MDBTD_addr
		repe	cmpsb
foundMatch:
		pop	bx, cx, si, di
		jne	done
	;
	; All systems go: add the address if it's not currently being
	; transmitted (or queued for transmission)
	; 
		call	OMLAddIfNotAlreadyTransmitting	; es <- new listObj seg
done:
	;
	; Store possibly-fixed-up object segment.
	; 
		mov	ss:[listObj].segment, es
exit:
		.leave
	;
	; Keep enumerating after adjusting CX to the next address index for the
	; next callback.
	; 
		inc	cx
		clc
		ret
OMLSelectByTransportCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLCheckMediumCompatible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the medium used by an address can use the unit
		stored in the search criteria.

CALLED BY:	(INTERNAL) OMLSelectByTransportCallback
PASS:		*es:bx	= MessageControlPanelCriteria for MDPT_BY_MEDIUM
		ds:di	= MailboxInternalTransAddr
RETURN:		carry set if the address can use the unit
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLCheckMediumCompatible proc	near
		uses	cx, dx, ax, bx
		.enter
		mov	bx, es:[bx]
		mov	cx, es
		lea	dx, es:[bx].MCPC_data.MDPC_byMedium
		mov	ax, ds:[di].MITA_medium
		call	OMCompare
		.leave
		ret
OMLCheckMediumCompatible endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLAddIfNotAlreadyTransmitting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the message & address to the list, or mark it for 
		transmission if it's SEND_WITHOUT_QUERY and within its
		transmission window.

CALLED BY:	(INTERNAL) OMLSelectByTransportCallback,
			   OMLSelectByMediumCallback
PASS:		ds:di	= MailboxInternalTransAddr
		cx	= address index
		*ds:bx	= MailboxMessageDesc
		es:si	= OutboxMessageListInstance
		ss:bp	= inherited frame from OMLSelect
RETURN:		es	= fixed up
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLAddIfNotAlreadyTransmitting proc	near
		uses	ds, bx, dx
		class	OutboxMessageListClass
		.enter	inherit	OMLSelect
	;
	; See if there's a thread actively transmitting to this transport +
	; medium combo and if it's transmitting this message to this address
	; 
		mov	dl, ds:[di].MITA_flags
		andnf	dl, mask MTF_STATE
		cmp	dl, MAS_QUEUED shl offset MTF_STATE
		jae	done
	;
	; The message & address are eligible to be displayed. If the message
	; is marked send-without-query and the medium over which it'd be sent
	; is available, and we're within its transmission window, mark this
	; address and its duplicates as requiring transmission and tell
	; OMLSelect it needs to add the message to the xmit queue
	; 
		mov	bx, ds:[bx]
		test	ds:[bx].MMD_flags, mask MMF_SEND_WITHOUT_QUERY
		jz	addMsg
		test	ds:[di].MITA_flags, mask MTF_TRIES
		jnz	addMsg		; if we've tried to send this before,
					;  do *not* attempt another auto-send;
					;  wait for the user to explicitly
					;  request it.
		tst	ss:[canXmit]
		jz	addMsg
		
		mov	ax, es:[si].OMLI_currentTime.FDAT_date
		cmp	ds:[bx].MMD_transWinOpen.FDAT_date, ax
		jb	xmit		; => we're on a different day, so
					;  do the send
		ja	addMsg		; => we're on an earlier day, so just
					;  display the thing

		mov	ax, es:[si].OMLI_currentTime.FDAT_time
		cmp	ds:[bx].MMD_transWinOpen.FDAT_time, ax
		jbe	xmit		; => we're after the window, so do
					;  the send

addMsg:
	;
	; Add the message + address to the end of the list.
	; 
		push	bp
		StructPushBegin	MLMessage
		StructPushSkip	<MLM_priority, MLM_state>
		StructPushField	MLM_registered, \
			<ds:[bx].MMD_registered.FDAT_time, \
			 ds:[bx].MMD_registered.FDAT_date>
if	_AUTO_RETRY_AFTER_TEMP_FAILURE
		StructPushSkip	<MLM_autoRetryTime, MLM_medium, MLM_transport>
else
		StructPushSkip	<MLM_medium, MLM_transport>
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE
		StructPushField	MLM_address, cx
		StructPushField	MLM_message, <ss:[msg].high, ss:[msg].low>
		StructPushEnd

		lds	si, ss:[listObj]
		call	MailboxGetAdminFile
		mov	bp, sp
		call	MessageListAddMessage
		add	sp, size MLMessage
		pop	bp

		segmov	es, ds		; es <- fixed up list object segment
done:
		.leave
		ret

xmit:
	;
	; Mark this address and all its duplicates with the xmitID
	; 
		mov	dx, ss:[xmitID]
		mov	si, ds:[bx].MMD_transAddrs
xmitDupLoop:
		mov	ds:[di].MITA_addrList, dx
		mov	ax, ds:[di].MITA_next
			CheckHack <MITA_NIL eq -1>
		inc	ax
		jz	xmitLoopDone
		dec	ax
		call	ChunkArrayElementToPtr		; ds:di <- next dup
EC <			CheckHack <MAS_SENT eq 0>			>
EC <		test	ds:[di].MITA_flags, mask MTF_STATE		>
EC <		ERROR_Z	DUP_ADDRESS_SENT_BEFORE_ORIGINAL		>
   		jmp	xmitDupLoop

xmitLoopDone:
	;
	; Now dirty the message block before we return, and tell OMLSelect to
	; add this message to the xmit queue.
	; 
		call	UtilVMDirtyDS
		mov	ss:[needXmit], TRUE
		jmp	done
OMLAddIfNotAlreadyTransmitting endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLSelectByMediumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this address should be listed or transmitted.

CALLED BY:	(INTERNAL) OMLSelect via MessageAddrEnum
PASS:		ds:di	= MailboxInternalTransAddr
		*ds:si	= address array
		*ds:bx	= MailboxMessageDesc
		cx	= address #
		ss:bp	= inherited frame (from OMLSelect)
RETURN:		carry set if enum should stop:
			bx, cx, bp, di = return values
		carry clear if should keep going:
			cx, bp = data for next callback (cx = next address #)
DESTROYED:	bx, di
SIDE EFFECTS:	message+address may be added to the list

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLSelectByMediumCallback proc	far
		uses	ds, es, cx
		class	OutboxMessageListClass
		.enter	inherit	OMLSelect
	;
	; If address has been sent to, or is a duplicate of something we've
	; already seen, then just ignore it. If it's a duplicate, the handling
	; of the original address will also take care of this duplicate.
	; 
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	done		; jump if MAS_SENT
if	_DUPS_ALWAYS_TOGETHER
		test	ds:[di].MITA_flags, mask MTF_DUP
		jnz	done
endif	; _DUPS_ALWAYS_TOGETHER

		les	si, ss:[listObj]
		mov	si, es:[si]
		add	si, es:[si].OutboxMessageList_offset
	;
	; See if this address can use the medium in the primary criteria.
	; 
		push	bx
		mov	bx, es:[si].MLI_primaryCriteria
		call	OMLCheckMediumCompatible
		pop	bx
		jnc	done
	;
	; That's enough for us to go on. Add the thing...
	; 
		call	OMLAddIfNotAlreadyTransmitting	; es <- new listObj seg
		mov	ss:[listObj].segment, es
done:
		.leave
		inc	cx			; next address, coming up
		clc
		ret
OMLSelectByMediumCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLMlUpdateList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare our instance data for examining this new message.
		Note that we *do not* do anything special for SEND_WITHOUT_QUERY
		messages here, in contrast to ML_RESCAN, as we assume they
		have been taken care of by MSG_MA_OUTBOX_SENDABLE_CONFIRMATION

CALLED BY:	MSG_ML_UPDATE_LIST
PASS:		*ds:si	= OutboxMessageList object
		ds:di	= OutboxMessageListInstance
		cxdx	= MailboxMessage new to outbox (bit 0 of dx set if
			  skip sorting)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLMlUpdateList method dynamic OutboxMessageListClass, MSG_ML_UPDATE_LIST
	;
	; Set OMLI_transmitQueue.high to 0 so we know, when we're called
	; back, we can't transmit.
	; 
		mov	ds:[di].OMLI_transmitQueue.high, 0
	;
	; No need to do anything else. transmitID & currentTime are of concern
	; only when we can transmit, which we can't, and sigAddrBytes should
	; still be set from the last rescan.
	; 
		mov	di, offset OutboxMessageListClass
		GOTO	ObjCallSuperNoLock
OMLMlUpdateList endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to compare two messages from the outbox
		to sort them in ascending order.

CALLED BY:	(EXTERNAL) MLSortMessages
PASS:		ds:si	= MLMessage #1
		es:di	= MLMessage #2 (ds = es)
RETURN:		flags set so caller can jl, je, or jg according as
			ds:si is less than, equal to, or greater than es:di
DESTROYED:	ax, bx, cx, dx, di, si allowed
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		When comparing date stamps, we have to convert from unsigned
			comparison flags to signed comparison flags. We assume
			there will never be more than 32767 addresses for
			a message...
			

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLCompare	proc	far
		.enter
	;
	; If the things are the same message, we sort by the address number,
	; first addresses first.
	; 
	; We do our own double comparison instead of using "cmpdw", because
	; all we care is whether they are equal or not.  This way we can avoid
	; jumping twice if the first match fails.  And we can compare the low
	; word first (which is more likely to differ than the high word).
	;
		mov	ax, ds:[si].MLM_message.low
		cmp	ax, ds:[di].MLM_message.low
		jne	compareDates
		mov	ax, ds:[si].MLM_message.high
		cmp	ax, ds:[di].MLM_message.high
		je	compareAddressNums

compareDates:
	;
	; Deref the messages and compare the dates, first, as they're the
	; most significant part.
	; 
		mov	ax, ds:[si].MLM_registered.FDAT_date
		cmp	ax, ds:[di].MLM_registered.FDAT_date
		jb	convertToSigned
		ja	convertToSigned
	;
	; Same date, so now we can compare the times.
	; 
		mov	ax, ds:[si].MLM_registered.FDAT_time
		cmp	ax, ds:[di].MLM_registered.FDAT_time
		je	done

convertToSigned:
	;
	; Shift the inverse of the carry flag into the sign flag to get
	; reverse-order sorting. Why?
	;
	; 	JB => CF=1	JG => SF=0
	; 	JA => CF=0	JL => SF=1
	;
		lahf
		mov	al, mask CPU_SIGN
		ja	haveSign
		clr	al
haveSign:
		andnf	ah, not mask CPU_SIGN
		or	ah, al
		sahf
done:
		.leave
		ret

compareAddressNums:
		Assert	be, ds:[si].MLM_address, 32767
		Assert	be, ds:[di].MLM_address, 32767

		mov	ax, ds:[si].MLM_address
		cmp	ax, ds:[di].MLM_address
		jmp	done
OMLCompare	endp
		
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLMlCheckBeforeRemoval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The passed message is about to removed from the list due
		to a box-change notification. Decide if the thing should
		actually remain in the list, but with a different address
		instead.

CALLED BY:	MSG_ML_CHECK_BEFORE_REMOVAL
PASS:		*ds:si	= OutboxMessageList object
		ds:di	= OutboxMessageListInstance
		cxdx	= MailboxMessage
		bp	= MABoxChange
RETURN:		carry set if item should remain:
			bp	= address # for entry (may be same as
				  MABC_ADDRESS)
		carry clear if item should be removed
			bp	= destroyed
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLMlCheckBeforeRemoval method dynamic OutboxMessageListClass, 
					MSG_ML_CHECK_BEFORE_REMOVAL
		.enter
	;
	; If the change type is QUEUED or SENDING, we also nuke the thing
	; unconditionally, as duplicate addresses are always queued together.
	;
			CheckHack <MACT_REMOVED eq 0>
		test	bp, mask MABC_TYPE	; (clears carry)
		jnz	done
	;
	; If there are unsent duplicate addresses, update MLM_address to
	; next unsent duplicate.  Otherwise, nuke the reference.
	;	cx:dx = MailboxMessage
	;
		mov	ax, bp
		andnf	ax, mask MABC_ADDRESS	; ax <- starting address #
		push	cx, dx			;save MailboxMessage
		call	MessageLockCXDX		;*ds:di = MailboxMessageDesc
		mov	di, ds:[di]
		mov	si, ds:[di].MMD_transAddrs ;*ds:si = address array
		call	ChunkArrayElementToPtr	
	;
	; Check if ds:di = MailboxInternalTransAddr has unsent duplicates.
	;
nukeLoop:
		mov	ax, ds:[di].MITA_next	;ax = address # to test.
		cmp	ax, MITA_NIL		;Any more duplicates?
		je	noDups			;No, just nuke it.
		
		call	ChunkArrayElementToPtr	;ds:di = address to test
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	nukeLoop
	;
	; Found an unsent duplicate -- return index of unsent MTF_DUP address
	; which we've found, telling caller to keep the message in the list.
	;
		call	UtilVMUnlockDS
		mov_tr	bp, ax			; bp <- new addr index
		stc				; CF <- keep it, please
		jmp	popDone
noDups:
	;
	; There are no unsent duplicates, so get rid of the message
	; reference.
	;
		call	UtilVMUnlockDS
		clc
popDone:
		pop	cx, dx			;cx:dx = MailboxMessage
done:
		.leave
		ret
OMLMlCheckBeforeRemoval endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLMlDeliverAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Place all the messages we're displaying onto a single queue
		and submit them for transmission.

CALLED BY:	MSG_ML_DELIVER_ALL
PASS:		*ds:si	= OutboxMessageList object
		ds:di	= OutboxMessageListInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLMlDeliverAll	method dynamic OutboxMessageListClass, MSG_ML_DELIVER_ALL
		.enter
		CheckHack <OutboxMessageList_offset eq MessageList_offset>
		mov	si, ds:[di].MLI_messages
		tst	si
		jz	done
	;
	; Create a queue to which we can add all the messages.
	; 
		call	OTCreateQueue
		mov_tr	dx, ax
	;
	; Allocate a TalID with which we can mark all the addresses.
	;
		call	AdminAllocTALID
	;
	; Mark them all and add them to the queue, please.
	; 
		clrdw	cxbp
		mov	bx, cs
		mov	di, offset OMLDeliverAllCallback
		call	ChunkArrayEnum
	;
	; Submit the queue for transmission
	;
		mov	di, dx
		mov_tr	cx, ax
		call	OutboxTransmitMessageQueue
		jnc	done
		call	OutboxCleanupFailedTransmitQueue
done:
		.leave
		ret
OMLMlDeliverAll	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLDeliverAllCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark a message to be delivered and add it to the queue,
		if it's not already there.

CALLED BY:	(INTERNAL) OMLMlDeliverAll via ChunkArrayEnum
PASS:		ax	= TalID with which to mark the thing
		cxbp	= MailboxMessage from previous entry
		dx	= DBQ handle to which to add message if different
			  from previous
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLDeliverAllCallback proc	far
		.enter
	;
	; Lock down the message to get to its address array.
	;
		push	ds, di
		push	dx, cx
		push	ax
		mov	cx, ds:[di].MLM_address		; cx <- address to mark
		movdw	dxax, ds:[di].MLM_message
		call	MessageLock
		mov	di, ds:[di]
		mov	si, ds:[di].MMD_transAddrs
		mov_tr	ax, cx				; ax <- starting addr #
		pop	dx				; dx <- TalID
		clr	bx
markLoop:
	;
	; Mark the selected address and all its duplicates, noting whether
	; there were any of them yet unsent.
	;
		call	ChunkArrayElementToPtr
		CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	nextAddr
		mov	bl, 1
		mov	ds:[di].MITA_addrList, dx
nextAddr:
		mov	ax, ds:[di].MITA_next
		cmp	ax, MITA_NIL
		jne	markLoop
		
		tst	bx
		jz	noQueue			; => all were transmitted
	;
	; Dirty the message block, since we changed something, then release it.
	;
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS

		mov_tr	ax, dx			; ax <- TalID
		pop	dx, cx			; cxbp <- previous entry's msg
						; dx <- DBQ
		pop	ds, di			; ds:di <- MLMessage
	;
	; If this is a different message from the previous entry's, add the
	; thing to the queue.
	; 
		cmpdw	cxbp, ds:[di].MLM_message
		je	done
		movdw	cxbp, ds:[di].MLM_message	; cxbp <- message, for
							;  next callback
		call	MailboxGetAdminFile
		mov	di, dx			; ^vbx:di <- DBQ

		push	dx, ax
		movdw	dxax, cxbp		; dxax <- message to add
		call	DBQAdd
		; XXX: ERROR?
		pop	dx, ax
done:
		clc	
		.leave
		ret
noQueue:
	;
	; Not actually transmitting anything for this address, as it's already
	; been done. Release the message block without dirtying it and
	; restore registers for the next callback.
	; 
		call	UtilVMUnlockDS
		mov_tr	ax, dx			; ax <- TalID
		pop	dx, cx
		pop	ds, di
		jmp	done
OMLDeliverAllCallback endp
OutboxUICode	ends

endif	; _CONTROL_PANELS
