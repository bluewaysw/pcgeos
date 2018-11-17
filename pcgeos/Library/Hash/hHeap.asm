COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Hash library
FILE:		hheap.asm

AUTHOR:		Paul L. DuBois, Nov  8, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB MHMarkFree		Mark free entries by nuking their next fields.

    GLB MHRestoreFree		Restore freelist after calling MHMarkFree

    GLB MiniHeapCreate		Allocate a new "mini-heap"

    GLB MHAlloc			Return a new chunklet from the free list

    GLB MHFree			Add a chunklet to the free list

    INT MH_Expand		Add more chunklets

    INT MH_InitFreeList		Put a range of elements onto the free list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 8/94   	Initial revision

DESCRIPTION:
	Routines that manage the mini-heap chunk.

	The mini-heap could be implemented on top of memory blocks instead
	of LMem (as it doesn't use any LMem things except ChunkSizePtr, for
	internal error checking).

	$Id: hheap.asm,v 1.1 97/05/30 06:48:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MHMarkFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark free entries by nuking their next fields.

CALLED BY:	GLOBAL
PASS:		*ds:si	- MiniHeap chunk
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Mark each free entry's MHE_next field with MH_FREE_ELEMENT.
	You MUST restore the freelist by calling MHRestoreFree before
	trying to MHAlloc again.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MHMarkFree	proc	far
	uses	ax,bx, si
	.enter
		mov	si, ds:[si]
EC <		call	ECCheckMiniHeap					>

		mov	bx, MH_FREE_ELEMENT
		xchg	bx, ds:[si].MHH_freeHead
traverseList:		
		cmp	bx, MH_NULL_ELEMENT
		je	done
		mov	ax, MH_FREE_ELEMENT
		xchg	ds:[si+bx].MHE_next, ax
		mov_tr	bx, ax
		jmp	traverseList
done:
	.leave
	ret
MHMarkFree	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MHRestoreFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore freelist after calling MHMarkFree

CALLED BY:	GLOBAL
PASS:		*ds:si	- MiniHeap chunk
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Build up list by keeping a pointer to the previous link field
	(the tail of the list) around, as opposed to pushing new
	elements onto the head every time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MHRestoreFree	proc	far
	uses	ax,bx,cx, si
	.enter
		mov	si, ds:[si]
		mov	cx, ds:[si].MHH_size
		jcxz	done

		mov	ax, ds:[si].MHH_entrySize
		lea	di, ds:[si].MHH_freeHead
		mov	bx, offset MHH_data
fixupLoop:
	; ds:si	- MiniHeap
	; ds:si+bx - MiniHeap entry
	; ds:di - ptr to tail of freelist's link field
	; cx	- # entries left to process
	; ax	- entry size
		cmp	ds:[si+bx], MH_FREE_ELEMENT
		je	fl_fixup
fl_next:
		add	bx, ax
		loop	fixupLoop
		mov	ds:[di], MH_NULL_ELEMENT
		
done:
EC <		call	ECCheckMiniHeap					>
	.leave
	ret

fl_fixup:
		mov	ds:[di], bx
		lea	di, ds:[si+bx].MHE_next
		jmp	fl_next
MHRestoreFree	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MiniHeapCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a new "mini-heap"

CALLED BY:	GLOBAL
		HashTableCreate
PASS:		ds	- Locked LMem block
		al	- ObjChunkFlags to pass to LMemAlloc
		cl	- # of data bytes per entry (should be at least 2)

RETURN:		carry	- set if couldn't allocate chunk and LMF_RETURN_ERRORS
		ax	- ChunkHandle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	When compiled with tagging an extra byte is added to chunklets.

	WARNING: This routine MAY resize the LMem block, moving it on the
		 heap and invalidating stored segment pointers and current
		 register or stored offsets to it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHack <MH_INITIAL_HEAP_COUNT eq 8>

MiniHeapCreate	proc	far
	uses	bx,cx,dx,si
	.enter
		clr	ch
EC <		cmp	cl, size MiniHeapEntry				>
EC <		ERROR_B	MINI_HEAP_ENTRY_SIZE_TOO_SMALL			>
TEC <		inc	cl						>
TEC <		ERROR_Z	MINI_HEAP_ENTRY_SIZE_TOO_LARGE			>
		mov	dx, cx		; save for later
		shl	cx		; fast mul by
		shl	cx		;   MH_INITIAL_HEAP_COUNT (8)
		shl	cx
		add	cx, size MiniHeapHeader
		call	LMemAlloc
		jc	done

	; Initialize the header
		mov	si, ax
		mov	si, ds:[si]
		mov	ds:[si].MHH_freeHead, MH_NULL_ELEMENT
		clr	ds:[si].MHH_count
		mov	ds:[si].MHH_size, MH_INITIAL_HEAP_COUNT
		mov	ds:[si].MHH_entrySize, dx
		
		mov	cx, MH_INITIAL_HEAP_COUNT
		mov	bx, size MiniHeapHeader
		call	MH_InitFreeList
		call	ECCheckMiniHeap

done:
	.leave
	ret
MiniHeapCreate	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MHAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a new chunklet from the free list

CALLED BY:	GLOBAL
PASS:		*ds:si	- MiniHeap chunk
RETURN:		*ds:si	- same chunk (block possibly moved)
	carry set:
		bx	- offset within chunk of new chunklet
	carry clear:
		bx	- MH_NULL_ELEMENT -- allocation failed
DESTROYED:
SIDE EFFECTS:	
	WARNING: This routine MAY resize the LMem block, moving it on the
		 heap and invalidating stored segment pointers and current
		 register or stored offsets to it.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MHAlloc	proc	far
chunkHan	local	word	push	si
	uses	ax
	.enter
		mov	si, ds:[si]
EC <		Assert	chunkPtr, si, ds				>
EC <		clr	ax		; first time thru		>
tryAgain:
		mov	bx, ds:[si].MHH_freeHead

	; Check that we're not between calls to MHMarkFree and MHRestoreFree
EC <		cmp	bx, MH_FREE_ELEMENT				>
EC <		ERROR_E	MINI_HEAP_FREE_LIST_STILL_NUKED			>

		cmp	bx, MH_NULL_ELEMENT
		je	allocMore
		
EC <		call	ECCheckChunklet					>

if ERROR_CHECK_TAG
		add	bx, ds:[si].MHH_entrySize
		cmp	{byte}ds:[si+bx][-1], MHT_FREE
		ERROR_NE MINI_HEAP_ENTRY_BAD_TAG
		mov	{byte}ds:[si+bx][-1], MHT_USED
		sub	bx, ds:[si].MHH_entrySize
endif
		mov	ax, ds:[si+bx].MHE_next
		mov	ds:[si].MHH_freeHead, ax
		inc	ds:[si].MHH_count
		clc
done:
		mov	si, ss:[chunkHan]	; restore si
	.leave
	ret

allocMore:
EC <		tst	ax		; passing thru here twice is bad>
EC <		ERROR_NZ MINI_HEAP_INTERNAL_ERROR			>

EC <		mov	ax, ds:[si].MHH_size				>
EC <		cmp	ds:[si].MHH_count, ax				>
EC <		ERROR_NE MINI_HEAP_CORRUPT				>
		mov	si, ss:[chunkHan]
		call	MH_Expand
		mov	si, ds:[si]
		jc	done		; failed
EC <		mov	ax, -1						>
		jmp	tryAgain
MHAlloc	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MHFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a chunklet to the free list

CALLED BY:	GLOBAL
PASS:		*ds:si	- MiniHeap chunk
		bx	- offset to chunklet
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	The obvious.

PSEUDO CODE/STRATEGY:
	element.next = heap.freeHead
	heap.freeHead = element
	decrement used count

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MHFree	proc	far
	uses	si, ax
	.enter
		mov	si, ds:[si]
EC <		call	ECCheckChunklet					>
		mov	ax, ds:[si].MHH_freeHead
		mov	ds:[si].MHH_freeHead, bx

if ERROR_CHECK_TAG
		add	bx, ds:[si].MHH_entrySize
		cmp	{byte}ds:[si+bx][-1], MHT_USED
		ERROR_NE MINI_HEAP_ENTRY_BAD_TAG
		mov	{byte}ds:[si+bx][-1], MHT_FREE
		sub	bx, ds:[si].MHH_entrySize
endif
		mov	ds:[si+bx].MHE_next, ax
		dec	ds:[si].MHH_count
	.leave
	ret
MHFree	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MH_Expand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add more chunklets

CALLED BY:	INTERNAL
		MHAlloc
PASS:		*ds:si	- mini heap
RETURN:		*ds:si	- mini heap (block possibly moved)
		carry	- set if wasn't expanded
DESTROYED:	nothing
SIDE EFFECTS:
	new elements added
	WARNING: This routine MAY resize the LMem block, moving it on the
		 heap and invalidating stored segment pointers and current
		 register or stored offsets to it.

PSEUDO CODE/STRATEGY:
	Allocate size/2 elements.  If there isn't enough space, try just
	allocating space for one more (ugh!  but better slow than fail)
	FIXME: good heuristic?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MH_Expand	proc	near
	uses	ax,bx,cx,dx,di
	.enter
		mov	di, ds:[si]
		mov	ax, ds:[di].MHH_size
		shr	ax
		mov	bx, ax		; bx <- # new elements
		mov	cx, ds:[di].MHH_entrySize
		mul	cx		; ax <- # new bytes needed
EC <		tst	dx						>
EC <		ERROR_NZ -1						>

		mov_tr	dx, ax		; dx <- # new bytes needed
		call	expandIt
		jnc	success

tryOnlyOne::
	; Allocate enough space for just one more entry, since
	; allocating a bunch just failed
	;
		mov	di, ds:[si]
		mov	dx, ds:[di].MHH_entrySize
		mov	bx, 1		; bx <- # new elements
		call	expandIt
		jc	done		; return failure

success:
	; add new elements to free list.
	; dx - # bytes added
	; cx - new chunk size
	; bx - # new elements added
		mov	di, si		; save si
		mov	si, ds:[si]
		add	ds:[si].MHH_size, bx
		xchg	bx, cx		; bx <- chunk size, cx <- # elements
		sub	bx, dx		; bx <- chunklet to start at
		call	MH_InitFreeList
		mov	si, di		; restore si
		clc
done:
	.leave
	ret
expandIt:
	; dx - # bytes to add
	; si - chunkhandle
	; trashes ax, dx
		ChunkSizePtr	ds, di, cx
		add	cx, dx
		mov	ax, si
		call	LMemReAlloc
		retn

MH_Expand	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MH_InitFreeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put a range of elements onto the free list

CALLED BY:	INTERNAL
		HashTableCreate
PASS:		ds:si	- mini heap
		ds:si+bx - element to start at
		cx	- # entries to add
RETURN:		ds:si	- initialized
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	i = first
	DO THIS ax TIMES:
	    heap.data[i].next = offset(heap.data[i])
	    i++
	heap.data[i-1].next = heap.freeHead
	heap.freeHead = offset(heap.data[first])

	where offset() gives the offset from the beginning of the chunk

IDEAS:
	might want to add the new entries at the end of the free list?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MH_InitFreeList	proc	near
	uses	ax,di
	.enter
EC <		call	ECCheckChunklet					>

if ERROR_CHECK
	; check to see if any elements in the range are out of bounds
		push	ax, dx
		mov	ax, bx
		sub	ax, size MiniHeapHeader
		push	cx		; save # entries
		mov	cx, ds:[si].MHH_entrySize
		clr	dx
		div	cx		; ax <- element #
		pop	cx		; restore # entries
		tst	dx
		ERROR_NZ -1
		add	ax, cx		; ax <- end of range + 1
		cmp	ax, ds:[si].MHH_size
		ERROR_A	MINI_HEAP_RANGE_TOO_LARGE
		pop	ax, dx
endif		

	; set up regs for the loop:
	;  ax	- entry size
	;  cx	- # elements to add to free list
	;  bx	- offset from [si] to first element to add
	;  [di]	- first element in chain
		mov	ax, ds:[si].MHH_entrySize
		lea	di, ds:[si+bx]
		mov	dx, bx	; save this offset to use as freelist head
		add	bx, ax		; bx <- now offset of 2nd elt.

	; we could get tricky with this loop but it gets pretty
	; unreadable...
	; ds:[si+bx] always points one element beyond ds:[di]
	; in other words, di+(element size) = si+bx
initLoop:
		mov	ds:[di].MHE_next, bx
TEC <		mov	{byte}ds:[si+bx][-1], MHT_FREE			>
		add	di, ax
		add	bx, ax
		loop	initLoop

	; stick the chain just created onto the head of the free list
		sub	di, ax
		xchg	dx, ds:[si].MHH_freeHead
					; dx <- old free list head
		mov	ds:[di].MHE_next, dx

	.leave
	ret
MH_InitFreeList	endp

MainCode	ends
