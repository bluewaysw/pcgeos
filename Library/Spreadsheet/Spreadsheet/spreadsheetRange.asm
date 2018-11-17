COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetRange.asm

AUTHOR:		Gene Anderson, Mar  2, 1991

ROUTINES:
	Name				Description
	----				-----------
 METHOD SpreadsheetProtectRange		Protect the range of cells from being
					modified.

 METHOD SpreadsheetUnprotectRange	Unprotect the range of cells so that
					they can be modified.

    EXT CheckProtectedCell	Check if there are some protected cells in
				the input range.

    EXT RecalcVisibleRangeGState Recalculate which cells are visible after
				resize/scroll/etc.

    EXT RangeDrawGrid		Draw range for specified range

    EXT CheckLargeGrid		Check to see if the range we want to draw
				is too large to draw in one piece.

    EXT RangeDrawLargeGrid	Draw a large grid by breaking it up into
				pieces.

    EXT CheckTranslate		Check to see if we need to translate the
				range in order to draw the grid.

    EXT TranslateRangeInBounds	Apply a translation to the gstate in order
				to draw the range.

    EXT RangeDraw		Draw the specified range

    EXT CallRangeEnumSelected	Call RangeEnum() on selected area with
				current draw flags

    EXT CallRangeEnum		Call RangeEnum() after setting up params

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/ 2/91		Initial revision

DESCRIPTION:
	Range routines for the spreadsheet.

	$Id: spreadsheetRange.asm,v 1.1 97/04/07 11:13:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


if _PROTECT_CELL
EditCode	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetProtectRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the range of the cells to be protected.

CALLED BY:	MSG_SPREADSHEET_PROTECT_RANGE
PASS:		*ds:si	= SpreadsheetClass object
		ds:di	= SpreadsheetClass instance data
		es 	= segment of SpreadsheetClass
		cl	= SpreadsheetProctectionOptions
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	* Find out the range of the cells that we have to protect.
	* Mark each of the cells in the range to be protected using callback
		using RangeEnum.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetProtectRange	method dynamic SpreadsheetClass, 
					MSG_SPREADSHEET_PROTECT_RANGE
locals		local	CellLocals
		uses	cx, dx, bp
		.enter

		Assert	etype cl, SpreadsheetProtectionOptions
	;
	; First of all, change the cursor to be a busy cursor. And then
	; find out the range of the cells that we have to protect.
	;
		push	si
		mov	si, di				;ds:si = instance data
		call	SpreadsheetMarkBusy
		cmp	cl, SPO_SELECTED_CELLS	;selected range?
		jne	allCells		;go to all Cell if not
		mov	ax, ds:[si].SSI_selected.CR_start.CR_row
		mov	cx, ds:[si].SSI_selected.CR_start.CR_column
		mov	bx, ds:[si].SSI_selected.CR_end.CR_row
		mov	dx, ds:[si].SSI_selected.CR_end.CR_column
		jmp	gotRange
allCells:
		mov	di, SET_ENTIRE_SHEET
		call	CallRangeExtentWholeSheet	;(ax,cx) (dx,bx) =
							;range of spreadsheet
		xchg	dx, bx				;(bx,dx) = (r,c)
	;
	; We don't lock a whole empty spreadsheet. Give error message here if
	; the user is trying to do that.
	;
		cmp	ax, -1				;empty spreadsheet
		je	error
gotRange:
	;
	; We have the range in (ax,cx) (bx,dx). Protect all cells in this
	; range.
	;
		mov	locals.CL_params.REP_callback.segment, SEGMENT_CS
		mov	locals.CL_params.REP_callback.offset, offset ProtectCellCB
		mov	di, mask REF_ALL_CELLS
		call	CallRangeEnum			;di trashed
	;
	; Make sure the UI Control is up-to-date
	;
		pop	si				;*ds:si = spreadsheet
		call	SpreadsheetProtectionUpdateUI	;ax trashed
	;
	; Everything is done. Change the cursor back
	;
quit:
		call	SpreadsheetMarkNotBusy
		
		.leave
		ret
error:
	;
	; Display the error dialog. 
	;
		pop	si
		mov	si, offset CellProtectEmptyError
		call	PasteNameNotifyDB
		jmp	quit
		
SpreadsheetProtectRange		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetCheckProtectedCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the given range of the cells is protected.

CALLED BY:	MSG_SPREADSHEET_CHECK_PROTECTED_CELLS
PASS:		*ds:si	= SpreadsheetClass object
		ds:di	= SpreadsheetClass instance data
		es 	= segment of SpreadsheetClass
		ss:bp	= CellRange
		dx	= size of CellRange (called remotely)
		ax	= message #
RETURN:		carry	= set	-- protected cell exists
			  clear	-- no protected cell in the range
DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetCheckProtectedCells	method dynamic SpreadsheetClass, 
					MSG_SPREADSHEET_CHECK_PROTECTED_CELLS
		uses	cx, dx
		.enter
		mov	ax, ss:[bp].CR_start.CR_row
		mov	cx, ss:[bp].CR_start.CR_column
		mov	bx, ss:[bp].CR_end.CR_row
		mov	dx, ss:[bp].CR_end.CR_column
		mov	si, di
		call	CheckProtectedCell
		.leave
		ret
SpreadsheetCheckProtectedCells		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProtectCellCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback used by RangeEnum to mark the cell to be protected.

CALLED BY:	RangeEnum() through SpreadsheetProtectRange
PASS:		(ax, cx) = current cell (r, c)
		ss:bp	= callback local variables (locals of type CallLocals)
		ss:bx	= RangeEnumParams
		*es:di	= cell data if any
		carry set if cell has data
RETURN:		carry set to abort enumeration
		es	= seg. addr of cell (updated)
		dl	= RangeEnumFlags
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	* First of all, make sure the cell in current location is exist. If
		not, we have to create one.
	* Mark the cell to be protected and exit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProtectCellCB	proc	far
locals		local	CellLocals
		uses	ax, di, si, ds
		.enter	inherit
	;
	; First of all, we have to find out if the current cell is allocated
	; or not. If it is not, we have to allocate one.
	;
		mov	dl, 0			;assume cell exists
		jc	gotCell			;Branch if cell exists
	;
	; Cell doesn't exist. Create a new one.
	;
		mov	dl, mask REF_CELL_ALLOCATED
		movdw	dssi, locals.CL_instanceData	;ds:si = spreadsheet
							;instance data
		call	SpreadsheetCreateEmptyCell
		SpreadsheetCellLock		;*es:di = cell data
gotCell:
	;
	; Turn on the cell protection bit
	;
		mov	di, es:[di]		;es:di = cell data
		ornf	es:[di].CC_recalcFlags, mask CRF_PROTECTION
		SpreadsheetCellDirty		; Dirty the cell data
		clc				; don't abort enum
		.leave
		ret
ProtectCellCB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetUnprotectRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the range of cell to be unprotected, so the content
		of the cells can be changed again.

CALLED BY:	MSG_SPREADSHEET_UNPROTECT_RANGE
PASS:		*ds:si	= SpreadsheetClass object
		ds:di	= SpreadsheetClass instance data
		es 	= segment of SpreadsheetClass
		cl	= SpreadsheetProctectionOptions
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	* Find out the range of the cells that we have to unprotec.
	* Unprotect the range by using RangeEnum through callback.
	* Notify the edit bar to update itself because the cell may change
		from being protected to be unprotected
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetUnprotectRange	method dynamic SpreadsheetClass, 
					MSG_SPREADSHEET_UNPROTECT_RANGE
locals		local	CellLocals
		uses	cx, dx, bp
		.enter
		Assert	etype cl, SpreadsheetProtectionOptions
	;
	; First of all, change the cursor to be a busy cursor. And then
	; find out the range of the cells that we have to unprotect.
	;
		push	si
		mov	si, di				;ds:si = instance data
		call	SpreadsheetMarkBusy
		cmp	cl, SPO_SELECTED_CELLS	;selected range?
		jne	allCells		;go to all Cell if not
		mov	ax, ds:[si].SSI_selected.CR_start.CR_row
		mov	cx, ds:[si].SSI_selected.CR_start.CR_column
		mov	bx, ds:[si].SSI_selected.CR_end.CR_row
		mov	dx, ds:[si].SSI_selected.CR_end.CR_column
		jmp	gotRange
allCells:
		mov	di, SET_ENTIRE_SHEET
		call	CallRangeExtentWholeSheet	;(ax,cx) (dx,bx) =
							;range of spreadsheet
		xchg	dx, bx				;(bx,dx) = (r,c)
	;
	; We don't lock a whole empty spreadsheet. Give error message here if
	; the user is trying to do that.
	;
		cmp	ax, -1				;empty spreadsheet
		je	error
gotRange:
	;
	; We have the range in (ax,cx) (bx,dx). Unrotect all cells in this
	; range.
	;
		mov	locals.CL_params.REP_callback.segment, SEGMENT_CS
		mov	locals.CL_params.REP_callback.offset, offset UnprotectCellCB
		mov	di, mask REF_ALL_CELLS
		call	CallRangeEnum			;di trashed
	;
	; Update the related controllers
	;
		pop	si				;*ds:si = spreadsheet
		call	SpreadsheetProtectionUpdateUI	;ax trashed
	;
	; Everything is done. Change the cursor back
	;
quit:
		call	SpreadsheetMarkNotBusy
		
		.leave
		ret
error:
	;
	; Display the error dialog. 
	;
		pop	si
		mov	si, offset CellProtectEmptyError
		call	PasteNameNotifyDB
		jmp	quit
		
SpreadsheetUnprotectRange		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnprotectCellCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback used by RangeEmnu to unmark the protected cells.

CALLED BY:	RangeEnum() through SpreadsheetUnprotectRange
PASS:		(ax, cx) = current clee (r,c)
		ss:bp	= callback local variables (locals of type CallLocals)
		ss:bx	= RangeEnumParams
		*es:di	= cell data if any
		carry set if cell has data
RETURN:		carry set to abort enumeration
		es	= seg. addr of cell (updated)
		dl	= RangeEnumFlags
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	* If there is no cell in the current location, then quit.
	* If the cell exists, clear the protection bit. BE CAREFULL: we
		use the unused bit in CC_recalcFlag to be the protection
		bit, so we don't have to allocate an extra byte just for
		cell protection.
	* We may need to delete the cell if the cell has no data
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnprotectCellCB	proc	far
locals		local	CellLocals
		class	SpreadsheetClass
		uses	ax, di, si, ds
		.enter	inherit	far
	;
	; If cell at this location doesn't exist, just quit then.
	;
		jnc	quit
		
EC <		call	ECCheckInstancePtr				>

		clr	dl				;assume default return
		mov	di, es:[di]			;es:di = cell data
	;
	; Clear the protection bit from the cell data
	;
		andnf	es:[di].CC_recalcFlags, not (mask CRF_PROTECTION)
		SpreadsheetCellDirty
	;
	; We need to delete the cell if this cell has no empty, no note and
	; no attri.
	;
		cmp	es:[di].CC_type, CT_EMPTY	;empty cell?
		jnz	quit
		tst	es:[di].CC_notes.segment	;notes?
		jnz	quit
		tst	es:[di].CC_dependencies.segment	;dependencies?
		jnz	quit
	;
	; NOTE: this checks agains default column attributes, because if a
	; cell is deleted, it will be recreated with those attributes
	;
		push	dx
		call	ColumnGetDefaultAttrs		;dx = default col attrs
		cmp	es:[di].CC_attrs, dx		;default attrs?
		pop	dx
		jnz	quit
	;
	; This cell will really be deleted -- unlock it first
	;
		SpreadsheetCellUnlock
		call	DeleteCell
		
quit:
		clc
		.leave
		ret
UnprotectCellCB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetProtectionUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the controllers to reveal whether the cell(s) is/are
		protected.

CALLED BY:	SpreadsheetProtectRange, SpreadsheetUnprotectRange
PASS:		*ds:si	= spreadsheet instance data
		ds:di	= *ds:si
		es	= seg address of SpreadsheetClass
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetProtectionUpdateUI	proc	near
		uses	cx, dx, bp
		.enter
	;
	; Update the EditBar Controller
	;
		mov	ax, MSG_META_UI_FORCE_CONTROLLER_UPDATE
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_SPREADSHEET_EDIT_BAR_CHANGE
		call	ObjCallInstanceNoLock
		.leave
		ret
SpreadsheetProtectionUpdateUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckProtectedCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if there are some protected cells in the input range.

CALLED BY:	UTILITY for cell protection feature
PASS:		ds:si	= Spreadsheet instance
		ax,cx	= r, c of the top-left corner
		bx,dx	= r, c of the bottom-right corner
RETURN:		carry set if the range contains protected cells;
		otherwise, carry is clear
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	* Clear CL_data1 because we need it to tell us whether there exists
		any protected cell in the range. If it does, CL_data1 will be
		set to non-zero.
	* Use RangeEnum to check all the cells in the range
	* Set the apropriate carry flag based on CL_data1
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckProtectedCell	proc	far
locals		local	CellLocals
		uses	di
		.enter
EC<	call	ECCheckInstancePtr 					>

	;
	; Init some of the local variables. CL_data1 is used to tell whether
	; there exists any protected cell(s) in the range. Orginally, it should
	; be set to 0. 
	;
		clr	locals.CL_data1
		mov	locals.CL_params.REP_callback.segment, SEGMENT_CS
		mov	locals.CL_params.REP_callback.offset, offset CheckProtectedCellCB
		clr	di				;use default flag
		call	CallRangeEnum			;di trashed
	;
	; If CL_data1 is non-zero, that means there exists some protected
	; in the range. We have to correct carry flag for the return.
	;
		tst	locals.CL_data1
		jnz	exit
		stc				; no protected cell
exit:
		cmc
		.leave
		ret
CheckProtectedCell		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckProtectedCellCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback used to check if the cell is protected.

CALLED BY:	RangeEnum() through CheckProtectCell()
PASS:		(ax, cx) = current cell (r, c)
		ss:bp	= callback local variables (locals of type CallLocals)
		ss:bx	= RangeEnumParams
		*es:di	= cell data if any
		carry set if cell has data
RETURN:		carry set to abort enumeration
		es	= seg. addr of cell (updated)
		dl	= RangeEnumFlags
		locals.CL_data1 is non_zero if a protected cell is found.
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckProtectedCellCB	proc	far
locals		local	CellLocals		
		uses	di
		.enter	inherit
EC <		ERROR_NC	-1					>
	;
	; Find out if this cell is protected or not. If it is, then set
	; locals.CL_data1 to be non-zero, and abort the enum
	;
		mov	di, es:[di]		;es:di = cell data
		test	es:[di].CC_recalcFlags, mask CRF_PROTECTION
		jz	quit			;quit if not protected
		mov	locals.CL_data1, 1	;cell is protected
		stc				;abort enum since the protected
						;cell is found
quit:
		clr	dl
		.leave
		ret
CheckProtectedCellCB		endp
EditCode	ends
endif

DrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcVisibleRangeGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate which cells are visible after resize/scroll/etc.
CALLED BY:	SpreadsheetDraw()

PASS:		ds:si - ptr to Spreadsheet instance
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RecalcVisibleRangeGState	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, dx
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	call	GetWinBounds32
	lea	bx, ss:locals.CL_docBounds.RD_right ;ss:bx <- ptr to PointDWord
	call	Pos32ToVisCellFar		;(ax,cx) <- lower right cell
	mov	ds:[si].SSI_visible.CR_end.CR_row, ax
	mov	ds:[si].SSI_visible.CR_end.CR_column, cx

	.leave
	ret
RecalcVisibleRangeGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeDrawGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw range for specified range
CALLED BY:	RangeDraw()

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx)
		(bx,dx) - range of cells to draw (r,c)
		ss:bp - inherited CellLocals
			CL_origin - origin for relative draw
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	sets CL_params.REP_bounds
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RangeDrawGrid	proc	near
	uses	ax, bx, cx, dx
	class	SpreadsheetClass

locals	local	CellLocals

EC <	call	ECCheckInstancePtr		;>

	.enter	inherit

EC <	push	bp				;>
EC <	mov	bp, bx				;>
EC <	call	ECCheckOrderedCoords		;>
EC <	pop	bp				;>

	mov	ss:locals.CL_params.REP_bounds.R_left, cx
	mov	ss:locals.CL_params.REP_bounds.R_top, ax
	mov	ss:locals.CL_params.REP_bounds.R_right, dx
	mov	ss:locals.CL_params.REP_bounds.R_bottom, bx
	;
	; Set the line draw mask to 50% to cool grid lines
	;
	push	ax, dx
	mov	al, SDM_50			;al <- SysDrawMask
	call	GrSetLineMask
	;
	; Set the line width to 0.0, so it doesn't scale
	;
	clr	ax, dx				;dx.ax <- 0.0
	call	GrSetLineWidth
	pop	ax, dx
	;
	; Get the range bounds, relative to specified origin
	;
	call	GetRangeRelBounds32

	;
	; We need to handle grids for large ranges specially.
	;
	call	CheckLargeGrid
	jnc	notLarge
	call	RangeDrawLargeGrid
	jmp	quit
notLarge:

	;
	; If the grid is off the legal drawing area we need to apply a
	; translation to get it legal.
	;
	call	CheckTranslate
	pushf					;save "translated" flag (carry)
	jnc	coordsOK
	call	GrSaveState
	call	TranslateRangeInBounds
coordsOK:

	;
	; Draw a vertical line at the left edge of each column
	;
	mov	ax, ss:locals.CL_docBounds.RD_left.low
	mov	bx, ss:locals.CL_docBounds.RD_top.low
	mov	dx, ss:locals.CL_docBounds.RD_bottom.low
	mov	cx, ss:locals.CL_params.REP_bounds.R_left
columnLoop:
	call	GrDrawVLine
	cmp	cx, ss:locals.CL_params.REP_bounds.R_right
	ja	doneColumns			;branch if done
	push	dx
	call	ColumnGetWidth			;dx <- column width
	add	ax, dx				;ax <- next x position
	pop	dx
	inc	cx				;cx <- next column
	jmp	columnLoop

doneColumns:
	;
	; Draw a horizontal line at the top of each row
	;
	mov	cx, ss:locals.CL_docBounds.RD_right.low
	mov	bx, ss:locals.CL_docBounds.RD_top.low
	mov	ax, ss:locals.CL_params.REP_bounds.R_top
rowLoop:
	push	ax
	mov	ax, ss:locals.CL_docBounds.RD_left.low
	call	GrDrawHLine
	pop	ax				;ax <- row #
	cmp	ax, ss:locals.CL_params.REP_bounds.R_bottom
	ja	doneRows			;branch if more rows
	call	RowGetHeight			;dx <- column width
	add	bx, dx				;bx <- next y position
	inc	ax				;ax <- next row
	jmp	rowLoop

doneRows:

	popf					;restore "translated" flag
	jnc	quit
	call	GrRestoreState
quit:
	;
	; Set the line thickness back to 1.0 for other operations
	;
	mov	dx, 1
	clr	ax				;dx.ax <- 1.0
	call	GrSetLineWidth

	.leave

	ret
RangeDrawGrid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckLargeGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the range we want to draw is too large to
		draw in one piece.

CALLED BY:	RangeDrawGrid
PASS:		ss:bp	= Inheritable CellLocals
RETURN:		carry set if we need to break up the draw.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckLargeGrid	proc	near
	uses	ax, bx
locals	local	CellLocals
	.enter	inherit
	;
	; Check height.
	;
	mov	ax, locals.CL_docBounds.RD_bottom.low
	mov	bx, locals.CL_docBounds.RD_bottom.high
	
	sub	ax, locals.CL_docBounds.RD_top.low
	sbb	bx, locals.CL_docBounds.RD_top.high
	
	tst	bx
	jnz	largeGrid
	cmp	ax, LARGEST_POSITIVE_COORDINATE
	jae	largeGrid

	;
	; Check width.
	;
	mov	ax, locals.CL_docBounds.RD_right.low
	mov	bx, locals.CL_docBounds.RD_right.high
	
	sub	ax, locals.CL_docBounds.RD_left.low
	sbb	bx, locals.CL_docBounds.RD_left.high
	
	tst	bx
	jnz	largeGrid
	cmp	ax, LARGEST_POSITIVE_COORDINATE
	jae	largeGrid

	clc					; Signal: small grid
quit:
	.leave
	ret

largeGrid:
	stc					; Signal: large grid
	jmp	quit
CheckLargeGrid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeDrawLargeGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a large grid by breaking it up into pieces.

CALLED BY:	RangeDrawGrid
PASS:		ss:bp	= Inheritable CellLocals
		di	= GState to use
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeDrawLargeGrid	proc	near
	uses	ax, bx, cx, dx
locals	local	CellLocals
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	;
	; Break the grid into four pieces.
	;
	mov	ax, ss:locals.CL_params.REP_bounds.R_top
	mov	bx, ss:locals.CL_params.REP_bounds.R_bottom
	mov	cx, ss:locals.CL_params.REP_bounds.R_left
	mov	dx, ss:locals.CL_params.REP_bounds.R_right
	
	push	dx				; Save old right
	push	cx				; Save old left
	push	bx				; Save old bottom
	;
	; Top-Left quadrant first...
	;
	push	dx				; Save right edge
	sub	bx, ax
	shr	bx, 1
	add	bx, ax				; bx <- new bottom
	
	sub	dx, cx
	shr	dx, 1
	add	dx, cx				; dx <- new right
	
	call	RangeDrawGrid			; Draw top-left

	;
	; Set left edge to current right edge (+1)
	;
	mov	cx, dx				; cx <- old right
	inc	cx
	pop	dx				; Restore right edge
	
	;
	; Top-Right quadrant next...
	;
	call	RangeDrawGrid			; Draw top-right
	
	;
	; Lower-Left quadrant next...
	;
	mov	ax, bx				; ax <- new top
	inc	ax
	pop	bx				; Restore old bottom
	
	mov	dx, cx				; dx <- new right edge
	dec	dx
	pop	cx				; Restore old left
	
	call	RangeDrawGrid			; Draw lower-left
	
	;
	; Lower-Right quadrant next...
	;
	mov	cx, dx				; cx <- new left
	inc	cx
	pop	dx				; Restore old right
	
	call	RangeDrawGrid			; Draw lower-right
	.leave
	ret
RangeDrawLargeGrid	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTranslate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we need to translate the range in order to
		draw the grid.

CALLED BY:	RangeDrawGrid
PASS:		ss:bp	= Inheritable CellLocals
RETURN:		carry set if a translation is required
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckTranslate	proc	near
	uses	ax
locals	local	CellLocals
	.enter	inherit
	mov	ax, ss:locals.CL_docBounds.RD_bottom.high
	or	ax, ss:locals.CL_docBounds.RD_right.high
	jnz	translate
	
	mov	ax, LARGEST_POSITIVE_COORDINATE
	cmp	ss:locals.CL_docBounds.RD_bottom.low, ax
	jae	translate
	cmp	ss:locals.CL_docBounds.RD_right.low, ax
	jae	translate

	clc					; Signal: no translation needed
quit:
	.leave
	ret

translate:
	stc					; Signal: needs translation
	jmp	quit
CheckTranslate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateRangeInBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply a translation to the gstate in order to draw the range.

CALLED BY:	RangeDrawGrid
PASS:		ss:bp	= Inheritable CellLocals
		di	= GState to transform
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateRangeInBounds	proc	near
	uses	ax, bx, cx, dx
locals	local	CellLocals
	.enter	inherit
	mov	dx, locals.CL_docBounds.RD_left.high
	mov	cx, locals.CL_docBounds.RD_left.low
	
	mov	bx, locals.CL_docBounds.RD_top.high
	mov	ax, locals.CL_docBounds.RD_top.low
	
	call	GrApplyTranslationDWord
	
	sub	locals.CL_docBounds.RD_bottom.low, ax
	sbb	locals.CL_docBounds.RD_bottom.high, bx

	sub	locals.CL_docBounds.RD_right.low, cx
	sbb	locals.CL_docBounds.RD_right.high, dx
	
	clr	ax
	mov	locals.CL_docBounds.RD_top.low, ax
	mov	locals.CL_docBounds.RD_top.high, ax
	mov	locals.CL_docBounds.RD_left.low, ax
	mov	locals.CL_docBounds.RD_left.high, ax
	.leave
	ret
TranslateRangeInBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the specified range
CALLED BY:	SpreadsheetDrawRange(), SpreadsheetDraw()

PASS:		ds:si - instance data (SpreadsheetClass)
		(ax,cx)
		(bx,dx) - range of cells to draw (r,c)
		di - handle of GState
		ss:bp - inherited CellLocals
			CL_origin - relative draw origin
			CL_drawFlags - SpreadsheetDrawFlags
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RangeDraw	proc	far
	uses	ax, bx, cx, dx, di
	class	SpreadsheetClass
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
EC <	push	bp				;>
EC <	mov	bp, bx				;>
EC <	call	ECCheckOrderedCoords		;>
EC <	pop	bp				;>

	mov	ss:locals.CL_gstate, di		;pass GState
	;
	; Draw the range of cells
	;
	clr	{byte}ss:locals.CL_data1	;border flags
	clr	di				;only cells w/data
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, offset CellDrawInt
	call	CallRangeEnum
	;
	; Draw any cells in that are overlapped by other cells.
	; Note that we only call back for rows that are marked
	; as having overlap, but for all cells in that row.
	;
	mov	di, mask REF_MATCH_ROW_FLAGS or \
			mask REF_ALL_CELLS
	mov	ss:locals.CL_params.REP_matchFlags, mask SRF_HAS_OVERLAP
	mov	ss:locals.CL_data2, -1
	mov	ss:locals.CL_data3, -1
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, offset CellDrawOverlap
	call	CallRangeEnum
	;
	; Draw the grid lines -- NOTE: we do this after the cells so that
	; the gridlines consistently appear (otherwise they appear semi-
	; randomly if a cell has a background color, at least in printing)
	; but before cell borders so that those consistently appear.
	;
	test	ss:locals.CL_drawFlags, mask SDF_DRAW_GRID
	jz	skipGridDraw
	mov	di, ss:locals.CL_gstate
	call	RangeDrawGrid
skipGridDraw:
	;
	; Draw the borders for the range, if any
	;
	tst	{byte}ss:locals.CL_data1	;any borders to draw?
	jz	noBorders			;branch if no borders
	clr	di				;only cells w/data
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, offset CellDrawBorders
	call	CallRangeEnum
noBorders:
	;
	; If this is our GState, reset the area mask and color for
	; any further drawing.
	;
	mov	di, ss:locals.CL_gstate
	cmp	di, ds:[si].SSI_gstate
	jne	noReset				;branch if not our GState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
	mov	al, SDM_100
	call	GrSetAreaMask
noReset:
	.leave
	ret
RangeDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRangeEnumSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call RangeEnum() on selected area with current draw flags
CALLED BY:	ds:si - ptr to Spreadsheet instance
		ss:bp - ptr to CellLocals:
			CL_data1 - data word #1
			CL_data2 - data word #2
			CL_data3 - data word #3
			CL_params.REP_callback - fptr to callback
		di.low - RangeEnumFlags
RETURN:		none
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallRangeEnumSelected	proc	far
	uses	ax, bx, cx, dx
	class	SpreadsheetClass

locals	local	CellLocals

	.enter	inherit

EC <	call	ECCheckInstancePtr		;>

	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bx, ds:[si].SSI_selected.CR_end.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column

	call	CallRangeEnum

	.leave
	ret
CallRangeEnumSelected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRangeEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call RangeEnum() after setting up params
CALLED BY:	UTILITY

PASS:		ds:si - instance data (SpreadsheetClass)
		(ax,cx)
		(bx,dx) - range of cells to enumerate (r,c)
		ss:bp - ptr to CellLocals:
			CL_gstate - handle of GState, if needed
			CL_drawFlags - SpreadsheetDrawFlags, if needed
			CL_data1 - data word #1
			CL_data2 - data word #2
			CL_data3 - data word #3
			CL_params.REP_callback - fptr to callback
			CL_origin - relative draw origin
		di.low - RangeEnumFlags
RETURN:		none
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallRangeEnum	proc	far
	uses	ax, bx, cx, dx
	class	SpreadsheetClass

locals	local	CellLocals

	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	;
	; Store arguments passed in registers
	;
	mov	ss:locals.CL_params.REP_bounds.R_left, cx
	mov	ss:locals.CL_params.REP_bounds.R_top, ax
	mov	ss:locals.CL_params.REP_bounds.R_right, dx
	mov	ss:locals.CL_params.REP_bounds.R_bottom, bx
	mov	ss:locals.CL_instanceData.segment, ds
	mov	ss:locals.CL_instanceData.offset, si
	;
	; Set up other arguments
	;
	mov	dx, di				;dl <- RangeEnumFlags
	mov	ss:locals.CL_styleToken, -1	;no styles set yet
	;
	; Call RangeEnum() to callback for specified cells
	;
	lea	bx, ss:locals.CL_params		;ss:bx <- ptr to args
CheckHack <offset SSI_cellParams eq 0 >
	call	RangeEnum

	.leave
	ret
CallRangeEnum	endp

DrawCode	ends
