COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		heapHigh.asm (high level heap routines)

AUTHOR:		Tony Requist

ROUTINES:
	Name		Description
	----		-----------
   GLB	MemAlloc		Allocate memory from the heap
   GLB	MemReAlloc		Reallocate a block on the heap
   GLB	MemFree			Free the given block on the heap
   GLB	MemLock			Retrieve the absolute address of and lock a
				block on the global heap
   GLB	MemDerefDS		fetch segment of locked block into DS
   GLB	MemDerefES		fetch segment of locked block into ES
   GLB	MemUnlock		Unlock the given block on the global heap
   GLB	MemGetInfo		Return information about a block
   GLB	MemModifyFlags		Modify the flags associated with a block
   GLB	HandleModifyOwner	Modify the owner of a Handle
   GLB	MemModifyOtherInfo	Modify the other info associated with a block
   GLB	MemThreadGrab		Lock a block and set a semaphore on the block
				that allows the current thread to do more
				MemThreadGrab's but will cause other threads
				to wait.
   GLB	MemThreadRelease	Undo MemThreadGrab
   GLB	HandleP			Set a semaphore on the given block to ensure
				exclusive access
   GLB	HandleV			Release a semaphore on the given block
   GLB	ECMemVerifyHeap		Make sure the heap is ok (does nothing in non-ec
   				version)
   GLB	MemLockRead		Lock a block for read-only access
   GLB	MemLockWrite		Lock a block for exclusive read-write access
   GLB	MemUnlockRead		Unlock a block that was locked with either
				MemLockRead or MemLockWrite

Kernel-Global Routines:
   EXT	PHeap			Do P_SEM heapSem
   EXT	VHeap			Do V_SEM heapSem
   EXT	NearLock		Call LockBlock from the kernel
   EXT	NearUnlock		Call UnlockBlock from the kernel
   EXT	SegmentToHandle		Find the handle for a segment value
   EXT	GetByteSize		Figure size of block bx in ax & cx
   EXT	ParaToByteAX		Convert para-size ax to bytes in ax & cx
   EXT	MemSwap			Swap memory between two handles.
   EXT	MemTransfer		Create a new handle and transfer ownership
   				of memory from old handle to it.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

DESCRIPTION:
	This module contains the high level heap routines.  See
heapManager.asm for details.

	$Id: heapHigh.asm,v 1.1 97/04/05 01:13:55 newdeal Exp $

-------------------------------------------------------------------------------@


ChunkArray segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	MemAllocLMem

DESCRIPTION:	Utility routine to allocate a block with a local memory heap

CALLED BY:	GLOBAL

PASS:
	ax - type of heap (LMemType)
	cx - size of block header (or 0 for default)

RETURN:
	bx - block handle:
		lmem handles - 2 (the minimum)
		lmem heap space - 64 bytes

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/91		Initial version

------------------------------------------------------------------------------@
MemAllocLMem	proc	far	uses cx, dx, si, di, ds
	.enter

EC <	call	FarAssertInterruptsEnabled				>

	push	ax
	push	cx
	mov	ax, 128				;initial block size
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAllocFar
	mov	ds, ax

	pop	dx				;dx = block header size
	pop	ax				;ax = heap type

	clr	di
	mov	si, size LMemBlockHeader
	cmp	ax, LMEM_TYPE_OBJ_BLOCK
	jne	gotFlags

	; set exec thread of object block to current thread
	push	ax
	mov	ax, ss:[TPD_threadHandle]
	call	MemModifyOtherInfo
	pop	ax				;ax = LMEM_TYPE_OBJ_BLOCK

	mov	di, mask LMF_HAS_FLAGS or mask LMF_RELOCATED
	mov	si, size ObjLMemBlockHeader

gotFlags:

	; if no size given for header then use the default

	tst	dx
	jnz	10$
	mov	dx, si
10$:

	mov	cx, 2				;2 initial handles
	mov	si, 64				;initial heap size
	call	LMemInitHeap

	call	MemUnlock

	.leave
	ret

MemAllocLMem	endp

ChunkArray ends

COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemAlloc, MemAllocSetOwner

DESCRIPTION:
	Allocate the given number of bytes on the heap.  This block can be:
		Discardable or non-discardable
		Swapable or non-swapable
		Allocated fixed or movable blocks
		Initialized to zero or not
	A passed flag determines whether heap compaction or discarding
	of objects should be used to generate the free space.

CALLED BY:	GLOBAL

PASS:
	ax - size (in bytes) to allocate
	cl - flags for block type: HeapFlags record
	ch - flags for allocation method: HeapAllocFlags record

MemAllocSetOwner:
	bx - new owner of block

RETURN:
	bx - handle to block allocated
	ax - address of block allocated (if block is fixed or locked)
	carry - set if error (not enough memory)

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Set the appropriate registers and call AllocHandleAndBytes to do
	the work.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

MemAllocFar	proc	far
	call	MemAlloc
	ret
MemAllocFar	endp

MemAllocSetOwnerFar	proc	far
	call	MemAllocSetOwner
	ret
MemAllocSetOwnerFar	endp

MemAlloc	proc	near
	mov	bx, ss:[TPD_processHandle]	;bx <- owner (current thread)
	FALL_THRU	MemAllocSetOwner
MemAlloc	endp

MemAllocSetOwner	proc	near
	push	ds
EC <	call	AssertInterruptsEnabled					>
	LoadVarSeg	ds
	call	PHeap
	call	MemAllocLow
	call	VHeap
	pop	ds
	ret
MemAllocSetOwner	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MemReAlloc

DESCRIPTION:
	Change the size of a given block.  Also used to reallocate space for a
	block that has been discarded.

CALLED BY:	GLOBAL

PASS:
	ax - size (in bytes) to allocate (or 0 to allocate same size)
	bx - handle of block to reallocate (may be locked)
	ch - flags for allocation method: HeapAllocFlags record
		HAF_ZERO_INIT - To initialize new memory to 0 (only applicable
				if block is getting larger)
		HAF_LOCK - To lock the block after reallocating (normally
			   used when reallocating discarded blocks)
		HAF_NO_ERR - To not return errors

RETURN:
	carry - set if error (not enough memory)
	bx - same
	ax - segment address of block if HF_LOCK passed
	     or if passed block was locked already

DESTROYED:
	ax, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Set variables and call DoReAlloc to do the work

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Blocks which are locked can be re-alloc'd. The new segment address
	is returned in ax. You probably don't want to pass the HF_LOCK flag
	as this will result in another lock being made on the block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added
	John	15-Aug-89	Update documentation.

------------------------------------------------------------------------------@

MemReAlloc	proc	far
	push	dx
EC <	call	AssertInterruptsEnabled					>
	call	EnterHeap		;do generic entry stuff

	; non-ec: verify handle

NEC <	call	FastCheckHandleLegal					>

EC <	call	ECCheckMemHandleNSFar					>

;	malloc() uses this!
;EC <	test	ds:[bx][HM_flags],mask HF_FIXED				>
;EC <	ERROR_NZ	HANDLE_FIXED					>

EC <	cmp	ax,0fff1h						>
EC <	ERROR_AE	REALLOC_TOO_LARGE				>
EC <	test	ch,not(mask HAF_ZERO_INIT or mask HAF_LOCK or mask HAF_NO_ERR)>
EC <	ERROR_NZ	REALLOC_BAD_FLAGS				>

	call	CheckFreeHandles
NEC <	jc	done			;if not enough handles, exit with error>
EC <	jc	wasNotResident		;if not enough handles, exit with error>

EC <	push	ds:[bx].HM_addr		;save original address		>

	add	ax,15			;compute # of paragraphs
	mov	cl,4
	shr	ax,cl

	; some vmem stuff..  in case we are changing the size of a
	; vmem block..

	mov	dx, ds:[bx].HM_size
	push	si
	push	dx

	clr	dx
	call	DoReAlloc		;do reallocation
	jc	done

	;	VM Dirty Size Tracking
	; Do some nifty VM File stuff.. I'll explain as we go
	; first, check if we're dealing with a VM block
	;
	mov	si, ds:[bx].HM_owner
	cmp	ds:[si].HVM_signature, SIG_VM
	jne	doneWithVMStuff
	;
	; now, check if the block was previously marked dirty (else
	; they'll take care of it later..)
	;
	test	ds:[bx].HM_flags, mask HF_DISCARDABLE
	jnz	doneWithVMStuff
	;
	; ok, now calc the size difference 
	;
	pop	dx
	push	dx

	xchg	cx, dx			; preserve cx
	sub	cx, ds:[bx].HM_size
	neg	cx
	;
	; now, check if this new size causes a mode change..
	; 
	push	es
	segmov	es, ds, ax
	call	VMTestDirtySizeForModeChange
	pop	es
	mov	cx, dx			; restore cx
doneWithVMStuff:

	mov	al,DEBUG_REALLOC	;notify debugger of reallocation
	call	FarDebugMemory

	mov	ax,ds:[bx][HM_addr]
	test	ch,mask HAF_LOCK	;check for lock also
	jz	done
	test	ds:[bx][HM_flags],mask HF_FIXED
	jnz	done
	inc	ds:[bx][HM_lockCount]

done:
	pop	dx
	pop	si

;	Return AX=NULL_SEGMENT if the block isn't fixed or locked
EC <	pushf								>
EC <	test	ds:[bx][HM_flags],mask HF_FIXED				>
EC <	jnz	noNullSeg						>
EC <	tst	ds:[bx][HM_lockCount]					>
EC <	jnz	noNullSeg						>
EC <	mov	ax, NULL_SEGMENT					>
EC <noNullSeg:								>
EC <	popf								>

EC <	pop	cx							>
EC <	jcxz	wasNotResident		;don't check the thing if it	>
EC <					;is uninitialized		>
EC <	call	CheckHeapHandleSW					>
EC <wasNotResident:							>
	jmp	ExitHeap		;do generic exit stuff

MemReAlloc	endp

ife	ERROR_CHECK
FastCheckHandleLegal	proc	near
	FAST_CHECK_HANDLE_LEGAL
	ret
FastCheckHandleLegal	endp
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemFree

C DECLARATION:	extern void
			_far _pascal MemFree(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMFREE	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	FALL_THRU	MemFree

MEMFREE	endp
	SetDefaultConvention

COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemFree

DESCRIPTION:
	Free a block of memory.  The block can be locked.

CALLED BY:	GLOBAL

PASS:
	bx - handle of block to free

RETURN:
	none

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Do setup and call DoFree to free the block

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

MemFree	proc	far
EC <	call	AssertInterruptsEnabled					>
EC <	call	ECCheckMemHandleFar					>
	push	dx
	call	EnterHeap		;do generic entry stuff
	push	ax

	; non-ec: verify handle

NEC <	call	FastCheckHandleLegal					>

EC <	call	CheckHeapHandleSW					>
EC <	push	bx							>
EC <	mov	bx, ds:[bx].HM_owner					>
EC <	cmp	ds:[bx].HG_type, SIG_VM					>
EC <	pop	bx							>
EC <	ERROR_Z	MEM_FREE_PASSED_A_BLOCK_IN_A_VM_FILE			>

	call	DoFree

	pop	ax
	jmp	ExitHeap		;do generic exit stuff

MemFree	endp

NearFree	proc	near
		call	MemFree
		ret
NearFree	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemDiscard

C DECLARATION:	extern void
			_far _pascal MemDiscard(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/4/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMDISCARD	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	FALL_THRU	MemDiscard

MEMDISCARD	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemDiscard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Throw away the contents of a discardable block

CALLED BY:	GLOBAL
PASS:		bx	= handle to be biffed
RETURN:		carry set if block couldn't be discarded (may happen if
		the block being discarded is a VM block, for instance, and
		some other thread is actively using the file)
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemDiscard	proc	far
		push	dx
		call	EnterHeap
		push	ax, cx
NEC <		FAST_CHECK_HANDLE_LEGAL					>
EC <		call	CheckHeapHandleSW				>

	;
	; Use DoFullDiscard to biff the block so VM and FontManager get
	; properly notified.
	; 
		mov	dx, ds:[bx].HM_addr
		call	DoFullDiscard

EC <		call	ECMemVerifyHeap					>
		pop	ax, cx
		jmp	ExitHeap
MemDiscard	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemDerefFar

C DECLARATION:	extern void far *
			_far _pascal MemDeref(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Returns NULL (0) if block is discarded.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMDEREF	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	push	ds
	LoadVarSeg	ds

NEC <	call	FastCheckHandleLegal					>
EC <	call	DerefEC							>

	mov	dx, ds:[bx].HM_addr
	clr	ax
	pop	ds

	ret

MEMDEREF	endp
	SetDefaultConvention


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemDerefDS

DESCRIPTION:	De-reference a locked handle into DS

CALLED BY:	GLOBAL

PASS:
	bx - handle

RETURN:
	ds - segment of handle

DESTROYED:
	none -- flags preserved

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/89		Initial version
-------------------------------------------------------------------------------@

MemDerefDS	proc	far
	LoadVarSeg	ds

	; non-ec: verify handle

NEC <	pushf								>
NEC <	FAST_CHECK_HANDLE_LEGAL						>
NEC <	popf								>

EC <	call	DerefEC							>

	mov	ds,ds:[bx].HM_addr
	ret

MemDerefDS	endp

if	ERROR_CHECK

DerefEC	proc	near
if 0
	;
	; I don't understand why we need to check for this here.
	; Adam and Drew agreed that I can get rid of this check.
	; 						- jang
	;
	call	AssertInterruptsEnabled
endif
	pushf
	call	ECCheckMemHandleNSFar
	cmp	ds:[bx].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	jz	done
	test	ds:[bx].HM_flags,mask HF_FIXED
	jnz	done
	cmp	ds:[bx].HM_lockCount,0
	ERROR_Z	BLOCK_MUST_BE_LOCKED
done:
	popf
	ret
DerefEC	endp

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemDerefES

DESCRIPTION:	De-reference a locked handle into ES

CALLED BY:	GLOBAL

PASS:
	bx - handle

RETURN:
	es - segment of handle

DESTROYED:
	none -- flags preserved

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/89		Initial version
-------------------------------------------------------------------------------@

MemDerefES	proc	far
	LoadVarSeg	es

	; non-ec: verify handle

NEC <	pushf								>
NEC <	FAST_CHECK_HANDLE_LEGAL		es				>
NEC <	popf								>

EC <	call	SwapESDS						>
EC <	call	DerefEC							>
EC <	call	SwapESDS						>

	mov	es,es:[bx].HM_addr
	ret

MemDerefES	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemDerefStackDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reload DS from the segment of the block whose handle is
		passed on the stack. This exists to allow one to push
		ds:[LMBH_handle], then reload DS without destroying any
		register or flags.

CALLED BY:	(GLOBAL)
PASS:		on stack: handle whose current address is to be placed in DS
RETURN:		ds reloaded
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemDerefStackDS proc	far
		push	bx
		LoadVarSeg	ds, bx
		mov	bx, sp
		mov	bx, ss:[bx+6]

NEC <		pushf							>
NEC <		FAST_CHECK_HANDLE_LEGAL					>
NEC <		popf							>

EC <		call	DerefEC						>
		mov	ds, ds:[bx].HM_addr
		pop	bx
		ret	2
MemDerefStackDS endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemDerefStackES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reload ES from the segment of the block whose handle is
		passed on the stack. This exists to allow one to push
		es:[LMBH_handle], then reload ES without destroying any
		register or flags.

CALLED BY:	(GLOBAL)
PASS:		on stack: handle whose current address is to be placed in ES
RETURN:		es reloaded
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemDerefStackES proc	far
		push	bx
		LoadVarSeg	es, bx
		mov	bx, sp
		mov	bx, ss:[bx+6]
NEC <		pushf							>
NEC <		FAST_CHECK_HANDLE_LEGAL		es			>
NEC <		popf							>

EC <		call	SwapESDS					>
EC <		call	DerefEC						>
EC <		call	SwapESDS					>
		mov	es, es:[bx].HM_addr
		pop	bx
		ret	2
MemDerefStackES endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemLockFixedOrMovable

C DECLARATION:	extern void *
			MemLockFixedOrMovable(void *);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Returns NULL (0) if block is discarded and cannot be brought in.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMLOCKFIXEDORMOVABLE	proc	far
	C_GetOneDWordArg	bx, dx,   ax,cx

	call	MemLockFixedOrMovable
	xchg	ax, dx		; dx:ax <- fptr
	jnc	done
	clr	ax		; clear offset portion, too
done:	
	ret

MEMLOCKFIXEDORMOVABLE	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemUnlockFixedOrMovable

C DECLARATION:	extern void 
			MemUnlockFixedOrMovable(void *);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMUNLOCKFIXEDORMOVABLE	proc	far
	C_GetOneDWordArg	bx, dx,   ax,cx

	GOTO	MemUnlockFixedOrMovable

MEMUNLOCKFIXEDORMOVABLE	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemPLock

C DECLARATION:	extern void _far *
			_far _pascal MemPLock(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Returns NULL (0) if block is discarded.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMPLOCK	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	clr	dx		; return offset is 0
	call	NearPLock
	xchg	ax, dx		; dx:ax <- fptr
	ret

MEMPLOCK	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

FUNCTION:	MemPLock, NearPLock, NearPLockDS, NearPLockES

DESCRIPTION:	Do a HandleP followed by a MemLock

CALLED BY:	GLOBAL

PASS:	bx - handle of memory block

RETURN:
	ax - seg addr of block (all)
	ds - seg addr of block (NearPLockDS)
	es - seg addr of block (NearPLockES)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

------------------------------------------------------------------------------@


MemPLock	proc	far
	call	NearPLock
	ret
MemPLock	endp

NearPLockES	proc	near
	call	NearPLock
	mov	es, ax
	ret
NearPLockES	endp

NearPLock	proc	near

	; non-ec: verify handle done in HandleP and in NearLock

	call	HandleP
	FALL_THRU	NearLock
NearPLock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NearLock

DESCRIPTION:	Call MemLock from within the kernel

CALLED BY:	INTERNAL

PASS:
	bx - handle to block of memory to lock

RETURN:
	carry - set on error (block is discarded)
	ax - seg addr of block (all)
	ds - seg addr of block (NearLockDS)
	es - seg addr of block (NearLockES)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

NearLock	proc	near
	uses	ds

	.enter

	LoadVarSeg	ds, ax			;ds <- idata

	;
	; 5/6/92: allow ourselves to be called on a VM block if the thing is
	; swapped out, as that's the only way the Swat stub has of forcing a
	; swapped block into memory. Not allowing this causes horrible random
	; death when attempting to pobj objects in a VM file when their blocks
	; have been swapped out -- ardeb
	; 
EC <	push	bx							>
EC <	mov	bx, ds:[bx].HM_owner					>
EC <	cmp	ds:[bx].HG_type, SIG_VM					>
EC <	pop	bx							>
EC <	jne	isOK							>
EC <	test	ds:[bx].HM_flags, mask HF_SWAPPED			>
EC <	ERROR_Z	MEM_LOCK_PASSED_A_BLOCK_IN_A_VM_FILE			>
EC <isOK:								>

	; non-ec: verify handle

NEC <	FAST_CHECK_HANDLE_LEGAL						>

	FastLock1	ds, bx, ax, ML_1, ML_2	;ax <- seg addr of block

	.leave
	ret

	; FastLock2	ds, bx, ax, ML_1, ML_2

	; if the block is a resource, use LockDiscardedResource to read it
	; back in

???_ML_2	label	near
	INT_ON
	call	PHeap
	test	ds:[bx].HM_flags, mask HF_DISCARDED
	jz	notAResource
if ERROR_CHECK
NOFXIP <cmp	bx, ds:[bx].HM_owner					>
NOFXIP <ERROR_E	LOCKING_DISCARDED_CORE_BLOCK				>
endif
FXIP <	cmp	bx, ds:[bx].HM_owner					>
FXIP <	je	lockingCoreblock					>
	push	bx
	call	HandleToID			;is it a resource ?
	pop	bx
	jc	notAResource
	call	VHeap

	push	es
	mov	es, ax
	call	UnlockES			;unlock owner's core block
	pop	es
lockingCoreblock::
	call	LockDiscardedResource
	clc					;return no error
	jmp	???_ML_1

notAResource:
	call	VHeap
	
	call	FullLockNoReload
	; the extra PHeap here (i.e. delaying the VHeap until after the
	; FullLockNoReload) is required to prevent multiple things from
	; attempting to swap in the same block, should AllocateHandleAndBytes
	; try to release the heapSem to allow other people to do things. Of
	; couse, this means that that attempt to release the semaphore is
	; hopeless, and I will soon change the code to realize it and just
	; give up right then... A potentially better solution here would be
	; a semaphore just for swapping stuff in, so other people could
	; free up memory but people couldn't swap in the same block at the
	; same time -- ardeb 5/11/94

	; It seems to me that, since the heap is P'd while attempting to swap
	; in a block, and since all of the swapping and allocation code
	; checks for and handles the case of someone else swapping in our
	; block, the extra PHeap is unneccessary.  Changed order to
	; VHeap before FullLockNoReload. -dhunter 8/25/2000

	jmp	???_ML_1

NearLock	endp

NearLockDS	proc	near
	call	NearLock
	mov	ds, ax				;ds <- seg addr of block
	ret
NearLockDS	endp

NearLockES	proc	near
	call	NearLock
	mov	es, ax				;es <- seg addr of block
	ret
NearLockES	endp

UnlockES	proc	near
	push	bx
	mov	bx, es:[GH_geodeHandle]
	call	NearUnlock
	pop	bx
	ret
UnlockES	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemLock

C DECLARATION:	extern void _far *
			_far _pascal MemLock(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Returns NULL (0) if block is discarded.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMLOCK	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	clr	dx
	call	NearLock
EC <	push	ds							>
EC <	jc	skipCheck						>
EC <	LoadVarSeg	ds						>
EC <	test	ds:[bx].HM_flags, mask HF_LMEM				>
EC <	jz	skipCheck						>
EC <	mov	ds, ax							>
EC <	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	WARNING_Z	CANNOT_CALL_MEM_LOCK_ON_AN_OBJECT_BLOCK		>
EC <skipCheck:								>
EC <	pop	ds							>
	xchg	ax, dx
	ret

MEMLOCK	endp
	SetDefaultConvention


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemLock

DESCRIPTION:
	Return the absolute address of the block of memory pointed to by
	the given handle.  Lock the block by incrementing its lock count.
	Locked memory cannot be moved or discarded.

CALLED BY:	GLOBAL

PASS:
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
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

MemLock	proc	far
EC <	call	AssertInterruptsEnabled					>
	call	NearLock
EC <  	pushf								>
EC <	push	ds							>
EC <	jc	skipCheck						>
EC <	LoadVarSeg	ds						>
EC <	test	ds:[bx].HM_flags, mask HF_LMEM				>
EC <	jz	skipCheck						>
EC <	;it's okay if we aren't the first lock'er (ignore small timing hole >
EC <	;where another thread could have locked between NearLock and here) >
EC <	cmp	ds:[bx].HM_lockCount, 1					>
EC <	ja	skipCheck						>
EC <	mov	ds, ax							>
EC <	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	WARNING_Z	CANNOT_CALL_MEM_LOCK_ON_AN_OBJECT_BLOCK		>
EC <skipCheck:								>
EC <	pop	ds							>
EC <  	popf								>
	ret
MemLock	endp

if	ERROR_CHECK
global MemLockSkipObjCheck:far
MemLockSkipObjCheck	proc	far
EC <	call	AssertInterruptsEnabled					>
	call	NearLock
	ret
MemLockSkipObjCheck	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NearUnlock

DESCRIPTION:	Call MemUnlock from within the kernel

CALLED BY:	EXTERNAL

PASS:
	Same as MemUnlock

RETURN:
	Same as MemUnlock

DESTROYED:
	Same as MemUnlock

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

NearUnlock	proc	near
	call	MemUnlock		; Again, don't do error checking
					; if called from within the kernel
					; (see NearLock)
	ret

NearUnlock	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemUnlock

C DECLARATION:	extern void
			_far _pascal MemUnlock(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMUNLOCK	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	; for the benefit of C, make this work on virtual segments

	cmp	bh, 0xf0
	jb	notVirtual
	shl	bx
	shl	bx
	shl	bx
	shl	bx
notVirtual:

;	ES can be biffed by C routines, so let's null it out here. This fixes
;	the problem where you have a block locked by 2 threads, and thread
;	1 unlocks it, then thread 2 unlocks it - if thread 1 is written in
;	C, there's no way to null out ES to avoid getting segment deaths
;	when thread 2 finally unlocks the block.
		
EC <	call	NullES							>

	FALL_THRU	MemUnlock

MEMUNLOCK	endp
	SetDefaultConvention


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemUnlock

DESCRIPTION:
	Unlock the given block of memory by decrementing its lock count.
	If the lock count reaches zero then the block is subject to moving
	or discarding.

CALLED BY:	GLOBAL

PASS:
	bx - handle to block of memory to unlock

RETURN:
	none

DESTROYED:
	Non-EC: Nothing (flags preserved)

	EC:	Nothing (flags preserved), except, possibly for DS and ES:

		If segment error-checking is on, and either DS or ES
		is pointing to a block that has become unlocked,
		then this register will be set to NULL_SEGMENT upon
		return from this procedure. 




REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Update block's usage value and decrement its lock count

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added
	ardeb	4/17/94		Changed unlockMove code to always work.

-------------------------------------------------------------------------------@

MemUnlock	proc	far
	pushf
	push	ax
	push	ds
	LoadVarSeg	ds, ax

EC <	test	ds:[bx].HM_flags, mask HF_LMEM				>
EC <	jnz	10$							>
EC <	push	bx							>
EC <	mov	bx, ds:[bx].HM_owner					>
EC <	cmp	ds:[bx].HG_type, SIG_VM					>
EC <	pop	bx							>
EC <	ERROR_Z	MEM_UNLOCK_PASSED_A_BLOCK_IN_A_VM_FILE			>
EC <10$:								>

	; non-ec: verify handle

NEC <	FAST_CHECK_HANDLE_LEGAL						>

if	ANALYZE_WORKING_SET
	call	WorkingSetObjBlockNotInUse
endif

	FastUnLock	ds, bx, ax, NO_NULL_SEG

	pop	ds
EC <	call	NullSegmentRegisters					>

	; if "ec unlockMove" is on and lockCount is 0 then move the block
	; (moved after the NullSegmentRegisters to before that happens if
	; the block reaches a lock count of 0...)

if	ERROR_CHECK
	push	ds, cx
	LoadVarSeg	ds
	test	ds:[sysECLevel], mask ECF_UNLOCK_MOVE
	jz	done
	tst	ds:[bx].HM_lockCount
	jnz	done

if LOG_BLOCK_MOVEMENT
	mov	ax, BMO_UNLOCK
	call	LogBlockMovement
endif

	;
	; added check to see if the current Thread owns the heap
	; semaphore (the heap may be inconsistent)
	;
	mov	cx, ds:[currentThread]
	cmp	cx, ds:[heapSem].TL_owner
	je	done

	mov	cx, TRUE	; block must be unlocked to be moved
	call	MemForceMove
done:
	pop	ds, cx
endif

	pop	ax
	popf
	ret

MemUnlock	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	PHeap, VHeap

DESCRIPTION:	Do a P or a V on the heap semaphore

CALLED BY:	EXTERNAL
		FreeGeodeBlocks, ThreadDestroy, CreateThreadCommon

PASS:
	none

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
	Tony	6/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@


FarVHeap	proc	far
	call	VHeap
	ret
FarVHeap	endp

VHeap	proc	near
EC <	call	AssertInterruptsEnabled					>
	;
	; Release the shared lock we put on the FSIR in PHeap
	; 
	call	FSDUnlockInfoShared

VHeapNoFSIR label near
	push	bx
	mov	bx, offset heapSem
	jmp	SysUnlockCommon
VHeap	endp

FarPHeap	proc	far
	call	PHeap
	ret
FarPHeap	endp
 
PHeap	proc	near
	;
	; Lock FSIR shared, in case we need to swap.
	; 
	push	ax
	call	FSDLockInfoShared
	pop	ax

	push	bx
	mov	bx, offset heapSem
	jmp	SysLockCommon
PHeap	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemGetInfo

DESCRIPTION:	Return information about a block

CALLED BY:	GLOBAL

PASS:
	ax - MemGetInfoType:
			MGIT_SIZE			enum	MemGetInfoType
			MGIT_FLAGS_AND_LOCK_COUNT	enum	MemGetInfoType
			MGIT_OWNER_OR_VM_FILE_HANDLE	enum	MemGetInfoType
			MGIT_ADDRESS			enum	MemGetInfoType
			MGIT_OTHER_INFO			enum	MemGetInfoType
			MGIT_EXEC_THREAD		enum	MemGetInfoType

	bx - handle to block of memory about which to return information

RETURN:
	ax - value dependent on MemGetInfoTypes passed:
			MGIT_SIZE			enum	MemGetInfoType
				ax = size of block in bytes

			MGIT_FLAGS_AND_LOCK_COUNT	enum	MemGetInfoType
				al = HeapFlags
				ah = lock count

			MGIT_OWNER_OR_VM_FILE_HANDLE	enum	MemGetInfoType
				ax = handle of owner

			MGIT_ADDRESS			enum	MemGetInfoType
				ax = segment of block

			MGIT_OTHER_INFO			enum	MemGetInfoType
				ax = HM_otherInfo

			MGIT_EXEC_THREAD		enum	MemGetInfoType
 				ax = handle of thread 
					(or 0 if the handle was a queue)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Return handle's info from handle table

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	The actual size of a block can be larger than the size requested
	since memory is allocated on fixed boundries.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/91		Initial version

-------------------------------------------------------------------------------@

MemGetInfo	proc	far	uses cx, si, ds
	.enter
	LoadVarSeg	ds
	mov_trash	si, ax
EC <	cmp	si, MGIT_EXEC_THREAD					>
EC <	je	skipCheck						>
EC <	call	ECCheckMemHandleNSFar					>
EC <skipCheck:								>

EC <	cmp	si, size globalMemGetInfoTable				>
EC <	ERROR_AE	MEM_GET_INFO_BAD_PARAMETER			>

	call	cs:[globalMemGetInfoTable][si]

	.leave
	ret

MemGetInfo	endp

globalMemGetInfoTable	nptr	\
	GetByteSize,				;MGIT_SIZE
	MGI_FlagsAndLockCount,			;MGIT_FLAGS_AND_LOCK_COUNT
	MGI_OwnerOrVMFileHandle,		;MGIT_OWNER_OR_VM_FILE_HANDLE
	MGI_Address,				;MGIT_ADDRESS
	MGI_OtherInfo,				;MGIT_OTHER_INFO
	MGI_ExecThread				;MGIT_EXEC_THREAD

;---

MGI_FlagsAndLockCount	proc	near
	mov	ax, {word} ds:[bx].HM_flags	;al = flags, ah = lock count
	cmp	ah, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	jnz	notPseudoFixed
	or	al, mask HF_FIXED
	clr	ah
notPseudoFixed:
	ret
MGI_FlagsAndLockCount	endp

;---

MGI_OwnerOrVMFileHandle	proc	near
	mov	si, ds:[bx].HM_owner
	cmp	ds:[si].HG_type, SIG_VM
	jnz	10$
	mov	si, ds:[si].HVM_fileHandle
10$:
	mov_trash	ax, si			;return owner in ax
	ret
MGI_OwnerOrVMFileHandle	endp

;---

MGI_Address	proc	near
	mov	ax, ds:[bx].HM_addr
	ret
MGI_Address	endp

;---

MGI_OtherInfo	proc	near
	mov	ax, ds:[bx].HM_otherInfo
	ret
MGI_OtherInfo	endp

;---

MGI_ExecThread	proc	near

;	If this is a queue, return 0 as the exec thread

	clr	ax
	cmp	ds:[bx].HG_type, SIG_QUEUE
	je	exit

;	If it is a thread, return the thread itself as the exec thread

	mov	ax, bx
	cmp	ds:[bx].HG_type, SIG_THREAD
	je	exit

	mov	ax, ds:[bx].HM_otherInfo
EC <	call	ECCheckMemHandleNSFar					>

	; if it's a VM block then return HVM_execThread

	mov	si, ds:[bx].HM_owner
	cmp	ds:[si].HG_type, SIG_VM
	jnz	exit
	mov	ax, ds:[si].HVM_execThread
exit:
	ret
MGI_ExecThread	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemOwner

C DECLARATION:	extern GeodeHandle
			_far _pascal MemOwner(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMOWNER	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

EC <	call	AssertInterruptsEnabled					>
	call	MemOwner
	mov_trash	ax, bx

	ret

MEMOWNER	endp
	SetDefaultConvention

COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemOwner	(should really be called HandleGetOwner)

DESCRIPTION:	Return the owner field of a handle

CALLED BY:	GLOBAL

PASS:
	bx - handle 

RETURN:
	bx - owner: if the block is owned by a VM file, the process that owns
		    the VM file is returned (unlike MemInfo, which returns the
		    VM file)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Doug	3/93		Changed to deal w/events

-------------------------------------------------------------------------------@

MemOwnerFar	proc	far
	call	MemOwner
	ret
MemOwnerFar	endp

MemOwner	proc	near		uses ds
	.enter

if 0	; I can see no reason for interupts to be on, can you?  - TS 10/05/92
EC <	call	AssertInterruptsEnabled					>
endif

;EC_CONTEXT CONTEXT_CHECKING_HANDLE_IN_MEM_OWNER
EC <	call	CheckHandleLegal					>

	LoadVarSeg	ds

	; non-ec: verify handle

NEC <	call	FastCheckHandleLegal					>

	; Cope with event handles, which store the owner in a non-standard place
	; 
	cmp	ds:[bx].HG_type, SIG_EVENT_REG
	je	getEventOwner
	cmp	ds:[bx].HG_type, SIG_EVENT_STACK
	je	getEventOwner

	mov	bx, ds:[bx].HM_owner
;EC_CONTEXT CONTEXT_CHECKING_OWNER_FIELD
EC <	call	CheckHandleLegal					>

	cmp	ds:[bx].HG_type, SIG_VM
	je	getVMOwner

done:
	; Make sure that the owner is a geode

EC <	call	ECCheckGeodeHandle					>

	.leave
	ret

getEventOwner:
	mov	bx, ds:[bx].HE_next
	andnf	bx, 0fff0h
	jmp	short done

getVMOwner:
	mov	bx, ds:[bx].HVM_fileHandle
	mov	bx, ds:[bx].HG_owner
	jmp	short done

MemOwner	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemModifyFlags

DESCRIPTION:	Modify the flags associated with a block.

CALLED BY:	GLOBAL

PASS:
	bx - handle of block to modify
	al - flags to be set in HM_flags
	ah - flags to be cleared in HM_flags. The following bits can be
	     altered: HF_SHARABLE, HF_DISCARDABLE, HF_SWAPABLE, HF_LMEM

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Modify block's flags as passed.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

	; Bits that may be modified
MM_MASK		=	mask HF_DISCARDABLE or mask HF_SWAPABLE or \
			mask HF_SHARABLE or mask HF_LMEM

MemModifyFlags	proc	far
	push	ds
	LoadVarSeg	ds

EC <	call	ECCheckMemHandleNSFar					>
EC <	test	ax, not (MM_MASK or (MM_MASK shl 8))			>
EC <	ERROR_NZ	MODIFY_BAD_FLAGS				>
EC <	call	AssertInterruptsEnabled					>

	not	ah		; invert so we clear indicated bits
	and	ds:[bx].HM_flags, ah
	or	ds:[bx].HM_flags, al

	FALL_THRU	ModifyCommon, ds

MemModifyFlags	endp

;---

ModifyCommon	proc	far
	mov	al,DEBUG_MODIFY		;notify debugger of block modification
	call	FarDebugMemory

	FALL_THRU_POP	ds
	ret
ModifyCommon	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	HandleModifyOwner

DESCRIPTION:	Modify the owner of a block.  If passed a process handle,
		change the parent process instead of the owner.

CALLED BY:	GLOBAL

PASS:
	bx - handle of block to modify
	ax - block's new owner

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Modify block's flags as passed.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

HandleModifyOwner	proc	far

EC <	call	CheckHandleLegal					>

	push	ds
	LoadVarSeg	ds

	; Make sure that the new owner is a geode

EC <	xchg	bx, ax							>
EC <	call	ECCheckGeodeHandle					>
EC <	xchg	bx, ax							>

	;
	; Cope with event handles, which store the owner in a non-standard
	; place, so none of the usual stuff is safe.
	; 
	cmp	ds:[bx].HG_type, SIG_EVENT_REG
	je	changeEventOwner
	cmp	ds:[bx].HG_type, SIG_EVENT_STACK
	je	changeEventOwner

	; Check for modifying parent process of a geode

	cmp	bx, ds:[bx].HM_owner
	jnz	notGeode
	push	ax
	call	NearLockDS
	pop	ds:[GH_parentProcess]
	call	UnlockDS
	jmp	done
notGeode:

EC <	push	ax							>
	; Check for a legal handle type

EC <	mov	al, ds:[bx].HG_type					>
EC <	cmp	al, SIG_TIMER						>
EC <	jz	checkCurrentOwner					>
EC <	cmp	al, SIG_THREAD						>
EC <	jz	checkCurrentOwner					>
EC <	cmp	al, SIG_QUEUE						>
EC <	jz	checkCurrentOwner					>
EC <	cmp	al, SIG_FILE						>
EC <	jz	checkCurrentOwner					>
EC <	cmp	al, SIG_SEMAPHORE					>
EC <	jz	checkCurrentOwner					>
EC <	call	ECCheckMemHandleNSFar					>
EC <checkCurrentOwner:							>

	; Make sure block is owned by current thread now

EC <	mov	ax, ss:[TPD_processHandle]				>
EC <	cmp	ax, ds:[bx].HM_owner					>
EC <	jz	canChangeOwner						>
EC <	test	ds:[bx].HM_flags, mask HF_SHARABLE			>
EC <	ERROR_Z	CANNOT_CHANGE_OWNER					>
EC <canChangeOwner:							>

EC <	pop	ax							>

HMA <	cmp	ds:[bx].HG_type, SIG_UNUSED_FF				>
HMA <	je	isMem							>

	cmp	ds:[bx].HG_type, SIG_NON_MEM
	jbe	modifyNonMem
HMA <isMem:								>

	mov	ds:[bx][HG_owner],ax

	GOTO	ModifyCommon, ds


modifyNonMem:
	;
	; No need to notify Swat of these changes,
	; 
	mov	ds:[bx].HG_owner, ax
done:
	pop	ds
	ret

changeEventOwner:
EC <	push	ax							>
EC <	mov	ax, ss:[TPD_processHandle]				>
EC <	cmp	ds:[bx].HE_next, ax					>
EC <	je	bleah							>
EC <	ERROR	CANNOT_CHANGE_OWNER					>
EC <bleah:								>
EC <	pop	ax							>
   	andnf	ds:[bx].HE_next, 0xf
	ornf	ds:[bx].HE_next, ax
	jmp	done
HandleModifyOwner	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemModifyOtherInfo

DESCRIPTION:	Modify the other info associated with a block.

CALLED BY:	GLOBAL

PASS:
	bx - handle of block to modify
	ax - new HM_otherInfo value

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Modify block's flags as passed.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

MemModifyOtherInfo	proc	far
	push	ds
	LoadVarSeg	ds

EC <	call	ECCheckMemHandleNSFar					>
EC <	call	AssertInterruptsEnabled					>

	mov	ds:[bx].HM_otherInfo, ax

	GOTO	ModifyCommon, ds

MemModifyOtherInfo	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	HandleP

C DECLARATION:	extern void
			far HandleP(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
HANDLEP	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	FALL_THRU	HandleP

HANDLEP	endp
	SetDefaultConvention

COMMENT @-----------------------------------------------------------------------

FUNCTION:	HandleP

DESCRIPTION:	Set a semaphore on the given block, providing the caller with
		exclusive access to the block (providing that all processes
		use the HandleP/HandleV mechanism).  The "HM_otherInfo"
		field of the block is used for the semaphore and must not be
		used for any other purpose.

		HandleP/HandleV can be used on memory handles and it can be
		used on file handles.

CALLED BY:	GLOBAL

PASS:
	bx - handle of block to own

RETURN:
	bx - same

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Use "HM_otherInfo" field to store the state of the semaphore.  Possible
	values are:
		1 - Not owned
		0 - Owned, no threads waiting
		other - Owned, handle to first thread waiting

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@


INCLUDE_HANDLE_P_DEADLOCK_HELPER_CODE	= FALSE
;
; A little code here to help track down horrible problems where 
; somebody's P'd a block, but forgotten to "V" it.  Is currently
; written for scenerios where the handle having this problem is
; known in advance.  Use "imem hpHandle" to setup the word handle to watch
; for.  Once the deadlock occurs, type "phan hpThread" to see which
; thread was the last to successfully "P" the block, & then type
; "dump hpStack" to see what code was running at the time.
; 					- Doug 6/3/92

if	(INCLUDE_HANDLE_P_DEADLOCK_HELPER_CODE)
idata	segment
hpHandle	word
hpThread	word
hpStack		word 20 dup (?)
idata	ends
endif


HandleP	proc	far
	push	ds
	LoadVarSeg	ds

	; non-ec: verify handle

NEC <	call	FastCheckHandleLegal					>

	FastMemP	ds, bx			; this calls CheckToP

if	(INCLUDE_HANDLE_P_DEADLOCK_HELPER_CODE)
	pushf
	cmp	bx, ds:[hpHandle]
	jne	skipRecord

	push	ax, cx, si, di, ds, es
	mov	ax, ss:[0]		; get handle of current running thread
	mov	ds:[hpThread], ax	; save away to analyze after deadlock
	mov	ax, ds			; get es:di = hpStack
	mov	es, ax
	mov	di, offset hpStack
	mov	ax, ss			; get ds:si = ss:sp + 2*7
	mov	ds, ax
	mov	si, sp
	add	si, 2*7
	mov	cx, 20			; copy stack contents over
	cld
	rep	movsw
	pop	ax, cx, si, di, ds, es

skipRecord:
	popf
endif

	pop	ds
	ret

HandleP	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemUnlockV, NearUnlockV

DESCRIPTION:	Do a MemUnlock followed by a HandleV

CALLED BY:	GLOBAL

PASS:
	bx - handle of memory block

RETURN:

DESTROYED:
	Nothing (even flags preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

-------------------------------------------------------------------------------@

NearUnlockV	proc	near
	call	MemUnlockV
	ret
NearUnlockV	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemUnlockV

C DECLARATION:	extern void
			_far _pascal MemUnlockV(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMUNLOCKV	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	FALL_THRU	MemUnlockV

MEMUNLOCKV	endp
	SetDefaultConvention

MemUnlockV	proc	far
	push	ds
	push	ax
	pushf
	LoadVarSeg	ds
	FastUnLock	ds, bx, ax, NO_NULL_SEG
	popf
	pop	ax
EC <	pop	ds							>
EC <	call	NullSegmentRegisters					>
EC <	push	ds							>
EC <	LoadVarSeg	ds						>
	jmp	short HandleVMiddle

MemUnlockV	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	HandleV

C DECLARATION:	extern void
			far HandleV(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
HANDLEV	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	FALL_THRU	HandleV

HANDLEV	endp
	SetDefaultConvention

COMMENT @-----------------------------------------------------------------------

FUNCTION:	HandleV

DESCRIPTION:	Release a semaphore on the given block.

CALLED BY:	GLOBAL

PASS:
	bx - handle of block to release

RETURN:
	bx - same

DESTROYED:
	Nothing  (even flags preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Use "HM_otherInfo" field to store the state of the semaphore.  Possible
	values are:
		1 - Not owned
		0 - Owned, no threads waiting
		other - Owned, handle to first thread waiting

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

HandleV	proc	far
	push	ds
	LoadVarSeg	ds

HandleVMiddle label far

	pushf

	; non-ec: verify handle

NEC <	call	FastCheckHandleLegal					>

; nuked 2/10/92 to avoid death when called from MemUnlockShared -- ardeb
;EC <	call	AssertInterruptsEnabled					>

	FastMemV1	ds, bx, MV_1, MV_2	; calls CheckToV
	popf

	pop	ds
	ret

	FastMemV2	ds, bx, MV_1, MV_2

HandleV	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemThreadGrab

C DECLARATION:	extern void _far *
			_far _pascal MemThreadGrab(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Returns NULL (0) if block is discarded.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMTHREADGRAB	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	clr	dx
	call	MemThreadGrab
	xchg	ax, dx
	ret

MEMTHREADGRAB	endp
	SetDefaultConvention

COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemThreadGrab

DESCRIPTION:	Lock a block and set a semaphore on the block so that the
		current thread can do more MemThreadGrab's but other threads
		will block on MemThreadGrab.  If the block is discarded then
		it must be a resource block.

CALLED BY:	GLOBAL

PASS:
	bx - handle of block to ThreadGrab

RETURN:
	if block resident:
		carry clear
		ax - segment address of block of memory
	else (block discarded):
		carry set
		ax - 0

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	Doug	12/6/88		Fixed bug in case of blocked on long queue,
				unblocked & shortly thereafter time-sliced out
	Adam	12/15/89	Changed to use MemThreadGrabCommon

-------------------------------------------------------------------------------@

MemThreadGrabFar	proc	far
	call	MemThreadGrab
	ret
MemThreadGrabFar	endp

MemThreadGrab	proc	near
	call	MemThreadGrabCommon
	jc	mustWait
	tst	ax
	jnz	done
	stc				;indicate discarded
done:
	INT_ON
	ret

mustWait:
	;
	; Use the otherInfo as a queue and wait for it.
	;
	push	ds
	LoadVarSeg	ds, ax		; ds, ax <- idata
	push	bx
	add	bx,HM_otherInfo		;pass offset of semaphore
	call	BlockOnLongQueue	;put current thread on waiting queue
					;when returns, will have been put into
					; HM_usageValue for us by
					; MemThreadRelease.
	pop	bx			; Recover handle
	mov	ax,ds:[bx][HM_addr]	; Fetch segment
	pop	ds			; Restore entry ds
	clc
	jmp	done			; wheeeeee
MemThreadGrab	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemThreadGrabNB

C DECLARATION:	extern void _far *
			_far _pascal MemThreadGrabNB(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Returns NULL (0) if block is discarded.
	Returns BLOCK_GRABBED (1) if block is already grabbed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMTHREADGRABNB	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	clr	dx
	call	MemThreadGrabNB
	xchg	ax, dx
	jnc	done
	inc	ax
done:
	ret

MEMTHREADGRABNB	endp
	SetDefaultConvention


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemThreadGrabNB

DESCRIPTION:	Similar to MemThreadGrab but will not block if the block is
		already grabbed. Returns carry set if block couldn't be grabbed.

CALLED BY:	GLOBAL

PASS:
	bx - handle of block to ThreadGrab

RETURN:
	if block not discarded:
		carry clear if successful
		ax - segment address of block of memory
	else
		carry clear, ax = 0

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/89		Initial version

-------------------------------------------------------------------------------@

MemThreadGrabNB	proc	far
	call	MemThreadGrabCommon
	INT_ON				; make sure...
	ret
MemThreadGrabNB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemThreadGrabCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to grab a block for the current thread.

CALLED BY:	INTERNAL
       		MemThreadGrab, MemThreadGrabNB
PASS:		bx	= handle to grab
RETURN:		ax	= segment of block, if grab successful (0 if block
			  discarded and not grabbed)
		carry set if block already grabbed
		INTERRUPTS OFF
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Use "HM_otherInfo" field to store the state of the semaphore.  Possible
	values are:
		1 - Not owned
		0 - Owned, no threads waiting
		other - Owned, handle to first thread waiting

	While the block is locked/owned, the usageValue field contains the
	handle of the thread that has possession of the block.

	if (HM_otherInfo == 1) {
		HM_otherInfo = 0;
		HM_usageValue = 0;
		lock block
gotIt:
		HM_usageValue = currentThread;
		return(data address)
	} else if (currentThread == HM_usageValue) {
		HM_lockCount++
		return(data address)
	} else {
		wait on block
		goto gotIt
	}
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemThreadGrabCommon	proc	near	uses	ds
		.enter
		LoadVarSeg	ds

EC <		call	CheckToLock					>

	; non-ec: verify handle

NEC <	FAST_CHECK_HANDLE_LEGAL						>

		INT_OFF				;ensure consistency

		;
		; See if the block is already owned by someone
		;
		cmp	ds:[bx][HM_otherInfo],1
		jnz	owned

		;
		; If block is discarded, we can't grab it, but don't want
		; to return that we didn't grab it because it was owned, so
		; return ax 0, but carry clear to indicate the discarded
		; nature of the thing.
		; 
		clr	ax			;assume discarded
		test	ds:[bx].HM_flags, mask HF_DISCARDED
		jnz	done

		;
		; It's ours: set the otherInfo field to 0 to denote an empty
		; queue and store the current thread in the usageValue field to
		; denote the owner of the block.
		;
		mov	ds:[bx][HM_otherInfo],0
		mov	ax,ds:[currentThread]
		mov	ds:[bx][HM_usageValue],ax

		;
		; Now lock the block down, using FastLock in case the block is
		; swapped or a discarded resource block.
		;
		FastLock1	ds, bx, ax, FL1, FL2
;EC <		ERROR_C	GRAB_DISCARDED					>

		jmp	returnGrabbed

		; Block is swapped

		FastLock2	ds, bx, ax, FL1, FL2

owned:
		; error-checking to make sure the otherInfo field contains 0 or
		; the valid head of a queue
EC <		push	bx						>
EC <		mov	bx,ds:[bx][HM_otherInfo]			>
EC <		tst	bx						>
EC <		jz	MTG_1						>
EC <		call	ECCheckThreadHandle				>
EC <MTG_1:								>
EC <		pop	bx						>

		;
		; See if we've already got the block grabbed.
		;
		mov	ax,ds:[currentThread]
		cmp	ax,ds:[bx][HM_usageValue]
		jne	mustWait

		;
		; It's ours -- just have to increase the lock count and fetch
		; the address of the block as it must be in memory for us to
		; have grabbed it.
		;
EC <		cmp	ds:[bx][HM_lockCount],MAX_LOCKS			>
EC <		ERROR_E	THREAD_GRAB_TOO_MANY_LOCKS			>

		inc	ds:[bx][HM_lockCount]
		mov	ax,ds:[bx][HM_addr]
returnGrabbed:
		clc				;return in memory
done:
		.leave
		ret
mustWait:
		clr	ax			;return 0 in case loaded into
						; segment before carry checked
						; (q.v. VMBlockBiffableLow)
		stc				;signal block not grabbed
		jmp	done
MemThreadGrabCommon	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemThreadRelease

C DECLARATION:	extern void
			_far _pascal MemThreadRelease(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMTHREADRELEASE	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	FALL_THRU	MemThreadReleaseFar

MEMTHREADRELEASE	endp
	SetDefaultConvention


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MemThreadRelease

DESCRIPTION:	Undo a ThreadGrab

CALLED BY:	GLOBAL

PASS:
	bx - handle of block to ThreadRelease

RETURN:

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Use "HM_otherInfo" field to store the state of the semaphore.  Possible
	values are:
		1 - Not owned
		0 - Owned, no threads waiting
		other - Owned, handle to first thread waiting

	if (HM_lockCount == 1) {
		if (HM_otherInfo == 0) {
			HM_lockCount = 0;
			update HM_usageValue
			HM_otherInfo = 1;
		} else {
			wake up (other info)
		}
	} else {
		HM_lockCount--
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	Doug	12/6/88		Fixed bug in case of blocked on long queue,
				unblocked & shortly thereafter time-sliced out

-------------------------------------------------------------------------------@

MemThreadReleaseFar	proc	far
			call	MemThreadRelease
			ret
MemThreadReleaseFar	endp

MemThreadRelease	proc	near
	pushf				; preserve interrupt state

	push	ax
	push	ds
	LoadVarSeg	ds, ax		; ax, ds <= idata

EC <	call	CheckToUnlockNS						>
EC <	call	AssertInterruptsEnabled					>

	; non-ec: verify handle

NEC <	FAST_CHECK_HANDLE_LEGAL						>

	INT_OFF				;ensure consistency

	;
	; Are we releasing the last grab for this block?
	;
	cmp	ds:[bx][HM_lockCount],1
	jnz	multipleLocks

	;
	; Last grab -- make sure the handle's in a reasonable state
	;
EC <	push	ax							>
EC <	mov	ax,ds:[currentThread]					>
EC <	cmp	ax,ds:[bx][HM_usageValue]				>
EC <	ERROR_NE THREAD_RELEASE_NOT_OWNER				>
EC <	pop	ax							>

if ERROR_CHECK
	;
	; If DS or ES points to the block, null it, since the block is
	; effectively unlocked, as far as this thread is concerned
	;
	call	CheckSegmentECEnabled
	jz	nullSegDone
	pop	ax		; ax <- DS on entry
	cmp	ax, ds:[bx].HM_addr
	jne	setDS
	mov	ax, NULL_SEGMENT
setDS:
	push	ax		; put DS-on-entry back on the stack
				; (possibly now "NULL_SEGMENT")
	mov	ax, es
	cmp	ax, ds:[bx].HM_addr
	jne	setES
	mov	ax, NULL_SEGMENT
setES:
	mov	es, ax
nullSegDone:

endif	; ERROR_CHECK

	;
	; Anyone waiting?
	;
	cmp	ds:[bx][HM_otherInfo],0
	jnz	mustWakeUp

	;
	; No-one there -- treat this as a regular unlock, setting the usage
	; value correctly, but set the otherInfo field to 1 to indicate the
	; lack of a grab on the block.
	; 
	mov	ax,ds:[systemCounter.low]
	mov	ds:[bx][HM_usageValue],ax
	mov	ds:[bx][HM_otherInfo],1
multipleLocks:
	dec	ds:[bx][HM_lockCount]	; reduce lock count by 1 (to 0 if was
					;  last grab)
done:
	pop	ds
	pop	ax
	call	SafePopf		; recover flags & interrupt state
	ret

mustWakeUp:
	;
	; Wake up the highest-priority thread on the queue after giving
	; it ownership of the block, which stays locked.
	;
	push	si
	push	es, bx, cx, dx, di
	LoadVarSeg	es, ax
	add	bx, HM_otherInfo		; es:bx = queue
	call	RemoveFromQueue
	pop	es, bx, cx, dx, di
	mov	ds:[bx].HM_usageValue, si	; pass the torch
	call	WakeUpSI
	pop	si
	jmp	done

MemThreadRelease	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MemSegmentToHandle

DESCRIPTION:	Given a segment value, return the corresponding handle

CALLED BY:	GLOBAL

PASS:
	cx - segment address

RETURN:
	carry - set if a matching handle is found
	cx - handle

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

MemSegmentToHandle	proc	far
	call	SegmentToHandle
	ret
MemSegmentToHandle	endp

if	0
SegmentToHandleWithIntOff	proc	far	uses bx, dx
	.enter 
	; first check for virtual segment
HMA <	cmp	cx, HMA_SEGMENT			;check hi-mem segment	>
HMA <	je	realSegment						>
	cmp	ch, high MAX_SEGMENT
	jb	realSegment
	shl	cx
	shl	cx
	shl	cx
	shl	cx
EC <	xchg	bx, cx							>
EC <	call	ECCheckMemHandleFar					>
EC <	xchg	bx, cx							>
	jmp	found
realSegment:
	; first try segment:[LMBH_handle]
	pushf
	push	ds
	mov	ds, cx
	mov	bx, ds:[LMBH_handle]
	INT_OFF
	LoadVarSeg	ds
	call	SegmentToHandleBody
	pop	ds
	jnc	notFound
	call	SafePopf
found:
	stc
exit:
	.leave
	ret
notFound:
	call	SafePopf
	clc
	jmp	exit
SegmentToHandleWithIntOff	endp
endif	;ERROR_CHECK

SegmentToHandle	proc	near	uses bx, ds, dx
	.enter
	; first check for virtual segment

HMA <	cmp	cx, HMA_SEGMENT			;check hi-mem segment	>
HMA <	je	realSegment						>
	cmp	ch, high MAX_SEGMENT
	jb	realSegment
	shl	cx
	shl	cx
	shl	cx
	shl	cx
EC <	xchg	bx, cx							>
EC <	call	ECCheckMemHandleFar					>
EC <	xchg	bx, cx							>
	stc
	jmp	exit

realSegment:

	; first try segment:[LMBH_handle]

	mov	ds, cx
	mov	bx, ds:[LMBH_handle]
	LoadVarSeg	ds

						;ensure exclusive access
						; DO NOT USE PHEAP, as that
						; will also get the FSIR,
						; which screws up
						; NullSegmentRegisters

	LockModule	ds:[currentThread], ds, heapSem

	call	SegmentToHandleBody

	call	VHeapNoFSIR			;release exclusive access
exit:
	.leave
	ret

SegmentToHandle	endp



SegmentToHandleBody	proc	near

if	FULL_EXECUTE_IN_PLACE
	sub	cx, ds:[loaderVars].KLV_mapPageAddr
	jc	notXIP
	cmp	cx, MAPPING_PAGE_SIZE/16
	jae	notXIP

	push	es, ax

;	We have a resource mapped in from the XIP image - do a lookup
;	in the handleAddressTable


	shl	cx, 1
	shl	cx, 1
	shl	cx, 1
	shl	cx, 1

	mov	ax, ds:[curXIPPage]
	mov	es, ds:[loaderVars].KLV_xipHeader

;	See if this is the cached segment, by looking up the associated handle
;	table entry to see if that's what is currently mapped in

	cmp	cx, ds:[sthCacheSegment]
	jnz	notCachedXIP
	mov	bx, ds:[sthCacheHandle]
	mov	dx, bx
	sub	bx, ds:[loaderVars].KLV_handleTableStart
	shr	bx
	shr	bx
	add	bx, es:[FXIPH_handleAddresses]
	cmpdw	es:[bx], axcx
	je	xipFound
	
notCachedXIP:

	mov	dx, es:[FXIPH_handleTableStart]	;DX <- first handle in the
						; system
	mov	bx, es:[FXIPH_handleAddresses]	;BX <- associated entry in
						; handleAddresses table
xipSearch:

;	Scan through the handleAddresses table, to see which resource in the
;	image CX maps to.
;
;	DX <- handle we are currently checking against
;	BX <- offset in handleAddresses table that holds the information about
;		the handle in DX
;
;	AX <- page of the XIP image that is currently mapped in
;	CX <- offset into logical page where the segment data lies
;
;	handleAddresses table has two words of information for each handle in
;	the XIP image:
;
;	high word - logical page number in the XIP image
;	low word - offset in the logical page where data lies

	cmpdw	es:[bx], axcx
	je	xipFound
	add	dx, size HandleGen
	add	bx, size dword
	cmp	dx, LAST_XIP_RESOURCE_HANDLE
	jbe	xipSearch
	pop	es, ax
	jmp	notFound
xipFound:
	pop	es, ax
	mov	bx, dx
	jmp	found

notXIP:
	add	cx, ds:[loaderVars].KLV_mapPageAddr
endif

	
	; Make sure the thing's in bounds
	
	test	bx, 0xf				; valid handle ID?
	jnz	10$
	cmp	bx, ds:[loaderVars].KLV_lastHandle	; after table?
	jae	10$
	cmp	bx, ds:[loaderVars].KLV_handleTableStart
	jb	10$

	cmp	ds:[bx].HM_owner, 0		; want to return only alloc'd
	jz	10$				;  handle so caller gets error
						;  if segment points to free

	cmp	cx, ds:[bx].HM_addr
	jz	found2

	cmp	bx, ds:[handleBeingSwappedDontMessWithIt]
	je	found2
10$:

	; next look in our handy one level cache

	cmp	cx, ds:[sthCacheSegment]
	jnz	notCached
	mov	bx, ds:[sthCacheHandle]

	cmp	cx,ds:[bx].HM_addr
	jz	found2

	cmp	bx, ds:[handleBeingSwappedDontMessWithIt]
	je	found2
notCached:

	; do it the slow way

	mov	bx, ds:[loaderVars].KLV_handleBottomBlock
	mov	dx, bx

	; loop through heap until we've wrapped around

STH_loop:
	cmp	cx,ds:[bx].HM_addr
	jz	found
	mov	bx,ds:[bx].HM_next
	cmp	bx,dx
	jnz	STH_loop

	; we've wrapped around -- segment not found
FXIP <notFound:								>
	clr	cx			;return 0 and clear carry
	jmp	done

	; found -- store as the cached value and return handle, unless
	; handleBeingSwappedDontMessWithIt is non-zero, in which case it's
	; vital that the cached segment & handle remain as the block that's
	; being swapped out, or else segment registers that point to the
	; block that's being swapped get set to NULL_SEGMENT and death
	; rapidly results.

found:
	tst	ds:[handleBeingSwappedDontMessWithIt]
	jnz	found2
	mov	ds:[sthCacheSegment],cx
	mov	ds:[sthCacheHandle],bx
found2:
	stc
	mov	cx,bx
done:
	ret
SegmentToHandleBody	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetByteSize, ParaToByteAX

DESCRIPTION:	Calculate the size of a block in bytes given it in paragraphs

CALLED BY:	EXTERNAL
		GetByteSize - DoZeroInit, MemInfo

		INTERNAL
		ParaToByteAX - MoveBlock, ReadWriteSwap

PASS:
	GetByteSize:
		bx - handle
		ds - kernel data segment
	ParaToByteAX:
		ax - size in paragraphs

RETURN:
	ax, cx - size in bytes
	bx, ds - same

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Chris	10/7/88		Made ParaToByte external and changed name
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

GetByteSizeFar	proc	far
	call	GetByteSize
	ret
GetByteSizeFar	endp

ForceRef GetByteSizeFar		; We need it for EC and language patching.

GetByteSize	proc	near
	mov	ax,ds:[bx][HM_size]
	REAL_FALL_THRU	ParaToByteAX
GetByteSize	endp

ParaToByteAX	proc	near
	mov	cl,4			;shift left four times to multiply by
	shl	ax,cl			;16 to get number of bytes
	mov	cx,ax
	ret

ParaToByteAX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECMemVerifyHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the heap is in a consistent state

CALLED BY:	DoAlloc, MemInfoHeap
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (not even flags)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECMEMVERIFYHEAP	proc	far
if	ERROR_CHECK
	pushf
	push	bx
	push	ds
	LoadVarSeg	ds
	call	PHeap
	call	ECMemVerifyHeapLow
	call	VHeap
	pop	ds
	pop	bx
	popf
endif
	ret

ECMEMVERIFYHEAP	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MemSwap

DESCRIPTION:	Swap memory between two handles

CALLED BY:	EXTERNAL

PASS:
	bx, si - handles for which to swap memory

RETURN:
	memory swapped

DESTROYED:
	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

MemSwap	proc	far
	push	di, ds
	LoadVarSeg	ds
	call	PHeap
	call	SwapHandlesLow
	call	VHeap
	pop	di, ds
	ret

MemSwap	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MemTransfer

DESCRIPTION:	Create a new handle and transfer the given block's memory to it

CALLED BY:	EXTERNAL

PASS:
	Exclusive access to heap
	bx - handle (in memory)
	ds - idata

RETURN:
	bx - new handle
	si - handle passed (discarded)

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	XXX: What about another thread locking this block while we're doing
	this?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

MemTransfer	proc	far
EC <	call	AssertHeapMine						>
	call	DupHandle
	call	FixLinks2		;bx = new handle, fix up links to it
	ornf	ds:[si].HM_flags,mask HF_DISCARDED or mask HF_DISCARDABLE
	mov	ds:[si].HM_addr,0
	mov	ds:[si].HM_lockCount, 0

	mov	al,DEBUG_DISCARD
	xchg	bx,si
	call	FarDebugMemory
	xchg	bx,si

	ret

MemTransfer	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	THREADGETERROR

DESCRIPTION:	Return the thread's most recent error

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	ax - error

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This is both the assembly and the C entry point

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

THREADGETERROR	proc	far
	mov	ax, ss:[TPD_error]
	ret

THREADGETERROR	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	THREADSETERROR

C DECLARATION:	void ThreadSetError(word errno)
	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94	Initial Revision

------------------------------------------------------------------------------@
THREADSETERROR	proc	far
		C_GetOneWordArg ax, bx, cx		
		FALL_THRU	ThreadSetError
THREADSETERROR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadSetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the value of TPD_error

CALLED BY:	GLOBAL
PASS:		ax	- value to set
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadSetError	proc	far
		mov	ss:[TPD_error], ax
		ret
ThreadSetError	endp

		
;==============================================================================
;
;		      SHARED MEMORY LOCK/UNLOCK
;
;==============================================================================

;
; The locking of shared memory and synchronization between threads cooperating
; to share a block of memory can often be a complex task, and difficult to
; get right. Two kernel mechanisms (HandleP/HandleV and MemThreadGrab/
; MemThreadRelease) exist to aid in this synchronization, but both are rather
; draconian, allowing only a single thread access to the block at once.
;
; Often a block will be used primarily in a read-only fashion by a number of
; threads, with occasionally one wishing to modify the block. MemLockShared and
; MemLockExcl cooperate to allow this to happen. A block may be locked for
; reading, by as many threads as desire it, by calling MemLockShared. When the
; thread is done with the block access, it should call MemUnlockShared. If a
; thread wishes to modify the block's contents, it must call MemLockExcl,
; at which point it will be given exclusive access to the block. When its
; modifications are complete, it should call MemUnlockExcl.
;
; NOTE: AS FOR THE MemThreadGrab/MemThreadRelease MECHANISM, A BLOCK THAT IS
; ACCESSED WITH THESE FUNCTIONS MUST NOT BE LOCKED USING ANY OTHER MECHANISM.
; DOING SO WILL LEAD TO UNPREDICTABLE RESULTS.
;
; The basis for this mechanism is the classic solution to the readers/writers
; problem (as this problem is known). The classic solution involves two
; mutual-exclusion semaphores and a counter, thus:
;
; MemLockShared:			MemLockExcl:
; 	P(mutex);
; 	if (shareCount++ == 0) {
; 		P(excl);		P(excl);
; 	}
; 	V(mutex);
;
; MemUnlockShared:			MemUnlockExcl:
; 	P(mutex);
; 	if (--shareCount == 0) {
;		V(excl);		V(excl);
;	}
;	V(mutex);
;
; The solution is elegant and simple. When the first reader enters the
; critical section, it grabs the writing lock so no writer is allowed in
; until the last reader has exited. If a writer is currently in its critical
; section, the first reader will block in the "write" semaphore, while any
; subsequent readers will block on the "mutex" semaphore, guaranteeing the
; integrity of the shareCount variable.
;
; There is a limited amount of room in a handle, however, so this elegant
; solution is denied to us. We haven't the 5 words it would require to implement
; two standard semaphores and the counter per block, we have only 2 1/2 words:
; 	- HM_otherInfo
; 	- HM_usageValue
; 	- HM_lockCount
;
; HM_otherInfo is used by the FastMemP and FastMemV macros we invoke to
; (sort of) take the place of the P(mutex) and V(mutex) in the classic
; solution. HM_usageValue is set to 0 when the block has been locked via
; MemLockShared, and is always non-zero any other time, whether locked by
; a writer or unlocked. HM_lockCount serves as our shareCount variable. When
; it goes to zero, HandleV is invoked on the block, releasing either a
; reader or a writer to access the block.
;
; The final wrinkle in the implementation comes from the requirement that
; all waiting readers be woken up should a reader be the one awoken by the
; writer that previously had possesion of the block. This function would
; be performed by the first reader, which blocked on the write semaphore
; while the other readers blocked on the mutex semaphore, as it V'd the mutex
; semaphore. The reader released by this V operation would then find the
; shareCount non-zero and immediately V the mutex semaphore again, releasing
; the next reader, and so on until all the readers that had been blocked are
; running again. The solution here is similar, except there's only a
; single queue on which both readers and writers block (HM_otherInfo). When
; a reader awakens from its FastMemP, it sees if anything else is on the
; queue and runs down it looking for another blocked reader, as identified
; by the carry having been set when the thread blocked. The first one found
; is removed from the queue and made runnable. It will perform a similar
; service for another reader, and so on until the queue is empty of all but
; writers.
;
; The first reader to gain access to the block sets its HM_usageValue to
; 0 once the block is locked and before releasing another thread, so any
; reader calling MemLockShared before one of the released readers has a chance
; to zero it will not needlessly block in FastMemP.

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemLockShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a block down for shared (usually read-only) access.

CALLED BY:	GLOBAL
PASS:		bx	= handle of block to be locked.
RETURN:		ax	= segment of locked block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		INT_OFF
		if (usageValue != 0) {
		    ; Not already reading, so gain exclusive access
		    stc		; flag reader blocking
		    HandleP(bx)
		    ; Now lock the block down
		    NearLock(bx)
		    ; Flag shared access
		    usageValue = 0
		    ; If anything blocked on the handle, wake up any reader
		    ; that's present
		    if (otherInfo != 0) {
			foreach thread on queue {
			    if thread ss:sp.TBS_flags & CPU_CARRY {
			    	remove & wake up thread
				break
			    }
			}
		    }
		} else {
		    ; just note another reader in existence
		    lockCount++
		}
		ax <- addr
		INT_ON

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemLockShared	proc	far
		uses	ds
		.enter
	;
	; Point to dgroup, of course.
	;
		LoadVarSeg	ds
EC <		call	CheckToLock	; block must be sharable	>
	;
	; See if shared access already declared. Even though we're careful
	; in setting HM_usageValue when unlocking the block, other people are
	; not, so HM_usageValue, when the block isn't locked at all, can be
	; 0 when we come in here. To deal with this, look at the lock count
	; and always do the HandleP if the block is unlocked when we come in.
	;
		pushf
		INT_OFF
		tst	ds:[bx].HM_lockCount
		jz	notLockedYet

		tst	ds:[bx].HM_usageValue
		jz	alreadySharing
notLockedYet:
	;
	; Nope. Gain exclusive access to the handle. We don't call HandleP
	; here b/c it likes to nuke the carry and we need to have it set
	; when we block so we can distinguish between readers and writers
	; on the queue.
	; 
		stc
		FastMemP	ds, bx, INT_OFF
	;
	; Carry is preserved by FastMemP itself, but gets cleared if we get
	; woken up by MemWakeUpOtherSharers. The problem with the code as it
	; stood was, a low-priority sharer could be woken up but never run to
	; perform this NearLock until after the awakener had already unlocked
	; the block. The awakener would have thought it was the last sharer and
	; released shared-access to the block completely, wreaking havoc when
	; the low-priority sharer came to release the block itself.
	;
	; To get around this, MemWakeUpOtherSharers increments the lock count
	; for the sharer it wakes up, then clears that sharer's carry flag, so
	; it knows, when it gets here, that the block is already locked.
	; 					-- t&a 4/22/93
	; 
		jnc	10$
		call	NearLock
10$:
	;
	; Now wake up another reader, if there's one waiting.
	; 
		call	MemWakeUpOtherSharers
done:
	;
	; Fetch the current address of the block (finally) and get out of
	; here, being careful of how we pop the flags, in case interrupts
	; were off when we came in.
	; 
		mov	ax, ds:[bx].HM_addr
		call	SafePopf
		.leave
		ret
alreadySharing:
	;
	; If the block is already locked shared, as indicated by the
	; HM_usageValue being 0, just up the lock count to signal another
	; reader on the loose.
	; 
		inc	ds:[bx].HM_lockCount
		jmp	done
MemLockShared	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemWakeUpOtherSharers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wake up any other sharers currently blocked on the passed
		block.

CALLED BY:	MemLockShared, MemDowngradeExclLock
PASS:		ds:bx	= handle being locked shared for the first time
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Wake up the first

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemWakeUpOtherSharers proc	near
		uses	bx, es, di, si, bp
		.enter
	;
	; Flag the block as locked for shared access, in case not done yet.
	; 
		mov	ds:[bx].HM_usageValue, 0
		mov	bp, bx		; save in case of wakeup
	;
	; If any reader is blocked on the handle, wake it up.
	;
		; adjust BX so it's like a thread handle, for the purposes
		; of the loop. Of course, BX gets loaded from SI, so...
		lea	si, ds:[bx][offset HM_otherInfo - offset HT_nextQThread]
wakeupLoop:
		mov	bx, si
	;
	; Any next thread? If not, we found no reader but we're still done.
	;
		mov	si, ds:[bx].HT_nextQThread
		tst	si
		jz	doneWakeup
	;
	; See if the carry is set in the flags word saved on the thing's
	; stack. If it is, it means we've got us a reader on our hands.
	; 
		les	di, {dword}ds:[si].HT_saveSP
		test	es:[di].TBS_flags, mask CPU_CARRY
		jz	wakeupLoop

	;
	; Got a thread to wake up. Remove it from the the queue and wake the
	; beastie (SI) up after clearing its carry flag and incrementing
	; the lock count for the block..
	;
		andnf	es:[di].TBS_flags, not mask CPU_CARRY
		inc	ds:[bp].HM_lockCount

		mov	ax, ds:[si].HT_nextQThread
		mov	ds:[bx].HT_nextQThread, ax
		call	WakeUpSI
doneWakeup:
		.leave
		ret
MemWakeUpOtherSharers endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemLockExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a memory block for exclusive read/write access.

CALLED BY:	GLOBAL
PASS:		bx	= block to lock
RETURN:		ax	= segment of locked block.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemLockExcl	proc	far
		uses	ds
		.enter
		LoadVarSeg	ds
		clc				; flag us as a writer
		FastMemP	ds, bx
		call	NearLock
		.leave
		ret
MemLockExcl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemUnlockShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a block that was locked by either MemLockShared or
		MemLockExcl. The operations required for either type of
		access are identical.

CALLED BY:	GLOBAL
PASS:		bx	= handle to be unlocked
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		INT_OFF
		if (--lockCount == 0) {
		    ; set usageValue to unlock time, making sure it's never
		    ; 0, as that indicates the block is read-only
		    usageValue = systemCounter.low | 1
		    HandleV(bx)
		}
		INT_ON

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemUnlockShared	proc	far
		uses	ax
EC <		uses	cx		; cx holds DS to restore in ec	>
NEC <		uses	ds		; just save DS in non-ec	>
		.enter
		pushf
EC <		mov	cx, ds		; save DS and prep for null-seg	>

		LoadVarSeg	ds, ax
NEC <		FAST_CHECK_HANDLE_LEGAL					>
EC <		call	CheckToUnlockNS					>

	;
	; EC: Since we only allow one lock per thread, if either DS or ES
	; points to the block being unlocked, set it to NULL_SEGMENT when
	; ECF_SEGMENT is enabled. This prevents a thread from having one of
	; its segment registers made invalid by some other unlocking a block
	; the one thread previously had locked shared.
	; 
EC <		test	ds:[sysECLevel], mask ECF_SEGMENT		>
EC <		jz	nullSegDone					>
EC <		mov	ax, es						>
EC <		cmp	ax, ds:[bx].HM_addr				>
EC <		jne	setES						>
EC <		mov	ax, NULL_SEGMENT				>
EC <setES:								>
EC <		mov	es, ax						>
EC <		cmp	cx, ds:[bx].HM_addr				>
EC <		jne	nullSegDone					>
EC <		mov	cx, NULL_SEGMENT				>
EC <nullSegDone:							>
   		
		INT_OFF
		dec	ds:[bx].HM_lockCount
		jnz	done		; still locked, so don't release it
	;
	; Set the usage value properly, making sure the result is never 0.
	; 
		mov	ax, ds:[systemCounter].low
		ornf	ax, 1		; ensure non-zero
		mov	ds:[bx].HM_usageValue, ax
	;
	; Release the block, allowing either a reader or a writer access to it.
	; This wakeup is on a priority basis, in contrast to the wakeup of
	; other readers in MemLockRead...
	; 
		FastMemV1	ds, bx, MUS1, MUS2,, INT_OFF
done:
	;
	; All done. Again be careful of interrupts...
	; 
EC <		mov	ds, cx						>
		call	SafePopf
		.leave
		ret

		FastMemV2	ds, bx, MUS1, MUS2

MemUnlockShared	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemUpgradeSharedLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upgrade a shared lock to an exclusive one. If the block is
		locked shared by other threads, this will block and the
		memory block may move on the heap before exclusive access
		is granted.

CALLED BY:	GLOBAL
PASS:		bx	= memory handle locked shared (just once by this
			  thread!) whose lock should be upgraded
RETURN:		ds, es	= fixed up to possibly new block location, if
			  they were pointing to the block on entry.
		ax	= position of locked block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MemUpgradeSharedLock proc	far
		uses	cx
		.enter
	;
	; First figure which, if any, segment registers point to the block
	; at the moment. We use cx to retain this vital information, with
	; bit 0 set if ES was pointing to it, and bit 1 set if DS was
	; pointing to it.
	; 
		clr	cx
		mov	ax, ds
		LoadVarSeg	ds
		cmp	ax, ds:[bx].HM_addr
		jne	checkES
		ornf	cx, 2
checkES:
		push	ax		; save DS in any case
		mov	ax, es
		cmp	ax, ds:[bx].HM_addr
		jne	doTheUpgrade
EC <	; set es to NULL_SEG to avoid ec +segment death if locked by 	>
EC <	; another thread and we have to block				>
EC <		segmov	es, NULL_SEGMENT, ax				>
		ornf	cx, 1
doTheUpgrade:
EC <		tst	ds:[bx].HM_usageValue				>
EC <		ERROR_NZ UPGRADING_SHARED_LOCK_WITHOUT_HAVING_LOCKED_IT_SHARED>
	;
	; Now see if we're the only one who has this block locked shared.
	; If the block is locked more than once, that means more than one
	; thread has it locked shared, so we can't just change the thing to
	; be locked exclusively.
	; 
		INT_OFF
		cmp	ds:[bx].HM_lockCount, 1
		jnz	mustWait
	;
	; It's all ours, so switch the HM_usageValue from 0 to 1 to signal its
	; exclusive use. We leave the HM_otherInfo field as it is -- the place
	; where other exclusive folks might be waiting to get in.
	; 
		mov	ds:[bx].HM_usageValue, 1	; signal exclusivity
	;
	; Upgrade complete. Turn interrupts back on and fetch the address
	; of the block into AX for return and for fixing up the segments.
	; 
		INT_ON
		mov	ax, ds:[bx].HM_addr
finish:
		shr	cx		; ES pointing to block on entry?
		jnc	fixupDS		; => no
		mov	es, ax		; else point it there again.
fixupDS:
		pop	ds		; restore DS in any case
		shr	cx		; DS pointing to block on entry?
		jnc	done		; => no
		mov	ds, ax		; else point it there again.
done:
		.leave
		ret

mustWait:
	;
	; More than one thread has the block locked shared, so we must go
	; through normal channels, after releasing our shared lock on the
	; block by decrementing the lock count.
	; 
		dec	ds:[bx].HM_lockCount
		INT_ON
		call	MemLockExcl
		jmp	finish
MemUpgradeSharedLock		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemDowngradeExclLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Downgrade an exclusive lock to a shared lock, waking any
		shared lockers blocked on the block.

CALLED BY:	GLOBAL
PASS:		bx	= block whose exclusive lock is to be downgraded.
RETURN:		ax	= segment of block, in case you wanted it; block
			  won't actually move during this downgrade.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemDowngradeExclLock proc far
		uses	ds
		.enter
		LoadVarSeg	ds
EC <		call	CheckToUnlockNS					>
EC <		tst	ds:[bx].HM_usageValue				>
EC <		ERROR_Z	DOWNGRADING_EXCL_LOCK_WITHOUT_HAVING_LOCKED_IT_EXCL>
   		call	MemWakeUpOtherSharers
		mov	ax, ds:[bx].HM_addr
		.leave
		ret
MemDowngradeExclLock endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemLockShared

C DECLARATION:	extern void *
			 MemLockShared(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMLOCKSHARED	proc	far
	C_GetOneWordArg	bx, cx, dx
	call	MemLockShared
	mov	dx, ax
	clr	ax
	ret
MEMLOCKSHARED	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemLockExcl

C DECLARATION:	extern void *
			 MemLockExcl(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMLOCKEXCL	proc	far
	C_GetOneWordArg	bx, cx, dx
	call	MemLockExcl
	mov	dx, ax
	clr	ax
	ret
MEMLOCKEXCL	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemUnlockShared

C DECLARATION:	extern void *
			 MemUnlockShared(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMUNLOCKSHARED	proc	far
	C_GetOneWordArg	bx, cx, dx
	call	MemUnlockShared
	ret
MEMUNLOCKSHARED	endp
	SetDefaultConvention


COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemUpgradeSharedLock

C DECLARATION:	extern void *
			 MemUpgradeSharedLock(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMUPGRADESHAREDLOCK	proc	far
	C_GetOneWordArg	bx, cx, dx
	call	MemUpgradeSharedLock
	mov	dx, ax
	clr	ax
	ret
MEMUPGRADESHAREDLOCK	endp
	SetDefaultConvention


COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemDowngradeExclLock

C DECLARATION:	extern void
			 MemDowngradeExclLock(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMDOWNGRADEEXCLLOCK	proc	far
	C_GetOneWordArg	bx, cx, dx
	call	MemDowngradeExclLock
	ret
MEMDOWNGRADEEXCLLOCK	endp
	SetDefaultConvention
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemLockFixedOrMovable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a virtual segment, lock the corresponding block down,
		if the segment is movable.

CALLED BY:	GLOBAL
PASS:		bx	= virtual segment
RETURN:		carry set if block discarded and can't be reloaded:
			ax	= 0
		carry clear if block ok:
			ax	= usable segment
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemLockFixedOrMovable	proc	far
		.enter
		mov	ax, bx		; assume real segment
HMA <		cmp	bx, HMA_SEGMENT	;check hi-mem segment		>
HMA <		je	done						>
	CheckHack <(MAX_SEGMENT AND 0xff) eq 0>
		cmp	ah, MAX_SEGMENT shr 8
		jb	done

		push	bx
		shl	bx
		shl	bx
		shl	bx
		shl	bx
		call	NearLock

if	ANALYZE_WORKING_SET
		pushf
		push	ds
		LoadVarSeg	ds
		call	WorkingSetResourceInUse
		pop	ds
		popf
endif

		pop	bx
		cmc
done:
		cmc
		.leave
		ret
MemLockFixedOrMovable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemUnlockFixedOrMovable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a virtual segment, unlock the corresponding block,
		if the segment is movable.

CALLED BY:	GLOBAL
PASS:		bx	= virtual segment
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemUnlockFixedOrMovable	proc	far
		.enter
		pushf
HMA <		cmp	bx, HMA_SEGMENT	;check hi-mem segment		>
HMA <		je	done						>
	CheckHack <(MAX_SEGMENT AND 0xff) eq 0>
		cmp	bh, MAX_SEGMENT shr 8
		jb	done

		push	bx
		shl	bx
		shl	bx
		shl	bx
		shl	bx

if	ANALYZE_WORKING_SET
		push	ds
		LoadVarSeg	ds
		call	WorkingSetResourceNotInUse
		pop	ds
endif

		call	NearUnlock
		pop	bx
done:
		popf
		.leave
		ret
MemUnlockFixedOrMovable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemInitRefCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a reference count for a memory handle

CALLED BY:	GLOBAL

PASS:		BX	= Memory handle
		AX	= Initial reference count (0 not allowed)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MemInitRefCount	proc	far
	uses	ds
	.enter
	
EC <	tst	ax				; check for illegal val	>
EC <	ERROR_Z	MEM_REFERENCE_COUNT_ILLEGAL_INITIAL_VALUE		>
EC <	call	ECCheckMemHandleFar		; check for bad handle	>
	LoadVarSeg	ds
	mov	ds:[bx].HM_otherInfo, ax	; store the reference count
	
	.leave
	ret
MemInitRefCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemIncRefCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment a reference count on a memory handle

CALLED BY:	GLOBAL

PASS:		BX	= Memory handle.  If zero, will do nothing (Allows
			  blindly calling this function in routines where
			  data block is optionally passed)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MemIncRefCount	proc	far
	uses	ds
	tst	bx
	jz	exit
	.enter
	
EC <	call	ECCheckMemHandleFar		; check for bad handle	>
	LoadVarSeg	ds
EC <	tst	ds:[bx].HM_otherInfo					>
EC <	ERROR_Z	MEM_REFERENCE_COUNT_NEVER_INITIALIZED			>
	inc	ds:[bx].HM_otherInfo		; increment the reference count
EC <	ERROR_Z	MEM_REFERENCE_COUNT_OVERFLOW				>

	.leave
exit:
	ret
MemIncRefCount	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemDecRefCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement a reference count in a memory handle, and
		free it if the count becomes zero.

CALLED BY:	GLOBAL

PASS:		BX	= Memory handle.  If zero, will do nothing (Allows
			  blindly calling this function in routines where
			  data block is optionally passed)

RETURN:		
	Non-EC:	Nothing

	EC:	BX cleared if reference count drops to zero (and block
		was freed)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The memory handle will be free'd if the reference count
		reaches zero. In general, do not use the passed handle
		after you have called this function.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MemDecRefCount	proc	far
	uses	ds
	tst	bx
	jz	exit
	.enter
	
EC <	call	ECCheckMemHandleFar		; check for bad handle	>
	LoadVarSeg	ds
	dec	ds:[bx].HM_otherInfo		; decrement the reference count
EC <	pushf					; save zero flag result	>
EC <	cmp	ds:[bx].HM_otherInfo, 0xffff	; check for impossible	>
EC <	ERROR_E	MEM_REFERENCE_COUNT_UNDERFLOW				>
EC <	popf					; restore zero flag	>
	jnz	done				; if not zero, do nothing
	call	MemFree				; else free the memory handle
EC <	clr	bx				; a little insurance	>
done:
	.leave
exit:
	ret
MemDecRefCount	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeapGetOperatingSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get amount of space that would be left on the heap if 
		everything discardable or swappable to to be nuked/moved.

CALLED BY:	EXTERNAL
PASS:
RETURN:		ax	- Heap space available (in paragraphs), meaning
			  space that is free, discardable and not locked,
			  or can be swapped out, if needed.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	* Doesn't add in blocks that could be swapped out, as this is being
	  written to get Zoomer out the door.  Will not affect usage of this
	  routine very much, however, as blocks that can be swapped will have
	  been so by the time that space gets very tight.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/2/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	(0)
HeapGetOperatingSpace	proc	far
	push	dx
EC <	call	AssertInterruptsEnabled					>
	call	EnterHeap		;do generic entry stuff
EC <	call	ECMemVerifyHeapLow					>

	push	bx, cx, dx

	clr	dx			; start w/no space available

	;
	; Start at the top
	;
	call	GetLastBlock
	jc	done			; CF set => no heap (!?)

blockLoop:
	;
	; Shift our focus down to the next block. If the address of our new
	; block-of-the-minute is greater than our previous block's, it means
	; we've wrapped and should quit while we're ahead.
	;
        mov     si,bx                   ;secondBlock = firstBlock
	mov	bx,ds:[bx][HM_prev]	;firstBlock = firstBlock.HM_prev
	mov	di,ds:[bx][HM_addr]	;di = address (used if block moved)
	cmp	di,ds:[si][HM_addr]	;make sure first block < second block
EC <	ERROR_E	CORRUPTED_HEAP					>
	ja	done

	tst	ds:[bx][HM_owner]		; check for free
	jz	available			; available if free

	mov	al, ds:[bx][HM_flags]		; get flags

	test	al,mask HF_FIXED		; check for fixed
	jnz	done				; done if reached FIXED area

	tst	ds:[bx][HM_lockCount]		; check for locked
	jnz	blockLoop			; go on to next if locked

	test	al, mask HF_DISCARDABLE		; check for discardable
	jnz	available			; available if discardable

	jmp	short blockLoop			; go on to the next block

available:
	add	dx, ds:[bx].HM_size
	jmp	short blockLoop

done:
	mov	ax, dx			; return total potentially avail space

	pop	bx, cx, dx

EC <	call	ECMemVerifyHeapLow					>
	jmp	ExitHeap

HeapGetOperatingSpace	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeapGetOperatingSpaceUsedByGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out how much  space would be added to the heap if this
		geode were to exit.

CALLED BY:	EXTERNAL
PASS:		bx	- geode to check for
RETURN:		ax	- Amount of Heap available space (in paragraphs) that
			  would be freed up if this geode were to exit.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/3/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	(0)
HeapGetOperatingSpaceUsedByGeode	proc	far
	push	dx
EC <	call	AssertInterruptsEnabled					>
	call	EnterHeap		;do generic entry stuff
EC <	call	ECMemVerifyHeapLow					>

	push	bx, cx, dx, bp

	mov	bp, bx			; keep owning geode in bp

	clr	dx			; start w/no space used

	;
	; Start at the top
	;
	call	GetLastBlock
	jc	done			; CF set => no heap (!?)

blockLoop:
	;
	; Shift our focus down to the next block. If the address of our new
	; block-of-the-minute is greater than our previous block's, it means
	; we've wrapped and should quit while we're ahead.
	;
        mov     si,bx                   ;secondBlock = firstBlock
	mov	bx,ds:[bx][HM_prev]	;firstBlock = firstBlock.HM_prev
	mov	di,ds:[bx][HM_addr]	;di = address (used if block moved)
	cmp	di,ds:[si][HM_addr]	;make sure first block < second block
EC <	ERROR_E	CORRUPTED_HEAP					>
	ja	done

	cmp	bp, ds:[bx][HM_owner]	; check ownership
	jne	blockLoop		; if not a match, loop

	; Skip unlocked, discardable resources, which could already be
	; discarded if needed.
	;
	tst	ds:[bx][HM_lockCount]	; check for locked
	jnz	afterUnlockedDiscardable
	test	al, mask HF_DISCARDABLE	; check for discardable
	jnz	blockLoop		; loop back if unlocked discardable
afterUnlockedDiscardable:

	add	dx, ds:[bx].HM_size	; if correct owner, add size into pot
	jmp	short blockLoop

done:
	mov	ax, dx			; return mem space used

	pop	bx, cx, dx, bp

EC <	call	ECMemVerifyHeapLow					>
	jmp	ExitHeap

HeapGetOperatingSpaceUsedByGeode	endp
endif

