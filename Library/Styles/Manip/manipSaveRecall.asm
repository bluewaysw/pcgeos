COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipSaveRecall.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code for StyleSheetSaveStyle and
	StyleSheetPrepareForRecallStyle

	$Id: manipSaveRecall.asm,v 1.1 97/04/07 11:15:28 newdeal Exp $

------------------------------------------------------------------------------@

SaveRecallBlockHeader	struct
    SRBH_meta		ObjLMemBlockHeader
    SRBH_styleArray	lptr
    SRBH_attrArrays	lptr	MAX_STYLE_SHEET_ATTRS dup (?)
    SRBH_attrTokens	word	MAX_STYLE_SHEET_ATTRS dup (?)
SaveRecallBlockHeader	ends

ManipCode	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetSaveStyle

DESCRIPTION:	Define a new style

CALLED BY:	GLOBAL

PASS:
	ss:bp - StyleSheetParams
	ss:ax - SSCSaveStyleParams

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
	Tony	12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetSaveStyle	proc	far
STYLE_COPY_LOCALS

	; if no style array was passed then bail out

	tst	ss:[bp].SSP_styleArray.SCD_chunk
	jnz	1$
	ret
1$:

	.enter

	call	EnterStyleSheet

	; We must allocate a block and put a style array and attribute
	; arrays in it.  We then copy the elements into this block.  We
	; set up the block as the "xferArray".

	; Since we have already done the EnterStyleSheet, we need to
	; manually lock the xfer style.

	mov	ax, LMEM_TYPE_OBJ_BLOCK
	mov	cx, size SaveRecallBlockHeader
	call	MemAllocLMem

	mov	di, ss:[bp]			;ss:di = StyleSheetParams
	mov	ss:[di].SSP_xferStyleArray.SCD_vmFile, 0
	mov	ss:[di].SSP_xferStyleArray.SCD_vmBlockOrMemHandle, bx
	mov	xferStyleArrayHandle, bx
	clc
	pushf
	pop	xferStyleArrayFlags
	call	MemLock

	; allocate a style array

	call	Load_dssi_styleArray		;get source data size
	mov	si, ds:[si]
	mov	bx, ds:[si].NAH_dataSize
	mov	cx, ds:[si].CAH_offset

	; NOTE: We set the low bit of the chunk handle saved in the
	;	StyleSheetParams to mark this this is not an object block

	mov	ds, ax
	clr	si
	clr	ax
	call	NameArrayCreate			;*ds:si = xfer style array
	mov	ss:[di].SSP_xferStyleArray.SCD_chunk, si
	ornf	ss:[di].SSP_xferStyleArray.SCD_chunk,
						STYLE_CHUNK_NOT_IN_OBJ_BLOCK
	movdw	xferStyleArray, dssi
	mov	ds:SRBH_styleArray, si

	; allocate attribute arrays

createAttrLoop:
	push	di
	mov	ax, CA_NULL_ELEMENT
	call	LockLoopAttrArray		;ds:si = attr array
	pop	di

	mov	si, ds:[si]
	mov	bx, ds:[si].CAH_elementSize
	mov	cx, ds:[si].CAH_offset

	mov	ds, xferStyleArray.segment
	clr	si
	clr	ax
	call	ElementArrayCreate		;*ds:si = element array
	mov	xferStyleArray.segment, ds
	mov	bx, ds:[LMBH_handle]
	mov	ss:[di].SSP_xferAttrArrays.SCD_vmFile, 0
	mov	ss:[di].SSP_xferAttrArrays.SCD_vmBlockOrMemHandle, bx
	mov	ss:[di].SSP_xferAttrArrays.SCD_chunk, si
	ornf	ss:[di].SSP_xferAttrArrays.SCD_chunk,
						STYLE_CHUNK_NOT_IN_OBJ_BLOCK
	add	di, size StyleChunkDesc

	mov	bx, attrCounter2
	mov	ds:[SRBH_attrArrays][bx], si

	; unlock attribute array

	call	UnlockLoopAttrArray
	jnz	createAttrLoop

	clr	optBlock
	clr	fromTransfer
	clr	changeDestStyles

	; copy the elements

copyAttrLoop:
	mov	di, saved_ax			;ss:di = SSCSaveStyleParams
	add	di, attrCounter2
	mov	ax, ss:[di].SSCSSP_attrTokens	;ax = source token
	push	ax
	call	LockLoopAttrArray		;ds:si = attr array
						;ds:di = element
	mov	ax, ds:[di].SSEH_style
	mov	styleToChange, ax

	; CopyStyle locks and unlocks attribute arrays, so we can't keep
	; this one locked

	push	attrCounter1
	call	UnlockSpecificAttrArray

	call	CopyStyle			;ax = style in dest
	mov	destStyle, ax
	mov	destCopyFromStyle, ax

	mov	ax, CA_NULL_ELEMENT
	pop	bx
	call	LockSpecificAttrArray

	pop	ax				;ax = element
	clr	dx
	call	CopyElement			;ax = element in dest

	mov	ds, xferStyleArray.segment
	mov	di, attrCounter2
	mov	ds:[SRBH_attrTokens][di], ax

	; unlock attribute array

	call	UnlockLoopAttrArray
	jnz	copyAttrLoop

	mov	di, saved_ax			;ss:di = SSCSaveStyleParams
	movdw	bxsi, ss:[di].SSCSSP_replyObject
	mov	cx, xferStyleArrayHandle
	mov	ax, MSG_STYLE_SHEET_SET_SAVED_STYLE
	clr	di
	call	ObjMessage

	call	FreeOptBlock

	call	LeaveStyleSheet

	.leave
	ret

StyleSheetSaveStyle	endp

FreeOptBlock	proc	near
STYLE_COPY_LOCALS
	.enter inherit far

	mov	bx, optBlock
	tst	bx
	jz	done
	call	MemFree
done:
	.leave
	ret

FreeOptBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetPrepareForRecallStyle

DESCRIPTION:	Prepare for recall style by copying saved attributes back
		into the arrays

CALLED BY:	GLOBAL

PASS:
	ss:bp - StyleSheetParams
	cx - block containing saved style

RETURN:
	ss:bp - StyleSheetParams with SSP_attrTokens filled in

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetPrepareForRecallStyle	proc	far	uses bx
STYLE_COPY_LOCALS

	; if no style array was passed then bail out

	tst	ss:[bp].SSP_styleArray.SCD_chunk
	jnz	1$
	ret
1$:

	.enter

	call	EnterStyleSheet

	; first set up the xferStyleArray

	mov	bx, cx
	mov	xferStyleArrayHandle, bx
	call	MemLock
	mov	ds, ax
	mov	si, ds:SRBH_styleArray

	; NOTE: We set the low bit of the chunk handle saved in the
	;	StyleSheetParams to mark this this is not an object block

	mov	di, ss:[bp]			;ss:di = StyleSheetParams
	mov	ss:[di].SSP_xferStyleArray.SCD_vmFile, 0
	mov	ss:[di].SSP_xferStyleArray.SCD_vmBlockOrMemHandle, bx
	mov	ss:[di].SSP_xferStyleArray.SCD_chunk, si
	ornf	ss:[di].SSP_xferStyleArray.SCD_chunk,
						STYLE_CHUNK_NOT_IN_OBJ_BLOCK
	movdw	xferStyleArray, dssi
	clc
	pushf
	pop	xferStyleArrayFlags

	clr	optBlock
	mov	fromTransfer, 1
	clr	changeDestStyles

	; fill in the table

	mov	ds, xferStyleArray.segment
	mov	bx, ds:[LMBH_handle]
	clr	di
fillLoop:
	shl	di
	mov	ax, ds:[SRBH_attrTokens][di]	;ax = element
	mov	cx, ds:[SRBH_attrArrays][di]	;cx = chunk

	mov	si, di
	shl	si
	add	si, di
	add	si, ss:[bp]
	mov	ss:[si].SSP_xferAttrArrays.SCD_vmFile, 0
	mov	ss:[si].SSP_xferAttrArrays.SCD_vmBlockOrMemHandle, bx
	mov	ss:[si].SSP_xferAttrArrays.SCD_chunk, cx
	ornf	ss:[si].SSP_xferAttrArrays.SCD_chunk,
						STYLE_CHUNK_NOT_IN_OBJ_BLOCK

	shr	di
	inc	di
	cmp	di, attrTotal
	jnz	fillLoop

	; copy in the attributes

copyAttrLoop:
	mov	ds, xferStyleArray.segment
	mov	di, attrCounter2
	mov	ax, ds:[SRBH_attrTokens][di]	;ax = element
	push	ax

	mov	ax, CA_NULL_ELEMENT
	call	LockLoopAttrArray		;ds:si = attr array
						;ds:di = element
	call	Load_dssi_xferAttrArray
	pop	ax
	push	ax
	call	ChunkArrayElementToPtr
	mov	ax, ds:[di].SSEH_style
	mov	styleToChange, ax

	; CopyStyle locks and unlocks attribute arrays, so we can't keep
	; this one locked

	push	attrCounter1
	call	UnlockSpecificAttrArray

	call	CopyStyle			;ax = style in dest
	mov	destStyle, ax
	mov	destCopyFromStyle, ax

	mov	ax, CA_NULL_ELEMENT
	pop	bx
	call	LockSpecificAttrArray

	pop	ax				;ax = element
	clr	dx
	call	CopyElement			;ax = element in dest

	mov	di, ss:[bp]
	add	di, attrCounter2
	mov	ss:[di].SSP_attrTokens, ax

	call	UnlockLoopAttrArray
	jnz	copyAttrLoop

	call	FreeOptBlock

	push	xferStyleArrayHandle

	call	LeaveStyleSheet

	pop	bx
	call	MemDecRefCount

	.leave
	ret

StyleSheetPrepareForRecallStyle	endp

ManipCode	ends
