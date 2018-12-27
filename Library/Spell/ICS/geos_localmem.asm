COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	Spell Checker
MODULE:		Local Memory routines
FILE:		geos_localmem.asm

AUTHOR:		Andrew Wilson, Mar 11, 1991

ROUTINES:
	Name			Description
	----			-----------
	GeosLocalAlloc		Allocate memory in our dgroup
	GeosLocalFree		Free memory in our dgroup
	GeosLocalInit		Init our local heap
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/11/91		Initial revision

DESCRIPTION:
	This routine allocates memory in our own dgroup.

	Each used or free block is preceded by its size.

	Each free block has a pointer to the next free block at its beginning
	(after the size word). We use a first-fit algorithm to allocate memory.

	All blocks, free and used, are sized in multiples of 4 bytes.

	$Id: geos_localmem.asm,v 1.1 97/04/07 11:06:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata	segment
	even	
	localHeap	byte	SIZE_OF_LOCAL_HEAP dup (?)
	freePtr		nptr	(?)
EC <	localEC		byte	(?)					>
	endOfLocalHeap	label	byte
udata	ends
LB_size		equ	-2

;
;	Fatal Errors
;
ALLOC_OF_ZERO						       enum FatalErrors
BAD_PTR							       enum FatalErrors
FREE_BLOCK_NOT_EMPTY					       enum FatalErrors
LOCAL_BLOCK_SIZE_IS_NOT_MULTIPLE_OF_4			       enum FatalErrors
LOCAL_BLOCK_TOO_SMALL_TO_ADD_TO_FREE_LIST		       enum FatalErrors
SIZE_OF_FREE_BLOCKS_EXCEEDS_SIZE_OF_HEAP		       enum FatalErrors
HEAP_SIZES_DO_NOT_ADD_UP				       enum FatalErrors
LOCAL_HEAP_FULL						       enum FatalErrors

.model	medium, pascal

CODE	segment	
if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the passed free block is all zeroes.

CALLED BY:	GLOBAL
PASS:		ds:ax - ptr to free block
RETURN:		nada
DESTROYED:	es, cx, di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckFreeBlock	proc	near
	tst	ds:[localEC]
	jz	exit
	tst	ax			;
	jz	exit
	push	ax
	segmov	es, ds			;ES:DI <- ptr to this chunk
	xchg	ax, di			;
	mov	cx, ds:[di].LB_size
EC <	test	cx, 0x3						>
EC <	ERROR_NZ	LOCAL_BLOCK_SIZE_IS_NOT_MULTIPLE_OF_4	>
	shr	cx, 1
	dec	cx			;CX <- # words in this block
	dec	cx			;
	inc	di			;Skip the next ptr at the start of the
	inc	di			; free block.
	mov	ax, 0xcccc
	jcxz	nope
	repe	scasw
	ERROR_NZ	FREE_BLOCK_NOT_EMPTY
nope:
	pop	ax
exit:
	ret
ECCheckFreeBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckLocalHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the local heap to be sure it is OK.

CALLED BY:	GLOBAL
PASS:		ds - dgroup
RETURN:		nada
DESTROYED:	di, si
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckLocalHeap	proc	near	uses	ax, cx
	.enter
	tst	ds:[localEC]
	jz	exit
	clr	cx
	mov	si, offset localHeap
loopTop:
	add	cx, ds:[si]
	add	si, ds:[si]
	cmp	cx, SIZE_OF_LOCAL_HEAP
	ERROR_A	HEAP_SIZES_DO_NOT_ADD_UP				
	jne	loopTop

	mov	si, ds:[freePtr]
10$:
	tst	si
	jz	exit
	cmp	si, offset localHeap
	ERROR_B	BAD_PTR
	cmp	si, offset endOfLocalHeap
	ERROR_AE BAD_PTR	
	mov	ax, si
	call	ECCheckFreeBlock
	mov	si, ds:[si]			;Go to the next free block
	jmp	10$
exit:
	.leave
	ret
ECCheckLocalHeap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckBlockPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to be sure this is a valid block ptr.

CALLED BY:	GLOBAL
PASS:		ds:ax - ptr to the block to check
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckBlockPtr	proc	near		uses	si
	.enter
	tst	ds:[localEC]
	jz	exit
	mov	si, offset localHeap+2
10$:
	cmp	ax, si
	je	exit
	add	si, ds:[si].LB_size
	cmp	si, offset endOfLocalHeap
	jb	10$
	ERROR	BAD_PTR
exit:
	.leave
	ret
ECCheckBlockPtr	endp

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosLocalInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This code inits the local heap.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry clear
DESTROYED:	ds, ax
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosLocalInit	proc	far
	mov	ax, segment idata
	mov	ds, ax
if ERROR_CHECK
;	mov	ds:[localEC], -1
	mov	es, ax
	mov	di, offset localHeap
	mov	ax, 0xcccc
	mov	cx, SIZE_OF_LOCAL_HEAP/2
	rep	stosw
endif
	mov	si, offset localHeap+2
	mov	ds:[freePtr], si
	mov	ds:[si].LB_size, SIZE_OF_LOCAL_HEAP
	mov	{word} ds:[si], 0
	clc
	ret
GeosLocalInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a block to the free list.

CALLED BY:	LMemFree, LMemReAlloc, LMemSplitBlock
PASS:		ds = segment address of the heap block.
		ds:si = ptr to the block to add to the list
			(ds:si points *after* the size word)
RETURN:		nothing
DESTROYED:	bx, cx, di

CHECKS:		The block pointed at by ds:si is not already free.

PSEUDO CODE/STRATEGY:
	This routine needs to combine adjacent free blocks.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddFreeBlock	proc	near
	uses	ax, si				;
	.enter					;
						;
						;
	mov	bx, si				; bx <- ptr to item.
	mov	di, offset freePtr		; ds:di <- ptr to start of list
AFB_loop:					;
	mov	si, di				; ds:si <- ptr to last item
	mov	di, ds:[si]			; di <- next.
	tst	di				; check for no next.
	jz	AFB_endLoop			; quit if none.
	cmp	di, bx				; check for next > item
	jbe	AFB_loop			; loop if not.
AFB_endLoop:					;
	;
	; ds:si = ptr to chunk to link after.		(prev)
	; ds:bx = ptr to chunk to link in.		(current)
	; ds:di = ptr to chunk to link before.		(next)
	;
	mov	ds:[si], bx			; link prev to this one.
	mov	ds:[bx], di			; link this one to next.
	;
	; Now...
	; if (prev + size-prev) = current then
	;    can coalesce prev and current.
	; if (current + size-current) = next then
	;    can coalesce current and next.
	;
	cmp	si, offset freePtr		;Did we add this item at the
	je	AFB_notPrev			; front of the free list?
						;Branch if so...
						;
	mov	ax, ds:[si].LB_size		;
	add	ax, si				; ax <- prev + size-prev
	cmp	ax, bx				;
	jne	AFB_notPrev			;
	;
	; Combine previous and current.
	;
	mov	ax, ds:[bx].LB_size		;
	add	ds:[si].LB_size, ax		; add current's size to prev
						;
	mov	ax, ds:[bx]			; ax <- free-list ptr of 2nd.
	mov	ds:[si], ax			; re-link free list.
if ERROR_CHECK
	mov	{word} ds:[bx],0xcccc		;Clear out portion of heap
	mov	{word} ds:[bx].LB_size, 0xcccc	; (we want all free blocks to
						; be 0'd out)
endif
	mov	bx, si				; current is now combination.
AFB_notPrev:					;
	mov	ax, ds:[bx].LB_size		;
	add	ax, bx				; bx <- cur + cur-size.
						;

	cmp	ax, offset endOfLocalHeap+2	; check for on last chunk.
	je	AFB_notNext			;
EC <	ERROR_A	SIZE_OF_FREE_BLOCKS_EXCEEDS_SIZE_OF_HEAP		>
						;
	cmp	ax, di				;
	jne	AFB_notNext			;
	;
	; Combine current and next.
	;
	mov	ax, ds:[di].LB_size		;
	add	ds:[bx].LB_size, ax		; save new size.
						;
	mov	ax, ds:[di]			; re-link free list.
	mov	ds:[bx], ax			;
if ERROR_CHECK
	mov	{word} ds:[di],0xcccc		;Clear out portion of heap
	mov	{word} ds:[di].LB_size, 0xcccc	; (we want all free blocks to
						; be 0'd out)
endif
AFB_notNext:					;
	.leave					;
	ret					;
AddFreeBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEOSLocalAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a block on our local heap

C DECLARATION:	VOID FAR * GEOSLocalAlloc(UINT2B blockSize, UINT2B clearFlag);
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	GEOSLocalAlloc:far
GEOSLocalAlloc	proc	far	blockSize:word, clearFlag: word
				uses	es, di, si, bp
	.enter
EC <	call	ECCheckLocalHeap				>
	mov	cx, blockSize
EC <	tst	cx						>
EC <	ERROR_Z	ALLOC_OF_ZERO					>

;	Add 2 to size of block so we can precede it with a size word, and
;	round it off to be a multiple of 4

	add	cx, 5
	and	cx, 0xfffc

;	call	AllocateChunk		;Returns chunk offset in ds:ax
					; (offset past size word at start of
					; block, or 0 if no room)

;	ALLOCATE THE CHUNK

	mov	si, offset freePtr
scanLoop:
	mov	di, si				;DS:DI <- ptr to previous item
						; on free list
	mov	si, ds:[si]			; move to next one.
	tst	si				; if at end of list	
	jz	outOfMem
EC <	test	{word} ds:[si].LB_size, 0x3				>
EC <	ERROR_NZ	LOCAL_BLOCK_SIZE_IS_NOT_MULTIPLE_OF_4		>
	cmp	cx, ds:[si].LB_size		; if didn't find one then
	ja	scanLoop			;    branch back up.
	mov	dx, cx				;Preserve and pass to split
	mov	ax, ds:[si]			;Remove block from free list
	mov	ds:[di], ax			;
	mov	ax, si				;DS:AX <- ptr to new chunk

;	SPLIT THE REMAINING BLOCK INTO HALVES	

	mov	bx, ds:[si].LB_size	; bx <- size of chunk in words.
EC <	test	bx, 0x3							>
EC <	ERROR_NZ	LOCAL_BLOCK_SIZE_IS_NOT_MULTIPLE_OF_4		>
	sub	bx, dx			; bx <- size of top half
	je	LMSB_done
					;
EC <	cmp	bx, 4			; need at least 4 bytes in the	>
EC <					;   top half in order to make	>
EC <					;   it into a free chunk.	>
EC <	jb	LMSB_uhOh		; quit and use whole chunk.	>
	;
	; ds:si = ptr to block to split.
	; dx = size for low portion of the block.
	; bx = size for the upper portion.
	;
	; NOTE: storing of sizes *must* be performed in this order for
	; LMemReAlloc to work (passes 0 as size for chunk to remain
	; in-use)
	;
	mov	ds:[si].LB_size, dx	; save size for low chunk.
EC <	mov	ds:[si], 0xcccc		; nuke next-free ptr	>
	add	si, dx			; set ptr to high block.
	mov	ds:[si].LB_size, bx	; save size for high chunk.
	call	AddFreeBlock		; add to free list.
LMSB_done:				;

EC <	tst	ax			;If a null pointer, exit>
EC <	ERROR_Z	LOCAL_HEAP_FULL					>
EC <	call	ECCheckBlockPtr					>
EC <	call	ECCheckLocalHeap				>

	tst	clearFlag		;If we don't need to clear the block,
	jz	exit			; just exit

;	ZERO OUT THE BLOCK

	segmov	es, ds, di		;ES:DI <- ptr to the new block
	mov	di, ax
	xchg	bx, ax
	clr	ax
	mov	cx, blockSize
	shr	cx, 1			;We always allocate in groups of 4,
					; so don't worry about extra byte.
	rep	stosw
	xchg	ax, bx
exit:
	mov	dx, ds
99$:
	.leave
	ret
;
; We are in trouble...
; The leftover portion of the chunk is too small to put on the free-list.
; (We need at least 2 words. 1 for the size and 1 for the next item in the
;  free-list).
; We can't add it to the free-list, but we can't just give the whole chunk
; back to fulfill the request, because then the size of the chunk will be
; incorrect.
;
EC<LMSB_uhOh:				;			>
EC <	ERROR	LOCAL_BLOCK_TOO_SMALL_TO_ADD_TO_FREE_LIST	>
outOfMem:

;	WHINE TO THE USER ABOUT BEING OUT OF MEMORY

	push	ds
	mov	bx, handle noMemError
	call	MemLock
	mov	ds, ax
assume	ds:Strings
	mov	si, ds:[noMemError]
	clr	di
assume	ds:dgroup
	mov	ax, mask SNF_EXIT or mask SNF_ABORT
	call	SysNotify
	pop	ds
	test	ax, mask SNF_ABORT
	mov	ax, 0
	mov	dx, ax
	jnz	99$
	mov	ax, SST_DIRTY
	mov	si, -1
	call	SysShutdown
	.unreached

GEOSLocalAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEOSLocalFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a block on our local heap

C DECLARATION:	VOID GEOSLocalFree(VOID NEAR * blockPtr);
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	GEOSLocalFree:far
GEOSLocalFree	proc	far	blockPtr:fptr
					uses	es, si, di, bp
	.enter

if ERROR_CHECK
	cmp	blockPtr.segment, segment dgroup			
	ERROR_NZ BLOCK_NOT_IN_DGROUP

	call	ECCheckLocalHeap				
	segmov	es, ds, di		;
	mov	di, blockPtr.offset	;ES:DI <- ptr to block to free
	mov	si, di
	mov	ax, si							
	call	ECCheckBlockPtr						
	mov	cx, ds:[si].LB_size	;CX <- # bytes in the block	
	test	cx, 0x3							
	ERROR_NZ	LOCAL_BLOCK_SIZE_IS_NOT_MULTIPLE_OF_4

	shr	cx, 1			;CX <- # words in the block
	dec	cx			;Don't count size word
	mov	ax, 0xcccc
	rep	stosw			;Clear the block out (zero it)
else
	mov	si, blockPtr.offset	;DS:SI <- ptr to block to free
endif

	call	AddFreeBlock		;Free the block up
EC <	call	ECCheckLocalHeap				>
	.leave
	ret
GEOSLocalFree	endp

CODE	ends

