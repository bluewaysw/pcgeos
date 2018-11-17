COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		messageSendableNotifyDialog.asm

AUTHOR:		Allen Yuen, Jan 12, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/12/95   	Initial revision


DESCRIPTION:
	Code to implement MessageSendableNotifyDialogClass, the base class
	for all sendable message confirmation dialog classes.

	$Id: messageSendableNotifyDialog.asm,v 1.1 97/04/05 01:20:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource
	MessageSendableNotifyDialogClass
MailboxClassStructures	ends

MessageUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNDSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the MailboxMessage to be displayed in this dialog.

CALLED BY:	MSG_MSND_SET_MESSAGE
PASS:		ds:di	= MessageSendableNotifyDialogClass instance data
		ax	= message #
		cxdx	= MailboxMessage w/extra reference
		bp	= TalID of address(es) to display
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	trigger monikers & text object get mangled

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version (from OSCSetMessage)
	AY	1/ 9/95		Moved common code to here

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSNDSetMessage	method dynamic MessageSendableNotifyDialogClass, 
					MSG_MSND_SET_MESSAGE

	;
	; Store the stuff in our instance data for later send or dont-send
	; handling.
	; 
EC <		tst	ds:[di].MSNDI_talID				>
EC <		ERROR_NZ	DUPLICATE_SET_MESSAGE			>
		movdw	ds:[di].MSNDI_message, cxdx
		mov	ds:[di].MSNDI_talID, bp
		push	ds:[di].MSNDI_msgGlyph
	;
	; Fetch the verb for the transport/medium combination. First find an
	; address marked with the talID so we can get the medium
	; 
		pushdw	cxdx			; save MailboxMessage to talk
						;  to glyph
		push	{word} ds:[di].MSNDI_textHasTwoMarkers
		push	ds:[di].MSNDI_notifyText
		push	ds:[di].MSNDI_laterTrigger
		push	ds:[di].MSNDI_nowTrigger

			CheckHack <MSG_MSND_SET_MESSAGE + 1 \
				eq MSG_MSND_GET_VERB>
		inc	ax		; ax = MSG_MSND_GET_VERB
		call	ObjCallInstanceNoLock	; *ds:ax = verb
	;
	; *ds:ax = the verb to use. We now need to mangle the monikers for the
	; two triggers.
	; 
		pop	si			; *ds:si = nowTrigger
		Assert	objectPtr, dssi, GenClass
		call	UtilMangleMoniker
		pop	si			; *ds:si = laterTrigger
		Assert	objectPtr, dssi, GenClass
		call	UtilMangleMoniker
	;
	; Downcase the entire verb for use in the explanatory text.
	; 
		mov	si, ax
		mov_tr	dx, ax
		mov	si, ds:[si]
		clr	cx			; cx <- string is null-
						;  terminated
		call	LocalDowncaseString
	;
	; Replace the two \1 markers in the template text chunk with the
	; downcased verb.
	; 
		mov	cx, ds:[LMBH_handle]	; ^lcx:dx ,- verb
		pop	si			; *ds:si = notifyText
		pop	bx			; bl = textHasTwoMarkers bool
		tst	si
		jz	allMarkersReplaced	; jump if null
		Assert	objectPtr, dssi, GenTextClass
		call	UtilReplaceFirstMarkerInTextChunk
		tst	bl
		jz	allMarkersReplaced
		call	UtilReplaceFirstMarkerInTextChunk
allMarkersReplaced:
	;
	; Free the verb chunk.
	; 
		mov_tr	ax, dx
		call	LMemFree
	;
	; Add another reference to the message, which will be removed by the
	; glyph. We keep a reference to the message until the user tells us
	; what to do with it.
	; 
		popdw	dxax
		call	MailboxGetAdminFile
		call	DBQAddRef
	;
	; Tell the glyph to display the message.
	; 
		xchg	ax, dx			; ax <- msg.high, dx <- msg.low
		mov_tr	cx, ax			; cx <- msg.high
		mov	ax, MSG_MG_SET_MESSAGE_ALL_VIEW
		pop	si			; *ds:si = MessageGlyph object
		Assert	objectPtr, dssi, MessageGlyphClass
		GOTO	ObjCallInstanceNoLock

MSNDSetMessage	endm

if ERROR_CHECK
;
; This message must be intercepted by our subclasses.
;
MSNDError	method	dynamic	MessageSendableNotifyDialogClass,
							MSG_MSND_GET_VERB

		ERROR	-1

MSNDError	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNDSendMessageLater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't send the message now.  Adjusts the deadline (if
		applicable).

CALLED BY:	MSG_MSND_SEND_MESSAGE_LATER
PASS:		*ds:si	= MessageSendableNotifyDialogClass object
		ds:di	= MessageSendableNotifyDialogClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	
	if MSND_dealyHour and MSND_delayMinute exist
		delay the message deadline
		tell app object about the new deadline

	fall-thru to MSNDDestroyDialogCommon to do the cleanup

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSNDSendMessageLater	method dynamic MessageSendableNotifyDialogClass, 
					MSG_MSND_SEND_MESSAGE_LATER

	push	si			; save self ptr
	mov	si, ds:[di].MSNDI_delayMinute
	tst	si
	LONG jz	cleanUp			; jump if no delay
	pushdw	ds:[di].MSNDI_message

	;
	; Get the new deadline.
	;
	Assert	objectPtr, dssi, GenValueClass
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	push	ax
	push	ds:[di].MSNDI_delayHour
	call	ObjCallInstanceNoLock	; dl = minute
	Assert	e, dh, 0

	pop	si			; *ds:si = delayHour
	Assert	objectPtr, dssi, GenValueClass
	pop	ax			; ax = MSG_GEN_VALUE_GET_VALUE
	push	dx			; save minute
	call	ObjCallInstanceNoLock	; dl = hour
	Assert	e, dh, 0
	pop	cx			; cl = minute
	mov	ch, dl			; ch = hour

	call	UtilGetFutureFileDateTime	; dxax = FileDateAndTime
	mov	bx, dx			; bxax = FileDateAndTime

	;
	; Store new deadline, clear MIMF_NOTIFIED_TRANS_WIN_CLOSE so that we
	; will notify the user when the new deadline is reached.
	;
	popdw	cxdx			; cxdx = MailboxMessage
	push	ds			; save self sptr
	call	MessageLockCXDX		; *ds:di = MailboxMessageDesc
	mov	di, ds:[di]
	movdw	ds:[di].MMD_transWinClose, bxax
	BitClr	ds:[di].MMD_flags, MIMF_NOTIFIED_TRANS_WIN_CLOSE
	call	UtilVMDirtyDS
	call	UtilVMUnlockDS

	;
	; Tell app about the new deadline.
	;
	mov	dx, bx
	mov_tr	cx, ax			; dxcx = FileDateAndTime
	mov	ax, MSG_MA_START_NEXT_EVENT_TIMER
	call	UtilSendToMailboxApp

	pop	ds			; ds = self sptr

cleanUp:
	;
	; Cleanup work.
	;
	pop	si			; *ds:si = self
	DerefDI	MessageSendableNotifyDialog
	FALL_THRU MSNDDestroyDialogCommon

MSNDSendMessageLater	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNDDestroyDialogCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the dialog after removing 1 ref from the message.

CALLED BY:	MSG_MSND_SEND_MESSAGE_NOW, MSG_MSND_DELETE_MESSAGE,
		FALL_THRU'ed from MSNDSendMessageLater
PASS:		*ds:si	= MessageSendableNotifyDialogClass object
		ds:di	= MessageSendableNotifyDialogClass instance data
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSNDDestroyDialogCommon	method MessageSendableNotifyDialogClass, 
					MSG_MSND_SEND_MESSAGE_NOW,
					MSG_MSND_DELETE_MESSAGE

	;
	; Remove the reference we left on the message.
	; 
		movdw	dxax, ds:[di].MSNDI_message
		call	MailboxGetAdminFile	; ^vbx = admin file
		call	DBQDelRef
	;
	; Get the application to do the work of destroying us, thanks.
	; 
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	ax, MSG_MA_DESTROY_DIALOG
		GOTO	UserCallApplication

MSNDDestroyDialogCommon	endm

MessageUICode	ends
