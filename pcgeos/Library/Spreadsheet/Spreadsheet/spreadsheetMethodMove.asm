COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetMethodMove.asm

AUTHOR:		Gene Anderson, Mar  3, 1991

ROUTINES:
	Name			Description
	----			-----------
MSG_SPREADSHEET_MOVE_ACTIVE_CELL	Move active cell
	MoveActiveCellFar	Move the active cell

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/ 3/91		Initial revision

DESCRIPTION:
	Routines and methods related to moving the active cell

	$Id: spreadsheetMethodMove.asm,v 1.1 97/04/07 11:13:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveActiveCellDeselectFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deselect current range and move active cell
CALLED BY:	UTILITY

PASS:		ds:si - ptr to instance data
		(ax,cx) - cell to move to (r,c) (method)
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MoveActiveCellDeselectFar	proc	far
	call	DeselectRange
	GOTO	MoveActiveCellFar
MoveActiveCellDeselectFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveActiveCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the active cell
CALLED BY:	MSG_MOVE_ACTIVE_CELL

PASS:		*ds:si - ptr to instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		(bp,cx) - cell to move to (r,c) (method)
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This is called both as a method and a routine
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetMoveActiveCell	method 	SpreadsheetClass, \
					MSG_SPREADSHEET_MOVE_ACTIVE_CELL
	mov	ax, bp				;(ax,cx) <- cell (r,c)
	mov	si, di				;ds:si <- ptr to instance data
	FALL_THRU	MoveActiveCellFar
SpreadsheetMoveActiveCell	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveActiveCellFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the active cell
CALLED BY:	MoveActiveCell()

PASS:		ds:si - ptr to instance data
		(ax,cx) - cell to move to (r,c) (method)
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MoveActiveCellFar	proc	far
	uses	si
	class	SpreadsheetClass

	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; Have we actually moved?  If not, we're done...
	;
	cmp	ax, ds:[si].SSI_active.CR_row
	jne	moveCell			;branch if change in row
	cmp	cx, ds:[si].SSI_active.CR_column
	je	done				;branch if same column
moveCell:
	call	CreateGState			;di <- handle of GState
	;
	; Is the new location outside the current selection?
	; If so, we need to deselect the current selection
	; before moving the active cell.
	;
	call	CellSelected?
	jnc	changeSelection

	push	ax, cx
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column		;(ax,cx) <- old active cell
	call	InvertActiveVisibleCell		;de-active old active cell
	call	InvertSelectedVisibleCell	;select old active cell
	pop	ax, cx
	call	InvertSelectedVisibleCell	;deselect new active cell
	mov	ds:[si].SSI_active.CR_row, ax
	mov	ds:[si].SSI_active.CR_column, cx

afterDeselect:
	call	InvertActiveVisibleCell		;invert new active cell
	call	DestroyGState
	push	ax
	;
	; Set the edit bar to the cell contents
	;
	mov	ax, SNFLAGS_ACTIVE_CELL_MOVE	;ax <- SpreadsheetNotifyFlags
	call	SS_SendNotification
	;
	; Make sure the cell is on screen
	;
	pop	ax
	call	KeepActiveCellOnScreen
done:
	.leave
	ret

	;
	; The active cell is moving outside the current selection.
	; Deselect the current selection and make the new cell
	; selected.
	;
changeSelection:
	call	DeselectRange
	mov	ds:[si].SSI_selected.CR_start.CR_row, ax
	mov	ds:[si].SSI_selected.CR_start.CR_column, cx
	mov	ds:[si].SSI_selected.CR_end.CR_row, ax
	mov	ds:[si].SSI_selected.CR_end.CR_column, cx
	push	ax, cx
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column
	call	InvertActiveVisibleCell		;un-invert old active cell
	pop	ax, cx
	mov	ds:[si].SSI_active.CR_row, ax
	mov	ds:[si].SSI_active.CR_column, cx
	;
	; Notify the UI gadgetry to update itself.
	; NOTE: we don't include SNFLAGS_ACTIVE_CELL_MOVE because
	; that will be sent by the common code above.
	;
	push	ax
	mov	ax, SNFLAGS_SELECTION_CHANGE and \
		    not (SNFLAGS_ACTIVE_CELL_MOVE)
	call	SS_SendNotification
	pop	ax
	jmp	afterDeselect

MoveActiveCellFar	endp

DrawCode	ends
