COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiMarker.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 5/92   	Initial version.

DESCRIPTION:
	

	$Id: uiMarker.asm,v 1.1 97/04/07 11:09:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @----------------------------------------------------------------------

MESSAGE:	SplineMarkerControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for SplineMarkerControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of SplineMarkerControlClass

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
SplineMarkerControlGetInfo	method dynamic	SplineMarkerControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset SMC_dupInfo
	call	CopyDupInfoCommon
	ret
SplineMarkerControlGetInfo	endm

SMC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	SMC_IniFileKey,			; GCBI_initFileKey
	SMC_gcnList,			; GCBI_gcnList
	length SMC_gcnList,		; GCBI_gcnCount
	SMC_notifyTypeList,		; GCBI_notificationList
	length SMC_notifyTypeList,	; GCBI_notificationCount
	MarkerName,			; GCBI_controllerName

	handle MarkerControlUI,		; GCBI_dupBlock
	SMC_childList,			; GCBI_childList
	length SMC_childList,		; GCBI_childCount
	SMC_featuresList,		; GCBI_featuresList
	length SMC_featuresList,	; GCBI_featuresCount
	SMC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	SMC_helpContext>		; GCBI_helpContext

SMC_helpContext	char	"dbMrkrShape",0

SMC_DEFAULT_FEATURES equ mask SMCF_MARKER_SHAPE

SMC_IniFileKey	char	"marker", 0

SMC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPLINE_MARKER_SHAPE>

SMC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPLINE_MARKER_SHAPE>

;---

SMC_childList	GenControlChildInfo	\
	<offset MarkerList, SMC_DEFAULT_FEATURES, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SMC_featuresList	GenControlFeaturesInfo	\
	<offset	MarkerList, MarkerName, 0>





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMarkerControlSetMarkerShape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= SplineMarkerControlClass object
		ds:di	= SplineMarkerControlClass instance data
		es	= Segment of SplineMarkerControlClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMarkerControlSetMarkerShape  method dynamic SplineMarkerControlClass,
					MSG_SMC_SET_MARKER_SHAPE
	mov	ax, MSG_SPLINE_SET_MARKER_SHAPE
	GOTO	SendToSplineClass
SplineMarkerControlSetMarkerShape	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToSplineClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send to a series-class object

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToSplineClass	proc	far
	mov	bx, segment VisSplineClass
	mov	di, offset VisSplineClass
	call	GenControlOutputActionRegs
	ret
SendToSplineClass	endp







COMMENT @----------------------------------------------------------------------

MESSAGE:	SplineMarkerControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for SplineMarkerControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of SplineMarkerControlClass

	ax - The message
	dx - NotificationStandardNotificationType
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
SplineMarkerControlUpdateUI	method dynamic SplineMarkerControlClass,
				MSG_GEN_CONTROL_UPDATE_UI


	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	cl, ds:[MNB_markerShape]
	call	MemUnlock

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset MarkerList

	; Set marker shape

	call	SendListSetExcl

	.leave
	ret
SplineMarkerControlUpdateUI	endm

