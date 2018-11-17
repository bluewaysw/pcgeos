COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextTrans
FILE:		ttQuick.asm

AUTHOR:		John Wedgwood, Oct 25, 1989

METHODS:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/25/89		Initial revision

DESCRIPTION:
	Quick copy/move method handlers w/ support.

	$Id: ttQuick.asm,v 1.1 97/04/07 11:19:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextTransfer segment resource

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  If you change this following definition, make sure it is updated ;;;
;;;  in /Appl/TEdit/tedit.asm as well.	ptrinh 5/26/95		      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
QUICK_TRANS_PARAMS	equ	<\
.warn -unref_local\
oldRange	local	VisTextRange\
newRange	local	VisTextRange\
sourceEQdest	local	BooleanByte\
owner		local	optr\
queriedItem	local	dword\
quickFlags	local	ClipboardQuickNotifyFlags\
.warn @unref_local\
>

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextStartMoveCopy -- MSG_META_START_MOVE_COPY for
			VisTextClass

DESCRIPTION:	Start a quick move or a quick copy from the text object

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

	cx - x position
	dx - y position
	bp low - UIButtonFlags
	bp high - UIFunctionsActive

RETURN:
	ax - MouseReturnFlags

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
VisTextStartMoveCopy	proc	far
	mov	bx, bp				; bx <- flags
	
	;
	; Allocate stack frame for VisTextLargeStartMoveCopy
	;
	sub	sp, size LargeMouseData		; Allocate space
	mov	bp, sp				; ss:bp <- stack frame

	call	InitLargeMouseStructure

	call	VisTextLargeStartMoveCopy
	
	;
	; Restore the stack
	;
	add	sp, size LargeMouseData		; Restore stack

	ret
VisTextStartMoveCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextLargeStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a quick move/copy operation.

CALLED BY:	via MSG_META_LARGE_START_MOVE_COPY, VisTextStartMoveCopy
PASS:		*ds:si	= Instance
		ss:bp	= LargeMouseData
RETURN:		ax	= MouseReturnFlags
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextLargeStartMoveCopy	proc	far
	mov	ax, bp				; ss:ax <- LargeMouseData
QUICK_TRANS_PARAMS
	.enter
	class	VisTextClass

	test	ds:[di].VTI_state, mask VTS_SELECTABLE
	jz	done				; quit if not selectable.

	push	ax				; save params
	call	TextTakeGadgetExclAndGrab
	call	TextMakeFocusAndTarget
	pop	bx				; ss:bx <- LargeMouseData

	;
	; Make sure that the event really does fall in a region.
	;
	xchg	bp, bx				; ss:bp <- event position
						; ss:bx <- variables
	call	TR_RegionFromPoint		; cx <- region
						; ax/dx destroyed
	xchg	bp, bx				; Restore frame ptrs
	
	cmp	cx, CA_NULL_ELEMENT
	je	replay

	;
	; Get information into stack frame
	;
	clr	ax				;we haven't started transfer
	call	QuickTransferPositionInfo	;carry = set if in selection
	jnc	done				;Branch if not in selection

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; 6/ 9/93 -jw
; If there is a section break in the selection, then we can't move the text,
; since we aren't allowed to delete section breaks in this manner. We can't
; copy it, since we aren't allowed to insert section breaks either. We just
; do nothing.
;
	push	bp
	lea	bp, oldRange			; ss:bp <- selection
	call	TR_CheckCrossSectionChange	; Not w/ a section break...
	pop	bp
	jc	done
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	;
	; Start the UI part of the quick move
	;
	mov	di, si				;^lBX:DI <- this object (OD
	mov	bx, ds:[LMBH_handle]		; to send NOTIFY_QUICK_TRANSFER
						; to
	mov_tr	si, ax
	mov	ax, -1
	call	ClipboardStartQuickTransfer
	mov	si, di				;restore instance chunk handle.
	jc	done				; quick-transfer already in
						;	progress, can't start
						;	another
	;
	; Register the transfer item
	;
	call	ClipboardGetClipboardFile		;bx = VM file
	clr	ax				;generate a transfer item
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; owner is ourself
	mov	di, -1				; standard name
	call	GenerateTransferItem		;ax = VM block, bx = VM file
	push	bp
	mov	bp, mask CIF_QUICK		;not RAW, QUICK
	call	ClipboardRegisterItem
	pop	bp
	jc	done

	;
	; Prepare to use the mouse
	; (will be released when mouse leaves visible bounds -- on a
	;  MSG_VIS_LOST_GADGET_EXCL or MSG_META_VIS_LEAVE)

	call	TextTakeGadgetExclAndGrab

	;
	; sucessfully started UI part of quick-transfer and sucessfully
	; registered item, now allow pointer to roam around globally for
	; feedback
	;
	push	bp
	mov	ax, MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; We have started feedback, indicate this
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].VTI_intSelFlags, mask VTISF_DOING_SELECTION or \
					mask VTISF_DOING_DRAG_SELECTION
done:
	mov	ax, mask MRF_PROCESSED

quit:
	.leave
	ret

replay:
	mov	ax, mask MRF_REPLAY
	jmp	quit
VisTextLargeStartMoveCopy	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	TT_SetClipboardQuickTransferFeedback

DESCRIPTION:	Set the quick transfer cursor on a MSG_META_PTR

CALLED BY:	VisTextPtr	

PASS:
	*ds:si	= object
	ss:bp	= LargeMouseData

RETURN:
	ax - MouseReturnFlags

DESTROYED:
	bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/25/92		Initial version

------------------------------------------------------------------------------@
TT_SetClipboardQuickTransferFeedback	proc	far
QUICK_TRANS_PARAMS
	.enter
	class	VisTextClass

	;
	; Make sure that the event really does fall in a region.
	;
	push	bp
	mov	bp, ss:[bp]
	call	TR_RegionFromPoint		; cx <- region
	pop	bp				; ax/dx destroyed
	cmp	cx, CA_NULL_ELEMENT
	jnz	inBounds

	;
	; We are getting pointer events even though the mouse is outside
	; the bounds of our object. Allow someone else to grab the events
	; and signal that we aren't paying attention to them any more.
	;
	call	VisTextVisLeave
	mov	ax, mask MRF_REPLAY
	jmp	done

inBounds:
	;
	; We are in the process of doing a quick-move/copy and this event
	; is inside the bounds of this object. Check to see if this is our
	; first notification about the quick-move operation.
	;
	; If it is then we want to grab the gadget exclusive and make sure that
	; we get all the pointer events.
	;
	; If it isn't all we need to do is make sure that the cursor
	; is correct.
	;
	test	ds:[di].VTI_intSelFlags, mask VTISF_DOING_DRAG_SELECTION
	jnz	setCursor
	;
	; This is our first notification of this event. Grab the gadget
	; exclusive and make sure we get pointer events while the mouse
	; is over our object.
	;
	call	TextTakeGadgetExclAndGrab	; grab mouse for feedback
	ornf	ds:[di].VTI_intSelFlags, mask VTISF_DOING_DRAG_SELECTION

setCursor:
	mov	ax, -1
	mov	bx, ss:[bp]
	call	QuickTransferPositionInfo

	mov	ax, CQTF_CLEAR
	test	dx, mask CQNF_NO_OPERATION
	jnz	common
	mov	ax, CQTF_MOVE
	test	dx, mask CQNF_MOVE
	jnz	common
	mov	ax, CQTF_COPY
common:
	mov	ch, ss:[bx].LMD_uiFunctionsActive
	xchg	cx, bp
	call	ClipboardSetQuickTransferFeedback
	xchg	cx, bp

	mov	ax, mask MRF_PROCESSED

done:
	.leave
	ret

TT_SetClipboardQuickTransferFeedback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	QuickTransferPositionInfo

DESCRIPTION:	Get information about a quick transfer

CALLED BY:	INTERNAL

PASS:
	*ds:si	= object
	ss:bx	= LargeMouseData
	ss:bp	= Inherited variables
	ax	= non-zero if we've started the transfer already (if not set
		     then owner not returned)

RETURN:
	ds:di		= VisTextInstance
	ax		= ClipboardQuickTransferFlags (CQTF_COPY_ONLY set if not editable)
	dx		= ClipboardQuickNotifyFlags
	carry set if position is over selection

	newRange	= position under point
	oldRange	= selected area
	quickFlags	= ClipboardQuickNotifyFlags
	sourceEQdest	= set if source equal dest
	owner		= set

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/24/92		Initial version

------------------------------------------------------------------------------@
QuickTransferPositionInfo	proc	near
	class	VisTextClass
QUICK_TRANS_PARAMS
	.enter inherit far
	;
	; Need a gstate to operate
	;
	call	TextGStateCreate

	;
	; Get the selection into the "old range".
	;
	push	bp
	lea	bp, oldRange
	call	T_FarGetSelectionFrame
	pop	bp

	push	ax				;Save "started transfer" flag

	;
	; In order to get the closest coordinate we need to have a stack
	; frame containing the position of the event. We have that already
	; as part of the LargeMouseData.
	;
	xchg	bx, bp				;ss:bp <- LargeMouseData
						;ss:bx <- Local variables
	call	IsPositionInLine		;carry set if in a line
						;dx.ax <- address of event
	xchg	bp, bx				;Restore frame ptrs
	jnc	outOfRange			;Branch if not over a line

	;
	; Check to see if the new position falls in the selection.
	;
	cmpdw	dxax, oldRange.VTR_start
	jb	outOfRange
	cmpdw	dxax, oldRange.VTR_end
	ja	outOfRange

	stc
	jmp	figureMoreStuff

outOfRange:
	clc

figureMoreStuff:
	pop	cx				;cx <- passed flag

	;
	; Carry is set if the position falls inside the selection.
	;
	pushf					;save "in range" flag
	
	;
	; Save the position as the "new range"
	;
	movdw	newRange.VTR_start, dxax
	movdw	newRange.VTR_end, dxax

	;
	; get information about the transfer
	;
	tst	cx
	LONG jz	done				;Branch if we haven't started

	;
	; We have started the transfer.
	;
	push	bx
	push	bp				;Save frame ptrs
	mov	bp, mask CIF_QUICK
	call	ClipboardQueryItem		;bp = # formats, cx:dx = owner
	pop	bp				;bx = VM file, ax = VM block
	movdw	queriedItem, bxax
	movdw	owner, cxdx

	; make sure that an acceptable format exists

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT			;format to search for
	call	ClipboardTestItemFormat
	jnc	gotPasteStatus			;jump if valid assumption
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_GRAPHICS
	stc
	jz	gotPasteStatus
	mov	dx, CIF_GRAPHICS_STRING		;format to search for
	call	ClipboardTestItemFormat
gotPasteStatus:
	pop	bx				;Restore frame ptrs
	mov	dx, mask CQNF_NO_OPERATION	;Assume drop on selection
	jc	doneDoneWithTr

	;
	; We are trying to set the ClipboardQuickNotifyFlags correctly. We use
	; dx to accumulate the correct flags.
	;
	; First test: Is the source the same object ?
	;
	mov	sourceEQdest, BB_FALSE		;Assume source != dest
	mov	ax, ds:[LMBH_handle]		;^lax:si <- our object
						;^lcx:dx == owner of transfer

	cmpdw	axsi, owner			;Compare source/dest objects
	mov	dx, mask CQNF_COPY		;Default to copy if different
	jnz	gotFlags			;Branch if different

	;
	; The source is the same object -- make sure that we're not dropping
	; the transfer on top of itself -- default to move
	;
	mov	sourceEQdest, BB_TRUE		;Signal: source == dest
	popf					;Get "in range" flag
	pushf					;Save it again to preserve stack

	mov	dx, mask CQNF_NO_OPERATION	;Assume drop on selection
	jc	doneDoneWithTr			;Branch if drop on selection

	;
	; We're dropping the transfer somewhere other than on the selection of 
	; the object in which the transfer originated. We assume that the user
	; wanted to move the data.
	;
	mov	dx, mask CQNF_MOVE
gotFlags:
	;
	; Handle quick-transfer overrides specified by the user (if any).
	;
	mov	al, ss:[bx].LMD_uiFunctionsActive
	test	al, mask UIFA_MOVE		; force move?
	jz	notForceMove			; nope, check force-copy
	mov	dx, mask CQNF_MOVE
	jmp	afterOverrides

notForceMove:
	test	al, mask UIFA_COPY		; force copy?
	jz	afterOverrides			; nope, leave default behavior
	mov	dx, mask CQNF_COPY

afterOverrides:

doneDoneWithTr:
	push	bx
	movdw	bxax, queriedItem
	call	ClipboardDoneWithItem
	pop	bx

done:
	;
	; *ds:si= Instance
	; dx	= ClipboardQuickNotifyFlags
	;
	; One last check. If the object isn't editable then we can only copy
	; out of it.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, mask CQTF_NOTIFICATION

	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jnz	10$
	ornf	ax, mask CQTF_COPY_ONLY
	mov	dx, mask CQNF_NO_OPERATION
10$:
	mov	quickFlags, dx

	call	TextGStateDestroy
	popf
	.leave
	ret

QuickTransferPositionInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsPositionInLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to make sure a position is actually over the data on
		a line.

CALLED BY:	QuickTransferPositionInfo
PASS:		*ds:si	= Instance
		ss:bp	= LargeMouseData
RETURN:		carry set if event is over a line
		dx.ax	= Offset of the event
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsPositionInLine	proc	near
	class	VisTextClass
	uses	bx, cx, di, bp
	.enter
	;
	; Find the line the event occurred on.
	;
	movdw	cxbx, ss:[bp].PDF_x.DWF_int	; cx.bx <- X position
	movdw	dxax, ss:[bp].PDF_y.DWF_int	; dx.ax <- Y position
	call	TL_LineFromExtPosition		; bx.di <- Line under the event
	
	pushdw	bxdi				; Save line
	pushf					; Save "below last line" flag
	
	;
	; Get the left edge of the line and see if we're before it.
	;
	call	TL_LineToExtPosition		; cx.bx <- left edge of line
						; dx.ax <- top edge of line

	mov	di, ds:[si]			; ds:di <- instance
	add	di, ds:[di].Vis_offset
	
	push	ax, dx				; Save top edge of line
	mov	ax, ds:[di].VTI_leftOffset	; dx.ax <- left offset
	cwd

	adddw	cxbx, dxax			; Account for left offset

	subdw	cxbx, ss:[bp].PDF_x.DWF_int	; cx.bx <- offset from line left
	negdw	cxbx
	pop	ax, dx				; Restore top edge of line

	popf					; Restore "below last line" flag
	jc	useLargeXOffset			; Branch if below last line

	tst	cx				; Branch if negative or too big
	js	useNegativeOffset		; Branch if <0
	jnz	useLargeXOffset			; Branch if really big
	
	;
	; The offset is some reasonable value
	;
	
figureOffset:
	;
	; bx	= Offset into line to compute for
	; On stack:
	;	Line to compute on
	;
	mov	bp, bx				; bp <- Pixel offset from left
	popdw	bxdi				; Restore line
	movdw	dxax, -1			; dx.ax <- Offset to calc up to
	call	TL_LineTextPosition		; dx.ax <- Nearest text offset
						; bx <- pixel from line left
						; carry set if not on line

	cmc					; carry set if over line
						; carry clear otherwise
	.leave
	ret


useNegativeOffset:
	mov	bx, -1				; bx <- negative offset
	jmp	figureOffset

useLargeXOffset:
	;
	; Fall thru since we're not over a line
	;
	mov	bx, 0x7fff			; bx <- large offset
	jmp	figureOffset

IsPositionInLine	endp


COMMENT @----------------------------------------------------------------------

METHOD:		VisTextEndMoveCopy -- MSG_META_END_MOVE_COPY
		for VisTextClass

DESCRIPTION:	Handle a quick transfer

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

	cx - x position
	dx - y position
	bp low - UIButtonFlags
	bp high - UIFunctionsActive
			UIFA_MOVE set if move override
			UIFA_COPY set if copy override

RETURN:

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	brianc	3/91		Updated for 2.0 quick-transfer

------------------------------------------------------------------------------@
VisTextEndMoveCopy	proc	far		; MSG_META_END_MOVE_COPY
	mov	ax, bp				; ax <- flags
	
	;
	; Allocate stack frame for VisTextLargeStartMoveCopy
	;
	sub	sp, size LargeMouseData		; Allocate space
	mov	bp, sp				; ss:bp <- stack frame
	
	;
	; Copy the parameters into the stack frame and call the handler
	;
	mov	ss:[bp].LMD_location.PDF_x.DWF_int.low, cx
	mov	ss:[bp].LMD_location.PDF_x.DWF_int.high, 0
	mov	ss:[bp].LMD_location.PDF_x.DWF_frac, 0
	mov	ss:[bp].LMD_location.PDF_y.DWF_int.low, dx
	mov	ss:[bp].LMD_location.PDF_y.DWF_int.high, 0
	mov	ss:[bp].LMD_location.PDF_y.DWF_frac, 0

	mov	ss:[bp].LMD_buttonInfo, al
	mov	ss:[bp].LMD_uiFunctionsActive, ah

	call	VisTextLargeEndMoveCopy
	
	;
	; Restore the stack
	;
	add	sp, size LargeMouseData		; Restore stack
	ret
VisTextEndMoveCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextLargeEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish a quick move/copy operation.

CALLED BY:	via MSG_META_LARGE_END_MOVE_COPY, VisTextEndMoveCopy
PASS:		*ds:si	= Instance
		ss:bp	= LargeMouseData
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextLargeEndMoveCopy	proc	far
	mov	ax, bp				; ss:ax <- LargeMouseData
QUICK_TRANS_PARAMS
	.enter
	class	VisTextClass

	mov	bx, ax				; ss:bx <- LargeMouseData

	;
	; if we were doing feedback, stop it now
	;
	call	VisTextVisLeave			; Release mouse, clear cursor
	andnf	ds:[di].VTI_intSelFlags, not mask VTISF_DOING_SELECTION
	call	VisReleaseMouse			; release mouse unconditionally

	mov	ax, -1				; Signal: transfer in progress
	call	QuickTransferPositionInfo	; carry set if pos in selection

	;
	; If this object is not editable then we can't do anything
	;
	test	dx, mask CQNF_NO_OPERATION
	jnz	toDone
	
	;
	; If wee are doing a move inside the same object and if the destination
	; is inside the source then bail
	;
	tst	sourceEQdest
	jz	noBail
	movdw	dxax, newRange.VTR_start
	cmpdw	dxax, oldRange.VTR_start
	jbe	noBail
	cmpdw	dxax, oldRange.VTR_end
	jae	noBail
toDone:
	jmp	done
noBail:

	and	ds:[di].VTI_intFlags, not mask VTIF_ADJUST_TYPE
	or	ds:[di].VTI_intFlags, AT_QUICK shl offset VTIF_ADJUST_TYPE

	call	TextGStateCreate

	;
	; Make this object the focus object in the window
	; (will award KBD grab also.)

	call	TextMakeFocusAndTarget

	;
	; Find the generic window group that this object is in, and bring
	; the window to the top.
	;
	push	ds:[LMBH_handle], si		; Save object OD
	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	bx, segment GenClass
	mov	si, offset GenClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; Create ClassedEvent
	mov	cx, di				; cx <- handle to ClassedEvent
	pop	bx, si				; Restore object OD
	clr	di
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP	; Send the message upward
	call	ObjMessage

	call	MemDerefDS			; Fixup object's segment

	;
	; Bring app itself to top of heap
	;
	push	bp
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	GenCallApplication
	pop	bp

	;
	; Set the selection for this object to the position we intend to
	; paste at. This way if we are doing a quick-move the delete will
	; cause the selection position to be updated.
	;
	push	bp
	lea	bp, newRange
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; if we're moving to ourself then adjust the range
	;
	movdw	dxax, newRange.VTR_start
	tst	sourceEQdest
	jz	noAdjust
	
	;
	; We are copying to ourselves
	;
	test	quickFlags, mask CQNF_COPY
	jnz	noAdjust
	
	;
	; We are doing a move inside the same object.
	;
	movdw	cxbx, oldRange.VTR_end
	cmpdw	dxax, cxbx
	jb	noAdjust
	subdw	cxbx, oldRange.VTR_start
	subdw	dxax, cxbx
noAdjust:

	push	ax
	mov	ax, offset QuickCopyString
	test	quickFlags, mask CQNF_COPY
	jnz	isCopy
	mov	ax, offset QuickMoveString
isCopy:
	call	TU_StartChainIfUndoable
	pop	ax

	;
	; paste the sucker
	;
	movdw	cxbx, dxax
	mov	di, mask CIF_QUICK
	call	PasteCommon

	call	TU_EndChainIfUndoable

	mov	bx, quickFlags
	jnc	noProblem			; Branch if no error pasting

	;
	; There was a problem. If the source and destination are in the same
	; object, reset the selection. (We would have nuked it above).
	;
	push	bp
	lea	bp, oldRange
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	pop	bp

noProblem:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	and	ds:[di].VTI_intFlags, not mask VTIF_ADJUST_TYPE
	or	ds:[di].VTI_intFlags, AT_NORMAL shl offset VTIF_ADJUST_TYPE

	call	TextGStateDestroy

done:
	;
	; stop UI part of quick-transfer (will clear default quick-transfer
	; cursor, etc.)
	; (this is done regardless of whether we accepted an item or not)
	;
	push	bp				; Save frame ptr
	mov	bp, quickFlags			; bp = ClipboardQuickNotifyFlags
	call	ClipboardEndQuickTransfer		; Finish up
	pop	bp				; Restore frame ptr

	;
	; Send out appropriate notifications now that the move has completed
	;
	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
	call	TA_SendNotification

	mov	ax, mask MRF_PROCESSED		; Signal: handled the event
	.leave
	ret
VisTextLargeEndMoveCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickMoveSpecial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called right before a inserting a graphic or pasting in a
		transfer item.

CALLED BY:
PASS:		*ds:si	= object we are going to paste into.
		bp	= Inheritable stack frame
RETURN:		*ds:si	= object we ought to paste into.
		VTRP_range.VTR_start set correctly for the paste.
		carry set if the operation can't succeed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:z
	Name	Date		Description
	----	----		-----------
	jcw	6/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuickMoveSpecial	proc	far
	class	VisTextClass
QUICK_TRANS_PARAMS
	.enter inherit far

		CheckHack <offset CTP_pasteFrame eq offset RWGP_pasteFrame>
	push	bp
	mov	bp, ss:[bp][size VisTextReplaceParameters]

	call	QuickMoveSpecialInternal

	pop	bp
	.leave
	ret
QuickMoveSpecial	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickMoveSpecialInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See QuickMoveSpecial

CALLED BY:	GLOBAL
PASS:		*ds:si	= object we are going to paste into.
		ss:bp	= CommonTransferParams
RETURN:		*ds:si	= object we ought to paste into.
		VTRP_range.VTR_start set correctly for the paste.
		carry set if the operation can't succeed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:z
	Name	Date		Description
	----	----		-----------
	gene	3/22/00		Broke out from QuickMoveSpecial

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickMoveSpecialInternal	proc	near 	uses	ax, bx, cx, dx, di
	class	VisTextClass
QUICK_TRANS_PARAMS
	.enter	inherit	far

	mov	bp, ss:[bp].CTP_pasteFrame
	tst	bp				; Quit if this wasn't called
	LONG jz	done				;  as part of a paste.

	mov	bp, ss:[bp].PCP_quickFrame

	tst	bp				;Quit if no "quickFrame"
	LONG jz	done				;
	test	quickFlags, mask CQNF_MOVE	;
	LONG jz	done				; Quit if not quick move.

	; This is a quick move.  Before we do the move we must send a
	; MSG_NOTIFY_QUICK_MOVE_ACCEPTED to the old owner -- if this is
	; ourself then we need to adjust the paste range accordingly

	tst	sourceEQdest
	jz	differentObject

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	al, ds:[di].VTI_intFlags
	push	ax
	and	al, not mask VTIF_ADJUST_TYPE
	or	al, AT_NORMAL shl offset VTIF_ADJUST_TYPE
	mov	ds:[di].VTI_intFlags, al

	movdw	dxax, oldRange.VTR_start
	movdw	cxbx, oldRange.VTR_end
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp
	movdw	ss:[bp].VTRP_range.VTR_start, dxax
	movdw	ss:[bp].VTRP_range.VTR_end, cxbx
	clrdw	ss:[bp].VTRP_insCount
	mov	ss:[bp].VTRP_flags, 0
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock
	lahf					; Save error flag
	add	sp, size VisTextReplaceParameters
	sahf					; Restore error flag

	pushf					; Save error flag again...
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	popf					; Restore error for return
	pop	ax
	mov	ds:[di].VTI_intFlags, al
	jmp	done

differentObject:
	push	si
	mov	bx, segment VisTextClass
	mov	si, offset VisTextClass
	mov	ax, MSG_VIS_TEXT_DELETE_SELECTION
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	dx, TO_SELF
	movdw	bxsi, owner
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	clr	di
	call	ObjMessage
	pop	si
	clc					; Signal: "success"

done:
	.leave
	ret
QuickMoveSpecialInternal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextNotifyQuickTransferConcluded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message handler is invoked when a quick transfer has 
		concluded. We basically just make sure that various flags
		have been cleared.

CALLED BY:	GLOBAL
PASS:		*ds:si,ds:di - VisText object
		es - segment of VisTextClass
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextNotifyQuickTransferConcluded	proc	far
	class	VisTextClass
	.enter
	call	VisTextVisLeave
	andnf	ds:[di].VTI_intSelFlags, not mask VTISF_DOING_SELECTION
	
	.leave
	ret
VisTextNotifyQuickTransferConcluded	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextPrepForQuickTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prep work for subclasses of VisText that want to handle
		MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT specially
		to do interesting things on a paste.

CALLED BY:	GLOBAL
PASS:		*ds:si	= object we are going to paste into.
		bp	= Inheritable stack frame
RETURN:		*ds:si	= object we ought to paste into.
		VTRP_range.VTR_start set correctly for the paste.
		carry set if the operation can't succeed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:z
	Name	Date		Description
	----	----		-----------
	gene	3/22/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisTextPrepForQuickTransfer	proc	far
					; MSG_VIS_TEXT_PREP_FOR_QUICK_TRANSFER
		call	QuickMoveSpecialInternal
		ret
VisTextPrepForQuickTransfer	endp

TextTransfer ends
