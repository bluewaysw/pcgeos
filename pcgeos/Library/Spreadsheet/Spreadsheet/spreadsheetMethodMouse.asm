COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetMethodMouse.asm

AUTHOR:		Gene Anderson, Mar 29, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/29/91		Initial revision

DESCRIPTION:
	Routines and method handlers for mouse input

	$Id: spreadsheetMethodMouse.asm,v 1.1 97/04/07 11:13:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartLargeMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start of large mouse message.
CALLED BY:	SpreadsheetStartSelect(), SpreadsheetPtr()

PASS:		ss:bp - ptr to LargeMouseData
RETURN:		ss:bx - ptr to PointDWord for mouse event
		bp.low - ButtonInfo
		bp.high - UIFunctionsActive
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If the mouse position is negative, zero is returned.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StartLargeMouse	proc	near
	pop	dx				;dx <- return address
	;
	; Make sure the y position is non-negative
	;
	mov	ax, ss:[bp].LMD_location.PDF_y.DWF_int.high
	mov	bx, ss:[bp].LMD_location.PDF_y.DWF_int.low
	tst	ax
	jns	yOK
	clr	ax
	mov	bx, ax				;ax:bx <- y position
yOK:
	push	ax				;pass PD_y.high
	push	bx				;pass PD_y.low
	;
	; make sure the x position is non-negative
	;
	mov	ax, ss:[bp].LMD_location.PDF_x.DWF_int.high
	mov	bx, ss:[bp].LMD_location.PDF_x.DWF_int.low
	tst	ax
	jns	xOK
	clr	ax
	mov	bx, ax				;ax:bx <- x position
xOK:
	push	ax				;pass PD_x.high
	push	bx				;pass PD_x.low
	;
	; Return stack frame, button info
	;
	mov	bx, sp				;ss:bx <- ptr to PointDWord
	mov	bp, {word}ss:[bp].LMD_buttonInfo
	jmp	dx				;jump to return address
StartLargeMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the mouse
CALLED BY:	UTILITY

PASS:		*ds:si - spreadsheet object
		ds:di - spreadsheet object
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrabMouse	proc	far
	uses	ax, cx, dx, bp
	class	SpreadsheetClass
	.enter

EC <	push	si				;>
EC <	mov	si, di				;>
EC <	call	ECCheckInstancePtr		;>
EC <	pop	si				;>
;EC <	test	ds:[di].SSI_flags, mask SF_HAVE_GRAB >
;EC <	ERROR_NZ SPREADSHEET_ALREADY_HAS_MOUSE_GRAB >
	ornf	ds:[di].SSI_flags, mask SF_HAVE_GRAB
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
GrabMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReleaseMouse
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

ReleaseMouse	proc	far
	uses	ax, cx, dx, bp, di
	class	SpreadsheetClass
	.enter

	call	VisReleaseMouse
	mov	di, ds:[si]
	add	di, ds:[di].Spreadsheet_offset
EC <	test	ds:[di].SSI_flags, mask SF_HAVE_GRAB >
EC <	ERROR_Z SPREADSHEET_DOESNT_HAVE_MOUSE_GRAB >
	andnf	ds:[di].SSI_flags, not (mask SF_HAVE_GRAB)
	;
	; Release the gadget exclusive, too
	;
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	mov	dx, si
	mov	cx, ds:[LMBH_handle]
	call	ObjCallInstanceNoLock

	.leave
	ret
ReleaseMouse	endp


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
	V2.0 CHANGE: 32-bit mouse events

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/91		Initial version
	cheng	2/92		Added code for Ctrl selection

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetStartSelect	method dynamic SpreadsheetClass, \
						MSG_META_LARGE_START_SELECT
	.enter

EC <	test	ds:[di].SSI_attributes, mask SA_ENGINE_MODE >
EC <	ERROR_NZ MESSAGE_NOT_HANDLED_IN_ENGINE_MODE >
	;
	; Grab the mouse
	;
	call	GrabMouse
	;
	;
	;
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_EXTEND
	jnz	returnProcessed

	mov	si, di				;ds:si <- ptr to instance
	;
	; Deselect any current range
	;
	call	DeselectRange			;deselect any range
	;
	; Get the cell under the mouse
	;
	call	StartLargeMouse
	call	Pos32ToVisCell			;(ax,cx) <- row,column
	add	sp, (size PointDWord)
	call	MoveActiveCellFar
	;
	; Double click?  If not, we're done.
	;
	test	bp, mask BI_DOUBLE_PRESS	;check for double click
	jz	returnProcessed			;branch if not double click
	;
	; Double click. Bring up a note if one exists.
	;
	call	BringUpNoteIfOneExists		;bring up the note
	jnc	returnProcessed			;branch if no note

	;
	; Release the mouse so we won't select while we're bringing up the note
	;
	mov	si, ds:[si].SSI_chunk
	call	ReleaseMouse

returnProcessed:
	.leave
	GOTO	Return_MRF_PROCESSED_SET_PTR
SpreadsheetStartSelect	endm

Return_MRF_PROCESSED_SET_PTR	proc	far
	mov	cx, handle ptrSSheet
	mov	dx, offset ptrSSheet		;^lcx:dx <- OD of ptr
	mov	ax, mask MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
	ret
Return_MRF_PROCESSED_SET_PTR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BringUpNoteIfOneExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up a note for the current cell if one exists.

CALLED BY:	SpreadsheetStartSelect
PASS:		ds:si	= Instance ptr
RETURN:		z flag - clear if a note exists for the active cell
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BringUpNoteIfOneExists	proc	near
	class	SpreadsheetClass
	uses	ax, cx, dx
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row	;ax <- row
	mov	cx, ds:[si].SSI_active.CR_column	; cx <- column
	mov	dl, mask SDCF_MOUSE_CLICK	;dl <- SpreadsheetDoubleClick
	call	SendBringUpNote

	.leave
	ret
BringUpNoteIfOneExists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendBringUpNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to our subclass to tell them about a double-click

CALLED BY:	BringUpNoteIfOneExists()
PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx) - (r,c) of cell to send message for
		dl - SpreadsheetDoubleClickFlags to send
RETURN:		z flag - clear if a note exists for the active cell
		dl - nrw SpreadsheetDoubleClickFlags
		dh - CellType
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendBringUpNote		proc	far
	class	SpreadsheetClass
	uses	ax, cx, es, di, si, bp
	.enter

	mov	dh, CT_EMPTY			;
	SpreadsheetCellLock			; *es:di <- cell data
	jnc	sendMessage			; Branch if no cell

	;
	; Cell exists, check for a note.
	;
	mov	di, es:[di]
	mov	di, es:[di].CC_notes.handle	; di <- 0 if there is no note
	ornf	dl, mask SDCF_CELL_EXISTS	;dl <- mark cell as existing
	mov	dh, es:[di].CC_type		;dh <- CellType

	SpreadsheetCellUnlock			; Release the cell

	tst	di				; Check for a note
	jz	sendMessage			; Branch if no note
	ornf	dl, mask SDCF_NOTE_EXISTS
	;
	; There is a note. We want to notify our subclass so that it can
	; bring the note up on the screen.
	;
sendMessage:
	push	dx
	mov	ax, MSG_SPREADSHEET_DISPLAY_NOTE
	mov	si, ds:[si].SSI_chunk
	call	ObjCallInstanceNoLock		; Display the note
	pop	dx

	test	dx, mask SDCF_NOTE_EXISTS	;clears carry
	;
	; z flag clear if the cell contained a note
	;
	.leave
	ret
SendBringUpNote		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetDragSelect
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

SpreadsheetDragSelect	method dynamic SpreadsheetClass, MSG_META_LARGE_DRAG_SELECT
EC <	test	ds:[di].SSI_attributes, mask SA_ENGINE_MODE >
EC <	ERROR_NZ MESSAGE_NOT_HANDLED_IN_ENGINE_MODE >
	GOTO	Return_MRF_PROCESSED_SET_PTR
SpreadsheetDragSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle end of drag select
CALLED BY:	MSG_META_LARGE_END_SELECT

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

SpreadsheetEndSelect	method dynamic SpreadsheetClass, MSG_META_LARGE_END_SELECT

EC <	test	ds:[di].SSI_attributes, mask SA_ENGINE_MODE >
EC <	ERROR_NZ MESSAGE_NOT_HANDLED_IN_ENGINE_MODE >
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_EXTEND
	jz	noCtrlSelection
	;
	; Let the PTR handler deal with ctrl selection
	;
	ornf	ss:[bp].LMD_uiFunctionsActive, mask UIFA_SELECT
	push	si
	call	SpreadsheetPtr
	pop	si
	;
	; re-dereference di, since we've called a message handler
	;
	mov	di, ds:[si]
	add	di, ds:[di].Spreadsheet_offset

noCtrlSelection:
	call	ReleaseMouse			;release the ptr
	;
	; Notify the UI of style change
	;
	mov	si, di				;ds:si <- ptr to instance data
	call	SS_SendNotificationSelectAdd	;update the UI
	GOTO	Return_MRF_PROCESSED_SET_PTR
SpreadsheetEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse drags
CALLED BY:	MSG_META_LARGE_PTR

PASS:		ds:*si - ptr to Spreadsheet instance
		ds:di - *ds:si
		ax - MSG_META_LARGE_PTR

		ss:bp - ptr to LargeMouseData

RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	The active cell acts as an anchor point -- any mouse selection
	uses it as the opposite corner for the selection.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetPtr	method	static	SpreadsheetClass,  MSG_META_LARGE_PTR

EC <	test	ds:[di].SSI_attributes, mask SA_ENGINE_MODE >
EC <	ERROR_NZ MESSAGE_NOT_HANDLED_IN_ENGINE_MODE >

	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_MOVE_COPY
	jne	checkQuickTransfer

	;
	; Ignore pointer events if we aren't selecting or don't have
	; the grab
	;
	test	ds:[di].SSI_flags, mask SF_HAVE_GRAB
	jz	notGrabbed

	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_SELECT
	jz	checkQuickTransfer

	mov	si, di				;ds:si <- ptr to instance
	call	StartLargeMouse
	;
	; Get the cell under the mouse and change the selection
	;
	call	Pos32ToVisCell			;(ax,cx) <- row,column
	add	sp, (size PointDWord)
	mov	dx, ax
	mov	bp, cx				;(dx,bp) <- end row,column
	call	AddAnchoredSelection
setPtr:
	GOTO	Return_MRF_PROCESSED_SET_PTR

notGrabbed:
	;
	; If there isn't some sort of selection action going on,
	; we can provide feedback.  Otherwise, we shouldn't muck
	; with the cursor...
	;
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_SELECT or \
						mask UIFA_MOVE_COPY or \
						mask UIFA_FEATURES
	jz	setPtr
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	ret

checkQuickTransfer:
	;***********************************************************************
	; right button pressed

	call	ClipboardGetQuickTransferStatus	; really in progress?
	jz	done				; done if not

	test	ds:[di].SSI_flags, mask SF_IN_VIEW	; "in view"?
	jz	done				; no, skip feedback

if 0
	test	ds:[di].SSI_flags, mask SF_QUICK_TRANS_IN_PROGRESS
	jne	done
endif

	test	ds:[di].SSI_flags, mask SF_HAVE_GRAB
	jnz	5$
	call	GrabMouse
5$:

	;
	; need to check the current quick-transfer item to see if it supports
	; the CIF_SPREADSHEET format
	;
	; pushes & pops indented
	;
    push	bp				;
	mov	bp, mask CIF_QUICK
	call	ClipboardQueryItem		; bp = # formats, cx:dx = owner
						; bx:ax = VM file:VM block
	tst	bp				; any formats?
	stc
	jz	10$				; none (carry set)
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_SPREADSHEET
	call	ClipboardTestItemFormat		; is CIF_SPREADSHEET there?
						; (carry clear if so)
10$:
     pushf					; save result flag
      push	ax
	call	ClipboardGetItemInfo		; cx:dx <- sourceID
	mov	ax, CQTF_MOVE			; assume MOVE
	cmp	cx, ds:LMBH_handle
	jne	different
	cmp	dx, si
	jne	opDetermined
different:
	mov	ax, CQTF_COPY			; modify to COPY
opDetermined:
	mov	si, ax				; si <- operation
      pop	ax

	call	ClipboardDoneWithItem
     popf					; retreive result flag
    pop		bp				; retrieve UIFunctionsActive
	;
	; now, set the mouse pointer shape to provide feedback
	;	carry = clear if CIF_SPREADSHEET supported
	;
	mov	ax, si
	jnc	haveCursor
	mov	ax, CQTF_CLEAR			; not supported -> clear cursor

haveCursor:
	push	bp
	mov	bh, ss:[bp].LMD_uiFunctionsActive
	clr	bl
	mov	bp, bx
	call	ClipboardSetQuickTransferFeedback	; set cursor
	ornf	ds:[di].SSI_flags, mask SF_DOING_FEEDBACK
	pop	bp

done:
	GOTO	Return_MRF_PROCESSED_SET_PTR
SpreadsheetPtr	endp

DrawCode	ends
