COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cellRange.asm

AUTHOR:		John Wedgwood, Jan  8, 1991

ROUTINES:
	Name			Description
	----			-----------
	RangeExists		Check for cells in a given range.
	RangeFree		Free all cells in a given range.
	RangeEnum		Process a range of cells

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	1/ 8/91		Initial revision
	John	 3/29/91	Optimizations required major rewrites...

DESCRIPTION:
	Range related functions

	$Id: cellRange.asm,v 1.1 97/04/04 17:44:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of cells in a range

CALLED BY:	Global
PASS:		ds:si	= Pointer to CellFunctionParameters
		ax,cl	= Row/Column of first cell in range
		dx,ch	= Row/Column of last cell in range
RETURN:		carry set if one or more cells in the range contain data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeExists	proc	far
	uses	ax, bx, dx, bp
	.enter
	clr	bp			; Assume no cells hold data
	
	sub	sp, size RangeEnumParams
	mov	bx, sp			; ss:bx <- range enum parameters
	
	;
	; Initialize the stack frame.
	;
	mov	ss:[bx].REP_bounds.R_top, ax
	mov	ss:[bx].REP_bounds.R_bottom, dx
	
	clr	ax
	mov	al, cl
	mov	ss:[bx].REP_bounds.R_left, ax
	
	mov	al, ch
	mov	ss:[bx].REP_bounds.R_right, ax
	
	mov	ss:[bx].REP_callback.segment, cs
	mov	ss:[bx].REP_callback.offset, offset cs:ExistsCallback
	
	clr	dl			; Only cells that exist please
	call	RangeEnum
	
	add	sp, size RangeEnumParams
	;
	; If bp is non-zero then we do have at least one cell.
	;
	tst	bp			; Check for cells
	jz	quit			; Branch if no cells (carry clear)
	stc				; Signal: There is data
quit:
	.leave
	ret
RangeExists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExistsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a cell existing

CALLED BY:	RangeEnum
PASS:		Only called if a cell was found
RETURN:		carry set always
		bp = -1 always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExistsCallback	proc	far
	mov	bp, -1			; Signal: found data
	stc				; Abort callback
	ret
ExistsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback routine for each cell in a range
CALLED BY:	RangeDraw()

PASS:		ds:si	= Pointer to CellFunctionParameters
		ss:bp	= ptr to callback local variables
		ss:bx	= ptr to RangeEnumParams
		    REP_callback
		    REP_bounds
		(The REP_callback routine *must* vfptr for XIP.)
		dl	= RangeEnumFlags
RETURN:		carry set if callback aborted
DESTROYED:	none

CALLBACK:
	PASS:		ds:si	= Pointer to CellFunctionParameters
			(ax,cx)	= current cell (r,c)
			ss:bp	= ptr to callback local variables
			ss:bx	= ptr to stack frame passed as RangeEnumParams
			if REF_COLUMN_FLAGS:
				REP_columnFlagsArray - ptr to ColumnArrayHeader
				REP_columnFlags - ColumnFlags for cell
			*es:di	= ptr to cell data if any
			dl	= RangeEnumFlags
			carry set if cell has data
	RETURN:		carry set to abort enumeration
			es	= seg addr of cell (updated)
			dl	= RangeEnumFlags modified to (possibly)
				include: 
					REF_CELL_ALLOCATED
					REF_CELL_FREED
					REF_OTHER_ALLOC_OR_FREE
					REF_COLUMN_FLAGS_MODIFIED
	DESTROYED:	nothing

	If the caller passed REF_ALL_CELLS and REF_NO_LOCK then the callback
	will not know if the cell exists or not. Basically these parameters
	are actually undefined:
			*es:di	= ptr to cell data if any
			carry set if cell has data

	1) If you allocate the cell for which the callback is made:
		Do not unlock the cell. RangeEnum will do that.
		Return REF_CELL_ALLOCATED
	2) If you allocate a different cell than the one for which the
	   callback is made:
		You should unlock the cell.
		Return REF_OTHER_ALLOC_OR_FREE
	3) If you free the cell for which the callback is made:
		You need to unlock the cell before doing the free.
		If you don't do this then the block containing the
		free'd cell can't be removed if the cell is the
		last one in that block.
		Return REF_CELL_FREED
	4) If you free a different cell than the one for which the
	   callback is made:
		You need to unlock the cell for the same reasons outlined
		in (3).
		Return REF_OTHER_ALLOC_OR_FREE
	5) If you change the ColumnFlags:
		Be sure you change the data pointed at by REP_columnFlagsArray
		Return REF_COLUMN_FLAGS_MODIFIED

PSEUDO CODE/STRATEGY:
	This code has two different parts:
	    Callback for all cells:
		- Loop, calling CellLock()
	    Callback for existing cells only:
		- Horribly complex case

This horribly complex case stems from the fact that the callback routine
can allocate or free cells. The problem then is one of making sure that
we handle these cases.

What we'll need is enough state information so that if the user allocates
a cell, we'll be able to resynch ourselves in the current row. This is
necessary because the user may have inserted a cell in the current row
which would throw off our pointers.

If the user has freed a cell we have a similar problem. This actually breaks
down into a few cases:
	- At the least we may need to resynch ourselves as we did
	  when a cell was added.
	- The row may no longer exist, in which case we just want to
	  abort processing the row.
	- The row-block may no longer exist, in which case we want
	  to abort processing the row-block.

So, while we are processing along, here's what we watch out for:
	- Callback free'd current cell
	- Callback allocated a cell other than the current one

In either of the cases we need to resynch and, in the case of free'ing,
possibly abort processing the current row or row-block.

The REF_CELL_ALLOCATED bit is only useful when the REF_ALL_CELLS bit is
passed in since the callback will never get the chance to allocate the
current cell when we are processing only cells that already exist.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/12/91		Initial version
	jcw	 4/22/91	Massive optimization rewrite
	jcw	 8/15/91	Rewrote the whole thing again...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeEnum	proc	far
	uses	ax
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx, si, ax					>
EC <		mov	si, ss:[bx].REP_callback.offset			>
EC <		mov	bx, ss:[bx].REP_callback.segment		>
EC <		mov	ax, cs						>
EC <		cmp	bx, ax						>
EC <		je	xipSafe						>
EC <		call	ECAssertValidFarPointerXIP			>
EC < xipSafe:								>
EC <		pop	bx, si, ax					>
endif

	movdw	ss:[bx].REP_cfp, dssi		;save CFP pointer
	;
	; Figure out which routine to call...
	;
	mov	ax, offset cs:RangeEnumRowFlags
	test	dl, mask REF_MATCH_ROW_FLAGS
	jnz	gotRoutine

	mov	ax, offset cs:RangeEnumAllCells	; ax <- routine to call
	test	dl, mask REF_ALL_CELLS		; Check for doing all cells
	jnz	gotRoutine			; Branch if doing all cells

	mov	ax, offset cs:RangeEnumDataCells; ax <- routine to call
gotRoutine:
	call	ax

	.leave
	ret
RangeEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeEnumAllCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback for all cells in the spreadsheet.

CALLED BY:	RangeEnum
PASS:		ds:si	= CellFunctionParameters
		ss:bx	= RangeEnumParams
		ss:bp	= Parameters for the callback
		dl	= RangeEnumFlags
RETURN:		carry set if the callback aborted
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeEnumAllCells	proc	near
	uses	cx, di, es
	.enter
	mov	ax, ss:[bx].REP_bounds.R_top	; ax <- current row
rowLoop:
	cmp	ax, ss:[bx].REP_bounds.R_bottom	; Check for past the bottom
	ja	quitNoAbort			; Branch if done

	mov	cx, ss:[bx].REP_bounds.R_left	; cx <- current column
columnLoop:
	cmp	cx, ss:[bx].REP_bounds.R_right	; Check for past right edge
	ja	nextRow				; Branch if done

	;
	; ds:si	= CellFunctionParameters
	; ax	= Row
	; cx	= Column
	;
EC <	call	ECCheckEnumParams		;>
	call	RangeEnumLockCell		; *es:di <- cell data
						; carry set if cell exists
	pushf					; Save 'cell exists' flag

EC <	call	ECCheckEnumParams		;>
if FULL_EXECUTE_IN_PLACE
	push	bx, ax
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	mov	ax, ss:[bx].REP_callback.offset
	mov	bx, ss:[bx].REP_callback.segment
	call	ProcCallFixedOrMovable
	pop	bx, ax
else
	call	ss:[bx].REP_callback		; Call the callback routine
endif
EC <	call	ECCheckEnumParams		;>
	jc	abort				; Branch if callback aborted

	popf					; Restore 'cell exists' flag
	call	RangeEnumUnlockCell		; Release the cell
EC <	call	ECCheckEnumParams		;>
	inc	cx				; Move to next column
	jmp	columnLoop			; Loop to process it

nextRow:
	inc	ax				; Move to next row
	jmp	rowLoop				; Loop to process it

quitNoAbort:
	clc					; Signal: Didn't abort

quit:
	.leave
	ret

abort:
	;
	; The callback aborted.
	; On stack:
	;	flags, carry set if cell existed.
	;
	popf					; Restore 'cell exists' flag
	call	RangeEnumUnlockCell		; Release the cell
	stc					; Signal: Aborted
	jmp	quit

RangeEnumAllCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeEnumLockCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a cell down (if requested).

CALLED BY:	RangeEnumAllCells
PASS:		ds:si	= CellFunctionParameters
		ax	= Row
		cx	= Column
		dl	= RangeEnumFlags
		ss:bx	= RangeEnumParams
RETURN:		*es:di	= Pointer to the cell data (if any and if the callback
			  isn't locking the cell itself).
		carry set if the cell exists and the callback isn't locking the
			cell itself.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeEnumLockCell	proc	near
	uses	ax, bx
EC <	call	ECCheckEnumParams		;>
	.enter

	test	dl, mask REF_ROW_FLAGS
	jnz	getFlags
afterFlags:
	call	CheckCellDBItem			; ax <- group
						; di <- item
						; carry set if cell exists
	jnc	quit				; Branch if cell doesn't exist

	test	dl, mask REF_NO_LOCK		; Check for callback locking
	jnz	quitHasCell			; Branch if so

EC <	call	ECCheckCellParams		;>
	mov	bx, ds:[si].CFP_file		; bx <- VM file handle
	call	DBLock				; *es:di <- ptr to the data

quitHasCell:
	stc					; Signal: cell exists

quit:
	.leave
EC <	call	ECCheckEnumParams		;>
	ret

	;
	; The caller wants the row flags -- get them
	; We might be able to get this in a more efficient
	; fashion, but this is a convient place to do it...
	;
getFlags:
	push	dx
	mov	ss:[bx].REP_flagRow, ax		;save row for unlock
	call	RowGetFlags
	mov	ss:[bx].REP_rowFlags, dx
	pop	dx
	jmp	afterFlags
RangeEnumLockCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeEnumUnlockCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a cell

CALLED BY:	RangeEnumAllCells
PASS:		es	= Segment address of the cell
		carry set if the cell existed
		dl	= RangeEnumFlags
		ss:bx	= RangeEnumParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeEnumUnlockCell	proc	near
	uses	ax
	.enter
	lahf				; ah <- 'cell exists' flag (carry)

	test	dl, mask REF_ROW_FLAGS_MODIFIED
	jnz	setFlags
afterFlags:
	;
	; If we didn't lock the cell or the cell was freed,
	; we skip the unlock
	;
	test	dl, mask REF_NO_LOCK or \
			mask REF_CELL_FREED
	jnz	quit

	test	dl, mask REF_CELL_ALLOCATED
	jnz	unlock			; Branch if cell was allocated

	;
	; The cell wasn't allocated or freed and we should unlock it if it
	; existed before.
	;
	sahf				; Restore 'cell exists' flag (carry)
	jnc	quit			; Branch if cell never existed

unlock:
	call	DBUnlock		; Release the cell

quit:
	.leave
	ret

	;
	; The row flags were changed -- dirty them
	;
setFlags:
EC <	test	dl, mask REF_ROW_FLAGS		;>
EC <	ERROR_Z	MUST_PASS_REF_ROW_FLAGS_TO_RETURN_REF_ROW_FLAGS_MODIFIED >
	push	ax, dx
	mov	dx, ss:[bx].REP_rowFlags	;dx <- new row flags
	mov	ax, ss:[bx].REP_flagRow		;ax <- row #
	lds	si, ss:[bx].REP_cfp		;ds:si <- ptr to CFP
	call	RowSetFlags
	pop	ax, dx
	jmp	afterFlags
RangeEnumUnlockCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeEnumDataCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback for all cells that contain data.

CALLED BY:	RangeEnum
PASS:		ds:si	= CellFunctionParameters
		ss:bx	= RangeEnumParams
		ss:bp	= Parameters for the callback
		dl	= RangeEnumFlags
RETURN:		carry set if the callback aborted
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeEnumDataCells	proc	near
	uses	cx, ds
	.enter
	;
	; Fill in the parameter block.
	;
	movdw	ss:[bx].REP_cfp, dssi	; Save the CellFunctionParameters
	;
	; Now start processing the rows.
	;
	clr	cx				; cx <- current row block
						; 0 == No current row block

	mov	ax, ss:[bx].REP_bounds.R_top	; ax <- starting row
	jmp	lockRowBlock			; Branch to get the row-block

rowLoop:
	;
	; Process the next row-block
	;
	; ax	= Current row
	; cx	= Segment address of current row-block, 0 for none
	; ds	= Segment address of current row-block if one exists
	;
	cmp	ax, ss:[bx].REP_bounds.R_bottom	; Check for done
	ja	endLoopNoAbort			; Branch if no more rows
	
	;
	; Check for being finished with the current row-block. The easiest
	; way to do this is to check the lower bits of the row to see if they
	; are all clear. That is an indication that we need to move to the
	; start of the next row-block.
	;
	test	ax, ROW_TO_ROW_CHUNK_MASK	; Check for all bits clear
	jnz	gotRowBlock			; Branch if still in same block

	;
	; Release the old row block.
	; cx	= Current row-block segment address, 0 for none
	; ds	= Segment address of row-block (if it exists)
	;
	jcxz	lockRowBlock			; Branch if no row block

	call	UnlockRowBlock

lockRowBlock:
	;
	; Lock the next row block
	; ax	= Row block
	;
	lds	si, ss:[bx].REP_cfp		; ds:si <- CellFunctionParameters
	call	LockRowBlock			; ds <- row-block
						; carry set if row block exists
	jnc	noRowBlock			; Branch if it doesn't exist
	
	mov	cx, ds				; cx <- segment address

gotRowBlock:
	;
	; cx	= Segment address of the current row-block
	; ds	= Segment address of the current row-block
	; ax	= Starting row
	;
	call	RangeEnumRowBlock		; Process this row-block
	jc	endLoop				; Branch if callback aborted
	jz	nextRowBlock			; Branch if row-block exists

noRowBlock:
	;
	; The row block no longer exists, we don't want to unlock it when we
	; move on, so we mark it as gone by zeroing cx.
	;
	clr	cx				; Signal: no more row-block
	
nextRowBlock:
	;
	; Move to the next row-block starting row
	;
	ComputeNextRowBlockStart	ax	; ax <- start of next row block
	jmp	rowLoop

endLoopNoAbort:
	;
	; The callback didn't abort.
	;
	clc					; Signal: didn't abort

endLoop:
	;
	; We have finished the last row. Unlock the row-block.
	; cx	= Segment address of the row-block, 0 for none
	; ds	= Segment address of row-block (if it exists)
	; carry set if callback aborted
	;
	jcxz	quit				; Branch if no row-block
						; (doesn't affect flags)

	call	UnlockRowBlock			;preserves flags

quit:
	;
	; Carry set if the callback aborted
	;
	.leave
	ret

RangeEnumDataCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeEnumRowBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a row-block

CALLED BY:	RangeEnumDataCells
PASS:		ds	= Segment address of row block (must exist)
		ax	= Starting row
		ss:bx	= RangeEnumParams
		dl	= RangeEnumFlags
		ss:bp	= Parameters for callback
RETURN:		carry set if callback aborted
		zero flag clear (nz) if row-block no longer exists
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeEnumRowBlock	proc	near
	uses	ax, si
	.enter
	ComputeRowChunkHandle	ax, si		; *ds:si <- Current row
rowLoop:
	cmp	ax, ss:[bx].REP_bounds.R_bottom	; Check for done
	ja	quitNoAbortWithRowBlock		; Branch if done

	cmp	{word} ds:[si], -1		; Check for no such row-block
	je	nextRow				; Move to next row
	
	;
	; Now process all of the cells in the row.
	;
	call	RangeEnumRow			; Process the row
	;
	; Carry set if callback aborted.
	; Zero flag clear (nz) if the row-block is gone.
	;
	jc	quit				; Branch if it's gone
	jnz	quitNoAbort			; Branch if no more row-block

nextRow:
	;
	; ds	= Segment address of row block
	; si	= Chunk handle
	; ax	= Row
	;
	add	si, size word			; Move to next chunk
	inc	ax				; Move to next row
	;
	; Check for finished with this row-block.
	;
	test	ax, ROW_TO_ROW_CHUNK_MASK	; If all bits == 0, then done
	jnz	rowLoop				; Branch if not done

quitNoAbortWithRowBlock:
	clr	ax				; Set z flag

	;;; zero flag set (z): the row-block is complete and still exists.

quitNoAbort:
	;
	; Zero flag clear (nz) if the row block is gone.
	;
	clc					; Signal: Did not abort

quit:
	;
	; Carry set if the callback aborted.
	; Zero flag clear (nz) if the row block is gone.
	;
	.leave
	ret
RangeEnumRowBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeEnumRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process all the cells in a row.

CALLED BY:	RangeEnumRowBlock
PASS:		*ds:si	= Pointer to the row, must contain data.
		ax	= Current row
		ss:bx	= RangeEnumParams
		dl	= RangeEnumFlags
		ss:bp	= Parameters for callback
RETURN:		carry set if callback aborted
		zero flag clear (nz) if row-block no longer exists
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeEnumRow	proc	near
	uses	cx, di, si
	.enter
	mov	di, si				; di <- chunk handle

	mov	cx, ss:[bx].REP_bounds.R_left	; cx <- column
	;
	; Find the position of the starting column in the row.
	;
	; ax	= Row
	; cx	= Column
	; ss:bx	= RangeEnumParams
	;
	; Since ResynchRow() will get the position of the next entry (not
	; the current one) we decrement cx as a way of offseting the 'inc'
	; that ResynchRow() will be doing.
	;
	dec	cx				; Start at previous column
	call	ResynchRow			; si <- offset to the entry
EC <	ERROR_NZ ROW_AND_ROW_BLOCK_MUST_EXIST	>

columnLoop:
	;
	; ds	= Segment address of the row
	; di	= Chunk handle of the row
	; si	= Offset into the row
	; ss:bx	= RangeEnumParams
	; ax	= Row
	; dl	= RangeEnumFlags
	; ss:bp	= Parameters for callback
	;
	; Make sure the column offset isn't passed the end.
	;
	ChunkSizeHandle	ds, di, cx		; cx <- size of chunk
	cmp	si, cx				; Check for past end
	jae	endLoop				; Quit if we are

	push	si				; Save offset into row
	add	si, ds:[di]			; ds:si <- current entry
	clr	ch
	mov	cl, ds:[si].CAE_column		; cx <- column
	pop	si				; Restore offset into row

	cmp	cx, ss:[bx].REP_bounds.R_right	; Check for done
	ja	endLoop				; Branch if done

	call	ElementEnum			; Process the element
	;
	; Carry set if callback aborted
	; Zero flag clear (nz) if the row-block no longer exists.
	;
	jc	quit				; Branch if callback aborted
	jnz	quit				; Branch if row-block is gone

	;
	; Callback didn't abort and our row-block is intact.
	;
	; ds	= Segment address of the row
	; di	= Chunk handle of the row
	; si	= Offset into the row for next element
	;
	; Check to see if the row vanished (in which case we can quit)
	;
	cmp	{word} ds:[di], -1		; Check for row vanished
	jne	columnLoop			; Branch if it's still here

endLoop:
	;
	; The callback didn't abort and the row-block is still with us.
	;
	clr	cx				; Set zero flag (rb still here)
						; Clears carry flag (no abort)
quit:
	;
	; Carry set if the callback aborted.
	; Zero flag clear if row-block is gone.
	;
	.leave
	ret
RangeEnumRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ElementEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a single element

CALLED BY:	RangeEnumRow
PASS:		ax	= Row
		cx	= Column
		ss:bp	= Parameters for callback
		
		ss:bx	= RangeEnumParams
		dl	= RangeEnumFlags
		
		ds	= Segment address of the row
		di	= Chunk handle of the row
		si	= Offset into the row
RETURN:		Carry set if callback aborted
		Zero flag clear (nz) if the row-block has vanished
		si pointing at the next element in the row
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	- If the callback allocates an element we need to resynch our position
	  in the row.
	  
	- If the callback frees the current cell then we need to resynch our
	  position.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ElementEnum	proc	near
	uses	dx, di, es
	.enter
	;
	; First set up the RangeEnumFlags for the call.
	;
	and	dl, not (mask REF_CELL_ALLOCATED or \
			 mask REF_CELL_FREED or \
			 mask REF_OTHER_ALLOC_OR_FREE)

	push	ds, si, di			; Save pointer, chunk handle
	;
	; Does the caller want the row flags for this cell?
	;
	test	dl, mask REF_ROW_FLAGS
	jz	skipFlags			;branch if we don't want flags
	push	ax, si
	mov	ss:[bx].REP_flagRow, ax		;save row
	mov	si, ds:[si]			;ds:si <- row entry
	mov	ax, ds:[si].CAH_rowFlags	;ax <- row flags
	mov	ss:[bx].REP_rowFlags, ax
	pop	ax, si
skipFlags:
	;
	; Does the caller want us to lock down the cell data?
	;
	test	dl, mask REF_NO_LOCK
	jnz	skipLock			; branch if not locking

	;
	; Rather than calling RangeEnumLockCell() we just use DBLock() since
	; we know that the entry exists.
	;
	push	ax, bx				; Save row
	add	si, ds:[di]			; ds:si <- ptr to entry
	mov	ax, ds:[si].CAE_data.DBI_group	; ax <- group
	mov	di, ds:[si].CAE_data.DBI_item	; di <- item
	lds	si, ss:[bx].REP_cfp		; ds:si <- CellFunctionParameter
EC <	call	ECCheckCellParams		;>
	mov	bx, ds:[si].CFP_file		; bx <- VM file
	call	DBLock				; *es:di <- cell data
	pop	ax, bx				; Restore row

skipLock:

	lds	si, ss:[bx].REP_cfp		; ds:si <- CellFunctionParameters

	;
	; We don't need to save the 'cell exists' flag because it has to exist.
	; If it didn't exist, we wouldn't be here.
	;
	stc					; pass 'cell exists' flag
if  FULL_EXECUTE_IN_PLACE
	push	bx, ax
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	mov	ax, ss:[bx].REP_callback.offset
	mov	bx, ss:[bx].REP_callback.segment
	call	ProcCallFixedOrMovable
	pop	bx, ax
else
	call	ss:[bx].REP_callback		; Call the callback
endif
	
	;
	; Since this routine is only called for RangeEnumDataCells() we know
	; that the cell must have existed. Therefore the callback couldn't
	; possibly have allocated the current cell.
	;
EC <	pushf						>
EC <	test	dl, mask REF_CELL_ALLOCATED		>
EC <	ERROR_NZ CELL_ALREADY_EXISTED_BEFORE		>
EC <	popf						>

	pop	ds, si, di			; Restore pointer, chunk handle
	;
	; Unlock the cell, we know that it existed...
	;
	; Carry set if callback aborted
	;
	; ax	= Row
	; cx	= Column
	; ds	= Segment address of the row-block
	; di	= Chunk handle of the row
	; si	= Current offset into the row
	;
	; es	= Segment address of the cell
	; dl	= RangeEnumFlags
	;
	pushf					; Save "aborted" flag
	stc					; Signal: It existed
	call	RangeEnumUnlockCell		; Release the cell
	popf					; Restore "aborted" flag
	
	jc	abort				; Branch if callback aborted

	;
	; Move to the next element in the array.
	;
	add	si, size ColumnArrayElement	; Assume no changes

	;
	; Check for the special cases of allocating a new cell or freeing
	; the existing cell.
	;
	test	dl, mask REF_OTHER_ALLOC_OR_FREE or mask REF_CELL_FREED
	jz	gotNextElement			; Branch if no special case
						; (zero flag set if branch taken)

	;
	; Resynch our position in the row.
	;
	call	ResynchRow			; (nz) if row-block gone

gotNextElement:
	;
	; Zero flag clear (nz) if the row-block is gone
	; ds	= Segment address of the row-block (still)
	; di	= Chunk handle of the row (still)
	; si	= Offset to the next element in the row
	;
	clc					; Signal: callback didn't abort

quit:
	;
	; Carry set if the callback aborted
	; Zero flag clear (nz) if the row-block is gone
	;
	.leave
	ret

abort:
	;
	; Callback aborted. We may need to resynch if the callback alloc'd
	; or free'd anything.
	;
	test	dl, mask REF_OTHER_ALLOC_OR_FREE or mask REF_CELL_FREED
	jz	abortQuit			; Branch if no special case
						; (zero flag set if branch taken)
	call	ResynchRow			; (nz) if row block is gone

abortQuit:
	stc					; Signal: Callback aborted
	jmp	quit
ElementEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResynchRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get us set back up while processing a row.

CALLED BY:	RangeEnumRow, ElementEnum
PASS:		ax	= Row
		cx	= Current column
		ss:bx	= RangeEnumParams
		di	= Chunk handle of the row
RETURN:		Zero flag clear (nz) if the row block no longer exists
		ds	= Segment address of the row-block if it exists
		si	= Offset into the row to the next element
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResynchRow	proc	near
	uses	ax, bx, dx
	.enter
	;
	; We do need to resynch. The callback allocated a cell or freed the
	; current one.
	;

	;
	; Check for the row-block vanishing.
	;
	lds	si, ss:[bx].REP_cfp		; ds:si <- CellFunctionParameters
	ComputeRowBlockOffset	ax, bx		; bx <- index into block
	mov	ax, ds:[si].CFP_rowBlocks.RBL_blocks[bx]
	tst	ax				; row block still exists
	jz	rowBlockVanished		; Branch if no row-block
	
	;
	; The row-block still exists.
	;
	; Previously, ds was passed to us as the segment of the row block.
	; However, one of the many reasons we may be resynching things
	; is because another cell was allocated, which means the row
	; block may have been resized, which (even though it is locked)
	; means the row block may have moved.  So we dereference it
	; manually in case it has moved...
	;
	mov	bx, ds:[si].CFP_file		;bx <- file handle
	call	VMVMBlockToMemBlock
	mov	bx, ax				;bx <- memory handle
	call	MemDerefDS			;ds <- seg addr of row block
	;
	; Now check for the row still existing.
	;
	cmp	{word} ds:[di], -1		; Check row
	je	rowBlockStillHere		; Branch if row is gone
	
	;
	; The row is around. Find the entry in the row
	; ds	= Segment address of the row-block
	; di	= Chunk handle of the row
	; cx	= Column we want to find the entry after
	;
;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Changes to code  3/29/93 -jw
;
; The original code worked fine for all columns except #255.
; Unfortunately one of the calls expects this code to handle the value -1
; correctly (by getting the offset to the zero'th cell. I special case
; the -1 value and handle all the rest in the new (correct) manner.
;
	mov	si, di				; *ds:si <- row pointer

	cmp	cx, -1				; Check special case
	jne	useCorrectCode			; Branch if not special case

	;
	; This is the old code, which we execute in order to handle the
	; one case where we want to resynch to the start of the row.
	;
	inc	cx				; Find next entry
	call	FindCellInRow			; ds:si <- ptr to entry
	jmp	changeToOffset			; Branch to convert to offset

useCorrectCode:
	;
	; This code replaces those two lines above and handles the case
	; of column #255 correctly.
	;
	call	FindNextCellInRow		; Find next entry
						; ds:si <- ptr to entry

changeToOffset:
	sub	si, ds:[di]			; si <- offset to entry
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

rowBlockStillHere:
	;
	; The row may or may not be with us, but the row-block is still here.
	;
	clr	dx				; Set zero flag (rb still here)


quit:
	;
	; ds	= Segment address of row-block (if it exists)
	; di	= Chunk handle of the row (still)
	; si	= Offset into the row for next entry
	;
	; Zero flag clear (nz) if the row-block is gone.
	;
	.leave
	ret

rowBlockVanished:
	;
	; Signal that the row is not here.
	;
	clr	dx				; dx <- 0
	inc	dx				; Clear zero flag (nz)
	jmp	quit
ResynchRow	endp

CellCode	ends
