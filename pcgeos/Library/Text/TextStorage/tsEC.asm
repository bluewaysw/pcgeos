COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsEC.asm

AUTHOR:		John Wedgwood, Nov 19, 1991

ROUTINES:
	Name				Description
	----				-----------
	TS_ECCheckParams		Exported parameter checking routine

	ECCheckTextReference		Check a general text reference

	ECCheckTextReferencePointer	Check specific text references
	ECCheckTextReferenceSegmentChunk
	ECCheckTextReferenceBlockChunk
	ECCheckTextReferenceBlock
	ECCheckTextReferenceVMBlock
	ECCheckTextReferenceDBItem
	ECCheckTextReferenceHugeArray

	ECCheckVisTextReplaceParameters	Check VisTextReplaceParameters

	ECSmallCheckVisTextReplaceParameters

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/19/91	Initial revision

DESCRIPTION:
	Error checking routines for the TextStorage module.

	$Id: tsEC.asm,v 1.1 97/04/07 11:22:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextEC	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_ECCheckParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported routine to do parameter checking.

CALLED BY:	VisTextReplace
PASS:		*ds:si	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		nothing
DESTROYED:	nothing (even flags are preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_ECCheckParams	proc	far
	uses	di
	.enter
	pushf
	mov	di, TSV_CHECK_PARAMS		; di <- routine to call
	call	CallStorageHandler		; Call the ec routine
	test	ss:[bp].VTRP_flags, not mask VisTextReplaceFlags
	ERROR_NZ VIS_TEXT_BAD_REPLACE_FLAGS
	popf
	.leave
	ret
TS_ECCheckParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTextReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to make sure that a text reference is valid.

CALLED BY:	ECCheckVisTextReplaceParameters
PASS:		ss:bp	= TextReference
		*ds:si	= Text instance
RETURN:		nothing
DESTROYED:	nothing (even flags are left intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTextReference	proc	far
	uses	bx, bp
	.enter
	pushf
	mov	bx, ss:[bp].TR_type		; bx <- type
	
	lea	bp, ss:[bp].TR_ref		; ss:bp <- ptr to reference
	
	push	cs				; Far routines
	call	cs:checkTypeTable[bx]		; Call a routine...
	popf
	.leave
	ret
ECCheckTextReference	endp

checkTypeTable	word	\
	offset cs:ECCheckTextReferencePointer,		; TRT_POINTER
	offset cs:ECCheckTextReferenceSegmentChunk,	; TRT_SEGMENT_CHUNK
	offset cs:ECCheckTextReferenceBlockChunk,	; TRT_BLOCK_CHUNK
	offset cs:ECCheckTextReferenceBlock,		; TRT_BLOCK
	offset cs:ECCheckTextReferenceVMBlock,		; TRT_VM_BLOCK
	offset cs:ECCheckTextReferenceDBItem,		; TRT_DB_ITEM
	offset cs:ECCheckTextReferenceHugeArray		; TRT_HUGE_ARRAY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTextReferencePointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a pointer reference to some text.

CALLED BY:	ECCheckTextReference
PASS:		*ds:si	= Text instance
		ss:bp	= TextReferencePointer
RETURN:		nothing
DESTROYED:	nothing (even flags are intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTextReferencePointer	proc	far
	class	VisTextClass
	uses	ax, si, ds
	.enter
	pushf

	;
	; We need to make sure that if the text object is a small object
	; the reference cannot be to text that is in the same block as the
	; text object. The problem here is that making room for the text
	; could cause the text chunk itself to move. The result is that the
	; pointer might not be valid.
	;
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset		; ds:si <- instance ptr
	test	ds:[si].VTI_storageFlags, mask VTSF_LARGE
	jnz	afterSegmentCheck
	
	mov	ax, ds
	cmp	ax, ss:[bp].TRP_pointer.segment
	ERROR_Z	CANNOT_USE_A_POINTER_TO_TEXT_IN_SAME_BLOCK_AS_TEXT_OBJECT
afterSegmentCheck:
	
	;
	; Make sure that the segment and offset are valid.
	;
	mov	ds, ss:[bp].TRP_pointer.segment
	mov	si, ss:[bp].TRP_pointer.offset
	EC_BOUNDS	ds, si
	popf
	.leave
	ret
ECCheckTextReferencePointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTextReferenceSegmentChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a segment.chunk reference to some text.

CALLED BY:	ECCheckTextReference
PASS:		*ds:si	= Text instance
		ss:bp	= TextReferenceSegmentChunk
RETURN:		nothing
DESTROYED:	nothing (even flags are intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTextReferenceSegmentChunk	proc	far
	uses	si, ds
	.enter
	mov	ds, ss:[bp].TRSC_segment
	mov	si, ss:[bp].TRSC_chunk
	
	call	ECLMemValidateHandle
	.leave
	ret
ECCheckTextReferenceSegmentChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTextReferenceBlockChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a block.chunk reference to some text.

CALLED BY:	ECCheckTextReference
PASS:		*ds:si	= Text instance
		ss:bp	= TextReferenceBlockChunk
RETURN:		nothing
DESTROYED:	nothing (even flags are intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTextReferenceBlockChunk	proc	far
	uses	ax, bx, si, ds
	.enter
	pushf
	mov	bx, ss:[bp].TRBC_ref.handle
	mov	si, ss:[bp].TRBC_ref.chunk
	
	call	ObjLockObjBlock			; Lock the block
	mov	ds, ax				; *ds:si <- chunk
	call	ECLMemValidateHandle
	call	MemUnlock			; Release the block
	popf
	.leave
	ret
ECCheckTextReferenceBlockChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTextReferenceBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a block reference to some text.

CALLED BY:	ECCheckTextReference
PASS:		*ds:si	= Text instance
		ss:bp	= TextReferenceBlock
RETURN:		nothing
DESTROYED:	nothing (even flags are intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTextReferenceBlock	proc	far
	uses	ax, bx, si, ds
	.enter
	pushf
	mov	bx, ss:[bp].TRB_handle
	call	MemLock				; ax <- block segment
	mov	ds, ax				; ds <- segment
	
	clr	si				; ds:si <- ptr to text
	EC_BOUNDS	ds, si
	
	call	MemUnlock			; Release the block
	popf
	.leave
	ret
ECCheckTextReferenceBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTextReferenceVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a vm-block reference to some text.

CALLED BY:	ECCheckTextReference
PASS:		*ds:si	= Text instance
		ss:bp	= TextReferenceVMBlock
RETURN:		nothing
DESTROYED:	nothing (even flags are intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTextReferenceVMBlock	proc	far
	uses	ax, bx
	.enter
	pushf
	mov	bx, ss:[bp].TRVMB_file
	call	ECVMCheckVMFile

	mov	ax, ss:[bp].TRVMB_block
	call	ECVMCheckVMBlockHandle
	popf
	.leave
	ret
ECCheckTextReferenceVMBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTextReferenceDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a dbItem reference to some text.

CALLED BY:	ECCheckTextReference
PASS:		*ds:si	= Text instance
		ss:bp	= TextReferenceDBItem
RETURN:		nothing
DESTROYED:	nothing (even flags are intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTextReferenceDBItem	proc	far
	uses	ax, bx
	.enter
	pushf
	mov	bx, ss:[bp].TRDBI_file
	call	ECVMCheckVMFile

	mov	ax, ss:[bp].TRDBI_group
	call	ECVMCheckVMBlockHandle
	
	;
	; We don't have any way of checking the item right now.
	;
	popf
	.leave
	ret
ECCheckTextReferenceDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTextReferenceHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a huge-array reference to some text.

CALLED BY:	ECCheckTextReference
PASS:		*ds:si	= Text instance
		ss:bp	= TextReferenceHugeArray
RETURN:		nothing
DESTROYED:	nothing (even flags are intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTextReferenceHugeArray	proc	far
	uses	ax, bx, di
	.enter
	pushf
	
	mov	bx, ss:[bp].TRHA_file
	call	ECVMCheckVMFile

	mov	ax, ss:[bp].TRHA_array
	call	ECVMCheckVMBlockHandle
	
	mov	di, ax
	call	ECCheckHugeArray		; Check the huge array

	popf
	.leave
	ret
ECCheckTextReferenceHugeArray	endp

			

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckVisTextReplaceParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check VisTextReplaceParameters to make sure they're valid.

CALLED BY:	ECSmallCheckVisTextReplaceParameters,
		ECLargeCheckVisTextReplaceParameters
PASS:		ss:bp	= VisTextReplaceParameters
		*ds:si	= Instance
		dx.ax	= Current number of bytes of text in the object
RETURN:		nothing
DESTROYED:	nothing (even flags are intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckVisTextReplaceParameters	proc	far
	uses	ax, dx, bp
	.enter
	pushf

	cmpdw	dxax, ss:[bp].VTRP_range.VTR_start
	ERROR_B	POSITION_FOR_CHANGE_IS_BEYOND_END_OF_TEXT
	
	cmpdw	dxax, ss:[bp].VTRP_range.VTR_end
	ERROR_B	CANNOT_DELETE_PAST_END_OF_OBJECT
	
	tstdw	ss:[bp].VTRP_insCount
	jz	afterRefCheck
	
	;
	; There is text to be inserted, so check to make sure it's kosher.
	;
	lea	bp, ss:[bp].VTRP_textReference
	call	ECCheckTextReference
afterRefCheck:

	popf
	.leave
	ret
ECCheckVisTextReplaceParameters	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSmallCheckVisTextReplaceParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that a VisTextReplaceParameters structure
		is valid for a modification to a small text object.

CALLED BY:	SmallReplaceText
PASS:		*ds:si	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		nothing
DESTROYED:	nothing (even flags are intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSmallCheckVisTextReplaceParameters	proc	far
	class	VisTextClass
	uses	ax, dx, di
	.enter
	pushf
	;
	; First check the high-words of the size/position parameters.
	;
	tst	ss:[bp].VTRP_range.VTR_start.high
	ERROR_NZ POSITION_HIGH_WORD_NON_ZERO_FOR_SMALL_TEXT_OBJECT
	tst	ss:[bp].VTRP_insCount.high
	ERROR_NZ INSERTION_COUNT_HIGH_WORD_NON_ZERO_FOR_SMALL_TEXT_OBJECT
	tst	ss:[bp].VTRP_range.VTR_end.high
	ERROR_NZ DELETION_COUNT_HIGH_WORD_NON_ZERO_FOR_SMALL_TEXT_OBJECT
	
	;
	; Now check the result against the maximum size.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di <- instance ptr
	mov	dx, ds:[di].VTI_maxLength	; dx <- maximum allowed size

	mov	di, ds:[di].VTI_text
	mov	di, ds:[di]			; ds:di <- text chunk ptr
	ChunkSizePtr	ds, di, ax		; ax <- text size
DBCS <	shr	ax, 1				; ax <- text length	>
	dec	ax				; Don't count the null

	push	ax				; Save current size
	add	ax, ss:[bp].VTRP_insCount.low	; ax <- size after changes
	sub	ax, ss:[bp].VTRP_range.VTR_end.low
	add	ax, ss:[bp].VTRP_range.VTR_start.low

	cmp	ax, dx
	ERROR_A	SIZE_CHANGE_WOULD_EXCEED_MAXLENGTH
	
	pop	ax				; Restore current size
	clr	dx				; dx.ax <- current size

	call	ECCheckVisTextReplaceParameters
	popf
	.leave
	ret
ECSmallCheckVisTextReplaceParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECLargeCheckVisTextReplaceParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that a VisTextReplaceParameters structure
		is valid for a modification to a large text object.

CALLED BY:	LargeReplaceText
PASS:		*ds:si	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		nothing
DESTROYED:	nothing (even flags are intact)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECLargeCheckVisTextReplaceParameters	proc	far
	uses	ax, dx
	.enter
	pushf
	call	LargeGetTextSize		; dx.ax <- size of object
	call	ECCheckVisTextReplaceParameters
	popf
	.leave
	ret
ECLargeCheckVisTextReplaceParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTextForInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that a block of text doesn't contain NULLs

CALLED BY:	InsertFrom*
PASS:		bp:si	= Pointer to the text
		cx	= Number of bytes to check
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTextForInsert	proc	far
	ret
ECCheckTextForInsert	endp

TextEC	ends
