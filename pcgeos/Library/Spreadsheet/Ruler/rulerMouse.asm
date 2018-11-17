COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		rulerMouse.asm
FILE:		rulerMouse.asm

AUTHOR:		Gene Anderson, Jul 27, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	7/27/92		Initial revision

DESCRIPTION:
	

	$Id: rulerMouse.asm,v 1.1 97/04/07 11:13:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerGrabMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the mouse
CALLED BY:	UTILITY

PASS:		*ds:si - ruler object
		ds:di - ruler object
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerGrabMouse	proc	near
	uses	ax, cx, dx, bp
	class	SpreadsheetRulerClass
	.enter

	ornf	ds:[di].SRI_flags, mask SRF_HAVE_GRAB
	call	VisGrabLargeMouse
	;
	; Grab the gadget exclusive, too
	;
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	mov	dx, si
	mov	cx, ds:[LMBH_handle]
	call	ObjCallInstanceNoLock

	.leave
	ret
RulerGrabMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerReleaseMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the mouse
CALLED BY:	UTILITY

PASS:		*ds:si - spreadsheet object
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerReleaseMouse	proc	near
	uses	ax, cx, dx, bp, di
	class	SpreadsheetRulerClass
	.enter

	call	VisReleaseMouse
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	andnf	ds:[di].SRI_flags, not (mask SRF_HAVE_GRAB)
	;
	; Release the gadget exclusive, too
	;
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	mov	dx, si
	mov	cx, ds:[LMBH_handle]
	call	ObjCallInstanceNoLock

	.leave
	ret
RulerReleaseMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start of mouse selection
CALLED BY:	MSG_META_LARGE_START_SELECT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		ss:bp - ptr to LargeMouseData

RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
    Start select with:
    Ctrl key	Select flag	Action
    --------	-----------	------
    0		0		Regular start select
    0		1		Do nothing, let end select select region
    1		0		Set flag
    1		1		Do nothing, let end select select region

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetRulerStartSelect	method dynamic SpreadsheetRulerClass, \
						MSG_META_LARGE_START_SELECT
	;
	; See if our spreadsheet has the target
	;
	test	ds:[di].SRI_flags, mask SRF_SSHEET_IS_TARGET
	jnz	haveFocus
	;
	; The spreadsheet doesn't have the target -- make it so.
	; This is so if the spreadsheet is simply a layer in an application
	; that clicking on the rulers will make do something useful.
	;
	push	bp
	mov	ax, MSG_SPREADSHEET_MAKE_FOCUS
	call	CallSpreadsheet
	pop	bp
haveFocus:
	;
	; Grab the mouse
	;
	call	RulerGrabMouse
	sub	sp, (size SpreadsheetRangeParams)
	mov	bx, sp				;ss:bx <- range parameters
	call	RulerGetRowColumnAtPosition
	;
	; See if we're beginning a row/column resize
	;
	call	RulerCheckForResize
	jc	notResize			;branch if not resize
	;
	; See if we got a double click
	;
	pushf
	test	ss:[bp].LMD_buttonInfo, mask BI_DOUBLE_PRESS
	jz	notDoubleClick
	popf
	;
	; If it's a double-click, set the row height to automatic
	;
	mov_tr	dx, ax				;dx <- row/column to set
	mov	ax, MSG_SPREADSHEET_SET_ROW_HEIGHT
	jz	notHorizontalDouble
	mov	ax, MSG_SPREADSHEET_SET_COLUMN_WIDTH
notHorizontalDouble:
	mov	cx, ROW_HEIGHT_AUTOMATIC
	CheckHack <ROW_HEIGHT_AUTOMATIC eq COLUMN_WIDTH_BEST_FIT>
	call	CallSpreadsheet
	jmp	setResizePtr
	
notDoubleClick:
	popf					;z flag from RulerCheckForResize
	;
	; If we are beginning a resize, save the row/column and the position
	;
	mov	ds:[di].SRI_resizeRC, ax
	movdw	ds:[di].SRI_startRCPos, dxcx
setResizePtr:
	call	RulerResizeReturn_MRF_PROCESSED_SET_PTR
	jmp	done

notResize:
	mov	ds:[di].SRI_resizeRC, -1	;indicate not resize
	;
	; See if we're doing an extend or just a start select
	;
	mov	ax, MSG_SPREADSHEET_EXTEND_CONTRACT_SELECTION
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_EXTEND
	jnz	doSelection
	mov	ax, MSG_SPREADSHEET_SET_SELECTION
doSelection:
	mov	bp, bx				;ss:bp <- range paramters
	call	CallSpreadsheet
	call	RulerSelectReturn_MRF_PROCESSED_SET_PTR
done:
	add	sp, (size SpreadsheetRangeParams)
	ret
SpreadsheetRulerStartSelect	endm

RulerSelectReturn_MRF_PROCESSED_SET_PTR	proc	far
	mov	cx, handle PointerImages
	mov	dx, offset ptrSSheet		;^lcx:dx <- OD of ptr image
	mov	ax, mask MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
	ret
RulerSelectReturn_MRF_PROCESSED_SET_PTR	endp

RulerResizeReturn_MRF_PROCESSED_SET_PTR	proc	far
	class	SpreadsheetRulerClass
	mov	dx, offset ptrResizeRow
	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jz	notHorizontalResize
	mov	dx, offset ptrResizeColumn
notHorizontalResize:
	mov	cx, handle PointerImages	;^lcx:dx <- OD of ptr image
	mov	ax, mask MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
	ret
RulerResizeReturn_MRF_PROCESSED_SET_PTR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetRulerEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle end of drag select
CALLED BY:	MSG_META_LARGE_END_SELECT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetRulerClass
		ax - the method

		ss:bp - ptr to LargeMouseData

RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetRulerEndSelect	method dynamic SpreadsheetRulerClass,
						MSG_META_LARGE_END_SELECT
	call	SpreadsheetRulerStartMouse
	;
	; See if we're in the middle of resizing a row or column
	;
	cmp	ds:[di].SRI_resizeRC, -1
	je	notResize			;branch if not a resize
	;
	; Figure out how far we've moved and tell the spreadsheet
	; to change the row/column height/width by that much.
	;
	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	movdw	dxcx, ss:[bp].LMD_location.PDF_y.DWF_int
	mov	ax, MSG_SPREADSHEET_CHANGE_ROW_HEIGHT
	jz	sendResize
	movdw	dxcx, ss:[bp].LMD_location.PDF_x.DWF_int
	mov	ax, MSG_SPREADSHEET_CHANGE_COLUMN_WIDTH
sendResize:
	subdw	dxcx, ds:[di].SRI_startRCPos
	jcxz	noChange			;branch if no change
	mov	dx, ds:[di].SRI_resizeRC	;dx <- resize column
	call	CallSpreadsheet
noChange:
	call	RulerReleaseMouse
	GOTO	RulerResizeReturn_MRF_PROCESSED_SET_PTR

	;
	; Release the mouse
	;
notResize:
	call	RulerReleaseMouse		;release the ptr
	GOTO	RulerSelectReturn_MRF_PROCESSED_SET_PTR
SpreadsheetRulerEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetRulerPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse pointer events
CALLED BY:	MSG_META_LARGE_PTR

PASS:		ds:*si - ptr to SpreadsheetRuler instance
		ds:di - *ds:si
		ax - MSG_META_LARGE_PTR

		ss:bp - ptr to LargeMouseData

RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetRulerPtr	method	static	SpreadsheetRulerClass,
							MSG_META_LARGE_PTR

	call	SpreadsheetRulerStartMouse
	sub	sp, (size SpreadsheetRangeParams)
	mov	bx, sp				;ss:bx <- range parametersn
	call	RulerGetRowColumnAtPosition
	;
	; Ignore pointer events if we aren't selecting or don't have
	; the grab
	;
	test	ds:[di].SRI_flags, mask SRF_HAVE_GRAB
	jz	notGrabbed
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_SELECT
	jz	noFeedback
	;
	; See if we're in the middle of a resize
	;
	cmp	ds:[di].SRI_resizeRC, -1
	je	notResize
	call	RulerResizeReturn_MRF_PROCESSED_SET_PTR
	jmp	done

	;
	; Send the extend selection message to the spreadsheet
	;
notResize:
	push	bp
	mov	bp, bx				;ss:bp <- range parameters
	mov	ax, MSG_SPREADSHEET_EXTEND_CONTRACT_SELECTION
	call	CallSpreadsheet
	pop	bp
	;
	; Set the pointer image
	;
setPtr:
	call	RulerSelectReturn_MRF_PROCESSED_SET_PTR
	jmp	done

	;
	; If there is some sort of selection action going on,
	; we can provide feedback.  Otherwise, we shouldn't muck
	; with the cursor...
	;
notGrabbed:
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_SELECT or \
						mask UIFA_MOVE_COPY or \
						mask UIFA_FEATURES
	jz	checkResize
	;
	; Don't set the pointer image
	;
noFeedback:
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
done:
	add	sp, (size SpreadsheetRangeParams)
	ret

	;
	; See if we're close enough to the edge of a row/column
	; to provide resize feedback
	;
checkResize:
	call	RulerCheckForResize
	jc	setPtr				;branch if not resize
	call	RulerResizeReturn_MRF_PROCESSED_SET_PTR
	jmp	done
SpreadsheetRulerPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetRulerDragSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle beginning of drag select
CALLED BY:	MSG_META_LARGE_DRAG_SELECT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		ss:bp - ptr to LargeMouseData

RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetRulerDragSelect	method dynamic SpreadsheetRulerClass,
						MSG_META_LARGE_DRAG_SELECT
	call	SpreadsheetRulerStartMouse
	cmp	ds:[di].SRI_resizeRC, -1
	je	notResize
	GOTO	RulerResizeReturn_MRF_PROCESSED_SET_PTR
notResize:
	GOTO	RulerSelectReturn_MRF_PROCESSED_SET_PTR
SpreadsheetRulerDragSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetLostGadgetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle loss of gadget exclusive...

CALLED BY:	MSG_VIS_LOST_GADGET_EXCL

PASS:		ds:*si - ptr to instance data
		ds:di - ptr to instance data
		es - segment of SpreadsheetClass
		ax = MSG_VIS_LOST_GADGET_EXCL.

RETURN:		none
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetLostGadgetExcl	method	SpreadsheetRulerClass,
							MSG_VIS_LOST_GADGET_EXCL
	call	RulerReleaseMouse
	ret
SpreadsheetLostGadgetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerGetRowColumnAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get row or column at mouse position

CALLED BY:	UTILITY
PASS:		ss:bp - ptr to LargeMouseData
		ss:bx - ptr to SpreadsheetRangeParams
RETURN:		ss:bx - filled in for row/column selection
		ax - row/column at position
		cx - distance to row/column edge
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerGetRowColumnAtPosition		proc	near
	class	SpreadsheetRulerClass
	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jz	RulerGetRowAtPosition
	FALL_THRU RulerGetColumnAtPosition
RulerGetRowColumnAtPosition		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerGetColumnAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the column at the specified mouse position
CALLED BY:	UTILITY

PASS:		ss:bp - ptr to LargeMouseData
		ss:bx - ptr to SpreadsheetRangeParams
RETURN:		ss:bx - filled in for column selection
		ax - column at position
		cx - distance to column edge
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerGetColumnAtPosition	proc	near
	uses	bp
	.enter

	movdw	dxcx, ss:[bp].LMD_location.PDF_x.DWF_int
	mov	ax, MSG_SPREADSHEET_GET_COLUMN_AT_POSITION
	call	CallSpreadsheet
	mov	ss:[bx].SRP_active.CR_row, SPREADSHEET_ADDRESS_ON_SCREEN
	mov	ss:[bx].SRP_active.CR_column, ax
	mov	ss:[bx].SRP_selection.CR_start.CR_row, 0
	mov	ss:[bx].SRP_selection.CR_end.CR_row, SPREADSHEET_ADDRESS_PAST_END
	mov	ss:[bx].SRP_selection.CR_start.CR_column, ax
	mov	ss:[bx].SRP_selection.CR_end.CR_column, ax

	.leave
	ret
RulerGetColumnAtPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerGetRowAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the column at the specified mouse position
CALLED BY:	UTILITY

PASS:		ss:bp - ptr to LargeMouseData
		ss:bx - ptr to SpreadsheetRangeParams
RETURN:		ss:bx - filled in for row selection
		ax - row at position
		cx - distance to row edge
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerGetRowAtPosition	proc	near
	uses	bp
	.enter

	movdw	dxcx, ss:[bp].LMD_location.PDF_y.DWF_int
	mov	ax, MSG_SPREADSHEET_GET_ROW_AT_POSITION
	call	CallSpreadsheet
	mov	ss:[bx].SRP_active.CR_row, ax
	mov	ss:[bx].SRP_active.CR_column, SPREADSHEET_ADDRESS_ON_SCREEN
	mov	ss:[bx].SRP_selection.CR_start.CR_row, ax
	mov	ss:[bx].SRP_selection.CR_end.CR_row, ax
	mov	ss:[bx].SRP_selection.CR_start.CR_column, 0
	mov	ss:[bx].SRP_selection.CR_end.CR_column, SPREADSHEET_ADDRESS_PAST_END

	.leave
	ret
RulerGetRowAtPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetRulerStartMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to start SpreadsheetRuler mouse events
CALLED BY:	UTILITY

PASS:		*ds:si - ptr to SpreadsheetRuler
		ds:di - *ds:si
RETURN:		doesn't if spreadsheet not focus
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Must be called by a far routine or method handler
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetRulerStartMouse	proc	near
	class	SpreadsheetRulerClass
	test	ds:[di].SRI_flags, mask SRF_SSHEET_IS_FOCUS
	jz	resetPtr			;branch if not focus
	ret

resetPtr:
	pop	ax				;remove caller's address
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	retf					;returns to caller's caller
SpreadsheetRulerStartMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetRulerSetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Corresponding spreadsheet has gained the target
CALLED BY:	MSG_SPREADSHEET_RULER_GAINED_TARGET

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetRulerClass
		ax - the message

		dl - SpreadsheetRulerFlags to set
		dh - SpreadsheetRulerFlags to clear

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetRulerSetFlags	method dynamic SpreadsheetRulerClass, \
					MSG_SPREADSHEET_RULER_SET_FLAGS
	push	dx
	not	dh				;dh <- stuff to save
	andnf	ds:[di].SRI_flags, dh		;clear stuff
	ornf	ds:[di].SRI_flags, dl		;set stuff
	pop	dx
	;
	; Tell the other ruler, if any, about the change
	;
	FALL_THRU	SpreadsheetRulerSendToSlave
SpreadsheetRulerSetFlags	endm

SpreadsheetRulerSendToSlave	proc	far
	class	VisRulerClass
	movdw	bxsi, ds:[di].VRI_slave
	clr	di
	GOTO	ObjMessage
SpreadsheetRulerSendToSlave	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerCheckForResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're close enough to an edge to do resize

CALLED BY:	UTILITY
PASS:		*ds:di - ruler object
		ss:bp - LargeMouseData
		ax, cx, dx - row/column, etc. from RulerGetColumnAtPosition()
RETURN:		carry - clear if doing resize
		    ax - row/column for resize
		    dxcx - x or y of LargeMouseData
		    z flag - clear (JNZ) if horizontal ruler
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerCheckForResize		proc	near
	class	SpreadsheetRulerClass

	test	ds:[di].SRI_flags, mask SRF_NO_INTERACTIVE_RESIZE
	jnz	notResize

	cmp	cx, -RESIZE_FEEDBACK_THRESHOLD
	jge	isResize			;branch if resizing

	cmp	dx, RESIZE_FEEDBACK_THRESHOLD
	jg	notResize

	; We're close to the left edge, so resize the previous column
	; instead. 
	dec	ax

isResize:
	;
	; Following test:
	; - clears the carry
	; - clears the Z flag if horizontal
	;
	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	;
	; Get the x or y value as appropriate
	;
	movdw	dxcx, ss:[bp].LMD_location.PDF_x.DWF_int
	jnz	isHorizontal
	movdw	dxcx, ss:[bp].LMD_location.PDF_y.DWF_int
isHorizontal:
	ret

notResize:
	stc	
	ret
RulerCheckForResize		endp

RulerCode	ends
