COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Heap
FILE:		heapSwap.asm

AUTHOR:		Adam de Boor, Jun  7, 1990

ROUTINES:
	Name			Description
	----			-----------
    GLB	MemAddSwapDriver	Register another swap driver in the system
    GLB MemExtendHeap		Add more space to the heap from a swap driver
    GLB MemGetSwapDriverInfo	Returns info about a swap driver

    INT MemSwapOut		Swap the given block using the current swap
				driver
    INT MemSwapIn		Swap the given block back in
    INT MemSwapDelete		Free the swap space held by the given block.


	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 7/90		Initial revision


DESCRIPTION:
	Functions to interface with swap drivers.
		

	$Id: heapSwap.asm,v 1.31 98/03/12 17:37:22 allen Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kinit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemAddSwapDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add another swap driver to the system, if possible.
		THIS IS ONLY TO BE CALLED DURING INIT CODE SO I DON'T HAVE
		TO PROTECT THE TABLE WITH A SEMAPHORE. DIMBULBS NEED NOT
		APPLY...

CALLED BY:	Swap drivers
PASS:		cx:dx	= driver strategy routine
		al	= SwapSpeed giving the speed of the swap device
		ah	= SwapDriverFlags
RETURN:		carry set if driver couldn't be added (driver should return
			carry set from its DR_INIT function so it gets
			unloaded)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The Kernel variable heapSize is adjusted here to
	account for a larger effective heap.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemAddSwapDriver proc	far	uses di, ds, es, si, ax
		.enter
		LoadVarSeg	ds, si
		mov	es, si
	;
	; See if the table is full.
	;
		cmp 	ds:swapNumDrivers, MAX_SWAP_DRIVERS
		je	fail
		
	;
	; Find the proper place in the table for the driver.
	;
		push	cx
		mov	cx, ds:swapNext
		mov	si, offset swapTable - size SwapDriver
searchLoop:
		add	si, size SwapDriver	; point to next
		cmp	si, cx			; hit the end of the table?
		je	addDriver		; yes -- just add it here
		
		cmp	al, ds:[si].SD_speed	; if slower or same, keep
		jae	searchLoop		;  looking
		
	;
	; Need to insert a record into the table by shifting everything up one
	; entry.
	;
		mov	di, cx			; di <- end of table
		sub	cx, si			; cx <- # words to move
		shr	cx
		dec	di			; di <- end of record after
		dec	di			;  table in a convoluted manner
		mov	si, di
		add	di, size SwapDriver

		std
		rep	movsw
		cld

		inc	si			; point back to the start
		inc	si			;  of the record we just opened
						;  up...
addDriver:
		mov	ds:[si].SD_speed, al
		mov	ds:[si].SD_flags, ah
		mov	ds:[si].SD_strategy.offset, dx
		pop	cx			; recover strategy segment
		mov	ds:[si].SD_strategy.segment, cx
		
	;
	; Record another record in the table.
	;
		add	ds:swapNext, size SwapDriver	; clears carry
		inc	ds:swapNumDrivers

if	not NEVER_ENFORCE_HEAPSPACE_LIMITS
	;
	; OK, now add this contribution to heapSize
	;
		mov	di, DR_SWAP_GET_MAP		; seg in ax
		call	ds:[si].SD_strategy
		mov	es, ax
		mov	ax, es:[SM_page]
		mov	di, es:[SM_total]
		xchg	di, dx				; preserve dx in di
		mul	dx

		mov	al, ah	; now divide by 1024.. srh 10
		mov	ah, dl
		mov	dl, dh
		shr	dx
		rcr	ax
		shr	dx
		rcr	ax
	;
	; and scale it (3/4)
	;
		shr	ax
		mov	dx, ax
		shr	ax
		add	ax, dx

MASD_addToHeapSize::				; showcalls -H

		add	ds:[heapSize], ax
		mov	dx, di				; restore dx
		clc
endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS

done:
		.leave
		ret
fail:
		stc
		jmp	done
MemAddSwapDriver endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MEHBeforeHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a free block before the current start of the heap.	

CALLED BY:	(INTERNAL) MemExtendHeap
PASS:		ds	= dgroup
		ax	= segment of new free block
		bx	= distance from this seg to edge of heap in para
		cx	= size of new free block (paragraphs)
RETURN:		si	= block to link in with lower address (free block,
			  for this function)
		bx	= block to link in with higher address (gap block,
			  for this function)
		cx	= routine to call to fixup the links (MEHFixLinks
			  or MEHFixLinks2)
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MEHBeforeHeap	proc	near
		.enter
		push	ax, cx
		clr	si			; assume no 2d block needed
		cmp	bx, cx			; do we need one block or two?
		je	allocFreeBlock		; => no gap between current
						;  heap start and new space, so
						;  don't alloc a handle for it

		mov	cx, mask HF_FIXED	; must be fixed, to avoid
						;  death
		mov	bx, handle 0		; gap block owned by us
		call	AllocateMemHandleFar
		mov	si, bx			; si <- gap block

allocFreeBlock:
		clr	bx			;handle is free, so owner 0
		call	AllocateMemHandleFar
		pop	ax, cx
		
		mov	ds:[bx].HM_addr, ax	; bx = handle covering heap
		mov	ds:[bx].HM_size, cx	;  extension
		
		add	cx, ax			; cx <- gap addr
		xchg	ds:[loaderVars].KLV_heapStart, ax

		tst	si			; any gap to be set up?
		jnz	setupGapBlock
		mov	cx, offset MEHFixLinks2	; if no gap, just want to fix
						;  up bx
		mov	si, bx			; si <- bx so setting of
						;  [si].HM_prev does the
						;  right thing
		jmp	fixup

setupGapBlock:
		mov	ds:[si].HM_addr, cx
		sub	ax, cx			; ax <- size of gap (from start
						;  to former heap start)
		mov	ds:[si].HM_size, ax
		mov	ds:[si].HM_otherInfo, FAKE_BLOCK_CODE
						; dloft 12/9/93 -- stuff
						; otherInfo so we can id fakes

		mov	cx, offset MEHFixLinks	; we'll need to fixup both bx
						;  and si.

	;
	; Partially link the two new blocks between the first and the last
	; blocks on the heap. We need to set both pointers for the fake
	; (locked) block (si) and the HM_next pointer for the extension
	; block (bx). FixLinks will deal with si first, pointing bx to it.
	; It will then link handleBottomBlock to bx and life will be good.
	;
fixup:
		xchg	bx, si
		.leave
		ret
MEHBeforeHeap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MEHAfterHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a free block beyond the current end of the heap.	

CALLED BY:	(INTERNAL) MemExtendHeap
PASS:		ds	= dgroup
		ax	= segment of new free block
		cx	= size of new free block (paragraphs)
RETURN:		si	= block to link in with lower address (gap block,
			  for this function)
		bx	= block to link in with higher address (free block,
			  for this function)
		cx	= routine to call to fixup the links (MEHFixLinks
			  or MEHFixLinks2)
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	not FULL_EXECUTE_IN_PLACE

MEHAfterHeap	proc	near
		.enter
	;
	; Allocate two blocks to cover the distance from the current heap
	; end to the end of the block being added to the heap. Only allocate
	; one block if the block being added follows immediately after the
	; heap itself, as can happen with some funky Extended -> Expanded
	; memory managers (which use 64K of conventional memory to give
	; programs that know nothing of extended memory the ability to access
	; that memory).
	;
		push	ax, cx
		mov	si, 0			; assume no gap (don't hose
						;  flags...)
		je	allocFreeBlock		; => no gap between current
						;  heap end and new space, so
						;  don't alloc a handle for it
						;  (flags still set from cmp
						;  with heapEnd)

		clr	cx			; no special allocation flags
		mov	bx, handle 0
		call	AllocateMemHandleFar
		mov	si, bx
		mov	ds:[si].HM_lockCount, 1	; si remains locked forever

allocFreeBlock:
		clr	bx			;handle is free, so owner 0
		call	AllocateMemHandleFar
		pop	ax, cx
		
		mov	ds:[bx].HM_addr, ax	; bx = handle covering heap
		mov	ds:[bx].HM_size, cx	;  extension
		
		add	ax, cx			; ax <- new end of heap
		xchg	ds:[loaderVars].KLV_heapEnd, ax
						; addr of gap block is old
						;  end

		tst	si			; any gap to be set up?
		jnz	setupGapBlock
		mov	cx, offset MEHFixLinks2	; if no gap, just want to fix
						;  up bx
		mov	si, bx			; si <- bx so setting of
						;  [si].HM_prev does the
						;  right thing
		jmp	done

setupGapBlock:
		mov	cx, offset MEHFixLinks	; we'll need to fixup both bx
						;  and si.
		mov	ds:[si].HM_addr, ax	; gap addr <- old heapEnd

		sub	ax, ds:[bx].HM_addr	; figure # paragraphs in gap
		neg	ax			;  block
		mov	ds:[si].HM_size, ax
		mov	ds:[si].HM_otherInfo, FAKE_BLOCK_CODE
						; dloft 12/9/93 -- stuff
						; otherInfo so we can identify
						; these fake blocks
done:
		.leave
		ret
MEHAfterHeap	endp

endif	; not FULL_EXECUTE_IN_PLACE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemExtendHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add another block of memory to be managed by the heap code.

CALLED BY:	GLOBAL (swap drivers)
PASS:		ax	= starting segment of block
		cx	= length of block (paragraphs)
RETURN:		nothing
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine has the side effect of adjusting the
	Kernel variable heapSize to account for the added heap space.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemExtendHeap	proc	far	uses ds, bx, dx, si, di
		.enter
		LoadVarSeg	ds
		
EC <		call	FarPHeap					>

	;
	; Cannot extend the heap above MAX_SEGMENT -- doing so will cause
	; extreme pain and agony in various parts of the heap code.
	; 
	; In FXIP, cannot extend the heap above ROM.  (There are lots
	; of places in the code that assume that ROM resources lie above
	; KLV_heapEnd).  We know that ROM resources are below MAX_SEGMENT, and
	; KLV_xipHeader is the bottommost ROM address.
	;
		mov	bx, ax		; figure the end of the block
NOFXIP <	sub	bx, MAX_SEGMENT					>
FXIP <		sub	bx, ds:[loaderVars].KLV_xipHeader		>
		jae	ignoreBlock	; => block wholly above MAX_SEGMENT
		add	bx, cx
		jae	blockOk		; => block wholly below MAX_SEGMENT
		sub	cx, bx		; else adjust the added block to
					;  be within bounds
		ja	blockOk		; continue if there's still stuff to
					;  add
ignoreBlock:
		jmp	done

blockOk:
if	not NEVER_ENFORCE_HEAPSPACE_LIMITS
	;
	; Adjust heapSize..  Translate size from paras to K
	;
		push	ax, cx
		mov	ax, cx
		mov	cl, 6
		shr	ax, cl		; round down - truncate
MEH_addToHeapSize::				; showcalls -H
		add	ds:[heapSize], ax
		pop	ax, cx
endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS

		cmp	ax, ds:[loaderVars].KLV_heapEnd
		jb	checkBelowHeap
if	FULL_EXECUTE_IN_PLACE
	;
	; In FXIP, all the unused space between KLV_heapEnd and the bottom of
	; ROM is already covered by a fake block.  So here we extend
	; KLV_heapEnd to include all the new space being added, and then
	; shrink the fake block that is now included (maybe partially) in the
	; heap.
	;
		mov	ds:[loaderVars].KLV_heapEnd, ax
		add	ds:[loaderVars].KLV_heapEnd, cx
		jmp	shrinkFakeBlock
else
		call	MEHAfterHeap
endif	; FULL_EXECUTE_IN_PLACE

	;
	; Partially link the two new blocks between the first and the last
	; blocks on the heap. We need to set both pointers for the lower
	; block (si) and the HM_next pointer for the higher
	; block (bx). FixLinks will deal with si first, pointing bx to it.
	; It will then link handleBottomBlock to bx and life will be good.
	;
fixup:
		mov	ds:[si].HM_next, bx
		mov	di, ds:[loaderVars].KLV_handleBottomBlock
		mov	ds:[bx].HM_next, di
		mov	ax, ds:[di].HM_prev
		mov	ds:[si].HM_prev, ax
		call	cx

		tst	ds:[bx].HM_owner
		jz	officiallyFreeIt
		xchg	bx, si
officiallyFreeIt:
		call	DoFreeNoDeleteSwapFar
done:
EC <		call	FarVHeap					>
		.leave
		ret

checkBelowHeap:
		mov	bx, ds:[loaderVars].KLV_heapStart
		sub	bx, ax
		jb	shrinkFakeBlock		; => already part of the heap,
						;  but covered by a fake block

		je	done			; where the hell'd this come
						;  from? should already be
						;  part of the heap..
		call	MEHBeforeHeap
		jmp	fixup

shrinkFakeBlock:
	;
	; The new extension has already been incorporated into the heap.
	; Find the fake block that must be covering it and free it up.
	;
		mov	bx, ds:[loaderVars].KLV_handleBottomBlock
searchLoop:
		; XXX: EC code might be appropriate...
		mov	bx, ds:[bx].HM_prev
		cmp	ds:[bx].HM_addr, ax
		ja	searchLoop
		
	;
	; Now have the first block whose address is below or equal to the
	; new block. This must be the one we want to split.
	;
		je	simple
		
		sub	ax, ds:[bx].HM_addr
		push	cx
		push	ax
		add	ax, cx
		cmp	ds:[bx].HM_size, ax
		mov	cl, mask HF_FIXED	; keep bottom allocated
		pop	ax
		jne	complex		; double-split needed
	;
	; Another simple case -- we can just do a SplitBlockFreeRemainder
	; keeping the bottom part allocated.
	;
		call	SplitBlockFreeRemainderWithAddr
		pop	cx
NOAXIP <	jmp	done						>
AXIP <		mov	si, ds:[bx].HM_next	; si <- new free block	>
AXIP <		mov	si, ds:[si].HM_next	; si <- block above	>
AXIP <		jmp	fixupTopBlock					>

complex:
EC <		ERROR_B	FAKE_BLOCK_DOESNT_COVER_ENTIRE_NEW_HEAP_SEGMENT	>
	;
	; Double-split required. Just do a split without freeing the remainder,
	; as part of it must remain allocated and freeing the remainder would
	; result in filling that part with 0xcc in the EC version...
	;
		call	SplitBlockWithAddrFar
		pop	cx
		mov	bx, si		; split the free part
		; Mark block as owned now to prevent attempts at coalescing
		; the two pieces when SplitBlockFreeRemainderWithAddr is called
		; below. Also fends off rabid EC code (+heapFree and the like)
		mov	ds:[bx].HM_owner, handle 0
simple:
	;
	; The part being added is at the bottom of BX. Split it, freeing the
	; bottom part.
	; 
		xchg	ax, cx		; ax <- size of useful block
		sub	ax, ds:[bx].HM_size	; ax <- size to keep
		neg	ax
		jnz	simpleSplit	; => free only part of fake block

if	KERNEL_EXECUTE_IN_PLACE or FULL_EXECUTE_IN_PLACE
	;
	; We are going to free the whole fake block.  Before we do so,
	; however, we need to prepare for fixing up xipHandleTopBlock later,
	; because after we free the fake block the handle may be freed if
	; the block is incorporated into another free block, and we can't find
	; where on the heap we are again.
	; - If the block above this fake block is not free, it may be another
	;   block on the heap (below xipHandleTopBlock) or a block in ROM
	;   (above xipHandleTopBlock).  Either way we will compare
	;   xipHandleTopBlock with the above-block, and update the value if
	;   the above-block is higher.
	; - If the block above is free, xipHandleTopBlock must already be
	;   higher than the above-block.  So we don't need to fixup.
	; - If the fake block is the current xipHandleTopBlock, we need to
	;   fixup now because after we free the fake block, the handle may
	;   be invalid and we can't do comparison anymore.  In this case we
	;   know that this fake block must be the one that connects the last
	;   heap block and the first ROM block.  Hence the above-block will
	;   become the new xipHandleTopBlock.
	;
		mov	si, ds:[bx].HM_next	; si <- block above
		cmp	bx, ds:[xipHandleTopBlock]
		jne	checkFree	; => top block not this fake block
		mov	ds:[xipHandleTopBlock], si	; new top <- blk above
		jmp	noFixupLater
checkFree:
		tst	ds:[si].HM_owner	; check if blk above is free
		jne	freeFakeBlock	; => not free block.  May need fixup
noFixupLater:
		clr	si		; no need to fixup xipHandleTopBlock
freeFakeBlock:
endif	; KERNEL_EXECUTE_IN_PLACE or FULL_EXECUTE_IN_PLACE

		call	DoFreeNoDeleteSwapFar	; free whole fake block
AXIP <		tst	si		; need to fixup?		>
AXIP <		jnz	fixupTopBlock	; => yes.			>
		jmp	done

simpleSplit:
		clr	cl		; free the bottom part
		call	SplitBlockFreeRemainderWithAddr
	;
	; Make sure the split block is locked and owned by the kernel, to deal
	; with fall-thru from the complex double-split case above.
	;
	; 12/8/93 dloft: Also, let's stuff a unique value into HM_otherInfo so
	; that we don't confuse these blocks with something real...
	;
		mov	ds:[bx].HM_lockCount, 1
		mov	ds:[bx].HM_owner, handle 0
		mov	ds:[bx].HM_otherInfo, FAKE_BLOCK_CODE
AXIP <		mov	si, bx		; si <- block above new free block>

if	KERNEL_EXECUTE_IN_PLACE or FULL_EXECUTE_IN_PLACE
fixupTopBlock:
	; si = block above new free block
	;
	; Fixup xipHandleTopBlock if the block above the new free block is
	; higher than the current xipHandleTopBlock.
	;
		mov	bx, ds:[xipHandleTopBlock]
		mov	ax, ds:[bx].HM_addr
		cmp	ax, ds:[si].HM_addr
		jae	done
		mov	ds:[xipHandleTopBlock], si
endif	; KERNEL_EXECUTE_IN_PLACE or FULL_EXECUTE_IN_PLACE

		jmp	done
MemExtendHeap	endp

	;--------------------
	; Copy of FixLinks and FixLinks2 w/o all the EC stuff so I don't
	; have to add Far versions of them. These things just fixup the
	; double-links. MEHFixLinks2 takes the HM_prev and HM_next pointers
	; of ds:bx and makes those handles point to bx. MEHFixLinks does
	; likewise for si first, and then for bx.
	; 
MEHFixLinks	proc	near
		xchg	bx, si			; Fix si first
		call	MEHFixLinks2
		xchg	bx, si
		REAL_FALL_THRU	MEHFixLinks2
MEHFixLinks	endp

MEHFixLinks2	proc	near
		push	si
		mov	si, ds:[loaderVars].KLV_heapStart
		cmp	si, ds:[bx].HM_addr
		jne	10$
		mov	ds:[loaderVars].KLV_handleBottomBlock, bx
10$:
		mov	si, ds:[bx].HM_prev	; fix link from prev block
		mov	ds:[si].HM_next, bx
		mov	si, ds:[bx].HM_next	; fix link from next block
		mov	ds:[si].HM_prev, bx
		pop	si
		ret
MEHFixLinks2	endp

kinit	ends


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetOwnerToKernel

DESCRIPTION:	Set a block's HG_owner field to be the kernel

CALLED BY:	UTILITY

PASS:
	ds - idata
	bx - handle

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
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

SetOwnerToKernel	proc	near
	.enter
	mov	ds:[bx].HG_owner, handle 0
	.leave
	ret

SetOwnerToKernel	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemSwapOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap the given block out to the current swap driver

CALLED BY:	ThrowOutOne
PASS:		bx	= block to swap
		dx	= segment of block being swapped
		ds	= idata
		di	= swap driver to use
		exclusive access to heap variables
RETURN:		carry set if block could not be swapped (swap driver marked
		as full)
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemSwapOut	proc	near	uses di, si
		.enter
	;
	; Call the current swap driver to swap the thing out.
	;
		mov	si, di
	;
	; We can be called when we're full. It's easiest to just check for this
	; here and declare an error if so.
	;
		test	ds:[si].SD_flags, mask SDF_FULL
		jnz	error
retry:
		mov	di, DR_SWAP_SWAP_OUT
		call	CallSwapDriver
		jc	error
	;
	; Tell the debugger the block has been swapped out.
	;
		push	ax
		mov	al, DEBUG_SWAPOUT
		call	FarDebugMemory
	;
	; Update the statistics.
	;
		INT_OFF
		mov	ax, ds:[bx].HM_size
		add	ds:[curStats].SS_swapOuts.SSI_paragraphs, ax
		inc	ds:[curStats].SS_swapOuts.SSI_blocks
		INT_ON
	;
	; Release the memory held by the block.
	;
		mov	al, mask HF_SWAPPED
		call	FreeBlockData
	;
	; Record the swap ID and driver used to swap the thing out.
	;
		pop	ds:[bx].HSM_swapID
		mov	ds:[bx].HSM_swapDriver, si
doneGood:
		clc			; Signal success
done:
		.leave
		ret

error:
	;
	; Couldn't swap it out. If the driver is fast enough to be preferred
	; to discarding, biff enough discardable-but-swapped blocks to make
	; room for the block.
	; XXX: chain blocks swapped to the same driver through the
	; HM_usageValue field? Requires link (simple) and unlink (more
	; complex) but allows easy traversal...
	;
		ornf	ds:[si].SD_flags, mask SDF_FULL	; assume failure

		cmp	ds:[si].SD_speed, SS_PRETTY_FAST
		ja	fail			; => not fast enough to swap
						;  discardable blocks

		push	bx			;preserve handle being swapped
		mov	ds:[bx].HM_addr, dx	;replace address so any heap
						; verifies (e.g. by VM code)
						; won't choke.
		
		mov	bx, ds:[loaderVars].KLV_handleTableStart
scanLoop:
		cmp	ds:[bx].HM_owner,0		;test for free
		je	next
		cmp	ds:[bx].HM_addr,0		;test for in memory
		jnz	next				;branch if so

	;
	; Nuke the block if it's discardable and swapped to this driver.
	;
		test	ds:[bx].HM_flags,mask HF_SWAPPED or mask HF_DISCARDABLE
		jz	next			; no if neither set
		jpo	next			; no if only one set
		cmp	ds:[bx].HSM_swapDriver, si
		jne	next

	;
	; Use MemDiscard.
	;
		call	MemDiscard
next:
		add	bx,size HandleMem
		cmp	bx,ds:[loaderVars].KLV_lastHandle
		jb	scanLoop
		pop	bx			;recover initial handle and
						; its segment

	;
	; If the block being swapped has now become discarded, swapped, or
	; freed, return success.  This could happen if the discard loop above
	; hits a VM block -- we could go through the whole ThrowOutBlocks shme
	; again as we try make room to bring in the VM header during the VM
	; block discard.
	;
		cmp	ds:[bx].HM_owner, 0
		je	doneGood
		test	ds:[bx].HM_flags, mask HF_DISCARDED or mask HF_SWAPPED
		jnz	doneGood
	;
	; Now zero the block's address again and make sure it hasn't become
	; locked in the interim. If it has, we can't swap it, but still need
	; to return with its address field 0 and dx containing the segment,
	; so ThrowOutBlocks can replace it...
	;
		clr	dx
		xchg	ds:[bx].HM_addr, dx
		tst	ds:[bx].HM_lockCount
		jnz	fail

	;
	; If anything was discarded, then MemSwapDelete will have cleared the
	; SDF_FULL flag for the driver. Since we set it at the start, if
	; it's still set, nothing got nuked so the device is still full.
	; 
		test	ds:[si].SD_flags, mask SDF_FULL
		jnz	fail
		jmp	retry
fail:
		add	si, size SwapDriver
		cmp	si, ds:[swapNext]
		jne	returnError

	;
	; Let the user know that all devices are full. This isn't fatal,
	; however. To avoid infinite looping when SysNotify forces a
	; screen refresh, and to try (as usual) to be as unannoying as
	; possible, we only put up this box if a certain interval has
	; passed since last the user saw it. Currently this is 30 seconds.
	; (Don't do any of this for Redwood, which has a very small swap
	; space and can fill up intermittently at any time.)
	; 
if not NO_FULL_SWAPFILE_NOTIFICATION
		mov	ax, ds:[systemCounter].low
		push	ax
		sub	ax, ds:[lastSwapFullNotice]
		cmp	ax, SWAP_FULL_NOTIFICATION_INTERVAL
		pop	ax
		jbe	returnError
		mov	ds:[lastSwapFullNotice], ax

		push	ds
		mov	ds, ds:[fixedStringsSegment]
ifdef	GPC
		mov	si, ds:[tooMuchAtOnce]
		mov	di, ds:[tooMuchAtOncePartTwo]
else
		mov	si, ds:[swapDevFull]
		mov	di, ds:[swapDevFull2]
endif
		mov	ax, mask SNF_CONTINUE
		call	SysNotify
		pop	ds
endif

returnError:
		stc
		jmp	done
MemSwapOut	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemSwapIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap a block in from its swap device

CALLED BY:	FullLockReload
PASS:		ds	= idata
		bx	= block to swap in
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemSwapIn	proc	near
		.enter
		mov	dx, NUMBER_OF_ALLOCATION_RETRIES + 1
retry:
		clr	cx			; allow allocation errors
						;	from MemSwapInLow
		push	dx
		call	MemSwapInLow
		pop	dx
		jnc	done			; got it
		call	AllocationFailure	; else, dec retries and sleep
		;
		; we want to retry -- since we released the heap
		; semaphore in AllocationFailure to sleep, let's see if
		; someone else has swapped in the block we are trying to
		; swap in
		;
		test	ds:[bx].HM_flags, mask HF_SWAPPED
		jnz	retry			; still swapped, try again
						;	(carry clear)
done:
		.leave
		ret
MemSwapIn	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemSwapInLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine to actually swap in a block

CALLED BY:	MemSwapIn, MemPreserveVolatileSwapData
PASS:		ds:bx	= HandleMem to swap in
		ch	= HeapAllocFlags for allocating the new memory
		heap lock grabbed
RETURN:		carry set if AllocHandleAndBytes failed
		carry clear if block swapped in:
			ds:bx.HM_addr set
DESTROYED:	ax, cx, dx, si, di


PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemSwapInLow	proc	far
		.enter
EC <    	call    ECCheckMemHandleFar                             >
EC <		test	ds:[bx].HM_flags, mask HF_SWAPPED		>
EC <		ERROR_Z	BLOCK_NOT_SWAPPED				>

	;
	; Prevent MemSwapOut from discarding our block in the swap device while
	; we're making room for the thing to be swapped in.
	; 
		push    {word}ds:[bx].HM_flags
		andnf   ds:[bx].HM_flags,not (mask HF_DISCARDABLE or mask HF_SWAPABLE)

	;
	; Allocate another block big enough to hold the data.
	;
		push    bx                              ;save handle
		mov     ax, ds:[bx].HSM_size            ;allocate new memory
		mov     bx, ds:[bx].HSM_owner
		call    AllocHandleAndBytes

		mov     si,bx                   ;save space handle
		pop     bx                      ;recover original handle
		jc	allocErr

		call	MemSwapInCallDriver
		jc	swapError
	;
	; Now give the memory from the new handle to the old. Change the
	; handle from swapped to discarded so SwapHandles doesn't double-free
	; the swap-space when it frees SI.
	;
		Assert	bitSet, ds:[bx].HM_flags, HF_SWAPPED
		Assert	bitClear, ds:[bx].HM_flags, HF_DISCARDED
		xornf	ds:[bx].HM_flags, mask HF_SWAPPED or mask HF_DISCARDED
		call    SwapHandles
	;
	; When we pushed the flags above, the lock count was pushed as well.
	; While the flags are guaranteed to be unaffected while the heap is P'd,
	; the lock count is not, so we need to restore the flags in a manner
	; that leaves the lock count unmodified.  Otherwise, we may end up
	; causing a very rare and hard-to-find bug. -dhunter 8/25/2000
	;
		pop	ax			; al = flags, ah = lock count
		andnf	al, not mask HF_SWAPPED
		mov	ds:[bx].HM_flags, al
	;
	; Update the statistics.
	;
		INT_OFF
		mov	ax, ds:[bx].HM_size
		add	ds:[curStats].SS_swapIns.SSI_paragraphs, ax
		inc	ds:[curStats].SS_swapIns.SSI_blocks
		INT_ON
	;
	; Notify debugger that block has come back in again.
	; 
		mov     al, DEBUG_SWAPIN
		call    FarDebugMemory
		clc			; signal success
done:
		.leave
		ret
swapError:
allocErr:
	;
	; We need not worry about popping the lock count with the flags
	; at this point.  Since the block was never swapped in, HM_addr
	; never went non-zero, and no one will touch the lock count while
	; HM_addr is zero. (We also don't need to free the swap memory
	; after a failed swap since MemSwapInCallDriver will never return.)
	; -dhunter 9/5/00
	;
		pop	{word}ds:[bx].HM_flags
		jmp	done
MemSwapInLow	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemSwapInCallDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate swap driver to swap in a block to
		new memory

CALLED BY:	(INTERNAL) MemSwapInLow, MemUnlockMoveCallback
PASS:		ds	= dgroup
		bx	= swapped handle
		si	= handle holding new memory as destination
RETURN:		carry set on error
DESTROYED:	dx, di, ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemSwapInCallDriver proc	near
		.enter
		push	si

EC <		inc	ds:[si].HM_lockCount	; so disk swap won't die in EC>

	;
	; Call the proper swap driver to swap the data back into memory
	;
		mov	dx, ds:[si].HM_addr	; dx <- destination
		mov	si, ds:[bx].HSM_swapDriver
		mov	di, DR_SWAP_SWAP_IN
		call	CallSwapDriver
		jc	swapError
	;
	; Mark the swap driver as not full again.
	;
		andnf	ds:[si].SD_flags, not mask SDF_FULL
done:
		pop	si			;recover handle
EC <		dec	ds:[si].HM_lockCount			>
		.leave
		ret
swapError:
		push	es
		mov	al, KS_TE_SYSTEM_ERROR
		call	AddStringAtMessageBuffer
		mov	al, KS_SWAP_IN_ERROR
		call	AddStringAtESDI
		mov	ax, mask SNF_REBOOT
		call	SysNotifyWithMessageBuffer
		pop	es
		stc
		jmp	done
MemSwapInCallDriver endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallSwapDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to call the swap driver while avoiding death
		in the segment EC code

CALLED BY:	MemSwapInCallDriver, MemSwapOut
PASS:		ds	= idata
		bx	= block whose swap space is being manipulated
		dx	= segment address of the block
		si	= offset of SwapDriver structure
		di	= SwapFunction
RETURN:		carry set on error
DESTROYED:	di, cx, ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	9/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallSwapDriver	proc	near		uses bx
		.enter
	;
	; Fake out SegmentToHandle by priming its one-level cache
	; with the block being swapped. Since we've got the heap semaphore,
	; this should allow drivers to call things that check segments
	; without difficulty, so long as they use the segment in DX and don't
	; adjust it at all...
	;
	; XXX: Right now, this is only important to avoid death in the
	; ECF_SEGMENT error-checking code, but we have it in the non-ec version
	; as well, just to be safe, since SegmentToHandle is available for
	; use there as well...
	; 
		mov	ds:[sthCacheSegment], dx
		mov	ds:[sthCacheHandle], bx	

		call	GetByteSize		; cx <- size
		mov	ds:[handleBeingSwappedDontMessWithIt], bx
		mov	bx, ds:[bx].HSM_swapID	; bx <- swap ID (for read and
						;  delete, only)
		call	ds:[si].SD_strategy
		mov	ds:[handleBeingSwappedDontMessWithIt], 0
		.leave
		ret
CallSwapDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemSwapDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the swap space occupied by a block.

CALLED BY:	DeleteSwapFileIfExists
PASS:		ds	= idata
		bx	= block whose swap space is to be deleted
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemSwapDelete	proc	near	uses si, di, bx
		.enter
		mov	si, ds:[bx].HSM_swapDriver
		mov	bx, ds:[bx].HSM_swapID
	;
	; Mark the device as no longer full, since we're biffing something.
	;
		andnf	ds:[si].SD_flags, not mask SDF_FULL
	;
	; Now contact the driver to free up the space.
	;
		mov	di, DR_SWAP_DISCARD
		call	ds:[si].SD_strategy
		.leave
		ret
MemSwapDelete	endp

DosapplCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemPreserveVolatileSwapData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Preserve any data swapped to a volatile swap device before
		suspending the system.

CALLED BY:	DosExecSuspend
PASS:		ds	= dgroup
RETURN:		carry set if not everything could be swapped in that
			needed to be.
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemPreserveVolatileSwapData proc	near
		uses	ax, bx, cx, dx, si, di
		.enter
	;
	; Gain exclusive access to the heap.
	; 
		call	FarPHeap
	;
	; Now work through the swap driver array, looking for things that are
	; marked volatile and mark them all endangered. This prevents us from
	; swapping stuff out to a later volatile device while bringing things
	; in from an earlier one, then having to do it all over again for
	; the later device...
	; 
		mov	si, offset swapTable - size SwapDriver
		clr	cx
markEndangeredLoop:
		add	si, size SwapDriver
		cmp	si, ds:[swapNext]
		je	handleMarkedDrivers
		test	ds:[si].SD_flags, mask SDF_VOLATILE
		jz	markEndangeredLoop
		inc	cx
		ornf	ds:[si].SD_flags, mask SDF_ENDANGERED
		jmp	markEndangeredLoop

	;
	; Now look through the entire handle table for memory blocks
	; swapped to a driver we marked above. If it's discardable, discard
	; it, else swap it into memory.
	; 
handleMarkedDrivers:
		jcxz	done		; => no volatile drivers, so don't
					;  bother... (carry cleared by ==
					;  comparison w/swapNext)

		mov	bx, ds:[loaderVars].KLV_handleTableStart
		sub	bx, size HandleMem
handleLoop:
		add	bx, size HandleMem
		cmp	bx, ds:[loaderVars].KLV_lastHandle
		je	done
		
		tst	ds:[bx].HM_addr	; non-memory or resident?
		jnz	handleLoop	; yes

		test	ds:[bx].HM_flags, mask HF_SWAPPED
		jz	handleLoop	; => not swapped, so not our concern

		mov	si, ds:[bx].HSM_swapDriver
		test	ds:[si].SD_flags, mask SDF_ENDANGERED
		jz	handleLoop	; => block is safe where it is
	;
	; Block is indeed swapped to a volatile device. If it's discardable,
	; we discard it now, so as not to overburden the non-volatile swap
	; devices in the system.
	; 
		test	ds:[bx].HM_flags, mask HF_DISCARDABLE
		jnz	biffIt
	;
	; Not discardable, so force it into memory, but allow MemSwapInLow
	; to return us an error, in case we've overstressed the system.
	;
swapIn: 
		clr	cx		; no special flags (i.e. allow
					;  errors in allocation)
		call	MemSwapInLow
		jnc	handleLoop
error::					; (a convenient breakpoint for Swat)
	;
	; Couldn't discard or swap in a block, so clear the SDF_ENDANGERED
	; for all drivers before returning carry set.
	; 
		call	MemVolatileSwapNowSafeAndSound
		stc
done:
	;
	; All done, for better or for worse.
	; 
		call	FarVHeap
		.leave
		ret
biffIt:
		call	MemDiscard
		jnc	handleLoop
	;
	; Couldn't discard the handle.  If it's now on the heap, just 
	; continue.  Otherwise, swap it in.
	;
		test	ds:[bx].HM_flags, mask HF_SWAPPED
		jz	handleLoop
		jmp	swapIn

MemPreserveVolatileSwapData endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemVolatileSwapNowSafeAndSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the contents of all volatile swap devices are
		now safe, happy, etc. etc. etc.

CALLED BY:	DosExecUnsuspend, MemPreserveVolatileSwapData
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemVolatileSwapNowSafeAndSound proc	near
		.enter
		mov	si, offset swapTable
clearEndangeredLoop:
		andnf	ds:[si].SD_flags, not mask SDF_ENDANGERED
		add	si, size SwapDriver
		cmp	si, ds:[swapNext]
		jb	clearEndangeredLoop
		.leave
		ret
MemVolatileSwapNowSafeAndSound endp


DosapplCode	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemGetSwapDriverInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the info about a swap driver that's stored in the
		kernel's swap table

CALLED BY:	task drivers
PASS:		cl = zero-based index of swap driver to get information on
RETURN:		carry set if no driver for the passed index
		otherwise:
			bx:dx	= driver strategy routine
			al	= SwapSpeed giving the speed of the swap device
			ah	= SwapDriverFlags
			di	= swap driver id

DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	12/ 1/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemGetSwapDriverInfo	proc	far
		uses	ds, cx
		.enter

		cmp	cl, MAX_SWAP_DRIVERS
		jge	noChance

		segmov	ds, dgroup, ax

		cmp	cl, ds:[swapNumDrivers]
		jge	noChance
		mov	di, offset swapTable

		mov	al, size SwapDriver
		mul	cl
		add	di, ax			; ds:si -> our driver

		movdw	bxdx, ds:[di].SD_strategy
		mov	al, ds:[di].SD_speed
		mov	ah, ds:[di].SD_flags

		clc
done:
		.leave
		ret
noChance:
		stc
		jmp	done
MemGetSwapDriverInfo		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemMigrateSwapData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Migrate a swapped block from one swap driver to another.

CALLED BY:	GLB (swap drivers)
PASS:		bx	= handle of block to migrate
		di	= destination swap driver id
		exclusive access to heap variables
RETURN:		carry set on error (destination device is full)
DESTROYED:	nothing
SIDE EFFECTS:	heap modified

PSEUDO CODE/STRATEGY:
	MemSwapIn(handle)
	MemSwapOut(handle, new driver)
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	12/ 8/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemMigrateSwapData		proc	far
		uses	ax, cx, dx, si, di, ds
		.enter

		push	ax, dx, di	; strategy, id
		segmov	ds, dgroup, cx
		clr	cx		; no special flags (i.e. allow
					;  errors in allocation)
					; ds:bx = HandleMem
		call	MemSwapInLow
		pop	ax, dx, di	; strategy, id
		jc	done

	;
	; Stuff the lastSwapFullNotice so that MemSwapOut doesn't try to put up
	; a SysNotify box...
	;
		mov	dx, ds:[systemCounter].low
		mov	ds:[lastSwapFullNotice], dx

		mov	dx, ds:[bx].HM_addr
		call	MemSwapOut
done:
		.leave
		ret
MemMigrateSwapData		endp

