COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextAttr
FILE:		taAttr.asm

METHODS:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:
	This file contains the attribute setting messages and their callbacks

	$Id: taAttr.asm,v 1.1 97/04/07 11:18:44 newdeal Exp $

------------------------------------------------------------------------------@

TextAttributes segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		Many messages for setting attributes

DESCRIPTION:	Set the attribute for the selected area.  If the object does
		not have multiple charAttrs, set the attribute for the entire
		object.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/91		Initial version

------------------------------------------------------------------------------@

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_FONT_ID

PARAMETERS:	ss:bp - VisTextSetFontIDParams

---------------@

VisTextSetFontID		proc	far	; MSG_VIS_TEXT_SET_FONT_ID
	mov	ax, offset VTCA_fontID
	mov	di, offset SetWordCallback
	GOTO	CharAttrChangeCommon
VisTextSetFontID	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_POINT_SIZE

PARAMETERS:	ss:bp - VisTextSetPointSizeParams

---------------@

VisTextSetPointSize		proc	far	; MSG_VIS_TEXT_SET_POINT_SIZE
	mov	ax, offset VTCA_pointSize
	mov	di, offset SetWBFixedCallback
	GOTO	CharAttrChangeCommon
VisTextSetPointSize	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_FONT_WEIGHT

PARAMETERS:	ss:bp - VisTextSetFontWeightParams

---------------@

VisTextSetFontWeight		proc	far	; MSG_VIS_TEXT_SET_FONT_WEIGHT
	mov	ax, offset VTCA_fontWeight
	mov	di, offset SetByteCallback
	GOTO	CharAttrChangeCommon
VisTextSetFontWeight	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_FONT_WIDTH

PARAMETERS:	ss:bp - VisTextSetFontWidthParams

---------------@

VisTextSetFontWidth		proc	far	; MSG_VIS_TEXT_SET_FONT_WIDTH
	mov	ax, offset VTCA_fontWidth
	mov	di, offset SetByteCallback
	GOTO	CharAttrChangeCommon
VisTextSetFontWidth	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_SMALLER_POINT_SIZE

PARAMETERS:	ss:bp - VisTextSetSmallerPointSizeParams

---------------@

VisTextSetSmallerPointSize	proc	far
					; MSG_VIS_TEXT_SET_SMALLER_POINT_SIZE

EC <	cmp	ss:[bp].VTSSPSP_minimumSize, MIN_POINT_SIZE		>
EC <	ERROR_B	VIS_TEXT_MAKE_POINT_SIZE_SMALLER_ILLEGAL_MINIMUM_VALUE	>

	mov	di, offset SetPointSizeSmallerCallback
	GOTO	CharAttrChangeCommon
VisTextSetSmallerPointSize	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_LARGER_POINT_SIZE

PARAMETERS:	ss:bp - VisTextSetLargerPointSizeParams

---------------@

VisTextSetLargerPointSize	proc	far
					; MSG_VIS_TEXT_SET_LARGER_POINT_SIZE

EC <	cmp	ss:[bp].VTSLPSP_maximumSize, MAX_POINT_SIZE		>
EC <	ERROR_A	VIS_TEXT_MAKE_POINT_SIZE_LARGER_ILLEGAL_MAXIMUM_VALUE	>

	mov	di, offset SetPointSizeLargerCallback
	GOTO	CharAttrChangeCommon
VisTextSetLargerPointSize	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_TEXT_STYLE

PARAMETERS:	VisTextSetTextStyleParams

---------------@

VisTextSetTextStyle	proc	far	; MSG_VIS_TEXT_SET_TEXT_STYLE
	mov	di, offset SetTextStyleCallback
	GOTO	CharAttrChangeCommon
VisTextSetTextStyle	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_COLOR

PARAMETERS:	VisTextSetColorParams

---------------@

VisTextSetColor		proc	far	; MSG_VIS_TEXT_SET_COLOR
	mov	ax, offset VTCA_color
	mov	di, offset SetColorCallback
	GOTO	CharAttrChangeCommon
VisTextSetColor	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_GRAY_SCREEN

PARAMETERS:	VisTextSetGrayScreenParams

---------------@

VisTextSetGrayScreen	proc	far	; MSG_VIS_TEXT_SET_GRAY_SCREEN

EC <	cmp	ss:[bp].VTSGSP_grayScreen, SystemDrawMask			>
EC <	ERROR_AE	VIS_TEXT_ILLEGAL_GRAY_SCREEN			>

	mov	ax, offset VTCA_grayScreen
	mov	di, offset SetByteCallback
	GOTO	CharAttrChangeCommon
VisTextSetGrayScreen	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_PATTERN

PARAMETERS:	VisTextSetPatternParams

---------------@

VisTextSetPattern	proc	far	; MSG_VIS_TEXT_SET_PATTERN

	mov	ax, offset VTCA_pattern
	mov	di, offset SetWordCallback
	GOTO	CharAttrChangeCommon
VisTextSetPattern	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_CHAR_BG_COLOR

PARAMETERS:	VisTextSetColorParams

---------------@

VisTextSetCharBGColor		proc	far	; MSG_VIS_TEXT_SET_CHAR_BG_COLOR
	mov	ax, offset VTCA_bgColor
	mov	di, offset SetColorCallback
	GOTO	CharAttrChangeCommon
VisTextSetCharBGColor	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_CHAR_BG_GRAY_SCREEN

PARAMETERS:	VisTextSetGrayScreenParams

---------------@

VisTextSetCharBGGrayScreen	proc	far
				; MSG_VIS_TEXT_SET_CHAR_BG_GRAY_SCREEN

EC <	cmp	ss:[bp].VTSGSP_grayScreen, SystemDrawMask			>
EC <	ERROR_AE	VIS_TEXT_ILLEGAL_GRAY_SCREEN			>

	mov	di, offset SetCharBGGrayCallback
	GOTO	CharAttrChangeCommon
VisTextSetCharBGGrayScreen	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_CHAR_BG_PATTERN

PARAMETERS:	VisTextSetPatternParams

---------------@

VisTextSetCharBGPattern	proc	far	; MSG_VIS_TEXT_SET_CHAR_BG_PATTERN

	mov	ax, offset VTCA_bgPattern
	mov	di, offset SetWordCallback
	GOTO	CharAttrChangeCommon
VisTextSetCharBGPattern	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_TRACK_KERNING

PARAMETERS:	VisTextSetTrackKerningParams

---------------@

VisTextSetTrackKerning	proc	far	; MSG_VIS_TEXT_SET_TRACK_KERNING
	mov	ax, offset VTCA_trackKerning
	mov	di, offset SetWordCallback
	GOTO	CharAttrChangeCommon
VisTextSetTrackKerning	endp

;=========================== PARA_ATTR STUFF ==================================

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_BORDER_BITS

PARAMETERS:	ss:bp - VisTextSetBorderBitsParams

---------------@

VisTextSetBorderBits	proc	far	; MSG_VIS_TEXT_SET_BORDER_BITS
	mov	ax, offset VTPA_borderFlags
	mov	di, offset SetWordBitsCallback
	GOTO	ParaAttrBorderChangeCommon
VisTextSetBorderBits	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_BORDER_WIDTH

PARAMETERS:	ss:bp - VisTextSetBorderWidthParams

---------------@

VisTextSetBorderWidth	proc	far	; MSG_VIS_TEXT_SET_BORDER_WIDTH
	mov	ax, offset VTPA_borderWidth
	mov	di, offset SetByteCallback
	GOTO	ParaAttrBorderChangeCommon
VisTextSetBorderWidth	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_BORDER_SPACING

PARAMETERS:	ss:bp - VisTextSetBorderSpacingParams

---------------@

VisTextSetBorderSpacing	proc	far	; MSG_VIS_TEXT_SET_BORDER_SPACING
	mov	ax, offset VTPA_borderSpacing
	mov	di, offset SetByteCallback
	GOTO	ParaAttrBorderChangeCommon
VisTextSetBorderSpacing	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_BORDER_SHADOW

PARAMETERS:	ss:bp - VisTextSetBorderShadowParams

---------------@

VisTextSetBorderShadow	proc	far	; MSG_VIS_TEXT_SET_BORDER_SHADOW
	mov	ax, offset VTPA_borderShadow
	mov	di, offset SetByteCallback
	GOTO	ParaAttrBorderChangeCommon
VisTextSetBorderShadow	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_BORDER_COLOR

PARAMETERS:	VisTextSetColorParams

---------------@

VisTextSetBorderColor	proc	far	; MSG_VIS_TEXT_SET_BORDER_COLOR
	mov	ax, offset VTPA_borderColor
	mov	di, offset SetColorCallback
	GOTO	ParaAttrBorderChangeCommon
VisTextSetBorderColor	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_BORDER_GRAY_SCREEN

PARAMETERS:	VisTextSetGrayScreenParams

---------------@

VisTextSetBorderGrayScreen	proc	far
					; MSG_VIS_TEXT_SET_BORDER_GRAY_SCREEN

EC <	cmp	ss:[bp].VTSGSP_grayScreen, SystemDrawMask			>
EC <	ERROR_AE	VIS_TEXT_ILLEGAL_GRAY_SCREEN			>

	mov	ax, offset VTPA_borderGrayScreen
	mov	di, offset SetByteCallback
	GOTO	ParaAttrBorderChangeCommon
VisTextSetBorderGrayScreen	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_BORDER_PATTERN

PARAMETERS:	VisTextSetPatternParams

---------------@

VisTextSetBorderPattern	proc	far	; MSG_VIS_TEXT_SET_BORDER_PATTERN

	mov	ax, offset VTPA_borderPattern
	mov	di, offset SetWordCallback
	GOTO	ParaAttrChangeCommon
VisTextSetBorderPattern	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_PARA_ATTRIBUTES

PARAMETERS:	ss:bp - VisTextSetParaAttrAttributesParams

---------------@

VisTextSetParaAttrAttributes	proc	far
					; MSG_VIS_TEXT_SET_PARA_ATTRIBUTES
	mov	ax, offset VTPA_attributes
	mov	di, offset SetWordBitsCallback
	GOTO	ParaAttrChangeCommon
VisTextSetParaAttrAttributes	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_LINE_SPACING

PARAMETERS:	ss:bp - VisTextSetLineSpacingParams

---------------@

VisTextSetLineSpacing	proc	far	; MSG_VIS_TEXT_SET_LINE_SPACING
	mov	ax, offset VTPA_lineSpacing
	mov	di, offset SetWordCallback
	GOTO	ParaAttrBorderChangeCommon

VisTextSetLineSpacing	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_DEFAULT_TABS

PARAMETERS:	ss:bp - VisTextSetDefaultTabsParams

---------------@

VisTextSetDefaultTabs	proc	far	; MSG_VIS_TEXT_SET_DEFAULT_TABS
	mov	ax, offset VTPA_defaultTabs
	mov	di, offset SetWordCallback
	GOTO	ParaAttrChangeCommon

VisTextSetDefaultTabs	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_LEFT_MARGIN

PARAMETERS:	ss:bp - VisTextSetMarginParams

---------------@

VisTextSetLeftMargin	proc	far	; MSG_VIS_TEXT_SET_LEFT_MARGIN
	mov	ax, offset VTPA_leftMargin
	mov	di, offset SetWordCallback
	GOTO	ParaAttrChangeCommon

VisTextSetLeftMargin	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_RIGHT_MARGIN

PARAMETERS:	ss:bp - VisTextSetMarginParams

---------------@

VisTextSetRightMargin	proc	far	; MSG_VIS_TEXT_SET_RIGHT_MARGIN
	mov	ax, offset VTPA_rightMargin
	mov	di, offset SetWordCallback
	GOTO	ParaAttrChangeCommon

VisTextSetRightMargin	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_PARA_MARGIN

PARAMETERS:	ss:bp - VisTextSetMarginParams

---------------@

VisTextSetParaMargin	proc	far	; MSG_VIS_TEXT_SET_PARA_MARGIN
	mov	ax, offset VTPA_paraMargin
	mov	di, offset SetWordCallback
	GOTO	ParaAttrChangeCommon

VisTextSetParaMargin	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_LEFT_AND_PARA_MARGIN

PARAMETERS:	ss:bp - VisTextSetMarginParams

---------------@

VisTextSetLeftAndParaMargin	proc	far
				; MSG_VIS_TEXT_SET_LEFT_AND_PARA_MARGIN
	mov	di, offset SetLeftAndParaMarginCallback
	GOTO	ParaAttrChangeCommon

VisTextSetLeftAndParaMargin	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_SPACE_ON_TOP

PARAMETERS:	ss:bp - VisTextSetSpaceOnTBParams

---------------@

VisTextSetSpaceOnTop	proc	far	; MSG_VIS_TEXT_SET_SPACE_ON_TOP
	mov	ax, offset VTPA_spaceOnTop
	mov	di, offset SetWordCallback
	GOTO	ParaAttrChangeCommon
VisTextSetSpaceOnTop	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_SPACE_ON_BOTTOM

PARAMETERS:	ss:bp - VisTextSetSpaceOnTBParams

---------------@

VisTextSetSpaceOnBottom	proc	far	; MSG_VIS_TEXT_SET_SPACE_ON_BOTTOM
	mov	ax, offset VTPA_spaceOnBottom
	mov	di, offset SetWordCallback
	GOTO	ParaAttrChangeCommon
VisTextSetSpaceOnBottom	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_LEADING

PARAMETERS:	ss:bp - VisTextSetLeadingParams

---------------@

VisTextSetLeading	proc	far	; MSG_VIS_TEXT_SET_LEADING
	mov	ax, offset VTPA_leading
	mov	di, offset SetWordCallback
	GOTO	ParaAttrBorderChangeCommon
VisTextSetLeading	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_PARA_BG_COLOR

PARAMETERS:	VisTextSetColorParams

---------------@

VisTextSetParaBGColor	proc	far	; MSG_VIS_TEXT_SET_PARA_BG_COLOR
	mov	ax, offset VTPA_bgColor
	mov	di, offset SetColorCallback
	GOTO	ParaAttrChangeCommon
VisTextSetParaBGColor	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_PARA_BG_GRAY_SCREEN

PARAMETERS:	VisTextSetGrayScreenParams

---------------@

VisTextSetParaBGGrayScreen	proc	far
				; MSG_VIS_TEXT_SET_PARA_BG_GRAY_SCREEN

EC <	cmp	ss:[bp].VTSGSP_grayScreen, SystemDrawMask			>
EC <	ERROR_AE	VIS_TEXT_ILLEGAL_GRAY_SCREEN			>

	mov	ax, offset VTPA_bgGrayScreen
	mov	di, offset SetByteCallback
	GOTO	ParaAttrChangeCommon
VisTextSetParaBGGrayScreen	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_PARA_BG_PATTERN

PARAMETERS:	VisTextSetPatternParams

---------------@

VisTextSetParaBGPattern	proc	far	; MSG_VIS_TEXT_SET_PARA_BG_PATTERN

	mov	ax, offset VTPA_bgPattern
	mov	di, offset SetWordCallback
	GOTO	ParaAttrChangeCommon
VisTextSetParaBGPattern	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_TAB

PARAMETERS:	VisTextSetTabParams

---------------@

VisTextSetTab	proc	far	; MSG_VIS_TEXT_SET_TAB
	mov	ax, ss:[bp].VTSTP_tab.T_position
	call	SelectTab
	mov	di, offset SetTabCallback
	GOTO	ParaAttrChangeCommon
VisTextSetTab	endp

SelectTab	proc	near
	push	ax
	mov	ax, ATTR_VIS_TEXT_SELECTED_TAB
	mov	cx, size word
	call	ObjVarAddData
	pop	ds:[bx]
	ret
SelectTab	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_CLEAR_TAB

PARAMETERS:	VisTextClearTabTabParams

---------------@

VisTextClearTab	proc	far	; MSG_VIS_TEXT_CLEAR_TAB
	mov	di, offset ClearTabCallback
	GOTO	ParaAttrChangeCommon
VisTextClearTab	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_MOVE_TAB

PARAMETERS:	VisTextMoveTabParams

---------------@

VisTextMoveTab	proc	far	; MSG_VIS_TEXT_MOVE_TAB
	mov	ax, ss:[bp].VTMTP_destPosition
	call	SelectTab
	mov	di, offset MoveTabCallback
	GOTO	ParaAttrChangeCommon
VisTextMoveTab	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_CLEAR_ALL_TABS

PARAMETERS:	VisTextClearAllTabsParams

---------------@

VisTextClearAllTabs	proc	far	; MSG_VIS_TEXT_CLEAR_ALL_TABS
	mov	di, offset ClearAllTabsCallback
	GOTO	ParaAttrChangeCommon
VisTextClearAllTabs	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_PREPEND_CHARS

PARAMETERS:	VisTextSetPrependCharsParams

---------------@

VisTextSetPrependChars	proc	far	; MSG_VIS_TEXT_SET_PREPEND_CHARS
	mov	ax, offset VTPA_prependChars
	mov	di, offset SetDWordCallback
	GOTO	ParaAttrChangeCommon
VisTextSetPrependChars	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_HYPHENATION_PARAMS

PARAMETERS:	VisTextSetHyphenationPParams

---------------@

VisTextSetHyphenationParams	proc	far
				; MSG_VIS_TEXT_SET_HYPHENATION_PARAMS
	mov	ax, offset VTPA_hyphenationInfo
	mov	di, offset SetWordBitsCallback
	GOTO	ParaAttrBorderChangeCommon
VisTextSetHyphenationParams	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_DROP_CAP_PARAMS

PARAMETERS:	VisTextSetDropCapPParams

---------------@

VisTextSetDropCapParams	proc	far
				; MSG_VIS_TEXT_SET_DROP_CAP_PARAMS
	mov	ax, offset VTPA_dropCapInfo
	mov	di, offset SetWordBitsCallback
	GOTO	ParaAttrChangeCommon
VisTextSetDropCapParams	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_KEEP_PARAMS

PARAMETERS:	VisTextSetKeepPParams

---------------@

VisTextSetKeepParams	proc	far
				; MSG_VIS_TEXT_SET_HYPHENATION_PARAMS
	mov	ax, offset VTPA_keepInfo
	mov	di, offset SetWordBitsCallback
	GOTO	ParaAttrBorderChangeCommon
VisTextSetKeepParams	endp

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_PARAGRAPH_NUMBER

PARAMETERS:	VisTextSetParagraphNumberParams

---------------@

VisTextSetParagraphNumber	proc	far
					; MSG_VIS_TEXT_SET_PARAGRAPH_NUMBER
	mov	di, offset SetParagraphNumberCallback
	GOTO	ParaAttrBorderChangeCommon
VisTextSetParagraphNumber	endp

if CHAR_JUSTIFICATION

COMMENT @------

MESSAGE:	MSG_VIS_TEXT_SET_TEXT_MISC_MODE

PARAMETERS:	VisTextSetFullJustificationTypeParams

---------------@

VisTextSetTextMiscMode	proc	far
				; MSG_VIS_TEXT_SET_TEXT_MISC_MODE
	mov	ax, offset VTPA_miscMode
	mov	di, offset SetByteCallback
	GOTO	ParaAttrChangeCommon
VisTextSetTextMiscMode	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	Various callbacks

DESCRIPTION:	Apply a change to a structure

CALLED BY:	ModifyRun (as a callback)

PASS:
	ss:bp - structure to act on
	ss:di - structure passed to ModifyRun
	ax - offset in structure to act on

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

COMMENT @------

FUNCTION:	SetByteCallback

DESCRIPTION:	Apply a byte change to a structure

---------------@

SetByteFrame	struct
    SBF_range	VisTextRange
    SBF_value	byte
SetByteFrame	ends

SetByteCallback	proc	far
	add	bp, ax				;ss:[bp] is dest
	mov	al, ss:[di].SBF_value
	mov	ss:[bp], al
	ret

SetByteCallback	endp

COMMENT @------

FUNCTION:	SetCharBGGrayCallback

DESCRIPTION:	Apply a character background color change

---------------@

SetCharBGGrayCallback	proc	far
	mov	al, ss:[di].SBF_value
	mov	ss:[bp].VTCA_bgGrayScreen, al
	andnf	ss:[bp].VTCA_extendedStyles, not mask VTES_BACKGROUND_COLOR
	cmp	al, SDM_0
	jz	done
	ornf	ss:[bp].VTCA_extendedStyles, mask VTES_BACKGROUND_COLOR
done:
	ret

SetCharBGGrayCallback	endp

COMMENT @------

FUNCTION:	SetWordCallback

DESCRIPTION:	Apply a word change to a structure

---------------@

SetWordFrame	struct
    SWF_range	VisTextRange
    SWF_value	word
SetWordFrame	ends

SetWordCallback	proc	far
	add	bp, ax				;ss:[bp] is dest
	mov	ax, ss:[di].SWF_value
	mov	ss:[bp], ax
	ret

SetWordCallback	endp

COMMENT @------

FUNCTION:	SetDWordCallback

DESCRIPTION:	Apply a dword change to a structure

---------------@

SetDWordFrame	struct
    SDWF_range	VisTextRange
    SDWF_value	dword
SetDWordFrame	ends

SetDWordCallback	proc	far
	add	bp, ax				;ss:[bp] is dest
	mov	ax, ss:[di].SDWF_value.low
	mov	ss:[bp].low, ax
	mov	ax, ss:[di].SDWF_value.high
	mov	ss:[bp].high, ax
	ret

SetDWordCallback	endp

COMMENT @------

FUNCTION:	SetWBFixedCallback

DESCRIPTION:	Apply a word change to a structure

---------------@

SetWBFixedFrame	struct
    SWBFF_range	VisTextRange
    SWBFF_pad	byte
    SWBFF_value	WBFixed
SetWBFixedFrame	ends

SetWBFixedCallback	proc	far
	add	bp, ax				;ss:[bp] is dest
	mov	ax, ss:[di].SWBFF_value.WBF_int
	mov	ss:[bp].WBF_int, ax
	mov	al,ss:[di].SWBFF_value.WBF_frac
	mov	ss:[bp].WBF_frac, al
	ret

SetWBFixedCallback	endp

COMMENT @------

FUNCTION:	SetPointSizeSmallerCallback

DESCRIPTION:	Set the point size smaller

---------------@

SetPointSizeSmallerCallback	proc	far

	; get current point size

	mov	ax, ss:[bp].VTCA_pointSize.WBF_int

	; if more than 216 then make 72 points smaller

	cmp	ax, 216
	jbe	notHuge
	sub	ax, 72
	cmp	ax, 216
	jae	common
	mov	ax, 216
	jmp	common
notHuge:

	; if minimum point or less then do nothing

	cmp	ax, ss:[di].VTSSPSP_minimumSize
	jbe	done

	; scan table to find next smaller size

	segmov	es, cs
	mov	di, offset PointSizeTable	;es:di = table

smallerLoop:
	scasb
	ja	smallerLoop

	; if exact match -> es:[di-2] = smaller size, es:[di] = larger sz
	; if not exact match -> es:[di-2] = smaller size, es:[di-1] = larger sz

	clr	ax
	mov	al, es:[di-2]
common:
	mov	ss:[bp].VTCA_pointSize.WBF_int, ax

done:
	mov	ss:[bp].VTCA_pointSize.WBF_frac, 0
	ret

SetPointSizeSmallerCallback	endp

PointSizeTable	label	byte
	byte	4, 6, 8, 9, 10, 12, 14, 18, 24, 36, 54, 72
	byte	144, 180, 216

COMMENT @------

FUNCTION:	SetPointSizeLargerCallback

DESCRIPTION:	Set the point size larger

---------------@

SetPointSizeLargerCallback	proc	far

	; get current point size

	mov	ax, ss:[bp].VTCA_pointSize.WBF_int
	mov	cx, ss:[di].VTSLPSP_maximumSize

	; if too large then exit

	cmp	ax, cx
	jae	done

	; if more than or equal 216 then make 72 points larger

	cmp	ax, 216
	jb	notHuge
	add	ax, 72
	cmp	ax, cx			;if larger than max
	jbe	common			;then set max
	mov	ax, cx
	jmp	common
notHuge:

	; scan table to find next larger size

	segmov	es, cs
	mov	di, offset PointSizeTable	;es:di = table

smallerLoop:
	scasb
	ja	smallerLoop

	; if exact match -> es:[di] = larger sz
	; if not exact match -> es:[di-1] = larger sz

	mov	ah,0
	mov	al, es:[di]			;assume exact match
	jz	common
	mov	al, es:[di-1]

common:
	mov	ss:[bp].VTCA_pointSize.WBF_int, ax

done:
	mov	ss:[bp].VTCA_pointSize.WBF_frac, 0
	.leave
	ret

SetPointSizeLargerCallback	endp

COMMENT @------

FUNCTION:	SetTextStyleCallback

DESCRIPTION:	Change the text charAttr

---------------@

SetTextStyleCallback	proc	far

	mov	al, ss:[bp].VTCA_textStyles
	mov	cl, {byte} ss:[di].VTSTSP_styleBitsToClear
	mov	ch, {byte} ss:[di].VTSTSP_styleBitsToSet

	cmp	cl, ch				;if cl=ch then xor
	jnz	setAndClear
	xor	al, cl
	jmp	common
setAndClear:
	not	cl
	and	al, cl				;clear bits
	or	al, ch				;set bits
common:

	; special case: if both superscript and subscript are set the clear
	;		one of them

	mov	ah, al
	and	ah, mask TS_SUPERSCRIPT or mask TS_SUBSCRIPT
	cmp	ah, mask TS_SUPERSCRIPT or mask TS_SUBSCRIPT
	jnz	notBoth

	; if presently superscript then change to subscript and visa-versa

	test	ss:[bp].VTCA_textStyles, mask TS_SUPERSCRIPT
	jz	presentlySubscript
	andnf	al, not mask TS_SUPERSCRIPT
	jmp	notBoth
presentlySubscript:
	andnf	al, not mask TS_SUBSCRIPT

notBoth:
	mov	ss:[bp].VTCA_textStyles, al

	; handle extended charAttrs

	mov	ax, ss:[bp].VTCA_extendedStyles
	mov	bx, ss:[di].VTSTSP_extendedBitsToClear
	not	bx
	and	ax, bx
	or	ax, ss:[di].VTSTSP_extendedBitsToSet

	; special case: if both boxed and button are set the clear
	;		one of them

	mov	cx, ax
	and	cx, mask VTES_BOXED or mask VTES_BUTTON
	cmp	cx, mask VTES_BOXED or mask VTES_BUTTON
	jnz	notBothEx

	; if presently boxed then change to button and visa-versa

	test	ss:[bp].VTCA_extendedStyles, mask VTES_BOXED
	jz	presentlyButton
	andnf	ax, not mask VTES_BOXED
	jmp	notBothEx
presentlyButton:
	andnf	ax, not mask VTES_BUTTON
notBothEx:

	mov	ss:[bp].VTCA_extendedStyles, ax
	
	;
	; ax =	The extended styles. If there is no background color then
	;	we want to mark the background as unfilled.
	;
	test	ax, mask VTES_BACKGROUND_COLOR
	jnz	quit
	
	;
	; OK, no background color, mark the thing as unfilled.
	;
	mov	ss:[bp].VTCA_bgGrayScreen, SDM_0
quit:
	ret

SetTextStyleCallback	endp

COMMENT @------

FUNCTION:	SetColorCallback

DESCRIPTION:	Change the color

---------------@

SetColorFrame	struct
    SC_range	VisTextRange
    SC_color	ColorQuad
SetColorFrame	ends

SetColorCallback	proc	far
	add	bp, ax				;ss:[bp] is dest

	mov	ax, {word} ss:[di].SC_color
	mov	bx, {word} ss:[di].SC_color+2

	; if color index passed then zero unused bytes

	cmp	ah, CF_INDEX
	jnz	notIndex
	clr	bx
notIndex:

	mov	{word} ss:[bp], ax
	mov	{word} ss:[bp]+2, bx

	ret

SetColorCallback	endp

COMMENT @------

FUNCTION:	SetWordBitsCallback

DESCRIPTION:	Apply a bits change to a word in a structure

---------------@

SetWordBitsFrame	struct
    SWBF_range		VisTextRange
    SWBF_bitsToSet	word
    SWBF_bitsToClear	word
SetWordBitsFrame	ends

SetWordBitsCallback	proc	far
	add	bp, ax				;ss:[bp] is dest

	mov	ax, ss:[bp]			;ax = word to modify

	; handle bits to clear

	mov	bx, ss:[di].SWBF_bitsToClear
	not	bx
	and	ax, bx

	; handle bits to set

	or	ax, ss:[di].SWBF_bitsToSet

	mov	ss:[bp], ax
	ret

SetWordBitsCallback	endp

COMMENT @------

FUNCTION:	SetLeftAndParaMarginCallback

DESCRIPTION:	Change left and para margin

---------------@

SetLeftAndParaMarginCallback	proc	far
	mov	ax, ss:[di].SWF_value
	mov	ss:[bp].VTPA_leftMargin, ax
	mov	ss:[bp].VTPA_paraMargin, ax
	ret

SetLeftAndParaMarginCallback	endp

COMMENT @------

FUNCTION:	SetTabCallback

DESCRIPTION:	Set a tab

---------------@

SetTabCallback	proc	far

	; search for a tab at the given position

	mov	ax, ss:[di].VTSTP_tab.T_position
	call	FindTabAtPosition
	jc	tabFound

	; no tab, insert one and fall through to set it

	cmp	ss:[bp].VTPA_numberOfTabs, VIS_TEXT_MAX_TABS
	je	done				;quit if too many tabs.
	call	InsertTabAtPosition		;ss:[bp][si] = new tab

	; tab found, replace it

tabFound:
	mov	cx, (size Tab) / 2
copyLoop:
	mov	ax, {word} ss:[di].VTSTP_tab
	mov	ss:[bp][si], ax
	inc	si
	inc	si
	inc	di
	inc	di
	loop	copyLoop
done:
	ret

SetTabCallback	endp

COMMENT @------

FUNCTION:	ClearTabCallback

DESCRIPTION:	Clear a tab

---------------@

ClearTabCallback	proc	far
	mov	ax, ss:[di].VTCTP_position
	call	ClearTabAtPosition
	ret
ClearTabCallback	endp

COMMENT @------

FUNCTION:	MoveTabCallback

DESCRIPTION:	Move a tab

---------------@

MoveTabCallback	proc	far

	; first clear the tab

	mov	ax, ss:[di].VTMTP_sourcePosition
	call	ClearTabAtPosition
	jnc	done				;if no tab found then exit

	cmp	ss:[bp].VTPA_numberOfTabs, VIS_TEXT_MAX_TABS
	je	done				;quit if too many tabs.
	mov	ax, ss:[di].VTMTP_destPosition
	call	InsertTabAtPosition		;ss:[bp][si] = new tab

	mov	ss:[bp][si].T_position, ax
	mov	ss:[bp][si]+2, bx
	mov	ss:[bp][si]+4, cx
	mov	ss:[bp][si]+6, dx
done:
	ret

MoveTabCallback	endp

COMMENT @------

FUNCTION:	ClearAllTabsCallback

DESCRIPTION:	Clear all tabs

---------------@

ClearAllTabsCallback	proc	far
	mov	ss:[bp].VTPA_numberOfTabs, 0
	ret
ClearAllTabsCallback	endp

COMMENT @------

FUNCTION:	SetParagraphNumberCallback

DESCRIPTION:	Set paragraph numbering

---------------@

SetParagraphNumberCallback	proc	far
	mov	ax, ss:[di].VTSPNP_startingParaNumber
	mov	ss:[bp].VTPA_startingParaNumber, ax
	ret
SetParagraphNumberCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindTabAtPosition

DESCRIPTION:	Search a paraAttr for a tab

CALLED BY:	INTERNAL

PASS:
	ss:bp - paraAttr to search
	ax - tab position, points*8 (T_position)

RETURN:
	carry - set if tab found
	ss:[bp][si] - pointing at Tab found
	cx - number of tabs to right of tab found (including tab found)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

FindTabAtPosition	proc	near
	clr	cx
	mov	cl, ss:[bp].VTPA_numberOfTabs
	jcxz	notFound

	mov	si, VTPA_tabList
searchLoop:
	cmp	ax, ss:[bp][si].T_position
	jz	found
	add	si,size Tab
	loop	searchLoop

notFound:
	clc
	ret

found:
	stc
	ret

FindTabAtPosition	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	InsertTabAtPosition

DESCRIPTION:	Insert a tab at the given position

CALLED BY:	INTERNAL

PASS:
	ss:bp - paraAttr to search
	ax - tab position, integer (T_position)

RETURN:
	ss:[bp][si] - pointing at Tab inserted

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

InsertTabAtPosition	proc	near		uses ax, cx, dx, di, ds
	.enter

	mov	si, VTPA_tabList

	clr	cx
	mov	cl, ss:[bp].VTPA_numberOfTabs
	jcxz	insertHere

	; search for correct location in list

searchLoop:
	cmp	ax, ss:[bp][si].T_position
	jz	done				;we used to ERROR here
	jb	insertHere
	add	si, size Tab
	loop	searchLoop

	; insert tab at ss:[bp][si], must move (ax) tab structures

insertHere:
	inc	ss:[bp].VTPA_numberOfTabs

	segmov	ds, ss
	segmov	es, ss

	push	si
	add	si, bp				;ds:si = tab to move

	mov	ax, size Tab
	mul	cx				;ax = bytes to move
	mov_tr	cx, ax

	add	si, cx				;si points to end of list
	dec	si
	lea	di, [si+(size Tab)]
	std
	rep	movsb
	cld
	pop	si
done:
	.leave
	ret

InsertTabAtPosition	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ClearTabAtPosition

DESCRIPTION:	Clear a tab at the given position

CALLED BY:	INTERNAL

PASS:
	ss:bp - paraAttr to search
	ax - tab position, integer (T_position)

RETURN:
	carry - set if a tab cleared
	bx, cx, dx - data for tab cleared

DESTROYED:
	ax, cx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
	CheckHack <(size Tab) eq 8>

ClearTabAtPosition	proc	far		uses di, ds
	.enter

	call	FindTabAtPosition		;ss:[bp][si] = tab
						;cx = # tabs left
	jnc	done
	mov	bx, {word} ss:[bp][si]+2
	push	{word} ss:[bp][si]+4		;return in cx
	push	{word} ss:[bp][si]+6		;return in dx

	; found tab, remove it

	dec	ss:[bp].VTPA_numberOfTabs

	segmov	ds, ss
	segmov	es, ss

	add	si, bp				;ds:[si] = tab

	mov	ax, size Tab
	mul	cx				;ax = bytes to move
	mov_tr	cx, ax
	mov	di, si
	add	si, size Tab
	rep	movsb

	pop	dx
	pop	cx
	stc
done:
	.leave
	ret

ClearTabAtPosition	endp

TextAttributes ends
