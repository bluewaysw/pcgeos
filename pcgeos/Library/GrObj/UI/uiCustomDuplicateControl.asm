COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiCustomDuplicateControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjCustomDuplicateControlClass

	$Id: uiCustomDuplicateControl.asm,v 1.1 97/04/04 18:06:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjCustomDuplicateControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjCustomDuplicateControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjCustomDuplicateControlClass

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
GrObjCustomDuplicateControlGetInfo	method dynamic	GrObjCustomDuplicateControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOCDC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjCustomDuplicateControlGetInfo	endm

GOCDC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOCDC_IniFileKey,		; GCBI_initFileKey
	GOCDC_gcnList,			; GCBI_gcnList
	length GOCDC_gcnList,		; GCBI_gcnCount
	GOCDC_notifyList,		; GCBI_notificationList
	length GOCDC_notifyList,	; GCBI_notificationCount
	GOCDCName,			; GCBI_controllerName

	handle GrObjCustomDuplicateControlUI,	; GCBI_dupBlock
	GOCDC_childList,			; GCBI_childList
	length GOCDC_childList,		; GCBI_childCount
	GOCDC_featuresList,		; GCBI_featuresList
	length GOCDC_featuresList,	; GCBI_featuresCount

	GOCDC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	0,	; GCBI_dupBlock
	0,	; GCBI_childList
	0,	; GCBI_childCount
	0,	; GCBI_featuresList
	0,	; GCBI_featuresCount

	0,	; GCBI_defaultFeatures
	GOCDC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOCDC_helpContext	char	"dbCustomDup", 0

GOCDC_IniFileKey	char	"GrObjCustomDuplicate", 0

GOCDC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GOCDC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GOCDC_childList	GenControlChildInfo \
	<offset GrObjCustomDuplicateInteraction, mask GOCDCFeatures, 0>

GOCDC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjCustomDuplicateSkewGroup, CDSkewName, 0>,
	<offset GrObjCustomDuplicateRotationGroup, CDRotationName, 0>,
	<offset GrObjCustomDuplicateScaleGroup, CDScaleName, 0>,
	<offset GrObjCustomDuplicateMoveGroup, CDMoveName, 0>,
	<offset GrObjCustomDuplicateRepetitionValue, CDRepetitionsName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjCustomDuplicateControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjCustomDuplicateControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjCustomDuplicateControlClass
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
GrObjCustomDuplicateControlUpdateUI	method GrObjCustomDuplicateControlClass,
						MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	ax, mask GOCDCFeatures			;any feature
	mov	cx, 1					;just 1 grobj
	mov	si, offset GrObjCustomDuplicateReplyApply
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	.leave
	ret
GrObjCustomDuplicateControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCustomDuplicateControlCustomDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjCustomDuplicateControl method for MSG_GOCDC_CUSTOM_DUPLICATE

Called by:	

Pass:		*ds:si = GrObjCustomDuplicateControl object
		ds:di = GrObjCustomDuplicateControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCustomDuplicateControlCustomDuplicate	method dynamic	GrObjCustomDuplicateControlClass, MSG_GOCDC_CUSTOM_DUPLICATE

	.enter

	mov	di, offset GrObjCustomDuplicateControlClass
	call	ObjCallSuperNoLock

	call	GetChildBlockAndFeatures

	sub	sp, size GrObjBodyCustomDuplicateParams
	mov	bp, sp

	push	si					;save controller chunk

	;
	;  Get the number of repetitions
	;
	mov	dx, 1
	test	ax, mask GOCDCF_REPETITIONS
	jz	afterReps

	push	bp, ax
	mov	si, offset GrObjCustomDuplicateRepetitionValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp, ax

afterReps:
	mov	ss:[bp].GBCDP_repetitions, dx

	clr	dx
	clrdwf	ss:[bp].GBCDP_move.PDF_x, dx
	clrdwf	ss:[bp].GBCDP_move.PDF_y, dx

	push	ax
	test	ax, mask GOCDCF_MOVE
	jz	afterMove

	;
	;  Get horizontal offset
	;

	push	bp
	mov	si, offset GrObjCustomDuplicateMoveHValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp

	mov_tr	ax, dx
	cwd
	movdwf	ss:[bp].GBCDP_move.PDF_x, dxaxcx

	;
	;  Get vertical offset
	;
	push	bp
	mov	si, offset GrObjCustomDuplicateMoveVValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp

	mov_tr	ax, dx
	cwd
	movdwf	ss:[bp].GBCDP_move.PDF_y, dxaxcx

afterMove:
	pop	ax
	clrwwf	dxcx
	test	ax, mask GOCDCF_ROTATE
	jz	afterRotate

	;
	;  Get rotation
	;
	push	bp, ax
	mov	si, offset GrObjCustomDuplicateRotationValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp, ax

	movwwf	ss:[bp].GBCDP_rotation, dxcx

afterRotate:

	;
	;  Clear the rotation anchor for now
	;
	clr	ss:[bp].GBCDP_rotateAnchor

	;
	;  Get width scale
	;

	clr	dx
	mov	ss:[bp].GBCDP_scale.GOASD_scale.GOSD_xScale.WWF_frac, dx
	mov	ss:[bp].GBCDP_scale.GOASD_scale.GOSD_yScale.WWF_frac, dx
	inc	dx
	mov	ss:[bp].GBCDP_scale.GOASD_scale.GOSD_xScale.WWF_int, dx
	mov	ss:[bp].GBCDP_scale.GOASD_scale.GOSD_yScale.WWF_int, dx


	push	ax
	test	ax, mask GOCDCF_SCALE
	jz	afterScale

	push	bp
	mov	si, offset GrObjCustomDuplicateScaleHValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp

	;
	;  Convert from %
	;
	push	bx
	mov	bx, 100
	clr	ax
	call	GrSDivWWFixed
	pop	bx

	movwwf	ss:[bp].GBCDP_scale.GOASD_scale.GOSD_xScale, dxcx

	;
	;  Get height scale
	;
	push	bp
	mov	si, offset GrObjCustomDuplicateScaleVValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp

	;
	;  Convert from %
	;
	push	bx
	mov	bx, 100
	clr	ax
	call	GrSDivWWFixed
	pop	bx

	movwwf	ss:[bp].GBCDP_scale.GOASD_scale.GOSD_yScale, dxcx

afterScale:
	;
	;  Clear the scale anchor for now
	;
	clr	ss:[bp].GBCDP_scale.GOASD_scaleAnchor

	pop	ax
	clr	dx
	
	clrwwf	ss:[bp].GBCDP_skew.GOASD_degrees.GOSD_xDegrees, dx
	clrwwf	ss:[bp].GBCDP_skew.GOASD_degrees.GOSD_yDegrees, dx

	test	ax, mask GOCDCF_SKEW
	jz	afterSkew

	;
	;  Get horizontal skew
	;
	push	bp
	mov	si, offset GrObjCustomDuplicateSkewHValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp

	movwwf	ss:[bp].GBCDP_skew.GOASD_degrees.GOSD_xDegrees, dxcx

	;
	;  Get vertical skew
	;
	push	bp
	mov	si, offset GrObjCustomDuplicateSkewVValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp

	movwwf	ss:[bp].GBCDP_skew.GOASD_degrees.GOSD_yDegrees, dxcx

afterSkew:
	;
	;  Clear the skew anchor for now
	;
	clr	ss:[bp].GBCDP_skew.GOASD_skewAnchor

	pop	si					;*ds:si - controller
	mov	dx, size GrObjBodyCustomDuplicateParams
	mov	ax, MSG_GB_CUSTOM_DUPLICATE_SELECTED_GROBJS
	call	GrObjControlOutputActionStackToBody

	add	sp, size GrObjBodyCustomDuplicateParams

	.leave
	ret
GrObjCustomDuplicateControlCustomDuplicate	endm

GrObjUIControllerActionCode	ends
