; This is just some dummy address which is above DIRECT_MAPPING_MEMORY and
; which doesn't yield an internal page number of -1.
DUMMY_PHYSICAL_ADDR	equ	0x00800000

;brianc 9/7/00
include Internal/heapInt.def
include system.def
include sem.def
include assert.def



	;
	; When multiple geodes use this library at the same time, the winInfo
	; variable will be shared.  But it's okay because SysGetUtilWindowInfo
	; always return the same info in this structure anyway.
	;
	; However, even though in practice SysGetUtilWindowInfo only writes
	; valid data into winInfo while it is executing, in theory it can
	; write anything into the variable before it writes valid data and
	; returns.  Then it'll be bad if one thread is in SysGetUtilWindowInfo
	; and another thread is reading winInfo.  So we need to use a
	; semaphore to protect winInfo to prevent this theoretical problem.
	;
	; An alternative is to keep a separate winInfo for each geode using
	; us.  But that takes more memory for the data and doesn't seem to
	; take fewer bytes for the code.
	;
	; A better way is to use a thread lock instead of a semaphore, but
	; that would take more bytes for the code.  The slight loss of
	; parallelism from using a semaphore is not important here.
	;
udata	segment
	winInfo		UtilWinInfo	UTIL_WINDOW_MAX_NUM_WINDOWS dup (<>)
udata	ends
idata	segment
	winInfoSem	Semaphore
idata	ends


;brianc 9/7/00 (also, ret @ArgSize -> ret)
			SetDefaultConvention    ; C-style

CommonCode	segment	resource

;brianc 9/7/00
global _MapHeapEnter:far
global _MapHeapLeave:far
global _MapHeapCreate:far
global _MapHeapDestroy:far
global _MapHeapMaybeInHeap:far
global _MapHeapMalloc:far
global _MapHeapFree:far
global _MapHeapRealloc:far

;dhunter 9/20/00
global _LMemLockAllocAndReturnError:far
global _LMemLockReAllocAndReturnError:far

;dhunter 10/25/00
global MapHeapWindowNumToPtr:far
global MapHeapPtrToWindowNum:far


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_MapHeapEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start using the map heap.  The util mapping window(s) will be
		mapped to the heap area.

CALLED BY:	EXTERNAL
PASS:		on stack:
			hptr.phyMemInfoBlk
RETURN:		nothing
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
C DECLARATION:	extern void _cdecl
			_MapHeapEnter(MemHandle phyMemInfoBlk)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/01/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_MapHeapEnter	proc	far	phyMemInfoBlk:hptr.UtilWinPhyMemInfoBlk
	uses	ds
	.enter
	pusha

	;
	; Lock info block to get the physical addrs.
	;
	mov	bx, ss:[phyMemInfoBlk]
	call	MemLock
	mov	es, ax
	clr	di			; start at 1st win

	push	bx			; save info blk hptr

	segmov	ds, dgroup
	clr	bx			; start at 1st win

	call	PWinInfo

mapLoop:
	;
	; Get physical addr to map to this win.
	;
	tst	ds:[winInfo][bx].UWI_addr
	jz	mapNext
	mov	ax, bx			; ax = array offset
		CheckHack <size UtilWinInfo eq 4>
	shr	ax, 2			; ax = win #
EC <	Assert	b, ax, es:[UWPMIB_count]				>
EC <	mov	dx, ds:[winInfo][bx].UWI_paraSize			>
EC <	Assert	e, dx, es:[UWPMIB_info][di].UWPMI_paraSize		>
	movdw	dxbp, es:[UWPMIB_info][di].UWPMI_addr	;no need to preserve bp
	call	SysMapUtilWindow

mapNext:
	add	di, size UtilWinPhyMemInfo
	add	bx, size UtilWinInfo
	cmp	bx, size winInfo
	jb	mapLoop

	call	VWinInfo

	;
	; Unlock info block.
	;
	pop	bx			; ^hbx = info blk
	call	MemUnlock

	popa
	.leave
	ret
_MapHeapEnter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_MapHeapLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Done using the map heap.  The util mapping window(s) will be
		unmapped.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
C DECLARATION:	extern void _cdecl
			_MapHeapLeave(void)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/01/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_MapHeapLeave	proc	far
	uses	ds
	.enter

	call	PWinInfo

	segmov	ds, dgroup
	mov	bx, size winInfo - size UtilWinInfo	; start at last entry

unmapLoop:
	tst	ds:[winInfo][bx].UWI_addr
	jz	unmapNext
	call	SysUnmapUtilWindow

unmapNext:
	sub	bx, size UtilWinInfo
	jae	unmapLoop

	call	VWinInfo

	.leave
	ret
_MapHeapLeave	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_MapHeapCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the map heap.

CALLED BY:	EXTERNAL
PASS:		On stack:
			fptr to permanent name of geode (GEODE_NAME_SIZE chars)
			fptr to hptr to be filled in with handle to
				UtilWinPhyMemInfoBlk
RETURN:		ax	= TRUE if map heap supported
			block of UtilWinPhyMemInfoBlk entries for this
			geode (to be passed to MapHeapEnter/MapHeapDestroy)
DESTROYED:	bx, cx, dx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
C DECLARATION:	extern Boolean _cdecl
			_MapHeapCreate(char permName[GEODE_NAME_SIZE],
					MemHandle *phyMemInfoBlk)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/01/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_MapHeapCreate	proc	far	permName:fptr.char,
				phyMemInfoBlk:fptr.hptr.UtilWinPhyMemInfoBlk
	uses	si, ds
	.enter

	;
	; Get window info.
	;
	call	PWinInfo
	push	bp
	lds	si, ss:[permName]
	mov	dx, segment winInfo
	mov	bp, offset winInfo	; dx:bp = winInfo
	call	SysGetUtilWindowInfo	; ax = TRUE if supported, ^hbx = UWPMIB
	pop	bp
	call	VWinInfo
	tst	ax
	jz	exit			; => not supported

	lds	si, ss:[phyMemInfoBlk]
	mov	ds:[si], bx		; return blk hptr

	;
	; Set owner of UWPMIB to us, so that in case the current thread isn't
	; owned by the geode using us, the block won't be freed prematurely
	; when the current thread's owner exits.
	;
	; Also need to mark it shared since we don't own the thread that will
	; be calling us later.
	;
	mov	ax, handle 0
	call	HandleModifyOwner
	mov	ax, (0 shl 8) or mask HF_SHARABLE
	call	MemModifyFlags

	;
	; Map in the memory.
	;
	push	bx			; pass hptr on stack
	call	_MapHeapEnter
	pop	ax			; remove parameter

	call	PWinInfo

	segmov	ds, dgroup
	clr	bx			; start at 1st win

createLoop:
	;
	; Create an LMem heap in each window.
	;
	mov	ax, ds:[winInfo][bx].UWI_addr
	tst	ax
	jz	createNext
	mov	cx, ds:[winInfo][bx].UWI_paraSize
	Assert	be, cx, <65536 shr 4>
	cmp	cx, 65536 shr 4
	jb	hasSize
	dec	cx			; can't handle 65536 bytes.  Use 65520.
hasSize:
	call	MapHeapCreateOneHeap

createNext:
	add	bx, size UtilWinInfo
	cmp	bx, size winInfo
	jb	createLoop

	call	VWinInfo

	;
	; Unmap the memory.
	;
	call	_MapHeapLeave

	mov	ax, TRUE		; supported

exit:
	.leave
	ret
_MapHeapCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapHeapCreateOneHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize one LMem block within the map heap.

CALLED BY:	(INTERNAL) _MapHeapCreate
PASS:		ax	= segment of heap
		cx	= size of heap (in paragraphs)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/03/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapHeapCreateOneHeap	proc	near
	uses	ds
	.enter
	pusha

	mov_tr	si, ax			; si = heap seg

	;
	; Allocate a handle for this block.  Since we can't simply allocate
	; a generic handle from the kernel, we have to allocate a semaphore
	; handle, then change the semaphore handle to a memory handle for this
	; block.
	;
	; Don't care what we pass in bx to ThreadAllocSem.
	call	ThreadAllocSem		; bx = sem handle
	mov	ax, handle 0
	call	HandleModifyOwner

	;
	; Now convert the semaphore handle to a memory handle.
	;
	mov	ax, SGIT_HANDLE_TABLE_SEGMENT
	call	SysGetInfo		; ax = kdata, ax:bx = HandleSem
	mov	ds, ax			; ds:bx = HandleSem = HandleMem
	mov	ds:[bx].HM_addr, si
	mov	ds:[bx].HM_size, cx
	mov	ds:[bx].HM_flags, mask HF_FIXED or mask HF_SHARABLE \
			or mask HF_LMEM

	;
	; Initialize an LMem heap.
	;
	mov	ds, si			; ds = blk sptr
	mov	si, cx			; si = blk size in paras
		CheckHack <size LMemBlockHeader eq (1 shl 4)>
	dec	si			; si -= size LMemBlockHeader in paras
	shl	si, 4			; si = free space in bytes
	mov	dx, size LMemBlockHeader
	mov	ax, LMEM_TYPE_GENERAL
	mov	di, mask LMF_NO_HANDLES or mask LMF_NO_ENLARGE \
			or mask LMF_RETURN_ERRORS
	call	LMemInitHeap

	popa
	.leave
	ret
MapHeapCreateOneHeap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_MapHeapDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free any system resource associated with the map heap.

CALLED BY:	EXTERNAL
PASS:		on stack:
			hptr.phyMemInfoBlk
RETURN:		block freed
DESTROYED:	ax, bx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

C DECLARATION:	extern void _cdecl
			_MapHeapDestroy(MemHandle phyMemInfoBlk)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/02/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_MapHeapDestroy	proc	far	phyMemInfoBlk:hptr.UtilWinPhyMemInfoBlk
	uses	ds
	.enter

	;
	; Map in the memory.
	;
	push	ss:[phyMemInfoBlk]	; pass hptr on stack
	call	_MapHeapEnter
	pop	ax			; remove parameter

	call	PWinInfo

	segmov	ds, dgroup
	mov	bx, size winInfo - size UtilWinInfo	; start at last win

destroyLoop:
	tst	ds:[winInfo][bx].UWI_addr
	jz	destroyNext
	mov	es, ds:[winInfo][bx].UWI_addr
	call	MapHeapDestroyOneHeap

destroyNext:
	sub	bx, size UtilWinInfo	; ds:bx = prev. winInfo entry
	jae	destroyLoop

	call	VWinInfo

	;
	; Unmap the memory.
	;
	call	_MapHeapLeave

	;
	; Free the info blk.
	;
	mov	bx, ss:[phyMemInfoBlk]
	call	MemFree

	.leave
	ret
_MapHeapDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapHeapDestroyOneHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free any resource associated with one LMem block within the
		map heap.

CALLED BY:	(INTERNAL) _MapHeapDestroy
PASS:		es	= segment of heap
RETURN:		nothing
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/03/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapHeapDestroyOneHeap	proc	near
	.enter
	pusha

	;
	; Convert the memory handle for this heap back to semaphore handle.
	;
	mov	bx, es:[LMBH_handle]
	mov	ax, SGIT_HANDLE_TABLE_SEGMENT
	call	SysGetInfo		; ax = kdata
	mov	es, ax			; es:bx = HandleMem = HandleSem
	mov	es:[bx].HS_type, SIG_SEMAPHORE

	;
	; Free the semaphore handle.
	;
	call	ThreadFreeSem

	popa
	.leave
	ret
MapHeapDestroyOneHeap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_MapHeapMalloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a fixed memory block in the map heap.

CALLED BY:	EXTERNAL
PASS:		_MapHeapEnter() already called
		on stack:
			block size (word)
RETURN:		dx:ax	= fptr of allocated block, or NULL if fail
DESTROYED:	bx, cx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

C DECLARATION:	extern void *_cdecl 
			_MapHeapMalloc(word blockSize)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/01/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_MapHeapMalloc	proc	far	blockSize:word
	uses	ds
	.enter

	call	PWinInfo

	mov	cx, ss:[blockSize]

	segmov	es, dgroup
	mov	bx, size winInfo - size UtilWinInfo

	;
	; Try to allocate in each LMem heap.
	;
tryLoop:
	mov	dx, es:[winInfo][bx].UWI_addr
	tst	dx
	jz	tryNext			; => this win not supported
	mov	ds, dx			; ds = LMem heap segment
	call	LMemAlloc
	jnc	done			; => success.  dx:ax = chunk

tryNext:
	sub	bx, size UtilWinInfo
	jae	tryLoop

	clr	ax, dx			; dx:ax = NULL, failure

done:
	call	VWinInfo

	.leave
	ret
_MapHeapMalloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_MapHeapFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a fixed memory block in the map heap.

CALLED BY:	EXTERNAL
PASS:		_MapHeapEnter() already called
		on stack:
			fptr to block
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
C DECLARATION:	extern void _cdecl 
			_MapHeapFree(void *blockPtr)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/02/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_MapHeapFree	proc	far	blockPtr:fptr
	uses	ds
	.enter

	lds	ax, ss:[blockPtr]
	call	LMemFree

	.leave
	ret
_MapHeapFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_MapHeapRealloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-allocate a previously allocated block in the map heap.

CALLED BY:	EXTERNAL
PASS:		on stack:
			fptr to block
			new block size (word)
RETURN:		dx:ax	= fptr of re-allocated block, or NULL if fail
DESTROYED:	bx, cx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
C DECLARATION:	extern void *_cdecl 
			_MapHeapRealloc(void *blockPtr, word newSize)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/07/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_MapHeapRealloc	proc	far	blockPtr:fptr, newSize:word
	uses	si, di, ds
	.enter

	;
	; First, try to re-alloc in the same LMem block.
	;
	lds	ax, ss:[blockPtr]
	mov	dx, ds
	mov	cx, ss:[newSize]
	call	LMemReAlloc		; ds:ax = dx:ax = new pointer
	jnc	exit			; => success

	;
	; Can't re-alloc in the same LMem block, so try the hard way.  Try
	; to allocate a new chunk in other LMem blocks and then copy the data
	; over.
	;
	call	PWinInfo
	segmov	es, dgroup
	mov	bx, size winInfo - size UtilWinInfo

allocLoop:
	mov	dx, es:[winInfo][bx].UWI_addr
	tst	dx
	jz	allocNext		; this win not supported.
	cmp	dx, ss:[blockPtr].segment
	je	allocNext		; => don't bother trying in same blk
	mov	ds, dx			; ds = this LMem block
	call	LMemAlloc		; ds:ax = new block, CF if fail
	jnc	copyBlock		; => success

allocNext:
	sub	bx, size UtilWinInfo
	jae	allocLoop

	clr	ax, dx			; can't re-alloc anywhere. dx:ax = NULL
	jmp	exitV

copyBlock:
	;
	; Copy the content of the old chunk to the new chunk.  We know that
	; the new size is larger than the old size, otherwize LMemReAlloc in
	; the same heap would've succedded.
	;
	push	ax			; save new chunk offset
	movdw	esdi, dxax		; es:di = new chunk
	lds	si, ss:[blockPtr]	; ds:si = old chunk
	mov	ax, si			; ds:ax = old chunk
	ChunkSizePtr	ds, si, cx
	rep	movsb

	;
	; Free the old chunk.
	;
	call	LMemFree
	pop	ax			; dx:ax = new chunk

exitV:
	call	VWinInfo

exit:
	.leave
	ret
_MapHeapRealloc	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_MapHeapMaybeInHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if a block was possibly allocated in the map heap.

CALLED BY:	EXTERNAL
PASS:		on stack:
			fptr to block
RETURN:		ax	= TRUE if block may have been allocated in map heap,
			  FALSE if block couldn't have possibly been allocated
			  in map heap.
DESTROYED:	bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
C DECLARATION:	extern Boolean _cdecl
			_MapHeapMaybeInHeap(void *blockPtr)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/07/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_MapHeapMaybeInHeap	proc	far	blockPtr:fptr
	uses	ds
	.enter

	call	PWinInfo

	mov	cx, ss:[blockPtr].segment
	jcxz	notFound		; => NULL ptr, no match

	segmov	ds, dgroup
	mov	bx, size winInfo - size UtilWinInfo
	mov	ax, TRUE		; assume found

	;
	; See if the segment matches any of our windows.
	;
cmpLoop:
	cmp	cx, ds:[winInfo][bx].UWI_addr
	je	exit
	sub	bx, size UtilWinInfo
	jae	cmpLoop

notFound:
	clr	ax			; not in heap, return FALSE

exit:
	call	VWinInfo

	.leave
	ret
_MapHeapMaybeInHeap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_LMemLockAllocAndReturnError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock an LMem block, call LMemAlloc, and return the chunk
		or NullChunk on error.

CALLED BY:	jsememextAlloc
PASS:		on stack: block as hptr, chunkSize as word
RETURN:		ax = nptr to chunk if allocation succeeded
		     NullChunk if allocation failed
DESTROYED:	nothing
SIDE EFFECTS:	Block is locked on return

PSEUDO CODE/STRATEGY:
		Lock the block
		Call LMemAlloc
		Clear return value if carry set
		
C DECLARATION:	ChunkHandle
			LMemLockAllocAndReturnError(MemHandle block,
						    word chunkSize);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	9/20/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_LMemLockAllocAndReturnError	proc	far	block:hptr, chunkSize:word
	uses	bx,cx,ds
	.enter

	mov	bx, block
	mov	cx, chunkSize
	call	MemLock			; ax = segment
	mov	ds, ax
	clr	al			; no flags
	call	LMemAlloc		; ax = chunk
	jnc	done			; branch if no error
	clr	ax			; clear ax if error
done:
	.leave
	ret
_LMemLockAllocAndReturnError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_LMemLockReAllocAndReturnError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock an LMem block, call LMemReAlloc, and return the chunk
		or NullChunk on error.

CALLED BY:	jsememextRealloc
PASS:		on stack: chunkOptr as optr, chunkSize as word
RETURN:		ax = nptr to chunk if allocation succeeded
		     NullChunk if allocation failed
DESTROYED:	nothing
SIDE EFFECTS:	Block is locked on return

PSEUDO CODE/STRATEGY:
		Lock the block
		Call LMemReAlloc
		Clear return value if carry set
		
C DECLARATION:	ChunkHandle
			LMemLockReAllocAndReturnError(optr chunkOptr,
						      word chunkSize);
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	9/20/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_LMemLockReAllocAndReturnError	proc	far	chunkOptr:optr, chunkSize:word
	uses	bx,cx,ds
	.enter

	mov	bx, chunkOptr.handle
	mov	cx, chunkSize
	call	MemLock			; ax = segment
	mov	ds, ax
	mov	ax, chunkOptr.chunk
	call	LMemReAlloc		; ax = chunk
	jnc	done			; branch if no error
	clr	ax			; clear ax if error
done:
	.leave
	ret
_LMemLockReAllocAndReturnError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapHeapWindowNumToPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a "window number" to the window segment.

CALLED BY:	GLOBAL
PASS:		bx = window number
RETURN:		ax = window segment
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/25/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapHeapWindowNumToPtr	proc	far
	uses	bx, ds
	.enter

	call	PWinInfo
	segmov	ds, dgroup, ax			; ds = dgroup
EC <	cmp	bx, UTIL_WINDOW_MAX_NUM_WINDOWS				>
EC <	ERROR_AE -1							>
	CheckHack <size UtilWinInfo eq 4>
	shl	bx, 2				; bx = offset in winInfo
	mov	ax, ds:[winInfo][bx].UWI_addr	; ax = segment
	call	VWinInfo

	.leave
	ret
MapHeapWindowNumToPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapHeapPtrToWindowNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a segment of a mapped window to its "window number".

CALLED BY:	GLOBAL
PASS:		ax = window segment
RETURN:		carry set if no such window, else bx = window number
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/25/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapHeapPtrToWindowNum	proc	far
	uses	ax, ds
	.enter

	call	PWinInfo
	segmov	ds, dgroup, bx			; ds = dgroup
	clr	bx				; bx = offset in winInfo
next:
	cmp	ax, ds:[winInfo][bx].UWI_addr	; found it?
	je	found				; branch if so
	add	bx, size UtilWinInfo		; next window
	cmp	bx, UTIL_WINDOW_MAX_NUM_WINDOWS shl 2
	jne	next				; branch if more windows
	stc					; else not found
	jmp	done
found:
	CheckHack <size UtilWinInfo eq 4>
	shr	bx, 2				; bx = win #
	; Carry clear from first cmp
done:
	call	VWinInfo
	.leave
	ret
MapHeapPtrToWindowNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PWinInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the winInfo semaphore.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	12/17/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PWinInfo	proc	near
	uses	ds
	.enter

	segmov	ds, dgroup
	PSem	ds, winInfoSem

	.leave
	ret
PWinInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VWinInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the winInfo semaphore.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	12/17/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VWinInfo	proc	near
	uses	ds
	.enter

	segmov	ds, dgroup
	VSem	ds, winInfoSem

	.leave
	ret
VWinInfo	endp

CommonCode	ends
