COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		heapLow (heap low level routines)

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------
   INT	EnterHeap		Generic code to start working with heap
   INT	ExitHeap		Generic code to finish working with heap
   INT	DoAlloc			Allocate memory for a given handle
   EXT	DoReAlloc		Reallocate the given block (internal routine)
   INT	AllocHandleAndBytes	Allocate a handle and bytes for it
   EXT	DoFree			Free the given block (internal routine)
   EXT	RemoveSwapFiles		Remove all swap files from the swap disk
   INT	MemAllocLow		Allocate a memory block for MemAlloc and others


	(Error checking version)
   EXT	ECCheckMemHandle	Check to make sure a handle is legal, cause an
				appropriate fatal error if not
   INT	CheckLocked		Check to make sure a handle is unlocked, cause
				an appropriate fatal error if not
   INT	CheckFixed		Check to make sure a handle is not fixed, cause
				an appropriate fatal error if not

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	6/88		Added MemOwn, MemRelease
				Added "Mem" naming convention
	Tony	10/88		Comments from Jim's code review added
	Tony	10/88		Changed MemOwn, MemRelease to HandleP, HandleV,
				added MemThreadGrab, MemThreadRelease

DESCRIPTION:
	This file contains the simple heap routines, those that do no
allocation.  For a description of the heap, see manager.asm

     	$Id: heapLow.asm,v 1.1 97/04/05 01:14:06 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckFreeHandles

DESCRIPTION:	Check the number of free handles and compact the heap to 
		attempt to get more if not enough around (the hope is that
		block coalescing will cause handles to be freed up).

CALLED BY:	INTERNAL
		MemAlloc, MemReAlloc

PASS:
	ch - allocation flags

RETURN:
	carry set to return error

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

-------------------------------------------------------------------------------@

CheckFreeHandles	proc	near
	cmp	ds:[loaderVars].KLV_handleFreeCount, MIN_FREE_HANDLES
	jnc	done			;if enough handles, exit OK
	test	ch, mask HAF_NO_ERR
	stc
	jz	done

	;
	; If we're low on handles, compact the heap in an attempt to gain some
	; more by means of coalescing blocks.
	; 
	call	PushAll
	mov	cl, TRUE
	call	CompactHeap
	call	PopAll

	clc
done:
	ret

CheckFreeHandles	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FullLockNoReload

DESCRIPTION:	Lock a block when HM_addr is 0.

CALLED BY:	INTERNAL
		MemLock, FAST_LOCK macro

PASS:
	ds - kernel data
	bx - handle to block of memory to lock

RETURN:
	carry - set on error (block is discarded)
	ax - segment address of block of memory

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	It is very important that this routine be fast when the block is
	in memory.  Therefore that case is tested for first.

	if (not discarded and not swapped)
		increment lock count
		return data address
	endif

	if (block is discarded)
		return error
	endif

	Swap in the block, jump to start of routine to lock it

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Lock counts of more than 255 are not handled well.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

-------------------------------------------------------------------------------@


FarFullLockNoReload	proc	far
	call	FullLockNoReload
	ret
FarFullLockNoReload	endp

FullLockNoReload	proc	near
	call	PHeap				;get semaphore for special case
EC <	call	CheckHeapHandleSW					>
	mov	ax,ds:[bx][HM_addr]		;get address
	or	ax,ax				;test for not in memory
	jnz	doneComp

	test	ds:[bx][HM_flags],mask HF_DISCARDED
	stc
	jnz	doneDisc	;if block is discarded, exit with carry set

	; block is swapped, swap it back in

	call	PushAll

	mov	di, 300
	call	ThreadBorrowStackSpace
	push	di

;	The call to ThreadBorrowStackSpace may have made the block be discarded
;	so check it here...

	test	ds:[bx][HM_flags],mask HF_DISCARDED
	stc
	jnz	noSwapIn	;if block is discarded, exit with carry set

	call	MemSwapIn	;Will return carry clear

EC <	ERROR_C	-1							>

	; Check if the block went from swapped to discarded.
	test	ds:[bx][HM_flags],mask HF_DISCARDED
	stc
	jnz	noSwapIn
	clc

noSwapIn:

	pop	di
	call	ThreadReturnStackSpace

	call	PopAll
	jc	doneDisc			;Exit if the block is discarded
	mov	ax,ds:[bx][HM_addr]
NEC <	tst	ax							>
NEC <	ERROR_Z	-1							>

doneComp:
EC <	call	CheckToLockNS						>
	inc	ds:[bx][HM_lockCount]		;lock block
NEC <	ERROR_Z -1							>
	clc					;return no error
doneDisc:
EC <	call	CheckHeapHandleSW					>
	GOTO	VHeap

FullLockNoReload	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FullLockReload

DESCRIPTION:	Lock a block when HM_addr is 0.  if the block is discarded
		reallocate it and use the given function to re-load it.

CALLED BY:	INTERNAL
		MemLock, FAST_LOCK macro

PASS:
	bx - handle to block of memory to lock
	dx - address of call-back routine to re-load memory after it
	di - data to pass to call-back routine

RETURN:
	ax - segment address of block of memory

DESTROYED:
	dx

	Call back routine:
	PASS:
		bx - handle passed (HM_addr NOT valid)
		si - temporary handle (HM_addr valid, HM_otherInfo NOT valid)
		ds - idata
	RETURN:
		none
	DESTROYED:
		ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	It is very important that this routine be fast when the block is
	in memory.  Therefore that case is tested for first.

	if (not discarded and not swapped)
		increment lock count
		return data address
	endif

	if (block is discarded)
		return error
	endif

	Swap in the block, jump to start of routine to lock it

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Lock counts of more than 255 are not handled well.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

-------------------------------------------------------------------------------@

FullLockReload	proc	near
	call	PHeap				;get semaphore for special case
	push	ss:[TPD_callVector].offset	;needed for module calling
						;routines
EC <	call	CheckHeapHandleSW					>
	mov	ax,ds:[bx][HM_addr]		;get address
	tst	ax				;test for not in memory
	jnz	doneComp

	push	cx, si, di

	mov	cx, di
	mov	di, 300
	call	ThreadBorrowStackSpace
	push	di
	mov	di, cx

	mov	ch,HAF_STANDARD_NO_ERR
	call	DoReAlloc

	pop	di
	call	ThreadReturnStackSpace

	pop	cx, si, di
	mov	ax,ds:[bx][HM_addr]

doneComp:
EC <	call	CheckToLockNS						>
	inc	ds:[bx][HM_lockCount]		;lock block
NEC <	ERROR_Z -1							>
EC <	call	CheckHeapHandleSW					>
	pop	ss:[TPD_callVector].offset

if	ANALYZE_WORKING_SET
	call	WorkingSetResourceLoaded
endif

	GOTO	VHeap

FullLockReload	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	EnterHeap, ExitHeap

DESCRIPTION:	Do generic stuff to start/finish working with heap

CALLED BY:	INTERNAL
		MemAlloc, MemReAlloc, MemFree, MemDiscard,

PASS:
	none

RETURN:
	old ds, di, si ,bp - saved
	ds - kernel segment
	Exclusive access set for heap code

DESTROYED:
	EnterHeap - dx
	ExitHeap - none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	EnterHeap:
		push	ds
		push	di
		push	bp
		push	si

		call	PHeap
		LoadVarSeg	ds

	ExitHeap:
		pop	si
		call	VHeap
		pop	bp
		pop	di
		pop	ds
		ret

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	The caller MUST push dx BEFORE calling this routine!
	The caller MUST jmp to ExitHeap without popping dx!
	This routine messes with the stack!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

ExitHeap	proc	far
	pop	si
	call	VHeap
	pop	bp
	pop	di
	pop	ds
	pop	dx
EC <	call	NullSegmentRegisters					>
	ret
ExitHeap	endp


EnterHeap	proc	near
EC <	call	FarCheckDS_ES						>
	pop	dx

	push	ds
	push	di
	push	bp
	push	si

	push	dx

	LoadVarSeg	ds
	GOTO	PHeap

EnterHeap	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemAllocLow

DESCRIPTION:
	Allocate the given number of bytes on the heap.  This block can be:
		Discardable or non-discardable
		Swapable or non-swapable
		AllocLowated fixed or movable blocks
		Initialized to zero or not
	A passed flag determines whether heap compaction or discarding
	of objects should be used to generate the free space.

CALLED BY:	EXTERNAL (MemAlloc, MemAllocSetOwner)

PASS:
	ax - size (in bytes) to allocate
	bx - owner to set for block
	cl - flags for block type: HeapFlags record
	ch - flags for allocation method: HeapAllocLowFlags record

RETURN:
	bx - handle to block allocated
	ax - address of block allocated (if block is fixed)
	carry - set if error (not enough memory)

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Set the appropriate registers and call AllocLowHandleAndBytes to do
	the work.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

MemAllocLow	proc	near
	uses	ds,di,bp,si,dx
	.enter
	InsertGenericProfileEntry PET_HEAP, 1, PMF_HEAP, ax
	LoadVarSeg	ds

	; error checking
EC <	tst	ax							>
EC <	ERROR_Z	ALLOC_ZERO						>
EC <	cmp	ax,0fff0h						>
EC <	ERROR_A	ALLOC_TOO_LARGE						>
EC <	test	cl,mask HF_FIXED					>
EC <	jz	MAL_30							>
EC <	test	cx,mask HF_DISCARDABLE or mask HF_SWAPABLE or \
   			mask HF_DISCARDED or \
			(mask HAF_LOCK shl 8)>
EC <	jz	MAL_30							>
EC <err:								>
EC <	ERROR	ALLOC_BAD_FLAGS						>
EC <MAL_30:								>
EC <	test	cl,mask HF_SWAPPED					>
EC <	jnz	err							>

;	It is OK for the kernel to allocate non-swappable and non-discardable
;	blocks (like the font block) but pretty much everyone else is
;	not allowed to...

EC <	cmp	bx, handle 0						>
EC <	jz	noWarn							>
EC <	test	cl, mask HF_FIXED or mask HF_DISCARDABLE or mask HF_SWAPABLE >
EC <	WARNING_Z BLOCK_ALLOCATED_WITH_NO_FLAGS				>
EC <noWarn:								>

;	BX must either be:
;
;	FONT_MAN_ID
;	a HandleVM (in which case kdata:[bx].HG_type = SIG_VM
;	a geode handle

EC <	cmp	bx, FONT_MAN_ID						>
EC <	jz	validOwner						>
EC <	cmp	ds:[bx].HG_type, SIG_VM					>
EC <	jz	validOwner						>
EC <	call	ECCheckGeodeHandle					>
EC <validOwner:								>

	call	CheckFreeHandles
	jc	error			;if not enough handles, exit with error

	push	cx
	add	ax,15			;convert bytes to paragraphs
	mov	cl,4			;allocate extra if needed
	shr	ax,cl
	pop	cx

	test	cl,mask HF_DISCARDED	;test for allocate discarded
	jz	alloc

				;Can't allocate discarded *and* locked

EC <	test	ch, mask HAF_LOCK					>
EC <	ERROR_NZ ALLOC_BAD_FLAGS					>

	push	ax			;allocate discarded -- get a handle
	call	AllocateMemHandle
	pop	ds:[bx][HM_size]	;set size
	jmp	done
alloc:
	call	AllocHandleAndBytes	;allocate a handle and bytes for it
	jc	error			;if error then don't try to lock it

	mov	ax,ds:[bx][HM_addr]
	test	ch,mask HAF_LOCK	;check for lock also
	jz	done
	test	ds:[bx][HM_flags],mask HF_FIXED
	jnz	done
	inc	ds:[bx][HM_lockCount]
done:

;	Return AX=NULL_SEGMENT if the block isn't fixed or locked

EC <	test	ds:[bx][HM_flags],mask HF_FIXED				>
EC <	jnz	noNullSeg						>
EC <	tst	ds:[bx][HM_lockCount]					>
EC <	jnz	noNullSeg						>
EC <	mov	ax, NULL_SEGMENT					>
EC <noNullSeg:								>

EC <	call	CheckHeapHandleSW					>
error:
	InsertGenericProfileEntry PET_HEAP, 0, PMF_HEAP, ax
	.leave
	ret
MemAllocLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyAllocError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the user that we couldn't allocate memory and see
		what s/he wants us to do.

CALLED BY:	AllocHandleAndBytes, DoReAlloc
PASS:		ds	= kdata
		heap lock grabbed
RETURN:		only if should retry
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyAllocError proc	near
	call	PushAll
	call	VHeap				;give up the heap semaphore

if 0	; Can cause deadlock in ThreadProcess and no one actually handles
	; this event...
	mov	ax,MSG_PROCESS_MEM_FULL
	call	ObjProcBroadcastMessage
endif

ifdef	GPC
	mov	al, KS_TE_SYSTEM_ERROR
	call	AddStringAtMessageBufferFar
	mov	al, KS_MEMORY_FULL
	call	AddStringAtESDIFar
	mov	si, offset messageBuffer	; ds:si <- first string
	clr	di
	mov	ax, mask SNF_REBOOT		; unrecoverable - reboot
else
	mov	ds, ds:[fixedStringsSegment]
	mov	si, ds:[memFull1]
	mov	di, ds:[memFull2]
	mov	ax,mask SNF_RETRY or mask SNF_EXIT
endif
	call	SysNotify
ifndef	GPC					; never happens on GPC
	test	ax, mask SNF_EXIT

	jnz	fieldEvents			; EXIT -- get out now
	call	PHeap				;get back the heap semaphore
	call	PopAll
	ret

fieldEvents:
	;
	; SNF_EXIT chosen -- field events until we die...
	; 1/26/93: change of plans. Just perform a dirty shutdown at this
	; point. -- ardeb
	;
	mov	si, -1
	mov	ax, SST_DIRTY
	call	SysShutdown
endif
	.UNREACHED
NotifyAllocError		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocationFailure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle allocation failure

CALLED BY:	AllocHandleAndBytes, MemSwapIn
PASS:		dx - number of retries remaining
RETURN:		dx - one less retry or full number of retries if we ran
			out of retries, put up the SysNotify and the user
			selected "Retry"
		if no more retries and user selects "Exit", doesn't return
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocationFailure	proc	near
	dec	dx
	jz	error

	; if heap sem grabbed more than once, there is absolutely no point in
	; releasing the heap sem (which won't actually release it fully) and
	; sleeping -- nothing will be able to do squat b/c we'll still hold
	; the heapSem -- ardeb 5/11/94
	;
	; never mind...someone could unlock a block while we're asleep and that
	; would give us the ability to discard or write out or just move the
	; sucker... -- ardeb 5/11/94

	call	VHeap
	WARNING	GLOBAL_HEAP_IS_CONGESTED_SO_THREAD_IS_SLEEPING
	push	ax
	mov	ax, ALLOCATION_RETRY_WAIT_TIME
	call	TimerSleep
	pop	ax
	call	PHeap
	ret

error:
	call	NotifyAllocError	; returns only on "Retry"
	mov	dx, NUMBER_OF_ALLOCATION_RETRIES + 1
	ret
AllocationFailure	endp


ifdef PRODUCT_GEOS32
COMMENT @-----------------------------------------------------------------------

FUNCTION:	AllocHandleAndBytes

DESCRIPTION:	Allocate a handle and allocate a given number of paragraphs
		for it.

CALLED BY:	INTERNAL
		MemAlloc, DoReAlloc, SwapInMemBlock, SwapInDiskBlock

PASS:
	exclusive access to heap variables
	ax - size (in paragraphs) to allocate
	bx - owner for new memory
	cl - flags for block type: HeapFlags record
	ch - flags for allocation method: HeapAllocFlags record
	ds - kernel data segment

RETURN:
	bx - handle to block allocated
	carry - set if error (not enough memory)

DESTROYED:
	ax, cl, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	allocate a handle for the block first, since allocating the handle
	could involve modifying the heap.

	newHandle = AllocateHandle()
	#para = #bytes / 16
	AllocBlock(#para, flags, handle)
	if (AllocBlock failed)
		FreeHandle(newHandle)
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

AllocHandleAndBytes	proc	near
EC <	call	AssertHeapMine						>
EC <    call    AssertFreeBlocksCC                                      >

	push	ax			;save size
	call	AllocateMemHandle	;make us a handle, returned in bx
	pop	ax


	push	bx			;save handle passed

	mov	dx, NUMBER_OF_ALLOCATION_RETRIES + 1
retry:
        push    ax, bx, cx
        clr     bx
        mov     cx, ax
        shld    bx, cx, 4
        shl     cx, 4
        call    GPMIAllocateBlock
        mov     si, bx
        pop     ax, bx, cx
	jnc	found			;if found then continue

	; if not found then loop, sleeping between tries
	; we only want to loop if HAF_NO_ERR was passed
	test	ch, mask HAF_NO_ERR
	jz	returnError

; !!!TBD - Currently the only good this does is try more times and let
; other threads free memory.  We won't have a scrubber thread going for
; now.
	call	AllocationFailure	; dec retries and sleep

	; recover initial setting of HF_FIXED
	pop	bx
	push	bx
	mov	cl, ds:[bx].HM_flags
	jmp	retry			; retry

found:
        pop     bx
        ; ax = size
        ; bx = handle to new memory
        ; dx = num retries
        ; si = allocated block addr

        ; Set the block's address and size
        mov     ds:[bx].HM_addr, si
        mov     ds:[bx].HM_size, ax

        ; Link in the block to the heap list
        mov     di, ds:[loaderVars].KLV_handleBottomBlock
        mov     si, ds:[di].HM_prev
        mov     ds:[bx].HM_prev, di
        mov     ds:[bx].HM_next, si
        mov     ds:[di].HM_next, bx
        mov     ds:[si].HM_prev, bx

        ; Do we need to zero out the memory?
	test	ch, mask HAF_ZERO_INIT
	jz	noZeroInit

	push	cx			; preserve ch...
	call	DoZeroInit		;if HAF_ZERO_INIT passed, do it
	pop	cx
noZeroInit:
	clc
	ret

returnError:
	pop	bx
	call	FreeHandle		;error -- free handle
	stc
	ret
AllocHandleAndBytes	endp
else            ; now not PRODUcT_GEOS32
COMMENT @-----------------------------------------------------------------------

FUNCTION:	AllocHandleAndBytes

DESCRIPTION:	Allocate a handle and allocate a given number of paragraphs
		for it.

CALLED BY:	INTERNAL
		MemAlloc, DoReAlloc, SwapInMemBlock, SwapInDiskBlock

PASS:
	exclusive access to heap variables
	ax - size (in paragraphs) to allocate
	bx - owner for new memory
	cl - flags for block type: HeapFlags record
	ch - flags for allocation method: HeapAllocFlags record
	ds - kernel data segment

RETURN:
	bx - handle to block allocated
	carry - set if error (not enough memory)

DESTROYED:
	ax, cl, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	allocate a handle for the block first, since allocating the handle
	could involve modifying the heap.

	newHandle = AllocateHandle()
	#para = #bytes / 16
	AllocBlock(#para, flags, handle)
	if (AllocBlock failed)
		FreeHandle(newHandle)
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

AllocHandleAndBytes	proc	near
EC <	call	AssertHeapMine						>
EC <    call    AssertFreeBlocksCC                                      >

	push	ax			;save size
	call	AllocateMemHandle	;make us a handle, returned in bx
	pop	ax


	push	bx			;save handle passed

	mov	dx, NUMBER_OF_ALLOCATION_RETRIES + 1
retry:
	call	FindFree		;allocate some memory
	jnc	found			;if found then continue

	; If we are trying to allocate a fixed block, we are probably failing
	; because there is a locked block just above the fixed blocks, resulting
	; in a very small border block.
	; Instead of dying, we can allocate a movable, locked block.  This is
	; not exactly healthy for the heap, but beats the alternative.
	;
	; If we are trying to allocate a movable block, we are failing because
	; it can't make enought room above the top fixed block.  Instead of
	; dying, we try again by searching beyond the top fixed block and see
	; if there is any room.  This effectively moves the fixed/movable heap
	; boundary downward and forces more subsequent fixed block allocations
	; to be allocated as pseudo-fixed.  This is not exactly healthy for
	; the heap, but beats the alternative.

	test	cl, mask HF_DEBUG
	jnz	notFound		;=> already tried desperate method

	xornf	cl, mask HF_FIXED or mask HF_DEBUG	;flip HF_FIXED and set
							; HF_DEBUG
	jmp	retry
notFound:

	; if not found then loop, sleeping between tries
	; we only want to loop if HAF_NO_ERR was passed

	test	ch, mask HAF_NO_ERR
	jz	returnError

	call	AllocationFailure	; dec retries and sleep

	; recover initial setting of HF_FIXED

	pop	bx
	push	bx
	mov	cl, ds:[bx].HM_flags
	jmp	retry			; retry

found:
	;
	; Need to decide how we want to split the free block.
	; - normal fixed block: leave bottom allocated
	; - normal movable block: leave top allocated
	; - pseudo-fixed block: leave top allocated
	; - movable block, desperate method: it was probably found in fixed
	;   heap, but we are not sure.  It may also be in movable heap.  (This
	;   can happen if ThrowOutBlocks couldn't throw out at least
	;   MIN_SPACE_TO_THROW_OUT during the first trial, but has already
	;   thrown out enough blocks which, combined with the original
	;   adjacent free space, make enough room for the block being
	;   allocated.  In this case, the free block would be found in movable
	;   heap during the second trial.)  So, we need to check in which heap
	;   it is allocated, and decide which part to keep accordingly.  If
	;   HF_FIXED is clear for the block above, that block above is either
	;   a movable block or a fake block in the movable heap.  Either way,
	;   we take our free block as in the movable heap, and leave the top
	;   allocated.  (If the free block happens to be the boundary block,
	;   we still treat it the same way and leave the top allocated.)

	push	cx			;save HeapFlags in cl
	test	cl, mask HF_DEBUG
	jz	split			;=> normal method
	test	cl, mask HF_FIXED
	jz	split			;=> HF_DEBUG w/o HF_FIXED, pseudo-fixed

	mov	si, ds:[bx].HM_next	;^hsi = block above
	cmp	si, ds:[loaderVars].KLV_handleBottomBlock   ;check if the free
							    ; block is the
							    ; topmost block
	je	keepTop			;=> yes, leave top allocated
	test	ds:[si].HM_flags, mask HF_FIXED
	jnz	split			;=> leave bottom allocated
keepTop:
	BitClr	cl, HF_FIXED		;leave top allocated

split:
	;
	; Split the found block to give us a block of the right size.
	;
	sub	ds:[loaderVars].KLV_heapFreeSize, ax ;you are mine. All mine...
	call	SplitBlockWithAddr	;split free block into two pieces

	pop	cx			;recover HeapFlags in cl
	mov	si, bx			;move new mem to si
	pop	bx			;recover handle passed
	
	;
	; See if we had to allocate the thing pseudo-fixed. If HF_FIXED is
	; clear but HF_DEBUG is set, it's pseudo-fixed.
	;
	; Also see if we had to allocate a movable block the desperate way
	; (movable crossed into fixed heap).  If both HF_FIXED and HF_DEBUG
	; are set, it is so.
	;
	test	cl, mask HF_DEBUG
	jz	giveMem			;=> normal method
	test	cl, mask HF_FIXED
	jz	pseudoFixed		;=> HF_DEBUG w/o HF_FIXED, pseudo-fixed

	;
	; Block is movable and was allocated the desperate way, so it was
	; *probably* allocated in fixed heap.  Need to go upward and convert
	; all fixed block above this one to pseudo-fixed.
	;
	mov	di, si			;^hdi = starting block
convertLoop:
	mov	di, ds:[di].HM_next	;^hdi = block above
	cmp	di, ds:[loaderVars].KLV_handleBottomBlock   ;check if top of
							    ; heap was reached
	je	giveMem			;=> yes
	tst	ds:[di].HM_owner	;free?
	jz	convertLoop		;=> skip free block
	test	ds:[di].HM_flags, mask HF_FIXED
	jz	giveMem			;=> movable heap reached, done
	BitClr	ds:[di].HM_flags, HF_FIXED
	mov	ds:[di].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	jmp	convertLoop

giveMem:
	push	cx
	call	SwapHandles
	pop	cx

	test	ch, mask HAF_ZERO_INIT
	jz	noZeroInit

	push	cx			; preserve ch...
	call	DoZeroInit		;if HAF_ZERO_INIT passed, do it
	pop	cx
noZeroInit:
	clc
	ret

returnError:
	pop	bx
	call	FreeHandle		;error -- free handle
	stc
	ret

pseudoFixed:
	;
	; Need to clear HF_FIXED in the handle we allocated and set the
	; lock count to indicate pseudo-fixed.
	;
	andnf	ds:[bx].HM_flags, not mask HF_FIXED
	mov	ds:[bx].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	jmp	giveMem
AllocHandleAndBytes	endp
endif       ; not PRODUCT_GEOS32

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoZeroInit

DESCRIPTION:	initialize a memory block to 0's

CALLED BY:	INTERNAL
		AllocHandleAndBytes

PASS:
	exclusive access to heap variables
	bx - handle of block to initialize
	ds - handles

RETURN:
	bx, ds - same

DESTROYED:
	ax, cx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Chris	10/7/88		Reflects changed routine name GetByteSize
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

DoZeroInit	proc	near
	push	es
	mov	es,ds:[bx][HM_addr]	;get segment address in es
	call	GetByteSize
	shr	cx,1			;convert to words
	clr	ax			;store zeros
	mov	di,ax
	rep stosw

	pop	es
	ret

DoZeroInit	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoReAlloc

DESCRIPTION:	Realloocate a block of memory (internal routine)

CALLED BY:	EXTERNAL
		MemReAlloc, ProcCallModuleRoutine

PASS:
	exclusive access to heap variables
	ax - size (in paragraphs) to allocate (or 0 to allocate same size)
	bx - handle of block to reallocate
	ch - flags for allocation method: HeapAllocFlags record
	ds - kernel data segment
	dx - address of call back routine to load in block (0 for none)
	di - data to pass to callback routine

RETURN:
	carry - set if error (not enough memory)
	bx, cx - same
	ds - handles

DESTROYED:
	ax, dx, si, di

	Call back routine:
	PASS:
		bx - handle passed (HM_addr NOT valid)
		si - temporary handle (HM_addr valid, HM_otherInfo NOT valid)
		ds - idata
	RETURN:
		none
	DESTROYED:
		ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if (new size <= old size) begin
		call SplitBlock to make block partially free
	end else begin
		allocate new block
		if old block swapped swapped call MemSwapIn
	end

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

if	ERROR_CHECK
DoReAllocFar	proc	far
	call	DoReAlloc
	ret
DoReAllocFar	endp
endif	;ERROR_CHECK

DoReAlloc	proc	near
	InsertGenericProfileEntry PET_HEAP, 1, PMF_HEAP, bx
	push	cx
EC <	call	AssertHeapMine						>
	or	ax,ax			;test for allocate same size
	jnz	diffSize
	mov	ax,ds:[bx][HM_size]	;if so then get size
diffSize:
	mov	cl,ds:[bx][HM_flags]
	cmp	ds:[bx].HM_addr,0
	jnz	inMem
	test	cl,mask HF_DISCARDED
	jnz	discarded

	push	ax, cx, di
	call	MemSwapIn
	pop	ax, cx, di

	; Check if the block went from swapped to discarded.
	test	ds:[bx][HM_flags],mask HF_DISCARDED
	jnz	discarded

inMem:
	cmp	ax,ds:[bx][HM_size]	;compare to current size

	jz	doneGood		;if same then do nothing
	ja	makeLarger		;if more then branch to make larger

	; allocating a block smaller -- split it into two blocks

	mov	cl,mask HF_FIXED	;pass flag to put block at bottom
	clr	dx
	xchg	ds:[bx].HM_addr, dx
	call	SplitBlockFreeRemainder
	xchg	ds:[bx].HM_addr, dx
doneGood:
	tst	ds:[bx].HM_lockCount	; If block is locked, don't muck with
	jnz	done			;  the usage value, as it would screw
					;  up thread-grabbed blocks (tst
					;  clears the carry)

	mov	ax, ds:[systemCounter.low];Else set the usageValue for the block
	mov	ds:[bx].HM_usageValue, ax;  so it doesn't get discarded or
					;   swapped right away.
done:
	pop	cx
	InsertGenericProfileEntry PET_HEAP, 0, PMF_HEAP, bx
	ret

	; block is discarded -- allocate new bytes for it

discarded:
	call	allocRoom
	jc	done

discardedHaveRoom:
	tst	dx			;callback function ?
	jz	noCallBack
	inc	ds:[si].HM_lockCount	;ensure new memory remains resident,
					; in case callback must release heapSem
					; -- ardeb 8/11/92
	call	dx
	dec	ds:[si].HM_lockCount
noCallBack:
	cmp	ds:[si].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	pushf	
	call	SwapHandles		;assign memory to correct handle
	popf	
	jne	notPsuedoFixed
	;
	; If the new memory was allocated psuedo fixed before handles
	; were swapped, we want to make sure that it is still psuedo fixed.
	; -Ian 6/95
	;
	BitClr	ds:[bx].HM_flags, HF_FIXED
	mov	ds:[bx].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
notPsuedoFixed:
	BitClr	ds:[bx][HM_flags], HF_DISCARDED
	jmp	short done

	; block is not discarded and is expanding
	; XXX: Look for large enough free block before...


makeLarger:
if LOG_BLOCK_MOVEMENT
	push	ax
	mov	ax, BMO_RESIZE
	call	LogBlockMovement
	pop	ax
endif
	mov	dx, NUMBER_OF_ALLOCATION_RETRIES
tryAgain:
	call	TryExpand
	jnc	doneGood
	;
	; Following block is either in-use or not big enough, so just bite
	; the bullet and allocate another block large enough to copy to.
	;
	push	cx
	andnf	ch, not mask HAF_NO_ERR	; Give us a second chance...
	call	allocRoom
	pop	cx
	jc	tryExpandAgain

	; bx = old mem
	; si = new mem

	mov	di,ds:[bx][HM_addr]	;pass address of block to relocate
	tst	di
	jz	madeLargerButBlockNowNonResident

	cmp	ds:[si].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	pushf	
	call	RelocateBlock
	popf	
	jne	doneGood
	;
	; If the new memory was allocated psuedo fixed before handles
	; were swapped, we want to make sure that it is still psuedo fixed.
	; -mevissen 4/99
	;
	BitClr	ds:[bx].HM_flags, HF_FIXED
	mov	ds:[bx].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED

	jmp	doneGood	;finish up

tryExpandAgain:
	call	TryExpand
	jnc	doneGood

	test	ch, mask HAF_NO_ERR
	stc
	jz	done
	;
	; If HAF_NO_ERROR was passed try sleeping before putting up
	; and error dialog box.
	;
	tst	dx	
	jz 	error
	call	AllocationFailure
	jmp	tryAgain
error:
	call	NotifyAllocError
	jmp	tryAgain

madeLargerButBlockNowNonResident:
	; more code to cope with being called on a block that's not locked,
	; which means allocating more room for it could cause it to be discarded
	; or swapped. -- ardeb 4/17/94

	test	ds:[bx].HM_flags, mask HF_DISCARDED
	jnz	discardedHaveRoom	;allocating room caused block to be
					; discarded, so just pretend the darn
					; thing was discarded on entry

EC <	test	ds:[bx].HM_flags, mask HF_SWAPPED			>
EC <	ERROR_Z	BLOCK_NOT_SWAPPED					>
	call	MemSwapInCallDriver

	; mark reallocated handle as discarded, not swapped, so SwapHandles
	; doesn't try to free swap space that was freed by swapping the block
	; in.
	xornf	ds:[bx].HM_flags, mask HF_SWAPPED or mask HF_DISCARDED
	jmp	noCallBack		; after that, it's the same as if we
					;  reallocated a discarded block, but
					;  with no need to call the callback
					;  to get the data for the block.

;------------------------------------------------------------------------------
; subroutine to allocate a block of memory with which to swap the source or
; to which to relocate the source...
allocRoom:
	push	dx, bx, di
	mov	dl, ds:[bx].HM_flags

;	Do not discard or swap this block

	push	dx
	andnf	dl, not (mask HF_DISCARDABLE or mask HF_SWAPABLE)
	mov	ds:[bx].HM_flags, dl
	mov	bx,ds:[bx][HM_owner]

;	If the old block was fixed, then make the new one fixed too.

	mov	cl, mask HF_FIXED	;We want to allocate the new block
	test	dl, mask HF_FIXED	; as fixed if the old one was fixed
	jnz	10$			; or pseudo-fixed.
	cmp	ds:[bx][HM_lockCount], LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	je	10$
	clr	cl			;
10$:	
	call	AllocHandleAndBytes	;allocate bytes for new handle
	mov	si,bx			;si = new mem
	pop	dx
	pop	bx, di
	mov	ds:[bx].HM_flags, dl
	pop	dx
	retn
DoReAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TryExpand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to expand a block to its neighboring blocks

CALLED BY:	(INTERNAL) DoReAlloc
PASS:		ds	= dgroup
		bx	= block to enlarge
		ch	= HeapAllocFlags
		ax	= desired size (paras)
RETURN:		carry clear if expansion successful
DESTROYED:	cl, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TryExpand	proc	near
		uses	dx
		.enter
	;
	; First go for following block, as that takes the least work.
	; 
		call	ExpandToPostNeighbor
		jnc	done
	;
	; Ok, try the preceding block, then.
	; 
		call	ExpandToPreNeighbor
		jnc	done
	;
	; That failure, established try combining preceding and following blocks
	; 
		call	ExpandToBothNeighbors
done:
		.leave
		ret
TryExpand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandToPostNeighbor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to enlarge a global block into its following block

CALLED BY:	DoReAlloc
PASS:		ds	= idata
		bx	= block to enlarge
		ch	= HeapAllocFlags
		ax	= desired size (paras)
RETURN:		carry clear if expansion successful
DESTROYED:	cl, di, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandToPostNeighbor proc	near	uses ax
		.enter
	;
	; See if the following block is free and big enough for us to
	; expand into it.
	;
		mov	si, ds:[bx].HM_next
		cmp	si, ds:[loaderVars].KLV_handleBottomBlock ;wrapping?
		je	done			; yes -- can't use it (CF=0)

		mov	cl, mask HF_FIXED
		call	ExpandCommon

done:
		cmc
		.leave
		ret
ExpandToPostNeighbor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to attempt to expand to a single neighboring
		block. Checking for wrapping around the heap chain should
		already have happened.

CALLED BY:	(INTERNAL) ExpandToPostNeighbor,
			   ExpandToPreNeighbor
PASS:		ds	= dgroup
		bx	= block being enlarged
		si	= block to expand into, if possible
		ch	= HeapAllocFlags indicating whether expansion should
			  be zero-initialized
		cl	= HeapFlags telling which way we're going: HF_FIXED
			  means we're expanding to the following block,
			  0 means we're expanding to the previous block
		ax	= number of paragraphs required
RETURN:		carry clear if expansion successful
DESTROYED:	di, dx, si, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandCommon	proc	near
		.enter
		tst_clc	ds:[si].HM_owner	; handle free?
		jnz	toDone			; no -- can't use it (CF=0)

		sub	ax, ds:[bx].HM_size	; figure size needed from
						;  neighbor
		cmp	ax, ds:[si].HM_size	; can neighbor provide that
						;  much?
		jb	splitBlock		; yes, and more -- take what
						;  we need
		je	mergeSI			; if neighbor block has exactly
						;  that much, just consume the
						;  thing.
		; (CF=0 if JA would have taken)
toDone:
		jmp	done

splitBlock:
	;
	; Split neighbor block in two, giving us the appropriate part (as
	; dictated by our passed CL)
	;
		push	bx
		mov	bx, si
		call	SplitBlockWithAddr
		mov	si, bx			; si <- block to merge in.
		pop	bx

mergeSI:
		test	cl, mask HF_FIXED
		jnz	blockCopied		; => expanding to following,
						;  so no need for copy
	;
	; Expanding to previous, so swap segments between the block being
	; subsumed and the block being enlarged.
	; 
		mov	ax, ds:[bx].HM_addr
		xchg	ds:[si].HM_addr, ax
		mov	ds:[bx].HM_addr, ax
	;
	; Copy the block down to the start of the new block. Can't use
	; MoveBlock b/c it moves stuff backwards...
	; 
		push	cx, ds, si, es, di
		mov	es, ax			; es <- bx.HM_addr
		call	GetByteSize		; cx <- bytes to move
		mov	ds, ds:[si].HM_addr
		clr	si, di
if	USE_32BIT_STRING_INSTR
		shr	cx, 2
		rep	movsd
else
		shr	cx
		rep	movsw
endif	; USE_32BIT_STRING_INSTR
	;
	; Set true address of expansion block (swapping HM_addr fields is fine
	; for the copy, but when it comes to zero-initialization, si.HM_addr
	; must point to the first byte beyond the just-copied data)
	; 
		mov	ax, es			; ax <- bx.HM_addr
		pop	cx, ds, si, es, di
		add	ax, ds:[bx].HM_size
		mov	ds:[si].HM_addr, ax

blockCopied:
	;
	; Give SI's memory to BX. zero-initialize the victim first, if so
	; requested.
	;
		test	ch, mask HAF_ZERO_INIT
		jz	victimInitialized

		push	cx
		xchg	bx, si
		call	DoZeroInit		; destroys ax, cx, di
		xchg	bx, si
		pop	cx

victimInitialized:
	;
	; Up the size of the reallocated block by size of neighbor block
	;
		mov	ax, ds:[si].HM_size
		sub	ds:[loaderVars].KLV_heapFreeSize, ax
						; reduce total free space by
						;  this amount as well, since
						;  space ain't free
		add	ds:[bx].HM_size, ax

	;
	; Fix the links for the handle after/before the subsumed one before
	; freeing the thing.
	;
		mov	ax, si			; preserve subsumed handle for
						;  free
		test	cl, mask HF_FIXED
		jz	fixPrev
		
		mov	si, ds:[si].HM_next	; si <- handle after that
		mov	ds:[bx].HM_next, si	; point enlarged one to new next
		mov	ds:[si].HM_prev, bx	; point new next back at e.o.
		jmp	freeHandle

fixPrev:
		mov	si, ds:[si].HM_prev	; si <- handle before that
		mov	ds:[bx].HM_prev, si	; point enlarged one to new prev
		mov	ds:[si].HM_next, bx	; point new prev back at e.o.
	;
	; If the subsumed block was the bottom of the heap, the enlarged one
	; takes on that role now (note that if prev block was split,
	; KLV_handleBottomBlock will *not* be == ax here)
	; 
		cmp	ds:[loaderVars].KLV_handleBottomBlock, ax
		jne	freeHandle
		mov	ds:[loaderVars].KLV_handleBottomBlock, bx
freeHandle:

		xchg	ax, bx		; bx <- subsumed block, ax <- enlarged
					;  block

if TRACK_FINAL_FREE
   		cmp	ds:[lastFreeBlock], bx
		jne	freeVictim
	;
	; About to free the block known as the last free one in the heap, so
	; we have to find the next-earlier one in the heap and store its
	; handle instead.
	; 
		mov	si, bx
findPrevFree:
		mov	si, ds:[si].HM_prev
		cmp	ds:[si].HM_owner, 0
		jne	findPrevFree
setLastFree::
		mov	ds:[lastFreeBlock], si
freeVictim:
endif
		call	FreeHandle		; just free subsumed handle, as
						;  it has no memory
		xchg	ax, bx		; bx <- enlarged block, again
		stc			; so we return carry clear...
done:
		.leave
		ret
ExpandCommon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandToPostNeighbor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to enlarge a global block into its following block

CALLED BY:	(INTERNAL) TryExpand
PASS:		ds	= idata
		bx	= block to enlarge
		ch	= HeapAllocFlags
		ax	= desired size (paras)
RETURN:		carry clear if expansion successful
DESTROYED:	cl, di, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/94		Initial version (copied from
				ExpandToPostNeighbor)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandToPreNeighbor proc	near	uses ax
		.enter
	;
	; See if the previous block is free and big enough for us to
	; expand into it.
	;
		cmp	bx, ds:[loaderVars].KLV_handleBottomBlock ;wrapping?
		je	done			; yes -- can't use it (CF=0)

		mov	si, ds:[bx].HM_prev
		clr	cl			; signal expand to previous
		call	ExpandCommon
done:
		cmc
		.leave
		ret
ExpandToPreNeighbor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandToBothNeighbors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to expand a block to both its previous and following
		neighboring blocks. We know when we get here that neither is
		enough to satisfy the request.

CALLED BY:	(INTERNAL) TryExpand
PASS:		ds	= idata
		bx	= block to enlarge
		ch	= HeapAllocFlags
		ax	= desired size (paras)
RETURN:		carry clear if expansion successful
DESTROYED:	cl, di, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandToBothNeighbors proc	near
		uses	di, ax
		.enter
	;
	; Make sure prev & following blocks exist and are free.
	; 
		cmp	bx, ds:[loaderVars].KLV_handleBottomBlock
		je	done		; => no previous (CF=0)

		mov	si, ds:[bx].HM_next
		cmp	si, ds:[loaderVars].KLV_handleBottomBlock
		je	done		; next is bottom => wrapped, so no
					;  next (CF=0)

		tst	ds:[si].HM_owner
		jnz	done		; => next is not free (CF=0)

		mov	di, ds:[bx].HM_prev
		tst	ds:[di].HM_owner
		jnz	done		; => prev is not free (CF=0)
	;
	; We know here that the previous block is not large enough to satisfy
	; the request, so we can just blithely do these subtractions.
	; 
		sub	ax, ds:[bx].HM_size	; ax <- # additional paras
		sub	ax, ds:[si].HM_size	; ax <- # needed from previous
EC <		ERROR_B	GASP_CHOKE_WHEEZE				>
		cmp	ax, ds:[di].HM_size	; is previous block big enough?
		ja	done			; no (CF=0)
	;
	; The sum of the two neighboring free blocks is big enough to satisfy
	; the request. First expand into just enough of the previous block
	; as required, assuming we'll use all of the following. We expand into
	; the previous block to limit the number of bytes we have to move...
	; 
		add	ax, ds:[bx].HM_size	; ax <- # paras "required" so
						;  we use just enough of the
						;  previous block
		call	ExpandToPreNeighbor
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>
		mov	si, ds:[bx].HM_next
		add	ax, ds:[si].HM_size	; ax still # existing + # used
						;  from prev block. with this
						;  addition, we get back to
						;  the total number needed,
						;  since we'll be absorbing
						;  the entire following block.
		call	ExpandToPostNeighbor
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>
		cmc				; so carry returned clear
						;  (in NEC, this also ensures
						;  we return carry set if
						;  second expansion somehow
						;  failed...)
done:
		cmc
		.leave
		ret
ExpandToBothNeighbors endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoFree

DESCRIPTION:	Free the given block, even if it is locked

CALLED BY:	EXTERNAL
		MemFree, SwapHandles, FreeGeodeBlocks

PASS:
	exclusive access to heap variables
	bx - handle of block to free
	ds - handles

RETURN:
	ds - same

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

if	ERROR_CHECK
DoFreeFar	proc	far
	call	DoFree
	ret
DoFreeFar	endp
endif	;ERROR_CHECK

DoFree	proc	near

if ERROR_CHECK
udata	segment
	extrn	threadStackPtr:hptr
udata	ends

;	We don't want to do this test during a dirty shutdown, so if we
;	are running on the kernel thread, skip this.

	tst	ds:[currentThread]
	jz	inKernel
	push	si
	mov	si, offset threadStackPtr - offset HM_usageValue
checkStackListLoop:
	mov	si, ds:[si].HM_usageValue
	cmp	bx, si
	ERROR_E	FREEING_ACTIVE_STACK
	tst	si
	jnz	checkStackListLoop
	pop	si
inKernel:
endif

if	TEST_DUPLICATE_LIST

%out CANNOT WORK since core block must be locked -- rewrite...

	push	bx, si, es
	mov	si, ds:[bx].HM_owner		;si = handle of owner
	tst	si
	jz	endOfList
	cmp	si, handle 0
	jz	endOfList
	cmp	si, 0x20
	jz	endOfList
	mov	es, ds:[si].HM_addr		;es = core block
	test	es:[GH_geodeAttr], mask GA_PROCESS
	jz	endOfList
	mov	si, offset PH_savedBlockPtr	;es:si points at list
dupLoop:
	mov	si, es:[si]			;si = block on list
	tst	si
	jz	endOfList
	cmp	si, bx
	ERROR_Z	FREEING_BLOCK_ON_DUPLICATE_LIST
	segmov	es, ds
	lea	si, ds:[si].HSB_next
	jmp	dupLoop
endOfList:
	pop	bx, si, es

endif
if	FULL_EXECUTE_IN_PLACE
EC <	cmp	bx, LAST_XIP_RESOURCE_HANDLE				>
EC <	ERROR_BE	FREEING_XIP_RESOURCE				>
endif

EC <	call	AssertHeapMine						>
	call	DeleteSwapFileIfExists	;if swapped, delete the swap file

if LOG_BLOCK_MOVEMENT
	mov	ax, BMO_FREE
	call	LogBlockMovement
endif

	FALL_THRU	DoFreeNoDeleteSwap

DoFree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoFreeNoDeleteSwap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a block of memory, filling it with CC's if EC, but
		don't worry about any swap file (use this if you know the
		block can't have a swap file, else use DoFree).

CALLED BY:	DoFree, SplitBlockFreeRemainder, others
PASS:		ds	= idata
		bx	= block to free
		exclusive access to heap variables
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoFreeNoDeleteSwap	proc	near
EC <	call	AssertHeapMine						>

	inc	ds:[tobId]		;give the scrubber pause if called
					; from anywhere but ThrowOutBlocks

	mov	al,DEBUG_FREE		;notify debugger of freeing block
	call	FarDebugMemory

	cmp	ds:[bx][HM_addr],0	;check for memory associated with
	jz	noMem		;handle
EC <	call	CheckBX							>

	; fill block to free with breakpoints

NEC <	push	ds							>
NEC <	mov	ds, ds:[bx].HM_addr					>
NEC <	mov	{word} ds:[0], 0xcccc					>
NEC <	pop	ds							>

EC <	call	ECFillCCCC						>

	mov	ds:[bx][HM_owner],0	;mark as free
	mov	{word}ds:[bx][HM_flags],0	;zero flags and lock count
	mov	ax, ds:[bx].HM_size
	add	ds:[loaderVars].KLV_heapFreeSize, ax

	call	CombineBX
	ret

noMem:
	jmp	FreeHandle

DoFreeNoDeleteSwap	endp

DoFreeNoDeleteSwapFar	proc	far	; for MemExtendHeap
	call	DoFreeNoDeleteSwap
	ret
DoFreeNoDeleteSwapFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoDiscardFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special case for discarding fonts.
CALLED BY:	JMP'd to by DoDiscard

PASS:		exclusive access to heap variables
		ds - seg addr of idata
		bx - handle of font to discard or free
RETURN:		if font deleted:
			carry clear
		else:
			DoDiscard();
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
	if (refCount == 0) {
		DoFree(bx);
	} else {
		DoDiscard(bx);
	}

		Checking the reference count is somewhat tricky.
	We need the font info block, but we are in the middle of
	the heap code. Blocking on the font semaphore would be
	"a bad thing", so we do the bizarre things below. If we
	can't get the font semaphore, we just discard the font,
	as we would have done if the block wasn't a font. If
	the reference count is non-zero, we do the same thing.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoDiscardFont	proc	near
	mov	cx, bx				;cx <- handle to delete
	mov	bx, ds:fontBlkHandle		;bx <- handle of font info block
	call	MemThreadGrabNB			;can we get semaphore?
	jc	cantDelete			;can't P, can't delete
	push	ds
	mov	ds, ax				;ds <- seg addr of info block
	mov	ax, cx				;ax <- handle of font to delete
	call	DeleteFontByHandle		;find font, check ref count
	pop	ds
	jnz	cantDeleteRelease		;branch if can't delete
	xchg	bx, cx				;bx <- handle to delete
	;
	; We need to restore the address so DoFree doesn't choke.
	; This is safe to do because no one has this handle anymore.
	;
	mov	ds:[bx].HM_addr, dx		;restore address for DoFree
	call	DoFree				;free the block & handle
	xchg	bx, cx				;bx <- handle of font info block
	call	MemThreadRelease		;release semaphore
	mov	bx, cx				;bx <- original handle
	clc					;indicate success
	ret

cantDeleteRelease:
	call	MemThreadRelease		;release semaphore
cantDelete:
	mov	bx, cx				;cx <- handle to delete
	jmp	afterFontDiscard
DoDiscardFont	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoFullDiscard

DESCRIPTION:	Discard the given block without trying to delete the swap file

CALLED BY:	INTERNAL
		MemSwapOut, ThrowOutBlocks

PASS:
	exclusive access to heap variables
	bx - handle of block to discard
	ds - kernel data
	dx - address of block to discard

RETURN:
	carry - set if error

DESTROYED:
	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

DoFullDiscard	proc	near
EC <	call	ECCheckMemHandleNSFar					>
EC <	call	AssertDSKdata						>
EC <	call	AssertHeapMine						>

	;
	; If the block is a VM block, pass the buck to the VM code, as it
	; needs to know when one of its blocks goes away.
	; 
	mov	bp, ds:[bx].HM_owner
	cmp	ds:[bp].HG_type, SIG_VM
	jne	notVM

	call	VMUpdateAndRidBlk		;func(ds,bp,bx,dx)
	ret

notVM:
	FALL_THRU	DoDiscard

DoFullDiscard	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoDiscard

DESCRIPTION:	Discard the given block and biff any swap space it may have.

CALLED BY:	INTERNAL
		MemSwapOut, ThrowOutBlocks

PASS:
	exclusive access to heap variables
	bx - handle of block to discard
	ds - kernel data
	dx - address of block to discard

RETURN:
	carry - clear

DESTROYED:
	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

DoDiscard	proc	near
	cmp	ds:[bx].HM_owner, FONT_MAN_ID	;owned by font manager?
	je	DoDiscardFont			;special case for fonts...
afterFontDiscard	label	near

	mov	al,DEBUG_DISCARD		;notify debugger of discard
	call	FarDebugMemory

	;
	; if the block is currently swapped, free up its swap space first.
	; this is necessary to deal with discarding swapped VM blocks, both
	; for task-switching and when a fast swap device is filled up.
	; -- ardeb 5/22/91
	; 

	test	ds:[bx].HM_flags, mask HF_SWAPPED
	jz	freeData
	call	MemSwapDelete

freeData:
	mov	al,mask HF_DISCARDED

	FALL_THRU	FreeBlockData

DoDiscard	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FreeBlockData

DESCRIPTION:	FreeBlockData - Free the memory associated with a given block

CALLED BY:	INTERNAL
		DoFullDiscard, MemSwapOut, VMUpdateRidBlk

PASS:
	exclusive access to heap variables
	al - HF_DISCARDED if block discarded, HF_SWAPPED if block swapped.
	bx - handle of block to discard
	dx - address of block to discard
	ds - handles

RETURN:
	carry - clear

DESTROYED:
	ax, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

FreeBlockData	proc	near
	push	si
EC <	call	AssertHeapMine						>

	call	DupHandle		;new handle returned in bx, old in si
	mov	ds:[bx][HM_addr],dx
	andnf	ds:[bx].HM_flags, not mask HF_DEBUG	; Swat can't be
							;  interested...
	call	FixLinks		;put new block in list

; I can see no reason for not clearing both these bits (it used to just clear
; HF_SWAPPED, formerly HF_MEM_SWAP), but only if HF_DISCARDED wasn't passed in.
; I remember asking Tony about this and him not knowing why this was done, and
; I vaguely recall having found why, but I would have put a comment here
; explaining it, so I must not have. So this test is commented out, on the
; off chance that there's as reason for its existence -- ardeb 8/28/90
;
; NEWS FLASH! I believe this was done b/c the old memory-swapping code would
; do an AssertMemSwappedHandle before allowing something to delete the swap
; space for the block. Since MemSwapDelete doesn't care if the thing is swapped
; or not (it trusts its caller to have determined this ahead of time). The only
; nasty possibility is if the VM code discards the block, but that will call us
; with HF_DISCARDED and we don't try to delete the swap file. MemSwapOut will
; call MemSwapDelete properly and we should be happy.
;
;	test	al, mask HF_DISCARDED
;	jne	10$

	andnf	ds:[si][HM_flags],not (mask HF_SWAPPED or mask HF_DISCARDED)
;10$:
	ornf	ds:[si][HM_flags],al	;mark as discarded or swapped

	mov	ds:[si][HM_addr],0	;mark as not associated with memory

	call	DoFreeNoDeleteSwap	;free memory

	clc				;just in case anyone cares
	mov	bx,si
	pop	si
	ret

FreeBlockData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoDiscardFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call DoDiscard from outside kcode.

CALLED BY:	VM code, mostly
PASS:		
	exclusive access to heap variables
	bx - handle of block to discard
	ds - kernel data
	dx - address of block to discard

RETURN:
	carry - clear

DESTROYED:
	ax, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoDiscardFar	proc	far
		.enter
		call	DoDiscard
		.leave
		ret
DoDiscardFar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DeleteSwapFileIfExists

DESCRIPTION:	Delete a swap file

CALLED BY:	INTERNAL
		RemoveSwapFiles, DoFree

PASS:
	bx - handle of block to delete swap file for
	ds - handles

RETURN:
	bx, ds - unchanged

DESTROYED:
	al

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

DeleteSwapFileIfExists	proc	near
EC<	call	AssertDSKdata						>

	cmp	ds:[bx][HM_owner],0		;test for free
	jz	done
	cmp	ds:[bx][HM_addr],0		;discarded or swapped out?
	jnz	done				;branch if not

	test	ds:[bx].HM_flags, mask HF_SWAPPED
	jz	done

	call	MemSwapDelete
done:
	ret
DeleteSwapFileIfExists	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SGI_SwapFreeSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the total amount of swap space available

CALLED BY:	SysGetInfo

PASS:		ds - dgroup

RETURN:		dx:ax - amount of free memory (bytes)

DESTROYED:	bx, cx, si, ds

PSEUDO CODE/STRATEGY:
	Look at each swap driver's "map" and multiply the number of
	free pages by the page size.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This procedure is here instead of sysStats.asm because it uses
	variables and constants that are defined only in this module.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/23/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SGI_SwapFreeSize	proc	near
		uses	es
		.enter
		mov	si, offset swapTable
		clr	bx, cx
swapLoop:
		mov	di, DR_SWAP_GET_MAP
		call	ds:[si].SD_strategy
		tst	ax
		jz	next

		mov	es, ax
		mov	ax, es:[SM_numFree]
		mul	es:[SM_page]		; dx:ax - free bytes
		adddw	bxcx, dxax
next:
		add	si, size SwapDriver
		cmp	si, ds:[swapNext]
		jb	swapLoop

		movdw	dxax, bxcx
		.leave
		ret
SGI_SwapFreeSize	endp
