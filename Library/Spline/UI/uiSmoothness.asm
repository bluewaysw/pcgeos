COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiSmoothness.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 5/92   	Initial version.

DESCRIPTION:
	

	$Id: uiSmoothness.asm,v 1.1 97/04/07 11:09:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @----------------------------------------------------------------------

MESSAGE:	SplineSmoothnessControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for SplineSmoothnessControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of SplineSmoothnessControlClass

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
SplineSmoothnessControlGetInfo	method dynamic	SplineSmoothnessControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset SSC_dupInfo
	call	CopyDupInfoCommon
	ret
SplineSmoothnessControlGetInfo	endm

SSC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	SSC_initFileKey,		; GCBI_initFileKey
	SSC_gcnList,			; GCBI_gcnList
	length SSC_gcnList,		; GCBI_gcnCount
	SSC_notifyTypeList,		; GCBI_notificationList
	length SSC_notifyTypeList,	; GCBI_notificationCount
	SmoothnessName,			; GCBI_controllerName

	handle SmoothnessUI,		; GCBI_dupBlock
	SSC_childList,			; GCBI_childList
	length SSC_childList,		; GCBI_childCount
	SSC_featuresList,		; GCBI_featuresList
	length SSC_featuresList,	; GCBI_featuresCount
	SSMC_DEFAULT_FEATURES,		; GCBI_features


	handle SmoothnessToolUI,	; GCBI_toolBlock
 	SSC_toolList,			; GCBI_toolList            
	length SSC_toolList,		; GCBI_toolCount           
	SSC_toolFeaturesList,		; GCBI_toolFeaturesList    
	length SSC_toolFeaturesList,	; GCBI_toolFeaturesCount   
	SSMC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures     
	0>				; GCBI_helpContext

SSC_initFileKey	char	"polyline", 0

SSC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPLINE_SMOOTHNESS>

SSC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPLINE_SMOOTHNESS>

;---

SSC_childList	GenControlChildInfo	\
	<offset SmoothnessList, SSMC_DEFAULT_FEATURES, <0,1>>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSC_featuresList	GenControlFeaturesInfo	\
	<offset SmoothnessList, SmoothnessName >

; Tools

SSC_toolList	GenControlChildInfo	\
	<offset SmoothnessToolList, SSMC_DEFAULT_TOOLBOX_FEATURES, <0,1>>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset SmoothnessToolList, SmoothnessToolName >



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmoothnessControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= SmoothnessControlClass object
		ds:di	= SmoothnessControlClass instance data
		es	= Segment of SmoothnessControlClass.

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSmoothnessControlUpdateUI	method	dynamic	SplineSmoothnessControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI

	mov	bx, bp

locals	local	SplineControlUpdateUIParams

	.enter

	mov	locals.SCUUIP_params, bx

	; ONLY ENABLE UI if mode is ADVANCED_EDIT (or indeterminate),
	; and the selection count is nonzero.


	; get notification data

	mov	bx, ss:[bx].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	ch, ds:[SPNB_smoothness]
	mov	cl, ds:[SPNB_mode]
	tst	ds:[SPNB_numSelected]
	call	MemUnlock
	jz	disable		; disable if none selected.
	

	cmp	cl, -1		; indeterminate
	je	enable
	cmp	cl, SM_ADVANCED_EDIT
	je	enable

disable:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jmp	callIt
enable:
	mov	ax, MSG_GEN_SET_ENABLED
callIt:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset SmoothnessList
	mov	di, offset SmoothnessToolList
	call	SendToChildAndTool
	
	; Now set the smoothness type
	
	mov	cl, ch			; smoothness
	clr	ch

	mov	si, offset SmoothnessList
	mov	di, offset SmoothnessToolList
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	SendToChildAndTool

	.leave
	ret
SplineSmoothnessControlUpdateUI	endm







