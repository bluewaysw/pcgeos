COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiDefaultAttributesControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjDefaultAttributesControlClass

	$Id: uiDefaultAttributesControl.asm,v 1.1 97/04/04 18:06:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDefaultAttributesControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjDefaultAttributesControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjDefaultAttributesControlClass

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
GrObjDefaultAttributesControlGetInfo	method dynamic	GrObjDefaultAttributesControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GODAC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjDefaultAttributesControlGetInfo	endm

GODAC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GODAC_IniFileKey,		; GCBI_initFileKey
	GODAC_gcnList,			; GCBI_gcnList
	length GODAC_gcnList,		; GCBI_gcnCount
	GODAC_notifyList,		; GCBI_notificationList
	length GODAC_notifyList,		; GCBI_notificationCount
	GODACName,			; GCBI_controllerName

	handle GrObjDefaultAttributesControlUI,	; GCBI_dupBlock
	GODAC_childList,			; GCBI_childList
	length GODAC_childList,		; GCBI_childCount
	GODAC_featuresList,		; GCBI_featuresList
	length GODAC_featuresList,	; GCBI_featuresCount

	GODAC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	handle GrObjDefaultAttributesToolControlUI,	; GCBI_dupBlock
	GODAC_toolList,			; GCBI_childList
	length GODAC_toolList,		; GCBI_childCount
	GODAC_toolFeaturesList,		; GCBI_featuresList
	length GODAC_toolFeaturesList,	; GCBI_featuresCount

	GODAC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_defaultFeatures
	GODAC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GODAC_helpContext	char	"dbGrObjDefAt", 0

GODAC_IniFileKey	char	"GrObjDefaultAttributes", 0

GODAC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GODAC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GODAC_childList	GenControlChildInfo \
	<offset GrObjSetDefaultAttributesTrigger, mask GODACF_SET_DEFAULT_ATTRIBUTES, mask GCCF_IS_DIRECTLY_A_FEATURE>

GODAC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjSetDefaultAttributesTrigger, SetDefaultAttributesName, 0>

GODAC_toolList	GenControlChildInfo \
	<offset GrObjSetDefaultAttributesTool, mask GODACF_SET_DEFAULT_ATTRIBUTES, mask GCCF_IS_DIRECTLY_A_FEATURE>

GODAC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset GrObjSetDefaultAttributesTool, SetDefaultAttributesName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDefaultAttributesControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjDefaultAttributesControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjDefaultAttributesControlClass
	ax - MSG_GEN_CONTROL_UPDATE_UI



RETURN: 	nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

	Set the UI enabled if exactly one object (not a group) is selected.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 feb 1992	Initial version
------------------------------------------------------------------------------@
GrObjDefaultAttributesControlUpdateUI	method dynamic GrObjDefaultAttributesControlClass, MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	cx, 1
	mov	ax, mask GODACF_SET_DEFAULT_ATTRIBUTES
	mov	si, offset GrObjSetDefaultAttributesTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	mov	si, offset GrObjSetDefaultAttributesTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	.leave
	ret
GrObjDefaultAttributesControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDefaultAttributesControlSetDefaultAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjDefaultAttributesControl method for
		MSG_GODAC_SET_DEFAULT_ATTRIBUTES

Called by:	

Pass:		*ds:si = GrObjDefaultAttributesControl object
		ds:di = GrObjDefaultAttributesControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDefaultAttributesControlSetDefaultAttributes	method dynamic	GrObjDefaultAttributesControlClass, MSG_GODAC_SET_DEFAULT_ATTRIBUTES

	.enter

	mov	ax, MSG_GO_MAKE_ATTRS_DEFAULT
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjDefaultAttributesControlSetDefaultAttributes	endm

GrObjUIControllerActionCode	ends
