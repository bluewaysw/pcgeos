COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inboxTransWin.asm

AUTHOR:		Allen Yuen, Jan 11, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/11/95   	Initial revision


DESCRIPTION:
	Code to implement inbox deadline notification.


	$Id: inboxTransWin.asm,v 1.1 97/04/05 01:20:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource
	InboxTransWinCloseClass
MailboxClassStructures	ends

InboxCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxDoEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to process one message in the inbox queue.
		Put up a notify dialog box when the deadline is reached

CALLED BY:	(EXTERNAL) MADoNextEvent via DBQEnum
PASS:		sidi	= MailboxMessage
		ss:bp	= inherited stack frame from MADoNextEvent
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	ss:[nextEventTimer] modified

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxDoEvent	proc	far
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
	; Don't inform user of trans win close if we already did or if the
	; message was already delivered.
	;
	test	ds:[di].MMD_flags, mask MIMF_NOTIFIED_TRANS_WIN_CLOSE \
			or mask MIMF_DELIVERED
	jnz	unlock

	;
	; See if the deadline is reached
	;
	movdw	cxsi, ds:[di].MMD_transWinClose
	cmp	si, ss:[currentTime].FDAT_date
	jne	cmpDone
	cmp	cx, ss:[currentTime].FDAT_time
cmpDone:
	ja	notYet			; jump if not deadline yet

	;
	; It's deadline.  Tell the app to display dialog.  We need to add 1
	; ref first.
	;
	ornf	ds:[di].MMD_flags, mask MIMF_NOTIFIED \
			or mask MIMF_NOTIFIED_TRANS_WIN_CLOSE
	call	UtilVMDirtyDS
	call	MailboxGetAdminFile	; bx = admin file
	call	DBQAddRef
	MovMsg	cxdx, dxax
	mov	ax, MSG_MA_INBOX_NOTIFY_TRANS_WIN_CLOSE
	call	UtilSendToMailboxApp

unlock:
	call	UtilVMUnlockDS
done:
	clc

	.leave
	ret

notYet:
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
	jae	unlock			; jump if this event is later
	movdw	ss:[nextEventTime], cxsi
	jmp	unlock

InboxDoEvent	endp

InboxCode	ends

InboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITWCMsndSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message to be displayed in this dialog.

CALLED BY:	MSG_MSND_SET_MESSAGE
PASS:		*ds:si	= InboxTransWinCloseClass object
		ds:di	= InboxTransWinCloseClass instance data
		ds:bx	= InboxTransWinCloseClass object (same as *ds:si)
		es 	= segment of InboxTransWinCloseClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ITWCMsndSetMessage	method dynamic InboxTransWinCloseClass, 
					MSG_MSND_SET_MESSAGE
	uses	ax, cx, dx, si, es
	.enter

	;
	; Replace the \1 in the template text with the passive verb.
	;
	mov	bx, INBOX_DELIVERY_VERB_PASSIVE
	call	IUGetDeliveryVerbInMessage	; *ds:ax = verb
	mov	si, offset InWinCloseText	; *ds:si = text
	mov	cx, ds:[OLMBH_header].LMBH_handle
	mov	dx, ax			; ^lcx:dx = verb
	call	UtilReplaceFirstMarkerInTextChunk
EC <	segmov	es, cs			; to avoid EC death		>
	call	LMemFree		; free verb

	.leave

	;
	; Call superclass to do the rest.
	;
	mov	di, offset InboxTransWinCloseClass
	GOTO	ObjCallSuperNoLock

ITWCMsndSetMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITWCMsndGetVerb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the delivery verb for this message.

CALLED BY:	MSG_MSND_GET_VERB
PASS:		ds:di	= InboxTransWinCloseClass instance data
RETURN:		ax	= lptr to verb in object block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ITWCMsndGetVerb	method dynamic InboxTransWinCloseClass, 
					MSG_MSND_GET_VERB
	uses	cx,dx
	.enter

	movdw	cxdx, ds:[di].MSNDI_message
	mov	bx, INBOX_DELIVERY_VERB_ACTIVE
	call	IUGetDeliveryVerbInMessage

	.leave
	ret
ITWCMsndGetVerb	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITWCMsndSendMessageNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the displayed message now.

CALLED BY:	MSG_MSND_SEND_MESSAGE_NOW
PASS:		*ds:si	= InboxTransWinCloseClass object
		ds:di	= InboxTransWinCloseClass instance data
		es 	= segment of InboxTransWinCloseClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ITWCMsndSendMessageNow	method dynamic InboxTransWinCloseClass, 
					MSG_MSND_SEND_MESSAGE_NOW

	push	ax, es
	movdw	cxdx, ds:[di].MSNDI_message
	call	IRNotifyDestApp

	pop	ax, es
	mov	di, offset InboxTransWinCloseClass
	GOTO	ObjCallSuperNoLock

ITWCMsndSendMessageNow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITWCMsndDeleteMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the displayed message from the inbox.

CALLED BY:	MSG_MSND_DELETE_MESSAGE
PASS:		*ds:si	= InboxTransWinCloseClass object
		ds:di	= InboxTransWinCloseClass instance data
		es 	= segment of InboxTransWinCloseClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ITWCMsndDeleteMessage	method dynamic InboxTransWinCloseClass, 
					MSG_MSND_DELETE_MESSAGE

	push	ax
	movdw	cxdx, ds:[di].MSNDI_message
	call	IUDeleteMessage

	pop	ax
	mov	di, offset InboxTransWinCloseClass
	GOTO	ObjCallSuperNoLock

ITWCMsndDeleteMessage	endm

InboxUICode	ends
