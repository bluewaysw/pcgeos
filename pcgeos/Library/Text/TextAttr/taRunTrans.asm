COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Text
FILE:		taRunManip.asm

ROUTINES:

	Name			Description
	----			-----------
				routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

DESCRIPTION:
	This file contains the internal routines to handle charAttr, paraAttr
	and type runs.  None of these routines are directly accessable
	outisde the text object.

	$Id: taRunTrans.asm,v 1.1 97/04/07 11:18:52 newdeal Exp $

------------------------------------------------------------------------------@

TRANS_PARAMS	equ	<\
.warn -unref_local\
ssParams	local	StyleSheetParams\
styleAttrOffset	local	word\
copyRange	local	VisTextRange\
runOffset	local	word\
optBlock	local	hptr\
fromTransfer	local	word\
objFile		local	hptr\
objRunDataBX	local	word\
objRunDataSI	local	word\
objRunDataDI	local	word\
objRunCount	local	word\
xferFile	local	word\
xferRunPtr	local	fptr\
xferRunCount	local	word\
xferRunToken	local	word\
textobject	local	optr\
transferHeader	local	hptr\
fileToken	local	word\
.warn @unref_local\
>

TextTransfer segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_CopyRunToTransfer

DESCRIPTION:	Copy run information from a text object to a transfer run

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ax - transfer file
	bx - offset of run in text object
	cx - xfer run vm block
	dx - optimization block (or 0 to allocate)
	ss:bp - VisTextRange in source to copy
	di - handle of (locked) TextTransferBlockHeader

RETURN:
	dx - optimization block

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	sourceRun = GetRunForPosition(sourceRunArray, sourcePos)
	destRun = destRunArray

	if (graphicRun} {
	    sourcePos = sourceRun.pos
	}

	do {
	    if ((charAttr or paraAttr) && style array exists) {
	        newToken = StyleSheetCopyElementToTransfer(sourceRun.token)
	    } else {
		temp = GetElement(sourceRunArray, sourceRun.token)
		newToken = AddElement(destRunArray, element)
	    }
	    InsertRun(destRun, range.start - sourceRun.position, newToken)
	    destRun++		/* point at TEXT_ADDRESS_PAST_END */
	    sourceRun++
	    range.start = sourceRun.pos
	} while (range.start < range.end)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
TA_CopyRunToTransfer	proc	near	uses ax, bx, cx, si, di, bp, ds
	class	VisTextClass
TRANS_PARAMS
sourceStart	local	dword
	.enter

	; sourceRun = GetRunForPosition(sourceRunArray, sourcePos)
	; destRun = destRunArray

	call	LoadCopyRunParams
	mov	fromTransfer, 0

	; if this is a graphic run, then check for the graphic being out of the
	; selection

	call	TTLoadObjRun
	clr	dx
	mov	dl, ds:[si].TRAE_position.WAAH_high
	mov	ax, ds:[si].TRAE_position.WAAH_low
	movdw	sourceStart, dxax

	cmp	runOffset, OFFSET_FOR_GRAPHIC_RUNS
	jnz	notGraphics
	jgedw	dxax, copyRange.VTR_end, afterLoop
	movdw	sourceStart, copyRange.VTR_start, ax
notGraphics:

runLoop:
	mov	bx, CA_NULL_ELEMENT	;style to use if no styles
	mov	dx, CA_NULL_ELEMENT	;copy style also
	call	CopyTransferElement	;bx = token
	jc	afterLoop

	;     InsertRun(destRun, sourceRun.position - sourceStart, newToken)
	;     destRun++		/* point at TEXT_ADDRESS_PAST_END */
	;     sourceRun++
	;     sourceStart = range.start
	; } while (range.start < range.end)

	call	TTLoadObjRun
	clr	dx
	mov	dl, ds:[si].TRAE_position.WAAH_high
	mov	ax, ds:[si].TRAE_position.WAAH_low
	subdw	dxax, sourceStart

	call	TTLoadXferRun
	call	FarRunArrayInsert
	push	bx
	call	FarRunArrayNext
	pop	bx
	call	TTStoreXferRun
	call	RemoveElement			;remove extra reference

	call	TTLoadObjRun
	call	FarRunArrayNext			;dxax = next pos
	call	TTStoreObjRun
	cmpdw	dxax, copyRange.VTR_end
	movdw	sourceStart, copyRange.VTR_start, ax
	jb	runLoop

afterLoop:
	call	TTLoadXferRun
	call	FarRunArrayUnlock

	; leaves source file set

	call	TTLoadObjRun
	call	FarRunArrayUnlock

	mov	dx, optBlock

	.leave
	ret

TA_CopyRunToTransfer	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_CopyRunFromTransfer

DESCRIPTION:	Copy run information from a transfer run to a text object

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ax - transfer file
	bx - offset of run in text object
	cx - xfer run vm block
	dx - optimization block (or 0 to allocate)
	ss:bp - VisTextRange in source to copy
	di - handle of (locked) TextTransferBlockHeader

RETURN:
	dx - optimization block

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

Handling of paraAttrs: ($ means C_CR)
    Transfer:  ab$cd$ef    where paraAttr runs are:  AA$BB$CC
    Object:    12$34$56    where paraAttr runs are:  XX$YY$ZZ, cursor btw 3 & 4

    Result:      12$3ab$cd$ef4$56
    ParaAttr runs:  XX$YYY$BB$YYY$ZZZ

	sourceRun = GetRunForPosition(sourceRunArray, 0)
	destRun = GetRunForPosition(destRunArray, range.start)
	if (graphicRuns) {
	    range.start += sourceRun.pos
	} else {
	    newToken = destRun.token
	    destRun++
	    if (destRun.pos != destEnd && destEnd != end of text) {
	        InsertRun(destRunArray, destEnd, newToken)
	    }
	}
	if (paraAttr) {
		nextPara = T_FindPara(range.start)
		adjustment = nextPara - range.start
		range.start = nextPara
	}

	do {
	    if ((charAttr or paraAttr) && style array exists) {
	        newToken = StyleSheetCopyElementFromTransfer(sourceRun.token)
	    } else {
		temp = GetElement(sourceRunArray, sourceRun.token)
		newToken = AddElement(destRunArray, element)
	    }
	    InsertRun(destRunArray, range.start, newToken)
	    range.start += (sourceRun+1.pos - sourceRun.pos)
	    destRun++
	    sourceRun++
	} while (range.start != TEXT_ADDRESS_PAST_END)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
TA_CopyRunFromTransfer	proc	near	uses ax, bx, cx, di, bp
	class	VisTextClass
TRANS_PARAMS
textsize	local	dword
adjustment	local	dword
insertedRunFlag	local	byte
runTokenAtAreaStart local word
posToStartStyleCopy local dword
posToEndStyleCopy local dword
valueToPassToCopy local word
baseStyleIfNone	local	word
	.enter

	pushdw	dxax
	call	TS_GetTextSize
	movdw	textsize, dxax
	popdw	dxax

	; sourceRun = GetRunForPosition(sourceRunArray, 0)
	; destRun = GetRunForPosition(destRunArray, range.start)

	call	LoadCopyRunParams
	mov	fromTransfer, -1

	push	ds, si
	call	TTLoadObject
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	test	ds:[di].VTI_features, mask VTF_ALLOW_UNDO
	pop	di
	jz	noUndo
	push	ax
	call	GenProcessUndoCheckIfIgnoring	;Don't create any actions if
	tst	ax				; ignoring undo
	pop	ax
	jnz	noUndo

;	Add an undo item to delete these runs.

	push	bp, cx
	mov	cx, runOffset
	lea	bp, copyRange
	call	CheckIfRunsInRangeForUndoFar
	tst	ax
	jz	noUndoRuns
	push	bx
	mov	bx, bp
	call	TU_CreateUndoForRunsInRange
	pop	bx
noUndoRuns:
	call	TU_CreateUndoForRunModification
	pop	bp, cx
noUndo:
	pop	ds, si

	; if (graphicRuns) {
	;     range.start += sourceRun.pos

	clr	insertedRunFlag
	cmp	runOffset, OFFSET_FOR_GRAPHIC_RUNS
	jnz	notGraphics
	call	TTLoadXferRun
	clr	dx
	mov	dl, ds:[si].TRAE_position.WAAH_high
	mov	ax, ds:[si].TRAE_position.WAAH_low
	adddw	copyRange.VTR_start, dxax
	jmp	common

	; Since we will be splitting a run and putting information in the
	; middle, we must ensure that the parts before and after the part we
	; change retain the same run.  In the general case, this involves
	; inserting a run after the run to be split, positioning it just after
	; the end of the area we change, and giving it the token of the run
	; that we split.
	; There are some boundry cases to take care of when inserting at the
	; edge of a run:
	; * if we are at the right edge of a run, do not insert a run

	; } else {
	;     newToken = destRun.token
	;     destRun++
	;     if (destRun.pos != destEnd && destEnd != end of text) {
	;         InsertRun(destRunArray, destEnd, newToken)
	;     }
	; }

notGraphics:
	call	TTLoadObjRun				;load dest
	push	ds:[si].TRAE_token
	call	FarRunArrayNext				;dxax = next pos
	pop	bx
	mov	runTokenAtAreaStart, bx

	push	bp
	sub	sp, size VisTextMaxParaAttr
	mov	bp, sp
	call	GetElement
	mov	ax, ss:[bp].SSEH_style
	add	sp, size VisTextMaxParaAttr
	pop	bp
	mov	baseStyleIfNone, ax

	movdw	dxax, copyRange.VTR_end
	cmp	dl, ds:[si].TRAE_position.WAAH_high
	jnz	10$
	cmp	ax, ds:[si].TRAE_position.WAAH_low
10$:
	jz	noInsertRun
	cmpdw	dxax, textsize
	jz	noInsertRun

	call	FarRunArrayInsert
	inc	insertedRunFlag
noInsertRun:
	call	TTStoreObjRun

common:

	; if (paraAttr) {
	;	nextPara = T_FindPara(range.start)
	;	adjustment = nextPara - range.start
	;	range.start = nextPara
	; }

	movdw	posToEndStyleCopy, TEXT_ADDRESS_PAST_END
	clr	ax
	clrdw	adjustment, ax
	clrdw	posToStartStyleCopy, ax
	call	TTLoadObject

	cmp	runOffset, offset VTI_paraAttrRuns
	jnz	notParaAttr

	movdw	dxax, copyRange.VTR_start
	call	TSL_IsParagraphStart
	LONG jc	runLoop

	call	TSL_FindParagraphEnd			;dxax = para end
	jc	toAfterLoop
	incdw	dxax
	pushdw	dxax
	subdw	dxax, copyRange.VTR_start
	movdw	adjustment, dxax
	popdw	dxax
	movdw	copyRange.VTR_start, dxax		;range.start = nextPara

	; if the adjustment is bigger than the range to paste then we're not
	; pasting any CR's, so bail

	cmpdw	dxax, copyRange.VTR_end
	jbe	runLoop
toAfterLoop:
	jmp	afterLoop

	; if we are adjusting character attribute runs then we need to not
	; copy the style until the next paragraph

notParaAttr:
	cmp	runOffset, offset VTI_charAttrRuns
	jnz	runLoop

	movdw	dxax, copyRange.VTR_start
	call	TSL_IsParagraphStart
	jc	notCAParaStart
	call	TSL_FindParagraphEnd			;dxax = para end
	movdw	posToStartStyleCopy, dxax
notCAParaStart:
	movdw	dxax, copyRange.VTR_end
	stc
	call	TSL_FindParagraphStart
	jc	20$
	decdw	dxax
20$:
	cmpdw	dxax, copyRange.VTR_start
	ja	30$
	movdw	dxax, TEXT_ADDRESS_PAST_END
30$:
	movdw	posToEndStyleCopy, dxax

	; now loop through all of the runs in the source (the transfer item)
	; and copy each run to the destination (the text object)

	; we must be careful with character attribute styles since we do
	; not want to copy the underlying style unless we are copying the
	; entire para

runLoop:
	movdw	dxax, copyRange.VTR_start
	cmpdw	dxax, posToStartStyleCopy
	jb	copyNoStyle
	cmpdw	dxax, posToEndStyleCopy
	mov	dx, CA_NULL_ELEMENT
	jb	copyCommon
copyNoStyle:
	mov	dx, runTokenAtAreaStart
copyCommon:
	mov	bx, baseStyleIfNone
	call	CopyTransferElement	;bx = token
	LONG jc	toAfterLoop

	;    InsertRun(destRunArray, range.start, newToken)
	;    range.start += (sourceRun+1.pos - sourceRun.pos) - adjustment
	;    destRun++
		;    sourceRun++
	;    adjustment = 0
	; } while (range.start != TEXT_ADDRESS_PAST_END)

	call	TTLoadObjRun
	movdw	dxax, copyRange.VTR_start
	pushdw	dxax
	call	FarRunArrayInsert

	; Since FarRunArrayInsert adds another reference for the element,
	; we now have an extra reference,so delete this extra reference

	call	RemoveElement

	call	FarRunArrayNext

	; if we're not copying style information until we hit a paragraph
	; edge so see if we've hit one yet

	cmpdw	dxax, posToStartStyleCopy
	jb	noLookForParaEdge
	clrdw	dxax
	xchgdw	dxax, posToStartStyleCopy
	tstdw	dxax
	jz	noLookForParaEdge
	mov	valueToPassToCopy, CA_NULL_ELEMENT	;copy with style
	call	insertAtDXAX
noLookForParaEdge:
	popdw	dxax

	; if we're at the point to stop copying style information then
	; deal with that

	cmpdw	dxax, posToEndStyleCopy
	jb	noLookForParaEdgeEnd
	mov	ax, runTokenAtAreaStart
	mov	valueToPassToCopy, ax
	movdw	dxax, TEXT_ADDRESS_PAST_END
	xchgdw	dxax, posToEndStyleCopy
	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH
	jz	noLookForParaEdgeEnd
	call	insertAtDXAX
noLookForParaEdgeEnd:

	call	TTStoreObjRun

	call	TTLoadXferRun
	clr	dx
	mov	dl, ds:[si].TRAE_position.WAAH_high
	mov	ax, ds:[si].TRAE_position.WAAH_low
	pushdw	dxax			;save sourceRun.pos
	call	FarRunArrayNext
	call	TTStoreXferRun
	popdw	cxbx
	subdw	dxax, cxbx				;dxax = diff between
	adddw	dxax, copyRange.VTR_start
	subdw	dxax, adjustment
	clrdw	adjustment
	movdw	copyRange.VTR_start, dxax
	cmpdw	dxax, copyRange.VTR_end
	LONG jb	runLoop

afterLoop:

	; if were dealing with paraAttr runs and if the last run does not point
	; at a C_CR remove it and move its token to the previous run

	cmp	runOffset, offset VTI_paraAttrRuns
	jnz	noParaAttrPatch
	tst	insertedRunFlag
	jz	noParaAttrPatch

	; The last paragraph is partially from the inserted data and partially
	; from the original.  We cannot leave it this way since a paragraph can
	; have only one paraAttr (and the EC code would barf on the run in the
	; middle of a paragraph).

	; We need to move this run that is in the middle of a paragraph back
	; to the start of the last paragraph.

	call	TTLoadObjRun
	clr	dx
	mov	dl, ds:[si].TRAE_position.WAAH_high
	mov	ax, ds:[si].TRAE_position.WAAH_low
	call	TTLoadObject
	stc
	call	TSL_FindParagraphStart		;dxax = paragraph start
	pushdw	dxax

	call	TTLoadObjRun
	popdw	dxax
	mov	ds:[si].TRAE_position.WAAH_high, dl
	mov	ds:[si].TRAE_position.WAAH_low, ax
	call	FarRunArrayMarkDirty
noParaAttrPatch:

	; if were dealing with charAttr runs and if the last run does not point
	; at a C_CR then insert a token at the paragraph start

	call	TTLoadXferRun
	call	FarRunArrayUnlock

	; leaves dest file set

	call	TTLoadObjRun
	call	FarRunArrayUnlock

	call	TTLoadObject

	mov	bx, runOffset
	cmp	bx, OFFSET_FOR_GRAPHIC_RUNS
	jz	noCoalesce
	call	CoalesceRun
noCoalesce:

	mov	dx, optBlock

	.leave
	ret

insertAtDXAX:
	call	TTStoreObjRun
	pushdw	dxax
	mov	dx, valueToPassToCopy
	mov	cx, 1			;mark "from"
	mov	bx, baseStyleIfNone
	call	CopyTransferElement
	popdw	dxax
	call	TTLoadObjRun
	call	FarRunArrayInsert
	call	FarRunArrayNext
	retn

TA_CopyRunFromTransfer	endp

;---

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadCopyRunParams

DESCRIPTION:	Load parameters for TA_CopyRunToTransfer and
		TA_CopyRunFromTransfer

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ax - transfer file
	bx - offset of run in text object
	cx - xfer run vm block
	dx - optimization block (or 0 to allocate)
	ss:bp - VisTextRange in source to copy

RETURN:
	parameters - set

DESTROYED:
	ax, bx, cx, dx, si, di, ds

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
LoadCopyRunParams	proc	near
TRANS_PARAMS
	class	VisTextClass
	.enter inherit near

	mov	xferFile, ax
	mov	optBlock, dx
	mov	transferHeader, di

	xchg	bx, di
	call	MemDerefES
	xchg	bx, di

	mov	runOffset, bx
	mov	di, ss:[bp]
	movdw	copyRange.VTR_start, ss:[di].VTR_start, ax
	movdw	copyRange.VTR_end, ss:[di].VTR_end, ax

	mov	ax, ds:[LMBH_handle]
	movdw	textobject, axsi

	push	bx
	call	T_GetVMFile
	mov	objFile, bx
	pop	bx

	push	bp
	lea	bp, ssParams
	clc					;copy all
	call	LoadSSParams
	pop	bp

	mov	ax, es:TTBH_charAttrElements.high
	mov	ssParams.SSP_xferAttrArrays[0*(size StyleChunkDesc)].\
					SCD_vmBlockOrMemHandle, ax
	mov	ax, es:TTBH_paraAttrElements.high
	mov	ssParams.SSP_xferAttrArrays[1*(size StyleChunkDesc)].\
					SCD_vmBlockOrMemHandle, ax
	mov	ax, es:TTBH_styles.high
	mov	ssParams.SSP_xferStyleArray.SCD_vmBlockOrMemHandle, ax
	mov	ax, VM_ELEMENT_ARRAY_CHUNK
	mov	ssParams.SSP_xferAttrArrays[0*(size StyleChunkDesc)].\
					SCD_chunk, ax
	mov	ssParams.SSP_xferAttrArrays[1*(size StyleChunkDesc)].\
					SCD_chunk, ax
	mov	ssParams.SSP_xferStyleArray.SCD_chunk, ax

	clr	ax					;assume char attr
	cmp	bx, offset VTI_charAttrRuns
	jz	gotAttrOffset
	mov	ax, 1
gotAttrOffset:
	mov	styleAttrOffset, ax

	; objRun = GetRunForPosition(objRunArray, copyRange.start)

	push	cx				;save xfer run block
	movdw	dxax, copyRange.VTR_start
	cmp	runOffset, OFFSET_FOR_GRAPHIC_RUNS
	jz	10$
	call	FarGetRunForPosition
	jmp	20$
10$:
	call	GetGraphicRunForPosition
20$:
	call	TTStoreObjRun
	pop	di				;di = xfer run

	; destRun = destRunArray

	mov	bx, xferFile
	mov	ssParams.SSP_xferStyleArray.SCD_vmFile, bx
	mov	ssParams.SSP_xferAttrArrays[0*(size StyleChunkDesc)].\
					SCD_vmFile, bx
	mov	ssParams.SSP_xferAttrArrays[1*(size StyleChunkDesc)].\
					SCD_vmFile, bx
	call	TransRunArrayLock
	call	TTStoreXferRun

	.leave
	ret

LoadCopyRunParams	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyTransferElement

DESCRIPTION:	Copy an element to/from a transfer space

CALLED BY:	TA_CopyRunToTransfer, TA_CopyRunFromTransfer

PASS:
	bx - style to be based on if copying with no style
	dx - CA_NULL_ELEMENT to copy style or attribute token to base
	     destination on
	ss:bp - inherited variables

RETURN:
	bx - token
	carry - set if at end of runs

DESTROYED:
	ax, cx, dx, si, di, ds

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
CopyTransferElement	proc	near
TRANS_PARAMS
	class	VisTextClass
	.enter inherit near

	; do {
	;     if ((charAttr or paraAttr) && style array exists) {

	tst	fromTransfer
	jz	10$				;load SOURCE
	call	TTLoadXferRun			;to -> object is source
	jmp	20$
10$:
	call	TTLoadObjRun			;from -> xfer is source
20$:

	cmp	ds:[si].TRAE_position.WAAH_high, TEXT_ADDRESS_PAST_END_HIGH
	jnz	notAtEnd
	stc
	.leave
	ret
notAtEnd:

	mov	ax, ds:[si].TRAE_token		;ax = sourceRun.token
	tst	ssParams.SSP_styleArray.SCD_vmBlockOrMemHandle
	jz	noStyleSheetDest
	tst	ssParams.SSP_xferStyleArray.SCD_vmBlockOrMemHandle
	jz	noStyleSheet
	cmp	runOffset, offset VTI_charAttrRuns
	jz	styleSheet
	cmp	runOffset, offset VTI_paraAttrRuns
	jnz	noStyleSheet
styleSheet:

	;         newToken = StyleSheetCopyElementToTransfer(sourceRun.token)

	push	bp

	; check for a character only style, if which case we always pass
	; CA_NULL_ELEMENT

	cmp	dx, CA_NULL_ELEMENT
	jz	callStyleSheet
	tst	styleAttrOffset
	jnz	callStyleSheet
specialCheck::
	push	ax, si, ds
	mov_tr	bx, ax
	call	GetElementStyle			;ax = style sheet

	lea	si, ssParams
	lea	bx, ss:[si].SSP_styleArray
	jcxz	25$
	lea	bx, ss:[si].SSP_xferStyleArray
25$:
	call	StyleSheetLockStyleChunk	;*ds:si = style array
						;carry = value to pass to unlock
	pushf
	call	ChunkArrayElementToPtr
	test	ds:[di].TSEH_privateData.TSPD_flags,
						mask TSF_APPLY_TO_SELECTION_ONLY
	jz	notCharOnlyStyle
	mov	dx, CA_NULL_ELEMENT
notCharOnlyStyle:
	popf
	call	StyleSheetUnlockStyleChunk
	pop	ax, si, ds

callStyleSheet:
	call	TTLoadObject
	mov	bx, styleAttrOffset
	mov	cx, fromTransfer
	mov	di, optBlock
	lea	bp, ssParams
	call	StyleSheetCopyElement
	pop	bp
	mov	optBlock, di
	jmp	gotToken				;bx = token

noStyleSheetDest:

	; since there are no style sheets in the destination space we always
	; want to have the base style be NULL

	mov	bx, CA_NULL_ELEMENT

noStyleSheet:

	;     } else {
	;	 temp = GetElement(sourceRunArray, sourceRun.token)

	sub	sp, size VisTextMaxParaAttr
	mov	dx, sp
	push	bp
	push	bx				;save style
	push	runOffset
	mov	bp, dx
	mov_tr	bx, ax				;bx = token
	call	GetElement
	pop	ax				;ax = run offset
	pop	bx				;bx = style (if applicable)
	cmp	ax, offset VTI_charAttrRuns
	jz	stuffStyle
	cmp	ax, offset VTI_paraAttrRuns
	jnz	noStuffStyle
	mov	dx, bp
stuffStyle:
	mov	ss:[bp].SSEH_style, bx
noStuffStyle:
	pop	bp

	tst	fromTransfer
	jz	50$				;load DEST
	call	TTLoadObjRun			;from -> object is dest
	mov	bx, objFile			;bx = dest file
	mov	cx, xferFile			;cx = source file
	jmp	60$
50$:
	call	TTLoadXferRun			;to -> xfer is dest
	mov	bx, xferFile			;bx = dest file
	mov	cx, objFile			;cx = source file
60$:

	; if the element is a type then we must copy the names in (or
	; ensure that it already exists)

	cmp	runOffset, OFFSET_FOR_TYPE_RUNS
	jnz	notTypeElement

	push	di
	mov	di, dx
	call	TypeRunCopyNames
	pop	di

notTypeElement:

	;	 newToken = AddElement(destRunArray, element)

	push	bp
	cmp	runOffset, OFFSET_FOR_GRAPHIC_RUNS
	jnz	notGraphicElement
	push	fromTransfer
	mov	bp, dx				;ss:bp = element
	mov	dx, cx				;dx = source file (bx = dest)
	tst	ss:[bp].VTG_vmChain.high	;if graphic is stored in lmem
	jnz	gotGraphicToCopy		;then zero it out
	clr	ss:[bp].VTG_vmChain.low
gotGraphicToCopy:
	call	AddGraphicElement		;bx = token
	pop	cx				;cx = frpm transfer flag
	jnc	common
	tst	cx
	jnz	common

	; we copied a graphic to a transfer file -- link it into the chain

	movdw	dxdi, ss:[bp].VTG_vmChain
	pop	bp
	add	sp, size VisTextMaxParaAttr
	push	bx
	mov	bx, transferHeader
	call	MemDerefDS
	inc	ds:TTBH_meta.VMCT_count
	mov	si, ds:TTBH_meta.VMCT_count
	shl	si
	shl	si
	add	si, ds:TTBH_meta.VMCT_offset

	; test for resize needed

	mov	ax, MGIT_SIZE
	call	MemGetInfo			;ax = size
	cmp	ax, si
	jae	noRealloc
	mov	ax, si
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc
	mov	ds, ax
noRealloc:
	movdw	<ds:[si-(size dword)]>, dxdi
	pop	bx
	jmp	commonAfterPop

notGraphicElement:
	mov	bp, dx				;ss:bp = element
	call	AddElement			;bx = token

common:
	pop	bp
	add	sp, size VisTextMaxParaAttr
commonAfterPop:

gotToken:
	clc
	.leave
	ret

CopyTransferElement	endp

;---

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TypeRunCopyNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the context names from the text object to the 
		clipboard, or vice versa

CALLED BY:	CopyTransferElement
PASS:		ds:si	= current TextRunArrayElement
		ss:di	= VisTextType assoc. w/ the current TextRunArrayElement

RETURN:		the passed VisTextType may be possibly changed.
DESTROYED:	
SIDE EFFECTS:	ds gets updated if the block moves.

PSEUDO CODE/STRATEGY:

	fileToken = -1;	
	// the VTND_file of the first element in Name Array is always
	// -1(current file).  This is true because we handle 
	// VTT_hyperlinkFile before VTT_hyperlinkName (i.e. in the
	// name array,  the element that contains the context
	// associated w/ the file "foo" always comes after the element
	// that contains "foo", this is the reason we check 
	// VTT_hyperlinkFile before VTT_hyperlinkName)

	while (a VTT field contains a name element token) {
		if(CopyFromTextObjectToClipboard) {
			Get the name element from the text object;

			// now see if element is a context element
			// if true, then update its VTND_file to the
			// the name token of the file element
			if(the element's VTND_file != -1) {
				the element's VTND_file = fileToken;
			}
			new name token = Clipboard NameArrayAdd(element);
			fileToken = new name token;
		} else { // CopyFromClipboardToTextObject
			Get the name element from the clipboard;

			// now see if element is a context element
			// if true, then update its VTND_file to the
			// the name token of the file element
			if(the element's VTND_file != -1) {
				the element's VTND_file = fileToken;
			}
			new name token = TextObject NameArrayAdd(element);
			fileToken = new name token;
			send notification to the name list;
		}
	}

	Important Concept: We always define a file before defining a
	context for that file.  Thus, the file element is always
	before the context element in the Name array.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Edwin	3/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TypeRunCopyNamesNameType	etype	byte
TRCNNT_HYPERLINK_FILE		enum 	TypeRunCopyNamesNameType
TRCNNT_HYPERLINK_NAME		enum 	TypeRunCopyNamesNameType
TRCNNT_CONTEXT			enum 	TypeRunCopyNamesNameType

TypeRunCopyNames	proc	near
TRANS_PARAMS
	class	VisTextClass
	uses	ax, bx,cx,dx,si,di,bp,es

	push	ds:[LMBH_handle]
	.enter inherit near

	mov	fileToken, -1		; Stores an initial value for
					; the file.
	;
	; check whether there is a name element to insert
	;
	mov	dx, TRCNNT_HYPERLINK_FILE	; add a file name
	mov	ax, ss:[di].VTT_hyperlinkFile
	cmp	ax, -1
	jnz	insert
	mov	dx, TRCNNT_HYPERLINK_NAME	; add a hyperlink name
	mov	ax, ss:[di].VTT_hyperlinkName
	cmp	ax, -1
	jnz	insert
	mov	dx, TRCNNT_CONTEXT		; add a context name
	mov	ax, ss:[di].VTT_context
	cmp	ax, -1
	jnz	insert
	jmp	quit				; no name element to insert

insert:
	;
	; Add a name element for the hyperlink file, hyperlink name, or
	; context to the destination Name array.
	;
	push	dx			; save which VTT field will be modified
	push	di
	push	bp

	tst	fromTransfer
	LONG jnz	CopyFromClipboardToTextObject
	;
	;  CopyFromTextObjectToClipboard (from -> clipboard is dest)
	;
	call	TTLoadObject	
	push	ax			; save the name token of the VTI field
	call	FarLockNameArray	; *ds:si = text object's name array
	pop	ax			; restore the value of VTT field
	push	bx			; save the value for unlock name array
	call	ChunkArrayElementToPtr	; ds:di = VisTextNameArrayElement 
	;
	; Make sure the merde-filled element is actually in use before
	; trying to use it.  Otherwise the element size is 3, and the
	; manipulations below will result in a negative (ie. large positive
	; size), which wreaks havoc in NameArrayAdd().
	;
	cmp	ds:[di].VTNAE_meta.NAE_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	LONG je	quitUnlock		; branch if free element
					; cx = element size
	sub	cx, (size VisTextNameArrayElement)	; cx = string size
DBCS <	shr	cx, 1			; cx <- string length
	add	di, (size NameArrayElement)
	;
	;  Now check if the context doesn't belong to *same file*
	;
	cmp	ds:[di].VTND_file, -1
	mov	bx, ds:[di].VTND_file

	je	fine		; jumps if context belongs to *same file*
	mov	bx, fileToken		; Otherwise, update VTND_file of
					;   the context with the new token
					;   for the file that the context
					;   associates with
fine:	;
	;  Push VisTextNameData onto the stack for NameArrayAdd
	;
	push	ds:[di].VTND_helpText.DBGI_item
	push	ds:[di].VTND_helpText.DBGI_group
	push	bx
	push	{word} ds:[di].VTND_type ; push both VTND_type
					 ; & VTND_contextType
	add	di, (size VisTextNameData)
	segmov	es, ds			; es:di = string pointer
	clr	bx			; NameArrayAddFlags
	mov	dx, ss
	mov	ax, sp
	push	cx			; cx = length of the context string
	call	GetClipboardNameArray	; *ds:si - name array
	mov	bp, cx
	pop	cx
	call	NameArrayAdd		; ax = name token
	call	VMUnlock
	add	sp, (size VisTextNameData)

	pop	bx
	call	FarUnlockNameArray

update:	;
	;  Update the name token in the VisTextType element
	;
	pop	bp			; to access local var in TRANS_PARAMS
	pop	di
	pop	dx			; see which field we need to modify
	mov	fileToken, ax		; save the new file name token

	cmp	dx, TRCNNT_HYPERLINK_FILE
	jne	cntxt2
	mov	ss:[di].VTT_hyperlinkFile, ax

	mov	ax, ss:[di].VTT_hyperlinkName
	cmp	ax, -1			; is there a hyperlinkName to add?
	je	quit			;   No? How can this happen?
	mov	dx, TRCNNT_HYPERLINK_NAME
	jmp	insert			; add the hyperlinkName to Name array
cntxt2:
	cmp	dx, TRCNNT_HYPERLINK_NAME
	jne	cntxt3
	mov	ss:[di].VTT_hyperlinkName, ax
	;
	; Can a type element have both a hyperlink and a context?
	;
	mov	ax, ss:[di].VTT_context
	cmp	ax, -1
	LONG je	quit
	mov	dx, TRCNNT_CONTEXT
	jmp	insert			; add context name to the Name array
cntxt3:
EC <	cmp	dx, TRCNNT_CONTEXT				>
EC <	LONG jne	quit					>
	mov	ss:[di].VTT_context, ax

quit:
	.leave
	pop	bx
	call	MemDerefDS
	ret

quitUnlock:
	pop	bx			;bx <- value from FarLockNameArray
	call	FarUnlockNameArray
	pop	bp
	pop	di
	pop	dx
	jmp	quit

CopyFromClipboardToTextObject:		; to -> xfer is 
	push	bp
	call	GetClipboardNameArray	;*ds:si = name array of the clipboard
	push	cx			;    cx = value for VMUnlock
	call	ChunkArrayElementToPtr	; ds:di = element
	;
	; Make sure the merde-filled element is actually in use.
	;
EC <	cmp	ds:[di].VTNAE_meta.NAE_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT >
EC <	ERROR_E	VIS_TEXT_NAME_NOT_IN_USE_IN_CLIPBOARD			>
	sub	cx, (size VisTextNameArrayElement)
DBCS <	shr	cx, 1							>
	add	di, (size NameArrayElement)

	;
	; Check to see if the file name of this name element is the
	; same as the name of the text object's file.  If so, the
	; name element is not added to the text object's Name array.
	; 
	cmp	ds:[di].VTND_type, VTNT_FILE	; is this a file name element?
	jne	notFile				;
	movdw	bxax, textobject		; check if text object's file
						;  name matches this name
	call	CheckDestFileName		; if yes, don't paste the
	cmp	ax, -1				; does ax = *same file* token?
	je	skip				; if yes, don't add the name
notFile:
	mov	bx, ds:[di].VTND_file
	cmp	bx, -1
	je	fine2
	mov	bx, fileToken

fine2:	;
	;  Push VisTextNameData onto the stack for NameArrayAdd
	;
	push	ds:[di].VTND_helpText.DBGI_item
	push	ds:[di].VTND_helpText.DBGI_group
	push	bx
	push	{word} ds:[di].VTND_type ; push both VTND_type
					 ; & VTND_contextType
	add	di, (size VisTextNameData)
	segmov	es, ds			; es:di string pointer

	call	TTLoadObject		; from -> object is dest
	call	FarLockNameArray	; *ds:si = name array
	mov	bp, bx			; value for unlock name array
	clr	bx			; NameArrayAddFlags
	mov	dx, ss
	mov	ax, sp			; dx:ax = data
	call	NameArrayAdd		; ax = name token
	mov	bx, bp
	call	FarUnlockNameArray
	add	sp, (size VisTextNameData)
skip:
	;
	; Unlock the name array
	;
	pop	bp			; bp = value for VMUnlock
	call	VMUnlock
	pop	bp			; bp = point to stack
	jmp	update

TypeRunCopyNames	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetClipboardNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name array of the clipboard

CALLED BY:	TypeRunCopyNames
PASS:		TRANS_PARAMS data structure
RETURN:		*ds:si = name array of the clipboard
		    cx = value for unlock vm block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Edwin	3/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetClipboardNameArray	proc	near
TRANS_PARAMS 
	class	VisTextClass
	uses	ax, dx, bx, bp
	.enter inherit near
	mov	bx, transferHeader
	mov	si, VM_ELEMENT_ARRAY_CHUNK
	call	MemDerefDS
	mov	ax, ds:TTBH_names.high	;ax = vm handle of name array
					;     of the clipboard
	mov	bx, xferFile		;bx = vm file of the clipboard
	call	VMLock			;ax = segment of VM block
	mov	ds, ax
	mov	cx, bp
	.leave
	ret

GetClipboardNameArray	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDestFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the file name of the destination
		already exists in the name array of the clipboard
		

CALLED BY:	TypeRunCopyNames
PASS:		ds:di = name array element
		bxax = optr of textobj
		cx = length of the name associated w/ the name array element
RETURN:		ax = -1 if the file name of current GeoWrite exists in
		     the name array of the clipboard
		ax = 0 otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		(note for TypeRunCopyNames:
		If the file name of the destination already exists in
		the name array of the clipboard, TypeRunCopyNames will
		not add the name element to the destination file.  
		TypeRunCopyNames will change the name token that 
		associates with the file name to the *same file* token (-1)
		in the type elements before adding them to the destination
		name array.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Edwin	3/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDestFileName	proc	near
buffer		local	FileLongName
nameAddr	local	fptr.char
nameLen		local	word
	class	VisTextClass
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter 

	mov	nameAddr.high, ds
	add	di, (size VisTextNameData)
	mov	nameAddr.low, di	; *nameAddr = string
	mov	nameLen, cx		; nameLen = length of string

	mov	{word}buffer, 0		; put an emptry string in buffer
		
	push	bp
	pushdw	bxax
	mov	cx, ss
	lea	dx, buffer
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage

	popdw	bxsi			; ^lbx:si <- text object
	call	MemDerefDS
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	mov	cx, di
	call	ObjCallInstanceNoLock	; now buffer contains file name
	pop	bp			; of the current GeoWrite file

	segmov	es, ss, ax
	lea	di, buffer		; es:di <- file name
	call	LocalStringLength	; cx = # chars, not counting null

	mov	ax, 0			; assume names are not the same
	cmp	cx, nameLen
	jne	exit			; exit if file names are not equal

	segmov	ds, ss, ax
	mov	si, di			; ds:si = file name of GeoWrite doc 
	les	di, nameAddr		; es:di = file name from name array
	call	LocalCmpStrings
	jnz	exit
	mov	ax, -1			; token of the current file
exit:
	.leave
	ret
CheckDestFileName	endp

;---

TTStoreXferRun	proc	near
TRANS_PARAMS
	.enter inherit near
	movdw	xferRunPtr, dssi
	mov	xferRunCount, cx
	mov	xferRunToken, di
	.leave
	ret
TTStoreXferRun	endp

TTStoreObjRun	proc	near	uses bx
TRANS_PARAMS
	.enter inherit near
	call	RunArrayUnref
	mov	objRunDataBX, bx
	mov	objRunDataSI, si
	mov	objRunDataDI, di
	mov	objRunCount, cx
	.leave
	ret
TTStoreObjRun	endp

TTLoadXferRun	proc	near	uses bx
TRANS_PARAMS
	.enter inherit near
	movdw	dssi, xferRunPtr
	mov	di, xferRunToken
	mov	cx, xferRunCount
	.leave
	ret
TTLoadXferRun	endp

TTLoadObjRun	proc	near	uses bx
TRANS_PARAMS
	.enter inherit near
	mov	bx, objRunDataBX
	mov	si, objRunDataSI
	mov	di, objRunDataDI
	call	RunArrayReref
	mov	cx, objRunCount
	.leave
	ret
TTLoadObjRun	endp

TTLoadObject	proc	near	uses bx
TRANS_PARAMS
	.enter inherit near
	movdw	bxsi, textobject
	call	MemDerefDS
	.leave
	ret
TTLoadObject	endp

TextTransfer ends
