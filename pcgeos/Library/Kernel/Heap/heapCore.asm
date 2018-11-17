COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		heapCore.asm (core heap routines)

AUTHOR:		Tony Requist

ROUTINES:
	Name		Description
	----		-----------
   INT	FindFree	Create a free block on the heap of the given size
   INT	RelocateBlock	Move a block from one position to another
   INT	FixLinks	Fix the links to a block from prev and next blocks
   INT	CombineBlocks	Combine two adjacent blocks if both are free
   INT	SplitBlock	Split a block into a free block and a non-free block
   INT	SplitBlockFreeRemainder	Split a used block in two, freeing one of the
   				two pieces
   INT	SwapHandles	Swap the block associated with two handles

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Chris	10/88		Made ParaToByte external. Needs new name.
	Tony	10/88		Comments from Jim's code review added
	Cheng	5/89		Code for VM blocks added

DESCRIPTION:
	This file conatins the core heap routines.  See manager.asm for details.

	$Id: heapCore.asm,v 1.1 97/04/05 01:14:05 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FindFree

DESCRIPTION:	Find a block of memory of the given size and type.

CALLED BY:	INTERNAL
		DoAlloc, SysInfo

PASS:
	exclusive access to heap variables
	ax - size (in paragraphs) requested -- if 0xffff then treat this as
	     a request to find the largest block
	cl - flags for block type
		HF_FIXED => search from bottom of memory (fixed heap)
		HF_DEBUG => search from top of memory, but not beyond original
			    heap confines b/c block is pseudo-fixed and may be
			    needed at interrupt time, and we can't guarantee
			    its availability if the thing is allocated in the
			    EMS page frame, e.g.
		0 	=> search from top of memory
		HF_FIXED+HF_DEBUG => search from top of memory (movable heap),
					and continue into fixed heap.
	ds - kernel data segment

RETURN:
	carry - set if not successful
	bx - handle of block found
	ax, cx, ds - unchanged

DESTROYED:
	si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

		/* See if there is space on the heap.  If so, done */
	SearchHeap(paraRequested);
	if (SearchHeap found space) begin
		return(successful);
	end

		/* Next, get rid of cached memory */
	FlushGStateCache();
	curSwapDriver = first swap driver

		/* Next, try compacting the heap.  If this does not work, */
		/* throw out blocks until there is enough space */
	do begin
		if (no compaction was specified) begin
			return(unsuccessful);
		end
		CompactHeap();
		SearchHeap(paraRequested);
		if (SearchHeap found space) begin
			return(successful);
		end
		if (no removing blocks was specified) begin
			return(unsuccessful);
		end
		ThrowOutBlocks(paraRequested - largest block);
	while (ThrowOutBlocks did not return error);
	return(unsuccessful);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

FindFree	proc	far	uses cx, ax, dx
parasNeeded	local	word		; # paragraphs caller needs
blockType	local	HeapFlags
	.enter
EC <	call	AssertHeapMine						>

	;
	; Save parameters in local variables to avoid constant, nagging
	; pushes and pops.
	;
	mov	parasNeeded, ax
	mov	blockType, cl

	;
	; First just look for space on the heap. If it's there, we're happy.
	;
	call	SearchHeap		;see if room exists
	jnc	gotIt			;if so then done

	;
	; If we're trying to allocate a fixed block and there is a locked
	; block too close to the top of fixed heap, there is no point
	; compacting the heap and/or throwing out blocks repeatedly, because
	; doing so won't make us enough room anyway.  Hence we detect such a
	; situation and return an error to our caller now, instead of
	; returning an error after we throw out *all* unlocked blocks, which
	; causes unnecessary threshing both now and later.
	;
	mov	cl, blockType
	andnf	cl, mask HF_FIXED or mask HF_DEBUG	;discard other bits
	cmp	cl, mask HF_FIXED
	jne	checkDone		;=> not normal fixed blk
	call	CalcNonLockedSpaceAboveFixedHeap	;ax = # paras
	cmp	ax, parasNeeded
	jb	jcDone			;=> impossible to make room (CF set)
checkDone:

	mov	di,offset swapTable

	;
	; Try compacting the heap (again)
	;
	cmp	parasNeeded, 0xffff
	jz	forceCompact

if	INI_SETTABLE_HEAP_THRESHOLDS
	push	ax, es
	mov	ax, segment minSpaceForInitialCompaction
	mov	es, ax
	mov	ax, es:minSpaceForInitialCompaction
	cmp	ds:loaderVars.KLV_heapFreeSize, ax
	pop	ax, es
else
	cmp	ds:loaderVars.KLV_heapFreeSize, MIN_SPACE_FOR_INITIAL_COMPACTION
endif
	jbe	noCompact
forceCompact:
	mov	cl,TRUE			;compact entire heap
	call	CompactHeap		;compact to try to make room

	mov	cl, blockType
	mov	ax, parasNeeded
	;
	; if (finding largest block) then return (registers loaded properly)
	;
	cmp	ax,0ffffh
	LONG jz	findLargest

	;
	; Search through the heap again to see if we've made enough room yet.
	;
	call	SearchHeap		;see if room exists
	jnc	gotIt			;if so then done
noCompact:

	;
	; Nope. Throw out enough blocks, over and above the size of the largest
	; block on the heap, for the request to be filled.
	;
	mov	ax, parasNeeded
	sub	ax,dx			;calculate # of para to throw out

	; always throw out a fair amount (or else it is not worth our while)

if	INI_SETTABLE_HEAP_THRESHOLDS
	push	dx, ds
	mov	dx, segment minSpaceToThrowOut
	mov	ds, dx
	cmp	ax, ds:minSpaceToThrowOut
	pop	dx, ds
else
	cmp	ax, MIN_SPACE_TO_THROW_OUT
endif
	jae	10$
if	INI_SETTABLE_HEAP_THRESHOLDS
	push	dx, ds
	mov	dx, segment minSpaceToThrowOut
	mov	ds, dx
	mov	ax, ds:minSpaceToThrowOut
	pop	dx, ds
else
	mov	ax, MIN_SPACE_TO_THROW_OUT
endif
10$:
	push	bp
	call	ThrowOutBlocks
	pop	bp
jcDone:
	jc	done			;if error then branch

	;
	; See if the room was generated in the right place...
	;
	mov	ax, parasNeeded
	mov	cl, blockType
	call	SearchHeap		;see if room exists now.
	jnc	gotIt
	call	FlushGstateCache	;free cached GStates
	jmp	forceCompact		;nope -- go back to compact the heap

gotIt:
	;
	; If allocating movable, try to avoid allocating too close to fixed
	; if there's enough free space in the movable. "Too close" here means
	; in the final free block before the fixed heap. If the movable heap,
	; minus the block we got back, contains more than 1/4 free space,
	; but the request still couldn't be satisfied from any free
	; block but the boundary block, compact the heap and do one more search.
	; 
	test	blockType, mask HF_FIXED; Allocating fixed? (clears CF)
	jnz	done			; Yes -- don't care about this
	mov	si, ds:[bx].HM_next
	cmp	si, ds:[loaderVars].KLV_handleBottomBlock
					; Are we at the top of the heap?
	je	done			; Yes -- don't care about this
	mov	al, ds:[si].HM_flags	; Are we stuck in the middle?
	mov	si, ds:[bx].HM_prev
	xor	al, ds:[si].HM_flags
	test	al, mask HF_FIXED	; (clears CF)
	jz	done			; if blocks are of the same type,
					;  we're not at the block-between-the-
					;  heaps, so we don't care.
	
	mov	ax, ds:[bx].HM_size
	sub	cx, ax			; our block was added in...
	sub	ax, parasNeeded		; Reduce size of inter-block by amount
					;  we require
	cmp	ax, (64 * 1024) shr 4	; Within 64K of fixed heap?
	jae	done			; Nope -- don't worry about it.

	; flag danger to heap if w/in 32K of fixed heap

	cmp	ax, DANGER_LEVEL shr 4	; Within danger level?
	jae	checkFragmentation	; nope

	call	VScrub			; yup -- activate scrub thread

checkFragmentation:
	; see if anything to be gained from compacting the heap now
	add	ax, ds:[bx].HM_addr	; figure total space above and
					;  including our block
	sub	ax, ds:loaderVars.KLV_heapEnd
	neg	ax
	shr	ax			; divide total by 4
	shr	ax
	cmp	ax, cx			; free space >= 1/4 total?
	jb	compactAndSearch	; yes -- must be fragmented. compact and
					;  try again.
done:
EC <	jc	99$							>
EC <	mov	ax, parasNeeded						>
EC <	cmp	ds:[bx].HM_size, ax					>
EC <	ERROR_B	GASP_CHOKE_WHEEZE					>
EC <99$:								>
	.leave
	ret

findLargest:
	;
	; Just finding largest block -- search heap once more and return what
	; we got.
	;
	call	SearchHeap
	jmp	done

compactAndSearch:
	;
	; The movable heap is too fragmented and we're allocating too close to
	; fixed space for our own comfort, so compact the heap and make one
	; more search.
	;
	mov	cl, TRUE
	call	CompactHeap
	mov	ax, parasNeeded
	mov	cl, blockType
	call	SearchHeap
	jmp	done
FindFree	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SearchHeap

DESCRIPTION:	Search the heap for a free block of the given size, or search
		for the largest free block.

CALLED BY:	INTERNAL
		FindFree

PASS:
	exclusive access to heap variables
	ax - size (in paragraphs) requested ($ffff to find largest)
	cl - HeapFlags for block being allocated
		HF_FIXED => search from bottom of memory (fixed heap)
		HF_DEBUG => search from top of memory, but not beyond original
			    heap confines b/c block is pseudo-fixed and may be
			    needed at interrupt time, and we can't guarantee
			    its availability if the thing is allocated in the
			    EMS page frame, e.g.
		0 	=> search from top of memory
		HF_FIXED+HF_DEBUG => search from top of memory (movable heap),
					and continue into fixed heap.
	ds - handles segment

RETURN:
	carry - set if not successful
	bx - handle of block found, or handle to largest block if none found
	dx - size of block bx
	cx - amount of free space above/below bx
	ds - unchanged

DESTROYED:
	si

REGISTER/STACK USAGE:
	ax - number of paragraphs needed
	bx - tempPtr
	dx - size of largest block so far
	bp - handle of largest block so far
	si - offset to HM_prev or HM_next
	di - blockToStopAt

PSEUDO CODE/STRATEGY:

	tempPtr = handleBottomBlock;
	if (request is at allocate from top)
		tempPtr = tempPtr->HM_prev;
	endif
	blockToStopAt = tempPtr
	do begin
		if (tempPtr is free)
			if (block is big enough)
				return (tempPtr)
			endif
		endif
	while (tempPtr != blockToStopAt && tempPtr type == request type)
	return (not found)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

SearchHeap	proc	near	uses di
largest		local	hptr		; Largest free block so far
sizeFree	local	word		; Amount free so far in blocks too small
upperLimit	local	sptr		; Highest address allowed for allocation
	.enter
EC <	call	AssertHeapMine						>
	;
	; Figure starting conditions: initial block (bx) and which pointer in
	; the handle should be used to get to the next one (si)
	; 
	mov	dx, ds:[loaderVars].KLV_heapEnd

	mov	si, HM_next		;assume from bottom
	mov	bx, ds:[loaderVars].KLV_handleBottomBlock
AXIP <	mov	di, bx			;save block at which to stop	>
	andnf	cl, mask HF_FIXED or mask HF_DEBUG	;discard other bits
	cmp	cl, mask HF_FIXED
	je	startSearch		;=> HF_FIXED only, search from bottom
	mov	si, HM_prev		;from top -- go backwards
if TRACK_FINAL_FREE
	mov	bx, ds:[lastFreeBlock]	; and start with final free block
else
NOAXIP<	mov	bx, ds:[bx][si]		;and start at top		>
AXIP <	mov	di, ds:[bx][si]		;save block at which to stop	>
AXIP <	mov	bx, ds:[xipHandleTopBlock]				>
AXIP <	mov	bx, ds:[bx][si]		;previous handle is start point	>
endif

	cmp	cl, mask HF_DEBUG	;allocating pseudo-fixed?
	jne	startSearch		;=> 0 or HF_FIXED+HF_DEBUG. Not p-fixed
	mov	dx, ds:[loaderVars].KLV_origHeapEnd
					;yes -- don't allocate beyond original
					; heap confines.
startSearch:
	mov	ss:[upperLimit], dx

	clr	dx			;init largest so far
	mov	ss:[largest], dx	; and largest handle
	mov	ss:[sizeFree], dx	;  and accumulated free-space
NOAXIP<	mov	di,bx			;save block at which to stop	>

	; the loop starts here -- loop until block found or done

blockLoop:
EC <	call	ECCheckHandleForWeirdness				>

	cmp	ds:[bx][HM_owner],0	;test for block free (owner = 0)
	jz	free

	; Don't check for heap boundary if allocating movable with desperate
	; method.
	cmp	cl, mask HF_FIXED or mask HF_DEBUG
	je	tryNext			;=> don't check

	mov	ch, cl
	xor	ch,ds:[bx][HM_flags]	;check for types different
			CheckHack <mask HF_FIXED eq 0x80>
	js	notFound		;differ => crossed into other heap so
					; there's nothing big enough in the
					; heap we want.

tryNext:

	; move to next block on list

	mov	bx,ds:[bx][si]		;follow pointer
	cmp	bx,di
	jnz	blockLoop		;if looped around then done

notFound:
	mov	bx, ss:[largest]	; return handle of largest block found
	stc
	jmp	done

free:

	;
	; We've found a free block.  See if it's larger than the
	; largest one we've seen so far.
	;
	; ax - size required
	; bx - handle of free block
	; dx - size of largest block seen so far
	;
		
	push	cx
	mov	cx, ds:[bx].HM_size	;adjust accumulated free-space size
	add	ss:[sizeFree], cx

	cmp	dx, cx			;block biggest yet?
	pop	cx
	jae	tryNext			;not as big as biggest and biggest
					; wasn't enough, so advance to next

	;
	; This block is the biggest.  See if it's in the valid range.
	; If it's not, we don't want to save its size, because that
	; will cause us to ignore smaller blocks inside the valid
	; range that are actually big enough to satisfy the required
	; size. 
	;
		
	
	push	bx
	mov	bx, ds:[bx].HM_addr	;block beyond allowed range?
	cmp	ss:[upperLimit], bx	;upper limit below this block?
					; (carry cleared by comparison on fall
					;  through)
	pop	bx
	jbe	tryNext			;yes -- keep looking

	mov	dx, ds:[bx].HM_size	;record size
	mov	ss:[largest], bx	;save handle

	cmp	dx, ax			;block big enough?
	jb	tryNext

done:
	mov	cx, ss:[sizeFree]	;return size free above chosen block
					; (or in entire movable/fixed part of
					; heap)
	.leave
	ret

SearchHeap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcNonLockedSpaceAboveFixedHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the amount of contiguous non-locked space above
		the topmost fixed block and the bottommost locked movable
		block (if any).  This includes space from all free blocks
		and all unlocked movable blocks.  Space above KLV_origHeapEnd
		is not counted, however.

CALLED BY:	INTERNAL
		FindFree
PASS:		ds	= kernel data segment
RETURN:		ax	= # paragraphs
DESTROYED:	bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Fake blocks in fixed heap are treated as fixed (HF_FIXED set).
	Fake blocks in movable heap are treated as locked (HM_lockCount = 1).
	Pseudo-fixed blocks are treated as locked (HM_lockCount =
		LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED).

	This routine hasn't been tested in XIP yet.  -- ayuen 4/30/00

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	4/28/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AXIP <	PrintMessage <This routine hasn't been tested in XIP yet.>	>

CalcNonLockedSpaceAboveFixedHeap	proc	near

	mov	ax, ds:[loaderVars].KLV_origHeapEnd	; ax = upper limit

	mov	bx, ds:[loaderVars].KLV_handleBottomBlock
	jmp	checkAddr		; enter the loop

blkLoop:
	mov	bx, ds:[bx].HM_next
	cmp	bx, ds:[loaderVars].KLV_handleBottomBlock
	je	endFound		; => prev blk was top blk

checkAddr:
	mov	di, ds:[bx].HM_addr
	cmp	di, ax			; KLV_origHeapEnd reached?
	jae	endFound		; => yes

	test	ds:[bx].HM_flags, mask HF_FIXED
	jz	notFixed		; => free or unlocked or locked
	mov	cx, di			; cx = start addr of this fixed blk
	add	cx, ds:[bx].HM_size	; cx = end addr of this fixed blk
if	ERROR_CHECK
	; SearchHeap claims it doesn't allocate fixed blocks in the region
	; above KLV_origHeapEnd, but I think as a bug it may do that.  So
	; let's try to catch that case.
	Assert	b, cx, ax		; assert end of blk below origHeapEnd
endif	; ERROR_CHECK
	jmp	blkLoop

notFixed:
	tst	ds:[bx].HM_lockCount
	jz	blkLoop			; => free or unlocked

	; locked block found
	mov	ax, di			; ax = start addr of this locked blk

endFound:
	;
	; We know for sure the above loop has found an end address of some
	; fixed block, since we know there exist at least two fixed blocks:
	; kdata and kcode.
	;
	sub	ax, cx			; ax = non-locked space

	ret
CalcNonLockedSpaceAboveFixedHeap	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CompactHeap

DESCRIPTION:	Compact the heap to bring the free space togather

CALLED BY:	INTERNAL
		FindFree

PASS:
	exclusive access to heap variables
	cl - flag - TRUE for compact whole heap, FALSE for incremental mode
	ds - kernel data segment

RETURN:
	carry - set if entire heap compacted
	ds - same

DESTROYED:
	ax, bx, cx, dx, bp, si

REGISTER/STACK USAGE:
	bx - firstBlock
	cx - incremental flag
	dx - mlSize
	si - secondBlock
	bp - mlBlock (block to which unlocked blocks are shifted, if they'll
	     fit)

PSEUDO CODE/STRATEGY:

	Move from the end of the stack forward, moving all unlocked moveable
blocks towards the end of memory.

	mlSize = 0				/* this is the free block */
						/* used to move stuff around */
						/* locked blocks */
	firstBlock = handleBottomBlock->HM_prev	/* last block on heap */
	while (1) do begin
		secondBlock = firstBlock
		firstBlock = firstBlock->HM_prev
		if (firstBlock > secondBlock)
			exit()
		endif
		Combine(firstBlock, secondBlock)
		if (firstBlock not free)
			if (firstBlock fixed)
				exit()
			endif
			INT_OFF
			if (firstBlock locked)
				INT_ON
				if (secondBlock free
						and secondBlock.size > mlSize)
					mlBlock = secondBlock
					mlSize = secondBlock.size
				endif
			else
				temp = firstBlock.address
				firstBlock.address = 0
				INT_ON
				if (firstBlock->HM_size <= mlSize)
					Move(firstBlock to mlBlock)
					firstBlock.address = moved to address
					if (incremental flag)
						exit
					endif
					firstBlock = mlBlock
				else if (secondBlock free)
					Swap(firstBlock, secondBlock)
					firstBlock.address = moved to address
					if (incremental flag)
						exit
					endif
				endif
			endif
		endif
	end

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Stop compacting if you get a block of the needed size?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

CompactHeap	proc	near		uses bp, di
	.enter
EC <	call	AssertHeapMine						>
EC <	call	ECMemVerifyHeapLow					>

	; mlSize = 0
	; firstBlock = handleBottomBlock.HM_prev

	;
	; Initialize state, pointing to highest block on the heap and setting
	; mlSize (size of the block to which unlocked movable blocks can be
	; copied) to 0 so we don't try to move anything. mlSize (dx) will be set
	; throughout this loop to be the size of the largest free block seen
	; so far. mlBlock (bp) holds the handle of this modern wonder.
	;
	clr	dx

if TRACK_FINAL_FREE
	; no point in starting with any block past the last free one, as that
	; part of the heap is clearly already compacted.
	; 
	mov	bx, ds:[lastFreeBlock]
else
	call	GetLastBlock
	jc	done			;CF set => nothing to compact (!?)
endif

blockLoop:
	;
	; Shift our focus down to the next block. If the address of our new
	; block-of-the-minute is greater than our previous block's, it means
	; we've wrapped and should quit while we're ahead.
	;
	INT_ON
	mov	si,bx			;secondBlock = firstBlock
	mov	bx,ds:[bx][HM_prev]	;firstBlock = firstBlock.HM_prev
	mov	di,ds:[bx][HM_addr]	;di = address (used if block moved)
	cmp	di,ds:[si][HM_addr]	;make sure first block < second block
EC <	ERROR_E	CORRUPTED_HEAP					>
	ja	allCompact
	;
	; Combine the two blocks in case previous motion yielded two
	; free blocks next to each other (CombineBlocks handles being
	; given an in-use block or two).
	;
	call	CombineBlocks
	;
	; If block is free, we don't do anything with it for now. When we're
	; sure it can't be combined with any earlier blocks (i.e. when it's our
	; secondBlock and our firstBlock is in-use), we'll deal with possibly
	; making it the mlBlock to which lower blocks will be moved.
	;
	cmp	ds:[bx][HM_owner],0	;check for free
	jz	blockLoop
	;
	; Exit if we've gotten back to the fixed portion of the heap
	;
	test	ds:[bx][HM_flags],mask HF_FIXED
	jnz	allCompact		;heap totally compacted if so

	;
	; See if our current secondBlock should be promoted to be our preferred
	; mlBlock destination. We do this if secondBlock is both free and
	; larger than our current mlBlock.
	; 

	INT_OFF
	cmp	ds:[bx][HM_lockCount],0	;check for locked
	jz	unLocked		;if unlocked then branch

	cmp	ds:[si][HM_owner],0	;test for secondBlock free
	jnz	blockLoop			;if not then loop

	cmp	ds:[si][HM_size],dx	;compare size to mlSize
	jbe	blockLoop

	mov	bp,si			;save free block to move stuff to
	mov	dx,ds:[si][HM_size]	;and save size
	jmp	blockLoop

unLocked:
	;
	; See if we can shift this block to the current destination.
	;
	cmp	ds:[bx][HM_size],dx	;check for able to move this block
	jbe	moveAround		;around a fixed block
	;
	; Well, if we can't move it to the current destination, see if
	; secondBlock is free and shift firstBlock up to there if it
	; is, getting the contents that much higher in memory.
	; 
	cmp	ds:[si][HM_owner],0	;test for secondBlock free
	jnz	blockLoop		;if not then loop -- nothing we can do.

	mov	ds:[bx][HM_addr],0	;data address is saved in di
	INT_ON

	push	cx
	push	dx

	mov	dx, di
	call	callContract
	mov	di, dx
	mov	si, ds:[bx].HM_next	;reload SI in case block was contracted
					; and former SI was combined with new
					; free block holding BX's former free
					; space.
	mov	ax, ds:[si].HM_size	;compensate for DoFree that SwapHandles
	sub	ds:[loaderVars].KLV_heapFreeSize, ax
					; will be doing in a bit...

	call	SwapUsedFree		;swap the blocks at bx and si. This
					; will cause us to re-examine si with
					; it having been combined with bx.prev
					; if that was free too.
	pop	dx
afterMove:
	pop	cx
	;XXX: IS THIS EVER USED?
	tst	cl			;test for compacting entire heap
	jnz	blockLoop		;if so then keep going
	clc				;return that entire heap is (probably)
					;not compacted

done:
EC <	pushf								>
EC <	call	ECMemVerifyHeapLow					>
EC <	popf								>
	.leave
	ret
allCompact:
	stc
	jmp	done
moveAround:

	;We're here to move a block around a (or many) locked block(s). 
	; bx is block to move, bp is destination, dx is destination size

	;
	; zero bx's address so no-one tries to use it while it's in-transit
	;
	mov	ds:[bx][HM_addr],0	;data address is saved in di
	INT_ON				;can now allow switches

	xchg	dx, di			;dx <- data address, di <- mlSize
	call	callContract		;contract block before moving
	xchg	dx, di

	push	cx			;save "incremental flag" -- it will
					; be restored at afterMove
	;
	; Split mlBlock into two, if necessary, pointing mlBlock at the higher
	; portion, sized to fit the block we're shifting.
	;
	mov	ax,ds:[bx][HM_size]	;size to create
	sub	ds:[loaderVars].KLV_heapFreeSize, ax
					;compensate for DoFree that SwapHandles
					; will be doing later...
	xchg	bx,bp			;pass block to split and save block
					; being moved
	clr	cl			;allocate at top (movable)
	call	SplitBlockWithAddr
	mov	si,bx			;restore proper relationship between
					; source and dest.
	mov	bx, bp

	;
	; Move the data and reposition bx in the handle chain. This will cause
	; us to re-traverse the blocks between the block we just moved and the
	; destination block to which we moved it, which is good.
	;
	call	RelocateBlock

	clr	dx			;reset free block size -- it will be
					; handled by re-traversing the handle
					; list from bx's new position.
	jmp	afterMove

;---

callContract:
	mov	ax, ds:systemCounter.low
	sub	ax, ds:[bx].HM_usageValue
	mov	cx, LCT_ALWAYS_COMPACT
	cmp	ax, AGE_TO_ALWAYS_LMEM_COMPACT
	jae	gotCompactParam
	mov	cx, LCT_COMPACT_IF_12_FREE
	cmp	ax, AGE_TO_LMEM_COMPACT_IF_12_FREE
	jae	gotCompactParam
	mov	cx, LCT_COMPACT_IF_25_FREE
	cmp	ax, AGE_TO_LMEM_COMPACT_IF_25_FREE
	jae	gotCompactParam
	mov	cx, LCT_COMPACT_IF_50_FREE
gotCompactParam:
	call	ContractIfLMem		;contract the block before moving it
	retn

CompactHeap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplitBlockWithAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Split a block that still has its address in HM_addr

CALLED BY:	CompactHeap, DoReAlloc
PASS:		ax	= size of block to allocate (paragraphs)
		bx	= block to split
		cl	= mask HF_FIXED to leave bottom allocated,
		 	  0 to leave top allocated
RETURN:		bx	= block that was split (ax paragraphs)
		si	= handle to free memory, if any
		dx	= segment address of used block
		carry set if block was actually split
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		lastFreeBlock may be updated

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplitBlockWithAddrFar proc far
	call	SplitBlockWithAddr
	ret
SplitBlockWithAddrFar endp

SplitBlockWithAddr proc	near
	.enter
	clr	dx
	xchg	ds:[bx].HM_addr, dx	;fetch block addr & zero it
	call	SplitBlock		;split block into two
	mov	ds:[bx].HM_addr, dx	;restore new address

if TRACK_FINAL_FREE
	pushf
	push	si
	jc	checkLastFree		; => si is handle to free memory
	clr	si			; no free memory
checkLastFree:
	cmp	ds:[lastFreeBlock], bx	; did we just split the last beast?
	jne	giveOverNewMem		; no, so couldn't have changed
					;  anything.
	tst	si			; any free stuff left here?
	jnz	haveLastFree		; yes -- that must still be the last
					;  free block, regardless of whether
					;  used space was allocated from top
					;  or bottom
	mov	si, bx			; no -- find next free block below
					;  what was the last.
findLastFree:
	mov	si, ds:[si].HM_prev
	cmp	ds:[si].HM_owner, 0	; free?
	jne	findLastFree

haveLastFree:
	mov	ds:[lastFreeBlock], si
giveOverNewMem:
	pop	si
	popf
endif

	.leave
	ret
SplitBlockWithAddr endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplitBlockFreeRemainderWithAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Split a block that still has its address in HM_addr and free
		the remainder.

CALLED BY:	MemExtendHeap
PASS:		ax	= size of block to allocate (paragraphs)
		bx	= block to split
		cl	= mask HF_FIXED to leave bottom allocated,
		 	  0 to leave top allocated
RETURN:		bx	= block that was split (ax paragraphs)
		dx	= segment address of used block
		carry set if block was actually split
DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplitBlockFreeRemainderWithAddr proc	far
	.enter
	clr	dx
	xchg	ds:[bx].HM_addr, dx	;fetch block addr & zero it
	call	SplitBlockFreeRemainder		;split block into two
	mov	ds:[bx].HM_addr, dx	;restore new address
	.leave
	ret
SplitBlockFreeRemainderWithAddr endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SplitBlock

DESCRIPTION:	Split a block into two blocks

CALLED BY:	INTERNAL
		DoAlloc, CompactHeap, DoReAlloc

PASS:
	exclusive access to heap variables
	ax - block size to create (paragraphs)
	bx - handle of block to split
	cl - flag: HF_FIXED to allocate used block at bottom
	ds - kernel data segment
	dx - segment address of block to split

RETURN:
	carry - set if block was actually split
	si - handle to new (free) block
	bx - handle of block that was split
	dx - segment address of split (used) block

DESTROYED:
	ax

REGISTER/STACK USAGE:
	ax - size of new block
	si - handle of higher block
	bx - handle of lower block

PSEUDO CODE/STRATEGY:
	The idea here is to split input block into two pieces, one holding
		ax paragraphs of memory and one holding the rest.
	Before addresses are assigned, si is the handle with ax paragraphs,
		bx the handle with the rest.
	The addresses (i.e. the actual piece of the initial block) of these
		two handles are determined by the passed flag: if cl is
		HF_FIXED, si retains its original address and bx is
		adjusted upward, else the opposite happens.
	Once the addresses are set, the two are linked together in the
		proper order and the surrounding blocks adjusted accordingly


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/15/87		Initial version written and tested
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

SplitBlock	proc	near
	.enter
EC <	call	AssertHeapMine						>

	;
	; Figure new free-block's size
	;
	cmp	ax, ds:[bx].HM_size
	je	finish

	;
	; Duplicate the handle and divide the block into its two areas
	;
	call	DupHandle

	mov	ds:[si][HM_size],ax	;store used size in original handle

	sub	ds:[bx][HM_size],ax	;figure free size in new handle
EC <	ERROR_B	SPLIT_BLOCK_FREE_SIZE_TOO_BIG				>
	mov	ds:[bx][HM_owner],0		;mark new as free
	mov	{word}ds:[bx][HM_flags],0  	;not discardable or swappable or
					      	; locked

	push	bx, si
	mov	ds:[bx].HM_addr, dx	; Assume free at bottom
	add	dx, ds:[bx].HM_size	; Compute new address for used block
					;  after the free block

	test	cl,mask HF_FIXED
	jz	fixlinks	;if allocating at top, branch -- free addr
				; and registers already set

	mov	dx, ds:[bx].HM_addr	; fetch original address
	add	ax, dx			; add to used size
	mov	ds:[bx].HM_addr, ax	; and store in free handle
	xchg	bx,si			;swap handles to allocate at top

fixlinks:
	; fix up links.
	;
	; bx = handle of block lower in memory
	; si = handle of block higher in memory

	mov	ds:[si][HM_prev],bx	;point high block at low block
	mov	ds:[bx][HM_next],si	;point low block at high block

	call	FixLinks		;update surrounding blocks

	pop	si, bx			; si <- free, bx <- split
	stc				;indicate split happened

finish:
	.leave
	ret
SplitBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplitBlockFreeRemainder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Split an in-use block into two and free the remainder

CALLED BY:	ContractBlock, DoReAlloc
PASS:		exclusive access to heap variables
		ax - block size to create (paragraphs)
		bx - handle of block to split
		cl - flag: HF_FIXED to allocate used block at bottom
		ds - kernel data segment
		dx - segment address of block to split

RETURN: 	carry - set if block was actually split
		bx - handle of block that was split

DESTROYED: 	ax, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplitBlockFreeRemainder	proc	near
		.enter
	;
	; Perform initial split
	;
		call	SplitBlock
		jnc	done			;branch if no split happened
	;
	; Free the other block we got back.
	;
		xchg	bx, si
		call	DoFreeNoDeleteSwap
		mov	bx, si
		stc				;block was split
done:
EC <    	call    AssertFreeBlocksCC                                     >

		.leave
		ret
SplitBlockFreeRemainder	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SwapUsedFree

DESCRIPTION:	Swap in the heap a used block (in lower memory) and a free
		block (in higher memory)

CALLED BY:	INTERNAL
		CompactHeap

PASS:
	exclusive access to heap variables
	bx - handle to first block (unlocked)
	si - handle to second block (free)
	di - data address of first block
	ds - kernel data segment

RETURN:
	ax - new address for second block

DESTROYED:
	cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	secondHandle.HM_addr = firstHandle.HM_addr

	newDataAddress = firstHandle.HM_addr + secondHandle.size
	firstHandle.HM_addr = newDataAddress

	call MoveBlock to move the block's data


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

SwapUsedFree	proc	near
EC <	call	CheckBX_SIAdjacent					>
EC <	call	AssertHeapMine						>

	mov	ax,ds:[bx][HM_size]		;swap sizes (they will be
	mov	cx,ax
	xchg	ax,ds:[si][HM_size]		;swapped back later)
	mov	ds:[bx][HM_size],ax

	mov	dx,di
	add	ax,dx				;dx = source for move
						;ax = destination for move
						;cx = # paras to move
	mov	ds:[si][HM_addr],ax

	GOTO	SUF_RB_common

SwapUsedFree	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	RelocateBlock

DESCRIPTION:	Move a block from one handle to another

CALLED BY:	INTERNAL
		DoReAlloc, CompactHeap

PASS:
	exclusive access to heap variables
	bx - handle of block to relocate
	si - handle of destination to relocate to
	ds - kernel data segment
	di - address of block to relocate

RETURN:
	si - same but memory freed

DESTROYED:
	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Copy block's data
	Exchange HM_addr, size, HM_next and HM_prev from dest to source
	Fix pointers to both blocks
	Call DoFree to free dest

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

RelocateBlock	proc	near
	mov	ax,ds:[si][HM_addr]	;dest address
	mov	dx,di			;source address
	mov	cx,ds:[bx][HM_size]	;# of paragraphs

	FALL_THRU	SUF_RB_common

RelocateBlock	endp


SUF_RB_common	proc	near
	call	MoveBlock		;copy block data

	INT_OFF				;no context switching until handles
					;are swapped
	mov	ds:[bx][HM_addr],dx

	FALL_THRU	SwapHandles

SUF_RB_common	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SwapHandles

DESCRIPTION:	Exchange address, size, next and prev pointers between two
		handles, "freeing" the second handle's memory (i.e. combining
		it with any neighboring blocks)

CALLED BY:	INTERNAL
		RelocateBlock, DoAlloc

PASS:
	exclusive access to heap variables
	bx - handle of block to relocate
	si - handle of destination to relocate to
	ds - kernel data segment

RETURN:
	si - same but memory freed

DESTROYED:
	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Copy block's data
	Exchange HM_addr, size, HM_next and HM_prev from dest to source
	Fix pointers to both blocks
	Call DoFree to free dest

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

SwapHandles	proc	near
	call	SwapHandlesLow
	push	bx
	mov	bx,si
	call	DoFree
	pop	bx
	ret

SwapHandles	endp

if	ERROR_CHECK
SwapHandlesFar	proc	far
	call	SwapHandles
	ret
SwapHandlesFar	endp
endif	;ERROR_CHECK


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SwapHandlesLow

DESCRIPTION:	Swap data between two handles

CALLED BY:	INTERNAL
		SwapHandles, MemSwap

PASS:
	exclusive access to heap variables
	bx, si - handles for which to swap memory

RETURN:
	memory swapped

DESTROYED:
	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Copy block's data
	Exchange HM_addr, size, HM_next and HM_prev from dest to source
	Fix pointers to both blocks

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

SwapHandlesLow	proc	near
EC <	call	AssertHeapMine					>
	push	bx
	push	si
	mov	cx,5			;exchange 4 words (+1 for HM_owner,
					; which is not swapped)
	INT_OFF
copy:
	lodsw				;fetch initial word
	cmp	cx, 5 - ((offset HM_owner)/2)
	jz	skipThisWord
	xchg	ds:[bx],ax
	mov	ds:[si-2],ax
skipThisWord:
	inc	bx			;bump pointer
	inc	bx
	loop	copy
		CheckHack <offset HM_flags eq 10>
	;
	; Exchange the HF_DISCARDED & HF_SWAPPED flags between the blocks, as
	; well. Do this with interrupts off. This closes a nasty window where
	; a core block was being moved, via MemForceMove, and had a non-zero
	; address, but still had HF_DISCARDED set, when MemOwner was called
	; during a timer routine, yielding death -- ardeb 11/10/94
	;
	mov	al, ds:[bx]
	mov	ah, ds:[si]
	mov	cx, ax
	andnf	cx, not (mask HF_DISCARDED or mask HF_SWAPPED or \
			 ((mask HF_DISCARDED or mask HF_SWAPPED) shl 8))
	andnf	ax, (mask HF_DISCARDED or mask HF_SWAPPED or \
		     ((mask HF_DISCARDED or mask HF_SWAPPED) shl 8))
	xchg	al, ah		; exchange swapped/discarded bits
	or	ax, cx		; merge exchanged into actual
	mov	ds:[bx], al
	mov	ds:[si], ah

	INT_ON
	pop	si
	pop	bx

	;
	; Special case swapping of swapped handle with memory handle. Swapped
	; handle isn't in the memory list and we don't want to get mysterious
	; death because opaque HSM_swapID happens to match the handle ID of
	; the memory handle...
	; 
	tst	ds:[si].HM_addr
	jz	20$

	;
	; Adjust linkage to each other, if necessary. Since HM_next and HM_prev
	; were swapped above, along with HM_addr and HM_size, we need to see
	; if the handles are self-referential in either direction.
	; 
	cmp	ds:[bx][HM_next],bx	;si below bx?
	jnz	10$			; no
	mov	ds:[bx][HM_next],si	;Yes -- bx now below si
	mov	ds:[si][HM_prev],bx
	jmp	20$
10$:
	cmp	ds:[bx][HM_prev],bx	;bx below si?
	jnz	20$
	mov	ds:[bx][HM_prev],si	;Yes -- si now below bx
	mov	ds:[si][HM_next],bx
20$:
	;
	; Now fix links to other blocks around si
	;
	GOTO	FixLinks		;fix links in new block

SwapHandlesLow	endp

if LOG_BLOCK_MOVEMENT
	;	ax = BlockMovementOperation (trashed on return)
	;	bx = Handle being moved
	;	ds = kernel data segment
LogBlockMovement	proc	far
	push	cx, si
	mov	si, ds:blockMovementHead
	add	si, offset blockMovementLog
	;
	; record vital data
	;
	mov	ds:[si].BME_op, ax
	mov	ds:[si].BME_handle, bx
	mov	ax, ds:[bx].HM_addr
	mov	ds:[si].BME_address, ax
	mov	ax, ds:[bx].HM_size
	mov	cl, 4
	shl	ax, cl
	mov	ds:[si].BME_size, ax
	;
	; Increment head pointer
	;
	add	si, size BlockMovementEntry
	sub	si, offset blockMovementLog
	cmp	si, size blockMovementLog
	jb	done
	clr	si
done:
	mov	ds:blockMovementHead, si
	pop	cx, si
	ret
LogBlockMovement	endp

endif ; LOG_BLOCK_MOVEMENT


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MoveBlock

DESCRIPTION:	Move memory from one block to another

CALLED BY:	INTERNAL
		RelocateBlock, SwapUsedFree

PASS:
	ax - destination segment address
	bx - handle of block being moved
	cx - number of paragraphs to move
	dx - source segment for move
	ds - kernel data segment

RETURN:

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	convert paragraphs to words and use rep movsw to do the move

	We move from the top down to accomodate SwapUsedFree, which is
	moving things up that could easily overlap.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

MoveBlock	proc	near
	push	ax, es
	push	si, ds, cx

	; non-ec: make sure we're not moving to/from 0:0

NEC <	tst	ax							>
NEC <	jz	necError						>
NEC <	tst	dx							>
NEC <	jz	necError						>

EC <	cmp	ax, ds:[loaderVars].KLV_heapStart			>
EC <	ERROR_B	BAD_MOVE_BLOCK						>
EC <	cmp	ax, ds:[loaderVars].KLV_heapEnd				>
EC <	ERROR_AE BAD_MOVE_BLOCK						>
EC <	cmp	dx, ds:[loaderVars].KLV_heapStart			>
EC <	ERROR_B	BAD_MOVE_BLOCK						>
EC <	cmp	dx, ds:[loaderVars].KLV_heapEnd				>
EC <	ERROR_AE BAD_MOVE_BLOCK						>

if LOG_BLOCK_MOVEMENT
	push	ax
	mov	ax, BMO_MOVE
	call	LogBlockMovement
	pop	ax
endif
	mov	ds, dx			;source segment
	mov	es, ax			;dest segment

	xchg	ax, cx			;(1-byte inst)
	call	ParaToByteAX		;convert paragraphs to bytes

	mov	si, cx			;set si and di last word to move
if	USE_32BIT_STRING_INSTR
	sub	si, size dword
else
	dec	si
	dec	si
endif	; USE_32BIT_STRING_INSTR
	mov	di, si
if	USE_32BIT_STRING_INSTR
	shr	cx, 2			;convert back to dwords
else
	shr	cx			;convert back to words
endif	; USE_32BIT_STRING_INSTR

	std				;set direction flag
if	USE_32BIT_STRING_INSTR
	rep movsd
else
	rep movsw
endif	; USE_32BIT_STRING_INSTR
	cld				;reset default state

	pop	si, ds, cx

	mov	al,DEBUG_MOVE		;notify debugger of block movement
					; passing destination address in es.
	call	FarDebugMemory		

	pop	ax, es

	ret

NEC <necError:								>
NEC <	ERROR	BAD_MOVE_BLOCK						>

MoveBlock	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FixLinks, FixLinks2

DESCRIPTION:	FixLinks - Fix the links to both bx and si
		FixLinks2 - Fix the links to the block bx

CALLED BY:	INTERNAL
		FixLinks - FreeBlockData, SplitBlock, SwapHandles
		FixLinks2 - CombineBlocks, FixLinks

PASS:
	exclusive access to heap variables
	bx, si - blocks to fix
	ds - kernel data segment

RETURN:
	bx, si, ds - same

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

FixLinks	proc	near
	xchg	bx,si			; Fix si first
	call	FixLinks2
	xchg	bx,si
	REAL_FALL_THRU	FixLinks2	; Now fix BX
FixLinks	endp

FixLinks2	proc	near
EC <	call	AssertHeapMine						>
	cmp	ds:[bx][HM_addr],0	;check for no memory associated
	jz	20$

	push	si

	mov	si, ds:[loaderVars].KLV_heapStart
	cmp	si, ds:[bx].HM_addr
EC <	ERROR_A	CORRUPTED_HEAP						>
	jnz	10$
	mov	ds:[loaderVars].KLV_handleBottomBlock, bx
10$:

	mov	si, ds:[bx].HM_prev	;fix link from prev block
	mov	ds:[si].HM_next, bx

	mov	si, ds:[bx].HM_next	;fix link from next block
	mov	ds:[si].HM_prev, bx

	pop	si
20$:
	ret

FixLinks2	endp

if	ERROR_CHECK
FixLinks2Far	proc	far
	call	FixLinks2
	ret
FixLinks2Far	endp
endif	;ERROR_CHECK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CombineBX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try and combine the block BX with its adjacent compatriots

CALLED BY:	DoFreeNoDeleteSwap, SplitBlockFreeRemainder
PASS:		ds	= idata
		bx	= block to combine
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CombineBX	proc	near	uses	si
		.enter
		mov	si,ds:[bx][HM_next]	;try to combine with next block
		call	CombineBlocks

		mov	si, bx
		mov	bx,ds:[bx][HM_prev]	;try to combine with previous
		call	CombineBlocks

if TRACK_FINAL_FREE
	;
	; see if original block combined with previous, so we can return
	; a useful handle.
	; 
   		cmp	ds:[si].HG_type, SIG_FREE
		je	haveBX
		mov	bx, si			; not combined, so return
						;  original handle in BX
haveBX:
	;
	; Now see if result of combination is a block that comes after the
	; lastFreeBlock.
	; 
		mov	si, ds:[lastFreeBlock]
		mov	si, ds:[si].HM_addr
		cmp	si, ds:[bx].HM_addr
		jae	done
setLastFree::
		mov	ds:[lastFreeBlock], bx
done:
EC <		call	CheckLastFreeBlock				>
endif
		.leave
		ret
CombineBX	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	CombineBlocks

DESCRIPTION:	CombineBlocks - Combine two adjacent blocks if both are free

CALLED BY:	INTERNAL
		CombineBlocks - DoFree, CompactHeap, DoReAlloc

PASS:
	exclusive access to heap variables
	bx - pointer to first block (lower block in memory)
	si - pointer to second block
	ds - kernel segment

RETURN:
	ds - same
	si - same but possibly meaningless (if second handle was freed)

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	assuming bx and si are adjacent (bx below si):
	If (block blocks are free) and (first block < second block)
		fix size
		fix first block's HM_next
		fix block after second block's HM_prev
		free second handle

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@
CombineBlocks	proc	near
EC <	call	CheckBX_SIAdjacent					>
EC <	call	AssertHeapMine						>

	; don't combine last the block with the first

	cmp	si, ds:[loaderVars].KLV_handleBottomBlock
	jz	done

	mov	ax, ds:[bx].HM_owner	;test for both free
	or	ax, ds:[si].HM_owner
	jnz	done			;if not then done
	mov	ax, ds:[bx].HM_addr
	cmp	ax, ds:[si].HM_addr	;make sure first block < second block
EC <	ERROR_AE	CORRUPTED_HEAP					>
NEC <	jae	done							>

	mov	ax, ds:[si].HM_size	;fix size
	add	ds:[bx].HM_size, ax

	mov	ax, ds:[si].HM_next	;make si point at block after second
	mov	ds:[bx].HM_next, ax	;fix links
	call	FixLinks2

	xchg	bx, si			;free second handle

if TRACK_FINAL_FREE
	cmp	bx, ds:[lastFreeBlock]
	jne	freeBX
	; if we're freeing the handle for the last free block because we merged
	; it with si, then si must be the new lastFreeBlock
	mov	ds:[lastFreeBlock], si
freeBX:
endif

	call	FreeHandle
	xchg	bx, si
done:
	ret

CombineBlocks	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ThrowOutBlocks

DESCRIPTION:	Throw out blocks from memory.

CALLED BY:	INTERNAL
		FindFree

PASS:
	exclusive access to heap variables unless called by the scrub thread
	ax - number of paragraphs to throw out
	ds - kernel segment
	di - first swap driver to use (offset swapTable)

RETURN:
	carry - set if error
	ax - destroyed
	ds - unchanged

DESTROYED:
	bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax - paraToThrowOut
	bx - tempPtr
	cx - HM_flags (inner loop), counter (outer loop)
	si - index into TOB array

PSEUDO CODE/STRATEGY:

	Throw out memory starting at the least recently used block.  If it
	is discardable, discard it.  If it is moveable, swap it.

	do {
		numberFound = FindNOldest(methodToUse)
		if (numberFound == 0) {
			swap driver = next(swap driver)
			if (swap drivers exhausted)
				return(error)
			}
		}
		for (count = 0; count < numberFound and paraToThrowOut > 0;
								    count++) {
		    tempPtr = hArray[count];
		    if (tempPtr is unlocked) {
			    err = ThrowOutBlock(tempPtr);
			    if (err) {
				break
			    } else {
        			paraToThrowOut -= tempPtr.HM_size;
			    }
		    }   /* if unlocked */
		}   /* for count */
	} while (paraToThrowOut > 0);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added
	Adam	6/90		Changed to work on scrub thread
	mevissen 3/99		Added shme to ensure a 'slow' swap driver is
				called to discard discardable blocks

------------------------------------------------------------------------------@

ThrowOutBlocks	proc	far

	; do {
scanLoop:

	;
	; Locate as many biffable blocks as we can using the current
	; disposal method.
	;
	call	PHeap

getMoreBlocks:
	push	ax		; (smaller to do this here than in FindNOldest,
				;  which has two exit points)
	call	FindNOldest			;returns count in cx
	pop	ax
	mov	bp, ds:[tobId]
	call	VHeap		; Give other threads a chance if we're scrubbing

	;
	; If none found that can be nuked with our current method, advance to
	; the next.
	;
	jcxz	methodExhausted

	;
	; Loop through the array of biffable blocks, throwing out each in turn
	; (they are ordered from most to least desirable) until we've made
	; enough room on the heap.
	;
	mov	si,offset tobTable	;start at first block
throwLoop:
	call	PHeap
	cmp	ds:[tobId], bp		;tobTable still unchanged?
	jne	getMoreBlocks		;nope -- go fill it again

	;
	; Fetch the next block to be nuked.
	;
	mov	bx,ds:[si].TOB_handle

	;
	; If the block has become locked in the interim, skip it. Else change
	; its address to 0 so no one can lock it.
	;
	INT_OFF				;change handle so it cannot be locked
	;
	; If the block has become freed, discarded or swapped in the interim,
	; skip it.  This could happen if ThrowOutOne/MemSwapOut fails and
	; starts discarding discarable blocks swapped to that device.  If such
	; a block is a VM block, we could go through this whole ThrowOutBlocks
	; shme again as we try to make room to bring in the VM header during
	; the VM block discard.
	;
		CheckHack <HM_lockCount eq HM_flags+1>
	test	{word}ds:[bx].HM_flags, \
			(mask HF_DISCARDED or mask HF_SWAPPED) or (0xff shl 8)
	jnz	innerLocked
	cmp	ds:[bx].HM_owner, 0
	je	innerLocked
	clr	dx
	xchg	dx,ds:[bx][HM_addr]
	INT_ON				;dx = block address

	;		    err = ThrowOutBlock(tempPtr);
	;		    if (err) {
	;			break
	;		    } else {
        ;			paraToThrowOut -= tempPtr.HM_size;
	;		    }
	;	    }   /* if unlocked */

	push	cx
	push	ax, ds:[bx].HM_size, bp	; record block size in case mangled by
					;  throw-out
	call	ThrowOutOne
	pop	ax, cx, bp
	mov	ds:[tobId], bp	; compensate for possible increment in
				;  DoFreeNoDeleteSwap, since the tobTable
				;  isn't outdated unless tobId is upped
				;  when we've not got the heapSem

	jc	error		; couldn't nuke
	sub	ax, cx		; record size nuked
	pop	cx		; recover loop count

	;	}   /* for count */
	; } while (paraToThrowOut > 0);
	jbe	found		; ax <= size means we've got enough
tryNext:
	call	VHeap
	add	si,size ThrowOutBlock	;move to next
	loop	throwLoop
	cmp	si, offset tobTable + size tobTable
	jne	methodExhausted		;table wasn't full => hit the end of
					; what this disposal method can do
	jmp	scanLoop		;else try for another set of blocks.

innerLocked:
	INT_ON
	jmp	tryNext

found:
	call	VHeap
	clc
	ret

error:
	pop	cx				; recover loop count
	mov	ds:[bx].HM_addr,dx
	jmp	tryNext				; just because one block
						;  couldn't make it doesn't
						;  mean we should give up.
						;  FindNOldest will decide if
						;  it's impossible to throw
						;  out anything else...

methodExhausted:
	add	di, size SwapDriver		; point to next swap driver
	cmp	di, ds:[swapNext]		; hit the end?
	jb	scanLoop			; => more drivers to check...
	jne	noMoreMethods			; => past dummy driver, even

	; invoke a dummy driver if no slow methods have yet been called;
	; this allows discardable blocks to be discarded in FindNOldest.
	;					mevissen, 3/99

	cmp	ds:[di-(size SwapDriver)].SD_speed, SS_PRETTY_FAST
	jbe	scanLoop			; try again with dummy driver

noMoreMethods:
	stc					; return error
	ret

ThrowOutBlocks	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ThrowOutOne

DESCRIPTION:	Throw out a block for ThrowOutBlocks

CALLED BY:	INTERNAL
		ThrowOutBlocks

PASS:
	bx - handle (with data address = 0)
	dx - data address
	ds - kernel data
	di - SwapDriver to use if swapping

RETURN:
	carry - set if error (dx must be preserved)
	bx, ds - same

DESTROYED:
	ax, cx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if (speed(curSwapDriver) >= PRETTY_FAST) {
		/* Always swap since device is so fast */
		error = MemSwapOut(tempPtr, addr, driver)
	} else if (tempPtr is VM block) {
		/* Give VM a crack at it first */
		error = VMUpdateAndRidBlk(tempPtr, addr)
		if (error) {
			/* VM couldn't nuke it, so try and swap it instead */
			error = MemSwapOut(tempPtr, addr, driver)
		}
	} else if (tempPtr is discardable) {
		error = DoDiscard(tempPtr)
	} else if (tempPtr is swapable) {
		error = MemSwapOut(tempPtr, addr, driver)
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@
ThrowOutOne	proc	near
EC <	call	AssertHeapMine						>
	mov	cx, LCT_ALWAYS_COMPACT
	call	ContractIfLMem		; Contract any LMem block that's
					;  being nuked

	mov	cl,ds:[bx].HM_flags
	;
	; If we're swapping to a pretty fast or really fast driver, always
	; swap w/o regard to the type of block being biffed (unless the
	; block is only discardable).
	;
	test	cl, mask HF_SWAPABLE
	jz	discard
	cmp	ds:[di].SD_speed, SS_PRETTY_FAST
	jbe	trySwap

	;
	; If the block is a VM data block, give it to the VM code to dispose
	; of. If it can't go away, try and swap it.
	;
	mov	bp, ds:[bx][HM_owner]		;get owner
	cmp	ds:[bp][HG_type], SIG_VM	;is owner a VM file handle?
	jne	notVM			;branch if not

	call	VMUpdateAndRidBlk
	jnc	done
	jmp	trySwap

notVM:
	;
	; If the block is discardable, we want to discard it. Call DoDiscard
	; to handle it.
	;
	test	cl,mask HF_DISCARDABLE
	jz	trySwap
discard:
	;
	; If DoDiscard is called on a VM block, the VMHeader does not
	; get properly updated and you can get a death due to VM_BAD_HDR.
	;
	; This can happen if a non-swapable heap block is attached
	; to a VM file, as when an extra state block created by an app
	; with the wrong heap flags is attached to the state file.
	;
	; DoFullDiscard will handle VM blocks correctly, so call it in
	; the EC version, but call DoDiscard in the non-ec, as it is
	; faster.   -cassie, 6/30/95
	; 		
	; Just call DoFullDiscard, so that the non-ec system won't crash 
	; if a VM block is incorrectly discarded.  -cassie, 7/05/95
	; 		
EC <	mov	bp, ds:[bx][HM_owner]		;get owner	>
EC <	cmp	ds:[bp][HG_type], SIG_VM			>
EC <	WARNING_E DISCARDING_VM_BLOCK_INCORRECTLY		>
	call	DoFullDiscard		

done:
	ret

trySwap:
EC<	test	cl, mask HF_SWAPABLE					>
EC<	ERROR_Z	GASP_CHOKE_WHEEZE					>
	call	MemSwapOut
	jmp	done

ThrowOutOne	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FindNOldest

DESCRIPTION:	Search the heap for the N oldest blocks that can be disposed
		of with the current swap driver.

CALLED BY:	INTERNAL
		ThrowOutBlocks

PASS:
	exclusive access to heap variables
	di - swap driver being used for this pass
		SS_REALLY_FAST, SS_PRETTY_FAST - prefer swapping over discarding
		anything else - prefer discarding over swapping.

	ds - idata segment

RETURN:
	cx - number of blocks found
	ds - same

DESTROYED:
	ax, bx, dx, si, bp

REGISTER/STACK USAGE:
	ax - tempPtr's flags and lock count
	bx - tempPtr
	cl - curSDSpeed
	ch - swapFlags
	dx - temp
	si - count*4
	di - lastBlock
	bp - temporary

PSEUDO CODE/STRATEGY:

	"Oldest" for a block x is figured by (high scores indicate old blocks):
		score = systemCounter.low-x.HM_usageValue
	
	hArray[0] = 0
	if (speed(curSwapDriver) >= PRETTY_FAST && curSwapDriver is full) {
		return(error)
	}
	tempPtr = last block on heap

	do begin
		if ((tempPtr.HM_owner != 0) && (tempPtr->lockCount == 0) {
			temp = systemCounter.low - tempPtr.HM_usageValue
			;
			; Prefer swapping to memory above all else -- we'll
			; do it until memory is full
			;
			if (swapSpeed >= pretty fast) {
			    if (tempPtr is not swapable) {
				break
			    }
			} else if (tempPtr is a VM block) {
			    if (VM can biff it) {
			        if (tempPtr is DISCARDABLE) {
				    ; weight high by leaving score alone
				} else {
			    	    ; make same weight as swapping
			    	    temp /= 2
				}
			    } else {
				; this is an unfortunate choice as updating
				; the file would involve reading the thing
				; from swap then writing it to disk
				temp /= 2
				try swapping
			    }
			} else if (tempPtr is DISCARDABLE) {
				; discarding is fastish -- weight it higher
				; by leaving the score alone
			} else if (tempPtr is SWAPABLE and can swap to disk) {
			    temp /= 2
			} else if (tempPtr is lmem and detachable) {
			    ; this is really slow so make it worse than swapping
			    temp /= 4
			} else {
			    break /* block is hopeless */
			}
			; put into hArray in proper order
			count = 0
			do begin
				if (hArray[count] = 0 or temp > sArray[count])
					shift array down
					hArray[count] = tempPtr
					sArray[count] = temp
				else
					count = TOB_ARRAY_SIZE
				endif
			end while (count < TOB_ARRAY_SIZE)
		}
		tempPtr = tempPtr.HM_prev
	end while (tempPtr != last block on heap)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Would like to add the size into the score here....

	When deciding if we should write a VM block to its file or swap it or
	discard it, we should take into account if the file is on a floppy.
	Use DiskIsFloppy to find out...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

FindNOldest	proc	near
EC <	call	AssertHeapMine						>
	; hArray[0] = 0
startAgain:
	clr	dx				;use dx as 0 throughout
	mov	ds:[tobTable].TOB_handle,dx	;zero first count
	inc	ds:[tobId]			;another time through the mill..

	;
	; If the current swap device is full and fast, return no blocks
	; nukable...(if device is slow, we might still find blocks to discard
	; or write to a VM file)
	;
	mov	cx, {word}ds:[di].SD_speed	; ch = SwapDriverFlags,
						; cl = SwapSpeed

	test	ch, mask SDF_ENDANGERED
	jnz	notPossible		; if endangered, then never possible
	
	test	ch, mask SDF_FULL
	jz	possible

	cmp	cl, SS_PRETTY_FAST
	ja	possible

notPossible:
	clr	cx
	ret

possible:

	;
	; set tempPtr (bx) to be the last block on the heap. this value is
	; saved in di so we know when to stop (can you imagine a heap of
	; 10 64K blocks? Yeah. right :)
	;
	; cl = SwapSpeed
	;
	call	GetLastBlock
	jc	notPossible
	push	es
	push	di
	mov	di,bx

scanLoop:
	;do begin
EC <	call	ECCheckHandleForWeirdness				>
	;
	; if block now free or locked, skip it
	;
	cmp	ds:[bx][HM_owner],dx	;check for free
	jz	next
	mov	ax, {word}ds:[bx][HM_flags]	; ah = lockCount, al = flags
	tst	ah			;check for locked
	jnz	next

	;
	; If hit a fixed block, there's nothing more that can be thrown out.
	;
	test	al, mask HF_FIXED
	jnz	atEnd

	;
	; Calculate the initial score by subtracting the usage value from the
	; low word of the system counter, giving a higher score for older
	; blocks.
	;

	; Scores work like this: the score starts at (time since last use)
	;
	; If the block can be discarded (and therefore will be by ThrowOutOne)
	; then we want to make is more likely to be thrown out by ADDING a
	; small ammount to its score since discarding is faster than swapping.
	; The constant is proportional to the expected extra time required
	; for swapping.

	mov	dx,ds:[systemCounter.low]
	sub	dx,ds:[bx][HM_usageValue]

	;
	; If swapping to fast driver and the block isn't swappable or
	; discardable, skip it,
	; else proclaim the block valid.
	;
	cmp	cl, SS_PRETTY_FAST
	ja	other

	; REALLY_FAST or PRETTY_FAST (EMS and XMS)

	test	al, mask HF_SWAPABLE or mask HF_DISCARDABLE
	jz	next
	jmp	valid

other:
	; Swapping to KINDA_SLOW or REALLY_SLOW (disk)
	;
	; See if the thing's a VM block that the VM code can write out.
	;
	mov	bp, ds:[bx][HM_owner]		;retrieve owner
	cmp	ds:[bp][HG_type], SIG_VM	;is owner a VM file handle?
	jne	notVM			;branch if not

	; its a VM block -- if it is DIRTY (and biffable) then add
	; NORMAL_SWAP_PENALTY to make it less like to get biffed

	push	ds:[tobId]
	call	VMBlockBiffable
	pop	bp
	pushf
	cmp	bp, ds:[tobId]
	jnz	toStartAgain
	popf
	jc	notDiscardable		; no -- DO NOT DO USUAL DISCARD CHECK
	test	ds:[bx].HM_flags, mask HF_DISCARDABLE
	jz	valid			;if dirty then the block cannot be
					;discarded so the score remains as-is
addPenalty:
	add	dx, NORMAL_SWAP_PENALTY	; CLEAN and biffable
	jnc	valid
	mov	dx, 0xffff		; catch wrap around
	jmp	valid

toStartAgain:
	popf
	pop	di
	pop	es
	jmp	startAgain

notVM:
	;
	; If block is discardable then add in the penalty as described above
	;
	test	al, mask HF_DISCARDABLE
	jnz	addPenalty
notDiscardable:
	;
	; if block is swappable and we can swap to disk, do so
	;
	test	al,mask HF_SWAPABLE
	jz	next
	test	ch, mask SDF_FULL
	jnz	next
	jmp	valid

	;-----------------
	; little piece of table-traversal code here to avoid out-of-range jumps
	; and allow fall-through to "next", given we need to jump someplace
	; at the end of the loop, but next can't be too far down or we
	; won't reach.
innerNext:
	add	si,4
	cmp	si, offset tobTable + size tobTable
	jnz	innerLoop

next:
	;
	; Advance tempPtr to next-oldest block (tempPtr.HM_prev)
	;

	clr	dx			;set dx=0 for scanLoop
	mov	bx,ds:[bx][HM_prev]
	cmp	bx,di
	jnz	scanLoop
atEnd:
	; find out how many handles

	mov	cx, TOB_ARRAY_SIZE
	mov	si, offset tobTable - size ThrowOutBlock
countLoop:
	add	si,size ThrowOutBlock
	tst	ds:[si].TOB_handle
	loopnz	countLoop
	jnz	done
	inc	cx
done:
	sub	cx, TOB_ARRAY_SIZE
	neg	cx			
	pop	di
	pop	es
	ret

valid:
	;
	; We think we can biff this here block. It's relative biff-rating
	; is in dx. Find the proper place for it in the array.
	;

	mov	si,offset tobTable	;init count
innerLoop:
	tst	ds:[si].TOB_handle	;hit first empty slot in table?
	jz	replace
	cmp	dx,ds:[si].TOB_score	;compare score
	jbe	innerNext		; advance to next slot and fall into
					; "next" (skipping this block) if all
					; current blocks are more biffable.
replace:
	mov	bp,si			;save current position for loop end
	;
	; Shift all following blocks up in the array. This propagates the
	; initial 0 handle up to the end if there aren't enough blocks
	; to be nuked...Of course, we have to start with the last and work
	; down.
	;
	mov	si, offset tobTable + size tobTable - size ThrowOutBlock
replaceLoop:
	mov	ax,ds:[si-size ThrowOutBlock].TOB_handle
	mov	ds:[si].TOB_handle,ax
	mov	ax,ds:[si-size ThrowOutBlock].TOB_score
	mov	ds:[si].TOB_score,ax
	sub	si,size ThrowOutBlock
	cmp	si,bp
	ja	replaceLoop

	;
	; Store new block and advance to next oldest.
	;
	mov	ds:[si].TOB_handle,bx
	mov	ds:[si].TOB_score,dx
	jmp 	short next


FindNOldest	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetLastBlock

DESCRIPTION:	Load the handle of the highest block on the heap

CALLED BY:	INTERNAL
		FindNOldest, CompactHeap

PASS:
	ds - kernel data segment

RETURN:
	bx - handle to last block on heap
	carry - set if heap is empty

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

GetLastBlock	proc	near
NOAXIP<	mov	bx, ds:[loaderVars].KLV_handleBottomBlock		>
AXIP<	mov	bx, ds:[xipHandleTopBlock]				>
	mov	ax, ds:[bx].HM_prev
	cmp	ax, bx			;check for heap empty
	stc
	jz	10$
	clc
10$:
	mov	bx, ax
	ret

GetLastBlock	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FlushGstateCache

DESCRIPTION:	Flush the GState cache to generate free memory

CALLED BY:	INTERNAL
		FindFree

PASS:
	exclusive access to heap
	ds - kernel variables

RETURN:
	none

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	See GrCreate

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

-------------------------------------------------------------------------------@

FlushGstateCache	proc	near
FGC_loop:

	; remove GState from cache

	INT_OFF
	mov	bx, ds:[GStateCachePtr]		;get first cached GState
	tst	bx
	jz	done				;if null then done
	mov	ax,ds:[bx].HM_otherInfo		;get next GState, set it as
	mov	ds:[GStateCachePtr],ax		;first in list
	INT_ON

	call	DoFree				;free the GState

	jmp	short FGC_loop

done:
	INT_ON
	ret

FlushGstateCache	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ContractIfLMem

DESCRIPTION:	Contract a block if it's an LMem block. This is done just
		before moving it in CompactHeap, discarding it, or
		swapping it out.

CALLED BY:	INTERNAL
		CompactHeap
		ThrowOutOne
PASS:
	exclusive access to heap
	ds - kernel variables
	bx - block to contract, if lmem
	dx - data address of block
	cl - compaction threshhold LMemCompactionThreshhold

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:
		INT_OFF
		if ((tempPtr is unlocked) and (tempPtr is an lmem block) {
			ContractBlock(tempPtr);
		INT_ON

PSEUDO CODE/STRATEGY:
	See LMem documentation.

	We dont want to compact discardable lmem blocks, because
	if they are discarded and then reloaded, then HM_size might not
	match the internal state of the LMem block.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

-------------------------------------------------------------------------------@

ContractIfLMem	proc	near	uses cx, si, di
	.enter

	;	INT_OFF
	;	if ((tempPtr is unlocked) and (tempPtr is an lmem block) and
	;	     (tempPtr is not discardable)) {
	;		save HM_addr for tempPtr, set HM_addr to 0

	INT_OFF
	mov	ax,{word}ds:[bx][HM_flags]	;al - flags, ah = lock
	test	al, mask HF_LMEM
	jz	done
	test	ax, (0xff shl 8) or mask HF_DISCARDABLE
	jnz	done

	;		ContractBlock(tempPtr);

	;
	; The code used to turn interrupts on at done:, causing ContractNoNotify
	; to be called with interrupts off.  This is an exceedingly bad thing
	; since ContractNoNotify calls LMemCompcatHeap which can take eons to
	; complete.
	;
	INT_ON
	call	ContractNoNotify
done:
	INT_ON
	.leave
	ret
ContractIfLMem	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ContractBlock

DESCRIPTION:	Contract an lmem block

CALLED BY:	INTERNAL
		ContractLMem, DoLMemDiscard, DetachObjBlock

PASS:
	exclusive access to heap
	bx - handle of block to contract (HM_addr = 0)
	dx - data address
	ds - kernel data

RETURN:
	interrupts on
	[bx].HM_addr set to dx

DESTROYED:
	ax, cx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	compact the block's heap
	biff all free space at the end, giving it to a free block.
	restore data address

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

ContractBlock	proc	far
	mov	cx, LCT_ALWAYS_COMPACT
	call	ContractNoNotify
	mov	ds:[bx][HM_addr],dx
	jnc	noNotify
	mov	al, DEBUG_REALLOC		;notify debugger of block
	call	FarDebugMemory			; shrinkage
noNotify:
	ret					;
ContractBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContractNoNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Contract an lmem block, nuking any free space in the block,
		without notifying the debugger of the change.

CALLED BY:	ContractBlock, MoveBlock
PASS:		exclusive access to heap
		bx	= handle of block to contract (HM_addr = 0)
		cl	= compaction threshhold LMemCompactionThreshhold
		dx	= data address
		ds	= idata
RETURN:		interrupts on
		carry set if the block actually changed size.
DESTROYED:	ax, cx, si, di


PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContractNoNotify proc	near
	.enter
	mov	di, ds				; preserve kdata

	mov	ax, ds:[bx][HM_size]		;
	mov	ds, dx
	test	ds:[LMBH_flags], mask LMF_NO_ENLARGE
	jnz	done

;
;	If EC_FORCE_MOVE is set, then there is the possibility that when
;	an LMem block is being force-moved, the original copy of the block
;	is compacted. This results in the size as stored in the handle of
;	the block to not match LMBH_blockSize.
;
;	So, if we are asked to compact the block currently being force moved,
;	just exit
;

EC <	push	es, ax							>
EC <	mov	es, di							>
EC <	mov	ax, ds:[LMBH_handle]					>
EC <	cmp	ax, es:[handleBeingForceMoved]				>
EC <	pop	es, ax							>
EC <	jz	done							>

	call	LMemCompactHeap			;shrink the heap.
	jc	done
						;
	mov	cx, ds:LMBH_blockSize		;figure size used
EC <	test	cx, 1							>
EC <	ERROR_NZ ODD_LMEM_BLOCK_SIZE					>
	sub	cx, ds:LMBH_totalFree
EC <	ERROR_B	GASP_CHOKE_WHEEZE					>
EC <	test 	cx, 1							>
EC <	ERROR_NZ ODD_LMEM_TOTAL_FREE_SIZE				>
	mov	ds:LMBH_blockSize, cx		;set new size to size used.
	mov	ds:LMBH_totalFree, 0		;no more free space.
	mov	ds:LMBH_freeList, 0		;and no free list.
						;
	;
	; compare new and old sizes and see if we can shrink the block at all.
	;
	mov	si, cx				;si <- new total size.
	mov	ds, di				; restore kdata
	add	si, 15				;si = min para size
	mov	cl, 4				;
	shr	si, cl				;
	cmp	ax, si				;can it be made smaller ?
EC <	ERROR_B	CORRUPTED_HEAP			;new block can't be bigger>
	jz	done				;

	xchg	ax, si				;ax = new size (1-byte inst)
						;si = old size
	mov	cl, mask HF_FIXED		;leave the low part in-use

	push	si				;preserve old size

CNN_LMemBlockContract label near		; needed for "showcalls -l"
	ForceRef	CNN_LMemBlockContract

	call	SplitBlockFreeRemainder

	;
	; do some VM File stuff..  for monitoring the dirty size
	;
	; first, check if we are dealing with a block in a vm file
	;
	pop	cx				; restore old size
	mov	si, ds:[bx].HM_owner
	cmp	ds:[si].HVM_signature, SIG_VM
	jne	setDone
	;
	; has it been marked dirty before?  if not yet, this will be
	; taken care of later
	;
	test	ds:[bx].HM_flags, mask HF_DISCARDABLE
	jnz	setDone
	;
	; ok, now find the amount of new dirty size..  since the block
	; is shrinking, this will positive
	;
	sub	cx, ds:[bx].HM_size		; old size - new size
	;
	; Just do it (TM)
	;
	INT_OFF
	tst	ds:[si].HVM_relocRoutine.segment
	jnz	setDone
	;
	; very quickly check if the dirtly size has gone negative..
	; time is important with interrupts off
	test	{byte}ds:[si].HVM_relocRoutine.offset.high, 0x80

	jnz	setDone
	add	ds:[si].HVM_relocRoutine.offset, cx

setDone:
	stc
done:						
	INT_ON	
	mov	ds, di				; restore kdata
	.leave
	Destroy	ax, cx, si, di
	ret
ContractNoNotify endp

ifdef PRODUCT_GEOS32
include gpmi.def

; Pass
;   bx:cx = size of block to allocate in bytes
; Return
;   bx = selector (if carry clear)
GPMIAllocateBlock  proc    near
                push    es
		push	si
                les     si, ds:[loaderVars].KLV_GPMIVectorTable
                call    {fptr}es:[si+GPMI_CALL_ALLOCATE_BLOCK]
		pop	si
                pop     es
                ret
GPMIAllocateBlock       endp

GPMIAlias       proc    near
                push    es
		push	si
                les     si, ds:[loaderVars].KLV_GPMIVectorTable
                call    {fptr}es:[si+GPMI_CALL_ALIAS]
		pop	si
                pop     es
                ret
GPMIAlias       endp

GPMIFreeAlias       proc    near
                push    es
		push	si
                les     si, ds:[loaderVars].KLV_GPMIVectorTable
                call    {fptr}es:[si+GPMI_CALL_FREE_ALIAS]
		pop	si
                pop     es
                ret
GPMIFreeAlias       endp

GPMIAccessRealSegment       proc    near
                push    es
		push	si
                les     si, ds:[loaderVars].KLV_GPMIVectorTable
                call    {fptr}es:[si+GPMI_CALL_ACCESS_REAL_SEGMENT]
		pop	si
                pop     es
                ret
GPMIAccessRealSegment       endp

if 0
GPMIResizeBlock	proc near
                push    es
		push	si
                les     si, ds:[loaderVars].KLV_GPMIVectorTable
                call    {fptr}es:[si+GPMI_CALL_RESIZE_BLOCK]
		pop	si
                pop     es
                ret
GPMIResizeBlock	endp
endif

GPMIGetInterruptHandler	proc near
                push    es
		push	si
                les     si, ds:[loaderVars].KLV_GPMIVectorTable
                call    {fptr}es:[si+GPMI_CALL_GET_INTERRUPT_HANDLER]
		pop	si
                pop     es
                ret
GPMIGetInterruptHandler	endp

GPMISetInterruptHandler	proc near
                push    es
		push	si
                les     si, ds:[loaderVars].KLV_GPMIVectorTable
                call    {fptr}es:[si+GPMI_CALL_SET_INTERRUPT_HANDLER]
		pop	si
                pop     es
                ret
GPMISetInterruptHandler	endp

GPMIReleaseSegmentAccess	proc near
                push    es
		push	si
                les     si, ds:[loaderVars].KLV_GPMIVectorTable
                call    {fptr}es:[si+GPMI_CALL_RELEASE_SEGMENT_ACCESS]
		pop	si
                pop     es
                ret
GPMIReleaseSegmentAccess	endp

GPMIIsSelector16Bit     proc near
                push    es
		push	si
                les     si, ds:[loaderVars].KLV_GPMIVectorTable
                call    {fptr}es:[si+GPMI_CALL_IS_SELECTOR_16_BIT]
		pop	si
                pop     es
                ret
GPMIIsSelector16Bit     endp

GPMISelectorCheckLimits proc near
                push    es
		push	si
                les     si, ds:[loaderVars].KLV_GPMIVectorTable
                call    {fptr}es:[si+GPMI_CALL_SELECTOR_CHECK_LIMITS]
		pop	si
                pop     es
                ret
GPMISelectorCheckLimits endp
endif
