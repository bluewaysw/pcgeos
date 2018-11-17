COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiPoint.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 5/92   	Initial version.

DESCRIPTION:
	

	$Id: uiPoint.asm,v 1.1 97/04/07 11:09:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @----------------------------------------------------------------------

MESSAGE:	SplinePointControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for SplinePointControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of SplinePointControlClass

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
SplinePointControlGetInfo	method dynamic	SplinePointControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset SPC_dupInfo
	call	CopyDupInfoCommon
	ret
SplinePointControlGetInfo	endm

SPC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	SPC_initFileKey,		; GCBI_initFileKey
	SPC_gcnList,			; GCBI_gcnList
	length SPC_gcnList,		; GCBI_gcnCount
	SPC_notifyTypeList,		; GCBI_notificationList
	length SPC_notifyTypeList,	; GCBI_notificationCount
	PointName,			; GCBI_controllerName

	handle PointUI,			; GCBI_dupBlock
	SPC_childList,			; GCBI_childList
	length SPC_childList,		; GCBI_childCount
	SPC_featuresList,		; GCBI_featuresList
	length SPC_featuresList,	; GCBI_featuresCount
	SPC_DEFAULT_FEATURES,		; GCBI_features

	handle PointToolUI,		; GCBI_toolBlock
	SPC_toolList,			; GCBI_toolList
	length SPC_toolList,		; GCBI_toolCount
	SPC_toolFeaturesList,		; GCBI_toolFeaturesList
	length SPC_toolFeaturesList,	; GCBI_toolFeaturesCount
	SPC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	0>				; GCBI_helpContext

SPC_initFileKey	char	"point", 0

SPC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPLINE_POINT>

SPC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPLINE_POINT>

;---

SPC_childList	GenControlChildInfo	\
    <offset DeleteControlTrigger, mask SPCF_DELETE_CONTROLS, 
	mask GCCF_IS_DIRECTLY_A_FEATURE>,
    <offset InsertControlTrigger, mask SPCF_INSERT_CONTROLS, 
	mask GCCF_IS_DIRECTLY_A_FEATURE>,
    <offset DeleteAnchorTrigger, mask SPCF_DELETE_ANCHORS, 
	mask GCCF_IS_DIRECTLY_A_FEATURE>,
    <offset InsertAnchorTrigger, mask SPCF_INSERT_ANCHORS, 
	mask GCCF_IS_DIRECTLY_A_FEATURE>



; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SPC_featuresList	GenControlFeaturesInfo	\
	<offset DeleteControlTrigger, DeleteControlName >,
	<offset InsertControlTrigger, InsertControlName >,
	<offset DeleteAnchorTrigger, DeleteAnchorName >,
	<offset InsertAnchorTrigger, InsertAnchorName >


SPC_toolList	GenControlChildInfo	\
	<offset DeleteControlTool, mask SPCF_DELETE_CONTROLS, 
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset InsertControlTool, mask SPCF_INSERT_CONTROLS, 
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DeleteAnchorTool, mask SPCF_DELETE_ANCHORS, 
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset InsertAnchorTool, mask SPCF_INSERT_ANCHORS, 
		mask GCCF_IS_DIRECTLY_A_FEATURE>


SPC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset DeleteControlTool, DeleteControlName >,
	<offset InsertControlTool, InsertControlName >,
	<offset DeleteAnchorTool, DeleteAnchorName >,
	<offset InsertAnchorTool, InsertAnchorName >


COMMENT @----------------------------------------------------------------------

MESSAGE:	SplinePointControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for SplinePointControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of SplinePointControlClass

	ax - The message
	dx - NotificationStandardNotificationType
	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	If ActionType is AT_SELECT_SEGMENT
		enable the "Insert Anchor" ui
		disable all others

	ELSE
	  If ActionType is AT_SELECT_ANCHOR or AT_SELECT_CONTROL
		If numControls is ZERO
			disable DELETE CONTROLS,
			enable INSERT CONTROLS & delete ANCHORS
		else if numControls is ONE
			enable DELETE and INSERT controls
		else if numControls is TWO
			disable INSERT controls
		else
			enable them all, as we probably have multiple
			splines selected.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91	Initial version

------------------------------------------------------------------------------@
EnableDisableFlags	record
	EDF_INSERT_ANCHOR:1
	EDF_INSERT_CONTROL:1
	EDF_DELETE_ANCHOR:1
	EDF_DELETE_CONTROL:1
	:4
EnableDisableFlags	end

PointTable	EnableDisableEntry	\
	<InsertAnchorTrigger, InsertAnchorTool>,
	<InsertControlTrigger, InsertControlTool>,
	<DeleteAnchorTrigger, DeleteAnchorTool>,
	<DeleteControlTrigger, DeleteControlTool>


SplinePointControlUpdateUI	method dynamic SplinePointControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	mov	bx, bp		; GenControlUpdateUIParams

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
	tst	ds:[SPNB_numSelected]
	call	MemUnlock
	
	;
	; If there are no points selected, then just disable all UI
	;

	mov	al, 0
	jz	doIt

	; If mode is not one of the edit modes, or unknown,
	; then disable all ui.

	cmp	dl, SM_ADVANCED_EDIT
	je	ok
	cmp	dl, SM_BEGINNER_EDIT
	je	ok
	cmp	dl, -1
	je	ok
	clr	al			; disable 'em all!
	jmp	doIt

ok:
	; If AT_SELECT_SEGMENT, then enable "Insert Anchor", else delete

	cmp	cl, AT_SELECT_SEGMENT
	jne	notSelectSegment

	mov	al, mask EDF_INSERT_ANCHOR
	jmp	doIt

notSelectSegment:

	; Delete anchors is always a possibility...

	mov	al, mask EDF_DELETE_ANCHOR

	cmp	ch, 0
	jne	notZero
	or	al, mask EDF_INSERT_CONTROL
	jmp	doIt

notZero:
	cmp	ch, 1
	jne	notOne
	or	al, mask EDF_INSERT_CONTROL or mask EDF_DELETE_CONTROL
	jmp	doIt

notOne:
	cmp	ch, 2
	jne	notTwo
	or	al, mask EDF_DELETE_CONTROL
	jmp	doIt
notTwo:
	; enable 'em all
	or	al, mask EDF_DELETE_CONTROL or mask EDF_INSERT_CONTROL
doIt:
	mov	locals.SCUUIP_table, offset PointTable
	mov	locals.SCUUIP_tableEnd, (offset PointTable + size PointTable)
	call	ProcessEnableDisableFlags

	.leave
	ret
SplinePointControlUpdateUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessEnableDisableFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	process the flags

CALLED BY:	SplinePointControlUpdateUI, SplinePolylineControlUpdateUI

PASS:		al - flags -- each bit corresponds to a posn in the
		table
		ss:bp - GenControlUpdateUIParams
		*ds:si - GenControl object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessEnableDisableFlags	proc near
	uses	ax,bx,cx,dx,di,si,bp

	.enter	inherit	SplinePointControlUpdateUI

	mov	bl, al			; passed flags

	mov	di, locals.SCUUIP_table

	mov	dl, VUM_DELAYED_VIA_UI_QUEUE

startLoop:
	shl	bl
	jnc	disable				; bit not set
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	sendIt
disable:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
sendIt:
	push	di
	mov	si, cs:[di].EDE_child
	mov	di, cs:[di].EDE_tool
	call	SendToChildAndTool
	pop	di

	add	di, size EnableDisableEntry
	cmp	di, locals.SCUUIP_tableEnd
	jl	startLoop

	.leave
	ret
ProcessEnableDisableFlags	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToChildAndTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the child and to the tool

CALLED BY:

PASS:		si - child chunk handle
		di - tool chunk handle
		ax,cx,dx,bx - message data
		ss:[bp] - SplineControlUpdateUIParams

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToChildAndTool	proc near
	uses	di,si,bp,bx

	.enter	inherit	SplinePointControlUpdateUI

	mov	bp, locals.SCUUIP_params

	xchg	bx, bp		; ssbx - params, bp - data bp

	push	bx, di		; di - tool chunk
	mov	bx, ss:[bx].GCUUIP_childBlock
	call	ObjMessageCheck
	pop	bx, si		; si - tool chunk
	
	mov	bx, ss:[bx].GCUUIP_toolBlock
	call	ObjMessageCheck

	.leave
	ret
SendToChildAndTool	endp

