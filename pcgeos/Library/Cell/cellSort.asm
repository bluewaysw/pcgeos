COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cellSort.asm

AUTHOR:		John Wedgwood, Aug  9, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 8/ 9/91	Initial revision

DESCRIPTION:
	Sorting code.

	$Id: cellSort.asm,v 1.1 97/04/04 17:45:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeSort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort a range.

CALLED BY:	Global
PASS:		ds:si	= Pointer to CellFunctionParameters
		ss:bp	= Pointer to RangeSortParams
RETURN:		ax	= RangeSortError
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeSort	proc	far
	uses	bx, dx, di, ds, es
	.enter

	;
	; Save the CellFunctionParameters
	;
	mov	ss:[bp].RSP_cfp.segment, ds
	mov	ss:[bp].RSP_cfp.offset, si

	;
	; Allocate and initialize the block to sort.
	;
	call	AllocBlockToSort		; bx <- block handle
						; di <- number of entries
	jc	errorAlloc			; Branch if unable to allocate

	;
	; Now do the sorting and reordering of the data.
	;
	xchg	bx, bp				; ss:bx <- parameters
						; bp <- block handle
	call	SortBlock			; Sort the block
	
	xchg	bx, bp				; ss:bp <- parameters
						; bx <- block handle

	;
	; Pass the segment address of the sort-block in es.
	;
	segmov	es, ds, ax
	
	mov	ax, offset cs:ReorderRows	; Assume we're sorting rows
	test	ss:[bp].RSP_flags, mask RSF_SORT_ROWS
	jnz	gotReorderRoutine		; Branch if sorting rows
	mov	ax, offset cs:ReorderColumns	; We're doing columns
gotReorderRoutine:

	call	ax				; Shuffle the data
	
	;
	; Nuke the sort-block
	;
	call	MemFree				; See ya'

	mov	ax, RSE_NO_ERROR		; Signal: no error
quit:
	.leave
	ret

errorAlloc:
	;
	; We were unable to allocate the sort block. This is a sign that we're
	; getting low on memory. Don't choke, just return an error.
	;
	mov	ax, RSE_UNABLE_TO_ALLOC		; Error to return
	jmp	quit
RangeSort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocBlockToSort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block to sort in.

CALLED BY:	RangeSort
PASS:		ss:bp	= RangeSortParams
RETURN:		carry set on error (unable to alloc the block)
		bx	= Block handle of initialized sort block
		di	= Number of entries in the block
		ds	= Segment address of the block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocBlockToSort	proc	near
	uses	ax, cx, dx, si
	.enter
	;
	; We may be sorting columns or rows, the flags will tell...
	; dx <- start row
	; ax <- # of rows (-1)
	;
	mov	dx, ss:[bp].RSP_range.R_top
	mov	ax, ss:[bp].RSP_range.R_bottom
	sub	ax, dx
	
	test	ss:[bp].RSP_flags, mask RSF_SORT_ROWS
	jnz	gotCount			; Branch if we're sorting rows
	
	;
	; We're sorting columns
	;
	mov	dx, ss:[bp].RSP_range.R_left
	mov	ax, ss:[bp].RSP_range.R_right
	sub	ax, dx

gotCount:
	;
	; dx = Starting point
	; ax = # of entries - 1
	;
	inc	ax				; ax <- # of entries
	push	ax				; Save # of entries

	shl	ax, 1				; ax <- # of bytes to allocate
	clr	cl				; No HeapFlags
	mov	ch, mask HAF_LOCK		; Lock the block please
	call	MemAlloc			; bx <- block, ax <- address

	pop	cx				; cx <- # of entries
	jc	quit				; Branch if allocation error

	;
	; ax = Segment address of the sort block
	; bx = Block handle of the sort block
	; cx = # of entries
	; dx = First entry for the sort block
	;
	mov	ss:[bp].RSP_base, dx		; Save base of the array

	mov	di, cx				; di <- # of entries (to return)

	mov	ds, ax				; ds <- address of block
	clr	si				; ds:si <- ptr to the block
initLoop:
	mov	{word} ds:[si], dx		; Save current value
	add	si, size word			; Move to next entry
	inc	dx				; Move to next value
	loop	initLoop			; Loop to keep initializing

	clc					; Signal: no error
quit:
	.leave
	ret
AllocBlockToSort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SortBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort the block entries

CALLED BY:	RangeSort
PASS:		ss:bx	= RangeSortParams
		ds:0	= Pointer to the sort-block
		di	= Number of entries in the block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SortBlock	proc	near
	uses	ax, bx, cx, dx, si
params	local	QuickSortParameters
	.enter
	
	;
	; Signal that no entry is locked.
	;
	mov	ss:[bx].RSP_lockedEntry.segment, -1

	;
	; Fill in the parameter block.
	;
	mov	params.QSP_compareCallback.segment, SEGMENT_CS
	mov	params.QSP_compareCallback.offset, \
					offset cs:RangeSortCompareCallback
	
	mov	params.QSP_lockCallback.segment, SEGMENT_CS
	mov	params.QSP_lockCallback.offset, \
					offset cs:RangeSortLockCallback

	mov	params.QSP_unlockCallback.segment, SEGMENT_CS
	mov	params.QSP_unlockCallback.offset, \
					offset cs:RangeSortUnlockCallback

	mov	params.QSP_insertLimit, DEFAULT_INSERTION_SORT_LIMIT
	mov	params.QSP_medianLimit, DEFAULT_MEDIAN_LIMIT
	
	;
	; Set up the other paramters.
	;
	clr	si				; ds:si <- start of the array
	mov	ax, 2				; ax <- element size (word)
	mov	cx, di				; cx <- # of elements
	
	;
	; ds:si	= Start of sort-block
	; ax	= Size of each element
	; cx	= # of elements in the array
	; ss:bp	= QuickSortParameters
	; bx	= Frame ptr to SortRangeParams
	;
	call	ArrayQuickSort			; Sort the block
						; Nukes ax, cx, dx
	.leave
	ret
SortBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeSortCompareCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two cells.

CALLED BY:	ArrayQuickSort()
PASS:		ds:si	= Pointer to first cells row/column
		es:di	= Pointer to second cells row/column
		ss:bx	= RangeSortParams
RETURN:		Flags set for the comparison of the cells referred to by
			ds:si and es:di
DESTROYED:	ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeSortCompareCallback	proc	far
	uses	ds, es, bp
	.enter
	;
	; Assume sorting by rows. This means that we are comparing some
	; column in each row. This column is the active cells columns, so:
	;	cell #1: (R = ds:[si], C = activeColumn)
	;	cell #2: (R = es:[di], C = activeColumn)
	;
	mov	ax, {word} ds:[si]		; ax <- row for first cell
	mov	dx, {word} es:[di]		; dx <- row for second cell

	mov	cx, ss:[bx].RSP_active.P_x	; cx <- column for first cell
	mov	bp, cx				; bp <- column for second cell
	
	test	ss:[bx].RSP_flags, mask RSF_SORT_ROWS
	jnz	gotRowAndColumn
	
	;
	; We're sorting by columns. This means we are comparing some row
	; in each column. This row is the active cells row, so:
	;	cell #1: (R = activeRow, C = ds:[si])
	;	cell #2: (R = activeRow, C = es:[di])
	;
	mov	cx, ax				; cx <- column for first cell
	mov	bp, dx				; bp <- column for second cell

	mov	ax, ss:[bx].RSP_active.P_y	; ax <- row for first cell
	mov	dx, ax				; dx <- row for second cell

gotRowAndColumn:
	;
	; ax = Row for first cell
	; cx = Column for first cell
	; dx = Row for second cell
	; bp = Column for second cell
	;
	; Before we lock the cells, compare the rows/columns of the cells
	; to find which cell falls closest to the start of the spreadsheet.
	; This allows us to enforce a stable sorting of the data.
	;
	; We know that either the rows or columns will be the same. That means
	; That if the rows aren't different, the columns must be.
	;
	mov	si, ax				; Save row

	cmp	ax, dx				; Compare rows
	jne	gotComparison			; Branch if not same
	cmp	dx, bp				; Compare columns
gotComparison:
	lahf					; ah <- flags
	push	ax				; Save the result of the compare
	
	mov	ax, si				; Restore the row

	;
	; Lock the first cell and get the flags.
	;
	call	LockCellForCompareCheckCache	; es:di <- ptr to cell data
						; carry set if cell exists
	pushf					; Save "1st cell exists" flag
	push	es, di				; Save 1st ptr
	
	mov	ax, dx				; ax/cx <- row/col of 2nd cell
	mov	cx, bp

	;
	; Lock the second cell and get the flags.
	;
	call	LockCellForCompare		; es:di <- ptr to cell data
						; carry set if cell exists
	pop	ds, si				; Restore ptr to 1st cell
	
	;
	; ds:si = Pointer to first cell
	; es:di = Pointer to second cell
	; Carry set if second cell exists
	; On stack:
	;	Flags, Carry set if first cell exists
	;	word containing flags from comparing rows & columns
	;
	mov	ax, 0				; Doesn't destroy flags
	rcl	ax, 1				; Save "2nd exists" flag
	popf					; Restore "1st exists" flag
	rcl	ax, 1				; Save "1st exists" flag
	
	;
	; ds:si = Pointer to 1st cell data
	; es:di = Pointer to 2nd cell data
	; ax	= "cells exist" flags
	; ss:bx	= RangeSortParams
	; On stack:
	;	word containing flags from comparing rows & columns
	;
if FULL_EXECUTE_IN_PLACE
	push	bx, ax
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	mov	ax, ss:[bx].RSP_callback.offset
	mov	bx, ss:[bx].RSP_callback.segment
	call	ProcCallFixedOrMovable
	pop	bx, ax
else
	call	ss:[bx].RSP_callback		; Do the comparison
endif

	pushf					; Save result
	
	;
	; Release the second cell first.
	;
	push	ds				; Save ptr to 1st cell
	test	ax, mask RSCEF_SECOND_CELL_EXISTS
	call	UnlockCellAfterCompare		; Release the cell
	pop	es				; es <- ptr to 1st cell

	;
	; Release the first cell.
	;
	test	ax, mask RSCEF_FIRST_CELL_EXISTS
	call	UnlockCellAfterCompareCheckCache; Release the first cell

	popf					; Restore result

	;
	; Flags	= Flags set for the comparison of cell1 to cell2
	; ss:bx	= RangeSortParams
	; On stack:
	;	word containing flags from comparing rows & columns
	;
	; Check to see if we are doing an ascending/descending sort
	;

	lahf					; ah <- flags

	test	ss:[bx].RSP_flags, mask RSF_SORT_ASCENDING
	jnz	gotFlags
	
	;
	; We want to switch the meaning of the flags in ah.
	; To do this we leave the 'zero' flag alone, but we toggle the sign bit.
	;
	xor	ah, mask CPU_SIGN		; Toggle the sign bit

gotFlags:
	;
	; ah = flags to return.
	;
	sahf					; Set the new flags

	;
	; On stack:
	;	word containing flags from comparing rows & columns
	;
	pop	ax				; ax <- row/column compare flags

	jne	notEqual			; Branch if the data for the
						;    cells wasn't the same.
	;
	; We can't return that two entries are equal. This would make the
	; sorting algorithm unstable. To handle this, when the comparison
	; routine returns that the entries are the same, we compare the
	; rows (and columns) of the two cells so that the cell which falls
	; closest to the top/left of the spreadsheet sorts below the cell
	; that falls further away.
	;
	sahf					; Set flags based on the row
						;    and column comparison.
notEqual:
	.leave
	ret
RangeSortCompareCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockCellForCompareCheckCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a cell, using the cached cell it there is one.

CALLED BY:	RangeSortCompareCallback
PASS:		ss:bx	= RangeSortParams
		ax	= Row
		cx	= Column
RETURN:		es:di	= Pointer to cell data (if any)
		carry set if cell exists
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockCellForCompareCheckCache	proc	near
	uses	ax
	.enter
	cmp	ss:[bx].RSP_lockedEntry.segment, -1
	je	lockCell			; Branch if no cached cell
	
	;
	; There is a cached cell.
	;
	les	di, ss:[bx].RSP_lockedEntry
	mov	ah, ss:[bx].RSP_cachedFlags
	sahf					; Set carry from cached flags
	
	jmp	quit

lockCell:
	call	LockCellForCompare		; Lock the cell
quit:
	.leave
	ret
LockCellForCompareCheckCache	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockCellForCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a cell down for comparison

CALLED BY:	RangeSortCompareCallback, RangeSortLockCallback
PASS:		ss:bx	= RangeSortParams
		ax	= Row
		cx	= Column
RETURN:		es:di	= Pointer to cell data (if any)
		carry set if cell exists
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If there is no cell data then es is returned as a valid segment (cs)
	so that the caching code doesn't need to worry about putting some
	uncheckable value into the cached cell address.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockCellForCompare	proc	near
	uses	ds, si
	.enter
	lds	si, ss:[bx].RSP_cfp	; ds:si <- CellFunctionParameters
	call	CellLock		; *es:di <- cell
	jnc	noCell			; Branch if no cell
	mov	di, es:[di]		; es:di <- ptr to cell
quit:
	.leave
	ret

noCell:
	segmov	es, cs, di		; Put something valid in es
	jmp	quit
LockCellForCompare	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockCellAfterCompareCheckCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a cell, but if there is a cell in the cache, don't
		really unlock it...

CALLED BY:	RangeSortCompareCallback
PASS:		ss:bx	= RangeSortParams
		es	= Segment address of the cell
		zero flag set (z) if the cell doesn't exist
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockCellAfterCompareCheckCache	proc	near
	jz	UCACNC_quit			; Quit if no such cell
	
	cmp	ss:[bx].RSP_lockedEntry.segment, -1
	jne	UCACNC_quit			; Branch if cell is cached
	GOTO	UnlockCellAfterCompareNC
UnlockCellAfterCompareCheckCache	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockCellAfterCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release a cell after a comparison.

CALLED BY:	RangeSortCompareCallback
PASS:		es	= Segment address of the cell
		ss:bx	= RangeSortParams
		zero flag set (zero) if the cell existed
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockCellAfterCompare	proc	near
	jz	UCACNC_quit			; Branch if no such cell
	FALL_THRU	UnlockCellAfterCompareNC
UnlockCellAfterCompare	endp

UnlockCellAfterCompareNC	proc	near
	uses	ds, si
	.enter
	;
	; If UnlockCellAfterCompareNC() is called, we know the cell exists.
	; Therefore we skip the check for existance since the z flag has
	; been set for something else by this point.
	;
	lds	si, ss:[bx].RSP_cfp		; ds:si <- parameters
	call	CellUnlock			; Release the cell
	.leave
UCACNC_quit	label	near
	ret
UnlockCellAfterCompareNC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeSortLockCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock an element and mark the entry as locked.

CALLED BY:	ArrayQuickSort
PASS:		ds:si	= Pointer to the element to lock
		ss:bx	= RangeSortParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The idea is to lock the key-entry outside of the quicksort loop so
	that we don't need to lock it over and over again inside.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeSortLockCallback	proc	far
	uses	ax, cx, es, di
	.enter
EC <	cmp	ss:[bx].RSP_lockedEntry.segment, -1		>
EC <	ERROR_NE SOME_KEY_IS_ALREADY_LOCKED			>
	;
	; Assume ds:si points to a row.
	;
	mov	ax, ds:[si]			; ax <- entry to lock
	mov	cx, ss:[bx].RSP_active.P_x	; cx <- column for first cell
	
	test	ss:[bx].RSP_flags, mask RSF_SORT_ROWS
	jnz	gotRowAndColumn			; Branch if sorting by rows
	
	mov	cx, ax				; cx <- column
	mov	ax, ss:[bx].RSP_active.P_y	; ax <- ax for first cell
gotRowAndColumn:

	;
	; ax	= Row
	; cx	= Column
	; ss:bx	= RangeSortParams
	;
	call	LockCellForCompare		; es:di <- ptr to data
						; carry set if cell exists
	lahf					; ah <- flags

	mov	ss:[bx].RSP_cachedFlags, ah	; Save "exists" flag
	mov	ss:[bx].RSP_lockedEntry.segment, es
	mov	ss:[bx].RSP_lockedEntry.offset, di
	.leave
	ret
RangeSortLockCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeSortUnlockCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the currently locked entry.

CALLED BY:	ArrayQuickSort
PASS:		ss:bx	= RangeSortParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeSortUnlockCallback	proc	far
	uses	ax, si, ds, es
	.enter
EC <	cmp	ss:[bx].RSP_lockedEntry.segment, -1		>
EC <	ERROR_Z THERE_IS_NO_LOCKED_KEY				>

	;
	; Make sure the cell existed at all.
	;
	mov	ah, ss:[bx].RSP_cachedFlags
	sahf				; carry set if cell existed
	jnc	quit			; Branch if it didn't
	
	;
	; Release the locked entry.
	;
	lds	si, ss:[bx].RSP_cfp
	mov	es, ss:[bx].RSP_lockedEntry.segment
	call	CellUnlock

quit:
	;
	; Signal: nothing is locked.
	;
	mov	ss:[bx].RSP_lockedEntry.segment, -1
	.leave
	ret
RangeSortUnlockCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReorderColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reorder columns of data.

CALLED BY:	RangeSort
PASS:		es	= Segment address of the sort block
		di	= # of entries in the block
		ss:bp	= RangeSortParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	It's faster to sort the data in one row, then move to the next. As
	a result, the algorithm looks like this:
		Foreach row do
		    ReorderColumnsInRow()
		End

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReorderColumns	proc	near
	uses	ax
	.enter
	mov	ax, ss:[bp].RSP_range.R_top	; bx <- first row

rowLoop:
	cmp	ax, ss:[bp].RSP_range.R_bottom	; Check for done
	ja	quit				; Branch if done

	call	ReorderColumnsInRow		; Reorder the data
	jmp	rowLoop				; Loop to process it

quit:
	.leave
	ret
ReorderColumns	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReorderColumnsInRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reorder the columns in a given row

CALLED BY:	ReorderColumns
PASS:		ss:bp	= RangeSortParams
		es	= Segment address of the sort-block
		di	= Number of elements in the sort-block
		ax	= Current row
RETURN:		ax	= Next row
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Foreach row in range
	    Lock row
	    Reorder columns in locked row
	    Unlock row
	End

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReorderColumnsInRow	proc	near
	uses	bx, si, bp, ds
	.enter
	lds	si, ss:[bp].RSP_cfp		; ds:si <- CellFunctionParameters
	call	LockRowBlock			; ds <- seg address of row-block
	jnc	quitNextRowBlock		; Branch if no row-block
	
	call	GetRowPointer			; *ds:si <- row pointer
	jnc	quitUnlock			; Branch if no row
	
	mov	bx, si				; *ds:bx <- row pointer

	push	ax				; Save current row
	mov	ax, offset cs:SwapColumns	; ax <- routine to call
	call	ReorderRange			; Reorder the data
	pop	ax				; Restore current row

EC <	call	ECCheckRow					>

quitUnlock:
	mov	bp, ds:LMBH_handle		; bp <- block handle
	call	VMUnlock			; Release the block
	
	inc	ax				; Return next row
quit:
	.leave
	ret

quitNextRowBlock:
	;
	; Get to the next row-block by clearing bits to get to the base of
	; the current row-block and then adding the amount to get to the
	; start of the next row block.
	;
	ComputeNextRowBlockStart	ax	; ax <- offset to next row block
	jmp	quit
ReorderColumnsInRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap two colums in a row.

CALLED BY:	ReorderRange
PASS:		cx	= first column
		dx	= second column
		ss:bp	= RangeSortParams
		*ds:bx	= Pointer to the row (which must exist)
RETURN:		nothing (except the data swapped, of course)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There are a few cases to consider:
	    - Both entries exist
	    	Swap the dbase-item references
	    - One exists, the other doesn't
	        * Second would fall right after the first
		    Do nothing
		* Second would fall right at same position as first
		    Do nothing
		* Second would not fall right after the first
		    Get dbase item reference
		    Delete first entry
		    Insert second entry
		    Stuff dbase item reference
		    
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapColumns	proc	near
	uses	ax, cx, dx, di, si, bp
	.enter
	mov	si, bx			; *ds:si <- row pointer
	mov	di, si			; *ds:di <- row pointer

	call	FindCellInRow		; ds:si <- ptr to first element
	jnc	firstNotFound		; Branch if it doesn't exist
	
	;
	; The first entry exists. Find the second entry.
	;
	xchg	di, si			; *ds:si <- row ptr
					; ds:di <- first element pointer
	mov	cx, dx			; cl <- column of second entry
	call	FindCellInRow		; ds:si <- ptr to second element
	jnc	secondNotFound		; Branch if it doesn't exist
	
	;
	; Both entries exist. Swap the dbase items and dirty the block.
	; ds:di	= Pointer to first entry
	; ds:si	= Pointer to second entry
	;
	mov	ax, ds:[si].CAE_data.DBI_group
	xchg	ax, ds:[di].CAE_data.DBI_group
	mov	ds:[si].CAE_data.DBI_group, ax

	mov	ax, ds:[si].CAE_data.DBI_item
	xchg	ax, ds:[di].CAE_data.DBI_item
	mov	ds:[si].CAE_data.DBI_item, ax

quitDirty:
	mov	bp, ds:LMBH_handle	; bp <- block handle
	call	VMDirty			; Dirty the block

quit:
	.leave
	ret


firstNotFound:
	;
	; Deal with the first element not existing.
	; *ds:di = Row pointer
	; ds:si  = Position for first element
	; cx	 = First element column
	; dx	 = Second element column
	;
	xchg	di, si			; *ds:si <- row ptr
					; ds:di <- first element pointer
	xchg	cx, dx			; cl <- column of second entry
					; dl <- column of first entry
	call	FindCellInRow		; ds:si <- ptr to second element
	jnc	quit			; Branch if it doesn't exist
	
	;
	; The first doesn't exist but the second does.
	;
	; ds:di	= Pointer to where the first one should go
	; ds:si	= Pointer to where the second one is
	; cx	= Column of second entry
	; dx	= Column of first entry (which doesn't exist)
	;
	xchg	di, si			; di <- ptr to entry which exists
					; si <- ptr to entry which doesn't
	;;; Fall through to handle it

secondNotFound:
	;
	; Deal with the first existing but the second not existing.
	; ds:di	= Pointer to first entry
	; ds:si = Pointer to place where second entry would fall (but doesn't)
	; dx	= Column number for the second entry (which doesn't exist)
	;
	cmp	di, si			; Check for same position
	je	setColumnNumber		; Branch if same position
	
	;
	; Compute the difference between the two positions. If the second
	; one falls right after the first one then we only need to set the
	; column number of the first entry to that of the second
	;
	mov	ax, di			; ax <- position of first element
	add	ax, size ColumnArrayElement ; ax <- after first element
	cmp	ax, si			; Check for 2nd right after 1st
	je	setColumnNumber		; Branch if that's the case
	
	;
	; Well, it didn't work out easy... We need to shuffle data to open
	; a hole where the second part will go.
	; ds:di	= Pointer to the entry which exists (which we want to nuke)
	; ds:si	= Pointer to the place where the new entry would go in
	;	  the existing row.
	; dl	= Entry number
	;
	; First grab the data from the entry we're nuking.
	;
	mov	ax, ds:[di].CAE_data.DBI_group
	mov	cx, ds:[di].CAE_data.DBI_item

	call	ShiftRowData			; ds:si <- new destination

	;
	; Now save the data and the column number.
	;
	mov	ds:[si].CAE_data.DBI_group, ax
	mov	ds:[si].CAE_data.DBI_item, cx
	
	mov	di, si				; Set pointers the same
	;;; Fall thru

setColumnNumber:
	mov	ds:[di].CAE_column, dl
	jmp	quitDirty
SwapColumns	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShiftRowData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift data around in a row to open a hole for a new entry.

CALLED BY:	SwapColumns
PASS:		ds:di	= Position of the entry to remove
		ds:si	= Position at which we want to create an entry.
RETURN:		ds:si	= Position of the entry which has opened up.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	newDest = si

	if di > si then
	    /* Moving data forward in the buffer */
	    direction = backwards
	    nBytes = di - si
	    source = di - 1
	    dest = di - 1 + size ColumnArrayElement
	else
	    /* Moving data backwards in the buffer */
	    newDest = si - size ColumnArrayElement

	    direction = forwards
	    nbytes = si - di - size ColumnArrayElement
	    source = di + size ColumnArrayElement
	    dest = di
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShiftRowData	proc	near
	uses	bx, cx, di, es
	.enter
	mov	bx, si				; bx <- new destination

	segmov	es, ds, cx			; es/ds <- same segment

	cmp	di, si				; Check direction
	jbe	shiftDataDown			; Branch for shifting down
	;
	; Moving data up in the buffer.
	;
	std					; Move data backwards
	mov	cx, di				; cx <- # of bytes
	sub	cx, si

	dec	di
	mov	si, di				; si <- source

	add	di, size ColumnArrayElement	; di <- dest
	jmp	moveData			; Branch to move the data

shiftDataDown:
	mov	bx, si				; bx <- place entry opens up
	sub	bx, size ColumnArrayElement

	mov	cx, si				; cx <- # of bytes
	sub	cx, di
	sub	cx, size ColumnArrayElement
	
	mov	si, di				; si <- source
	add	si, size ColumnArrayElement
	
moveData:
	rep	movsb				; Shuffle the data
	cld					; Always want this set right.
	
	mov	si, bx				; Return new destination
	.leave
	ret
ShiftRowData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReorderRows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reorder data between rows.

CALLED BY:	RangeSort
PASS:		es	= Segment address of the sort block
		di	= # of entries in the block
		ss:bp	= RangeSortParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReorderRows	proc	near
	uses	ax
	.enter
	mov	ax, offset cs:SwapRowRanges	; ax <- callback routine
	call	ReorderRange			; Do the reordering
	.leave
	ret
ReorderRows	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapRowRanges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap two row ranges.

CALLED BY:	ReorderRange
PASS:		cx	= First row
		dx	= Second row
		ss:bp	= RangeSortParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	/*
	 * First we figure out the size of the ranges in each of the rows.
	 */
	size1 = SizeOfRowRange(firstRow, startColumn, endColumn)
	size2 = SizeOfRowRange(secondRow, startColumn, endColumn)
	
	/*
	 * Then we make sure there is space to exchange the data
	 */
	EnsureSpace(secondRow, endColumn, size1-size2)
	EnsureSpace(firstRow, endColumn, size2-size1)
	
	/*
	 * Now that the areas are the same size, we exchange the data
	 */
	ExchangeRowData(firstRow, secondRow, startColumn, MAX(size1, size2))
	
	/*
	 * Then we remove any unused space at the end of the areas
	 */
	RemoveSpace(firstRow, endColumn, size1-size2)
	RemoveSpace(secondRow, endColumn, size2-size1)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapRowRanges	proc	near
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter
	mov	di, cx				; di <- first row

	;
	; Compute the size of the first row range.
	;
	push	dx				; Save second row
	mov	ax, cx				; ax <- first row
	mov	cx, ss:[bp].RSP_range.R_left	; cx <- left edge
	mov	dx, ss:[bp].RSP_range.R_right	; dx <- right edge
	call	GetRowRangeSize			; bx <- first size
						; Z = 1 if entire row
	pop	ax				; Restore second row
	
	pushf					; Save "entire 2nd row" flag

	;
	; Compute the size of the second row range.
	; ax	= Second row
	; cx	= Left edge of range
	; dx	= Right edge of range
	; bx	= Size of first rows range
	;
	push	bx				; Save size in first row
	call	GetRowRangeSize			; bx <- first size
						; Z = 1 if entire row
	pop	dx				; Restore size in first row
	
	;
	; Set si to be a flag indicating if we're swapping entire rows.
	;
	mov	si, 0				; Don't nuke flags
	jnz	gotFlag				; Branch if not entire 1st row
	popf					; Get "entire 2nd row" flag
	pushf
	jnz	gotFlag				; Branch if not entire 2nd row
	mov	si, 1				; Signal swapping entire rows
gotFlag:
	popf					; Discard flags from stack
	
	;
	; Check to see if both the source and dest ranges are empty.
	; In this case we can just ignore skip all this silliness.
	;
	tstdw	bxdx				; Check for both being zero
	jz	quit				; Branch if nothing in either

	;
	; Make sure there is enough space in the two rows to allow us to
	; swap the data. Do the second row first because it's convenient.
	;
	; di	= First row
	; dx	= Size of first row range
	;
	; ax	= Second row
	; bx	= Size of second row range
	;
	; cx	= Left column of range
	;
	; si	= Flag indicating if we are swapping entire rows
	;
	push	si				; Save "entire rows" flag
	push	ax, dx, bx			; Save second row, size1, size2

	push	di				; Save 1st row
	sub	dx, bx				; dx <- size to ensure
	call	EnsureSpace			; si <- offset to start of area
						; di <- chunk handle
	mov	ss:[bp].RSP_destChunk, di	; Save chunk handle

	mov	di, si				; di <- offset of 2nd row
	pop	ax				; Restore 1st row
	;
	; NOTE: we save the handle from the segment returned from
	; EnsureSpace(), since saving the segment is a *bad* thing.
	; The second call to EnsureSpace() may allocate and resize
	; in the same block as the first, and hence change the segment.
	; By saving the handle instead, we can get the up-to-date
	; segment after instead.
	;
	push	ds:LMBH_handle			; save handle of 2nd block
	;
	; Make sure there is space in the first row.
	;
	; ax	= First row
	; dx	= (size1 - size2)
	; bx	= size2
	; di	= Offset into second row of data to swap
	;
	push	di				; Save offset into second row
	neg	dx				; dx <- size to ensure
	call	EnsureSpace			; si <- offset to start of area
	mov	ss:[bp].RSP_sourceChunk, di	; Save chunk handle
	pop	di				; Restore offset to second row
	pop	bx				; bx <- handle of 2nd block
	call	MemDerefES			; es <- seg addr of 2nd block

	pop	cx, dx, bx			; <- second row, size1, size2
	
	;
	; Swap the data in the two rows.
	;
	; ax	= First row
	; ds	= Segment address of first row
	; si	= Offset to position in first row
	; dx	= Amount of data to take from first row
	;
	; cx	= Second row
	; es	= Segment address of second row
	; di	= Offset to position in second row
	; bx	= Amount of data to take from second row
	;
	call	ExchangeRowData			; Swap the data
	
	;
	; Resize the rows back to their final size.
	;
	; ax	= First row
	; ds	= Segment address of first row
	; si	= Offset where we started swapping data in first row
	; bx	= Amount of data now present in the first row
	;
	; cx	= Second row
	; es	= Segment address of second row
	; di	= Offset where we started swapping data in second row
	; dx	= Amount of data now present in the second row
	;
	push	dx, di				; Save old size1, offset
	mov	di, ss:[bp].RSP_sourceChunk	; di <- chunk handle of row1
	sub	dx, bx				; dx <- amount of space to remove
	call	RemoveSpace			; Remove space from 1st row
	pop	dx, si				; Restore old size1, offset
	
	
	push	ds, es, ax, cx			; Save segment addresses, rows

	segmov	ds, es, ax			; ds <- segment address in row2
	mov	ax, cx				; ax <- second row

	sub	bx, dx				; bx <- Amount of data for 2nd
	mov	dx, bx				; Pass it in dx
	
	mov	di, ss:[bp].RSP_destChunk	; di <- chunk handle
	call	RemoveSpace			; Remove space from 2nd row
	
	pop	ds, es, ax, cx			; Restore segments, rows
	pop	si				; Restore "entire rows" flag
	
	;
	; Now we need to unlock the blocks. If a row is empty, we want to
	; nuke it entirely.
	;
	; ax	= First row
	; ds	= Segment address of first row
	; ss:bp.RSP_sourceChunk = Chunk handle of first row
	;
	; cx	= Second row
	; es	= Segment address of second row
	; ss:bp.RSP_destChunk = Chunk handle of second row
	;
	; si	= Non zero if we are swapping entire rows
	;
	call	SwapRowFlagsIfRequired

	call	UnlockOrDeleteRows
quit:
	.leave
	ret
SwapRowRanges	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapRowFlagsIfRequired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap row-flags if we swapped entire rows.

CALLED BY:	SwapRowRanges
PASS:		ds	= Segment address of first row
		ss:bp.RSP_sourceChunk = Chunk of first row
		es	= Segment address of second row
		ss:bp.RSP_destChunk = Chunk of second row
		si	= Non-zero if we should swap them
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapRowFlagsIfRequired	proc	near
	uses	ax, si, di
	.enter
EC <	call	ECCheckSegments			>
	;
	; Check to see if swapping is even required.
	;
	tst	si
	jz	quit				; Branch if no swap needed

	;
	; Swap the flags
	;
	mov	si, ss:[bp].RSP_sourceChunk	; *ds:si <- row1
	mov	si, ds:[si]			; ds:si <- row1

	mov	di, ss:[bp].RSP_destChunk	; *es:di <- row2
	mov	di, es:[di]			; es:di <- row2
	
	mov	ax, ds:[si].CAH_rowFlags	; ax <- row1.flags
	xchg	ax, es:[di].CAH_rowFlags	; ax <- row2.flags, save flags
	mov	ds:[si].CAH_rowFlags, ax	; save flags

quit:
	.leave
	ret
SwapRowFlagsIfRequired	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRowRangeSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of a range within a row

CALLED BY:	SwapRowRanges
PASS:		ax	= The row
		cx	= Left column
		dx	= Right column
		ss:bp	= RangeSortParams
RETURN:		bx	= Size of the range including the final column
		Flags set (equal/not-equal) to indicate whether or not
		the entire row is contained in this range.
			Z = 1 (jz)  if the entire row is in this range
			Z = 0 (jnz) otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRowRangeSize	proc	near
	uses	cx, di, si, ds, bp
	.enter
	lds	si, ss:[bp].RSP_cfp		; ds:si <- params
	
	mov	bp, size ColumnArrayHeader	; Assume chunk size in bp
	clr	bx				; Accumulate size in bx

	call	LockRowBlock			; ds <- row block
	jnc	quit				; Branch if no such row block

	call	GetRowPointer			; *ds:si <- row pointer
	jnc	quitUnlock			; Branch if no such row
	
	ChunkSizeHandle	ds, si, bp		; bp <- size of chunk
	
	;
	; The row exists. This means that FindCellInRow() will be returning
	; us valid pointers, even if the columns we request don't exist.
	;
	mov	di, si				; Save chunk handle in di
	call	FindCellInRow			; ds:si <- ptr to cell (cx)
	
	xchg	di, si				; *ds:si <- row pointer
						; ds:di <- ptr to cell (cx)
	
	mov	cx, dx				; cx <- right side
	call	FindNextCellInRow		; ds:si <- ptr past cell (dx)
	
	;
	; ds:si	= Pointer past last column
	; ds:di	= Pointer to first column
	;
	sub	si, di				; si <- size of range
	mov	bx, si				; bx <- size of range

quitUnlock:
	call	UnlockRowBlock			; Release the row-block
quit:
	;
	; bx	= Amount of data in the range
	; bp	= Size of the chunk
	;
	sub	bp, size ColumnArrayHeader	; bp <- size of data
	cmp	bx, bp				; Set the flags correctly
	.leave
	ret
GetRowRangeSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNextCellInRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer past the data for a given column

CALLED BY:	GetRowRangeSize
PASS:		*ds:si	= Row
		cl	= Column
RETURN:		ds:si	= Pointer past the element
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNextCellInRow	proc	near
	;
	; Get a pointer to the cell, if the cell is not found, then we'll
	; be pointing past the data anyway...
	;
	call	FindCellInRow
	jnc	gotPointer
	
	;
	; The entry was found, point past it.
	;
	add	si, size ColumnArrayElement
gotPointer:
	ret
FindNextCellInRow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that a certain amount of space is in a row.

CALLED BY:	SwapRowRanges
PASS:		ax	= Row
		cx	= Left column
		dx	= Amount of space to insert before the column
			  Negative value means insert nothing
		ss:bp	= RangeSortParams
RETURN:		ds	= Segment address of the row
		si	= Offset to the start of the area
		di	= Chunk handle of the row
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureSpace	proc	near
	uses	ax, bx, cx, bp
	.enter
	;
	; We need to insert space into the row.
	; dx = Amount of space
	; cx = Column position to insert at.
	;
	lds	si, ss:[bp].RSP_cfp		; ds:si <- parameters
	call	ForceLockRowBlock		; ds <- row block
	
	call	ForceGetRowPointer		; *ds:si <- row pointer

EC <	call	ECCheckRow				>

	mov	di, si				; Save chunk handle in di
	
	call	FindCellInRow			; ds:si <- place to insert
	
	sub	si, ds:[di]			; si <- offset into the row
	;
	; ds	= Segment address of the row
	; di	= Chunk handle of the row
	; si	= Offset at which to insert space
	; dx	= Amount of space to insert
	;
	tst	dx				; Check for nothing to insert
	js	quit				; If negative or zero that
	jz	quit				;    means insert no space
	
	mov	ax, di				; ax <- chunk handle
	mov	cx, dx				; cx <- # of bytes to insert
	mov	bx, si				; bx <- place to insert
	call	LMemInsertAt			; Make the space
	
	mov	bp, ds:LMBH_handle		; bp <- block handle
	call	VMDirty				; Dirty the block
quit:
	.leave
	ret
EnsureSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExchangeRowData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exchange data in two rows.

CALLED BY:	SwapRowRanges
PASS:		ds	= Segment address of first range
		si	= Offset into first range
		ss:bp.RSP_sourceChunk = Chunk handle of first range
		dx	= Amount of data to take from first range

		es	= Segment address of second range
		di	= Offset into second range
		ss:bp.RSP_destChunk = Chunk handle of second range
		bx	= Amount of data to take from second range
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The blocks associated with the row are dirtied (if any data is copied).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExchangeRowData	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter

EC <	call	ECCheckSegments			;>

	mov	cx, dx				; cx <- Max( bx, dx)
	cmp	cx, bx
	jae	gotSize
	mov	cx, bx

gotSize:
EC <	tst	cx					>
EC <	ERROR_Z	THERE_MUST_BE_SOME_DATA_TO_SWAP		>

	push	bx				; Save size2
	mov	bx, ss:[bp].RSP_sourceChunk
	add	si, ds:[bx]			; ds:si <- ptr to data1
	
	mov	bx, ss:[bp].RSP_destChunk
	add	di, es:[bx]			; es:di <- ptr to data2
	pop	bx				; Restore size2

	;
	; cx	= # of bytes to swap
	; ds:si	= Pointer to first part
	; es:di	= Pointer to second part
	;
	shr	cx, 1				; cx <- # of words
						; carry set if odd # of bytes
	jnc	swapWords
	;
	; Odd number of bytes. Swap the first byte, then fall through to
	; move words
	;
	lodsb					; al <- source, advance source
	xchg	al, {byte} es:[di]		; swap with dest
	mov	{byte} ds:[si-1], al		; save dest into source
	inc	di				; advance destination

swapWords:
	;
	; ds:si	= Pointer to first part
	; es:di	= Pointer to second part
	; cx	= # of words to move
	;
	jcxz	endLoop				; Branch if no data to move

swapLoop:
	lodsw					; ax <- source, advance source
	xchg	ax, {word} es:[di]		; swap with dest
	mov	{word} ds:[si-2], ax		; save dest into source

	add	di, size word			; advance destination
	loop	swapLoop			; loop to move next word

endLoop:

	;
	; We need to update the counts in the two blocks.
	; dx	= # of bytes taken from the first row
	; bx	= # of bytes taken from the second row
	;
	; This means that if:
	;	nElements = (dx-bx)/size ColumnArrayElement
	; then
	;	first.count  -= nElements
	;	second.count += nElements
	;
	call	ComputeNElements		; ax <- # of elements moved
	
	mov	si, ss:[bp].RSP_sourceChunk	; *ds:si <- first row
	mov	si, ds:[si]			; ds:si <- ptr to row
	add	ds:[si].CAH_numEntries, ax	; Update first row

	mov	di, ss:[bp].RSP_destChunk	; *es:di <- second row
	mov	di, es:[di]			; es:di <- ptr to row
	sub	es:[di].CAH_numEntries, ax	; Update second row

	;
	; Dirty the blocks.
	;
	mov	bp, ds:LMBH_handle		; bp <- handle of 1st row
	call	VMDirty				; Dirty the first row

	mov	bp, es:LMBH_handle		; bp <- handle of 2nd row
	call	VMDirty				; Dirty the second row

	.leave
	ret
ExchangeRowData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeNElements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the number of new elements added to a row

CALLED BY:	ExchangeRowData
PASS:		bx	= # of bytes moved into row
		dx	= # of bytes moved out of row
RETURN:		ax	= # of entries
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (bx > dx) then
	    /* More elements moved into the row than out of it */
	    nElements = (bx-dx) / size ColumnArrayElement
	else
	    nElements = -1 * (dx-bx) / size ColumnArrayElement

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeNElements	proc	near
	uses	bx, dx
	.enter
	clr	ax				; Assume no change

	cmp	bx, dx
	je	quit				; Branch if no change
	jb	moreMovedOut

	;
	; More moved in. Evaluate:
	;	(bytesIn - bytesOut) / size ColumnArrayElement
	;
	sub	bx, dx				; bx <- difference in bytes
	mov	ax, bx				; ax <- difference in bytes
	clr	dx				; dx.ax <- difference in bytes
	mov	bx, size ColumnArrayElement	; bx <- element size
	div	bx				; ax <- # of entries
	jmp	quit

moreMovedOut:
	;
	; More moved out. Evaluate:
	;	-1 * (bytesOut - bytesIn) / size ColumnArrayElement
	;
	sub	dx, bx				; dx <- difference in bytes
	mov	ax, dx				; ax <- difference in bytes
	clr	dx				; dx.ax <- difference in bytes
	mov	bx, size ColumnArrayElement	; bx <- element size
	div	bx				; ax <- # of entries moved out
	neg	ax

quit:
	.leave
	ret
ComputeNElements	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove space from a row

CALLED BY:	SwapRowRanges
PASS:		ax	= The row
		ds	= Segment address of the row
		si	= Offset into the row at which to delete
		di	= Chunk handle of the row
		dx	= Amount of space to remove
			  Negative means remove nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveSpace	proc	near
	uses	ax, bx, cx, bp
	.enter
	tst	dx				; Check for nothing to remove
	js	quit				; Negative or zero means
	jz	quit				;    delete nothing
	
	;
	; We do want to delete space.
	;
	mov	ax, di				; ax <- chunk handle
	mov	bx, si				; bx <- offset to delete pos
	mov	cx, dx				; cx <- # of bytes to delete
	call	LMemDeleteAt			; Nuke the bytes...
	
	mov	bp, ds:LMBH_handle		; bp <- handle of the row block
	call	VMDirty				; Dirty the row

EC <	xchg	si, di				; *ds:si <- ptr to row	>
EC <	call	ECCheckRow						>
EC <	xchg	si, di				; Restore di, si	>

quit:
	.leave
	ret
RemoveSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockOrDeleteRows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the rows, deleting them if they are empty.

CALLED BY:	SwapRowRanges
PASS:		ax	= Source row
		ds	= Segment address of source row
		ss:bp.RSP_sourceChunk = Chunk handle of first row

		cx	= Destination row
		es	= Segment address of dest row
		ss:bp.RSP_destChunk = Chunk handle of second row
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockOrDeleteRows	proc	near
	uses	ax, bx, dx, si, ds, es
	.enter
	;
	; Set up some parameters and call ZeroRow() for the first block
	; if it's emtpy.
	;
	mov	bx, ss:[bp].RSP_sourceChunk	; bx <- chunk handle of row
	
	mov	si, ds:[bx]			; ds:si <- row ptr
	
	tst	ds:[si].CAH_numEntries		; Check for no more entries
	jnz	unlockBlock1			; Branch if not empty

	push	ds				; Save row segment 
	mov	dx, ax				; dx <- row
	mov	ax, ds				; ax <- segment address
	lds	si, ss:[bp].RSP_cfp		; ds:si <- parameters
	call	ZeroRow				; Nuke the row
	pop	ds				; Restore row segment

	jc	noMoreRowBlock1			; Branch if row-block is gone

unlockBlock1:
	;
	; Unlock the second block
	; ds	= Segment address of second block
	; bx	= Chunk handle
	;
EC <	xchg	si, bx				; si <- chunk handle	>
EC <	call	ECCheckRow						>
EC <	xchg	si, bx							>

	call	UnlockRowBlock
noMoreRowBlock1:
	
	;
	; Now do the same for second block
	;
	mov	bx, ss:[bp].RSP_destChunk	; bx <- chunk handle of row
	
	mov	si, es:[bx]			; es:si <- row ptr
	tst	es:[si].CAH_numEntries		; Check for no more entries
	jnz	unlockBlock2			; Branch if not empty

	push	es				; Save row segment
	mov	dx, cx				; dx <- row
	mov	ax, es				; ax <- segment address
	lds	si, ss:[bp].RSP_cfp		; ds:si <- parameters
	call	ZeroRow				; Nuke the row
	pop	es				; Restore row segment

	jc	noMoreRowBlock2			; Branch if row-block is gone

unlockBlock2:
	;
	; Unlock the second block
	; es	= Segment address of second block
	; bx	= Chunk handle
	;
EC <	push	ds							>
EC <	segmov	ds, es							>
EC <	xchg	si, bx				; si <- chunk handle	>
EC <	call	ECCheckRow						>
EC <	xchg	si, bx							>
EC <	pop	ds							>

	push	bp				; Save frame ptr
	mov	bp, es:LMBH_handle		; bp <- block handle
	call	VMUnlock			; Release the block
	pop	bp				; Restore frame ptr

noMoreRowBlock2:
	.leave
	ret
UnlockOrDeleteRows	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReorderRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reorder the range based on the sort-block.

CALLED BY:	RangeSort
PASS:		es	= Segment address of the sort block.
		di	= # of entries in the list
		ss:bp	= RangeSortParams
		ax	= Callback routine to swap ranges
				Pass:	cx	= part1
					dx	= part2
					bx, ds whatever was passed in
				Return: nothing
				Destroyed: nothing
		bx, ds = Parameters for the callback
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReorderRange	proc	near
	uses	cx, dx, di, si
	.enter
	clr	si				; es:si <- first entry
	mov	cx, di				; cx <- # of entries

reorderLoop:
	;
	; ds:si	= Current entry
	; cx	= # of entries left to do
	;
	mov	di, es:[si]			; di <- entry to swap with
	sub	di, ss:[bp].RSP_base		; di <- offset into list

	shl	di, 1				; Index into table of words

findEntryLoop:
	;
	; es:si	= Current entry
	; es:di	= Entry to check out
	; cx	= # of entries left to do
	;
	; If di < si then the entry we want to swap with has moved. It has
	; moved to the entry stored at es:di.
	;
	cmp	di, si				; Check for already moved
	jae	gotEntry			; Branch if entry is OK

	mov	di, es:[di]			; Find out where it went
	sub	di, ss:[bp].RSP_base		; di <- offset into list

	shl	di, 1				; Index into table of words
	jmp	findEntryLoop			; Loop to check this spot out

gotEntry:
	;
	; es:si	= Current entry
	; es:di	= Entry to swap with
	; cx	= # of entries left to do
	; ax	= Callback routine to swap ranges
	;
	cmp	di, si				; Check for already in position
	je	nextEntry			; Branch if already in position

	push	cx				; Save # of entries to do
	mov	cx, es:[si]			; cx <- part 1
	mov	dx, es:[di]			; dx <- part 2

	call	ax				; Callback swaps the parts
	pop	cx				; Restore # of entries to do

nextEntry:
	add	si, size word			; Move to next entry
	loop	reorderLoop			; Loop to process it

	.leave
	ret
ReorderRange	endp

CellCode	ends
