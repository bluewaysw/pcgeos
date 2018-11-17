COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiFontAttrControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	FontAttrControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement FontAttrControlClass

	$Id: uiFontAttr.asm,v 1.1 97/04/07 11:16:47 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	FontAttrControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	FontAttrControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for FontAttrControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of FontAttrControlClass

	ax - The message

RETURN:
	cx:dx - list of children

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
FontAttrControlGetInfo	method dynamic	FontAttrControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset FAC_dupInfo
	GOTO	CopyDupInfoCommon

FontAttrControlGetInfo	endm

FAC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	FAC_IniFileKey,			; GCBI_initFileKey
	FAC_gcnList,			; GCBI_gcnList
	length FAC_gcnList,		; GCBI_gcnCount
	FAC_notifyTypeList,		; GCBI_notificationList
	length FAC_notifyTypeList,	; GCBI_notificationCount
	FACName,			; GCBI_controllerName

	handle FontAttrControlUI,	; GCBI_dupBlock
	FAC_childList,			; GCBI_childList
	length FAC_childList,		; GCBI_childCount
	FAC_featuresList,		; GCBI_featuresList
	length FAC_featuresList,	; GCBI_featuresCount
	FAC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	FAC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	FAC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

FAC_helpContext	char	"dbCharAttr", 0


FAC_IniFileKey	char	"fontAttr", 0

FAC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_FONT_ATTR_CHANGE>

FAC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_FONT_ATTR_CHANGE>

;---

FAC_childList	GenControlChildInfo	\
	<offset FontWeightRange, mask FACF_FONT_WEIGHT,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset FontWidthRange, mask FACF_FONT_WIDTH,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TrackKerningRange, mask FACF_TRACK_KERNING,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

FAC_featuresList	GenControlFeaturesInfo	\
	<offset TrackKerningRange, TrackKerningName, 0>,
	<offset FontWidthRange, FontWidthName, 0>,
	<offset FontWeightRange, FontWeightName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

TextControlCommon ends

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	FontAttrControlSetFontWeight -- MSG_FAC_SET_FONT_WEIGHT
						for FontAttrControlClass

DESCRIPTION:	Handle a font weight setting

PASS:
	*ds:si - instance data
	es - segment of FontAttrControlClass

	ax - The message

	dx - font weight

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/25/91		Initial version

------------------------------------------------------------------------------@
FontAttrControlSetFontWeight	method dynamic	FontAttrControlClass,
						MSG_FAC_SET_FONT_WEIGHT

	mov	ax, MSG_VIS_TEXT_SET_FONT_WEIGHT
	FALL_THRU	SendMeta_AX_DX_Common

FontAttrControlSetFontWeight	endm

SendMeta_AX_DX_Common 	proc	far
	mov	cx, dx
	call	SendMeta_AX_CX_Common
	ret
SendMeta_AX_DX_Common 	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	FontAttrControlSetFontWidth -- MSG_FAC_SET_FONT_WIDTH
						for FontAttrControlClass

DESCRIPTION:	Handle a font weight setting

PASS:
	*ds:si - instance data
	es - segment of FontAttrControlClass
	ax - The message

	dx - font weight

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/25/91		Initial version

------------------------------------------------------------------------------@
FontAttrControlSetFontWidth	method dynamic	FontAttrControlClass,
						MSG_FAC_SET_FONT_WIDTH

	mov	ax, MSG_VIS_TEXT_SET_FONT_WIDTH
	GOTO	SendMeta_AX_DX_Common

FontAttrControlSetFontWidth	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	FontAttrControlSetTrackKerning -- MSG_FAC_SET_TRACK_KERNING
						for FontAttrControlClass

DESCRIPTION:	Handle a font weight setting

PASS:
	*ds:si - instance data
	es - segment of FontAttrControlClass

	ax - The message

	dx - track kerning

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/25/91		Initial version

------------------------------------------------------------------------------@
FontAttrControlSetTrackKerning	method dynamic	FontAttrControlClass,
						MSG_FAC_SET_TRACK_KERNING

	mov	ax, MSG_VIS_TEXT_SET_TRACK_KERNING
	GOTO	SendMeta_AX_DX_Common

FontAttrControlSetTrackKerning	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	FontAttrControlUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for FontAttrControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of FontAttrControlClass

	ax - The message

	cx.dx - change type ID
	bp - handle of block with NotifyTextChange structure

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
FontAttrControlUpdateUI	method dynamic FontAttrControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	di, ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	cmp	ss:[bp].GCUUIP_changeType, GWNT_TEXT_CHAR_ATTR_CHANGE
	jz	textNotify
	clr	dx
	mov	cl, ds:NFAC_fontWeight
	mov	dl, ds:NFAC_fontWeightDiffs
	push	cx, dx
	mov	cl, ds:NFAC_fontWidth
	mov	dl, ds:NFAC_fontWidthDiffs
	push	cx, dx
	mov	cx, ds:NFAC_trackKerning
	mov	dl, ds:NFAC_trackKerningDiffs
	jmp	common
textNotify:
	mov	cl, ds:VTNCAC_charAttr.VTCA_fontWeight
	mov	ax, ds:VTNCAC_charAttrDiffs.VTCAD_diffs
	mov	dx, ax
	and	dx, mask VTCAF_MULTIPLE_FONT_WEIGHTS
	push	cx, dx
	mov	cl, ds:VTNCAC_charAttr.VTCA_fontWidth
	mov	dx, ax
	and	dx, mask VTCAF_MULTIPLE_FONT_WIDTHS
	push	cx, dx
	mov	cx, ds:VTNCAC_charAttr.VTCA_trackKerning
	mov	dx, ax
	and	dx, mask VTCAF_MULTIPLE_TRACK_KERNINGS
common:
	call	MemUnlock
	mov	ds, di

	; set track kerning

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask FACF_TRACK_KERNING
	jz	noKerning
	mov	si, offset TrackKerningRange
	call	SendRangeSetValue
noKerning:

	; set font width

	pop	cx, dx
	test	ax, mask FACF_FONT_WIDTH
	jz	noWidth
	mov	si, offset FontWidthRange
	call	SendRangeSetValue
noWidth:

	; set font weight

	pop	cx, dx
	test	ax, mask FACF_FONT_WEIGHT
	jz	noWeight
	mov	si, offset FontWeightRange
	call	SendRangeSetValue
noWeight:

	ret

FontAttrControlUpdateUI	endm

TextControlCode ends

endif		; not NO_CONTROLLERS
