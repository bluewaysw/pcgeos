COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiNudgeControl.asm

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
	Code for the GrObjNudgeControlClass

	$Id: uiNudgeControl.asm,v 1.1 97/04/04 18:06:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjNudgeControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjNudgeControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjNudgeControlClass

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
GrObjNudgeControlGetInfo	method dynamic	GrObjNudgeControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GONC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjNudgeControlGetInfo	endm

GONC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GONC_IniFileKey,		; GCBI_initFileKey
	GONC_gcnList,		; GCBI_gcnList
	length GONC_gcnList,		; GCBI_gcnCount
	GONC_notifyList,		; GCBI_notificationList
	length GONC_notifyList,		; GCBI_notificationCount
	GONCName,			; GCBI_controllerName

	handle GrObjNudgeControlUI,	; GCBI_dupBlock
	GONC_childList,		; GCBI_childList
	length GONC_childList,		; GCBI_childCount
	GONC_featuresList,	; GCBI_featuresList
	length GONC_featuresList,	; GCBI_featuresCount

	GROBJ_NUDGE_CONTROL_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	GONC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GONC_helpContext	char	"dbGrObjNudge", 0

GONC_IniFileKey	char	"GrObjNudge", 0

GONC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GONC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GONC_childList	GenControlChildInfo \
	<offset GrObjNudgeLeftTrigger, mask GONCF_NUDGE_LEFT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjNudgeRightTrigger, mask GONCF_NUDGE_RIGHT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjNudgeUpTrigger, mask GONCF_NUDGE_UP, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjNudgeDownTrigger, mask GONCF_NUDGE_DOWN, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjCustomMoveInteraction, mask GONCF_CUSTOM_MOVE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GONC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjCustomMoveInteraction, CustomMoveName, 0>,
	<offset GrObjNudgeDownTrigger, NudgeDownName, 0>,
	<offset GrObjNudgeUpTrigger, NudgeUpName, 0>,
	<offset GrObjNudgeRightTrigger, NudgeRightName, 0>,
	<offset GrObjNudgeLeftTrigger, NudgeLeftName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjNudgeControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjNudgeControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjNudgeControlClass
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
GrObjNudgeControlUpdateUI	method GrObjNudgeControlClass,
						MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	cx, 1
	mov	dx, mask GOL_MOVE

	mov	ax, mask GONCF_NUDGE_LEFT
	mov	si, offset GrObjNudgeLeftTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear

	mov	ax, mask GONCF_NUDGE_RIGHT
	mov	si, offset GrObjNudgeRightTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear

	mov	ax, mask GONCF_NUDGE_UP
	mov	si, offset GrObjNudgeUpTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear

	mov	ax, mask GONCF_NUDGE_DOWN
	mov	si, offset GrObjNudgeDownTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	mov	ax, mask GONCF_CUSTOM_MOVE
	mov	si, offset GrObjCustomMoveReplyApply
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear
	.leave
	ret
GrObjNudgeControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjNudgeControlNudge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjNudgeControl method for MSG_GONC_NUDGE

Called by:	

Pass:		*ds:si = GrObjNudgeControl object
		ds:di = GrObjNudgeControl instance

		cx - x nudge
		dx - y nudge

Return:		nothing

Destroyed:	bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjNudgeControlNudge	method	GrObjNudgeControlClass, MSG_GONC_NUDGE

	.enter

	mov	ax, MSG_GO_NUDGE
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjNudgeControlNudge	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjNudgeControlSetDisplayFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjNudgeControl method for MSG_GONC_SET_DISPLAY_FORMAT

Called by:	

Pass:		*ds:si = GrObjNudgeControl object
		ds:di = GrObjNudgeControl instance

		cl - GenValueDisplayFormat

Return:		nothing

Destroyed:	bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjNudgeControlSetDisplayFormat	method	GrObjNudgeControlClass,
					MSG_GONC_SET_DISPLAY_FORMAT
	.enter

	call	GetChildBlockAndFeatures
	test	ax, mask GONCF_CUSTOM_MOVE
	jz	done

	mov	si, offset GrObjCustomMoveVValue
	mov	ax, MSG_GEN_VALUE_SET_DISPLAY_FORMAT
	clr	di
	call	ObjMessage

	mov	si, offset GrObjCustomMoveHValue
	mov	ax, MSG_GEN_VALUE_SET_DISPLAY_FORMAT
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjNudgeControlSetDisplayFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjNudgeControlCustomMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjMoveControl method for MSG_GONC_CUSTOM_MOVE

Called by:	

Pass:		*ds:si = GrObjMoveControl object
		ds:di = GrObjMoveControl instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjNudgeControlCustomMove	method dynamic	GrObjNudgeControlClass,
				MSG_GONC_CUSTOM_MOVE
	uses	bp
	.enter

	mov	bp, MSG_GO_MOVE
	call	GrObjCustomMoveCommon

	.leave
	ret
GrObjNudgeControlCustomMove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCustomMoveCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is the common routine for handling a custom
		move-type operation for GrObjNudgeControlClass and
		any of its subclassings (read: GrObjMoveInsideControl)

Pass:		*ds:si - subclass of GrObjNudgeControlClass

		bp - MSG_GO_<whatever it takes to move your grobj here>

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCustomMoveCommon	proc	near
	uses	ax, bx, cx, dx, bp, di
	.enter

	;
	;  Check for custom move feature. If no, bail
	;
	call	GetChildBlockAndFeatures
	test	ax, mask GONCF_CUSTOM_MOVE
	jz	done

	;
	;  Get the amount to move vertically and push the DWF on the stack
	;
	push	si, bp
	mov	si, offset GrObjCustomMoveVValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si, bp
	mov_tr	ax, dx
	cwd
	pushdwf	dxaxcx

	;
	;  Get the amount to move horizontally and push the DWF on the stack
	;
	push	si, bp
	mov	si, offset GrObjCustomMoveHValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si, bp
	mov_tr	ax, dx
	cwd
	pushdwf	dxaxcx

	;
	;  Send the PointDWFixed that we've pushed on the stack to the grobjs
	;
	mov_tr	ax, bp					;ax <- passed message
	mov	bp, sp
	mov	dx, size PointDWFixed
	mov	ax, MSG_GO_MOVE
	call	GrObjControlOutputActionStackToGrObjs
	add	sp, size PointDWFixed

done:
	.leave
	ret
GrObjCustomMoveCommon	endp

GrObjUIControllerActionCode	ends
