COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainWidths.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	BitstreamGenWidths	build FontBuf

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/8/93		Initial version.

DESCRIPTION:
	This file contains GEOS Bitstream Font Driver routines.

	$Id: mainWidths.asm,v 1.1 97/04/18 11:45:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DBCS_PCGEOS
FontRangeEntry	struct
	FRE_charSet	FontCharSet
	FRE_firstChar	byte
	FRE_lastChar	byte
FontRangeEntry	ends

fontRangeTable	FontRangeEntry \
<	0x00,	0x20,	0xF7	>,
<	0x03,	0x91,	0xC9	>,
<	0x04,	0x01,	0x51	>,
<	0x20,	0x10,	0xDD	>,
<	0x21,	0x03,	0xD4	>,
<	0x22,	0x00,	0xBF	>,
<	0x23,	0x12,	0x12	>,
<	0x24,	0x60,	0x73	>,
<	0x25,	0x00,	0xCF	>,
<	0x26,	0x05,	0x6F	>,
<	0x30,	0x00,	0xFE	>,
<	0x32,	0x31,	0xA8	>,
<	0x33,	0x03,	0xCD	>,
<	0x4E,	0x00,	0xFB	>,
<	0x4F,	0x01,	0xFE	>,
<	0x50,	0x05,	0xFB	>,
<	0x51,	0x00,	0xFE	>,
<	0x52,	0x00,	0xFF	>,
<	0x53,	0x01,	0xFA	>,
<	0x54,	0x01,	0xFD	>,
<	0x55,	0x04,	0xFE	>,
<	0x56,	0x06,	0xFF	>,
<	0x57,	0x00,	0xFC	>,
<	0x58,	0x00,	0xFD	>,
<	0x59,	0x02,	0xFF	>,
<	0x5A,	0x01,	0xFB	>,
<	0x5B,	0x09,	0xFF	>,
<	0x5C,	0x01,	0xFD	>,
<	0x5D,	0x07,	0xFE	>,
<	0x5E,	0x02,	0xFF	>,
<	0x5F,	0x01,	0xFF	>,
<	0x60,	0x0E,	0xFB	>,
<	0x61,	0x00,	0xFF	>,
<	0x62,	0x00,	0xFF	>,
<	0x63,	0x01,	0xFA	>,
<	0x64,	0x06,	0xFE	>,
<	0x65,	0x00,	0xFB	>,
<	0x66,	0x02,	0xFF	>,
<	0x67,	0x00,	0xFF	>,
<	0x68,	0x02,	0xFA	>,
<	0x69,	0x00,	0xFF	>,
<	0x6A,	0x02,	0xFB	>,
<	0x6B,	0x04,	0xF3	>,
<	0x6C,	0x08,	0xF3	>,
<	0x6D,	0x0B,	0xFB	>,
<	0x6E,	0x05,	0xFF	>,
<	0x6F,	0x01,	0xFE	>,
<	0x70,	0x01,	0xFD	>,
<	0x71,	0x09,	0xFF	>,
<	0x72,	0x06,	0xFD	>,
<	0x73,	0x0A,	0xFE	>,
<	0x74,	0x03,	0xF8	>,
<	0x75,	0x03,	0xFF	>,
<	0x76,	0x01,	0xFE	>,
<	0x77,	0x01,	0xFC	>,
<	0x78,	0x02,	0xFD	>,
<	0x79,	0x01,	0xFB	>,
<	0x7A,	0x00,	0xFF	>,
<	0x7B,	0x02,	0xF7	>,
<	0x7C,	0x00,	0xFE	>,
<	0x7D,	0x00,	0xFB	>,
<	0x7E,	0x01,	0x9C	>,
<	0x7F,	0x36,	0xFC	>,
<	0x80,	0x00,	0xFD	>,
<	0x81,	0x02,	0xFE	>,
<	0x82,	0x01,	0xFB	>,
<	0x83,	0x02,	0xFD	>,
<	0x84,	0x03,	0xFF	>,
<	0x85,	0x00,	0xFE	>,
<	0x86,	0x02,	0xFE	>,
<	0x87,	0x00,	0xFE	>,
<	0x88,	0x05,	0xFE	>,
<	0x89,	0x02,	0xF8	>,
<	0x8A,	0x00,	0xFE	>,
<	0x8B,	0x00,	0x9A	>,
<	0x8C,	0x37,	0xFD	>,
<	0x8D,	0x04,	0xFF	>,
<	0x8E,	0x08,	0xFE	>,
<	0x8F,	0x03,	0xFD	>,
<	0x90,	0x00,	0xFD	>,
<	0x91,	0x02,	0xFF	>,
<	0x92,	0x0D,	0xFC	>,
<	0x93,	0x06,	0xE8	>,
<	0x94,	0x03,	0x81	>,
<	0x95,	0x77,	0xE5	>,
<	0x96,	0x1C,	0xFB	>,
<	0x97,	0x00,	0xFF	>,
<	0x98,	0x01,	0xFE	>,
<	0x99,	0x03,	0xFF	>,
<	0x9A,	0x01,	0xFB	>,
<	0x9B,	0x06,	0xF5	>,
<	0x9C,	0x04,	0xF6	>,
<	0x9D,	0x03,	0xFD	>,
<	0x9E,	0x1A,	0xFD	>,
<	0x9F,	0x07,	0xA0	>,
<	0xFF,	0x01,	0xE5	>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCharSetRangeIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the character set, this function returns an
		index to the fontRangeTable so that the correct 
		character ranges for the set can be used.

CALLED BY:	PKGenWidths()
PASS:		dh - FontCharSet
RETURN:		si - FontRangeEntry to use
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	grisco	6/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCharSetRangeIndex	proc	near
		.enter

		clr	si
searchLoop:
		cmp	dh, cs:fontRangeTable[si].FRE_charSet
		je	foundEntry
		add	si, size FontRangeEntry
		cmp	si, size fontRangeTable
		jb	searchLoop
EC <		WARNING BITSTREAM_CHAR_SET_NOT_FOUND			>
						; point to 0x00->0xff entry
		mov	si, (offset fontRangeTable)+17*(size FontRangeEntry)
foundEntry:
		.leave
		ret
FindCharSetRangeIndex	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamGenWidths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	allocate and initialize FontBuf for given font

CALLED BY:	DR_FONT_GEN_WIDTHS - BitstreamStrategy

PASS:		di - 0 for new font; handle of old FontBuf (P'd)
		es - segment of GState (locked)
			contains:
				GS_fontAttr:
					FCA_fontID	FontID
					FCA_pointSize	WBFixed
					FCA_textStyle	TextStyle
		bp:cx - transformation matrix (TMatrix)
		ds - segment of font info block

RETURN:		carry clear if successful
			bx - handle of FontBuf (locked)
			ax - segment of FontBuf (locked)
		carry set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitstreamGenWidths	proc	far
	uses	cx, dx, di, si, ds, es

gStateSeg	local	sptr.GState	push	es
	ForceRef gStateSeg
fontBufHan	local	hptr.FontBuf	push	di
xform		local	fptr.TMatrix
cacheFile	local	hptr
stylesLeft	local	TextStyle
pointSize	local	WBFixed
fontWidth	local	FontWidth
	ForceRef fontWidth
fontWeight	local	FontWeight
	ForceRef fontWeight
widthScale	local	WWFixed
	ForceRef widthScale
heightScale	local	WWFixed
	ForceRef heightScale
fontProcessor	local	BitstreamFontProcessor
DBCS <charSet		local	FontCharSet				>
extraData	local	word
DBCS <firstChar	local	Chars						>
DBCS <lastChar	local	Chars						>
unscaledWidth	local	word
scaledWidth	local	WBFixed
	ForceRef scaledWidth

	.enter

	mov	ax, ss:[bp]			; save xform ptr (ss:[bp] = bp)
	mov	xform.segment, ax
	mov	xform.offset, cx

	mov	ss:unscaledWidth, 0x8000	; no width calc'd yet

if DBCS_PCGEOS
	;
	; grab optimized first/last char info
	;
	mov     dh, es:GS_fontAttr.FCA_charSet
	mov	charSet, dh
	call	FindCharSetRangeIndex		;si -> FontRangeEntry
	mov	ch, dh
	mov	dl, cs:[si].FRE_lastChar	;dx = last char
	mov     cl, cs:[si].FRE_firstChar	;cx = first char
	mov	firstChar, cx
	mov	lastChar, dx
endif
						; save pointsize
	movwbf	pointSize, es:[GS_fontAttr].FCA_pointsize, ax
	mov	al, es:[GS_fontAttr].FCA_width
	mov	fontWidth, al
	mov	al, es:[GS_fontAttr].FCA_weight
	test	es:[GS_fontAttr].FCA_textStyle, mask TS_BOLD
	jz	noBoldWeight
	add	al, (BFW_BOLD-BFW_NORMAL)
noBoldWeight:
	mov	fontWeight, al
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
	; grab some info while we can
	;	ds:di = OutlineEntry (chunk handle of BitstreamOutlineEntry)
	;
	mov	di, ds:[di]			; *ds:di = BitstreamOutlineEntry
	mov	extraData, di			; store for later
	mov	di, ds:[di]			; ds:di = BitstreamOutlineEntry
	mov	ax, ds:[di].BOE_processor
	mov	fontProcessor, ax
	;
	; see if desired cached data file is cached
	;	ds:di = BitstreamOutlineEntry
	;
	segmov	es, dgroup, ax
.assert (offset BOE_cachedFileName) eq 0
	mov	si, di				; ds:si = desired cache file
	call	FindCacheFileInCache		; carry set if found (ax=handle)
	jc	haveCacheHandle
	;
	; switch to Bitstream cached data directory
	;
	call	FilePushDir
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath
	push	ds
	segmov	ds, dgroup, dx
	mov	dx, offset bitstreamDir
	clr	bx				; relative to CWD
	call	FileSetCurrentPath
	pop	ds
EC <	WARNING_C	BITSTREAM_CANNOT_FIND_FONT_INFO			>
	LONG jc	fontNotFound
	;
	; open cached data file for selected font
	;	ds:di = BitstreamOutlineEntry
	;	es = dgroup
	;
.assert (offset BOE_cachedFileName) eq 0
	mov	dx, di				; ds:dx = BOE (cache file name)
	mov	al, FILE_DENY_W or FILE_ACCESS_R
	call	FileOpen			; ax = file handle
EC <	WARNING_C	BITSTREAM_CANNOT_FIND_FONT_INFO			>
	call	FilePopDir			; (preserves flags)
	LONG jc	fontNotFound
	mov	bx, ax				; bx = font file handle
	mov	ax, handle 0			; change owner to driver
	call	HandleModifyOwner
	mov	ax, bx				; ax = font file handle
	call	StoreCacheFileInCache
DBCS <	mov	es:[cachedCacheFileOffset], -1	; illegal offset to invalidate>
haveCacheHandle:
	mov	cacheFile, ax
	mov	bx, ax				; bx = file handle
	;
	; read in desired cached data
	;	bx = cache file handle
	;	ds:di = BitstreamOutlineEntry
	;
	mov	cx, 0
	mov	dx, ds:[di].BOE_cacheData.FFLI_offset

if DBCS_PCGEOS	;------------------------------------------------------------
;
; for DBCS, where we'll need to create a FontBuf for each FontCharSet, keep
; the cached data block around so we don't need to re-read the cache file
;
	;
	; check if the cached data we have cached is the one were looking for
	;	dx = offset of cached data
	;	es = dgroup
	;
	cmp	dx, es:[cachedCacheFileOffset]
	jne	readCachedData			; nope
	mov	bx, es:[cachedCacheBufferHandle]
	call	MemLock
	mov	ds, ax
	jmp	short haveCacheSeg

readCachedData:
	;
	; it's not, read in cached data
	;	cx:dx = file offset
	;	bx = cache file handle
	;	ds:di = BitstreamOutlineEntry
	;	es = dgroup
	;
	mov	es:[cachedCacheFileOffset], dx	; store offset
	push	bx				; save file handle
	mov	bx, es:[cachedCacheBufferHandle]
	tst	bx
	jz	afterCacheFree
	call	MemFree				; free previous data
afterCacheFree:
	pop	bx				; bx = cache file handle
endif	;---------------------------------------------------------------------
	mov	al, FILE_POS_START
	call	FilePos
	mov	ax, ds:[di].BOE_cacheData.FFLI_length
	push	ax				; save size
	mov	cx, ALLOC_DYNAMIC_LOCK or \
			mask HF_SHARABLE or (mask HAF_NO_ERR shl 8)
	mov	bx, handle 0			; owned by driver
	call	MemAllocSetOwner		; ax = segment
	pop	cx				; cx = size
	mov	es:[cachedCacheBufferHandle], bx
	mov	ds, ax
	mov	dx, 0
	mov	al, FILE_NO_ERRORS
	mov	bx, cacheFile
	call	FileRead
DBCS <haveCacheSeg:							>
	;
	; close cached data file
	;
	call	ReleaseCacheFileFromCache
if DBCS_PCGEOS
	;
	; in DBCS, use firstChar/lastChar to compute numChars
	;
	mov	ax, lastChar
	sub	ax, firstChar
	inc	ax
	mov	ds:[BFCD_numChars], ax
endif
	;
	; allocate a FontBuf
	;	ds - BitstreamFontCachedData
	;
	mov	bx, size BitstreamCharGenData
	mov	cx, ds:[BFCD_numChars]		; cx = num chars
	mov	ax, ds:[BFCD_kernCount]
	mov	di, fontBufHan
	call	FontAllocFontBlock		; es = seg of FontBuf
						;	es:FB_dataSize set
	push	bx				; save handle of FontBuf
	;
	; transfer data from cached data to FontBuf
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;
	call	TransferData
	;
	; clean up
	;
	segmov	ds, dgroup, ax
	mov	bx, ds:[cachedCacheBufferHandle]
SBCS <	call	MemFree				; no cached data in SBCS>
DBCS <	call	MemUnlock			; cache for DBCS	>
	;
	; return stuff
	;
	pop	bx				; bx = FontBuf handle
	mov	ax, es				; ax = segment of FontBuf

	clc					; indicate all is well
done:
	.leave
	ret

fontNotFound:
	stc
	jmp	short done

BitstreamGenWidths	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCacheFileInCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find file in cache

CALLED BY:	BitstreamGenWidths

PASS:		ds:si - name of cache file

RETURN:		carry set if found
			ax - file handle
		carry clear if not found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/18/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCacheFileInCache	proc	near
	uses	cx, si, es, di
	.enter
	segmov	es, dgroup, cx
	;
	; check file name
	;
	mov	di, offset cachedCacheFileName
	clr	cx				; null-terminated
	call	LocalCmpStrings
	jne	noMatch
	;
	; have match, return cached file handle
	;
	mov	ax, es:[cachedCacheFile]
	stc					; indicate match
	jmp	short done

noMatch:
	clc
done:
	.leave
	ret
FindCacheFileInCache	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreCacheFileInCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store file in cache

CALLED BY:	BitstreamGenWidths

PASS:		ds:si - name of cache file
		ax - file handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/18/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreCacheFileInCache	proc	near
	uses	ax, bx, si, es, di
	.enter
	mov_tr	bx, ax				; bx = new file handle
	segmov	es, dgroup, ax
	;
	; store file name
	;
	mov	di, offset cachedCacheFileName
	LocalCopyString				; copy null-term string
	;
	; store new file and close old file
	;
	xchg	bx, es:[cachedCacheFile]
	tst	bx
	jz	done
	mov	al, FILE_NO_ERRORS
	call	FileClose			; close previous one
done:
	.leave
	ret
StoreCacheFileInCache	endp

ReleaseCacheFileFromCache	proc	near
	ret
ReleaseCacheFileFromCache	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransferData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	transfer data from BitstreamFontCachedData to FontBuf

CALLED BY:	BitstreamGenWidths

PASS:		ds - BitstreamFontCachedData
		es - FontBuf

RETURN:		es:di - BitstreamCharGenData

DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransferData	proc	near
	.enter inherit BitstreamGenWidths
	;
	; calculate scale factor from pointsize and styles
	;
	movwbf	dxch, pointSize			; dx:cx = pointsize
	clr	cl
	clr	ax				; bx:ax = grid size
	mov	bx, ds:[BFCD_ORUsPerEm]
	call	GrUDivWWFixed			; dx:cx = pointsize/grid
	movwwf	widthScale, dxcx
	movwwf	heightScale, dxcx
	;
	; adjust width scale for remaining styles, if needed
	;	dx:cx = current width scale
	;
	test	stylesLeft, mask TS_SUBSCRIPT or mask TS_SUPERSCRIPT
	jz	noScript
	mov	bx, SCRIPT_FACTOR_INT
	mov	ax, SCRIPT_FACTOR_FRAC
	call	GrMulWWFixed			; dx:cx = new width scale
noScript:
if 0
;bold handled with font weight
	test	stylesLeft, mask TS_BOLD
	jz	noBold
	mov	bx, BOLD_FACTOR_INT
	mov	ax, BOLD_FACTOR_FRAC
	call	GrMulWWFixed			; dx:cx = new width scale
noBold:
endif
	movwwf	widthScale, dxcx		; store updated width scale
	;
	; adjust width scale for font's font width and font weight and
	; desired font width and font scale
	;
	mov	dl, fontWidth
	cmp	dl, ds:[BFCD_fontWidth]
	je	noWidth
	clr	ax, cx
	mov	dh, al
	mov	bh, al
	mov	bl, ds:[BFCD_fontWidth]
	call	GrUDivWWFixed			; dx.cx = percentage
	movwwf	bxax, widthScale
	call	GrMulWWFixed
	movwwf	widthScale, dxcx
noWidth:

	mov	dl, fontWeight
	cmp	dl, ds:[BFCD_fontWeight]
	je	noWeight
	clr	ax, cx
	mov	dh, al
	mov	bh, al
	mov	bl, ds:[BFCD_fontWeight]
	call	GrUDivWWFixed			; dx.cx = percentage
	movwwf	bxax, widthScale
	call	GrMulWWFixed
	movwwf	widthScale, dxcx
noWeight:
	;
	; init fields
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;
	mov	es:[FB_maker], FM_BITSTREAM
	mov	es:[FB_flags], mask FBF_IS_OUTLINE
	mov	es:[FB_heapCount], 0
						; height adjust is ptsize
	movwbf	es:[FB_heightAdjust], pointSize, ax
	clrwbf	es:[FB_extLeading]		; no external leading
	;
	; convert various fields with scaling
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;
	call	ConvertMetrics
	;
	; initialize BitstreamCharGenData
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;
	mov	di, ds:[BFCD_numChars]
	;
	; NOTE: the following is not really an index, but the
	; calculation is identical.
	;
	FDIndexCharTable di, cx
	add	di, size FontBuf - size CharTableEntry	; skip header
	mov	bx, di
	mov	al, 0
	mov	cx, size BitstreamCharGenData
	rep stosb				; zero everything out
	mov	di, bx
	add	di, offset BCGD_fontInstID.BFIID_fontAttrs
	push	ds
	mov	ds, gStateSeg			; ds:si = FontCommonAttrs
	mov	si, offset GS_fontAttr
	mov	cx, size BFIID_fontAttrs
	rep movsb				; copy GState's FontCommonAttrs
						; nuke kern implemented styles
	and	es:[bx].BCGD_fontInstID.BFIID_fontAttrs.FCA_textStyle,\
			not (KERNEL_STYLES)
	pop	ds				; ds = BFCD
	mov	ax, ds:[BFCD_minCharBufSize]
	mov	es:[bx].BCGD_minCharBufSize, ax
	mov	ax, fontProcessor
	mov	es:[bx].BCGD_fontInstID.BFIID_processor, ax
DBCS <	mov	al, ds:[BFCD_kanjiFont]					>
DBCS <	mov	es:[bx].BCGD_kanjiFont, al				>
	mov	ax, extraData
	mov	es:[bx].BCGD_extraData, ax
	;
	; convert widths (build char table)
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;
if DBCS_PCGEOS
	mov	ax, firstChar
	mov	es:[FB_firstChar], ax
	mov	ax, lastChar
	mov	es:[FB_lastChar], ax
	mov	ax, ds:[BFCD_defaultChar]
	mov	es:[FB_defaultChar], ax
else
	mov	al, ds:[BFCD_firstChar]
	mov	es:[FB_firstChar], al
	mov	al, ds:[BFCD_lastChar]
	mov	es:[FB_lastChar], al
	mov	al, ds:[BFCD_defaultChar]
	mov	es:[FB_defaultChar], al
endif
	mov	cx, ds:[BFCD_numChars]
	mov	di, offset FB_charTable		; es:di = FontBuf char table

if DBCS_PCGEOS	;-------------------------------------------------------------

	;
	; get info for DBCS
	;	cx = num chars
	;
	mov	ax, firstChar			; ax = first char in CharSet
widthLoop:
	push	ax, cx
	;
	; init FB_charTable entry to defaults
	;	ax = Unicode char
	;
if FAST_GEN_WIDTHS
	;
	; all characters exist
	;
	mov	es:[di].CTE_dataOffset, CHAR_NOT_BUILT
	mov	es:[di].CTE_flags, 0
else
	mov	es:[di].CTE_dataOffset, CHAR_NOT_EXIST
	mov	es:[di].CTE_flags, mask CTF_NO_DATA
endif
SBCS <	mov	es:[di].CTE_usage, 0					>
	clrwbf	es:[di].CTE_width
	test	ds:[BFCD_kanjiFont], mask BKFF_KANJI
	jz	nonKanjiFont
	;
	; DBCS Kanji font -- convert Unicode to SJIS, if ward 0, use
	; BFCD_charTable, else use BFCD_charExistsTable and generate width
	;	ax = Unicode char
	;
	cmp	ax, C_YEN_SIGN
	jne	notYen
	mov	ax, C_BACKSLASH			; map to SJIS backslash
	jmp	short ward0
notYen:
if FAST_GEN_WIDTHS
	;
	;	ax = Unicode character
	;
	cmp	ax, C_SPACE
	jb	notLowAscii
	cmp	ax, C_DELETE
	jbe	ward0				; Unicode 32-127 is SJIS ward 0
notLowAscii:
	cmp	ax, C_HALFWIDTH_IDEOGRAPHIC_PERIOD
	jb	notHalfwidth
	cmp	ax, C_HALFWIDTH_KATAKANA_VOICED_ITERATION_MARK
	ja	notHalfwidth
	;
	; convert halfwidth 0xff61-0xff9f to SJIS 0xa1-0xdf
	;
	sub	ax, (C_HALFWIDTH_IDEOGRAPHIC_PERIOD-0xa1)
	jmp	ward0

notHalfwidth:
else
	mov	bx, CODE_PAGE_SJIS
	clr	dx
	call	LocalGeosToDosChar		; ax = SJIS
	LONG jc	doneChar			; can't map
	tst	ah				; ward 0?
	jz	ward0
	;
	; not ward 0, check if char exists via BFCD_charExistsTable, if so,
	; use default width for this non-ward 0 char
	;	ax = SJIS char
	;	ds = BitstreamFontCachedData
	;
	call	CheckCharExists
	jz	doneChar			; doesn't exist, use defaults
endif
	mov	dx, ds:[BFCD_kanjiCharWidth]	; dx = width
	mov	es:[di].CTE_dataOffset, CHAR_NOT_BUILT	; not built yet
	andnf	es:[di].CTE_flags, not mask CTF_NO_DATA
	jmp	short haveWidth

nonKanjiFont:
	;
	; DBCS non-Kanji font -- lookup character in BFCD_xlatTable to
	; see if it exists, if so, we have Bitstream direct index so use
	; it to offset into BFCD_charTable to get char info
	;	ax = Unicode char
	;
	push	es, di
	segmov	es, ds
	mov	cx, MAX_BITSTREAM_DIRECT_INDEX+1
	lea	di, ds:[BFCD_xlatTable]
	repne scasw
	mov	ax, di				; save table offset
	pop	es, di
	jne	doneChar			; not found, use defaults
	dec	ax				; point back to found char
	dec	ax
	sub	ax, offset BFCD_xlatTable	; subtract table offset
	shr	ax, 1				; ax = Bitstream direct index
						; (indexes BFCD_charTable)
ward0:
	;
	; ward 0, use SJIS as index into BFCD_charTable
	;	ax = SJIS char (index into BFCD_charTable)
	;
	cmp	ax, ds:[BFCD_firstChar]		; before first char?
	jb	doneChar			; yes, defaults okay
	cmp	ax, ds:[BFCD_lastChar]		; after last char?
	ja	doneChar			; yes, defaults okay
	sub	ax, ds:[BFCD_firstChar]		; else convert to table index
	mov	si, ax
.assert (size BitstreamCharTableEntry eq 3)
	shl	si, 1
	add	si, ax				; si = BFCD_charTable offset
	add	si, ds:[BFCD_charTable]
	mov	cl, ds:[si].BCTE_flags		; cl = CharTableFlags
	test	cl, mask CTF_NO_DATA
	jnz	noData				; no data, leave CHAR_NOT_EXIST
	mov	es:[di].CTE_dataOffset, CHAR_NOT_BUILT	; else, not built yet
noData:
	mov	es:[di].CTE_flags, cl
	mov	dx, ds:[si].BCTE_width		; dx.cx = width
haveWidth:
	;
	; See if we've computed this width before...
	;
	cmp	dx, ss:unscaledWidth		; same unscaled width?
	je	setWidth			; branch if so
	mov	ss:unscaledWidth, dx		; record unscaled width
	;
	; Calc the scaled width
	;
	clr	cx
	movwwf	bxax, widthScale		; bx:ax = width scale
	call	GrMulWWFixed			; dx.cx = adj width
	rndwwbf7	dxcx			; dx.ch = rounded width
	movwbf	ss:scaledWidth, dxch
setWidth:
	movwbf	dxch, ss:scaledWidth		; dx.ch <- rounded width
	movwbf	es:[di].CTE_width, dxch
doneChar:
	pop	ax, cx
	inc	ax				; next char
	add	di, size CharTableEntry		; move to next char table entry
;	loop	widthLoop			; do next character
	dec	cx
	LONG jnz	widthLoop

else	;---------------------------------------------------------------------

	;
	; get info for SBCS -- grab info from BFCD_charTable, sorted by
	; GEOS character set
	;
	movwwf	bxax, widthScale		; bx:ax = width scale
	mov	si, ds:[BFCD_charTable]		; ds:si = BFCD char table
widthLoop:
	push	cx
	mov	dx, ds:[si].BCTE_width		; dx.cx = width
	clr	cx
	call	GrMulWWFixed
	rndwwbf7		dxcx		; dx.ch = rounded value
	movwbf	es:[di].CTE_width, dxch
	mov	dx, CHAR_NOT_BUILT		; dx = initial flags
	mov	cl, ds:[si].BCTE_flags		; cl = CharTableFlags
	test	cl, mask CTF_NO_DATA
	jz	hasData
	mov	dx, CHAR_NOT_EXIST
hasData:
	mov	es:[di].CTE_dataOffset, dx
	mov	es:[di].CTE_flags, cl
	mov	es:[di].CTE_usage, 0
	add	si, BitstreamCharTableEntry	; advance source ptr
	add	di, size CharTableEntry		; advance dest ptr
	pop	cx
	loop	widthLoop

endif	;---------------------------------------------------------------------

	;
	; convert kerning pairs
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;
	mov	ax, ds:[BFCD_kernCount]
	mov	es:[FB_kernCount], ax
	tst	ax
	jz	noKernPairs
	mov	di, ds:[BFCD_numChars]
	;
	; NOTE: the following is not really an index, but the
	; calculation is identical.
	;
	FDIndexCharTable di, cx
	add	di, size FontBuf - size CharTableEntry + \
			size BitstreamCharGenData ; skip header and privdata
	mov	es:[FB_kernValuePtr], di
	mov	cx, ax
.assert (size BBFixed) eq 2
	shl	ax, 1
	add	ax, di
	mov	es:[FB_kernPairPtr], ax
	mov	si, ds:[BFCD_kernValuePtr]
	push	cx
	rep movsw				; copy kern values
	pop	cx
	push	cx
	rep movsw				; copy kern pairs
	pop	cx
	mov	di, es:[FB_kernValuePtr]
	movwwf	bxax, widthScale
kernLoop:
	mov	dx, es:[di]			; integer
	tst	dx
	jz	nextKern
	push	cx
	clr	cx
	call	GrMulWWFixed
	mov	({BBFixed}es:[di]).BBF_int, dl	; truncate int
	mov	({BBFixed}es:[di]).BBF_frac, ch	; truncate frac
	pop	cx
nextKern:
.assert (size word) eq (size BBFixed)
	add	di, size word
	loop	kernLoop
noKernPairs:
	;
	; compute transformation
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;
	mov	di, ds:[BFCD_numChars]		; di = # chars
	;
	; NOTE: the following is not really an index, but the
	; calculation is identical.
	;
	FDIndexCharTable di, dx
	add	di, size FontBuf - size CharTableEntry	; skip header
						; es:di = BitstreamCharGenData
	movwwf	dxcx, heightScale
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11, dxcx
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22, dxcx
	test	stylesLeft, TRANSFORM_STYLES
	jz	noStyles
	call	AddStyleTransforms
noStyles:
	;
	; adjust for width and weight
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;	es:di - BitstreamCharGenData
	;
	mov	dl, fontWidth
	cmp	dl, ds:[BFCD_fontWidth]
	je	noFMWidth
	clr	ax, cx
	mov	dh, al
	mov	bh, al
	mov	bl, ds:[BFCD_fontWidth]
	call	GrUDivWWFixed			; dx.cx = percentage
	movwwf	bxax, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11
	call	GrMulWWFixed
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11, dxcx
noFMWidth:

	mov	dl, fontWeight
	cmp	dl, ds:[BFCD_fontWeight]
	je	noFMWeight
	clr	ax, cx
	mov	dh, al
	mov	bh, al
	mov	bl, ds:[BFCD_fontWeight]
	call	GrUDivWWFixed			; dx.cx = percentage
	movwwf	bxax, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11
	call	GrMulWWFixed
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11, dxcx
noFMWeight:
	;
	; add graphics system transform
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;	es:di - BitstreamCharGenData
	;
	push	ds
	lds	si, xform			; ds:si = GState transform
	movwbf	es:[di].BCGD_fontInstID.BFIID_heightY, es:[FB_baselinePos], ax
	test	ds:[si].TM_flags, TM_COMPLEX
	jz	simpleTransform
	call	AddGraphicsTransform
simpleTransform:
	pop	ds
	;
	; convert coordinate system
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;	es:di - BitstreamCharGenData
	;
	negwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_12
	negwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_21
	;
	; convert for Bitstream matrix format
	;	ds - BitstreamFontCachedData
	;	es - FontBuf
	;
	mov	bx, ds:[BFCD_ORUsPerEm]
	mov	ax, 0
	movdw	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11
	call	GrMulWWFixed
	movdw	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11, dxcx
	movdw	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_12
	call	GrMulWWFixed
	movdw	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_12, dxcx
	movdw	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_21
	call	GrMulWWFixed
	movdw	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_21, dxcx
	movdw	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22
	call	GrMulWWFixed
	movdw	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22, dxcx
	;
	; determine if bitmap or outline output
	;
	call	UseRegionIfNeeded

	.leave
	ret
TransferData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCharExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if char exists via BFCD_charExistsTable

CALLED BY:	TransferData

PASS:		ds - BitstreamFontCachedData
		ax - SJIS char

RETURN:		Z clear if char exists (JNZ)
		Z set if doesn't exist (JZ)

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		81XX-9fXX, e0XX-efXX

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if FAST_GEN_WIDTHS
else
if DBCS_PCGEOS
CheckCharExists	proc	near
	uses	di
	.enter
	mov	bx, ax
EC <	cmp	ah, 0x81						>
EC <	ERROR_B	BITSTREAM_INTERNAL_ERROR				>
EC <	cmp	ah, 0xef						>
EC <	ERROR_A	BITSTREAM_INTERNAL_ERROR				>
EC <	cmp	ah, 0x9f						>
EC <	jbe	wardOkay						>
EC <	cmp	ah, 0xe0						>
EC <	ERROR_B	BITSTREAM_INTERNAL_ERROR				>
EC <wardOkay:								>
	sub	ah, 0x81			; normalize to zero
	cmp	ah, (0x9f-0x81)
	jbe	haveRange
	sub	ah, 0xe0-(0x9f-0x81+1)-0x81	; normalize e0XX-efXX
haveRange:
	mov	al, ah
	clr	ah
	mov	di, ax
	shl	di, 1
	shl	di, 1
	shl	di, 1
	shl	di, 1
	shl	di, 1				; *32 = 32-chunk offset
	mov	al, bl
	clr	ah
	shr	al, 1
	shr	al, 1
	shr	al, 1				; ax = offset w/in 32-chunk
	add	di, ax				; di = offset w/in table
	mov	al, bl
	andnf	al, 0x7
	mov	bx, offset charExistsMask
	xlatb	cs:				; al = bit for this char
	test	ds:[BFCD_charExistsTable][di], al
	.leave
	ret
CheckCharExists	endp

charExistsMask	label	byte
	byte	10000000b
	byte	01000000b
	byte	00100000b
	byte	00010000b
	byte	00001000b
	byte	00000100b
	byte	00000010b
	byte	00000001b
endif
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertMetrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	transfer metrics info from Bitstream cached data to FontBuf

CALLED BY:	TransferData

PASS:		ds - BitstreamFontCachedData
		es - FontBuf

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertMetrics	proc	near

	.enter inherit TransferData

	movwwf	bxax, widthScale		; bx:ax = width scale factor

	mov	dx, ds:[BFCD_minLSB]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled LSB
	rndwwbf	dxcx				; dx:ch = rounded value
	rndwbf	dxch				; dx = rounded value
	mov	es:[FB_minLSB], dx

	mov	dx, ds:[BFCD_maxRSB]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled RSB
	rndwwbf	dxcx				; dx:ch = rounded value
	rndwbf	dxch				; dx = rounded value
if not DBCS_PCGEOS
	mov	es:[FB_maxRSB], dx
endif

	mov	dx, ds:[BFCD_avgWidth]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled avg width
	rndwwbf	dxcx				; dx:ch = rounded value
	movwbf	es:[FB_avgwidth], dxch

	mov	dx, ds:[BFCD_maxWidth]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled max width
	rndwwbf	dxcx				; dx:ch = rounded value
	movwbf	es:[FB_maxwidth], dxch

	movwwf	bxax, heightScale

	mov	dx, ds:[BFCD_height]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled height
	rndwwbf	dxcx				; dx:ch = rounded value
	movwbf	es:[FB_height], dxch
	subwbf	es:[FB_heightAdjust], dxch
	rndwbf	dxch				; dx = rounded value
	mov	es:[FB_pixHeight], dx

	mov	dx, ds:[BFCD_baseAdjust]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled height adj
	rndwwbf	dxcx				; dx:ch = rounded value
	rndwbf	dxch				; dx = rounded value
	mov	es:[FB_baseAdjust].WBF_int, dx	; text object wants integer
	mov	es:[FB_baseAdjust].WBF_frac, 0

	mov	dx, ds:[BFCD_ascent]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled ascent
	rndwwbf	dxcx				; dx:ch = rounded value
	movwbf	es:[FB_baselinePos], dxch

	mov	dx, ds:[BFCD_minTSB]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled TSB
	rndwwbf	dxcx				; dx:ch = rounded value
	ceilwbf	dxch, dx			; dx = ceiling
	mov	es:[FB_aboveBox].WBF_int, dx
	mov	es:[FB_aboveBox].WBF_frac, 0
	mov	es:[FB_minTSB], dx
	add	es:[FB_pixHeight], dx		; pixHeight includes all

	mov	dx, ds:[BFCD_maxBSB]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled BSB
	rndwwbf	dxcx				; dx:ch = rounded value
	ceilwbf	dxch, dx			; dx = ceiling
	mov	es:[FB_belowBox].WBF_int, dx
	mov	es:[FB_belowBox].WBF_frac, 0
if not DBCS_PCGEOS
	mov	es:[FB_maxBSB], dx
endif

	mov	dx, ds:[BFCD_underPos]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled value
	rndwwbf	dxcx				; dx:ch = rounded value
	movwbf	es:[FB_underPos], dxch

	mov	dx, ds:[BFCD_underThickness]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled value
	rndwwbf	dxcx				; dx:ch = rounded value
	movwbf	es:[FB_underThickness], dxch

	mov	dx, ds:[BFCD_strikePos]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled value
	rndwwbf	dxcx				; dx:ch = rounded value
	movwbf	es:[FB_strikePos], dxch

	mov	dx, ds:[BFCD_mean]		; dx:cx = height of lowers
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled value
	rndwwbf	dxcx				; dx:ch = rounded value
	movwbf	es:[FB_mean], dxch

	mov	dx, ds:[BFCD_descent]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled value
	rndwwbf	dxcx				; dx:ch = rounded value
	movwbf	es:[FB_descent], dxch

	mov	dx, ds:[BFCD_accent]
	clr	cx
	call	GrMulWWFixed			; dx:cx = scaled value
	rndwwbf	dxcx				; dx:ch = rounded value
	movwbf	es:[FB_accent], dxch
	addwbf	dxch, es:[FB_baselinePos]
	rndwbf	dxch				; dx = rounded value
	mov	es:[FB_baselinePos].WBF_int, dx	; text object wants integer
	mov	es:[FB_baselinePos].WBF_frac, 0

	.leave
	ret
ConvertMetrics	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddStyleTransforms
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add style transformations info base transform

CALLED BY:	TransferData

PASS:		ds - BitstreamFontCachedData
		es:di - BitstreamCharGenData in FontBuf
		stylesLeft - styles to implement

RETURN:		matrix updated

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddStyleTransforms	proc	near
	.enter inherit TransferData
	;
	; superscript, subscript
	;
	test	stylesLeft, mask TS_SUPERSCRIPT or mask TS_SUBSCRIPT
	LONG jz	noScript
	;
	; adjust scale
	;
	mov	bx, SCRIPT_FACTOR_INT
	mov	ax, SCRIPT_FACTOR_FRAC
	movwwf	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11
	call	GrMulWWFixed
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11, dxcx
	movwwf	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22
	call	GrMulWWFixed
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22, dxcx
	;
	; adjust vertical position
	;
	clr	cl				; dx:cx = font height
	movwbf	dxch, es:[FB_height]
	addwbf	dxch, es:[FB_heightAdjust]
	test	stylesLeft, mask TS_SUBSCRIPT
	jnz	isSubScript
	;
	; do superscript positioning
	;
	mov	bx, SUPERSCRIPT_OFFSET_INT
	mov	ax, SUPERSCRIPT_OFFSET_FRAC
	call	GrMulWWFixed
	subwbf	dxch, es:[FB_baselinePos]
	subwbf	dxch, es:[FB_baseAdjust]
	jmp	finishScript

isSubScript:
	mov	bx, SUBSCRIPT_OFFSET_INT
	mov	ax, SUBSCRIPT_OFFSET_FRAC
	call	GrMulWWFixed
finishScript:
	rndwbf	dxch				; dx = rounded value
	mov	es:[di].BCGD_fontInstID.BFIID_scriptY, dx

noScript:
if 0
;bold handled with font weight
	;
	; bold
	;
	test	stylesLeft, mask TS_BOLD
	jz	noBold
	;
	; scale for bold (TM11 = TM11*bold)
	;
	movwwf	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11
	mov	bx, BOLD_FACTOR_INT
	mov	ax, BOLD_FACTOR_FRAC
	call	GrMulWWFixed
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11, dxcx
noBold:
endif
	;
	; italic
	;
	test	stylesLeft, mask TS_ITALIC
	jz	noItalic
	;
	; scale for italic (TM21 = TM22*italic)
	;
	movwwf	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22
	mov	bx, NEG_ITALIC_FACTOR_INT
	mov	ax, NEG_ITALIC_FACTOR_FRAC
	call	GrMulWWFixed
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_21, dxcx
noItalic:
	.leave
	ret
AddStyleTransforms	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddGraphicsTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add graphics transformation info base transform

CALLED BY:	TransferData

PASS:		ds:si - graphics transform
		es:di - BitstreamCharGenData in FontBuf

RETURN:		matrix updated

DESTROYED:	

PSEUDO CODE/STRATEGY:
		FM = current font matrix
		GM = graphics matrix

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddGraphicsTransform	proc	near

tmpMatrix	local	FontMatrix

	.enter

	ornf	es:[FB_flags], mask FBF_IS_COMPLEX

	test	ds:[si].TM_flags, TM_ROTATED
	LONG jnz	rotateStart
afterRotateStart:
	;
	; FM11 = FM11 * GM11
	;
	movwwf	bxax, ds:[si].TM_11
	movwwf	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11
	call	GrMulWWFixed
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11, dxcx
	;
	; FM21 = FM21 * GM11
	;
	movwwf	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_21
	call	GrMulWWFixed
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_21, dxcx
	;
	; FM22 = FM22 * GM22
	;
	movwwf	bxax, ds:[si].TM_22
	movwwf	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22
	call	GrMulWWFixed
	movwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22, dxcx
	;
	; adjust fields in FontBuf for new scaling (GM22)
	;	bxax = GM22
	;
	movwbf	dxch, es:[FB_height]
	clr	cl
	call	GrMulWWFixed
	mov	es:[FB_pixHeight], dx

	mov	dx, es:[FB_minTSB]
	clr	cx
	call	GrMulWWFixed
	mov	es:[FB_minTSB], dx
	add	es:[FB_pixHeight], dx

	movwbf	dxch, es:[FB_baselinePos]
	clr	cl
	call	GrMulWWFixed			; dx:cx = baseline * scale
	rndwwbf	dxcx				; dx:ch = rounded
	movwbf	es:[di].BCGD_fontInstID.BFIID_heightY, dxch

	mov	dx, es:[di].BCGD_fontInstID.BFIID_scriptY
	clr	cx
	call	GrMulWWFixed
	rndwwf	dxcx
	mov	es:[di].BCGD_fontInstID.BFIID_scriptY, dx

	test	ds:[si].TM_flags, TM_ROTATED
	jnz	rotateEnd
afterRotateEnd:

	.leave
	ret

rotateStart:
	;
	; save current font matrix into temporary matrix
	;
	movwwf	tmpMatrix.FM_11, \
			es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11, ax
	movwwf	tmpMatrix.FM_12, \
			es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_12, ax
	movwwf	tmpMatrix.FM_21, \
			es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_21, ax
	movwwf	tmpMatrix.FM_22, \
			es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22, ax
	;
	; save y offset
	;
	push	es:[di].BCGD_fontInstID.BFIID_scriptY
	jmp	afterRotateStart

rotateEnd:
	;
	; FM21 += FM22 * GM21
	;
	movwwf	bxax, ds:[si].TM_21
	movwwf	dxcx, tmpMatrix.FM_22
	call	GrMulWWFixed
	addwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_21, dxcx
	;
	; FM12 += FM11 * GM12
	;
	movwwf	bxax, ds:[si].TM_12
	movwwf	dxcx, tmpMatrix.FM_11
	call	GrMulWWFixed
	addwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_12, dxcx
	;
	; FM22 += FM21 * GM12
	;
	movwwf	dxcx, tmpMatrix.FM_21
	call	GrMulWWFixed
	addwwf	es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22, dxcx
	;
	; update position for rotation
	;
	movwwf	bxax, ds:[si].TM_21		; bxax = GM21
	pop	dx
	mov	cx, 0				; dx:cx = y offset
	call	GrMulWWFixed
	rndwwf	dxcx
	mov	es:[di].BCGD_fontInstID.BFIID_scriptX, dx
	movwbf	dxch, es:[FB_baselinePos]	; dx:cx = height above baseline
	mov	cl, 0
	call	GrMulWWFixed
	rndwwf	dxcx
	mov	es:[di].BCGD_fontInstID.BFIID_heightX, dx
	jmp	afterRotateEnd

AddGraphicsTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UseRegionIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	if character is big, use regions

CALLED BY:	BitstreamGenWidths

PASS:		ds - BitstreamFontCachedData
		es - FontBuf
		es:di - BitstreamCharGenData

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UseRegionIfNeeded	proc	near
	.enter inherit TransferData
	;
	; if character is large (or rotation causes offsets to be large),
	; use region
	;
	movwwf	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_11
	rndwwf	dxcx
	Abs	dx
	movwwf	bxax, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_21
	rndwwf	bxax
	Abs	bx
	add	dx, bx
	cmp	dx, MAX_BITMAP_SIZE
	LONG ja	useRegion
	movwwf	dxcx, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_22
	rndwwf	dxcx
	Abs	dx
	movwwf	bxax, es:[di].BCGD_fontInstID.BFIID_transMatrix.FM_12
	rndwwf	bxax
	Abs	bx
	add	dx, bx
	cmp	dx, MAX_BITMAP_SIZE
	ja	useRegion
	;
	; if character is not large, but subscript offset is large,
	; use regions
	;
	test	stylesLeft, mask TS_SUBSCRIPT
	jz	done
	mov	ax, es:[di].BCGD_fontInstID.BFIID_scriptX
	Abs	ax
	mov	dx, es:[di].BCGD_fontInstID.BFIID_heightX
	Abs	dx
	add	ax, dx				; ax = x script offset
	add	ax, SCRIPT_SAFETY_SIZE		; "kind of a hack..."
	cmp	ax, MAX_BITMAP_SIZE
	ja	useRegion
	mov	ax, es:[di].BCGD_fontInstID.BFIID_scriptY
	Abs	ax
	movwbf	bxch, es:[di].BCGD_fontInstID.BFIID_heightY
	rndwbf	bxch
	Abs	bx
	add	ax, bx				; ax = y script offset
	add	ax, SCRIPT_SAFETY_SIZE		; "kind of a hack..."
	cmp	ax, MAX_BITMAP_SIZE
	ja	useRegion
done:
	.leave
	ret

useRegion:
	ornf	es:[FB_flags], mask FBF_IS_REGION
	jmp	short done

UseRegionIfNeeded	endp
