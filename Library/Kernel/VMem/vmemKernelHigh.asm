COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VM Manager
FILE:		vmemKernelHigh.asm

AUTHOR:		Adam de Boor, Jan  2, 1990

ROUTINES:
	Name			Description
	----			-----------
    EXT	VMAlterExtraUnassigned	Adjust minimum number of unassigned handles
    				required by user of the file
    EXT VMAllocAndAttach	Allocate a VM block and give it the indicated
    				memory
    EXT	VMEmpty			Remove the memory from a VM block
    EXT	VMSetHandle		Change the memory handle for a VM block
    EXT	VMUpdateAndRidBlk	write blk to disk and remove it from memory
    EXT VMBlockBiffable		See if we can get rid of a VM memory block
    				for the heap code
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/ 2/90		Initial revision


DESCRIPTION:
	This file contains interface routines exported to the rest of the
	kernel, but not to geodes.
		

	$Id: vmemKernelHigh.asm,v 1.1 97/04/05 01:16:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode	segment	resource
if 	0	; no longer used -- ardeb 10/28/91
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMAlterExtraUnassigned

DESCRIPTION:	Adjust the minimum number of unassigned handles that must be
		available for crisis situations.

CALLED BY:	EXTERNAL

PASS:		bx - VM file handle
		ax - number of extra unassigned handles by which to increase/
		     decrease (signed number) the current total.  If 0 then
		     the desired number is set to 0
		(these 'extra' unassigned blocks will be in excess of the
		the unassigned blocks already present to maintain the
		2 unassigned blocks to 1 resident block ratio)

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/89		Initial version

-------------------------------------------------------------------------------@

VMAlterExtraUnassigned	proc	far
	call	VMPush_OverRide_EnterVMFile

	; set new total

	tst	ax
	jz	10$
	add	ax,ds:[VMH_numExtraUnassigned]
10$:
EC <	cmp	ax, 4000						>
EC <	ERROR_A	VM_UNASSIGNED_ADJUSTMENT_UNREASONABLE_YOU_PROBABLY_HAVE_A_DETACHABLE_READ_ONLY_LMEM_BLOCK_IN_YOUR_APPLICATION>

	mov	ds:[VMH_numExtraUnassigned],ax
	call	VMMarkHeaderDirty
	call	NotifyDirty

	call	VMMaintainExtraBlkHans				;func(es, si)

	jmp	VMPop_ExitVMFile

VMAlterExtraUnassigned	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMBlockBiffable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a VM block is a candidate for writing to its file

CALLED BY:	EXTERNAL (FindNOldest)
PASS:		ds	= idata
		bx	= memory handle of block in question
		bp	= vm handle owning the block
RETURN:		carry clear if we can write the thing out
DESTROYED:	

PSEUDO CODE/STRATEGY:
	The only VM block about which we have qualms is a VM header block,
	which we can only biff if none of the VM blocks it describes is
	actually in memory (except for itself, of course).	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMBlockBiffable	proc	near	uses bx, es, si, ax, dx
		.enter
		clr	dx			; block
		call	VMBlockBiffableLow
		jz	noRelease
; assume common case is not recursive, as it was NEVER recursive
; before tempasync stuff..
		pushf
		cmp	ds:[bx].HM_lockCount, 1
		jne	justRelease
		call	MemThreadRelease
		FastMemV1	ds, bp, MV_1, MV_2
afterRelease:
		popf
noRelease:
		.leave
		ret
justRelease:
		call	MemThreadRelease
		jmp	afterRelease

		FastMemV2	ds, bp, MV_1, MV_2
VMBlockBiffable	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMUpdateAndRidBlk

DESCRIPTION:	Write the block to disk (if necessary) and free it from memory.

CALLED BY:	EXTERNAL (ThrowOutOne, DoFullDiscard)

PASS:		heap semaphore down
		ds - idata seg
		bx - VM mem handle (with data address = 0)
		dx - data address
		bp - VM handle

RETURN:		carry set if block couldn't be nuked

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:
	assert used blk
	file size, file pos <- write blk to disk
	di <- VM block handle of blk
	free blk

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@


VMUpdateAndRidBlk	proc	far 	uses bx, dx, es, di, si
	.enter
	call	VMBlockBiffableLow
	jz	error
	jc	errorRelease

	mov	si, bx				;later code likes header in si

	cmp	ax, bx				;dealing with header?
	jne	doBlk				;branch if not

	;----------------------------------------------------------------------
	;discarding header, update file header on disk

	mov	bx, ds:[bp].HVM_fileHandle	;pass file handle in bx
	
	;
	; Turn off compression for the file. Compression would invoke bad
	; error-checking code, as well as try to allocate more memory,
	; which we can ill afford at this critical juncture.
	;
writeTheHeader:				;FOR DEBUGGING
	ForceRef	writeTheHeader

	call	SwapESDS
	push	{word}ds:[VMH_compressFlags]
	BitSet	ds:[VMH_compressFlags], VMCF_NO_COMPRESS
	call	VMUpdateHeader		;func(ds,bx,si,es,dx), destroys ax, di
	pop	{word}ds:[VMH_compressFlags]

swapWriteError:
	call	SwapESDS
	jc	writeError

	mov	ds:[bp].HVM_headerHandle, 0	;note absence of header
;
; since will die in DoFreeNoDeleteSwap if HM_lockCount not 0, we can
; assume we have the only lock on it here.. and always V the sema in
; the VM Handle
;	
EC<	call	VMCheckVMHandle						>
					; verify that bp is good VMHandle
	xchg	bp, bx
	call	HandleV
	xchg	bp, bx

EC <	dec	ds:[si].HM_lockCount	;avoid death in DoFreeNoDeleteSwap,>
					; unless header was locked before
					; we got here...
	mov	bx, si			;free header handle and block
	mov	di, offset DoFree	; Always free the header
	jmp	freeHandle

errorRelease:
	cmp	ds:[bx].HM_lockCount, 1	; if we are the last to
					; unlock, release the sema too.
	jne	continueErrorRelease
	call	MemThreadRelease
	xchg	bp, bx
	call	HandleV				; the VMHandle in bx
	xchg	bp, bx

error:
	stc
	jmp	done

continueErrorRelease:
	call	MemThreadRelease
	jmp	error

writeError:
	mov	ax, offset doNothingReturnError
	jmp	releaseHeader

doBlk:	
	;----------------------------------------------------------------------
	;discarding VM block
	call	SwapESDS
	call	VMGetBlkHandle			;di <- VMGetBlkHandle(ds, ax)

EC<	test	ds:[di].VMBH_sig, VM_IN_USE_BIT				>
EC<	ERROR_Z	VM_DISCARDING_NON_USED_BLOCK				>
EC<	cmp	ds:[di].VMBH_sig, VMBT_DUP				>
EC<	ERROR_B VM_DISCARDING_NON_USED_BLOCK				>

	mov	bx, es:[bp].HVM_fileHandle

	mov	bp, ax
	test	es:[bp][HM_flags], mask HF_DISCARDABLE		;dirty??
	jnz	notDirty		;branch if not
	
	;
	; Turn off compression for the file. Compression would invoke bad
	; error-checking code, as well as try to allocate more memory,
	; which we can ill afford at this critical juncture.
	;
	push	{word}ds:[VMH_compressFlags]
	BitSet	ds:[VMH_compressFlags], VMCF_NO_COMPRESS
	call	VMWriteBlk		;func(ds,es,bx,di,si,bp,dx)
	pop	{word}ds:[VMH_compressFlags]
	jc	swapWriteError

notDirty:
	dec	ds:VMH_numResident

if	IDLE_UPDATE_ASYNC_VM
	;
	; If not single-thread access, ask the scrub thread to update the
	; thing as soon as it can.
	;
	test	ds:[VMH_attributes], mask VMA_SINGLE_THREAD_ACCESS
	jnz	noIdleUpdate
	call	HeapMarkForIdleUpdate
noIdleUpdate:
endif	; IDLE_UPDATE_ASYNC_VM

	;
	; Always discard the block first while we've still got the header
	; block. This prevents ugly race conditions when something is going
	; for this block while we're biffing it (the other thing would come
	; in when we release the header and grab the sucker just before
	; we discard it...).
	;
	call	SwapESDS
	mov	bx, bp		; bx <- block handle
	call	DoDiscard

	mov	ax, offset doNothing		; Assume preserving
	test	es:[di].VMBH_flags, mask VMBF_PRESERVE_HANDLE
	jnz	releaseHeader

	mov	es:[di].VMBH_memHandle, 0	; Note no handle for block
	mov	ax, offset FreeHandle		; Still need to free the handle
	CheckHack	<segment FreeHandle eq @CurSeg>

releaseHeader:
	;
	; Release grab on the header handle now we're done with the block
	; and have zeroed the memHandle field.
	;
	xchg	ax, di		; di = function to call (1-byte inst)
	mov	bx, si		; bx <- header handle
EC<	call	VMCheckHeaderHandle			; in si		>

	cmp	ds:[bx].HM_lockCount, 1
	jnz	justRelease
	call	MemThreadRelease
	mov	bx, ds:[bx].HM_owner			; HandleVM in bx
	call	HandleV

continueRelease:
	mov	bx, bp		; Free block handle
freeHandle:

	; Can no longer by used since we don't zero out the data address
if	0
EC <	test	ds:[bx].HM_flags, mask HF_SWAPPED			>
EC <	jnz	okNoMem							>
EC <	tst	ds:[bx].HM_addr						>
EC <	ERROR_Z	GASP_CHOKE_WHEEZE					>
EC <okNoMem:								>
endif

	;
	; ds = idata, bx = block to nuke, di = function to call to nuke it
	;
	call	di

EC <	call	ECMemVerifyHeapLow					>
	clc
done:
EC <	call	AssertDSKdata						>
	.leave
	ret

justRelease:				; part of releaseHeader above,
	call	MemThreadRelease	; but rearranged for
	jmp	continueRelease		; common-case optimization

doNothingReturnError:
	stc				; Indicate error
	pop	di			; Nuke return address
	jmp	done			; Get out now

doNothing:
	retn

VMUpdateAndRidBlk	endp

kcode		ends


DBaseCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMMarkUngroupAvail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the VMBF_UNGROUP_AVAIL bit for a VM block

CALLED BY:	(EXTERNAL) DBItemFree
PASS:		ax	= VM block handle
		bx	= memory handle of same
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	the header is marked dirty when the VMBF_UNGROUPED_AVAIL flag
     			is set for the block.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMMarkUngroupAvail proc	far		; must be far to use VMPush_EnterVMFile
EC <		call	ECVMCheckMemHandle			>
	;
	; Fetch the standard file handle for the VM file that contains the
	; memory block.
	; 
		push	ds
		LoadVarSeg	ds
EC <		tst	ds:[bx].HM_lockCount			>
EC <		ERROR_Z	DB_UNGROUP_NOT_LOCKED			>

		mov	bx, ds:[bx].HM_owner
		mov	bx, ds:[bx].HVM_fileHandle
		pop	ds

		call	VMPush_EnterVMFileFar
		mov	di, ax
EC <		call	VMCheckUsedBlkHandle			>
		ornf	ds:[di].VMBH_flags, mask VMBF_UNGROUPED_AVAIL
		call	VMMarkHeaderDirty
		jmp	VMPop_ExitVMFileFar
VMMarkUngroupAvail endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFindAvailUngroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a VM block handle in the file that is marked as an
		available ungroup block.

CALLED BY:	(EXTERNAL) DBGroupNewUngrouped
PASS:		bx	= file handle
RETURN:		carry set if found an available block:
			ax	= VM block handle
		carry clear if no available block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMFindAvailUngroup proc	far		; must be far to use VMPush_EnterVMFile
		call	VMPush_EnterVMFileFar
		mov	di, offset VMH_blockTable
blockLoop:
		call	VMGetNextUsedBlk
		jc	done
		test	ds:[di].VMBH_flags, mask VMBF_UNGROUPED_AVAIL
		jz	blockLoop
	;
	; Found one. Clear the flag again, now that it's going to become
	; *the* ungrouped block, as we don't want to find this same block
	; when next we go searching.
	; 
		andnf	ds:[di].VMBH_flags, not mask VMBF_UNGROUPED_AVAIL
		call	VMMarkHeaderDirty
	;
	; Return its handle in AX.
	; 
		mov_tr	ax, di
done:
		cmc
		jmp	VMPop_ExitVMFileFar
VMFindAvailUngroup endp

DBaseCode	ends
