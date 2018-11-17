COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxFeedback.asm

AUTHOR:		Adam de Boor, May 24, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/24/95		Initial revision


DESCRIPTION:
	Implementation of the OutboxFeedbackNote class
		

	$Id: outboxFeedbackNote.asm,v 1.1 97/04/05 01:21:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_OUTBOX_FEEDBACK

MailboxClassStructures	segment resource
	OutboxFeedbackNoteClass
MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFNSetDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remember the dialog we need to dismiss when we go away.

CALLED BY:	MSG_OFN_SET_DIALOG
PASS:		*ds:si	= OutboxFeedbackNote object
		ds:di	= OutboxFeedbackNoteInstance
		^lcx:dx	= dialog
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	OFNI_dialog set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFNSetDialog	method dynamic OutboxFeedbackNoteClass, MSG_OFN_SET_DIALOG
		.enter
		movdw	ds:[di].OFNI_dialog, cxdx
		Destroy	ax, cx, dx
		.leave
		ret
OFNSetDialog	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFNSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up to watch for status changes in the passed message.
		And see if we should already be off-screen.

CALLED BY:	MSG_OFN_SET_MESSAGE
PASS:		*ds:si	= OutboxFeedbackNote object
		ds:di	= OutboxFeedbackNoteInstance
		es 	= segment of OutboxFeedbackNoteClass
		cxdx	= MailboxMessage to watch for.  cx = 0 if message
			  couldn't be registered.  cx = -1 if message couldn't
			  be registered but the user shouldn't be notified.
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	box may be dismissed
    		box may be added to the outbox change list on the mailbox
			app object

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFNSetMessage	method dynamic OutboxFeedbackNoteClass, MSG_OFN_SET_MESSAGE
		uses	bp
		.enter

		jcxz	notifyCanceled
		inc	cx
		jz	done			; => don't notify of failure
		dec	cx			; cxdx = MailboxMessage

	;
	; Add ourselves to the GCN list before checking to see if the user has
	; already been notified to handle the case where the message transitions
	; from QUEUED to PREPARING before we get a chance to add ourselves to
	; the list... IC_DISMISS handling will remove us from the list, so
	; we're safe.
	;
		movdw	ds:[di].OFNI_message, cxdx

		mov	ax, MGCNLT_OUTBOX_CHANGE
		call	UtilAddToMailboxGCNListSync
		
		call	OFNCheckAlreadyNotified
		jc	dismiss
		
done:
		.leave
		ret

notifyCanceled:
		mov	bp, offset OFCanceled

changeContents:
		push	si
		push	bp
		mov	si, offset OFProgress
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
		pop	si
		
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		pop	si
	;
	; If user forced us down before, bring ourselves back up.
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
		jmp	done

dismiss:
		push	si
	;
	; If the marker in the text chunk is gone, it means we have been here
	; before and OFInOutbox should already be on-screen.  This can happen
	; if within OUTBOX_CONFIRMATION_DURATION ticks after the message is
	; placed in outbox, it switches to MAS_PREPARING state because the
	; transmission thread has just finished sending other messages.  In
	; such cases we just do nothing and get outta here. --- AY 3/10/96.
	;
		mov	si, offset OFInOutbox
		mov	ax, '\1'
		call	UtilCheckIfMarkerExists	; ZF set if exists
		jz	getReason

		pop	si
		jmp	done

getReason:
	;
	; Get the optr of the reason string for placing in the text object
	;
		pushdw	cxdx
		call	OFNGetReasonOptr
		jc	dismissBox		; => no address marked right, so
						;  we have no idea what reason
						;  to use

	;
	; Replace \1 with the reason.
	;
		call	UtilReplaceFirstMarkerInTextChunk
		mov_tr	ax, dx
		call	LMemFree

	;
	; Extract the subject into our block and replace \2 with it
	;
		popdw	cxdx
		mov	bx, ds:[LMBH_handle]
		call	MailboxGetSubjectLMem
		mov	cx, bx
		mov_tr	dx, ax
		mov	ax, '\2'
		call	UtilReplaceMarkerInTextChunk
		mov_tr	ax, dx
		call	LMemFree
		pop	si

		mov	bp, offset OFInOutbox
		jmp	changeContents

dismissBox:
		popdw	cxdx
		pop	si
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjCallInstanceNoLock

	;
	; Since we're not relying on flashing note mechanism to dismiss us,
	; destroy ourselves ourselves...
	;
		mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
		call	ObjCallInstanceNoLock
		jmp	done
OFNSetMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFNSetSummary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remember the message summary

CALLED BY:	MSG_OFN_SET_SUMMARY
PASS:		*ds:si	= OutboxFeedbackNote object
		ds:di	= OutboxFeedbackNoteInstance
		^lcx:dx	= summary text
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFNSetSummary	method dynamic OutboxFeedbackNoteClass, MSG_OFN_SET_SUMMARY
		.enter
		
		mov	si, offset OutboxFeedbackNoteText
		call	UtilReplaceFirstMarkerInTextChunk

		.leave
		ret
OFNSetSummary	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFNGetReasonOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an address marked with the given talID and fetch its
		failure reason.

CALLED BY:	(INTERNAL) OFNSetMessage
PASS:		ds	= lmem block
		cxdx	= MailboxMessage to examine
RETURN:		carry set if no address marked
			cx, dx	= destroyed
		carry clear if have reason:
			^lcx:dx	= reason string
			ds	= fixed up (cx = ds:[LMBH_handle])
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFNGetReasonOptr proc	near
		.enter
	;
	; Look for an address and fetch its reason.
	;
		MovMsg	dxax, cxdx
		mov	bx, SEGMENT_CS
		mov	di, offset checkAddress
		call	MessageAddrEnum
		cmc
		jc	done
	;
	; Have reason token, so fetch the reason string into our block.
	;
		mov_tr	ax, cx
		call	OutboxGetReason
		mov_tr	dx, ax
		mov	cx, ds:[LMBH_handle]
		clc
done:
		.leave
		ret
	;--------------------
	; Callback to examine an address.
	;
	; Pass:
	; 	ds:di	= MailboxInternalTransAddr to check
	; Return:
	; 	carry set to stop enumerating:
	; 		cx	= reason token for found address
	; 	carry clear to keep looking:
	; 		cx	= preserved
checkAddress:
		test	ds:[di].MITA_flags, mask MTF_TRIES
		jz	checkAddressDone
		mov	cx, ds:[di].MITA_reason
		stc
checkAddressDone:
		retf
OFNGetReasonOptr endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFNCheckAlreadyNotified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the user has already been notified about the passed
		message so there's no need for us to be on-screen

CALLED BY:	OFNSetMessage
PASS:		cxdx	= MailboxMessage we're supposed to be watching
RETURN:		carry set if user already notified
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Look through all the addresses for the message. If any of
		them has a fail count of 1, or a status of SENDING, return
		carry set.
		
		9/19/95: need to run through the outbox to find the message
		because the thing could already have been sent by the time we
		get here. DBQEnum ensures that the thing won't be removed
		from the outbox until we're done, so we can safely mess with
		the addresses (as the message descriptor won't go away until
		it's removed from the outbox), if we find it in our callback.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFNCheckAlreadyNotified proc	near
msg		local	MailboxMessage	push cx, dx
		uses	ax, bx, cx, dx, si, di
		.enter
		call	AdminGetOutbox
		mov	cx, SEGMENT_CS
		mov	dx, offset findMessage
		call	DBQEnum
		cmc
		jc	done			; => message not found, so
						;  already notified
		jcxz	done			; => user not notified
		stc
done:
		.leave
		ret

findMessage:
		clr	cx			; assume not found
		cmpdw	ss:[msg], sidi
		clc
		jne	findMessageDone

		MovMsg	dxax, sidi
		mov	bx, SEGMENT_CS
		mov	di, offset checkAddress
		call	MessageAddrEnum
		sbb	cx, 0			; set CX non-z if notified
		stc				; found msg, so stop enumerating
findMessageDone:
		retf

checkAddress:
		test	ds:[di].MITA_flags, mask MTF_TRIES
		stc
		jnz	checkAddressDone
		cmp	ds:[di].MITA_flags, MAS_PREPARING shl offset MTF_STATE
		cmc		; set carry if AE (is sending)
checkAddressDone:
		retf
OFNCheckAlreadyNotified endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFNGenGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove ourselves from the outbox change list if IC_DISMISS

CALLED BY:	MSG_GEN_GUP_INTERACTION_COMMAND
PASS:		*ds:si	= OutboxFeedbackNote object
		ds:di	= OutboxFeedbackNoteInstance
		cx	= InteractionCommand
RETURN:		carry set if query handled
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFNGenGupInteractionCommand method dynamic OutboxFeedbackNoteClass, 
				MSG_GEN_GUP_INTERACTION_COMMAND
		cmp	cx, IC_DISMISS
		jne	toSuper
		tst	ds:[di].OFNI_dialog.handle
		jz	checkMessage
	;
	; Send the message to the dialog, too, but be sure to only do it
	; once.
	;
		push	si, ax
		clr	bx
		xchg	bx, ds:[di].OFNI_dialog.handle
		mov	si, ds:[di].OFNI_dialog.chunk
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	si, ax
		DerefDI	OutboxFeedbackNote

checkMessage:
		tst	ds:[di].OFNI_message.high
		jz	toSuper

		mov	ax, MGCNLT_OUTBOX_CHANGE
		call	UtilRemoveFromMailboxGCNListSync

		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
toSuper:
		mov	di, offset OutboxFeedbackNoteClass
		GOTO	ObjCallSuperNoLock
OFNGenGupInteractionCommand endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFNMbNotifyBoxChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the message being notified is the one we were brought
		up for, bring ourselves down at the right time.

CALLED BY:	MSG_MB_NOTIFY_BOX_CHANGE
PASS:		*ds:si	= OutboxFeedbackNote object
		ds:di	= OutboxFeedbackNoteInstance
		cxdx	= MailboxMessage affected
		bp	= MABoxChange
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If the change is MACT_PREPARING or MACT_EXISTS, take the
			box down. The former indicates the thing is
			being sent. The latter indicates the user has
			been told the message can't be sent.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFNMbNotifyBoxChange method dynamic OutboxFeedbackNoteClass, 
				MSG_MB_NOTIFY_BOX_CHANGE
		.enter
		cmpdw	ds:[di].OFNI_message, cxdx
		jne	done
		
		andnf	bp, mask MABC_TYPE
		cmp	bp, MACT_EXISTS shl offset MABC_TYPE
		je	takeDown	; => failed
		cmp	bp, MACT_PREPARING shl offset MABC_TYPE
		jne	done
takeDown:
	; XXX: reset our message, which should cause us to see the user's
	; "been notified" and adjust our display accordingly to show the reason
		mov	ax, MSG_OFN_SET_MESSAGE
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
OFNMbNotifyBoxChange endm

OutboxUICode	ends

endif	; _OUTBOX_FEEDBACK
