COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus Font Driver
FILE:		nimbusWidths.asm

AUTHOR:		Gene Anderson, Feb 20, 1990

ROUTINES:
	Name			Description
	----			-----------
EXT	NimbusGenWidths		Generate font header and widths for a font.

INT	CalcScaleForWidths	Calculate scale factor for width table.
INT	ConvertHeader		Convert height, average width, etc.
INT	ConvertWidths		Convert table of character widths.
INT	CalcTransform		Calculate transformation matrix for characters.
INT	CalcRoutines		Calculate continuity checking, routines to use.

INT	AdjustWidthForStyles	Adjust width scale factor for any styles.
INT	AddStyleTransforms	Add transformation for any styles.
INT	AddGraphicsTransform	Add transformation from the graphics system.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	11/3/89		Initial revision

DESCRIPTION:
	Implements a font driver for:
		The Company's Nimbus-Q outline fonts

	$Id: nimbusWidths.asm,v 1.1 97/04/18 11:45:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusGenWidths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the character width table for a font.
CALLED BY:	EXTERNAL: GrFindFont

PASS:		di - 0 for new font; handle to rebuild old font (P'd)
		es - seg addr of gstate (locked)
			GS_fontAttr - font attributes
		bp:cx - transformation matrix (TMatrix)
		ds - seg addr of font info block
RETURN:		bx - handle of font (locked)
		ax - seg addr of font (locked)
		carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	di is the bx passed to NimbusStrategy.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusGenWidths	proc	far
	uses	cx, dx, si, di, ds, es, bp
locals	local	WidthLocals

	mov	bx, bp
	.enter

	mov	ss:locals.WL_gstate, es		;save passed GState
	mov	ss:locals.WL_transformAll, TRUE
	movdw	ss:locals.WL_xform, bxcx
	mov	al, es:GS_fontAttr.FCA_textStyle
	movwbf	dxah, es:GS_fontAttr.FCA_pointsize
	mov	cx, es:GS_fontAttr.FCA_fontID	;cx <- FontID

SBCS <	mov	bx, ODF_HEADER			;bx <- flag: load header data>
DBCS <	mov	bx, offset NOED_header		;bx <- flag: load header data>
	call	LoadOutlineData
	push	cx				;save handle of odata
	segmov	ds, es				;ds <- seg addr of odata
	push	ax				;save styles to implement
	call	GetNumKernPairs			;ax <- # of kerning pairs
	mov	ss:locals.WL_numKernPairs, ax
	mov	cx, ds:NFH_numChars		;cx <- # of chars in font
	mov	bx, size CharGenData		;bx <- space for driver use
	call	FontAllocFontBlock		;allocate a block
	pop	ax				;al <- TextStyle to implement

	push	bx				;save handle of font
	call	CalcScaleForWidths		;calc scale factor for widths
	call	ConvertHeader			;convert FontBuf info
	call	ConvertWidths			;convert character widths
	call	ConvertKernPairs		;convert kerning pairs, if any
	call	CalcTransform			;calc transform for characters
	call	CalcRoutines			;figure out routines to use
	pop	cx				;cx <- handle of font

	pop	bx				;bx <- handle of odata
	call	MemUnlock			;unlock the outline data
	mov	bx, cx				;bx <- handle of font
	mov	ax, es				;ax <- seg addr of font

	clc					;indicate no error

	.leave
	ret
NimbusGenWidths	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert Nimbus font header information.
CALLED BY:	INTERNAL: NimbusGenWidths

PASS: 		ds - seg addr of outline data header
		dx.ah <- pointsize (WBFixed)
		ss:bp - inherited locals
		    WL_widthScale - scale factor for horizontal components
		    WL_heightScale - scale factor for vertical components
		es - seg addr of font data header
RETURN:		none
DESTROYED:	bx, cx, di, si

PSEUDO CODE/STRATEGY:
	Convert information in the header (eg. height, average width)
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/ 9/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertHeader	proc	near
	uses	ax, bx, cx, dx			;regs to save
	.enter	inherit	NimbusGenWidths

	mov	es:FB_maker, FM_NIMBUSQ		;<- font manufacturer

	mov	es:FB_kernPairPtr, 0		;no kerning
	mov	es:FB_kernValuePtr, 0		;no kerning
	mov	es:FB_kernCount, 0		;no kerning

	mov	es:FB_heapCount, 0		;no usage yet
	mov	es:FB_flags, mask FBF_IS_OUTLINE

	mov	es:FB_heightAdjust.WBF_int, dx
	mov	es:FB_heightAdjust.WBF_frac, ah

	mov	ax, ss				;ax <- seg addr of stack
	lea	si, ss:locals.WL_widthScale
	lea	di, ss:locals.WL_register

	mov	bx, ds:NFH_minLSB		;bx <- minimum left side
	call	ScaleShortWBFixed
	rnduwbf	dxch				;dx <- rounded value
	mov	es:FB_minLSB, dx

	mov	bx, ds:NFH_avgwidth		;bx <- width of average char
	call	ScaleShortWBFixed
	movwbf	es:FB_avgwidth, dxch

	mov	bx, ds:NFH_maxwidth		;bx <- width of widest char
	call	ScaleShortWBFixed
	movwbf	es:FB_maxwidth, dxch

if not DBCS_PCGEOS
	mov	bx, ds:NFH_maxRSB		;bx <- maximum right side
	call	ScaleShortWBFixed
	rnduwbf	dxch				;dx <- rounded value
	mov	es:FB_maxRSB, dx
endif

	lea	si, ss:locals.WL_heightScale

	mov	bx, ds:NFH_height		;bx <- height of font box
	call	ScaleShortWBFixed
	movwbf	es:FB_height, dxch
	subwbf	es:FB_heightAdjust, dxch
	rnduwbf	dxch				;dx <- rounded value
	mov	es:FB_pixHeight, dx		;<- height (in device coords)

	mov	bx, ds:NFH_baseAdjust		;bx <- adjustment for height
	call	ScaleShortWBFixed
	rnduwbf	dxch				;dx <- rounded value
	;
	; NOTE: we don't want fractional baseline adjustments.
	; It gives the text object fits...
	;
	mov	es:FB_baseAdjust.WBF_int, dx
	mov	es:FB_baseAdjust.WBF_frac, 0

	mov	bx, ds:NFH_ascent		;bx <- height above baseline
	call	ScaleShortWBFixed
	movwbf	es:FB_baselinePos, dxch
	;
	; Take the ceiling of the TSB, to account for any pixel wandering
	;
	mov	bx, ds:NFH_minTSB		;bx <- minimum top side
	call	ScaleShortWBFixed
	ceilwbf	dxch, dx			;dx <- ceiling(TSB)
	mov	es:FB_aboveBox.WBF_frac, 0
	mov	es:FB_aboveBox.WBF_int, dx
	mov	es:FB_minTSB, dx
	add	es:FB_pixHeight, dx		;pixHeight includes all
	;
	; Take the ceiling of the BSB, to account for any pixel wandering
	;
	mov	bx, ds:NFH_maxBSB		;bx <- maximum bottom side
	call	ScaleShortWBFixed
	ceilwbf	dxch, dx			;dx <- ceiling(BSB)
	mov	es:FB_belowBox.WBF_frac, 0
	mov	es:FB_belowBox.WBF_int, dx
SBCS <	mov	es:FB_maxBSB, dx					>

	mov	bx, ds:NFH_underPos		;bx <- underline position
	call	ScaleShortWBFixed
	movwbf	es:FB_underPos, dxch
				   
	mov	bx, ds:NFH_underThick		;bx <- thickness of underline
	call	ScaleShortWBFixed
	movwbf	es:FB_underThickness, dxch

	mov	bx, ds:NFH_strikePos		;bx <- underline position
	call	ScaleShortWBFixed
	movwbf	es:FB_strikePos, dxch

	mov	bx, ds:NFH_x_height		;bx <- height of lowers
	call	ScaleShortWBFixed
	movwbf	es:FB_mean, dxch

	mov	bx, ds:NFH_descent		;bx <- maximum descent
	call	ScaleShortWBFixed
	movwbf	es:FB_descent, dxch
	;
	; NOTE: we don't want any fractional baseline.
	; It gives the text object fits...
	;
	mov	bx, ds:NFH_accent		;bx <- accent height
	call	ScaleShortWBFixed
	movwbf	es:FB_accent, dxch
	addwbf	dxch, es:FB_baselinePos
	rnduwbf	dxch				;dx <- rounded value
	mov	es:FB_baselinePos.WBF_frac, 0
	mov	es:FB_baselinePos.WBF_int, dx
	;
	; The Nimbus-Q fonts don't have any external leading
	;
	clrwbf	es:FB_extLeading		;<- no external leading

	.leave
	ret
ConvertHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertWidths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert Nimbus widths to PC/GEOS format.
CALLED BY:	INTERNAL: NimbusGenWidths

PASS:		ds - seg addr of outline data header
		es - seg addr of font
		ss:bp - inherited locals
		    WL_widthScale - scale factor for widths (WWFixed)
RETURN:		none
DESTROYED:	bx, cx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Will cause problems if the DEFAULT_CHAR doesn't exist
	(only checks to see that DEFAULT_CHAR is in range)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/ 9/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertWidths	proc	near
	uses	ax, dx
	.enter	inherit	NimbusGenWidths

DBCS <	clr	ah							>
	mov	al, ds:NFH_firstChar		;al <- first char
SBCS <	mov	es:FB_firstChar, al					>
DBCS <	mov	es:FB_firstChar, ax					>
	mov	al, ds:NFH_lastChar		;al <- last char
SBCS <	mov	es:FB_lastChar, al					>
DBCS <	mov	es:FB_lastChar, ax					>
	mov	al, ds:NFH_defaultChar		;al <- default char
SBCS <	mov	es:FB_defaultChar, al					>
DBCS <	mov	es:FB_defaultChar, ax					>

	mov	cx, ds:NFH_numChars		;cx <- # of chars

	mov	di, offset FB_charTable		;es:di <- ptr to width table
	mov	si, size NewFontHeader 		;skip over font header
CBW_loop:
	mov	ax, ds:[si].NW_width		;ax <- width of character
	call	ScaleWidth
	mov	es:[di].CTE_width.WBF_int, ax	;store new width
	mov	es:[di].CTE_width.WBF_frac, dh
	mov	ax, CHAR_NOT_BUILT		;ax <- flag: char not built
	mov	bl, ds:[si].NW_flags		;bl <- data flags
	test	bl, mask CTF_NO_DATA		;see if any data
	je	isData				;branch if data
	mov	ax, CHAR_NOT_EXIST		;ax <- flag: no data
isData:
	mov	es:[di].CTE_dataOffset, ax	;store data flag
	mov	es:[di].CTE_flags, bl		;store flags
SBCS <	mov	es:[di].CTE_usage, 0		;no usage		>
	add	si, size NewWidth		;advance src ptr
	add	di, size CharTableEntry		;advance dest ptr
	loop	CBW_loop			;loop while more chars

	.leave
	ret
ConvertWidths	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a width component
CALLED BY:	ConvertWidths(), ConvertKernPairs()

PASS:		ax - value to scale
		ss:bp - inherited locals
		    WL_widthScale - scale factor for widths (WWFixed)
RETURN:		ax.dh - scaled value
DESTROYED:	dl

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleWidth	proc	near
	uses	cx, si, di, ds, es
	.enter	inherit	NimbusGenWidths

	lea	si, ss:locals.WL_widthScale	;ds:si <- ptr to mutiplicand
	lea	di, ss:locals.WL_register	;es:di <- ptr to multiplier
	mov	ss:[di].WWF_int, ax
	mov	ss:[di].WWF_frac, 0
	mov	ax, ss				;ax <- seg addr of stack
	mov	ds, ax
	mov	es, ax
	call	GrMulWWFixedPtr			;dx.cx == scale * width
	mov	ax, dx
	mov	dx, cx				;ax.dx -- scale * width
	rndwwbf	axdx				;ax.dh <- rounded (WBFixed)

	.leave
	ret
ScaleWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNumKernPairs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get # of kerning pairs in this font
CALLED BY:	NimbusGenWidths()

PASS:		ds - seg addr of outline data for header
		bx - size of outline data for header
RETURN:		ax - # of kerning pairs
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <(size NewWidth) eq 3>
CheckHack <(size KernPair)+(size word) eq 4>

GetNumKernPairs	proc	near
	uses	dx
	.enter

	;
	; Calculate the size of the block
	;
	mov	ax, ds:NFH_numChars		;ax <- # of characters
	mov	dx, ax
	shl	ax, 1				;ax <- #*2
	add	ax, dx				;ax <- #*3
	add	ax, (size NewFontHeader)	;ax <- size of header
	;
	; Is the size of the block larger than we've calculated?
	;
	clr	dx				;dx <- # of pairs
	cmp	bx, ax				;actual size bigger?
	je	done				;branch if same size
EC <	ERROR_L	BAD_FONT_HEADER_FOR_KERNING	;>
	;
	; The block is larger than calculated.  Presumably, the remaining
	; information is kerning pairs.
	;
	mov	dx, bx				;dx <- actual size
	sub	dx, ax				;dx <- extra size
EC <	test	dx, 00000011b			;multiple of 4?>
EC <	ERROR_NZ	BAD_FONT_HEADER_FOR_KERNING	;>
	shr	dx, 1
	shr	dx, 1				;dx <- # of kerning pairs
	stc					;carry <- kerning pairs exist
done:
	mov	ax, dx				;ax <- # of kerning pairs

	.leave
	ret
GetNumKernPairs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertKernPairs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert kerning pairs, if any, for the font
CALLED BY:	NimbusGenWidths()

PASS:		ds - seg addr of outline data header
		es - seg addr of font
		ss:bp - inherited locals
		    WL_widthScale - scale factor for widths (WWFixed)
		    WL_numKernPairs - number of kerning pairs
RETURN:		none
DESTROYED:	bx, cx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <(size NewWidth) eq 3>
CheckHack <(size KernPair)+(size word) eq 4>
CheckHack <(size KernPair)+(size BBFixed) eq 4>
SBCS <CheckHack <(size CharTableEntry) eq 8>				>
DBCS <CheckHack <(size CharTableEntry) eq 6>				>

ConvertKernPairs	proc	near
	uses	ax, dx
	.enter	inherit	NimbusGenWidths

	mov	cx, ss:locals.WL_numKernPairs	;cx <- # of kerning pairs
	jcxz	done				;branch if no pairs
	mov	es:FB_kernCount, cx		;store # of kerning pairs
	;
	; Figure out where the kern data is in the outline data
	;
	mov	ax, ds:NFH_numChars		;ax <- # of chars
	mov	bx, ax				;bx <- # of chars
	shl	ax, 1				;ax <- #*2
	add	ax, bx				;ax <- (# of chars)*(size width)
	add	ax, (size NewFontHeader)	;ax <- offset of kerning data
	mov	si, ax				;ds:si <- ptr to kern pairs
	;
	; Figure out where the kern data goes in the font we're building
	;
	mov	di, bx
if DBCS_PCGEOS
	shl	di, 1				;*2
	shl	di, 1				;*4
	add	di, bx				;*5
	add	di, bx				;di = bx*6 (size CharTableEntry)
else
	shl	di, 1
	shl	di, 1
	shl	di, 1				;di <- (# of chars)*(size entry)
endif
	add	di, (size FontBuf)-(size FB_charTable)+(size CharGenData)
						 ;es:di <- ptr to dest
	;
	; Copy the kern character pairs
	;
	mov	es:FB_kernPairPtr, di
	push	cx				;cx <- save # of pairs
	rep	movsw				;copy me jesus
	pop	cx
	;
	; Copy and scale the adjustment amounts
	;
	mov	es:FB_kernValuePtr, di
kernLoop:
	lodsw					;ax <- adjustment value
	call	ScaleWidth			;ax.dh <- scaled width
	mov	ah, al
	mov	al, dh				;ah.al <- adjustment (BBFixed)
	stosw					;store me jesus
	loop	kernLoop			;loop while more

done:

	.leave
	ret
ConvertKernPairs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcScaleForWidths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate scale factor for character widths and header info.
CALLED BY:	NimbusGenWidths

PASS:		dx.ah <- pointsize (WBFixed)
		al - styles to implement (TextStyle)
		ss:bp - inherited locals
		    WL_gstate - seg addr of GState
RETURN:		ss:bp - inherited locals
		    WL_widthScale - scale factor (WWFixed)
DESTROYED:	bx, cx, si, di

PSEUDO CODE/STRATEGY:
	scale factor = pointsize / grid size
	Adjust for styles:
		subscript, superscript, bold, outline
	Adjust for widths and/or weights:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcScaleForWidths	proc	near
	uses	dx, ds, es
	.enter	inherit	NimbusGenWidths

	push	ax
	mov	ch, ah
	clr	cl				;dx:cx <- point size
	clr	ax
	mov	bx, NIMBUS_GRID_SIZE		;bx:ax <- grid size
	call	GrUDivWWFixed			;dx:cx <- ptsize / grid
	movwwf	ss:locals.WL_widthScale, dxcx
	movwwf	ss:locals.WL_heightScale, dxcx
	pop	ax				;al <- styles

	mov	ds, ss:locals.WL_gstate

	test	al, WIDTH_STYLES		;check only styles that matter
	jz	noStyles			;branch if no styles
	call	AdjustWidthForStyles
noStyles:
	lea	di, ss:locals.WL_widthScale
	segmov	es, ss				;es:di <- scale factor
	mov	cl, ds:GS_fontAttr.FCA_width	;cl <- width (%)
	cmp	cl, FWI_MEDIUM
	je	noWidth
	call	Mul100WWFixedES
noWidth:
	mov	cl, ds:GS_fontAttr.FCA_weight	;cl <- weight (%)
	cmp	cl, FW_NORMAL
	je	noWeight
	call	Mul100WWFixedES
noWeight:

	.leave
	ret
CalcScaleForWidths	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustWidthForStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust width scale factor to account for styles.
CALLED BY:	CalcScaleForWidths

PASS:		ss:bp - inherited locals
		    WL_widthScale - current scale factor (WWFixed)
		al - styles to implement (TextStyle)
		ds - seg addr of GState
RETURN:		ss:bp - inherited locals
		    WL_widthScale - current scale factor (WWFixed)
DESTROYED:	di, cx

PSEUDO CODE/STRATEGY:
	Styles that are not implied by the outline data (eg. bold
	or italic) or done by the kernel (underline or strikethrough)
	will be implemented in the font driver.
		superscript - scale (x,y)
		subscript - scale (x,y)

	The width is basically the size of the character along the
	baseline, so only things that affect the x position affect it.
	This means that only superscript, subscript, bold and outline
	will affect the new width.

	Also, there are items in the font header which are not affected
	by the style (eg. the baseline offset) so they are scaled by
	NGW_heightScale which is untouched in this routine.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AdjustWidthForStyles	proc	near
	uses	dx, es
	.enter	inherit	NimbusGenWidths

	lea	di, ss:locals.WL_widthScale
	segmov	es, ss				;es:di <- scale factor

	test	al, mask TS_SUBSCRIPT or mask TS_SUPERSCRIPT
	jz	noScript
	mov	dx, SCRIPT_FACTOR_INT
	mov	cx, SCRIPT_FACTOR_FRAC		;dx.cx <- scale factor
	call	MulWWFixedES
noScript:
	test	al, mask TS_BOLD
	jz	noBold
	mov	dx, BOLD_FACTOR_INT
	mov	cx, BOLD_FACTOR_FRAC		;dx.cx <- scale factor
	call	MulWWFixedES
noBold:

	.leave

	ret
AdjustWidthForStyles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the transformation for generating characters.
CALLED BY:	NimbusGenWidths


PASS:		dx.ah - pointsize (WBFixed)
		al - styles to implement (TextStyle)
		es - seg addr of font
		ds - seg addr of outline data
		ss:bp - inherited locals
		    WL_heightScale - scale factor
RETURN:		es:[di].CGD_matrix - transformation matrix for characters
DESTROYED:	bx, cx

PSEUDO CODE/STRATEGY:
	Calculates the transformation matrix necesssary for generating
	characters. This includes scaling from the Nimbus data to the
	desired pointsize, scaling for superscript or subscript,
	shearing for italic, and any transformation from the graphics
	system.

	[n11 n12 0]   [scale 0 0][super 0 0][1      0 0][g11 g12 0]
	[n21 n22 0] = [0 scale 0][0 super 0][italic 1 0][g21 g22 0]
	[0   0   1]   [0   0   1][0   0   1][0      0 1][0   0   1]

	The scale factor used here is different than that used for
	converting the width table. The Nimbus code has an implied
	denominator of 32768, and our graphics system has an implied
	denominator of 65536 (ie. a word). This means the scale
	here must be divided by 2 (shifted right 1 bit)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcTransform	proc	near
	uses	ds, dx
	.enter	inherit NimbusGenWidths

	mov	di, ds:NFH_numChars		;di <- # of chars
if DBCS_PCGEOS
.assert (size CharTableEntry eq 6)
	shl	di, 1				;*2
	mov	cx, di
	shl	di, 1				;*4
	add	di, cx				;*6
else
.assert (size CharTableEntry eq 8)
	shl	di, 1
	shl	di, 1
	shl	di, 1				;di <- size of width table
endif
	add	di, size FontBuf - size CharTableEntry	;skip header

	push	ax
	push	di
	clr	al				;al <- data to store
	mov	cx, (size CharGenData)		;cx <- # of bytes to store
	rep	stosb

	pop	di
	pop	ax

	movwwf	dxcx, ss:locals.WL_heightScale
	sarwwf	dxcx				;dx.cx <- val / 2
	movwwf	es:[di].CGD_matrix.FM_22, dxcx
	movwwf	es:[di].CGD_matrix.FM_11, dxcx

	test	al, TRANSFORM_STYLES		;see if adding any styles
	jz	noStyles
	mov	es:[di].CGD_style, al		;pass styles to add
	call	AddStyleTransforms		;adjust for italic, etc.
noStyles:
	;
	; Adjust for width & weight
	;
	push	di
	lea	di, es:[di].CGD_matrix.FM_11
	mov	ds, ss:locals.WL_gstate		;ds <- seg addr of GState
	mov	cl, ds:GS_fontAttr.FCA_width
	cmp	cl, FWI_MEDIUM
	je	noWidth
	call	Mul100WWFixedES			;scale TM11
noWidth:
	mov	cl, ds:GS_fontAttr.FCA_weight
	cmp	cl, FW_NORMAL
	je	noWeight
	call	Mul100WWFixedES			;scale TM11
noWeight:
	pop	di
	;
	; Add any transformation from the graphics system
	;
	lds	si, ss:locals.WL_xform		;ds:si <- ptr to graphics xform
	mov	dx, es:FB_baselinePos.WBF_int
	mov	es:[di].CGD_heightY, dx
	test	ds:[si].TM_flags, TM_COMPLEX	;see if complex transform
	jz	simpleTransform			;branch if not complex
	ornf	es:FB_flags, mask FBF_IS_COMPLEX
	call	AddGraphicsTransform		;add xform from graphics system
simpleTransform:
	;
	; Finally, we must correct for the fact that
	; our graphics system has y->0 = up.
	;
	negwwf	es:[di].CGD_matrix.FM_12
	negwwf	es:[di].CGD_matrix.FM_21

	.leave
	ret
CalcTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddStyleTransforms
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add additional transformations for any styles.
CALLED BY:	CalcTransform

PASS:		es:[di].CGD_matrix - current transform
		al - styles to implement (TextStyle)
		ss:bp - inherited locals
		   WL_gstate - seg addr of GState
RETURN:		es:[di].CGD_matrix - new transform (FontMatrix)
DESTROYED:	bx, cx, dx, si

PSEUDO CODE/STRATEGY:
	superscript or subscript:
		[S 0 0]
		[0 S 0], S=scale factor=7/12
		[0 0 1]
	italic:
		[1 0 0]
		[I 1 0], I=shear factor
		[0 0 1]
	bold:
		[S 0 0]
		[0 1 0], S=scale factor
		[0 0 1]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddStyleTransforms	proc	near
	uses	di
	.enter	inherit NimbusGenWidths

	mov	bx, di				;es:bx <- ptr to CharGenData

	test	al, mask TS_SUPERSCRIPT or mask TS_SUBSCRIPT
	jz	noScript

	;
	; If subscript or superscript, we need to scale to
	; about 7/12ths the orginal size.
	;
	mov	dx, SCRIPT_FACTOR_INT
	mov	cx, SCRIPT_FACTOR_FRAC		;dx.cx <- scale factor
	add	di, offset CGD_matrix.FM_11
	call	MulWWFixedES			;scale TM11
	add	di, (offset FM_22) - (offset FM_11)
	call	MulWWFixedES			;scale TM22
	;
	; We also need to adjust the vertical position
	; up or down depending on whether it is superscript
	; or subscript by about 1/3 the orginal height.
	;
	push	ax				;save style
	push	bx
	clr	cl
	mov	ch, es:FB_height.WBF_frac
	mov	dx, es:FB_height.WBF_int	;dx.cx <- height
	add	ch, es:FB_heightAdjust.WBF_frac
	adc	dx, es:FB_heightAdjust.WBF_int	;dx.cx <- adjusted height
	test	al, mask TS_SUBSCRIPT
	jnz	isSubscript

	mov	ax, SUPERSCRIPT_OFFSET_FRAC
	mov	bx, SUPERSCRIPT_OFFSET_INT	;bx.ax <- superscript offset
	call	GrMulWWFixed
	sub	ch, es:FB_baselinePos.WBF_frac
	sbb	dx, es:FB_baselinePos.WBF_int
	sub	ch, es:FB_baseAdjust.WBF_frac
	sbb	dx, es:FB_baseAdjust.WBF_int
	jmp	finishScript

isSubscript:
	mov	ax, SUBSCRIPT_OFFSET_FRAC
	mov	bx, SUBSCRIPT_OFFSET_INT	;bx.ax <- subscript offset
	call	GrMulWWFixed

finishScript:
	rnduwbf	dxch				;dx <- rounded value
	pop	bx				;bx <- offset to CharGenData
	mov	di, bx
	mov	es:[di].CGD_scriptY, dx		;<- height +/- 1/3
	pop	ax				;al <- TextStyle

noScript:
	;
	; If we're faking bold, scale horizontally
	;
	test	al, mask TS_BOLD
	jz	noBold
	mov	di, bx
	mov	dx, BOLD_FACTOR_INT
	mov	cx, BOLD_FACTOR_FRAC		;dx.cx <- scale factor
	add	di, offset CGD_matrix.FM_11
	call	MulWWFixedES			;scale TM11
noBold:
	test	al, mask TS_ITALIC
	jz	noItalic
	;
	; If we're faking italic, put in a shear factor
	;
	mov	di, bx
	mov	dx, es:[di].CGD_matrix.FM_22.WWF_int
	mov	es:[di].CGD_matrix.FM_21.WWF_int, dx
	mov	dx, es:[di].CGD_matrix.FM_22.WWF_frac
	mov	es:[di].CGD_matrix.FM_21.WWF_frac, dx	;TM21 = TM22*italic
;	; JIM EXPERIMENTING
	mov	dx, NEG_ITALIC_FACTOR_INT
	mov	cx, NEG_ITALIC_FACTOR_FRAC		;dx.cx <- -shear factor
;	mov	dx, ITALIC_FACTOR_INT
;	mov	cx, ITALIC_FACTOR_FRAC		;dx.cx <- -shear factor
	add	di, offset CGD_matrix.FM_21
	call	MulWWFixedES			;scale TM21
noItalic:


	.leave
	ret
AddStyleTransforms	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddGraphicsTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add any complex transformation from the graphics system.
CALLED BY:	CalcTransform

PASS:		ds:si - ptr to graphics system transform (TMatrix)
		es:[di].CGD_matrix - current transformation matrix (FontMatrix)
		ss:bp - inherited locals
RETURN:		es:[di].CGD_matrix - updated transformation matrix
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
	D = destination matrix
	N = Nimbus matrix
	G = graphics system matrix
	D = N * G

	if (rotated) save matrix values;
	D11 = N11*G11
	D21 = N21*G11
	D12 = N12*G22				;N12*G22 == 0
	D22 = N22*G22
	if (rotated) {
	    D11 = D11 + N12*G21			;N12*G21 == 0
	    D21 = D21 + N22*G21
	    D12 = D12 + N11*G12
	    D22 = D22 + N21*G12
	}

	By making the above assumption (ie. that N12 is zero, and hence
	the corresponding factors are zero), we can reduce the number
	of multiplies from 4 to 3 (or 8 to 6 in the case of rotation).
	We can safely make this assumption because the style and scale
	transforms will only affect N11, N21, and N22.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathAddGraphicsTransform	proc	far
	uses	ax, bx, cx, dx
locals	local	WidthLocals
	.enter

	mov	ss:locals.WL_transformAll, FALSE
	call	AddGraphicsTransform

	.leave
	ret
PathAddGraphicsTransform	endp

AddGraphicsTransform	proc	near
	uses	di, si, ds
	.enter	inherit NimbusGenWidths

	test	ds:[si].TM_flags, TM_ROTATED
	jnz	rotateStart			;additional work for rotation
afterRotateStart:

	push	di
	mov	cx, ds:[si].TM_11.WWF_frac
	mov	dx, ds:[si].TM_11.WWF_int	;dx.cx <- tm11
	add	di, offset CGD_matrix.FM_11	;es:di <- element to scale
	call	MulWWFixedES
	add	di, offset FM_21 - offset FM_11	;es:di <- element to scale
	call	MulWWFixedES

	mov	cx, ds:[si].TM_22.WWF_frac
	mov	dx, ds:[si].TM_22.WWF_int	;dx.cx <- tm22
	add	di, offset FM_22 - offset FM_21	;es:di <- element to scale
	call	MulWWFixedES
	pop	di

	tst	ss:locals.WL_transformAll
	jz	doneScale			;if FALSE, we're done here
	push	si
	add	si, offset TM_22		;scale by tm22
	clr	cl
	mov	ch, es:FB_height.WBF_frac
	mov	dx, es:FB_height.WBF_int	;dx.cx <- font height
	call	MulWWFixedDS
	mov	es:FB_pixHeight, bx		;store scaled height

	clr	cx
	mov	dx, es:FB_minTSB		;dx.cx <- top-side bearing
	call	MulWWFixedDS
	mov	es:FB_minTSB, bx
	add	es:FB_pixHeight, bx		;pixHeight includes all

	clr	cl
	mov	ch, es:FB_baselinePos.WBF_frac
	mov	dx, es:FB_baselinePos.WBF_int	;dx.cx <- height above baseline
	call	MulWWFixedDS
	mov	es:[di].CGD_heightY, bx		;store scaled height

	clr	cx
	mov	dx, es:[di].CGD_scriptY
	call	MulWWFixedDS
	mov	es:[di].CGD_scriptY, bx		;store scaled script height
	pop	si
doneScale:
	test	ds:[si].TM_flags, TM_ROTATED
	jnz	rotateEnd			;additional work for rotation
afterRotateEnd:

	.leave
	ret

rotateStart:
	;
	; The graphics system has rotation. This means we need
	; to do 6 multiplies instead of just 3. Bummer. Here
	; we save the original matrix values so we can trash
	; the matrix while doing the multiplies that are needed
	; for both scaling and rotation.
	;
	push	es:[di].CGD_scriptY		;save for later
	push	si, di, ds, es
	segmov	ds, es
	mov	si, di				;ds:si <- ptr to original
	segmov	es, ss
	lea	di, ss:locals.WL_tmatrix	;es:di <- ptr to copy
	mov	cx, (size FontMatrix) / 2	;cx <- # of words to copy
	rep	movsw				;copy me jesus
	pop	si, di, ds, es
	jmp	afterRotateStart

rotateEnd:
	;
	; The graphics system has rotation. We now do the
	; additional 3 multiplies that are necessary.
	;
	add	si, offset TM_21
	movwwf	dxcx, ss:locals.WL_tmatrix.FM_22
	call	MulWWFixedDS
	addwwf	es:[di].CGD_matrix.FM_21, bxax

	add	si, offset TM_12 - offset TM_21
	movwwf	dxcx, ss:locals.WL_tmatrix.FM_11
	call	MulWWFixedDS
	addwwf	es:[di].CGD_matrix.FM_12, bxax

	movwwf	dxcx, ss:locals.WL_tmatrix.FM_21
	call	MulWWFixedDS
	addwwf	es:[di].CGD_matrix.FM_22, bxax

	pop	dx
	tst	ss:locals.WL_transformAll
	jz	doneRotate			;if FALSE, we're done here
	clr	cx				;dx.cx <- script offset
	add	si, offset TM_21 - offset TM_12
	call	MulWWFixedDS
	mov	es:[di].CGD_scriptX, bx		;store x of rotated offset

	movwbf	dxch, es:FB_baselinePos		;dx.cx <- height above baseline
	call	MulWWFixedDS
	mov	es:[di].CGD_heightX, bx		;store x of rotated height

doneRotate:
	jmp	afterRotateEnd
AddGraphicsTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out continuity checking and which routines to use,
		based on the height of the font.
		Also copy values from Nimbus header used in generation.
CALLED BY:	NimbusGenWidths

PASS:		es:di - ptr to outline specific data (CharGenData)
		ds - seg addr of outline data
RETURN:		none
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	There are three cutoff points:
		(1) continuity checking off/on	(~25 lines)
		(2) regions/bitmaps		(~128 lines)
		(3) Nimbus/no hints		(~500 lines)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcRoutines	proc	near
	uses	bp
	.enter

	;
	; Some fonts have small heights for their size
	; (eg. Zapf Chancery). To avoid overflow in the Nimbus
	; engine, we check the large of the height and the
	; grid size the data is defined at (plus some).
	;
	mov	ax, NIMBUS_GRID_SIZE+140	;ax <- grid size
	mov	dx, ds:NFH_height		;dx <- height of font
	cmp	dx, ax				;see if smaller than grid
	jae	heightIsLarger
	mov	dx, ax				;dx <- grid size
heightIsLarger:

	shl	dx, 1				;*2 for Nimbus stuff
	clr	cx				;dx.cx <- height of font
	push	ds
	segmov	ds, es
	mov	si, di				;ds:si <- ptr to FontMatrix
CheckHack <(offset CGD_matrix) eq 0>
CheckHack <(offset FM_11) eq 0>
	call	MulWWFixedDS			;bx.ax <- scaled pointsize
	Abs	bx				;bx <- absolute value (x)
	mov	bp, bx
	add	si, offset FM_21 - offset FM_11	;ds:si <- TM_21
	call	MulWWFixedDS			;bx.ax <- scaled pointsize
	Abs	bx				;bx <- absolute value (x)
	add	bx, bp
	push	bx
	add	si, offset FM_12 - offset FM_21	;ds:si <- TM_12
	call	MulWWFixedDS			;bx.ax <- scaled pointsize
	Abs	bx				;bx <- absolute value (y)
	mov	bp, bx
	add	si, offset FM_22 - offset FM_12	;ds:si <- TM_22
	call	MulWWFixedDS			;bx.ax <- scaled pointsize
	Abs	bx				;bx <- absolute value (y)
	add	bx, bp
	pop	ax
	cmp	ax, bx				;x component larger?
	ja	isLarger			;yes, use it
	mov	ax, bx				;else use y component
isLarger:
	;
	; If the pointsize is large, but we are doing subscript,
	; we may need to use regions anyway because the offsets
	; for drawing the characters may be > +/- 127.
	;
	test	es:[di].CGD_style, mask TS_SUBSCRIPT
	jz	notScript			;branch if not super or sub.

	mov	bp, ax

	mov	ax, es:[di].CGD_scriptX
	Abs	ax
	mov	dx, es:[di].CGD_heightX
	Abs	dx
	add	dx, ax				;dx <- x script offset

	mov	ax, es:[di].CGD_heightY
	Abs	ax
	mov	bx, es:[di].CGD_scriptY
	Abs	bx
	add	ax, bx				;ax <- y script offset

	cmp	ax, dx				;y component larger?
	ja	yIsLarger			;yes, use it
	mov	ax, dx				;else use x component
yIsLarger:
	add	ax, SCRIPT_SAFETY_SIZE		;kind of a hack...

notScript:
	pop	ds				;ds <- seg addr of outline data
	mov	bl, FALSE			;bl <- no continuity checking
	mov	dx, CSR_NIMBUS_BITMAP		;dx <- bitmap chars
	cmp	ax, ds:NFH_continuitySize
	ja	noCheck				;branch if doing checking
	mov	bl, TRUE			;bl <- continuity checking
noCheck:
	cmp	ax, MAX_BITMAP_SIZE
	ja	doRegions			;branch if doing regions
setRoutines:
	call	SetTrans			;set transforms, etc.
setRoutines2:
	mov	es:[di].CGD_check, bl		;bl <- store continuity flag
	mov	es:[di].CGD_routs, dx		;dx <- store routine set

	.leave
	ret

doRegions:
	ornf	es:FB_flags, mask FBF_IS_REGION	;mark as region chars
	mov	dx, CSR_NIMBUS_REGION		;dx <- do hinted regions
	cmp	ax, MAX_NIMBUS_SIZE		;see if really big
	jb	setRoutines
	mov	dx, CSR_UNHINTED_REGION		;dx <- do unhinted regions
	jmp	setRoutines2
CalcRoutines	endp
