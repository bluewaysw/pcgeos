COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cellFlags.asm

AUTHOR:		Gene Anderson, Aug 24, 1992

ROUTINES:
	Name			Description
	----			-----------
    GBL	RowGetFlags		Get flags for given row
    GBL RowSetFlags		Set flags for given row

	RangeEnumRowFlags	version of RangeEnum() for matching row flags

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/24/92		Initial revision


DESCRIPTION:
	Code for dealing with the infamous ColumnFlags

	$Id: cellFlags.asm,v 1.1 97/04/04 17:44:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get flags for specified row

CALLED BY:	GLOBAL
PASS:		ds:si - ptr to CellFunctionParameters
		ax - row #
RETURN:		carry - set if row exists
		dx - flags for row (0 if row doesn't exist)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RowGetFlags		proc	far
	uses	ds, si
	.enter

EC <	call	ECCheckCellParams	>
	clr	dx				;dx <- assume row doesn't exist
	call	LockRowBlock
	jnc	done				;branch if row doesn't exist
	call	GetRowPointer			;*ds:si <- ptr to row
	jnc	doneUnlock			;branch if row doesn't exist
	mov	si, ds:[si]			;ds:si <- ColumnArrayHeader
EC <	call	ECCheckBounds			;>
	mov	dx, ds:[si].CAH_rowFlags	;dx <- flags for row
doneUnlock:
	call	UnlockRowBlock
done:
	.leave
	ret
RowGetFlags		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowSetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set flags for a given row

CALLED BY:	GLOBAL
PASS:		ds:si - ptr to CellFunctionParameters
		ax - row #
		dx - flags for row
RETURN:		carry - set if row exists
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RowSetFlags		proc	far
	uses	ds, si
	.enter

EC <	call	ECCheckCellParams		;>
	call	LockRowBlock
	jnc	done				;branch if row doesn't exist
	call	GetRowPointer			;*ds:si <- ptr to row
EC <	ERROR_NC ROW_BLOCK_MUST_EXIST		;>
	mov	si, ds:[si]			;ds:si <- ColumnArrayHeader
EC <	call	ECCheckBounds			;>
	push	bp
	mov	bp, ds:LMBH_handle		;bp <- handle of row block
	cmp	ds:[si].CAH_rowFlags, dx	;flags changing?
	je	noChange			;branch if no change
	mov	ds:[si].CAH_rowFlags, dx	;store new flags
	call	VMDirty				;dirty me jesus
noChange:
	call	VMUnlock			;unlock me jesus
	pop	bp
	stc					;carry <- row exists
done:

	.leave
	ret
RowSetFlags		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeEnumRowFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a RangeEnum() for cells with certain flags

CALLED BY:	GLOBAL
PASS:		ds:si	= Pointer to CellFunctionParameters
		ss:bp	= ptr to callback local variables
		ss:bx	= ptr to RangeEnumParams
		    RECFP_params - RangeEnumParams
		    RECFP_flags - flags to check
		dl	= RangeEnumFlags
RETURN:		carry set if callback aborted
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	This routine is optimized under the following assumptions:
	- a lot of rows tend to be entirely empty
	- therefore a lot of row blocks tend to be entirely empty
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	See RangeEnum() for more information.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeEnumRowFlags		proc	near
	uses	ax, cx, ds, di, dx
	.enter

EC <	call	ECCheckCellParams		;>
	mov	ax, ss:[bx].REP_bounds.R_top	;ax <- current row
rowLoop:
	cmp	ax, ss:[bx].REP_bounds.R_bottom	;past bottom?
	ja	quitNoAbort			;branch if done

	mov	cx, ss:[bx].REP_bounds.R_left	;cx <- current column
columnLoop:
	cmp	cx, ss:[bx].REP_bounds.R_right	;past right edge?
	ja	nextRow				;branch if done
	;
	; See if the row block exists -- if not, we can skip 32 rows
	;
	push	ds
	call	LockRowBlock
	jnc	nextRowBlock			;branch if block doesn't exist
	;
	; See if the row exists -- if not, we can skip 1 row
	;
	push	si
	push	ax				;save row #
	call	GetRowPointer
	jnc	nextRowUnlockPop		;branch if row doesn't exist
	;
	; Get the flags for the current row
	;
	push	si
	mov	si, ds:[si]			;ds:si <- ptr to row header
	mov	ax, ds:[si].CAH_rowFlags	;ax <- flags for row
	pop	si
	;
	; Correct flags set for row?
	;
	test	ax, ss:[bx].REP_matchFlags	;right bits set?
	jnz	doCell				;branch if right bit(s) set
	tst	ss:[bx].REP_matchFlags		;special case?
	jnz	nextRowUnlockPop		;branch if not special case
	;
	; Special case -- match flags are zero.  See if the column
	; flags are zero, too
	;
	tst	ax				;column flags zero?
	jnz	nextRowUnlockPop		;branch if not to do next col
	;
	; We've finally gotten to a row where the flags match --
	; do the usual RangeEnum things on it.
	;
doCell:
	call	UnlockRowBlock
	pop	ax				;ax <- row #
	pop	si				;ds:si <- ptr to CFP
	pop	ds
	;
	; Lock the cell if requested
	;
	call	RangeEnumLockCell
	pushf
if FULL_EXECUTE_IN_PLACE
	push	bx, ax
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	mov	ax, ss:[bx].REP_callback.offset
	mov	bx, ss:[bx].REP_callback.segment
	call	ProcCallFixedOrMovable
	pop	bx, ax
else
	call	ss:[bx].REP_callback		;call me jesus
endif
	jc	abort
	popf					;restore 'cell exists' flag
	;
	; Unlock the cell if necessary
	;
	call	RangeEnumUnlockCell
	;
	; Go to do the next column
	;
	inc	cx				;cx <- next column
	jmp	columnLoop

nextRowUnlockPop:
	call	UnlockRowBlock
	pop	ax				;ax <- row #
	pop	si
	pop	ds				;ds:si <- ptr to CFP
nextRow:
	inc	ax
	jmp	rowLoop

nextRowBlock:
	pop	ds				;get rid of redundant ds.
	ComputeNextRowBlockStart ax
	jmp	rowLoop


quitNoAbort:
	clc					;signal: didn't abort
quit:
	.leave
	ret

abort:
	;
	; The callback aborted.
	; On stack:
	;	flags, carry set if cell existed.
	;
	popf					;restore 'cell exists' flag
	call	RangeEnumUnlockCell		;release the cell
	stc					;signal: aborted
	jmp	quit
RangeEnumRowFlags		endp

CellCode	ends
