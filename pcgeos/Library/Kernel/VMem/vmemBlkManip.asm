COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Virtual Memory Manager
FILE:		vmemBlkManip.asm

AUTHOR:		Adam de Boor, Dec 13, 1989

ROUTINES:
	Name			Description
	----			-----------
DHI INT	VMUseBlk		allocate a block in the file
DHI INT	VMUseBlkDoExtend	subr - allocate by extending the file
DHI INT	VMUseBlkDoSplit		subr - allocate by splitting a free blk

    INT	VMFreeAllBlks		free all used blks
DHI INT	VMFreeBlkHandle		free a blk handle
DHI INT	VMAssignBlk		subr - insert the used blk
DHI INT	VMCoalesceIfPossible	subr - combine free blks
					
DH  INT	VMDetachBlk		utility - detach an assigned blk
DH  INT	VMInsertBlk		utility - insert an assigned blk

DHI INT	VMExtendBlkTable	utility - enlarge the VM header
DHI INT	VMLinkFree		utility - link added unassigned blks

DHI INT	VMGetUnassignedBlk	utility - detach an unassigned blk
DHI INT VMGetUnassignedBlkMaybeExtend	 utility - detach an unassigned blk,
					  extending the header if the file is
					  VMA_SYNC_UPDATE
DH  INT	VMGetUnassignedBlkCommon  used by above two

DH  INT	VMUnassignBlk		utility - add blk to unassigned list

    INT	VMMarkBlkUsed		utility - mark a blk as used

DHI INT	VMMaintainExtraBlkHans	make sure header has enough unassigned blk
				 handles to flush all dirty blocks to disk,
				 if file is async-update
    INT	VMGetNextUsedBlk	utility - locate the next used blk

    INT	VMReadBlk		read blk from mem and leave blk locked
DHI INT	VMWriteBlk		write blk out to disk
DHI INT	VMBackupBlockIfNeeded	create a backup block of an in-use block
				 if the file requires it.
    INT CallVMReloc		call the relocation routine for the
				 file. Also handles object relocation
    INT	VMFindFollowingUsedBlk	Locate the used block that should follow an
				 assigned block
DHI INT VMCheckCompression	See if the file should be compressed
DHI INT VMDoCompress		Compress and truncate the file, if possible
DH  INT VMAllocThis		Allocate a specific block handle in a file.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/89		Initial version


DESCRIPTION:
	Low-level routines for manipulating VM blocks.
		
	$Id: vmemBlkManip.asm,v 1.1 97/04/05 01:15:55 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @-----------------------------------------------------------------------

NOTES:
	A 'free block' is an entry in the block table that is not currently
	being used by the application. Free blocks can either be assigned or
	unassigned.

	An 'assigned block' is a free block that has a corresponding block
	in the file.  Assigned blocks are chained together as a doubly linked
	list with VMH_assignedPtr as the head pointer.  The assigned list
	is kept in order of increasing file position for easy coalescing.

	An 'unassigned block' is a free block handle that does not have a
	corresponding block in the file.  Unassigned blocks are chained together
	as a singly linked list with VMH_unassignedPtr as the head pointer.

	A block that is 'used' is one that the application is currently
	using (!).

	Assigned blocks are not yielded to the application unless both these
	conditions are met:
	1) The block manipulation code happens to be inspecting this block, and
	2) The application so happens to request the exact number of bytes
	   contained in the block

	This is because assigned blocks contain information that keep track of
	the empty blocks in the file.

REGISTER USAGE:
	es - idata segment
	bx - VM file handle
	di - VM block handle
	si - VM header handle
	ds - VM header
	bp - VM handle / VM mem handle (for lack of registers)

	when relevant:
	ax - number of bytes
	cx - high word of file pos
	dx - low word of file pos

TO DO ?:
	block compaction within the file

-------------------------------------------------------------------------------@

kcode	segment	resource
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMUseBlk

DESCRIPTION:	Positions the file at the location of a buffer that is
		large enough for the given number of bytes, returning the
		VM block handle describing the file space allocated.

CALLED BY:	INTERNAL (VMDoWriteBlk, VMTransfer)

PASS:		es - idata seg
		bx - VM file handle
		si - VM header handle
		ds - VM header
		ax - number of bytes

RETURN:		ds - VM header - possibly changed
		di - VM block handle
		cx:dx - file pos allotted
		file pos set at cx:dx

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	block allocation is by first fit
	go through list of assigned blocks and use the first block that
		is large enough
	if no such assigned block exists, use an unassigned block and
		extend the file

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header by calling VMUseBlkDoSplit or VMUseBlkDoExtend

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial Version

-------------------------------------------------------------------------------@

VMUseBlk	proc	far	uses ax
	.enter
EC<	call	AssertESKdata						>
EC<	call	VMCheckDSHeader						>
EC<	call	VMCheckFileHandle					>

	mov 	di, VMH_assignedPtr - VMFBH_nextPtr
	test	ds:[VMH_compressFlags], mask VMCF_COMPRESSING
	jnz	handleCompressing
scanLoop:
	mov	di, ds:[di].VMFBH_nextPtr	;move on to next blk
	tst	di				;nil ptr?
	je	mustExtend			;branch if so

	mov	dx, ds:[di].VMFBH_fileSize.low	;get size of blk
	mov	cx, ds:[di].VMFBH_fileSize.high
	sub	dx, ax				;compute num bytes left
	sbb	cx, 0
	jb	scanLoop			;keep looking if too small

	;-----------------------------------------------------------------------
	;found free block that is large enough
	call	VMUseBlkDoSplit
	jmp	doPosition
mustExtend:
	;-----------------------------------------------------------------------
	;no free block large enough
	call	VMUseBlkDoExtend

doPosition:
	;
	; Position the file at the start of the block:
	;	al 	= positioning method (e.g. FILE_POS_START)
	;	cx:dx	= parameter for position
	;
	call	FilePosFar
	;
	; Store the actual position in the block (VMUseBlkDoExtend just
	; returns FILE_POS_END(0,0) so we need to use dx:ax to obtain the
	; real position of the block.
	; 
	mov	ds:[di].VMBH_filePos.high, dx
	mov	ds:[di].VMBH_filePos.low, ax

	mov	cx, dx				;return file pos in cx:dx
	mov	dx, ax

	call	VMMarkBlkUsed			;func(ds, di)

EC<	call	VMVerifyUseBlk						>
	.leave
	ret

	;
	; There is an ugly situation that can happen during compressing as
	; a result of a rediculous series of coincidences.  The planets
	; have to align just so for this to happen:
	;
	; 1. VMDoCompress is trying to swap the first assigned block with the
	;    adjacent in-use block, and the block is not resident.
	; 2. The copy routine allocates space on the heap for the block,
	;    which may force the heap to discard a block to make room.
	; 3. The heap may decide to discard a block in this same file.
	; 4. If that block is dirty and the current available swap driver is
	;    slow, it will call VMUpdateAndRidBlock.
	; 5. The dirtied block has grown, so this routine is called to find
	;    a new spot for it.
	; 6. The first assigned block happens to be large enough to hold the
	;    block being updated.
	;
	; When the update finishes and the copy finally occurs, it ends up
	; writing directly over the block that was just updated, and the
	; file is subsequently hosed.  So......
	;
	; To avoid this, ignore the first assigned block during compression.
	; Sounds simple, right? :) -dhunter 3/23/2000
	;
handleCompressing:
	mov	di, ds:[di].VMFBH_nextPtr	; get the first block
	tst	di				; nil ptr?
	je	mustExtend			; branch if so
	jmp	scanLoop			; skip the first block

VMUseBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMUseBlkDoExtend

DESCRIPTION:	No free block was found to be large enough, so we extend the
		file size.

CALLED BY:	INTERNAL (VMUseBlk)

PASS:		es - idata seg
		ds - VM header
		ax - size of block requested

RETURN:		di - VM block handle
		al - file positioning method to employ
		cx:dx - file position to give FilePosLow

DESTROYED:	

PSEUDO CODE/STRATEGY:
	use an unassigned block
	set file pos method and offset

	9/89 changed to:
	use an unassigned block
	if compression ratio < specification then
		DoCompress
	else if entire block is not writable then
		DoCompress
	endif
	cx:dx <- file size

	The assumption is made that the file is writable once compression
	is performed.  The check to ensure this was made in VMCheckWritable.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header by calling VMGetUnassignedBlkMaybeExtend

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	Cheng	9/89		Modified to handle possibility of running out of
				disk space

-------------------------------------------------------------------------------@

VMUseBlkDoExtend	proc	near
	.enter
EC<	call	AssertESKdata						>
EC<	call	VMCheckDSHeader						>

	; test for an assigned block at the end of the file.  If so, use it

	push	bp
	mov	bp, ds:[VMH_lastAssigned]
	tst	bp
	jz	doExtend
	
	call	VMFindFollowingUsedBlk
	jnc	doExtend
	mov	di, bp
	pop	bp
	
	call	VMDetachBlk
	mov	ds:[di].VMBH_fileSize, ax
	mov	al, FILE_POS_START
	mov	cx, ds:[di].VMFBH_filePos.high
	mov	dx, ds:[di].VMFBH_filePos.low
	jmp	done

doExtend:
	pop	bp
	call	VMGetUnassignedBlkMaybeExtend		;ds, di <- func(si, ds)
	mov	ds:[di].VMBH_fileSize, 0	;init blk size

	call	VMCheckCompression

IF	VM_CHECK_WRITABLE
	;-----------------------------------------------------------------------
	;will write fail due to insufficient disk space? Seek to the
	;end of the allocated block and try to write a single byte. If this
	;fails, the allocation must fail.
	push	ax
	mov	dx, ax
	dec	dx
	clr	cx
	mov	al, FILE_POS_END
	call	FilePos				;dx:ax <- func(al,bx,cx,dx)

	clr	al
	mov	cx, 1
	clr	dx				;just ensure that ds:dx does
						;not point to a read-sensitive
						;location (SOH)
	call	FileWrite
	pop	ax

	; XXX: WHAT DO WE DO HERE?
ENDIF

	mov	ds:[di].VMBH_fileSize, ax	; initialize block size
	;
	; Return values for FilePos -- 0 bytes beyond the end of the file.
	; 
	mov	al, FILE_POS_END		;use offset from end
	clr	cx				;specify offset 0
	mov	dx, cx
done:
	.leave
	ret
VMUseBlkDoExtend	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMUseBlkDoSplit

DESCRIPTION:	A free block has been found for use. This block may need
		to be split into used and unused portions.

CALLED BY:	INTERNAL (VMUseBlk)

PASS:		ds - VM header
		ax - size of block requested
		cx:dx - number of free bytes left in the free block
		di - VM block handle of free blk

RETURN:		di - VM block handle (possibly different from passed value)
		al - file positioning method (FILE_POS_START)
		cx:dx - file position

DESTROYED:	

PSEUDO CODE/STRATEGY:
	if exact fit, just detach the block and return its position
	else get an unassigned handle, give it the starting position and
		desired size and modify the free block appropriately,
		leaving it in the chain to map the remainder of the
		block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header by calling VMGetUnassignedBlkMaybeExtend or VMDetachBlk

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMUseBlkDoSplit	proc	near
	.enter
EC<	call	VMCheckBlkHandleAndDSHeader				>

	tst	dx				; low size word non-zero?
	jnz	mustSplit			; yes => bytes left
	jcxz	detachDI			; => no need to split
mustSplit:
	;
	; Allocate an unassigned block we can return. We continue to use the
	; passed-in block as the assigned block so we needn't mangle the
	; pointers -- we can just leave di in the list.
	; 
	push	si
	mov	si, di
	call	VMGetUnassignedBlkMaybeExtend	; fetch new handle for return
	
	mov	ds:[si].VMFBH_fileSize.low, dx	; set size of free to remainder
	mov	ds:[si].VMFBH_fileSize.high, cx	

	;
	; Set the position of the block we're returning to match that of the
	; free block we're about to shrink. The size of the block we're
	; returning will be initialized at setupReturn.
	;
	mov	dx, ds:[si].VMFBH_filePos.low	; cx:dx <- start of assigned
	mov	cx, ds:[si].VMFBH_filePos.high

	mov	ds:[di].VMBH_filePos.low, dx	; store in used block
	mov	ds:[di].VMBH_filePos.high, cx

	add	dx, ax				; point free block to start
	adc	cx, 0				; of remainder
	mov	ds:[si].VMBH_filePos.low, dx
	mov	ds:[si].VMBH_filePos.high, cx

	pop	si				; recover si now we're done with
						;  the passed assigned block.
	jmp	setupReturn
detachDI:
	call	VMDetachBlk			; remove di from the assigned
						;  list
setupReturn:
	mov	ds:[di].VMBH_fileSize, ax
	;
	; Set up other return values -- want to seek to the position of the
	; block we're returning.
	;
	mov	al, FILE_POS_START
	mov	cx, ds:[di].VMFBH_filePos.high
	mov	dx, ds:[di].VMFBH_filePos.low
	.leave
	ret
VMUseBlkDoSplit	endp
kcode	ends

VMOpenCode	segment	resource
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMFreeAllBlks

DESCRIPTION:	Frees all used blocks.

CALLED BY:	INTERNAL (VMClose)

PASS:		VM handle grabbed
		VM header handle grabbed
		es - idata segment
		bp - VM handle
		bx - VM file handle
		si - VM header handle
		ds - VM header

RETURN:		carry - set if error

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMFreeAllBlks	proc	far	uses ax, cx, di, bx
	.enter
EC<	call	AssertESKdata						>
EC<	call	VMCheckFileHandle					>
EC<	call	VMCheckVMHandle						>
EC<	call	VMCheckHeaderHandle					>

	clr	cx			; error flag
	call	FarPHeap		; Get us the heap semaphore for the
					;  entire time we're freeing things

	mov	di, offset VMH_blockTable
freeLoop:
	call	VMGetNextUsedBlk
	jc	freeHeader

	mov	bx, ds:[di].VMBH_memHandle
EC <	tst	bx							>
EC <	jz	10$							>
EC <	tst	es:[bx].HM_lockCount					>
EC <	ERROR_NZ VM_BLOCK_LOCKED_IN_VM_CLOSE				>
EC <10$:								>
	call	incCXIfDirty
	call	VMDiscardMemBlk		;func(ds, es, di)
	jmp	freeLoop

freeHeader:

	mov	bx, si
	call	incCXIfDirty

	call	VMOpenCode_SwapESDS
	clr	ax
	mov	ds:[bp].HVM_headerHandle, ax

	;free VM header handle

EC <	push	ax, ds							>
EC <	LoadVarSeg	ds						>
EC <	mov	ax, ss:[TPD_processHandle]				>
EC <	mov	ds:[bx].HM_owner, ax					>
EC <	pop	ax, ds							>

	call	MemFree			;func(ds, bx), destroys ax, bx

	call	FarVHeap		;All done
	call	VMOpenCode_SwapESDS

	clc
	jcxz	done
	stc
done:
	.leave
	ret

incCXIfDirty:
	tst	bx
	jz	good
	test	es:[bx].HM_flags, mask HF_DISCARDED
	jnz	good
	test	es:[bx].HM_flags, mask HF_DISCARDABLE
	jnz	good
	inc	cx
good:
	retn


VMFreeAllBlks	endp

VMOpenCode	ends


kcode	segment	resource
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMFreeBlkHandle

DESCRIPTION:	Free the space taken up by the given block.

CALLED BY:	INTERNAL (VMFree, VMDoWriteBlk)

PASS:		ds - VM header
		di - used VM block handle. If VMBH_sig is VMBT_USED or VMBT_DUP,
		     VMH_numUsed will be decremented. NOTE: even if block
		     isn't in-use, its size must reside solely in VMBH_fileSize.
		     IT CANNOT RESIDE IN THE VMFBH_fileSize DWORD.

RETURN:		di added to one of the free lists

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header by calling VMUnassignBlk or VMAttachBlk

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMFreeBlkHandle	proc	far uses ax
	.enter
EC<	call	VMCheckBlkHandleAndDSHeader				>

	mov	ax, ds:[di].VMBH_fileSize

	test	ds:[di].VMBH_sig, VM_IN_USE_BIT
	jz	notUsed
	cmp	ds:[di].VMBH_sig, VMBT_DUP
	jb	notUsed			; => ZOMBIE or BACKUP
	dec	ds:[VMH_numUsed]
notUsed:
	tst	ax
	jne	hasDiskSpace
	;-----------------------------------------------------------------------
	;blk han with no corresponding blk on disk, add to unassigned list

	call	VMUnassignBlk
	jmp	done

hasDiskSpace:
	;-----------------------------------------------------------------------
	;blk han with corresponding blk on disk, add to assigned list

	mov	ds:[di].VMFBH_fileSize.low, ax
	mov	ds:[di].VMFBH_fileSize.high, 0

	sub	ds:[VMH_usedSize.low], ax
	sbb	ds:[VMH_usedSize.high], 0

EC <	ERROR_B	GASP_CHOKE_WHEEZE					>

	push	bp, di
	call	VMAssignBlk			;position di in chain, dest bp

EC<	call	VMCheckDSHeader						>

	push	ds:[di].VMFBH_nextPtr		;save next
	mov	bp, di				; bp <- following block
	mov	di, ds:[bp].VMFBH_prevPtr	; di <- preceding block
	call	VMCoalesceIfPossible		;combine if possible. restores
						; di for us.
	pop	bp				; bp <- following block
	call	VMCoalesceIfPossible		;combine if possible

EC<	push	bx				;bp recovered below	>
EC<	mov	bp, ds:[VMH_assignedPtr]				>
EC<	mov	bx, ds:[VMH_lastAssigned]				>
EC<	call	VMCheckAssignedList					>
EC<	pop	bx							>

	pop	bp, di
done:
	.leave
	ret
VMFreeBlkHandle	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMAssignBlk

DESCRIPTION:	Add the passed block to the assigned list in the proper
		position. It is up to the caller to coalesce the block
		with its neighbors, if necessary.

CALLED BY:	INTERNAL (VMFreeBlkHandle)

PASS:		ds - VM header
		di - VM block handle for which to locate slot

RETURN:		di chained in

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	locate first blk whose file pos is greater than that of di
	insert di into the preceding position in the chain

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header by calling VMInsertBlk

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMAssignBlk	proc	far	uses cx, dx, si
	.enter
EC<	call	VMCheckBlkHandleAndDSHeader				>

	mov	cx, ds:[di].VMFBH_filePos.high	;get file pos in cx:dx
	mov	dx, ds:[di].VMFBH_filePos.low
	mov	si, VMH_assignedPtr - VMFBH_nextPtr
scanLoop:
	mov	si, ds:[si].VMFBH_nextPtr		;move on to next blk
	tst	si					;at end of list?
	jz	foundPoint				;branch if so

	cmp	ds:[si].VMFBH_filePos.high, cx	;else compare dword
	jne	20$
	cmp	ds:[si].VMFBH_filePos.low, dx
20$:

EC<	ERROR_E	VM_BLOCKS_HAVE_SAME_FILE_POSITION			>

	jb	scanLoop

foundPoint:
	call	VMInsertBlk				;link them
EC<	call	VMCheckDSHeader						>
	.leave
	ret
VMAssignBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMCoalesceIfPossible

DESCRIPTION:	Combine the two free blocks if they are adjacent.

CALLED BY:	INTERNAL (VMFreeBlkHandle)

PASS:		ds - VM header
		di - VM block handle of preceding block
		bp - VM block handle

RETURN:		di - coalesced block if coalecsing possible
		     else if bp <> 0 then
			di = bp
		     else no change

DESTROYED:	bp

PSEUDO CODE/STRATEGY:
	coalescing is possible if di and bp are adjacent
	if coalescing is possible then
		update data in di
		unassign bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header if necessary by calling VMDetachBlk (and VMUnassignBlk
	for good measure :)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMCoalesceIfPossible	proc	far	uses ax, bx
	.enter
EC<	call	VMCheckBlkHandleAndDSHeader				>
EC<	xchg	di, bp							>
EC<	call	VMCheckBlkHandle			;check bp	>
EC<	xchg	di, bp							>

	;no coalescing possible if either of the handles is nil
	tst	di
	je	restoreDI
	tst	bp
	je	99$

	mov	bx, ds:[di].VMFBH_filePos.low		;get file pos
	mov	ax, ds:[di].VMFBH_filePos.high

	add	bx, ds:[di].VMFBH_fileSize.low		;compute end of blk + 1
	adc	ax, ds:[di].VMFBH_fileSize.high

	cmp	bx, ds:[bp].VMFBH_filePos.low		;adjacent to di?
	jne	restoreDI				;done if not
	cmp	ax, ds:[bp].VMFBH_filePos.high
	jne	restoreDI

	;blocks are adjacent
	mov	ax, ds:[bp].VMFBH_fileSize.low
	add	ds:[di].VMFBH_fileSize.low, ax		;size of resulting blk
	mov	ax, ds:[bp].VMFBH_fileSize.high
	adc	ds:[di].VMFBH_fileSize.high, ax

	xchg	bp, di					;detach bp
	call	VMDetachBlk
	call	VMUnassignBlk				;unassign blk
restoreDI:
	mov	di, bp
99$:
	.leave
	ret
VMCoalesceIfPossible	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMDetachBlk

DESCRIPTION:	Remove a block from the assigned list for the file

CALLED BY:	INTERNAL (VMUseBlkDoSplit, VMCoalesceIfPossible)

PASS:		ds - VM header
		di - VM block handle to remove

RETURN:		di detached
		assigned count decremented

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	link( prev(di), next(di) )

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Marks header dirty

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMDetachBlk	proc	far	uses di, bp
	.enter
EC<	call	VMCheckBlkHandleAndDSHeader				>

	;
	; Fetch the bounding blocks
	;
	mov	bp, ds:[di].VMFBH_prevPtr
	mov	di, ds:[di].VMFBH_nextPtr

	tst	bp				; Anything before us?
	jnz	notHead				; yes -- not head
	mov	ds:VMH_assignedPtr, di		; Adjust head pointer
	tst	di				; Anything after us?
	jnz	setPrevPtr			; yes -- set its prevPtr
						;  null (by storing bp) and
						;  adjust VMH_numAssigned.
adjustTail:
	;
	; Make the preceding block be the tail of the list
	;
	mov	ds:VMH_lastAssigned, bp
	jmp	adjustNA			; go adjust VMH_numAssigned
notHead:
	;
	; Not the head of the list -- see if there's anything after us
	;
	mov	ds:[bp].VMFBH_nextPtr, di	; always set nextPtr, even if
						;  nothing follows (must
						;  null-terminate)
	tst	di
	jz	adjustTail			; no -- set bp as the tail
	;
	; Point the two blocks at each other
	;
setPrevPtr:
	mov	ds:[di].VMFBH_prevPtr, bp
adjustNA:
	dec	ds:[VMH_numAssigned]		; one fewer block
	call	VMMarkHeaderDirty
	.leave
	ret
VMDetachBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMInsertBlk

DESCRIPTION:	Inserts the VM block handle into the free list at the given
		location.

CALLED BY:	INTERNAL (VMAssignBlk)

PASS:		ds - VM header
		di - VM block handle to insert
		si - VM block handle on the free list before which to insert di

RETURN:		di inserted, all relevant header pointers updated
		assigned count incremented

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	the block originally preceding bp will be refered to as blk 1
	di will be refered to as blk 2
	bp will be refered to as blk 3

	blk1 <- prev(bp)
	blk2 <- di
	blk3 <- bp
	link( blk2, blk3 )
	link( blk1, blk2 )

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Marks header dirty

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMInsertBlk	proc	near	uses bp, si
	.enter
EC<	call	VMCheckBlkHandleAndDSHeader				>
EC<	xchg	di, si							>
EC<	call	VMCheckBlkHandle		;check si		>
EC<	xchg	di, si							>

	mov	ds:[di].VMFBH_nextPtr, si	;initialize nextPtr of new
						; block regardless of whether
						; si is null
	tst	si
	jz	atEnd				;make di be the tail
linkToPrev:
	mov	bp, di				;point si back at di
	xchg	bp, ds:[si].VMFBH_prevPtr	; retrieving previous previous
						; block

	mov	ds:[di].VMFBH_prevPtr, bp	;install that as the previous
						; block for di
	tst	bp				;anything there?
	jz	atFront				;no -- install di as head
	mov	ds:[bp].VMFBH_nextPtr, di	;yes -- point it at di
done:
	inc	ds:VMH_numAssigned		;one more assigned block
	call	VMMarkHeaderDirty
EC<	call	VMCheckDSHeader						>
	.leave
	ret
atEnd:
	;
	; di is being added as the last block in the chain -- set bp
	; so that xchg above will modify VMH_lastAssigned and go deal with
	; possibly inserting di as the only block in the chain.
	;
	mov	si, VMH_lastAssigned-VMFBH_prevPtr
	jmp	linkToPrev
atFront:
	;
	; di is the new head of the list -- just point assignedPtr at it
	;
	mov	ds:VMH_assignedPtr, di
	jmp	done
VMInsertBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMExtendBlkTable

DESCRIPTION:	Extend the block table in the VM header.

CALLED BY:	INTERNAL (VMAlloc, VMGetUnassignedBlk, VMMaintainExtraBlkHans)

PASS:		ds - VM header block
		ax - num blks by which to extend the block table

RETURN:		carry clear if successful
			ds - VM header block (possibly different)
		carry set if couldn't extend

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	unlock header
	MemReAlloc( header size + extension size)
	link the new unassigned block handles

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header by calling VMLinkFree

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMExtendBlkTable	proc	far	uses bx, cx, dx, di
	.enter
EC<	call	VMCheckDSHeader						>

	push	ax
	mov	di, ds:[VMH_lastHandle]		;addr to start linking (later)

	mov	bx, ds:[VMH_blockTable].VMBH_memHandle;handle in bx
	mov	cx, size VMBlockHandle
	mul	cx				;dx:ax <- ax * cx
;EC<	ERROR_C	VM_HEADER_TOO_LARGE		;dx must be 0		>
	jc	error

	add	ax, di				;ax <- new header size
;check here also:
	jc	error
	cmp	ax, 0xfff0			;MemReAlloc allows up to this
	ja	error
;end of check
	mov	cx, (mask HAF_NO_ERR or mask HAF_ZERO_INIT) shl 8
	call	MemReAlloc
;should never return error since we pass HAF_NO_ERR
EC<	ERROR_C	VM_HEADER_TOO_LARGE		;dx must be 0		>
	mov	ds, ax

	pop	cx
	call	VMLinkFree			;link from di for cx blks
	clc					;success
exit:
	.leave
	ret

error:
	stc
	pop	cx
	jmp	short exit
VMExtendBlkTable	endp

;
; even though this doesn't return, we call it instead of jmp to it so we
; can see where it came from (even in non-EC)
;
VMExtendBlkTableError	proc	far
	LoadVarSeg	ds, ax
	mov	ds, ds:[fixedStringsSegment]
	mov	si, ds:[vmHeaderOverflow1]
	mov	di, ds:[vmHeaderOverflow2]
	mov	ax, mask SNF_EXIT
	call	SysNotify
	mov	si, -1
	mov	ax, SST_DIRTY
	call	SysShutdown
	.UNREACHED
VMExtendBlkTableError	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMLinkFree

DESCRIPTION:	Links the given number of blocks.
		Assumes that the blocks are:
			* in a contiguous chunk of memory
			* at the end of the VM header

CALLED BY:	INTERNAL (VMCreateHeader, VMExtendBlkTable)

PASS:		ds - VM header block
		di - first VM block handle from which to link
		cx - number of VM block handles to link

RETURN:		VMH_lastHandle set

DESTROYED:	di

PSEUDO CODE/STRATEGY:
	di <- first block to link
	repeat
		unassign(di)
		di <- di + size VMBlockHandle
	until done
	VMH_lastHandle <- di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header by calling VMUnassignBlk

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMLinkFree	proc	far
EC<	call	VMCheckBlkHanOffset					>

10$:
	call	VMUnassignBlk
	add	di, size VMBlockHandle
	loop	10$

	mov	ds:[VMH_lastHandle], di
	ret
VMLinkFree	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetUnassignedBlk

DESCRIPTION:	Detaches the first unassigned block for use, extending the
		header if no blocks currently unassigned.

CALLED BY:	INTERNAL (VMAlloc, VMAllocAndCopy)

PASS:		si - VM header handle
		ds - VM header

RETURN:		ds - VM header (possibly different value)
		di - VM block handle
		unassigned count decremented

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	di <- unassigned ptr
	if di = nil then
		extend VM header
		di <- unassigned ptr
	endif
	detach di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header by calling VMGetUnassignedBlkCommon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMGetUnassignedBlk	proc	far	uses ax
	.enter
EC<	call	VMCheckHeaderHandle					>
	mov	ax, 1		; empty list is ok
	call	VMGetUnassignedBlkCommon
	call	VMMaintainExtraBlkHans
	.leave
	ret
VMGetUnassignedBlk	endp




COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetUnassignedBlkMaybeExtend

DESCRIPTION:	Detaches the first unassigned block for use. If there are
		no unassigned blocks left and the header ensures the file
		is being updated synchronously (i.e. not in a short-on-memory
		situation), we allow the header to be extended.

CALLED BY:	INTERNAL

PASS:		ds - VM header

RETURN:		di - VM block handle
		unassigned count decremented

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	di <- unassigned ptr
	detach di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header by calling VMGetUnassignedBlkCommon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@
VMGetUnassignedBlkMaybeExtend	proc	near		uses ax, si
	.enter
	clr	ax
	mov	al, ds:[VMH_attributes]	; ax = 1 if update must be happening
	andnf	ax, mask VMA_SYNC_UPDATE;  synchronously (so we may resize
	rol	al			;  the header).
					CheckHack <mask VMA_SYNC_UPDATE eq 0x80>
	call	VMGetUnassignedBlkCommon
	.leave
	ret
VMGetUnassignedBlkMaybeExtend	endp

if 0		; no longer used -- ardeb 6/20


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetUnassignedBlkNoExtend

DESCRIPTION:	Detaches the first unassigned block for use. It is a fatal
		error for there not to be any unassigned blocks available.

CALLED BY:	INTERNAL (VMDoWriteBlk, VMUseBlkDoSplit)

PASS:		ds - VM header

RETURN:		di - VM block handle
		unassigned count decremented

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	di <- unassigned ptr
	detach di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMGetUnassignedBlkNoExtend	proc	near		uses ax
	.enter
	clr	ax
	call	VMGetUnassignedBlkCommon
	.leave
	ret
VMGetUnassignedBlkNoExtend	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMGetUnassignedBlkCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to remove an unassigned block from the list

CALLED BY:	INTERNAL (VMGetUnassignedBlkNoExtend, VMGetUnassignedBlk)
PASS:		ds	= grabbed header
		ax	= 0 if may not extend the header, 1 if ok.
			  if extending not allowed and no blocks are
			  available, generates a fatal error.
RETURN:		di	= VM block handle
		VMH_numUnassigned decremented
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Marks header dirty		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMGetUnassignedBlkCommon proc	near
		.enter
EC<		call	VMCheckDSHeader					>
		mov	di, ds:VMH_unassignedPtr
		;
		; To easily determine if an empty list is allowed, the caller
		; passes 0 if not and 1 if so. We then merge the head pointer
		; into the passed value. If the result is zero, it must be
		; an error. Else, we decrement the result to get rid of the
		; passed value of 1. If that results in a zero value, we need
		; to extend the header, as VMH_unassignedPtr must have been zero
		;
		or	ax, di
EC <		ERROR_Z	VM_NO_UNASSIGNED_BLOCKS_LEFT			>
		dec	ax
		jnz	gotIt
		mov	ax, VM_EXTEND_NUM_BLKS
		call	VMExtendBlkTable
		jnc	extendOK
		call	VMExtendBlkTableError		; doesn't return
extendOK:
		mov	di, ds:[VMH_unassignedPtr]
gotIt:
		clr	ax
		xchg	ax, ds:[di].VMFBH_nextPtr
		mov	ds:[VMH_unassignedPtr], ax
		dec	ds:[VMH_numUnassigned]
		call	VMMarkHeaderDirty
		.leave
		ret
VMGetUnassignedBlkCommon endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMUnassignBlk

DESCRIPTION:	Adds the given VM block handle to the unassigned list.

CALLED BY:	INTERNAL (VMFreeBlkHandle, VMCoalesceIfPossible, VMLinkFree)

PASS:		VM handle grabbed
		VM header handle grabbed
		ds - VM header
		di - VM block handle
		es - idata

RETURN:		di added to the unassigned list
		unassigned count incremented

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Marks header dirty

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMUnassignBlk	proc	far	uses ax
	.enter
EC<	call	VMCheckDSHeader						>
EC<	call	VMCheckBlkHanOffset					>

	push	es
	segmov	es, ds
	clr	ax
CheckHack <size VMBlockHandle eq 12>
	stosw
	stosw
	stosw
	stosw
	stosw
	stosw
	pop	es

	sub	di, size VMBlockHandle
	
	mov	ax, ds:[VMH_unassignedPtr]		;get cur head
	mov	ds:[di].VMFBH_nextPtr, ax		;link cur head
	mov	ds:[VMH_unassignedPtr], di		;make di the head

	inc	ds:[VMH_numUnassigned]

	call	VMMarkHeaderDirty
	.leave
	ret
VMUnassignBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMMarkBlkUsed

DESCRIPTION:	Marks the given VM block handle as used.

CALLED BY:	INTERNAL (VMUseBlk, VMAlloc)

PASS:		ds - VM header
		di - VM block handle

RETURN:		block marked used
		used count incremented

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	No need to mark the header dirty, as it should have been marked dirty
	by the getting of an unassigned block to be marked used.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMMarkBlkUsed	proc	far
EC<	call	VMCheckBlkHandle			;check di	>

EC<	test	ds:[di].VMBH_sig, VM_IN_USE_BIT	;already used?		>
EC<	ERROR_NZ VM_BLOCK_ALREADY_USED			;error if so	>

	mov	ds:[di].VMBH_sig, VMBT_USED	;mark di used
	mov	ds:[di].VMBH_flags, 0
	test	ds:[VMH_attributes], mask VMA_BACKUP
	jz	noBackup
	mov	ds:[di].VMBH_sig, VMBT_DUP	;in backup mode, any newly
						; allocated block must be
						; labeled a duplicate
noBackup:
	mov	ds:[di].VMBH_memHandle, 0	;no associated mem
	mov	ds:[di].VMBH_uid, 0		;no associated id
	inc	ds:[VMH_numUsed]
EC <	cmp	di, offset VMH_blockTable	; header block?		>
EC <	je	done	; can't possibly be dirty b/c haven't set it up yet>
EC <	call	VMCheckHeaderDirty					>
EC <done:								>
	ret
VMMarkBlkUsed	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMMaintainExtraBlkHans

DESCRIPTION:	Ensures that there are at least twice as many unassigned blk
		handles as there are resident blks.  This helps to avoid having
		to extend the block table when ThrowOutBlocks picks a VM block
		to throw out, because updating a dirty block might entail
		using two unassigned blocks.

CALLED BY:	INTERNAL (VMUpdate, VMGetUnassignedBlk, VMAlloc)

PASS:		ds - VM header

RETURN:		ds - VM header (possibly different)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	There are three things that affect the number of unassigned handles
	needed:
		- the number of resident blocks: 2 handles are needed for each
		  in the worst case (dirty block larger than the on-disk form
		  and smaller than the free block to which its data are
		  transfered). One handle must map the old disk space in the
		  assigned list while the second is needed to map the rest of
		  the formerly-assigned block that is split to hold the dirty
		  one.
		- an additional count provided by the user of the file. This
		  indicates the number of handles the user might need while it's
		  got the heap semaphore. At the moment, this is used only
		  by the object-state file mechanism in Object/objectFile.asm
		- when writing out a block, a third handle is needed for
		  several instructions, but not on a long-term basis as the
		  above-mentioned two handles are.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Dirties header, if necessary, by calling VMExtendBlkTable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@
VMMaintainExtraBlkHansFar proc far
	call	VMMaintainExtraBlkHans
	ret
VMMaintainExtraBlkHansFar endp

VMMaintainExtraBlkHans	proc	near	uses ax
	.enter
EC<	call	VMCheckDSHeader						>

	;
	; If file is synchronously updated, no need to maintain extra unassigned
	; blocks... I think.
	; But need to check if can go tempAsync.
	; 
	test	ds:[VMH_blockTable].VMBH_uid.high, 0x80
	jz	doAnyway
	test	ds:[VMH_attributes], mask VMA_SYNC_UPDATE
	jnz	done

doAnyway:
	mov	ax, ds:[VMH_numResident]
	shl	ax, 1
	add	ax, ds:[VMH_numExtraUnassigned]
	inc	ax				;one more to deal with the
						;temporary need for a 3d
						;handle in VMDoWriteBlk
	sub	ax, ds:[VMH_numUnassigned]
	jbe	done
	call	VMExtendBlkTable		;func(ds, ax)
	; ignore error, it's not fatal...yet
done:
	.leave
	ret
VMMaintainExtraBlkHans	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetNextUsedBlk

DESCRIPTION:	Locates the next used blk from the VM block handle given.
		Returns only VMBT_USED and VMBT_DUP blocks, never a VMBT_BACKUP
		or VMBT_ZOMBIE block.

CALLED BY:	INTERNAL (VMUpdate, VMLoadHeaderBlk)

PASS:		ds - VM header
		di - VM block from which to get next blk handle

RETURN:		carry - clear if found, set otherwise
		di - next used blk handle

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	No need to dirty header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMGetNextUsedBlk	proc	far
	.enter
checkLoop:
	call	VMGetNextInUseBlk
	jc	notFound
	cmp	ds:[di].VMBH_sig, VMBT_BACKUP	; actively in-use? Or just a
						;  place-holder
	jbe	checkLoop		; BACKUP or ZOMBIE -- keep looking
notFound:
	.leave
	ret
VMGetNextUsedBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetNextInUseBlk

DESCRIPTION:	Locates the next used blk from the VM block handle given.

CALLED BY:	INTERNAL (VMUpdate, VMLoadHeaderBlk)

PASS:		ds - VM header
		di - VM block from which to get next blk handle

RETURN:		carry - clear if found, set otherwise
		di - next used blk handle

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	No need to dirty header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@
VMGetNextInUseBlkFar	proc	far
	call	VMGetNextInUseBlk
	ret
VMGetNextInUseBlkFar	endp

VMGetNextInUseBlk	proc	near	uses ax
	.enter
EC<	call	VMCheckDSHeader						>

	mov	ax, ds:[VMH_lastHandle]
	dec	ax			; to allow jb, not jbe
10$:
	add	di, size VMBlockHandle
	cmp	ax, di
	jb	notFound
	test	ds:[di].VMBH_sig, VM_IN_USE_BIT	; clear => not in-use
	jz	10$
notFound:
	.leave
	ret
VMGetNextInUseBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMReadBlk

DESCRIPTION:	Load a VM block into memory from the disk. NOTE: if the passed
		memory handle is non-zero, the block is assumed to be resident
		and nothing is read.

CALLED BY:	INTERNAL

PASS:		VM handle grabbed
		ds - VM header (if reading a block other than the header)
		es - idata seg
		ax - number of bytes
		bx - VM file handle
		cx:dx - file pos
		si - 0 if anything to be read.
		di - VM block handle

RETURN:		si - VM mem handle
		VM block from file loaded into buffer referenced by si, if
		si was zero on entry

DESTROYED:	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Does not dirty the header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@
VMReadBlk	proc	near
EC<	call	AssertESKdata						>
EC<	call	VMCheckFileHandle					>
EC<	tst	si							>
EC<	je	10$							>
EC<	call	VMCheckMemHandle					>
EC<10$:									>

	tst	si			;block in memory?
	jz	notResident
	test	es:[si].HM_flags, mask HF_DISCARDED
	LONG jz	resident		;don't read if so

	;discarded -- reallocate memory

	push	ax
	push	cx
	xchg	bx, si			;bx = mem handle
			; Clear the LMEM bit so CheckHeapHandle won't choke.
			; The bit will get set again when CallVMReloc
			; is called by VMReadBlk (since VMBF_LMEM must
			; have been set for this thing...)
EC <	andnf	es:[bx].HM_flags, not mask HF_LMEM			>

			; Clear the memory handle from the block so it
			; doesn't get counted as resident by any EC code
			; called as a side-effect of the relocation routine.
			;
			; The header always gets freed, never discarded, so
			; we can't be reading in the header, hence this is
			; safe.
EC <	mov	ds:[di].VMBH_memHandle, 0				>

	mov	ch, mask HAF_NO_ERR or mask HAF_LOCK
	call	MemReAlloc
	xchg	bx, si			;si = mem handle, bx = file handle
	jmp	common

notResident:
	push	ax
	tst	ax
	jne	20$
	inc	ax			;force allocation of at least one byte
20$:
	;
	; Allocate a new handle for the block
	;
	push	cx
	mov	cx, mask HAF_LOCK shl 8	;don't zero-init the thing, but do
					; lock it so it doesn't get swapped
					; before we can use the memory
	call	VMGetMemSpaceAndSetOtherInfo	;si <- func(ax, bx, ds)
common:
	pop	cx

	;
	; Perform in-line thread-grab of the block. No-one else can be
	; interested in this block as we've got the file grabbed and the block
	; was non-resident. usageValue <- owning thread. otherInfo <- 0,
	; to indicate possession.
	; 
	cmp	di, offset VMH_blockTable; block is the header, which we
					 ;  always grab, regardless of whether
					 ;  the thing is single-thread
					 ;  or no -- ardeb 9/3/92
	je	grabezLe
	cmp	es:[si].HM_otherInfo, -1
	jz	noGrab

grabezLe:
	mov	ax, es:[currentThread]
	mov	es:[si].HM_usageValue, ax
	mov	es:[si].HM_otherInfo, 0
noGrab:

	mov	ax, es:[si].HM_addr	;fetch segment of block for reading...

	XchgTopStack	si		; save memory handle & get block size
	xchg	si, ax			; si <- block segment, ax <- block size

	;
	; Read the block to si:0
	;
	call	VMReadBlkLow

	; call relocation routine

	mov	dx, si			;dx = segment address
	pop	ax			;pass memory handle in ax

	; save the memory handle of the block and up the count of resident
	; blocks -- done here so that calls to the error checking code in
	; CallVMReloc don't die with a bad VMH_numResident

	cmp	di, offset VMH_blockTable
	jne	storeHandle
	mov	ds, dx			; ds <- header segment if we just
					;  read the sucker in.
storeHandle:
	mov	ds:[di].VMBH_memHandle, ax
	inc	ds:[VMH_numResident]

if COMPRESSED_VM
	call	VMUncompressBlk
else
EC <	test	ds:[di].VMBH_flags, mask VMBF_COMPRESSED		>
EC <	ERROR_NZ ERROR_VM_BLOCK_DATA_IS_COMPRESSED			>
endif

	mov	cx, VMRT_RELOCATE_AFTER_READ
	call	CallVMReloc

	mov	si, bx			; preserve file handle
	xchg	bx, ax			; recover block handle (1-byte inst)
	ornf	es:[bx].HM_flags, mask HF_DISCARDABLE	; mark block clean
	cmp	es:[bx].HM_otherInfo, -1
	jnz	multiThread

	FastUnLock es, bx, ax, NO_NULL_SEG

	jmp	unlockCommon
multiThread:
	call	MemThreadRelease
unlockCommon:
	xchg	bx, si
resident:
EC<	Destroy	ax, cx, dx							>
	ret
VMReadBlk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMReadBlkLow

DESCRIPTION:	Read a block from a VM file

CALLED BY:	INTERNAL (VMReadBlk, VMDoCompress)

PASS:		cx:dx	= position of disk block
		ax	= size of disk block
		bx	= VM file handle
		si	= segment of block to which to read the block

RETURN:

DESTROYED:	ax, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Does not dirty the header.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

VMReadBlkLow	proc	far
	tst	ax			;anything on disk?
	je	done			;branch if not

	push	ax			;save num bytes
	mov	al, FILE_POS_START
	call	FilePosFar		;dx:ax <- func(al, cx, dx)
	pop	cx

	push	ds

	mov	ds, si			;point ds:dx at buffer
	clr	dx
	mov	al, FILE_NO_ERRORS
; can be reading to unlocked block b/c we've got the heap semaphore, at times
EC <	call	FileReadNoCheckFar					>
NEC <	call	FileReadFar						>

;errors never returned...if we nuke use of FILE_NO_ERRORS, above, however...
;EC <	ERROR_C	VM_BAD_READ						>
	pop	ds

done:
	ret
VMReadBlkLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMUncompressBlk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompress VM block if necessary

CALLED BY:	VMReadBlk
PASS:		ds:di	= VMBlockHandle
		dx	= VM memory segment
RETURN:		dx	= VM memory segment (may have moved)
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	2/24/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if COMPRESSED_VM

VMUncompressBlk	proc	near
	uses	ax,bx,si,di,ds,es
	.enter

	test	ds:[di].VMBH_flags, mask VMBF_COMPRESSED
	jz	done

	; Allocate temporary space and uncompress VM block

	push	ds, di
	mov	ds, dx
	clr	si			;ds:si = compressed data
	lodsw				;ax = size of uncompressed block
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc		;ax,bx = func(ax,cx)
	mov	es, ax
	clr	di			;es:di = new buffer
	call	LZGUncompress		;cx = func(ds,si,es,di)
	cmp	cx, ds:[0]		;compare actual size vs. expected size
	ERROR_NE ERROR_COMPRESSED_VM_DATA_IS_CORRUPT
	pop	ds, di

	; Resize VM memory block to the uncompressed size

	push	bx, cx
	mov	ax, cx			;ax = size of uncompressed block
	mov	bx, ds:[di].VMBH_memHandle
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc		;ax = func(ax,bx,cx)
	pop	bx, cx

	; Copy uncompressed data back to the VM memory block

	segmov	ds, es
	mov	es, ax
	clr	si, di
	shr	cx, 1
	rep	movsw
	adc	cx, cx
	rep	movsb

	call	MemFree			;free temporary block
	mov	dx, es			;dx <- segment of uncompressed data
done:
	.leave
	ret
VMUncompressBlk	endp

endif	; COMPRESSED_VM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMCompressBlk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compress VM data block

CALLED BY:	VMDoWriteBlk

PASS:		ds:di	= VMBlockHandle
		es	= idata seg
		ax	= size of grabbed VM mem block to be written

		on stack: handle of compressed data block (0)
			  segment of grabbed VM mem block to be written
			  handle of grabbed VM mem block to be written

RETURN:		ax = size of data to be written

DESTROYED:	cx

SIDE EFFECTS:	if data is compressed, then segment of grabbed VM mem block
		on the stack is replaced with the segment of compressed data

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	2/25/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if COMPRESSED_VM

VMCompressBlk	proc	near		vmMemHandle:hptr,
					vmMemSegment:word,
					compressedDataBlk:hptr
	ForceRef vmMemHandle				
	uses	bx,dx,si,di,bp,ds,es
	.enter

	cmp	di, offset VMH_blockTable
	je	done				; don't compress
	cmp	ax, VM_COMPRESS_MINIMUM_BLOCK_SIZE
	jb	done				; don't compress

	; allocate compressed data block and compress the data

	mov	dx, ax				; dx = VM mem block size
	shr	ax, 3				; ax = 1/8 * block size
	add	ax, dx				; ax = 1 1/8 * block size
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			; bx = func(ax,cx)
	mov	si, ax				; si = compress data segment
	mov	ax, dx				; ax = VM mem block size
	jc	done

	mov	compressedDataBlk, bx		; save compressed data block

	; make sure we have a compress stack

	mov	bx, es:[vmCompressStack]
	tst	bx
	jnz	compress

	mov	bx, handle 0			; compress stack owned by geos
	call	LZGAllocCompressStack
	mov	es:[vmCompressStack], bx

compress:
	mov	es, si
	xchg	si, vmMemSegment		; update vmMemSegment
	mov	ds, si
	clr	si, di
	stosw					; save uncompressed size
	mov	cx, ax				; cx = uncompressed size
	call	LZGCompress			; cx = compressed size
	add	cx, size word			; add 2 for uncompressed size
	xchg	ax, cx				; ax = compressed size
	add	ax, 0x0f			; 
	andnf	ax, 0xfff0			; round up to paragraph size
	cmp	ax, cx
EC <	WARNING_A WARNING_COMPRESSED_VM_DATA_SIZE_IS_BIGGER		>
	jb	done

	; compressed size is bigger, so just use the uncompressed data

	clr	bx
	xchg	bx, compressedDataBlk
	call	MemFree				; free compressed data block
	mov	vmMemSegment, ds		; revert vmMemSegment
	mov_tr	ax, cx				; ax = uncompressed size
done:
	.leave
	ret
VMCompressBlk	endp

endif	; COMPRESSED_VM


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMWriteBlk
DESCRIPTION:	Writes the given VM block out to disk.

CALLED BY:	INTERNAL (VMUpdateHeader, VMUpdateAndRidBlk)

PASS:		VM handle grabbed
		es - idata seg
		bx - VM file handle
		si - VM header handle
		ds - VM header
		di - VM block handle
		bp - grabbed VM mem handle of blk to be written out
		dx - seg addr of blk to be written out

RETURN:		ds - VM header (possibly different)
		di - VM block handle
		file pos of block updated in VM block handle
		carry set if block couldn't be written:
			ax = error code (VM_UPDATE_INSUFFICIENT_DISK_SPACE
				if out of disk space, else FileError member
				from FileWrite)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	May dirty header by calling VMDoWriteBlk

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@
VMWriteBlkFar	proc	far
		call	VMWriteBlk
		ret
VMWriteBlkFar	endp

VMWriteBlk	proc	near	uses cx
	.enter
EC<	call	AssertESKdata						>
EC<	call	VMCheckBlkHandleAndDSHeader				>
EC<	call	VMCheckFileHandle					>
EC<	call	VMCheckHeaderHandle					>
EC<	xchg	si, bp							>
EC<	call	VMCheckMemHandle	; check si (block being written)>
EC<	xchg	si, bp							>

	test	es:[bp][HM_flags], mask HF_DISCARDABLE
	jnz	done

	;
	; Invalidate the file if this is the first write since an
	; update..  check the INVALID_FILE flag to see if this is the case
	;

	push	bp
	mov	bp, es:[bp].HM_owner	; get the HandleVM
	test	es:[bp].HVM_flags, mask IVMF_INVALID_FILE
	jnz	notFirstTime

	;
	; ok, write over the VMFH_signature with the beginning of the
	; header (the VMH_headerSig)
	;

	push	dx, ax
	or	es:[bp].HVM_flags, mask IVMF_INVALID_FILE
	clr	cx
	mov	dx, offset VMFH_signature
	mov	al, FILE_POS_START
	call	FilePosFar
	clr	dx
	mov	cx, size VMFH_signature
	clr	ax
	call	FileWriteFar
	pop	dx, ax
EC<	ERROR_C	GASP_CHOKE_WHEEZE					>
	
notFirstTime:
	pop	bp
	

EC<	xchg	bx, bp							>
EC<	call	AddToOddityList						>
EC<	xchg	bx, bp							>

	inc	es:[bp].HM_lockCount		; lock temporarily so
						; that heap stuff
						; won't be tempted to
						; throw this out..
	xchg	ax, bp				;pass memory handle in ax
	mov	cx, VMRT_UNRELOCATE_BEFORE_WRITE  ;block is going away
	call	CallVMReloc
	xchg	ax, bp				;restore registers
	dec	es:[bp].HM_lockCount
	call	VMDoWriteBlk
	jc	error

relocAndExit:
	pushf

	inc	es:[bp].HM_lockCount
	xchg	ax, bp				;pass memory handle in ax
	mov	cx, VMRT_RELOCATE_AFTER_WRITE	;block is "just loaded"
	call	CallVMReloc
	xchg	ax, bp
	dec	es:[bp].HM_lockCount
EC<	xchg	bx, bp							>
EC<	call	RemoveFromOddityList					>
EC<	xchg	bx, bp							>

	popf


done:
EC <	call	VMCheckStrucs						>
	.leave
	ret

error:
	tst	ds:[VMH_numAssigned]
	jz	fail			; Already compressed, so can't
					;  do anything
	test	ds:[VMH_compressFlags], mask VMCF_NO_COMPRESS
					; Not allowed to compress, so can't
	jnz	fail			;  do anything
	;
	; Compress the file to get us some space and try to write once more.
	;
	push	dx			; preserve block segment...
	call	VMDoCompress
	pop	dx
	call	VMDoWriteBlk
	jmp	relocAndExit
fail:
	stc
	jmp	relocAndExit
VMWriteBlk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMDoWriteBlk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform actual writing of a block that's been unrelocated

CALLED BY:	VMWriteBlk
PASS:		VM handle grabbed
		es - idata seg
		bx - VM file handle
		si - VM header handle
		ds - VM header
		di - VM block handle
		bp - grabbed VM mem handle of blk to be written out
		dx - seg addr of blk to be written out

RETURN:		ds - VM header (possibly different)
		di - VM block handle
		file pos of block updated in VM block handle
		carry set if block couldn't be written:
			ax = error code (VM_UPDATE_INSUFFICIENT_DISK_SPACE
				if out of disk space, else FileError member
				from FileWrite)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	May dirty header if the block has changed size.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMDoWriteBlk	proc	near 	uses bx, cx, dx
	.enter

if COMPRESSED_VM
	push	0			; setup initial compressed data block
endif

	push	dx

	;assert blk not discarded
EC<	test	es:[bp][HM_flags], mask HF_DISCARDED			>
EC<	ERROR_NE VM_WRITE_BLOCK_DISCARDED				>
EC<	test	es:[bp][HM_flags], mask HF_SWAPPED			>
EC<	ERROR_NE VM_WRITE_BLOCK_SWAPPED					>

	;assert mem handles match
EC<	cmp	ds:[di].VMBH_memHandle, bp				>
EC<	ERROR_NE VM_WRITE_HANDLE_MISMATCH				>

	;
	; Deal with contracting LMem and Huge Array blocks.
	; 
	test	es:[bp].HM_flags, mask HF_LMEM
	jnz	contractMe
	mov	ax, ds:[di].VMBH_uid
	cmp	ax, SVMID_HA_BLOCK_ID
	je	contractMe
	cmp	ax, SVMID_HA_DIR_ID
	jne	fetchSize
contractMe:
	call	SwapESDS		; ds <- dgroup, es <- header
	call	PHeap
	push	si, di			; these get biffed by ContractNoNotify
	xchg	bx, bp			; bx <- memory handle
	mov	cl, LCT_ALWAYS_COMPACT	; XXX: IS THIS RIGHT?
	call	ContractNoNotify
	jnc	restoreRegs

	mov	al, DEBUG_REALLOC
	call	FarDebugMemory		; notify Swat of the change (HM_addr
					;  is still 0, but dx = segment)
restoreRegs:
	xchg	bx, bp
	pop	si, di
	call	VHeap
	call	SwapESDS		; ds <- header, es <- dgroup

	test	es:[bp].HM_flags, mask HF_LMEM
	jz	fetchSize
	push	ds
	mov	ds, dx
	mov	ds:[LMBH_handle], di
	pop	ds

fetchSize:
	push	bp

	mov	ax, es:[bp][HM_size]		;bp <- size of blk in mem
	mov	cl, 4				;mult by 16 to conv to bytes
	shl	ax, cl

if COMPRESSED_VM
	;
	; ds:di = VMBlockHandle
	; ax = size of grabbed VM mem block to be written
	;
	; on stack: handle of compressed data block (0)
	;	    segment of grabbed VM mem block to be written
	;	    handle of grabbed VM mem block to be written
	;
	call	VMCompressBlk
endif

	mov	bp, ax

	;get data of blk already on disk
	mov	ax, ds:[di].VMBH_fileSize

	cmp	di, offset VMH_blockTable	;don't backup the header
	je	compareSizes

	test	ds:VMH_attributes, mask VMA_BACKUP
	jz	compareSizes
	cmp	ds:[di].VMBH_sig, VMBT_USED
	je	doBackup
compareSizes:
	cmp	bp, ax				;cmp size in mem and on disk
	jbe	blockSmallerOrSame

;-----------------------------------------------------------------------
;block in mem is greater than blk on disk, or we're in backup mode and
;the block has no backup copy yet. Free (or backup) the old space and
;allocate new stuff for the block.
;-----------------------------------------------------------------------
doBackup:
	;
	; Get an unassigned block, copy the file space to it and either free it
	; or turn in into a BACKUP block that points at this block (which
	; becomes a DUP block)
	;
	push	si
	call	VMBackupBlockIfNeeded
	;
	; We have some problems with writing the header for a SYNC_UPDATE file
	; at this point, as VMBackupBlockIfNeeded could have, by calling
	; VMDuplicateHandle, caused the header to enlarge and shift on the heap.
	; The shifting on the heap is taken care of later, but we have to have
	; the correct size when allocating space for the thing. Once VMBBIN has
	; been called, there is *guaranteed* to be at least one unassigned
	; handle in the header (b/c the duplicate of the header handle is
	; always freed by VMBBIN), so VMUseBlk (which only needs one unassigned
	; handle to do its work) will *never* cause the header to expand. SO,
	; if we're writing the header, fetch its size again from its handle here
	; into BP. This will be used for all further calculations...
	;
	; WRONG! If there were no assigned blocks near the old header, the block
	; just freed will be an assigned block, not unassigned as is asserted
	; by the goober in the preceding paragraph. We have to actually see if
	; there's a block around for our purposes and if not, forcibly extend
	; the header to have one.
	; 
	cmp	si, offset VMH_blockTable
	jne	getMoreSpace

	cmp	ds:[VMH_numUnassigned], 1
	jae	fetchNewHeaderSize
	; This should *only* be necessary for sync-update files, as async-update
	; ones maintain extra block handles for this purpose...
EC <	test	ds:[VMH_attributes], mask VMA_SYNC_UPDATE		>
EC <	ERROR_Z	GASP_CHOKE_WHEEZE					>

	mov	ax, 1				; give us another block, please
	call	VMExtendBlkTable
	jnc	fetchNewHeaderSize
	call	VMExtendBlkTableError		; doesn't return

fetchNewHeaderSize:
	mov	bp, ds:[si].VMBH_memHandle
	mov	bp, es:[bp].HM_size
	mov	cl, 4				;mult by 16 to conv to bytes
	shl	bp, cl

getMoreSpace:
	;
	; Now allocate another piece of the file of the proper size. This may
	; end up re-using the space we had before, if there was a free block big
	; enough immediately following the old used block.
	;
	mov	ax, bp
	call	VMUseBlk		; doesn't nuke ax
	;
	; Record the block's position, as returned by VMUseBlk (which also
	; positions the file there), and release the handle we got back (do
	; not release the file space, of course).
	;
	mov	ds:[si].VMBH_fileSize, ax
	mov	ds:[si].VMBH_filePos.low, dx
	mov	ds:[si].VMBH_filePos.high, cx
	call	VMUnassignBlk
	dec	ds:VMH_numUsed
	;
	; Point di back at the block we're writing.
	;
	mov	di, si
	pop	si
	;
	; Adjust record of used block size (which was downgraded by
	; VMFreeBlkHandle). This is the *only* place that VMH_usedSize gets
	; added to, because this is the *only* place where we allocate
	; file space for a block.
	;
	add	ds:VMH_usedSize.low, bp
	adc	ds:VMH_usedSize.high, 0
	jmp	writeBlockCopyBP

blockSmallerOrSame:

	mov	dx, ds:[di].VMBH_filePos.low
	mov	cx, ds:[di].VMBH_filePos.high
	je	writeBlock			;don't free anything if whole
						; block required.

;-----------------------------------------------------------------------
;block in mem is smaller than blk on disk, so place the remainder of the
;block into an assigned block.
;-----------------------------------------------------------------------
	;
	; Free up extra space by fetching an unassigned block and giving it
	; the space we don't need, then passing it to VMFreeBlkHandle
	; for coalescing and linking.
	;
	push	di
	call	VMGetUnassignedBlkMaybeExtend	;get an unassigned blk to hold
						; extra stuff

	add	dx, bp				;point cx:dx at pos for free blk
	adc	cx, 0
	mov	ds:[di].VMBH_filePos.low, dx
	mov	ds:[di].VMBH_filePos.high, cx
	sub	ax, bp				;compute size of free
	mov	ds:[di].VMBH_fileSize, ax

	; fix file size to keep EC code happy
EC <	pop	ax		;ax = block handle			>
EC <	push	ax							>
EC <	xchg	ax, bp		;ax = size, bp = block handle		>
EC <	mov	ds:[bp].VMBH_fileSize, ax				>
EC <	xchg	ax, bp		;bp = size				>

	call	VMFreeBlkHandle			;put handle in free list
	pop	di
	;
	; Position the file at the start of the used block, something that
	; VMUseBlk does for the block-be-bigger case.
	;
	sub	dx, bp				;point cx:dx back at used block
	sbb	cx, 0
writeBlock:
	mov	al, FILE_POS_START
	call	FilePosFar
writeBlockCopyBP:
	xchg	ax, bp				;(1 byte move)
	;-----------------------------------------------------------------------
	;write mem block out
	pop	bp
	mov	ds:[di].VMBH_fileSize, ax

EC<	test	es:[bp][HM_flags], mask HF_DISCARDABLE			>
EC<	ERROR_NZ VM_BLOCK_NOT_DIRTY					>

	;assert used
EC<	cmp	ds:[di].VMBH_sig, VMBT_DUP				>
EC<	ERROR_B VM_DISCARDING_NON_USED_BLOCK				>

	;assert blk has file data
EC<	tst	ds:[di].VMBH_fileSize					>
EC<	ERROR_E	VM_BLOCK_HAS_NO_DATA					>

EC<	cmp	ds:[di].VMBH_filePos.low, 0				>
EC<	jne	80$							>
EC<	cmp	ds:[di].VMBH_filePos.high, 0				>
EC<	ERROR_E	VM_BLOCK_HAS_NO_FILE_POSITION				>
EC<80$:									>

	mov	cx, ax				;num bytes in cx

	pop	dx				;retrieve seg addr of blk
	cmp	di, offset VMH_blockTable	;writing header block?
	jne	doWrite
	mov	dx, ds				;header might have moved during
						; the above gyrations, so fixup
						; dx, both for our own use and
						; so the caller's got it right.

doWrite:
	push	dx, ds
	mov	ds, dx				;we have block locked or
						; have heap sem
	clr	dx
	clr	al
	;
	; When called from VMUpdateAndRidBlk, the block in question is
	; unlocked. Calling FileWrite with segment-checking on causes
	; unnecessary death...
	; 
EC <	call	FileWriteNoCheckFar					>
NEC <	call	FileWriteFar						>
	pop	dx, ds

if COMPRESSED_VM
	pop	cx				;^hcx = compressed data block
	jcxz	noFree				;skip if no compressed block

	lahf					;save FileWrite error flag
	xchg	bx, cx				;bx = compressed data block
	call	MemFree				;free compressed data block
	mov	bx, cx				;bx = VMFileHandle, cx!=0
	sahf					;restore FileWrite error flag
noFree:
endif	

	jc	error

	ornf	es:[bp][HM_flags], mask HF_DISCARDABLE	;mark block clean

if COMPRESSED_VM
	andnf	ds:[di].VMBH_flags, not mask VMBF_COMPRESSED
	jcxz	notCompressed
	ornf	ds:[di].VMBH_flags, mask VMBF_COMPRESSED
notCompressed:
endif

EC <	call	VMVerifyWrite						>
done:
	.leave
	ret
error:
	;
	; Wait -- We could not write out the data.  We must fix up the state of
	; the file by freeing the file space that we tried unsuccessfully to use
	;
	push	si
	call	VMDuplicateHandle		;di <- duplicate, si = original
	call	VMFreeBlkHandleAndIncNumUsed
	mov	di, si
	pop	si
EC <	call	VMCheckStrucs						>

	cmp	ax, ERROR_SHORT_READ_WRITE
	stc
	jne	done
	mov	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
	jmp	done
VMDoWriteBlk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMBackupBlockIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an unassigned block, copy the file space to it and either
		free it or turn in into a BACKUP block that points at this block
		(which becomes a DUP block). Which is done depends on the
		VMA_BACKUP bit in the header.

CALLED BY:	VMDoWriteBlk, VMFree
PASS:		VM handle grabbed
		es - idata seg
		bx - VM file handle
		ds - VM header
		di - VM block handle

RETURN:		ds - VM header (possibly different)
		di - newly allocated handle (freed or VMBT_BACKUP)
		si - VM block handle passed (VMBT_USED, or VMBT_DUP with
							 VMF_HAS_BACKUP set)
		     its file space has been released.

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Marks header dirty by calling VMGetUnassignedBlkMaybeExtend
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMBackupBlockIfNeededFar proc far
	call	VMBackupBlockIfNeeded
	ret
VMBackupBlockIfNeededFar endp

VMBackupBlockIfNeeded	proc	near
	;
	; Call common routine to allocate an unassigned block and copy this
	; block's data there
	;
	call	VMDuplicateHandle	;di <- new block, si <- block being
					;			backed up
	;
	; If we're in backup mode and the block being written is VMBT_USED, we
	; just want to switch the signature of the duplicate to be VMBT_BACKUP
	; and give it no memory.
	;
	cmp	si, offset VMH_blockTable
	je	doFree			; header never gets backed up
	cmp	ds:[si].VMBH_sig, VMBT_DUP
	je	doFree			;we're here b/c block grew
	test	ds:[VMH_attributes], mask VMA_BACKUP
	jz	doFree			;ditto
	;
	; Transform the unassigned block to which we just gave this block's
	; file space into a BACKUP block whose uid field holds the handle of
	; the in-use block, which we transform into a DUP block in honor of
	; this transformation.
	; 
	mov	ds:[di].VMBH_sig, VMBT_BACKUP
	mov	ds:[di].VMBH_uid, si
	mov	ds:[si].VMBH_sig, VMBT_DUP
	ornf	ds:[si].VMBH_flags, mask VMBF_HAS_BACKUP
	ret

doFree:
	FALL_THRU	VMFreeBlkHandleAndIncNumUsed

VMBackupBlockIfNeeded	endp

VMFreeBlkHandleAndIncNumUsed	proc	near
	;
	; Free the duplicated handle. This may or may not release the handle
	; itself, depending on whether the freed space can be coalesced.
	;
	call	VMFreeBlkHandle
	inc	ds:VMH_numUsed		;compensate for dec owing to block
					; appearing in-use
	ret
VMFreeBlkHandleAndIncNumUsed	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMDuplicateHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate an unassigned block and make it a copy of the passed
		block, except give it no associated memory

CALLED BY:	VMBackupBlockIfNeeded, VMDoWriteBlk
PASS:		VM handle grabbed
		es - idata seg
		bx - VM file handle
		si - VM header handle
		ds - VM header
		di - VM block handle

RETURN:		ds - VM header (possibly different)
		di - newly allocated handle
		si - VM block handle passed without its file space

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMDuplicateHandle	proc	near
	;
	; First get an unassigned block to which we can copy the proper size and
	; position data from the old disk block
	;
	mov	si, di		; si <- block being backed up
	call	VMGetUnassignedBlkMaybeExtend
	;
	; Copy in the file size and position.
	;
	mov	cx, size VMBlockHandle/2
	push	es
	segmov	es, ds
	rep	movsw
	pop	es
	sub	si, size VMBlockHandle
	sub	di, size VMBlockHandle

	mov	ds:[di].VMBH_memHandle,0;new block doesn't get old's memory...

					;nor does old block retain file space
	mov	ds:[si].VMBH_fileSize, cx
	mov	ds:[si].VMBH_filePos.low, cx
	mov	ds:[si].VMBH_filePos.high, cx
	ret

VMDuplicateHandle	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CallVMReloc

DESCRIPTION:	Call the VM relocation routine (if one exists). Also deal
		with initializing the lmem heap (in the EC version) and
		marking the block as an LMEM block.

CALLED BY:	INTERNAL

PASS:
	cx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE
	VM handle grabbed
	ds - VM header
	es - idata seg
	bx - VM file handle
	di - VM block handle
	dx - seg addr of blk to be relocated/unrelocated
	ax - memory handle

RETURN:
	none

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Does not dirty the header, even if VMBF_LMEM is set for the block,
	on the assumption that either (1) the bit was set before, so there's
	no need to mark the header dirty, or (2) if the bit wasn't set before,
	the block must never have been written to the file, so the act of
	giving the block file space will have marked the header dirty.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

CallVMReloc	proc	near
	; call relocation routine (if one exists)

	cmp	di, offset VMH_blockTable
	jz	noRelocate
	push	si
	mov	si, ax
	jcxz	checkLMemInit

	; Check for special initialization for huge array blocks

EC <	cmp	ds:[di].VMBH_uid, SVMID_HA_DIR_ID			>
EC <	jz	haInit							>
EC <	cmp	ds:[di].VMBH_uid, SVMID_HA_BLOCK_ID			>
EC <	jnz	afterHAInit						>
EC <haInit:								>
EC <	cmp	cx, VMRT_RELOCATE_AFTER_READ				>
EC <	jne	afterHAInit						>
EC <	call	ECLMemInitHeap						>
EC <afterHAInit:							>

	;
	; In the EC kernel, initialize the ends of all chunks and all free
	; blocks to the required 0xcc so EC code doesn't choke.
	;
	; In both ec and non-ec, mark the block as an LMEM block after
	; setting its handle.
	; 
	test	ds:[di].VMBH_flags, mask VMBF_LMEM
	jz	afterLMemInit

	push	ds
	mov	ds, dx
	mov	ds:[LMBH_handle], si
	ornf	ds:[LMBH_flags], mask LMF_IS_VM
	pop	ds

	ornf	es:[si].HM_flags, mask HF_LMEM

EC <	cmp	cx, VMRT_RELOCATE_AFTER_READ				>
EC <	jne	checkObject						>
EC <	call	ECLMemInitHeap						>
checkObject:

	;
	; If the file has object relocation enabled and the block is an
	; object block, use our own relocation routine to relocate or
	; unrelocate the block in question.
	;
	mov	si, {word} ds:[VMH_attributes]
	test	si, mask VMA_OBJECT_RELOC
	jz	afterLMemInit
	push	ds
	mov	ds, dx
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	pop	ds
	jne	afterLMemInit

	call	PushAll
	call	VMObjRelocOrUnReloc
	jmp	popAndFinish

afterLMemInit:

	mov	si, es:[bx].HF_otherInfo	;si = HandleVM
	tst	es:[si].HVM_relocRoutine.segment;test for relocRoutine
						;is to just test the segment!
	jz	noRelocatePop

	call	PushAll
	mov	bp, ds:[di].VMBH_uid
	call	es:[si].HVM_relocRoutine

popAndFinish:
	call	PopAll

noRelocatePop:
	pop	si
noRelocate:
	ret

checkLMemInit:
	;
	; Set the VMBF_LMEM bit in the block handle if the block being
	; unrelocated has its LMEM bit set. This must be done both in the
	; EC and the NEC cases, as it's intended to allow files written by
	; the NEC kernel to be read by the EC kernel.
	; 
	test	es:[si].HM_flags, mask HF_LMEM
	jz	afterLMemInit
	
	ornf	ds:[di].VMBH_flags, mask VMBF_LMEM
	jmp	checkObject
CallVMReloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFindFollowingUsedBlk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the used block that should follow the given assigned
		block.

CALLED BY:	VMDoCompress, VMCheckCoalescing
PASS:		ds	= VMHeader
		bp	= VMFreeBlockHandle of assigned block to check
RETURN:		carry set if no used block follows, else:
		di	= VMBlockHandle of following used block
		cx:dx	= file position of block
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMFindFollowingUsedBlk		proc	far
		.enter
		mov	dx, ds:[bp].VMFBH_fileSize.low
		mov	cx, ds:[bp].VMFBH_fileSize.high

		add	dx, ds:[bp].VMFBH_filePos.low	;get start of used
		adc	cx, ds:[bp].VMFBH_filePos.high	;block for which to
							;search
		; Start searching with the header block
		mov	di, VMH_blockTable - size VMBlockHandle
10$:
		call	VMGetNextInUseBlk	;look for BACKUP blocks, too...
		jc	done
		cmp	dx, ds:[di].VMBH_filePos.low
		jne	10$
		cmp	cx, ds:[di].VMBH_filePos.high
		jne	10$
done:
		.leave
		ret
VMFindFollowingUsedBlk		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMCheckCompression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the file should be compressed

CALLED BY:	VMUseBlkDoExtend, VMFree
PASS:		ds	= VM header
		bx	= VM file handle
		es	= idata
RETURN:		nothing
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties the header if VMDoCompress is called...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMCheckCompression	proc	far	uses ax, di
	.enter
	;-----------------------------------------------------------------------
	;check on compression ratio

	test	ds:[VMH_compressFlags], mask VMCF_NO_COMPRESS
	jnz	done

	call	FileSize			;dx:ax = file size

	; Since VMDoCompress no longer immediately truncates the file after
	; completing its work, further computations of the compression ratio
	; are skewed by the remaining final assigned block.  If the last block
	; in the file is assigned, subtract its length from the returned
	; total file size. -dhunter 4/17/2000

	tst	ds:[VMH_numAssigned]
	jz	noLastAssigned		; no assigned blocks
	push	bp
	mov	bp, ds:[VMH_lastAssigned]
	push	dx			; preserve across call
	call	VMFindFollowingUsedBlk
	pop	dx
	jnc	noLastAssignedPopBP	; => free block not at end of file
	subdw	dxax, ds:[bp].VMFBH_fileSize
noLastAssignedPopBP:
	pop	bp
noLastAssigned:

	push	bx
	mov	bx, ds:[VMH_usedSize.low]
	mov	cx, ds:[VMH_usedSize.high]
	; Make sure usedSize non-zero to avoid divide-by-zero exceptions
	tst	bx				;done if cx:bx = 0
	jne	10$
	jcxz	popFileHandle		; will jmp to done after popping b/c
					; ZF is obviously set from the tst bx

10$:
	; maintain compression ratio
	; dx:ax = file size
	; cx:bx = size of used blocks
	;
	; We only want to use simple multiply/divide, so shift values down,
	; discarding insignificant bits, until we've got the significant piece
	; of the larger number (the file size) all in ax. We only need a coarse
	; approximation, after all.
	; 
	tst	dx
	jz	checkRatio	; dx == 0 => already in ax
	tst	dh
	jnz	shiftWord	; all of dx is significant
	;
	; Only dl is significant -- drop the low byte of both values
	;
	mov	al, ah
	mov	ah, dl
	mov	bl, bh
	mov	bh, cl
	jmp	checkRatio
shiftWord:
	mov	ax, dx
	mov	bx, cx
checkRatio:
	;
	; Figure (used * 100)/total to get percentage of file used in ax. If
	; this percentage drops below the compaction threshold, we need to
	; compress the file.
	; 
	xchg	ax, bx
	mov	dx, 100
	mul	dx
	div	bx
	cmp	ax, ds:VMH_compactionThreshold
	
popFileHandle:
	pop	bx				;retrieve VM file handle
	jae	done

	call	VMDoCompress			;destroys ax, cx, dx

done:
	.leave
	ret
VMCheckCompression	endp
kcode	ends

VMHigh	segment	resource	; XXX: better name
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMDoCompress

DESCRIPTION:	Performs compression by making all used blocks on disk
		consecutive. The single assigned block at the end of the file
		is then truncated.

CALLED BY:	INTERNAL (VMUseBlkDoExtend)

PASS:		VM handle grabbed (exclusive access to file)
		bx - VM file handle
		ds - VM header

RETURN:		nothing

DESTROYED:	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
    loop till done
	bp <- head of assigned list
	di <- blk handle of used blk starting at the end of the assigned blk
	done if none
	case block status in
		non-resident:
			load block, write at new position and discard
		resident and clean:
			if block locked (grabbed by someone else):
				release file space to assigned block and mark
				block as dirty
			else
				switch file positions and mark block dirty
		resident and dirty:
			release file space to assigned block

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Dirties the header by calling VMUnassignBlk at the end

	NOTE: THIS WILL NOT FUNCTION PROPERLY IF THE FILE IS IN BACKUP MODE
	AND HAS BACKUP BLOCKS. THIS IS WHY COMPRESSION IS TURNED OFF FOR
	BACKUP-MODE FILES UNTIL A SAVE OR REVERT IS PERFORMED.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMDoCompress	proc	far
EC<	call	VMCheckFileHandle					>
EC<	call	VMCheckStrucs						>

	test	ds:[VMH_compressFlags], mask VMCF_NO_COMPRESS or \
					mask VMCF_COMPRESSING
	jnz	noCompress

	;
	; don't attempt to compress if the file is read-only, as we won't be
	; able to write out any non-resident blocks that we want to copy down,
	; so the exercise is both pointless and dangerous -- ardeb 10/6/94
	; 
	push	ds
	LoadVarSeg	ds, ax
			CheckHack <FA_READ_ONLY eq 0>
	test	ds:[bx].HF_accessFlags, mask FFAF_MODE
	pop	ds
	jz	noCompress

	tst	ds:[VMH_assignedPtr]		;any assigned blocks?
	jnz	doCompress
noCompress:
	ret

doTruncate:
; Error-checking: bp should be the first, last and only assigned block now
EC<	cmp	bp, ds:[VMH_assignedPtr]				>
EC<	ERROR_NE	VM_COMPRESS_HOSED				>
EC<	cmp	bp, ds:[VMH_lastAssigned]				>
EC<	ERROR_NE	VM_COMPRESS_HOSED				>
EC<	cmp	ds:[VMH_numAssigned], 1					>
EC<	ERROR_NE	VM_COMPRESS_HOSED				>

	add	sp, 4				; discard file pos of
						;  final assigned blk, as
						;  we no longer truncate
						;  here
compressDone:
	pop	bp, di, si, es
	call	VMReleaseExtraDiskLock
	BitClr	ds:[VMH_compressFlags], VMCF_COMPRESSING
	ret

doCompress:
	BitSet	ds:[VMH_compressFlags], VMCF_COMPRESSING
	call	VMAddExtraDiskLock

	push	bp, di, si, es
	LoadVarSeg	es
blockLoop:
	mov	bp, ds:[VMH_assignedPtr]	;fetch earliest assigned block

	push	ds:[bp].VMFBH_filePos.high	;save start of block
	push	ds:[bp].VMFBH_filePos.low

	call	VMFindFollowingUsedBlk
	jc	doTruncate

	mov	ax, ds:[di].VMBH_fileSize	;get num bytes
	;
	; Figure the status of the block with regards to its residence,
	; dirtiness, etc. etc. etc.
	; 
	mov	si, ds:[di].VMBH_memHandle
	tst	si				;is block in memory?
	jz	blkOnDisk
	test	es:[si].HM_flags, mask HF_DISCARDED
	jz	blkInMem
blkOnDisk:

;----------------------------------------------------------------------
; Block is out on disk. While we could copy it down in pieces, keeping
; the amount of memory required for this process small, it's
; easier for now to just read the beastie in whole and write it out
; whole.
;----------------------------------------------------------------------
	pop	dx			; cx:dx <- destination position
	pop	cx

	push	ax			; save # bytes to write
	mov	si, es:[bx].HF_otherInfo; si <- HandleVM
	call	VMCopyNonRes
	pop	ax			; ax <- # bytes written
	jc	compressDone		; if we couldn't copy the non-resident
					;  block properly, we stop the
					;  compress right away. -- ardeb 10/6/94


	mov	ds:[di].VMBH_filePos.low, dx	; set file pos for block
	mov	ds:[di].VMBH_filePos.high, cx
	;
	; Adjust the position of the assigned block
	;
	add	dx, ax
	adc	cx, 0
	mov	ds:[bp].VMFBH_filePos.low, dx
	mov	ds:[bp].VMFBH_filePos.high, cx
coalesce:
	;
	; Coalesce the assigned block with any now-neighboring assigned block.
	; 
	mov	di, bp
	mov	bp, ds:[bp].VMFBH_nextPtr
	call	VMCoalesceIfPossible
	;
	; Mark the file as modified so the VMHeader will be updated
	;
	push	bp
	mov	bp, es:[bx].HF_otherInfo
	ornf	es:[bp].HVM_flags, mask IVMF_FILE_MODIFIED
	pop	bp

	jmp	blockLoop
	
;-----------------------------------------------------------------------
; Block is in memory. Give its disk space to the assigned block and mark
; it as dirty so that it will get written out later.
;-----------------------------------------------------------------------
blkInMem:
EC<	call	AssertESKdata						>
EC<	push	bp, bx, di						>
EC<	mov	bp, ds:[VMH_assignedPtr]				>
EC<	mov	bx, ds:[VMH_lastAssigned]				>
EC<	call	VMCheckCoalescing					>
EC<	pop	bp, bx, di						>
	pop	dx				;recover file pos of assigned
	pop	cx				; block

	add	ds:[bp].VMFBH_fileSize.low, ax
	adc	ds:[bp].VMFBH_fileSize.high, 0

	sub	ds:[VMH_usedSize.low], ax	;file space no longer in-use
	sbb	ds:[VMH_usedSize.high], 0
EC <	ERROR_B	GASP_CHOKE_WHEEZE				>

	clr	ax				; mark block as having
						;  no file space allocated
	mov	ds:[di].VMBH_fileSize, ax
	mov	ds:[di].VMBH_filePos.low, ax
	mov	ds:[di].VMBH_filePos.high, ax

	push	bp
	mov	bp, es:[bx].HF_otherInfo
	ornf	es:[bp].HVM_flags, mask IVMF_FILE_MODIFIED
	pop	bp
	andnf	es:[si].HM_flags, not mask HF_DISCARDABLE; Mark block dirty so
							;  it does get written
	jmp	coalesce

VMDoCompress	endp

VMHigh	ends

VMSaveRevertCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMAllocThis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a specific VM block handle

CALLED BY:	VMTransfer
PASS:		di	= VM block handle to allocate
		bx	= HandleVM of file in which to allocate
			  (grabbed/entered)
		ax	= uid for block
		cl	= flags for the block
RETURN:		carry set if handle already in-use
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The unassigned list is linked in reverse order, while VMSaveAs
		works forward. Perhaps VMSaveAs should work backwards?

		Dirties header directly if desired blk is unassigned.
		Dirties header via VMDetachBlk and VMGetUnassignedBlk
		    if desired blk is assigned.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMAllocThis	proc	near	uses es, si, ds, bp, dx, cx
		.enter
	;
	; Lock the header for the file down.
	;
		LoadVarSeg	ds
		mov	si, ds:[bx].HVM_headerHandle
		mov	bp, ds:[bx].HVM_fileHandle
		xchg	bx, bp
		call	VMLockHeaderBlk		; ds = header segment
	;
	; Extend the header as necessary to get to the desired handle
	;
		push	ax
		push	cx
		lea	ax, [di+size VMBlockHandle]	; Convert to value fit
							; for VMH_lastHandle
		sub	ax, ds:[VMH_lastHandle]
		jbe	handleExists
		mov	cx, size VMBlockHandle
		clr	dx
		div	cx
		call	VMExtendBlkTable
		jnc	handleExists
		call	VMExtendBlkTableError		; doesn't return
handleExists:
	;
	; See if the handle is in-use
	;
		test	ds:[di].VMBH_sig, VM_IN_USE_BIT
		jnz	eeeeeeeeek
	;
	; Handle not in use. If it has no file space, look for the thing on the
	; unassigned list.
	;
		mov	ax, ds:[di].VMFBH_fileSize.low
		or	ax, ds:[di].VMFBH_fileSize.high
		jnz	findAssigned
		push	si		; Save header handle for release
		mov	ax, offset VMH_unassignedPtr - offset VMFBH_nextPtr
findLoop:
		xchg	ax, si		; (1-byte inst)
		mov	ax, ds:[si].VMFBH_nextPtr
		cmp	di, ax
		jne	findLoop
		mov	ax, ds:[di].VMFBH_nextPtr
		mov	ds:[si].VMFBH_nextPtr, ax
		dec	ds:[VMH_numUnassigned]
		call	VMMarkHeaderDirty
haveHandle:
		call	VMMarkBlkUsed
		pop	si
		pop	cx			;cl = flags
		and	cl, mask VMBF_PRESERVE_HANDLE
		mov	ds:[di].VMBH_flags, cl
		pop	ds:[di].VMBH_uid
		clc			; happiness
done:
		call	VMReleaseHeader	; flags preserved
		mov	bx, bp		; bx = HandleVM again
		.leave
		ret
eeeeeeeeek:
	; This should never happen, given when this function is being used,
	; hence the funky label.
		pop	cx
		pop	ax
		stc
		jmp	done
findAssigned:
	;
	; Ugly case. We need to remove the thing from the assigned list,
	; transfer the file space to an unassigned block, then put that block
	; on the assigned list.
	;
		call	VMDetachBlk
		push	si		; save header handle for "haveHandle"
		push	bx		; save bx b/c we need to preserve it
		push	di		; save di b/c it's wednesday
		call	VMGetUnassignedBlk
		pop	si		; recover block handle to si for xchg
		;
		; Exchange file size and position between former assigned block
		; and just-acquired unassigned block.
		;
		mov	bx, offset VMFBH_fileSize.low
		mov	cx, 4
		call	VMExchangeWords
		;
		; Put the former unassigned block on the assigned list.
		;
		call	VMAssignBlk
		xchg	si, di		; di = desired handle
		pop	bx		; restore passed bx
		jmp	haveHandle
VMAllocThis	endp

VMSaveRevertCode	ends
