COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Text library
MODULE:		TextUndo
FILE:		tuMain.asm

AUTHOR:		Andrew Wilson, Jun 16, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/16/92		Initial revision

DESCRIPTION:
	This file contains routines to implement undo for the text object.

	$Id: tuMain.asm,v 1.1 97/04/07 11:22:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if undo is active.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
RETURN:		z flag set if no undo (jz noUndo)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForUndo	proc	near	uses	ax, si
	class	VisTextClass
	.enter
	mov	si, ds:[si]
	add	si, ds:[si].VisText_offset
	test	ds:[si].VTI_features, mask VTF_ALLOW_UNDO
	jz	exit

	call	GenProcessUndoCheckIfIgnoring
	tst	ax
	jnz	ignoring
	or	ax, 1
exit:
	.leave
	ret
ignoring:
	clr	ax			;Set the zero flag
	jmp	exit
CheckForUndo	endp

if 0
CheckForUndoFar	proc	far
	call	CheckForUndo
	ret
CheckForUndoFar	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_NukeCachedUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine nukes the cached undo data for the current object,
		so future undos start a new undo item

CALLED BY:	GLOBAL
PASS:		*ds:si - text object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_NukeCachedUndo	proc	far	uses	bx
	class	VisTextClass
	.enter	
	call	CheckForUndo
	jz	exit

;	Nuke the current undo information

	call	TU_DerefUndo
	clrdw	ds:[bx].VTCUI_vmChain
exit:
	.leave
	ret
TU_NukeCachedUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_StartChainIfUndoable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts a new undo chain

CALLED BY:	GLOBAL
PASS:		ax - chunk handle of undo title
RETURN:		nada
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_StartChainIfUndoable	proc	far
	.enter
	call	CheckForUndo
	jz	exit
	call	TU_StartUndoChain
exit:
	.leave
	ret
TU_StartChainIfUndoable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_EndChainIfUndoable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ends a new undo chain

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nada
DESTROYED:	nothing (flags preserved)
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_EndChainIfUndoable	proc	far
	.enter
	pushf
	call	CheckForUndo
	jz	exit
	call	TU_EndUndoChain
exit:
	popf
	.leave
	ret
TU_EndChainIfUndoable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_AbortChainIfUndoable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Aborts the current undo chain

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada (flags preserved)
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_AbortChainIfUndoable	proc	far
	.enter
	pushf
	call	CheckForUndo
	jz	exit
	call	TU_AbortUndoChain
exit:
	popf
	.leave
	ret
TU_AbortChainIfUndoable	endp


TextFixed	ends

TextUndo	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_DerefUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference the cached undo information.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
RETURN:		ds:bx - ptr to vardata (created if none existed previously)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_DerefUndo	proc	far	uses	ax
	.enter
	mov	ax, TEMP_VIS_TEXT_CACHED_UNDO_INFO
	call	ObjVarFindData
	jnc	create
common:
	.leave
	ret
create:
	push	cx
	mov	cx, size VisTextCachedUndoInfo
	call	ObjVarAddData
	pop	cx
	jmp	common
TU_DerefUndo	endp

if	ERROR_CHECK
TU_DerefVis_DI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	ret
TU_DerefVis_DI	endp
endif	;ERROR_CHECK

VMLockCX	proc	near
	mov	cx, bp
	call	VMLock
	xchg	cx, bp
	ret
VMLockCX	endp
VMUnlockCX	proc	near
	xchg	cx, bp
	call	VMUnlock
	xchg	cx, bp
	ret
VMUnlockCX	endp
VMDirtyCX	proc	near
	xchg	cx, bp
	call	VMDirty
	xchg	cx, bp
	ret
VMDirtyCX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends characters from the text object into the undo action.

CALLED BY:	GLOBAL
PASS:		*ds:si - text object
		es - segment of block containing TextTypingData structure
		DX.AX - offset into text object to get chars
		DI - # chars to get
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendChars	proc	near	uses	cx, di
	.enter		

	mov	cx, di
	mov	di, es:[CRD_charsToInsert].low
DBCS <	shl	di, 1							>
	add	di, offset CRD_chars
	call	CopyCharsFromTextObjectToBuffer
	.leave
	ret
AppendChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCharsFromTextObjectToBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets chars from the text object

CALLED BY:	GLOBAL
PASS:		dx.ax - start of range to get chars
		cx - # chars to get
		es:di - dest for chars
		*ds:si - text object
RETURN:		nada
DESTROYED:	cx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyCharsFromTextObjectToBuffer	proc	near	uses	ax, bx, dx, bp, ds, si
	.enter

;	Set up VisTextRange of text to get

	sub	sp, size VisTextRange
	mov	bx, sp
	movdw	ss:[bx].VTR_start, dxax
	add	ax, cx
	adc	dx, 0
	movdw	ss:[bx].VTR_end, dxax

;	Set up the TextReference

	sub	sp, size TextReference
	mov	bp, sp
	inc	cx				;+1 for NULL
DBCS <	shl	cx, 1							>
	sub	sp, cx
	
	mov	ss:[bp].TR_type, TRT_POINTER
	movdw	ss:[bp].TR_ref.TRU_pointer.TRP_pointer, sssp

;	Get the text out of the text object

	call	TS_GetTextRange

;	Copy the text from our buffer into the text object

	segmov	ds, ss
	mov	si, sp
	push	cx
DBCS <	shr	cx, 1							>
	dec	cx				;-1 for NULL
SBCS <	shr	cx, 1							>
SBCS <	jnc	10$							>
SBCS <	movsb								>
SBCS <10$:								>
	rep	movsw
	pop	cx
	add	sp, cx
	add	sp, size TextReference + VisTextRange
	.leave
	ret
CopyCharsFromTextObjectToBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCharsFromTextObjectToHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets chars from the text object

CALLED BY:	GLOBAL
PASS:		dx.ax - start of range to get chars
		di.cx - # chars to get
		bx - vm file handle to create huge array in
		*ds:si - text object
RETURN:		di - handle of HugeArray
DESTROYED:	cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyCharsFromTextObjectToHugeArray	proc	near	uses	ax, dx, bp, ds, si
	range	local	VisTextRange
	ref	local	TextReference
	.enter

;	Set up VisTextRange of text to get

	movdw	range.VTR_start, dxax
	adddw	dxax, dicx
	movdw	range.VTR_end, dxax

;	Create a huge array to hold this data

	mov	cx, BYTES_PER_CHAR
	clr	di
	call	HugeArrayCreate		;DI <- handle of huge array

;	Set up the TextReference

	mov	ref.TR_type, TRT_HUGE_ARRAY
	mov	ref.TR_ref.TRU_hugeArray.TRHA_file, bx
	mov	ref.TR_ref.TRU_hugeArray.TRHA_array, di

;	Get the text out of the text object

	push	bp
	lea	bx, range
	lea	bp, ref
	call	TS_GetTextRange
	pop	bp

	.leave
	ret
CopyCharsFromTextObjectToHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrependChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepends chars to the passed TextTypingData structure

CALLED BY:	GLOBAL
PASS:		*ds:si - text object
		ES - segment of block containing TextTypingData structure
		DX.AX - offset into text object to get chars
		DI - # chars to get
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrependChars	proc	near	uses	cx, di
	.enter

;	Move the chars that already are in the structure forward, to make room
;	for the new chars

	mov	cx, di
	push	cx
	mov	cx, es:[CRD_charsToInsert].low
	jcxz	skipCopy
	push	ds, si
	segmov	ds, es
if DBCS_PCGEOS
	push	ax
	mov	si, offset CRD_chars-(size wchar)
	mov	ax, es:[CRD_charsToInsert].low
	shl	ax, 1				;AX <- byte offset
	add	si, ax				;DS:SI <- ptr to last char
	shl	di, 1				;DI <- byte offset
	add	di, si				;ES:DI <- ptr to dest for
						; last char
	pop	ax
else
	mov	si, offset CRD_chars-1		;
	add	si, es:[CRD_charsToInsert].low	;DS:SI <- ptr to last char
	add	di, si				;ES:DI <- ptr to dest for
						; last char
endif
	std
	LocalCopyNString
	cld
	pop	ds, si
skipCopy:
	pop	cx

;	Copy the characters in

	mov	di, offset CRD_chars
	call	CopyCharsFromTextObjectToBuffer
	.leave
	ret
PrependChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateCommonReplacementData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a CommonReplacementData structure in a VMBlock

CALLED BY:	GLOBAL
PASS:		ss:bp - VisTextReplaceParameters
		bx - file handle
RETURN:		cx - mem handle of vm block allocated
		ax - vm handle of block allocated
		es - pointing to locked vm block
DESTROYED:	dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateCommonReplacementData	proc	near
	.enter
	movdw	dxcx, ss:[bp].VTRP_range.VTR_end
	subdw	dxcx, ss:[bp].VTRP_range.VTR_start	;DX.CX <- # chars to
							; put in this box
	cmpdw	dxcx, MAX_CHARS_IN_SMALL_STRUCT
	ja	huge

	test	ss:[bp].VTRP_flags, mask VTRF_KEYBOARD_INPUT
	jz	common

;	If this is the beginning of an update-on-the-fly typing undo action,
;	then make sure it has *at least* MAX_CHARS_PER_TYPING_UNDO_ACTION
;	chars.

	cmp	cx, MAX_CHARS_PER_TYPING_UNDO_ACTION
	ja	common
	mov	cx, MAX_CHARS_PER_TYPING_UNDO_ACTION
common:
DBCS <	shl	cx, 1							>
	add	cx, size CommonReplacementData

	clr	ax
	call	VMAlloc
	push	ax				;Save vm handle
	call	VMLockCX
	push	cx				;Save mem handle
	call	VMDirtyCX


	mov	es, ax
	movdw	es:[CRD_charsToDelete], ss:[bp].VTRP_insCount, ax
	movdw	diax, ss:[bp].VTRP_range.VTR_start
	movdw	es:[CRD_insertionPoint], diax


	movdw	dxcx, ss:[bp].VTRP_range.VTR_end
	subdw	dxcx, diax			;CX = # chars we are replacing
	movdw	es:[CRD_charsToInsert], dxcx

	pop	cx				;Restore vm handle
	pop	ax				;Restore mem handle
	.leave
	ret
huge:
	clr	cx		;No extra data to store chars to
	jmp	common
AllocateCommonReplacementData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddVMChainUndoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a VM Chain undo action

CALLED BY:	GLOBAL
PASS:		ax - head block of VMChain
		cx -- AddUndoActionFlags
		bx - low word of AppType
		*ds:si - VisText object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddVMChainUndoAction	proc	near
	.enter
EC <	call	T_AssertIsVisText					>
	mov	dx, size AddUndoActionStruct
	sub	sp, dx
	mov	bp, sp	
	mov	ss:[bp].AUAS_data.UAS_dataType, UADT_VM_CHAIN
	mov	ss:[bp].AUAS_flags, cx
	mov	ss:[bp].AUAS_data.UAS_appType.low, bx
	clr	ss:[bp].AUAS_data.UAS_appType.high
	mov	ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain.high,ax
	clr	ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain.low

	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].AUAS_output.handle, ax
	mov	ss:[bp].AUAS_output.chunk, si

	mov	ax, MSG_GEN_PROCESS_UNDO_ADD_ACTION
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	TU_ObjMessageToProcess
	add	sp, size AddUndoActionStruct
	.leave
	ret
AddVMChainUndoAction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNewReplaceUndoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates and sends off a new replace undo action.

CALLED BY:	TU_DoReplaceUndo
PASS:		*ds:si - object
		ss:bp - VisTextReplaceParameters
		bx - file handle
RETURN:		ax - VM Handle containing TextTypingData structure
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNewReplaceUndoAction	proc	near	uses	bx, cx, es, di, bp
	.enter		

;	Create a CommonReplacementData structure that will hold information to
;	undo this replacement.

	call	AllocateCommonReplacementData
					;Returns CX = locked block handle
					;AX = VM handle
	push	cx, ax
	movdw	dicx, es:[CRD_charsToInsert]	;DICX <- # chars being deleted
	movdw	dxax, ss:[bp].VTRP_range.VTR_start

	cmpdw	dicx, MAX_CHARS_IN_SMALL_STRUCT
	ja	doHuge

;	Copy the chars from the text object to here.

EC <	tst	di							>
EC <	ERROR_NZ	-1						>
	mov	di, offset CRD_chars		;ES:DI <- dest for chars
	call	CopyCharsFromTextObjectToBuffer
	clr	di
	mov	bx, TUT_SMALL_REPLACEMENT_CHARS
	jmp	common
doHuge:
	call	CopyCharsFromTextObjectToHugeArray
	mov	bx, TUT_LARGE_REPLACEMENT_CHARS

common:
	mov	es:[VMCL_next], di
	pop	cx,ax
	call	VMUnlockCX


;	Send this undo action off

	clr	cx
	test	ss:[bp].VTRP_flags, mask VTRF_KEYBOARD_INPUT
	jz	20$
	mov	cx, mask AUAF_NOTIFY_BEFORE_FREEING
20$:
	call	AddVMChainUndoAction
	.leave
	ret

CreateNewReplaceUndoAction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetUndoFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the undo file for the app.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		bx - undo file
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetUndoFile	proc	near	
	.enter
	mov_tr	bx, ax				;BX <- old ax value
	call	GenProcessUndoGetFile
	xchg	ax, bx				;AX <- old ax value
						;BX <- file handle
	.leave
	ret
GetUndoFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_DoReplaceUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine creates an undo action for the passed 
		VisTextReplaceParameters.

CALLED BY:	GLOBAL
PASS:		*ds:si - text object
		ss:bp - VisTextReplaceParameters
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_DoReplaceUndo	proc	far	uses	ax, bx, cx, dx, di
	class	VisTextClass
	.enter	
EC <	call	TU_DerefVis_DI						>
EC <	test	ds:[di].VTI_features, mask VTF_ALLOW_UNDO		>
EC <	ERROR_Z	UNDO_NOT_TURNED_ON					>

EC <	call	GenProcessUndoCheckIfIgnoring				>
EC <	tst	ax							>
EC <	ERROR_NZ	UNDO_RESOURCE_LOADED_EVEN_THOUGH_IGNORING_UNDO	>

;	If this replace is generated from keyboard input, and there is already
;	a cached replace item, just update it

	test	ss:[bp].VTRP_flags, mask VTRF_KEYBOARD_INPUT
	jz	createNewAction
	call	TU_DerefUndo
	mov	ax, ds:[bx].VTCUI_vmChain.high
	tst	ax
	jnz	updateCurrentAction
createNewAction:
	call	GetUndoFile			;bx = undo file

	call	CreateNewReplaceUndoAction	;Returns undo VM handle in AX

;	Store the handle of the undo item

	mov	di, bx
	call	TU_DerefUndo

	clrdw	ds:[bx].VTCUI_vmChain
	test	ss:[bp].VTRP_flags, mask VTRF_KEYBOARD_INPUT
	jz	exit
	mov	ds:[bx].VTCUI_vmChain.high, ax
	mov	ds:[bx].VTCUI_file, di
exit:
	.leave
	ret
updateCurrentAction:

;	We already have a current typing action. Try to modify it rather than
;	creating a new one.

	mov	bx, ds:[bx].VTCUI_file
	call	VMLockCX
	mov	es, ax
	movdw	dxax, ss:[bp].VTRP_range.VTR_end	;DX.AX <- # chars in
	subdw	dxax, ss:[bp].VTRP_range.VTR_start	; range being modified

	tst	dx
	jnz	tooLarge

;	If deleting these characters will push the number of chars to delete
;	in this action beyond the limit, just create a new one.

	mov	di, ax			;DI <- # chars in replace range
	tst	di
	LONG jz	afterDelete

	tst	es:[CRD_charsToInsert].high
	jnz	tooLarge

	movdw	dxax, es:[CRD_insertionPoint]
	adddw	dxax, es:[CRD_charsToDelete]	;DX.AX = current cursor 
						; position
	cmpdw	ss:[bp].VTRP_range.VTR_start, dxax
	jb	deletingBackward
EC <	cmpdw	ss:[bp].VTRP_range.VTR_start, dxax			>
EC <	ERROR_NZ	CANNOT_UPDATE_TYPING_UNDO_ACTION		>

;
;	We are deleting forward DI chars
;
;	Adjust the # chars we need to insert to undo this replacement,
;	and append the chars to insert to the CRD_chars array
;

	add	di, es:[CRD_charsToInsert].low	;If there are too many chars
	jc	tooLarge			; to delete, branch to create
						; a new item
	cmp	di, MAX_CHARS_PER_TYPING_UNDO_ACTION
	ja	tooLarge			
	sub	di, es:[CRD_charsToInsert].low

	call	AppendChars
	add	es:[CRD_charsToInsert].low, di
	jmp	afterDelete

tooLarge:

;	We are deleting too many characters in this replace to keep in the
;	current undo action, so jump back to create a new one.

	call	VMUnlockCX		;Unlock the undo action
	jmp	createNewAction
	
deletingBackward:
EC <	cmpdw	ss:[bp].VTRP_range.VTR_end, dxax			>
EC <	ERROR_NZ	CANNOT_UPDATE_TYPING_UNDO_ACTION		>

;	They are deleting backward DI chars.
;
;	if DI <= CRD_charsToDelete
;		CRD_charsToDelete = CRD_charsToDelete - DI
;
;	else if DI > CRD_charsToDelete
;		CRD_charsToInsert = CRD_charsToInsert+(DI - CRD_charsToDelete)
;		CRD_insertionPoint = CRD_insertionPoint-(DI-CRD_charsToDelete)
;		<prepend chars being deleted to CRD_chars array>
;		CRD_charsToDelete = 0


;	Ensure that the chars we will be deleting will fit in this string

	cmp	di, es:[CRD_charsToDelete].low
	jb	deleteInThisItem
	tst	es:[CRD_charsToDelete].high
	jne	deleteInThisItem
	mov	ax, di
	sub	di, es:[CRD_charsToDelete].low
	add	di, es:[CRD_charsToInsert].low
	jc	tooLarge
	cmp	di, MAX_CHARS_PER_TYPING_UNDO_ACTION
	ja	tooLarge
	mov_tr	di, ax
deleteInThisItem:
	sub	es:[CRD_charsToDelete].low, di	;If we are just deleting chars
	sbb	es:[CRD_charsToDelete].high, 0	; we just entered, branch
	jnc	afterDelete			; 

	mov	di, es:[CRD_charsToDelete].low
	neg	di				;DI = DI-CRD_charsToDelete
	clrdw	es:[CRD_charsToDelete]
	sub	es:[CRD_insertionPoint].low, di
	sbb	es:[CRD_insertionPoint].high, 0
	movdw	dxax, es:[CRD_insertionPoint]	
	call	PrependChars
	add	es:[CRD_charsToInsert].low, di

afterDelete:
	adddw	es:[CRD_charsToDelete], ss:[bp].VTRP_insCount, ax
	call	VMDirtyCX
	call	VMUnlockCX
	jmp	exit

TU_DoReplaceUndo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextUndoFreeingAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method handler for MSG_META_UNDO_FREEING_ACTION - if the action
		being freed is the current typing undo action, then nuke the
		cached info, so we will create a new undo action when it is
		freed.

CALLED BY:	GLOBAL
PASS:		ss:bp - AddUndoActionStruct
RETURN:		nada
DESTROYED:	ax,cx,dx,bp, 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextUndoFreeingAction	proc	far	;MSG_META_UNDO_FREEING_ACTION
	.enter
	mov	bx, ss:[bp].AUAS_data.UAS_appType.low
EC <	cmp	bx, TextUndoType					>
EC <	ERROR_AE	BAD_TEXT_UNDO_TYPE				>
	shl	bx, 1
	call	cs:[freeUndoHandlers][bx]
	.leave
	ret
VisTextUndoFreeingAction	endp
freeUndoHandlers	nptr	FreeTypingUndo, FreeTypingUndo, Death, FreeRunsUndo

.assert 	(length freeUndoHandlers) eq TextUndoType

Death	proc	near
EC <	ERROR	BAD_TEXT_UNDO_TYPE					>
NEC <	ret								>
Death	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeRunsUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When an undo action containing runs is deleted, we dec
		the reference count for the associated elements.

CALLED BY:	GLOBAL
PASS:		ss:bp - AddUndoActionStruct
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeRunsUndo	proc	near
	.enter
	mov	bx, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_file
	mov	di, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain.high

;	Get our data from the huge array directory block

	push	ds
	call	HugeArrayLockDir
	mov	ds, ax	
	mov	dx, ds:[RHAD_runOffset]
	call	HugeArrayUnlockDir
	pop	ds

	call	TA_DecrementRefCountsFromHugeArray
	.leave
	ret
FreeRunsUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeTypingUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When a typing undo action is freed, this nukes the cached
		typing undo information, so we don't try to update it.

CALLED BY:	GLOBAL
PASS:		ss:bp - AddUndoActionStruct
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeTypingUndo	proc	near
	.enter

	call	TU_DerefUndo
	cmpdw	ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain, ds:[bx].VTCUI_vmChain,ax
	jne	exit
	clrdw	ds:[bx].VTCUI_vmChain
exit:
	.leave
	ret
FreeTypingUndo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Contains data for doing undo.

CALLED BY:	GLOBAL
PASS:		ss:bp - UndoActionStruct
RETURN:		nada
DESTROYED:	ax,cx, dx,bp, 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextUndo	proc	far		;MSG_META_UNDO
	class	VisTextClass
	.enter

;	Set DI as a flag to tell if we are suspended or not:
;	DI = 0 if suspended already
;	DI = non-zero if not suspended (so we have to generate our own
;		suspend)
;

EC <	test	ds:[di].VTI_features, mask VTF_ALLOW_UNDO		>
EC <	ERROR_Z	UNDO_NOT_TURNED_ON					>

	test	ds:[di].VTI_intFlags, mask VTIF_SUSPENDED
	mov	di,0
	jnz	noSuspend

	mov	di, -1
	call	TextSuspend

noSuspend:
	;
	; Abort any active search/spell sessions.
	;
	call	SendAbortSearchSpellNotification

	mov	bx, ss:[bp].AUAS_data.UAS_appType.low
EC <	cmp	bx, TextUndoType					>
EC <	ERROR_AE	BAD_TEXT_UNDO_TYPE				>

	shl	bx, 1
	push	di
	call	cs:[undoHandlers][bx]
	pop	di
	tst	di
	jz	noUnSuspend
	mov	ax, MSG_META_UNSUSPEND
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
noUnSuspend:
	.leave
	ret
VisTextUndo	endp

undoHandlers	nptr	SmallReplaceUndo, LargeReplaceUndo, DeleteRunsUndo, RestoreRunsUndo
.assert 	(length undoHandlers) eq TextUndoType



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallReplaceUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undoes a small replace.

CALLED BY:	GLOBAL
PASS:		ss:bp - UndoActionStruct
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp
 
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallReplaceUndo	proc	near
	.enter
	mov	ax, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain.high
	mov	bx, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_file
	call	VMLockCX

	push	cx
	mov	es, ax			;ES = SmallReplacementData

;	Setup a replace call

	sub	sp, size VisTextReplaceParameters
	mov	bp, sp
	movdw	dxax, es:[CRD_insertionPoint]
	movdw	ss:[bp].VTRP_range.VTR_start, dxax
	adddw	dxax, es:[CRD_charsToDelete]
	movdw	ss:[bp].VTRP_range.VTR_end, dxax
	movdw	ss:[bp].VTRP_insCount, es:[CRD_charsToInsert], ax
	mov	ss:[bp].VTRP_flags, mask VTRF_USER_MODIFICATION or mask VTRF_UNDO
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	mov	ss:[bp].VTRP_pointerReference.segment, es
	mov	ss:[bp].VTRP_pointerReference.offset, offset CRD_chars

SRU_beforeReplaceText label near    ;THIS LABEL USED BY SWAT		
ForceRef	SRU_beforeReplaceText

	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock
	add	sp, size VisTextReplaceParameters

	pop	cx
	call	VMUnlockCX
	.leave
	ret
SmallReplaceUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeReplaceUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undoes a large replace.

CALLED BY:	GLOBAL
PASS:		ss:bp - UndoActionStruct
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeReplaceUndo	proc	near
	.enter
	mov	ax, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain.high
	mov	bx, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_file
	call	VMLockCX

	push	cx
	mov	es, ax			;ES = LargeReplacementData

;	Setup a replace call

	sub	sp, size VisTextReplaceParameters
	mov	bp, sp
	movdw	dxax, es:[CRD_insertionPoint]
	movdw	ss:[bp].VTRP_range.VTR_start, dxax
	adddw	dxax, es:[CRD_charsToDelete]
	movdw	ss:[bp].VTRP_range.VTR_end, dxax
	movdw	ss:[bp].VTRP_insCount, es:[CRD_charsToInsert], ax
	mov	ss:[bp].VTRP_flags, mask VTRF_USER_MODIFICATION or mask VTRF_UNDO
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_HUGE_ARRAY
	mov	ss:[bp].VTRP_textReference.TR_ref.TRU_hugeArray.TRHA_file, bx
	mov	ax, es:[VMCL_next]
	mov	ss:[bp].VTRP_textReference.TR_ref.TRU_hugeArray.TRHA_array, ax
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock
	add	sp, size VisTextReplaceParameters

	pop	cx
	call	VMUnlockCX
	.leave
	ret
LargeReplaceUndo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteRunsUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a series of runs.

CALLED BY:	GLOBAL
PASS:		ss:bp - UndoActionStruct
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteRunsUndo	proc	near	
	.enter
	mov	ax, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain.high
	mov	bx, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_file
	call	VMLock
	mov	es, ax			;ES - ptr to DeleteRunsData
	mov	cx, es:[DRD_runOffset]
	pushdw	es:[DRD_range].VTR_end
	pushdw	es:[DRD_range].VTR_start
	call	VMUnlock

;	Delete the runs in the range

	mov	bp, sp
	call	TA_DeleteRunsInRange
	add	sp, size VisTextRange	
	.leave
	ret
DeleteRunsUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreRunsUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undoes a run change.

CALLED BY:	GLOBAL
PASS:		ss:bp - UndoActionStruct
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreRunsUndo	proc	near	
	.enter

	mov	di, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain.high
	mov	bx, ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_file

	push	ds
	call	HugeArrayLockDir
	mov	ds, ax
	mov	cx, ds:[RHAD_runOffset]
	call	HugeArrayUnlockDir
	pop	ds

EC <	call	ECCheckRunOffset					>
	call	TA_RestoreRunsFromHugeArray
	.leave
	ret
RestoreRunsUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_IgnoreUndoActions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the process to stop accepting undo actions.

CALLED BY:	GLOBAL
PASS:		cx	= non-zero to flush queue
RETURN:		nothing
DESTROYED:	bx, cx, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_IgnoreUndoActions	proc	far
		uses	ax
		.enter

		mov	ax, MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS
		call	TU_ObjMessageCallProcess

		.leave
		ret
TU_IgnoreUndoActions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_AcceptUndoActions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the process to start accepting undo actions again.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_AcceptUndoActions	proc	far
		mov	ax, MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS
		call	TU_ObjMessageCallProcess
		ret
TU_AcceptUndoActions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_ObjMessageCallProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the process with MF_CALL. 

CALLED BY:	INTERNAL	TU_IgnoreUndoActions
				TU_AcceptUndoActions
PASS:		ax	= message
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_ObjMessageCallProcess	proc	near
		uses	bp
		.enter

		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	TU_ObjMessageToProcess

		.leave
		ret
TU_ObjMessageCallProcess	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_ObjMessageToProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the process.

CALLED BY:	INTERNAL
PASS:		ax	= message
		di	= MessageFlags
RETURN:		whatever message returns
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_ObjMessageToProcess	proc	near
		call	GeodeGetProcessHandle
		call	ObjMessage
		ret
TU_ObjMessageToProcess	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_StartUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts the undo chain

CALLED BY:	GLOBAL
PASS:		ax - chunk handle of undo chain title (or 0 if none)
		*ds:si - VisText object
RETURN:		nada
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_StartUndoChain	proc	far
	.enter
	call	StartChain

;	If the text object is currently suspended, create a "wraparound"
;	undo chain, so all undo actions while the object is suspended will
;	be grouped together.

	mov	ax, TEMP_VIS_TEXT_UNDO_FOR_SUSPEND
	call	ObjVarDeleteData
	jc	exit

	clr	ax
	call	StartChain
exit:
	.leave
	ret
TU_StartUndoChain	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts an undo chain

CALLED BY:	GLOBAL
PASS:		ax - chunk handle of undo chain title (or 0 if none)
		*ds:si - VisText object
RETURN:		nada
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartChain	proc	far 	uses	bx, dx, bp, di
	.enter

EC <	call	T_AssertIsVisText					>

	mov	dx, size StartUndoChainStruct
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].SUCS_title.chunk, ax

;	If we don't want a title, set the title to 0:0
;	If the title is 0, then the undo chain will inherit the title of
;		the next StartUndoChain call.

	tst	ax
	jz	10$
	mov	ax, handle UndoStrings
10$:
	mov	ss:[bp].SUCS_title.handle, ax
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[bp].SUCS_owner, axsi
	mov	ax, MSG_GEN_PROCESS_UNDO_START_CHAIN
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	TU_ObjMessageToProcess
	add	sp, dx
	.leave
	ret
StartChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_EndUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End the current undo chain

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_EndUndoChain	proc	far	uses	cx
	.enter
	mov	cx, -1
;	Pass CX non-zero, because in general, we don't want to allow
;	empty chains hanging around.

	call	EndChainCommon

	.leave
	ret
TU_EndUndoChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndChainCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ends an undo chain.

CALLED BY:	GLOBAL
PASS:		cx - non-zero if the chain should be deleted if empty
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EndChainCommon	proc	near	uses ax, bx, di

	.enter

	mov	ax, MSG_GEN_PROCESS_UNDO_END_CHAIN
	mov	di, mask MF_FIXUP_DS
	call	TU_ObjMessageToProcess
	.leave
	ret
EndChainCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_AbortUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Abort the current undo chain

CALLED BY:	GLOBAL
PASS:		ds - segment of lmem resource
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_AbortUndoChain	proc	far	uses	ax, bx, di
	.enter

	mov	ax, MSG_GEN_PROCESS_UNDO_ABORT_CHAIN
	mov	di, mask MF_FIXUP_DS
	call	TU_ObjMessageToProcess
	.leave
	ret
TU_AbortUndoChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_CreateEmptyChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a chain with no items (except for the
		TUT_END item)

CALLED BY:	GLOBAL
PASS:		ax - chunk handle of undo chain title
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_CreateEmptyChain	proc	far
	call	TU_StartUndoChain
	push	cx
	clr	cx			;Don't delete this empty chain, let
					; it hang around, so we can insert
					; actions in it later on (we do this
					; when generating undo chains for
					; user input/typing).	
	call	EndChainCommon
	pop	cx
	ret
TU_CreateEmptyChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_CreateUndoForRunsInRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an undo action for this run.

CALLED BY:	GLOBAL
PASS:		ss:bx - VisTextReplaceParameters
		cx - run offset
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
		For each TextRunArrayElement in the deletion range:
			Inc the reference count for the associated token
			Copy the TextRunArrayElement to the huge array

		Add the huge array as an undo action

		When the item is freed,
			For each TextRunArrayElement in the huge array:
				Dec the reference count
				


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_CreateUndoForRunsInRange	proc	far	uses	ax, bx, cx, dx, di, bp
	.enter

EC <	call	T_AssertIsVisText					>
EC <	call	ECCheckRunOffset					>

EC <	call	GenProcessUndoCheckIfIgnoring				>
EC <	tst	ax							>
EC <	ERROR_NZ	UNDO_RESOURCE_LOADED_EVEN_THOUGH_IGNORING_UNDO	>

	mov	bp, bx			;SS:BP <- VisTextReplaceParams

;	Create a huge array to store the data in

	push	cx			;Save runOffset
	call	GetUndoFile		;bx = undo file

	mov	cx, size TextRunArrayElement
	mov	di, size RunHAD
					;Store the "runOffset" with the huge
	call	HugeArrayCreate		; array
	pop	cx

	push	ds
	call	HugeArrayLockDir
	mov	ds, ax
	mov	ds:[RHAD_runOffset], cx
	call	HugeArrayDirty
	call	HugeArrayUnlockDir
	pop	ds			;*DS:SI <- VisText object

;	Add the runs to the huge array

	call	TA_AppendRunsInRangeToHugeArray	;

;	Add the action

	mov_tr	ax, di			;AX <- VM Chain
	mov	cx, mask AUAF_NOTIFY_BEFORE_FREEING
	mov	bx, TUT_SAVED_RUNS
	call	AddVMChainUndoAction

	call	TU_NukeCachedUndo
	.leave
	ret
TU_CreateUndoForRunsInRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TU_CreateUndoForRunModification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates an undo item

CALLED BY:	GLOBAL
PASS:		ss:bp - VisTextRange
		cx - run offset
		*ds:si - VisText object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TU_CreateUndoForRunModification	proc	far	uses	ax, bx, cx, dx, bp, di, es
	.enter
EC <	call	T_AssertIsVisText					>
EC <	call	ECCheckRunOffset					>

EC <	call	GenProcessUndoCheckIfIgnoring				>
EC <	tst	ax							>
EC <	ERROR_NZ	UNDO_RESOURCE_LOADED_EVEN_THOUGH_IGNORING_UNDO	>


;	Create a VM chain containing the data for deleting this run range 

	call	GetUndoFile			;bx = undo file
	mov	di, cx				;DI <- run offset
	clr	ax
	mov	cx, size DeleteRunsData
	call	VMAlloc
	push	ax				;Save vm handle
	call	VMLockCX
	call	VMDirtyCX
	mov	es, ax
	clr	es:[DRD_meta].VMCL_next		;This is the only block in the
						; chain.
	mov	es:[DRD_runOffset], di		;Store the run offset/range
	movdw	es:[DRD_range].VTR_start, ss:[bp].VTR_start, di
	movdw	es:[DRD_range].VTR_end, ss:[bp].VTR_end, di
	call	VMUnlockCX
	pop	ax

;	Add the VM Chain to the current undo chain.

	push	bx
	clr	cx
	mov	bx, TUT_DELETE_RUNS_IN_RANGE
	call	AddVMChainUndoAction
	pop	bx
	.leave
	ret
TU_CreateUndoForRunModification	endp

TextUndo	ends
