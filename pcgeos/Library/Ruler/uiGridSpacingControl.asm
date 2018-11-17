COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiGridSpacingControl.asm

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
	jon	11 feb 1992   	Initial version.

DESCRIPTION:
	Code for the Grid Spacing controller

	$Id: uiGridSpacingControl.asm,v 1.1 97/04/07 10:43:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerUICode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerGridControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for RulerGridControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of RulerGridControlClass

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
RulerGridControlGetInfo	method dynamic	RulerGridControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset RGC_dupInfo
	call	CopyDupInfoCommon
	ret
RulerGridControlGetInfo	endm

RGC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	RGC_IniFileKey,			; GCBI_initFileKey
	RGC_gcnList,			; GCBI_gcnList
	length RGC_gcnList,		; GCBI_gcnCount
	RGC_notifyList,			; GCBI_notificationList
	length RGC_notifyList,		; GCBI_notificationCount
	RGCName,			; GCBI_controllerName

	handle RulerGridControlUI,	; GCBI_dupBlock
	RGC_childList,			; GCBI_childList
	length RGC_childList,		; GCBI_childCount
	RGC_featuresList,		; GCBI_featuresList
	length RGC_featuresList,	; GCBI_featuresCount

	RGC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	RGC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
RulerControlInfoXIP	segment resource
endif

RGC_helpContext	char	"dbRulerGrid", 0
RGC_IniFileKey	char	"RulerGrid", 0

RGC_gcnList	GCNListType \
<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_RULER_TYPE_CHANGE>,
<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_RULER_GRID_CHANGE>

RGC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_RULER_TYPE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_RULER_GRID_CHANGE>

;---

RGC_childList	GenControlChildInfo \
<offset GridSpacingGroup,	mask RGCF_GRID_SPACING, 0>,
<offset GridOptionsList, mask RGCF_SNAP_TO_GRID or mask RGCF_SHOW_GRID, 0>

RGC_featuresList	GenControlFeaturesInfo	\
	<offset GridShowGridEntry, ShowGridName, 0>,
	<offset GridSnapToGridEntry, SnapToGridName, 0>,
	<offset GridSpacingGroup, GridSpacingName, 0>

if FULL_EXECUTE_IN_PLACE
RulerControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerGridControlSetGridSpacing -- MSG_RGC_SET_GRID_SPACING
						for RulerGridControlClass

DESCRIPTION:	Set grid spacing

PASS:
	*ds:si - instance data
	es - segment of RulerGridControlClass

	dx.cx - wwf points

RETURN:

DESTROYED:
	ax, bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Only update on a USER change

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version
------------------------------------------------------------------------------@
RulerGridControlSetGridSpacing	method dynamic	RulerGridControlClass,
				MSG_RGC_SET_GRID_SPACING
				
	.enter
	mov	ax, MSG_VIS_RULER_SET_GRID_SPACING
	mov	bx, segment VisRulerClass
	mov	di, offset VisRulerClass
	call	GenControlOutputActionRegs
	.leave
	ret
RulerGridControlSetGridSpacing	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerGridControlSetGridOptions -- MSG_RGC_SET_GRID_OPTIONS
						for RulerGridControlClass

DESCRIPTION:	Set grid spacing

PASS:
	*ds:si - instance data
	es - segment of RulerGridControlClass

	cl - GridOptions

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Only update on a USER change

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version
------------------------------------------------------------------------------@
RulerGridControlSetGridOptions	method dynamic	RulerGridControlClass,
				MSG_RGC_SET_GRID_OPTIONS

	uses	cx, dx

	.enter
	;
	;	First check the options
	;
	mov	ax, MSG_VIS_RULER_TURN_GRID_SNAPPING_ON
	test	cx, mask GO_SNAP_TO_GRID
	jnz	setGrid
	mov	ax, MSG_VIS_RULER_TURN_GRID_SNAPPING_OFF
setGrid:
	push	bx
	mov	bx, segment VisRulerClass
	mov	di, offset VisRulerClass
	call	GenControlOutputActionRegs
	pop	bx

	mov	ax, MSG_VIS_RULER_SHOW_GRID
	test	cx, mask GO_SHOW_GRID
	jnz	showOrHide
	mov	ax, MSG_VIS_RULER_HIDE_GRID
showOrHide:
	mov	bx, segment VisRulerClass
	mov	di, offset VisRulerClass
	call	GenControlOutputActionRegs

	.leave
	ret
RulerGridControlSetGridOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerGridControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for RulerGridControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of RulerGridControlClass
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
RulerGridControlUpdateUI	method RulerGridControlClass,
						MSG_GEN_CONTROL_UPDATE_UI
	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock
	cmp	ss:[bp].GCUUIP_changeType, GWNT_RULER_TYPE_CHANGE
	jne	notType

	call	MemLock
	mov	ds, ax
	mov	cl, ds:[RTNB_type]
	call	MemUnlock

	call	ConvertVisRulerTypeToDisplayFormat

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset GridSpacingUnitsList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di, dx
	call	ObjMessage

	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cx, ax						;mark modified
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	clr	di
	call	ObjMessage
done:
	.leave
	ret

notType:
	mov	bx, ss:[bp].GCUUIP_dataBlock
	push	ds
	call	MemLock
	mov	ds, ax
	movwwf	dxcx, ds:[RGNB_gridSpacing]
	mov	al, ds:[RGNB_gridOptions]
	call	MemUnlock
	pop	ds

	push	ax					;save options

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset GridSpacingValue
	clr	bp
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	clr	di
	call	ObjMessage

	pop	cx					;cx <- options
	mov	dx, cx
	not	dx
	mov	si, offset GridOptionsList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage
	jmp	done
RulerGridControlUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVisRulerTypeToDisplayFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Converts a VisRulerType to a GenValueDisplayFormat
		(why, oh why don't I just merge them?)

Pass:		cl	- VisRulerType

Return:		cl	- GenValueDisplayFormat

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertVisRulerTypeToDisplayFormat	proc	near
	.enter

	;
	;  Convert the VisRulerType in cl to the appropriate id
	;  in GridSpacingUnitsList
	;
	cmp	cl, VRT_INCHES
	jne	checkPoints
	mov	cl, GVDF_INCHES
	jmp	done

checkPoints:
	cmp	cl, VRT_POINTS
	jne	checkPicas
	mov	cl, GVDF_POINTS
	jmp	done

checkPicas:
	cmp	cl, VRT_PICAS
	jne	checkCM
	mov	cl, GVDF_PICAS
	jmp	done

checkCM:
	cmp	cl, VRT_CENTIMETERS
	jne	useDefault
	mov	cl, GVDF_CENTIMETERS
	jmp	done

useDefault:
	;
	;  use the system preference
	;
	push	ax
	mov	cl, GVDF_INCHES
	call	LocalGetMeasurementType
	mov	cl, GVDF_CENTIMETERS
	cmp	al, MEASURE_METRIC
	pop	ax
	jz	done
	mov	cl, GVDF_INCHES
done:
	.leave
	ret
ConvertVisRulerTypeToDisplayFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVisRulerTypeToDistanceUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Converts a VisRulerType to a DistanceUnit
		(why, oh why don't I just merge them?)

Pass:		cl - VisRulerType

Return:		cl - DistanceUnit

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertVisRulerTypeToDistanceUnit	proc	near
	.enter

	;
	;  Convert the VisRulerType in cl to the appropriate id
	;  in GridSpacingUnitsList
	;
	cmp	cl, VRT_INCHES
	jne	checkCM

	mov	cl, DU_INCHES
	jmp	done

checkCM:
	cmp	cl, VRT_CENTIMETERS
	jne	checkPoints

	mov	cl, DU_CENTIMETERS
	jmp	done

checkPoints:
	cmp	cl, VRT_POINTS
	jne	checkPicas

	mov	cl, DU_POINTS
	jmp	done

checkPicas:
	cmp	cl, VRT_PICAS
	jne	useDefault

	mov	cl, DU_PICAS
	jmp	done

useDefault:
	;
	;  This will have to change to use the system preference
	;
	mov	cl, DU_INCHES_OR_CENTIMETERS
	
done:
	.leave
	ret
ConvertVisRulerTypeToDistanceUnit	endp

RulerUICode	ends
