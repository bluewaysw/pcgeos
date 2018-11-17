COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Text
FILE:		textMethodParaAttr.asm

METHODS:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:
	This file contains method handlers for paraAttr methods

	$Id: taParaAttr.asm,v 1.1 97/04/07 11:18:48 newdeal Exp $

------------------------------------------------------------------------------@

TextAttributes segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextSetSelectedTab -- MSG_VIS_TEXT_SET_SELECTED_TAB
						for VisTextClass

DESCRIPTION:	Set the selected tab

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx - selected tab

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 8/92		Initial version

------------------------------------------------------------------------------@
VisTextSetSelectedTab	proc	far	; MSG_VIS_TEXT_SET_SELECTED_TAB
	mov	dx, cx

	mov	ax, ATTR_VIS_TEXT_SELECTED_TAB
	call	ObjVarFindData
	jnc	addNew
	cmp	dx, ds:[bx]
	jz	done
common:
	mov	ds:[bx], dx
	mov	ax, mask VTNF_PARA_ATTR
	call	TA_SendNotification
done:
	ret

addNew:
	mov	cx, size word
	call	ObjVarAddData
	jmp	common

VisTextSetSelectedTab	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextSetParaAttrByDefault --
		    MSG_VIS_TEXT_SET_PARA_ATTR_BY_DEFAULT for VisTextClass

DESCRIPTION:	Set the entire paraAttr structure for the selected area to a
		default value.  If the object does not have multiple paraAttrs,
		set the paraAttr for the entire object.

PASS:
	*ds:si - instance data (VisTextInstance)
	ss:bp - VisTextSetParaAttrByDefaultParams

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

SetParaAttrFrame	struct
    SPAF_range	VisTextRange
    SPAF_paraAttr	VisTextMaxParaAttr
SetParaAttrFrame	ends

VisTextSetParaAttrByDefault	proc	far
				; MSG_VIS_TEXT_SET_PARA_ATTR_BY_DEFAULT
	class	VisTextClass

	push	bp
	mov	ax, ss:[bp].VTSPABDP_paraAttr

	; allocate a temporary structure

	sub	sp, size SetParaAttrFrame
	segmov	es, ss, cx		;stack segment is also in cx
	mov	di, sp			;es:di = dest

	push	si, ds
	mov	ds, cx
	mov	si, bp			;ds:si = source
	mov	cx, (size VisTextRange)/2
	rep movsw
	pop	si, ds

	; get default into structure, set up frame

	lea	bp, ss:[di-(size VisTextRange)].SPAF_paraAttr
	call	TextMapDefaultParaAttr
	sub	bp, offset SPAF_paraAttr

	call	SetParaAttrCommon

	add	sp, size SetParaAttrFrame
	pop	bp
	ret

VisTextSetParaAttrByDefault	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextSetParaAttrByToken --
		    MSG_VIS_TEXT_SET_PARA_ATTR_BY_TOKEN for VisTextClass

DESCRIPTION:	Set the entire paraAttr structure for the selected area to a
		given token.

PASS:
	*ds:si - instance data (VisTextInstance)
	ss:bp - VisTextSetParaAttrByTokenParams

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
VisTextSetParaAttrByToken	proc	far
				; MSG_VIS_TEXT_SET_PARA_ATTR_BY_TOKEN
	class	VisTextClass

	; unhilite and get the range of the selected area

	call	UnHiliteAndFixupParaAttrRange
	push	bx						;save vm file

	mov	ax, offset FormattingString
	call	TU_StartChainIfUndoable

	mov	ax, ss:[bp].VTSPABTP_paraAttr
	mov	bx, offset VTI_paraAttrRuns
	clr	cx
EC <	call	ECCheckRun						>
	call	ModifyRun
EC <	call	ECCheckRun						>
	call	UpdateLastRunPositionByRunOffset

	call	TU_EndChainIfUndoable

	; reflect the change

	pop	bx
	call	ReflectChangeUpdateGeneric
	ret

VisTextSetParaAttrByToken	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextSetParaAttr -- MSG_VIS_TEXT_SET_PARA_ATTR for VisTextClass

DESCRIPTION:	Set the entire paraAttr structure for the selected area.  If the
		object does not have multiple paraAttrs, set the paraAttr for the
		entire object.

PASS:
	*ds:si - instance data (VisTextInstance)
	ss:bp - VisTextSetParaAttrParams structure

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	John	11/90		Fixed to handle paragraphs across page
				boundaries.

------------------------------------------------------------------------------@

VisTextSetParaAttr		proc	far	; MSG_VIS_TEXT_SET_PARA_ATTR
	class	VisTextClass

if ERROR_CHECK
	;
	; Validate that the para attr is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	movdw	bxsi, ss:[bp].VTSPAP_paraAttr				>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	; copy charAttr onto the stack

	push	bp
	sub	sp, size SetParaAttrFrame
	segmov	es, ss
	mov	di, sp

	push	si, ds
	segmov	ds, ss
	mov	si, bp
	mov	cx, (size VisTextRange) / 2
	rep movsw				;copy range
	lds	si, ss:[bp].VTSPAP_paraAttr
	mov	cx, (size VisTextMaxParaAttr) / 2
	rep movsw
	pop	si, ds
	mov	bp, sp

	call	SetParaAttrCommon

	add	sp, size SetParaAttrFrame
	pop	bp
	ret

VisTextSetParaAttr	endp

;---

SetParaAttrCommon	proc	far
	class	VisTextClass

	; unhilite and get the range of the selected area to change

	mov	bx, mask VTRC_PARAGRAPH_CHANGE
	call	UnHiliteAndFixupParaAttrRange
	push	bx					;save vm file

EC <	add	bp, offset SPAF_paraAttr				>
EC <	call	ECCheckParaAttr						>
EC <	sub	bp, offset SPAF_paraAttr				>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_PARA_ATTRS
	jnz	multiple

	; Single charAttr -- set it

	add	bp, offset SPAF_paraAttr
	call	SetSingleParaAttr
	sub	bp, offset SPAF_paraAttr
	jmp	done

	; Multiple paraAttrs -- add the paraAttrs

multiple:
	mov	bx, offset VTI_paraAttrRuns
	call	SetCharAttrOrParaAttrMultiple

	; reflect the change

done:

	; expand the range to include everything that needs to be invalidated

	mov	bx, mask VTRC_PARAGRAPH_CHANGE \
			or mask VTRC_PARA_ATTR_BORDER_CHANGE
	call	TA_GetTextRange

	pop	bx
	call	ReflectChangeUpdateGeneric
	ret

SetParaAttrCommon	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextGetParaAttr -- MSG_VIS_TEXT_GET_PARA_ATTR for VisTextClass

DESCRIPTION:	Return the paraAttr structure for the selected area.

PASS:
	*ds:si - instance data (VisTextInstance)

	dx - size VisTextGetAttrParams (if called remotely)
	ss:bp - VisTextGetAttrParams structure

RETURN:
	ax - paraAttr token (CA_NULL_ELEMENT if multiple)
	buffer - filled

DESTROYED:
	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

VTGPA_Frame	struct
    VTGPA_element	VisTextMaxParaAttr <>

	; the following fields are pushed on the stack

    VTGPA_passedFrame	word		;frame passed
VTGPA_Frame	ends

VisTextGetParaAttr	proc	far	; MSG_VIS_TEXT_GET_PARA_ATTR
	class	VisTextClass

if ERROR_CHECK
	;
	; Validate that the char attr is *not* in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	movdw	bxsi, ss:[bp].VTGAP_attr				>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	push	si, ds

	; zero out return values

	test	ss:[bp].VTGAP_flags, mask VTGAF_MERGE_WITH_PASSED
	jnz	skipZero
	les	di, ss:[bp].VTGAP_return
	clr	ax
	stosw
	stosw
	stosw
	stosw
skipZero:

	; allocate stack space and save vars

	movdw	dxax, ss:[bp].VTR_start
	mov	di, bp

	push	bp				;passed frame
	sub	sp, (size VTGPA_Frame)-2
	mov	bp, sp

	; if we are to merge with the passed attributes then copy the passed
	; structure in

	test	ss:[di].VTGAP_flags, mask VTGAF_MERGE_WITH_PASSED
	jz	skipCopy
	push	si, di, ds, es
	lds	si, ss:[di].VTGAP_attr		;ds:si = source
	segmov	es, ss
	mov	di, bp				;es:di = dest
	mov	cx, (size VisTextParaAttr) / 2
	rep	movsw
	pop	si, di, ds, es
skipCopy:

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VTI_storageFlags, mask VTSF_MULTIPLE_PARA_ATTRS
	jnz	multiple

	; one paraAttr -- get it

	; ss:bp = VTGPA_Frame, ss:di = VisTextGetAttrParams

	call	GetSingleParaAttr
	test	ss:[di].VTGAP_flags, mask VTGAF_MERGE_WITH_PASSED
	jnz	oneRun
	jmp	done
multiple:

	; ss:bp = VTGCA_Frame, ss:di = VisTextGetAttrParams

	xchg	bp, di				;ss:di = VTGPA_Frame
						;ss:bp = VisTextGetAttrParams

	call	FixupParaAttrRange
	clr	bx
	call	TA_GetTextRange

	; first fill the buffer with the first run

	movdw	dxax, ss:[bp].VTR_start
	cmpdw	dxax, ss:[bp].VTR_end		;if area selected then
	xchg	bp, di				;ss:bp = VTGPA_Frame
						;ss:di = VisTextGetAttrParams
	push	si, ds
	mov	bx, offset VTI_paraAttrRuns
	call	GetRunForPosition		;returns cx = token
	call	GetElement

	; if (selectionEnd >= run.end) {
	;	selection in one run, return token
	; } else {
	;	selection in more than one run, return 0
	; }

	push	bx
	call	RunArrayNext		;dxax = next run position
	pop	bx
	call	RunArrayUnlock
	pop	si, ds

	mov	di, ss:[bp].VTGPA_passedFrame
	cmpdw	dxax, ss:[di].VTR_end
	mov_tr	ax, bx				;ax = token
	jae	oneRun

	; use enumeration function to scan all runs

	mov	dx, offset GetParaAttrCallback
	xchg	di, bp				;ss:di = frame, ss:bp = range
	mov	bx, offset VTI_paraAttrRuns
	call	EnumRunsInRange
	xchg	di, bp				;ss:bp = frame, ss:di = frame
	mov	ax, CA_NULL_ELEMENT		;return multiple tokens
	jmp	done

oneRun:
	test	ss:[di].VTGAP_flags, mask VTGAF_MERGE_WITH_PASSED
	jz	done

	; diff this single structure with the passed structure

	push	di
	movdw	dxbx, ss:[di].VTGAP_return	;dx:bx=VisTextParaAttrDiffs
	lds	si, ss:[di].VTGAP_attr		;dssi = passed
	segmov	es, ss
	mov	di, bp				;es:di = single attr
	call	DiffParaAttr
	pop	di

done:

	; fill the destination buffer

	segmov	ds, ss				;ds:si = source
	mov	si, bp
	les	di, ss:[di].VTGAP_attr		;es:di = dest
	CalcParaAttrSize	<ds:[si]>, cx
	shr	cx
	rep	movsw

	; recover local space

	add	sp, (size VTGPA_Frame)-2
	pop	bp

	pop	si, ds

	ret

VisTextGetParaAttr	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetParaAttrCallback

DESCRIPTION:	Mark the differences between the given paraAttr and the base
		paraAttr

CALLED BY:	INTERNAL -- Callback from EnumRunsInRange
				(from VisTextGetParaAttr)

PASS:
	ss:bp - element from run
	ss:di - VTGPA_Frame

RETURN:

DESTROYED:
	ax, bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
GetParaAttrCallback	proc	near

	; load parameters and call the diff routine

	segmov	es, ss				;es:di = element #2
	segmov	ds, es
	mov	si, bp				;ds:si = element #1

	mov	bx, ss:[di].VTGPA_passedFrame	;ss:bx=VisTextGetCharAttrParams
	mov	dx, ss:[bx].VTGAP_return.segment
	mov	bx, ss:[bx].VTGAP_return.offset  ;dx:bx=VisTextCharAttrDiffs

	call	DiffParaAttr
	
	ret

GetParaAttrCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DiffParaAttr

DESCRIPTION:	Compute the difference between two paragraph attribute
		structures

CALLED BY:	INTERNAL

PASS:
	ds:si - para attr #1
	es:di - para attr #2
	dx:bx - VisTextParaAttrDiffs to "or" results into

RETURN:
	dx:bx - structure updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91		Initial version

------------------------------------------------------------------------------@
DiffParaAttr	proc	far	uses	ax, cx
	.enter

	clr	cx

	; compare names

	mov	ax, ds:[si].VTPA_meta.SSEH_style
	cmp	ax, es:[di].VTPA_meta.SSEH_style
	jz	sameName
	ornf	cx, mask VTPAF_MULTIPLE_STYLES
sameName:

	; compare left margins

	mov	ax, ds:[si].VTPA_leftMargin
	cmp	ax, es:[di].VTPA_leftMargin
	jz	sameLeftMargin
	ornf	cx, mask VTPAF_MULTIPLE_LEFT_MARGINS
sameLeftMargin:

	; compare right margins

	mov	ax, ds:[si].VTPA_rightMargin
	cmp	ax, es:[di].VTPA_rightMargin
	jz	sameRightMargin
	ornf	cx, mask VTPAF_MULTIPLE_RIGHT_MARGINS
sameRightMargin:

	; compare para margins

	mov	ax,ds:[si].VTPA_paraMargin
	cmp	ax,es:[di].VTPA_paraMargin
	jz	sameParaMargin
	ornf	cx, mask VTPAF_MULTIPLE_PARA_MARGINS
sameParaMargin:

	; compare line spacings

	mov	ax, {word} ds:[si].VTPA_lineSpacing
	cmp	ax, {word} es:[di].VTPA_lineSpacing
	jz	sameLineSpacing
	ornf	cx, mask VTPAF_MULTIPLE_LINE_SPACINGS
sameLineSpacing:

	; compare extra leadings

	mov	ax, ds:[si].VTPA_leading
	cmp	ax, es:[di].VTPA_leading
	jz	sameLeading
	ornf	cx, mask VTPAF_MULTIPLE_LEADINGS
sameLeading:

	; compare default tabs

	mov	ax, ds:[si].VTPA_defaultTabs
	cmp	ax, es:[di].VTPA_defaultTabs
	jz	sameDefaultTabs
	ornf	cx, mask VTPAF_MULTIPLE_DEFAULT_TABS
sameDefaultTabs:

	; compare top spacing

	mov	ax, ds:[si].VTPA_spaceOnTop
	cmp	ax, es:[di].VTPA_spaceOnTop
	jz	sameTopSpacing
	ornf	cx, mask VTPAF_MULTIPLE_TOP_SPACING
sameTopSpacing:

	; compare bottom spacing

	mov	ax, ds:[si].VTPA_spaceOnBottom
	cmp	ax, es:[di].VTPA_spaceOnBottom
	jz	sameBottomSpacing
	ornf	cx, mask VTPAF_MULTIPLE_BOTTOM_SPACING
sameBottomSpacing:

	; compare background colors

	mov	ax, ds:[si].VTPA_bgColor.low
	cmp	ax, es:[di].VTPA_bgColor.low
	jnz	diffColor
	mov	ax, ds:[si].VTPA_bgColor.high
	cmp	ax, es:[di].VTPA_bgColor.high
	jz	sameColor
diffColor:
	ornf	cx, mask VTPAF_MULTIPLE_BG_COLORS
sameColor:

	; compare gray screens

	mov	al, ds:[si].VTPA_bgGrayScreen
	cmp	al, es:[di].VTPA_bgGrayScreen
	jz	sameGrayScreen
	ornf	cx, mask VTPAF_MULTIPLE_BG_GRAY_SCREENS
sameGrayScreen:

	; compare hatches

	mov	ax, {word} ds:[si].VTPA_bgPattern
	cmp	ax, {word} es:[di].VTPA_bgPattern
	jz	sameBGPattern
	ornf	cx,mask VTPAF_MULTIPLE_BG_PATTERNS
sameBGPattern:

	; compare tab lists

	push	cx, dx, si, di
	clr	cx
	mov	cl, ds:[si].VTPA_numberOfTabs
	cmp	cl, es:[di].VTPA_numberOfTabs
	jnz	differentTabs
	tst	cl
	jz	sameTabs		;carry clear

	mov	ax, (size Tab) / 2
	mul	cx			;ax = list size in words
	mov_tr	cx, ax
	add	si, offset VTPA_tabList
	add	di, offset VTPA_tabList
	repe cmpsw
	clc
	jz	sameTabs

differentTabs:
	stc
sameTabs:
	pop	cx, dx, si, di
	jnc	40$
	ornf	cx, mask VTPAF_MULTIPLE_TAB_LISTS
40$:

	; compare prepend characters

	mov	ax, {word} ds:[si].VTPA_prependChars
	cmp	ax, {word} es:[di].VTPA_prependChars
	jnz	diffPrependChars
	mov	ax, {word} ds:[si].VTPA_prependChars+2
	cmp	ax, {word} es:[di].VTPA_prependChars+2
	jz	samePrependChars
diffPrependChars:
	ornf	cx, mask VTPAF_MULTIPLE_PREPEND_CHARS
samePrependChars:

	; compare paragraph numbers

	mov	ax, ds:[si].VTPA_startingParaNumber
	cmp	ax, es:[di].VTPA_startingParaNumber
	jz	sameParaNumbers
	ornf	cx, mask VTPAF_MULTIPLE_STARTING_PARA_NUMBERS
sameParaNumbers:

	; compare next styles

	mov	ax, ds:[si].VTPA_nextStyle
	cmp	ax, es:[di].VTPA_nextStyle
	jz	sameNextStyles
	ornf	cx, mask VTPAF_MULTIPLE_NEXT_STYLES
sameNextStyles:

	push	ds
	mov	ds, dx
	or	ds:[bx].VTPAD_diffs, cx
	pop	ds

;----------

	clr	cx

	; compare border sides

	push	bx
	mov	ax, ds:[si].VTPA_borderFlags
	xor	ax, es:[di].VTPA_borderFlags
	mov	bx, ax
	and	bx, (mask VTPBF_LEFT or mask VTPBF_TOP or mask VTPBF_RIGHT \
			or mask VTPBF_BOTTOM)
	or	cx, bx
	pop	bx

	; compare border anchors

	test	ax, mask VTPBF_ANCHOR
	jz	sameBorderAnchors
	ornf	cx, mask VTPABF_MULTIPLE_BORDER_ANCHORS
sameBorderAnchors:

	; compare border double flags

	test	ax, mask VTPBF_DOUBLE
	jz	sameBorderDoubles
	ornf	cx, mask VTPABF_MULTIPLE_BORDER_DOUBLES
sameBorderDoubles:

	; compare border inner flags

	test	ax, mask VTPBF_DRAW_INNER_LINES
	jz	sameBorderInnerFlags
	ornf	cx, mask VTPABF_MULTIPLE_BORDER_DRAW_INNERS
sameBorderInnerFlags:

	; compare border widths

	mov	al, ds:[si].VTPA_borderWidth
	cmp	al, es:[di].VTPA_borderWidth
	jz	sameBorderWidths
	ornf	cx, mask VTPABF_MULTIPLE_BORDER_WIDTHS
sameBorderWidths:

	; compare border spacing

	mov	al, ds:[si].VTPA_borderSpacing
	cmp	al, es:[di].VTPA_borderSpacing
	jz	sameBorderSpacings
	ornf	cx, mask VTPABF_MULTIPLE_BORDER_SPACINGS
sameBorderSpacings:

	; compare border shadows

	mov	al, ds:[si].VTPA_borderShadow
	cmp	al, es:[di].VTPA_borderShadow
	jz	sameBorderShadows
	ornf	cx, mask VTPABF_MULTIPLE_BORDER_SHADOWS
sameBorderShadows:

	; compare border colors

	mov	ax, ds:[si].VTPA_borderColor.low
	cmp	ax, es:[di].VTPA_borderColor.low
	jnz	diffBorderColor
	mov	ax, ds:[si].VTPA_borderColor.high
	cmp	ax, es:[di].VTPA_borderColor.high
	jz	sameBorderColor
diffBorderColor:
	ornf	cx, mask VTPABF_MULTIPLE_BORDER_COLORS
sameBorderColor:

	; compare gray screens

	mov	al, ds:[si].VTPA_borderGrayScreen
	cmp	al, es:[di].VTPA_borderGrayScreen
	jz	sameBorderGrayScreen
	ornf	cx, mask VTPABF_MULTIPLE_BORDER_GRAY_SCREENS
sameBorderGrayScreen:

	; compare hatches

	mov	ax, {word} ds:[si].VTPA_borderPattern
	cmp	ax, {word} es:[di].VTPA_borderPattern
	jz	sameBorderPattern
	ornf	cx,mask VTPABF_MULTIPLE_BORDER_PATTERNS
sameBorderPattern:

	mov	ax, ds:[si].VTPA_hyphenationInfo
	xor	ax, es:[di].VTPA_hyphenationInfo

	push	ds
	mov	ds, dx
	or	ds:[bx].VTPAD_borderDiffs, cx
	or	ds:[bx].VTPAD_hyphenationInfo, ax
	pop	ds

;----------

	mov	ax, ds:[si].VTPA_dropCapInfo
	xor	ax, es:[di].VTPA_dropCapInfo
	mov	cx, ds:[si].VTPA_attributes
	xor	cx, es:[di].VTPA_attributes

	push	ds
	mov	ds, dx
	or	ds:[bx].VTPAD_dropCapInfo, ax
	or	ds:[bx].VTPAD_attributes, cx
	pop	ds

;----------

	clr	cx


	; compare next styles

	mov	al, ds:[si].VTPA_language
	cmp	al, es:[di].VTPA_language
	jz	sameLanguage
	ornf	cx, mask VTPAF2_MULTIPLE_LANGUAGES
sameLanguage:

if CHAR_JUSTIFICATION
	;
	; compare full justification types
	;
	mov	al, ds:[si].VTPA_miscMode
	cmp	al, es:[di].VTPA_miscMode
	jz	sameJustType
	ornf	cx, mask VTPAF2_MULTIPLE_JUSTIFICATION_TYPES
sameJustType:
endif

	mov	al, ds:[si].VTPA_keepInfo
	xor	al, es:[di].VTPA_keepInfo

	push	ds
	mov	ds, dx
	or	ds:[bx].VTPAD_diffs2, cx
	or	ds:[bx].VTPAD_keepInfo, al
	pop	ds

	.leave
	ret

DiffParaAttr	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextParaAttrAdd -- MSG_VIS_TEXT_ADD_PARA_ATTR for VisTextClass

DESCRIPTION:	Add a given paraAttr to the paraAttr array and initialize its
		reference count to one.

	*** Note: Calling this method on a text object that does not have
	***	  multiple paraAttrs will result in a fatal error.

PASS:
	*ds:si - instance data (VisTextInstance)

	dx - size of paraAttr passed (if called remotely)
	ss:bp - VisTextParaAttr

RETURN:
	ax - paraAttr token

DESTROYED:
	dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

VisTextParaAttrAdd		proc	far	; MSG_VIS_TEXT_ADD_PARA_ATTR
	class	VisTextClass

	mov	ax, offset AddElement
	FALL_THRU	AddRemoveParaAttrCommon

VisTextParaAttrAdd	endp

;---

AddRemoveParaAttrCommon	proc	far
	class	VisTextClass
	mov	bx, offset VTI_paraAttrRuns
	call	LockAndCall			;ax = token
	ret
AddRemoveParaAttrCommon	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextParaAttrRemove -- MSG_VIS_TEXT_REMOVE_PARA_ATTR for VisTextClass

DESCRIPTION:	Remove a given paraAttr from the paraAttr array.

	*** Note: Calling this method on a text object that does not have
	***	  multiple paraAttrs will result in a fatal error.

PASS:
	*ds:si - instance data (VisTextInstance)

	dx - size of paraAttr passed (if called remotely)
	cx - token to remove

RETURN:
	none

DESTROYED:
	dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

VisTextParaAttrRemove	proc	far	; MSG_VIS_TEXT_REMOVE_PARA_ATTR
	class	VisTextClass

	mov	ax, offset RemoveElement
	GOTO	AddRemoveParaAttrCommon

VisTextParaAttrRemove	endp

;-----------------------------------------------------------------------------
;		Utility routines below here
;-----------------------------------------------------------------------------

COMMENT @----------------------------------------------------------------------

FUNCTION:	ParaAttrChangeCommon

DESCRIPTION:	Do a change for a charAttr routine

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance data (VisTextInstance)
	ss:bp - VisTextRange
	ax, dx - callback data
	di - offset of callback
	bx - VisTextRangeContext for invalidation

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
ParaAttrChangeCommon	proc	far
	clr	bx
	GOTO	DoParaAttrChangeCommon
ParaAttrChangeCommon	endp

;---

ParaAttrBorderChangeCommon	proc	far
	mov	bx, mask VTRC_PARAGRAPH_CHANGE or mask VTRC_PARA_ATTR_BORDER_CHANGE
	FALL_THRU	DoParaAttrChangeCommon
ParaAttrBorderChangeCommon	endp

;---

DoParaAttrChangeCommon	proc	far
	class	VisTextClass
	push	bx

	call	UnHiliteAndFixupParaAttrRange
	push	bx				;save vm file

	mov	cx, cs				;segment of callback

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_PARA_ATTRS
	pop	di
	jnz	multiple

	call	DoSingleParaAttrChange
	clr	ax
	clrdw	ss:[bp].VTR_start, ax
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END
	jmp	done

	; Multiple paraAttrs -- add the paraAttr

multiple:

	; modify the paraAttr run

	push	ax
	mov	ax, offset FormattingString
	call	TU_StartChainIfUndoable
	pop	ax

	mov	bx, offset VTI_paraAttrRuns
EC <	call	ECCheckRun						>
	call	ModifyRun
EC <	call	ECCheckRun						>
	call	UpdateLastRunPositionByRunOffset

	call	TU_EndChainIfUndoable
done:
	pop	ax				;recover vm file

	pop	bx				;recover context
	tst	bx
	jz	noInvalidateContext
	call	TA_GetTextRange
noInvalidateContext:

	; since we are changing a paragraph related thing we *must* have
	; a non-zero range to recalculate (unless there is no text al all)

	push	ax
	movdw	dxax, ss:[bp].VTR_start
	cmpdw	dxax, ss:[bp].VTR_end
	jnz	noRangeProblem
	tstdw	dxax
	jz	noRangeProblem
	decdw	dxax
	movdw	ss:[bp].VTR_start, dxax
noRangeProblem:

	pop	bx				;pass vm file
	GOTO	ReflectChangeUpdateGeneric

DoParaAttrChangeCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetSingleParaAttr

DESCRIPTION:	Set the paraAttr for a single paraAttr text object

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisTextInstance
	ss:bp - VisTextParaAttr

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
SetSingleParaAttr	proc	near			uses	ax, cx, si, di
	class	VisTextClass
	.enter

EC <	call	ECCheckParaAttr						>

	mov	di, ds:[si]			;ds:si = instance
	add	di, ds:[di].Vis_offset

	; check for a default

	call	TextFindDefaultParaAttr
	jnc	noDefault

	; its a default -- remove the chunk

	test	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_PARA_ATTR
	xchg	ax,ds:[di].VTI_paraAttrRuns
	jnz	done
	ornf	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_PARA_ATTR
	call	ObjFreeChunk
	jmp	done

	; not a default paraAttr -- must make a chunk

noDefault:
	CalcParaAttrSize	<ss:[bp]>, cx
	test	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_PARA_ATTR
	mov	ax, ds:[di].VTI_paraAttrRuns
	jz	chunkExists

	; no chunk exists -- create one

	mov	ax, si
	call	ObjGetFlags
	and	al, mask OCF_IGNORE_DIRTY

	or	al, mask OCF_DIRTY
	call	LMemAlloc
	mov	di, ds:[si]			;ds:si = instance
	add	di, ds:[di].Vis_offset
	and	ds:[di].VTI_storageFlags, not mask VTSF_DEFAULT_PARA_ATTR
	mov	ds:[di].VTI_paraAttrRuns, ax
	jmp	common

	; if the chunk exists realloc it to the correct size (since the size
	; might have changed)

chunkExists:
	call	LMemReAlloc

	; *ds:ax = chunk to set

common:
	mov_tr	di, ax
	push	ds, es
	segmov	es, ds				;es:di = dest
	mov	di, ds:[di]
	segmov	ds, ss				;ds:si = source
	mov	si, bp

	rep	movsb
	pop	ds, es

done:
	.leave
	ret

SetSingleParaAttr	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DoSingleParaAttrChange

DESCRIPTION:	Make a change to a text object with a single paraAttr

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisTextObject
	ss:bp - parameter structure
	cx:di - callback routine to make change
	ax, dx - data passed to callback

		Callback routine:
		PASS:
			ss:bp - element
			ss:di - parameter structure
			ax, dx - modData
		RETURN:
			ss:bp - updated
		DESTROYED:
			ax, bx, cx, dx, si, di, bp, es

RETURN:
	none

DESTROYED:
	ax, bc, cx, dx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

DSRC_frame	struct
    DSRC_paraAttr		VisTextMaxParaAttr <>
    DSRC_callback	dword
DSRC_frame	ends

DoSingleParaAttrChange	proc	near		uses	bp
	.enter

	; save calllback address in frame

	push	cx
	push	di
	mov	di, bp				;ss:di = passed frame

	; allocate charAttr structure no stack

	sub	sp, (size DSRC_frame)-4
	mov	bp, sp

	; get current paraAttr

	call	GetSingleParaAttr

	; make the change

EC <	tst	cx							>
EC <	ERROR_Z	CANNOT_SUBSTITUTE_IN_DO_SINGLE_PARA_ATTR_CHANGE		>
	push	si, bp
	call	ss:[bp].DSRC_callback
	pop	si, bp

	; get the new paraAttr

	call	SetSingleParaAttr

	; recover stack space

	add	sp, size DSRC_frame

	.leave
	ret

DoSingleParaAttrChange	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetSingleParaAttr

DESCRIPTION:	Get the paraAttr for a single paraAttr text object

CALLED BY:	CreateParaAttrRuns, DoSingleParaAttrChange, ParaAttrRunGetParaAttr,
		VisTextGetParaAttr

PASS:
	*ds:si - VisTextInstance
	ss:bp - buffer for VisTextParaAttr

RETURN:
	buffer - filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

TextFixed	segment resource

GetSingleParaAttr	proc	far
	class	VisTextClass
	uses	ax, cx, di, si, es
	.enter

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags,mask VTSF_DEFAULT_PARA_ATTR
	mov	si, ds:[di].VTI_paraAttrRuns
	jnz	default

	; not default paraAttr -- load from chunk

	mov	si, ds:[si]			;ds:si = VisTextParaAttr

	segmov	es, ss				;es:di = dest
	mov	di, bp
	ChunkSizePtr	ds, si, cx
	rep	movsb

	jmp	done

	; default paraAttr -- use routine

default:
	mov_tr	ax, si
	call	TextMapDefaultParaAttr

done:

EC <	call	ECCheckParaAttr						>

	.leave
	ret
GetSingleParaAttr	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextMapDefaultParaAttr

DESCRIPTION:	Load a defualt paraAttr

CALLED BY:	INTERNAL

PASS:
	ax - VisTextDefaultParaAttr

	ss:bp - buffer for VisTextParaAttr

RETURN:
	buffer - set

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
TextMapDefaultParaAttr	proc	far
	uses	ax, bx, cx, di, si, es
	.enter
	mov_tr	bx, ax				;bx = default

	; zero out the entire paraAttr

	mov	cx, (size VisTextParaAttr)/2
	segmov	es, ss
	mov	di, bp
	clr	ax
	rep	stosw

	mov	ss:[bp].VTPA_meta.SSEH_style, CA_NULL_ELEMENT
	mov	ss:[bp].VTPA_lineSpacing.BBF_int, 1
	mov	ss:[bp].VTPA_language, SL_ENGLISH
	mov	ss:[bp].VTPA_startingParaNumber,
				VIS_TEXT_DEFAULT_STARTING_NUMBER

	; set the left margin

	mov	ax, bx
	and	ax, mask VTDPA_LEFT_MARGIN
	mov	cl, offset VTDPA_LEFT_MARGIN
	shr	ax, cl
	mov	cx, (PIXELS_PER_INCH/2)*8
	mul	cx
	mov	ss:[bp].VTPA_leftMargin, ax

	; set the right margin

	mov	ax, bx
	and	ax, mask VTDPA_RIGHT_MARGIN

	mov	cl, offset VTDPA_RIGHT_MARGIN
	shr	ax, cl
	mov	cx, (PIXELS_PER_INCH/2)*8
	mul	cx
	mov	ss:[bp].VTPA_rightMargin, ax

	; set the para margin

	mov	ax, bx
	and	ax, mask VTDPA_PARA_MARGIN
	mov	cl, offset VTDPA_PARA_MARGIN
	shr	ax, cl
	mov	cx, (PIXELS_PER_INCH/2)*8
	mul	cx
	mov	ss:[bp].VTPA_paraMargin, ax

	; set the default tabs

	mov	ax, bx
	and	ax, mask VTDPA_DEFAULT_TABS
	mov	cl, (offset VTDPA_DEFAULT_TABS) - 1
	shr	ax, cl
	mov_tr	si, ax
	mov	ax, cs:[si].defaultDefaultTabs
	mov	ss:[bp].VTPA_defaultTabs, ax

	; set the justification

	and	bx, mask VTPAA_JUSTIFICATION
	mov	ss:[bp].VTPA_attributes, bx

	; set the bg color

	mov	ss:[bp].VTPA_bgColor.low, C_WHITE
	mov	ss:[bp].VTPA_bgGrayScreen, SDM_0

	; set the border color

	mov	ss:[bp].VTPA_borderColor.CQ_redOrIndex, C_BLACK
	mov	ss:[bp].VTPA_borderGrayScreen, SDM_100

	mov	ss:[bp].VTPA_startingParaNumber,
					VIS_TEXT_DEFAULT_STARTING_NUMBER
	mov	ss:[bp].VTPA_borderWidth, 1*8
	mov	ss:[bp].VTPA_borderSpacing, 2*8
	mov	ss:[bp].VTPA_borderShadow, 1*8
	mov	ss:[bp].VTPA_hyphenationInfo, VisTextHyphenationInfo <,,,>
	mov	ss:[bp].VTPA_dropCapInfo, VisTextDropCapInfo <,,>
	mov	ss:[bp].VTPA_nextStyle, CA_NULL_ELEMENT

EC <	call	ECCheckParaAttr						>

	.leave
	ret
TextMapDefaultParaAttr	endp

defaultDefaultTabs	word	\
	0,
	(PIXELS_PER_INCH / 2) * 8,
	PIXELS_PER_INCH * 8,
	227

TextFixed	ends

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextFindDefaultParaAttr

DESCRIPTION:	Given an paraAttr structure, determine if it is one of the
		default paraAttrs

CALLED BY:	INTERNAL

PASS:
	ss:bp - VisTextParaAttr

RETURN:
	carry - set if paraAttr is one of the default paraAttrs
	ax - VisTextDefaultParaAttr

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
TextFindDefaultParaAttr	proc	far		uses	bx, cx, dx
	.enter

EC <	call	ECCheckParaAttr						>

	; test many things that must be 0

	mov	ax, {word} ss:[bp].VTPA_spaceOnTop
	or	ax, {word} ss:[bp].VTPA_spaceOnBottom
	or	al, ss:[bp].VTPA_numberOfTabs
	or	ax, ss:[bp].VTPA_borderFlags
	or	ax, ss:[bp].VTPA_leading
	or	ax, {word} ss:[bp].VTPA_prependChars
	or	ax, {word} ss:[bp].VTPA_prependChars+2
	or	al, ss:[bp].VTPA_keepInfo
	tst	ax
	jz	10$
toNoDefault:
	jmp	noDefault
10$:

	cmp	ss:[bp].VTPA_startingParaNumber,
					VIS_TEXT_DEFAULT_STARTING_NUMBER
	jnz	toNoDefault
	cmp	ss:[bp].VTPA_borderWidth, 1*8
	jnz	toNoDefault
	cmp	ss:[bp].VTPA_borderSpacing, 2*8
	jnz	toNoDefault
	cmp	ss:[bp].VTPA_borderShadow, 1*8
	jnz	toNoDefault
	cmp	ss:[bp].VTPA_hyphenationInfo, VisTextHyphenationInfo <,,,>
	jnz	toNoDefault
	cmp	ss:[bp].VTPA_dropCapInfo, VisTextDropCapInfo <,,>
	jnz	toNoDefault
	cmp	ss:[bp].VTPA_nextStyle, CA_NULL_ELEMENT
	jnz	toNoDefault

	cmp	ss:[bp].VTPA_bgGrayScreen, SDM_0
	jne	toNoDefault
	cmp	ss:[bp].VTPA_borderGrayScreen, SDM_100
	jne	toNoDefault

	; test the line spacing

	cmp	{word} ss:[bp].VTPA_lineSpacing,1 * 256
	jne	noDefault

	; test the bg color

	cmp	ss:[bp].VTPA_bgColor.low, C_WHITE
	jne	noDefault

	; test the border color

	cmp	ss:[bp].VTPA_borderColor.low, C_BLACK
	jne	noDefault

	; deal with the default tabs

	mov	ax, ss:[bp].VTPA_defaultTabs
	mov	bx, VTDDT_NONE shl offset VTDPA_DEFAULT_TABS
	tst	ax
	jz	gotDefaultTabs
	mov	bx, VTDDT_HALF_INCH shl offset VTDPA_DEFAULT_TABS
	cmp	ax, (PIXELS_PER_INCH / 2) * 8
	jz	gotDefaultTabs
	mov	bx, VTDDT_INCH shl offset VTDPA_DEFAULT_TABS
	cmp	ax, PIXELS_PER_INCH * 8
	jz	gotDefaultTabs
	mov	bx, VTDDT_CENTIMETER shl offset VTDPA_DEFAULT_TABS
	cmp	ax, 227
	jnz	noDefault
gotDefaultTabs:

	; test the left margin

	mov	ax, ss:[bp].VTPA_leftMargin
	clr	dx
	mov	cx, (PIXELS_PER_INCH/2)*8
	div	cx
	tst	dx
	jnz	noDefault
	mov	cl, offset VTDPA_LEFT_MARGIN
	shl	ax, cl
	or	bx, ax

	; test the right margin

	mov	ax, ss:[bp].VTPA_rightMargin	;dx already 0
	cmp	ax, VIS_TEXT_MAX_PARA_WIDTH*8	;test for special case
	jz	afterRightMargin
	mov	cx, (PIXELS_PER_INCH/2)*8
	div	cx
	tst	dx
	jnz	noDefault
	mov	cl, offset VTDPA_RIGHT_MARGIN
	shl	ax, cl
	or	bx, ax
afterRightMargin:

	; test the para margin

	mov	ax, ss:[bp].VTPA_paraMargin
	mov	cx, (PIXELS_PER_INCH/2)*8
	div	cx
	tst	dx
	jnz	noDefault
	mov	cl, offset VTDPA_PARA_MARGIN
	shl	ax, cl
	or	bx, ax

	; test the attributes

	mov	ax, ss:[bp].VTPA_attributes
	test	ax, not mask VTPAA_JUSTIFICATION
	jnz	noDefault
	or	ax, bx

	; its a default

	stc
done:
	.leave
	ret

	; its not a default

noDefault:
	clc
	jmp	done

TextFindDefaultParaAttr	endp

TextAttributes	ends

;============================================================================
;============================================================================
;		Error checking code below
;============================================================================

TextEC	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckParaAttr

DESCRIPTION:	Make sure that a VisTextParaAttr structure is legal

CALLED BY:	INTERNAL

PASS:
	ss:bp - pointer to paraAttr on stack.

RETURN:
	none

DESTROYED:
	none -- FLAGS PRESERVED

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

ECCheckParaAttr	proc	far		uses ax, bx, cx, di, es
	.enter
	pushf

	; reference count -- must be <= 10000

	tst	ss:[bp].VTPA_meta.SSEH_meta.REH_refCount.WAAH_high
	ERROR_NZ	VIS_TEXT_CHAR_ATTR_HAS_REF_COUNT_OVER_10000
	cmp	ss:[bp].VTPA_meta.SSEH_meta.REH_refCount.WAAH_low, 10000
	ERROR_A	VIS_TEXT_PARA_ATTR_HAS_REF_COUNT_OVER_10000

	; margins must be < VIS_TEXT_MAX_PARA_ATTR_WIDTH
	; (right-left) must be >= VIS_TEXT_MIN_LEFT_TO_RIGHT_MARGIN_DISTANCE
	; (right-para) must be >= VIS_TEXT_MIN_LEFT_TO_RIGHT_MARGIN_DISTANCE

	cmp	ss:[bp].VTPA_leftMargin, VIS_TEXT_MAX_PARA_WIDTH*8
	ERROR_A	VIS_TEXT_ILLEGAL_LEFT_MARGIN
	cmp	ss:[bp].VTPA_paraMargin, VIS_TEXT_MAX_PARA_WIDTH*8
	ERROR_A	VIS_TEXT_ILLEGAL_PARA_MARGIN
	cmp	ss:[bp].VTPA_rightMargin, VIS_TEXT_MAX_PARA_WIDTH*8
	ERROR_A	VIS_TEXT_ILLEGAL_RIGHT_MARGIN

	; line spacing must be <= VIS_TEXT_MAX_LINE_SPACING

	cmp	{word} ss:[bp].VTPA_lineSpacing, \
					VIS_TEXT_MIN_NON_ZERO_LINE_SPACING
	ERROR_B	VIS_TEXT_ILLEGAL_LINE_SPACING
	cmp	{word} ss:[bp].VTPA_lineSpacing, VIS_TEXT_MAX_LINE_SPACING
	ERROR_A	VIS_TEXT_ILLEGAL_LINE_SPACING

	; leading must be < VIS_TEXT_MAX_LEADING

	cmp	{word} ss:[bp].VTPA_leading, 0
	jz	20$
	cmp	{word} ss:[bp].VTPA_leading, VIS_TEXT_MIN_NON_ZERO_LEADING
	ERROR_B	VIS_TEXT_ILLEGAL_LEADING
20$:
	; Value is ThirteenIntThreeFrac, so multiply by 8
		
	cmp	{word} ss:[bp].VTPA_leading, VIS_TEXT_MAX_LEADING*8
	ERROR_A	VIS_TEXT_ILLEGAL_LEADING

	; no checking for space on top/bottom

	; check the attributes

	test	ss:[bp].VTPA_attributes, not VisTextParaAttrAttributes
	ERROR_NZ	VIS_TEXT_ILLEGAL_PARA_ATTR_ATTRIBUTE_BITS_SET

	; check border flags

	test	ss:[bp].VTPA_borderFlags, not VisTextParaBorderFlags
	ERROR_NZ	VIS_TEXT_ILLEGAL_BORDER_BITS_SET

	; check language

	cmp	ss:[bp].VTPA_language, StandardLanguage
	ERROR_AE VIS_TEXT_ILLEGAL_LANGUAGE

	; compare tabs

	clr	cx
	mov	cl, ss:[bp].VTPA_numberOfTabs
	cmp	cx, VIS_TEXT_MAX_TABS
	ERROR_A	VIS_TEXT_PARA_ATTR_HAS_TOO_MANY_TABS

	jcxz	noTabs

	push	bp
	add	bp, size VisTextParaAttr
	clr	ax

	; ss:bp = tab, ax = minimum tab position (last tab)

tabLoop:
	cmp	ss:[bp].T_position, VIS_TEXT_MAX_PARA_WIDTH*8
	ERROR_A	VIS_TEXT_ILLEGAL_TAB_POSITION
	add	bp, size Tab
	loop	tabLoop

	pop	bp
noTabs:

	; reserved -- must be 0

	segmov	es, ss
	lea	di, ss:[bp].VTPA_reserved
	mov	cx, size VTPA_reserved
	clr	ax
	repe scasb
	ERROR_NZ	VIS_TEXT_PARA_ATTR_RESERVED_MUST_BE_0

	popf
	.leave
	ret

ECCheckParaAttr	endp

endif

TextEC ends
