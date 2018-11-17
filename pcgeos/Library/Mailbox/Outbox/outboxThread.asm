COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox -- Transmit-thread Creation
FILE:		outboxThread.asm

AUTHOR:		Adam de Boor, Apr 29, 1994

ROUTINES:
	Name			Description
	----			-----------
    EXT OTCreateTransmitThread	Create a thread to transmit messages.

    EXT OTFindThread		Find the thread for a particular transport

    INT OTFindThreadCallback	Callback function to locate the thread for
				a transport

    INT OTUnlock		Release the OutboxThreads block

    INT OTCreateQueue		Create a DBQ for a thread.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/29/94		Initial revision


DESCRIPTION:
	
		

	$Id: outboxThread.asm,v 1.1 97/04/05 01:21:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Outbox		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTCreateTransmitThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a thread to transmit messages.

CALLED BY:	(EXTERNAL)
PASS:		ds	= PLocked OutboxThreads block
RETURN:		carry set if couldn't spawn thread
			bx, di	= destroyed
		carry clear if thread spawned:
			bx	= handle of spawned thread
			ds:di	= OutboxThreadData (MTD_thread set)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTCreateTransmitThread proc	near
		uses	cx, ax, dx, bp, si
		.enter
EC <		call	ECMainThreadDSIsThreadData			>
	;
	; First attempt to create the transmit thread.
	; 
		mov	di, OUTBOX_TRANSMIT_STACK_SIZE
		mov	cx, vseg OTrMain
		mov	dx, offset OTrMain
		mov	al, PRIORITY_STANDARD
		mov	bp, handle 0
		call	ThreadCreateVirtual
		jc	done
	;
	; Thread successfully spawned, so contact MainThread to set up an
	; entry for the beastie.
	;
		mov	ax, MTT_TRANSMIT
		mov	cx, size OutboxThreadData
		call	MainThreadCreate
		
	;
	; Allocate a P'd semaphore on which the thread can block when it
	; discovers its medium is no longer available. Must be separate
	; semaphore instead of a queue so MainThreads block can be released
	; before the block.
	;
		push	bx			; save thread handle for return
		clr	bx
		call	ThreadAllocSem
		mov	ax, handle 0		; make it owned by us
		call	HandleModifyOwner	;  so it doesn't vanish
		mov	ds:[di].OTD_mediaSem, bx
		pop	bx
		clc
done:
		.leave
		ret
		assume	ds:nothing
OTCreateTransmitThread endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTFindThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the thread for a particular transport/medium

CALLED BY:	(EXTERNAL) OutboxTransmitMessage, 
			OTQTransmitMessageQueueInternal, 
			OUCheckIfTransmitting
PASS:		cxdx	= MailboxTransport
		bx	= MailboxTransportOption
		ax	= media ref token
RETURN:		ds	= PLocked thread data segment (must call 
			  MainThreadUnlock when done)
		carry set if thread found:
			ds:di	= OutboxThreadData
		carry clear if no thread for transport
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We can accept and compare media reference tokens without
			fear, even though their validity is tied to the
			continuing existence of messages that refer to
			them, because messages are only removed from the
			thread's queue with the OutboxThreads resource
			P'd, and it's only when a message is removed from
			the thread queue that a media element could become
			unreferenced and be nuked, as that's when the message
			descriptor itself could finally be freed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTFindThread	proc	far
transOpt	local	MailboxTransportOption	push bx
mediaToken	local	word			push ax
	ForceRef	transOpt	; OTFindThreadCallback
	ForceRef	mediaToken	; OTFindThreadCallback
		uses	bx, ax, si, bp
		.enter
		mov	bx, SEGMENT_CS
		mov	di, offset OTFindThreadCallback
		call	MainThreadEnum
	;
	; Return offset, if any, in DI. Carry already set properly
	; 
		mov_tr	di, ax
		.leave
		ret
OTFindThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTFindThreadCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate the thread for a transport

CALLED BY:	(INTERNAL) OTFindThread via ChunkArrayEnum
PASS:		*ds:si	= threads array
		ds:di	= OutboxThreadData to check
		ax	= MailboxTransportOption
		cxdx	= MailboxTransport whose thread is sought
		bp	= medium ref token that qualifies the transport...
RETURN:		carry set to stop enumerating:
			ds:ax	= OutboxThreadData for transport
		carry clear to keep looking
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTFindThreadCallback proc	far
		.enter	inherit	OTFindThread
		cmp	ds:[di].MTD_type, MTT_TRANSMIT
		jne	noMatch
ife 	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
		cmpdw	ds:[di].MTD_transport, cxdx
		jne	noMatch
		mov	ax, ss:[transOpt]
		cmp	ds:[di].MTD_transOption, ax
		jne	noMatch
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM
		mov	ax, ss:[mediaToken]
		cmp	ds:[di].OTD_medium, ax
		je	match
noMatch:
		clc
done:
		.leave
		ret
match:
		mov_tr	ax, di
		stc
		jmp	done
OTFindThreadCallback endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTCreateQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a DBQ for a thread.

CALLED BY:	(INTERNAL) OutboxTransmitMessage
PASS:		OutboxThreads block P'd
RETURN:		carry set if couldn't create
			bx, ax	= destroyed
		carry clear if queue created:
			ax	= queue handle
			bx	= VM file
DESTROYED:	nothing
SIDE EFFECTS:	none (yet)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTCreateQueue	proc	far
		uses	dx
		.enter
		call	MailboxGetAdminFile
		mov	dx, DBQ_NO_ADD_ROUTINE
		call	MessageCreateQueue
		.leave
		ret
OTCreateQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTExitThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the thread data for the current thread

CALLED BY:	(EXTERNAL) OTrMain
PASS:		ds:di	= OutboxThreadData for current thread
RETURN:		cx, dx, bp = for caller to return, to be passed to ThreadDestroy
DESTROYED:	ax, bx, cx, dx, si, di, ds
SIDE EFFECTS:	OutboxThreadData deleted
		OutboxThreads resource released
		progress box removed from screen and destruction started
		DBQ for thread destroyed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTExitThread	proc	far
		.enter
EC <		call	ECMainThreadDSIsThreadData			>
EC <   		clr	bx						>
EC <		mov	ax, TGIT_THREAD_HANDLE				>
EC <		call	ThreadGetInfo					>
EC <		cmp	ds:[di].MTD_thread, ax				>
EC <		ERROR_NE	DS_DI_NOT_DATA_FOR_CURRENT_THREAD	>
	;
	; Destroy the thread message queue. We don't care about the talIDs
	; for the messages, as they'll get mangled when next the messages are
	; displayed, since we won't be around...
	; 
   		push	di
		mov	di, ds:[di].OTD_dbq
		call	MailboxGetAdminFile
		call	DBQDestroy
		pop	di
	;
	; Destroy the media-wait semaphore.
	;
		clr	bx
		xchg	ds:[di].OTD_mediaSem, bx
		call	ThreadFreeSem
	;
	; Tell MainThread to nuke the entry and biff the progress box.
	;
		call	MainThreadDestroy	; cx, dx, bp <- ack ID/OD
		.leave
		ret
OTExitThread	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetCancelFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the address of the cancel flag for this thread

CALLED BY:	(GLOBAL)
PASS:		nothing
RETURN:		dx:ax	= far pointer to the word-sized cancel flag
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/94 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetCancelFlag proc	far
		uses	ds, di
		.enter
		call	MainThreadFindCurrentThread
		movdw	dxax, ds:[di].MTD_cancelFlag
		call	MainThreadUnlock
		.leave
		ret
MailboxGetCancelFlag endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxSetCancelAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the action descriptor for the cancel button, in effect,
		for this thread.

CALLED BY:	(GLOBAL)
PASS:		^lbx:si	= destination of message
		ax	= message to send when Stop clicked
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxSetCancelAction proc	far
		uses	ds, di
		.enter
		call	MainThreadFindCurrentThread
		movdw	ds:[di].MTD_cancelAction.AD_OD, bxsi
		mov	ds:[di].MTD_cancelAction.AD_message, ax
		call	MainThreadUnlock
		.leave
		ret
MailboxSetCancelAction endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxThreadCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the transmit thread is able to field the cancel
		indication.

CALLED BY:	(EXTERNAL) MainThreadCancel
PASS:		ds:di	= OutboxThreadData
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, bp, es - may be destroyed

SIDE EFFECTS:	If the thread is blocked, it is awakened.
     		If the thread isn't blocked, it'll spin an extra time
			when next it finds the medium unavailable.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/13/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxThreadCancel proc	far
		.enter
		call	OTMaybeWakeup
		.leave
		ret
OutboxThreadCancel endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMaybeWakeup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wake up a transmission thread that's blocked waiting for
		its medium to become available again.

CALLED BY:	(EXTERNAL) OutboxThreadCancel, 
			   OutboxNotifyMediumAvailable,
			   OutboxNotifyMediumNotConnected
PASS:		ds:di	= OutboxThreadData for thread to wake up
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	OTD_waiting is set FALSE

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/13/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMaybeWakeup	proc	near
		.enter
		clr	bx
		xchg	ds:[di].OTD_waiting, bx
		tst	bx
		jz	done
		mov	bx, ds:[di].OTD_mediaSem
		tst	bx
		jz	done
		call	ThreadVSem
done:
		.leave
		ret
OTMaybeWakeup	endp
Outbox	ends

