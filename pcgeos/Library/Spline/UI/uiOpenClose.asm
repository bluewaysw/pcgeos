COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiOpenClose.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

DESCRIPTION:
	

	$Id: uiOpenClose.asm,v 1.1 97/04/07 11:09:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @----------------------------------------------------------------------

MESSAGE:	SplineOpenCloseControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for SplineOpenCloseControlClass

DESCRIPTION:	

PASS:
	*ds:si - instance data
	es - segment of SplineOpenCloseControlClass

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
SplineOpenCloseControlGetInfo	method dynamic	SplineOpenCloseControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset SOCC_dupInfo
	call	CopyDupInfoCommon
	ret
SplineOpenCloseControlGetInfo	endm

SOCC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	SOCC_initFileKey,		; GCBI_initFileKey
	SOCC_gcnList,			; GCBI_gcnList
	length SOCC_gcnList,		; GCBI_gcnCount
	SOCC_notifyTypeList,		; GCBI_notificationList
	length SOCC_notifyTypeList,	; GCBI_notificationCount
	OpenCloseName,			; GCBI_controllerName

	handle OpenCloseUI,		; GCBI_dupBlock
	SOCC_childList,			; GCBI_childList
	length SOCC_childList,		; GCBI_childCount
	SOCC_featuresList,		; GCBI_featuresList
	length SOCC_featuresList,	; GCBI_featuresCount
	SSMC_DEFAULT_FEATURES,		; GCBI_features


	handle OpenCloseToolUI,	; GCBI_toolBlock
 	SOCC_toolList,			; GCBI_toolList            
	length SOCC_toolList,		; GCBI_toolCount           
	SOCC_toolFeaturesList,		; GCBI_toolFeaturesList    
	length SOCC_toolFeaturesList,	; GCBI_toolFeaturesCount   
	SSMC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures     
	0>				; GCBI_helpContext

SOCC_initFileKey	char	"openClose", 0

SOCC_gcnList	GCNListType \
<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPLINE_OPEN_CLOSE_CHANGE>

SOCC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPLINE_OPEN_CLOSE_CHANGE>

;---

SOCC_childList	GenControlChildInfo	\
	<offset OpenCloseList, SSMC_DEFAULT_FEATURES, <0,1>>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SOCC_featuresList	GenControlFeaturesInfo	\
	<offset OpenCloseList, OpenCloseName >

; Tools

SOCC_toolList	GenControlChildInfo	\
	<offset OpenCloseToolList, SSMC_DEFAULT_TOOLBOX_FEATURES, <0,1>>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SOCC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset OpenCloseToolList, OpenCloseToolName >



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenCloseControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= OpenCloseControlClass object
		ds:di	= OpenCloseControlClass instance data
		es	= Segment of OpenCloseControlClass.

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

SplineOpenCloseControlUpdateUI	method	dynamic	SplineOpenCloseControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI

	mov	bx, bp

locals	local	SplineControlUpdateUIParams

	.enter

	mov	locals.SCUUIP_params, bx

	; get notification data

	mov	bx, ss:[bx].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	ch, ds:[SOCNB_state]
	mov	cl, ds:[SOCNB_stateDiffs]
	call	MemUnlock

	;
	; If the SS_CLOSED bit is indeterminate, then set the list
	; that way.
	;

	mov	dx, TRUE
	test	cl, mask SS_CLOSED
	jnz	gotIndetFlag
	clr	dx
gotIndetFlag:

	;
	; The identifier of the items is the message that they send
	; out -- so set the right one.
	;

	test	ch, mask SS_CLOSED
	mov	cx, MSG_SPLINE_OPEN_CURVE
	jz	gotMessage
	mov	cx, MSG_SPLINE_CLOSE_CURVE
gotMessage:

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	si, offset OpenCloseList
	mov	di, offset OpenCloseToolList
	call	SendToChildAndTool
	
	.leave
	ret
SplineOpenCloseControlUpdateUI	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineOpenCloseControlChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= SplineOpenCloseControlClass object
		ds:di	= SplineOpenCloseControlClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineOpenCloseControlChange	method	dynamic	SplineOpenCloseControlClass, 
					MSG_OPEN_CLOSE_CONTROL_CHANGE
	uses	ax,cx,dx,bp
	.enter
	mov_tr	ax, cx			; message to send
	mov	bx, segment VisSplineClass
	mov	di, offset VisSplineClass
	call	GenControlOutputActionRegs

	.leave
	ret
SplineOpenCloseControlChange	endm







