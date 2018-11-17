COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Object
FILE:		objectFile.asm

ROUTINES:
	Name			Description
	----			-----------
    EXT	FullObjLock		Re-load an object block, taking into account
    				information from any associated state file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines manipulate an application's state file

	Object blocks run by a thread other than the ui or an application's
	process thread will lose the associated thread and will be run by the
	application's process thread when the block is loaded from the state
	file. The application needs to map a block to its VM id with
	ObjMapSavedToState (unrelocation) and back again (relocation) to deal
	with this, forking whatever threads are necessary and calling
	HandleModifyOwner on the blocks to set the thread to run each block.
	
	$Id: objectFile.asm,v 1.1 97/04/05 01:14:44 newdeal Exp $

------------------------------------------------------------------------------@

ObjectLoad	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	FullObjLock

DESCRIPTION:	Call FullLockReload to reload an object block

CALLED BY:	EXTERNAL

PASS:
	bx - handle

RETURN:
	ax - data address

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

FullObjLock	proc	far	uses bx, cx, dx, si, di, bp, ds, es
	.enter

	; see if this is a VM block. Must be done before FindDuplicate since
	; owner isn't geode handle if block *is* from the VM file.

	LoadVarSeg	ds

	mov	si, ds:[bx].HM_owner
	cmp	ds:[si].HG_type, SIG_VM
	jnz	notVM

	; it's a VM block -- get VM code to reload it from the file. We
	; call VMUnlock and use NearLock instead so the file can be updated
	; properly. VMLock leaves the handle grabbed, so anyone else trying
	; to close the file will get a BLOCK_DIRTY error from VMFreeAllBlks
	; unless we release the thing and lock it in the normal way.
	;
	; 11/9/90: well, tony changed this to just do a VMLock, but that
	; has the problems outlined above (not that anyone but the driving
	; thread should be closing the file, but...), as well as causing
	; problems for certain applications that think they can call
	; VMLock on an object block in their data files and have it work.
	; Since only the thread that opened the file should be trying to
	; lock down object blocks in it (ObjLockObjBlock enforces this in
	; the EC version), we have only to change the HM_otherInfo field of
	; the handle back to 1 (its state before the MemThreadGrab that
	; VMLock performed) so any future VMLocks performed on the beast
	; don't block indefinitely, should the block be discarded. -- ardeb
	; 
	call	VMMemBlockToVMBlock		;ax=vm block, bx=vm file
	call	VMLock
	cmp	ds:[bp].HM_otherInfo, -1	;single-thread access?
	je	toDone				;yes -- leave it alone
	mov	ds:[bp].HM_otherInfo, 1		;else mark as unowned
toDone:
	jmp	done

notVM:
	;op = FullLockReload(han, ReLoadResource)	/* Load in block */

	; see if the block is a duplicate block
	; if so, load it from saved VM handle

	call	FindDuplicate			;is it a duplicate block ?
	jc	notDup

	; ds = idata, si = HandleSavedBlock found, cx = VM file handle

	mov	bp, cx				;bp = VM file

	mov	ax,ds:[si].HSB_vmID		;steal the block from the
						;  state file
	mov	cx,ds:[bx].HM_owner
	xchg	bx, bp				; bx = VM file, bp = block
	call	VMDetach			; di = handle
	xchg	bx, bp

	; 11/20/90 -- Evil timing hole here.  If this block is swapped while
	; we are doing the MemReAlloc, the MemSwap will yield a locked block
	; with a data address of 0.

	; Lock the detached block so that it does not get swapped

	xchg	bx, di
	call	MemLockSkipObjCheck
	xchg	bx, di

	mov	ch,HAF_STANDARD_NO_ERR_LOCK
	mov	ax, 1
	call	MemReAlloc			;allocate dummy paragraph
						; so flags are matched between
						; the handle VMLock returns and
						; this one.

	mov	si, di
	call	MemSwap				;give memory to handle being
						; locked

	call	MemDerefDS			;block is already locked
	mov	ds:[LMBH_handle],bx		;setup lmem header

	xchg	bx, si				;free the block we got from the
	call	MemFree				; vm file
	xchg	bx, si

; Hard to know in TransferToVM if we registered VM_NUM_EXTRA or VM_NUM_EXTRA-1
; for a block and reducing by too many causes painful errors, so just screw
; it and go for one extra...
;	mov	ax,VM_NUM_EXTRA-1		;add extra unassigned for when
;						; this resource needs to go out.
;						; Don't need the full complement
;						; as we've already got a VM
;						; block handle
	jmp	common

notDup:
	;
	; Actually a resource block, not a saved duplicate. These things come in
	; from their object file before being merged with any saved state
	; block (they're not saved wholesale like duplicates)...
	;
	LoadVarSeg	ds
	call	LockDiscardedResource

	;if (LMF_IN_RESOURCE) {		/* If just loaded in */

	mov	dx,ds:[bx].HM_size		;dx = size
	mov	ds,ax
	test	ds:[LMBH_flags],mask LMF_IN_RESOURCE
	jz	toDone

EC <	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	ERROR_NZ	LMF_IN_RESOURCE_FLAG_SET_ON_NON_OBJECT_BLOCK	>

	mov	ds:[LMBH_handle],bx		;stuff block handle

	;	LMF_IN_RESOURCE = 0;
	;	op->resourceSize = han.size;

	BitClr	ds:[LMBH_flags],LMF_IN_RESOURCE
	mov	ds:[OLMBH_resourceSize],dx

	;
	; Find any associated VM block in the state file for the process, if
	; this is a process.
	;
	call	HandleToID			;bx: handle -> ID
EC <	ERROR_C	FULL_OBJ_LOCK_CANNOT_FIND_RESOURCE			>
NEC <	jc	choke							>
	mov	es, ax				;es = core block of owner

	mov_trash	ax, bx			;pass tag in ax
	mov	cx, es:[GH_geodeAttr]
	push	es:[PH_vmHandle]
	call	Obj_MemUnlockES			;preserves flags
EC <	call	NullES							>
	pop	bx				;bx = PH_vmHandle

	test	cx,mask GA_PROCESS
	jz	reloc				;only processes have associated
						; vm files...

						;don't see if non-detachable
						; block was detached...
	test	ds:[LMBH_flags], mask LMF_DETACHABLE
	jz	reloc

;	When an XIP geode is saved to state, all of its blocks that are saved
;	to the state file are marked discardable. The next time we lock them
;	down, we want to make sure that the discardable flag is cleared.
;
;	The XIP tool makes sure that there are not discardable, detachable
;	lmem blocks (there shouldn't be any, anyway).

	test	cx, mask GA_XIP
	jz	notXIP
	push	bx, ds							
	mov	bx, ds:[LMBH_handle]					
	LoadVarSeg	ds
	andnf	ds:[bx].HM_flags, not mask HF_DISCARDABLE
	pop	bx, ds
notXIP:

	tst	bx
	jz	reloc

	clr	cx				;find first one
	call	VMFind				;returns ax = handle

	;
	; If block has associated VM block in state file, merge any changes
	; recorded there into the block we just got before relocating the thing
	;

	jc	noCorrespondingVMBlock

	;
	; Make sure there's actually data in the block by calling VMInfo on it.
	; If the file size of the thing is 0, the system must have crashed
	; before the state file was properly written out (the header could have
	; been written by VMUpdateAndRidBlk). If we don't check this, we try
	; to merge with a 16-byte garbage block, which causes ugly death.
	; 
	push	ax
	call	VMInfo
	pop	ax
	jcxz	noCorrespondingVMBlock
	
	push	bx			; save file handle
	mov	bx, ds:[LMBH_handle]	; bx <- handle of resource
	call	MemOwnerFar		; fetch the data from the file, but
	mov	cx, bx			;  give us control of the handle so
	pop	bx			;  we can free it when we're done. Block
	call	VMDetach		;  is owned by owner of resource...
			
	mov	bx, di
	push	ax
	call	MemLockSkipObjCheck
	mov	es, ax
	pop	ax			; lock down state block
	push	bx			; save for later free

	call	MergeObjBlock

	pop	bx			;free the state block
	call	MemFree

noCorrespondingVMBlock:
common:

reloc:
	mov	cx, VMRT_RELOCATE_FROM_RESOURCE
	call	RelocateObjBlock		;relocate objects
NEC <	jc	choke							>
	mov	ax,ds				;return address in ax

done:
	.leave
	ret

if NOT ERROR_CHECK
choke:
	;
	; Error loading the object block. Truncate the state file so it
	; won't get used next time, tell the user what's wrong, and boogie.
	;
	mov	bx, ss:[TPD_processHandle]
	call	MemLock
	mov	ds, ax
	clr	bx
	xchg	bx, ds:[PH_vmHandle]
	tst	bx
	jz	stateFileTruncated

	call	VMTruncateAndClose

stateFileTruncated:
ifdef	GPC
	mov	al, KS_OBJ_LOAD_ERROR
else
	mov	si, offset objLoadError1
	mov	di, offset objLoadError2
endif
	FALL_THRU	ChokeWithMovableString
endif
FullObjLock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ChokeWithMovableString

DESCRIPTION:	Call SysNotify and die

CALLED BY:	INTERNAL

PASS:
	si - chunk handle of first string
	di - chunk handle of second string

RETURN:
	never

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/26/92		Initial version

------------------------------------------------------------------------------@
if NOT ERROR_CHECK

ChokeWithMovableString	proc	far

ifdef GPC
	push	ax
	LoadVarSeg	ds, ax
	mov	al, KS_TE_SYSTEM_ERROR
	call	AddStringAtMessageBufferFar
	pop	ax
	call	AddStringAtESDIFar
	mov	si, offset messageBuffer
	clr	di
	mov	ax, mask SNF_REBOOT
else
	mov	bx, handle MovableStrings
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	mov	di, ds:[di]
	mov	ax, mask SNF_REBOOT or mask SNF_EXIT
endif
	call	SysNotify
ifndef	GPC
	mov	bx, handle MovableStrings
	call	MemUnlock
endif

	clr	bx
	call	ThreadAttachToQueue		; Doesn't return
	.UNREACHED

ChokeWithMovableString	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	MergeObjBlock

DESCRIPTION:	Merge a VM block into a resource block

CALLED BY:	INTERNAL
		FullObjLock

PASS:
	ds - segment of resource block (locked)
	es - segment of VM block

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	for (each chunk in VM block) {
		if (OCF_IN_RESOURCE) {
			replace resource chunk with chunk from ".uic" block
					the chunk handle stays the same
		} else {
			copy chunk from ".uic" block, making sure that
					the chunk handle stays the same
		}
	}   /* for */

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

MergeObjBlock	proc	near
EC <	call	ECLMemValidateHeapFar					>
	
	; ds = resource block, es = VM block
	; for (each chunk in VM block) {

	mov	si,es:LMBH_offset		;si points at handle
	mov	cx,es:LMBH_nHandles		;cx is a counter
	mov	bp,es:[si]			;ds:bp = flags for block
	jmp	next			;skip handles chunk

	;*es:si = object, es:bp = flags, cx = counter

loadLoop:
	mov	di,es:[si]			;es:di = VM chunk
	mov	al,es:[bp]			;al = flags for chunk
	inc	di
	jz	checkNull
	dec	di
	jz	next
	push	cx
	ChunkSizePtr	es, di, cx

	;	if (OCF_IN_RESOURCE) {
	;		replace resource chunk with chunk from state block

	test	al,mask OCF_IN_RESOURCE
	jz	notInResource
	mov	ax,si				;resize chunk in resource
	call	LMemReAlloc			;cx = size, do it
	jmp	copyAndMark

	;	} else {
	;		copy chunk from state block, making sure that
	;				the chunk handle stays the same
	;	}

checkNull:
	; if zero-length chunk is not in the resource, we need to allocate it
	; zero-length in the resource... (a zero-length chunk that is in the
	; resource indicates a chunk that is to come from the resource even
	; though state is being restored, unless it's dirty and not marked
	; ignoreDirty)

	push	cx
	clr	cx

	test	al, mask OCF_IN_RESOURCE
	jnz	checkNullResourceChunk
notInResource:
	; chunk was created on the fly, so we need to allocate it again before
	; we copy the data in

	call	LMemAllocHere			;al = flags, si = handle
EC <	ERROR_C	CANNOT_ALLOCATE_CORRECT_CHUNK_HANDLE			>

	;	mark as dirty (si = handle)

copyAndMark:
	; Copy the data from the state block into the real one and mark the
	; chunk dirty.
	push	si
	xchg	si,di				;si = src addr, di = dest han
	mov	di,ds:[di]			;di = dest address
	segxchg	ds, es				;ds = VM, es = resource
	inc	cx				;round up to copy enough
	shr	cx,1				;word words
	rep	movsw
	segxchg	ds, es				;ds = resource, es = VM
	pop	si
mark:
	mov	ax, si				;mark chunk as dirty. NOTE:
	clr	bh				; we *must* use ObjSetFlags as
	mov	bl, es:[bp]			; the flags chunks for the two
	call	ObjSetFlags			; blocks probably aren't in sync
						; Use the flags from the state
						; block to be sure to catch
						; OCF_VARDATA_RELOC
		

	; }   /* for */

popCXNext:
	pop	cx
next:
EC <	call	ECLMemValidateHeapFar					>
	add	si,2
	inc	bp
	loop	loadLoop

EC <	call	ECLMemValidateHeapFar					>
	ret

checkNullResourceChunk:
	; zero-length resource chunk comes from the resource only if chunk is
	; ignoreDirty or clean

	test	al, mask OCF_DIRTY
	jz	popCXNext
	test	al, mask OCF_IGNORE_DIRTY
	jnz	popCXNext
	
	; shrink resource chunk down to 0 & mark it dirty

	mov	ax, si
	call	LMemReAlloc
	jmp	mark

MergeObjBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetSavedBlockVMUserID

DESCRIPTION:	Return the correct user ID for a saved VM block

CALLED BY:	INTERNAL
		TransferToVm, ObjDisassocVMFile

PASS:
	ds - idata
	bx - memory handle of block

RETURN:
	ax - VM user ID

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

GetSavedBlockVMUserID	proc	far
if	(0)
	xchg	ax, bx				;ax = block
	mov	bx, ds:[uiHandle]
	call	ProcInfo			;bx = first thread handle
	xchg	ax, bx				;ax = first thread, bx = block
	cmp	ax, ds:[bx].HM_otherInfo
	mov	ax, VM_SAVED_UI
	je	uiRun
	mov	ax, VM_SAVED_APP
uiRun:
else
	push	bx				; save object block
	call	MemOwnerFar
	call	ProcInfo			; get first thread
	mov	ax, bx				; put first thread of owning
						; geode into ax
	pop	bx				; get object block back in bx
	cmp	ax, ds:[bx].HM_otherInfo
	mov	ax, VM_SAVED_APP
	je	uiRun
	mov	ax, VM_SAVED_UI
uiRun:
endif
	ret

GetSavedBlockVMUserID	endp

ObjectLoad ends

;---

ObjectFile segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	DetachObjBlock

DESCRIPTION:	Write an object block out to its process's state file

CALLED BY:	INTERNAL
		ObjDisassocVMFile

PASS:
	bx - handle of block to detach

RETURN:
	carry set if couldn't unrelocate

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

DetachObjBlock	proc	near	uses ax, bx, cx, dx, si, di, bp, ds, es
	.enter

	call	MemLockSkipObjCheck	; lock block so it can be swapped in
	mov	ds, ax			;  if necessary.

EC <	ERROR_C	OBJ_DETACH_BLOCK_NOT_RESIDENT				>
EC <	push	ds							>
EC <	LoadVarSeg	ds						>
EC <	cmp	ds:[bx].HM_lockCount, 1					>
EC <	ERROR_NZ	OBJ_DETACH_LOCK_COUNT_NON_ZERO			>
EC <	pop	ds							>

EC <	; In use count must be 0, or something is very wrong		>
EC <	cmp	ds:[OLMBH_inUseCount], 0				>
EC <	ERROR_NZ	OBJ_BLOCK_BAD_IN_USE_COUNT			>

	push	ds:[OLMBH_resourceSize]

	; CompactObjBlock(han);

EC <	call	ECLMemValidateHeapFar					>
	call	CompactObjBlock
EC <	call	ECLMemValidateHeapFar					>

	; LMemCompact(han);

	push	ds
	mov	dx, ds
	LoadVarSeg	ds
	call	FarPHeap
	call	ContractBlock
	call	FarVHeap
	pop	ds

	;
	; Unrelocate all the objects in the block
	;
	mov	cx, VMRT_UNRELOCATE_FROM_RESOURCE
	call	UnRelocateObjBlock
NEC <	jc	error							>

	mov	bx,ds:[LMBH_handle]		;get handle


	;
	; Transfer the block to the state file.
	;

	push	bx
	call	TransferToVM			;ds <- idata
	pop	bx		

DOB_finalSize	label	near	; *REQUIRED BY SHOWCALLS -V *
ForceRef	DOB_finalSize

	pop	ds:[bx].HM_size			;restore block size to original
						; resource size in case it must
						; be brought in again.

	clc
NEC <done:								>
	.leave
	ret
NEC <error:								>
NEC <	pop	ax				; Discard size		>
NEC <	jmp	done							>
DetachObjBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TransferToVM

DESCRIPTION:	Transfer a resource/duplicated block to a VM block

CALLED BY:	EXTERNAL
		DetachObjBlock

PASS:
	bx - resource handle
	ds - address of block (in memory)

RETURN:
	ds - idata

DESTROYED:
	ax, bx, cx, dx, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

TransferToVM	proc	near
	push	si, di
	LoadVarSeg	ds

	call	FindDuplicate			;is it a duplicate block ?
	jc	notDup

	;
	; Put duplicate out to its assigned VM block, as recorded in the
	; HandleSavedBlock for the thing. The ID for the block is set to
	; VM_SAVED_APP if the block was run by the application.
	; Else it is set to VM_SAVED_UI. We compare the block's
	; HM_otherInfo against the ui's thread to determine who ran the thing so
	; we can later support applications that have threads other than their
	; process thread running an object block.
	;
	call	GetSavedBlockVMUserID		;ax = user ID
	push	ds:[si].HSB_vmID
	jmp	doTransfer

notDup:
	;
	; Get the resource ID of the block so we can set it as the UID of the
	; new VM block.
	;
	push	bx, ds
	call	HandleToID			;bx = res ID, ax = core block
EC <	ERROR_C	TRANSFER_TO_VM_CANNOT_FIND_RESOURCE			>
	mov	ds, ax				; ds = core block
	mov_trash	ax, bx			;ax = resource ID (1-byte inst)
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	pop	bx, ds				;bx = resource

	;
	; See if we've already got a vm block allocated for this resource in
	; the state file. Re-use it if so...this allows the return to a
	; previous state in the face of a system crash after writing the header
	; block back to the file...
	; 
	mov	di, ax				;preserve resid
	push	bx, cx
	mov	bx, cx				;bx = VM file
	clr	cx				;find first with given ID
	call	VMFind
	pop	bx, cx

	push	ax				;save handle (0 if not there,
						; so VMAttach will alloc one)
	xchg	ax, di				;ax = resid (1-byte inst)

doTransfer:
	;
	; Common code:
	;	ax = ID to give to VM block.
	;	ss:[sp] = VM block handle to which to attach memory block (0
	;		  if handle should be allocated)
	;	ss:[sp+2] = segment of block being transferred
	;
	; 1) allocate a new handle and give the memory to it (allows the
	;    existing handle to remain as a discarded handle)
	; 2) attach the new handle to the VM block assigned to the thing
	;    (one will be allocated if no block assigned yet [e.g. for a
	;    resource block])
	; 3) set the UID of the VM block to the proper value
	;
	; cx = VM file

	push	ax
	call	FarPHeap
	call	MemTransfer			;give memory to new handle that
						; we'll be giving to the VM
	call	FarVHeap

	call	MemUnlock			;unlock the block we got back

	pop	dx 				;fetch UID
	pop	ax				;fetch VM block
	BitClr	ds:[bx].HM_flags,HF_DISCARDABLE	;mark dirty

	xchg	cx, bx				;cx = mem handle, bx = VM file
	call	VMAttachNoEC

	mov	cx, dx
	call	VMModifyUserID
	pop	si, di
	ret
TransferToVM	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CompactObjBlock

DESCRIPTION:	Shrink down all objects in a block

CALLED BY:	INTERNAL
		DetachObjBlock

PASS:
	ds - segment of block (will not move)

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


	; We have three options:
	;	1) Free the chunk -- it will never be needed
	;	2) Resize the chunk to zero length -- it exists in the resource
	;	   file so there is no need to save it but we don't want its
	;	   chunk handle to be used elsewhere
	;	3) Save the chunk --

	; We have several state bits:
	;	DIRTY -- Chunk has been modified
	;	IGNORE_DIRTY -- Don't consider ???
	;	IN_RESOURCE -- Chunk exists in the resource file
	;	DUPLICATED -- Chunk is in a duplicated block (flag takes the
	;		place of the OCF_IS_OBJECT flag for the chunk)

COBActions	etype	byte
COB_SAVE	enum	COBActions
COB_REALLOC_0	enum	COBActions
COB_FREE	enum	COBActions

COBTable	label	COBActions

				;		IGNORE	IN
				;	DIRTY	DIRTY	RESOUR	DUP'ED	Action
				;	-----	------	------	------	------
	byte	COB_FREE	;	0	0	0	0	Free
	byte	COB_FREE	;	0	0	0	1	Free
	byte	COB_REALLOC_0	;	0	0	1	0	Realloc
	byte	COB_SAVE	;	0	0	1	1	Save
	byte	COB_FREE	;	0	1	0	0	Free
	byte	COB_FREE	;	0	1	0	1	Free
	byte	COB_REALLOC_0	;	0	1	1	0	Realloc
	byte	COB_FREE	;	0	1	1	1	Free
	byte	COB_SAVE	;	1	0	0	0	Save
	byte	COB_SAVE	;	1	0	0	1	Save
	byte	COB_SAVE	;	1	0	1	0	Save
	byte	COB_SAVE	;	1	0	1	1	Save
	byte	COB_FREE	;	1	1	0	0	Free
	byte	COB_FREE	;	1	1	0	1	Free
	byte	COB_REALLOC_0	;	1	1	1	0	Realloc
	byte	COB_FREE	;	1	1	1	1	Free

;------------------

CompactObjBlock	proc	far	uses	ax, bx, cx, dx, si, di, bp, ds, es
	.enter

CheckHack <(ObjChunkFlags eq 0x1f) AND \
	   (mask OCF_VARDATA_RELOC eq 0x10) AND \
	   (mask OCF_DIRTY eq 0x8) AND \
	   (mask OCF_IGNORE_DIRTY eq 0x4) AND \
	   (mask OCF_IN_RESOURCE eq 0x2) AND \
	   (mask OCF_IS_OBJECT eq 0x1)>

OCF_IS_DUPLICATE equ <OCF_IS_OBJECT>

	; for (each chunk in block) {

	mov	si,ds:LMBH_offset		;si points at handle
	mov	cx,ds:LMBH_nHandles		;cx is a counter
	mov	bp,ds:[si]			;ds:bp = flags for block
	mov	bx, offset COBTable		;cs:bx is action table
toNext:
	jmp	next			;skip flags chunk

	;ds:si - current position in handle table
	;ds:bp - current position in flags table
	;cx - count

COB_loop:
	mov	di, ds:[si]			;ds:di = UIC chunk
	inc	di				;no memory?
	jz	toNext				;z => no memory
	dec	di				;handle free?
	jz	toNext				;z => free
	mov	al, ds:[bp]			;al = flags for chunk
	mov	ah, al				;save for later use
	;
	; Use the flags for the chunk to index into COBTable, after replacing
	; OCF_IS_OBJECT with a bit indicating if the block was duplicated or
	; is from a resource.
	;
	andnf	al, not (mask OCF_IS_OBJECT or mask OCF_VARDATA_RELOC)
						;make room for DUP flag,
						;biff vardata reloc flag
	test	ds:[LMBH_flags],mask LMF_DUPLICATED
	jz	notDuplicated
	ornf	al, mask OCF_IS_DUPLICATE
notDuplicated:
	xlat	cs:[COBTable]			;bx is COBTable.
						; al = action
CheckHack <(COB_SAVE eq 0) AND (COB_REALLOC_0 eq 1) AND (COB_FREE eq 2)>
	dec	al
	js	save
	dec	al
	js	realloc0

	; free the chunk

	mov	ax,si
	call	LMemFree
	jmp	next

	; reallocate the chunk to size 0

realloc0:
	mov	ax,si				;ax = chunk
	push	cx
	clr	cx				;size 0
	call	LMemReAlloc

	; clear dirty bit that LMemReAlloc set, since the chunk couldn't
	; have been dirty (or was ignoreDirty if it was) or we wouldn't
	; have done this.

	andnf	{ObjChunkFlags}ds:[bp], not mask OCF_DIRTY
	pop	cx
nextJMP:
	jmp	next

	; save the chunk

save:
	test	ah,mask OCF_IS_OBJECT		;if not an object then save
	jz	nextJMP				;the entire chunk

	;
	; Discard any master pieces we're allowed to nuke. A master piece
	; may be biffed if the master class that starts the piece is marked
	; DISCARD_ON_SAVE, so long as there was a variant master class just
	; below it. The variance or invariance of the previous master level
	; is encoded in dx (-1 if previous master level was variant, 0 if not)
	;
	mov	di,ds:[si]			;ds:di = UIC chunk
	les	di,ds:[di].MB_class		;es:di = class
	clr	dx				;last master level wasn't
						; variant
classLoop:
EC <	call	ECCheckClass			; Make sure a valid class >
						;if not a master class, walk
						;up superclasses until we
						;find one
	mov	al,es:[di].Class_flags
	test	al,mask CLASSF_MASTER_CLASS
	jnz	isMaster			;branch to handle master
	les	di,es:[di].Class_superClass	;MetaClass is a master, so we
	jmp	classLoop			; needn't check for null super
						; here.

isMaster:
	and	dl, al				;dl <- 0 if previous master
						; wasn't variant, al if previous
						; was variant
	test	dl,mask CLASSF_DISCARD_ON_SAVE	;master class, check for
	pushf					; discard-on-save & save result

	test	al,mask CLASSF_VARIANT_CLASS	;move to super
	mov	ax,es:[di].Class_masterOffset	;ax = offset
	push	ax				;save for resize
	jz	notVariant

	mov	dx, TRUE			;flag previous master as having
						; been variant

	; extract superclass from start of master.
	
	add	ax,ds:[si]			;get ptr to master offset
	xchg	di,ax				;(1-byte inst)
	mov	ax,ds:[di]			;get master offset
	tst	ax
	jz	popNext				;=> nothing grown here,
						; so nothing to discard (and we
						; wouldn't know how to get there
						; if there were :)
	add	ax,ds:[si]			;get ptr to master part
	mov_tr	di,ax
	les	ax,ds:[di].MB_class		;get variant class to use
	mov_tr	di, ax
	jmp	haveSuperClass	;branch to process superclass
notVariant:
	clr	dx				;flag previous master as not
						; variant
	les	di,es:[di].Class_superClass
haveSuperClass:
	pop	ax				;recover master offset
	popf
	push	bp
	jnz	discard				;=> is discard-on-save that
						; should be obeyed
	mov	bp, -1				; not discard-on-save, free
						;	only the variable data
						;	with VDF_SAVE_TO_STATE=0
	jmp	freeVarData

discard:
	mov_tr	bx, ax				;bx <- master offset
	clr	ax				;new size in ax
	call	ObjResizeMaster

	mov	bp, ds:[si]			; ds:bp <- object base
	xchg	bp, si				; can't combine bx & bp, so
						;  swap bp & si...
	clr	ax
	mov	ds:[si][bx], ax			;null out master offset, to
						;	show empty
	;
	; Since we've biffed the master data for the group above the variant,
	; we want to also zero out the variant's superclass pointer.
	; 
	add	si, ds:[si][bx+2]		; ds:si <- base of data for
						;  previous master level
	mov	ds:[si].MB_class.offset, ax
	mov	ds:[si].MB_class.segment, ax
	mov	si, bp				; *ds:si <- object again

	mov_tr	ax, bx				;ax <- master offset
	mov	bx, offset COBTable		;this is the only time BX gets
						; biffed in the loop, so just
						; restore it here, not every
						; time through...
	clr	bp				; delete all variable data
						;	entries for this master
						;	level
	;
	; free variable data for this master level
	;	ax = master offset
	;	bp = 0 to free all data entries in correct range
	;	   = non-zero to free only those with VDF_SAVE_TO_STATE=0
	;
freeVarData:
	push	cx, dx
	mov	dx, FIRST_MASTER_MESSAGE-1	; assume meta class
	mov_tr	cx, ax
	jcxz	haveVarDataRange		; => meta-class, so cx (start
						;  of range) is also properly
						;  set (to 0, of course)

	sub	cx, size MetaBase - 2		; figure start of method #s
	shr	cx, 1				;	for this master level
						; (- 2 so cx is 1 for first
						;  master level)
	mov	ax, FIRST_MASTER_MESSAGE-DEFAULT_MASTER_MESSAGES
getStartLoop:
	add	ax, DEFAULT_MASTER_MESSAGES	; compute start of range
	loop	getStartLoop

	mov	dx, ax				; compute end of range
	add	dx, DEFAULT_MASTER_MESSAGES-1

	mov_tr	cx, ax				; cx <- start of range

haveVarDataRange:
	call	ObjVarDeleteDataRange
	pop	cx, dx
	pop	bp
	;
	; Any place to which to continue on?
	; 
	mov	ax, es
	tst	ax
	LONG jnz classLoop		; yes

next:
	; Done with this chunk. Go to next
	add	si,2
	inc	bp
	loop	toLoop
	.leave
	ret

popNext:
	; Nuke saved offset & flags from discard-on-save test before advancing
	; to next chunk
	add	sp,4
	jmp	next

toLoop:
	jmp	COB_loop

CompactObjBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocSavedBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a saved block for a process

CALLED BY:	AllocAllSavedBlocks
PASS:		ds	= core block of process (locked)
		es	= idata
		ax	= VM block handle for saved block
		dx	= thread to run the block
		bx	= VM file
RETURN:		nothing
DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocSavedBlock	proc	near	uses es, bx, ds
		.enter
		push	bx		; save VM file
		push	ax		; save VM block handle
	;
	; Allocate a discarded block for the thing -- it will be brought
	; in from the VM file when it is needed by FullObjLock.
	; 
		mov	ax, 1		; allocate 1 byte discarded (can't pass
					;  0)
		mov	cx, SAVED_FLAGS	; XXX: if system ever uses HAF_UI for
					;  anything but InitResources, this
					;  will be hosed
		call	MemAllocFar
		mov	es:[bx].HM_otherInfo, dx	; set thread to run it
	;
	; Add the block to the saved-block list for the process
	;
		pop	ax
		segmov	es, ds
		call	AddToSavedList
	;
	; Change the user ID of the VM block so we don't find the thing again.
	;
		pop	bx
		mov	cx, VM_SAVED_ATTACHED
		call	VMModifyUserID
		.leave
		ret
AllocSavedBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocAllSavedBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find and allocate HandleSavedBlocks for all saved/duplicated
		blocks recorded in the state file that are to be run by
		either the UI thread or the application thread.

CALLED BY:	ObjAssocVMFile(2)
PASS:		bx	= VM file
		dx	= thread to run the blocks
		ax	= VM uid for which to search
		es	= idata
		ds	= process's core block (locked)
RETURN:		nothing
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocAllSavedBlocks	proc	near	uses	bp
		.enter
		mov	bp, ax		; preserve UID during the loop
blockLoop:
		clr	cx		; find first block with given ID
					; (cx trashed in AllocSavedBlock)
		call	VMFind		; look for another block
		jc	done		;=> no more
		call	AllocSavedBlock
		mov	ax, bp		; recover UID
		jmp	blockLoop
done:
		.leave
		ret
AllocAllSavedBlocks	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjAssocVMFile

DESCRIPTION:	Associate a VM file with the current process

CALLED BY:	GLOBAL -- Intended for UI use

PASS:
	bx - VM file handle

RETURN:
	carry - set if error (protocol error)
	ax - handle of extra block of data (0 for none)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
	ardeb	2/90		Changed to use AllocSavedBlock function in two
				loops to avoid extra searches once all UI blocks
				are found.
-------------------------------------------------------------------------------@

ObjAssocVMFile	proc	far	uses bx, cx, dx, si, di, bp, ds, es
	.enter

	push	bx
	mov	bx, ss:[TPD_processHandle]
	call	MemLock
	mov	ds, ax			;ds = core block
	pop	bx
	mov	ds:[PH_vmHandle],bx

	; First we must check protocols to ensure that this state file
	; is compatible with its libraries

	; If no map block exists then this is a new state file and we must
	; stuff the protocols

	call	VMGetMapBlock
	tst	ax
	jnz	checkProtocol
	call	StateFileSetProtocol
	jmp	afterProtocol
checkProtocol:
	call	StateFileCheckProtocol
	jnc	afterProtocol
	mov	ds:[PH_vmHandle], 0	; don't leave the state file
					;  associated on error, please...
	mov	bx, ss:[TPD_processHandle]
	call	MemUnlock
EC <	call	NullDS							>
	jmp	done
afterProtocol:

	;
	; Allocate handles for all saved blocks. The blocks are identified
	; by their uid being VM_SAVED_UI, if the block is to be run
	; by the UI thread, or VM_SAVED_APP, if the block is to be
	; run by the app's process thread.
	;
	LoadVarSeg	es

	;
	; We look for all UI-run blocks first.
	;
	mov	dx, ds:[PH_uiThread]
	mov	ax, VM_SAVED_UI
	call	AllocAllSavedBlocks
	
	;
	; Now look for all process-run blocks.
	;
	push	bx
	mov	bx, ss:[TPD_processHandle]
	call	ProcInfo			;actually, need first thread
	mov	dx, bx
	pop	bx
	mov	ax, VM_SAVED_APP
	call	AllocAllSavedBlocks

	;
	; Now return the UID's of the saved blocks to their proper value,
	; indicating who runs the block, so if the header gets flushed, we
	; can still use the state file. We also allocate an empty block handle
	; for any saved/duplicated blocks that existed before we were called
	; (their HSB_vmID fields are odd).
	;

	mov	dx, bx				;dx = VM file
	push	ds				;save core block
	mov	si, ds:[PH_savedBlockPtr]	;si <- first HSB
	segmov	ds, es				;ds <- idata
hsbLoop:
	tst	si
	jz	doneWithHSBs
	
	mov	bx, ds:[si].HSB_handle
	mov	cx, ds:[si].HSB_vmID
	test	cx, 1
	jnz	allocNew
	
	call	GetSavedBlockVMUserID
	xchg	ax, cx			; ax <- vm block handle, cx <- uid
	mov	bx, dx			; bx = VM file
	call	VMModifyUserID
	jmp	nextHSB

allocNew:
	call	AllocEmptyVMBlock
	mov	ds:[si].HSB_vmID, ax
	
nextHSB:
	mov	si, ds:[si].HSB_next
	jmp	hsbLoop


doneWithHSBs:
	;
	; Find all object resources that are currently resident and alter
	; the extra unassigned count for the state file accordingly.
	;
	pop	ds				;ds <- proc's core block

	mov	si, ds:[GH_resHandleOff]	;si <- resource handle table
	mov	cx, ds:[GH_resCount]		;cx <- # resources
	clr	dx				;no extras yet
resLoop:
	push	ds
	lodsw					;fetch next handle
	mov_tr	bx, ax
	test	es:[bx].HM_flags, mask HF_LMEM	;lmem?
	jz	reloadDSNextResource		;no -- can't be object block

	test	es:[bx].HM_flags, mask HF_DISCARDED	;discarded?
	jnz	reloadDSNextResource		;yes -- don't worry about it
	
	call	MemLockSkipObjCheck		;lock it so we can check its
	mov	ds, ax				; lmemType
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jne	unlockNextResource
	add	dx, VM_NUM_EXTRA

unlockNextResource:
	call	MemUnlock
reloadDSNextResource:
	pop	ds				;ds <- proc's core block again
	loop	resLoop
	push	ds:[PH_vmHandle]
	mov	bx, ds:[GH_geodeHandle]
	call	MemUnlock
EC <	call	NullDS							>
	pop	bx

	;
	; Return extra data block.  The "extra data" block is a block returned
	; when the application exited (via ObjDisassocVMFile).
	; ds = idata
	;
	clr	di				;assume no extra block

	mov	ax, VM_EXTRA_DATA
	clr	cx				;find first block with given ID
	call	VMFind
	jc	doneGood

	mov	cx, ss:[TPD_processHandle]	;block owned by current process
	call	VMDetach			;read in and give me the thing

doneGood:
	clc
done:
	mov	ax, di				;return extra block in AX

	.leave
	ret

ObjAssocVMFile	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StateFileSetProtocol

DESCRIPTION:	Store the protocols for a state file

CALLED BY:	INTERNAL

PASS:
	bx - state file

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	Store the application's protocol in the GeosFileHeader
	Store the protocols of all imported libraries in the map block

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/30/91		Initial version

------------------------------------------------------------------------------@
StateFileSetProtocol	proc	near	uses bx, ds
proto	local	ProtocolNumber
rel	local	ReleaseNumber
attrs	local	2 dup(FileExtAttrDesc)
	.enter

	; Fetch the protocol & release numbers for the current process

	push	bx				;save file
	clr	bx
	segmov	es, ss
	mov	ax, GGIT_GEODE_RELEASE
	lea	di, ss:[rel]
	call	GeodeGetInfo
	mov	ax, GGIT_GEODE_PROTOCOL
	lea	di, ss:[proto]
	call	GeodeGetInfo
	pop	bx				;bx = file

	;
	; Set them as attributes of the state file.
	; 
	mov	ss:[attrs][0*FileExtAttrDesc].FEAD_attr, FEA_RELEASE
	mov	ss:[attrs][0*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[rel]
	mov	ss:[attrs][0*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[attrs][0*FileExtAttrDesc].FEAD_size, size rel

	mov	ss:[attrs][1*FileExtAttrDesc].FEAD_attr, FEA_PROTOCOL
	mov	ss:[attrs][1*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[proto]
	mov	ss:[attrs][1*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[attrs][1*FileExtAttrDesc].FEAD_size, size proto

	mov	ax, FEA_MULTIPLE
	mov	cx, length attrs
	lea	di, ss:[attrs]
	call	FileSetHandleExtAttributes
	
	; Access the app's core block so that we can find the libraries

	push	bx
	mov	bx, ss:[TPD_processHandle]
	call	MemLock
	mov	ds, ax				;ds = core block
	pop	bx

	; allocate a map block to hold the protocols

	push	bp
	mov	ax, ds:[GH_libCount]
	mov	cx, size ProtocolNumber
	mul	cx
	add	ax, 2
	mov_tr	cx, ax				;cx = size to allocate
	clr	ax
	call	VMAlloc				;ax = vm block handle
	call	VMSetMapBlock
	call	VMLock
	call	VMDirty
	mov	es, ax				;es = map block

	; loop to get the protocols from the imported libraries

	mov	cx, ds:[GH_libCount]
	mov	si, ds:[GH_libOffset]
	clr	di
	mov	ax, cx
	stosw					;store count first
libLoop:
	lodsw
	mov_tr	bx, ax				;bx = library
	mov	ax, GGIT_GEODE_PROTOCOL
	call	GeodeGetInfo
	add	di, size ProtocolNumber
	loop	libLoop

	call	VMUnlock

	mov	bx, ds:[GH_geodeHandle]		;unlock core block
	call	MemUnlock
	pop	bp

	.leave
	ret

StateFileSetProtocol	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StateFileCheckProtocol

DESCRIPTION:	Check the protocols for a state file

CALLED BY:	INTERNAL

PASS:
	bx - state file

RETURN:
	carry - set if error

DESTROYED:
	ax, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/30/91		Initial version

------------------------------------------------------------------------------@
StateFileCheckProtocol	proc	near	uses bx, ds
fileProto local ProtocolNumber
proto	local	ProtocolNumber
	.enter

	segmov	es, ss
	lea	di, ss:[fileProto]
	mov	cx, size fileProto
	mov	ax, FEA_PROTOCOL
	call	FileGetHandleExtAttributes

	; Fetch the protocol numbers for the current process

	mov	dx, bx				;dx = file
	clr	bx
	segmov	es, ss
	mov	ax, GGIT_GEODE_PROTOCOL
	lea	di, proto
	call	GeodeGetInfo
	lea	si, ss:[fileProto]
	segmov	ds, ss				; ds:si <- file proto
	call	CompareProto
	jc	doneNoUnlock

	; Access the app's core block so that we can find the libraries

	mov	bx, ss:[TPD_processHandle]
	call	MemLock
	mov	es, ax				;es = core block

	; allocate a map block to hold the protocols

	push	bp
	mov	cx, bp				;cx = locals
	mov	bx, dx
	call	VMGetMapBlock
	call	VMLock
	push	bp				;save VM mem handle
	mov	ds, ax				;ds = map block
	mov	bp, cx				;bp = locals

	; loop to get the protocols from the imported libraries

	mov	cx, es:[GH_libCount]
	cmp	cx, ds:[0]			;check # libraries
	stc
	jnz	done
	mov	di, es:[GH_libOffset]
	mov	si, 2
libLoop:
	mov	bx, es:[di]			;bx = library
	push	di, es
	segmov	es, ss
	lea	di, proto
	mov	ax, GGIT_GEODE_PROTOCOL
	call	GeodeGetInfo
	call	CompareProto
	pop	di, es
	jc	done
	add	si, size ProtocolNumber
	inc	di
	inc	di
	loop	libLoop
	clc
done:
	pop	bp				;bp = VM mem handle
	call	VMUnlock
	mov	bx, es:[GH_geodeHandle]		;unlock core block
	call	MemUnlock
EC <	call	NullES							>
	pop	bp

doneNoUnlock:
	.leave
	ret

StateFileCheckProtocol	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CompareProto

DESCRIPTION:	Compare protocols

CALLED BY:	INTERNAL

PASS:
	ds:si - expected protocol
	es:di - actual protocol

RETURN:
	carry - set if error

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/30/91		Initial version

------------------------------------------------------------------------------@
CompareProto	proc	near
	mov	ax, ds:[si].PN_major
	cmp	ax, es:[di].PN_major
	jnz	bad
	mov	ax, ds:[si].PN_minor
	cmp	ax, es:[di].PN_minor
	ja	bad
	clc
	ret
bad:
	stc
	ret

CompareProto	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjSaveExtraStateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the extra block of state the application wants to
		keep in its state file.

CALLED BY:	(GLOBAL)
PASS:		cx	= handle of the block to save
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	block is freed or given to the state file. In either case,
     		    it is beyond the caller's pale.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/92 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjSaveExtraStateBlock proc	far
	uses	ax, cx, dx, bx, es, ds
	.enter
	jcxz	exit
EC <	mov	bx, cx							>
EC <	call	ECCheckMemHandleFar					>

	LoadVarSeg	es, ax			;es = kernel variables

EC <	test es:[bx].HM_flags, mask HF_SWAPABLE				>
EC <	ERROR_Z		EXTRA_STATE_BLOCK_MUST_BE_SWAPPABLE		>
EC <	test es:[bx].HM_flags, mask HF_DISCARDABLE			>
EC <	ERROR_NZ	EXTRA_STATE_BLOCK_CANNOT_BE_DISCARDABLE		>

	mov	bx, ss:[TPD_processHandle]
	call	MemLock
	mov	ds, ax				;ds = core block, bx = han
	mov	bx, ds:[PH_vmHandle]

	;
	; Make sure process has a state file. We can get into a situation
	; where an exiting process calls us w/o a state file if the state file
	; couldn't be created. The process then goes into an infinite
	; attach loop after calling SysNotify, eventually (we hope) calling
	; us during the detach process...but there's no state file from which
	; to unassociate, so...
	; 
	tst	bx
	jz	done

	;----------------------------------------------------------------------
	; See if there's already a VM block handle allocated in the state file
	; for the extra data block

	mov	ax, VM_EXTRA_DATA
	push	cx
	clr	cx				;find first block with given ID
	call	VMFind				;use existing, or alloc new
	pop	cx				;(ax return as 0) if none
						;there yet.
	;
	; Attach the block to that vm block handle, or allocate a new one, as
	; appropriate.
	; 
	call	VMAttachNoEC
	;
	; Change the id to what we expect, in case VMAttach allocated a vm
	; block handle for us.
	; 
	mov	cx,VM_EXTRA_DATA
	call	VMModifyUserID
done:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
exit:
	.leave
	ret
ObjSaveExtraStateBlock endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjDisassocVMFile

DESCRIPTION:	UnAssociate a VM file with the current process

CALLED BY:	GLOBAL -- Intended for UI use

PASS:
	nothing

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
	ardeb	2/90		Adapted to VM module changes
-------------------------------------------------------------------------------@
ObjDisassocVMFile	proc	far	uses bx, cx, dx, si, di, bp, ds, es
	.enter

	LoadVarSeg	es, ax			;es = kernel variables

	mov	bx, ss:[TPD_processHandle]
	call	MemLock
	mov	ds, ax				;ds = core block, bx = han
	mov	bx, ds:[PH_vmHandle]

	;
	; Make sure process has a state file. We can get into a situation
	; where an exiting process calls us w/o a state file if the state file
	; couldn't be created. The process then goes into an infinite
	; attach loop after calling SysNotify, eventually (we hope) calling
	; us during the detach process...but there's no state file from which
	; to unassociate, so...
	; 
	tst	bx
	LONG jz	done

	;----------------------------------------------------------------------
	; Flush any object resources to the file first.

	mov	bp,ds:[GH_resHandleOff]		;ds:bp points at resource table
	mov	cx,ds:[GH_resCount]
resLoop:
	push	cx

	; fetch next resource handle
	mov	bx,ds:[bp]			;get handle
	push	ds

	; see if resource is lmem and detachable
	test	es:[bx].HM_flags,mask HF_LMEM
	jz	next				;carry is clear

	test	es:[bx].HM_flags, mask HF_DISCARDABLE or mask HF_DISCARDED
						;discardable or discarded?
	jnz	next				;carry is clear

ODVMF_lock	label	near	; * REQUIRED BY SHOWCALLS -V *
ForceRef ODVMF_lock
		
	call	MemLockSkipObjCheck
	mov	ds, ax
	test	ds:[LMBH_flags],mask LMF_DETACHABLE
	call	MemUnlock			;preserves flags
	jz	next				;carry is clear

ODVMF_detach	label	near	; * REQUIRED BY SHOWCALLS -V *
ForceRef ODVMF_detach

	call	DetachObjBlock
next:
	pop	ds
	inc	bp
	inc	bp
	pop	cx
EC <	ERROR_C	CANNOT_UNRELOCATE					>
NEC <	jc	error							>
	loop	resLoop

	;----------------------------------------------------------------------
	; save all blocks on the saved list

	mov	bx, ds:[PH_savedBlockPtr]
	push	ds
	LoadVarSeg	ds
savedLoop:
	tst	bx
	jz	savedDone

	push	ds:[bx].HSB_next		;save next on list
	mov	si, bx				;si = handle of HandleSavedBlock
	mov	bx,ds:[bx].HSB_handle

	test	ds:[bx].HM_flags, mask HF_DISCARDED
	jnz	nextSaved
	call	DetachObjBlock
nextSaved:
	pop	bx
EC <	ERROR_C	CANNOT_UNRELOCATE					>
NEC <	jc	errorPopDS						>
	jmp	savedLoop
savedDone:
	pop	ds

	;----------------------------------------------------------------------
	; now remove the HandleSavedBlock handles and close the state file

	call	ObjCloseVMFile

done:
	mov	bx, ds:[GH_geodeHandle]
	call	MemUnlock
	.leave
	ret

if NOT ERROR_CHECK
;
; Handle unrelocation error in non-ec by truncating the state file.
;
errorPopDS:
	pop	ds
error:
	mov	bx, ds:[PH_vmHandle]
	call	FileDuplicateHandle	; Make a duplicate of the state
					;  handle so we can truncate it

	push	ax			;save copy file
	call	ObjCloseVMFile
	pop	bx			; bx <- copy
	clr	cx			; truncate at 0
	mov	dx, cx
	call	FileTruncate
	mov	al, FILE_NO_ERRORS
	call	FileCloseFar		; Close extra. Since file is now 0
					;  length, this *has* to succeed, else
					;  the file couldn't have been
					;  created
	jmp	done
endif
ObjDisassocVMFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjCloseVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the process's state file without saving its objects
		to state. Useful if one is quitting after having restored
		from state. Process must be in a state where it can guarantee
		that no thread belonging to it will call ObjDuplicateResource
		during this call. (This is usually accomplished by having only
		one thread left for the process...)

CALLED BY:	(GLOBAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	process loses its state file, and state file is closed.
     		all record of any duplicated blocks is destroyed, so
		    process cannot attach to another state file even if it
		    wanted to.

PSEUDO CODE/STRATEGY:
		; XXX: Just zero the HSB_vmID fields so can re-attach to another
		; state file?


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjCloseVMFile	proc	far
	uses	bx, si, ds
	.enter
	mov	bx, ss:[TPD_processHandle]
	call	MemLock
	mov	ds, ax
	mov	si, ds:[PH_savedBlockPtr]
	push	ds
	LoadVarSeg	ds
freeLoop:
	tst	si
	jz	freeDone
	mov	bx,si
	mov	si,ds:[si].HSB_next
	call	FarFreeHandle
	jmp	freeLoop
freeDone:
	pop	ds
	mov	ds:[PH_savedBlockPtr], 0	;no more saved blocks

	clr	bx
	xchg	bx, ds:[PH_vmHandle]		;no associated VM file any more
	tst	bx
	jz	done				;=> never was one
	clr	al				;allow errors
	call	VMClose
	jnc	done
	
	; destroy all VM blocks and close the file, instead
	call	VMTruncateAndClose

done:
	mov	bx, ds:[GH_geodeHandle]
	call	MemUnlock
	.leave
	ret
ObjCloseVMFile	endp

ObjectFile	ends
