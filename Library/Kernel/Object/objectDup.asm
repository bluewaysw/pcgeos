COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Object
FILE:		objectDup.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to load a GEODE and execute it.

	$Id: objectDup.asm,v 1.1 97/04/05 01:14:47 newdeal Exp $

------------------------------------------------------------------------------@

ObjectLoad	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjDuplicateResource

DESCRIPTION:	Duplicate an object resource block.  The new block will be
		put on the "saved blocks" list so that it will be saved by
		ObjDisassocVMFile.

CALLED BY:	GLOBAL

PASS:
	bx - resource handle to duplicate (must not be in memory)

	ax - handle of geode to own new block, OR
	     0 to be have block owned by geode owning current running thread, OR
	     -1 to copy owner from source block

	cx - handle of thread to run new block, OR
	     0 to have block run by current running thread, OR
	     -1 to copy nature of thread from source block:
			if source is process-run, dest will be process-run.
			if source is ui-run, dest will be ui-run.
			if source run by anything else, that same thread will
				run the new block.

RETURN:
	bx - handle of duplicated block

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Doug	4/92		Added ability to pass in burden thread to use
	Doug	6/1/92		Additions for new thread model

------------------------------------------------------------------------------@

ObjDuplicateResource	proc	far	uses	ax, cx, dx, si, di, bp, ds, es
	.enter

EC <	push	bx	; For duplicated block symbols -- save source	>
EC <	call	ECCheckResourceHandle					>

	LoadVarSeg	ds

	; Ensure that block to duplicate is not in memory
	;
EC <	test	ds:[bx].HM_flags,mask HF_DISCARDED			>
EC <	ERROR_Z	OBJ_DUPLICATE_BLOCK_NOT_DISCARDED			>


	; Get owner for new block, in AX
	;
	tst	ax
	jz	useOwnerOfCurrentThread
	cmp	ax, -1
	jne	haveOwner
;copyOwner:
	mov	ax, ds:[bx].HM_owner	;ax = owner of block to duplicate
	jmp	short haveOwner
useOwnerOfCurrentThread:
	mov	ax, ss:[TPD_processHandle]
haveOwner:
EC <	xchg	ax,bx							>
EC <	call	ECCheckGeodeHandle					>
EC <	xchg	ax,bx							>


	; Get burden thread to use, in DI
	;
	call	DetermineBurdenThreadForDuplicatedResource


	; If source & new owner are both instances of the same application,
	; (as being determined by their having the same executable file), then
	; use the new owner when performing relocations, as some relocations
	; may be to non-sharable blocks, & we want to get those blocks of the
	; new owner.  If the new owner is unrelated to the source, then we
	; must instead relocate relative to the source, as the dest's relocation
	; table has nothing to do with the block we're duplicating.
	;

	; Start by assuming new owner unrelated to source
	;
	mov	si, ds:[bx].HM_owner	;si = owner of block to duplicate

	xchg	bx, si
	call	Obj_MemLockES_save_ax	;es = core block
	xchg	bx, si
	mov	cx, es:[GH_geoHandle]	;cx = file handle to executable file
	call	Obj_MemUnlockES
EC <	call	NullES							>

;	If the owning geode is in the XIP resource (has GH_geoHandle = 0) then
;	we know they don't come from the same executable.

if _FXIP or FAULT_IN_EXECUTABLES_ON_FLOPPIES
	jcxz	notSameExecutable
endif
	push	bx
	mov	bx, ax			;bx = new owner
	call	Obj_MemLockES_save_ax	;es = core block of new owner
	cmp	cx, es:[GH_geoHandle]	;if files are the same then special case
	call	Obj_MemUnlock
EC <	call	NullES							>
	pop	bx
	jnz	notSameExecutable
	;
	; Oh, but it is the same executable!  Perform all relocations 
	; relative to the new owner.
	;
	mov	si, ax
	;
notSameExecutable:

	; si = temporary owner (during RelocateObjBlock)
	; di = burden thread
	; ds = idata

	push	ax			;save new owner for block
	push	bx			;save handle to duplicate
	push	si			;save temporary owner
	push	di			;save burden thread

	; allocate a block for the resource

	call	GeodeDuplicateResource

	;Circumvent the EC code that dies if you MemLock an object block,
	; as it is OK in this case (we do the relocations below)

	call	MemLockSkipObjCheck		;ax = segment

	pop	ds:[bx].HM_otherInfo	;set "burden thread" for new block
	pop	ds:[bx].HM_owner	;set temporary owner
	mov	bp, bx			;bp = handle to copy to
	pop	bx			;bx = block to copy from

	; load in the resource

	; fix up block header

	mov	ds, ax
EC <	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	ERROR_NZ OBJ_DUPLICATE_BLOCK_REQUIRES_AN_OBJECT_BLOCK		>

	mov	ax, ds:[LMBH_flags]
	ornf	ax, mask LMF_DUPLICATED
	andnf	ax, not mask LMF_IN_RESOURCE
	mov	ds:[LMBH_flags], ax

	; if an object block then store size and relocate

	LoadVarSeg	es
	mov	dx, es:[bp].HM_size	;dx = size (paragraphs)
	shl	dx
	shl	dx
	shl	dx
	shl	dx
	mov	ds:[OLMBH_resourceSize], dx	;store size in bytes

	; relocate the block

	push	bx, bp			;save old handle
	mov	cx, VMRT_RELOCATE_FROM_RESOURCE
	call	RelocateObjBlock	;relocate objects
	pop	bx, bp

	pop	es:[bp].HM_owner	;set owner for new block. Saved until
					; now so ORS_OWNING_GEODE_ENTRY_POINT
					; relocations use the right owner in
					; the case of duplicating a shared
					; resource.
EC <	call	ECLMemValidateHeapFar					>

	; Allocate a VM block

	mov	bx, ds:[LMBH_handle]
	test	ds:[LMBH_flags], mask LMF_DETACHABLE
	jz	noVM

	call	AllocVMAddToSavedList
noVM:
EC <	pop	cx			; Retrieve source template handle >
EC <	call	DebugTagDuplicate	; Mark duplicate w/origin info 	  >
	call	Obj_MemUnlock

	.leave
	ret

ObjDuplicateResource	endp

;---

Obj_MemLockES_save_ax	proc	near	uses ax
	.enter
	call	Obj_MemLock
	mov	es, ax
	.leave
	ret
Obj_MemLockES_save_ax	endp

Obj_MemLock	proc	near
	call	MemLock
	ret
Obj_MemLock	endp

;---

Obj_MemUnlockES	proc	near	uses bx
	.enter
	mov	bx, es:[LMBH_handle]
	call	Obj_MemUnlock
	.leave
	ret
Obj_MemUnlockES	endp

Obj_MemUnlock	proc	near
	call	MemUnlock
	ret
Obj_MemUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DebugTagDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tag new duplicate block w/source for the debugger's sake.  We
		do this by adding a piece of vardata to the first object, that
		contains the permanent name of the geode owning the source
		template, & the handle of the source template, unrelocated
		relative to its owner.  From this info, the debugger can
		use the symbols of the source template when printing out the
		objects in the duplicated block.  Much better than hex
		numbers.

CALLED BY:	INTERNAL
PASS:		cx	= source block
		bx	= duplicated block
		*ds	= duplicate block
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di, bp, es

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK
DebugTagDuplicate	proc	near	uses	bx
	.enter
if 	0
	mov	ax, ds:[LMBH_offset]	; Get first chunk handle (flags)
	inc	ax			; Get first object/data handle
	inc	ax
	mov	si, ax			; Setup *ds:si to be same
	call	ObjGetFlags		; Get flags for the chunk
	test	al, mask OCF_IS_OBJECT	; Only do it if is an object coming
	jz	exit			; from resource.  (An object so we
					; can add vardata, and a resource
	test	al, mask OCF_IN_RESOURCE; so we have some reassurance
	jz	exit			; that it will stay in place)
	mov_tr	bp, cx			; save source block in bp
	mov	ax, DEBUG_META_OBJ_DUPLICATE_RESOURCE_INFO or \
						mask VDF_SAVE_TO_STATE
	mov	cx, size DebugObjDuplicateResourceInfo
	call	ObjVarAddData		; ds:bx = new entry
	segmov	es, ds			; es:di = new entry
	mov	di, bx
	mov	bx, bp			; get source template block in bx
	call	MemOwnerFar
	call	MemLock
	mov	ds, ax			; ds:si = perm name of owner
	mov	si, offset GH_geodeName
	mov	cx, GEODE_NAME_SIZE	; Copy into vardata
	rep	movsb
	call	MemUnlock
EC <	call	NullDS							>
	mov	cx, bp			; get source template block in cx
					; bx still = owner
	mov	al, RELOC_HANDLE	; Unrelocate it
	call	ObjDoUnRelocation	; cx = unrelocated template handle
	mov	ax, cx
	stosw				; Stuff result into vardata
	segmov	ds, es			; Final seg in ds
exit:
endif
	.leave
	ret
DebugTagDuplicate	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	DetermineBurdenThreadForDuplicatedResource

DESCRIPTION:	

CALLED BY:	INTERNAL
		ObjDuplicateResource

PASS:		ds	- kdata
		ax	- new owner to be used for duplicated resource
		bx	- resource to be duplicated
		cx	- handle of thread to run new block, OR
	     	          0 to have block run by current running thread, OR
	     	  	  -1 to copy nature of thread from source block:

			  if source is process-run, dest will be process-run.
			  if source is ui-run, dest will be ui-run.
			  if source run by anything else, that same thread will
				run the new block.

RETURN:		di	- burden thread to run duplicated resource, or
			  "-2" to use as-yet-uncreated UI thread of new owner

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/1/92		Broke out, extended for new thread model
------------------------------------------------------------------------------@

DetermineBurdenThreadForDuplicatedResource	proc	near
	uses	bx, si, es
	.enter

	mov	di, cx

	; If ZERO passed, return current thread.
	;
	tst	di
	jne	notCurrentThread
	mov	di, ds:[currentThread]
	jmp	short doneWithRealThread

notCurrentThread:
	;
	; If a -1 passed, duplicate nature from source block.
	; Otherwise, real thread handle passed, just return that.
	;
	cmp	di, -1
	jne	doneWithRealThread

	mov	di, ds:[bx].HM_otherInfo	;di = burden thread of source
	mov	si, ds:[bx].HM_owner		;si = owner of source

	;
	; if source block run by process, convert burden thread to token "-1"
	;
	cmp	di, -1
	je	sourceIsProcessRun
	cmp	di, ds:[si].HM_otherInfo	;compare against 1st thread
	jne	sourceNotProcessRun

sourceIsProcessRun:
	mov	bx, ax				;get new owner in bx
	mov	di, ds:[bx].HM_otherInfo	;return 1st thread of new owner
	jmp	short doneWithRealThread

sourceNotProcessRun:
	;
	; if source block run by ui, convert burden thread to token "-2"
	;
	cmp	di, -2
	je	sourceIsUIRun
	mov	bx, si				;get owner of source block in bx
	call	Obj_MemLockES_save_ax		;es = core block of source
	cmp	di, es:[PH_uiThread]		;compare against UI thread
	call	Obj_MemUnlock
EC <	call	NullES							>
	jne	sourceNotUIRun

sourceIsUIRun:
	mov	bx, ax				;get new owner in bx
	call	Obj_MemLockES_save_ax		;es = core block of source
	mov	di, es:[PH_uiThread]		;return UI thread of new owner
	call	Obj_MemUnlock
EC <	call	NullES							>
	tst	di				;... unless NULL...
	jnz	doneWithRealThread
	mov	di, -2				;in which case return "-2",
						;which will be converted to the
						;UI thread, once one is created.
	jmp	short done

sourceNotUIRun:
	; Warning!  bx may be trashed at this point

	; 
	; If source run by neither process nor UI thread, then there's no
	; symbolic nature to be duplicated -- just have new duplicated resource
	; run by the same exact thread as ran the source.
	;

doneWithRealThread:

EC <	xchg	bx, di							>
EC <	call	ECCheckThreadHandleFar					>
EC <	xchg	bx, di							>

done:
	.leave
	ret

DetermineBurdenThreadForDuplicatedResource	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindDuplicate

DESCRIPTION:	Locate the saved-block handle corresponding to the given
		memory block.

CALLED BY:	FullObjLock, ObjMapSavedToState, TransferToVM

PASS:
	bx - handle for which to search

RETURN:
	carry - set if error (not found)
	ds - idata
	si - handle found
	cx - vm file handle

DESTROYED:	ax, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

FindDuplicate	proc	far
if	TEST_DUPLICATE_LIST
	call	ECCheckMemHandleNS
endif
	push	bx
	LoadVarSeg	ds
	mov	bx,ds:[bx].HM_owner
	call	Obj_MemLockES_save_ax			;es = core block
	pop	bx

	mov	cx,es:[PH_vmHandle]
	mov	si, es:[PH_savedBlockPtr]	;si = handle
	test	es:[GH_geodeAttr],mask GA_PROCESS
	call	Obj_MemUnlockES
EC <	call	NullES							>
	jz	retErr

FD_loop:
if	TEST_DUPLICATE_LIST
	call	ECCheckMemHandleNS
endif
	tst	si
	jz	retErr
	cmp	bx,ds:[si].HSB_handle
	jz	FD_ret
	mov	si, ds:[si].HSB_next
	jmp	FD_loop

retErr:
	stc
FD_ret:
	ret

FindDuplicate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocVMAddToSavedList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to allocate a VM block handle for a saved
		block in its process's state file and append the block
		to the list of saved blocks for the process

CALLED BY:	ObjSaveBlock, ObjDuplicateResource
PASS:		bx	= handle to add
RETURN:		nothing
DESTROYED:	si, ax, cx, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocVMAddToSavedList	proc	far
		.enter
	;
	; Fetch the segment of the owner's core block so we can get at its
	; saved block list and its state file handle.
	;
		push	bx
		LoadVarSeg	ds
		mov	bx,ds:[bx].HM_owner
		call	MemLock
		mov	es, ax			;es = core block
		pop	bx
EC <		test	es:[GH_geodeAttr], mask GA_PROCESS		>
EC <		ERROR_Z	OBJ_BLOCK_NOT_OWNED_BY_PROCESS		>
		mov	ax, es:[PH_vmHandle]

		tst	ax
		jz	allocHSB
	;
	; Replace the VM override file so (a) bx is unmolested and (b) we
	; don't unintentionally use a file we don't want to.
	;
		mov_tr	dx, ax			;dx = VM file
		call	AllocEmptyVMBlock

	;
	; Create a saved block handle associated with the block.
	; ax = associated vm block handle, or 0 if no state file yet
	;
allocHSB:
		call	AddToSavedList
		push	bx
		mov	bx, es:[GH_geodeHandle]
		call	MemUnlock
EC <		call	NullES						>
		pop	bx
	;
	; Mark the block as being detachable now it is in the saved-blocks
	; list for the process.
	;
		call	MemLockSkipObjCheck			;ax = segment

		mov	ds, ax
		ornf	ds:[LMBH_flags], mask LMF_DETACHABLE
		call	MemUnlock
		.leave
		ret
AllocVMAddToSavedList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocEmptyVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate an empty VM block in the state file for the
		process for a duplicated block.

CALLED BY:	AllocVMAddToSavedList, ObjAssocVMFile
PASS:		dx	= handle of state file
		bx	= handle of duplicated/saved block
RETURN:		ax	= VM block handle for block
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocEmptyVMBlock proc	far	uses bx, ds
		.enter
	;
	; Figure the UID for the block.
	;
		LoadVarSeg	ds
		call	GetSavedBlockVMUserID
	;
	; Allocate an empty VM block handle for the thing so we can relocate
	; and unrelocate references to this block.
	; 
		clr	cx			;alloc VM handle only
		mov	bx, dx
		call	VMAlloc
		.leave
		ret
AllocEmptyVMBlock endp
COMMENT @----------------------------------------------------------------------

FUNCTION:	AddToSavedList

DESCRIPTION:	Put the given handle on the saved blocks list

CALLED BY:	AllocSavedBlock, AllocVMAddToSavedList

PASS:
	ax - associated VM ID (if 0 then allocate next odd id)
	bx - handle to put on list
	es - core block of owner (locked)

RETURN:
	bx - same

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
AddToSavedList	proc	far	uses ax, si, ds
	.enter

	push	bx
	LoadVarSeg	ds
	mov	bx, es:[GH_geodeHandle]		;set owner for HSB
	call	MemIntAllocHandle		;bx = new handle
	mov	ds:[bx].HSB_handleSig,SIG_SAVED_BLOCK

	mov	si, bx				;si = new handle
	INT_OFF		; prevent blocks being lost should a context
			;  switch to another thread of the same process
			;  that also performs an ObjDuplicateResource (or
			;  ObjSaveBlock) happen between the xchg and the mov
	xchg	si,es:[PH_savedBlockPtr]	;put at start of list
	mov	ds:[bx].HSB_next, si
	INT_ON

	; if VM ID passed is 0 then substitute next odd number

	tst	ax
	jnz	gotID
	inc	ax				;assume this is the first block
	tst	si
	jz	gotID
	mov	ax, ds:[si].HSB_vmID
	inc	ax
	inc	ax
gotID:

	mov	ds:[bx].HSB_vmID, ax

	pop	ax				;ax = handle being saved
	mov	ds:[bx].HSB_handle,ax
	xchg	bx,ax				;(1-byte inst) bx <- ax

	.leave
	ret

AddToSavedList	endp


ObjectLoad ends

;------------------------------------------

ObjectFile segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjSaveBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up an LMem block to be saved to its owner's state file

CALLED BY:	GLOBAL
PASS:		bx	= handle of block to be saved. This block must be
			  an LMem block and have LMF_HAS_FLAGS set in its
			  LMBH_flags word (and have a flags chunk of course).
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjSaveBlock	proc	far	uses ax, cx, si, ds, es
		.enter

EC <		LoadVarSeg	ds					>
EC < 		test	ds:[bx].HM_flags, mask HF_LMEM			>
EC <		ERROR_Z	OBJ_SAVE_BLOCK_NOT_LMEM				>
EC <		push	ax						>
EC <		call	MemLock						>
EC <		mov	es, ax						>
EC <		pop	ax						>
EC <		test	es:[LMBH_flags], mask LMF_HAS_FLAGS		>
EC <		ERROR_Z	OBJ_LMEM_BLOCK_HAS_NO_FLAGS			>
EC <		call	MemUnlock					>
EC <		call	FindDuplicate					>
EC <		ERROR_NC OBJ_SAVE_BLOCK_ALREADY_SAVED			>

		call	AllocVMAddToSavedList

	; Mark that there is no other copy of this block in the state file

		call	MemLock
		mov	ds, ax
		ornf	ds:LMBH_flags, mask LMF_DUPLICATED
		call	MemUnlock

		.leave
		ret
ObjSaveBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjFreeDuplicate

DESCRIPTION:	Free a block created by ObjDuplicateResource or saved with
		ObjSaveBlock

CALLED BY:	GLOBAL

PASS:
	bx - handle of block to free

RETURN:
	none

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ObjFreeDuplicate	proc	far	uses ax, cx, dx, si, di, bp, ds, es
	.enter

EC <	call	ECCheckMemHandleFar					>
	call	ObjLockObjBlock		;lock the sucker
	mov	ds, ax
	test	ds:[LMBH_flags], mask LMF_DETACHABLE
	jz	done

	push	ax, bx
	LoadVarSeg	ds
	mov	bx, ds:[bx].HM_owner
	call	MemLock
	mov	es, ax					; es = core block
	pop	ax, bx

	push	es

	mov	cx, es:[PH_vmHandle]			; cx <- state file
	mov	di, offset PH_savedBlockPtr

	; Keep interrupts off during the unlinking so that we don't context
	; switch at a bad time

	INT_OFF

findLoop:
	mov	si, es:[di]
	tst	si
	jz	noVM
	cmp	bx, ds:[si].HSB_handle
	jz	found
	lea	di, ds:[si].HSB_next
	segmov	es, ds
	jmp	findLoop

	; found, es:di points at pointer to handle, si = handle

found:
	mov	ax, ds:[si].HSB_next
	stosw				;remove from linked list

	INT_ON

	push	bx
	jcxz	freeHSB			; if no state file,  don't
					;  futz with VM file, as nothing's
					;  been allocated.

	mov	ax, ds:[si].HSB_vmID	
	mov	bx, cx			; bx <- VM file handle
	call	VMFree

freeHSB:
	mov	bx, si
	call	FarFreeHandle
	pop	bx
noVM:
	INT_ON					;restore ints in not found case
	pop	es				; es <- core block
	push	bx
	mov	bx, es:[GH_geodeHandle]
	call	MemUnlock
EC <	call	NullES							>
	pop	bx
done:
	.leave
	GOTO	MemFree

ObjFreeDuplicate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMapSavedToState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a saved/duplicated block to its corresponding VM block
		handle in the process's state file.

CALLED BY:	GLOBAL
PASS:		bx	= handle to map
RETURN:		if block found, carry is clear and
			ax	= VM block handle for the block
		if no such block is on the process's list of non-resource
			blocks to be saved, the carry is returned set
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMapSavedToState proc	far	uses ds, si, es, di, cx
		.enter
		call	FindDuplicate
		jc	done
		mov	ax, ds:[si].HSB_vmID
done:
		.leave
		ret
ObjMapSavedToState endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMapStateToSaved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a VM block ID from a state file to the corresponding
		memory block handle for a process.

CALLED BY:	GLOBAL
PASS:		ax	= VM block handle
		bx	= process handle or 0 for current thread's process
RETURN:		if block found, carry is clear and
			bx	= memory block handle 
		if no such block appears on a process's saved block list,
			carry is set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMapStateToSaved proc	far	uses ds, si
		.enter
		tst	bx			; process handle passed ?
		jnz	getAddress		; yes, so use it
		mov	bx, ss:[TPD_processHandle]
						; else get the current process
getAddress:
EC <		call	ECCheckGeodeHandle	; verify the handle	>
		push	ax
		call	MemLock
		mov	ds, ax
		pop	ax

EC <		test	ds:[GH_geodeAttr], mask GA_PROCESS		>
EC <		ERROR_Z	NOT_PROCESS_HANDLE				>
		mov	si, ds:[PH_savedBlockPtr]
		LoadVarSeg	ds
scanLoop:
		tst	si
		jz	fail
		cmp	ds:[si].HSB_vmID, ax
		je	happiness
		mov	si, ds:[si].HSB_next
		jmp	scanLoop
happiness:
		mov	si, ds:[si].HSB_handle
done:
		call	MemUnlock
		mov	bx, si
		.leave
		ret
fail:
		stc
		jmp	done
ObjMapStateToSaved endp

ObjectFile	ends
