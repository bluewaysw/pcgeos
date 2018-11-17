COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiScaleControl.asm

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
	Code for the GrObjScaleControlClass

	$Id: uiScaleControl.asm,v 1.1 97/04/04 18:06:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjScaleControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjScaleControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjScaleControlClass

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
GrObjScaleControlGetInfo	method dynamic	GrObjScaleControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GrObjScaleControl_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjScaleControlGetInfo	endm

GrObjScaleControl_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GrObjScaleControl_IniFileKey,		; GCBI_initFileKey
	GrObjScaleControl_gcnList,		; GCBI_gcnList
	length GrObjScaleControl_gcnList,		; GCBI_gcnCount
	GrObjScaleControl_notifyList,		; GCBI_notificationList
	length GrObjScaleControl_notifyList,		; GCBI_notificationCount
	GrObjScaleControlName,			; GCBI_controllerName

	handle GrObjScaleControlUI,	; GCBI_dupBlock
	GrObjScaleControl_childList,		; GCBI_childList
	length GrObjScaleControl_childList,		; GCBI_childCount
	GrObjScaleControl_featuresList,	; GCBI_featuresList
	length GrObjScaleControl_featuresList,	; GCBI_featuresCount

	GROBJ_SCALE_CONTROL_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	GrObjScaleControl_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GrObjScaleControl_helpContext	char	"dbGrObjScale", 0

GrObjScaleControl_IniFileKey	char	"GrObjScale", 0

GrObjScaleControl_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GrObjScaleControl_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---

GrObjScaleControl_childList	GenControlChildInfo \
	<offset GrObjScaleHalfWidthTrigger, mask GOSCF_HALF_WIDTH, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjScaleDoubleWidthTrigger, mask GOSCF_DOUBLE_WIDTH, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjScaleHalfHeightTrigger, mask GOSCF_HALF_HEIGHT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjScaleDoubleHeightTrigger, mask GOSCF_DOUBLE_HEIGHT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjCustomScaleInteraction, mask GOSCF_CUSTOM_SCALE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GrObjScaleControl_featuresList	GenControlFeaturesInfo	\
	<offset GrObjCustomScaleInteraction, GrObjScaleControlCustomName, 0>,
	<offset GrObjScaleDoubleHeightTrigger, GrObjScaleControlDoubleHeightName, 0>,
	<offset GrObjScaleDoubleWidthTrigger, GrObjScaleControlDoubleWidthName, 0>,
	<offset GrObjScaleHalfHeightTrigger, GrObjScaleControlHalfHeightName, 0>,
	<offset GrObjScaleHalfWidthTrigger, GrObjScaleControlHalfWidthName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjScaleControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjScaleControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjScaleControlClass
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
GrObjScaleControlUpdateUI	method GrObjScaleControlClass,
						MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	cx, 1
	mov	dx, mask GOL_RESIZE

	mov	ax, mask GOSCF_HALF_WIDTH
	mov	si, offset GrObjScaleHalfWidthTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GOSCF_HALF_HEIGHT
	mov	si, offset GrObjScaleHalfHeightTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GOSCF_DOUBLE_WIDTH
	mov	si, offset GrObjScaleDoubleWidthTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GOSCF_DOUBLE_HEIGHT
	mov	si, offset GrObjScaleDoubleHeightTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear

	mov	ax, mask GOSCF_CUSTOM_SCALE
	mov	si, offset GrObjCustomScaleReplyApply
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	.leave
	ret
GrObjScaleControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjScaleControlScaleHorizontally
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjScaleControl method for MSG_GOSC_SCALE_HORIZONTALLY

Called by:	

Pass:		*ds:si = GrObjScaleControl object
		ds:di = GrObjScaleControl instance
		dx.cx - degrees

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScaleControlScaleHorizontally	method	GrObjScaleControlClass,
					MSG_GOSC_SCALE_HORIZONTALLY
	.enter

	mov	bx, 100
	clr	ax
	call	GrUDivWWFixed
	mov	bx, 1
	clr	ax
	call	OutputScaleCommon

	.leave
	ret
GrObjScaleControlScaleHorizontally	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjScaleControlScaleVertically
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjScaleControl method for MSG_GOSC_SCALE_VERTICALLY

Called by:	

Pass:		*ds:si = GrObjScaleControl object
		ds:di = GrObjScaleControl instance
		dx.cx - degrees

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScaleControlScaleVertically	method	GrObjScaleControlClass,
					MSG_GOSC_SCALE_VERTICALLY
	uses	cx, dx
	.enter

	mov	bx, 100
	clr	ax
	call	GrUDivWWFixed
	movwwf	bxax, dxcx
	mov	dx, 1
	clr	cx
	call	OutputScaleCommon

	.leave
	ret
GrObjScaleControlScaleVertically	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			OutputScaleCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Common code for the MSG_GOSC_SCALE_### methods

Called by:	

Pass:		*ds:si = GrObjScaleControl object
		ds:di = GrObjScaleControl instance

		dxcx = wwf x scale
		bxax = wwf y scale

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutputScaleCommon	proc	near
	uses	ax, cx, dx, bp
	.enter

CheckHack	<size GrObjScaleData eq 8>
	pushwwf	bxax
	pushwwf	dxcx
	mov	bp, sp
	mov	dx, size GrObjScaleData
	mov	ax, MSG_GO_SCALE_OBJECT
	call	GrObjControlOutputActionStackToGrObjs
	add	sp, size GrObjScaleData

	.leave
	ret
OutputScaleCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjScaleControlCustomScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjScaleControl method for MSG_GOSC_CUSTOM_SCALE

Called by:	

Pass:		*ds:si = GrObjScaleControl object
		ds:di = GrObjScaleControl instance
		dx.cx - degrees

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScaleControlCustomScale	method	GrObjScaleControlClass,
				MSG_GOSC_CUSTOM_SCALE
	.enter

	call	GetChildBlockAndFeatures
	test	ax, mask GOSCF_CUSTOM_SCALE
	jz	done

	push	si
	mov	si, offset GrObjCustomScaleVValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si

	push	bx
	mov	bx, 100
	clr	ax
	call	GrUDivWWFixed
	pop	bx

	pushwwf	dxcx

	push	si
	mov	si, offset GrObjCustomScaleHValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si

	mov	bx, 100
	clr	ax
	call	GrUDivWWFixed
	pushwwf	dxcx

	mov	bp, sp
CheckHack <size GrObjScaleData eq (2 * size WWFixed)>
	mov	dx, size GrObjScaleData
	mov	ax, MSG_GO_SCALE_OBJECT
	call	GrObjControlOutputActionStackToGrObjs
	add	sp, size GrObjScaleData

done:
	.leave
	ret
GrObjScaleControlCustomScale	endm

GrObjUIControllerActionCode	ends
