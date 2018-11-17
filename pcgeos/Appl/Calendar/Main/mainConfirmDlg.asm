COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Calendar\Main
FILE:		mainConfirmDlg.asm

AUTHOR:		Jason Ho, Dec 11, 1996

METHODS:
	Name				Description
	----				-----------
	MSG_CALENDAR_CONFIRM_DLG_CANCEL_NEW_EVENT
				User presses Cancel to a received
				event. Confirm and close the dialog.
	MSG_CALENDAR_CONFIRM_DLG_SET_FLAGS
				Set / clear CCDI_flags.
	MSG_META_FUP_KBD_CHAR	Ignore all help request on this
				dialog, because help will close us,
				pretty unexpecting for user.
	MSG_VIS_CLOSE		When closing, destroy and free the
				whole block.

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		12/11/96   	Initial revision


DESCRIPTION:
	Code for CalendarConfirmDlgClass.
		

	$Id: mainConfirmDlg.asm,v 1.1 97/04/04 14:48:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HANDLE_MAILBOX_MSG

	;
	; There must be an instance of every class in a resource.
	;
idata		segment
	CalendarConfirmDlgClass
idata		ends

MailboxCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarConfirmDlgCancelNewEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User presses Cancel to a received event. Confirm and
		close the dialog.

CALLED BY:	MSG_CALENDAR_CONFIRM_DLG_CANCEL_NEW_EVENT
PASS:		*ds:si	= CalendarConfirmDlgClass object
		ds:di	= CalendarConfirmDlgClass instance data
		ds:bx	= CalendarConfirmDlgClass object (same as *ds:si)
		es 	= segment of CalendarConfirmDlgClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarConfirmDlgCancelNewEvent method dynamic CalendarConfirmDlgClass, 
				MSG_CALENDAR_CONFIRM_DLG_CANCEL_NEW_EVENT
		.enter
	;
	; Confirm with a dialog.
	;
	; Couldn't use FoamDisplayQuestion because the current dialog
	; ConfirmEventDialog is sysModal. Foam question dialog would
	; not come above it.
	;
		sub	sp, size FoamStandardDialogOptrParams
		mov	bp, sp
		mov	ss:[bp].FSDOP_customFlags, \
				FoamCustomDialogBoxFlags <1, CDT_QUESTION, \
						   	  GIT_AFFIRMATION, 0>
		mov	cx, handle ConfirmCancelNewEventText
		mov	dx, offset ConfirmCancelNewEventText
		movdw	ss:[bp].FSDOP_bodyText, cxdx
		clr	ax			;none of these are passed
		mov	ss:[bp].FSDOP_titleText.handle, ax
		mov	ss:[bp].FSDOP_titleIconBitmap.handle, ax
		mov	ss:[bp].FSDOP_triggerTopText.handle, ax
		mov	ss:[bp].FSDOP_stringArg1.segment, ax
		mov	ss:[bp].FSDOP_stringArg2.segment, ax
		mov	ss:[bp].FSDOP_helpContext.segment, ax
		mov	ss:[bp].FSDOP_layerPriority, al
		call    FoamStandardDialogOptr  	; pass params on stack
							; ax <-
							; InteractionCommand 
	;
	; Did user press YES?
	;
		cmp	ax, IC_YES
		jne	quit
	;
	; Take away the dialog.
	;
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	cx, IC_DISMISS
		call	ObjCallInstanceNoLock
quit:
		.leave
		ret
CalendarConfirmDlgCancelNewEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarConfirmDlgSetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set / clear CCDI_flags.

CALLED BY:	MSG_CALENDAR_CONFIRM_DLG_SET_FLAGS
PASS:		*ds:si	= CalendarConfirmDlgClass object
		ds:di	= CalendarConfirmDlgClass instance data
		ds:bx	= CalendarConfirmDlgClass object (same as *ds:si)
		es 	= segment of CalendarConfirmDlgClass
		ax	= message #
		cl	= ConfirmDlgFlags to set
		ch	= ConfirmDlgFlags to clear
RETURN:		nothing
DESTROYED:	cx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarConfirmDlgSetFlags	method dynamic CalendarConfirmDlgClass, 
					MSG_CALENDAR_CONFIRM_DLG_SET_FLAGS
		.enter
		Assert	record, cl, ConfirmDlgFlags
		Assert	record, ch, ConfirmDlgFlags
	;
	; Set flags.
	;
		ornf	ds:[di].CCDI_flags, cl
	;
	; Clear flags.
	;
		not	ch
		andnf	ds:[di].CCDI_flags, ch
		
		.leave
		ret
CalendarConfirmDlgSetFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarConfirmDlgMetaFupChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore all help request on this dialog, because help
		will close us, pretty unexpecting for user.

CALLED BY:	MSG_META_FUP_KBD_CHAR
PASS:		*ds:si	= CalendarConfirmDlgClass object
		ds:di	= CalendarConfirmDlgClass instance data
		ds:bx	= CalendarConfirmDlgClass object (same as *ds:si)
		es 	= segment of CalendarConfirmDlgClass
		ax	= message #
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high	= scan code
RETURN:		carry set if character was handled by someone (and should
		not be used elsewhere).
DESTROYED:	?
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/24/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarConfirmDlgMetaFupChar	method dynamic \
					CalendarConfirmDlgClass, 
					MSG_META_FUP_KBD_CHAR
	;
	; must be 1st press or repeated press
	;
		test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
		jz	callSuper
	;
	; If help is pressed, don't call super class it.
	;
		cmp	cx, RUDY_HELP_CHAR
		je	quit
	;
	; Do we have GenView associated with us?
	;
		test	ds:[di].CCDI_flags, mask CDF_HAS_GEN_VIEW
		jz	callSuper
	;
	; If down, send MSG_GEN_VIEW_SCROLL_DOWN to GenView
	;
SBCS <		cmp	cx, VC_DOWN or (CS_CONTROL shl 8)		>
DBCS <		cmp	cx, C_SYS_DOWN					>
		mov	ax, MSG_GEN_VIEW_SCROLL_DOWN
		je	sendToView
	;
	; If page-down, send MSG_GEN_VIEW_SCROLL_PAGE_DOWN to GenView
	;
SBCS <		cmp	cx, VC_NEXT or (CS_CONTROL shl 8)		>
DBCS <		cmp	cx, C_SYS_NEXT					>
	;	mov	ax, MSG_GEN_VIEW_SCROLL_PAGE_DOWN
		je	sendToView
	;
	; If up, send MSG_GEN_VIEW_SCROLL_UP to GenView
	;
SBCS <		cmp	cx, VC_UP or (CS_CONTROL shl 8)			>
DBCS <		cmp	cx, C_SYS_UP					>
		mov	ax, MSG_GEN_VIEW_SCROLL_UP
		je	sendToView
	;
	; If page-up, send MSG_GEN_VIEW_SCROLL_PAGE_UP to GenView
	;
SBCS <		cmp	cx, VC_PREVIOUS or (CS_CONTROL shl 8)		>
DBCS <		cmp	cx, C_SYS_PREVIOUS				>
	;	mov	ax, MSG_GEN_VIEW_SCROLL_PAGE_UP
		jne	callSuper

sendToView:
		mov	si, offset EventsListView
		call	ObjCallInstanceNoLock
quit:		
		stc					; consider handled
		ret
callSuper:
		mov	ax, MSG_META_FUP_KBD_CHAR
		mov	di, offset CalendarConfirmDlgClass
		GOTO	ObjCallSuperNoLock
CalendarConfirmDlgMetaFupChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarConfirmDlgVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When closing, destroy and free the whole block.

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= CalendarConfirmDlgClass object
		ds:di	= CalendarConfirmDlgClass instance data
		ds:bx	= CalendarConfirmDlgClass object (same as *ds:si)
		es 	= segment of CalendarConfirmDlgClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/12/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarConfirmDlgVisClose	method dynamic CalendarConfirmDlgClass, 
					MSG_VIS_CLOSE
		.enter
	;
	; Call super first.
	;
		mov	di, offset CalendarConfirmDlgClass
		call	ObjCallSuperNoLock
	;
	; Destroy the whole block, by sending a message to the top
	; most object in the block.
	;
		CheckHack<offset ConfirmDlgsInteraction eq \
			  offset ForcedDlgsInteraction>
		mov	bx, ds:[LMBH_handle]
		mov	si, offset ConfirmDlgsInteraction
		mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		
		.leave
		ret
CalendarConfirmDlgVisClose	endm

MailboxCode	ends

endif	; HANDLE_MAILBOX_MSG
