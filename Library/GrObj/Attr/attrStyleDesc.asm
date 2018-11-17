COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextAttr
FILE:		taStyleDesc.asm

AUTHOR:		Tony

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/89		Initial revision

DESCRIPTION:
	Routines for generating a text description of a style

	$Id: attrStyleDesc.asm,v 1.1 97/04/04 18:07:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjStyleSheetCode segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	DescribeGrObjStyle

DESCRIPTION:	Return a text description of a text style

CALLED BY:	INTERNAL

PASS:
	es:di - buffer
	cx - bufer size left
	ds:si - style structure
	ds:dx - base style structure (dx = 0 for none)
	bp - number of characters already in buffer
	on stack - optr of extra UI to update

RETURN:
	es:di - updated
	cx - updated

DESTROYED:
	ax, bx, dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/27/91	Initial version

------------------------------------------------------------------------------@
DescribeGrObjStyle	proc	far	extraUI:optr, privateData:dword,
					attrsFlag:word
	ForceRef extraUI
	ForceRef privateData
	ForceRef attrsFlag
	.enter


	push	cx, di
	movdw	cxdi, extraUI
	call	UpdateGrObjStyleAttributeList
	pop	cx, di

	; if we are describing attributes then we do not want to add these
	; descriptions (because it does not make sense in the "Define New
	; Style" dialog box.

	tst	attrsFlag
	jnz	done

	mov	ax, ss:[bp]			;ax = # chars

	mov	bx, handle GrObjStyleStrings
	mov	dx, ds:[si].GSE_privateData.GSPD_flags

	test	dx, mask GSF_AREA_COLOR_RELATIVE
	jz	checkAreaMask
	mov	si, offset AreaColorRelativeString
	call	StyleSheetAddAttributeHeader
	mov	ax, 1

checkAreaMask:
	test	dx, mask GSF_AREA_MASK_RELATIVE
	jz	checkLineColor
	mov	si, offset AreaMaskRelativeString
	call	StyleSheetAddAttributeHeader
	mov	ax, 1

checkLineColor:
	test	dx, mask GSF_LINE_COLOR_RELATIVE
	jz	checkLineMask
	mov	si, offset LineColorRelativeString
	call	StyleSheetAddAttributeHeader
	mov	ax, 1

checkLineMask:
	test	dx, mask GSF_LINE_MASK_RELATIVE
	jz	checkLineWidth
	mov	si, offset LineMaskRelativeString
	call	StyleSheetAddAttributeHeader
	mov	ax, 1

checkLineWidth:
	test	dx, mask GSF_LINE_WIDTH_RELATIVE
	jz	done
	mov	si, offset LineWidthRelativeString
	call	StyleSheetAddAttributeHeader
	mov	ax, 1

done:


	.leave
	ret	@ArgSize

DescribeGrObjStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DescribeAreaAttr

DESCRIPTION:	Return a text description of the differences between two
		para attr structures

CALLED BY:	INTERNAL

PASS:
	es:di - buffer
	cx - bufer size left
	ds:si - derived attribute structure
	ds:dx - base attribute structure (dx = 0 for none)
	bp - number of characters already in buffer
	on stack - optr of extra UI to update
	on stack - optr of extra UI to update

RETURN:
	es:di - updated
	cx - updated

DESTROYED:
	ax, bx, dx, si, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/27/91		Initial version

------------------------------------------------------------------------------@
DescribeAreaAttr	proc	far	extraUI:optr, privateData:dword,
					attrsFlag:word

	ForceRef extraUI
	ForceRef attrsFlag

	clr	bx
diffs	local	GrObjBaseAreaAttrDiffs	\
		push	bx

	.enter

	; call diff routine -- if no ruler passed then use default para attr
	; and manually set the bits for the fields we always want to display

	push	cx, dx, di, es
	segmov	es, ds				;assume base structure passed
	mov	di, dx
	tst	dx
	jnz	gotBaseAreaAttr

	segmov	es, cs
	mov	di, offset defaultAreaAttr
	mov	diffs, mask GOBAAD_MULTIPLE_COLORS

if FULL_EXECUTE_IN_PLACE
	;
	; If XIP'ed we have to copy the element to the stack since 
	; GrObjDiffBaseAreaAttrs resides in a movable code segment and thus
	; can not take a fptr to a movable code segment.
	;
	mov	cx, size GrObjBaseAreaAttrElement
	call	SysCopyToStackESDI
	mov	dx, ss
	lea	bx, diffs			;dx:bx = diffs
	call	GrObjDiffBaseAreaAttrs
	;
	; Restore the stack since we used it to copy the element
	;
	call	SysRemoveFromStack	
	jmp	gotBaseAreaAttrXIP
endif

gotBaseAreaAttr:
	mov	dx, ss
	lea	bx, diffs			;dx:bx = diffs
	call	GrObjDiffBaseAreaAttrs

if FULL_EXECUTE_IN_PLACE
gotBaseAreaAttrXIP:
endif
	;
	;	remove undesireable flags
	;
	andnf	diffs, mask GOBAAD_MULTIPLE_COLORS or \
			mask GOBAAD_MULTIPLE_MASKS or \
			mask GOBAAD_MULTIPLE_PATTERNS or \
			mask GOBAAD_MULTIPLE_DRAW_MODES or \
			mask GOBAAD_MULTIPLE_INFOS or \
			mask GOBAAD_MULTIPLE_BACKGROUND_COLORS or \
			mask GOBAAD_MULTIPLE_ELEMENT_TYPES \
			or mask GOBAAD_MULTIPLE_GRADIENT_END_COLORS \
			or mask GOBAAD_MULTIPLE_GRADIENT_TYPES \
			or mask GOBAAD_MULTIPLE_GRADIENT_INTERVALS

	; if there is anything here then add the string "Paragraph: "

	pop	cx, dx, di, es
	jz	noDiffs

	push	si
	mov	ax, ss:[bp]
	mov	bx, handle GrObjStyleStrings
	mov	si, offset AreaString
	call	StyleSheetAddAttributeHeader
	pop	si

	; now go through the diff structure to generate text for all
	; things that are different

	push	bp
	mov	bx, dx				;ds:bx = old structure
	mov	dx, privateData.low
	mov	ax, offset GOBAADiffTable		;cs:ax = table
	pushdw	csax
	mov	ax, length GOBAADiffTable		;ax = count
	lea	bp, diffs
	call	StyleSheetCallDescribeRoutines
	pop	bp
noDiffs:

	.leave
	ret	@ArgSize

DescribeAreaAttr	endp

DescribeLineAttr	proc	far	extraUI:optr, privateData:dword,
					attrsFlag:word

	ForceRef extraUI
	ForceRef attrsFlag

	clr	bx
diffs	local	GrObjBaseLineAttrDiffs	\
		push	bx

	.enter

	; call diff routine -- if no ruler passed then use default para attr
	; and manually set the bits for the fields we always want to display

	push	cx, dx, di, es
	segmov	es, ds				;assume base structure passed
	mov	di, dx
	tst	dx
	jnz	gotBaseLineAttr

	segmov	es, cs
	mov	di, offset defaultLineAttr
	mov	diffs, mask GOBLAD_MULTIPLE_COLORS or \
			mask GOBLAD_MULTIPLE_WIDTHS

if FULL_EXECUTE_IN_PLACE
	;
	; If XIP'ed we have to copy the element to the stack since 
	; GrObjDiffBaseLineAttrs resides in a movable code segment and thus
	; can not take a fptr to a movable code segment.
	;
	mov	cx, size GrObjBaseLineAttrElement
	call	SysCopyToStackESDI
	mov	dx, ss
	lea	bx, diffs			;dx:bx = diffs
	call	GrObjDiffBaseLineAttrs
	;
	; Restore the stack since we used it to copy the element
	;
	call	SysRemoveFromStack	
	jmp	gotBaseLineAttrXIP
endif

gotBaseLineAttr:
	mov	dx, ss
	lea	bx, diffs			;dx:bx = diffs
	call	GrObjDiffBaseLineAttrs

if FULL_EXECUTE_IN_PLACE
gotBaseLineAttrXIP:
endif
	;
	;	remove undesireable flags
	;
	andnf	diffs, mask GOBLAD_MULTIPLE_COLORS or \
			mask GOBLAD_MULTIPLE_MASKS or \
			mask GOBLAD_MULTIPLE_WIDTHS or \
			mask GOBLAD_MULTIPLE_STYLES or \
			mask GOBLAD_ARROWHEAD_ON_START or \
			mask GOBLAD_ARROWHEAD_ON_END or \
			mask GOBLAD_ARROWHEAD_FILLED or \
			mask GOBLAD_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES or \
			mask GOBLAD_MULTIPLE_ARROWHEAD_ANGLES or \
			mask GOBLAD_MULTIPLE_ARROWHEAD_LENGTHS

	; if there is anything here then add the string "Paragraph: "

	tst	diffs
	pop	cx, dx, di, es
	jz	noDiffs

	push	si
	mov	ax, ss:[bp]
	mov	bx, handle GrObjStyleStrings
	mov	si, offset LineString
	call	StyleSheetAddAttributeHeader
	pop	si

	; now go through the diff structure to generate text for all
	; things that are different

	push	bp
	mov	bx, dx				;ds:bx = old structure
	mov	dx, privateData.low
	mov	ax, offset GLADiffTable		;cs:ax = table
	pushdw	csax
	mov	ax, length GLADiffTable		;ax = count
	lea	bp, diffs
	call	StyleSheetCallDescribeRoutines
	pop	bp
noDiffs:

	.leave
	ret	@ArgSize

DescribeLineAttr	endp

defaultAreaAttr	GrObjBaseAreaAttrElement <
	<<<1, 0>>, CA_NULL_ELEMENT>,		;GOBAAE_styleElement???
	0,					;r
	0,					;g
	0,					;b
	SDM_100,				;SystemDrawMask
	MM_COPY,				;MixMode
	<PT_SOLID,0>,				;GraphicPattern
	255,					;background r
	255,					;background g
	255,					;background b
	GOAAET_BASE,				;GrObjAreaAttrElementType
	mask GOAAIR_TRANSPARENT,		;GrObjAreaAttrInfoRecord
	0,					;reserved byte
	0,					;reserved word
>

defaultLineAttr	GrObjBaseLineAttrElement <
	<<<1, 0>>, CA_NULL_ELEMENT>,		;GOBAAE_styleElement???
	0,					;r
	0,					;g
	0,					;b
	LE_BUTTCAP,				;end
	LJ_MITERED,				;join
	<0, 1>,					;width
	SDM_100,				;mask
	LS_SOLID,				;style
	<0xb000,1>,				;miterLimit
	GOLAET_BASE,				;GrObjLineAttrElementType
	0,					;GrObjLineAttrInfoRecord
	15,					;Arrowhead angle
	10,					;arrowhead length
	0,					;reserved word
>

GOBAADiffTable	SSDiffEntry	\
 <0, mask GOBAAD_MULTIPLE_COLORS, DescAreaColor, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBAAD_MULTIPLE_MASKS, DescAreaMask, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBAAD_MULTIPLE_PATTERNS, DescPattern, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBAAD_MULTIPLE_DRAW_MODES, DescDrawMode, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBAAD_MULTIPLE_INFOS, DescAreaInfo, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBAAD_MULTIPLE_BACKGROUND_COLORS, DescBackgroundColor, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBAAD_MULTIPLE_ELEMENT_TYPES, DescGradientFill, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBAAD_MULTIPLE_GRADIENT_END_COLORS, DescGradientEndColor, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBAAD_MULTIPLE_GRADIENT_TYPES, DescGradientType, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBAAD_MULTIPLE_GRADIENT_INTERVALS, DescGradientIntervals, mask SSDF_NEW_CATEGORY>


GLADiffTable	SSDiffEntry	\
 <0, mask GOBLAD_MULTIPLE_COLORS, DescLineColor, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBLAD_MULTIPLE_MASKS, DescLineMask, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBLAD_MULTIPLE_WIDTHS, DescLineWidth, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBLAD_MULTIPLE_STYLES, DescLineStyle, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBLAD_ARROWHEAD_ON_START, DescArrowheadOnStart, mask SSDF_NEW_CATEGORY>,
 <0, mask GOBLAD_ARROWHEAD_ON_END, DescArrowheadOnEnd, mask SSDF_NEW_CATEGORY>,

 <0, mask GOBLAD_ARROWHEAD_FILLED or \
     mask GOBLAD_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES, \
	DescArrowheadFillType, mask SSDF_NEW_CATEGORY>,

 <0, mask GOBLAD_MULTIPLE_ARROWHEAD_ANGLES, DescArrowheadShape, mask SSDF_NEW_CATEGORY>

;---

AddSpace	proc	near
	push	ax
	LocalLoadChar ax, ' '
	call	StyleSheetAddCharToDescription
	pop	ax
	ret
AddSpace	endp

DescColorCommon		proc	far

	; for now just describe the standard colors

	push	bx, di

	lodsb			;al <- r
	mov	bh, al		;bh <- r
	lodsb			;al <- g
	mov	bl, al		;bl <- g
	lodsb			;al <- b
	xchg	al, bh		;al <- r, bh <- g
	clr	di
	call	GrMapColorRGB
	mov	al, ah
	clr	ah
	pop	bx, di

	mov	si, dx

	tst	bx
	jz	10$
	call	StyleSheetAddNameFromChunk
	call	AddSpace
10$:

	segmov	ds, cs
	mov	si, offset colorTable
	mov	dx, length colorTable
	mov	bx, handle GrObjStyleStrings
	clr	bp
	call	StyleSheetDescribeExclusiveWord
	ret

DescColorCommon	endp

colorTable	SSDescribeWordEntry	\
	<C_BLACK, offset BlackString>,
	<C_BLUE, offset DarkBlueString>,
	<C_GREEN, offset DarkGreenString>,
	<C_CYAN, offset CyanString>,
	<C_RED, offset DarkRedString>,
	<C_VIOLET, offset DarkVioletString>,
	<C_BROWN, offset BrownString>,
	<C_LIGHT_GRAY, offset LightGrayString>,
	<C_DARK_GRAY, offset DarkGrayString>,
	<C_LIGHT_BLUE, offset LightBlueString>,
	<C_LIGHT_GREEN, offset LightGreenString>,
	<C_LIGHT_CYAN, offset LightCyanString>,
	<C_LIGHT_RED, offset LightRedString>,
	<C_LIGHT_VIOLET, offset LightVioletString>,
	<C_YELLOW, offset YellowString>,
	<C_WHITE, offset WhiteString>

;---

DescGrayCommon	proc	far
	clr	dh

	; dx = draw mask, get 64 - (dx - SDM_100) = -dx + (64+SDM_100)

	neg	dx
	add	dx, SDM_100 + 64
	mov	ax, (100*256)/64
	mul	dx			;dx.ax = result/128, use dl.ah
	adddw	dxax, 0x80		;round
	mov	dh, dl
	mov	dl, ah
	clr	ax

	pushdw	bxsi
	clr	bx
	call	StyleSheetDescribeWWFixed
	LocalLoadChar	ax, '%'
	call	StyleSheetAddCharToDescription
	call	AddSpace
	popdw	bxsi
	call	StyleSheetAddNameFromChunk
	ret
DescGrayCommon	endp

DescPattern	proc	far
	mov	ax, {word} ds:[si].GOFAAE_base.GOBAAE_pattern
	segmov	ds, cs
	mov	si, offset patternTable
	mov	dx, length patternTable
	mov	bx, handle UnknownString
	mov	bp, offset UnknownString
	call	StyleSheetDescribeExclusiveWord

	call	AddSpace
	mov	bx, handle PatternString
	mov	si, offset PatternString
	call	StyleSheetAddNameFromChunk
	ret
DescPattern	endp

patternTable	SSDescribeWordEntry	\
	<0, SolidPatternString>,
	<PT_SYSTEM_HATCH or (SH_VERTICAL shl 8), VerticalPatternString>,
	<PT_SYSTEM_HATCH or (SH_HORIZONTAL shl 8), HorizontalPatternString>,
	<PT_SYSTEM_HATCH or (SH_45_DEGREE shl 8), Degree45PatternString>,
	<PT_SYSTEM_HATCH or (SH_135_DEGREE shl 8), Degree135PatternString>,
	<PT_SYSTEM_HATCH or (SH_BRICK shl 8), BrickPatternString>,
	<PT_SYSTEM_HATCH or (SH_SLANTED_BRICK shl 8), SlantedBrickPatternString>

DescGradientType	proc	far
	;
	;  If we're not a gradient, screw this
	;
	cmp	ds:[si].GOFAAE_base.GOBAAE_aaeType, GOAAET_GRADIENT
	jne	done

	clr	ah
	mov	al, ds:[si].GOGAAE_type
	segmov	ds, cs
	mov	si, offset gradientTypeTable
	mov	dx, length gradientTypeTable
	mov	bx, handle UnknownString
	mov	bp, offset UnknownString
	call	StyleSheetDescribeExclusiveWord

	call	AddSpace
	mov	bx, handle GradientString
	mov	si, offset GradientString
	call	StyleSheetAddNameFromChunk

done:
	ret
DescGradientType	endp

gradientTypeTable	SSDescribeWordEntry	\
	<GOGT_NONE, NoGradientString>,	
	<GOGT_LEFT_TO_RIGHT, HorizontalGradientString>,
	<GOGT_TOP_TO_BOTTOM, VerticalGradientString>,
	<GOGT_RADIAL_RECT, RadialRectGradientString>,
	<GOGT_RADIAL_ELLIPSE, RadialEllipseGradientString>

DescGradientIntervals	proc	far
	;
	;  If we're not a gradient, screw this
	;
	cmp	ds:[si].GOFAAE_base.GOBAAE_aaeType, GOAAET_GRADIENT
	jne	done

if 0
	cmp	ds:[si].GOGAAE_type, GOGT_NONE
	je	done
endif

	mov	ax, ds:[si].GOGAAE_numIntervals
	push	cx
	clr	cx, dx
	call	UtilHex32ToAscii
	add	di, cx
DBCS <	add	di, cx				; char offset -> byte offset>
	pop	ax
	sub	ax, cx
	mov_tr	cx, ax
	call	AddSpace
	mov	bx, handle GradientIntervalString
	mov	si, offset GradientIntervalString
	call	StyleSheetAddNameFromChunk

done:
	ret
DescGradientIntervals	endp

DescDrawMode	proc	far
	mov	al, ds:[si].GOFAAE_base.GOBAAE_drawMode
	clr	ah
	segmov	ds, cs
	mov	si, offset drawModeTable
	mov	dx, length drawModeTable
	mov	bx, handle UnknownString
	mov	bp, offset UnknownString
	call	StyleSheetDescribeExclusiveWord

	call	AddSpace
	mov	bx, handle DrawModeString
	mov	si, offset DrawModeString
	call	StyleSheetAddNameFromChunk
	ret
DescDrawMode	endp

drawModeTable	SSDescribeWordEntry	\
	<MM_CLEAR,MMClearString>,
	<MM_COPY,MMCopyString>,
	<MM_NOP,MMNopString>,
	<MM_AND,MMAndString>,
	<MM_INVERT,MMInvertString>,
	<MM_XOR,MMXorString>,
	<MM_SET,MMSetString>,
	<MM_OR,MMOrString>

DescAreaColor	proc	far
		; I think it'll be cleaner without the label
if not _USE_AREA_LINE_COLOR_STRING	
	clr	bx
else
	mov	bx, handle AreaColorString
	mov	dx, offset AreaColorString
endif
	addnf	si, <offset GOFAAE_base + offset GOBAAE_r>
	call	DescColorCommon
	ret
DescAreaColor	endp

DescLineColor	proc	far
		; I think it'll be cleaner without the label
if not _USE_AREA_LINE_COLOR_STRING	
	clr	bx
else
	mov	bx, handle LineColorString
	mov	dx, offset LineColorString
endif
	addnf	si, <offset GOFLAE_base + offset GOBLAE_r>
	call	DescColorCommon
	ret
DescLineColor	endp

DescBackgroundColor	proc	far
	mov	bx, handle BackgroundColorString
	mov	dx, offset BackgroundColorString
	addnf	si, <offset GOFAAE_base + offset GOBAAE_backR>
	call	DescColorCommon
	ret
DescBackgroundColor	endp

DescGradientEndColor	proc	far
	;
	;  If we're not a gradient, screw this
	;
	cmp	ds:[si].GOFAAE_base.GOBAAE_aaeType, GOAAET_GRADIENT
	jne	done

if 0
	cmp	ds:[si].GOGAAE_type, GOGT_NONE
	je	done
endif

	mov	bx, handle GradientEndColorString
	mov	dx, offset GradientEndColorString
	addnf	si, <offset GOGAAE_endR>
	call	DescColorCommon

done:
	ret
DescGradientEndColor	endp

;---

DescAreaInfo	proc	far
	mov	ax, offset DoDrawBackgroundString
	test	ds:[si].GOFAAE_base.GOBAAE_areaInfo, mask GOAAIR_TRANSPARENT
	jz	addName
	mov	ax, offset DontDrawBackgroundString
addName:
	mov_tr	si, ax
	mov	bx, handle DoDrawBackgroundString
	call	StyleSheetAddNameFromChunk
	ret
DescAreaInfo	endp

DescGradientFill	proc	far
	mov	ax, offset NoGradientFillString
	cmp	ds:[si].GOFAAE_base.GOBAAE_aaeType, GOAAET_GRADIENT
	jne	addName

	cmp	ds:[si].GOGAAE_type, GOGT_NONE
	je	addName

	mov	ax, offset YesGradientFillString
addName:
	mov_tr	si, ax
	mov	bx, handle YesGradientFillString
	call	StyleSheetAddNameFromChunk
	ret
DescGradientFill	endp

DescAreaMask	proc	far
	mov	dl, ds:[si].GOFAAE_base.GOBAAE_mask
	mov	bx, handle FilledString
	mov	si, offset FilledString
	call	DescGrayCommon
	ret
DescAreaMask	endp

DescLineMask	proc	far
	mov	dl, ds:[si].GOFLAE_base.GOBLAE_mask
	mov	bx, handle FilledString
	mov	si, offset FilledString
	call	DescGrayCommon
	ret
DescLineMask	endp

;---

DescLineWidth	proc	far
	clr	ax
	clr	bp
	test	dx, mask GSF_LINE_WIDTH_RELATIVE
	movdw	dxax, ds:[si].GOFLAE_base.GOBLAE_width
	jz	notRelative
	tst	bx
	jz	notRelative
	subdw	dxax, ds:[bx].GOFLAE_base.GOBLAE_width
	mov	bp, mask SSDDF_RELATIVE
notRelative:

	; dx.ah = value, convert to 13.3

rept 3
	shl	ax
	rcl	dx
endm

	mov	al, DU_POINTS
	clr	bx
	call	StyleSheetDescribeDistance
	ret

DescLineWidth	endp

DescLineStyle	proc	far
	mov_tr	bp, ax
	clr	ax
	mov	al, ds:[si].GOFLAE_base.GOBLAE_style
	segmov	ds, cs
	mov	si, offset lsNameTable
	mov	dx, length lsNameTable
	mov	bx, handle GrObjStyleStrings
	call	StyleSheetDescribeExclusiveWord
	ret
DescLineStyle	endp

lsNameTable	SSDescribeWordEntry	\
	<LS_SOLID, offset SolidString>,
	<LS_DASHED, offset DashedString>,
	<LS_DOTTED, offset DottedString>,
	<LS_DASHDOT, offset DashDotString>,
	<LS_DASHDDOT, offset DashDDotString>

DescArrowheadOnStart	proc	far
	test	 ds:[si].GOFLAE_base.GOBLAE_lineInfo, mask GOLAIR_ARROWHEAD_ON_START
	jnz	afterNo
	
	mov	bx, handle NoString
	mov	si, offset NoString
	call	StyleSheetAddNameFromChunk

afterNo:
	mov	bx, handle ArrowheadOnStartString
	mov	si, offset ArrowheadOnStartString
	call	StyleSheetAddNameFromChunk
	ret
DescArrowheadOnStart	endp
	
DescArrowheadOnEnd	proc	far
	test	ds:[si].GOFLAE_base.GOBLAE_lineInfo, mask GOLAIR_ARROWHEAD_ON_END
	jnz	afterNo
	
	mov	bx, handle NoString
	mov	si, offset NoString
	call	StyleSheetAddNameFromChunk

afterNo:
	mov	bx, handle ArrowheadOnEndString
	mov	si, offset ArrowheadOnEndString
	call	StyleSheetAddNameFromChunk
	ret
DescArrowheadOnEnd	endp

DescArrowheadFillType	proc	far
	mov	ax, offset ArrowheadUnfilledString
	test	ds:[si].GOFLAE_base.GOBLAE_lineInfo, mask GOLAIR_ARROWHEAD_FILLED
	jz	haveType
	mov	ax, offset ArrowheadFilledWithLineAttributesString
	test	ds:[si].GOFLAE_base.GOBLAE_lineInfo, mask GOLAIR_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES
	jz	haveType
	mov	ax, offset ArrowheadFilledWithAreaAttributesString
haveType:
	mov_tr	si, ax
	mov	bx, handle ArrowheadUnfilledString
	call	StyleSheetAddNameFromChunk
	ret
DescArrowheadFillType	endp

DescArrowheadShape	proc	far
	mov	al, ds:[si].GOFLAE_base.GOBLAE_arrowheadAngle
	clr	ah
	segmov	ds, cs
	mov	si, offset arrowheadShapeTable
	mov	dx, length arrowheadShapeTable
	mov	bx, handle UnknownString
	mov	bp, offset UnknownString
	call	StyleSheetDescribeExclusiveWord

	call	AddSpace
	mov	bx, handle ArrowheadString
	mov	si, offset ArrowheadString
	call	StyleSheetAddNameFromChunk
	ret
DescArrowheadShape	endp

arrowheadShapeTable	SSDescribeWordEntry	\
	<30, NarrowArrowheadString>,
	<45, WideArrowheadString>,
	<90, FlatheadArrowheadString>

GrObjStyleSheetCode ends
