COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiFlipControl.asm

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
	Code for the GrObjFlipControlClass

	$Id: uiFlipControl.asm,v 1.1 97/04/04 18:06:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjFlipControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjFlipControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjFlipControlClass

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
GrObjFlipControlGetInfo	method dynamic	GrObjFlipControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOFlipC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjFlipControlGetInfo	endm

GOFlipC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOFC_IniFileKey,			; GCBI_initFileKey
	GOFC_gcnList,				; GCBI_gcnList
	length GOFC_gcnList,			; GCBI_gcnCount
	GOFC_notifyList,			; GCBI_notificationList
	length GOFC_notifyList,			; GCBI_notificationCount
	GOFCName,				; GCBI_controllerName

	handle GrObjFlipControlUI,		; GCBI_dupBlock
	GOFC_childList,				; GCBI_childList
	length GOFC_childList,			; GCBI_childCount
	GOFC_featuresList,			; GCBI_featuresList
	length GOFC_featuresList,		; GCBI_featuresCount

	GOFC_DEFAULT_FEATURES,			; GCBI_features

	handle GrObjFlipToolControlUI,
	GOFC_toolList,
	length GOFC_toolList,
	GOFC_toolFeaturesList,
	length GOFC_toolFeaturesList,
	GOFC_DEFAULT_TOOLBOX_FEATURES,
	GOFC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOFC_helpContext	char	"dbGrObjFlip", 0

GOFC_IniFileKey	char	"GrObjFlip", 0

GOFC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GOFC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GOFC_childList	GenControlChildInfo \
	<offset GrObjFlipHorizontallyTrigger, mask GOFCF_FLIP_HORIZONTALLY, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjFlipVerticallyTrigger, mask GOFCF_FLIP_VERTICALLY, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOFC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjFlipVerticallyTrigger, GrObjFlipVerticallyName, 0>,
	<offset GrObjFlipHorizontallyTrigger, GrObjFlipHorizontallyName, 0>

GOFC_toolList	GenControlChildInfo \
	<offset GrObjFlipHorizontallyTool, mask GOFCF_FLIP_HORIZONTALLY, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjFlipVerticallyTool, mask GOFCF_FLIP_VERTICALLY, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOFC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset GrObjFlipVerticallyTool, GrObjFlipVerticallyName, 0>,
	<offset GrObjFlipHorizontallyTool, GrObjFlipHorizontallyName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjFlipControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjFlipControlClass

DESCRIPTION:	Handle notification of type change

PASS:
		*ds:si - instance data
		es - segment of GrObjFlipControlClass
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
GrObjFlipControlUpdateUI	method dynamic GrObjFlipControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	cx, 1

	mov	ax, mask GOFCF_FLIP_HORIZONTALLY
	mov	si, offset GrObjFlipHorizontallyTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	si, offset GrObjFlipHorizontallyTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	mov	ax, mask GOFCF_FLIP_VERTICALLY
	mov	si, offset GrObjFlipVerticallyTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	si, offset GrObjFlipVerticallyTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	.leave
	ret
GrObjFlipControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjFlipControlFlipHorizontally
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjFlipControl method for MSG_GODC_BRING_TO_FRONT

Called by:	UI

Pass:		*ds:si = GrObjFlipControl object
		ds:di = GrObjFlipControl instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjFlipControlFlipHorizontally	method dynamic	GrObjFlipControlClass,
					MSG_GOFC_FLIP_HORIZONTALLY
	.enter

	mov	ax, MSG_GO_FLIP_HORIZ
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjFlipControlFlipHorizontally	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjFlipControlFlipVertically
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjFlipControl method for MSG_GODC_BRING_TO_FRONT

Called by:	UI

Pass:		*ds:si = GrObjFlipControl object
		ds:di = GrObjFlipControl instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjFlipControlFlipVertically	method dynamic	GrObjFlipControlClass,
					MSG_GOFC_FLIP_VERTICALLY
	.enter

	mov	ax, MSG_GO_FLIP_VERT
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjFlipControlFlipVertically	endm

GrObjUIControllerActionCode	ends
