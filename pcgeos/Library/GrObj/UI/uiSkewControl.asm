COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiSkewControl.asm

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
	Code for the GrObjSkewControlClass

	$Id: uiSkewControl.asm,v 1.1 97/04/04 18:05:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjSkewControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjSkewControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjSkewControlClass

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
GrObjSkewControlGetInfo	method dynamic	GrObjSkewControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GrObjSkewControl_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjSkewControlGetInfo	endm

GrObjSkewControl_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GrObjSkewControl_IniFileKey,		; GCBI_initFileKey
	GrObjSkewControl_gcnList,		; GCBI_gcnList
	length GrObjSkewControl_gcnList,		; GCBI_gcnCount
	GrObjSkewControl_notifyList,		; GCBI_notificationList
	length GrObjSkewControl_notifyList,		; GCBI_notificationCount
	GrObjSkewControlName,			; GCBI_controllerName

	handle GrObjSkewControlUI,	; GCBI_dupBlock
	GrObjSkewControl_childList,		; GCBI_childList
	length GrObjSkewControl_childList,		; GCBI_childCount
	GrObjSkewControl_featuresList,	; GCBI_featuresList
	length GrObjSkewControl_featuresList,	; GCBI_featuresCount

	GROBJ_SKEW_CONTROL_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	GrObjSkewControl_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GrObjSkewControl_helpContext	char	"dbGrObjSkew", 0

GrObjSkewControl_IniFileKey	char	"GrObjSkew", 0

GrObjSkewControl_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GrObjSkewControl_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---

GrObjSkewControl_childList	GenControlChildInfo \
	<offset GrObjSkewLeftTrigger, mask GOSCF_LEFT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjSkewRightTrigger, mask GOSCF_RIGHT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjSkewUpTrigger, mask GOSCF_UP, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjSkewDownTrigger, mask GOSCF_DOWN, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjCustomSkewInteraction, mask GOSCF_CUSTOM_SKEW, mask GCCF_IS_DIRECTLY_A_FEATURE>

GrObjSkewControl_featuresList	GenControlFeaturesInfo	\
	<offset GrObjCustomSkewInteraction, GrObjSkewControlCustomName, 0>,
	<offset GrObjSkewDownTrigger, GrObjSkewControlDownName, 0>,
	<offset GrObjSkewUpTrigger, GrObjSkewControlUpName, 0>,
	<offset GrObjSkewRightTrigger, GrObjSkewControlRightName, 0>,
	<offset GrObjSkewLeftTrigger, GrObjSkewControlLeftName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjSkewControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjSkewControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjSkewControlClass
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
GrObjSkewControlUpdateUI	method GrObjSkewControlClass,
						MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	cx, 1
	mov	dx, mask GOL_SKEW


	mov	ax, mask GOSCF_LEFT
	mov	si, offset GrObjSkewLeftTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GOSCF_RIGHT
	mov	si, offset GrObjSkewRightTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GOSCF_UP
	mov	si, offset GrObjSkewUpTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GOSCF_DOWN
	mov	si, offset GrObjSkewDownTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GOSCF_CUSTOM_SKEW
	mov	si, offset GrObjCustomSkewReplyApply
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	.leave
	ret
GrObjSkewControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjSkewControlSkewHorizontally
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjSkewControl method for MSG_GOSC_SKEW_HORIZONTALLY

Called by:	

Pass:		*ds:si = GrObjSkewControl object
		ds:di = GrObjSkewControl instance
		dx.cx - degrees

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSkewControlSkewHorizontally	method	GrObjSkewControlClass,
					MSG_GOSC_SKEW_HORIZONTALLY
	.enter

	clrwwf	bxax
	call	OutputSkewCommon

	.leave
	ret
GrObjSkewControlSkewHorizontally	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjSkewControlSkewVertically
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjSkewControl method for MSG_GOSC_SKEW_VERTICALLY

Called by:	

Pass:		*ds:si = GrObjSkewControl object
		ds:di = GrObjSkewControl instance
		dx.cx - degrees

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSkewControlSkewVertically	method	GrObjSkewControlClass,
					MSG_GOSC_SKEW_VERTICALLY
	uses	cx, dx
	.enter

	movwwf	bxax, dxcx
	clrwwf	dxcx
	call	OutputSkewCommon

	.leave
	ret
GrObjSkewControlSkewVertically	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			OutputSkewCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Common code for the MSG_GOSC_SKEW_### methods

Called by:	

Pass:		*ds:si = GrObjSkewControl object
		ds:di = GrObjSkewControl instance

		dxcx = wwf x degrees
		bxax = wwf y degrees

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutputSkewCommon	proc	near
	uses	ax, cx, dx, bp
	.enter

CheckHack	<size GrObjSkewData eq 8>
	pushwwf	bxax
	pushwwf	dxcx
	mov	bp, sp
	mov	dx, size GrObjSkewData
	mov	ax, MSG_GO_SKEW
	call	GrObjControlOutputActionStackToGrObjs
	add	sp, size GrObjSkewData

	.leave
	ret
OutputSkewCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjSkewControlCustomSkew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjSkewControl method for MSG_GOSC_CUSTOM_SKEW

Called by:	

Pass:		*ds:si = GrObjSkewControl object
		ds:di = GrObjSkewControl instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSkewControlCustomSkew	method	GrObjSkewControlClass,
				MSG_GOSC_CUSTOM_SKEW
	.enter

	call	GetChildBlockAndFeatures
	test	ax, mask GOSCF_CUSTOM_SKEW
	jz	done

	push	si
	mov	si, offset GrObjCustomSkewVValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si
	pushwwf	dxcx

	push	si
	mov	si, offset GrObjCustomSkewHValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si
	pushwwf	dxcx

	mov	bp, sp
CheckHack <size GrObjSkewData eq (2 * size WWFixed)>
	mov	dx, size GrObjSkewData
	mov	ax, MSG_GO_SKEW
	call	GrObjControlOutputActionStackToGrObjs
	add	sp, size GrObjSkewData

done:
	.leave
	ret
GrObjSkewControlCustomSkew	endm


GrObjUIControllerActionCode	ends
