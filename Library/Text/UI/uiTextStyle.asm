COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiTextStyleControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	TextStyleControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement TextStyleControlClass

	$Id: uiTextStyle.asm,v 1.1 97/04/07 11:17:42 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	TextStyleControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextStyleControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for TextStyleControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of TextStyleControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
TextStyleControlGetInfo	method dynamic	TextStyleControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset TSC_dupInfo
	FALL_THRU	CopyDupInfoCommon

TextStyleControlGetInfo	endm

CopyDupInfoCommon	proc	far
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
CopyDupInfoCommon	endp

TSC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	TSC_IniFileKey,			; GCBI_initFileKey
	TSC_gcnList,			; GCBI_gcnList
	length TSC_gcnList,		; GCBI_gcnCount
	TSC_notifyTypeList,		; GCBI_notificationList
	length TSC_notifyTypeList,	; GCBI_notificationCount
	TSCName,			; GCBI_controllerName

	handle TextStyleControlUI,	; GCBI_dupBlock
	TSC_childList,			; GCBI_childList
	length TSC_childList,		; GCBI_childCount
	TSC_featuresList,		; GCBI_featuresList
	length TSC_featuresList,	; GCBI_featuresCount
	TSC_DEFAULT_FEATURES,		; GCBI_features

	handle TextStyleControlToolboxUI,	; GCBI_toolBlock
	TSC_toolList,			; GCBI_toolList
	length TSC_toolList,		; GCBI_toolCount
	TSC_toolFeaturesList,		; GCBI_toolFeaturesList
	length TSC_toolFeaturesList,	; GCBI_toolFeaturesCount
	TSC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

TSC_IniFileKey	char	"textStyle", 0

TSC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_STYLE_CHANGE>

TSC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_STYLE_CHANGE>

;---

TSC_childList	GenControlChildInfo	\
	<offset PlainTextList, mask TSCF_PLAIN, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TextStyleList, mask TSCF_BOLD or mask TSCF_ITALIC or
				mask TSCF_UNDERLINE or mask TSCF_STRIKE_THRU or
				mask TSCF_SUBSCRIPT or mask TSCF_SUPERSCRIPT, 0>,
	<offset ExtendedStylesGroup, mask TSCF_BOXED or mask TSCF_BUTTON or
					mask TSCF_INDEX or
					mask TSCF_ALL_CAP or
					mask TSCF_SMALL_CAP, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TSC_featuresList	GenControlFeaturesInfo	\
	<offset AllCapEntry, AllCapName, 0>,
	<offset SmallCapEntry, SmallCapName, 0>,
	<offset IndexEntry, IndexName, 0>,
	<offset ButtonEntry, ButtonName, 0>,
	<offset BoxedEntry, BoxedName, 0>,
	<offset SuperscriptEntry, SuperscriptName, 0>,
	<offset SubscriptEntry, SubscriptName, 0>,
	<offset StrikeThruEntry, StrikeThruName, 0>,
	<offset UnderlineEntry, UnderlineName, 0>,
	<offset ItalicEntry, ItalicName, 0>,
	<offset BoldEntry, BoldName, 0>,
	<offset PlainTextList, PlainTextName, 0>

;---

TSC_toolList	GenControlChildInfo	\
	<offset PlainTextToolList, mask TSCTF_PLAIN,
						mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TextStyleToolList, mask TSCTF_BOLD or mask TSCTF_ITALIC or
			mask TSCTF_UNDERLINE or mask TSCTF_STRIKE_THRU or
			mask TSCTF_SUBSCRIPT or mask TSCTF_SUPERSCRIPT, 0>,
	<offset ExtendedStylesToolList, mask TSCTF_BOXED or mask TSCTF_BUTTON
					or mask TSCTF_INDEX
					or mask TSCTF_ALL_CAP
					or mask TSCTF_SMALL_CAP, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TSC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset AllCapToolEntry, AllCapName, 0>,
	<offset SmallCapToolEntry, SmallCapName, 0>,
	<offset IndexToolEntry, IndexName, 0>,
	<offset ButtonToolEntry, ButtonName, 0>,
	<offset BoxedToolEntry, BoxedName, 0>,
	<offset SuperscriptToolEntry, SuperscriptName, 0>,
	<offset SubscriptToolEntry, SubscriptName, 0>,
	<offset StrikeThruToolEntry, StrikeThruName, 0>,
	<offset UnderlineToolEntry, UnderlineName, 0>,
	<offset ItalicToolEntry, ItalicName, 0>,
	<offset BoldToolEntry, BoldName, 0>,
	<offset PlainTextToolList, PlainTextName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextStyleControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for TextStyleControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of TextStyleControlClass

	ax - The message

	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91		Initial version

------------------------------------------------------------------------------@
TextStyleControlUpdateUI	method dynamic TextStyleControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	cmp	ss:[bp].GCUUIP_changeType, GWNT_TEXT_CHAR_ATTR_CHANGE
	jz	textNotify
	mov	cl, ds:NTSC_styles
	mov	dl, ds:NTSC_indeterminates
	clr	si
	clr	di
	jmp	common
textNotify:
	mov	cl, ds:VTNCAC_charAttr.VTCA_textStyles
	mov	dl, ds:VTNCAC_charAttrDiffs.VTCAD_textStyles
	mov	si, ds:VTNCAC_charAttr.VTCA_extendedStyles
	mov	di, ds:VTNCAC_charAttrDiffs.VTCAD_extendedStyles
common:
	clr	ch
	clr	dh
	call	MemUnlock
	pop	ds

	push	si, di

	; set text style list

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask TSCF_BOLD or mask TSCF_ITALIC or mask TSCF_UNDERLINE \
			or mask TSCF_STRIKE_THRU or mask TSCF_SUBSCRIPT \
			or mask TSCF_SUPERSCRIPT
	jz	noStyles
	mov	si, offset TextStyleList
	call	SendListSetViaData
noStyles:

	; set the plain text list

	pop	si, di				;recover extended stuff
	push	si, di

	push	cx, dx

	; Consider all bits BUT background color when considering extended bits.
	; Also, let's do this better, where you set indeterminate non-zero
	; based on the extendedStyles, not or the selected item identifier
	; of PlainTextList with the extendedStyles values, though both seem
	; to yield the same result.  4/18/94 cbh

;	or	cx, si				;plain is indeterminate if

	and	si, not mask VTES_BACKGROUND_COLOR
	and	di, not mask VTES_BACKGROUND_COLOR
	or	dx, si				;plain is indeterminate if
	or	dx, di				;any extended styles set
	test	ax, mask TSCF_PLAIN
	jz	noPlain
	mov	si, offset PlainTextList
	call	SendListSetExcl
noPlain:

	; set the plain text tool list

	mov	ax, ss:[bp].GCUUIP_toolboxFeatures
	mov	bx, ss:[bp].GCUUIP_toolBlock
	test	ax, mask TSCTF_PLAIN
	jz	noPlainTool
	mov	si, offset PlainTextToolList
	call	SendListSetExcl
noPlainTool:
	pop	cx, dx

	; set text style tool

	test	ax, mask TSCTF_BOLD or mask TSCTF_ITALIC \
			or mask TSCTF_UNDERLINE or mask TSCTF_STRIKE_THRU \
			or mask TSCTF_SUBSCRIPT or mask TSCTF_SUPERSCRIPT
	jz	noToolStyles
	mov	si, offset TextStyleToolList
	call	SendListSetViaData
noToolStyles:

	; set extended style list

	pop	cx, dx
	and	cx, mask VTES_BOXED or mask VTES_BUTTON
	and	dx, mask VTES_BOXED or mask VTES_BUTTON

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask TSCF_BOXED or mask TSCF_BUTTON or mask TSCF_INDEX \
			or mask TSCF_ALL_CAP or mask TSCF_SMALL_CAP
	jz	noExtendedStyles
	mov	si, offset ExtendedStylesList
	call	SendListSetViaData
noExtendedStyles:

	; set extended style tool list

	test	ss:[bp].GCUUIP_toolboxFeatures,
			mask TSCTF_BOXED or mask TSCTF_BUTTON or \
			mask TSCTF_INDEX or mask TSCTF_ALL_CAP or \
			mask TSCTF_SMALL_CAP
	jz	noETools
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, offset ExtendedStylesToolList
	call	SendListSetViaData
noETools:

	ret

TextStyleControlUpdateUI	endm

;---

SendListSetViaData	proc	far	uses ax, cx, dx, bp
	.enter
	
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	Com_ObjMessageSend

	.leave
	ret
SendListSetViaData	endp

;---

	; cx = value, dx = non-zero if indeterminate
	; (it seems that cx = -1 if none selected.  -cbh)

SendListSetExcl	proc	far	uses	ax, cx, bp
	.enter
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	cmp	cx, -1				;no selection?
	jne	10$
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
10$:
	call	Com_ObjMessageSend
	.leave
	ret

SendListSetExcl	endp

;---

	; call ObjMessage with di = 0

Com_ObjMessageSend	proc	near		uses di
	.enter
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
Com_ObjMessageSend	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextStyleControlPlainTextChange -- MSG_TSC_PLAIN_TEXT_CHANGE
						for TextStyleControlClass

DESCRIPTION:	Handle a change in theee "Plain" state

PASS:
	*ds:si - instance data
	es - segment of TextStyleControlClass

	ax - The message

	bp low - ListEntryState
	bp high - ListUpdateFlags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@

TextStyleControlPlainTextChange	method TextStyleControlClass,
						MSG_TSC_PLAIN_TEXT_CHANGE

	mov	cx, 0xff		; clear all bits
	clr	dx
	mov	ax, not mask VTES_BACKGROUND_COLOR
	clr	bx
	GOTO	TextStyleCommon

TextStyleControlPlainTextChange	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextStyleControlStyleChange -- MSG_TSC_STYLE_CHANGE
						for TextStyleControlClass

DESCRIPTION:	Handle change to style list

PASS:
	*ds:si - instance data
	es - segment of TextStyleControlClass

	ax - The message

	cx - booleansSelected
	bp - booleansChanged

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
TextStyleControlStyleChange	method dynamic	TextStyleControlClass,
						MSG_TSC_STYLE_CHANGE

	mov	dx, cx				;cx & dx = selectedBooleans

	;Bits to set = selectedBooleans & changedBooleans
	and	dx, bp

	;Bits to clear = ~selectedBooleans & changedBooleans
	not	cx
	and	cx, bp

	;
	; If the superscript flag is set, then clear the subscript
	; flag, and vice-versa.
	;
	test	dx, mask TS_SUPERSCRIPT
	jz	afterSuper

	andnf	dx, not mask TS_SUBSCRIPT
	ornf	cx, mask TS_SUBSCRIPT
	jmp	afterSub


afterSuper:
	test	dx, mask TS_SUBSCRIPT
	jz	afterSub

	andnf	dx, not mask TS_SUPERSCRIPT
	ornf	cx, mask TS_SUPERSCRIPT

afterSub:

	clr	ax
	clr	bx
	FALL_THRU	TextStyleCommon

TextStyleControlStyleChange	endm

;---

	; ax = bits to clear (extended), bx = bits to set (extended)
	; cx = bits to clear, dx = bits to set

TextStyleCommon	proc	far
	class	TextStyleControlClass

	push	ax			;extended bits to clear
	push	bx			;extended bits to set
	push	cx			;bits to clear
	push	dx			;bits to set
	push	ax			;range.end.high
	push	ax			;range.end.low
	mov	bx, VIS_TEXT_RANGE_SELECTION
	push	bx			;range.start.high
	push	ax			;range.start.low
	mov	bp, sp
	mov	dx, size VisTextSetTextStyleParams
	mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
	clr	bx			;any class -- this is a meta message
	clr	di
	call	GenControlOutputActionStack
	add	sp, size VisTextSetTextStyleParams
	ret

TextStyleCommon	endp

TextControlCommon ends

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextStyleControlExtendedStyleChange --
			MSG_TSC_EXTENDED_STYLE_CHANGE for TextStyleControlClass

DESCRIPTION:	Handle change to style list

PASS:
	*ds:si - instance data
	es - segment of TextStyleControlClass

	ax - The message

	cx - bit to set/reset
	bp low - ListEntryState
	bp high - ListUpdateFlags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
TextStyleControlExtendedStyleChange	method dynamic	TextStyleControlClass,
						MSG_TSC_EXTENDED_STYLE_CHANGE

	mov	ax, cx				;ax & bx = selectedBooleans
	mov	bx, cx

	;Bits to set = selectedBooleans & changedBooleans
	and	bx, bp

	;Bits to clear = ~selectedBooleans & changedBooleans
	not	ax
	and	ax, bp

	; If the boxed flag is set, then clear the button
	; flag, and vice-versa.

	test	bx, mask VTES_BOXED
	jz	afterBoxed
	andnf	bx, not mask VTES_BUTTON
	ornf	ax, mask VTES_BUTTON
	jmp	afterButton
afterBoxed:
	test	dx, mask VTES_BUTTON
	jz	afterButton
	andnf	bx, not mask VTES_BOXED
	ornf	ax, mask VTES_BOXED
afterButton:

	clr	cx
	clr	dx
	call	TextStyleCommon
	ret

TextStyleControlExtendedStyleChange	endm

;---

CallListGetExcl	proc	near	uses cx, dx, di, bp
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret

CallListGetExcl	endp

;---

SendRangeSetBBFixedValue	proc	near	uses	ax, cx, dx, bp
	;Pass:  cx -- BBFixed value to set
	;	dx -- non-zero if indeterminate

	.enter
	call	SetIndFlag
	clr	dx
	mov	ax, cx
	mov	cx, 8
10$:
	shl	ax, 1
	rcl	dx, 1
	loop	10$
	mov	cx, ax				;dx.cx <- WWFixed value

	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	ObjMessageSend
	.leave
	ret
SendRangeSetBBFixedValue endp


;---

SendRangeSetValueTimes8	proc	near	uses	ax, cx, dx, bp
	;Pass:  cx -- points * 8
	;	dx -- non-zero if indeterminate

	.enter
	call	SetIndFlag
	mov	dx, cx
	clr	cx
	shr	dx, 1
	rcr	cx, 1
	shr	dx, 1
	rcr	cx, 1
	shr	dx, 1
	rcr	cx, 1
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	ObjMessageSend
	.leave
	ret
SendRangeSetValueTimes8 endp


;---
SendRangeSetWWFixedValue	proc	far	uses	ax, cx, dx, bp
	;Pass:  cx.ax -- value to set
	;	dx -- indeterminate flag
	.enter
	call	SetIndFlag
	mov	dx, cx
	mov	cx, ax		;pass value in dx.cx
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	ObjMessageSend
	.leave
	ret

SendRangeSetWWFixedValue	endp

SendRangeSetValue	proc	near	uses ax, cx, dx, bp
	;Pass:  cx -- value to set
	.enter
	call	SetIndFlag
	mov	dx, cx
	clr	cx			;pass value in dx.cx

	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	ObjMessageSend

	.leave
	ret

SendRangeSetValue	endp

;---

SendRangeSetValueNoIndeterminate	proc	near	uses dx
	.enter
	clr	dx
	call	SendRangeSetValue
	.leave
	ret

SendRangeSetValueNoIndeterminate	endp


SendRangeSetValueTimes8NoIndeterminate	proc	near	uses dx
	.enter
	clr	dx
	call	SendRangeSetValueTimes8
	.leave
	ret

SendRangeSetValueTimes8NoIndeterminate	endp


CallRangeGetValue	proc	near	uses ax, dx, di, bp
	.enter		;returns value in cx
	call	CallRangeCommon
	.leave
	ret

CallRangeGetValue	endp

;---
CallRangeGetValueTimes8	proc	near	uses ax, dx, di, bp
	.enter		;returns 13.3 value in cx

	call	CallRangeCommon
	shl	dx, 1
	rcl	cx, 1
	shl	dx, 1
	rcl	cx, 1
	shl	dx, 1
	rcl	cx, 1
	.leave
	ret

CallRangeGetValueTimes8	endp

;---

CallRangeCommon	proc	near
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	xchg	cx, dx			;returns cx.dx
	ret
CallRangeCommon	endp


SetIndFlag	proc	near
	clr	bp
	tst	dx
	jz	notIndeterminate
	mov	bp, mask GVSF_INDETERMINATE
	
notIndeterminate:
	ret
SetIndFlag	endp

;---

	; call ObjMessage with di = 0

ObjMessageSend	proc	near		uses di
	.enter
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
ObjMessageSend	endp

TextControlCode ends

endif		; not NO_CONTROLLERS
