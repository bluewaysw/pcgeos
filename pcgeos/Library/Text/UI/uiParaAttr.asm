COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiParaAttrControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ParaAttrControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement ParaAttrControlClass

	$Id: uiParaAttr.asm,v 1.1 97/04/07 11:16:58 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	ParaAttrControlClass		;declare the class record

if not NO_CONTROLLERS
	method	SetParaAttrCommon, ParaAttrControlClass, MSG_PAC_SET_PARA_ATTR
endif		; not NO_CONTROLLERS

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaAttrControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ParaAttrControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of ParaAttrControlClass

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
ParaAttrControlGetInfo	method dynamic	ParaAttrControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset PAC_dupInfo
	GOTO	CopyDupInfoCommon

ParaAttrControlGetInfo	endm

PAC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	PAC_IniFileKey,			; GCBI_initFileKey
	PAC_gcnList,			; GCBI_gcnList
	length PAC_gcnList,		; GCBI_gcnCount
	PAC_notifyTypeList,		; GCBI_notificationList
	length PAC_notifyTypeList,	; GCBI_notificationCount
	PACName,			; GCBI_controllerName

	handle ParaAttrControlUI,	; GCBI_dupBlock
	PAC_childList,			; GCBI_childList
	length PAC_childList,		; GCBI_childCount
	PAC_featuresList,		; GCBI_featuresList
	length PAC_featuresList,	; GCBI_featuresCount
	PAC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	PAC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	PAC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

PAC_helpContext	char	"dbParaAttr", 0

PAC_IniFileKey	char	"paraAttr", 0

PAC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>

PAC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>

;---

PAC_childList	GenControlChildInfo	\
	<offset PAOverallGroup, mask PACF_WORD_WRAP
					or mask PACF_COLUMN_BREAK_BEFORE
					or mask PACF_KEEP_PARA_WITH_NEXT
					or mask PACF_KEEP_PARA_TOGETHER
					or mask PACF_KEEP_LINES, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

PAC_featuresList	GenControlFeaturesInfo	\
	<offset PAKeepGroup, KeepLinesName, 0>,
	<offset KeepParaTogetherEntry, KeepParaTogetherName, 0>,
	<offset KeepParaWithNextEntry, KeepParaWithNextName, 0>,
	<offset ColumnBreakBeforeEntry, HiddenName, 0>,
	<offset WordWrapEntry, WordWrapName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

TextControlCommon ends

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaAttrControlSetKeep -- MSG_PAC_SET_KEEP
						for ParaAttrControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of ParaAttrControlClass

	ax - The message

	cx - selected booleans
	bp - changed booleans

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/13/91		Initial version

------------------------------------------------------------------------------@
ParaAttrControlSetKeep	method dynamic	ParaAttrControlClass, MSG_PAC_SET_KEEP

	mov	dx, mask VTPAA_KEEP_LINES

	; cx = bits to set, dx = bits to clear

	mov	ax, MSG_VIS_TEXT_SET_PARA_ATTRIBUTES
	call	SendMeta_AX_DXCX_Common
	ret
ParaAttrControlSetKeep	endm

;---

ParaAttrControlUserChangedKeep	method dynamic	ParaAttrControlClass,
						MSG_PAC_USER_CHANGED_KEEP
	call	GetFeaturesAndChildBlock
	clr	dx
	call	EnableDisableKeepLines
	ret
ParaAttrControlUserChangedKeep	endm

EnableDisableKeepLines	proc	near
	mov	si, offset PACustomKeepGroup
	GOTO	EnableDisableCommon
EnableDisableKeepLines	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaAttrControlSetKeepFirst -- MSG_PAC_SET_KEEP_FIRST
						for ParaAttrControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of ParaAttrControlClass
	ax - The message

	dx - value
RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/13/91		Initial version

------------------------------------------------------------------------------@
ParaAttrControlSetKeepFirst	method dynamic	ParaAttrControlClass,
						MSG_PAC_SET_KEEP_FIRST

	mov	cx, dx
	sub	cx, 2				;make zero based
	mov_tr	ax, cx
	mov	cl, offset VTKI_TOP_LINES
	shl	ax, cl
	mov_tr	cx, ax
	mov	dx, mask VTKI_TOP_LINES
	FALL_THRU	KeepCommon

ParaAttrControlSetKeepFirst	endm

KeepCommon	proc	far
	mov	ax, MSG_VIS_TEXT_SET_KEEP_PARAMS
	GOTO	SendVisText_AX_DXCX_Common
KeepCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaAttrControlSetKeepLast -- MSG_PAC_SET_KEEP_LAST
						for ParaAttrControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of ParaAttrControlClass
	ax - The message

	dx - value
RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/13/91		Initial version

------------------------------------------------------------------------------@
ParaAttrControlSetKeepLast	method dynamic	ParaAttrControlClass,
						MSG_PAC_SET_KEEP_LAST

	CheckHack <offset VTKI_BOTTOM_LINES eq 0>

	mov	cx, dx
	sub	cx, 2				;make zero based
	mov	dx, mask VTKI_BOTTOM_LINES
	GOTO	KeepCommon

ParaAttrControlSetKeepLast	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaAttrControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for ParaAttrControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of ParaAttrControlClass

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
ParaAttrControlUpdateUI	method dynamic ParaAttrControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_attributes
	mov	dx, es:VTNPAC_paraAttrDiffs.VTPAD_attributes

	; set list

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask PACF_WORD_WRAP or mask PACF_COLUMN_BREAK_BEFORE or \
			mask PACF_KEEP_PARA_TOGETHER or \
			mask PACF_KEEP_PARA_WITH_NEXT
	jz	noList
	mov	si, offset PASimpleList
	call	SendListSetViaData
noList:

	; set keep lines

	test	ax, mask PACF_KEEP_LINES
	jz	noKeepLines
	and	cx, mask VTPAA_KEEP_LINES
	and	dx, mask VTPAA_KEEP_LINES
	mov	si, offset PAKeepList
	call	SendListSetExcl

	call	EnableDisableKeepLines

	clr	cx
	clr	dx
	mov	cl, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_keepInfo
	mov	dl, es:VTNPAC_paraAttrDiffs.VTPAD_keepInfo

	; set custom keep

	push	cx, dx
	mov_tr	ax, cx
	mov	cl, offset VTKI_TOP_LINES
	shr	ax, cl
	mov_tr	cx, ax
	add	cx, 2				;make one based
	and	dx, mask VTKI_TOP_LINES
	mov	si, offset KeepFirstRange
	call	SendRangeSetValue
	pop	cx, dx

	CheckHack <offset VTKI_BOTTOM_LINES eq 0>
	and	cx, mask VTKI_BOTTOM_LINES
	add	cx, 2				;make one based
	and	dx, mask VTKI_BOTTOM_LINES
	mov	si, offset KeepLastRange
	call	SendRangeSetValue
noKeepLines:

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

	ret

ParaAttrControlUpdateUI	endm

TextControlCode ends

endif		; not NO_CONTROLLERS
