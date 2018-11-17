COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uirtctrl.asm

AUTHOR:		Jon Witort

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 feb 1992   	Initial version.

DESCRIPTION:
	Code for the Ruler Type controller

	$Id: uiRulerTypeControl.asm,v 1.1 97/04/07 10:42:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerUICode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerTypeControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for RulerTypeControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of RulerTypeControlClass

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
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
RulerTypeControlGetInfo	method dynamic	RulerTypeControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset RTC_dupInfo
	call	CopyDupInfoCommon
	ret
RulerTypeControlGetInfo	endm

RTC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	RTC_IniFileKey,			; GCBI_initFileKey
	RTC_gcnList,			; GCBI_gcnList
	length RTC_gcnList,		; GCBI_gcnCount
	RTC_notifyTypeList,		; GCBI_notificationList
	length RTC_notifyTypeList,	; GCBI_notificationCount
	RTCName,			; GCBI_controllerName

	handle RulerTypeControlUI,	; GCBI_dupBlock
	RTC_childList,			; GCBI_childList
	length RTC_childList,		; GCBI_childCount
	RTC_featuresList,		; GCBI_featuresList
	length RTC_featuresList,	; GCBI_featuresCount
	RTC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	RTC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
RulerControlInfoXIP	segment resource
endif

RTC_helpContext	char	"dbRulerType", 0

RTC_IniFileKey	char	"rulerType", 0

RTC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_RULER_TYPE_CHANGE>

RTC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_RULER_TYPE_CHANGE>

;---

RTC_childList	GenControlChildInfo \
	<offset RulerTypeList,	mask RTCF_INCHES or \
					mask RTCF_CENTIMETERS or \
					mask RTCF_POINTS or \
					mask RTCF_PICAS or \
					mask RTCF_SPREADSHEET or \
					mask RTCF_DEFAULT, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

RTC_featuresList	GenControlFeaturesInfo	\
	<offset	PicasEntry, PicasName, 0>,
	<offset	PointsEntry, PointsName, 0>,
	<offset	CentimetersEntry, CentimetersName, 0>,
	<offset	InchesEntry, InchesName, 0>,
	<offset SpreadsheetEntry, SpreadsheetName, 0>,
	<offset SysDefaultEntry, SysDefaultName, 0>

if FULL_EXECUTE_IN_PLACE
RulerControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerTypeControlTypeChange -- MSG_RTC_TYPE_CHANGE
						for RulerTypeControlClass

DESCRIPTION:	Update the UI stuff based on the setting of the
		RulerTypeControlFlags

PASS:
	*ds:si - instance data
	es - segment of RulerTypeControlClass

	ax - The message
	cl - new VisRulerType

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Only update on a USER change

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version
------------------------------------------------------------------------------@
RulerTypeControlTypeChange	method dynamic	RulerTypeControlClass,
						MSG_RTC_TYPE_CHANGE

	mov	ax, MSG_VIS_RULER_SET_TYPE
	mov	bx, segment VisRulerClass
	mov	di, offset VisRulerClass
	call	GenControlOutputActionRegs
	ret
RulerTypeControlTypeChange	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerTypeControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for RulerTypeControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of RulerTypeControlClass
	ax - MSG_GEN_CONTROL_UPDATE_UI

	ss:bp - GenControlUpdateUIParams

RETURN: nothing

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 feb 1992	Initial version
------------------------------------------------------------------------------@
RulerTypeControlUpdateUI	method RulerTypeControlClass,
						MSG_GEN_CONTROL_UPDATE_UI
	.enter
	mov	si, offset RulerTypeList
	call	UpdateRulerUnits
	.leave
	ret
RulerTypeControlUpdateUI	endm

RulerUICode	ends
