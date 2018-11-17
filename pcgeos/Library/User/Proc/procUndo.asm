COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	UI
MODULE:		Proc
FILE:		procUndo.asm

AUTHOR:		Andrew Wilson, Jun  5, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial revision

DESCRIPTION:
	This file contains method handlers and support routines for the
	general undo mechanism.

	$Id: procUndo.asm,v 1.1 97/04/07 11:44:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Undo	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendUndoFreeNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends an undo free notification.

CALLED BY:	GLOBAL
PASS:		ds:di - AddUndoActionStruct
		(ds:di *cannot* be pointing into the movable XIP resource.)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendUndoFreeNotification	proc	near	uses	ax, bx, cx, dx, di, si
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid. In fact, this AddUndoActionStruct
	; is very unlikely to be in XIP code segment.
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dsdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

;	Notify the owner that his precious undo action is being
;	unceremoniously dumped.

;	Copy the AddUndoActionStruct onto the stack

	mov	dx, size AddUndoActionStruct
	sub	sp, dx
	mov	bp, sp

	push	es
	mov	cx, size AddUndoActionStruct/2
	mov	si, di			;DS:SI <- source struct
	segmov	es, ss			;ES:DI <- dest
	mov	di, bp
	rep	movsw
	pop	es
	mov	ax, MSG_META_UNDO_FREEING_ACTION
	movdw	bxsi, ss:[bp].AUAS_output
	call	SendUndoActionStruct
	add	sp, dx
	.leave
	ret
SendUndoFreeNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeUndoActionStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up the data associated with the passed
		AddUndoActionStruct.

CALLED BY:	GLOBAL
PASS:		ds:di - AddUndoActionStruct
		(ds:di *cannot* be pointing into the movable XIP resource.)
		ax - non-zero if freeing after being played back
RETURN:		carry set if end token
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeUndoActionStruct	proc	far	uses	ax
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid. In fact, it is very unlikely to
	; have ds:di pointing to the XIP movable code segment.
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dsdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	cmp	ds:[di].AUAS_data.UAS_dataType, UADT_END_TOKEN
	stc			;If we've reached the end token, stop the
				; enumeration (exit with carry set)
	je	exit
	cmp	ds:[di].AUAS_data.UAS_dataType, UADT_START_TOKEN
	je	continueExit

EC <	test	ds:[di].AUAS_flags, not mask AddUndoActionFlags		>
EC <	ERROR_NZ	BAD_ADD_UNDO_ACTION_FLAGS			>

	test	ds:[di].AUAS_flags, mask AUAF_NOTIFY_BEFORE_FREEING
	jne	doNotify
	test	ds:[di].AUAS_flags, mask AUAF_NOTIFY_IF_FREED_WITHOUT_BEING_PLAYED_BACK
	jz	10$
	tst	ax
	jnz	10$
doNotify:

	call	SendUndoFreeNotification

10$:
	cmp	ds:[di].AUAS_data.UAS_dataType, UADT_PTR
	je	doFree
	cmp	ds:[di].AUAS_data.UAS_dataType, UADT_VM_CHAIN
	jne	continueExit
doFree:
	movdw	axbp, ds:[di].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain

	call	FreeUndoVMChain

continueExit:
	clc
exit:
	.leave
	ret
FreeUndoActionStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeUndoVMChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up a VMChain in the undo file

CALLED BY:	GLOBAL
PASS:		ax.bp - undo chain
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeUndoVMChain	proc	near	uses	bx
	.enter

	mov_tr	bx, ax				;Save old value of ax
	call	GenProcessUndoGetFile
	xchg	bx, ax				;Restore old value of ax,
						; and load bx with file han
	call	VMFreeVMChain

	.leave
	ret
FreeUndoVMChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlushUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up/flushes the current undo chain

CALLED BY:	GLOBAL
PASS:		*ds:si - chunk array of AddUndoActionStruct
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlushUndoChain	proc	near	uses	ax, bx, cx, dx, bp, di, es
	.enter
	clr	ax			;Freeing before played back
	mov	bx, cs
	mov	di, offset FreeUndoActionStruct
	call	ChunkArrayEnum
	call	ChunkArrayZero
	.leave
	ret
FlushUndoChain	endp

if ERROR_CHECK
EnsureObjBlockRunByProcessThread	proc	near	uses	ax, bx
	.enter
	tst	bx							
	jz	exit							
	mov	ax, MGIT_EXEC_THREAD					
	call	MemGetInfo						
	call	GeodeGetProcessHandle					
	call	ProcInfo
	cmp	ax, bx							
	ERROR_NZ	UNDO_OBJECT_MUST_BE_RUN_BY_PROCESS_THREAD	
exit:								
	.leave
	ret
EnsureObjBlockRunByProcessThread	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessUndoStartChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts an undo chain.

CALLED BY:	GLOBAL
PASS:		ss:bp - StartUndoChainStruct
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessUndoStartChain	method	GenProcessClass, 
				MSG_GEN_PROCESS_UNDO_START_CHAIN
	.enter

	segmov	es, dgroup, bx
	call	LockUndoBlockFar	;Returns bx <- handle of LMem block
					;DS - segment of lmem block with undo
					; information
	jz	notIgnoring
	tst	ds:[ULMBH_aborting]
	jz	exit
	inc	ds:[ULMBH_startCount]
EC <	ERROR_Z	UNDO_START_COUNT_OVERFLOW				>
	jmp	exit
notIgnoring:
EC <	cmpdw	ds:[ULMBH_context],NULL_UNDO_CONTEXT			>
EC <	ERROR_Z	MUST_SET_CONTEXT_BEFORE_SENDING_UNDO_MESSAGES		>

	inc	ds:[ULMBH_startCount]
EC <	ERROR_Z	UNDO_START_COUNT_OVERFLOW				>
	cmp	ds:[ULMBH_startCount], 1
	jnz	checkNullTitle

GPUSC_startNewChain label near			;This label is used by swat
ForceRef	GPUSC_startNewChain

if 0
EC <	push	bx, di							>
EC <	mov	ax, MSG_GEN_PROCESS_DO_UNDO_EC				>
EC <	call	GeodeGetProcessHandle					>
EC <	mov	di, mask MF_FORCE_QUEUE					>
EC <	call	ObjMessage						>
EC <	pop	bx, di							>
endif

;	Create a new start item:
;
;	Zero out the current array
;
	call	FlushUndoChain
	clr	ds:[ULMBH_currentChain]
;
;       Add a start token
;
	call	ChunkArrayAppend	;DS:DI <- place for AddUndoActionStruct
	mov	ds:[di].AUAS_data.UAS_dataType, UADT_START_TOKEN
	clr	ds:[di].AUAS_flags
	movdw	ds:[di].AUAS_data.UAS_appType, ss:[bp].SUCS_title, ax
	movdw	ds:[di].AUAS_output, ss:[bp].SUCS_owner, ax
EC <	push	bx,si							>
EC <	movdw	bxsi, ds:[di].AUAS_output				>
EC <	call	ECCheckOD						>
EC <	call	EnsureObjBlockRunByProcessThread			>
EC <	pop	bx,si

exit:
	call	MemUnlock
	Destroy	ax, cx, dx, bp
	.leave
	ret

checkNullTitle:

;	If the title of the chain was null before, cause it to adopt the
;	title of a successive undo chain. This allows something like the
;	grobj body to group undo chains into a higher level undo chain
;	without having to specify a title itself.

	mov	ax, ds:[ULMBH_currentChain]
	call	ChunkArrayElementToPtr
EC <	ERROR_C	-1							>
	tstdw	ds:[di].AUAS_data.UAS_appType		;Check if any title
	jnz	exit					;Branch if so
	movdw	ds:[di].AUAS_data.UAS_appType, ss:[bp].SUCS_title, ax
	jmp	exit
GenProcessUndoStartChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendUndoNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends an undo notification to the edit control

CALLED BY:	GLOBAL
PASS:		cxdx - title
		al - UndoType
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendUndoNotification	proc	near	uses	ax, bx, cx, dx, bp, di, es
	.enter

;	Allocate/fill in the block

	push	cx, dx
	push	ax	
	mov	ax, size NotifyUndoStateChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	pop	ax
	popdw	es:[NUSC_undoTitle]
	mov	es:[NUSC_undoType], al
	call	MemUnlock

;	Send the block off to the appropriate gcn list

	mov	bp, bx
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_UNDO_STATE_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage		;DI <- event handle

	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_EDIT_CONTROL_NOTIFY_UNDO_STATE_CHANGE
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx

	.leave
	ret
SendUndoNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessUndoEndChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ends an undo chain.

CALLED BY:	GLOBAL
PASS:		cx - non-zero if we want to free the chain if empty
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessUndoEndChain	method	GenProcessClass, 
				MSG_GEN_PROCESS_UNDO_END_CHAIN
	.enter

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	segmov	es, dgroup, ax		; SH
	mov_tr	ax, cx			; AX <- freeChainIfEmpty flag
	call	LockUndoBlockFar	; Returns bx <- handle of LMem block
					; DS - segment of lmem block with undo
					;      information

	jz	notIgnoring

;	If we are ignoring actions as a result of an abort, then decrement
;	the startCount. When it reaches zero, turn off "ignore mode"...

	tst	ds:[ULMBH_aborting]		;Exit if not aborting
	jz	toExit
EC <	tst	ds:[ULMBH_startCount]					>
EC <	ERROR_Z	UNDO_START_COUNT_UNDERFLOW				>
	dec	ds:[ULMBH_startCount]		;If chain hasn't ended yet,
	jnz	toExit				; just exit
	clr	ds:[ULMBH_aborting]
	dec	ds:[ULMBH_ignoreCount]		;Else, turn off ignore mode
EC <   	ERROR_NZ IGNORE_COUNT_IS_NON_ZERO_AFTER_END_OF_ABORTED_CHAIN	>
	call	FlushUndoChain
	
toExit:
	jmp	exit	
notIgnoring:

EC <	cmpdw	ds:[ULMBH_context], NULL_UNDO_CONTEXT			>
EC <	ERROR_Z	MUST_SET_CONTEXT_BEFORE_SENDING_UNDO_MESSAGES		>
EC <	tst	ds:[ULMBH_startCount]					>
EC <	ERROR_Z	UNDO_START_COUNT_UNDERFLOW				>

	dec	ds:[ULMBH_startCount]
	jnz	toExit		;Exit if we are not ending the current chain

EC <	cmp	cx, MAX_UNDO_ACTIONS					>
EC <	ERROR_A	TOO_MANY_UNDO_ACTIONS					>

GPUEC_endCurrentChain label near		;Used by swat
	ForceRef	GPUEC_endCurrentChain

;	If only one item in the chain, and the "freeEmptyChain" flag is set,
;	then free up the item.

	cmp	cx, 1
   	ja	noFlush
EC <	ERROR_B	UNDO_INTERNAL_ERROR					>
	tst	ax
	mov	al, UD_UNDO
	jnz	doFlush
noFlush:

;
;       Add an end token to the token chain
;
	call	ChunkArrayAppend	;DS:DI <- place for AddUndoActionStruct
	mov	ds:[di].AUAS_data.UAS_dataType, UADT_END_TOKEN

	clr	ax
	call	ChunkArrayElementToPtr	;DS:DI <- AddUndoActionStruct of 
					; first chain

;	Notify the system that there is an active undo chain

	movdw	cxdx, ds:[di].AUAS_data.UAS_appType	;CX:DX <- title
	mov	al, UD_UNDO
	cmp	ds:[di].AUAS_data.UAS_dataType, UADT_START_TOKEN
	je	sendUndoNotification
EC <	cmp	ds:[di].AUAS_data.UAS_dataType, UADT_REDO_TOKEN		>
EC <	ERROR_NZ	BAD_START_OF_CHAIN_TOKEN			>
	mov	al, UD_REDO
sendUndoNotification:

	call	SendUndoNotification

exit:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock		;Unlock undo chain
	Destroy	ax, cx, dx, bp

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

doFlush:
	call	FlushUndoChain
	clrdw	cxdx
	jmp	sendUndoNotification
GenProcessUndoEndChain	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessUndoAddAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds an undo action to the current undo chain.

CALLED BY:	GLOBAL
PASS:		ds - dgroup
		ss:bp - AddUndoActionStruct
RETURN:		AX.BP - created VMChain/DBItem if UADT_PTR or UADT_VMCHAIN
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessUndoAddAction	method	GenProcessClass,
					MSG_GEN_PROCESS_UNDO_ADD_ACTION
	.enter

EC <	cmp	ss:[bp].AUAS_data.UAS_dataType, UndoActionDataType	>
EC <	ERROR_AE	BAD_UNDO_ACTION_DATA_TYPE			>

EC <	test	ss:[bp].AUAS_flags, not mask AddUndoActionFlags		>
EC <	ERROR_NZ	BAD_ADD_UNDO_ACTION_FLAGS			>

	cmp	ss:[bp].AUAS_data.UAS_dataType, UADT_PTR
	LONG je	handlePtrType

copyData:
	segmov	es, dgroup, bx		; SH
	call	LockUndoBlockFar
	LONG jnz ignoring

EC <	cmpdw	ds:[ULMBH_context], NULL_UNDO_CONTEXT			>
EC <	ERROR_Z	MUST_SET_CONTEXT_BEFORE_SENDING_UNDO_MESSAGES		>

;
;	The # items in the array can exceed MAX_UNDO_ACTIONS:
;	We create a chain, and add a bunch of actions, up to
;	MAX_UNDO_ACTIONS. We end the chain (a total of MAX_UNDO_ACTIONS+1
;	actions). Then, we replay the chain, which adds another action.
;	The app sends MSG_GEN_PROCESS_UNDO_ADD_ACTION, which adds the
;	latest action. So MAX_UNDO_ACTIONS+3 is the true maximum # of
;	undo actions that can ever be in the array.
;	
;

EC <	cmp	cx, MAX_UNDO_ACTIONS+3					>
EC <	ERROR_A	TOO_MANY_UNDO_ACTIONS					>

	cmp	cx, MAX_UNDO_ACTIONS-1
	jb 	insertAction

;
;	If we've added too many actions, this will turn ignore on, and nuke
;	the undo chain when it is ended.
;

	push	bx
	mov	ax, MSG_GEN_PROCESS_UNDO_ABORT_CHAIN
	call	GeodeGetProcessHandle
	clr	di
	call	ObjMessage
	pop	bx

insertAction:

;	Insert this new action at the front of the undo chain.

	mov	ax, ds:[ULMBH_currentChain]
	inc	ax
	call	ChunkArrayElementToPtr
	jc	doAppend			;Branch if no end chain
	call	ChunkArrayInsertAt
copyIt:
	
	segmov	es, ds			;ES:DI <- ptr to dest ActionStruct
	segmov	ds, ss			;DS:SI <- ptr to source ActionStruct
	mov	si, bp			;
	mov	cx, size AddUndoActionStruct/2
	rep	movsw

EC <	push	bx,si							>
EC <	movdw	bxsi, ss:[bp].AUAS_output				>
EC <	call	ECCheckOD						>
EC <	call	EnsureObjBlockRunByProcessThread			>
EC <	pop	bx,si

	movdw	axbp, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain
exit:
	call	MemUnlock
	Destroy	cx, dx
	.leave
	ret
doAppend:
	call	ChunkArrayAppend		;Else, branch
	jmp	copyIt
handlePtrType:

;	They've passed us a ptr to some data - allocate a db item and
;	return it to them.

;	DS:SI <- ptr to  data they want to copy in

	push	es
	lds	si, ss:[bp].AUAS_data.UAS_data.UADU_ptr.UADP_ptr
EC <	call	ECCheckBounds						>

	call	GenProcessUndoGetFile
	mov_tr	bx, ax				; VM file handle => BX

	mov	ax, DB_UNGROUPED
	mov	cx, ss:[bp].AUAS_data.UAS_data.UADU_ptr.UADP_size
	call	DBAlloc

;	Store the allocated ptr to be returned later.

	movdw	ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain, axdi
	call	DBLock
	call	DBDirty

;	Copy the data from the supplied ptr

	mov	di, es:[di]
	shr	cx, 1
	jnc	20$
	movsb
20$:
	rep	movsw
	call	DBUnlock
	pop	es
	jmp	copyData


ignoring:

;	Free up any associated data

	segmov	ds, ss		;DS:DI <- ptr to AddUndoActionStruct
	mov	di, bp
	push	bx
	clr	ax			;Freeing before played back
	call	FreeUndoActionStruct
	pop	bx
	clrdw	axbp
	jmp	exit

GenProcessUndoAddAction	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GENPROCESSUNDOGETFILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the undo file for the current app/context.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - VM file handle
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GENPROCESSUNDOGETFILE	method	GenProcessClass, MSG_GEN_PROCESS_UNDO_GET_FILE
	uses	bx
	.enter	
	call	ClipboardGetClipboardFile
	mov_tr	ax, bx
	.leave
	ret
GENPROCESSUNDOGETFILE	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessUndoFlushActions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine flushes/frees the current undo chain.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessUndoFlushActions	method GenProcessClass,
				MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	.enter

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	segmov	es, dgroup, bx			; SH
	call	LockUndoBlockFar
EC <	pushf								>
EC <	jz	10$							>
EC <	call	ChunkArrayGetCount					>
EC <	tst	cx							>
EC <	WARNING_NZ	UNDO_FLUSH_ACTIONS_IGNORED_IS_THIS_WHAT_YOU_EXPECT>
EC <10$:								>
EC <	popf								>
	jnz	exit			;Exit if ignoring
EC <	tst	ds:[ULMBH_startCount]					>
EC <	ERROR_NZ	FLUSH_SENT_BEFORE_END_OF_UNDO_CHAIN		>

	call	FlushUndoChain

;	Inform the edit control that there is no undo item.

	clrdw	cxdx
	mov	al, UD_UNDO
	call	SendUndoNotification

exit:
	call	MemUnlock

	pop	di
	call	ThreadReturnStackSpace

	Destroy	ax, cx, dx, bp
	.leave
	ret
GenProcessUndoFlushActions	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessUndoGetContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the undo context.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		cx.dx - context
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessUndoGetContext	method	GenProcessClass, 
				MSG_GEN_PROCESS_UNDO_GET_CONTEXT
	.enter
	segmov	es, dgroup, bx			; SH
	call	LockUndoBlockFar
	movdw	cxdx, ds:[ULMBH_context]
	call	MemUnlock
	Destroy	ax, bp
	.leave
	ret
GenProcessUndoGetContext	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlaybackUndoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays back the current undo action

CALLED BY:	GLOBAL
PASS:		ds:di - AddUndoActionStruct
		(ds:di *cannot* be pointing in the movable XIP resource.)
		es - dgroup
RETURN:		carry set if end token
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlaybackUndoAction	proc	far
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dsdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	mov	bx, ds:[di].AUAS_data.UAS_dataType
	cmp	bx, UADT_END_TOKEN
	stc			;If we've reached the end token, stop the
				; enumeration (exit with carry set)
	je	exit
			
	mov	dx, size UndoActionStruct
	sub	sp, dx
	mov	bp, sp		;SS:BP - ptr to UndoActionStruct

	cmp	bx, UADT_REDO_TOKEN
	jae	continueExit	;Exit with carry clear if it is a start token

;	Copy the fields over and exit
	
	mov	ss:[bp].UAS_dataType, bx	;Store data type
EC <	cmp	bx, UndoActionDataType					>
EC <	ERROR_AE	BAD_UNDO_ACTION_DATA_TYPE			>
	movdw	ss:[bp].UAS_appType, ds:[di].AUAS_data.UAS_appType, ax
	movdw	ss:[bp].UAS_data.UADU_flags.UADF_flags, ds:[di].AUAS_data.UAS_data.UADU_flags.UADF_flags, ax
	mov	ax, ds:[di].AUAS_data.UAS_data.UADU_flags.UADF_extraFlags
	mov	ss:[bp].UAS_data.UADU_flags.UADF_extraFlags, ax
	mov	ax, MSG_META_UNDO
	movdw	bxsi, ds:[di].AUAS_output
	call	SendUndoActionStruct

continueExit:
	add	sp, size UndoActionStruct	;Clears carry
exit:
	.leave
	ret
PlaybackUndoAction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendUndoActionStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends an undo action struct, possibly locking/unlocking
		data (if data type is UADT_PTR)

CALLED BY:	GLOBAL
PASS:		ss:bp - ptr to UndoActionStruct
		dx - size of stack frame
		^lbx:si - output
		ax - message to send
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendUndoActionStruct	proc	near
EC <	call	EnsureObjBlockRunByProcessThread			>
   	cmp	ss:[bp].UAS_dataType, UADT_FLAGS
	je	sendUndo

	push	ax
	call	GenProcessUndoGetFile
	mov	ss:[bp].UAS_data.UADU_vmChain.UADVMC_file, ax
	pop	ax

	cmp	ss:[bp].UAS_dataType, UADT_PTR
	je	isPtr

sendUndo:
	mov	di, mask MF_STACK or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage
	ret
	

isPtr:

;	The data type is "ptr", so lock down the db block and pass a ptr
;	instead.

	push	es
	push	ax, bx
	mov	bx, ss:[bp].UAS_data.UADU_vmChain.UADVMC_file
	movdw	axdi, ss:[bp].UAS_data.UADU_vmChain.UADVMC_vmChain
	call	DBLock

;	Extract a pointer to the data

	mov	ax, es:[LMBH_handle]
	movdw	ss:[bp].UAS_data.UADU_optr.UADO_optr, axdi
	mov	ss:[bp].UAS_dataType, UADT_OPTR
	pop	ax, bx
	call	sendUndo
	call	DBUnlock
	pop	es
	ret
SendUndoActionStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessUndoPlaybackChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine plays back the current undo chain.

CALLED BY:	GLOBAL
PASS:		ds - dgroup
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessUndoPlaybackChain	method	GenProcessClass,
				MSG_GEN_PROCESS_UNDO_PLAYBACK_CHAIN
	.enter

	segmov	es, dgroup, bx		; SH
	call	LockUndoBlockFar
	LONG jnz exit			; If ignoring, don't playback	


EC <	tst	ds:[ULMBH_startCount]					>
EC <	ERROR_NZ	UNDO_CHAIN_PLAYED_BACK_BEFORE_ENDED		>

EC <	cmpdw	ds:[ULMBH_context],NULL_UNDO_CONTEXT			>
EC <	ERROR_Z	MUST_SET_CONTEXT_BEFORE_SENDING_UNDO_MESSAGES		>

;
;	Now, we want to playback the current undo chain, and create a
;	new "redo" chain from it.


	call	ChunkArrayGetCount			;CX <- # items
	tst	cx							
EC <	WARNING_Z	MSG_GEN_PROCESS_UNDO_PLAYBACK_CHAIN_SENT_WHEN_NO_CHAIN_EXISTED>
	LONG jz	exit
	push	cx
;
;	First, start a new "redo" chain with the same title, etc as the
;	last chain.
;

;	call	ChunkArrayGetCount
	mov	ds:[ULMBH_currentChain], cx

	call	ChunkArrayAppend		;Append a new start token
	mov	bx, di

	clr	ax				;
	call	ChunkArrayElementToPtr		;DS:DI <- ptr to old starttoken
EC <	ERROR_C NO_UNDO_CHAIN					>

	mov	ax, UADT_START_TOKEN		;AX <- type of the array we
						; are creating (undo or redo)
	cmp	ds:[di].AUAS_data.UAS_dataType, UADT_REDO_TOKEN
	je	10$
	mov	ax, UADT_REDO_TOKEN
EC <	cmp	ds:[di].AUAS_data.UAS_dataType, UADT_START_TOKEN	>
EC <	ERROR_NZ	BAD_START_OF_CHAIN_TOKEN			>
10$:

;	Initialize the new start token

	mov	ds:[bx].AUAS_data.UAS_dataType, ax
	movdw	ds:[bx].AUAS_data.UAS_appType, ds:[di].AUAS_data.UAS_appType,ax
	movdw	ds:[bx].AUAS_output, ds:[di].AUAS_output, ax
	inc	ds:[ULMBH_startCount]

;
;	Playback all the undo elements in the current chain
;

	mov	bx, cs
	mov	di, offset PlaybackUndoAction
	call	ChunkArrayEnum

;
;	Free the undo chain we just played back (this does not affect the
;	redo chain we added in this routine).
;

	mov	ax, TRUE		;Freeing after playback
	mov	bx, cs
	mov	di, offset FreeUndoActionStruct
	call	ChunkArrayEnum
	pop	cx

	clr	ax				;Delete all the actions in the
	call	ChunkArrayDeleteRange		; undo chain we just played
						; back.

;
;	We may have had to abort the redo chain (due to too many items in
;	the queue). If so, MSG_GEN_PROCESS_UNDO_END_CHAIN will clean up
;	for us.
;

EC <	tst	ds:[ULMBH_aborting]					>
EC <	jnz	endChain						>
EC <	tst	ds:[ULMBH_ignoreCount]					>
EC <	ERROR_NZ	IGNORE_COUNT_IS_NON_ZERO_AT_END_OF_PLAYBACK	>
EC <endChain:								>
	clr	ds:[ULMBH_currentChain]		;Now the current undo chain
						; starts at the front

;
;	End the current chain (this notifies the undo control)
;

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	mov	ax, MSG_GEN_PROCESS_UNDO_END_CHAIN
	call	GeodeGetProcessHandle
	clr	di
	call	ObjMessage
exit:
	Destroy	ax, cx, dx, bp
	.leave
	ret
GenProcessUndoPlaybackChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessUndoIgnoreActions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignores undo actions.

CALLED BY:	GLOBAL
PASS:		ds - dgroup
		cx - non-zero to flush undo actions
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessUndoIgnoreActions	method	GenProcessClass,
					MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS
	.enter

	; Flush the current context if needed

	jcxz	noFlush
	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	GeodeGetProcessHandle
	clr	di
	call	ObjMessage
noFlush:
	segmov	es, dgroup, bx			; SH
	call	LockUndoBlockFar
	inc	ds:[ULMBH_ignoreCount]
EC <   	ERROR_Z	IGNORE_COUNT_OVERFLOW					>
	call	MemUnlock

	Destroy	ax, cx, dx, bp
	.leave
	ret
GenProcessUndoIgnoreActions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessUndoAcceptActions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accepts undo actions.

CALLED BY:	GLOBAL
PASS:		ds - dgroup
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessUndoAcceptActions	method	GenProcessClass,
					MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS
	.enter
	segmov	es, dgroup, bx			; SH
	call	LockUndoBlockFar
EC <	tst	ds:[ULMBH_ignoreCount]					>
EC <   	ERROR_Z	IGNORE_COUNT_UNDERFLOW					>
	dec	ds:[ULMBH_ignoreCount]
	call	MemUnlock

	Destroy	ax, cx, dx, bp
	.leave
	ret
GenProcessUndoAcceptActions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GENPROCESSUNDOCHECKIFIGNORING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if we are ignoring or not

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - non-zero if ignoring
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GENPROCESSUNDOCHECKIFIGNORING	method	GenProcessClass, 
				MSG_GEN_PROCESS_UNDO_CHECK_IF_IGNORING
	uses	es, ds, si, bx, cx
	.enter
	mov	ax, segment dgroup
	mov	es, ax

;
;	This causes the undo block to be created, if none was created before.
;	This isn't a problem, because if we are ignoring undo actions, then
;	there will already have been an undo block allocated. If we aren't
;	ignoring undo actions, then the app will most likely be adding an
;	action right after this routine completes, so we're just allocating it
;	a little early.
;

	call	LockUndoBlockFar

;	If the current chain is being aborted, then the ignore count will be
;	non-zero, and will not be decremented to zero until the end chain
;	comes in. It is a common practice (in, say, the text object) to
;	avoid doing start or end chains if undo actions are being ignored.
;	This is a problem, because the text object will start an undo chain,
;	but if that undo chain is aborted, it will never end it.
;
;	Because of this, we do a further check - if we are ignoring, we check
;	if we are aborting the chain, and if the ignore count is "1" - if so,
;	we say that we aren't ignoring, so that the text library will end
;	the undo chain.

	jz	notIgnoring		;Branch to set AX zero if not 
					; ignoring

	mov	ax, BW_TRUE
	tst	ds:[ULMBH_aborting]	;if ignoring but not aborting, just 
	jz	exit			; return AX non-zero
	
	cmp	ds:[ULMBH_ignoreCount], 1 ;If aborting, but the ignore count
	jnz	exit			  ; is not "1", then return that undo
					  ; actions are being ignored.

notIgnoring:
	clr	ax
exit:
	call	MemUnlock
	.leave
	ret

GENPROCESSUNDOCHECKIFIGNORING	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessUndoAbortChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Aborts the current chain.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
	If we are not in the middle of creating a chain
		Flush the current undo chain
		Notify the undo controller that there is nothing to undo

	else (we are in the middle of creating a chain)
		Set a flag saying that we are ignoring actions
		Set a flag saying that we are aborting
		Tell the undo controller that the last action was not
			undoable
		When the current chain is ended, flush the undo actions.
		
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessUndoAbortChain	method	GenProcessClass,
				MSG_GEN_PROCESS_UNDO_ABORT_CHAIN,
				MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	.enter
	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	segmov	es, dgroup, bx		; SH
	call	LockUndoBlockFar
EC <	pushf								>
EC <	jz	10$							>
EC <	tst	cx							>
EC <	WARNING_NZ	UNDO_FLUSH_ACTIONS_OR_ABORT_CHAIN_IGNORED_IS_THIS_WHAT_YOU_EXPECT>
EC <10$:								>
EC <	popf								>
	jnz	exit			;Exit if ignoring

	tst	ds:[ULMBH_startCount]	;
	jnz	inMiddleOfChain		;
EC <	tst	ds:[ULMBH_currentChain]					>
EC <	ERROR_NZ	DOING_PLAYBACK_BUT_NOT_IN_MIDDLE_OF_CHAIN	>

;
;	We are not in the middle of a chain, so flush the undo chain now.
;
	call	FlushUndoChain

	mov	al, UD_UNDO
	jmp	sendNotification

inMiddleOfChain:
;
;	If we are in the middle of creating a chain, we no longer free the 
;	chain immediately (GeoDraw can't deal with the UNDO_ADD_ACTION handler
;	freeing up the action immediately). We do it in the UNDO_END_CHAIN
;	handler.
;	

;	Set things up so we will turn off ignore mode when the current
;	chain is ended.


	mov	ds:[ULMBH_aborting], TRUE
	inc	ds:[ULMBH_ignoreCount]
	mov	al, UD_NOT_UNDOABLE

sendNotification:
	clrdw	cxdx
	call	SendUndoNotification
exit:
	call	MemUnlock		;Unlock the block with undo information
	pop	di
	call	ThreadReturnStackSpace
	Destroy	ax, cx, dx, bp
	.leave
	ret
	
GenProcessUndoAbortChain	endp

if 0
NUKED, BECAUSE GROBJ *DOES* HAVE UNDO CHAINS OPEN - THIS IS OK, BECAUSE THE
UI CANNOT GENERATE A PLAYBACK IN BETWEEN (or so Steve says).

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessDoUndoEC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special EC code.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessDoUndoEC	method	GenProcessClass, MSG_GEN_PROCESS_DO_UNDO_EC
	.enter
if 	ERROR_CHECK
	segmov	es, dgroup, bx			; SH
	call	LockUndoBlockFar
	tst	ds:[ULMBH_startCount]
	ERROR_NZ	UNDO_CHAIN_LEFT_OPEN
	call	MemUnlock
endif
	.leave
	ret
GenProcessDoUndoEC	endp
endif
Undo	ends


Build	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessUndoSetContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the undo context to the passed value.

CALLED BY:	GLOBAL
PASS:		cx.dx - new context value
RETURN:		cx.dx - old context value
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessUndoSetContext	method	GenProcessClass,
					MSG_GEN_PROCESS_UNDO_SET_CONTEXT
	.enter
	segmov	es, dgroup, bx			; SH
	call	LockUndoBlock
	jnz	ignoring
EC <	tst	ds:[ULMBH_startCount]					>
EC <	ERROR_NZ	UNDO_CONTEXT_SWITCHED_BEFORE_END_OF_UNDO_CHAIN	>

	xchgdw	dxcx, ds:[ULMBH_context]
	call	MemUnlock

if 0
	tstdw	dxcx			;If old context was null, don't 
	jz	exit			; flush it.

;	Flush the current context.

	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	GeodeGetProcessHandle
	clr	di
	call	ObjMessage
endif
exit:
	Destroy	ax, bp
	.leave
	ret
ignoring:
	movdw	dxcx, ds:[ULMBH_context]
	call	MemUnlock
	jmp	exit
GenProcessUndoSetContext	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockUndoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine locks the undo block down for the geode. If there
		is none, it creates one.

CALLED BY:	GLOBAL
PASS:		es - dgroup
RETURN:		bx - handle of undo block
		ds - segment of locked block
		zero flag clear if ignore count (or if too many items)
		si - chunk array
		cx - # items in chunk array
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockUndoBlockFar	proc	far
	call	LockUndoBlock
	ret
LockUndoBlockFar	endp


LockUndoBlock	proc	near	uses	ax,di
	.enter

EC <	push	ax, bx							>
EC <	mov	bx, es							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
EC <	pop	ax, bx							>

;	Read the handle of the undo block from our private data area

	clr	bx
	mov	di, es:[undoOffset]
	mov	cx, 1
	sub	sp, 2
	mov	si, sp			;DS:SI <- place to read handle of undo
	segmov	ds, ss			; block
	call	GeodePrivRead
	pop	bx			;BX <- value read

	tst	bx			;If no block created yet, create a 
	jz	createNewUndoBlock	; new one
	call	MemLock
	mov	ds, ax
done:
	mov	si, ds:[ULMBH_actionArray]
	call	ChunkArrayGetCount
	tst	ds:[ULMBH_ignoreCount]
	.leave
	ret

createNewUndoBlock:

;	Allocate a new undo block

	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, size UndoLMemBlockHeader
	call	MemAllocLMem

;	Write the handle of the block out to our private data area

	push	bx
	clr	bx			;Use current process handle
	mov	di, es:[undoOffset]	;DI <- offset to our data
	mov	cx, 1			;CX <- # words to write out
	mov	si, sp			;DS:SI <- ptr to word to write out
	call	GeodePrivWrite
	pop	bx

;	Initialize the state of the block

	call	MemLock
	mov	ds, ax
	clr	ax
	mov	ds:[ULMBH_currentChain], ax
	mov	ds:[ULMBH_startCount], ax
	mov	ds:[ULMBH_ignoreCount], ax
	mov	ds:[ULMBH_aborting], ax
	clrdw	ds:[ULMBH_context], ax

.assert	NULL_UNDO_CONTEXT	eq	0

;	Allocate a chunk array to hold the undo chain

	push	bx
	mov	bx, size AddUndoActionStruct
	clr	cx		;-- No extra data
	clr	si		;-- Create a new chunk
	clr	al		;-- No flags	
	call	ChunkArrayCreate
	mov	ds:[ULMBH_actionArray], si
	pop	bx
	jmp	done
LockUndoBlock	endp


Build	ends
