COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetErrorCheck.asm

AUTHOR:		Gene Anderson, Mar 25, 1991

ROUTINES:
	Name			Description
	----			-----------
	ECCheckCellCoord	see if a cell coordinate is legal
	ECCheckSelectedCell	see if a cell coordinate is selected and legal
	ECCheckOrderedCoords	make sure range bounds are ordered
	ECTrashBuffer		trash common buffer
	ECCheckInstancePtr	check pointer to spreadsheet instance data

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/25/91		Initial revision

DESCRIPTION:
	General-purpose error-checking routines for Spreadsheet object

	$Id: spreadsheetErrorCheck.asm,v 1.1 97/04/07 11:14:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ECCode	segment	resource

if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSelectedCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a cell coordinate is selected and legal
CALLED BY:	UTILITY

PASS:		(ax,cx) - cell coords to check
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckSelectedCell	proc	far
	class	SpreadsheetClass

	call	ECCheckInstancePtr

	cmp	ax, ds:[si].SSI_selected.CR_start.CR_row
	jb	notSelected
	cmp	ax, ds:[si].SSI_selected.CR_end.CR_row
	ja	notSelected
	cmp	cx, ds:[si].SSI_selected.CR_start.CR_column
	jb	notSelected
	cmp	cx, ds:[si].SSI_selected.CR_end.CR_column
	ja	notSelected

	GOTO	ECCheckCellCoord

notSelected:
	ERROR	CELL_NOT_SELECTED

ECCheckSelectedCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCellCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if cell coordinate is legal
CALLED BY:	UTILITY

PASS:		(ax,cx) - cell coords to check
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckCellCoord	proc	far
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	cmp	ax, MIN_ROW
	ERROR_B	ILLEGAL_ROW
	cmp	ax, ds:[si].SSI_maxRow
	ERROR_A	ILLEGAL_ROW
	cmp	cx, MIN_ROW
	ERROR_B	ILLEGAL_COLUMN
	cmp	cx, ds:[si].SSI_maxCol
	ERROR_A	ILLEGAL_COLUMN
	ret
ECCheckCellCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckOrderedCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that coordinates are ordered and legal
CALLED BY:	UTILITY

PASS:		(ax,cx)
		(bp,dx) - range to check
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckOrderedCoords	proc	far
	class	SpreadsheetClass

	call	ECCheckCellCoord		;check 1st coordinate
	push	ax, cx
	mov	ax, bp
	mov	cx, dx
	call	ECCheckCellCoord		;check 2nd coordinate
	pop	ax, cx
	cmp	ax, bp				;check row coordinates ordered
	ERROR_A	UNORDERED_COORDINATES
	cmp	cx, dx				;check column column ordered
	ERROR_A	UNORDERED_COORDINATES
	ret
ECCheckOrderedCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a pointer is valid

CALLED BY:	Utility
PASS:		ds:si	= Pointer to check
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckPointer	proc	far
	uses	ax, bx, cx, dx, di
	.enter
	call	SysGetECLevel		; Check for segment checking
	test	ax, mask ECF_SEGMENT
	jz	quit			; Branch if no segment checking

	mov	ax, ds			; ax <- segment to check
	call	ECCheckSegment		; Check the segment...
	
	mov	cx, ds			; cx <- segment
	call	MemSegmentToHandle	; cx <- handle
	ERROR_NC PASSED_SEGMENT_HAS_NO_HANDLE

	mov	bx, cx			; bx <- handle to check
	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
	call	MemGetInfo
	mov	cx, ax			; cl <- flags, ch <- lock count
	mov	ax, MGIT_SIZE		; ax <- MemGetInfoType
	call	MemGetInfo		; ax <- size in bytes

	test	cl, mask HF_FIXED	; Check for fixed block
	jnz	skipLockCheck
	tst	ch			; Check for unlocked block
	ERROR_Z	PASSED_SEGMENT_IN_UNLOCKED_BLOCK
skipLockCheck:
	cmp	si, ax			; Check offset vs. block size
	ERROR_A	PASSED_OFFSET_PAST_END_OF_BLOCK

quit:
	.leave
	ret
ECCheckPointer	endp


ECCheckPointerESDI	proc	far
	uses	ds, si
	.enter
	segmov	ds, es, si
	mov	si, di
	call	ECCheckPointer
	.leave
	ret
ECCheckPointerESDI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCellListHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a cell list block header

CALLED BY:	
PASS:		ds	= Segment address of the block
RETURN:		nothing
DESTROYED:	nothing (not even flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckCellListHeader	proc	far
	uses	si
	.enter
	pushf

	;
	; First check that the data doesn't fall beyond the block.
	;
	mov	si, ds:CLH_endOfData
	cmp	si, ds:CLH_blockSize
	ERROR_A	DATASIZE_IS_LARGER_THAN_BLOCK_SIZE
	
	;
	; Now check that the block-size is valid.
	;
	mov	si, ds:CLH_blockSize	; ds:si <- ptr past block end
	dec	si			; ds:si <- ptr to end of block
	call	ECCheckPointer		; Make sure that's a legal offset

	popf
	.leave
	ret
ECCheckCellListHeader	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckInstancePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that DS:SI points to what we think it does.

CALLED BY:

PASS:		DS:SI - pointer to spreadsheet instance data (?)

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckInstancePtr	proc far
	uses	di
	class	SpreadsheetClass
	.enter
	pushf
	call	ECCheckPointer
	mov	di, ds:[si].SSI_chunk
	mov	di, ds:[di]
	add	di, ds:[di].Spreadsheet_offset
	cmp	di, si
	ERROR_NE DS_SI_NOT_POINTING_TO_SPREADSHEET
	popf
	.leave
	ret
ECCheckInstancePtr	endp


endif

ECCode ends
