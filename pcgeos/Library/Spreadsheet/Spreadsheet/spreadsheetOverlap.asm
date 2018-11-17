COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetOverlap.asm

AUTHOR:		Gene Anderson, Mar 18, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/18/93		Initial revision
	witt	11/9/93		DBCS-ized


DESCRIPTION:
	Code for dealing with evil cells that have text larger than their
	bounds.

	The row flags are used to indicate there are one or more cells in
	that row which overlap their bounds.

	The row flags are never explicitly cleared, but when a row is
	deleted its flags are deleted as well.  This is because it would
	be necessary to recalculate the flags for the entire row every
	time something was resized in it (eg. column widths, cell attrs
	that change the string size, the cell data itself).

	Once it is determined a row has overlaps, redraw of any cell
	in that row causes the entire row to be invalidated.  Not the most
	efficient, but it handles lots of weird cases in a simple fashion.
	Also, to handle the case where the last cell in the row to be
	deleted was an overlap cell, redrawing a cell after deleting it
	causes the entire row to be invalidated.

	When an expose occurs, the drawing code draws any cells with data.
	It then makes a second pass for any rows that have the row flag
	set indicating overlap, and calls CellDrawOverlap() to handle
	the case of empty cells that are overlapped getting exposed.
	What needs to happen, of course, is that the cell that overlaps
	them gets redrawn, even it wasn't part of the expose.

	CellDrawOverlap() does its best to draw things in an efficient way.
	As it draws cells in a particular row, it keeps track of what it
	has drawn so far so as to minimize the work done.  The basic
	idea is that when an empty cell is exposed, there may or may not
	be a cell to the left that overlaps it.  If there is, it needs
	to be redrawn.

	Listed below are various cases and how they are dealt with.  Cells
	are marked with "XXX" to indicate they are part of the expose;
	in all examples column C is the current column.


(1)	CASE:  No data cells to the left and left edge is reached:
	    A	    B	    C
	+-------+-------+-------+
	|	|	| XXXXX	|
	+-------+-------+-------+
	SOLUTION:  Do nothing -- there can't be an overlapping cell.


(2)	CASE:  Data cell to the left, but it doesn't overlap anything:
	    A	    B	    C
	+-------+-------+-------+
	|text	|	|XXXXXXX|
	+-------+-------+-------+
	SOLUTION:  Do nothing -- if the first data cell to the left
	doesn't overlap us, nothing to the left of it does, either,
	because it will stop drawing at the data cell.


(3)	CASE:  Data cell to the left that overlaps the current cell:
	    A	    B	    C
	+-------+-------+-------+
	|big text overlaps XXXXX|
	+-------+-------+-------+
	SOLUTION:  Draw the cell that overlaps.


(4)	CASE:  Data cell to the left that overlaps beyond current cell:
	    A	    B	    C	    D
	+-------+-------+-------+-------+
	|big text overlaps many cells	|
	+-------+-------+-------+-------+
	SOLUTION:  Same as (3) -- draw the cell that overlaps.  The only
	difference here is that not only do we now know that everything
	up the current cell is up-to-date, but all cells that are
	overlapped are up-to-date as well, so if we are called back
	for them, we don't need to draw them again.


(5)	CASE:  Data in current cell:
	    A	    B	    C
	+-------+-------+-------+
	|	|	|text XX|
	+-------+-------+-------+
	SOLUTION:  Do nothing -- this cell was drawn in the first pass.


	$Id: spreadsheetOverlap.asm,v 1.1 97/04/07 11:14:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCellOverlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find cell bounds including overlap for redrawing a cell

CALLED BY:	CellRedraw()
PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx) - (r,c) of cell
		di - handle of GState
RETURN:		(ax,bx,cx,dx) - bounds of cell
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCellOverlap		proc	near
	class	SpreadsheetClass
locals	local	CellLocals
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	bx, di				;bx <- handle of GState
	SpreadsheetCellLock
	jnc	doWholeRow			;branch if no cell
	;
	; The cell exists.  Get the normal bounds of the cell
	; and calculate the bounds of what it overlaps, if anything.
	;
	push	bx
	push	ax, cx
	call	GetCellVisBounds16		;(ax,bx,cx,dx) <- bounds
	mov	ss:locals.CL_bounds.R_left, ax
	mov	ss:locals.CL_bounds.R_top, bx
	mov	ss:locals.CL_bounds.R_right, cx
	mov	ss:locals.CL_bounds.R_bottom, dx
	pop	ax, cx
	mov	dx, es:[di]			;es:dx <- ptr to cell data
	pop	di				;di <- handle of GState
	mov	ss:locals.CL_styleToken, -1
	call	FindCellOverlapNoLock
	SpreadsheetCellUnlock
	;
	; See if there is overlap in this row.  If so, we return
	; the bounds of the whole row even if this cell doesn't
	; overlap anything, to account for the case where the
	; presence of this cell changes overlap for a different
	; cell.
	;
	call	RowGetFlags			;dx <- row flags
	test	dx, mask SRF_HAS_OVERLAP	;any overlap?
	mov	bx, ss:locals.CL_bounds.R_top
	mov	dx, ss:locals.CL_bounds.R_bottom
	jnz	doWholeRowGotBounds		;branch if overlap
	mov	ax, ss:locals.CL_bounds.R_left
	mov	cx, ss:locals.CL_bounds.R_right
	jmp	done

	;
	; Just return the whole row as the bounds.
	; This is to handle the case of deleting a cell which previously
	; overlapped multiple cells.  We don't check the row flags for
	; this case either, because of the case where the cell was the
	; last cell in the row, in which case the flags no longer exist.
	;
doWholeRow:
	mov	dx, ds:[si].SSI_visible.CR_start.CR_row
	call	RowGetRelPos16			;dx <- row offset
	xchg	bx, dx				;bx <- top of cell
	add	dx, bx				;dx <- bottom of cell
doWholeRowGotBounds:
	call	GetWinLeftRight
done:
	.leave
	ret
FindCellOverlap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCellOverlapNoLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find cell bounds including overlap w/cell locked

CALLED BY:	FindCellOverlap()
PASS:		ds:si - ptr to Spreadsheet instance
		ss:bp - inherited locals
			CL_bounds - cell bounds w/no overlap
			CL_styleToken - previous style token (-1 for none)
			CL_cellAttrs - current attrs (if any)
		es:dx - ptr to cell data
		(ax,cx) - (r,c) of cell
		di - handle of GState
RETURN:		ss:bp - inherited locals
			CL_bounds - bounds of cell (16-bit)
			CL_buffer - cell data formatted as text
			CL_justParams.JTP_width - width of string
			CL_justGeneral - Justification for string
			CL_data3 - column to right of overlap (if any)
		carry - set if string needs to be clipped
		z flag - set (jz) if cell overlaps
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
getCellAsTextRoutines	nptr \
	GetTextCellAsText,		;CT_TEXT
	GetConstantCellAsText,		;CT_CONSTANT
	GetFormulaCellAsText,		;CT_FORMULA
	BadCellType,			;CT_NAME
	BadCellType,			;CT_CHART
	GetEmptyCellAsText,		;CT_EMPTY
	GetDisplayFormulaCellAsText	;CT_DISPLAY_FORMULA
CheckHack <(size getCellAsTextRoutines) eq CellType>

FindCellOverlapNoLock		proc	near
	uses	bx, cx, dx
	class	SpreadsheetClass
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	mov	bx, dx				;es:bx <- cell data
	mov	dx, es:[bx].CC_attrs		;dx <- cell attrs
	cmp	dx, ss:locals.CL_styleToken	;same attrs?
	je	gotAttrs			;branch if same attrs
	;
	; The attributes have changed since the last time --
	; get them and setup the GState
	;
	call	SetCellGStateAttrs
gotAttrs:
	;
	; Get the cell data as a string
	;
	push	di
	mov	di, bx				;es:di <- ptr to CellCommon
	mov	bl, es:[di].CC_type
	clr	bh				;bx <- CellType
	call	cs:getCellAsTextRoutines[bx]
	pop	di
	;
	; If the justification is not general, use it directly.
	;
	mov	dl, ss:locals.CL_cellAttrs.CA_justification
	cmp	dl, J_GENERAL			;general justification?
	je	isGeneral
	mov	ss:locals.CL_justGeneral, dl
isGeneral:
	;
	; Get the width of ye olde string.  If it is small enough
	; to fit into the cell bounds, we're done -- we can just
	; return the cell bounds with no additional checking.
	;
getStringWidth:
	push	ds, si, cx
	segmov	ds, ss
	lea	si, ss:locals.CL_buffer		;ds:si <- ptr to text
	clr	cx				;cx <- NULL-terminated
	call	GrTextWidth			;dx <- width of string
	pop	ds, si, cx
	mov	ss:locals.CL_justParams.JTP_width, dx
	clr	bl				;bl <- overlap flag
	;
	; See if the area is large enough for the string
	;
checkStringWidth:
	push	ax
	mov	ax, ss:locals.CL_bounds.R_right
	sub	ax, ss:locals.CL_bounds.R_left	;ax <- width of area
	sub	ax, (CELL_INSET)*2
	cmp	ax, ss:locals.CL_justParams.JTP_width
	pop	ax
	jge	gotBounds			;branch if large enough
	;
	; If this is an error, don't let it flow over other cells
	;
	cmp	ss:locals.CL_returnType, RT_ERROR
	stc					;carry <- clip me jesus
	je	done				;branch if error string
	;
	; The string is too large for the cell.  See if the string is a value
	; -- if so, replace it with the text ### to indicate it.
	;
	cmp	ss:locals.CL_returnType, RT_VALUE
	je	numTooBig
	;
	; The string is too large for the cell.  Calculate the cells
	; that it overlaps, stopping if/when we get to occupied cells
	; or when we've got sufficient width.
	;
nextColumn:
	cmp	cx, ds:[si].SSI_maxCol		;at last column?
	stc					;carry <- clip me jesus
	je	done				;branch if at last column
	inc	cx				;cx <- next column
	call	CheckEmptyCell			;cell exists?
	jc	done				;branch if cell exists
	;
	; The next cell is empty -- add in the column width
	;
	call	ColumnGetWidth			;dx <- column width
	jz	nextColumn			;branch if column hidden
	add	ss:locals.CL_bounds.R_right, dx
	mov	ss:locals.CL_data3, cx		;save column #
	;
	; And mark the row as having overlaps
	;
	mov	dx, mask SRF_HAS_OVERLAP	;dx <- SpreadsheetRowFlags
	call	RowSetFlags
	mov	bl, 1				;bl <- cell overlaps
	jmp	checkStringWidth

gotBounds:
	clc					;carry <- bounds OK
done:
	;
	; bl is set to 0 for no overlap, or 1 for overlap.  The
	; following decrement will go to non-zero (jnz) if no overlap
	; and zero (jz) if overlap, as required, without destroying
	; the carry flag.
	;
	dec	bl				;set z flag for overlap

	.leave
	ret

	;
	; The number is too big to fit in the cell.  Replace it with ###
	; to indicate it can't be displayed in the available space.
	;
numTooBig:
	push	ax, es, di
	mov	ax, C_NUMBER_SIGN		;ax <- char to store
	segmov	es, ss
	lea	di, ss:locals.CL_buffer
	LocalPutChar esdi, ax
	LocalPutChar esdi, ax
	LocalPutChar esdi, ax
	clr	ax				;ax <- char to store
	LocalPutChar esdi, ax			;NULL-terminate me jesus
	pop	ax, es, di
	mov	ss:locals.CL_returnType, RT_ERROR
	mov	ss:locals.CL_justGeneral, J_CENTER
	jmp	getStringWidth
FindCellOverlapNoLock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextCellAsText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a CT_TEXT cell as text

CALLED BY:	FindCellOverlapNoLock()
PASS:		ds:si - ptr to Spreadsheet instance
		es:di - ptr to CellText structure
		ss:bp - inherited locals
RETURN:		CL_buffer - text
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextCellAsTextFar		proc	far
	call	GetTextCellAsText
	ret
GetTextCellAsTextFar		endp

GetTextCellAsText		proc	near
	uses	ds, si, es, di, cx
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>

	segmov	ds, es
	ChunkSizePtr ds, di, cx			;cx <- # bytes for cell
	sub	cx, (size CellText)		;cx <- # bytes for string
	lea	si, ds:[di].CT_text		;ds:si <- ptr to text
DBCS <EC< test	cx, 1				;size must be even!	> >
DBCS <EC< ERROR_NZ  CELL_DATA_STRING_ODDSIZE				> >
	;
	; Skip over any leading quote for 1-2-3 compatibility
	;
	call	Skip123Quote
	;
	; Copy the string into CL_buffer
	;
	segmov	es, ss
	lea	di, ss:locals.CL_buffer		;es:di <- ptr to buffer
	rep	movsb				;copy me jesus
	;
	; Set the Justification for J_GENERAL
	;
	mov	{word}ss:locals.CL_justGeneral, J_LEFT or (RT_TEXT shl 8)

	.leave
	ret
GetTextCellAsText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Skip123Quote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip any leading quote for 1-2-3 compatibility

CALLED BY:	GetTextCellAsText()
PASS:		ds:si - ptr to string
		cx - bytes to check (size)
RETURN:		ds:si - updated if necessary
		cx - updated size, if necessary
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/22/93		Initial version
	witt	11/15/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Skip123QuoteFar		proc	far
	call	Skip123Quote
	ret
Skip123QuoteFar		endp

Skip123Quote		proc	near
	uses	ax
	.enter

	;
	; Check for CX=0, as this prevents a crash in a certain case.
	;

	jcxz	done

	LocalGetChar ax, dssi			;ax <- char

SBCS <	cmp	al, C_ASCII_CIRCUMFLEX		;>
DBCS <	cmp	ax, C_SPACING_CIRCUMFLEX	;>
	je	doneSkip
SBCS <	cmp	al, C_SNG_QUOTE			;>
DBCS <	cmp	ax, C_APOSTROPHE_QUOTE		;>
	je	doneSkip
SBCS <	cmp	al, C_QUOTE			;>
DBCS <	cmp	ax, C_QUOTATION_MARK 		;>
	je	doneSkip

	LocalPrevChar	dssi		;ds:si <- unskip char

done:
	.leave
	ret

doneSkip:
	LocalPrevChar	dscx		;cx <- one less wchar/char in string
	jmp	done
Skip123Quote		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetConstantCellAsText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a CT_CONSTANT cell as text

CALLED BY:	FindCellOverlapNoLock()
PASS:		ds:si - ptr to Spreadsheet instance
		ss:bp - inherited locals
		es:di - ptr to CellConstant
RETURN:		CL_buffer - text
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetConstantCellAsTextFar	proc	far
	call	GetConstantCellAsText
	ret
GetConstantCellAsTextFar	endp

GetConstantCellAsText		proc	near
	uses	es, di
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	;
	; Format constant as text into CL_buffer
	;
	call	FormatConstantCellAsText
	mov	dx, J_RIGHT or (RT_VALUE shl 8)
	jnc	gotJust
	mov	dx, J_CENTER or (RT_ERROR shl 8)
	;
	; Set the Justification for J_GENERAL
	;
gotJust:
	mov	{word}ss:locals.CL_justGeneral, dx

	.leave
	ret
GetConstantCellAsText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFormulaCellAsText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a CT_FORMULA cell as text

CALLED BY:	FindCellOverlapNoLock()
PASS:		ds:si - ptr to Spreadsheet instance
		ss:bp - inherited locals
		(ax,cx) - (r,c) of cell
		es:di - ptr to CellFormula
RETURN:		CL_buffer - text
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFormulaCellAsTextFar		proc	far
	call	GetFormulaCellAsText
	ret
GetFormulaCellAsTextFar		endp

GetFormulaCellAsText		proc	near
	uses	bx
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>

	mov	bx, offset GetFormulaCellAsTextInt
	call	GetFormulaAsTextCommon

	.leave
	ret
GetFormulaCellAsText		endp

GetFormulaCellAsTextInt	proc	near
	call	FormulaCellGetResult
	ret
GetFormulaCellAsTextInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDisplayFormulaCellAsText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a CT_DISPLAY_FORMULA cell as text

CALLED BY:	FindCellOverlapNoLock()
PASS:		ds:si - ptr to Spreadsheet instance
		ss:bp - inherited locals
		(ax,cx) - (r,c) of cell
		es:di - ptr to CellFormula
RETURN:		CL_buffer - text
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDisplayFormulaCellAsTextFar		proc	far
	call	GetDisplayFormulaCellAsText
	ret
GetDisplayFormulaCellAsTextFar		endp

GetDisplayFormulaCellAsText		proc	near
	uses	bx
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>

	mov	bx, offset GetDisplayFormulaCellAsTextInt
	call	GetFormulaAsTextCommon

	.leave
	ret
GetDisplayFormulaCellAsText		endp

GetDisplayFormulaCellAsTextInt	proc	near
	call	FormulaDisplayCellGetResult
	ret
GetDisplayFormulaCellAsTextInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFormulaAsTextCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get CT_FORMULA or CT_DISPLAY_FORMULA cell as text

CALLED BY:	FindCellOverlapNoLock()
PASS:		ds:si - ptr to Spreadsheet instance
		ss:bp - inherited locals
		es:di - ptr to CellFormula
		(ax,cx) - (r,c) of cell
		bx - near routine to call for formatting
RETURN:		CL_buffer - text
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFormulaAsTextCommon		proc	near
	uses	dx, di, es
	class	SpreadsheetClass
locals	local	CellLocals

EC <	call	ECCheckInstancePtr		;>
	;
	; See if we're showing formulas instead
	;
	test	ds:[si].SSI_drawFlags, mask SDF_SHOW_FORMULAS
	jnz	showFormulas

	.enter	inherit

	;
	; Format the result as text into CL_buffer
	;
	push	bp
	mov	dx, di
	lea	di, ss:locals.CL_buffer
	mov	bp, dx
	mov	dx, es				;dx:bp <- ptr to cell data
	segmov	es, ss				;es:di <- ptr to buffer
	call	bx				;dl <- ReturnType
	pop	bp
	;
	; Align the text based on the return type
	;
	mov	dh, dl				;dh <- ReturnType
	mov	dl, J_RIGHT			;dl <- value :: right
	cmp	dh, RT_VALUE			;value?
	je	gotJust				;branch if value
	mov	dl, J_CENTER			;dl <- error :: center
	cmp	dh, RT_ERROR			;error?
	je	gotJust				;branch if error
	mov	dl, J_LEFT			;dl <- text :: left
gotJust:
	mov	{word}ss:locals.CL_justGeneral, dx
CheckHack <(offset CL_returnType) eq (offset CL_justGeneral)+1>

	.leave
	ret

showFormulas:
	FALL_THRU	ShowFormulaAsText
GetFormulaAsTextCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowFormulaAsText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a formula as text instead of its value

CALLED BY:	GetFormulaAsTextCommon()
PASS:		(ax,cx) - cell (r,c)
		es:di - ptr to CellFormula
		ds:si - ptr to Spreadsheet instance data
		ss:bp - inherited CellLocals
RETURN:		CL_buffer - text
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowFormulaAsText		proc	near
	uses	cx, dx, di
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	push	bp
	mov	dx, ss
	lea	bp, ss:locals.CL_buffer		;dx:bp <- ptr to buffer
	call	EditFormatFormulaCellFar
	pop	bp
	mov	{word}ss:locals.CL_justGeneral, J_LEFT or (RT_TEXT shl 8)
CheckHack <(offset CL_returnType) eq (offset CL_justGeneral)+1>

	.leave
	ret
ShowFormulaAsText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEmptyCellAsText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get CT_EMPTY cell as text

CALLED BY:	FindCellOverlapNoLock()
PASS:		ds:si - ptr to Spreadsheet instance
		ss:bp - inherited locals
RETURN:		CL_buffer - text
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	We're on a string to nowhere...
	...we're on a string to paradise, here we go.
					- The Talking Cells
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetEmptyCellAsText		proc	near
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>

	mov	{word}ss:locals.CL_buffer, 0	;An empty string

	.leave
	ret
GetEmptyCellAsText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellDrawOverlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Version of CellDrawInt() that checks for overlap

CALLED BY:	RangeDraw() via RangeEnum()

PASS:		ss:bp - ptr to RangeDraw() local variables
			CL_drawFlags - SpreadsheetDrawFlags
			CL_gstate - GState for drawing
			CL_styleToken - current style token
			CL_data1.low - CellBorderInfo
				--- cell borders that have been seen
				--- for the range being drawn
			CL_data2,3 - (r,c) of last data cell
		(ax,cx) - cell coordinates (r,c)
		carry - set if cell has data
		*es:di - ptr to cell data, if any

RETURN:		carry - clear (ie. don't abort enum)
		ss:bp - ptr to RangeDraw() local variables
			CL_data1.low - CellBorderInfo (updated)
			CL_styleToken - current style token (updated)
			CL_data2,3 - (r,c) of last data cell (updated)
DESTROYED:	none
		ss:bp - ptr to RangeDraw() local variables
			CL_buffer -- destroyed

PSEUDO CODE/STRATEGY:
	Unlike CellDrawInt(), we're only interested in drawing a cell
	if it doesn't have data.  This is because cells that do have
	data were drawn in by the first pass which called CellDrawInt().
	This routine is called only for rows that have overlap.

	NOTE: It is important to not do anything relative the visible cell
	since this may be called as part of printing, in which case our
	concept of a visible cell is neither relevant nor accurate.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CellDrawOverlap		proc	far
		uses	dx, di, es

locals		local	CellLocals
		.enter	inherit

		push	cx
EC <		call	ECCheckInstancePtr		;>
	;
	; We don't need to draw anything if the cell has data, as
	; that was dealt with by CellDrawInt() in the first pass.
	;
		jc	doneCheck			;branch if has data
	;
	; See if we already know something about the cells in this row.
	; If so, we can skip the search to the left.
	;
searchLeft:
		cmp	ax, ss:locals.CL_data2		;same row?
		jne	searchLeftLoop			;branch if not same
	;
	; If we've already drawn over this cell because of overlap from the
	; left, just skip it.
	;
		cmp	cx, ss:locals.CL_data3		;before known column?
		jbe	done				;branch if before known
		jmp	gotDataCell

	;
	; If we're at the left edge of the spreadsheet (a fairly common
	; case), we don't need to search to the left or draw anything.
	;
	; Search to the left until we find a cell we're interested in --
	; Either we reach the left edge or we reach a non-empty cell
	;
searchLeftLoop:
		jcxz	done				;branch if at left edge
		dec	cx				;cx <- left one column
		call	CheckEmptyCell			;cell exists?
		jnc	searchLeftLoop			;branch if doesn't exist
		jmp	gotDataCell2

	;
	; We've found the cell to the left that has data, or that
	; we last drew over (which will be empty or it wouldn't
	; have been overlapped).  If the cell doesn't exist, it means
	; it was drawn as part of the overlap of a cell to its left,
	; so we don't need to draw it again and can go to the next cell.
	;
gotDataCell:
		mov	cx, ss:locals.CL_data3		;cx <- column of cell
gotDataCell2:
		SpreadsheetCellLock
		jnc	done				;branch if cell empty
	;
	; Finally attempt to draw the cell.
	;
		call	DrawOverlapCell
		SpreadsheetCellUnlock
		jmp	doneSetRow

	;
	; The cell exists, so normally we'd be done.  However, we
	; double-check that the cell isn't "empty" (ie. exists because
	; it has attributes or dependencies).  If it is, we treat it
	; as if the cell didn't exist.
	;
doneCheck:
		mov	di, es:[di]			;es:di <- ptr to data
		cmp	es:[di].CC_type, CT_EMPTY
		je	searchLeft
	;
	; Record the last known cell with data in it or that we've drawn.
	; This allows us a small optimization, since we know we don't
	; need to search back any further than this cell (assuming it is
	; in the same row).
	;
done:
		mov	ss:locals.CL_data3, cx
doneSetRow:
		mov	ss:locals.CL_data2, ax
	;
	; Make sure we don't back up.  If we've gotten to the current
	; column, we've either verified it doesn't overlap anything,
	; or is empty and we've drawn anything that might be overlapping
	; it to the left, and FindCellOverlapNoLock() has set the column
	; to what was overlapped.  This means there is nothing to our
	; left that needs redrawing, so we can update the column accordingly.
	;
		pop	cx
		cmp	cx, ss:locals.CL_data3		;backing up?
		jbe	columnOK			;branch if not
		mov	ss:locals.CL_data3, cx		;set to current column
columnOK:
		clc					;carry <- don't abort

		.leave
		ret
CellDrawOverlap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOverlapCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a cell to deal with it overlapping empty cells

CALLED BY:	CellDrawOverlap()

PASS:		ss:bp - ptr to RangeDraw() local variables
			CL_drawFlags - SpreadsheetDrawFlags
			CL_gstate - GState for drawing
			CL_styleToken - current style token
			CL_data1.low - CellBorderInfo
				--- cell borders that have been seen
				--- for the range being drawn
			CL_data2,3 - (r,c) of last data cell
		(ax,cx) - (r,c) of cell
		*es:di - ptr to cell data

RETURN:		ss:bp - ptr to RangeDraw() local variables
			CL_data1.low - CellBorderInfo (updated)
			CL_styleToken - current style token (updated)
			CL_data2,3 - (r,c) of last data cell (updated)
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawOverlapCell		proc	near
	locals	local	CellLocals
		.enter	inherit

	;
	; Try formatting the cell and checking its overlap.  This means
	; that if the cell is drawn, it will have been formatted twice,
	; but in the (hopefully more likely) event it doesn't have
	; overlap, we can bail early without drawing anything since
	; that was already dealt with in the first pass.  We're only
	; interested in overlap, not the real bounds, so we just pass
	; the size of the cell for the bounds (0,0,width,height).
	;
		call	RowGetHeight
		jz	quitSet				;branch if hidden
		mov	ss:locals.CL_bounds.R_bottom, dx
		call	ColumnGetWidth
		jz	quitSet				;branch if hidden
		mov	ss:locals.CL_bounds.R_right, dx
		clr	ss:locals.CL_bounds.R_top
		clr	ss:locals.CL_bounds.R_left
		push	di
		mov	dx, es:[di]			;es:dx <- ptr to data
		mov	di, ss:locals.CL_gstate		;di <- GState
		call	FindCellOverlapNoLock
		pop	di				;*es:di <- cell data
		jnz	quitSet				;branch if no overlap
	;
	; Finally draw the bugger...
	;
		stc					;carry <- cell exists
		call	CellDrawInt
quit:

		.leave
		ret

	;
	; We didn't call FindCellOverlapNoLock() or we did and it said
	; there was no overlap.  Set the last column drawn to the current
	; one.
	;
quitSet:
		mov	ss:locals.CL_data3, cx
		jmp	quit
DrawOverlapCell		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEmptyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a cell is empty or doesn't exist

CALLED BY:	CellDrawOverlap(), FindCellOverlapNoLock()
PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cl) - (r,c) of cell
RETURN:		carry -
			set if cell exists
		else:
			cell is empty
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEmptyCell		proc	near
		uses	es, di
		.enter

	;
	; See if the cell exists at all.
	;
		SpreadsheetCellLock
		jnc	done			;branch if cell doesn't exist
	;
	; The cell exists, so see if it is empty or not
	;
		mov	di, es:[di]		;es:di <- ptr to cell data
		cmp	es:[di].CC_type, CT_EMPTY
		je	unlockCell		;branch (carry clear)
		stc				;carry <- cell is non-empty
unlockCell:
		SpreadsheetCellUnlock		;preserves flags
done:

		.leave
		ret
CheckEmptyCell		endp

DrawCode ends
