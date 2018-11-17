COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsLargeModify.asm

AUTHOR:		John Wedgwood, Nov 19, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/19/91	Initial revision

DESCRIPTION:
	Modification code for large text objects.

	$Id: tsLargeModify.asm,v 1.1 97/04/07 11:22:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeReplaceRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace a range in a large object.

CALLED BY:	TS_ReplaceRange via CallStorageHandler
PASS:		*ds:si	= Text object instance
		ss:bp	= VisTextReplaceParameters
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Delete the elements in the range
	Insert new elements

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeReplaceRange	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	;
	; Get the array handle
	;
	call	Text_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_text		; di <- vm handle of array

	movdw	dxax, ss:[bp].VTRP_range.VTR_start	; dx.ax <- place to start
	movdw	cxbx, ss:[bp].VTRP_range.VTR_end	; cx.bx <- place to stop
	subdw	cxbx, dxax				; cx.bx <- # to nuke

	;
	; Delete the elements that need deleting
	;
	call	DeleteRangeFromHugeArray	; Nuke cx.bx elements at dx.ax

	;
	; Insert the text that needs inserting.
	;
	tstdw	ss:[bp].VTRP_insCount		; Check for nothing to insert
	jz	quit				; Branch if nothing to insert

	movdw	cxbx, ss:[bp].VTRP_insCount	; cx.bx <- # to insert
	lea	bp, ss:[bp].VTRP_textReference	; ss:bp <- text reference
	call	InsertIntoHugeArray		; Insert the text
quit:
	.leave
	ret
LargeReplaceRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteRangeFromHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a dword range from a huge-array.

CALLED BY:	LargeReplaceRange
PASS:		*ds:si	= text object
		dx.ax	= Element to start deleting at
		cx.bx	= Number of elements to nuke
		di	= Huge-array to nuke from
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteRangeFromHugeArray	proc	near
	uses	bx, cx, bp
	.enter
deleteLoop:
	;
	; di	= Array vm-block handle
	; dx.ax	= Element to delete at
	; cx.bx	= Number to delete
	;
	tstdw	cxbx				; Check for none to delete
	jz	endLoop				; Branch if nothing
	
	;
	; Nuke 64K or cx.bx whichever is less
	;
	pushdw	cxbx				; Save number left
	jcxz	deleteBX			; Branch if cx.bx < 64K
	mov	bx, -1				; bx <- # to nuke
deleteBX:
	;
	; bx	= Number to delete
	; di	= Array
	; dx.ax	= Element to start nuking at
	;
	mov	cx, bx				; cx <- # to nuke
	call	T_GetVMFile
	call	HugeArrayDelete			; Delete this many
	
	mov	bp, cx				; bp <- number nuked
	popdw	cxbx				; Restore number to nuke
	
	;
	; cx.bx	= Number to nuke (before last delete)
	; si	= Number nuked as part of last delete
	;
	sub	bx, bp				; cx.bx <- number left
	sbb	cx, 0
	
	jmp	deleteLoop
endLoop:
	.leave
	ret
DeleteRangeFromHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertTextFromPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert text from a pointer into a huge-array.

CALLED BY:	InsertIntoHugeArray
PASS:		*ds:si	= text object
		ss:bp	= TextReferencePointer
		cx.bx	= Number of bytes to insert
		di	= Huge-array handle
		dx.ax	= Position to insert at
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertTextFromPointer	proc	near
	uses	bx, cx, si, bp
	.enter

	mov	cx, bx				; cx <- # to insert
	call	T_GetVMFile			; bx = VM file
	mov	si, ss:[bp].TRP_pointer.offset	; bp.si <- ptr to text
	mov	bp, ss:[bp].TRP_pointer.segment

EC <	call	ECCheckTextForInsert				>

	call	HugeArrayInsert			; Insert the text
	.leave
	ret
InsertTextFromPointer	endp

Text	ends

;----------------------------------------------------------------------------
;
; The following insert-handlers aren't used for standard editing so they
; have been moved out of the text resource.
;

TextStorageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertTextFromSegmentChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert text from a segment/chunk into a huge-array.

CALLED BY:	InsertIntoHugeArray
PASS:		ss:bp	= TextReferenceSegmentChunk
		cx.bx	= Number of bytes to insert
		di	= Huge-array handle
		dx.ax	= Position to insert at
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertTextFromSegmentChunk	proc	far
	uses	bx, cx, si, bp
	.enter

	mov	cx, bx				; cx <- # to insert
	call	T_GetVMFile			; bx = VM file

	mov	si, ss:[bp].TRSC_chunk		; bp.si <- ptr to text
	mov	bp, ss:[bp].TRSC_segment

EC <	call	ECCheckTextForInsert				>

	call	HugeArrayInsert			; Insert the text
	.leave
	ret
InsertTextFromSegmentChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertTextFromBlockChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert text from a block/chunk into a huge-array.

CALLED BY:	InsertIntoHugeArray
PASS:		ss:bp	= TextReferenceBlockChunk
		cx.bx	= Number of bytes to insert
		di	= Huge-array handle
		dx.ax	= Position to insert at
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertTextFromBlockChunk	proc	far
	uses	bx, cx, si, bp
	.enter

	push	ss:[bp].TRBC_ref.handle		; save handle for unlock before
						;  pushing position & count

	push	ds				; save text obj segment
	push	ax, bx				; Save pos.low, count
	;
	; Lock the block
	;
	mov	bx, ss:[bp].TRBC_ref.handle	; bx <- handle
	call	ObjLockObjBlock			; ax <- segment of block
	call	T_GetVMFile			; bx = VM file
	mov	ds, ax				; ds <- segment of block
	
	;
	; Dereference the chunk
	;
	mov	si, ss:[bp].TRBC_ref.chunk	; *ds:si <- text
	mov	si, ds:[si]			; ds:si <- text
	
	;
	; Set up the pointer and get the position and count
	;
	mov	bp, ds				; bp:si <- text
	pop	ax, cx				; Restore pos.low, count
	pop	ds				; ds <- text obj segment
	
	;
	; Insert the text.
	;

EC <	call	ECCheckTextForInsert				>

	call	HugeArrayInsert			; Insert the text
	
	;
	; Release the block
	;
	pop	bx
	call	MemUnlock			; Release the block
	.leave
	ret
InsertTextFromBlockChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertTextFromBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert text from a block into a huge-array.

CALLED BY:	InsertIntoHugeArray
PASS:		*ds:si	= text object
		ss:bp	= TextReferenceBlock
		cx.bx	= Number of bytes to insert
		di	= Huge-array handle
		dx.ax	= Position to insert at
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertTextFromBlock	proc	far
	uses	bx, cx, si, bp
	.enter
	;
	; Lock the block
	;
	mov	cx, bx				; cx <- number to insert

	push	ax				; Save position.low
	mov	bx, ss:[bp].TRB_handle		; bx <- handle
	call	MemLock				; ax <- segment of block
	mov	bp, ax				; bp <- segment of block
	pop	ax				; Restore position.low
	
	;
	; Insert the text.
	;

EC <	call	ECCheckTextForInsert				>

	push	bx
	call	T_GetVMFile			; bx = VM file
	clr	si				; bp:si <- text
	call	HugeArrayInsert			; Insert the text
	pop	bx
	
	;
	; Release the block
	;
	call	MemUnlock			; Release the block
	.leave
	ret
InsertTextFromBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertTextFromVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert text from a vm-block into a huge-array.

CALLED BY:	InsertIntoHugeArray
PASS:		*ds:si	= text object
		ss:bp	= TextReferenceVMBlock
		cx.bx	= Number of bytes to insert
		di	= Huge-array handle
		dx.ax	= Position to insert at
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	ourFile = GetOverride()

	SetOverride(0)
	seg,han = VMLock(TR_file, TR_block)
	SetOverride(ourFile)
	
	HugeArrayInsert(...)
	VMUnlock(han)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertTextFromVMBlock	proc	far
	uses	ax, bx, cx, si, bp
	.enter
	mov	cx, bx				; cx <- # of bytes to insert
	push	ax				; save pos.low
	;
	; Lock the vm-block
	;
	mov	bx, ss:[bp].TRVMB_file		; bx <- source file
	mov	ax, ss:[bp].TRVMB_block		; ax <- vm block
	call	VMLock				; ax <- segment
						; bp <- handle
	pop	ax				; restore pos.low
	;
	; ax	= Segment of source VM block
	; bx	= VM file handle
	; bp	= Block handle of source VM block
	; cx	= Number of bytes to insert
	; di	= HugeArray vm-handle
	; dx.ax	= Position to insert at
	;
	push	bp				; Save block handle
	mov	bp, ax				; bp:si <- ptr to text
	call	T_GetVMFile			; bx = VM file
	clr	si

EC <	call	ECCheckTextForInsert				>

	call	HugeArrayInsert			; Insert the new bytes
	
	;
	; Now release the locked vm-block
	;
	pop	bp				; Restore block handle
	call	VMUnlock			; Release the block
	.leave
	ret
InsertTextFromVMBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertTextFromDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert text from a db-item into a huge-array.

CALLED BY:	InsertIntoHugeArray
PASS:		*ds:si	= text object
		ss:bp	= TextReferenceDBItem
		cx.bx	= Number of bytes to insert
		di	= Huge-array handle
		dx.ax	= Position to insert at
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	ourFile = GetOverride()

	SetOverride(0)
	seg,chunk = DBLock(TR_file, TR_group, TR_item)
	SetOverride(ourFile)
	
	HugeArrayInsert(...)
	DBUnlock(seg)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertTextFromDBItem	proc	far
	uses	ax, bx, cx, si, bp, es
	.enter
	mov	cx, bx				; cx <- # of bytes to insert
	push	ax, di				; Save pos.low, array
	;
	; Lock the vm-block
	;
	mov	bx, ss:[bp].TRDBI_file		; bx <- source file
	mov	ax, ss:[bp].TRDBI_group		; ax <- group
	mov	di, ss:[bp].TRDBI_item		; di <- item
	call	DBLock				; *es:di <- text

	call	T_GetVMFile			; bx = VM file
	mov	si, es:[di]			; es:di <- text

	pop	ax, di				; Rstore pos.low, array
	;
	; es	= Segment of source db-item
	; si	= Pointer to source db-item
	; cx	= Number of bytes to insert
	; di	= HugeArray vm-handle
	; dx.ax	= Position to insert at
	; bx	= VM file handle
	;
	mov	bp, es				; bp:si <- ptr to text

EC <	call	ECCheckTextForInsert				>

	call	HugeArrayInsert			; Insert the new bytes
	
	;
	; Now release the locked db-item
	;
	call	DBUnlock			; Release the block
	.leave
	ret
InsertTextFromDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertTextFromHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert text from a huge-array into a huge-array.

CALLED BY:	InsertIntoHugeArray
PASS:		*ds:si	= text object
		ss:bp	= TextReferenceHugeArray
		cx.bx	= Number of bytes to insert
		di	= Huge-array handle
		dx.ax	= Position to insert at
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertTextFromHugeArray	proc	far
	uses	ax, bx, cx, dx, di, si, bp, ds
reference	local	word		push	bp
sourceCount	local	dword		push	cx, bx
destOffset	local	dword		push	dx, ax
destArray	local	word		push	di
destFile	local	word

sourceOffset	local	dword
	.enter
	;
	; Copy stuff from one frame to another...
	;
	mov	bx, reference			; ss:bx <-TextReferenceHugeArray

	call	T_GetVMFile			; bx = VM file
	mov	destFile, bx

;-----------------------------------------------------------------------------
	clrdw	sourceOffset			; Start at the start
insertLoop:
	tstdw	sourceCount			; Check for nothing to insert
	jz	endLoop				; Branch if nothing
	
	;
	; If sourceCount < 64K, insert that many bytes, otherwise use 64K.
	;
	mov	cx, -1				; Assume 64K
	tst	sourceCount.high
	jnz	gotInsCount			; Branch if sourceCount > 64K
	mov	cx, sourceCount.low		; Else use amount left
gotInsCount:
	
	;
	; cx	= Amount to insert if we can.
	;
	; Lock down the source array at the current offset.
	;
	push	cx				; Save number to insert
	mov	bx, ss:[bp]
	mov	di, ss:[bx].TRHA_array		; di <- array
	mov	bx, ss:[bx].TRHA_file		; bx <- file
	movdw	dxax, sourceOffset		; dx.ax <- offset
if DBCS_PCGEOS
PrintMessage <need to change offsets and/or char counts?>
endif
	call	HugeArrayLock			; ds:si <- ptr to element
EC <	tst	ax							>
EC <	ERROR_Z	PASSED_OFFSET_DOES_NOT_EXIST_IN_HUGE_ARRAY		>
						; ax <- count after
						; cx <- count before
						; dx <- element size (1)
	pop	cx				; Restore # to insert
	
	;
	; ds:si	= Pointer to text to insert
	; cx	= Number of bytes we'd like to insert
	; ax	= Number available to us
	;
	cmp	cx, ax				; Use the minimum
	jbe	gotFinalCount			; Branch if already got it
	mov	cx, ax				; cx <- # available
gotFinalCount:
	
	;
	; ds:si	= Pointer to the text to insert
	; cx	= Number of bytes to insert
	; bp	= Frame ptr
	;
	push	bp				; Save frame ptr
	mov	bx, destFile
	mov	di, destArray			; di <- dest array
	movdw	dxax, destOffset		; dx.ax <- position to insert
	mov	bp, ds				; bp:si <- ptr to text
	call	HugeArrayInsert			; Insert the bytes
	pop	bp				; Restore frame ptr
	
	call	HugeArrayUnlock			; Release the source text
	
	;
	; Update the offsets and the amount left.
	;
	add	destOffset.low, cx		; Adjust the dest offset
	adc	destOffset.high, 0

	add	sourceOffset.low, cx		; Adjust the source offset
	adc	sourceOffset.high, 0

	sub	sourceCount.low, cx		; Subtract off what we inserted
	sbb	sourceCount.high, 0

	jmp	insertLoop			; Loop to insert more

endLoop:
;-----------------------------------------------------------------------------
	.leave
	ret
InsertTextFromHugeArray	endp

TextStorageCode	ends

Text segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertIntoHugeArray	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert into a huge-array from one of any number of
		data-structures.

CALLED BY:	LargeReplaceRange
PASS:		*ds:si	= text object
		ss:bp	= TextReference
		cx.bx	= Number of bytes to insert
		di	= Huge-array VM-handle
		dx.ax	= Position to insert at
RETURN:		nothing
DESTROYED:	si, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertIntoHugeArray	proc	near
	push	si

	mov	si, ss:[bp].TR_type		; bx <- type
EC <	cmp	si, TextReferenceType					>
EC <	ERROR_AE VIS_TEXT_BAD_TEXT_REFERENCE_TYPE			>

	ConvertReferenceTypeToCallOffset si	; si <- offset to handler
	add	si, offset cs:insertTextHandler	; cs:si <- place to jmp to

	push	bp
	mov	bp, sp
	xchg	si, ss:[bp+2]
	pop	bp

	lea	bp, ss:[bp].TR_ref		; ss:bp <- ptr to the reference
	ret


insertTextHandler	label	near
	DefTextCall	InsertTextFromPointer		; TRT_POINTER
	DefTextCall	InsertTextFromSegmentChunk	; TRT_SEGMENT_CHUNK
	DefTextCall	InsertTextFromBlockChunk	; TRT_BLOCK_CHUNK
	DefTextCall	InsertTextFromBlock		; TRT_BLOCK
	DefTextCall	InsertTextFromVMBlock		; TRT_VM_BLOCK
	DefTextCall	InsertTextFromDBItem		; TRT_DB_ITEM
	DefTextCall	InsertTextFromHugeArray		; TRT_HUGE_ARRAY

InsertIntoHugeArray	endp

Text ends
