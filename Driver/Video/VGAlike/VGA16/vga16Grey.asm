COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PROJECT:	PC GEOS
MODULE:		VGA16 Video Driver
FILE:		vga16Grey.asm

DESCRIPTION:
	Greyscale characters (font buffers with FBF_IS_GREY, GreyCharData,
	see fontDr.def): 4 bits of coverage per pixel, blended with the
	screen in 16 bit (5-6-5) color.

	Where the character code draws:
	    FastCharCommon (fully visible, MM_COPY, solid)  -> GreyBlit
	    CLCh_CharClip (clipped by a simple clip rect)   -> GreyClipChar
	    CharGeneralRealSlow (everything else)	    -> GreyToMono,
		then the normal 1 bit code (coverage >= 8 is ink)

	Subpixel positioning: in fonts with FBF_GREY_PHASES (small sizes) a
	greyscale character holds GREY_PHASES bitmaps, shifted by -1/2,
	-1/4, 0, +1/4 pixel. CharLowFast and
	CharLowCheck save the fraction of the pen position (greyFrac) before
	they round it; GreyBlit draws the phase closest to it, GreyToMono
	uses the unshifted one.

	The blend tables are computed per text color (GreyEnsureTables):
	    tab[c][d] = d + (ink - d) * c / 15	for each color component.

	The driver announces the capability with VID_ESC_GREY_TEXT; only
	then does the font manager request greyscale fonts.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;
; VID_ESC_GREY_TEXT: just being in the escape table is the answer.
;
VidEscGreyText	proc	near
		ret
VidEscGreyText	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GreyCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Is the current font greyscale?
PASS:		gs	- code (PSL_saveGState set by VidPutString)
RETURN:		ZF clear (jnz) if greyscale
DESTROYED:	nothing (flags)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GreyCheck	proc	near
		push	ds
		mov	ds, gs:[PSL_saveGState]
		test	ds:[GS_fontFlags], mask FBF_IS_GREY
		pop	ds
		ret
GreyCheck	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GreyClipChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Greyscale character clipped by the simple clip rect
		(from CharLowCheck). Jmp'able only.
PASS:		ax - x position, bx - top line, cx - right edge,
		dx - bottom line, ds - Window, es:si - char data,
		on stack - new x position
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GreyClipChar	label	near
		;
		; Blend only for plain drawing: MM_COPY and a solid mask.
		; Anything else goes the 1 bit way.
		;
		test	fs:[stateFlags], mask AO_MASK_1
		jz	GCC_toMono
		push	ds
		mov	ds, gs:[PSL_saveGState]
		cmp	ds:[GS_mixMode], MM_COPY
		pop	ds
		jne	GCC_toMono
		call	CheckCollisionsDS
		sub	dx, bx
		inc	dx				; dx <- rows
		mov	cx, ds:[W_clipRect.R_left]	; cx <- clip left
		mov	bp, ds:[W_clipRect.R_right]	; bp <- clip right
		segmov	ds, es				; ds:si <- char data
		jmp	GreyBlit

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GreyMaskChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Greyscale character partially visible in a complex clip
		region (from CharClip). Blended and clipped row by row if
		every row lies in a null or simple clip band (WinValClipLine);
		otherwise, and for patterns or other mix modes, it goes the
		1 bit way (CharClipMono). Jmp'able only.
PASS:		ax - x position, bx - top line, cx - right edge,
		dx - bottom line, ds - Window, es:si - char data,
		on stack - new x position
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GreyMaskChar	label	near
		test	fs:[stateFlags], mask AO_MASK_1
		jz	GMC_mono
		push	ds
		mov	ds, gs:[PSL_saveGState]
		cmp	ds:[GS_mixMode], MM_COPY
		pop	ds
		jne	GMC_mono
		;
		; Every row in a null or simple clip band?
		;
		push	ax, bx, si, di
GMC_checkRow:
		cmp	bx, dx
		jg	GMC_allSimple
		cmp	bx, ds:[W_clipRect.R_top]
		jl	GMC_valClip
		cmp	bx, ds:[W_clipRect.R_bottom]
		jle	GMC_haveClip
GMC_valClip:
		call	WinValClipLine			; destroys ax, si, di
GMC_haveClip:
		test	ds:[W_grFlags], mask WGF_CLIP_NULL or mask WGF_CLIP_SIMPLE
		jz	GMC_complexBand			; band with holes
		inc	bx
		jmp	GMC_checkRow
GMC_complexBand:
		pop	ax, bx, si, di
GMC_mono:
		jmp	CharClipMono
GMC_allSimple:
		pop	ax, bx, si, di
		call	CheckCollisionsDS
		mov	fs:[greyRowClip], TRUE
		mov	fs:[greyWinSeg], ds
		sub	dx, bx
		inc	dx				; dx <- rows
		segmov	ds, es				; ds:si <- char data
		jmp	GreyBlitRowClip
GCC_toMono:
		jmp	CharClip			; ends in
							;  CharGeneralRealSlow

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GreyBlit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Blend a greyscale character into the screen. Jmp'able only.
PASS:		ax - x position (left), bx - top line, dx - # of rows,
		ds:si - GreyCharData, cx - clip left, bp - clip right,
		fs - dgroup, gs - code,
		on stack - new x position
RETURN:		ax - new x position, continues at PSL_afterDraw
DESTROYED:	bx, cx, dx, si, di, bp, ds, es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GreyBlit	label	near
		mov	fs:[greyRowClip], FALSE
		mov	fs:[greyClipL], cx
		mov	fs:[greyClipR], bp
GreyBlitRowClip	label	near
		mov	fs:[greyLeft], ax
		mov	fs:[greyTop], bx
		mov	fs:[greyRows], dx
		mov	fs:[greyCharSeg], ds
		clr	ah
		mov	al, ds:[si].GCD_pictureWidth
		mov	fs:[greyWidth], ax
		inc	ax
		shr	ax, 1				; 2 pixels per byte
		mov	fs:[greyBpr], ax
		;
		; Subpixel phase: the char is drawn at its pen position rounded
		; to a pixel (CharLowFast/CharLowCheck), so the remaining shift
		; is the fraction as a signed byte, -1/2..+1/2 pixel. Pick the
		; nearest phase (shifts -1/2, -1/4, 0, +1/4, see fontDr.def).
		;
		push	ds
		mov	ds, gs:[PSL_saveGState]
		test	ds:[GS_fontFlags], mask FBF_GREY_PHASES
		pop	ds
		jz	GB_onePhase			; larger sizes: no phases
		mov	al, fs:[greyFrac]
		cbw					; ax <- shift * 256
		add	ax, 256 / GREY_PHASES / 2	; round
		sar	ax, 6				; ax <- shift in phases
		cmp	ax, GREY_PHASES - 1 - GREY_PHASE_ZERO
		jle	GB_phaseOK
		mov	ax, GREY_PHASES - 1 - GREY_PHASE_ZERO
GB_phaseOK:
		add	ax, GREY_PHASE_ZERO		; ax <- phase
		mul	fs:[greyBpr]			; ax <- phase * bytes/row
		mov	cl, ds:[si].GCD_numRows
		clr	ch
		mul	cx				; ax <- offset of phase
		add	si, ax
GB_onePhase:
		add	si, offset GCD_data
		mov	fs:[greyData], si
		call	GreyEnsureTables

GB_rowLoop:
		tst	fs:[greyRows]
		jz	GB_done
		;
		; Visible part of this row: clip range cx..bp, fixed or from
		; the row's clip band (GreyMaskChar).
		;
		mov	cx, fs:[greyClipL]
		mov	bp, fs:[greyClipR]
		tst	fs:[greyRowClip]
		jz	GB_haveRange
		mov	ds, fs:[greyWinSeg]
		mov	bx, fs:[greyTop]
		cmp	bx, ds:[W_clipRect.R_top]
		jl	GB_valClip
		cmp	bx, ds:[W_clipRect.R_bottom]
		jle	GB_haveClip
GB_valClip:
		call	WinValClipLine			; destroys ax, si, di
GB_haveClip:
		test	ds:[W_grFlags], mask WGF_CLIP_NULL
		jnz	GB_skipRow
		mov	cx, ds:[W_clipRect.R_left]
		mov	bp, ds:[W_clipRect.R_right]
GB_haveRange:
		mov	ax, fs:[greyLeft]
		mov	dx, ax
		add	dx, fs:[greyWidth]
		dec	dx				; dx <- right edge
		cmp	ax, cx
		jge	GB_leftOK
		mov	ax, cx
GB_leftOK:
		cmp	dx, bp
		jle	GB_rightOK
		mov	dx, bp
GB_rightOK:
		cmp	ax, dx
		jg	GB_skipRow			; nothing visible
		mov	fs:[greyX0], ax
		mov	fs:[greyX1], dx
		;
		; Copy the row's coverage to greyRowBuf (ds and es are
		; needed for the frame buffer below).
		;
		mov	ds, fs:[greyCharSeg]
		mov	si, fs:[greyData]
		mov	cx, fs:[greyBpr]
		segmov	es, fs
		mov	di, offset greyRowBuf
		rep	movsb
		mov	fs:[greyData], si
		;
		; ds:di <- read, es:di <- write pointer for (x0, y)
		;
		mov	bx, fs:[greyTop]
		mov	dx, fs:[greyX0]
		shl	dx, 1				; 2 bytes per pixel
		CalcScanLineBoth bx, dx, es, ds
		mov	di, bx
		mov	cx, fs:[greyX0]
		sub	cx, fs:[greyLeft]		; cx <- index in char
GB_pixLoop:
		mov	si, cx
		shr	si, 1
		mov	al, fs:greyRowBuf[si]
		test	cl, 1
		jnz	GB_lowNibble
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		jmp	GB_haveCoverage
GB_lowNibble:
		and	al, 0x0f
GB_haveCoverage:
		tst	al
		jz	GB_nextPixel			; background
		cmp	al, GREY_LEVELS-1
		jne	GB_blend
		mov	ax, fs:[currentColor]		; full ink
		mov	es:[di], ax
		jmp	GB_nextPixel
GB_blend:
		call	GreyBlendPixel
GB_nextPixel:
		inc	cx
		mov	ax, cx
		add	ax, fs:[greyLeft]
		cmp	ax, fs:[greyX1]
		jg	GB_rowDone
		NextScanBoth	di, 2
		jmp	GB_pixLoop
GB_rowDone:
		inc	fs:[greyTop]
		dec	fs:[greyRows]
		jmp	GB_rowLoop
GB_skipRow:
		mov	ax, fs:[greyBpr]
		add	fs:[greyData], ax		; next row of char data
		jmp	GB_rowDone
GB_done:
		pop	ax				; ax <- new x position
		jmp	PSL_afterDraw

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GreyBlendPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Blend the text color into one pixel.
PASS:		al - coverage (1..GREY_LEVELS-2)
		ds:di - pixel to read, es:di - pixel to write
		fs - dgroup (blend tables valid)
DESTROYED:	ax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GreyBlendPixel	proc	near
		uses	bx, cx, dx, si
		.enter
		clr	ah
		mov	si, ax				; si <- coverage
		mov	dx, ds:[di]			; dx <- screen pixel
		;
		; red: greyTabR[c * 32 + (p >> 11)]
		;
		mov	bx, si
		shl	bx, 5
		mov	ax, dx
		shr	ax, 11
		add	bx, ax
		mov	cl, fs:greyTabR[bx]
		;
		; green: greyTabG[c * 64 + ((p >> 5) & 63)]
		;
		mov	bx, si
		shl	bx, 6
		mov	ax, dx
		shr	ax, 5
		and	ax, 0x3f
		add	bx, ax
		mov	ch, fs:greyTabG[bx]
		;
		; blue: greyTabB[c * 32 + (p & 31)]
		;
		mov	bx, si
		shl	bx, 5
		mov	ax, dx
		and	ax, 0x1f
		add	bx, ax
		clr	ah
		mov	al, fs:greyTabB[bx]
		;
		; ax <- (r << 11) | (g << 5) | b
		;
		mov	bl, ch
		clr	bh
		shl	bx, 5
		or	ax, bx
		mov	bl, cl
		clr	bh
		shl	bx, 11
		or	ax, bx
		mov	es:[di], ax
		.leave
		ret
GreyBlendPixel	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GreyEnsureTables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Compute the blend tables for fs:[currentColor], unless
		they are for that color already.
		tab[c][d] = d + ((ink - d) * c * 273 + 2048) >> 12
		(273/4096 ~ 1/15; c = 15 gives the ink color exactly)
PASS:		fs - dgroup
DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GreyEnsureTables	proc	near
		uses	ax, bx, cx, dx, si, di
		.enter
		mov	ax, fs:[currentColor]
		tst	fs:[greyTabValid]
		jz	compute
		cmp	ax, fs:[greyTabColor]
		je	done
compute:
		mov	fs:[greyTabColor], ax
		mov	fs:[greyTabValid], TRUE
		;
		; red
		;
		mov	si, ax
		shr	si, 11				; si <- ink red
		mov	di, offset greyTabR
		mov	cx, 32
		call	GreyFillTable
		;
		; green
		;
		mov	si, fs:[currentColor]
		shr	si, 5
		and	si, 0x3f			; si <- ink green
		mov	di, offset greyTabG
		mov	cx, 64
		call	GreyFillTable
		;
		; blue
		;
		mov	si, fs:[currentColor]
		and	si, 0x1f			; si <- ink blue
		mov	di, offset greyTabB
		mov	cx, 32
		call	GreyFillTable
done:
		.leave
		ret
GreyEnsureTables	endp

;
; Fill one table: fs:di <- GREY_LEVELS rows of cx entries.
; PASS: si - ink component, cx - # of values of the component
; DESTROYED: ax, bx, dx, di
;
GreyFillTable	proc	near
		uses	bp
		.enter
		clr	bp				; bp <- coverage c
levelLoop:
		clr	bx				; bx <- screen value d
valueLoop:
		mov	ax, si
		sub	ax, bx				; ax <- ink - d
		imul	bp				; dx:ax <- (ink - d) * c
		push	bx
		mov	bx, 273
		imul	bx				; dx:ax <- * 273
		add	ax, 2048
		adc	dx, 0
		mov	al, ah				; dx:ax >> 12
		mov	ah, dl
		sar	ax, 1
		sar	ax, 1
		sar	ax, 1
		sar	ax, 1
		pop	bx
		add	ax, bx				; ax <- d + delta
		mov	fs:[di], al
		inc	di
		inc	bx
		cmp	bx, cx
		jb	valueLoop
		inc	bp
		cmp	bp, GREY_LEVELS
		jb	levelLoop
		.leave
		ret
GreyFillTable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GreyToMono
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Convert a greyscale character to 1 bit CharData in
		greyMonoBuf (coverage >= GREY_LEVELS/2 is ink), for the
		code paths that only draw 1 bit characters.
PASS:		es:si - GreyCharData, or the converted CharData already
			(greyMonoBuf): then nothing is done
RETURN:		es:si - CharData (in greyMonoBuf)
DESTROYED:	nothing else
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GreyToMono	proc	near
		uses	ax, bx, cx, dx, di, bp, ds
		.enter
		cmp	si, offset greyMonoBuf
		jne	convert
		mov	ax, es
		mov	bx, fs
		cmp	ax, bx
		je	done				; converted already
convert:
		segmov	ds, es				; ds:si <- source
		segmov	es, fs
		mov	di, offset greyMonoBuf		; es:di <- dest
		mov	ax, {word}ds:[si].GCD_pictureWidth ; al width, ah rows
		mov	es:[di], ax			; same header
		mov	ax, {word}ds:[si].GCD_yoff
		mov	es:[di+2], ax
		;
		; Does it fit? rows * ((width + 7) / 8)
		;
		mov	al, ds:[si].GCD_pictureWidth
		clr	ah
		mov	bp, ax				; bp <- width
		add	ax, 7
		shr	ax, 1
		shr	ax, 1
		shr	ax, 1
		mov	bx, ax				; bx <- mono bytes/row
		mov	cl, ds:[si].GCD_numRows
		clr	ch
		mul	cl				; ax <- mono data size
		cmp	ax, GREY_MONO_BUF_SIZE - SIZE_CHAR_HEADER
		jbe	fits
		mov	{word}es:[di], 0		; too big: draw nothing
		jmp	done
fits:
		mov	dx, bp
		inc	dx
		shr	dx, 1				; dx <- grey bytes/row
		add	si, offset GCD_data		; ds:si <- grey data
		push	ax, dx, ds
		mov	ds, gs:[PSL_saveGState]
		test	ds:[GS_fontFlags], mask FBF_GREY_PHASES
		pop	ax, dx, ds
		jz	noPhases			; just one bitmap
		push	ax, dx
		mov	ax, dx				; grey bytes/row
		mul	cx				; ax <- size of a phase
		shl	ax, 1				; phase GREY_PHASE_ZERO (2):
		add	si, ax				;  no shift
		pop	ax, dx
noPhases:
		add	di, offset CD_data		; es:di <- mono data
rowLoop:
		jcxz	done
		push	cx, si, di
		clr	cx				; cx <- pixel index
		clr	ah				; ah <- mono byte
pixLoop:
		cmp	cx, bp
		jae	rowEnd
		push	bx				; bx = mono bytes/row
		mov	bx, cx
		shr	bx, 1
		mov	al, ds:[si][bx]
		pop	bx
		test	cl, 1
		jnz	lowNibble
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
lowNibble:
		and	al, 0x0f
		cmp	al, GREY_LEVELS/2		; carry set if background
		cmc					; carry set if ink
		rcl	ah, 1
		inc	cx
		test	cl, 7
		jnz	pixLoop
		mov	es:[di], ah
		inc	di
		clr	ah
		jmp	pixLoop
rowEnd:
		test	cl, 7				; partial last byte?
		jz	rowStored
shiftLast:
		shl	ah, 1
		inc	cx
		test	cl, 7
		jnz	shiftLast
		mov	es:[di], ah
rowStored:
		pop	cx, si, di
		add	si, dx
		add	di, bx
		dec	cx
		jmp	rowLoop
done:
		.leave
		mov	si, offset greyMonoBuf		; es:si <- CharData
		ret
GreyToMono	endp

