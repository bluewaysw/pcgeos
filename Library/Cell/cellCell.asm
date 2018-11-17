COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cellCell.asm

AUTHOR:		John Wedgwood, December  5th, 1990

ROUTINES:
	Name			Description
	----			-----------
GLBL	CellReplace		Replace a cell with new data
GLBL	CellLock		Lock a cell
GLBL	CellGetDBItem		Get the dbase item associated with a cell
GLBL	CellGetExtent		Get the extent of the current sheet

	ForceCellDBItem		Force the existence of a cell
	CheckCellDBItem		Check the existence of a cell
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/ 5/90	Initial revision

DESCRIPTION:
	Cell manipulation routines.

	$Id: cellCell.asm,v 1.1 97/04/04 17:44:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellReplace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace a cell with new data.

CALLED BY:	Global
PASS:		ds:si	= Pointer to CellFunctionParameters
		ax	= Row #
		cl	= Column #
		es:di	= pointer to the data to replace with
		dx	= Size of the data to replace with
			= 0 to free the cell.
RETURN:		nothing
DESTROYED:	Possibly es, if it pointed at a dbase item in the same file.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 5/90	Initial version
	jcw	 3/29/91	Optimizations required a complete rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CellReplace	proc	far
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter
	;
	; Error check the parameters.
	;
EC <	tst	dx			>
EC <	jz	skipPtrCheck		>
EC <	call	ECCheckPointerESDI	>
EC <skipPtrCheck:			>
EC <	call	ECCheckAXRow		>
EC <	call	ECCheckCLColumn		>
EC <	call	ECCheckDXSize		>

EC <	call	ECCheckCellParams		;>
	mov	bx, ds:[si].CFP_file	; bx <- VM file

	tst	dx			; Check for removing the cell
	jz	removeCell		; Branch if removing the cell
	;
	; We are actually adding cell data.
	;
	push	es, di			; Save ptr to the data
	call	ForceCellDBItem		; Forcibly create a cell db-item
					; ax <- group
					; di <- item

	mov	cx, dx			; cx <- new size
	call	DBReAlloc		; Change the size of the item

	call	DBLock			; *es:di <- ptr to cell
	mov	di, es:[di]		; es:di <- ptr to the cell
	pop	ds, si			; ds:si <- ptr to the data
	;
	; ds:si = ptr to the data to save
	; es:di = ptr to the cell to save it in
	; cx	= size of the data
	;
	shr	cx, 1			; cx <- number of words to copy
	rep	movsw			; Save the data
	jnc	noMore			; jump if no more to copy
	movsb				; copy remaining byte
noMore:	
	;
	; The block was dirtied by DBReAlloc(), we don't need to do it
	; ourselves.
	;
	call	DBUnlock		; Release the cell
	jmp	done			; Branch to finish up

removeCell:
	;
	; Remove the cell data, if it exists.
	;
	mov	dx, ax			; Save row in dx

	call	CheckCellDBItem		; ax/di <- cell dbase-item
	jnc	done			; Quit if it doesn't exist
	;
	; Cell does exist (ax/di = group/item). Remove the cell.
	;
	call	DBFree			; Free the item
	
	mov	ax, dx			; Restore row
	call	RowDeleteCell		; Remove the cell from the row
done:
	.leave
	ret
CellReplace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a cells data to examine or change it.
		It is highly uncool to keep a cell locked while you go off
		and add or delete other cells. If you want to do something
		like that, lock the cell, copy the data out, and then
		unlock it again.

CALLED BY:	Global
PASS:		ds:si	= Pointer to CellFunctionParameters
		ax	= Row #
		cl	= Column #
RETURN:		carry set if the cell exists
		    *es:di = Pointer to cell data
		carry clear otherwise
		    di destroyed
DESTROYED:	di (unless it is returned)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 5/90	Initial version
	jcw	 3/29/91	Optimizations required a complete rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CellLock	proc	far
	uses	ax, bx
	.enter
EC <	call	ECCheckAXRow		>
EC <	call	ECCheckCLColumn		>

	call	CheckCellDBItem		; ax, di <- cell
	jnc	quit			; Quit if it doesn't exist

EC <	call	ECCheckCellParams		;>
	mov	bx, ds:[si].CFP_file	; bx <- VM file
	call	DBLock			; Lock the cell.
	stc				; Mark that the cell exists.
quit:
	.leave
	ret
CellLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellGetDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dbase item associated with a cell

CALLED BY:	Global
PASS:		ds:si	= Pointer to CellFunctionParameters
		ax	= Row
		cl	= Column
RETURN:		carry set if the item exists
		ax, di	= Group,Item of the cell
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 5/91	Initial version
	jcw	 3/29/91	Optimizations required a complete rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CellGetDBItem	proc	far
	uses	bx, dx
	.enter
EC <	call	ECCheckAXRow		>
EC <	call	ECCheckCLColumn		>

	call	CheckCellDBItem		; Check for cell existing
	;
	; Carry set if cell exists
	;
	mov	dx, ax			; dx <- group

	mov	ax, dx			; Return group in ax
	.leave
	ret
CellGetDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceCellDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the creation of a cell dbase item

CALLED BY:	CellReplace
PASS:		ds:si	= Pointer to the CellFunctionParameters
		ax	= Row
		cl	= Column
RETURN:		ax, di	= Group, item of the cell
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceCellDBItem	proc	near
	uses	ds, si, bx, bp
	.enter
EC <	call	ECCheckCellParams	>
	mov	bx, ds:[si].CFP_file	; bx <- VM file handle
	call	ForceLockRowBlock	; ds <- segment address of the row
	
	call	ForceGetRowPointer	; *ds:si <- ptr to the row
	
	call	ForceFindCellInRow	; ds:si <- ptr to cell entry
	;
	; Entry does exist.
	;
	mov	ax, ds:[si].CAE_data.DBI_group
	mov	di, ds:[si].CAE_data.DBI_item

	mov	bp, ds:LMBH_handle	; bp <- memory handle
	call	VMUnlock		; Release the rows block

	.leave
	ret
ForceCellDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCellDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of a cell dbase item

CALLED BY:	CellGetDBItem, CellReplace, CellLock
PASS:		ds:si	= Pointer to CellFunctionParameters
		ax	= Row of the cell
		cl	= Column of the cell
RETURN:		carry set if the cell exists
		ax, di	= Group, item of the cell if it exists
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckCellDBItem	proc	near
	uses	ds, si, bp
	.enter
EC <	call	ECCheckCellParams	>
	call	LockRowBlock		; ds <- segment address of the row
	jnc	quit			; Quit if it doesn't exist
	
	call	GetRowPointer		; *ds:si <- ptr to the row
	jnc	quitUnlockRow		; Quit if the row doesn't exist
	
	call	FindCellInRow		; ds:si <- ptr to cell entry
	jnc	quitUnlockRow		; Quit if entry doesn't exist
	;
	; Entry does exist.
	; Carry is already set here.
	;
	mov	ax, ds:[si].CAE_data.DBI_group
	mov	di, ds:[si].CAE_data.DBI_item
quitUnlockRow:
	;
	; Carry is set correctly here.
	; VMUnlock doesn't destroy the carry.
	;
	mov	bp, ds:LMBH_handle	; bp <- memory handle
	call	VMUnlock		; Release the rows block
quit:
	.leave
	ret
CheckCellDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellGetExtent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the extent of the current sheet

CALLED BY:	Global
PASS:		ds:si	= Pointer to CellFunctionParameters
		ss:bx	= Pointer to RangeEnumParams
RETURN:		REP_bounds filled in with the extent of the spreadsheet
			All bounds set to -1 if there is no spreadsheet
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The caller doesn't need to set anything in the RangeEnumParams. This
	routine does it all.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CellGetExtent	proc	far
	uses	ax, dx
reParams	local	RangeEnumParams
	.enter
EC <	call	ECCheckCellParams	>
	;
	; Initialize our extent to something unusual.
	;
	mov	reParams.REP_bounds.R_top, -1
	;
	; Set up parameters for call to RangeEnum()
	;
	mov	ss:[bx].REP_bounds.R_top, 0
	mov	ss:[bx].REP_bounds.R_left, 0
	mov	ss:[bx].REP_bounds.R_bottom, LARGEST_VISIBLE_ROW
	mov	ss:[bx].REP_bounds.R_right, LARGEST_COLUMN

	mov	ss:[bx].REP_callback.segment, cs
	mov	ss:[bx].REP_callback.offset,  offset cs:CGE_callback
	clr	dl				; Only cells which exist
	call	RangeEnum
	;
	; Check for no cells at all.
	;
	cmp	reParams.REP_bounds.R_top, -1
	jne	gotBounds
	mov	ax, -1
	mov	reParams.REP_bounds.R_top, ax
	mov	reParams.REP_bounds.R_left, ax
	mov	reParams.REP_bounds.R_right, ax
	mov	reParams.REP_bounds.R_bottom, ax
gotBounds:
	;
	; Copy the bounds from one frame to another.
	;
	mov	ax, reParams.REP_bounds.R_top
	mov	ss:[bx].REP_bounds.R_top, ax

	mov	ax, reParams.REP_bounds.R_left
	mov	ss:[bx].REP_bounds.R_left, ax
	
	mov	ax, reParams.REP_bounds.R_bottom
	mov	ss:[bx].REP_bounds.R_bottom, ax

	mov	ax, reParams.REP_bounds.R_right
	mov	ss:[bx].REP_bounds.R_right, ax
	.leave
	ret
CellGetExtent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGE_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for CellGetExtent

CALLED BY:	RangeEnum
PASS:		ax/cx	= Row/Column of current cell
		ss:bp	= Local variables
RETURN:		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGE_callback	proc	far
reParams	local	RangeEnumParams
	.enter	inherit
	cmp	reParams.REP_bounds.R_top, -1
	je	firstCell		; Branch if this is the first call

	cmp	reParams.REP_bounds.R_top, ax
	jbe	skipTopSet
	mov	reParams.REP_bounds.R_top, ax
skipTopSet:

	cmp	reParams.REP_bounds.R_bottom, ax
	jae	skipBottomSet
	mov	reParams.REP_bounds.R_bottom, ax
skipBottomSet:

	cmp	reParams.REP_bounds.R_left, cx
	jbe	skipLeftSet
	mov	reParams.REP_bounds.R_left, cx
skipLeftSet:

	cmp	reParams.REP_bounds.R_right, cx
	jae	skipRightSet
	mov	reParams.REP_bounds.R_right, cx
skipRightSet:

quit:
	clc					; Signal: continue
	.leave
	ret

firstCell:
	;
	; This is the first callback. Set the extent to this cell.
	;
	mov	reParams.REP_bounds.R_top, ax
	mov	reParams.REP_bounds.R_bottom, ax
	mov	reParams.REP_bounds.R_left, cx
	mov	reParams.REP_bounds.R_right, cx
	jmp	quit
CGE_callback	endp

CellCode	ends
