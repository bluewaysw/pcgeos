COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userQuick.asm

ROUTINES:
	Name			Description
	----			-----------
GLB	ClipboardStartQuickTransfer
GLB	ClipboardGetQuickTransferStatus
GLB	ClipboardSetQuickTransferFeedback
GLB	ClipboardEndQuickTransfer
GLB	ClipboardAbortQuickTransfer
GLB	ClipboardClearQuickTransferNotification

GLB	ClipboardHandleEndMoveCopy


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/91		Initial version (broken out of Flow object)

DESCRIPTION:
	This file contains routines for quick-transfer.
	
	$Id: userQuick.asm,v 1.1 97/04/07 11:45:57 newdeal Exp $

-------------------------------------------------------------------------------@

idata segment

quickTransferFlags		ClipboardQuickTransferFlags	;init to zeros
quickTransferRegionStrategy	dword
quickTransferNotifyOD		optr
quickTransferSem		Semaphore <1,0>

idata ends

;---

TransferCommon segment resource

PQuickTransfer	proc	far
	call	TransferCommon_DS_DGroup
	PSem	ds, quickTransferSem
	ret
PQuickTransfer	endp

VQuickTransfer	proc	far
	pushf
	VSem	ds, quickTransferSem
	popf
	ret
VQuickTransfer	endp
;
; pass:
;	ds - dgroup
;	quickTransfer semaphore
; return:
;	nothing
; destroy:
;	nothing
;
QTClearQuickTransfer	proc	far
	uses	ax, bp
	.enter
EC <	push	bx							>
EC <	mov	bx, ds							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
EC <	pop	bx							>
	;
	; clear quick-transfer cursor
	;
	call	QTClearCursor
	;
	; clear the current quick-transfer item
	;
	clr	ax				; clear quick-transfer item
	mov	bp, mask CIF_QUICK
	call	ClipboardRegisterItem
	;
	; clear quick-transfer flags
	;
	clr	ds:[quickTransferFlags]
	.leave
	ret
QTClearQuickTransfer	endp

;
; pass:
;	ds - dgroup
;	quickTransfer semaphore
; return:
;	nothing
; destroy:
;	nothing
;
QTClearCursor	proc	far
	uses	ax, bx, cx, dx, si, di, ds, bp
	.enter
EC <	mov	bx, ds							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
	;
	; clear quick-transfer cursor
	;
	mov	ax, CQTF_CLEAR_DEFAULT		; clear both, in case object
	call	QuickTransferSetCursor		;	doesn't get a chance to
	mov	ax, CQTF_CLEAR
	call	QuickTransferSetCursor
	;
	; clear region, if needed
	;
	test	ds:[quickTransferFlags], mask CQTF_USE_REGION
	jz	done				; nope
	;
	; stop XOR region
	;
	mov	di, DR_VID_CLEAR_XOR	; (ret: ax, bx, cx, dx, si, di, bp)
	call	ds:[quickTransferRegionStrategy]
done:
	.leave
	ret
QTClearCursor	endp
;
; pass:
;	ax - ClipboardQuickTransferFeedback
;	bp high - UIFunctionsActive
;	quickTransfer semaphore
; return:
;	nothing
; destroy:
;	nothing
;
QuickTransferSetCursor	proc	far
	uses	ax, cx, dx, bp, si, di, ds, es
	.enter

EC <	push	ax, bx							>
EC <	mov	bx, ds							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
EC <	pop	ax, bx							>
EC <	cmp	ax, ClipboardQuickTransferFeedback			>
EC <	ERROR_AE	BAD_QUICK_TRANSFER_CURSOR			>

	cmp	ax, CQTF_MOVE
	je	haveMoveCopy
	cmp	ax, CQTF_COPY
	jne	haveMode
haveMoveCopy:
	test	ds:[quickTransferFlags], mask CQTF_COPY_ONLY	; copy only?
	jnz	forceCopy			; yes -> force copy
	test	bp, mask UIFA_MOVE shl 8	; user force move?
	jz	notForceMove			; nope, check force-copy
	mov	ax, CQTF_MOVE			; else, force move
						; fall-thru
						; (if force copy also, copy
						;  has precedence)
notForceMove:
	test	bp, mask UIFA_COPY shl 8	; user force copy?
	jz	haveMode			; nope, have mode
forceCopy:
	mov	ax, CQTF_COPY			; else, force copy
haveMode:
	test	ds:[quickTransferFlags], mask CQTF_IN_PROGRESS
							; don't set cursor
	jz	done					;	if not doing
							;	quick-transfer
	push	ax				; save ClipboardQuickTransferFeedback
	shl	ax, 1				; convert to word index
	mov	si, ax
	mov	bp, cs:[FSQTClevel][si]
	mov	cx, cs:[FSQTChandle][si]
	mov	dx, cs:[FSQTCoffset][si]
	call	ImSetPtrImage
	;
	; send notification of default move/copy behavior to source
	;
	pop	bp				; bp = ClipboardQuickTransferFeedback
	mov	ax, MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_FEEDBACK
	call	SendToQTSource			; (pass ds - dgroup)
done:
	.leave
	ret
QuickTransferSetCursor	endp

.assert (PIL_3 eq PIL_FLOW+1)

;
; order depends on ClipboardQuickTransferFeedback enum
;
FSQTClevel	label	word
	word	PIL_3				; CQTF_SET_DEFAULT
	word	PIL_3				; CQTF_CLEAR_DEFAULT
	word	PIL_FLOW			; CQTF_MOVE
	word	PIL_FLOW			; CQTF_COPY
	word	PIL_FLOW			; CQTF_CLEAR
FSQTChandle	label	word
	word	handle pDefaultMoveCopy	; CQTF_SET_DEFAULT
	word	0				; CQTF_CLEAR_DEFAULT
	word	handle pMove			; CQTF_MOVE
	word	handle pCopy			; CQTF_COPY
	word	0				; CQTF_CLEAR
FSQTCoffset	label	word
	word	offset pDefaultMoveCopy		; CQTF_SET_DEFAULT
	word	0				; CQTF_CLEAR_DEFAULT
	word	offset pMove			; CQTF_MOVE
	word	offset pCopy			; CQTF_COPY
	word	0				; CQTF_CLEAR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardAbortQuickTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	abort a quick-transfer - used if quick-transfer source
		object is about to be destroyed or if error occurs trying
		to register a quick-transfer item

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardAbortQuickTransfer	proc	far
	uses	ds
	.enter
	call	PQuickTransfer			; ds = dgroup
	;
	; clear cursor, clear quick-transfer item, clear quick-transfer flag
	;
	call	QTClearQuickTransfer
	call	VQuickTransfer
	.leave
	ret
ClipboardAbortQuickTransfer	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ClipboardClearQuickTransferNotification

DESCRIPTION:	Remove quick-transfer OD notification as it is going
		away.

CALLED BY:	GLOBAL

PASS:
	bx:di - notification OD to remove

RETURN:

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/91		Updated for 2.0 quick-transfer

------------------------------------------------------------------------------@


ClipboardClearQuickTransferNotification	proc	far	uses ax, ds
	.enter
	call	PQuickTransfer			; ds = dgroup
					; make sure that the correct OD
					;	gets cleared
	cmp	ds:[quickTransferNotifyOD].handle, bx
	jne	done
	cmp	ds:[quickTransferNotifyOD].chunk, di
	jne	done
	clr	ax
	mov	ds:[quickTransferNotifyOD].handle, ax
	mov	ds:[quickTransferNotifyOD].chunk, ax
done:
	call	VQuickTransfer
	.leave
	ret

ClipboardClearQuickTransferNotification	endp


TransferCommon ends

;---

Transfer	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ClipboardStartQuickTransfer

DESCRIPTION:	Initiate a quick transfer (normally called from
		MSG_META_START_MOVE_COPY

CALLED BY:	GLOBAL

PASS:
	si - ClipboardQuickTransferFlags
		mask CQTF_COPY_ONLY - if source only supports copying
		mask CQTF_USE_REGION - region passed as QT cursor
		mask CQTF_NOTIFICATION - if source wants notification when
						quick-transfer item is
						accepted by destination

	ax - initial cursor (CQTF_MOVE or CQTF_COPY)
		= -1 if default cursor desired (i.e. object is quick-transfer
			source but not a quick-transfer destination)

	if CQTF_USE_REGION:
		cx, dx - mouse position in SCREEN coordinates
		on stack:
			ClipboardQuickTransferRegionInfo	struct
				CQTRI_paramAX	word
				CQTRI_paramBX	word
				CQTRI_paramCX	word
				CQTRI_paramDX	word
				CQTRI_regionPos	Point
				CQTRI_strategy	dword
				CQTRI_region	dword
			ClipboardQuickTransferRegionInfo	ends
		(CQTRI_region *cannot* be pointing to the movable XIP code
			 resource.)
		NOTE: CQTRI_region must be in a block that is in memory
			already (see VidSetXOR)

	if CQTF_NOTIFICATION:
		bx:di - OD to receive MSG_NOTIFY_QUICK_TRANSFER_{MOVE,COPY}
			and MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_FEEDBACK
		

RETURN:
	carry clear if UI part of quick transfer begun
	carry set if quick-transfer already in progress

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	brianc	3/91		Updated for 2.0 quick-transfer

------------------------------------------------------------------------------@


ClipboardStartQuickTransfer	proc	far

	; if these are changed, make sure to change code below that
	; points bp to passed structure

	push	ax, bx, cx, dx, di, si, bp, ds	; don't use uses since it gives
						;  different results depending
						;  on whether .186 is on or not

	call	PQuickTransfer			; ds  = dgroup

	mov	bp, sp
	add	bp, (16+4)	; return addresses plus 8 words pushed on
				;	stack above SQRS structure

EC <	test	si, not ClipboardQuickTransferFlags				>
EC <	ERROR_NZ	BAD_FLOW_QUICK_TRANSFER_FLAGS			>

	;
	; check if a quick-transfer is already in progress, if so, return
	; error
	;
	test	ds:[quickTransferFlags], mask CQTF_IN_PROGRESS
	stc					; assume so
	LONG	jnz	done			; yes, exit with error

	push	ax				; save ClipboardQuickTransferFeedback

	;
	; save notification OD, if any
	;
	clr	ax
	mov	ds:[quickTransferNotifyOD].handle, ax	; clear, in case none
	mov	ds:[quickTransferNotifyOD].chunk, ax
	test	si, mask CQTF_NOTIFICATION	; notification desired?
	jz	noNotify
	mov	ds:[quickTransferNotifyOD].handle, bx
	mov	ds:[quickTransferNotifyOD].chunk, di
noNotify:

	;
	; set copy-only flag
	;
;still clear from above
;	clr	ax				; base quick transfer flags
	test	si, mask CQTF_COPY_ONLY		; copy only?
	jz	haveBaseFlags			; nope
	ornf	ax, mask CQTF_COPY_ONLY
haveBaseFlags:
	mov	ds:[quickTransferFlags], ax

	;
	; first, set region, if needed
	;
	test	si, mask CQTF_USE_REGION		; using region?
	jz	setCursor			; nope
	;
	; use region for Quick Transfer cursor
	;	cx, dx - mouse position from MSG_META_START_MOVE_COPY
	;
	mov	ax, ss:[bp].CQTRI_strategy.low
	mov	ds:[quickTransferRegionStrategy].low, ax
	mov	ax, ss:[bp].CQTRI_strategy.high
	mov	ds:[quickTransferRegionStrategy].high, ax
						
	; Warning -- first four parameters passed are expected to match
	; first four parameters in VisXORParams!

	; Warning -- since we use follow-mouse option, we need to pass
	; VXP_mousePos also.  CQTRI_regionPos must match up with
	; VXP_mousePos

	mov	ax, cx				; ax,bx = mouse position
	mov	bx, dx
	xchg	ax, ss:[bp].CQTRI_regionPos.P_x	; ax,bx = region position
	xchg	bx, ss:[bp].CQTRI_regionPos.P_y	; CQTRI_regionPos = mouse pos.
	mov	dx, ss:[bp].CQTRI_region.high
	mov	cx, ss:[bp].CQTRI_region.low

EC <	push	ax							>
EC <	xchg	bx, dx				; bx = region handle	>
EC <	call	MemLock							>
EC <	ERROR_C	BAD_QUICK_TRANSFER_XOR_REGION				>
EC <	call	MemUnlock						>
EC <	xchg	bx, dx				; restore		>
EC <	pop	ax							>

	mov	si, mask VXF_X_POS_FOLLOWS_MOUSE or \
			mask VXF_Y_POS_FOLLOWS_MOUSE
	mov	di, DR_VID_SET_XOR
	call	ss:[bp].CQTRI_strategy
	ornf	ds:[quickTransferFlags], mask CQTF_USE_REGION

setCursor:

	;
	; set flag saying that quick transfer is in progress
	; (needs to be done before QuickTransferSetCursor)
	;
	ornf	ds:[quickTransferFlags], mask CQTF_IN_PROGRESS

	;
	; set the specific move/copy cursor
	;
	pop	ax
	cmp	ax, -1
	je	noSpecificCursor
	clr	dl

; MORE TO DO!
;	mov	dh, ds:[activeMouseUIFunctionsActive]
;
; FOR NOW, just set one way....
	clr	dh

	mov	bp, dx				; get overrides, if any
	call	QuickTransferSetCursor
noSpecificCursor:

	;
	; then, set the default move/copy cursor
	;
	mov	ax, CQTF_SET_DEFAULT
	call	QuickTransferSetCursor

	; The flow object will send a keyboard character event saying that 
	; we're starting a quick copy.  This is not used at all for the 
	; functionality of the quick copy, just as notification.
	; (we send out something on all button presses now -- chris 7/16/90)
	
;	clr	bp				; bp doesn't matter
;	clr	dx				; nor does dl, dh
;	mov	cx, CS_UI_FUNCS shl 8 or UC_QUICK_COPY
;	clr	di
;	mov	ax, MSG_META_KBD_CHAR 
;	call	UserCallFlow			; send to flow object

	clc					; indicate quick-transfer
						;	started successfully
done:

	call	VQuickTransfer

	pop	ax, bx, cx, dx, di, si, bp, ds
	ret

ClipboardStartQuickTransfer	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ClipboardGetQuickTransferStatus

DESCRIPTION:	Check if a quick-transfer is in progress

CALLED BY:	GLOBAL

PASS:
	nothing

RETURN:
	Z flag - clear (JNZ) if quick-transfer in progress
		ax - ClipboardQuickTransferFlags
	       - set (JZ) if quick-transfer not in progress

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/91		Initial version for 2.0 quick-transfer

------------------------------------------------------------------------------@


ClipboardGetQuickTransferStatus	proc	far
	uses	ds
	.enter
	call	PQuickTransfer			; ds  = dgroup
	mov	ax, ds:[quickTransferFlags]	; ax = ClipboardQuickTransferFlags
	test	ax, mask CQTF_IN_PROGRESS	; set Z flag
	call	VQuickTransfer
	.leave
	ret
ClipboardGetQuickTransferStatus	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ClipboardSetQuickTransferFeedback

DESCRIPTION:	Set mouse cursor for quick-transfer

CALLED BY:	GLOBAL

PASS:
	ax - ClipboardQuickTransferFeedback enum
	if ax = CQTF_MOVE or CQTF_COPY
		bp high = UIFunctionsActive flags
			UIFA_MOVE - force move override
			UIFA_COPY - force copy override

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/91		Initial version for 2.0 quick-transfer

------------------------------------------------------------------------------@


ClipboardSetQuickTransferFeedback	proc	far
	uses	ds
	.enter
	call	PQuickTransfer			; ds = dgroup
	call	QuickTransferSetCursor
	call	VQuickTransfer
	.leave
	ret
ClipboardSetQuickTransferFeedback	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ClipboardEndQuickTransfer

DESCRIPTION:	End a quick-transfer:  reset mouse pointer image, clear
		quick-transfer region (if any), and clear quick-transfer
		item, send out notification, if needed.

CALLED BY:	GLOBAL

PASS:
	bp - ClipboardQuickNotifyFlags
		CQNF_MOVE if quick-transfer move operation was done
		CQNF_COPY if quick-transfer copy operation was done
		CQNF_NO_OPERATION if quick-transfer item was not
			accepted
		(sends out MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED)
	(quickTransferRegionStrategy - video driver strategy routine
					   from ClipboardStartQuickTransfer)

RETURN:
	ds	- unchanged

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	brianc	3/91		Updated for 2.0 quick-transfer

------------------------------------------------------------------------------@


ClipboardEndQuickTransfer	proc	far
	uses	ds
	.enter
	call	PQuickTransfer			; ds = dgroup
	;
	; clear cursor, clear quick-transfer item, clear quick-transfer flags
	; and send notification to quick-transfer source
	;
	call	QTEndQuickTransfer
	call	VQuickTransfer
	.leave
	ret
ClipboardEndQuickTransfer	endp

;
; pass:
;	bp - ClipboardQuickNotifyFlags
;	ds - dgroup
;	quickTransfer semaphore
; return:
;	nothing
; destroy:
;	nothing
QTEndQuickTransfer	proc	near
	uses	ax
	.enter
EC <	push	bx							>
EC <	mov	bx, ds							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	pop	bx							>
EC <	ERROR_NZ	0						>
	;
	; clear cursor, region (if any), quick-transfer item,
	; and quick-transfer flags
	;
	call	QTClearQuickTransfer
	;
	; check ClipboardQuickNotifyFlags
	; (allow only one of CQNF_MOVE, CQNF_COPY, CQNF_NO_OPERATION)
	;
EC <	push	bp							>
EC <	andnf	bp, mask CQNF_MOVE or mask CQNF_COPY or mask CQNF_NO_OPERATION >
EC <	cmp	bp, mask CQNF_MOVE					>
EC <	je	ecFlagOK						>
EC <	cmp	bp, mask CQNF_COPY					>
EC <	je	ecFlagOK						>
EC <	cmp	bp, mask CQNF_NO_OPERATION				>
EC <	ERROR_NZ	WRONG_QUICK_NOTIFY_FLAGS_FOR_TRANSFER_DONE	>
EC <ecFlagOK:								>
EC <	pop	bp							>
	;
	; send notification to quick-transfer source
	;
		
	mov	ax, MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED
	call	SendToQTSource
	;
	; clear notification OD, as end-quick-transfer notification
	; should only happen once
	;
	clr	ax
	mov	ds:[quickTransferNotifyOD].handle, ax
	mov	ds:[quickTransferNotifyOD].chunk, ax
	.leave
	ret
QTEndQuickTransfer	endp

;
; pass:	ax - method to send
;	cx, dx, bp - method data
;	ds - dgroup
;	quickTransfer semaphore
; destroys:
;	none
;
SendToQTSource	proc	far
	uses	ax, bx, si, di
	.enter
EC <	mov	bx, ds							>
EC <	mov	si, segment dgroup					>
EC <	cmp	si, bx							>
EC <	ERROR_NZ	0						>
	mov	bx, ds:[quickTransferNotifyOD].handle
	tst	bx
	jz	done				; no OD to notify
	mov	si, ds:[quickTransferNotifyOD].chunk
	;
	; DON'T send this FORCE_QUEUE, as the recipient may be on
	; the same thread, and might expect this to arrive
	; synchronously (ie, ssheet).
	;
	clr	di
	;
	; Release the quick transfer semaphore during the call, in
	; case the recipient is run by the same thread.
	; This should be OK, although there's no documentation as to
	; what this semaphore does, so I really can't say for sure...
	;
	call	VQuickTransfer		
	call	ObjMessage
	call	PQuickTransfer		
done:
	.leave
	ret
SendToQTSource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardHandleEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle MSG_META_END_MOVE_COPY -- either prepare to finish
		a quick-transfer and send a MSG_META_END_MOVE_COPY to the
		active-grab or end the quick-transfer and send a
		MSG_META_END_OTHER to the implied grab

CALLED BY:	GLOBAL
			FlowButton, VisContentMouseEvent

PASS:		bx - non-zero to send MSG_META_END_MOVE_COPY
		   - zero to send a MSG_META_END_OTHER
		bp high - UIFunctionsActive
		carry set to check if quick-transfer is in-progress
			(needed for internal input handling)
		carry clear to not check (should be used for all external
			handling)

RETURN:		ax - MSG_META_END_MOVE_COPY if bx<>0
			bp high - UIFunctionsActive modified with copy-override
				  if source of quick-transfer specified
				  CQTF_COPY_ONLY
		   - MSG_META_END_OTHER bx=0

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardHandleEndMoveCopy	proc	far
	uses	ds
	.enter
	pushf
	call	PQuickTransfer			; ds = dgroup
	popf
	;
	; check if quick-transfer is in progress
	;
	mov	ax, ds:[quickTransferFlags]
	jnc	noInProgressCheck
	test	ax, mask CQTF_IN_PROGRESS
	jz	checkGrab		; no just send MSG_META_END_OTHER
					;	or MSG_META_END_MOVE_COPY
noInProgressCheck:
	;
	; quick-transfer in progress, deal with CQTF_COPY_ONLY flag
	;
	test	ax, mask CQTF_COPY_ONLY
	jz	notCopyOnly
	andnf	bp, not mask UIFA_MOVE shl 8	; clear move-override
	ornf	bp, mask UIFA_COPY shl 8	; set copy-override
notCopyOnly:
	;
	; clear quick-transfer cursor so user knows immediately that we
	; processed his action
	;
	call	QTClearCursor
	;
	; we need to clear the quick-transfer status flag here because
	; the quick-transfer destination might not process the quick-transfer
	; with haste (e.g. GeoManager can actually put up a modal dialog box),
	; also the user might start another quick-transfer elsewhere
	;
	clr	ds:[quickTransferFlags]
	tst	bx
	jnz	endMoveCopy
	;
	; since there is a quick-transfer in progress and no one will be
	; receiving the MSG_META_END_MOVE_COPY, let's clear the quick-transfer
	; item; this prevents anything from being quick-transfer'ed if some
	; object later receives a MSG_META_END_MOVE_COPY but nothing registered
	; an associated quick-transfer item
	;
	mov	bp, mask CQNF_NO_OPERATION
	call	QTEndQuickTransfer
			; fall through to send MSG_META_END_OTHER (bx is 0)
checkGrab:
	tst	bx
	mov	ax, MSG_META_END_OTHER
	jz	done
endMoveCopy:
	mov	ax, MSG_META_END_MOVE_COPY
done:
	call	VQuickTransfer
	.leave
	ret
ClipboardHandleEndMoveCopy	endp

Transfer	ends
