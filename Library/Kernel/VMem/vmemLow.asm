COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VM Managment
FILE:		vmemLow.asm

AUTHOR:		Adam de Boor, Dec  4, 1989

ROUTINES:
	Name			Description
	----			-----------
    INT VMEnforceHandleLimit	See if VM blocks should be biffed to reduce
    				the number of handles used by a file
    INT	VMBlockBiffableLow	See if a memory block owned by a VM
    				file may be thrown away
    INT SetHandleLow		Set the memory handle for a VM block
    INT	CreateVMHandle

    INT	VMGetBlkHandle		get VM blk han given the VM mem han

    INT	VMGrabHeaderBlk		lock a VM mem blk
    INT	VMReleaseHeader		unlock the header block
    INT	VMDiscardMemBlk		discard a VM mem blk

    INT	VMGetMemSpace		allocate a mem blk as a VM blk

    INT VMUpdateLow		write all dirty blocks to disk
    INT VMCheckWritable		see if all used blocks will fit on disk

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 4/89	Initial revision


DESCRIPTION:
	Low-level VM file manipulation	
		
REGISTER USAGE:
		bx - VM file handle
		di - VM block handle
		si - VM mem handle

		when relevant:
		ax - number of bytes
		cx - high word of file pos
		dx - low word of file pos

		bp - general purpose

	$Id: vmemLow.asm,v 1.2 98/05/08 11:25:46 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Moved out of kcode, as kcode is limited to 49680 bytes in Redwood, currently.
;
kcode	segment	resource				



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMEnforceHandleLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that the passed VM file does not use an inordinate
		number of handles, as can happen if you've got a large fast
		swap device, so clean blocks are never discarded.

CALLED BY:	GLOBAL
PASS:		ds - VM header (grabbed)
		bx - VM file handle
RETURN:		nada
DESTROYED:	nada (flags preserved)
 
PSEUDO CODE/STRATEGY:
	If VMH_numResident (the # handles in use by this VM file) > hi_limit {
	    scan through all the in-use blocks while VMH_numRes > lo_limit {
	      discard swapped discardable blocks
	    }
	    if !VMA_SYNC_UPDATE {
	      scan through all the in-use blocks while VMH_numRes > lo_limit {
		write out swapped dirty blocks
		force idle-time update
	      }
	    }
	    scan through all the in-use blocks while VMH_numRes > lo_limit {
	      discard or write out any remaining blocks in LRU order
	    }
	}

	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VM_HANDLE_HIGH_WATER_MARK_	equ	250
; The maximum number of handles we want to allow in use by a VM file - this
; number could be increased

VM_HANDLE_LOW_WATER_MARK_	equ	150
; When the # handles in use passes VM_HANDLE_HIGH_WATER_MARK, we try to reduce
; it to VM_HANDLE_LOW_WATER_MARK.

VMEnforceHandleLimit	proc	far
	uses	cx, dx
	.enter
	mov	dx, VM_HANDLE_HIGH_WATER_MARK_
	mov	cx, VM_HANDLE_LOW_WATER_MARK_
	call	VMEnforceHandleLimitLow
	.leave
	ret
VMEnforceHandleLimit	endp

VMEnforceHandleLimitLow	proc	far
	.enter
	pushf
EC <	call	VMCheckFileHandle					>
EC <	call	VMCheckStrucs						>

	cmp	ds:[VMH_numResident], dx
	jbe	exit

enforceHandleLimit::
	call	PHeap	;VMUpdateAndRidBlk wants the heap semaphore

;	If demand paging not allowed, then we cannot discard any of the VM
;	blocks, as we can't read them back in, so just give up on the
;	whole thing

	push	ax, bx, dx, bp, di, es
	LoadVarSeg	es
	mov	bp, es:[bx].HF_otherInfo
EC <	call	VMCheckVMHandle						>
	test	es:[bp].HVM_flags, mask IVMF_DEMAND_PAGING
	jz	popExit

;	First, discard swapped VM blocks

	mov	di, offset DiscardSwappedBlocks
	call	EnumForAllResidentBlocks
EC <	WARNING_C	ERROR_ENCOUNTERED_WHILE_WRITING_OUT_VM_BLOCK	>
	jc	popExit		;If we encountered an error, it must have been
				; due to a disk error when writing out the
				; block, so there's no need to continue

	cmp	ds:[VMH_numResident], cx
	jbe	popExit

;	If we still haven't biffed enough handles, write out dirty swapped
;	blocks, if this is not a "sync update" file.

	test	ds:[VMH_attributes], mask VMA_SYNC_UPDATE
	jnz	discardResidentBlocks

	mov	di, offset WriteOutSwappedBlocks
	call	EnumForAllResidentBlocks
EC <	WARNING_C	ERROR_ENCOUNTERED_WHILE_WRITING_OUT_VM_BLOCK	>
	jc	popExit		;If we encountered an error, it must have been
				; due to a disk error when writing out the
				; block, so there's no need to continue

	cmp	ds:[VMH_numResident], cx
	jbe	popExit

discardResidentBlocks:

;	We *still* haven't biffed enough handles, so start in on the
;	discardable resident blocks (in LRU order, natch). There is the
;	possibility that in the previous passes, some previously resident
;	blocks were swapped out, so we'll try biffing *all* blocks, not just
;	the resident ones.

	clr	ax
	mov	di, offset FindLRUBiffableBlock
	call	EnumForAllResidentBlocks

	tst	ax		;If no biffable blocks, just exit - we've done
	jz	popExit		; all we can.

;	We've found the least-recently-used resident VM mem handle, so nuke it.
;	We already checked to be sure that the block is biffable, so if
;	VMUpdateAndRidBlk returns an error, then we know that it was a disk
;	error, so we should abort this loop, lest we loop forever, vainly
;	trying discard the same least-recently-used block.

	mov_tr	di, ax		;BX <- mem handle to biff
	call	RidBlk
	jc	popExit

;	Keep discarding blocks until we hit the low-water mark, or until we
;	run out of biffable blocks.

	cmp	ds:[VMH_numResident], cx
	ja	discardResidentBlocks			
popExit:
	pop	ax, bx, dx, bp, di, es
	call	VHeap
exit:
	popf
	.leave
	ret
VMEnforceHandleLimitLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RidBlk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tries to biff the passed block, handling all the details
		necessary to use VMUpdateAndRidBlk (bringing in dirty
		swapped blocks, restoring the handle's data address on
		errors, etc).

CALLED BY:	GLOBAL
PASS:		ds - grabbed VMHeader
		di - VMBlockHandle being biffed
		bp - VM handle
RETURN:		carry set if error
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RidBlk	proc	near	uses	dx, bp, ds, es
	.enter
	segmov	es, ds
	LoadVarSeg	ds
	mov	bx, es:[di].VMBH_memHandle

;	VMUpdateAndRidBlk does not deal gracefully with swapped dirty blocks,
;	so make them resident before calling it.

	test	ds:[bx].HM_flags, mask HF_SWAPPED 
	jz	biffIt
	test	ds:[bx].HM_flags, mask HF_DISCARDABLE
	jnz	biffIt

	push	ax, bp
	mov	bx, ds:[bp].HVM_fileHandle	;BX <- file handle
	mov	ax, di
	call	VMLock
	call	VMUnlock
	mov	bx, bp				;BX <- block handle
	pop	ax, bp

;	vmDiscard EC shouldn't have nuked this block (since it is not
;	discardable), but just to be safe, make sure the block is still
;	resident:

	tst_clc	es:[di].VMBH_memHandle
	jz	exit
EC <	cmp	bx, es:[di].VMBH_memHandle				>
EC <	ERROR_NZ	VM_HANDLE_MISMATCH				>

biffIt:
	clr	dx
	xchg	dx, ds:[bx].HM_addr
	call	VMUpdateAndRidBlk
EC <	WARNING_C	ERROR_ENCOUNTERED_WHILE_WRITING_OUT_VM_BLOCK	>
	jnc	exit

;	There was an error, so restore the block address

	mov	ds:[bx].HM_addr, dx

exit:
	.leave
	ret
RidBlk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscardSwappedBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discards the passed swapped block, if it is discardable

CALLED BY:	GLOBAL
PASS:		ds - VMHeader
		es - dgroup
		bp - VMHandle
		di - VMBlockHandle
RETURN:		carry set if error in VMUpdateAndRidBlk
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscardSwappedBlocks	proc	near
	.enter

;	Check if the block is swapped

	mov	bx, ds:[di].VMBH_memHandle
EC <	xchg	bx, si							>
EC <	call	VMCheckMemHandle					>
EC <	xchg	bx, si							>
   	test	es:[bx].HM_flags, mask HF_SWAPPED
	jz	exit		;Branch with carry clear if not swapped

;	If the block is dirty, just exit (we'll check it in the next pass,
;	if necessary)

	test	es:[bx].HM_flags, mask HF_DISCARDABLE
	jz	exit

;	Check if the block is biffable

	call	BiffBlockCommon
	jnc	exit

;	The block is biffable, so biff it.

	call	RidBlk
exit:
	.leave
	ret
DiscardSwappedBlocks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteOutSwappedBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes out the passed swapped block, if it is *not*
		discardable.

CALLED BY:	GLOBAL
PASS:		ds - VMHeader
		es - dgroup
		bp - VMHandle
		di - VMBlockHandle
RETURN:		carry set if error in VMUpdateAndRidBlk
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteOutSwappedBlocks	proc	near
	.enter

;	Check if the block is swapped

	mov	bx, ds:[di].VMBH_memHandle
EC <	xchg	bx, si							>
EC <	call	VMCheckMemHandle					>
EC <	xchg	bx, si							>
   	test	es:[bx].HM_flags, mask HF_SWAPPED
	jz	exit		;Branch with carry clear if not swapped

;	The assumption is that we already tried to biff any discardable
;	swapped blocks in the last pass, so ignore them now. In the last
;	pass, we'll check them again, to catch any clean blocks that got
;	swapped out while we are doing this.

	test	es:[bx].HM_flags, mask HF_DISCARDABLE
	jnz	exit

	call	BiffBlockCommon
	jnc	exit			;Branch if block isn't biffable

;	The block is biffable, so biff it.

	call	RidBlk

exit:
	.leave
	ret
WriteOutSwappedBlocks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLRUBiffableBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the least-recently-used biffable block

CALLED BY:	GLOBAL
PASS:		ds - VMHeader
		es - dgroup
		bp - VMHandle
		di - VMBlockHandle
		ax - VMBlockHandle of previous LRU biffable-block
RETURN:		ax - VMBlockHandle of least-recently-used block between
			passed in handle and current handle, if biffable
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLRUBiffableBlock	proc	near
	.enter
	mov	bx, ds:[di].VMBH_memHandle
EC <	xchg	bx, si							>
EC <	call	VMCheckMemHandle					>
EC <	xchg	bx, si							>

	tst	ax
	jz	noPrevious

;	See if the current block has been accessed less recently than the
;	old block (you can determine how long it has been since a block was
;	used by subtracting the current systemCounter from the blocks' usage
;	value

	push	cx, bx, dx
	mov	cx, es:[systemCounter].low
	mov	dx, cx
	sub	cx, es:[bx].HM_usageValue	;CX <- # ticks since last used
	mov	bx, ax				;BX <- prev LRU block
	mov	bx, ds:[bx].VMBH_memHandle
	sub	dx, es:[bx].HM_usageValue	;DX <- # ticks since last used

;	CX = # ticks since this block was last used
;	DX = # ticks since previous LRU block was last used

	cmp	dx, cx
	pop	cx, bx, dx
	jae	exit		;Branch if previous LRU block was older
	
noPrevious:

;	Now, see if this block is biffable.

	push	ax
	call	BiffBlockCommon
	pop	ax
	jnc	exit

;	The block is biffable, so return it as the LRU block

	mov	ax, di
exit:
	clc		;Return carry clear to scan through all of the
			; handles
	.leave
	ret
FindLRUBiffableBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BiffBlockCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the block is biffable, doing some simple checks 
		to see if it is possible, first.

CALLED BY:	GLOBAL
PASS:		ds - VMHeader
		es - dgroup
		bp - VMHandle
		di - VMBlockHandle
		bx - associated mem handle
RETURN:		carry set if block is biffable
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BiffBlockCommon	proc	near
	.enter

;	If we need to preserve the handle for this block, don't try to biff
;	it

	test	ds:[di].VMBH_flags, mask VMBF_PRESERVE_HANDLE
	jnz	exit		;Branch with carry clear

;	If the block is locked, it isn't biffable, so get out of here

	tst_clc	es:[bx].HM_lockCount
	jnz	exit

;	If VMA_NO_DISCARD_IF_IN_USE is set, and this is a swapped LMEM
;	block, then lock it down to make it resident, because otherwise
;	VMBlockBiffableLow will just assume it cannot be nuked.

	test	ds:[VMH_attributes], mask VMA_NO_DISCARD_IF_IN_USE
	jz	biffTheBlock
	test	es:[bx].HM_flags, mask HF_LMEM 
	jz	biffTheBlock
	test	es:[bx].HM_flags, mask HF_SWAPPED
	jz	biffTheBlock

;
;	Lock the swapped block, so VMBlockBiffableLow can do its in-use
;	check.
;


	push	bp
	mov	bx, es:[bp].HVM_fileHandle	;BX <- file handle
	mov	ax, di
	call	VMLock
	call	VMUnlock
	mov	bx, bp			;BX <- block handle
	pop	bp			;BP <- file handle

;	It's possible that the user has vmDiscard EC on, which biffed the
;	block when we called VMUnlock, so if this is the case, exit.

	tst_clc	ds:[di].VMBH_memHandle
	jz	exit
EC <	cmp	bx, ds:[di].VMBH_memHandle				>
EC <	ERROR_NZ	VM_HANDLE_MISMATCH				>

biffTheBlock:

;	If a block can be biffed, then we end up calling VMBlockBiffable twice
;	(once now, and once in VMUpdateAndRidBlk). We do this so we can be sure
;	that if VMUpdateAndRidBlk returns an error, it is because of a disk
;	error, and not just because a block was not biffable.
;
;	The hope is that this procedure doesn't happen very often, and that
;	biffing a block takes enough time that calling VMBlockBiffable
;	twice won't have an impact. The alternative is to break up
;	VMUpdateAndRidBlk and just call the part that discards/writes out
;	the block if the block can be biffed.
;

	push	ds
	LoadVarSeg	ds			;DS <- idata
	call	VMBlockBiffable			;Carry clear if block biffable
	pop	ds
	cmc					;Set carry if block biffable

exit:
	.leave
	ret
BiffBlockCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumForAllResidentBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the passed near routine for all used blocks

CALLED BY:	GLOBAL
PASS:		di - routine to call
		ds - grabbed VM header
		es - dgroup
		cx - low water mark

		Callback is passed:
			ax, as passed in/modified by previous callback

		Callback returns:
			carry set to end enumeration

RETURN:		ax - returned from callback
		carry as returned from callback
DESTROYED:	bx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumForAllResidentBlocks	proc	near
	.enter
	mov	bx, di			;BX <- callback
	mov	di, offset VMH_blockTable

loopTop:
	call	VMGetNextUsedBlk	;DI = in-use VMBlockHandle
	cmc
	jnc	exit			;Branch if no more in-use blocks
	tst	ds:[di].VMBH_memHandle	;Loop if block is not resident
	jz	loopTop

	push	bx
	call	bx			;Call our callback
	pop	bx
	jc	exit

;	Have we nuked enough handles yet? If so, exit.

	cmp	ds:[VMH_numResident], cx
	ja	loopTop
	clc
exit:
	.leave
	ret
EnumForAllResidentBlocks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMBlockBiffableLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a block can safely be biffed

CALLED BY:	VMBlockBiffable, VMUpdateAndRidBlk
PASS:		ds	= idata
		bx	= block to check
		bp	= VMHandle
		dx	= address of data block, if known, or 0 if not known
RETURN:		es	= grabbed header block
		bx	= header handle
		ax	= block handle
		carry set if block cannot be nuked
		jz if header doesn't need releasing when caller is done
DESTROYED:	dx (if dx pass in zero), si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMBlockBiffableLow	proc	far
		.enter
EC<		call	AssertDSKdata					>
EC<		mov	si, bx						>
EC<		call	VMCheckMemHandleFar				>
EC<		call	VMCheckVMHandle					>

		mov	ax, bx				;save mem handle

EC <		mov	bx, ds:[bp].HVM_fileHandle;bx <- VM file han	>
EC<		call	VMCheckFileHandle				>

		clr	si

		; Check for demand paging not allowed

		test	ds:[bp].HVM_flags, mask IVMF_DEMAND_PAGING
		jz	noBiffNoRel

	;
	; It is possible for us to be called for a VM block (the header,
	; actually) when the header has *just* been read in from disk
	; and its handle not yet stored in the VM handle. We accept
	; no responsibility for the consistency of the VM handle -- if
	; the header is 0, we simply tell our caller that it may not
	; biff the block in question.
	;
		mov	bx, ds:[bp].HVM_headerHandle
		tst	bx
		jnz	headerResident
noBiffNoRel:
		dec	si		; si = -1 so inc returns ZF set
		jmp	noBiff

headerResident:
	;
	; If dx!=0 then we have mucked with the address field of some block
	; (which might be the header), thus we must check this so we
	; don't try to do a MemThreadGrabNB on a block with data adrress=0
	;
		tst	dx
		jz	headerOK		;we know header's resident
		cmp	bx, ax			;checking header?
		jne	headerOK
		INT_OFF
		cmp	ds:[bp].HVM_semaphore, 1;make sure the HandleVM isn't
						; owned. If it is, the other
						; thread could have just loaded
						; the header handle into SI and
						; be on its way to grabbing it
						; when we come through and
						; rudely throw it away --
						; ardeb 8/6/92
		jne	noBiffNoRel
		mov	ds:[bx].HM_addr, dx	;store actual address away so
						; MemThreadGrabNB doesn't have
						; a fit.
						; XXX: WHERE THE HELL DO WE SET
						; THIS BACK TO 0 ON ERROR? DO
						; WE NEVER GET AN ERROR?
headerOK:
	;
	; Deal with weird recursion that's possible when clearing out
	; discardable blocks from a fast swap device (and at other times).
	; The recursion looks like this:
	;	ThrowOutBlocks -> ThrowOutOne(vm data block) -> us ->
	;	MemThreadGrabNB(swapped header) -> AllocateHandleAndBytes ->
	;	ThrowOutBlocks -> ThrowOutOne(vm data block) -> us ->
	;	MemThreadGrabNB(still swapped, but owned header) returns
	;	ax = 0, which is ungood.
	; To deal with this, we see if the header has a data address of 0 but
	; seems partially owned and refuse to biff the data block if so.
	;
		cmp	ds:[bx].HM_addr, 0	; resident?
		jne	doGrab			; yes -- is ok
		cmp	ds:[bx].HM_otherInfo, 1	; owned?
		jne	noBiffNoRel		; yes -- is bad
doGrab:
		push	ax
	;
	; changed from just doing a ThreadGrab to doing what amounts
	; to an EnterVMFile - so that we can recurse.
	; Why do we need to recurse?  So that we can write out blocks
	; of a file when reading in other blocks of that same file..
	; Could be crucial on resource-poor devices.
	;
		push	si
		INT_OFF
		cmp	ds:[bp].HVM_semaphore, 1
		je	grabIt
		tst	ds:[bx].HM_lockCount
		jz	mustAbort
		mov	si, ds:[bx].HM_usageValue
		cmp	si, ds:[currentThread]
		je	justLockIt
mustAbort:
		pop	si
		pop	ax
		jmp	noBiffNoRel		; couldn't grab, so
						; can't biff and no
						; need to release.
grabIt:
		FastMemP	ds, bp, INT_OFF
justLockIt:
		pop	si
		call	MemThreadGrabNB		; turns INT_ON
		mov	es, ax			;es <- header seg
		pop	ax

		jc	noBiffNoRel		;CF set => couldn't grab, so
						; can't biff and no need to
						; release.

	;
	; We have the header, now we must see if the block can be
	; biffed.  First, check for VMA_NO_DISCARD_IF_IN_USE and a
	; block that is in use
	;
		xchg	ax, bx			;bx = mem handle, ax = header

		test	es:[VMH_attributes], mask VMA_NO_DISCARD_IF_IN_USE
		jz	noInUseCheck

		test	ds:[bx].HM_flags, mask HF_LMEM
		jz	noInUseCheck
		push	ds

	;
	; If we are dealing with an object block that is swapped we
	; must assume that it cannot be biffed in any further manner
	; since it could be in-use
	;
		tst	dx
		jnz	getAddrFromDX
		tst	ds:[bx].HM_addr
		jz	noBiffObjBlock
		mov	dx, ds:[bx].HM_addr	;dx = mem block
getAddrFromDX:
		mov	ds, dx
		cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
		clc				;if not object block then branch
		jnz	notObjectBlock		;with carry clear to allow biff
		tst_clc	ds:[OLMBH_inUseCount]	;if in-use count is 0 then
		jz	notObjectBlock		;branch with carry clear to
						;allow biff
noBiffObjBlock:
		stc
notObjectBlock:
		pop	ds
		jc	noBiffSwapMemAndHeader

noInUseCheck:
	; bx = mem handle, ax = header
	;
	; First see if we're allowed to update dirty blocks
	; asynchronously for this file. Of course, we only care about
	; this if the block in question is dirty...
	;
		test	ds:[bx].HM_flags, mask HF_DISCARDABLE
		xchg	ax, bx			; ax = mem handle, bx = header
		jnz	checkHeader

	;
	; If file is read only, we obviously can't write anything out.
	; It's ok to use SI here, as inc of a file handle will never be 0,
	; so we'll still return ZF clear.
	; 
		mov	si, ds:[bp].HVM_fileHandle
			CheckHack <FA_READ_ONLY eq 0>
		test	ds:[si].HF_accessFlags, mask FAF_MODE
		jz	noBiff


		test	es:[VMH_attributes], mask VMA_SYNC_UPDATE
		jnz	noBiff			; asynch update not allowed
checkHeader:
		cmp	ax, bx			;dealing with header?
		clc				;clear in case not header
		jne	canBiff			;no other tests needed. ZF
						; already clear

	;
	; For the header, we just need to make sure the header's the
	; only block resident...and the beast hasn't got
	; any blocks with VMBF_PRESERVE_HANDLE set whose memory has been
	; discarded (if it does, numResident can be down to 1, but we still
	; need the header, as we need the handle IDs for those blocks)
	; 
EC<		segxchg	ds, es					>
EC<		call	VMCheckDSHeader				>
EC<		segxchg	ds, es					>
		cmp	es:[VMH_numResident], 1
		jne	noBiff
		mov	si, offset VMH_blockTable
checkDiscardsLoop:
		add	si, size VMBlockHandle		; advance to next block
		cmp	si, es:[VMH_lastHandle]		; done?
		je	canBiffHeader
		test	es:[si].VMBH_sig, VM_IN_USE_BIT	; handle in use?
		jz	checkDiscardsLoop
		tst	es:[si].VMBH_memHandle		; have memory handle?
		jz	checkDiscardsLoop		; no => keep looking
							; yes => can't nuke hdr
noBiffSwapMemAndHeader:
		xchg	ax, bx		; if this was the header, ax == bx; if
					;  it's not, we're coping with what we
					;  did when checking OLMBH_inUseCount
noBiff:
		stc
canBiffHeader:
		inc	si		; return ZF clear but don't touch CF
canBiff:
		INT_ON			; in case was checking the header
		.leave
		ret
VMBlockBiffableLow		endp


kcode	ends				


VMHigh	segment resource



COMMENT @----------------------------------------------------------------------

FUNCTION:	SetHandleLow

DESCRIPTION:	Set the memory handle for a VM block and mark it as dirty

CALLED BY:	INTERNAL

PASS:
	cx - memory handle
	di - VM block handle
	bp - VM handle	ENTERED!
	ds - VM header
	es - idata

RETURN:
	ax - VM block handle

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

SetHandleLow	proc	near
	.enter
	mov	ds:[di][VMBH_memHandle], cx	;stuff mem han into blk han
	inc	ds:[VMH_numResident]
	mov	ax, di				;return blk han in ax

EC <	xchg	bx, cx							>
EC <	call	ECCheckMemHandleFar					>
EC <	xchg	bx, cx							>

	mov	di, cx
	INT_OFF
	mov	es:[di].HM_owner, bp	; ownership passes to the VM file
	mov	es:[di].HM_usageValue,0	; Initialize block as ungrabbed
	mov	es:[di].HM_otherInfo,1
	;
	; If this VM file is accessed by a single thread then set the
	; other info to -1 since we never really grab it
	;
	test	ds:[VMH_attributes], mask VMA_SINGLE_THREAD_ACCESS
	jz	multiThread
	mov	es:[di].HM_otherInfo, -1
multiThread:
	andnf	es:[di].HM_flags, not mask HF_DISCARDABLE
	INT_ON

	;
	; Deal with dirty notification & LMF_IS_VM bit for lmem blocks
	;
	xchg	bx, cx		; bx = memory handle

	test	es:[bx].HM_flags, mask HF_LMEM
	jz	checkDirty

	; normally it is a bad thing to call MemLock with a block in a
	; VM file.  We don't have many alternatives here, but MemLock is
	; safe since we have the file to ourself and nobody else knows
	; about the block yet.

	push	ds, ax
EC <	push	es:[bx].HM_owner					>
EC <	mov	ax, ss:[TPD_processHandle]				>
EC <	mov	es:[bx].HM_owner, ax					>
	call	MemLockSkipObjCheck
	mov	ds, ax
	ornf	ds:[LMBH_flags], mask LMF_IS_VM
	call	MemUnlock
EC <	pop	es:[bx].HM_owner					>
	pop	ds, ax

checkDirty:
	call	NotifyDirtyFar
	xchg	bx, cx

	.leave
	ret

SetHandleLow	endp
VMHigh	ends


VMOpenCode 	segment
COMMENT @-----------------------------------------------------------------------

FUNCTION:	CreateVMHandle

DESCRIPTION:	Allocate a handle for a VM file and initialize some fields.

CALLED BY:	VMOpen

PASS:		exclusive access to heap variables
		es - idata
		bx - PC/GEOS file handle
		ss:bp - inherited variables from VMOpen

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	The only difference between an PC/GEOS file handle and a VM file handle
	is the presence of a VM handle in the HF_otherInfo field.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

CreateVMHandle	proc	near	uses ax, si, ds
passedFlags	local	word
compaction	local	word
fileFlags	local	GeosFileHeaderFlags
fileAttributes	local	FileAttrs
returnValue	local	VMStatus
internalFlags	local	InternalVMFlags
	.enter inherit far

EC<	call	AssertESKdata						>

	segmov	ds, es
	push	bx
	call	MemIntAllocHandle	; far equiv. of AllocateHandle

	mov	al, internalFlags
	mov	ds:[bx].HVM_flags, al

	mov	ds:[bx].HVM_refCount, 1

	mov	ds:[bx].HVM_signature, SIG_VM

	mov	ax, ds:[currentThread]
	mov	ds:[bx].HVM_execThread, ax
	;clr	ax	; AllocateHandle zeroes it all
	;mov	ds:[bx].HVM_relocRoutine.offset, ax	; no relocation routine
	;mov	ds:[bx].HVM_relocRoutine.segment, ax
	;mov	ds:[bx].HVM_headerHandle, ax		;header not in memory

	mov	ds:[bx].HVM_semaphore, 1	;return handle unlocked

	mov	si, bx
	pop	bx				;retrieve file handle

EC <	call	ECCheckFileHandle					>

	mov	ds:[bx][HF_otherInfo], si	;store VM handle in file handle
	mov	ds:[si].HVM_fileHandle, bx	;store file handle in VM handle

EC<	call	VMCheckFileHandle					>

	; if IVMF_BLOCK_LEVEL_SYNC then set up refCount as a counter
	; else set it up as the update count

if not FLOPPY_BASED_DOCUMENTS
	test	internalFlags, mask IVMF_BLOCK_LEVEL_SYNC
	jnz	noGetUpdateCounter
	mov	ax, offset VMFH_updateCounter
	call	VMFileReadWord			;ax = counter
	mov	ds:[si].HVM_refCount, ax
noGetUpdateCounter:
endif

	.leave
	ret
CreateVMHandle	endp
VMOpenCode	ends

kcode	segment



COMMENT @----------------------------------------------------------------------

ROUTINE:	VMCheckMemHandleFar

SYNOPSIS:	See VMCheckMemHandle.

CALLED BY:	FAR

PASS:		bx - memory handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 6/94       	Initial version

------------------------------------------------------------------------------@

EC <VMCheckMemHandleFar	proc	far					>
EC <	call	VMCheckMemHandle					>
EC <	ret								>
EC <VMCheckMemHandleFar	endp						>


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetBlkHandle

DESCRIPTION:	Given the VM header and a VM mem handle, searches the
		block table to locate the block handle that contains the
		mem handle in its VMBH_memHandle field.

CALLED BY:	INTERNAL (VMUpdateAndRidBlock, VMMemBlockToVMBlock)

PASS:		ds - VM header
		ax - VM mem handle

RETURN:		di - VM block handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMGetBlkHandle	proc	near
EC<	call	VMCheckDSHeader						>

	mov	di, ds:[VMH_lastHandle]
10$:
	sub	di, size VMBlockHandle
	cmp	di, offset VMH_blockTable
	jb	done
	test	ds:[di].VMBH_sig, VM_IN_USE_BIT
	jz	10$
	cmp	ds:[di].VMBH_memHandle, ax
	jne	10$
done:
EC <	ERROR_C	VM_BLOCK_HANDLE_NOT_FOUND				>
	ret
VMGetBlkHandle	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMDiscardMemBlk

DESCRIPTION:	Given the VM block handle, the corresponding memory block and
		handle are freed.

CALLED BY:	INTERNAL (VMFree, VMUpdateAndRidBlk, VMFreeAllBlks)

PASS:		es - idata seg
		ds - VM header
		di - VM block handle

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMDiscardMemBlk	proc	far	uses ax, bx
	.enter
EC<	call	AssertESKdata						>
EC<	call	VMCheckDSHeader						>
EC<	call	VMCheckBlkHandle

	;
	; Fetch any handle that's there and mark block as non-resident
	;
	clr	bx
	xchg	bx, ds:[di].VMBH_memHandle
	tst	bx		; Anyone home?
	jz	10$		; no -- nothing to do

	;
	; Adjust header's numResident count if handle actually has memory
	;
	test	es:[bx].HM_flags, mask HF_DISCARDED
	jnz	5$
	dec	ds:[VMH_numResident]
5$:

EC <	push	ax, ds							>
EC <	LoadVarSeg	ds						>
EC <	mov	ax, ss:[TPD_processHandle]				>
EC <	mov	ds:[bx].HM_owner, ax					>
EC <	pop	ax, ds							>

	call	NearFree			;destroys bx
EC <	call	ECMemVerifyHeap					>
10$:
	.leave
	ret
VMDiscardMemBlk	endp




COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetMemSpaceAndSetOtherInfo

DESCRIPTION:	Call VMGetMemSpace and then set the HF_otherInfo field to -1
		if needed

CALLED BY:	INTERNAL (VMCreateHeader, VMGetMemHandle)

PASS:		es - idata seg
		bx - VM file handle
		ax - number of bytes to create (>0)
		cx - additional allocation flags for the block (e.g.
		     (mask HAF_ZERO_INIT shl 8) to initialize the block to
		     all zero)
		ds - VM header

RETURN:		si - mem handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@
VMGetMemSpaceAndSetOtherInfo	proc	far
	call	VMGetMemSpace
	;
	; If this VM file is accessed by a single thread then set the
	; other info to -1 since we never really grab it
	;
	test	ds:[VMH_attributes], mask VMA_SINGLE_THREAD_ACCESS
	jz	multiThread
	mov	es:[si].HM_otherInfo, -1
multiThread:
	ret
VMGetMemSpaceAndSetOtherInfo	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetMemSpace

DESCRIPTION:	Allocate memory to serve as a VM block. The block is allocated
		sharable and swapable by default. If the block is not to
		be dirty initially, you must pass mask HF_DISCARDABLE in CX.

CALLED BY:	INTERNAL (VMCreateHeader, VMGetMemHandle)

PASS:		es - idata seg
		bx - VM file handle
		ax - number of bytes to create (>0)
		cx - additional allocation flags for the block (e.g.
		     (mask HAF_ZERO_INIT shl 8) to initialize the block to
		     all zero)

RETURN:		si - mem handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VM_HAF	=	mask HAF_NO_ERR
VM_HF	=	mask HF_SHARABLE or mask HF_SWAPABLE
VM_MEM_FLAGS	=	(VM_HAF shl 8) or VM_HF

VMGetMemSpace	proc	far	uses ax, cx
	.enter
EC<	call	AssertESKdata						>
EC<	call	VMCheckFileHandle					>
EC<	tst	ax							>
EC<	ERROR_Z	VM_ERR							>

	push	bx
	mov	bx, es:[bx].HF_otherInfo;make HandleVM the owner
	ornf	cx, VM_MEM_FLAGS
	call	MemAllocSetOwner	;bx <- func(ax, bx, cx), destroys cx
	mov	si, bx			;return mem handle in si
	pop	bx			;restore VM file handle

	.leave
	ret
VMGetMemSpace	endp
kcode	ends



VMSaveRevertCode	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSaveRevertCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to handle VMSave and VMRevert

CALLED BY:	VMSave, VMRevert, VMSaveAs
PASS:		ax =	VMOperation
		cx	= non-0 for VMSave, 0 for VMRevert
		bx	= VM file handle
RETURN:		carry	= set on error
		ax	= error code
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine is FAR so we can use the
		VMPush_EnterVMFile and VMPop_ExitVMFile routines

		WARNING: THIS CODE CAN GET GROSS. IT USES INTERNAL SUBROUTINES
		TO KEEP THE BYTE-COUNT DOWN -- THE ROUTINES ARE TOO SMALL TO
		BE MADE INTO REAL ROUTINES ON THEIR OWN...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSaveRevertCommon proc	far

	;The only possible return values are VMSERV_NO_CHANGES, VMSERV_CHANGES
	;and VMSERV_TIMEOUT.  VMSERV_TIMEOUT is impossible since we passed no
	;timeout.  VMSERV_NO_CHANGES causes no problems.  This leaves
	;VMSERV_CHANGES in either the save or the revert case:
	;
	;Save:
	;Since save is illegal for a files opened shared multiple, the file
	;must be shared single.  One cannot "save" a file unless one has write
	;permission, which means to nobody else has write permission (since the
	;file was opened deny write).  Thus VMSERV_CHANGES is impossible here.
	;
	;Revert:
	;It is possible to get VMSERV_CHANGES on revert if the file is opened
	;read-only and somebody else changed the file.  In this case
	;VMSaveRevertCommon should do nothing because all the blocks have been
	;purged (just like revert of a read-only file).

		call	VMStartExclusiveNoTimeout

		call	VMPush_EnterVMFileFar

	; Only add another lock if we will need to access the disk

		tst	cx
		jnz	doDiskLock		; if not revert then always lock

		mov	di, offset VMH_blockTable
checkWillWriteLoop:
		mov	al, ds:[di].VMBH_sig
		test	al, VM_IN_USE_BIT
		jz	checkWillWriteNext
		cmp	al, VMBT_USED
		jne	doDiskLock		; => z, d or b so will at least
						;  write the header
checkWillWriteNext:
		add	di, size VMBlockHandle
		cmp	di, ds:[VMH_lastHandle]
		jnz	checkWillWriteLoop

		mov	ax, 0			;no write
		jmp	afterDiskLock
doDiskLock:
		call	VMAddExtraDiskLock
		mov	ax, -1			;need unlock
afterDiskLock:
		
		push	ax

		mov	di, ds:[VMH_lastHandle]
		jcxz	preScan			; go directly to scan if revert,
						;  as file will always fit.
	;
	; Make sure that following compression and discarding of backup and
	; zombie blocks, all the rest of the blocks will fit on disk. Do this
	; before we do anything else, so the file can still be reverted if
	; it won't fit.
	;
		push	cx
		clr	ch			; ch <- we'll be nuking backup
						;  and zombie blocks
		call	VMEnsureWillFit
		pop	cx
		jnc	preScan
		jmp	noSpecialDirtyCheck
preScan:
		push	si			; save header handle for exit
		push	bx			; ditto for file handle

	;
	; First Pass: Search for all BACKUP blocks. If reverting, exchange
	; file space with corresponding DUP block and free BACKUP. If saving,
	; free BACKUP block. DUP handle becomes USED.
	;
scanLoop:
EC <		call	VMCheckDSHeader				>
		;
		; Look for the next BACKUP block
		;
		sub	di, size VMBlockHandle
		cmp	di, offset VMH_blockTable
		LONG jbe done
		mov	bx, {word}ds:[di].VMBH_sig
		cmp	bl, VMBT_BACKUP
		jne	checkNonBackup
		mov	si, ds:[di].VMBH_uid	; uid of backup gives duplicate
		jcxz	revert

		;
		; Deal with zombie blocks during a save: they get biffed.
		;
		cmp	ds:[si].VMBH_sig, VMBT_ZOMBIE
		jne	promoteDuplicate
		call	freeDuplicateHandle	; Free the memory handle and
						;  any associated memory
		call	freeVMBlockSI		; Free the block handle now too
		jmp	freeBackup
revert:
		;
		; We're reverting, so we have to give the backup's file space
		; back to the duplicate and biff any memory associated with
		; that duplicate. We exchange the filePos and fileSize so any
		; space allocated for the duplicate will be freed too.
		;
		mov	bx, offset VMBH_fileSize
		push	cx
		mov	cx, 3
		call	VMExchangeWords
		pop	cx
		;
		; Free any memory associated with the duplicate as it is now
		; out-of-date. Have to deal with VMBF_PRESERVE_HANDLE, though...
		; 
		call	discardOrFreeSI
		cmp	ds:[si].VMBH_sig, VMBT_ZOMBIE
		jne	promoteDuplicate
		inc	ds:[VMH_numUsed]	; Block is back in use...
promoteDuplicate:
		;
		; Promote the DUP block to be a real USED block again
		;
		mov	ds:[si].VMBH_sig, VMBT_USED
		andnf	ds:[si].VMBH_flags, not mask VMBF_HAS_BACKUP
freeBackup:
		;
		; The backup block has no memory, so we can just call
		; VMFreeBlkHandle to get rid of it.
		;
		call	VMFreeBlkHandle
		jmp	scanLoop

checkNonBackup:
	;
	; See if the thing is a DUP block with no backup (needs to be promoted
	; or freed) or, when reverting, a dirty USED block (needs to have its
	; memory discarded when reverting)
	;
		cmp	bl, VMBT_DUP
		jne	checkUsed
		test	bh, mask VMBF_HAS_BACKUP; Do nothing with DUP blocks
		jnz	scanLoop		;  unless they have no backup
						;  as we'll get them when we
						;  get their backups
		jcxz	revertNBDuplicate
		;
		; SAVE: If block has a backup or isn't a duplicate, do nothing
		;
		mov	ds:[di].VMBH_sig, VMBT_USED	; Promote to USED
		jmp	scanLoop

checkUsed:
		jb	checkZombie		; => ZOMBIE
		tst	cx
		jnz	scanLoop
		;
		; REVERT: If block dirty, nuke its memory
		;
		mov	si, ds:[di].VMBH_memHandle
		tst	si
		jz	scanLoop		; no memory -- do nothing
		test	es:[si].HM_flags, mask HF_DISCARDABLE
		jnz	scanLoop		; clean -- do nothing
		xchg	si, di
		call	discardOrFreeSI
exchangeAndLoop:
		xchg	si, di
		jmp	scanLoop

checkZombie:
	;
	; Check if it is a ZOMBIE with no backup, in which case it won't
	; be freed via its backup. It doesn't have a memory block, just 
	; free the vm handle, for both save and revert. --cassie, 6/7/95
	;
		cmp	bl, VMBT_ZOMBIE
		jne	toScanLoop
		test	ds:[di].VMBH_flags, mask VMBF_HAS_BACKUP
		jnz	toScanLoop
EC <		tst	ds:[di].VMBH_memHandle				>
EC <		ERROR_NZ	VM_ERR					>
		call	VMFreeBlkHandle
toScanLoop:
		jmp	scanLoop
		
revertNBDuplicate:
		;
		; Duplicate with no backup when reverting: free its memory
		; and the block itself.
		;
		; Also: if this is the DB map block then zero out the db map
		;	field in the VM header
		;
		cmp	di, ds:[VMH_dbMapBlock]
		jnz	notFreeingDBMap
		mov	ds:[VMH_dbMapBlock], 0
notFreeingDBMap:
		xchg	si, di
		call	freeDuplicateHandle
		call	freeVMBlockSI
		jmp	exchangeAndLoop
		
done:
	;
	; SAVE/REVERT COMPLETE
	; 
		pop	bx
		pop	si
	;
	; Force an update with VMA_BACKUP FALSE after compressing the file
	; so all dirty blocks get put on disk as USED, not DUP.
	; 
		pop	ax
		push	ax
		tst	ax
		jz	noUpdateNeeded
		call	VMUpdateNoBackup
noUpdateNeeded:
	;
	; Set the NOTIFY_DIRTY flag if needed (if the file is in BACKUP
	; mode then VMUpdate does not set this)
	;
		jc	noSpecialDirtyCheck

	; Forcably clear the MODIFIED flag if we have got here with no
	; errors, this means that we must have skipped the VMUpdateNoBackup
	; above, but nothing needs to be done

		push	bp
		mov	bp, es:[bx].HF_otherInfo
		and	es:[bp].HVM_flags, not mask IVMF_FILE_MODIFIED

		test	ds:[VMH_attributes], mask VMA_BACKUP
		jz	noFaultInBlocks
		or	es:[bp].HVM_flags, mask IVMF_NOTIFY_OWNER_ON_DIRTY

		call	VMFaultInBlocksIfNeeded
noFaultInBlocks:
		clc					;indicate no error
		pop	bp

noSpecialDirtyCheck:
		call	VMReleaseExclusive

		pop	di
		pushf
		tst	di
		jz	noReleaseLock
		call	VMReleaseExtraDiskLock
noReleaseLock:
		popf
		jmp	VMPop_ExitVMFileFar

	;----------------------------------------------------------------------
	;		  INTERNAL ROUTINES
	;----------------------------------------------------------------------
freeDuplicateHandle:
	;
	; Subroutine to free the memory and handle associated with the
	; duplicate/zombie block whose VMBlockHandle is at es:[si]
	; 
		xchg	si, di
		call	VMDiscardMemBlk
		xchg	si, di
		retn
discardOrFreeSI:
	;
	; Subroutine to biff the memory for the VM block in si. If the block
	; has the PRESERVE_HANDLE bit set, we need to just discard the
	; memory, keeping the handle valid. Else, we just call our friendly
	; neighborhood freeDuplicateHandle routine to nuke the beast.
	; 
		test	ds:[si].VMBH_flags, mask VMBF_PRESERVE_HANDLE
		jz	freeDuplicateHandle

		;
		; Want to free the memory associated with the duplicate block
		; but we have to preserve the handle ID for posterity.
		;
		mov	bx, ds:[si].VMBH_memHandle
		tst	bx
		jz	discardOrFreeComplete
		test	es:[bx].HM_flags, mask HF_DISCARDED
		jnz	discardOrFreeComplete
		call	swapESDS
		call	FarPHeap
		clr	dx
		xchg	dx, ds:[bx].HM_addr
		push	ax, cx
		call	DoDiscardFar
		pop	ax, cx
		call	FarVHeap
		call	swapESDS
		dec	ds:[VMH_numResident]
discardOrFreeComplete:
		retn

swapESDS:
		segxchg	ds, es
		retn

freeVMBlockSI:
	;
	; Free the VM block handle in SI (as opposed to the memory handle *for*
	; the block handle in SI, which is dealt with by discardOrFreeSI)
	;
		xchg	si, di
		call	VMFreeBlkHandle
		xchg	si, di
		retn
VMSaveRevertCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMComputeSizeNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out how many bytes of file space the data in the
		file require. This does not include free space, of course.

CALLED BY:	(INTERNAL) VMEnsureWillFit
PASS:		ds	= VMHeader
		es	= kdata
		ch	= non-zero to include backup/zombie blocks
			= zero to include only used/dup blocks
RETURN:		bxdx	= size needed
DESTROYED:	ax, cl, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMComputeSizeNeeded proc	far
		.enter
		mov	di, offset VMH_blockTable - size VMBlockHandle
		movdw	bxdx, <size VMFileHeader>; bxdx <- Start with the size
						 ;  of the file header
		mov	cl, 4			; cl <- shift count for turning
						;  paragraphs into bytes
pass1:
		call	VMGetNextInUseBlkFar
		jc	done
		cmp	ds:[di].VMBH_sig, VMBT_BACKUP
		ja	getSize
		tst	ch
		jz	pass1
getSize:
		mov	si, ds:[di].VMBH_memHandle
		mov	ax, ds:[di].VMBH_fileSize; assume non-res
		tst	si
		jz	haveBlockSize

if COMPRESSED_VM
		test	es:[si].HM_flags, mask HF_DISCARDABLE
		jnz	haveBlockSize		;use filesize if discardable
endif

		mov	ax, es:[si].HM_size
		shl	ax, cl
haveBlockSize:
	;
	; Add in the size of this block, please.
	;
		add	dx, ax
		adc	bx, 0
		jmp	pass1

done:
		.leave
		ret
VMComputeSizeNeeded endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMEnsureWillFit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the file will fit on disk once the save is complete

CALLED BY:	(INTERNAL) VMSaveRevertCommon
PASS:		ds	= header segment
		bx	= file handle
		ch	= non-zero if performing an update, so backup and
			  zombie block size is significant.
			= 
		es	= kdata
		si	= header handle
		bp	= HandleVM
RETURN:		carry set if won't fit:
			ax	= VM_UPDATE_INSUFFICIENT_DISK_SPACE
		carry clear if it will:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMEnsureWillFit proc	far
		uses	cx, dx, si, di, bp
		.enter
		call	GetFileSize		; dxax <- file size
		
		pushdw	dxax			; Save it for later...

		push	bx			; save file handle for possible
						;  write
	;--------------------
	;
	; First pass: sum the size of all the resident/non-resident USED and
	; DUP blocks. This will yield the size of the file when we're done,
	; since we compress the thing before updating.
	; 
		call	VMComputeSizeNeeded

	;--------------------
	;
	; To save time, see if the final size falls within the reach of any
	; currently known file block (assigned or used)
	;
		mov	di, offset VMH_blockTable
findBlockLoop:
		call	getBlockData
		jz	nextBlock
	;
	; bpcx = size of this block
	; siax = position of this block
	; bxdx = size of file
	;
		cmpdw	bxdx, siax
		jbe	weAreHappy		; => end size is below start of
						;  existing block, so file must
						;  be big enough already
		adddw	siax, bpcx		; siax <- end of existing block
		cmpdw	bxdx, siax
		jbe	weAreHappy		; => end size is below end of
						;  existing block, so file must
						;  be big enough already
	;
	; Current block tells us nothing, so advance to the next one.
	;
nextBlock:
		add	di, size VMBlockHandle
		cmp	di, ds:[VMH_lastHandle]
		jb	findBlockLoop
	;--------------------
	;
	; Ok. Couldn't find an existing block that covers the ending size.
	; We're going to have to extend the file to write it out. Attempt to
	; write a byte at the final size.
	;
		mov_tr	cx, bx			; cxdx <- final size
		pop	bx			; bx <- file handle
		push	bx
		pushdw	cxdx
		decdw	cxdx			; cxdx <- position of final
						;  byte we'll actually write
						;  (for a one-byte file, we'll
						;  write at position 0...)
		mov	al, FILE_POS_START
		call	FilePosFar

		push	ds
		mov	dx, sp
		segmov	ds, ss			; ds:dx <- buffer (anything,
						;  since it'll be overwritten)
		clr	al			; al <- return errors
		mov	cx, 1			; cx <- write 1 byte
		call	FileWriteFar
		pop	ds
		popdw	cxdx
		jnc	allocAssignedBlock
	;
	; Added, 6/22/95 -jw
	;
	; Some versions of DOS will screw up when saving the file-size
	; out to the disk. The problem is that in some versions of
	; DOS, the call to FilePos() changes the concept of how large
	; the file is, even though the file can't actually be that
	; large.
	;
	; By calling FileTruncate() with the original size, we force
	; the file-size back to what it ought to be.
	;
	; We can ignore errors here because truncating the file to
	; its original size should never produce an error.
	;
		pop	bx
		popdw	cxdx			; cxdx <- old size

		mov	al, FILE_NO_ERRORS
		; bx already holds the file handle
		call	FileTruncate		; Nukes ax, cx, dx

	;
	; Couldn't write, so we're hosed -- return appropriate error
	;
		mov	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
		stc				; signal an error
		jmp	exit
weAreHappy:
		pop	bx			; bx <- file handle

		pop	dx			; Nuke old file-size
		pop	dx			; preserve flags
done:
		clc
exit:
		.leave
		ret

allocAssignedBlock:
	;
	; Since the file has been extended, we must now allocate an assigned
	; block to cover the space we just allocated, lest an attempt to write
	; a block that won't fit in any of the free spaces yield a gap (when
	; FILE_POS_END, 0L is used to find the position of the new free space).
	; You might think that the file compression that'll take place before
	; the update would take care of this, as compression truncates the file.
	; You'd be wrong, however: compression/truncation doesn't take place
	; unless there's at least one assigned block in the file.
	;
	; We know how big the file used to be and how big it is now. We need
	; to allocate an assigned block to cover that span.
	;
	;
		pop	si			; si <- file handle
		popdw	bxax			; bxax <- original file size
		push	si			; save file handle for return
	;
	; Allocate an unassigned block handle so we can give it the file space.
	;
		mov	si, ds:[VMH_blockTable].VMBH_memHandle
		call	VMGetUnassignedBlk
	;
	; Now give it the file space, please.
	;
		movdw	ds:[di].VMFBH_filePos, bxax
		subdw	cxdx, bxax		; cxdx <- size of final block
		movdw	ds:[di].VMFBH_fileSize, cxdx
	;
	; Place it in the assigned list.
	;
		call	VMAssignBlk
	;
	; Coalesce with preceding block, if possible.
	;
		mov	bp, di
		mov	di, ds:[di].VMFBH_prevPtr
		call	VMCoalesceIfPossible
		pop	bx			; bx <- file handle
		jmp	done
		
	;--------------------
	; Examine the current block to see if it has any file space and return
	; that and its size.
	;
	; Pass:		ds:di	= block to check
	; Return:	flags set so JZ will take if block has no file space
	; 		bpcx	= size of block in file
	; 		siax	= position of block in file
getBlockData:
		test	ds:[di].VMBH_sig, VM_IN_USE_BIT
		jz	checkFree		; => might be assigned block
	;
	; Fetch size and position from used block.
	;
		mov	cx, ds:[di].VMBH_fileSize
		clr	bp
		movdw	siax, ds:[di].VMBH_filePos
		jmp	checkBlock

checkFree:
	;
	; Fetch size and position from free (assigned/unassigned) block.
	;
		movdw	bpcx, ds:[di].VMFBH_fileSize
		movdw	siax, ds:[di].VMBH_filePos
checkBlock:
	;
	; bpcx = size of this block
	; siax = position of this block
	;
		tstdw	bpcx
		retn

VMEnsureWillFit endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the file size

CALLED BY:	Utility
PASS:		bx	= File handle
RETURN:		dx.ax	= File size
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JCW	6/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileSize	proc	near
		uses	cx
		.enter
		mov	al, FILE_POS_END	; relative to end
		clrdw	cxdx			; at the end
		call	FilePosFar		; dx.ax <- file size
		.leave
		ret
GetFileSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMUpdateNoBackup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a VM file with VMA_BACKUP off.

CALLED BY:	VMSaveRevertCommon, VMSaveAs
PASS:		ds	= segment of grabbed header
		es	= idata
		bx	= file handle
		si	= handle of header
RETURN:		carry set if couldn't complete the update
			ax = error code (VM_UPDATE_INSUFFICIENT_DISK_SPACE
				if out of disk space, else FileError member
				from FileWrite)

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMUpdateNoBackup proc	near	uses bp
		.enter
	CheckHack <(size VMH_attributes eq 1) AND \
		   (size VMH_compressFlags eq 1) AND \
		   (offset VMH_compressFlags eq offset VMH_attributes+1)>

		mov	bp, es:[si].HM_owner	; bp <- HandleVM

		test	es:[bx].HF_accessFlags, mask FAF_MODE
		jz	readOnly

		push	{word}ds:[VMH_attributes]	; save attributes and
							;  compressFlags state
		andnf	ds:[VMH_attributes], not mask VMA_BACKUP
		BitClr	ds:[VMH_compressFlags], VMCF_NO_COMPRESS
		call	VMDoCompress
		pop	ax			;al = real VMH_attributes
		push	ax			;ah = real VMH_compressFlags
		mov	ds:[VMH_compressFlags], ah; Replace VMH_compressFlags now
						;  to prevent dirtying of
						;  blocks that have already
						;  been updated during a save.
						;  Else the file appears dirty
						;  in an annoying fashion even
						;  after the changes have been
						;  saved.
	;
	; We need to do one special test -- it is possible that
	; VMSaveRevertCommon marked the header as dirty without setting the
	; IVMF_FILE_MODIFIED flag.  We don't want to set this flag because that
	; would tell the app that the file is dirty.  Instead, we just check
	; for a dirty header here
	;
		test	es:[si].HM_flags, mask HF_DISCARDABLE
		jz	forceUpdate
		test	es:[bp].HVM_flags, mask IVMF_FILE_MODIFIED
		jz	nothingToUpdate		;branch with carry clear
forceUpdate:
		call	VMUpdateLowFar
nothingToUpdate:
	; VMUpdateLow does some very important operations on
	; VMA_TEMP_ASYNC and VMA_SYNC_UPDATE yet we push our bits
	; around it..  so we do some bitwork to grab only those bits.

		xchg	ax, bp			; preserve ax

		pop	ax			; retrieve old attributes

		and	{word}ds:[VMH_attributes], mask VMA_TEMP_ASYNC or \
						   mask VMA_SYNC_UPDATE
						; mask out all but these 2
		and	al, not (mask VMA_SYNC_UPDATE or \
				 mask VMA_TEMP_ASYNC)
						; mask out these two
		or	{word}ds:[VMH_attributes], ax
						; combine

		mov	ax, bp			; restore ax

readOnly:
;;;done:
		.leave
		ret

if 0
	;
	; There is nothing to update, but we still must set IVMF_FILE_MODIFIED
	; properly.
	;
nothingToUpdate:
		pop	{word}ds:[VMH_attributes]

readOnly:
	;
	; File is read-only, so no compressing and no updating. We need
	; to set IVMF_NOTIFY_OWNER_ON_DIRTY properly, however, based on
	; whether there are any dirty blocks around for the file.
	;
		test	ds:[VMH_attributes], mask VMA_NOTIFY_DIRTY
		jz	done
		or	es:[bp].HVM_flags, mask IVMF_NOTIFY_OWNER_ON_DIRTY
		jmp	done
endif

VMUpdateNoBackup endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMExchangeWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to exchange two words in two VMBlockHandles

CALLED BY:	VMSaveRevertCommon, VMAllocThis
PASS:		ds:si	= VMBlockHandle 1
		ds:di	= VMBlockHandle 2
		bx	= offset into handles of words to be exchanged
		cx	= number of successive words to exchange
RETURN:		nothing
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMExchangeWords	proc	near
		.enter
xchgLoop:
		mov	ax, ds:[di][bx]
		xchg	ax, ds:[si][bx]
		mov	ds:[di][bx], ax
		inc	bx
		inc	bx
		loop	xchgLoop
		.leave
		ret
VMExchangeWords	endp

VMSaveRevertCode	ends


kcode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	PvmSem, VvmSem

DESCRIPTION:	P and V routines for the vmSem semaphore.

CALLED BY:	INTERNAL (VMOpen, VMClose)

PASS:		nothing

RETURN:		vmSem semaphore Ped/Ved

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

PvmSemFar proc far
	call	PvmSem
	ret
PvmSemFar endp

PvmSem	proc	near
	push	bx
	mov	bx, offset vmSem
	jmp	SysPSemCommon
PvmSem	endp

VvmSemFar proc far
	call	VvmSem
	ret
VvmSemFar endp

VvmSem	proc	near
	push	bx
	mov	bx, offset vmSem
	jmp	SysVSemCommon
VvmSem	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	EnterVMFile

DESCRIPTION:	Utility routines for setting registers up for the VM code.

CALLED BY:	INTERNAL

PASS:		bx - VM file handle

RETURN:		VM handle grabbed/released
		es - idata seg
		bp - VM handle (not needed for exit)
		si - VM header handle
		ds - VM header

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

EnterVMFileFar	proc	far
	call	EnterVMFile
	ret
EnterVMFileFar	endp

EnterVMFile	proc near
EC<	call	VMCheckFileHandle					>
	push	bx
	LoadVarSeg	ds, bp
	mov	es, bp				;for return...
	mov	bx, ds:[bx][HF_otherInfo]	;get VM handle
	mov	bp, bx				;return VM handle in bp

	; we want a thread specific lock on the thing.  This is done using
	; the header handle thread-grab

	INT_OFF
	cmp	ds:[bx].HVM_semaphore, 1
	jz	PIt
	mov	si, ds:[bx].HVM_headerHandle
	tst	si				;if header handle is 0 then
	jz	PIt				;somebody else is in the
						;middle of P'ing it.
	tst	ds:[si].HM_lockCount		;ditto
	jz	PIt
	mov	si, ds:[si].HM_usageValue	;do we own the header?
	cmp	si, ds:[currentThread]
	jz	grabHeader
PIt:
	call	HandleP

grabHeader:
	INT_ON
	mov	si, ds:[bx].HVM_headerHandle	;return VM header handle in si
	pop	bx				;retrieve VM file handle
	call	VMLockHeaderBlk			;ds <- VM header
	ret
EnterVMFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the VM file

CALLED BY:	INTERNAL
PASS:		bx	= VM file handle used
		ds	= VM header
		es	= idata
RETURN:		nothing
DESTROYED:	si (flags intact)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExitVMFileFar	proc	far
		call	ExitVMFile
		ret
ExitVMFileFar	endp

ExitVMFile	proc	near
	pushf
EC<	call	AssertESKdata						>
EC<	call	VMCheckFileHandle					>
EC<	call	VMCheckStrucs						>

	mov	si, ds:[VMH_blockTable].VMBH_memHandle
	cmp	es:[si].HM_lockCount, 1		;must check before to deal
						; with block being thrown out
	call	VMReleaseHeader			; immediately after being
						; released
	jnz	done

	push	bx
	mov	bx, es:[bx].HF_otherInfo	;bx = HandleVM
	call	HandleV
	pop	bx
done:
	popf
	ret
ExitVMFile	endp

kcode	ends


VMHigh	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMUpdateLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write all dirty blocks out to disk.

CALLED BY:	VMUpdate, VMClose
PASS:		ds	= grabbed header
		al	= real VMH_attributes (since the ones in the header
			  might be faked)
		si	= header's handle
		bx	= VM file handle
		bp	= VM handle
		es	= idata
		VM handle grabbed
RETURN:		carry set if update couldn't be performed
			ax = error code (VM_UPDATE_INSUFFICIENT_DISK_SPACE
				if out of disk space, else FileError member
				from FileWrite)
DESTROYED:	di

PSEUDO CODE/STRATEGY:
	di <- second block (first block is header)
	done <- false
	repeat
		if used(di) then
			if block is dirty then
				write block out
			endif
		elif zombie(di) then
			if 
		else
			di <- next(di)
			if di = block past last then
				done <- true
			endif
		endif
	until done
	update file header

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 4/90		Initial version (extracted from VMUpdate)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VMUpdateLowRealAttrs	proc	far
	;
	; this is leaving the "temp" attributes in effect..  so we
	; must do any bitwork on both the temp and real attributes in
	; VMUpdateLow
	;
	mov	al, ds:[VMH_attributes]
	FALL_THRU	VMUpdateLowFar
VMUpdateLowRealAttrs	endp

VMUpdateLowFar	proc	far
		call	VMUpdateLow
		ret
VMUpdateLowFar	endp

VMUpdateLow	proc	near	uses bp, dx
	.enter
	; silently disallow any update of a file opened read-only.
	; XXX: be a bit more vocal here?
	test	es:[bx][HF_accessFlags], mask FAF_MODE	;test access
							; permissions
	jnz	checkWritable
	mov	ax, ERROR_ACCESS_DENIED
error:
	stc
	jmp	reallyDone

	;-----------------------------------------------------------------------
	;is there enough disk space?

checkWritable:
	push	ax				;save real attributes
	mov	ch, TRUE		; ch <- doing update, so include
					;  backup/zombie
	call	VMEnsureWillFit
	jnc	canWrite
	pop	ax
	mov	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
	jmp	error

canWrite:
	call	VMAddExtraDiskLock
redo:
	or	es:[bp].HVM_flags, mask IVMF_NOTIFY_OWNER_ON_DIRTY
						; Assume notification needed

	; mark the file as not modified so that we can tell if it was
	; compressed

	andnf	es:[bp].HVM_flags, not mask IVMF_FILE_MODIFIED

	call	VMMaintainExtraBlkHansFar		;func(es, si)

	; invalidate file's signature at the start of the write so if we die
	; during the update, the file is recognized as bogus.
	;
	; NOTE - this is now done with the very first VMWriteBlkLow

EC<	call	ECMemVerifyHeap						>
	;-----------------------------------------------------------------------
	;loop for all dirty blocks other than the header
	;
	mov	di, VMH_blockTable
blockLoop:
EC<	call	VMCheckHeaderHandle					>
	call	VMGetNextUsedBlk		;di <- next used
	LONG jc	checkForZombies			;branch if no more

	mov	bp, ds:[di].VMBH_memHandle	;else get mem handle of blk
	tst	bp				;in memory?
	je	blockLoop			;loop if not

	test	es:[bp][HM_flags], mask HF_DISCARDABLE or mask HF_DISCARDED
	jne	blockLoop			;loop if not dirty or if
						; discarded

	;
	; Perform a non-blocking grab of the block before attempting to write
	; it. If the grab fails, we assume it's ok for the thing to not be
	; updated -- the file won't be closed (we assume) until an update with
	; the block unlocked is performed.
	;
	; *** Special case: if single threaded then lock it
	;
	; To get around EC code that does not allow locking blocks owned by
	; a VM file, change the owner temporarily
	;
	xchg	bx, bp
	cmp	es:[bx].HM_otherInfo, -1
	jnz	multiThread
EC <	push	es:[bx].HM_owner					>
EC <	mov	ax, ss:[TPD_processHandle]				>
EC <	mov	es:[bx].HM_owner, ax					>
	call	MemLockSkipObjCheck
EC <	pop	es:[bx].HM_owner					>
	clc
	jmp	lockCommon
multiThread:
	call	MemThreadGrabNB
lockCommon:
	xchg	bx, bp
	mov_tr	dx, ax			; dx = segment address
	mov	ax, VM_UPDATE_BLOCK_WAS_LOCKED
	cmc				; invert carry so dirtyNotWritten
					;  knows whether to continue or bail
	jnc	dirtyNotWritten		; => couldn't grab, so can't write

	;
	; Write the block out
	;
	call	VMWriteBlkFar

	pushf
	push	ax
	xchg	bx, bp
	cmp	es:[bx].HM_otherInfo, -1
	jnz	multiThread2
EC <	push	es:[bx].HM_owner					>
EC <	mov	ax, ss:[TPD_processHandle]				>
EC <	mov	es:[bx].HM_owner, ax					>
	call	MemUnlock
EC <	pop	es:[bx].HM_owner					>
	jmp	unlockCommon
multiThread2:
	call	MemThreadReleaseFar
unlockCommon:
	xchg	bx, bp
	pop	ax
	popf
	jnc	blockLoop

dirtyNotWritten:
	; File still dirty, so don't notify on next VMDirty call
	mov	bp, es:[bp].HM_owner
	pushf
	and	es:[bp].HVM_flags, not mask IVMF_NOTIFY_OWNER_ON_DIRTY
	ornf	es:[bp].HVM_flags, mask IVMF_FILE_MODIFIED
	popf
	LONG jnc blockLoop

	inc	sp				; remove attributes from stack
	inc	sp
	jmp	releaseExtraLock

checkForZombies:
	call	VMUpdateCheckForZombies
	mov	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE	; in case of error
	jc	dirtyNotWritten			; error, abort update

;-----------------------------------------------------------------------
;update the header
updateHeader::
	;
	; OK.  Do VM Dirty Tracking stuff
	; first, check if we are in sync mode:
	;
	pop	ax					; get the real attribs
	test	al, mask VMA_SYNC_UPDATE
	jnz	notTempAsync
	;
	; ok, are we TempAsync, or full-time Async?
	;
	test	al, mask VMA_TEMP_ASYNC
	jz	fullTimeAsync
	;
	; guess were tempasync!  now, reset the real attributes so
	; they get written out
	;
	or	al, mask VMA_SYNC_UPDATE
	and	al, not mask VMA_TEMP_ASYNC
	;
	; and set the temp attributes (which turn into the real
	; attributes most of the time)
	;
	xchg	al, ds:[VMH_attributes]
	or	al, mask VMA_SYNC_UPDATE
	and	al, not mask VMA_TEMP_ASYNC
	xchg	al, ds:[VMH_attributes]
	;
	; check for a reloc routine and reset the dirty size
	;
notTempAsync:
	mov	bp, es:[si].HM_owner				; get VM Handle
	push	bx
EC<	call	VMCheckDSHeader				>
	mov	bx, ds:[VMH_blockTable].VMBH_uid		; get dirty limit
	INT_OFF
	cmp	{word}es:[bp].HVM_relocRoutine.segment, 0
	jnz	relocRoutinePresent
	mov	es:[bp].HVM_relocRoutine.offset, bx
relocRoutinePresent:
	INT_ON
	pop	bx	
fullTimeAsync:
	push	ax			

	call	VMMaintainExtraBlkHansFar	;func(es, si)
	;
	; Truncate the file if only one assigned block and it's at the end
	; of the file. This is what we used to do in VMDoCompress, but
	; decided it was better to save that until the file actually got
	; written, lest the machine crash after a compress while much of the
	; data was still in memory and the old version be unavailable, since we
	; truncated the file...
	; 
if VM_COMPACT_ON_UPDATE
	;
	; actually compress the file again to account for free space made
	; available when writing out dirty blocks in the above loop
	;
	call	VMCheckCompression
endif

	cmp	ds:[VMH_numAssigned], 1
	jne	setStatusBeforeUpdate
	mov	bp, ds:[VMH_assignedPtr]
	call	VMFindFollowingUsedBlk
	jnc	setStatusBeforeUpdate	; => free block not at end of file
	
	; mark no free space available
	clr	ax
	mov	ds:[VMH_numAssigned], ax
	mov	ds:[VMH_lastAssigned], ax
	mov	ds:[VMH_assignedPtr], ax

	; place the final assigned block on the unassigned list

	movdw	cxdx, ds:[bp].VMFBH_filePos
	mov	di, bp			; di <- blk to unassign
	call	VMUnassignBlk		; dirties the header (doesn't send
					;  notification)

	; truncate the file to the start of what was the final free block

	call	FileTruncate

setStatusBeforeUpdate:
	;
	; Set final return status, assuming header write succeeds. If something
	; couldn't be written b/c a block was locked, the caller will want
	; to know. This is signaled by IVMF_NOTIFY_OWNER_ON_DIRTY being set
	; to FALSE at dirtyNotWritten, above...
	; 
	clr	ax			; assume happy
	mov	bp, es:[si].HM_owner	; bp = VM handle (what a concept)
	test	es:[bp].HVM_flags, mask IVMF_NOTIFY_OWNER_ON_DIRTY
	jnz	allWritten
	mov	ax, VM_UPDATE_BLOCK_WAS_LOCKED

allWritten:

	;
	; If file not in NOTIFY_DIRTY mode, set IVMF_NOTIFY_OWNER_ON_DIRTY
	; back to FALSE so we don't notify anyone...
	; 
	test	ds:[VMH_attributes], mask VMA_NOTIFY_DIRTY
	jnz	doUpdate		; Leave IVMF_NOTIFY_OWNER_ON_DIRTY as is
	and	es:[bp].HVM_flags, not mask IVMF_NOTIFY_OWNER_ON_DIRTY
doUpdate:

EC<	call	VMCheckStrucs						>
EC<	call	ECMemVerifyHeap						>

	mov	dx, ds
	mov_tr	di, ax				;di <- return code (1-b i)
	pop	ax				;al = real VMH_attributes

	xchg	al, ds:[VMH_attributes]		;pass real attributes in the
						;header, save temp attributes
						;in al

	push	ax
	push	di

;	If, for some reason, a block could not be written out, don't update
;	the header, as the file is not in a consistent state - atw 5/20/96

	tst	di
	jnz	skipHeaderUpdate
	call	VMUpdateHeader			;func(ds, bx, si, es), dest di
skipHeaderUpdate:
	pop	di				;di <- saved return code
	jnc	noHeaderError			;if error then return error code
						;from writing the header

	; get rid of saved attributes since we are returning an error now...

	xchg	ax, di
	ornf	es:[bp].HVM_flags, mask IVMF_FILE_MODIFIED
	jmp	common

noHeaderError:

	; no error on header -- any in the body of the file?

	tst	di
	jnz	common				;error in body, so don't loop
						;back

	; no error on header or body -- did we compress the file ?

	test	es:[bp].HVM_flags, mask IVMF_FILE_MODIFIED
	jz  	common
	
	; yes -- restore temp attributes and loop

	pop	ax
	xchg	al, ds:[VMH_attributes]
	push	ax
	jmp	redo

common:
	pop	ax
	xchg	al, ds:[VMH_attributes]

	xchg	ax, di
	tst	ax				;did all those other blocks
						; get written ok?
	jz	done
	stc

done:

	; if the file is in backup mode then we don't want to set the
	; NOTIFY_DIRTY flag (since the file is still dirty from the user's
	; perspective)

	jc	noSpecialDirtyCheck
	test	ds:[VMH_attributes], mask VMA_BACKUP
	jz	noSpecialDirtyCheck
	and	es:[bp].HVM_flags, not mask IVMF_NOTIFY_OWNER_ON_DIRTY
							;clears the carry
noSpecialDirtyCheck:

	; if this is not a block-level accessed file then up the change
	; counter (even if there was an error)

	pushf
	push	ax, dx

if not FLOPPY_BASED_DOCUMENTS
	test	es:[bp].HVM_flags, mask IVMF_BLOCK_LEVEL_SYNC
	jnz	noCounter
	inc	es:[bp].HVM_refCount
	mov	ax, es:[bp].HVM_refCount
	mov	dx, offset VMFH_updateCounter
	call	VMFileWriteWord
	mov	ax, VMO_READ
	mov	dx, offset VMFH_updateType
	call	VMFileWriteWord
noCounter:
endif

	clr	ax				;allow errors
	call	FileCommit
	pop	ax, dx
	popf

releaseExtraLock:
	call	VMReleaseExtraDiskLock

;	We probably have made some blocks discardable, so check if we should
;	biff any to keep under the handle limit.

	call	VMEnforceHandleLimit
reallyDone:
EC<	call	VMCheckFileHandle					>
EC<	call	VMCheckStrucs						>
EC<	call	ECMemVerifyHeap						>


	.leave
	ret

VMUpdateLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMUpdateCheckForZombies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle ZOMBIEs specially so that VMDiscardWithDirtyBlocks
		will work.

CALLED BY:	VMUpdateLow
PASS:		ds	- segment of VMHeader
		si	- handle of VMHeader

RETURN:		carry set if couldn't update all
DESTROYED:	

PSEUDO CODE/STRATEGY:
	for all zombies:
		if backup(zombie)
			if filespace(zombie)
				transfer filespace to an unassigned block,
				assign and coalesce it
			endif
		else
			if VMA_BACKUP set
				create backup block, mark it ZOMBIE
				(original ZOMBIE is marked as DUP with backup)
			else
				VMFreeBlkHandle
			endif
		endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMUpdateCheckForZombies		proc	near
	uses	bp
	.enter

EC<	call	VMCheckStrucs						>
		
	mov	di, VMH_blockTable

zombieLoop:
EC<	call	VMCheckHeaderHandle					>
	call	VMGetNextInUseBlkFar		;di <- next in use
	jnc	nextBlock

	clc					;success
exit:
EC<	call	VMCheckStrucs						>
	.leave
	ret

nextBlock:		
	cmp	ds:[di].VMBH_sig, VMBT_ZOMBIE
	jne	zombieLoop			;loop if not
    	test	ds:[di].VMBH_flags, mask VMBF_HAS_BACKUP
	jnz  	hasBackup
	;
	; If not in backup mode, just free the zombie.
	;
	test	ds:[VMH_attributes], mask VMA_BACKUP
	jnz	createBackup		
	call	VMFreeBlkHandle
	jmp	zombieLoop		

createBackup:		
	;
	; VMBackupBlockIfNeededFar is fatal if we are not in VMA_SYNC_UPDATE
	; and there are no unassigned blocks, so ensure we have an available
	; block beforehand (I'm not sure why VMBackupBlockIfNeededFar doesn't
	; allow the block table to be extended, we know we can do it here
	; since VMGetUnassignedBlk at the hasBackup: label also does it)
	; -- brianc 3/2/00
	;
	test	ds:[VMH_attributes], mask VMA_SYNC_UPDATE
	jnz	gotBackup
	tst	ds:[VMH_numUnassigned]
	jnz	gotBackup
extendForBackup::
	mov	ax, 1
	call	VMExtendBlkTable
	jc	exit				; error if couldn't extend
gotBackup:
	;
	; Allocate an unassigned block and copy this block's data to it.
	; The new block is marked as BACKUP, and this one as DUP with
	; VMBF_HAS_BACKUP set.  We need to change it back to a ZOMBIE.
	;
	push	si				; save header handle
	call	VMBackupBlockIfNeededFar 	; di <- new, si <- old handle
	mov	di, si
	mov	ds:[di].VMBH_sig, VMBT_ZOMBIE
	pop	si
	jmp	zombieLoop

hasBackup:
	;
	; If this zombie has filespace, free it so that if 
	; VMDiscardDirtyBlocks is called, it won't be turned into
	; a DUP block.  
	;
	tst	ds:[di].VMBH_fileSize
	jz	zombieLoop

	push	si, di				; save header and blk handle
	push	di				; save old handle
	call	VMGetUnassignedBlk		; di <- unassigned block
	pop	si				; si <- zombie block
	;
	; Transfer the zombie's fileSize and filePos to the new block,
	; and assign it.
	;
	mov	ax, ds:[si].VMBH_filePos.low
	mov	ds:[di].VMFBH_filePos.low, ax
	mov	ax, ds:[si].VMBH_filePos.high
	mov	ds:[di].VMFBH_filePos.high, ax

	mov	ax, ds:[si].VMBH_fileSize
	mov	ds:[di].VMFBH_fileSize.low, ax
	mov	ds:[di].VMFBH_fileSize.high, 0
	sub	ds:[VMH_usedSize.low], ax	; reduce the usedSize by
	sbb	ds:[VMH_usedSize.high], 0	;   the appropriate amount
EC <	ERROR_B	GASP_CHOKE_WHEEZE					>
	;
	; Now clear the fileSize and filePos from the zombie.
	;
	clr	ax			
	mov	ds:[si].VMBH_fileSize, ax
	mov	ds:[si].VMBH_filePos.low, ax
	mov	ds:[si].VMBH_filePos.high, ax
	;
	; Add the new block to the assigned list, and coalesce it
	; with its neighbors, if possible.
	;
	call	VMAssignBlk			;add it to the assigned list
	push	ds:[di].VMFBH_nextPtr		;save next
	mov	bp, di				; bp <- following block
	mov	di, ds:[bp].VMFBH_prevPtr	; di <- preceding block
	call	VMCoalesceIfPossible		;combine if possible. restores
						; di for us.
	pop	bp				; bp <- following block
	call	VMCoalesceIfPossible		;combine if possible. 

EC<	call	VMCheckStrucs						>

	pop	si, di				; restore header and blk handle
	jmp	zombieLoop

VMUpdateCheckForZombies		endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckWritable

DESCRIPTION:	Checks to see if the update will be entirely successful,
		ie the file will be written out in its entirety.  This
		may entail compressing the file.

CALLED BY:	INTERNAL (VMUpdateLow)

PASS:		bx - VM file handle

RETURN:		carry clear if writable

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	cx:bp <- 0
	for all dirty blocks
		cx:bp <- cx:bp + (mem size - file size)
	end for
	if cx:bp > 0 then
		writable <- extend file size by bp (worst case)
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@
if 0	;No longer used - ardeb
VMCheckWritable	proc	near
ife VM_CHECK_WRITABLE
	clc			; assume write will succeed
else
EC<	call	VMCheckFileHandle					>
	call	EnterVMFile
EC<	call	VMCheckDSHeader						>
EC<	call	AssertESKdata						>

	push	ax, cx, dx, di, si, bp
	push	bx				;save VM file handle

	call	GetFileSize			;dx.ax <- filesize
	pushdw	dxax				;save filesize

	clr	cx				;cx:bp <- difference between
	clr	bp				; memory and file sizes

	mov	di, VMH_blockTable		;start at first block

VMCW_loop:
	call	VMGetNextUsedBlk		;es:di <- next used
	jc	doneCounting		;branch if no more

	mov	bx, ds:[di].VMBH_memHandle	;else get mem handle
	tst	bx				;in memory?
	je	VMCW_loop			;on to next if not

	test	es:[bx][HM_flags], mask HF_DISCARDABLE	;dirty?
	jne	VMCW_loop			;on to next if not

	push	cx
	mov	ax, es:[bx][HM_size]		;blks are < 65536 bytes
	call	ParaToByteAX 			;ax <- mem size
	pop	cx

	sub	ax, ds:[di].VMBH_fileSize	;ax <- (mem size-file size)

	add	bp, ax
	adc	cx, 0
	jmp	short VMCW_loop

doneCounting:
	push	cx
	or	cx, bp				;non zero?
	pop	cx
	jne	doCheck			;branch if so

	tst	cx				;blks in mem > blks on disk?
	jns	doCheck			;branch if so

	clc					;else file is writable for sure
	jmp	short done

doCheck:
;	clc					;to get around bug
;	ret

	;-----------------------------------------------------------------------
	;size of VM blocks in memory exceed corresponding ones on disk
	; => VM file size will be increased => writable/not writable
	; check needs to be performed

	mov	al, FILE_POS_END
	pop	bx				;retrieve VM file handle
	push	bx				;replace on stack

	push	cx
	clr	cx
	clr	dx
EC<	call	VMCheckFileHandle					>
	call	FilePos				;dx:ax <- size of file
	pop	cx
EC<	jnc	VMCW_10							>
EC<	ERROR	VM_ERR							>
EC< VMCW_10:								>

EC<	call	VMCheckHeaderHandle					>
	call	VMGetUnassignedBlkNoExtend	;es:di <- func(si,es)

	add	ax, 1				; inc setteth not the carry
	adc	dx, 0
	mov	ds:[di].VMFBH_filePos.low, ax
	mov	ds:[di].VMFBH_filePos.high, dx
	sub	ax, 1				; ditto for dec
	sbb	dx, 0

	;64K limit to extension right now!
	;need to write loop to allocate handles in the case of blk > 64K

;XXXX: USE DWORD fileSize NOW AVAILABLE
	mov	word ptr es:[di].VMFBH_fileSize, bp
	call	VMFreeBlkHandle			;func(es:di)

	add	ax, bp				;dx:ax <- potential last byte
	adc	dx, cx

	mov	cx, dx
	mov	dx, ax
	mov	al, FILE_POS_START
EC<	call	VMCheckFileHandle					>
	call	FilePos				;dx:ax <- func(al,bx,cx:dx)
EC<	jnc	VMCW_20							>
EC<	ERROR	VM_ERR							>
EC< VMCW_20:								>

	mov	al, FILE_NO_ERRORS
	mov	cx, 1				;specify 1 byte
	mov	dx, offset ds:[vmInitHeader]	;just ensure that ds:dx does
						;not point to a read-sensitive
						;location
	call	FileWrite			;func(al,bx,cx,ds:dx)

	jnc	done				;branch if no error

	;
	; Added, 6/22/95 -jw
	;
	; Some versions of DOS will screw up when saving the file-size
	; out to the disk. The problem is that in some versions of
	; DOS, the call to FilePos() changes the concept of how large
	; the file is, even though the file can't actually be that
	; large.
	;
	; By calling FileTruncate() with the original size, we force
	; the file-size back to what it ought to be.
	;
	; We can ignore errors here because truncating the file to
	; it's original size should never produce an error.
	;
	popdw	cxdx			; cxdx <- old size
	pushdw	cxdx			; need stuff on the stack for later
	mov	al, FILE_NO_ERRORS
	; bx already holds the file handle
	call	FileTruncate		; Nukes ax, cx, dx
	
	stc				; signal an error

IF	0	;***************************************************************
	jnc	done		;branch if write will be successful

	;file won't fit in the worst case
	;check to see if compression will help

	add	bp, es:[VMH_usedSize.low]
	adc	si, es:[VMH_usedSize.high]

	mov	al, FILE_POS_START
	pop	bx			;retrieve VM file handle
	push	bx
	mov	dx, bp
	mov	cx, si
	dec	dx			;dec cx:dx
	sbb	cx, 0
	call	FilePos
EC<	jnc	VMCW_30							>
EC<	ERROR	VM_ERR							>
EC< VMCW_30:								>

	mov	al, FILE_NO_ERRORS
	mov	cx, 1
	lea	dx, ds:[fileList]	;just ensure that ds:dx does not
					; point to a read-sensitive location
	call	FileWrite
ENDIF	;***********************************************************************

done:
	call	ExitVMFile
	
	popdw	dxax				;must preserve flags
	pop	bx
	pop	ax, cx, dx, di, si, bp
endif ; VM_CHECK_WRITABLE
	ret
VMCheckWritable	endp
endif

VMHigh	ends


kcode	segment	resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMPreLoadBlocks

DESCRIPTION:	Load a bunch of blocks at the beginning of a VM file, 
		until the amount of blocks loaded exceeds the threshold
		passed.

CALLED BY:	EXTERNAL

PASS:		bx - VM file handle
		dx.cx -- byte threshold, for how much to PreLoad.

RETURN:		dx.cx - amount loaded in

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	cx:bp <- 0
	for all dirty blocks
		cx:bp <- cx:bp + (mem size - file size)
	end for

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	11/17/93	Initial version

-------------------------------------------------------------------------------@

if	0 	;not needed, we'll just fault in everything.  cbh 1/ 7/94

VMPreLoadBlocks	proc	far		uses	ax, bx, bp, si, di, ds, es
	.enter

	LoadVarSeg	es

	pushdw	dxcx				;save threshold for end
	
	mov	bp, cx
	mov	cx, dx				;running total in cx.bp

	push	bp
EC<	call	VMCheckFileHandle					>
	call	EnterVMFileFar
EC<	call	VMCheckDSHeader						>
EC<	call	AssertESKdata						>
	pop	bp
	
	push	bx				;save VM file handle
	mov	di, VMH_blockTable		;start at first block

VMCW_loop:
	call	VMGetNextUsedBlk		;es:di <- next used
	jc	doneCounting			;branch if no more

	mov	bx, ds:[di].VMBH_memHandle	;else get mem handle
	tst	bx				;in memory?
	jne	VMCW_count			;on to next if so

	;
	; lock and unlock block here...
	;
	pop	bx				;VM file handle
	push	bx
	push	bp, ax
	mov	ax, di				;ax <- VM block handle
	call	VMLock
	call	VMUnlock
	pop	bp, ax

VMCW_count:
	push	cx
	mov	ax, es:[bx][HM_size]		;blks are < 65536 bytes
	mov	cl,4			;shift left four times to multiply by
	shl	ax,cl			;16 to get number of bytes
	mov	cx,ax
	pop	cx

	sub	bp, ax
	sbb	cx, 0
	js	doneCounting			;running threshold is acting
						;  negative, so let's go home.
	jmp	short VMCW_loop

doneCounting:
	pop	bx
	call	ExitVMFileFar

	;
	; Our running (now negative) threshold in cx.bp, we'll create
	; a total amount loaded (passedThreshold - runningThreshold)
	;
	popdw	dxcx				;passed threshold
	subdw	dxcx, cxbp	
	.leave
	ret
VMPreLoadBlocks	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	VMPush_EnterVMFile

DESCRIPTION:	Do common enter code for VM routines

CALLED BY:	INTERNAL

PASS:
	bx - VM file handle

RETURN:
	VM handle grabbed
	es - idata seg
	bp - VM handle
	si - VM header handle
	ds - VM header

	on stack (pushed in this order):
		si, bx, cx, dx, di, bp, ds, es
	order is encoded in VMPOEStack if original registers are needed.

DESTROYED:
	di (VMPush_EnterVMFileFar)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
VMPush_EnterVMFileFar	proc	far
	call	VMPush_EnterVMFile
	mov	di, sp
	jmp	ss:[di].VMPOESF_ret
VMPush_EnterVMFileFar	endp

VMPush_EnterVMFile	proc	near
EC <	call	FarCheckDS_ES						>
	XchgTopStack	si	; Save SI and fetch return address
	push	bx, cx, dx, di, bp, ds, es
	push	si		; Push ret addr back since EnterVMFile sets si

	call	EnterVMFile
EC <	call	VMCheckStrucs						>

	ret
VMPush_EnterVMFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMAddExtraDiskLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an extra disk lock to the disk that holds a VM file
		to prevent extra commits from happening during this
		update/save/revert. Leaves the FSIR and the disk locked
		for shared access (not supposed to unlock the FSIR while
		holding a disk & drive shared, ya know...)

CALLED BY:	(INTERNAL) VMSaveRevertCommon, VMUpdateLow
PASS:		bx	= VM file handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	FSIR, disk and drive all locked for shared access

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMAddExtraDiskLock proc	far
		uses	es, si, ax, bp
		.enter
		segmov	es, dgroup, si
EC <		call	ECCheckFileHandle				>
		mov	si, es:[bx].HF_disk
		call	FileLockInfoSharedToES
		mov	al, FILE_NO_ERRORS
		call	DiskLockFar
		.leave
		ret
VMAddExtraDiskLock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMReleaseExtraDiskLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the extra lock added by VMAddExtraDiskLock

CALLED BY:	(INTERNAL) VMPop_ExitVMFileFar_ReleaseExtraDiskLock,
			   VMUpdateLow
PASS:		bx	= VM file handle
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	FSIR and disk are unlocked

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMReleaseExtraDiskLock proc	far
		uses	es, si, ax, bp
		.enter
		pushf
EC <		call	ECCheckFileHandle				>
		segmov	es, dgroup, si
		mov	si, es:[bx].HF_disk
		call	FSDDerefInfo
		mov	es, ax
		call	DiskUnlockFar
		call	FSDUnlockInfoShared
		popf
		.leave
		ret
VMReleaseExtraDiskLock endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VMPop_ExitVMFile

DESCRIPTION:	Do common enter code for VM routines

CALLED BY:	INTERNAL -- SPECIAL: This routine must be jumped to!

PASS:
	bx - VM file handle
	es - idata
	ds - VM header block
RETURN:
	popped:
		si, bx, cx, dx, di, bp, ds, es

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
VMPop_ExitVMFileFar_ReleaseExtraDiskLock proc far jmp
	; Use the fptr left holding the return address for
	; VMPush_EnterVMFileFar to point to our continuation, where we'll
	; release the disk lock and return to our caller's caller

	mov	si, sp
	mov	ss:[si].VMPOESF_ret.offset, offset releaseLock
	mov	ss:[si].VMPOESF_ret.segment, cs
	jmp	VMPop_ExitVMFile

releaseLock:
	call	VMReleaseExtraDiskLock
	ret			; return to the caller of the caller of
				;  VMPush_EnterVMFileFar
VMPop_ExitVMFileFar_ReleaseExtraDiskLock endp

VMPop_ExitVMFileFar	proc	far jmp
	; Use the fptr left holding the return address for
	; VMPush_EnterVMFileFar to point to a far return (our standard
	; far return for the kernel) to return to our caller's caller.

	mov	si, sp
	mov	ss:[si].VMPOESF_ret.offset, offset FarRet
	mov	ss:[si].VMPOESF_ret.segment, segment FarRet
	REAL_FALL_THRU	VMPop_ExitVMFile
VMPop_ExitVMFileFar	endp

VMPop_ExitVMFile	proc	far jmp
				on_stack es ds bp di dx cx bx si retf

EC <	call	VMCheckStrucs						>

	call	ExitVMFile

VMPop_NoExitVMFile	label 	far
	pop	si, bx, cx, dx, di, bp, ds, es
				on_stack	retf
EC <	call	NullSegmentRegisters					>
FarRet	label	far
	ret

VMPop_ExitVMFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification to the owners of all file handles open
		to this VM file that the file has just become dirty.

CALLED BY:	VMDirty, SetHandleLow, VMAlloc
PASS:		es	= idata
		bx	= memory handle or file handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Snag the vmSem so VMOpen/VMClose block and our world remains
			consistent
		Search the file list for all handles referencing the same file
			as that referenced by the HVM_fileHandle.
		For each file handle found, queue a MSG_META_VM_FILE_DIRTY for
			that handle's owner
		Since FileFindDuplicate won't return HVM_fileHandle, send
			notification to that handle's owner too.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyDirtyFar	proc	far
		call	NotifyDirty
		ret
NotifyDirtyFar	endp

MAX_NOTIFICATIONS	= 20

NotifyDirty	proc	near
EC <		call	AssertESKdata					>
	;
	; For speed reasons we want to test quickly to see if we need to
	; do any modifications.
	;
		push	bx
		cmp	es:[bx].HG_type, SIG_FILE
		jz	filePassed
EC <		xchg	bx, si						>
EC <		call	VMCheckMemHandle				>
EC <		xchg	bx, si						>
		mov	bx, es:[bx].HM_owner		;bx = HandleVM
		jmp	common
filePassed:
EC <		call	VMCheckFileHandle				>
		mov	bx, es:[bx].HF_otherInfo	;bx = HandleVM
common:

		or	es:[bx].HVM_flags, mask IVMF_FILE_MODIFIED
		INT_OFF
		test	es:[bx].HVM_flags, mask IVMF_NOTIFY_OWNER_ON_DIRTY
		jz	exit
		and	es:[bx].HVM_flags, not mask IVMF_NOTIFY_OWNER_ON_DIRTY
		INT_ON

		call	PushAll
		sub	sp, MAX_NOTIFICATIONS*2
		mov	bp, sp			;ss:bp = list
		clr	di			;si = file count
		segmov	ds, es
	;
	; If the file uses block level syncronization then we need to find
	; all instances of this file being open and notify them all.
	; If the file does not use block level syncronization then the
	; files are independent and we only send notification for the file
	; being dirtied
	;
		call	PvmSem		; So no-one can close one of these
					;  things while we're searching
		test	es:[bx].HVM_flags, mask IVMF_BLOCK_LEVEL_SYNC
		mov	bx, es:[bx].HVM_fileHandle
		jz	notifyLast
		clr	si		; Start from head of list
searchLoop:
		call	VMFindOtherOpen
		jnc	notifyLast

		; add handle to list

		call	AddToModifyDirtyList

		jmp	searchLoop
notifyLast:
		mov	si, bx
		call	AddToModifyDirtyList
		call	VvmSem

		; loop to send notifications

sendNotificationLoop:
		tst	di
		jz	notificationsDone
		dec	di
		dec	di
		push	di
		mov	bx, ss:[bp][di]
		mov	cx, bx				;cx = file handle
		mov	bx, ds:[bx].HF_owner		;bx = owner
		mov	ax, MSG_META_VM_FILE_DIRTY
		clr	di
		call	ObjMessageNear
		pop	di
		jmp	sendNotificationLoop
notificationsDone:

		add	sp, MAX_NOTIFICATIONS*2
		call	PopAll
exit:
		INT_ON
		pop	bx
		ret
NotifyDirty	endp

;---

AddToModifyDirtyList	proc	near
		cmp	di, MAX_NOTIFICATIONS*2
		jz	dontAdd
		mov	ss:[bp][di], si
		inc	di
		inc	di
dontAdd:
		ret
AddToModifyDirtyList	endp

kcode	ends

VMOpenCode	segment	resource






COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetDirtySize

DESCRIPTION:	Adds up the size of the dirty blocks in the VM file.

CALLED BY:	EXTERNAL

PASS:		bx - VM file handle

RETURN:		dx.cx - size of dirty portion of VM file

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	cx:bp <- 0
	for all dirty blocks
		cx:bp <- cx:bp + (mem size - file size)
	end for

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	11/17/93	Initial version

-------------------------------------------------------------------------------@

VMGetDirtySize	proc	far

	clr	dx				;dirty blocks only
	call	VMGetDirtySizeCommon
	ret
VMGetDirtySize	endp



VMGetDirtySizeCommon	proc	near	

	uses	ax, bx, bp, si, di, ds, es
	;
	; Passed:
	;	bx -- VM file handle
	;	dl -- non-zero if we're to get all used blocks,
	;	      zero to return dirty blocks only
	;

	.enter
	LoadVarSeg	es

EC<	call	VMCheckFileHandle					>
	call	EnterVMFileFar
EC<	call	VMCheckDSHeader						>
EC<	call	AssertESKdata						>

	push	bx				;save VM file handle

	clr	cx				;cx:bp <- difference between
	clr	bp				; memory and file sizes

	mov	di, VMH_blockTable		;start at first block

VMCW_loop:
	call	VMGetNextUsedBlk		;es:di <- next used
	jc	doneCounting			;branch if no more

	mov	bx, ds:[di].VMBH_memHandle	;else get mem handle
	tst	bx				;in memory?
	je	VMCW_loop			;on to next if not

	tst	dl				;doing all used blocks?
	jnz	countBlock			;yes, count block

	test	es:[bx][HM_flags], mask HF_DISCARDABLE	;dirty?
	jne	VMCW_loop			;on to next if not

countBlock:
	push	cx
	mov	ax, es:[bx][HM_size]		;blks are < 65536 bytes
	mov	cl,4			;shift left four times to multiply by
	shl	ax,cl			;16 to get number of bytes
	mov	cx,ax
	pop	cx

	add	bp, ax
	adc	cx, 0
	jmp	short VMCW_loop

doneCounting:
	pop	bx
	call	ExitVMFileFar
	mov	dx, cx				;return in dx.cx to be pretty
	mov	cx, bp
	.leave
	ret
VMGetDirtySizeCommon	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetUsedSize

DESCRIPTION:	Gets size of used VM blocks in the VM file, by looking
		in the file header.

CALLED BY:	EXTERNAL

PASS:		bx - VM file handle

RETURN:		dx.cx - amount loaded in

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	1/25/94		Initial version

-------------------------------------------------------------------------------@

VMGetUsedSize	proc	far		

	mov	dl, 0ffh			;count all used & dirty blocks
	call	VMGetDirtySizeCommon
	ret
VMGetUsedSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMCheckDirtyOnOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with opening a VM file that's already open, sending
		out MSG_META_VM_FILE_DIRTY if dirty notification was requested
		for the file and the other geodes with the file open have
		already been notified.

CALLED BY:	VMOpen
PASS:		es	= idata
		bx	= file handle
		bp	= vm handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMCheckDirtyOnOpen proc	near	uses si
		.enter
		call	VMOpenCode_SwapESDS
		mov	si, bp
	;
	; See if notification has already been sent for the file. If not, we
	; don't need to either.
	;
		test	ds:[si].HVM_flags, mask IVMF_NOTIFY_OWNER_ON_DIRTY
		jnz	done
	;
	; See if the header for the file is in memory. If not, nothing can be
	; dirty so we don't need to notify.
	;
		INT_OFF
		mov	si, ds:[si].HVM_headerHandle
		tst	si
		jz	done
	;
	; See if dirty notification is enabled for the file now we know the
	; header's in-core.
	;
		push	ds
		mov	ds, ds:[si].HM_addr
		test	ds:[VMH_attributes], mask VMA_NOTIFY_DIRTY
		pop	ds
		INT_ON
		jz	done
	;
	; Notify opener that the file is dirty.  We must use the queue here,
	; even though we normally do not, we have not returned the file handle
	; yet (so nobody outside of the kernel knows what it is).
	;
		push	ax, bx, cx, di
		mov	ax, MSG_META_VM_FILE_DIRTY
		mov	cx, bx			; cx = file handle
		mov	bx, ds:[bx].HF_owner	; bx = owner
		mov	di, mask MF_INSERT_AT_FRONT or mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	ax, bx, cx, di
done:
		INT_ON
		call	VMOpenCode_SwapESDS
		.leave
		ret
VMCheckDirtyOnOpen endp

VMOpenCode	ends

VMSaveRevertCode	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a block to a new file, allocating the same VM
		block handle in the new file.

CALLED BY:	VMSaveAs
PASS:		ds:di	= VMBlockHandle whose data are to be transfered
		si	= HandleVM of source file (grabbed/entered)
		bx	= HandleVM of dest file (grabbed/entered)
		es	= idata
RETURN:		carry set if couldn't transfer
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTransfer	proc	near	uses ds, si
		.enter
	;
	; First allocate the handle in the destination file.
	;
		mov	ax, ds:[di].VMBH_uid
		mov	cl, ds:[di].VMBH_flags
		call	VMAllocThis
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>
	;
	; See if the source block is already in memory.
	;
		mov	ax, ds:[di].VMBH_memHandle
		tst	ax
		jz	nonResident

		xchg	ax, bx
		test	es:[bx].HM_flags, mask HF_DISCARDED
		xchg	ax, bx
		jnz	nonResidentButCopyHandle
	;
	; Yup. We just need to detach the block from the source and add it
	; to the destination.
	;
		dec	ds:[VMH_numResident]		; Detach from source
		mov	ds:[di].VMBH_memHandle, 0
		
		mov	si, es:[bx].HVM_headerHandle	; ds = dest header
		mov	ds, es:[si].HM_addr
		
EC <		tst	ds:[di].VMBH_memHandle				>
EC <		ERROR_NZ	GASP_CHOKE_WHEEZE			>

		mov	ds:[di].VMBH_memHandle, ax	; Attach to dest
		inc	ds:[VMH_numResident]
		xchg	ax, si
		
		mov	es:[si].HM_owner, bx		; Switch owner to dest
		andnf	es:[si].HM_flags, 		;  and mark block dirty
				not mask HF_DISCARDABLE	;  (clears carry)

done:
		.leave
		ret

nonResidentButCopyHandle:
	;
	; Handle is discarded, meaning PRESERVE_HANDLE is set for the source,
	; so we need to copy the handle ID to the destination file and remove
	; it from the source, leaving the sucker discarded.
	;
		push	ds, si				; Preserve source header
		mov	ds:[di].VMBH_memHandle, 0	; Detach from source
		mov	si, es:[bx].HVM_headerHandle	; ds = dest header
		mov	ds, es:[si].HM_addr
		mov	ds:[di].VMBH_memHandle, ax	; Attach to dest
		xchg	ax, si
		mov	es:[si].HM_owner, bx		; Switch owner to dest
		xchg	ax, si
		pop	ds, si
nonResident:
	;
	; Yuck. The block isn't in memory. The easy way out of this is to just
	; load the block in and attach it to the destination. Sadly, that could
	; have some adverse effects should the file be large. So instead, as for
	; compaction, we want to transfer the block directly over (without
	; any relocation or anything).
	;
		push	bx, si, ds, di
		mov	cl, ds:[di].VMBH_flags		; cl = block flags
		andnf	cl, not mask VMBF_HAS_BACKUP	; no backup here

		mov	ax, ds:[di].VMBH_fileSize	; ax = size needed
		mov	si, es:[bx].HVM_headerHandle	; si = header handle of
							;  dest
		mov	bx, es:[bx].HVM_fileHandle	; bx = file handle of
							;  dest
		mov	ds, es:[si].HM_addr		; ds = header segment of
							;  dest
		mov	ds:[di].VMBH_flags, cl		; preserve flags from
							;  original block
						; Allocate enough space in the
		call	VMUseBlk		;  dest with VMUseBlk. Gives
						;  back a block handle in the
		call	VMUnassignBlk		;  dest for which we have no
						;  use, so just free it again,
						;  keeping hold of the position
		dec	ds:[VMH_numUsed]	;  of the space allocated
		
		pop	di
		mov	ds:[di].VMBH_filePos.low, dx	; Set position of dest
		mov	ds:[di].VMBH_filePos.high, cx
		mov	ds:[di].VMBH_fileSize, ax	; record file size of
							;  dest (ax untouched by
							;  VMUseBlk and
							;  VMUnassignBlk)
		add	ds:[VMH_usedSize].low, ax	; do this here since
		adc	ds:[VMH_usedSize].high, 0	;  we're not using
							;  VMDoWriteBlk to
							;  alloc space in the
							;  dest...

		pop	si, ds
	;
	; Perform the actual transfer to the destination file.
	;
		call	VMCopyNonRes		; nukes ax, si
		pop	bx
		jmp	done
VMTransfer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMCopyNonRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a non-resident block from one file and copy it to
		a new position in a possibly different file.

CALLED BY:	VMTransfer, VMDoCompress
PASS:		ds:di	= VMBlockHandle of block at old position
		si	= HandleVM of source file (grabbed/entered)
		bx	= file handle of dest file
		cx:dx	= position to which to write the block
		es	= idata
RETURN:		carry set on error
DESTROYED:	si, ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMCopyNonRes	proc	far	uses bp, ds
		.enter
		mov	ax, ds:[di].VMBH_fileSize
		push	ax
		push	bx, cx, dx		; Save dest position & handle
						;  until we need it
	;
	; Allocate memory for the block.
	;
		mov	cx, mask HAF_LOCK shl 8	; Lock block initially, so
						;  it doesn't get swapped
		mov	bx, es:[si].HVM_fileHandle
		call	VMGetMemSpaceAndSetOtherInfo

		mov	bp, si			; bp <- mem block
		mov	si, es:[si].HM_addr	; si <- segment (block locked)
	;
	; Now read the block into memory.
	;
		mov	cx, ds:[di].VMBH_filePos.high
		mov	dx, ds:[di].VMBH_filePos.low
		call	VMReadBlkLow		; DOESN'T RETURN AN ERROR
	;
	; Now write it to the destination file.
	;
		pop	bx, cx, dx		; recover destination pos &
						;  handle

		mov	al, FILE_POS_START
		call	FilePosFar

		pop	cx			; cx <- # bytes

		push	dx, ax			; preserve file pos for final
						;  pop

		mov	ds, si				; ds:dx = buffer
		clr	dx
		clr	al				; give me errors
		call	FileWriteFar
	;
	; Free the buffer block, since we need it no longer.
	;
		pushf			; preserve any error from FileWrite
		xchg	bx, bp
EC <		push	ax, ds						>
EC <		LoadVarSeg	ds					>
EC <		mov	ax, ss:[TPD_processHandle]			>
EC <		mov	ds:[bx].HM_owner, ax				>
EC <		pop	ax, ds						>
EC <		call	MemUnlock	; don't try to free a locked VM block >
		call	MemFree
		mov	bx, bp
		popf
		pop	cx, dx
		.leave
		ret
VMCopyNonRes	endp
VMSaveRevertCode	ends

kcode	segment	resource

if 0 	; no longer used -- ardeb 3/23/92

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMRewind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rewind the passed file to its start

CALLED BY:	VMSetHeader, VMGetHeader, VMSaveAs...
PASS:		bx	= file handle
RETURN:		nothing
DESTROYED:	cx, dx, ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMRewind	proc	far
		.enter
		clr	cx
		mov	dx, cx
		mov	al, FILE_POS_START
		call	FilePos
		.leave
		ret
VMRewind	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFindOtherOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate another file handle open (in VM mode) to the same
		disk file.

CALLED BY:	VMOpen, VMDirty
PASS:		bx	= file handle, the duplicate of which is sought
		si	= handle after which to start searching, or 0
			  to search the entire list.
		vmSem grabbed.
RETURN:		si	= duplicate handle
		carry set if successful
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMFindOtherOpen	proc	far	uses di, ds
		.enter
		LoadVarSeg	ds
searchLoop:
		call	FileFindDuplicate
		jnc	done			; => no more
	;
	; Make sure the file is opened for VM access.
	;
		mov	di, ds:[si].HF_otherInfo
		tst	di
		jz	searchLoop
		cmp	ds:[di].HG_type, SIG_VM
		jne	searchLoop
		stc
done:
		.leave
		ret
VMFindOtherOpen	endp
kcode		ends
