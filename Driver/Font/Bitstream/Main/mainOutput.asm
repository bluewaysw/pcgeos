COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainOutput.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	sp_open_bitmap		output character
EXT	sp_set_bitmap_bits	output character
EXT	sp_close_bitmap		output character

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/12/93	Initial version.

DESCRIPTION:
	This file contains GEOS Bitstream Font Driver routines.

	$Id: mainOutput.asm,v 1.1 97/04/18 11:45:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


	SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_open_bitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	begin bitmap output

CALLED BY:	Bitstream C code

PASS:		sp_open_bitmap(fix31 x_set_width, fix31 y_set_width,
				fix31 xorg, fix31 yorg,
				fix15 xsize, fix15 ysize)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_open_bitmap	proc	far	x_set_width:WWFixed, y_set_width:WWFixed,
				xorg:WWFixed, yorg:WWFixed,
				xsize:word, ysize:word
ForceRef x_set_width
ForceRef y_set_width

	uses	ds, es, di, si

	.enter

	segmov	es, dgroup, ax
	;
	; compute info for bitmap header
	; (info needed for both bitmap and region...)
	;
	mov	ax, xsize			; width
	tst	ax
	jns	widthOkay			; ensure minimum width
	mov	ax, 0
	mov	xsize, ax
widthOkay:
	mov	es:[outputInfo].OI_charWidth, ax
	mov	ax, ysize			; height
	tst	ax
	jns	heightOkay			; ensure minimum height
	mov	ax, 1				; at least 1
	mov	ysize, ax
heightOkay:
	mov	es:[outputInfo].OI_charHeight, ax
	;
	; compute X offset for character
	;
	movwwf	axdx, xorg			; xoffset
	rndwwf	axdx				; ax = rounded value
	add	ax, es:[outputInfo].OI_scriptX	; script/rotation adjustment
	add	ax, es:[outputInfo].OI_heightX
	mov	es:[outputInfo].OI_charXOffset, ax
	;
	; GEOS Y offset = FB_baselinePos (scaled) - Bitstream Y offset - height
	;
					; ax:dh = FB_baselinePos (scaled)
	movwbf	axdh, es:[outputInfo].OI_heightY
	movwwf	bxcx, yorg			; bx:dx = Bitstream y offset
	rndwwbf	bxcx				; bx:ch = Bitstream y offset
	subwbf	axdh, bxch
	mov	bx, es:[outputInfo].OI_charHeight	; bx:ch = height
	mov	ch, 0
	subwbf	axdh, bxch
	rndwbf	axdh				; ax = rounded value
	add	ax, es:[outputInfo].OI_scriptY	; script/rotation adjustment
	mov	es:[outputInfo].OI_charYOffset, ax
EC <	;								>
EC <	; check if forcing regions (GEN_IN_REGION)			>
EC <	;								>
EC <	tst	es:[outputInfo].OI_forceRegion				>
EC <	ERROR_NZ	BITSTREAM_INTERNAL_ERROR			>
	;
	; check if doing regions or bitmaps
	;
	mov	ds, es:[outputInfo].OI_fontBuf
	test	ds:[FB_flags], mask FBF_IS_REGION
	LONG jnz	useRegion
	;
	; compute size of bitmap needed
	;
	mov	ax, xsize			; bit width
	add	ax, 0x7				; round up
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1				; ax = byte width
	mov	es:[outputInfo].OI_byteWidth, ax
	mov	bx, es:[outputInfo].OI_charHeight
	mul	bx				; dx:ax = size
	tst	dx
	LONG jnz	useRegion			; too big, use region
	mov	es:[outputInfo].OI_bitmapMode, BB_TRUE
	push	ax				; data size w/o header
	add	ax, (size CharData) - size (CD_data)
	;
	; delete LRU character if block getting too large
	;	ax = size of new character data
	;	es = dgroup
	;
	call	ResizeFontBufForChar
	;
	; initialize bitmap header (all relevant fields are byte-sized)
	;	ds:si = bitmap
	;
	mov	ax, es:[outputInfo].OI_charWidth
EC <	mov	bx, ax							>
EC <	Abs	bx							>
EC <	tst	bh							>
EC <	ERROR_NZ	FONT_CHAR_TOO_BIG				>
	mov	ds:[si].CD_pictureWidth, al
	mov	ax, es:[outputInfo].OI_charHeight
EC <	mov	bx, ax							>
EC <	Abs	bx							>
EC <	tst	bh							>
EC <	ERROR_NZ	FONT_CHAR_TOO_BIG				>
	mov	ds:[si].CD_numRows, al
	mov	ax, es:[outputInfo].OI_charXOffset
EC <	mov	bx, ax							>
EC <	Abs	bx							>
EC <	tst	bh							>
EC <	ERROR_NZ	FONT_CHAR_TOO_BIG				>
	mov	ds:[si].CD_xoff, al
	mov	ax, es:[outputInfo].OI_charYOffset
EC <	mov	bx, ax							>
EC <	Abs	bx							>
EC <	tst	bh							>
EC <	ERROR_NZ	FONT_CHAR_TOO_BIG				>
	mov	ds:[si].CD_yoff, al
	;
	; zero out rest of data
	;
	pop	cx				; cx = size of data w/o header
	segmov	es, ds
	lea	di, ds:[si].CD_data		; es:di = data
	mov	al, 0
	rep stosb

done:
	.leave
	ret

useRegion:
	;
	; character is too big to generate bitmap for, use region
	;	es = dgroup
	;
	segmov	ds, es				; ds = dgroup
	mov	ds:[outputInfo].OI_bitmapMode, BB_FALSE
						; handle of block for region
	push	bp
	mov	di, ds:[outputInfo].OI_regionHandle
	mov	cx, RFR_ODD_EVEN or (UNUSED_PER_LINE shl 8)
	clr	bp				; minimum y
	mov	dx, ds:[outputInfo].OI_charHeight	; maximum y
	call	GrRegionPathInit		; es = segment of block
	pop	bp
						; cx = size of block
	mov	ds:[outputInfo].OI_regionSeg, es
	jmp	short done

sp_open_bitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeFontBufForChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	resize FontBuf for new CharData or RegionCharData

CALLED BY:	sp_open_bitmap (for CharData)
		sp_close_bitmap (for RegionCharData)

PASS:		es - dgroup
		ax - size of CharData or RegionCharData

RETURN:		ds:si = new CharData, RegionCharData

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/20/93	broke out of sp_open_bitmap

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeFontBufForChar	proc	near
	mov	ds, es:[outputInfo].OI_fontBuf		; ds = FontBuf
	mov	cx, ds:[FB_dataSize]		; cx = current FontBuf size
	mov	bx, cx
	add	bx, ax				; bx = new size
	cmp	bx, MAX_FONT_SIZE		; will be too big?
	jbe	sizeOK				; nope, allocate it
	call	FontDrDeleteLRUChar		; else, delete LRU char
	mov	cx, ds:[FB_dataSize]		; cx = shrunken size
sizeOK:
	;
	; store data offset in char table and allocate space for data
	;	ds = FontBuf
	;	cx = offset for character data
	;	ax = size of new character data
	;	es = dgroup
	;
	mov	dx, es:[outputInfo].OI_character	; dx = GEOS char (SBCS)
							; dx = Unicode (DBCS)
DBCS <	sub	dx, ds:[FB_firstChar]					>
SBCS <	sub	dl, ds:[FB_firstChar]					>
	mov	di, dx
	FDIndexCharTable di, dx			;di <- pffset to CharTableEntry
	mov	ds:[FB_charTable][di].CTE_dataOffset, cx
	mov	si, cx				; ds:si = data
	mov	es:[outputInfo].OI_dataOffset, cx	; store data offset for
						;	other output routines
	add	ax, cx				; ax = new data size
	mov	ds:[FB_dataSize], ax		; update data size
	mov	ch, HAF_STANDARD_NO_ERR
	mov	bx, es:[outputInfo].OI_fontBufHan
	call	MemReAlloc			; add space for new character
	mov	es:[outputInfo].OI_fontBuf, ax	; store updated segment
	mov	ds, ax
	ret
ResizeFontBufForChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_set_bitmap_bits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bitmap output

CALLED BY:	Bitstream C code

PASS:		sp_set_bitmap_bits(fix15 y, fix15 xbit1, fix15 xbit2)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_set_bitmap_bits	proc	far	scan_line:word, xbit1:word, xbit2:word

	uses	ds, es, si, di

	.enter

	segmov	es, dgroup, ax

	tst	es:[outputInfo].OI_bitmapMode
	jnz	bitmapMode
EC <	;								>
EC <	; check if forcing regions (GEN_IN_REGION)			>
EC <	;								>
EC <	tst	es:[outputInfo].OI_forceRegion				>
EC <	ERROR_NZ	BITSTREAM_INTERNAL_ERROR			>
	;
	; region mode -- set points in region for this scanline
	;
	segmov	ds, es					; ds = dgroup
	mov	es, ds:[outputInfo].OI_regionSeg	; es = region segment
	mov	cx, xbit1
	mov	dx, scan_line
	call	GrRegionPathAddOnOffPoint
	mov	ds:[outputInfo].OI_regionSeg, es	; updated segment
	mov	cx, xbit2
	mov	dx, scan_line
	call	GrRegionPathAddOnOffPoint
	mov	ds:[outputInfo].OI_regionSeg, es	; updated segment
	jmp	done

bitmapMode:
	;
	; bitmap mode, build out this scanline of bitmap
	;
	mov	ds, es:[outputInfo].OI_fontBuf	; ds:si = CharData
	mov	si, es:[outputInfo].OI_dataOffset
	mov	ax, scan_line
EC <	cmp	ax, es:[outputInfo].OI_charHeight			>
EC <	ERROR_AE	FONT_CHAR_TOO_BIG				>
	mov	bx, es:[outputInfo].OI_byteWidth
EC <	tst	bh							>
EC <	ERROR_NZ	FONT_CHAR_TOO_BIG				>
	mul	bl
	mov	di, ax				; di = offset to scan-line
	mov	cx, xbit1
	tst	cx
	jns	leftPos
	mov	cx, 0
leftPos:
	cmp	cl, ds:[si].CD_pictureWidth
	jbe	leftOkay
	mov	cl, ds:[si].CD_pictureWidth
	mov	xbit1, cx
leftOkay:
	mov	dx, xbit2
	tst	dx
	jns	rightPos
	mov	dx, 0
rightPos:
	cmp	dl, ds:[si].CD_pictureWidth
	jbe	rightOkay
	mov	dl, ds:[si].CD_pictureWidth
	mov	xbit2, dx
rightOkay:
EC <	cmp	cx, dx							>
EC <	ERROR_A		FONT_CHAR_TOO_BIG				>
	add	si, offset CD_data		; ds:si = CD_data
	shr	cx, 1				; convert xbit1 to byte
	shr	cx, 1
	shr	cx, 1
	shr	dx, 1				; convert xbit2 to byte
	shr	dx, 1
	shr	dx, 1
	cmp	cx, dx				; same byte?
	jne	diffByte			; no
	;
	; same byte: cx = dx = (xbit1 >> 3) = (xbit2 >> 3) = byte offset
	; within scan-line
	;	ds:si = CD_data
	;	di = scan-line offset from CD_data
	;
	add	di, cx				; di = offset from CD_data
	mov	bx, xbit1
	andnf	bx, 0x7				; bx = start bit offset
	mov	al, cs:[startBitTable][bx]
	mov	bx, xbit2
	andnf	bx, 0x7				; bx = end bit offset
	andnf	al, cs:[endBitTable][bx]	; combine start/end byte bits
	mov	bx, di
	ornf	ds:[si][bx], al			; store bits

done:
	.leave
	ret

diffByte:
	;
	; start and end on different bytes
	;	ds:si = CD_data
	;	cx = start byte
	;	dx = end byte
	;	di = scan-line offset from CD_data
	;
	add	dx, di				; dx = end byte offset
	add	di, cx				; di = start offset from CD_data
	mov	bx, xbit1
	andnf	bx, 0x7				; bx = start bit offset
	mov	al, cs:[startBitTable][bx]
	mov	bx, di
	ornf	ds:[si][bx], al			; store start bits
byteLoop:
	inc	di
	cmp	di, dx				; reached end byte?
	je	endByte
	mov	bx, di
	mov	{byte}ds:[si][bx], 0xff		; set all intermediate bits
	jmp	short byteLoop

endByte:
	mov	bx, xbit2
	andnf	bx, 0x7				; bx = end bit offset
	mov	al, cs:[endBitTable][bx]
	mov	bx, di
	ornf	ds:[si][bx], al			; store end bits
	jmp	short done

sp_set_bitmap_bits	endp

startBitTable	byte	11111111b
		byte	01111111b
		byte	00111111b
		byte	00011111b
		byte	00001111b
		byte	00000111b
		byte	00000011b
		byte	00000001b

endBitTable	byte	00000000b
		byte	10000000b
		byte	11000000b
		byte	11100000b
		byte	11110000b
		byte	11111000b
		byte	11111100b
		byte	11111110b


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_close_bitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	finish bitmap output

CALLED BY:	Bitstream C code

PASS:		sp_close_bitmap()

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_close_bitmap	proc	far

	uses	ds, es, si, di

	.enter

	segmov	es, dgroup, ax

EC <	;								>
EC <	; check if forcing regions (GEN_IN_REGION)			>
EC <	;								>
EC <	tst	es:[outputInfo].OI_forceRegion				>
EC <	ERROR_NZ	BITSTREAM_INTERNAL_ERROR			>
	;
	; check for bitmap mode, region mode
	;
	tst	es:[outputInfo].OI_bitmapMode
	jnz	done				; nothing for bitmap mode
	;
	; region mode -- create RegionCharData in FontBuf from regionHandle
	; block
	;
	push	es				; save dgroup
	mov	es, es:[outputInfo].OI_regionSeg
	call	GrRegionPathClean		; cx = region size
	pop	es				; es = dgroup
	mov	ax, cx
	push	ax				; save data size
	add	ax, SIZE_REGION_HEADER		; RegionCharData header
	push	ax				; save total size
	call	ResizeFontBufForChar		; ds:si = RegionCharData
	;
	; initialize RegionCharData header
	;	ds:si = RegionCharData
	;	es = dgroup
	;
	pop	ds:[si].RCD_size		; RegionCharData total size
	mov	ax, es:[outputInfo].OI_charXOffset
	mov	ds:[si].RCD_xoff, ax
	mov	ax, es:[outputInfo].OI_charYOffset
	mov	ds:[si].RCD_yoff, ax
if DBCS_PCGEOS
	mov	ax, ds:FB_heapCount
	mov	ds:[si].RCD_usage, ax
endif
	;
	; copy over RCD_bounds and RCD_data from regionHandle
	;	ds:si = RegionCharData
	;	es = dgroup
	;
	pop	cx				; cx = data size
	push	es				; save dgroup
	mov	ax, es:[outputInfo].OI_regionSeg
	segmov	es, ds				; es:di = RCD_bounds
	lea	di, ds:[si].RCD_bounds
	mov	ds, ax				; ds:si = region bounds/data
	mov	si, offset RP_bounds
	shr	cx, 1				; cx = # words to copy
EC <	ERROR_C	BITSTREAM_INTERNAL_ERROR				>
	rep movsw
EC <	segmov	ds, es							>
EC <	mov	si, di							>
EC <	dec	si							>
EC <	call	ECCheckBounds						>
	pop	ds				; ds = dgroup
	;
	; unlock regionHandle
	;
	mov	bx, ds:[outputInfo].OI_regionHandle
	call	MemUnlock
done:
	.leave
	ret
sp_close_bitmap	endp

	SetDefaultConvention
