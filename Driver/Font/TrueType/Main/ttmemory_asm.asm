COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		TrueType Font Driver
FILE:		ttmemory_asm.asm

AUTHOR:		Andrew Wilson, Sep 17, 1991

ROUTINES:
	Name			Description
	----			-----------
	_Malloc			allocs fixed memory
	_Free			frees fixed memory

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/17/91		Initial revision
	schoon  6/11/92		Revised for ANSI C standards
	marcusg 7/29/23	Adapted for TrueType driver

DESCRIPTION:
	This file contains the PC/GEOS implementations of the C routines
	TT_Alloc(), TT_Free(), TTMemory_Init(), TTMemory_Done(), to avoid
	the need to link to the ansic library.

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ttmemory_TEXT	segment	public	'CODE'

.model	medium, c


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddHandleToMallocList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a handle to the associated list of handles.

CALLED BY:	GLOBAL
PASS:		ds:[LMBH_handle] - handle to add
		cx - handle of block containing list of blocks
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

	mov	bx, handle 0		;current Geode
	mov	ax, SLOT_INCREMENT*2	;
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or (mask HAF_ZERO_INIT shl 8)
	call	MemAllocSetOwner
	jc	exit			;If we could not allocate the block,
					; branch.
	mov	es, ax			;
	mov	{word} es:[0], SLOT_INCREMENT-1;
	push	ds
NOFXIP<	segmov	ds, <segment udata>, cx				>
FXIP <	mov	bx, handle dgroup				>
FXIP <	call	MemDerefDS		; ds = dgroup		>
	mov	ds:[di], bx		;
	pop	ds
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
		cx - handle of block containing list of blocks
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

	mov	dx, ds:[LMBH_handle]
EC <	jcxz	nullError		;If no block, fail >

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
PASS:		cx - handle of block containing list of blocks
RETURN:		dx - # free blocks
DESTROYED:	ax, bx, di, ds
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCountFreeBlocksOnMallocList	proc	near
	uses	cx, si, es
	.enter

;	Read in the handle of the block containing the list of blocks

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
PASS:		cx - # bytes to allocate
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
FXIP <	mov	bx, handle dgroup				>
FXIP <	call	MemDerefDS		; ds = dgroup		>
	mov	cx, ds:[smallListHandle]	;
	pop	ds
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
	call	MemAllocSetOwner		;Try to allocate memory
	mov	ds, ax
	ret
MemAllocFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_TT_Alloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine allocates fixed memory for C programs to use.

C DECLARATION:	TT_Error TT_Alloc(word blockSize, void**p);

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
global _TT_Alloc:far
_TT_Alloc	proc	far	blockSize:word, p:fptr
	uses	ds, di, si
	.enter		
	mov	cx, blockSize

	tst	cx
	jz	zeroAlloc		;zero-sized allocs are valid

;	Mallocs of over MALLOC_LARGE_THRESHOLD should be put in their own
;	fixed block.

	cmp	cx, MALLOC_LARGE_THRESHOLD
	ja	largeAlloc

;	Scan through the list of fixed lmem blocks to allocate this 
;	small block.

	call	AllocInSmallList	;Try to allocate in various blocks
					; in small list (returns pointer in
					; DS:AX).
	jnc	zinitAndExit		;Branch if successful

;	Could not allocate in already existing lmem block, so allocate a new
;	lmem block and allocate in it.

	mov	ax, MALLOC_SMALL_BLOCK_SIZE
	mov	bx, handle 0		;current Geode
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
	mov	di, offset smallListHandle
	jmp	mallocCommon		;Branch to add block to list, and
					; to return pointer to block

largeAlloc:

;	Allocate a fixed block on the heap with the handle of the block at the
;	start, and the remainder of the block to be returned for use by the
;	caller.

	add	cx, LARGE_BLOCK_OFFSET	;These blocks have the handle of the
	xchg	ax, cx			; block at the start. Put size in AX.
	mov	bx, handle 0		;current Geode
	call	MemAllocFixed		;
	jc	errRet			;If we couldn't, branch
	mov	dx, bx			;DX <- handle of new block
	mov	ds:[0], bx		;Save handle of block

	mov	di, offset largeListHandle
					;DI <- offset to handle of block
					; containing list of large data blocks
					; (in the GeodePrivData area reserved
					;  for the malloc routines).
	mov	ax, LARGE_BLOCK_OFFSET	;DS:AX <- pointer to data just alloc'd

mallocCommon:
;	Get the handle to the block list indicated by DI

	push	ds
NOFXIP<	segmov	ds, <segment udata>, bx				>
FXIP <	mov	bx, handle dgroup				>
FXIP <	call	MemDerefDS		; ds = dgroup		>
	mov	cx, ds:[di]		;
	pop	ds
	call	AddHandleToMallocList	;Add handle at DS:0 to malloc list
	jc	freeError		;If couldn't add to list, branch and
					; exit.
zinitAndExit:				;
	mov	dx, ds			;DX:AX <- pointer to data
	push	es
	push	ax
	mov	es, dx			;ES:DI <- pointer to block
	xchg	di, ax
	clr	ax
	mov	cx, blockSize
	shr	cx, 1
	jnc	80$
	stosb	
80$:
	rep	stosw
	pop	ax			;DX:AX <- pointer to block
exitWithPtr:
	les	di, p
	mov	es:[di].low, ax
	mov	es:[di].high, dx
	pop	es
	mov	ax, 0			;TT_Err_Ok
exit:	
	.leave
	ret

freeError:
	mov	bx, dx			;Free up the block
	call	MemFree
errRet:
	mov	ax, 100h		;TT_Err_Out_Of_Memory
	jmp	exit

zeroAlloc:
	clr	ax			;Return zero pointer
	clr	dx
	push	es
	jmp	exitWithPtr
_TT_Alloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_TT_Free
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up a block previously returned from _TT_Alloc.

CALLED BY:	GLOBAL

C DECLARATION:	TT_Error _Free(void **p);

PSEUDO CODE/STRATEGY:
		Accepts p or *p being NULL.
		If the block is freed, *p is set to NULL.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _TT_Free:far
_TT_Free	proc	far	p:fptr
	uses	es, ds, di, si
	.enter		
	tst	p.high				;no pointer passed
	jz	exit				;nothing to do
	les	si, p
	tst	es:[si].high			;pointer is already NULL?
	jz	exitZero			;nothing to do

	cmp	es:[si].low, LARGE_BLOCK_OFFSET
	jne	smallBlockFree

;	The free block was large (allocated as a single block on the global
;	heap). Remove the block from the list, and free it up.

NOFXIP< segmov	ds, <segment udata>, di					>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
	mov	cx, ds:[largeListHandle]	;cx <- handle of large
						; block list
freeAndRemoveBlock:
	mov	ds, es:[si+2]
	call	RemoveHandleFromMallocList	;
	mov	bx, ds:[LMBH_handle]
	call	MemFree				;Free up the handle
	jmp	exit
smallBlockFree:
	lds	ax, es:[si]			;If small block, just free
	call	LMemFree			; up the chunk. We never 
						; return this memory to the
						; global heap.

;	If the block is now empty, free it.

	cmp	ds:[LMBH_totalFree], MALLOC_SMALL_BLOCK_SIZE - size LMemBlockHeader
	jne	exitZero			; Branch if block is non-empty

NOFXIP<	segmov	ds, <segment udata>, di					>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
	mov	cx, ds:[smallListHandle]	;cx <- handle of small

EC <	call	ECCountFreeBlocksOnMallocList	;			>
EC <	cmp	dx, 2				;			>
EC <	ERROR_A	MORE_THAN_ONE_FREE_MALLOC_BLOCK				>
	jmp	freeAndRemoveBlock
exitZero:
	clr	ax
	mov	es:[si], ax
	mov	es:[si+2], ax
exit:
	mov	ax, 0				;TT_Err_Ok
	.leave
	ret
_TT_Free	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_TTMemory_Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine initializes the heap.

C DECLARATION:

TT_Error TTMemory_Init()

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	marcusg	7/29/23		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global _TTMemory_Init:far
_TTMemory_Init	proc	far
	uses	ds, di, bx
	.enter		
NOFXIP<	segmov	ds, <segment udata>, di					>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
	clr     bx
	mov	ds:[smallListHandle], bx	;initialize: no lists yet
	mov	ds:[largeListHandle], bx
	mov	ax, 0				; TT_Err_Ok
	.leave
	ret
_TTMemory_Init	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_TTMemory_Done
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine should deinitialize the heap if needed.

C DECLARATION:

TT_Error TTMemory_Done()

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	marcusg	7/29/23		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global _TTMemory_Done:far
_TTMemory_Done	proc	far
	mov	ax, 0			; TT_Err_Ok
	ret
_TTMemory_Done	endp

ttmemory_TEXT	ends
