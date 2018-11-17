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

	$Id: attrStyleMerge.asm,v 1.1 97/04/04 18:07:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjStyleSheetCode segment resource

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
	Tony	12/27/91		Initial version

------------------------------------------------------------------------------@

	; preserve dx to return same element size passed

MergeGrObjAreaAttr	proc	far
	push	dx
	clr	ax
	mov	dx, ({GrObjStylePrivateData} ss:[bp]).GSPD_flags
diffs		local	GrObjBaseAreaAttrDiffs	\
			push	ax
	.enter

EC <	call	ECLMemValidateHeap					>

	; diff "target" and "old"

	push	dx, di, es
	mov	dx, ss
	lea	bx, diffs			;dx:bx = diffs

if FULL_EXECUTE_IN_PLACE
	segmov	es, ds				;es:di = old
	mov	di, cx
	jcxz	10$
	segmov	es, cs
	mov	di, offset defaultAreaAttr
	mov	cx, size GrObjBaseAreaAttrElement
	call	SysCopyToStackESDI		;es:di <- fptr to stack
	call	GrObjDiffBaseAreaAttrs
	call	SysRemoveFromStack
	jmp	20$
10$:
	call	GrObjDiffBaseAreaAttrs
20$:
else
	segmov	es, cs
	mov	di, offset defaultAreaAttr
	jcxz	10$
	segmov	es, ds				;es:di = old
	mov	di, cx
10$:
	call	GrObjDiffBaseAreaAttrs
endif

	pop	dx, di, es

	; if there is no old structure then don't do things relative

	tst	cx
	jnz	oldExists
	clr	dx
oldExists:

	; if the relative flag(s) is set then we must force differences in the
	; fields that are relative

	test	dx, mask GSF_AREA_COLOR_RELATIVE
	jz	checkAreaMask
	BitSet	diffs, GOBAAD_MULTIPLE_COLORS

checkAreaMask:
	test	dx, mask GSF_AREA_MASK_RELATIVE
	jz	afterRelative
	BitSet	diffs, GOBAAD_MULTIPLE_MASKS

afterRelative:

	; now go through the diff structure to handle all
	; things that are different

	push	bp
	mov	ax, offset GAAMergeTable		;cs:ax = table
	pushdw	csax
	mov	bx, cx				;ds:bx = old
	mov	cx, length GAAMergeTable		;ax = count
	lea	bp, diffs
	call	StyleSheetCallMergeRoutines
	pop	bp

EC <	call	ECLMemValidateHeap					>

	.leave
	pop	dx
	ret

MergeGrObjAreaAttr	endp

GAAMergeTable	SSMergeEntry	\
	<0, mask GOBAAD_MULTIPLE_COLORS, MergeWordAndAHalf, offset GOFAAE_base + offset GOBAAE_r>,
	<0, mask GOBAAD_MULTIPLE_BACKGROUND_COLORS, MergeWordAndAHalf, offset GOFAAE_base + offset GOBAAE_backR>,
	<0, mask GOBAAD_MULTIPLE_MASKS, MergeByte, offset GOFAAE_base + offset GOBAAE_mask>,
	<0, mask GOBAAD_MULTIPLE_PATTERNS, MergeWord, offset GOFAAE_base + offset GOBAAE_pattern>,
	<0, mask GOBAAD_MULTIPLE_DRAW_MODES, MergeByte, offset GOFAAE_base + offset GOBAAE_drawMode>,
	<0, mask GOBAAD_MULTIPLE_INFOS, MergeByte, offset GOFAAE_base + offset GOBAAE_areaInfo>

	; ds:si = target
	; es:di = result
	; ds:bx = old
	; ss:ax = diffs
	; cx = data (offset in structure)
	; dx = TextStyleFlags

;---

MergeGrObjLineAttr	proc	far
	push	dx
	clr	ax
	mov	dx, ({GrObjStylePrivateData} ss:[bp]).GSPD_flags
diffs		local	GrObjBaseLineAttrDiffs	\
			push	ax
	.enter

EC <	call	ECLMemValidateHeap					>

	; diff "target" and "old"

	push	dx, di, es
	mov	dx, ss
	lea	bx, diffs			;dx:bx = diffs

if FULL_EXECUTE_IN_PLACE
	segmov	es, cs
	mov	di, offset defaultLineAttr
	jcxz	10$
	segmov	es, ds				;es:di = old
	mov	di, cx
	call	GrObjDiffBaseLineAttrs
	jmp	20$
10$:
	push	cx
	mov	cx, size GrObjBaseLineAttrElement
	call	SysCopyToStackESDI		;es:di <- stack ptr
	call	GrObjDiffBaseLineAttrs
	call	SysRemoveFromStack
	pop	cx
20$:
else
	segmov	es, cs
	mov	di, offset defaultLineAttr
	jcxz	10$
	segmov	es, ds				;es:di = old
	mov	di, cx
10$:
	call	GrObjDiffBaseLineAttrs
endif
	pop	dx, di, es

	; if there is no old structure then don't do things relative

	tst	cx
	jnz	oldExists
	clr	dx
oldExists:

	; if the relative flag(s) is set then we must force differences in the
	; fields that are relative

	test	dx, mask GSF_LINE_COLOR_RELATIVE
	jz	checkLineMask
	BitSet	diffs, GOBLAD_MULTIPLE_COLORS

checkLineMask:
	test	dx, mask GSF_LINE_MASK_RELATIVE
	jz	checkLineWidth
	BitSet	diffs, GOBLAD_MULTIPLE_MASKS

checkLineWidth:
	test	dx, mask GSF_LINE_WIDTH_RELATIVE
	jz	afterRelative
	BitSet	diffs, GOBLAD_MULTIPLE_WIDTHS

afterRelative:

	; now go through the diff structure to handle all
	; things that are different

	push	bp
	mov	ax, offset GLAMergeTable		;cs:ax = table
	pushdw	csax
	mov	bx, cx				;ds:bx = old
	mov	cx, length GLAMergeTable		;ax = count
	lea	bp, diffs
	call	StyleSheetCallMergeRoutines
	pop	bp

EC <	call	ECLMemValidateHeap					>

	.leave
	pop	dx
	ret

MergeGrObjLineAttr	endp

GLAMergeTable	SSMergeEntry	\
	<0, mask GOBLAD_MULTIPLE_COLORS, MergeWordAndAHalf, offset GOFLAE_base + offset GOBLAE_r>,
	<0, mask GOBLAD_MULTIPLE_MASKS, MergeByte, offset GOFLAE_base + offset GOBLAE_mask>,
	<0, mask GOBLAD_MULTIPLE_WIDTHS, MergeWidth, offset GOFLAE_base + offset GOBLAE_width>,
	<0, mask GOBLAD_MULTIPLE_STYLES, MergeByte, offset GOFLAE_base + offset GOBLAE_style>,
	<0, mask GOBLAD_ARROWHEAD_ON_START or \
		mask GOBLAD_ARROWHEAD_ON_END or \
		mask GOBLAD_ARROWHEAD_FILLED or \
		mask GOBLAD_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES, \
	MergeByte, offset GOFLAE_base + offset GOBLAE_lineInfo>,
	<0, mask GOBLAD_MULTIPLE_ARROWHEAD_ANGLES, MergeByte, offset GOFLAE_base + offset GOBLAE_arrowheadAngle>,
	<0, mask GOBLAD_MULTIPLE_ARROWHEAD_LENGTHS, MergeByte, offset GOFLAE_base + offset GOBLAE_arrowheadLength>
	
	; ds:si = target
	; es:di = result
	; ds:bx = old
	; ss:ax = diffs
	; cx = data (offset in structure)
	; dx = TextStyleFlags

;---

MergeWordAndAHalf	proc	far
	add	si, cx
	add	di, cx
	movsw
	movsb
	ret
MergeWordAndAHalf	endp

MergeWord	proc	far
	add	si, cx
	add	di, cx
	movsw
	ret
MergeWord	endp

MergeByte	proc	far
	add	si, cx
	add	di, cx
	movsb
	ret
MergeByte	endp

;---

MergeWidth	proc	far

	movwwf	axcx, ds:[si].GOFLAE_base.GOBLAE_width

	; if relative then use target - old + new

	test	dx, mask GSF_LINE_WIDTH_RELATIVE
	jz	10$
	subwwf	axcx, ds:[bx].GOFLAE_base.GOBLAE_width
	addwwf	axcx, es:[di].GOFLAE_base.GOBLAE_width
10$:
	movwwf	es:[di].GOFLAE_base.GOBLAE_width, axcx
	ret
MergeWidth	endp

;---


GrObjStyleSheetCode ends
