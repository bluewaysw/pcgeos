COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextAttr
FILE:		taStyleMerge.asm

AUTHOR:		Tony

ROUTINES:
	Name			Description
	----			-----------
	SendCharAttrParaAttrChange

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/89		Initial revision

DESCRIPTION:
	Low level utility routines for implementing the methods defined on
	VisTextClass.

	$Id: taStyleMerge.asm,v 1.1 97/04/07 11:18:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextStyleSheet segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	MergeCharAttr

DESCRIPTION:	Merge the differences between two char attr structres into
		a third char attr structure.
			target <= new + (target - old)

CALLED BY:	INTERNAL

PASS:
	ds:si - attribute structure to modify ("target")
	es:di - result attribute structure (copy of "new")
	ds:cx - old attribute structure ("old")
	ss:bp - pointer to private data from style structure
	dx - current element size

RETURN:
	dx - new element size
	structure updated

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/27/91	Initial version
	SH	05/06/94	XIP'ed
------------------------------------------------------------------------------@

	; preserve dx to return same element size passed

MergeCharAttr	proc	far
	push	dx
	clr	ax
	mov	dx, ({TextStylePrivateData} ss:[bp]).TSPD_flags
diffs		local	VisTextCharAttrDiffs	\
			push	ax, ax, ax
	.enter

EC <	call	ECLMemValidateHeap					>

	; diff "target" and "old"

	push	dx, di, es
	mov	dx, ss
	lea	bx, diffs			;dx:bx = diffs
	segmov	es, cs
	mov	di, offset defaultCharAttr
	jcxz	10$
	segmov	es, ds				;es:di = old
	mov	di, cx
10$:
FXIP<	push	cx							>
FXIP<	mov	cx, size VisTextCharAttr				>
FXIP<	call	SysCopyToStackESDI					>
FXIP<	pop	cx							>
	call	DiffCharAttr
FXIP<	call	SysRemoveFromStack					>
	pop	dx, di, es

	; if there is no old structure then don't do things relative

	tst	cx
	jnz	oldExists
	clr	dx
oldExists:

	; if the relative flag(s) is set then we must force differences in the
	; fields that are relative

	test	dx, mask TSF_POINT_SIZE_RELATIVE
	jz	notRelative
	ornf	diffs.VTCAD_diffs, mask VTCAF_MULTIPLE_POINT_SIZES
notRelative:

	; now go through the diff structure to handle all
	; things that are different

	push	bp
	mov	ax, offset CAMergeTable		;cs:ax = table
	pushdw	csax
	mov	bx, cx				;ds:bx = old
	mov	cx, length CAMergeTable		;ax = count
	lea	bp, diffs
	call	StyleSheetCallMergeRoutines
	pop	bp

EC <	call	ECLMemValidateHeap					>

	.leave
	pop	dx
	ret

MergeCharAttr	endp

CAMergeTable	SSMergeEntry	\
	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_FONT_IDS,
		MergeWord, offset VTCA_fontID>,
	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_POINT_SIZES,
		MergePointSize, offset VTCA_pointSize>,
	<offset VTCAD_textStyles, TextStyle,
		MergeTextStyle, offset VTCA_textStyles>,
	<offset VTCAD_extendedStyles, VisTextExtendedStyles,
		MergeExtendedStyle, offset VTCA_extendedStyles>,

	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_COLORS,
		MergeDWord, offset VTCA_color>,
	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_GRAY_SCREENS,
		MergeByte, offset VTCA_grayScreen>,
	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_PATTERNS,
		MergeWord, offset VTCA_pattern>,

	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_FONT_WEIGHTS,
		MergeByte, offset VTCA_fontWeight>,
	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_FONT_WIDTHS,
		MergeByte, offset VTCA_fontWidth>,
	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_TRACK_KERNINGS,
		MergeWord, offset VTCA_trackKerning>,

	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_BG_COLORS,
		MergeDWord, offset VTCA_bgColor>,
	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_BG_GRAY_SCREENS,
		MergeByte, offset VTCA_bgGrayScreen>,
	<offset VTCAD_diffs, mask VTCAF_MULTIPLE_BG_PATTERNS,
		MergeWord, offset VTCA_bgPattern>

	; ds:si = target
	; es:di = result
	; ds:bx = old
	; ss:ax = diffs
	; cx = data (offset in structure)
	; dx = TextStyleFlags

;---

MergeDWord	proc	far
	add	si, cx
	add	di, cx
	movsw
	movsw
	ret
MergeDWord	endp

;---

MergeWord	proc	far
	add	si, cx
	add	di, cx
	movsw
	ret
MergeWord	endp

;---

MergeByte	proc	far
	add	si, cx
	add	di, cx
	movsb
	ret
MergeByte	endp

;---

MergePointSize	proc	far
	mov	cl, ds:[si].VTCA_pointSize.WBF_frac	;ax.cl = target
	mov	ax, ds:[si].VTCA_pointSize.WBF_int

	; if relative then use target - old + new

	test	dx, mask TSF_POINT_SIZE_RELATIVE
	jz	10$
	sub	cl, ds:[bx].VTCA_pointSize.WBF_frac
	sbb	ax, ds:[bx].VTCA_pointSize.WBF_int
	add	cl, es:[di].VTCA_pointSize.WBF_frac
	adc	ax, es:[di].VTCA_pointSize.WBF_int
10$:
	mov	es:[di].VTCA_pointSize.WBF_frac, cl
	mov	es:[di].VTCA_pointSize.WBF_int, ax
	ret
MergePointSize	endp

;---

MergeTextStyle	proc	far
	mov_tr	bp, ax				;ss:bp = diffs
	mov	al, ds:[si].VTCA_textStyles	;al = target
	mov	ah, es:[di].VTCA_textStyles	;ah = new
	mov	bl, ss:[bp].VTCAD_textStyles	;bl = bits to transfer
	and	al, bl
	not	bl
	and	ah, bl
	or	ah, al
	mov	es:[di].VTCA_textStyles, ah
	ret
MergeTextStyle	endp

;---

MergeExtendedStyle	proc	far
	mov_tr	bp, ax				;ss:bp = diffs
	mov	ax, ds:[si].VTCA_extendedStyles	;ax = target
	mov	bx, es:[di].VTCA_extendedStyles	;bx = new
	mov	cx, ss:[bp].VTCAD_extendedStyles ;cx = bits to transfer
	and	ax, cx
	not	cx
	and	bx, cx
	or	bx, ax
	mov	es:[di].VTCA_extendedStyles, bx
	ret
MergeExtendedStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MergeParaAttr

DESCRIPTION:	Merge the differences between two para attr structres into
		a third para attr structure
			target <= new + (target - old)

CALLED BY:	INTERNAL

PASS:
	ds:si - attribute structure to modify ("target")
	es:di - new attribute structure ("new")
	ds:cx - old attribute structure ("old")
	ss:bp - pointer to private data from style structure
	dx - chunk handle of element arrray (in case the target
	     needs to be resized)

RETURN:
	structure updated

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/27/91	Initial version
	SH	05/06/94	XIP'ed
------------------------------------------------------------------------------@
MergeParaAttr	proc	far
	clr	ax
	mov	dx, ({TextStylePrivateData} ss:[bp]).TSPD_flags
diffs		local	VisTextParaAttrDiffs	\
			push	ax, ax, ax, ax, ax, ax, ax
	.enter

EC <	call	ECLMemValidateHeap					>

	; diff "target" and "old"

	push	dx, di, es
	mov	dx, ss
	lea	bx, diffs			;dx:bx = diffs
	segmov	es, cs
	mov	di, offset defaultParaAttr
	jcxz	10$
	segmov	es, ds				;es:di = old
	mov	di, cx
10$:
FXIP<	push	cx							>
FXIP<	mov	cx, size VisTextParaAttr				>
FXIP<	call	SysCopyToStackESDI					>
FXIP<	pop	cx							>
	call	DiffParaAttr
FXIP<	call	SysRemoveFromStack					>
	pop	dx, di, es

	; if there is no old structure then don't do things relative

	tst	cx
	jnz	oldExists
	clr	dx
oldExists:

	; if the relative flag(s) is set then we must force differences in the
	; fields that are relative

	test	dx, mask TSF_MARGINS_RELATIVE
	jz	notRelative1
	ornf	diffs.VTPAD_diffs, mask VTPAF_MULTIPLE_LEFT_MARGINS or \
				   mask VTPAF_MULTIPLE_PARA_MARGINS or \
				   mask VTPAF_MULTIPLE_RIGHT_MARGINS
notRelative1:
	test	dx, mask TSF_LEADING_RELATIVE
	jz	notRelative2
	ornf	diffs.VTPAD_diffs, mask VTPAF_MULTIPLE_LEADINGS
notRelative2:

	; now go through the diff structure to handle all
	; things that are different

	push	bp
	mov	ax, offset PAMergeTable		;cs:ax = table
	pushdw	csax
	mov	bx, cx				;ds:bx = old
	mov	cx, length PAMergeTable		;ax = count
	lea	bp, diffs
	call	StyleSheetCallMergeRoutines
	pop	bp

EC <	call	ECLMemValidateHeap					>

	; return size

	CalcParaAttrSize	<es:[di]>, dx

	.leave
	ret

MergeParaAttr	endp

PAMergeTable	SSMergeEntry	\
	<offset VTPAD_attributes, VisTextParaAttrAttributes,
		MergeParaAttributes, offset VTPA_attributes>,
	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_LEFT_MARGINS,
		MergeMargin, offset VTPA_leftMargin>,
	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_PARA_MARGINS,
		MergeMargin, offset VTPA_paraMargin>,
	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_RIGHT_MARGINS,
		MergeMargin, offset VTPA_rightMargin>,

	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_LINE_SPACINGS,
		MergeWord, offset VTPA_lineSpacing>,
	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_LEADINGS,
		MergeLeading, 0>,
	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_TOP_SPACING,
		MergeWord, offset VTPA_spaceOnTop>,
	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_BOTTOM_SPACING,
		MergeWord, offset VTPA_spaceOnBottom>,
	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_DEFAULT_TABS,
		MergeWord, offset VTPA_defaultTabs>,

	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_BG_COLORS,
		MergeDWord, offset VTPA_bgColor>,
	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_BG_GRAY_SCREENS,
		MergeByte, offset VTPA_bgGrayScreen>,
	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_BG_PATTERNS,
		MergeWord, offset VTPA_bgPattern>,

	<offset VTPAD_diffs, mask VTPAF_MULTIPLE_TAB_LISTS,
		MergeTabList, 0>,

	<offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_LEFT or \
			    mask VTPABF_MULTIPLE_BORDER_TOP or \
			    mask VTPABF_MULTIPLE_BORDER_RIGHT or \
			    mask VTPABF_MULTIPLE_BORDER_BOTTOM or \
			    mask VTPABF_MULTIPLE_BORDER_DOUBLES or \
			    mask VTPABF_MULTIPLE_BORDER_DRAW_INNERS or \
			    mask VTPABF_MULTIPLE_BORDER_ANCHORS or \
			    mask VTPABF_MULTIPLE_BORDER_SHADOWS,
		MergeBorder, 0>,
	<offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_WIDTHS,
		MergeByte, offset VTPA_borderWidth>,
	<offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_SPACINGS,
		MergeByte, offset VTPA_borderSpacing>,
	<offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_COLORS,
		MergeDWord, offset VTPA_borderColor>,
	<offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_GRAY_SCREENS,
		MergeByte, offset VTPA_borderGrayScreen>,
	<offset VTPAD_borderDiffs, mask VTPABF_MULTIPLE_BORDER_PATTERNS,
		MergeWord, offset VTPA_borderPattern>,

	<offset VTPAD_hyphenationInfo, mask VisTextHyphenationInfo,
		MergeHypenationInfo, 0>,

	<offset VTPAD_keepInfo, mask VisTextKeepInfo,
		MergeKeepInfo, 0>

	; ds:si = target
	; es:di = result
	; ds:bx = old
	; ss:ax = diffs
	; cx = data (offset in structure)
	; dx = TextStyleFlags

;---

MergeParaAttributes	proc	far
	mov_tr	bp, ax				;ss:bp = diffs
	mov	ax, ds:[si].VTPA_attributes	;ax = target
	mov	bx, es:[di].VTPA_attributes	;bx = new
	mov	cx, ss:[bp].VTPAD_attributes	;cx = bits to transfer
	and	ax, cx
	not	cx
	and	bx, cx
	or	bx, ax
	mov	es:[di].VTPA_attributes, bx
	ret
MergeParaAttributes	endp

;---

MergeMargin	proc	far
	add	si, cx
	add	bx, cx
	add	di, cx

	mov	ax, ds:[si]			;ax = target

	; if relative then use target - old + new

	test	dx, mask TSF_MARGINS_RELATIVE
	jz	10$
	sub	ax, ds:[bx]
	add	ax, es:[di]
10$:
	mov	es:[di], ax
	ret

MergeMargin	endp

;---

MergeLeading	proc	far
	mov	ax, ds:[si].VTPA_leading	;ax = target

	; if relative then use target - old + new

	test	dx, mask TSF_LEADING_RELATIVE
	jz	10$
	sub	ax, ds:[bx].VTPA_leading
	add	ax, es:[di].VTPA_leading
10$:
	mov	es:[di].VTPA_leading, ax
	ret

MergeLeading	endp

;---

MergeTabList	proc	far
	mov	al, ds:[si].VTPA_numberOfTabs
	mov	es:[di].VTPA_numberOfTabs, al
	add	si, offset VTPA_tabList
	add	di, offset VTPA_tabList
	mov	cx, (VIS_TEXT_MAX_TABS * (size Tab)) / 2
	rep movsw
	ret
MergeTabList	endp

;---

MergeBorder	proc	far
	mov	ax, ds:[si].VTPA_borderFlags
	mov	es:[di].VTPA_borderFlags, ax
	mov	al, ds:[si].VTPA_borderShadow
	mov	es:[di].VTPA_borderShadow, al
	ret
MergeBorder	endp

;---

MergeHypenationInfo	proc	far

	mov_tr	bp, ax				;ss:bp = diffs
	mov	cx, ss:[bp].VTPAD_hyphenationInfo	;diffs
	mov	ax, ds:[si].VTPA_hyphenationInfo	;ax = target
	mov	bx, es:[di].VTPA_hyphenationInfo	;bx = old

	test	cx, mask VTHI_HYPHEN_MAX_LINES
	jz	10$
	and	bx, not mask VTHI_HYPHEN_MAX_LINES
	push	ax
	and	ax, mask VTHI_HYPHEN_MAX_LINES
	or	bx, ax
	pop	ax
10$:

	test	cx, mask VTHI_HYPHEN_SHORTEST_WORD
	jz	20$
	and	bx, not mask VTHI_HYPHEN_SHORTEST_WORD
	push	ax
	and	ax, mask VTHI_HYPHEN_SHORTEST_WORD
	or	bx, ax
	pop	ax
20$:

	test	cx, mask VTHI_HYPHEN_SHORTEST_PREFIX
	jz	30$
	and	bx, not mask VTHI_HYPHEN_SHORTEST_PREFIX
	push	ax
	and	ax, mask VTHI_HYPHEN_SHORTEST_PREFIX
	or	bx, ax
	pop	ax
30$:

	test	cx, mask VTHI_HYPHEN_SHORTEST_SUFFIX
	jz	40$
	and	bx, not mask VTHI_HYPHEN_SHORTEST_SUFFIX
	and	ax, mask VTHI_HYPHEN_SHORTEST_SUFFIX
	or	bx, ax
40$:

	mov	es:[di].VTPA_hyphenationInfo, bx
	ret
MergeHypenationInfo	endp

;---

MergeKeepInfo	proc	far

	mov_tr	bp, ax				;ss:bp = diffs
	mov	cl, ss:[bp].VTPAD_keepInfo	;diffs
	mov	al, ds:[si].VTPA_keepInfo	;ax = target
	mov	bl, es:[di].VTPA_keepInfo	;bx = old

	test	cl, mask VTKI_TOP_LINES
	jz	10$
	and	bl, not mask VTKI_TOP_LINES
	push	ax
	and	al, mask VTKI_TOP_LINES
	or	bl, al
	pop	ax
10$:

	test	cl, mask VTKI_BOTTOM_LINES
	jz	20$
	and	bl, not mask VTKI_BOTTOM_LINES
	and	al, mask VTKI_BOTTOM_LINES
	or	bl, al
20$:

	mov	es:[di].VTPA_keepInfo, bl
	ret
MergeKeepInfo	endp

TextStyleSheet ends
