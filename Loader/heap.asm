COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Loader
FILE:		heap.asm

ROUTINES:
	Name			Description
	----			-----------
   	InitHeap		Initialize the heap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

DESCRIPTION:

	$Id: heap.asm,v 1.1 97/04/04 17:26:51 newdeal Exp $

------------------------------------------------------------------------------@

MAX_SIMPLE_ALLOC	=	10

simpleAllocSegment	sptr	0

SimpleAllocEntry	struct
    SAE_segment		sptr
    SAE_size		word
    SAE_handleOff	word
    SAE_flags		word
SimpleAllocEntry	ends

simpleAllocTable	SimpleAllocEntry	MAX_SIMPLE_ALLOC dup (<>)

simpleAllocPtr		word	(offset simpleAllocTable)


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderSimpleAlloc

DESCRIPTION:	Allocate a block before the heap has been initialized using
		the simple stack oriented approach.

CALLED BY:	OpenIniFiles

PASS:
	ax - # of bytes
	cx - flags for block
	bx - offset (in loader) to store real handle after heap is init'ed

RETURN:
	ax - segment

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

LoaderSimpleAlloc	proc	near	uses si, ds
	.enter

	segmov	ds, cs

	mov	si, ds:[simpleAllocPtr]

EC <	cmp	si, (offset simpleAllocTable) + (size simpleAllocTable)	>
EC <	ERROR_Z	TOO_MANY_SIMPLE_ALLOCS					>

	mov	ds:[si].SAE_flags, cx
	mov	ds:[si].SAE_handleOff, bx
	mov	ds:[si].SAE_size, ax

	; convert ax to paragraphs

	add	ax, 15
	shr	ax
	shr	ax
	shr	ax
	shr	ax

	sub	ds:[simpleAllocSegment], ax
	mov	ax, ds:[simpleAllocSegment]

	mov	ds:[si].SAE_segment, ax
	mov	ds:[bx], ax

	add	ds:[simpleAllocPtr], size SimpleAllocEntry

	.leave
	ret

LoaderSimpleAlloc	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	InitHeap

DESCRIPTION:	Initialize the heap

CALLED BY:	LoadKernel

PASS:
	ds, es - loader segment
	KLV_handleTableStart - set
 	KLV_lastHandle - set
	KLV_handleFreeCount - set
	KLV_heapStart - set
	KLV_heapEnd - set

RETURN:
	KLV_origHeapEnd - set
	KLV_heapDesiredSize - set
	KLV_handleBottomBlock - set
	KLV_kernelHandle - set
	KLV_heapFreeSize - set
	KLV_handleFreePtr - set

	KLV_lastHandle - set
	KLV_handleTableStart - set

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
Create the heap's initial state:

	+---------------------------------------+
	|	Fixed block for kdata		|	first handle
	+---------------------------------------+
	|					|
	|	FREE BLOCK			|	third handle
	|					|
	+---------------------------------------+
	|	Movable locked block for loader	|	second handle
	+---------------------------------------+

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

InitHeap	proc	near	uses	es
	.enter

PC <	call	InitHeapWithCC						>
PC <	mov	ds:[loaderVars].KLV_kernelHandle, LOADER_ID		>

	; Figure destination size for scrub thread, based on overall heap size.
	; make sure it doesn't go below a useful minimum....

	mov	ax, ds:[loaderVars].KLV_heapEnd
	mov	ds:[loaderVars].KLV_origHeapEnd, ax
	sub	ax, ds:[loaderVars].KLV_heapStart	;ax = heap size
	clr	dx
	mov	cx, SCRUB_DESIRED_PERCENTAGE
	div	cx
	cmp	ax, SCRUB_MIN_DESIRED_SIZE shr 4
	jae	storeDesired
	mov	ax, SCRUB_MIN_DESIRED_SIZE shr 4
storeDesired:
	mov	ds:[loaderVars].KLV_heapDesiredSize, ax

ifidn	HARDWARE_TYPE, <PC>

	; initialize the handle table

	call	InitHandleTable

	; load handles of first blocks

	mov	si, ds:[loaderVars].KLV_handleTableStart  ;si = handle of kdata
	lea	bx, ds:[si+size HandleMem]	;bx = handle of loader
	lea	di, ds:[bx+size HandleMem]	;di = handle of free block

	; initialize kdata handle

	mov	ds:[loaderVars].KLV_handleBottomBlock, si
	mov	es:[si].HM_addr, es
	mov	ax, ds:[loaderVars].KLV_lastHandle
	mov	cl, 4
	shr	ax, cl
	mov	es:[si].HM_size, ax
	mov	es:[si].HM_prev, bx
	mov	es:[si].HM_next, di
	mov	es:[si].HM_owner, LOADER_ID
	mov	es:[si].HM_flags, mask HF_FIXED

	; initialize loader handle

	mov	es:[bx].HM_addr, cs
	mov	ax, ds:[loaderVars].KLV_heapEnd
	mov	dx, cs
	sub	ax, dx
	mov	es:[bx].HM_size, ax
	mov	es:[bx].HM_prev, di
	mov	es:[bx].HM_next, si
	mov	es:[bx].HM_owner, LOADER_ID
	mov	es:[bx].HM_flags, mask HF_DISCARDABLE
	mov	es:[bx].HM_lockCount, 1

	;initialize free block handle

	mov	ax, ds:[loaderVars].KLV_heapStart
	add	ax, es:[si].HM_size
	mov	es:[di].HM_addr, ax
	sub	dx, ax
	mov	es:[di].HM_size, dx
	mov	ds:[loaderVars].KLV_heapFreeSize, dx
	mov	es:[di].HM_prev, si
	mov	es:[di].HM_next, bx

	; zero out udata (except handle table)

	mov	cx, ds:[loaderVars].KLV_handleTableStart
	mov	di, ds:[kdataSize]
	sub	cx, di
	clr	al
	rep	stosb

	; now we can set kdataSize to encompass the handle table
	mov	ax, ds:[loaderVars].KLV_lastHandle
	mov	ds:[kdataSize], ax

elseifdif	HARDWARE_TYPE, <PC>		; BULLET and ZOOMER

	; calculate free space in the heap (first used block - start of heap)

	push	ds
	mov	ax, es:[loaderVars].KLV_dgroupSegment
	mov	ds, ax
	mov	bp, es:[loaderVars].KLV_handleBottomBlock
	mov	ax, ds:[bp].HM_addr
	mov	dx, cs				; heap start => DX
	sub	ax, dx				; free size => AX
	mov	es:[loaderVars].KLV_heapFreeSize, ax

	; allocate the single free block on the heap

	call	AllocateHandle			; handle => BX
	mov	es:[loaderVars].KLV_handleBottomBlock, bx

	mov	di, ds:[bp].HM_prev		; previous handle => DI
	mov	ds:[bp].HM_prev, bx		; fixup next handle

	mov	ds:[bx].HM_next, bp		; fixup new handle
	mov	ds:[bx].HM_prev, di
	mov	ds:[bx].HM_size, ax
	mov	ds:[bx].HM_addr, dx
	clr	ds:[bx].HM_owner		; this is free memory

	mov	ds:[di].HM_next, bx		; fixup prev handle
	pop	ds

endif
	; turn all of the simple allocations into real handles

	call	MakeHandlesForSimpleAllocs

	.leave
	ret
InitHeap	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitHeapWithCC

DESCRIPTION:	Initialize the handle table to all free handles

CALLED BY:	INTERNAL
		InitHeap

PASS:
	ds, es - loader segment

RETURN:
	es - handle table

DESTROYED:
	ax, bx, cx, di

REGISTER/STACK USAGE:
	bx - current handle

PSEUDO CODE/STRATEGY:
	handleFreePtr = first handle allocated
	while (not at end of block)
		init a new handle and link it to the next one

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/93		Broke out into separate routine

-------------------------------------------------------------------------------@

ifidn	HARDWARE_TYPE, <PC>

InitHeapWithCC	proc	near
if	ERROR_CHECK
	uses	ax, cx, dx, di, es
	.enter

	; Fill the entire heap with breakpoints, except for our own stuff.
	; 
	mov	dx, cs:[simpleAllocSegment]	;dx = last segment to fill + 1
	mov	es, ds:[loaderVars].KLV_heapStart;es = first segment to fill
	mov	ax,0cccch		;INT 3 opcode (2 of them)
fillLoop:
	clr	di
	mov	cx,8			;16/2
	rep stosw
	mov	bx,es
	inc	bx
	mov	es,bx
	cmp	bx,dx
	jnz	fillLoop

	.leave
endif
	ret
InitHeapWithCC	endp

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitHandleTable

DESCRIPTION:	Initialize the handle table to all free handles

CALLED BY:	INTERNAL
		InitHeap

PASS:
	ds, es - loader segment

RETURN:
	es - handle table

DESTROYED:
	ax, bx, cx, di

REGISTER/STACK USAGE:
	bx - current handle

PSEUDO CODE/STRATEGY:
	handleFreePtr = first handle allocated
	while (not at end of block)
		init a new handle and link it to the next one

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version written and tested
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
InitHandleTable	proc	near

	; compensate for two handles we use

	sub	ds:[loaderVars].KLV_handleFreeCount, 3

	; Zero out the entire handle table in one fell swoop.

	mov	cx, ds:[loaderVars].KLV_lastHandle
	shr	cx
	mov	es, ds:[loaderVars].KLV_heapStart
	clr	di
	clr	ax
	rep	stosw

	mov	bx, ds:[loaderVars].KLV_handleTableStart
	add	bx, (size HandleMem)*3
	mov	ds:[loaderVars].KLV_handleFreePtr, bx
	mov	ax, bx
linkLoop:
	add	ax, size HandleMem		;address of next free handle
	mov	es:[bx].HM_next, ax
	mov	es:[bx].HG_type,SIG_FREE
	mov	bx, ax
	cmp	ax, ds:[loaderVars].KLV_lastHandle	;test for done
	jnz	linkLoop				;loop until then...
	mov	es:[bx][-size HandleMem].HM_next,0	;Init last handle.
	mov	es:[bx][-size HandleMem].HG_type, SIG_FREE
	ret

InitHandleTable	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	MakeHandlesForSimpleAllocs

DESCRIPTION:	Allocate handles for blocks allocated with LoaderSimpleAlloc

CALLED BY:	InitHeap

PASS:
	ds, es - loader segment

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

MakeHandlesForSimpleAllocs	proc	near	uses ds
	.enter

	mov	si, offset simpleAllocTable

allocHandleLoop:
	cmp	si, cs:[simpleAllocPtr]
	jz	done

	mov	ax, cs:[si].SAE_size
	mov	cx, cs:[si].SAE_flags
	call	LoaderMemAlloc
EC <	cmp	ax, cs:[si].SAE_segment					>
EC <	ERROR_NZ	ERROR_IN_SIMPLE_ALLOC				>
	mov_trash	ax, bx
	mov	bx, cs:[si].SAE_handleOff
	mov	cs:[bx], ax

	add	si, size SimpleAllocEntry
	jmp	allocHandleLoop

done:
	.leave
	ret

MakeHandlesForSimpleAllocs	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MakeKernelOwnBlocks

DESCRIPTION:	Make the kernel own all allocated blocks

CALLED BY:	LoadGeos

PASS:
	ds, es - loader

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
MakeKernelOwnBlocks	proc	near	uses ds
	.enter

	mov	bx, ds:[loaderVars].KLV_handleTableStart
	mov	cx, ds:[loaderVars].KLV_lastHandle
	mov	ax, ds:[kernelCoreBlock].GH_geodeHandle
	mov	ds:[loaderVars].KLV_kernelHandle, ax
	mov	ds, ds:[loaderVars].KLV_heapStart
ownerLoop:
	cmp	ds:[bx].HM_owner, LOADER_ID
	jnz	next
	mov	ds:[bx].HM_owner, ax
next:
	add	bx, size HandleMem
	cmp	bx, cx
	jnz	ownerLoop

	.leave
	ret

MakeKernelOwnBlocks	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BytesToParas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a number of bytes to the number of paragraphs
		required to hold those bytes.

CALLED BY:	LoaderMemAlloc, AllocateResource
PASS:		ax	= # bytes
RETURN:		ax	= # paras
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BytesToParas	proc	near
		.enter
	push	cx						; 1 / 15
	add	ax, 15		;convert bytes to paragraphs	; 3 / 4
	mov	cl, 4		;allocate extra if needed	; 3 / 4
	shr	ax, cl						; 2 / 24
	pop	cx						; 1 / 8
		.leave
		ret
BytesToParas	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoaderMemAlloc

DESCRIPTION:
	Allocate the given number of bytes on the heap.  This block can be:
		Discardable or non-discardable
		Swapable or non-swapable
		Allocated fixed or movable blocks
		Initialized to zero or not

CALLED BY:	UTILITY

PASS:
	ax - size (in bytes) to allocate
	cl - flags for block type: HeapFlags record
	ch - flags for allocation method: HeapAllocFlags record

RETURN:
	bx - handle to block allocated
	ax - address of block allocated

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

LoaderMemAlloc	proc	near	uses	cx, dx, si, di, ds, es
	.enter

	mov	ds, cs:[loaderVars].KLV_dgroupSegment	;ds = kdata
	segmov	es, cs					;es = loader

	push	cx
	call	BytesToParas

	call	SearchHeap		;allocate some memory
	sub	es:[loaderVars].KLV_heapFreeSize, ax	;you are mine
	call	SplitBlockWithAddr	;split free block into two pieces
	pop	cx

	; zero init if needed

	test	ch, mask HAF_ZERO_INIT
	jz	noZeroInit
	call	DoZeroInit
noZeroInit:

	; bx = handle, make it ours

	mov	ds:[bx].HM_flags, cl	;save flags
	mov	ds:[bx].HM_lockCount, 0	;save lock count
	mov	ds:[bx].HM_otherInfo, 1
	mov	ds:[bx].HM_usageValue, 0
PC <	mov	ds:[bx].HM_owner, LOADER_ID				>
XIP <	mov	ax, cs:[loaderVars].KLV_kernelHandle			>
XIP <	mov	ds:[bx].HM_owner, ax					>
	mov	ax, ds:[bx].HM_addr

	.leave
	ret

LoaderMemAlloc	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoZeroInit

DESCRIPTION:	initialize a memory block to 0's

CALLED BY:	LoaderMemAlloc

PASS:
	bx - handle of block to initialize
	ds - kdata

RETURN:
	bx, ds - same

DESTROYED:
	ax, di

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

DoZeroInit	proc	near	uses es, cx
	.enter

	mov	es, ds:[bx].HM_addr	;get segment address in es
	mov	cx, ds:[bx].HM_size
	shl	cx, 1
	shl	cx, 1
	shl	cx, 1			;cx = # words
	clr	ax, di			;store zeros
	rep stosw

	.leave
	ret

DoZeroInit	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	AllocateHandle

DESCRIPTION:	Allocate a handle from the handle table

CALLED BY:	AllocateMemHandle

PASS:
	ds - kdata
	es - loader vars

RETURN:
	bx - handle (all fields but HG_owner initialized to zero)

DESTROYED:
	none (not even flags)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	temp = handleFreePtr
	handleFreePtr = handleFreePtr->nextFreeHandle
	return(temp)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

AllocateHandle	proc	near
	pushf
	push	ax

	mov	bx, es:[loaderVars].KLV_handleFreePtr
	mov	ax, ds:[bx].HM_next
	mov	es:[loaderVars].KLV_handleFreePtr, ax
	dec	es:[loaderVars].KLV_handleFreeCount

	; clear out the handle.
	clr	ax				

	mov	{word}ds:[bx].HG_data1, ax	; 2	(9)
	mov	ds:[bx].HG_data2[0], ax		; 3	(19)
	mov	ds:[bx].HG_data2[2], ax		; 3	(19)
	mov	ds:[bx].HG_data2[4], ax		; 3	(19)
	mov	ds:[bx].HG_data2[6], ax		; 3	(19)
	mov	ds:[bx].HG_data2[8], ax		; 3	(19)
	mov	ds:[bx].HG_data2[10], ax	; 3	(19)
						; 20	(123)

	mov	ds:[bx][HM_owner], LOADER_ID	;set owner

	pop	ax
	popf
	ret

AllocateHandle	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FreeHandle

DESCRIPTION:	Deallocate a handle from the handle table

CALLED BY:	-

PASS:
	bx - handle to free
	ds - kdata
	es - loader vars

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Put passed handle at the front of the LRU list.

	handle->HM_addr = 0
	handle->nextFreeHandle = handleFreePtr
	handleFreePtr = handle

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@
if 0
FreeHandle	proc	near
	pushf					;Save interrupt state

	push	ax
	clr	ax
	mov	ds:[bx].HM_addr, ax		;mark handle as unused
	mov	ds:[bx].HM_owner, ax		;mark handle as unused
	mov	ds:[bx].HG_type, SIG_FREE	;mark handle as free (now done
	mov	ax, es:[loaderVars].KLV_handleFreePtr	;use a temp
	mov	ds:[bx].HM_next,ax		;was HM_nextFree
	mov	es:[loaderVars].KLV_handleFreePtr, bx
	inc	es:[loaderVars].KLV_handleFreeCount
	pop	ax
	popf
	ret
FreeHandle	endp
endif

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DupHandle

DESCRIPTION:	Allocate a new handle and make it a duplicate of the handle
		passed.

CALLED BY:	SplitBlock

PASS:
	bx - handle to duplicate
	ds - kdata
	es - loader

RETURN:
	bx - new handle
	si - handle passed
	ds - unchanged

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

DupHandle	proc	near	uses cx, di, es
	.enter

	mov	si, bx
				;don't care what owner is set to
	call	AllocateHandle	;allocate a new handle for second block

	; copy data from old to new, si = old, bx = new

	push	si

	segmov 	es, ds		;es = dest
	mov	di, bx

	mov	cx, size HandleMem / 2	;copy entire handle
	rep movsw

	pop	si

	.leave
	ret

DupHandle	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SearchHeap

DESCRIPTION:	Search the heap for a free block of the given size, or search
		for the largest free block.

CALLED BY:	LoaderMemAlloc

PASS:
	ax - size (in paragraphs) requested
	cl - HeapFlags for block being allocated
		HF_FIXED => search from bottom of memory (fixed heap)
		0 	=> search from top of memory w/o restrictions
	ds - kdata
	es - loader

RETURN:
	bx - handle of block found

DESTROYED:
	none

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

SearchHeap	proc	near	uses cx, si, di
	.enter
	;
	; Figure starting conditions: initial block (bx) and which pointer in
	; the handle should be used to get to the next one (si)
	; 
	mov	dx, es:[loaderVars].KLV_heapEnd

	mov	si, HM_next		;assume from bottom
	mov	bx, es:[loaderVars].KLV_handleBottomBlock
PC <	test	cl, mask HF_FIXED					>
PC <	jnz	bottom							>
PC <	mov	si, HM_prev		;from top -- go backwards	>
PC <	mov	bx, ds:[bx][si]		;and start at top		>
PC <bottom:								>
	mov	di, bx			;save block at which to stop

	; the loop starts here -- loop until block found or done

blockLoop:
	cmp	ds:[bx].HM_owner,0	;test for block free (owner = 0)
	jnz	notFree

	cmp	ax, ds:[bx].HM_size	;block big enough?
	ja	tryNext

	; found

	.leave
	ret

notFree:
	mov	ch, cl
	xor	ch, ds:[bx].HM_flags	;check for types different
			CheckHack <mask HF_FIXED eq 0x80>
	js	notFound		;differ => crossed into other heap so
					; there's nothing big enough in the
					; heap we want.

tryNext:

	; move to next block on list

	mov	bx, ds:[bx][si]		;follow pointer
	cmp	bx, di
	jnz	blockLoop		;if looped around then done

notFound:
	ERROR	LS_NOT_ENOUGH_MEMORY

SearchHeap	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SplitBlockWithAddr

DESCRIPTION:	Split a block that still has its address in HM_addr

CALLED BY:	LoaderMemAlloc

PASS:
	ax - size of block to allocate (paragraphs)
	bx - block to split
	cl - mask HF_FIXED to leave bottom allocated,
	 	  0 to leave top allocated
	ds - kdata
	es - loader vars

RETURN:
	bx - block that was split (ax paragraphs)
	si - handle to free memory, if any
	dx - segment address of used block

DESTROYED:
n	ax

REGISTER/STACK USAGE:

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
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

SplitBlockWithAddr proc	near
	;
	; Figure new free-block's size
	;
	clr	si
	cmp	ax, ds:[bx].HM_size
	je	finish
	;
	; Duplicate the handle and divide the block into its two areas
	;
	call	DupHandle

	mov	ds:[si].HM_size, ax	;store used size in original handle

	sub	ds:[bx].HM_size, ax	;figure free size in new handle
	mov	ds:[bx].HM_owner, 0		;mark new as free
	mov	{word}ds:[bx].HM_flags, 0  	;not discardable or swappable or
					      	; locked

	push	bx, si
	mov	dx, ds:[bx].HM_addr
	add	dx, ds:[bx].HM_size	; Compute new address for used block
					;  after the free block

	test	cl,mask HF_FIXED
	jz	fixlinks		;if allocating at top, branch -- free
					; addr and registers already set

	mov	dx, ds:[bx].HM_addr	; fetch original address
	add	dx, ax			; add to used size
	xchg	bx, si			; swap handles to allocate at bottom

fixlinks:
	mov	ds:[si].HM_addr, dx

	; fix up links.
	;
	; bx = handle of block lower in memory
	; si = handle of block higher in memory

	mov	ds:[si].HM_prev, bx	;point high block at low block
	mov	ds:[bx].HM_next, si	;point low block at high block

	call	FixLinks		;update surrounding blocks

	pop	si, bx			; si <- free, bx <- split
finish:
	ret
SplitBlockWithAddr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FixLinks, FixLinks2

DESCRIPTION:	FixLinks - Fix the links to both bx and si
		FixLinks2 - Fix the links to the block bx

CALLED BY:	FixLinks - SplitBlock
		FixLinks2 - FixLinks

PASS:
	exclusive access to heap variables
	bx, si - blocks to fix
	ds - kdata
	es - loader vars

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
	call	FixLinks2	; Now fix BX
	ret
FixLinks	endp


FixLinks2	proc	near
	cmp	ds:[bx][HM_addr], 0	;check for no memory associated
	jz	20$

	push	si

	mov	si, es:[loaderVars].KLV_heapStart
	cmp	si, ds:[bx].HM_addr
	jnz	10$
	mov	es:[loaderVars].KLV_handleBottomBlock, bx
10$:

	mov	si, ds:[bx].HM_prev	;fix link from prev block
	mov	ds:[si].HM_next, bx

	mov	si, ds:[bx].HM_next	;fix link from next block
	mov	ds:[si].HM_prev, bx

	pop	si
20$:
	ret

FixLinks2	endp
