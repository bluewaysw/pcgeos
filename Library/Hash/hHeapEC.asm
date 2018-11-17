COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Hash library
FILE:		hheapec.asm

AUTHOR:		Paul L. DuBois, Nov  9, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB ECCheckMiniHeap		Perform general sanity checking

    GLB ECCheckMHFreeList	Do some checks on the free list

    GLB ECCheckUsedChunklet	Check the offset of a Mini heap entry.
				Assert that it is used (only with
				ERROR_CHECK_TAG)

    GLB ECCheckChunklet		Check the offset of a Mini heap entry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 9/94   	Initial revision


DESCRIPTION:
	Error checking routines for mini heap module.

	$Id: hheapec.asm,v 1.1 97/05/30 06:48:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCode	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckMiniHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform general sanity checking

CALLED BY:	GLOBAL
PASS:		ds:si	- mini heap
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	May fatal error

PSEUDO CODE/STRATEGY:
	Besides checking free list, checks that
	(MHH_size * MHH_entrySize) + size of header == chunk size

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckMiniHeap	proc	far
if ERROR_CHECK
	uses	ax,cx,dx
	.enter
		Assert	chunkPtr, si, ds
		mov	ax, ds:[si].MHH_size
		mov	cx, ds:[si].MHH_entrySize
		mul	cx
		tst	dx
		ERROR_NZ MINI_HEAP_CORRUPT

		ChunkSizePtr ds, si, cx
		add	ax, size MiniHeapHeader
		cmp	ax, cx
		ERROR_NE MINI_HEAP_CORRUPT

		call	ECCheckMHFreeList
	.leave
endif
	ret
ECCheckMiniHeap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckMHFreeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some checks on the free list

CALLED BY:	EXTERNAL (not exported cause its not generally useful)
PASS:		ds:si	- Mini Heap
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	May fatal error

PSEUDO CODE/STRATEGY:
	FIXME: just punts on checks if free entries are marked
	(should probably walk through entire heap and count free entries)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckMHFreeList	proc	far
if ERROR_CHECK
	uses	ax,bx,cx,dx
	.enter
		cmp	ds:[si].MHH_freeHead, MH_FREE_ELEMENT
		je	done
		
		clr	ax		; ax <- # elements on free list...
		ChunkSizePtr ds, si, cx
		mov	dx, ds:[si].MHH_size

	; Walk through the free list:
	;  * check that offset is valid
	;  * count the number of free entries
	;  * check that # free entries <= total # entries
		mov	bx, ds:[si].MHH_freeHead
traverseList:
		cmp	bx, MH_NULL_ELEMENT
		je	gotEnd
		inc	ax
		call	ECCheckChunklet
		cmp	ax, dx
		ERROR_A	MINI_HEAP_ENTRIES_DONT_ADD_UP
if ERROR_CHECK_TAG
		add	bx, ds:[si].MHH_entrySize
		cmp	{byte}ds:[si+bx][-1], MHT_FREE
		ERROR_NE MINI_HEAP_ENTRY_BAD_TAG
		sub	bx, ds:[si].MHH_entrySize
endif
		mov	bx, ds:[si+bx].MHE_next
		jmp	traverseList		
	
	; check that # free + # used = total # entries
gotEnd:
		add	ax, ds:[si].MHH_count
		cmp	ax, dx
		ERROR_NE MINI_HEAP_ENTRIES_DONT_ADD_UP
done:
	.leave
endif
	ret
ECCheckMHFreeList	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckUsedChunklet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the offset of a Mini heap entry.  Assert that it is
		used (only with ERROR_CHECK_TAG)

CALLED BY:	GLOBAL
PASS:		ds:si	- mini heap
		ds:si+bx - alleged (used) mini heap entry
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	May fatal error
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckUsedChunklet	proc	far
if ERROR_CHECK
if ERROR_CHECK_TAG
		add	bx, ds:[si].MHH_entrySize
		cmp	{byte}ds:[si+bx][-1], MHT_USED
		ERROR_NE MINI_HEAP_ENTRY_BAD_TAG
		sub	bx, ds:[si].MHH_entrySize
endif
		call	ECCheckChunklet
endif
	ret
ECCheckUsedChunklet	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckChunklet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the offset of a Mini heap entry

CALLED BY:	GLOBAL
PASS:		ds:si	- mini heap
		ds:si+bx - alleged mini heap entry
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	May fatal error

PSEUDO CODE/STRATEGY:
	assert that (offset - (size MiniHeapHeader)) % entry size = 0
	and also offset < chunk size

	assumes that MHH_size can be trusted.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckChunklet	proc	far
if ERROR_CHECK
		Assert	chunkPtr, si, ds
		push	ax, cx, dx
		mov	ax, bx
		sub	ax, size MiniHeapHeader
		mov	cx, ds:[si].MHH_entrySize
		clr	dx
		div	cx		; remainder in dx
		tst	dx
		ERROR_NZ MINI_HEAP_BAD_OFFSET
		cmp	ax, ds:[si].MHH_size
		ERROR_NB MINI_HEAP_BAD_OFFSET
		pop	ax, cx, dx
endif
	ret
ECCheckChunklet	endp
ECCode	ends
