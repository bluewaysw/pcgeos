COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		spreadsheetExtent.asm
FILE:		spreadsheetExtent.asm

AUTHOR:		Gene Anderson, Oct  9, 1991

ROUTINES:
	Name			Description
	----			-----------
METHOD	SpreadsheetGetExtent	Get bounds of populated spreadsheet
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/ 9/91	Initial revision

DESCRIPTION:
	Code for finding various bounds of the spreadsheet

	$Id: spreadsheetExtent.asm,v 1.1 97/04/07 11:13:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetExtent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the extent of the spreadsheet

CALLED BY:	via MSG_SPREADSHEET_GET_EXTENT
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= SpreadsheetExtentType
RETURN:		ax/cx	= Row/Column of top-left of extent
		dx/bp	= Row/Column of bottom-right of extent
		
		ax	= -1 if there is no spreadsheet data
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetExtent	method	SpreadsheetClass,
			MSG_SPREADSHEET_GET_EXTENT
	.enter
	mov	si, di				;ds:si <- instance ptr

	mov	di, cx				;di <- SpreadsheetExtentType
	call	CallRangeExtentWholeSheet	;enum me jesus
	;
	; ax/cx = Top/left of the extent
	; dx/bx = Bottom/right of the extent
	;
	; ax	= -1 if there was no data
	;
	.leave

	mov	bp, bx				; Return value in bp
	ret
SpreadsheetGetExtent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtentEntireSheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range of cells in the entire sheet

CALLED BY:	SpreadsheetGetExtent via RangeEnum
PASS:		ds:si	= Instance ptr
		*es:di	= Pointer to the cell data
		ax/cx	= Row/Column of the cell
		ss:bp	= Pointer to inherited CellRange
RETURN:		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtentEntireSheet	proc	far
extent	local	CellRange
	.enter	inherit
EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>
EC <	call	ECCheckInstancePtr		;>
	cmp	extent.CR_start.CR_row, -1		; Check for first call
	jne	checkTop
	
	;
	; First call, set the cell.
	;
	mov	extent.CR_start.CR_row, ax
	mov	extent.CR_end.CR_row, ax
	mov	extent.CR_start.CR_column, cx
	mov	extent.CR_end.CR_column, cx
	jmp	quit

checkTop:
	cmp	extent.CR_start.CR_row, ax
	jbe	skipTopSet
	mov	extent.CR_start.CR_row, ax
skipTopSet:

	cmp	extent.CR_end.CR_row, ax
	jae	skipBottomSet
	mov	extent.CR_end.CR_row, ax
skipBottomSet:

	cmp	extent.CR_start.CR_column, cx
	jbe	skipLeftSet
	mov	extent.CR_start.CR_column, cx
skipLeftSet:

	cmp	extent.CR_end.CR_column, cx
	jae	skipRightSet
	mov	extent.CR_end.CR_column, cx
skipRightSet:

quit:
	clc					; Signal: continue
	.leave
	ret
ExtentEntireSheet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtentNoEmptyCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range of cells in the entire sheet but don't count
		CT_EMPTY cells

CALLED BY:	SpreadsheetGetExtent via RangeEnum
PASS:		ds:si	= Instance ptr
		*es:di	= Pointer to the cell data
		ax/cx	= Row/Column of the cell
		ss:bp	= Pointer to inherited CellRange
RETURN:		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtentNoEmptyCells	proc	far
EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>
EC <	call	ECCheckInstancePtr		;>
	mov	di, es:[di]			;*es:di <- ptr to cell data
	cmp	es:[di].CC_type, CT_EMPTY
	je	quit				; Carry is clear if we branch
	;
	; It's not an empty cell. Accumulate information about it.
	;
EC <	stc					; reset the carry for EC >
	call	ExtentEntireSheet		; Handle it...
quit:
	ret
ExtentNoEmptyCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtentNoEmptyCellsNoHdrFtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range of cells in the entire sheet but don't count
		CT_EMPTY cells or cells in the header or footer

CALLED BY:	SpreadsheetGetExtent via RangeEnum
PASS:		ds:si	= Instance ptr
		*es:di	= Pointer to the cell data
		ax/cx	= Row/Column of the cell
		ss:bp	= Pointer to inherited CellRange
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtentNoEmptyCellsNoHdrFtr	proc	far
	class	SpreadsheetClass
EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>
EC <	call	ECCheckInstancePtr		;>
	;
	; Check to see if the row/column falls within the header range.
	;
	cmp	ax, ds:[si].SSI_header.CR_start.CR_row
	jb	notHeader
	cmp	ax, ds:[si].SSI_header.CR_end.CR_row
	ja	notHeader
	cmp	cx, ds:[si].SSI_header.CR_start.CR_column
	jb	notHeader
	cmp	cx, ds:[si].SSI_header.CR_end.CR_column
	jbe	quit
notHeader:
	;
	; Check to see if the row/column falls within the footer range.
	;
	cmp	ax, ds:[si].SSI_footer.CR_start.CR_row
	jb	notFooter
	cmp	ax, ds:[si].SSI_footer.CR_end.CR_row
	ja	notFooter
	cmp	cx, ds:[si].SSI_footer.CR_start.CR_column
	jb	notFooter
	cmp	cx, ds:[si].SSI_footer.CR_end.CR_column
	jbe	quit
notFooter:
	;
	; Row and column aren't in the header or footer
	;
EC <	stc					; reset carry for EC >
	call	ExtentNoEmptyCells		; Handle it...
quit:
	clc					; Continue processing
	ret
ExtentNoEmptyCellsNoHdrFtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtentNextTransitionCellCur{Row,Col}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find next cell at exists/doesn't transition
CALLED BY:	CalcKbdCtrl{Down,Right}

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx),
		(dx,bx) - range to search
RETURN:		(ax,cx) - next cell of opposite state
DESTROYED:	bx, dx, di

PSEUDO CODE/STRATEGY:
	We have one of the following conditions:
	  (1) on data cell, next to data cell	(last data)
	  (2) on data cell, next to empty cell	(next data)
	  (3) on empty cell, next to data cell	(next data)
	  (4) on empty cell, next to empty cell	(next data)
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtentNextTransitionCellCurRow		proc	far
	class	SpreadsheetClass
extent		local	CellRange
reParams	local	RangeEnumParams
	.enter
ForceRef extent
ForceRef reParams

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row		;ax <- current row
	mov	dx, ax				;dx <- current row

	call	GetCellStatus			;on empty cell? (#3 & #4)
	pushf
	call	GetNextColumnFar		;don't search first column
	popf
	call	ExtentNextTransitionCellCommon

	.leave
	ret
ExtentNextTransitionCellCurRow		endp

ExtentNextTransitionCellCurCol	proc	far
	class	SpreadsheetClass
extent		local	CellRange
reParams	local	RangeEnumParams
	.enter
ForceRef extent
ForceRef reParams

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_active.CR_column		;cx <- current column
	mov	bx, cx				;bx <- current column

	call	GetCellStatus			;on empty cell? (#3 & #4)
	pushf
	call	GetNextRowFar			;don't search first row
	popf
	call	ExtentNextTransitionCellCommon

	.leave
	ret
ExtentNextTransitionCellCurCol	endp

ExtentNextTransitionCellCommon	proc	near
	class	SpreadsheetClass
extent		local	CellRange
reParams	local	RangeEnumParams
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	mov	di, SET_NEXT_DATA_CELL		;assume next cell is empty
	jnc	doEnum				;branch if empty
	call	GetCellStatus			;next to empty cell? (#2)
	jnc	doEnum				;branch if empty
	mov	di, SET_LAST_DATA_CELL		;case #1
doEnum:
	call	CallRangeExtent			;enum me jesus
	jne	done				;branch if found
	mov	ax, ss:reParams.REP_bounds.R_bottom
	mov	cx, ss:reParams.REP_bounds.R_right
done:
	.leave
	ret
ExtentNextTransitionCellCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtentPrevTransitionCellCur{Row,Col}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find previos cell of opposite state (exists vs. doesn't)
CALLED BY:	CalcKbdCtrl{Up,Left}

SYNOPSIS:	Find next cell of opposite state (exists vs. doesn't)
CALLED BY:	CalcKbdCtrl{Down,Up,Right,Left}

PASS:		ds:si - ptr to Spreadsheet instance
		(dx,bx),
		(ax,cx) - range to search (NOTE: reverse order!)
RETURN:		(ax,cx) - next cell of opposite state
DESTROYED:	bx, dx, di

PSEUDO CODE/STRATEGY:
	We have one of the following conditions:
	  (1) on data cell, prev is data cell	(first data)
	  (2) on data cell, prev is empty cell	(prev data)
	  (3) on empty cell, prev is data cell	(prev data)
	  (4) on empty cell, prev is empty cell	(prev data)
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtentPrevTransitionCellCurRow		proc	far
	class	SpreadsheetClass
extent		local	CellRange
reParams	local	RangeEnumParams

ForceRef	extent
ForceRef	reParams
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row		;ax <- current row
	mov	dx, ax				;dx <- current row

	call	GetCellStatus			;on empty cell? (#3 & #4)
	pushf
	call	GetPreviousColumnFar		;don't search first column
	popf

	call	ExtentPrevTransitionCellCommon

	.leave
	ret
ExtentPrevTransitionCellCurRow		endp

ExtentPrevTransitionCellCurCol	proc	far
	class	SpreadsheetClass
extent		local	CellRange
reParams	local	RangeEnumParams

ForceRef	extent
ForceRef	reParams
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_active.CR_column		;cx <- current column
	mov	bx, cx				;bx <- current column

	call	GetCellStatus			;on empty cell? (#3 & #4)
	pushf
	call	GetPreviousRowFar		;don't search first row
	popf

	call	ExtentPrevTransitionCellCommon

	.leave
	ret
ExtentPrevTransitionCellCurCol	endp

ExtentPrevTransitionCellCommon	proc	near
	class	SpreadsheetClass
extent		local	CellRange
reParams	local	RangeEnumParams
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	mov	di, SET_PREV_DATA_CELL		;assume prev cell is empty
	jnc	doEnum				;branch if empty
	call	GetCellStatus			;prev empty cell? (#2)
	jnc	doEnum				;branch if empty
	mov	di, SET_FIRST_DATA_CELL		;case #1
doEnum:
	call	CallRangeExtent			;enum me jesus
	jne	done				;branch if found
	mov	ax, ss:reParams.REP_bounds.R_top
	mov	cx, ss:reParams.REP_bounds.R_left
done:
	.leave
	ret
ExtentPrevTransitionCellCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCellStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get exists/doesn't exist status of a cell
CALLED BY:	ExtentPrevTransitionCell(), ExtentNextTransitionCell()

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx) - (r,c) of cell to check
RETURN:		carry - set if cell has real data
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCellStatus	proc	near
	class	SpreadsheetClass
	uses	di
	.enter

EC <	call	ECCheckInstancePtr		;>
	SpreadsheetCellLock
	jnc	done				;branch if empty cell
	mov	di, es:[di]			;es:di <- ptr to cell data
	cmp	es:[di].CC_type, CT_EMPTY	;style only?
	SpreadsheetCellUnlock			;preserves flags
	clc					;assume style only
	je	done				;branch if style only
	stc					;carry <- cell has real data
done:

	.leave
	ret
GetCellStatus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRangeExtentWholeSheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the extent of data cells for the entire spreadsheet

CALLED BY:	UTILITY
PASS:		ds:si - ptr to Spreadsheet instance
		di - SpreadsheetExtentType
RETURN:		(ax,cx),
		(dx,bx) - range or cell found
		ax = -1 if no range or cell found
		flags - set for ax = -1
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallRangeExtentWholeSheet	proc	far
	class	SpreadsheetClass
extent		local	CellRange
reParams	local	RangeEnumParams
ForceRef extent
ForceRef reParams
	.enter

EC <	call	ECCheckInstancePtr				>

	test	di, SET_IGNORE_NONZERO_ORIGIN
	jnz	haveMin		
	test	ds:[si].SSI_flags, mask SF_NONZERO_DOC_ORIGIN
	jnz	getMin	
haveMin:
	and	di, not SET_IGNORE_NONZERO_ORIGIN
	mov	ax, MIN_ROW
	mov	cx, ax				;(ax,cx) <- start (r,c)
getMax:
	mov	dx, ds:[si].SSI_maxRow
	mov	bx, ds:[si].SSI_maxCol		;(dx,bx) <- end (r,c)
	call	CallRangeExtent

	.leave
	ret
getMin:
	push	si
	mov	si, ds:[si].SSI_chunk
	mov	ax, TEMP_SPREADSHEET_DOC_ORIGIN
	call	ObjVarFindData
	pop	si

	mov	ax, ds:[bx].SDO_rowCol.CR_row
	mov	cx, ds:[bx].SDO_rowCol.CR_column
	jmp	getMax
CallRangeExtentWholeSheet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRangeExtent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup common params and call RangeEnum() for finding extent
CALLED BY:	ExtentNextTransitionCell(), SpreadsheetGetExtent()

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx),
		(dx,bx) - range of cells to search
		ss:bp - inherited RangeEnumParams & CellRange
		di - SpreadsheetExtentType
RETURN:		(ax,cx),
		(dx,bx) - range or cell found
		ax = -1 if no range or cell found
		flags - set for ax = -1
		ss:bp - RangeEnumParams - range searched
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

extentCallbacks	nptr	\
	offset cs:ExtentEntireSheet,		; SET_ENTIRE_SHEET
	offset cs:ExtentNoEmptyCells,		; SET_NO_EMPTY_CELLS
	offset cs:ExtentNoEmptyCellsNoHdrFtr,	; SET_NO_EMPTY_CELLS_NO_HDR_FTR
	offset cs:ExtentNextDataCell,		; SET_NEXT_DATA_CELL
	offset cs:ExtentLastDataCell,		; SET_LAST_DATA_CELL
	offset cs:ExtentPrevDataCell,		; SET_PREV_DATA_CELL
	offset cs:ExtentFirstDataCell		; SET_FIRST_DATA_CELL

extentFlags	RangeEnumFlags \
	0,					; SET_ENTIRE_SHEET
	0,					; SET_NO_EMPTY_CELLS
	0,					; SET_NO_EMPTY_CELLS_NO_HDR_FTR
	0,					; SET_NEXT_DATA_CELL
	mask REF_ALL_CELLS,			; SET_LAST_DATA_CELL
	0,					; SET_PREV_DATA_CELL
	mask REF_ALL_CELLS			; SET_FIRST_DATA_CELL

CheckHack <(SET_NO_EMPTY_CELLS-SET_ENTIRE_SHEET) eq 2>

CallRangeExtent	proc	far
	class	SpreadsheetClass
extent		local	CellRange
reParams	local	RangeEnumParams
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>

	;
	; Make sure the range is ordered
	;
	cmp	ax, dx				;rows OK?
	jbe	rowsOK
	xchg	ax, dx
rowsOK:
	cmp	cx, bx				;columns OK?
	jbe	colsOK
	xchg	cx, bx
colsOK:

	mov	ss:reParams.REP_bounds.R_top, ax
	mov	ss:reParams.REP_bounds.R_left, cx
	mov	ss:reParams.REP_bounds.R_bottom, dx
	mov	ss:reParams.REP_bounds.R_right, bx
	mov	dx, cs:extentCallbacks[di]	;dx <- offset of callback
	mov	ss:reParams.REP_callback.offset, dx
	mov	ss:reParams.REP_callback.segment, SEGMENT_CS
	shr	di, 1				;table o' bytes
	mov	dl, cs:extentFlags[di]		;dl <- RangeEnumFlags

	lea	bx, ss:reParams			;ss:bx <- ptr to RangeEnumParams
	mov	ss:extent.CR_start.CR_row, -1		;init top to not found
CheckHack <offset SSI_cellParams eq 0 >
	call	RangeEnum			;enum me jesus...
	mov	ax, ss:extent.CR_start.CR_row
	mov	cx, ss:extent.CR_start.CR_column		;(ax,cx) <- (r,c) of cell
	mov	dx, ss:extent.CR_end.CR_row
	mov	bx, ss:extent.CR_end.CR_column		;(dx,bx) <- (r,c) of end, if any
	cmp	ax, -1				;any data?

	.leave
	ret
CallRangeExtent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtentNextDataCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for finding next data cell in range
CALLED BY:	ExtentNextTransitionCell() via RangeEnum()

PASS:		ss:bp - ptr to CellRange
		(ax,cx) - cell coordinates (r,c)
		*es:di - ptr to cell data
RETURN:		carry - set to abort
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtentNextDataCell	proc	far
	uses	di
extent	local	CellRange
	.enter	inherit

EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>
	mov	di, es:[di]			;es:di <- ptr to cell data
	cmp	es:[di].CC_type, CT_EMPTY	;format only?
	clc					;don't abort (z flag OK)
	jne	cellFound			;branch if actual data
done:
	.leave
	ret

cellFound:
	mov	extent.CR_start.CR_column, cx
	mov	extent.CR_start.CR_row, ax
	stc					;carry <- abort enum
	jmp	done

ExtentNextDataCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtentLastDataCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find last data cell in current contiguous range
CALLED BY:	ExtentNextTransitionCell() via RangeEnum()

PASS:		ss:bp - ptr to CellRange
		(ax,cx) - cell coordinates (r,c)
		*es:di - ptr to cell data, if any
		carry - set if cell has data
RETURN:		carry - set to abort
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtentLastDataCell	proc	far
	uses	di
extent	local	CellRange
	.enter	inherit

	;
	; See if the cell is empty, or has no real data
	;
	jnc	noData				;branch if no data
	mov	di, es:[di]			;es:di <- ptr to cell data
	cmp	es:[di].CC_type, CT_EMPTY	;styles only?
	je	noData				;branch if no data
	;
	; We're over a data cell -- record the position
	;
	mov	ss:extent.CR_start.CR_column, cx
	mov	ss:extent.CR_start.CR_row, ax
doneNoAbort:
	clc					;carry <- don't abort
done:
	.leave
	ret

noData:
	cmp	ss:extent.CR_start.CR_row, -1		;seen any data cells yet?
	je	doneNoAbort			;branch if no data cells
	stc					;abort
	jmp	done				;and we're done
ExtentLastDataCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtentPrevDataCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for finding previous data cell in range
CALLED BY:	ExtentPrevTransitionCell() via RangeEnum()

PASS:		ss:bp - ptr to CellRange
		(ax,cx) - cell coordinates (r,c)
		*es:di - ptr to cell data
RETURN:		carry - clear (don't abort)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: RangeEnum() goes left to right and top to bottom
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtentPrevDataCell	proc	far
	uses	di
extent	local	CellRange
	.enter	inherit

EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>
	mov	di, es:[di]			;es:di <- ptr to cell data
	cmp	es:[di].CC_type, CT_EMPTY	;format only?
	je	done				;branch if empty
	;
	; We assume the search is done top to bottom, left to right.
	; Make sure that is actually the case
	;
EC <	cmp	ss:extent.CR_start.CR_row, -1		;not called yet?>
EC <	je	cellOK				;>
EC <	cmp	ax, ss:extent.CR_start.CR_row		;>
EC <	ERROR_B	RANGE_ENUM_ORDER_CHANGED	;>
EC <	cmp	cx, ss:extent.CR_start.CR_column		;>
EC <	ERROR_B	RANGE_ENUM_ORDER_CHANGED	;>
EC <cellOK:					;>
	mov	ss:extent.CR_start.CR_row, ax
	mov	ss:extent.CR_start.CR_column, cx		;save current cell
done:
	clc					;don't abort

	.leave
	ret
ExtentPrevDataCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtentFirstDataCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find first data cell in current contiguous range
CALLED BY:	ExtentNextTransitionCell() via RangeEnum()

PASS:		ss:bp - ptr to CellRange
		(ax,cx) - cell coordinates (r,c)
		*es:di - ptr to cell data, if any
		carry - set if cell has data
RETURN:		carry - set to abort
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtentFirstDataCell	proc	far
	uses	di
extent	local	CellRange
	.enter	inherit

	;
	; See if the cell is empty, or has no real data
	;
	jnc	noData				;branch if no data
	mov	di, es:[di]			;es:di <- ptr to cell data
	cmp	es:[di].CC_type, CT_EMPTY	;format only?
	je	noData				;branch if no data
	;
	; We're over a data cell -- record this as the start of a
	; of a range of data cells if we don't already have one...
	;
	cmp	ss:extent.CR_start.CR_row, -1		;any range yet?
	jne	done				;branch if we've got a range
	mov	ss:extent.CR_start.CR_row, ax
	mov	ss:extent.CR_start.CR_column, cx		;save current cell
done:
	clc					;carry <- don't abort

	.leave
	ret

noData:
	mov	ss:extent.CR_start.CR_row, -1		;no range
	jmp	done
ExtentFirstDataCell	endp

ExtentCode	ends
