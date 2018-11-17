COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiDuplicateControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjDuplicateControlClass

	$Id: uiDuplicateControl.asm,v 1.1 97/04/04 18:06:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDuplicateControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjDuplicateControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjDuplicateControlClass

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
GrObjDuplicateControlGetInfo	method dynamic	GrObjDuplicateControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GrObjDuplicateControl_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjDuplicateControlGetInfo	endm

GrObjDuplicateControl_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GrObjDuplicateControl_IniFileKey,		; GCBI_initFileKey
	GrObjDuplicateControl_gcnList,			; GCBI_gcnList
	length GrObjDuplicateControl_gcnList,		; GCBI_gcnCount
	GrObjDuplicateControl_notifyList,		; GCBI_notificationList
	length GrObjDuplicateControl_notifyList,		; GCBI_notificationCount
	GrObjDuplicateControlName,			; GCBI_controllerName

	handle GrObjDuplicateControlUI,	; GCBI_dupBlock
	GrObjDuplicateControl_childList,			; GCBI_childList
	length GrObjDuplicateControl_childList,		; GCBI_childCount
	GrObjDuplicateControl_featuresList,		; GCBI_featuresList
	length GrObjDuplicateControl_featuresList,	; GCBI_featuresCount

	GROBJ_DUPLICATE_CONTROL_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	handle GrObjDuplicateToolControlUI,	; GCBI_dupBlock
	GrObjDuplicateControl_toolList,			; GCBI_childList
	length GrObjDuplicateControl_toolList,		; GCBI_childCount
	GrObjDuplicateControl_toolFeaturesList,		; GCBI_featuresList
	length GrObjDuplicateControl_toolFeaturesList,	; GCBI_featuresCount

	GROBJ_DUPLICATE_CONTROL_DEFAULT_TOOLBOX_FEATURES,	; GCBI_defaultFeatures
	GrObjDuplicateControl_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GrObjDuplicateControl_helpContext	char	"dbGrObjEdSpc", 0

GrObjDuplicateControl_IniFileKey	char	"GrObjDuplicate", 0

GrObjDuplicateControl_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GrObjDuplicateControl_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GrObjDuplicateControl_childList	GenControlChildInfo \
	<offset GrObjDuplicateTrigger, mask GODCF_DUPLICATE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjCloneTrigger, mask GODCF_DUPLICATE_IN_PLACE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GrObjDuplicateControl_featuresList	GenControlFeaturesInfo	\
	<offset GrObjCloneTrigger, CloneName, 0>,
	<offset GrObjDuplicateTrigger, DuplicateName, 0>

GrObjDuplicateControl_toolList	GenControlChildInfo \
	<offset GrObjDuplicateTool, mask GODCTF_DUPLICATE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjCloneTool, mask GODCTF_DUPLICATE_IN_PLACE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GrObjDuplicateControl_toolFeaturesList	GenControlFeaturesInfo	\
	<offset GrObjCloneTool, CloneName, 0>,
	<offset GrObjDuplicateTool, DuplicateName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDuplicateControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjDuplicateControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjDuplicateControlClass
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
GrObjDuplicateControlUpdateUI	method dynamic GrObjDuplicateControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	cx, 1
	mov	ax, mask GODCF_DUPLICATE_IN_PLACE
	mov	si, offset GrObjCloneTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	mov	ax, mask GODCTF_DUPLICATE_IN_PLACE
	mov	si, offset GrObjCloneTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	mov	ax, mask GODCF_DUPLICATE
	mov	si, offset GrObjDuplicateTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	mov	ax, mask GODCTF_DUPLICATE
	mov	si, offset GrObjDuplicateTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	.leave
	ret
GrObjDuplicateControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjDuplicateControlClone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjDuplicateControl method for MSG_GrObjDuplicateControl_CLONE

Called by:	

Pass:		*ds:si = GrObjDuplicateControl object
		ds:di = GrObjDuplicateControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDuplicateControlClone	method dynamic	GrObjDuplicateControlClass, MSG_GROBJ_DUPLICATE_CONTROL_DUPLICATE_IN_PLACE

	.enter
	mov	ax, MSG_GB_CLONE_SELECTED_GROBJS
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjDuplicateControlClone	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjDuplicateControlDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjDuplicateControl method for MSG_GrObjDuplicateControl_DUPLICATE

Called by:	

Pass:		*ds:si = GrObjDuplicateControl object
		ds:di = GrObjDuplicateControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDuplicateControlDuplicate	method dynamic	GrObjDuplicateControlClass, MSG_GROBJ_DUPLICATE_CONTROL_DUPLICATE

	.enter
	mov	ax, MSG_GB_DUPLICATE_SELECTED_GROBJS
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjDuplicateControlDuplicate	endm
GrObjUIControllerActionCode	ends
