COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel VM Manager
FILE:		vmemEC.asm

AUTHOR:		Cheng, June 1989

ROUTINES:
	Name			Description
	----			-----------
    GLB	ECVMHandleVMFileOverride
    GLB	ECVMCheckFileHandle
    GLB	ECVMCheckStrucs
    GLB	ECVMCheckMemHandle
    GLB	ECVMCheckBlkHanOffset
    EXT	VMHandleVMFileOverride
    INT	VMCheckStrucs
    INT	VMCheckHeader
    INT	VMCheckAssignedList
    INT	VMCheckTermination
    INT	VMCheckSortOrder
    INT	VMCheckUnassignedList
    INT	VMCheckUsedBlks
    INT	VMCheckFileHandle
    INT	VMCheckVMHandle
    INT VMCheckVMAndFileHandleAndDSKdata
    INT	VMCheckHeaderHandle
    INT	VMCheckMemHandle
    INT	VMCheckBlkHandle
    INT VMCheckBlkHandleAndDSHeader
    INT	VMCheckESHeader
    INT	AssertESKdata		;assert es = idata
    INT	VMVerifyWrite		;rereads blk that was written out and
				    ; compares it with the one in memory


	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/89	Initial revision


DESCRIPTION:
	Error-checking code for VM module
		
REGISTER USAGE:
	when possible:
	ds - idata
	bp - VM handle / VM mem handle
	bx - VM file handle
	di - VM block handle
	si - VM header handle
	es - VM header

	when relevant:
	ax - number of bytes
	cx - high word of file position
	dx - low word of file position

	$Id: vmemEC.asm,v 1.1 97/04/05 01:15:50 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode	segment

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECVMCheckMemHandle

DESCRIPTION:	Assert that a memory handle is the handle of a VM block

CALLED BY:	INTERNAL

PASS:
	bx - memory handle

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 9/91		Initial version

------------------------------------------------------------------------------@
ECVMCheckMemHandle	proc	far
EC <	xchg	bx, si							>
EC <	call	VMCheckMemHandle					>
EC <	xchg	bx, si							>
	ret
ECVMCheckMemHandle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECVMCheckVMFile

DESCRIPTION:	Versify the integrity of a VM file

CALLED BY:	INTERNAL

PASS:
	bx - vm file to check (or override if any)

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
	Tony	9/ 9/91		Initial version

------------------------------------------------------------------------------@
ECVMCheckVMFile	proc	far
EC <	mov	ss:[TPD_callVector.offset], offset VMCheckStrucs	>
EC <	call	ECVMEnterAndCall					>
	ret

ECVMCheckVMFile	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECVMCheckVMBlockHandle

DESCRIPTION:	Assert that a given VM block handle is valid

CALLED BY:	INTERNAL

PASS:
	bx - VM file handle
	ax - VM block handle

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
	Tony	9/ 9/91		Initial version

------------------------------------------------------------------------------@
ECVMCheckVMBlockHandle	proc	far
EC <	mov	ss:[TPD_callVector.offset], offset VMCheckStrucs	>
EC <	call	ECVMEnterAndCall					>
EC <	xchg	ax, di							>
EC <	mov	ss:[TPD_callVector.offset], offset VMCheckBlkHandle	>
EC <	call	ECVMEnterAndCall					>
EC <	xchg	ax, di							>
	ret

ECVMCheckVMBlockHandle	endp

IF	ERROR_CHECK	;*******************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVMEnterAndCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter the passed/override VM file and call an EC function

CALLED BY:	ECVMCheckStrucs, ECVMCheckBlkHandle
PASS:		ss:[TPD_callVector.offset]	= offset of routine to call
		bx	= VM file handle (if no override present)
		others depend on function called
RETURN:		result of call
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVMEnterAndCall proc near
	uses bx, ds, bp, si, es
	.enter
	push	ss:[TPD_callVector.offset]
	call	EnterVMFile			; might change callVector
	pop	ss:[TPD_callVector.offset]
	push	cs
	call	ss:[TPD_callVector.offset]
	call	ExitVMFile
	.leave
	ret
ECVMEnterAndCall endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckStrucs

DESCRIPTION:	Performs checks on the VM header, the assigned list and
		the unassigned list.

CALLED BY:	INTERNAL (error checking)

PASS:		ds - VM header

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing, flags not affected

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMCheckStrucs	proc	far
;if	INCLUDE_VMEM_EC
	uses	bp, bx, di, si, es
	.enter
	pushf
	LoadVarSeg	es
	test	es:sysECLevel, mask ECF_VMEM
	jz	done
	call	VMCheckDSHeader

	;init registers
	mov	bp, ds:[VMH_assignedPtr]
	mov	bx, ds:[VMH_lastAssigned]
	mov	si, ds:[VMH_unassignedPtr]

	mov	di, VMH_blockTable		;get header block han
	mov	di, ds:[di].VMBH_memHandle	;get header han
	xchg	si, di
	call	VMCheckMemHandle
	xchg	si, di
	mov	di, es:[di][HM_owner]		;get VM han
	xchg	bp, di
	call	VMCheckVMHandle
	xchg	bp, di

	call	VMCheckHeader			;destroys di
	call	VMCheckAssignedList		;destroys di
	call	VMCheckUnassignedList
	call	VMCheckUsedBlks			;destroys bp, bx, di, si

done:
	popf
	.leave
;endif
	ret
VMCheckStrucs	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckHeader

DESCRIPTION:	Performs checks on the VM header.

CALLED BY:	INTERNAL (VMCheckStrucs)

PASS:		ds - VM header
		bp - assigned list head
		bx - assigned list tail
		si - unassigned list head

RETURN:		nothing, dies if assertions fail

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMCheckHeader	proc	near
;if	INCLUDE_VMEM_EC
	;see that offsets are legal
	mov	di, bp			;check assigned head handle
	call	VMCheckBlkHandle

	mov	di, bx			;check assigned tail handle
	call	VMCheckBlkHandle

	mov	di, si			;check unassigned head handle
	call	VMCheckBlkHandle

	;check unassigned/resident counts
;	mov	di, ds:[VMH_numResident]	;num unassigned >= num dirty
;	shl	di
;	add	di, ds:[VMH_numExtraUnassigned]	;+ num extra unassigned
;	inc	di
;	cmp	di, ds:[VMH_numUnassigned]
;	ERROR_A	VM_BAD_HDR
; disabled 1/4 as it causes bogus errors during update -- ardeb
	tst	ds:VMH_numExtraUnassigned
	js	choke

	;check block handle for header
	mov	di, VMH_blockTable
	call	VMCheckUsedBlkHandle

	push	bp, es, si
	mov	si, ds:[di].VMBH_memHandle
	tst	si
	je	90$
	call	VMCheckMemHandle

	LoadVarSeg	es
	mov	di, es:[si][HM_owner]
	cmp	si, es:[di].HVM_headerHandle
	jnz	choke

;	tst	es:[si].HM_addr		; Allow headerHandle's addr to be 0
					;  or we can't write the damn thing
					;  out from ThrowOutBlocks
;	jz	90$

	mov	bp, ds
	cmp	bp, es:[si][HM_addr]
	je	90$
choke:
	ERROR	VM_BAD_HDR
90$:
	pop	bp, es, si
;endif
	ret
VMCheckHeader	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckAssignedList

DESCRIPTION:	Perform checks on the assigned list of the given header.

CALLED BY:	INTERNAL (VMCheckStrucs)

PASS:		ds - VM header
		bp - assigned list head
		bx - assigned list tail

RETURN:		nothing, dies if assertions fail

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMCheckAssignedList	proc	near
;if	INCLUDE_VMEM_EC
	pushf
	call	CheckNormalECEnabled
	jz	90$
	call	VMCheckTermination
	tst	bp
	je	90$
	call	VMCheckSortOrder	;destroys di
	call	VMCheckCoalescing
90$:
;endif
	popf
	ret
VMCheckAssignedList	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckTermination

DESCRIPTION:	Checks pointers in the VM header for proper termination.

CALLED BY:	INTERNAL (VMCheckAssignedList)

PASS:		ds - VM header
		bp - assigned list head
		bx - assigned list tail

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMCheckTermination	proc	near
;if	INCLUDE_VMEM_EC
	pushf
	call	CheckNormalECEnabled
	jz	90$
	tst	bp				;assigned head = nil?
	je	50$				;branch if so
	;-----------------------------------------------------------------------
	;head <> nil
	tst	bx				;tail must not be nil
	jz	choke

	tst	ds:[bp].VMFBH_prevPtr		;assert prev ptr of head = nil
	jnz	choke

	tst	ds:[bx].VMFBH_nextPtr		;assert next ptr of tail = nil
	jnz	choke

	tst	ds:[VMH_numAssigned]		;assert num assigned > 0
	jne	90$
choke:
	ERROR		VM_BAD_ASSIGNED_LIST
50$:
	;-----------------------------------------------------------------------
	;head = nil
	tst	bx				;tail must be nil too
	jnz	choke

	tst	ds:[VMH_numAssigned]		;assert num assigned = 0
	jnz	choke
90$:
;endif
	popf
	ret
VMCheckTermination	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckSortOrder

DESCRIPTION:	Traverses the assigned list to see that the elements are sorted
		in the proper order.

CALLED BY:	INTERNAL (VMCheckAssignedList)

PASS:		ds - VM header
		bp - assigned list head
		bx - assigned list tail

RETURN:		nothing, dies if assertions fail

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@


VMCheckSortOrder	proc	near
;if	INCLUDE_VMEM_EC
	uses	ax, cx, dx, si
	.enter
	;ax counts the number of elements in the assigned list
	;cx and dx holds the end of the previous block
	;di is the current block
	;si is the previous block
	pushf
	call	CheckNormalECEnabled
	jz	done
	mov	di, bp				;use di to traverse list
	clr	ax				;use ax to count elements
	mov	cx, ax				;init file pos to 0
	mov	dx, ax
	mov	si, ax				;use si to track prev handle
10$:
	inc	ax				;up element count
	call	VMCheckBlkHandle

	cmp	ds:[di].VMFBH_prevPtr, si	;confirm prev ptr
	jne	badAssignedList

	cmp	cx, ds:[di].VMFBH_filePos.high	;make sure block doesn't overlap
	jne	60$				; prev (prev is below)
	cmp	dx, ds:[di].VMFBH_filePos.low
60$:
	ERROR_A		VM_BAD_SORT_ORDER
	mov	si, di				;track prev handle
	mov	dx, ds:[di].VMFBH_filePos.low	;get file pos of block end
	mov	cx, ds:[di].VMFBH_filePos.high
	add	dx, ds:[di].VMFBH_fileSize.low
	adc	cx, ds:[di].VMFBH_fileSize.high

	mov	di, ds:[di].VMFBH_nextPtr	;on to next
	tst	di				;end of list?
	jne	10$			;loop if not

	cmp	si, bx				;confirm last ptr matches
						; caller's idea
	je	checkNum
badAssignedList:
	ERROR	VM_BAD_ASSIGNED_LIST

checkNum:
	cmp	ax, ds:[VMH_numAssigned]
	ERROR_NE	VM_BAD_ASSIGNED_COUNT
done:
	popf
	.leave
;endif
	ret
VMCheckSortOrder	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckCoalescing

DESCRIPTION:	Traverses the assigned list to see that there exists a used
		block assigned to the file pos following the end of the
		assigned free block. Asserts proper coalescing.

CALLED BY:	INTERNAL
		VMDoCompress, VMCheckAssignedList

PASS:		ds - VM header
		bp - assigned list head
		bx - assigned list tail

RETURN:		nothing, dies if assertions fail

DESTROYED:	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMCheckCoalescing	proc	far

	uses	ax, bx, cx, dx, si, bp

assignedListTail	local	word push bx
assignedListHead	equ {word}ss:[bp]
prevAssigned		local	word

	.enter

	push	bx
	call	SysGetECLevel
	pop	bx
	test	ax, mask ECF_VMEM
	jnz	doAnal

	;non-anal version
	;bx will be used to traverse the assigned list
	push	bp
	mov	bp, ss:[assignedListHead]
VMCC_loop:
	call	VMFindFollowingUsedBlk
	jc	assertLastAssigned
	mov	di, ds:[bp].VMFBH_nextPtr		;on to next assigned
	tst	di
	jz	assertLastAssigned
	mov	bp, di
	jmp	VMCC_loop

assertLastAssigned:
	cmp	bp, bx
	pop	bp		; recover now so user can debug...
	ERROR_NE	VM_BAD_ASSIGNED_LIST
done:
	.leave
	ret

doAnal:
	; dx:cx = file position of first block in file

	clr	dx
	mov	cx, size VMFileHeader
	clr	si
	mov	ss:[prevAssigned], si

	; dx:cx = first position to look for
	; si = last handle (0 if none)

scanLoop:

	; find block at position dx:cx

	clr	ax				;ax = block above flag
	mov	di, ds:[VMH_lastHandle]
innerLoop:
	sub	di, size VMBlockHandle
	cmp	di, VMH_blockTable
	jb	notFound
	cmp	dx, ds:[di].VMBH_filePos.high
	jb	markBlockAbove
	ja	innerLoop
	cmp	cx, ds:[di].VMBH_filePos.low
	jz	found
	ja	innerLoop
markBlockAbove:
	inc	ax				;set "block above" flag
	jmp	innerLoop
found:

	test	ds:[di].VMBH_sig, VM_IN_USE_BIT
	jnz	used

	; block is a free block

	add	cx, ds:[di].VMFBH_fileSize.low
	adc	dx, ds:[di].VMFBH_fileSize.high
	tst	si
	jz	10$
	test	ds:[si].VMBH_sig, VM_IN_USE_BIT
	ERROR_Z	VM_TWO_CONSECUTIVE_FREE_BLOCKS	;two consecutive free block
10$:
	mov	si, di
	xchg	si, ss:[prevAssigned]
	tst	si
	jnz	notFirstAssigned
	cmp	di, ss:[assignedListHead]	;first assigned must be
	jz	common				;assignedListHead
	ERROR	VM_ASSIGNED_LIST_HEAD_IS_WRONG

notFirstAssigned:
	cmp	di, ds:[si].VMFBH_nextPtr	;assigned blocks must be
	jz	common				;listed in ascending order
	ERROR	VM_BAD_ASSIGNED_LIST		; so nothing can come between
						; prev and this one.

	; block is used

used:
	add	cx, ds:[di].VMBH_fileSize
	adc	dx, 0

common:
	mov	si, di				;save last block
	jmp	scanLoop

notFound:
	tst	ax				;if a block exists past this
	ERROR_NZ	VM_GAP_EXISTS_IN_FILE	;one then gap & error

if	0
;;;	; NO LONGER VALID
;;;	; at end of file -- first test to see if the file size is correct
;;;
;;;	mov	bx, ds:VMH_blockTable.VMBH_memHandle	;bx = header handle
;;;	mov	bx, es:[bx].HM_owner			;bx = VM handle
;;;	mov	bx, es:[bx].HVM_fileHandle		;bx = file handle
;;;	call	FileSize				;dx:ax = file size
;;;	test	ds:[si].VMBH_sig, VM_IN_USE_BIT
;;;	jnz	subInUseSize
;;;	sub	ax, ds:[si].VMFBH_fileSize.low
;;;	sbb	dx, ds:[si].VMFBH_fileSize.high
;;;	jmp	subCommon
;;;subInUseSize:
;;;	sub	ax, ds:[si].VMBH_fileSize
;;;	sbb	dx, 0
;;;subCommon:
;;;	cmp	dx, ds:[si].VMFBH_filePos.high
;;;	jnz	badFileSize
;;;	cmp	ax, ds:[si].VMFBH_filePos.low
;;;	jz	goodFileSize
;;;badFileSize:
;;;	ERROR	VM_BAD_FILE_SIZE
;;;goodFileSize:
endif

	; at end of file

	mov	si, ss:[prevAssigned]		;the last assigned block
	cmp	si, ss:[assignedListTail]	;that we encountered must
	ERROR_NZ	VM_ASSIGNED_LIST_TAIL_IS_WRONG
						;be the tail of the list

	jmp	done

VMCheckCoalescing	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckUnassignedList

DESCRIPTION:	Checks the unassigned list.

CALLED BY:	INTERNAL (VMCheckStrucs)

PASS:		ds - VM header
		si - unassigned list head

RETURN:		nothing, dies if assertions fail

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMCheckUnassignedList	proc	near
	pushf
	call	CheckNormalECEnabled
	jz	done
	push	ax
	clr	ax				;count num unassigned with ax

	tst	si				;any unassigned blocks?
	je	checkCount			;no -- make sure the count is 0
	;-----------------------------------------------------------------------
	;unassigned blocks exist
	mov	di, si				;go through blk handles with di
20$:
	inc	ax				;up count
	call	VMCheckBlkHandle
	tst	ds:[di].VMFBH_fileSize.low	;unassigned?
	jnz	ok
	tst	ds:[di].VMFBH_fileSize.high
	ERROR_NZ	VM_BAD_UNASSIGNED_LIST
ok:
	mov	di, ds:[di].VMFBH_nextPtr	;move on to next
	tst	di
	jne	20$

checkCount:
	cmp	ds:[VMH_numUnassigned], ax
	ERROR_NE	VM_BAD_UNASSIGNED_COUNT
	pop	ax
done:
	popf
	ret
VMCheckUnassignedList	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckUsedBlks

DESCRIPTION:	Check to see that the VMH_usedBlks count is correct.

CALLED BY:	INTERNAL (VMCheckStrucs)

PASS:		ds - VM header

RETURN:		nothing, dies if assertions fail

DESTROYED:	di, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMCheckUsedBlks	proc	near
	pushf
	call	CheckNormalECEnabled
	jz	exit
	push	ax
	clr	ax				;use ax to count used blks
	mov	di, ds:[VMH_lastHandle]
10$:
	sub	di, size VMBlockHandle
	cmp	di, offset VMH_blockTable
	jb	done
	test	ds:[di].VMBH_sig, VM_IN_USE_BIT
	jz	10$
	cmp	ds:[di].VMBH_sig, VMBT_DUP
	jb	10$
	inc	ax
	tst	ds:[di].VMBH_fileSize
	jz	noFileSpace
	tst	ds:[di].VMBH_filePos.low
	jnz	10$
	tst	ds:[di].VMBH_filePos.high
	jnz	10$
choke:
	ERROR	VM_BAD_HDR
noFileSpace:
	tst	ds:[di].VMBH_filePos.low
	jnz	choke
	tst	ds:[di].VMBH_filePos.high
	jnz	choke
	jmp	10$
done:
	cmp	ds:[VMH_numUsed], ax		;used count ok?
	ERROR_NE	VM_BAD_USED_COUNT
	pop	ax
exit:
	popf
	ret
VMCheckUsedBlks	endp


if 0	; flagged as unused 12/21/89 -- ardeb
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCountBlks

DESCRIPTION:	Count all the blocks and see that it matches the total
		of numAssigned, numUnassigned and numUsed.

CALLED BY:	INTERNAL (VMCheckStrucs)

PASS:		ds - VM header

RETURN:		nothing, dies if assertions fail

DESTROYED:	bx, di, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMCountBlks	proc	near
	pushf
	call	CheckNormalECEnabled
	jz	90$
	clr	bx				;bx will be used to count
	mov	di, VMH_blockTable
	mov	si, ds:[VMH_lastHandle]
10$:
	inc	bx
	add	di, size VMBlockHandle
	cmp	di, si
	jne	10$

	mov	di, ds:[VMH_numAssigned]
	add	di, ds:[VMH_numUnassigned]
	add	di, ds:[VMH_numUsed]
	cmp	bx, di
	je	90$
	ERROR	VM_BAD_TOTAL_COUNT
90$:
	popf
	ret
VMCountBlks	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckFileHandle

DESCRIPTION:	Sees that the VM file handle is valid.

CALLED BY:	INTERNAL

PASS:		bx - VM file handle

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	assert HF_otherInfo <> 0
	assert sig(VM handle) = SIG_VM

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMCheckFileHandle	proc	far	uses ds, bp
	.enter
	pushf		;Added 7/25/93 - atw
	call	ECCheckFileHandle

	LoadVarSeg	ds
	mov	bp, ds:[bx][HF_otherInfo]

	call	VMCheckVMHandle
	popf
	.leave
	ret
VMCheckFileHandle	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckVMHandle

DESCRIPTION:	Checks to see that the handle given is a VM handle.

CALLED BY:	INTERNAL

PASS:		bp - VM handle

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMCheckVMHandle	proc	far
	pushf			;Added 7/25/93 - atw
	push	ds
	LoadVarSeg	ds
	cmp	ds:[bp].HG_type, SIG_VM
	ERROR_NE	VM_ERR_NOT_VM_HANDLE
	pop	ds
	popf
	ret
VMCheckVMHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMCheckVMAndFileHandleAndDSKdata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure passed a valid FILE and VM handle, and that DS
		actually points to idata

CALLED BY:	INTERNAL
PASS:		bx	= file handle
		bp	= VM handle
		ds	= idata
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMCheckVMAndFileHandleAndDSKdata	proc	far
		.enter
		call	AssertDSKdata
		call	VMCheckVMHandle
		call	VMCheckFileHandle
		.leave
		ret
VMCheckVMAndFileHandleAndDSKdata	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckHeaderHandle

DESCRIPTION:

CALLED BY:	INTERNAL

PASS:		si - VM mem handle

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMCheckHeaderHandle	proc	far
	uses	ds, di
	.enter
	call	VMCheckMemHandle

	LoadVarSeg	ds
	mov	di, ds:[si][HM_owner]		;assert owner = VM handle
	cmp	ds:[di].HVM_headerHandle, si
	ERROR_NE	VM_BAD_MEM_HAN
	.leave
	ret
VMCheckHeaderHandle	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckMemHandle

DESCRIPTION:	Checks to see that the owner of the VM block has the
		VM signature.

CALLED BY:	INTERNAL

PASS:		si - VM mem handle

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMCheckMemHandle	proc	near
	uses	ds, bp
	.enter
	tst	si				;handle must be non 0
	ERROR_Z	VM_BAD_MEM_HAN
	LoadVarSeg	ds
	mov	bp, ds:[si][HM_owner]		;assert owner = VM header handle
	call	VMCheckVMHandle
	.leave
	ret
VMCheckMemHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMCheckUsedBlkHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed VM block handle is legal and actively
		in-use (VMBT_DUP or VMBT_USED)

CALLED BY:	INTERNAL
PASS:		ds	= VM header
		di	= handle to check
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMCheckUsedBlkHandle proc far
		.enter
		call	VMCheckBlkHandle
		tst	di
		jnz	10$
error:
		ERROR	VM_HANDLE_NOT_IN_USE

10$:
		test	ds:[di].VMBH_sig, VM_IN_USE_BIT
		jz	error
		cmp	ds:[di].VMBH_sig, VMBT_DUP
		jb	error
		.leave
		ret
VMCheckUsedBlkHandle endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckBlkHandle

DESCRIPTION:	Sees that the VM block handle falls within legal bounds.

CALLED BY:	INTERNAL (error checking utility)

PASS:		ds - VM header
		di - VM block handle (offset from ds, may be 0)

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMCheckBlkHandle	proc	far
	tst	di
	je	90$		;no check if nil
	cmp	di, offset VMH_blockTable
	ERROR_B	VM_BAD_BLK_HAN

	cmp	di, ds:[VMH_lastHandle]	;offset must be less than size of header
	ERROR_AE	VM_BAD_BLK_HAN

	call	VMCheckBlkHanOffset	;assert legal offset
90$:
	ret
VMCheckBlkHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMCheckBlkHandleAndDSHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure DS is a valid VM header and DI, a valid VM block
		handlle

CALLED BY:	INTERNAL
PASS:		ds	= VM Header
		di	= VM block handle
RETURN:		nothing
DESTROYED:	flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMCheckBlkHandleAndDSHeader proc near
		.enter
		call	VMCheckDSHeader
		call	VMCheckBlkHandle
		.leave
		ret
VMCheckBlkHandleAndDSHeader endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckBlkHanOffset

DESCRIPTION:	In the absence of ds = VM header, checks to see that
		the block handle is a legal offset into the VM header block.

CALLED BY:	INTERNAL

PASS:		di - VM block handle

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	assert offset falls on block handle boundaries

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMCheckBlkHanOffset	proc	far	uses ax, dx, di
	.enter
	sub	di, offset VMH_blockTable;adjust
	mov	ax, size VMBlockHandle
	xchg	ax, di			;dx:ax <- di
	clr	dx
	div	di			;dx:ax / blk handle size
	tst	dx			;confirm remainder = 0
	ERROR_NZ	VM_BAD_BLK_HAN
	.leave
	ret
VMCheckBlkHanOffset	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCheckDSHeader

DESCRIPTION:	Asserts that ds = VM header.

CALLED BY:	INTERNAL

PASS:		ds - VM header

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	assert legal VM hdr handle
	assert es = han_addr(hdr handle)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMCheckDSHeader	proc	far	uses ax, cx, si, es, di, dx
	.enter
	cmp	ds:[VMH_headerSig], VM_HDR_SIG
	ERROR_NE	VM_BAD_HDR
	mov	di, ds:[VMH_assignedPtr]
	tst	di
	jne	10$
	tst	ds:[VMH_lastAssigned]
	ERROR_NE	VM_BAD_HDR
	jmp	15$

10$:
	call	VMCheckBlkHanOffset
15$:
	mov	di, ds:[VMH_unassignedPtr]
	tst	di
	je	20$
	call	VMCheckBlkHanOffset
20$:
	LoadVarSeg	es
	mov	di, ds:[VMH_lastHandle]
	clr	cx, dx
30$:
	sub	di, size VMBlockHandle
	cmp	di, offset VMH_blockTable
	jb	done
	test	ds:[di].VMBH_sig, VM_IN_USE_BIT
	jz	30$
	cmp	ds:[di].VMBH_sig, VMBT_DUP	; in-use?
	jb	30$
	mov	si, ds:[di].VMBH_memHandle	; in-use; in-core?
	tst	si
	jz	30$
	cmp	es:[handleBeingForceMoved], si
	je	flagForceMove

checkDiscarded:
	test	es:[si].HM_flags, mask HF_DISCARDED
	jnz	30$
	inc	cx				; count another resident
	jmp	30$

flagForceMove:
	inc	dx
	jmp	checkDiscarded

done:
	cmp	cx, ds:[VMH_numResident]
	je	ok
	ERROR_A		VM_BAD_HDR		; if we think more are
						;  resident, that's a problem
	add	cx, dx				; else add 1 if something was
						;  being force-moved
	cmp	cx, ds:[VMH_numResident]	; and check that sum
	ERROR_NE	VM_BAD_HDR		; if still off, then we're hosed
ok:
	.leave
	ret

VMCheckDSHeader	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	AssertESKdata

DESCRIPTION:	Assert that es = idata.

CALLED BY:	INTERNAL

PASS:		es

RETURN:		nothing, dies if assertion fails

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

AssertESKdata	proc	far
	push	ax
	mov	ax, es
	cmp	ax, idata
	ERROR_NE	VM_ERR
	pop	ax
	ret
AssertESKdata	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMVerifyWrite

DESCRIPTION:	Verifies the write operation.

CALLED BY:	INTERNAL (VMWriteBlk)

PASS:		es - idata seg
		bx - VM file handle
		si - VM header handle
		ds - VM header
		di - VM block handle
		bp - VM mem handle of blk to be written out
		dx - segment address of block just written

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	retrieve block storage data
	read block into buffer
	compare data in memory block with data in buffer

	reg usage:
		es:di will be used to address VM block in memory
		ds:si will be used to address buffer

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Currently verifies a maximum of VM_VERIFY_NUM_BYTES bytes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMVerifyWrite	proc	near
	call	AssertESKdata
	test	es:[sysECLevel], mask ECF_VMEM
	jz	done
	
	call	PushAll
	call	VMCheckFileHandle
	call	VMCheckMemHandle
	call	VMCheckDSHeader
	call	VMCheckBlkHandle

if COMPRESSED_VM
	; Can't do data comparison because the data on disk is compressed.
	
	test	ds:[di].VMBH_flags, mask VMBF_COMPRESSED
	jnz	popAll
endif

	cmp	bp, ds:[di].VMBH_memHandle	;confirm mem handle
	jne	badWrite

	mov	es, dx				;save block segment in ES
						; for later use

	mov	cx, ds:[di].VMBH_filePos.high
	mov	dx, ds:[di].VMBH_filePos.low

	mov	al, FILE_POS_START
	call	FilePosFar
	mov	cx, ds:[di].VMBH_fileSize	;cx <- num bytes

	cmp	cx, VM_VERIFY_NUM_BYTES
	jbe	20$
	mov	cx, VM_VERIFY_NUM_BYTES
20$:
	sub	sp, cx				;make room for the buffer
	mov	dx, sp				; on the stack
	segmov	ds, ss				;ds:dx = buffer
	clr	al
	;
	; For the same reason that we use FileWriteNoCheck in
	; VMDoWriteBlk, we use FileReadNoCheck here
	;

EC <	call	FileReadNoCheckFar				>
NEC <	call	FileRead					>
	jc	badWrite

	mov	si, dx				;point ds:si at buffer
	clr	di
	mov	ax, cx				;save # bytes for stack clear
	shr	cx, 1				;get number of words to compare
	repe	cmpsw
	jne	badWrite

	add	sp, ax				;remove buffer from stack
popAll::
	call	PopAll
done:
	ret

badWrite:
	ERROR	VM_BAD_WRITE

VMVerifyWrite	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMVerifyUseBlk

DESCRIPTION:	Traverses assigned list to ensure that no assigned block
		overlaps that block that has been assigned.

CALLED BY:	INTERNAL

PASS:		ds - VM header
		di - Used VM block handle
		cx:dx - file pos of allocated block

RETURN:

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMVerifyUseBlk	proc	near	uses ax, bx, si
	.enter
	pushf
	call	CheckNormalECEnabled
	jz	90$
	call	VMCheckDSHeader
	call	VMCheckBlkHandle
	tst	ds:[di].VMBH_fileSize
	je	90$

	mov	si, ds:[VMH_assignedPtr]		;get head of assigned
10$:
	tst	si					;at end?
	je	90$				;branch if so
	mov	bx, ds:[si].VMFBH_filePos.low
	mov	ax, ds:[si].VMFBH_filePos.high
	cmp	ax, cx	;equal?
	jne	20$
	cmp	bx, dx
	je	vmErr
20$:
	ja	50$
	;-----------------------------------------------------------------------
	;file pos of assigned block < file pos of block
	;see that last pos of assigned block < file pos of block

	add	bx, ds:[si].VMFBH_fileSize.low
	adc	ax, ds:[si].VMFBH_fileSize.high
	cmp	cx, ax
	jne	30$
	cmp	dx, bx
30$:
	jb	vmErr
	jmp	80$				;on to next

50$:
	;-----------------------------------------------------------------------
	;file pos of assigned block > file pos of block
	;see that last pos of block < file pos of assigned block
	;(equivalently, assigned - used size >= pos of used)

	sub	bx, ds:[di].VMBH_fileSize
	sbb	ax, 0
	cmp	cx, ax
	jne	60$
	cmp	dx, bx
60$:
	ja	vmErr
80$:
	mov	si, ds:[si].VMFBH_nextPtr
	jmp	short 10$
90$:
	popf
	.leave
	ret

vmErr:
	ERROR	VM_NEWLY_USED_BLOCK_OVERLAPS_FREE_BLOCK

VMVerifyUseBlk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMCheckHeaderDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the header is dirty.

CALLED BY:	INTERNAL (VMMarkBlkUsed)
PASS:		ds	= VM header to check
		es	= idata
RETURN:		nothing
DESTROYED:	flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMCheckHeaderDirty proc	near	uses si
		.enter
		mov	si, ds:[VMH_blockTable].VMBH_memHandle
		test	es:[si].HM_flags, mask HF_DISCARDABLE
		ERROR_NZ	VM_HEADER_SHOULD_BE_DIRTY
		.leave
		ret
VMCheckHeaderDirty endp

ENDIF			;*******************************************************

kcode	ends
