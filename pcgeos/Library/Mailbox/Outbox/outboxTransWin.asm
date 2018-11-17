COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxTransWin.asm

AUTHOR:		Allen Yuen, Jan  3, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/ 3/95   	Initial revision


DESCRIPTION:
	Code to implement outbox transmission window bounds notifications.


	$Id: outboxTransWin.asm,v 1.1 97/04/05 01:21:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Outbox	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxDoEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to process one message in the outbox queue.
		Put up notify dialog boxes when some bounds are reached.

CALLED BY:	(EXTERNAL) MADoNextEvent via DBQEnum
PASS:		sidi	= MailboxMessage
		ss:bp	= inherited stack frame from MADoNextEvent
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	ss:[nextEventTimer] modified

PSEUDO CODE/STRATEGY:
		Process MMD_transWinClose before MMD_transWinOpen, because
		we want to inform the user of the deadline if both start and
		end bounds are reached at the same time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxDoEvent	proc	far
;
; WARNING: These local variables must match those in MADoNextEvent!
;
currentTime	local	FileDateAndTime
nextEventTime	local	FileDateAndTime
	uses	bx,si,di,ds
	.enter inherit			; inherited from MADoNextEvent

	Assert	stackFrame, bp

	mov	dx, si
	mov_tr	ax, di			; dxax = MailboxMessage
	call	MessageLock		; *ds:di = MailboxMessageDesc
	jc	done			; message not valid anymore
	mov	di, ds:[di]

	;
	; Don't inform user of trans win close if we already did.
	;
	test	ds:[di].MMD_flags, mask MIMF_NOTIFIED_TRANS_WIN_CLOSE
	jnz	checkWinOpen

	;
	; See if the deadline is reached
	;
	movdw	cxsi, ds:[di].MMD_transWinClose
	cmp	si, ss:[currentTime].FDAT_date
	jne	cmpDone
	cmp	cx, ss:[currentTime].FDAT_time
cmpDone:
	ja	notCloseYet

	;
	; It's deadline.
	;
	; We still want to set MIMF_NOTIFIED_TRANS_WIN_OPEN even though we're
	; processing a deadline, because we don't want to notify the user
	; of the start bound once we have notified the user of the deadline.
	;
	ornf	ds:[di].MMD_flags, mask MIMF_NOTIFIED_TRANS_WIN_OPEN \
			or mask MIMF_NOTIFIED_TRANS_WIN_CLOSE
	push	bp
	mov	bp, MSG_MA_OUTBOX_NOTIFY_TRANS_WIN_CLOSE
	call	notifyUser
	pop	bp

	jmp	unlockMsg

notCloseYet:
	call	storeNextEventTime

checkWinOpen:
	;
	; Don't inform user of trans win open if we already did.
	;
	test	ds:[di].MMD_flags, mask MIMF_NOTIFIED_TRANS_WIN_OPEN
	jnz	unlockMsg

	;
	; See if it's time to start transmission.
	;
	movdw	cxsi, ds:[di].MMD_transWinOpen

if	_AUTO_RETRY_AFTER_TEMP_FAILURE

	;
	; Fetch the later of MMD_transWinOpen and MMD_autoRetryTime
	;
	cmp	si, ds:[di].MMD_autoRetryTime.FDAT_date
	jne	afterCmpRetryTime
	cmp	cx, ds:[di].MMD_autoRetryTime.FDAT_time
afterCmpRetryTime:
	jae	haveLaterTime
	movdw	cxsi, ds:[di].MMD_autoRetryTime
haveLaterTime:

endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

	cmp	si, ss:[currentTime].FDAT_date
	jne	afterCmpTime
	cmp	cx, ss:[currentTime].FDAT_time
afterCmpTime:
	ja	notOpenYet		; jump if window not open yet

	;
	; Switch the message into the Waiting state by zeroing out the retry
	; time.
	;
if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	movdw	ds:[di].MMD_autoRetryTime, MAILBOX_NOW
	call	UtilVMDirtyDS
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

	;
	; Make sure some medium the message needs is available before we pay
	; attention to the open-window or retry time. If none is available,
	; the next event will get rescheduled when the medium becomes available.
	;
	call	OTWCheckMediumAvailable
	jnc	unlockMsg

	BitSet	ds:[di].MMD_flags, MIMF_NOTIFIED_TRANS_WIN_OPEN
	push	bp
	mov	bp, MSG_MA_OUTBOX_NOTIFY_TRANS_WIN_OPEN
	call	notifyUser
	pop	bp
	jmp	unlockMsg

notOpenYet:
	call	storeNextEventTime

unlockMsg:
	call	UtilVMUnlockDS

done:
	clc

	.leave
	ret



notifyUser	label	near
	;
	; Bound is reached.  We have to put up some notify boxes.  First we
	; have to dismiss any confirm boxes showing the same message.
	;
	call	UtilVMDirtyDS		; because we've just set some MMD_flags
	call	UtilVMUnlockDS		; unlock and lock again later, because
					;  MMD's might move within the VM block
	MovMsg	cxdx, dxax
	mov	ax, MSG_MA_DISMISS_CONFIRM_BOXES
	call	UtilSendToMailboxApp	; will be handled right away since
					;  we're on the same thread

	;
	; Put up a box for each medium.
	;
	call	MessageLockCXDX		; *ds:di = MailboxMessageDesc
	mov	di, ds:[di]
	mov	si, ds:[di].MMD_transAddrs
	mov	bx, cs
	mov	di, offset OutboxDoEventEachAddr
	call	ChunkArrayEnum
	retn



storeNextEventTime	label	near
	;
	; Set the time for the next event timer to be this date/time if it
	; is earlier than pervious ones.
	;
	; cxsi	= FileDateAndTime of event
	;
	cmp	si, ss:[nextEventTime].FDAT_date
	jne	cmpComplete
	cmp	cx, ss:[nextEventTime].FDAT_time
cmpComplete:
	jae	return			; jump if this event is later
	movdw	ss:[nextEventTime], cxsi
return:
	retn



OutboxDoEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTWCheckMediumAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if any of the media needed for sending this message
		are available.

CALLED BY:	(INTERNAL) OutboxDoEvent
PASS:		ds:di	= MailboxMessageDesc
RETURN:		carry set if one of the media is available
DESTROYED:	si
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTWCheckMediumAvailable proc	near
		uses	bx, di, ax, bp, cx, dx
		.enter
		mov	si, ds:[di].MMD_transAddrs
		tst_clc	si
		jz	done
		
		movdw	cxdx, ds:[di].MMD_transport
		mov	bp, ds:[di].MMD_transOption
		segmov	es, ds
		mov	bx, SEGMENT_CS
		mov	di, offset checkAddress
		call	ChunkArrayEnum
done:
		.leave
		ret

checkAddress:
		mov	ax, ds:[di].MITA_medium
		mov	si, bp
		add	di, offset MITA_opaqueLen
		call	OMCheckConnectable
		retf
OTWCheckMediumAvailable endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxDoEventEachAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to process one address of a message.  Put up
		a confirm dialog if the address is not yet handled.

CALLED BY:	(INTERNAL) OutboxDoEvent via ChunkArrayEnum
PASS:		*ds:si	= MailboxInternalTransAddr chunk array
		ds:di	= MailboxInternalTransAddr
		cxdx	= MailboxMessage
		bp	= MSG_MA_OUTBOX_NOTIFY_TRANS_WIN_OPEN/CLOSE
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxDoEventEachAddr	proc	far
	uses	bp
	.enter inherit OutboxDoEvent

	;
	; If this address is already sent or marked with a TalID, do nothing.
	;
		CheckHack <MAS_SENT eq 0>
	test	ds:[di].MITA_flags, mask MTF_STATE
	jz	done
	tst	ds:[di].MITA_addrList
	jnz	done

	;
	; Don't check medium availability if we're dealing with a deadline.
	;
	mov	ax, ds:[di].MITA_medium
	cmp	bp, MSG_MA_OUTBOX_NOTIFY_TRANS_WIN_CLOSE
	je	allocTalID

	;
	; If this medium is not connectable, do nothing.
	;
	push	es, di, cx, dx, si
	segmov	es, ds
	add	di, offset MITA_opaqueLen	; es:di <- size & address

	push	di
	call	MessageLockCXDX		; lock MMD again so we can get
					;  the transport & option
	mov	di, ds:[di]
	movdw	cxdx, ds:[di].MMD_transport
	mov	si, ds:[di].MMD_transOption
	call	UtilVMUnlockDS		; release extra lock
	pop	di

	call	OMCheckConnectable	; CF set if available
	pop	es, di, cx, dx, si
	jnc	done

allocTalID:
	;
	; Mark all addresses with this medium with a new TalID.
	;
	pushdw	cxdx			; save MailboxMessage
	mov_tr	dx, ax			; dx = medium token
	call	AdminAllocTALID		; ax = TalID
	mov_tr	cx, ax			; cx = TalID
		CheckHack <segment ORMessageAddedMarkCallback \
			eq segment @CurSeg>
	mov	bx, cs
	mov	di, offset ORMessageAddedMarkCallback
	call	ChunkArrayEnum

	;
	; Tell app object to put up sendable box.  We need to add 1 ref first.
	;
	call	MailboxGetAdminFile	; bx = admin file
	popdw	dxax			; dxax = MailboxMessage
	call	DBQAddRef
	xchg	bp, cx			; bp = TalID, cx = msg to send to app
	xchg	cx, ax			; ax = msg to send to app, dxcx = 
					;  MailboxMessage
	xchg	cx, dx			; cxdx = MailboxMessage
	clr	di
	call	UtilForceQueueMailboxApp; must force-queue this message so
					;  we're not holding a message locked
					;  when we go to transmit the thing
					;  (which requires grabbing
					;  MainThreads)
	clc

done:
	.leave
	ret
OutboxDoEventEachAddr	endp

Outbox	ends
