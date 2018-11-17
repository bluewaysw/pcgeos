COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Object
FILE:		objProcess.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ProcessClass		Superclass of all processes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file contains routines to implement the process class.

	$Id: objectProcess.asm,v 1.1 97/04/05 01:14:48 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT @----------------------------------------------------------------------

Synopsis
--------

ProcessClass is the parent of all processes in the system.  ProcessClass is
a special class in that there are no instances of ProcessClass and there is
only one instance of each subclass of ProcessClass.  Also, methods sent to
a process (via ObjMessage) are sent as events and therefore are
received asyncronously.

ProcessClass provides methods for the standard handling of some standard events
sent to processes.

------------------------------------------------------------------------------@

	; process class (parent of all processes)
	ProcessClass	mask CLASSF_NEVER_SAVED

	method	ThreadDestroy, ProcessClass, MSG_PROCESS_EXIT


COMMENT @----------------------------------------------------------------------

FUNCTION:	ProcessDetach -- MSG_META_DETACH for ProcessClass

DESCRIPTION:	Destroy the current thread by clearing the event queue and
		calling ThreadDestroy

PASS:
	ds - core block of geode
	es - segment where process class defined (same as ds for applications)

	di - MSG_META_DETACH

	cx 	- Exit code
	dx:bp	- Output descriptor of caller (one to send METHOD_META_ACK to)
	si 	- data to pass as BP portion of "DX:BP = source of ACK" in
		  MSG_META_ACK, as the source, this thread, requires only DX
		  to reference.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

ProcessDetach	method static	ProcessClass, MSG_META_DETACH
	mov	ax, MSG_PROCESS_EXIT
	mov	bx,ss:[TPD_threadHandle]
	call	ObjMessageForceQueue
	ret

ProcessDetach	endm

MetaProcessClassCode	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ProcessFinalBlockFree --
		MSG_PROCESS_FINAL_BLOCK_FREE for ProcessClass

DESCRIPTION:	free the block

PASS:
	ds - core block of geode

	cx - block handle

RETURN:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Broken out from ProcessInternalContinueFreeBlock

------------------------------------------------------------------------------@

ProcessFinalBlockFree	method dynamic ProcessClass,
					MSG_PROCESS_FINAL_BLOCK_FREE

	mov	bx, cx

	; First, check to see if the block is really a VM block

	LoadVarSeg	ds
	mov	si, ds:[bx].HM_owner
	cmp	ds:[si].HG_type, SIG_VM
	jnz	notVM

	call	VMMemBlockToVMBlock
	call	VMFree
	ret

notVM:
	call	ObjLockObjBlock
	mov	ds, ax
	mov	ax, ds:[LMBH_flags]
	test	ax, mask LMF_DETACHABLE
	jz	useMemFree
	test	ax, mask LMF_DUPLICATED
	jnz	useFreeDup
useMemFree:
	GOTO	MemFree

useFreeDup:
	call	ObjFreeDuplicate
	ret

ProcessFinalBlockFree	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessBlockDiscard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discards the passed block - if it is a resource block, this
		modifies the handle data to reflect the size of the block.

CALLED BY:	GLOBAL
PASS:		cx - handle of block to discard (must be owned by this geode)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessBlockDiscard	method	ProcessClass, MSG_PROCESS_OBJ_BLOCK_DISCARD
	.enter
   	mov	bx, cx
EC <	call	ECCheckLMemHandle					>

	call	MemLock
	mov	ds, ax

;	Ensure that the block passed in is valid - it has to be an object
;	block, and cannot be allocated from scratch or duplicated

EC <	test	ds:[LMBH_flags], mask LMF_DUPLICATED 			>
EC <	ERROR_NZ	CANNOT_DISCARD_DUPLICATED_BLOCK			>

EC <	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	ERROR_NZ	CANNOT_DISCARD_NON_OBJ_BLOCK			>

EC <	tst	ds:[OLMBH_inUseCount]					>
EC <	ERROR_NZ	CANNOT_DISCARD_BLOCK_THAT_IS_IN_USE		>


;	The object block can be a different size than it was originally
;	(if objects were allocated/spec built in the block).
;
;	Get the original size of the resource so we can stuff it back in
;

	mov	cx, ds:[OLMBH_resourceSize]	;CX <- original size of block
						; (in paragraphs)
EC <	tst	cx							>
EC <	ERROR_Z		CANNOT_DISCARD_ALLOCATED_OBJ_BLOCK		>

	call	MemUnlock	;

;	Make the block discardable temporarily, discard it, then set it
;	not-discardable.

	LoadVarSeg	ds
	BitSet	ds:[bx].HM_flags, HF_DISCARDABLE
   	call	MemDiscard
	BitClr	ds:[bx].HM_flags, HF_DISCARDABLE
	mov	ds:[bx].HM_size, cx
	.leave
	ret
ProcessBlockDiscard	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ProcessInstantiate -- MSG_PROCESS_INSTANTIATE for ProcessClass

DESCRIPTION:	Remotely instantiate an object

PASS:
	ds - core block of geode
	es - segment where process class defined (same as ds for applications)

	di - MSG_PROCESS_INSTANTIATE

	cx - data for ObjInstantiate
	dx - block to instantiate in
	bp:si - class to instantiate

RETURN:
	bp - newly created chunk

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

ProcessInstantiate	method dynamic ProcessClass, MSG_PROCESS_INSTANTIATE
	mov	es,bp
	mov	di,si
	mov	bx,dx
	call	ObjInstantiate
	mov	bp,si
	ret

ProcessInstantiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessInstantiateForThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remotely instantiate an object for thread

CALLED BY:	MSG_PROCESS_INSTANTIATE_FOR_THREAD
PASS:		*ds:si	= ProcessClass object
		ds:di	= ProcessClass instance data
		ds:bx	= ProcessClass object (same as *ds:si)
		es 	= segment of ProcessClass
		ax	= message #
		dx:bp	= class of new object to instantiate
RETURN:		^ldx:bp	= optr of new object
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	2/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessInstantiateForThread	method dynamic ProcessClass, 
					MSG_PROCESS_INSTANTIATE_FOR_THREAD
	clr	bx		; instantiate for current thread
	movdw	esdi, dxbp
	call	ObjInstantiateForThread
	movdw	dxbp, bxsi
	ret
ProcessInstantiateForThread	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ProcessCopyChunkIn

DESCRIPTION:	Copy memory into an object block. Source can be in same block
		(but must be using mode CCM_OPTR).	

WHO CAN USE:	Anyone

PASS:
	es - segment of ProcessClass

	ax - MSG_PROCESS_COPY_CHUNK_IN

	dx		- # of bytes on stack
	ss:bp		- pointer to:

	CopyChunkInFrame	struct
		CCIF_copyFlags	CopyChunkFlags
		CCIF_source	dword
		CCIF_destBlock	hptr
	CopyChunkInFrame	ends

		CopyChunkMode	etype byte
			CCM_OPTR
				;from <object block><chunk>
				;object flags are copied to dest chunk
			CCM_HPTR
				;from <mem block><offset>
			CCM_FPTR
				;from <seg><offset>

		to <destination block><CREATED chunk>

		CopyChunkFlags	record
			CCF_DIRTY:1
			; DIRTY	- if set, mark dest chunk dirty

			CCF_MODE CopyChunkMode:2

			CCF_SIZE:13
			;	Not used for CCM_OPTR

		CopyChunkFlags	end

		DIRTY	- if set, new chunk is DIRTY, but not IGNORE_DIRTY
			  if clear, not DIRTY, but IGNORE_DIRTY

RETURN:
	ax - chunk handle created
	cx - # bytes copied

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	If an object chunk is copied to another chunk the OCF_IS_OBJECT flag
	IS copied to the dest chunk. See above for more details


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/90		Initial version
	cdb	10/91		Changed to allow copying to a
				non-object lmem block

------------------------------------------------------------------------------@
ProcessCopyChunkIn	method	ProcessClass, MSG_PROCESS_COPY_CHUNK_IN
	mov	cx,ss:[bp].CCIF_source.handle	;<cx><dx> = source
	mov	dx,ss:[bp].CCIF_source.chunk
	mov	bx,ss:[bp].CCIF_destBlock
	mov	bp, ss:[bp].CCIF_copyFlags	;bp = CopyChunkFlags
	call	ObjLockObjBlock			;Lock destination block
EC <	call	ECCheckLMemHandle					>
	mov	ds,ax				;DS <- destination block
EC <	call	ECLMemValidateHeapFar					>

	; First, get a far pointer to the data and get the size of the data.
	; How to do this depends on the type of parameters passed.

	push	bp				;Save flags
	clr	si				;Set flag saying we want to
						; unlock the block
	and	bp, mask CCF_MODE
	cmp	bp, CCM_HPTR shl offset CCF_MODE
	je	handleoffset
	inc	si				;Set flag saying we don't want
						; to unlock a block
	cmp	bp, CCM_FPTR shl offset CCF_MODE
	je	farptr
EC <	cmp	bp, CCM_OPTR shl offset CCF_MODE			>
EC <	ERROR_NZ BAD_COPY_CHUNK_MODE					>

	; passed ^lcx:dx -- must lock block, get chunk size and deref chunk

	mov	bx, cx
	call	ObjLockObjBlock		; lock block
	mov	es, ax
	mov	si, dx			; *es:si = source

	; make sure that the passed chunk actually exists

EC <	push	ds							>
EC <	segmov	ds, es							>
EC <	call	ECLMemValidateHandle					>
EC <	pop	ds							>

	mov	di, es:[si]		; es:di = source
	ChunkSizePtr	es, di, cx	; cx = size

	call	ProcObjGetFlags		; get object flags
	andnf	al, mask OCF_IS_OBJECT	; leave only is object flag
	ornf	al, mask OCF_DIRTY	; assume dirty
	pop	bp			; passed chunk copy flags
	test	bp,mask CCF_DIRTY
	jne	dirty1
	andnf	al, not (mask OCF_DIRTY); clear dirty
	ornf	al, mask OCF_IGNORE_DIRTY; set ignore dirty
dirty1:
	call	LMemAlloc
	mov	di, ax			; *ds:di is destination
	mov	di, ds:[di]		; ds:di = dest
	segmov	es, ds			; es:di = dest
	call	MemDerefDS		; *ds:si = source
	mov	si, ds:[si]		; ds:si = source
	clr	bp			; Unlock source block
	jmp	short common

	; passed global memory handle:far

handleoffset:
	mov	bx,cx
	call	MemLock			; lock global block:far
	mov	cx,ax			; segment in cx, offset in dx
farptr:
EC <	mov	ax,ds							>
EC <	cmp	cx,ax							>
EC <	ERROR_Z	CANT_COPY_CHUNK_FROM_FIXED_OFFSET_IN_SAME_SEGMENT	>
	pop	bp			;Restore CopyChunkFlags
	push	cx			;Save source segment
	mov	cx,bp			; cx <- size
	and	cx, mask CCF_SIZE	;
	push	cx			;Save size
EC <	tst	cx							>
EC <	ERROR_Z	ZERO_SIZE_PASSED_TO_COPY_CHUNK_MESSAGE			>

	mov	al, mask OCF_DIRTY
	test	bp,mask CCF_DIRTY
	jne	dirty2
	mov	al, mask OCF_IGNORE_DIRTY
dirty2:
	call	LMemAlloc
	mov	di, ax			; *ds:di is destination
	mov	di, ds:[di]		; ds:di = dest
	segmov	es, ds			; es:di = dest
	pop	cx			;CX <- size
	pop	ds			;Restore source segment
	mov	bp,si			;Move unlock flag into BP
	mov	si,dx			; ds:si = source
common:
	; ds:si = source
	; es:di = dest
	; cx = size
	; bp is zero if block needs unlocking
	; ax = chunk handle of created destination chunk

	call	ProcessCopyCommon
	push	ax
	mov	bx, es:[LMBH_handle]	;Unlock destination block
	call	MemUnlock
	pop	ax
	ret
ProcessCopyChunkIn	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcObjGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Return flags for chunk. If chunk has no flags return 0

CALLED BY:	INTERNAL
		ProcessCopyChunkIn
PASS:		
		*(es:si) - chunk

RETURN:		
		al - flags or zero
		ah - zero

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		optimized for no flags case

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcObjGetFlags		proc	near
	.enter
	test	es:[LMBH_flags], mask LMF_HAS_FLAGS
	jnz	hasFlags
	clr	ax					;no flags
done:
	.leave
	ret

hasFlags:
	push	ds					;don't destroy
	segmov	ds,es,ax				;object segment
	mov	ax,si					;object chunk
	call	ObjGetFlags		
	pop	ds					;undestroy
	jmp	done

ProcObjGetFlags		endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ProcessCopyCommon

DESCRIPTION:	Common code between GenCopyChunkIn and GenCopyChunkOut

CALLED BY:	INTERNAL

PASS:
	ds:si - source
	es:di - dest
	cx - number of bytes to move (not including possible null-termination)
	bp - flag -> if bp=0 then unlock bx after move
	bx - handle (if bp = 0)

RETURN:	nada


DESTROYED:	cx,si,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ProcessCopyCommon	proc	near
	uses	cx
	.enter

	;ds:si = source, es:di = dest, cx = count

	rep	movsb

	tst	bp
	jnz	farPtr
	push	ax
	call	MemUnlock
	pop	ax
farPtr:
	.leave
	ret

ProcessCopyCommon	endp


COMMENT @----------------------------------------------------------------------

METHOD:		ProcessCopyChunkOut

DESCRIPTION:	Copy a local memory chunk.  Operation may be done in same 
		block.

WHO CAN USE:	Anyone

PASS:
	es - segment of ProcessClass

	ax - MSG_PROCESS_COPY_CHUNK_OUT

	dx		- # of bytes on stack
	ss:bp		- pointer to:

	CopyChunkOutFrame	struct
		CCOF_copyFlags	CopyChunkFlags
		CCOF_source	optr
		CCOF_dest	dword
	CopyChunkOutFrame	ends

	CopyChunkMode	etype byte
		CCM_OPTR
			;to <object block><CREATED CHUNK)
			; object block handle in CCOF_dest.handle	
		CCM_HPTR
			;to <CREATED mem block>)
		CCM_FPTR
			;to <seg><offset>

	In CopyChunkFlags:

	DIRTY	- IF there is a CREATED chunk, THEN:
		  if set, new chunk is DIRTY, but not IGNORE_DIRTY
		  if clear, not DIRTY, but IGNORE_DIRTY

RETURN:
	ax - chunk/block handle (if one created)
	cx - number of characters copied

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	If an object chunk is copied to another chunk the OCF_IS_OBJECT flag
	is NOT copied to the dest chunk. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/90		Initial version

------------------------------------------------------------------------------@
ProcessCopyChunkOut	method dynamic	ProcessClass, MSG_PROCESS_COPY_CHUNK_OUT

	mov	cx, ss:[bp].CCOF_copyFlags

;	FIRST, GET PTR TO SOURCE IN DS:SI

	mov	bx,ss:[bp].CCOF_source.handle
	mov	si,ss:[bp].CCOF_source.chunk
	call	ObjLockObjBlock				;Lock source block
EC <	call	ECCheckLMemHandle					>
	mov	ds,ax					;DS <- source block
EC <	call	ECLMemValidateHeapFar					>
EC <	call	ECLMemValidateHandle					>
	mov	si,ds:[si]				;DS:SI <- ptr to data
	ChunkSizePtr	ds,si,dx			;DX <- size of data

;	NOW, GET PTR TO DEST IN ES:DI

	clr	di				;Set flag saying we want to
						; unlock the block
	push	cx
	and	cx, mask CCF_MODE
	cmp	cx, CCM_HPTR shl offset CCF_MODE
	je	handleoffset
	inc	di				;Set flag saying we don't want
						; to unlock a block
	cmp	cx, CCM_FPTR shl offset CCF_MODE
	je	farptr
EC <	cmp	cx, CCM_OPTR shl offset CCF_MODE			>
EC <	ERROR_NZ BAD_COPY_CHUNK_MODE					>

;	DEST IS OPTR -- LOCK BLOCK AND CREATE CHUNK FOR DEST

	pop	cx				;Restore CopyChunkFlags
	push	bx				;Save handle of source block
	mov	bx,ss:[bp].CCOF_dest.handle
	call	ObjLockObjBlock			;Lock the block
	mov	ds,ax				;DS <- dest block
EC <	call	ECLMemValidateHeapFar					>
	pop	bx				;Restore handle of source block
	mov	al, mask OCF_DIRTY		;Set dirty flags of dest block
	test	cx, mask CCF_DIRTY
	jne	dirty
	mov	al, mask OCF_IGNORE_DIRTY
dirty:
	mov	cx,dx				;CX <- size
	call	LMemAlloc
	push	ax				;Save chunk handle
	mov	di,ax
	mov	di,ds:[di]			;Dereference new chunk
	segmov	es,ds				;ES:DI <- ptr to dest
	call	MemDerefDS			;DS:SI <- ptr to source
	mov	bx, es:[LMBH_handle]		;BX <- handle of dest block
	jmp	unlockblockcommon
handleoffset:

;	DEST IS CREATED BLOCK -- CREATE BLOCK

	pop	cx				;Pop flags off stack
	mov	ax,dx				;AX <- SIZE OF NEW BLOCK
	mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or mask HF_SHARABLE or mask HF_SWAPABLE
	call	MemAllocFar			;BX <- handle of dest block
						;AX <- size of dest block
	push	bx				;Save new block handle
	mov	es,ax				;ES:DI <- dest
	clr	di
unlockblockcommon:
	clr	bp				;Set flag -- we want to unlock
						; dest block
	jmp	common
farptr:

;	DEST IS FAR POINTER -- JUST GET POINTER

	pop	cx				;Pop flags off stack
	mov	es, ss:[bp].CCOF_dest.segment
	mov	di, ss:[bp].CCOF_dest.offset
	mov	bp,1				;Don't want to unlock dest
						; block
	push	bp				;Just push any random amount
common:		
	mov	cx,dx				;CX <- size
	call	ProcessCopyCommon
	mov	bx,ds:[LMBH_handle]
	call	MemUnlock			;Unlock source block
	pop	ax				;Restore created chunk/block 
						; handle
	ret
ProcessCopyChunkOut	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ProcessCopyChunkOver

DESCRIPTION:	Copy a local memory chunk OVER an object block chunk. If 
		copying from the same block, MUST USE CCM_OPTR!

WHO CAN USE:	Anyone

PASS:
	es - segment of ProcessClass

	ax - MSG_PROCESS_COPY_CHUNK_OVER

		dx		- # of bytes on stack
		ss:bp		- pointer to:

		CopyChunkOVerFrame	struct
			CCOVF_copyFlags	CopyChunkFlags
			CCOVF_source	dword
			CCOVF_dest	optr
				;If dest chunk is 0, new chunk created and
				;object flags are copied to dest chunk
		CopyChunkOVerFrame	ends


		CopyChunkMode	etype byte
			CCM_OPTR
				;from <object block><chunk>
			CCM_HPTR
				;from <mem block><offset>
			CCM_FPTR
				;from <seg><offset>
;
		CopyChunkFlags	record
			CCF_DIRTY:1
			; DIRTY	- if set, mark dest chunk dirty

			CCF_MODE CopyChunkMode:2

			CCF_SIZE:13
			;	Not used for CCM_OPTR

		CopyChunkFlags	end

RETURN:

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	In general, if an object chunk is copied to another chunk,
	the OCF_IS_OBJECT flag is NOT copied to the dest chunk. 
	See above for more details

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/90		Initial version

------------------------------------------------------------------------------@
ProcessCopyChunkOver	method dynamic	ProcessClass, MSG_PROCESS_COPY_CHUNK_OVER
	mov	cx, ss:[bp].CCOVF_copyFlags	;cx = CopyChunkFlags

	; First, get a far pointer to the data and get the size of the data.
	; How to do this depends on the type of parameters passed.

	tst	ss:[bp].CCOVF_dest.chunk	;Is dest chunk null?
	jne	notnull				;Branch if not
	mov	bx,bp				;Save CCOVF
	sub	sp, size CopyChunkInFrame
	mov	bp, sp
	mov	ax, ss:[bx].CCOVF_source.handle
	mov	ss:[bp].CCIF_source.handle, ax
	mov	ax, ss:[bx].CCOVF_source.chunk
	mov	ss:[bp].CCIF_source.chunk, ax
	mov	ax, ss:[bx].CCOVF_dest.handle
	mov	ss:[bp].CCIF_destBlock, ax
	mov	ss:[bp].CCIF_copyFlags, cx
	call	ProcessCopyChunkIn		;Copy the data in.
	add	sp, size CopyChunkInFrame
	ret

notnull:
	push	cx				;Save flags
	clr	si				;Set flag saying we want to
						; unlock the block
	and	cx, mask CCF_MODE
	cmp	cx, CCM_HPTR shl offset CCF_MODE
	LONG_EC je	handleoffset
	inc	si				;Set flag saying we don't want
						; to unlock a block
	cmp	cx, CCM_FPTR shl offset CCF_MODE
	LONG_EC je	farptr
EC <	cmp	cx, CCM_OPTR shl offset CCF_MODE			>
EC <	ERROR_NZ BAD_COPY_CHUNK_MODE					>

;	SOURCE IS OPTR - LOCK BLOCK AND DEREFERENCE CHUNK

	mov	bx, ss:[bp].CCOVF_source.handle
	call	ObjLockObjBlock			; lock source block
	mov	es, ax
	mov	si, ss:[bp].CCOVF_source.chunk	; *es:si = source

	; make sure that the passed chunk actaully exists

EC <	push	ds							>
EC <	segmov	ds, es							>
EC <	call	ECLMemValidateHeapFar					>
EC <	call	ECLMemValidateHandle					>
EC <	pop	ds							>

	mov	di, es:[si]		; es:di = source
	ChunkSizePtr	es, di, cx	; cx = size

	mov	bx, ss:[bp].CCOVF_dest.handle
	call	ObjLockObjBlock		;Lock the block
	mov	ds,ax			;DS <- dest segment
	mov	ax, ss:[bp].CCOVF_dest.chunk
EC <	push	si							>
EC <	mov	si,ax							>
EC <	call	ECLMemValidateHeapFar					>
EC <	call	ECLMemValidateHandle					>
EC <	pop	si							>
	call	LMemReAlloc		;Reallocate the chunk to be the right
					; size
	pop	di
	test	di, mask CCF_DIRTY	;Do we want to mark the chunk as dirty?
	mov	bx, (mask OCF_DIRTY shl 8)	;assume not, clear OCF_DIRTY
	jz	notdirty		;If not, branch	
	mov	bx, mask OCF_DIRTY	;Else set the block as dirty
notdirty:
	call	ObjSetFlags		;
	mov	di,ax
	mov	di,ds:[di]		;
	segmov	es,ds			;es:di <- dest ptr
	mov	bx, ss:[bp].CCOVF_source.handle	;^lBX:SI <- source ptr
	call	MemDerefDS		;*DS:SI <- source ptr
	mov	si,ds:[si]		;DS:SI <- source ptr
	clr	bp			;Else, clear BP so we unlock the block
					; in BX
	jmp	common

handleoffset:
	mov	bx,ss:[bp].CCOVF_source.handle
	call	MemLock			; lock global block:far
	mov	es,ax			;ES <- source segment
	jmp	offsetcommon
farptr:
	mov	es,ss:[bp].CCOVF_source.segment
offsetcommon:
	pop	cx			;Restore flags
	push	bx
	mov	bx, ss:[bp].CCOVF_dest.handle
	call	ObjLockObjBlock
EC <	mov	bx,es							>
EC <	cmp	bx,ax							>
EC <	ERROR_Z	CANT_COPY_CHUNK_FROM_FIXED_OFFSET_IN_SAME_SEGMENT	>
	mov	ds,ax			;DS <- dest block
	mov	ax, ss:[bp].CCOVF_dest.chunk

;	MARK DEST CHUNK AS DIRTY IF NEEDED

	test	cx, mask CCF_DIRTY	;Do we want to mark the chunk as dirty?
	je	notdirty1		;If not, branch	
	mov	bx, mask OCF_DIRTY	;Else set the block as dirty
	call	ObjSetFlags		;
notdirty1:
	and	cx, mask CCF_SIZE	;CX <- size of data
EC <	tst	cx							>
EC <	ERROR_Z	ZERO_SIZE_PASSED_TO_COPY_CHUNK_MESSAGE		>
	call	LMemReAlloc		;Reallocate dest to be correct size
	mov	di,es			;DI <- segment of source block
	segmov	es,ds,dx		;ES <- segment of dest block
	mov	ds,di			;DS <- segment of source block
	mov	di,ss:[bp].CCOVF_source.offset ;DS:DI <- source
	mov	bp,si			;BP <- unlock source block flag
					; (if 0, unlock the source block in 
					; ProcessCopyCommon)
	mov	si,di			;DS:SI <- source 
	mov	di,ax			;*ES:DI <- dest
	mov	di,es:[di]		;ES:DI <- dest
	pop	bx			;Restore handle of source block (if 
					; mode is CCM_HPTR)
common:
	; ds:si = source
	; es:di = dest
	; cx = size
	; bp is zero if block in bx needs unlocking

	call	ProcessCopyCommon
	push	ax
	mov	bx, es:[LMBH_handle]	;Unlock destination block
	call	MemUnlock
	pop	ax
	ret
ProcessCopyChunkOver	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle MSG_META_SEND_CLASSED_EVENT to avoid getting to
		MetaClass handler, which assumes an LMem object

CALLED BY:	MSG_META_SEND_CLASSED_EVENT

PASS:		ds	= dgroup of process
		es 	= segment of ProcessClass
		ax	= MSG_META_SEND_CLASSED_EVENT

		cx	= handle of classed event
		dx	= TravelOption:
				If TO_NULL, destroy
				If TO_OBJ_BLOCK_OUTPUT, FatalError
				else send to self (TO_SELF or TO_PROCESS)

RETURN:		if Event delivered:
			carry, ax, cx, dx, bp	= return values, if any,
							from method

ALLOWED TO DESTROY:
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/21/93  	Initial version (modified from
						ObjMetaSendClassedEvent)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessSendClassedEvent	method	ProcessClass, MSG_META_SEND_CLASSED_EVENT
	mov	bx, cx			; bx = event
	tst	dx
	jnz	maybeDeliver		; if not TO_NULL, maybe deliver
destroyEvent:
	call	ObjFreeMessage
	;
	; Emulate ObjCallMethodTable, clearing AX and carry, so caller
	; can reliably determine if message was delivered, barring
	; thread crossings and assuming real handler always returns carry
	; set... -- ardeb 10/25/92
	; 
	clr	ax
	ret				; <-- EXIT HERE

maybeDeliver:
EC <	cmp	dx, TO_OBJ_BLOCK_OUTPUT					>
EC <	ERROR_E	PROCESS_CLASS_ASKED_TO_SEND_TO_OBJ_BLOCK_OUTPUT		>
NEC <	cmp	dx, TO_OBJ_BLOCK_OUTPUT					>
NEC <	je	destroyEvent						>
	
	call	ObjGetMessageInfo	; ^lcx:si = class
	jcxz	dispatchEvent		; null class, dispatch
	push	ds, es
	mov	di, si
	mov	es, cx			; es:di = event class
	mov	si, segment ProcessClass
	mov	ds, si
	mov	si, offset ProcessClass	; ds:si = ProcessClass
	call	ObjIsClassADescendant	; is event class a subclass of Process?
	pop	ds, es
	jnc	destroyEvent		; nope, destroy event

dispatchEvent:
	push	bx			; save event handle
	call	GeodeGetProcessHandle	; bx = process
	mov	cx, bx
	pop	bx			; restore event handle
	clr	si			; no extra data for process message
					;	handler
	call	MessageSetDestination	; set destination
	mov	di, mask MF_CALL
	call	MessageDispatch
	ret
ProcessSendClassedEvent	endm

MetaProcessClassCode	ends

GLoad	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessStartupUIThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a "UI" thread for this process, if any of its resources
		are marked to be run by such a thread.

CALLED BY:	MSG_PROCESS_STARTUP_UI_THREAD
PASS:		es	= kdata
RETURN:		carry clear if thread created
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	6/1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessStartupUIThread method	ProcessClass,
					MSG_PROCESS_STARTUP_UI_THREAD
	.enter
	call	GeodeGetProcessHandle
	call	MemLock
	mov	ds, ax		; ds:0 now points at ProcessHeader

	push	bx
	mov	ax, -2		; "-2" is token left to mean "UI thread"
	mov	bx, ax

	; Nothing to substitute yet, just find out if there are any blocks 
	; marked to be run by an as-yet uncreated UI thread
	;
	call	SubstituteRunningThread
	pop	bx
	tst	ax
	jz	noThread	; if none found, exit -- no UI thread needed

	clr	si
	mov	cx, segment ProcessClass
	mov	dx, offset ProcessClass
	clr	bp		; Use default stack size (GenProcessClass
				; will intercept to stuff appropriate value,
				; if app hasn't intercepted & overridden)
	mov	ax, MSG_PROCESS_CREATE_UI_THREAD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jc	noThread	; if unable to create for whatever reason, exit

	; Now that we've got a UI thread, fix up all resources marked as
	; "ui-object" to be run by that thread.
	; 
	push	bx
	mov	bx, -2		; "-2" is token left to mean "UI thread"
	xchg	ax, bx
	call	SubstituteRunningThread
	xchg	ax, bx
	pop	bx

	; Store thread handle in ProcessHeader, for later access
	mov	ds:[PH_uiThread], ax
	clc			; return carry clear, to indicate thread created

done:
	call	MemUnlock	; unlock core block
	.leave
	ret

noThread:
	stc
	jmp	short done

ProcessStartupUIThread endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessCreateEventThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an event-driven thread owned by the current process.
		Thread is a PRIORITY_STANDARD thread.

CALLED BY:	MSG_PROCESS_CREATE_EVENT_THREAD,
		MSG_PROCESS_CREATE_UI_THREAD
PASS:		es	= kdata
		cx:dx	= fptr to object class for new thread
		bp	= size of stack for new thread, or NULL for default
			  size (512 bytes)
RETURN:		carry clear if thread could be created:
			ax	= handle of new thread
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessCreateEventThread method	ProcessClass, MSG_PROCESS_CREATE_EVENT_THREAD,
					MSG_PROCESS_CREATE_UI_THREAD
		mov	si, ss:[TPD_processHandle]
		FALL_THRU	ProcessCreateEventThreadWithOwner
ProcessCreateEventThread	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessCreateEventThreadWithOwner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates an event thread for a geode.

CALLED BY:	GLOBAL
PASS:		si - geode to own the thread
		cx:dx - class for the thread
		bp - stack size for the thread, or NULL for the default
RETURN:		carry clear if thread created
		ax - handle of new thread
DESTROYED:	cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessCreateEventThreadWithOwner	method	ProcessClass,
				MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER
		.enter

		LoadVarSeg	ds, ax	; ds <- kdata
		push	cx, dx		; Save class pointer
	;
	; Allocate a queue for the thing.
	;
		call	GeodeAllocQueue
		mov	ax, si
		call	HandleModifyOwner	;Make it owned by the passed
						; geode.
	;
	; Put MSG_META_ATTACH on it for when the thread attaches to it.
	;
		mov	ax, MSG_META_ATTACH
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage	; no nukage of BP if MF_FORCE_QUEUE

	;
	; Now create a thread for the beast and make it attach to the queue
	; we just created. BX already holds the queue (to be passed to the
	; thread in CX)
	;
		mov	al, PRIORITY_STANDARD
		mov	cx, segment NewEventThread
		mov	dx, offset NewEventThread

		mov	di, bp
		tst	di			; if NULL stack size passed,
		jnz	haveStackSize
		mov	di, 512			; use a paltry size of 512.
haveStackSize:
		mov	bp, si			;BP <- owner thread to create
		push	bx
		call	ThreadCreate
		jc	error

   		pop	ds:[bx].HT_eventQueue	; set event queue for the
						;  thread in case somebody
						;  sends an event to it early.
	;
	; Set the class pointer for the thread to that passed. It'll wait
	; until we've done this before it tries to attach to the queue.
	;
		call	ThreadFindStack		; use ThreadFindStack to deal with the
						;  thread possibly being in DOS while it's
						;  notifying its various libraries of its
						;  creation.
		mov	es, ax
		pop	es:[TPD_classPointer].segment, \
			es:[TPD_classPointer].offset
	;
	; Let the new thread run. Again, we use the semaphore created at
	; the bottom of the stack, just above ThreadPrivateData, to
	; synchronize the startup of the thread. 
	;
		mov	di, size ThreadPrivateData
		.warn 	-field
		VSem	es, [di]
		.warn	@field
	;
	; Return the new thread handle in AX
	;
		mov_trash	ax, bx
		clc
done:
		.leave
		ret

error:
	;
	; Free the queue, since there's no thread for it.
	;
		pop	bx
		call	GeodeFreeQueue
	;
	; Clear out the class pointer
	;
		add	sp, 4
	;
	; Return an error, dude.
	;
		stc
		jmp	done
ProcessCreateEventThreadWithOwner	endm

GLoad	ends

; Put this small routine into kcode to avoid swapping in of the entire GLoad
; resource if the system makes frequent use of MSG_PROCESS_CALL_ROUTINE
; (e.g. gpc1apm for battery polling). -- mgroeber 12/03/00

kcode	segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	ProcessCallRoutine -- MSG_PROCESS_CALL_ROUTINE for ProcessClass

DESCRIPTION:	Call a routine

PASS:
	*ds:si - instance data
	es - segment of ProcessClass

	ax - The message

 	ss:bp - ProcessCallRoutineParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/22/93		Initial version

------------------------------------------------------------------------------@
ProcessCallRoutine	method dynamic	ProcessClass, MSG_PROCESS_CALL_ROUTINE

	mov	ax, ss:[bp].PCRP_dataAX
	mov	ss:[TPD_dataAX], ax
	mov	ax, ss:[bp].PCRP_dataBX
	mov	ss:[TPD_dataBX], ax
	mov	cx, ss:[bp].PCRP_dataCX
	mov	dx, ss:[bp].PCRP_dataDX
	mov	si, ss:[bp].PCRP_dataSI
	mov	di, ss:[bp].PCRP_dataDI
	movdw	bxax, ss:[bp].PCRP_address
	GOTO	ProcCallFixedOrMovable

ProcessCallRoutine	endm

kcode	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NewEventThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Simple little startup routine for MSG_PROCESS_CREATE_EVENT_THREAD
		that waits until it's ok to attach to the passed queue
		and does so.

CALLED BY:	ThreadCreate
PASS:		ds,es	= thread's dgroup
		cx	= queue to which to attach
RETURN:		never
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		Block on ss:TPD_callVector until TPD_classPointer is set
		Go to AttachToQueueLow to handle everything else.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewEventThread	proc	far
	;
	; block on semaphore at stackBot until resources properly initialized/
	; class pointer is properly set, then shift stackBot back to its
	; original place.
	;
		mov	bx, ss:[TPD_stackBot]
		sub	bx, size Semaphore
		.warn	-field		; I know, I know...
		PSem	ss, [bx]
		.warn	@field
		mov	ss:[TPD_stackBot], bx
		
		mov	bx, cx
		jmp	AttachToQueueLow
NewEventThread	endp
