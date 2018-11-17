COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiRotateControl.asm

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
	Code for the GrObjRotateControlClass

	$Id: uiRotateControl.asm,v 1.1 97/04/04 18:05:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjRotateControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjRotateControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjRotateControlClass

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
GrObjRotateControlGetInfo	method dynamic	GrObjRotateControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GORC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjRotateControlGetInfo	endm

GORC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GORC_IniFileKey,		; GCBI_initFileKey
	GORC_gcnList,		; GCBI_gcnList
	length GORC_gcnList,		; GCBI_gcnCount
	GORC_notifyList,		; GCBI_notificationList
	length GORC_notifyList,		; GCBI_notificationCount
	GORCName,			; GCBI_controllerName

	handle GrObjRotateControlUI,	; GCBI_dupBlock
	GORC_childList,		; GCBI_childList
	length GORC_childList,		; GCBI_childCount
	GORC_featuresList,	; GCBI_featuresList
	length GORC_featuresList,	; GCBI_featuresCount

	GROBJ_ROTATE_CONTROL_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	GORC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GORC_helpContext	char	"dbGrObjRot", 0

GORC_IniFileKey	char	"GrObjRotate", 0

GORC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GORC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---

GORC_childList	GenControlChildInfo \
	<offset GrObjRotate45DegreesCWTrigger, mask GORCF_45_DEGREES_CW, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjRotate90DegreesCWTrigger, mask GORCF_90_DEGREES_CW, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjRotate135DegreesCWTrigger, mask GORCF_135_DEGREES_CW, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjRotate180DegreesTrigger, mask GORCF_180_DEGREES, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjRotate135DegreesCCWTrigger, mask GORCF_135_DEGREES_CCW, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjRotate90DegreesCCWTrigger, mask GORCF_90_DEGREES_CCW, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjRotate45DegreesCCWTrigger, mask GORCF_45_DEGREES_CCW, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjCustomRotateInteraction, mask GORCF_CUSTOM_ROTATION, mask GCCF_IS_DIRECTLY_A_FEATURE>

GORC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjCustomRotateInteraction, GORCCustomName, 0>,
	<offset GrObjRotate45DegreesCCWTrigger, GORC45CCWName, 0>,
	<offset GrObjRotate90DegreesCCWTrigger, GORC90CCWName, 0>,
	<offset GrObjRotate135DegreesCCWTrigger, GORC135CCWName, 0>,
	<offset GrObjRotate180DegreesTrigger, GORC180Name, 0>,
	<offset GrObjRotate135DegreesCWTrigger, GORC135CWName, 0>,
	<offset GrObjRotate90DegreesCWTrigger, GORC90CWName, 0>,
	<offset GrObjRotate45DegreesCWTrigger, GORC45CWName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjRotateControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjRotateControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjRotateControlClass
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
GrObjRotateControlUpdateUI	method GrObjRotateControlClass,
						MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	cx, 1
	mov	dx, mask GOL_ROTATE

	mov	ax, mask GORCF_45_DEGREES_CW
	mov	si, offset GrObjRotate45DegreesCWTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GORCF_90_DEGREES_CW
	mov	si, offset GrObjRotate90DegreesCWTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GORCF_135_DEGREES_CW
	mov	si, offset GrObjRotate135DegreesCWTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GORCF_180_DEGREES
	mov	si, offset GrObjRotate180DegreesTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GORCF_135_DEGREES_CCW
	mov	si, offset GrObjRotate135DegreesCCWTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GORCF_90_DEGREES_CCW
	mov	si, offset GrObjRotate90DegreesCCWTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GORCF_45_DEGREES_CCW
	mov	si, offset GrObjRotate45DegreesCCWTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GORCF_CUSTOM_ROTATION
	mov	si, offset GrObjCustomRotateReplyApply
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	.leave
	ret
GrObjRotateControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjRotateControlRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjRotateControl method for MSG_GORC_ROTATE

Called by:	

Pass:		*ds:si = GrObjRotateControl object
		ds:di = GrObjRotateControl instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjRotateControlRotate	method dynamic	GrObjRotateControlClass,
				MSG_GORC_ROTATE
	uses	cx, dx, bp
	.enter

	xchg	cx, dx					;dx:cx <- wwf degrees
	clr	bp					;rotate about center
	mov	ax, MSG_GO_ROTATE
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjRotateControlRotate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjRotateControlCustomRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjRotateControl method for MSG_GORC_CUSTOM_ROTATE

Called by:	

Pass:		*ds:si = GrObjRotateControl object
		ds:di = GrObjRotateControl instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjRotateControlCustomRotate	method dynamic	GrObjRotateControlClass,
				MSG_GORC_CUSTOM_ROTATE
	uses	cx, dx, bp
	.enter

	call	GetChildBlockAndFeatures
	test	ax, mask GORCF_CUSTOM_ROTATION
	jz	done

	push	si
	mov	si, offset GrObjCustomRotateValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	xchg	cx, dx
	clr	bp					;rotate about center
	mov	ax, MSG_GO_ROTATE
	call	GrObjControlOutputActionRegsToGrObjs

done:
	.leave
	ret
GrObjRotateControlCustomRotate	endm

GrObjUIControllerActionCode	ends
