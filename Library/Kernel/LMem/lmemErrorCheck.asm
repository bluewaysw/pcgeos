COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Local Memory Manager
FILE:		lmErrorCheck.asm

AUTHOR:		John Wedgwood, Apr 12, 1989

ROUTINES:
	Name			Description
	----			-----------

    INT ECLMemValidateHeap	Do a complete error check on the heap.
    INT ECLMemValidateHandle	Validate an individual handle.
    INT ECCheckLMemChunk	Validate a chunk.

    GLB ECCheckLMemHandle	Make sure a handle is a valid LMem handle
				and may be shared.

    GLB ECCheckLMemHandleNS	Make sure a handle is a valid LMem handle
				without worrying about sharing

    INT ECInitFreeChunk		Initialize a free chunk to contain nothing
				but 0xcc.

    INT ECInitEndOfChunk	Initialize the end of a used chunk to 0xcc.

    INT ECLMemInitHeap		Initialize an LMem heap that just came in
				from a VM file.

    INT LMValidateHeap		Do a complete error check on the heap.
    INT LMValidateSizes		Check heap-size variables.
    INT LMValidateFreeList	Validate free list in a local memory heap.
    INT LMValidateHandleTable	Validate the entire handle table.
    INT LMValidateHandle	Validate an individual LMem block chunk
				handle. ASSUMES that ds points to a valid
				heap block which is an LMem block. (No
				checking is done to ensure this)

    INT LMValidateChunks	Validate all chunks on the heap.
    INT LMValidateChunk		Validate a chunk.
    INT LMValidateFlags		Validate the flags chunk (if one exists)

ERRORS:
	Name			Meaning
	----			-------
	BAD_HEAP_SIZES		The various heap/chunk sizes don't add up
				correctly. The offset to the heap start added
				to the sum of the chunk sizes doesn't match
				the value of blockSize (the stored size of the
				block).
	UNFREE_CHUNK_ON_LIST	Somehow a non-free chunk is part of the free
				list.
	FREE_SPACE_WRONG	The sum of the free-chunk sizes doesn't match
				the totalFree variable stored in the info.
	HANDLES_MATCH		Two handles refer to the same chunk.
	HANDLE_OUT_OF_BOUNDS	A reference to a handle which is outside the
				handle table has been made.
	ADDR_OUT_OF_BOUNDS	A reference to a chunk which is outside the
				heap has been made.
	TAGS_DONT_MATCH		The size/flags words at either end of a chunk
				do not match.
	CHUNK_WITHOUT_HANDLE	A non-free chunk has been found which doesn't
				have a handle associated with it.
	HANDLE_TO_FREE		A free chunk has been found that has a handle
				pointing at it.
	ADJACENT_FREE_CHUNKS	Two adjacent chunks are marked as free. This is
				a no-no. They should have been coalesced.
	NOT_LMEM_HANDLE		ECCheckLMemHandle* was called on a handle
				that didn't have the HF_LMEM bit set.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	4/12/89		Initial revision
	Adam	9/28/89		Added ECCheckLMemHandle*

DESCRIPTION:
	Routines used for error checking in the local-memory heap code.

	$Id: lmemErrorCheck.asm,v 1.1 97/04/05 01:14:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECLMemValidateHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a complete error check on the heap.

CALLED BY:	Internal.
PASS:		ds = segment address of the local-memory heap block.
RETURN:		nothing
DESTROYED:	nothing

CHECKS:		Entire heap for consistency.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECLMemValidateHeapFar	proc	far
EC <	call	ECLMemValidateHeap					>
	ret
ECLMemValidateHeapFar	endp
	public	ECLMemValidateHeapFar

if ERROR_CHECK
ECLMemValidateHeap	proc	near
	pushf
	push	ax
	push	bx

	test	ds:[LMBH_flags], mask LMF_IN_LMEM_ALLOC
	jnz	done

	call	SysGetECLevel
	test	ax, mask ECF_LMEM or mask ECF_FREE
	jz	done

	call	LMValidateHeap

done:
	pop	bx
	pop	ax
	popf

	ret

ECLMemValidateHeap	endp
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECLMemValidateHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate an individual handle.

CALLED BY:	Internal.
PASS:		ds = segment address of the local-memory heap block.
		ds:si = ptr to the handle to check.
RETURN:		nothing
DESTROYED:	nothing

CHECKS:		Handle for consistency.
		1 - Handle must fall within handle table.
		2 - If handle is zero then all is ok.
		3 - If handle is non-zero, validate the chunk it points to.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECLMemValidateHandle	proc	far
if ERROR_CHECK

	pushf
	push	bp
	push	ds
	LoadVarSeg	ds
	mov	bp, ds:[sysECLevel]
	test	bp, mask ECF_HIGH
	pop	ds
	jz	done


	call	PushAll
	call	LMValidateHandle
	call	PopAll

done:
	pop	bp
	popf

endif
	ret					;
ECLMemValidateHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckLMemChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate a chunk.

CALLED BY:	Internal.
PASS:		ds = segment address of the local-memory heap block.
		ds:si = ptr to chunk to validate.
RETURN:		nothing
DESTROYED:	nothing

CHECKS:		Chunk for consistency.
		1 - The address of the chunk falls inside the bounds of the
		    heap.
		2 - Checks that the size/flags words at either end are the
		    same.
		3 - If the chunk is marked as allocated, make sure that some
		    handle points to the chunks.
		4 - If the chunk is marked as free make sure no handle points
		    to it.
		5 - If the chunk is marked as free make sure next block on heap
		    is not free (can't have adjacent free blocks).

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckLMemChunk	proc	far
if ERROR_CHECK
	call	PushAll
	mov	al, LM_USED_CHUNK
	mov	bp, mask ErrorCheckingFlags
	call	LMValidateChunk
	call	PopAll
endif
	ret					;
ECCheckLMemChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckLMemHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a handle is a valid LMem handle and may be shared.

CALLED BY:	GLOBAL
PASS:		bx	= lmem block handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckLMemHandle proc	far
if ERROR_CHECK
	pushf
	push	ds
	call	ECCheckMemHandleFar
	LoadVarSeg	ds
	test	ds:[bx].HM_flags, mask HF_LMEM
	ERROR_Z	NOT_LMEM_HANDLE
	pop	ds
	popf
endif
	ret
ECCheckLMemHandle endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckLMemHandleNS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a handle is a valid LMem handle without worrying
		about sharing

CALLED BY:	GLOBAL
PASS:		bx	= lmem block handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Most of the work is done by ECCheckMemHandleNS -- we just make sure
	the HF_LMEM bit is set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Perhaps the values in the LMemBlockHeader should be range-checked.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckLMemHandleNS proc	far
if ERROR_CHECK
;;;	pushf
;;;	push	ds
	call	ECCheckMemHandleNSFar
	;
	; There are problems with this check below.
	; The block could be just loaded, but not marked as being an LMem
	; block. The block could be discarded (as in a vm-block) and will be
	; marked as an object block when it gets loaded.
	;
	; john & tony - 15-Mar-90
	;
;;;	LoadVarSeg	ds
;;;	test	ds:[bx].HM_flags, mask HF_LMEM
;;;	ERROR_Z	NOT_LMEM_HANDLE
;;;	pop	ds
;;;	popf
endif
	ret
ECCheckLMemHandleNS endp

if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECInitFreeChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a free chunk to contain nothing but 0xcc.

CALLED BY:	AddFreeBlock, LMemInitHeap
PASS:		ds:si	= pointer to free chunk.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECInitFreeChunk	proc	near
	uses	es, di, cx, ax			;
	.enter					;
	segmov	es, ds				;
	mov	di, si				;
	mov	cx, ds:[di].LMC_size		;
	RoundUp	cx				;

if 0			;adam had this if 0'd out, I wonder why? -- tony
	push	di
	cmp	di, ds:[LMBH_offset]
	ERROR_B	GASP_CHOKE_WHEEZE
	add	di, cx
	dec	di				; ignore size word
	dec	di
	cmp	di, ds:[LMBH_blockSize]
 	ERROR_A	GASP_CHOKE_WHEEZE
	pop	di
endif
	sub	cx, 4				; Size/link don't count.
	inc	di				; Skip the link.
	inc	di
	mov	al, 0xcc			;
	rep	stosb				;
	.leave					;
	ret					;
ECInitFreeChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECInitEndOfChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the end of a used chunk to 0xcc.

CALLED BY:	LMemAlloc, LMemReAlloc
PASS:		ds:si	= chunk.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECInitEndOfChunk	proc	near
	uses	es, di, cx, ax			;
	.enter					;

	push	bx
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	cmp	si, ax
	ERROR_AE	-1
	mov	bx, ds:[LMBH_blockSize]
	add	bx, 15		;Round to nearest paragraph boundary
	andnf	bx, 0xfff0
	cmp	bx, ax
	ERROR_NZ	LMEM_INVALID_BLOCK_SIZE
	pop	bx

	segmov	es, ds				;
	mov	di, si				; es:di <- ptr to chunk.
	mov	cx, ds:[di].LMC_size		;
	add	di, cx				;
	dec	di				; di <- ptr to chunk end.
	dec	di
	mov	ax, cx				;
	RoundUp	cx				;
	sub	cx, ax				; cx <- # of free bytes.
	jcxz	exit
	mov	al, 0xcc			;
	rep	stosb				;
	cmp	di, ds:[LMBH_blockSize]
	ERROR_A	-1
exit:
	.leave					;
	ret					;
ECInitEndOfChunk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECLMemInitHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize an LMem heap that just came in from a VM
		file.

CALLED BY:	VM relocation code
PASS:		heap semaphore grabbed
		ax	= memory block handle of lmem block
		dx	= segment of LMem block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECLMemInitHeap	proc	far
		call	PushAll
		mov	ds, dx

		push	ds:[LMBH_handle]
		mov	ds:[LMBH_handle], ax

	; First error check the block

		call	SysGetECLevel
		push	ax, bx
		mov	ax, mask ECF_LMEM
		call	SysSetECLevel

		call	LMValidateHeap

		pop	ax, bx
		call	SysSetECLevel
	;
	; First the in-use chunks
	;
		test	ds:[LMBH_flags], mask LMF_NO_HANDLES
		jnz	noHandles
		mov	cx, ds:[LMBH_nHandles]
		jcxz	noHandles
		mov	si, ds:[LMBH_offset]
handleLoop:
		mov	ax, ds:[si]	; NOT LODSW -- don't want to increment
					;  si if handle in-use
		inc	ax	
		jz	doneHandle	; => ax was -1, so No memory
		dec	ax
		jz	doneHandle	; => ax was 0, so Handle free
		push	si
		mov	si, ds:[si]
		call	ECInitEndOfChunk
		pop	si
doneHandle:
		inc	si
		inc	si
		loop	handleLoop
	;
	; Now the free blocks
	;
noHandles:
		mov	si, ds:[LMBH_freeList]
freeLoop:
		tst	si
		jz	done
		call	ECInitFreeChunk
		mov	si, ds:[si]	; ds:si = next free block
		jmp	freeLoop
done:
		pop	ds:[LMBH_handle]
		call	PopAll
		ret
ECLMemInitHeap	endp

ChunkArray segment resource		;reasonable place for EC code

;
; These are used by LMValidateChunk() to determine what additional error
; checking code should be done.
;
ChunkTypes	etype	byte
LM_FREE_CHUNK	enum	ChunkTypes
LM_USED_CHUNK	enum	ChunkTypes
LM_UNKNOWN_CHUNK enum	ChunkTypes


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMValidateHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a complete error check on the heap.

CALLED BY:	Internal.
PASS:		ds = segment address of the local-memory heap block.
RETURN:		nothing
DESTROYED:	nothing

CHECKS:		Entire heap for consistency.
		There are three types of error checking:
			ECF_LMEM
				- Do all error checking.
				- Check object flags.
			ECF_FREE
				- Check free list.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMValidateHeap	proc	far
if ERROR_CHECK
	push	ax, bp				;
	mov	ax, ds				;
	call	ECCheckSegment			;
	call	SysGetECLevel			; ax <- ec flags.
	mov	bp, ax
						;
	test	ax, mask ECF_LMEM
	jz	skipSizes			;
	call	LMValidateSizes			; check size variables.
skipSizes:					;
	test	ax, mask ECF_FREE
	jz	skipFreeList			;
	call	LMValidateFreeList		; check free list.
skipFreeList:					;
	test	ax, mask ECF_LMEM
	jz	skipHandleTable			;
	call	LMValidateHandleTable		; check handle table.
skipHandleTable:				;
	test	ax, mask ECF_LMEM
	jz	skipChunks			;
	call	LMValidateChunks		; check chunks.
skipChunks:					;
	test	ax, mask ECF_LMEM
	jz	skipFlags			;
	call	LMValidateFlags			; check objects (if obj block)
skipFlags:					;
	pop	ax, bp				;
	ret					;
endif
LMValidateHeap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMValidateSizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check heap-size variables.

CALLED BY:	Internal.
PASS:		ds = segment address of a local-memory heap block.
RETURN:		nothing
DESTROYED:	nothing

CHECKS:		Consistency of size variables.
		block size == 4 + infoOffset + size info + nHandles*2
				+ sum( chunk sizes ).

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMValidateSizes	proc	near
if ERROR_CHECK
	push	si, ax, cx, dx			;

	push	bx
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	mov	bx, ds:[LMBH_blockSize]
	add	bx, 15
	andnf	bx, 0xfff0
	cmp	bx, ax
	ERROR_NZ	LMEM_INVALID_BLOCK_SIZE
	pop	bx

	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	LMVS_done
	mov	cx, ds:LMBH_blockSize		; cx <- size of block.
						;
	mov	dx, cx				; dx <- size of block too.
	sub	dx, ds:LMBH_offset		; minus offset to handle table.
	mov	ax, ds:LMBH_nHandles		; ax <- size of handle table. 
	shl	ax, 1				;
	sub	dx, ax				; dx <- heap size.
	;
	; Now dx == sum( chunk sizes )      if everything is ok.
	; ds:si == ptr to the info struct.
	; ax    == size of handle table.
	; cx	== size of block total.
	;
	mov	si, ds:LMBH_offset		; ds:si <- ptr to handles.
	add	si, ax				; ds:si <- ptr to heap.
	sub	si, LMC_size			; ptr to block exactly.
LMVS_loop:					;
	cmp	si, cx				; check for gone too far.
	jae	LMVS_endLoop			;
	mov	ax, ds:[si].LMC_size		; ax <- size.
	RoundUp	ax				;
	cmp	ax, 4				; check size.
	jae	LMVS_sizeOK			;
	ERROR	LMEM_CHUNK_SIZE_LESS_THAN_FOUR	;
LMVS_sizeOK:					;
	sub	dx, ax				; subtract off chunk size.
	ERROR_C	LMEM_HEAP_SIZES_DONT_ADD_UP				
	add	si, ax				; advance to next chunk.
	jmp	LMVS_loop			;
LMVS_endLoop:					;
	tst	dx				; check for size OK.
	jz	LMVS_done			;
	ERROR	LMEM_HEAP_SIZES_DONT_ADD_UP	;
LMVS_done:					;
	pop	si, ax, cx, dx			;
	ret					;
endif
LMValidateSizes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMValidateFreeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate free list in a local memory heap.

CALLED BY:	Internal.
PASS:		ds = segment address of the local-memory heap block.
		bp = ErrorCheckingFlags
RETURN:		nothing
DESTROYED:	nothing

CHECKS:		Consistency of free list.
		1 - If no free list and totalFree == 0, then OK, else error.
		2 - Sum of chunks on the free list == totalFree.
		3 - All chunks on the free list are marked as free.
		4 - Validate each free chunk.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMValidateFreeList	proc	near
if ERROR_CHECK
	push	ax, dx, si
	clr	si				;
	mov	dx, ds:LMBH_totalFree		; dx <- total bytes free.
	mov	ax, ds:LMBH_freeList		; ds:ax <- ptr to 1st free.
	tst	ax				; check for done.
	jz	LMVFL_endLoop			; quit if we are.
LMVFL_loop:					;
	cmp	dx, ds:[LMBH_blockSize]
	ERROR_A	LMEM_FREE_SPACE_EXCEEDS_BLOCK_SIZE	
	;
	; ds:si == ptr to previous free block (or zero if no previous one).
	; ds:ax == ptr to current free block.
	; dx    == totalFree - space seen so far.
	;
	cmp	si, ax				; if previous > current then
	ERROR_AE LMEM_FREE_LIST_NOT_SORTED	;  free list not sorted.
	mov_tr	si, ax				; si <- chunk handle.
						;
	mov	al, LM_FREE_CHUNK		; Chunk is a free one.
	call	LMValidateChunk			; Check the chunk out.
						;
	mov	ax, ds:[si].LMC_size		;
	RoundUp	ax				;
	sub	dx, ax				; subtract off the size.
	ERROR_C	LMEM_SUM_OF_FREE_CHUNKS_EXCEEDS_LMBH_totalFree
	mov	ax, ds:[si]			; ax <- next next block.
	tst	ax				; check for no more.
	jnz	LMVFL_loop			; loop to check if there is.
LMVFL_endLoop:					;
	tst	dx				; check that sum of sizes is
	ERROR_NZ LMEM_FREE_SPACE_DOESNT_ADD_UP	; same as totalFree
	pop	ax, dx, si
	ret					;
endif
LMValidateFreeList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMValidateHandleTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the entire handle table.

CALLED BY:	Internal.
PASS:		ds = segment address of the local-memory heap block.
		bp = sysECLevel
RETURN:		nothing
DESTROYED:	nothing

CHECKS:		Consistency of entire handle table.
		1 - No two handles can refer to the same block.
		2 - Validate each handle in the table.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMValidateHandleTable	proc	near
if ERROR_CHECK

	push	es, di, si, ax, bx, cx		;
	test	bp, not mask ErrorCheckingFlags
	ERROR_NZ LMEM_BAD_EC_FLAGS

	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	LMVHT_done
	segmov	es, ds				; es == ds.
	mov	cx, ds:LMBH_nHandles		; cx <- number of handles.
	tst	cx				; no handles?
	jz	LMVHT_done			; yes, don't bother with this
	mov	di, ds:LMBH_offset		; di <- ptr to handles.
	mov	si, di				; si <- ptr to first handle.
LMVHT_loop:					;
	;
	; ds:si == ptr to current handle.
	; es:di == ptr to handle table.
	; cx    == number of handles left.
	;
	push	si			; save what's trashed by...
	call	LMValidateHandle	; Check this handle.
	pop	si
					;
	dec	cx			; one less to check.
	jcxz	LMVHT_done		; quit if done last one.
					;
	lodsw				; ax <- current ptr, advance si.
	tst	ax			; check for zero-pointer.
	jz	LMVHT_skip		;
	cmp	ax, -1			; check for handle w/o chunk.
	je	LMVHT_skip		;
	push	cx, di			; save count, ptr.
	mov	di, si			;
	repne	scasw			; search list for matching ptr.
	jne	LMVHT_noError		;
	ERROR	LMEM_TWO_HANDLES_WITH_THE_SAME_ADDRESS
LMVHT_noError:				;
	pop	cx, di			;
LMVHT_skip:				;
	jmp	LMVHT_loop		;
LMVHT_done:				;
	pop	es, di, si, ax, bx, cx	;
	ret				;
endif
LMValidateHandleTable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMValidateHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate an individual LMem block chunk handle.
		ASSUMES that ds points to a valid heap block which is
		an LMem block. (No checking is done to ensure this)

CALLED BY:	Internal.
PASS:		ds = segment address of the local-memory heap block.
		bp = sysECLevel
		ds:si = ptr to the handle to check.
RETURN:		nothing
DESTROYED:	ax, bx, si

CHECKS:		Handle for consistency.
		1 - Handle must fall within handle table.
		1 1/2 - handle MUST NOT be an odd value (all lmem handles
			are even)
		2 - If handle is zero then all is ok.
		3 - If handle is non-zero, validate the chunk it points to.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/13/89		Initial version
	df	1/16/90		Added check for non-even handle

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMValidateHandle	proc	far
if ERROR_CHECK
	test	bp, not mask ErrorCheckingFlags
	ERROR_NZ LMEM_BAD_EC_FLAGS

	test	si, 1				; if ODD, then bad LMem chunk
	ERROR_NZ LMEM_CHUNK_HANDLE_AT_ODD_ADDRESS

	mov	ax, ds:LMBH_nHandles		; ax <- # of handles.
	tst	ax				; are there even any?
	jz	beyond				; no, handle can't be valid then
	shl	ax, 1				; ax <- size of handle table.
	sub	si, ds:LMBH_offset		; si <- offset into table.
	jns	LMVH_notBelow			;
	ERROR	LMEM_HANDLE_BEFORE_HANDLE_TABLE	;
LMVH_notBelow:					;
	cmp	si, ax				; check for outside table.
	jb	LMVH_notAbove			;
beyond:
	ERROR	LMEM_HANDLE_BEYOND_HANDLE_TABLE	;
LMVH_notAbove:					;
	;
	; Handle is in the table, check for zero.
	;
	add	si, ds:LMBH_offset		; ds:si == handle.
	mov	si, ds:[si]			; ds:si <- chunk ptr
	tst	si				; check for empty handle.
	jz	LMVH_done			;
	cmp	si, -1				; check for handle w/o chunk.
	je	LMVH_done			;
	mov	al, LM_USED_CHUNK		; Chunk is in use.
	call	LMValidateChunk			; Check the chunk.
LMVH_done:					;
	ret					;
endif
LMValidateHandle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMValidateChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate all chunks on the heap.

CALLED BY:	Internal.
PASS:		ds = segment address of a local memory heap.
RETURN:		nothing
DESTROYED:	nothing

CHECKS:		Consistency of all chunks on the heap.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMValidateChunks	proc	near
if ERROR_CHECK	
	push	si, ax, bx			;
	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	LMVCs_done
	mov	ax, ds:LMBH_nHandles		;
	mov	bx, ds:LMBH_blockSize		; bx <- total size of block.
	mov	si, ds:LMBH_offset		; ds:si <- ptr to handles.
	add	si, ax				;
	add	si, ax				; ds:si <- ptr to heap.
	add	si, 2				; point into the first block.
LMVCs_loop:					;
	cmp	si, bx				; Check for out of bounds
	jae	LMVCs_done			;
	mov	al, LM_UNKNOWN_CHUNK		; Could be free, could be used.
	call	LMValidateChunk			; Check a chunk.
	mov	ax, ds:[si].LMC_size		;
	RoundUp	ax				;
	add	si, ax				; Move to next chunk.
	jmp	LMVCs_loop			;
LMVCs_done:					;
	pop	si, ax, bx			;
	ret					;
endif
LMValidateChunks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMValidateChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate a chunk.

CALLED BY:	Internal.
PASS:		al	= The type of chunk (ChunkTypes).
		bp = sysECLevel
		ds	= segment address of the local-memory heap block.
		ds:si	= ptr to chunk to validate.
RETURN:		nothing
DESTROYED:	nothing

CHECKS:		Chunk for consistency.
		- The address of the chunk falls inside the bounds of the
		  heap.
		- The address of the chunk is word-aligned (even).
		For free chunks:
		      - All bytes (except size and link) must be 0xcc.
		      - Next chunk is not free.
		For used chunks:
		      - All bytes after the end of the used data must be 0xcc.
		
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMValidateChunk	proc	far
if ERROR_CHECK
	uses	ax, bx, cx, es, di		;
	.enter					;
	test	bp, not mask ErrorCheckingFlags
	ERROR_NZ LMEM_BAD_EC_FLAGS
	push	ax				; Save chunk type.
	mov	ax, ds:LMBH_nHandles		;
	shl	ax, 1				; ax <- size of handle table.
	add	ax, ds:LMBH_offset		; ax <- offset to heap start.
	mov	bx, ds:LMBH_blockSize		; bx <- offset to heap end.
	;
	; Check for address passed being in bounds.
	;
	cmp	si, ax				; check for below heap start.
	jae	notBelow			;
	ERROR	LMEM_ADDR_BEFORE_HEAP_START	;
notBelow:					;
	cmp	si, bx				; check for above heap end.
	jb	notAbove			;
	ERROR	LMEM_ADDR_AFTER_HEAP_END	;
notAbove:					;
	test	si, 1				; Check for not word alinged
	ERROR_NZ LMEM_ADDR_NOT_WORD_ALIGNED	;
	pop	ax				; Restore chunk type.
						;
	cmp	al, LM_UNKNOWN_CHUNK		;
	je	done				;
	cmp	al, LM_FREE_CHUNK		;
	je	checkFreeChunk			;

	; only check cc's if FREE_AREAS checking is on

	test	bp, mask ECF_FREE
	jz	done
	;
	; A used chunk... Check space at the very end.
	; address = chunkAddr + chunkSize-2
	; nBytes  = chunkSize & 3
	;
	segmov	es, ds, cx			;
						;
	mov	cx, ds:[si].LMC_size		;
	mov	di, si				;
	add	di, cx				;
	sub	di, 2				; es:di <- ptr to space at end.
	;
	; The amount of space at the end of the chunk is 0, 1, 2, or 3 bytes.
	; What we want to do is round up the size of the chunk and subtract
	; off the value in LMC_size to get the amount to check.
	;
	mov	ax, cx				; Save value in LMC_size.
	RoundUp	cx				;
	sub	cx, ax				; cx <- # of bytes to check.
						;
	mov	al, 0xcc			; al <- byte to check.
	jcxz	done				; Quit if nothing to check.
	repe	scasb				;
	;
	; If this error is triggered, then you have written beyond the end
	; of a chunk, but not into the next chunk. The way that chunks are
	; allocated requires that all chunk sizes be multiples of four bytes.
	; This means that when you allocate a chunk, you may be given between
	; zero and three more bytes than you requested. This error is triggered
	; if you have somehow scribbled over these extra bytes.
	;
	ERROR_NZ LMEM_SPACE_AT_END_OF_USED_CHUNK_HAS_CHANGED
	jmp	done				;
checkFreeChunk:					;
	;
	; Free chunk, check all bytes.
	; es:di <- pointer to bytes in the free chunk.
	; cx <- size of chunk: total chunk size - size word - link word.
	;
	segmov	es, ds				;
	mov	di, si				;
	add	di, 2				; Skip free list link.
	mov	cx, ds:[si].LMC_size		;
	sub	cx, 4				;
	jae	wasLargerThanFourBytes		;
	ERROR	LMEM_FREE_CHUNK_SIZE_NOT_MULTIPLE_OF_FOUR
wasLargerThanFourBytes:				;
	mov	al, 0xcc			; al <- byte to check.
	jcxz	done				;
	repe	scasb				;
	;
	; This error occurs if a free chunk has been written to. Clearly if a
	; chunk is free, then you shouldn't be writing in it.
	;
	ERROR_NZ LMEM_FREE_CHUNK_HAS_BEEN_MODIFIED
done:						;
	.leave					;
	ret					;
endif
LMValidateChunk	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LMValidateFlags

DESCRIPTION:	Validate the flags chunk (if one exists)

CALLED BY:	LMValidateHeap

PASS:
	ds - lmem block

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

LMValidateFlags	proc	near
if ERROR_CHECK
	test	ds:[LMBH_flags], mask LMF_RELOCATED
	jz	afterObjBlock
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jne	afterObjBlock
	push	bx, si
	mov	bx, ds:[OLMBH_output].handle
	mov	si, ds:[OLMBH_output].chunk
	cmp	bx, ds:[LMBH_handle]
	je	outputChecked		; => will be checked later, and we
					;  don't want to recurse infinitely
	call	ECCheckOD
outputChecked:
	pop	bx, si
afterObjBlock:

	test	ds:[LMBH_flags],mask LMF_HAS_FLAGS
	jz	LMVF_ret
	test	ds:[LMBH_flags],mask LMF_RELOCATED
	jz	LMVF_ret
	push	ax, bx, cx, dx, si, di, bp, es

	mov	si,ds:LMBH_offset		;si = first handle
	mov	cx,ds:LMBH_nHandles		;cx = count
	mov	bp,ds:[si]			;ds:bp = flags
	jmp	short LMVF_next

	; *ds:si = chunk, ds:bp = flags, cx = count

LMVF_loop:
	mov	di,ds:[si]			;ds:di = chunk
	tst	di
	jz	LMVF_next
	cmp	di,-1
	jz	LMVF_next
	test	byte ptr ds:[bp], not mask ObjChunkFlags
	jz	LMVF_10
	ERROR	LMEM_BAD_FLAGS
LMVF_10:

	test	byte ptr ds:[bp],mask OCF_IS_OBJECT
	jz	LMVF_20
	les	di,dword ptr ds:[di]		;es:di = class
	call	ECCheckClass
LMVF_20:

LMVF_next:
	add	si,2
	inc	bp
	loop	LMVF_loop

	pop	ax, bx, cx, dx, si, di, bp, es
LMVF_ret:
endif
;
; This return is not if ERROR_CHECK'd out so all the routines
; can fall through to it and do nothing, but only waste one byte.
;
	ret

LMValidateFlags	endp

ChunkArray ends

endif
