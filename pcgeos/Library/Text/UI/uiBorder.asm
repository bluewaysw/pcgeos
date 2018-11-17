COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiBorderControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	BorderControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement BorderControlClass

	$Id: uiBorder.asm,v 1.1 97/04/07 11:17:38 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	BorderControlClass		;declare the class record

TextClassStructures	ends


;---------------------------------------------------

BorderTypes	etype	word
BT_NORMAL		enum	BorderTypes
BT_SHADOW		enum	BorderTypes
BT_DOUBLE_LINE		enum	BorderTypes
BT_INDETERMINATE	enum	BorderTypes

; This is a hack to allow us to shove the border width in unused bits for
; communicating with UI objects


BCBorderFlags	record
    BCBF_LEFT:1			;Set if a border on the left
    BCBF_TOP:1			;Set if a border on the top
    BCBF_RIGHT:1		;Set if a border on the right
    BCBF_BOTTOM:1		;Set if a border on the bottom
    BCBF_DOUBLE:1		;Draw two line border
    BCBF_DRAW_INNER_LINES:1	;Draw lines between bordered paragraphs
    BCBF_SHADOW:1		;Set to use shadow
    BCBF_WIDTH:7		;Width
    BCBF_ANCHOR	ShadowAnchor:2
BCBorderFlags	end


if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	BorderControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for BorderControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of BorderControlClass

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
BorderControlGetInfo	method dynamic	BorderControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset BC_dupInfo
	GOTO	CopyDupInfoCommon

BorderControlGetInfo	endm

BC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	BC_IniFileKey,			; GCBI_initFileKey
	BC_gcnList,			; GCBI_gcnList
	length BC_gcnList,		; GCBI_gcnCount
	BC_notifyTypeList,		; GCBI_notificationList
	length BC_notifyTypeList,	; GCBI_notificationCount
	BCName,				; GCBI_controllerName

	handle BorderControlUI,		; GCBI_dupBlock
	BC_childList,			; GCBI_childList
	length BC_childList,		; GCBI_childCount
	BC_featuresList,		; GCBI_featuresList
	length BC_featuresList,		; GCBI_featuresCount
	BC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	BC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

BC_IniFileKey	char	"paraSpacing", 0

BC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>

BC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>

;---

BC_childList	GenControlChildInfo	\
	<offset SimpleBorderList, mask BCF_LIST,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset CustomBorderBox, mask BCF_CUSTOM,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

BC_featuresList	GenControlFeaturesInfo	\
	<offset CustomBorderBox, CustomBorderName, 0>,
	<offset SimpleBorderList, SimpleBorderName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

TextControlCommon ends

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	BorderControlSetSimpleBorder -- MSG_BC_SET_SIMPLE_BORDER
						for BorderControlClass

DESCRIPTION:	Handle a change in theee "Plain" state

PASS:
	*ds:si - instance data
	es - segment of BorderControlClass

	ax - The message

	cx - spacing
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
BorderControlSetSimpleBorder	method BorderControlClass,
						MSG_BC_SET_SIMPLE_BORDER

	push	cx

	mov	ax, MSG_META_SUSPEND
	call	SendVisText_AX_CX_Common

	and	cx, mask BCBF_WIDTH
	shr	cx		| CheckHack <offset BCBF_WIDTH eq 2>
	shr	cx
	mov	ax, MSG_VIS_TEXT_SET_BORDER_WIDTH
	call	SendVisText_AX_CX_Common

	mov	ax, MSG_VIS_TEXT_SET_BORDER_SPACING
	mov	cx, 2*8
	call	SendVisText_AX_CX_Common

	mov	ax, MSG_VIS_TEXT_SET_BORDER_SHADOW
	mov	cx, 1*8
	call	SendVisText_AX_CX_Common

	pop	cx

	and	cx, mask VisTextParaBorderFlags
	mov	dx, 0xffff
	mov	ax, MSG_VIS_TEXT_SET_BORDER_BITS
	call	SendVisText_AX_DXCX_Common

	mov	ax, MSG_META_UNSUSPEND
	call	SendVisText_AX_CX_Common

	ret

BorderControlSetSimpleBorder	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	BorderControlSetBorderBits -- MSG_BC_SET_BORDER_BITS
						for BorderControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of BorderControlClass

	ax - The message

	cx - selectedBooleans
	bp - changedBooleans

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/14/91		Initial version

------------------------------------------------------------------------------@
BorderControlSetBorderBits	method dynamic	BorderControlClass,
						MSG_BC_SET_BORDER_BITS

	mov	dx, cx				;cx & dx = selectedBooleans

	;Bits to set = selectedBooleans & changedBooleans
	and	cx, bp

	;Bits to clear = ~selectedBooleans & changedBooleans
	not	dx
	and	dx, bp

	; cx = bits to set, dx = bits to clear

	mov	ax, MSG_VIS_TEXT_SET_BORDER_BITS
	GOTO	SendVisText_AX_DXCX_Common

BorderControlSetBorderBits	endm


BorderControlBorderSidesStatus	method dynamic	BorderControlClass,
						MSG_BC_BORDER_SIDES_STATUS

	call	GetFeaturesAndChildBlock	;ax = features, bx = child block

	; if "top" or "bottom" then enable

	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_ENABLED
	test	cx, mask VTPBF_TOP or mask VTPBF_BOTTOM
	jnz	haveInner
	mov	ax, MSG_GEN_SET_NOT_ENABLED
haveInner:
	mov	si, offset BorderInnerLinesList
	call	ObjMessageSend
	ret
BorderControlBorderSidesStatus	endm

;---

BorderControlSetBorderAnchor	method dynamic	BorderControlClass,
						MSG_BC_SET_BORDER_ANCHOR

	mov	dx, mask VTPBF_ANCHOR
	mov	ax, MSG_VIS_TEXT_SET_BORDER_BITS
	GOTO	SendVisText_AX_DXCX_Common

BorderControlSetBorderAnchor	endm

;---

SendVisText_AX_DXCX_Common	proc	far	uses bx, dx, di, bp
	.enter

	pushdw	dxcx			;point size
	clr	dx
	push	dx			;range.end.high
	push	dx			;range.end.low
	mov	bx, VIS_TEXT_RANGE_SELECTION
	push	bx			;range.start.high
	push	dx			;range.start.low
	mov	bp, sp
	mov	dx, size VisTextSetPointSizeParams
	mov	bx, segment VisTextClass
	mov	di, offset VisTextClass
	call	GenControlOutputActionStack
	add	sp, size VisTextSetPointSizeParams

	.leave
	ret

SendVisText_AX_DXCX_Common	endp

;---

SendVisText_AX_DX_CX_Times_8_Common	proc	far
	;Pass: dx.cx -- (text object cx parameter)/8 

	shl	cx
	rcl	dx
	shl	cx
	rcl	dx
	shl	cx
	rcl	dx
	;
	; all uses of this are for setting a word or byte value from a
	; WWFixed, so let's round it - brianc 11/3/94
	;
	rndwwf	dxcx
	FALL_THRU	SendVisText_AX_DX_Common
SendVisText_AX_DX_CX_Times_8_Common	endp


SendVisText_AX_DX_Common	proc	far
	;Pass: dx -- text object cx parameter 
	mov	cx, dx
	FALL_THRU	SendVisText_AX_CX_Common
SendVisText_AX_DX_Common	endp


SendVisText_AX_CX_Common	proc	far	uses bx, dx, di, bp
	.enter

	push	bp
	clr	dx
	push	cx			;font id
	push	dx			;range.end.high
	push	dx			;range.end.low
	mov	bx, VIS_TEXT_RANGE_SELECTION
	push	bx			;range.start.high
	push	dx			;range.start.low
	mov	bp, sp
	mov	dx, size VisTextSetFontIDParams
	mov	bx, segment VisTextClass
	mov	di, offset VisTextClass
	call	GenControlOutputActionStack
	add	sp, size VisTextSetFontIDParams
	pop	bp

	.leave
	ret

SendVisText_AX_CX_Common	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	BorderControlSetBorderWidth -- MSG_BC_SET_BORDER_WIDTH
						for BorderControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of BorderControlClass
	ax - The message

	dx - integer of range value

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/14/91		Initial version

------------------------------------------------------------------------------@
BorderControlSetBorderWidth	method dynamic	BorderControlClass,
						MSG_BC_SET_BORDER_WIDTH

	mov	ax, MSG_VIS_TEXT_SET_BORDER_WIDTH
	GOTO	SendVisText_AX_DX_CX_Times_8_Common

BorderControlSetBorderWidth	endm

;---

BorderControlSetBorderSpacing	method dynamic	BorderControlClass,
						MSG_BC_SET_BORDER_SPACING

	mov	ax, MSG_VIS_TEXT_SET_BORDER_SPACING
	GOTO	SendVisText_AX_DX_CX_Times_8_Common

BorderControlSetBorderSpacing	endm

;---

BorderControlSetBorderShadowWidth	method dynamic	BorderControlClass,
						MSG_BC_SET_SHADOW_WIDTH

	mov	ax, MSG_VIS_TEXT_SET_BORDER_SHADOW
	GOTO	SendVisText_AX_DX_CX_Times_8_Common

BorderControlSetBorderShadowWidth	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	BorderControlSetBorderType -- MSG_BC_SET_BORDER_TYPE
						for BorderControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of BorderControlClass

	ax - The message

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/14/91		Initial version

------------------------------------------------------------------------------@
BorderControlSetBorderType	method dynamic	BorderControlClass,
						MSG_BC_SET_BORDER_TYPE

	mov_tr	ax, cx
	clr	cx
	cmp	al, BT_NORMAL
	jz	actualCommon
	mov	cx, mask VTPBF_SHADOW
	cmp	al, BT_SHADOW
	jz	actualCommon
	mov	cx, mask VTPBF_DOUBLE

actualCommon:
	mov	dx, mask VTPBF_SHADOW or mask VTPBF_DOUBLE
	mov	ax, MSG_VIS_TEXT_SET_BORDER_BITS
	GOTO	SendVisText_AX_DXCX_Common
BorderControlSetBorderType	endm


BorderControlBorderTypeStatus	method dynamic	BorderControlClass,
						MSG_BC_BORDER_TYPE_STATUS

	call	GetFeaturesAndChildBlock	;ax = features, bx = child block
	clr	dx

	; if "normal" then do nothing special

	mov	ax, MSG_GEN_SET_NOT_ENABLED	;ax = for shadow width spin
	mov	di, MSG_GEN_SET_NOT_ENABLED	;di = for between lines spin
	cmp	cx, BT_NORMAL
	jz	common

	; if "shadow" then set anchor to upper left, shadow width to 1

	cmp	cx, BT_SHADOW
	jnz	doubleLine

	mov	cx, 1
	mov	si, offset BorderShadowWidthSpin
	call	SendRangeSetValue

	mov	cx, SA_TOP_LEFT
	mov	si, offset BorderShadowAnchorList
	call	SendListSetExcl

	mov	ax, MSG_GEN_SET_ENABLED		;ax = for shadow width spin
	mov	di, MSG_GEN_SET_NOT_ENABLED	;di = for between lines spin
	jmp	common

	; if "double" then set space between lines to 1

doubleLine:
	mov	cx, 1
	mov	si, offset BorderWidthBetweenLinesSpin
	call	SendRangeSetValue

	mov	ax, MSG_GEN_SET_NOT_ENABLED	;ax = for shadow width spin
	mov	di, MSG_GEN_SET_ENABLED		;di = for between lines spin

common:

	; set enabled/disabled status of "shadow" stuff

	mov	dl, VUM_NOW
	mov	si, offset BorderShadowAnchorList
	call	ObjMessageSend
	mov	si, offset BorderShadowWidthSpin
	call	ObjMessageSend

	; set enabled/disabled status of "double line" stuff

	mov_tr	ax, di
	mov	si, offset BorderWidthBetweenLinesSpin
	call	ObjMessageSend
	ret

BorderControlBorderTypeStatus	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	BorderControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for BorderControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of BorderControlClass

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
BorderControlUpdateUI	method dynamic BorderControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_borderFlags
	mov	dx, es:VTNPAC_paraAttrDiffs.VTPAD_borderDiffs

	; set list

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask BCF_LIST
	jz	noList

	push	ax, cx, dx

	; put width into bits

	clr	ax
	mov	al, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_borderWidth
	cmp	al, 128
	jae	10$
	shl	al		| CheckHack <offset BCBF_WIDTH eq 2>
	shl	al
	or	cx, ax

	; if width, spacing or shadow is non-1 then indeterminate

	cmp	es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_borderSpacing, 2*8
	jnz	10$
	cmp	es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_borderShadow, 1*8
	jz	20$
10$:
	mov	dx, 1
20$:
	mov	si, offset SimpleBorderList
	call	SendListSetExcl
	pop	ax, cx, dx
noList:

	; set custom border

	test	ax, mask BCF_CUSTOM
	LONG jz	noCustom

	; update border sides

	push	dx
	and	dx, mask VTPABF_MULTIPLE_BORDER_LEFT \
			or mask VTPABF_MULTIPLE_BORDER_TOP \
			or mask VTPABF_MULTIPLE_BORDER_RIGHT \
			or mask VTPABF_MULTIPLE_BORDER_BOTTOM
	mov	si, offset BorderSidesList
	call	SendListSetViaData
	pop	dx

	; update draw inner lines

	push	dx
	and	dx, mask VTPABF_MULTIPLE_BORDER_DRAW_INNERS
	mov	si, offset BorderInnerLinesList
	call	SendListSetViaData
	pop	dx

	; disable Inner Lines if not Top/Bottom

	push	dx
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_ENABLED
	test	cx, mask VTPBF_TOP or mask VTPBF_BOTTOM
	jnz	haveInner
	mov	ax, MSG_GEN_SET_NOT_ENABLED
haveInner:
	mov	si, offset BorderInnerLinesList
	call	ObjMessageSend
	pop	dx

	; update border type (make correct group active)

	push	dx
	test	dx, mask VTPBF_DOUBLE or mask VTPBF_SHADOW
	mov	ax, MSG_GEN_SET_ENABLED		;ax = for shadow width spin
	mov	dx, MSG_GEN_SET_ENABLED		;dx = for between lines spin
	mov	di, BT_INDETERMINATE		;exclusive
	jnz	groupCommon

						;assume double line
	mov	ax, MSG_GEN_SET_NOT_ENABLED	;ax = for shadow width spin
	mov	dx, MSG_GEN_SET_ENABLED		;dx = for between lines spin
	mov	di, BT_DOUBLE_LINE		;exclusive
	test	cx, mask VTPBF_DOUBLE
	jnz	groupCommon
						;assume normal
	mov	ax, MSG_GEN_SET_NOT_ENABLED	;ax = for shadow width spin
	mov	dx, MSG_GEN_SET_NOT_ENABLED	;dx = for between lines spin
	mov	di, BT_NORMAL			;exclusive
	test	cx, mask VTPBF_SHADOW
	jz	groupCommon
						;must be shadow
	mov	ax, MSG_GEN_SET_ENABLED		;ax = for shadow width spin
	mov	dx, MSG_GEN_SET_NOT_ENABLED	;dx = for between lines spin
	mov	di, BT_SHADOW			;exclusive
groupCommon:

	push	dx
	mov	dl, VUM_NOW
	mov	si, offset BorderShadowAnchorList
	call	ObjMessageSend
	mov	si, offset BorderShadowWidthSpin
	call	ObjMessageSend
	pop	ax

	mov	dl, VUM_NOW
	mov	si, offset BorderWidthBetweenLinesSpin
	call	ObjMessageSend

	mov	cx, di
	clr	dx
	mov	si, offset BorderTypesList
	call	SendListSetExcl
	pop	dx

	; update border shadow width spin

	cmp	di, BT_SHADOW
	jnz	notShadow

	; update shadow anchor

	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_borderFlags
	and	cx, mask VTPBF_ANCHOR
	push	dx
	and	dx, mask VTPABF_MULTIPLE_BORDER_ANCHORS
	mov	si, offset BorderShadowAnchorList
	call	SendListSetExcl
	pop	dx

	clr	cx
	mov	cl, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_borderShadow
	push	dx
	and	dx, mask VTPABF_MULTIPLE_BORDER_SHADOWS
	mov	si, offset BorderShadowWidthSpin
	call	SendRangeSetValueTimes8
	pop	dx
notShadow:

	; update space between lines spin

	cmp	di, BT_DOUBLE_LINE
	jnz	notDouble
	clr	cx
	mov	cl, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_borderShadow
	push	dx
	and	dx, mask VTPABF_MULTIPLE_BORDER_SHADOWS
	mov	si, offset BorderWidthBetweenLinesSpin
	call	SendRangeSetValueTimes8
	pop	dx
notDouble:

	; update border width

	clr	cx
	mov	cl, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_borderWidth
	push	dx
	and	dx, mask VTPABF_MULTIPLE_BORDER_WIDTHS
	mov	si, offset BorderWidthSpin
	call	SendRangeSetValueTimes8
	pop	dx

	; update border spacing

	clr	cx
	mov	cl, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_borderSpacing
	and	dx, mask VTPABF_MULTIPLE_BORDER_SPACINGS
	mov	si, offset BorderSpacingSpin
	call	SendRangeSetValueTimes8

noCustom:

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

	ret

BorderControlUpdateUI	endm

TextControlCode ends

endif		; not NO_CONTROLLERS
