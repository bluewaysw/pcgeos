COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	NetMsg Library
MODULE:		buffer manager
FILE:		hugeLMem.asm

AUTHOR:		Steve Jang, Mar 10, 1994

ROUTINES:
	Name			Description
	----			-----------
	HugeLMemCreate		creates a HugeLMem
	HugeLMemDestroy		destroys a HugeLMem
	HugeLMemAllocLock	allocates a chunk in HugeLMem
	HugeLMemFree		deallocates a chunk in HugeLMem
	HugeLMemLock		locks a buffer in HugeLMem
	HugeLMemUnlock		unlocks a buffer in HugeLMem
	HugeLMemReAlloc		downsizes a buffer in HugeLMem
				( you cannot make the buffer bigger. )

	Internal functions	Description
	------------------	-----------
	ChooseBufferBlock	given the size of a new chunk, decide
				which mem block to put the chunk in.
	FindBufferBlock		given a HugeMem chunk optr, finds the block
				table entry to which the chunk actually belongs

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/10/94   	Initial revision


DESCRIPTION:
	Implementation of huge lmem operations. These things are designed to
	permit simple and quick allocation of optimal-sized buffers with 
	minimal timeouts and without using up too many global handles.
	
SYNCHRONIZATION:
	Access to the HugeLMemMap block is always via a MemPLock.
	
	Data blocks are always locked with a MemPLock, to allow something
	that's attempting to allocate a buffer from a block to be sure,
	after checking the lock count, that it has exclusive right to
	perform the allocation.
	
	In the case of locking a block to access an already-allocated buffer,
	the handle is immediately V'd, as any allocator can consult the
	MGIT_FLAGS_AND_LOCK_COUNT for the handle to determine if anyone else
	is currently using the block.
	
	These rules ensure that things block on data blocks for as short a
	time as possible (barring massive delays in the heap code), allowing
	timeouts to be gauged accurately.

	$Id: hugelmem.asm,v 1.1 97/04/05 01:25:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FREEING_HUGE_LMEM_WHILE_SOMEONE_IS_WAITING		enum FatalErrors
ES_ALREADY_POINTING_TO_HUGE_LMEM_BLOCK			enum FatalErrors
DS_ALREADY_POINTING_TO_HUGE_LMEM_BLOCK			enum FatalErrors
BUFFER_BLOCK_NOT_IN_HUGE_LMEM_MAP			enum FatalErrors
CORRUPTED_HUGELMEM_MAP					enum FatalErrors
RESIZING_TO_EXPAND_NOT_ALLOWED				enum FatalErrors

COMMENT |-------------------------------------------------------------------
		GLOBAL VARIABLES
----------------------------------------------------------------------------|

HugeLMemCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates and initializes a HugeLMem.

CALLED BY:	GLOBAL

PASS:		ax = maximum # of mem blocks to be used
		     0 for default(maximum) value
		bx = minimum size for an optimal block
		cx = maximum size for an optimal block

RETURN:		bx = HugeLMem handle
		carry set on error( most likely to be "insufficient memory" )

DESTROYED:	ax, bx, cx

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

	1. allocate a map block
	2. store information about huge lmem characteristics
	3. initialize block table

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeLMemCreate	proc	far
		uses	ds, bp, es, si, di
		.enter
EC <		call	ECCheckHugeLMemParams				>

		tst	ax
		jnz	continue
		mov	ax, DEFAULT_MAX_BLOCK_NUMBER
continue:
		push	ax, bx, cx
	;
	; Compute initial block table size
	;
		MultByBlockEntrySize	ax, cx		; ax =(num of entry *
							;      ea. entry size)
		add	ax, size HugeLMemMap		; ax = map block size
	;
	; allocate a map block
	;
		mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8) or \
				(mask HF_SHARABLE or mask HF_SWAPABLE)
		mov	bx, handle 0
		call	MemAllocSetOwner	; -> bx = new block handle
						;    ax = seg addr of block
						;    carry set on error
		mov_tr	bp, bx
		mov	ds, ax
		pop	ax, bx, cx
		jc	done			; <- just return error if error
	;
	; copy information
	;
		mov	ds:HLMM_handle, bp
		mov	ds:HLMM_maxNumBlock, ax
		mov	ds:HLMM_minOptimalSize, bx
		mov	ds:HLMM_maxOptimalSize, cx
	;
	; redundunt:
	;	clr	ds:HLMM_status
	;	clr	ds:HLMM_chunkCount
	;	clr	ds:HLMM_blockSem
	;	clr	ds:HLMM_dynamicStorage
	;	clr	ds:HLMM_callbackArray
	;
		
	;
	; allocate an lmem for dynamic storage
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		call	MemAllocLMem		; bx = lmem handle
		jc	destroyHugeLMem
		mov	ax, mask HF_SHARABLE	; set HF_SHARABLE
		call	MemModifyFlags		; ax destroyed
		mov	ax, handle 0
		call	HandleModifyOwner	; ax destroyed
		mov	ds:HLMM_dynamicStorage, bx
		segmov	es, ds, ax		; es = map block
	;
	; allocate a chunk array to store callback routines
	;
EC <		push	ds			; save map block	>
		call	MemLock
		mov	ds, ax
		mov	bx, size FreeSpaceCallbackStruct
		clr	cx, si
		call	ChunkArrayCreate
		jc	skipvar
		mov	es:HLMM_callbackArray, si
		mov	bx, es:HLMM_dynamicStorage
		clc
skipvar:
		call	MemUnlock
EC <		pop	ds			; recover map block	>
		jc	destroyHugeLMem
	;
	; EC: allocate lock record for ec +segment support
	;
EC <		mov	ax, size HugeLMemLockRecordHeader		>
EC <		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE>
EC <		mov	bx, handle 0					>
EC <		call	MemAllocSetOwner				>
EC <		push	es						>
EC <		mov	es, ax						>
EC <		mov	ax, offset HLMLRH_locks				>
EC <		mov	es:[HLMLRH_free], ax				>
EC <		mov	es:[HLMLRH_max], ax				>
EC <		pop	es						>
EC <		mov	ds:[HLMM_locks], bx				>
EC <		call	MemUnlock					>

		clc
	;
	; Unlock Map Block, return its handle in bx
	;
		mov_tr	bx, bp
		call	MemUnlock		; nothing changed
done:
		.leave
		ret
destroyHugeLMem:
		mov	bx, bp
		call	MemUnlock
		call	MemFree
		stc
		jmp	done
HugeLMemCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemForceDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys HugeLMem even if there are still chunks in it.

CALLED BY:	GLOBAL
PASS:		bx = HugeLMemHandle
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeLMemForceDestroy	proc	far
		push	cx
		BitClr	cl, HLMDF_CHECK_CHUNK_COUNT
		GOTO	HugeLMemDestroyCommon, cx
HugeLMemForceDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys a HugeLMem.

CALLED BY:	GLOBAL
PASS:		bx = HugeLMem handle
RETURN:		carry set if hugelmem was not freed because there are still
		chunks around
DESTROYED:	bx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	1. Free all the memory blocks that belong to HugeLMem.
	2. Free the map block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeLMemDestroy	proc	far
		push	cx
		BitSet	cl, HLMDF_CHECK_CHUNK_COUNT
		FALL_THRU HugeLMemDestroyCommon, cx
HugeLMemDestroy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemDestroyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys a HugeLMem.
CALLED BY:	GLOBAL
PASS:		cl = HugeLMemDestroyFlag
		bx = HugeLMem handle
RETURN:		carry set if there are still chunks around
DESTROYED:	bx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	1. Free all the memory blocks that belong to HugeLMem.
	2. Free the map block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeLMemDestroyCommon	proc	far
		uses	ax,cx,di,ds
		.enter
EC <		call	ECValidateHugeLMem				>
	;
	; Free all the data blocks ( iteration )
	;
		push	bx				; save map block handle
		call	MemPLock			;-> ax = segment addr
		mov	ds, ax				;
	;
	; Check destroy flag
	;
		test	cl, mask HLMDF_CHECK_CHUNK_COUNT
		jz	skipChunkNumCheck
	;
	; Check if there are any chunks around
	;
		cmp	ds:HLMM_chunkCount, 0		; are there any chunks?
		ja	skipDestroy			
	;
	; Check if there are waiters.  (There'll be a semaphore if there are).
	; If so, we don't want to free the HugeLMem, as someone is waiting on
	; it.  Instead, we just mark it destroyed, and let the waiter deal
	; with it.
	;
		mov	bx, ds:HLMM_blockSem		
		tst	bx
		jnz	skipDestroy
skipChunkNumCheck:
	;
	;  Free all the data blocks allocated
	;
		mov	di, offset HLMM_blockTable	; ds:di = 1st block
							;         tbl entry
		mov	cx, ds:HLMM_maxNumBlock		; cx = counter
freeLoop:
	;
	; Any HLMBE_block which is not 0 should be a data block handle
	;
		tst	ds:[di].HLMBE_block		;
		jz	skipFree			; unallocated blk entry
		mov	bx, ds:[di].HLMBE_block		;
		call	MemFree				;-> nothing changed
skipFree:
		add	di, size HugeLMemBlockEntry	; next entry
		loop	freeLoop
	;
	; Free block semaphore
	;
		mov	bx, ds:HLMM_blockSem		
		tst	bx
		jz	semDestroyed
		call	ThreadFreeSem			
semDestroyed:
	;
	; Free dynamic storage
	;
		mov	bx, ds:HLMM_dynamicStorage
		call	MemFree

	;
	; Free the allocate lock record
	;
EC <		mov	bx, ds:HLMM_locks				>
EC <		call	MemFree						>

	;
	; Free the map block
	;
		pop	bx			

EC <		mov	ax, MGIT_OTHER_INFO				>
EC <		call	MemGetInfo					>
EC <		tst	ax	; non-z => thread: we're about to hose someone>
EC <		ERROR_NZ	FREEING_HUGE_LMEM_WHILE_SOMEONE_IS_WAITING>

		call	MemFree			
		clc
done:
		.leave
		FALL_THRU_POP	cx
		ret
skipDestroy:
		or	ds:HLMM_status, mask HLMS_DESTROYED

		mov	bx, ds:HLMM_blockSem
		tst	bx
		jz	noWaiters
		call	ThreadVSem		; let'em loose
noWaiters:
		pop	bx
		call	MemUnlockV
		stc
		jmp	done
HugeLMemDestroyCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemWaitFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a callback routine to be called when half of hugelmem
		frees up.
CALLED BY:	Global
PASS:		bx	= hugelmem handle
		dx	= a word to pass into the callback routine
		axcx	= vfptr for callback routine
RETURN:		carry set if there is not enough space for allocating structure
		to hold callback routine

CALLBACK ROUTINE:
		Pass:	ax = the word passed into this routine in dx
		Return: nothing
		Destroy: nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeLMemWaitFreeSpace	proc	far
		uses	ax,cx,si,di,ds
		.enter
	;
	; Allocate a chunk array element for callback routine
	;
		push	bx
		pushdw	axcx
		call	MemPLock
		mov	ds, ax
	;
	; Allocate a chunk array elt for callback routine
	;
		mov	bx, ds:HLMM_dynamicStorage
		mov	si, ds:HLMM_callbackArray
		call	MemLock
		mov	ds, ax
		mov	cx, size FreeSpaceCallbackStruct
		call	ChunkArrayAppend	; ds:di =  fptr to elt
		popdw	axcx
		jc	done
	;
	; copy callback routine
	;
		movdw	ds:[di].FSCS_callback, axcx
		mov	ds:[di].FSCS_arg1, dx
done:
		call	MemUnlock
		pop	bx
		call	MemUnlockV
		.leave
		ret
HugeLMemWaitFreeSpace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeSpaceAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free space is availale.  Call all the callback routines
		and remove them.
CALLED BY:	HugeLMemFree
PASS:		es	= HugeLMemMapBlock
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeSpaceAvailable	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	; enum thru callback array calling all callbacks of geodes waiting
	; for some free space
	;
		mov	bx, es:HLMM_dynamicStorage
		call	MemLockExcl
		mov	ds, ax
		mov	si, es:HLMM_callbackArray
		
if	_FXIP
		mov	bx, vseg CallbackCallback
else
		mov	bx, cs
endif
		mov	di, offset CallbackCallback
		push	es
		call	ChunkArrayEnum	; ax,cx,dx,bp,es destroyed
		pop	es
	;
	; Zero chunk array
	;
		call	ChunkArrayZero
	;
	; callbackArray will now contain no element
	;
		mov	bx, es:HLMM_dynamicStorage
		call	MemUnlockShared
		
		.leave
		ret
FreeSpaceAvailable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallbackCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls a callback routine

CALLED BY:	ChunkArrayEnum
PASS:		ds:di = current element
		ds:*si = chunk array
		es = HugeLMemMap block
RETURN:		ax,cx,dx,bp,es	- returned from callback routine
DESTROYED:	bx,si,di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallbackCallback	proc	far
		uses	ds
		.enter
	;
	; Get arg
	;
		mov	ax, ds:[di].FSCS_arg1
		pushdw	ds:[di].FSCS_callback
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; destroys nothing
		.leave
		ret
CallbackCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemAllocLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a chunk in HugeLMem, and returns optr & fptr to it.
		When this function returns, the block containing the newly
		allocated chunk is locked.

CALLED BY:	GLOBAL

PASS:		ax = size of chunk
		bx = HugeMemHandle
		cx = timeout value( ticks ): range 0-fffeh ( ffffh reseved )
		     0 for no wait
		     FOREVER_WAIT for waiting forever

RETURN:		^lax:cx = new buffer( optr )
		ds:di	= new buffer( fptr )
		carry set if not enough mem

DESTROYED:	nothing

SIDE EFFECTS:	a new memory block might get allocated for HugeLMem

PSEUDO CODE/STRATEGY:

	1. choose a block
	   - linear search until we find a block that can hold the new chunk
	     without exceeding maxOptimalSize.
	   - if a new block needs to be allocated, allocate a block and
	     record it in block table.
	2. allocate a chunk in the block and return optr

	If not enough memory, either wait until some memory frees up,
	or return error(carry set) according to cx.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeLMemAllocLock	proc	far
		chunkSize	local	word	push	ax
		hugelmemHandle	local	word	push	bx
		timeout		local	word	push	cx
		currentTime	local	word
		uses	bx, dx, si, es, bp
		.enter

EC <		call	ECValidateHugeLMem				>
	;
	; choose a block to allocate new chunk in
	;
		call	MemPLock
		mov	es, ax			; es = map block
	;
	; if hugelmem was destroyed, we don't allocate anything
	;
		test	es:HLMM_status, mask HLMS_DESTROYED
		jnz	exit2

chooseNewBufferBlock:
		segmov	ds, es			; ds = map block
		mov	si, offset HLMM_blockTable
		mov	ax, chunkSize
		call	ChooseBufferBlock	; ds:si = HugeLMemBlockEntry
		jc	waitForFree		;	  to use
	;
	; gain exclusive access to the data block
	;
		mov	bx, ds:[si].HLMBE_block
		call	MemPLock
		mov	ds, ax			; ds = data block
	;
	; if anybody locked the data block between the time it was chosen in
	; ChooseBufferBlock and now, we need to pick another one
	;
		mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
		call	MemGetInfo
		cmp	ah, 1
		je	useBlock

		call	MemUnlockV
		jmp	chooseNewBufferBlock
useBlock:
	;
	; allocate new chunk
	;
		clr	al
		mov	cx, chunkSize
		call	LMemAlloc		; ax = chunk handle
		call	HandleV			; release exclusive access
		jc	unlockWaitForFree	; we'd better sleep than
	;					; trying to choose another blk
	; bx	= new block handle
	; ax	= new chunk handle
	;
		mov_tr	cx, ax
		mov_tr	ax, bx			; ^lax:cx = new chunk
	;
	; update block status
	; es	= map block segment
	; si	= current HugeLMemBlockEntry
	; ds	= data block segment
	;
		tst	es:[si].HLMBE_numChunks
		jnz	notEmpty
		dec	es:HLMM_numEmptyBlock	; update empty blk count
notEmpty:	inc	es:[si].HLMBE_numChunks	; inc block chunk count
		inc	es:HLMM_chunkCount	; inc global chunk count
		mov	dx, chunkSize
		add	es:[si].HLMBE_blockSize, dx ; inc block size
	;
	; record overhead used for this chunk
	;
EC <		LMemChunkOverhead dx					>
EC <		add	ds:HLMDBH_overhead, dx				>
	;
	; release exclusive access to hugelmem map block
	;
		mov	bx, hugelmemHandle
		call	MemUnlockV
	;
	; return arguments
	;
EC <		call	ECHugeLMemAddLockRecord				>
		mov	di, cx			;
		mov	di, ds:[di]		; ds:di = new chunk
		clc
done:
		.leave
		ret
		
unlockWaitForFree:
	;
	; bx = data block, already V'ed, needs to be unlocked
	;
		call	MemUnlock
waitForFree:
	;
	; es = map block
	; record current time
	;
		call	TimerGetCount		; bx.ax = current ticks
		mov	currentTime, ax
waitMore:
		mov	bx, es:HLMM_blockSem
		tst	bx
		jnz	haveSem
	;
	; allocate blocking sem
	;
		call	ThreadAllocSem		; bx = sem
		mov	es:HLMM_blockSem, bx
		mov	ax, handle 0
		call	HandleModifyOwner
haveSem:
		inc	es:HLMM_waiters
		mov	dx, bx			; dx = block sem
		mov	bx, hugelmemHandle
		call	MemUnlockV
	;
	; block for free space
	;
		mov	cx, timeout
		xchg	bx, dx			; bx = block sem, dx = hugelmem
		call	ThreadPTimedSem		; ax = SemaphoreError
wokeup::
		mov	si, ax			; si = SemaphoreError
	;
	; gain exclusive access to map again
	;
		xchg	bx, dx			; bx = hugelmem, dx = block sem
		call	MemPLock
		mov	es, ax
		dec	es:HLMM_waiters
		jnz	others
	;
	; deallocate block sem
	;
		clr	bx
		xchg	bx, es:HLMM_blockSem
		call	ThreadFreeSem
	;
	; no waiters, if HugeLMem is marked as destroyed and there are no
	; more chunks, destroy it
	;
		test	es:HLMM_status, mask HLMS_DESTROYED
		jz	afterVOthers
	;
	; if destroyed, but chunks still exist, just exit to allow
	; HugeLMemFree to handle the destroy
	;
		cmp	es:HLMM_chunkCount, 0
		jne	exit2
		mov	bx, hugelmemHandle
		call	MemUnlockV
		call	HugeLMemDestroy
		stc
		jmp	done

others:
	;
	; if hugelmem was destroyed, V all the others
	;
		test	es:HLMM_status, mask HLMS_DESTROYED
		jnz	vOthers
	;
	; Timed out?
	;
		cmp	si, SE_TIMEOUT
		je	timedOut
vOthers:
	;
	; V all the next guy that might be waiting on block sem since
	; the block that has been freed may be big enough for all of us
	;
		mov_tr	bx, dx		; bx = block sem
		call	ThreadVSem
	;
	; if hugelmem was destroyed, just exit
	;
		test	es:HLMM_status, mask HLMS_DESTROYED
		jnz	exit2
afterVOthers:
	;
	; if timed out, just exit
	;
		cmp	si, SE_TIMEOUT
		je	timedOut
	;
	; if ~waiting forever, adjust timeout value by subtracting elapsed time
	;
		cmp	cx, FOREVER_WAIT
		je	chooseNewBufferBlock

		call	TimerGetCount		; bx.ax = current time
		sub	ax, currentTime		; assuming max 1 roll over
		sub	timeout, ax		; timeout = timeout - elapse t
						; (always, elapse < timeout)
		jmp	chooseNewBufferBlock
timedOut:
		cmp	cx, FOREVER_WAIT
		je	waitMore
exit2:
		mov	bx, hugelmemHandle
		call	MemUnlockV
		stc
		jmp	done
		
HugeLMemAllocLock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseBufferBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the size of a new chunk, chooses a memory block to
		put that chunk in, and returns pointer to the corresponding
		entry in block table.

CALLED BY:	HugeMemAlloc

PASS:		ds    = HugeLMemMap block segment
		ds:si = first entry of block table
		ax    = desired chunk size

RETURN:		ds:si = block table entry corresponding to the block to use

DESTROYED:	nothing

SIDE EFFECTS:	This may allocate a new memory block in global heap.

PSEUDO CODE/STRATEGY:

	1. FIRST TIME THROUGH: Linear search through block table until we
	   find a block that is not optimal and can hold the given size buffer.
	   For each entry:

		if (block size + new chunk size > max optimal size), pass.
		else if block is locked by somebody, pass.
		otherwise block found!

	2. If nothing has been found, return error. (carry set)


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChooseBufferBlock	proc	near
		uses	ax, bx, cx, dx, bp, es, di
		.enter
	;
	; Search loop
	;
		mov	bp, ds:HLMM_maxOptimalSize	; something to compare
		mov	cx, ds:HLMM_maxNumBlock		; counter for loop
	;
	; If (new chunk size > max opt size), just find an empty block
	;
		cmp	ax, bp			; carry clr if oversized chunk
searchLoop:
	;
	; ax = new chunk size
	; ds:si = HugeLMemBlockEntry
	;
		pushf				; carry = 0 if oversized
						;         1 if not
		jc	notOversized
	;
	; If oversized, just find an empty block
	;
		tst	ds:[si].HLMBE_numChunks
		jz	found
		jmp	continueSearch		
notOversized:
	;
	; If not oversized, find a block that has enough room
	;
		mov	bx, ds:[si].HLMBE_block
		tst	bx
		jz	found

	;
	; the following code doesn't work since we don't know how much of the
	; current lmem block is actually used and how much of it is free
	;
	;	mov	ax, MGIT_SIZE
	;	call	MemGetInfo
	;	mov_tr	di, ax				; di = cur block size
	;
		mov	di, ds:[si].HLMBE_blockSize	; di = cur block size
		add	di, ax				; di += new chunk size
		cmp	bp, di				; cmp with max opt size
		jae	found				; carry == clear
continueSearch:		
		add	si, size HugeLMemBlockEntry	; go to next entry
		popf
		loop	searchLoop			;
		stc					; block never found
		jmp	done
found:
	;
	; If the block was not allocated yet, allocate it now.
	;
		tst	ds:[si].HLMBE_block
		jnz	checkLock
	;
	; Allocate a LMEM heap for this entry
	;
		popf
		mov	ax, LMEM_TYPE_GENERAL
		mov	cx, size HugeLMemDataBlockHeader
		call	MemAllocLMem		;-> bx = block handle
		mov	ds:[si].HLMBE_block, bx	;   carry set on err
	;
	; Modify the flags and owner of this mem block
	;
		mov	ax, mask HF_SHARABLE	; set HF_SHARABLE
		call	MemModifyFlags		; ax destroyed
		mov	ax, handle 0
		call	HandleModifyOwner	; ax destroyed

		inc	ds:HLMM_numAllocatedBlock ; one more block allocated
		inc	ds:HLMM_numEmptyBlock	; the block is initially empty

		call	MemLock			; ax = data block segment
		mov	es, ax
		segmov	es:HLMDBH_hugelmem, ds:[HLMM_handle], cx
EC <		clr	es:HLMDBH_overhead				>
EC <		segmov	es:HLMDBH_locks, ds:[HLMM_locks], cx		>
		call	MemUnlock
done:
		.leave
		ret
checkLock:
	;
	; Check if the block is currently in use by someone (which means we
	; wouldn't be able to allocate anything in it, as that would screw
	; up the pointers they have to it). If so, go back to search loop
	;
		mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
		mov	bx, ds:[si].HLMBE_block
		call	MemGetInfo		; ah = lock ocunt
		tst	ah
		jnz	continueSearch
		popf
		clc
		jmp	done
		
ChooseBufferBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemReAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the size of a chunk in a hugelmem

CALLED BY:	GLOBAL
PASS:		*ds:ax = handle of the hugelmem chunk
		cx = size to resize chunk to
RETURN:		carry = set if error
DESTROYED:	nothing

IMPORTANT:
		currently incrementing size of a chunk is NOT ALLOWED.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeLMemReAlloc	proc	far
		chunkHandle	local	nptr	push	ax
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; Lock HugeLMemMap block
	;
		mov	bx, ds:HLMDBH_hugelmem
		call	MemPLock
		mov	es, ax				; es = map block
	;
	; Find Block entry that contains this chunk
	;
		push	ds
		mov_tr	bx, ax
		mov	ax, ds:LMBH_handle
		mov	ds, bx
		call	FindBufferBlock			; ds:si = map entry
		pop	ds				; ds = data block seg
EC <		ERROR_C	BUFFER_BLOCK_NOT_IN_HUGE_LMEM_MAP		>
	;
	; Find out the current size
	;
		mov	ax, chunkHandle
		ChunkSizeHandle ds, ax, bx
		cmp	cx, bx
EC <		ERROR_A RESIZING_TO_EXPAND_NOT_ALLOWED			>
NEC <		ja	doneUnlock			; carry set	>
	;
	; If it is downsizing go ahead
	;
		call	LMemReAlloc			; never returns error
	;
	; update map entry
	;
EC <		push	bx						>
		sub	bx, cx				; compute difference
		sub	es:[si].HLMBE_blockSize, bx	; subtract difference
EC <		pop	bx						>
	;
	; Update overhead
	;
EC <		LMemChunkOverhead bx					>
EC <		sub	ds:HLMDBH_overhead, bx				>
EC <		mov	bx, cx						>
EC <		LMemChunkOverhead bx					>
EC <		add	ds:HLMDBH_overhead, bx				>
doneUnlock::
	;
	; Unlock HugeLMemMap block
	;
		mov	bx, ds:HLMDBH_hugelmem
		call	MemUnlockV
		clc
		.leave
		ret
HugeLMemReAlloc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	frees a HugeMem chunk;
		this also destroys the hugelmem in case it was already
		destroyed before but we waited until now that the last chunk
		in it was destroyed.  If there are still chunks when we
		destroy a hugelmem, hugelmem will be marked destroyed, but
		actually data structures will stay around until the last
		chunk in hugelmem is destroyed.

CALLED BY:	GLOBAL

PASS:		^lax:cx = huge mem chunk optr

RETURN:		cx	= size of chunk

		In EC version,
			Invalid chunk optr is detected in
			ECValidateHugeLMemChunk. 

			ES, DS set to NULL_SEGMENT if pointing to block being
			freed when ec +segment on.

		In non-EC version:
			if datablock(ax) belongs to this hugeLMem,
			   if cx = illegal handle, then [fatal error from
				LMemFree] 
			   else [everything is fine]
			else
			   carry = set.

DESTROYED:	ax

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	1. find the block that the chunk belongs to
	2. adjust size entry of the block, and free chunk

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeLMemFree	proc	far
		uses	bx, dx, si, di, ds, es
		.enter
	;
	; First find handle to hugelmem map block
	;
		mov	dx, ax			; store data block handle in dx
		mov	bx, ax			;
		call	MemPLock		;-> ax = seg of data block
		mov	ds, ax			;
		mov	ax, ds:HLMDBH_hugelmem	; get hugelmem handle
		call	MemUnlockV		;
		mov_tr	bx, ax			; bx = hugelmem handle
		
EC <		call	ECValidateHugeLMemChunk				>
	;
	; Find the block that the chunk belongs to
	;
		call	MemPLock  		;-> ax = seg addr/CF set on err

		mov	ds, ax   			; ds = map's seg addr
		mov	ax, dx			; ax = data block hptr to find
		call	FindBufferBlock		; -> ds:si = entry found
EC <		ERROR_C	BUFFER_BLOCK_NOT_IN_HUGE_LMEM_MAP 		>
						;    => CF = 1
		segmov	es, ds			;
		mov	di, si			; now es:di = entry in blocktbl
		mov_tr	ax, dx
	;
	; Now free the chunk
	;
		mov_tr	dx, bx			; store map block handle in dx
		mov	bx, ax			; bx = data block handle
		call	MemPLock		;-> ax = seg addr/CF set on err
		mov	ds, ax			; ds = datablk seg addr
	;
	; Free the chunk from actual data block( in ds now )
	;
		mov_tr	ax, cx			; ax = chunk handle to remove
		ChunkSizeHandle ds,ax,cx	; cx = size of chunk
		call	LMemFree		;-> nothing changed
	;
	; update various block information
	;
		dec	es:[di].HLMBE_numChunks
		dec	es:HLMM_chunkCount
		sub	es:[di].HLMBE_blockSize, cx
EC <		ERROR_C	CORRUPTED_HUGELMEM_MAP				>
	;
	; subtract chunk overhead
	;
EC <		mov	ax, cx						>
EC <		LMemChunkOverhead ax					>
EC <		sub	ds:HLMDBH_overhead, ax				>

if ERROR_CHECK
	;
	; EC check to see if block size table entry has the correct value
	;
		mov	ax, ds:LMBH_blockSize	; ax = block size
		sub	ax, ds:LMBH_totalFree
		sub	ax, ds:LMBH_offset
		sub	ax, ds:LMBH_nHandles
		sub	ax, ds:LMBH_nHandles	; twice
		sub	ax, ds:HLMDBH_overhead	; size, alignment overhead, etc
		sub	ax, es:[di].HLMBE_blockSize
	;
	; if you got this error check if you used any LMemReAlloc on hugelmem
	; chunks.  If that's not the problem, it must be some other memory
	; trashing problem, in your or my code.
	;
		ERROR_NZ CORRUPTED_HUGELMEM_MAP
endif
	;
	; Unlock data block
	;
		call	MemUnlockV		;-> nothing changed
	;
	; decide whether to deallocate some blocks
	;
		tst	es:[di].HLMBE_numChunks
		jnz	checkEmptyToUsedRatio
		inc	es:HLMM_numEmptyBlock
checkEmptyToUsedRatio:
	;
	; if (empty allocated blocks > allocated blocks / 2),
	; then deallocate 1/2 of all empty blocks
	;
		mov	ax, es:HLMM_numAllocatedBlock
		shr	ax, 1
		cmp	ax, es:HLMM_numEmptyBlock
		jae	pokeFreeSpaceWaiter
		
		call	DeallocateHalfOfEmptyBlocks	;-> nothing changed

pokeFreeSpaceWaiter:
	;
	; If there's a block semaphore, V it, as someone is probably blocking
	; on it.
	;
		mov	bx, es:HLMM_blockSem
		tst	bx
		jz	releaseMap
		call	ThreadVSem
releaseMap:
		mov	bx, dx			; get map block handle back
		call	MemUnlockV   		;-> nothing changed
	;
	; check if we need to destroy hugelmem
	;
		pushf
		call	MemPLock
		mov	ds, ax
		test	ds:HLMM_status, mask HLMS_DESTROYED
		jz	hugelmemok
	;
	; check if there are any chunks left
	;
		tst	ds:HLMM_chunkCount
		jz	destroyHugeLMem
hugelmemok:
		call	MemUnlockV
done:
		popf				; carry preserved
		.leave
EC <		call	ECHugeLMemNullSegmentRegisters			>
		ret
destroyHugeLMem:
	;
	; destroy hugelmem because it was destroyed before but we waited until
	; now when the last chunk was freed
	;
		call	MemUnlockV
	;
	; destroy hugelmem
	;
		call	HugeLMemDestroy
		jmp	done
HugeLMemFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECHugeLMemNullSegmentRegisters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Null segment registers if they point to invalid segments and
		ec +segment on

CALLED BY:	(INTERNAL) HugeLMemFree
PASS:		nothing
RETURN:		DS and ES become NULL_SEGMENT if they point to invalid
		segments and ec +segment
DESTROYED:	nothing (Flags preserved)
SIDE EFFECTS:	

NOTES:		This MUST be a NEAR procedure to the caller to avoid
		CheckToLockNS which fatal errors if DS or ES is invalid.


PSEUDO CODE/STRATEGY:
	if (ec +segment) {
		if (DS != NULL_SEGMENT) {
			if (MemSegmentToHandle(DS) == invalid_handle) {
				DS = NULL_SEGMENT;
			}
		}
		if (ES != NULL_SEGMENT) {
			if (MemSegmentToHandle(ES) == invalid_handle) {
				ES = NULL_SEGMENT;
			}
		}
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/23/96    	Initial version
	jwu	5/13/96		Changed to near proc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECHugeLMemNullSegmentRegisters	proc	near
if	ERROR_CHECK

		pushf
		uses	ax, bx, cx
		.enter
	;
	; Skip everything if ec +segment NOT turned on
	;
		call	SysGetECLevel		; ax = ErrorCheckingFlags,
						; bx = error checking block
		test	ax, mask ECF_SEGMENT	; ec +segment on?
		jz	checkDone		; jmp if not
	;
	; Use MemSegmentToHandle to determine whether the segments are
	; valid. Null the seg reg is no handle found
	;
	; Check ES...
	;
		mov	cx, es
		cmp	cx, NULL_SEGMENT
		je	checkDS			; skip if already NULL segment
		call	MemSegmentToHandle	; carry clr if handle not found
						; otherwise, cx = handle
		jc	checkDS
		mov	ax, NULL_SEGMENT
		mov_tr	es, ax			; es = NULL_SEGMENT
checkDS:
	;
	; Check DS...
	;
		mov	cx, ds
		cmp	cx, NULL_SEGMENT
		je	checkDone		; skip if already NULL sgement
		call	MemSegmentToHandle	; carry clr if handle not found
						; otherwise, cx = handle
		jc	checkDone
		mov	ax, NULL_SEGMENT
		mov_tr	ds, ax			; ds = NULL_SEGMENT
		
checkDone:
		.leave
		popf
		ret

endif	; ERROR_CHECK
	

ECHugeLMemNullSegmentRegisters	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeallocateHalfOfEmptyBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deallocate half of empty allocated blocks in hugelmem.

CALLED BY:	HugeLMemFree
PASS:		es	= hugelmem map segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeallocateHalfOfEmptyBlocks	proc	near
		uses	bx,cx,di
		.enter
	;
	; Compute how many data blocks(LMem) to deallocate
	;
		mov	cx, es:HLMM_numEmptyBlock
		shr	cx, 1				; half of empty blocks
		jz	done
		push	cx
		mov	di, offset HLMM_blockTable	; es:di = first table
							;         entry
deallocateLoop:
		call	FindNextEmptyBlock		;-> es:di = table entry
							; 	for empty block
		clr	bx
		xchg	bx, es:[di].HLMBE_block		;
		call	MemFree				;-> bx = destroyed
		loop	deallocateLoop
	;
	; Adjust empty block count
	;
		pop	cx
done:
		sub	es:HLMM_numEmptyBlock, cx
		sub	es:HLMM_numAllocatedBlock, cx
	;
	; Notify anybody waiting for free space because hugelmem was full at
	; one point.
	;
		call	FreeSpaceAvailable
		.leave
		ret
DeallocateHalfOfEmptyBlocks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNextEmptyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the next empty allocated block in hugelmem block table

CALLED BY:	DeallocateHalfOfEmptyBlocks
PASS:		es:di	= current block entry
RETURN:		es:di	= empty block entry
DESTROYED:	nothing

ASSUMPTION:	Caller must make sure that there is at least one empty
		allocated block in the block table

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNextEmptyBlock	proc	near
		uses	cx
		.enter
	;
	; Search loop:
	;   Assumption here is that the caller guarantees that there will be
	;   at least one empty block
	;
		mov	cx, es:HLMM_maxNumBlock		; counter for loop
searchLoop:
		tst	es:[di].HLMBE_numChunks		; check block size
		jz	mayHaveFound			;
continue:
		add	di, size HugeLMemBlockEntry	; advance one entry
		loop	searchLoop			;
found:
		.leave
		ret
mayHaveFound:
		tst	es:[di].HLMBE_block		; check for unallocated
		jz	continue			; empty block
		jmp	found
		
FindNextEmptyBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindBufferBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given a HugeLMem chunk optr, finds the block entry for the
		data block to which the chunk actually belongs

CALLED BY:	HugeLMemFree

PASS:		ax = data block handle of the chunk
		ds = map segment

RETURN:		ds:si = the entry for the data block
		carry set if no such block is found in the table

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	1. loop around until we find the block handle in the table

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindBufferBlock	proc	far
		uses	cx
		.enter
	;
	; Search loop
	;
		mov	si, offset HLMM_blockTable	; si = first tbl entry
		mov	cx, ds:HLMM_maxNumBlock		; counter for loop
searchLoop:
		cmp	ds:[si].HLMBE_block, ax		; compare block handles
		je	found				; carry = clear
		add	si, size HugeLMemBlockEntry	; advance one entry
		loop	searchLoop			;
		stc					; carry set on error
found:
		.leave
		ret
FindBufferBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks an optr to a buffer in HugeLMem

CALLED BY:	GLOBAL
PASS:		bx = hptr part of hugelmem optr
RETURN:		ax = segment address of the data block
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	7/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeLMemLock	proc	far
		.enter
	;
	; Lock the block down and then release it, but leave it locked.
	; Recall (from the file header :) that the PLock ensures that no one
	; is attempting to allocate a chunk in this block, and that the
	; lock count being non-zero (non-one if we sneak in between the call
	; to ChooseBufferBlock and the MemPLock call) will prevent another
	; thread from allocating stuff here, so we can HandleV the thing
	; right away.
	;
		call	MemPLock
		call	HandleV
EC <		push	ds						>
EC <		mov	ds, ax						>
EC <		call	ECHugeLMemAddLockRecord				>
EC <		pop	ds						>
		.leave
		ret
HugeLMemLock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks the buffer in HugeLMem

CALLED BY:	GLOBAL
PASS:		bx = hptr part of a hugelmem optr
RETURN:		nothing
DESTROYED:	nothing ( flags preserved )
		EC: es, ds set to NULL_SEGMENT if pointing to block being
		    unlocked
			

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	7/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; ==========================================================================
; ECSG
; ==========================================================================
; SYNOPSYS:	include the line only if ECF_SEGMENT is set in register arg
; PASS:		reg	= ErrorCheckingFlags
;		line	= code to compile
; ==========================================================================
ECSG		macro	reg, line
		local	skip
		test	reg, mask ECF_SEGMENT
		jz	skip
		line
skip:
endm
HugeLMemUnlock	proc	far
		.enter
	;
	; If ECF_SEGMENT is not set, do not check segments
	; : added to prevent errors when ECF_SEGMENT is off
	;
EC <		push	bp						>
EC <		push	ax, bx						>
EC <		call	SysGetECLevel; ax = ECF, bx = error checking block>
EC <		mov	bp, ax						>
EC <		pop	ax, bx						>
	;
	; If ES or DS pointing to the block, null the thing out, to take care
	; of multiple threads locking stuff in this array. We assume things
	; don't have multiple blocks from the array locked at once with
	; different registers pointing to them...
	; 
EC <		pushf							>
EC <		push	ax, cx, dx					>
EC <		mov	ax, ds						>
EC <		ECSG bp, <	call	ECCheckSegment			>>
EC <		mov	ax, es						>
EC <		ECSG bp, <	call	ECCheckSegment			>>
EC <		mov_tr	dx, ax						>
EC <		call	MemDerefES					>
EC <		call	ECHugeLMemRemoveLockRecord			>
EC <		jnc	nullSegDone	; => thread has another lock	>
EC <		mov	cx, es						>
EC <		cmp	dx, cx						>
EC <		jne	checkDS						>
EC <		mov	dx, NULL_SEGMENT				>
EC < checkDS:								>
EC <		mov	ax, ds						>
EC <		ECSG bp, <	call	ECCheckSegment			>>
EC <		cmp	ax, cx						>
EC <		jne	dsSet						>
EC <		mov	ax, NULL_SEGMENT				>
EC <dsSet:								>
EC <		mov	ds, ax						>
EC <nullSegDone:							>
EC <		mov	es, dx						>
EC <		pop	ax, cx, dx					>
EC <		popf							>
EC <		pop	bp						>
		call	MemUnlock
		.leave
		ret
HugeLMemUnlock	endp

HugeLMemCode	ends









;----------------------------------------------------------------------------
;
; DISCARDED CODE:
;
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeLMemAllocLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a chunk in HugeLMem, and returns optr & fptr to it.
		When this function returns, the block containing the newly
		allocated chunk is locked.

CALLED BY:	GLOBAL

PASS:		ax = size of chunk
		bx = HugeMemHandle
		cx = timeout value( ticks ): range 0-fffeh ( ffffh reseved )
		     0 for no wait
		     FOREVER_WAIT for waiting forever

RETURN:		^lax:cx = new buffer( optr )
		ds:di	= new buffer( fptr )
		carry set if not enough mem

DESTROYED:	nothing

SIDE EFFECTS:	a new memory block might get allocated for HugeLMem

PSEUDO CODE/STRATEGY:

	1. choose a block
	   - linear search until we find a block that can hold the new chunk
	     without exceeding maxOptimalSize.
	   - if a new block needs to be allocated, allocate a block and
	     record it in block table.
	2. allocate a chunk in the block and return optr

	If not enough memory, either wait until some memory frees up,
	or return error(carry set) according to cx.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DISCARDED_HugeLMemAllocLock	proc	far

		uses	bx, dx, si, es, bp
		.enter
EC <		call	ECValidateHugeLMem				>

	;
	; Choose the block to allocate new chunk in
	;
		push	bx				; save hugelmem handle
		mov_tr	dx, ax				; save chunk size in dx
		call	MemPLock  			;-> ax = seg addr

		mov	ds, ax				; ds = map seg addr
chooseNewBufferBlock:
		mov	ax, dx				; ax = new chunk size
							; dx = still chunk size
		mov	si, offset HLMM_blockTable	; si = offset to table
		call	ChooseBufferBlock		;-> ds:si = block table
							;          entry to use
							;   CF set on error
		jc	notEnoughMemory

		mov	bx, ds:[si].HLMBE_block		; bx = data block
		call	MemPLock   			; -> ax = seg. addr
							;    carry set on error
		mov	es, ax				; es = block`s seg addr
	;
	; See if someone locked this block down between when ChooseBufferBlock
	; checked the lock count and when we gained exclusive access to the
	; thing in MemPLock. If so, we have to go pick another block.
	;
		mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
		call	MemGetInfo
		cmp	ah, 1
		jne	allocationAborted
	;
	; If this block was an empty one, decrement numEmptyBlock counter
	;
		tst	ds:[si].HLMBE_numChunks
		jnz	notEmpty
		dec	ds:HLMM_numEmptyBlock
notEmpty:
	;
	; ds = hugelmem map block
	; bx = data block handle
	; cx = timeout value
	; dx = new chunk size
	;
		inc	ds:[si].HLMBE_numChunks
		add	ds:[si].HLMBE_blockSize, dx
		inc	ds:HLMM_chunkCount
		mov_tr	di, cx				; di = timeout value
	;						;    saved just in case
	; Now allocate a new chunk
	;
		segmov	ds, es, ax			; ds = data block
		clr	ax
		mov	cx, dx				; ax = cleared
							; cx = chunk size
		call	LMemAlloc   			; -> ax = chunk handle
		jc	noMemory			;    ds = might'v chged
	;
	; Once the chunk is allocated, we can release exclusive access to the
	; data block, but we leave the thing locked.
	;
		call	HandleV				; flags preserved
EC <		call	ECHugeLMemAddLockRecord				>
		mov_tr	cx, ax				;
		mov_tr	ax, bx				; now chunk optr =
							; ^lax:cx
	;
	; Locate new chunk for the user( make ds:di = chunk fptr )
	;
		mov	di, cx				;
		mov	di, ds:[di]			; di: handle -> offset
		clc					; no error
finishUp:
	;
	; Release the map block, finally.
	;
		pop	bx				; bx = hugelmem handle
		call	MemUnlockV   			; -> nothing changed
done::
		.leave
		ret

allocationAborted:
	;
	; Release the block we were hoping to use and go find another one.
	;
		mov	bp, es:HLMDBH_hugelmem
		call	MemUnlockV
		mov_tr	bx, bp				; bx = map block again
		jmp	chooseNewBufferBlock

noMemory:
	;
	; We really don't have memory to allocate new chunk, so we block
	; according to API.
	; ds = data block chosen
	; bx = data block chosen
	; dx = chunk size
	; di = timeout value
	;
		mov	ax, ds:HLMDBH_hugelmem
		call	MemUnlockV		; unlock data block
		mov_tr	bx, ax
		call	MemDerefDS		; ds = hugelmem map block
		mov	ax, dx			; ax = new chunk size
		mov_tr	cx, di			; cx = timeout value
notEnoughMemory:
	;
	; ds	= hugelmem map block segment
	; ax,dx	= new chunk size
	; bx	= hugelmem handle
	; cx	= time out value
	;
	; If cx(time out) < 1, just return error
	;
		cmp	cx, 1				; set CF iff cx < 1
		jc	finishUp			;
	;
	; Otherwise P timed semaphore, with time out(cx)
	;
		mov	bp, bx
		push	ax, bx				; save ax = chunk size
							; bx = hugelmem handle
		
		call	TimerGetCount			;-> ax = time.low word
							;   bx = time.high word
		mov_tr	dx, ax				; store time.low in dx
blockForFree:
		mov	bx, ds:HLMM_blockSem
		tst	bx
		jnz	haveSem
	    ;
	    ; allocate blocking semaphore, since we have none yet
	    ;
		clr	bx
		call	ThreadAllocSem		; -> bx = semaphor handle
		mov	ds:HLMM_blockSem, bx	; store semaphore in map block
		mov	ax, handle 0
		call	HandleModifyOwner
haveSem:
	    ;
	    ; Record another waiter before we release the map block
	    ;
		inc	ds:HLMM_waiters

		xchg	bx, bp				; bx = hugelmem handle
		call	MemUnlockV			; release map block
	    ;
	    ; Now block on the semaphore with appropriate timeout.
	    ;
		xchg	bx, bp				; bx = block sem
		call	ThreadPTimedSem			;;;; block on
							;;;; HLMM_blockSem
	;
	; Gain exclusive access to the map again.
	;
		xchg	bx, bp				; bx = hugelmem handle
		mov_tr	bp, ax				; bp = result of PSem
		call	MemPLock			;
		mov	ds, ax				;

	;
	; One more waiter done -- free the blockSem if we were the last.
	;
		dec	ds:HLMM_waiters
		jnz	checkResult

		clr	bx
		xchg	bx, ds:HLMM_blockSem
		call	ThreadFreeSem
checkResult:
	;
	; See if we timed out or were woken up.
	;
		cmp	bp, SE_TIMEOUT			;
		je	timedOut			;
	;
	; In theory, there's memory available. Compute the elapsed time and
	; adjust the original timeout by that, in case we have to block again.
	;
		call	TimerGetCount			;-> ax = time.low word
							;   bx = time.hi word
		sub	ax, dx				; ax = elapsed ticks
							;  (assuming no more
							;  than one rollover)
		sub	cx, ax				; cx = cx - time elapse
		jae	chooseAgain
		clr	cx				; waited too long
							;  (scheduling is
							;  imprecise...) but
							;  that doesn't mean
							;  wait forever next
							;  time...
chooseAgain:
		pop	ax, bx				; ax = chunk size,
							;  bx = map block
		jmp 	chooseNewBufferBlock		; re-choose data block

timedOut:
		cmp	cx, FOREVER_WAIT
		je	blockForFree			; => keep waiting
							;  until someone wakes
							;  us up
	;
	; Real timeout, so return carry set, please.
	;
		pop	ax, bx				; ax = chunk size,
							;  bx = map block
		stc
		jmp	finishUp

DISCARDED_HugeLMemAllocLock	endp@

