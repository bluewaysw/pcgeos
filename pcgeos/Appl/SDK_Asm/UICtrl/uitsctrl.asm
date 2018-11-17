COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiTextStyleControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	UICTextStyleControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement UICUICTextStyleControlClass

	$Id: uitsctrl.asm,v 1.1 97/04/04 16:32:24 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

idata segment

	UICTextStyleControlClass		;declare the class record

idata ends

;---------------------------------------------------

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	UICTextStyleControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for UICTextStyleControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of UICTextStyleControlClass

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
UICTextStyleControlGetInfo	method dynamic	UICTextStyleControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset TSC_dupInfo
	FALL_THRU	CopyDupInfoCommon

UICTextStyleControlGetInfo	endm

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

TSC_IniFileKey	char	"textStyleControl", 0

TSC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE>

TSC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_CHAR_ATTR_CHANGE>

;---

TSC_childList	GenControlChildInfo	\
	<offset PlainTextList, mask TSCF_PLAIN,
			mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TextStyleList, mask TSCF_BOLD or mask TSCF_ITALIC or
			mask TSCF_UNDERLINE or mask TSCF_STRIKE_THRU or
			mask TSCF_SUBSCRIPT or mask TSCF_SUPERSCRIPT, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TSC_featuresList	GenControlFeaturesInfo	\
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
			mask TSCTF_SUBSCRIPT or mask TSCTF_SUPERSCRIPT, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TSC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset SuperscriptToolEntry, SuperscriptName, 0>,
	<offset SubscriptToolEntry, SubscriptName, 0>,
	<offset StrikeThruToolEntry, StrikeThruName, 0>,
	<offset UnderlineToolEntry, UnderlineName, 0>,
	<offset ItalicToolEntry, ItalicName, 0>,
	<offset BoldToolEntry, BoldName, 0>,
	<offset PlainTextToolList, PlainTextName, 0>

COMMENT @----------------------------------------------------------------------

MESSAGE:	UICTextStyleControlPlainTextChange -- MSG_TSC_PLAIN_TEXT_CHANGE
						for UICTextStyleControlClass

DESCRIPTION:	Handle a change in theee "Plain" state

PASS:
	*ds:si - instance data
	es - segment of UICTextStyleControlClass

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
UICTextStyleControlPlainTextChange	method UICTextStyleControlClass,
						MSG_TSC_PLAIN_TEXT_CHANGE

	mov	cx, 0xff		; clear all bits
	clr	dx
	GOTO	TextStyleCommon

UICTextStyleControlPlainTextChange	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	UICTextStyleControlStyleChange -- MSG_TSC_STYLE_CHANGE
						for UICTextStyleControlClass

DESCRIPTION:	Handle change to style list

PASS:
	*ds:si - instance data
	es - segment of UICTextStyleControlClass

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
UICTextStyleControlStyleChange	method dynamic	UICTextStyleControlClass,
						MSG_TSC_STYLE_CHANGE

	mov	dx, cx				;cx & dx = selectedBooleans

	;Bits to set = selectedBooleans & changedBooleans
	and	dx, bp

	;Bits to clear = ~selectedBooleans & changedBooleans
	not	cx
	and	cx, bp

	FALL_THRU	TextStyleCommon

UICTextStyleControlStyleChange	endm

;---

	; cx = bits to clear, dx = bits to set

TextStyleCommon	proc	far
	class	UICTextStyleControlClass

	clr	ax
	push	ax			;extended bits to clear
	push	ax			;extended bits to set
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

COMMENT @----------------------------------------------------------------------

MESSAGE:	UICTextStyleControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for UICTextStyleControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of UICTextStyleControlClass

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
UICTextStyleControlUpdateUI	method dynamic UICTextStyleControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	clr	cx
	clr	dx
	mov	cl, ds:VTNCAC_charAttr.VTCA_textStyles
	mov	dl, ds:VTNCAC_charAttrDiffs.VTCAD_textStyles
	call	MemUnlock
	pop	ds

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

	test	ax, mask TSCF_PLAIN
	jz	noPlain
	mov	si, offset PlainTextList
	call	SendListSetExcl
noPlain:

	; set text style tool

	mov	ax, ss:[bp].GCUUIP_toolboxFeatures
	mov	bx, ss:[bp].GCUUIP_toolBlock
	test	ax, mask TSCTF_BOLD or mask TSCTF_ITALIC \
			or mask TSCTF_UNDERLINE or mask TSCTF_STRIKE_THRU \
			or mask TSCTF_SUBSCRIPT or mask TSCTF_SUPERSCRIPT
	jz	noToolStyles
	mov	si, offset TextStyleToolList
	call	SendListSetViaData
noToolStyles:

	; set the plain text tool list

	test	ax, mask TSCTF_PLAIN
	jz	noPlainTool
	mov	si, offset PlainTextToolList
	call	SendListSetExcl
noPlainTool:

	ret

UICTextStyleControlUpdateUI	endm

;---

SendListSetViaData	proc	near	uses ax
	.enter

	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjMessageSend

	.leave
	ret
SendListSetViaData	endp

;---

	; cx = value, dx = non-zero if indeterminate

SendListSetExcl	proc	near	uses	ax
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	tst	dx
	jz	setExclusive
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
setExclusive:
	call	ObjMessageSend

	.leave
	ret

SendListSetExcl	endp

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
