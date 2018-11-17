COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiAlignDistributeControl.asm

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
	Code for the GrObjAlignDistributeControlClass

	$Id: uiAlignControl.asm,v 1.1 97/04/04 18:06:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAlignDistributeControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjAlignDistributeControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjAlignDistributeControlClass

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
GrObjAlignDistributeControlGetInfo	method dynamic	GrObjAlignDistributeControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOADC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjAlignDistributeControlGetInfo	endm

GOADC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	GOADC_IniFileKey,		; GCBI_initFileKey
	GOADC_gcnList,			; GCBI_gcnList
	length GOADC_gcnList,		; GCBI_gcnCount
	GOADC_notifyList,		; GCBI_notificationList
	length GOADC_notifyList,	; GCBI_notificationCount
	GOADCName,			; GCBI_controllerName

	handle GrObjAlignDistributeControlUI,	; GCBI_dupBlock
	GOADC_childList,		; GCBI_childList
	length GOADC_childList,		; GCBI_childCount
	GOADC_featuresList,		; GCBI_featuresList
	length GOADC_featuresList,	; GCBI_featuresCount

	GOADC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	GOADC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOADC_helpContext	char	"dbGrObjAlign", 0

GOADC_IniFileKey	char	"GrObjAlignDistribute", 0

GOADC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GOADC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GOADC_childList	GenControlChildInfo \
<offset GrObjAlignGroup,	mask GOADCF_ALIGN_LEFT or \
				mask GOADCF_ALIGN_CENTER_HORIZONTALLY or \
				mask GOADCF_ALIGN_RIGHT or \
				mask GOADCF_ALIGN_WIDTH or \
				mask GOADCF_ALIGN_CENTER_VERTICALLY or \
				mask GOADCF_ALIGN_BOTTOM or \
				mask GOADCF_ALIGN_HEIGHT, 0>,
<offset GrObjDistributeGroup,	mask GOADCF_DISTRIBUTE_LEFT or \
				mask GOADCF_DISTRIBUTE_CENTER_HORIZONTALLY or \
				mask GOADCF_DISTRIBUTE_RIGHT or \
				mask GOADCF_DISTRIBUTE_WIDTH or \
				mask GOADCF_DISTRIBUTE_CENTER_VERTICALLY or \
				mask GOADCF_DISTRIBUTE_BOTTOM or \
				mask GOADCF_DISTRIBUTE_HEIGHT, 0>
				   
GOADC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjDistributeHeightItem, DistributeHeightName, 0>,
	<offset GrObjDistributeBottomItem, DistributeBottomName, 0>,
	<offset GrObjDistributeCenterVerticallyItem, DistributeCenterVerticallyName, 0>,
	<offset GrObjDistributeTopItem, DistributeTopName, 0>,
	<offset GrObjDistributeWidthItem, DistributeWidthName, 0>,
	<offset GrObjDistributeRightItem, DistributeRightName, 0>,
	<offset GrObjDistributeCenterHorizontallyItem, DistributeCenterHorizontallyName, 0>,
	<offset GrObjDistributeLeftItem, DistributeLeftName, 0>,
	<offset GrObjAlignHeightItem, AlignHeightName, 0>,
	<offset GrObjAlignBottomItem, AlignBottomName, 0>,
	<offset GrObjAlignCenterVerticallyItem, AlignCenterVerticallyName, 0>,
	<offset GrObjAlignTopItem, AlignTopName, 0>,
	<offset GrObjAlignWidthItem, AlignWidthName, 0>,
	<offset GrObjAlignRightItem, AlignRightName, 0>,
	<offset GrObjAlignCenterHorizontallyItem, AlignCenterHorizontallyName, 0>,
	<offset GrObjAlignLeftItem, AlignLeftName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAlignDistributeControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjAlignDistributeControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjAlignDistributeControlClass
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
GrObjAlignDistributeControlUpdateUI	method dynamic GrObjAlignDistributeControlClass,
						MSG_GEN_CONTROL_UPDATE_UI

	uses	cx, dx

	.enter

	mov	cx, 2

	mov	ax, mask GOADCF_ALIGN_LEFT
	mov	si, offset GrObjAlignLeftItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_ALIGN_CENTER_HORIZONTALLY
	mov	si, offset GrObjAlignCenterHorizontallyItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_ALIGN_RIGHT
	mov	si, offset GrObjAlignRightItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_ALIGN_WIDTH
	mov	si, offset GrObjAlignWidthItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_ALIGN_TOP
	mov	si, offset GrObjAlignTopItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_ALIGN_CENTER_VERTICALLY
	mov	si, offset GrObjAlignCenterVerticallyItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_ALIGN_BOTTOM
	mov	si, offset GrObjAlignBottomItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_ALIGN_HEIGHT
	mov	si, offset GrObjAlignHeightItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	mov	cx, 3
	mov	ax, mask GOADCF_DISTRIBUTE_LEFT
	mov	si, offset GrObjDistributeLeftItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_DISTRIBUTE_CENTER_HORIZONTALLY
	mov	si, offset GrObjDistributeCenterHorizontallyItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_DISTRIBUTE_RIGHT
	mov	si, offset GrObjDistributeRightItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_DISTRIBUTE_WIDTH
	mov	si, offset GrObjDistributeWidthItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_DISTRIBUTE_TOP
	mov	si, offset GrObjDistributeTopItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_DISTRIBUTE_CENTER_VERTICALLY
	mov	si, offset GrObjDistributeCenterVerticallyItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_DISTRIBUTE_BOTTOM
	mov	si, offset GrObjDistributeBottomItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet
	mov	ax, mask GOADCF_DISTRIBUTE_HEIGHT
	mov	si, offset GrObjDistributeHeightItem
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	clr	dx
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, GIGS_NONE			; select "none"
	clr	dx				; determinate

	test	ss:[bp].GCUUIP_features, mask GOADCF_ALIGN_LEFT or \
				mask GOADCF_ALIGN_CENTER_HORIZONTALLY or \
				mask GOADCF_ALIGN_RIGHT or \
				mask GOADCF_ALIGN_WIDTH
	jz	afterAlignH
	mov	si, offset GrObjAlignHList
	clr	di
	call	ObjMessage
afterAlignH:
	test	ss:[bp].GCUUIP_features, mask GOADCF_ALIGN_TOP or \
				mask GOADCF_ALIGN_CENTER_VERTICALLY or \
				mask GOADCF_ALIGN_BOTTOM or \
				mask GOADCF_ALIGN_HEIGHT
	jz	afterAlignV
	mov	si, offset GrObjAlignVList
	clr	di
	call	ObjMessage
afterAlignV:
	test	ss:[bp].GCUUIP_features, mask GOADCF_DISTRIBUTE_LEFT or \
				mask GOADCF_DISTRIBUTE_CENTER_HORIZONTALLY or \
				mask GOADCF_DISTRIBUTE_RIGHT or \
				mask GOADCF_DISTRIBUTE_WIDTH
	jz	afterDistributeH
	mov	si, offset GrObjDistributeHList
	clr	di
	call	ObjMessage
afterDistributeH:
	test	ss:[bp].GCUUIP_features, mask GOADCF_DISTRIBUTE_TOP or \
				mask GOADCF_DISTRIBUTE_CENTER_VERTICALLY or \
				mask GOADCF_DISTRIBUTE_BOTTOM or \
				mask GOADCF_DISTRIBUTE_HEIGHT
	jz	done
	mov	si, offset GrObjDistributeVList
	clr	di
	call	ObjMessage
done:
	.leave
	ret
GrObjAlignDistributeControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAlignDistributeControlAlignApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Method for MSG_GOADC_ALIGN_APPLY

Called by:	

Pass:		*ds:si = GrObjAlignDistributeControl object
		ds:di = GrObjAlignDistributeControl instance

Return:		nothing

Destroyed:	ax, bx, cx, dx, bp, di, si

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
	Don	1/20/98		Split up align & distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAlignDistributeControlAlignApply	method dynamic	GrObjAlignDistributeControlClass, MSG_GOADC_ALIGN_APPLY

	.enter

	push	si

	call	GetChildBlockAndFeatures

	clr	cl
	test	ax, mask GOADCF_ALIGN_LEFT or \
		    mask GOADCF_ALIGN_CENTER_HORIZONTALLY or \
		    mask GOADCF_ALIGN_RIGHT or \
		    mask GOADCF_ALIGN_WIDTH
	jz	checkVertical

	push	ax, cx
	mov	si, offset GrObjAlignHList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov_tr	dx, ax
	pop	ax, cx
	cmp	dx, GIGS_NONE
	je	checkVertical
	mov	cl, dl
checkVertical:
	test	ax, mask GOADCF_ALIGN_TOP or \
		    mask GOADCF_ALIGN_CENTER_VERTICALLY or \
		    mask GOADCF_ALIGN_BOTTOM or \
		    mask GOADCF_ALIGN_HEIGHT
	jz	sendAlign

	push	ax, cx
	mov	si, offset GrObjAlignVList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov_tr	dx, ax
	pop	ax, cx
	cmp	dx, GIGS_NONE
	je	sendAlign
	or	cl, dl

sendAlign:
	pop	si
	mov	ax, MSG_GB_ALIGN_SELECTED_GROBJS
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjAlignDistributeControlAlignApply	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAlignDistributeControlDistributeApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Method for MSG_GOADC_DISTRIBUTE_APPLY

Called by:	

Pass:		*ds:si = GrObjAlignDistributeControl object
		ds:di = GrObjAlignDistributeControl instance

Return:		nothing

Destroyed:	ax, bx, cx, dx, bp, di, si

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
	Don	1/20/98		Split up align & distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAlignDistributeControlDistributeApply	method dynamic	GrObjAlignDistributeControlClass, MSG_GOADC_DISTRIBUTE_APPLY

	.enter

	push	si

	call	GetChildBlockAndFeatures

	clr	cl
	test	ax, mask GOADCF_DISTRIBUTE_LEFT or \
		    mask GOADCF_DISTRIBUTE_CENTER_HORIZONTALLY or \
		    mask GOADCF_DISTRIBUTE_RIGHT or \
		    mask GOADCF_DISTRIBUTE_WIDTH
	jz	checkVertical

	push	ax, cx
	mov	si, offset GrObjDistributeHList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov_tr	dx, ax
	pop	ax, cx
	cmp	dx, GIGS_NONE
	je	checkVertical
	mov	cl, dl
checkVertical:
	test	ax, mask GOADCF_DISTRIBUTE_TOP or \
		    mask GOADCF_DISTRIBUTE_CENTER_VERTICALLY or \
		    mask GOADCF_DISTRIBUTE_BOTTOM or \
		    mask GOADCF_DISTRIBUTE_HEIGHT
	jz	sendAlign

	push	ax, cx
	mov	si, offset GrObjDistributeVList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov_tr	dx, ax
	pop	ax, cx
	cmp	dx, GIGS_NONE
	je	sendAlign
	or	cl, dl

sendAlign:
	pop	si
	mov	ax, MSG_GB_ALIGN_SELECTED_GROBJS
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjAlignDistributeControlDistributeApply	endp

GrObjUIControllerActionCode	ends
