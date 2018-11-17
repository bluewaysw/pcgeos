COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetMethodSelect.asm

AUTHOR:		Gene Anderson, Mar 20, 1991

ROUTINES:
	Name			Description
	----			-----------
EXT	DeselectRange		Deselect range

EXT	ContractSelectionDown	contract selection downward
EXT	ContractSelectionUp	contract selection upward
EXT	ContractSelectionRight	contract selection towards right
EXT	ContractSelectionLeft	contract selection towards left

EXT	ExtendSelectionDown	extend selection downward
EXT	ExtendSelectionUp	extend selection upward
EXT	ExtendSelectionRight	extend selection towards right
EXT	ExtendSelectionLeft	extend selection towards left

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/20/91		Initial revision

DESCRIPTION:
	Routines and method handlers for selecting cells.

	$Id: spreadsheetMethodSelect.asm,v 1.1 97/04/07 11:13:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContractSelectionDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Contract the selected area downwards to specified row
CALLED BY:	CalcKbdShiftDown()

PASS:		ds:si - ptr to Spreadsheet instance
		ax - new top row of selection
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContractSelectionDown	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	push	ax, bx, cx, dx, di, bp
	call	CreateGState			;di <- handle of GState

	mov	dx, ax				;dx <- new top of selection
	dec	dx				;dx <- bottom of range
	xchg	ax, ds:[si].SSI_selected.CR_start.CR_row

	GOTO	RowFinishSelection, bp, di, dx, cx, bx, ax
ContractSelectionDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContractSelectionUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Contract the selected area upwards to specified row
CALLED BY:	CalcKbdShiftUp()

PASS:		ds:si - ptr to Spreadsheet instance data
		ax - new bottom row of selection
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContractSelectionUp	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	push	ax, bx, cx, dx, di, bp
	call	CreateGState			;di <- handle of GState

	mov	dx, ax				;dx <- new bottom of selection
	inc	ax				;ax <- top of range
	xchg	dx, ds:[si].SSI_selected.CR_end.CR_row ;dx <- (old) bottom of range

	GOTO	RowFinishSelection, bp, di, dx, cx, bx, ax

ContractSelectionUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtendSelectionDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend selection down to include specified row
CALLED BY:	CalcKbdShiftDown()

PASS:		ds:si - ptr to Spreadsheet instance
		ax - row to include
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtendSelectionDown	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	cmp	ax, ds:[si].SSI_maxRow		;too large?
	ja	done

	push	ax, bx, cx, dx, di, bp
	call	CreateGState			;di <- handle of GState

	mov	dx, ax				;dx <- bottom of range
	xchg	ds:[si].SSI_selected.CR_end.CR_row, ax
	inc	ax				;ax <- top of range
	GOTO	RowFinishSelection, bp, di, dx, cx, bx, ax

done:
	ret
ExtendSelectionDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtendSelectionUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend selection up to include specified row
CALLED BY:	CalcKbdShiftUp()

PASS:		ds:si - ptr to Spreadsheet instance
		ax - row to include
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtendSelectionUp	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	push	ax, bx, cx, dx, di, bp
	call	CreateGState			;di <- handle of GState

	mov	dx, ax				;dx <- bottom of range
	xchg	ds:[si].SSI_selected.CR_start.CR_row, dx
	dec	dx				;dx <- bottom of range
	FALL_THRU	RowFinishSelection, bp, di, dx, cx, bx, ax

ExtendSelectionUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowFinishSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish up row (de)selection.
CALLED BY:	ExtendSelectionRow()

PASS:		ds:si - ptr to Spreadsheet instance
		di - handle of GState
		ax - start row to invert
		dx - end row to invert
		on stack:
			ax,bx,cx,dx,di,bp
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowFinishSelection	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bp, ds:[si].SSI_selected.CR_end.CR_column
	xchg	dx, bp
	call	InvertSelectedVisibleRange

	call	DestroyGState
	FALL_THRU_POP	bp, di, dx, cx, bx, ax
	ret
RowFinishSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContractSelectionRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Contract selection to the right to specified column
CALLED BY:	CalcKbdShiftRight()

PASS:		ds:si - ptr to Spreadsheet instance
		cx - new left column of selection
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContractSelectionRight	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	push	ax, bx, cx, dx, di, bp
	call	CreateGState			;di <- handle of GState

	mov	bp, cx				;bp <- new left of selection
	dec	bp				;bp <- right of range
	xchg	cx, ds:[si].SSI_selected.CR_start.CR_column	;cx <- (old) left of range

	GOTO	ColumnFinishSelection, bp, di, dx, cx, bx, ax
ContractSelectionRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContractSelectionLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Contract selection to the left to specified column
CALLED BY:	CalcKbdShiftLeft()

PASS:		ds:si - ptr to Spreadsheet instace
		cx - new right column of selection
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContractSelectionLeft	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	push	ax, bx, cx, dx, di, bp
	call	CreateGState			;di <- handle of GState

	mov	bp, cx				;bp <- new right of selection
	inc	cx				;cx <- left of range
	xchg	bp, ds:[si].SSI_selected.CR_end.CR_column ;bp <- right of range

	GOTO	ColumnFinishSelection, bp, di, dx, cx, bx, ax
ContractSelectionLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtendSelectionRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend selection to the right to include specified column
CALLED BY:	CalcKbdShiftRight()

PASS:		ds:si - ptr to Spreadsheet instance
		cx - column to include
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtendSelectionRight	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	cmp	cx, ds:[si].SSI_maxCol		;too large?
	ja	done

	push	ax, bx, cx, dx, di, bp
	call	CreateGState			;di <- handle of GState

	mov	bp, cx				;bp <- right of range
	xchg	ds:[si].SSI_selected.CR_end.CR_column, cx
	inc	cx				;cx <- left of range
	GOTO	ColumnFinishSelection, bp, di, dx, cx, bx, ax

done:
	ret
ExtendSelectionRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtendSelectionLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend selection to the left to include specified column
CALLED BY:	CalcKbdShiftLeft()

PASS:		ds:si - ptr to Spreadsheet instance
		cx - column to include
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtendSelectionLeft	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	push	ax, bx, cx, dx, di, bp
	call	CreateGState			;di <- handle of GState

	mov	bp, cx				;bp <- right of range
	xchg	ds:[si].SSI_selected.CR_start.CR_column, bp
	dec	bp				;bp <- right of range
	FALL_THRU	ColumnFinishSelection, bp, di, dx, cx, bx, ax
ExtendSelectionLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnFinishSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish column (de)selection
CALLED BY:	{Extend,Contract}Selection{Left,Right}()

PASS:		ds:si - ptr to Spreadsheet instance
		di - handle of GState
		cx - start column to invert
		bp - end column to invert
		on stack:
			ax,bx,cx,dx,di,bp
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColumnFinishSelection	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
	xchg	dx, bp
	call	InvertSelectedVisibleRange

	call	DestroyGState
	FALL_THRU_POP bp, di, dx, cx, bx, ax
	ret
ColumnFinishSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeselectRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Visually deselect the selected range of cells
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeselectRange	proc	near
	uses	ax, bx, cx, dx, di, bp
	class	SpreadsheetClass

	.enter

EC <	call	ECCheckInstancePtr		;>
	call	SingleCell?
	jc	afterDeselect

	call	CreateGState

	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column
	call	InvertActiveVisibleCell		;unactivate current cell

	call	InvertSelectedVisibleCell	;invert to allow rectangle

	call	InvertRangeAndActiveCell	;erase range and display cell

	mov	ds:[si].SSI_selected.CR_start.CR_row, ax
	mov	ds:[si].SSI_selected.CR_start.CR_column, cx
	mov	ds:[si].SSI_selected.CR_end.CR_row, ax
	mov	ds:[si].SSI_selected.CR_end.CR_column, cx
	call	DestroyGState

afterDeselect:

	.leave
	ret
DeselectRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertRangeAndActiveCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert the current range and the active cell.

CALLED BY:	DeselectRange, SetSelectedRange, SpreadsheetInvertRangeLast
PASS:		ds:si	= Pointer to the spreadsheet
		di	= gstate to use
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertRangeAndActiveCell	proc	near
	class	SpreadsheetClass
	uses	ax, cx, dx, bp
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bp, ds:[si].SSI_selected.CR_end.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	call	InvertSelectedVisibleRange	;Invert selected range

	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column
	call	InvertActiveVisibleCell		;Invert current cell
	.leave
	ret
InvertRangeAndActiveCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSelectedRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a new selected range. Force the active cell to be the
		top left cell of the range.

CALLED BY:	GotoCell
PASS:		ds:si	= Pointer to spreadsheet instance
		ax/cx	= Row/column of first cell in range
		dx/bp	= Row/column of last cell in range
RETURN:		carry - set if selection changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtendSelectedRangeNotify	proc	far
	call	SetSelectedRange
	jnc	noNotify			;branch if no change
	call	SS_SendNotificationSelectAdd
noNotify:
	ret
ExtendSelectedRangeNotify	endp

SetSelectedRangeNotify	proc	far
	call	SetSelectedRange
	jnc	noNotify			;branch if no change
	call	SS_SendNotificationSelectChange
noNotify:
	ret
SetSelectedRangeNotify	endp
	
SetSelectedRange	proc	far
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, di
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	bx, bp
	call	OrderRangeArgs		; make sure args are ordered
	mov	bp, bx
	;
	; Make sure the selection is changing
	;
	cmp	ax, ds:[si].SSI_selected.CR_start.CR_row
	jne	checkSelection
	cmp	cx, ds:[si].SSI_selected.CR_start.CR_column
	jne	checkSelection
	cmp	dx, ds:[si].SSI_selected.CR_end.CR_row
	jne	checkSelection
	cmp	bp, ds:[si].SSI_selected.CR_end.CR_column
	clc					;carry <- in case of exit
	LONG je	quit
checkSelection:
	;
	; We've got the same number of rows
	;
	; Extend or contract the left side, if the right side is set
	;
	cmp	bp, ds:[si].SSI_selected.CR_end.CR_column
	jne	checkRight			;branch if bottom not set
	cmp	cx, ds:[si].SSI_selected.CR_start.CR_column
	jb	extendLeft
	je	checkRight
	call	ContractSelectionRight
	jmp	checkRight
extendLeft:
	call	ExtendSelectionLeft
	;
	; Extend or contract the right side, if the left side is set
	;
checkRight:
	cmp	cx, ds:[si].SSI_selected.CR_start.CR_column
	jne	noOptRows			;branch if left side not set
	push	cx
	mov	cx, bp				;cx <- column to include
	cmp	cx, ds:[si].SSI_selected.CR_end.CR_column
	ja	extendRight
	je	doneColumns
	call	ContractSelectionLeft
	jmp	doneColumns
extendRight:
	call	ExtendSelectionRight
doneColumns:
	pop	cx
noOptRows:
	;
	; We've got the same number of columns
	;
	; Extend or contract the top, if the bottom is set
	;
	cmp	dx, ds:[si].SSI_selected.CR_end.CR_row
	jne	checkBottom			;branch if bottom not set
	cmp	ax, ds:[si].SSI_selected.CR_start.CR_row
	jb	extendUp
	je	checkBottom
	call	ContractSelectionDown
	jmp	checkBottom
extendUp:
	call	ExtendSelectionUp
	;
	; Extend or contract the bottom, if the top is set
	;
checkBottom:
	cmp	ax, ds:[si].SSI_selected.CR_start.CR_row
	jne	noOptColumns			;branch if top not set
	push	ax
	mov	ax, dx				;ax <- row to include
	cmp	ax, ds:[si].SSI_selected.CR_end.CR_row
	ja	extendDown
	je	doneRows
	call	ContractSelectionUp
	jmp	doneRows
extendDown:
	call	ExtendSelectionDown
doneRows:
	pop	ax
noOptColumns:
	;
	; Make sure the selection is still going to change
	;
	cmp	ax, ds:[si].SSI_selected.CR_start.CR_row
	jne	setSelection
	cmp	cx, ds:[si].SSI_selected.CR_start.CR_column
	jne	setSelection
	cmp	dx, ds:[si].SSI_selected.CR_end.CR_row
	jne	setSelection
	cmp	bp, ds:[si].SSI_selected.CR_end.CR_column
	je	sendNotification
setSelection:
	call	CreateGState		; di <- gstate to use for drawing
	;
	; Remove the current range. This routine leaves the active cell
	; still visible on the screen.
	;
	call	DeselectRange		; Remove old range from the screen
	;
	; Remove the active cell from the screen.
	;
	push	ax, cx			; Save passed cell
	mov	ax, ds:[si].SSI_active.CR_row	; ax <- row
	mov	cx, ds:[si].SSI_active.CR_column	; cx <- column
	call	InvertActiveVisibleCell	; Turn off the active cell
	pop	ax, cx			; Restore passed cell
	
	;
	; Now we can set the current active cell and the current selected area.
	;
	
	mov	ds:[si].SSI_selected.CR_start.CR_row, ax
	mov	ds:[si].SSI_selected.CR_start.CR_column, cx
	mov	ds:[si].SSI_selected.CR_end.CR_row, dx
	mov	ds:[si].SSI_selected.CR_end.CR_column, bp
	;
	; See if the active cell is already in the new selected range
	;
	cmp	ds:[si].SSI_active.CR_row, ax
	jb	setCell
	cmp	ds:[si].SSI_active.CR_column, cx
	jb	setCell
	cmp	ds:[si].SSI_active.CR_row, dx
	ja	setCell
	cmp	ds:[si].SSI_active.CR_column, bp
	jbe	skipSet
setCell:
	mov	ds:[si].SSI_active.CR_row, ax	; Save new current row/column
	mov	ds:[si].SSI_active.CR_column, cx	; Save new current row/column
skipSet:
	;
	; Now invert the current range and the active cell.
	; Need ax/cx = Row/column of current cell.
	;
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column
	call	InvertSelectedVisibleCell	; Invert to allow rectangle

	call	InvertRangeAndActiveCell
	
	call	DestroyGState		; Nuke the gstate
sendNotification:
	stc					;carry <- selection changed
quit:

	.leave
	ret
SetSelectedRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishSelectCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for finishing a selection
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FinishSelectExtendCommon	proc	near
	.enter

EC <	call	ECCheckInstancePtr		;>

	call	SS_SendNotificationSelectAdd
	call	KeepSelectCellOnScreen

	.leave
	ret
FinishSelectExtendCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSelectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "Select All"
CALLED BY:	MSG_META_SELECT_ALL

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSelectAll	method dynamic SpreadsheetClass, \
						MSG_META_SELECT_ALL
	sub	sp, (size SpreadsheetRangeParams)
	mov	bp, sp				;ss:bp <- ptr to params
	;
	; Get the current selection, so we can preserve the active cell
	;
	call	SpreadsheetGetSelection
	;
	; Set the selection to everything
	;
	clr	ax
	mov	ss:[bp].SRP_selection.CR_start.CR_row, ax
	mov	ss:[bp].SRP_selection.CR_start.CR_column, ax
	mov	ax, ds:[di].SSI_maxRow
	mov	ss:[bp].SRP_selection.CR_end.CR_row, ax
	mov	ax, ds:[di].SSI_maxCol
	mov	ss:[bp].SRP_selection.CR_end.CR_column, ax
	call	SpreadsheetSetSelection
	add	sp, (size SpreadsheetRangeParams)
	ret
SpreadsheetSelectAll	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetExtendContractSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend the selection to include the specified range
CALLED BY:	MSG_SPREADSHEET_EXTEND_SELECTION

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		ss:bp - ptr to SpreadsheetRangeParams
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetExtendContractSelection	method dynamic SpreadsheetClass, \
				MSG_SPREADSHEET_EXTEND_CONTRACT_SELECTION
	mov	si, di				;ds:si <- ptr to Spreadsheet
	;
	; Get the specified selection range
	;
	call	GetSelectionFromParams
	;
	; Add the range, with the active cell as an anchor point
	;
	call	AddAnchoredSelection
	jnc	noChange		;branch if selection didn't change
	;
	; Send a notification, if the selection actually changed
	;
	call	SS_SendNotificationSelectAdd
noChange:
	ret
SpreadsheetExtendContractSelection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddAnchoredSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the range to the selection, with the active cell
		as an anchor point
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx),
		(dx,bp) - range to set
RETURN:		carry - set if selection changed
DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddAnchoredSelection	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; Add the range to the current selection, using
	; the active cell as an anchor point.
	;
	cmp	ax, ds:[si].SSI_active.CR_row
	jb	gotStartRow
	mov	ax, ds:[si].SSI_active.CR_row
gotStartRow:
	cmp	cx, ds:[si].SSI_active.CR_column
	jb	gotStartColumn
	mov	cx, ds:[si].SSI_active.CR_column
gotStartColumn:
	cmp	dx, ds:[si].SSI_active.CR_row
	jae	gotEndRow
	mov	dx, ds:[si].SSI_active.CR_row
gotEndRow:
	cmp	bp, ds:[si].SSI_active.CR_column

	jae	gotEndColumn
	mov	bp, ds:[si].SSI_active.CR_column
gotEndColumn:
	;
	; Set the new selection
	;
	call	SetSelectedRange

	.leave
	ret
AddAnchoredSelection	endp

DrawCode	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selection for a spreadsheet
CALLED BY:	MSG_SPREADSHEET_SET_SELECTION

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		ss:bp - ptr to SpreadsheetRangeParams
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetSelection	method SpreadsheetClass, \
						MSG_SPREADSHEET_SET_SELECTION
	mov	si, di				;ds:si <- ptr to Spreadsheet


	push	ss:[bp].SRP_active.CR_row
	push	ss:[bp].SRP_active.CR_column
	;
	; Set the selection
	;
	call	GetSelectionFromParams
	call	SetSelectedRangeNotify
	;
	; Set the active cell
	;
	pop	cx
	pop	ax				;(ax,cx) <- (r,c)

	;
	; Check for special case for row and column for active cell: VISIBLE
	;
	cmp	ax, SPREADSHEET_ADDRESS_ON_SCREEN
	jne	gotARow
	mov	ax, ds:[si].SSI_visible.CR_start.CR_row
gotARow:
	cmp	cx, SPREADSHEET_ADDRESS_ON_SCREEN
	jne	gotAColumn
	mov	cx, ds:[si].SSI_visible.CR_start.CR_column
gotAColumn:
	;
	; Check for special case for row and column for active cell: SELECTION
	;
	cmp	ax, SPREADSHEET_ADDRESS_IN_SELECTION
	jne	gotBRow
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
gotBRow:
	cmp	cx, SPREADSHEET_ADDRESS_IN_SELECTION
	jne	gotBColumn
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
gotBColumn:

	; One last check -- don't allow active cell in "locked" area

	call	CheckMinRowCol

EC <	call	ECCheckCellCoord		;>
	call	MoveActiveCellFar

	call	KeepActiveCellOnScreen
	ret
SpreadsheetSetSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMinRowCol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that the passed range doesn't fall outside
		the current spreadsheet's minimum row/column bounds

CALLED BY:	SpreadsheetSetSelection, GetSelectionFromParams

PASS:		ds:si - spreadsheet object
		(ax, cx) - row, column to check

RETURN:		(ax, cx) - fixed up

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/21/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckMinRowCol	proc near
		class	SpreadsheetClass

		uses	bx, si

		.enter

		test	ds:[si].SSI_flags, mask SF_NONZERO_DOC_ORIGIN
		jz	done

		push	ax
		mov	ax, TEMP_SPREADSHEET_DOC_ORIGIN
		mov	si, ds:[si].SSI_chunk
		call	ObjVarFindData
		pop	ax
		jnc	done

		mov	si, ds:[bx].SDO_rowCol.CR_row
		cmp	ax, si
		ja	checkCol
		mov	ax, si
checkCol:
		mov	si, ds:[bx].SDO_rowCol.CR_column
		cmp	cx, si
		ja	done
		mov	cx, si

done:
		.leave
		ret
CheckMinRowCol	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectionFromParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get selection from SpreadsheetRangeParams structure
CALLED BY:	SpreadsheetSetSelection()

PASS:		ss:bp - ptr to SpreadsheetRangeParams
RETURN:		(ax,cx),
		(dx,bp) - range
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetSelectionFromParams	proc	far
	uses	bx, di
	class	SpreadsheetClass
	.enter

	mov	ax, ss:[bp].SRP_selection.CR_start.CR_row
	mov	cx, ss:[bp].SRP_selection.CR_start.CR_column
	mov	dx, ss:[bp].SRP_selection.CR_end.CR_row
	mov	bx, ss:[bp].SRP_selection.CR_end.CR_column
	;
	; Check for special row and column: DATA_AREA
	;
	mov	di, SPREADSHEET_ADDRESS_DATA_AREA
	cmp	ax, di
	je	getDataArea
	cmp	cx, di
	je	getDataArea
	cmp	dx, di
	je	getDataArea
	cmp	bx, di
	je	getDataArea
afterDataArea:
	;
	; Check for special row and column: USE_SELECTION
	;
	mov	di, SPREADSHEET_ADDRESS_USE_SELECTION
	cmp	ax, di
	jne	gotStartRow2
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
gotStartRow2:
	cmp	cx, di
	jne	gotStartColumn2
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
gotStartColumn2:
	cmp	dx, di
	jne	gotEndRow2
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
gotEndRow2:
	cmp	bx, di
	jne	gotEndColumn2
	mov	bx, ds:[si].SSI_selected.CR_end.CR_column
gotEndColumn2:
	;
	; Check for special row and column: PAST_END
	;
	mov	di, SPREADSHEET_ADDRESS_PAST_END
	cmp	ax, di
	jne	gotStartRow
	mov	ax, ds:[si].SSI_maxRow
gotStartRow:
	cmp	cx, di
	jne	gotStartColumn
	mov	cx, ds:[si].SSI_maxCol
gotStartColumn:
	cmp	dx, di
	jne	gotEndRow
	mov	dx, ds:[si].SSI_maxRow
gotEndRow:
	cmp	bx, di
	jne	gotEndColumn
	mov	bx, ds:[si].SSI_maxCol
gotEndColumn:

EC <	push	dx, bp				;>
EC <	mov	bp, dx				;>
EC <	mov	dx, bx				;(ax,cx),(bp,dx) <- range >
EC <	call	ECCheckOrderedCoords		;>
EC <	pop	dx, bp				;>

	mov	bp, bx				;bp <- end column

	; (ax,cx),(dx,bp) - selection range

	call	CheckMinRowCol

	xchg	ax, dx
	xchg	cx, bp
	call	CheckMinRowCol
	xchg	ax, dx
	xchg	cx, bp

	.leave
	ret

	;
	; One or more of the parameters is SPREADSHEET_ADDRESS_DATA_AREA,
	; so calculate the data area and replace the necessary parameter(s).
	;
getDataArea:
	mov	di, SET_NO_EMPTY_CELLS
	call	CallRangeExtentWholeSheet
	cmp	ax, -1
	je	noData
	mov	di, SPREADSHEET_ADDRESS_DATA_AREA
	cmp	di, ss:[bp].SRP_selection.CR_start.CR_row
	je	gotDataStartRow
	mov	ax, ss:[bp].SRP_selection.CR_start.CR_row
gotDataStartRow:
	cmp	di, ss:[bp].SRP_selection.CR_start.CR_column
	je	gotDataStartColumn
	mov	cx, ss:[bp].SRP_selection.CR_start.CR_row
gotDataStartColumn:
	cmp	di, ss:[bp].SRP_selection.CR_end.CR_row
	je	gotDataEndRow
	mov	dx, ss:[bp].SRP_selection.CR_end.CR_row
gotDataEndRow:
	cmp	di, ss:[bp].SRP_selection.CR_end.CR_column
	je	gotDataEndColumn
	mov	bx, ss:[bp].SRP_selection.CR_end.CR_row
gotDataEndColumn:
	jmp	afterDataArea

	;
	; There was no data area -- reset everything
	;
noData:
	clr	ax, cx, dx, bx
	jmp	afterDataArea
GetSelectionFromParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the currently selected range

CALLED BY:	via MSG_SPREADSHEET_GET_SELECTION
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		ss:bp	= ptr to SpreadsheetRangeParams
RETURN:		ss:bp	= SpreadsheetRangeParams filled in
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetSelection	method	SpreadsheetClass,
				MSG_SPREADSHEET_GET_SELECTION
	mov	si, di				;ds:si <- ptr to instance data
	;
	; Copy the active cell
	;
	mov	ax, ds:[si].SSI_active.CR_row
	mov	ss:[bp].SRP_active.CR_row, ax
	mov	ax, ds:[si].SSI_active.CR_column
	mov	ss:[bp].SRP_active.CR_column, ax
	;
	; Copy the selection
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	ss:[bp].SRP_selection.CR_start.CR_row, ax
	mov	ax, ds:[si].SSI_selected.CR_start.CR_column
	mov	ss:[bp].SRP_selection.CR_start.CR_column, ax
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	mov	ss:[bp].SRP_selection.CR_end.CR_row, ax
	mov	ax, ds:[si].SSI_selected.CR_end.CR_column
	mov	ss:[bp].SRP_selection.CR_end.CR_column, ax
	ret
SpreadsheetGetSelection	endm

CommonCode	ends
