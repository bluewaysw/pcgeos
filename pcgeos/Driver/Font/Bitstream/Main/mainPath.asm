COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainPath.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	BitstreamGenPath	generate path for character

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/21/93	Initial version.

DESCRIPTION:
	This file contains GEOS Bitstream Font Driver routines.

	$Id: mainPath.asm,v 1.1 97/04/18 11:44:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamGenPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	generate path for the outline of character

CALLED BY:	DR_FONT_GEN_PATH - BitstreamStrategy

PASS:		dx - character to generate (Chars)
		ds - segment of font info block (locked)
		di - handle of GState (passed in bx to DR_FONT_GEN_PATH)
		cl - FontGenPathFlags
			FGPF_POSTSCRIPT - transform for use as Postscript
						Type 1 or Type 3 font
			FGPF_SAVE_STATE - do save/restore for GState

RETURN:		none

DESTROYED:	di (on the way here)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitstreamGenPath	proc	far
	uses	ax, cx, dx, si, ds, es

	push	bx, di
	mov	bx, di
	mov	di, FONT_C_CODE_STACK_SPACE
	call	ThreadBorrowStackSpace
	push	di

fontInfoSeg	local	sptr		push	ds
pathFlags	local	word		push	cx
charToDo	local	word		push	dx
gstateHan	local	hptr.GState	push	bx
gstateSeg	local	sptr.GState
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
	mov	gstateSeg, ax
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
	;	bh = SJISEntry (DBCS only)
	;
	segmov	es, dgroup, ax
	mov	ax, ds:[si].BOE_processor
	mov	es:[outputInfo].OI_fontInstance.BFIID_processor, ax
DBCS <	mov	es:[outputInfo].OI_fontInstance.BFIID_SJISEntry, bh	>
DBCS <	mov	al, ds:[si].BOE_kanjiFont				>
DBCS <	mov	es:[outputInfo].OI_kanjiFont, al			>
	;
	; get metrics info from OutlineEntry
	;	ds = BitstreamOutlineEntry
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
	mov	ds, gstateSeg
	mov	si, offset GS_fontAttr		; ds:si = GS_fontAttr
	lea	di, es:[outputInfo].OI_fontInstance.BFIID_fontAttrs
	mov	cx, size BFIID_fontAttrs
	rep movsb
	;
	; initialize output matrix to get ORUs-per-em based output
	;	es = dgroup
	;
	call	ClearMatrix
	mov	ax, es:[outputInfo].OI_fontMetrics.BOEM_ORUsPerEm
	clr	dx				; ax.dx = ORUs per em WWFixed
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_11, axdx
	movwwf	es:[outputInfo].OI_fontInstance.BFIID_transMatrix.FM_22, axdx
	;
	; lock global data and font file header
	;	es = dgroup
	;
	mov	ds, fontInfoSeg
					; es:di = BitstreamFontInstanceID
	lea	di, es:[outputInfo].OI_fontInstance
	mov	al, BB_TRUE			; outline mode
	call	EnsureGlobalsAndHeader
	pop	dx			; (dx = min char buffer size)
	LONG jc	lockError			; ax = 0 if fontHeaderHandle
						;	and globalsHandle locked
	;
	; generate matrix in es:[outputInfo].OI_fontInstance
	;	es = dgroup
	;	dx = min char buffer size
	;
	push	dx
	mov	al, stylesLeft
	mov	cx, gstateSeg
	call	GenerateMatrix
	;
	; save gstate, etc. for output
	;
	mov	bx, gstateHan
	call	MemUnlock
	mov	es:[outputInfo].OI_gstateHan, bx
	mov	al, pathFlags.low
	mov	es:[outputInfo].OI_pathFlags, al
	;
	; lock and reallocate character generation buffer
	;	es = dgroup
	;	(on stack) = min char buffer size
	;
	pop	ax				; ax = min char buffer size
	mov	bx, es:[charGenBufferHandle]
	mov	ch, mask HAF_NO_ERR or mask HAF_LOCK
	call	MemReAlloc			; ax = segment
	mov	es:[charGenBufferSeg], ax
	;
	; call Bitstream code to get character bounds
	;	es = dgroup
	;
	segmov	ds, es				; ds = dgroup
;	push	ss
;	lea	ax, charToDo
;	push	ax
;	push	ds
;	lea	ax, ds:[outputInfo].OI_charBounds
;	push	ax
;	call	fi_get_char_bbox		; ax = TRUE/FALSE
;	pop	dx				; remove character from stack
;	tst	ax
;	jz	noChar
	;
	; call Bitstream code to generate character
	;
	push	ss
	lea	ax, charToDo
	push	ax
	call	fi_make_char
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

BitstreamGenPath	endp
