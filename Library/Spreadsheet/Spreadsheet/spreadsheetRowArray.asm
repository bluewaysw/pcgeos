COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetRowArray.asm

AUTHOR:		Gene Anderson, Mar  7, 1991

ROUTINES:
	Name			Description
	----			-----------
EXT	ColumnGetWidth		Get width of a column
EXT	ColumnSetWidth		Set width of a column
EXT	RowGetHeight		Get height of a row
EXT	RowSetHeight		Set height of a row

EXT	RowGetRelPos32		Get 32-bit relative position
EXT	RowGetRelPos16		Get 16-bit visible position
EXT	ColumnGetRelPos32	Get 32-bit relative position
EXT	ColumnGetRelPos16	Get 16-bit visible position

EXT	Pos32ToVisCell		Get cell under visible position
EXT	Pos32ToCellRel		Get cell under position
EXT	Pos32ToRowRel		Get row under position
EXT	Pos32ToColRel		Get column under position

INT	LockRowArray		Lock row or column array
INT	RowGetHeightInt		Get width or height from array
INT	RowGetPositionInt	Get row of column offset from array

EXT	RowColArrayInit		Create and initialize row and column arrays
INT	RowArrayAlloc		Create row or column array

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/ 7/91		Initial revision

DESCRIPTION:
	Routines for manipulating row height and column width arrays.

	Since there are large number of rows (8192), a normal array
	is not practical.  Instead, row heights are stored as runs.
	Each entry in the array implies: "all rows since the last entry
	up to and including the current row are of this height."

	The result is generally a very compact method of storage.
	A direct-acess array of row heights would be faster to
	access, but would require a staggering 16K of space to
	hold, no matter how many rows were actually in use in the
	spreadsheet.  The method described here will result in a
	very compact array.  The worst-case is if each row was
	was a different height than the one before it, resulting in
	twice as much space (32K) as required for the direct array.  The
	average case for normal spreadsheets will be much more compact.

	NOTE: To simplify changing a row height, the definition of
	the array is expanded to include the rows outside the
	bounds of spreadsheet, similar to the way regions are defined.
	Rows outside the spreadsheet have height -1 so they will never
	match rows within the spreadsheet.

	Consider the following examples:

	A new spreadsheet will have:
		r=0,h=-1
		r=8192,h=14
		r=8193,h=-1
		-----------
		= 12 bytes

	A spreadsheet with rows 5 and 6 18 points will have:
		r=0,h=-1
		r=4,h=14
		r=6,h=18
		r=8192,h=14
		r=8193,h=-1
		----------
		= 20 bytes

	A spreadsheet with all rows changed to 18 points will have:
		r=0,h=-1
		r=8192,h=18
		r=8193,h=-1
		---------
		= 12 bytes

	NOTE: Along with the row heights, we also need to store the
	baseline for each row.  To commonize code, the column width
	array has the same size entries but uses the extra data
	for the default attributes for new cells in that column.
	NOTE: Since there is common code, the row and column
	arrays are frequently both referred to as row arrays.

	$Id: spreadsheetRowArray.asm,v 1.1 97/04/07 11:13:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowColArrayInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the row height and column width arrays.
CALLED BY:	SpreadsheetInitFile()

PASS:		bx - file handle of VM file
		dx - # of rows
		cx - # of columns
RETURN:		ax - VM handle of array
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowColArrayInit	proc	near
	uses	bx, cx, dx, si, di, bp, ds
	.enter

	push	cx
	clr	ax				;ax <- no user ID
	mov	cx, STD_INIT_HEAP		;cx <- # of bytes
	call	VMAlloc
	pop	cx
	push	ax				;save VM handle of array
	push	cx				;save # of columns
	push	dx				;save # rows
	;
	; Lock and initalize the block
	;
	call	VMLock				;ax <- seg addr of block
	mov	ds, ax				;ds <- seg addr of block
	mov	bx, bp				;bx <- memory handle
	mov	dx, (size LMemBlockHeader)	;dx <- offset of heap
	mov	ax, LMEM_TYPE_GENERAL		;ax <- LMemType
	mov	cx, ROW_ARRAY_NUM_HANDLES	;cx <- # of handles
	push	si, di, bp
	mov	si, (size RowArrayEntry)*6	;si <- amount of free space
	clr	di				;di <- LocalMemoryFlags
	clr	bp				;bp <- end of space (0 = end)
	call	LMemInitHeap
	pop	si, di, bp
	;
	; Allocate and initalize a block to use for the row height array
	;
	pop	cx				;cx <- # of rows
;;;
;;; Added 5/17/95 -jw
;;;
;;; The problem is that when you move between different platforms, the
;;; number of rows/columns varies. In order to avoid death due to the
;;; RowArray not having runs out to the right distance, or to avoid
;;; the RowArray being "too long", I've decided that it is preferable
;;; to assume some arbitrary "largest row / column" and use that value.
;;;
;;; This, combined with another minor change later to handle older docs
;;; should make this sort of thing work.
;;;
;;; The only bug I can think of, which we will probably have to live with,
;;; is that if you insert columns, then delete columns, the columns which
;;; scroll back onto the right edge (or bottom edge, for rows) will have
;;; a width that is non-standard, because it will have been preserved in
;;; the RowArray, even though the columns/rows were pushed off the bottom
;;; of the spreadsheet.
;;;
	mov	cx, ROW_ARRAY_TERMINATOR+1

	mov	dx, ROW_HEIGHT_DEFAULT
	mov	bx, ROW_BASELINE_DEFAULT or ROW_HEIGHT_AUTOMATIC
	call	RowArrayAlloc
	;
	; Allocate and initalize a block to use for the column width array
	;
	pop	cx				;cx <- # of columns
;;;
;;; Same fix as above  5/17/95 -jw
;;;
	mov	cx, COLUMN_ARRAY_TERMINATOR+1
	mov	dx, COLUMN_WIDTH_DEFAULT
	clr	bx				;bx <- default style for cols
CheckHack <DEFAULT_STYLE_TOKEN eq 0>
	call	RowArrayAlloc
	;
	; Mark the block as dirty and release it
	;
	call	VMDirty
	call	VMUnlock
	pop	ax				;ax <- VM handle of array

	.leave
	ret
RowColArrayInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowArrayAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate row or column array
CALLED BY:	RowColArrayInit()

PASS:		cx - # of rows or columns
		dx - value for 1st word
		bx - value for 2nd word
		ds - seg addr of array
		di - chunk handle of array
RETURN:		none
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowArrayAlloc	proc	near
	.enter

	push	cx
	mov	cx, (size RowArrayEntry)*3	;cx <- size of chunk
	call	LMemAlloc
	pop	cx				;cx <- # rows/columns
	mov	di, ax				;di <- chunk handle
	mov	di, ds:[di]			;ds:di <- ptr to chunk
	;
	; Initialize rows 0 through 'cx'-1 to be 'dx' points tall
	;
	dec	cx
	mov	ds:[di][(size RowArrayEntry)*1].RAE_row, cx
	mov	ds:[di][(size RowArrayEntry)*1].RAE_height, dx
	mov	ds:[di][(size RowArrayEntry)*1].RAE_baseline, bx
	;
	; Initialize all rows up to first to be NULL
	;
	mov	ax, -1
	mov	ds:[di][(size RowArrayEntry)*0].RAE_row, (MIN_ROW-1)
	mov	ds:[di][(size RowArrayEntry)*0].RAE_height, ax
	mov	ds:[di][(size RowArrayEntry)*0].RAE_baseline, ax
	;
	; Initialize all rows after 'cx' to be NULL
	;
	inc	cx
	mov	ds:[di][(size RowArrayEntry)*2].RAE_row, cx
	mov	ds:[di][(size RowArrayEntry)*2].RAE_height, ax
	mov	ds:[di][(size RowArrayEntry)*2].RAE_baseline, ax

	.leave
	ret
RowArrayAlloc	endp

InitCode	ends

DrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockRowArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a row array (either row heights or column widths)
CALLED BY:	RowGetHeight(), ColumnGetWidth()

PASS:		ds:si - ptr to Spreadsheet instance data
		ax - chunk handle of array
RETURN:		ds:si - ptr to 1st RowArrayEntry
		bp - memory handle of block
		di - chunk handle of array
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: first entry can be skipped (for rows < 0)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockRowArrayFar	proc	far
	call	LockRowArray
	ret
LockRowArrayFar	endp

LockRowArray	proc	near
	uses	bx
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	push	ax
	mov	ax, ds:[si].SSI_rowArray	;ax <- VM block handle
	mov	bx, ds:[si].SSI_cellParams.CFP_file ;bx <- handle of file
	call	VMLock
	mov	ds, ax				;ds <- seg addr of block
	pop	di				;di <- chunk handle
EC <	call	ECCheckRowArray			;>
	mov	si, ds:[di]			;ds:si <- ptr to chunk
	add	si, (size RowArrayEntry)	;ds:si <- ptr to 1st entry

	.leave
	ret
LockRowArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckRowArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify a row array is valid

CALLED BY:	LockRowArray()
PASS:		*ds:di - ptr to start of row array
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	to be valid:
	(1) no adjacent entries have have the same height and baseline
	(2) for entries i & j, i<j, row(i)<row(j)
	(3) row(0) = -1, height(0) = -1, baseline(0) = -1
	(4) row(n) = MAX+1, height(n) = -1, baseline(n) = -1
	(5) size(array) MOD (size RowArrayEntry) = 0
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK

ECCheckRowArray		proc	far
	uses	si, ax, di
	.enter

	mov	si, ds:[di]			;ds:si <- ptr to array
	ChunkSizePtr	ds, si, di		;di <- size of chunk
	add	di, si				;ds:di <- ptr to end
	;
	; Verify (3): row(0) = -1, height(0) = -1, baseline(0) = -1
	;
	cmp	ds:[si].RAE_row, -1
	ERROR_NE ROW_ARRAY_CORRUPTED
	cmp	ds:[si].RAE_height, -1
	ERROR_NE ROW_ARRAY_CORRUPTED
	cmp	ds:[si].RAE_baseline, -1
	ERROR_NE ROW_ARRAY_CORRUPTED
	;
	; For each entry, verify (1) and (2)
	;
rowLoop:
	cmp	si, di				;end of array?
	ERROR_AE ROW_ARRAY_CORRUPTED		;should have stopped on last row
	cmp	ds:[si].RAE_height, -1		;first or last row?
	jne	checkEntry
	cmp	ds:[si].RAE_row, -1		;last row?
	jne	endArray			;branch if last row
checkEntry:
	mov	ax, ds:[si].RAE_row
	cmp	ax, ds:[si][+(size RowArrayEntry)].RAE_row
	ERROR_GE ROW_ARRAY_CORRUPTED		;row(i) >= row(j)
	mov	ax, ds:[si].RAE_height
	cmp	ax, ds:[si][+(size RowArrayEntry)].RAE_height
	jne	nextEntry
	mov	ax, ds:[si].RAE_baseline
	cmp	ax, ds:[si][+(size RowArrayEntry)].RAE_baseline
	ERROR_E ROW_ARRAY_CORRUPTED		;i=j
	;
	; Also make sure the height and baseline are reasonable:
	; (a) baseline < height
	; (b) height < MAX
	;
	cmp	ds:[si].RAE_height, -1
	je	nextEntry			;skip row(0) = -1
	mov	ax, ds:[si].RAE_baseline
	andnf	ax, not (ROW_HEIGHT_AUTOMATIC)
	cmp	ax, ds:[si].RAE_height
	ERROR_A	ROW_ARRAY_CORRUPTED		;baseline > height
	cmp	ds:[si].RAE_height, ROW_HEIGHT_MAX
	ERROR_A ROW_ARRAY_CORRUPTED		;height > MAX
nextEntry:
	add	si, (size RowArrayEntry)	;ds:si <- ptr to next entry
	jmp	rowLoop


	;
	; (5) Make sure we've hit the end of the chunk exactly
	;
endArray:
	sub	di, (size RowArrayEntry)	;ds:di <- ptr to last entry(?)
	cmp	si, di				;end of array?
	ERROR_NE ROW_ARRAY_CORRUPTED
	;
	; Make sure height(n) = -1, baseline(n) = -1
	;
	cmp	ds:[si].RAE_height, -1
	ERROR_NE ROW_ARRAY_CORRUPTED
	cmp	ds:[si].RAE_baseline, -1
	ERROR_NE ROW_ARRAY_CORRUPTED

	.leave
	ret
ECCheckRowArray		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnGetWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of a column
CALLED BY:	GetCellBounds()

PASS:		cx	= column #
		ds:si	= ptr to Spreadsheet instance data
RETURN:		dx	= column width
		z flag - set if column hidden
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColumnGetWidthFar	proc	far
	call	ColumnGetWidth
	ret
ColumnGetWidthFar	endp

ColumnGetWidth	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	push	ax, cx
	mov	ax, COLUMN_ARRAY_CHUNK		;ax <- chunk of column array
	GOTO	RowGetHeightInt, cx, ax
ColumnGetWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowGetHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of a row
CALLED BY:	GetCellBounds()

PASS:		ax - row
		ds:si - ptr to Spreadsheet instance data
RETURN:		dx - row height
		z flag - set if row hidden
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowGetHeightFar	proc	far
	call	RowGetHeight
	ret
RowGetHeightFar	endp

RowGetHeight	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	push	ax, cx
	mov	cx, ax				;cx <- row #
	mov	ax, ROW_ARRAY_CHUNK		;ax <- chunk of row array
	FALL_THRU	RowGetHeightInt, cx, ax
RowGetHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowGetHeightInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the row height, part II
CALLED BY:	RowGetHeight(), ColumnGetWidth()

PASS: 		ax - VM handle of row or column array
		cx - row/column to find
		ds:si - ptr to Spreadsheet instance data
		on stack:
			saved ax
			saved cx
RETURN:		dx - row height/column width
		z flag - set if row/column hidden (cmp dx, 0)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowGetHeightInt	proc	near
	uses	bp, ds, si, di
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	LockRowArray			;ds:si <- ptr to 1st entry
	mov	ax, cx				;ax <- row/column to find

rowLoop:
EC <	call	ECRowCheckOffset		;>
	cmp	ds:[si].RAE_row, ax		;correct row?
	jae	found
	add	si, (size RowArrayEntry)	;ds:si <- ptr to next entry
	jmp	rowLoop

found:
	mov	dx, ds:[si].RAE_height		;dx <- height

	call	VMUnlock			;all done with array

	.leave

	FALL_THRU_POP	cx, ax

	cmp	dx, 0				;set flags
	ret
RowGetHeightInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnGetDefaultAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the default attributes for a column

CALLED BY:	UTILITY
PASS:		ds:si - ptr to Spreadsheet instance
		cx - column to find
RETURN:		dx - default attrs for column
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColumnGetDefaultAttrs		proc	far
EC <	call	ECCheckInstancePtr		;>
	push	ax, cx
	mov	ax, COLUMN_ARRAY_CHUNK		;ax <- chunk of column array
	GOTO	RowGetBaselineInt, cx, ax
ColumnGetDefaultAttrs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowGetBaseline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the baseline for a row

CALLED BY:	CellDrawString()
PASS:		ds:si - ptr to Spreadsheet instance
		ax - row to find
RETURN:		dx - baseline of row
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RowGetBaseline		proc	far
EC <	call	ECCheckInstancePtr		;>
	push	ax, cx
	mov	cx, ax				;cx <- row #
	mov	ax, ROW_ARRAY_CHUNK		;ax <- chunk of row array
	FALL_THRU	RowGetBaselineInt, cx, ax
RowGetBaseline		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowGetBaselineInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the row baseline offset or column default attrs
CALLED BY:	RowGetBaseline(), ColumnGetDefaultAttrs()

PASS: 		ax - VM handle of row or column array
		cx - row/column to find
		ds:si - ptr to Spreadsheet instance data
		on stack:
			saved ax
			saved cx
RETURN:		dx - row baseline
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowGetBaselineInt	proc	far
	uses	bp, ds, si, di
	.enter

EC <	call	ECCheckInstancePtr		;>

	call	LockRowArray			;ds:si <- ptr to 1st element
	mov	ax, cx				;ax <- row/column to find
rowLoop:
EC <	call	ECRowCheckOffset		;>
	cmp	ds:[si].RAE_row, ax		;correct row?
	jae	found
	add	si, (size RowArrayEntry)	;ds:si <- ptr to next entry
	jmp	rowLoop

found:
	mov	dx, ds:[si].RAE_baseline	;dx <- height
	call	VMUnlock			;all done with array

	.leave
	FALL_THRU_POP	cx, ax
	ret
RowGetBaselineInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnGetRelPos16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a column's document position, relative to another column
CALLED BY:	UTILITY

PASS:		cx - column #
		dx - origin column #
RETURN:		dx - position of column 'cx'
		bx - width of column 'cx'
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColumnGetRelPos16	proc	near
	uses	ax
	class	SpreadsheetClass
	.enter

	mov	ax, COLUMN_ARRAY_CHUNK		;ax <- chunk of column array
	call	RowGetPositionInt
EC <	cmp	ax, 0xffff			;>
EC <	je	noDeath				;>
EC <	tst	ax				;result too big?>
EC <	ERROR_NZ	VISIBLE_POSITION_TOO_LARGE	;>
EC <noDeath:					;>

	.leave
	ret
ColumnGetRelPos16	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnGetRelPos32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a column's document position, relative to another column
CALLED BY:	UTILITY

PASS:		cx - column #
		dx - column # origin
		ds:si - ptr to Spreadsheet instance data
RETURN:		ax:dx - position of column 'cx' relative to column 'dx'
		bx - width of column 'cx'
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColumnGetRelPos32	proc	near
	class	SpreadsheetClass
EC <	call	ECCheckInstancePtr		;>
	mov	ax, COLUMN_ARRAY_CHUNK		;ax <- chunk of column array
	GOTO	RowGetPositionInt
ColumnGetRelPos32	endp

ColumnGetRelPos32Far	proc	far
	call	ColumnGetRelPos32
	ret
ColumnGetRelPos32Far	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowGetRelPos16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get position of row relative to another row
CALLED BY:	GetCellBounds()

PASS:		ax - row #
		dx - row # origin
		ds:si - ptr to Spreadsheet instance data
RETURN:		dx - position of row 'ax'
		bx - height of row 'ax'
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowGetRelPos16	proc	near
	uses	ax, cx
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ax				;cx <- row #
	mov	ax, ROW_ARRAY_CHUNK		;ax <- chunk of row array
	call	RowGetPositionInt
EC <	cmp	ax, 0xffff			;>
EC <	je	noDeath				;>
EC <	tst	ax				;result too big?>
EC <	ERROR_NZ	VISIBLE_POSITION_TOO_LARGE	;>
EC <noDeath:					;>

	.leave
	ret
RowGetRelPos16	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowGetRelPos32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a row's document position, relative to another row.
CALLED BY:	GetCellBounds()

PASS:		ax - row #
		dx - row # origin
		ds:si - ptr to Spreadsheet instance data
RETURN:		ax:dx - position of row 'ax' relative to row 'dx'
		bx - height of row 'ax'
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowGetRelPos32Far	proc	far
	call	RowGetRelPos32
	ret
RowGetRelPos32Far	endp

RowGetRelPos32	proc	near
	uses	cx
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ax				;cx <- row #
	mov	ax, ROW_ARRAY_CHUNK		;ax <- chunk of row array
	call	RowGetPositionInt

	.leave
	ret
RowGetRelPos32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowGetPositionInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get row or column position relative to a cell
CALLED BY:	ColumnGetRelPosition(), RowGetRelPosition()

PASS:		ax - chunk handle of row or column array
		cx - row/column #
		dx - row/column # origin
		ds:si - ptr to Spreadsheet instance data
RETURN:		ax:dx - position of row/col cx relative to row/col dx
		bx - height/width of row/column
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	The idea behind this is that the Spreadsheet object will
	be keeping track of the upper left visible cell, and so
	cell positions for drawing can be computed based on it
	rather than from $A$1 every time.
	This routine will return a negative value if the row/column passed
	is before the row/column origin specified.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	There may be a faster way to add up row heights, like
	computing the # of rows for a gap and multiplying instead
	of adding each one up.  However, given the intended use
	of these routines, the current method should be OK.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowGetPositionInt	proc	near
	uses	cx, bp, ds, si, di
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	LockRowArray			;ds:si <- ptr to 1st element
	mov	ax, dx				;ax <- row # origin
	;
	; If the cell is before the origin cell specified, swap the rows.  
	; Later we will negate the result to make this value correct.
	;
	cmp	ax, cx				;is row before origin?
	pushf					;save results for later
	jbe	noSwap
	xchg	ax, cx				;swap row and origin
noSwap:
	;
	; Find the starting row
	;
startRowLoop:
EC <	call	ECRowCheckOffset		;>
	cmp	ds:[si].RAE_row, ax		;correct row?
	jae	startFound
	add	si, (size RowArrayEntry)	;ds:si <- ptr to next entry
	jmp	startRowLoop

	;
	; From the starting row, add heights until the
	; target row is reached.
	;
startFound:
	push	ds:[si].RAE_height
	clr	bx
	mov	dx, bx				;bx:dx <- position
endRowLoop:
EC <	call	ECRowCheckOffset		;>
	cmp	ax, ds:[si].RAE_row		;height still same?
	jbe	rowOK				;branch if same height
	add	si, (size RowArrayEntry)	;skip to next block
rowOK:
	cmp	ax, cx				;to last row?
	je	done				;branch if at last row
	add	dx, ds:[si].RAE_height		;dx <- add height of row
	adc	bx, 0
	inc	ax				;ax <- next row
	jmp	endRowLoop

done:
	mov	ax, bx				;ax:dx <- position
	mov	bx, ds:[si].RAE_height		;bx <- height of row
	call	VMUnlock			;done with array
	pop	cx				;cx = width/height of 1st row
	;
	; If the cell was before the specified origin, we negate
	; the position we've found.
	;
	popf					;flags from swap comparison
	jbe	noNegation
	negdw	axdx				;ax:dx <- -position
	mov	bx, cx				;bx = width/height of 1st row
noNegation:

	.leave
	ret
RowGetPositionInt	endp

DrawCode	ends

AttrCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnSetDefaultAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default attributes for a column

CALLED BY:	SetSpreadsheetAttrs()
PASS:		cx - column #
		ax - default attributes for column
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColumnSetDefaultAttrs		proc	far
EC <	call	ECCheckInstancePtr		;>
	push	ax, bx, cx
	mov	bx, ax				;bx <- new attr token
	mov	ax,  COLUMN_ARRAY_CHUNK
	mov	dx, -1				;dx <- don't change width
	GOTO	RowSetHeightInt,  cx, bx, ax
ColumnSetDefaultAttrs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnSetWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the width of a column
CALLED BY:	SpreadsheetSetColumnWidth()

PASS:		cx - column #
		dx - new column width
		ds:si - ptr to Spreadsheet instance data
RETURN:		dx - actual column width set
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColumnSetWidth	proc	far
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	cmp	dx, SS_COLUMN_WIDTH_MAX		;dx <- MIN( width, maxWidth )
	jbe	gotWidth
	mov	dx, SS_COLUMN_WIDTH_MAX
gotWidth:

	push	ax, bx, cx
	mov	ax, COLUMN_ARRAY_CHUNK		;ax <- chunk of column array
	mov	bx, -1				;don't change default attrs
	GOTO	RowSetHeightInt, cx, bx, ax
ColumnSetWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowSetHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the height of a row
CALLED BY:	SpreadsheetSetRowHeight()

PASS:		ax - row #
		dx - new row height
		bx - new row baseline (ROW_HEIGHT_AUTOMATIC OR'd for automatic)
		ds:si - ptr to Spreadsheet instance data

RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowSetHeight	proc	far
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	cmp	dx, ROW_HEIGHT_MAX	; dx <- MIN( height, maxHeight )
	jbe	gotHeight
	mov	dx, ROW_HEIGHT_MAX
gotHeight:

	push	ax, bx, cx
	mov	cx, ax				;cx <- row #
	mov	ax, ROW_ARRAY_CHUNK		;ax <- chunk of row array
	FALL_THRU	RowSetHeightInt, cx, bx, ax
RowSetHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowSetHeightInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the row height / column width, part II
CALLED BY:	ColumnSetWidth(), RowSetHeight()

PASS:		ax - VM block handle of row/column array
		cx - row #
		dx - new row height / column width
		bx - new baseline (0 for columns)
		(if either of dx or bx is -1, it will not be set)
		on stack:
			saved ax
			saved bx
			saved cx
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	There are several cases for setting the row height:
	(1) do nothing -- height hasn't changed
	(2) insert 0 entries (separate entry already exists)
	(3) insert 0 entries (matches run before)
	(4) insert 0 entries (matches run after)
	(5) insert 1 entry (new entry at end of run)
	(6) insert 1 entry (new entry at beginning of run)
	(7) insert 2 entries (new entry in middle of run)
	(8) delete 1 entry (was separate, matches run before)
	(9) delete 1 entry (was separate, matches run after)
	(10) delete 2 entries (was separate, matches before & after, combine 3)
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Little effort has been put into making this routine efficient,
	as setting row heights and column widths is not a frequently
	done operation.  Given the number of possibilities enumerated
	above, optimization would be difficult, in any event.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowSetHeightInt	proc	far
	uses	bp, ds, si, di
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	LockRowArrayFar			;ds:si <- ptr to 1st entry

findRowLoop:
EC <	call	ECRowCheckOffset		;>
	cmp	ds:[si].RAE_row, cx		;correct row?
	jae	foundRow			;branch if correct row
	add	si, (size RowArrayEntry)	;ds:si <- ptr to next entry
	jmp	findRowLoop

foundRow:
	cmp	bx, -1				;skip baseline check?
	jne	afterBaselineCheck
	mov	bx, ds:[si].RAE_baseline	;bx <- current baseline
afterBaselineCheck:
	cmp	dx, -1				;skip height check?
	jne	afterHeightCheck
	mov	dx, ds:[si].RAE_height		;dx <- current row height
afterHeightCheck:
	;
	; Height or baseline changed?  If not, we're done.
	; (1) do nothing -- height hasn't changed
	;
	cmp	ds:[si].RAE_height, dx		;height changed?
	jne	changed
	cmp	ds:[si].RAE_baseline, bx	;baseline changed?
	je	noChange
	;
	; Check if at border of runs
	;
changed:
EC <	call	ECRowCheckOffset		;>
	mov	ax, ds:[si][-(size RowArrayEntry)].RAE_row
	inc	ax
	cmp	ax, cx				;after rows before?
	je	atEnd
	cmp	ds:[si].RAE_row, cx
	je	atTop
	;
	; The row is in the middle of a run. We need to insert two
	; new entries, one for the first half of the old run, and
	; one for the new run.
	; (7) insert 2 entries (new entry in middle of run)
	;
	mov	ax, (size RowArrayEntry)*2	;ax <- # bytes to insert
	call	RowArrayInsert
	mov	ax, ds:[si][+(size RowArrayEntry)*2].RAE_height
	mov	ds:[si].RAE_height, ax
	mov	ax, ds:[si][+(size RowArrayEntry)*2].RAE_baseline
	mov	ds:[si].RAE_baseline, ax
	cmp	dx, -1
	mov	ds:[si][+(size RowArrayEntry)].RAE_height,  dx
	mov	ds:[si][+(size RowArrayEntry)].RAE_baseline, bx
	mov	ds:[si][+(size RowArrayEntry)].RAE_row, cx
	dec	cx
	mov	ds:[si].RAE_row, cx
done:
	call	VMDirty
noChange:
EC <	call	ECCheckRowArray			;>
	call	VMUnlock			;done with array

	.leave
	FALL_THRU_POP	cx, bx, ax
	ret

	;
	; The row is at the end of the run before.
atEnd:
	;
	; See if a separate entry
	;
	cmp	ds:[si].RAE_row, cx		;separate entry?
	je	separateEntry
	;
	; See if the row heights and baselines match.  If so, we can
	; just extend the run before to include our row.
	;
	cmp	ds:[si][-(size RowArrayEntry)].RAE_height, dx
	jne	insertOne
	cmp	ds:[si][-(size RowArrayEntry)].RAE_baseline, bx
	jne	insertOne
	;
	; The row is at the end of the run before, and the
	; height and baseline are the same, so we can just
	; extend the run to include our row.
	; (3) insert 0 entries (matches run before)
	;
	mov	ds:[si][-(size RowArrayEntry)].RAE_row, cx
	jmp	done

	;
	; The row is at the top of the current run.
	; Because of the order of checks, we know it isn't
	; after the end of the run before, too.
atTop:
	;
	; See if the row heights and baselines match the next run.
	;  If so, we can just extend the run after to include our row.
	;
	cmp	ds:[si][+(size RowArrayEntry)].RAE_height, dx
	jne	insertOneAfter
	cmp	ds:[si][+(size RowArrayEntry)].RAE_baseline, bx
	jne	insertOneAfter
	;
	; The row is at the start of the next run, and the
	; height and baseline are the same, so we can just
	; extend the run to include our row.
	; This is actually done by shortening the current run.
	; (4) insert 0 entries (matches run after)
	;
	dec	cx
	mov	ds:[si].RAE_row, cx
	jmp	done

	; The row is at the end of the run before and the heights don't match.
	; (5) insert 1 entry (new entry at end of run)
	;
insertOne:
	mov	ax, (size RowArrayEntry)	;ax <- # bytes to insert
	call	RowArrayInsert			;insert me jesus
setCurrentRow:
	mov	ds:[si].RAE_row, cx
setCurrent:
	mov	ds:[si].RAE_height, dx
	mov	ds:[si].RAE_baseline, bx
	jmp	done

	;
	; The row is at the start of the run after and the heights don't match
	; (6) insert 1 entry (new entry at beginning of run)
	;
insertOneAfter:
	mov	ax, (size RowArrayEntry)	;ax <- # bytes to insert
	add	si, ax
	call	RowArrayInsert			;insert me jesus
	mov	ax, cx
	dec	ax
	mov	ds:[si][-(size RowArrayEntry)].RAE_row, ax
	jmp	setCurrentRow

	;
	; There is currently a separate entry for this row.
	; Either the new row matches, none, one, or both
	; of the runs before and after, in which case we
	; delete 0, 1 or 2 runs, respectively.
	; (2) insert 0 entries (separate entry already exists)
	; (8) delete 1 entry (was separate, matches run before)
	; (9) delete 1 entry (was separate, matches run after)
	; (10) delete 2 entries (was separate, matches before & after, combine)
	;
separateEntry:
	cmp	ds:[si][-(size RowArrayEntry)].RAE_height, dx
	jne	mismatchBefore
	cmp	ds:[si][-(size RowArrayEntry)].RAE_baseline, bx
	jne	mismatchBefore
	cmp	ds:[si][+(size RowArrayEntry)].RAE_height, dx
	jne	mergeBefore
	cmp	ds:[si][+(size RowArrayEntry)].RAE_baseline, bx
	jne	mergeBefore
	;
	; The new row matches before and after, so we can combine
	; three entries into one.
	; (10) delete 2 entries (was separate, matches before and after)
	;
	sub	si, (size RowArrayEntry)	;ds:si <- ptr to deletion
	mov	ax, (size RowArrayEntry)*2	;ax <- # bytes to delete
	call	RowArrayDelete
	jmp	done

	;
	; The new row mismatches before.  If it mismatches after, too,
	; then we can just set the new values in the existing entry.
	; (2) insert 0 entries (separate entry already)
	;
mismatchBefore:
	cmp	ds:[si][+(size RowArrayEntry)].RAE_height, dx
	jne	setCurrent
	cmp	ds:[si][+(size RowArrayEntry)].RAE_baseline, bx
	jne	setCurrent
	;
	; The new row mismatches before, but matches after.
	; Combine the old separate entry with the run after.
	; (9) delete 1 entry (was separate, matches run after)
	;
deleteCurrent:
	mov	ax, (size RowArrayEntry)	;ax <- # bytes to delete
	call	RowArrayDelete
	jmp	done

	;
	; The new row matches before, and mismatches after.
	; Combine the old separate entry with the run before
	; (8) delete 1 entry (was separate, matches run before)
	;
mergeBefore:
	mov	ds:[si][-(size RowArrayEntry)].RAE_row, cx
	jmp	deleteCurrent

RowSetHeightInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowArrayInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert space in the middle of the row/column array
CALLED BY:	RowSetHeightInt()

PASS:		ds:si - ptr to insertion
		ax - # of bytes to insert
		di - chunk handle of row or column array
RETURN:		ds:si - ptr to insertion
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowArrayInsert	proc	near
	uses	bx, cx
	.enter

	mov	cx, ax				;cx <- # bytes to insert
	mov	ax, di				;ax <- chunk handle
	mov	bx, ds:[di]			;bx <- offset of chunk
	sub	si, bx
	mov	bx, si				;bx <- offset of insertion
	call	LMemInsertAt
	mov	si, ds:[di]			;ds:si <- ptr to chunk
	add	si, bx				;ds:si <- ptr to insertion

	.leave
	ret
RowArrayInsert	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowArrayDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete space in the middle of a row/column array
CALLED BY:	RowSetHeightInt()

PASS:		ds:si - ptr to deletion
		ax - # of bytes to delete
		di - chunk handle of row or column array
RETURN:		ds:si - ptr to deletion
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowArrayDelete	proc	far
	uses	ax, bx, cx
	.enter

	mov	cx, ax				;cx <- # bytes to insert
	mov	ax, di				;ax <- chunk handle
	mov	bx, ds:[di]			;bx <- offset of chunk
	sub	si, bx
	mov	bx, si				;bx <- offset of insertion
	call	LMemDeleteAt
	mov	si, ds:[di]			;ds:si <- ptr to chunk
	add	si, bx				;ds:si <- ptr to insertion

	.leave
	ret
RowArrayDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECRowCheckOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the offset passed is within array bounds.
CALLED BY:	RowSetHeightInt(), RowGetHeightInt(), RowGetPositionInt()

PASS:		ds - seg addr of row/column array
		si - offset to check
		di - chunk handle of row/column array
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK

ECRowCheckOffset	proc	far
	uses	ax, cx, si
	.enter

	mov	ax, si				;ax <- offset to check
	mov	si, ds:[di]			;ds:si <- ptr to chunk
	cmp	ax, si				;offset large enough?
	ERROR_B	ROW_ARRAY_BAD_ROW
	ChunkSizePtr	ds, si, cx		;cx <- size of chunk
	add	si, cx				;si <- ptr to end of chunk
	cmp	ax, si				;offset small enough?
	ERROR_A	ROW_ARRAY_BAD_ROW

	.leave
	ret
ECRowCheckOffset	endp

endif

AttrCode	ends

DrawCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Pos32ToVisCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return row and column relative to cell given a visible position
CALLED BY:	SpreadsheetStartSelect()

PASS:		ds:si - ptr to Spreadsheet instance
		ss:bx - ptr to point (ptr to PointDWord)
RETURN:		(ax,cx) - row, column
DESTROYED:	ss:bx - point destroyed

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Pos32ToVisCellFar	proc	far
	call	Pos32ToVisCell
	ret
Pos32ToVisCellFar	endp

Pos32ToVisCell	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_offset.PD_x.low
	sub	ss:[bx].PD_x.low, ax
	mov	ax, ds:[si].SSI_offset.PD_x.high
	sbb	ss:[bx].PD_x.high, ax
	mov	ax, ds:[si].SSI_offset.PD_y.low
	sub	ss:[bx].PD_y.low, ax
	mov	ax, ds:[si].SSI_offset.PD_y.high
	sbb	ss:[bx].PD_y.high, ax

	mov	ax, ds:[si].SSI_visible.CR_start.CR_row
	mov	cx, ds:[si].SSI_visible.CR_start.CR_column

	FALL_THRU	Pos32ToCellRel
Pos32ToVisCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Pos32ToCellRel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return row and column relative to cell given a position
CALLED BY:	FindLowerRightCell(), RangeDrawGrid()

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx) - (r,c) to get position relative to
		ss:bx - ptr to point (ptr to PointDWord)
RETURN:		(ax,cx) - row, column
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Pos32ToCellRel	proc	near
	uses	dx, bp
	.enter

EC <	call	ECCheckInstancePtr		;>
	push	cx				;save column origin
	mov	cx, ax				;cx <- origin row
	lea	bp, ss:[bx].PD_y		;ss:bp <- ptr to coordinate
	call	Pos32ToRowRel
	pop	cx				;cx <- column origin
	push	ax				;save row #
	lea	bp, ss:[bx].PD_x		;ss:bp <- ptr to coordinate
	call	Pos32ToColRel
	mov	cx, ax				;cx <- column #
	pop	ax				;ax <- row #

	.leave
	ret
Pos32ToCellRel	endp

Pos32ToCellRelFar	proc	far
	call	Pos32ToCellRel
	ret
Pos32ToCellRelFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Pos32ToColRel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert 32-bit position to column (relative to specified origin)
CALLED BY:	Pos32ToCellRel()

PASS:		ds:si - ptr to Spreadsheet instance
		cx - column to get position relative to
		ss:bp - ptr to sdword
RETURN:		ax - column #
		cx - distance to column right edge (<=0)
		dx - distance to column left edge (>=0)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Pos32ToColRel	proc	near
	class	SpreadsheetClass
EC <	call	ECCheckInstancePtr		;>
	mov	ax, COLUMN_ARRAY_CHUNK		;ax <- chunk of array
	mov	dx, ds:[si].SSI_maxCol		;dx <- maximum column to check
	GOTO	PositionToCommon
Pos32ToColRel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Pos32ToRowRel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert 32-bit position to row (relative to specified origin)
CALLED BY:	Pos32ToCellRel()

PASS:		ds:si - ptr to Spreadsheet instance
		cx - row to get position relative to
		ss:bp - ptr to sdword
RETURN:		ax - row #
		cx - distance to row bottom edge (<=0)
		dx - distance to row top edge (>=0)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Pos32ToRowRel	proc	near
	class	SpreadsheetClass
EC <	call	ECCheckInstancePtr		;>
	mov	ax, ROW_ARRAY_CHUNK		;ax <- chunk of array
	mov	dx, ds:[si].SSI_maxRow		;dx <- maximum row to check
	FALL_THRU PositionToCommon
Pos32ToRowRel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionToCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find nearest row/column to relative position
CALLED BY:	PositionToColumn(), PositionToRow(), PositionToCell()

PASS:		ds:si - ptr to Spreadsheet instance
		ss:bp - ptr to position (x or y coordinate)
		ax - row/column array chunk handle
		cx - row/column to start at
		dx - maximum row/column to check
RETURN:		ax - row/column #
		cx - distance to row/column bottom/right edge (<=0)
		dx - distance to row/column top/left edge (>=0)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If the position specified is negative, then the first row/column
	is returned.  If the position specified is beyond the last
	row/column, then the last row/column is returned.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PositionToCommon	proc	near
	uses	bx, si, di, bp, ds
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	bx, ss:[bp].high		;bx <- high word of position
	tst	bx				;check for before first row
	js	beforeFirst			;branch if negative
	push	ss:[bp].low			;save low word
	call	LockRowArray			;ds:si <- ptr to RowArray
	pop	di				;bx:di <- position to find

startRowLoop:
	cmp	cx, ds:[si].RAE_row		;at start row yet?
	jbe	foundStart
	add	si, (size RowArrayEntry)	;ds:si <- ptr to next entry
	jmp	startRowLoop

foundStart:
	push	bp				;save VM handle
	clrdw	bpax				;bp:ax <- running total
rowLoop:
	cmp	cx, dx				;at end of row block?
	ja	foundPastRow			;branch if after last row
	cmp	bp, bx				;check high word
	ja	foundPastRow			;branch if far enough
	jb	rowOK
	cmp	ax, di				;check low word
	ja	foundPastRow			;branch if far enough

	; If they're equal, we proceed as if AX < DI, so that BP:AX
	; will correctly point to the right edge of the current column
	; (or the bottom of the current row).

rowOK:
	cmp	cx, ds:[si].RAE_row		;height still same?
	jbe	sameHeight			;branch if height same
	add	si, (size RowArrayEntry)	;skip to next block
sameHeight:
	add	ax, ds:[si].RAE_height
	adc	bp, 0				;bp:ax <- running total
	inc	cx				;cx <- new current row
	jmp	rowLoop

foundPastRow:
	dec	cx				;cx <- row/column
	;
	; cx - row/column #
	; bp:ax - total position
	; bx:di - position to match
	;
	sub	di, ax				;di <- distance to start
	mov_tr	ax, cx				;ax <- row/column
	mov	cx, di				;cx <- distance to bottom (<=0)
	mov	dx, cx
	add	dx, ds:[si].RAE_height		;dx <- distance to top (>= 0)
	;
	; Unlock the row array
	;
	pop	bp				;bp <- VM handle
	call	VMUnlock			;preserves flags
done:

	.leave
	ret

beforeFirst:
	mov	ax, cx				;ax <- first row/column
	clrdw	dxcx				;dxcx <- at edge
	jmp	done

	
PositionToCommon	endp

DrawCode	ends

AttrCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRowDiffs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get row heights and/or differences for a range
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		cx - start row
		dx - end row
RETURN:		ax - row height for selection
			ROW_HEIGHT_AUTOMATIC set if appropriate
		carry - set if multiple row heights
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRowDiffs	proc	near
	mov	ax, ROW_ARRAY_CHUNK		;ax <- chunk of array
	GOTO	RowDiffsCommon
GetRowDiffs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetColumnDiffs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get column widths and/or differences for a range
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		cx - start row
		dx - end row
RETURN:		ax - column width for selection
		carry - set if multiple column widths
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetColumnDiffs	proc	near
	mov	ax, COLUMN_ARRAY_CHUNK
	FALL_THRU	RowDiffsCommon
GetColumnDiffs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowDiffsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to get row or column differences for a range
CALLED BY:	GetRowDiffs(), GetColumnDiffs()

PASS:		ds:si - ptr to Spreadsheet instance
		ax - row/column array chunk handle
		cx - start row
		dx - end row
RETURN:		ax - row height / column width for selection
		carry - set if multiple row heights
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RowDiffsCommon	proc	near
	uses	bp, si, di, ds
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	LockRowArrayFar			;ds:si <- ptr to RowArray
	;
	; Find the entry for the first row
	;
startRowLoop:
EC <	call	ECRowCheckOffset		;>
	cmp	cx, ds:[si].RAE_row		;at start row yet?
	jbe	foundStart
	add	si, (size RowArrayEntry)	;ds:si <- ptr to next entry
	jmp	startRowLoop

	;
	; If the last row is in the same entry, then there are
	; no differences, otherwise there are.
	;
foundStart:
	clr	ax
	cmp	di, COLUMN_ARRAY_CHUNK		;doing columns?
	je	getHeight			;if columns, ignore baseline
	mov	ax, ds:[si].RAE_baseline
	andnf	ax, ROW_HEIGHT_AUTOMATIC	;ax <- automatic flag
getHeight:
	ornf	ax, ds:[si].RAE_height		;ax <- height of first row
	cmp	dx, ds:[si].RAE_row
	jbe	noDiffs
	stc					;carry <- diffs
	jmp	done

noDiffs:
	clc					;carry <- no diffs
done:
	call	VMUnlock			;preserves flags

	.leave
	ret
RowDiffsCommon	endp

AttrCode	ends

;
; NOTE: this code is placed in the same resource as
; MSG_SPREADSHEET_INSERT_SPACE since that is the only code that
; calls it.
;
SpreadsheetSortSpaceCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowInsertHeights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert specified number of new row heights

CALLED BY:	UTILITY
PASS:		ds:si - ptr to Spreadsheet instance
		cx - starting row
		dx - # of rows (<0 == delete)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RowInsertHeights		proc	near
	class	SpreadsheetClass

	push	ax, bx
	mov	ax, ROW_ARRAY_CHUNK
;;;
;;; Hack 5/17/95 -jw
;;;
;;; We need a consistent value, otherwise spreadsheets with different
;;; numbers of rows can't move between platforms.
;;;
;;;	mov	bx, ds:[si].SSI_maxRow		;bx <- maximum row to check
	mov	bx, ROW_ARRAY_TERMINATOR
	GOTO	RowInsertCommon, bx, ax
RowInsertHeights		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnInsertWidths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert specified number of new column heights

CALLED BY:	UTILITY
PASS:		ds:si - ptr to Spreadsheet instance
		cx - starting column
		dx - # of columns (<0 == delete)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColumnInsertWidths		proc	near
	class	SpreadsheetClass

	push	ax, bx
	mov	ax, COLUMN_ARRAY_CHUNK

;;;
;;; Hack 5/17/95 -jw
;;;
;;; We need a consistent value, otherwise spreadsheets with different
;;; numbers of columns can't move between platforms.
;;;
;;;	mov	bx, ds:[si].SSI_maxCol		;bx <- maximum column to check
	mov	bx, COLUMN_ARRAY_TERMINATOR
	FALL_THRU	RowInsertCommon, bx, ax
ColumnInsertWidths		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowInsertCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to insert # of row/column heights/widths

CALLED BY:	RowInsertHeights(), ColumnInsertWidths()
PASS:		ax - chunk of row/column array
		bx - max row/column to check
		ds:si - ptr to Spreadsheet instance
		cx - starting row
		dx - # of rows/columns (<0 == delete)
		on stack:
			saved ax
			saved bx
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Two different cases:
	
	Inserting:
	----------
	    (1) All rows after the starting row are shifted by the number
	        of rows being inserted.  (one exception to this is the
	        last row entry, because it never changes).
	    (2) All entries are normalized -- checked for duplicate entries, 
	        or adjacent entries that can be combined.
	    (3) The new rows are set to the default height.

	Deleting:
	---------
	    (1) All entries which are entirely in the deleted area are marked
	        as needing to be nuked
	    (2) All entries which span the end of the deleted area are set
	        so they start at the end of the deleted area
	    (3) All entries beyond the deleted area are adjusted
	    (4) All entries are normalized -- checked for duplicate entries, 
	        or adjacent entries that can be combined.
	    (5) The new rows are set to the default height.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RowInsertCommon		proc	near
	uses	ax, ds, si, di, bp
	.enter
;;;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
;;; Changes,  4/23/93 -jw
;;; Much of this did not change, but I did add some comments. The changed
;;; part really starts where the "===" appears below
	;
	; Lock the row array and find the first entry which begins after the
	; start of the affected area. That is to say, find the first entry
	; after the place we inserted or deleted.
	;
		call	LockRowArrayFar		; ds:si <- ptr to 1st entry
						; di <- chunk handle
						; bp <- VM block handle 
		
		push	si			; Save this, for merging later
		
	;
	; Find the entry for the first row after the affected area.
	;
		clr	bp			; bp <- previous entry
startRowLoop:
EC <		call	ECRowCheckOffset		>
		
		cmp	cx, ds:[si].RAE_row
		jbe	adjustRows		; Branch if at affected row
		
		mov	bp, ds:[si].RAE_row	; bp <- previous row
		add	si, (size RowArrayEntry); ds:si <- ptr to next entry
		jmp	startRowLoop

	;
	; Check to see if we have run into the very last entry, in which case
	; there's nothing to modify and we can quit out early.
	;
adjustRows:
		cmp	bx, ds:[si].RAE_row
		LONG je	noChange		; if at last row, no change

	;
	; For each affected entry, do something meaningful.
	;
adjustRowLoop:
EC <		call	ECRowCheckOffset		>
		mov	ax, ds:[si].RAE_row
	;
	; Check for having reached the last row (which means we can quit this)
	;
		cmp	bx, ax
		je	doneAdjust		; Branch if on last row
;;;=============================================================================
;;; This code handles deleting correctly. The cases for inserting haven't
;;; changed at all, they're still really simple.
	;
	; Adjust the row value for this entry and make a few special cases
	;	row + adjust > maxRow
	;		row <- maxRow, make this entry the last one
	;		This can only happen when inserting
	;
		tst	dx
		js	deletingSpace
		
		add	ax, dx			; ax <- adjusted row

		cmp	ax, bx
		jg	adjustTooBig		; Branch if adjusted to far
		
		jmp	storeAdjust
		
deletingSpace:
	;
	; 1) Range spans start of deleted area:
	;		+--- del ---+
	;	    +-------e
	;	Test:	(range.start < del.start) &&
	;		(range.end >= del.start)
	;	Set:	range.end = del.start - 1
	;
	; 2) Range is inside deleted area:
	;	    +--- del ---+
	;	      +-------e
	;	Test:	(range.start >= del.start) && 
	;		(range.start <= del.end) &&
	;		(range.end   >= del.start) &&
	;		(range.end   <= del.end)
	;	Set:	range.end = -1
	;
	; All other cases mean that the end of the range is beyond the end
	; of the deleted range, and therefore should simply be adjusted by
	; the amount of space that is being deleted.
	;
	; We already know that range.start is > del.start, since that's what
	; that first loop in this routine produced.
	;
		push	cx
		sub	cx, dx			; cx <- del.end
		dec	cx
		cmp	ax, cx			; Check r.end, d.end
		pop	cx
		jae	adjustForDelete
		
	;
	; The end of the range falls before the end of the deleted area
	; This indicates one of the two special cases above. The only
	; real check we need to do is to find if the start of the range
	; is before or after the start of the deleted area.
	;
		cmp	bp, cx			; Check r.start , d.start
		jae	rangeInsideDel

	;
	; The range spans the start of the deleted range
	;
		mov	ax, cx
		dec	ax
		jmp	storeAdjust
		
rangeInsideDel:
	;
	; The range is entirely inside the deleted area
	;
		mov	ax, -1
		jmp	storeAdjust
		
adjustForDelete:
		add	ax, dx			; Adjust for deletion
		
storeAdjust:
	;
	; Save the value to adjust.
	;
		mov	bp, ds:[si].RAE_row	; di <- previous row
		
;;;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	ds:[si].RAE_row, ax		;store adjusted row
	
	add	si, (size RowArrayEntry)	;ds:si <- next entry
	jmp	adjustRowLoop

adjustTooBig:
	mov	ax, bx				;ax <- maximum row
	jmp	storeAdjust

	;
	; Make sure there are no duplicate entries, and merge
	; any adjacent entries that can be merged.
	;
doneAdjust:
	pop	si				;ds:si <- ptr to 1st entry
mergeLoop:
	cmp	ds:[si].RAE_height, -1		;beyond last row?
	je	doneMerge
	;
	; Is this entry for the same row(s) as the next?
	;
	mov	ax, ds:[si].RAE_row		;ax <- row #
	cmp	ax, ds:[si][+(size RowArrayEntry)].RAE_row
	jb	checkAdjacent
	;
	; This entry is the same as the next...delete it.
	; We branch back to the top of the loop without
	; advancing the pointer because the next entry
	; has been shifted down, so the ptr is correct.
	;
	cmp	ax, cx				;beyond start row?
	ja	deleteMergeEntry
	mov	ax, (size RowArrayEntry)	;ax <- # of bytes to delete
	add	si, ax				;delete next entry for insert
	call	RowArrayDelete
	sub	si, ax				;ds:si <- back up to original
	jmp	mergeLoop

deleteMergeEntry:
	mov	ax, (size RowArrayEntry)	;ax <- # of bytes to deletee
	call	RowArrayDelete
	jmp	mergeLoop			;branch do next entry

	;
	; See if the row height and baseline for this entry are
	; the same as the next entry.
	;
checkAdjacent:
	mov	ax, ds:[si].RAE_height
	cmp	ax, ds:[si][+(size RowArrayEntry)].RAE_height
	jne	nextMergeEntry
	mov	ax, ds:[si].RAE_baseline
	cmp	ax, ds:[si][+(size RowArrayEntry)].RAE_baseline
	je	deleteMergeEntry
	;
	; Advance to the next entry
	;
nextMergeEntry:
	add	si, (size RowArrayEntry)	;ds:si <- ptr to next entry
	jmp	mergeLoop

noChange:
	pop	si				;clean up stack
	jmp	unlockArray

	;
	; Mark the block as dirty, and unlock it.
	;
doneMerge:
	mov	bp, ds:LMBH_handle
	call	VMDirty
unlockArray:
EC <	call	ECCheckRowArray			;>
	mov	bp, ds:LMBH_handle
	call	VMUnlock

	.leave
	FALL_THRU_POP	bx, ax
	ret
RowInsertCommon		endp

SpreadsheetSortSpaceCode	ends
