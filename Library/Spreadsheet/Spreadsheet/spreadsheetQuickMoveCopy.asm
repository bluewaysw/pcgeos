
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetQuickMoveCopy.asm

AUTHOR:		Cheng, 6/91

ROUTINES:
	Name				Description
	----				-----------
	SpreadsheetStartMoveCopy	MSG_META_LARGE_START_MOVE_COPY
	SpreadsheetStopFeedback		MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL
	SpreadsheetEndMoveCopy		MSG_META_LARGE_END_MOVE_COPY
	SpreadsheetGetClickedOnCell
	SpreadsheetIsClickInBounds?
	SpreadsheetNotifyQuickTransferConcluded
					MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED
	SpreadsheetClearSource
	SpreadsheetClearCell
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial revision

DESCRIPTION:
		
	$Id: spreadsheetQuickMoveCopy.asm,v 1.1 97/04/07 11:14:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CutPasteCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SpreadsheetStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle MSG_META_LARGE_START_MOVE_COPY - begin a quick-transfer

CALLED BY:	EXTERNAL (MSG_META_LARGE_START_MOVE_COPY)

PASS:		*ds:si - Spreadsheet instance
		es - 	segment of SpreadsheetClass
		ss:bp - LargeMouseData

RETURN:		ax - MouseReturnFlags

DESTROYED:	bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetStartMoveCopy	method	dynamic SpreadsheetClass,
					MSG_META_LARGE_START_MOVE_COPY
	;
	; bail if a quick-transfer is already in progress
	;
	test	ds:[di].SSI_flags, mask SF_QUICK_TRANS_IN_PROGRESS
	LONG jne	noGo

	;
	; bail if click is out of the selected region
	;
	call	SpreadsheetGetClickedOnCell	; ax,cx <- (r,c)
	call	SpreadsheetIsClickInBounds?
	LONG jc	noGo				; branch if not

	;
	; mark quick-transfer in progress
	;
	ornf	ds:[di].SSI_flags, mask SF_QUICK_TRANS_IN_PROGRESS or \
				mask SF_IN_VIEW

	call	GrabMouse

	mov	ch, ss:[bp].LMD_uiFunctionsActive
	clr	cl

	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef	locals
	ForceRef	SSM_local
	.enter

	;
	; Start the UI part of the quick-transfer.
	; We need to check for locked cells and if they are present, disallow
	; moving.
	;
	push	di,si
	mov	bx, ds:LMBH_handle
	mov	di, si				; bx:di = OD for our process
						;	(notification OD)
	mov	si, mask CQTF_NOTIFICATION

	;
	; use appropriate operation
	;
	mov	ax, CQTF_MOVE			; assume MOVE
	test	cx, (mask UIFA_COPY) shl 8	; copy key depressed?
	je	10$				; branch if not
	mov	ax, CQTF_COPY			; else force COPY
10$:
; check on locked cells
;	or	si, mask CQTF_COPY_ONLY
;	mov	ax, CQTF_COPY			; initial feedback cursor
	call	ClipboardStartQuickTransfer
	pop	di,si
	jc	done				; do nothing  if quick-transfer
						; is already in progress
	;
	; create and register a quick-transfer item
	;
	push	di, si
	mov	CCSF_local.CCSF_copyFlag, -1
	mov	CCSF_local.CCSF_transferItemFlag, mask CIF_QUICK
	call	CutCopyDoCopy			; destroys  bx,si,di,es
	pop	di, si
	jc	error				; handle error
	;
	; quick-transfer sucessfully started, allow the mouse pointer to
	; wander everywhere for feedback
	;
	push	bp
	mov	ax, MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; save the coords of the source region
	;
	mov	ax, ds:[di].SSI_selected.CR_start.CR_column
	mov	ds:[di].SSI_quickSource.CR_start.CR_column, ax

	mov	ax, ds:[di].SSI_selected.CR_start.CR_row
	mov	ds:[di].SSI_quickSource.CR_start.CR_row, ax

	mov	ax, ds:[di].SSI_selected.CR_end.CR_column
	mov	ds:[di].SSI_quickSource.CR_end.CR_column, ax

	mov	ax, ds:[di].SSI_selected.CR_end.CR_row
	mov	ds:[di].SSI_quickSource.CR_end.CR_row, ax

	ornf	ds:[di].SSI_flags, mask SF_DOING_FEEDBACK
	jmp	short done

error:
	;
	; handle error creating item by stoping UI part of quick-tranfser
	;
	call	SpreadsheetStopFeedback
done:
	.leave
exit:
	mov	ax, mask MRF_PROCESSED		; accepted mouse event
	ret

noGo:
	andnf	ds:[di].SSI_flags, not mask SF_QUICK_TRANS_IN_PROGRESS
	jmp	short exit

SpreadsheetStartMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetStopFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle MSG_SUBVIEW_LOST_GADGET_EXCL
		by stopping quick-transfer feedback

CALLED BY:	MSG_SUBVIEW_LOST_GADGET_EXCL

PASS:		ds:di - Spreadsheet instance

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	02/02/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetStopFeedback	method	SpreadsheetClass, \
					MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL

	test	ds:[di].SSI_flags, mask SF_DOING_FEEDBACK
	je	done

	;
	; indicate that we have left the view, in case we get a few lingering
	; MSG_PTRs, while waiting for MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER to take
	; effect
	;
	andnf	ds:[di].SSI_flags, not mask SF_IN_VIEW

	mov	ax, CQTF_CLEAR
	call	ClipboardSetQuickTransferFeedback
	andnf	ds:[di].SSI_flags, not mask SF_DOING_FEEDBACK

done:
	ret
SpreadsheetStopFeedback	endm


SpreadsheetContentEnter	method	SpreadsheetClass, MSG_META_CONTENT_ENTER
	ornf	ds:[di].SSI_flags, mask SF_IN_VIEW
	ret
SpreadsheetContentEnter	endp

SpreadsheetContentLeave	method	SpreadsheetClass, MSG_META_CONTENT_LEAVE
	andnf	ds:[di].SSI_flags, not mask SF_IN_VIEW
	test	ds:[di].SSI_flags, mask SF_HAVE_GRAB
	jz	done

	call	ReleaseMouse
done:
	ret
SpreadsheetContentLeave	endp


if 0
SpreadsheetVisEnter	method	SpreadsheetClass, MSG_META_VIS_ENTER
	ornf	ds:[di].SSI_flags, mask SF_IN_VIEW
	ret
SpreadsheetVisEnter	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SpreadsheetEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle MSG_META_LARGE_END_MOVE_COPY - quick-paste item if
		CIF_SPREADSHEET available

CALLED BY:	EXTERNAL (MSG_META_LARGE_END_MOVE_COPY)

PASS:		ss:bp - LargeMouseData

RETURN:		ax - MouseReturnFlags

DESTROYED:	bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if there is no override then
	    if destination document = source document then
		operation = move
	    else
		operation = copy
	    endif
	endif
	call PasteCommon, set ClipboardQuickNotifyFlags
	call ClipboardEndQuickTransfer

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetEndMoveCopy	method	dynamic SpreadsheetClass,
				MSG_META_LARGE_END_MOVE_COPY
	
	call	ReleaseMouse

	push	bp
	call	SpreadsheetStopFeedback
	mov	bp, mask CIF_QUICK
	call	ClipboardQueryItem	; bp <- number of formats
					; cx:dx <- owner
					; bx <- VM file han
					; ax <- TransferItemFinished VM blk han
	clr	cx
	tst	bp			; any formats?
	pop	bp
	LONG je	flagNoOp		;branch if no formats

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_SPREADSHEET
	call	ClipboardTestItemFormat
	LONG jc	flagNoOp		;branch if no spreadsheet format
	;
	; Clean up after ourselves
	;
	call	ClipboardDoneWithItem
	;-----------------------------------------------------------------------
	; convert DWFixed data in the LargeMouseData into a PointDWord
	; get destination cell

	call	SpreadsheetGetClickedOnCell	; ax,cx <- (r,c)

	;-----------------------------------------------------------------------
	; if destination cell = top left cell of source then source = dest
	; need to confirm that source spreadsheet = dest spreadsheet...

	;-----------------------------------------------------------------------
	; force destination cell
	; ax,cx <- (r,c)

	mov	ds:[di].SSI_active.CR_row, ax
	mov	ds:[di].SSI_active.CR_column, cx
	mov	ds:[di].SSI_selected.CR_start.CR_column, cx
	mov	ds:[di].SSI_selected.CR_end.CR_column, cx
	mov	ds:[di].SSI_selected.CR_start.CR_row, ax
	mov	ds:[di].SSI_selected.CR_end.CR_row, ax

	mov	PSF_local.PSF_selectedRange.R_top, ax
	mov	PSF_local.PSF_selectedRange.R_right, cx
	mov	PSF_local.PSF_selectedRange.R_bottom, ax
	mov	PSF_local.PSF_selectedRange.R_left, cx

ifdef GPC_ONLY
	;-----------------------------------------------------------------------
	; query user if destructive
	cmp	ds:[di].SSI_quickSource.CR_start.CR_row, ax
	jne	notSame
	cmp	ds:[di].SSI_quickSource.CR_start.CR_column, cx
	je	same
notSame:
	push	bx, cx, dx, ds, si, di, bp
	mov	bx, handle CutPasteStrings
	call	MemLock
	mov	ds, ax
	mov	si, offset QuickPasteConfirm
	mov	si, ds:[si]
	mov	di, ds
	mov	bp, si
	mov	ax, mask CDBF_SYSTEM_MODAL or \
		(CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
		(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	call	PasteCallUserStandardDialog	; ax = response
	mov	bx, handle CutPasteStrings
	call	MemUnlock
	pop	bx, cx, dx, ds, si, di, bp
	cmp	ax, IC_YES
	LONG jne	afterNoOp
same:
endif ;GPC_ONLY
	;-----------------------------------------------------------------------
	; check on format

	push	di,si
	mov	ax, mask CIF_QUICK

	locals		local	CellLocals	;inherited...
ForceRef locals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc	;inherited...
ForceRef SSM_local
	class	SpreadsheetClass
	.enter

	call	PasteCommon		; destroys ax,bx,ch,dx,di,si,bp
					; cl <- boolean - source = dest
	.leave
	pop	di,si
	jc	noOp

	mov	ah, ss:[bp].LMD_uiFunctionsActive
	clr	al
	mov	bp, ax			; bp <- UIFA flags

	;-----------------------------------------------------------------------
	; check for button overrides

	test	bp, (mask UIFA_MOVE) shl 8
	je	checkCopy

doMove:
	mov	bp, mask CQNF_MOVE
	jmp	short doRedraw

checkCopy:
	test	bp, (mask UIFA_COPY) shl 8
	je	doDefault
	;
	; We did a copy -- force a redraw, etc.
	;
doCopy:
	mov	bp, mask CQNF_COPY		;bp <- ClipboardQuickNotifyFlags
doRedraw:
	push	si, bp
	mov	si, di				;ds:si <- instance ptr
	call	CutCopyRedrawRange
	pop	si, bp
	jmp	done

doDefault:
	;-----------------------------------------------------------------------
	; no button overrides, determine default action

	tst	cl				; source = dest?
	je	doCopy				; copy if not
	jmp	short doMove			; else do move

noOp:
	;
	; there was no operation, we will restore the source selection
	;
	mov	ax, ds:[di].SSI_quickSource.CR_start.CR_column
	mov	ds:[di].SSI_selected.CR_start.CR_column, ax

	mov	ax, ds:[di].SSI_quickSource.CR_end.CR_column
	mov	ds:[di].SSI_selected.CR_end.CR_column, ax

	mov	ax, ds:[di].SSI_quickSource.CR_start.CR_row
	mov	ds:[di].SSI_selected.CR_start.CR_row, ax

	mov	ax, ds:[di].SSI_quickSource.CR_end.CR_row
	mov	ds:[di].SSI_selected.CR_end.CR_row, ax

	push	si
	mov	si, di				; ds:si <- instance ptr
	call	CutCopyRedrawRange
	pop	si

afterNoOp::
	mov	bp, mask CQNF_NO_OPERATION

done:
	tst	cl				; source = dest?
	je	endTransfer			; branch if not

	ornf	bp, mask CQNF_SOURCE_EQUAL_DEST

endTransfer:
	call	ClipboardEndQuickTransfer		; end quick-transfer
						;	(clears q-t item)

	mov	ax, mask MRF_PROCESSED		; accepted mouse event

	ret

flagNoOp:
	call	ClipboardDoneWithItem
	jmp	afterNoOp
SpreadsheetEndMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SpreadsheetGetClickedOnCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the coordinates of the cell that the mouse was clicked on.

CALLED BY:	INTERNAL (SpreadsheetStartMoveCopy, SpreadsheetEndMoveCopy)

PASS:		ds:di - Spreadsheet instance
		ss:bp - LargeMouseData

RETURN:		ax, cx - (r,c)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGetClickedOnCell	proc	near	uses	bx,si
	.enter
	mov	si, di			; ds:si <- Spreadsheet instance
	sub	sp, size PointDWord
	mov	bx, sp
	mov	ax, ss:[bp].PDF_x.DWF_int.high
	mov	ss:[bx].PD_x.high, ax
	mov	ax, ss:[bp].PDF_x.DWF_int.low
	mov	ss:[bx].PD_x.low, ax

	mov	ax, ss:[bp].PDF_y.DWF_int.high
	mov	ss:[bx].PD_y.high, ax
	mov	ax, ss:[bp].PDF_y.DWF_int.low
	mov	ss:[bx].PD_y.low, ax
	call	Pos32ToVisCellFar	; ax,cx <- (r,c)
	add	sp, size PointDWord
	.leave
	ret
SpreadsheetGetClickedOnCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SpreadsheetIsClickInBounds?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Is the mouse click within the bounds of the selected region?

CALLED BY:	INTERNAL (SpreadsheetStartMoveCopy)

PASS:		ds:di - Spreadsheet instance
		ax, cx - (r,c)

RETURN:		carry clear if click is within the selected region
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetIsClickInBounds?	proc	near
	class	SpreadsheetClass
	cmp	ax, ds:[di].SSI_selected.CR_start.CR_row
	jb	outOfBounds
	cmp	ax, ds:[di].SSI_selected.CR_end.CR_row
	ja	outOfBounds
	cmp	cx, ds:[di].SSI_selected.CR_start.CR_column
	jb	outOfBounds
	cmp	cx, ds:[di].SSI_selected.CR_end.CR_column
	ja	outOfBounds

	clc
	jmp	short done

outOfBounds:
	stc
done:
	ret
SpreadsheetIsClickInBounds?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SpreadsheetNotifyQuickTransferConcluded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle notification that a quick-transfer that we started
		has finished.

CALLED BY:	EXTERNAL (MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED)

PASS:		bp - ClipboardQuickNotifyFlags
		ds:di - Spreadsheet instance

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetNotifyQuickTransferConcluded	method	dynamic	SpreadsheetClass,
					MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED

	mov	si, di				; ds:si <- Spreadsheet instance
	mov	di, bp				; save ClipboardQuickNotifyFlags

	locals		local	CellLocals
	.enter

	test	di, mask CQNF_MOVE		; move operation?
	je	done				; done if not

	;
	; SSI_selected <- the source region
	; ax,bx,cx,dx, SSI_quickSource <- current region
	;

	mov	ax, ds:[si].SSI_quickSource.CR_start.CR_column
	xchg	ax, ds:[si].SSI_selected.CR_start.CR_column
	mov	ds:[si].SSI_quickSource.CR_start.CR_column, ax

	mov	bx, ds:[si].SSI_quickSource.CR_start.CR_row
	xchg	bx, ds:[si].SSI_selected.CR_start.CR_row
	mov	ds:[si].SSI_quickSource.CR_start.CR_row, bx

	mov	cx, ds:[si].SSI_quickSource.CR_end.CR_column
	xchg	cx, ds:[si].SSI_selected.CR_end.CR_column
	mov	ds:[si].SSI_quickSource.CR_end.CR_column, cx

	mov	dx, ds:[si].SSI_quickSource.CR_end.CR_row
	xchg	dx, ds:[si].SSI_selected.CR_end.CR_row
	mov	ds:[si].SSI_quickSource.CR_end.CR_row, dx

	;
	; clear the source region
	;
	push	cx
	clr	cx
	test	di, mask CQNF_SOURCE_EQUAL_DEST
	je	10$
	dec	cx
10$:
	mov	locals.CL_styleToken, -1	; init with illegal token
	mov	locals.CL_data1, cx
	call	SpreadsheetClearSource
	pop	cx

	;
	; restore the selected region
	;
	mov	ds:[si].SSI_selected.CR_start.CR_column, ax
	mov	ds:[si].SSI_selected.CR_start.CR_row, bx
	mov	ds:[si].SSI_selected.CR_end.CR_column, cx
	mov	ds:[si].SSI_selected.CR_end.CR_row, dx

	;
	; redraw the selected region
	;
	push	bp
	sub	sp, size CellLocals
	mov	bp, sp
	call	CutCopyRedrawRange	; destroys ax,bx,cx,dx,di
	add	sp, size CellLocals
	pop	bp

done:

	;
	; mark quick-transfer complete
	;
	andnf	ds:[si].SSI_flags, not mask SF_QUICK_TRANS_IN_PROGRESS

	.leave
	ret
SpreadsheetNotifyQuickTransferConcluded	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SpreadsheetClearSource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Clear the selected cells.

CALLED BY:	INTERNAL (SpreadsheetNotifyQuickTransferConcluded)

PASS:		ds:si - Spreadsheet instance
		cx - boolean - source ssheet = dest ssheet

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetClearSource	proc	near
	class	SpreadsheetClass
	uses	ax,bx,cx,dx,di
	locals	local	CellLocals
	.enter	inherit	near

	clr	di				;di <- data cells only
	mov	locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	locals.CL_params.REP_callback.offset, offset QuickCopyClearCell
	call	CallRangeEnumSelected		; destroys ax,bx,cx,dx,di

	.leave
	ret
SpreadsheetClearSource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	QuickCopyClearCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the current cell if it isn't part of the destination.

CALLED BY:	SpreadsheetClearSource() via CallRangeEnumSelected()

PASS:		ss:bp - ptr to CallRangeEnum() local variables
		ds:si - ptr to SpreadsheetInstance data
		    SSI_quickSource = destination
		(ax,cx) - cell coordinates (r,c)
		carry - set if data

RETURN:		carry - set to abort enum

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickCopyClearCell	proc	far
	class	SpreadsheetClass
	uses	ax, bx, di
	locals		local	CellLocals
	.enter	inherit	far

	;
	; if the spreadsheet is different, the bounds check need not be done
	;
	cmp	locals.CL_data1, 0
	je	clearCell

	;
	; check to see if cell is part of the destination region
	;
	cmp	ax, ds:[si].SSI_quickSource.CR_start.CR_row
	jb	clearCell				; branch if not in dest
	cmp	ax, ds:[si].SSI_quickSource.CR_end.CR_row
	ja	clearCell				; branch if not in dest

	cmp	cx, ds:[si].SSI_quickSource.CR_start.CR_column
	jb	clearCell				; branch if not in dest
	cmp	cx, ds:[si].SSI_quickSource.CR_end.CR_column
	jbe	done					; done if part of dest

clearCell:
	mov	dh, mask SCF_CLEAR_ATTRIBUTES or \
			mask SCF_CLEAR_DATA
	stc					;carry <- cell exists
	call	ClearCell			;dl <- RangeEnumFlags
	;
	; Recalculate any dependent cells we may have
	;
	call	RecalcCell			;recalc me jesus
;we are not called with REF_NO_LOCK (see SpreadsheetClearSource),
;so we don't need to return this.  We do need to have cells locked as
;ClearCell uses this.
;	;
;	; Add in REF_NO_LOCK, since we were called with this, and
;	; RangeEnum() will become upset if it is suddenly cleared.
;	;
;	ornf	dl, mask REF_NO_LOCK		;dl <- RangeEnumFlags
done:
	clc					;carry <- don't abort
	.leave
	ret
QuickCopyClearCell	endp

CutPasteCode	ends
