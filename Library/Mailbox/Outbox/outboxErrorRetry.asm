COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox
FILE:		outboxErrorRetry.asm

AUTHOR:		Allen Yuen, Mar 15, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT OERDelRefAndFreeBlock   Remove one ref from the message and destroy
				the dialog block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/15/95   	Initial revision


DESCRIPTION:
	Code for the OutboxErrorRetryClass dialog.


	$Id: outboxErrorRetry.asm,v 1.1 97/04/05 01:21:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_QUERY_DELETE_AFTER_PERMANENT_ERROR

MailboxClassStructures	segment	resource
	OutboxErrorRetryClass
MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OERSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the message to be displayed in the error retry dialog.

CALLED BY:	MSG_OER_SET_MESSAGE
PASS:		ds:di	= OutboxErrorRetryClass instance data
		ss:bp	= OERSetMessageArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OERSetMessage	method dynamic OutboxErrorRetryClass, 
					MSG_OER_SET_MESSAGE

	movdw	cxdx, ss:[bp].OERSMA_message
	movdw	ds:[di].OERI_message, cxdx
	pushdw	cxdx			; save MailboxMessage
	mov	ax, ss:[bp].OERSMA_delay
	mov	ds:[di].OERI_delay, ax

	;
	; Get reason string.  Put it in our text.
	;
	mov	ax, ss:[bp].OERSMA_reason
	call	OutboxGetReason		; *ds:ax = reason string
	mov	si, offset OutErrorRetryReason	; *ds:si = text object
	mov	cx, ds:[OLMBH_header].LMBH_handle
	mov	dx, ax			; ^lcx:dx = reason string
	mov	ax, '$'			; 3rd argument
	call	UtilReplaceMarkerInTextChunk
	mov_tr	ax, dx
	call	LMemFree		; free reason string
	
	;
	; Get the transport verb for replacing '&' (4th argument)
	;
	popdw	dxax
	pushdw	dxax

	push	ds
	call	MessageLock

	mov	si, ds:[di]
	movdw	cxdx, ds:[si].MMD_transport
	mov	bx, ds:[si].MMD_transOption
	mov	si, ds:[si].MMD_transAddrs

	push	cx
	mov	ax, ss:[bp].OERSMA_addr
	call	ChunkArrayElementToPtr
	mov	ax, ds:[di].MITA_medium
	pop	cx

	call	UtilVMUnlockDS
	pop	ds


	call	OutboxMediaGetTransportVerb
	mov	si, ax
	mov	si, ds:[si]
	clr	cx			; null-terminated
	mov_tr	dx, ax
	call	LocalDowncaseString
	
	mov	cx, ds:[OLMBH_header].LMBH_handle

	mov	si, offset OutErrorRetryReason
	mov	ax, '&'			; 4th argument
	call	UtilReplaceMarkerInTextChunk

	mov_tr	ax, dx
	call	LMemFree
	

	;
	; Use exported routines to fetch the subject and destination
	;
	popdw	cxdx

	mov	bx, ds:[LMBH_handle]
	call	MailboxGetSubjectLMem
	push	ax			; save subject chunk

	mov	ax, ss:[bp].OERSMA_addr	; ax <- addr index
	call	MailboxGetUserTransAddrLMem
	
	;
	; Replace \2 with the destination.
	;
	mov_tr	dx, ax
	mov	cx, bx			; ^lcx:dx <- destination text
	mov	ax, '\2'
	call	UtilReplaceMarkerInTextChunk
	mov_tr	ax, dx
	call	LMemFree
	
	;
	; Replace \1 with the subject.
	;
	pop	dx
	call	UtilReplaceFirstMarkerInTextChunk
	mov_tr	ax, dx
	call	LMemFree
   	
	;
	; Leave reference on the message until user tells us what to do with it
	;
	ret
OERSetMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OERClipString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clip string to passed width

CALLED BY:	OERSetMessage
PASS:		^lcx:dx = lmem chunk containing string
		ax = width to clip to
		*ds:si = text object
RETURN:		^lcx:dx = lmem chunk with clipped string
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OERRetry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Schedules the message displayed to retry transmission later.

CALLED BY:	MSG_OER_RETRY
PASS:		*ds:si	= OutboxErrorRetryClass object
		ds:di	= OutboxErrorRetryClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OERRetry	method dynamic OutboxErrorRetryClass, 
					MSG_OER_RETRY

	pushdw	dssi			; save self

	movdw	dxax, ds:[di].OERI_message
	pushdw	dxax			; for DBQDelRef later
	mov	cx, ds:[di].OERI_delay	; ch = hours, cl = minutes
	call	MessageLock		; *ds:di = MailboxMessageDesc
	jc	cleanUp			; just cleanup if error
	mov	di, ds:[di]

	;
	; Reset the retry count to 1.  There should only be one address so
	; we just use the first one.
	;
	push	cx, di			; save delay and MMD nptr
	mov	si, ds:[di].MMD_transAddrs
EC <	call	ChunkArrayGetCount	; cx = count			>
EC <	Assert	e, cx, 1						>
	clr	ax
	call	ChunkArrayElementToPtr	; ds:di = MailboxInternalTransAddr
	BitClr	ds:[di].MITA_flags, MTF_TRIES	; retry count = 0
		CheckHack <offset MTF_TRIES eq 0>
	inc	ds:[di].MITA_flags	; retry count = 1
	pop	cx, di			; cx = delay, ds:di = MMD

	;
	; Get the new retry time
	;
	call	UtilGetFutureFileDateTime	; dxax = new time
	mov	bx, dx
	mov_tr	si, ax			; bxsi = FileDateAndTime of new time

if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; Change the auto-retry time.
	;
	movdw	ds:[di].MMD_autoRetryTime, bxsi
	BitClr	ds:[di].MMD_flags, MIMF_NOTIFIED_TRANS_WIN_OPEN
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

	;
	; Change the end bound if we have already passed end bound.
	;
	call	TimerGetFileDateTime	; dxax = FileDateAndTime
	cmp	ax, ds:[di].MMD_transWinClose.FDAT_date
	jne	afterCmp
	cmp	dx, ds:[di].MMD_transWinClose.FDAT_time
afterCmp:
if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	jb	setAppTimer
else
	jb	dirty
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

	movdw	ds:[di].MMD_transWinClose, bxsi
	BitClr	ds:[di].MMD_flags, MIMF_NOTIFIED_TRANS_WIN_CLOSE

if	_AUTO_RETRY_AFTER_TEMP_FAILURE
setAppTimer:
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

	;
	; Tell app object about the new bound.
	;
	movdw	dxcx, bxsi		; dxcx = FileDateAndTime
	mov	ax, MSG_MA_START_NEXT_EVENT_TIMER
	call	UtilSendToMailboxApp

if	not _AUTO_RETRY_AFTER_TEMP_FAILURE
dirty:
endif	; not _AUTO_RETRY_AFTER_TEMP_FAILURE
	call	UtilVMDirtyDS
	call	UtilVMUnlockDS		; unlock message

cleanUp:
	popdw	cxdx
	popdw	dssi			; *ds:si = self
	mov	bp, (MACT_EXISTS shl offset MABC_TYPE) or \
			mask MABC_OUTBOX
	mov	ax, MSG_MA_BOX_CHANGED
	clr	di
	call	UtilForceQueueMailboxApp
	MovMsg	dxax, cxdx		; dxax = MailboxMessage
	FALL_THRU OERDelRefAndFreeBlock

OERRetry	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OERDelRefAndFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove one ref from the message and destroy the dialog block.

CALLED BY:	(INTERNAL) OERRetry, OERDeleteMessage
PASS:		dxax	= MailboxMessage
		*ds:si	= OutboxErrorRetryClass object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OERDelRefAndFreeBlock	proc	far
	class	OutboxErrorRetryClass


	;
	; Remove one reference from the message.  The reference was added
	; before this dialog was created.
	;
	call	MailboxGetAdminFile	; ^vbx = admin file
	call	DBQDelRef

	;
	; Destroy the dialog.  We are not on any of the MailboxApp GCN list,
	; hence we can simply send ourselves MSG_GEN_DESTROY_AND_FREE_BLOCK.
	;
	mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
	GOTO	ObjCallInstanceNoLock

OERDelRefAndFreeBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OERDeleteMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the message displayed from the outbox.

CALLED BY:	MSG_OER_DELETE_MESSAGE
PASS:		*ds:si	= OutboxErrorRetryClass object
		ds:di	= OutboxErrorRetryClass instance data
		ds:bx	= OutboxErrorRetryClass object (same as *ds:si)
		es 	= segment of OutboxErrorRetryClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OERDeleteMessage	method dynamic OutboxErrorRetryClass, 
					MSG_OER_DELETE_MESSAGE


	;
	; Delete the message.  We start deleting at the first address since
	; on the Responder (_RESPONDER_BEHAVIOR) the user can only specify one
	; address.
	;
	movdw	dxax, ds:[di].OERI_message
	pushdw	dxax
	clr	bx, cx			; TalID = 0, delete first address.
	call	OUDeleteMessage

	;
	; Do the rest of the cleanup.
	;
	popdw	dxax			; dxax = MailboxMessage
	GOTO	OERDelRefAndFreeBlock

OERDeleteMessage	endm

OutboxUICode	ends

endif	; _QUERY_DELETE_AFTER_PERMANENT_ERROR
