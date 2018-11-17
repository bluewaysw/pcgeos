COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiCustomShapeControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjCustomShapeControlClass

	$Id: uiCustomShapeControl.asm,v 1.1 97/04/04 18:06:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjCustomShapeControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjCustomShapeControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjCustomShapeControlClass

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
GrObjCustomShapeControlGetInfo	method dynamic	GrObjCustomShapeControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOCSC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjCustomShapeControlGetInfo	endm

GOCSC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOCSC_IniFileKey,		; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	GOCSCName,			; GCBI_controllerName

	handle GrObjCustomShapeControlUI,	; GCBI_dupBlock
	GOCSC_childList,			; GCBI_childList
	length GOCSC_childList,		; GCBI_childCount
	GOCSC_featuresList,		; GCBI_featuresList
	length GOCSC_featuresList,	; GCBI_featuresCount

	GOCSC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	0,	; GCBI_dupBlock
	0,	; GCBI_childList
	0,	; GCBI_childCount
	0,	; GCBI_featuresList
	0,	; GCBI_featuresCount

	0,	; GCBI_defaultFeatures
	GOCSC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOCSC_helpContext	char	"dbGrObjShape", 0

GOCSC_IniFileKey	char	"GrObjCustomShape", 0

;---


GOCSC_childList	GenControlChildInfo \
	<offset GrObjCreatePolygonDialog, mask GOCSCF_NUM_POLYGON_SIDES or \
					mask GOCSCF_POLYGON_RADIUS, 0>,
	<offset GrObjCreateStarDialog, mask GOCSCF_NUM_STAR_POINTS or \
					mask GOCSCF_STAR_RADII, 0>

GOCSC_featuresList	GenControlFeaturesInfo	\
	<offset StarRadiiGroup, StarRadiiName, 0>,
	<offset NumStarPointsValue, StarPointsName, 0>,
	<offset PolygonRadiusGroup, PolygonRadiusName, 0>,
	<offset NumPolygonPointsValue, PolygonSidesName, 0>


if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCustomShapeControlCreateStar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjCustomShapeControl method for MSG_GOCSC_CREATE_STAR

Called by:	

Pass:		*ds:si = GrObjCustomShapeControl object
		ds:di = GrObjCustomShapeControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCustomShapeControlCreateStar	method dynamic	GrObjCustomShapeControlClass, MSG_GOCSC_CREATE_STAR

	uses	cx, dx, bp
	.enter

	push	si					;save controller chunk

	call	GetChildBlockAndFeatures

	;
	;  Get the number of star points
	;
	mov	dx, 5
	test	ax, mask GOCSCF_NUM_STAR_POINTS
	jz	afterStarPoints

	push	ax
	mov	si, offset NumStarPointsValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	ax					;ax <- features

afterStarPoints:
	push	dx					;save n points

	;
	;  Get the inner radius of the star
	;
	mov	dx, 40
	push	dx, dx
	mov	dx, 100
	push	dx

	test	ax, mask GOCSCF_STAR_RADII
	jz	afterRadii

	add	sp, 6

	mov	si, offset StarInnerXRadiusValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	push	dx					;save inner X radius

	mov	si, offset StarInnerYRadiusValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	push	dx					;save inner y radius
	
	;
	;  Get the outer radius of the star
	;
	mov	si, offset StarOuterXRadiusValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	push	dx					;save outer X radius

	mov	si, offset StarOuterYRadiusValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

afterRadii:

	pop	ax					;ax <- outer x radius
	pop	bx					;bx <- inner y radius
	pop	cx					;cx <- inner x radius
	pop	di					;di <- # star points

	pop	si					;*ds:si - controller

	sub	sp, size SplineMakeStarParams
	mov	bp, sp

	mov	ss:[bp].SMSP_outerRadius.P_y, dx
	mov	ss:[bp].SMSP_outerRadius.P_x, ax
	mov	ss:[bp].SMSP_innerRadius.P_y, bx
	mov	ss:[bp].SMSP_innerRadius.P_x, cx
	mov	ss:[bp].SMSP_starPoints, di

	mov	dx, size SplineMakeStarParams
	mov	ax, MSG_GB_CREATE_STAR

	call	GrObjControlOutputActionStackToBody

	add	sp, size SplineMakeStarParams

	.leave
	ret
GrObjCustomShapeControlCreateStar	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCustomShapeControlCreatePolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjCustomShapeControl method for MSG_GOCSC_CREATE_POLYGON

Called by:	

Pass:		*ds:si = GrObjCustomShapeControl object
		ds:di = GrObjCustomShapeControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCustomShapeControlCreatePolygon	method dynamic	GrObjCustomShapeControlClass, MSG_GOCSC_CREATE_POLYGON

	uses	cx, dx, bp
	.enter

	push	si					;save controller chunk

	call	GetChildBlockAndFeatures

	;
	;  Get the number of polygon points
	;
	mov	dx, 5
	test	ax, mask GOCSCF_NUM_POLYGON_SIDES
	jz	afterPolygonPoints

	push	ax
	mov	si, offset NumPolygonPointsValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	ax

afterPolygonPoints:
	push	dx					;save n points

	;
	;  Get the inner radius of the star
	;
	mov	dx, 100
	push	dx

	test	ax, mask GOCSCF_POLYGON_RADIUS
	jz	afterRadii

	pop	ax

	;
	;  Get the radius of the polygon
	;
	mov	si, offset PolygonXRadiusValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	push	dx					;save X radius

	mov	si, offset PolygonYRadiusValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

afterRadii:
	pop	cx					;cx <- x radius

	;
	;  Double the radius into the diameter
	;
	shl	cx
	shl	dx

	pop	bp					;bp <- n points

	pop	si					;*ds:si <- controller
	mov	ax, MSG_GB_CREATE_POLYGON
	call	GrObjControlOutputActionRegsToBody

	.leave
	ret
GrObjCustomShapeControlCreatePolygon	endm

GrObjUIControllerActionCode	ends
