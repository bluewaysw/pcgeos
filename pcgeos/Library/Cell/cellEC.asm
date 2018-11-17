COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cellEC.asm

AUTHOR:		John Wedgwood, Jan 15, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/15/91	Initial revision

DESCRIPTION:
	Error checking code for the cell library.

	$Id: cellEC.asm,v 1.1 97/04/04 17:44:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCellParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that valid cell function parameters are passed
CALLED BY:	UTILITY

PASS:		ds:si - ptr to CellFunctionParameters
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckCellParams	proc	near
	uses	bx
	.enter

	pushf
EC <	mov	bx, ds:[si].CFP_file		;bx <- file handle>
EC <	tst	bx				;>
EC <	ERROR_Z CELL_PASSED_BAD_FILE		;>
EC <	call	ECCheckBXFileHandle		;>
EC <	test	ds:[si].CFP_flags, not (mask CellFunctionParameterFlags) >
EC <	ERROR_NZ CELL_PASSED_BAD_PARAMS		;>
	popf

	.leave
	ret
ECCheckCellParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckBXFileHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if bx contains a file handle

CALLED BY:	Utility
PASS:		bx	= File handle to verify
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckBXFileHandle	proc	far
	.enter

	call	ECVMCheckVMFile

	.leave
	ret
ECCheckBXFileHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckAXRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if ax contains a valid row #

CALLED BY:	Utility
PASS:		ax	= Row # to check
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There is really no good way to check this...
	When I think of one, I'll put it here.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckAXRow	proc	far
	cmp	ax, LARGEST_ROW
	ERROR_A	ROW_IS_OUT_OF_BOUNDS
	ret
ECCheckAXRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCLColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if cl is a valid column #

CALLED BY:	Utility
PASS:		cl	= Column #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There is really no good way to check this...
	When I think of one, I'll put it here.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckCLColumn	proc	far
	ret
ECCheckCLColumn	endp


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
	ERROR_NC CELL_PASSED_SEGMENT_HAS_NO_HANDLE
	
	mov	bx, cx			; bx <- handle to check
	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
	call	MemGetInfo
	mov	cx, ax			; cl <- flags, ch <- lock count
	mov	ax, MGIT_SIZE		; ax <- MemGetInfoType
	call	MemGetInfo		; ax <- size in bytes
	
	test	cl, mask HF_FIXED	; Check for fixed block
	jnz	skipLockCheck
	tst	ch			; Check for unlocked block
	ERROR_Z	CELL_PASSED_SEGMENT_IN_UNLOCKED_BLOCK
skipLockCheck:
	cmp	si, ax			; Check offset vs. block size
	ERROR_A	CELL_PASSED_OFFSET_PAST_END_OF_BLOCK

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
		ECCheckDXSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a size is valid

CALLED BY:	Utility
PASS:		dx	= Size to check
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	It's silly but simple. I won't allow cells to be over 16K in size.
	This should catch 3/4 of the screwups.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckDXSize	proc	far
	cmp	dx, 0x4000
	ERROR_A	CELL_PASSED_SIZE_IS_TOO_LARGE
	ret
ECCheckDXSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a range

CALLED BY:	Utility
PASS:		ss:bp	= Pointer to rectangle that should be a range.
RETURN:		nothing
DESTROYED:	nothing, not even flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckRange	proc	far
	uses	ax
	.enter
	pushf

	mov	ax, ss:[bp].R_top
	cmp	ax, ss:[bp].R_bottom
	ERROR_A	CELL_PASSED_RANGE_HAS_UNORDERED_ROWS
	
	mov	ax, ss:[bp].R_left
	cmp	ax, ss:[bp].R_right
	ERROR_A	CELL_PASSED_RANGE_HAS_UNORDERED_COLUMNS
	
	popf
	.leave
	ret
ECCheckRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a row for consistency...

CALLED BY:	
PASS:		*ds:si	= Segment address of the row
RETURN:		nothing
DESTROYED:	nothing (not even the flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 3/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckRow	proc	far
	uses	bx, cx, dx, di, si
	.enter
	pushf
	mov	si, ds:[si]		; ds:si <- ptr to the row
	cmp	si, -1			; Check for empty row
	je	quit			; Branch if row empty
	;
	; Check that all the elements in the row are in order
	; and that the items for each cell are valid.
	;
	mov	cx, ds:[si].CAH_numEntries ; cx <- # of entries to check
	jcxz	quit
	clr	dh			; Signal: First entry
	add	si, size ColumnArrayHeader
checkNextEntry:
	;
	; ds:si = Pointer to the entry to check
	; dl	= Previous column #
	;
	; Check that the current entry # is greater than the previous one.
	;
	tst	dh			; Check for first entry
	jz	skipEntryNumCheck	; Branch if first entry
	cmp	ds:[si].CAE_column, dl
	ERROR_BE ROW_ELEMENTS_ARE_NOT_ORDERED
skipEntryNumCheck:
	;
	; There isn't a good way to error check the dbase item...
	;
	
	add	si, size ColumnArrayElement
	loop	checkNextEntry		; Loop to check the next one
quit:
	popf
	.leave
	ret
ECCheckRow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckEnumParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that RangeEnumParams are valid

CALLED BY:	EC code
PASS:		ss:bx - ptr to RangeEnumParams
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckEnumParams	proc	near
	uses	ds, si, bp
	.enter

	pushf
	movdw	dssi, ss:[bx].REP_callback

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the callback passed in is valid
	;
EC <	push	bx						>
EC <	mov	bx, ds						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	pop	bx						>
else
	call	ECCheckBounds
endif
	lea	bp, ss:[bx].REP_bounds		;ss:bp <- ptr to Rectangle
	call	ECCheckRange
	popf

	.leave
	ret
ECCheckEnumParams	endp

CellCode	ends
