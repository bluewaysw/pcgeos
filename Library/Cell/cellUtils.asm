COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cellUtils.asm

AUTHOR:		John Wedgwood, Aug  9, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 8/ 9/91	Initial revision

DESCRIPTION:
	Utilities for insert/delete and sorting.

	$Id: cellUtils.asm,v 1.1 97/04/04 17:45:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockAndDirtyRowBlockWithHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock and dirty a row block.

CALLED BY:	InsertColumns
PASS:		cx	= VM block handle (0 if no block handle)
RETURN:		cx	= 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockAndDirtyRowBlockWithHandle	proc	near
	jcxz	skipUnlock			; Branch if no row block

	xchg	bp, cx				; bp <- handle, cx <- frame ptr
	call	VMDirty				; Dirty the row block
	call	VMUnlock			; Release the row block
	mov	bp, cx				; bp <- frame ptr

skipUnlock:	
	clr	cx				; No row block right now
	ret
UnlockAndDirtyRowBlockWithHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeRowRangeSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the number of bytes in a range of columns.

CALLED BY:	InsertPartialRowCallback
PASS:		*ds:si	= Pointer to the row
		al	= Start column
		ah	= End column
RETURN:		cx	= Size of the range
		dx	= # of entries
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeRowRangeSize	proc	near
	uses	di, si
	.enter
	ChunkSizeHandle	ds, si, di		; di <- offset to chunk end
	add	di, ds:[si]			; di <- ptr to chunk end

	mov	cl, al				; cl <- column of the cell
	call	FindCellInRow			; ds:si <- ptr to cell (or close)

	clr	cx				; Size so far
	clr	dx				; No entries so far
columnLoop:
	;
	; ds:si	= Pointer to current entry
	; ds:di	= Pointer past end of the row
	; ah	= End column
	; cx	= Current size
	; dx	= # of entries so far
	;
	cmp	si, di				; Check for done
	je	done				; Branch if no more to do
	
	cmp	ds:[si], ah			; Check for past end column
	ja	done				; Branch if past end column
	
	inc	dx				; One more element
	add	cx, size ColumnArrayElement	; cx += element size
	add	si, size ColumnArrayElement	; ds:si <- next entry
	jmp	columnLoop			; Branch to check it out

done:
	.leave
	ret
ComputeRowRangeSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyRowRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a range of a given row to another row.

CALLED BY:	InsertPartialRowCallback
PASS:		*ds:si	= Source row
		*es:di	= Destination row
		al	= Start column
		ah	= Ending column
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyRowRange	proc	near
	uses	ax, bx, cx, dx, di, si
	.enter
	call	ComputeRowRangeSize		; cx <- size of range
						; dx <- # of entries to nuke

	;
	; We have the size and number of entries we'll be moving. We need to
	; make space for it in the destination chunk.
	;
	push	ds:LMBH_handle			; Save source block handle
	push	di, si, ax			; Save chunks, column
	segmov	ds, es, bx			; ds <- destination segment
	mov	si, di				; *ds:si <- destination row
	mov	bx, ds:[si]			; ds:bx <- destination row
	
	push	cx				; Save # of bytes
	mov	cl, al				; cl <- start column
	call	FindCellInRow			; ds:si <- ptr to source entry
	pop	cx				; Restore # of bytes
	
	sub	si, bx				; si <- offset to insert at

	add	ds:[bx].CAH_numEntries, dx	; Update the number of entries
	
	;
	; ds	= Segment address of destination
	; di	= Chunk handle
	; si	= Offset to insert at
	; cx	= # of bytes to insert
	;
	mov	ax, di				; ax <- chunk
	mov	bx, si				; bx <- offset to insert at
	call	LMemInsertAt			; Make the space
	segmov	es, ds, ax			; es <- destination segment

	pop	di, si, ax			; Restore chunks, column
	mov	dx, bx				; dx <- offset into dest row
	pop	bx				; bx <- source block handle
	call	MemDerefDS			; ds <- source block segment
	
	;
	; *ds:si = Source row
	; *es:di = Destination row
	; dx	 = Offset into destination row for the copy
	; cx	 = # of bytes to move
	; al	 = Starting column
	;
	
	push	cx				; Save size of range
	mov	cl, al				; al <- start row
	call	FindCellInRow			; ds:si <- ptr to entry
	pop	cx				; Restore size of range

	mov	di, es:[di]			; es:di <- ptr to base of dst row
	add	di, dx				; es:di <- ptr to dest range

	;
	; ds:si	= Pointer to the start of the source range
	; es:di	= Pointer to the start of the destination range
	; cx	= Size of range we want to nuke + size ColumnArrayHeader
	;
	rep	movsb				; Copy the data
	.leave
	ret
CopyRowRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteRowRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a range of columns from a row.

CALLED BY:	InsertPartialRowCallback
PASS:		*ds:si	= Row
		al	= Starting column
		ah	= Ending column
RETURN:		carry set if the row should be nuked
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteRowRange	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	call	ComputeRowRangeSize		; cx <- size of range
						; dx <- # of entries to nuke
	add	cx, size ColumnArrayHeader	; cx <- size w/ header
	
	ChunkSizeHandle	ds, si, bx		; bx <- chunk size
	
	cmp	bx, cx				; Check for same size
	je	nukeRow				; Branch if nuking entire row
	
	;
	; The row will still be around when we are all done
	;
	mov	di, si				; di <- chunk handle (save it)

	push	cx				; Save size of range
	mov	cl, al				; al <- start row
	call	FindCellInRow			; ds:si <- ptr to entry
	pop	cx				; Restore size of range

	;
	; *ds:di = Pointer to the row
	; ds:si	 = Pointer to the start of the range
	; cx	 = Size of range we want to nuke + size ColumnArrayHeader
	;
	sub	si, ds:[di]			; si <- offset to delete at
	mov	bx, si				; bx <- offset to delete at

	mov	ax, di				; ax <- chunk
	sub	cx, size ColumnArrayHeader	; cx <- # of bytes to nuke

	;
	; ds	= Segment address of the block
	; ax	= Chunk handle
	; bx	= Offset to delete at
	; cx	= # of bytes to delete
	; dx	= # of entries in the range we're nuking
	;
	call	LMemDeleteAt			; Nuke the space
	
	;
	; Now update the number of entries in the row.
	;
	mov	si, ax				; si <- chunk handle
	mov	di, ds:[si]			; ds:di <- ptr to the row
	sub	ds:[di].CAH_numEntries, dx	; This many fewer entries
	
	clc					; Signal: Keep the row.
quit:
	;
	; Carry should be set if we want to nuke the row.
	;
	.leave
	ret

nukeRow:
	stc					; Signal: nuke the row
	jmp	quit
DeleteRowRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureSourceBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that we have a source block

CALLED BY:	InsertRowCommon
PASS:		ss:bx	= InsertRowParams
		ss:bp	= RangeInsertParams
RETURN:		ds	= Segment address of the source block
		carry set if there isn't one
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Check for a source block
	If there is one then return
	
	Otherwise update the source and destination row
	Unlock the destination block always

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureSourceBlock	proc	near
	uses	ax, si
	.enter
	tst	ss:[bx].IRP_sourceBlock		; Check for a source
						; (carry is cleared by the tst)
	jnz	quit				; Branch if we done
	
	;
	; There wasn't a source block. Move to another one.
	;
	lds	si, ss:[bp].RIP_cfp		; ds:si <- CellFunctionParameters
	mov	ax, ss:[bx].IRP_source		; ax <- source row
	call	LockRowBlock			; ds <- segment of row block
	jnc	noBlock				; Branch if there is none

	;
	; The row block is there. Save the block handle into the frame ptr.
	;
	mov	ax, ds:LMBH_handle		; ax <- handle for the row block
	mov	ss:[bx].IRP_sourceBlock, ax	; Save the source block
	clc					; We do have a block
quit:
	.leave
	ret

noBlock:
	;
	; We didn't have a source block. Move to the next one.
	;
	mov	ax, ss:[bx].IRP_nextSource	; ax <- nextSource - source
	sub	ax, ss:[bx].IRP_source

	add	ss:[bx].IRP_dest, ax		; Adjust destination
	add	ss:[bx].IRP_source, ax		; Adjust source

	call	UnlockDestBlock			; Always unlock the dest block
	;
	; We call ComputeNextSourceAndDestRBStarts() to get recalculate
	; the row block starts because simply subtracting N_ROWS_PER_ROW_BLOCK
	; from each will not give the correct results -- a boundary case
	; when inserting one row will end up with the destination row
	; block off-by-one. 
	;
	call	ComputeNextSourceAndDestRBStarts
	stc					; Signal: didn't have a block
	jmp	quit
EnsureSourceBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockDestBlock, UnlockSource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the source/destination block (if there is one)

CALLED BY:	EnsureSourceBlock
PASS:		ss:bx	= InsertRowParams
RETURN:		IRP_sourceBlock/IRP_destBlock zeroed.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockDestBlock	proc	near
	uses	bp
	.enter

	clr	bp
	xchg	bp, ss:[bx].IRP_destBlock	; bp <- dest block
	
	tst	bp				; Check for no dest block
	jz	quit				; Branch if no block
	
	call	VMDirty				; Dirty it, what the heck
	call	VMUnlock			; Release the dest block
quit:
	.leave
	ret
UnlockDestBlock	endp

UnlockSourceBlock	proc	near
	uses	bp
	.enter

	clr	bp
	xchg	bp, ss:[bx].IRP_sourceBlock	; bp <- source block
	
	tst	bp				; Check for no source block
	jz	quit				; Branch if no block
	
	call	VMDirty				; Dirty it, what the heck
	call	VMUnlock			; Release the source block
quit:
	.leave
	ret
UnlockSourceBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeNextSourceAndDestRBStarts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the point at which we need to move to the next/previous
		source and destination row blocks.

CALLED BY:	InsertRowCommon
PASS:		ss:bx	= InsertRowParams w/ IRP_source/dest set
		ss:bp	= RangeInsertParams
RETURN:		IRP_nextSource/Dest set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The formula for the start of the next block is:
	If moving data up:
		nxt = N_ROWS_PER_ROW_BLOCK * (RowBlock(current) + 1)
	If moving data down:
		nxt = (N_ROWS_PER_ROW_BLOCK * RowBlock(current)) - 1

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeNextSourceAndDestRBStarts	proc	near
	uses	ax, cx, dx, di, si, bp
	.enter
	;
	; We're going to load up:
	;	ax = Source
	;	dx = Destination
	;	di = Amount to add to row-block
	;	si = Amount to subtract from the total
	;
	mov	ax, ss:[bx].IRP_source		; ax <- source row
	mov	dx, ss:[bx].IRP_dest		; dx <- destination row
	
	mov	di, 1				; Assume moving data up
	clr	si

	tst	ss:[bp].RIP_delta.P_y		; Check for negative delta
	js	gotParams			; Branch if moving data up

	xchg	si, di				; Moving data down

gotParams:
	;
	; ax = Source row
	; dx = Destination row
	; di = Amount to add to row-block
	; si = Amount to subtract from total
	; ss:bx = Pointer to InsertRowParams
	;
	mov	cl, ROW_TO_ROW_BLOCK_SHIFT_COUNT

	shr	ax, cl				;ax <- row block #
	add	ax, di				;add in mystery amount
	shl	ax, cl				;ax <- row at start of row block
	sub	ax, si				;subtract mystery amount

	mov	ss:[bx].IRP_nextSource, ax	;save offset to next block
	;
	; Now compute the next destination row block position
	;
	shr	dx, cl				;dx <- row block #
	add	dx, di				;add in mystery amount
	shl	dx, cl				;dx <- row at start of row block
	sub	dx, si				;subtract mystery amount

	mov	ss:[bx].IRP_nextDest, dx	;save offset to next block

	.leave
	ret
ComputeNextSourceAndDestRBStarts	endp

CellCode	ends
