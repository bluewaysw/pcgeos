COMMENT @----------------------------------------------------------------------

  Copyright (c) 1999-2000 Breadbox Company Company -- All Rights Reserved

PROJECT:	GEOS-PM
MODULE:		Loader
FILE:		gpmi.asm

ROUTINES:
	Name			Description
	----			-----------
   	GPMIStartup		Start GPMI and protected mode
	GPMIAllocateBlock	Create a block with a descriptor
	GPMIFreeBlock		Free a block pointed at by a descriptor
	GPMIResizeBlock		Resize a block pointed at by a descriptor
	GPMIAlias		Create an read/write alias to an existing 
				descriptor
	GPMIFreeAlias		Remove an existing alias
	GPMIConvertToCodeBlock	Make a data block a code block
	GPMIAccessRealSegment	Convert a segment in real mode to a descriptor
	GPMIGetExceptionHandler	Determine address of exception handler
	GPMISetExceptionHandler	Change address of exception handler
	GPMIGetInterruptHandler	Determine address of INT handler
	GPMISetInterruptHandler	Change address of INT handler
	GPMIMapPhysicalAddress	Create descriptor pointing to specific address
	GPMIMapRealSegment	Create descriptor pointing to real-mode segment
	GPMIGetDescriptor	Read the 8 byte internal descriptor (!!!)
	GPMISetDescriptor	Write the 8 byte internal descriptor (!!!)
	GPMIGetInfo		Get various GPMI stats
	GPMIMakeNotPresent	Delete a block but keep its selector around
	GPMIMakePresent		Allocate a block previously made not present
	GPMIAllocateNotPresentBlock	Allocate a block with no data
        GPMIGetLimit            Get the limit on a descriptor
        GPMISelectorGetLimit    Return the limit on a descriptor
        GPMISelectorCheckLimits Determine if the given limits fit in any descriptor

        GPMIAllocDMABuffer      Get a 16K DMA buffer
        GPMIFreeDMABUffer       Free a 16K DMA buffer

	GPMIReleaseSegmentAccess

	GPMIRealInterrupt
	GPMIAllocateDOSBlock	Create a DOS block with a descriptor
	GPMIFreeDOSBlock	Free a block pointed at by a descriptor


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/15		Initial version

DESCRIPTION:
	Routines to provide an interface between DPMI services and
	GEOS.  Also handles extensive memory allocation methods.

	$Id: gpmi.asm$
------------------------------------------------------------------------------@

include gpmi.def
include Internal\gpmiInt.def

.386
; -------------------------------------------------------------------------
;   Global CS segment variables used
; -------------------------------------------------------------------------
; Real mode entry to call to switch between real mode to protected mode
DPMIEntry		fptr

; Data selector to GPMIData that starts with the real mode segment
; but changes to a protected mode selector by IGPMIFixupDataSelector
GPMI_dataSelector	word	0


; -------------------------------------------------------------------------
;   GPMIData Block
; -------------------------------------------------------------------------
;GPMIData segment para public 'BSS';
;	; The following selector array is designed so that for each selector,
;	; there is one entry.  Each entry is one for one.
;	GPMI_selectorArray	GPMISelector	GPMI_NUM_SELECTORS dup(<?>)
;GPMIData ends


; -------------------------------------------------------------------------
;   Global Vector table to all exported routines
; -------------------------------------------------------------------------
; The following is the vector table.  It has been placed in its own segment
; so that other protected mode programs can just indirectly call routine
; via a [Routine Number * 4] reference.  Note that this list starts out
; with the wrong selectors because it is compiled as segments in real mode.
; This is modified by GPMIStartup to correct locations.

GPMIVectorTable	fptr \
                GPMIStartupWithCaller,
		GPMIAllocateBlock, 
		GPMIFreeBlock,
		GPMIResizeBlock,
		GPMIAlias,
		GPMIFreeAlias,
		GPMIConvertToCodeBlock,
		GPMIAccessRealSegment,
		GPMIGetExceptionHandler,
		GPMISetExceptionHandler,
		GPMIGetInterruptHandler,
		GPMISetInterruptHandler,
		GPMIMapPhysicalAddress,
		GPMIMapRealSegment,
		GPMIGetDescriptor,
		GPMISetDescriptor,
		GPMIGetInfo,
		GPMIMakeNotPresent,
		GPMIMakePresent,
		GPMIAllocateNotPresentBlock,
                GPMIIsSelector16Bit,
                GPMISelectorGetLimit,
                GPMISelectorCheckLimits,
		GPMITestPresent,
		GPMIUnmapRealSegment,
		GPMIReleaseSegmentAccess,
		GPMIRealInterrupt,
		GPMIAllocateDOSBlock,
		GPMIFreeDOSBlock,
		GPMIRealModeCallback,
		GPMIFreeRealModeCallback,
		0  ; Last one must be a null pointer (to mark end of table)

; Given a selector, find the offset to the GPMISelector in 
; GPMI_selectorArray
SelectorToOffset	macro	selector
			and selector, SELECTOR_INDEX_MASK
			endm

; Grab the data selector and put into the DS register
IGPMIGetDataSelector	macro
	push	ax
	mov	ax, cs:GPMI_dataSelector
	mov	ds, ax
	pop	ax
	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIStartup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the rites of initiation for entering protected mode
CALLED BY:	LoadGeos (?)
PASS:		es	= segment to fixup to selector (or 0 for none)
		ds	= segment to fixup to selector (or 0 for none)
RETURN:		ax	= number of descriptors allocated
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Check for DPMI
	Go into protected mode
	Allocate a table of descriptors (empty)
	Set the default exception handlers
	Transfer control to the start routine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/14/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GPMIStartupWithCaller   proc far
        call    GPMIStartup
        jc      failed

        ; We need to create a selector for a our caller
        pop     ax      ; calling offset
	pop     bx      ; calling segment
	push	cx
	mov	cx, 0ffffh
        call    GPMIMapRealSegment
                        ; bx = segment -> selector
	pop	cx
	push    bx      ; calling selector
        push    ax      ; calling offset

        ; Before we return, we need to make sure we are executing in code space
        call    GPMIConvertToCodeBlock

        mov     bx, cs  ; bx = cs        
failed:
        ret
GPMIStartupWithCaller   endp

GPMIStartup	proc near
if LOAD_DOS_EXTENDER
	; Load the dos extender
	call	GPMILoadDOSExtender
endif

	; Now go into protected mode
	mov     ax, 1687h
	int     2Fh
	test    ax, ax
	jnz     failed
	mov     cs:[DPMIEntry.offset], di
	mov     cs:[DPMIEntry.segment], es

	; Make sure our DPMIBuffer is big enough
	test    si, si
	jz      enterPM

	cmp	si, size DPMIBuffer/16
	ja	failed
	mov	ax, segment DPMIBuffer
	mov	es, ax

enterPM:
	; go into PM
	xor     ax, ax
	call    cs:[DPMIEntry]
	jc      failed

	; Determine where GPMIMemory is in memory
	call	IGPMIFixupDataSelector

	; Initialize that table
	call	IGPMIInitDescriptorTable

	clc
	ret

failed:
	stc
	ret
GPMIStartup	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIQueryStarted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the GPMI has started
CALLED BY:	LoadGeos (?)
PASS:		
RETURN:		zero flag = set if started, else false
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Check for DPMI
	Go into protected mode
	Allocate a table of descriptors (empty)
	Set the default exception handlers
	Transfer control to the start routine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/14/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GPMIQueryStarted   proc far
	; If the data selector isn't zero, then we have started
	mov	ax, cs:GPMI_dataSelector
	test	ax, 0xFFFF
	ret
GPMIQueryStarted   endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIAllocateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a data block of memory.
CALLED BY:	Loader, Kernel
PASS:		bx:cx	= block size
RETURN:		bx	= descriptor to new memory block (0 if failed)
		carry	= clear if success, else set
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Remove a descriptor from the free pool
		Allocate a block of linear memory
		Assign that block to the descriptor

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/14/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIAllocateBlock	proc far
	uses	ds, ax, cx, dx, si, di
blockSize	local	dword
selector	local	word
	.enter
	movdw	blockSize, bxcx
	IGPMIGetDataSelector

	; We need a selector for the block
	call	IGPMIAllocateDescriptor
	jc	failed

	; Hold onto that descriptor
	mov	selector, ax

	; Allocate the memory block
	; -- bx:cx is the size of the block to allocate
	mov	ax, DPMI_FUNC_ALLOCATE_MEMORY_BLOCK
	int	31h
	jc	allocFailed

	; NOTE:  At this point si:di has the 32-bit block handle

	; Change the base and limit of the selector
	; Base first
	mov	dx, cx
	mov	cx, bx
	mov	bx, selector
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_BASE
	int	31h

	; Now the limit
	movdw	cxdx, blockSize
	decdw	cxdx
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_LIMIT
	int	31h

	; Now we have a selector and a block of data
	; Associate the information and store in the list
	; NOTE:  At this point si:di has the 32-bit block handle
	mov	ax, selector
	SelectorToOffset	ax
	xchg	ax, si
	mov	[si].GPMIS_type, GPMI_SELECTOR_TYPE_MEMORY

	; Store ax:di (32 bit handled from DPMI)
	mov	[si].GPMIS_data1, ax
	mov	[si].GPMIS_data2, di
	andnf	[si].GPMIS_flags, not mask GPMISF_isCode

	; Get the descriptor in bx and return with positive status
	mov	bx, selector
	clc
	jmp	done

allocFailed:
	; Selector was created, but alloc failed.  Free descriptor
	mov	bx, selector
	call	IGPMIFreeDescriptor
	; Fall through
failed:
	clr	bx
	stc
done:
	.leave
	ret
GPMIAllocateBlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIAllocateNotPresentBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a data block of memory.
CALLED BY:	Loader, Kernel
PASS:		bx:cx	= block size
RETURN:		bx	= descriptor to new memory block (0 if failed)
		carry	= set if success, else clear
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Allocate a descriptor
	Set the limit on it
	Mark it as not present
	Change our table to match

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/18/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIAllocateNotPresentBlock	proc far
	uses	ds, ax, cx, dx, si, di, es
blockSize	local	dword
selector	local	word
descriptor	local	8 dup(byte)
	.enter
	movdw	blockSize, bxcx
	IGPMIGetDataSelector

	; We need a selector for the block
	call	IGPMIAllocateDescriptor
	jc	failed

	; Hold onto that descriptor
	mov	selector, ax

	; Change the size of the limit (even though we don't have any)
	movdw	cxdx, blockSize
	decdw	cxdx
	mov	bx, selector
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_LIMIT
	int	31h

	; Mark the descriptor now as not present
	segmov	es, ss
	lea	di, descriptor
	mov	bx, selector
	mov	ax, DPMI_FUNC_GET_DESCRIPTOR
	int	31h
	jc	failed

	; Modify bits in the 5th byte (which really doesn't have a name --
	;     perhaps Access rights is best)
	; Turn off the Present bit
	mov	al, descriptor+5
	andnf	al, 0x7F
	mov	descriptor+5, al

	mov	bx, selector
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR
	int	31h

	; Now we have a selector and a block of data
	; Associate the information and store in the list
	mov	ax, selector
	SelectorToOffset	ax
	xchg	ax, si
	mov	[si].GPMIS_type, GPMI_SELECTOR_TYPE_NOT_PRESENT

	; Setup the table as a not present data block
	clr	[si].GPMIS_data1
	clr	[si].GPMIS_data2
	andnf	[si].GPMIS_flags, not mask GPMISF_isCode
	ornf	[si].GPMIS_flags, mask GPMISF_isNotPresent

	; Get the descriptor in bx and return with positive status
	mov	bx, selector
	clc
	jmp	done

failed:
	clr	bx
	stc
done:
	.leave
	ret
GPMIAllocateNotPresentBlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a block of memory.
CALLED BY:	Loader, Kernel
PASS:		bx	= block descriptor
RETURN:		carry	= cleared if success, else set
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Free the block of memory assigned to the descriptor
		Return the descriptor to the free pool

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/14/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIFreeBlock	proc far
	uses	ds, ax, si, bx, cx, di
	.enter
	
	IGPMIGetDataSelector

	; Get the handle previously stored in the table
	; and mark it free (no matter what)
	mov	si, bx
	SelectorToOffset	si

	; Only free if it was allocated
	test	[si].GPMIS_flags, mask GPMISF_allocated
	jz	failed

	; Only free if it is a normal memory block or not present
	cmp	[si].GPMIS_type, GPMI_SELECTOR_TYPE_MEMORY
	je	freeBlock

	cmp	[si].GPMIS_type, GPMI_SELECTOR_TYPE_NOT_PRESENT
	jne	failed
	
freeBlock:
	; Clear out the info on this block while grabbing
	; the previously stored 32-bit DPMI block handle.
	mov	ax, [si].GPMIS_data1
	mov	di, [si].GPMIS_data2
	clr	[si].GPMIS_data1
	clr	[si].GPMIS_data2
	andnf	[si].GPMIS_flags, not mask GPMISF_allocated

	; Now do the actual free
	mov	si, ax
	mov	ax, DPMI_FUNC_FREE_MEMORY_BLOCK
	int	31h
	jc	failed

freeSelector:
	call	IGPMIFreeDescriptor

	; Free seemed to work ok
	clc
	jmp	done

failed:
	stc
done:
	.leave
	ret
GPMIFreeBlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIResizeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the size of a previously allocated block.
CALLED BY:	Loader, Kernel
PASS:		bx	= descriptor
		cx:dx	= new size of block
RETURN:		carry	= clear if success, else set if failed
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Find the selector in the GPMISelector table
	Check to see that it is allocated
	Call DPMI to resize the block
	Report result		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIResizeBlock	proc far
	uses	ax, bx, cx, si, di, ds
selector	local	word	push bx
blockSize	local	dword	push cx, dx	; (think about it)
	.enter
	IGPMIGetDataSelector
	mov	si, bx
	SelectorToOffset si
	test	[si].GPMIS_flags, mask GPMISF_allocated
	je	failed
	mov	ax, [si].GPMIS_data1
	mov	di, [si].GPMIS_data2
	mov	bx, cx
	mov	cx, dx
	mov	si, ax
	mov	ax, DPMI_FUNC_RESIZE_MEMORY_BLOCK
	int	31h
	jc	done

	; NOTE:  At this point si:di has the NEW 32-bit block handle

	; Change the base and limit of the selector
	; Base first
	mov	dx, cx
	mov	cx, bx
	mov	bx, selector
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_BASE
	int	31h

	; Now the limit
	movdw	cxdx, blockSize
	decdw	cxdx
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_LIMIT
	int	31h

	; Now we have a selector and a block of data
	; Associate the information and store in the list
	; NOTE:  At this point si:di has the 32-bit block handle
	mov	ax, selector
	SelectorToOffset	ax
	xchg	ax, si

	; Store ax:di (32 bit handled from DPMI)
	mov	[si].GPMIS_data1, ax
	mov	[si].GPMIS_data2, di

done:
	.leave
	ret
failed:
	stc
	jmp	done
GPMIResizeBlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIAlias
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup a full read/write access descriptor for a given
		descriptor.  MUST BE A CODE SEGMENT TO WORK.
CALLED BY:	Loader, Kernel
PASS:		bx	= descriptor
RETURN:		bx	= new aliased descriptor
		carry	= clear if success, else set if failed
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Tell DPMI to make an alias selector
	Mark in the table that the selector is used as an alias

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIAlias	proc far
	uses	ax, si, ds
	.enter

	IGPMIGetDataSelector

	; Create the alias in DPMI
	push	bx
	mov	ax, DPMI_FUNC_CREATE_CODE_DESCRIPTOR_ALIAS
	int	31h
	jc	failed

	; Modify the table entry by declaring an alias and storing
	; the selector that is being aliased.
	mov	bx, ax
	mov	si, ax
	SelectorToOffset si
	mov	[si].GPMIS_type, GPMI_SELECTOR_TYPE_ALIAS
	pop	ax
	mov	[si].GPMIS_data1, ax
	jmp	done
failed:
	pop	bx
done:
	.leave
	ret
GPMIAlias	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIFreeAlias
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy a previously created alias
CALLED BY:	Loader, Kernel
PASS:		bx	= descriptor to alias
RETURN:		carry	= clear if success, else set if failed
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Check to see that this is really an alias
	Free it from DPMI

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIFreeAlias	proc far
	uses	cx, bx, si, ds
	.enter

	IGPMIGetDataSelector

	; Make sure this is an alias we are trying to free (and not
	; anything else)
	mov	si, bx
	mov	cx, bx
	SelectorToOffset si
	mov	bl, [si].GPMIS_type
	cmp	bl, GPMI_SELECTOR_TYPE_ALIAS
	jne	failed

	; Do the actual free now
	mov	bx, cx
	call	IGPMIFreeDescriptor
	jmp	done
failed:
	stc
done:
	.leave
	ret
GPMIFreeAlias	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIRealModeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates an real mode address that is forwarded to a
			protected mode callback to be supplied to interrupts.
CALLED BY:	Loader, Kernel
PASS:		DS:ESI = selector:offset of protected mode procedure to call
			ES:EDI = selector:offset of 32H-byte buffer for real mode 
			         register data structure to be used when calling 
			         callback routine.
RETURN:		CX:DX = segment:offset of real mode callback
			carry	= clear if success, else set if failed
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Let GPMI create a real mode callback alias

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	12/5/2009	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIRealModeCallback	proc far
	uses	ax
	.enter
	mov	es, cx
	mov	di, dx
	mov	ax, DPMI_FUNC_ALLOCATE_REAL_MODE_CALLBACK
	int	31h
	.leave
	ret
GPMIRealModeCallback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIFreeRealModeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy a previously created alias
CALLED BY:	Loader, Kernel
PASS:		bx	= descriptor to alias
RETURN:		carry	= clear if success, else set if failed
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Check to see that this is really an alias
	Free it from DPMI

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIFreeRealModeCallback	proc far
	uses	cx, bx, si, ds
	.enter

	IGPMIGetDataSelector

	; Make sure this is an alias we are trying to free (and not
	; anything else)
	mov	si, bx
	mov	cx, bx
	SelectorToOffset si
	mov	bl, [si].GPMIS_type
	cmp	bl, GPMI_SELECTOR_TYPE_ALIAS
	jne	failed

	; Do the actual free now
	mov	bx, cx
	call	IGPMIFreeDescriptor
	jmp	done
failed:
	stc
done:
	.leave
	ret
GPMIFreeRealModeCallback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIConvertToCodeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a previously allocated data block a code block
CALLED BY:	Loader, Kernel
PASS:		bx	= descriptor to make a code block
RETURN:		carry	= clear if success, else set if failed
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Setup a bit of memory on the stack
	Get the 8 byte descriptor for the given selector
	Modify the few flags necessary
	Put back out the 8 byte descriptor
	Mark the block as code in our internal table
	Return fail/success status
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIConvertToCodeBlock	proc far
	uses	ax, bx, es, di, ds
descriptor	local	8 dup(byte)
selector	local	word
	.enter
	mov	selector, bx
	segmov	es, ss
	lea	di, descriptor
	mov	ax, DPMI_FUNC_GET_DESCRIPTOR
	int	31h
	jc	skip		; Failed, just quit here

	; Modify bits in the 5th byte (which really doesn't have a name --
	;     perhaps Access rights is best)
	; Turn on Code block type
	; Turn off expand down blocks
	; Turn on read access for block
	mov	al, descriptor+5
	andnf	al, not 0x0E
	ornf	al, 0x0A
	mov	descriptor+5, al

	; Make sure the D Bit that controls if code segments are 16-bit
	; or 32-bit instructions is set to 16-bit by default (cleared bit)
	mov	al, descriptor+6
	andnf	al, 0xBF
	mov	descriptor+6, al

	mov	bx, selector
	lea	di, descriptor
	segmov	es, ss
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR
	int	31h
	jc	skip

        push    bx
	SelectorToOffset	bx
	IGPMIGetDataSelector
	ornf	[bx].GPMIS_flags, mask GPMISF_isCode
        pop     bx
	clc
skip:
	.leave
	ret
GPMIConvertToCodeBlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIAccessRealSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a selector to a real-mode segment.
CALLED BY:	Loader, Kernel
PASS:		bx	= segment
RETURN:		bx	= descriptor
		carry	= clear if success, else set if failed
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Do the DPMI segment to descriptor call
	Store the type of selector in our table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Since we call DPMI_FUNC_SEGMENT_TO_DESCRIPTOR, the returned selector
	must not be subsequently modified or freed.  This means you!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIAccessRealSegment	proc far
	uses	ax, cx, si, ds
	.enter
	push	bx
	
	; Have DPMI create a segment based descriptor
	mov	ax, DPMI_FUNC_SEGMENT_TO_DESCRIPTOR
	int	31h
	jc	failure

        push    ax

	; If success, store this information in our table
	mov	bx, ax
	IGPMIGetDataSelector
	mov	si, bx
	SelectorToOffset si
	mov	[si].GPMIS_type, GPMI_SELECTOR_TYPE_REAL_SEGMENT

        pop     bx

	; Be sure to save the original segment in our table
	pop	[si].GPMIS_data1
	jmp	done
failure:
	pop	cx
done:
	.leave
	ret
GPMIAccessRealSegment	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIGetExceptionHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the protected mode address of the routine declared to 
		handle an exception fault.
CALLED BY:	Loader, Kernel
PASS:		bl	= GPMIExceptionType
RETURN:		cx:(e)dx= 6 byte address to routine
		carry clear if successful
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIGetExceptionHandler	proc far
	uses	ax
	.enter
	mov	ax, DPMI_FUNC_GET_EXCEPTION_HANDLER
	int	31h
	.leave
	ret
GPMIGetExceptionHandler	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMISetExceptionHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the protected mode address of the routine declared to 
		handle an exception fault.
CALLED BY:	Loader, Kernel
PASS:		bl	= GPMIExceptionType
		cx:(e)dx= 6 byte address to routine
RETURN:		carry clear if success, else set for failed.
		carry clear if successful
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMISetExceptionHandler	proc far
	uses	ax
	.enter
	mov	ax, DPMI_FUNC_SET_EXCEPTION_HANDLER
	int	31h
	.leave
	ret
GPMISetExceptionHandler	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIGetInterruptHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the protected mode address of the routine declared to 
		handle a software/hardware interrupt.
CALLED BY:	Loader, Kernel
PASS:		bl	= Interrupt number
RETURN:		cx:(e)dx= 6 byte address to routine
		carry clear if success, else set for failed.
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIGetInterruptHandler	proc far
	uses	ax
	.enter
	mov	ax, DPMI_FUNC_GET_PROTECTED_MODE_INTERRUPT_HANDLER
	int	31h
	.leave
	ret
GPMIGetInterruptHandler	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMISetInterruptHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the protected mode address of the routine declared to 
		handle a software/hardware interrupt.
CALLED BY:	Loader, Kernel
PASS:		bl	= Interrupt number
		cx:(e)dx= 6 byte address to routine
RETURN:		carry clear if success, else set for failed.
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMISetInterruptHandler proc far
	uses	ax
	.enter
	mov	ax, DPMI_FUNC_SET_PROTECTED_MODE_INTERRUPT_HANDLER
	int	31h
	.leave
	ret
GPMISetInterruptHandler endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIMapPhysicalAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a descriptor that maps to a particular area of
		physical memory.  Used mainly by device driveres that
		know where to work.
CALLED BY:	Loader, Kernel
PASS:		bx:cx	physical address
		si:di	size limit in bytes
RETURN:		bx	descriptor created to access that space, or 0 if none
		carry clear if success, else set for failed.
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/14/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIMapPhysicalAddress	proc far
	uses	ds, ax, cx, dx, si, di
blockSize	local	dword
physicalAddr	local	dword
selector	local	word
	.enter
	movdw	blockSize, sidi
	movdw	physicalAddr, bxcx

	IGPMIGetDataSelector

	; We need a selector for the block
	call	IGPMIAllocateDescriptor
	jc	failed

	; Hold onto that descriptor
	mov	selector, ax

	; Map the physical block
	; -- bx:cx is the size of the block to allocate
	movdw	bxcx, physicalAddr
	movdw	sidi, blockSize
	mov	ax, DPMI_FUNC_MAP_PHYSICAL_ADDRESS
	int	31h
	jc	allocFailed

	; Change the base and limit of the selector
	; Base first
	mov	dx, cx
	mov	cx, bx
	mov	bx, selector
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_BASE
	int	31h

	; Now the limit
	movdw	cxdx, blockSize
	decdw	cxdx
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_LIMIT
	int	31h

	; Now we have a selector and a block of data
	; Associate the information and store in the list
	mov	si, selector
	SelectorToOffset	si
	mov	[si].GPMIS_type, GPMI_SELECTOR_TYPE_PHYSICAL_ADDRESS

	; Store the physical address
	movdw	cxdx, physicalAddr
	mov	[si].GPMIS_data1, cx
	mov	[si].GPMIS_data2, dx
	andnf	[si].GPMIS_flags, not mask GPMISF_isCode

	; Get the descriptor in bx and return with positive status
	mov	bx, selector
	clc
	jmp	done

allocFailed:
	; Selector was created, but alloc failed.  Free descriptor
	mov	bx, selector
	call	IGPMIFreeDescriptor
	; Fall through
failed:
	clr	bx
	stc
done:
	.leave
	ret
GPMIMapPhysicalAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIMapRealSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a descriptor with a given limit that maps to the
		given real-mode	segment.  Used mainly by the stub during
		initialization to handle the switch to protected mode.

CALLED BY:	Loader, Kernel
PASS:		bx	real-mode segment
		cx	size limit in bytes
RETURN:		bx	selector to given location
		carry clear if success, else set for failed.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 11/16/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIMapRealSegment	proc	far
	uses	ax, cx, dx, si, ds
	.enter
	push	bx				; save segment
	IGPMIGetDataSelector

	; We need a selector for the block
	call	IGPMIAllocateDescriptor		; ax = new selector
	jc	failed
	mov	bx, ax				; bx = selector

	; Change the base and limit of the selector
	; Base first
	pop	dx				; dx = segment
	push	dx				; save it again
	push	cx				; save limit
	clr	cx
	shld	cx, dx, 4			; cx = upper nibble of segment
	shl	dx, 4				; cx:dx = logical address
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_BASE
	int	31h

	; Now the limit
	clr	cx
	pop	dx				; cx:dx = selector limit
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_LIMIT
	int	31h

	; Now we have a selector and a block of data
	; Associate the information and store in the list
	mov	si, bx
	SelectorToOffset	si
	mov	[si].GPMIS_type, GPMI_SELECTOR_TYPE_PHYSICAL_ADDRESS
	pop	[si].GPMIS_data1		; save segment
	andnf	[si].GPMIS_flags, not mask GPMISF_isCode

	; Return with positive status
	clc
done:
	.leave
	ret
failed:
	pop	bx
	jmp	done
GPMIMapRealSegment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIUnmapRealSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a selector previously allocated by GPMIMapRealSegment.

CALLED BY:	Kernel
PASS:		bx	real-mode segment
RETURN:		carry	= clear if success, else set if failed
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 1/17/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIUnmapRealSegment	proc	far
	uses	cx, bx, si, ds
	.enter

	IGPMIGetDataSelector

	; Make sure the selector is of the right type.
	mov	si, bx
	mov	cx, bx
	SelectorToOffset si
	mov	bl, [si].GPMIS_type
	cmp	bl, GPMI_SELECTOR_TYPE_PHYSICAL_ADDRESS
	jne	failed

	; Do the actual free now
	mov	bx, cx
	call	IGPMIFreeDescriptor
	jmp	done
failed:
	stc
done:
	.leave
	ret
GPMIUnmapRealSegment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIGetDescriptor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the descriptor from the LDT to the given memory
		location.  Should only be used for debugging purposes.
CALLED BY:	Loader, Kernel
PASS:		bx	= Selector to descriptor
		es:edi  = Address to 8 byte buffer for descriptor
RETURN:		carry clear if success, else set for failed.
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIGetDescriptor	proc far
	mov	ax, DPMI_FUNC_GET_DESCRIPTOR
	int	31h
	ret
GPMIGetDescriptor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMISetDescriptor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Overwrite the descriptor in the LDT from the given memory
		location.  Should only be used for debugging purposes.
CALLED BY:	Loader, Kernel
PASS:		bx	= Selector to descriptor
		es:edi  = Address to 8 byte buffer for descriptor
RETURN:		carry clear if success, else set for failed.
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/14/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMISetDescriptor	proc far
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR
	int	31h
	ret
GPMISetDescriptor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get various information about the state of the GPMI.
CALLED BY:	Loader, Kernel
PASS:		bx	= GPMIInfoType
RETURN:		carry clear if success, else set for failed.
		bx:cx   - Information returned
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/14/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIGetInfo	proc far
	uses ax, es, di
info	local	DPMIInfoStruct
	.enter
	cmp	bx, GPMI_INFO_SIZE_PAGE
	je	getPageSize

	; Read in the DPMI memory info structure
	lea	di, info
	segmov	es, ss
	mov	ax, DPMI_FUNC_GET_MEMORY_INFORMATION
	int	31h
	jc	done

	cmp	bx, GPMI_INFO_PHYS_MEM_TOTAL
	je	getPhysMemTotal
	cmp	bx, GPMI_INFO_PHYS_MEM_USED
	je	getPhysMemUsed
	cmp	bx, GPMI_INFO_LARGEST_FREE_BLOCK
	je	getLargestFree
	cmp	bx, GPMI_INFO_SIZE_NUM_LINEAR_PAGES
	je	getSizeNumLinearPages
	cmp	bx, GPMI_INFO_SIZE_PAGING_FILE
	je	getSizePagingFile

	; Bad GPMIInfoType
	stc
	jmp	done

getPhysMemTotal:
	mov	ax, DPMI_FUNC_GET_PAGE_SIZE
	int	31h
	; bx:cx page size in bytes

	movdw	bxcx, info.DPMIIS_totalPhysicalPages

	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx

	jmp	done

getPhysMemUsed:
	mov	ax, DPMI_FUNC_GET_PAGE_SIZE
	int	31h
	; bx:cx page size in bytes


	movdw	bxcx, info.DPMIIS_totalPhysicalPages
	subdw	bxcx, info.DPMIIS_numberPages


	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx
	shldw	bxcx

	jmp	done

getLargestFree:
	movdw	bxcx, info.DPMIIS_largestFreeBlock
	jmp	done

getSizeNumLinearPages:
	movdw	bxcx, info.DPMIIS_linearAddrSpaceInPages
	jmp	done

getSizePagingFile:
	movdw	bxcx, info.DPMIIS_sizePagingFilePages
	jmp	done

getPageSize:
	; Grab the page size from 
	mov	ax, DPMI_FUNC_GET_PAGE_SIZE
	int	31h
	jmp	done
done:
	.leave
	ret
GPMIGetInfo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIMakeNotPresent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Declare a memory block not present (and free the memory)
CALLED BY:	Loader, Kernel
PASS:		bx	= Selector to mark not present
RETURN:		carry clear if success, else set for failed.
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Make sure we are working on a standard memory block (not real or
		physical addresses, sorry)
	Free the memory currently attached
	Mark the bit on the selector not present

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If the get/set selector functions don't work, the block will be
	in a halfway state.  This should never occur unless a bad selector
	or a corrupt LDT has occurred (very unlikely).

	Also note that the selector will still keep info about where it
	was and a limit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/18/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIMakeNotPresent	proc	far
	uses	es, ds, ax, bx, cx, dx, si, di
descriptor	local	8 dup(byte)
selector	local	word
	.enter

	; Get access to this selector's information
	mov	selector, bx
	IGPMIGetDataSelector
	mov	si, bx
	SelectorToOffset	si

	; Only work on regular memory blocks (or code blocks)
	cmp	[si].GPMIS_type, GPMI_SELECTOR_TYPE_MEMORY
	jne	failed

	; Free the memory associated with it
	push	si
	mov	di, [si].GPMIS_data2
	mov	si, [si].GPMIS_data1
	mov	ax, DPMI_FUNC_FREE_MEMORY_BLOCK
	int	31h
	pop	si
	jc		failed

	; Fixup our table entry
	clr	[si].GPMIS_data1
	clr	[si].GPMIS_data2
	mov	[si].GPMIS_type, GPMI_SELECTOR_TYPE_NOT_PRESENT
	andnf	[si].GPMIS_flags, not mask GPMISF_allocated
	ornf	[si].GPMIS_flags, mask GPMISF_isNotPresent

	; Mark the descriptor now as not present
	segmov	es, ss
	lea	di, descriptor
	mov	bx, selector
	mov	ax, DPMI_FUNC_GET_DESCRIPTOR
	int	31h
	jc	failed		; Failed, just quit here

	; Modify bits in the 5th byte (which really doesn't have a name --
	;     perhaps Access rights is best)
	; Turn off the Present bit
	mov	al, descriptor+5
	andnf	al, 0x7F
	mov	descriptor+5, al

	mov	ax, DPMI_FUNC_SET_DESCRIPTOR
	int	31h
	jnc	done
failed:
	stc	
done:
	.leave
	ret
GPMIMakeNotPresent	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIMakePresent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Declare a memory block present and allocate memory for it.
		This also makes code blocks data blocks so that they can
		be filled with information (returning a flag on which type
		it was originally).
CALLED BY:	Loader, Kernel
PASS:		bx	= Selector to mark not present
		cx:dx	= new size of block
RETURN:		carry clear if success, else set for failed.
		ax = GPMI_MAKE_PRESENT_ORIGINALLY_DATA_BLOCK if data 
			selector, GPMI_MAKE_PRESENT_ORIGINALLY_CODE_BLOCK 
			if code selector originally
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Make sure we are working on a block that is not present
	Allocate the memory again
	Attach the memory to the descriptor
	Mark the block present and data (if it was code, the caller
		will have to work on that and convert the code over).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/18/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIMakePresent	proc	far
	uses	es, ds, bx, cx, dx, si, di
blockSize	local	dword	push cx, dx	; (think about it)
selector	local	word
selectorIndex	local	word
descriptor	local	8 dup(byte)
	.enter
	mov	selector, bx

	; Get access to this selector's information
	IGPMIGetDataSelector
	mov	si, bx
	SelectorToOffset	si
	mov	selectorIndex, si

	; Only work on regular memory blocks (or code blocks)
	cmp	[si].GPMIS_type, GPMI_SELECTOR_TYPE_NOT_PRESENT
	jne	failed

	; Get the descriptor (for the size)
	segmov	es, ss
	lea	di, descriptor
	mov	ax, DPMI_FUNC_GET_DESCRIPTOR
	int	31h
	jc	failed		; Failed, just quit here

	; Allocate the memory needed
	mov	bx, cx
	mov	cx, dx
	mov	ax, DPMI_FUNC_ALLOCATE_MEMORY_BLOCK
	int	31h
	jc	done

	; Fixup our table entry
	xchg	ax, si
	mov	si, selectorIndex
	mov	[si].GPMIS_data1, ax
	mov	[si].GPMIS_data2, di
	mov	[si].GPMIS_type, GPMI_SELECTOR_TYPE_MEMORY
	ornf	[si].GPMIS_flags, mask GPMISF_allocated
	andnf	[si].GPMIS_flags, not mask GPMISF_isNotPresent

	; Modify bits in the 5th byte (which really doesn't have a name --
	;     perhaps Access rights is best)
	; Turn on the Present bit
	mov	al, descriptor+5
	ornf	al, 0x80
	andnf	al, 0xF7	; Make data segment
	mov	descriptor+5, al

	; Put back the descriptor
	mov	dx, cx
	mov	cx, bx				; cx:dx = selector base
	mov	bx, selector			; bx = selector
	segmov	es, ss
	lea	di, descriptor
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR
	int	31h
	jc	done

	; Change the base address for this selector
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_BASE
	int	31h
	jc	done

	; Now the limit
	movdw	cxdx, blockSize
	decdw	cxdx
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_LIMIT
	int	31h

	; Was this a code block?  Report it to the caller
	mov	si, selectorIndex
	mov	ax, GPMI_MAKE_PRESENT_ORIGINALLY_DATA_BLOCK
	test	[si].GPMIS_flags, mask GPMISF_isCode	; carry clear
	jz	done
	
	; was a code segment.  Mark it not as code and return
	; a status saying it was code
	andnf	[si].GPMIS_flags, not mask GPMISF_isCode
	mov	ax, GPMI_MAKE_PRESENT_ORIGINALLY_CODE_BLOCK
	jmp	done
done:
	.leave
	ret
failed:
	stc
	jmp	done
GPMIMakePresent	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IGPMIInitDescriptorTable (internal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Startup the descriptor table with empty entries.
		Descriptors and blocks will be allocated as necessary.
CALLED BY:	Loader, Kernel
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/14/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGPMIInitDescriptorTable	proc near
	uses ax, cx, di, bx, ds
	.enter
	IGPMIGetDataSelector

	; Empty the table and store the default information
	mov	cx, GPMI_NUM_SELECTORS
	clr	di
fill_loop:
	mov	[di].GPMIS_type, GPMI_SELECTOR_TYPE_NOT_USED
	clr	[di].GPMIS_flags
	clr	[di].GPMIS_reserved
	clr	[di].GPMIS_data1
	clr	[di].GPMIS_data2
	add	di, size GPMISelector
	loop	fill_loop
	.leave
	ret
IGPMIInitDescriptorTable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IGPMIFixupDataSelector (internal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine where the segment selector for the GPMIData block
		is now in protected mode and change it in the CS memory.
CALLED BY:	Loader, Kernel
PASS:		Nothing
RETURN:		carry -- cleared when success, else set when failed
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Map the real data selector to a new data selector
	Make an alias to the code selector so we can modify near data
	Modify the near data variable GPMI_dataSelector
	Release the previous alias

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGPMIFixupDataSelector proc near
	uses	ax, bx, cx, dx, ds
selector	local	word
	.enter

	; Allocate a selector
	mov	ax, 0
	mov	cx, 1
	int	31h
	mov	selector, ax

	; Allocate a block of data for our GPMIData group
	mov	bx, 1
	mov	cx, 0
	mov	ax, DPMI_FUNC_ALLOCATE_MEMORY_BLOCK
	int	31h
	jc	failed

	; Set the base location of this block of data
	mov	dx, cx
	mov	cx, bx
	mov	bx, selector
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_BASE
	int	31h
	jc	failed

	; Set the limit on this block of data
	mov	cx, 1
	mov	dx, 0
	mov	ax, DPMI_FUNC_SET_DESCRIPTOR_LIMIT
	int	31h

	; Alias our own code segment so we can write there
	mov	bx, cs
	mov	ax, DPMI_FUNC_CREATE_CODE_DESCRIPTOR_ALIAS
	int	31h
	jc	failed

	; Store the data selector for easy referencing
	mov	ds, ax
	mov	ax, selector
	mov	ds:[GPMI_dataSelector], ax

	; Fixup the vector table to point to near pointers
	call	IGPMIFixupVectorTable

	; Now get rid of the alias of the code selector
	mov	bx, ds
	mov	ax, DPMI_FUNC_FREE_DESCRIPTOR
	int	31h

	; We are now done
	clc
	jmp done
failed:
	stc
done:
	.leave
	ret
IGPMIFixupDataSelector endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IGPMIFixupVectorTable (internal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change all the segment registers into the appropriate
		code selector in the VectorTable.
CALLED BY:	Loader, Kernel
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Loop through all the vector entries until a null segment is found.
	For each item, change the orignal segment into CS.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/18/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGPMIFixupVectorTable	proc	near
	uses	si
	.enter
	mov	si, offset GPMIVectorTable
nextVector:
	cmp	[si].segment, 0
	je	done
	mov	[si].segment, cs
	add	si, size fptr
	jmp	nextVector
done:
	.leave
	ret
IGPMIFixupVectorTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		 IGPMIAllocateDescriptor (internal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a GPMI descriptor
CALLED BY:	Loader, Kernel
PASS:		Nothing
RETURN:		carry	-- set if failed, else cleared
		ax	-- selector allocated
		ds	-- GPMIData
DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:
	Call DPMI for a descriptor.
	If its a bad descriptor (bad range value), then just forget it
		and try again.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGPMIAllocateDescriptor	proc near
	uses	cx
	.enter

cantUseThatSelector:
	mov	ax, DPMI_FUNC_ALLOCATE_DESCRIPTOR
	mov	cx, 1
	int	31h
	jc	abort
	cmp	ax, GPMI_HIGH_SELECTOR_VALUE
	jae	cantUseThatSelector

	; Got a selector.  Now mark the selector as free for use
	; (but allocated)
	push	ax
	SelectorToOffset	ax
	mov	si, ax
	ornf	[si].GPMIS_flags, mask GPMISF_allocated
	mov	[si].GPMIS_type, GPMI_SELECTOR_TYPE_EMPTY
	pop	ax
	clc
abort:
	.leave
	ret
IGPMIAllocateDescriptor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		 IGPMIFreeDescriptor (internal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a GPMI descriptor
CALLED BY:	Loader, Kernel
PASS:		bx	-- descriptor to free
		ds	-- GPMIData
RETURN:		carry	-- set if failed, else cleared
DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:
	Call DPMI for a descriptor.
	If its a bad descriptor (bad range value), then just forget it
		and try again.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	12/16/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGPMIFreeDescriptor	proc near
	mov	si, bx
	; Remove the descriptor from DPMI (as passed in by bx)
	mov	ax, DPMI_FUNC_FREE_DESCRIPTOR
	int	31h

	; Reset entry to default value
	SelectorToOffset	si
	clr	[si].GPMIS_flags
	mov	[si].GPMIS_type, GPMI_SELECTOR_TYPE_NOT_USED
	clr	[si].GPMIS_data1
	clr	[si].GPMIS_data2
	ret
IGPMIFreeDescriptor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIReleaseSegmentAccess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy a previously created alias
CALLED BY:	Loader, Kernel
PASS:		bx	= descriptor to alias
RETURN:		carry	= clear if success, else set if failed
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Check to see that this is really an alias
	Free it from DPMI

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	08/11/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIReleaseSegmentAccess	proc far
	uses	bx, si, ds
	.enter

	IGPMIGetDataSelector

	; Make sure this is an alias we are trying to free (and not
	; anything else)
	mov	si, bx
	SelectorToOffset si
	mov	bl, [si].GPMIS_type
	cmp	bl, GPMI_SELECTOR_TYPE_REAL_SEGMENT
	jne	failed

	; Do the actual free now
	call	IGPMIFreeDescriptor
	jmp	done
failed:
	stc
done:
	.leave
	ret
GPMIReleaseSegmentAccess	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIRealInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Simulates a real mode interrupt
CALLED BY:	VESA video drivers and other drivers
PASS:		bl      = interrupt to call
                bh      = flags
                cx      = number of words on stack to pass
                es:edi  = real mode register date
RETURN:		carry	= clear if success, else set if failed
                ax      = error code on failure
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Call DPMI to simulate the interrupt.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	24/04/2009	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIRealInterrupt	proc far

	; simulate real mode interrupt here
        mov     es, dx
	mov	ax, DPMI_FUNC_REAL_INTERRUPT
	int	31h

	jc	failed
	jmp	done
failed:
	stc
done:
	ret
GPMIRealInterrupt	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIAllocateDOSBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a data block of memory in DOS area.
CALLED BY:	Loader, Kernel
PASS:		bx	= number of 16 byte paragraphs to be allicated
RETURN:		carry	= cleared if success, else set
		ax	= real mode segment
		dx 	= selector of allocated block
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Allocate a block of DOS memory

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	24/04/09	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIAllocateDOSBlock	proc far
	.enter

	; Allocate the DOS memory block
	; -- bx:cx is the size of the block to allocate
	mov	ax, DPMI_FUNC_ALLOCATE_DOS_MEMORY_BLOCK
	int	31h
	.leave
	ret
GPMIAllocateDOSBlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIFreeDOSBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a block of DOS memory.
CALLED BY:	Loader, Kernel
PASS:		dx	= free dos block descriptor
RETURN:		carry	= cleared if success, else set
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Free the block of DOS memory assigned to the descriptor
		Return the descriptor to the free pool

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	24/04/09	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMIFreeDOSBlock	proc far
	uses	ax
	.enter
	
	; Now do the actual free
	mov	ax, DPMI_FUNC_FREE_DOS_MEMORY_BLOCK
	int	31h
	.leave
	ret
GPMIFreeDOSBlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMIIsSelector16Bit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the data we're looking at is a 16 bit
                code or data selector.  NOTE:  THis is not a fast method
CALLED BY:	Loader, Kernel
PASS:		bx	= descriptor to alias
RETURN:		zero flag	= set if 32 bit, clear if 16 bit
DESTROYED:	

PSEUDO CODE/STRATEGY:
        Get the descriptor for the selector
        Check if 16-bit flag is set

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	08/11/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GPMIIsSelector16Bit proc    far
        uses    bx, ax, es, edi
descriptor	local   PMCodeDescriptor
        .enter
        segmov  es, ss, ax
        clr     edi
        lea     di, descriptor
        call    GPMIGetDescriptor

        ; Note:  Code and data descriptors use the same location for this
        ; type of data.  Therefore, we can just look at that one bit
        ; and see if it is zero or not.
        mov     bx, descriptor.PMD_code.PMCD_flags
        test    bx, mask PMCF_code32
        .leave
        ret
GPMIIsSelector16Bit endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMISelectorGetLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Examines a selector and adjusts the given range if past
                the end.  If the selector, doesn't exist, returns
                the carry flag set.  Note:  1 is added because descriptors
                are inclusive on their limits and this routine returns
                an execulsive limit.  (e.g. a limit of 0-4 would be
                stored as 4, we return 5).  If a granularity is 1,
                4096 is added instead of 1.
CALLED BY:	Loader, Kernel
PASS:		bx	= descriptor to check
RETURN:		carry set = descriptor is not valid, else clear
                eax     = 1+Limit on descriptor (factors in large blocks)
DESTROYED:	

PSEUDO CODE/STRATEGY:
        Get the descriptor for the selector
        Read out the limit field
        Multiply by 4096 if a big granularity

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	08/24/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMISelectorGetLimit proc far
        uses    edx, edi, es
descriptor	local   PMCodeDescriptor
        .enter
        segmov  es, ss, ax
        clr     edi
        lea     di, descriptor
        call    GPMIGetDescriptor       ; Get a full description of the descriptor
        jc      noDescriptor

    ;
    ; We have a descriptor!  What is it's limit?
    ;
        mov     ax, descriptor.PMCD_flags
        and     ax, mask PMCF_limit
        shr     ax, offset PMCF_limit
        shld    eax, eax, 16
        mov     ax, descriptor.PMCD_limit
;        inc     eax
	.inst	db 0x66
	inc	ax
        test    descriptor.PMCD_flags, mask PMCF_granularity
        jz      notBig
        shl     eax, 12
notBig:
        clc
        jmp     done
noDescriptor:                           ; No descriptor by that name
        clr     eax
        stc
done:
        .leave
        ret
GPMISelectorGetLimit endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMISelectorCheckLimits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Examines a selector and adjusts the given range if past
                the end.  If the selector, doesn't exist, returns
                the carry flag set.
CALLED BY:	Loader, Kernel
PASS:		bx	= descriptor to check
                edx     = starting offset of range
                ecx     = range distance (add to edx for end position)
RETURN:		carry set = descriptor is not in range
                ecx     = adjusted new length
DESTROYED:	

PSEUDO CODE/STRATEGY:
        Get the descriptor for the selector
        Check if 16-bit flag is set

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	08/24/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMISelectorCheckLimits proc far
        uses    bx, edx, eax
        .enter
        call    GPMISelectorGetLimit
        jc      noValidRange
        cmp     edx, eax
        jb      startIsBelow

    ; Start is past limit, so report none of the range valid
        clc
        jmp     noValidRange
startIsBelow:
        sub     eax, edx                ; EAX = num bytes past start of range
        cmp     ecx, eax                ; Is our num of characters past the end?
        jbe     endIsWithin
        mov     ecx, eax                ; Past end.  Take what we can get
endIsWithin:
        clc                             ; Return with valid descriptor status
        jmp     done
noValidRange:
        pushf
        xor     ecx, ecx
        popf
done:
        .leave
        ret
GPMISelectorCheckLimits endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMITestPresent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test if a memory block is present
CALLED BY:	Loader, Kernel
PASS:		ax	= Selector to test if present
RETURN:		carry clear if present, else set if not present.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Check our table for the selector's present state.

	NOTE: This is only a temporary measure until we're ready to replace
	ResourceCallInt with a not-present exception handler.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	11/21/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMITestPresent	proc	far
	uses	ds, si
	.enter

	; Get access to this selector's information
	IGPMIGetDataSelector
	mov	si, ax
	SelectorToOffset	si

	; Block is not present if GPMI_SELECTOR_TYPE_NOT_PRESENT
	cmp	[si].GPMIS_type, GPMI_SELECTOR_TYPE_NOT_PRESENT
	stc
	je	done
	clc
done:
	.leave
	ret
GPMITestPresent	endp


if LOAD_DOS_EXTENDER

; --------------------- Extender data ----------------------
extenderPathAndName	db	100 dup (0)
extenderName	db "dosext.exe", 0	; DOS Name
extenderCSIP	fptr			; CS:IP to start location
extenderSSSP	fptr			; SS:SP of extender stack
extenderPSP	word			; PSP of extender


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtenderCreateFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	From the current drive and location, create a full path
		to the DOS extender (which should be located in the
		same place as the loader.exe as dosext.exe)
CALLED BY:	Loader
PASS:		nothing
RETURN:		fills extenderPathAndName
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Get the current drive
	Setup X:\
	Append the path
	Append extenderName

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	lshields	12/19/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtenderCreateFilename	proc	near
	uses ds, es, ax, si, di, cx
	.enter
	segmov	es, cs

	segmov	ds, cs
	mov	si, offset extenderPathAndName

	; Start the path with a X:\ prefix
	mov	ah, MSDOS_GET_DEFAULT_DRIVE
	int	21h
	add	al, 'A'
	mov	ds:[si], al
	inc	si
	mov	byte ptr ds:[si], ':'
	inc	si
	mov	byte ptr ds:[si], '\\'
	inc	si

	; Append the drive path
	mov	ah, MSDOS_GET_CURRENT_DIR
	clr	dl
	int	21h

	cld
	clr	al
findNull:
	cmp	al, ds:[si]
	je	found
	inc	si
	jmp	findNull
found:

	; append a \ and the extender name
	mov	al, '\\'
	mov	ds:[si], al
	inc	si

	segmov	es, ds
	mov	di, si
	mov	si, offset extenderName
	mov	cx, 11

	rep	movsb

	.leave
	ret
ExtenderCreateFilename	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtenderMakeRoom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resizes the loader so that there is a room for the dos
		extender at the top of memory.  If there is not enough
		room, a loader error is generated.
CALLED BY:	Loader
PASS:		es = PSP of loader.exe
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Look at the PSP and see if we have room
	If so, calculate what our new size is minus 128K
	Do the resize

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	lshields	12/19/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtenderMakeRoom	proc	near
	uses	ax, bx, es
	.enter

	; es should point to PSP of loader
	mov	bx, es:[PSP_endAllocBlk]
	mov	ax, es
	sub	bx, ax
	sub	bx, 8192 ; 128K of data
	ERROR_C LS_NOT_ENOUGH_MEMORY

	mov	ah, MSDOS_RESIZE_MEM_BLK
	int	21h

	.leave
	ret
ExtenderMakeRoom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtenderLoad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actually load the extender, but don't run it.
		Record all pertinent data in the extender data area

CALLED BY:	Loader
PASS:		es = PSP of loader.exe
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Load up a LoadProgramArgs structure
		- Full name
		- Pass loader's cmd tail
		- Use the loader's FCBs
	Do the load (error if can't load)
	Read in the new PSP for the extender
	Store data (SS:SP, CS:IP, and PSP)

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	lshields	12/19/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadProgramArgs	struct
    LPA_environment	sptr		; environment for program
    LPA_commandTail	fptr		; command tail to use
    LPA_fcb1		fptr		; FCB #1
    LPA_fcb2		fptr		; FCB #2
    LPA_ss_sp		fptr		; OUT: ss:sp for new process
    LPA_cs_ip		fptr		; OUT: cs:ip for new process
LoadProgramArgs	ends

ExtenderLoad	proc	near
lpa		local	LoadProgramArgs
	uses	es, ax, bx, cx, dx, si, di
	.enter

	;
	; Set up the parameter block and load the extender
	;
	mov	ss:[lpa].LPA_environment, 0
	mov	ax, es
	mov	ss:[lpa].LPA_commandTail.segment, ax
	mov	ss:[lpa].LPA_commandTail.offset, PSP_cmdTail
	mov	ss:[lpa].LPA_fcb1.segment, ax
	mov	ss:[lpa].LPA_fcb1.offset, offset PSP_fcb1
	mov	ss:[lpa].LPA_fcb2.segment, ax
	mov	ss:[lpa].LPA_fcb2.offset, offset PSP_fcb2

	segmov	es, ss
	lea	bx, ss:[lpa]
	mov	dx, offset extenderPathAndName
	mov	ax, (MSDOS_EXEC shl 8) or MSESF_LOAD
	push	bp, ds
	segmov	ds, cs
	int	21h		; XXX: on 2.X, this biffs everything
				;  but CS:IP
	pop	bp, ds
	ERROR_C	LS_CANNOT_LOAD_DOS_EXTENDER

	; Get the PSP of the dos extender
	mov	ah, MSDOS_GET_PSP
	int	21h
	mov	cs:extenderPSP, bx

	; Store the pertinent data
	movdw	cs:extenderCSIP, ss:[lpa].LPA_cs_ip, ax
	movdw	cs:extenderSSSP, ss:[lpa].LPA_ss_sp, ax

	.leave
	ret
ExtenderLoad	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtenderStartup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run the extender.  It should just install it's DPMI
		vectors.  We return in Real Mode.

CALLED BY:	Loader
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Do whatever we need to call the extender and return

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	lshields	12/19/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtenderStartup	proc	near
	.enter
	call	dword ptr ds:[extenderCSIP]
	.leave
	ret
ExtenderStartup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPMILoadDOSExtender
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go through all the steps of loading the dos extender
		into memory after making room for it.  Calls LoaderError
		if fails at any step.

CALLED BY:	Loader
PASS:		es = PSP of loader.exe
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Get the loader.exe PSP
	Make room for the dosext.exe
	Load it
	Run it (correctly)

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	lshields	12/19/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPMILoadDOSExtender	proc	near
	uses	ax, bx, es
	.enter

	; Get the PSP of us!
	mov	ah, MSDOS_GET_PSP
	int	21h
	mov	es, bx

	call	ExtenderCreateFilename
	call	ExtenderMakeRoom
	call	ExtenderLoad
	call	ExtenderStartup
	.leave
	ret
GPMILoadDOSExtender	endp

endif
