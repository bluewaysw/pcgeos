COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox -- Queueing Messages for Transmit Threads
FILE:		outboxTransmitQ.asm

AUTHOR:		Adam de Boor, May  2, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT OTQGetTransport	Fetches the MailboxTransport for a message

    EXT OutboxTransmitMessage	Arrange for a message to be transmitted to
				one or more of its addresses.

    INT OTQAddOneMessage	Add a single message to the DBQ for a
				transmit thread.

    INT OTQAddOneMessageCallback 
				If the address has the indicated talID,
				change it to the other one.

    EXT OutboxTransmitMessageQueue 
				Queue all the messages in a single DBQ to
				be sent to those addresses marked with the
				given talID

    INT OTQGetFirstTransport	Fetch the MailboxTransport for the first
				message in the passed queue.

    INT OTQCheckAllSameTransport 
				See if the passed queue contains messages
				all for a single transport

    INT OTQCheckAllSameTransportCallback 
				See if a message uses the transport driver
				in the passed local frame

    INT OTQGetQueueOfFirstTransport 
				Remove all messages that use the same
				transport as the first message from the
				passed queue, placing them in a new queue.

    INT OTQGetQueueOfFirstTransportCallback 
				Callback function to remove the messages
				that use a transport from the original
				queue. This cannot be done during a DBQEnum
				of the original queue, as HugeArrayEnum
				does *not* cope with having elements
				removed during the enumeration.

    INT OTQTransmitMessageQueueInternal 
				Submit the messages in the passed queue for
				transmission to the marked addresses.

    INT OTQTransmitMessageQueueInternalCallback 
				Callback function to queue up a single
				message from a DBQ of messages

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 2/94		Initial revision


DESCRIPTION:
	Random functions for queueing up messages to be transmitted and
	arranging for transmit threads to be created, when necessary.
		

	$Id: outboxTransmitQ.asm,v 1.1 97/04/05 01:21:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Outbox	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQGetTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetches the MailboxTransport for a message

CALLED BY:	(INTERNAL) OTQGetFirstTransport, OutboxTransmitMessage
PASS:		dxax	= MailboxMessage
		cx	= talID
RETURN:		carry set if no address with the given ID
		carry clear if got one:
			cxdx	= MailboxTransport
			bx	= MailboxTransportOption
			ax	= medium ref token
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTQGetTransport proc	near
		uses	ds, di, si
		.enter
		clr	si		; start search w/first
		call	OUFindNextAddr	; *ds:di <- message
					; ds:si <- addr
					; ax <- index of addr
		jc	done
		mov	di, ds:[di]
		movdw	cxdx, ds:[di].MMD_transport
		mov	bx, ds:[di].MMD_transOption
		mov	ax, ds:[si].MITA_medium
		call	UtilVMUnlockDS
done:
		.leave
		ret
OTQGetTransport endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQEnsureOnlyOneMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC: Make sure that all marked addresses for the single message
		being sent use the same medium, as we have no means here for
		spawning multiple threads (one per medium) in the single-
		message-being-queued case

CALLED BY:	(INTERNAL) OutboxTransmitMessage
PASS:		dxax	= message being queued
		cx	= talID of addresses to which to send it
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
OTQEnsureOnlyOneMedium proc near
		uses	ds, si, di, bx, cx, dx, ax
		.enter
		call	MessageLock
		mov	si, ds:[di]
		mov	dx, -1
		mov	si, ds:[si].MMD_transAddrs
		test	cx, mask TID_ADDR_INDEX
		jnz	checkAddressInRange

		mov	bx, cs
		mov	di, offset foo
		call	ChunkArrayEnum
		inc	dx
		ERROR_Z	MUST_HAVE_AT_LEAST_ONE_MARKED_ADDRESS
done:
		call	UtilVMUnlockDS
		.leave
		ret

checkAddressInRange:
		mov	ax, cx
		andnf	ax, mask TID_NUMBER
		call	ChunkArrayElementToPtr
		ERROR_C	MUST_HAVE_AT_LEAST_ONE_MARKED_ADDRESS
		jmp	done

	;--------------------
	;ds:di = MailboxInternalTransAddr
	;cx = talID of addresses to send
	;dx = medium ref for previous address (-1 if no previous marked addr)
	;
foo:
		cmp	ds:[di].MITA_addrList, cx
		jne	fooDone
		mov	bx, ds:[di].MITA_medium
		inc	dx
		jz	fooSet
		dec	dx
		cmp	dx, bx
		ERROR_NE ALL_ADDRESSES_MUST_BE_FOR_SAME_TRANSPORT_AND_MEDIUM
fooDone:
		clc
		retf
fooSet:
		mov	dx, bx
		jmp	fooDone
OTQEnsureOnlyOneMedium endp
endif	; ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxTransmitMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Arrange for a message to be transmitted to one or more of
		its addresses.

CALLED BY:	(EXTERNAL) OSCSendMessage, MAOutboxSendableConfirmation,
			ODSendMessage
PASS:		dxax	= MailboxMessage
		cx	= talID for the addresses to which the message is
			  to be sent (use of the talID is hereby passed
			  to this module; caller should not use it for other
			  addresses)
RETURN:		carry set if message couldn't be queued:
			ax	= MailboxError
		carry clear if message queued
			ax	= destroyed
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- plock data block
	- look for thread for transport driver
	- if found, add message to queue, setting addresses with passed tal ID
	  to the thread's own tal ID. Thread will discover the new message
	  & addresses on its next time through the loop. (This will *NOT*
	  piggyback the new message onto an existing connection unless the
	  transmit loop is redone.)
	- if not found:
		- alloc dbq & entry in tracking block
		- add msg to dbq
		- set thread's tal ID to message's
		- spawn thread
		- store handle
	- release block
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxTransmitMessage proc	far
qTalID		local	word		push cx
msg		local	MailboxMessage	push dx, ax
	ForceRef	qTalID		; OTQAddOneMessage
	ForceRef	msg		; OTQAddOneMessage
		uses	cx, dx, ds, di, bx, si
		.enter
EC <		call	OTQEnsureOnlyOneMedium			>
	;
	; Find a thread that's transmitting stuff for the message's transport
	; driver.
	; 
		call	OTQGetTransport	; cxdx <- transport
					;  bx <- option
					; ax <- medium ref
EC <		WARNING_C NO_MESSAGE_ADDRESS_MARKED_WITH_GIVEN_ID	>
		jc	exit

   		clr	si
		call	OTQFindOrCreateThread
		jc	done
	;
	; Add the message to the transmit thread's queue.
	; 
		mov	cx, ds:[di].OTD_dbq
		mov	dx, ds:[di].OTD_queuedID
		call	OTQAddOneMessage
done:
		call	MainThreadUnlock
exit:
		.leave
		ret
OutboxTransmitMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQFindOrCreateThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the transmit thread for the indicated transport +
		transOption + medium triple. If no such thread yet exists,
		create it.

CALLED BY:	(INTERNAL) OutboxTransmitMessage,
			   OTQTransmitMessageQueueInternal
PASS:		cxdx	= MailboxTransport
		bx	= MailboxTransportOption
		ax	= outboxMedia token
		si	= talID for the thread (0 if should be allocated)
RETURN:		carry set if couldn't create the thread:
			ax	= ME_UNABLE_TO_CREATE_TRANSMIT_THREAD
		carry clear if thread found/created:
			ds:di	= OutboxThreadData
		OutboxThreads block p-locked in either case
DESTROYED:	ax, si
SIDE EFFECTS:	thread may be spawned

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTQFindOrCreateThread proc	near
		.enter

		call	OTFindThread	; ds <- MainThreads
					; ds:di <- OutboxThreadData, if CF=1
		jc	doneOK
	;
	; Thread doesn't exist yet. Spawn the sucker & initialize those parts
	; of the OutboxThreadData that are our responsibility. 
	;
	; OTD_xmitID, and OTD_progress are initialized by the transmit thread
	; itself.
	; 
		push	bx		; save transport option
		call	OTCreateTransmitThread 	;bx = thread handle
						;ds:di = OutboxThreadData
		pop	bx
		jc	error
		
		mov	ds:[di].MTD_transOption, bx
		mov	ds:[di].OTD_medium, ax
		movdw	ds:[di].MTD_transport, cxdx

		mov_tr	ax, si		; ax <- TalID for thread
		tst	ax
		jnz	haveTalID	; => caller allocated it already
		call	AdminAllocTALID
haveTalID:
		mov	ds:[di].OTD_queuedID, ax
		call	OTCreateQueue
		mov	ds:[di].OTD_dbq, ax
doneOK:
		clc
done:
		.leave
		ret

error:
		mov	ax, ME_UNABLE_TO_CREATE_TRANSMIT_THREAD
		jmp	done
OTQFindOrCreateThread endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQChangeAddressMarks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the talIDs for those addresses marked by the given
		talID to a new talID

CALLED BY:	(INTERNAL) OTQAddOneMessage, OTrCancelMessagesCallback
PASS:		dxax	= message
		bx	= MABoxChange with MABC_TYPE filled in and
			  MABC_OUTBOX set
		cx	= talID of addresses to be changed
		si	= new talID
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	message block is dirtied

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTQChangeAddressMarks proc	far
newID		local	TalID		push	si
boxChange	local	MABoxChange	push	bx
msg		local	MailboxMessage	push	dx, ax
		uses	dx, ds, di, bx, si, bp, ax
		.enter
EC <		call	OTQEnsureDupsAllMarked				>
		Assert	bitSet, bx, MABC_OUTBOX
				CheckHack <MACT_REMOVED eq 0>
		Assert	bitSet, bx, MABC_TYPE   ; must be one of the things
						;  that indicate existence

		test	cx, mask TID_ADDR_INDEX
		jnz	markByIndex

		mov	bx, SEGMENT_CS
		mov	di, offset changeCallback
		call	MessageAddrEnum
done:
		.leave
		ret

	;
	; The TalID we were given was for an address number, so we want to mark
	; it and its duplicates appropriately
	; 
markByIndex:
		call	MessageLock		; *ds:di <- message
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		mov	ax, cx
		andnf	ax, mask TID_NUMBER
		Assert 	bitClear, ax, <not mask MABC_ADDRESS>
		or	ss:[boxChange], ax	; for eventual notification

if 	_DUPS_ALWAYS_TOGETHER
markByIndexLoop:
		inc	ax
			CheckHack <MITA_NIL eq -1>
		jz	markByIndexDone
		dec	ax
endif	; _DUPS_ALWAYS_TOGETHER
		call	ChunkArrayElementToPtr
EC <		ERROR_C	INVALID_ADDRESS_NUMBER				>

if	_DUPS_ALWAYS_TOGETHER
		mov	ax, ds:[di].MITA_next
endif	; _DUPS_ALWAYS_TOGETHER

			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	markByIndexDone
EC <		tst	ds:[di].MITA_addrList				>
EC <		WARNING_NZ OVERWRITING_EXISTING_ADDRESS_MARK		>
		call	markAddress

if	_DUPS_ALWAYS_TOGETHER
		jmp	markByIndexLoop
endif	; _DUPS_ALWAYS_TOGETHER

markByIndexDone:
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
	;
	; Now let the world know about the change to the head address.
	;
		mov	ax, ss:[boxChange]
		call	notifyApp
		jmp	done

	;--------------------
	; Pass:	ds:di	= MailboxInternalTransAddr
	; 	*ds:si	= address array
	;	*ds:bx 	= MailboxMessageDesc
	; 	cx	= talID being sought
	; 	ss:bp	= replacement talID
	; Return:	carry set to stop enumerating
	; 
changeCallback:
		cmp	ds:[di].MITA_addrList, cx
		jne	changeDone
		call	markAddress
		call	UtilVMDirtyDS
	;
	; Send notification if not duplicate address.
	;
		test	ds:[di].MITA_flags, mask MTF_DUP
		jnz	changeDone
		call	ChunkArrayPtrToElement	; ax <- addr #

		Assert 	bitClear, ax, <not mask MABC_ADDRESS>

		or	ax, ss:[boxChange]
		call	notifyApp
changeDone:
		clc
		retf

	;--------------------
	; Mark a single address with the new ID, adjusting the MTF_STATE
	; appropriately.
	;
	; Pass:	ds:di	= MailboxInternalTransAddr to mark
	; 	ss:bp	= "inherited" frame with newID and boxChange set
	; Return:	nothing
	;		ds is *NOT* marked dirty
	; Destroyed:	bx
	;
markAddress:
		mov	bx, ss:[newID]
		mov	ds:[di].MITA_addrList, bx
	;
	; Set the MTF_STATE properly. The rules are:
	; 	- if the new ID is 0, the thing is neither queued nor being sent
	; 	- else we look at the change type to decide.
	;
		BitClr	ds:[di].MITA_flags, MTF_STATE
			CheckHack <offset MABC_TYPE - 8 eq offset MTF_STATE>
			CheckHack <width MABC_TYPE eq width MTF_STATE>
			CheckHack <MACT_EXISTS eq MAS_EXISTS>
			CheckHack <MACT_QUEUED eq MAS_QUEUED>
			CheckHack <MACT_PREPARING eq MAS_PREPARING>
			CheckHack <MACT_READY eq MAS_READY>
			CheckHack <MACT_SENDING eq MAS_SENDING>
			
		mov	bl, ss:[boxChange].high
		andnf	bx, mask MTF_STATE
		ornf	ds:[di].MITA_flags, bl
		retn

	;--------------------
	; Let the world know that the head of an address chain has changed
	; 
	; Pass:	ax	= MABoxChange with MABC_ADDRESS set
	; 	ss:bp	= stack frame
	; Return:	nothing
	; Destroyed:	ax, dx
	; 
notifyApp:
		push	bp, cx
		movdw	cxdx, ss:[msg]
		mov_tr	bp, ax
		mov	ax, MSG_MA_BOX_CHANGED
		call	UtilSendToMailboxApp
		pop	bp, cx
		retn
OTQChangeAddressMarks endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQAddOneMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a single message to the DBQ for a transmit thread.

CALLED BY:	(INTERNAL) OutboxTransmitMessage,
			   OTQTransmitMessageQueueInternalCallback
PASS:		cx	= DBQ of transmit thread's queue
		dx	= tal ID for messages queued for this thread
		ss:bp	= inherited local frame
				qTalID 	= talID of addresses to be added
				msg	= message to be added
RETURN:		carry set if unable to add to the queue:
			ax	= MailboxError
		carry clear if message queued:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTQAddOneMessage proc	near
qTalID		local	word		; talID of addresses to be added
msg		local	MailboxMessage	; message to be added
		uses	bx, dx, ds, si, di
		.enter	inherit
	;
	; Change the MITA_addrList fields for all messages marked with
	; qTalID to be the talID passed in DX.
	;
	; 3/9/95: used to skip this if dx == qTalID, but we don't any more as
	; we want the notification to be sent, and this is the easiest way to
	; cause it to happen -- ardeb
	; 

		push	cx
		mov	si, dx		; si <- new talID
		movdw	dxax, ss:[msg]	; dxax <- msg to change
		mov	cx, ss:[qTalID]	; cx <- talID for which to look
		mov	bx, (MACT_QUEUED shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		call	OTQChangeAddressMarks
		pop	di		; di <- passed queue

if	_CONFIRM_AFTER_FIRST_FAILURE or _OUTBOX_FEEDBACK
	;
	; If there are other messages queued, we need to let the user know
	; of the delay for this message if it's the first time it's been
	; submitted for transmission.
	;
		call	MailboxGetAdminFile
		call	DBQGetCount
		or	ax, dx
		movdw	dxax, ss:[msg]
		jz	addToQueue
		call	OTQNotifyOfDelayIfFirstTime
addToQueue:
else
		call	MailboxGetAdminFile
		movdw	dxax, ss:[msg]
endif	; _CONFIRM_AFTER_FIRST_FAILURE or _OUTBOX_FEEDBACK

	;
	; Add the thing to the end of the passed queue.
	; Must make sure the message isn't already in the queue (as can happen
	; if the user chooses to send to individual addresses successively,
	; rather than all at once).
	; 
		
		call	DBQCheckMember
		cmc
		jnc	done		; => already there. We say this is a
					;  successful enqueueing of the message.
		call	DBQAdd
		jnc	done
		mov	ax, ME_CANNOT_ENQUEUE_MESSAGE
done:
		.leave
		ret
OTQAddOneMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQNotifyOfDelayIfFirstTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the user know the message is in the outbox if it might
		be a bit before it gets sent.

CALLED BY:	(INTERNAL) OTQAddOneMessage
PASS:		bx	= admin file
		dxax	= message being added
		si	= TalID of affected addresses
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONFIRM_AFTER_FIRST_FAILURE or _OUTBOX_FEEDBACK
OTQNotifyOfDelayIfFirstTime proc	near
		uses	bx, di, cx, bp
		.enter
	;
	; Mark any address with 0 tries with the standard "hang on, dude"
	; reason.
	;
		mov	bp, -1		; no reason stored yet.
if	_CONFIRM_AFTER_FIRST_FAILURE
		push	bx
endif	; _CONFIRM_AFTER_FIRST_FAILURE
		mov	bx, SEGMENT_CS
		mov	di, offset markAddress
		mov	cx, si		; cx <- talID to look for
		call	MessageAddrEnum
if	_CONFIRM_AFTER_FIRST_FAILURE
		pop	bx
		cmp	bp, -1		; anything marked?
		je	done		; no
	;
	; At least one address was marked, so let the application object
	; tell the user about it.
	;
		call	DBQAddRef
		MovMsg	cxdx, dxax
		mov	bp, si
		mov	ax, MSG_MA_OUTBOX_CONFIRMATION
		call	UtilSendToMailboxApp
		MovMsg	dxax, cxdx
done:
endif	; _CONFIRM_AFTER_FIRST_FAILURE
		.leave
		ret
	;--------------------
	; Callback to set the reason for any address just queued with 0 tries
	;
	; Pass:
	; 	cx	= TalID to look for
	; 	bp	= -1 or reason token obtained before
	; 	ds:di	= MailboxInternalTransAddr to check
	; 	*ds:si	= trans addr array
	; 	*ds:bx	= MailboxMessageDesc
	; Return:
	; 	carry set to stop enumerating (always clear)
	; 	bp	= -1 or reason token, if needed to mark something
	; Destroyed:
	; 	nothing

markAddress:
		cmp	ds:[di].MITA_addrList, cx
		jne	markAddressDone
		test	ds:[di].MITA_flags, mask MTF_TRIES
		jnz	markAddressDone
		
		cmp	bp, -1
		jne	haveReason
		
		
		push	cx, dx, ax
		mov	cx, handle uiOutboxSendingAnotherDocument
		mov	dx, offset uiOutboxSendingAnotherDocument
		call	ORStoreReason
		mov_tr	bp, ax
		Assert	ne, bp, -1
		pop	cx, dx, ax
haveReason:
		mov	ds:[di].MITA_reason, bp
			CheckHack <offset MTF_TRIES eq 0>
		inc	ds:[di].MITA_flags
		call	UtilVMDirtyDS
markAddressDone:
		clc
		retf
OTQNotifyOfDelayIfFirstTime endp
endif	; _CONFIRM_AFTER_FIRST_FAILURE or _OUTBOX_FEEDBACK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQEnsureDupsAllMarked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC: Make sure that all the duplicate addresses for a message
		are either marked to be queued, or not marked to be queued.
		
		XXX: IF SOME OF THESE ADDRESSES ARE ALREADY QUEUED, WILL THIS
		GET HOSED BY THE CHANGING OF THOSE ADDRESSES FROM THE QUEUED
		STATE TO THE TRANSMIT STATE BY THE TRANSMIT THREAD?

CALLED BY:	(INTERNAL) OTQAddOneMessage
PASS:		dxax	= MailboxMessage
		cx	= talID for which to check
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
OTQEnsureDupsAllMarked proc	near
if _DUPS_ALWAYS_TOGETHER
		uses	bx, di, dx
		.enter
		mov	bx, SEGMENT_CS
		mov	di, offset callback
		call	MessageAddrEnum
		.leave
		ret

	;--------------------
	; ds:di	= MailboxInternalTransAddr
	; *ds:si = addr array
	; cx = tal ID of addresses being queued
	; -> cx, ax, di = destroyed
	; 
callback:
		mov	dx, cx			; dx = tal ID
	;
	; If the first address is marked MAS_SENT, the skip out of the check, 
	; because subsequent addresses may not have been sent yet, and thus
	; be marked differently. 
	;
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	callbackDone
	;
	; Don't check duplicate addresses, because they will have been 
	; checked (or not checked) along with the main address.
	;
		test	ds:[di].MITA_flags, mask MTF_DUP
		jnz	callbackDone
	;
	; Figure if this address is marked. CX <- 0 if it is, non-z if it's not
	; 
		clr	cx
		mov	ax, ds:[di].MITA_next
		cmp	ds:[di].MITA_addrList, dx
		je	ensureLoop
		dec	cx			; cx <- non-z (1-byte inst)

ensureLoop:
	;
	; If no next duplicate, then check is done.
	; 
		inc	ax
		jz	callbackDone
	;
	; Point to the next duplicate, preserving CX
	; 
		dec	ax
		push	cx
		call	ChunkArrayElementToPtr
		pop	cx
	;
	; Fetch the next duplicate out before the comparison, so looping back
	; is easy.
	; 
		mov	ax, ds:[di].MITA_next
	;
	; Perform the comparison, then use jcxz to get to the right branch.
	; 
		cmp	ds:[di].MITA_addrList, dx
		jcxz	ensureMarked
	    ; initial addr was unmarked, so this one better be, too
		jne	ensureLoop		
honk:
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	ensureLoop	; can be anything it wants if it's been
					;  sent...
		ERROR	ALL_DUPLICATES_NOT_MARKED_THE_SAME

callbackDone:
		mov	cx, dx		; cx <- talID again
		clc			; keep enumerating, please
		retf
ensureMarked:
	    ; initial addr was marked, so this one better be, too
		je	ensureLoop
		jmp	honk
else	; !_DUPS_ALWAYS_TOGETHER
		ret
endif
OTQEnsureDupsAllMarked endp
endif ; ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxTransmitMessageQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Queue all the messages in a single DBQ to be sent to those
		addresses marked with the given talID

CALLED BY:	(EXTERNAL)
PASS:		di	= DBQ (control of the queue passes to this module
			  and queue should not be referenced after the call,
			  unless an error is returned)
		cx	= talID for the addresses to which the message is
			  to be sent (use of the talID is hereby passed
			  to this module; caller should not use it for other
			  addresses)
RETURN:		carry set if message couldn't be queued:
			ax	= MailboxError
			some messages may have been queued successfully. Those
			that have not been queued remain in the passed DBQ
		carry clear if all messages queued:
			ax	= destroyed
			passed DBQ destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxTransmitMessageQueue proc	far
		uses	bx
		.enter
		call	MailboxGetAdminFile
xmitLoop:
		push	cx
		call	OTQGetQueueOfFirstTransport
		jc	doneOK
	;
	; Now submit the entire queue (DI) all of whose members are guaranteed
	; to use the same transport & medium.
	; cx = talID identifying this batch
	;
		call	OTQTransmitMessageQueueInternal
		jc	done
		pop	cx		; cx <- original talID
		jmp	xmitLoop
doneOK:
	;
	; Free the DBQ, please, and return happiness.
	; 
		call	DBQDestroy
		clc
done:
		pop	cx
		.leave
		ret
OutboxTransmitMessageQueue endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxCleanupFailedTransmitQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after a failed OutboxTransmitMessageQueue,
		returning unqueued messages to the outbox.

CALLED BY:	(EXTERNAL)
PASS:		di	= DBQ that was passed to OutboxTransmitMessageQueue
		cx	= talID that was passed to OutboxTransmitMessageQueue
RETURN:		nothing
DESTROYED:	cx
SIDE EFFECTS:	the DBQ is destroyed
     		messages may have their address marks changed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/14/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxCleanupFailedTransmitQueue proc	far
talID		local	word	push cx
		uses	bx, dx
		.enter
		call	MailboxGetAdminFile
		mov	cx, SEGMENT_CS
		mov	dx, offset callback
		call	DBQEnum
		call	DBQDestroy
		.leave
		ret
	;--------------------
	;
	; Find all addresses marked with the talID and set them back to 0
	;
	; Pass:
	; 	sidi	= MailboxMessage
	; 	bx	= admin file
	; 	ss:bp	= inherited frame:
	;		  talID set to id to find
	; Return:
	; 	carry set to stop (always clear)
	;
callback:
		push	ds
		movdw	dxax, sidi
		mov	cx, ss:[talID]
		clr	si		; si <- search from first
addrLoop:
		push	ax		; save msg.low
		call	OUFindNextAddr	; ds:si <- addr, if CF=0
		jc	callbackDone
		mov	ds:[si].MITA_addrList, 0
		mov_tr	si, ax		; si <- addr from which to search
					;  in next iteration
		pop	ax		; dxax <- MailboxMessage
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		jmp	addrLoop
callbackDone:
		pop	ax
		pop	ds
		clc
		retf
OutboxCleanupFailedTransmitQueue endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQGetFirstTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the MailboxTransport for the first message in the
		passed queue.

CALLED BY:	(INTERNAL) OTQCheckAllSameTransport,
			   OTQGetQueueOfFirstTransport,
			   OTQTransmitMessageQueueInternal,
			   OTrMain
PASS:		bx	= VM file (admin file)
		di	= queue
		cx	= talID
		si	= TRUE if need to call OTrDequeue to remove the
			  the message from the queue
RETURN:		carry set if queue is empty:
			ax, bx, cx destroyed
			dx	= 0
		carry clear if have transport:
			cxdx	= MailboxTransport
			bx	= MailboxTransportOption
			ax	= medium ref
DESTROYED:	none
SIDE EFFECTS:	items will be removed from the front of the queue if they have
     			no addresses marked with the given talID

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTQGetFirstTransport proc	far
		.enter
tryAgain:
	;
	; Get the first item in the queue, please.
	; 
		push	cx			;save talID
		clr	cx
		call	DBQGetItemNoRef
		pop	cx			;restore cx = talID
		jc	done		
	;
	; Save a bunch of registers in case we have to remove an item.
	;
		push	dx, ax, bx
	;
	; Retrieve its transport token for comparison against those of the
	; rest of the queue.
	; 
		call	OTQGetTransport	; cxdx <- transport for dxax
					; bx <- transport option
					; ax <- medium ref
		jnc	popAndDone
	;
	; Current first item has no more addresses with the talID, so remove it
	; and try again.
	; 
		pop	dx, ax, bx
		tst	si
		jnz	callDequeue
		call	DBQRemove
		jmp	tryAgain
callDequeue:
		call	OTrDequeue
		jmp	tryAgain
	;
	; Get rid of the stuff we previously pushed
	;
popAndDone:
		add	sp, 3 * size word
		clc
done:
		.leave
		ret
OTQGetFirstTransport endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQGetQueueOfFirstTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all messages that use the same transport as the first
		message from the passed queue, placing them in a new queue.

CALLED BY:	(INTERNAL) OutboxTransmitMessageQueue
PASS:		bx	= VM file
		di	= queue
		cx	= talID of queued addresses
RETURN:		carry set if queue is empty
		carry clear if have messages to submit:
			cx	= talID for relevant addresses
DESTROYED:	nothing
SIDE EFFECTS:	original queue is shortened if it began with messages that
     			had no more marked with the passed talID

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTQGetQueueOfFirstTransport proc near
talID		local	word		push	cx
vmFile		local	word		push	bx
transport	local	MailboxTransport
transOption	local	MailboxTransportOption
mediumRef	local	word
newTalID	local	word
	ForceRef	talID	; OTQGetQueueOfFirstTransportCallback
		uses	ax, bx, si, dx
		.enter
	;
	; Find the transport for the first message, for giving to our callback.
	; Also removes any messages from the front of the queue that have
	; no more addresses marked with the passed talID
	; 
		clr	si			; si <- no need to call
						;  OTrDequeue
		call	OTQGetFirstTransport	;cxdx = transport
						; bx = option
		jc	done			; => queue now empty

		movdw	ss:[transport], cxdx
		mov	ss:[transOption], bx
		mov	ss:[mediumRef], ax
	;
	; Now find those messages in the queue that have the MMD_transport
	; equal to that value. We have to give the addresses that match
	; those of the first selected address of the first message a new
	; talID so we can separate them from the rest of the chaff...
	; 
		call	AdminAllocTALID
		mov	ss:[newTalID], ax
		mov	bx, ss:[vmFile]
		mov	cx, SEGMENT_CS
		mov	dx, offset OTQGetQueueOfFirstTransportCallback
		call	DBQEnum

		mov	cx, ss:[newTalID]
		clc
done:
		.leave
		ret
OTQGetQueueOfFirstTransport endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		 OTQGetQueueOfFirstTransportCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to select those messages that are for the
		same transport/medium as the first address selected from the
		first message.

CALLED BY:	(INTERNAL) OTQGetQueueOfFirstTransport via DBQEnum
PASS:		bx	= admin file
		sidi	= message to check
		ss:bp	= inherited frame
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	si, di
SIDE EFFECTS:	message block is dirtied if any addresses relevant

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTQGetQueueOfFirstTransportCallback proc	far
		uses	dx, ax, cx
		.enter	inherit OTQGetQueueOfFirstTransport
	;
	; Find any and all addresses for this message that use the transport
	; and medium and mark them with the new talID.
	; 
		movdw	dxax, sidi
		mov	bx, SEGMENT_CS
		mov	di, offset checkAndChange
		call	MessageAddrEnum
		clc
		.leave
		ret
		
	;--------------------
	;ds:di = MailboxInternalTransAddr
	;*ds:bx = MailboxMessageDesc
	;cx = number of addresses that are pertinent for this message
	;-> carry set to stop enumerating (always clear)
	;   cx = incremented if address pertinent
	;
checkAndChange:
	;
	; See if it's a marked address, first...
	; 
		mov	ax, ss:[talID]
		cmp	ax, ds:[di].MITA_addrList
		jne	checkDone
	;
	; It's marked: see if it's for the same medium
	; 
		mov	ax, ss:[mediumRef]
		cmp	ax, ds:[di].MITA_medium
		jne	checkDone
	;
	; See if the transport is the same
	; 
		mov	bx, ds:[bx]
		cmpdw	ds:[bx].MMD_transport, ss:[transport], ax
		jne	checkDone
		mov	ax, ds:[bx].MMD_transOption
		cmp	ss:[transOption], ax
		jne	checkDone
	;
	; It is. Change its talID to the new one for this submission and
	; mark the block dirty.
	; 
		mov	ax, ss:[newTalID]
		mov	ds:[di].MITA_addrList, ax
		call	UtilVMDirtyDS
checkDone:
		clc
		retf
OTQGetQueueOfFirstTransportCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQTransmitMessageQueueInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Submit the messages in the passed queue for transmission
		to the marked addresses.

CALLED BY:	(INTERNAL) OutboxTransmitMessageQueue
PASS:		bx	= admin file
		di	= queue of messages to submit. all for one transport
			  and medium
		cx	= tal ID that marks addresses to which messages
			  should be sent (different from talID originally
			  passed to OutboxTransmitMessageQueue)
RETURN:		carry set if couldn't submit messages for transmission:
			ax	= MailboxError
		carry clear if messages submitted:
			ax	= 0
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	this is much like the individual-message case, except the queue can be
		taken over by the transmit thread, if the thread is new,
		else each message must be added one at a time

	- plock data block
	- look for thread for transport driver
	- if found, add all messages to queue, adjusting tal IDs of messages to
	  thread's tal ID
	- if not found:
		- alloc entry in tracking block & set passed dbq as thread's dbq
		- set thread's tal ID to queue's
		- spawn thread
		- store handle
	- release block
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTQTransmitMessageQueueInternal proc	near
qTalID		local	word 	push cx		; for OTQAddOneMessage
msg		local	MailboxMessage		; for OTQAddOneMessage
adminFile	local	word	
msgQ		local	word
destQ		local	word
destID		local	word
	ForceRef	msg
	ForceRef	qTalID
		.enter
		mov	adminFile, bx
		mov	ss:[msgQ], di		; (can't push-initialize as
						;  qTalID and msg must be first
						;  two vars...)
		clr	si			; si <- no need to call
						;  OTrDequeue
		call	OTQGetFirstTransport	; cxdx <- transport
						;  bx <- option
						;  ax <- medium
		mov	si, ss:[qTalID]		; Take over the talID for the
						;  queue, as it was allocated
						;  specially for this batch
						;  of messages.
		call	OTQFindOrCreateThread
		jc	done
	;
	; Transfer each message over to the queue in turn.
	;
	; First, Store the thread's queue and queuedID into local variables for
	; the callback routine to get to.
	; 
		mov	ax, ds:[di].OTD_queuedID
		mov	ss:[destID], ax
		mov	ax, ds:[di].OTD_dbq
		mov	ss:[destQ], ax
	;
	; Now call a callback for each message. The callback will add the
	; message to the thread's queue and adjust the talIDs appropriately.
	;
	; XXX: If there's an error, we'll be saying that some messages
	; haven't been queued, when they might actually have been, since the
	; error might have occurred queueing the 2d or subsequent message.
	; 
		mov	cx, SEGMENT_CS
		mov	dx, offset OTQTransmitMessageQueueInternalCallback
		mov	di, ss:[msgQ]
		mov	bx, ss:[adminFile]
		call	DBQEnum
done:
		call	MainThreadUnlock
		.leave
		ret
OTQTransmitMessageQueueInternal endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTQTransmitMessageQueueInternalCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to queue up a single message from a DBQ
		of messages

CALLED BY:	(INTERNAL) OTQTransmitMessageQueueInternal via DBQEnum
PASS:		bx	= admin file
		sidi	= message to enqueue
		ss:bp	= inherited frame
RETURN:		carry set to stop enumerating:
			ax	= MailboxError
		carry clear to keep going
			ax	= destroyed
DESTROYED:	cx, dx
SIDE EFFECTS:	If successful, message is added to ss:[destQ] and any
     			MITA_addrList fields that are equal to qTalID
			are changed to destID

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTQTransmitMessageQueueInternalCallback proc	far
		.enter	inherit OTQTransmitMessageQueueInternal
		movdw	ss:[msg], sidi
		mov	cx, ss:[destQ]
		mov	dx, ss:[destID]
		call	OTQAddOneMessage
		.leave
		ret
OTQTransmitMessageQueueInternalCallback endp

Outbox		ends
