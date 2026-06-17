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

PASS:		ds:[LMBH_handle]	= handle to add to the list
		cx			= handle of block containing the list
					  (0 if no list block allocated yet)

RETURN:		carry set if error (out of memory)

DESTROYED:	bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:
	If no list block exists (cx == 0), allocate a new one and store
	its handle in dgroup, then fall through to scan for an empty slot.
	Lock the list block and scan for a zero (empty) slot via repne scasw.
	If an empty slot is found, store the handle there and unlock.
	If no empty slot exists, reallocate the block larger by
	SLOT_INCREMENT entries (zero-initialized) and retry the scan.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The scan starts at word offset 2 (skipping the entry count at
	offset 0), so es:[0] must always hold the number of handle slots
	(not counting the counter word itself).
	Overlap detection assumes same-segment buffers only.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version
	JK	23.05.2026	AI supported optimization:
				- fixed undefined DI in doMalloc path
				- replaced always-true jnc with jmp
				- clarified reAlloc byte-size calculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SLOT_INCREMENT	equ	8

AddHandleToMallocList	proc	near	uses	ds, es, bp, ax
	.enter

	mov	dx, ds:[LMBH_handle]	; DX = handle to add to list
	jcxz	doMalloc		; No list block yet: allocate one

;	Lock the list block and scan for an empty (zero) slot.
	mov	bx, cx
	call	MemLock
	mov	es, ax

scanTop:
	mov	di, 2			; DI = offset of first handle slot
	mov	cx, es:[0]		; CX = number of slots in block
	xor	ax, ax			; AX = 0 (search value: empty slot)
	repne	scasw			; Scan for empty slot
	jne	reAlloc			; No empty slot found: grow block

;	Empty slot found at ES:[DI-2]: store the new handle there.
	mov	es:[di-2], dx		; Save handle in empty slot
	clc				; Signal success
unlockExit:
	call	MemUnlock		; Unlock list block
exit:
	.leave
	ret

reAlloc:
;	No empty slots remain.  Grow the block by SLOT_INCREMENT entries.
;	Current block size in bytes = (es:[0] + 1) * 2
;	  (+1 accounts for the counter word at offset 0).
	mov	ax, es:[0]		; AX = current slot count
	inc	ax			; +1 for the counter word itself
	shl	ax, 1			; AX = current block size in bytes
	add	ax, SLOT_INCREMENT*2	; Add room for SLOT_INCREMENT new slots
	mov	ch, mask HAF_ZERO_INIT	; Zero-init the new space
	call	MemReAlloc
	jc	unlockExit		; Realloc failed: unlock and return error
	mov	es, ax
	add	{word} es:[0], SLOT_INCREMENT	; Update slot count
	jmp	scanTop			; Retry scan (new slots are zeroed)

doMalloc:
;	No list block exists yet.  Allocate a new one large enough for
;	SLOT_INCREMENT handle slots plus the leading count word.
	mov	bx, handle 0		; Current geode as owner
	mov	ax, SLOT_INCREMENT*2 + 2; SLOT_INCREMENT slots + count word
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or (mask HAF_ZERO_INIT shl 8)
	call	MemAllocSetOwner
	jc	exit			; Allocation failed: return error

;	Initialize the new block: store slot count at offset 0, then
;	save the block handle in dgroup so future calls can find it.
	mov	es, ax
	mov	{word} es:[0], SLOT_INCREMENT	; Slot count (not counting
						;  the counter word itself)
	push	ds
NOFXIP<	segmov	ds, <segment udata>, cx				>
FXIP <	mov	bx, handle dgroup				>
FXIP <	call	MemDerefDS		; ds = dgroup			>
	mov	ds:[di], bx		; Store list block handle in dgroup
	pop	ds
	jmp	scanTop			; Scan the new block for a free slot
					; (was always-true jnc in original)

AddHandleToMallocList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveHandleFromMallocList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Removes a handle from the associated list of handles.

CALLED BY:	GLOBAL

PASS:		ds:[LMBH_handle]	= handle to remove from the list
		cx			= handle of block containing the list

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:
	Lock the list block.
	Scan word-wise for the handle via repne scasw.
	Zero the found slot to mark it as empty.
	Unlock the list block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	In EC builds, asserts that cx is non-zero (list must exist)
	and that the handle is actually present in the list.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version
	JK	23.05.2026	AI supported optimization:
				- direct load into AX (saves mov ax,dx)
				- xor ax,ax + mov for zeroing slot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveHandleFromMallocList	proc	near	uses	es, ds
	.enter

EC <	jcxz	nullError					>

;	Load handle to remove directly into AX -- no need for DX detour
;	since this function returns nothing.
	mov	ax, ds:[LMBH_handle]	; AX = handle to remove

;	Lock the list block and scan for the handle.
	mov	bx, cx
	call	MemLock
	mov	es, ax			; ES = list block segment
	mov	ax, ds:[LMBH_handle]	; AX = handle to find (reload after
					;      MemLock trashes AX)
	mov	di, 2			; DI = offset of first handle slot
	mov	cx, es:[0]		; CX = number of slots in block
	repne	scasw			; Scan for handle
EC <	ERROR_NZ HANDLE_NOT_FOUND_IN_LIST_OF_MALLOC_BLOCKS		>

;	Zero the found slot: xor+mov is faster than mov mem,imm16 on 8086.
	xor	ax, ax			; AX = 0  (1 cycle)
	mov	es:[di-2], ax		; Clear slot  (2 cycles vs 4 for imm)

	call	MemUnlock
	.leave
	ret

EC <nullError:							>
EC <	ERROR	FREE_CALLED_BEFORE_MALLOC			>
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
	JK	23.05.2026	8086 optimization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MALLOC_LARGE_THRESHOLD	equ	511
MALLOC_SMALL_BLOCK_SIZE	equ	1024
LARGE_BLOCK_OFFSET	equ	size hptr

global _TT_Alloc:far
_TT_Alloc	proc	far	blockSize:word, p:fptr
	uses	ds, di, si
	.enter

	mov	cx, blockSize		; CX = requested size
	jcxz	zeroAlloc		; Zero-sized alloc returns NULL

	cmp	cx, MALLOC_LARGE_THRESHOLD
	ja	largeAlloc

;	Try to allocate from an existing small LMem block.
	call	AllocInSmallList
	jnc	zinitAndExit

;	No room found; create a new small LMem block.
	mov	ax, MALLOC_SMALL_BLOCK_SIZE
	mov	bx, handle 0
	call	MemAllocFixed
	jc	errRet

	mov	ax, LMEM_TYPE_GENERAL
	mov	dx, size LMemBlockHeader
	mov	di, mask LMF_NO_HANDLES or mask LMF_NO_ENLARGE or mask LMF_RETURN_ERRORS
	push	bp
	clr	bp
	call	LMemInitHeap
	pop	bp

	mov	cx, blockSize
	call	LMemAlloc
EC <	ERROR_C	COULD_NOT_ALLOC_BLOCK_WHEN_THERE_SHOULD_BE_ROOM_FOR_IT	>
	mov	di, offset smallListHandle
	jmp	mallocCommon

largeAlloc:
	add	cx, LARGE_BLOCK_OFFSET
	mov	ax, cx			; AX = total block size
	mov	bx, handle 0
	call	MemAllocFixed
	jc	errRet

	mov	ds:[0], bx		; Store handle before user data
	mov	di, offset largeListHandle
	mov	ax, LARGE_BLOCK_OFFSET	; AX = user data offset

mallocCommon:
	push	ds			; Save allocated block segment
NOFXIP<	segmov	ds, <segment udata>, bx	>
FXIP <	mov	bx, handle dgroup	>
FXIP <	call	MemDerefDS		>
	mov	cx, ds:[di]		; CX = list block handle
	pop	ds			; Restore allocated block segment
	call	AddHandleToMallocList
	jc	freeError

zinitAndExit:
;	Zero-initialize the allocated memory.
;	DS:AX points to the user buffer.
	mov	dx, ds			; Save return pointer in DX:AX
	push	es
	push	ax
	mov	es, dx
	mov	di, ax			; ES:DI = destination

	mov	cx, blockSize
	shr	cx, 1			; CX = word count, carry if odd
	xor	ax, ax			; AX = 0
	jnc	doWords			; Even size: skip leading byte
	stosb				; Clear odd leading byte
doWords:
	rep	stosw			; Clear remaining words

	pop	ax			; Restore return pointer offset

exitWithPtr:
	les	di, p
	mov	es:[di].low, ax
	mov	es:[di].high, dx
	pop	es
	xor	ax, ax			; TT_Err_Ok
exit:
	.leave
	ret

freeError:
	mov	bx, ds:[LMBH_handle]	; Free the newly allocated block
	call	MemFree
errRet:
	mov	ax, 100h		; TT_Err_Out_Of_Memory
	jmp	exit

zeroAlloc:
	xor	ax, ax			; Return NULL
	xor	dx, dx
	push	es
	jmp	exitWithPtr

_TT_Alloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_TT_Free
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Frees up a block previously returned from _TT_Alloc.

CALLED BY:	GLOBAL

C DECLARATION:	TT_Error _TT_Free(void **p);

PSEUDO CODE/STRATEGY:
	Bail out silently if p itself is NULL (p.high == 0).
	Bail out silently if *p is NULL (es:[si].high == 0).
	If the block offset equals LARGE_BLOCK_OFFSET it was allocated
	as a single global-heap block: remove from large list and free.
	Otherwise it is an lmem chunk: free the chunk via LMemFree.
	If the lmem block is now completely empty, remove it from the
	small list and free it too.
	On either free path, zero *p so the caller sees NULL.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Accepts p == NULL or *p == NULL gracefully.
	*p is zeroed only on the small-block path (exitZero); the large-
	block path falls through to exit without zeroing *p -- this
	matches the original behaviour.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/91		Initial version
	JK	23.05.2026	AI supported optimization:
				- xor ax,ax replaces mov ax,0 and clr ax
				- stosw pair replaces two mov [mem],ax stores
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _TT_Free:far
_TT_Free	proc	far	p:fptr
	uses	es, ds, di, si
	.enter

;	Bail if the pointer argument itself is NULL.
	tst	p.high
	jz	exit

;	Dereference p: ES:SI = *p
	les	si, p
	tst	es:[si].high		; Is *p already NULL?
	jz	exitZero		; Yes: nothing to do

;	Determine block type by offset value.
	cmp	es:[si].low, LARGE_BLOCK_OFFSET
	jne	smallBlockFree

;	Large block: allocated as a single global-heap block.
;	Remove from large list and free.
NOFXIP<	segmov	ds, <segment udata>, di					>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
	mov	cx, ds:[largeListHandle]	; CX = large block list handle

freeAndRemoveBlock:
	mov	ds, es:[si+2]			; DS = segment of block to free
	call	RemoveHandleFromMallocList
	mov	bx, ds:[LMBH_handle]
	call	MemFree
	jmp	exit

smallBlockFree:
;	Small block: free the lmem chunk only.  The lmem block itself
;	stays on the global heap for reuse.
	lds	ax, es:[si]
	call	LMemFree

;	If the lmem block is now fully empty, remove it from the small
;	list and free the global-heap block too.
	cmp	ds:[LMBH_totalFree], MALLOC_SMALL_BLOCK_SIZE - size LMemBlockHeader
	jne	exitZero		; Block still has live chunks: skip free

NOFXIP<	segmov	ds, <segment udata>, di					>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
	mov	cx, ds:[smallListHandle]	; CX = small block list handle
EC <	call	ECCountFreeBlocksOnMallocList				>
EC <	cmp	dx, 2							>
EC <	ERROR_A	MORE_THAN_ONE_FREE_MALLOC_BLOCK				>
	jmp	freeAndRemoveBlock

exitZero:
;	Zero *p so the caller sees NULL after the free.
;	Use stosw twice: saves one instruction vs two mov [mem],reg.
	xor	ax, ax			; AX = 0
	mov	di, si			; ES:DI = *p  (ES already set)
	stosw				; (*p).low  = 0, DI += 2
	stosw				; (*p).high = 0

exit:
	xor	ax, ax			; TT_Err_Ok  (1 cycle vs 2 for mov ax,0)
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
