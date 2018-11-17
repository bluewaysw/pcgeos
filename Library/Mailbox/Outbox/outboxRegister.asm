COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxRegister.asm

AUTHOR:		Adam de Boor, Apr 29, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/29/94		Initial revision


DESCRIPTION:
	Functions to handle the registration of a new message in the outbox.
		

	$Id: outboxRegister.asm,v 1.1 97/04/05 01:21:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Outbox	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxMessageAdded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification routine called when a message is added to the
		outbox DBQ.

CALLED BY:	(EXTERNAL) DBQAdd
PASS:		bx	= VM file handle holding the message
		di	= DBQ handle
		dxax	= DBGroupAndItem of the message
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		For each address:
		    if MITA_addrList is 0:
			allocate talID & mark address & all other addresses
			    with same medium
			if current time after start time & medium is available:
			    send MSG_MA_OUTBOX_SENDABLE_CONFIRMATION
			else
			    send MSG_MA_OUTBOX_CONFIRMATION
				

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxMessageAdded proc	far
		uses	cx, ax, ds, di, si, bx, bp, dx
		.enter
		call	MessageLock		; *ds:di <- MMD
		mov	cx, di			; pass to enum in CX
		mov	si, ds:[di]

if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; If a transmission-window-open time has been set for the message, make
	; that the initial retry time for the message.
	;
		mov	bx, ds:[si].MMD_transWinOpen.FDAT_date
		or	bx, ds:[si].MMD_transWinOpen.FDAT_time
		jz	initialRetryHandled
		movdw	ds:[si].MMD_autoRetryTime, ds:[si].MMD_transWinOpen, bx
initialRetryHandled:
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

if 	_OUTBOX_SEND_WITHOUT_QUERY or _AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; Forcibly set the SEND_WITHOUT_QUERY flag for these systems. Block
	; will be dirtied in a moment.
	;
	; 10/27/95: if third-class or worse priority, do not set this bit.
	; Wait for user to request it or some other thing to happen before
	; attempting to send the message. -- ardeb
	;
		mov	bx, ds:[si].MMD_flags
 if	_OUTBOX_SEND_WITHOUT_QUERY
		ornf	bx, mask MMF_SEND_WITHOUT_QUERY
		mov	ds:[si].MMD_flags, bx	; assume not 3d class
 endif	; _OUTBOX_SEND_WITHOUT_QUERY

		andnf	bx, mask MMF_PRIORITY
		cmp	bx, MMP_THIRD_CLASS shl offset MMF_PRIORITY
		jb	swqDone

 if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; Flag Upon Request state by setting retry to eternity
	;
		movdw	ds:[si].MMD_autoRetryTime, MAILBOX_ETERNITY
 endif

 if	_OUTBOX_SEND_WITHOUT_QUERY
		andnf	ds:[si].MMD_flags, not mask MMF_SEND_WITHOUT_QUERY
 endif

swqDone:
endif	; _OUTBOX_SEND_WITHOUT_QUERY or _AUTO_RETRY_AFTER_TEMP_FAILURE
		
		mov	si, ds:[si].MMD_transAddrs
		mov	bx, cs
		mov	di, offset ORMessageAddedCallback
		mov	bp, ax			; ds:bp = MailboxMessage
		pushdw	dxax
		call	ChunkArrayEnum

		call	UtilVMDirtyDS		; addresses were changed...
		call	UtilVMUnlockDS

		popdw	cxdx
		mov	bp, (MABC_ALL shl offset MABC_ADDRESS) or \
				mask MABC_OUTBOX or \
				(MACT_EXISTS shl offset MABC_TYPE)
		mov	ax, MSG_MA_BOX_CHANGED
		clr	di			; di <- additional msg flags
		call	UtilForceQueueMailboxApp; queue to avoid stack overflow
						;  when sending poof message
						;  -- ardeb 9/11/95
		.leave
		ret
OutboxMessageAdded endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORNotifyIndicator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the indicator app know how many documents are in the 
		outbox

CALLED BY:	(INTERNAL) OutboxMessageAdded
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	GCN notification sent out

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORMessageAddedCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check this address to see if it's a new medium and, if so,
		whether it can be sent, generating an appropriate confirmation
		box for the user for each medium used.

CALLED BY:	(INTERNAL) OutboxMessageAdded via ChunkArrayEnum
PASS:		ds:di	= MailboxInternalTransAddr
		ax	= size of MailboxInternalTransAddr
		*ds:si	= address array
		dxbp	= MailboxMessage
		*ds:cx	= MailboxMessageDesc
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	message may be sent to the mailbox library app object to tell
		the user about the message.

PSEUDO CODE/STRATEGY:
		if MITA_addrList is 0:
		    allocate talID & mark address & all other addresses
			with same medium
		    if current time after start time & medium is available:
			send MSG_MA_OUTBOX_SENDABLE_CONFIRMATION
		    else
			send MSG_MA_OUTBOX_CONFIRMATION
		
NOTES:
		If MMD_transWinOpen is set to MAILBOX_ETERNITY, we
		are treating that as a request to send the message
		using the next available connection.  This was added
		for Lizzy by partner's request.

		_OUTBOX_SEND_WITHOUT_QUERY and _AUTO_RETRY_AFTER_TEMP_FAILURE
		must both be TRUE for this change to work.

		I'm leaving the code responder-only until someone
		decides to include the "clear talID" fix for all products. 
							-jwu 3/4/97

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version
	jwu	3/04/97		Added transWinOpen set to ETERNITY code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ORMessageAddedCallback proc	far
		.enter
	;
	; See if this address has already been handled (field initialized to 0
	; when address stored)
	; 
		tst	ds:[di].MITA_addrList
		LONG jnz done			; => it has
	;
	; Mark it and all the other addresses that use the same medium with
	; a new talID that will be used when creating the display in the
	; confirmation box (and also tell us when we've dealt with subsequent
	; addresses using the same medium).
	; 
		push	dx, di
		call	AdminAllocTALID
		push	cx
		mov_tr	cx, ax
		mov	dx, ds:[di].MITA_medium
		mov	bx, cs
		mov	di, offset ORMessageAddedMarkCallback
		call	ChunkArrayEnum
		pop	cx
	;
	; Now see if the message is into its transmission window. If it's not,
	; the presence or absence of the medium is irrelevant. (can't use cmpdw
	; for the comparison b/c FileDateAndTime has the words in the wrong
	; order.)
	; 
		call	TimerGetFileDateTime	; dxax <- date & time
		mov	di, cx
		mov	di, ds:[di]		; ds:di <- MailboxMessageDesc

		cmp	ds:[di].MMD_transWinOpen.FDAT_date, ax
		jne	dateCheckComplete	; (branch at dCC will handle
						; both > & < cases)
		cmp	ds:[di].MMD_transWinOpen.FDAT_time, dx
dateCheckComplete:
		mov	si, di		; ds:si = MailboxMessageDesc
		mov	ax, MSG_MA_START_NEXT_EVENT_TIMER
		pop	dx, di
		ja	notEligible	; start of transmit window is beyond
					;  the current time, so message is
					;  not sendable
	;
	; start of xmit window is open.  Schedule an event for the deadline.
	;
		BitSet	ds:[si].MMD_flags, MIMF_NOTIFIED_TRANS_WIN_OPEN
		push	cx, dx
		movdw	dxcx, ds:[si].MMD_transWinClose
		cmpdw	dxcx, MAILBOX_ETERNITY
		je	afterDeadline	; jump if no deadline to schedule
		call	UtilSendToMailboxApp
afterDeadline:
		pop	cx, dx

if	_OUTBOX_SEND_WITHOUT_QUERY
		test	ds:[si].MMD_flags, mask MMF_SEND_WITHOUT_QUERY
		jnz	checkMedium

		mov	ax, handle uiSentUponRequestStr
		mov	si, offset uiSentUponRequestStr
		jmp	notEligibleAfterStartSchedule

checkMedium:
endif	; _OUTBOX_SEND_WITHOUT_QUERY

	;
	; Ask the OM code to see if the medium this message needs
	; is available. If it is, then we use the confirmation box that says
	; the message can be sent...
	; 
		mov	ax, ds:[di].MITA_medium
if	_OUTBOX_SEND_WITHOUT_QUERY
		push	es, si, cx, dx, di
		segmov	es, ds
		add	di, offset MITA_opaqueLen
		movdw	cxdx, ds:[si].MMD_transport
		mov	si, ds:[si].MMD_transOption
		call	OMCheckConnectable
		pop	es, si, cx, dx, di
else	; !_OUTBOX_SEND_WITHOUT_QUERY
		call	OMCheckMediumAvailable
endif	; _OUTBOX_SEND_WITHOUT_QUERY

		mov	bx, si		; ds:bx = MailboxMessageDesc
		mov	si, MSG_MA_OUTBOX_SENDABLE_CONFIRMATION
		jc	tellApp

		push	cx
		mov	si, ds:[bx].MMD_transAddrs	; *ds:si = addr array
		push	si
		push	dx
		sub	di, ds:[si]	; di = offset to current MITA element
		mov	dx, ds:[bx].MMD_transOption
		mov	cx, ds:[bx].MMD_transport.MT_id
		mov	bx, ds:[bx].MMD_transport.MT_manuf
		;
		; Unlock message to avoid possibility of deadlock.
		; ORGetMediumNotAvailReason tries to find an active
		; transmission thread for this medium/transport using
		; OTFindThread.  If there was a (unrelated) transmission
		; thread active with the MainThread resource locked and
		; trying to lock a message in the same DB item group as
		; our message, we'd deadlock on MainThread and the DB item
		; group.  See bug 56777, for example.
		; 
		call	UtilVMUnlockDS	; unlock message to avoid poss. of
					;	deadlock, we re-deref when
					;	re-locking to handle possible
					;	lmem movement
		call	ORGetMediumNotAvailReason
		pop	dx
		;
		; address array for this message won't change, so we can
		; just re-derefence this way
		;	di = offset to current MITA element in addr array
		;	dxbp = Message
		;	^lax:si = reason string
		;	(on stack) = addr array chunk
		;
		push	di
		xchg	ax, bp		; dxax = Message, bp = reason handle
		call	MessageLock	; ds = Message block
		xchg	ax, bp		; dxbp = Message, ax = reason handle
		pop	di
		pop	bx		; *ds:bx = addr array
		add	di, ds:[bx]	; ds:di = current MITA element
		pop	cx
		jmp	notEligibleAfterStartSchedule

notEligible:


	;
	; Send MSG_MA_START_NEXT_EVENT_TIMER to schedule an event for
	; the start of xmit window.  ds:[si].MMD_transWinOpen is when
	; message will be sent.
	;
		push	cx, dx
		movdw	dxcx, ds:[si].MMD_transWinOpen
		call	UtilSendToMailboxApp
		pop	cx, dx

		mov	ax, handle uiNotTimeForTransmissionStr
		mov	si, offset uiNotTimeForTransmissionStr

notEligibleAfterStartSchedule:
	;
	; Set the reason we weren't willing to send the message.
	;
		push	cx, dx
		movdw	cxdx, axsi
		call	ORStoreReason
		mov	ds:[di].MITA_reason, ax
			CheckHack <offset MTF_TRIES eq 0>
		inc	ds:[di].MITA_flags
		call	UtilVMDirtyDS
	;
	; Free the lmem block we might have allocated to fetch the reason
	; the medium's not available.
	;
		cmp	cx, handle ROStrings
		je	reasonStored
		mov	bx, cx
		call	MemFree
reasonStored:
		pop	cx, dx
	
		mov	si, MSG_MA_OUTBOX_CONFIRMATION
tellApp:
	;
	; Time now to tell the application to put up a confirmation box.
	; First we need to add a reference to the message (which will be 
	; removed when the box comes down).
	;
		mov	ax, bp

	; dxax	= MailboxMessage
	; ds:di	= MailboxInternalTransAddr
	; si	= message to send to app
	; 
		push	cx, dx, bp, ax
		call	MailboxGetAdminFile
		call	DBQAddRef
	;
	; Rearrange the registers for the call:
	; 	cxdx <- MailboxMessage
	; 	bp <- talID
	; 	ax <- message for app
	; 
		mov	cx, dx
		mov_tr	dx, ax
		mov_tr	ax, si
		mov	bp, ds:[di].MITA_addrList
	;
	; Tell our application object, asynchronously, to tell the user.
	; 
		call	UtilSendToMailboxApp
		pop	cx, dx, bp, ax
done:
		clc
		.leave
		ret
ORMessageAddedCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORGenerateTimeMessageString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate "Send time <time> string"

CALLED BY:	ORMessageAddedCallback

PASS:		ax = FileTime
RETURN:		^lax:si is null terminated string for why message not sent
DESTROYED:	nothing

NOTES:		Replaces '\1' in uiNotTimeForTransmissionStr with passed time

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	12/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORGetMediumNotAvailReason
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the reason the medium's not available into an
		lmem chunk we can use.

CALLED BY:	(INTERNAL) ORMessageAddedCallback
PASS:		ax	= OutboxMedia token
		bxcx	= MailboxTransport (can pass bx >
				MANUFACTURER_ID_DATABASE_LAST if there is no
				associated transport)
		dx	= MailboxTransportOption (ignored if bx >
				MANUFACTURER_ID_DATABASE_LAST)
RETURN:		^lax:si	= reason string to use. ax may be dynamically
			  allocated global block that must be freed by
			  the caller.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ORGetMediumNotAvailReason proc	far
		uses	ds, di, cx, dx, bx
		.enter
		
		push	es		; (done outside uses to be popped
					;  earlier and avoid segment ec
					;  death)

	;
	; Allocate an lmem block into which we can fetch the medium descriptor
	; and the reason for its absence.
	;
		push	ax
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		call	MemAllocLMem
		call	MemLock
		mov	es, ax
		mov	ds, ax
		pop	ax
		
	;
	; Find out how big we need to make the chunk for the medium descriptor
	;
		clr	di, cx
		call	OMGetMediumDesc	; cx <- # bytes
	;
	; Allocate a chunk that big
	;
		push	ax
		call	LMemAlloc
		mov_tr	si, ax
		pop	ax
	;
	; Fetch the descriptor, s'il vous plais
	;
		mov	di, ds:[si]
		call	OMGetMediumDesc

		pop	es		; es <- passed es (avoid ec +segment)

	;
	; See if there's a reason stored.
	;
		movdw	cxdx, dsdi
		call	MediaGetReason
		tst	ax
		jz	useDefault	; => no, use default
	;
	; Release the lmem block and return it and the chunk.
	;
		call	MemUnlock
		mov_tr	si, ax
		mov_tr	ax, bx		; ^lax:si <- reason
done:
		.leave
		ret
useDefault:
		push	es
		segmov	es, ds
		call	MediaCheckMediumAvailableByPtr
		pop	es
		jc	isAvailable
		mov	ax, handle uiMediumNotAvailableStr
		mov	si, offset uiMediumNotAvailableStr
toDone:
		call	MemFree
		jmp	done
isAvailable:
		mov	ax, handle uiMediumBusyStr
		mov	si, offset uiMediumBusyStr
		jmp	toDone
ORGetMediumNotAvailReason endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORMessageAddedMarkCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to mark all the addresses for the same
		medium with the same talID

CALLED BY:	(INTERNAL) ORMessageAddedCallback via ChunkArrayEnum,
			OSCMsndDeleteMessage via ChunkArrayEnum
PASS:		ds:di	= MailboxInternalTransAddr
		dx	= medium token
		cx	= talID, or 0 to unmark addresses
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ORMessageAddedMarkCallback proc	far
		.enter
		cmp	ds:[di].MITA_medium, dx
		jne	done
EC <		tst	ds:[di].MITA_addrList				>
EC <		jz	EC_ok						>
EC <		tst	cx						>
EC <		ERROR_NZ NEW_ADDRESS_IS_ALREADY_MARKED			>
EC <	EC_ok:								>
		mov	ds:[di].MITA_addrList, cx
		call	UtilVMDirtyDS
done:
		clc
		.leave
		ret
ORMessageAddedMarkCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxStoreAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the addresses for an outgoing message.

CALLED BY:	(EXTERNAL) MRStoreAddresses
PASS:		cx	= number of addresses
		es:si	= MailboxTransAddr array
		*ds:di	= MailboxMessageDesc
		ds:bx	= MailboxMessageDesc
		ax	= MailboxTransportOption
RETURN:		carry set on error
			ax	= MailboxError
DESTROYED:	es, si, cx, bx
SIDE EFFECTS:	loads

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxStoreAddresses proc	far
	;
	; Attempt to load the transport driver, as we'll need it for each
	; address.
	; 
		push	ax, cx, dx
		movdw	cxdx, ds:[bx].MMD_transport
		call	MailboxLoadTransportDriver
		pop	ax, cx, dx
		jc	loadError
	;
	; Loop over all the addresses, storing them one at a time.
	; 
addrLoop:
		call	ORStoreOneAddress
		jc	doneUnloadDriver
		call	ORCheckDuplicate
		add	si, size MailboxTransAddr
		loop	addrLoop
		clc
doneUnloadDriver:
		pushf
		call	MailboxFreeDriver
		popf
		ret

loadError:
		mov	ax, ME_CANNOT_LOAD_TRANSPORT_DRIVER
		ret
OutboxStoreAddresses endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORCheckDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the address just added is a duplicate, in its 
		significant opaque bytes, of another address already
		specified for the message.

CALLED BY:	(INTERNAL) OutboxStoreAddresses
PASS:		*ds:di	= MailboxMessageDesc
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ORCheckDuplicate proc	near
		uses	bx, cx, si, di, ax, dx, bp, es
		.enter
	;
	; Find how many addresses there are, so we can (1) do nothing when
	; there's only one address, and (2) find the last element in the array
	; 
		mov	si, ds:[di]
		movdw	axdx, ds:[si].MMD_transport	; axdx <- transport, for
							;  getting sig # bytes
		mov	bx, ds:[si].MMD_transOption	; bx <- trans option,
							;  for same reason
		mov	si, ds:[si].MMD_transAddrs
		call	ChunkArrayGetCount
		dec	cx			; (1-byte check for == 1, and
						;  gets us 0-origin index from
						;  1-origin count)
		jz	done			; => only 1 addr, so no dup
						;  possible
	;
	; Point to the last element in the array (nukes CX [var sized elts], so
	; use mov_tr...)
	; 
		push	ax			; save transport.high
		mov_tr	ax, cx			; ax <- idx of last elt
		call	ChunkArrayElementToPtr
		pop	cx			; cxdx <- transport
	;
	; Find the number of significant address bytes for the medium/transport
	; pair.
	; 
		mov	ax, ds:[di].MITA_medium
		push	ax			; save for enum...
		call	OMGetSigAddrBytes	; ax <- # bytes
	;
	; Arrange the registers for ChunkArrayEnum and loop over all the
	; addresses, looking for ones that use the same medium and whose first
	; n bytes compare the same.
	; 
		pop	dx			; dx <- medium token
		mov_tr	bp, ax			; bp <- # significant bytes
		mov	cx, di			; cx <- last elt
		segmov	es, ds			; es <- ds, so doesn't have to
						;  be done each time through
						;  the callback
		
		mov	bx, cs
		mov	di, offset ORCheckDuplicateCallback
		call	ChunkArrayEnum		; ax <- index of first dup
		jnc	done
	;
	; Found a duplicate, so run to the end of the list and point it to
	; the last element.
	; 
linkLoop:
		call	ChunkArrayElementToPtr
EC <		ERROR_C	INVALID_DUPLICATE_ADDR_LIST			>
		mov	ax, ds:[di].MITA_next
		cmp	ax, MITA_NIL
		jne	linkLoop

		call	ChunkArrayGetCount
		dec	cx
		mov	ds:[di].MITA_next, cx
	;
	; Mark the new thing as a duplicate.
	; 
		mov_tr	ax, cx
		call	ChunkArrayElementToPtr
		ornf	ds:[di].MITA_flags, mask MTF_DUP
done:
		.leave
		ret
ORCheckDuplicate endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORCheckDuplicateCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to see if this address is the same, in its
		significant opaque address bytes, to the one just added.
		
CALLED BY:	(INTERNAL) ORCheckDuplicate via ChunkArrayEnum
PASS:		ds:di	= MailboxInternalTransAddr to check
		ds:cx	= MailboxInternalTransAddr just added
		es	= ds
		dx	= medium used by ds:cx
		bp	= # bytes to compare
RETURN:		carry set if the same:
			ax	= index of address checked
		carry clear if different
			ax	= destroyed
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ORCheckDuplicateCallback proc	far
		.enter
		cmp	di, cx
		je	done		; => same element, so don't compare
		
		cmp	ds:[di].MITA_medium, dx
		jne	notEqual	; => can't possibly be the same addr

		xchg	si, cx
		call	OUCompareAddresses
		xchg	cx, si
		je	match
notEqual:
		clc
done:
		.leave
		ret

match:
	;
	; Same address, so return the index of this element and stop enumerating
	; 
		call	ChunkArrayPtrToElement
		stc
		jmp	done
ORCheckDuplicateCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORStoreOneAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a single transport address at the end of the array
		of addresses for the message.

CALLED BY:	(INTERNAL) OutboxStoreAddresses
PASS:		es:si	= MailboxTransAddr to add
		*ds:di	= MailboxMessageDesc
		bx	= loaded transport driver
		ax	= MailboxTransportOption
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			ax	= destroyed
		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	variable-sized element appended to MMD_transAddrs array

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/94		Initial version
	ardeb	2/17/95		Commonized grunt work of storing an address
				for both InboxStoreAddresses and
				ORStoreOneAddress

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ORStoreOneAddress proc	near
		uses	cx, di, bx
		.enter
	;
	; Fetch the medium & unit for the address and have the outbox
	; store it away.
	; 
		call	ORGetAndStoreMedium	; ax <- medium token
		jc	done

		call	MessageStoreAddress
		jc	allocErr
done:
		.leave
		ret
allocErr:
	;
	; Unregister the medium & transport.
	; *ds:di	= MMD
	; ax		= medium token
	; 
		push	dx
		mov	di, ds:[di]
		movdw	cxdx, ds:[di].MMD_transport
		mov	bx, ds:[di].MMD_transOption
		call	OMUnregister
		pop	dx

		mov	ax, ME_NOT_ENOUGH_MEMORY
		stc
		jmp	done
ORStoreOneAddress endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORGetAndStoreMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load and call the transport driver to get the medium &
		unit for an address.

CALLED BY:	(INTERNAL) ORStoreOneAddress
PASS:		*ds:di	= MailboxMessageDesc
		es:si	= MailboxTransAddr
		bx	= loaded transport driver
		ax	= MailboxTransportOption
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			ax	= token for medium
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ORGetAndStoreMedium proc	near
mapArgs		local	MBTDMediumMapArgs
		uses	bx, di, cx, dx, si
		.enter
	;
	; Set up the MBTDMediumMapArgs thing on the stack for
	; fetching the medium.
	; 
		mov	ss:[mapArgs].MBTDMMA_transOption, ax
		mov	ax, es:[si].MTA_transAddrLen
		mov	ss:[mapArgs].MBTDMMA_transAddrLen, ax
		movdw	ss:[mapArgs].MBTDMMA_transAddr, \
				es:[si].MTA_transAddr, ax
	;
	; Call the driver to ask for the medium. This also serves to 
	; error-check the address...
	; 
		push	ds, di
		call	GeodeInfoDriver
		mov	cx, ss
		lea	dx, ss:[mapArgs]
		mov	di, DR_MBTD_GET_ADDRESS_MEDIUM
		call	ds:[si].DIS_strategy
		pop	ds, di
		mov	ax, ME_ADDRESS_INVALID
		jc	done
	;
	; Fetch the transport for the message, and let the outbox know
	; what's in store.
	; 
		mov	di, ds:[di]
		mov	bx, ds:[di].MMD_transOption
		mov	si, ds:[di].MMD_transport.high
		mov	di, ds:[di].MMD_transport.low
		call	OMRegister
	;
	; While we've got the medium token, clear the phone blacklist,
	; if necessary
	;
		clc
done:
		.leave
		ret
ORGetAndStoreMedium endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetTransAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the opaque portion of the indicated transport address

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		es:di	= buffer for copy
		ax	= # bytes in buffer
		bx	= address # requested
RETURN:		carry set if couldn't copy:
			ax	= 0 if message or address invalid
				= # bytes needed if buffer was too small
		carry clear if address copied out:
			ax	= # bytes copied out
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetTransAddr proc	far
		uses	ds, si, di, bp, bx, cx
		.enter
EC <		tst	ax						>
EC <		jz	bufferPtrOK					>
EC <		Assert	fptr, esdi					>
EC <bufferPtrOK:							>

		mov	bp, di			; preserve dest ptr
		call	MessageLockCXDX		; *ds:di <- MMD
		jc	invalidMsg
	;
	; Fetch out the address array. If there is none, the address # is
	; invalid.
	; 
		mov	di, ds:[di]
		mov	si, ds:[di].MMD_transAddrs
		tst	si
		jz	invalidAddress
	;
	; Point to the address element.
	; 
		xchg	ax, bx			; ax <- addr #, bx <- buf size
		call	ChunkArrayElementToPtr
		jc	invalidAddress		; => beyond the pale, so addr
						;  is invalid
	;
	; Fetch the size of the opaque data into AX for comparison and return.
	; 
		mov	ax, ds:[di].MITA_opaqueLen
		cmp	ax, bx
		ja	errReturn		; => not enough room in buf
	;
	; Move the data into the passed buffer.
	; 
		lea	si, ds:[di].MITA_opaque
		mov	di, bp			; es:di <- dest buffer
		mov	cx, ax			; cx <- # bytes to copy
		rep	movsb
		clc				; signal happiness
done:
	;
	; Release the message block.
	; 
		call	UtilVMUnlockDS
exit:
		.leave
		ret

invalidAddress:
		clr	ax			; signal no amount of buffer
						;  space could hold the address,
						;  as the thing is bad
errReturn:
		stc
		jmp	done

invalidMsg:
		mov	ax, 0			; signal no amount of buffer
						;  space could hold the address
						;  as the thing is bad
		jmp	exit
MailboxGetTransAddr endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetNumTransAddrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of addresses bound to the given message

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		carry set on error:
			ax	= MailboxError (message invalid)
		carry clear if ok:
			ax	= number of addresses
				= 0 if message is in the inbox
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetNumTransAddrs proc	far
		uses	ds, di, si
		.enter
		call	MessageLockCXDX
		jc	exit

		mov	di, ds:[di]
		mov	si, ds:[di].MMD_transAddrs
		clr	ax			; assume no addresses
		tst	si
		jz	done			; correct -- return 0

		mov_tr	ax, cx			; ax <- entry cx
		call	ChunkArrayGetCount
		xchg	ax, cx			; ax <- count, cx <- saved cx
done:
		call	UtilVMUnlockDS
		clc
exit:
		.leave
		ret
MailboxGetNumTransAddrs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxSetTransAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the opaque transport address for a message, replacing the
		existing one.

		NOTE: the new address may not differ from the old address in its
		      significant address bytes. This is not intended to allow
		      arbitrary redirection of a message, but simply for trans-
		      port drivers to record their progress for a particular
		      address in the insignificant portion of the address.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		es:di	= buffer containing the new address
		bx	= address number to set
		ax	= number of bytes in the buffer.
RETURN:		carry set if copy couldn't be completed:
			ax	= MailboxError (message is invalid or
				  not enough memory available)
		carry clear if address successfully changed:
			ax	= ME_SUCCESS
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxSetTransAddr proc	far
		uses	ds, si, di, cx, dx, es, bx
EC <		uses	bp						>
		.enter
		push	di			; preserve new addr base
		call	MessageLockCXDX
		pop	dx			; es:dx <- new addr
		jc	toDone
	;
	; Point to the element in the transAddrs array.
	; 
		mov	si, ds:[di]
EC <		mov	bp, si						>
		mov	si, ds:[si].MMD_transAddrs
		tst	si
		jz	invalidAddress

		xchg	ax, bx			; ax <- addr #, bx <- addr size
		call	ChunkArrayElementToPtr	; cx <- elt size
		jc	invalidAddress		; => index beyond the pale

			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jnz	doResize		; => address not sent to yet,
						;  so it may be changed

invalidAddress:
		call	UtilVMUnlockDS
		mov	ax, ME_ADDRESS_INVALID
		stc
toDone:
		jmp	done
doResize:

	;
	; EC: Make sure the caller isn't attempting to change the significant
	; bytes of the address.
	; 
EC <		push	ax, cx, si, di					>
EC <		push	bx						>
EC <		push	dx						>
EC <		mov	ax, ds:[di].MITA_medium				>
EC <		movdw	cxdx, ds:[bp].MMD_transport			>
EC <		mov	bx, ds:[bp].MMD_transOption			>
EC <		call	OMGetSigAddrBytes				>
EC <		pop	dx						>
EC <		mov	cx, ds:[di].MITA_opaqueLen			>
EC <		cmp	cx, ax						>
EC <		jbe	haveCmpSize					>
EC <		mov	cx, ax						>
EC <haveCmpSize:							>
EC <		lea	si, ds:[di].MITA_opaque				>
EC <		mov	di, dx						>
EC <	; cx = # avail, or # significant, whichever is smaller		>
EC <		pop	bx		; bx <- # passed		>
EC <		cmp	bx, cx						>
EC <		ERROR_B	CANNOT_CHANGE_SIGNIFICANT_ADDRESS_BYTES		>
EC <		je	doCompare	; => can compare bytes		>
EC <	; compare ax to cx here to catch case where MITA holds fewer	>
EC <	; than the # of significant, where # sig is not ALL_BYTES_SIG	>
EC <		cmp	ax, cx		; are bytes beyond cx significant?>
EC <		ERROR_A	CANNOT_CHANGE_SIGNIFICANT_ADDRESS_BYTES	; yes	>
EC <doCompare:								>
EC <		repe	cmpsb						>
EC <		ERROR_NE CANNOT_CHANGE_SIGNIFICANT_ADDRESS_BYTES	>
EC <		pop	ax, cx, si, di					>

	;
	; Resize the element properly. XXX: have to mess with the chunkarray
	; offset table by hand, here, as kernel provides no way to insert or
	; delete within an element, and we can't use ChunkArrayElementResize,
	; as that'll destroy the user-readable stuff (it deletes at the end).
	; blech.
	;
		sub	bx, ds:[di].MITA_opaqueLen
		je	copy			; same size. yea!

		push	ax			; save element #
		mov	cx, bx			; cx <- # bytes difference (+/-)
		lahf				; save carry for figuring which
						;  LMem routine to call
		lea	bx, ds:[di].MITA_opaque	
		sub	bx, ds:[si]		; bx <- insert/delete offset
		sahf
		mov	ax, si			; *ds:ax <- chunk to adjust
		jb	deleteSpace
		call	LMemInsertAt
		jmp	adjust
deleteSpace:
		neg	cx			; cx <- # bytes to delete
		call	LMemDeleteAt
		neg	cx			; cx <- adjustment value, again
adjust:
	;
	; Now adjust the offset array in the header.
	; 
		pop	ax			; ax <- address #
		add	bx, ds:[si]		; ds:bx <- opaque data
		lea	di, ds:[bx-offset MITA_opaque]	; ds:di <- MITA again
		add	ds:[di].MITA_opaqueLen, cx	; adjust the opaqueLen
							;  properly, while we've
							;  still got cx
		mov	bx, ax			; bx <- address #
		mov_tr	ax, cx			; ax <- adjustment value
	    ;
	    ; Compute the number of elements that need adjusting.
	    ; 
		mov	si, ds:[si]
		mov	cx, ds:[si].CAH_count
		inc	bx			; start adjusting with following
						;  element
		sub	cx, bx			; cx <- # to adjust
		jz	copy
		shl	bx
		add	bx, ds:[si].CAH_offset	; bx <- entry to adjust first
adjustLoop:
		add	ds:[bx], ax		; adjust element base up or
						;  down, as appropriate
		inc	bx			; advance to next
		inc	bx
		loop	adjustLoop

copy:
	;
	; Copy the new data into the properly-sized element
	; 
		mov	cx, ds:[di].MITA_opaqueLen
		add	di, offset MITA_opaque
		mov	si, dx
		segxchg	ds, es			; ds:si <- source
						; es:di <- dest
		rep	movsb
	;
	; Dirty and unlock the message block.
	; 
		segmov	ds, es			; ds <- msg block again
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		call	UtilUpdateAdminFile
			CheckHack <ME_SUCCESS eq 0>
		clr	ax			; (clears carry)
done:
		.leave
		ret
MailboxSetTransAddr endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetUserTransAddrLMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the user-readable form of the passed address

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		bx	= lmem block in which to allocate a chunk to hold
			  the address
		ax	= address # requested
RETURN:		carry set on error:
			ax	= MailboxError (invalid message, insufficient
				  memory)
		carry clear if ok:
			^lbx:ax	= null-terminated subject
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetUserTransAddrLMem proc	far
		uses	si, di, cx, bx, dx
		.enter
		mov	si, ds		; preserve DS in case it points to ^hbx
	;
	; Lock down the message.
	;
		call	MessageLockCXDX
		mov	dx, si		; dx <- DS on entry, for restore
		jc	done		; => message invalid, so boogie.
					;  ax = MailboxError
	;
	; Point to the address desired.
	;
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		call	ChunkArrayElementToPtr
		mov	ax, ME_ADDRESS_INVALID
		jc	unlockDone
	;
	; Compute the size and location of the user-readable portion.
	;
		sub	cx, ds:[di].MITA_opaqueLen
		sub	cx, size MailboxInternalTransAddr
		lea	si, ds:[di].MITA_opaque
		add	si, ds:[di].MITA_opaqueLen
	;
	; Lock down the destination block and note if DS on entry was pointing
	; there. (bx = -1 if so, else 0)
	;
		push	ds
		call	ObjLockObjBlock	; in case lmem block is an object block
		mov	ds, ax
		clr	bx		; assume not pointing to block
		cmp	ax, dx
		jne	allocChunk	; yes
		dec	bx		; no -- flag it
allocChunk:
	;
	; Allocate a chunk to hold the address.
	;
		mov	ax, mask OCF_DIRTY
		call	LMemAlloc
		mov	di, ds		; di <- new location of dest block,
					;  for setting ES and adjusting return
					;  value for DS
		pop	ds
		jc	allocErr
	;
	; If DS was pointing to the block on entry, make sure it'll point there
	; on return.
	;
		inc	bx
		jnz	doCopy		; => not pointing there
		mov	dx, di		; dx <- new segment
doCopy:
	;
	; Copy the data from the trans addr to the chunk.
	;
		push	es		; preserve ES from entry (fixed up if
					;  was pointing to the destination
					;  block)
		mov	es, di
		mov	di, ax
		mov	di, es:[di]	; es:di <- destination
		rep	movsb

		mov	bx, es:[LMBH_handle]
		pop	es
		call	MemUnlock
		clc
unlockDone:
		call	UtilVMUnlockDS
done:
		mov	ds, dx		; ds <- passed DS, possibly fixed up
		.leave
		ret
allocErr:
		call	UtilUnlockDS
		pop	ds
		mov	ax, ME_NOT_ENOUGH_MEMORY
		jmp	unlockDone
MailboxGetUserTransAddrLMem endp


Outbox	ends
