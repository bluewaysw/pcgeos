COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiDefaultTabsControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	DefaultTabsControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement DefaultTabsControlClass

	$Id: uiDefaultTabs.asm,v 1.1 97/04/07 11:17:15 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	DefaultTabsControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	DefaultTabsControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for DefaultTabsControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of DefaultTabsControlClass

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
DefaultTabsControlGetInfo	method dynamic	DefaultTabsControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset DTC_dupInfo
	GOTO	CopyDupInfoCommon

DefaultTabsControlGetInfo	endm

DTC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	DTC_IniFileKey,			; GCBI_initFileKey
	DTC_gcnList,			; GCBI_gcnList
	length DTC_gcnList,		; GCBI_gcnCount
	DTC_notifyTypeList,		; GCBI_notificationList
	length DTC_notifyTypeList,	; GCBI_notificationCount
	DTCName,			; GCBI_controllerName

	handle DefaultTabsControlUI,	; GCBI_dupBlock
	DTC_childList,			; GCBI_childList
	length DTC_childList,		; GCBI_childCount
	DTC_featuresList,		; GCBI_featuresList
	length DTC_featuresList,	; GCBI_featuresCount
	DTC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	DTC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	DTC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

DTC_helpContext	char	"dbDefTab", 0

DTC_IniFileKey	char	"paraSpacing", 0

DTC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>

DTC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>

;---

DTC_childList	GenControlChildInfo	\
	<offset DefaultTabsList, mask DTCF_LIST,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DefaultTabsDistance, mask DTCF_CUSTOM,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

DTC_featuresList	GenControlFeaturesInfo	\
	<offset DefaultTabsDistance, DefaultTabCustomName, 0>,
	<offset DefaultTabsList, DefaultTabListName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

TextControlCommon ends

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	DefaultTabsControlSetDefaultTabs -- MSG_DTC_SET_DEFAULT_TABS
						for DefaultTabsControlClass

DESCRIPTION:	Handle a change in theee "Plain" state

PASS:
	*ds:si - instance data
	es - segment of DefaultTabsControlClass

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
DefaultTabsControlSetDefaultTabsViaList	method DefaultTabsControlClass,
					MSG_DTC_SET_DEFAULT_TABS_VIA_LIST

	mov	ax, MSG_VIS_TEXT_SET_DEFAULT_TABS
	GOTO	SendVisText_AX_CX_Common

DefaultTabsControlSetDefaultTabsViaList	endm

;---

DefaultTabsControlSetDefaultTabs	method DefaultTabsControlClass,
						MSG_DTC_SET_DEFAULT_TABS

	mov	ax, MSG_VIS_TEXT_SET_DEFAULT_TABS
	GOTO	SendVisText_AX_DX_CX_Times_8_Common

DefaultTabsControlSetDefaultTabs	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DefaultTabsControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for DefaultTabsControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of DefaultTabsControlClass

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
DefaultTabsControlUpdateUI	method dynamic DefaultTabsControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax
	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_defaultTabs
	mov	dx, es:VTNPAC_paraAttrDiffs.VTPAD_diffs
	and	dx, mask VTPAF_MULTIPLE_DEFAULT_TABS
	call	MemUnlock

	; set list

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask DTCF_LIST
	jz	noList
	mov	si, offset DefaultTabsList
	call	SendListSetExcl
noList:

	; set custom range

	test	ax, mask DTCF_CUSTOM
	jz	noCustom
	mov	si, offset DefaultTabsDistance
	call	SendRangeSetValueTimes8
noCustom:

	ret

DefaultTabsControlUpdateUI	endm

TextControlCode ends

endif		; not NO_CONTROLLERS
