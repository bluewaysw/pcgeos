COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainMetrics.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	BitstreamCharMetrics	return character metrics

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/21/93	Initial version.

DESCRIPTION:
	This file contains GEOS Bitstream Font Driver routines.

	$Id: mainMetrics.asm,v 1.1 97/04/18 11:45:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamCharMetrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return character metrics

CALLED BY:	DR_FONT_CHAR_METRICS - BitstreamStrategy

PASS:		dx - character to get metrics of (Chars)
		ds - segment of font info block (locked)
		es - segment of GState (locked)
			contains:
				GS_fontAttr:
					FCA_fontID	FontID
					FCA_pointSize	WBFixed
					FCA_textStyle	TextStyle
		cx - info to return (GCM_info)

RETURN:		if GCMI_ROUNDED set:
			dx - information (rounded)
		else:
			dx.ah - information (WBFixed)
		carry set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitstreamCharMetrics	proc	far
	uses	cx, si, ds

	push	bx, di
	mov	di, FONT_C_CODE_STACK_SPACE
	call	ThreadBorrowStackSpace
	push	di

savedAX		local	word		push	ax
charToDo	local	word		push	dx
returnInfo	local	GCM_info	push	cx
stylesLeft	local	TextStyle

	.enter

if not DBCS_PCGEOS
EC <	tst	dh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif

	;
	; find FontInfo for specific FontID
	;
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
	stc					; char not found
	jmp	fontNotFound
endif	;=====================================================================


5$:
	sub	di, bx				; subtract table offset
	shr	di, 1
	dec	di				; di = Bitstream direct index
	mov	charToDo, di
if PROC_TYPE1
7$:
endif
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
else	;---------------------------------------------------------------------
	mov	bx, charToDo
	shl	bx, 1
	mov	ax, ds:[si].BOE_xlatTable[bx]
	mov	charToDo, ax
endif	;---------------------------------------------------------------------
	push	ds:[si].BOE_minCharBufSize	; save min char buffer size
	;
	; copy font processor from BitstreamOutlineEntry into fontInstance
	;	ds:si = BitstreamOutlineEntry
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
	;	ds:si = BitstreamOutlineEntry
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
	; generate matrix in fontInstance
	;	es = dgroup
	;	cx = gstate segment
	;
	mov	al, stylesLeft
	call	GenerateMatrix
	;
	; lock global data and font file header
	;	ds = font info seg
	;	es = dgroup
	;
					; es:di = BitstreamFontInstanceID
	lea	di, es:[outputInfo].OI_fontInstance
	mov	al, BB_FALSE			; not outline mode
	call	EnsureGlobalsAndHeader
	pop	dx				; (dx = min char buffer size)
	LONG jc	lockError			; ax = 0 if fontHeaderHandle
						;	and globalsHandle locked
	;
	; lock and reallocate character generation buffer
	;	dx = min char buffer size
	;	es = dgroup
	;
	mov	ax, dx				; ax = min char buffer size
	mov	bx, es:[charGenBufferHandle]
	mov	ch, mask HAF_NO_ERR or mask HAF_LOCK
	call	MemReAlloc			; ax = segment
	mov	es:[charGenBufferSeg], ax
	;
	; call Bitstream code to get character bounds
	;	es = dgroup
	;
	segmov	ds, es				; ds = dgroup
	push	ss
	lea	ax, charToDo
	push	ax
	push	es
	lea	ax, es:[outputInfo].OI_charBounds
	push	ax
	call	fi_get_char_bbox		; ax = TRUE/FALSE
	pop	dx				; remove character from stack
	tst	ax
	stc					; assume error
	jz	bboxError
	;
	; compute return info
	;	ds = dgroup
	;
	mov	si, returnInfo
	andnf	si, not (GCMI_ROUNDED)
	mov	di, cs:[metricTable][si]
						; dx.cx = value
	mov	dx, ({WWFixed}ds:[outputInfo].OI_charBounds[di]).WWF_int
	mov	cx, ({WWFixed}ds:[outputInfo].OI_charBounds[di]).WWF_frac
	mov	di, cs:[metricOffsetTable][si]
	clr	ax
	mov	bx, {word}ds:[outputInfo].OI_fontInstance[di]
	addwwf	dxcx, bxax
	test	returnInfo, GCMI_ROUNDED
	jnz	roundToInt
	rndwwbf	dxcx				; dx.ch = rounded
	mov	savedAX.high, ch		; return in ah
returnIt:
	clc					; else, no error
bboxError:
	;
	; unlock character generation buffer
	;	ds = dgroup
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

	mov	ax, savedAX

	.leave

	pop	di
	call	ThreadReturnStackSpace	; (preserves flags)
	pop	bx, di

	ret

roundToInt:
	;
	; ds = dgroup
	;
	rndwwf	dxcx				; dx = rounded
	jmp	returnIt

BitstreamCharMetrics	endp

.assert (GCMI_MIN_X eq 0)
.assert (GCMI_MIN_Y eq 2)
.assert (GCMI_MAX_X eq 4)
.assert (GCMI_MAX_Y eq 6)

metricTable	label	word
	word	offset BB_xmin
	word	offset BB_ymin
	word	offset BB_xmax
	word	offset BB_ymax

metricOffsetTable	label	word
	word	offset BFIID_scriptX
	word	offset BFIID_scriptY
	word	offset BFIID_scriptX
	word	offset BFIID_scriptY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	builds matrix for DR_FONT_CHAR_METRICS,
		DR_FONT_GEN_PATH and DR_FONT_GEN_IN_REGION 

CALLED BY:	INTERNAL
			BitstreamCharMetrics
			BitstreamGenPath
			BitstreamGenInRegion

PASS:		es - dgroup
			es:[outputInfo].OI_fontInstance
			es:[outputInfo].OI_fontMetrics
		cx - GState
		al - styles to implement

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateMatrix	proc	near
	uses	ds

stylesLeft	local	TextStyle

	.enter

	mov	stylesLeft, al
	mov	ds, cx				; ds = GState
	;
	; initialize matrix
	;
	call	ClearMatrix
	;
	; set scale
	;
	movwbf	dxch, ds:[GS_fontAttr].FCA_pointsize	; dx.cx = point size
	clr	cl
	clr	ax					; bx.ax = grid size
	mov	bx, es:[outputInfo].OI_fontMetrics.BOEM_ORUsPerEm
	call	GrUDivWWFixed				; dx.cx = ptsize/grid
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11, dxcx
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22, dxcx
	;
	; account for bold
	;
if 0
;bold handled with font weight
	test	stylesLeft, mask TS_BOLD
	jz	afterBold
	mov	bx, BOLD_FACTOR_INT
	mov	ax, BOLD_FACTOR_FRAC
	call	GrMulWWFixed
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11, dxcx
afterBold:
endif
	;
	; account for superscript/subscript
	;
	mov	al, stylesLeft
	test	al, mask TS_SUBSCRIPT or mask TS_SUPERSCRIPT
	LONG jz	notScript
	test	al, mask TS_SUBSCRIPT
	jnz	isSubScript
	;
	; superscript positioning
	;
	movwwf	bxax, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22
	mov	cx, 0
	mov	dx, es:[outputInfo].OI_fontMetrics.BOEM_ascent
	add	dx, es:[outputInfo].OI_fontMetrics.BOEM_accent
	call	GrMulWWFixed
	rndwwf	dxcx					; dx = rounded
	push	dx
	clr	cx
	mov	dx, es:[outputInfo].OI_fontMetrics.BOEM_baseAdjust
	call	GrMulWWFixed
	rndwwf	dxcx					; dx = rounded
	push	dx
	movwbf	dxch, ds:[GS_fontAttr].FCA_pointsize	; dx.cx = point size
	clr	cl
	mov	bx, SUPERSCRIPT_OFFSET_INT
	mov	ax, SUPERSCRIPT_OFFSET_FRAC
	call	GrMulWWFixed
	pop	ax
	sub	dx, ax
	pop	ax
	sub	dx, ax
	jmp	finishScript

isSubScript:
	;
	; subscript positioning
	;
	movwbf	dxch, ds:[GS_fontAttr].FCA_pointsize	; dx.cx = point size
	clr	cl
	mov	bx, SUBSCRIPT_OFFSET_INT
	mov	ax, SUBSCRIPT_OFFSET_FRAC
	call	GrMulWWFixed
finishScript:
	inc	dx					; fudge factor
	negwwf	dxcx
	rndwwf	dxcx
	mov	es:[outputInfo].OI_fontInstance.BFIID_scriptY, dx
	;
	; scale for subscript/superscript
	;
	mov	bx, SCRIPT_FACTOR_INT
	mov	ax, SCRIPT_FACTOR_FRAC
	movwwf	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11
	call	GrMulWWFixed
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11, dxcx
	movwwf	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22
	call	GrMulWWFixed
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22, dxcx
notScript:
	;
	; account for italic
	;
	test	stylesLeft, mask TS_ITALIC
	jz	noItalic
	movwwf	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22
	mov	bx, ITALIC_FACTOR_INT
	mov	ax, ITALIC_FACTOR_FRAC
	call	GrMulWWFixed
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_21, dxcx
noItalic:
	;
	; adjust for width and weight
	;	ds - gstate
	;	es - dgroup
	;
	mov	dl, ds:[GS_fontAttr].FCA_width
	cmp	dl, es:[outputInfo].OI_fontMetrics.BOEM_fontWidth
	je	noWidth
	clr	ax, cx
	mov	dh, al
	mov	bh, al
	mov	bl, es:[outputInfo].OI_fontMetrics.BOEM_fontWidth
	call	GrUDivWWFixed			; dx.cx = percentage
	movwwf	bxax, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11
	call	GrMulWWFixed
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11, dxcx
noWidth:

	mov	dl, ds:[GS_fontAttr].FCA_weight
	test	ds:[GS_fontAttr].FCA_textStyle, mask TS_BOLD
	jz	noBoldWeight
	add	dl, BFW_BOLD-BFW_NORMAL
noBoldWeight:
	cmp	dl, es:[outputInfo].OI_fontMetrics.BOEM_fontWeight
	je	noWeight
	clr	ax, cx
	mov	dh, al
	mov	bh, al
	mov	bl, es:[outputInfo].OI_fontMetrics.BOEM_fontWeight
	call	GrUDivWWFixed			; dx.cx = percentage
	movwwf	bxax, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11
	call	GrMulWWFixed
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11, dxcx
noWeight:
	;
	; convert for Bitstream matrix format
	;
	mov	ax, 0					; bx.ax = grid size
	mov	bx, es:[outputInfo].OI_fontMetrics.BOEM_ORUsPerEm
	movdw	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11
	call	GrMulWWFixed
	movdw	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11, dxcx
	movdw	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_12
	call	GrMulWWFixed
	movdw	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_12, dxcx
	movdw	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_21
	call	GrMulWWFixed
	movdw	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_21, dxcx
	movdw	dxcx, es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22
	call	GrMulWWFixed
	movdw	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22, dxcx
	.leave
	ret
GenerateMatrix	endp

ClearMatrix	proc	near
						; es:di = FontMatrix
	lea	di, es:[outputInfo].OI_fontInstance.BFIID_transMatrix
.assert (offset BFIID_scriptY) eq ((offset BFIID_transMatrix)+(size BFIID_transMatrix))
.assert (offset BFIID_heightY) eq ((offset BFIID_scriptY)+(size BFIID_scriptY))
.assert (offset BFIID_scriptX) eq ((offset BFIID_heightY)+(size BFIID_heightY))
.assert (offset BFIID_heightX) eq ((offset BFIID_scriptX)+(size BFIID_scriptX))
	mov	cx, size FontMatrix +\
			(size BFIID_scriptY) + (size BFIID_heightY) +\
			(size BFIID_scriptX) + (size BFIID_heightX)
	clr	al
	rep stosb
	ret
ClearMatrix	endp
