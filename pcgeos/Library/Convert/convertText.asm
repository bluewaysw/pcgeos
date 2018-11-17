COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Convert
FILE:		convertText.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains utility stuff for converting from 1.X to 2.0

	$Id: convertText.asm,v 1.1 97/04/04 17:52:42 newdeal Exp $

------------------------------------------------------------------------------@

ConvertText segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertOldTextTransfer

DESCRIPTION:	Convert a 1.X text transfer format to 2.0

CALLED BY:	INTERNAL

PASS:
	si - VM file handle
	cx - text transfer format
	dx - non-zero to free old 1.2 transfer format

RETURN:
	ax - 2.0 text transfer format

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/30/92		Initial version

------------------------------------------------------------------------------@
ConvertOldTextTransfer	proc	far	uses bx, cx, dx, si, di, ds, es
fileHandle	local	word			push	si
oldTransfer	local	word			push	cx
freeFlag	local	word			push	dx
storageFlags	local	VisTextStorageFlags
oldObject	local	optr
vmMemHandle	local	word
	.enter

	mov	storageFlags, 0

	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	MemAllocLMem
	call	MemLock
	mov	ds, ax
	mov	cx, size OldVisTextInstance
	call	LMemAlloc
	movdw	oldObject, bxax
	mov_tr	di, ax
	mov	di, ds:[di]
	mov	ds:[di].OVTI_typeFlags, 0
	;
	; hack here to allow ConvertOldTextObject to do a
	;	add	di, ds:[di].Vis_offset
	; and have no effect
	mov	ds:[di].Vis_offset, 0
	;
	; make sure that we won't be using this part of the OldVisTextInstance
	;
.assert (offset OVTI_text ne offset Vis_offset)
.assert (offset OVTI_rulerRuns ne offset Vis_offset)
.assert (offset OVTI_gstringRuns ne offset Vis_offset)
.assert (offset OVTI_styleRuns ne offset Vis_offset)

	; lock the transfer item and copy the chunks

	mov	bx, si
	mov	ax, oldTransfer
	push	bp
	call	VMLock
	mov	es, ax
	mov_tr	ax, bp
	pop	bp
	mov	vmMemHandle, ax

	mov	si, es:[OTTBH_text]
	mov	bx, offset OVTI_text
	mov	dx, -1				; null-terminate chunk
	call	copyChunk

	mov	si, es:[OTTBH_styleRuns]
	tst	si
	jz	noStyles
	mov	bx, offset OVTI_styleRuns
	call	copyRunArray
	mov	di, oldObject.chunk
	mov	di, ds:[di]
	ornf	ds:[di].OVTI_typeFlags, mask OVTTF_MULTIPLE_STYLES
	ornf	storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS
noStyles:

	mov	si, es:[OTTBH_rulerRuns]
	tst	si
	jz	noRulers
	mov	bx, offset OVTI_rulerRuns
	call	copyRunArray
	mov	di, oldObject.chunk
	mov	di, ds:[di]
	ornf	ds:[di].OVTI_typeFlags, mask OVTTF_MULTIPLE_RULERS
	ornf	storageFlags, mask VTSF_MULTIPLE_PARA_ATTRS
noRulers:

	mov	di, oldObject.chunk		; in case no graphic runs
	mov	di, ds:[di]
	clr	ds:[di].OVTI_gstringRuns
	mov	si, es:[OTTBH_gstringRuns]
	tst	si
	jz	noGraphics
	mov	bx, offset OVTI_gstringRuns
	call	copyRunArray
	ornf	storageFlags, mask VTSF_GRAPHICS
noGraphics:

	; unlock the transfer item and free it if so directed

	push	bp
	mov	bp, vmMemHandle
	call	VMUnlock
	pop	bp

	; copy the text

	mov	bx, fileHandle
	mov	al, storageFlags		;al = VisTextStorageFlags
	clr	ah				;no regions
	call	TextAllocClipboardObject	;bxsi = new object
	movdw	cxdx, bxsi

	mov	di, CA_NULL_ELEMENT
	mov	si, oldObject.chunk
	push	bp
	mov	bp, fileHandle
	call	ConvertOldTextObject
	pop	bp

	movdw	bxsi, cxdx
	mov	ax, TCO_RETURN_TRANSFER_FORMAT
	call	TextFinishWithClipboardObject		;ax = format

	push	ax
	mov	bx, fileHandle
	tst	freeFlag
	jz	noFree
	mov	ax, oldTransfer
	push	bp
	clr	bp
	call	VMFreeVMChain
	pop	bp
noFree:
	mov	bx, oldObject.handle		;free created old text object
	call	MemFree
	pop	ax

	.leave
	ret

	; pass:
	;	*es:si = source
	;	ds = destination
	;	bx = offset in instance to store new chunk

copyRunArray:
	push	bp
	clr	dx				; don't null-terminate
	call	copyChunk			; *ds:di = new RunArray
	mov	bp, di				; *ds:bp = new RunArray
	mov	di, ds:[bp]			; ds:di = new RunArray
	;
	; copy element array chunk, if any
	;
						; *es:si=old ElementArray chunk
	mov	si, ds:[di].RA_elementArrayChunk
	tst	si
	jz	afterElementArray
EC <	tst	ds:[di].RA_elementArrayHandle	; must be in same block! >
EC <	ERROR_NZ	CONVERT_ERROR					>
	clr	bx				; don't store new chunk
	clr	dx				; don't null-terminate
	call	copyChunk			; di = new ElementArray chunk
	mov	si, di				; si = new ElementArray chunk
afterElementArray:
	mov	di, ds:[bp]			; ds:di = new RunArray
	mov	ds:[di].RA_elementArrayChunk, si	; save new EA chunk
							; (= 0 if no old one)
	;
	; copy name array chunk, if any
	;
	mov	si, ds:[di].RA_nameArrayChunk	; *es:si = old nameArray chunk
	tst	si
	jz	afterNameArray
EC <	tst	ds:[di].RA_nameArrayHandle	; must be in same block! >
EC <	ERROR_NZ	CONVERT_ERROR					>
	clr	bx				; don't store new chunk
	clr	dx				; don't null-terminate
	call	copyChunk			; di = new nameArray chunk
	mov	si, di				; si = new nameArray chunk
afterNameArray:
	mov	di, ds:[bp]			; ds:di = new RunArray
	mov	ds:[di].RA_nameArrayChunk, si	; save new nameArary chunk
							; (= 0 if no old one)
	pop	bp
	retn

	; pass:
	;	*es:si = source
	;	ds = destination
	;	bx = offset in instance to store new chunk
	;		(bx = 0 to not store new chunk handle)
	;	dx = non-zero to null-terminate chunk
	; return:
	;	di = new chunk

copyChunk:

	; allocate chunk

	ChunkSizeHandle	es, si, cx
	tst	dx
	jz	dontNullTerm
	inc	cx				;make room for null
dontNullTerm:
	call	LMemAlloc

	; store chunk handle

	mov	di, oldObject.chunk
	mov	di, ds:[di]
	tst	bx
	jz	noStore
	mov	ds:[di][bx], ax
noStore:
	push	ax				;save new chunk handle

	; copy data

	segxchg	ds, es
	mov	si, ds:[si]			;ds:si = source
	mov_tr	di, ax
	mov	di, es:[di]
	rep	movsb
	tst	dx
	jz	dontNullTerm2
	mov	{byte} es:[di-1], 0		;null-terminate
dontNullTerm2:
	segxchg	ds, es

	pop	di				;return new chunk
	retn

ConvertOldTextTransfer	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertOldTextObject

DESCRIPTION:	Convert a 1.X text object

CALLED BY:	INTERNAL

PASS:
	*ds:si - 1.X text object to convert
	cxdx - 2.0 text object to append text to
	di - style for text to be based on (CA_NULL_ELEMENT if the destination
	     has no styles)
	bp - VM file handle

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
	Tony	10/18/92		Initial version

------------------------------------------------------------------------------@
ConvertOldTextObject	proc	far	uses bx, cx, dx, si, ds, es

	push	ax, di
	mov_tr	ax, di
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

newObject	local	optr		push	cx, dx
newStyle	local	word		push	ax
refRange	local	VisTextRange
oldObject	local	fptr.OldVisTextInstance
setMessage	local	word
elementArrayHan	local	hptr
setAttrParams	local	VisTextSetCharAttrParams
replaceGrParams	local	ReplaceWithGraphicParams
element		local	VisTextMaxParaAttr
	ForceRef newStyle
	ForceRef elementArrayHan
	ForceRef setAttrParams
	ForceRef replaceGrParams
	ForceRef element
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	movdw	oldObject, dsdi

	; suspend the new object

	movdw	bxsi, newObject
	mov	ax, MSG_META_SUSPEND
	call	ObjMessageNoFlags

	; find out how big the new object is

	movdw	refRange.VTR_start, 0
	movdw	refRange.VTR_end, TEXT_ADDRESS_PAST_END
	push	bp
	mov	dx, ss
	lea	bp, refRange
	clr	cx					;no special context
	mov	ax, MSG_VIS_TEXT_GET_RANGE
	call	objMessageCallNoFlags
	pop	bp

	; append the text first

	mov	si, ds:[di].OVTI_text
	mov	cx, ds:[si]				;dscx = text

	; replace C_GRAPHIC with '.'

	mov	si, cx
replLoop:
	lodsb
	tst	al
	jz	replDone
	cmp	al, C_GRAPHIC
	jnz	replLoop
	mov	{char} ds:[si-1], '.'
	jmp	replLoop
replDone:

	movdw	bxsi, newObject
	push	bp
	movdw	dxbp, dscx				;dxbp = text
	clr	cx					;null terminated
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	call	ObjMessageNoFlags
	pop	bp

	; now change the character attributes correctly

	test	ds:[di].OVTI_typeFlags, mask OVTTF_MULTIPLE_STYLES
	jz	afterCharAttr
	mov	si, ds:[di].OVTI_styleRuns
	mov	setMessage, MSG_VIS_TEXT_SET_CHAR_ATTR
	call	CopyOldRun
afterCharAttr:

	movdw	dsdi, oldObject
	test	ds:[di].OVTI_typeFlags, mask OVTTF_MULTIPLE_RULERS
	jz	afterParaAttr
	mov	si, ds:[di].OVTI_rulerRuns
	mov	setMessage, MSG_VIS_TEXT_SET_PARA_ATTR
	call	CopyOldRun
afterParaAttr:

	movdw	dsdi, oldObject
	mov	si, ds:[di].OVTI_gstringRuns
	tst	si
	jz	afterGraphics
	mov	setMessage, MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC
	call	CopyOldRun
afterGraphics:

	; move to the start of the text object

	movdw	bxsi, newObject
	mov	ax, MSG_VIS_TEXT_SELECT_START
	call	ObjMessageNoFlags

	; unsuspend the new object

	mov	ax, MSG_META_UNSUSPEND
	call	ObjMessageNoFlags

	.leave

	pop	di
	call	ThreadReturnStackSpace
	pop	ax, di

	ret

;---

objMessageCallNoFlags:
	push	di
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di
	retn

ConvertOldTextObject	endp

;---

ObjMessageNoFlags	proc	near
	push	di
	clr	di
	call	ObjMessage
	pop	di
	ret
ObjMessageNoFlags	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyOldRun

DESCRIPTION:	Copy the from an old run structure to the new object (for which
		the text has already been added)

CALLED BY:	INTERNAL

PASS:
	*ds:si - old run
	ss:bp - inherited variables

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/20/92		Initial version

------------------------------------------------------------------------------@
CopyOldRun	proc	near
	.enter inherit ConvertOldTextObject

	mov	si, ds:[si]				;dssi = run array
	segmov	es, ds
	mov	ax, ds:[si].RA_elementArrayHandle
	call	RelocToVMBlock
	mov	di, ds:[si].RA_elementArrayChunk
	tst	ax
	jz	sameBlock
	mov	bx, ss:[bp]				;bx = file handle
	push	bp
	call	VMLock
	mov	es, ax					;*es:di = element array
	mov_tr	ax, bp
	pop	bp
sameBlock:
	mov	elementArrayHan, ax
	add	si, size RunArray

	mov	di, es:[di]

	; dssi = run array element, es:di = element array

attrLoop:
	cmp	ds:[si].RAE_position, 0x8000
	LONG jz	attrDone

	push	si, di

	; copy the element

	mov	ax, ds:[si].RAE_token
	cmp	setMessage, MSG_VIS_TEXT_SET_CHAR_ATTR
	jnz	notCharAttr
	call	GetOldCharAttr
	jmp	gotAttr
notCharAttr:
	cmp	setMessage, MSG_VIS_TEXT_SET_PARA_ATTR
	jnz	notParaAttr
	call	GetOldParaAttr
	jmp	gotAttr
notParaAttr:
	call	GetOldGraphic
gotAttr:

	; set up the range

	movdw	dxax, refRange.VTR_end
	add	ax, ds:[si].RAE_position
	adc	dx, 0
	movdw	setAttrParams.VTSCAP_range.VTR_start, dxax
	movdw	setAttrParams.VTSCAP_range.VTR_end, TEXT_ADDRESS_PAST_END
	lea	ax, element
	movdw	setAttrParams.VTSCAP_charAttr, ssax

	mov	ax, setMessage
	movdw	bxsi, newObject
	push	bp
	cmp	ax, MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC
	jz	graphic
	lea	bp, setAttrParams
	jmp	sendMessage
graphic:
	movdw	dxcx, setAttrParams.VTSCAP_range.VTR_start
	movdw	replaceGrParams.RWGP_range.VTR_start, dxcx
	incdw	dxcx
	movdw	replaceGrParams.RWGP_range.VTR_end, dxcx
	mov	replaceGrParams.RWGP_pasteFrame, 0
	mov	replaceGrParams.RWGP_sourceFile, 0
	lea	bp, replaceGrParams
sendMessage:
	call	ObjMessageNoFlags
	pop	bp

	pop	si, di
	add	si, size RunArrayElement
	jmp	attrLoop

attrDone:
	push	bp
	mov	bp, elementArrayHan
	tst	bp
	jz	noUnlock
	call	VMUnlock
noUnlock:
	pop	bp


	.leave
	ret

CopyOldRun	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RelocToVMBlock

DESCRIPTION:	Relocate a word to a VM block handle

CALLED BY:	INTERNAL

PASS:
	ax - word

RETURN:
	ax - VM block handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/20/92		Initial version

------------------------------------------------------------------------------@
RelocToVMBlock	proc	near	uses	dx
	.enter

	tst	ax
	jz	done

	and	ax, mask RID_INDEX
	mov	dx, size VMBlockHandle
	mul	dx
	add	ax, offset VMH_blockTable

done:
	.leave
	ret

RelocToVMBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetOldCharAttr

DESCRIPTION:	Get an old character attribute element

CALLED BY:	INTERNAL

PASS:
	es:di - attribute array
	ss:bp - inherited variables, including buffer for result
	ax - token

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/20/92	Initial version

------------------------------------------------------------------------------@
cElement	equ	<({VisTextCharAttr} element)>

GetOldCharAttr	proc	near	uses di
	.enter inherit ConvertOldTextObject

	; point at the old element

	add	di, ax				;es:di = old element

	; load the default character attribute

	push	bp
	lea	bp, element
	mov	ax, VIS_TEXT_INITIAL_CHAR_ATTR
	call	TextMapDefaultCharAttr
	pop	bp

	; set the style to be based on

	mov	ax, newStyle
	mov	cElement.VTCA_meta.SSEH_style, ax

	; copy attributes

	mov	ax, es:[di].OVTS_font
	mov	cElement.VTCA_fontID, ax

	movwbf	axdl, es:[di].OVTS_pointSize
	movwbf	cElement.VTCA_pointSize, axdl

	mov	al, es:[di].OVTS_textStyle
	mov	cElement.VTCA_textStyles, al

	movdw	bxax, es:[di].OVTS_color
	call	ConvertForegroundColor		;bxax = color, cl = gray screen
	movdw	cElement.VTCA_color, bxax
	mov	cElement.VTCA_grayScreen, cl

	mov	ax, es:[di].OVTS_trackKerning
	mov	cElement.VTCA_trackKerning, ax

	.leave
	ret

GetOldCharAttr	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetOldParaAttr

DESCRIPTION:	Get an old paragraph attribute element

CALLED BY:	INTERNAL

PASS:
	es:di - attribute array
	ss:bp - inherited variables, including buffer for result
	ax - token

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/20/92		Initial version

------------------------------------------------------------------------------@
pElement	equ	<({VisTextParaAttr} element)>

GetOldParaAttr	proc	near	uses di
	.enter inherit ConvertOldTextObject

	; point at the old element

	add	di, size ElementArray		;es:di = first element
findLoop:
	cmp	ax, es:[di].OVTR_token
	jz	gotElement
	clr	cx
	mov	cl, es:[di].OVTR_numberOfTabs
	shl	cx
	shl	cx
	add	cx, size OVisTextRuler
	add	di, cx
	loop	findLoop
gotElement:

	; load the default paragraph attribute

	push	bp
	lea	bp, pElement
	mov	ax, VIS_TEXT_INITIAL_PARA_ATTR
	call	TextMapDefaultParaAttr
	pop	bp

	; set the style to be based on

	mov	ax, newStyle
	mov	pElement.VTPA_meta.SSEH_style, ax

	; ----- copy attributes ------

	; copy border

	mov	ax, es:[di].OVTR_border
	tst	ax
	jnz	5$
	mov	ax, (2 shl offset OVTBF_SPACING)
5$:
	mov	bx, ax
	and	ax, mask VisTextParaBorderFlags	;mask out spacing and shadow
	test	bx, mask OVTBF_SHADOW
	jz	10$
	test	bx, mask OVTBF_DOUBLE
	jnz	10$
	ornf	ax, mask VTPBF_SHADOW
10$:
	mov	pElement.VTPA_borderFlags, ax

	mov	ax, bx
	and	ax, mask OVTBF_WIDTH
				CheckHack <(offset OVTBF_WIDTH gt 3)>
	add	ax, 1 shl offset OVTBF_WIDTH
	mov	cl, (offset OVTBF_WIDTH) - 3	;get points * 8
	shr	ax, cl
	mov	pElement.VTPA_borderWidth, al

	mov	ax, bx
	and	ax, mask OVTBF_SPACING
				CheckHack <(offset OVTBF_SPACING gt 3)>
	mov	cl, (offset OVTBF_SPACING) - 3	;get points * 8
	shr	ax, cl
	mov	pElement.VTPA_borderSpacing, al

	mov	ax, bx
	and	ax, mask OVTBF_SHADOW
				CheckHack <(offset OVTBF_SHADOW lt 3)>
	mov	cl, 3 - (offset OVTBF_SHADOW)	;get points * 8
	shl	ax, cl
	tst	al
	jnz	20$
	mov	al, 1 * 8
20$:
	mov	pElement.VTPA_borderShadow, al

	; copy border color

	movdw	bxax, es:[di].OVTR_borderColor
	call	ConvertForegroundColor		;bxax = color, cl = gray screen
	movdw	pElement.VTPA_borderColor, bxax
	mov	pElement.VTPA_borderGrayScreen, cl

	; copy attributes

 CheckHack <(offset OVTRA_JUSTIFICATION)+8 eq (offset VTPAA_JUSTIFICATION)>

	clr	ax
	mov	ah, es:[di].OVTR_attributes
	mov	bx, ax
	and	ah, mask OVTRA_JUSTIFICATION
	and	pElement.VTPA_attributes, not mask VTPAA_JUSTIFICATION
	or	pElement.VTPA_attributes, ax

	and	bh, mask OVTRA_DEFAULT_TABS
	clr	ax
	cmp	bh, OVTDT_NONE shl offset OVTRA_DEFAULT_TABS
	jz	gotDefaultTabs
	mov	ax, (72 * 8) / 2
	cmp	bh, OVTDT_HALF_INCH shl offset OVTRA_DEFAULT_TABS
	jz	gotDefaultTabs
	mov	ax, 72 * 8
	cmp	bh, OVTDT_INCH shl offset OVTRA_DEFAULT_TABS
	jz	gotDefaultTabs
	mov	ax, 227
gotDefaultTabs:
	mov	pElement.VTPA_defaultTabs, ax

	; copy margins

	mov	ax, es:[di].OVTR_leftMargin
	shl	ax
	shl	ax
	shl	ax
	mov	pElement.VTPA_leftMargin, ax

	mov	ax, es:[di].OVTR_rightMargin
	shl	ax
	shl	ax
	shl	ax
	mov	pElement.VTPA_rightMargin, ax

	mov	ax, es:[di].OVTR_paraMargin
	shl	ax
	shl	ax
	shl	ax
	mov	pElement.VTPA_paraMargin, ax

	; copy line spacing and stuff

	mov	ax, {word} es:[di].OVTR_lineSpacing
	mov	{word} pElement.VTPA_lineSpacing, ax

	mov	ax, es:[di].OVTR_leading
	shl	ax
	shl	ax
	shl	ax
	mov	pElement.VTPA_leading, ax

	mov	ax, {word} es:[di].OVTR_spaceOnTop	;bb fixed
	call	bbFixedTo133
	mov	pElement.VTPA_spaceOnTop, ax

	mov	ax, {word} es:[di].OVTR_spaceOnBottom
	call	bbFixedTo133
	mov	pElement.VTPA_spaceOnBottom, ax

	; copy color

	movdw	bxax, es:[di].OVTR_bgColor
	call	ConvertBackgroundColor		;bxax = color, cl = gray screen
	movdw	pElement.VTPA_bgColor, bxax
	mov	pElement.VTPA_bgGrayScreen, cl

	; copy tabs

	clr	cx
	mov	cl, es:[di].OVTR_numberOfTabs
	jcxz	afterTabs
	mov	pElement.VTPA_numberOfTabs, cl

	push	bp
	add	di, OVTR_tabList		;es:di = old tab list
	lea	bp, element.VTMPA_tabs		;ss:bp = new tab list

tabLoop:
	push	cx
	mov	ax, es:[di].OT_position
	shl	ax
	shl	ax
	shl	ax
	mov	ss:[bp].T_position, ax

	clr	ax
	mov	al, es:[di].OT_attr
	mov	bx, ax
	and	al, mask OTA_TYPE or mask OTA_LEADER	;al = type and leader
	mov	ss:[bp].T_attr, al

	mov	ax, bx
				CheckHack <(offset OTA_LINE_WIDTH gt 3)>
	and	al, mask OTA_LINE_WIDTH
	mov	cl, (offset OTA_LINE_WIDTH) - 3
	shr	ax, cl
	mov	ss:[bp].T_lineWidth, al

	mov	ax, bx
				CheckHack <(offset OTA_LINE_SPACING gt 3)>
	and	al, mask OTA_LINE_SPACING
	mov	cl, (offset OTA_LINE_SPACING) - 3
	shr	ax, cl
	mov	ss:[bp].T_lineSpacing, al

	mov	ss:[bp].T_grayScreen, SDM_100
	mov	ss:[bp].T_anchor, '.'

	pop	cx
	add	di, size OTab
	add	bp, size Tab
	loop	tabLoop
	pop	bp

afterTabs:

	.leave
	ret

	; value in ax

bbFixedTo133:
	shr	ax
	shr	ax
	shr	ax
	shr	ax
	shr	ax
	retn

GetOldParaAttr	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetOldGraphic

DESCRIPTION:	Get an old graphic element

CALLED BY:	INTERNAL

PASS:
	es:di - attribute array
	ss:bp - inherited variables, including buffer for result
	ax - token

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/20/92		Initial version

------------------------------------------------------------------------------@
GetOldGraphic	proc	near	uses si, di
	.enter inherit ConvertOldTextObject

	; point at the old element

	add	di, ax				;es:di = old element

	; load the default graphic

	mov	si, offset defaultGStringGraphic
	cmp	es:[di].OVTG_type, OVTGT_GSTRING_METHOD
	jnz	10$
	mov	si, offset defaultPageNumberGraphic
10$:

	push	di, ds, es
	segmov	es, ss
	lea	di, replaceGrParams.RWGP_graphic
	segmov	ds, cs
	mov	cx, (size VisTextGraphic) / 2
	rep	movsw
	pop	di, ds, es

	cmp	es:[di].OVTG_type, OVTGT_GSTRING_METHOD
	jz	done

	; this is a gstring based graphic

	mov	ax, es:[di].OVTG_size.XYS_width
	mov	replaceGrParams.RWGP_graphic.VTG_size.XYS_width, ax
	mov	ax, es:[di].OVTG_size.XYS_height
	mov	replaceGrParams.RWGP_graphic.VTG_size.XYS_height, ax

	push	di
	mov	cx, ss:[bp]			;cx = file
	mov	di, es:[di].OVTG_data.OVTGD_vm.OVTGGVM_block
	mov	dx, cx
	clr	si				;don't free original
	call	ConvertGString
	mov_tr	ax, di				;ax = new VM chain
	pop	di
EC <	ERROR_C	CONVERT_ERROR						>
	mov	replaceGrParams.RWGP_graphic.VTG_vmChain.high, ax

done:
	.leave
	ret

GetOldGraphic	endp

defaultGStringGraphic	VisTextGraphic <
    <				;VTG_meta.
	<>,			;    REH_refCOunt
    >,
    0,				;VTG_vmChain
    <0, 0>,			;VTG_size
    VTGT_GSTRING,		;VTG_type
    <>,				;VTG_flags
    <>,				;VTG_reserved
    <VTGD_gstring <		;VTG_data
	<>
    >>
>

defaultPageNumberGraphic	VisTextGraphic <
    <				;VTG_meta.
	<>,			;    REH_refCOunt
    >,
    0,				;VTG_vmChain
    <0, 0>,			;VTG_size
    VTGT_VARIABLE,		;VTG_type
    mask VTGF_DRAW_FROM_BASELINE, ;VTG_flags
    <>,				;VTG_reserved
    <VTGD_variable <		;VTG_data
	MANUFACTURER_ID_GEOWORKS,
	VTVT_PAGE_NUMBER,
	<VTNT_NUMBER>
    >>
>

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertForegroundColor

DESCRIPTION:	Convert and old color to a new color

CALLED BY:	INTERNAL

PASS:
	bxax - old color (OSetColorParams)
	       al = red/index, ah = OVisTextColorMapModes, bl = green, bh = blue

RETURN:
	bxax - new color (ColorQuad)
	       al = red/index, ah = ColorFlag, bl = green, bh = blue
	cl - gray screen (SystemDrawMask)

DESTROYED:
	ch

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/20/92		Initial version

------------------------------------------------------------------------------@
ConvertForegroundColor	proc	near
	mov	ch, ah				;save gray screen

	and	ah, mask OVTCMM_COLOR_FLAG	;biff unneeded flags

	and	ch, mask OVTCMM_GRAY_SCREEN
	mov	cl, SDM_25
	cmp	ch, OVTGS_25 shl offset OVTCMM_GRAY_SCREEN
	jz	gotGrayScreen
	mov	cl, SDM_50
	cmp	ch, OVTGS_50 shl offset OVTCMM_GRAY_SCREEN
	jz	gotGrayScreen
	mov	cl, SDM_75
	cmp	ch, OVTGS_75 shl offset OVTCMM_GRAY_SCREEN
	jz	gotGrayScreen
	mov	cl, SDM_100
gotGrayScreen:

	ret

ConvertForegroundColor	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertBackgroundColor

DESCRIPTION:	Convert and old color to a new color

CALLED BY:	INTERNAL

PASS:
	bxax - old color (OSetColorParams)
	       al = red/index, ah = OVisTextColorMapModes, bl = green, bh = blue

RETURN:
	bxax - new color (ColorQuad)
	       al = red/index, ah = ColorFlag, bl = green, bh = blue
	cl - gray screen (SystemDrawMask)

DESTROYED:
	ch

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/20/92		Initial version

------------------------------------------------------------------------------@
ConvertBackgroundColor	proc	near
	mov	ch, ah				;save gray screen

	and	ah, mask OVTCMM_COLOR_FLAG	;biff unneeded flags

	and	ch, mask OVTCMM_GRAY_SCREEN
	mov	cl, SDM_12_5
	cmp	ch, OVTGS_25 shl offset OVTCMM_GRAY_SCREEN
	jz	gotGrayScreen
	mov	cl, SDM_25
	cmp	ch, OVTGS_50 shl offset OVTCMM_GRAY_SCREEN
	jz	gotGrayScreen
	mov	cl, SDM_50
	cmp	ch, OVTGS_75 shl offset OVTCMM_GRAY_SCREEN
	jz	gotGrayScreen
	mov	cl, SDM_100
gotGrayScreen:

	; a little hack here -- if the color is 100% WHITE, change it to
	; 0%

	cmp	cl, SDM_100
	jnz	noSpecial
	cmp	ah, CF_INDEX
	jnz	noSpecial
	cmp	al, C_WHITE
	jnz	noSpecial
	mov	cl, SDM_0
noSpecial:

	ret

ConvertBackgroundColor	endp

ConvertText ends
