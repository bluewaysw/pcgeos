COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/LMem
FILE:		lmCode.asm

AUTHOR:		John Wedgwood, Apr 11, 1989

GLOBAL ROUTINES:
	Name			Description
	----			-----------
	LMemInit		Initializes some variables.

	LMemInitHeap		Create and initialize a local heap.
	LMemAlloc		Allocate a chunk in the heap.
	LMemFree		Free a chunk in the heap.
	LMemReAlloc		Resize a chunk in the heap.
	LMemInsertAt		Insert bytes in the middle of a chunk
	LMemDeleteAt		Delete bytes in the middle of a chunk
	ECLMemExists		Does a chunk exist?

LOCAL ROUTINES:
	Name			Description
	----			-----------
	QuickLMemReAlloc	Try a fast re-allocation method.
	AddFreeBlock		Add a chunk to the free list.
	CreateMoreHandles	Allocate space for more lmem handles.
	FindFreeSpace		Find space in the free list.
	GetSpaceExact		Get an exact amount of space in the heap.
	LMemCompactHeap		Compress the heap.
	LMemSplitBlock		Divide a chunk in half.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	4/11/89		Initial revision

IMPLEMENTATION:
	Handles in the local-memory heap are pointers to chunks in the heap.
	There is no other information stored in a local-memory handle.

	Chunks on the local-memory heap consist of the data preceded by the
	size of the chunk. This size word can be even or odd, but when it is
	used, it is always rounded up. This forces the entire heap to be
	word aligned.

	The handle points directly to the data, not to the size word.

	Free chunk are kept in the heap in a linked list (a pointer to the
	start of the list is kept in the lmem-header). The pointer to the next
	chunk is stored in the position that the data occupied before the
	chunk was free'd. Because a free chunk requires 1 word for the size
	and 1 word for the link into the free list, no chunk will be allocated
	that is smaller than 4 bytes.

	The structure of the local memory block is as follows:
	    Block Start:
		Global handle of this block.
		Offset into the block where the heap begins.
		Flags.
	    Heap Info:
		Type of the lmem block (see flags to LMemInitHeap).
	    	Size of the entire block.
		Number of handles currently allocated.
		Pointer to first block of free list.
		Total amount of free space (sum of sizes of free blocks).
	    Block specific data
	    Handles
	    Chunks

NOTES:
	Much of this code assumes that the size of a local-memory handle
	is 1 word (2 bytes). This is assumed in searching for free handles
	and in allocating new handles. If you decide to change the size of
	a local-memory handle you need to update this code.

	Routines which might force the block to be unlocked and resized are
	marked with '***' at the top of the routine header near the routine
	name.

	Routines which actually do unlock, resize, and lock the block are
	marked with '+++'.

	It is also important to note that after any call to the local-memory
	manager all pointers (dereferenced handles) into the affected block
	that you may have had will no longer be valid. You must dereference
	the handles again. Be careful!!!

	If you are having strange problems with local memory blocks getting
	screwed up (like when the error checking code complains) you should
	try using the swat function "lhwalk" to examine and error-check the
	block. If there is a problem then you can try re-running using
	"showcalls -l" to show calls to the local memory manager.

	If neither one of these is illuminating, try placing calls to the
	ECLMemValidateHeap() routine in your code after any operations that you
	think might be screwing up the heap.

DESCRIPTION:
	Yet another implementation of the local-memory manager.

	$Id: lmemCode.asm,v 1.1 97/04/05 01:14:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


kinit	segment


COMMENT @----------------------------------------------------------------------

ROUTINE:	LMemInit

SYNOPSIS:	Initializes some lmem variables.

CALLED BY:	InitGeos

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 3/93       	Initial version

------------------------------------------------------------------------------@

if	INI_SETTABLE_HEAP_THRESHOLDS

LMemInit	proc	near
	;
	; Initialize some thresholds from the .ini file, if there.
	;

	push	ds
	mov	cx, cs
	mov	ds, cx
	mov	si, offset cs:systemCategoryString
	mov	dx, offset cs:lmemMinAllocationPaddingKey
	mov	ax, LMEM_MIN_ALLOCATION_PADDING		;default
	call	InitFileReadInteger
	pop	ds
	mov	ds:[lmemMinAllocationPadding], ax

	push	ds
	mov	ds, cx
	mov	dx, offset cs:lmemMaxAllocationPaddingKey
	mov	ax, LMEM_MAX_ALLOCATION_PADDING		;default
	call	InitFileReadInteger
	pop	ds
	mov	ds:[lmemMaxAllocationPadding], ax

	push	ds
	mov	ds, cx
	mov	dx, offset cs:lmemForceCompactThresholdKey
	mov	ax, LMEM_FORCE_COMPACT_THRESHHOLD	;default
	call	InitFileReadInteger
	pop	ds
	mov	ds:[lmemForceCompactThreshold], ax

	push	ds
	mov	ds, cx
	mov	dx, offset cs:lmemForceToughThresholdKey
	mov	ax, LMEM_FORCE_TOUGH_THRESHHOLD		;default
	call	InitFileReadInteger
	pop	ds
	mov	ds:[lmemForceToughThreshold], ax
	ret
LMemInit	endp


lmemMinAllocationPaddingKey	char	"lmemMinAllocationPadding",0
lmemMaxAllocationPaddingKey	char	"lmemMaxAllocationPadding",0
lmemForceCompactThresholdKey	char	"lmemForceCompactThreshold",0
lmemForceToughThresholdKey	char	"lmemForceToughThreshold",0

endif


kinit	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMemFixupES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup ES to point to the new block location if it was
		pointing to the block on entry.

CALLED BY:	INTERNAL (LMemInitHeap and others)
PASS:		ds	= LMem block
		on stack (pushed in this order):
			ds on entry to function (initial location of block)
			es on entry
RETURN:		es	= initial value or ds
		initial ds/es popped
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMemFixupES	proc	near	passedES:sptr, passedDS:sptr
	uses	ax
	.enter
	pushf
	mov	ax, passedES
	cmp	ax, passedDS
	jne	skipESPatch
	mov	ax, ds
skipESPatch:
	mov	es, ax
EC <	call	FarCheckDS_ES			;	>
	popf
	.leave
	ret	@ArgSize
LMemFixupES	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMemInitHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a local-memory heap block.

CALLED BY:	External.
PASS:		ds = segment of memory block to use as the heap.
		ax = type of heap to create (LMemType in lmem.def).
		bx = handle of the same memory block.
		cx = number of handles to allocate initially
		dx = offset in segment to the start of the heap
		si = amount of free space to allocate initially
		di = LocalMemoryFlags
RETURN:		ds = segment of block passed (may have changed).
		es = unchanged, unless es and ds were the same on entry to the
		     routine, in which case es and ds are the same on return.
DESTROYED:	nothing
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

NOTES:		It is important that the handle flags are not set to HF_LMEM
		until the end of the routine, otherwise the error checking code
		and the compaction code might attempt to manipulate the block
		when it is not fully created.

	Where possible, you should try to use the higher-level
	routines:  MemAllocLMem, VMAllocLMem, or UserAllocObjBlock
	rather than this one.


CHECKS:		bx is actual handle of memory segment in ds.
		Flags in ax are valid.
		Offset in dx is >= size LMemBlockHeader
		Block is locked.
		Heap is validated at the end of initialization.

PSEUDO CODE/STRATEGY:
	Store block handle and heap offset in first two words of the block.
	If there is not enough space after the offset for the header then
		Allocate some extra space.
	Endif
	Set increment amount (amount of extra space to allocate when resizing).
	Set pointer to end of allocated space.
	Set pointer to next free handle.
	Initialize free list to point at space at the end of the heap.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMemInitHeap	proc	far
	uses	ax, bx, cx, dx, di, si		;
	.enter					;
						;
	push	ds, es				; Save passed seg registers.
						;
EC <	cmp	dx, size LMemBlockHeader	; Check for bad offset	>
EC <	ERROR_B	BAD_OFFSET_TO_HEAP		;			>
EC <	cmp	ax, LMemType			; Check for bad type	>
EC <	ERROR_AE	BAD_HEAP_TYPE		;			>
EC <	test	di, not (mask LMF_HAS_FLAGS or mask LMF_DETACHABLE or \
			mask LMF_NO_HANDLES or mask LMF_NO_ENLARGE or \
			mask LMF_RETURN_ERRORS or mask LMF_RELOCATED or \
			mask LMF_IS_VM)	>
EC <	ERROR_NZ	LMEM_INIT_HEAP_BAD_FLAGS			>
EC <	test	di, mask LMF_NO_HANDLES					>
EC <	jnz	1$							>
EC <	tst	cx							>
EC <	ERROR_Z	LMEM_INIT_HEAP_BAD_DI					>
EC <1$:									>
EC <	tst	si							>
EC <	ERROR_Z	LMEM_INIT_HEAP_FREE_SPACE_MUST_BE_NON_ZERO		>

	; if LMF_NO_HANDLES passed then # handles = 0

	test	di, mask LMF_NO_HANDLES
	jz	notNoHandles
	clr	cx				;LMF_NO_HANDLES -> #handles=0
notNoHandles:

	push	ax				;save lmem type
	push	di				;save lmem flags

	RoundUp	dx				; align the offset.
	RoundUp	si				; round up free space
	inc	cx				; round #handles to multiple
	and	cx, 0xfffe			; to 2
						;
	segmov	es, ds				;
						;
EC <	push	di, ds				; need to save segment	>
EC <	mov	di, ds							>
EC <	LoadVarSeg	ds			;			>
EC <	cmp	di, ds:[bx].HM_addr		; does segment match handle? >
EC <	ERROR_NE NOT_IN_CORRECT_BLOCK		;			>
EC <	test	ds:[bx].HM_flags, mask HF_FIXED	; it doesn't have to be	>
EC <	jnz     skipLockCheck			;  locked if fixed...	>
EC <	cmp	ds:[bx].HM_lockCount, 0		; handle must be locked	>
EC <	ERROR_Z	BLOCK_NOT_LOCKED		;			>
EC <skipLockCheck:							>
EC <	pop	di, ds				;			>

	;
	; cx = # of handles.
	; si = heap space.
	; dx = offset to heap.
	;
	push	cx				; save initial # handles

	mov_trash	ax, si			; ax <- heap space
	shl	cx				;
	add	ax, cx				; ax <- size of heap + handle.
						;
	add	ax, dx				; ax <- plus offset to heap.
						;    (size needed for block).
	add	cx, dx				; cx <- first (only) free block
	inc	cx				;  (skip size word)
	inc	cx
	mov	ds:LMBH_freeList, cx

	; if address given for end of space then use it

	;
	; bx = handle to the block.
	; ax = the size to make the block.
	; dx = offset to place to put info structure.
	; ds = segment address of the block.
	;
	push	ds, ax				; if block is already larger
	LoadVarSeg	ds			;  than what we've decided we
	call	GetByteSize			;  need, don't shrink it --
	pop	ds, ax				;  just use that size. Allows
	xchg	ax, cx				;  something to have more than
						; ax = cur size, cx = desired
	cmp	ax, cx				;  2K free at the start
	jae	noReAlloc
	test	di, mask LMF_NO_ENLARGE
	jnz	noReAlloc
	
	mov_trash	ax, cx			;put size back in ax (was
						; swapped in case block was
						; big enough...)
	push	ax				;save size
	mov	ch, HAF_STANDARD_NO_ERR		;can't handle errors here.
	call	MemReAlloc			;make block new size.
	mov	ds, ax				;and re-set to our segment
	mov	es, ax				;
	pop	ax				;ax = size
noReAlloc:

	mov	ds:LMBH_handle, bx    		; save the handle with the heap
						;
	mov	ds:LMBH_offset, dx		; save offset to handle table
	;
	; ds = segment address of heap block.
	; dx = offset to heap start.
	; ax = size of the block.
	; on stack :
	;	1st - lmem type for the block.
	;
	pop	cx				; cx <- # of handles.
	mov	ds:LMBH_blockSize, ax		;
	mov	ds:LMBH_nHandles, cx		; set number of handles.
						;
	mov	di, dx				; es:di <- ptr to handles.
	; cx already holds the number of handles.
	clr	ax				;
	rep	stosw				; Mark all of them as free.
						;
;--------------------------------------------------
; Initialize the free block and the free list using the block size and heap
; start we calculated earlier.
;
	mov	cx, ds:LMBH_blockSize
	mov	si, ds:LMBH_freeList
	sub	cx, si
	jbe	noFree
	inc	cx
	inc	cx
	andnf	cx, LMEM_ALIGN_SIZE		; round down to proper alignment
						;  since block is only so big
	mov	ds:LMBH_totalFree, cx
	;
	; Set the size word in the free block.
	; ds:si points at the block.
	;
	mov	{word}ds:[si], ax		; no next link in free list.
	mov	ds:[si].LMC_size, cx		; set size word.
EC <	call	ECInitFreeChunk			;	>

	; Store header variables

afterFreeInit:

	pop	cx
	pop	ax
	mov	ds:LMBH_flags, cx
	mov	ds:LMBH_lmemType, ax		; set the block type.

	; if an object block then do special initialization
	;
	cmp	ax, LMEM_TYPE_OBJ_BLOCK
	jnz	notObjectBlock
	push	ax
	clr	ax
	mov	ds:OLMBH_inUseCount, ax
	mov	ds:OLMBH_interactibleCount, ax
	mov	ds:OLMBH_output.handle, ax
	mov	ds:OLMBH_output.chunk, ax
	mov	ds:OLMBH_resourceSize, ax
	pop	ax
notObjectBlock:

	test	cx, mask LMF_HAS_FLAGS
	jz	noFlags
	push	ax
	mov	al, mask OCF_IGNORE_DIRTY
	mov	cx,ds:LMBH_nHandles		;
	call	LMemAlloc			;allocate flags
	pop	ax
noFlags:

						;
	mov	si, ds				; save data segment.
	LoadVarSeg	ds			; ds <- kernel data segment.
	BitSet	ds:[bx][HM_flags],HF_LMEM	; Mark as an LMem block
	mov	ds, si				; restore data segment
						;
	call	LMemFixupES
	.leave					;
	ret					;
noFree:
	; No free space available in the heap -- set free list and totalFree
	; to 0.
	mov	ds:LMBH_freeList, ax
	mov	ds:LMBH_totalFree, ax
	jmp	afterFreeInit
LMemInitHeap	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LMemDeref

C DECLARATION:	extern void _far *
			_far _pascal LMemDeref(MemHandle mh,
							ChunkHandle chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
LMEMDEREF	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = chunk

	push	ds
	call	MemDerefDS
	mov_trash	bx, ax
	mov	ax, ds:[bx]
	mov	dx, ds
	pop	ds

	ret

LMEMDEREF	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LMemAlloc

C DECLARATION:	extern ChunkHandle
			_far _pascal LMemAlloc(MemHandle mh,
							word chunkSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
LMEMALLOC	proc	far
	C_GetTwoWordArgs	bx, cx,   ax,dx	;bx = han, cx = size

	push	ds
	call	MemDerefDS
	clr	ax				;no flags
	call	LMemAlloc
	pop	ds

	ret

LMEMALLOC	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
***		LMemAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate space on a local memory heap.

CALLED BY:	External.
PASS:		ds = segment pointer for the heap.
		al = object flags (if allocating in an object block)
		     ObjChunkFlags in lmem.def:
			    OCF_DIRTY
			    OCF_IGNORE_DIRTY
			    OCF_IN_RESOURCE
			    OCF_IS_OBJECT
		cx = amount of space to allocate.
RETURN:		carry = set if error (if LMF_RETURN_ERRORS set)
		ax = handle of the chunk.
		ds = segment address of same heap block.
		es = unchanged, unless es and ds were the same on entry to the
		     routine, in which case es and ds are the same on return.
DESTROYED:	nothing
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

CHECKS:		ds is a segment address of an lmem-heap block.
		Heap is validated on entry and exit.

PSEUDO CODE/STRATEGY:
	If there are no more handles then
		Allocate some more handles.
	Endif
	Get first free handle.
	Allocate space.
	Attach the handle to the space.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMemAlloc	proc	far
	uses	cx, dx, di			;
	.enter					;
						;
	InsertGenericProfileEntry PET_LMEM, 1, PMF_LMEM, ax		;
EC <	call	ECLMemValidateHeap		;		>
EC <	ornf	ds:[LMBH_flags], mask LMF_IN_LMEM_ALLOC		>

EC <	call	ForceBlockToMove					>

	push	ds, es				;save for LMemFixupES

	push	ax				;save object flags

	clr	di
	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	doAlloc
						;
	mov	dx, cx				; dx <- amount to allocate.
						;
	mov	di, ds:LMBH_offset		; ds:di <- ptr to heap.
	mov	cx, ds:LMBH_nHandles		; cx <- number of handles.
	segmov	es, ds				; es:di <- ptr to handles.
	clr	ax				; find empty handle please.
	jcxz	moreHandles			; we may not have any handles
	repne	scasw				; do the find.
	;
	; Either an empty handle has been found, or we have run out of
	; handles and need to allocate more handles.
	;
	je	foundHandle			; found one, go use it.
moreHandles:
	call	CreateMoreHandles		; Create more handles.
	jc	error
	inc	di				; make di point past new handle
	inc	di
foundHandle:					;
	dec	di				; es:di <- ptr to handle
	dec	di				;  (points beyond b/c of scasw)
						;
	mov	cx, dx				; cx <- size
doAlloc:
	pop	dx				; dx <- object flags
	call	AllocChunkHere
	jc	error
done:
	call	LMemFixupES

if AUTOMATICALLY_FIXUP_PSELF
	; We have to call ThreadFixupPSelf before we clear LMF_IN_LMEM_ALLOC.
	; Otherwise if we are called from a C method, the newly allocated
	; chunk is an object chunk, and "ec normal high lmem" is on, it dies
	; because the class pointer in the chunk isn't set up yet.
	; --- AY 8/6/96
	pushf
	call	ThreadFixupPSelf
	popf
endif

EC <	pushf								>
EC <	andnf	ds:[LMBH_flags], not mask LMF_IN_LMEM_ALLOC		>
EC <	popf								>
	InsertGenericProfileEntry PET_LMEM, 0, PMF_LMEM, ax		;
	.leave					;
	ret					;

error:
	test	ds:[LMBH_flags], mask LMF_RETURN_ERRORS
	stc
	jnz	done
	ERROR	LMEM_CANNOT_ALLOCATE

LMemAlloc	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ForceBlockToMove

DESCRIPTION:	Force a block to move if "ec lmemMove" is on. -- EC ONLY

CALLED BY:	INTERNAL -- LMemAlloc, LMemReAlloc

PASS:
	ds - block segment (locked)

RETURN:
	ds - new segment
	es - new segment if used to point to old segment

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/90		Initial version

------------------------------------------------------------------------------@


if	ERROR_CHECK

ForceBlockToMove	proc	near	uses	ax, bx, cx
	.enter

	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	done

	call	SysGetECLevel
	test	ax, mask ECF_LMEM_MOVE
	jz	done

	mov	cx, LCT_ALWAYS_COMPACT
	call	LMemCompactHeap

	; save "ds == es" status

	mov	ax, ds
	mov	bx, es
	cmp	ax, bx
	pushf

	mov	bx, ds:[LMBH_handle]
	LoadVarSeg	ds
	clr	cx		; move regardless of lock count
	call	MemForceMove
	mov	ax, ds:[bx].HM_addr	; ax <- block's new address

	mov	ds, ax

	popf
	jnz	done
	mov	es, ax
done:
	.leave
	ret

ForceBlockToMove	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
***		LMemContractBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Contract a given lmem block

CALLED BY:	Global
PASS:		bx = block handle to contract
RETURN:		none
		block is guaranteed to be at the same address if locked
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMemContractBlock	proc	far	uses	ax, cx, dx, si, di, ds
	.enter

	call	NearLock
	jc	exit
	mov	ds, ax
	call	LMemContract
	call	NearUnlock
exit:

	.leave
	ret

LMemContractBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
***		LMemContract
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Contract a given lmem block

CALLED BY:	Global
PASS:		ds = segment address of block to contract
RETURN:		none
		block is guaranteed to be at the same address if locked
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMemContract	proc	far	uses	ax, cx, dx, si, di, ds, bx
	.enter

	mov	bx, ds:[LMBH_handle]		; load up the block handle
	mov	dx, ds				;dx = segment address
	call	LoadVarSegDS
	call	PHeap

	call	ContractBlock

	call	VHeap

	.leave
	ret

LMemContract	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMemAllocHere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate memory in an LMem block, assigning it to a specific
		chunk handle. If the handle isn't free, return an error.

CALLED BY:	EXTERNAL (MergeObjBlock)
PASS:		ds	= block's segment
		al	= object flags, if object block
		cx	= size of chunk to allocate
		si	= chunk handle needed
RETURN:		carry clear if chunk allocated properly
		carry set if chunk already in-use
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMemAllocHere	proc	far
		uses	cx, dx, di
		.enter
EC <		call	ECLMemValidateHeap				>
EC <		ornf	ds:[LMBH_flags], mask LMF_IN_LMEM_ALLOC		>

		push	ds, es			;pass to AllocChunkHere
						;  for possible fixup of es
		segmov	es, ds			; wants es,ds = block
handleLoop:
	;
	; If the desired chunk is beyond the bounds of the block's handle
	; table, extend the table enough to accomodate it.
	;
		mov	di, ds:LMBH_nHandles
		shl	di
		add	di, ds:LMBH_offset	;di = last handle+2
		cmp	si, di
		jb	inRange
		call	CreateMoreHandles
		jmp	handleLoop
inRange:
		tst	{word}ds:[si]
		stc				;assume desired chunk isn't
						; free
		jnz	done			;=> not free, return carry set
	;
	; Do all the normal chunk-allocation stuff LMemAlloc does, passing
	; the object flags in dx instead of ax, and the handle in di.
	;
		mov	di, si
		xchg	dx, ax			;(1-byte inst)
		call	AllocChunkHere
		clc
done:
		lahf		; save carry for return
		call	LMemFixupES
EC <		andnf	ds:[LMBH_flags], not mask LMF_IN_LMEM_ALLOC	>
		sahf		; restore carry
		.leave
		ret
LMemAllocHere	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocChunkHere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize a chunk of memory, given the handle
		to which to assign it.

CALLED BY:	LMemAlloc, LMemAllocHere
PASS:		ds,es	= block in which to allocate it
		cx	= chunk size
		dx	= object flags (if in object block)
		di	= handle to which to assign the memory (0 -> no handle)
RETURN:		carry	= set if error
		ax	= handle
		es	= es from entry to caller (fixed up if was same as
			  ds on entry)
DESTROYED:	di, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocChunkHere	proc	near
	tst	di
	jz	noHandle
	mov	{word}ds:[di],LMEM_NOMEM_HANDLE ; assume no memory.
	mov	ax, di				;  assume no memory
	jcxz	done				; quit if none desired.

	;
	; es:di = ptr to the handle to use.
	; cx    = amount of data-space to allocate.
	;
	call	AllocAndAssociate		; Allocate memory and associate
						;  it with the given handle.
	jc	exit				;If no space, exit
	mov_trash	di, ax			; di <- chunk
	mov	ds:[di].LMC_size, cx	; save the size.
						;
						;
done:
	;
	; Set object flags (if in an object block)
	;
	test	ds:LMBH_flags,mask LMF_HAS_FLAGS
	jz	noFlags

EC <	test	dl,not mask ObjChunkFlags				>
EC <	ERROR_NZ	BAD_LMEM_FLAGS					>

	mov	di,ds:[LMBH_offset]		;*ds:si = flags
	mov	cx, ax
	sub	cx, di
	shr	cx				;cx = handle #
	mov	di,ds:[di]			;ds:si = flags
	add	di,cx

	mov	ds:[di],dl
	xchg	al,dl				;flags in al
	call	ObjHandleDirtyFlags
	xchg	al,dl

noFlags:
	;
	; In the error checking version we will be nuking any unused bytes that
	; are at the end of the chunk.
	;
EC <	push	si				;	>
EC <	mov	si, ax				;	>
EC <	mov	si, ds:[si]			;	>
EC <	cmp	si, LMEM_NOMEM_HANDLE		;	>
EC <	je	skipInit			;	>
doInit:
EC <	call	ECInitEndOfChunk		;	>
EC <skipInit:					;	>
EC <	pop	si				;	>
	clc
exit:
	ret

	; allocate in a chunk that has no handles
	; Can't set flags, etc.

noHandle:
EC <	tst	cx							>
EC <	ERROR_Z CANNOT_ALLOC_CHUNK_OF_ZERO_SIZE_IF_LMF_NO_HANDLES_SET	>
	call	AllocAndAssociate
	jc	exit
	mov	di, ax			; di <- chunk
	mov	ds:[di].LMC_size, cx	; save the size.
EC <	push	si				;	>
EC <	mov	si, ax				;	>
	jmp	doInit

AllocChunkHere	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocAndAssociate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a chunk and associate it with a given handle.

CALLED BY:	LMemAlloc, LMemReAlloc
PASS:		ds,es = segment address of a local memory block.
		ds:di = the handle to associate memory with (if 0, no handle)
		cx    = the desired size of the chunk

RETURN:		handle filled with the offset of the chunk (if non-zero).
		carry - set if error
		ax    = offset of the chunk
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocAndAssociate	proc	near
	inc	cx
	inc	cx				; need size word too.
	push	cx				; save total size.
	RoundUp	cx				; align size.
	call	FindFreeSpace		; Search free list for space.
	pop	cx
	jc	done
	tst_clc	di			;If no chunk handle, branch
	jz	done
	;
	; ds:di = ptr to handle to use.
	; ax = ptr to the chunk to use.
	;
	mov	ds:[di], ax		; save ptr to chunk.
done:
	ret				;
AllocAndAssociate	endp
COMMENT @----------------------------------------------------------------------

C FUNCTION:	LMemFree

C DECLARATION:	extern void
			_far _pascal LMemFree(MemHandle mh,
							ChunkHandle chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
LMEMFREE	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = chunk

	push	ds
	call	MemDerefDS
	call	LMemFree
	pop	ds

	ret

LMEMFREE	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMemFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the space occupied by a local memory chunk.

CALLED BY:	External.
PASS:		ax = handle of the chunk to remove.
		ds = segment address of the local memory heap.
RETURN:		nothing
DESTROYED:	nothing

CHECKS:		Heap is validated on entry and exit.

PSEUDO CODE/STRATEGY:
	Add the handle to the list of free handles.
	If the handle has associated memory then
	    Add the chunk the the free list.
	Endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMemFree	proc	far
	uses	si				;
	.enter					;

EC <	cmp	ax, size LMemBlockHeader	; can't be less than	>
EC <	ERROR_B ILLEGAL_HANDLE						>
EC <	test	ds:[LMBH_flags], mask LMF_NO_HANDLES			>
EC <	jnz	10$							>
EC <	call	ECLMemExists						>
EC <10$:								>

if	ERROR_CHECK

	; IF block has flags for each chunk, then make sure we're not
	; trying to free a chunk that came from a resource block.  This
	; is a BAD thing to do & will cause death on reattaching the
	; application later, so let's catch it NOW.
	;
	test	ds:[LMBH_flags], mask LMF_HAS_FLAGS
	jz	ECAfterFlagCheck		; If doesn't have flags, skip
						;	check
	test	ds:[LMBH_flags], mask LMF_DETACHABLE
	jz	ECAfterFlagCheck		;if not detachable then freeing
						;	a chunk is OK
	push	ax
	call	ObjGetFlags			; Get flags for chunk
	test	al, mask OCF_IN_RESOURCE	; See if chunk is in a resource
						; If so, kindly blow up.
	ERROR_NZ	LMEM_RESOURCE_CHUNKS_MAY_NOT_BE_FREED
	pop	ax
ECAfterFlagCheck:
endif

	mov	si, ax				; si <- handle.
	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	noHandles

	push	ds:[si]				; save ptr.
	mov	word ptr ds:[si], 0		; nuke handle.
	pop	si				; si <- ptr to chunk.
	cmp	si, LMEM_NOMEM_HANDLE		; check for no memory.
	je	LMF_done			;
noHandles:
	call	AddFreeBlock			; add ds:si to free list.
LMF_done:					;
	.leave					;
	ret					;
LMemFree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
***		LMemReAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the size of a chunk in a local-memory heap.

CALLED BY:	External.
PASS:		ax = handle of the chunk.
		cx = size to resize the chunk to.
		ds = segment address of the local-memory heap.

RETURN:		ds = segment address of same lmem heap (may have moved).
		es = unchanged, unless es and ds were the same on entry to the
		     routine, in which case es and ds are the same on return.
		carry = set if error (errors only returned in LMF_RETURN_ERRORS
			is set)

		if lmem block has LMF_NO_HANDLES set:
		    ax - chunk handle (address) of resized chunk.

DESTROYED:	nothing
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

CHECKS:		ds is a segment address of an lmem-heap block.
		ax is a handle of a non-free block on this heap.
		Heap is validated on entry and exit.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Special case code to handle re-allocation to zero.
;
LMRA_allocToZero	label	near
	pop	cx
EC <	test	ds:[LMBH_flags], mask LMF_NO_HANDLES			>
EC <	ERROR_NZ	CANNOT_REALLOC_CHUNK_TO_ZERO_SIZE_IF_LMF_NO_HANDLES_SET>
	mov	ax, LMEM_NOMEM_HANDLE		; set to indicate no memory
	xchg	ax, ds:[si]			;  and fetch old pointer
	xchg	ax, si				; ds:si = old block, ax = handle
	cmp	si, LMEM_NOMEM_HANDLE		; had no memory before?
	je	toQuit				; yes -- done
	call	AddFreeBlock			; free old block
toQuit:
	jmp	LMRA_quit

;---

LMemReAlloc	proc	far
	uses	bx, si				;
	.enter					;
	
	InsertGenericProfileEntry PET_LMEM, 1, PMF_LMEM, ax		;

	push	ds, es				; Save passed seg registers
						;  for LMemFixupES
						;
EC <	test	ds:[LMBH_flags], mask LMF_NO_HANDLES			>
EC <	jnz	10$							>
EC <	call	ECLMemExists						>
EC <10$:								>
EC <	ornf	ds:[LMBH_flags], mask LMF_IN_LMEM_ALLOC			>
						;
	push	cx				; save actual size.
	segmov	es, ds				; es <- segment addr of block.
	mov	bx, ax				; save handle (also for
						;  reference, of course...)

	mov	si, ax				; si <- handle to old data

	call	ObjMarkDirty			; mark chunk (and block) dirty

	jcxz	LMRA_allocToZero		; handle case of realloc to 0.
						;
	push	di
	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	hasMemory

	mov	si, ds:[bx]			; ds:si <- ptr to chunk.
	cmp	si, LMEM_NOMEM_HANDLE		; check for no memory with this
	jne	hasMemory			;
	;
	; This handle has no memory associated with it.
	; We call AllocAndAssociate() to grab some memory for it.
	;

EC <	call	ForceBlockToMove					>

	mov	di, bx				; ds:di <- ptr to handle.
	call	AllocAndAssociate		; Get some memory please.
	mov	si, ds:[bx]
	LONG jnc donePopDI			; ok to quit now.
	jmp	errorPopDICX

hasMemory:					;
	inc	cx
	inc	cx				; need size word.
	RoundUp	cx				;
	mov	ax, ds:[si].LMC_size		; ax <- old size.
	RoundUp	ax			;
						;
	cmp	cx, ax				; compare new-size to old-size.
	LONG je	donePopDI			; quit if same size.
	;
	; Note that the flags from the compare are used below. None of the
	; next few instructions alters the flags.
	;
	push	dx				;  donePopDI to work...
	mov	dx, cx				; want size in dx.
	mov	di, si				; want pointer to block in di
						; for LMF_NO_HANDLES case
						; documented below
	;
	; Now we branch according the size change.
	;
	jb	smaller				;

EC <	test	ds:[LMBH_flags], mask LMF_NO_HANDLES			>
EC <	jnz	20$							>
EC <	call	ForceBlockToMove					>
EC <	mov	si, ds:[bx]						>
EC <20$:								>

	;
	; New size is larger than old size.
	; ax == old size (rounded).
	; cx, dx == new size (rounded).
	; ds:si == ptr to chunk.
	; ds:bx == ptr to handle.
	;

	call	QuickLMemReAlloc		; Try a quick re-alloc.
	jc	changeDone			; quit if it works out.

	; If the block has a bunch of free space but not enough to satisfy the
	; request, then compact it and try the quick way again

	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	noForceCompact
if	INI_SETTABLE_HEAP_THRESHOLDS
	push	ax, es
	mov	ax, segment lmemForceCompactThreshold
	mov	es, ax
	mov	ax, es:lmemForceCompactThreshold
	cmp	ds:[LMBH_totalFree], ax
	pop	ax, es
else
	cmp	ds:[LMBH_totalFree], LMEM_FORCE_COMPACT_THRESHHOLD
endif
	jb	noForceCompact
	cmp	ds:[LMBH_totalFree], cx
	ja	noForceCompact
	push	cx
	mov	cx, LCT_ALWAYS_COMPACT
	call	LMemCompactHeap
	pop	cx
	mov	si, ds:[bx]
	call	QuickLMemReAlloc
	jc	changeDone
noForceCompact:

	mov_tr	dx, ax				; Preserve old size

	; If the chunk to reallocate is too large then always use the "tough"
	; method

	test	ds:[LMBH_flags], mask LMF_NO_HANDLES or mask LMF_NO_ENLARGE
	jnz	noForceTough
if	INI_SETTABLE_HEAP_THRESHOLDS
	push	ds, ax
	mov	ax, segment lmemForceToughThreshold
	mov	ds, ax
	cmp	dx, ds:lmemForceToughThreshold
	pop	ds, ax
else
	cmp	dx, LMEM_FORCE_TOUGH_THRESHHOLD
endif
	jae	tough
noForceTough:

	; Temporarily make sure that FindFreeSpace will always return an
	; error if it couldn't allocate (rather than stalling) no matter
	; what has been requested. The only exception is if we are not
	; prepared to use the "tough" method later. mgroeber -- 3/27/00
	
	push	ds:[LMBH_flags]
	test	ds:[LMBH_flags], mask LMF_NO_HANDLES or mask LMF_NO_ENLARGE
	jnz	25$
	or	ds:[LMBH_flags], mask LMF_RETURN_ERRORS
25$:
	call	FindFreeSpace			; Find a free chunk somewhere.
	pop	ds:[LMBH_flags]
	jnc	notTough

	; There is not enough space to use the standard "allocate and copy"
	; method of reallocation, thus we must use the painful (and slower)
	; method

	test	ds:[LMBH_flags], mask LMF_NO_HANDLES or mask LMF_NO_ENLARGE
	jnz	errorPopDXDICX
tough:
	call	ToughLMemReAlloc
	jc	errorPopDXDICX
	jmp	changeDone

notTough:
	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	30$
	mov	si, ds:[bx]			; si <- chunk addr (may have
						;  moved)
	mov	ds:[bx], ax			; save new ptr into handle.
30$:
	mov	di, ax				;ES:DI <- ptr to dest
	mov	cx, dx				; cx <- number of words to move
	shr	cx, 1				;
	dec	cx				;    don't move size word.
	mov	dx, si				; save ptr to old block for free
	rep	movsw				; move data.
	mov	si, dx				; ds:si == ptr to block to free
	mov_trash di, ax			; ds:di <- ptr to new block

	;
	; FALL THROUGH to "split" the old block into a 0-byte used portion (cx
	; is 0 from the REP instruction) and a free portion containing the
	; whole old block.
	;

smaller:
	;
	; New size is smaller than old size.
	; cx == new size (rounded).
	; ds:si == ptr to the block.
	; ds:bx == ptr to the handle.
	;
	mov	dx, cx				; want size in dx.
	call	LMemSplitBlock			; Split block, add top to free.
	mov	si, di				;Reload SI with pointer to
						; realloc'd block. This is 
						; necessary for the no-handles
						; case, as we can't reload it
						; from the handle below.
changeDone:					;
	pop	dx
donePopDI:
	pop	di				;
	pop	cx				; get actual size.

	; bx = handle, cx = actual size requested

	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	noHandle
	mov	si, ds:[bx]
noHandle:
	mov	ax, cx				; bx <- size of block +
	inc	ax				;  2 for the size word
	inc	ax				;  itself
	mov	ds:[si].LMC_size, ax		; save the size
	mov_trash	ax, bx			; ax <- handle (again)

	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jz	gotHandle
	mov	ax, si				;ax = address
gotHandle:
EC <	call	ECInitEndOfChunk					>

LMRA_quit label near					;
	clc
done:
	call	LMemFixupES

if AUTOMATICALLY_FIXUP_PSELF
	; We have to call ThreadFixupPSelf before we clear LMF_IN_LMEM_ALLOC.
	; Otherwise if we are called from a C method, the newly allocated
	; chunk is an object chunk, and "ec normal high lmem" is on, it dies
	; because the class pointer in the chunk isn't set up yet.
	; --- AY 8/6/96
	pushf
	call	ThreadFixupPSelf
	popf
endif

EC <	pushf								>
EC <	andnf	ds:[LMBH_flags], not mask LMF_IN_LMEM_ALLOC		>
EC <	popf								>
EC <	call	ECLMemValidateHeap					>

	InsertGenericProfileEntry PET_LMEM, 0, PMF_LMEM, ax

	.leave					;
	ret					;

errorPopDXDICX:
	pop	dx
errorPopDICX:
	pop	di
	pop	cx
	test	ds:[LMBH_flags], mask LMF_RETURN_ERRORS
	stc
	jnz	done
	ERROR	LMEM_CANNOT_ALLOCATE

LMemReAlloc	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LMemInsertAt

DESCRIPTION:	Insert space in the middle of a chunk.  The new space is
		initialized to zeros.

CALLED BY:	GLOBAL

PASS:
	ds - segment of lmem heap
	ax - chunk
	bx - offset to insert at
	cx - number of bytes to insert

RETURN:
	carry - set if error (errors only returned in LMF_RETURN_ERRORS is set)
	ds - same block (possibly changed)

DESTROYED:
	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

LMemInsertAt	proc	far
	uses	ax, cx, si, di
	.enter

EC <	call	ECLMemExists						>
EC <	push	cx, si							>
EC <	mov	si,ax							>
EC <	call	ChunkSizeHandleDS_SI_CX					>
EC <	cmp	bx,cx							>
EC <	ERROR_A	LMEM_BAD_INSERT_OFFSET					>
EC <	pop	cx, si							>
EC <	test	ds:[LMBH_flags], mask LMF_NO_HANDLES			>
EC <	ERROR_NZ	OPERATION_REQUIRES_CHUNK_HANDLES		>
					;
	jcxz	doneGood		; quit if nothing to insert.
					;
	push	ax			; save chunk handle.
	mov	si, ax			; si <- chunk handle.

	xchg	cx, di
	call	ChunkSizeHandleDS_SI_CX
	xchg	cx, di

	mov	si, cx			; Save # of bytes to insert.
	add	cx, di			; cx <- new total size.
	call	LMemReAlloc		; Resize chunk.
	pop	di			; di <- chunk handle.
	jc	done
	mov	ax, ds:[di]		; ax = chunk address
	;
	; making object larger, start at top and move down
	;
	; bx = offset at which to insert
	; cx = chunkSize
	; si = bytes to insert
	; dest = chunkEnd - 1
	; source = dest - (bytes to insert)
	; count = source - (insert offset) + 1
	;
	push	es			; save passed segment register.
	push	si			; save number to insert
	segmov	es,ds			; both ds and es point at block
	mov	di,cx			; di = offset to end of chunk
	dec	di			; di = top (dest)
	sub	si,di			; si = #insert - dest
	neg	si			; si = source (dest - #insert)
					;
	mov	cx,si			;
	sub	cx,bx			;
	inc	cx			; cx = count
					;
	add	si,ax			;
	add	di,ax			;
	std				;
	rep	movsb			;
	pop	cx			; cx = # to insert
	clr	ax			; zero inserted space
	rep	stosb			;
	cld				;
	pop	es			; restore passed segment register.

;EEC <	call	ECLMemValidateHeap					>
doneGood:
	clc
done:
	.leave
	ret
LMemInsertAt	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LMemDeleteAt

DESCRIPTION:	Delete space in the middle of a chunk

CALLED BY:	GLOBAL

PASS:
	ds - segment of lmem heap
	ax - chunk
	bx - offset to delete at
	cx - number of bytes to delete

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
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

LMemDeleteAt	proc	far
	uses	ax, si, di
	.enter

EC <	call	ECLMemExists						>
EC <	push	ax, bx, si						>
EC <	mov	si,ax							>
EC <	xchg	ax, cx							>
EC <	call	ChunkSizeHandleDS_SI_CX					>
EC <	xchg	ax, cx				;ax = size		>
EC <	cmp	bx,ax							>
EC <	ERROR_A	LMEM_BAD_DELETE_OFFSET					>
EC <	cmp	cx,ax							>
EC <	ERROR_A	LMEM_BAD_DELETE_SIZE					>
EC <	add	bx,cx							>
EC <	cmp	bx,ax							>
EC <	ERROR_A	LMEM_BAD_DELETE_COMBINATION				>
EC <	pop	ax, bx, si						>
EC <	test	ds:[LMBH_flags], mask LMF_NO_HANDLES			>
EC <	ERROR_NZ	OPERATION_REQUIRES_CHUNK_HANDLES		>

	jcxz	LDA_ret

	;
	; move data first (so that LMemReAlloc does not trash it)
	;
	; bx = ofset to insert at
	; cx = # bytes to insert
	; dest = chunkPos + (delete offset)
	; source = dest + (# to delete)
	; count = chunkEnd - source
	;
	push	ax, cx, es			; Save chunk handle, # to delete
	segmov	es,ds				; Both ds and es point at block
	mov	si, ax				;
	mov	di, ds:[si]			;
	mov	si, cx				; si <- # to delete.
	ChunkSizePtr	ds, di, cx		; cx <- size of chunk.
						;
	cmp	cx, si				; Check for deleting everything
	je	afterMove			;
						;
	push	cx				; Save chunk size
	add	cx,di				; cx = end of chunk
	add	di,bx				; di = dest
	add	si,di				; si = source
	sub	cx,si				;
	shr	cx
	rep	movsw				;
	jnc	notOdd
	movsb
notOdd:
	pop	cx				; recover chunk size
afterMove:					;
	pop	ax, si, es			; Restore handle, # to delete.
	sub	cx,si				; cx <- new chunk size.
	call	LMemReAlloc			; Re-alloc block.
						;
	mov	cx, si				; Restore cx before leaving.
;EEC <	call	ECLMemValidateHeap		;			>
LDA_ret:					;
	.leave					;
	ret					;

LMemDeleteAt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECLMemExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the chunk exists on the heap.
		Sees first if we've ever used the handle (by comparing with
		LMBH_nextHandle), then makes sure the chunk for that handle
		wasn't deleted previously.

		This routine should be called by applications if they are
		not sure about their handle, whether it exists or not.  This
		check will no longer be made in the other routines for speed
		reasons.

CALLED BY:	INTERNAL

PASS:		ax -- the handle in question
		ds -- segment of our heap

RETURN:		carry clear always. (Signals that chunk does exist).
		This routine will call FatalError() if the chunk does not
		exist.

DESTROYED:	nothing.

PSEUDO CODE/STRATEGY:
	We need to do a good job of catching bad handles:
		1. Offset from start of addresses must be multiple of 4
		2. Handles < LMBH_offset+SIZE heapHeader are bad
		3. Handles >= LMBH_nextHandle are bad
		4. Handles that have a null pointer are bad

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/18/88	Initial version
	John	 4/19/89	Minor changes.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECLMemExists	proc	far
EC <	push	si			; Save this		>
EC <	call	ECLMemValidateHeap	; Check the heap	>
EC <	mov	si, ax			; si <- handle.		>
EC <	call	ECLMemValidateHandle	; Check the handle.	>
EC <	mov	si, ds:[si]		; ds:si <- chunk ptr.	>
EC <	tst	si			;			>
EC <	jnz	LME_done		; must be non-zero	>
EC <	ERROR	ILLEGAL_HANDLE		;			>
EC <LME_done:				;			>
EC <	pop	si			; Restore this.		>
EC <					;			>
EC <	clc				; if we get back, handle must be  >

	ret
ECLMemExists	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickLMemReAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try to expand a chunk into an adjacent free chunk.

CALLED BY:	LMemReAlloc
PASS:		ds:si = ptr to chunk to try to expand.
		bx    = ptr to handle (if any)
		ax    = old size.
		dx    = desired size (must be aligned)
		es    = ds
RETURN:		carry set if quick re-alloc was possible.
		si    = possibly changed (due to re-alloc)
		NOTE: LMC_size is *not* set for the block if successful.
		since LMemReAlloc sets the size anyway, there doesn't seem
		to be much point...
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/28/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuickLMemReAlloc	proc	near	uses	ax, cx, dx, di, bp
	.enter

	; calculate # extra bytes needed

	sub	dx, ax				; both ax & dx are aligned

	mov	cx, si				; cx = ptr to chunk
	mov	bp, ax
	add	bp, si				; bp <- ptr to next chunk.
	cmp	bp, ds:LMBH_blockSize		; check for gone too far.
	jae	tryBefore			; quit if past the end.
	mov	si, offset LMBH_freeList	; ds:si <- ptr to free list.
scanFreeLoop:
	mov	di, si				; di = last free
	mov	si, ds:[si]			; get next free chunk.
	tst	si				; quit if chunk not free.
	jz	tryBefore
	cmp	si, bp				; check for next free.
	jne	scanFreeLoop			; loop if not found.

	; Next chunk is free.

	call	testSizeAndRemove
	jnc	tryBefore
doneGood:
	call	LMemSplitBlock			; Split the chunk please.
;;this should not be done as SI = free block that was split, not incoming
;;block to realloc
;;however, when we branch to doneGood from below (where we've allocated
;;a completely new chunk, we do need 'mov cx, si', so we add that below)
;;	mov	cx, si
	stc					; signal success
done:
	mov	si, cx
	.leave
	ret

	; there is no acceptable before after, try before

tryBefore:
	mov	si, offset LMBH_freeList	; ds:si <- ptr to free list.
scanFreeLoop2:
	mov	di, si				; di = last free
	mov	si, ds:[si]			; get next free chunk.
	tst	si				; quit if chunk not free.
	jz	done				; (carry cleared by tst)
	mov	bp, si				; bp = address of free chunk
	add	bp, ds:[si].LMC_size		; bp = address of chunk after
						; free chunk
	cmp	bp, cx				; check for previous free.
	jne	scanFreeLoop2			; loop if not found.

	; Previous chunk is free

	call	testSizeAndRemove
	jnc	done

	add	ds:[si].LMC_size, ax
	add	dx, ax				; dx = total size for chunk

	; copy chunk data down

	push	si
	mov	di, si				; es:di = dest
	mov	si, cx				; ds:si = source
	mov_tr	cx, ax
	shr	cx
	rep	movsw
	pop	si				; si = new block

	; fix the handle (if needed)

	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	noFixHandle
	mov	ds:[bx], si
noFixHandle:
;;added for above fix
	mov	cx, si				; for NO_HANDLES case
	jmp	doneGood

;---
	; ds:si = ptr to free chunk.
	; dx	= extra size needed.

	; return carry set if success

testSizeAndRemove:
	mov	bp, ds:[si].LMC_size
	cmp	dx, bp				; if not enough space then quit
	ja	testDone

	; unlink free block here (to avoid another search of the free list)

	sub	ds:LMBH_totalFree, bp
	mov	bp, ds:[si]
	mov	ds:[di], bp
	stc
testDone:
	retn

QuickLMemReAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToughLMemReAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-allocate a block the hard way.

CALLED BY:	LMemReAlloc
PASS:		ds = segment address of the lmem heap.
		bx = the handle to the chunk.
		cx = desired size for the chunk.
		     This should include the size word.
		     The value should be aligned.
RETURN:		carry set if error
DESTROYED:	ax, bx, cx, dx, es, di, si

PSEUDO CODE/STRATEGY:
	- Compact the heap.
	- Figure out how much the block needs to expand.
	- Call FindFreeSpace() to get a block of that size.
	- Knowing how the allocation routines work, we will get a heap that
	  looks like:
	  	Block-1 ... Block-n Extra-space Free-space
	- Shift all blocks after the re-alloc'ing one down.
	- Reset the tag-words on the re-alloc'd block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/20/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChunkArray segment resource

ToughLMemReAlloc	proc	far
	segmov	es, ds				; es == ds == heap segment.

EC <	call	ECLMemValidateHeapFar					>
						;
	push	cx
	mov	di, ds:[bx]			; ds:di <- ptr to chunk.
	mov	dx, ds:[di].LMC_size		;
	RoundUp	dx				;
	xchg	cx, dx				; cx = old size, dx = desired
	sub	dx, cx				; dx <- additional size.
	call	GetSpaceExact			; get 'dx' bytes and some extra
	jnc	10$
	pop	cx				; restore stack
	ret
10$:

EC <	call	ECLMemValidateHeapFar					>

	clr	si
	mov	ds:LMBH_totalFree, si		; no more free space.
	xchg	si, ds:LMBH_freeList		; ds:si <- ptr to free chunk.
	;
	; *ds:bx = chunk
	; ds:si  = ptr to free space
	; dx     = size of free space (distance to move)
	;
	; # Bytes to move = freeChunkAddr-chunkPos-oldSize
	;
	mov	di, ds:[bx]			; ds:di <- ptr to chunk
	add	ds:[di].LMC_size, dx
	neg	cx				; cx = -oldSize
	add	cx, si
	sub	cx, di				; cx = # bytes to move
	shr	cx

	sub	si, 4				; ds:si = source
	mov	di, si
	add	di, dx				; ds:di = dest
	std
	rep	movsw
	cld

	; bumb all chunk handles after the block to realloc up by the
	; ammount moved
	; dx = distance moved
	; bx = handle of chunk being realloc'ed

	mov	cx, ds:[LMBH_nHandles]
	mov	di, ds:[bx]			;ds:di = chunk being realloc'ed
	mov	si, ds:[LMBH_offset]		;ds:si = handles
handleLoop:
	lodsw					;get handle
	inc	ax
	jz	next
	dec	ax
	cmp	ax, di
	jbe	next
	add	ds:[si-2], dx
next:
	loop	handleLoop

EC <	call	ECLMemValidateHeapFar					>

	mov	si, di				; ds:si <- ptr to block
	pop	dx
	call	LMemSplitBlock

EC <	call	ECLMemValidateHeapFar					>
	clc
	ret

ToughLMemReAlloc	endp

ChunkArray ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a block to the free list.

CALLED BY:	LMemFree, LMemReAlloc, LMemSplitBlock
PASS:		ds = segment address of the heap block.
		ds:si = ptr to the block to add to the list.
RETURN:		nothing
DESTROYED:	nothing

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
	uses	ax, bx, cx, di, si		;
	.enter					;
						;
	mov	ax, ds:[si].LMC_size		; ax <- size.
	RoundUp	ax				;
	mov	ds:[si].LMC_size, ax		; set free block size to rounded
						;  size...
	add	ds:LMBH_totalFree, ax		; update free space.
						;
	mov	cx, ds:LMBH_nHandles		;
	shl	cx, 1				; cx <- size of handle table.
	add	cx, ds:LMBH_offset		; cx <- ptr to heap start.
						;
	mov	bx, si				; bx <- ptr to item.
	mov	di, LMBH_freeList		; ds:si <- ptr to start of list
AFB_loop:					;
	mov	si, di				;
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
	; cx    = ptr to start of heap.
	; ds:LMBH_blockSize = ptr to end of heap.
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
	cmp	si, cx				; check for at start of heap.
	jbe	AFB_notPrev			; can't combine with prev if so
						;
	mov	ax, ds:[si].LMC_size		;
	add	ax, si				; ax <- prev + size-prev
	cmp	ax, bx				;
	jne	AFB_notPrev			;
	;
	; Combine previous and current.
	;
	mov	ax, ds:[bx].LMC_size		;
	add	ds:[si].LMC_size, ax		; add current's size to prev
						;
	mov	ax, ds:[bx]			; ax <- free-list ptr of 2nd.
	mov	ds:[si], ax			; re-link free list.
						;
	mov	bx, si				; current is now combination.
AFB_notPrev:					;
	mov	ax, ds:[bx].LMC_size		;
	add	ax, bx				; bx <- cur + cur-size.
						;
	cmp	ax, ds:LMBH_blockSize		; check for on last chunk.
	jae	AFB_notNext			; quit if it is.
						;
	cmp	ax, di				;
	jne	AFB_notNext			;
	;
	; Combine current and next.
	;
	mov	ax, ds:[di].LMC_size		;
	add	ds:[bx].LMC_size, ax		; save new size.
						;
	mov	ax, ds:[di]			; re-link free list.
	mov	ds:[bx], ax			;
AFB_notNext:					;
	;
	; ds:bx = pointer to the free block (or combination of free blocks).
	; In the error checking version we init the entire block (except for
	; the size and link) to 0xcc.
	;
EC <	xchg	si, bx				;	>
EC <	call	ECInitFreeChunk			;	>
EC <	xchg	si, bx				;	>
	.leave					;
	ret					;
AddFreeBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
+++		CreateMoreHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate more lmem handles for an lmem block.

CALLED BY:	LMemAlloc
PASS:		ds, es = segment address of the lmem heap.
RETURN:		carry - set if error
		ds, es = segment of same heap, perhaps moved.
		di = ptr to the start of the new handles.
		     This handle pointed to is guaranteed to be free.
		more handles allocated.
DESTROYED:	nothing

CHECKS:		All handle pointers are non-zero.
		Heap is validated on entry and exit.

NOTES:		This routine can cause the heap to be compacted. This means
		that all pointers directly into the heap (pointers to chunks)
		are not valid when this routine returns. It is important that
		you reset your pointers by dereferencing a handle. If you
		don't have a handle then you are screwed.

PSEUDO CODE/STRATEGY:
	A call to GetSpaceExact() garbage collects the heap and allocates
	space at the end of it.

	The data in the heap is shifted down to make space for the new
	handles.

	The new handles are initialized to 0.

	The old handles get updated to point at the new positions of the data.

	The free-list pointer is updated to point at the free space.

	The amount of free space is reduced by the amount allocated for
	handles.

	The free-block at the end of the buffer has its size/flags word
	updated to reflect its smaller size.

	Update the number of handles.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateMoreHandles	proc	near
	uses	ax, cx, dx, si, bp		;
	.enter					;

	test	ds:[LMBH_flags], mask LMF_HAS_FLAGS
	jz	noFlags
	mov	ax,ds:LMBH_offset		;reallocate flags to acount
	mov	cx,ds:LMBH_nHandles		; for new handles
	add	cx, LMEM_HANDLE_INCR
	call	LMemReAlloc			;
EC <	;								>
EC <	; Turn LMF_IN_LMEM_ALLOC back on after LMemReAlloc clears it.	>
EC <	; We should leave it on for our caller.				>
EC <	;								>
EC <	lahf								>
EC <	BitSet	ds:[LMBH_flags], LMF_IN_LMEM_ALLOC			>
EC <	sahf								>
	jc	done
noFlags:

						; amount of space needed.
	mov	dx, (LMEM_HANDLE_INCR * 2)
	call	GetSpaceExact			; get exactly dx bytes of free.
	jc	done

	;
	; Shift the data up to make room for the handles.
	;
	std					; copy from the end
	mov	dx, ds:LMBH_nHandles		; dx <- # of handles.
	shl	dx, 1				; dx <- offset to after handles
	add	dx, ds:LMBH_offset		;
	;
	; We copy from the entire heap up. We only copy the first 2 words of
	; the free-block up. These two words consist of the size/flags word
	; and the ptr to the next free block (always zero).
	;
	mov	si, ds:LMBH_freeList		; pointer to end of data. (src)
	mov	di, si				; es:di <- dest.
	add	di, LMEM_HANDLE_INCR * 2	;
	mov	cx, si				;
	sub	cx, dx				; cx <- # of bytes.
	shr	cx, 1				;
	inc	cx				; copy free size word
	rep	movsw				; do it.
	cld					; reset direction.
	;
	; Now space has been made. Initialize new handles to zero.
	; ds:dx == ptr to new handles.
	;
	clr	ax				; value to store.
	mov	di, dx				; es:di <- ptr to handles.
	mov	cx, LMEM_HANDLE_INCR		; cx <- # of new handles.
	rep	stosw				; init handles.
	;
	; Update old handles.
	;
	mov	cx, ds:LMBH_nHandles		; cx <- # old handles.
	mov	si, ds:LMBH_offset		; si <- ptr to handle table.
	mov	di, si
	mov	dx, LMEM_HANDLE_INCR * 2	; amount to add.
	jcxz	updateComplete
CMH_handleUpdateLoop:				;
	lodsw					; ax <- value in handle.
	mov	bp, ax				; so we may trash it...
	inc	bp				; check for no memory.
	jz	CMH_loopNext			; skip if it has none.
	dec	bp				; if it is zero (free) then
	jz	CMH_loopNext			;    no update needed.
	add	ax, dx				; else update this handle.
CMH_loopNext:					;
	stosw
	loop	CMH_handleUpdateLoop		; loop until done.

updateComplete:
	;
	; Change the free-list pointer and the amount of free space.
	; dx = amount change.
	;
	add	ds:LMBH_freeList, dx		; update free list ptr.
	sub	ds:LMBH_totalFree, dx		; update amount free.
	;
	; Change the size/flags words of the free block at the end of heap.
	;
	mov	si, ds:LMBH_freeList		;
	sub	ds:[si].LMC_size, dx		; update size word.
	;
	; Update the number of handles and return pointer to start of the
	; new ones (left in DI by the update loop).
	;
	add	ds:LMBH_nHandles, LMEM_HANDLE_INCR
	clc
done:					;
	.leave					;
	ret					;
CreateMoreHandles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
***		FindFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for space in the free list.

CALLED BY:	AllocAndAssociate, LMemReAlloc
PASS:		ds, es = segment address of the lmem heap block.
		cx = the amount of space to find.
		     This should include the size word.
		     This should be aligned.
RETURN:		ax = ptr to block to use. (if one was available).
DESTROYED:	carry - set if error (cannot allocate)

CHECKS:		Check that amount to find > LMEM_MIN_CHUNK_SIZE + 4.
		Heap is validated on entry.
		Cannot validate heap or chunk on exit because the block is
		marked as used, but no handle points to it.

NOTES:		This routine can cause the heap to be compacted. This means
		that all pointers directly into the heap (pointers to chunks)
		are not valid when this routine returns. It is important that
		you reset your pointers by dereferencing a handle. If you
		don't have a handle then you are screwed.

PSEUDO CODE/STRATEGY:
	Trivial rejection is done if the amount of space requested added to
	the size of the lmem-block is larger than 64K.

	The free list is searched for a block with enough space.

	If the size of the block is more than 6 bytes larger than the desired
	space then the block is split into two. The lower portion is changed
	to be a chunk of the desired size. The higher portion is changed to
	hold the leftovers.

	If the block was not split then it is removed from the free list.

	The total amount of free space is recalculated.

	A pointer to the allocated block is returned in ax.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindFreeSpace	proc	near
	uses	cx, dx, di, si			;
	.enter					;

	mov	ax, ds:LMBH_blockSize		; ax <- total used
	sub	ax, ds:LMBH_totalFree		;
	add	ax, cx				; ax <- new total
	jc	done
	cmp	ax, 0xfff0
	cmc
	jc	done
						;
	cmp	cx, ds:LMBH_totalFree		; if not enough space in the
	ja	noFit				;  block, enlarge it. No need
						;  to search a fragmented free
						;  list...
tryAgain:					;
	;
	; Search free list for a large enough block.
	;
	mov	si, LMBH_freeList		; ds:si == ptr to ptr to free.
scanLoop:	
	mov	di, si				; di = previous free chunk
	mov	si, ds:[si]			; move to next one.
	tst	si				; if at end of list
	jz	noFit				;    bummer, garbage collect.
	mov	ax, ds:[si].LMC_size		;
	AssertRounded	ax
	cmp	cx, ax				; if found one then
	ja	scanLoop			;    quit.

	;
	; Found a block that is big enough.
	; ds:si points to the block.

	; Free the block ourself

	sub	ds:LMBH_totalFree, ax
	mov	dx, ds:[si]
	mov	ds:[di], dx

	mov	dx, cx				; Preserve and pass to split
	call	LMemSplitBlock			; Split block into halves.
	mov	ax, si				; ax <- ptr to block.

	clc
done:
	.leave					;
	ret					;
noFit:						;
	test	ds:[LMBH_flags], mask LMF_NO_ENLARGE
	stc
	jnz	done
	;
	; No blocks fit. Need to call GetSpaceExact() to allocate something for
	; us, then we can loop around to get the space.
	;
	push	dx
	mov	dx, cx
	call	GetSpaceExact			; get exactly dx bytes of free.
	pop	dx
	jc	done
	jmp	tryAgain			; loop to find free space.

FindFreeSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSpaceExact
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an exact amount of free space at the end of the heap.

CALLED BY:	FindFreeSpace, CreateMoreHandles
PASS:		ds, es = segment address of an lmem heap
		dx     = the exact number of bytes to get at the heap end.
RETURN:		carry - set if error
		dx	= size of free space created
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/21/89		Initial version
	mg	3/27/00		Fixed handling of allocation failures

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSpaceExact	proc	far	uses	ax, bx, cx, si, di
	.enter					;

EC <	test	ds:[LMBH_flags], mask LMF_NO_ENLARGE			>
EC <	ERROR_NZ	CANNOT_GET_SPACE_EXACT_IF_NO_EXPAND		>

	mov	ax, ds:LMBH_blockSize
	sub	ax, ds:LMBH_totalFree
	add	ax, dx
	LONG jc	done

	; compute size for new block
	;	if (size < LMEM_MIN_ALLOCATION_PADDING)
	;		-> newSize = size + LMEM_MIN_ALLOCATION_PADDING
	;	else if (size > LMEM_ALLOC_INCR) ->
	;		-> newSize = size + LMEM_MAX_ALLOCATION_PADDING
	;	else newSize = size * 2

if	INI_SETTABLE_HEAP_THRESHOLDS
	push	ds, ax
	mov	ax, segment lmemMinAllocationPadding
	mov	ds, ax
	cmp	dx, ds:lmemMinAllocationPadding
	pop	ds, ax
else
	cmp	dx, LMEM_MIN_ALLOCATION_PADDING
endif
	jb	addMinIncrement
if	INI_SETTABLE_HEAP_THRESHOLDS
	push	ds, ax
	mov	ax, segment lmemMaxAllocationPadding
	mov	ds, ax
	cmp	dx, ds:lmemMaxAllocationPadding
	pop	ds, ax
else
	cmp	dx, LMEM_MAX_ALLOCATION_PADDING
endif
	ja	addMaxIncrement
	shl	dx, 1
	jmp	common

addMinIncrement:
if	INI_SETTABLE_HEAP_THRESHOLDS
	push	ds, ax
	mov	ax, segment lmemMinAllocationPadding
	mov	ds, ax
	add	dx, ds:lmemMinAllocationPadding
	pop	ds, ax
else
	add	dx, LMEM_MIN_ALLOCATION_PADDING	; dx <- size of free space.
endif

;	Carry will never be set here (as LMEM_MIN_ALLOCATION_PADDING*2 < 65535

	jmp	common
addMaxIncrement:
if	INI_SETTABLE_HEAP_THRESHOLDS
	push	ds, ax
	mov	ax, segment lmemMaxAllocationPadding
	mov	ds, ax
	add	dx, ds:lmemMaxAllocationPadding
	pop	ds, ax
else
	add	dx, LMEM_MAX_ALLOCATION_PADDING	; dx <- size of free space.
endif

;	If this wraps around, don't bother adding any padding...

	jnc	common
	sub	dx, LMEM_MAX_ALLOCATION_PADDING

common:

	mov	cx, LCT_ALWAYS_COMPACT
	call	LMemCompactHeap			; Push all non-free chunks
						;    toward the start.
	RoundUp	dx
						;
	; locate the final block on the free list. a heap with no handles
	; will not have been compacted by LMemCompactHeap, so we can no longer
	; rely on all free space being at the end here -- ardeb 10/13/92
	
	mov	ax, offset LMBH_freeList
findLastFree:
	mov	si, ax
	mov	ax, ds:[si]			; ax <- next block
	tst	ax				; last block?
	jnz	findLastFree

	dec	si				; back up to size word
	dec	si
	mov	di, ds:[si]
	cmp	si, offset LMBH_freeList-2
	je	useBlockSize

	; make sure the final free block is the final block in the heap.

	mov	ax, si
	add	ax, di				; ax <- start of next block
	cmp	ax, ds:[LMBH_blockSize]
	jae	haveLastFree

useBlockSize:
	clr	di
	mov	si, ds:[LMBH_blockSize]

haveLastFree:
	sub	di, ds:[LMBH_totalFree]		; di <- amount of free space
	neg	di				;  w/o final block

	; si is now the basis to which to add the amount of space needed.
	; it is either the start of the final block (as we want to use the
	; free space in the final block if there is any) or the size of the
	; block, if there is no free space.

	mov	ax, dx				; ax <- amount of space needed.
	add	ax, si				; ax <- new block size.
	jnc	noOverflow

	; overflow -- cannot allocate this large
	; dx <- dx - (ax - 0xfff0) = dx - ax + 0xfff0
	; ax <- 0xfff0

	sub	dx, ax
	mov	ax, 0xfff0			;overflow, use max block size
	add	dx, ax
noOverflow:

	mov	bx, ds:LMBH_handle		;
	mov	ch, HAF_STANDARD_NO_ERR		;can't handle errors here. ?
	test	ds:[LMBH_flags], mask LMF_RETURN_ERRORS
	jz	10$
	clr	ch
10$:

GSE_LMemBlockReAlloc label near			; needed for "showcalls -l"
	ForceRef	GSE_LMemBlockReAlloc

	push	ax	    			;remember the new size.
	call	MemReAlloc			;make block new size.
	pop	bx				
	jc	done

	mov	ds, ax				;and re-set to our segment
	mov	es, ax				;
	mov	ds:LMBH_blockSize, bx		;save the new size.

	;
	; ds = segment address of the block.
	; dx = amount of free space at end of block.
	; si = pointer to free block's size word.
	; di = free space in block without the final free block
	;
	add	di, dx
	mov	ds:LMBH_totalFree, di		; set total free space.

	inc	si
	inc	si				; si <- ptr into free space.

	;
	; Put the free block at the end onto the free list, coping with it
	; already being there and the free list being empty.
	; 
	mov	di, offset LMBH_freeList
addToFreeListLoop:
	mov	ax, ds:[di]			; ax <- next block
	cmp	ax, si				; found the insertion point
						;  (or the block itself)?
	jae	addFreeBlockHere		; yes -- stop looping
	tst	ax				; found the end of the list?
	jz	addFreeBlockHere		; yes -- stop looping

	mov_tr	di, ax				; di <- next block
	jmp	addToFreeListLoop

addFreeBlockHere:
	cmp	ax, si				; block already in the list?
	je	setBlockSize			; yes -- no need to add it,
						;  then
	mov	ds:[di], si			; store in pointer to next
	mov	ds:[si], ax			; store next

setBlockSize:
	mov	ds:[si].LMC_size, dx		; save size word.
EC <	call	ECInitFreeChunk			; make sure new memory is cc>
	clc
done:
	.leave					;
	ret					;
GetSpaceExact	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMemCompactHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compact an lmem heap, leaving all free space at the end.

CALLED BY:	CombineFreeChunks, FindFree
PASS:		cx	= threshhold for when to do compaction
			  (LMemCompactionThreshhold)
			  1 - comnpact if at least 50% free
			  2 - comnpact if at least 25% free
			  3 - comnpact if at least 12.5% free
			  4 - comnpact if at least 6.25% free
			  5 - always compact
		ds	= segment address of an lmem heap
RETURN:		carry - set if compaction aborted
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		count free chunks in the heap
		if sp - 4 * #free + STACK_RESERVED_FOR_INTERRUPTS < stackBot
			/* Not enough stack space to perform fast compact */
			OldLMemCompactHeap
		else
			foreach free chunk in the heap:
				shift following used chunks down over the
				    free chunk, saving the address of
				    both the free chunk and the first
				    following used chunk
			freeList = last free chunk
			having built a table of source addresses & distances
			    moved (on the stack), foreach handle:
				binary-search the table to find the block in
				    which the chunk was located. Adjust the
				    handle by the difference between the
				    source and the dest.
			release the stack space used by the table
		


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMemCompactHeap	proc	far
		.enter
EC <		tst	cx						>
EC <		ERROR_Z	LMEM_COMPACT_HEAP_BAD_THRESHHOLD		>
EC <		cmp	cx, LMemCompactionThreshhold			>
EC <		ERROR_AE LMEM_COMPACT_HEAP_BAD_THRESHHOLD		>

		InsertGenericProfileEntry PET_LMEM, 1, PMF_LMEM, ax

		test	ds:[LMBH_flags], mask LMF_NO_HANDLES
		jnz	quickLeave
		tst	ds:[LMBH_totalFree] 
		jnz	noTrivialReject
quickLeave:
		stc
		InsertGenericProfileEntry PET_LMEM, 0, PMF_LMEM, ax
		.leave			; XXX: but smaller than jz to end...
		ret

popStartCompact:
		pop	ax, cx
		jmp	startCompact

	; bail if less than 25% is free

noTrivialReject:
		cmp	cl, LCT_ALWAYS_COMPACT
		jae	startCompact
		push	ax, cx
		mov	ax, ds:[LMBH_totalFree]
shiftloop:
		shl	ax
		jc	popStartCompact
		loop	shiftloop
		cmp	ax, ds:[LMBH_blockSize]
		pop	ax, cx
		jb	quickLeave
startCompact:

		call	PushAll
		segmov	es, ds
again:
	;
	; Establish the boundary below which SP may not go when we're building
	; our table.
	;
		mov	bp, ss:[TPD_stackBot]
		add	bp, STACK_RESERVED_FOR_INTERRUPTS+4

	;
	; Record the end of the table we're going to build in BX, where
	; it'll be safe :).
	; 
		mov	bx, sp
		mov	di, ds:[LMBH_freeList]

compactLoop:
		mov	si, di		; si = next chunk
		mov	dx, ds:[di].LMC_size	; fetch size of free chunk
						;  for figure next chunk and
						;  for later coalescing
		add	si, dx

		push	dx		; Save amount moved
		push	si		; Save current source
	;
	; If si >= the block size, di must be the last chunk on the heap, so
	; we're done with the chunk movement phase of the exercise.
	; 
		mov	ax, ds:[LMBH_blockSize]	; (used two more times...)
		cmp	si, ax
		jae	adjustHandles

	;
	; Figure the length of the chunk to move. This is the distance from the
	; start of the used chunk to the start of the next free chunk, if it
	; exists. If there is no next free chunk, it is the distance from the
	; start of the used chunk to the end of the heap.
	; 
		mov	cx, ds:[di]	; cx <- base of next free chunk
		sub	cx, si
		ja	doMove		; => next free chunk exists
		;
		; No next free chunk, so use distance to the end of the block
		; 
		add	cx, ax		; (cx is already -si, since ds:[di]
					;  must have been zero)
		inc	cx		; account for size word in used chunk
		inc	cx		; (this is taken care of in the case
					; of an existing next free chunk by
					; including the size word of the next
					; free chunk in the calculations; no
					; such possibility exists here)

doMove:
		dec	di		; point to size word
		dec	di

		dec	si		; ditto
		dec	si
		
		shr	cx		; convert to words
		rep	movsw
		
	;
	; Now coalesce the newly-freed area with the following free chunk,
	; if it exists. In any case, we need to set up the size and next
	; pointers for the new free chunk.
	; 
		cmp	si, ax		; have we hit the end of the block?
		mov	ax, cx		; assume yes (no size to add in;
					;  cx is already 0 from the REP)
		jae	coalesce
		lodsw			; fetch size of next free
		xchg	ax, cx
		lodsw			; fetch next free chunk
		xchg	ax, cx		; ax = size, cx = offset
coalesce:
		add	ax, dx		; merge chunk sizes
		stosw			; store the size word and normalize
					;  the pointer
		mov	ds:[di], cx	; set pointer to next free chunk

		cmp	sp, bp		; have we used up our stack space?
		ja	compactLoop	; nope -- keep going.

adjustHandles:
	;
	; Make sure we actually moved something. If the current block is the
	; first block on the free list, we can't have moved anything, so there's
	; no point in looping through the handles...
	;
		mov	bp, di			; Figure end of the last free
		add	bp, ds:[di].LMC_size	;  chunk so we can tell if a
						;  used chunk was actually
						;  moved. Also need it in AX
						;  at adjustComplete to decide
						;  if we've compacted the whole
						;  block.
		dec	bp			; Handle case where block is
						;  64K long -- still need to
						;  avoid adjusting NOMEM
						;  chunk handles, and the
						;  comparison with one less
						;  than the next block is still
						;  valid, since chunks are
						;  rounded to a dword...

		cmp	di, ds:[LMBH_freeList]
		je	adjustComplete
		
	;
	; Now need to adjust all the handles for the block so they point to
	; their respective chunks.
	; 	di	= first (maybe only) free chunk
	; 	bp	= block following the first free chunk, if any.
	;
	; 	bx ->	saved registers
	;		first amount moved
	;		first source
	;		second amount moved
	;		second source
	;		...
	;		nth amount moved
	;	sp ->	nth source
	; 
EC <		; First, initialize the final free chunk to 0xcc if EC  >
EC <		mov	si, di						>
EC <		call	ECInitFreeChunk					>

   		mov	ds:[LMBH_freeList], di	; Save offset of last free
						; chunk as the entire list

   		mov	si, ds:[LMBH_offset]
		mov	di, si
		mov	cx, ds:[LMBH_nHandles]
adjustLoop:
		lodsw
	;
	; Perform a binary search of the table to find the range into which
	; the handle falls. The only trick here, from an algorithmic
	; standpoint, is the table is sorted in *descending* order, in
	; contrast to the normal way a table for binary search is sorted.
	;
	; (faster to use BX for addressing the table b/c ss:[bp] requires four
	; extra cycles to process the null byte-sized displacement, while
	; ss:[bx] requires only two to process the byte-sized segment override.
	; Also the ANDNF can be byte-sized.)
	; 
		cmp	ax, ss:[bx-4]	; if handle below first area moved
		jb	skipHandle	;  (or handle is free) then skip it.

		cmp	ax, bp		; if chunk begins after the end of the
		jae	skipHandle	;  first free chunk, it means we've not
					;  shifted it down at all, so skip it
					;  for now. Also catches handles with
					;  no memory, as 0xffff is ae the end
					;  of the first free block always.

		mov	dx, sp		; dx <- bottom
		push	bp		; save end of first free for next loop
		push	bx		; preserve the top
truncateHigh:
		lea	bp, [bx-4]	; point to last entry
searchLoop:
		mov	bx, bp		; bx <- midpoint between the two entries
		sub	bx, dx
		jb	found		; => pointers have crossed. dx points
					;  to the proper entry
		shr	bx
		andnf	bx, not 3	; round down to start of table entry
		add	bx, dx

		cmp	ax, ss:[bx]
		je	match
		ja	truncateHigh	; Handle points above the mid-point's
					;  address, so shift our focus
					;  downwards.
		;
		; Handle points below the mid-point's address, so shift our
		; focus upwards.
		; 
		lea	dx, [bx+4]
		jmp	searchLoop

skipHandle:
		mov	di, si		; adjust storage pointer
		jmp	endLoop		; finish (smaller than loop/jmp pair)

found:
		mov	bx, dx
match:
		sub	ax, ss:[bx+2]	; Adjust by amount moved

		stosw
		pop	bx
		pop	bp		; Recover end of first free chunk
endLoop:
		loop	adjustLoop
   		
adjustComplete:
		mov	sp, bx		; Biff the adjustment table

	;
	; See if we stopped compacting because we ran out of stack space
	; (the first free block on the list is not the last block on the heap).
	; If so, go back and compact some more. We'll continue doing this until
	; the heap is completely compacted.
	;
		cmp	bp, ds:[LMBH_blockSize]
		jae	done
		jmp	again
done:
		call	PopAll
		clc
		InsertGenericProfileEntry PET_LMEM, 0, PMF_LMEM, ax
		.leave
		ret
LMemCompactHeap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMemSplitBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Split a block into two pieces.

CALLED BY:	LMemReAlloc, QuickLMemReAlloc, FindFreeSpace
PASS:		ds:si = ptr to block to split.
		dx = size for first half.
		     This value should be aligned.
RETURN:		second block added to the free list.
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMemSplitBlock	proc	far
	push	bx			;
	mov	bx, ds:[si].LMC_size	; bx <- size of chunk in words.
	RoundUp	bx			;
	cmp	bx, dx			; if these are equal then
	je	LMSB_done		;    quit, we are done
	sub	bx, dx			; bx <- size of top half.
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
	push	si			; save ptr to low portion
	mov	ds:[si].LMC_size, dx	; save size for low chunk.
	add	si, dx			; set ptr to high block.
	mov	ds:[si].LMC_size, bx	; save size for high chunk.
	call	AddFreeBlock		; add to free list.
	pop	si			; restore ptr to low chunk.
LMSB_done:				;
	pop	bx			;
	ret				;
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
EC <	ERROR	LMEM_CHUNK_TOO_SMALL_TO_ADD_TO_FREE_LIST	>
LMemSplitBlock	endp

;--------------------------

EC <ChunkSizePtrError	proc	near					>
EC <	ERROR	CAN_NOT_USE_CHUNKSIZEPTR_MACRO_ON_EMPTY_CHUNKS		>
EC <ChunkSizePtrError	endp						>

ChunkSizeHandleES_BX_DX	proc	near
	xchg	bx, di
	xchg	ax, dx
	call	ChunkSizeHandleES_DI_AX
	xchg	ax, dx
	xchg	bx, di
	ret
ChunkSizeHandleES_BX_DX	endp

ChunkSizeHandleES_DI_AX	proc	near
	ChunkSizeHandle	es, di, ax
	ret
ChunkSizeHandleES_DI_AX	endp

ChunkSizeHandleDS_SI_CX	proc	near
	ChunkSizeHandle	ds, si, cx
	ret
ChunkSizeHandleDS_SI_CX	endp
