COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiMarginControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	MarginControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement MarginControlClass

	$Id: uiMargin.asm,v 1.1 97/04/07 11:16:55 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	MarginControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	MarginControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for MarginControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of MarginControlClass

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
MarginControlGetInfo	method dynamic	MarginControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset MC_dupInfo
	GOTO	CopyDupInfoCommon

MarginControlGetInfo	endm

MC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	MC_IniFileKey,			; GCBI_initFileKey
	MC_gcnList,			; GCBI_gcnList
	length MC_gcnList,		; GCBI_gcnCount
	MC_notifyTypeList,		; GCBI_notificationList
	length MC_notifyTypeList,	; GCBI_notificationCount
	MCName,				; GCBI_controllerName

	handle MarginControlUI,		; GCBI_dupBlock
	MC_childList,			; GCBI_childList
	length MC_childList,		; GCBI_childCount
	MC_featuresList,		; GCBI_featuresList
	length MC_featuresList,		; GCBI_featuresCount
	MC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	MC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	MC_helpContext>			; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

MC_helpContext	char	"dbMargin", 0

MC_IniFileKey	char	"margins", 0

MC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>

MC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>

;---

MC_childList	GenControlChildInfo	\
	<offset ParaMarginRange, mask MCF_PARA_MARGIN,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset LeftMarginRange, mask MCF_LEFT_MARGIN,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset RightMarginRange, mask MCF_RIGHT_MARGIN,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

MC_featuresList	GenControlFeaturesInfo	\
	<offset RightMarginRange, RightMarginName, 0>,
	<offset ParaMarginRange, ParaMarginName, 0>,
	<offset LeftMarginRange, LeftMarginName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

TextControlCommon ends

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	MarginControlSetLeftMargin -- MSG_MC_SET_LEFT_MARGIN
						for MarginControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of MarginControlClass

	ax - The message

	dx.cx - WWFixed points

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
MarginControlSetLeftMargin	method dynamic	MarginControlClass,
						MSG_MC_SET_LEFT_MARGIN
	mov	ax, MSG_VIS_TEXT_SET_LEFT_MARGIN
	GOTO	SendVisText_AX_DX_CX_Times_8_Common

MarginControlSetLeftMargin	endm

;---

MarginControlSetParaMargin	method dynamic	MarginControlClass,
						MSG_MC_SET_PARA_MARGIN
	mov	ax, MSG_VIS_TEXT_SET_PARA_MARGIN
	GOTO	SendVisText_AX_DX_CX_Times_8_Common

MarginControlSetParaMargin	endm

;---

MarginControlSetRightMargin	method dynamic	MarginControlClass,
						MSG_MC_SET_RIGHT_MARGIN
	mov	ax, MSG_VIS_TEXT_SET_RIGHT_MARGIN
	GOTO	SendVisText_AX_DX_CX_Times_8_Common

MarginControlSetRightMargin	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	MarginControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for MarginControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of MarginControlClass

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
MarginControlUpdateUI	method dynamic MarginControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	mov	dx, es:VTNPAC_paraAttrDiffs.VTPAD_diffs

	; set left margin

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock

	test	ax, mask MCF_LEFT_MARGIN
	jz	noLeft
	push	dx
	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_leftMargin
	and	dx, mask VTPAF_MULTIPLE_LEFT_MARGINS
	mov	si, offset LeftMarginRange
	call	SendRangeSetValueTimes8
	pop	dx
noLeft:

	test	ax, mask MCF_PARA_MARGIN
	jz	noPara
	push	dx
	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_paraMargin
	and	dx, mask VTPAF_MULTIPLE_PARA_MARGINS
	mov	si, offset ParaMarginRange
	call	SendRangeSetValueTimes8
	pop	dx
noPara:

	test	ax, mask MCF_RIGHT_MARGIN
	jz	noRight
	push	dx
	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_rightMargin
	and	dx, mask VTPAF_MULTIPLE_RIGHT_MARGINS
	mov	si, offset RightMarginRange
	call	SendRangeSetValueTimes8
	pop	dx
noRight:

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

	ret

MarginControlUpdateUI	endm

TextControlCode ends

endif		; not NO_CONTROLLERS
