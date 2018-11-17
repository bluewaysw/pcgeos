COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiPolyline.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 5/92   	Initial version.

DESCRIPTION:
	

	$Id: uiPolyline.asm,v 1.1 97/04/07 11:09:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @----------------------------------------------------------------------

MESSAGE:	SplinePolylineControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for SplinePolylineControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of SplinePolylineControlClass

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
SplinePolylineControlGetInfo	method dynamic	SplinePolylineControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset SPLC_dupInfo
	call	CopyDupInfoCommon
	ret
SplinePolylineControlGetInfo	endm

SPLC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	SPLC_initFileKey,		; GCBI_initFileKey
	SPLC_gcnList,			; GCBI_gcnList
	length SPLC_gcnList,		; GCBI_gcnCount
	SPLC_notifyTypeList,		; GCBI_notificationList
	length SPLC_notifyTypeList,	; GCBI_notificationCount
	PolylineName,			; GCBI_controllerName

	handle PolylineUI,		; GCBI_dupBlock
	SPLC_childList,			; GCBI_childList
	length SPLC_childList,		; GCBI_childCount
	SPLC_featuresList,		; GCBI_featuresList
	length SPLC_featuresList,	; GCBI_featuresCount
	SPLC_DEFAULT_FEATURES,		; GCBI_features

	handle PolylineToolUI,		; GCBI_toolBlock
	SPLC_toolChildList,		; GCBI_toolList
	length SPLC_toolChildList,	; GCBI_toolCount
	SPLC_toolFeaturesList,		; GCBI_toolFeaturesList
	length SPLC_toolFeaturesList,	; GCBI_toolFeaturesCount
	SPLC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	0>				; GCBI_helpContext

SPLC_initFileKey	char	"polyline", 0

SPLC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPLINE_POLYLINE>

SPLC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPLINE_POLYLINE>

;---

SPLC_childList	GenControlChildInfo	\
	<offset MakeCurvyTrigger, mask SPLCF_MAKE_CURVY, <0,1>>,
	<offset MakeStraightTrigger, mask SPLCF_MAKE_STRAIGHT, <0,1>>,
	<offset DeleteTrigger, mask SPLCF_DELETE, <0,1>>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SPLC_featuresList	GenControlFeaturesInfo	\
	<offset MakeCurvyTrigger, MakeCurvyName >,
	<offset MakeStraightTrigger, MakeStraightName >,
	<offset DeleteTrigger, DeleteName >


SPLC_toolChildList	GenControlChildInfo	\
	<offset MakeCurvyTool, mask SPLCF_MAKE_CURVY, <0,1>>,
	<offset MakeStraightTool, mask SPLCF_MAKE_STRAIGHT, <0,1>>,
	<offset DeleteTool, mask SPLCF_DELETE, <0,1>>

SPLC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset MakeCurvyTool, MakeCurvyName >,
	<offset MakeStraightTool, MakeStraightName >,
	<offset DeleteTool, DeleteName >






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplinePolylineControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= SplinePolylineControlClass object
		ds:di	= SplinePolylineControlClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PolylineEnableDisableFlags	record
	PLEDF_DELETE:1
	PLEDF_MAKE_CURVY:1
	PLEDF_MAKE_STRAIGHT:1
	:5
PolylineEnableDisableFlags	end

SplinePolylineControlUpdateUI	method	dynamic	SplinePolylineControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI
	uses	ax,cx,dx,bp

	mov	bx, bp

locals	local	SplineControlUpdateUIParams

	.enter

	mov	locals.SCUUIP_params, bx
	
	; get notification data
	

	mov	bx, ss:[bx].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	cl, ds:[SPNB_actionType]
	mov	ch, ds:[SPNB_numControls]
	mov	dl, ds:[SPNB_mode]
	call	MemUnlock

	; If mode is not BEGINNER_EDIT, or indeterminate, then disable
	; 'em all!

	cmp	dl, SM_BEGINNER_EDIT
	je	ok
	cmp	dl, -1
	je	ok
	clr	al
	jmp	doIt
ok:

	mov	al, mask PLEDF_DELETE

	cmp	ch, 0
	jne	notZero
	or	al, mask PLEDF_MAKE_CURVY
	jmp	doIt

notZero:
	cmp	ch, 1
	jne	notOne
	or	al, mask PLEDF_MAKE_STRAIGHT or mask PLEDF_MAKE_CURVY
	jmp	doIt

notOne:
	cmp	ch, 2
	jne	notTwo
	or	al, mask PLEDF_MAKE_STRAIGHT
	jmp	doIt
notTwo:
	; enable 'em all
	or	al, mask PLEDF_MAKE_CURVY or mask PLEDF_MAKE_STRAIGHT
doIt:
	mov	locals.SCUUIP_table, offset PolylineTable
	mov	locals.SCUUIP_tableEnd, (offset PolylineTable +\
					size PolylineTable)

	call	ProcessEnableDisableFlags
	.leave
	ret
SplinePolylineControlUpdateUI	endm


PolylineTable	EnableDisableEntry	\
	<DeleteTrigger, DeleteTool>,
	<MakeCurvyTrigger, MakeCurvyTool>,
	<MakeStraightTrigger, MakeStraightTool>

