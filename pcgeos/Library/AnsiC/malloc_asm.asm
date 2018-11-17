COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		AnsiC library
FILE:		malloc_asm.asm

AUTHOR:		Andrew Wilson, Sep 17, 1991

ROUTINES:
	Name			Description
	----			-----------
	_Malloc			allocs fixed memory
	_ReAlloc		resizes fixed memory
	_Free			frees fixed memory

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/17/91		Initial revision
	schoon  6/11/92		Revised for ANSI C standards

DESCRIPTION:
	This file contains the PC/GEOS implementations of the C routines
	malloc(), calloc(), realloc(), cfree(), and free().

NOTES:
	There are 2 allocation strategies used by this code. If the block size
	is below MALLOC_LARGE_THRESHOLD, then it is allocated in one of the
	fixed LMem heaps kept for this purpose. If the block size is above
	the threshold, then the memory is allocated in a global memory block
	by itself. Since the pointer to memory returned by the "large" strategy
	is below any of the valid pointers returned by the "small" strategy 
	(due to the fact that the small blocks all lie beyond the 
	LMemBlockHeader at the start of the lmem blocks, while the large 
	blocks all lie at LARGE_BLOCK_OFFSET, which is less than the
	LMemBlockHeader), we are able to tell which type of block it is just
	by looking at the address.

	When we free these blocks, we have a different strategy for each.
	When we free a large block, we just call MemFree on the block. If 
	it is a small block, we free the chunk, and then check to see if that
	LMem block is now empty. If it isn't, we just exit. If it is, we scan
	through the list of lmem blocks to see if it is the only lmem block.
	if it isn't, we free it up (so we have at most one empty lmem block
	hanging around per geode).

	In the GeodePrivData for each geode we keep 2 words - the first one
	is the handle of a block containing a list of handles of lmem blocks
	used for the small allocation scheme. The second one is the handle
	of a block containing a list of handles of global memory blocks 
	containing blocks allocated via the large allocation scheme.
	The format of these blocks is as follows:

		word	numberOfEntriesInList	;This includes any empty slots
		word	entry1
		word	entry2
		word	entry3
			.
			.
			.

	$Id: malloc_asm.asm,v 1.1 97/04/04 17:42:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include ansicGeode.def


;RESIDENT	segment	word	public	'CODE'
;MAINCODE	segment	word	public	'CODE'
MAINCODE	segment	public	'CODE'

.model	medium, pascal

GeodePrivReadOneWord	proc	near	;Returns value in CX
	mov	cx, 1		;Read one word
	push	ax
	segmov	ds, ss
	mov	si, sp		;DS:SI <- ptr to word on stack
	call	GeodePrivRead
	pop	cx		;	
	ret
GeodePrivReadOneWord	endp

GeodePrivWriteOneWord	proc	near	;Pass value to write in CX
	push	cx
	mov	cx, 1		;Write one word
	segmov	ds, ss
	mov	si, sp		;DS:SI <- ptr to word on stack
	call	GeodePrivWrite
	pop	cx		;	
	ret
GeodePrivWriteOneWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddHandleToMallocList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a handle to the associated list of handles.

CALLED BY:	GLOBAL
PASS:		ds:[LMBH_handle] - handle to add
		bx - geode whose privData we should use
		di - offset to pass to GeodePrivRead/GeodePrivWrite
RETURN:		carry set if error
DESTROYED:	bx, cx, dx, di, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SLOT_INCREMENT	equ	8
AddHandleToMallocList	proc	near	uses	ds, es, bp, ax
	.enter

;	Read in the handle of the block containing the list of blocks

	mov	dx, ds:[LMBH_handle]
	call	GeodePrivReadOneWord
	jcxz	doMalloc	;If no block, allocate a new one

;	Scan through the block looking for an empty slot to store the new
;	handle. 

	mov	bx, cx
	call	MemLock
	mov	es, ax
scanTop:
	mov	di, 2
	mov	cx, es:[0]	;CX <- # items in block
	clr	ax
	repne	scasw		;Look for an empty spot
	jne	reAlloc		;Branch if no empty slots found

	mov	es:[di][-2], dx	;Save handle in empty slot
	clc			;Signify no errors
unlockExit:
	call	MemUnlock	;Unlock the block
exit:	
	.leave
	ret
reAlloc:

;	No empty slots found, so reallocate the block bigger (create some).

	mov	ax, es:[0]
	inc	ax		;AX <- # words in block currently
	shl	ax, 1		;AX <- # bytes in block
	add	ax, SLOT_INCREMENT*2	;Add room for 8 more slots
	mov	ch, mask HAF_ZERO_INIT
	call	MemReAlloc
	jc	unlockExit	;If error reallocing, branch
	mov	es, ax
	add	{word} es:[0], SLOT_INCREMENT	;
	jmp	scanTop
doMalloc:

;	ALLOCATE A NEW BLOCK TO HOLD DATA

	mov	bp, bx			;BP <- geode handle
	mov	ax, SLOT_INCREMENT*2	;
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or (mask HAF_ZERO_INIT shl 8)
	call	MemAllocSetOwnerOrDefault
	jc	exit			;If we could not allocate the block,
					; branch.
	mov	es, ax			;
	mov	{word} es:[0], SLOT_INCREMENT-1;
	mov	cx, bx			;
	mov	bx, bp			;BX <- GeodeHandle
	call	GeodePrivWriteOneWord	;Store the handle in the GeodePrivData
	mov	bx, cx			; area. 
	jnc	scanTop			;If no error, branch
	call	MemFree			;Else, free up this block and exit.
	stc
	jmp	exit
AddHandleToMallocList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveHandleFromMallocList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a handle from the associated list of handles.

CALLED BY:	GLOBAL
PASS:		ds:[LMBH_handle] - handle to remove
		bx - geode whose privData we should use
		di - offset to pass to GeodePrivRead/GeodePrivWrite
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveHandleFromMallocList	proc	near	uses	es, ds
	.enter

;	Read in the handle of the block containing the list of blocks

	mov	dx, ds:[LMBH_handle]
	call	GeodePrivReadOneWord
EC <	jcxz	nullError		;If no block, allocate a new one >

;	Scan through the block looking for the passed handle.

	mov	bx, cx
	call	MemLock
	mov	es, ax
	mov	di, 2
	mov	cx, es:[0]	;CX <- # items in block
	mov	ax, dx
	repne	scasw		;Look for an empty spot
EC <	ERROR_NZ HANDLE_NOT_FOUND_IN_LIST_OF_MALLOC_BLOCKS		>

	mov	{word} es:[di][-2], 0	;Nuke handle
	call	MemUnlock
	.leave
	ret
EC <nullError:								>
EC <	ERROR	FREE_CALLED_BEFORE_MALLOC				>
RemoveHandleFromMallocList	endp


if ERROR_CHECK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCountFreeBlocksOnMallocList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Counts total number of malloc heaps with no items

CALLED BY:	_Free
PASS:		bx - geode whose privData we should use
		di - offset to pass to GeodePrivRead/GeodePrivWrite
RETURN:		dx - # free blocks
DESTROYED:	ax, bx, cx, di, si, ds, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCountFreeBlocksOnMallocList	proc	near
	.enter

;	Read in the handle of the block containing the list of blocks

	call	GeodePrivReadOneWord
	jcxz	nullError		;If no block, fail

;	Traverse the block counting the # empty blocks

	mov	bx, cx
	call	MemLock
	push	bx
	mov	ds, ax
	mov	si, 2
	mov	cx, ds:[0]	;CX <- # items in block
	clr	dx
findNext:
	lodsw
	tst	ax
	jz	next
	xchg	ax, bx
	call	MemDerefES
	cmp	es:[LMBH_totalFree], MALLOC_SMALL_BLOCK_SIZE - size LMemBlockHeader
	jne	next		;If not empty, branch
	inc	dx		;Else, increment count of empty blocks
next:
	loop	findNext
	pop	bx
	call	MemUnlock	;
	.leave
	ret
nullError:
	ERROR	FREE_CALLED_BEFORE_MALLOC
ECCountFreeBlocksOnMallocList	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocInSmallList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Traverses the list of lmem blocks and tries to allocate 
		the passed # bytes in each one until it is successful

CALLED BY:	GLOBAL
PASS:		bx - geode whose privData we should use
		cx - # bytes to allocate
RETURN:		ds:ax <- pointer to block allocated
		carry set if unsuccessful
DESTROYED:	ax, bx, cx, di, si, ds
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocInSmallList	proc	near
	.enter

;	Read in the handle of the block containing the list of blocks

	mov	dx, cx			;DX <- size 
	push	ds
NOFXIP<	segmov	ds, dgroup, di					>
FXIP <	push	bx						>
FXIP <	mov	bx, handle dgroup				>
FXIP <	call	MemDerefDS		; ds = dgroup		>
FXIP <	pop	bx						>
	mov	di, ds:[mallocOffset]	;
	pop	ds
	call	GeodePrivReadOneWord
	stc
	jcxz	exit			;If no blocks allocated, exit 
	
;	Traverse the block and attempt to allocate in each one (ignoring
;	empty slots).

	mov	bx, cx
	mov	cx, dx		;CX <- # bytes to allocate
	push	bx
	call	MemLock
	mov	ds, ax
	mov	si, 2
	mov	dx, ds:[0]	;CX <- # items in block
findNext:
	lodsw
	tst	ax
	jz	next		;If handle is null, branch (empty slot)
	mov	di, ds		;.
	xchg	ax, bx		;BX <- handle of this lmem block
	call	MemDerefDS	;DS <- segment of this lmem block
	call	LMemAlloc	;Try to allocate here
	jnc	success		;Branch if no error allocating
	mov	ds, di		;
next:
	dec	dx		;Decrement # handles to try
	jnz	findNext	;
	stc			;Unsuccessful, so unlock and exit w/carry set
success:
	pop	bx		;Unlock list of blocks
	call	MemUnlock	; 
exit:
	.leave
	ret
AllocInSmallList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemAllocFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a front end to MemAlloc

CALLED BY:	GLOBAL
PASS:		ax - size of block to alloc
		bx - owner of block
RETURN:		ds - segment of block
		+ rest of MemAlloc return values
DESTROYED:	cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemAllocFixed	proc	near
	mov	cx, mask HF_FIXED or mask HF_SHARABLE
	call	MemAllocSetOwnerOrDefault
	mov	ds, ax
	ret
MemAllocFixed	endp

MemAllocSetOwnerOrDefault	proc	near
	tst	bx				;If an owner is passed in,
	jnz	setOwner			; then set the owner.
	call	MemAlloc			;Else, use current process
	jmp	exit
setOwner:
	call	MemAllocSetOwner		;Try to allocate memory
exit:
	ret
MemAllocSetOwnerOrDefault	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_Malloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine allocates fixed memory for C programs to use.

C DECLARATION:

extern void _far _pascal 
  	*_Malloc(size_t blockSize, GeodeHandle geodeHan, word zeroInit)

NOTES:	geodeHan can be 0, if you just want to use the current process'
	malloc heap.
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MALLOC_LARGE_THRESHOLD	equ	511
MALLOC_SMALL_BLOCK_SIZE	equ	1024
LARGE_BLOCK_OFFSET	equ	size hptr
global _Malloc:far
_Malloc	proc	far	blockSize:word, geodeHan:hptr, zinit:word
	uses	ds, di, si
	.enter		
	mov	cx, blockSize
EC <	tst	cx							>
EC <	ERROR_Z	GEO_MALLOC_PASSED_SIZE_OF_ZERO				>

;	Mallocs of over MALLOC_LARGE_THRESHOLD should be put in their own
;	fixed block.

	cmp	cx, MALLOC_LARGE_THRESHOLD
	ja	largeAlloc

;	Scan through the list of fixed lmem blocks to allocate this 
;	small block.

	mov	bx, geodeHan
	call	AllocInSmallList	;Try to allocate in various blocks
					; in small list (returns pointer in
					; DS:AX).
	jnc	zinitAndExit		;Branch if successful

;	Could not allocate in already existing lmem block, so allocate a new
;	lmem block and allocate in it.

	mov	ax, MALLOC_SMALL_BLOCK_SIZE
	mov	bx, geodeHan
	call	MemAllocFixed		;Try to allocate new lmem block.
	jc	errRet			;If unsuccessful, branch to exit.
	mov	ax, LMEM_TYPE_GENERAL
	mov	dx, size LMemBlockHeader
	mov	di, mask LMF_NO_HANDLES or mask LMF_NO_ENLARGE or mask LMF_RETURN_ERRORS
	push	bp
	clr	bp
	call	LMemInitHeap
	pop	bp

;	Allocate a new chunk on the just-allocated lmem heap.

	mov	cx, blockSize
	call	LMemAlloc
EC <	ERROR_C	COULD_NOT_ALLOC_BLOCK_WHEN_THERE_SHOULD_BE_ROOM_FOR_IT	>
	clr	di
	jmp	mallocCommon		;Branch to add block to list, and
					; to return pointer to block

largeAlloc:

;	Allocate a fixed block on the heap with the handle of the block at the
;	start, and the remainder of the block to be returned for use by the
;	caller.


	add	cx, LARGE_BLOCK_OFFSET	;These blocks have the handle of the
	xchg	ax, cx			; block at the start. Put size in AX.
	mov	bx, geodeHan
	call	MemAllocFixed		;
	jc	errRet			;If we couldn't, branch
	mov	dx, bx			;DX <- handle of new block
	mov	ds:[0], bx		;Save handle of block


	mov	di, 2			;DI <- offset to handle of block
					; containing list of large data blocks
					; (in the GeodePrivData area reserved
					;  for the malloc routines).
	mov	ax, LARGE_BLOCK_OFFSET	;DS:AX <- pointer to data just alloc'd

mallocCommon:

;	Get the offset to the GeodePriv area reserved for the malloc routines.

	push	ds
NOFXIP<	segmov	ds, <segment udata>, bx				>
FXIP <	mov	bx, handle dgroup				>
FXIP <	call	MemDerefDS		; ds = dgroup		>
	add	di, ds:[mallocOffset]	;
	pop	ds
	mov	bx, geodeHan		;
	call	AddHandleToMallocList	;Add handle at DS:0 to malloc list
	jc	freeError		;If couldn't add to list, branch and
					; exit.
zinitAndExit:				;
	mov	dx, ds			;DX:AX <- pointer to data
	tst	zinit			;If no zero-init desired, just branch
	jz	exit

	push	es, ax
	mov	es, dx			;ES:DI <- pointer to block
	xchg	di, ax
	clr	ax
	mov	cx, blockSize
	shr	cx, 1
	jnc	80$
	stosb	
80$:
	rep	stosw
	pop	es, ax			;DX:AX <- pointer to block
exit:	
	.leave
	ret

freeError:
	mov	bx, dx			;Free up the block
	call	MemFree
errRet:
	clr	dx
	clr	ax
	jmp	exit
_Malloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_Free
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up a block previously returned from _Malloc.

CALLED BY:	GLOBAL
C DECLARATION:
    extern void _far _pascal _Free(void *blockPtr, GeodeHandle geodeHan);

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _Free:far
_Free	proc	far	blockPtr:fptr, geodeHan:hptr
	uses	ds, di, si
	.enter		
EC <	tst	blockPtr.high						>
EC <	ERROR_Z	NULL_PTR_PASSED_TO_GEO_FREE				>
	cmp	blockPtr.low, LARGE_BLOCK_OFFSET
	jne	smallBlockFree

;	The free block was large (allocated as a single block on the global
;	heap). Remove the block from the list, and free it up.

NOFXIP< segmov	ds, <segment udata>, di					>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
	mov	di, ds:[mallocOffset]		;DI <- ptr to handle of large
	add	di, 2				; block list in GeodePrivData
freeAndRemoveBlock:
	mov	bx, geodeHan			;
	mov	ds, blockPtr.segment
	call	RemoveHandleFromMallocList	;
	mov	bx, ds:[0]
	call	MemFree				;Free up the handle
	jmp	exit
smallBlockFree:
	lds	ax, blockPtr			;If small block, just free
	call	LMemFree			; up the chunk. We never 
						; return this memory to the
						; global heap.

;	If the block is now empty, free it.

	cmp	ds:[LMBH_totalFree], MALLOC_SMALL_BLOCK_SIZE - size LMemBlockHeader
	jne	exit				; Branch if block is non-empty

	push	ds
NOFXIP<	segmov	ds, <segment udata>, di					>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
	mov	di, ds:[mallocOffset]		;DI <- ptr to handle of small
	pop	ds				; block list in GeodePrivData

EC <	mov	bx, geodeHan			;			>
EC <	call	ECCountFreeBlocksOnMallocList	;			>
EC <	cmp	dx, 2				;			>
EC <	ERROR_A	MORE_THAN_ONE_FREE_MALLOC_BLOCK				>
	jmp	freeAndRemoveBlock
exit:
	.leave
	ret
_Free	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_ReAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ReAllocates a previously _Malloc'd block of memory.

CALLED BY:	GLOBAL

C DECLARATION:	extern void _far _pascal 
  	*_ReAlloc(void *blockPtr, size_t newSize, GeodeHandle geodeHan);

 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
 *
 *	1) If the space is resized larger, new space is *not* zero-initialized.
 *
 *	2) If realloc() is called to resize the memory *smaller*, it will
 *	   always succeed.
 *
 *	3) If realloc() does not succeed, it will return NULL, and the original
 *	   memory block will be unaffected.
 *
 *	4) If the passed blockPtr is NULL, realloc() acts like malloc().
 *
 *	5) If the passed newSize is 0, the passed blockPtr is freed, and
 *	   NULL is returned.
 *
 *	6) The block *may* move.
 *	   
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _ReAlloc:far
_ReAlloc	proc	far	blockPtr:fptr, newSize:word, geodeHan:hptr
	uses	ds
	.enter

;	Handle special goofy cases (null size or block ptr passed in)

	mov	cx, newSize
	tst	blockPtr.high	;If null block ptr, pass off to malloc()
	jz	doMalloc	;
	jcxz	doFree		;If zero new size, pass off to free()
	mov	ds, blockPtr.high
	cmp	blockPtr.low, LARGE_BLOCK_OFFSET;If large block, use
	je	largeBlockReAlloc		; appropriate realloc method

;	If this is a "small" block, then try to LMemReAlloc it. If that fails,
;	then try malloc-ing a new block, and copying the data over.

	mov	ax, blockPtr.low		;DS:AX <- ptr to block
	call	LMemReAlloc			;
	mov	dx, ds				;DX:AX <- ptr to block
if 0
	jc	20$				;Error

;       Copy data from blockptr to new chunk and delete blockptr.
;       LMemRealloc does not always resize blockptr, instead it may
;	allocate a new chunk.
;
	cmp 	ax, blockPtr.low
	je	exit				;No new chunk, so done
	push	es, di, si
	jmp	30$			;Copy and delete.
else
;
; For LMF_NO_HANDLES, if LMemReAlloc has to allocate a new chunk, it will
; copy over the data itself and delete the old chunk, so we don't need to
; do this -- brianc 11/17/98 (yes, '98)
;
	jnc	exit
endif

;	Simple allocation failed. malloc() new block and copy the data over.
20$:
	push	es, di, si
	push	newSize				
	push	geodeHan
	clr	ax
	push	ax
	call	_Malloc
	tst	dx			;If malloc failed, branch
	jz	mallocFailed

;	Copy the data from the old block into the newly alloc'd block.
30$:
	mov	si, blockPtr.low	;DS:SI <- ptr to original block
	ChunkSizePtr	ds, si, cx	;CX <- size of original block (data to
					; copy over).
EC <	cmp	cx, newSize						>
EC <	ERROR_AE	LMEM_REALLOC_FAILED_WHEN_MAKING_CHUNK_SMALLER	>
	mov	es, dx
	mov	di, ax
	shr	cx, 1
	jnc	10$
	movsb
10$:
	rep	movsw

;	Free the old block up.

	push	dx, ax
	push	blockPtr.high
	push	blockPtr.low
	push	geodeHan
	call	_Free
	pop	dx, ax
mallocFailed:
	pop	es, di, si
exit:
	.leave
	ret
doFree:
	push	blockPtr.high
	push	blockPtr.low
	push	geodeHan
	call	_Free
	jmp	clrRet
doMalloc:
EC <	tst	blockPtr.low						>
EC <	ERROR_NZ	INVALID_PTR_PASSED_TO_GEO_REALLOC		>
	push	cx			; newSize
	push	geodeHan
	clr	ax			;Do not zero init
	push	ax
	call	_Malloc
	jmp	exit

;	For large blocks, the data lies in a global memory block by itself.
;	Just call MemReAlloc routine.
largeBlockReAlloc:
	mov	ds, blockPtr.high
	mov_tr	ax, cx
	add	ax, LARGE_BLOCK_OFFSET
	clr	ch
	mov	bx, ds:[0]		;ReAllocate the block
	call	MemReAlloc
	xchg	dx, ax			;DX <- segment of fixed block
	mov	ax, LARGE_BLOCK_OFFSET	;DX:AX <- ptr to large block
	jnc	exit			;If no error in the realloc, branch
clrRet:
	clr	ax, dx
	jmp	exit
_ReAlloc	endp

;RESIDENT	ends
MAINCODE	ends
