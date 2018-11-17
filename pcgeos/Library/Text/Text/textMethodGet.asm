COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textMethodGet.asm

AUTHOR:		John Wedgwood, Nov 21, 1991

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/21/91	Initial revision

DESCRIPTION:
	Methods for getting text from the text object.

	$Id: textMethodGet.asm,v 1.1 97/04/07 11:18:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextInstance	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetTextRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a range of text.

CALLED BY:	via MSG_VIS_TEXT_GET_TEXT_RANGE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		ss:bp	= VisTextGetTextRangeParameters
RETURN:		dx.ax	= Number of chars actually copied
		cx/bp	= Return values depending on TextReferenceType
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:
	Check for zero range
	if (zero range && allocAlways) {
	    Allocate destination
	    quit
	}
	Allocate destination

	if ! (allocate || allocAlways) {
	    if (resizeDest) {
	    	Resize destination
	    }
	}

	Copy to destination

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetTextRange	method dynamic	VisTextClass, 
			MSG_VIS_TEXT_GET_TEXT_RANGE
EC <	cmp	ss:[bp].VTGTRP_textReference.TR_type, TextReferenceType	>
EC <	ERROR_AE VIS_TEXT_BAD_TEXT_REFERENCE_TYPE			>

	clr	bx			; No context
	call	TA_GetTextRange		; Convert the range
	
	;
	; The VisTextRange has been made 'real' but that doesn't mean that
	; the offsets contained in it are legal. It is OK to pass offsets
	; which are larger than the size of the text. These offsets are
	; mapped to legal values now.
	;
	call	TS_GetTextSize			; dx.ax <- size of object
	cmpdw	dxax, ss:[bp].VTGTRP_range.VTR_start
	jae	startOK
	movdw	ss:[bp].VTGTRP_range.VTR_start, dxax
startOK:
	
	cmpdw	dxax, ss:[bp].VTGTRP_range.VTR_end
	jae	endOK
	movdw	ss:[bp].VTGTRP_range.VTR_end, dxax
endOK:

	;
	; Compute the number of bytes to copy.
	;
	movdw	dxax, ss:[bp].VTGTRP_range.VTR_end
	subdw	dxax, ss:[bp].VTGTRP_range.VTR_start
					; dxax <- number of bytes to copy
	
	;
	; See if the caller wants something allocated anyway.
	;
	test	ss:[bp].VTGTRP_flags, mask VTGTRF_ALLOCATE_ALWAYS
	jnz	allocateDest		; Branch if allocating

	;
	; Check to see if there is a range to copy. If there isn't then we
	; can just skip to the end because the user doesn't want anything 
	; allocated. (We already checked for this case above).
	;
	tstdw	dxax
	jz	checkResize		; Branch if there is no range

	;
	; There is a range to copy. See if we want to allocate a destination
	;
	test	ss:[bp].VTGTRP_flags, mask VTGTRF_ALLOCATE
	jz	checkResize

allocateDest:
	;
	; We do want to allocate a destination.
	;
	push	bp			; Save frame ptr
	lea	bp, ss:[bp].VTGTRP_textReference
	call	AllocateDestBuffer	; Allocate text reference
	pop	bp			; Restore frame ptr

checkResize:
	;
	; Check to see if we want to resize the destination buffer down
	; to fit. We only do this if the buffer was passed in to us. Since
	; we alway allocate only as much as we need it's not an issue when
	; the buffer is our own.
	;
	test	ss:[bp].VTGTRP_flags, mask VTGTRF_ALLOCATE or \
				      mask VTGTRF_ALLOCATE_ALWAYS
	jnz	copyToDest		; Branch if it's our buffer
	
	;
	; It's not our buffer, check to see if the caller wants it resized.
	;
	test	ss:[bp].VTGTRP_flags, mask VTGTRF_RESIZE_DEST
	jz	copyToDest		; Branch if not resizing

	;
	; Sigh... resize the buffer to the size in dx.ax
	;
	push	bp			; Save frame ptr
	lea	bp, ss:[bp].VTGTRP_textReference
	call	ResizeDestBuffer
	pop	bp			; Restore frame ptr

copyToDest:
	;
	; ss:bp	= VisTextGetRangeParameters filled in
	; dx.ax	= Number of bytes to copy
	;
	call	ZeroHugeArray		; Zero the destination if it's a huge
					;    array.

	tstdw	dxax			; Check for nothing to copy
	jz	writeNull		; Branch if nothing to copy

copyBytes:
	push	bp			; Save frame ptr
	lea	bx, ss:[bp].VTGTRP_range
	lea	bp, ss:[bp].VTGTRP_textReference
	call	TS_GetTextRange		; Get text, fill in struct
					; dx.ax <- number of bytes copied
	pop	bp			; Restore frame ptr

quit:
	;
	; dx.ax	= Number of bytes copied.
	; bp	= Same as passed in
	;
	call	GetReturnValuesByType	; cx/bp <- return values

	ret


writeNull:
	;
	; There is no text. We need to stuff a null into the buffer in
	; one of two cases:
	;	- "allocate-always" bit is set
	;	- Neither of the allocate bits is set
	;
	test	ss:[bp].VTGTRP_flags, mask VTGTRF_ALLOCATE_ALWAYS
	jnz	addNullToBuffer

	test	ss:[bp].VTGTRP_flags, mask VTGTRF_ALLOCATE or \
				      mask VTGTRF_ALLOCATE_ALWAYS
	jnz	quit

addNullToBuffer:
	;
	; Either the allocate-always bit is set or neither alloc bit is set.
	; What this means is that there is a buffer here somewhere and
	; we can write a null to the first byte.
	;
	; Conveniently since we have a buffer we can just call "get-text"
	; and it will do nothing but add the null...
	;
	jmp	copyBytes		; Do it man
VisTextGetTextRange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ZeroHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the destination is a huge-array make it zero sized.

CALLED BY:	VisTextGetTextRange
PASS:		ss:bp	= VisTextGetTextRangeParameters
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ZeroHugeArray	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	cmp	ss:[bp].VTGTRP_textReference.TR_type, TRT_HUGE_ARRAY
	jnz	done

	mov	bx, ss:[bp].VTGTRP_textReference.TR_ref.TRU_hugeArray.TRHA_file
							; bx <- file handle
EC <	call	ECVMCheckVMFile					>

	mov	di, ss:[bp].VTGTRP_textReference.TR_ref.TRU_hugeArray.TRHA_array

deleteLoop:
	call	HugeArrayGetCount		;dx.ax = count
	tstdw	dxax
	jz	done
	
	clrdw	dxax
	mov	cx, 0xffff
	call	HugeArrayDelete
	jmp	deleteLoop
done:
	.leave
	ret
ZeroHugeArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateDestBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a buffer for the text to be put into.

CALLED BY:	VisTextGetRange
PASS:		ss:bp	= TextReference
		dx.ax	= # of chars to allocate buffer to (not counting NULL)
		ds	= pointing to segment containing text object 

RETURN:		ss:bp	= TextReference filled in completely
		ds 	= fixed up, if necessary

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateDestBuffer	proc	near
	uses	ax, bx, dx, bp
	.enter
	incdw	dxax			; Allow space for NULL
DBCS <	shldw	dxax			; dx:ax <- size of buffer	>

	mov	bx, ss:[bp].TR_type	; bx <- reference type

	lea	bp, ss:[bp].TR_ref	; ss:bp <- reference

	push	ds:[LMBH_handle]
	call	cs:allocDestHandler[bx]	; Call the appropriate handler
	pop	bx
	call	MemDerefDS
	.leave
	ret
AllocateDestBuffer	endp

allocDestHandler	word	\
	offset cs:AllocDestBufferPointer,	; TRT_POINTER
	offset cs:AllocDestBufferSegmentChunk,	; TRT_SEGMENT_CHUNK
	offset cs:AllocDestBufferBlockChunk,	; TRT_BLOCK_CHUNK
	offset cs:AllocDestBufferBlock,		; TRT_BLOCK
	offset cs:AllocDestBufferVMBlock,	; TRT_VM_BLOCK
	offset cs:AllocDestBufferDBItem,	; TRT_DB_ITEM
	offset cs:AllocDestBufferHugeArray	; TRT_HUGE_ARRAY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocDestBufferPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a fatal-error, you can't allocate this buffer.

CALLED BY:	AllocateDestBuffer via allocDestHandler table
PASS:		ss:bp	= TextReferencePointer
		dx.ax	= Size of buffer
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocDestBufferPointer	proc	near
EC <	ERROR	CANNOT_ALLOCATE_SPACE_FOR_POINTER_REFERENCE	>
NEC <	ret							>
AllocDestBufferPointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocDestBufferSegmentChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a chunk in a given lmem segment.

CALLED BY:	AllocateDestBuffer via allocDestHandler table
PASS:		ss:bp	= TextReferenceSegmentChunk
		dx.ax	= Size of buffer
RETURN:		TRSC_chunk field filled in

DESTROYED:	ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocDestBufferSegmentChunk	proc	near
	uses	ax, cx
	.enter
	;
	; Check that the size isn't >64K
	;
EC <	tst	dx						>
EC <	ERROR_NZ CANNOT_ALLOCATE_CHUNK_TO_SIZE_OVER_64K		>

	;
	; Check that the segment is valid
	;
EC <	push	ax						>
EC <	mov	ax, ss:[bp].TRSC_segment			>
EC <	call	ECCheckSegment					>
EC <	pop	ax						>
	
	;
	; Allocate the space
	;
	mov	ds, ss:[bp].TRSC_segment	; ds <- segment of heap

	mov	cx, ax				; cx <- size
	mov	al, mask OCF_DIRTY		; al <- flags
	call	LMemAlloc			; ax <- chunk handle
						; ds <- new segment
	;
	; Stuff the segment and chunk back into the stack frame
	;
	mov	ss:[bp].TRSC_segment, ds
	mov	ss:[bp].TRSC_chunk,   ax
	.leave
	ret
AllocDestBufferSegmentChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocDestBufferBlockChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a chunk in a given lmem segment.

CALLED BY:	AllocateDestBuffer via allocDestHandler table
PASS:		ss:bp	= TextReferenceBlockChunk
		dx.ax	= Size of buffer
RETURN:		TRBC_chunk field filled in

DESTROYED:	ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocDestBufferBlockChunk	proc	near
	uses	ax, bx, cx
	.enter
	;
	; Check that the size isn't >64K
	;
	push	ax				; Save size.low
EC <	tst	dx						>
EC <	ERROR_NZ CANNOT_ALLOCATE_CHUNK_TO_SIZE_OVER_64K		>

	mov	bx, ss:[bp].TRBC_ref.handle	; bx <- block handle
EC <	call	ECCheckMemHandle				>
	
	call	MemLock				; ax <- segment address
EC <	call	ECCheckSegment					>

	;
	; Allocate the space
	;
	mov	ds, ax				; ds <- segment of heap

	pop	cx				; cx <- size
	mov	al, mask OCF_DIRTY		; al <- flags
	call	LMemAlloc			; ax <- chunk handle
						; ds <- new segment
	;
	; Stuff the segment and chunk back into the stack frame
	;
	mov	ss:[bp].TRBC_ref.chunk, ax
	
	call	MemUnlock			; Release the block
	.leave
	ret
AllocDestBufferBlockChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocDestBufferBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block for text.

CALLED BY:	AllocateDestBuffer via allocDestHandler table
PASS:		ss:bp	= TextReferenceBlock
		dx.ax	= Size of buffer
RETURN:		TRB_handle field filled in
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocDestBufferBlock	proc	near
	uses	ax, bx, cx
	.enter
EC <	tst	dx						>
EC <	ERROR_NZ CANNOT_ALLOCATE_BLOCK_TO_SIZE_OVER_64K		>

	mov	cx, ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc			; bx <- handle
	mov	ss:[bp].TRB_handle, bx		; Save new handle
	.leave
	ret
AllocDestBufferBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocDestBufferVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a vm-block for text.

CALLED BY:	AllocateDestBuffer via allocDestHandler table
PASS:		ss:bp	= TextReferenceVMBlock
		dx.ax	= Size of buffer
RETURN:		TRVMB_block field filled in
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocDestBufferVMBlock	proc	near
	uses	ax, bx, cx
	.enter
	
EC <	tst	dx						>
EC <	ERROR_NZ CANNOT_ALLOCATE_VM_BLOCK_TO_SIZE_OVER_64K	>
	
	mov	bx, ss:[bp].TRVMB_file		; bx <- file handle
EC <	call	ECVMCheckVMFile				>

	mov	cx, ax				; cx <- Number of bytes
	clr	ax				; No id number
	
	call	VMAlloc				; ax <- new vm block
	
	mov	ss:[bp].TRVMB_block, ax		; Save new handle
	
	.leave
	ret
AllocDestBufferVMBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocDestBufferDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a db-item for text.

CALLED BY:	AllocateDestBuffer via allocDestHandler table
PASS:		ss:bp	= TextReferenceDBItem
		dx.ax	= Size of buffer
RETURN:		TRDBI_group/item fields filled in
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocDestBufferDBItem	proc	near
	uses	ax, bx, cx, di
	.enter

EC <	tst	dx						>
EC <	ERROR_NZ CANNOT_ALLOCATE_DB_ITEM_TO_SIZE_OVER_64K	>
	
	mov	bx, ss:[bp].TRDBI_file		; bx <- file handle
EC <	call	ECVMCheckVMFile				>

	mov	cx, ax				; cx <- Number of bytes
	mov	ax, ss:[bp].TRDBI_group		; ax <- group
	
	call	DBAlloc
	
	mov	ss:[bp].TRDBI_group, ax		; Save group
	mov	ss:[bp].TRDBI_item, di		; Save item
	
	.leave
	ret
AllocDestBufferDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocDestBufferHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a db-item for text.

CALLED BY:	AllocateDestBuffer via allocDestHandler table
PASS:		ss:bp	= TextReferenceHugeArray
		dx.ax	= Size of buffer
RETURN:		TRHA_array field filled in
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocDestBufferHugeArray	proc	near
SBCS <	uses	bx, cx, di						>
DBCS <	uses	bx, cx, di, ax, dx					>
	.enter
	;
	; Create an empty array
	;
DBCS <	shrdw	dxax				; dxax <- # of chars	>
	mov	bx, ss:[bp].TRHA_file		; bx <- file handle
EC <	call	ECVMCheckVMFile					>

SBCS <	mov	cx, 1				; cx <- element size	>
DBCS <	mov	cx, (size wchar)		; cx <- element size	>
	clr	di				; No extra space in header
	call	HugeArrayCreate			; di <- huge array handle
	
	mov	ss:[bp].TRHA_array, di		; Save the new array
	
	.leave
	ret
AllocDestBufferHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeDestBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a destination buffer.

CALLED BY:	VisTextGetRange
PASS:		ss:bp	= TextReference
		dx.ax	= # of chars to reallocate it to (not counting NULL)
		ds	= segment containing text object

RETURN:		ds	= fixed up to point at same segment, if
			  necessary

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeDestBuffer	proc	near
	uses	ax, bx, dx, bp
	.enter
	incdw	dxax				; Allow space for NULL
DBCS <	shldw	dxax				; dxax <- size of buffer >

	mov	bx, ss:[bp].TR_type		; bx <- reference type

	lea	bp, ss:[bp].TR_ref		; ss:bp <- reference

	
	push	ds:[LMBH_handle]
	call	cs:resizeDestHandler[bx]	; Call the appropriate handler
	pop	bx
	call	MemDerefDS
	.leave
	ret
ResizeDestBuffer	endp

resizeDestHandler	word	\
	offset cs:ResizeDestBufferPointer,	; TRT_POINTER
	offset cs:ResizeDestBufferSegmentChunk,	; TRT_SEGMENT_CHUNK
	offset cs:ResizeDestBufferBlockChunk,	; TRT_BLOCK_CHUNK
	offset cs:ResizeDestBufferBlock,	; TRT_BLOCK
	offset cs:ResizeDestBufferVMBlock,	; TRT_VM_BLOCK
	offset cs:ResizeDestBufferDBItem,	; TRT_DB_ITEM
	offset cs:ResizeDestBufferHugeArray	; TRT_HUGE_ARRAY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeDestBufferPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a fatal-error, you can't resize this buffer.

CALLED BY:	ResizeDestBuffer via resizeDestHandler table
PASS:		ss:bp	= TextReferencePointer
		dx.ax	= Size to reallocate to
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeDestBufferPointer	proc	near
EC <	ERROR	CANNOT_RESIZE_A_POINTER_REFERENCE			>
NEC <	ret								>
ResizeDestBufferPointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeDestBufferSegmentChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a chunk in a given heap

CALLED BY:	ResizeDestBuffer via resizeDestHandler table
PASS:		ss:bp	= TextReferenceSegmentChunk
		dx.ax	= Size to reallocate to
RETURN:		nothing

DESTROYED:	ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeDestBufferSegmentChunk	proc	near
	uses	ax, cx
	.enter
EC <	tst	dx						>
EC <	ERROR_NZ CANNOT_RESIZE_CHUNK_TO_SIZE_OVER_64K		>

	mov	cx, ax				; cx <- new size
	mov	ds, ss:[bp].TRSC_segment	; ds <- segment
	mov	ax, ss:[bp].TRSC_chunk		; ax <- chunk
	call	LMemReAlloc			; Resize the thing
	
	;
	; Since we are guaranteed to have resized the thing smaller or not at
	; all we don't need to worry about saving the segment again.
	;
	.leave
	ret
ResizeDestBufferSegmentChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeDestBufferBlockChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a chunk in a given heap

CALLED BY:	ResizeDestBuffer via resizeDestHandler table
PASS:		ss:bp	= TextReferenceBlockChunk
		dx.ax	= Size to reallocate to
RETURN:		nothing

DESTROYED:	ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeDestBufferBlockChunk	proc	near
	uses	ax, bx, cx
	.enter
EC <	tst	dx						>
EC <	ERROR_NZ CANNOT_RESIZE_CHUNK_TO_SIZE_OVER_64K		>

	mov	cx, ax				; cx <- new size

	mov	bx, ss:[bp].TRBC_ref.handle
	call	ObjLockObjBlock			; ax <- segment
	mov	ds, ax				; ds <- segment

	mov	ax, ss:[bp].TRSC_chunk		; ax <- chunk
	call	LMemReAlloc			; Resize the thing
	
	call	MemUnlock			; Release the block
	.leave
	ret
ResizeDestBufferBlockChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeDestBufferBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a block

CALLED BY:	ResizeDestBuffer via resizeDestHandler table
PASS:		ss:bp	= TextReferenceBlock
		dx.ax	= Size to reallocate to
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeDestBufferBlock	proc	near
	uses	ax, bx, cx
	.enter
EC <	tst	dx						>
EC <	ERROR_NZ CANNOT_RESIZE_BLOCK_TO_SIZE_OVER_64K		>

	clr	cl				; HeapFlags
	mov	ch, mask HAF_NO_ERR		; HeapAllocFlags

	mov	bx, ss:[bp].TRB_handle		; bx <- handle
	call	MemReAlloc			; Make me smaller (or same size)
	.leave
	ret
ResizeDestBufferBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeDestBufferVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a vm-block

CALLED BY:	ResizeDestBuffer via resizeDestHandler table
PASS:		ss:bp	= TextReferenceVMBlock
		dx.ax	= Size to reallocate to
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeDestBufferVMBlock	proc	near
	uses	ax, bx, cx, bp
	.enter
	
EC <	tst	dx						>
EC <	ERROR_NZ CANNOT_RESIZE_VMBLOCK_TO_SIZE_OVER_64K		>

	;
	; Lock the vm-block to get a memory block handle
	;
	push	ax				; Save size
	mov	bx, ss:[bp].TRVMB_file		; bx <- file
	mov	ax, ss:[bp].TRVMB_block		; ax <- block
	call	VMLock				; ax <- segment
						; bp <- block
	pop	ax				; Restore size

	;
	; ax	= New size
	; bp	= Block handle
	;
	mov	bx, bp				; bx <- block handle
	clr	cl				; HeapFlags
	mov	ch, mask HAF_NO_ERR		; HeapAllocFlags
	call	MemReAlloc			; Resize the block

	call	VMUnlock			; Release the block
	
	.leave
	ret
ResizeDestBufferVMBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeDestBufferDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a db-item

CALLED BY:	ResizeDestBuffer via resizeDestHandler table
PASS:		ss:bp	= TextReferenceDBItem
		dx.ax	= Size to reallocate to
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeDestBufferDBItem	proc	near
	uses	ax, bx, cx, di
	.enter
	
EC <	tst	dx						>
EC <	ERROR_NZ CANNOT_RESIZE_DBITEM_TO_SIZE_OVER_64K		>

	mov	cx, ax				; cx <- size
	mov	bx, ss:[bp].TRDBI_file		; bx <- file
	mov	ax, ss:[bp].TRDBI_group		; ax <- group
	mov	di, ss:[bp].TRDBI_item		; di <- item
	call	DBReAlloc			; Resize the item
	
	.leave
	ret
ResizeDestBufferDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeDestBufferHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a huge-array

CALLED BY:	ResizeDestBuffer via resizeDestHandler table
PASS:		ss:bp	= TextReferenceHugeArray
		dx.ax	= Size to reallocate to
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeDestBufferHugeArray	proc	near
EC <	ERROR	RESIZING_A_HUGE_ARRAY_DOES_NOT_MAKE_SENSE	>
NEC <	ret							>
ResizeDestBufferHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetReturnValuesByType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get return values for VisTextGetTextRange.

CALLED BY:	VisTextGetTextRange
PASS:		ss:bp	= VisTextGetTextRangeParameters
RETURN:		cx/bp	= Return values according to the TextReferenceType
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetReturnValuesByType	proc	near
	uses	bx
	.enter
	lea	bp, ss:[bp].VTGTRP_textReference
	mov	bx, ss:[bp].TR_type	; bx <- reference type
	lea	bp, ss:[bp].TR_ref	; ss:bp <- reference
	call	cs:returnValueHandler[bx]
	.leave
	ret
GetReturnValuesByType	endp

returnValueHandler	word	\
	offset cs:ReturnPointer,	; TRT_POINTER
	offset cs:ReturnSegmentChunk,	; TRT_SEGMENT_CHUNK
	offset cs:ReturnBlockChunk,	; TRT_BLOCK_CHUNK
	offset cs:ReturnBlock,		; TRT_BLOCK
	offset cs:ReturnVMBlock,	; TRT_VM_BLOCK
	offset cs:ReturnDBItem,		; TRT_DB_ITEM
	offset cs:ReturnHugeArray	; TRT_HUGE_ARRAY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy cx and bp, the return values for this type are
		meaningless.

CALLED BY:	AllocDestBuffer via allocDestHandler
PASS:		ss:bp	= TextReferencePointer
RETURN:		cx/bp	= Destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnPointer	proc	near
EC <	mov	cx, -1					>
EC <	mov	bp, -1					>
	ret
ReturnPointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnSegmentChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the chunk handle in cx.

CALLED BY:	AllocDestBuffer via allocDestHandler
PASS:		ss:bp	= TextReferenceSegmentChunk
RETURN:		cx	= Chunk handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnSegmentChunk	proc	near
	mov	cx, ss:[bp].TRSC_chunk
EC <	mov	bp, -1						>
	ret
ReturnSegmentChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnBlockChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the chunk handle in cx.

CALLED BY:	AllocDestBuffer via allocDestHandler
PASS:		ss:bp	= TextReferenceBlockChunk
RETURN:		cx	= Chunk handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnBlockChunk	proc	near
	mov	cx, ss:[bp].TRBC_ref.chunk
EC <	mov	bp, -1					>
	ret
ReturnBlockChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the block handle in cx.

CALLED BY:	AllocDestBuffer via allocDestHandler
PASS:		ss:bp	= TextReferenceBlock
RETURN:		cx	= Block handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnBlock	proc	near
	mov	cx, ss:[bp].TRB_handle
EC <	mov	bp, -1						>
	ret
ReturnBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the vm-block handle in cx.

CALLED BY:	AllocDestBuffer via allocDestHandler
PASS:		ss:bp	= TextReferenceVMBlock
RETURN:		cx	= VM-block handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnVMBlock	proc	near
	mov	cx, ss:[bp].TRVMB_block
EC <	mov	bp, -1						>
	ret
ReturnVMBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the db-item group/item in cx/bp

CALLED BY:	AllocDestBuffer via allocDestHandler
PASS:		ss:bp	= TextReferenceDBItem
RETURN:		cx	= Group
		bp	= Item
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnDBItem	proc	near
	mov	cx, ss:[bp].TRDBI_group
	mov	bp, ss:[bp].TRDBI_item
	ret
ReturnDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the huge array in cx.

CALLED BY:	AllocDestBuffer via allocDestHandler
PASS:		ss:bp	= TextReferenceHugeArray
RETURN:		cx	= Huge array
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnHugeArray	proc	near
	mov	cx, ss:[bp].TRHA_array
EC <	mov	bp, -1						>
	ret
ReturnHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetAllPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the text from a text object into a buffer referenced
		by a pointer.

CALLED BY:	via MSG_VIS_TEXT_GET_ALL_PTR
PASS:		*ds:si	= Instance ptr
		dx:bp	= Pointer to the buffer
RETURN:		cx	= String length not counting the null
		ax	= Size of the text (not counting the NULL)
		dx, bp	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetAllPtr	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_ALL_PTR
	uses	dx, bp
	.enter
	clr	cl			; cl <- VisTextGetTextRangeFlags
	xchg	dx, bp			; Offset first, then segment
	mov	ax, TRT_POINTER		; ax <- TextReferenceType
	call	GetAllIntoSomething	; dx.ax <- size
	
	mov	cx, ax			; Return size in cx
	.leave
	ret
VisTextGetAllPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetAllOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the text from a text object into a buffer referenced
		by a optr.

CALLED BY:	via MSG_VIS_TEXT_GET_ALL_OPTR
PASS:		*ds:si	= Instance ptr
		^ldx:bp	= Pointer to the buffer
		bp	= 0 to allocate the chunk
RETURN:		cx	= Chunk that the text was placed in
		ax	= String size
		dx, bp	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetAllOptr	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_ALL_OPTR
	uses	dx, bp
	.enter
	mov	cl, mask VTGTRF_RESIZE_DEST
	tst	bp			; Check for allocate
	jnz	gotFlags		; Branch if chunk exists
	or	cl, mask VTGTRF_ALLOCATE_ALWAYS
gotFlags:

	xchg	dx, bp			; Block first, then chunk
	mov	ax, TRT_OPTR		; ax <- TextReferenceType
	call	GetAllIntoSomething	; bx <- chunk
	
	mov	cx, bx			; Return chunk in cx
	.leave
	ret
VisTextGetAllOptr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetAllBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the text from a text object into a buffer referenced
		by a block.

CALLED BY:	via MSG_VIS_TEXT_GET_ALL_BLOCK
PASS:		*ds:si	= Instance ptr
		^hdx	= Pointer to the buffer
		dx	= 0 to allocate the block
RETURN:		cx	= Block that the text was placed in
		ax	= Size of the text (not counting the NULL)
		dx, bp	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetAllBlock	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_ALL_BLOCK
	uses	dx, bp
	.enter
	mov	cl, mask VTGTRF_RESIZE_DEST
	tst	dx			; Check for allocate
	jnz	gotFlags		; Branch if block exists
	or	cl, mask VTGTRF_ALLOCATE_ALWAYS
gotFlags:

	mov	ax, TRT_BLOCK		; ax <- TextReferenceType
	call	GetAllIntoSomething	; bx <- block
	
	mov	cx, bx			; Return block in cx
	.leave
	ret
VisTextGetAllBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetAllVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the text from a text object into a buffer referenced
		by a vm-block.

CALLED BY:	via MSG_VIS_TEXT_GET_ALL_VM_BLOCK
PASS:		*ds:si	= Instance ptr
		^vdx:bp	= Pointer to the buffer
		bp	= 0 to allocate the vm-block
RETURN:		cx	= VM-Block that the text was placed in
		ax	= Size of the text (not counting the NULL)
		dx, bp	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetAllVMBlock	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_ALL_VM_BLOCK
	uses	dx, bp
	.enter
	mov	cl, mask VTGTRF_RESIZE_DEST
	tst	bp			; Check for allocate
	jnz	gotFlags		; Branch if vm-block exists
	or	cl, mask VTGTRF_ALLOCATE_ALWAYS
gotFlags:

	mov	ax, TRT_VM_BLOCK	; ax <- TextReferenceType
	call	GetAllIntoSomething	; bp <- vm-block
	
	mov	cx, bp			; Return vm-block in cx
	.leave
	ret
VisTextGetAllVMBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetAllDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the text from a text object into a buffer referenced
		by a db-item.

CALLED BY:	via MSG_VIS_TEXT_GET_ALL_DB_ITEM
PASS:		*ds:si	= Instance ptr
		dx	= File
		bp	= Group (cannot be ungrouped)
		cx	= Item
			= 0 to allocate the item
RETURN:		cx	= Item that the text was placed in
		bp	= Group that the text was placed in
		ax	= Size of the text (not counting the NULL)
		dx	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetAllDBItem	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_ALL_DB_ITEM
	uses	dx
	.enter
	mov	di, cx			; Pass item in di

	mov	cl, mask VTGTRF_RESIZE_DEST
	tst	di			; Check for allocate
	jnz	gotFlags		; Branch if item exists
	or	cl, mask VTGTRF_ALLOCATE_ALWAYS
gotFlags:

	xchg	bp, di			; Item first, then group
	mov	ax, TRT_DB_ITEM		; ax <- TextReferenceType
	call	GetAllIntoSomething	; bp <- item
	
	mov	cx, bp			; Return item in cx
	mov	bp, di			; Return group in bp
	.leave
	ret
VisTextGetAllDBItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetAllHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the text from a text object into a buffer referenced
		by a huge-array.

CALLED BY:	via MSG_VIS_TEXT_GET_ALL_HUGE_ARRAY
PASS:		*ds:si	= Instance ptr
		dx	= File
		bp	= Array handle
			= 0 to allocate the array
RETURN:		cx	= Array that the text was placed in
		dx.ax	= Size of the text (not counting the NULL)
		bp	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetAllHugeArray	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_ALL_HUGE_ARRAY
	uses	bp
	.enter
	mov	cl, mask VTGTRF_RESIZE_DEST
	tst	bp			; Check for allocate
	jnz	gotFlags		; Branch if item exists
	or	cl, mask VTGTRF_ALLOCATE_ALWAYS
gotFlags:

	mov	ax, TRT_HUGE_ARRAY	; ax <- TextReferenceType
	call	GetAllIntoSomething	; bp <- array
	
	mov	cx, bp			; Return item in cx
	.leave
	ret
VisTextGetAllHugeArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAllIntoSomething
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the text from an object into a destination buffer.

CALLED BY:	VisTextGetAll*
PASS:		*ds:si	= Instance ptr
		ax	= TextReferenceType
		cl	= VisTextGetTextRangeFlags
		dx,bp,di= TextReference
RETURN:		dx.ax	= Number of bytes copied
		bx,bp,di= TextReference after the call
DESTROYED:	everything else

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAllIntoSomething	proc	far
	mov	bx, bp			; bx <- parameter passed in bp
	
	sub	sp, size VisTextGetTextRangeParameters
	mov	bp, sp			; ss:bp <- frame
	
	clrdw	ss:[bp].VTGTRP_range.VTR_start
	movdw	ss:[bp].VTGTRP_range.VTR_end,   TEXT_ADDRESS_PAST_END

	mov	ss:[bp].VTGTRP_flags, cl
	

	;
	; Fill in the frame...
	;
	mov	ss:[bp].VTGTRP_textReference.TR_type, ax
	mov	{word} ss:[bp].VTGTRP_textReference.TR_ref, dx
	mov	{word} ss:[bp].VTGTRP_textReference.TR_ref[2], bx
	mov	{word} ss:[bp].VTGTRP_textReference.TR_ref[4], di
	
	;
	; Do the get
	;
	push	bp
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
	call	ObjCallInstanceNoLock
	pop	bp
	
	mov	bx, {word} ss:[bp].VTGTRP_textReference.TR_ref
	mov	di, {word} ss:[bp].VTGTRP_textReference.TR_ref[4]
	mov	bp, {word} ss:[bp].VTGTRP_textReference.TR_ref[2]

	add	sp, size VisTextGetTextRangeParameters
	ret
GetAllIntoSomething	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetSelectionPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection from a text object into a buffer referenced
		by a pointer.

CALLED BY:	via MSG_VIS_TEXT_GET_SELECTION_PTR
PASS:		*ds:si	= Instance ptr
		dx:bp	= Pointer to the buffer
RETURN:		cx	= String length not counting the null
		ax	= Size of the text (not counting the NULL)
		dx, bp	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetSelectionPtr	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_SELECTION_PTR
	uses	dx, bp
	.enter
	clr	cl			; cl <- VisTextGetTextRangeFlags
	xchg	dx, bp			; Offset first, then segment
	mov	ax, TRT_POINTER		; ax <- TextReferenceType
	call	GetSelectionIntoSomething	; dx.ax <- size
	
	mov	cx, ax			; Return size in cx
	.leave
	ret
VisTextGetSelectionPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetSelectionOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection from a text object into a buffer referenced
		by a optr.

CALLED BY:	via MSG_VIS_TEXT_GET_SELECTION_OPTR
PASS:		*ds:si	= Instance ptr
		^ldx:bp	= Pointer to the buffer
		bp	= 0 to allocate the chunk
RETURN:		cx	= Chunk that the text was placed in
		ax	= Size of the text (not counting the NULL)
		dx, bp	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetSelectionOptr	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_SELECTION_OPTR
	uses	dx, bp
	.enter
	mov	cl, mask VTGTRF_RESIZE_DEST
	tst	bp			; Check for allocate
	jnz	gotFlags		; Branch if chunk exists
	or	cl, mask VTGTRF_ALLOCATE_ALWAYS
gotFlags:

	xchg	dx, bp			; Chunk first, then block
	mov	ax, TRT_OPTR		; ax <- TextReferenceType
	call	GetSelectionIntoSomething	; bx <- chunk
	
	mov	cx, bx			; Return chunk in cx
	.leave
	ret
VisTextGetSelectionOptr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetSelectionBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection from a text object into a buffer referenced
		by a block.

CALLED BY:	via MSG_VIS_TEXT_GET_SELECTION_BLOCK
PASS:		*ds:si	= Instance ptr
		^hdx	= Pointer to the buffer
		dx	= 0 to allocate the block
RETURN:		cx	= Block that the text was placed in
		ax	= Size of the text (not counting the NULL)
		dx, bp	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetSelectionBlock	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_SELECTION_BLOCK
	uses	dx, bp
	.enter
	mov	cl, mask VTGTRF_RESIZE_DEST
	tst	dx			; Check for allocate
	jnz	gotFlags		; Branch if block exists
	or	cl, mask VTGTRF_ALLOCATE_ALWAYS
gotFlags:

	mov	ax, TRT_BLOCK		; ax <- TextReferenceType
	call	GetSelectionIntoSomething	; bx <- block
	
	mov	cx, bx			; Return block in cx
	.leave
	ret
VisTextGetSelectionBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetSelectionVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection from a text object into a buffer referenced
		by a vm-block.

CALLED BY:	via MSG_VIS_TEXT_GET_SELECTION_VM_BLOCK
PASS:		*ds:si	= Instance ptr
		^vdx:bp	= Pointer to the buffer
		bp	= 0 to allocate the vm-block
RETURN:		cx	= VM-Block that the text was placed in
		ax	= Size of the text (not counting the NULL)
		dx, bp	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetSelectionVMBlock	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_SELECTION_VM_BLOCK
	uses	dx, bp
	.enter
	mov	cl, mask VTGTRF_RESIZE_DEST
	tst	bp			; Check for allocate
	jnz	gotFlags		; Branch if vm-block exists
	or	cl, mask VTGTRF_ALLOCATE_ALWAYS
gotFlags:

	mov	ax, TRT_VM_BLOCK	; ax <- TextReferenceType
	call	GetSelectionIntoSomething	; bp <- vm-block
	
	mov	cx, bp			; Return vm-block in cx
	.leave
	ret
VisTextGetSelectionVMBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetSelectionDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection from a text object into a buffer referenced
		by a db-item.

CALLED BY:	via MSG_VIS_TEXT_GET_SELECTION_DB_ITEM
PASS:		*ds:si	= Instance ptr
		dx	= File
		bp	= Group (cannot be ungrouped)
		cx	= Item
			= 0 to allocate the item
RETURN:		cx	= Item that the text was placed in
		bp 	= Group that the text was placed in
		ax	= Size of the text (not counting the NULL)
		
		dx 	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetSelectionDBItem	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_SELECTION_DB_ITEM
	uses	dx
	.enter
	mov	di, cx			; Pass item in di

	mov	cl, mask VTGTRF_RESIZE_DEST
	tst	di			; Check for allocate
	jnz	gotFlags		; Branch if item exists
	or	cl, mask VTGTRF_ALLOCATE_ALWAYS
gotFlags:

	xchg	bp, di			; Item first, then group
	mov	ax, TRT_DB_ITEM		; ax <- TextReferenceType
	call	GetSelectionIntoSomething ; bp <- item
	
	mov	cx, bp			; Return item in cx
	mov	bp, di			; Return group in bp
	.leave
	ret
VisTextGetSelectionDBItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetSelectionHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection from a text object into a buffer referenced
		by a huge-array.

CALLED BY:	via MSG_VIS_TEXT_GET_SELECTION_HUGE_ARRAY
PASS:		*ds:si	= Instance ptr
		dx	= File
		bp	= Array handle
			= 0 to allocate the array
RETURN:		cx	= Array that the text was placed in
		dx.ax	= Size of the text (not counting the NULL)
		bp	= Unchanged
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetSelectionHugeArray	method dynamic	VisTextClass,
			MSG_VIS_TEXT_GET_SELECTION_HUGE_ARRAY
	uses	bp
	.enter
	mov	cl, mask VTGTRF_RESIZE_DEST
	tst	bp			; Check for allocate
	jnz	gotFlags		; Branch if item exists
	or	cl, mask VTGTRF_ALLOCATE_ALWAYS
gotFlags:

	mov	ax, TRT_HUGE_ARRAY	; ax <- TextReferenceType
	call	GetSelectionIntoSomething ; bp <- array
	
	mov	cx, bp			; Return item in cx
	.leave
	ret
VisTextGetSelectionHugeArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReturnSelectionBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get selection text in a block and return it to 'object'

CALLED BY:	MSG_VIS_TEXT_RETURN_SELECTION_BLOCK

PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ds:bx	= VisTextClass object (same as *ds:si)
		es 	= segment of VisTextClass
		ax	= message #
		^lcx:dx	= object requesting selection
		bp	= message to send to object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/13/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReturnSelectionBlock	method dynamic VisTextClass, 
					MSG_VIS_TEXT_RETURN_SELECTION_BLOCK
	push	cx, dx, bp
	mov	ax, MSG_VIS_TEXT_GET_SELECTION_BLOCK
	clr	dx			; allocate a new block
	call	ObjCallInstanceNoLock	; ^hcx = block of text
	pop	bx, si, ax

	mov	di, mask MF_CALL
	GOTO	ObjMessage

VisTextReturnSelectionBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectionIntoSomething
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection from an object into a destination buffer.

CALLED BY:	VisTextGetSelection*
PASS:		*ds:si	= Instance ptr
		ax	= TextReferenceType
		cl	= VisTextGetTextRangeFlags
		dx,bp,di= TextReference
RETURN:		dx.ax	= Number of bytes copied
		bx,bp,di= TextReference after the call
DESTROYED:	everything else

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectionIntoSomething	proc	far
	mov	bx, bp			; bx <- parameter passed in bp
	
	sub	sp, size VisTextGetTextRangeParameters
	mov	bp, sp			; ss:bp <- frame
	
	mov	ss:[bp].VTGTRP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION

	mov	ss:[bp].VTGTRP_flags, cl
	

	;
	; Fill in the frame...
	;
	mov	ss:[bp].VTGTRP_textReference.TR_type, ax
	mov	{word} ss:[bp].VTGTRP_textReference.TR_ref, dx
	mov	{word} ss:[bp].VTGTRP_textReference.TR_ref[2], bx
	mov	{word} ss:[bp].VTGTRP_textReference.TR_ref[4], di
	
	;
	; Do the get
	;
	push	bp
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
	call	ObjCallInstanceNoLock
	pop	bp
	
	mov	bx, {word} ss:[bp].VTGTRP_textReference.TR_ref
	mov	di, {word} ss:[bp].VTGTRP_textReference.TR_ref[4]
	mov	bp, {word} ss:[bp].VTGTRP_textReference.TR_ref[2]

	add	sp, size VisTextGetTextRangeParameters
	ret
GetSelectionIntoSomething	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStartingAtPositionRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the range of text to get if CL_STARTING_AT_POSITION is
		passed.

CALLED BY:	GLOBAL
PASS:		bp - # chars to get
		dx.ax - GCP_position
RETURN:		(dx.ax), (cx.bx) - text range to get
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStartingAtPositionRange	proc	near
	.enter
	movdw	cxbx, dxax
	call	TS_GetTextSize
	cmpdw	cxbx, dxax
	jae	10$
	movdw	dxax, cxbx		;DX.AX = MIN(startPos,endOfText)
10$:
	movdw	cxbx, dxax		;CX.BX <- starting position
	add	bx, bp
	adc	cx, 0			;CX.BX = end of range
EC <	ERROR_C	BAD_CONTEXT_POSITION					>

;	Clip range to text bounds

	pushdw	dxax
	call	TS_GetTextSize
	cmpdw	cxbx, dxax
	jbe	20$
	movdw	cxbx, dxax
20$:
	popdw	dxax
	.leave
	ret
GetStartingAtPositionRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEndingAtPositionRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the range of text to get if CL_ENDING_AT_POSITION is
		passed.

CALLED BY:	GLOBAL
PASS:		bp - # chars to get
		dx.ax - GCP_position
RETURN:		(dx.ax), (cx.bx) - text range to get
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetEndingAtPositionRange	proc	near
	.enter
	movdw	cxbx, dxax
	call	TS_GetTextSize
	cmpdw	cxbx, dxax
	jae	10$
	movdw	dxax, cxbx		;DX.AX = MIN(endPos,endOfText)
10$:
	movdw	cxbx, dxax		;CX.BX <- starting position
	sub	bx, bp
	sbb	cx, 0			;CX.BX = end of range
	jnc	exit
	clrdw	cxbx
exit:
	.leave
	ret
GetEndingAtPositionRange	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCenteredAroundSelectionRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a range centered around the current selection

CALLED BY:	GLOBAL
PASS:		bp - num chars to get
RETURN:		(dx.ax), (cx.bx) - text range to get
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCenteredAroundSelectionRange	proc	near
	call	TSL_SelectGetSelection
	GOTO	GetCenteredAroundRangeCommon
GetCenteredAroundSelectionRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCenteredAroundSelectionStartRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a range centered around the start of the current selection

CALLED BY:	GLOBAL
PASS:		bp - num chars to get
RETURN:		(dx.ax), (cx.bx) - text range to get
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCenteredAroundSelectionStartRange	proc	near
	call	TSL_SelectGetSelectionStart
	FALL_THRU	GetCenteredAroundPositionRange
GetCenteredAroundSelectionStartRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCenteredAroundPositionRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a range centered around the passed position

CALLED BY:	GLOBAL
PASS:		bp - num chars to get
		dx.ax - position to center around
RETURN:		(dx.ax), (cx.bx) - text range to get
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCenteredAroundPositionRange	proc	near

	movdw	cxbx, dxax
	FALL_THRU	GetCenteredAroundRangeCommon
GetCenteredAroundPositionRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCenteredAroundRangeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a range centered around the passed range (as much
		as possible)

CALLED BY:	GLOBAL
PASS:		*ds:si - object
		bp - # chars to get
		dx.ax - start of range
		cx.bx - end of range
RETURN:		(dx.ax), (cx.bx) - text range to get
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCenteredAroundRangeCommon	proc	near
	numChars	local	word	\
			push	bp

	range		local	VisTextRange
	.enter
	movdw	range.VTR_start, dxax
	movdw	range.VTR_end, cxbx

;	We want to get a range centered around the passed range, unless there
;	aren't enough characters available (i.e. the range is close to
;	the start/end of the document, in which case we'll get as large of
;	an area as possible).

	subdw	cxbx, dxax			;CX.BX <- # chars in selection
	tst	cx				;If there is more than the
	jnz	justGetSelection		; requested # chars selected
	mov	ax, numChars			; just get the selection
	sub	ax, bx
	jc	justGetSelection

	mov_tr	bx, ax				;BX <- # chars to try to get
						; after the selection.
	shr	bx, 1				;CX.BX <- # chars to get after
	clr	cx				; selection

	adddw	cxbx, range.VTR_end		;CX.BX <- end of range to get

;	If the end of the range we want to get is beyond the edge of the text,
;	just get up to the end of the text.

	call	TS_GetTextSize
	cmpdw	cxbx, dxax
	jb	haveRangeEnd
	movdw	cxbx, dxax
haveRangeEnd:

;	CX.BX <- End of the range to get

	movdw	dxax, cxbx
	sub	ax, numChars		;If the start of the range goes beyond
	sbb	dx, 0			; the start of the text, branch...
	jc	adjustEnd
exit:

	.leave
	ret

adjustEnd:

;	We want the text range we are getting to start at 0 and extend to
;	0+numChars or to the end of the text, whichever comes first.

	mov	bx, numChars		;CX.BX <- offset to start of text +
	clr	cx			; "numChars"
	call	TS_GetTextSize
	cmpdw	cxbx, dxax
	jbe	haveEnd
	movdw	cxbx, dxax
haveEnd:
	clrdw	dxax
	jmp	exit
	
justGetSelection:

;	The selected area is larger than "numChars" -
;	Just get the first "numChars" characters of the selection

	movdw	dxax, range.VTR_start
	movdw	cxbx, dxax
	add	bx, numChars
	adc	cx, 0
	jmp	exit

GetCenteredAroundRangeCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectedWordRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the range of text to get if CL_GET_SELECTED_WORD is 
		passed.

CALLED BY:	GLOBAL
PASS:		bp - max # chars to get
RETURN:		(dx.ax), (cx.bx) - text range to get
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectedWordRange	proc	near
	.enter
	call	TSL_SelectGetSelection	;Either get the selection, 
	jc	gotRange
	call	SelectByModeWordFar
gotRange:

;	Ensure that at most "bp" chars are grabbed

	pushdw	cxbx
	subdw	cxbx, dxax
	tst	cx
	jnz	tooManyChars
	cmp	bx, bp
	ja	tooManyChars
	popdw	cxbx
exit:
	.leave
	ret
tooManyChars:
	movdw	cxbx, dxax
	add	bx, bp
	adc	cx, 0
	add	sp, size dword
	jmp	exit
GetSelectedWordRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendSelectionContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a context notification centered around the current
		selection.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendSelectionContext	proc	far	uses	ax, cx, dx, bp
	.enter
	sub	sp, size GetContextParams
	mov	bp, sp
	mov	ss:[bp].GCP_numCharsToGet, 500
	mov	ss:[bp].GCP_location, CL_CENTERED_AROUND_SELECTION_START
	mov	ax, MSG_META_GENERATE_CONTEXT_NOTIFICATION
	call	ObjCallInstanceNoLock
	add	sp, size GetContextParams
	.leave
	ret
SendSelectionContext	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendPositionContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a context notification centered around the passed
		position.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
		dx.ax - position
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendPositionContext	proc	far	uses	ax, cx, dx, bp
	.enter
	sub	sp, size GetContextParams
	mov	bp, sp
	movdw	ss:[bp].GCP_position, dxax
	mov	ss:[bp].GCP_numCharsToGet, 500
	mov	ss:[bp].GCP_location, CL_CENTERED_AROUND_POSITION
	mov	ax, MSG_META_GENERATE_CONTEXT_NOTIFICATION
	call	ObjCallInstanceNoLock
	add	sp, size GetContextParams
	.leave
	ret
SendPositionContext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the context from the text object.

CALLED BY:	GLOBAL
PASS:		ss:bp - GetContextParams
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetContext	method	VisTextClass, MSG_META_GET_CONTEXT

	pushdw	ss:[bp].GCP_replyObj
	call	CreateTextContextBlock
	popdw	bxsi
	mov	ax, MSG_META_CONTEXT
	clr	di
	GOTO	ObjMessage
VisTextGetContext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTextContextBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a block containing ContextData for this text object

CALLED BY:	GLOBAL
PASS:		*ds:si - object
		ss:bp - GetContextParams
RETURN:		bp - block with context data
DESTROYED:	ax, bx, cx, dx, di, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTextContextBlock	proc	near
	.enter
;
;	Figure out the range of the text we want to get
;	

	movdw	dxax, ss:[bp].GCP_position
	mov	bx, ss:[bp].GCP_location
	mov	bp, ss:[bp].GCP_numCharsToGet
EC <	cmp	bx, ContextLocation					>
EC <	ERROR_AE	BAD_CONTEXT_LOCATION				>
   	shl	bx
	call	cs:getContextRangeRouts[bx]

;	DX.AX = Start of range to get
;	CX.BX = End of range to get
	

	sub	sp, size VisTextGetTextRangeParameters
	mov	bp, sp
	movdw	ss:[bp].VTGTRP_range.VTR_start, dxax
	movdw	ss:[bp].VTGTRP_range.VTR_end, cxbx

;	Allocate and initialize a block with ContextData structure

	subdw	cxbx, dxax
EC <	tst	cx							>
EC <	ERROR_NZ	-1						>
	mov_tr	ax, bx		
DBCS <	shl	ax, 1			; # chars -> # bytes		>
	add	ax, size ContextData+1 ;	(add one for null terminator)
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	push	bx

;	Convert the selection to be relative to the start of the data in
;	the context block, and store it in the ContextData struct.

	call	TSL_SelectGetSelection
	movdw	es:[CD_selection].VTR_start, dxax
	movdw	es:[CD_selection].VTR_end, cxbx
	mov	ax, ds:[LMBH_handle]
	movdw	es:[CD_object], axsi

;	Set the flags denoting whether or not the context included the
;	start/end of the text.

	call	TS_GetTextSize
	movdw	es:[CD_numChars], dxax

	movdw	es:[CD_range].VTR_start, ss:[bp].VTGTRP_range.VTR_start, ax
	movdw	es:[CD_range].VTR_end, ss:[bp].VTGTRP_range.VTR_end, ax


;	Copy the text from the object into the block with ContextData

	mov	ss:[bp].VTGTRP_textReference.TR_type, TRT_POINTER
	mov	ss:[bp].VTGTRP_pointerReference.segment, es
	mov	ss:[bp].VTGTRP_pointerReference.offset, offset CD_contextData
	clr	ss:[bp].VTGTRP_flags
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
	call	ObjCallInstanceNoLock

	pop	bx
	call	MemUnlock

	add	sp, size VisTextGetTextRangeParameters

	mov	bp, bx			;BP <- block with context data
	.leave
	ret
CreateTextContextBlock	endp


getContextRangeRouts	nptr	\
			GetStartingAtPositionRange,
			GetEndingAtPositionRange,
			GetCenteredAroundPositionRange,
			GetCenteredAroundSelectionRange,
			GetCenteredAroundSelectionStartRange,
			GetSelectedWordRange

.assert length getContextRangeRouts eq ContextLocation



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGenerateContextNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message handler sends the passed context block off to the
		appropriate GCN list.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
		ss:bp - GetContextParams
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGenerateContextNotification	method	dynamic VisTextClass, 
					MSG_META_GENERATE_CONTEXT_NOTIFICATION
	.enter
EC <	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS		>
EC <	jnz	hasFocus						>
EC <	mov	ax, ATTR_VIS_TEXT_SEND_CONTEXT_NOTIFICATIONS_EVEN_IF_NOT_FOCUSED >
EC <	call	ObjVarFindData						>
EC <	ERROR_NC	MUST_BE_FOCUS_TO_GENERATE_CONTEXT_NOTIFICATION	>
EC <hasFocus:								>
	call	CreateTextContextBlock		;BP <- Context block

	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_TEXT_CONTEXT
	mov	di, mask MF_RECORD
	call	ObjMessage			;DI <- event handle

	mov	bx, bp
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_NOTIFY_TEXT_CONTEXT
	mov	dx, size GCNListMessageParams
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	clr	ss:[bp].GCNLMP_flags


;	If we don't have the focus, we must have
;	ATTR_VIS_TEXT_SEND_CONTEXT_NOTIFICATIONS_EVEN_IF_NOT_FOCUSED. If so,
;	then assume that the user knows what he's doing, and send the message
;	directly to the gcn list.

	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jz	sendDirectly

;	Otherwise, check to see if a UserDoDialog is running. If so, the
;	process thread could be blocked, so send this directly to the app
;	object. This is OK, as any recipients of this message will know to
;	ignore notifications coming from objects not run from the UI if a
;	UserDoDialog is onscreen. Basically, this is all just a hack that
;	is needed if you want your controllers to get updated when a
;	UserDoDialog is up.

	mov	ax, MSG_GEN_APPLICATION_CHECK_IF_RUNNING_USER_DO_DIALOG

	push	cx, dx, bp
	call	UserCallApplication
	pop	cx, dx, bp

	tst	ax			;If a UserDoDialog is active, send
	jnz	sendDirectly		; this directly on.
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
common:
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx	
	.leave
	ret
sendDirectly:
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_META_GCN_LIST_SEND
	jmp	common
	
VisTextGenerateContextNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextRegionFromPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the region associated with a given point

CALLED BY:	MSG_VIS_TEXT_REGION_FROM_POINT
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ds:bx	= VisTextClass object (same as *ds:si)
		es 	= segment of VisTextClass
		ax	= message #
		ss:bp	= PointDWFixed

RETURN:		cx	= Region
		ax	= Relative X position
		dx	= Relative Y position
		
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextRegionFromPoint	method dynamic VisTextClass, 
					MSG_VIS_TEXT_REGION_FROM_POINT
	call	TR_RegionFromPoint
	ret
VisTextRegionFromPoint	endm


TextInstance	ends

TextFixed	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		T_CheckIfContextUpdateDesired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if context updates are desired.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
RETURN:		z flag set if not desired (jz noUpdate)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
T_CheckIfContextUpdateDesired	proc	far	uses	ax, bx, di
	class	VisTextClass
	.enter
	call	UserCheckIfContextUpdateDesired
	tst	ax
	jz	exit

;	The object must have the focus (or have the override attribute), and
;	be editable as well.

	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	mov	ax,ATTR_VIS_TEXT_SEND_CONTEXT_NOTIFICATIONS_EVEN_IF_NOT_FOCUSED
	call	ObjVarFindData
	jc	skipFocusCheck
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jz	exit
skipFocusCheck:
	test	ds:[di].VTI_state, mask VTS_EDITABLE
exit:
	.leave
	ret
T_CheckIfContextUpdateDesired	endp

TextFixed	ends
