COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsReference.asm

AUTHOR:		John Wedgwood, Nov 20, 1991

ROUTINES:
	Name			Description
	----			-----------
	CopyTextReference	Copy text into a buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/20/91	Initial revision

DESCRIPTION:
	Code for accessing and manipulating text references.

	$Id: tsReference.asm,v 1.1 97/04/07 11:22:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyTextFromPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a pointer into a buffer.

CALLED BY:	CopyTextReference
PASS:		es:di	= Destination for text
		cx	= # of chars to copy
		ss:bp	= TextReferencePointer
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyTextFromPointer	proc	near
	uses	cx, di, si, ds
	.enter
	mov	ds, ss:[bp].TRP_pointer.segment
	mov	si, ss:[bp].TRP_pointer.offset
	
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	.leave
	ret
CopyTextFromPointer	endp

Text	ends

;----------------------------------------------------------------------------
;
; The following insert-handlers aren't used for standard editing so they
; have been moved out of the text resource.
;

TextStorageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyTextFromSegmentChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a segment.chunk into a buffer.

CALLED BY:	CopyTextReference
PASS:		es:di	= Destination for text
		cx	= # of chars to copy
		ss:bp	= TextReferenceSegmentChunk
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyTextFromSegmentChunk	proc	far
	uses	cx, di, si, ds
	.enter
	mov	ds, ss:[bp].TRSC_segment
	mov	si, ss:[bp].TRSC_chunk
	mov	si, ds:[si]
	
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	.leave
	ret
CopyTextFromSegmentChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyTextFromBlockChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a block.chunk into a buffer.

CALLED BY:	CopyTextReference
PASS:		es:di	= Destination for text
		cx	= # of chars to copy
		ss:bp	= TextReferenceBlockChunk
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyTextFromBlockChunk	proc	far
	uses	ax, bx, cx, di, si, ds
	.enter
	mov	bx, ss:[bp].TRBC_ref.handle
	call	ObjLockObjBlock
	mov	ds, ax

	mov	si, ss:[bp].TRBC_ref.chunk
	mov	si, ds:[si]
	
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	
	call	MemUnlock
	.leave
	ret
CopyTextFromBlockChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyTextFromBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a block into a buffer.

CALLED BY:	CopyTextReference
PASS:		es:di	= Destination for text
		cx	= # of chars to copy
		ss:bp	= TextReferenceBlock
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyTextFromBlock	proc	far
	uses	ax, bx, cx, di, si, ds
	.enter
	mov	bx, ss:[bp].TRB_handle
	call	MemLock
	mov	ds, ax

	clr	si
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	
	call	MemUnlock
	.leave
	ret
CopyTextFromBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyTextFromVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a vm block into a buffer.

CALLED BY:	CopyTextReference
PASS:		es:di	= Destination for text
		cx	= # of chars to copy
		ss:bp	= TextReferenceVMBlock
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyTextFromVMBlock	proc	far
	uses	ax, bx, cx, di, si, bp, ds
	.enter
	
	mov	bx, ss:[bp].TRVMB_file
	mov	ax, ss:[bp].TRVMB_block
	call	VMLock				; bp <- block handle
						; ax <- segment address
	mov	ds, ax				; ds:si <- ptr to text
	clr	si
	
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	
	call	VMUnlock			; Release the block

	.leave
	ret
CopyTextFromVMBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyTextFromDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a db-item into a buffer.

CALLED BY:	CopyTextReference
PASS:		es:di	= Destination for text
		cx	= # of chars to copy
		ss:bp	= TextReferenceDBItem
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyTextFromDBItem	proc	far
	uses	ax, bx, cx, di, si, bp, ds, es
	.enter
	;
	; Lock the db-item and get the pointer into ds:si
	;
	push	es, di				; Save ptr to buffer
	mov	bx, ss:[bp].TRDBI_file
	mov	ax, ss:[bp].TRDBI_group
	mov	di, ss:[bp].TRDBI_item
	call	DBLock				; *es:di <- text
	mov	di, es:[di]			; es:di <- text
	
	segmov	ds, es, si			; ds:si <- text
	mov	si, di
	pop	es, di				; Restore pointer to destination

	;
	; Copy the text
	;
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	
	;
	; Unlock the db-item
	;
	segmov	es, ds, ax			; es <- segment address of item
	call	DBUnlock			; Release it

	.leave
	ret
CopyTextFromDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyTextFromHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a huge-array into a buffer.

CALLED BY:	CopyTextReference
PASS:		es:di	= Destination for text
		cx	= # of chars to copy
		ss:bp	= TextReferenceHugeArray
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Lock first element of huge-array
    copyLoop:
	Copy as many bytes as we can (up to cx)
	If we aren't done yet
	    Release the huge-array and lock the next block of data
	    jmp copy loop

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyTextFromHugeArray	proc	far
	uses	ax, bx, cx, dx, si, ds
	.enter
	;
	; Copy the data
	;
	clrdw	dxax				; dx.ax <- next element to get
copyLoop:
	;
	; bx	= huge array file
	; ss:bp	= TextReferenceHugeArray
	; dx.ax	= Next element to get
	; es:di	= Destination buffer
	; cx	= Number of bytes to copy
	;
	pushdw	dxax				; Save next element to get
	push	cx, di				; Save # of bytes, dest ptr
	mov	bx, ss:[bp].TRHA_file		; bx <- file
	mov	di, ss:[bp].TRHA_array		; di <- array
	call	HugeArrayLock			; ds:si <- data to copy
EC <	tst	ax							>
EC <	ERROR_Z	PASSED_OFFSET_DOES_NOT_EXIST_IN_HUGE_ARRAY		>
						; ax <- # of valid bytes
						; Nukes cx, dx
	pop	cx, di				; Restore # of bytes, dest ptr
	
	;
	; ds:si	= Pointer to source text to copy
	; es:di	= Pointer to destination
	; cx	= Max number of bytes to copy
	; ax	= Number of bytes available
	;
	mov	dx, cx				; Save max number to copy
	cmp	cx, ax				; Check for more than we need
	jbe	gotCount
	mov	cx, ax				; cx <- # to copy

gotCount:
	;
	; dx	= Number left to copy
	; cx	= Number we can copy now
	; ds:si = Source
	; es:di	= Dest
	;
	push	cx				; Save count
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	pop	cx				; Restore count
	
	call	HugeArrayUnlock			; Release the block

	;
	; Advance to the next block if we need to.
	;
	sub	dx, cx				; dx <- number left to copy
	mov	bx, cx				; bx <- number we did copy
	mov	cx, dx				; cx <- number left to copy
	popdw	dxax				; Restore next element to get

	jz	endLoop				; Branch if no more to copy
	
	;
	; There is more to copy...
	; bx	= number of bytes we did copy
	; cx	= number of bytes left to copy
	; dx.ax	= last element we got
	;
	add	ax, bx				; dx.ax <- next element to lock
	adc	dx, 0
	jmp	copyLoop
endLoop:
	.leave
	ret
CopyTextFromHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendFromPointerToTextReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append text from a buffer onto a text-reference.

CALLED BY:	SmallGetTextRange, LargeGetTextRange
PASS:		ds:si	= Pointer to text to copy
		ax	= Number of chars to copy
		cx.bx	= Offset to start writing at in output text-reference
				(char offset)
		ss:bp	= TextReference to write to
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendFromPointerToTextReference	proc	far
	uses	di, bp
	.enter
	mov	di, bx				; di <- low word of offset

	mov	bx, ss:[bp].TR_type		; bx <- type

	lea	bp, ss:[bp].TR_ref		; ss:bp <- ptr to the reference
	xchg	bx, di				; bx <- low word of offset
						; di <- handler to call
DBCS <	cmp	di, TRT_HUGE_ARRAY					>
DBCS <	je	isHugeArray			; huge array, use char offset>
DBCS <	shldw	cxbx				; else, use byte offset	>
DBCS <isHugeArray:							>
	call	cs:appendTextHandler[di]
	.leave
	ret
AppendFromPointerToTextReference	endp

appendTextHandler	word	\
	offset	cs:AppendTextToPointer,		; TRT_POINTER
	offset	cs:AppendTextToSegmentChunk,	; TRT_SEGMENT_CHUNK
	offset	cs:AppendTextToBlockChunk,	; TRT_BLOCK_CHUNK
	offset	cs:AppendTextToBlock,		; TRT_BLOCK
	offset	cs:AppendTextToVMBlock,		; TRT_VM_BLOCK
	offset	cs:AppendTextToDBItem,		; TRT_DB_ITEM
	offset	cs:AppendTextToHugeArray	; TRT_HUGE_ARRAY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendTextToPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append text from one buffer to another given a pointer
		reference to the destination.

CALLED BY:	AppendFromPointerToTextReference via appendTextHandler
PASS:		ds:si	= Pointer to text to copy
		ax	= Number of chars to copy
		cx.bx	= Offset into destination buffer to start writing
		ss:bp	= TextReferencePointer
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendTextToPointer	proc	near
	uses	ax, cx, di, si, es
	.enter
	;
	; Get the destination pointer
	;
	mov	es, ss:[bp].TRP_pointer.segment
	mov	di, ss:[bp].TRP_pointer.offset
	add	di, bx
EC <	ERROR_C	OFFSET_FOR_POINTER_REFERENCE_IS_TOO_LARGE	>
EC <	tst	cx						>
EC <	ERROR_NZ OFFSET_FOR_POINTER_REFERENCE_IS_TOO_LARGE	>

	call	CopyAndNullTerminate		; Copy the text
	.leave
	ret
AppendTextToPointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyAndNullTerminate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string and null-terminate it.

CALLED BY:	Append*
PASS:		ds:si	= Source
		es:di	= Dest
		ax	= Number of chars to copy
RETURN:		ds:si	= Pointer past source
		es:di	= Pointer past the NULL
		cx	= 0
		ax	= 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyAndNullTerminate	proc	near
SBCS <	mov	cx, ax				; cx <- # of bytes to copy >
DBCS <	mov_tr	cx, ax				; cx <- # of bytes to copy >
	jcxz	stuffNull			; Branch if nothing to copy

SBCS <	rep	movsb							>
DBCS <	rep	movsw							>

stuffNull:
SBCS <	clr	al				; Null terminate the result>
DBCS <	clr	ax							>
SBCS <	stosb								>
DBCS <	stosw								>
	ret
CopyAndNullTerminate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendTextToSegmentChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append text from one buffer to another given a segment/chunk
		reference to the destination.

CALLED BY:	AppendFromPointerToTextReference via appendTextHandler
PASS:		ds:si	= Pointer to text to copy
		ax	= Number of chars to copy
		cx.bx	= Offset into destination buffer to start writing
		ss:bp	= TextReferenceSegmentChunk
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendTextToSegmentChunk	proc	near
	uses	ax, cx, di, si, es
	.enter
	;
	; Get the destination pointer
	;
	mov	es, ss:[bp].TRSC_segment
	mov	di, ss:[bp].TRSC_chunk
	mov	di, es:[di]
	add	di, bx
EC <	ERROR_C	OFFSET_FOR_SEGMENT_CHUNK_REFERENCE_IS_TOO_LARGE		>
EC <	tst	cx							>
EC <	ERROR_NZ OFFSET_FOR_SEGMENT_CHUNK_REFERENCE_IS_TOO_LARGE	>

	call	CopyAndNullTerminate		; Copy the text
	.leave
	ret
AppendTextToSegmentChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendTextToBlockChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append text from one buffer to another given a block/chunk
		reference to the destination.

CALLED BY:	AppendFromPointerToTextReference via appendTextHandler
PASS:		ds:si	= Pointer to text to copy
		ax	= Number of chars to copy
		cx.bx	= Offset into destination buffer to start writing
		ss:bp	= TextReferenceBlockChunk
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendTextToBlockChunk	proc	near
	uses	ax, bx, cx, dx, di, si, es
	.enter
	mov	dx, bx				; Save low word of offset
	push	ax				; Save number of bytes to copy
	
	;
	; Get the destination pointer
	;
	mov	bx, ss:[bp].TRBC_ref.handle
	call	ObjLockObjBlock			; ax <- segment address
	mov	es, ax
	mov	di, ss:[bp].TRBC_ref.chunk
	mov	di, es:[di]

	add	di, dx
EC <	ERROR_C	OFFSET_FOR_SEGMENT_CHUNK_REFERENCE_IS_TOO_LARGE		>
EC <	tst	cx							>
EC <	ERROR_NZ OFFSET_FOR_SEGMENT_CHUNK_REFERENCE_IS_TOO_LARGE	>

	pop	ax				; ax <- # of bytes to copy

	call	CopyAndNullTerminate		; Copy the text
	
	call	MemUnlock			; Release the block
	.leave
	ret
AppendTextToBlockChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendTextToBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append text from one buffer to another given a block
		reference to the destination.

CALLED BY:	AppendFromPointerToTextReference via appendTextHandler
PASS:		ds:si	= Pointer to text to copy
		ax	= Number of chars to copy
		cx.bx	= Offset into destination buffer to start writing
		ss:bp	= TextReferenceBlock
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendTextToBlock	proc	near
	uses	ax, bx, cx, dx, di, si, es
	.enter
	mov	dx, bx				; Save low word of offset
	push	ax				; Save number of bytes to copy
	
	;
	; Get the destination pointer
	;
	mov	bx, ss:[bp].TRB_handle
	call	MemLock				; ax <- segment address
	mov	es, ax
	mov	di, dx

EC <	tst	cx						>
EC <	ERROR_NZ OFFSET_FOR_BLOCK_REFERENCE_IS_TOO_LARGE	>

	pop	ax				; ax <- # of bytes to copy

	call	CopyAndNullTerminate		; Copy the text
	
	call	MemUnlock			; Release the block
	.leave
	ret
AppendTextToBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendTextToVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append text from one buffer to another given a vm-block
		reference to the destination.

CALLED BY:	AppendFromPointerToTextReference via appendTextHandler
PASS:		ds:si	= Pointer to text to copy
		ax	= Number of chars to copy
		cx.bx	= Offset into destination buffer to start writing
		ss:bp	= TextReferenceVMBlock
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendTextToVMBlock	proc	near
	uses	ax, bx, cx, dx, di, si, bp, es
	.enter
	mov	dx, bx				; Save low word of offset
	
	;
	; Get the destination pointer
	;
	push	ax				; Save number of bytes to copy

	mov	bx, ss:[bp].TRVMB_file
	mov	ax, ss:[bp].TRVMB_block
	call	VMLock				; bp <- block handle
						; ax <- segment address
	mov	es, ax				; es:di <- ptr
	mov	di, dx

EC <	tst	cx						>
EC <	ERROR_NZ OFFSET_FOR_VM_BLOCK_REFERENCE_IS_TOO_LARGE	>

	pop	ax				; ax <- # of bytes to copy

	call	CopyAndNullTerminate		; Copy the text

	call	VMUnlock			; Release the block

	.leave
	ret
AppendTextToVMBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendTextToDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append text from one buffer to another given a db-item
		reference to the destination.

CALLED BY:	AppendFromPointerToTextReference via appendTextHandler
PASS:		ds:si	= Pointer to text to copy
		ax	= Number of chars to copy
		cx.bx	= Offset into destination buffer to start writing
		ss:bp	= TextReferenceDBItem
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendTextToDBItem	proc	near
	uses	ax, bx, cx, dx, di, si, es
	.enter
	mov	dx, bx				; Save low word of offset
	
	;
	; Get the destination pointer
	;
	push	ax				; Save number of bytes to copy

	mov	bx, ss:[bp].TRDBI_file
	mov	ax, ss:[bp].TRDBI_group
	mov	di, ss:[bp].TRDBI_item
	call	DBLock				; *es:di <- chunk
	mov	di, es:[di]			; es:di <- chunk
	add	di, dx				; es:di <- destination
EC <	ERROR_C	OFFSET_FOR_DB_ITEM_REFERENCE_IS_TOO_LARGE	>
EC <	tst	cx						>
EC <	ERROR_NZ OFFSET_FOR_DB_ITEM_REFERENCE_IS_TOO_LARGE	>

	pop	ax				; ax <- # of bytes to copy

	call	CopyAndNullTerminate		; Copy the text

	call	DBUnlock			; Release the block

	.leave
	ret
AppendTextToDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendTextToHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append text from one buffer to another given a huge-array
		reference to the destination.

CALLED BY:	AppendFromPointerToTextReference via appendTextHandler
PASS:		ds:si	= Pointer to text to copy
		ax	= Number of chars to copy
		cx.bx	= Offset into destination buffer to start writing
		ss:bp	= TextReferenceHugeArray
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if the offset into the destination buffer is not all the way to the
	end of the buffer then we assume that the end already contains a
	null. This means that we can skip adding the null ourselves.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendTextToHugeArray	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	push	ax				; Save # of elements to append
	movdw	dxax, cxbx			; dx.ax <- place to append
	pop	cx				; cx <- Number of elements

	mov	bx, ss:[bp].TRHA_file		; bx <- file
	mov	di, ss:[bp].TRHA_array		; di <- array

	call	IsInsertPosAtEnd		; Check for inserting at end
	pushf					; Save "insert at end" flag

	jcxz	appendNull			; Branch if no text

	mov	bp, ds				; bp:si <- ptr to buffer
	call	HugeArrayInsert			; Append those elements
EC <	call	ECCheckHugeArray					>

appendNull:
	;
	; Append a null if we need to.
	;
	popf					; Restore "insert at end" flag
	jne	afterNull			; Branch if not at end

NOFXIP<	mov	bp, cs							>
NOFXIP<	mov	si, offset cs:tNullString				>
FXIP<	mov	cx, NULL						>
FXIP<	push	cx							>
FXIP<	mov	bp, ss							>
FXIP<	mov	si, sp							>
	mov	cx, 1
	call	HugeArrayAppend
FXIP<	pop	cx				; reset stack		>

afterNull:
	.leave
	ret
AppendTextToHugeArray	endp

if not FULL_EXECUTE_IN_PLACE
LocalDefNLString tNullString	<0>
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsInsertPosAtEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the position of an insert is at the end of
		a huge-array.

CALLED BY:	AppendTextToHugeArray
PASS:		bx	= File
		di	= Array
		dx.ax	= Position to insert at
RETURN:		Zero set (z) if the insert position is at the end of the array
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsInsertPosAtEnd	proc	near
	uses	ax, cx, dx, bp
	.enter
	movdw	cxbp, dxax			; cx.bp <- insert position
	call	HugeArrayGetCount		; dx.ax <- # elements
	
	cmpdw	cxbp, dxax			; Compare insertPos, count
	.leave
	ret
IsInsertPosAtEnd	endp

TextStorageCode	ends

Text segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyTextReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy bytes referenced by a text-reference into a buffer.

CALLED BY:	SmallReplaceRange
PASS:		es:di	= Place to put the text
		ss:bp	= TextReference
		cx	= Number of bytes to copy
RETURN:		nothing
DESTROYED:	bx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyTextReference	proc	near
	mov	bx, ss:[bp].TR_type		; bx <- type
EC <	cmp	bx, TextReferenceType					>
EC <	ERROR_AE VIS_TEXT_BAD_TEXT_REFERENCE_TYPE			>

	ConvertReferenceTypeToCallOffset bx	; bx <- offset to handler

	lea	bp, ss:[bp].TR_ref		; ss:bp <- ptr to the reference
	add	bx, offset cs:copyTextHandler	; cs:bx <- place to jmp to
	jmp	bx

copyTextHandler	label	near
	DefTextCall	CopyTextFromPointer		; TRT_POINTER
	DefTextCall	CopyTextFromSegmentChunk	; TRT_SEGMENT_CHUNK
	DefTextCall	CopyTextFromBlockChunk		; TRT_BLOCK_CHUNK
	DefTextCall	CopyTextFromBlock		; TRT_BLOCK
	DefTextCall	CopyTextFromVMBlock		; TRT_VM_BLOCK
	DefTextCall	CopyTextFromDBItem		; TRT_DB_ITEM
	DefTextCall	CopyTextFromHugeArray		; TRT_HUGE_ARRAY

CopyTextReference	endp

Text ends
