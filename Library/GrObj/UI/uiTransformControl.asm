COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiTransformControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjTransformControlClass

	$Id: uiTransformControl.asm,v 1.1 97/04/04 18:06:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjTransformControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjTransformControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjTransformControlClass

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
GrObjTransformControlGetInfo	method dynamic	GrObjTransformControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOTransformC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjTransformControlGetInfo	endm

GOTransformC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOTransformC_IniFileKey,		; GCBI_initFileKey
	GOTransformC_gcnList,			; GCBI_gcnList
	length GOTransformC_gcnList,		; GCBI_gcnCount
	GOTransformC_notifyList,		; GCBI_notificationList
	length GOTransformC_notifyList,		; GCBI_notificationCount
	GOTransformCName,			; GCBI_controllerName

	handle GrObjTransformControlUI,	; GCBI_dupBlock
	GOTransformC_childList,			; GCBI_childList
	length GOTransformC_childList,		; GCBI_childCount
	GOTransformC_featuresList,		; GCBI_featuresList
	length GOTransformC_featuresList,	; GCBI_featuresCount

	GOTransformC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	0,	; GCBI_dupBlock
	0,	; GCBI_childList
	0,	; GCBI_childCount
	0,	; GCBI_featuresList
	0,	; GCBI_featuresCount

	0,	; GCBI_defaultFeatures
	GOTransformC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOTransformC_helpContext	char	"dbGrObjTrans", 0

GOTransformC_IniFileKey	char	"GrObjTransform", 0

GOTransformC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GOTransformC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GOTransformC_childList	GenControlChildInfo \
	<offset GrObjUntransformTrigger, mask GOTCF_UNTRANSFORM, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOTransformC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjUntransformTrigger, UntransformName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjTransformControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjTransformControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjTransformControlClass
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
GrObjTransformControlUpdateUI	method dynamic GrObjTransformControlClass,
				MSG_GEN_CONTROL_UPDATE_UI
	uses	cx
	.enter


	mov	si, offset GrObjUntransformTrigger
	mov	cx, 1
	mov	ax, mask GOTCF_UNTRANSFORM
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	.leave
	ret
GrObjTransformControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjTransformControlUntransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjTransformControl method for MSG_GOTC_UNTRANSFORM

Called by:	

Pass:		*ds:si = GrObjTransformControl object
		ds:di = GrObjTransformControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTransformControlUntransform  method dynamic  GrObjTransformControlClass,
				  MSG_GOTC_UNTRANSFORM
	.enter

	mov	ax, MSG_GO_UNTRANSFORM
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjTransformControlUntransform	endm

GrObjUIControllerActionCode	ends
