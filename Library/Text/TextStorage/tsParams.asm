COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsParams.asm

AUTHOR:		John Wedgwood, Nov 21, 1991

ROUTINES:
	Name			Description
	----			-----------
GLBL	TS_GetReplaceSize	Convert a virtual VTRP_insCount field
GLBL	TS_ComputeReferenceSize	Compute the size of a text reference

	GetSizePointer		Get the size of various text references
	GetSizeSegmentChunk
	GetSizeBlockChunk
	GetSizeBlock
	GetSizeVMBlock
	GetSizeDBItem
	GetSizeHugeArray

	ComputeStringLength	Compute the length of a null terminated string
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/21/91	Initial revision

DESCRIPTION:
	Code for manipulating VisTextReplaceParameters structure.

	$Id: tsParams.asm,v 1.1 97/04/07 11:22:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_GetReplaceSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a virtual VTRP_insCount to something real.

CALLED BY:	Global
PASS:		*ds:si	= Text object instance
		ss:bp	= VisTextReplaceParameters
RETURN:		ss:bp.VTRP_insCount converted to something real
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_GetReplaceSize	proc	far
	uses	ax, bx, dx
	.enter
	cmp	ss:[bp].VTRP_insCount.high, INSERT_COMPUTE_TEXT_LENGTH
	jne	quit
	
	push	bp
	lea	bp, ss:[bp].VTRP_textReference
	call	TS_ComputeReferenceSize			; dx.ax <- size
	pop	bp
	
DBCS <	shrdw	dxax					; dxax <- # chars>
	movdw	ss:[bp].VTRP_insCount, dxax
quit:
	.leave
	ret
TS_GetReplaceSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSizePointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of the text referred to by a pointer.

CALLED BY:	TS_ComputeReferenceSize via getSizeTable
PASS:		ss:bp	= TextReferencePointer
RETURN:		dx.ax	= Size of the text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSizePointer	proc	near
	uses	di, es
	.enter
	mov	es, ss:[bp].TRP_pointer.segment
	mov	di, ss:[bp].TRP_pointer.offset
	
	call	ComputeStringLength	; dx.ax <- size
	.leave
	ret
GetSizePointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the size of a string that is <64K in size.

CALLED BY:	GetSize*
PASS:		es:di	= Pointer to string
RETURN:		dx.ax	= Size of string w/o NULL
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeStringLength	proc	far
	mov	ax, cx			; Save value of cx in ax
	call	LocalStringSize		; cx <- size of string w/o null
	clr	dx			; dx.ax <- size of string w/o null
	xchg	ax, cx			; cx <- old cx value
	ret
ComputeStringLength	endp

Text	ends

;----------------------------------------------------------------------------
;
; The following insert-handlers aren't used for standard editing so they
; have been moved out of the text resource.
;

TextStorageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSizeSegmentChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of the text referred to by a segment/chunk.

CALLED BY:	TS_ComputeReferenceSize via getSizeTable
PASS:		ss:bp	= TextReferenceSegmentChunk
RETURN:		dx.ax	= Size of the text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSizeSegmentChunk	proc	far
	uses	di, es
	.enter
	mov	es, ss:[bp].TRSC_segment
	mov	di, ss:[bp].TRSC_chunk
	mov	di, es:[di]		; es:di <- ptr to text
	
	call	ComputeStringLength	; dx.ax <- size
	.leave
	ret
GetSizeSegmentChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSizeBlockChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of the text referred to by a block/chunk.

CALLED BY:	TS_ComputeReferenceSize via getSizeTable
PASS:		ss:bp	= TextReferenceBlockChunk
RETURN:		dx.ax	= Size of the text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSizeBlockChunk	proc	far
	uses	bx, di, es
	.enter
	mov	bx, ss:[bp].TRBC_ref.handle
	call	ObjLockObjBlock			; ax <- segment of block
	mov	es, ax			; es <- segment of block

	mov	di, ss:[bp].TRBC_ref.chunk
	mov	di, es:[di]		; es:di <- ptr to text
	
	call	ComputeStringLength	; dx.ax <- size
	
	call	MemUnlock		; Release the block
	.leave
	ret
GetSizeBlockChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSizeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of the text referred to by a block.

CALLED BY:	TS_ComputeReferenceSize via getSizeTable
PASS:		ss:bp	= TextReferenceBlock
RETURN:		dx.ax	= Size of the text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSizeBlock	proc	far
	uses	bx, di, es
	.enter
	mov	bx, ss:[bp].TRB_handle
	call	MemLock			; ax <- segment of block
	mov	es, ax			; es <- segment of block

	clr	di			; es:di <- ptr to text
	
	call	ComputeStringLength	; dx.ax <- size
	
	call	MemUnlock		; Release the block
	.leave
	ret
GetSizeBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSizeVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of the text referred to by a vm-block.

CALLED BY:	TS_ComputeReferenceSize via getSizeTable
PASS:		ss:bp	= TextReferenceVMBlock
RETURN:		dx.ax	= Size of the text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSizeVMBlock	proc	far
	uses	bx, di, bp, es
	.enter
	
	mov	bx, ss:[bp].TRVMB_file
	mov	ax, ss:[bp].TRVMB_block
	call	VMLock			; bp <- block handle
					; ax <- segment address
	mov	es, ax			; es <- segment of block
	clr	di			; es:di <- ptr to text
	
	call	ComputeStringLength	; dx.ax <- size
	
	call	VMUnlock		; Release the block
	
	.leave
	ret
GetSizeVMBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSizeDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of the text referred to by a db-item

CALLED BY:	TS_ComputeReferenceSize via getSizeTable
PASS:		ss:bp	= TextReferenceDBItem
RETURN:		dx.ax	= Size of the text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSizeDBItem	proc	far
	uses	bx, di, es
	.enter

	mov	bx, ss:[bp].TRDBI_file
	mov	ax, ss:[bp].TRDBI_group
	mov	di, ss:[bp].TRDBI_item
	call	DBLock			; *es:di <- ptr to item
	mov	di, es:[di]		; es:di <- ptr to text
	
	call	ComputeStringLength	; dx.ax <- size
	
	call	DBUnlock		; Release the block
	
	.leave
	ret
GetSizeDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSizeHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of the text referred to by a huge-array

CALLED BY:	TS_ComputeReferenceSize via getSizeTable
PASS:		ss:bp	= TextReferenceHugeArray
RETURN:		dx.ax	= Size of the text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSizeHugeArray	proc	far
	uses	bx, cx, di, si, ds
	.enter
	;
	; Lock the last element
	;
	mov	bx, ss:[bp].TRHA_file
	mov	di, ss:[bp].TRHA_array
	call	HugeArrayGetCount	; dx.ax <- last element
	
	pushdw	dxax			; Save number of bytes
	decdw	dxax
	call	HugeArrayLock		; ds:si <- ptr to last
EC <	tst	ax							>
EC <	ERROR_Z	PASSED_OFFSET_DOES_NOT_EXIST_IN_HUGE_ARRAY		>
	popdw	dxax			; Restore number of bytes
	
	;
	; Check for ends in a NULL
	;
SBCS <	cmp	{byte} ds:[si], 0	; Check for null		>
DBCS <	cmp	{wchar} ds:[si], 0	; Check for null		>
	jne	noNull			; Branch if last is not a null
	decdw	dxax			; Account for null at end
DBCS <	shldw	dxax			; each entry is 2 bytes 	>
noNull:
	call	HugeArrayUnlock		; Release the block

	.leave
	ret
GetSizeHugeArray	endp

TextStorageCode	ends

Text segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_ComputeReferenceSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the size of a text reference

CALLED BY:	Global, TS_GetReplaceSize
PASS:		ss:bp	= TextReference
RETURN:		dx.ax	= Size of the text
DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_ComputeReferenceSize	proc	far
	;
	; Compute the size of the text reference.
	;
	mov	bx, ss:[bp].TR_type		; bx <- type
EC <	cmp	bx, TextReferenceType					>
EC <	ERROR_AE VIS_TEXT_BAD_TEXT_REFERENCE_TYPE			>
	
	ConvertReferenceTypeToCallOffset bx	; bx <- offset to handler

	lea	bp, ss:[bp].TR_ref		; ss:bp <- ptr to reference
	add	bx, offset cs:getSizeTable	; cs:bx <- place to jmp to
	jmp	bx

getSizeTable	label	near
	DefTextCall	GetSizePointer			; TRT_POINTER
	DefTextCall	GetSizeSegmentChunk		; TRT_SEGMENT_CHUNK
	DefTextCall	GetSizeBlockChunk		; TRT_BLOCK_CHUNK
	DefTextCall	GetSizeBlock			; TRT_BLOCK
	DefTextCall	GetSizeVMBlock			; TRT_VM_BLOCK
	DefTextCall	GetSizeDBItem			; TRT_DB_ITEM
	DefTextCall	GetSizeHugeArray		; TRT_HUGE_ARRAY

TS_ComputeReferenceSize	endp

Text ends
