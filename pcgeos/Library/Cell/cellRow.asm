COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cellRow.asm

AUTHOR:		John Wedgwood, December  5th, 1990

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/ 5/90	Initial revision
	John	 3/29/91	Optimizations required a complete rewrite

DESCRIPTION:
	Row manipulation routines.

	$Id: cellRow.asm,v 1.1 97/04/04 17:45:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockRowBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a row block if it exists

CALLED BY:	CheckCellDBItem
PASS:		ds:si	= Pointer to CellFunctionParameters
		ax	= Row
RETURN:		carry set if the row block exists
		ds	= Segment of the row block (if it exists)
			= Unchanged if block doesn't exist
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockRowBlock	proc	near
	uses	ax, bx, dx, bp
	.enter
	ComputeRowBlockOffset	ax
	mov	bx, ax		; bx <- offset into row-block array

	mov	ax, ds:[si].CFP_rowBlocks.RBL_blocks[bx]

	tst	ax		; Check for missing row-block (clears carry)
	jz	quit		; Quit if it doesn't exist
	;
	; The row-block does exist
	;
EC <	call	ECCheckCellParams		;>
	mov	bx, ds:[si].CFP_file		;bx <- VM file handle
	call	VMLock		; ax <- segment address of the VM block
	mov	ds, ax		; ds <- segment address of row-block
	mov	ds:LMBH_handle, bp

	stc			; Signal: Block does exist
quit:
	.leave
	ret
LockRowBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceLockRowBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the existence of a row block and lock it

CALLED BY:	ForceCellDBItem
PASS:		ds:si	= Pointer to the CellFunctionParameters
		ax	= Row
RETURN:		ds	= Segment address of the cell
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceLockRowBlock	proc	near
	call	LockRowBlock	; ds <- segment address of row block
	jc	quit		; Quit if it does exist
	;
	; Row block doesn't exist.
	;
	call	CreateRowBlock	; Force it to be created
	call	LockRowBlock	; ds <- segment address of row block
quit:
	ret
ForceLockRowBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRowPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to a row

CALLED BY:	CheckCellDBItem
PASS:		ds	= Segment address of the row block
		ax	= The row
RETURN:		carry set if the row exists
		*ds:si	= Pointer to the row (if it exists)
		si	= Chunk handle of the row if it doesn't
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRowPointer	proc	near
	uses	ax, bx, dx
	.enter
	ComputeRowChunkHandle	ax
	mov	si, ax		; si <- chunk handle of the row

	;
	; Now we check to see if the thing actually exists
	;
	ChunkSizeHandle	ds, si, ax

	tst	ax		; Check for non-existent (clears carry)
	jz	quit		; Quit if it doesn't really exist

EC <	call	ECCheckRow	; Make sure the row is OK		>

	stc			; Signal: it does exist
quit:
	.leave
	ret
GetRowPointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceGetRowPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the existence of a row and get a pointer to it

CALLED BY:	ForceCellDBItem
PASS:		ds	= Segment address of the row block
		ax	= Row
RETURN:		*ds:si	= Pointer to the row
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceGetRowPointer	proc	near

	call	GetRowPointer	; *ds:si <- ptr to the row
	jc	quit		; Quit if it does exist
	;
	; It doesn't exist. Allocate a new row.
	;
	call	CreateEmptyRow	; *ds:si <- ptr to empty row
quit:
	ret
ForceGetRowPointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCellInRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a cell in a row

CALLED BY:	CheckCellDBItem
PASS:		*ds:si	= Pointer to the row
		cl	= The column of the cell
RETURN:		carry set if the cell was found
		ds:si	= Pointer to the ColumnArrayElement
		if cell was not found then ds:si is the place to put it.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCellInRow	proc	near
	uses	ax, cx
	.enter
	mov	si, ds:[si]	; ds:si <- ptr to start of the array

				; ax <- # of entries in the array
	mov	ax, ds:[si].CAH_numEntries
				; ds:si <- ptr to 1st entry
	add	si, size ColumnArrayHeader

	xchg	cx, ax		; cx <- # of entries
				; al <- Column to find

	jcxz	notFound	; Branch if there are no entries

searchLoop:
	cmp	al, ds:[si].CAE_column
	je	found		; Branch if found
	jb	notFound	; Branch if past the right element
	add	si, size ColumnArrayElement
	loop	searchLoop	; Loop to check next entry
notFound:
	clc			; Signal: not found
quit:
	.leave
	ret

found:
	stc			; Signal: found
	jmp	quit		; Branch to quit
FindCellInRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceFindCellInRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the existence of a cell in a row

CALLED BY:	ForceCellDBItem
PASS:		*ds:si	= Pointer to the row
		cl	= Column of the cell
		bx	= VM file handle
RETURN:		ds:si	= Pointer to the ColumnArrayElement
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceFindCellInRow	proc	near
	uses	ax, di, bp
	.enter
	mov	ax, si		; Save chunk handle in ax

	call	FindCellInRow	; ds:si <- ptr to the cell data
	jc	quit		; Quit if found
	push	cx		; Save column number
	push	bx		; save file handle
	;
	; Cell wasn't found. We need to insert a new cell element
	;
	mov	bx, ax		; bx <- chunk handle too
	sub	si, ds:[bx]	; si <- offset to insert at
	mov	bx, si		; bx <- offset to insert at

	mov	cx, size ColumnArrayElement
	call	LMemInsertAt
	;
	; Now that we've created this fine element we need to up the count
	; of the number of cells in this row.
	;
	mov	si, ax		; si <- chunk handle
	mov	si, ds:[si]	; ds:si <- ptr to the row
	inc	ds:[si].CAH_numEntries	; One more cell in this row

	add	si, bx		; ds:si <- ptr to the cell data (to return)
	;
	; Now we need to allocate the cell dbase-item and store the group
	; and item into this structure.
	;
	mov	ax, DB_UNGROUPED
	pop	bx		; bx <- VM file handle
EC <	call	ECCheckBXFileHandle >
	mov	cx, DEFAULT_CELL_SIZE
	call	DBAlloc		; Allocate the new item
	
	pop	cx		; Restore column number

	mov	ds:[si].CAE_column, cl
	mov	ds:[si].CAE_data.DBI_group, ax
	mov	ds:[si].CAE_data.DBI_item,  di
	;
	; Need to dirty the row block.
	;
	mov	bp, ds:LMBH_handle
	call	VMDirty		; Dirty the row block
quit:
	.leave
	ret
ForceFindCellInRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowDeleteCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a cell from a row

CALLED BY:	CellReplace
PASS:		ds:si	= Pointer to CellFunctionParameters
		ax	= Row
		cl	= Column
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Remove the cell from the row.
	If the cell is the last one in the row free the row-chunk.
	If all the row chunks in this block are empty, free the row-block.
	
	The cell-data should be free'd before this routine is called.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RowDeleteCell	proc	near
	uses	ax, bx, cx, dx, di, es
	.enter
	mov	dx, ax			; dx <- row we are looking for

	push	ds, si			; Save ptr to parameters block

	call	LockRowBlock		; ds <- segment of row block
EC <	ERROR_NC ROW_BLOCK_MUST_EXIST					>

	call	GetRowPointer		; *ds:si <- ptr to the row
EC <	ERROR_NC ROW_MUST_EXIST						>

	mov	bx, si			; Save chunk handle of the row in bx
	call	FindCellInRow		; ds:si <- ptr to the cell
EC <	ERROR_NC CELL_MUST_EXIST					>

	;
	; ds:si = ptr to the cell in the row
	; bx = chunk handle of the row
	;
	mov	di, ds:[bx]		; ds:di <- ptr to the row
	dec	ds:[di].CAH_numEntries	; One less entry in the row
	jnz	removeEntry		; Branch to remove the entry
	
	;
	; On stack:
	;	ptr to parameter block.
	; bx	= Chunk handle of the row
	; dx	= Row we want to remove
	;
	mov	ax, ds			; ax <- segment address of row block
	pop	ds, si			; ds:si <- CFP pointer

	call	ZeroRow			; ReAlloc row to empty
	jc	quit			; Branch if row block is gone now
	
	push	ds, si			; Put these back on the stack again.
	mov	ds, ax			; ds <- segment address of row block
	jmp	dirtyRowAndQuit		; Branch if row block is still here

removeEntry:
	;
	; Remove the element from the row.
	; bx = Chunk handle of the row
	; si = Pointer to the entry to remove
	;
	mov	ax, bx			; ax <- chunk handle
	sub	si, ds:[bx]		; si <- offset to delete at
	mov	bx, si			; bx <- offset to delete at
	mov	cx, size ColumnArrayElement
	call	LMemDeleteAt		; Remove the element

	mov	bx, ax			; bx <- chunk handle again

dirtyRowAndQuit:
	;
	; Dirty the row block and unlock it.
	; ds = Segment address of the row-block
	; bx = Chunk handle of the row
	; On stack:
	;	Pointer to CFP
	;
	call	UnlockAndDirtyRowBlock
	pop	ds, si			; Restore ptr to parameter block

quit:
	.leave
	ret
RowDeleteCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ZeroRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Zero a row free'ing the row block if there are no more rows.

CALLED BY:	RowDeleteCell, InsertCompleteRows
PASS:		ds:si	= Pointer to CellFunctionParameters
		ax	= Segment address of row block
		bx	= Chunk handle of the row
		dx	= The row we're zeroing
RETURN:		carry set if row block is gone
		carry clear if it still exists
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ZeroRow	proc	near
	uses	ax, cx, di, es
	.enter
	push	ds, si			; Save CFP ptr
	mov	ds, ax			; ds <- segment address of row block

	;
	; The row has no more items in it. ReAlloc it so it is empty.
	;
	clr	cx			; Size of zero please
	mov	ax, bx			; ax <- chunk handle
	call	LMemReAlloc		; Allocate me to zero size
	
	;
	; Check to see if the row has any non-zero entries in it.
	;
	mov	ax, -1			; What all handles need to be
	segmov	es, ds, di		; es:di <- ptr to handles
	mov	di, ds:LMBH_offset
	mov	cx, N_ROWS_PER_ROW_BLOCK
	repe	scasw			; Find a non-empty handle
	jne	rowBlockStays		; Branch if we found one
	
	;
	; All the chunks in this block are empty. We should nuke the block.
	;
	pop	ds, si			; Restore ptr to parameter block
	mov	ax, dx			; ax <- the row
	call	FreeRowBlock		; Free me jesus
	
	stc				; Signal: row block is gone
quit:
	.leave
	ret

rowBlockStays:
	pop	ds, si			; Restore CFP pointer
	clc				; Signal: row block stays
	jmp	quit
ZeroRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateRowBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the creation of the row block

CALLED BY:	ForceLockRowBlock
PASS:		ds:si	= Pointer to CellFunctionParameters
		ax	= Row
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateRowBlock	proc	near
	uses	ax, bx, cx, dx, di, ds, es, bp
	.enter
	ComputeRowBlockOffset	ax
	mov	bp, ax		; bp <- offset into row-block array
	
	mov	ax, ROW_BLOCK_ID
EC <	call	ECCheckCellParams		;>
	mov	bx, ds:[si].CFP_file	;bx <- VM file
	mov	cx, size EmptyRowBlock
	call	VMAlloc		; ax <- vm block handle
	;
	; Save the vm block handle, mark the parameters as dirty.
	;
	mov	ds:[si].CFP_rowBlocks.RBL_blocks[bp], ax
	ornf	ds:[si].CFP_flags, mask CFPF_DIRTY
	;
	; Lock the new row-block and initialize it as an lmem heap
	;
	call	VMLock		; ax <- segment address of the block
				; bp <- memory handle
	;
	; Initialize the lmem heap block.
	;
	mov	ds, ax		; ds <- segment address of the new heap
				; dx <- size of the header
	mov	bx, bp		; bx <- memory block handle
	mov	dx, size LMemBlockHeader
	mov	cx, N_ROWS_PER_ROW_BLOCK
	mov	ax, LMEM_TYPE_GENERAL
	push	bp, si, di
	mov	si, INITIAL_ROW_BLOCK_FREE_SPACE ;si <- amount of free space
	clr	di				;di <- LocalMemoryFlags
	clr	bp				;bp <- end of space (0 = end)
	call	LMemInitHeap	; Initialize the heap
	pop	bp, si, di
	;
	; Mark the lmem heap as being part of a vm file so that relocation
	; will occur automatically on the handle at the base of the block.
	;
	ornf	ds:LMBH_flags, mask LMF_IS_VM
	;
	; Now initialize all the handles in the block to -1, which indicates
	; that they are allocated but empty.
	;
	segmov	es, ds, di	; es:di <- ptr to the handle table
	mov	di, ds:LMBH_offset
	mov	cx, N_ROWS_PER_ROW_BLOCK
	mov	ax, -1		; Value for an empty but allocated handle
	rep	stosw		; Allocate all those handles

	call	UnlockAndDirtyRowBlock

	.leave
	ret
CreateRowBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateEmptyRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an empty row

CALLED BY:	ForceGetRowPointer
PASS:		ds	= Segment address of lmem block to allocate in
		ax	= Row
RETURN:		*ds:si	= Pointer to the row
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateEmptyRow	proc	near
	uses	ax, cx, dx, bp, es, di
	.enter
	ComputeRowChunkHandle	ax
	mov	cx, size ColumnArrayHeader
	call	LMemReAlloc	; Allocate a new entry

	mov	si, ax		; *ds:si <- ptr to the row
	segmov	es, ds, di	; es <- segment of the row
	mov	di, ds:[si]	; es:di <- ptr to the row
	
	clr	ax		; Zero everything out
	mov	cx, (size ColumnArrayHeader)/(size word)
	rep	stosw		; Zero it all...
CheckHack <((size ColumnArrayHeader) and 1) eq 0>
	
	mov	bp, ds:LMBH_handle
	call	VMDirty		; Dirty the row block
	.leave
	ret
CreateEmptyRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeRowBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a row block, it isn't needed any more

CALLED BY:	RowDeleteCell
PASS:		ds:si	= Pointer to CellFunctionParameters
		es	= Segment address of locked row block
		ax	= Row
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeRowBlock	proc	near
	uses	ax, bx, dx, bp
	.enter
	mov	bp, es:LMBH_handle
	call	VMUnlock		; Unlock the block first

	ComputeRowBlockOffset	ax
	mov	bp, ax			; bp <- offset into row-block array
	
	mov	ax, ds:[si].CFP_rowBlocks.RBL_blocks[bp]
EC <	call	ECCheckCellParams	;>
	mov	bx, ds:[si].CFP_file	; bx <- VM file
	call	VMFree			; Free the vm block
	;
	; Zero the entry in the row-block array and mark it as dirty.
	;
	mov	ds:[si].CFP_rowBlocks.RBL_blocks[bp], 0
	or	ds:[si].CFP_flags, mask CFPF_DIRTY
	.leave
	ret
FreeRowBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockAndDirtyRowBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock and dirty a row block

CALLED BY:	UTILITY
PASS:		ds - seg addr of row block
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockAndDirtyRowBlock		proc	near
	uses	bp
	.enter

	pushf
	mov	bp, ds:LMBH_handle		;bp <- handle of row block
	call	VMDirty
	call	VMUnlock
	popf

	.leave
	ret
UnlockAndDirtyRowBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockRowBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a row block

CALLED BY:	UTILITY
PASS:		ds - seg addr of a row block
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockRowBlock		proc	near
	uses	bp
	.enter

	mov	bp, ds:LMBH_handle
	call	VMUnlock

	.leave
	ret
UnlockRowBlock		endp

CellCode	ends
