COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		Engine
FILE:		cwordEngine.asm

AUTHOR:		Jennifer Lew, May 12, 1994

ROUTINES:
	Name			Description
	----			-----------
		INITIALIZATION ROUTINES		

		BASIC ACCESS
	EngineGetPuzzleDimensions
	EngineMapAGCToCellToken
	EngineGetCellAGC
	EngineMapCellTokenToClueToken
	EngineSetUserLetter
	EngineGetCellFlags
	EngineGetCellFlagsFar
	EngineGetSolutionLetter
	EngineSetUserLetterHinted
	EngineSetUserLetterVerified
	EngineSetCellEmpty
	EngineMapClueTokenToFirstCellToken
	EngineGetPrevCellTokenInRow
	EngineGetNextCellTokenInRow
	EngineGetPrevCellTokenInColumn
	EngineGetNextCellTokenInColumn
	EngineGetCellNumber
	EngineVerifyCell


		BASIC CLUES ACCESS
	EngineGetFirstClueTokenAcross
	EngineGetFirstClueTokenDown
	EngineGetNextClueTokenAcross
	EngineGetNextClueTokenDown
	EngineGetNextClueToken
	EngineGetClueType
	EngineGetClueText

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/12/94   	Initial revision

DESCRIPTION:
	This file contains routines provided by the Engine Module
	of the Crossword Puzzle Application.
		
	$Id: cwordEngine.asm,v 1.1 97/04/04 15:13:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CwordCode	segment	resource




;----------------------------------------------------------------------------
;			BASIC	ACCESS
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMapAGCToCellToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps an absolute grid coordinate to a cell token.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		al	- x grid coordinate
		bl	- y grid coordinate

RETURN:		cx	- cell token

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	   The cell token is really just the index into the cell
	   chunk array.
		index = (Y coord * cells in row) + X coord
		cells in row is the number of columns on the board

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMapAGCToCellToken	proc	near
	uses	ax,bx,dx,bp,ds
	.enter

	Assert	EngineTokenType	dx
	Assert	ge	al, 0
	Assert	ge	bl, 0

	EngineGetCellSegmentDS			; ds - cell block segment
	mov	bp, dx				; engine token

	Assert	l	al, ds:[CBH_columns]
	Assert	l	bl, ds:[CBH_rows]

	; MAP AGC TO CELL TOKEN (INDEX)
	; index = (Y coord * cells in row) + X coord

	clr	ah, bh
	clr	dx
	mov	dl, al			; save X coord in dl

	mov	al, bl			; al = Y coord

	; number of columns = number of cells in a row
	mov	cl, {byte} ds:[CBH_columns]
	mul	cl			; ax = Y coord * columns
	add	ax, dx			; ax = (Y coord * columns)
					;             + X coord
	mov	cx, ax			; the final index

EC <	xchg	dx, bp			; engine token			>
EC <	call	ECVerifyCellTokenType					>
EC <	xchg	dx, bp			; engine token			>

	mov	bx, bp			; engine token
	Assert	lmem	bx
	call	MemUnlock

	.leave
	ret
EngineMapAGCToCellToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetCellAGC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the X and Y absolute grid coordinates given
		the cell token

CALLED BY:	GLOBAL
PASS:		ax	- cell token
		dx	- engine token

RETURN:		bx	- X grid coord
		cx	- y grid coord

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Y coord = quotient (index / columns)
	X coord = index - (Y coord * columns)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetCellAGC	proc	near
	uses	ax,ds,bp
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellSegmentDS		; ds - cell block segment

	mov	bp, ax			; save index

	mov	cl, ds:[CBH_columns]
	div	cl			; al = Y coord
	clr	ah
	push	ax			; save Y coord (the quotient)

	mul	cl			; ax = Y coord * columns
	sub	bp, ax			; X coord
	
	EngineUnlockDX

	mov	bx, bp			; X coord
	Assert	e	bh, 0

	pop	cx			; Y coord

	.leave
	ret
EngineGetCellAGC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMapCellTokenToClueToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the cell token, find the corresponding across
		and down clues.

CALLED BY:	GLOBAL
PASS:		ax	- cell token
		dx	- engine token
		
RETURN:		bx	- across clue token
		cx	- down clue token

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMapCellTokenToClueToken	proc	near
	uses	si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI		; *ds:si = cell array

EC <	call	ECVerifyCellTokenType				>

	call	ChunkArrayElementToPtr	; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	mov	bx, ds:[di].CD_acrossClueToken
	mov	cx, ds:[di].CD_downClueToken

	EngineUnlockDX

	.leave
	ret
EngineMapCellTokenToClueToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetUserLetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the user entered letter for a cell.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- cell token
		bl	- letter

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Put the user letter into the cell array and clear the
	CF_EMPTY flag.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetUserLetter	proc	near
	uses	si,di,ds
	.enter

	Assert	EngineTokenType	dx
EC <	call	ECVerifyCellTokenType				>
EC <	call	ECVerifyUserLetter				>

	EngineGetCellArrayDSSI			; *ds:si = cell array	

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	mov	ds:[di].CD_userLetter, bl
	BitClr	ds:[di].CD_flags, CF_EMPTY
	BitClr	ds:[di].CD_flags, CF_WRONG

	EngineUnlockDX

	.leave
	ret
EngineSetUserLetter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetUserLetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the user entered letter for a cell.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- cell token
		
RETURN:		bl	- letter

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetUserLetter	proc	near
	uses	si,di,ds
	.enter

	Assert	EngineTokenType	dx
EC <	call	ECVerifyCellTokenType				>

	EngineGetCellArrayDSSI			; *ds:si = cell array	

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	mov	bl, ds:[di].CD_userLetter

	EngineUnlockDX

	.leave
	ret
EngineGetUserLetter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetCellFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the flags for a given cell.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- cell token
		
RETURN:		cl	- cell flags (CellFlags)
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetCellFlags	proc	near
	uses	si,di,ds
	.enter

	Assert	EngineTokenType	dx
EC <	call	ECVerifyCellTokenType				>

	EngineGetCellArrayDSSI			; *ds:si = cell array	

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	mov	cl, ds:[di].CD_flags

	EngineUnlockDX

	.leave
	ret
EngineGetCellFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetCellFlagsFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Far version of EngineGetCellFlags.

CALLED BY:	Global

PASS:		dx	- engine token
		ax	- cell token
		
RETURN:		cl	- cell flags (CellFlags)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetCellFlagsFar	proc	far
	.enter

	call	EngineGetCellFlags

	.leave
	ret
EngineGetCellFlagsFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetSolutionLetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the solution letter for a cell.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- cell token
		
RETURN:		bl	- letter

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetSolutionLetter	proc	near
	uses	si,di,ds
	.enter

	Assert	EngineTokenType	dx
EC <	call	ECVerifyCellTokenType				>

	EngineGetCellArrayDSSI			; *ds:si = cell array	

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	mov	bl, ds:[di].CD_solutionLetter

	EngineUnlockDX

	.leave
	ret
EngineGetSolutionLetter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetUserLetterHinted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the hinted flag for a cell.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- cell token
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetUserLetterHinted	proc	near
	uses	si,di,ds
	.enter

	Assert	EngineTokenType	dx
EC <	call	ECVerifyCellTokenType				>

	EngineGetCellArrayDSSI			; *ds:si = cell array	

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	BitSet	ds:[di].CD_flags, CF_HINTED

	EngineUnlockDX

	.leave
	ret
EngineSetUserLetterHinted	endp
if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetUserLetterVerified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the verified flag for a cell.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- cell token
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetUserLetterVerified	proc	near
	uses	si,di,ds
	.enter

	Assert	EngineTokenType	dx
EC <	call	ECVerifyCellTokenType				>

	EngineGetCellArrayDSSI			; *ds:si = cell array	

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	BitSet	ds:[di].CD_flags, CF_VERIFIED

	EngineUnlockDX

	.leave
	ret
EngineSetUserLetterVerified	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineClrUserLetterVerified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the CF_VERIFIED bit.

CALLED BY:	GLOBAL

PASS:		dx	- engine token
		ax	- cell token
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineClrUserLetterVerified	proc	near
	uses	si,di,ds
	.enter

	Assert	EngineTokenType	dx
	Assert	CellTokenType	ax

	EngineGetCellArrayDSSI			; *ds:si = cell array	

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	BitClr	ds:[di].CD_flags, CF_VERIFIED

EC <	push	ax						>
EC <	clr	ax						>
EC <	mov	al, ds:[di].CD_flags				>
EC <	Assert	CellFlags 	ax				>
EC <	pop	ax						>

	EngineUnlockDX
	.leave
	ret
EngineClrUserLetterVerified	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetCellEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the empty flag for a cell, and moves a space into
		the user letter.  Clears the wrong and hinted flags.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- cell token
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none
PSEUDO CODE/STRATEGY:
	Sets the letter to be a space and the CF_EMPTY flag.
	Clears the CF_HINTED AND CF_WRONG flags.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version
	PT	6/17/94		- Used Assert instead of calling EC routine.
				- Fatal error on error from chunk array.
				- Assert changes are valid.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetCellEmpty	proc	near
	uses	si,di,ds
	.enter

	Assert	EngineTokenType	dx
	Assert	CellTokenType	ax

	EngineGetCellArrayDSSI			; *ds:si = cell array

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	BitSet	ds:[di].CD_flags, CF_EMPTY
	mov	ds:[di].CD_userLetter, C_SPACE
	BitClr	ds:[di].CD_flags, CF_HINTED
	BitClr	ds:[di].CD_flags, CF_WRONG

EC <	push	ax						>
EC <	clr	ax						>
EC <	mov	al, ds:[di].CD_flags				>
EC <	Assert	CellFlags 	ax				>
EC <	pop	ax						>

	EngineUnlockDX

	.leave
	ret
EngineSetCellEmpty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMapClueTokenToFirstCellToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the clue token, finds the cell token to the
		first letter in the corresponding word.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- clue token
		bx	- direction (ACROSS or DOWN)
			- is also the offset of the clue header in the
			  cell block

RETURN:		bx	- first cell token
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMapClueTokenToFirstCellToken	proc	near
	uses	cx,si,di,ds
	.enter

	Assert	EngineTokenType	dx

	EngineGetClueHeaderArrayDSSI		; *ds:si - clue header array
						; bx - clue header handle

	call	ChunkArrayElementToPtr		; ds:di	- element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	mov	cx, ds:[di].CH_cellToken
	
	Assert	lmem	bx			
	call	MemUnlock		; unlock clue header block

	mov	bx, cx			; first cell token
	.leave
	ret
EngineMapClueTokenToFirstCellToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetPrevCellTokenInRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives the cell token of the cell before the given cell
		in the row.

CALLED BY:	GLOBAL
PASS:		ax	- cell token
		dx	- engine token

RETURN:		bx	- Prev cell token
			or ENGINE_GRID_EDGE if given cell was the first
			cell in the row
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Cell is on the edge if (cell token) mod (columns) = 0,
		so ENGINE_GRID_EDGE is returned.
	Otherwise, the previous cell token in the row is just
	(the given cell token) - 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetPrevCellTokenInRowFar	proc	far
	call	EngineGetPrevCellTokenInRow
	ret
EngineGetPrevCellTokenInRowFar	endp

EngineGetPrevCellTokenInRow	proc	near
	uses	ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellSegmentDS			; ds - cell block segment
	call	EngineGetPrevCellTokenInRowLocked	; bx - prev
							;    cell token
	EngineUnlockDX

	.leave
	ret
EngineGetPrevCellTokenInRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetPrevCellTokenInRowLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives the cell token of the cell before the given cell
		in the row.

CALLED BY:	ENGINE INTERNAL
PASS:		ax	- cell token
		ds	- cell data segment

RETURN:		bx	- Prev cell token
			or ENGINE_GRID_EDGE if given cell was the first
			cell in the row
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Cell is on the edge if (cell token) mod (columns) = 0,
		so ENGINE_GRID_EDGE is returned.
	Otherwise, the previous cell token in the row is just
	(the given cell token) - 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetPrevCellTokenInRowLocked	proc	near
	uses	ax
	.enter

EC <	call	ECVerifyCellTokenType				>

	push	ax				; cell token
	mov	bl, ds:[CBH_columns]

	; See if cell token is on the edge	
	div	bl		; ah = (cell token) mod (columns)
	tst	ah			
	jz	edge

	; not on edge
	pop	ax				; cell token
	mov	bx, ax				; cell token
	dec	bx				; Prev cell token
done:
	.leave
	ret
edge:
	pop	ax				; cell token
	mov	bx, ENGINE_GRID_EDGE
	jmp	done

EngineGetPrevCellTokenInRowLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetNextCellTokenInRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives the cell token of the cell after the given cell
		in the row.

CALLED BY:	GLOBAL
PASS:		ax	- cell token
		dx	- engine token

RETURN:		bx	- next cell token
			or ENGINE_GRID_EDGE if given cell was the last
			cell in the row
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Cell is on the edge if (cell token) mod (columns) = columns-1
		so ENGINE_GRID_EDGE is returned.
	Otherwise, the next cell token in the row is just
	(the given cell token) + 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetNextCellTokenInRowFar	proc	far
	call	EngineGetNextCellTokenInRow
	ret
EngineGetNextCellTokenInRowFar	endp


EngineGetNextCellTokenInRow	proc	near
	uses	ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellSegmentDS			; ds - cell block segment
	call	EngineGetNextCellTokenInRowLocked	; bx - next
							;    cell token
	EngineUnlockDX

	.leave
	ret
EngineGetNextCellTokenInRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetNextCellTokenInRowLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives the cell token of the cell after the given cell
		in the row.

CALLED BY:	ENGINE INTERNAL
PASS:		ax	- cell token
		ds	- cell data segment

RETURN:		bx	- next cell token
			or ENGINE_GRID_EDGE if given cell was the last
			cell in the row

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Cell is on the edge if (cell token) mod (columns) = columns-1
		so ENGINE_GRID_EDGE is returned.
	Otherwise, the next cell token in the row is just
	(the given cell token) + 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetNextCellTokenInRowLocked	proc	near
	uses	ax
	.enter

EC <	call	ECVerifyCellTokenType				>
	
	mov	bl, ds:[CBH_columns]
	
	push	ax		; cell token
	div	bl		; ah - (cell token) mod columns
	clr	bh
	dec	bl		; columns - 1
	cmp	ah, bl		; ah - (cell token) mod columns,
				;		 columns - 1
	je	edge

	; not on edge
	pop	ax				; cell token
	mov	bx, ax				; cell token
	inc	bx				; next cell token
done:
	.leave
	ret
edge:
	pop	ax				; cell token
	mov	bx, ENGINE_GRID_EDGE
	jmp	done

EngineGetNextCellTokenInRowLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetPrevCellTokenInColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives the cell token of the cell before the given cell
		in the column.

CALLED BY:	
PASS:		ax	- cell token
		dx	- engine token

RETURN:		bx	- Prev cell token
			or ENGINE_GRID_EDGE if given cell was the first
			cell in the column

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Cell is on the edge if (cell token) < (columns)
		so ENGINE_GRID_EDGE is returned.
	Otherwise, the prev cell token in the column is just
	(the given cell token) - columns.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetNextCellTokenInColumnFar	proc	far
	call	EngineGetNextCellTokenInColumn
	ret
EngineGetNextCellTokenInColumnFar	endp

EngineGetPrevCellTokenInColumn	proc	near
	uses	ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellSegmentDS			; ds - cell block segment
	call	EngineGetPrevCellTokenInColumnLocked	; bx - prev
							;   cell token
	EngineUnlockDX
	
	.leave
	ret
EngineGetPrevCellTokenInColumn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetPrevCellTokenInColumnLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives the cell token of the cell before the given cell
		in the column.

CALLED BY:	ENGINE INTERNAL
PASS:		ax	- cell token
		ds	- cell data segment

RETURN:		bx	- Prev cell token
			or ENGINE_GRID_EDGE if given cell was the first
			cell in the column

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Cell is on the edge if (cell token) < (columns)
		so ENGINE_GRID_EDGE is returned.
	Otherwise, the prev cell token in the column is just
	(the given cell token) - columns.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetPrevCellTokenInColumnLocked	proc	near
	uses	cx
	.enter

EC <	call	ECVerifyCellTokenType				>

	clr	cx
	mov	cl, ds:[CBH_columns]
	cmp	ax, cx				; cell token, columns
	jl	edge

	; not on edge
	mov	bx, ax				; cell token
	sub	bx, cx				; Prev cell token
done:
	.leave
	ret
edge:
	mov	bx, ENGINE_GRID_EDGE
	jmp	done
EngineGetPrevCellTokenInColumnLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetNextCellTokenInColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives the cell token of the cell after the given cell
		in the column.

CALLED BY:	GLOBAL
PASS:		ax	- cell token
		dx	- engine token

RETURN:		bx	- next cell token
			or ENGINE_GRID_EDGE if given cell was the last
			cell in the column

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Cell is on the edge if 	cell token >= [(rows-1) * columns]
		so ENGINE_GRID_EDGE is returned.
	Otherwise, the next cell token in the column is just
	(the given cell token) + columns.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetNextCellTokenInColumn	proc	near
	uses	ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellSegmentDS			; ds - cell block segment
	call	EngineGetNextCellTokenInColumnLocked	; bx - next
							;   cell token
	EngineUnlockDX

	.leave
	ret
EngineGetNextCellTokenInColumn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetNextCellTokenInColumnLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives the cell token of the cell after the given cell
		in the column.

CALLED BY:	ENGINE INTERNAL
PASS:		ax	- cell token
		ds	- cell data segment

RETURN:		bx	- next cell token
			or ENGINE_GRID_EDGE if given cell was the last
			cell in the column

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Cell is on the edge if 	cell token >= [(rows-1) * columns]
		so ENGINE_GRID_EDGE is returned.
	Otherwise, the next cell token in the column is just
	(the given cell token) + columns.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetNextCellTokenInColumnLocked	proc	near
	uses	cx
	.enter

EC <	call	ECVerifyCellTokenType				>

	push	ax				; cell token		

	clr	ax
	mov	al, ds:[CBH_rows]
	dec	al				; rows-1
	mul	{byte} ds:[CBH_columns]		; (rows-1) * columns
	
	mov	bx, ax				; (rows-1) * columns
	pop	ax				; cell token
	cmp	ax, bx				; cell token,
						;   (rows-1) * columns
	jge	edge

	; not on edge
	clr	cx
	mov	cl, ds:[CBH_columns]
	mov	bx, ax				; cell token
	add	bx, cx				; next cell token
done:
	.leave
	ret
edge:
	mov	bx, ENGINE_GRID_EDGE
	jmp	done

EngineGetNextCellTokenInColumnLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetOffsetOfSelectedCellInSelectedWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the offset of the selected cell within the
		selected word.
		
CALLED BY:	GLOBAL	(FileWriteSelectedWordAndCellData)
PASS:		ax	- first cell token in selected word
		cx	- direction of selected word
		dx	- engine token

RETURN:		al	- offset of selected cell within selected word
DESTROYED:	nothing (ax used for return value)
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetOffsetOfSelectedCellInSelectedWord	proc	far
	uses	bx,cx,si,di,bp,ds
	.enter
	
	Assert	EngineTokenType	dx
	mov	bp, ax			; first cell token in selected word

	; set the procedure to call (depending on the direction) when 
	; looking for the next cell token

	cmp	cx, ACROSS
	jne	downDir
	mov	cx, offset EngineGetNextCellTokenInRowLocked
	jmp	procSet
downDir:
	mov	cx, offset EngineGetNextCellTokenInColumnLocked
procSet:
	EngineGetCellSegmentDS		; ds - cell block segment

	mov	bx, handle Board	; single-launchable
	mov	si, offset Board
	mov	di, mask MF_CALL
	mov	ax, MSG_CWORD_BOARD_GET_SELECTED_CELL_TOKEN
	call	ObjMessage		; ax - cell token

	; Initial offset of selected cell token in word.
	; This will be used to count what the real offset is.
	clr	si
	xchg	ax, bp
		; ax - current cell token in word
		; bp - selected cell token
newOffset:
	cmp	ax, bp		; ax - current cell token in word
				; bp - selected cell token
	je	offsetFound
	call	cx		; bx - next cell token
	Assert	ne	bx, ENGINE_GRID_EDGE
	mov	ax, bx		; new current cell token
	inc	si		; new offset
	jmp	newOffset
	
offsetFound:
	EngineUnlockDX
	mov	ax, si		; offset of selected cell
	Assert	e	ah, 0

	.leave
	ret
EngineGetOffsetOfSelectedCellInSelectedWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetCellTokenGivenOffsetAndDirection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the cell token of the cell at the given offset
		and direction from the given cell token.

CALLED BY:	GLOBAL - the File Module
PASS:		dx	- engine token
		ax	- cell token to base offset on
		bx	- direction (ACROSS or DOWN)
		cl	- offset of cell to look for

RETURN:		ax	- cell token of cell which is at the offset
				from the given cell token
DESTROYED:	ax used for return value
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetCellTokenGivenOffsetAndDirection	proc	far
	uses	bx,cx,dx,ds
	.enter

	Assert	EngineTokenType	dx

	; if the offset is 0, nothing needs to be done.
	tst	cl
	jz	done

	EngineGetCellSegmentDS			; ds - cell segment
	push	dx				; engine token
	push	ax				; base cell token

	cmp	bx, ACROSS
	jne	downDir

	mov	al, ds:[CBH_columns]
	mov	dx, offset EngineGetNextCellTokenInRowLocked
	jmp	boundarySet

downDir:
	mov	al, ds:[CBH_rows]
	mov	dx, offset EngineGetNextCellTokenInColumnLocked

boundarySet:
	clr	ch			; cx - the offset for the loop
	Assert	l	cx, ax		; offset should be less than
					; number of columns/rows
	
	pop	ax			; base cell token
	Assert	g	cx, 0

	; Increment the cell token one by one to get the next
	; cell token until the given offset is reached.
theLoop:
	call	dx			; bx -  the next cell token
	mov	ax, bx			; current cell token to look at
	Assert	ne	ax, ENGINE_GRID_EDGE
	loop	theLoop

	pop	dx			; engine token
	EngineUnlockDX	
done:
	.leave
	ret
EngineGetCellTokenGivenOffsetAndDirection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetCellNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the number in the given cell.

CALLED BY:	GLOBAL
PASS:		ax	- cell token
		dx	- engine token

RETURN:		cl	- number
			  or ENGINE_NO_NUMBER if the cell has no number.

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetCellNumber	proc	near
	uses	si,di,ds
	.enter

	Assert	EngineTokenType	dx
EC <	call	ECVerifyCellTokenType				>

	EngineGetCellArrayDSSI			; *ds:si = cell array

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	; see if the cell really has a nubmer
	test	ds:[di].CD_flags, mask CF_NUMBER
	jz	noNumber

	mov	cl, ds:[di].CD_number

	EngineUnlockDX
finish:
	.leave
	ret
noNumber:
	mov	cl, ENGINE_NO_NUMBER
	jmp	finish
EngineGetCellNumber	endp

EngineGetCellNumberFAR	proc	far
	call	EngineGetCellNumber
	ret
EngineGetCellNumberFAR	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetFirstAndLastCellsInWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the first and last cell in a word given any cell
		and the direction.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- CellTokenType
		cx	- direction (ACROSS or DOWN)

RETURN:		ax	- first cell token
		bx	- last cell token
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetFirstAndLastCellsInWord	proc	near
	uses	cx,dx,si,bp,ds
	.enter

	Assert	EngineTokenType	dx
EC <	call	ECVerifyCellTokenType				>

	EngineGetCellArrayDSSI			; *ds:si - cell array
	push	dx				; engine token

	; a passed cell token that is a hole is not a valid argument
EC <	push	di						>
EC <	call	ChunkArrayElementToPtr		; ds:di - element  >
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
EC <	test	ds:[di].CD_flags, mask CF_HOLE			>
EC <	ERROR_NZ	ENGINE_HOLE_IS_NOT_IN_WORD		>
EC <	pop	di						>

	mov	bp, ax			; passed cell token

	cmp	cx, DOWN
	je	down
	
	mov	cx, offset EngineGetPrevCellTokenInRowLocked
	mov	dx, offset EngineGetNextCellTokenInRowLocked
	jmp	argsSet
down:	
	mov	cx, offset EngineGetPrevCellTokenInColumnLocked
	mov	dx, offset EngineGetNextCellTokenInColumnLocked
argsSet:
	call	EngineGetFirstAndLastCellsInWordLocked
			; ax - first cell token
			; bx - last cell token
	pop	dx				; engine token
	EngineUnlockDX

	.leave
	ret
EngineGetFirstAndLastCellsInWord	endp

EngineGetFirstAndLastCellsInWordFAR	proc	far
	call	EngineGetFirstAndLastCellsInWord
	ret
EngineGetFirstAndLastCellsInWordFAR	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetFirstAndLastCellsInWordLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first and last cells in the word containing 
		the given cell token.

CALLED BY:	ENGINE INTERNAL	(EngineGetFirstAndLastCellsInWord)
PASS:		bp	- passed (validated) cell token
		*ds:si	- Cell Array
		cx	- offset of funtion to call for finding the
			  previous cell token.  Either:
			  offset EngineGetPrevCellTokenInRowLocked or
			  offset EngineGetPrevCellTokenInColumnLocked
	
		dx	- offset of function to call for finding the
			  next cell token.  Either:
			  offset EngineGetNextCellTokenInRowLocked or
			  offset EngineGetNextCellTokenInColumnLocked	

RETURN:		ax	- first cell token
		bx	- last cell token
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	To get the first cell, just keep getting the previous cell
	till a hole, non-existent, or ENGINE_GRID_EDGE is hit.

	To get the last cell, just keep getting the previous cell
	till a hole, non-existent, or ENGINE_GRID_EDGE is hit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetFirstAndLastCellsInWordLocked	proc	near
	uses	cx,di
	.enter

	mov	bx, bp					; passed cell

	; FIND THE FIRST CELL IN THE WORD
firstCell:
	mov	ax, bx					; current cell
	; get the previous cell
	call	cx					; bx - prev cell
	cmp	bx, ENGINE_GRID_EDGE
	je	firstDone
	xchg	ax, bx
		; ax - prev cell
		; bx - current cell that was not a hole or edge

	call	ChunkArrayElementToPtr		; ds:di - prev element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	xchg	ax, bx
		; ax - current cell that was not a hole or edge
		; bx - prev cell

	; If a hole or a non-existent cell is hit, 
	; the first cell of the word is found.
	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	firstDone
	test	ds:[di].CD_flags, mask CF_NON_EXISTENT
	jz	firstCell

firstDone:
	mov	cx, ax				; first cell token
	mov	bx, bp				; passed cell

	; FIND THE LAST CELL IN THE WORD
lastCell:
	mov	ax, bx				; current cell
	; get the next cell
	call	dx				; bx - last cell
	cmp	bx, ENGINE_GRID_EDGE
	je	lastDone
	xchg	ax, bx
		; ax - next cell
		; bx - current cell that was not a hole or edge

	call	ChunkArrayElementToPtr		; ds:di - next element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	xchg	ax, bx
		; ax - current cell that was not a hole or edge
		; bx - next cell

	; If a hole or a non-existent cell is hit, 
	; the last cell of the word is found.
	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	lastDone
	test	ds:[di].CD_flags, mask CF_NON_EXISTENT
	jz	lastCell

lastDone:
	mov	bx, ax				; last cell token
	mov	ax, cx				; first cell token

	.leave
	ret
EngineGetFirstAndLastCellsInWordLocked	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMapClueToFirstEmptyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the first empty cell in the word corresponding
		to the clue given.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- clue token
		bx	- direction (ACROSS or DOWN)

RETURN:		bx	- cell token of first empty cell or 
			  ENGINE_NO_EMPTY_CELL if no cells in the word
			  are empty.
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMapClueToFirstEmptyCell	proc	near
	uses	ax,cx,si,di,ds
	.enter

	Assert	EngineTokenType	dx

EC <	xchg	bx, cx				; direction	>
EC <	call	ECVerifyClueTokenType				>
EC <	xchg	bx, cx				; direction	>

	; Set up the procedure to call to get the next cell
	; in the word
	cmp	bx, ACROSS
	jne	downDir
	mov	cx, offset EngineGetNextCellTokenInRowLocked
	jmp	procSet
downDir:
	mov	cx, offset EngineGetNextCellTokenInColumnLocked
procSet:

	EngineGetClueHeaderArrayDSSI	; bx - clue header handle
					; *ds:si - clue header array

	call	ChunkArrayElementToPtr	; ds:di - element
	mov	ax, ds:[di].CH_cellToken	; first cell token of word
	Assert	lmem	bx
	call	MemUnlock

	EngineGetCellArrayDSSI		; *ds:si - cell data array
	mov	bx, ax			; first cell token in word
next:
	; See if a grid edge, a hole, or a non-existent cell was hit.
	; If yes, then all cells in word have a user letter in it.
	cmp	ax, ENGINE_GRID_EDGE
	je	noEmptyCell

	call	ChunkArrayElementToPtr	; ds:di - element

	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	noEmptyCell
	test	ds:[di].CD_flags, mask CF_NON_EXISTENT
	jnz	noEmptyCell

	;  If the cell is empty, we are done.
	test	ds:[di].CD_flags, mask CF_EMPTY
	jnz	finish
	call	cx			; bx - next cell token
	mov	ax, bx			; next cell token
	jmp	next
		
finish:
	EngineUnlockDX
	.leave
	ret
	
noEmptyCell:
	mov	bx, ENGINE_NO_EMPTY_CELL
	jmp	finish
EngineMapClueToFirstEmptyCell	endp






;----------------------------------------------------------------------------
;		ENGINE Clean Up
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineCleanUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up all the Engine's allocated blocks.

CALLED BY:	GLOBAL
PASS:		dx	- engine token

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineCleanUp	proc	far
	uses	bx
	.enter

	tst	dx				; see if no engine token
	jz	done

	Assert	EngineTokenType	dx
	call	EngineCleanClueHeaders

	mov	bx, dx				; engine token
	call	MemFree
done:
	.leave
	ret
EngineCleanUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineCleanClueHeaders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up clue header blocks.

CALLED BY:	ENGINE INTERNAL	(EngineCleanUp)
PASS:		dx	- engine token

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineCleanClueHeaders	proc	near
	uses	bx,ds
	.enter

	Assert	EngineTokenType	dx

	; clean the ACROSS clue header
	mov	bx, ACROSS
	EngineGetClueHeaderSegmentDS		; ds - clue header segment
						; bx - clue header handle
	call	EngineCleanClueDataBlocks
	call	MemFree

	; clean the DOWN clue header
	mov	bx, DOWN
	EngineGetClueHeaderSegmentDS		; ds - clue header segment
						; bx - clue header handle
	call	EngineCleanClueDataBlocks
	call	MemFree

	.leave
	ret
EngineCleanClueHeaders	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineCleanClueDataBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free all Data Blocks referenced in given clue header
		segment.

CALLED BY:	ENGINE INTERNAL	(EngineCleanClueHeaders)
PASS:		ds	- clue header segment

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Go through each element in the clue header chunk array and
	free the block its data is in.  If the block is already freed
	(for ex. by a previous element), just ignore it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineCleanClueDataBlocks	proc	near
	uses	bx,cx,si,di
	.enter
	
	mov	si, ds:[CHBH_clueHeaderChunkHandle]
	mov	cx, -1			; initial clue data block
	mov	bx, cs
	mov	di, offset EngineFreeDataBlockCallback
	call	ChunkArrayEnum
	
	.leave
	ret
EngineCleanClueDataBlocks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineFreeDataBlockCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	free the data block for the given element if not
		already freed.
		
CALLED BY:	ENGINE INTERNAL
			(ChunkArrayEnum in EngineCleanClueDataBlocks)

PASS:		cx	- last data block
		*ds:si 	- array
		ds:di 	- array element being enumerated

RETURN:		cx	- last data block (possibly updated)
		CF	- set to end enumeration
			- clear to continue
			(always clear)

DESTROYED:	bx, si, di (by ChunkArrayEnum)
SIDE EFFECTS:	must be a _far_ procedure since it's a callback proc.

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineFreeDataBlockCallback	proc	far
	uses	bx
	.enter

	cmp	cx, ds:[di].CH_textClueDataToken.CDT_blockHandle
	je	finish

	; update the last data block seen
	mov	cx, ds:[di].CH_textClueDataToken.CDT_blockHandle
	mov	bx, cx				; block handle
	call	MemFree
finish:
	clc

	.leave
	ret
EngineFreeDataBlockCallback	endp



CwordCode	ends



;----------------------------------------------------------------------------
;			CLUE ACCESS
;----------------------------------------------------------------------------
CwordClueListCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetFirstClueTokenAcross
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the clue token of the first across clue.

CALLED BY:	GLOBAL	
PASS:		dx	- engine token

RETURN:		bx	- first across clue token

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetFirstClueTokenAcross	proc	near
	.enter

	Assert	EngineTokenType	dx
	clr	bx

	.leave
	ret
EngineGetFirstClueTokenAcross	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetFirstClueTokenDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the clue token of the first Down clue.

CALLED BY:	GLOBAL
PASS:		dx	- engine token

RETURN:		bx	- first Down clue token

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetFirstClueTokenDown	proc	near
	.enter

	Assert	EngineTokenType	dx
	clr	bx

	.leave
	ret
EngineGetFirstClueTokenDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetNextClueTokenAcross
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the clue token following the given across clue
		token.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- clue token

RETURN:		bx	- next clue across token
				or ENGINE_LAST_CLUE if given clue
				was the last clue in the list.

DESTROYED:	nothing	(bx used for return value)
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetNextClueTokenAcross	proc	near
	.enter

	Assert	EngineTokenType	dx
	mov	bx, ACROSS
	call	EngineGetNextClueToken		; bx - next clue token

	.leave
	ret
EngineGetNextClueTokenAcross	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetNextClueTokenDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the clue token following the given down clue
		token.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- clue token

RETURN:		bx	- next clue down token
				or ENGINE_LAST_CLUE if given clue
				was the last clue in the list.

DESTROYED:	nothing (bx used for return value)
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetNextClueTokenDown	proc	near
	.enter

	Assert	EngineTokenType	dx
	mov	bx, DOWN
	call	EngineGetNextClueToken		; bx - next clue token

	.leave
	ret
EngineGetNextClueTokenDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetNextClueToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next clue after the given one.

CALLED BY:	ENGINE INTERNAL	(EngineGetNextClueTokenAcross and
				EngineGetNextClueTokenDown)
PASS:		dx	- engine token
		ax	- clue token
		bx	- direction (ACROSS or DOWN) 
			  Also, the constants are the clue header
			  block handle offset in the cell block header.

RETURN:		bx	- next clue token
				or ENGINE_LAST_CLUE if given clue
				was the last clue in the list.

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY: 
	Increment the clue token.  If the clue token refers to the
	last element in the clue header array, return ENGINE_LAST_CLUE.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetNextClueToken	proc	near
	uses	ax,cx,si,ds
	.enter

	Assert	EngineTokenType	dx
EC <	xchg	cx, bx						>
EC <	call	ECVerifyClueTokenType				>
EC <	xchg	cx, bx						>

	EngineGetClueHeaderArrayDSSI	; *ds:si - clue header array
	push	bx			; clue header block handle

	; Get the maximum index.  If this index equals the clue token,
	; the given clue token is the last one.  Return 
	; ENGINE_LAST_CLUE in this case, otherwise increment the clue
	; token.
	call	ChunkArrayGetCount	; cx - number of elements
		; convert number of elements to maximum index:
		;      (# elements - 1)
	dec	cx			; max index
	cmp	ax, cx			; clue token, # elems
	jge	lastClue
	
	; not the last clue, ok to increment clue token.
	mov	bx, ax			; clue token
	inc	bx			; next clue token
done:
	pop	cx			; clue header block handle

	xchg	bx, cx	
			; cx - clue token, bx - clue header block handle
	Assert	lmem	bx
	call	MemUnlock
	xchg	bx, cx	
			; bx - clue token, cx - clue header block handle

	.leave
	ret

lastClue:
	mov	bx, ENGINE_LAST_CLUE
	jmp	done	
EngineGetNextClueToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetClueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a buffer with the text of a given clue.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- clue token
		cx	- direction of clue (ACROSS or DOWN)
			  Also the offset into the cell block header
			  of the clue handle.
		es:di	- pointer to buffer to fill
			  Buffer must be of length 
				ENGINE_MAX_LENGTH_FOR_CLUE_TEXT
		
RETURN:		cx	- number of bytes copied into buffer
		es:di	- filled buffer

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetClueText	proc	near
bufferOffset		local	word	push	di
clueHeaderHandle	local	hptr
dataToken		local	ClueDataToken
	uses	ax,bx,dx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	mov	bx, cx					; direction
EC <	call	ECVerifyClueTokenType				>

	; Find the Clue in the Clue Header Array	
	EngineGetClueHeaderArrayDSSI			; *ds:si -
							;   clue header
							;   array
							; bx - clue
							;   header handle
	mov	ss:[clueHeaderHandle], bx

EC < 	call	ECCheckChunkArray				>

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	
	; Fill the local structure dataToken with the element's
	; data info - block handle and element where to find the
	; actual clue text
	mov	ax, ds:[di].CH_textClueDataToken.CDT_blockHandle
	mov	ss:[dataToken].CDT_blockHandle, ax
	mov	ax, ds:[di].CH_textClueDataToken.CDT_element
	mov	ss:[dataToken].CDT_element, ax

	mov	bx, ss:[clueHeaderHandle]
	call	MemUnlock			; unlock the clue
						; header block
	; Lock the clue data block and get the element in the chunk
	; array within that block.
	mov	bx, ss:[dataToken].CDT_blockHandle
	call	MemLock				; ax - segment

	mov	ds, ax				; clue data segment
	mov	si, ds:[CDBH_clueDataChunkHandle]	; *ds:si - array
	mov	ax, ss:[dataToken].CDT_element
	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	
	; copy the clue data into the given buffer
	mov	dx, ds:[di].CD_size
EC <	cmp	dx, ENGINE_MAX_LENGTH_FOR_CLUE_TEXT			>
EC <	ERROR_G	ENGINE_CLUE_TEXT_WILL_NOT_FIT_IN_BUFFER			>

	lea	si, ds:[di].CD_data				; element
	mov	di, ss:[bufferOffset]
		; es:di - buffer, ds:si - clue data text
	mov	cx, dx				; size of text
	
	; optimization in reading in all text
	shr	cx
	jnc	evenCount
	movsb
evenCount:
	rep	movsw
	
	mov	cx, dx				; size of text

	; unlock the data block since retrieving text is done
	mov	bx, ss:[dataToken].CDT_blockHandle
	call	MemUnlock

	.leave
	ret
EngineGetClueText	endp


CwordClueListCode	ends




CwordBoardBoundsCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetPuzzleDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of rows and columns in the crossword
		grid.

CALLED BY:	GLOBAL
PASS:		dx	- engine token

RETURN:		al	- number of rows
		cl	- number of columns

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetPuzzleDimensions	proc	far
	uses	ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellSegmentDS			; ds - cell block segment
	mov	al, {byte} ds:[CBH_rows]
	mov	cl, {byte} ds:[CBH_columns]
	EngineUnlockDX

	.leave
	ret
EngineGetPuzzleDimensions	endp


CwordBoardBoundsCode	ends


CwordVictoryCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineVerifyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the CF_WRONG flag in a cell if the user letter
		does not match the solution letter

CALLED BY:	UTILITY

PASS:		
		dx - engine token
		ax - cell token

RETURN:		
		stc - cell is wrong
		clc - cell is not wrong

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineVerifyCell		proc	far
	uses	ax,ds,si,di
	.enter

	Assert	EngineTokenType	dx
EC <	call	ECVerifyCellTokenType				>

	EngineGetCellArrayDSSI			; *ds:si = array

	call	ChunkArrayElementToPtr
	call	EngineVerifyCellCallback

	test	ds:[di].CD_flags, mask CF_WRONG
	jnz	itsWrong
	clc
unlock:
	EngineUnlockDX

	.leave
	ret

itsWrong:
	stc
	jmp	unlock

EngineVerifyCell		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineVerifyAllCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify all non-empty cells.

CALLED BY:	GLOBAL	(Board module)

PASS:		dx	- engine token

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineVerifyAllCells	proc	far
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si = array

	mov	bx, cs
	mov	di, offset EngineVerifyCellCallback
	call	ChunkArrayEnum
	
	EngineUnlockDX

	.leave
	ret
EngineVerifyAllCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineVerifyCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies entire puzzle for user.

CALLED BY:	ENGINE INTERNAL (ChunkArrayEnum from EngineVerifyAllCells)
PASS:		*ds:si	- array
		ds:di	- enumerated element

RETURN:		CF	- always clear
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	If a cell exists, is non-hole, and non-empty, check to see
	if the user letter matches the solution letter.  If it doesn't
	match, set the CF_WRONG flag.

	Must be a far call.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineVerifyCellCallback	proc	far
	uses	ax
	.enter

	test	ds:[di].CD_flags, mask CF_HOLE or \
			mask CF_NON_EXISTENT or \
			mask CF_EMPTY
	jnz	done

	mov	al, ds:[di].CD_userLetter
	cmp	al, {byte}ds:[di].CD_solutionLetter
	je	done

	BitSet	ds:[di].CD_flags, CF_WRONG	; flag the user letter
						; is wrong
done:
	clc
	.leave
	ret
EngineVerifyCellCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineClearAllCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear all cells.

CALLED BY:	GLOBAL	(Board module)

PASS:		dx	- engine token

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineClearAllCells	proc	far
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si = array

	mov	bx, cs
	mov	di, offset EngineClearCellCallback
	call	ChunkArrayEnum
	
	EngineUnlockDX

	.leave
	ret
EngineClearAllCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineClearCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the cell out

CALLED BY:	ENGINE INTERNAL (ChunkArrayEnum from EngineClearAllCells)
PASS:		*ds:si	- array
		ds:di	- enumerated element

RETURN:		CF	- always clear
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Must be a far call.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineClearCellCallback	proc	far
	uses	ax
	.enter

	test	ds:[di].CD_flags, mask CF_NON_EXISTENT or \
				mask CF_HOLE or \
				mask CF_EMPTY
	jnz	done

	andnf	ds:[di].CD_flags, not (mask CF_HINTED or mask CF_WRONG)
	ornf	ds:[di].CD_flags, mask CF_EMPTY
	mov	ds:[di].CD_userLetter, C_SPACE

done:
	clc
	.leave
	ret
EngineClearCellCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineClearWrongCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear all cells that are wrong

CALLED BY:	GLOBAL	(Board module)

PASS:		dx	- engine token

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineClearWrongCells	proc	far
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si = array

	mov	bx, cs
	mov	di, offset EngineClearWrongCellCallback
	call	ChunkArrayEnum
	
	EngineUnlockDX

	.leave
	ret
EngineClearWrongCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineClearWrongCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the cell out if it is wrong

CALLED BY:	ENGINE INTERNAL (ChunkArrayEnum from EngineClearWrongCells)
PASS:		*ds:si	- array
		ds:di	- enumerated element

RETURN:		CF	- always clear
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Must be a far call.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineClearWrongCellCallback	proc	far
	uses	ax
	.enter

	test	ds:[di].CD_flags, mask CF_NON_EXISTENT or \
				mask CF_HOLE or \
				mask CF_EMPTY 
	jnz	done

	test	ds:[di].CD_flags, mask CF_WRONG
	jz	done

	andnf	ds:[di].CD_flags, not mask CF_WRONG
	ornf	ds:[di].CD_flags, mask CF_EMPTY
	mov	ds:[di].CD_userLetter, C_SPACE

done:
	clc
	.leave
	ret
EngineClearWrongCellCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineCheckForAllCellsFilled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if no cells are empty

CALLED BY:	GLOBAL	(Board module)

PASS:		dx	- engine token

RETURN:		
		clc - all cells filled
		stc - all cells not filled in

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineCheckForAllCellsFilled	proc	far
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si = array

	mov	bx, cs
	mov	di, offset EngineCheckForAllCellsFilledCallback
	call	ChunkArrayEnum
	
	EngineUnlockDX

	.leave
	ret
EngineCheckForAllCellsFilled	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineCheckForAllCellsFilledCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if cell is not empty

CALLED BY:	ENGINE INTERNAL 
			(ChunkArrayEnum from EngineCheckForAllCellsFilled)
PASS:		*ds:si	- array
		ds:di	- enumerated element

RETURN:		clc - cell not empty
		stc - cell empty

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineCheckForAllCellsFilledCallback	proc	far
	.enter

	test	ds:[di].CD_flags, mask CF_HOLE or mask CF_NON_EXISTENT
	jnz	okCell

	test	ds:[di].CD_flags, mask CF_EMPTY
	jnz	empty
okCell:
	clc
done:
	.leave
	ret

empty:
	stc
	jmp	done	

EngineCheckForAllCellsFilledCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineCheckForAllCellsCorrect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if all cells have letters that are either
		not wrong or hinted

CALLED BY:	GLOBAL	(Board module)

PASS:		dx	- engine token

RETURN:		
		clc - all cells correct
		stc - all cells not correct

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineCheckForAllCellsCorrect	proc	far
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si = array

	mov	bx, cs
	mov	di, offset EngineCheckForAllCellsCorrectCallback
	call	ChunkArrayEnum
	
	EngineUnlockDX

	.leave
	ret
EngineCheckForAllCellsCorrect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineCheckForAllCellsCorrectCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if cell is not empty, and the user letter
		equals the solution letter

CALLED BY:	ENGINE INTERNAL 
			(ChunkArrayEnum from EngineCheckForAllCellsCorrect)
PASS:		*ds:si	- array
		ds:di	- enumerated element

RETURN:		clc - cell correct
		stc - cell not correct

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineCheckForAllCellsCorrectCallback	proc	far
	uses	ax
	.enter

	test	ds:[di].CD_flags, mask CF_HOLE or mask CF_NON_EXISTENT
	jnz	okCell

	test	ds:[di].CD_flags, mask CF_EMPTY
	jnz	bad

	mov	al, ds:[di].CD_solutionLetter
	cmp	al,ds:[di].CD_userLetter
	jne	bad

okCell:
	clc
done:
	.leave
	ret

bad:
	stc
	jmp	done	

EngineCheckForAllCellsCorrectCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineCheckForAllCellsEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if all cells are empty

CALLED BY:	GLOBAL	(Board module)

PASS:		dx	- engine token

RETURN:		
		clc - all cells correct
		stc - all cells not correct

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineCheckForAllCellsEmpty	proc	far
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si = array

	mov	bx, cs
	mov	di, offset EngineCheckForAllCellsEmptyCallback
	call	ChunkArrayEnum
	
	EngineUnlockDX

	.leave
	ret
EngineCheckForAllCellsEmpty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineCheckForAllCellsEmptyCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if cell is empty

CALLED BY:	ENGINE INTERNAL 
			(ChunkArrayEnum from EngineCheckForAllCellsEmpty)
PASS:		*ds:si	- array
		ds:di	- enumerated element

RETURN:		clc - cell correct
		stc - cell not correct

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineCheckForAllCellsEmptyCallback	proc	far
	.enter

	test	ds:[di].CD_flags, mask CF_HOLE or \
				mask CF_NON_EXISTENT or \
				mask CF_EMPTY
	jz	bad

	clc
done:
	.leave
	ret

bad:
	stc
	jmp	done	

EngineCheckForAllCellsEmptyCallback	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineFindFirstWrongCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find first wrong cell in puzzle

CALLED BY:	GLOBAL	(Board module)

PASS:		dx	- engine token

RETURN:		
		clc - didn't find a wrong cell
		stc - found a wrong cell
			ax - cell token

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineFindFirstWrongCell	proc	far
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si = array

	mov	bx, cs
	mov	di, offset EngineFindFirstWrongCellCallback
	call	ChunkArrayEnum
	
	EngineUnlockDX

	.leave
	ret
EngineFindFirstWrongCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineFindFirstWrongCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if cell is wrong

CALLED BY:	ENGINE INTERNAL 
			(ChunkArrayEnum from EngineFindFirstWrongCell)
PASS:		*ds:si	- array
		ds:di	- enumerated element

RETURN:		
		clc - didn't find a wrong cell
		stc - found a wrong cell
			ax - cell token


DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineFindFirstWrongCellCallback	proc	far
	.enter

	test	ds:[di].CD_flags, mask CF_WRONG
	jnz	itsWrong

	clc
done:
	.leave
	ret

itsWrong::
	call	ChunkArrayPtrToElement
	stc
	jmp	done	

EngineFindFirstWrongCellCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineFindFirstEmptyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find first empty cell in puzzle

CALLED BY:	GLOBAL	(Board module)

PASS:		dx	- engine token

RETURN:		
		clc - didn't find a empty cell
		stc - found a empty cell
			ax - cell token

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineFindFirstEmptyCell	proc	far
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si = array

	mov	bx, cs
	mov	di, offset EngineFindFirstEmptyCellCallback
	call	ChunkArrayEnum
	
	EngineUnlockDX

	.leave
	ret
EngineFindFirstEmptyCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineFindFirstEmptyCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if cell is empty

CALLED BY:	ENGINE INTERNAL 
			(ChunkArrayEnum from EngineFindFirstEmptyCell)
PASS:		*ds:si	- array
		ds:di	- enumerated element

RETURN:		
		clc - didn't find a empty cell
		stc - found a empty cell
			ax - cell token


DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineFindFirstEmptyCellCallback	proc	far
	.enter

	test	ds:[di].CD_flags, mask CF_EMPTY
	jnz	itsEmpty

	clc
done:
	.leave
	ret

itsEmpty::
	call	ChunkArrayPtrToElement
	stc
	jmp	done	

EngineFindFirstEmptyCellCallback	endp




CwordVictoryCode	ends


if	0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineUnVerifyAllCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	UnVerify all non-empty cells.

CALLED BY:	GLOBAL	(Board module)

PASS:		dx	- engine token

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Unset the CF_WRONG flag for all non-empty, non-hole, existing
	cells.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineUnVerifyAllCells	proc	near
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si = array

	mov	bx, cs
	mov	di, offset EngineUnVerifyCellCallback
	call	ChunkArrayEnum
	
	EngineUnlockDX

	.leave
	ret
EngineUnVerifyAllCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineUnVerifyCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	UnVerifies entire puzzle for user.

CALLED BY:	ENGINE INTERNAL 
			(ChunkArrayEnum from EngineUnVerifyAllCells)
PASS:		*ds:si	- array
		ds:di	- enumerated element

RETURN:		CF	- always clear
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Just clear the CF_WRONG flags.
	Must be a far call.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineUnVerifyCellCallback	proc	far
	uses	ax
	.enter

	BitClr	ds:[di].CD_flags, CF_WRONG

	clc
	.leave
	ret
EngineUnVerifyCellCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetClueType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the ClueTypeFlags for a given clue token.
		These flags are for the alternate clues.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- clue token
		cx	- direction of clue (ACROSS or DOWN)

RETURN:		bl	- ClueTypeFlags

DESTROYED:	bl used for return value
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetClueType	proc	near
	uses	ax,si,di,bp,ds
	.enter

	mov	al, bh				; preserve bh
	Assert	EngineTokenType	dx
	mov	bx, cx				; direction
EC <	call	ECVerifyClueTokenType				>
	
	EngineGetClueHeaderArrayDSSI		; *ds:si - clue header
						;   array
						; bx - clue header handle
	mov	bp, bx 			; clue Header Handle

EC < 	call	ECCheckChunkArray				>

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	mov	bl, {byte} ds:[di].CH_altClueTypeFlags

	push	bx				; clue type flags
	mov	bx, bp				; clue header handle
	Assert	lmem	bx
	call	MemUnlock
	pop	bx				; clue type flags

	mov	bh, al				; preserve bh
	.leave
	ret
EngineGetClueType	endp

endif
