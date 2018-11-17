COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainChars.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	BitstreamGenChar	build character

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/12/93	Initial version.

DESCRIPTION:
	This file contains GEOS Bitstream Font Driver routines.

	$Id: mainChars.asm,v 1.1 97/04/18 11:45:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamGenChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	generate character

CALLED BY:	DR_FONT_GEN_CHAR - BitstreamStrategy

PASS:		dx - character to build (Chars)
		es - segment of FontBuf (locked)
		ds - segment of font info block (locked)
		bp - segment of GState (locked)
			contains:
				GS_fontHandle	hptr.FontBuf
				GS_fontAttr:
					FCA_fontID	FontID
					FCA_pointSize	WBFixed
					FCA_textStyle	TextStyle

RETURN:		es - segment of FontBuf (locked, possibly moved)
		carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/12/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitstreamGenChar	proc	far
	uses	ax, bx, cx, dx, di, si, ds

	.enter

	mov	di, FONT_C_CODE_STACK_SPACE
	call	ThreadBorrowStackSpace
	push	di

if not DBCS_PCGEOS
EC <	tst	dh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif
	;
	; locate BitstreamCharGenData
	;	es = FontBuf segment
	;	ds = font info block
	;
DBCS <	mov	di, es:[FB_lastChar]					>
DBCS <	sub	di, es:[FB_firstChar]		; di = num chars - 1	>
SBCS <	mov	al, es:[FB_lastChar]					>
SBCS <	sub	al, es:[FB_firstChar]					>
SBCS <	clr	ah							>
SBCS <	mov	di, ax				; di = num chars - 1	>
	inc	di				; di = num chars
	;
	; NOTE: the following is not really an index, but the
	; calculation is identical.
	;
	FDIndexCharTable di, ax			; di = size of CTEs
	add	di, size FontBuf - size CharTableEntry	; es:di = BCGD
	;
	; translate GEOS character into Bitstream direct index
	;	es:di = BitstreamCharGenData
	;	ds = font info block
	;	dx = GEOS character (SBCS)
	;	dx = Unicode character (DBCS)
	;
	push	dx				; save Unicode (DBCS)
						; save GEOS char (SBCS)
scanAgain::
if DBCS_PCGEOS	;------------------------------------------------------------
	mov	ax, dx				; ax = Unicode
						; no xlat for Kanji font
	test	es:[di].BCGD_kanjiFont, mask BKFF_KANJI
	jnz	10$
;sigh, need to translate
;if PROC_TRUETYPE
;	mov	si, es:[di].BCGD_extraData	; *ds:si = BOE
;	mov	si, ds:[si]			; ds:si = BOE
;	cmp	ds:[si].BOE_processor, PROC_TRUE_TYPE
;	je	5$				; no translation needed
;endif
if PROC_TYPE1
	mov	si, es:[di].BCGD_extraData	; *ds:si = BOE
	mov	si, ds:[si]			; ds:si = BOE
	cmp	ds:[si].BOE_processor, PROC_TYPE_1
	je	5$				; no translation needed
endif
	push	es, di
	mov	di, es:[di].BCGD_extraData	; *ds:di = BOE
	segmov	es, ds				; *es:di = BOE
	mov	di, es:[di]			; es:di = BOE
	add	di, offset BOE_xlatTable
	mov	bx, di
	mov	cx, length BOE_xlatTable
	repne scasw
	mov	dx, di				; dx = table offset
	pop	es, di
	stc					; assume not found error
	jne	nonKanjiNotFound		; not found
	sub	dx, bx				; subtract table offset
	shr	dx, 1
	dec	dx				; dx = Bitstream direct index
5$::
	mov	es:[di].BCGD_fontInstID.BFIID_SJISEntry, 0
	jmp	short 20$

nonKanjiNotFound:
if FAST_GEN_WIDTHS
	mov	dx, '.'				; non-Kanji font default
	jmp	scanAgain
else
	pop	ax				; remove character from stack
	jmp	exit
endif

10$:
	call	MapUnicodeCharToSJIS
	jc	mapError
	call	IsToshibaExtendedChar
	jc	mapError
mapped:
	mov	dx, ax
	mov	es:[di].BCGD_fontInstID.BFIID_SJISEntry, dh
20$:
else	;--------------------------------------------------------------------
	mov	bx, dx
	shl	bx, 1
	mov	si, es:[di].BCGD_extraData	; *ds:si = BOE
	mov	si, ds:[si]			; ds:si = BOE
	mov	ax, ds:[si].BOE_xlatTable[bx]
	mov	dx, ax				; dx = translated char
endif	;--------------------------------------------------------------------
	clc					; no error
mapError::
	pop	cx				; cx = Unicode (DBCS)
						; cx = GEOS char (SBCS)
if FAST_GEN_WIDTHS		; only for DBCS
	;
	; use default char on map error
	;
	jnc	noError
	mov	ax, 0x81A1			; SJIS black rectangle!
	test	es:[di].BCGD_kanjiFont, mask BKFF_KANJI
	jnz	haveDefault
	mov	ax, '.'				; SBCS font default
haveDefault:
	push	cx				; stick char back on stack
	jmp	short mapped

noError:
else
	LONG jc	exit
endif
	;
	; lock global data and font file header
	;	es:di = BitstreamCharGenData = BCGD_fontInstID =
	;			BitstreamFontInstanceID
	;	dx = Bitstream direct index (SBCS, DBCS non-Kanji)
	;	dx = SJIS (DBCS Kanji)
	;	cx = Unicode (DBCS)
	;	cx = GEOS char (SBCS)
	;
.assert (offset BCGD_fontInstID) eq 0
	push	dx				; save character
	push	cx				; save Unicode (DBCS)
						; save GEOS char (SBCS)
	mov	al, BB_FALSE			; not outline mode
	call	EnsureGlobalsAndHeader
	pop	cx				; cx = Unicode (DBCS)
						; cx = GEOS char (SBCS)
	pop	dx				; dx = character
	LONG jc	lockError			; ax = 0 if fontHeaderHandle
						;	and globalsHandle locked
	;
	; save info for output routines
	;	es = FontBuf segment
	;	dx = Bitstream direct index (SBCS, DBCS non-Kanji)
	;	dx = SJIS (DBCS Kanji)
	;	bp = GState segment
	;	cx = Unicode (DBCS)
	;	cx = GEOS char (SBCS)
	;
	mov	ds, bp				; ds = GState seg
	mov	bx, ds:[GS_fontHandle]		; ax = FontBuf handle
	segmov	ds, dgroup, ax			; ds = dgroup
	mov	ds:[outputInfo].OI_fontBufHan, bx
	mov	ds:[outputInfo].OI_fontBuf, es
	mov	ds:[outputInfo].OI_character, cx	; save Unicode (DBCS)
							; save GEOS char (SBCS)
	;
	; lock and reallocate character generation buffer
	;	es:di = BitstreamCharGenData
	;	dx = Bitstream direct index (SBCS, DBCS non-Kanji)
	;	dx = SJIS (DBCS Kanji)
	;
	mov	bx, ds:[charGenBufferHandle]
	mov	ch, mask HAF_NO_ERR or mask HAF_LOCK
	mov	ax, es:[di].BCGD_minCharBufSize
	call	MemReAlloc			; ax = segment
	mov	ds:[charGenBufferSeg], ax
	;
	; some more output info
	;	es:di = BitstreamCharGenData
	;	ds = group
	;	dx = Bitstream direct index (SBCS, DBCS non-Kanji)
	;	dx = SJIS (DBCS Kanji)
	;
	mov	ax, es:[di].BCGD_fontInstID.BFIID_scriptY
	mov	ds:[outputInfo].OI_scriptY, ax
	movwbf	ds:[outputInfo].OI_heightY, \
			es:[di].BCGD_fontInstID.BFIID_heightY, ax
	mov	ax, es:[di].BCGD_fontInstID.BFIID_scriptX
	mov	ds:[outputInfo].OI_scriptX, ax
	mov	ax, es:[di].BCGD_fontInstID.BFIID_heightX
	mov	ds:[outputInfo].OI_heightX, ax
DBCS <	mov	al, es:[di].BCGD_fontInstID.BFIID_SJISEntry		>
DBCS <	mov	ds:[outputInfo].OI_fontInstance.BFIID_SJISEntry, al	>
DBCS <	mov	al, es:[di].BCGD_kanjiFont				>
DBCS <	mov	ds:[outputInfo].OI_kanjiFont, al			>
	;
	; call Bitstream code to generate character
	;	ds = dgroup
	;	es = FontBuf
	;	dx = Bitstream direct index (SBCS, DBCS non-Kanji)
	;	dx = SJIS (DBCS Kanji)
	;
	push	dx				; put character on stack
	mov	ax, sp				; ss:ax = character
	push	ss
	push	ax
EC <	call	ECMemVerifyHeap						>
	call	fi_make_char			; ax = TRUE/FALSE
EC <	call	ECMemVerifyHeap						>
	pop	dx				; remove character from stack
	tst	ax
	jz	noChar
unlockAll:
	;
	; unlock character generation buffer
	;	ds = dgroup
	;
	mov	bx, ds:[charGenBufferHandle]
	call	MemUnlock
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
	call	UnlockGlobalsAndHeader
	;
	; return updated FontBuf segment
	;	ds = dgroup
	;
	mov	es, ds:[outputInfo].OI_fontBuf

	clc				; all is apparently well

exit::
	pop	di
	call	ThreadReturnStackSpace	; (preserves flags)

	.leave
	ret

noChar:
	;
	; handle character generation error
	;	all buffers locked
	;
	jmp	short unlockAll

BitstreamGenChar	endp
