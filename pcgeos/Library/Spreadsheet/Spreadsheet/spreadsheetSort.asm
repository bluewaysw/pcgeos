COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetSort.asm

AUTHOR:		John Wedgwood, Aug  1, 1991

METHODS:
	Name				Description
	----				-----------
	MSG_SPREADSHEET_SORT_RANGE	Sort a range of the spreadsheet

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 8/ 1/91	Initial revision

DESCRIPTION:
	Implementation of sorting.

	$Id: spreadsheetSort.asm,v 1.1 97/04/07 11:13:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSortSpaceCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSortRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort a range of the spreadsheet.

CALLED BY:	via MSG_SPREADSHEET_SORT_RANGE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		es	= Class segment
		ax	= Method
		cl	= RangeSortFlags (see cell.def)
RETURN:		ax	= RangeSortError
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Parameters structure passed to the comparison callback.
;
SpreadsheetSortRange	method	SpreadsheetClass, MSG_SPREADSHEET_SORT_RANGE
params		local	RangeSortParams
reParams	local	RangeEnumParams
	.enter
	mov	si, di				; ds:si <- instance ptr

	call	SpreadsheetMarkBusy
	;
	; Initialize the parameters.
	;
	mov	params.RSP_flags, cl
	;
	; Get the range to sort
	;
	call	GetSortRange
	jz	quit				;branch if no data
	mov	params.RSP_range.R_left, cx
	mov	params.RSP_range.R_right, bx
	mov	params.RSP_range.R_bottom, dx
	mov	params.RSP_range.R_top, ax
	;
	; Copy the active cell (so we know which entry in the row/column to
	; look at).
	;
	mov	ax, ds:[si].SSI_active.CR_row
	mov	params.RSP_active.P_y, ax
	mov	ax, ds:[si].SSI_active.CR_column
	mov	params.RSP_active.P_x, ax
	
	;
	; Set up the callback routine.
	;
	mov	params.RSP_callback.segment, SEGMENT_CS
	mov	params.RSP_callback.offset, offset cs:SpreadsheetSortCallback

	;
	; ds:si	= Spreadsheet instance (CellFunctionParameters)
	; ss:bp	= Stack frame
	;
	
	lea	bx, reParams			; ss:bx <- RangeEnumParams
	call	CellGetExtent			; Get the spreadsheet extent

	cmp	ss:[bx].REP_bounds.R_top, -1	; Check for empty sheet
	je	quit				; Branch if sheet is empty

	;
	; The spreadsheet has data, remove the old dependencies before
	; doing anything silly like sorting the data.
	;
	call	RemoveOldDependencies		; Remove all dependencies

	push	bp				; Save frame ptr
	lea	bp, params			; ss:bp <- ptr to base of block
	call	RangeSort			; Sort the range
						; ax <- RangeSortError
	pop	bp				; Restore frame ptr

	push	ax				; Save return value

	;
	; The data is sorted, now generate the dependencies again.
	;
	call	RegenerateDependencies		; Put them back
	
	;
	; Recalculate all of the row-heights
	;
	mov	ax, params.RSP_range.R_top	; ax <- Top of range
	mov	cx, params.RSP_range.R_bottom	; cx <- Bottom of range
	call	RecalcRowHeightsInRange		; Nukes: bx, cx, dx
	;
	; Force the spreadsheet to draw now that we're done,
	; and update the UI (the active cell may have different
	; contents, but it won't have moved)
	; We update the UI for:
	;	edit bar
	;	cell notes
	; NOTE: we also recalculate the document size because
	; there are cases where it may change when sorting.
	;
	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE
	jnz	noRedraw
	mov	ax, SNFLAGS_ACTIVE_CELL_DATA_CHANGE
	call	UpdateDocUIRedrawAll
noRedraw:
	;
	; We need to recalculate everything.
	;
	call	ManualRecalc			; Recalculate everything

	pop	ax				; Restore return value
quit:
	call	SpreadsheetMarkNotBusy

	.leave
	ret
SpreadsheetSortRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSortRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range for sorting based on the selection & data

CALLED BY:	SpreadsheetSortRange()
PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		z flag - set (jz) if no data in selection
		(ax,cx),
		(dx,bx) - range to sort
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSortRange		proc	near
	class	SpreadsheetClass
extent		local	CellRange
reParams	local	RangeEnumParams
ForceRef extent
ForceRef reParams
	.enter

	;
	; Get the extent of the data within the selection.
	;
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	bx, ds:[si].SSI_selected.CR_end.CR_column
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
	mov	di, SET_NO_EMPTY_CELLS
	call	CallRangeExtent
	jz	quit				;branch if no data in range
	;
	; We don't use the top bound we found because if there are
	; empty cells at the start of the selection, we want them
	; to go to the end whether sorting is ascending or descending.
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
quit:

	.leave
	ret
GetSortRange		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveOldDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove dependencies for every cell in a range.

CALLED BY:	SpreadsheetSortRange
PASS:		ss:bx	= RangeEnumParams with REP_bounds filled in.
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveOldDependencies	proc	near
	uses	dx
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	ss:[bx].REP_callback.segment, SEGMENT_CS
	mov	ss:[bx].REP_callback.offset, offset cs:RemDepsCallback
	clr	dl
	call	RangeEnum
	.leave
	ret
RemoveOldDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemDepsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove dependencies from a cell, possibly removing the cell.

CALLED BY:	RemoveOldDependencies
PASS:		ds:si	= Spreadsheet instance
		ax	= Row
		cx	= Column
		ss:bx	= RangeEnumParams
		*es:di	= Pointer to cell data (must exist)
		carry set always
RETURN:		carry clear always
		dl	= with both these bits set if we free'd the cell:
				REF_OTHER_ALLOC_OR_FREE
				REF_CELL_FREED
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemDepsCallback	proc	far
	uses	di
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	di, es:[di]			; es:di <- cell pointer
	call	SpreadsheetCellNukeDependencies	; Kiss them all good-bye

	mov	es:[di].CC_dependencies.segment,0
	
	SpreadsheetCellDirty			; Cell is dirty

	;
	; Check for cell nukable.
	;
	cmp	es:[di].CC_type, CT_EMPTY	; Check for empty cell
	jne	hasData				; Branch if it's not empty
	
	cmp	es:[di].CC_attrs, DEFAULT_STYLE_TOKEN
	jne	hasData				; Branch if it has a style

	cmp	es:[di].CC_notes.segment, 0	; Check for has a note
	jne	hasData
	
	;
	; The cell should be removed.
	;
	push	dx				; Save passed flags
	
	SpreadsheetCellUnlock			; Release the cell
	clr	dx				; dx == 0 means remove the cell
	SpreadsheetCellReplaceAll		; Nuke the data
	
	pop	dx				; Restore passed flags
	or	dl, mask REF_OTHER_ALLOC_OR_FREE or \
		    mask REF_CELL_FREED

hasData:
	clc					; Signal: continue
	.leave
	ret
RemDepsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegenerateDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Regenerate dependencies for all cells in a range.

CALLED BY:	SpreadsheetSortRange
PASS:		ss:bx	= RangeEnumParams with REP_bounds filled in
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RegenerateDependencies	proc	near
	uses	dx
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	ss:[bx].REP_callback.segment, SEGMENT_CS
	mov	ss:[bx].REP_callback.offset, offset cs:CreateDepsCallback
	
	clr	dl
	call	RangeEnum
	.leave
	ret
RegenerateDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateDepsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create dependencies for a cell

CALLED BY:	RangeEnum
PASS:		ds:si	= Spreadsheet instance
		ax	= Row
		cx	= Column
		ss:bx	= RangeEnumParams
		*es:di	= Cell data
		carry set always
RETURN:		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateDepsCallback	proc	far
	uses	bx, dx
	.enter
EC <	call	ECCheckInstancePtr		;>
	
	;
	; We need to save the handle to the cells block because the block
	; may move on the heap when we add dependencies.
	;
	push	es:LMBH_handle			; Save block handle
		
	clr	dx				; Add dependencies
	call	FormulaCellAddParserRemoveDependencies

	pop	bx				; bx <- block handle
	call	MemDerefES			; Restore segment address
		
	.leave
	or	dl, mask REF_OTHER_ALLOC_OR_FREE
	clc					; Signal: continue
	ret
CreateDepsCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSortCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two cells

CALLED BY:	RangeSort
PASS:		ds:si	= Pointer to first cell
		es:di	= Pointer to second cell
		ax	= RangeSortCellExistsFlags
		ss:bx	= RangeSortParams
RETURN:		Flags set for comparison (ds:si to es:di)
DESTROYED:	cx, dx, di, si, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetSortCallback	proc	far
	.enter
	;
	; Get the types of the two cells.
	;
	mov	cl, CT_EMPTY			; Assume cell #1 doesn't exist

	test	ax, mask RSCEF_FIRST_CELL_EXISTS
	jz	gotFirstCellType		; Branch if doesn't
	mov	cl, ds:[si].CC_type		; cl <- cell #1 type

gotFirstCellType:
	mov	ch, CT_EMPTY			; Assume cell #2 doesn't exist

	test	ax, mask RSCEF_SECOND_CELL_EXISTS
	jz	gotSecondCellType		; Branch if doesn't
	mov	ch, es:[di].CC_type		; ch <- cell #2 typee

gotSecondCellType:

	;
	; ds:si	= Pointer to first cell (if it exists)
	; cl	= Type of the first cell (CT_EMPTY if it doesn't exist)
	;
	; es:di	= Pointer to second cell (if it exists)
	; ch	= Type of the second cell (CT_EMPTY if it doesn't exist)
	;
	call	CompareCellData
	.leave
	ret
SpreadsheetSortCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareCellData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the data in two cells that actually exist

CALLED BY:	CompareCells
PASS:		ds:si	= Pointer to first cells data
		es:di	= Pointer to second cells data
		cl	= Type of the first cell
		ch	= Type of the second cell
		ss:bx	= Pointer to RangeSortParams
RETURN:		Flags set for comparison of ds:si to es:di
DESTROYED:	cx, dx, di, si, bp

PSEUDO CODE/STRATEGY:
	The cell types we need to compare:
		CT_TEXT		<- Text string
		CT_CONSTANT	<- Numeric constant
		CT_FORMULA	<- Result is text, number, error
		CT_EMPTY	<- As if cell doesn't exist
		CT_DISPLAY_FORMULA <- As if cell doesn't exist

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareCellData	proc	near
	uses	bx
	.enter
	mov	bp, bx				; ss:bp <- RangeSortParams

	;
	; First we need a pointer to the "real" data to compare and the type
	; of that data.
	;
	mov	bl, cl				; bl <- Cell type
	call	GetTypeAndPointer		; ds:si <- ptr to 1st data
						; bx <- SortType

	push	ds, si, bx			; Save ptr, type
	
	mov	bl, ch				; bl <- Cell type
	segmov	ds, es, si			; ds:si <- ptr to 2nd cell
	mov	si, di
	call	GetTypeAndPointer		; ds:si <- ptr to 2nd data
						; bx <- SortType
	
	segmov	es, ds, di			; es:di <- ptr to 2nd data
	mov	di, si
	pop	ds, si, dx			; Restore ptr, type

	;
	; ds:si	= Pointer to the first cells "real" data
	; dx	= SortType of that data
	; es:di	= Pointer to the second cells "real" data
	; bx	= SortType of that data
	; ss:bp	= RangeSortParams
	;

	;
	; We always want empty cells to come last, regardless of the sort
	; order.
	;
	cmp	dx, ST_EMPTY			;1st cell empty?
	je	cellIsEmpty			;branch if empty
	cmp	bx, ST_EMPTY			;2nd cell empty?
	je	cellIsEmpty			;branch if empty
	;
	; Check for different types. If they are we can just return the
	; flags that come back from the comparison.
	;
doNormalCompare:
	cmp	dx, bx				; Compare 1st to 2nd
	jne	quit				; Branch if different types

	;
	; Same SortType
	;
	call	cs:comparisonHandler[bx]	; Call the handler
quit:
	.leave
	ret

	;
	; The first and/or second cell is empty.  We always want empty cells
	; to come last, so if we are sorting descending, we reverse the
	; compare.
	;
cellIsEmpty:
	test	ss:[bp].RSP_flags, mask RSF_SORT_ASCENDING
	jnz	doNormalCompare
	;
	; At this point, either dx == ST_EMPTY, meaning the first cell is
	; empty or bx == ST_EMPTY meaning the second cell is empty or both.
	; If both are empty, we will return that the cells are equal,
	; which is what we want if both are empty.  If dx == ST_EMPTY but
	; bx != ST_EMPTY, we will return that the 1st cell (empty) > 2nd cell;
	; if the reverse is true, we will return that 1st cell < 2nd cell
	; (empty) which is what we  want so that empty cells will always
	; come last.
	;
	cmp	bx, dx
	jmp	quit

CheckHack <ST_EMPTY eq SortTypes-2>

CompareCellData	endp

;
; These are the different types of data we'll encounter in the cells.
;
; This list must be ordered so that the types are ordered from
; smallest to largest.
;
; For instance, if you wanted text to be sorted as less than numbers the
; ST_TEXT entry should come before the ST_NUMBER entry.
;
SortTypes	etype	word, 0, 2
ST_TEXT		enum	SortTypes
ST_NUMBER	enum	SortTypes
ST_ERROR	enum	SortTypes
ST_DISPLAY	enum	SortTypes
ST_EMPTY	enum	SortTypes

comparisonHandler	word \
	offset cs:CompareTextStrings,
	offset cs:CompareNumbers,
	offset cs:CompareErrors,
	offset cs:CompareDisplayCells,
	offset cs:CompareEmptyCells
CheckHack <(SortTypes/2) eq (length comparisonHandler)>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTypeAndPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a cell pointer and cell type, return a pointer to
		the data to compare and the SortType of that data

CALLED BY:	CompareCellData
PASS:		ds:si	= Pointer to cell data (if it exists)
		bl	= Cell type
RETURN:		ds:si	= Pointer to data to compare
		bx	= SortType
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTypeAndPointer	proc	near
	clr	bh				; bx <- Index into table
	call	cs:getTypeHandlers[bx]		; Call the handler
	ret
GetTypeAndPointer	endp

getTypeHandlers	word \
	offset cs:GetTextPtrAndType,		; CT_TEXT
	offset cs:GetConstantPtrAndType,	; CT_CONSTANT
	offset cs:GetFormulaPtrAndType,		; CT_FORMULA
	offset cs:GetPtrAndTypeError,		; CT_NAME
	offset cs:GetPtrAndTypeError,		; CT_GRAPH
	offset cs:GetEmptyPtrAndType,		; CT_EMPTY
	offset cs:GetDisplayPtrAndType		; CT_DISPLAY_FORMULA
CheckHack <(size getTypeHandlers) eq CellType>

;
; General purpose error routine :-)
;
GetPtrAndTypeError	proc	near
EC <	ERROR	BAD_CELL_TYPE				>
NEC <	ret						>
GetPtrAndTypeError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextPtrAndType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to the text in a text cell.

CALLED BY:	GetTypeAndPointer via getTypeHandlers
PASS:		ds:si	= Cell pointer
RETURN:		ds:si	= Text pointer
		bx	= ST_TEXT
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextPtrAndType	proc	near
	add	si, size CellText		; ds:si <- ptr to text
	mov	bx, ST_TEXT
	ret
GetTextPtrAndType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetConstantPtrAndType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to the constant in a constant cell.

CALLED BY:	GetTypeAndPointer via getTypeHandlers
PASS:		ds:si	= Cell pointer
RETURN:		ds:si	= Pointer to constant
		bx	= ST_NUMBER
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetConstantPtrAndType	proc	near
	add	si, offset CC_current		; ds:si <- ptr to number
	mov	bx, ST_NUMBER
	ret
GetConstantPtrAndType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFormulaPtrAndType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to the formula result.

CALLED BY:	GetTypeAndPointer via getTypeHandlers
PASS:		ds:si	= Cell pointer
RETURN:		ds:si	= Pointer to result
		bx	= SortType
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFormulaPtrAndType	proc	near
	uses	ax, dx
	.enter
	mov	al, ds:[si].CF_return
	;
	; al = Formula result type
	; bx will hold the type
	; dx will hold the offset into the cell data
	;
	mov	bx, ST_TEXT			; Assume text
	mov	dx, size CellFormula
	cmp	al, RT_TEXT
	je	gotOffsetAndType
	
	mov	bx, ST_NUMBER			; Assume number
	mov	dx, offset CF_current
	cmp	al, RT_VALUE
	je	gotOffsetAndType
	
	;
	; Must be an error
	mov	bx, ST_ERROR			; bx <- type
						; dx already holds offset
	
gotOffsetAndType:
	add	si, dx				; ds:si <- data
	.leave
	ret
GetFormulaPtrAndType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEmptyPtrAndType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return ST_EMPTY

CALLED BY:	GetTypeAndPointer via getTypeHandlers
PASS:		nothing
RETURN:		bx	= ST_EMPTY
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetEmptyPtrAndType	proc	near
	mov	bx, ST_EMPTY
	ret
GetEmptyPtrAndType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDisplayPtrAndType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return ST_DISPLAY

CALLED BY:	GetTypeAndPointer via getTypeHandlers
PASS:		nothing
RETURN:		bx	= ST_DISPLAY
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDisplayPtrAndType	proc	near
	mov	bx, ST_DISPLAY
	ret
GetDisplayPtrAndType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareTextStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two text strings.

CALLED BY:	CompareCellData via comparisonHandler
PASS:		ds:si	= First string
		es:di	= Second string
		ss:bp	= RangeSortParams
RETURN:		Flags set for comparison
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareTextStrings	proc	near
	uses	cx
	.enter
	clr	cx			; Null terminated strings

	test	ss:[bp].RSP_flags, mask RSF_IGNORE_SPACES
	jnz	ignoreSpaces

	test	ss:[bp].RSP_flags, mask RSF_IGNORE_CASE
	jnz	ignoreCase

	call	LocalCmpStrings		; Compare (with case)
quit:
	.leave
	ret

ignoreCase:
	call	LocalCmpStringsNoCase
	jmp	quit

ignoreSpaces:
	test	ss:[bp].RSP_flags, mask RSF_IGNORE_CASE
	jnz	ignoreSpaceCase
	call	LocalCmpStringsNoSpace
	jmp	quit

ignoreSpaceCase:
	call	LocalCmpStringsNoSpaceCase
	jmp	quit
CompareTextStrings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two numbers.

CALLED BY:	CompareCellData via comparisonHandler
PASS:		ds:si	= First number
		es:di	= Second number
RETURN:		Flags set for comparison
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareNumbers	proc	near
	uses	ax, ds, si
	.enter
	call	FloatPushNumber		; Push (ds:si) onto the stack
	
	segmov	ds, es, si		; ds:si <- ptr to 2nd number
	mov	si, di
	
	call	FloatPushNumber		; Push (es:di) onto the stack

	call	FloatCompAndDrop	; Compare numbers
	.leave
	ret
CompareNumbers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareErrors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two errors.

CALLED BY:	CompareCellData via comparisonHandler
PASS:		ds:si	= First error
		es:di	= Second error
RETURN:		Flags set for comparison
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareErrors	proc	near
	clr	ax		; Set "zero" (equal) flag
	ret
CompareErrors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareEmptyCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two empty cells (hah)

CALLED BY:	CompareCellData via comparisonHandler
PASS:		nothing
RETURN:		Flags set for comparison
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareEmptyCells	proc	near
	clr	ax		; Set "zero" (equal) flag
	ret
CompareEmptyCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareDisplayCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two display-formula cells (hah)

CALLED BY:	CompareCellData via comparisonHandler
PASS:		nothing
RETURN:		Flags set for comparison
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareDisplayCells	proc	near
	clr	ax		; Set "zero" (equal) flag
	ret
CompareDisplayCells	endp

SpreadsheetSortSpaceCode	ends
