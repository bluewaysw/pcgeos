COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiHandleControl.asm

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
	Code for the GrObjHandleControlClass

	$Id: uiHandleControl.asm,v 1.1 97/04/04 18:05:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjHandleControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjHandleControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjHandleControlClass

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
GrObjHandleControlGetInfo	method dynamic	GrObjHandleControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOHC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjHandleControlGetInfo	endm

GOHC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOHC_IniFileKey,		; GCBI_initFileKey
	GOHC_gcnList,			; GCBI_gcnList
	length GOHC_gcnList,		; GCBI_gcnCount
	GOHC_notifyList,		; GCBI_notificationList
	length GOHC_notifyList,		; GCBI_notificationCount
	GOHCName,			; GCBI_controllerName

	handle GrObjHandleControlUI,	; GCBI_dupBlock
	GOHC_childList,		; GCBI_childList
	length GOHC_childList,		; GCBI_childCount
	GOHC_featuresList,	; GCBI_featuresList
	length GOHC_featuresList,	; GCBI_featuresCount

	GOHC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	GOHC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOHC_helpContext	char	"dbGrObjHandl", 0

GOHC_IniFileKey	char	"GrObjHandle", 0

GOHC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_INSTRUCTION_FLAGS_CHANGE>

GOHC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_INSTRUCTION_FLAGS_CHANGE>

;---


GOHC_childList	GenControlChildInfo \
	<offset GrObjHandleSizeItemGroup,	mask GOHCF_SMALL_HANDLES or \
					mask GOHCF_MEDIUM_HANDLES or \
					mask GOHCF_LARGE_HANDLES, 0>,
	<offset GrObjInvisibleHandlesBooleanGroup, mask GOHCF_INVISIBLE_HANDLES,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

GOHC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjInvisibleHandlesBooleanGroup, InvisibleHandlesName, 0>,
	<offset GrObjLargeHandlesExcl,	LargeHandlesName, 0>,
	<offset GrObjMediumHandlesExcl,	MediumHandlesName, 0>,
	<offset GrObjSmallHandlesExcl,	SmallHandlesName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjInstructionControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjInstructionControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjInstructionControlClass
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
GrObjHandleControlUpdateUI	method dynamic GrObjHandleControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx, dx, bp

	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	jc	done
	mov	es, ax
	mov	al, es:[GBNIF_handleSize]
	cbw
	clr	dx
	call	MemUnlock
	mov	bx, ss:[bp].GCUUIP_childBlock

	clr	bp
	tst	ax
	jns	absSize
	inc	bp
	neg	ax
absSize:
	mov_tr	cx, ax
	mov	si, offset GrObjHandleSizeItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

	mov	cx, bp
	mov	dx, cx
	not	dx

	mov	si, offset GrObjInvisibleHandlesBooleanGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjHandleControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHandleControlSetDesiredHandleSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjHandleControl method: MSG_GOHC_SET_DESIRED_HANDLE_SIZING

Called by:	

Pass:		*ds:si = GrObjHandleControl object
		ds:di = GrObjHandleControl instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 28, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHandleControlSetHandles	method dynamic	GrObjHandleControlClass,
				MSG_GOHC_SET_HANDLES
	uses	cx,dx
	.enter

	push	si
	call	GetChildBlockAndFeatures
	test	ax, mask GOHCF_SMALL_HANDLES or \
			mask GOHCF_MEDIUM_HANDLES or \
			mask GOHCF_LARGE_HANDLES
	mov	cx, MEDIUM_DESIRED_HANDLE_SIZE
	jz	checkInvisible
	push	ax					;save features
	mov	si, offset GrObjHandleSizeItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage				;al <- size
	mov_tr	cx, ax					;cx <- size
	pop	ax					;ax <- features
checkInvisible:
	test	ax, mask GOHCF_INVISIBLE_HANDLES
	jz	setSize
	push	cx					;save size
	mov	si, offset GrObjInvisibleHandlesBooleanGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage				;ax <- invisible?
	pop	cx					;cl <- size
	tst	ax
	jz	setSize

	neg	cl
setSize:
	pop	si
	mov	ax, MSG_GB_SET_DESIRED_HANDLE_SIZE
	mov	bx, segment GrObjBodyClass
	mov	di, offset GrObjBodyClass
	call	GenControlOutputActionRegs

	.leave
	ret
GrObjHandleControlSetHandles	endm


GrObjUIControllerActionCode	ends
