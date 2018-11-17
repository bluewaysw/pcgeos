COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MetricsMod
FILE:		nimbusMetrics.asm

AUTHOR:		Gene Anderson, Jun  5, 1990

ROUTINES:
	Name			Description
	----			-----------
EXT	NimbusCharMetrics	Return character metric information.

INT	FindCharData		Find ptr to character data
INT	SetupTMatrix		Setup transformation for metrics calculations
INT	AddMetricsStyles	Add factors to transform for style emulation
INT	TransformData		Transform data for metrics calculations


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/ 5/90		Initial revision

DESCRIPTION:
	Routines for generating character metrics.

	$Id: nimbusMetrics.asm,v 1.1 97/04/18 11:45:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusCharMetrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return character metrics information in document coords.
CALLED BY:	DR_FONT_CHAR_METRICS - NimbusStrategy

PASS:		ds - seg addr of font info block
		es - seg addr of GState
			es:GS_fontAttr - font attributes
		dx - character to get metrics of
		cx - info to return (GCM_info)
RETURN:		if GCMI_ROUNDED set:
			dx - information (rounded)
		else:
			dx.ah - information (WBFixed)
		carry - set if error (eg. data / font not available)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusCharMetrics	proc	far
	uses	bx, cx, si, di, ds
locals	local	MetricsLocals
	.enter

if DBCS_PCGEOS
else
EC <	tst	dh				;>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION ;>
endif

	push	dx
	mov	si, cx				;si <- value to find (GGM_info)
	mov	cx, dx				;cx <- character to find
	mov	ss:locals.ML_infoSeg, ds	;save seg addr of font info
	call	FindCharData			;find ptr to char data
	call	SetupTMatrix			;set up transformation
	pop	ax				;al <- char, ah <- saved
	call	TransformData			;transform appropriate point
	call	MemUnlock			;unlock outline data
	clc					;carry <- no error

	.leave
	ret
NimbusCharMetrics	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCharData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find ptr to individual character data
CALLED BY:	INTERNAL: NimbusCharMetrics()

PASS:		cl - character (Chars)
		es - seg addr of GState
		ss:bp - inherited MetricsLocals
			ML_infoSeg - seg addr of font info
RETURN:		es:di - ptr to character data
		bx - handle of outline data
		al - styles to implement (TextStyle)
		cx - font ID (FontID)
		dx.ah - pointsize (WBFixed)
		ds - seg addr of GState
		ss:bp - inherited MetricsLocals
			ML_fontHeight - height of font
			ML_firstChar - first character in font
			ML_lastChar - last character in font
			ML_defaultChar - default character for font
			ML_fontID - FontID value for font
			ML_styles - TextStyle for font
			ML_baseAdjust - NFH_baseAdjust for font
			ML_ascent - NFH_ascent for font
			ML_accent - NFH_accent for font
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Calls LoadOutlineData which finds the outline data
	with the largest subset of styles built in. The
	styles to implement that are returned is the set of
	styles that is not implied by the outline data.
	(eg. italic returned when making bold-italic from bold data) 
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES the cutoff point for characters is 0x80
	(as does nim2pc)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindCharData	proc	near
	uses	si
locals	local	MetricsLocals
	.enter	inherit

	push	es				;save seg addr of GState
	;
	; Get the header info for the font to find the
	; first, last and default characters.
	;
	push	cx				;save character
	mov	ds, ss:locals.ML_infoSeg	;ds <- seg addr of info block
	mov	cx, es:GS_fontAttr.FCA_fontID	;cx <- font ID (FontID)
	mov	al, es:GS_fontAttr.FCA_textStyle
	mov	ss:locals.ML_fontID, cx
	mov	ss:locals.ML_styles, al
SBCS <	mov	bx, ODF_HEADER			;bx <- flag: header	>
DBCS <	mov	bx, offset NOED_header		;bx <- flag: header	>
	call	LoadOutlineData
	mov	ax, es:NFH_height		;ax <- font height
	mov	ss:locals.ML_fontHeight, ax
	mov	ax, es:NFH_baseAdjust
	mov	ss:locals.ML_baseAdjust, ax
	mov	ax, es:NFH_ascent
	mov	ss:locals.ML_ascent, ax
	mov	ax, es:NFH_accent
	mov	ss:locals.ML_accent, ax
	mov	ax, {word}es:NFH_firstChar	;al <- first char, ah <- last
	mov	dh, es:NFH_defaultChar		;dh <- default character
	mov	bx, cx				;bx <- handle of header
	pop	cx				;cl <- character
	call	MetricsGetCharWidth
	call	MemUnlock			;unlock the header
	mov	ss:locals.ML_charWidth, si	;save width of character
	mov	{word}ss:locals.ML_firstChar, ax
	mov	ss:locals.ML_defaultChar, dh	;save default char

	;
	; Find out which half of the set the character is in,
	; and load the appropriate data. If the character
	; has no data, then use the default.
	;
checkChar:
SBCS <	mov	bx, ODF_PART1			;bx <- flag: first half	>
DBCS <	mov	bx, offset NOED_part1		;bx <- flag: first half	>
	mov	dl, cl
	cmp	cl, NIMBUS_CHAR_MIDPOINT	;see if in second half
	jae	secondHalf			;branch if in second half
	sub	dl, al				;dl <- char index
	jc	charMissing			;branch if before first char
afterHalf:
	clr	dh

	mov	cx, ss:locals.ML_fontID		;cx <- font ID (FontID)
	mov	al, ss:locals.ML_styles		;al <- styles (TextStyle)

	call	LoadOutlineData			;es <- seg addr of odata
	mov	di, dx				;di <- char index
	shl	di, 1				;*2 for words
	mov	di, es:[di]			;di <- ptr to char data
	tst	di				;any data?
	mov	bx, cx				;bx <- handle of outline data
	jz	charMissingUnlock		;branch if no data
	;
	; We have the pointer to the character data.
	; Return the pointsize et al from the GState.
	;
	pop	ds				;ds <- seg addr of GState
	movwbf	dxah, ds:GS_fontAttr.FCA_pointsize
	mov	cx, ds:GS_fontAttr.FCA_fontID	;cx <- font ID (FontID)

	.leave
	ret

	;
	; the character has no data, so use the default
	;
charMissingUnlock:
	call	MemUnlock			;unlock outline data
	mov	ax, {word}ss:locals.ML_firstChar ;al <- first char, ah <- last
	mov	dh, ss:locals.ML_defaultChar	;dh <- default character
charMissing:
	mov	cl, dh				;cl <- default character
	jmp	checkChar

	;
	; the character is in the second half of the set,
	; so adjust the index accordingly.
	;
secondHalf:
	cmp	dl, ah				;after last char?
	ja	charMissing			;branch if after last char
	sub	dl, NIMBUS_CHAR_MIDPOINT	;dl <- char index
SBCS <	mov	bx, ODF_PART2			;bx <- flag: second half>
DBCS <	mov	bx, offset NOED_part2		;bx <- flag: second half>
	jmp	afterHalf
FindCharData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupTMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup transformation matrix for metrics calculations
CALLED BY:	NimbusCharMetrics()

PASS:		al - styles to implement (TextStyle)
		dx.ah - pointsize (WBFixed)
		ds - seg addr of GState
		ss:bp - inherited MetricsLocals
			ML_fontHeight - set to NFH_height for font
RETURN:		ML_tmatrix - transformation to use (TMatrix)
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupTMatrix	proc	near
	uses	bx, es, di
locals	local	MetricsLocals
	.enter	inherit

	push	ax
	segmov	es, ss
	lea	di, ss:locals.ML_tmatrix	;es:di <- ptr to TMatrix
	mov	cx, (size TMatrix) / 2
	clr	ax
	rep	stosw				;init matrix to zeroes
	pop	ax

	push	ax
	mov	ch, ah
	clr	cl				;dx.cx <- point size
	clr	ax
	mov	bx, NIMBUS_GRID_SIZE		;bx.ax <- grid size
	call	GrUDivWWFixed			;dx.cx <- ptsize / grid

	mov	ss:locals.ML_tmatrix.TM_11.WWF_frac, cx
	mov	ss:locals.ML_tmatrix.TM_11.WWF_int, dx
	mov	ss:locals.ML_tmatrix.TM_22.WWF_frac, cx
	mov	ss:locals.ML_tmatrix.TM_22.WWF_int, dx
	pop	ax				;al <- style (TextStyle)

	call	AddMetricsStyles
	;
	; Adjust for width & weight
	;
	lea	di, ss:locals.ML_tmatrix.TM_11
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

	.leave
	ret
SetupTMatrix	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddMetricsStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add scales, et al to the transformation matrix for styles
CALLED BY:	SetupTMatrix()

PASS:		ss:bp - inherted MetricsLocals
			ML_tmatrix - transform for scaling
		al - styles to implement (TextStyle)
		ds - seg addr of GState
RETURN:		ML_tmatrix - updated TMatrix
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddMetricsStyles	proc	near
	uses	ds, es, si
locals	local	MetricsLocals
	.enter	inherit

	;
	; Any styles of interest?
	;
	test	al, TRANSFORM_STYLES		;any to styles to implement?
	jz	done				;branch if no styles
	segmov	es, ds				;es <- seg addr of GState
	segmov	ds, ss				;ds <- seg addr of tmatrix
	;
	; If faking bold, scale horizontally
	;
	test	al, mask TS_BOLD		;bold?
	jz	noBold
	lea	si, ss:locals.ML_tmatrix.TM_11
	mov	dx, BOLD_FACTOR_INT
	mov	cx, BOLD_FACTOR_FRAC		;dx.cx <- scale factor
	call	ScaleWWFixed
noBold:
	;
	; If doing sub- or superscript, scale and translate
	;
	test	al, mask TS_SUBSCRIPT or mask TS_SUPERSCRIPT
	jz	noScript
	call	AdjustMetricsForScript
noScript:
	;
	; If doing italic, use a skew factor
	;
	test	al, mask TS_ITALIC		;italic?
	jz	noItalic
	mov	dx, ss:locals.ML_tmatrix.TM_22.WWF_frac
	mov	ss:locals.ML_tmatrix.TM_21.WWF_frac, dx
	mov	dx, ss:locals.ML_tmatrix.TM_22.WWF_int
	mov	ss:locals.ML_tmatrix.TM_21.WWF_int, dx	;TM21 = TM22*shear
	lea	si, ss:locals.ML_tmatrix.TM_21
	mov	dx, ITALIC_FACTOR_INT
	mov	cx, ITALIC_FACTOR_FRAC		;dx.cx <- scale factor
	call	ScaleWWFixed
noItalic:

done:
	.leave
	ret
AddMetricsStyles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustMetricsForScript
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the tmatrix used for metrics for super- or subscript
CALLED BY:	AddMetricsStyles()

PASS:		ss:bp - inherted MetricsLocals
			ML_tmatrix - transform for scaling
		al - styles to implement (TextStyle)
		ds = ss
		es - seg addr of GState
RETURN:		ML_tmatrix - updated TMatrix
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AdjustMetricsForScript	proc	near
	uses	ax, bx
locals	local	MetricsLocals
	.enter	inherit

	;
	; We need to adjust the vertical position up or down depending on
	; whether it is superscript or subscript by 1/3 the orginal height.
	; The adjusted height used elsewhere is actually the pointsize.
	;
	test	al, mask TS_SUBSCRIPT		;doing subscript?
	jnz	isSubscript			;branch if subscript
	;
	; For superscript, we take 1/3 the height, and adjust up
	; from the (adjusted) baseline.
	;
	mov	ax, ss:locals.ML_tmatrix.TM_11.WWF_frac
	mov	bx, ss:locals.ML_tmatrix.TM_11.WWF_int
	clr	cx
	mov	dx, ss:locals.ML_ascent
	add	dx, ss:locals.ML_accent		;dx <- NFH_ascent+NFH_accent
	call	GrMulWWFixed			;dx.cx <- scaled value
	rndwwf	dxcx				;dx <- rounded value
	push	dx
	clr	cx
	mov	dx, ss:locals.ML_baseAdjust	;dx <- NFH_baseAdjust
	call	GrMulWWFixed			;dx.cx <- scaled value
	rndwwf	dxcx				;dx <- rounded value
	push	dx
	clr	cl
	movwbf	dxch, es:GS_fontAttr.FCA_pointsize
	mov	ax, SUPERSCRIPT_OFFSET_FRAC
	mov	bx, SUPERSCRIPT_OFFSET_INT	;bx.ax <- superscript offset
	call	GrMulWWFixed
	pop	ax				;ax <- NFH_baseAdjust
	sub	dx, ax
	pop	ax				;ax <- NFH_ascent+NFH_accent
	sub	dx, ax
	jmp	finishScript

	;
	; For subscript, we take 1/3 the height and adjust down
	;
isSubscript:
	clr	cl
	movwbf	dxch, es:GS_fontAttr.FCA_pointsize
	mov	ax, SUBSCRIPT_OFFSET_FRAC
	mov	bx, SUBSCRIPT_OFFSET_INT	;bx.ax <- subscript offset
	call	GrMulWWFixed
finishScript:
	inc	dx				;fudge factor
	negwwf	dxcx				;dx.cx <- negative amount
	mov	ax, dx
	cwd					;sign-extend me jesus
	mov	ss:locals.ML_tmatrix.TM_32.DWF_frac, cx
	mov	ss:locals.ML_tmatrix.TM_32.DWF_int.low, ax	;store result
	mov	ss:locals.ML_tmatrix.TM_32.DWF_int.high, dx
	;
	; Scale by 1/2
	;
	lea	si, ss:locals.ML_tmatrix.TM_11
	mov	dx, SCRIPT_FACTOR_INT
	mov	cx, SCRIPT_FACTOR_FRAC		;dx.cx <- scale factor
	call	ScaleWWFixed
	lea	si, ss:locals.ML_tmatrix.TM_22
	call	ScaleWWFixed

	.leave
	ret
AdjustMetricsForScript	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a WWFixed by another WWFixed
CALLED BY:	AddMetricsStyles()

PASS:		ds:si - ptr to value to scale (WWFixed)
		dx.cx - scale factor (WWFixed)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleWWFixed	proc	near
	uses	ax, bx, cx, dx
	.enter

	mov	bx, ds:[si].WWF_int
	mov	ax, ds:[si].WWF_frac
	call	GrMulWWFixed
	mov	ds:[si].WWF_int, dx
	mov	ds:[si].WWF_frac, cx

	.leave
	ret
ScaleWWFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransformData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform appropriate data for metrics calculations
CALLED BY:	NimbusCharMetrics()

PASS:		ss:bp - inherited MetricsLocals
			ML_tmatrix - transformation to use (TMatrix)
		si - info to return (GCM_info)
		es:di - ptr to outline data for character
RETURN:		if GCMI_ROUNDED set:
			dx - information (rounded)
		else:
			dx.ah - information (WBFixed)
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: order of GCM_info is (minx, miny, maxx, maxy)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransformData	proc	near
	uses	bx
locals	local	MetricsLocals
	.enter	inherit

	push	ax				;save al, ah
	push	si
	andnf	si, not (GCMI_ROUNDED)		;ignore rounding bit
	push	bp
	;
	; Get the x component of the value
	;
	add	bp, cs:tdataTM_table[si]	;bp <- fudge frame pointer
	mov	bx, cs:tdataX_table[si]		;bx <- offset of value
	clr	cx
	mov	dx, es:[di][bx]			;dx.cx <- x value
	mov	ax, ss:locals.ML_tmatrix.TM_11.WWF_frac
	mov	bx, ss:locals.ML_tmatrix.TM_11.WWF_int
	call	GrMulWWFixed
	push	dx, cx				;save result
	;
	; Get the y component of the value
	;
	mov	bx, cs:tdataY_table[si]		;bx <- offset of value
	clr	cx
	mov	dx, es:[di][bx]			;dx.cx <- y value
	mov	ax, ss:locals.ML_tmatrix.TM_21.WWF_frac
	mov	bx, ss:locals.ML_tmatrix.TM_21.WWF_int
	call	GrMulWWFixed
	pop	bx, ax
	add	cx, ax
	adc	dx, bx
	;
	; Get any additional offset (for sub- and superscript)
	;
	pop	bp
	push	bp
	add	bp, cs:tdataTM_off_table[si]	;bp <- fudge frame pointer
	add	cx, ss:locals.ML_tmatrix.TM_31.DWF_frac	;dx.cx <- result
	adc	dx, {word} ss:locals.ML_tmatrix.TM_31.DWF_int
	pop	bp
	;
	; We've got the result as a WWFixed. Round appropriately.
	;
	pop	si
	pop	ax				;al <- char, ah <- saved
	test	si, GCMI_ROUNDED		;round to integer?
	jnz	roundToInt			;branch if integer
	rndwwbf	dxcx				;dx.ch <- result (WBFixed)
	mov	ch, ah
done:

	.leave
	ret

roundToInt:
	rndwwf	dxcx				;dx <- result (sword)
	jmp	done

TransformData	endp

CheckHack <GCMI_MIN_X eq 0>
CheckHack <GCMI_MIN_Y eq 2>
CheckHack <GCMI_MAX_X eq 4>
CheckHack <GCMI_MAX_Y eq 6>

tdataX_table word \
	offset ND_xmin,				;min x
	offset ND_xmax,				;min y
	offset ND_xmax,				;max x
	offset ND_xmax				;max y

tdataY_table word \
	offset ND_ymin,				;min x
	offset ND_ymin,				;min y
	offset ND_ymax,				;max x
	offset ND_ymax				;max y

tdataTM_table word \
	offset TM_11 - offset TM_11,		;min x
	offset TM_12 - offset TM_11,		;min y
	offset TM_11 - offset TM_11,		;max x
	offset TM_12 - offset TM_11		;max y

tdataTM_off_table word \
	offset TM_31 - offset TM_31,		;min x
	offset TM_32 - offset TM_31,		;min y
	offset TM_31 - offset TM_31,		;max x
	offset TM_32 - offset TM_31		;max y

CheckHack <(offset TM_21 - offset TM_11) eq (offset TM_22 - offset TM_12)>
