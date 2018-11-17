COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextAttr
FILE:		taRunLow.asm

ROUTINES:

	Name			Description
	----			-----------
   EXT	GetTokenForPosition
   EXT	GetTokenForPositionLeft

   EXT	GetRunForPosition
   EXT	GetRunForPositionLeft
   EXT	GetGraphicRunForPosition

   EXT	RunArrayLock
   EXT	RunArrayUnlock

   EXT	RunArrayInsert
   EXT	RunArrayDelete

   EXT	RunArrayNext
   EXT	RunArrayPrevious

   EXT	RunArrayMarkDirty

   EXT	RunArrayUnref (commented out)
   EXT	RunArrayReref (commented out)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

DESCRIPTION:

This file contains the internal routines that directly look at the structure
of the run array.  All code that depends on whether the run array is local or
in a huge array is here.

	$Id: taRunLow.asm,v 1.1 97/04/07 11:18:34 newdeal Exp $

------------------------------------------------------------------------------@

TextAttributes segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_AddGraphicAndRun

DESCRIPTION:	Add a graphic to the graphic array and a run for it to the
		object

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	dxax - position to add run
	ss:bp - graphic
	bx - source file

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/25/92		Initial version

------------------------------------------------------------------------------@

TextGraphic segment resource

TA_AddGraphicAndRun	proc	near
	class	VisTextClass
	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	test	ds:[di].VTI_features, mask VTF_ALLOW_UNDO
	jz	noUndo
	push	ax
	call	GenProcessUndoCheckIfIgnoring	;Don't create any actions if
	tst	ax				; ignoring undo
	pop	ax
	jnz	noUndo

;	Add an undo item to delete this run

	push	bp
	sub	sp, size VisTextRange
	mov	bp, sp
	movdw	ss:[bp].VTR_start, dxax
	movdw	ss:[bp].VTR_end, dxax
	mov	cx, OFFSET_FOR_GRAPHIC_RUNS
	call	TU_CreateUndoForRunModification
	add	sp, size VisTextRange
	pop	bp

noUndo:
	push	si, ds:[LMBH_handle]
	pushdw	dxax				;save position

	push	bx				;save source file
	call	T_GetVMFile			; bx = VM file (dest)
	push	bx
	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	call	GetGraphicRunForPosition

	pop	bx				;bx = dest file
	pop	dx				;dx = source file
	call	AddGraphicElement

	popdw	dxax
	call	FarRunArrayInsert
	call	RemoveElement			;remove our extra reference
	call	FarRunArrayUnlock
	pop	si, bx
	call	MemDerefDS

	ret

TA_AddGraphicAndRun	endp

TextGraphic ends

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetTokenForPosition

DESCRIPTION:	Given a position, find the corresponding token

	NOTE:	There is a subtle but very important different question of
		what to do at the edge of a run.  GetTokenForPosition returns
		the run to the RIGHT.  GetTokenForPositionLeft returns the
		run to the LEFT.

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset of run
	dx.ax - position

RETURN:
	dx.ax - position of run
	bx - token for run
	cx - number of consecutive elements

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/91		Initial version

------------------------------------------------------------------------------@
if 0
GetTokenForPositionLeft	proc	near
	push	si, di, ds

	call	GetRunForPositionLeft

	GOTO	GetTokenForPositionCommon, ds, di, si

GetTokenForPositionLeft	endp
;---

GetTokenForPosition	proc	near
	push	si, di, ds

	call	GetRunForPosition

	FALL_THRU	GetTokenForPositionCommon, ds, di, si

GetTokenForPosition	endp

;---

GetTokenForPositionCommon	proc	near
	call	RunArrayUnlock

	FALL_THRU_POP	ds, di, si
	ret

GetTokenForPositionCommon	endp
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetRunForPosition

DESCRIPTION:	Given a position, find the corresponding run

	NOTE:	There is a subtle but very important different question of
		what to do at the edge of a run.  GetRunForPosition returns the
		run to the RIGHT.  GetRunForPositionLeft returns the run to
		the LEFT.

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset of run
	dx.ax - position

RETURN:
	dx.ax - position of run
	bx - token for run
	cx - number of consecutive elements
	ds:si - run element (locked)
	di - run token (to pass to other RunArray routines)
	** UnlockRun() must be called after processing **

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

GRPFlags	record
    GRPF_RETURN_PREV_IF_EXACT_MATCH:1		;otherwise return match
    GRPF_RETURN_RIGHT_IF_IN_MIDDLE:1		;otherwise return left
    GRPF_PAST_BEGINNING:1
GRPFlags	end

;---

FarGetRunForPositionLeft	proc	far
	call	GetRunForPositionLeft
	ret
FarGetRunForPositionLeft	endp

GetRunForPositionLeft	proc	near
	mov	dh, mask GRPF_RETURN_PREV_IF_EXACT_MATCH
	GOTO	GetRunForPositionCommon

GetRunForPositionLeft	endp

;---

GetGraphicRunForPositionLeft	proc	far
	clr	dh
	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	call	GetRunForPositionCommon
	ret
GetGraphicRunForPositionLeft	endp

;---

GetGraphicRunForPosition	proc	far
	mov	dh, mask GRPF_RETURN_RIGHT_IF_IN_MIDDLE
	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	call	GetRunForPositionCommon
	ret
GetGraphicRunForPosition	endp

;---

FarGetRunForPosition	proc	far
	call	GetRunForPosition
	ret
FarGetRunForPosition	endp

GetRunForPosition	proc	near
	clr	dh
	FALL_THRU	GetRunForPositionCommon

GetRunForPosition	endp

;---

	; dl = 0 for right, -1 for left, 1 for graphics

GetRunForPositionCommon	proc	near	uses	bp
	.enter

	call	RunArrayLock			;ds:si = run, cx = count

topLoopReloadBP:
	mov	bp, cx				;bp = # consecutive

topLoop:
	cmp	dl, ds:[si].TRAE_position.WAAH_high
	jnz	10$
	cmp	ax, ds:[si].TRAE_position.WAAH_low
10$:
	jb	inMiddle
	jz	exactMatch

	ornf	dh, mask GRPF_PAST_BEGINNING
	add	si, size TextRunArrayElement
	loop	topLoop

	xchg	ax, cx				;huge array code uses ax
	push	dx
	sub	si, size TextRunArrayElement
	call	HugeArrayNext			;for count
	pop	dx
	xchg	ax, cx
	jmp	topLoopReloadBP

	; run is at position passed

exactMatch:
	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH	;if the position being looked
	jz	inMiddle			;for is T_A_P_E then treat this
						;as being in the middle
	test	dh, mask GRPF_RETURN_PREV_IF_EXACT_MATCH
	jz	useThis
	jmp	useLast

inMiddle:

	test	dh, mask GRPF_RETURN_RIGHT_IF_IN_MIDDLE
	jnz	useThis

	; run found and we are one past the right one

useLast:
	test	dh, mask GRPF_PAST_BEGINNING
	jz	useThis

	; we need to move back one element, but we could be at the first
	; element in a huge array block

	cmp	cx, bp
	jnz	notArrayFirst
	call	RunArrayPrevious
	jmp	useThis

notArrayFirst:
	inc	cx
	sub	si,size TextRunArrayElement

useThis:
	call	LoadRegsFromRun

	.leave
	ret

GetRunForPositionCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RunArrayInsert

DESCRIPTION:	Insert a run in a locked run array

CALLED BY:	INTERNAL

PASS:
	ds:si - run element to insert before
	di - run element token (chunk or header)
	dx.ax - position to insert at
	bx - token

RETURN:
	ds:si - pointing at inserted token
	cx - # of consecutive elements at ds:si

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/91		Initial version

------------------------------------------------------------------------------@
FarRunArrayInsert	proc	far
	call	RunArrayInsert
	ret
FarRunArrayInsert	endp

RunArrayInsert	proc	near
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jz	lmem

	; insert in a huge array

	push	ax, bp
	mov	cx, 1
	clr	bp				;no data
	call	HugeArrayExpand
	mov_tr	cx, ax
	pop	ax, bp
	jmp	common

	; insert in an lmem chunk

lmem:
	push	ax, bx, cx
	mov	ax, di				;chunk
	mov	bx, si
	sub	bx, ds:[di]			;offset in chunk
	mov	cx, size TextRunArrayElement	;size
	call	LMemInsertAt

	; recalculate the index

	mov	si, ds:[di]
	inc	ds:[si].TRAH_meta.CAH_count
	add	si, bx				;ds:si = element
	pop	ax, bx, cx

common:
	mov	ds:[si].TRAE_token, bx
	mov	ds:[si].TRAE_position.WAAH_low, ax
	mov	ds:[si].TRAE_position.WAAH_high, dl

	call	ElementAddRef

	ret

RunArrayInsert	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RunArrayDelete

DESCRIPTION:	Delete a run in a locked run array

CALLED BY:	INTERNAL

PASS:
	ds:si - run element to delete
	di - run element token (chunk or header)
	cx - # of consecutive elements at ds:si
	bx - VM file handle

RETURN:
	ds:si - pointing at inserted token
	bx - token removed (is this even used ???)
	cx - # of consecutive elements at ds:si

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/91		Initial version

------------------------------------------------------------------------------@
FarRunArrayDeleteNoElement	proc	far
	call	RunArrayDeleteNoElement
	ret
FarRunArrayDeleteNoElement	endp

RunArrayDelete	proc	near

	; first remove the token

	push	cx
	mov	cx, bx
	mov	bx, ds:[si].TRAE_token
	call	RemoveElement
	pop	cx

	FALL_THRU RunArrayDeleteNoElement
RunArrayDelete	endp

RunArrayDeleteNoElement	proc	near
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jz	lmem

	; delete in a huge array

	push	ax
	mov	cx, 1
	call	HugeArrayContract
	mov_tr	cx, ax				;cx = # consecutive elements
	pop	ax
	ret

	; delete in an lmem chunk

lmem:
	push	ax, bx, cx

	; then remove the run array element from the array

	mov	ax, di				;ax = chunk
	mov	bx, si
	sub	bx, ds:[di]			;bx = offset to delete at
	mov	cx,size TextRunArrayElement
	call	LMemDeleteAt

	mov	bx, ds:[di]			;ds:bx - run array
	dec	ds:[bx].TRAH_meta.CAH_count	;increment array count

	pop	ax, bx, cx
	ret

RunArrayDeleteNoElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RunArrayPrevious

DESCRIPTION:	Point at the previous entry in a run array

CALLED BY:	INTERNAL

PASS:
	ds:si - run array element
	cx - # consecutive elements at ds:si

RETURN:
	ds:si - previous run array element
	cx - # consecutive elements at ds:si
	dx.ax - position
	bx - token

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/25/91		Initial version

------------------------------------------------------------------------------@
RunArrayPrevious	proc	near
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jz	lmem

	; we will optimize here by knowing how the huge array code works

	push	di
	mov	di, ds:[HUGE_ARRAY_DATA_CHUNK]
	add	di, size ChunkArrayHeader
	cmp	si, di				;first element in block ?
	pop	di
	jnz	lmem

	push	ax, dx, di
	call	HugeArrayPrev			;ax = # elements in block
	pop	ax, dx, di
	mov	cx, 1
	jmp	done

lmem:
	sub	si, size TextRunArrayElement
	inc	cx
done:
	GOTO	LoadRegsFromRun

RunArrayPrevious	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RunArrayMarkDirty

DESCRIPTION:	Mark a run array dirty

CALLED BY:	INTERNAL

PASS:
	ds:si - array element
	di - run token

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
	Tony	9/30/91		Initial version

------------------------------------------------------------------------------@
FarRunArrayMarkDirty	proc	far
	call	RunArrayMarkDirty
	ret
FarRunArrayMarkDirty	endp

RunArrayMarkDirty	proc	near
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jz	lmem

	call	HugeArrayDirty
	ret

lmem:
	xchg	si, di
	call	ObjMarkDirty
	xchg	si, di
	ret

RunArrayMarkDirty	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RunArrayNext

DESCRIPTION:	Point at the next entry in a run array

CALLED BY:	INTERNAL

PASS:
	ds:si - run array element
	cx - # consecutive elements at ds:si

RETURN:
	ds:si - next run array element
	cx - # consecutive elements at ds:si
	dx.ax - position
	bx - token

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/91		Initial version

------------------------------------------------------------------------------@
FarRunArrayNext	proc	far
	call	RunArrayNext
	ret
FarRunArrayNext	endp

RunArrayNext	proc	near
EC <	cmp	ds:[si].TRAE_position.WAAH_high, TEXT_ADDRESS_PAST_END_HIGH >
EC <	ERROR_Z	VIS_TEXT_CANNOT_GO_BEYOND_LAST_ELEMENT			>

	add	si, size TextRunArrayElement
	loop	done
	sub	si, size TextRunArrayElement
	mov_tr	cx, ax			;cx saves ax
	call	HugeArrayNext
	xchg	ax, cx			;restore ax, cx = count
done:
	FALL_THRU	LoadRegsFromRun

RunArrayNext	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadRegsFromRun

DESCRIPTION:	Load registers from run array element

CALLED BY:	INTERNAL

PASS:
	ds:si - run array element

RETURN:
	dx.ax - position
	bx - token

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/91		Initial version

------------------------------------------------------------------------------@
LoadRegsFromRun	proc	near
	mov	bx, ds:[si].TRAE_token
	mov	ax, ds:[si].TRAE_position.WAAH_low
	clr	dx
	mov	dl, ds:[si].TRAE_position.WAAH_high

EC <	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH				>
EC <	jnz	10$							>
EC <	cmp	bx, CA_NULL_ELEMENT					>
EC <	ERROR_NZ	END_RUN_TOKEN_MUST_BE_CA_NULL_ELEMENT		>
EC <10$:								>
	ret
LoadRegsFromRun	endp

LoadRegsFromRunFar proc far
	call LoadRegsFromRun
	ret
LoadRegsFromRunFar endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RunArrayUnref

DESCRIPTION:	Unreference a run array so that it can be found again after
		modifying the text of the elements

CALLED BY:	INTERNAL

PASS:
	ds:si - run array
	di - run token

RETURN:
	bx, si, di -  data to save

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/91		Initial version

------------------------------------------------------------------------------@
RunArrayUnref	proc	far
	mov	bx, ds:[LMBH_handle]
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jnz	done

	; if lmem then store offset of chunk

	EC_CHUNK_HANDLE	ds, di
	sub	si, ds:[di]			;si = offset in chunk
done:
	ret

RunArrayUnref	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RunArrayReref

DESCRIPTION:	Rederefernce a run array

CALLED BY:	INTERNAL

PASS:
	bx, si, di - data from RunArrayUnref

RETURN:
	ds:si - run array element
	di - run token
	flags preserved

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/91		Initial version

------------------------------------------------------------------------------@
RunArrayReref	proc	far
	pushf
	call	MemDerefDS
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jnz	done

	; if lmem then add back offset

	add	si, ds:[di]
done:
	popf
	ret

RunArrayReref	endp

;=============================================================================
;		Internal routines
;=============================================================================

COMMENT @----------------------------------------------------------------------

FUNCTION:	RunArrayLock

DESCRIPTION:	Lock a run array

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset of run array

RETURN:
	ds:si - first run array element
	di - token to pass to various RunArray routines
	cx - number of consecutive elements (or 0xffff if all of them)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/91		Initial version

------------------------------------------------------------------------------@
FarRunArrayLock	proc	far
	call	RunArrayLock
	ret
FarRunArrayLock	endp

RunArrayLock	proc	near	uses ax, bx, dx
	class	VisTextClass
	.enter

EC <	call	T_AssertIsVisText					>

EC <	cmp	bx, offset VTI_charAttrRuns				>
EC <	jz	10$							>
EC <	cmp	bx, offset VTI_paraAttrRuns				>
EC <	jz	10$							>
EC <	cmp	bx, OFFSET_FOR_GRAPHIC_RUNS				>
EC <	jz	10$							>
EC <	cmp	bx, OFFSET_FOR_TYPE_RUNS				>
EC <	ERROR_NZ	ILLEGAL_RUN_TYPE				>
EC <10$:								>

	mov	cx, bx
	call	T_GetVMFile
	xchg	bx, cx				;bx = run offset, cx = file

	mov	ax, ATTR_VIS_TEXT_TYPE_RUNS
	cmp	bx, OFFSET_FOR_TYPE_RUNS
	jz	vardataCommon
	mov	ax, ATTR_VIS_TEXT_GRAPHIC_RUNS
	cmp	bx, OFFSET_FOR_GRAPHIC_RUNS
	jz	vardataCommon

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	mov	di, ds:[si][bx]			;di = run
common:
	test	ds:[si].VTI_storageFlags, mask VTSF_LARGE
	jnz	large

	; we need to store the VM file handle in TRAH_elementArray so that
	; ElementArrayLock can use it, but only if this the element
	; array is in a VM file, not a chunk.

	mov	si, ds:[di]			;ds:si = run
	tst	ds:[si].TRAH_elementVMBlock	;in VM file?
	jz	notVM
	mov	ds:[si].TRAH_elementArray, cx
notVM:

	add	si, size TextRunArrayHeader	;ds:si = first run
	mov	cx, CONSECUTIVE_ELEMENTS_NON_VM
done:
	.leave
	ret

large:
	clr	ax, dx				;element #0
	mov	bx, cx
	call	HugeArrayLock
EC <	tst	ax							>
EC <	ERROR_Z	PASSED_OFFSET_DOES_NOT_EXIST_IN_HUGE_ARRAY		>
	mov_tr	cx, ax				;cx = # consecutive
	jmp	done

vardataCommon:
	call	ObjVarFindData
EC <	ERROR_NC VIS_TEXT_VAR_DATA_DOES_NOT_MATCH_STORAGE_FLAGS		>
	mov	di, ds:[bx]
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	jmp	common

RunArrayLock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TransRunArrayLock

DESCRIPTION:	Lock a transfer run array

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - file
	di - run

RETURN:
	ds:si - first run array element
	di - token to pass to various RunArray routines
	cx - number of consecutive elements (or 0xffff if all of them)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/91		Initial version

------------------------------------------------------------------------------@

TextTransfer	segment resource

TransRunArrayLock	proc	near	uses ax, dx
	.enter

	clr	dx
	clr	ax
	call	HugeArrayLock
	mov_tr	cx, ax				;cx = # consecutive

	.leave
	ret
TransRunArrayLock	endp

TextTransfer	ends

COMMENT @----------------------------------------------------------------------

FUNCTION:	RunArrayUnlock

DESCRIPTION:	Unlock a run array

CALLED BY:	INTERNAL

PASS:
	ds - locked run array block

RETURN:
	none

DESTROYED:
	none (flags preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/91		Initial version

------------------------------------------------------------------------------@
FarRunArrayUnlock	proc	far
	call	RunArrayUnlock
	ret
FarRunArrayUnlock	endp

RunArrayUnlock	proc	near
	pushf

	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jz	done
	call	HugeArrayUnlock
done:

	popf
	ret

RunArrayUnlock	endp

TextAttributes ends

;---

TextInstance segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	RunArrayLock

DESCRIPTION:	Free a run array

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset of run array

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
	Tony	9/23/91		Initial version

------------------------------------------------------------------------------@
RunArrayFree	proc	near	uses ax, bx, di
	class	VisTextClass
	.enter

EC <	call	T_AssertIsVisText					>

EC <	cmp	bx, offset VTI_charAttrRuns				>
EC <	jz	10$							>
EC <	cmp	bx, offset VTI_paraAttrRuns				>
EC <	jz	10$							>
EC <	cmp	bx, OFFSET_FOR_GRAPHIC_RUNS				>
EC <	jz	10$							>
EC <	cmp	bx, OFFSET_FOR_TYPE_RUNS				>
EC <	ERROR_NZ	ILLEGAL_RUN_TYPE				>
EC <10$:								>

	mov	ax, ATTR_VIS_TEXT_TYPE_RUNS
	cmp	bx, OFFSET_FOR_TYPE_RUNS
	jz	vardataCommon
	mov	ax, ATTR_VIS_TEXT_GRAPHIC_RUNS
	cmp	bx, OFFSET_FOR_GRAPHIC_RUNS
	jz	vardataCommon

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di][bx]			;ax = run
common:
	call	FreeLMemOrVMem
	.leave
	ret


vardataCommon:
	call	ObjVarFindData
EC <	ERROR_NC VIS_TEXT_VAR_DATA_DOES_NOT_MATCH_STORAGE_FLAGS		>
	mov	ax, ds:[bx]
	call	ObjVarDeleteDataAt
	jmp	common

RunArrayFree	endp

;---

FreeLMemOrVMem	proc	near	uses bx, di, bp
	class	VisTextClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	large

	call	ObjFreeChunk
done:
	.leave
	ret

large:
	call	T_GetVMFile			;bx = file
	clr	bp				;ax:bp = VMChain
	call	VMFreeVMChain
	jmp	done

FreeLMemOrVMem	endp

TextInstance ends

