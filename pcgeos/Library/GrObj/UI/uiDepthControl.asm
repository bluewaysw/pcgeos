COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiDepthControl.asm

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
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjDepthControlClass

	$Id: uiDepthControl.asm,v 1.1 97/04/04 18:05:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDepthControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjDepthControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjDepthControlClass

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
GrObjDepthControlGetInfo	method dynamic	GrObjDepthControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GODepthC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjDepthControlGetInfo	endm

GODepthC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GODepthC_IniFileKey,			; GCBI_initFileKey
	GODepthC_gcnList,			; GCBI_gcnList
	length GODepthC_gcnList,		; GCBI_gcnCount
	GODepthC_notifyList,			; GCBI_notificationList
	length GODepthC_notifyList,		; GCBI_notificationCount
	GODepthCName,				; GCBI_controllerName

	handle GrObjDepthControlUI,		; GCBI_dupBlock
	GODepthC_childList,			; GCBI_childList
	length GODepthC_childList,		; GCBI_childCount
	GODepthC_featuresList,			; GCBI_featuresList
	length GODepthC_featuresList,		; GCBI_featuresCount

	GODepthC_DEFAULT_FEATURES,			; GCBI_features

	handle GrObjDepthToolControlUI,
	GODepthC_toolList,
	length GODepthC_toolList,
	GODepthC_toolFeaturesList,
	length GODepthC_toolFeaturesList,
	GODepthC_DEFAULT_TOOLBOX_FEATURES,
	GODepthC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GODepthC_helpContext	char	"dbGrObjDepth", 0

GODepthC_IniFileKey	char	"GrObjDepth", 0

GODepthC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GODepthC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GODepthC_childList	GenControlChildInfo \
	<offset GrObjBringToFrontTrigger, mask GODepthCF_BRING_TO_FRONT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjSendToBackTrigger, mask GODepthCF_SEND_TO_BACK, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjShuffleUpTrigger, mask GODepthCF_SHUFFLE_UP, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjShuffleDownTrigger, mask GODepthCF_SHUFFLE_DOWN, mask GCCF_IS_DIRECTLY_A_FEATURE>

GODepthC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjShuffleDownTrigger, GrObjShuffleDownName, 0>,
	<offset GrObjShuffleUpTrigger, GrObjShuffleUpName, 0>,
	<offset GrObjSendToBackTrigger, GrObjSendToBackName, 0>,
	<offset GrObjBringToFrontTrigger, GrObjBringToFrontName, 0>

GODepthC_toolList	GenControlChildInfo \
	<offset GrObjBringToFrontTool, mask GODepthCF_BRING_TO_FRONT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjSendToBackTool, mask GODepthCF_SEND_TO_BACK, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjShuffleUpTool, mask GODepthCF_SHUFFLE_UP, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjShuffleDownTool, mask GODepthCF_SHUFFLE_DOWN, mask GCCF_IS_DIRECTLY_A_FEATURE>

GODepthC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset GrObjShuffleDownTool, GrObjShuffleDownName, 0>,
	<offset GrObjShuffleUpTool, GrObjShuffleUpName, 0>,
	<offset GrObjSendToBackTool, GrObjSendToBackName, 0>,
	<offset GrObjBringToFrontTool, GrObjBringToFrontName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDepthControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjDepthControlClass

DESCRIPTION:	Handle notification of type change

PASS:
		*ds:si - instance data
		es - segment of GrObjDepthControlClass
		ax - MSG_GEN_CONTROL_UPDATE_UI

		ss:bp - GenControlUpdateUIParams

RETURN: 	nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 feb 1992	Initial version
------------------------------------------------------------------------------@
GrObjDepthControlUpdateUI	method dynamic GrObjDepthControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	cx, 1

	mov	ax, mask GODepthCF_BRING_TO_FRONT
	mov	si, offset GrObjBringToFrontTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	si, offset GrObjBringToFrontTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	mov	ax, mask GODepthCF_SEND_TO_BACK
	mov	si, offset GrObjSendToBackTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	si, offset GrObjSendToBackTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	mov	ax, mask GODepthCF_SHUFFLE_UP
	mov	si, offset GrObjShuffleUpTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	si, offset GrObjShuffleUpTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	mov	ax, mask GODepthCF_SHUFFLE_DOWN
	mov	si, offset GrObjShuffleDownTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	si, offset GrObjShuffleDownTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	.leave
	ret
GrObjDepthControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjDepthControlBringToFront
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjDepthControl method for MSG_GODC_BRING_TO_FRONT

Called by:	UI

Pass:		*ds:si = GrObjDepthControl object
		ds:di = GrObjDepthControl instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDepthControlBringToFront	method	GrObjDepthControlClass,
				MSG_GODC_BRING_TO_FRONT
	.enter
	mov	ax, MSG_GB_PULL_SELECTED_GROBJS_TO_FRONT
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjDepthControlBringToFront	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjDepthControlSendToBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjDepthControl method for MSG_GODC_SEND_TO_BACK

Called by:	UI

Pass:		*ds:si = GrObjDepthControl object
		ds:di = GrObjDepthControl instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDepthControlSendToBack	method dynamic	GrObjDepthControlClass,
				MSG_GODC_SEND_TO_BACK
	.enter
	mov	ax, MSG_GB_PUSH_SELECTED_GROBJS_TO_BACK
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjDepthControlSendToBack	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjDepthControlShuffleUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjDepthControl method for MSG_GODC_SHUFFLE_UP

Called by:	UI

Pass:		*ds:si = GrObjDepthControl object
		ds:di = GrObjDepthControl instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDepthControlShuffleUp	method dynamic	GrObjDepthControlClass,
				MSG_GODC_SHUFFLE_UP
	.enter
	mov	ax, MSG_GB_SHUFFLE_SELECTED_GROBJS_UP
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjDepthControlShuffleUp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjDepthControlShuffleDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjDepthControl method for MSG_GODC_SHUFFLE_DOWN

Called by:	UI

Pass:		*ds:si = GrObjDepthControl object
		ds:di = GrObjDepthControl instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDepthControlShuffleDown	method dynamic	GrObjDepthControlClass,
				MSG_GODC_SHUFFLE_DOWN
	.enter
	mov	ax, MSG_GB_SHUFFLE_SELECTED_GROBJS_DOWN
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjDepthControlShuffleDown	endm

GrObjUIControllerActionCode	ends
