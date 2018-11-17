COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox
FILE:		outboxSendableConfirmation.asm

AUTHOR:		Adam de Boor, May 24, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/24/94		Initial revision


DESCRIPTION:
	Implementation of OutboxSendableConfirmationClass
		

	$Id: outboxSendableConfirmation.asm,v 1.1 97/04/05 01:21:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	not _OUTBOX_SEND_WITHOUT_QUERY

MailboxClassStructures	segment	resource
	OutboxSendableConfirmationClass
MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OSCMsndSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the message to be displayed by the box.

CALLED BY:	MSG_MSND_SET_MESSAGE
PASS:		*ds:si	= OutboxSendableConfirmationClass object
		es 	= segment of OutboxSendableConfirmationClass
		ax	= message #
		cxdx	= MailboxMessage w/one extra reference
		bp	= talID
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OSCMsndSetMessage	method dynamic OutboxSendableConfirmationClass, 
					MSG_MSND_SET_MESSAGE

	call	OSCCallSuper

	DerefDI	OutboxSendableConfirmation
	tst	ds:[di].OSCI_useIdleTimeout
	jz	done

	;
	; Start idle timeout timer.
	;
	call	AdminGetAutoDeliveryTimeout	; cx = # of ticks
	mov	bx, ds:[OLMBH_header].LMBH_handle	; ^lbx:si = self
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	dx, MSG_OSC_IDLE_TIMEOUT
	call	TimerStart
	mov	ds:[di].OSCI_idleTimerHandle, bx
	mov	ds:[di].OSCI_idleTimerID, ax

done:
	ret
OSCMsndSetMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OSCMsndGetVerb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the delivery verb for this message and addresses.

CALLED BY:	MSG_MSND_GET_VERB
PASS:		ds:di	= OutboxSendableConfirmationClass instance data
RETURN		ax	= lptr to verb in object block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OSCMsndGetVerb	method dynamic OutboxSendableConfirmationClass, 
					MSG_MSND_GET_VERB
	uses	cx,dx
	.enter

	push	ds			; save obj block
	movdw	dxax, ds:[di].MSNDI_message
	mov	cx, ds:[di].MSNDI_talID
	clr	si			; si <- start w/addr 0
	call	OUFindNextAddr		; *ds:di = MailboxMessageDesc,
					;  ds:si = MailboxInternalTransAddr
EC <	ERROR_C		NO_MESSAGE_ADDRESS_MARKED_WITH_GIVEN_ID		>
	mov	ax, ds:[si].MITA_medium
	mov	di, ds:[di]
	movdw	cxdx, ds:[di].MMD_transport
	mov	bx, ds:[di].MMD_transOption
	call	UtilVMUnlockDS
	pop	ds			; ds = obj block
	call	OutboxMediaGetTransportVerb	; *ds:ax = verb

	.leave
	ret
OSCMsndGetVerb	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OSCMsndSendMessageNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the displayed message now.

CALLED BY:	MSG_MSND_SEND_MESSAGE_NOW
PASS:		*ds:si	= OutboxSendableConfirmationClass object
		ds:di	= OutboxSendableConfirmationClass instance data
		es 	= segment of OutboxSendableConfirmationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OSCMsndSendMessageNow	method dynamic OutboxSendableConfirmationClass, 
					MSG_MSND_SEND_MESSAGE_NOW

	call	OSCStopTimerIfExist	; CF set if timer just stopped
	jnc	done			; jump to ignore this message

	push	ax
	movdw	dxax, ds:[di].MSNDI_message
	mov	cx, ds:[di].MSNDI_talID
	call	OutboxTransmitMessage

	pop	ax
	GOTO	OSCCallSuper
done:
	ret
OSCMsndSendMessageNow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OSCMsndSendMessageLater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't send the message now.

CALLED BY:	MSG_MSND_SEND_MESSAGE_LATER
PASS:		*ds:si	= OutboxSendableConfirmationClass object
		ds:di	= OutboxSendableConfirmationClass instance data
		es 	= segment of OutboxSendableConfirmationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OSCMsndSendMessageLater	method dynamic OutboxSendableConfirmationClass, 
					MSG_MSND_SEND_MESSAGE_LATER

	call	OSCStopTimerIfExist	; CF set if timer just stopped
	jnc	done			; jump to ignore this message

	push	ax			; save MSG_MSND_DELETE_MESSAGE

	;
	; Unmark all addresses with this TalID (ie. with the same medium).
	;
	movdw	dxax, ds:[di].MSNDI_message
	mov	cx, ds:[di].MSNDI_talID
	call	OUUnmarkAddresses

	;
	; Call superclass to do the rest.
	;
	pop	ax			; ax = MSG_MSND_SEND_MESSAGE_LATER
	GOTO	OSCCallSuper

done:
	ret
OSCMsndSendMessageLater	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OSCMsndDeleteMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the displayed message from the outbox.

CALLED BY:	MSG_MSND_DELETE_MESSAGE
PASS:		*ds:si	= OutboxSendableConfirmationClass object
		ds:di	= OutboxSendableConfirmationClass instance data
		es 	= segment of OutboxSendableConfirmationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OSCMsndDeleteMessage	method dynamic OutboxSendableConfirmationClass, 
					MSG_MSND_DELETE_MESSAGE

	call	OSCStopTimerIfExist	; CF set if timer just stopped
	jnc	done			; jump to ignore this message

	push	ax			; save MSG_MSND_DELETE_MESSAGE
	pushdw	dssi			; save self ptr

	;
	; Find the medium of our TalID
	;
	movdw	dxax, ds:[di].MSNDI_message
	pushdw	dxax			; save MailboxMessage
	mov	cx, ds:[di].MSNDI_talID
	clr	si			; start from first address
	call	OUFindNextAddr		; ax = address index, *ds:di = MMD,
					;  ds:si = MailboxInternalTransAddr
EC <	ERROR_C		ERR_NO_MESSAGE_ADDRESS_MARKED_WITH_GIVEN_ID	>

	;
	; Delete these addresses of the message.
	;
	mov_tr	cx, ax			; cx = address
	popdw	dxax			; dxax = MailboxMessage
	clr	bx			; delete all addrs of the same medium
	popdw	dssi			; *ds:si = self
	call	OUDeleteMessage

	;
	; Call superclass to do the rest.
	;
	pop	ax			; ax = MSG_MSND_DELETE_MESSAGE
	GOTO	OSCCallSuper

done:
	ret
OSCMsndDeleteMessage	endm

OSCCallSuper	proc	far
	mov	di, offset OutboxSendableConfirmationClass
	GOTO	ObjCallSuperNoLock
OSCCallSuper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OSCIdleTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The idle timeout timer has expired.  Send the message if there
		has been no user input.

CALLED BY:	MSG_OSC_IDLE_TIMEOUT
PASS:		*ds:si	= OutboxSendableConfirmationClass object
		ds:di	= OutboxSendableConfirmationClass instance data
		ds:bx	= OutboxSendableConfirmationClass object (same as *ds:si)
		es 	= segment of OutboxSendableConfirmationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We don't clear OSC_idleTimerHandle in this routine, so that
	OSCMsndSendMessageNow will know that this is the first time that
	MSG_MSND_SEND_MESSAGE_NOW is called, and will send the message (and
	clear OCS_idleTimerHandle).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OSCIdleTimeout	method dynamic OutboxSendableConfirmationClass, 
					MSG_OSC_IDLE_TIMEOUT

	mov	ax, SGIT_COUNTER_AT_LAST_INPUT
	call	SysGetInfo		; dxax = count at last user input
	mov_tr	cx, ax			; dxcx = count
	call	TimerGetCount		; bxax = current count

	;
	; Calculate the difference.  Even if wrap-around occured in the system
	; counter, subtraction below still yields the correct difference.
	;
	sub	ax, cx			; better not use "subdw"
	sbb	bx, dx			; bxax = difference
	jnz	sendMsg			; jump if bx !=0
	call	AdminGetAutoDeliveryTimeout	; cx = # of ticks
	cmp	ax, cx
	jb	done			; user is there.  Drop timer event.

sendMsg:
	mov	ax, MSG_MSND_SEND_MESSAGE_NOW
	GOTO	ObjCallInstanceNoLock

done:
	ret
OSCIdleTimeout	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OSCStopTimerIfExist
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops any pending timer.  Also determines whether we should
		automatically sends the message.

CALLED BY:	(INTERNAL) OSCMsndSendMessageNow, OSCMsndSendMessageLater,
			OSCMsndDeleteMessage
PASS:		ds:di	= OutboxSendableConfirmationClass instance data
RETURN:		CF set if either timer has just been stopped by this call, or
			we don't use idle timer for this dialog at all.  (See
			below.)
		CF clear if timer was already stopped earlier.
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The idea is that if CF is returned set, the caller should perform it's
	action.  If CF is returned clear, the caller should do nothing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OSCStopTimerIfExist	proc	near
	class	OutboxSendableConfirmationClass
	uses	ax
	.enter

	cmp	ds:[di].OSCI_useIdleTimeout, BB_TRUE	; CF set if BB_FALSE
	jb	done			; "jb" is the same as "jc"

	clr	bx
	xchg	bx, ds:[di].OSCI_idleTimerHandle
	tst_clc	bx
	jz	done			; timer already stopped earlier

	mov	ax, ds:[di].OSCI_idleTimerID
	call	TimerStop
	stc

done:
	.leave
	ret
OSCStopTimerIfExist	endp

OutboxUICode	ends

endif	; not _OUTBOX_SEND_WITHOUT_QUERY
