COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiParaSpacingControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ParaSpacingControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement ParaSpacingControlClass

	$Id: uiParaSpacing.asm,v 1.1 97/04/07 11:16:50 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	ParaSpacingControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaSpacingControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ParaSpacingControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of ParaSpacingControlClass

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
ParaSpacingControlGetInfo	method dynamic	ParaSpacingControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset PASC_dupInfo
	GOTO	CopyDupInfoCommon

ParaSpacingControlGetInfo	endm

PASC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	PASC_IniFileKey,		; GCBI_initFileKey
	PASC_gcnList,			; GCBI_gcnList
	length PASC_gcnList,		; GCBI_gcnCount
	PASC_notifyTypeList,		; GCBI_notificationList
	length PASC_notifyTypeList,	; GCBI_notificationCount
	PASCName,			; GCBI_controllerName

	handle ParaSpacingControlUI,	; GCBI_dupBlock
	PASC_childList,			; GCBI_childList
	length PASC_childList,		; GCBI_childCount
	PASC_featuresList,		; GCBI_featuresList
	length PASC_featuresList,	; GCBI_featuresCount
	PASC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	PASC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	PASC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

PASC_helpContext	char	"dbParaSpc", 0

PASC_IniFileKey	char	"paraSpacing", 0

PASC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>

PASC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>

;---

PASC_childList	GenControlChildInfo	\
	<offset SpaceOnTopDistance, mask PASCF_SPACE_ON_TOP,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SpaceOnBottomDistance, mask PASCF_SPACE_ON_BOTTOM,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

PASC_featuresList	GenControlFeaturesInfo	\
	<offset SpaceOnBottomDistance, SpaceOnBottomName, 0>,
	<offset SpaceOnTopDistance, SpaceOnTopName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

TextControlCommon ends

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaSpacingControlSetSpaceOnTop -- MSG_PASC_SET_SPACE_ON_TOP
						for ParaSpacingControlClass

DESCRIPTION:	Handle a change in theee "Plain" state

PASS:
	*ds:si - instance data
	es - segment of ParaSpacingControlClass
	ax - The message

	dx - spacing

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
ParaSpacingControlSetSpaceOnTop	method ParaSpacingControlClass,
						MSG_PASC_SET_SPACE_ON_TOP

	mov	ax, MSG_VIS_TEXT_SET_SPACE_ON_TOP
	GOTO	SendVisText_AX_DX_CX_Times_8_Common

ParaSpacingControlSetSpaceOnTop	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaSpacingControlSetSpaceOnBottom --
		MSG_PASC_SET_SPACE_ON_BOTTOM for ParaSpacingControlClass

DESCRIPTION:	Handle a change in theee "Plain" state

PASS:
	*ds:si - instance data
	es - segment of ParaSpacingControlClass
	ax - The message

	dx - spacing

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
ParaSpacingControlSetSpaceOnBottom	method ParaSpacingControlClass,
						MSG_PASC_SET_SPACE_ON_BOTTOM

	mov	ax, MSG_VIS_TEXT_SET_SPACE_ON_BOTTOM
	GOTO	SendVisText_AX_DX_CX_Times_8_Common

ParaSpacingControlSetSpaceOnBottom	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaSpacingControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for ParaSpacingControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of ParaSpacingControlClass

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
ParaSpacingControlUpdateUI	method dynamic ParaSpacingControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	mov	dx, es:VTNPAC_paraAttrDiffs.VTPAD_diffs

	; set spacing on top and bottom

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask PASCF_SPACE_ON_TOP
	jz	noSpaceOnTop
	mov	cx, {word} es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_spaceOnTop
	push	dx
	and	dx, mask VTPAF_MULTIPLE_TOP_SPACING
	mov	si, offset SpaceOnTopDistance
	call	SendRangeSetValueTimes8
	pop	dx
noSpaceOnTop:

	test	ax, mask PASCF_SPACE_ON_BOTTOM
	jz	noSpaceOnBottom
	mov	cx, {word} es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_spaceOnBottom
	and	dx, mask VTPAF_MULTIPLE_BOTTOM_SPACING
	mov	si, offset SpaceOnBottomDistance
	call	SendRangeSetValueTimes8
noSpaceOnBottom:

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

	ret

ParaSpacingControlUpdateUI	endm

TextControlCode ends

endif		; not NO_CONTROLLERS
