COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiGrid.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

DESCRIPTION:
	Code for the title controller

	$Id: uiGrid.asm,v 1.1 97/04/04 17:47:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartGridControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ChartGridControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of ChartGridControlClass

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
ChartGridControlGetInfo	method dynamic	ChartGridControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset CGRC_dupInfo
	call	CopyDupInfoCommon
	ret
ChartGridControlGetInfo	endm


CGRC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	CGRC_IniFileKey,		; GCBI_initFileKey
	CGRC_gcnList,			; GCBI_gcnList
	length CGRC_gcnList,		; GCBI_gcnCount
	CGRC_notifyGridList,		; GCBI_notificationList
	length CGRC_notifyGridList,	; GCBI_notificationCount
	CGRCName,			; GCBI_controllerName

	handle GridControlUI,		; GCBI_dupBlock
	CGRC_childList,			; GCBI_childList
	length CGRC_childList,		; GCBI_childCount
	CGRC_featuresList,		; GCBI_featuresList
	length CGRC_featuresList,	; GCBI_featuresCount
	CGRC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	CGRC_helpContext>		; GCBI_helpContext

CGRC_helpContext	char	"dbChrtGrid", 0

CGRC_DEFAULT_FEATURES  equ mask CGRCF_MAJOR_X or \
			mask CGRCF_MINOR_X or \
			mask CGRCF_MAJOR_Y or \
			mask CGRCF_MINOR_Y

CGRC_IniFileKey	char	"chartGrid", 0

CGRC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_CHART_GROUP_FLAGS>

CGRC_notifyGridList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_CHART_GROUP_FLAGS>

;---

CGRC_childList	GenControlChildInfo	\
	<offset GridInteraction,  mask CGRCF_MAJOR_X or 
			mask CGRCF_MINOR_X or 
			mask CGRCF_MAJOR_Y or 
			mask CGRCF_MINOR_Y,0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

CGRC_featuresList	GenControlFeaturesInfo	\
	<offset	XAxisGridList, XAxisGridName, 0>,
	<offset	YAxisGridList, 	YAxisGridName, 0>

COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartGridControlSetGridFlags -- MSG_CGRC_SET_GRID_FLAGS
						for ChartGridControlClass

DESCRIPTION:	Update the UI stuff based on the setting of the 
		ChartGridFlags.

PASS:
	*ds:si - instance data
	es - segment of ChartGridControlClass

	ax - The message

	cx - bits that are set (GridFlags)
	dx - indeterminate gridflags
	bp - modified bits
		

RETURN:

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
ChartGridControlSetGridFlags	method dynamic	ChartGridControlClass,
						MSG_CGRC_SET_GRID_FLAGS

	mov	ax, MSG_CHART_GROUP_SET_GRID_FLAGS
	mov	bx, segment ChartGroupClass
	mov	di, offset ChartGroupClass
	call	GenControlOutputActionRegs
	ret
ChartGridControlSetGridFlags	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartGridControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for ChartGridControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of ChartGridControlClass

	ax - The message
	dx - NotificationStandardNotificationGrid
	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91	Initial version

------------------------------------------------------------------------------@
ChartGridControlUpdateUI	method ChartGridControlClass,
				MSG_GEN_CONTROL_UPDATE_UI


	cmp	dx, GWNT_CHART_GROUP_FLAGS
	jne	done

	; get notification data

	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	al, ds:[GNB_notificationFlags]
	mov	ah, ds:[GNB_type]
	mov	cl, ds:[GNB_gridFlags]
	mov	dl, ds:[GNB_gridFlagDiffs]
	call	MemUnlock
	pop	ds

	call	GetChildBlock

	cmp	ah, CT_PIE

	mov	si, offset XAxisGridList
	call	DisableOrEnableOnZFlag

	mov	si, offset YAxisGridList
	call	DisableOrEnableOnZFlag

	mov	si, offset XAxisGridList
	call	SetBooleanGroupState

	mov	si, offset YAxisGridList
	call	SetBooleanGroupState
done:
	.leave
	ret
ChartGridControlUpdateUI	endm


