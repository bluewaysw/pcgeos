COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiConvertControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjConvertControlClass

	$Id: uiConvertControl.asm,v 1.1 97/04/04 18:06:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjConvertControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjConvertControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjConvertControlClass

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
GrObjConvertControlGetInfo	method dynamic	GrObjConvertControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOCC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjConvertControlGetInfo	endm

GOCC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOCC_IniFileKey,		; GCBI_initFileKey
	GOCC_gcnList,		; GCBI_gcnList
	length GOCC_gcnList,		; GCBI_gcnCount
	GOCC_notifyList,		; GCBI_notificationList
	length GOCC_notifyList,		; GCBI_notificationCount
	GOCCName,			; GCBI_controllerName

	handle GrObjConvertControlUI,	; GCBI_dupBlock
	GOCC_childList,		; GCBI_childList
	length GOCC_childList,		; GCBI_childCount
	GOCC_featuresList,	; GCBI_featuresList
	length GOCC_featuresList,	; GCBI_featuresCount

	GOCC_DEFAULT_FEATURES,		; GCBI_features

	handle GrObjConvertToolControlUI,	; GCBI_dupBlock
	GOCC_toolList,			; GCBI_childList
	length GOCC_toolList,		; GCBI_childCount
	GOCC_toolFeaturesList,		; GCBI_featuresList
	length GOCC_toolFeaturesList,	; GCBI_featuresCount

	GOCC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_features
	GOCC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOCC_helpContext	char	"dbGrObjConvert", 0

GOCC_IniFileKey	char	"GrObjConvert", 0

GOCC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GOCC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GOCC_childList	GenControlChildInfo \
	<offset GrObjConvertToBitmapTrigger, mask GOCCF_CONVERT_TO_BITMAP, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjConvertToGraphicTrigger, mask GOCCF_CONVERT_TO_GRAPHIC, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjConvertFromGraphicTrigger, mask GOCCF_CONVERT_FROM_GRAPHIC, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOCC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjConvertFromGraphicTrigger, ConvertFromGraphicName, 0>,
	<offset GrObjConvertToGraphicTrigger, ConvertToGraphicName, 0>,
	<offset GrObjConvertToBitmapTrigger, ConvertToBitmapName, 0>

GOCC_toolList	GenControlChildInfo \
	<offset GrObjConvertToBitmapTool, mask GOCCF_CONVERT_TO_BITMAP, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjConvertToGraphicTool, mask GOCCF_CONVERT_TO_GRAPHIC, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjConvertFromGraphicTool, mask GOCCF_CONVERT_FROM_GRAPHIC, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOCC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset GrObjConvertFromGraphicTool, ConvertFromGraphicName, 0>,
	<offset GrObjConvertToGraphicTool, ConvertToGraphicName, 0>,
	<offset GrObjConvertToBitmapTool, ConvertToBitmapName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjConvertControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjConvertControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjConvertControlClass
	ax - MSG_GEN_CONTROL_UPDATE_UI



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
GrObjConvertControlUpdateUI	method dynamic GrObjConvertControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx

	.enter

	mov	cx, 1
	mov	ax, mask GOCCF_CONVERT_TO_BITMAP
	mov	si, offset GrObjConvertToBitmapTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	mov	si, offset GrObjConvertToBitmapTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	mov	ax, mask GOCCF_CONVERT_TO_GRAPHIC
	mov	si, offset GrObjConvertToGraphicTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	mov	si, offset GrObjConvertToGraphicTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	mov	cx, mask GSSF_UNGROUPABLE
	mov	ax, mask GOCCF_CONVERT_FROM_GRAPHIC
	mov	si, offset GrObjConvertFromGraphicTrigger
	call	GrObjControlUpdateUIBasedOnSelectionFlagsAndFeatureSet

	mov	si, offset GrObjConvertFromGraphicTool
	call	GrObjControlUpdateToolBasedOnSelectionFlagsAndToolboxFeatureSet

	.leave
	ret
GrObjConvertControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertControlConvertToBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjConvertControl method for MSG_GOCC_CONVERT_TO_BITMAP

Called by:	

Pass:		*ds:si = GrObjConvertControl object
		ds:di = GrObjConvertControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertControlConvertToBitmap	method dynamic	GrObjConvertControlClass,
				MSG_GOCC_CONVERT_TO_BITMAP

	.enter
	mov	ax, MSG_GB_CONVERT_SELECTED_GROBJS_TO_BITMAP
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjConvertControlConvertToBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertControlConvertToGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjConvertControl method for MSG_GOCC_CONVERT_TO_GRAPHIC

Called by:	

Pass:		*ds:si = GrObjConvertControl object
		ds:di = GrObjConvertControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertControlConvertToGraphic	method dynamic	GrObjConvertControlClass,
				MSG_GOCC_CONVERT_TO_GRAPHIC

	.enter

	mov	ax, MSG_GB_GROUP_SELECTED_GROBJS
	call	GrObjControlOutputActionRegsToBody

	.leave
	ret
GrObjConvertControlConvertToGraphic	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertControlConvertFromGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjConvertControl method for MSG_GOCC_CONVERT_FROM_GRAPHIC

Called by:	

Pass:		*ds:si = GrObjConvertControl object
		ds:di = GrObjConvertControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertControlConvertFromGraphic	method dynamic	GrObjConvertControlClass, MSG_GOCC_CONVERT_FROM_GRAPHIC

	.enter

	mov	ax, MSG_GB_UNGROUP_SELECTED_GROUPS
	call	GrObjControlOutputActionRegsToBody

	.leave
	ret
GrObjConvertControlConvertFromGraphic	endm

GrObjUIControllerActionCode	ends
