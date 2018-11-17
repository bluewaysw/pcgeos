COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		uiProgressBox.asm

AUTHOR:		Adam de Boor, Nov 23, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/23/94	Initial revision


DESCRIPTION:
	Implementation of MailboxProgressBoxClass
		

	$Id: uiProgressBox.asm,v 1.1 97/04/05 01:19:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource
	MailboxProgressBoxClass
MailboxClassStructures	ends

UIProgressCode	segment	resource

if	MAILBOX_PERSISTENT_PROGRESS_BOXES
UIProgressCodeDerefGen proc near
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
UIProgressCodeDerefGen endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPBSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a progress box, attaching the box to the 
		MailboxApplication object and bringing the box up on screen

CALLED BY:	MSG_MPB_SETUP
PASS:		*ds:si	= MailboxProgressBox object
		ds:di	= MailboxProgressBoxInstance
		ss:bp	= MPBSetupArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	object is added below the mailbox application object and
     			brought on-screen

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MPBSetup	method dynamic MailboxProgressBoxClass, MSG_MPB_SETUP
		.enter
	;
	; Record the thread and generation numbers.
	; 
		mov	ax, ss:[bp].MPBSA_thread
		mov	ds:[di].MPBI_thread, ax
		mov	ax, ss:[bp].MPBSA_gen
		mov	ds:[di].MPBI_gen, ax
	;
	; See if the subclass wants us to mess with the moniker.
	;
		push	bp
		mov	ax, MSG_MPB_GET_MONIKER_STRING
		call	ObjCallInstanceNoLock
		tst	ax
		jz	addToMailboxApp
		call	UtilMangleCopyOfMoniker	; (must be copy of moniker for
						;  outbox progress box, which
						;  can have multiple MPB_SETUP
						;  calls on some platforms)
		call	LMemFree

addToMailboxApp:
	;
	; Add ourselves under the mailbox application. The application object
	; will set us usable, but will not bring us on-screen.
	; 
EC <		clr	bx						>
EC <		call	GeodeGetProcessHandle				>
EC <		cmp	bx, handle 0					>
EC <		ERROR_NE PROGRESS_BOX_NOT_RUN_BY_MAILBOX_THREAD		>

		DerefDI	MailboxProgressBox
		
		mov	bp, ds:[di].MPBI_type
		mov	dx, si
		mov	cx, ds:[LMBH_handle]
		mov	ax, MSG_MA_ADD_PROGRESS_BOX
		call	UserCallApplication
		pop	bp
	;
	; If we're not supposed to be displaying transmission percentage,
	; set the percentage gauge not-usable.
	; 
		tst	ss:[bp].MPBSA_showProgress
		jnz	initiate

		push	si
		DerefDI	MailboxProgressBox
		mov	si, ds:[di].MPBI_progressGauge
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		pop	si

initiate:
	;
	; Finally, bring ourselves on-screen: we've set up all we need to,
	; I believe.
	; 
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
		.leave
		ret
MPBSetup	endm
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPBHideThyself
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the box down.

CALLED BY:	MSG_MPB_HIDE_THYSELF
PASS:		*ds:si	= MailboxProgressBox object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	box be dismissed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MPBHideThyself	method dynamic MailboxProgressBoxClass, MSG_MPB_HIDE_THYSELF
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		GOTO	ObjCallInstanceNoLock
MPBHideThyself	endm
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPBGenGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interceptor to handle clicking the Stop trigger.

CALLED BY:	MSG_GEN_GUP_INTERACTION_COMMAND
PASS:		*ds:si	= MailboxProgressBox object
		ds:di	= MailboxProgressBoxInstance
		cx	= InteractionCommand
RETURN:		carry set if handled
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MPBGenGupInteractionCommand method dynamic MailboxProgressBoxClass, 
				MSG_GEN_GUP_INTERACTION_COMMAND
		cmp	cx, IC_STOP
		je	setCancelFlag
		mov	di, offset MailboxProgressBoxClass
		GOTO	ObjCallSuperNoLock

setCancelFlag:
		mov	ax, MCA_CANCEL_MESSAGE
		clr	cx, dx, bp		; no ack OD to set
		call	MPBSetCancelFlag

	;
	; Signal query handled.
	; 
		stc
		ret
MPBGenGupInteractionCommand endm
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPBSetCancelFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the MailboxCancelAction for this progress box's thread.

CALLED BY:	(INTERNAL) MPBGenGupInteractionCommand,
			   MPBDetachThread
PASS:		ds:di	= MailboxProgressBoxInstance
		ax	= MailboxCancelAction to tell the thread
		cx	= ack ID, if thread should have one
		^ldx:bp	= ack OD, if thread should have one
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds, es, bp
SIDE EFFECTS:	the thread's cancel flag is set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 9/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MPBSetCancelFlag proc	near
		class	MailboxProgressBoxClass
		.enter
	;
	; Make sure the thread's still around and interested by finding its
	; data. This thing could, conceivably, be triggered by something in
	; the queue when the thread exited, and OTExitThread just *sends* us
	; the GEN_REMOVE and META_BLOCK_FREE messages, without waiting around
	; for us to actually go away.
	; 
		mov	si, cx
		push	ax		; save cancel extent
		mov	ax, ds:[di].MPBI_thread
		mov	cx, ds:[di].MPBI_gen
		call	MainThreadFindByHandle
		jc	threadGone	; => thread has exited
		cmp	ds:[di].MTD_gen, cx
		jne	threadGone	; => thread has exited
	;
	; Tell the thread to stop what it's doing.
	;
		mov	cx, si		; cx <- ack ID
		pop	ax		; ax <- cancel action
		call	MainThreadCancel
done:
	;
	; Release the thread data block.
	; 
		call	MainThreadUnlock
		.leave
		ret

threadGone:
		tst	dx
		jz	popToDone	; => no ack needed
	;
	; Generate the needed MSG_META_ACK, since the thread can't do it.
	;
		mov	cx, si		; cx <- ack ID
		movdw	bxsi, dxbp	; ^lbx:si <- ack OD
		mov_tr	dx, ax		; ^ldx:bp <- ack source (^lthread:0)
		clr	bp
		mov	ax, MSG_META_ACK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

popToDone:
		pop	ax		; clear cancel action
		jmp	done
MPBSetCancelFlag endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPBDetachThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell our thread to go away.

CALLED BY:	MSG_OP_DETACH_THREAD
PASS:		*ds:si	= MailboxProgressBox object
		ds:di	= MailboxProgressBoxInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 9/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MPBDetachThread	method dynamic MailboxProgressBoxClass, MSG_MPB_DETACH_THREAD
		.enter
		mov	ax, MCA_CANCEL_ALL
		clr	cx
		mov	dx, handle MailboxApp
		mov	bp, offset MailboxApp
		call	MPBSetCancelFlag
		.leave
		ret
MPBDetachThread	endm
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPBSetProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the progress gauge know what's up

CALLED BY:	MSG_MPB_SET_PROGRESS
PASS:		*ds:si	= MailboxProgressBox object
		ds:di	= MailboxProgressBoxInstance
		ss:bp	= MPBSetProgressArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MPBSetProgress	method dynamic MailboxProgressBoxClass, MSG_MPB_SET_PROGRESS
		mov	si, ds:[di].MPBI_progressGauge
		mov	ax, MSG_MPG_SET_PROGRESS
		GOTO	ObjCallInstanceNoLock
MPBSetProgress	endm
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPBMetaBlockFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the class of the object to be MailboxProgressBox,
		if the current class is external to the Mailbox library, to
		make sure pending messages for this object don't get handled
		by a class that has vanished.

CALLED BY:	MSG_META_BLOCK_FREE
PASS:		*ds:si	= MailboxProgressBox object
		ds:di	= MailboxProgressBoxInstance
		ds:bx	= MailboxProgressBoxBase
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPBMetaBlockFree method dynamic MailboxProgressBoxClass, MSG_META_BLOCK_FREE
	;
	; See if the object class is external to this library.
	;
		mov	di, es
		cmp	ds:[bx].MB_class.segment, di
		mov	di, offset MailboxProgressBoxClass
		je	toSuper
	;
	; It is -- change it to be us, in case the definer is about to vanish
	;
		call	UtilChangeClass
toSuper:
		GOTO	ObjCallSuperNoLock
MPBMetaBlockFree endm

UIProgressCode	ends
