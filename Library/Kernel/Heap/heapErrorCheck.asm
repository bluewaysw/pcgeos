COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		heapErrorCheck.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------
	ECCheckMemHandle	Verify BX is a valid memory handle
	ECCheckMemHandleNS	Verify BX is a valid memory handle w/o
				worrying about sharing errors
	CheckHandleLegal	Verify handle ID is valid
EC ONLY:
	CheckLocked		Make sure handle isn't locked
	CheckToLock		Make sure lock count won't be exceeded.
				Calls ECCheckMemHandle
	CheckToLockNS		Make sure lock count won't be exceeded,
				but call ECCheckMemHandleNS.
	CheckToUnlock		Make sure handle is valid and locked
	CheckToUnlockNS		Same, but call ECCheckMemHandleNS to check
				handle validity.
	CheckDS_ES		Make sure DS and ES point into the heap
	ECCheckBounds
	AssertHeapMine		Make sure the heap is locked by the current
				thread.
	ECMemVerifyHeapLow	Make sure heap is consistent.

DESCRIPTION:
	This file contains error checking code for the heap

     	$Id: heapErrorCheck.asm,v 1.1 97/04/05 01:13:54 newdeal Exp $

-------------------------------------------------------------------------------@

kcode	segment
if	ERROR_CHECK
FarLoadVarSegDS	proc	far
	call	LoadVarSegDS
	ret
FarLoadVarSegDS	endp
endif	;ERROR_CHECK
kcode	ends

ECCode	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHandleLegal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed handle is reasonable. Doesn't check
		*type* of handle or anything, just the handle ID itself.

CALLED BY:	EXTERNAL/INTERNAL
PASS:		bx	= handle ID to check
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK

CheckHandleLegal	proc	far
	pushf
	push	ds
	call	FarLoadVarSegDS
	test	bl,00001111b		;make sure it's is on a 16 byte boundry
	jnz	illegalHandle

	cmp	bx, ds:[loaderVars].KLV_handleTableStart
	jb	illegalHandle
	cmp	bx,ds:[loaderVars].KLV_lastHandle ;make sure it's not too large
	jae	illegalHandle

	pop	ds
	popf
	ret

illegalHandle:
	ERROR	ILLEGAL_HANDLE

CheckHandleLegal	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckMemHandle

DESCRIPTION:	Check a memory handle for validity

CALLED BY:	GLOBAL

PASS:
	bx - memory handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


ECCheckMemHandleFar	proc	far
EC <	call	ECCheckMemHandle					>
	ret
ECCheckMemHandleFar	endp
	public	ECCheckMemHandleFar

if	ERROR_CHECK

ECCheckMemHandle	proc	near
	pushf
	push	ds
	LoadVarSeg	ds

HMA <	cmp	ds:[bx].HG_type, SIG_UNUSED_FF				>
HMA <	je	isMem							>

	cmp	ds:[bx].HG_type, SIG_NON_MEM
	ERROR_AE	NOT_MEM_HANDLE

HMA <isMem:								>

	call	ECCheckMemHandleNS

	test	ds:[sysECLevel], mask ECF_HIGH
	jz	done

	push	ax, si

	test	ds:[bx][HM_flags],mask HF_SHARABLE
	jnz	20$
	mov	ax,ss:[TPD_processHandle]
	cmp	ax, handle 0
	jz	20$
	mov	si,ds:[bx][HM_owner]
	cmp	ax,si
	jz	20$
	cmp	ds:[si].HG_type,SIG_VM
	ERROR_NZ	HANDLE_SHARING_ERROR
20$:
	pop	ax, si
done:
	pop	ds
	popf
	ret

ECCheckMemHandle	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckMemHandleNS

DESCRIPTION:	Check a memory handle for validity -- won't check for
		sharing violations

CALLED BY:	GLOBAL

PASS:
	bx - memory handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact (ints left in whatever state
		   they were in when routine was called)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


ECCheckMemHandleNSFar	proc	far
EC <	call	ECCheckMemHandleNS					>
	ret
ECCheckMemHandleNSFar	endp
	public	ECCheckMemHandleNSFar

if	ERROR_CHECK

ECCheckMemHandleNS	proc	near
	pushf
	push	ds
	LoadVarSeg	ds

	call	CheckHandleLegal

	cmp	ds:[bx][HM_owner],0
	ERROR_Z	HANDLE_FREE

HMA <	cmp	ds:[bx].HG_type, SIG_UNUSED_FF				>
HMA <	je	isMem							>

	cmp	ds:[bx].HG_type, SIG_NON_MEM
	ERROR_AE	ILLEGAL_HANDLE
HMA <isMem:								>

	test	ds:[sysECLevel], mask ECF_HIGH
	jz	done

	INT_OFF		; consistency 'R' us
	push	ax
	push	cx
	mov	ax,ds:[bx].HM_addr
	mov	cl,ds:[bx].HM_flags

	tst	ax
	jz	10$
	cmp	ax,ds:[loaderVars].KLV_heapStart	;check for bad address
	jb	illegalHandleData
	
	cmp	ax,ds:[loaderVars].KLV_heapEnd
if	 FULL_EXECUTE_IN_PLACE
    	jb	20$					;betw. start & end->OK

	; It is OK to have XIP resources above the end of the heap, as long
	; as they have non-zero lock counts.
	
	cmp	bx, LAST_XIP_RESOURCE_HANDLE
	ja	illegalHandleData			;not XIP handle
	tst	ds:[bx][HM_lockCount]
	jz	illegalHandleData			;handle count = 0..BAD

else	;FULL_EXECUTE_IN_PLACE is FALSE
	jae	illegalHandleData
	
endif	;FULL_EXECUTE_IN_PLACE

20$::
	test	cl,mask HF_DISCARDED or mask HF_SWAPPED
	ERROR_NZ	CORRUPTED_HEAP
	cmp	ds:[bx][HM_size],1000h
	ERROR_AE	BAD_PARA_SIZE
10$:
	pop	cx
	pop	ax

done:
	pop	ds
	call	SafePopf
	ret

illegalHandleData:
	ERROR	ILLEGAL_HANDLE_DATA

ECCheckMemHandleNS	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckBounds ECAssertValidFarPointerXIP

DESCRIPTION:	Verify that DS is a valid segment, and that SI is a
		valid offset in that segment.  If DS is an lmem block,
		verify that SI is inside a chunk in that block, or in
		the Header of that block.

CALLED BY:	GLOBAL

PASS:
	For ECCheckBounds:
	ds:si - pointer to check

	For ECAssertValidFarPointerXIP
	bx:si - vfptr to check (not passed in ds:si because could be vfptr)

	For ECAssertValidTrueFarPointerXIP
	bx:si - fptr to check (*cannot* be a vfptr)

RETURN:
	none (dies if assertion fails)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 9/91		Initial version

------------------------------------------------------------------------------@
if	ERROR_CHECK

if	FULL_EXECUTE_IN_PLACE
ECAssertValidTrueFarPointerXIP		proc	far
	pushf

;	Make sure that no virtual far pointers are passed in.	

HMA <	cmp	bx, HMA_SEGMENT			;check hi-mem segment	>
HMA <	je	realSegment						>
	cmp	bh, high MAX_SEGMENT
	ERROR_AE	ILLEGAL_SEGMENT
	
realSegment::
	popf
	FALL_THRU	ECAssertValidFarPointerXIP
ECAssertValidTrueFarPointerXIP		endp
endif
ECAssertValidFarPointerXIP		proc	far

FXIP <	pushf							>
FXIP <	push	ds, bx						>
FXIP <	LoadVarSeg	ds					>
FXIP <	sub	bx, ds:[loaderVars].KLV_mapPageAddr		>
FXIP <	jc	notXIP						>
FXIP <	cmp	bx, MAPPING_PAGE_SIZE/16			>
FXIP <	ERROR_B	FAR_POINTER_TO_MOVABLE_XIP_RESOURCE		>
notXIP::
FXIP <	pop	ds, bx						>
FXIP <	popf							>
	push	cx
	mov	cx, bx
	GOTO	ECCheckBoundsCommon, cx
ECAssertValidFarPointerXIP	endp


ECCheckBounds				proc	far
	push	cx
	call	CheckDS_ES
	mov	cx, ds
	FALL_THRU	ECCheckBoundsCommon, cx
ECCheckBounds	endp

ECCheckBoundsCommon			proc	far

;	Takes: CX:SI <- far ptr/virtual far ptr
	uses	ax, bx, ds, di
	.enter
	pushf
	push	cx			
	mov	ax, ss
	cmp	cx, ax
	jne	notInvalidStack
	cmp	si, ss:[TPD_stackBot]
	jb	notInvalidStack
	cmp	si, sp
	ERROR_B	INVALID_POINTER_INTO_STACK
	
notInvalidStack:
	call	MemSegmentToHandle
	ERROR_NC	ILLEGAL_SEGMENT

	mov	bx, cx
	LoadVarSeg	ds
	call	GetByteSizeFar		; ax, cx <- # bytes
	cmp	si, cx
	ERROR_AE	ADDRESS_OUT_OF_BOUNDS

	pop	ax				; ax = passed in segment
	
	test	ds:[sysECLevel], mask ECF_LMEM
	jz	done

	test	ds:[bx].HM_flags, mask HF_LMEM
	jz	done

	;
	; Make sure the offset points to an lmem chunk
	;
	mov	ds, ax
	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	done

	mov	cx, ds:[LMBH_nHandles]
	mov	bx, ds:[LMBH_offset]

	;
	; Allow the pointer to point within the lmem block header
	; (which for GStates and Windows may be the only data)
	;
	cmp	si, bx			; pointer into header?
	jb	done			; branch if so

startLoop:
	;
	; Added 10/19/94 -jw
	;
	; Allow pointers to the chunk handle, since that's a valid pointer.
	; vvvvvvvvvvvvvvvvvvvvvvvvvvvv

	cmp	si, bx			; pointer to chunk handle?
	jne	checkBounds		; if not, check the offset
	
	tst	{word}ds:[bx]		; Check for free chunk
	jnz	done			; If not free, pointer is valid
	
	ERROR	ADDRESS_OUT_OF_BOUNDS	; Otherwise die die die
	
checkBounds:
	; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	mov	di, ds:[bx]
	tst	di		; is chunk free?
	jz	next

	;
	; Added 11/10/94 - atw
	;
	; Allow pointers to the size word of a chunk (which comes before the 
	; data)
	;
	lea	di, ds:[di].LMC_size	;If the chunk is empty, DI will be
					; -3, so the following comparison
					; is still valid

	cmp	di, si
	ja	next		; SI is before this chunk, or chunk is
				; empty (di=-3)

	add	di, ds:[di]	; di <- after end of the chunk 
	cmp	di, si
	ja	done
next:
	add	bx, 2		; point to next handle
	loop	startLoop
	ERROR	ADDRESS_OUT_OF_BOUNDS
done:	
	popf
	.leave
	FALL_THRU_POP	cx
	ret
ECCheckBoundsCommon		endp

else
	;  The Non-EC stub.  Should never be called, but needed to
	;  keep the right kernel relocation numbers between EC and NONEC
ECAssertValidFarPointerXIP	proc	far
	FALL_THRU	ECCheckBounds
ECAssertValidFarPointerXIP	endp

ECCheckBounds		proc	far
		ret
ECCheckBounds		endp
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckSegment

DESCRIPTION:	Check a segment value for validity

CALLED BY:	GLOBAL

PASS:
	ax - segment value

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


NEC <ECCheckSegment	proc	far					>
NEC <	FALL_THRU	FarCheckDS_ES					>
NEC <ECCheckSegment	endp						>

NEC <FarCheckDS_ES	proc	far					>
NEC <	ret								>
NEC <FarCheckDS_ES	endp						>

if	ERROR_CHECK

ECCheckSegment	proc	far
	pushf

	cmp	ax, NULL_SEGMENT
	jz	done
	call	NullSeg
	cmp	ax, NULL_SEGMENT
	ERROR_Z	ILLEGAL_SEGMENT
done:
	popf
	ret

ECCheckSegment	endp

;-------------------------------------------------

CheckToLock	proc	far
	push	ax
	mov	ax, offset ECCheckMemHandle
	call	CheckToLockCommon
	pop	ax
	ret
CheckToLock	endp

CheckToLockNS	proc	far
	push	ax
	mov	ax, offset ECCheckMemHandleNS
	call	CheckToLockCommon
	pop	ax
	ret
CheckToLockNS	endp

CheckToLockCommon	proc	near
	pushf
	push	ds
	LoadVarSeg	ds
	call	ax
	test	ds:[bx].HM_flags, mask HF_FIXED
	jnz	tooManyLocks

	cmp	ds:[bx].HM_lockCount,MAX_LOCKS
	jae	tooManyLocks

	cmp	ds:[bx].HM_lockCount,MAX_LOCKS/2
	jae	lotsOfLocks
keepGoing:

	pop	ds

	;
	; Do not do this if interrupts are currently off -- it can cause
	; interrupts to be turned on and lead to much unhappiness.
	; 				-- ardeb 11/8/95
	;
	push	bp
	mov	bp, sp
	test	{CPUFlags}ss:[bp+2], mask CPU_INTERRUPT
	jz	dsEsDone
	call	CheckDS_ES
dsEsDone:
	pop	bp

	call	SafePopf
	ret

lotsOfLocks:
	;
	; This label exists only to allow one to set a breakpoint and 
	; possibly catch places where the lock count of a block is getting
	; large, before it achieves critical death status later on...
	;
	jmp	keepGoing
CheckToLockCommon	endp

tooManyLocks:
	ERROR	TOO_MANY_LOCKS

;-------------------------------------------------

CheckToUnlockNS	proc	far
	pushf
	call	ECCheckMemHandleNS
	push	ds
	LoadVarSeg	ds
	cmp	ds:[bx][HM_lockCount],0
	ERROR_Z	BAD_UNLOCK
	test	ds:[bx].HM_flags, mask HF_FIXED
	ERROR_NZ BAD_UNLOCK
	cmp	ds:[bx].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	ERROR_E BAD_UNLOCK
	pop	ds
	popf
	ret
CheckToUnlockNS	endp

CheckSegmentECEnabled proc far
	push	ds
	LoadVarSeg	ds
	test	ds:[sysECLevel], mask ECF_SEGMENT
	pop	ds
	ret
CheckSegmentECEnabled endp	

CheckNormalECEnabled proc far
	push	ds
	LoadVarSeg	ds
	test	ds:[sysECLevel], mask ECF_NORMAL
	pop	ds
	ret
CheckNormalECEnabled endp	
;-------------------------------------------------

FarCheckDS_ES	proc	far
	call	CheckDS_ES
	ret
FarCheckDS_ES	endp

CheckDS_ES	proc	near
	pushf
	call	CheckSegmentECEnabled
	jz	done

	push	ax
	mov	ax, ds
	call	ECCheckSegment
	mov	ax, es
	call	ECCheckSegment
	pop	ax
done:
	popf
	ret

CheckDS_ES	endp

;-------------------------------------------------

NullSegmentRegisters	proc	far
	pushf

	call	CheckSegmentECEnabled
	jz	done

	push	ax
	mov	ax, ds
	call	NullSeg
	mov	ds, ax
	mov	ax, es
	call	NullSeg
	mov	es, ax
	pop	ax

done:
	popf
	ret

NullSegmentRegisters	endp

NullSeg		proc	near
	tst	ax
	jz	done
	cmp	ax, NULL_SEGMENT
	jz	done
;;	cmp	ax, 0xffff		;HACK FOR THE WINDOW SYSTEM
;;	jz	done


	push	cx, ds
	cmp	ax, 40h			; allow segments pointing into
	jb	nullIt			;  DOS for things like the FS driver
					;  XXX: this is bullshit. The code does
					;  *NOT* do this -- ardeb
	je	popDone			; allow BIOS data area segment...

if	UTILITY_MAPPING_WINDOW
	;
	; leave segment in utility mapping window alone
	;
	LoadVarSeg	ds
	tst	ds:[utilWindowSegment]
	jz	notMappingWindow
	cmp	ax, ds:[utilWindowSegment]
	jb	notMappingWindow
	push	ax
	mov	ax, ds:[utilWindowSize]
	mov	cx, ds:[utilWindowNumWindows]
	dec	cx
	jcxz	haveWindowSize
getWindowSize:
	add	ax, ds:[utilWindowSize]
	loop	getWindowSize
haveWindowSize:
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	add	ax, ds:[utilWindowSegment]
	mov	cx, ax			; cx = end of mapping window
	pop	ax			; ax = segment to check
	cmp	ax, cx
	jb	popDone			; in mapping window, leave alone
notMappingWindow:
endif	; UTILITY_MAPPING_WINDOW
		
if	FULL_EXECUTE_IN_PLACE
		
	;
	; On XIP systems, if the segment is in the map area, just blindly
	; accept it (don't NULL it out) as this routine could be called from
	; a routine in movable memory, and so a pointer into the original
	; caller's code segment would be treated as invalid. It's better
	; to let some possibly invalid segments through than to die
	; when passed valid segments.
	;	
	LoadVarSeg	ds
	;
	; Also, if the segment points to the FullXIPHeader block (which
	; doesn't have an associated handle), don't null it.  This allows
	; us to use strings in GeodeNameTableEntry.  --- AY 11/14/94
	;
	; Moved up here, as the mapPage is *not* necessarily below the xip
	; header - atw 11/17/94
	;
	cmp	ax, ds:[loaderVars].KLV_xipHeader
	je	popDone

	cmp	ax, ds:[loaderVars].KLV_mapPageAddr
	jb	notInMapArea
	push	ax
	sub	ax, ds:[loaderVars].KLV_mapPageAddr
	cmp	ax, MAPPING_PAGE_SIZE/16
	pop	ax
	jb	popDone


notInMapArea:		
	
endif
		
	mov	cx, ax
	call	MemSegmentToHandle
	jc	found
nullIt:
	mov	ax, NULL_SEGMENT
	jmp	popDone

found:
	push	bx
	LoadVarSeg	ds
	mov	bx, cx
	test	ds:[bx].HM_flags, mask HF_FIXED
	jnz	10$

	; if this is the block being swapped then it is ok for the lock count
	; to be 0

	cmp	bx, ds:[handleBeingSwappedDontMessWithIt]
	jz	10$

	cmp	ds:[bx].HM_lockCount, 0
	jnz	10$
		
	mov	ax, NULL_SEGMENT
10$:
	pop	bx

popDone:
	pop	cx, ds

done:
	ret
NullSeg		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NullDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force DS to be NULL_SEGMENT

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		ds	= NULL_SEGMENT
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nullSeg		word	NULL_SEGMENT
NullDS		proc	far
		mov	ds, cs:[nullSeg]
		ret
NullDS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NullES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force ES to be NULL_SEGMENT

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		es	= NULL_SEGMENT
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NullES		proc	far
		mov	es, cs:[nullSeg]
		ret
NullES		endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckToPOrV

DESCRIPTION:	Make sure a handle is legal to P or V

CALLED BY:	Utility

PASS:
	bx - handle

RETURN:
	none

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

CheckToV	proc	far
	pushf

	push	ds
	LoadVarSeg	ds

	INT_OFF
	cmp	ds:[bx].HM_otherInfo, 0
	jz	semOK
	jmp	checkBlkdThread
CheckToV	endp

CheckToP	proc	far
	pushf

	push	ds
	LoadVarSeg	ds
	INT_OFF
	cmp	ds:[bx].HM_otherInfo, 1
	jbe	semOK

checkBlkdThread	label	near
	push	bx
	mov	bx, ds:[bx].HM_otherInfo
	call	ECCheckThreadHandleFar
	pop	bx

semOK	label	near
	cmp	ds:[bx].HG_type, SIG_VM
	jz	10$
	cmp	ds:[bx].HG_type, SIG_FILE
	je	10$
	call	ECCheckMemHandleNS
10$:
	pop	ds

	popf
	ret

CheckToP	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckBX_SIAdjacent

DESCRIPTION:	Make sure handles bx and si are adjacent

CALLED BY:	Utility

PASS:
	bx - handle
	si - handle

RETURN:
	none

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

CheckBX_SIAdjacent	proc	far
	pushf
	push	ds
	LoadVarSeg	ds

	cmp	bx,ds:[bx].HM_next
	jz	corrupt
	cmp	bx,ds:[bx].HM_prev
	jz	corrupt
	cmp	si,ds:[si].HM_next
	jz	corrupt
	cmp	si,ds:[si].HM_prev
	jz	corrupt
	cmp	ds:[bx].HM_next, si
	jnz	comb
	cmp	ds:[si].HM_prev, bx
	jnz	comb

	pop	ds
	popf
	ret

corrupt:
	ERROR	CORRUPTED_HEAP

comb:
	ERROR	COMBINING_NON_ADJACENT_BLOCKS

CheckBX_SIAdjacent	endp

;---------

CheckBX	proc	far
	pushf
	push	si
	push	ds
	LoadVarSeg	ds

	mov	si,ds:[bx].HM_next
	call	CheckBX_SIAdjacent

	mov	si,ds:[bx].HM_prev
	xchg	bx,si
	call	CheckBX_SIAdjacent
	xchg	bx,si

	pop	ds
	pop	si
	popf
	ret

CheckBX	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssertHeapMine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the heap is locked by the current thread

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AssertHeapMine	proc	far	uses ds, ax
		.enter
		pushf
		LoadVarSeg	ds
		cmp	ds:heapSem.TL_sem.Sem_value, 0
		jg	notMine
		mov	ax, ds:currentThread
		cmp	ax, ds:heapSem.TL_owner
		je	isOk
		tst	ax		; Allow kernel thread too to handle
					;  freeing of stack blocks &c.
		jz	isOk
notMine:
		ERROR	HEAP_NOT_OWNED_BY_ME
isOk:
		popf
		.leave
		ret
AssertHeapMine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECMemVerifyHeapLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the heap is consistent.

CALLED BY:	ECMemVerifyHeap, EXTERNAL
PASS:		ds	= idata
		heap semaphore down
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECMemVerifyHeapLow proc	far	uses bx
	.enter
	
	call	CheckNormalECEnabled
	jz	done
	mov	bx, ds:[loaderVars].KLV_handleBottomBlock
MVH_loop:
	call	CheckHeapHandle
	mov	bx, ds:[bx].HM_next
	cmp	bx, ds:[loaderVars].KLV_handleBottomBlock
	jnz	MVH_loop

	call	AssertFreeBlocksCC
	call	ECCheckBlockChecksum
done:
	.leave
	ret
ECMemVerifyHeapLow endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHeapHandleSW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a handle that may be swapped

CALLED BY:	EXTERNAL/INTERNAL
PASS:		bx	= handle to check
RETURN:		nothing
DESTROYED:	nothing (not even flags)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHeapHandleSW	proc	far
	pushf
	INT_OFF
	push	ds
	LoadVarSeg	ds
	cmp	ds:[bx][HM_addr],0
	jz	10$
	call	CheckHeapHandle
10$:
	pop	ds
	popf
	ret

CheckHeapHandleSW	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHeapHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a handle is a valid, resident memory handle

CALLED BY:	INTERNAL/EXTERNAL
PASS:		bx	= handle to check (should likely be locked or the
			  heap semaphore should be down)
RETURN:		nothing
DESTROYED:	flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHeapHandle	proc	far
	push	ax
	push	ds
	LoadVarSeg	ds
	; Block resident?
	cmp	ds:[bx][HM_addr],0
	jz	corrupt
	; Resonably sized?
	cmp	ds:[bx][HM_size],0
ifdef PRODUCT_GEOS32   ; GEOS32 doesn't have a heap of linear memory
        jnz     11$
else
	jz	corrupt

	; Stretches to next block?
	push	bx
	mov	ax,ds:[bx][HM_size]
	add	ax,ds:[bx][HM_addr]
	jc	corrupt
	mov	bx,ds:[bx][HM_next]
	cmp	bx,ds:[loaderVars].KLV_handleBottomBlock
						; was bx last block on heap?
	jz	10$				;  => has no next
	sub	ax,ds:[bx][HM_addr]		; Matches next? Use sub so
	jz	10$				;  we can see if next was in
						;  transit.
	; block doesn't reach to next -- see if next was in transit at
	; the time. we must do this as unless the heap semaphore is down,
	; we've been granted surety only for the handle being checked.
	pop	bx
	sub	ax, ds:[bx].HM_addr
	cmp	ax, ds:[bx].HM_size
	je	11$
endif   ; defined(PRODUCT_GEOS32) 
corrupt:
	ERROR	CORRUPTED_HEAP
ifndef PRODUCT_GEOS32   ; GEOS32 doesn't have a heap of linear memory
10$:
	pop	bx
endif   ; defined(PRODUCT_GEOS32) 
11$:

	; Check flag validity
	test	ds:[bx][HM_flags],mask HF_SWAPPED or mask HF_DISCARDED
	jnz	corrupt

	test	ds:[bx][HM_flags],mask HF_LMEM
	jnz	lmem
20$:
	cmp	ds:[bx][HM_owner],0	; block free?
	jnz	40$
	test	ds:[bx][HM_flags], not mask HF_DEBUG ; flags must be zero if so
	jnz	corrupt
40$:
	pop	ds
	pop	ax
	ret

lmem:

	; This checking has a race condition because FullObjLock momentarily
	; has the block with an incorrect LMBH_handle

if	0
	INT_OFF
	tst	ds:[bx].HM_lockCount
	jz	afterLMemCheck

	; handle race condition in FullObjLock where the block is realloced
	; to a single paragraph before calling MemSwap.
	
	cmp	ds:[bx].HM_size, 1
	je	afterLMemCheck

	; Check lmem parameters

	mov	ds,ds:[bx][HM_addr]

	; Handle matches handle in header?
	cmp	bx,ds:LMBH_handle
	jnz	corruptLMem

	; Reasonable lmem blocktype?

	cmp	ds:LMBH_lmemType, LMemType
	jae	corruptLMem

afterLMemCheck:
	INT_ON
endif

	LoadVarSeg	ds
	jmp	20$

if	0
corruptLMem:
	ERROR	CORRUPTED_LMEM_BLOCK
endif

CheckHeapHandle	endp


endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	AssertFreeBlocksCC

DESCRIPTION:	Make sure that all bytes in all free blocks are 0xcc

CALLED BY:	INTERNAL
		AllocHandleAndBytes, ECMemVerifyHeapLow

PASS:
	exclusive access to heap variables
	ds - kernel data segment

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
	Tony	2/90		Initial version

-------------------------------------------------------------------------------@


if	ERROR_CHECK

AssertFreeBlocksCC	proc	far
	pushf
	call	PushAllFar

	call	SysGetECLevel
	test	ax, mask ECF_FREE
	jz	done

	; start at the bottom of the heap

	clr	si
	mov	ax, 0xcccc
	mov	bx, ds:[loaderVars].KLV_handleBottomBlock
if TRACK_FINAL_FREE
	clr	bp
endif

blockLoop:
	cmp	ds:[bx].HM_owner, 0
	jnz	notFree
	
if TRACK_FINAL_FREE
	mov	bp, bx				; remember last one seen
endif

	; block is free -- test it

	mov	es, ds:[bx].HM_addr		;es = block
	mov	dx, ds:[bx].HM_size		;dx = # paragraphs
	add	si, dx				;add to total
largeLoop:
	mov	cx, dx
	cmp	cx, 0xfff
	jb	10$
	mov	cx, 0xfff
10$:
	sub	dx, cx				;dx = # paragraphs left
	shl	cx
	shl	cx
	shl	cx				;cx = # words
	clr	di
	repe	scasw
	ERROR_NZ	MEM_FREE_BLOCK_DATA_NOT_CC

	mov	cx, es				;assume > 0xfff paragraphs
	add	cx, 0xfff
	mov	es, cx
	tst	dx
	jnz	largeLoop

	; move to next block

notFree:
	mov	bx, ds:[bx].HM_next
	cmp	bx, ds:[loaderVars].KLV_handleBottomBlock
	jnz	blockLoop

	cmp	si, ds:[loaderVars].KLV_heapFreeSize
	ERROR_NE	FREE_SIZE_NOT_CORRECT
	
if TRACK_FINAL_FREE
	cmp	bp, ds:[lastFreeBlock]
	ERROR_NE	LAST_FREE_BLOCK_NOT_CORRECT
endif

done:
	call	PopAllFar
	popf
	ret

AssertFreeBlocksCC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckLastFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the lastFreeBlock variable is set right

CALLED BY:	(INTERNAL)
PASS:		ds	= kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if TRACK_FINAL_FREE
CheckLastFreeBlock proc	near
		uses	ax, si
		.enter
		pushf
		mov	si, ds:[loaderVars].KLV_handleBottomBlock
		mov	ax, si
checkFreeLoop:
		mov	si, ds:[si].HM_next
		cmp	si, ds:[loaderVars].KLV_handleBottomBlock
		je	checkLastFree
		cmp	ds:[si].HM_owner, 0
		jne	checkFreeLoop
		mov	ax, si
		jmp	checkFreeLoop
checkLastFree:
		cmp	ax, ds:[lastFreeBlock]
		ERROR_NE	LAST_FREE_BLOCK_NOT_CORRECT
		popf
		.leave
		ret
CheckLastFreeBlock endp
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECFillCCCC

DESCRIPTION:	Fill a block with 0xcc for EC purposes

CALLED BY:	GLOBAL

PASS:		ds	= idata
		bx	= block to fill

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@


ECFillCCCC	proc	far
	call	PushAllFar

	mov	es,ds:[bx][HM_addr]
	mov	dx,ds:[bx][HM_size]
	mov	ax, 0xcccc
largeLoop:
	mov	cx, 0xfff
	sub	dx, cx				;assume 0xfff0 bytes
	jae	10$				;=> ok
	add	cx, dx				;downgrade count by overshoot
10$:
	shl	cx				;convert paras to words
	shl	cx
	shl	cx				;cx = # words
	clr	di
	rep	stosw

	mov	cx, es				;assume > 0xfff paragraphs
	add	cx, 0xfff
	mov	es, cx
	tst	dx				;XXX: assumes no free block
						; > 1/2 megabyte. Fair enough?
	jg	largeLoop

	call	PopAllFar
	ret

ECFillCCCC	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckBlockChecksum

DESCRIPTION:	Check the checksum of the block passed to SysSetECLevel

CALLED BY:	INTERNAL

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
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

ECCheckBlockChecksumFar proc far
	call	ECCheckBlockChecksum
	ret
ECCheckBlockChecksumFar endp
	ForceRef ECCheckBlockChecksumFar ; mostly for calling from Swat...

ECCheckBlockChecksum	proc	near
	pushf
	push	ds
	call	FarLoadVarSegDS

	test	ds:[sysECLevel], mask ECF_BLOCK_CHECKSUM
	jz	done

	; DO NOT USE PushAll !!! It destroys callVector.segment.
	; It may not, in the future, however....

	push	ax, bx, cx, dx, si, di, es

	mov	bx, ds:[sysECBlock]
	mov	dx, ds:[bx].HM_addr
	tst	dx
	jz	donePop

	mov	cx, ds:[bx].HM_size
	mov	ds, dx

	; bx = handle
	; ds = block
	; cx = block size in paragraphs

;----------------

if	1	;Checksum

	; generate the checksum -- cx = # paragraphs

	clr	si
	clr	di			;di = checksum
addLoop:
	lodsw				;1
	add	di, ax
	lodsw				;2
	add	di, ax
	lodsw				;3
	add	di, ax
	lodsw				;4
	add	di, ax
	lodsw				;5
	add	di, ax
	lodsw				;6
	add	di, ax
	lodsw				;7
	add	di, ax
	lodsw				;8
	add	di, ax
	loop	addLoop

	call	FarLoadVarSegDS
	cmp	dx, ds:[bx].HM_addr
	jnz	donePop

	; di = checksum (if 0 then make 1)

	tst	di
	jnz	notZero
	inc	di
notZero:

	cmp	ds:[sysECChecksum],0
	jz	storeNew
	cmp	di, ds:[sysECChecksum]
	jz	storeNew
	ERROR	BLOCK_CHECHSUM_ERROR
storeNew:
	mov	ds:[sysECChecksum], di

endif

;----------------

if	0	;Trying to find the "6 bug"

	clr	si
	dec	cx
aloop:
	cmp	{word} ds:[si+2], 6
	jnz	diff

found:		;set breakpoint here
	nop

diff:
	add	si, 16
	loop	aloop

endif

;----------------

donePop:

	pop	ax, bx, cx, dx, si, di, es

done:
	pop	ds
	popf
	ret

ECCheckBlockChecksum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemForceMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the passed block to move on the heap, due to some
		error-checking flag having been set.

CALLED BY:	(EXTERNAL) MemUnlock, ForceBlockToMove
PASS:		ds	= dgroup
		bx	= block to move (keeps same lock count)
		cx	= non-zero if should only move the block if the
			  lock count is 0 (and block is still resident) after
			  grabbing the heap lock.
RETURN:		nothing
DESTROYED:	cx
SIDE EFFECTS:	Block will move on the heap, if possible.

PSEUDO CODE/STRATEGY:
		The essence of the strategy here is to give the current
		memory to a new handle, pretend the block to move has been
		discarded, then call DoReAlloc to allocate more memory for
		the block and call our callback routine. The callback routine
		then copies the data from the old place to the new. When
		DoReAlloc returns, we free the old memory (and the new
		handle) and we're done.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemForceMove	proc	far
		uses	dx, si, di
		.enter
	;
	; We are sometimes called from interrupt code (the sound library
	; unlocking the just-finished stream is the most notable case) and
	; do *not* want to do this during interrupt code.
	;
		tst	ds:[interruptCount]
		jnz	exeuntOmnes
	;
	; Gain exclusive access to the heap for the duration here and zero the
	; address of the handle, so anyone else attempting to lock it must
	; wait on our release of the semaphore.
	; 
		call	FarPHeap
		clr	dx
		xchg	ds:[bx].HM_addr, dx
	;
	; Make sure the block didn't get locked while we were waiting on the
	; heapSem.
	; 
		tst	dx
		jz	noMove		; => got swapped/discarded while count
					;  was 0, which means our purpose was
					;  accomplished by someone else

		jcxz	moveIt		; => don't care about lock count...

		tst	ds:[bx].HM_lockCount
		jz	moveIt

noMove:
	;
	; It got locked or swapped in that little window, so restore the
	; segment and get out. There's nothing more we need to or can do.
	; 
		mov	ds:[bx].HM_addr, dx
		jmp	unlockMoveDone
	
moveIt:
	;
	; First make a copy of the handle whose memory will be moved and
	; link it into the heap in place of the one being moved, giving the
	; memory to the duplicate. We leave the duplicate unlocked and allow
	; it to be swapped, if necessary, to allocate the new memory (hopefully
	; it won't happen in the same place :) to avoid memory-full deaths.
	; We cannot allow the memory to be discarded, however: that's getting
	; too complicated.
	; 
EC <		call	AssertHeapMine					>
		call	FarDupHandle		; bx <- new handle
		mov	ds:[bx].HM_addr, dx	; (set addr so FixLinks2 does
						;  something)
		call	FixLinks2Far		; link duplicate in place of old
		andnf	ds:[bx].HM_flags, not (mask HF_DISCARDABLE or \
					       mask HF_DEBUG)
	;
	; Now mark the one being moved as having been discarded, so the callback
	; we pass to DoReAlloc will be called.
	; 
		xchg	bx, si
		ornf	ds:[bx].HM_flags, mask HF_DISCARDED
		mov	ds:[handleBeingForceMoved], bx
		clr	ax			; same size
		clr	ch
		mov	dx, offset MemForceMoveCallback
		mov	di, si			; di <- data for callback
						;  (handle w/old mem)
		push	di			; save for free on return
		call	DoReAllocFar
		mov	di, bx			; preserve orig handle
		pop	bx			;  while we pop the handle with

		mov	ds:[handleBeingForceMoved], 0
						;  the original memory
		jc	cannotAlloc

		call	DoFreeFar
		mov	bx, di
unlockMoveDone:
		call	FarVHeap
exeuntOmnes:
		.leave
		ret

cannotAlloc:
	;
	; Couldn't allocate memory for the block, so give it back what it had
	; before. At the very worst, the dup handle has been swapped out, which
	; would also accomplish our end.
	;
		mov	si, di
		xchg	bx, si			; bx <- orig handle
						; si <- dup handle
		call	SwapHandlesFar
		jmp	unlockMoveDone
MemForceMove 	endp

kcode	segment		; this has to be kcode, because DoReAlloc does
			; a blind near call to it..  ei  "call	dx"

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemForceMoveCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to copy the contents of a block being
		moved by ECF_UNLOCK_MOVE or ECF_LMEM_MOVE

CALLED BY:	(INTERNAL) MemForceMove via DoReAlloc
PASS:		bx	= handle being moved
		si	= handle holding new memory for it
		di	= handle holding old memory for it
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemForceMoveCallback proc	near
		.enter
		test	ds:[di].HM_flags, mask HF_SWAPPED
		jz	copyMem
		
		push	bx
		mov	bx, di		; pretend to swap in the old memory
		call	MemSwapInCallDriver
		mov	di, bx
		pop	bx
		ERROR_C	ECF_UNLOCK_MOVE_FAILED_SORRY
	;
	; Change the status of the old block from swapped to discarded so we
	; don't double-free the swap space (which was freed by the swap-in)
	; 
		xornf	ds:[di].HM_flags, mask HF_SWAPPED or mask HF_DISCARDED
		jmp	done
copyMem:
	;
	; Use the common move routine to perform the copy.
	; 
		mov	ax, ds:[si].HM_addr	; ax <- dest addr
		mov	cx, ds:[bx].HM_size	; cx <- # paras to move
		mov	dx, ds:[di].HM_addr	; dx <- src addr
		call	MoveBlock
done:
		.leave
		ret
MemForceMoveCallback endp
kcode	ends

endif	; ERROR_CHECK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPageChecksum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a checksum check on the currently mapped in page

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	ERROR_CHECK and FULL_EXECUTE_IN_PLACE
ECCheckPageChecksum	proc	far	uses	ds
	.enter
	pushf
	LoadVarSeg	ds
	tst	ds:[xipChecksumPage]
	jz	exit

	push	ax
	mov	ax, ds:[xipChecksumPage]
	cmp	ax, ds:[curXIPPage]
	pop	ax
	jne	exit

;	Generate a checksum for the page

	push	ax, cx, si
	mov	ds, ds:[loaderVars].KLV_mapPageAddr
	clr	si			;DS:SI <- ptr to start of page to
					; checksum
	mov	cx, MAPPING_PAGE_SIZE/(size word)
	clr	ax
next:
	add	ax, ds:[si]
	add	si, 2
	loop	next

;	Don't allow a checksum of 0

	tst	ax
	jz	10$
	inc	ax
10$:
	LoadVarSeg	ds
	tst	ds:[xipChecksum]
	jnz	20$
	mov	ds:[xipChecksum], ax
20$:
	cmp	ax, ds:[xipChecksum]
	ERROR_NZ	BLOCK_CHECHSUM_ERROR
	pop	ax, cx, si
exit:
	popf
	.leave
	ret
ECCheckPageChecksum	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckXIPPageNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the passed page number is valid for the XIP
		image.

CALLED BY:	MapXIPPageInline macro

PASS:		ax = page number (in multiples of the mapping page size)

RETURN:		nothing.  Fatal error if invalid.

DESTROYED:	flags

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Each device needs to have its own check.
	
	Make sure you add the product to the list of products in
	MapXIPPageInline that calls this function.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	ERROR_CHECK and FULL_EXECUTE_IN_PLACE

if GULLIVER_XIP

ECCheckXIPPageNumber	proc	far
	uses	ax
	.enter

	; Convert ax to physical page size if mapping page size !=
	; physical page size
	
if	MAPPING_PAGE_SIZE eq PHYSICAL_PAGE_SIZE * 2
	shl	ax, 1
elseif	MAPPING_PAGE_SIZE ne PHYSICAL_PAGE_SIZE
	ErrMessage <Write code to deal with big mapping page>
endif

	; Unfortunately, zero is valid because when a thread is started, the
	; initial ThreadBlockState for a thread has TBS_xipPage initialized
	; to zero.  This is an interesting problem since DispatchSI, which
	; will be the one popping the page number off the stack and calling
	; MapXIPPageInline, causes pages 0 (and 1?) to be mapped in even if
	; they aren't in the XIP image... 
	tst	ax
	jz	done

if GULLIVER_XIP

	cmp	ax, XIP_PAGE_START_1
	ERROR_B	XIP_PAGE_NUMBER_NOT_IN_VALID_RANGE
	
	cmp	ax, XIP_PAGE_END_1
	jbe	done
	
	cmp	ax, XIP_PAGE_START_2
	ERROR_B	XIP_PAGE_NUMBER_NOT_IN_VALID_RANGE
	
	cmp	ax, XIP_PAGE_END_2
	ERROR_A	XIP_PAGE_NUMBER_NOT_IN_VALID_RANGE
	
endif
	
done::
	.leave
	ret
ECCheckXIPPageNumber	endp

endif ;GULLIVER_XIP or PENELOPE_XIP or DOVE_XIP

endif


if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddToOddityList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds an entry to the Oddity List.  Gives an Error if
		List is full.

CALLED BY:	Originally called by VMWriteBlk to track odd-state
		biffing blocks
PASS:		bx	- Handle to add
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Dies if list is full

PSEUDO CODE/STRATEGY:
	Lock Oddity List
	Find Handle (null)		
	if result = null
		Error
	else
		calc offset
		stick kdata:offset, Handle
	Release Oddity List
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddToOddityList	proc	far
	uses	bp, ds
	.enter
	LoadVarSeg	ds
	
	call	LockOddityList
;
; Find Handle
;
	push	bx
	clr	bx
	call	FindInOddityList
	pop	bx
;
; if result = 0, list is full!
;
	tst	bp
	ERROR_Z GASP_CHOKE_WHEEZE
;
; place handle in list
;
	mov	ds:[bp].startOfOddityList, bx
;
; Release the lock
;
	call	ReleaseOddityList

	.leave
	ret
AddToOddityList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveFromOddityList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes and entry from the Oddity List.  Gives an
		Error if it wasn't there..  it's not like we should be guessing!

CALLED BY:	probably just VMWriteBlk
PASS:		bx	- Handle to remove
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Lock Oddity List
	Find Handle (Handle)
	if result = null
		Error
	else
		calc offset
		stick kdata:offset, 0
	Release Oddity List

yes..  I know this looks awefully like the Add routine..

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveFromOddityList	proc	far
	uses	bp, ds
	.enter
	LoadVarSeg	ds

	call	LockOddityList
	call	FindInOddityList
	tst	bp
	ERROR_Z	GASP_CHOKE_WHEEZE
	clr	{word}ds:[bp].startOfOddityList
	call	ReleaseOddityList
	.leave
	ret
RemoveFromOddityList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindInOddityList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	looks up a word value in the Oddity List

CALLED BY:	anybody..
PASS:		bx - value to find
		ds - kdata
RETURN:		bp - offset from start to requested word, or 0 if not found
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindInOddityList	proc	far
	.enter
	call	LockOddityList
	mov	bp, offset startOfOddityList + (size startOfOddityList)-2
loopTop:
	cmp	bx, ds:[bp]
	je	done
	dec	bp
	dec	bp
	cmp	bp, offset startOfOddityList
	jne	loopTop
done:
	sub	bp, offset startOfOddityList
	call	ReleaseOddityList	
	.leave
	ret
FindInOddityList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockOddityList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks down a semaphore whose handle is stored at
		kdata:startOfOddityList.  If the handle = 0 it creates
		a semaphore.

CALLED BY:	the oddilty list stuff..
PASS:		ds	- kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockOddityList	proc	near
	uses	bx
	.enter
	pushf				; to restore interrupts to
					; initial state
	INT_OFF
	mov	bx, ds:[startOfOddityList]
	tst	bx
	jz	createLock
	popf
returnFromCreate:
	call	ThreadGrabThreadLock	
	.leave
	ret

createLock:
	call	ThreadAllocThreadLock
	mov	ds:[bx].HS_owner, Handle 0
	mov	ds:[startOfOddityList], bx
	popf
	jmp	returnFromCreate

LockOddityList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReleaseOddityList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just releases the lock..

CALLED BY:	oddity list stuff
PASS:		ds	- kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReleaseOddityList	proc	near
	uses	bx
	.enter
	mov	bx, ds:[startOfOddityList]
	call	ThreadReleaseThreadLock
	.leave
	ret
ReleaseOddityList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckHandleForWeirdness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the handle for a special case for these two routines.

CALLED BY:	SearchHeap and FindNOldest
PASS:		bx	- Mem Handle
		ds	- kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	2/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckHandleForWeirdness	proc	far
	.enter
;
; what a mess!  OK.  The funny business going on here is due to a
; possible recursion because of Objectblocks being biffed
; asynchronously (VMA_TEMP_ASYNC mechanism).  So we may have a locked
; VM Block with an address of zero coming through.  Since it is
; owned (SearchHeap case) and locked (FindNOldest case) it will be
; skipped in Non-EC, but that CheckHeapHandle will choke in EC.  So,
; we check for this case as specifically as we can and skip the
; CheckHeapHandle only in this particular case.
;
	tst	ds:[bx].HM_addr		; handle the commoncase
	jnz	okCheckHandle
	push	bx
	mov	bx, ds:[bx].HM_owner
	cmp	ds:[bx].HVM_signature, SIG_VM	; only odd ok case
	jne	restoreAndCheckHandle
	cmp	ds:[bx].HVM_semaphore, 1	; and must be entered
	je	restoreAndCheckHandle
	mov	bx, ds:[bx].HVM_headerHandle	; must be entered by
	mov	bx, ds:[bx].HM_usageValue	; this thread!
	cmp	bx, ds:[currentThread]
	jne	restoreAndCheckHandle
	pop	bx
	tst	{byte}ds:[bx].HM_lockCount	; and locked
	jz	okCheckHandle
	push	bp				; call trashes bp
	call	FindInOddityList
	tst	bp
	pop	bp
	jnz	afterCheckHandle		; so skip
	jmp	okCheckHandle
restoreAndCheckHandle:
	pop	bx
okCheckHandle:
	call	CheckHeapHandle
afterCheckHandle:
	.leave
	ret
ECCheckHandleForWeirdness	endp

endif	;ERROR_CHECK
ECCode	ends
