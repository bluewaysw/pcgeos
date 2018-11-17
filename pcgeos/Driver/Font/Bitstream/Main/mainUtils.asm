COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainUtils.asm

AUTHOR:		Brian Chin

FUNCTIONS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/6/93		Initial version.

DESCRIPTION:
	This file contains the GEOS Bitstream Font Driver utils.

	$Id: mainUtils.asm,v 1.1 97/04/18 11:45:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureGlobalsAndHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	lock/allocate Bitstream globals and desired font file
		header

CALLED BY:	UTILITY
			BitstreamGenChar
			BitstreamCharMetrics
			BitstreamGenPath
			BitstreamGenInRegion

PASS:		es:di - BitstreamFontInstanceID
		ds - font info block
		al - BB_TRUE for outline mode (only BitstreamGenPath)

RETURN:		carry clear if successful
			fontFileHandle - font file handle updated
			fontHeaderHandle - buffer reallocated
			fontHeaderSeg - buffer segment updated
		carry set if error
			ax = 0 if fontHeaderHandle and globalsHandle locked
			ax <> 0 if fontHeaderHandle and globalsHandle not locked

DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/12/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureGlobalsAndHeader	proc	far

	uses	ds, es, di

fontInfoSeg	local	word	push	ds
resetNeeded	local	BooleanWord
ufeSpecs	local	UFEStruct
gspecs		local	SpecsType
gbuff		local	BuffType

	.enter

	segmov	ds, dgroup, bx
	PSem	ds, bitstreamSem
	mov	resetNeeded, FALSE
	cmp	al, ds:[outputInfo].OI_outlineMode
	je	sameMode
	mov	resetNeeded, TRUE		; mode change, reset needed
	mov	ds:[outputInfo].OI_outlineMode, al
sameMode:
	;
	; compare previously accessed BitstreamFontInstanceID with this one
	;	es:di = this BitstreamFontInstanceID
	;
if PROC_TRUETYPE or PROC_TYPE1
	;
	; save previous font type for cleanup
	;
	mov	ax, ds:[lastFontInstID].BFIID_processor
	mov	ds:[prevFontProc], ax
endif
	mov	si, offset lastFontInstID	; ds:si = last font
	call	CompareFontInstanceIDs		; carry set if diff
	jc	reloadHeader
	;
	; same font, attempt to lock font file header
	;
if PROC_TRUETYPE
	cmp	ds:[lastFontInstID].BFIID_processor, PROC_TRUE_TYPE
	je	afterHeader			; no header for True Type
endif
if PROC_TYPE1
	cmp	ds:[lastFontInstID].BFIID_processor, PROC_TYPE_1
	je	afterHeader			; no header for True Type
endif
if FIXED_FONT_HEADER
	mov	bx, ds:[fontHeaderHandle]
	tst	bx
	jnz	afterHeader
else
	mov	bx, ds:[fontHeaderHandle]
	call	MemLock
	jnc	headerLoaded			; in memory and locked
						; else, discarded
endif
reloadHeader:
	;
	; reload font file header
	;
	mov	cx, ds:[lastFontInstID].BFIID_fontAttrs.FCA_fontID
	mov	al, ds:[lastFontInstID].BFIID_fontAttrs.FCA_textStyle
	mov	ah, ds:[lastFontInstID].BFIID_fontAttrs.FCA_weight
DBCS <	mov	bl, ds:[lastFontInstID].BFIID_SJISEntry			>
	push	ds				; save dgroup
	mov	ds, fontInfoSeg
	call	OpenAndLoadFontFile		; carry set if error
	pop	ds				; ds = dgroup
	mov	ax, -1				; in case error, indicate
						;	fontHeaderHandle not
						;	locked
;	LONG jc	done
;	jmp	short resetForHeader
;report error - brianc 2/8/94
	jnc	resetForHeader
	mov	bx, handle SysNotifyStrings
	call	MemLock
	push	ds
	mov	ds, ax
	mov	si, ds:[(offset fontNotFound1)]	; ds:si = string one
	mov	di, ds:[(offset fontNotFound2)]	; ds:di = string two
	mov	ax, mask SNF_RETRY or mask SNF_EXIT
	call	SysNotify
	pop	ds
	mov	bx, handle SysNotifyStrings
	call	MemUnlock
	test	ax, mask SNF_RETRY
	jnz	reloadHeader			; try again (disk inserted?)
	mov	ax, SST_DIRTY
	call	SysShutdown
	.UNREACHED

headerLoaded:
	cmp	ax, ds:[fontHeaderSeg]		; same address?
	je	afterHeader			; yes, can use it
	mov	ds:[fontHeaderSeg], ax		; save new header address
resetForHeader:
	mov	resetNeeded, TRUE		; indicate reset needed
afterHeader:
if STATIC_GLOBALS
else
	;
	; attempt to lock BitstreamGlobals
	;	ds - dgroup
	;
	mov	bx, ds:[globalsHandle]		; bx = globals block
	call	MemLock
	jnc	globalsLocked
	;
	; reallocate globals
	;
	mov	ax, 0				; same size
	mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
	call	MemReAlloc			; ax = globals segment
	jmp	short globalsMoved

globalsLocked:
	cmp	ax, ds:[sp_global_ptr].segment
	je	afterGlobals
globalsMoved:
	;
	; need to reinitialize
	;	ax = globals segment
	;
	mov	ds:[sp_global_ptr].segment, ax
	mov	ds:[sp_global_ptr].offset, 0
	mov	es, ax
	mov	ax, 0
	mov	di, ax
	mov	cx, size BitstreamGlobals
	rep stosb
	mov	resetNeeded, TRUE
afterGlobals:
endif
	;
	; reset, if needed
	;
	tst_clc	resetNeeded
	LONG jz	done				; carry clear
if PROC_TRUETYPE
	;
	; if PROC_TRUE_TYPE, free memory allocated by malloc
	;	ds = dgroup
	;
	cmp	ds:[prevFontProc], PROC_TRUE_TYPE
	jne	noRelease
	call	FreeSaveMalloc			; release previous mallocs
noRelease:
endif
if PROC_TYPE1
	;
	; if PROC_TYPE1, tr_unload_font(font_ptr)
	;
	cmp	ds:[prevFontProc], PROC_TYPE_1
	jne	noT1Free
	mov	ax, ds:[font_ptr].segment
	tst	ax
	jz	noT1Free
	push	ax
	push	ds:[font_ptr].offset
	call	tr_unload_font
	mov	ds:[font_ptr].segment, 0
noT1Free:
endif
	;
	; fi_reset(BitstreamFontProtocol charmap_protocol,
	;		BitstreamFontProcessor f_type)
	;	ds = dgroup
	;
	mov	bx, PROTO_DIRECT_INDEX
	mov	ax, ds:[lastFontInstID].BFIID_processor
if PROC_TRUETYPE
	cmp	ax, PROC_TRUE_TYPE
	jne	notTT
	mov	bx, PROTO_UNICODE		; this works, don't ask me why
notTT:
endif
if PROC_TYPE1
	cmp	ax, PROC_TYPE_1
	jne	notT1
	mov	bx, PROTO_UNICODE
notT1:
endif
	push	bx
	push	ax
	call	fi_reset
	mov	es, ds:[fontHeaderSeg]		; es:di = font header
	clr	di
if PROC_TRUETYPE
	;
	; if PROC_TRUE_TYPE, tt_load_font(fontHandle)
	;	ds = dgroup
	;	es:di = font header
	;
	cmp	ds:[lastFontInstID].BFIID_processor, PROC_TRUE_TYPE
	jne	notTrueType
	push	es
	clr	ax
	push	ax
	push	ds:[fontFileHandle]		; pass 32-bit version of handle
	call	tt_load_font			; load new font
	pop	es
	tst	ax
	stc					; assume error
	LONG jz	done				; ax=FALSE, error, carry set
notTrueType:
endif
if PROC_TYPE1
	;
	; if PROC_TYPE_1, tr_load_font(&font_ptr)
	;	ds = dgroup
	;
	cmp	ds:[lastFontInstID].BFIID_processor, PROC_TYPE_1
	jne	notType1
	mov	bx, ds:[fontFileHandle]
	clr	cx, dx
	mov	al, FILE_POS_START
	call	FilePos
	push	ds
	mov	ax, offset font_ptr
	push	ax
	call	tr_load_font
	tst	ax
	stc					; assume error
	LONG jz	done				; ax=FALSE, error
	;
	; pass font_ptr in gbuff.BT_org
	;
	mov	es, ds:[font_ptr].segment
	mov	di, ds:[font_ptr].offset
notType1:
endif
	;
	; fi_set_specs(UFEStruct *specs)
	;	ds = dgroup
	;	es:di = font header
	;
	; gbuff.org = font_buffer
	mov	gbuff.BT_org.segment, es
	mov	gbuff.BT_org.offset, di
	; gbuff.no_bytes = fontbuf_size
	mov	ax, ds:[fontHeaderSize]
	mov	gbuff.BT_noBytes.high, 0
	mov	gbuff.BT_noBytes.low, ax
	; gspecs.pfont = &gbuff
	mov	gspecs.ST_pfont.segment, ss
	lea	ax, gbuff
	mov	gspecs.ST_pfont.offset, ax
if PROC_TYPE1
	cmp	ds:[lastFontInstID].BFIID_processor, PROC_TYPE_1
	je	afterMatrix			; Type1 uses Matrix
endif
	; gspecs.xxmult = FM_11
	movdw	gspecs.ST_xxmult, \
		  ds:[lastFontInstID].BFIID_transMatrix.FM_11, ax
	; gspecs.xymult = FM_21
	movdw	gspecs.ST_xymult, \
			ds:[lastFontInstID].BFIID_transMatrix.FM_21, ax
	; gspecs.xoffset = rotation x offset
	mov	ax, 0
						; WWFixed for Speedo
	mov	({WWFixed} gspecs.ST_xoffset).WWF_int, ax
	mov	({WWFixed} gspecs.ST_xoffset).WWF_frac, 0
	; gspecs.yxmult = FM_12
	movdw	gspecs.ST_yxmult, \
			ds:[lastFontInstID].BFIID_transMatrix.FM_12, ax
	; gspecs.yymult = FM_22
	movdw	gspecs.ST_yymult, \
			ds:[lastFontInstID].BFIID_transMatrix.FM_22, ax
	; gspecs.yoffset = super/subscript/rotation y offset
	mov	ax, 0
						; WWFixed for Speedo
	mov	({WWFixed} gspecs.ST_yoffset).WWF_int, ax
	mov	({WWFixed} gspecs.ST_yoffset).WWF_frac, 0
if PROC_TYPE1
afterMatrix:
endif
	; gspecs.flags = MODE_2D
.assert (offset STF_OUTPUT_MODE) eq 0
	clr	gspecs.ST_flags.high
	mov	gspecs.ST_flags.low, SOM_2D
	tst	ds:[outputInfo].OI_outlineMode
	jz	twoDMode
	mov	gspecs.ST_flags.low, SOM_OUTLINE
twoDMode:
	; gspecs.out_info = 0
	clrdw	gspecs.ST_outInfo
	; ufeSpecs.Font.org = font_buffer
	mov	ufeSpecs.UFES_font.BT_org.segment, es
	mov	ufeSpecs.UFES_font.BT_org.offset, di
	; ufeSpecs.Font.no_bytes = fontbuf_size
	mov	ax, ds:[fontHeaderSize]
	mov	ufeSpecs.UFES_font.BT_noBytes.high, 0
	mov	ufeSpecs.UFES_font.BT_noBytes.low, ax
if PROC_TYPE1
;only Type1 uses Matrix
	segmov	es, ss				; es = Matrix segment
	; ufeSpecs.Matrix[0] = (real)FM_11
	movdw	dxax, ds:[lastFontInstID].BFIID_transMatrix.FM_11
	lea	di, ufeSpecs.UFES_matrix+0*(size BitstreamIEEE64)
	call	storeInMatrix
	; ufeSpecs.Matrix[1] = (real)FM_12
	movdw	dxax, ds:[lastFontInstID].BFIID_transMatrix.FM_12
	lea	di, ufeSpecs.UFES_matrix+1*(size BitstreamIEEE64)
	call	storeInMatrix
	; ufeSpecs.Matrix[2] = (real)FM_21
	movdw	dxax, ds:[lastFontInstID].BFIID_transMatrix.FM_21
	lea	di, ufeSpecs.UFES_matrix+2*(size BitstreamIEEE64)
	call	storeInMatrix
	; ufeSpecs.Matrix[3] = (real)FM_22
	movdw	dxax, ds:[lastFontInstID].BFIID_transMatrix.FM_22
	lea	di, ufeSpecs.UFES_matrix+3*(size BitstreamIEEE64)
	call	storeInMatrix
	; ufeSpecs.Matrix[4] = (real)rotation x offset
	clr	dx, ax
	lea	di, ufeSpecs.UFES_matrix+4*(size BitstreamIEEE64)
	call	storeInMatrix
	; ufeSpecs.Matrix[5] = (real)super/subscript/rotation y offset
	clr	dx, ax
	lea	di, ufeSpecs.UFES_matrix+5*(size BitstreamIEEE64)
	call	storeInMatrix
endif
	; ufeSpecs.Gen_specs = &gspecs
	lea	ax, gspecs
	mov	ufeSpecs.UFES_genSpecs.segment, ss
	mov	ufeSpecs.UFES_genSpecs.offset, ax
	; fi_set_specs(&ufeSpecs)
	push	ss
	lea	ax, ufeSpecs
	push	ax
	call	fi_set_specs			; ax = TRUE/FALSE
	tst_clc	ax
	jnz	done				; TRUE, carry clear
	stc					; else, indicate error (ax=0)
done:
	.leave
	ret

if PROC_TYPE1
;
; dx:ax = WWFixed value to store in Matrix
; es:di = Matrix location to store in
;
storeInMatrix	label	near
	call	FloatDwordToFloat		; fp = WWFixed value
	mov	dx, 1
	clr	ax
	call	FloatDwordToFloat		; fp = (WWFixed value) 65536
	call	FloatDivide			; fp = float value
	call	FloatGeos80ToIEEE64
	retn
endif

EnsureGlobalsAndHeader	endp

SysNotifyStrings	segment lmem	LMEM_TYPE_GENERAL
LocalDefString	fontNotFound1	<'Font data not found.',0>
LocalDefString	fontNotFound2	<'You may need to re-install fonts.',0>
SysNotifyStrings	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockGlobalsAndHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unlock Bitstream globals and font file header

CALLED BY:	UTILITY

PASS:		ax = 0 to unlock both fontHeaderHandle and globalsHandle
		ax <> 0 if fontHeaderHandle and globalsHandle aren't locked

RETURN:		nothing

DESTROYED:	nothing (preserves flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/12/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockGlobalsAndHeader	proc	far
	uses	ds, bx
	.enter
	pushf
	segmov	ds, dgroup, bx
	tst	ax
	jnz	noLock
if PROC_TRUETYPE
	cmp	ds:[lastFontInstID].BFIID_processor, PROC_TRUE_TYPE
	je	afterHeader			; no header for True Type
endif
if PROC_TYPE1
	cmp	ds:[lastFontInstID].BFIID_processor, PROC_TYPE_1
	je	afterHeader			; no header for Type 1
endif
if FIXED_FONT_HEADER
else
	mov	bx, ds:[fontHeaderHandle]
	call	MemUnlock
endif
if PROC_TRUETYPE || PROC_TYPE1
afterHeader:
endif
if STATIC_GLOBALS
else
	mov	bx, ds:[globalsHandle]
	call	MemUnlock
endif
noLock:
	VSem	ds, bitstreamSem
	popf
	.leave
	ret
UnlockGlobalsAndHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareFontInstanceIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare BitstreamFontInstanceIDs

CALLED BY:	EnsureGlobalsAndHeader

PASS:		ds:si - BitstreamFontInstanceData of previous access
		es:di - BitstreamFontInstanceData of current access

RETURN:		carry set if different
			ds:si updated with es:di
		carry clear if same

DESTROYED:	cx, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/12/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareFontInstanceIDs	proc	near
	uses	ds, es
	.enter
	push	si, di
	mov	cx, size BitstreamFontInstanceID
	repe cmpsb
	pop	di, si				; (xchg di, si)
	je	done				; (carry clear)
	;
	; different, so update ds:si
	;
	segxchg	ds, es				; es:di = previous access
						; ds:si = current access
	mov	cx, size BitstreamFontInstanceID
	rep movsb
	stc					; indicate different
done:
	.leave
	ret
CompareFontInstanceIDs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenAndLoadFontFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	open and load header for font file

CALLED BY:	EnsureGlobalsAndHeader

PASS:		cx - FontID
		al - TextStyle
		ah - FontWeight
		ds - font info block
		bl - SJIS high byte (i.e. font file containing desired char)
			(only if Kanji font)

RETURN:		carry clear if successful
			fontFileHandle - font file handle updated
			fontHeaderHandle - buffer reallocated
			fontHeaderSeg - buffer segment updated
			fontHeaderSize - size of font file header read
		carry set otherwise

DESTROYED:	ax, bx, dx, si, di, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/12/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenAndLoadFontFile	proc	near
	uses	es, bp
	.enter

	clr	bh
	mov	bp, bx
	;
	; find FontInfo for specific FontID
	;	cx = fontID
	;
	call	FontDrFindFontInfo		; ds:di = FontInfo
EC <	WARNING_NC	BITSTREAM_CANNOT_FIND_FONT_INFO			>
	LONG jnc	fontNotFound
	;
	; find outline data in FontInfo
	;	al = TextStyle
	;	ah = FontWeight
	;
	call	BitstreamFontDrFindOutlineData	; ds:di = OutlineEntry
	;
	; switch to font's directory
	;	ds:di = OutlineEntry (chunk handle of BitstreamOutlineEntry)
	;
	mov	di, ds:[di]			; *ds:di = BOE
	;
	; get disk handle for file
	;
	mov	si, ds:[di]			; ds:si = DiskSave data
	add	si, offset BOE_fontFileDisk
	mov	cx, 0				; no callback
	call	DiskRestore			; ax = disk handle
EC <	WARNING_C	BITSTREAM_CANNOT_FIND_FONT_INFO			>
	LONG jc	fontNotFound
	;
	; if multi-file kanji font, alter filename to get correct SJIS wards
	;	*ds:di = BitstreamOutlineEntry
	;	ax = disk handle
	;	bl = SJIS high byte
	;
DBCS <	mov	si, ds:[di]			; ds:si = BOE		>
DBCS <	test	ds:[si].BOE_kanjiFont, mask BKFF_MULTI_FILE		>
DBCS <	jz	10$				; not multi-Kanji font	>
DBCS <	call	alterKanjiFilename					>
DBCS <10$:								>
	;
	; try to find font file in cache
	;	*ds:di = BitstreamOutlineEntry
	;	ax = disk handle
	;
	call	FileCacheFind			; carry set if found (bx)
	LONG jc	haveFile
	;
	; else, need to load file
	;	ax = disk handle
	;
	push	ax
	call	FilePushDir
	mov	bx, ax
	mov	dx, ds:[di]			; ds:dx = font path
	add	dx, offset BOE_fontFilePath
	call	FileSetCurrentPath
EC <	WARNING_C	BITSTREAM_CANNOT_FIND_FONT_INFO			>
	pop	cx				; cx = disk handle
	LONG jc	fontNotFoundPopDir
	;
	; open font file for selected font
	;	*ds:di = BitstreamOutlineEntry
	;	cx = disk handle
	;
	mov	dx, ds:[di]			; ds:dx = font name
	add	dx, offset BOE_fontFileName
	mov	al, FILE_DENY_W or FILE_ACCESS_R
	call	FileOpen
EC <	WARNING_C	BITSTREAM_CANNOT_FIND_FONT_INFO			>
	LONG jc	fontNotFoundPopDir
	mov	bx, ax				; bx = font file handle
	mov	ax, handle 0			; change owner to driver
	call	HandleModifyOwner
	call	FileCacheStore
	call	FilePopDir
if DBCS_PCGEOS
	;
	; if concatenated Kanji font, read in file pos table
	;	*ds:di = BitstreamOutlineEntry
	;	bx = file handle
	;	file at position 0
	;
	mov	si, ds:[di]			; ds:si = BOE
if PROC_TRUETYPE
	cmp	ds:[si].BOE_processor, PROC_TRUE_TYPE
	je	haveFile			; not for TrueType fonts
endif
if PROC_TYPE1
	cmp	ds:[si].BOE_processor, PROC_TYPE_1
	je	haveFile			; not for Type 1 fonts
endif
	test	ds:[si].BOE_kanjiFont, mask BKFF_KANJI
	jz	haveFile			; not Kanji font
	test	ds:[si].BOE_kanjiFont, mask BKFF_MULTI_FILE
	jnz	haveFile			; not concat Kanji font
	push	ds
	segmov	ds, dgroup, ax
	mov	dx, offset kanjiFontFilePosTable
	mov	cx, size kanjiFontFilePosTable
	mov	al, FILE_NO_ERRORS
	call	FileRead
	pop	ds
endif
haveFile:
	segmov	es, dgroup, ax
	mov	es:[fontFileHandle], bx
if FONT_HEADER_CACHE	;-----------------------------------------------------
	push	di				; save BitstreamOutlineEntry
	mov	di, offset fontHeaderFileID
	mov	ax, FEA_FILE_ID
	mov	cx, size fontHeaderFileID
	call	FileGetHandleExtAttributes
	jnc	gotFileID
	clrdw	es:[fontHeaderFileID]
gotFileID:
	pop	di
endif	;---------------------------------------------------------------------

if PROC_TRUETYPE
	;
	; if True Type font, done
	;	*ds:di = BitstreamOutlineEntry
	;	bx = file handle
	;
	mov	si, ds:[di]			; ds:si = BOE
	cmp	ds:[si].BOE_processor, PROC_TRUE_TYPE
	je	fileDone
endif
if PROC_TYPE1
	;
	; if Type 1 font, done
	;	*ds:di = BitstreamOutlineEntry
	;	bx = file handle
	;
	mov	si, ds:[di]			; ds:si = BOE
	cmp	ds:[si].BOE_processor, PROC_TYPE_1
	je	fileDone
endif
	;
	; read in font header into fontHeaderHandle
	;	*ds:di = BitstreamOutlineEntry
	;
	mov	si, ds:[di]			; ds:si = BOE
	mov	ax, ds:[si].BOE_minFontBufSize	; ax = font header size
	push	ax				; save size
if FIXED_FONT_HEADER
	mov	ax, es:[fontHeaderSeg]		; assume we've got it
	tst	es:[fontHeaderHandle]
	jnz	haveFontHeader
	mov	ax, 2000
EC <	cmp	ax, ds:[si].BOE_minFontBufSize				>
EC <	ERROR_B	-1							>
	mov	bx, handle 0
	mov	cx, mask HF_FIXED or mask HF_SHARABLE
	call	MemAllocSetOwner		; bx = handle, ax = segment
	mov	es:[fontHeaderHandle], bx
haveFontHeader:
else
	mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
	mov	bx, es:[fontHeaderHandle]
	call	MemReAlloc			; ax = segment
endif
	mov	es:[fontHeaderSeg], ax
DBCS <	mov	bl, ds:[si].BOE_kanjiFont	; bl = BitstreamKanjiFontFlags>
	mov	ds, ax
	;
	; get position of font file header
	;	bp = SJIS high byte
	;	es = dgroup
	;	ds = font header segment
	;	bl = BitstreamKanjiFontFlags (DBCS only)
	;
	clr	cx, dx				; assume not concat Kanji font
if DBCS_PCGEOS
	test	bl, mask BKFF_KANJI
	jz	havePos				; not Kanji font
	test	bl, mask BKFF_MULTI_FILE
	jnz	havePos				; not concat Kanji font
	mov	di, bp
	tst	di
	jz	haveOffset
	sub	di, 0x80
	cmp	di, 0x1f
	jbe	haveOffset
	sub	di, (0xe0-0x080-0x20)
haveOffset:
	shl	di, 1
	shl	di, 1			; * (size dword)
	mov	cx, es:[kanjiFontFilePosTable][di].high
	mov	dx, es:[kanjiFontFilePosTable][di].low
havePos:
endif
if FONT_HEADER_CACHE	;-----------------------------------------------------
	;
	; get font header from cache, if possible
	;
	tstdw	cxdx				; no caching for pos 0
	jz	noCache
	mov	si, FONT_HEADER_CACHE_SIZE
	clr	bx
findFontHeaderCacheLoop:
	cmpdw	cxdx, es:[fontHeaderCache][bx].FHCE_pos
	jne	tryNextCacheEntry
	cmpdw	es:[fontHeaderCache][bx].FHCE_fileID, es:[fontHeaderFileID], ax
	je	foundCacheEntry
tryNextCacheEntry:
	add	bx, size FontHeaderCacheEntry
	dec	si
	jnz	findFontHeaderCacheLoop
	jmp	noCache

foundCacheEntry:
	pop	cx				; cx = header size
	push	ds, es
EC <	inc	es:[fontHeaderCache][bx].FHCE_hit			>
	mov	bx, es:[fontHeaderCache][bx].FHCE_buffer
	call	MemLock
	segmov	es, ds
	clr	di
	mov	ds, ax
	clr	si
	rep	movsb
	call	MemUnlock
	pop	ds, es
	jmp	gotHeaderPopped

noCache:
	movdw	disi, cxdx			; disi = file pos
endif	;---------------------------------------------------------------------
	mov	bx, es:[fontFileHandle]
	mov	al, FILE_POS_START
	call	FilePos
	pop	cx				; cx = header size
	mov	dx, 0				; ds:dx = fontHeaderHandle buf
	mov	al, FILE_NO_ERRORS
	call	FileRead			; cx = bytes read
if FONT_HEADER_CACHE	;-----------------------------------------------------
	;
	; cache font header just read in
	;	bx = file handle
	;	cx = size of header
	;	disi = pos
	;	ds:0 = font header buffer
	;
	push	bx				; save font file handle
	mov	dx, bx				; dx = file handle
	push	cx
	mov	cx, FONT_HEADER_CACHE_SIZE
	clr	bx
storeFontHeaderCacheLoop:
	cmpdw	es:[fontHeaderCache][bx].FHCE_pos, -1
	je	foundSpot
	add	bx, size FontHeaderCacheEntry
	loop	storeFontHeaderCacheLoop
	jmp	short gotHeader

foundSpot:
	mov	dx, bx				; dx = cache table offset
	pop	ax				; ax = size of header
	push	ax
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	mov	bx, handle 0
	call	MemAllocSetOwner		; bx = handle, ax = segment
	jc	gotHeader
	pop	cx				; cx = size
	push	cx
	xchg	bx, dx				; bx = offset, dx = mem handle
	mov	es:[fontHeaderCache][bx].FHCE_buffer, dx
	movdw	es:[fontHeaderCache][bx].FHCE_pos, disi
	movdw	es:[fontHeaderCache][bx].FHCE_fileID, es:[fontHeaderFileID], si
EC <	mov	es:[fontHeaderCache][bx].FHCE_hit, 0			>
	clr	si
	push	es
	mov	es, ax
	clr	di
	rep	movsb
	mov	bx, dx
	call	MemUnlock
	pop	es
gotHeader:
	pop	ax
	pop	bx				; bx = font file handle
gotHeaderPopped:
endif	;---------------------------------------------------------------------
	;
	; for Kanji fonts, BOE_minFontBufSize is going to be the max of all
	; the minFontBufSizes; fontHeaderSize is passed to fi_set_specs as
	; the size of the font header for a particular font file; we use
	; SFFH_minFontBufSize instead of the amount we've read because the max
	; of the minFontBufSizes may contain half the data for a character --
	; Bitstream will incorrectly think that all the character data is there
	;
	mov	al, {byte}ds:[SFFH_minFontBufSize]+3	; word-byte-swap
	mov	ah, {byte}ds:[SFFH_minFontBufSize]+2
	mov	es:[fontHeaderSize], ax
if PROC_TRUETYPE || PROC_TYPE1
fileDone:
endif
	;
	; finished with font file
	;	bx = font file
	;
	call	FileCacheRelease
	clc					; indicate success
done:
	.leave
	ret

fontNotFound:
	stc
	jmp	short done

fontNotFoundPopDir:
	call	FilePopDir
	stc
	jmp	short done

;
; *ds:di = BitstreamOutlineEntry
; bl = SJIS high byte
;
if DBCS_PCGEOS
alterKanjiFilename	label	near
	push	es, di, ax
	mov	di, ds:[di]
	add	di, offset BOE_fontFileName
	segmov	es, ds				; es:di = filename
	mov	ax, '.'
	mov	cx, length BOE_fontFileName
	LocalFindChar
EC <	ERROR_NE	BITSTREAM_INTERNAL_ERROR			>
	LocalPrevChar	esdi			; es:di = '.'
	LocalPrevChar	esdi			; es:di = low byte
	LocalPrevChar	esdi			; es:di = high byte
	mov	al, bl
	andnf	ax, 0x00f0
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	add	ax, '0'
	cmp	ax, '9'
	jbe	haveHighByte
	add	ax, ('A'-'9')-1
haveHighByte:
	LocalPutChar	esdi, ax
	mov	al, bl
	andnf	ax, 0x000f
	add	ax, '0'
	cmp	ax, '9'
	jbe	haveLowByte
	add	ax, ('A'-'9')-1
haveLowByte:
	LocalPutChar	esdi, ax
	pop	es, di, ax
	retn
endif

OpenAndLoadFontFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCacheFind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find file in cache

CALLED BY:	OpenAndLoadFontFile

PASS:		*ds:di - BitstreamOutlineEntry of file
		ax - disk handle of file

RETURN:		carry set if found
			bx - file handle
		carry clear if not found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/12/93	Initial version
	brianc	11/3/93		updated for seperate font files per face

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCacheFind	proc	near
	uses	ax, cx, si, es, di
	.enter
	segmov	es, dgroup, cx
	;
	; check disk handle
	;
	cmp	ax, es:[cachedFontDiskHandle]
	jne	noMatch
	;
	; check file name
	;
	mov	si, ds:[di]
	add	si, offset BOE_fontFileName
	mov	di, offset cachedFontFileName
	clr	cx				; null-terminated
	call	LocalCmpStrings
	jne	noMatch
	;
	; check pathname
	;	ds:si = BOE_fontFileName
	;
	add	si, (offset BOE_fontFilePath)-(offset BOE_fontFileName)
	mov	di, offset cachedFontFilePath
	clr	cx				; null-terminated
	call	LocalCmpStrings
	jne	noMatch
	;
	; have match, return cached file handle
	;
	mov	bx, es:[cachedFontFile]
	stc					; indicate match
	jmp	short done

noMatch:
	clc
done:
	.leave
	ret
FileCacheFind	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCacheStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store file in cache

CALLED BY:	OpenAndLoadFontFile

PASS:		*ds:di - BitstreamOutlineEntry
		bx - file handle
		cx - disk handle of file

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCacheStore	proc	near
	uses	ax, bx, si, es, di
	.enter
	segmov	es, dgroup, ax
	;
	; store disk handle
	;
	mov	es:[cachedFontDiskHandle], cx
	;
	; store file name
	;
	mov	si, ds:[di]
	push	si
	add	si, offset BOE_fontFileName
	mov	di, offset cachedFontFileName
	LocalCopyString				; copy null-term string
	pop	si
	;
	; store pathname
	;
	add	si, offset BOE_fontFilePath
	mov	di, offset cachedFontFilePath
	LocalCopyString				; copy null-term string
	;
	; store new file and close old file
	;
	xchg	bx, es:[cachedFontFile]
	tst	bx
	jz	done
	mov	al, FILE_NO_ERRORS
	call	FileClose			; close previous one
done:
	.leave
	ret
FileCacheStore	endp

FileCacheRelease	proc	near
	ret
FileCacheRelease	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamFontDrFindOutlineData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find OutlineDataEntry for a font, and calculate
		styles that need to be implemented algorithmically.
CALLED BY:	Bitstream Font Driver

PASS:		ds:di - ptr to FontInfo for font
		al - style (TextStyle)
		ah - weight (FontWeight)
RETURN:		ds:di - ptr to OutlineEntry
		al - styles to implement (TextStyle)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 3/92		Initial version
	brianc	11/4/93		added font weight support for Bitstream

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitstreamFontDrFindOutlineData	proc	far
	uses	bx, cx, dx, si, bp
	.enter

	test	al, mask TS_BOLD		;bold?
	jz	noBold
	andnf	al, not mask TS_BOLD		;clear bold style
	add	ah, (BFW_BOLD-BFW_NORMAL)	;adjust weight for bold
	cmp	ah, BFW_BLACK
	jbe	noBold
	mov	ah, BFW_BLACK			;limit to black
noBold:
	clr	ch				;ch <- initial style difference
	mov	cl, 127				;cl <- initial wgt difference
	mov	bp, di
	add	bp, ds:[di].FI_outlineEnd	;bp <- ptr to end of table
	add	di, ds:[di].FI_outlineTab	;di <- ptr to start of table
EC <	cmp	bp, di							>
EC <	ERROR_E	BITSTREAM_INTERNAL_ERROR				>
	mov	si, di				;si <- ptr to entry to use
	;
	; In the loop:
	;	al - TextStyle requested
	;	ah - FontWeight requested
	;
	;	ds:di - ptr to current entry
	;	dl - TextStyle of current entry
	;	dh - weight of current entry
	;	bl - current difference from TextStyle requested
	;
	;	ds:si - ptr to entry to use
	;	ch - difference of TextStyle for entry to use (ie. smallest)
	;	cl - difference of weight for smallest TextStyle difference
	;
FO_loop:
	cmp	di, bp				;at end of list?
	jae	endList				;yes, exit
	mov	dl, ds:[di].ODE_style		;dl <- style of outline
	mov	dh, ds:[di].ODE_weight		;dh <- weight of outline
	cmp	dx, ax				;an exact match?
	je	exactMatch			;branch if exact match
	cmp	dl, al
	je	styleMatch			;styles exact match
	mov	bh, al
	and	bh, dl
	mov	bl, bh				;bl <- weighted difference
	xor	bh, dl				;bh <- zero iff subset
	jne	notSubset			;branch if not a subset
	cmp	bl, ch				;cmp with minimum so far
	jb	notSubset			;branch if larger difference
	mov	si, di				;si <- new ptr to entry
	mov	ch, bl				;ch <- new minimum difference
notSubset:
	add	di, size OutlineDataEntry	;advance to next entry
	jmp	FO_loop				;and loop

styleMatch:
	mov	ch, 0				;no style difference
	mov	bh, ah
	sub	bh, dh				;bh = weight difference
	Abs	bh
	cmp	bh, cl
	jge	notSubset			;bigger difference, skip
	mov	si, di				;si <- new ptr to entry
	mov	cl, bh				;cl <- new minimum difference
	jmp	notSubset

exactMatch:
	mov	si, di				;ds:si <- ptr to current entry
	clr	al				;al <- no styles to implement
	jmp	gotStyles

endList:
	xor	al, ch				;al <- styles to implement
gotStyles:
	mov	di, si				;di <- off of OutlineDataEntry
	add	di, (size ODE_style + size ODE_weight)

	.leave
	ret
BitstreamFontDrFindOutlineData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapUnicodeCharToSJIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	map unicode char to SJIS

CALLED BY:	UTILITY

PASS:		ax = Unicode character to map

RETURN:		carry clear if mapped
			ax = SJIS value
		carry set if unmappable

DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/14/94	Broke out of GenChar for general usage

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
MapUnicodeCharToSJIS	proc	far
	cmp	ax, C_SPACE
	jb	mapError
	cmp	ax, C_DELETE
	je	mapError
if PZ_PCGEOS
	cmp	ax, C_YEN_SIGN
	jne	notYen
	mov	ax, C_BACKSLASH			; ax = SJIS backslash
	jmp	short mapped

notYen:
	;
	; Any user-defined characters 0xE000-0xF800 (U+) should be
	; mapped to the black square character since data for these
	; do not exist in the font.
	;
	cmp	ax, 0xE000
	jb	notUserDefined
	cmp	ax, 0xF800
	ja	notUserDefined
	jmp	mapError			; replace with black square
notUserDefined:
endif
	mov	bx, CODE_PAGE_SJIS
	clr	dx
	call	LocalGeosToDosChar		; ax = SJIS, carry
	ret

mapped::
	clc
	ret

mapError:
	stc
	ret
MapUnicodeCharToSJIS	endp
endif



if DBCS_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsToshibaExtendedChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry set if the character is a Toshiba
		extension.

CALLED BY:	BitstreamGenChar()
PASS:		ax - the character (SJIS value)
RETURN:		carry - set if true
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
	The Toshiba extension characters exist in 12 separate ranges
	in SJIS (they're scattered in Unicode).  If the character lies
	within one of these 12 ranges then set the carry and we're done.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtendedCharStruct	struct
	ECS_rangeStart	word
	ECS_rangeEnd	word
ExtendedCharStruct	ends

extendedCharTable	ExtendedCharStruct \
< 0x81ad, 0x81b7 >,
< 0x81c0, 0x81c7 >,
< 0x81cf, 0x81d9 >,
< 0x81e9, 0x81ef >,
< 0x81f8, 0x81fb >,
< 0x8240, 0x8246 >,
< 0x82f2, 0x82f6 >,
< 0x83be, 0x83be >,
< 0x83dd, 0x83dd >,
< 0x84bf, 0x84fc >,
< 0x8540, 0x857e >,
< 0x8580, 0x859e >,
< 0x0000, 0x0000 >

IsToshibaExtendedChar	proc	far
	uses	es, di
	.enter

	segmov	es, cs
	mov	di, offset extendedCharTable	;beginning of table
loopTop:
	tst	es:[di].ECS_rangeStart
	jz	notExtended			;we're at the end, no find
	cmp	ax, es:[di].ECS_rangeStart
	jb	notExtended			;it's not in range
	cmp	ax, es:[di].ECS_rangeEnd
	jbe	extended
	add	di, size ExtendedCharStruct	;next table entry
	jmp	loopTop
extended:
	stc					;it's Toshiba extended
	jmp	done
notExtended:
	clc
done:
	.leave
	ret
IsToshibaExtendedChar	endp
endif
