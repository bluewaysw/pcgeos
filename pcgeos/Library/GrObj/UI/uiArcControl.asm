COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiArcControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjArcControlClass

	$Id: uiArcControl.asm,v 1.1 97/04/04 18:06:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjArcControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjArcControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjArcControlClass

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
GrObjArcControlGetInfo	method dynamic	GrObjArcControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOArcC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjArcControlGetInfo	endm

GOArcC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOArcC_IniFileKey,		; GCBI_initFileKey
	GOArcC_gcnList,		; GCBI_gcnList
	length GOArcC_gcnList,		; GCBI_gcnCount
	GOArcC_notifyList,		; GCBI_notificationList
	length GOArcC_notifyList,		; GCBI_notificationCount
	GOArcCName,			; GCBI_controllerName

	handle GrObjArcControlUI,	; GCBI_dupBlock
	GOArcC_childList,		; GCBI_childList
	length GOArcC_childList,		; GCBI_childCount
	GOArcC_featuresList,	; GCBI_featuresList
	length GOArcC_featuresList,	; GCBI_featuresCount

	GOArcC_DEFAULT_FEATURES,		; GCBI_gcmFeatures

	0,				; GCBI_dupBlock
	0,				; GCBI_childList
	0,				; GCBI_childCount
	0,				; GCBI_featuresList
	0,				; GCBI_featuresCount

	0,				; GCBI_advancedFeatures
	GOArcC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOArcC_helpContext	char	"dbGrObjArc", 0

GOArcC_IniFileKey	char	"GrObjArc", 0

GOArcC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GOArcC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GOArcC_childList	GenControlChildInfo \
	<offset GrObjArcAngleGroup, mask GOACF_START_ANGLE or mask GOACF_END_ANGLE, 0>,
	<offset GrObjArcCloseTypeItemGroup, mask GOACF_PIE_TYPE or \
						mask GOACF_CHORD_TYPE, 0>

GOArcC_featuresList	GenControlFeaturesInfo	\
	<offset ChordItem, ChordTypeName, 0>,
	<offset PieItem, PieTypeName, 0>,
	<offset GrObjArcEndAngleMonikerAndValue, EndAngleName, 0>,
	<offset GrObjArcStartAngleMonikerAndValue, StartAngleName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjArcControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjArcControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjArcControlClass
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
GrObjArcControlUpdateUI	method dynamic GrObjArcControlClass,
				MSG_GEN_CONTROL_UPDATE_UI
	uses	cx, dx
	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	LONG	jc	done
	mov	es, ax
	mov	ax, MSG_GEN_SET_ENABLED			;assume ungroupable
	mov	cl, es:[GONSSC_selectionState].GSS_flags
	test 	cl, mask GSSF_ARC_SELECTED
	jnz	haveEnableMsg
	mov	ax, MSG_GEN_SET_NOT_ENABLED
haveEnableMsg:
	mov	bx, ss:[bp].GCUUIP_childBlock

	test	ss:[bp].GCUUIP_features, mask GOACF_START_ANGLE
	jz	checkEndAngle
	mov	si, offset GrObjArcStartAngleMonikerAndValue
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	cmp	ax, MSG_GEN_SET_NOT_ENABLED
	je	checkEndAngle

	push	ax,bp					;save enable msg,GCUUIP
	movwwf	dxcx, es:[GONSSC_arcStartAngle]
	mov	al, es:[GONSSC_selectionStateDiffs]
	and	ax, mask GSSD_MULTIPLE_ARC_START_ANGLES
	mov_tr	bp, ax
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	mov	si, offset GrObjArcStartAngleValue
	clr	di
	call	ObjMessage
	pop	ax,bp					;ax <- enable msg
							;ss:bp <- GCUUIP

checkEndAngle:
	test	ss:[bp].GCUUIP_features, mask GOACF_END_ANGLE
	jz	checkCloseType
	mov	si, offset GrObjArcEndAngleMonikerAndValue
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	cmp	ax, MSG_GEN_SET_NOT_ENABLED
	je	checkCloseType

	push	ax,bp					;save enable msg,GCUUIP
	movwwf	dxcx, es:[GONSSC_arcEndAngle]
	mov	al, es:[GONSSC_selectionStateDiffs]
	and	ax, mask GSSD_MULTIPLE_ARC_END_ANGLES
	mov_tr	bp, ax
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	mov	si, offset GrObjArcEndAngleValue
	clr	di
	call	ObjMessage
	pop	ax,bp					;ax <- enable msg
							;ss:bp <- GCUUIP
checkCloseType:
	test	ss:[bp].GCUUIP_features, mask GOACF_PIE_TYPE or mask GOACF_CHORD_TYPE
	jz	unlockDone
	mov	si, offset GrObjArcCloseTypeItemGroup
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	cmp	ax, MSG_GEN_SET_NOT_ENABLED
	je	unlockDone

	mov	cx, es:[GONSSC_arcCloseType]
	mov	dl, es:[GONSSC_selectionStateDiffs]
	and	dx, mask GSSD_MULTIPLE_ARC_CLOSE_TYPES
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

unlockDone:
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

done:
	.leave
	ret
GrObjArcControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjArcControlSetStartAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjArcControl method for MSG_GOAC_SET_START_ANGLE

Called by:	

Pass:		*ds:si = GrObjArcControl object
		ds:di = GrObjArcControl instance

		dx:cx - WWFixed starting angle

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjArcControlSetStartAngle	method dynamic	GrObjArcControlClass,
				MSG_GOAC_SET_START_ANGLE

	.enter

	mov	ax, MSG_ARC_SET_START_ANGLE

	mov	bx, segment ArcClass
	mov	di, offset ArcClass
	call	GenControlOutputActionRegs

	.leave
	ret
GrObjArcControlSetStartAngle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjArcControlSetEndAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjArcControl method for MSG_GOAC_SET_END_ANGLE

Called by:	

Pass:		*ds:si = GrObjArcControl object
		ds:di = GrObjArcControl instance

		dx:cx - WWFixed ending angle

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjArcControlSetEndAngle	method dynamic	GrObjArcControlClass,
				MSG_GOAC_SET_END_ANGLE

	.enter

	mov	ax, MSG_ARC_SET_END_ANGLE

	mov	bx, segment ArcClass
	mov	di, offset ArcClass
	call	GenControlOutputActionRegs

	.leave
	ret
GrObjArcControlSetEndAngle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjArcControlSetArcCloseType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjArcControl method for MSG_GOAC_SET_ARC_CLOSE_TYPE

Called by:	

Pass:		*ds:si = GrObjArcControl object
		ds:di = GrObjArcControl instance

		cx - ArcCloseType

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjArcControlSetArcCloseType	method dynamic	GrObjArcControlClass,
				MSG_GOAC_SET_ARC_CLOSE_TYPE

	.enter

	mov	ax, MSG_ARC_SET_ARC_CLOSE_TYPE

	mov	bx, segment ArcClass
	mov	di, offset ArcClass
	call	GenControlOutputActionRegs

	.leave
	ret
GrObjArcControlSetArcCloseType	endm
GrObjUIControllerActionCode	ends
