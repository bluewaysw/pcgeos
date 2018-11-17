COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipUtils.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code for StyleSheetDescribeStyle

	$Id: manipUtils.asm,v 1.1 97/04/07 11:15:22 newdeal Exp $

------------------------------------------------------------------------------@

CommonCode segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetLockStyleChunk

DESCRIPTION:	Lock a style chunk given a StyleChunkDesc

CALLED BY:	GLOBAL

PASS:
	ss:bx - StyleChunkDesc

RETURN:
	*ds:si - array
	carry - value to pass to StyleSheetUnlockStyleChunk

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/19/91	Initial version

------------------------------------------------------------------------------@
StyleSheetLockStyleChunk	proc	far	uses ax, bx, cx, bp
	.enter

	mov	bp, bx
	mov	si, ss:[bp].SCD_chunk
	mov	cx, ss:[bp].SCD_vmFile
	mov	bx, ss:[bp].SCD_vmBlockOrMemHandle
	jcxz	notVMFile

	; it is a VM file, save the override

	mov_tr	ax, bx			;ax = vmBlock
	mov	bx, cx
	call	VMLock
	mov	ds, ax

	; if this block is not an LMEM block (which it is not if it is a
	; transfer block) then temporarily make it an lmem block

	tst	ds:[LMBH_handle]
	clc
	jnz	done				;branch with carry clear
	mov	ds:[LMBH_handle], bp
	mov	bx, bp				;return non-zero
	mov	ax, mask HF_LMEM
	call	MemModifyFlags
	stc
	jmp	done

notVMFile:
	test	si, STYLE_CHUNK_NOT_IN_OBJ_BLOCK
	jnz	notInObjectBlock
	call	ObjLockObjBlock
afterLock:
	mov	ds, ax
	clc
done:
	.leave
	ret

notInObjectBlock:
	andnf	si, not STYLE_CHUNK_NOT_IN_OBJ_BLOCK
	call	MemLock
	jmp	afterLock

StyleSheetLockStyleChunk	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetUnlockStyleChunk

DESCRIPTION:	Unlock a style chunk given its segment

CALLED BY:	GLOBAL

PASS:
	ds - block to unlock
	flags - flags returned by StyleSheetLockStyleChunk
		carry - set if lmem<->vmem transition needed

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
	Tony	12/19/91		Initial version

------------------------------------------------------------------------------@
StyleSheetUnlockStyleChunk	proc	far	uses ax, bx, bp
	.enter

	mov	bx, ds:[LMBH_handle]
	jnc	10$
	mov	ax, (mask HF_LMEM) shl 8
	call	MemModifyFlags				;bx is handle
	clr	ds:[LMBH_handle]
10$:

	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jnz	vmBlock
	call	MemUnlock
	jmp	done

vmBlock:
	mov	bp, bx
	call	VMUnlock

done:
	.leave
	ret

StyleSheetUnlockStyleChunk	endp

CommonCode ends

;========================

; Common local variables for style sheet routines

STYLE_LOCALS	equ	<\
.warn -unref_local\
styleArray		local	fptr	;*ds:si of style array (locked)\
styleArrayHandle	local	hptr\
styleArrayFlags		local	word\
attrArray		local	fptr\
attrArrayHandle		local	hptr\
attrArrayFlags		local	word\
\
xferStyleArray		local	fptr\
xferStyleArrayHandle	local	hptr\
xferStyleArrayFlags	local	word\
xferAttrArray		local	fptr\
xferAttrArrayHandle	local	hptr\
xferAttrArrayFlags	local	word\
\
attrTotal		local	word	;number of attribute arrays\
attrCounter1		local	word	;loop counter\
attrCounter2		local	word	;loop counter (times 2)\
attrCounter4		local	word	;loop counter (times 4)\
saved_ax		local	word\
saved_bx		local	word\
saved_cxdx		local	dword\
saved_esdi		local	dword\
saved_si		local	word\
saved_ds_handle		local	hptr\
.warn @unref_local\
>

			CheckHack <(size SEH_reserved) eq 6>

STYLE_MANIP_LOCALS	equ	<\
STYLE_LOCALS\
.warn -unref\
styleToChange	local	word\
changeAttrs	local	MAX_STYLE_SHEET_ATTRS dup (word)\
privateData	local	dword\
reserved	local	6 dup (byte)\
enumElement	local	word\
oldElement	local	word\
newElement	local	word\
recalcFlag	local	word\
substituteFlag	local	byte\
.warn @unref_local\
>


;;copyStart	equ	styleArray
;;copyEnd	equ	xferStyleArrayStyleLocals	ends

ManipCode	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	LockLoopAttrArray

DESCRIPTION:	Lock an attr array for a style routine

CALLED BY:	INTERNAL

PASS:
	ax - attribute token
	ss:bp - inherited variables
		attrCounter2 - offset to attr array to lock

RETURN:
	attrArray - set
	xferAttrArray - set
	ds:si - attr array
	ds:di - element from style in attr array
	cx - element size
	carry - set if attr non-null

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/ 9/92		Initial version

------------------------------------------------------------------------------@
LockLoopAttrArray	proc	near	uses bx
STYLE_LOCALS
	.enter inherit far

	; lock appropriate attribute array

	call	LockCommon

	call	ElementToPtrCheckNull

	.leave
	ret

LockLoopAttrArray	endp

;--

ElementToPtrCheckNull	proc	near
	clr	di
	cmp	ax, CA_NULL_ELEMENT
	jz	done
	push	si
	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_elementSize
	pop	si
	call	ChunkArrayElementToPtr		;ds:di = style
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	stc
done:
	ret

ElementToPtrCheckNull	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UnlockLoopAttrArray

DESCRIPTION:	Utility routine to unlock attr array and update loop vars

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables
		attrCounter2 - offset to attr array to lock

RETURN:
	z flag - set if loop complete

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/ 9/92		Initial version

------------------------------------------------------------------------------@
UnlockLoopAttrArray	proc	near	uses ax
STYLE_LOCALS
	.enter inherit far

	call	UnlockCommon

	; loop to next attribute

	add	attrCounter2, 2
	add	attrCounter4, 4
	inc	attrCounter1
	mov	ax, attrCounter1
	cmp	ax, attrTotal
	jnz	done

	; if we're at the end of the loop we want to reload the counters

	mov	attrCounter1, 0
	mov	attrCounter2, 0
	mov	attrCounter4, 0
done:
	.leave
	ret

UnlockLoopAttrArray	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LockSpecificAttrArray

DESCRIPTION:	Lock an attr array for a style routine

CALLED BY:	INTERNAL

PASS:
	ax - attribute token
	bx - offset of attribute array to lock
	ss:bp - inherited variables
		attrCounter2 - offset to attr array to lock

RETURN:
	ds:si - attr array
	attrArray - set
	xferAttrArray - set

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/ 9/92		Initial version

------------------------------------------------------------------------------@
LockSpecificAttrArray	proc	near
STYLE_LOCALS
	.enter inherit far

	; lock appropriate attribute array

	mov	attrCounter1, bx
	shl	bx
	mov	attrCounter2, bx
	shl	bx
	mov	attrCounter4, bx

	call	LockCommon

	.leave
	ret

LockSpecificAttrArray	endp

;---

LockCommon	proc	near
STYLE_LOCALS
	.enter inherit far

	mov	di, ss:[bp]			;ss:di = StyleSheetParams

	lea	bx, ss:[di].SSP_xferAttrArrays
		CheckHack <(size StyleChunkDesc) eq 6>
	add	bx, attrCounter2
	add	bx, attrCounter4	;add * 6
	tst	ss:[bx].SCD_vmBlockOrMemHandle
	jz	noXferArray
	call	StyleSheetLockStyleChunk	;*ds:si = array
	pushf
	pop	xferAttrArrayFlags
	mov	bx, ds:[LMBH_handle]
	movdw	xferAttrArray, dssi
xferCommon:
	mov	xferAttrArrayHandle, bx

	lea	bx, ss:[di].SSP_attrArrays
		CheckHack <(size StyleChunkDesc) eq 6>
	add	bx, attrCounter2
	add	bx, attrCounter4	;add * 6
	call	StyleSheetLockStyleChunk	;*ds:si = array
	pushf
	pop	attrArrayFlags
	movdw	attrArray, dssi
	mov	bx, ds:[LMBH_handle]
	mov	attrArrayHandle, bx

	.leave
	ret

noXferArray:
	clr	bx
EC <	mov	xferAttrArray.segment, 0xcccc		>
EC <	mov	xferAttrArray.offset, 0xcccc			>
	jmp	xferCommon

LockCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UnlockSpecificAttrArray

DESCRIPTION:	Utility routine to unlock attr array

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables
		attrCounter2 - offset to attr array to lock

RETURN:
	z flag - set if loop complete

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/ 9/92		Initial version

------------------------------------------------------------------------------@
UnlockSpecificAttrArray	proc	near	uses ax
STYLE_LOCALS
	.enter inherit far

	call	UnlockCommon

	mov	attrCounter1, 0
	mov	attrCounter2, 0
	mov	attrCounter4, 0

	.leave
	ret

UnlockSpecificAttrArray	endp

;---

UnlockCommon	proc	near
STYLE_LOCALS
	.enter inherit far

	mov	ds, attrArray.segment
	push	attrArrayFlags
	popf
	call	StyleSheetUnlockStyleChunk

	tst	xferAttrArrayHandle
	jz	noXferArray
	mov	ds, xferAttrArray.segment
	push	xferAttrArrayFlags
	popf
	call	StyleSheetUnlockStyleChunk
noXferArray:
	mov	attrArrayHandle, 0
	mov	xferAttrArrayHandle, 0

EC <	mov	attrArray.segment, 0xcccc			>
EC <	mov	attrArray.offset, 0xcccc			>
EC <	mov	xferAttrArray.segment, 0xcccc		>
EC <	mov	xferAttrArray.offset, 0xcccc			>

	.leave
	ret

UnlockCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	EnterStyleSheet

DESCRIPTION:	Common entry code for style sheet routines

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables

RETURN:
	registers - saved in stack frame
	styleArray - set (with array locked)
	xferStyleArray - set (with array locked)
	attrTotal - set
	attrCounter1 - 0
	attrCounter2 - 0
	attrCounter4 - 0
	*ds:si - style array
	ss:di - StyleSheetParams

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/18/91		Initial version

------------------------------------------------------------------------------@
EnterStyleSheet	proc	near	uses ax, bx
STYLE_LOCALS
	.enter inherit far

	mov	saved_ax, ax
	mov	saved_bx, bx
	movdw	saved_cxdx, cxdx
	movdw	saved_esdi, esdi
	mov	saved_si, si
	mov	ax, ds:[LMBH_handle]
	mov	saved_ds_handle, ax

	mov	di, ss:[bp]			;ss:di = params

	lea	bx, ss:[di].SSP_styleArray
	call	StyleSheetLockStyleChunk	;*ds:si = array
	pushf
	pop	styleArrayFlags
	movdw	styleArray, dssi
	mov	bx, ds:[LMBH_handle]
	mov	styleArrayHandle, bx

	lea	bx, ss:[di].SSP_xferStyleArray
	tst	ss:[bx].SCD_vmBlockOrMemHandle
	jz	noXferArray
	call	StyleSheetLockStyleChunk	;*ds:si = array
	pushf
	pop	xferStyleArrayFlags
	mov	bx, ds:[LMBH_handle]
	movdw	xferStyleArray, dssi
xferCommon:
	mov	xferStyleArrayHandle, bx

	mov	bx, ds:[si]
	mov	ax, ds:[bx].NAH_dataSize	;# attrs = data size / 2
	sub	ax, (offset SEH_attrTokens) - (size SEH_meta)
	shr	ax
	mov	attrTotal, ax
	clr	ax
	mov	attrCounter1, ax
	mov	attrCounter2, ax
	mov	attrCounter4, ax
	mov	attrArrayHandle, ax
	mov	xferAttrArrayHandle, ax

	.leave
	ret

noXferArray:
	clr	bx
EC <	mov	xferStyleArray.segment, 0xcccc		>
EC <	mov	xferStyleArray.offset, 0xcccc		>
	jmp	xferCommon

EnterStyleSheet	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LeaveStyleSheet

DESCRIPTION:	Common exit code for style sheet routines

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables

RETURN:
	styleArray - unlocked
	registers - recovered in stack frame

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/18/91	Initial version

------------------------------------------------------------------------------@
LeaveStyleSheet	proc	near
STYLE_LOCALS
	.enter inherit far

EC <	call	ECCheckStyleArray					>

	mov	ds, styleArray.segment
	push	styleArrayFlags
	popf
	call	StyleSheetUnlockStyleChunk

	tst	xferStyleArrayHandle
	jz	noXferArray
	mov	ds, xferStyleArray.segment
	push	xferStyleArrayFlags
	popf
	call	StyleSheetUnlockStyleChunk
noXferArray:

	mov	bx, saved_ds_handle
	call	MemDerefDS
	mov	ax, saved_ax
	mov	bx, saved_bx
	movdw	cxdx, saved_cxdx
	movdw	esdi, saved_esdi
	mov	si, saved_si

	.leave
	ret

LeaveStyleSheet	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DerefStyleLocals

DESCRIPTION:	Dereference segments stored in local variables since they
		may have changed

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables

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
	Tony	1/15/92		Initial version

------------------------------------------------------------------------------@
DerefStyleLocals	proc	near	uses bx, ds
STYLE_LOCALS
	.enter inherit far

	pushf

	mov	bx, styleArrayHandle
	call	MemDerefDS
	mov	styleArray.segment, ds

	mov	bx, attrArrayHandle
	tst	bx
	jz	10$
	call	MemDerefDS
	mov	attrArray.segment, ds
10$:

	mov	bx, xferStyleArrayHandle
	tst	bx
	jz	20$
	call	MemDerefDS
	mov	xferStyleArray.segment, ds
20$:

	mov	bx, xferAttrArrayHandle
	tst	bx
	jz	30$
	call	MemDerefDS
	mov	xferAttrArray.segment, ds
30$:

	popf
	.leave
	ret

DerefStyleLocals	endp

;---

Load_dssi_styleArray	proc	near
STYLE_LOCALS
	.enter inherit far
	movdw	dssi, styleArray
	.leave
	ret
Load_dssi_styleArray	endp

;---

Load_dssi_attrArray	proc	near
STYLE_LOCALS
	.enter inherit far
	movdw	dssi, attrArray
	.leave
	ret
Load_dssi_attrArray	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IgnoreUndo

DESCRIPTION:	Start ignoring undo actions

CALLED BY:	INTERNAL

PASS:
	none

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
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
IgnoreUndoAndFlush	proc	far	uses ax, bx, cx
	.enter
	mov	ax, MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS
	mov	bx, MSG_GEN_APPLICATION_MARK_BUSY
	mov	cx, 1					;flush actions
	call	UndoCommon
	.leave
	ret
IgnoreUndoAndFlush	endp

UndoCommon	proc	near	uses bx, cx, dx, di, bp
	.enter
	push	bx
	clr	bx
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	ax
	call	GenCallApplication

	.leave
	ret
UndoCommon	endp

;---

AcceptUndo	proc	far	uses ax, bx
	.enter
	mov	ax, MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS
	mov	bx, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	UndoCommon
	.leave
	ret
AcceptUndo	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DisplayError

DESCRIPTION:	Display an error dialog

CALLED BY:	INTERNAL

PASS:
	ax - chunk handle of error string

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
	Tony	3/ 1/93		Initial version

------------------------------------------------------------------------------@
DisplayError	proc	near	uses bp
	pushf
	.enter

	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, \
			CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION,0>
	mov	ss:[bp].SDOP_customString.handle, handle ControlStrings
	mov	ss:[bp].SDOP_customString.chunk, ax
	clr	ss:[bp].SDOP_stringArg1.handle
	clr	ss:[bp].SDOP_stringArg2.handle
	clr	ss:[bp].SDOP_customTriggers.handle
	clrdw	ss:[bp].SDP_helpContext
	call	UserStandardDialogOptr

	.leave
	popf
	ret

DisplayError	endp

ManipCode	ends
