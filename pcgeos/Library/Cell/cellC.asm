COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Cell
FILE:		cellC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	2/92		Initial version

DESCRIPTION:
	This file contains C interface routines for the cell library routines

	$Id: cellC.asm,v 1.1 97/04/04 17:44:59 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Cell	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	CellLock

C DESCRIPTION:	Returns NULL if no data, else ptr to locked cell

C DECLARATION:	extern void *
			_far _pascal CellLock(CellFunctionParams *cfp,
							word rowNum, 
							word colNum);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	2/92		Initial version

------------------------------------------------------------------------------@
CELLLOCK	proc	far	cfp:fptr, rowNum:word, colNum:word
							uses ds, di, si, es

	.enter

	lds	si, cfp
	mov	ax, rowNum
	mov	cx, colNum
	call	CellLock
	jnc	noCell
	mov	ax, es:[di]
	mov	dx, es
	jmp	done
noCell:
	clr	ax, dx				;dx:ax <- no data
done:
	.leave
	ret
CELLLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	CellLockGetRef

C DESCRIPTION:	Returns NULL if no data, else handle & chunk of locked cell
		in *ref and ptr to locked cell.

C DECLARATION:	extern void *
			_far _pascal CellLockGetRef(CellFunctionParams *cfp,
							word rowNum, 
							word colNum,
							CellRef *ref);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	5/5/92		Initial version

------------------------------------------------------------------------------@
CELLLOCKGETREF	proc	far	cfp:fptr, rowNum:word, colNum:word, ref:fptr
							uses ds, di, si, es

	.enter

	lds	si, cfp
	mov	ax, rowNum
	mov	cx, colNum
	call	CellLock
	jnc	noCell
	mov	dx, es
	push	es:[di]			;save offset
	mov_trash	ax, di

	mov	bx, es:[LMBH_handle]	;save handle

	les	di, ref
	stosw				;store chunk
	mov	ax, bx
	stosw				;store handle

	pop 	ax
	jmp	done
noCell:
	clr	ax, dx			;dx:ax <- no data
done:
	.leave
	ret
CELLLOCKGETREF	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	CellReplace

C DECLARATION:	extern void 
                        _far _pascal CellReplace(CellFunctionParams *cfp,
							word rowNum,
							word colNum,
							void *newData,
							word dataSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	2/92		Initial version

------------------------------------------------------------------------------@
CELLREPLACE	proc	far		cfp:fptr, rowNum:word, colNum:word,
					newData:fptr, dataSize:word
					uses ds, si, es, di
	.enter

	lds	si, cfp
	mov	ax, rowNum
	mov	cl, colNum.low
	les	di, newData
	mov	dx, dataSize
	call	CellReplace

	.leave
	ret

CELLREPLACE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ROWGETFLAGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


C FUNCTION:	RowGetFlags

C DESCRIPTION:	Returns row flags

C DECLARATION:	extern flags 
			_far _pascal RowGetFlags(CellFunctionParams *cfp,
							word rowNum);
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ROWGETFLAGS	proc	far 	cfp:fptr, rowNum:word
	uses	ds, si
	.enter
	lds	si, ss:cfp
	mov	ax, ss:rowNum
	call	RowGetFlags			;dx <- row flags

	mov	ax, TRUE			;ax <- assume exists
	jc	rowExists
	mov	ax, FALSE			;ax <- 
rowExists:
	xchg	ax, dx				;ax <- row flags

	.leave
	ret
ROWGETFLAGS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ROWSETFLAGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	RowSetFlags

C DESCRIPTION:	Sets row flags

C DECLARATION:	extern flags
			_far _pascal RowSetFlags(CellFunctionParams *cfp,
							word rowNum,
							word flags);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ROWSETFLAGS	proc	far  cfp:fptr, rowNum:word, flags:word
	uses	ds, si
	.enter

	lds	si, ss:cfp
	mov	ax, ss:rowNum
	mov	dx, ss:flags
	call	RowSetFlags

	mov	ax, TRUE			;ax <- assume exists
	jc	rowExists
	mov	ax, FALSE			;ax <- 
rowExists:
	xchg	ax, dx				;ax <- row flags

	.leave
	ret
ROWSETFLAGS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RANGEEXISTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	RangeExists

C DESCRIPTION:	Check for the existence of cells in a range

C DECLARATION:	extern Boolean
			_far _pascal RangeExists(CellFunctionParams *cfp,
						 word rowStart,
						 word colStart,
						 word rowEnd,
						 word colEnd);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: the row must exist
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RANGEEXISTS	proc	far  cfp:fptr, rowStart:word, colStart:word,
			     rowEnd:word, colEnd:word

	uses	ds, si
	.enter

	lds	si, ss:cfp

	mov	ax, ss:rowStart
	mov	cl, {byte}ss:colStart

	mov	dx, ss:rowEnd
	mov	ch, {byte}ss:colEnd

	call	RangeExists

	mov	ax, TRUE			; Assume found.
	jc	exit				; Branch if not.
	clr	ax				; Signal: no cells in range.
exit:
	.leave
	ret
RANGEEXISTS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RANGEENUM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	RangeEnum

C DESCRIPTION:	Enumerates cells in a range

C DECLARATION:	extern Boolean
			_far _pascal RangeEnum(CellFunctionParams *cfp,
					 	CRangeEnumParams *params,
						RangeEnumFlags flags);
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/26/92		Initial version
	JDM	92.09.04	Added RangeEnumFlags.
	JDM	92.09.09	Fixed return handling.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RANGEENUM		proc	far	cfp:fptr, params:fptr, flags:word
	uses	ds, si
	.enter

	lds	si, ss:cfp			;ds:si <- ptr to CFP
EC <	mov	bx, ss				;>
EC <	cmp	bx, ss:params.segment		;>
EC <	ERROR_NE RANGE_ENUM_PARAMS_MUST_BE_ON_STACK ;>
	mov	bx, ss:params.offset		;ss:bx <- RangeEnumParams
	movdw	ss:[bx].CREP_callback, \
		ss:[bx].CREP_params.REP_callback, \
		ax				;Save caller's callback.
	mov	ss:[bx].CREP_params.REP_callback.segment, cs
	mov	ss:[bx].CREP_params.REP_callback.offset, \
						offset CRangeEnumCallback
	mov	dx, ss:[flags]			; DL = RangeEnumFlags.
	call	RangeEnum			; Carry set iff aborted.
	mov	ax, TRUE			; Assume abortion.
	jc	exit				; Branch if aborted.
	clr	ax				; Success.  Carry cleared.
exit:
	.leave
	ret
RANGEENUM		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CRangeEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for C version of RangeEnum()

CALLED BY:	RangeEnum()
PASS:		ds:si	= Pointer to CellFunctionParameters
		(ax,cx)	= current cell (r,c)
		ss:bp	= ptr to callback local variables
		ss:bx	= ptr to stack frame passed as RangeEnumParams
		if REF_ROW_FLAGS:
			REP_rowFlags - ColumnFlags for cell
		*es:di	= ptr to cell data if any
		dl	= RangeEnumFlags
		carry set if cell has data
RETURN:		carry set to abort enumeration
		es	= seg addr of cell (updated)
		dl	= RangeEnumFlags modified to (possibly) include:
				REF_CELL_ALLOCATED
				REF_CELL_FREED
				REF_OTHER_ALLOC_OR_FREE
				REF_COLUMN_FLAGS_MODIFIED
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CRangeEnumCallback		proc	far
	uses	ax, bx, cx, si, di, es, ds, bp
	.enter

	push	dx				;CRECP_rangeFlags
	movdw	bpdx, 0				;assume no data
	jnc	gotPtr				;branch if no data
	mov	bp, es
	mov	dx, es:[di]			;bp:dx <- ptr to data
gotPtr:
	pushdw	bpdx				;CRECP_cellData
	push	cx				;CRECP_column
	push	ax				;CRECP_row
	pushdw	ssbx				;CRECP_rangeParams
CheckHack <(size CRangeEnumCallbackParams) eq 13>
	mov	ax, ss:[bx].CREP_callback.offset
	mov	bx, ss:[bx].CREP_callback.segment
	call	ProcCallFixedOrMovable		;DX:AX = C callback return
						;DH = TRUE to abort.
						;DL = New RangeEnumFlags.
						;AX trashed by call.
	tst	dh				;abort?
	jz	done				;branch if not abort (carry clr)
	stc					;carry <- abort
done:

	.leave
	ret
CRangeEnumCallback		endp


C_Cell	ends

        SetDefaultConvention
