COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiGuideCreateControl.asm

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
	Code for the Guide Create controller

	$Id: uiGuideCreateControl.asm,v 1.1 97/04/07 10:43:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerUICode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GuideCreateControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GuideCreateControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GuideCreateControlClass

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
GuideCreateControlGetInfo	method dynamic	GuideCreateControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GCC_dupInfo
	call	CopyDupInfoCommon
	ret
GuideCreateControlGetInfo	endm

GCC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	GCC_IniFileKey,			; GCBI_initFileKey
	GCC_gcnList,			; GCBI_gcnList
	length GCC_gcnList,		; GCBI_gcnCount
	GCC_notifyList,			; GCBI_notificationList
	length GCC_notifyList,		; GCBI_notificationCount
	GCCName,			; GCBI_controllerName

	handle GuideCreateControlUI,	; GCBI_dupBlock
	GCC_childList,			; GCBI_childList
	length GCC_childList,		; GCBI_childCount
	GCC_featuresList,		; GCBI_featuresList
	length GCC_featuresList,	; GCBI_featuresCount

	GCC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	GCC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
RulerControlInfoXIP	segment resource
endif

GCC_helpContext	char	"dbGuideCreat", 0

GCC_IniFileKey	char	"GuideCreate", 0

GCC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_RULER_TYPE_CHANGE>

GCC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_RULER_TYPE_CHANGE>

;---


GCC_childList	GenControlChildInfo \
	<offset GuideCreateInteraction,	mask GCCF_HORIZONTAL_GUIDES or \
					mask GCCF_VERTICAL_GUIDES, 0>

GCC_featuresList	GenControlFeaturesInfo	\
	<offset	CreateHorizontalGuidelineTrigger, VGuideCreateName, 0>,
	<offset	CreateVerticalGuidelineTrigger, HGuideCreateName, 0>

if FULL_EXECUTE_IN_PLACE
RulerControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GuideCreateControlCreateGuide -- MSG_GCC_CREATE_VERTICAL_GUIDELINE
						for GuideCreateControlClass

DESCRIPTION:	Cretae a guideline

PASS:
	*ds:si - instance data
	es - segment of GuideCreateControlClass

	ax - The message

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
GuideCreateControlCreateVerticalGuideline	method dynamic	GuideCreateControlClass, MSG_GCC_CREATE_VERTICAL_GUIDELINE

	.enter
	;
	;	Sorry about the nomenclature, but a vertical *guideline* is
	;	actually a horizontal *guide*, since the guideline itself
	;	runs from the top of the screen to the bottom (it's vertical),
	;	but it guides your horizontal motion.
	;
	mov	ax, MSG_VIS_RULER_ADD_HORIZONTAL_GUIDE
	call	GuideCreateControlCreateGuidelineCommon

	.leave
	ret
GuideCreateControlCreateVerticalGuideline	endm

GuideCreateControlCreateHorizontalGuideline	method dynamic	GuideCreateControlClass, MSG_GCC_CREATE_HORIZONTAL_GUIDELINE

	.enter
	;
	;	Sorry about the nomenclature, but a horizontal *guideline* is
	;	actually a vertical *guide*, since the guideline itself
	;	runs from the top of the screen to the bottom (it's horizontal)
	;	but it guides your vertical motion.
	;
	mov	ax, MSG_VIS_RULER_ADD_VERTICAL_GUIDE
	call	GuideCreateControlCreateGuidelineCommon

	.leave
	ret
GuideCreateControlCreateHorizontalGuideline	endm

GuideCreateControlCreateGuidelineCommon		proc	near

	.enter

	push	ax,si				;save message, controller chunk

	call	GetChildBlock
	mov	si, offset GuideCreateValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	bx,si				;bx <- message, si <- chunk
	
	mov_tr	ax, dx
	cwd
	sub	sp, size DWFixed
	mov	bp, sp
	movdwf	ss:[bp], dxaxcx
	mov	dx, size DWFixed
	mov_tr	ax, bx				;ax <- message
	mov	bx, segment VisRulerClass
	mov	di, offset VisRulerClass
	call	GenControlOutputActionStack
	add	sp, size DWFixed
	.leave
	ret
GuideCreateControlCreateGuidelineCommon		endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GuideCreateControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GuideCreateControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GuideCreateControlClass
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
GuideCreateControlUpdateUI	method GuideCreateControlClass,
						MSG_GEN_CONTROL_UPDATE_UI
	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	cl, ds:[RTNB_type]
	call	MemUnlock

	call	ConvertVisRulerTypeToDisplayFormat

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset GuideCreateUnitsList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di, dx
	call	ObjMessage

	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cx, ax						;mark modified
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	clr	di
	call	ObjMessage

	.leave
	ret
GuideCreateControlUpdateUI	endm
RulerUICode	ends
