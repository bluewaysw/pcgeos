COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiGroupControl.asm

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
	Code for the GrObjGroupControlClass

	$Id: uiGroupControl.asm,v 1.1 97/04/04 18:05:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjGroupControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjGroupControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjGroupControlClass

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
GrObjGroupControlGetInfo	method dynamic	GrObjGroupControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOGC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjGroupControlGetInfo	endm

GOGC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOGC_IniFileKey,		; GCBI_initFileKey
	GOGC_gcnList,		; GCBI_gcnList
	length GOGC_gcnList,		; GCBI_gcnCount
	GOGC_notifyList,		; GCBI_notificationList
	length GOGC_notifyList,		; GCBI_notificationCount
	GOGCName,			; GCBI_controllerName

	handle GrObjGroupControlUI,	; GCBI_dupBlock
	GOGC_childList,		; GCBI_childList
	length GOGC_childList,		; GCBI_childCount
	GOGC_featuresList,	; GCBI_featuresList
	length GOGC_featuresList,	; GCBI_featuresCount

	GOGC_DEFAULT_FEATURES,		; GCBI_features

	handle GrObjGroupToolControlUI,	; GCBI_dupBlock
	GOGC_toolList,			; GCBI_childList
	length GOGC_toolList,		; GCBI_childCount
	GOGC_toolFeaturesList,		; GCBI_featuresList
	length GOGC_toolFeaturesList,	; GCBI_featuresCount

	GOGC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_features
	GOGC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOGC_helpContext	char	"dbGrObjGroup", 0

GOGC_IniFileKey	char	"GrObjGroup", 0

GOGC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GOGC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GOGC_childList	GenControlChildInfo \
	<offset GrObjGroupTrigger, mask GOGCF_GROUP, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjUngroupTrigger, mask GOGCF_UNGROUP, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOGC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjUngroupTrigger, UngroupName, 0>,
	<offset GrObjGroupTrigger, GroupName, 0>

GOGC_toolList	GenControlChildInfo \
	<offset GrObjGroupTool, mask GOGCF_GROUP, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjUngroupTool, mask GOGCF_UNGROUP, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOGC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset GrObjUngroupTool, UngroupName, 0>,
	<offset GrObjGroupTool, GroupName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjGroupControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjGroupControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjGroupControlClass
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
GrObjGroupControlUpdateUI	method dynamic GrObjGroupControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx, dx

	.enter

	mov	cx, 2
	mov	ax, mask GOGCF_GROUP
	mov	dx, mask GOL_GROUP
	mov	si, offset GrObjGroupTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear

	mov	si, offset GrObjGroupTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSetAndLocksClear

	mov	cx, mask GSSF_UNGROUPABLE
	mov	ax, mask GOGCF_UNGROUP
	mov	si, offset GrObjUngroupTrigger
	call	GrObjControlUpdateUIBasedOnSelectionFlagsAndFeatureSet

	mov	si, offset GrObjUngroupTool
	call	GrObjControlUpdateToolBasedOnSelectionFlagsAndToolboxFeatureSet

	.leave
	ret
GrObjGroupControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjGroupControlGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjGroupControl method for MSG_GOGC_GROUP

Called by:	

Pass:		*ds:si = GrObjGroupControl object
		ds:di = GrObjGroupControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGroupControlGroup	method dynamic	GrObjGroupControlClass, MSG_GOGC_GROUP

	.enter
	mov	ax, MSG_GB_GROUP_SELECTED_GROBJS
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjGroupControlGroup	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjGroupControlUngroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjGroupControl method for MSG_GOGC_UNGROUP

Called by:	

Pass:		*ds:si = GrObjGroupControl object
		ds:di = GrObjGroupControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGroupControlUngroup	method dynamic	GrObjGroupControlClass,
				MSG_GOGC_UNGROUP

	.enter

	mov	ax, MSG_GB_UNGROUP_SELECTED_GROUPS
	call	GrObjControlOutputActionRegsToBody

	.leave
	ret
GrObjGroupControlUngroup	endm

GrObjUIControllerActionCode	ends
