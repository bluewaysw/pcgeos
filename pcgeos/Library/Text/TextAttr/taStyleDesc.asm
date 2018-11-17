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

	$Id: taStyleDesc.asm,v 1.1 97/04/07 11:18:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextStyleSheet segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	DescribeTextStyle

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
DescribeTextStyle	proc	far	extraUI:optr, privateData:dword,
					attrsFlag:word
	ForceRef privateData
	.enter

	push	cx, di
	movdw	cxdi, extraUI
	call	UpdateDescTextStyleAttributeList
	pop	cx, di

	; if we are describing attributes then we do not want to add these
	; descriptions (because it does not make sense in the "Define New
	; Style" dialog box.

	tst	attrsFlag
	jnz	done

	mov	ax, ss:[bp]			;ax = # chars

	mov	bx, handle TextStyleStrings
	mov	dx, ds:[si].TSEH_privateData.TSPD_flags

	; if there is anything here then add the string " + Character Only"

	test	dx, mask TSF_APPLY_TO_SELECTION_ONLY
	jz	afterCharOnly
	mov	si, offset CharacterOnlyString
	call	StyleSheetAddAttributeHeader
	mov	ax, 1
afterCharOnly:

	test	dx, mask TSF_POINT_SIZE_RELATIVE
	jz	afterPS
	mov	si, offset PointSizeRelativeString
	call	StyleSheetAddAttributeHeader
	mov	ax, 1
afterPS:

	test	dx, mask TSF_MARGINS_RELATIVE
	jz	afterMargins
	mov	si, offset MarginsRelativeString
	call	StyleSheetAddAttributeHeader
	mov	ax, 1
afterMargins:

	test	dx, mask TSF_LEADING_RELATIVE
	jz	afterLeading
	mov	si, offset LeadingRelativeString
	call	StyleSheetAddAttributeHeader
afterLeading:

done:
	.leave
	ret	@ArgSize

DescribeTextStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DescribeCharAttr

DESCRIPTION:	Return a text description of the differences between two
		char attr structures

CALLED BY:	INTERNAL

PASS:
	es:di - buffer
	cx - bufer size left
	ds:si - derived attribute structure
	ds:dx - base attribute structure (dx = 0 for none)
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
	SH	05/06/94	XIP'ed
------------------------------------------------------------------------------@
DescribeCharAttr	proc	far	extraUI:optr, privateData:dword,
					attrsFlag:word
	ForceRef extraUI
	ForceRef attrsFlag
	clr	bx
diffs	local	VisTextCharAttrDiffs	\
		push	bx, bx, bx
	.enter

	; call diff routine -- if no ruler passed then use default char attr
	; and manually set the bits for the fields we always want to display

	push	cx, dx, di, es
	segmov	es, ds				;assume base structure passed
	mov	di, dx
	tst	dx
	jnz	gotBaseCharAttr
	segmov	es, cs
	mov	di, offset defaultCharAttr
FXIP<	mov	cx, size VisTextCharAttr				>
FXIP<	call	SysCopyToStackESDI	; es:di <- ptr to stack		>
	mov	diffs.VTCAD_diffs, mask VTCAF_MULTIPLE_FONT_IDS or \
				   mask VTCAF_MULTIPLE_POINT_SIZES
FXIP<	mov	dx, ss							>
FXIP<	lea	bx, diffs			;dx:bx = diffs		>
FXIP<	call	DiffCharAttr						>
FXIP<	call	SysRemoveFromStack					>
FXIP<	jmp	xipDone							>

gotBaseCharAttr:
	mov	dx, ss
	lea	bx, diffs			;dx:bx = diffs
	call	DiffCharAttr
FXIP<xipDone:								>
	andnf	diffs.VTCAD_diffs, not mask VTCAF_MULTIPLE_STYLES
	andnf	diffs.VTCAD_extendedStyles, not mask VTES_BACKGROUND_COLOR

	; if there is anything here then add the string "Paragraph: "

	segmov	es, ss
	lea	di, diffs			;es:di = diffs
	clr	ax
	mov	cx, (size VisTextCharAttrDiffs) / 2
	repe scasw
	pop	cx, dx, di, es
	jz	noDiffs

	push	si
	mov	ax, ss:[bp]
	mov	bx, handle TextStyleStrings
	mov	si, offset CharacterString
	call	StyleSheetAddAttributeHeader
	pop	si

	; now go through the diff structure to generate text for all
	; things that are different

	push	bp
	mov	bx, dx				;ds:bx = old structure
	mov	dx, privateData.low
	mov	ax, offset CADiffTable		;cs:ax = table
	pushdw	csax
	mov	ax, length CADiffTable		;ax = count
	lea	bp, diffs
	call	StyleSheetCallDescribeRoutines
	pop	bp
noDiffs:

	.leave
	ret	@ArgSize

DescribeCharAttr	endp

defaultCharAttr	VisTextCharAttr <
	<<<1, 0>>, 0>, FID_DTC_URW_ROMAN, <0, 12>, <>,
	<C_BLACK, CF_INDEX, 0>, 0, FW_NORMAL, FWI_MEDIUM, <>, SDM_100, <>,
	<C_WHITE, CF_INDEX, 0>, SDM_0, <>, <>
>

NEW_CAT		equ	mask SSDF_NEW_CATEGORY

CADiffTable	SSDiffEntry	\
 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_FONT_IDS, DescFont, 0>,
 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_POINT_SIZES, DescPointSize, 0>,
 <offset VTCAD_textStyles, TextStyle, DescTextStyle, 0>,
 <offset VTCAD_extendedStyles, VisTextExtendedStyles, DescExtendedStyle, 0>,

 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_COLORS, DescTextColor, NEW_CAT>,
 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_GRAY_SCREENS, DescGrayScreen, 0>,
 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_PATTERNS, DescPattern, 0>,

 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_FONT_WEIGHTS, DescFontWeight, NEW_CAT>,
 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_FONT_WIDTHS, DescFontWidth, NEW_CAT>,
 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_TRACK_KERNINGS, DescTrackKerning, NEW_CAT>,

 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_BG_COLORS, DescBGColor, NEW_CAT>,
 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_BG_GRAY_SCREENS, DescBGGrayScreen, 0>,
 <offset VTCAD_diffs, mask VTCAF_MULTIPLE_BG_PATTERNS, DescBGPattern, 0>

	; es:di = buffer, cx = count
	; ds:si = new structure
	; ds:bx = old structure
	; ss:ax = diffs
	; dx = TextStyleFlags

;---

DescFont	proc	far
DBCS <fontName	local	FONT_NAME_LEN dup(wchar)			>
SBCS <fontName	local	FONT_NAME_LEN dup(char)				>
	.enter
	mov	ax, ds:[si].VTCA_fontID		;ax <- FontID
	push	cx				;save buffer size
	mov	cx, ax
	segmov	ds, ss
	lea	si, ss:fontName			;ds:si <- ptr to buffer
	call	GrGetFontName
	jcxz	unknownFont			;branch if font not found
	pop	cx				;cx <- buffer size
	call	StyleSheetAddNameFromPtr
done:
	.leave
	ret

	;
	; Font is unknown, so display:
	;	Font=####,
	; where #### is the font ID.
	;
unknownFont:
	pop	cx				;cx <- buffer size
	mov	si, offset UnknownFontString	;^lbx:si <- string
	call	OurAddName			;add "Font="
	call	StyleSheetAddWord		;add "####"
	jmp	done
DescFont	endp

;---

DescPointSize	proc	far
	clr	ax
	clr	bp
	test	dx, mask TSF_POINT_SIZE_RELATIVE
	mov	dx, ds:[si].VTCA_pointSize.WBF_int
	mov	ah, ds:[si].VTCA_pointSize.WBF_frac
	jz	notRelative
	tst	bx
	jz	notRelative
	sub	ah, ds:[bx].VTCA_pointSize.WBF_frac
	sbb	dx, ds:[bx].VTCA_pointSize.WBF_int
	mov	bp, mask SSDDF_RELATIVE
notRelative:

	; dx.ah = value, convert to 13.3

	shl	ah
	rcl	dx
	shl	ah
	rcl	dx
	shl	ah
	rcl	dx

	mov	al, DU_POINTS
	clr	bx
	call	StyleSheetDescribeDistance
	ret

DescPointSize	endp

;---

DescTextStyle	proc	far
	mov_tr	bp, ax
	clr	ax
	mov	al, ss:[bp].VTCAD_textStyles
	segmov	ds, cs
	mov	si, offset tsNameTable
	mov	dx, length tsNameTable
	mov	bx, handle TextStyleStrings
	call	StyleSheetDescribeNonExclusiveWord
	ret
DescTextStyle	endp

tsNameTable	SSDescribeWordEntry	\
	<mask TS_UNDERLINE, offset UnderlineString>,
	<mask TS_OUTLINE, offset OutlineString>,
	<mask TS_BOLD, offset BoldString>,
	<mask TS_ITALIC, offset ItalicString>,
	<mask TS_STRIKE_THRU, offset StrikeThruString>,
	<mask TS_SUPERSCRIPT, offset SuperscriptString>,
	<mask TS_SUBSCRIPT, offset SubscriptString>

;---

DescExtendedStyle	proc	far
	mov_tr	bp, ax
	mov	ax, ss:[bp].VTCAD_extendedStyles
	segmov	ds, cs
	mov	si, offset etsNameTable
	mov	dx, length etsNameTable
	mov	bx, handle TextStyleStrings
	call	StyleSheetDescribeNonExclusiveWord
	ret
DescExtendedStyle	endp

etsNameTable	SSDescribeWordEntry	\
	<mask VTES_BOXED, offset BoxedString>,
	<mask VTES_BUTTON, offset ButtonString>,
	<mask VTES_INDEX, offset IndexString>,
	<mask VTES_ALL_CAP, offset AllCapString>,
	<mask VTES_SMALL_CAP, offset SmallCapString>,
	<mask VTES_HIDDEN, offset HiddenString>,
	<mask VTES_CHANGE_BAR, offset ChangeBarString>

;---

DescFontWeight	proc	far
	clr	dx
	mov	dl, ds:[si].VTCA_fontWeight
	clr	ax
	mov	bx, handle FontWeightString
	mov	si, offset FontWeightString
	call	StyleSheetDescribeWWFixed
	ret
DescFontWeight	endp

;---

DescFontWidth	proc	far
	clr	dx
	mov	dl, ds:[si].VTCA_fontWidth
	clr	ax
	mov	bx, handle FontWidthString
	mov	si, offset FontWidthString
	call	StyleSheetDescribeWWFixed
	ret
DescFontWidth	endp

;---

DescTrackKerning	proc	far
	mov	dx, ds:[si].VTCA_trackKerning
	clr	ax
	mov	bx, handle TrackKerningString
	mov	si, offset TrackKerningString
	call	StyleSheetDescribeWWFixed
	ret
DescTrackKerning	endp

;---

DescTextColor	proc	far
	clr	bx
	add	si, offset VTCA_color
	FALL_THRU	DescColorCommon
DescTextColor	endp

	; ds:si = SetColorParams, bx:dx = string

DescColorCommon	proc	far

	; for now just describe the standard colors

	clr	ax
	mov	al, ds:[si].CQ_redOrIndex

	mov	si, dx

	tst	bx
	jz	10$
	call	StyleSheetAddNameFromChunk
	call	AddSpace
10$:

	segmov	ds, cs
	mov	si, offset colorTable
	mov	dx, length colorTable
	mov	bx, handle TextStyleStrings
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

DescGrayScreen	proc	far
	mov	dl, ds:[si].VTCA_grayScreen
	FALL_THRU	DescGrayCommon

DescGrayScreen	endp

	; dl = SystemDraskMask

DescGrayCommon	proc	far
	mov	si, offset FilledString
	cmp	dl, SDM_100
	jz	gotString
	mov	si, offset UnfilledString
	cmp	dl, SDM_0
	jz	gotString

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

	clr	bx
	call	StyleSheetDescribeWWFixed
	LocalLoadChar ax, '%'
	call	StyleSheetAddCharToDescription
	call	AddSpace
	mov	si, offset HalftoneString
gotString:
	call	OurAddName
	ret
DescGrayCommon	endp

;---

DescPattern	proc	far
	mov	ax, {word} ds:[si].VTCA_pattern
	FALL_THRU	DescPatternCommon

DescPattern	endp

	; ax = pattern (al = PatternType, ah = data)

DescPatternCommon	proc	far
	segmov	ds, cs
	mov	si, offset patternTable
	mov	dx, length patternTable
	mov	bx, handle UnknownPatternString
	mov	bp, offset UnknownPatternString
	call	StyleSheetDescribeExclusiveWord

	call	AddSpace
	mov	si, offset PatternString
	GOTO	OurAddName

DescPatternCommon	endp

patternTable	SSDescribeWordEntry	\
	<0, SolidPatternString>,
	<PT_SYSTEM_HATCH or (SH_VERTICAL shl 8), VerticalPatternString>,
	<PT_SYSTEM_HATCH or (SH_HORIZONTAL shl 8), HorizontalPatternString>,
	<PT_SYSTEM_HATCH or (SH_45_DEGREE shl 8), Degree45PatternString>,
	<PT_SYSTEM_HATCH or (SH_135_DEGREE shl 8), Degree135PatternString>,
	<PT_SYSTEM_HATCH or (SH_BRICK shl 8), BrickPatternString>,
	<PT_SYSTEM_HATCH or (SH_SLANTED_BRICK shl 8), SlantedBrickPatternString>

;---

DescBGColor	proc	far
	mov	bx, handle BGColorString
	mov	dx, offset BGColorString
	add	si, offset VTCA_bgColor
	GOTO	DescColorCommon
DescBGColor	endp

;---

DescBGGrayScreen	proc	far
	mov	dl, ds:[si].VTCA_bgGrayScreen
	GOTO	DescGrayCommon

DescBGGrayScreen	endp

;---

DescBGPattern	proc	far
	mov	ax, {word} ds:[si].VTCA_bgPattern
	GOTO	DescPatternCommon

DescBGPattern	endp

;=========

AddSpace	proc	near
	push	ax
	LocalLoadChar	ax, ' '
	call	StyleSheetAddCharToDescription
	pop	ax
	ret
AddSpace	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DescribeParaAttr

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
DescribeParaAttr	proc	far	extraUI:optr, privateData:dword,
					attrsFlag:word
	ForceRef extraUI
	ForceRef attrsFlag

	clr	bx
diffs	local	VisTextParaAttrDiffs	\
		push	bx, bx, bx, bx, bx, bx, bx
	.enter

	; call diff routine -- if no ruler passed then use default para attr
	; and manually set the bits for the fields we always want to display

	push	cx, dx, di, es
	segmov	es, ds				;assume base structure passed
	mov	di, dx
	tst	dx
	jnz	gotBaseParaAttr
	segmov	es, cs
	mov	di, offset defaultParaAttr
FXIP<	mov	cx, size VisTextParaAttr				>
FXIP<	call	SysCopyToStackESDI	; es:di <- ptr to stack		>
	mov	diffs.VTPAD_attributes, mask VTPAA_JUSTIFICATION
FXIP<	mov	dx, ss							>
FXIP<	lea	bx, diffs			;dx:bx = diffs		>
FXIP<	call	DiffParaAttr						>
FXIP<	call	SysRemoveFromStack					>
FXIP<	jmp	xipDone							>

gotBaseParaAttr:
	mov	dx, ss
	lea	bx, diffs			;dx:bx = diffs
	call	DiffParaAttr
FXIP<xipDone:								>
	andnf	diffs.VTPAD_diffs, not mask VTPAF_MULTIPLE_STYLES

	; if there is anything here then add the string "Paragraph: "

	segmov	es, ss
	lea	di, diffs			;es:di = diffs
	clr	ax
	mov	cx, (size VisTextParaAttrDiffs) / 2
	repe scasw
	pop	cx, dx, di, es
	jz	noDiffs

	push	si
	mov	ax, ss:[bp]
	mov	bx, handle TextStyleStrings
	mov	si, offset ParagraphString
	call	StyleSheetAddAttributeHeader
	pop	si

	; now go through the diff structure to generate text for all
	; things that are different

	push	bp
	mov	bx, dx				;ds:bx = old structure
	mov	dx, privateData.low
	mov	ax, offset PADiffTable		;cs:ax = table
	pushdw	csax
	mov	ax, length PADiffTable		;ax = count
	lea	bp, diffs
	call	StyleSheetCallDescribeRoutines
	pop	bp
noDiffs:

	.leave
	ret	@ArgSize

DescribeParaAttr	endp

defaultParaAttr	VisTextParaAttr <
	<<<1, 0>>, CA_NULL_ELEMENT>,
	<0, 0, 0, 0, 0, 0, SA_TOP_LEFT>, <C_BLACK, CF_INDEX, 0>,
	<0, 0, 0, 0, 0, 0, 0, 0, 0>,		;attributes
	0*PIXELS_PER_INCH, 0*PIXELS_PER_INCH, 0*PIXELS_PER_INCH, ;margins
	<0, 1>, 0, 0, 0, <C_WHITE, CF_INDEX, 0>, ;bg color
	0, 1*8, 2*8, 1*8,
	SDM_100, SDM_0, <>, <>, (PIXELS_PER_INCH*8)/2,
	VIS_TEXT_DEFAULT_STARTING_NUMBER,
	<0,0,0,0>, <>, <>, <>, <>
>

PADiffTable	SSDiffEntry	\
 <offset VTPAD_attributes, mask VTPAA_JUSTIFICATION, DescJustification, 0>,
 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_LEFT_MARGINS, DescLeftMargin, NEW_CAT>,
 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_PARA_MARGINS, DescParaMargin, NEW_CAT>,
 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_RIGHT_MARGINS, DescRightMargin, NEW_CAT>,

 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_LINE_SPACINGS or mask VTPAF_MULTIPLE_LEADINGS, DescLineSpacingAndLeading, NEW_CAT>,
 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_TOP_SPACING, DescTopSpacing, NEW_CAT>,
 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_BOTTOM_SPACING, DescBottomSpacing, NEW_CAT>,
 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_DEFAULT_TABS, DescDefaultTabs, NEW_CAT>,

 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_BG_COLORS, DescParaBGColor, NEW_CAT>,
 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_BG_GRAY_SCREENS, DescParaBGGrayScreen, 0>,
 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_BG_PATTERNS, DescParaBGPattern, 0>,

 <offset VTPAD_diffs, mask VTPAF_MULTIPLE_TAB_LISTS, DescTabList, NEW_CAT>,

 <offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_LEFT or \
			    mask VTPABF_MULTIPLE_BORDER_TOP or \
			    mask VTPABF_MULTIPLE_BORDER_RIGHT or \
			    mask VTPABF_MULTIPLE_BORDER_BOTTOM or \
			    mask VTPABF_MULTIPLE_BORDER_DOUBLES or \
			    mask VTPABF_MULTIPLE_BORDER_DRAW_INNERS or \
			    mask VTPABF_MULTIPLE_BORDER_ANCHORS or \
			    mask VTPABF_MULTIPLE_BORDER_SHADOWS,
						DescBorder, NEW_CAT>,
 <offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_WIDTHS, DescBorderWidth, NEW_CAT>,
 <offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_SPACINGS, DescBorderSpacing, NEW_CAT>,
 <offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_COLORS, DescBorderColor, NEW_CAT>,
 <offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_GRAY_SCREENS, DescBorderGrayScreen, 0>,
 <offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_PATTERNS, DescBorderPattern, 0>,

 <offset VTPAD_attributes, mask VTPAA_DISABLE_WORD_WRAP, DescDisableWordWrap, NEW_CAT>,
 <offset VTPAD_attributes, mask VTPAA_COLUMN_BREAK_BEFORE, DescColumnBreakBefore, NEW_CAT>,
 <offset VTPAD_attributes, mask VTPAA_KEEP_PARA_WITH_NEXT, DescKeepParaWithNext, NEW_CAT>,
 <offset VTPAD_attributes, mask VTPAA_KEEP_PARA_TOGETHER, DescKeepParaTogether, NEW_CAT>,

 <offset VTPAD_attributes, mask VTPAA_ALLOW_AUTO_HYPHENATION, DescAutoHyphenation, NEW_CAT>,
 <offset VTPAD_hyphenationInfo, mask VTHI_HYPHEN_MAX_LINES, DescHyphenationMaxLines, NEW_CAT>,
 <offset VTPAD_hyphenationInfo, mask VTHI_HYPHEN_SHORTEST_WORD, DescHyphenationShortestWord, NEW_CAT>,
 <offset VTPAD_hyphenationInfo, mask VTHI_HYPHEN_SHORTEST_PREFIX, DescHyphenationShortestPrefix, NEW_CAT>,
 <offset VTPAD_hyphenationInfo, mask VTHI_HYPHEN_SHORTEST_SUFFIX, DescHyphenationShortestSuffix, NEW_CAT>,

 <offset VTPAD_attributes, mask VTPAA_KEEP_LINES, DescKeepLines, NEW_CAT>,
 <offset VTPAD_keepInfo, mask VTKI_TOP_LINES, DescKeepTop, NEW_CAT>,
 <offset VTPAD_keepInfo, mask VTKI_BOTTOM_LINES, DescKeepBottom, NEW_CAT>

;---

DescJustification	proc	far
	mov	ax, ds:[si].VTPA_attributes
if CHAR_JUSTIFICATION
.assert (offset VTPAA_JUSTIFICATION gt 8)
	ornf	al, ds:[si].VTPA_miscMode
	and	ax, mask VTPAA_JUSTIFICATION or mask TMMF_CHARACTER_JUSTIFICATION
else
	and	ax, mask VTPAA_JUSTIFICATION
endif
	segmov	ds, cs
	mov	si, offset justNameTable
	mov	dx, length justNameTable
	mov	bx, handle TextStyleStrings
	call	StyleSheetDescribeExclusiveWord
	ret
DescJustification	endp

if CHAR_JUSTIFICATION
justNameTable	SSDescribeWordEntry	\
	<J_LEFT shl offset VTPAA_JUSTIFICATION, offset LeftJustString>,
	<J_CENTER shl offset VTPAA_JUSTIFICATION, offset CenterJustString>,
	<J_RIGHT shl offset VTPAA_JUSTIFICATION, offset RightJustString>,
	<J_FULL shl offset VTPAA_JUSTIFICATION, offset FullJustString>,
	<J_FULL shl offset VTPAA_JUSTIFICATION or mask TMMF_CHARACTER_JUSTIFICATION, offset FullCharJustString>
else
justNameTable	SSDescribeWordEntry	\
	<J_LEFT shl offset VTPAA_JUSTIFICATION, offset LeftJustString>,
	<J_CENTER shl offset VTPAA_JUSTIFICATION, offset CenterJustString>,
	<J_RIGHT shl offset VTPAA_JUSTIFICATION, offset RightJustString>,
	<J_FULL shl offset VTPAA_JUSTIFICATION, offset FullJustString>
endif

;---

DescLeftMargin	proc	far	
	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	test	dx, mask TSF_MARGINS_RELATIVE
	mov	dx, ds:[si].VTPA_leftMargin
	jz	notRelative
	tst	bx
	jz	notRelative
	sub	dx, ds:[bx].VTPA_leftMargin
	mov	bp, mask SSDDF_RELATIVE
notRelative:

	mov	al, DU_INCHES_OR_CENTIMETERS
	mov	bx, handle LeftMarginString
	mov	si, offset LeftMarginString
	call	StyleSheetDescribeDistance
	ret

DescLeftMargin	endp

;---

DescParaMargin	proc	far
	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	test	dx, mask TSF_MARGINS_RELATIVE
	mov	dx, ds:[si].VTPA_paraMargin
	jz	notRelative
	tst	bx
	jz	notRelative
	sub	dx, ds:[bx].VTPA_paraMargin
	mov	bp, mask SSDDF_RELATIVE
notRelative:

	mov	al, DU_INCHES_OR_CENTIMETERS
	mov	bx, handle ParaMarginString
	mov	si, offset ParaMarginString
	call	StyleSheetDescribeDistance
	ret

DescParaMargin	endp

;---

DescRightMargin	proc	far
	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	test	dx, mask TSF_MARGINS_RELATIVE
	mov	dx, ds:[si].VTPA_rightMargin
	jz	notRelative
	tst	bx
	jz	notRelative
	sub	dx, ds:[bx].VTPA_rightMargin
	mov	bp, mask SSDDF_RELATIVE
notRelative:

	mov	al, DU_INCHES_OR_CENTIMETERS
	mov	bx, handle RightMarginString
	mov	si, offset RightMarginString
	call	StyleSheetDescribeDistance
	ret

DescRightMargin	endp

;---

DescLineSpacingAndLeading	proc	far
	tst	ds:[si].VTPA_leading
	jnz	leading

	; describe line spacing only

	clrdw	dxax
	mov	dl, ds:[si].VTPA_lineSpacing.high
	mov	ah, ds:[si].VTPA_lineSpacing.low

	mov	bx, handle LineSpacingString
	mov	si, offset LineSpacingString
	call	StyleSheetDescribeWWFixed
	ret

leading:

	; describe leading only

	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	test	dx, mask TSF_LEADING_RELATIVE
	mov	dx, ds:[si].VTPA_leading
	jz	notRelative
	tst	bx
	jz	notRelative
	sub	ax, ds:[bx].VTPA_leading
	mov	bp, mask SSDDF_RELATIVE
notRelative:

	mov	al, DU_POINTS_OR_MILLIMETERS
	mov	bx, handle LeadingString
	mov	si, offset LeadingString
	call	StyleSheetDescribeDistance
	ret

DescLineSpacingAndLeading	endp

;---

DescTopSpacing	proc	far
	mov	dx, ds:[si].VTPA_spaceOnTop

	mov	al, DU_POINTS_OR_MILLIMETERS
	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	mov	bx, handle TopSpacingString
	mov	si, offset TopSpacingString
	call	StyleSheetDescribeDistance
	ret

DescTopSpacing	endp

;---

DescBottomSpacing	proc	far
	mov	dx, ds:[si].VTPA_spaceOnBottom

	mov	al, DU_POINTS_OR_MILLIMETERS
	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	mov	bx, handle BottomSpacingString
	mov	si, offset BottomSpacingString
	call	StyleSheetDescribeDistance
	ret

DescBottomSpacing	endp

;---

DescDefaultTabs	proc	far
	mov	dx, ds:[si].VTPA_defaultTabs
	tst	dx
	jz	none

	mov	al, DU_INCHES_OR_CENTIMETERS
	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	mov	bx, handle DefaultTabsString
	mov	si, offset DefaultTabsString
	call	StyleSheetDescribeDistance
	ret

none:
	mov	si, offset NoDefaultTabsString
	FALL_THRU	OurAddName

DescDefaultTabs	endp

OurAddName	proc	far
	mov	bx, handle NoDefaultTabsString
	call	StyleSheetAddNameFromChunk
	ret
OurAddName	endp

;---

DescParaBGColor	proc	far
	mov	bx, handle ParaBGColorString
	mov	dx, offset ParaBGColorString
	add	si, offset VTPA_bgColor
	GOTO	DescColorCommon
DescParaBGColor	endp

;---

DescParaBGGrayScreen	proc	far
	mov	dl, ds:[si].VTPA_bgGrayScreen
	GOTO	DescGrayCommon

DescParaBGGrayScreen	endp

;---

DescParaBGPattern	proc	far
	mov	ax, {word} ds:[si].VTPA_bgPattern
	GOTO	DescPatternCommon

DescParaBGPattern	endp

;---

	; Tabs: 1 inch, 2 inches centered,
	;  3 inches anchored with '.' with bullet leader
	;  50% halftone 3 point wide lines 4 point spacing,
	;  4 inches anchored 50% halftone

DescTabList	proc	far
	clr	ax
	mov	al, ds:[si].VTPA_numberOfTabs
	tst	ax
	jnz	haveTabs
	mov	si, offset NoTabsString
	GOTO	OurAddName
haveTabs:

	lea	bp, ds:[si].VTPA_tabList
	mov	si, offset TabsString
	call	OurAddName
	call	AddSpace

tabLoop:
	push	ax

	push	bp
	mov	dx, ds:[bp].T_position
	mov	al, DU_INCHES_OR_CENTIMETERS
	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	clr	bx
	call	StyleSheetDescribeDistance
	pop	bp

	clr	ax
	mov	al, ds:[bp].T_attr
	push	ax
	and	al, mask TA_TYPE
	cmp	al, TT_LEFT
	jz	afterType
	call	AddSpace
	push	ds
	segmov	ds, cs
	mov	bx, handle TabsString
	mov	si, offset tabTypesTable
	mov	dx, length tabTypesTable
	call	StyleSheetDescribeExclusiveWord
	pop	ds

	cmp	al, TT_ANCHORED
	jnz	afterType
	call	AddSpace
	mov	si, offset AnchoredWithString
	call	OurAddName
	mov	al, ds:[bp].T_anchor.low
	call	StyleSheetAddCharToDescription
	mov	si, offset AnchoredEndString
	call	OurAddName
afterType:

	pop	ax
	and	al, mask TA_LEADER
	jz	afterLeader
	call	AddSpace
	mov	si, offset WithString
	call	OurAddName
	call	AddSpace
	push	ds
	segmov	ds, cs
	mov	si, offset tabLeadersTable
	mov	dx, length tabLeadersTable
	call	StyleSheetDescribeExclusiveWord
	pop	ds
	call	AddSpace
	mov	si, offset LeaderString
	call	OurAddName
afterLeader:

	mov	dl, ds:[bp].T_grayScreen
	cmp	dl, SDM_100
	jz	afterGray
	call	AddSpace
	call	DescGrayCommon
afterGray:

	clr	dx
	mov	dl, ds:[bp].T_lineWidth
	tst	dx
	jz	afterLineWidth
	push	bp
	call	AddSpace
	mov	al, DU_POINTS_OR_MILLIMETERS
	clr	bp
	clr	bx
	call	StyleSheetDescribeDistance
	mov	bx, handle TabLineWidthString
	mov	si, offset TabLineWidthString
	call	AddSpace
	call	OurAddName
	pop	bp
afterLineWidth:

	clr	dx
	mov	dl, ds:[bp].T_lineSpacing
	cmp	dx, 1*8
	jz	afterLineSpacing
	push	bp
	call	AddSpace
	mov	al, DU_POINTS_OR_MILLIMETERS
	clr	bp
	clr	bx
	call	StyleSheetDescribeDistance
	mov	bx, handle TabLineSpacingString
	mov	si, offset TabLineSpacingString
	call	AddSpace
	call	OurAddName
	pop	bp
afterLineSpacing:

	add	bp, size Tab
	pop	ax
	dec	ax
	jz	done
	push	ax
	LocalLoadChar	ax, ','
	call	StyleSheetAddCharToDescription
	pop	ax
	call	AddSpace
	jmp	tabLoop

done:
	ret

DescTabList	endp

tabTypesTable	SSDescribeWordEntry	\
	<TT_CENTER, offset CenterJustString>,
	<TT_RIGHT, offset RightJustString>,
	<TT_ANCHORED, offset AnchoredString>

tabLeadersTable	SSDescribeWordEntry	\
	<TL_DOT shl offset TA_LEADER, offset DotLeaderString>,
	<TL_LINE shl offset TA_LEADER, offset LineLeaderString>,
	<TL_BULLET shl offset TA_LEADER, offset BulletLeaderString>

;---

	; "Double Line Border"

DescBorder	proc	far
	mov	ax, ds:[si].VTPA_borderFlags
	clr	dx
	mov	dl, ds:[si].VTPA_borderShadow

	test	ax, mask VTPBF_LEFT or mask VTPBF_TOP or mask VTPBF_RIGHT \
				or mask VTPBF_BOTTOM
	jnz	borderExists
	mov	si, offset NoBorderString
	GOTO	OurAddName
borderExists:

	; first output the border type

	mov	si, offset DoubleBorderString
	test	ax, mask VTPBF_DOUBLE
	jnz	gotType
	mov	si, offset ShadowBorderString
	test	ax, mask VTPBF_SHADOW
	jnz	gotType
	mov	si, offset NormalBorderString
gotType:
	call	OurAddName			;sets bx

	push	ax
	test	ax, mask VTPBF_DOUBLE
	jz	notDouble

	; "Double Line Border"
	; "Double Line Border with 2 points between lines"

	cmp	dx, 1*8
	jz	afterDoubleWidth
	mov	al, DU_POINTS_OR_MILLIMETERS
	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	mov	si, offset WithString
	call	AddSpace
	call	StyleSheetDescribeDistance
	mov	si, offset SpaceBetweenString
	call	AddSpace
	call	OurAddName
afterDoubleWidth:
	jmp	common

notDouble:
	test	ax, mask VTPBF_SHADOW
	jz	common

	; "Shadowed Border"
	; "Shadowed Border from bottom-right"
	; "Shadowed Border with 2 point shadow"
	; "Shadowed Border from bottom-right with 2 point shadow"

	and	ax, mask VTPBF_ANCHOR
				CheckHack <SA_TOP_LEFT eq 0>
	jz	afterShadow
	mov	si, offset ShadowTopRightString
				CheckHack <SA_TOP_RIGHT eq 1>
	dec	ax
	jz	gotShadow
	mov	si, offset ShadowBottomLeftString
				CheckHack <SA_BOTTOM_LEFT eq 2>
	dec	ax
	jz	gotShadow
	mov	si, offset ShadowBottomRightString
				CheckHack <SA_BOTTOM_RIGHT eq 3>
gotShadow:
	call	AddSpace
	call	OurAddName
afterShadow:

	cmp	dx, 1*8
	jz	afterShadowWidth
	mov	al, DU_POINTS_OR_MILLIMETERS
	clr	bp
	mov	si, offset WithString
	call	AddSpace
	call	StyleSheetDescribeDistance
	mov	si, offset ShadowWidthString
	call	AddSpace
	call	OurAddName
afterShadowWidth:

;-----

common:
	pop	ax

	; "Normal Border top,left sides only"

	push	ax
	and	ax, mask VTPBF_LEFT or mask VTPBF_TOP or mask VTPBF_RIGHT \
				or mask VTPBF_BOTTOM
	cmp	ax, mask VTPBF_LEFT or mask VTPBF_TOP or mask VTPBF_RIGHT \
				or mask VTPBF_BOTTOM
	jz	afterSides
	call	AddSpace
	segmov	ds, cs
	mov	si, offset sidesTable
	mov	dx, length sidesTable
	call	StyleSheetDescribeNonExclusiveWord
	mov	si, offset SideString
	cmp	ax, 1
	jz	gotSideString
	mov	si, offset SidesString
gotSideString:
	call	AddSpace
	call	OurAddName
afterSides:
	pop	ax

	test	ax, mask VTPBF_DRAW_INNER_LINES
	jz	afterInner
	mov	si, offset DrawInnerString
	LocalLoadChar  ax, ','
	call	StyleSheetAddCharToDescription
	call	AddSpace
	call	OurAddName
afterInner:

	ret

DescBorder	endp

sidesTable	SSDescribeWordEntry	\
	<mask VTPBF_LEFT, offset LeftString>,
	<mask VTPBF_TOP, offset TopString>,
	<mask VTPBF_RIGHT, offset RightString>,
	<mask VTPBF_BOTTOM, offset BottomString>

;---

DescBorderWidth	proc	far
	clr	dx
	mov	dl, ds:[si].VTPA_borderWidth

	mov	al, DU_POINTS_OR_MILLIMETERS
	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	mov	bx, handle BorderWidthString
	mov	si, offset BorderWidthString
	call	StyleSheetDescribeDistance
	ret

DescBorderWidth	endp

;---

DescBorderSpacing	proc	far
	clr	dx
	mov	dl, ds:[si].VTPA_borderSpacing

	mov	al, DU_POINTS_OR_MILLIMETERS
	mov	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	mov	bx, handle BorderSpacingString
	mov	si, offset BorderSpacingString
	call	StyleSheetDescribeDistance
	ret

DescBorderSpacing	endp

;---

DescBorderColor	proc	far
	mov	bx, handle BorderColorString
	mov	dx, offset BorderColorString
	add	si, offset VTPA_borderColor
	GOTO	DescColorCommon
DescBorderColor	endp

;---

DescBorderGrayScreen	proc	far
	mov	dl, ds:[si].VTPA_borderGrayScreen
	GOTO	DescGrayCommon

DescBorderGrayScreen	endp

;---

DescBorderPattern	proc	far
	mov	ax, {word} ds:[si].VTPA_borderPattern
	GOTO	DescPatternCommon

DescBorderPattern	endp

;---

DescDisableWordWrap	proc	far
	mov	si, offset DisableWordWrapString
	GOTO	OurAddName
DescDisableWordWrap	endp

;---

DescColumnBreakBefore	proc	far
	mov	si, offset ColumnBreakBeforeString
	GOTO	OurAddName
DescColumnBreakBefore	endp

;---

DescKeepParaWithNext	proc	far
	mov	si, offset KeepParaWithNextString
	GOTO	OurAddName
DescKeepParaWithNext	endp

;---

DescKeepParaTogether	proc	far
	mov	si, offset KeepParaTogetherString
	GOTO	OurAddName
DescKeepParaTogether	endp

;---

DescAutoHyphenation	proc	far
	mov	si, offset AutoHyphenationString
	GOTO	OurAddName
DescAutoHyphenation	endp

;---

DescHyphenationMaxLines	proc	far
	mov	dx, ds:[si].VTPA_hyphenationInfo
	mov	si, offset MaxLinesString
	and	dx, mask VTHI_HYPHEN_MAX_LINES
	mov	al, offset VTHI_HYPHEN_MAX_LINES
	FALL_THRU	HyphenCommon
DescHyphenationMaxLines	endp

HyphenCommon	proc	far
	mov	bp, 1
	FALL_THRU	DescFieldCommon
HyphenCommon	endp

DescFieldCommon	proc	far
	xchg	ax, cx
	shr	dx, cl
	mov_tr	cx, ax
	add	dx, bp				;dx.cx = value
	clr	ax
	clr	bp
	mov	bx, handle TextStyleStrings
	call	StyleSheetDescribeWWFixed
	ret
DescFieldCommon	endp

;---

DescHyphenationShortestWord	proc	far
	mov	dx, ds:[si].VTPA_hyphenationInfo
	mov	si, offset ShortestWordString
	and	dx, mask VTHI_HYPHEN_SHORTEST_WORD
	mov	al, offset VTHI_HYPHEN_SHORTEST_WORD
	GOTO	HyphenCommon
DescHyphenationShortestWord	endp

;---

DescHyphenationShortestPrefix	proc	far
	mov	dx, ds:[si].VTPA_hyphenationInfo
	mov	si, offset ShortestPrefixString
	and	dx, mask VTHI_HYPHEN_SHORTEST_PREFIX
	mov	al, offset VTHI_HYPHEN_SHORTEST_PREFIX
	GOTO	HyphenCommon
DescHyphenationShortestPrefix	endp

;---

DescHyphenationShortestSuffix	proc	far
	mov	dx, ds:[si].VTPA_hyphenationInfo
	mov	si, offset ShortestSuffixString
	and	dx, mask VTHI_HYPHEN_SHORTEST_SUFFIX
	mov	al, offset VTHI_HYPHEN_SHORTEST_SUFFIX
	GOTO	HyphenCommon
DescHyphenationShortestSuffix	endp

;---

DescKeepLines	proc	far
	mov	si, offset KeepLinesString
	GOTO	OurAddName
DescKeepLines	endp

;---

DescKeepTop	proc	far
	mov	dl, ds:[si].VTPA_keepInfo
	mov	si, offset KeepTopString
	and	dx, mask VTKI_TOP_LINES
	mov	al, offset VTKI_TOP_LINES
	FALL_THRU	KeepCommon
DescKeepTop	endp

KeepCommon	proc	far
	mov	bp, 2
	GOTO	DescFieldCommon
KeepCommon	endp

;---

DescKeepBottom	proc	far
	mov	dl, ds:[si].VTPA_keepInfo
	mov	si, offset KeepBottomString
	and	dx, mask VTKI_BOTTOM_LINES
	mov	al, offset VTKI_BOTTOM_LINES
	GOTO	KeepCommon
DescKeepBottom	endp

TextStyleSheet ends
