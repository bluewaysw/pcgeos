COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Kernel Library
FILE:		geodesPriv.asm

AUTHOR:		Andrew Wilson, Sep 13, 1991

ROUTINES:
	Name			Description
	----			-----------
	GeodePrivAlloc		Allocates a group of contiguous words in the
				geode's private instance data
	GeodePrivFree		Frees a group of contiguous words.
	GeodePrivRead		Reads in a group of contiguous words from the
				private data for the current process' geode.
	GeodePrivWrite		Writes a group of contiguous words from the 
				private data for the current process' geode.
	GeodePrivExit		When a geode exits, this is called to clear
				any blocks owned by the geode.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/13/91		Initial revision

DESCRIPTION:
	This file contains routines to implement the GeodePrivXXXX routines,
	which allow libraries to allocate Geode-specific information.

	$Id: geodesPriv.asm,v 1.1 97/04/05 01:12:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePrivRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads data from the private data area of the passed geode.

CALLED BY:	GLOBAL
PASS:		bx - geode handle (or 0 to use handle of current process)
		di - offset returned by GeodePrivAlloc
		cx - # words to read
		ds:si - pointer to save words read in
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If no data has been written to the passed offset, this routine will
	store zeroes out.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePrivRead	proc	far	
	destSeg	local	sptr	push ds
	len	local	word	push cx		;# words to return
	.enter
	call	PushAll
	sub	di, FIRST_GEODE_PRIV_OFFSET
EC <	call	CheckGeodePrivOffset					>
	xchg	si, di				;DI <- ptr to dest for words
						;SI <- source offset
	LoadVarSeg	ds
	tst	bx
	jnz	10$
	call	GeodeGetProcessHandle		;BX <- handle of current proc
10$:
	cmp	bx, handle 0			;If kernel, just store zeroes
	jz	storeZeroes			; out.
	call	MemLock				;Lock the geode header
	mov	es, ax
	mov	ax, es:[GH_privData]		;Get private data block handle
	call	MemUnlock
EC <	call	NullES							>
	tst	ax				;If no privData block handle,
	jz	storeZeroes			; return zeroes.
	mov	bx, ax
	call	GetByteSize			;AX <- offset to end of block
	cmp	si, ax 				;if start past end of block,
	ja	storeZeroes			;	store zeroes
	push	ax
	call	MemPLock			;lock private data block
	mov	ds, ax				;DS:SI <- src
	pop	ax				;AX = offset to end of block
	mov	es, destSeg
	mov	cx, len				;CX = # of words of data to get
	rep	movsw				;copy out data
	sub	si, ax				;flags same as "cmp  si,ax"
	jbe	storeDone			;if end still in block, done
	mov	cx, si				;CX = # of bytes past end
	sub	di, cx				;backup pointer
	clr	al				;& fill over w/zeroes
	rep	stosb
storeDone:
	call	MemUnlockV
exit:
	call	PopAll
	.leave
	ret

;	OFFSET WAS NEVER WRITTEN TO IN BLOCK, SO RETURN ZEROES

storeZeroes:					;Store zeroes out there
	mov	es, destSeg
	clr	ax
	mov	cx, len				;CX = # of words of data to get
	rep	stosw
	jmp	exit
GeodePrivRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePrivExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release any Geode-Private space owned by an exiting geode

CALLED BY:	GLOBAL
PASS:		ax - handle of core block of exiting geode
		ds - kdata
RETURN:		nada
DESTROYED:	ax, bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePrivExit	proc	near	uses	es, di, cx, bp
	.enter
EC <	call	AssertDSKdata						>
EC <	push	bx							>
EC <	mov	bx, ax							>
EC <	call	ECCheckGeodeHandle					>
EC <	pop	bx							>

	mov_tr	bp, ax		;Save handle of owning geode.
	call	GeodePrivLockMap
	jc	unlockDone		; => no map block, so just
					;  unlock the kernel's core block
					;  and release privSem
	clr	di
	call	GetByteSize		;CX <- # bytes in map block
	mov_tr	ax, bp			;AX <- geode for which to look
	shr	cx, 1			;convert to words
scanLoop:
	repne	scasw			; Search for matching slot
	jne	unlockDone		; None -- all done
	mov	{word}es:[di-2], 0 	; Free that slot
	jcxz	unlockDone		; Avoid infinite loop, since
					;  mov won't alter ZF and REPNE will
					;  abort right off if CX is 0 on entry.
	jmp	scanLoop
unlockDone:
	call	GeodePrivUnlockMap	;Unlock map block
	.leave
	ret
GeodePrivExit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePrivLockMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the map block for geode-private data.

CALLED BY:	INTERNAL
PASS:		nada
RETURN:		carry set if map block not allocated:
			privSem grabbed
			es	= segment of kernel's core block
			bx	= handle of same
		carry clear if it is:
			bx	= handle of map block
			es	= segment of same
			privSem grabbed
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePrivLockMap proc	far
AXIP <	uses	si, ds							>
	.enter
	;
	; Grab the privSem first, in case the block's not been allocated yet.
	; 
	call	PGeodePrivSem

	;
	; Lock down the kernel's core block so we can examine its GH_privData
	; field. The kernel has no need of geode-private data (it uses no
	; libraries), so we use its geode-private data block as the map block
	; for the system, much as the scheduler thread's TPD_heap is the map
	; area for thread-private data in the system.
	; 
	mov	bx, handle 0
	call	MemLock			;Lock the geode handle
	mov	es, ax
NOAXIP <mov	ax, es:[GH_privData]	;Get the private data		>
NOAXIP <tst	ax			;Any allocated?			>
AXIP <	LoadVarSeg ds, si						>
AXIP <	mov	si, es:[GH_privData]	;Get the private data		>
KXIP <	cmp	ds:[si].HG_type, SIG_FREE				>
FXIP <	test	ds:[si].HM_flags, mask HF_DISCARDED			>
	stc
NOFXIP <jz	done			;Not allocated, so we're done	>
FXIP   <jnz	done							>

	;
	; Release the core block and lock down the map block itself.
	; 
	call	MemUnlock
EC <	call	NullES							>
NOAXIP <mov_tr	bx, ax			;^hBX <- map block		>
AXIP <	mov	bx, si			;^hBX <- map block		>
	call	MemLock
	mov	es, ax			;ES <- map block
	clc
done:
	.leave
	ret
GeodePrivLockMap endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePrivUnlockMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive access to the map block.

CALLED BY:	INTERNAL
PASS:		bx	= block to unlock (usually the map block, but doesn't
			  have to be)
		privSem grabbed
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePrivUnlockMap proc	far
	.enter
	call	MemUnlock
	call	VGeodePrivSem
	.leave
	ret
GeodePrivUnlockMap endp

;---

PGeodePrivSem	proc	near
	push	bx
	mov	bx, offset privSem
	jmp	SysPSemCommon
PGeodePrivSem	endp

VGeodePrivSem	proc	near
	push	bx
	mov	bx, offset privSem
	jmp	SysVSemCommon
VGeodePrivSem	endp

FarPGeodePrivSem	proc	far
	call	PGeodePrivSem
	ret
FarPGeodePrivSem	endp

FarVGeodePrivSem	proc	far
	call	VGeodePrivSem
	ret
FarVGeodePrivSem	endp
if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckGeodePrivOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the passed offset for validity.

CALLED BY:	GLOBAL
PASS:		di - offset passed to GeodePrivFree/Read/Write
		cx - # words passed to GeodePrivFree/Read/Write
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckGeodePrivOffset	proc	far	uses es, ax, bx
	.enter
	tst	cx							
	ERROR_Z	GEODE_PRIV_PASSED_SIZE_OF_ZERO				

	;
	; Lock down the system's geode-private map block. Grabs appropriate
	; synchronization points...
	; 
	call	GeodePrivLockMap	; es, ^hbx <- map block
	ERROR_C	GEODE_PRIV_ALLOC_NEVER_CALLED

	;
	; See if the offset points beyond the end of the map block. If so,
	; it's invalid.
	; 
	push	cx,ds							
	LoadVarSeg	ds
	call	GetByteSize						
	cmp	di, cx							
	ERROR_AE GEODE_PRIV_PASSED_OFFSET_THAT_IS_TOO_LARGE		
	pop	cx,ds							

	push	cx,di							
	mov	ax, es:[di]						
	tst	ax
	ERROR_Z	GEODE_PRIV_PASSED_RANGE_CONTAINING_FREE_WORD
	repe	scasw
	ERROR_NZ GEODE_PRIV_PASSED_RANGE_NOT_OWNED_BY_SAME_GEODE
	pop	cx,di							

	call	GeodePrivUnlockMap	;Unlock map block
	.leave
	ret
CheckGeodePrivOffset	endp
endif

;---

GLoad segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindContiguousWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds contiguous 0 words in the passed block, and sets them
		to the passed owner handle.

CALLED BY:	(EXTERNAL) AllocGeodePrivWords, ThreadPrivAlloc
PASS:		cx - word size of block
		bp - owner handle
		dx - # contiguous words to find
		es:di - ptr to block
RETURN:		carry set if couldn't find contiguous words (bx unchanged)
		 - else -
		bp - offset to contiguous stretch of words
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/13/91		Initial version (stolen from ThreadPrivAlloc)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindContiguousWords	proc	near	uses	cx, si
	.enter
	clr	ax
	mov	si, ax				;SI <- size of free run
top:
	scasw		; See if slot is free
	jz	free
	mov	si, ax	; terminate any free run in progress
	loop	top	; Advance to next
	;
	; If reached the end of the heap without returning, it means
	; we couldn't find an area large enough. Set the carry and
	; return.
	;
noroom:
	stc
done:
	.leave
	ret
free:
	;
	; Another slot free -- see if we've got enough to satisfy the
	; request.
	;
	inc	si	;
	cmp	dx, si	;
	loopne	top	;
	jne	noroom	; Hit end of heap and still not enough: error
	;
	; Have enough room for this request. Store the owner handle in
	; all the allocated words. NOTE: None of these
	; instructions should alter the carry unless a CLC is issued
	; before the jump to done.
	;
	;
	dec	di	; Adjust di to be the last word we're
	dec	di	; allocating to the caller.
	mov	ax, bp	; Transfer handle to AX for storing
	mov	cx, dx	; CX <- # words allocated
	std		; Need to work backward
	rep	stosw	; Fill area
	cld		; Restore DF to normal state
	;
	; DI is two too few, so use lea to adjust it while we store
	; the offset in BP for our return.
	;
	lea	bp, [di+2]
	jmp	done	; Carry cleared by equality in compare. All
			;  instructions above leave CF alone.
FindContiguousWords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocGeodePrivWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds contiguous 0 words in the passed block, and sets them
		to the passed owner handle.

CALLED BY:	(INTERNAL) GeodePrivAlloc
PASS:		cx - byte size of block
		bx - handle of block
		bp - owner handle
		dx - # contiguous words to find
RETURN:		carry set if couldn't find contiguous words (bx unchanged)
		 - else -
		bx - offset to contiguous stretch of words
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocGeodePrivWords	proc	near	uses	bp, cx
	.enter
	shr	cx, 1			;CX <- word size of block
	call	MemLock			;
	mov	es, ax			;ES:DI <- pointer to block
	clr	di			;
	call	FindContiguousWords	;bp <- start of allocated range
	call	MemUnlock
	jc	exit
	mov	bx, bp
	add	bx, FIRST_GEODE_PRIV_OFFSET	;Make sure offset is non-zero
						;Carry is cleared by this.
exit:
	.leave
	ret
AllocGeodePrivWords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePrivAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a string of contiguous words in the GeodePrivateData.

CALLED BY:	GLOBAL
PASS:		bx - Geode that will "own" the space
		cx - # contiguous words to allocate
RETURN:		bx - offset to start of range, or 0 if couldn't allocate

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePrivAlloc	proc	far	uses	ds, es, ax, cx, dx, bp, di
	.enter
EC <	tst	cx							>
EC <	ERROR_Z GEODE_PRIV_PASSED_SIZE_OF_ZERO				>
EC <	cmp	cx, 100							>
EC <	ERROR_A	GEODE_PRIV_ALLOC_PASSED_RATHER_LARGE_SIZE		>
EC <	call	ECCheckGeodeHandle					>

	mov	bp, bx			;BP <- owning geode
	mov	dx, cx			;DX <- # contiguous words
	
	LoadVarSeg	ds		;Needed for GetByteSize

	call	GeodePrivLockMap	; es, ^hbx <- map block, or kernel's
					;  core block...
	jc	allocMap

	call	MemUnlock		; don't actually need it locked...

;	Look through the map block and try to find the passed # contiguous
;	words.
;
;	BX = handle of map block
;	DX = # contiguous words to allocate

scanMapBlock:
	call	GL_GetByteSize		;CX <- # bytes in map block
	call	AllocGeodePrivWords	;If found, branch and return.
	jnc	exit			;Else, reallocate block and try again.
	mov_tr	ax, cx
reallocMapBlock::
	add	ax, ((PRIV_DATA_SLOT_INCREMENT * (size word))+15) and not 15
	mov	ch, mask HAF_ZERO_INIT
	call	MemReAlloc
	jnc	scanMapBlock		;If no error, branch back up to try to
					; alloc again, else exit with error.
errorExit::
	mov	bx, 0			; signal error w/o biffing carry
exit:
	call	FarVGeodePrivSem
	.leave
	ret

ife	FULL_EXECUTE_IN_PLACE
unlockExit:
	call	MemUnlock
	jmp	errorExit
endif

allocMap:

if	FULL_EXECUTE_IN_PLACE
;
; We already have a handle pre-allocated, but discarded - just reallocate it
; to the correct size.
;
	mov	ax, es:[GH_privData]		;Get handle for privdata
	call	MemUnlock			;Unlock the kernel's coreblock
	mov_tr	bx, ax
	clr	ax
	jmp	reallocMapBlock
else
;	If no map block around, allocate PRIV_DATA_SLOT_INCREMENT slots to
;	begin with, rounding that up to a paragraph, to ensure all the bytes
;	are zero-initialized.

	push	bx			;Save kernel core block for unlock

	mov	ax, ((PRIV_DATA_SLOT_INCREMENT * (size word))+15) and not 15
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT shl 8)
	call	MemAllocSetOwnerFar	;Set owner of private data block to be
					; owner of core block 
	pop	ax
	xchg	ax, bx			;bx <- core block, ax <- map block
	jc	unlockExit
	
KXIP <	push	si							>
KXIP <	mov	si, es:[GH_privData]	;si <- pre-allocated block	>
NOKXIP <mov	es:[GH_privData], ax	;				>
	call	MemUnlock		;Unlock the Kernel's GeodeHeader
EC <	call	NullES							>
	mov_tr	bx, ax			;bx <- map block
KXIP <	call	XIPUsePreAllocatedHandle				>
KXIP <	pop	si							>
	jmp	scanMapBlock
endif
GeodePrivAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePrivFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees a group of contiguous words.

CALLED BY:	GLOBAL
PASS:		bx - offset into block
		cx - # words to free
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePrivFree	proc	far	uses	es, ax, di, bx, cx
	.enter
	mov	di, bx			;DI <- offset into map block
	sub	di, FIRST_GEODE_PRIV_OFFSET
EC <	call	CheckGeodePrivOffset					>

	call	GeodePrivLockMap
NEC <	jc	done		; just in case...			>

	clr	ax
	rep	stosw
NEC <done:								>
	call	GeodePrivUnlockMap	; Unlock map block
	.leave
	ret
GeodePrivFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPrivDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the private data block for this geode, allocating one
		if it doesn't have one yet.

CALLED BY:	GLOBAL
PASS:		bx <- handle of GeodeHeader
		di <- offset into private data we are writing to
		cx <- # words we are writing
RETURN:		carry set if no priv data block and couldn't allocate new one
		else, bx = handle of private data block
DESTROYED:	ax, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPrivDataBlock	proc	near	uses	cx
	.enter

EC <	call	ECCheckGeodeHandle					>

	call	MemLock				;Lock the geode header
	mov	es, ax
	mov	ax, es:[GH_privData]		;Get private data block handle
	tst	ax				;If privData block handle 
	jnz	noAlloc				; then branch (don't alloc one)

;	ALLOCATE NEW PRIVATE DATA BLOCK FOR THIS GEODE

	call	FarPGeodePrivSem
	mov	ax, es:[GH_privData]		;
	tst_clc	ax				; Make sure no-one allocated
						;  it while we blocked on
						;  the privSem (clears carry)
	jnz	vSemAndExit			;

	push	bx
	mov	ax, cx
	shl	ax, 1				; ax <- # bytes to write
	add	ax, di				;AX <- passed offset
						;      + # bytes to write
	add	ax, 15				;Round up to next 16-byte 
	andnf	ax, not 15			; boundary so all bytes get
						; zero-initialized
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or (mask HAF_ZERO_INIT shl 8)
	call	MemAllocSetOwnerFar		;Set owner of data block to be
						; core block
	pop	ax				;Pop geode header handle
	xchg	ax, bx				;AX <- new block
						;BX <- handle of geode header
	jc	vSemAndExit			;If error allocating, exit
	mov	es:[GH_privData], ax		;

vSemAndExit:
	call	FarVGeodePrivSem		;(destroys nothing)
noAlloc:
	call	MemUnlock			;Unlock core block
EC <	call	NullES							>
	mov_tr	bx, ax				;bx <- privdata block
	.leave
	ret
GetPrivDataBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePrivWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes data to the private data area of the passed geode.

CALLED BY:	GLOBAL
PASS:		bx - geode handle (or 0 to use handle of current process)
		di - offset returned by GeodePrivAlloc
		cx - # words to write
		ds:si - pointer to words to write out
RETURN:		carry set if couldn't write data (out of memory)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePrivWrite	proc	far	
	srcSeg	local	sptr 	push ds
	len	local	word 	push cx		;# words to return
	.enter

	call	PushAllFar
	sub	di, FIRST_GEODE_PRIV_OFFSET
EC <	call	CheckGeodePrivOffset					>
	LoadVarSeg	ds
	tst	bx
	jnz	10$
	mov	bx, ss:[TPD_processHandle]	;BX <- handle of current proc
10$:

;	Make sure we aren't writing to the kernel geode, as we keep the
;	GeodePriv map information there.

EC <	cmp	bx, handle 0						>
EC <	ERROR_Z	CANNOT_CALL_GEODE_PRIV_WRITE_ON_KERNEL_GEODE		>

	call	GetPrivDataBlock		;
	jc	exit				;

	call	MemPLock			;
	mov	es, ax				;ES - segment of private data

	call	GL_GetByteSize			;AX <- byte size of block
	mov	cx, len
	shl	cx, 1				;CX <- # bytes to write
	add	cx, di				;CX <- offset after last word
						; to write.
	cmp	ax, cx				;If block is large enough...
	jae	bigEnough			; ...then branch...

	mov	ax, cx				;Round size up to nearest
	add	ax, 15				; paragraph boundary so all
	andnf	ax, not 15			; bytes zero-initialized
	mov	ch, mask HAF_ZERO_INIT		;If couldn't realloc, exit
	call	MemReAlloc
	jc	unlockVExit	
	mov	es, ax
bigEnough:

;	OFFSET LIES WITHIN BLOCK. COPY DATA IN

	mov	cx, len
	mov	ds, srcSeg			;DS:SI <- src
	rep	movsw				;Copy data into privData block
	clc
unlockVExit:
	call	MemUnlockV
exit:
	call	PopAllFar
	.leave
	ret

GeodePrivWrite	endp

;---

GL_GetByteSize	proc	near
EC <	call	AssertDSKdata						>
	mov	ax,ds:[bx][HM_size]
	mov	cl,4			;shift left four times to multiply by
	shl	ax,cl			;16 to get number of bytes
	mov	cx,ax
	ret
GL_GetByteSize	endp

;---


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XIPUsePreAllocatedHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use a pre-allocated handle, by swapping memory with
		a newly-allocated handle

CALLED BY:	GLOBAL

PASS:		BX	= New handle (allocated)
		SI	= Pre-allocated handle

RETURN:		BX	= Pre-allocated handle, pointing at allocated memory

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if		KERNEL_EXECUTE_IN_PLACE
XIPUsePreAllocatedHandle	proc	near
		uses	ax, cx, dx, ds
		.enter
	
		; First swap the handles
		;
		call	MemSwap

		; Now add the new free handle back onto the free list
		;
		LoadVarSeg	ds, ax
		call	FarPHeap
		mov	ax, ds:[loaderVars].KLV_handleFreePtr
		mov	ds:[bx].HM_next, ax
		mov	ds:[loaderVars].KLV_handleFreePtr, bx
		inc	ds:[loaderVars].KLV_handleFreeCount
		call	FarVHeap
		mov	bx, si			; pre-allocated handle => BX

		.leave
		ret
XIPUsePreAllocatedHandle	endp
endif

GLoad ends
