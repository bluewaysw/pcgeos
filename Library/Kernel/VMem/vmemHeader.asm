COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/VMem -- Virtual Memory Header Block things
FILE:		vmemHeader.asm

AUTHOR:		Adam de Boor, Oct 28, 1989

ROUTINES:
	Name			Description
	----			-----------
INT	VMCreateFileHeader	creates the VM file header on disk
INT	VMCreateHeader		creates the VM header in memory
INT	VMUpdateHeader		write hdr blk to disk
INT	VMLockHeaderBlk		given VM file han, lock VM header blk
INT	VMLoadHeaderBlk		load the header block in from disk
INT	VMMarkHeaderDirty	mark the header block dirty
INT	VMGrabHeaderBlk		gain exclusive access to the header block
INT	VMReleaseHeader		release exclusive access to the header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/28/89	Initial revision


DESCRIPTION:
	Functions for manipulating the header block of a VM file.

	Typical register usage for all functions:

		ds - idata segment
		bx - VM file handle
		bp - VM handle / VM mem handle
		si - VM header handle
		es - VM header
		di - VM block handle

		when relevant:
		ax - number of bytes
		cx - high word of file pos
		dx - low word of file pos


	$Id: vmemHeader.asm,v 1.1 97/04/05 01:15:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


kcode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGrabHeaderBlk

DESCRIPTION:	Lock the VM mem block.  

CALLED BY:	INTERNAL (VMCreateHeader, VMLoadHeadBlk)

PASS:		si - VM mem handle

RETURN:		ds - seg address of header block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMGrabHeaderBlk	proc	far	uses ax, bx
	.enter
EC<	call	VMCheckMemHandle					>

	xchg	bx, si
	call	MemThreadGrab		;ax <- func(bx)
	xchg	bx, si
EC <	ERROR_C	VM_HEADER_DISCARDED?_WHAT_THE_HELL?			>

EC<	call	VMCheckMemHandle					>

	mov	ds, ax
;done:
	.leave
	ret
if 0
mustLoad:
	;
	; If VMA_PRESERVE_HANDLES, we can get a discarded header block. If
	; MemThreadGrab says it's discarded, re-load the thing.
	;
	push	bp
	LoadVarSeg	ds
	mov	bp, ds:[si].HM_owner
	mov	bx, ds:[bp].HVM_fileHandle
	call	VMLoadHeaderBlk		;ds <- segment
	pop	bp
	jmp	done
endif
VMGrabHeaderBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMReleaseHeader

DESCRIPTION:	Unlocks the VM header block.

CALLED BY:	INTERNAL (utility)

PASS:		ds - VM header

RETURN:		nothing

DESTROYED:	nothing, flags remain intact

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMReleaseHeader	proc	far	uses ax, bx
	.enter
	pushf
	mov	bx, ds:[VMH_blockTable].VMBH_memHandle
	call	MemThreadRelease		;func(bx), destroys ax
	popf
	.leave
	ret
VMReleaseHeader	endp
kcode	ends


VMOpenCode	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMVerifyFileHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a VMFileHeader is valid

CALLED BY:	INTERNAL (VMReadFileHeader)
PASS:		bx	= file handle
RETURN:		carry	= set if header invalid
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMVerifyFileHeader	proc	near
fileType	local	GeosFileType
		uses	es, di, cx, ax
		.enter
		mov	ax, FEA_FILE_TYPE
		segmov	es, ss
		lea	di, ss:[fileType]
		mov	cx, size fileType
		call	FileGetHandleExtAttributes
		jc	done
		cmp	ss:[fileType], GFT_VM
		je	done		; (carry cleared by == comparison)
		stc
done:
		.leave
		ret
VMVerifyFileHeader	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCreateFileHeader

DESCRIPTION:	Initialzes the file header for the given VM file.

CALLED BY:	INTERNAL (VMOpen)

PASS:		bx - VM file handle

RETURN:		carry set if couldn't create the header

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

vmInitAttrs	FileExtAttrDesc \
	<FEA_FLAGS,vmInitFlags,size vmInitFlags>,
	<FEA_FILE_TYPE,vmInitFileType, size vmInitFileType>

idata	segment		; else the addresses in vmInitAttrs end up as virtual
			;  segments...
vmInitFlags	GeosFileHeaderFlags	0
vmInitFileType	GeosFileType		GFT_VM
idata	ends

vmInitHeader	VMFileHeader <VM_FILE_SIG,0,0,0>

VMCreateFileHeader	proc	near
	uses	ax, cx, dx, ds, es, di
	.enter

	;
	; First make sure the header flags and file type are set properly to
	; indicate the file isn't a template or shared in anyway, and the
	; file is a VM file.
	; 
	segmov	es, cs
	mov	di, offset vmInitAttrs
	mov	cx, length vmInitAttrs
	mov	ax, FEA_MULTIPLE
	call	FileSetHandleExtAttributes
	
	; make sure we're at the start of the file
	
	mov	al, FILE_POS_START
	clr	cx
	mov	dx, cx
	call	FilePosFar

	segmov	ds, cs			;point ds:dx at vmInitHeader
	mov	dx, offset vmInitHeader
	clr	al
	mov	cx, size vmInitHeader	;specify num bytes
	call	FileWriteFar
	mov	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE	;error to return
	jc	done
done:
	.leave
	ret
VMCreateFileHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMReadFileHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the file header for a VM file and return the location
		and size of its header block.

CALLED BY:	INTERNAL (VMLoadHeaderBlock, VMOpen)
PASS:		bx	= VM file handle
		exclusive access to the file
RETURN:		carry set if file header invalid
		ax	= size of header block
		cx:dx	= file position of header block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMReadFileHeader proc	far	uses ds
fileHeader	local	VMFileHeader
headerVMBH	local	VMBlockHandle	; header's block handle
vmHeader	local	VMHeader
		.enter
	CheckHack <offset headerVMBH-offset vmHeader eq offset VMH_blockTable>

	;
	; Position to the start of the file
	;
		mov	al, FILE_POS_START
		clr	cx
		mov	dx, cx
		call	FilePosFar
	;
	; Read the entire header into our buffer.
	;
		segmov	ds, ss
		lea	dx, ss:[fileHeader]
		mov	cx, offset VMFH_updateCounter	;don't read
							;update counter or type
		clr	al
		call	FileReadFar
		jc	done
	;
	; Verify the reasonableness of the file header
	;
		call	VMVerifyFileHeader
		jc	done
		cmp	ss:[fileHeader].VMFH_signature, VM_FILE_SIG
		jne	error
		tst	ss:[fileHeader].VMFH_headerSize; real header ever get
						;  written?
		jz	error			; no => bogus file
	;
	; Make sure the entire header block falls within the bounds of
	; the file.
	; 
		call	FileSize		; dx:ax = file size

		sub	ax, ss:[fileHeader].VMFH_headerSize
		sbb	dx, 0
		jb	done
		sub	ax, ss:[fileHeader].VMFH_headerPos.low
		sbb	dx, ss:[fileHeader].VMFH_headerPos.high
		jb	done

	;
	; Make sure the file is big enough to hold all the used blocks, the
	; combined size of which is contained in the VMH_usedSize field of the
	; header. We don't want to bring in the header (can't, as we're called
	; from VMLoadHeaderBlock), so just read the dword containing
	; VMH_usedSize.
	;
		mov	dx, ss:[fileHeader].VMFH_headerPos.low
		mov	cx, ss:[fileHeader].VMFH_headerPos.high

		mov	al, FILE_POS_START
		call	FilePosFar

		lea	dx, ss:[vmHeader]	; ds == ss already
		mov	cx, size vmHeader + size VMBlockHandle
		clr	al			; return errors
		call	FileReadFar

		jc	done			; error on read => bogus

	;
	; Make sure that the usedSize is non-zero
	;
		mov	ax, ss:[vmHeader].VMH_usedSize.low
		or	ax, ss:[vmHeader].VMH_usedSize.high
		jz	error
		
		call	FileSize		; this is pretty quick, and
						;  saves us some bother about
						;  having the size on the
						;  stack if an error is
						;  encountered...
		sub	ax, ss:[vmHeader].VMH_usedSize.low
		sbb	dx, ss:[vmHeader].VMH_usedSize.high
		jb	done			; => file too small
						; XXX: + size VMFileHeader?

	;
	; Now check the VMBlockHandle that describes the handle to make sure it
	; matches the data that was supposedly written from it to the file
	; header. If it doesn't, some funky flushing happened when the file
	; was closed (e.g. the buffer containing the header was flushed to disk
	; before that containing the file header and that containing the
	; directory entry without the invalid-signature header having been
	; flushed to disk; allowing such a file to be opened will lead to an
	; abbreviated header being read in, all of whose pointers expect a
	; full header to be there, with havoc resulting in following blocks
	; and the system in general...yes, this actually has happened -- ardeb)
	; 
	; Load the important values from the file header, then compare them
	; against the one in the header...
	;
		mov	ax, ss:[fileHeader].VMFH_headerSize
		mov	dx, ss:[fileHeader].VMFH_headerPos.low
		mov	cx, ss:[fileHeader].VMFH_headerPos.high

		cmp	ax, ss:[headerVMBH].VMBH_fileSize
		jne	error
		
		cmp	dx, ss:[headerVMBH].VMBH_filePos.low
		jne	error
		
		cmp	cx, ss:[headerVMBH].VMBH_filePos.high
		jne	error
done:
		.leave
		ret
error:
		stc
		jmp	done
VMReadFileHeader endp
VMOpenCode	ends



kcode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMMarkHeaderDirty

DESCRIPTION:	Mark header dirty. This is a routine mostly for error-checking
		purposes, as all that's needed is an ANDNF...
		and, updates the dirty size if appropriate.

CALLED BY:	INTERNAL (VMCreateHeader VMLockHeaderBlk)

PASS:		es - idata segment
		ds - VM header

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

VMMarkHeaderDirty	proc	far	uses bx
	.enter
EC<	call	AssertESKdata						>
EC<	call	VMCheckDSHeader						>
	mov	bx, ds:[VMH_blockTable].VMBH_memHandle

EC<	push	ax							>
EC<	mov	ax, es:[currentThread]					>
EC<	cmp	es:[bx][HM_usageValue], ax				>
EC<	ERROR_NE VM_HEADER_NOT_MINE					>
EC<	pop	ax							>

	test	es:[bx][HM_flags], mask HF_DISCARDABLE

	jz	alreadyDirty

	andnf	es:[bx][HM_flags], not mask HF_DISCARDABLE

	;
	; first, get the size of the header
	;
	push	cx, si
	mov	cx, es:[bx].HM_size

	;
	; now, get the VM Handle - it's the owner of the Mem Handle
	; of this block..
	;
	mov	si, es:[bx].HM_owner

	call	VMTestDirtySizeForModeChange

	pop	cx, si

alreadyDirty:
	.leave
	ret
VMMarkHeaderDirty	endp
kcode	ends


VMOpenCode	segment	resource
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCreateHeader

DESCRIPTION:	Allocates a block on the heap and initializes it as a
		VM header.

CALLED BY:	INTERNAL (VMOpen)

PASS:		es - idata seg
		bx - VM file handle
		cx - compaction threshold

RETURN:		nothing

DESTROYED:	ax, cx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMCreateHeader	proc	near	uses bp, ds, es
	.enter

	mov	bp, es:[bx].HF_otherInfo	;bp = HandleVM

	push	cx
	mov	ax, VM_INIT_HDR_SIZE		;specify num bytes to allocate
	mov	cx, mask HAF_ZERO_INIT shl 8
	call	VMGetMemSpace			;si <- func(ax, bx, cx)

	call	VMGrabHeaderBlk			;point ds at header
	mov	es:[bp][HVM_headerHandle], si	;store handle of header block
						; after grabbing, to prevent
						; premature use.

	; mark file as modified so header gets updated if nothing else happens
	; to the file -- ardeb 9/29/93

	ornf	es:[bp].HVM_flags, mask IVMF_FILE_MODIFIED

	;init fields
	mov	ds:[VMH_headerSig], VM_HDR_SIG
	mov	ds:[VMH_lastHandle], ax
	mov	ax, VM_DEF_COMPACTION_THRESHOLD
	pop	cx
	jcxz	useDefault
	mov_tr	ax, cx
useDefault:
	mov	ds:[VMH_compactionThreshold], ax
	clr	ax
	mov	ds:[VMH_attributes], al		;default to asynchronous update
						; with nothing else on
	mov	ds:[VMH_dbMapBlock], ax		;no db map block until we try
						;to allocate

	;
	; Mark the header block used and store away its memory handle
	;
	mov	di, VMH_blockTable
	call	VMMarkBlkUsed
	mov	ds:[di].VMBH_memHandle, si	;file size and pos already = 0
	mov	ds:[di].VMBH_uid, VM_FILE_SIG	;uid is signature for file,
						; for easy update (q.v.
						; VMUpdateHeader)
	inc	ds:[VMH_numResident]

	;init free list
	mov	di, VMH_blockTable + size VMBlockHandle
	mov	cx, VM_INIT_NUM_BLKS - 1
	call	VMLinkFree			;alters di (dirties header)

EC<	call	VMCheckStrucs						>
	call	VMReleaseHeader
	.leave
	ret
VMCreateHeader	endp
VMOpenCode	ends

kcode	segment	resource
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMUpdateHeader

DESCRIPTION:	Writes the VM header block out to disk and update the VM file
		header on disk.

CALLED BY:	INTERNAL (VMUpdate, VMUpdateAndRidBlk)

PASS:		VM handle grabbed
		es - idata seg
		bx - VM file handle
		si - VM header handle
		ds, dx - VM header seg addr		

RETURN:		carry - set if error
		ax - error code

DESTROYED:	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	write header block out
	update file header on disk
	update file header in VM handle

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMUpdateHeader	proc	far	uses cx, dx, bp
	.enter
EC<	call	AssertESKdata						>
EC<	call	VMCheckHeaderHandle					>
EC<	call	VMCheckFileHandle					>
EC<	call	ECMemVerifyHeap						>
	mov	di, VMH_blockTable		;di <- hdr blk handle
	test	es:[si][HM_flags], mask HF_DISCARDABLE		;dirty?
	jne	updateFileHeader		; no -- still need to update
						;  file header to make sure
						;  file signature gets changed
						;  back to valid number.

	mov	ax, ERROR_ACCESS_DENIED
	test	es:[bx][HF_accessFlags], mask FAF_MODE	;test access
							; permissions
	stc
	jz	exitStageLeft			;branch if read only access

	;
	; First write the header block out to the file.
	;
	mov	ds, dx
EC <	call	VMCheckDSHeader					>
; already checked by VMCheckHeaderHandle
;EC<	mov	bp, es:[si][HM_owner]				>
;EC<	call	VMCheckVMHandle					>
	mov	bp, si				;blk written out = si
	call	VMWriteBlk			;func(ds,es,bx,di,si,bp,dx)
	jc	exitStageLeft

	;
	; Now we need to update the VMFH_signature, VMFH_headerSize and
	; VMFH_headerPos fields of the on-disk VMFileHeader. "Happily" (as if
	; we didn't plan it :), these fields in the file header are in the same
	; order as they are in the VMBlockHandle, so we need only seek to
	; the right place in the file and write the data from the
	; VMBlockHandle straight to the file.
	;
updateFileHeader:
EC<	call	VMCheckFileHandle					>
	mov	al, FILE_POS_START		;update copy of header on disk
	mov	bp, VM_FILE_SIG
	xchg	bp, ds:[di].VMBH_uid		; swap out the dirty limit
	clr	cx
	mov	dx, offset VMFH_signature
	call	FilePosFar			;dx:ax <- func(al, bx, cx, dx)

	; don't write the update counter or update type

	lea	dx, ds:[di].VMBH_uid
	mov	cx, offset VMFH_updateCounter - offset VMFH_signature
	clr	al
	call	FileWriteFar
EC<	ERROR_C	VM_BAD_WRITE						>
EC<	call	ECMemVerifyHeap						>
	mov	ds:[di].VMBH_uid, bp		; put back the dirty limit
	mov	bp, es:[si][HM_owner]		; and mark the file valid
	and	es:[bp].HVM_flags, not mask IVMF_INVALID_FILE
exitStageLeft:
	.leave
	ret
VMUpdateHeader	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMLockHeaderBlk

DESCRIPTION:	Lock the VM header block for access.

CALLED BY:	INTERNAL (EnterVMFile)

PASS:		ds - idata segment
		bx - VM file handle
		bp - VM handle
		si - VM header handle

RETURN:		ds - VM header
		es - idata
		si - locked VM header handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMLockHeaderBlk	proc	far		uses ax
	.enter
EC<	call	VMCheckVMAndFileHandleAndDSKdata			>

	segmov	es, ds		;es = idata for return and others
	tst	si		;VM header handle present?
	jnz	10$		;branch if not

	;-----------------------------------------------------------------------
	;VM handle is zero => header is not in memory

	call	VMLoadHeaderBlk
	jmp	short 90$
10$:
	;-----------------------------------------------------------------------
	;si cannot be non zero if the block has been discarded
	;if header was swapped, VMGrabHeaderBlk will bring it back in for us.

EC<	call	VMCheckHeaderHandle					>
	call	VMGrabHeaderBlk
90$:
	;ds - header seg
	;si - VM header handle
	;es - idata

	.leave
	ret
VMLockHeaderBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMLoadHeaderBlk

DESCRIPTION:	Load the header block from disk.

CALLED BY:	INTERNAL (VMLockHeaderBlk, VMGrabHeaderBlk)

PASS:		ds - idata seg
		bx - VM file handle
		bp - VM handle (owned)

RETURN:		ds - VM header

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMLoadHeaderBlk	proc	near	uses cx, dx, bp, di
	.enter
EC<	call	VMCheckVMAndFileHandleAndDSKdata			>
	segmov	es, ds
	;
	; Read in the size and position from the file.
	;
	call	VMReadFileHeader
EC <	ERROR_C	VM_BAD_HDR						>

	push	ax			;save header size

	;
	; Now read in the block itself.
	;
	clr	si			;header never discarded, so can't
					; be an existing handle to use...
	mov	di, offset VMH_blockTable
	call	VMReadBlk		;si <- func(ds, ax, bx, cx, dx, si)
					;read blk into mem, destroys ax, cx, dx
	call	VMGrabHeaderBlk

	;
	; Deal with special header fields that aren't updated when the header
	; is written, for various reasons.
	;
	; If in backup mode then we what to disable compression.
	;
	mov	ds:VMH_numResident, 1	; only one block resident now
	clr	cx			;ignore previous state of all flags
	test	ds:VMH_attributes, mask VMA_BACKUP or mask VMA_SYNC_UPDATE
	jz	storeNoCompress
	BitSet	cl, VMCF_NO_COMPRESS
storeNoCompress:
	mov	ds:[VMH_compressFlags], cl
	;
	; If VMA_COMPACT_OBJ_BLOCK is set, indicating the file contains
	; generic objects, forbid asynchronous update, as wiping out
	; specific UI data and non-save-to-state generic vardata at arbitrary
	; times while the thing is off-screen is a Bad Idea.
	; 
EC <	test	ds:VMH_attributes, mask VMA_COMPACT_OBJ_BLOCK		>
EC <	jz	checkNotifyDirty					>
EC <	test	ds:VMH_attributes, mask VMA_SYNC_UPDATE			>
EC <	ERROR_Z	VMEM_GENERIC_OBJECTS_CANNOT_BE_UPDATED_ASYNCHRONOUSLY	>
EC <checkNotifyDirty:							>
	;
	; If VMA_NOTIFY_DIRTY set in the header, set the
	; IVMF_NOTIFY_OWNER_ON_DIRTY field in the VM handle so we know to
	; notify anyone that has the file open the first time something
	; is marked dirty.
	;
	test	ds:VMH_attributes, mask VMA_NOTIFY_DIRTY
	jz	zeroHandles
	or	es:[bp].HVM_flags, mask IVMF_NOTIFY_OWNER_ON_DIRTY
zeroHandles:

	;zero out remaining mem handles. NOTE: can't use VMGetNextUsedBlk
	;b/c it checks on # resident blocks etc....

	clr	dx
	mov	di, ds:[VMH_lastHandle]
	;
	; XYX: During this loop, we recalculate the usedSize b/c there was
	; a bug in previous versions of the kernel where the usedSize wasn't
	; updated during a SaveAs for non-resident blocks. To make sure we
	; don't biff people's files, we recalculate this thing here...
	; 
	pop	ds:[VMH_usedSize].low		; start usedSize off with
	mov	ds:[VMH_usedSize].high, dx	;  the size of the header.
handleLoop:
	sub	di, size VMBlockHandle
	cmp	di, offset VMH_blockTable
	jbe	handlesZeroed

	mov	al, ds:[di].VMBH_sig
	test	al, VM_IN_USE_BIT
	jz	handleLoop

	mov	ds:[di].VMBH_memHandle, dx

	mov	cx, ds:[di].VMBH_fileSize
	add	ds:[VMH_usedSize].low, cx
	adc	ds:[VMH_usedSize].high, 0

	cmp	al, VMBT_USED	; Anything but a VMBT_USED block with the
				;  VM_IN_USE_BIT set indicates the file
	je	handleLoop 	;  was dirty when it was closed.

	and	es:[bp].HVM_flags, not mask IVMF_NOTIFY_OWNER_ON_DIRTY
							;already dirty
	jmp	handleLoop

handlesZeroed:

	;update header handle field in VM file handle
	mov	es:[bp].HVM_headerHandle, si
	.leave
	ret
VMLoadHeaderBlk	endp
kcode	ends

VMHigh	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMGetHeaderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve statistics on the resource usage for the header
		of a VM file.

CALLED BY:	(GLOBAL)
PASS:		bx	= VM file handle
RETURN:		ax	= # used blocks
		cx	= # bytes in the header
		dx	= # free blocks
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMGetHeaderInfo	proc	far
		call	VMPush_EnterVMFileFar
	;
	; Convert header memory block size to bytes.
	; 
		mov	cl, 4
		mov	ax, es:[si].HM_size
		shl	ax, cl
		mov	bp, sp
		mov	ss:[bp].VMPOES_cx, ax	; return header size in CX
	;
	; Compute the number of blocks that are "free", either holding free
	; file space or utterly free.
	; 
		mov	ax, ds:[VMH_numUnassigned]
		add	ax, ds:[VMH_numAssigned]
		mov	ss:[bp].VMPOES_dx, ax	; return free blocks in DX
	;
	; Fetch the number of used blocks in the file and return it in AX
	; 
		mov	ax, ds:[VMH_numUsed]
		jmp	VMPop_ExitVMFileFar
VMGetHeaderInfo	endp

VMHigh	ends
