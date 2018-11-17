COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiGradientFillControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjGradientFillControlClass

	$Id: uiGradientFillControl.asm,v 1.1 97/04/04 18:06:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjGradientFillControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjGradientFillControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjGradientFillControlClass

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
GrObjGradientFillControlGetInfo	method dynamic	GrObjGradientFillControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOGFC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjGradientFillControlGetInfo	endm

GOGFC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOGFC_IniFileKey,		; GCBI_initFileKey
	GOGFC_gcnList,			; GCBI_gcnList
	length GOGFC_gcnList,		; GCBI_gcnCount
	GOGFC_notifyList,		; GCBI_notificationList
	length GOGFC_notifyList,		; GCBI_notificationCount
	GOGFCName,			; GCBI_controllerName

	handle GrObjGradientFillControlUI,	; GCBI_dupBlock
	GOGFC_childList,			; GCBI_childList
	length GOGFC_childList,		; GCBI_childCount
	GOGFC_featuresList,		; GCBI_featuresList
	length GOGFC_featuresList,	; GCBI_featuresCount

	GOGFC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	0,	; GCBI_dupBlock
	0,	; GCBI_childList
	0,	; GCBI_childCount
	0,	; GCBI_featuresList
	0,	; GCBI_featuresCount

	0,	; GCBI_defaultFeatures
	GOGFC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOGFC_helpContext	char	"dbGradient", 0

GOGFC_IniFileKey	char	"GrObjGradientFill", 0

GOGFC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_GRADIENT_ATTR_CHANGE>

GOGFC_notifyList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_GRADIENT_ATTR_CHANGE>

;---


GOGFC_childList	GenControlChildInfo \
	<offset GrObjGradientTypeList, mask GOGFCF_HORIZONTAL_GRADIENT or \
				mask GOGFCF_VERTICAL_GRADIENT or \
				mask GOGFCF_RADIAL_RECT_GRADIENT or \
				mask GOGFCF_RADIAL_ELLIPSE_GRADIENT, 0>,
	<offset GrObjNumGradientIntervalsValue, mask GOGFCF_NUM_INTERVALS, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOGFC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjNumGradientIntervalsValue, NumGradientIntervalsName, 0>,
	<offset RadialEllipseGradientItem, RadialEllipseGradientName, 0>,
	<offset RadialRectGradientItem, RadialRectGradientName, 0>,
	<offset VerticalGradientItem, VerticalGradientName, 0>,
	<offset HorizontalGradientItem, HorizontalGradientName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjGradientFillControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjGradientFillControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjGradientFillControlClass
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
GrObjGradientFillControlUpdateUI	method dynamic GrObjGradientFillControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx, dx

	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock	;bx <- notification block
	call	MemLock
	mov	es, ax
	mov	cl, es:[GONGAC_type]
	mov	ax, es:[GONGAC_numIntervals]
	mov	dl, es:[GONGAC_diffs]
	call	MemUnlock

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset GrObjGradientTypeList

	push	ax, dx
	clr	ch
	andnf	dx, mask GGAD_MULTIPLE_TYPES

	test	ss:[bp].GCUUIP_features,mask GOGFCF_HORIZONTAL_GRADIENT or \
					mask GOGFCF_VERTICAL_GRADIENT or \
					mask GOGFCF_RADIAL_RECT_GRADIENT or \
					mask GOGFCF_RADIAL_ELLIPSE_GRADIENT
	jz	afterGradientType
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

afterGradientType:
	test	ss:[bp].GCUUIP_features, mask GOGFCF_NUM_INTERVALS
	pop	dx, bp
	jz	done
	clr	cx
	andnf	bp, mask GGAD_MULTIPLE_INTERVALS
	mov	si, offset GrObjNumGradientIntervalsValue
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjGradientFillControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGradientFillControlSetNumberOfGradientIntervals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjGradientFillControl method for MSG_GOGFC_SET_NUMBER_OF_GRADIENT_INTERVALS

Called by:	

Pass:		*ds:si = GrObjGradientFillControl object
		ds:di = GrObjGradientFillControl instance

		dx.cx - number of intervals

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGradientFillControlSetNumberOfGradientIntervals	method dynamic	GrObjGradientFillControlClass, MSG_GOGFC_SET_NUMBER_OF_GRADIENT_INTERVALS

	.enter

	mov	cx, dx
	mov	ax, MSG_GO_SET_NUMBER_OF_GRADIENT_INTERVALS
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjGradientFillControlSetNumberOfGradientIntervals	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGradientFillControlSetGradientType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjGradientFillControl method for MSG_GOGFC_SET_GRADIENT_TYPE

Called by:	

Pass:		*ds:si = GrObjGradientFillControl object
		ds:di = GrObjGradientFillControl instance

		cl - GrObjGradientType

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGradientFillControlSetGradientType	method dynamic	GrObjGradientFillControlClass, MSG_GOGFC_SET_GRADIENT_TYPE

	.enter

	cmp	cx, GIGS_NONE
	jne	setType

	mov	cl, GOGT_NONE

setType:
	mov	ax, MSG_GO_SET_GRADIENT_TYPE
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjGradientFillControlSetGradientType	endm

GrObjUIControllerActionCode	ends
