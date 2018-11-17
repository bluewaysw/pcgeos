COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainInRegion.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	BitstreamGenChar	build character

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/93	Initial version.

DESCRIPTION:
	This file contains GEOS Bitstream Font Driver routines.

	$Id: mainInRegion.asm,v 1.1 97/04/18 11:44:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamGenInRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	generate character in passed region

CALLED BY:	DR_FONT_GEN_IN_REGION - BitstreamStrategy

PASS:		dx - character to build (Chars)
		ds - segment of font info block (locked)
		cx - RegionPath handle (locked)
		di - handle of GState
			contains:
				GS_fontHandle	hptr.FontBuf
				GS_fontAttr:
					FCA_fontID	FontID
					FCA_pointSize	WBFixed
					FCA_textStyle	TextStyle

RETURN:		nothing

DESTROYED:	di (on the way here)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitstreamGenInRegion	proc	far
	uses	ax, cx, dx, si, ds, es

	push	bx, di
	mov	bx, di
	mov	di, FONT_C_CODE_STACK_SPACE
	call	ThreadBorrowStackSpace
	push	di

regionHan	local	word		push	cx
charToDo	local	word		push	dx
gstateHan	local	hptr.GState	push	bx
stylesLeft	local	TextStyle

	.enter

if not DBCS_PCGEOS
EC <	tst	dh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif

	;
	; find FontInfo for specific FontID
	;
	call	MemLock
	mov	es, ax				; es = gstate
	mov	cx, es:[GS_fontAttr].FCA_fontID	; cx = FontID
	call	FontDrFindFontInfo		; ds:di = FontInfo
EC <	WARNING_NC	BITSTREAM_CANNOT_FIND_FONT_INFO			>
	LONG jnc	fontNotFound
	;
	; find outline data in FontInfo
	;
	mov	al, es:[GS_fontAttr].FCA_textStyle
	mov	ah, es:[GS_fontAttr].FCA_weight
	call	BitstreamFontDrFindOutlineData	; ds:di = OutlineEntry
	mov	stylesLeft, al			; al = styles to implement
	;
	; translate to character Bitstream direct index
	;
	mov	di, ds:[di]			; *ds:di = BitstreamOutlineEntry
	mov	si, ds:[di]			; ds:si = BitstreamOutlineEntry
if DBCS_PCGEOS	;-------------------------------------------------------------
	mov	ax, charToDo			; ax = Unicode
						; no xlat for Kanji font
scanAgain::
	test	ds:[si].BOE_kanjiFont, mask BKFF_KANJI
	jnz	10$
;sigh, need to translate
;if PROC_TRUETYPE
;	cmp	ds:[si].BOE_processor, PROC_TRUE_TYPE
;	je	7$
;endif
if PROC_TYPE1
	cmp	ds:[si].BOE_processor, PROC_TYPE_1
	je	7$
endif
	push	es
	segmov	es, ds
	lea	di, ds:[si].BOE_xlatTable
	mov	bx, di
	mov	cx, length BOE_xlatTable
	repne scasw
	pop	es
	je	5$				; char found
if FAST_GEN_WIDTHS	;=====================================================
	mov	ax, '.'				; non-Kanji font default char
	jmp	scanAgain
mapError:
	mov	ax, 0x81A1			; SJIS black rectangle!
	test	ds:[si].BOE_kanjiFont, mask BKFF_KANJI
	jnz	haveDefault
	mov	ax, '.'				; SBCS font default
haveDefault:
	jmp	short mapped
else	;=====================================================================
mapError:
	mov	bx, gstateHan			; char not found
	call	MemUnlock
	jmp	fontNotFound
endif	;=====================================================================

5$:
	sub	di, bx				; subtract table offset
	shr	di, 1
	dec	di				; di = Bitstream direct index
	mov	charToDo, di
7$::
	mov	bh, 0				; bh = SJISEntry
	jmp	short 20$
10$:
	call	MapUnicodeCharToSJIS
	jc	mapError			; can't map
	call	IsToshibaExtendedChar
	jc	mapError
mapped::
	mov	charToDo, ax
	mov	bh, ah				; bh = SJISEntry
20$:
else	;--------------------------------------------------------------------
	mov	bx, charToDo
	shl	bx, 1
	mov	ax, ds:[si].BOE_xlatTable[bx]
	mov	charToDo, ax
endif	;--------------------------------------------------------------------
	push	ds:[si].BOE_minCharBufSize	; save min char buffer size
	;
	; copy font processor from BitstreamOutlineEntry into fontInstance
	;	bh = SJISEntry (DBCS only)
	;
	push	ds				; save font info seg
	push	es				; save gstate segment
	segmov	es, dgroup, ax
	mov	ax, ds:[si].BOE_processor
	mov	es:[outputInfo].OI_fontInstance.BFIID_processor, ax
DBCS <	mov	es:[outputInfo].OI_fontInstance.BFIID_SJISEntry, bh	>
DBCS <	mov	al, ds:[si].BOE_kanjiFont				>
DBCS <	mov	es:[outputInfo].OI_kanjiFont, al			>
	;
	; get metrics info from OutlineEntry
	;	es = dgroup
	;
	add	si, offset BOE_metrics		; ds:si = BOEMetrics
	lea	di, es:[outputInfo].OI_fontMetrics
	mov	cx, size OI_fontMetrics
	rep movsb
	;
	; copy FontCommonAttrs from GState info fontInstance
	;	es = dgroup
	;
	pop	ds				; ds:si = GS_fontAttr
	mov	si, offset GS_fontAttr
	lea	di, es:[outputInfo].OI_fontInstance.BFIID_fontAttrs
	mov	cx, size BFIID_fontAttrs
	rep movsb
	mov	cx, ds				; cx = gstate segment
	pop	ds				; ds = font info seg
	;
	; generate matrix in es:[outputInfo].OI_fontInstance
	;	es = dgroup
	;	cx = gstate segment
	;
	mov	al, stylesLeft
	call	GenerateMatrix
	;
	; add graphics transform
	;
	mov	bx, gstateHan
	call	RegionAddGraphicsTransform
	;
	; unlock gstate
	;
	mov	bx, gstateHan
	call	MemUnlock
	;
	; set pen pos for region generation
	;	bx = gstate handle
	;
	mov	di, bx				; di = gstate
	call	GrGetCurPos			; ax, bx = position
	call	GrTransform			; device coords
	mov	es:[outputInfo].OI_penPos.P_x, ax
	mov	es:[outputInfo].OI_penPos.P_y, bx
	;
	; pass region segment for output routines
	;
	mov	bx, regionHan
	mov	ax, MGIT_ADDRESS
	call	MemGetInfo			; ax = segment
	mov	es:[outputInfo].OI_regionSeg, ax
	;
	; lock global data and font file header
	;	ds = font info seg
	;	es = dgroup
	;
					; es:di = BitstreamFontInstanceID
	lea	di, es:[outputInfo].OI_fontInstance
	mov	al, BB_TRUE			; not outline mode
	call	EnsureGlobalsAndHeader
	pop	dx				; (dx = min char buffer size)
	LONG jc	lockError			; ax = 0 if fontHeaderHandle
						;	and globalsHandle locked
	;
	; lock and reallocate character generation buffer
	;	es = dgroup
	;	dx = min char buffer size
	;
	mov	ax, dx				; ax = min char buffer size
	mov	bx, es:[charGenBufferHandle]
	mov	ch, mask HAF_NO_ERR or mask HAF_LOCK
	call	MemReAlloc			; ax = segment
	mov	es:[charGenBufferSeg], ax
	;
	; indicate forced region mode
	;
	mov	es:[outputInfo].OI_forceRegion, BB_TRUE
	;
	; some more output info
	;	es = group
	;
	mov	ax, es:[outputInfo].OI_fontInstance.BFIID_scriptY
	neg	ax
	mov	es:[outputInfo].OI_scriptY, ax
	movwbf	es:[outputInfo].OI_heightY, \
			es:[outputInfo].OI_fontInstance.BFIID_heightY, ax
	mov	ax, es:[outputInfo].OI_fontInstance.BFIID_scriptX
	mov	es:[outputInfo].OI_scriptX, ax
	mov	ax, es:[outputInfo].OI_fontInstance.BFIID_heightX
	mov	es:[outputInfo].OI_heightX, ax
	;
	; call Bitstream code to generate character
	;	es = dgroup
	;
	segmov	ds, es				; ds = dgroup
	push	ss
	lea	ax, charToDo
	push	ax
	call	fi_make_char
	mov	ds:[outputInfo].OI_forceRegion, BB_FALSE
	tst	ax
	jz	noChar
unlockAll:
	;
	; unlock character generation buffer
	;
	mov	bx, ds:[charGenBufferHandle]
	call	MemUnlock			; (preserves flags)
	;
	; unlock global data and font file header
	;
	mov	ax, 0				; unlock both buffers
lockError:
	;
	; handle error locking buffers
	;	ax = 0 if fontHeaderHandle and globalsHandle locked
	;	ax <> 0 otherwise
	;	charGenBufferHandle not locked
	;
	call	UnlockGlobalsAndHeader		; (preserves flags)

fontNotFound:

	.leave

	pop	di
	call	ThreadReturnStackSpace
	pop	bx, di

	ret

noChar:
	;
	; handle character gneeration error
	;	(all buffers locked)
	;
	jmp	short unlockAll

BitstreamGenInRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegionAddGraphicsTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add graphics transform to font matrix

CALLED BY:	INTERNAL
			BitstreamGenInRegion

PASS:		es - dgroup
			es:[outputInfo].OI_fontInstance
		bx - handle of locked gstate

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RegionAddGraphicsTransform	proc	near

	uses	ds

tmpMatrix	local	FontMatrix

	.enter

	call	MemDerefDS			; ds = gstate
	movwbf	dxch, ds:[GS_fontAttr].FCA_pointsize
	mov	si, offset GS_TMatrix		; assume no window
	mov	bx, ds:[GS_window]		; bx = window
	tst	bx
	jz	haveMatrix
EC <	call	ECCheckWindowHandle					>
	call	MemPLock
	mov	ds, ax				; ds = window
	mov	si, offset W_curTMatrix
haveMatrix:
	;
	; compute scaled height (script offsets computed in GenerateMatrix)
	;
	push	bx
	clr	cl				; dx.cx = pointsize
	clr	ax				; bx.ax = gridsize
	mov	bx, es:[outputInfo].OI_fontMetrics.BOEM_ORUsPerEm
	call	GrUDivWWFixed			; dx.cx = pointsize/grid
	mov	bx, es:[outputInfo].OI_fontMetrics.BOEM_accent
	add	bx, es:[outputInfo].OI_fontMetrics.BOEM_ascent
	clr	ax
	call	GrMulWWFixed
	movdw	bxax, dxcx			; bx.ax = scaled baselinePos
	movwwf	dxcx, ds:[si].TM_22
	call	GrMulWWFixed
	rndwwbf	dxcx				; dx.ch = rounded
						; heightY
	movwbf	es:[outputInfo].OI_fontInstance.BFIID_heightY, dxch
	movwwf	dxcx, ds:[si].TM_21
	call	GrMulWWFixed
	rndwwf	dxcx				; dx = heightX
	mov	es:[outputInfo].OI_fontInstance.BFIID_heightX, dx
	;
	; flip Y axis to convert from Bitstream to GEOS coordinates
	;
	negwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22

	test	ds:[si].TM_flags, TM_ROTATED
	LONG jnz	rotateStart
afterRotateStart:
	;
	; FM11 = FM11 * GM11
	;
	movwwf	bxax, ds:[si].TM_11
	movwwf	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11
	call	GrMulWWFixed
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11, dxcx
	;
	; FM21 = FM21 * GM11
	;
	movwwf	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_21
	call	GrMulWWFixed
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_21, dxcx
	;
	; FM22 = FM22 * GM22
	;
	movwwf	bxax, ds:[si].TM_22
	movwwf	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22
	call	GrMulWWFixed
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22, dxcx
	;
	; script Y = script Y * GM22
	;
	movwwf	bxax, ds:[si].TM_22
	mov	dx, es:[outputInfo].OI_fontInstance.BFIID_scriptY
	clr	cx
	call	GrMulWWFixed
	rndwwf	dxcx
	mov	es:[outputInfo].OI_fontInstance.BFIID_scriptY, dx

	test	ds:[si].TM_flags, TM_ROTATED
	jnz	rotateEnd
afterRotateEnd:

	pop	bx				; bx = Window handle
	tst	bx
	jz	winReleased
	call	MemUnlockV
winReleased:

	.leave
	ret

rotateStart:
	;
	; save current font matrix into temporary matrix
	;
	movwwf	tmpMatrix.FM_11, \
		  es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11, ax
	movwwf	tmpMatrix.FM_12, \
		  es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_12, ax
	movwwf	tmpMatrix.FM_21, \
		  es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_21, ax
	movwwf	tmpMatrix.FM_22, \
		  es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22, ax
	push	es:[outputInfo].OI_fontInstance.BFIID_scriptY
	jmp	afterRotateStart

rotateEnd:
	;
	; FM12 += FM11 * GM12
	;
	movwwf	bxax, ds:[si].TM_12
	movwwf	dxcx, tmpMatrix.FM_11
	call	GrMulWWFixed
	addwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_12, dxcx
	;
	; FM22 += FM21 * GM12
	;
	movwwf	dxcx, tmpMatrix.FM_21
	call	GrMulWWFixed
	addwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22, dxcx
	;
	; FM21 += FM22 * GM21
	;
	movwwf	bxax, ds:[si].TM_21
	movwwf	dxcx, tmpMatrix.FM_22
	call	GrMulWWFixed
	addwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_21, dxcx
	;
	; update offsets
	;	bx.ax = GM21
	;
	negwwf	bxax				; convert for flipped coords
	pop	dx
	mov	cx, 0
	call	GrMulWWFixed
	rndwwf	dxcx
	mov	es:[outputInfo].OI_fontInstance.BFIID_scriptX, dx
	jmp	afterRotateEnd

RegionAddGraphicsTransform	endp
