COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cellInsertDelete.asm

AUTHOR:		John Wedgwood, Aug  9, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 8/ 9/91	Initial revision

DESCRIPTION:
	Insert/delete code.

	$Id: cellInsertDelete.asm,v 1.1 97/04/04 17:44:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert/Delete rows or columns.

CALLED BY:	Global
PASS:		ds:si	= Pointer to CellFunctionParameters
		ss:bp	= Pointer to RangeInsertParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There are three different operations:
	    delta.Y != 0
		Insert partial row
	      left = 0, right = LARGEST_COLUMN
		Insert complete row

	    delta.X != 0
		Insert partial/complete column

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeInsert	proc	far
	uses	ax, bx
	.enter

	mov	ss:[bp].RIP_cfp.segment, ds	; Save CFP pointer
	mov	ss:[bp].RIP_cfp.offset, si

	;
	; Figure out which of the three possible handlers to call.
	;
	mov	ax, offset cs:InsertColumns	; ax <- routine to call
	tst	ss:[bp].RIP_delta.P_x		; Check for delta.X != 0
	jnz	gotRoutine			; Branch if inserting columns
	
	mov	ax, offset cs:InsertPartialRows	; ax <- routine to call
	tst	ss:[bp].RIP_bounds.R_left	; Check for left = 0
	jnz	gotRoutine			; Branch if not (partial row)

	cmp	ss:[bp].RIP_bounds.R_right, LARGEST_COLUMN
	jne	gotRoutine			; Branch if partial row
	
	mov	ax, offset cs:InsertCompleteRows

gotRoutine:
	;
	; ax = Routine to call
	;
	call	ax				; Do the insert/delete
	
	.leave
	ret
RangeInsert	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert/Delete columns

CALLED BY:	RangeInsert
PASS:		ss:bp	= Pointer to RangeInsertParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Foreach row:
	    Find left column to move
	    Foreach cell structure:
	        cell.column += delta.X

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertColumns	proc	near
	uses	ax, bx, cx, dx, di, si, ds
	.enter
	;
	; NOTE: various branches in this routine are signed branches
	; because some calculations can produce signed results.  Because
	; the maximum row/column is < 32767, signed results and signed
	; branches are not a problem.
	;

	;
	; Figure out the offset at which the next row-block starts
	; The technique I use is:
	;	(startRow + N_ROWS_PER_ROW_BLOCK) & not ROW_TO_ROW_CHUNK_MASK
	;
	mov	ax, ss:[bp].RIP_bounds.R_top	; ax <- first row
	ComputeNextRowBlockStart	ax	; ax <- offset to next row block
	mov	bx, ax				; bx <- offset to next row block

	;
	; Load up the first/last row.
	; bx	= Offset to start of next row block
	; ss:bp	= RangeInsertParams
	;
	mov	ax, ss:[bp].RIP_bounds.R_top	; ax <- first row
	mov	dx, ss:[bp].RIP_bounds.R_bottom	; dx <- last row
	
	clr	cx				; No row block locked yet
	
rowBlockLoop:
	;
	; ax	= Current row
	; bx	= Row which starts next row block
	; cx	= Block handle of the current row block
	; dx	= Last row to do
	; ss:bp	= RangeInsertParams
	;
	; Check for no more rows to do.
	;
	cmp	ax, dx				; Check for done
	jg	quit				; Branch if done last row

	;
	; Lock the current row block.
	;
	lds	si, ss:[bp].RIP_cfp		; ds:si <- CellFunctionParameters
	call	LockRowBlock			; ds <- seg-addr of row block
	jnc	nextRowBlock			; Branch if no such row block
	
	;
	; We've got a row block, save the handle somewhere we can get at it.
	;
	mov	cx, ds:LMBH_handle		; cx <- row block handle

rowLoop:
	;
	; ax	= Current row
	; bx	= Row which starts next row block
	; cx	= Block handle of current row block
	; dx	= Last row
	; ss:bp	= RangeInsertParams
	; ds	= Segment address of current row block
	;
	cmp	ax, dx				; Check for done
	jg	quit				; Branch if done last row
	
	cmp	ax, bx				; Check for done with row block
	jge	nextRowBlock			; Branch if need next row block

	;
	; We stay in this row block.
	;
	call	GetRowPointer			; *ds:si <- row pointer
	jnc	nextRow				; Branch if no such row
	
	;
	; The row block exists and the row exists.
	; *ds:si= Pointer to the row.
	;
	; Find the column where we want to start processing.
	;
	ChunkSizeHandle	ds, si, di		; di <- Offset to end of row
	add	di, ds:[si]			; di <- ptr past end of row

	push	cx				; Save row block handle
	mov	cx, ss:[bp].RIP_bounds.R_left	; cl <- left edge to find
	call	FindCellInRow			; ds:si <- ptr to cell
						; carry set if found
columnLoop:
	;
	; Process from here to the end of the block.
	; ds:si	= Pointer to current entry
	; ds:di	= Place to stop processing
	;
	cmp	si, di				; Check for gone too far
	je	endColumnLoop			; Branch if gone too far
	
	mov	cx, ss:[bp].RIP_delta.P_x	; cl <- amount of change
	add	ds:[si].CAE_column, cl		; Adjust this column
	
	add	si, size ColumnArrayElement	; Move to next element
	jmp	columnLoop			; Branch to do the next one
endColumnLoop:
	pop	cx				; Restore row block handle

nextRow:
	inc	ax				; Move to next row
	jmp	rowLoop				; Branch to process it

nextRowBlock:
	;
	; Move to the next row block.
	; bx = Row which starts the next row block.
	;
	mov	ax, bx				; ax <- start of next row block
	add	bx, N_ROWS_PER_ROW_BLOCK	; bx <- offset to next row block
	
	;
	; Now dirty the current row block and unlock it.
	; cx = Block handle of row block (if any)
	;
	call	UnlockAndDirtyRowBlockWithHandle ; Release and dirty the row block
	jmp	rowBlockLoop			; Branch to handle it

quit:
	;
	; cx = Block handle of row block (if any).
	;
	call	UnlockAndDirtyRowBlockWithHandle

	.leave
	ret
InsertColumns	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertPartialRows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert/Delete partial rows

CALLED BY:	RangeInsert
PASS:		ds:si	= Pointer to CellFunctionParameters
		ss:bp	= Pointer to RangeInsertParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertPartialRows	proc	near
	uses	bx
	.enter
	sub	sp, size InsertRowParams	; Make a stack frame
	mov	bx, sp				; ss:bx <- ptr to stack frame
	
	mov	ss:[bx].IRP_callback, offset cs:InsertPartialRowCallback
	call	InsertRowCommon			; Do the insert/delete

	add	sp, InsertRowParams		; Restore stack frame
	.leave
	ret
InsertPartialRows	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertPartialRowCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move part of a row

CALLED BY:	InsertRowCommon
PASS:		ss:bp	= Pointer to RangeInsertParams
		ss:bx	= Pointer to InsertRowParams
		*ds:si	= Pointer to source row
		es	= Destination row block if IRP_destBlock is non-zero
RETURN:		IRP_destBlock, IRP_sourceBlock possibly modified
		ds	= Segment address of IRP_sourceBlock
		es	= Segment address of IRP_destBlock
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertPartialRowCallback	proc	near
	uses	ax, cx, dx, di, si
	.enter
	;
	; Figure the size of the range that we want to move
	;
	mov	al, {byte} ss:[bp].RIP_bounds.R_left
	mov	ah, {byte} ss:[bp].RIP_bounds.R_right
	call	ComputeRowRangeSize		; cx <- range size
	jcxz	quit				; Branch if no data to move

	;
	; We know that the destination range doesn't exist.
	;
	tst	ss:[bx].IRP_destBlock		; Check for a destination block
	jnz	gotDstBlock			; Branch if got a row block
	
	;
	; Need to get the destination row block and lock it.
	;
	push	ds, si, ax			; Save src row ptr, start/end
	lds	si, ss:[bp].RIP_cfp		; ds:si <- CellFunctionParameters
	mov	ax, ss:[bx].IRP_dest		; ax <- destination row
	call	ForceLockRowBlock		; ds <- destination row block
	
	mov	ax, ds:LMBH_handle		; ax <- block handle
	mov	ss:[bx].IRP_destBlock, ax	; Save destination row block
	
	segmov	es, ds, ax			; es <- seg addr of destination
	pop	ds, si, ax			; Restore src row ptr, start/end

gotDstBlock:
	;
	; *ds:si = Source row
	; es	 = Segment address of destination row block
	; ss:bp	 = RangeInsertParams
	; ss:bx	 = InsertRowParams
	; al	 = Starting column
	; ah	 = Ending column
	;

	push	si, ax, bx			; Save src ptr, start/end, frame
	push	ds:LMBH_handle			; Save source block handle

	segmov	ds, es, ax			; ds <- seg of dest row block
	mov	ax, ss:[bx].IRP_dest		; ax <- destination row
	call	ForceGetRowPointer		; *ds:si <- chunk of dest row
	
	segmov	es, ds, di			; Update dest segment register
	mov	di, si				; di <- chunk of dest row

	pop	bx				; bx <- source block handle
	call	MemDerefDS			; ds <- source block
	pop	si, ax, bx			; Rstr src ptr, start/end, frame

	;
	; Move the data from one row to the other.
	;
	; *ds:si = Source row
	; *es:di = Destination row
	; al	 = Starting column
	; ah	 = Ending column
	;
	call	CopyRowRange			; Move the data

	call	DeleteRowRange			; Remove the data
	jnc	quit				; Branch if there's still data
	
	;
	; The row is empty, nuke it.
	;
	push	ds, es, bx			; Save src/dst, frame
	mov	dx, ss:[bx].IRP_source		; dx <- row we're nuking
	mov	ax, ds				; ax <- segment address of row
	mov	bx, si				; bx <- row chunk handle
	lds	si, ss:[bp].RIP_cfp		; ds:si = CellFunctionParameters
	call	ZeroRow				; Nuke the row
	pop	ds, es, bx			; Restore src/dst, frame
	
	jnc	quit				; Branch if row block exists
	
	mov	ss:[bx].IRP_sourceBlock, 0	; No more source row block
quit:
	.leave
	ret
InsertPartialRowCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertCompleteRows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert/Delete complete rows

CALLED BY:	RangeInsert
PASS:		ds:si	= Pointer to CellFunctionParameters
		ss:bp	= Pointer to RangeInsertParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Inserting complete rows requires us to move the row chunks
	from one place to another.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertCompleteRows	proc	near
	uses	bx
	.enter
	sub	sp, size InsertRowParams	; Make a stack frame
	mov	bx, sp				; ss:bx <- ptr to stack frame
	
	mov	ss:[bx].IRP_callback, offset cs:InsertCompleteRowCallback
	call	InsertRowCommon			; Do the insert/delete

	add	sp, InsertRowParams		; Restore stack frame
	.leave
	ret
InsertCompleteRows	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertCompleteRowCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move a complete of row

CALLED BY:	InsertRowCommon
PASS:		ss:bp	= Pointer to RangeInsertParams
		ss:bx	= Pointer to InsertRowParams
		*ds:si	= Pointer to source row
		es	= Destination row block if IRP_destBlock is non-zero
RETURN:		IRP_destBlock, IRP_sourceBlock possibly modified
		ds	= Segment address of IRP_sourceBlock (if non-zero)
		es	= Segment address of IRP_destBlock (if non-zero)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertCompleteRowCallback	proc	near
	uses	ax, cx, dx, di, si
	.enter
	;
	; We know that the destination row doesn't exist, so we need to create
	; the row.
	;
	tst	ss:[bx].IRP_destBlock		; Check for a destination block
	jnz	gotDstBlock			; Branch if got a row block
	
	;
	; Need to get the destination row block and lock it.
	;
	push	ds, si				; Save source row ptr
	lds	si, ss:[bp].RIP_cfp		; ds:si <- CellFunctionParameters
	mov	ax, ss:[bx].IRP_dest		; ax <- destination row
	call	ForceLockRowBlock		; ds <- destination row block
	
	mov	ax, ds:LMBH_handle		; ax <- destination row block
	mov	ss:[bx].IRP_destBlock, ax	; Save destination row block
	
	segmov	es, ds, ax			; es <- seg addr of destination
	pop	ds, si				; Restore source row ptr

gotDstBlock:
	;
	; *ds:si = Source row
	; es	 = Segment address of destination row block
	; ss:bp	 = RangeInsertParams
	; ss:bx	 = InsertRowParams
	;
	mov	ax, ds				; ax <- source segment
	mov	cx, es				; cx <- destination segment

	cmp	ax, cx				; Check for in same row block
	jne	notSameRowBlock			; Branch if not same row block
	
	;
	; The rows are in the same row block, just move the chunk ptr.
	;
	mov	ax, ss:[bx].IRP_dest		; ax <- destination row
	ComputeRowChunkHandle	ax
	mov	di, ax				; di <- chunk handle
	
	mov	ax, ds:[si]			; ax <- source chunk ptr
	mov	es:[di], ax			; Save chunk ptr
	mov	{word} ds:[si], -1		; Mark ds:[si] as empty chunk

quit:
	.leave
	ret

notSameRowBlock:
	;
	; The rows aren't in the same row block. Copy the chunk.
	;
	ChunkSizeHandle	ds, si, cx		; cx <- size of row
	
	;
	; Allocate space for the row in the destination block.
	;
	push	ds, si				; Save source ptr
	segmov	ds, es, ax			; ds <- destination heap
	mov	ax, ss:[bx].IRP_dest		; ax <- destination row #
	ComputeRowChunkHandle	ax
	mov	di, ax				; di <- chunk handle

	mov	ax, di				; ax <- destination chunk
	call	LMemReAlloc			; *ds:ax <- destination chunk
	
	segmov	es, ds, di			; *es:di <- destination row
	mov	di, ax
	pop	ds, si				; Restore source ptr
	
	;
	; *ds:si = Source chunk
	; *es:di = Destination chunk
	; cx	 = Size of the chunk
	;
	push	ds, es, bx			; Save src/dst, frame ptr
	mov	dx, ss:[bx].IRP_source		; dx <- source row
	mov	bx, si				; bx <- source chunk

	;
	; Copy the bytes.
	;
	mov	si, ds:[si]			; ds:si <- source bytes
	mov	di, es:[di]			; es:di <- dest bytes
	rep	movsb				; Copy the chunk
	
	;
	; Zero the row.
	;
	; bx = the row chunk handle
	; dx = The row we're zeroing
	;
	mov	ax, ds				; ax <- segment address of row
	lds	si, ss:[bp].RIP_cfp		; ds:si <- CellFunctionParameters
	call	ZeroRow				; Zero the row
	
	pop	ds, es, bx			; Restore src/dst, frame ptr

	jnc	quit				; Branch if row block exists
	
	mov	ss:[bx].IRP_sourceBlock, 0	; No more source row block
	jmp	quit
InsertCompleteRowCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertRowCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert or delete partial or complete rows.

CALLED BY:	InsertCompleteRows, InsertPartialRows
PASS:		ss:bp	= Pointer to RangeInsertParams
		ss:bx	= Pointer to InsertRowParams
		ds:si	= CellFunctionParameters
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	In english:
		Foreach row:
		    Find where it is now.
		    Find where it is going.
		    ReAlloc the destination block to the right size.
		    Copy the data
		    ReAlloc the source block to zero
		    
	Some optimizations we make:
	    - The destination will never exist
		This means that if the source doesn't exist, we can skip the
		copy.

findSrc:
	if (src != end)				/* Check for done */
	    goto quit
	endif

	if (srcBlk == 0)			/* Make sure we have a source */
	    srcBlock = LockRowBlock( src )
	    if (srcBlock == 0) then
	        dest += (next_src_block_start - src)
	        src = next_src_block_start
	    endif
	    goto findSrc
	endif
	
	if (src == next_src_block_start)	/* Check for in next block */
	    Unlock( sourceBlock )
	    Unlock( destBlock )
	    goto findSrc
	endif

	srcPtr = GetRowPointer( src )		/* Get row pointer */
	if (srcPtr != 0) then			/* Only if we have a row ptr */
	    /*
	     * We have both a source and destination pointer
	     */
	    MoveRow( srcPtr, destPtr )
	endif
	    
	/*
	 * Move to next row
	 */
	src += increment
	dest += increment
	    
	/*
	 * Check for in next destination row block
	 */
	if (dest != next_dest_block_start) then
	    Unlock( destBlock )
	endif
	goto findSrc

quit:
	    

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertRowCommon	proc	near
	uses	ax, bx, cx, dx, di, si, bp, ds, es
	.enter
	
	;
	; NOTE: various branches in this routine are signed branches
	; because some calculations can produce signed results.  Because
	; the maximum row/column is < 32767, signed results and signed
	; branches are not a problem.
	;

	;
	; Initialize the InsertRowParams
	; Assume we're deleting.
	;
	mov	ax, ss:[bp].RIP_bounds.R_top	; ax <- start
	mov	cx, ss:[bp].RIP_bounds.R_bottom	; cx <- end
	mov	dx, 1				; dx <- increment
	
	tst	ss:[bp].RIP_delta.P_y		; Check for not deleting
	js	gotParams			; Branch if we are deleting
	
	xchg	ax, cx				; Move bottom to top
	neg	dx

gotParams:
	mov	ss:[bx].IRP_source, ax		; Save starting row
	mov	ss:[bx].IRP_end, cx		; Save ending row
	mov	ss:[bx].IRP_increment, dx	; Save increment
	
	mov	ss:[bx].IRP_sourceBlock, 0	; Zero source row block
	mov	ss:[bx].IRP_destBlock, 0	; Zero destination row block
	
	;
	; Compute the destination.
	;
	add	ax, ss:[bp].RIP_delta.P_y	; ax <- destination row
	mov	ss:[bx].IRP_dest, ax		; Save destination row
	
	;
	; Figure the starts of the following source and dest row blocks
	;
rowLoopReset:
	call	ComputeNextSourceAndDestRBStarts
rowLoop:	
	;
	; Now start processing the rows.
	; We want to make sure that we're not done. Unfortunately the branch
	; could be a "above" or it could also be "below".
	;
	tst	ss:[bp].RIP_delta.P_y		; Check for deleting
	js	deleteCheck			; Branch if deleting

	;
	; If we're inserting we're moving data down. This means we're processing
	; the rows from bottom to top. We're done if the current row is below
	; the end row.
	mov	ax, ss:[bx].IRP_source		; ax <- source
	cmp	ax, ss:[bx].IRP_end		; Check for done
	jl	quit				; Branch if done
	jmp	notDone				; Branch if we're not done.

deleteCheck:
	;
	; If we're deleting we're moving data up. This means we're processing
	; the rows from top to bottom. We're done if the current row is above
	; the end row.
	mov	ax, ss:[bx].IRP_source		; ax <- source
	cmp	ax, ss:[bx].IRP_end		; Check for done
	jg	quit				; Branch if done

notDone:
	call	EnsureSourceBlock		; Make sure we've got a source
	jc	rowLoop				; Branch if there isn't one
	
	mov	ax, ss:[bx].IRP_source		; Check for into next block
	cmp	ax, ss:[bx].IRP_nextSource
	jne	gotSource			; Branch if we have source block
	
	call	UnlockSourceBlock		; Unlock source block
	call	UnlockDestBlock			; Unlock the destination block
	jmp	rowLoopReset			; Loop to start again...

gotSource:

	;
	; We have a source block, finally...
	; ds	= Segment address of the source block
	; ax	= Source row
	; ss:bx	= InsertRowParams
	; ss:bp	= RangeInsertParams
	;
	call	GetRowPointer			; *ds:si <- ptr to the row
	jnc	noRow				; Branch if no row

	;
	; There is a source row.
	;
	call	ss:[bx].IRP_callback		; Let callback handle it

noRow:
	;
	; We're done with this row, move to the next one.
	;
	mov	ax, ss:[bx].IRP_increment	; ax <- increment value
	add	ss:[bx].IRP_source, ax		; Next source row
	add	ss:[bx].IRP_dest, ax		; Next dest row
	
	;
	; Make sure that we haven't moved into the next dest block.
	;
	mov	ax, ss:[bx].IRP_dest		; ax <- dest
	cmp	ax, ss:[bx].IRP_nextDest	; Check for next dest block
	jne	rowLoop				; Branch if not
	call	UnlockDestBlock			; Release dest block
	jmp	rowLoopReset			; Branch to keep going

quit:
	;
	; Unlock the source and destination blocks.  UnlockSourceBlock()
	; and UnlockDestBlock() check for the case that the block in
	; question has already been unlocked.
	;
	call	UnlockSourceBlock
	call	UnlockDestBlock

	.leave
	ret
InsertRowCommon	endp


CellCode	ends
